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
        summary: l10n.runningCoachPostureGoodSummary,
        cue: l10n.runningCoachPostureGoodCue,
        drill: l10n.runningCoachPostureGoodDrill,
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
        summary: l10n.runningCoachBounceGoodSummary,
        cue: l10n.runningCoachBounceGoodCue,
        drill: l10n.runningCoachBounceGoodDrill,
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
        summary: l10n.runningCoachFootStrikeGoodSummary,
        cue: l10n.runningCoachFootStrikeGoodCue,
        drill: l10n.runningCoachFootStrikeGoodDrill,
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
        summary: l10n.runningCoachKneeGoodSummary,
        cue: l10n.runningCoachKneeGoodCue,
        drill: l10n.runningCoachKneeGoodDrill,
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
        summary: l10n.runningCoachArmGoodSummary,
        cue: l10n.runningCoachArmGoodCue,
        drill: l10n.runningCoachArmGoodDrill,
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
