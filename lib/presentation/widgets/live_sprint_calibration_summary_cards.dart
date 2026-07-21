import 'package:flutter/material.dart';

import '../../application/live_sprint_calibration_candidate_service.dart';
import '../../application/live_sprint_field_validation_matrix_service.dart';
import '../../domain/entities/sprint_capture_calibration_profile.dart';
import '../../gen/app_localizations.dart';

class LiveSprintFieldValidationMatrixCard extends StatelessWidget {
  final LiveSprintFieldValidationMatrixSummary summary;
  final bool dark;

  const LiveSprintFieldValidationMatrixCard({
    super.key,
    required this.summary,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final statusColor = dark
        ? _darkStatusColor(summary.status)
        : _matrixStatusColor(scheme, summary.status);
    final content = _CalibrationCardContainer(
      dark: dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CalibrationCardHeader(
            dark: dark,
            icon: Icons.grid_view_rounded,
            iconColor: statusColor,
            title: l10n.runningCoachFieldMatrixTitle,
            status: _matrixStatusLabel(l10n, summary.status),
            statusColor: statusColor,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _CompactPill(
                dark: dark,
                text: l10n.runningCoachFieldMatrixCoverageValue(
                  summary.coveredScenarioCount,
                  summary.requiredScenarioCount,
                ),
              ),
              _CompactPill(
                dark: dark,
                text: l10n.runningCoachFieldMatrixScoreValue(
                  summary.coverageScore,
                ),
                foreground: statusColor,
                background: statusColor.withValues(alpha: dark ? 0.18 : 0.12),
              ),
              _CompactPill(
                dark: dark,
                text: l10n.runningCoachFieldMatrixEligibleSessionsValue(
                  summary.eligibleSessionCount,
                ),
              ),
              if (summary.unknownContextSessionCount > 0)
                _CompactPill(
                  dark: dark,
                  text: l10n.runningCoachFieldMatrixUnknownContextValue(
                    summary.unknownContextSessionCount,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _BodyText(
            dark: dark,
            text: _matrixStatusBody(l10n, summary.status),
          ),
          const SizedBox(height: 6),
          _BodyText(
            dark: dark,
            muted: true,
            text: l10n.runningCoachFieldMatrixPrivacyNote,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.runningCoachFieldMatrixMissingTitle,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: dark ? Colors.white : null,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          if (summary.missingScenarios.isEmpty)
            _BodyText(
              dark: dark,
              muted: true,
              text: l10n.runningCoachFieldMatrixMissingNone,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final scenario in summary.missingScenarios.take(3))
                  _CompactPill(
                    dark: dark,
                    text: _matrixScenarioLabel(l10n, scenario),
                  ),
              ],
            ),
        ],
      ),
    );
    return dark
        ? content
        : Card(
            key: const ValueKey('running-live-session-report-field-matrix'),
            child: content,
          );
  }
}

class LiveSprintCalibrationCandidateCard extends StatelessWidget {
  final LiveSprintCalibrationCandidateSummary summary;
  final bool dark;

  const LiveSprintCalibrationCandidateCard({
    super.key,
    required this.summary,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final statusColor = dark
        ? _darkCandidateStatusColor(summary.status)
        : _candidateStatusColor(scheme, summary.status);
    final recommendedEvaluation = summary.recommendedEvaluation;
    final candidateEvaluation = recommendedEvaluation ??
        (summary.evaluations.isNotEmpty ? summary.evaluations.first : null);
    final content = _CalibrationCardContainer(
      dark: dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CalibrationCardHeader(
            dark: dark,
            icon: Icons.tune_rounded,
            iconColor: statusColor,
            title: l10n.runningCoachCalibrationCandidateTitle,
            status: _candidateStatusLabel(l10n, summary.status),
            statusColor: statusColor,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _CompactPill(
                dark: dark,
                text: l10n.runningCoachCalibrationCandidateScoreValue(
                  summary.score,
                ),
                foreground: statusColor,
                background: statusColor.withValues(alpha: dark ? 0.18 : 0.12),
              ),
              _CompactPill(
                dark: dark,
                text: l10n.runningCoachCalibrationCandidateEligibleValue(
                  summary.eligibleSessionCount,
                ),
              ),
              if (candidateEvaluation != null)
                _CompactPill(
                  dark: dark,
                  text: l10n.runningCoachCalibrationCandidateCoverageValue(
                    candidateEvaluation.passedSessionCount,
                    candidateEvaluation.eligibleSessionCount,
                  ),
                ),
              if (summary.evidenceMargin > 0)
                _CompactPill(
                  dark: dark,
                  text: l10n.runningCoachCalibrationCandidateMarginValue(
                    (summary.evidenceMargin * 100).round(),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _BodyText(
            dark: dark,
            text: _candidateStatusBody(l10n, summary.status),
          ),
          const SizedBox(height: 8),
          _BodyText(
            dark: dark,
            text: summary.hasRecommendation
                ? l10n.runningCoachCalibrationCandidateComparisonValue(
                    _profileLabel(l10n, summary.currentProfile),
                    _profileLabel(l10n, summary.recommendedProfile!),
                  )
                : l10n.runningCoachCalibrationCandidateComparisonKeep(
                    _profileLabel(l10n, summary.currentProfile),
                  ),
          ),
          const SizedBox(height: 6),
          _BodyText(
            dark: dark,
            muted: true,
            text: l10n.runningCoachCalibrationCandidatePrivacyNote,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.runningCoachCalibrationCandidateBlockersTitle,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: dark ? Colors.white : null,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          if (summary.blockers.isEmpty)
            _BodyText(
              dark: dark,
              muted: true,
              text: l10n.runningCoachCalibrationCandidateNoBlockers,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final blocker in summary.blockers.take(3))
                  _CompactPill(
                    dark: dark,
                    text: _candidateBlockerLabel(l10n, blocker),
                  ),
              ],
            ),
        ],
      ),
    );
    return dark
        ? content
        : Card(
            key: const ValueKey(
              'running-live-session-report-calibration-candidate',
            ),
            child: content,
          );
  }
}

class _CalibrationCardContainer extends StatelessWidget {
  final bool dark;
  final Widget child;

  const _CalibrationCardContainer({
    required this.dark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!dark) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }
}

class _CalibrationCardHeader extends StatelessWidget {
  final bool dark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String status;
  final Color statusColor;

  const _CalibrationCardHeader({
    required this.dark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: dark ? Colors.white : null,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                status,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BodyText extends StatelessWidget {
  final bool dark;
  final bool muted;
  final String text;

  const _BodyText({
    required this.dark,
    required this.text,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: dark
                ? muted
                    ? Colors.white60
                    : Colors.white
                : muted
                    ? scheme.onSurfaceVariant
                    : null,
            height: 1.25,
          ),
    );
  }
}

class _CompactPill extends StatelessWidget {
  final bool dark;
  final String text;
  final Color? foreground;
  final Color? background;

  const _CompactPill({
    required this.dark,
    required this.text,
    this.foreground,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background ??
            (dark
                ? Colors.white.withAlpha(18)
                : scheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground ?? (dark ? Colors.white70 : null),
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

Color _matrixStatusColor(
  ColorScheme scheme,
  LiveSprintFieldValidationMatrixStatus status,
) {
  return switch (status) {
    LiveSprintFieldValidationMatrixStatus.matrixComplete ||
    LiveSprintFieldValidationMatrixStatus.recommendationCoverageReady =>
      scheme.tertiary,
    LiveSprintFieldValidationMatrixStatus.buildingCoverage => scheme.primary,
    LiveSprintFieldValidationMatrixStatus.notReady => scheme.error,
  };
}

Color _darkStatusColor(LiveSprintFieldValidationMatrixStatus status) {
  return switch (status) {
    LiveSprintFieldValidationMatrixStatus.matrixComplete ||
    LiveSprintFieldValidationMatrixStatus.recommendationCoverageReady =>
      const Color(0xFFB8F28B),
    LiveSprintFieldValidationMatrixStatus.buildingCoverage =>
      const Color(0xFF9CC8FF),
    LiveSprintFieldValidationMatrixStatus.notReady => const Color(0xFFFFB4AB),
  };
}

Color _candidateStatusColor(
  ColorScheme scheme,
  LiveSprintCalibrationCandidateStatus status,
) {
  return switch (status) {
    LiveSprintCalibrationCandidateStatus.safeRecommendation => scheme.tertiary,
    LiveSprintCalibrationCandidateStatus.keepCurrent => scheme.primary,
    LiveSprintCalibrationCandidateStatus.notReady => scheme.error,
  };
}

Color _darkCandidateStatusColor(LiveSprintCalibrationCandidateStatus status) {
  return switch (status) {
    LiveSprintCalibrationCandidateStatus.safeRecommendation =>
      const Color(0xFFB8F28B),
    LiveSprintCalibrationCandidateStatus.keepCurrent => const Color(0xFF9CC8FF),
    LiveSprintCalibrationCandidateStatus.notReady => const Color(0xFFFFB4AB),
  };
}

String _matrixStatusLabel(
  AppLocalizations l10n,
  LiveSprintFieldValidationMatrixStatus status,
) {
  return switch (status) {
    LiveSprintFieldValidationMatrixStatus.notReady =>
      l10n.runningCoachFieldMatrixStatusNotReady,
    LiveSprintFieldValidationMatrixStatus.buildingCoverage =>
      l10n.runningCoachFieldMatrixStatusBuilding,
    LiveSprintFieldValidationMatrixStatus.recommendationCoverageReady =>
      l10n.runningCoachFieldMatrixStatusRecommendationReady,
    LiveSprintFieldValidationMatrixStatus.matrixComplete =>
      l10n.runningCoachFieldMatrixStatusComplete,
  };
}

String _matrixStatusBody(
  AppLocalizations l10n,
  LiveSprintFieldValidationMatrixStatus status,
) {
  return switch (status) {
    LiveSprintFieldValidationMatrixStatus.notReady =>
      l10n.runningCoachFieldMatrixBodyNotReady,
    LiveSprintFieldValidationMatrixStatus.buildingCoverage =>
      l10n.runningCoachFieldMatrixBodyBuilding,
    LiveSprintFieldValidationMatrixStatus.recommendationCoverageReady =>
      l10n.runningCoachFieldMatrixBodyRecommendationReady,
    LiveSprintFieldValidationMatrixStatus.matrixComplete =>
      l10n.runningCoachFieldMatrixBodyComplete,
  };
}

String _matrixScenarioLabel(
  AppLocalizations l10n,
  LiveSprintFieldValidationMatrixScenario scenario,
) {
  return switch (scenario) {
    LiveSprintFieldValidationMatrixScenario.rearPhoneNormalClearSide =>
      l10n.runningCoachFieldMatrixScenarioRearPhoneNormalClear,
    LiveSprintFieldValidationMatrixScenario.rearPhoneCloseClearSide =>
      l10n.runningCoachFieldMatrixScenarioRearPhoneCloseClear,
    LiveSprintFieldValidationMatrixScenario.rearPhoneFarClearSide =>
      l10n.runningCoachFieldMatrixScenarioRearPhoneFarClear,
    LiveSprintFieldValidationMatrixScenario.rearPhoneNormalPartialSide =>
      l10n.runningCoachFieldMatrixScenarioRearPhoneNormalPartial,
  };
}

String _candidateStatusLabel(
  AppLocalizations l10n,
  LiveSprintCalibrationCandidateStatus status,
) {
  return switch (status) {
    LiveSprintCalibrationCandidateStatus.notReady =>
      l10n.runningCoachCalibrationCandidateStatusNotReady,
    LiveSprintCalibrationCandidateStatus.keepCurrent =>
      l10n.runningCoachCalibrationCandidateStatusKeepCurrent,
    LiveSprintCalibrationCandidateStatus.safeRecommendation =>
      l10n.runningCoachCalibrationCandidateStatusRecommendation,
  };
}

String _candidateStatusBody(
  AppLocalizations l10n,
  LiveSprintCalibrationCandidateStatus status,
) {
  return switch (status) {
    LiveSprintCalibrationCandidateStatus.notReady =>
      l10n.runningCoachCalibrationCandidateBodyNotReady,
    LiveSprintCalibrationCandidateStatus.keepCurrent =>
      l10n.runningCoachCalibrationCandidateBodyKeepCurrent,
    LiveSprintCalibrationCandidateStatus.safeRecommendation =>
      l10n.runningCoachCalibrationCandidateBodyRecommendation,
  };
}

String _candidateBlockerLabel(
  AppLocalizations l10n,
  LiveSprintCalibrationCandidateBlockerKind blocker,
) {
  return switch (blocker) {
    LiveSprintCalibrationCandidateBlockerKind.repeatabilityReadiness =>
      l10n.runningCoachCalibrationCandidateBlockerRepeatability,
    LiveSprintCalibrationCandidateBlockerKind.fieldMatrixCoverage =>
      l10n.runningCoachCalibrationCandidateBlockerFieldMatrix,
    LiveSprintCalibrationCandidateBlockerKind.noMoreStringentProfile =>
      l10n.runningCoachCalibrationCandidateBlockerNoStricter,
    LiveSprintCalibrationCandidateBlockerKind.candidateEvidence =>
      l10n.runningCoachCalibrationCandidateBlockerEvidence,
    LiveSprintCalibrationCandidateBlockerKind.evidenceMargin =>
      l10n.runningCoachCalibrationCandidateBlockerMargin,
    LiveSprintCalibrationCandidateBlockerKind.coverageRegression =>
      l10n.runningCoachCalibrationCandidateBlockerCoverage,
    LiveSprintCalibrationCandidateBlockerKind.holdoutRegression =>
      l10n.runningCoachCalibrationCandidateBlockerHoldout,
  };
}

String _profileLabel(
  AppLocalizations l10n,
  SprintCaptureCalibrationProfile profile,
) {
  return switch (profile) {
    SprintCaptureCalibrationProfile.conservative =>
      l10n.runningCoachSprintCalibrationProfileConservative,
    SprintCaptureCalibrationProfile.balanced =>
      l10n.runningCoachSprintCalibrationProfileBalanced,
    SprintCaptureCalibrationProfile.responsive =>
      l10n.runningCoachSprintCalibrationProfileResponsive,
  };
}
