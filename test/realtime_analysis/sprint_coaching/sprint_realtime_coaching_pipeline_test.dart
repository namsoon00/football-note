import 'dart:ui' show Offset, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/entities/sprint_pose_frame.dart';
import 'package:football_note/domain/entities/sprint_realtime_coaching_state.dart';
import 'package:football_note/realtime_analysis/sprint_coaching/sprint_pipeline_config.dart';
import 'package:football_note/realtime_analysis/sprint_coaching/sprint_realtime_coaching_pipeline.dart';

void main() {
  group('SprintRealtimeCoachingPipeline', () {
    test('keeps the active cue until cooldown expires', () {
      final pipeline = SprintRealtimeCoachingPipeline(
        config: _scenarioConfig().copyWith(
          analysisWindow: const Duration(milliseconds: 400),
          feedbackCooldown: const Duration(milliseconds: 1800),
          minimumWindowFrames: 4,
        ),
      );
      final start = DateTime(2026, 4, 13, 9);

      var state = const SprintRealtimeCoachingState.initial();

      for (var index = 0; index < 4; index += 1) {
        state = pipeline.ingest(
          _poseFrame(
            timestamp: start.add(Duration(milliseconds: 120 * index)),
            hipCenterX: 220.0 + (30 * index),
            trunkLeanX: 0.08,
            kneeDriveHeight: 0.36,
            leftAnkleX: index.isEven ? 0.22 : -0.22,
            rightAnkleX: index.isEven ? -0.22 : 0.22,
          ),
        );
      }

      expect(state.status, SprintCoachingStatus.coaching);
      expect(state.feedback?.code, SprintFeedbackCode.leanForwardMore);
      expect(state.features.trunkAngleDegrees, lessThan(8));

      for (var index = 0; index < 4; index += 1) {
        state = pipeline.ingest(
          _poseFrame(
            timestamp: start.add(Duration(milliseconds: 480 + (120 * index))),
            hipCenterX: 360.0 + (30 * index),
            trunkLeanX: 0.22,
            kneeDriveHeight: 0.04,
            leftAnkleX: index.isEven ? 0.24 : -0.24,
            rightAnkleX: index.isEven ? -0.24 : 0.24,
          ),
        );
      }

      expect(state.features.trunkAngleDegrees, greaterThan(8));
      expect(state.stateEstimate.feedbackCooldownActive, isTrue);
      expect(state.feedback?.code, SprintFeedbackCode.leanForwardMore);
      expect(state.feedbackSwitchSuppressedByCooldown, isTrue);

      for (var index = 0; index < 4; index += 1) {
        state = pipeline.ingest(
          _poseFrame(
            timestamp: start.add(Duration(milliseconds: 2400 + (120 * index))),
            hipCenterX: 520.0 + (30 * index),
            trunkLeanX: 0.22,
            kneeDriveHeight: 0.04,
            leftAnkleX: index.isEven ? 0.24 : -0.24,
            rightAnkleX: index.isEven ? -0.24 : 0.24,
          ),
        );
      }

      expect(state.stateEstimate.feedbackCooldownActive, isFalse);
      expect(
        state.features.kneeDriveHeightRatio,
        lessThan(_scenarioConfig().minimumKneeDriveHeight),
      );
      expect(state.feedback?.code, SprintFeedbackCode.driveKneeHigher);
    });

    test(
      'locks a normal sprint into keep-pushing guidance with stable ranges',
      () {
        final state = _runScenario(
          config: _scenarioConfig(),
          start: DateTime(2026, 4, 13, 9),
          frames: _sequence(
            offsetsMs: const <int>[0, 220, 440, 660, 880, 1100],
            hipCenterXs: const <double>[220, 260, 300, 340, 380, 420],
            trunkLeanX: 0.22,
            kneeDriveHeight: 0.36,
          ),
        );

        expect(state.stateEstimate.runningDetected, isTrue);
        expect(state.feedback?.code, SprintFeedbackCode.keepPushing);
        expect(state.features.trunkAngleDegrees, inInclusiveRange(10.0, 15.0));
        expect(
          state.features.kneeDriveHeightRatio,
          greaterThanOrEqualTo(_scenarioConfig().minimumKneeDriveHeight),
        );
        expect(
          state.features.cadenceStepsPerMinute,
          greaterThan(_scenarioConfig().minimumRunningCadenceStepsPerMinute),
        );
        expect(
          state.features.stepIntervalStdMs,
          lessThan(_scenarioConfig().maximumStepIntervalStdMs),
        );
        expect(
          state.features.armSwingAsymmetryRatio,
          lessThan(_scenarioConfig().maximumArmAsymmetryRatio),
        );
      },
    );

    test('keeps slow jogging out of sprint feedback mode', () {
      final config = _scenarioConfig().copyWith(
        analysisWindow: const Duration(milliseconds: 2400),
      );
      final state = _runScenario(
        config: config,
        start: DateTime(2026, 4, 13, 9),
        frames: _sequence(
          offsetsMs: const <int>[0, 420, 840, 1260, 1680, 2100],
          hipCenterXs: const <double>[220, 250, 280, 310, 340, 370],
          trunkLeanX: 0.19,
          kneeDriveHeight: 0.31,
        ),
      );

      expect(state.features.detectedStepEvents, greaterThanOrEqualTo(3));
      expect(
        state.features.cadenceStepsPerMinute,
        lessThan(config.minimumRunningCadenceStepsPerMinute),
      );
      expect(state.stateEstimate.runningDetected, isFalse);
      expect(state.status, SprintCoachingStatus.collecting);
      expect(state.feedback, isNull);
    });

    test('keeps in-place low-travel motion out of running mode', () {
      final state = _runScenario(
        config: _scenarioConfig().copyWith(
          analysisWindow: const Duration(milliseconds: 800),
        ),
        start: DateTime(2026, 4, 13, 9),
        frames: _sequence(
          offsetsMs: const <int>[0, 120, 240, 360, 480, 600],
          hipCenterXs: const <double>[320, 321, 322, 323, 324, 325],
          trunkLeanX: 0.2,
          kneeDriveHeight: 0.34,
          leftAnkleXs: const <double>[0.34, -0.34, 0.34, -0.34, 0.34, -0.34],
          rightAnkleXs: const <double>[-0.34, 0.34, -0.34, 0.34, -0.34, 0.34],
        ),
      );

      expect(state.stateEstimate.bodyFullyVisible, isTrue);
      expect(state.stateEstimate.lowConfidence, isFalse);
      expect(state.features.detectedStepEvents, greaterThanOrEqualTo(3));
      expect(state.stateEstimate.hipTravelRatio, lessThan(0.04));
      expect(state.stateEstimate.runningDetected, isFalse);
      expect(state.status, SprintCoachingStatus.collecting);
      expect(state.feedback, isNull);
    });

    test('marks partial landmark loss as body-not-visible diagnostics', () {
      final state = _runScenario(
        config: _scenarioConfig().copyWith(
          analysisWindow: const Duration(milliseconds: 400),
          minimumWindowFrames: 4,
        ),
        start: DateTime(2026, 4, 13, 9),
        frames: const <_SyntheticSprintFrame>[
          _SyntheticSprintFrame(
            offsetMs: 0,
            hipCenterX: 450,
            trunkLeanX: 0.18,
            kneeDriveHeight: 0.3,
            leftAnkleX: 0.2,
            rightAnkleX: -0.2,
            missingLandmarks: <SprintPoseLandmarkType>{
              SprintPoseLandmarkType.leftElbow,
              SprintPoseLandmarkType.rightElbow,
              SprintPoseLandmarkType.leftWrist,
              SprintPoseLandmarkType.rightWrist,
              SprintPoseLandmarkType.leftKnee,
              SprintPoseLandmarkType.rightKnee,
              SprintPoseLandmarkType.leftAnkle,
              SprintPoseLandmarkType.rightAnkle,
            },
          ),
        ],
      );

      expect(state.status, SprintCoachingStatus.lowConfidence);
      expect(
        state.stateEstimate.bodyVisibilityStatus,
        SprintBodyVisibilityStatus.partial,
      );
      expect(state.stateEstimate.visibleCoreLandmarkCount, 4);
      expect(state.stateEstimate.missingCoreLandmarkCount, 8);
      expect(state.stateEstimate.bodyVisibilityRatio, closeTo(4 / 12, 0.001));
      expect(state.feedback?.code, SprintFeedbackCode.bodyNotVisible);
    });

    test('surfaces lean-forward feedback for insufficient trunk angle', () {
      final state = _runScenario(
        config: _scenarioConfig(),
        start: DateTime(2026, 4, 13, 9),
        frames: _sequence(
          offsetsMs: const <int>[0, 220, 440, 660, 880, 1100],
          hipCenterXs: const <double>[220, 260, 300, 340, 380, 420],
          trunkLeanX: 0.08,
          kneeDriveHeight: 0.36,
        ),
      );

      expect(state.stateEstimate.runningDetected, isTrue);
      expect(state.feedback?.code, SprintFeedbackCode.leanForwardMore);
      expect(
        state.features.trunkAngleDegrees,
        lessThan(_scenarioConfig().minimumTrunkAngleDegrees),
      );
    });

    test('surfaces knee-drive feedback for insufficient knee height', () {
      final state = _runScenario(
        config: _scenarioConfig(),
        start: DateTime(2026, 4, 13, 9),
        frames: _sequence(
          offsetsMs: const <int>[0, 220, 440, 660, 880, 1100],
          hipCenterXs: const <double>[220, 260, 300, 340, 380, 420],
          trunkLeanX: 0.22,
          kneeDriveHeight: 0.08,
        ),
      );

      expect(state.stateEstimate.runningDetected, isTrue);
      expect(state.feedback?.code, SprintFeedbackCode.driveKneeHigher);
      expect(
        state.features.kneeDriveHeightRatio,
        lessThan(_scenarioConfig().minimumKneeDriveHeight),
      );
    });

    test('surfaces rhythm feedback for irregular step timing', () {
      final state = _runScenario(
        config: _scenarioConfig().copyWith(
          analysisWindow: const Duration(milliseconds: 1400),
        ),
        start: DateTime(2026, 4, 13, 9),
        frames: _sequence(
          offsetsMs: const <int>[0, 140, 520, 660, 1040, 1180],
          hipCenterXs: const <double>[220, 260, 300, 340, 380, 420],
          trunkLeanX: 0.22,
          kneeDriveHeight: 0.36,
        ),
      );

      expect(state.stateEstimate.runningDetected, isTrue);
      expect(state.feedback?.code, SprintFeedbackCode.keepRhythmSteady);
      expect(
        state.features.stepIntervalStdMs,
        greaterThan(_scenarioConfig().maximumStepIntervalStdMs),
      );
    });

    test('surfaces arm-balance feedback for asymmetric arm swing', () {
      final state = _runScenario(
        config: _scenarioConfig(),
        start: DateTime(2026, 4, 13, 9),
        frames: _sequence(
          offsetsMs: const <int>[0, 220, 440, 660, 880, 1100],
          hipCenterXs: const <double>[220, 260, 300, 340, 380, 420],
          trunkLeanX: 0.22,
          kneeDriveHeight: 0.36,
          leftWristReach: 0.08,
          rightWristReach: 0.46,
        ),
      );

      expect(state.stateEstimate.runningDetected, isTrue);
      expect(state.feedback?.code, SprintFeedbackCode.balanceArmSwing);
      expect(
        state.features.armSwingAsymmetryRatio,
        greaterThan(_scenarioConfig().maximumArmAsymmetryRatio),
      );
    });
  });
}

SprintPipelineConfig _scenarioConfig() {
  return const SprintPipelineConfig(
    analysisWindow: Duration(milliseconds: 1400),
    minimumWindowFrames: 5,
    smoothingFactor: 1,
  );
}

SprintRealtimeCoachingState _runScenario({
  required SprintPipelineConfig config,
  required DateTime start,
  required List<_SyntheticSprintFrame> frames,
}) {
  final pipeline = SprintRealtimeCoachingPipeline(config: config);
  var state = const SprintRealtimeCoachingState.initial();

  for (final frame in frames) {
    state = pipeline.ingest(
      _poseFrame(
        timestamp: start.add(Duration(milliseconds: frame.offsetMs)),
        hipCenterX: frame.hipCenterX,
        trunkLeanX: frame.trunkLeanX,
        kneeDriveHeight: frame.kneeDriveHeight,
        leftAnkleX: frame.leftAnkleX,
        rightAnkleX: frame.rightAnkleX,
        leftWristReach: frame.leftWristReach,
        rightWristReach: frame.rightWristReach,
        missingLandmarks: frame.missingLandmarks,
      ),
    );
  }

  return state;
}

List<_SyntheticSprintFrame> _sequence({
  required List<int> offsetsMs,
  required List<double> hipCenterXs,
  required double trunkLeanX,
  required double kneeDriveHeight,
  List<double>? leftAnkleXs,
  List<double>? rightAnkleXs,
  double leftWristReach = 0.42,
  double rightWristReach = 0.44,
}) {
  expect(offsetsMs.length, hipCenterXs.length);
  final resolvedLeftAnkles =
      leftAnkleXs ??
      List<double>.generate(
        offsetsMs.length,
        (index) => index.isEven ? 0.24 : -0.24,
      );
  final resolvedRightAnkles =
      rightAnkleXs ??
      List<double>.generate(
        offsetsMs.length,
        (index) => index.isEven ? -0.24 : 0.24,
      );

  return List<_SyntheticSprintFrame>.generate(offsetsMs.length, (index) {
    return _SyntheticSprintFrame(
      offsetMs: offsetsMs[index],
      hipCenterX: hipCenterXs[index],
      trunkLeanX: trunkLeanX,
      kneeDriveHeight: kneeDriveHeight,
      leftAnkleX: resolvedLeftAnkles[index],
      rightAnkleX: resolvedRightAnkles[index],
      leftWristReach: leftWristReach,
      rightWristReach: rightWristReach,
    );
  });
}

class _SyntheticSprintFrame {
  final int offsetMs;
  final double hipCenterX;
  final double trunkLeanX;
  final double kneeDriveHeight;
  final double leftAnkleX;
  final double rightAnkleX;
  final double leftWristReach;
  final double rightWristReach;
  final Set<SprintPoseLandmarkType> missingLandmarks;

  const _SyntheticSprintFrame({
    required this.offsetMs,
    required this.hipCenterX,
    required this.trunkLeanX,
    required this.kneeDriveHeight,
    required this.leftAnkleX,
    required this.rightAnkleX,
    this.leftWristReach = 0.42,
    this.rightWristReach = 0.44,
    this.missingLandmarks = const <SprintPoseLandmarkType>{},
  });
}

SprintPoseFrame _poseFrame({
  required DateTime timestamp,
  required double hipCenterX,
  required double trunkLeanX,
  required double kneeDriveHeight,
  required double leftAnkleX,
  required double rightAnkleX,
  double leftWristReach = 0.42,
  double rightWristReach = 0.44,
  Set<SprintPoseLandmarkType> missingLandmarks =
      const <SprintPoseLandmarkType>{},
}) {
  const imageSize = Size(1000, 1000);
  const scale = 180.0;
  const hipCenterY = 500.0;

  Offset point(double normalizedX, double normalizedY) {
    return Offset(
      hipCenterX + (normalizedX * scale),
      hipCenterY + (normalizedY * scale),
    );
  }

  final leftShoulderX = trunkLeanX - 0.18;
  final rightShoulderX = trunkLeanX + 0.18;
  final landmarks = <SprintPoseLandmarkType, SprintPoseLandmark>{
    SprintPoseLandmarkType.leftShoulder: _landmarkFromOffset(
      point(leftShoulderX, -1),
    ),
    SprintPoseLandmarkType.rightShoulder: _landmarkFromOffset(
      point(rightShoulderX, -1),
    ),
    SprintPoseLandmarkType.leftElbow: _landmarkFromOffset(
      point(leftShoulderX - 0.1, -0.62),
    ),
    SprintPoseLandmarkType.rightElbow: _landmarkFromOffset(
      point(rightShoulderX + 0.1, -0.62),
    ),
    SprintPoseLandmarkType.leftWrist: _landmarkFromOffset(
      point(leftShoulderX - leftWristReach, -0.28),
    ),
    SprintPoseLandmarkType.rightWrist: _landmarkFromOffset(
      point(rightShoulderX + rightWristReach, -0.28),
    ),
    SprintPoseLandmarkType.leftHip: _landmarkFromOffset(point(-0.14, 0)),
    SprintPoseLandmarkType.rightHip: _landmarkFromOffset(point(0.14, 0)),
    SprintPoseLandmarkType.leftKnee: _landmarkFromOffset(point(-0.16, -0.18)),
    SprintPoseLandmarkType.rightKnee: _landmarkFromOffset(
      point(0.16, -kneeDriveHeight),
    ),
    SprintPoseLandmarkType.leftAnkle: _landmarkFromOffset(point(leftAnkleX, 1)),
    SprintPoseLandmarkType.rightAnkle: _landmarkFromOffset(
      point(rightAnkleX, 1),
    ),
  };

  landmarks.removeWhere((type, _) => missingLandmarks.contains(type));

  return SprintPoseFrame(
    imageSize: imageSize,
    timestamp: timestamp,
    landmarks: landmarks,
  );
}

SprintPoseLandmark _landmarkFromOffset(Offset offset) {
  return SprintPoseLandmark(position: offset, confidence: 0.98);
}
