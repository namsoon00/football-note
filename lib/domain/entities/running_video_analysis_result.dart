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

class RunningVideoPoseLandmark {
  final int index;
  final double x;
  final double y;
  final double z;
  final double? visibility;
  final double? presence;
  final double confidence;

  const RunningVideoPoseLandmark({
    required this.index,
    required this.x,
    required this.y,
    required this.z,
    required this.visibility,
    required this.presence,
    required this.confidence,
  });

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
    return RunningVideoPoseLandmark(
      index: index,
      x: x,
      y: y,
      z: z,
      visibility: _finiteDouble(map['visibility']),
      presence: _finiteDouble(map['presence']),
      confidence: confidence.clamp(0.0, 1.0).toDouble(),
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
  final List<Duration> validatedContactTimestamps;
  final double confidence;

  const RunningContactWindow({
    required this.start,
    required this.center,
    required this.end,
    required this.side,
    required this.denseSampleCount,
    required this.validatedContactTimestamps,
    required this.confidence,
  });

  int get startMs => start.inMilliseconds;
  int get centerMs => center.inMilliseconds;
  int get endMs => end.inMilliseconds;

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
      validatedContactTimestamps: _parseTimestampList(
        map['validatedContactFrameTimestampsMs'],
      ),
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
      validatedContactFrameTimestamps.isNotEmpty &&
      denseSamples.validFrames > 0;

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

  int get confidencePercent => (confidence.clamp(0.0, 1.0) * 100).round();

  bool get isLowConfidence => confidence < 0.6;
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
    final focus = focusInsights;
    if (focus.isNotEmpty) {
      return focus.first;
    }
    final ranked = rankedInsights;
    return ranked.isEmpty ? null : ranked.first;
  }

  Map<RunningCoachMetric, int> get focusPriorityByMetric {
    final priorities = <RunningCoachMetric, int>{};
    final focus = focusInsights;
    for (var index = 0; index < focus.length; index += 1) {
      priorities[focus[index].metric] = index + 1;
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
