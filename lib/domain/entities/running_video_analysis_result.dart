import 'dart:math' as math;

import 'running_analysis_measurement.dart';

export 'running_analysis_measurement.dart';

enum RunningDirection { leftToRight, rightToLeft, stationary }

enum RunningContactSide { left, right, unknown }

enum RunningCoachMetric {
  posture,
  bounce,
  footStrike,
  kneeFlexion,
  armCarriage,
}

enum RunningCoachBodyRegion { upperBody, lowerBody, wholeBody }

enum RunningCoachStatus { good, watch, needsWork }

enum RunningCoachScoreStatus { confirmed, estimated, unavailable }

enum RunningMetricEvidenceKind { rhythm, posture, landing, knee, bounce, arms }

enum RunningMetricEvidenceFrameRole {
  rhythmContact,
  representativePosture,
  lowering,
  initialContact,
  maximumKneeFlexion,
  recoveryKneeFlexion,
  pushOff,
  trajectoryHigh,
  trajectoryLow,
  armClosed,
  armOpen,
}

enum RunningMetricEvidenceWithheldReason {
  lowConfidence,
  limitedSamples,
  missingPoseFrames,
  missingContact,
  missingMeasuredFrames,
}

enum RunningVideoQualityIssue {
  tooSmall,
  notSideOn,
  bodyCutOff,
  scaleDrift,
  multiplePerson,
  targetIdentityUnstable,
}

enum RunningCoachFinding {
  postureAligned,
  postureTooUpright,
  postureTooLean,
  bounceEfficient,
  bounceTooHigh,
  footStrikeUnderBody,
  footStrikeOverstride,
  kneeFlexionLoaded,
  kneeTooStraight,
  kneeTooCollapsed,
  armCompact,
  armTooOpen,
  armTooTight,
}

const int mediaPipePoseLandmarkCount = 33;
const double runningCoachReliableMetricConfidence = 0.65;
const int runningCoachMinimumReliableMetricSamples = 3;
const double _runningMinimumLandmarkConfidence = 0.35;
const Duration _runningBounceResampleInterval = Duration(milliseconds: 50);
const Duration _runningBounceWindow = Duration(milliseconds: 800);
const Duration _runningBounceWindowStep = Duration(milliseconds: 400);

class RunningVideoPoseLandmark {
  final int index;
  final double x;
  final double y;
  final double z;
  final double? visibility;
  final double? presence;
  final double confidence;
  final double? worldX;
  final double? worldY;
  final double? worldZ;
  final double? worldVisibility;
  final double? worldPresence;
  final double? worldConfidence;

  const RunningVideoPoseLandmark({
    required this.index,
    required this.x,
    required this.y,
    required this.z,
    required this.visibility,
    required this.presence,
    required this.confidence,
    this.worldX,
    this.worldY,
    this.worldZ,
    this.worldVisibility,
    this.worldPresence,
    this.worldConfidence,
  });

  bool get hasWorldCoordinates =>
      worldX != null && worldY != null && worldZ != null;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'index': index,
      'x': x,
      'y': y,
      'z': z,
      if (visibility != null) 'visibility': visibility,
      if (presence != null) 'presence': presence,
      'confidence': confidence,
      if (hasWorldCoordinates) ...<String, Object?>{
        'worldX': worldX,
        'worldY': worldY,
        'worldZ': worldZ,
      },
      if (worldVisibility != null) 'worldVisibility': worldVisibility,
      if (worldPresence != null) 'worldPresence': worldPresence,
      if (worldConfidence != null) 'worldConfidence': worldConfidence,
    };
  }

  static RunningVideoPoseLandmark? fromObject(Object? raw) {
    final map = _asObjectMap(raw);
    if (map == null) return null;
    final index = _finiteInt(map['index']);
    final x = _finiteDouble(map['x']);
    final y = _finiteDouble(map['y']);
    final z = _finiteDouble(map['z']);
    final confidence = _finiteDouble(map['confidence']);
    if (index == null ||
        index < 0 ||
        index >= mediaPipePoseLandmarkCount ||
        x == null ||
        y == null ||
        z == null ||
        confidence == null) {
      return null;
    }
    final world = _asObjectMap(map['world']);
    final worldX = _finiteDouble(map['worldX']) ?? _finiteDouble(world?['x']);
    final worldY = _finiteDouble(map['worldY']) ?? _finiteDouble(world?['y']);
    final worldZ = _finiteDouble(map['worldZ']) ?? _finiteDouble(world?['z']);
    final hasWorldCoordinates =
        worldX != null && worldY != null && worldZ != null;
    final worldConfidence = _finiteDouble(map['worldConfidence']) ??
        _finiteDouble(world?['confidence']);
    return RunningVideoPoseLandmark(
      index: index,
      x: x,
      y: y,
      z: z,
      visibility: _finiteDouble(map['visibility']),
      presence: _finiteDouble(map['presence']),
      confidence: confidence.clamp(0.0, 1.0).toDouble(),
      worldX: hasWorldCoordinates ? worldX : null,
      worldY: hasWorldCoordinates ? worldY : null,
      worldZ: hasWorldCoordinates ? worldZ : null,
      worldVisibility: _finiteDouble(map['worldVisibility']) ??
          _finiteDouble(world?['visibility']),
      worldPresence: _finiteDouble(map['worldPresence']) ??
          _finiteDouble(world?['presence']),
      worldConfidence: worldConfidence?.clamp(0.0, 1.0).toDouble(),
    );
  }
}

class RunningPoseFrame {
  final Duration timestamp;
  final int imageWidth;
  final int imageHeight;
  final List<RunningVideoPoseLandmark> landmarks;

  const RunningPoseFrame({
    required this.timestamp,
    required this.imageWidth,
    required this.imageHeight,
    required this.landmarks,
  });

  int get timestampMs => timestamp.inMilliseconds;

  RunningVideoPoseLandmark? landmarkByIndex(int index) {
    if (index < 0 || index >= landmarks.length) return null;
    final landmark = landmarks[index];
    if (landmark.index == index) return landmark;
    for (final item in landmarks) {
      if (item.index == index) return item;
    }
    return null;
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'timestampMs': timestampMs,
      'imageWidth': imageWidth,
      'imageHeight': imageHeight,
      'landmarks': landmarks.map((landmark) => landmark.toMap()).toList(
            growable: false,
          ),
    };
  }

  static RunningPoseFrame? fromObject(Object? raw) {
    final map = _asObjectMap(raw);
    if (map == null) return null;
    final timestampMs = _finiteInt(map['timestampMs']);
    final imageWidth = _finiteInt(map['imageWidth']);
    final imageHeight = _finiteInt(map['imageHeight']);
    final rawLandmarks = map['landmarks'];
    if (timestampMs == null ||
        timestampMs < 0 ||
        imageWidth == null ||
        imageWidth <= 0 ||
        imageHeight == null ||
        imageHeight <= 0 ||
        rawLandmarks is! Iterable<Object?>) {
      return null;
    }

    final landmarks = <RunningVideoPoseLandmark>[];
    for (final item in rawLandmarks) {
      final landmark = RunningVideoPoseLandmark.fromObject(item);
      if (landmark == null) {
        return null;
      }
      landmarks.add(landmark);
    }
    if (landmarks.length != mediaPipePoseLandmarkCount) {
      return null;
    }
    landmarks.sort((a, b) => a.index.compareTo(b.index));
    for (var index = 0; index < mediaPipePoseLandmarkCount; index += 1) {
      if (landmarks[index].index != index) {
        return null;
      }
    }

    return RunningPoseFrame(
      timestamp: Duration(milliseconds: timestampMs),
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      landmarks: List<RunningVideoPoseLandmark>.unmodifiable(landmarks),
    );
  }
}

class RunningBounceTrajectoryPoint {
  final Duration timestamp;
  final RunningPoseFrame frame;
  final double value;
  final double confidence;

  const RunningBounceTrajectoryPoint({
    required this.timestamp,
    required this.frame,
    required this.value,
    required this.confidence,
  });

  int get timestampMs => timestamp.inMilliseconds;
}

class RunningMetricEvidenceFrame {
  final Duration timestamp;
  final RunningMetricEvidenceFrameRole role;
  final RunningGaitPhase? phase;
  final RunningContactSide side;
  final RunningPoseFrame? poseFrame;
  final Map<String, double> values;
  final double confidence;

  RunningMetricEvidenceFrame({
    required this.timestamp,
    required this.role,
    required this.confidence,
    this.phase,
    this.side = RunningContactSide.unknown,
    this.poseFrame,
    Map<String, double> values = const <String, double>{},
  }) : values = Map<String, double>.unmodifiable(values);

  int get timestampMs => timestamp.inMilliseconds;
}

class RunningMetricEvidence {
  final RunningMetricEvidenceKind kind;
  final RunningCoachMetric? metric;
  final List<RunningMetricEvidenceFrame> frames;
  final Map<String, double> measuredValues;
  final int sampleCount;
  final double reliability;
  final RunningMetricEvidenceWithheldReason? withheldReason;

  RunningMetricEvidence({
    required this.kind,
    required this.metric,
    required List<RunningMetricEvidenceFrame> frames,
    required Map<String, double> measuredValues,
    required this.sampleCount,
    required this.reliability,
    this.withheldReason,
  })  : frames = List<RunningMetricEvidenceFrame>.unmodifiable(frames),
        measuredValues = Map<String, double>.unmodifiable(measuredValues);

  bool get isReliable =>
      withheldReason == null &&
      frames.isNotEmpty &&
      reliability >= runningCoachReliableMetricConfidence;
}

class RunningAnalysisSampleSummary {
  final int attemptedFrames;
  final int validFrames;
  final int poseFrameCount;
  final int? maxFrameBudget;
  final double? targetFps;

  const RunningAnalysisSampleSummary({
    required this.attemptedFrames,
    required this.validFrames,
    required this.poseFrameCount,
    this.maxFrameBudget,
    this.targetFps,
  });

  static const empty = RunningAnalysisSampleSummary(
    attemptedFrames: 0,
    validFrames: 0,
    poseFrameCount: 0,
  );

  double get coverage => attemptedFrames == 0
      ? 0.0
      : (validFrames / attemptedFrames).clamp(0.0, 1.0).toDouble();

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'attemptedFrames': attemptedFrames,
      'validFrames': validFrames,
      'poseFrameCount': poseFrameCount,
      if (maxFrameBudget != null) 'maxFrameBudget': maxFrameBudget,
      if (targetFps != null) 'targetFps': targetFps,
    };
  }

  static RunningAnalysisSampleSummary fromObject(
    Object? raw, {
    required RunningAnalysisSampleSummary fallback,
  }) {
    final map = _asObjectMap(raw);
    if (map == null) return fallback;
    return RunningAnalysisSampleSummary(
      attemptedFrames:
          (_finiteInt(map['attemptedFrames']) ?? fallback.attemptedFrames)
              .clamp(0, 1 << 30)
              .toInt(),
      validFrames: (_finiteInt(map['validFrames']) ?? fallback.validFrames)
          .clamp(0, 1 << 30)
          .toInt(),
      poseFrameCount:
          (_finiteInt(map['poseFrameCount']) ?? fallback.poseFrameCount)
              .clamp(0, 1 << 30)
              .toInt(),
      maxFrameBudget: _finiteInt(map['maxFrameBudget']),
      targetFps: _finiteDouble(map['targetFps']),
    );
  }
}

class RunningVideoPerspectiveQuality {
  final int evaluatedFrameCount;
  final double medianBodyScaleRatio;
  final double minBodyScaleRatio;
  final double visibilityCoverage;
  final double sideViewScore;
  final double scaleDriftRatio;
  final double cutOffFrameRatio;
  final List<RunningVideoQualityIssue> issues;

  const RunningVideoPerspectiveQuality({
    required this.evaluatedFrameCount,
    required this.medianBodyScaleRatio,
    required this.minBodyScaleRatio,
    required this.visibilityCoverage,
    required this.sideViewScore,
    required this.scaleDriftRatio,
    required this.cutOffFrameRatio,
    this.issues = const <RunningVideoQualityIssue>[],
  });

  static const unevaluated = RunningVideoPerspectiveQuality(
    evaluatedFrameCount: 0,
    medianBodyScaleRatio: 0,
    minBodyScaleRatio: 0,
    visibilityCoverage: 0,
    sideViewScore: 0,
    scaleDriftRatio: 0,
    cutOffFrameRatio: 0,
  );

  bool get isEvaluated => evaluatedFrameCount > 0;

  bool get hasLimitations => issues.isNotEmpty;

  String? get primaryReasonCode {
    if (issues.contains(RunningVideoQualityIssue.multiplePerson)) {
      return 'multiple_person';
    }
    if (issues.contains(RunningVideoQualityIssue.targetIdentityUnstable)) {
      return 'target_identity_unstable';
    }
    if (issues.contains(RunningVideoQualityIssue.tooSmall)) {
      return 'too_small_runner';
    }
    if (issues.contains(RunningVideoQualityIssue.notSideOn)) {
      return 'not_side_on';
    }
    if (issues.contains(RunningVideoQualityIssue.bodyCutOff)) {
      return 'body_cut_off';
    }
    if (issues.contains(RunningVideoQualityIssue.scaleDrift)) {
      return 'scale_drift';
    }
    return null;
  }

  String? limitationReasonForMetric(RunningCoachMetric metric) {
    if (!isEvaluated) return null;
    if (issues.contains(RunningVideoQualityIssue.multiplePerson)) {
      return 'multiple_person';
    }
    if (issues.contains(RunningVideoQualityIssue.targetIdentityUnstable)) {
      return 'target_identity_unstable';
    }
    if (issues.contains(RunningVideoQualityIssue.tooSmall)) {
      return 'too_small_runner';
    }
    if (issues.contains(RunningVideoQualityIssue.bodyCutOff)) {
      return 'body_cut_off';
    }
    final isProjectionSensitiveMetric = metric == RunningCoachMetric.posture ||
        metric == RunningCoachMetric.footStrike ||
        metric == RunningCoachMetric.kneeFlexion ||
        metric == RunningCoachMetric.armCarriage;
    if (isProjectionSensitiveMetric &&
        issues.contains(RunningVideoQualityIssue.notSideOn)) {
      return 'not_side_on';
    }
    final isScaleSensitiveMetric = metric == RunningCoachMetric.footStrike ||
        metric == RunningCoachMetric.kneeFlexion ||
        metric == RunningCoachMetric.bounce;
    if (isScaleSensitiveMetric &&
        issues.contains(RunningVideoQualityIssue.scaleDrift)) {
      return 'scale_drift';
    }
    return null;
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'evaluatedFrameCount': evaluatedFrameCount,
      'medianBodyScaleRatio': medianBodyScaleRatio,
      'minBodyScaleRatio': minBodyScaleRatio,
      'visibilityCoverage': visibilityCoverage,
      'sideViewScore': sideViewScore,
      'scaleDriftRatio': scaleDriftRatio,
      'cutOffFrameRatio': cutOffFrameRatio,
      if (issues.isNotEmpty)
        'issues': issues.map((issue) => issue.name).toList(growable: false),
    };
  }

  static RunningVideoPerspectiveQuality fromObject(Object? raw) {
    final map = _asObjectMap(raw);
    if (map == null) return unevaluated;
    final rawIssues = map['issues'];
    final issues = <RunningVideoQualityIssue>[];
    if (rawIssues is Iterable<Object?>) {
      for (final item in rawIssues) {
        final issue = _qualityIssueFromToken(item?.toString());
        if (issue != null && !issues.contains(issue)) {
          issues.add(issue);
        }
      }
    }
    return RunningVideoPerspectiveQuality(
      evaluatedFrameCount: (_finiteInt(map['evaluatedFrameCount']) ?? 0)
          .clamp(0, 1 << 30)
          .toInt(),
      medianBodyScaleRatio: (_finiteDouble(map['medianBodyScaleRatio']) ?? 0)
          .clamp(0.0, 1.0)
          .toDouble(),
      minBodyScaleRatio: (_finiteDouble(map['minBodyScaleRatio']) ?? 0)
          .clamp(0.0, 1.0)
          .toDouble(),
      visibilityCoverage: (_finiteDouble(map['visibilityCoverage']) ?? 0)
          .clamp(0.0, 1.0)
          .toDouble(),
      sideViewScore:
          (_finiteDouble(map['sideViewScore']) ?? 0).clamp(0.0, 1.0).toDouble(),
      scaleDriftRatio: (_finiteDouble(map['scaleDriftRatio']) ?? 0)
          .clamp(0.0, 10.0)
          .toDouble(),
      cutOffFrameRatio: (_finiteDouble(map['cutOffFrameRatio']) ?? 0)
          .clamp(0.0, 1.0)
          .toDouble(),
      issues: List<RunningVideoQualityIssue>.unmodifiable(issues),
    );
  }
}

class RunningContactWindow {
  final Duration start;
  final Duration center;
  final Duration end;
  final RunningContactSide side;
  final int denseSampleCount;

  /// Number of dense frames in this window where the tracked foot was
  /// considered as a possible contact. This is diagnostic data: a candidate
  /// is not a validated contact and must not be used for coaching scores.
  final int candidateFrameCount;
  final List<Duration> validatedContactTimestamps;
  final List<Duration> estimatedContactTimestamps;

  /// Stable analyzer token describing how this window's observation was
  /// selected. `ground` is a dense, validated contact; `kinematic` is only a
  /// trajectory estimate and must never be promoted to validated evidence.
  final String? selectionMethod;

  /// Why dense-frame candidates were rejected. Kept as raw, stable analyzer
  /// codes so the presentation layer can explain the exact capture problem
  /// without turning an estimated contact into a measurement.
  final Map<String, int> rejectedFrameCounts;
  final double confidence;

  const RunningContactWindow({
    required this.start,
    required this.center,
    required this.end,
    required this.side,
    required this.denseSampleCount,
    required this.validatedContactTimestamps,
    required this.confidence,
    this.estimatedContactTimestamps = const <Duration>[],
    this.selectionMethod,
    this.candidateFrameCount = 0,
    this.rejectedFrameCounts = const <String, int>{},
  });

  int get startMs => start.inMilliseconds;
  int get centerMs => center.inMilliseconds;
  int get endMs => end.inMilliseconds;

  String? get primaryRejectedFrameReason {
    if (rejectedFrameCounts.isEmpty) return null;
    final entries = rejectedFrameCounts.entries
        .where((entry) => entry.value > 0)
        .toList(growable: false)
      ..sort((first, second) {
        final count = second.value.compareTo(first.value);
        return count != 0 ? count : first.key.compareTo(second.key);
      });
    return entries.isEmpty ? null : entries.first.key;
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'startTimestampMs': startMs,
      'centerTimestampMs': centerMs,
      'endTimestampMs': endMs,
      'side': side.name,
      'denseSampleCount': denseSampleCount,
      'candidateFrameCount': candidateFrameCount,
      'validatedContactFrameTimestampsMs': validatedContactTimestamps
          .map((timestamp) => timestamp.inMilliseconds)
          .toList(growable: false),
      'estimatedContactFrameTimestampsMs': estimatedContactTimestamps
          .map((timestamp) => timestamp.inMilliseconds)
          .toList(growable: false),
      if (selectionMethod != null) 'selectionMethod': selectionMethod,
      if (rejectedFrameCounts.isNotEmpty)
        'rejectedFrameCounts': rejectedFrameCounts,
      'confidence': confidence,
    };
  }

  static RunningContactWindow? fromObject(Object? raw) {
    final map = _asObjectMap(raw);
    if (map == null) return null;
    final startMs = _finiteInt(map['startTimestampMs']);
    final centerMs = _finiteInt(map['centerTimestampMs']);
    final endMs = _finiteInt(map['endTimestampMs']);
    if (startMs == null ||
        centerMs == null ||
        endMs == null ||
        startMs < 0 ||
        centerMs < startMs ||
        endMs < centerMs) {
      return null;
    }
    return RunningContactWindow(
      start: Duration(milliseconds: startMs),
      center: Duration(milliseconds: centerMs),
      end: Duration(milliseconds: endMs),
      side: _contactSideFromToken(map['side']?.toString()),
      denseSampleCount:
          (_finiteInt(map['denseSampleCount']) ?? 0).clamp(0, 1 << 30).toInt(),
      candidateFrameCount: (_finiteInt(map['candidateFrameCount']) ?? 0)
          .clamp(0, 1 << 30)
          .toInt(),
      validatedContactTimestamps: _parseTimestampList(
        map['validatedContactFrameTimestampsMs'],
      ),
      estimatedContactTimestamps: _parseTimestampList(
        map['estimatedContactFrameTimestampsMs'],
      ),
      selectionMethod: _optionalToken(map['selectionMethod']),
      rejectedFrameCounts: _parsePositiveIntMap(map['rejectedFrameCounts']),
      confidence:
          (_finiteDouble(map['confidence']) ?? 0).clamp(0.0, 1.0).toDouble(),
    );
  }
}

class RunningVideoPosePreviewResult {
  final Duration videoDuration;
  final int sampledFrames;
  final int validFrames;
  final List<RunningPoseFrame> poseFrames;
  final RunningVideoPerspectiveQuality perspectiveQuality;

  const RunningVideoPosePreviewResult({
    required this.videoDuration,
    required this.sampledFrames,
    required this.validFrames,
    required this.poseFrames,
    this.perspectiveQuality = RunningVideoPerspectiveQuality.unevaluated,
  });

  double get validFrameCoverage =>
      sampledFrames == 0 ? 0.0 : validFrames / sampledFrames;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'durationMs': videoDuration.inMilliseconds,
      'sampledFrames': sampledFrames,
      'validFrames': validFrames,
      'poseFrames': poseFrames.map((frame) => frame.toMap()).toList(
            growable: false,
          ),
      'perspectiveQuality': perspectiveQuality.toMap(),
    };
  }

  factory RunningVideoPosePreviewResult.fromMap(Map<Object?, Object?> map) {
    final poseFrames = _parsePoseFrames(map['poseFrames']);
    return RunningVideoPosePreviewResult(
      videoDuration: Duration(milliseconds: _finiteInt(map['durationMs']) ?? 0),
      sampledFrames:
          (_finiteInt(map['sampledFrames']) ?? 0).clamp(0, 1 << 30).toInt(),
      validFrames: (_finiteInt(map['validFrames']) ?? poseFrames.length)
          .clamp(0, 1 << 30)
          .toInt(),
      poseFrames: poseFrames,
      perspectiveQuality: RunningVideoPerspectiveQuality.fromObject(
        map['perspectiveQuality'],
      ),
    );
  }
}

class RunningVideoAnalysisResult {
  final int analysisVersion;
  final Duration videoDuration;
  final int sampledFrames;
  final int validFrames;
  final RunningDirection direction;
  final double forwardLeanDegrees;
  final double verticalBounceRatio;
  final double footStrikeDistanceRatio;
  final double stanceKneeAngleDegrees;
  final double elbowAngleDegrees;
  final Map<RunningCoachMetric, RunningMetricQuality> metricQualities;
  final List<RunningPoseFrame> poseFrames;
  final RunningAnalysisSampleSummary coarseSamples;
  final RunningAnalysisSampleSummary recoverySamples;
  final RunningAnalysisSampleSummary denseSamples;
  final List<RunningContactWindow> contactWindows;
  final List<Duration> validatedContactFrameTimestamps;
  final List<Duration> estimatedContactFrameTimestamps;
  final double contactConfidence;
  final RunningVideoPerspectiveQuality perspectiveQuality;
  final Map<RunningAnalysisMetric, RunningMetricMeasurement> measurements;
  final List<RunningScaleSegment> scaleSegments;
  final Duration? analysisWindowStart;
  final Duration? analysisWindowEnd;

  const RunningVideoAnalysisResult({
    this.analysisVersion = 1,
    required this.videoDuration,
    required this.sampledFrames,
    required this.validFrames,
    required this.direction,
    required this.forwardLeanDegrees,
    required this.verticalBounceRatio,
    required this.footStrikeDistanceRatio,
    required this.stanceKneeAngleDegrees,
    required this.elbowAngleDegrees,
    this.metricQualities = const <RunningCoachMetric, RunningMetricQuality>{},
    this.poseFrames = const <RunningPoseFrame>[],
    this.coarseSamples = RunningAnalysisSampleSummary.empty,
    this.recoverySamples = RunningAnalysisSampleSummary.empty,
    this.denseSamples = RunningAnalysisSampleSummary.empty,
    this.contactWindows = const <RunningContactWindow>[],
    this.validatedContactFrameTimestamps = const <Duration>[],
    this.estimatedContactFrameTimestamps = const <Duration>[],
    this.contactConfidence = 0,
    this.perspectiveQuality = RunningVideoPerspectiveQuality.unevaluated,
    this.measurements =
        const <RunningAnalysisMetric, RunningMetricMeasurement>{},
    this.scaleSegments = const <RunningScaleSegment>[],
    this.analysisWindowStart,
    this.analysisWindowEnd,
  });

  double get validFrameCoverage =>
      sampledFrames == 0 ? 0.0 : validFrames / sampledFrames;

  double get analysisConfidence {
    final coverage = validFrameCoverage.clamp(0.0, 1.0);
    final validFrameFactor = (validFrames / 10).clamp(0.0, 1.0);
    final sampledFrameFactor = (sampledFrames / 10).clamp(0.0, 1.0);
    return ((coverage * 0.55) +
            (validFrameFactor * 0.30) +
            (sampledFrameFactor * 0.15))
        .clamp(0.0, 1.0);
  }

  RunningMetricQuality? qualityFor(RunningCoachMetric metric) {
    return metricQualities[metric];
  }

  RunningMetricMeasurement measurementFor(RunningAnalysisMetric metric) {
    return measurements[metric] ?? _legacyMeasurementFor(this, metric);
  }

  bool get hasDenseContactEvidence =>
      validatedContactFrameTimestamps.length >=
          runningCoachMinimumReliableMetricSamples &&
      denseSamples.validFrames > 0;

  /// At least one contact was confirmed against the dense pose pass. This is
  /// deliberately weaker than [hasDenseContactEvidence]: one or two contacts
  /// can be shown as an observed lower-body frame, but never earn a coaching
  /// score, cadence, symmetry, or a good/bad judgement.
  bool get hasObservedContactEvidence =>
      validatedContactFrameTimestamps.isNotEmpty;

  /// Defensive single-runner contract for analyzers that currently return one
  /// pose per frame. Explicit native/web payload issues win; otherwise an
  /// extreme center, scale, or body-proportion discontinuity is treated as a
  /// likely identity jump. The guard withholds scoring instead of pretending
  /// that the second pose belongs to the selected runner.
  String? get targetIdentityIssueReason {
    if (perspectiveQuality.issues
        .contains(RunningVideoQualityIssue.multiplePerson)) {
      return 'multiple_person';
    }
    if (perspectiveQuality.issues
        .contains(RunningVideoQualityIssue.targetIdentityUnstable)) {
      return 'target_identity_unstable';
    }
    if (_hasExtremePoseIdentityDiscontinuity(poseFrames)) {
      return 'target_identity_unstable';
    }
    return null;
  }

  bool get hasTargetIdentityRisk => targetIdentityIssueReason != null;

  int get contactCandidateFrameCount => contactWindows.fold<int>(
        0,
        (total, window) => total + window.candidateFrameCount,
      );

  String? get primaryContactRejectionReason {
    final counts = <String, int>{};
    for (final window in contactWindows) {
      for (final entry in window.rejectedFrameCounts.entries) {
        counts.update(
          entry.key,
          (count) => count + entry.value,
          ifAbsent: () => entry.value,
        );
      }
    }
    if (counts.isEmpty) return null;
    final entries = counts.entries.toList(growable: false)
      ..sort((first, second) {
        final count = second.value.compareTo(first.value);
        return count != 0 ? count : first.key.compareTo(second.key);
      });
    return entries.first.key;
  }

  /// Per-step, phase-aware measurements derived from the same uploaded video.
  /// Returns null when the clip has no validated contact frame / pose-frame
  /// pairing. A result with fewer than three steps remains an observation;
  /// callers must not promote it to a score or coaching judgement.
  ///
  /// This remains a getter so legacy constant result fixtures and persisted
  /// snapshots retain their existing value semantics.
  RunningGaitAnalysis? get gaitAnalysis => _deriveRunningGaitAnalysis(this);

  /// Rhythm measurements calculated from verified contact timestamps.
  ///
  /// This deliberately requires a complete multi-contact sample: cadence and
  /// time between contacts should never be inferred from one or two observed
  /// steps. Pose-dependent observations may still be available through
  /// [gaitAnalysis], but remain unscored until they meet their own evidence
  /// threshold.
  RunningRhythmAnalysis? get rhythmAnalysis =>
      _deriveRunningRhythmAnalysis(this);

  /// Per-metric evidence selected from measured timestamps rather than display
  /// placeholders. This is derived on demand so old saved sessions that only
  /// contain summary values still deserialize without new persisted fields.
  List<RunningMetricEvidence> get metricEvidence =>
      _deriveRunningMetricEvidence(this);

  RunningMetricEvidence? evidenceForKind(RunningMetricEvidenceKind kind) {
    for (final evidence in metricEvidence) {
      if (evidence.kind == kind) return evidence;
    }
    return null;
  }

  RunningMetricEvidence? evidenceForMetric(RunningCoachMetric metric) {
    for (final evidence in metricEvidence) {
      if (evidence.metric == metric) return evidence;
    }
    return null;
  }

  Duration? nearestValidatedContactTimestamp(
    Duration position, {
    Duration tolerance = const Duration(milliseconds: 90),
  }) {
    Duration? nearest;
    var nearestDistanceMs = tolerance.inMilliseconds + 1;
    for (final timestamp in validatedContactFrameTimestamps) {
      final distanceMs =
          (timestamp.inMilliseconds - position.inMilliseconds).abs();
      if (distanceMs < nearestDistanceMs) {
        nearest = timestamp;
        nearestDistanceMs = distanceMs;
      }
    }
    return nearestDistanceMs <= tolerance.inMilliseconds ? nearest : null;
  }

  /// Keeps enough measured frames for an archived coaching replay without
  /// persisting every sampled frame with each history entry.
  RunningVideoAnalysisResult historySnapshot({
    int maxPoseFrames = 24,
    Iterable<Duration> evidenceTimestamps = const <Duration>[],
  }) {
    final frames = _historyPoseFrames(
      poseFrames,
      contactTimestamps: validatedContactFrameTimestamps,
      evidenceTimestamps: evidenceTimestamps.toList(growable: false),
      maxFrames: maxPoseFrames,
    );
    return RunningVideoAnalysisResult(
      analysisVersion: analysisVersion,
      videoDuration: videoDuration,
      sampledFrames: sampledFrames,
      validFrames: validFrames,
      direction: direction,
      forwardLeanDegrees: forwardLeanDegrees,
      verticalBounceRatio: verticalBounceRatio,
      footStrikeDistanceRatio: footStrikeDistanceRatio,
      stanceKneeAngleDegrees: stanceKneeAngleDegrees,
      elbowAngleDegrees: elbowAngleDegrees,
      metricQualities: metricQualities,
      poseFrames: frames,
      coarseSamples: coarseSamples,
      recoverySamples: recoverySamples,
      denseSamples: denseSamples,
      contactWindows: contactWindows,
      validatedContactFrameTimestamps: validatedContactFrameTimestamps,
      estimatedContactFrameTimestamps: estimatedContactFrameTimestamps,
      contactConfidence: contactConfidence,
      perspectiveQuality: perspectiveQuality,
      measurements: measurements,
      scaleSegments: scaleSegments,
      analysisWindowStart: analysisWindowStart,
      analysisWindowEnd: analysisWindowEnd,
    );
  }

  RunningVideoAnalysisResult copyWith({
    int? analysisVersion,
    RunningDirection? direction,
    double? forwardLeanDegrees,
    double? verticalBounceRatio,
    double? footStrikeDistanceRatio,
    double? stanceKneeAngleDegrees,
    double? elbowAngleDegrees,
    Map<RunningCoachMetric, RunningMetricQuality>? metricQualities,
    List<RunningPoseFrame>? poseFrames,
    RunningAnalysisSampleSummary? recoverySamples,
    List<RunningContactWindow>? contactWindows,
    List<Duration>? validatedContactFrameTimestamps,
    List<Duration>? estimatedContactFrameTimestamps,
    double? contactConfidence,
    Map<RunningAnalysisMetric, RunningMetricMeasurement>? measurements,
    List<RunningScaleSegment>? scaleSegments,
    Duration? analysisWindowStart,
    Duration? analysisWindowEnd,
  }) {
    return RunningVideoAnalysisResult(
      analysisVersion: analysisVersion ?? this.analysisVersion,
      videoDuration: videoDuration,
      sampledFrames: sampledFrames,
      validFrames: validFrames,
      direction: direction ?? this.direction,
      forwardLeanDegrees: forwardLeanDegrees ?? this.forwardLeanDegrees,
      verticalBounceRatio: verticalBounceRatio ?? this.verticalBounceRatio,
      footStrikeDistanceRatio:
          footStrikeDistanceRatio ?? this.footStrikeDistanceRatio,
      stanceKneeAngleDegrees:
          stanceKneeAngleDegrees ?? this.stanceKneeAngleDegrees,
      elbowAngleDegrees: elbowAngleDegrees ?? this.elbowAngleDegrees,
      metricQualities: metricQualities ?? this.metricQualities,
      poseFrames: poseFrames ?? this.poseFrames,
      coarseSamples: coarseSamples,
      recoverySamples: recoverySamples ?? this.recoverySamples,
      denseSamples: denseSamples,
      contactWindows: contactWindows ?? this.contactWindows,
      validatedContactFrameTimestamps: validatedContactFrameTimestamps ??
          this.validatedContactFrameTimestamps,
      estimatedContactFrameTimestamps: estimatedContactFrameTimestamps ??
          this.estimatedContactFrameTimestamps,
      contactConfidence: contactConfidence ?? this.contactConfidence,
      perspectiveQuality: perspectiveQuality,
      measurements: measurements ?? this.measurements,
      scaleSegments: scaleSegments ?? this.scaleSegments,
      analysisWindowStart: analysisWindowStart ?? this.analysisWindowStart,
      analysisWindowEnd: analysisWindowEnd ?? this.analysisWindowEnd,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'analysisVersion': analysisVersion,
      'durationMs': videoDuration.inMilliseconds,
      'sampledFrames': sampledFrames,
      'validFrames': validFrames,
      'direction': direction.name,
      'forwardLeanDegrees': forwardLeanDegrees,
      'verticalBounceRatio': verticalBounceRatio,
      'footStrikeDistanceRatio': footStrikeDistanceRatio,
      'stanceKneeAngleDegrees': stanceKneeAngleDegrees,
      'elbowAngleDegrees': elbowAngleDegrees,
      'metricQualities': <String, Object?>{
        for (final entry in metricQualities.entries)
          entry.key.name: entry.value.toMap(),
      },
      'poseFrames': poseFrames.map((frame) => frame.toMap()).toList(
            growable: false,
          ),
      'coarseSamples': coarseSamples.toMap(),
      'recoverySamples': recoverySamples.toMap(),
      'denseSamples': denseSamples.toMap(),
      'contactWindows': contactWindows.map((window) => window.toMap()).toList(
            growable: false,
          ),
      'validatedContactFrameTimestampsMs': validatedContactFrameTimestamps
          .map((timestamp) => timestamp.inMilliseconds)
          .toList(growable: false),
      'estimatedContactFrameTimestampsMs': estimatedContactFrameTimestamps
          .map((timestamp) => timestamp.inMilliseconds)
          .toList(growable: false),
      'contactConfidence': contactConfidence,
      'perspectiveQuality': perspectiveQuality.toMap(),
      'measurements': measurements.values
          .map((measurement) => measurement.toMap())
          .toList(growable: false),
      'scaleSegments': scaleSegments
          .map((segment) => segment.toMap())
          .toList(growable: false),
      if (analysisWindowStart != null)
        'analysisWindowStartMs': analysisWindowStart!.inMilliseconds,
      if (analysisWindowEnd != null)
        'analysisWindowEndMs': analysisWindowEnd!.inMilliseconds,
    };
  }

  factory RunningVideoAnalysisResult.fromMap(Map<Object?, Object?> map) {
    final durationMs = _finiteInt(map['durationMs']) ?? 0;
    final sampledFrames = _finiteInt(map['sampledFrames']) ?? 0;
    final validFrames = _finiteInt(map['validFrames']) ?? 0;
    final rawDirection = map['direction'];
    final directionToken = rawDirection is String ? rawDirection : 'stationary';
    final poseFrames = _parsePoseFrames(map['poseFrames']);
    final coarseFallback = RunningAnalysisSampleSummary(
      attemptedFrames: sampledFrames,
      validFrames: validFrames,
      poseFrameCount: poseFrames.length,
    );
    final parsedQualities = _parseMetricQualities(map['metricQualities']);
    final payloadUsesKinematicEstimate = parsedQualities.values.any(
      (quality) => quality.reason == 'kinematic_contact_estimate',
    );
    final parsedWindows = _parseContactWindows(map['contactWindows']);
    final parsedValidated = _parseTimestampList(
      map['validatedContactFrameTimestampsMs'],
    );
    final parsedEstimated = _parseTimestampList(
      map['estimatedContactFrameTimestampsMs'],
    );
    final hasExplicitEstimatedContactContract =
        map.containsKey('estimatedContactFrameTimestampsMs') ||
            parsedWindows.any(
              (window) =>
                  window.estimatedContactTimestamps.isNotEmpty ||
                  window.selectionMethod != null,
            );
    final shouldDemoteLegacyKinematicContacts =
        payloadUsesKinematicEstimate && !hasExplicitEstimatedContactContract;
    // Early v2 builds placed kinematic estimates in the validated list. They
    // always tagged the lower-body metric quality, so old history can be
    // repaired deterministically without changing truly validated v1 data.
    final alternation = shouldDemoteLegacyKinematicContacts
        ? null
        : _partitionAlternatingValidatedContacts(
            parsedValidated,
            parsedWindows,
          );
    final contactWindows = shouldDemoteLegacyKinematicContacts
        ? _demoteLegacyKinematicWindows(parsedWindows)
        : _demoteAlternationEstimatedWindows(
            parsedWindows,
            alternation?.demoted ?? const <Duration>[],
          );
    final validatedContacts = shouldDemoteLegacyKinematicContacts
        ? const <Duration>[]
        : alternation?.confirmed ?? parsedValidated;
    final estimatedContacts = <Duration>{
      ...parsedEstimated,
      if (shouldDemoteLegacyKinematicContacts) ...parsedValidated,
      if (!shouldDemoteLegacyKinematicContacts)
        ...(alternation?.demoted ?? const <Duration>[]),
    }.toList(growable: false)
      ..sort();
    final parsedMeasurements = _parseRunningMeasurements(map['measurements']);
    return RunningVideoAnalysisResult(
      analysisVersion: (_finiteInt(map['analysisVersion']) ?? 1)
          .clamp(1, runningAnalysisVersionV2)
          .toInt(),
      videoDuration: Duration(milliseconds: durationMs),
      sampledFrames: sampledFrames,
      validFrames: validFrames,
      direction: switch (directionToken) {
        'leftToRight' => RunningDirection.leftToRight,
        'rightToLeft' => RunningDirection.rightToLeft,
        _ => RunningDirection.stationary,
      },
      forwardLeanDegrees: _finiteDouble(map['forwardLeanDegrees']) ?? 0,
      verticalBounceRatio: _finiteDouble(map['verticalBounceRatio']) ?? 0,
      footStrikeDistanceRatio:
          _finiteDouble(map['footStrikeDistanceRatio']) ?? 0,
      stanceKneeAngleDegrees: _finiteDouble(map['stanceKneeAngleDegrees']) ?? 0,
      elbowAngleDegrees: _finiteDouble(map['elbowAngleDegrees']) ?? 0,
      metricQualities: parsedQualities,
      poseFrames: poseFrames,
      coarseSamples: RunningAnalysisSampleSummary.fromObject(
        map['coarseSamples'],
        fallback: coarseFallback,
      ),
      recoverySamples: RunningAnalysisSampleSummary.fromObject(
        map['recoverySamples'],
        fallback: RunningAnalysisSampleSummary.empty,
      ),
      denseSamples: RunningAnalysisSampleSummary.fromObject(
        map['denseSamples'],
        fallback: RunningAnalysisSampleSummary.empty,
      ),
      contactWindows: contactWindows,
      validatedContactFrameTimestamps: validatedContacts,
      estimatedContactFrameTimestamps:
          List<Duration>.unmodifiable(estimatedContacts),
      contactConfidence: (_finiteDouble(map['contactConfidence']) ?? 0)
          .clamp(0.0, 1.0)
          .toDouble(),
      perspectiveQuality: RunningVideoPerspectiveQuality.fromObject(
        map['perspectiveQuality'],
      ),
      measurements: shouldDemoteLegacyKinematicContacts
          ? _demoteLegacyKinematicMeasurements(parsedMeasurements)
          : parsedMeasurements,
      scaleSegments: _parseScaleSegments(map['scaleSegments']),
      analysisWindowStart: _durationFromMilliseconds(
        map['analysisWindowStartMs'],
      ),
      analysisWindowEnd: _durationFromMilliseconds(
        map['analysisWindowEndMs'],
      ),
    );
  }
}

/// Locally observable running-cycle stages for one foot.
///
/// Recovery and lowering happen before the next landing and must not be
/// promoted to landing measurements. The legacy preContact/contactExit names
/// remain readable for older in-memory callers; newly derived data uses the
/// release phase names below.
enum RunningGaitPhase {
  recovery,
  lowering,
  preContact,
  initialContact,
  support,
  maximumKneeFlexion,
  pushOff,
  contactExit,
}

class RunningGaitPhaseMeasurement {
  final RunningGaitPhase phase;
  final Duration timestamp;
  final double? footStrikeDistanceRatio;
  final double? kneeAngleDegrees;
  final double? forwardLeanDegrees;
  final double? elbowAngleDegrees;
  final double confidence;

  const RunningGaitPhaseMeasurement({
    required this.phase,
    required this.timestamp,
    required this.footStrikeDistanceRatio,
    required this.kneeAngleDegrees,
    required this.forwardLeanDegrees,
    required this.elbowAngleDegrees,
    required this.confidence,
  });
}

class RunningGaitStep {
  final RunningContactSide side;
  final Duration contactTimestamp;
  final double confidence;
  final RunningGaitPhaseMeasurement? recovery;
  final RunningGaitPhaseMeasurement? lowering;
  final RunningGaitPhaseMeasurement? preContact;
  final RunningGaitPhaseMeasurement initialContact;
  final RunningGaitPhaseMeasurement? support;
  final RunningGaitPhaseMeasurement? maximumKneeFlexion;
  final RunningGaitPhaseMeasurement? pushOff;
  final RunningGaitPhaseMeasurement? contactExit;

  const RunningGaitStep({
    required this.side,
    required this.contactTimestamp,
    required this.confidence,
    this.recovery,
    this.lowering,
    required this.preContact,
    required this.initialContact,
    this.support,
    required this.maximumKneeFlexion,
    this.pushOff,
    required this.contactExit,
  });

  bool get isReliable =>
      confidence >= runningCoachReliableMetricConfidence &&
      initialContact.kneeAngleDegrees != null &&
      initialContact.footStrikeDistanceRatio != null;

  double? get footStrikeDistanceRatio => initialContact.footStrikeDistanceRatio;
  double? get kneeAtContactDegrees => initialContact.kneeAngleDegrees;
  double? get minimumKneeAngleDegrees => maximumKneeFlexion?.kneeAngleDegrees;
  double? get recoveryKneeAngleDegrees => recovery?.kneeAngleDegrees;
  double? get forwardLeanAtContactDegrees => initialContact.forwardLeanDegrees;
  double? get elbowAtContactDegrees => initialContact.elbowAngleDegrees;
}

/// A robust summary for a metric collected over several contact events.
/// The range is intentionally shown with the median so a single average never
/// hides an inconsistent set of strides.
class RunningGaitDistribution {
  final double median;
  final double minimum;
  final double maximum;
  final int sampleCount;

  const RunningGaitDistribution({
    required this.median,
    required this.minimum,
    required this.maximum,
    required this.sampleCount,
  });

  double get span => maximum - minimum;

  static RunningGaitDistribution? fromValues(Iterable<double?> source) {
    final values = source
        .whereType<double>()
        .where((value) => value.isFinite)
        .toList(growable: false)
      ..sort();
    if (values.isEmpty) return null;
    final middle = values.length ~/ 2;
    final median = values.length.isOdd
        ? values[middle]
        : (values[middle - 1] + values[middle]) / 2;
    return RunningGaitDistribution(
      median: median,
      minimum: values.first,
      maximum: values.last,
      sampleCount: values.length,
    );
  }
}

/// One contact used solely for timing and rhythm measurements.
///
/// The side is kept as [RunningContactSide.unknown] when the analyzer could
/// validate a contact timestamp but could not defensibly assign it to a foot.
class RunningRhythmContact {
  final Duration timestamp;
  final RunningContactSide side;
  final double confidence;

  const RunningRhythmContact({
    required this.timestamp,
    required this.side,
    required this.confidence,
  });
}

/// Timing-only information that can be shown even when a full pose/contact
/// pairing is unavailable. This is an estimate of consecutive contact timing,
/// never an exact ground-contact-duration measurement.
class RunningRhythmAnalysis {
  final List<RunningRhythmContact> contacts;
  final double? cadenceSpm;
  final double? medianStepTimeMs;
  final double? leftRightStepTimeAsymmetryPercent;
  final int validIntervalCount;

  const RunningRhythmAnalysis({
    required this.contacts,
    required this.cadenceSpm,
    required this.medianStepTimeMs,
    required this.leftRightStepTimeAsymmetryPercent,
    required this.validIntervalCount,
  });

  int get reliableContactCount => contacts
      .where((contact) =>
          contact.confidence >= runningCoachReliableMetricConfidence)
      .length;

  bool get hasReliableSample =>
      reliableContactCount >= runningCoachMinimumReliableMetricSamples &&
      validIntervalCount >= runningCoachMinimumReliableMetricSamples - 1;

  int get leftContactCount => contacts
      .where((contact) => contact.side == RunningContactSide.left)
      .length;

  int get rightContactCount => contacts
      .where((contact) => contact.side == RunningContactSide.right)
      .length;

  bool get hasBilateralSample =>
      leftContactCount >= 2 && rightContactCount >= 2;
}

RunningRhythmAnalysis? _deriveRunningRhythmAnalysis(
  RunningVideoAnalysisResult result,
) {
  if (!result.hasDenseContactEvidence) return null;

  final timestamps = result.validatedContactFrameTimestamps
      .map((timestamp) => timestamp.inMilliseconds)
      .toSet()
      .toList(growable: false)
    ..sort();
  if (timestamps.length < runningCoachMinimumReliableMetricSamples) {
    return null;
  }

  final contacts = timestamps
      .map(
        (timestamp) => _rhythmContactForTimestamp(
          result: result,
          timestampMs: timestamp,
        ),
      )
      .toList(growable: false);
  final timing = _rhythmTimingSummary(contacts);
  return RunningRhythmAnalysis(
    contacts: List<RunningRhythmContact>.unmodifiable(contacts),
    cadenceSpm: timing.cadenceSpm,
    medianStepTimeMs: timing.medianStepTimeMs,
    leftRightStepTimeAsymmetryPercent: timing.asymmetryPercent,
    validIntervalCount: timing.validIntervalCount,
  );
}

RunningRhythmContact _rhythmContactForTimestamp({
  required RunningVideoAnalysisResult result,
  required int timestampMs,
}) {
  RunningContactWindow? nearestWindow;
  var nearestDistanceMs = 181;
  final explicitWindows = result.contactWindows.where(
    (window) => window.validatedContactTimestamps.any(
      (timestamp) => timestamp.inMilliseconds == timestampMs,
    ),
  );
  final candidateWindows =
      explicitWindows.isNotEmpty ? explicitWindows : result.contactWindows;
  for (final window in candidateWindows) {
    final isInside =
        timestampMs >= window.startMs && timestampMs <= window.endMs;
    final distanceMs = (timestampMs - window.centerMs).abs();
    if (!isInside && distanceMs > 180) continue;
    if (nearestWindow == null || distanceMs < nearestDistanceMs) {
      nearestWindow = window;
      nearestDistanceMs = distanceMs;
    }
  }
  final windowConfidence = nearestWindow?.confidence ?? 0;
  final fallbackConfidence = result.contactConfidence;
  final confidence = windowConfidence > 0 && fallbackConfidence > 0
      ? math.min(windowConfidence, fallbackConfidence)
      : math.max(windowConfidence, fallbackConfidence);
  return RunningRhythmContact(
    timestamp: Duration(milliseconds: timestampMs),
    side: nearestWindow?.side ?? RunningContactSide.unknown,
    confidence: confidence.clamp(0.0, 1.0).toDouble(),
  );
}

class _RunningRhythmTimingSummary {
  final double? cadenceSpm;
  final double? medianStepTimeMs;
  final double? asymmetryPercent;
  final int validIntervalCount;

  const _RunningRhythmTimingSummary({
    required this.cadenceSpm,
    required this.medianStepTimeMs,
    required this.asymmetryPercent,
    required this.validIntervalCount,
  });
}

_RunningRhythmTimingSummary _rhythmTimingSummary(
  List<RunningRhythmContact> contacts,
) {
  if (contacts.length < runningCoachMinimumReliableMetricSamples) {
    return const _RunningRhythmTimingSummary(
      cadenceSpm: null,
      medianStepTimeMs: null,
      asymmetryPercent: null,
      validIntervalCount: 0,
    );
  }
  final intervals = <double>[];
  final byStartingSide = <RunningContactSide, List<double>>{
    RunningContactSide.left: <double>[],
    RunningContactSide.right: <double>[],
  };
  for (var index = 0; index < contacts.length - 1; index += 1) {
    final current = contacts[index];
    final next = contacts[index + 1];
    final hasKnownSameSide =
        current.side != RunningContactSide.unknown && current.side == next.side;
    if (hasKnownSameSide) continue;
    final interval =
        (next.timestamp.inMilliseconds - current.timestamp.inMilliseconds)
            .toDouble();
    if (interval < 120 || interval > 1000) continue;
    intervals.add(interval);
    if (current.side != RunningContactSide.unknown &&
        next.side != RunningContactSide.unknown) {
      byStartingSide[current.side]!.add(interval);
    }
  }
  final distribution = RunningGaitDistribution.fromValues(intervals);
  final left = RunningGaitDistribution.fromValues(
    byStartingSide[RunningContactSide.left]!,
  );
  final right = RunningGaitDistribution.fromValues(
    byStartingSide[RunningContactSide.right]!,
  );
  final asymmetry = left != null &&
          right != null &&
          left.sampleCount >= 2 &&
          right.sampleCount >= 2
      ? ((left.median - right.median).abs() /
              ((left.median + right.median) / 2) *
              100)
          .clamp(0.0, 100.0)
          .toDouble()
      : null;
  return _RunningRhythmTimingSummary(
    cadenceSpm: distribution == null || distribution.median <= 0
        ? null
        : 60000 / distribution.median,
    medianStepTimeMs: distribution?.median,
    asymmetryPercent: asymmetry,
    validIntervalCount: intervals.length,
  );
}

/// Fine-grained measurements that are defensible from a single fixed,
/// side-view recording. Unsupported biomechanics such as pronation, ground
/// reaction force, and injury risk intentionally have no field here.
class RunningGaitAnalysis {
  final List<RunningGaitStep> steps;
  final RunningGaitDistribution? footStrikeDistance;
  final RunningGaitDistribution? kneeAtContact;
  final RunningGaitDistribution? minimumKneeFlexion;
  final RunningGaitDistribution? recoveryKneeFlexion;
  final RunningGaitDistribution? forwardLeanAtContact;
  final RunningGaitDistribution? elbowAtContact;
  final double? cadenceSpm;
  final double? medianStepTimeMs;
  final double? leftRightStepTimeAsymmetryPercent;
  final double? leftRightFootStrikeDifferenceRatio;
  final double? leftRightKneeDifferenceDegrees;

  const RunningGaitAnalysis({
    required this.steps,
    required this.footStrikeDistance,
    required this.kneeAtContact,
    required this.minimumKneeFlexion,
    required this.recoveryKneeFlexion,
    required this.forwardLeanAtContact,
    required this.elbowAtContact,
    required this.cadenceSpm,
    required this.medianStepTimeMs,
    required this.leftRightStepTimeAsymmetryPercent,
    required this.leftRightFootStrikeDifferenceRatio,
    required this.leftRightKneeDifferenceDegrees,
  });

  int get reliableStepCount => steps.where((step) => step.isReliable).length;

  bool get hasReliableStepSample =>
      reliableStepCount >= runningCoachMinimumReliableMetricSamples;

  int get leftStepCount =>
      steps.where((step) => step.side == RunningContactSide.left).length;

  int get rightStepCount =>
      steps.where((step) => step.side == RunningContactSide.right).length;

  bool get hasBilateralSample => leftStepCount >= 2 && rightStepCount >= 2;
}

RunningGaitAnalysis? _deriveRunningGaitAnalysis(
  RunningVideoAnalysisResult result,
) {
  if (!result.hasObservedContactEvidence ||
      result.poseFrames.isEmpty ||
      result.contactWindows.isEmpty) {
    return null;
  }
  final frames = result.poseFrames;
  final validated = result.validatedContactFrameTimestamps
      .map((timestamp) => timestamp.inMilliseconds)
      .toSet();
  final hasWindowLevelContactEvidence = result.contactWindows.any(
    (window) => window.validatedContactTimestamps.isNotEmpty,
  );
  final consumedTimestamps = <int>{};
  final steps = <RunningGaitStep>[];

  for (final window in result.contactWindows) {
    if (window.side == RunningContactSide.unknown) continue;
    final windowContacts = window.validatedContactTimestamps
        .map((timestamp) => timestamp.inMilliseconds)
        .toSet();
    // Fresh analyzer payloads identify the exact window/side that produced
    // each contact. Do not let another overlapping recovery window claim the
    // timestamp. The range fallback is only for older saved snapshots.
    final contactCandidates = (hasWindowLevelContactEvidence
            ? windowContacts
            : validated.where(
                (timestamp) =>
                    timestamp >= window.startMs && timestamp <= window.endMs,
              ))
        .toList(growable: false)
      ..sort((left, right) {
        final leftDistance = (left - window.centerMs).abs();
        final rightDistance = (right - window.centerMs).abs();
        return leftDistance == rightDistance
            ? left.compareTo(right)
            : leftDistance.compareTo(rightDistance);
      });
    if (contactCandidates.isEmpty) continue;
    final contactMs = contactCandidates.first;
    if (!consumedTimestamps.add(contactMs)) continue;
    final contactFrame = _nearestPoseFrame(
      frames,
      contactMs,
      toleranceMs: 90,
    );
    if (contactFrame == null) continue;
    final contactMeasurement = _gaitPhaseMeasurement(
      frame: contactFrame,
      phase: RunningGaitPhase.initialContact,
      side: window.side,
      direction: result.direction,
    );
    if (contactMeasurement.kneeAngleDegrees == null ||
        contactMeasurement.footStrikeDistanceRatio == null) {
      continue;
    }

    final recoveryFrame = _recoveryKneeFlexionFrame(
      frames,
      windows: result.contactWindows,
      side: window.side,
      contactMs: contactMs,
    );
    final loweringFrame = _nearestPoseFrameInRange(
      frames,
      targetMs: math.max(window.startMs, contactMs - 90).toInt(),
      minimumMs: window.startMs,
      maximumMs: math.max(window.startMs, contactMs - 20).toInt(),
      toleranceMs: 90,
    );
    final phaseEndMs = math.min(window.endMs, contactMs + 220).toInt();
    final phaseFrames = frames
        .where(
          (frame) =>
              frame.timestampMs >= contactMs && frame.timestampMs <= phaseEndMs,
        )
        .toList(growable: false);
    final kneeFlexionFrame = _minimumKneeAngleFrame(
      phaseFrames,
      side: window.side,
    );
    final exitFrame = _lastPoseFrameInRange(
      frames,
      minimumMs: math.min(window.endMs, contactMs + 50).toInt(),
      maximumMs: window.endMs,
    );
    final recoveryMeasurement = recoveryFrame == null
        ? null
        : _gaitPhaseMeasurement(
            frame: recoveryFrame,
            phase: RunningGaitPhase.recovery,
            side: window.side,
            direction: result.direction,
          );
    final loweringMeasurement = loweringFrame == null
        ? null
        : _gaitPhaseMeasurement(
            frame: loweringFrame,
            phase: RunningGaitPhase.lowering,
            side: window.side,
            direction: result.direction,
          );
    final supportMeasurement = kneeFlexionFrame == null
        ? null
        : _gaitPhaseMeasurement(
            frame: kneeFlexionFrame,
            phase: RunningGaitPhase.support,
            side: window.side,
            direction: result.direction,
          );
    final pushOffMeasurement = exitFrame == null
        ? null
        : _gaitPhaseMeasurement(
            frame: exitFrame,
            phase: RunningGaitPhase.pushOff,
            side: window.side,
            direction: result.direction,
          );
    final stepConfidence = window.confidence > 0
        ? math.min(window.confidence, contactMeasurement.confidence)
        : contactMeasurement.confidence;
    steps.add(
      RunningGaitStep(
        side: window.side,
        contactTimestamp: contactMeasurement.timestamp,
        confidence: stepConfidence.clamp(0.0, 1.0).toDouble(),
        recovery: recoveryMeasurement,
        lowering: loweringMeasurement,
        preContact: loweringMeasurement,
        initialContact: contactMeasurement,
        support: supportMeasurement,
        maximumKneeFlexion: supportMeasurement,
        pushOff: pushOffMeasurement,
        contactExit: pushOffMeasurement,
      ),
    );
  }

  steps.sort(
    (left, right) => left.contactTimestamp.compareTo(right.contactTimestamp),
  );
  final alternatingSteps = _alternatingGaitSteps(steps);
  if (alternatingSteps.isEmpty) return null;

  final reliableSteps =
      alternatingSteps.where((step) => step.isReliable).toList(
            growable: false,
          );
  final source =
      reliableSteps.length >= runningCoachMinimumReliableMetricSamples
          ? reliableSteps
          : alternatingSteps;
  final footStrike = RunningGaitDistribution.fromValues(
    source.map((step) => step.footStrikeDistanceRatio),
  );
  final kneeAtContact = RunningGaitDistribution.fromValues(
    source.map((step) => step.kneeAtContactDegrees),
  );
  final minimumKneeFlexion = RunningGaitDistribution.fromValues(
    source.map((step) => step.minimumKneeAngleDegrees),
  );
  final recoveryKneeFlexion = RunningGaitDistribution.fromValues(
    source.map((step) => step.recoveryKneeAngleDegrees),
  );
  final forwardLean = RunningGaitDistribution.fromValues(
    source.map((step) => step.forwardLeanAtContactDegrees),
  );
  final elbow = RunningGaitDistribution.fromValues(
    source.map((step) => step.elbowAtContactDegrees),
  );
  final timing = _gaitTimingSummary(source);
  final left = source
      .where((step) => step.side == RunningContactSide.left)
      .toList(growable: false);
  final right = source
      .where((step) => step.side == RunningContactSide.right)
      .toList(growable: false);
  final leftFoot = RunningGaitDistribution.fromValues(
    left.map((step) => step.footStrikeDistanceRatio),
  );
  final rightFoot = RunningGaitDistribution.fromValues(
    right.map((step) => step.footStrikeDistanceRatio),
  );
  final leftKnee = RunningGaitDistribution.fromValues(
    left.map((step) => step.kneeAtContactDegrees),
  );
  final rightKnee = RunningGaitDistribution.fromValues(
    right.map((step) => step.kneeAtContactDegrees),
  );

  return RunningGaitAnalysis(
    steps: List<RunningGaitStep>.unmodifiable(alternatingSteps),
    footStrikeDistance: footStrike,
    kneeAtContact: kneeAtContact,
    minimumKneeFlexion: minimumKneeFlexion,
    recoveryKneeFlexion: recoveryKneeFlexion,
    forwardLeanAtContact: forwardLean,
    elbowAtContact: elbow,
    cadenceSpm: timing.cadenceSpm,
    medianStepTimeMs: timing.medianStepTimeMs,
    leftRightStepTimeAsymmetryPercent: timing.asymmetryPercent,
    leftRightFootStrikeDifferenceRatio: leftFoot != null &&
            rightFoot != null &&
            left.length >= 2 &&
            right.length >= 2
        ? (leftFoot.median - rightFoot.median).abs()
        : null,
    leftRightKneeDifferenceDegrees: leftKnee != null &&
            rightKnee != null &&
            left.length >= 2 &&
            right.length >= 2
        ? (leftKnee.median - rightKnee.median).abs()
        : null,
  );
}

List<RunningGaitStep> _alternatingGaitSteps(List<RunningGaitStep> steps) {
  final filtered = <RunningGaitStep>[];
  for (final step in steps) {
    if (filtered.isEmpty ||
        step.side == RunningContactSide.unknown ||
        filtered.last.side == RunningContactSide.unknown ||
        step.side != filtered.last.side) {
      filtered.add(step);
      continue;
    }
    if (step.confidence > filtered.last.confidence) {
      filtered[filtered.length - 1] = step;
    }
  }
  return filtered;
}

List<RunningMetricEvidence> _deriveRunningMetricEvidence(
  RunningVideoAnalysisResult result,
) {
  final items = <RunningMetricEvidence>[];
  final rhythm = _rhythmMetricEvidence(result);
  if (rhythm != null) {
    items.add(rhythm);
  }
  items
    ..add(_poseMetricEvidence(result, RunningCoachMetric.posture))
    ..add(_poseMetricEvidence(result, RunningCoachMetric.footStrike))
    ..add(_poseMetricEvidence(result, RunningCoachMetric.kneeFlexion))
    ..add(_poseMetricEvidence(result, RunningCoachMetric.bounce))
    ..add(_poseMetricEvidence(result, RunningCoachMetric.armCarriage));
  return List<RunningMetricEvidence>.unmodifiable(items);
}

RunningMetricEvidence? _rhythmMetricEvidence(
  RunningVideoAnalysisResult result,
) {
  final rhythm = result.rhythmAnalysis;
  if (rhythm == null) {
    final cadence = result.measurementFor(RunningAnalysisMetric.cadence);
    final stepTime = result.measurementFor(RunningAnalysisMetric.stepTime);
    final asymmetry =
        result.measurementFor(RunningAnalysisMetric.leftRightTiming);
    final timestamps = <Duration>{
      ...cadence.evidenceTimestamps,
      ...stepTime.evidenceTimestamps,
    }.toList(growable: false)
      ..sort();
    if (cadence.state == RunningMeasurementState.unavailable &&
        stepTime.state == RunningMeasurementState.unavailable) {
      return null;
    }
    return RunningMetricEvidence(
      kind: RunningMetricEvidenceKind.rhythm,
      metric: null,
      frames: timestamps.take(4).map((timestamp) {
        return RunningMetricEvidenceFrame(
          timestamp: timestamp,
          role: RunningMetricEvidenceFrameRole.rhythmContact,
          confidence: math.max(cadence.confidence, stepTime.confidence),
          poseFrame: _nearestPoseFrame(
            result.poseFrames,
            timestamp.inMilliseconds,
            toleranceMs: 180,
          ),
          values: <String, double>{
            if (cadence.value != null) 'cadenceSpm': cadence.value!,
            if (stepTime.value != null) 'stepTimeMs': stepTime.value!,
            if (asymmetry.value != null)
              'leftRightStepTimeAsymmetryPercent': asymmetry.value!,
          },
        );
      }).toList(growable: false),
      measuredValues: <String, double>{
        if (cadence.value != null) 'cadenceSpm': cadence.value!,
        if (stepTime.value != null) 'stepTimeMs': stepTime.value!,
        if (asymmetry.value != null)
          'leftRightStepTimeAsymmetryPercent': asymmetry.value!,
      },
      sampleCount: math.max(cadence.sampleCount, stepTime.sampleCount),
      reliability: math.max(cadence.confidence, stepTime.confidence),
      withheldReason: RunningMetricEvidenceWithheldReason.lowConfidence,
    );
  }
  final reliableContacts = rhythm.contacts
      .where((contact) =>
          contact.confidence >= runningCoachReliableMetricConfidence)
      .toList(growable: false);
  final reliability = rhythm.contacts.isEmpty
      ? 0.0
      : rhythm.contacts
              .map((contact) => contact.confidence)
              .reduce((sum, value) => sum + value) /
          rhythm.contacts.length;
  final contacts =
      reliableContacts.isEmpty ? rhythm.contacts : reliableContacts;
  final frames = contacts.take(4).map((contact) {
    final poseFrame = _nearestPoseFrame(
      result.poseFrames,
      contact.timestamp.inMilliseconds,
      toleranceMs: 90,
    );
    return RunningMetricEvidenceFrame(
      timestamp: contact.timestamp,
      role: RunningMetricEvidenceFrameRole.rhythmContact,
      side: contact.side,
      poseFrame: poseFrame,
      confidence: contact.confidence,
      values: <String, double>{
        if (rhythm.cadenceSpm != null) 'cadenceSpm': rhythm.cadenceSpm!,
        if (rhythm.medianStepTimeMs != null)
          'stepTimeMs': rhythm.medianStepTimeMs!,
        if (rhythm.leftRightStepTimeAsymmetryPercent != null)
          'leftRightStepTimeAsymmetryPercent':
              rhythm.leftRightStepTimeAsymmetryPercent!,
      },
    );
  }).toList(growable: false);
  return RunningMetricEvidence(
    kind: RunningMetricEvidenceKind.rhythm,
    metric: null,
    frames: frames,
    measuredValues: <String, double>{
      if (rhythm.cadenceSpm != null) 'cadenceSpm': rhythm.cadenceSpm!,
      if (rhythm.medianStepTimeMs != null)
        'stepTimeMs': rhythm.medianStepTimeMs!,
      if (rhythm.leftRightStepTimeAsymmetryPercent != null)
        'leftRightStepTimeAsymmetryPercent':
            rhythm.leftRightStepTimeAsymmetryPercent!,
    },
    sampleCount: rhythm.contacts.length,
    reliability: reliability.clamp(0.0, 1.0).toDouble(),
    withheldReason: rhythm.hasReliableSample
        ? null
        : RunningMetricEvidenceWithheldReason.limitedSamples,
  );
}

RunningMetricEvidence _poseMetricEvidence(
  RunningVideoAnalysisResult result,
  RunningCoachMetric metric,
) {
  final quality = _metricEvidenceQualityFor(result, metric);
  final gate = _metricEvidenceGateFor(result, metric, quality);
  // Low-confidence or sparse *measured* frames are still useful to show as
  // observations. They remain explicitly withheld from scoring and coaching,
  // but the runner can inspect what the model actually saw. Missing contacts
  // and missing pose frames are hard stops because there is no defensible
  // frame to show for that metric.
  final canShowObservation =
      gate == RunningMetricEvidenceWithheldReason.lowConfidence ||
          gate == RunningMetricEvidenceWithheldReason.limitedSamples;
  if (gate != null && !canShowObservation) {
    return _withheldMetricEvidence(
      result,
      metric,
      quality,
      reason: gate,
    );
  }

  final candidates = switch (metric) {
    RunningCoachMetric.posture => _postureEvidenceCandidates(result),
    RunningCoachMetric.bounce => _bounceEvidenceCandidates(result),
    RunningCoachMetric.footStrike => _landingEvidenceCandidates(result),
    RunningCoachMetric.kneeFlexion => _kneeEvidenceCandidates(result),
    RunningCoachMetric.armCarriage => _armEvidenceCandidates(result),
  };
  if (candidates.isEmpty) {
    return _withheldMetricEvidence(
      result,
      metric,
      quality,
      reason: RunningMetricEvidenceWithheldReason.missingMeasuredFrames,
    );
  }

  final frames = candidates
      .map(
        (candidate) => RunningMetricEvidenceFrame(
          timestamp: candidate.timestamp,
          role: candidate.role,
          phase: candidate.phase,
          side: candidate.side,
          poseFrame: candidate.poseFrame,
          confidence: candidate.confidence,
          values: candidate.values,
        ),
      )
      .toList(growable: false)
    ..sort((left, right) => left.timestamp.compareTo(right.timestamp));
  final sampleCount =
      quality.sampleCount == 0 ? candidates.length : quality.sampleCount;
  return RunningMetricEvidence(
    kind: _evidenceKindForMetric(metric),
    metric: metric,
    frames: frames,
    measuredValues: _measuredValuesForMetric(result, metric),
    sampleCount: sampleCount,
    reliability: quality.confidence,
    withheldReason: gate,
  );
}

RunningMetricEvidence _withheldMetricEvidence(
  RunningVideoAnalysisResult result,
  RunningCoachMetric metric,
  RunningMetricQuality quality, {
  required RunningMetricEvidenceWithheldReason reason,
}) {
  return RunningMetricEvidence(
    kind: _evidenceKindForMetric(metric),
    metric: metric,
    frames: const <RunningMetricEvidenceFrame>[],
    measuredValues: const <String, double>{},
    sampleCount: quality.sampleCount,
    reliability: quality.confidence,
    withheldReason: reason,
  );
}

RunningMetricEvidenceWithheldReason? _metricEvidenceGateFor(
  RunningVideoAnalysisResult result,
  RunningCoachMetric metric,
  RunningMetricQuality quality,
) {
  if (quality.isContactPhaseProxy) {
    return RunningMetricEvidenceWithheldReason.missingContact;
  }
  if (quality.confidence < runningCoachReliableMetricConfidence) {
    return RunningMetricEvidenceWithheldReason.lowConfidence;
  }
  final minimumSamples = switch (metric) {
    RunningCoachMetric.footStrike ||
    RunningCoachMetric.kneeFlexion =>
      runningCoachMinimumReliableMetricSamples,
    RunningCoachMetric.posture ||
    RunningCoachMetric.bounce ||
    RunningCoachMetric.armCarriage =>
      5,
  };
  if (quality.sampleCount != 0 && quality.sampleCount < minimumSamples) {
    return RunningMetricEvidenceWithheldReason.limitedSamples;
  }
  if (result.poseFrames.isEmpty) {
    return RunningMetricEvidenceWithheldReason.missingPoseFrames;
  }
  if ((metric == RunningCoachMetric.footStrike ||
          metric == RunningCoachMetric.kneeFlexion) &&
      (result.contactWindows.isEmpty ||
          !result.hasObservedContactEvidence ||
          result.gaitAnalysis == null)) {
    final analysisMetric = metric == RunningCoachMetric.footStrike
        ? RunningAnalysisMetric.footStrike
        : RunningAnalysisMetric.kneeAtContact;
    final measurement = result.measurementFor(analysisMetric);
    if (measurement.state == RunningMeasurementState.estimated &&
        measurement.evidenceTimestamps.isNotEmpty) {
      return RunningMetricEvidenceWithheldReason.lowConfidence;
    }
    return RunningMetricEvidenceWithheldReason.missingContact;
  }
  return null;
}

RunningMetricQuality _metricEvidenceQualityFor(
  RunningVideoAnalysisResult result,
  RunningCoachMetric metric,
) {
  final perspectiveReason =
      result.perspectiveQuality.limitationReasonForMetric(metric);
  RunningMetricQuality applyPerspectiveGate(RunningMetricQuality quality) {
    if (perspectiveReason == null) return quality;
    if (quality.hasBlockingMeasurementReason) return quality;
    return quality.copyWith(
      confidence: math.min(quality.confidence, 0.55),
      reason: perspectiveReason,
    );
  }

  final quality = result.qualityFor(metric);
  if (quality != null) return applyPerspectiveGate(quality);
  if (result.metricQualities.isNotEmpty) {
    return applyPerspectiveGate(const RunningMetricQuality(
      confidence: 0,
      sampleCount: 0,
      reason: 'metric_unavailable',
    ));
  }
  final reason = result.validFrameCoverage < 0.6
      ? 'low_coverage'
      : result.validFrames < 7
          ? 'limited_samples'
          : null;
  return applyPerspectiveGate(RunningMetricQuality(
    confidence: result.analysisConfidence,
    sampleCount: result.validFrames,
    reason: reason,
  ));
}

Map<String, double> _measuredValuesForMetric(
  RunningVideoAnalysisResult result,
  RunningCoachMetric metric,
) {
  final measurement = result.measurementFor(switch (metric) {
    RunningCoachMetric.posture => RunningAnalysisMetric.posture,
    RunningCoachMetric.bounce => RunningAnalysisMetric.bounce,
    RunningCoachMetric.footStrike => RunningAnalysisMetric.footStrike,
    RunningCoachMetric.kneeFlexion => RunningAnalysisMetric.kneeAtContact,
    RunningCoachMetric.armCarriage => RunningAnalysisMetric.elbowAngle,
  });
  final value = measurement.value;
  if (value == null || !value.isFinite) return const <String, double>{};
  return switch (metric) {
    RunningCoachMetric.posture => <String, double>{
        'forwardLeanDegrees': value,
      },
    RunningCoachMetric.bounce => <String, double>{
        'verticalBouncePercent': value,
      },
    RunningCoachMetric.footStrike => <String, double>{
        'footStrikeDistanceRatio': value,
      },
    RunningCoachMetric.kneeFlexion => <String, double>{
        'kneeAngleDegrees': value,
      },
    RunningCoachMetric.armCarriage => <String, double>{
        'elbowAngleDegrees': value,
      },
  };
}

RunningMetricEvidenceKind _evidenceKindForMetric(RunningCoachMetric metric) {
  return switch (metric) {
    RunningCoachMetric.posture => RunningMetricEvidenceKind.posture,
    RunningCoachMetric.bounce => RunningMetricEvidenceKind.bounce,
    RunningCoachMetric.footStrike => RunningMetricEvidenceKind.landing,
    RunningCoachMetric.kneeFlexion => RunningMetricEvidenceKind.knee,
    RunningCoachMetric.armCarriage => RunningMetricEvidenceKind.arms,
  };
}

class _RunningMetricEvidenceCandidate {
  final Duration timestamp;
  final RunningMetricEvidenceFrameRole role;
  final RunningGaitPhase? phase;
  final RunningContactSide side;
  final RunningPoseFrame poseFrame;
  final Map<String, double> values;
  final double confidence;

  _RunningMetricEvidenceCandidate({
    required this.timestamp,
    required this.role,
    required this.poseFrame,
    required this.values,
    required this.confidence,
    this.phase,
    this.side = RunningContactSide.unknown,
  });
}

List<_RunningMetricEvidenceCandidate> _postureEvidenceCandidates(
  RunningVideoAnalysisResult result,
) {
  final candidates = <_RunningMetricEvidenceCandidate>[];
  for (final frame in result.poseFrames) {
    final value = _forwardLeanDegrees(frame, result.direction);
    if (value == null) continue;
    candidates.add(
      _RunningMetricEvidenceCandidate(
        timestamp: frame.timestamp,
        role: RunningMetricEvidenceFrameRole.representativePosture,
        poseFrame: frame,
        values: <String, double>{'forwardLeanDegrees': value},
        confidence:
            _landmarkConfidenceAverage(frame, const <int>[11, 12, 23, 24]),
      ),
    );
  }
  return _selectClosestEvidenceCandidates(
    candidates,
    target: result.forwardLeanDegrees,
    valueKey: 'forwardLeanDegrees',
  );
}

List<_RunningMetricEvidenceCandidate> _landingEvidenceCandidates(
  RunningVideoAnalysisResult result,
) {
  final gait = result.gaitAnalysis;
  final candidates = <_RunningMetricEvidenceCandidate>[];
  // A real, pose-paired contact remains useful as an explicitly limited
  // observation even before there are enough stable steps for coaching. The
  // per-metric quality gate keeps these frames out of scores and drills.
  for (final step in gait?.steps ?? const <RunningGaitStep>[]) {
    void addLandingPhase(
      RunningGaitPhaseMeasurement? measurement,
      RunningMetricEvidenceFrameRole role,
    ) {
      if (measurement == null) return;
      final value = measurement.footStrikeDistanceRatio;
      if (value == null) return;
      final poseFrame = _nearestPoseFrame(
        result.poseFrames,
        measurement.timestamp.inMilliseconds,
        toleranceMs: 90,
      );
      if (poseFrame == null) return;
      candidates.add(
        _RunningMetricEvidenceCandidate(
          timestamp: measurement.timestamp,
          role: role,
          phase: measurement.phase,
          side: step.side,
          poseFrame: poseFrame,
          values: <String, double>{'footStrikeDistanceRatio': value},
          confidence: math.min(step.confidence, measurement.confidence),
        ),
      );
    }

    addLandingPhase(step.lowering, RunningMetricEvidenceFrameRole.lowering);
    addLandingPhase(
      step.initialContact,
      RunningMetricEvidenceFrameRole.initialContact,
    );
    addLandingPhase(
      step.pushOff ?? step.contactExit,
      RunningMetricEvidenceFrameRole.pushOff,
    );
  }
  if (candidates.isEmpty) {
    final measurement = result.measurementFor(RunningAnalysisMetric.footStrike);
    for (final timestamp in measurement.evidenceTimestamps) {
      final poseFrame = _nearestPoseFrame(
        result.poseFrames,
        timestamp.inMilliseconds,
        toleranceMs: 180,
      );
      if (poseFrame == null) continue;
      final side = _estimatedSideForTimestamp(result, timestamp);
      final value = _footStrikeDistanceRatio(
        poseFrame,
        side,
        result.direction,
      );
      if (value == null) continue;
      candidates.add(_RunningMetricEvidenceCandidate(
        timestamp: poseFrame.timestamp,
        role: RunningMetricEvidenceFrameRole.initialContact,
        phase: RunningGaitPhase.initialContact,
        side: side,
        poseFrame: poseFrame,
        values: <String, double>{'footStrikeDistanceRatio': value},
        confidence: measurement.confidence,
      ));
    }
  }
  return _selectLandingEvidenceCandidates(result, candidates);
}

List<_RunningMetricEvidenceCandidate> _selectLandingEvidenceCandidates(
  RunningVideoAnalysisResult result,
  List<_RunningMetricEvidenceCandidate> candidates,
) {
  if (candidates.isEmpty) return const <_RunningMetricEvidenceCandidate>[];
  final selected = <_RunningMetricEvidenceCandidate>[];
  void selectRole(RunningMetricEvidenceFrameRole role) {
    final roleCandidates = candidates
        .where((candidate) => candidate.role == role)
        .toList(growable: false);
    if (roleCandidates.isEmpty) return;
    roleCandidates.sort((left, right) {
      final target = result.footStrikeDistanceRatio;
      final leftDistance =
          ((left.values['footStrikeDistanceRatio'] ?? target) - target).abs();
      final rightDistance =
          ((right.values['footStrikeDistanceRatio'] ?? target) - target).abs();
      return leftDistance == rightDistance
          ? left.timestamp.compareTo(right.timestamp)
          : leftDistance.compareTo(rightDistance);
    });
    selected.add(roleCandidates.first);
  }

  selectRole(RunningMetricEvidenceFrameRole.lowering);
  selectRole(RunningMetricEvidenceFrameRole.initialContact);
  selectRole(RunningMetricEvidenceFrameRole.pushOff);
  if (selected.isEmpty) {
    return _selectClosestEvidenceCandidates(
      candidates,
      target: result.footStrikeDistanceRatio,
      valueKey: 'footStrikeDistanceRatio',
    );
  }
  selected.sort((left, right) => left.timestamp.compareTo(right.timestamp));
  return selected.take(3).toList(growable: false);
}

List<_RunningMetricEvidenceCandidate> _kneeEvidenceCandidates(
  RunningVideoAnalysisResult result,
) {
  final gait = result.gaitAnalysis;
  final candidates = <_RunningMetricEvidenceCandidate>[];
  for (final step in gait?.steps ?? const <RunningGaitStep>[]) {
    void addPhaseCandidate(
      RunningGaitPhaseMeasurement? measurement,
      RunningMetricEvidenceFrameRole role,
    ) {
      if (measurement == null) return;
      final value = measurement.kneeAngleDegrees;
      if (value == null) return;
      final poseFrame = _nearestPoseFrame(
        result.poseFrames,
        measurement.timestamp.inMilliseconds,
        toleranceMs: 90,
      );
      if (poseFrame == null) return;
      candidates.add(
        _RunningMetricEvidenceCandidate(
          timestamp: measurement.timestamp,
          role: role,
          phase: measurement.phase,
          side: step.side,
          poseFrame: poseFrame,
          values: <String, double>{'kneeAngleDegrees': value},
          confidence: math.min(step.confidence, measurement.confidence),
        ),
      );
    }

    addPhaseCandidate(
      step.initialContact,
      RunningMetricEvidenceFrameRole.initialContact,
    );
    addPhaseCandidate(
      step.maximumKneeFlexion,
      RunningMetricEvidenceFrameRole.maximumKneeFlexion,
    );
    addPhaseCandidate(
      step.recovery,
      RunningMetricEvidenceFrameRole.recoveryKneeFlexion,
    );
  }
  if (candidates.isEmpty) {
    final measurement =
        result.measurementFor(RunningAnalysisMetric.kneeAtContact);
    for (final timestamp in measurement.evidenceTimestamps) {
      final poseFrame = _nearestPoseFrame(
        result.poseFrames,
        timestamp.inMilliseconds,
        toleranceMs: 180,
      );
      if (poseFrame == null) continue;
      final side = _estimatedSideForTimestamp(result, timestamp);
      final value = _kneeAngle(poseFrame, side);
      if (value == null) continue;
      candidates.add(_RunningMetricEvidenceCandidate(
        timestamp: poseFrame.timestamp,
        role: RunningMetricEvidenceFrameRole.initialContact,
        phase: RunningGaitPhase.initialContact,
        side: side,
        poseFrame: poseFrame,
        values: <String, double>{'kneeAngleDegrees': value},
        confidence: measurement.confidence,
      ));
    }
  }
  return _selectKneeEvidenceCandidates(result, candidates);
}

List<_RunningMetricEvidenceCandidate> _selectKneeEvidenceCandidates(
  RunningVideoAnalysisResult result,
  List<_RunningMetricEvidenceCandidate> candidates,
) {
  if (candidates.isEmpty) return const <_RunningMetricEvidenceCandidate>[];
  final selected = <_RunningMetricEvidenceCandidate>[];
  void selectRole(
    RunningMetricEvidenceFrameRole role,
    double? target,
  ) {
    final roleCandidates = candidates
        .where((candidate) => candidate.role == role)
        .toList(growable: false);
    if (roleCandidates.isEmpty) return;
    roleCandidates.sort((left, right) {
      final resolvedTarget = target ??
          left.values['kneeAngleDegrees'] ??
          result.stanceKneeAngleDegrees;
      final leftDistance =
          ((left.values['kneeAngleDegrees'] ?? resolvedTarget) - resolvedTarget)
              .abs();
      final rightDistance =
          ((right.values['kneeAngleDegrees'] ?? resolvedTarget) -
                  resolvedTarget)
              .abs();
      return leftDistance == rightDistance
          ? left.timestamp.compareTo(right.timestamp)
          : leftDistance.compareTo(rightDistance);
    });
    selected.add(roleCandidates.first);
  }

  selectRole(
    RunningMetricEvidenceFrameRole.initialContact,
    result.measurementFor(RunningAnalysisMetric.kneeAtContact).value ??
        result.stanceKneeAngleDegrees,
  );
  selectRole(
    RunningMetricEvidenceFrameRole.maximumKneeFlexion,
    result.measurementFor(RunningAnalysisMetric.maximumKneeFlexion).value,
  );
  selectRole(
    RunningMetricEvidenceFrameRole.recoveryKneeFlexion,
    result.measurementFor(RunningAnalysisMetric.recoveryKneeFlexion).value,
  );
  if (selected.isEmpty) {
    return _selectClosestEvidenceCandidates(
      candidates,
      target: result.stanceKneeAngleDegrees,
      valueKey: 'kneeAngleDegrees',
    );
  }
  selected.sort((left, right) => left.timestamp.compareTo(right.timestamp));
  return selected.take(3).toList(growable: false);
}

RunningContactSide _estimatedSideForTimestamp(
  RunningVideoAnalysisResult result,
  Duration timestamp,
) {
  RunningContactWindow? nearest;
  var nearestDistance = 1 << 30;
  for (final window in result.contactWindows) {
    final distance = (window.centerMs - timestamp.inMilliseconds).abs();
    if (distance < nearestDistance) {
      nearest = window;
      nearestDistance = distance;
    }
  }
  if (nearest?.side != null && nearest!.side != RunningContactSide.unknown) {
    return nearest.side;
  }
  final frame = _nearestPoseFrame(
    result.poseFrames,
    timestamp.inMilliseconds,
    toleranceMs: 180,
  );
  if (frame == null) return RunningContactSide.unknown;
  final left = _posePoint(frame, 27);
  final right = _posePoint(frame, 28);
  if (left == null) return RunningContactSide.right;
  if (right == null) return RunningContactSide.left;
  return left.y >= right.y ? RunningContactSide.left : RunningContactSide.right;
}

List<RunningBounceTrajectoryPoint> runningVerticalBounceTrajectoryForPoseFrames(
  List<RunningPoseFrame> source,
) {
  final frames = source
      .where((frame) => frame.landmarks.length == mediaPipePoseLandmarkCount)
      .toList(growable: false)
    ..sort((left, right) => left.timestampMs.compareTo(right.timestampMs));
  if (frames.length < 3) return const <RunningBounceTrajectoryPoint>[];

  final groundPoints = <_RunningGroundPoint>[];
  for (final frame in frames) {
    final torso = _torsoLengthPx(frame);
    if (torso == null) continue;
    for (final side in const <RunningContactSide>[
      RunningContactSide.left,
      RunningContactSide.right,
    ]) {
      final foot = _footBottomPointPx(frame, side);
      if (foot == null) continue;
      groundPoints.add(_RunningGroundPoint(
        timestamp: frame.timestamp,
        x: foot.x,
        y: foot.y,
        bodyScale: torso,
      ));
    }
  }
  if (groundPoints.length < _runningGroundLineMinimumSamples) {
    return const <RunningBounceTrajectoryPoint>[];
  }
  final groundLine = _runningGroundLineForPoints(groundPoints);
  final raw = <RunningBounceTrajectoryPoint>[];
  for (final frame in frames) {
    final hip = _midpoint(
      _posePointPx(frame, 23),
      _posePointPx(frame, 24),
    );
    final torso = _torsoLengthPx(frame);
    if (hip == null || torso == null) continue;
    final localGroundPoints = groundPoints
        .where(
          (point) =>
              (point.timestamp.inMilliseconds - frame.timestampMs).abs() <= 600,
        )
        .toList(growable: false);
    final localGroundLine =
        localGroundPoints.length >= _runningGroundLineMinimumSamples
            ? _runningGroundLineForPoints(localGroundPoints)
            : groundLine;
    final clearance = (localGroundLine.yAt(hip.x) - hip.y) / torso;
    if (!clearance.isFinite || clearance < 0.20 || clearance > 4.50) {
      continue;
    }
    raw.add(RunningBounceTrajectoryPoint(
      timestamp: frame.timestamp,
      frame: frame,
      value: clearance,
      confidence: math.min(
        hip.confidence,
        _landmarkConfidenceAverage(frame, const <int>[11, 12, 23, 24]),
      ),
    ));
  }
  if (raw.length < 3) return const <RunningBounceTrajectoryPoint>[];

  final first = raw.first;
  final last = raw.last;
  final durationMs =
      math.max(1, last.timestampMs - first.timestampMs).toDouble();
  final drift = last.value - first.value;
  final corrected = raw.map((point) {
    final fraction = (point.timestampMs - first.timestampMs) / durationMs;
    return RunningBounceTrajectoryPoint(
      timestamp: point.timestamp,
      frame: point.frame,
      value: point.value - (first.value + (drift * fraction)),
      confidence: point.confidence,
    );
  }).toList(growable: false);
  final values = corrected.map((point) => point.value).toList(growable: false);
  final center = RunningGaitDistribution.fromValues(values)?.median ?? 0;
  final deviations = corrected
      .map((point) => (point.value - center).abs())
      .toList(growable: false);
  final medianDeviation =
      RunningGaitDistribution.fromValues(deviations)?.median ?? 0;
  final tolerance = math.max(0.18, medianDeviation * 4.0);
  return List<RunningBounceTrajectoryPoint>.unmodifiable(
    corrected.where((point) => (point.value - center).abs() <= tolerance),
  );
}

double? runningVerticalBounceRatioForPoseFrames(
  List<RunningPoseFrame> source,
) {
  final trajectory = runningVerticalBounceTrajectoryForPoseFrames(source);
  if (trajectory.length < _runningMinimumBounceTrajectorySamples) return null;
  final spans = _runningBounceWindowRatios(trajectory);
  if (spans.isNotEmpty) {
    spans.sort();
    return math.max(0, _runningQuantile(spans, 0.50));
  }
  final values = trajectory.map((point) => point.value).toList()..sort();
  return math.max(
    0,
    _runningQuantile(values, 0.90) - _runningQuantile(values, 0.10),
  );
}

List<double> _runningBounceWindowRatios(
  List<RunningBounceTrajectoryPoint> source,
) {
  final trajectory = source.toList(growable: false)
    ..sort((left, right) => left.timestamp.compareTo(right.timestamp));
  if (trajectory.length < 3) return <double>[];

  final firstMs = trajectory.first.timestampMs;
  final lastMs = trajectory.last.timestampMs;
  if (lastMs <= firstMs) return <double>[];

  final resampled = <({int timestampMs, double value, double confidence})>[];
  var cursor = 0;
  for (var timestampMs = firstMs;
      timestampMs <= lastMs;
      timestampMs += _runningBounceResampleInterval.inMilliseconds) {
    while (cursor < trajectory.length - 2 &&
        trajectory[cursor + 1].timestampMs < timestampMs) {
      cursor += 1;
    }
    final before = trajectory[cursor];
    final after = trajectory[math.min(cursor + 1, trajectory.length - 1)];
    if (timestampMs < before.timestampMs || timestampMs > after.timestampMs) {
      continue;
    }
    final gapMs = after.timestampMs - before.timestampMs;
    if (gapMs <= 0 || gapMs > 300) continue;
    final fraction = (timestampMs - before.timestampMs) / gapMs;
    resampled.add((
      timestampMs: timestampMs,
      value: before.value + ((after.value - before.value) * fraction),
      confidence: math.min(before.confidence, after.confidence),
    ));
  }
  if (resampled.length < 3) return <double>[];

  final spans = <double>[];
  for (var windowStartMs = firstMs;
      windowStartMs <= lastMs - _runningBounceWindow.inMilliseconds;
      windowStartMs += _runningBounceWindowStep.inMilliseconds) {
    final windowEndMs = windowStartMs + _runningBounceWindow.inMilliseconds;
    final values = resampled
        .where((sample) =>
            sample.timestampMs >= windowStartMs &&
            sample.timestampMs <= windowEndMs)
        .map((sample) => sample.value)
        .toList(growable: false);
    if (values.length < 3) continue;
    values.sort();
    spans.add(math.max(
      0,
      _runningQuantile(values, 0.90) - _runningQuantile(values, 0.10),
    ));
  }
  return spans;
}

List<_RunningMetricEvidenceCandidate> _bounceEvidenceCandidates(
  RunningVideoAnalysisResult result,
) {
  final trajectory =
      runningVerticalBounceTrajectoryForPoseFrames(result.poseFrames);
  if (trajectory.length < 2) return const <_RunningMetricEvidenceCandidate>[];

  var high = trajectory.first;
  var low = trajectory.first;
  for (final item in trajectory.skip(1)) {
    if (item.value > high.value) high = item;
    if (item.value < low.value) low = item;
  }
  if (high.timestamp == low.timestamp) {
    return const <_RunningMetricEvidenceCandidate>[];
  }
  final trajectoryPercent = (high.value - low.value).abs() * 100;
  final metricPercent = result.verticalBounceRatio * 100;
  final candidates = <_RunningMetricEvidenceCandidate>[
    _RunningMetricEvidenceCandidate(
      timestamp: high.timestamp,
      role: RunningMetricEvidenceFrameRole.trajectoryHigh,
      poseFrame: high.frame,
      values: <String, double>{
        'verticalBouncePercent': metricPercent,
        'trajectoryPercent': trajectoryPercent,
      },
      confidence: high.confidence,
    ),
    _RunningMetricEvidenceCandidate(
      timestamp: low.timestamp,
      role: RunningMetricEvidenceFrameRole.trajectoryLow,
      poseFrame: low.frame,
      values: <String, double>{
        'verticalBouncePercent': metricPercent,
        'trajectoryPercent': trajectoryPercent,
      },
      confidence: low.confidence,
    ),
  ];
  candidates.sort((left, right) => left.timestamp.compareTo(right.timestamp));
  return candidates;
}

List<_RunningMetricEvidenceCandidate> _armEvidenceCandidates(
  RunningVideoAnalysisResult result,
) {
  final armFrames = <({RunningPoseFrame frame, double angle})>[];
  for (final frame in result.poseFrames) {
    final angle = _averageElbowAngle(frame);
    if (angle == null) continue;
    armFrames.add((frame: frame, angle: angle));
  }
  if (armFrames.isEmpty) return const <_RunningMetricEvidenceCandidate>[];

  var closed = armFrames.first;
  var open = armFrames.first;
  for (final item in armFrames.skip(1)) {
    if (item.angle < closed.angle) closed = item;
    if (item.angle > open.angle) open = item;
  }
  final candidates = <_RunningMetricEvidenceCandidate>[];
  void addArmCandidate(
    ({RunningPoseFrame frame, double angle}) item,
    RunningMetricEvidenceFrameRole role,
  ) {
    if (candidates.any(
      (candidate) => candidate.timestamp == item.frame.timestamp,
    )) {
      return;
    }
    candidates.add(
      _RunningMetricEvidenceCandidate(
        timestamp: item.frame.timestamp,
        role: role,
        poseFrame: item.frame,
        values: <String, double>{'elbowAngleDegrees': item.angle},
        confidence: _landmarkConfidenceAverage(
          item.frame,
          const <int>[11, 12, 13, 14, 15, 16],
        ),
      ),
    );
  }

  addArmCandidate(closed, RunningMetricEvidenceFrameRole.armClosed);
  addArmCandidate(open, RunningMetricEvidenceFrameRole.armOpen);
  if (candidates.length < 2 && armFrames.length > 1) {
    addArmCandidate(armFrames.first, RunningMetricEvidenceFrameRole.armClosed);
    addArmCandidate(armFrames.last, RunningMetricEvidenceFrameRole.armOpen);
  }
  if (candidates.length < 3) {
    final representative = _closestArmFrame(
      armFrames,
      target: result.elbowAngleDegrees,
    );
    addArmCandidate(representative, RunningMetricEvidenceFrameRole.armOpen);
  }
  candidates.sort((left, right) => left.timestamp.compareTo(right.timestamp));
  return candidates.take(3).toList(growable: false);
}

({RunningPoseFrame frame, double angle}) _closestArmFrame(
  List<({RunningPoseFrame frame, double angle})> frames, {
  required double target,
}) {
  var closest = frames.first;
  var closestDistance = (closest.angle - target).abs();
  for (final item in frames.skip(1)) {
    final distance = (item.angle - target).abs();
    if (distance < closestDistance) {
      closest = item;
      closestDistance = distance;
    }
  }
  return closest;
}

List<_RunningMetricEvidenceCandidate> _selectClosestEvidenceCandidates(
  List<_RunningMetricEvidenceCandidate> candidates, {
  required double target,
  required String valueKey,
  int limit = 3,
}) {
  if (candidates.isEmpty) return const <_RunningMetricEvidenceCandidate>[];
  final ranked = [...candidates]..sort((left, right) {
      final leftDistance = ((left.values[valueKey] ?? target) - target).abs();
      final rightDistance = ((right.values[valueKey] ?? target) - target).abs();
      return leftDistance == rightDistance
          ? left.timestamp.compareTo(right.timestamp)
          : leftDistance.compareTo(rightDistance);
    });
  final selected = ranked.take(limit).toList(growable: false)
    ..sort((left, right) => left.timestamp.compareTo(right.timestamp));
  return selected;
}

double _landmarkConfidenceAverage(RunningPoseFrame frame, List<int> indexes) {
  final values = indexes
      .map((index) => frame.landmarkByIndex(index)?.confidence)
      .whereType<double>()
      .where((value) => value.isFinite)
      .toList(growable: false);
  if (values.isEmpty) return 0;
  return (values.reduce((sum, value) => sum + value) / values.length)
      .clamp(0.0, 1.0)
      .toDouble();
}

class _RunningGaitTimingSummary {
  final double? cadenceSpm;
  final double? medianStepTimeMs;
  final double? asymmetryPercent;

  const _RunningGaitTimingSummary({
    required this.cadenceSpm,
    required this.medianStepTimeMs,
    required this.asymmetryPercent,
  });
}

_RunningGaitTimingSummary _gaitTimingSummary(List<RunningGaitStep> steps) {
  if (steps.length < 3) {
    return const _RunningGaitTimingSummary(
      cadenceSpm: null,
      medianStepTimeMs: null,
      asymmetryPercent: null,
    );
  }
  final intervals = <double>[];
  final byStartingSide = <RunningContactSide, List<double>>{
    RunningContactSide.left: <double>[],
    RunningContactSide.right: <double>[],
  };
  for (var index = 0; index < steps.length - 1; index += 1) {
    final current = steps[index];
    final next = steps[index + 1];
    if (current.side == next.side) continue;
    final interval = (next.contactTimestamp.inMilliseconds -
            current.contactTimestamp.inMilliseconds)
        .toDouble();
    if (interval < 120 || interval > 1000) continue;
    intervals.add(interval);
    byStartingSide[current.side]!.add(interval);
  }
  final distribution = RunningGaitDistribution.fromValues(intervals);
  final left = RunningGaitDistribution.fromValues(
    byStartingSide[RunningContactSide.left]!,
  );
  final right = RunningGaitDistribution.fromValues(
    byStartingSide[RunningContactSide.right]!,
  );
  final asymmetry = left != null &&
          right != null &&
          left.sampleCount >= 2 &&
          right.sampleCount >= 2
      ? ((left.median - right.median).abs() /
              ((left.median + right.median) / 2) *
              100)
          .clamp(0.0, 100.0)
          .toDouble()
      : null;
  return _RunningGaitTimingSummary(
    cadenceSpm: distribution == null || distribution.median <= 0
        ? null
        : 60000 / distribution.median,
    medianStepTimeMs: distribution?.median,
    asymmetryPercent: asymmetry,
  );
}

RunningPoseFrame? _nearestPoseFrame(
  List<RunningPoseFrame> frames,
  int targetMs, {
  required int toleranceMs,
}) {
  return _nearestPoseFrameInRange(
    frames,
    targetMs: targetMs,
    minimumMs: targetMs - toleranceMs,
    maximumMs: targetMs + toleranceMs,
    toleranceMs: toleranceMs,
  );
}

RunningPoseFrame? _nearestPoseFrameInRange(
  List<RunningPoseFrame> frames, {
  required int targetMs,
  required int minimumMs,
  required int maximumMs,
  required int toleranceMs,
}) {
  RunningPoseFrame? nearest;
  var nearestDistance = toleranceMs + 1;
  for (final frame in frames) {
    final timestamp = frame.timestampMs;
    if (timestamp < minimumMs || timestamp > maximumMs) continue;
    final distance = (timestamp - targetMs).abs();
    if (distance < nearestDistance) {
      nearest = frame;
      nearestDistance = distance;
    }
  }
  return nearestDistance <= toleranceMs ? nearest : null;
}

RunningPoseFrame? _lastPoseFrameInRange(
  List<RunningPoseFrame> frames, {
  required int minimumMs,
  required int maximumMs,
}) {
  RunningPoseFrame? candidate;
  for (final frame in frames) {
    if (frame.timestampMs < minimumMs || frame.timestampMs > maximumMs) {
      continue;
    }
    if (candidate == null || frame.timestampMs > candidate.timestampMs) {
      candidate = frame;
    }
  }
  return candidate;
}

RunningPoseFrame? _minimumKneeAngleFrame(
  List<RunningPoseFrame> frames, {
  required RunningContactSide side,
}) {
  RunningPoseFrame? candidate;
  double? minimum;
  for (final frame in frames) {
    final angle = _kneeAngle(frame, side);
    if (angle == null) continue;
    if (minimum == null || angle < minimum) {
      minimum = angle;
      candidate = frame;
    }
  }
  return candidate;
}

RunningPoseFrame? _recoveryKneeFlexionFrame(
  List<RunningPoseFrame> frames, {
  required List<RunningContactWindow> windows,
  required RunningContactSide side,
  required int contactMs,
}) {
  final previousSameSideContacts = <int>[];
  for (final window in windows) {
    if (window.side != side) continue;
    for (final timestamp in window.validatedContactTimestamps) {
      final timestampMs = timestamp.inMilliseconds;
      if (timestampMs < contactMs) previousSameSideContacts.add(timestampMs);
    }
  }
  previousSameSideContacts.sort();
  final recoveryStartMs = previousSameSideContacts.isEmpty
      ? contactMs - 520
      : previousSameSideContacts.last + 220;
  final recoveryEndMs = contactMs - 120;
  if (recoveryEndMs <= recoveryStartMs) return null;

  final localFrames = frames
      .where(
        (frame) =>
            frame.timestampMs >= recoveryStartMs &&
            frame.timestampMs <= recoveryEndMs,
      )
      .toList(growable: false);
  if (localFrames.isEmpty) return null;
  final footYs = <double>[];
  for (final frame in localFrames) {
    final foot = _footBottomPoint(frame, side);
    if (foot != null) footYs.add(foot.y);
  }
  final groundY = RunningGaitDistribution.fromValues(footYs)?.maximum;
  RunningPoseFrame? candidate;
  double? minimumAngle;
  for (final frame in localFrames) {
    final angle = _kneeAngle(frame, side);
    final foot = _footBottomPoint(frame, side);
    final scale = _bodyScale(frame);
    if (angle == null || foot == null || scale == null) continue;
    final isClearlyAirborne =
        groundY == null || groundY - foot.y >= scale * 0.055;
    if (!isClearlyAirborne) continue;
    if (minimumAngle == null || angle < minimumAngle) {
      minimumAngle = angle;
      candidate = frame;
    }
  }
  return candidate;
}

RunningGaitPhaseMeasurement _gaitPhaseMeasurement({
  required RunningPoseFrame frame,
  required RunningGaitPhase phase,
  required RunningContactSide side,
  required RunningDirection direction,
}) {
  return RunningGaitPhaseMeasurement(
    phase: phase,
    timestamp: frame.timestamp,
    footStrikeDistanceRatio: _footStrikeDistanceRatio(frame, side, direction),
    kneeAngleDegrees: _kneeAngle(frame, side),
    forwardLeanDegrees: _forwardLeanDegrees(frame, direction),
    elbowAngleDegrees: _averageElbowAngle(frame),
    confidence: _phaseConfidence(frame, side),
  );
}

class _RunningPosePoint {
  final double x;
  final double y;
  final double confidence;

  const _RunningPosePoint(this.x, this.y, this.confidence);
}

class _RunningGroundPoint {
  final Duration timestamp;
  final double x;
  final double y;
  final double bodyScale;

  const _RunningGroundPoint({
    required this.timestamp,
    required this.x,
    required this.y,
    required this.bodyScale,
  });
}

class _RunningGroundLine {
  final double slope;
  final double intercept;

  const _RunningGroundLine({
    required this.slope,
    required this.intercept,
  });

  double yAt(double x) => (slope * x) + intercept;
}

const int _runningGroundLineMinimumSamples = 3;
const double _runningGroundLineSampleFraction = 0.45;
const int _runningMinimumBounceTrajectorySamples = 4;

_RunningPosePoint? _posePoint(RunningPoseFrame frame, int index) {
  final landmark = frame.landmarkByIndex(index);
  if (landmark == null ||
      !landmark.x.isFinite ||
      !landmark.y.isFinite ||
      !landmark.confidence.isFinite ||
      landmark.confidence < _runningMinimumLandmarkConfidence ||
      frame.imageWidth <= 0 ||
      frame.imageHeight <= 0) {
    return null;
  }
  return _RunningPosePoint(
    landmark.x * frame.imageWidth,
    landmark.y * frame.imageHeight,
    landmark.confidence.clamp(0.0, 1.0).toDouble(),
  );
}

_RunningPosePoint? _posePointPx(RunningPoseFrame frame, int index) {
  return _posePoint(frame, index);
}

_RunningPosePoint? _midpoint(
  _RunningPosePoint? first,
  _RunningPosePoint? second,
) {
  if (first == null || second == null) return null;
  return _RunningPosePoint(
    (first.x + second.x) / 2,
    (first.y + second.y) / 2,
    math.min(first.confidence, second.confidence),
  );
}

double _distance(_RunningPosePoint first, _RunningPosePoint second) =>
    math.sqrt(
      ((first.x - second.x) * (first.x - second.x)) +
          ((first.y - second.y) * (first.y - second.y)),
    );

double? _bodyScale(RunningPoseFrame frame) {
  final shoulder = _midpoint(_posePoint(frame, 11), _posePoint(frame, 12));
  final hip = _midpoint(_posePoint(frame, 23), _posePoint(frame, 24));
  final ankle = _midpoint(_posePoint(frame, 27), _posePoint(frame, 28));
  if (shoulder == null || hip == null || ankle == null) return null;
  final value = math.max(_distance(shoulder, hip), _distance(hip, ankle));
  return value > 1 ? value : null;
}

double? _torsoLengthPx(RunningPoseFrame frame) {
  final shoulder = _midpoint(_posePointPx(frame, 11), _posePointPx(frame, 12));
  final hip = _midpoint(_posePointPx(frame, 23), _posePointPx(frame, 24));
  if (shoulder == null || hip == null) return null;
  final value = _distance(shoulder, hip);
  return value > 0.0001 ? value : null;
}

_RunningPosePoint? _footBottomPoint(
  RunningPoseFrame frame,
  RunningContactSide side,
) {
  final indexes = side == RunningContactSide.left
      ? const <int>[27, 29, 31]
      : const <int>[28, 30, 32];
  _RunningPosePoint? bottom;
  for (final index in indexes) {
    final point = _posePoint(frame, index);
    if (point == null) continue;
    if (bottom == null || point.y > bottom.y) bottom = point;
  }
  return bottom;
}

_RunningPosePoint? _footBottomPointPx(
  RunningPoseFrame frame,
  RunningContactSide side,
) {
  final indexes = side == RunningContactSide.left
      ? const <int>[27, 29, 31]
      : const <int>[28, 30, 32];
  _RunningPosePoint? bottom;
  for (final index in indexes) {
    final point = _posePointPx(frame, index);
    if (point == null) continue;
    if (bottom == null || point.y > bottom.y) bottom = point;
  }
  return bottom;
}

_RunningGroundLine _leastSquaresRunningGroundLine(
  List<_RunningGroundPoint> points,
) {
  if (points.isEmpty) {
    return const _RunningGroundLine(slope: 0, intercept: 0);
  }
  final meanX =
      points.map((point) => point.x).reduce((sum, value) => sum + value) /
          points.length;
  final meanY =
      points.map((point) => point.y).reduce((sum, value) => sum + value) /
          points.length;
  var covariance = 0.0;
  var variance = 0.0;
  for (final point in points) {
    covariance += (point.x - meanX) * (point.y - meanY);
    variance += (point.x - meanX) * (point.x - meanX);
  }
  final slope = variance <= 0.0001 ? 0.0 : covariance / variance;
  return _RunningGroundLine(
    slope: slope,
    intercept: meanY - (slope * meanX),
  );
}

_RunningGroundLine _runningGroundLineForPoints(
  List<_RunningGroundPoint> points,
) {
  final lowerEnvelopeCount = math.min(
    points.length,
    math.max(
      _runningGroundLineMinimumSamples,
      (points.length * _runningGroundLineSampleFraction).ceil(),
    ),
  );
  final lowerEnvelope = ([...points]..sort((left, right) {
          return right.y.compareTo(left.y);
        }))
      .take(lowerEnvelopeCount)
      .toList(growable: false);
  var line = _leastSquaresRunningGroundLine(lowerEnvelope);
  final residuals = lowerEnvelope
      .map((point) => point.y - line.yAt(point.x))
      .toList(growable: false);
  final residualCenter =
      RunningGaitDistribution.fromValues(residuals)?.median ?? 0;
  final medianDeviation = RunningGaitDistribution.fromValues(
        residuals.map((value) => (value - residualCenter).abs()),
      )?.median ??
      0;
  final averageScale =
      lowerEnvelope.map((point) => point.bodyScale).reduce((a, b) => a + b) /
          lowerEnvelope.length;
  final residualTolerance =
      math.max(averageScale * 0.025, medianDeviation * 2.5);
  final inliers = lowerEnvelope
      .where(
        (point) =>
            (point.y - line.yAt(point.x) - residualCenter).abs() <=
            residualTolerance,
      )
      .toList(growable: false);
  if (inliers.length >= 2) {
    line = _leastSquaresRunningGroundLine(inliers);
  }
  return line;
}

double _runningQuantile(List<double> sortedValues, double fraction) {
  if (sortedValues.isEmpty) return 0;
  final index = ((sortedValues.length - 1) * fraction)
      .clamp(0.0, (sortedValues.length - 1).toDouble())
      .toDouble();
  final lower = index.floor();
  final upper = index.ceil();
  if (lower == upper) return sortedValues[lower];
  return sortedValues[lower] +
      ((sortedValues[upper] - sortedValues[lower]) * (index - lower));
}

double? _footStrikeDistanceRatio(
  RunningPoseFrame frame,
  RunningContactSide side,
  RunningDirection direction,
) {
  if (direction == RunningDirection.stationary) return null;
  final hip = _midpoint(_posePoint(frame, 23), _posePoint(frame, 24));
  final ankle = _posePoint(frame, side == RunningContactSide.left ? 27 : 28);
  final scale = _bodyScale(frame);
  if (hip == null || ankle == null || scale == null) return null;
  final raw = ankle.x - hip.x;
  final forward = switch (direction) {
    RunningDirection.leftToRight => raw,
    RunningDirection.rightToLeft => -raw,
    RunningDirection.stationary => 0.0,
  };
  return math.max(0, forward) / scale;
}

double? _kneeAngle(RunningPoseFrame frame, RunningContactSide side) {
  final indices = side == RunningContactSide.left
      ? const <int>[23, 25, 27]
      : const <int>[24, 26, 28];
  final first = _posePoint(frame, indices[0]);
  final vertex = _posePoint(frame, indices[1]);
  final third = _posePoint(frame, indices[2]);
  if (first == null || vertex == null || third == null) return null;
  return _jointAngle(first, vertex, third);
}

double? _forwardLeanDegrees(
  RunningPoseFrame frame,
  RunningDirection direction,
) {
  if (direction == RunningDirection.stationary) return null;
  final shoulder = _midpoint(_posePoint(frame, 11), _posePoint(frame, 12));
  final hip = _midpoint(_posePoint(frame, 23), _posePoint(frame, 24));
  if (shoulder == null || hip == null) return null;
  final vertical = math.max(0.0001, hip.y - shoulder.y);
  final raw = shoulder.x - hip.x;
  final forward = switch (direction) {
    RunningDirection.leftToRight => raw,
    RunningDirection.rightToLeft => -raw,
    RunningDirection.stationary => 0.0,
  };
  // Preserve the sign: positive is leaning into the resolved travel
  // direction, while negative is leaning backward. Clamping or taking abs()
  // would make a backward lean look like the ideal forward posture.
  return math.atan2(forward, vertical) * 180 / math.pi;
}

double? _averageElbowAngle(RunningPoseFrame frame) {
  final values = <double>[];
  final left = _jointAngle(
    _posePoint(frame, 11),
    _posePoint(frame, 13),
    _posePoint(frame, 15),
  );
  final right = _jointAngle(
    _posePoint(frame, 12),
    _posePoint(frame, 14),
    _posePoint(frame, 16),
  );
  if (left != null) values.add(left);
  if (right != null) values.add(right);
  if (values.isEmpty) return null;
  return values.reduce((sum, value) => sum + value) / values.length;
}

double? _jointAngle(
  _RunningPosePoint? first,
  _RunningPosePoint? vertex,
  _RunningPosePoint? third,
) {
  if (first == null || vertex == null || third == null) return null;
  final firstX = first.x - vertex.x;
  final firstY = first.y - vertex.y;
  final secondX = third.x - vertex.x;
  final secondY = third.y - vertex.y;
  final firstLength = math.sqrt((firstX * firstX) + (firstY * firstY));
  final secondLength = math.sqrt((secondX * secondX) + (secondY * secondY));
  if (firstLength <= 0.0001 || secondLength <= 0.0001) return null;
  final cosine =
      ((firstX * secondX) + (firstY * secondY)) / (firstLength * secondLength);
  return math.acos(cosine.clamp(-1.0, 1.0)) * 180 / math.pi;
}

double _phaseConfidence(
  RunningPoseFrame frame,
  RunningContactSide side,
) {
  final indexes = side == RunningContactSide.left
      ? const <int>[11, 12, 23, 24, 25, 27]
      : const <int>[11, 12, 23, 24, 26, 28];
  final values = indexes
      .map((index) => _posePoint(frame, index)?.confidence)
      .whereType<double>()
      .toList(growable: false);
  if (values.isEmpty) return 0;
  return values.reduce((sum, value) => sum + value) / values.length;
}

List<RunningPoseFrame> _historyPoseFrames(
  List<RunningPoseFrame> frames, {
  required List<Duration> contactTimestamps,
  required List<Duration> evidenceTimestamps,
  required int maxFrames,
}) {
  if (maxFrames <= 0) {
    return const <RunningPoseFrame>[];
  }
  if (frames.length <= maxFrames) {
    return List<RunningPoseFrame>.unmodifiable(frames);
  }

  final selectedIndexes = <int>{0, frames.length - 1};
  void selectClosest(int timestampMs) {
    var closestIndex = 0;
    var closestDistance = (frames.first.timestampMs - timestampMs).abs();
    for (var index = 1; index < frames.length; index += 1) {
      final distance = (frames[index].timestampMs - timestampMs).abs();
      if (distance < closestDistance) {
        closestIndex = index;
        closestDistance = distance;
      }
    }
    if (selectedIndexes.length < maxFrames) {
      selectedIndexes.add(closestIndex);
    }
  }

  // Preserve the frames that were already selected as user-facing evidence.
  for (final timestamp in evidenceTimestamps) {
    if (selectedIndexes.length >= maxFrames) break;
    selectClosest(timestamp.inMilliseconds);
  }

  // Preserve the actual contact frame next. Then retain frames immediately
  // before and after it so archived step-by-step and comparison views do not
  // silently lose their locally observable movement phases.
  for (final timestamp in contactTimestamps) {
    if (selectedIndexes.length >= maxFrames) break;
    selectClosest(timestamp.inMilliseconds);
  }
  for (final timestamp in contactTimestamps) {
    if (selectedIndexes.length >= maxFrames) break;
    selectClosest(timestamp.inMilliseconds - 90);
    if (selectedIndexes.length >= maxFrames) break;
    selectClosest(timestamp.inMilliseconds + 80);
    if (selectedIndexes.length >= maxFrames) break;
    selectClosest(timestamp.inMilliseconds + 180);
  }
  for (var slot = 1;
      selectedIndexes.length < maxFrames && slot < maxFrames - 1;
      slot += 1) {
    selectedIndexes.add(((frames.length - 1) * slot / (maxFrames - 1)).round());
  }
  final selected = selectedIndexes.toList(growable: false)..sort();
  return List<RunningPoseFrame>.unmodifiable(
    selected.take(maxFrames).map((index) => frames[index]),
  );
}

List<RunningPoseFrame> _parsePoseFrames(Object? raw) {
  if (raw is! Iterable<Object?>) {
    return const <RunningPoseFrame>[];
  }
  final framesByTimestamp = <int, RunningPoseFrame>{};
  for (final item in raw) {
    final frame = RunningPoseFrame.fromObject(item);
    if (frame != null) {
      framesByTimestamp[frame.timestampMs] = frame;
    }
  }
  final frames = framesByTimestamp.values.toList(growable: false);
  frames.sort((a, b) => a.timestampMs.compareTo(b.timestampMs));
  return List<RunningPoseFrame>.unmodifiable(frames);
}

List<RunningContactWindow> _parseContactWindows(Object? raw) {
  if (raw is! Iterable<Object?>) {
    return const <RunningContactWindow>[];
  }
  final windows = <RunningContactWindow>[];
  for (final item in raw) {
    final window = RunningContactWindow.fromObject(item);
    if (window != null) {
      windows.add(window);
    }
  }
  windows.sort((a, b) => a.centerMs.compareTo(b.centerMs));
  return List<RunningContactWindow>.unmodifiable(windows);
}

({List<Duration> confirmed, List<Duration> demoted})
    _partitionAlternatingValidatedContacts(
  List<Duration> contacts,
  List<RunningContactWindow> windows,
) {
  final confirmed = <Duration>[];
  final demoted = <Duration>[];
  RunningContactSide? lastConfirmedSide;
  for (final contact in contacts.toList(growable: false)..sort()) {
    final side = _contactSideForTimestamp(contact, windows);
    if (side != RunningContactSide.unknown &&
        lastConfirmedSide != null &&
        side == lastConfirmedSide) {
      demoted.add(contact);
      continue;
    }
    confirmed.add(contact);
    if (side != RunningContactSide.unknown) {
      lastConfirmedSide = side;
    }
  }
  return (
    confirmed: List<Duration>.unmodifiable(confirmed),
    demoted: List<Duration>.unmodifiable(demoted),
  );
}

RunningContactSide _contactSideForTimestamp(
  Duration timestamp,
  List<RunningContactWindow> windows,
) {
  RunningContactWindow? nearest;
  var nearestDistanceMs = 181;
  final timestampMs = timestamp.inMilliseconds;
  final explicitWindows = windows.where(
    (window) => window.validatedContactTimestamps.any(
      (item) => item.inMilliseconds == timestampMs,
    ),
  );
  final candidates = explicitWindows.isNotEmpty ? explicitWindows : windows;
  for (final window in candidates) {
    final isInside =
        timestampMs >= window.startMs && timestampMs <= window.endMs;
    final distanceMs = (timestampMs - window.centerMs).abs();
    if (!isInside && distanceMs > 180) continue;
    if (nearest == null || distanceMs < nearestDistanceMs) {
      nearest = window;
      nearestDistanceMs = distanceMs;
    }
  }
  return nearest?.side ?? RunningContactSide.unknown;
}

List<RunningContactWindow> _demoteAlternationEstimatedWindows(
  List<RunningContactWindow> windows,
  List<Duration> demotedContacts,
) {
  if (demotedContacts.isEmpty) return windows;
  final demotedMs =
      demotedContacts.map((timestamp) => timestamp.inMilliseconds).toSet();
  return List<RunningContactWindow>.unmodifiable(
    windows.map((window) {
      final validated = window.validatedContactTimestamps
          .where((timestamp) => !demotedMs.contains(timestamp.inMilliseconds))
          .toList(growable: false);
      final moved = window.validatedContactTimestamps
          .where((timestamp) => demotedMs.contains(timestamp.inMilliseconds))
          .toList(growable: false);
      if (moved.isEmpty) return window;
      final estimated = <Duration>{
        ...window.estimatedContactTimestamps,
        ...moved,
      }.toList(growable: false)
        ..sort();
      return RunningContactWindow(
        start: window.start,
        center: window.center,
        end: window.end,
        side: window.side,
        denseSampleCount: window.denseSampleCount,
        candidateFrameCount: window.candidateFrameCount,
        validatedContactTimestamps:
            List<Duration>.unmodifiable(validated..sort()),
        estimatedContactTimestamps: List<Duration>.unmodifiable(estimated),
        selectionMethod: validated.isEmpty
            ? 'alternation_estimated'
            : window.selectionMethod,
        rejectedFrameCounts: window.rejectedFrameCounts,
        confidence: validated.isEmpty
            ? math.min(window.confidence, 0.62)
            : window.confidence,
      );
    }),
  );
}

List<RunningContactWindow> _demoteLegacyKinematicWindows(
  List<RunningContactWindow> windows,
) {
  return List<RunningContactWindow>.unmodifiable(
    windows.map((window) {
      final estimated = <Duration>{
        ...window.estimatedContactTimestamps,
        ...window.validatedContactTimestamps,
      }.toList(growable: false)
        ..sort();
      return RunningContactWindow(
        start: window.start,
        center: window.center,
        end: window.end,
        side: window.side,
        denseSampleCount: window.denseSampleCount,
        candidateFrameCount: window.candidateFrameCount,
        validatedContactTimestamps: const <Duration>[],
        estimatedContactTimestamps: estimated,
        selectionMethod: 'kinematic',
        rejectedFrameCounts: window.rejectedFrameCounts,
        confidence: window.confidence,
      );
    }),
  );
}

List<Duration> _parseTimestampList(Object? raw) {
  if (raw is! Iterable<Object?>) {
    return const <Duration>[];
  }
  final timestamps = <int>{};
  for (final item in raw) {
    final timestampMs = _finiteInt(item);
    if (timestampMs != null && timestampMs >= 0) {
      timestamps.add(timestampMs);
    }
  }
  final sorted = timestamps.toList(growable: false)..sort();
  return List<Duration>.unmodifiable(
    sorted.map((timestampMs) => Duration(milliseconds: timestampMs)),
  );
}

Map<String, int> _parsePositiveIntMap(Object? raw) {
  if (raw is! Map) return const <String, int>{};
  final values = <String, int>{};
  for (final entry in raw.entries) {
    final key = entry.key?.toString().trim();
    final value = _finiteInt(entry.value);
    if (key == null || key.isEmpty || value == null || value <= 0) continue;
    values[key] = value;
  }
  return Map<String, int>.unmodifiable(values);
}

Map<RunningCoachMetric, RunningMetricQuality> _parseMetricQualities(
  Object? raw,
) {
  final map = _asObjectMap(raw);
  if (map == null) return const <RunningCoachMetric, RunningMetricQuality>{};
  final qualities = <RunningCoachMetric, RunningMetricQuality>{};
  for (final entry in map.entries) {
    final metric = _metricFromToken(entry.key?.toString());
    final quality = RunningMetricQuality.fromObject(entry.value);
    if (metric != null && quality != null) {
      qualities[metric] = quality;
    }
  }
  return Map<RunningCoachMetric, RunningMetricQuality>.unmodifiable(qualities);
}

Map<RunningAnalysisMetric, RunningMetricMeasurement> _parseRunningMeasurements(
  Object? raw,
) {
  if (raw is! Iterable<Object?>) {
    return const <RunningAnalysisMetric, RunningMetricMeasurement>{};
  }
  final parsed = <RunningAnalysisMetric, RunningMetricMeasurement>{};
  for (final item in raw) {
    final measurement = RunningMetricMeasurement.fromObject(item);
    if (measurement != null) {
      parsed[measurement.metric] = measurement;
    }
  }
  return Map<RunningAnalysisMetric, RunningMetricMeasurement>.unmodifiable(
    parsed,
  );
}

Map<RunningAnalysisMetric, RunningMetricMeasurement>
    _demoteLegacyKinematicMeasurements(
  Map<RunningAnalysisMetric, RunningMetricMeasurement> measurements,
) {
  const contactDependentMetrics = <RunningAnalysisMetric>{
    RunningAnalysisMetric.cadence,
    RunningAnalysisMetric.stepTime,
    RunningAnalysisMetric.leftRightTiming,
    RunningAnalysisMetric.footStrike,
    RunningAnalysisMetric.kneeAtContact,
    RunningAnalysisMetric.maximumKneeFlexion,
    RunningAnalysisMetric.recoveryKneeFlexion,
  };
  return Map<RunningAnalysisMetric, RunningMetricMeasurement>.unmodifiable(
    measurements.map((metric, measurement) {
      if (!contactDependentMetrics.contains(metric) ||
          measurement.state != RunningMeasurementState.confirmed) {
        return MapEntry(metric, measurement);
      }
      return MapEntry(
        metric,
        RunningMetricMeasurement(
          metric: metric,
          state: RunningMeasurementState.estimated,
          value: measurement.value,
          expectedRange: measurement.expectedRange,
          confidence: measurement.confidence * 0.65,
          sampleCount: measurement.sampleCount,
          method: measurement.method,
          reason: 'kinematic_contact_estimate',
          evidenceTimestamps: measurement.evidenceTimestamps,
        ),
      );
    }),
  );
}

List<RunningScaleSegment> _parseScaleSegments(Object? raw) {
  if (raw is! Iterable<Object?>) return const <RunningScaleSegment>[];
  final parsed = raw
      .map(RunningScaleSegment.fromObject)
      .whereType<RunningScaleSegment>()
      .toList(growable: false)
    ..sort((left, right) => left.start.compareTo(right.start));
  return List<RunningScaleSegment>.unmodifiable(parsed);
}

Duration? _durationFromMilliseconds(Object? raw) {
  final milliseconds = _finiteInt(raw);
  return milliseconds == null || milliseconds < 0
      ? null
      : Duration(milliseconds: milliseconds);
}

String? _optionalToken(Object? raw) {
  final value = raw?.toString().trim();
  return value == null || value.isEmpty ? null : value;
}

RunningMetricMeasurement _legacyMeasurementFor(
  RunningVideoAnalysisResult result,
  RunningAnalysisMetric metric,
) {
  final rhythm = result.rhythmAnalysis;
  final gait = result.gaitAnalysis;
  final metricQuality = switch (metric) {
    RunningAnalysisMetric.posture =>
      result.qualityFor(RunningCoachMetric.posture),
    RunningAnalysisMetric.bounce =>
      result.qualityFor(RunningCoachMetric.bounce),
    RunningAnalysisMetric.footStrike =>
      result.qualityFor(RunningCoachMetric.footStrike),
    RunningAnalysisMetric.kneeAtContact ||
    RunningAnalysisMetric.maximumKneeFlexion ||
    RunningAnalysisMetric.recoveryKneeFlexion =>
      result.qualityFor(RunningCoachMetric.kneeFlexion),
    RunningAnalysisMetric.elbowAngle ||
    RunningAnalysisMetric.armSwingRange ||
    RunningAnalysisMetric.armAsymmetry =>
      result.qualityFor(RunningCoachMetric.armCarriage),
    _ => null,
  };
  final value = switch (metric) {
    RunningAnalysisMetric.cadence => rhythm?.cadenceSpm ?? gait?.cadenceSpm,
    RunningAnalysisMetric.stepTime =>
      rhythm?.medianStepTimeMs ?? gait?.medianStepTimeMs,
    RunningAnalysisMetric.leftRightTiming =>
      rhythm?.leftRightStepTimeAsymmetryPercent ??
          gait?.leftRightStepTimeAsymmetryPercent,
    RunningAnalysisMetric.posture => result.forwardLeanDegrees,
    RunningAnalysisMetric.bounce => result.verticalBounceRatio * 100,
    RunningAnalysisMetric.footStrike =>
      gait?.footStrikeDistance?.median ?? result.footStrikeDistanceRatio,
    RunningAnalysisMetric.kneeAtContact =>
      gait?.kneeAtContact?.median ?? result.stanceKneeAngleDegrees,
    RunningAnalysisMetric.maximumKneeFlexion =>
      gait?.minimumKneeFlexion?.median,
    RunningAnalysisMetric.recoveryKneeFlexion =>
      gait?.recoveryKneeFlexion?.median,
    RunningAnalysisMetric.elbowAngle =>
      gait?.elbowAtContact?.median ?? result.elbowAngleDegrees,
    RunningAnalysisMetric.armSwingRange ||
    RunningAnalysisMetric.armAsymmetry ||
    RunningAnalysisMetric.footRolling =>
      null,
  };
  final confidence = metricQuality?.confidence ??
      (metric == RunningAnalysisMetric.cadence ||
              metric == RunningAnalysisMetric.stepTime ||
              metric == RunningAnalysisMetric.leftRightTiming
          ? result.contactConfidence
          : result.analysisConfidence);
  final sampleCount = metricQuality?.sampleCount ??
      rhythm?.contacts.length ??
      gait?.steps.length ??
      0;
  final isBlocked = metricQuality?.hasBlockingMeasurementReason == true;
  if (value == null || !value.isFinite || confidence <= 0 || isBlocked) {
    return RunningMetricMeasurement.unavailable(
      metric: metric,
      method: 'legacy_unavailable',
      reason: metricQuality?.reason ?? 'coordinates_unavailable',
    );
  }
  final confirmed = metricQuality?.isReliableForCoaching == true;
  final timestamps = result.validatedContactFrameTimestamps.isNotEmpty
      ? result.validatedContactFrameTimestamps.take(4).toList(growable: false)
      : result.poseFrames
          .take(4)
          .map((frame) => frame.timestamp)
          .toList(growable: false);
  return RunningMetricMeasurement(
    metric: metric,
    state: confirmed
        ? RunningMeasurementState.confirmed
        : RunningMeasurementState.estimated,
    value: value,
    expectedRange: null,
    confidence: confidence.clamp(0.0, 1.0).toDouble(),
    sampleCount: sampleCount,
    method: confirmed ? 'legacy_verified' : 'legacy_estimate',
    reason: metricQuality?.reason,
    evidenceTimestamps: timestamps,
  );
}

RunningCoachMetric? _metricFromToken(String? token) {
  if (token == null) return null;
  for (final metric in RunningCoachMetric.values) {
    if (metric.name == token) return metric;
  }
  return null;
}

RunningContactSide _contactSideFromToken(String? token) {
  return switch (token) {
    'left' => RunningContactSide.left,
    'right' => RunningContactSide.right,
    _ => RunningContactSide.unknown,
  };
}

RunningVideoQualityIssue? _qualityIssueFromToken(String? token) {
  return switch (token) {
    'tooSmall' || 'too_small_runner' => RunningVideoQualityIssue.tooSmall,
    'notSideOn' || 'not_side_on' => RunningVideoQualityIssue.notSideOn,
    'bodyCutOff' || 'body_cut_off' => RunningVideoQualityIssue.bodyCutOff,
    'scaleDrift' || 'scale_drift' => RunningVideoQualityIssue.scaleDrift,
    'multiplePerson' ||
    'multiple_person' =>
      RunningVideoQualityIssue.multiplePerson,
    'targetIdentityUnstable' ||
    'target_identity_unstable' =>
      RunningVideoQualityIssue.targetIdentityUnstable,
    _ => null,
  };
}

bool _hasExtremePoseIdentityDiscontinuity(List<RunningPoseFrame> frames) {
  if (frames.length < 2) return false;
  final ordered = frames.toList(growable: false)
    ..sort((left, right) => left.timestamp.compareTo(right.timestamp));
  _PoseIdentitySignature? previous;
  Duration? previousTimestamp;
  for (final frame in ordered) {
    final current = _PoseIdentitySignature.fromFrame(frame);
    if (current == null) continue;
    if (previous != null && previousTimestamp != null) {
      final gapMs =
          frame.timestamp.inMilliseconds - previousTimestamp.inMilliseconds;
      if (gapMs > 0 && gapMs <= 850) {
        final centerJump = math.sqrt(
          math.pow(current.centerX - previous.centerX, 2) +
              math.pow(current.centerY - previous.centerY, 2),
        );
        final scaleRatio = math.max(current.height, previous.height) /
            math.max(0.001, math.min(current.height, previous.height));
        final proportionRatio =
            current.proportion == null || previous.proportion == null
                ? 1.0
                : math.max(current.proportion!, previous.proportion!) /
                    math.max(
                      0.001,
                      math.min(current.proportion!, previous.proportion!),
                    );
        final gapFactor = (gapMs / 850).clamp(0.0, 1.0).toDouble();
        final allowedTranslation = math.max(
          40.0,
          math.max(current.height, previous.height) *
              (0.35 + (0.80 * gapFactor)),
        );
        final implausibleTranslation = centerJump > allowedTranslation;
        if (implausibleTranslation ||
            scaleRatio > 2.6 ||
            proportionRatio > 2.35) {
          return true;
        }
      }
    }
    previous = current;
    previousTimestamp = frame.timestamp;
  }
  return false;
}

class _PoseIdentitySignature {
  final double centerX;
  final double centerY;
  final double height;
  final double? proportion;

  const _PoseIdentitySignature({
    required this.centerX,
    required this.centerY,
    required this.height,
    required this.proportion,
  });

  static _PoseIdentitySignature? fromFrame(RunningPoseFrame frame) {
    final visible = frame.landmarks
        .where((landmark) =>
            landmark.confidence >= _runningMinimumLandmarkConfidence &&
            landmark.x.isFinite &&
            landmark.y.isFinite)
        .toList(growable: false);
    if (visible.length < 8) return null;
    var minX = visible.first.x * frame.imageWidth;
    var maxX = visible.first.x * frame.imageWidth;
    var minY = visible.first.y * frame.imageHeight;
    var maxY = visible.first.y * frame.imageHeight;
    for (final landmark in visible.skip(1)) {
      final x = landmark.x * frame.imageWidth;
      final y = landmark.y * frame.imageHeight;
      minX = math.min(minX, x);
      maxX = math.max(maxX, x);
      minY = math.min(minY, y);
      maxY = math.max(maxY, y);
    }
    final height = maxY - minY;
    if (height <= math.min(frame.imageWidth, frame.imageHeight) * 0.05) {
      return null;
    }
    final shoulder = _identityMidpoint(frame, 11, 12);
    final hip = _identityMidpoint(frame, 23, 24);
    final ankle = _identityMidpoint(frame, 27, 28);
    final torso = shoulder == null || hip == null
        ? null
        : math.sqrt(
            math.pow(shoulder.$1 - hip.$1, 2) +
                math.pow(shoulder.$2 - hip.$2, 2),
          );
    final leg = hip == null || ankle == null
        ? null
        : math.sqrt(
            math.pow(hip.$1 - ankle.$1, 2) + math.pow(hip.$2 - ankle.$2, 2),
          );
    return _PoseIdentitySignature(
      centerX: (minX + maxX) / 2,
      centerY: (minY + maxY) / 2,
      height: height,
      proportion:
          torso == null || leg == null || leg <= 0.01 ? null : torso / leg,
    );
  }
}

(double, double)? _identityMidpoint(
  RunningPoseFrame frame,
  int first,
  int second,
) {
  final a = frame.landmarkByIndex(first);
  final b = frame.landmarkByIndex(second);
  if (a == null ||
      b == null ||
      a.confidence < _runningMinimumLandmarkConfidence ||
      b.confidence < _runningMinimumLandmarkConfidence) {
    return null;
  }
  return (
    ((a.x + b.x) / 2) * frame.imageWidth,
    ((a.y + b.y) / 2) * frame.imageHeight,
  );
}

Map<Object?, Object?>? _asObjectMap(Object? raw) {
  if (raw is Map<Object?, Object?>) return raw;
  if (raw is Map) {
    return raw.map<Object?, Object?>(
      (key, value) => MapEntry<Object?, Object?>(key, value),
    );
  }
  return null;
}

int? _finiteInt(Object? value) {
  if (value is! num || !value.isFinite) return null;
  return value.toInt();
}

double? _finiteDouble(Object? value) {
  if (value is! num || !value.isFinite) return null;
  return value.toDouble();
}

class RunningMetricQuality {
  final double confidence;
  final int sampleCount;
  final String? reason;

  const RunningMetricQuality({
    required this.confidence,
    required this.sampleCount,
    this.reason,
  });

  static const high = RunningMetricQuality(confidence: 1, sampleCount: 0);

  static RunningMetricQuality? fromObject(Object? raw) {
    final map = _asObjectMap(raw);
    if (map == null) return null;
    final confidence = _finiteDouble(map['confidence']);
    final sampleCount = _finiteInt(map['sampleCount']);
    if (confidence == null || sampleCount == null || sampleCount < 0) {
      return null;
    }
    final reason = map['reason']?.toString().trim();
    return RunningMetricQuality(
      confidence: confidence.clamp(0.0, 1.0).toDouble(),
      sampleCount: sampleCount,
      reason: reason == null || reason.isEmpty ? null : reason,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'confidence': confidence,
      'sampleCount': sampleCount,
      if (reason != null) 'reason': reason,
    };
  }

  int get confidencePercent => (confidence.clamp(0.0, 1.0) * 100).round();

  RunningMetricQuality copyWith({
    double? confidence,
    int? sampleCount,
    String? reason,
    bool clearReason = false,
  }) {
    return RunningMetricQuality(
      confidence: confidence ?? this.confidence,
      sampleCount: sampleCount ?? this.sampleCount,
      reason: clearReason ? null : reason ?? this.reason,
    );
  }

  bool get isLowConfidence => confidence < 0.6;

  /// A contact proxy is useful for explaining why a clip was rejected, but it
  /// must never become a posture prescription. The native and web analyzers
  /// deliberately tag those fallback measurements with this reason.
  bool get isContactPhaseProxy => reason == 'contact_phase_proxy';

  /// These codes mean the analyzer either could not pair the claimed value to
  /// a measurable frame or deliberately used a phase proxy. They are stronger
  /// than a low confidence warning: no score, good/bad label, or drill may be
  /// derived from them.
  bool get hasBlockingMeasurementReason => switch (reason) {
        'contact_phase_proxy' ||
        'kinematic_contact_estimate' ||
        'coarse_kinematic_contact_estimate' ||
        'alternation_estimated' ||
        'estimated_contact_maximum_flexion' ||
        'pose_cycle_period_estimate' ||
        'direction_unresolved' ||
        'missing_contact_evidence' ||
        'missing_pose_frames' ||
        'missing_measured_frames' ||
        'metric_unavailable' ||
        'too_small_runner' ||
        'not_side_on' ||
        'body_cut_off' ||
        'scale_drift' =>
          true,
        _ => false,
      };

  /// Old saved reports did not always persist a sample count. Preserve their
  /// compatibility while requiring three fresh measurements for new results.
  bool get hasSufficientSamples =>
      sampleCount == 0 ||
      sampleCount >= runningCoachMinimumReliableMetricSamples;

  bool get isReliableForCoaching =>
      confidence >= runningCoachReliableMetricConfidence &&
      hasSufficientSamples &&
      !hasBlockingMeasurementReason;
}

class RunningCoachingInsight {
  final RunningCoachMetric metric;
  final RunningCoachFinding finding;
  final RunningCoachStatus status;
  final int score;
  final double value;
  final RunningMetricQuality quality;

  const RunningCoachingInsight({
    required this.metric,
    required this.finding,
    required this.status,
    required this.score,
    required this.value,
    this.quality = RunningMetricQuality.high,
  });
}

class RunningCoachingReport {
  final int overallScore;
  final List<RunningCoachingInsight> insights;
  final RunningCoachScoreStatus scoreStatus;
  final int? estimatedScore;

  const RunningCoachingReport({
    required this.overallScore,
    required this.insights,
    this.scoreStatus = RunningCoachScoreStatus.confirmed,
    this.estimatedScore,
  });
}

extension RunningCoachMetricBodyRegion on RunningCoachMetric {
  RunningCoachBodyRegion get bodyRegion {
    return switch (this) {
      RunningCoachMetric.posture ||
      RunningCoachMetric.armCarriage =>
        RunningCoachBodyRegion.upperBody,
      RunningCoachMetric.footStrike ||
      RunningCoachMetric.kneeFlexion =>
        RunningCoachBodyRegion.lowerBody,
      RunningCoachMetric.bounce => RunningCoachBodyRegion.wholeBody,
    };
  }
}

extension RunningCoachingReportInsights on RunningCoachingReport {
  List<RunningCoachingInsight> get rankedInsights {
    final ranked = [...insights]..sort(_compareRunningInsights);
    return List<RunningCoachingInsight>.unmodifiable(ranked);
  }

  List<RunningCoachingInsight> get focusInsights {
    final rankedFocus = rankedInsights
        .where((insight) => insight.status != RunningCoachStatus.good)
        .toList(growable: false);
    return List<RunningCoachingInsight>.unmodifiable(rankedFocus);
  }

  List<RunningCoachingInsight> get strengthInsights {
    final strengths = rankedInsights
        .where((insight) => insight.status == RunningCoachStatus.good)
        .toList(growable: false);
    return List<RunningCoachingInsight>.unmodifiable(strengths);
  }

  RunningCoachingInsight? get primaryFocus {
    final reliable = rankedInsights
        .where((insight) => insight.quality.isReliableForCoaching)
        .toList(growable: false);
    if (reliable.isEmpty) {
      if (scoreStatus != RunningCoachScoreStatus.estimated) return null;
      final estimated = rankedInsights
          .where((insight) =>
              insight.quality.confidence > 0 &&
              insight.quality.reason != 'coordinates_unavailable' &&
              insight.quality.reason != 'metric_unavailable')
          .toList(growable: false);
      if (estimated.isEmpty) return null;
      final estimatedFocus = estimated
          .where((insight) => insight.status != RunningCoachStatus.good)
          .toList(growable: false);
      return estimatedFocus.isNotEmpty ? estimatedFocus.first : estimated.first;
    }
    final reliableFocus = reliable
        .where((insight) => insight.status != RunningCoachStatus.good)
        .toList(growable: false);
    return reliableFocus.isNotEmpty ? reliableFocus.first : reliable.first;
  }

  Map<RunningCoachMetric, int> get focusPriorityByMetric {
    final priorities = <RunningCoachMetric, int>{};
    final reliableFocus = focusInsights
        .where((insight) => insight.quality.isReliableForCoaching)
        .toList(growable: false);
    for (var index = 0; index < reliableFocus.length; index += 1) {
      priorities[reliableFocus[index].metric] = index + 1;
    }
    return Map<RunningCoachMetric, int>.unmodifiable(priorities);
  }
}

int _compareRunningInsights(
  RunningCoachingInsight first,
  RunningCoachingInsight second,
) {
  final severityCompare = _runningStatusSortOrder(
    first.status,
  ).compareTo(_runningStatusSortOrder(second.status));
  if (severityCompare != 0) {
    return severityCompare;
  }

  final scoreCompare = first.score.compareTo(second.score);
  if (scoreCompare != 0) {
    return scoreCompare;
  }

  return first.metric.index.compareTo(second.metric.index);
}

int _runningStatusSortOrder(RunningCoachStatus status) {
  return switch (status) {
    RunningCoachStatus.needsWork => 0,
    RunningCoachStatus.watch => 1,
    RunningCoachStatus.good => 2,
  };
}
