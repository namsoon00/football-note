import 'dart:math' as math;

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

enum RunningMetricEvidenceKind { rhythm, posture, landing, knee, bounce, arms }

enum RunningMetricEvidenceFrameRole {
  rhythmContact,
  representativePosture,
  initialContact,
  maximumKneeFlexion,
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
      rejectedFrameCounts: _parsePositiveIntMap(map['rejectedFrameCounts']),
      confidence:
          (_finiteDouble(map['confidence']) ?? 0).clamp(0.0, 1.0).toDouble(),
    );
  }
}

class RunningVideoAnalysisResult {
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
  final RunningAnalysisSampleSummary denseSamples;
  final List<RunningContactWindow> contactWindows;
  final List<Duration> validatedContactFrameTimestamps;
  final double contactConfidence;

  const RunningVideoAnalysisResult({
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
    this.denseSamples = RunningAnalysisSampleSummary.empty,
    this.contactWindows = const <RunningContactWindow>[],
    this.validatedContactFrameTimestamps = const <Duration>[],
    this.contactConfidence = 0,
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
      denseSamples: denseSamples,
      contactWindows: contactWindows,
      validatedContactFrameTimestamps: validatedContactFrameTimestamps,
      contactConfidence: contactConfidence,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
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
      'denseSamples': denseSamples.toMap(),
      'contactWindows': contactWindows.map((window) => window.toMap()).toList(
            growable: false,
          ),
      'validatedContactFrameTimestampsMs': validatedContactFrameTimestamps
          .map((timestamp) => timestamp.inMilliseconds)
          .toList(growable: false),
      'contactConfidence': contactConfidence,
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
    return RunningVideoAnalysisResult(
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
      metricQualities: _parseMetricQualities(map['metricQualities']),
      poseFrames: poseFrames,
      coarseSamples: RunningAnalysisSampleSummary.fromObject(
        map['coarseSamples'],
        fallback: coarseFallback,
      ),
      denseSamples: RunningAnalysisSampleSummary.fromObject(
        map['denseSamples'],
        fallback: RunningAnalysisSampleSummary.empty,
      ),
      contactWindows: _parseContactWindows(map['contactWindows']),
      validatedContactFrameTimestamps: _parseTimestampList(
        map['validatedContactFrameTimestampsMs'],
      ),
      contactConfidence: (_finiteDouble(map['contactConfidence']) ?? 0)
          .clamp(0.0, 1.0)
          .toDouble(),
    );
  }
}

/// The four locally observable stages used for a single contact window.
/// `contactExit` is deliberately named after the measured window rather than
/// `toeOff`: a side-view phone video cannot make a precise toe-off claim.
enum RunningGaitPhase {
  preContact,
  initialContact,
  maximumKneeFlexion,
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
  final RunningGaitPhaseMeasurement? preContact;
  final RunningGaitPhaseMeasurement initialContact;
  final RunningGaitPhaseMeasurement? maximumKneeFlexion;
  final RunningGaitPhaseMeasurement? contactExit;

  const RunningGaitStep({
    required this.side,
    required this.contactTimestamp,
    required this.confidence,
    required this.preContact,
    required this.initialContact,
    required this.maximumKneeFlexion,
    required this.contactExit,
  });

  bool get isReliable =>
      confidence >= runningCoachReliableMetricConfidence &&
      initialContact.kneeAngleDegrees != null &&
      initialContact.footStrikeDistanceRatio != null;

  double? get footStrikeDistanceRatio => initialContact.footStrikeDistanceRatio;
  double? get kneeAtContactDegrees => initialContact.kneeAngleDegrees;
  double? get minimumKneeAngleDegrees => maximumKneeFlexion?.kneeAngleDegrees;
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

    final preContactFrame = _nearestPoseFrameInRange(
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
    final stepConfidence = window.confidence > 0
        ? math.min(window.confidence, contactMeasurement.confidence)
        : contactMeasurement.confidence;
    steps.add(
      RunningGaitStep(
        side: window.side,
        contactTimestamp: contactMeasurement.timestamp,
        confidence: stepConfidence.clamp(0.0, 1.0).toDouble(),
        preContact: preContactFrame == null
            ? null
            : _gaitPhaseMeasurement(
                frame: preContactFrame,
                phase: RunningGaitPhase.preContact,
                side: window.side,
                direction: result.direction,
              ),
        initialContact: contactMeasurement,
        maximumKneeFlexion: kneeFlexionFrame == null
            ? null
            : _gaitPhaseMeasurement(
                frame: kneeFlexionFrame,
                phase: RunningGaitPhase.maximumKneeFlexion,
                side: window.side,
                direction: result.direction,
              ),
        contactExit: exitFrame == null
            ? null
            : _gaitPhaseMeasurement(
                frame: exitFrame,
                phase: RunningGaitPhase.contactExit,
                side: window.side,
                direction: result.direction,
              ),
      ),
    );
  }

  steps.sort(
    (left, right) => left.contactTimestamp.compareTo(right.contactTimestamp),
  );
  if (steps.isEmpty) return null;

  final reliableSteps = steps.where((step) => step.isReliable).toList(
        growable: false,
      );
  final source =
      reliableSteps.length >= runningCoachMinimumReliableMetricSamples
          ? reliableSteps
          : steps;
  final footStrike = RunningGaitDistribution.fromValues(
    source.map((step) => step.footStrikeDistanceRatio),
  );
  final kneeAtContact = RunningGaitDistribution.fromValues(
    source.map((step) => step.kneeAtContactDegrees),
  );
  final minimumKneeFlexion = RunningGaitDistribution.fromValues(
    source.map((step) => step.minimumKneeAngleDegrees),
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
    steps: List<RunningGaitStep>.unmodifiable(steps),
    footStrikeDistance: footStrike,
    kneeAtContact: kneeAtContact,
    minimumKneeFlexion: minimumKneeFlexion,
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
  if (rhythm == null) return null;
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
    return RunningMetricEvidenceWithheldReason.missingContact;
  }
  return null;
}

RunningMetricQuality _metricEvidenceQualityFor(
  RunningVideoAnalysisResult result,
  RunningCoachMetric metric,
) {
  final quality = result.qualityFor(metric);
  if (quality != null) return quality;
  if (result.metricQualities.isNotEmpty) {
    return const RunningMetricQuality(
      confidence: 0,
      sampleCount: 0,
      reason: 'metric_unavailable',
    );
  }
  final reason = result.validFrameCoverage < 0.6
      ? 'low_coverage'
      : result.validFrames < 7
          ? 'limited_samples'
          : null;
  return RunningMetricQuality(
    confidence: result.analysisConfidence,
    sampleCount: result.validFrames,
    reason: reason,
  );
}

Map<String, double> _measuredValuesForMetric(
  RunningVideoAnalysisResult result,
  RunningCoachMetric metric,
) {
  return switch (metric) {
    RunningCoachMetric.posture => <String, double>{
        'forwardLeanDegrees': result.forwardLeanDegrees,
      },
    RunningCoachMetric.bounce => <String, double>{
        'verticalBouncePercent': result.verticalBounceRatio * 100,
      },
    RunningCoachMetric.footStrike => <String, double>{
        'footStrikeDistanceRatio': result.footStrikeDistanceRatio,
      },
    RunningCoachMetric.kneeFlexion => <String, double>{
        'kneeAngleDegrees': result.stanceKneeAngleDegrees,
      },
    RunningCoachMetric.armCarriage => <String, double>{
        'elbowAngleDegrees': result.elbowAngleDegrees,
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
  if (gait == null) return const <_RunningMetricEvidenceCandidate>[];
  final candidates = <_RunningMetricEvidenceCandidate>[];
  // A real, pose-paired contact remains useful as an explicitly limited
  // observation even before there are enough stable steps for coaching. The
  // per-metric quality gate keeps these frames out of scores and drills.
  for (final step in gait.steps) {
    final measurement = step.initialContact;
    final value = measurement.footStrikeDistanceRatio;
    if (value == null) continue;
    final poseFrame = _nearestPoseFrame(
      result.poseFrames,
      measurement.timestamp.inMilliseconds,
      toleranceMs: 90,
    );
    if (poseFrame == null) continue;
    candidates.add(
      _RunningMetricEvidenceCandidate(
        timestamp: measurement.timestamp,
        role: RunningMetricEvidenceFrameRole.initialContact,
        phase: RunningGaitPhase.initialContact,
        side: step.side,
        poseFrame: poseFrame,
        values: <String, double>{'footStrikeDistanceRatio': value},
        confidence: math.min(step.confidence, measurement.confidence),
      ),
    );
  }
  return _selectClosestEvidenceCandidates(
    candidates,
    target: result.footStrikeDistanceRatio,
    valueKey: 'footStrikeDistanceRatio',
  );
}

List<_RunningMetricEvidenceCandidate> _kneeEvidenceCandidates(
  RunningVideoAnalysisResult result,
) {
  final gait = result.gaitAnalysis;
  if (gait == null) return const <_RunningMetricEvidenceCandidate>[];
  final candidates = <_RunningMetricEvidenceCandidate>[];
  for (final step in gait.steps) {
    final measurement = step.maximumKneeFlexion ?? step.initialContact;
    final value = measurement.kneeAngleDegrees;
    if (value == null) continue;
    final poseFrame = _nearestPoseFrame(
      result.poseFrames,
      measurement.timestamp.inMilliseconds,
      toleranceMs: 90,
    );
    if (poseFrame == null) continue;
    candidates.add(
      _RunningMetricEvidenceCandidate(
        timestamp: measurement.timestamp,
        role: measurement.phase == RunningGaitPhase.maximumKneeFlexion
            ? RunningMetricEvidenceFrameRole.maximumKneeFlexion
            : RunningMetricEvidenceFrameRole.initialContact,
        phase: measurement.phase,
        side: step.side,
        poseFrame: poseFrame,
        values: <String, double>{'kneeAngleDegrees': value},
        confidence: math.min(step.confidence, measurement.confidence),
      ),
    );
  }
  return _selectClosestEvidenceCandidates(
    candidates,
    target: result.stanceKneeAngleDegrees,
    valueKey: 'kneeAngleDegrees',
  );
}

List<_RunningMetricEvidenceCandidate> _bounceEvidenceCandidates(
  RunningVideoAnalysisResult result,
) {
  final hipFrames = <({RunningPoseFrame frame, double hipY, double scale})>[];
  for (final frame in result.poseFrames) {
    final hip = _midpoint(_posePoint(frame, 23), _posePoint(frame, 24));
    final scale = _bodyScale(frame);
    if (hip == null || scale == null) continue;
    hipFrames.add((frame: frame, hipY: hip.y, scale: scale));
  }
  if (hipFrames.length < 2) return const <_RunningMetricEvidenceCandidate>[];

  var high = hipFrames.first;
  var low = hipFrames.first;
  for (final item in hipFrames.skip(1)) {
    if (item.hipY < high.hipY) high = item;
    if (item.hipY > low.hipY) low = item;
  }
  if (high.frame.timestamp == low.frame.timestamp) {
    return const <_RunningMetricEvidenceCandidate>[];
  }
  final scale = RunningGaitDistribution.fromValues(
        hipFrames.map((item) => item.scale),
      )?.median ??
      1.0;
  final trajectoryPercent = ((low.hipY - high.hipY).abs() / scale) * 100;
  final metricPercent = result.verticalBounceRatio * 100;
  final candidates = <_RunningMetricEvidenceCandidate>[
    _RunningMetricEvidenceCandidate(
      timestamp: high.frame.timestamp,
      role: RunningMetricEvidenceFrameRole.trajectoryHigh,
      poseFrame: high.frame,
      values: <String, double>{
        'verticalBouncePercent': metricPercent,
        'trajectoryPercent': trajectoryPercent,
      },
      confidence: _landmarkConfidenceAverage(high.frame, const <int>[23, 24]),
    ),
    _RunningMetricEvidenceCandidate(
      timestamp: low.frame.timestamp,
      role: RunningMetricEvidenceFrameRole.trajectoryLow,
      poseFrame: low.frame,
      values: <String, double>{
        'verticalBouncePercent': metricPercent,
        'trajectoryPercent': trajectoryPercent,
      },
      confidence: _landmarkConfidenceAverage(low.frame, const <int>[23, 24]),
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

_RunningPosePoint? _posePoint(RunningPoseFrame frame, int index) {
  final landmark = frame.landmarkByIndex(index);
  if (landmark == null ||
      !landmark.x.isFinite ||
      !landmark.y.isFinite ||
      landmark.confidence <= 0) {
    return null;
  }
  return _RunningPosePoint(
    landmark.x,
    landmark.y,
    landmark.confidence.clamp(0.0, 1.0).toDouble(),
  );
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
  return value > 0.0001 ? value : null;
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
  if (forward <= 0) return 0;
  return math.atan2(forward.abs(), vertical) * 180 / math.pi;
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
        'missing_contact_evidence' ||
        'missing_pose_frames' ||
        'missing_measured_frames' ||
        'metric_unavailable' =>
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

  const RunningCoachingReport({
    required this.overallScore,
    required this.insights,
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
    if (reliable.isEmpty) return null;
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
