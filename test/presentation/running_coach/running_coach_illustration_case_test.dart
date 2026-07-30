import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';
import 'package:football_note/presentation/running_coach/running_coach_illustration_case.dart';

void main() {
  test('each correction finding selects its curated illustration', () {
    final cases = <(RunningCoachMetric, RunningCoachFinding, double, String)>[
      (
        RunningCoachMetric.posture,
        RunningCoachFinding.postureTooUpright,
        2,
        'posture_upright.webp',
      ),
      (
        RunningCoachMetric.posture,
        RunningCoachFinding.postureTooLean,
        24,
        'posture_forward_lean.webp',
      ),
      (
        RunningCoachMetric.bounce,
        RunningCoachFinding.bounceTooHigh,
        0.13,
        'bounce_high.webp',
      ),
      (
        RunningCoachMetric.footStrike,
        RunningCoachFinding.footStrikeOverstride,
        0.30,
        'foot_overstride.webp',
      ),
      (
        RunningCoachMetric.kneeFlexion,
        RunningCoachFinding.kneeTooStraight,
        179,
        'knee_straight.webp',
      ),
      (
        RunningCoachMetric.kneeFlexion,
        RunningCoachFinding.kneeTooCollapsed,
        122,
        'knee_collapsed.webp',
      ),
      (
        RunningCoachMetric.armCarriage,
        RunningCoachFinding.armTooOpen,
        151,
        'arm_open.webp',
      ),
      (
        RunningCoachMetric.armCarriage,
        RunningCoachFinding.armTooTight,
        39,
        'arm_tight.webp',
      ),
    ];

    for (final item in cases) {
      final illustration = resolveRunningCoachIllustrationCase(
        RunningCoachingInsight(
          metric: item.$1,
          finding: item.$2,
          status: RunningCoachStatus.needsWork,
          score: 32,
          value: item.$3,
        ),
      );

      expect(illustration.assetPath, endsWith(item.$4));
      expect(illustration.isMaintainCase, isFalse);
    }
  });

  test('a good result selects the target-only reference', () {
    final illustration = resolveRunningCoachIllustrationCase(
      const RunningCoachingInsight(
        metric: RunningCoachMetric.footStrike,
        finding: RunningCoachFinding.footStrikeUnderBody,
        status: RunningCoachStatus.good,
        score: 96,
        value: 0.08,
      ),
    );

    expect(illustration.isMaintainCase, isTrue);
    expect(
      illustration.targetAssetPath,
      endsWith('foot_overstride_target.webp'),
    );
  });

  test('reference emphasis follows the distance from the safe range', () {
    final mild = resolveRunningCoachIllustrationCase(_postureInsight(5));
    final moderate = resolveRunningCoachIllustrationCase(_postureInsight(3));
    final severe = resolveRunningCoachIllustrationCase(_postureInsight(1));

    expect(mild.severity, RunningCoachIllustrationSeverity.mild);
    expect(moderate.severity, RunningCoachIllustrationSeverity.moderate);
    expect(severe.severity, RunningCoachIllustrationSeverity.severe);
  });
}

RunningCoachingInsight _postureInsight(double value) {
  return RunningCoachingInsight(
    metric: RunningCoachMetric.posture,
    finding: RunningCoachFinding.postureTooUpright,
    status: RunningCoachStatus.needsWork,
    score: 42,
    value: value,
  );
}
