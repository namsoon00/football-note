import '../../domain/entities/running_video_analysis_result.dart';
import '../../gen/app_localizations.dart';

class RunningCoachInsightCopy {
  final String title;
  final String summary;
  final String cue;
  final String drill;
  final String statusLabel;
  final String value;

  const RunningCoachInsightCopy({
    required this.title,
    required this.summary,
    required this.cue,
    required this.drill,
    required this.statusLabel,
    required this.value,
  });

  factory RunningCoachInsightCopy.fromInsight(
    RunningCoachingInsight insight,
    AppLocalizations l10n,
  ) {
    // A value can sit inside the outer coaching guardrail while still being
    // far enough from the calibrated center to merit a watch status. Do not
    // reuse the "good" copy for that case: it would turn a caution into a
    // false all-clear.
    final isInRangeWatch = insight.status == RunningCoachStatus.watch;
    final statusLabel = switch (insight.status) {
      RunningCoachStatus.good => l10n.runningCoachStatusGood,
      RunningCoachStatus.watch => l10n.runningCoachStatusWatch,
      RunningCoachStatus.needsWork => l10n.runningCoachStatusNeedsWork,
    };
    final value = switch (insight.metric) {
      RunningCoachMetric.posture => l10n.runningCoachLeanValue(
          insight.value.toStringAsFixed(1),
        ),
      RunningCoachMetric.bounce => l10n.runningCoachBounceValue(
          insight.value.toStringAsFixed(1),
        ),
      RunningCoachMetric.footStrike => l10n.runningCoachFootStrikeValue(
          insight.value.toStringAsFixed(2),
        ),
      RunningCoachMetric.kneeFlexion => l10n.runningCoachKneeValue(
          insight.value.toStringAsFixed(0),
        ),
      RunningCoachMetric.armCarriage => l10n.runningCoachArmValue(
          insight.value.toStringAsFixed(0),
        ),
    };

    return switch (insight.finding) {
      RunningCoachFinding.postureAligned => RunningCoachInsightCopy(
          title: l10n.runningCoachInsightPostureTitle,
          summary: isInRangeWatch
              ? l10n.runningCoachInRangeWatchSummary
              : l10n.runningCoachPostureGoodSummary,
          cue: isInRangeWatch
              ? l10n.runningCoachInRangeWatchCue
              : l10n.runningCoachPostureGoodCue,
          drill: isInRangeWatch
              ? l10n.runningCoachInRangeWatchDrill
              : l10n.runningCoachPostureGoodDrill,
          statusLabel: statusLabel,
          value: value,
        ),
      RunningCoachFinding.postureTooUpright => RunningCoachInsightCopy(
          title: l10n.runningCoachInsightPostureTitle,
          summary: l10n.runningCoachPostureUprightSummary,
          cue: l10n.runningCoachPostureUprightCue,
          drill: l10n.runningCoachPostureUprightDrill,
          statusLabel: statusLabel,
          value: value,
        ),
      RunningCoachFinding.postureTooLean => RunningCoachInsightCopy(
          title: l10n.runningCoachInsightPostureTitle,
          summary: l10n.runningCoachPostureLeanSummary,
          cue: l10n.runningCoachPostureLeanCue,
          drill: l10n.runningCoachPostureLeanDrill,
          statusLabel: statusLabel,
          value: value,
        ),
      RunningCoachFinding.bounceEfficient => RunningCoachInsightCopy(
          title: l10n.runningCoachInsightBounceTitle,
          summary: isInRangeWatch
              ? l10n.runningCoachInRangeWatchSummary
              : l10n.runningCoachBounceGoodSummary,
          cue: isInRangeWatch
              ? l10n.runningCoachInRangeWatchCue
              : l10n.runningCoachBounceGoodCue,
          drill: isInRangeWatch
              ? l10n.runningCoachInRangeWatchDrill
              : l10n.runningCoachBounceGoodDrill,
          statusLabel: statusLabel,
          value: value,
        ),
      RunningCoachFinding.bounceTooHigh => RunningCoachInsightCopy(
          title: l10n.runningCoachInsightBounceTitle,
          summary: l10n.runningCoachBounceHighSummary,
          cue: l10n.runningCoachBounceHighCue,
          drill: l10n.runningCoachBounceHighDrill,
          statusLabel: statusLabel,
          value: value,
        ),
      RunningCoachFinding.footStrikeUnderBody => RunningCoachInsightCopy(
          title: l10n.runningCoachInsightFootStrikeTitle,
          summary: isInRangeWatch
              ? l10n.runningCoachInRangeWatchSummary
              : l10n.runningCoachFootStrikeGoodSummary,
          cue: isInRangeWatch
              ? l10n.runningCoachInRangeWatchCue
              : l10n.runningCoachFootStrikeGoodCue,
          drill: isInRangeWatch
              ? l10n.runningCoachInRangeWatchDrill
              : l10n.runningCoachFootStrikeGoodDrill,
          statusLabel: statusLabel,
          value: value,
        ),
      RunningCoachFinding.footStrikeOverstride => RunningCoachInsightCopy(
          title: l10n.runningCoachInsightFootStrikeTitle,
          summary: l10n.runningCoachFootStrikeOverSummary,
          cue: l10n.runningCoachFootStrikeOverCue,
          drill: l10n.runningCoachFootStrikeOverDrill,
          statusLabel: statusLabel,
          value: value,
        ),
      RunningCoachFinding.kneeFlexionLoaded => RunningCoachInsightCopy(
          title: l10n.runningCoachInsightKneeTitle,
          summary: isInRangeWatch
              ? l10n.runningCoachInRangeWatchSummary
              : l10n.runningCoachKneeGoodSummary,
          cue: isInRangeWatch
              ? l10n.runningCoachInRangeWatchCue
              : l10n.runningCoachKneeGoodCue,
          drill: isInRangeWatch
              ? l10n.runningCoachInRangeWatchDrill
              : l10n.runningCoachKneeGoodDrill,
          statusLabel: statusLabel,
          value: value,
        ),
      RunningCoachFinding.kneeTooStraight => RunningCoachInsightCopy(
          title: l10n.runningCoachInsightKneeTitle,
          summary: l10n.runningCoachKneeStraightSummary,
          cue: l10n.runningCoachKneeStraightCue,
          drill: l10n.runningCoachKneeStraightDrill,
          statusLabel: statusLabel,
          value: value,
        ),
      RunningCoachFinding.kneeTooCollapsed => RunningCoachInsightCopy(
          title: l10n.runningCoachInsightKneeTitle,
          summary: l10n.runningCoachKneeCollapseSummary,
          cue: l10n.runningCoachKneeCollapseCue,
          drill: l10n.runningCoachKneeCollapseDrill,
          statusLabel: statusLabel,
          value: value,
        ),
      RunningCoachFinding.armCompact => RunningCoachInsightCopy(
          title: l10n.runningCoachInsightArmTitle,
          summary: isInRangeWatch
              ? l10n.runningCoachInRangeWatchSummary
              : l10n.runningCoachArmGoodSummary,
          cue: isInRangeWatch
              ? l10n.runningCoachInRangeWatchCue
              : l10n.runningCoachArmGoodCue,
          drill: isInRangeWatch
              ? l10n.runningCoachInRangeWatchDrill
              : l10n.runningCoachArmGoodDrill,
          statusLabel: statusLabel,
          value: value,
        ),
      RunningCoachFinding.armTooOpen => RunningCoachInsightCopy(
          title: l10n.runningCoachInsightArmTitle,
          summary: l10n.runningCoachArmOpenSummary,
          cue: l10n.runningCoachArmOpenCue,
          drill: l10n.runningCoachArmOpenDrill,
          statusLabel: statusLabel,
          value: value,
        ),
      RunningCoachFinding.armTooTight => RunningCoachInsightCopy(
          title: l10n.runningCoachInsightArmTitle,
          summary: l10n.runningCoachArmTightSummary,
          cue: l10n.runningCoachArmTightCue,
          drill: l10n.runningCoachArmTightDrill,
          statusLabel: statusLabel,
          value: value,
        ),
    };
  }
}
