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
    if (result.hasTargetIdentityRisk) {
      return RunningCoachingReport(
        overallScore: 0,
        insights: insights,
        scoreStatus: RunningCoachScoreStatus.unavailable,
      );
    }
    if (result.analysisVersion < runningAnalysisVersionV2 &&
        result.measurements.isEmpty) {
      final reliable = weightedInsights
          .where((entry) => entry.key.quality.isReliableForCoaching)
          .toList(growable: false);
      final complete = reliable.length == weightedInsights.length;
      final weight = reliable.fold<double>(
        0,
        (total, entry) => total + entry.value,
      );
      final coveragePenalty =
          result.validFrameCoverage < thresholds.minimumReliableCoverage
              ? thresholds.lowCoveragePenalty
              : 0;
      final score = !complete || weight == 0
          ? 0
          : math.max(
              0,
              (reliable.fold<double>(
                            0,
                            (total, entry) =>
                                total + (entry.key.score * entry.value),
                          ) /
                          weight)
                      .round() -
                  coveragePenalty,
            );
      return RunningCoachingReport(
        overallScore: score,
        insights: insights,
        scoreStatus: complete
            ? RunningCoachScoreStatus.confirmed
            : RunningCoachScoreStatus.unavailable,
      );
    }
    const analysisMetricForCoachMetric =
        <RunningCoachMetric, RunningAnalysisMetric>{
      RunningCoachMetric.posture: RunningAnalysisMetric.posture,
      RunningCoachMetric.bounce: RunningAnalysisMetric.bounce,
      RunningCoachMetric.footStrike: RunningAnalysisMetric.footStrike,
      RunningCoachMetric.kneeFlexion: RunningAnalysisMetric.kneeAtContact,
      RunningCoachMetric.armCarriage: RunningAnalysisMetric.elbowAngle,
    };
    final confirmedInsights = weightedInsights.where((entry) {
      final metric = analysisMetricForCoachMetric[entry.key.metric]!;
      return result.measurementFor(metric).state ==
              RunningMeasurementState.confirmed &&
          entry.key.quality.isReliableForCoaching;
    }).toList(growable: false);
    final hasReliableConfirmedScore =
        confirmedInsights.length >= thresholds.minimumReliableScoreMetrics;

    int aggregate(List<MapEntry<RunningCoachingInsight, double>> entries) {
      final scoringWeight = entries.fold<double>(
        0,
        (total, entry) => total + entry.value,
      );
      if (scoringWeight == 0) return 0;
      final weightedTotal = entries.fold<double>(
            0,
            (total, entry) => total + (entry.key.score * entry.value),
          ) /
          scoringWeight;
      final coveragePenalty =
          result.validFrameCoverage < thresholds.minimumReliableCoverage
              ? thresholds.lowCoveragePenalty
              : 0;
      return math.max(0, weightedTotal.round() - coveragePenalty);
    }

    final confirmedScore =
        hasReliableConfirmedScore ? aggregate(confirmedInsights) : null;
    final estimatedInsights = confirmedScore == null
        ? weightedInsights.where((entry) {
            final metric = analysisMetricForCoachMetric[entry.key.metric]!;
            return _isEstimatedScoreEligible(
              result,
              entry.key,
              result.measurementFor(metric),
            );
          }).toList(growable: false)
        : const <MapEntry<RunningCoachingInsight, double>>[];
    final estimatedScore =
        estimatedInsights.length >= thresholds.minimumReliableScoreMetrics
            ? _aggregateEstimated(result, estimatedInsights)
            : null;
    final scoreStatus = confirmedScore != null
        ? RunningCoachScoreStatus.confirmed
        : estimatedScore != null
            ? RunningCoachScoreStatus.estimated
            : RunningCoachScoreStatus.unavailable;
    return RunningCoachingReport(
      overallScore: confirmedScore ?? 0,
      insights: insights,
      scoreStatus: scoreStatus,
      estimatedScore: estimatedScore,
    );
  }

  int _aggregateEstimated(
    RunningVideoAnalysisResult result,
    List<MapEntry<RunningCoachingInsight, double>> entries,
  ) {
    final scoringWeight = entries.fold<double>(
      0,
      (total, entry) => total + entry.value,
    );
    if (scoringWeight == 0) return 0;
    final weightedScore = entries.fold<double>(
          0,
          (total, entry) => total + (entry.key.score * entry.value),
        ) /
        scoringWeight;
    final weightedConfidence = entries.fold<double>(
          0,
          (total, entry) =>
              total + (entry.key.quality.confidence * entry.value),
        ) /
        scoringWeight;
    final frameCoveragePenalty =
        result.validFrameCoverage < thresholds.minimumReliableCoverage
            ? thresholds.lowCoveragePenalty
            : 0;
    final metricCoveragePenalty =
        (((5 - entries.length).clamp(0, 5) / 5) * 10).round();
    final confidencePenalty =
        ((1 - weightedConfidence.clamp(0.0, 1.0)) * 12).round();
    return math.max(
      0,
      weightedScore.round() -
          frameCoveragePenalty -
          metricCoveragePenalty -
          confidencePenalty,
    );
  }

  bool _isEstimatedScoreEligible(
    RunningVideoAnalysisResult result,
    RunningCoachingInsight insight,
    RunningMetricMeasurement measurement,
  ) {
    if (result.hasTargetIdentityRisk) return false;
    if (measurement.state == RunningMeasurementState.unavailable ||
        measurement.value == null ||
        !measurement.value!.isFinite ||
        measurement.sampleCount <= 0 ||
        measurement.confidence <= 0) {
      return false;
    }
    if (!insight.value.isFinite || insight.quality.confidence <= 0) {
      return false;
    }
    if (_reasonBlocksEstimatedScore(insight.quality.reason) ||
        _reasonBlocksEstimatedScore(measurement.reason) ||
        _reasonBlocksEstimatedScore(measurement.method)) {
      return false;
    }
    return true;
  }

  bool _reasonBlocksEstimatedScore(String? reason) {
    return switch (reason) {
      'coordinates_unavailable' ||
      'metric_unavailable' ||
      'missing_pose_frames' ||
      'missing_measured_frames' ||
      'missing_contact_evidence' ||
      'contact_phase_proxy' ||
      'direction_unresolved' ||
      'multiple_person' ||
      'target_identity_unstable' =>
        true,
      _ => false,
    };
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
    RunningMetricQuality applyPerspectiveGate(RunningMetricQuality quality) {
      final identityReason = result.targetIdentityIssueReason;
      if (identityReason != null) {
        return quality.copyWith(
          confidence: math.min(quality.confidence, 0.35),
          reason: identityReason,
        );
      }
      final reason = result.perspectiveQuality.limitationReasonForMetric(
        metric,
      );
      if (reason == null || quality.hasBlockingMeasurementReason) {
        return quality;
      }
      return quality.copyWith(
        confidence: math.min(quality.confidence, 0.55),
        reason: reason,
      );
    }

    final metricQuality = result.qualityFor(metric);
    if (metricQuality != null) {
      return _qualityWithFrameEvidence(
        result,
        metric,
        applyPerspectiveGate(metricQuality),
      );
    }
    // New analyzer payloads always include every metric quality. If one is
    // missing from a non-empty quality map, the measurement is unavailable;
    // do not invent confidence from overall frame coverage. Completely legacy
    // payloads (with no quality map) keep the previous compatibility path.
    if (result.metricQualities.isNotEmpty) {
      return applyPerspectiveGate(const RunningMetricQuality(
        confidence: 0,
        sampleCount: 0,
        reason: 'metric_unavailable',
      ));
    }
    final confidence = result.analysisConfidence;
    final reason =
        result.validFrameCoverage < thresholds.minimumReliableCoverage
            ? 'low_coverage'
            : result.validFrames < thresholds.minimumReliableFrames
                ? 'limited_samples'
                : null;
    return applyPerspectiveGate(RunningMetricQuality(
      confidence: confidence,
      sampleCount: result.validFrames,
      reason: reason,
    ));
  }

  RunningMetricQuality _qualityWithFrameEvidence(
    RunningVideoAnalysisResult result,
    RunningCoachMetric metric,
    RunningMetricQuality quality,
  ) {
    // Pre-evidence saved reports do not have a frame bundle. Keep their
    // previous compatibility behavior; all newly analyzed payloads include a
    // non-empty quality map and must be backed by a frame before scoring.
    if (result.metricQualities.isEmpty || !quality.isReliableForCoaching) {
      return quality;
    }
    final evidence = result.evidenceForMetric(metric);
    if (evidence?.isReliable == true) return quality;
    return quality.copyWith(
      reason: switch (evidence?.withheldReason) {
        RunningMetricEvidenceWithheldReason.lowConfidence => 'low_confidence',
        RunningMetricEvidenceWithheldReason.limitedSamples => 'limited_samples',
        RunningMetricEvidenceWithheldReason.missingPoseFrames =>
          'missing_pose_frames',
        RunningMetricEvidenceWithheldReason.missingContact =>
          'missing_contact_evidence',
        RunningMetricEvidenceWithheldReason.missingMeasuredFrames ||
        null =>
          'missing_measured_frames',
      },
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
  final int minimumReliableScoreMetrics;

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
    this.minimumReliableScoreMetrics = 3,
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
