import 'dart:math' as math;

import '../domain/entities/running_video_analysis_result.dart';

class RunningCoachingService {
  const RunningCoachingService();

  RunningCoachingReport buildReport(RunningVideoAnalysisResult result) {
    final insights = <RunningCoachingInsight>[
      _buildPostureInsight(result.forwardLeanDegrees),
      _buildBounceInsight(result.verticalBounceRatio),
      _buildStrideInsight(result.strideReachRatio),
    ];

    final averageScore =
        insights.fold<int>(0, (total, item) => total + item.score) ~/
            insights.length;
    final coveragePenalty = result.validFrameCoverage < 0.55 ? 8 : 0;

    return RunningCoachingReport(
      overallScore: math.max(0, averageScore - coveragePenalty),
      insights: insights,
    );
  }

  RunningCoachingInsight _buildPostureInsight(double leanDegrees) {
    final score = _clampScore(
      leanDegrees < 6
          ? 100 - ((6 - leanDegrees) * 12).round()
          : 100 - ((leanDegrees - 10).abs() * 8).round(),
    );
    if (leanDegrees < 5) {
      return RunningCoachingInsight(
        metric: RunningCoachMetric.posture,
        finding: RunningCoachFinding.postureTooUpright,
        status: _statusForScore(score),
        score: score,
        value: leanDegrees,
      );
    }
    if (leanDegrees > 13) {
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
    final score = _clampScore(100 - ((bouncePercent - 6.5).abs() * 11).round());
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

  RunningCoachingInsight _buildStrideInsight(double strideRatio) {
    final score = _clampScore(100 - ((strideRatio - 0.28).abs() * 220).round());
    if (strideRatio < 0.18) {
      return RunningCoachingInsight(
        metric: RunningCoachMetric.stride,
        finding: RunningCoachFinding.strideTooShort,
        status: _statusForScore(score),
        score: score,
        value: strideRatio,
      );
    }
    if (strideRatio > 0.38) {
      return RunningCoachingInsight(
        metric: RunningCoachMetric.stride,
        finding: RunningCoachFinding.strideOverstride,
        status: _statusForScore(score),
        score: score,
        value: strideRatio,
      );
    }
    return RunningCoachingInsight(
      metric: RunningCoachMetric.stride,
      finding: RunningCoachFinding.strideBalanced,
      status: RunningCoachStatus.good,
      score: score,
      value: strideRatio,
    );
  }

  RunningCoachStatus _statusForScore(int score) {
    if (score >= 85) return RunningCoachStatus.good;
    if (score >= 65) return RunningCoachStatus.watch;
    return RunningCoachStatus.needsWork;
  }

  int _clampScore(int score) => score.clamp(0, 100);
}
