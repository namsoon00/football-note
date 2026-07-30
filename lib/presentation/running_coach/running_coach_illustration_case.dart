import '../../domain/entities/running_video_analysis_result.dart';

/// The strength of the measured deviation used for copy and visual emphasis.
///
/// The app deliberately keeps this separate from [RunningCoachStatus]. Scores
/// use weighted coaching penalties, while an illustration needs a predictable
/// visual scale for one measured metric.
enum RunningCoachIllustrationSeverity { inRange, mild, moderate, severe }

extension RunningCoachIllustrationSeverityPresentation
    on RunningCoachIllustrationSeverity {
  bool get needsPronouncedReference =>
      this == RunningCoachIllustrationSeverity.moderate ||
      this == RunningCoachIllustrationSeverity.severe;
}

/// A pre-rendered coaching reference selected from an analysis finding.
///
/// It is intentionally a generic runner reference. The user’s measured pose
/// remains on the evidence-video surface and is never reconstructed from the
/// supplied image.
class RunningCoachIllustrationCase {
  final RunningCoachFinding finding;
  final RunningCoachIllustrationSeverity severity;
  final String assetPath;
  final String targetAssetPath;

  const RunningCoachIllustrationCase({
    required this.finding,
    required this.severity,
    required this.assetPath,
    required this.targetAssetPath,
  });

  bool get isMaintainCase =>
      severity == RunningCoachIllustrationSeverity.inRange;
}

/// Resolves a measured coaching finding to one of the curated illustration
/// pairs bundled with the app.
///
/// The art has a red current side and a blue target side. A good finding uses
/// only the target side in the presentation layer so the UI does not invent a
/// correction where none exists.
RunningCoachIllustrationCase resolveRunningCoachIllustrationCase(
  RunningCoachingInsight insight,
) {
  final finding = insight.finding;
  return RunningCoachIllustrationCase(
    finding: finding,
    severity: _severityFor(insight),
    assetPath: switch (finding) {
      RunningCoachFinding.postureAligned ||
      RunningCoachFinding.postureTooUpright =>
        _postureUprightAsset,
      RunningCoachFinding.postureTooLean => _postureTooLeanAsset,
      RunningCoachFinding.bounceEfficient ||
      RunningCoachFinding.bounceTooHigh =>
        _bounceHighAsset,
      RunningCoachFinding.footStrikeUnderBody ||
      RunningCoachFinding.footStrikeOverstride =>
        _footOverstrideAsset,
      RunningCoachFinding.kneeFlexionLoaded ||
      RunningCoachFinding.kneeTooStraight =>
        _kneeTooStraightAsset,
      RunningCoachFinding.kneeTooCollapsed => _kneeTooCollapsedAsset,
      RunningCoachFinding.armCompact ||
      RunningCoachFinding.armTooOpen =>
        _armTooOpenAsset,
      RunningCoachFinding.armTooTight => _armTooTightAsset,
    },
    targetAssetPath: switch (finding) {
      RunningCoachFinding.postureAligned ||
      RunningCoachFinding.postureTooUpright ||
      RunningCoachFinding.postureTooLean =>
        _postureUprightTargetAsset,
      RunningCoachFinding.bounceEfficient ||
      RunningCoachFinding.bounceTooHigh =>
        _bounceHighTargetAsset,
      RunningCoachFinding.footStrikeUnderBody ||
      RunningCoachFinding.footStrikeOverstride =>
        _footOverstrideTargetAsset,
      RunningCoachFinding.kneeFlexionLoaded ||
      RunningCoachFinding.kneeTooStraight ||
      RunningCoachFinding.kneeTooCollapsed =>
        _kneeStraightTargetAsset,
      RunningCoachFinding.armCompact ||
      RunningCoachFinding.armTooOpen ||
      RunningCoachFinding.armTooTight =>
        _armOpenTargetAsset,
    },
  );
}

const _postureUprightAsset =
    'assets/images/running_guides/cases/posture_upright.webp';
const _postureTooLeanAsset =
    'assets/images/running_guides/cases/posture_forward_lean.webp';
const _bounceHighAsset = 'assets/images/running_guides/cases/bounce_high.webp';
const _footOverstrideAsset =
    'assets/images/running_guides/cases/foot_overstride.webp';
const _kneeTooStraightAsset =
    'assets/images/running_guides/cases/knee_straight.webp';
const _kneeTooCollapsedAsset =
    'assets/images/running_guides/cases/knee_collapsed.webp';
const _armTooOpenAsset = 'assets/images/running_guides/cases/arm_open.webp';
const _armTooTightAsset = 'assets/images/running_guides/cases/arm_tight.webp';

const _postureUprightTargetAsset =
    'assets/images/running_guides/cases/posture_upright_target.webp';
const _bounceHighTargetAsset =
    'assets/images/running_guides/cases/bounce_high_target.webp';
const _footOverstrideTargetAsset =
    'assets/images/running_guides/cases/foot_overstride_target.webp';
const _kneeStraightTargetAsset =
    'assets/images/running_guides/cases/knee_straight_target.webp';
const _armOpenTargetAsset =
    'assets/images/running_guides/cases/arm_open_target.webp';

RunningCoachIllustrationSeverity _severityFor(
  RunningCoachingInsight insight,
) {
  if (insight.status == RunningCoachStatus.good) {
    return RunningCoachIllustrationSeverity.inRange;
  }

  final value = insight.value;
  return switch (insight.finding) {
    RunningCoachFinding.postureTooUpright => value >= 4
        ? RunningCoachIllustrationSeverity.mild
        : value >= 2
            ? RunningCoachIllustrationSeverity.moderate
            : RunningCoachIllustrationSeverity.severe,
    RunningCoachFinding.postureTooLean => value <= 19
        ? RunningCoachIllustrationSeverity.mild
        : value <= 23
            ? RunningCoachIllustrationSeverity.moderate
            : RunningCoachIllustrationSeverity.severe,
    RunningCoachFinding.bounceTooHigh => value <= 10
        ? RunningCoachIllustrationSeverity.mild
        : value <= 12
            ? RunningCoachIllustrationSeverity.moderate
            : RunningCoachIllustrationSeverity.severe,
    RunningCoachFinding.footStrikeOverstride => value <= 0.20
        ? RunningCoachIllustrationSeverity.mild
        : value <= 0.26
            ? RunningCoachIllustrationSeverity.moderate
            : RunningCoachIllustrationSeverity.severe,
    RunningCoachFinding.kneeTooStraight => value <= 175
        ? RunningCoachIllustrationSeverity.mild
        : value <= 178
            ? RunningCoachIllustrationSeverity.moderate
            : RunningCoachIllustrationSeverity.severe,
    RunningCoachFinding.kneeTooCollapsed => value >= 132
        ? RunningCoachIllustrationSeverity.mild
        : value >= 124
            ? RunningCoachIllustrationSeverity.moderate
            : RunningCoachIllustrationSeverity.severe,
    RunningCoachFinding.armTooOpen => value <= 135
        ? RunningCoachIllustrationSeverity.mild
        : value <= 150
            ? RunningCoachIllustrationSeverity.moderate
            : RunningCoachIllustrationSeverity.severe,
    RunningCoachFinding.armTooTight => value >= 50
        ? RunningCoachIllustrationSeverity.mild
        : value >= 40
            ? RunningCoachIllustrationSeverity.moderate
            : RunningCoachIllustrationSeverity.severe,
    _ => RunningCoachIllustrationSeverity.inRange,
  };
}
