import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../application/running_coaching_service.dart';
import '../../domain/entities/running_video_analysis_result.dart';

const double _minimumPoseConfidence = 0.35;
const int _maximumRetargetFrameCount = 48;
const int _maximumLowConfidenceHoldFrames = 5;

@visibleForTesting
const String runningThreeDRendererVersion = 'rigged-human-runner-v2';

class RunningThreeDRunnerPayload {
  final Map<String, Object?> data;

  const RunningThreeDRunnerPayload(this.data);

  String toJson() => jsonEncode(data);
}

class RunningThreeDRunnerRetargeter {
  final RunningCoachingThresholds thresholds;

  const RunningThreeDRunnerRetargeter({
    this.thresholds = const RunningCoachingThresholds(),
  });

  RunningThreeDRunnerPayload buildComparisonPayload({
    required Iterable<RunningPoseFrame> poseFrames,
    required RunningPoseFrame selectedFrame,
    required RunningCoachingInsight insight,
    required RunningDirection direction,
    required String currentLabel,
    required String targetLabel,
    required String confidenceLabel,
    required String loadingLabel,
    required String errorLabel,
    required String referenceNotice,
    required String currentColor,
    required String targetColor,
    required String successColor,
  }) {
    final sourceFrames = _sampleFrames(poseFrames, selectedFrame);
    final retargeted = _retargetSequence(
      frames: sourceFrames,
      insight: insight,
      direction: direction,
    );
    final selectedTimestampMs = selectedFrame.timestampMs;
    final selectedIndex = _nearestFrameIndex(
      retargeted,
      selectedTimestampMs: selectedTimestampMs,
    );
    final currentConfidence =
        retargeted.isEmpty ? 0.0 : retargeted[selectedIndex].current.confidence;
    final targetConfidence =
        retargeted.isEmpty ? 0.0 : retargeted[selectedIndex].target.confidence;
    return RunningThreeDRunnerPayload(<String, Object?>{
      'rendererVersion': runningThreeDRendererVersion,
      'metric': insight.metric.name,
      'status': insight.status.name,
      'direction': direction.name,
      'selectedTimestampMs': selectedTimestampMs,
      'selectedFrameIndex': selectedIndex,
      'hasMotion': retargeted.length > 1,
      'focusIndices': focusIndicesForRunningThreeDMetric(insight.metric)
          .toList(growable: false),
      'colors': <String, Object?>{
        'current': currentColor,
        'target': targetColor,
        'success': successColor,
      },
      'labels': <String, Object?>{
        'current': currentLabel,
        'target': targetLabel,
        'confidence': confidenceLabel,
        'loading': loadingLabel,
        'error': errorLabel,
        'referenceNotice': referenceNotice,
      },
      'confidence': <String, Object?>{
        'current': _round3(currentConfidence),
        'target': _round3(targetConfidence),
      },
      'frames': retargeted.map((frame) => frame.toMap()).toList(
            growable: false,
          ),
    });
  }

  @visibleForTesting
  List<Map<String, Object?>> retargetSequenceForTesting({
    required Iterable<RunningPoseFrame> frames,
    required RunningCoachingInsight insight,
    required RunningDirection direction,
  }) {
    return _retargetSequence(
      frames: frames,
      insight: insight,
      direction: direction,
    ).map((frame) => frame.toMap()).toList(growable: false);
  }

  List<_RunningThreeDRunnerFrame> _retargetSequence({
    required Iterable<RunningPoseFrame> frames,
    required RunningCoachingInsight insight,
    required RunningDirection direction,
  }) {
    final ordered = frames.toList(growable: false)
      ..sort((a, b) => a.timestampMs.compareTo(b.timestampMs));
    if (ordered.isEmpty) return const <_RunningThreeDRunnerFrame>[];

    final smoother = _TemporalPoseSmoother(direction: direction);
    final memory = _RetargetMemory();
    final output = <_RunningThreeDRunnerFrame>[];
    for (final frame in ordered) {
      final smoothed = smoother.smooth(frame);
      final current = _RunnerRig.fromSmoothed(
        frame: frame,
        smoothed: smoothed,
        direction: direction,
        memory: memory,
      );
      if (current == null) continue;
      final target = _targetFor(current, insight);
      output.add(
        _RunningThreeDRunnerFrame(
          timestampMs: frame.timestampMs,
          current: current,
          target: target,
          sourceLandmarks:
              frame.landmarks.map(_sourceLandmarkMap).toList(growable: false),
        ),
      );
    }
    return List<_RunningThreeDRunnerFrame>.unmodifiable(output);
  }

  _RunnerRig _targetFor(
    _RunnerRig current,
    RunningCoachingInsight insight,
  ) {
    if (insight.status == RunningCoachStatus.good ||
        !insight.quality.isReliableForCoaching) {
      return current.asTarget(modifiedChannels: const <String>[]);
    }

    final joints = Map<String, _Vec3>.from(current.joints);
    final modified = <String>{};
    switch (insight.metric) {
      case RunningCoachMetric.posture:
        _applyPostureTarget(joints, insight, modified);
      case RunningCoachMetric.bounce:
        _applyBounceTarget(joints, insight, modified);
      case RunningCoachMetric.footStrike:
        _applyFootStrikeTarget(joints, current, modified);
      case RunningCoachMetric.kneeFlexion:
        _applyKneeTarget(joints, current, insight, modified);
      case RunningCoachMetric.armCarriage:
        _applyArmTarget(joints, current, insight, modified);
    }
    return current.copyWith(
      joints: joints,
      isTarget: true,
      modifiedChannels: modified.toList(growable: false)..sort(),
    );
  }

  void _applyPostureTarget(
    Map<String, _Vec3> joints,
    RunningCoachingInsight insight,
    Set<String> modified,
  ) {
    final pelvis = joints['pelvisCenter'];
    final shoulder = _center(joints['leftShoulder'], joints['rightShoulder']);
    if (pelvis == null || shoulder == null) return;
    final torso = shoulder - pelvis;
    final torsoLength = torso.length;
    if (torsoLength < 0.05) return;
    final targetDegrees = insight.finding == RunningCoachFinding.postureTooLean
        ? thresholds.maximumForwardLeanDegrees
        : thresholds.minimumForwardLeanDegrees;
    final currentAngle = math.atan2(torso.x, torso.y);
    final targetAngle = targetDegrees * math.pi / 180;
    final delta = targetAngle - currentAngle;
    for (final name in _upperBodyJointNames) {
      final point = joints[name];
      if (point == null) continue;
      joints[name] = point.rotateAroundZ(pelvis, delta);
      modified.add(name);
    }
  }

  void _applyBounceTarget(
    Map<String, _Vec3> joints,
    RunningCoachingInsight insight,
    Set<String> modified,
  ) {
    final excess = math.max(
      0.0,
      insight.value - thresholds.maximumVerticalBouncePercent,
    );
    if (excess <= 0) return;
    final drop = (excess / 100).clamp(0.025, 0.10).toDouble();
    for (final name in _wholeBodyJointNames) {
      final point = joints[name];
      if (point == null) continue;
      joints[name] = point - _Vec3(0, drop, 0);
      modified.add(name);
    }
  }

  void _applyFootStrikeTarget(
    Map<String, _Vec3> joints,
    _RunnerRig current,
    Set<String> modified,
  ) {
    final side = _leadLegSide(joints);
    final hip = joints['${side}Hip'];
    final ankle = joints['${side}Ankle'];
    final toe = joints['${side}Toe'];
    final heel = joints['${side}Heel'];
    if (hip == null || ankle == null || toe == null || heel == null) return;

    final bodyHeight = current.bodyHeight.clamp(1.2, 2.1).toDouble();
    final targetToeX = current.joints['pelvisCenter']!.x +
        thresholds.maximumFootStrikeRatio * bodyHeight;
    final deltaX = targetToeX - toe.x;
    final targetAnkle = ankle + _Vec3(deltaX, 0, 0);
    final targetToe = toe + _Vec3(deltaX, 0, 0);
    final targetHeel = heel + _Vec3(deltaX, 0, 0);
    final solvedKnee = _solveTwoBone(
      root: hip,
      end: _clampReach(
        root: hip,
        end: targetAnkle,
        upperLength: _RunnerModel.thighLength,
        lowerLength: _RunnerModel.shinLength,
      ),
      hint: joints['${side}Knee'] ?? targetAnkle,
      upperLength: _RunnerModel.thighLength,
      lowerLength: _RunnerModel.shinLength,
    );
    joints['${side}Knee'] = solvedKnee.joint;
    joints['${side}Ankle'] = solvedKnee.end;
    joints['${side}Toe'] = targetToe + (solvedKnee.end - targetAnkle);
    joints['${side}Heel'] = targetHeel + (solvedKnee.end - targetAnkle);
    modified.addAll(<String>[
      '${side}Knee',
      '${side}Ankle',
      '${side}Toe',
      '${side}Heel',
    ]);
  }

  void _applyKneeTarget(
    Map<String, _Vec3> joints,
    _RunnerRig current,
    RunningCoachingInsight insight,
    Set<String> modified,
  ) {
    final side = _leadLegSide(joints);
    final hip = joints['${side}Hip'];
    final knee = joints['${side}Knee'];
    final ankle = joints['${side}Ankle'];
    if (hip == null || knee == null || ankle == null) return;
    final targetDegrees =
        insight.finding == RunningCoachFinding.kneeTooCollapsed
            ? thresholds.minimumStanceKneeAngleDegrees
            : thresholds.maximumStanceKneeAngleDegrees;
    final targetAnkle = _pointAtJointAngle(
      root: hip,
      joint: knee,
      end: ankle,
      targetDegrees: targetDegrees,
      turnSign: 1,
    );
    final solvedKnee = _solveTwoBone(
      root: hip,
      end: _clampReach(
        root: hip,
        end: targetAnkle,
        upperLength: _RunnerModel.thighLength,
        lowerLength: _RunnerModel.shinLength,
      ),
      hint: knee,
      upperLength: _RunnerModel.thighLength,
      lowerLength: _RunnerModel.shinLength,
    );
    final delta = solvedKnee.end - ankle;
    joints['${side}Knee'] = solvedKnee.joint;
    joints['${side}Ankle'] = solvedKnee.end;
    for (final name in <String>['${side}Toe', '${side}Heel']) {
      final point = joints[name];
      if (point != null) joints[name] = point + delta;
    }
    modified.addAll(<String>[
      '${side}Knee',
      '${side}Ankle',
      '${side}Toe',
      '${side}Heel',
    ]);
  }

  void _applyArmTarget(
    Map<String, _Vec3> joints,
    _RunnerRig current,
    RunningCoachingInsight insight,
    Set<String> modified,
  ) {
    final side = _leadArmSide(joints);
    final shoulder = joints['${side}Shoulder'];
    final elbow = joints['${side}Elbow'];
    final wrist = joints['${side}Wrist'];
    if (shoulder == null || elbow == null || wrist == null) return;
    final targetDegrees = insight.finding == RunningCoachFinding.armTooTight
        ? thresholds.minimumElbowAngleDegrees
        : thresholds.maximumElbowAngleDegrees;
    final targetWrist = _pointAtJointAngle(
      root: shoulder,
      joint: elbow,
      end: wrist,
      targetDegrees: targetDegrees,
      turnSign: -1,
    );
    final solvedElbow = _solveTwoBone(
      root: shoulder,
      end: _clampReach(
        root: shoulder,
        end: targetWrist,
        upperLength: _RunnerModel.upperArmLength,
        lowerLength: _RunnerModel.forearmLength,
      ),
      hint: elbow,
      upperLength: _RunnerModel.upperArmLength,
      lowerLength: _RunnerModel.forearmLength,
    );
    final delta = solvedElbow.end - wrist;
    joints['${side}Elbow'] = solvedElbow.joint;
    joints['${side}Wrist'] = solvedElbow.end;
    for (final name in <String>[
      '${side}Hand',
      '${side}Pinky',
      '${side}Index',
      '${side}Thumb',
    ]) {
      final point = joints[name];
      if (point != null) joints[name] = point + delta;
    }
    modified.addAll(<String>[
      '${side}Elbow',
      '${side}Wrist',
      '${side}Hand',
      '${side}Pinky',
      '${side}Index',
      '${side}Thumb',
    ]);
  }
}

@visibleForTesting
Set<int> focusIndicesForRunningThreeDMetric(RunningCoachMetric metric) {
  return switch (metric) {
    RunningCoachMetric.posture => const <int>{
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        23,
        24,
      },
    RunningCoachMetric.bounce => const <int>{
        0,
        7,
        8,
        11,
        12,
        23,
        24,
        27,
        28,
        29,
        30,
        31,
        32,
      },
    RunningCoachMetric.footStrike => const <int>{
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
        32,
      },
    RunningCoachMetric.kneeFlexion => const <int>{
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
        32,
      },
    RunningCoachMetric.armCarriage => const <int>{
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
        20,
        21,
        22,
      },
  };
}

class _RunningThreeDRunnerFrame {
  final int timestampMs;
  final _RunnerRig current;
  final _RunnerRig target;
  final List<Map<String, Object?>> sourceLandmarks;

  const _RunningThreeDRunnerFrame({
    required this.timestampMs,
    required this.current,
    required this.target,
    required this.sourceLandmarks,
  });

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'timestampMs': timestampMs,
      'sourceLandmarks': sourceLandmarks,
      'current': current.toMap(),
      'target': target.toMap(),
    };
  }
}

class _TemporalPoseSmoother {
  final RunningDirection direction;
  final Map<int, _SmoothedLandmark> _last = <int, _SmoothedLandmark>{};
  final Map<int, int> _heldFrames = <int, int>{};

  _TemporalPoseSmoother({required this.direction});

  _SmoothedPose smooth(RunningPoseFrame frame) {
    final raw = _rawLandmarksFor(frame, direction: direction);
    final smoothed = <int, _SmoothedLandmark>{};
    for (var index = 0; index < mediaPipePoseLandmarkCount; index += 1) {
      final landmark = frame.landmarkByIndex(index);
      final point = raw[index];
      if (landmark == null || point == null) continue;
      final confidence = _landmarkConfidence(landmark);
      final previous = _last[index];
      if (confidence >= _minimumPoseConfidence) {
        final alpha = (0.22 + confidence * 0.58).clamp(0.25, 0.86).toDouble();
        final nextPoint =
            previous == null ? point : _Vec3.lerp(previous.point, point, alpha);
        final next = _SmoothedLandmark(
          index: index,
          point: nextPoint,
          confidence: confidence,
          measured: true,
        );
        _last[index] = next;
        _heldFrames[index] = 0;
        smoothed[index] = next;
      } else if (previous != null &&
          (_heldFrames[index] ?? 0) < _maximumLowConfidenceHoldFrames) {
        final heldCount = (_heldFrames[index] ?? 0) + 1;
        _heldFrames[index] = heldCount;
        final next = _SmoothedLandmark(
          index: index,
          point: previous.point,
          confidence: math.max(0.05, previous.confidence * 0.55),
          measured: false,
        );
        smoothed[index] = next;
      } else {
        smoothed[index] = _SmoothedLandmark(
          index: index,
          point: point,
          confidence: confidence * 0.35,
          measured: false,
        );
      }
    }
    return _SmoothedPose(
      timestampMs: frame.timestampMs,
      landmarks: Map<int, _SmoothedLandmark>.unmodifiable(smoothed),
    );
  }
}

class _RunnerRig {
  final Map<String, _Vec3> joints;
  final double confidence;
  final double bodyHeight;
  final bool isTarget;
  final List<String> modifiedChannels;
  final List<_FootLockDecision> footLocks;
  final Map<String, Object?> orientation;

  const _RunnerRig({
    required this.joints,
    required this.confidence,
    required this.bodyHeight,
    required this.isTarget,
    required this.modifiedChannels,
    required this.footLocks,
    required this.orientation,
  });

  static _RunnerRig? fromSmoothed({
    required RunningPoseFrame frame,
    required _SmoothedPose smoothed,
    required RunningDirection direction,
    required _RetargetMemory memory,
  }) {
    final points = smoothed.landmarks;
    final leftHipRaw = points[23]?.point;
    final rightHipRaw = points[24]?.point;
    final leftShoulderRaw = points[11]?.point;
    final rightShoulderRaw = points[12]?.point;
    if (leftHipRaw == null ||
        rightHipRaw == null ||
        leftShoulderRaw == null ||
        rightShoulderRaw == null) {
      return null;
    }

    final rawHipCenter = _center(leftHipRaw, rightHipRaw)!;
    final rawShoulderCenter = _center(leftShoulderRaw, rightShoulderRaw)!;
    final rawTorso = rawShoulderCenter - rawHipCenter;
    var torsoLean = rawTorso.normalizedOr(const _Vec3(0, 1, 0));
    final leanX = torsoLean.x.clamp(-0.34, 0.34).toDouble();
    torsoLean = _Vec3(
      leanX,
      math.sqrt(math.max(0.0, 1 - leanX * leanX)),
      0,
    ).normalizedOr(const _Vec3(0, 1, 0));

    final leftDepthSign = leftHipRaw.z >= rightHipRaw.z ? 1.0 : -1.0;
    const pelvis = _Vec3(0, 0.92, 0);
    final leftHip =
        pelvis + _Vec3(0, 0, _RunnerModel.hipWidth * leftDepthSign / 2);
    final rightHip =
        pelvis - _Vec3(0, 0, _RunnerModel.hipWidth * leftDepthSign / 2);
    final chest = pelvis + torsoLean * _RunnerModel.torsoLength;
    final leftShoulder =
        chest + _Vec3(0, 0, _RunnerModel.shoulderWidth * leftDepthSign / 2);
    final rightShoulder =
        chest - _Vec3(0, 0, _RunnerModel.shoulderWidth * leftDepthSign / 2);
    final neck = chest + torsoLean * _RunnerModel.neckLength;
    final head = neck + torsoLean * _RunnerModel.headRadius * 1.12;

    final joints = <String, _Vec3>{
      'pelvisCenter': pelvis,
      'leftHip': leftHip,
      'rightHip': rightHip,
      'spine': _Vec3.lerp(pelvis, chest, 0.54),
      'chest': chest,
      'leftShoulder': leftShoulder,
      'rightShoulder': rightShoulder,
      'neck': neck,
      'head': head,
    };

    _addFaceJoints(joints, points, head: head, torsoLean: torsoLean);
    _addLegJoints(
      joints,
      points,
      side: 'left',
      hip: leftHip,
      kneeIndex: 25,
      ankleIndex: 27,
      heelIndex: 29,
      toeIndex: 31,
      leftDepthSign: leftDepthSign,
    );
    _addLegJoints(
      joints,
      points,
      side: 'right',
      hip: rightHip,
      kneeIndex: 26,
      ankleIndex: 28,
      heelIndex: 30,
      toeIndex: 32,
      leftDepthSign: -leftDepthSign,
    );
    _addArmJoints(
      joints,
      points,
      side: 'left',
      shoulder: leftShoulder,
      elbowIndex: 13,
      wristIndex: 15,
      pinkyIndex: 17,
      indexFingerIndex: 19,
      thumbIndex: 21,
      leftDepthSign: leftDepthSign,
    );
    _addArmJoints(
      joints,
      points,
      side: 'right',
      shoulder: rightShoulder,
      elbowIndex: 14,
      wristIndex: 16,
      pinkyIndex: 18,
      indexFingerIndex: 20,
      thumbIndex: 22,
      leftDepthSign: -leftDepthSign,
    );

    final ground = _groundY(joints);
    for (final entry in joints.entries.toList(growable: false)) {
      joints[entry.key] = entry.value - _Vec3(0, ground, 0);
    }

    final leftLock = _footLockDecision(
      side: 'left',
      frame: frame,
      smoothed: smoothed,
      memory: memory,
    );
    final rightLock = _footLockDecision(
      side: 'right',
      frame: frame,
      smoothed: smoothed,
      memory: memory,
    );
    _applyFootLock(joints, 'left', leftLock, memory);
    _applyFootLock(joints, 'right', rightLock, memory);
    memory.rememberFoot('left', joints, leftLock);
    memory.rememberFoot('right', joints, rightLock);

    final confidence = _average(
      points.values.map((landmark) => landmark.confidence),
    );
    final minY = joints.values.map((point) => point.y).reduce(math.min);
    final maxY = joints.values.map((point) => point.y).reduce(math.max);
    return _RunnerRig(
      joints: Map<String, _Vec3>.unmodifiable(joints),
      confidence: confidence,
      bodyHeight: maxY - minY,
      isTarget: false,
      modifiedChannels: const <String>[],
      footLocks: <_FootLockDecision>[leftLock, rightLock],
      orientation: <String, Object?>{
        'torsoAxis': torsoLean.toList(),
        'pelvisDepthSign': leftDepthSign,
        'usesWorldCoordinates':
            frame.landmarks.any((landmark) => landmark.hasWorldCoordinates),
      },
    );
  }

  _RunnerRig asTarget({required List<String> modifiedChannels}) {
    return copyWith(isTarget: true, modifiedChannels: modifiedChannels);
  }

  _RunnerRig copyWith({
    Map<String, _Vec3>? joints,
    bool? isTarget,
    List<String>? modifiedChannels,
  }) {
    return _RunnerRig(
      joints: Map<String, _Vec3>.unmodifiable(joints ?? this.joints),
      confidence: confidence,
      bodyHeight: bodyHeight,
      isTarget: isTarget ?? this.isTarget,
      modifiedChannels: List<String>.unmodifiable(
        modifiedChannels ?? this.modifiedChannels,
      ),
      footLocks: footLocks,
      orientation: orientation,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'isTarget': isTarget,
      'confidence': _round3(confidence),
      'bodyHeight': _round3(bodyHeight),
      'modifiedChannels': modifiedChannels,
      'orientation': orientation,
      'footLocks': footLocks.map((decision) => decision.toMap()).toList(
            growable: false,
          ),
      'joints': <String, Object?>{
        for (final entry in joints.entries) entry.key: entry.value.toList(),
      },
    };
  }
}

void _addFaceJoints(
  Map<String, _Vec3> joints,
  Map<int, _SmoothedLandmark> points, {
  required _Vec3 head,
  required _Vec3 torsoLean,
}) {
  final faceCenter = _weightedPoint(points, const <(int, double)>[
    (0, 2.0),
    (1, 0.45),
    (2, 0.45),
    (3, 0.45),
    (4, 0.45),
    (5, 0.45),
    (6, 0.45),
    (7, 0.70),
    (8, 0.70),
    (9, 0.35),
    (10, 0.35),
  ]);
  final faceDirection =
      (faceCenter ?? const _Vec3(1, 0, 0)).normalizedOr(const _Vec3(1, 0, 0));
  final forward = _Vec3(
    faceDirection.x.sign == 0 ? 1 : faceDirection.x.sign.toDouble(),
    0,
    faceDirection.z.clamp(-0.34, 0.34).toDouble(),
  ).normalizedOr(const _Vec3(1, 0, 0));
  joints['nose'] = head + forward * (_RunnerModel.headRadius * 0.82);
  joints['leftEye'] = head +
      forward * (_RunnerModel.headRadius * 0.56) +
      const _Vec3(0, 0.035, 0.035);
  joints['rightEye'] = head +
      forward * (_RunnerModel.headRadius * 0.56) -
      const _Vec3(0, -0.035, 0.035);
  joints['leftEar'] =
      head + const _Vec3(0, 0.005, _RunnerModel.headRadius * 0.82);
  joints['rightEar'] =
      head - const _Vec3(0, -0.005, _RunnerModel.headRadius * 0.82);
  joints['mouthLeft'] = head +
      forward * (_RunnerModel.headRadius * 0.58) -
      const _Vec3(0, 0.045, -0.032);
  joints['mouthRight'] = head +
      forward * (_RunnerModel.headRadius * 0.58) -
      const _Vec3(0, 0.045, 0.032);
}

void _addLegJoints(
  Map<String, _Vec3> joints,
  Map<int, _SmoothedLandmark> points, {
  required String side,
  required _Vec3 hip,
  required int kneeIndex,
  required int ankleIndex,
  required int heelIndex,
  required int toeIndex,
  required double leftDepthSign,
}) {
  final rawAnkle =
      points[ankleIndex]?.point ?? hip + const _Vec3(0.22, -0.92, 0);
  final rawKnee = points[kneeIndex]?.point ??
      _Vec3.lerp(hip, rawAnkle, 0.52) + _Vec3(0.05, 0, leftDepthSign * 0.10);
  final ankleTarget = _clampReach(
    root: hip,
    end: rawAnkle,
    upperLength: _RunnerModel.thighLength,
    lowerLength: _RunnerModel.shinLength,
  );
  final solved = _solveTwoBone(
    root: hip,
    end: ankleTarget,
    hint: rawKnee,
    upperLength: _RunnerModel.thighLength,
    lowerLength: _RunnerModel.shinLength,
  );
  joints['${side}Knee'] = solved.joint;
  joints['${side}Ankle'] = solved.end;

  final rawHeel = points[heelIndex]?.point;
  final rawToe = points[toeIndex]?.point;
  final footDirection = (rawToe != null && rawHeel != null)
      ? (rawToe - rawHeel).flattenY().normalizedOr(const _Vec3(1, 0, 0))
      : const _Vec3(1, 0, 0);
  joints['${side}Toe'] =
      solved.end + footDirection * (_RunnerModel.footLength * 0.66);
  joints['${side}Heel'] =
      solved.end - footDirection * (_RunnerModel.footLength * 0.40);
}

void _addArmJoints(
  Map<String, _Vec3> joints,
  Map<int, _SmoothedLandmark> points, {
  required String side,
  required _Vec3 shoulder,
  required int elbowIndex,
  required int wristIndex,
  required int pinkyIndex,
  required int indexFingerIndex,
  required int thumbIndex,
  required double leftDepthSign,
}) {
  final rawWrist = points[wristIndex]?.point ??
      shoulder + _Vec3(-0.22, -0.56, leftDepthSign * 0.08);
  final rawElbow = points[elbowIndex]?.point ??
      _Vec3.lerp(shoulder, rawWrist, 0.50) +
          _Vec3(0.04, 0, leftDepthSign * 0.08);
  final wristTarget = _clampReach(
    root: shoulder,
    end: rawWrist,
    upperLength: _RunnerModel.upperArmLength,
    lowerLength: _RunnerModel.forearmLength,
  );
  final solved = _solveTwoBone(
    root: shoulder,
    end: wristTarget,
    hint: rawElbow,
    upperLength: _RunnerModel.upperArmLength,
    lowerLength: _RunnerModel.forearmLength,
  );
  joints['${side}Elbow'] = solved.joint;
  joints['${side}Wrist'] = solved.end;

  final rawHand = _weightedPoint(points, <(int, double)>[
    (pinkyIndex, 0.75),
    (indexFingerIndex, 1.0),
    (thumbIndex, 0.85),
  ]);
  final handDirection =
      (rawHand == null ? rawWrist - shoulder : rawHand - rawWrist)
          .normalizedOr(const _Vec3(1, 0, 0));
  final hand = solved.end + handDirection * _RunnerModel.handLength;
  joints['${side}Hand'] = hand;
  joints['${side}Pinky'] = hand +
      _handAnchorDirection(points[pinkyIndex], rawWrist, handDirection) * 0.055;
  joints['${side}Index'] = hand +
      _handAnchorDirection(points[indexFingerIndex], rawWrist, handDirection) *
          0.070;
  joints['${side}Thumb'] = hand +
      _handAnchorDirection(points[thumbIndex], rawWrist, handDirection) * 0.060;
}

_Vec3 _handAnchorDirection(
  _SmoothedLandmark? landmark,
  _Vec3 wrist,
  _Vec3 fallback,
) {
  if (landmark == null) return fallback;
  return (landmark.point - wrist).normalizedOr(fallback);
}

Map<int, _Vec3> _rawLandmarksFor(
  RunningPoseFrame frame, {
  required RunningDirection direction,
}) {
  final leftHip = frame.landmarkByIndex(23);
  final rightHip = frame.landmarkByIndex(24);
  final leftShoulder = frame.landmarkByIndex(11);
  final rightShoulder = frame.landmarkByIndex(12);
  if (leftHip == null ||
      rightHip == null ||
      leftShoulder == null ||
      rightShoulder == null) {
    return const <int, _Vec3>{};
  }
  final hipX = (leftHip.x + rightHip.x) / 2;
  final hipY = (leftHip.y + rightHip.y) / 2;
  final hipZ = (leftHip.z + rightHip.z) / 2;
  final shoulderX = (leftShoulder.x + rightShoulder.x) / 2;
  final shoulderY = (leftShoulder.y + rightShoulder.y) / 2;
  final rawTorso = math.sqrt(
    math.pow(shoulderX - hipX, 2) + math.pow(shoulderY - hipY, 2),
  );
  final scale = _RunnerModel.torsoLength / math.max(0.035, rawTorso);
  final forward = _visualForward(frame, direction);
  final hipWorldZ = (leftHip.worldZ != null && rightHip.worldZ != null)
      ? (leftHip.worldZ! + rightHip.worldZ!) / 2
      : null;
  return <int, _Vec3>{
    for (final landmark in frame.landmarks)
      landmark.index: _Vec3(
        (landmark.x - hipX) * scale * forward,
        (hipY - landmark.y) * scale,
        _depthFor(landmark, hipZ: hipZ, hipWorldZ: hipWorldZ, scale: scale),
      ),
  };
}

double _depthFor(
  RunningVideoPoseLandmark landmark, {
  required double hipZ,
  required double? hipWorldZ,
  required double scale,
}) {
  final depth = landmark.hasWorldCoordinates && hipWorldZ != null
      ? (landmark.worldZ! - hipWorldZ) * scale
      : (landmark.z - hipZ) * scale * 0.42;
  return depth.clamp(-0.44, 0.44).toDouble();
}

double _visualForward(RunningPoseFrame frame, RunningDirection direction) {
  final nose = frame.landmarkByIndex(0);
  final leftShoulder = frame.landmarkByIndex(11);
  final rightShoulder = frame.landmarkByIndex(12);
  if (nose != null && leftShoulder != null && rightShoulder != null) {
    final shoulderX = (leftShoulder.x + rightShoulder.x) / 2;
    final offset = nose.x - shoulderX;
    if (offset.abs() > 0.018) return offset.isNegative ? -1 : 1;
  }
  return switch (direction) {
    RunningDirection.leftToRight => 1,
    RunningDirection.rightToLeft => -1,
    RunningDirection.stationary => 1,
  };
}

_FootLockDecision _footLockDecision({
  required String side,
  required RunningPoseFrame frame,
  required _SmoothedPose smoothed,
  required _RetargetMemory memory,
}) {
  final indices =
      side == 'left' ? const <int>[27, 29, 31] : const <int>[28, 30, 32];
  final points = <_SmoothedLandmark>[
    for (final index in indices)
      if (smoothed.landmarks[index] case final landmark?) landmark,
  ];
  if (points.isEmpty) {
    return _FootLockDecision(side: side, locked: false, confidence: 0);
  }
  final confidence = _average(points.map((point) => point.confidence));
  final footCenter = _averagePoint(points.map((point) => point.point));
  final allFootPoints = <_SmoothedLandmark>[
    for (final index in const <int>[27, 28, 29, 30, 31, 32])
      if (smoothed.landmarks[index] case final landmark?) landmark,
  ];
  final groundY = allFootPoints.isEmpty
      ? footCenter.y
      : allFootPoints.map((point) => point.point.y).reduce(math.min);
  final distanceToGround = footCenter.y - groundY;
  final previous = memory.rawFootCenters[side];
  final previousTimestamp = memory.previousFootTimestampMs[side];
  final elapsedMs = previousTimestamp == null
      ? 33
      : math.max(1, frame.timestampMs - previousTimestamp);
  final velocity = previous == null
      ? 0.0
      : (footCenter - previous).length / (elapsedMs / 33.0);
  memory.rawFootCenters[side] = footCenter;
  memory.previousFootTimestampMs[side] = frame.timestampMs;
  final locked = confidence >= 0.45 &&
      distanceToGround <= 0.20 &&
      (previous == null || velocity <= 0.075);
  return _FootLockDecision(
    side: side,
    locked: locked,
    confidence: confidence,
    velocity: velocity,
    distanceToGround: distanceToGround,
  );
}

void _applyFootLock(
  Map<String, _Vec3> joints,
  String side,
  _FootLockDecision decision,
  _RetargetMemory memory,
) {
  if (!decision.locked) return;
  final previous = memory.lockedFeet[side];
  final toe = joints['${side}Toe'];
  final heel = joints['${side}Heel'];
  final ankle = joints['${side}Ankle'];
  final hip = joints['${side}Hip'];
  if (previous == null ||
      toe == null ||
      heel == null ||
      ankle == null ||
      hip == null) {
    return;
  }
  final delta = previous.toe - toe;
  final nextAnkle = ankle + delta;
  final solved = _solveTwoBone(
    root: hip,
    end: _clampReach(
      root: hip,
      end: nextAnkle,
      upperLength: _RunnerModel.thighLength,
      lowerLength: _RunnerModel.shinLength,
    ),
    hint: joints['${side}Knee'] ?? nextAnkle,
    upperLength: _RunnerModel.thighLength,
    lowerLength: _RunnerModel.shinLength,
  );
  joints['${side}Knee'] = solved.joint;
  joints['${side}Ankle'] = solved.end;
  joints['${side}Toe'] = previous.toe;
  joints['${side}Heel'] = previous.heel;
}

Map<String, Object?> _sourceLandmarkMap(RunningVideoPoseLandmark landmark) {
  return <String, Object?>{
    'index': landmark.index,
    'x': landmark.x,
    'y': landmark.y,
    'z': landmark.z,
    'visibility': landmark.visibility,
    'presence': landmark.presence,
    'confidence': landmark.confidence,
    if (landmark.hasWorldCoordinates) ...<String, Object?>{
      'worldX': landmark.worldX,
      'worldY': landmark.worldY,
      'worldZ': landmark.worldZ,
    },
    'worldVisibility': landmark.worldVisibility,
    'worldPresence': landmark.worldPresence,
    'worldConfidence': landmark.worldConfidence,
  };
}

List<RunningPoseFrame> _sampleFrames(
  Iterable<RunningPoseFrame> poseFrames,
  RunningPoseFrame selectedFrame,
) {
  final byTimestamp = <int, RunningPoseFrame>{
    for (final frame in poseFrames) frame.timestampMs: frame,
    selectedFrame.timestampMs: selectedFrame,
  };
  final ordered = byTimestamp.values.toList(growable: false)
    ..sort((a, b) => a.timestampMs.compareTo(b.timestampMs));
  if (ordered.length <= _maximumRetargetFrameCount) {
    return List<RunningPoseFrame>.unmodifiable(ordered);
  }
  final selected = <int>{0, ordered.length - 1};
  final selectedIndex = ordered
      .indexWhere((frame) => frame.timestampMs == selectedFrame.timestampMs);
  if (selectedIndex >= 0) selected.add(selectedIndex);
  for (var slot = 1;
      selected.length < _maximumRetargetFrameCount &&
          slot < _maximumRetargetFrameCount - 1;
      slot += 1) {
    selected.add(
        ((ordered.length - 1) * slot / (_maximumRetargetFrameCount - 1))
            .round());
  }
  final indices = selected.toList(growable: false)..sort();
  return List<RunningPoseFrame>.unmodifiable(
      indices.map((index) => ordered[index]));
}

int _nearestFrameIndex(
  List<_RunningThreeDRunnerFrame> frames, {
  required int selectedTimestampMs,
}) {
  if (frames.isEmpty) return 0;
  var nearest = 0;
  var distance = (frames.first.timestampMs - selectedTimestampMs).abs();
  for (var index = 1; index < frames.length; index += 1) {
    final candidate = (frames[index].timestampMs - selectedTimestampMs).abs();
    if (candidate < distance) {
      nearest = index;
      distance = candidate;
    }
  }
  return nearest;
}

class _SmoothedPose {
  final int timestampMs;
  final Map<int, _SmoothedLandmark> landmarks;

  const _SmoothedPose({
    required this.timestampMs,
    required this.landmarks,
  });
}

class _SmoothedLandmark {
  final int index;
  final _Vec3 point;
  final double confidence;
  final bool measured;

  const _SmoothedLandmark({
    required this.index,
    required this.point,
    required this.confidence,
    required this.measured,
  });
}

class _FootLockDecision {
  final String side;
  final bool locked;
  final double confidence;
  final double velocity;
  final double distanceToGround;

  const _FootLockDecision({
    required this.side,
    required this.locked,
    required this.confidence,
    this.velocity = 0,
    this.distanceToGround = 0,
  });

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'side': side,
      'locked': locked,
      'confidence': _round3(confidence),
      'velocity': _round3(velocity),
      'distanceToGround': _round3(distanceToGround),
    };
  }
}

class _RetargetMemory {
  final Map<String, _Vec3> rawFootCenters = <String, _Vec3>{};
  final Map<String, _LockedFoot> lockedFeet = <String, _LockedFoot>{};
  final Map<String, int> previousFootTimestampMs = <String, int>{};

  void rememberFoot(
    String side,
    Map<String, _Vec3> joints,
    _FootLockDecision decision,
  ) {
    if (!decision.locked) {
      lockedFeet.remove(side);
      return;
    }
    final toe = joints['${side}Toe'];
    final heel = joints['${side}Heel'];
    if (toe == null || heel == null) return;
    lockedFeet[side] = _LockedFoot(toe: toe, heel: heel);
  }
}

class _LockedFoot {
  final _Vec3 toe;
  final _Vec3 heel;

  const _LockedFoot({
    required this.toe,
    required this.heel,
  });
}

class _RunnerModel {
  static const torsoLength = 0.66;
  static const neckLength = 0.10;
  static const headRadius = 0.125;
  static const shoulderWidth = 0.38;
  static const hipWidth = 0.27;
  static const thighLength = 0.52;
  static const shinLength = 0.52;
  static const footLength = 0.25;
  static const upperArmLength = 0.33;
  static const forearmLength = 0.31;
  static const handLength = 0.105;
}

class _IkResult {
  final _Vec3 joint;
  final _Vec3 end;

  const _IkResult({required this.joint, required this.end});
}

_IkResult _solveTwoBone({
  required _Vec3 root,
  required _Vec3 end,
  required _Vec3 hint,
  required double upperLength,
  required double lowerLength,
}) {
  final clampedEnd = _clampReach(
    root: root,
    end: end,
    upperLength: upperLength,
    lowerLength: lowerLength,
  );
  final direct = clampedEnd - root;
  final distance = direct.length;
  if (distance < 0.0001) {
    return _IkResult(joint: root + _Vec3(0, -upperLength, 0), end: clampedEnd);
  }
  final axis = direct / distance;
  final projection = ((upperLength * upperLength) -
          (lowerLength * lowerLength) +
          (distance * distance)) /
      (2 * distance);
  final height = math.sqrt(math.max(
    0,
    upperLength * upperLength - projection * projection,
  ));
  final hintVector = hint - root;
  var bend = hintVector - axis * hintVector.dot(axis);
  if (bend.length < 0.0001) {
    bend = axis.cross(const _Vec3(0, 0, 1));
  }
  if (bend.length < 0.0001) {
    bend = axis.cross(const _Vec3(0, 1, 0));
  }
  final joint = root + axis * projection + bend.normalized * height;
  return _IkResult(joint: joint, end: clampedEnd);
}

_Vec3 _clampReach({
  required _Vec3 root,
  required _Vec3 end,
  required double upperLength,
  required double lowerLength,
}) {
  final vector = end - root;
  final distance = vector.length;
  if (distance < 0.0001) {
    return root + _Vec3(0, -(upperLength + lowerLength), 0);
  }
  final maxReach = upperLength + lowerLength - 0.001;
  final minReach = (upperLength - lowerLength).abs() + 0.001;
  final clamped = distance.clamp(minReach, maxReach).toDouble();
  return root + vector / distance * clamped;
}

_Vec3 _pointAtJointAngle({
  required _Vec3 root,
  required _Vec3 joint,
  required _Vec3 end,
  required double targetDegrees,
  required double turnSign,
}) {
  final upper = (root - joint).normalizedOr(const _Vec3(0, 1, 0));
  final lowerLength = (end - joint).length;
  final radians = targetDegrees * math.pi / 180;
  final baseAngle = math.atan2(upper.y, upper.x);
  final nextAngle = baseAngle + turnSign * (math.pi - radians);
  return joint +
      _Vec3(math.cos(nextAngle), math.sin(nextAngle), upper.z) * lowerLength;
}

String _leadLegSide(Map<String, _Vec3> joints) {
  final leftToe = joints['leftToe'];
  final rightToe = joints['rightToe'];
  if (leftToe == null || rightToe == null) return 'left';
  return leftToe.x >= rightToe.x ? 'left' : 'right';
}

String _leadArmSide(Map<String, _Vec3> joints) {
  final leftWrist = joints['leftWrist'];
  final rightWrist = joints['rightWrist'];
  if (leftWrist == null || rightWrist == null) return 'left';
  return leftWrist.x >= rightWrist.x ? 'left' : 'right';
}

_Vec3? _center(_Vec3? first, _Vec3? second) {
  if (first == null || second == null) return null;
  return _Vec3.lerp(first, second, 0.5);
}

_Vec3? _weightedPoint(
  Map<int, _SmoothedLandmark> points,
  List<(int, double)> weightedIndices,
) {
  var totalWeight = 0.0;
  var total = _Vec3.zero;
  for (final (index, weight) in weightedIndices) {
    final point = points[index];
    if (point == null) continue;
    total += point.point * weight;
    totalWeight += weight;
  }
  if (totalWeight <= 0) return null;
  return total / totalWeight;
}

_Vec3 _averagePoint(Iterable<_Vec3> points) {
  var count = 0;
  var total = _Vec3.zero;
  for (final point in points) {
    total += point;
    count += 1;
  }
  return count == 0 ? _Vec3.zero : total / count.toDouble();
}

double _groundY(Map<String, _Vec3> joints) {
  final contacts = <_Vec3>[
    if (joints['leftAnkle'] case final point?) point,
    if (joints['rightAnkle'] case final point?) point,
    if (joints['leftHeel'] case final point?) point,
    if (joints['rightHeel'] case final point?) point,
    if (joints['leftToe'] case final point?) point,
    if (joints['rightToe'] case final point?) point,
  ];
  if (contacts.isEmpty) return 0;
  return contacts.map((point) => point.y).reduce(math.min);
}

double _landmarkConfidence(RunningVideoPoseLandmark landmark) {
  final worldConfidence = landmark.worldConfidence;
  final confidence = worldConfidence == null
      ? landmark.confidence
      : math.min(landmark.confidence, worldConfidence);
  return confidence.clamp(0.0, 1.0).toDouble();
}

double _average(Iterable<double> values) {
  var total = 0.0;
  var count = 0;
  for (final value in values) {
    if (!value.isFinite) continue;
    total += value;
    count += 1;
  }
  return count == 0 ? 0 : total / count;
}

double _round3(double value) {
  if (!value.isFinite) return 0;
  return (value * 1000).roundToDouble() / 1000;
}

const _upperBodyJointNames = <String>[
  'spine',
  'chest',
  'leftShoulder',
  'rightShoulder',
  'neck',
  'head',
  'nose',
  'leftEye',
  'rightEye',
  'leftEar',
  'rightEar',
  'mouthLeft',
  'mouthRight',
  'leftElbow',
  'rightElbow',
  'leftWrist',
  'rightWrist',
  'leftHand',
  'rightHand',
  'leftPinky',
  'rightPinky',
  'leftIndex',
  'rightIndex',
  'leftThumb',
  'rightThumb',
];

const _wholeBodyJointNames = <String>[
  'pelvisCenter',
  'leftHip',
  'rightHip',
  'spine',
  'chest',
  'leftShoulder',
  'rightShoulder',
  'neck',
  'head',
  'leftKnee',
  'rightKnee',
  'leftAnkle',
  'rightAnkle',
  'leftHeel',
  'rightHeel',
  'leftToe',
  'rightToe',
];

class _Vec3 {
  final double x;
  final double y;
  final double z;

  const _Vec3(this.x, this.y, this.z);

  static const zero = _Vec3(0, 0, 0);

  double get length => math.sqrt(x * x + y * y + z * z);

  _Vec3 get normalized => this / length;

  _Vec3 normalizedOr(_Vec3 fallback) {
    final len = length;
    if (!len.isFinite || len < 0.0001) return fallback;
    return this / len;
  }

  _Vec3 flattenY() => _Vec3(x, 0, z);

  double dot(_Vec3 other) => x * other.x + y * other.y + z * other.z;

  _Vec3 cross(_Vec3 other) {
    return _Vec3(
      y * other.z - z * other.y,
      z * other.x - x * other.z,
      x * other.y - y * other.x,
    );
  }

  _Vec3 rotateAroundZ(_Vec3 origin, double radians) {
    final point = this - origin;
    final cos = math.cos(radians);
    final sin = math.sin(radians);
    return origin +
        _Vec3(point.x * cos - point.y * sin, point.x * sin + point.y * cos,
            point.z);
  }

  List<double> toList() => <double>[_round3(x), _round3(y), _round3(z)];

  static _Vec3 lerp(_Vec3 first, _Vec3 second, double t) {
    return first + (second - first) * t;
  }

  _Vec3 operator +(_Vec3 other) => _Vec3(x + other.x, y + other.y, z + other.z);

  _Vec3 operator -(_Vec3 other) => _Vec3(x - other.x, y - other.y, z - other.z);

  _Vec3 operator -() => _Vec3(-x, -y, -z);

  _Vec3 operator *(double scale) => _Vec3(x * scale, y * scale, z * scale);

  _Vec3 operator /(double scale) => _Vec3(x / scale, y / scale, z / scale);
}
