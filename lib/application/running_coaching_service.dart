import 'dart:math' as math;

import '../domain/entities/running_video_analysis_result.dart';

class RunningCoachingService {
  const RunningCoachingService();

  RunningCoachingReport buildReport(RunningVideoAnalysisResult result) {
    final insights = <RunningCoachingInsight>[
      _buildPostureInsight(result.forwardLeanDegrees),
      _buildBounceInsight(result.verticalBounceRatio),
      _buildFootStrikeInsight(result.footStrikeDistanceRatio),
      _buildKneeInsight(result.stanceKneeAngleDegrees),
      _buildArmInsight(result.elbowAngleDegrees),
    ];

    final weightedTotal = _weightedInsight(insights[0], 0.24) +
        _weightedInsight(insights[1], 0.16) +
        _weightedInsight(insights[2], 0.24) +
        _weightedInsight(insights[3], 0.20) +
        _weightedInsight(insights[4], 0.16);
    final coveragePenalty = result.validFrameCoverage < 0.6 ? 8 : 0;

    return RunningCoachingReport(
      overallScore: math.max(0, weightedTotal.round() - coveragePenalty),
      insights: insights,
    );
  }

  RunningCoachingInsight _buildPostureInsight(double leanDegrees) {
    final score = _clampScore(100 - ((leanDegrees - 10).abs() * 8).round());
    if (leanDegrees < 6) {
      return RunningCoachingInsight(
        metric: RunningCoachMetric.posture,
        finding: RunningCoachFinding.postureTooUpright,
        status: _statusForScore(score),
        score: score,
        value: leanDegrees,
      );
    }
    if (leanDegrees > 16) {
      return RunningCoachingInsight(
        metric: RunningCoachMetric.posture,
        finding: RunningCoachFinding.postureTooLean,
        status: _statusForScore(score),
        score: score,
        value: leanDegrees,
      );
    }
    return RunningCoachingInsight(
      metric: RunningCoachMetric.posture,
      finding: RunningCoachFinding.postureAligned,
      status: RunningCoachStatus.good,
      score: score,
      value: leanDegrees,
    );
  }

  RunningCoachingInsight _buildBounceInsight(double bounceRatio) {
    final bouncePercent = bounceRatio * 100;
    final score = _clampScore(100 - ((bouncePercent - 6.0).abs() * 11).round());
    if (bouncePercent > 8.5) {
      return RunningCoachingInsight(
        metric: RunningCoachMetric.bounce,
        finding: RunningCoachFinding.bounceTooHigh,
        status: _statusForScore(score),
        score: score,
        value: bouncePercent,
      );
    }
    return RunningCoachingInsight(
      metric: RunningCoachMetric.bounce,
      finding: RunningCoachFinding.bounceEfficient,
      status: RunningCoachStatus.good,
      score: score,
      value: bouncePercent,
    );
  }

  RunningCoachingInsight _buildFootStrikeInsight(double strikeRatio) {
    final score = _clampScore(
      strikeRatio <= 0.16
          ? 100 - ((strikeRatio - 0.08).abs() * 220).round()
          : 100 - ((strikeRatio - 0.08).abs() * 320).round(),
    );
    if (strikeRatio > 0.16) {
      return RunningCoachingInsight(
        metric: RunningCoachMetric.footStrike,
        finding: RunningCoachFinding.footStrikeOverstride,
        status: _statusForScore(score),
        score: score,
        value: strikeRatio,
      );
    }
    return RunningCoachingInsight(
      metric: RunningCoachMetric.footStrike,
      finding: RunningCoachFinding.footStrikeUnderBody,
      status: RunningCoachStatus.good,
      score: score,
      value: strikeRatio,
    );
  }

  RunningCoachingInsight _buildKneeInsight(double kneeAngleDegrees) {
    final score = _clampScore(
      100 - ((kneeAngleDegrees - 155).abs() * 2.2).round(),
    );
    if (kneeAngleDegrees > 170) {
      return RunningCoachingInsight(
        metric: RunningCoachMetric.kneeFlexion,
        finding: RunningCoachFinding.kneeTooStraight,
        status: _statusForScore(score),
        score: score,
        value: kneeAngleDegrees,
      );
    }
    if (kneeAngleDegrees < 138) {
      return RunningCoachingInsight(
        metric: RunningCoachMetric.kneeFlexion,
        finding: RunningCoachFinding.kneeTooCollapsed,
        status: _statusForScore(score),
        score: score,
        value: kneeAngleDegrees,
      );
    }
    return RunningCoachingInsight(
      metric: RunningCoachMetric.kneeFlexion,
      finding: RunningCoachFinding.kneeFlexionLoaded,
      status: RunningCoachStatus.good,
      score: score,
      value: kneeAngleDegrees,
    );
  }

  RunningCoachingInsight _buildArmInsight(double elbowAngleDegrees) {
    final score = _clampScore(
      100 - ((elbowAngleDegrees - 90).abs() * 1.3).round(),
    );
    if (elbowAngleDegrees > 120) {
      return RunningCoachingInsight(
        metric: RunningCoachMetric.armCarriage,
        finding: RunningCoachFinding.armTooOpen,
        status: _statusForScore(score),
        score: score,
        value: elbowAngleDegrees,
      );
    }
    if (elbowAngleDegrees < 60) {
      return RunningCoachingInsight(
        metric: RunningCoachMetric.armCarriage,
        finding: RunningCoachFinding.armTooTight,
        status: _statusForScore(score),
        score: score,
        value: elbowAngleDegrees,
      );
    }
    return RunningCoachingInsight(
      metric: RunningCoachMetric.armCarriage,
      finding: RunningCoachFinding.armCompact,
      status: RunningCoachStatus.good,
      score: score,
      value: elbowAngleDegrees,
    );
  }

  RunningCoachStatus _statusForScore(int score) {
    if (score >= 85) return RunningCoachStatus.good;
    if (score >= 65) return RunningCoachStatus.watch;
    return RunningCoachStatus.needsWork;
  }

  double _weightedInsight(RunningCoachingInsight insight, double weight) {
    return insight.score * weight;
  }

  int _clampScore(int score) => score.clamp(0, 100);
}
