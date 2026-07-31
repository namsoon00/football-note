import 'dart:math' as math;

import '../domain/entities/running_video_analysis_result.dart';

class RunningCoachingService {
  final RunningCoachingThresholds thresholds;
  final RunningCoachingWeights weights;

  const RunningCoachingService({
    this.thresholds = const RunningCoachingThresholds(),
    this.weights = const RunningCoachingWeights(),
  });

  RunningCoachingReport buildReport(RunningVideoAnalysisResult result) {
    final insights = <RunningCoachingInsight>[
      _buildPostureInsight(
        result.forwardLeanDegrees,
        _qualityForResult(result, RunningCoachMetric.posture),
      ),
      _buildBounceInsight(
        result.verticalBounceRatio,
        _qualityForResult(result, RunningCoachMetric.bounce),
      ),
      _buildFootStrikeInsight(
        result.footStrikeDistanceRatio,
        _qualityForResult(result, RunningCoachMetric.footStrike),
      ),
      _buildKneeInsight(
        result.stanceKneeAngleDegrees,
        _qualityForResult(result, RunningCoachMetric.kneeFlexion),
      ),
      _buildArmInsight(
        result.elbowAngleDegrees,
        _qualityForResult(result, RunningCoachMetric.armCarriage),
      ),
    ];

    final weightedInsights = <MapEntry<RunningCoachingInsight, double>>[
      MapEntry(insights[0], weights.postureWeight),
      MapEntry(insights[1], weights.bounceWeight),
      MapEntry(insights[2], weights.footStrikeWeight),
      MapEntry(insights[3], weights.kneeWeight),
      MapEntry(insights[4], weights.armWeight),
    ];
    final reliableWeightedInsights = weightedInsights
        .where((entry) => entry.key.quality.isReliableForCoaching)
        .toList(growable: false);
    // Never turn a low-quality estimate into a numerical form score. A zero
    // here is intentionally paired with the retake-quality surface in the UI;
    // it is not a claim that the runner performed poorly.
    final scoringInsights = reliableWeightedInsights;
    final scoringWeight = scoringInsights.fold<double>(
      0,
      (total, entry) => total + entry.value,
    );
    final weightedTotal = scoringWeight == 0
        ? 0.0
        : scoringInsights.fold<double>(
              0,
              (total, entry) => total + (entry.key.score * entry.value),
            ) /
            scoringWeight;
    final coveragePenalty =
        result.validFrameCoverage < thresholds.minimumReliableCoverage
            ? thresholds.lowCoveragePenalty
            : 0;

    return RunningCoachingReport(
      overallScore: scoringInsights.isEmpty
          ? 0
          : math.max(0, weightedTotal.round() - coveragePenalty),
      insights: insights,
    );
  }

  RunningCoachingInsight _buildPostureInsight(
    double leanDegrees,
    RunningMetricQuality quality,
  ) {
    final score = _clampScore(
      100 -
          ((leanDegrees - thresholds.idealForwardLeanDegrees).abs() *
                  thresholds.forwardLeanScorePenaltyPerDegree)
              .round(),
    );
    if (leanDegrees < thresholds.minimumForwardLeanDegrees) {
      return RunningCoachingInsight(
        metric: RunningCoachMetric.posture,
        finding: RunningCoachFinding.postureTooUpright,
        status: _statusForScore(score),
        score: score,
        value: leanDegrees,
        quality: quality,
      );
    }
    if (leanDegrees > thresholds.maximumForwardLeanDegrees) {
      return RunningCoachingInsight(
        metric: RunningCoachMetric.posture,
        finding: RunningCoachFinding.postureTooLean,
        status: _statusForScore(score),
        score: score,
        value: leanDegrees,
        quality: quality,
      );
    }
    return RunningCoachingInsight(
      metric: RunningCoachMetric.posture,
      finding: RunningCoachFinding.postureAligned,
      status: _statusForInRangeScore(score),
      score: score,
      value: leanDegrees,
      quality: quality,
    );
  }

  RunningCoachingInsight _buildBounceInsight(
    double bounceRatio,
    RunningMetricQuality quality,
  ) {
    final bouncePercent = bounceRatio * 100;
    final score = _clampScore(
      100 -
          ((bouncePercent - thresholds.idealVerticalBouncePercent).abs() *
                  thresholds.verticalBounceScorePenaltyPerPercent)
              .round(),
    );
    if (bouncePercent > thresholds.maximumVerticalBouncePercent) {
      return RunningCoachingInsight(
        metric: RunningCoachMetric.bounce,
        finding: RunningCoachFinding.bounceTooHigh,
        status: _statusForScore(score),
        score: score,
        value: bouncePercent,
        quality: quality,
      );
    }
    return RunningCoachingInsight(
      metric: RunningCoachMetric.bounce,
      finding: RunningCoachFinding.bounceEfficient,
      status: _statusForInRangeScore(score),
      score: score,
      value: bouncePercent,
      quality: quality,
    );
  }

  RunningCoachingInsight _buildFootStrikeInsight(
    double strikeRatio,
    RunningMetricQuality quality,
  ) {
    final score = _clampScore(
      strikeRatio <= thresholds.maximumFootStrikeRatio
          ? 100 -
              ((strikeRatio - thresholds.idealFootStrikeRatio).abs() *
                      thresholds.footStrikeScorePenalty)
                  .round()
          : 100 -
              ((strikeRatio - thresholds.idealFootStrikeRatio).abs() *
                      thresholds.overstrideScorePenalty)
                  .round(),
    );
    if (strikeRatio > thresholds.maximumFootStrikeRatio) {
      return RunningCoachingInsight(
        metric: RunningCoachMetric.footStrike,
        finding: RunningCoachFinding.footStrikeOverstride,
        status: _statusForScore(score),
        score: score,
        value: strikeRatio,
        quality: quality,
      );
    }
    return RunningCoachingInsight(
      metric: RunningCoachMetric.footStrike,
      finding: RunningCoachFinding.footStrikeUnderBody,
      status: _statusForInRangeScore(score),
      score: score,
      value: strikeRatio,
      quality: quality,
    );
  }

  RunningCoachingInsight _buildKneeInsight(
    double kneeAngleDegrees,
    RunningMetricQuality quality,
  ) {
    final score = _clampScore(
      100 -
          ((kneeAngleDegrees - thresholds.idealStanceKneeAngleDegrees).abs() *
                  thresholds.kneeScorePenaltyPerDegree)
              .round(),
    );
    if (kneeAngleDegrees > thresholds.maximumStanceKneeAngleDegrees) {
      return RunningCoachingInsight(
        metric: RunningCoachMetric.kneeFlexion,
        finding: RunningCoachFinding.kneeTooStraight,
        status: _statusForScore(score),
        score: score,
        value: kneeAngleDegrees,
        quality: quality,
      );
    }
    if (kneeAngleDegrees < thresholds.minimumStanceKneeAngleDegrees) {
      return RunningCoachingInsight(
        metric: RunningCoachMetric.kneeFlexion,
        finding: RunningCoachFinding.kneeTooCollapsed,
        status: _statusForScore(score),
        score: score,
        value: kneeAngleDegrees,
        quality: quality,
      );
    }
    return RunningCoachingInsight(
      metric: RunningCoachMetric.kneeFlexion,
      finding: RunningCoachFinding.kneeFlexionLoaded,
      status: _statusForInRangeScore(score),
      score: score,
      value: kneeAngleDegrees,
      quality: quality,
    );
  }

  RunningCoachingInsight _buildArmInsight(
    double elbowAngleDegrees,
    RunningMetricQuality quality,
  ) {
    final score = _clampScore(
      100 -
          ((elbowAngleDegrees - thresholds.idealElbowAngleDegrees).abs() *
                  thresholds.elbowScorePenaltyPerDegree)
              .round(),
    );
    if (elbowAngleDegrees > thresholds.maximumElbowAngleDegrees) {
      return RunningCoachingInsight(
        metric: RunningCoachMetric.armCarriage,
        finding: RunningCoachFinding.armTooOpen,
        status: _statusForScore(score),
        score: score,
        value: elbowAngleDegrees,
        quality: quality,
      );
    }
    if (elbowAngleDegrees < thresholds.minimumElbowAngleDegrees) {
      return RunningCoachingInsight(
        metric: RunningCoachMetric.armCarriage,
        finding: RunningCoachFinding.armTooTight,
        status: _statusForScore(score),
        score: score,
        value: elbowAngleDegrees,
        quality: quality,
      );
    }
    return RunningCoachingInsight(
      metric: RunningCoachMetric.armCarriage,
      finding: RunningCoachFinding.armCompact,
      status: _statusForInRangeScore(score),
      score: score,
      value: elbowAngleDegrees,
      quality: quality,
    );
  }

  RunningCoachStatus _statusForScore(int score) {
    if (score >= 85) return RunningCoachStatus.good;
    if (score >= 65) return RunningCoachStatus.watch;
    return RunningCoachStatus.needsWork;
  }

  /// The outer target range is a coaching guardrail, not proof of an ideal
  /// movement. Values inside it but far from the calibrated center are shown
  /// as "watch" rather than being promoted to "good".
  RunningCoachStatus _statusForInRangeScore(int score) {
    return score >= 85 ? RunningCoachStatus.good : RunningCoachStatus.watch;
  }

  RunningMetricQuality _qualityForResult(
    RunningVideoAnalysisResult result,
    RunningCoachMetric metric,
  ) {
    final metricQuality = result.qualityFor(metric);
    if (metricQuality != null) {
      return metricQuality;
    }
    // New analyzer payloads always include every metric quality. If one is
    // missing from a non-empty quality map, the measurement is unavailable;
    // do not invent confidence from overall frame coverage. Completely legacy
    // payloads (with no quality map) keep the previous compatibility path.
    if (result.metricQualities.isNotEmpty) {
      return const RunningMetricQuality(
        confidence: 0,
        sampleCount: 0,
        reason: 'metric_unavailable',
      );
    }
    final confidence = result.analysisConfidence;
    final reason =
        result.validFrameCoverage < thresholds.minimumReliableCoverage
            ? 'low_coverage'
            : result.validFrames < thresholds.minimumReliableFrames
                ? 'limited_samples'
                : null;
    return RunningMetricQuality(
      confidence: confidence,
      sampleCount: result.validFrames,
      reason: reason,
    );
  }

  int _clampScore(int score) => score.clamp(0, 100);
}

class RunningCoachingThresholds {
  final double idealForwardLeanDegrees;
  final double minimumForwardLeanDegrees;
  final double maximumForwardLeanDegrees;
  final double forwardLeanScorePenaltyPerDegree;
  final double idealVerticalBouncePercent;
  final double maximumVerticalBouncePercent;
  final double verticalBounceScorePenaltyPerPercent;
  final double idealFootStrikeRatio;
  final double maximumFootStrikeRatio;
  final double footStrikeScorePenalty;
  final double overstrideScorePenalty;
  final double idealStanceKneeAngleDegrees;
  final double minimumStanceKneeAngleDegrees;
  final double maximumStanceKneeAngleDegrees;
  final double kneeScorePenaltyPerDegree;
  final double idealElbowAngleDegrees;
  final double minimumElbowAngleDegrees;
  final double maximumElbowAngleDegrees;
  final double elbowScorePenaltyPerDegree;
  final double minimumReliableCoverage;
  final int minimumReliableFrames;
  final int lowCoveragePenalty;

  const RunningCoachingThresholds({
    this.idealForwardLeanDegrees = 10,
    this.minimumForwardLeanDegrees = 6,
    this.maximumForwardLeanDegrees = 16,
    this.forwardLeanScorePenaltyPerDegree = 8,
    this.idealVerticalBouncePercent = 6,
    this.maximumVerticalBouncePercent = 8.5,
    this.verticalBounceScorePenaltyPerPercent = 11,
    this.idealFootStrikeRatio = 0.08,
    this.maximumFootStrikeRatio = 0.16,
    this.footStrikeScorePenalty = 220,
    this.overstrideScorePenalty = 320,
    this.idealStanceKneeAngleDegrees = 155,
    this.minimumStanceKneeAngleDegrees = 138,
    this.maximumStanceKneeAngleDegrees = 170,
    this.kneeScorePenaltyPerDegree = 2.2,
    this.idealElbowAngleDegrees = 90,
    this.minimumElbowAngleDegrees = 60,
    this.maximumElbowAngleDegrees = 120,
    this.elbowScorePenaltyPerDegree = 1.3,
    this.minimumReliableCoverage = 0.6,
    this.minimumReliableFrames = 7,
    this.lowCoveragePenalty = 8,
  });
}

class RunningCoachingWeights {
  final double postureWeight;
  final double bounceWeight;
  final double footStrikeWeight;
  final double kneeWeight;
  final double armWeight;

  const RunningCoachingWeights({
    this.postureWeight = 0.24,
    this.bounceWeight = 0.16,
    this.footStrikeWeight = 0.24,
    this.kneeWeight = 0.20,
    this.armWeight = 0.16,
  });
}
