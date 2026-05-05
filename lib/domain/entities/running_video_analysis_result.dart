enum RunningDirection { leftToRight, rightToLeft, stationary }

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

  factory RunningVideoAnalysisResult.fromMap(Map<Object?, Object?> map) {
    final durationMs = (map['durationMs'] as num?)?.toInt() ?? 0;
    final sampledFrames = (map['sampledFrames'] as num?)?.toInt() ?? 0;
    final validFrames = (map['validFrames'] as num?)?.toInt() ?? 0;
    final directionToken = (map['direction'] as String?) ?? 'stationary';
    return RunningVideoAnalysisResult(
      videoDuration: Duration(milliseconds: durationMs),
      sampledFrames: sampledFrames,
      validFrames: validFrames,
      direction: switch (directionToken) {
        'leftToRight' => RunningDirection.leftToRight,
        'rightToLeft' => RunningDirection.rightToLeft,
        _ => RunningDirection.stationary,
      },
      forwardLeanDegrees: (map['forwardLeanDegrees'] as num?)?.toDouble() ?? 0,
      verticalBounceRatio:
          (map['verticalBounceRatio'] as num?)?.toDouble() ?? 0,
      footStrikeDistanceRatio:
          (map['footStrikeDistanceRatio'] as num?)?.toDouble() ?? 0,
      stanceKneeAngleDegrees:
          (map['stanceKneeAngleDegrees'] as num?)?.toDouble() ?? 0,
      elbowAngleDegrees: (map['elbowAngleDegrees'] as num?)?.toDouble() ?? 0,
    );
  }
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
