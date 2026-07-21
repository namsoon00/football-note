import 'package:flutter/material.dart';

import '../../application/live_sprint_calibration_readiness_service.dart';
import '../../application/live_sprint_field_validation_service.dart';
import '../../application/live_sprint_trend_service.dart';
import '../../domain/entities/running_coach_session.dart';
import '../../domain/entities/sprint_capture_calibration_profile.dart';
import '../../domain/entities/running_video_analysis_result.dart';
import '../../domain/entities/sprint_realtime_coaching_state.dart';
import '../../gen/app_localizations.dart';
import 'running_coach_insight_copy.dart';
import '../widgets/live_sprint_trend_card.dart';
import '../widgets/live_sprint_pose_evidence_card.dart';

class RunningLiveSessionResultScreen extends StatelessWidget {
  final RunningCoachSessionAnalysis session;
  final bool isPersisted;
  final LiveSprintTrendSummary? trendSummary;
  final LiveSprintCalibrationReadinessSummary? calibrationReadinessSummary;

  const RunningLiveSessionResultScreen({
    super.key,
    required this.session,
    this.isPersisted = true,
    this.trendSummary,
    this.calibrationReadinessSummary,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final report = session.liveSprintReport;
    final fieldValidation = report == null
        ? null
        : const LiveSprintFieldValidationService().build(report);
    final calibrationReadiness = report == null
        ? null
        : calibrationReadinessSummary ??
            const LiveSprintCalibrationReadinessService().build(
              <RunningCoachSessionAnalysis>[session],
              currentSessionId: session.id,
            );
    final insights = session.insights;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.runningCoachLiveSessionReportScreenTitle),
      ),
      body: ListView(
        key: const ValueKey('running-live-session-report-list'),
        padding: const EdgeInsets.all(16),
        children: [
          _SessionHeadlineCard(
            session: session,
            report: report,
            isPersisted: isPersisted,
          ),
          if (fieldValidation != null) ...[
            const SizedBox(height: 16),
            _FieldValidationCard(summary: fieldValidation),
          ],
          if (calibrationReadiness != null) ...[
            const SizedBox(height: 16),
            _CalibrationReadinessCard(summary: calibrationReadiness),
          ],
          if (trendSummary?.hasLiveSessions == true) ...[
            const SizedBox(height: 16),
            LiveSprintTrendCard(
              summary: trendSummary!,
              cardKey: const ValueKey('running-live-session-report-trend'),
            ),
          ],
          const SizedBox(height: 16),
          _FocusCard(
            insight: insights.isEmpty ? null : insights.first,
            report: report,
          ),
          if (report != null) ...[
            const SizedBox(height: 16),
            _ReportSectionTitle(
              icon: Icons.accessibility_new_rounded,
              title: l10n.runningCoachLiveSessionReportEvidenceTitle,
            ),
            const SizedBox(height: 8),
            LiveSprintPoseEvidenceCard(report: report),
          ],
          const SizedBox(height: 16),
          _ReportSectionTitle(
            icon: Icons.accessibility_new_rounded,
            title: l10n.runningCoachLiveSessionReportFormTitle,
          ),
          const SizedBox(height: 8),
          _RunningFormCard(insights: insights),
          const SizedBox(height: 16),
          _ReportSectionTitle(
            icon: Icons.directions_run_rounded,
            title: l10n.runningCoachLiveSprintMetricsTitle,
          ),
          const SizedBox(height: 8),
          _SprintMechanicsCard(report: report),
          const SizedBox(height: 16),
          _ReportSectionTitle(
            icon: Icons.verified_outlined,
            title: l10n.runningCoachLiveSessionReportQualityTitle,
          ),
          const SizedBox(height: 8),
          _QualityCard(session: session, report: report),
        ],
      ),
    );
  }
}

class _SessionHeadlineCard extends StatelessWidget {
  final RunningCoachSessionAnalysis session;
  final LiveSprintSessionReport? report;
  final bool isPersisted;

  const _SessionHeadlineCard({
    required this.session,
    required this.report,
    required this.isPersisted,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final liveReport = report;
    final hasScore = session.overallScore > 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.flag_rounded,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasScore)
                    Text(
                      l10n.runningCoachOverallSummary(session.overallScore),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    )
                  else
                    Text(
                      l10n.runningCoachLiveSessionReportScoreUnavailable,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _formatSessionDate(context, session.analyzedAt),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (isPersisted) ...[
                    const SizedBox(height: 6),
                    Text(
                      l10n.runningCoachLiveSessionReportSaved,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                  if (liveReport != null) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _CompactPill(
                          text: l10n.runningCoachSprintQualityScore(
                            (liveReport.analysisConfidence * 100).round(),
                          ),
                        ),
                        _CompactPill(
                          text: l10n.runningCoachSprintDetectedSteps(
                            liveReport.detectedSteps,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldValidationCard extends StatelessWidget {
  final LiveSprintFieldValidationSummary summary;

  const _FieldValidationCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final statusColor = _fieldValidationStatusColor(scheme, summary.status);
    final checks = summary.nextCaptureChecks;
    return Card(
      key: const ValueKey('running-live-session-report-field-validation'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.fact_check_outlined, color: statusColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.runningCoachFieldValidationTitle,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _fieldValidationStatusLabel(l10n, summary.status),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
                _CompactPill(
                  text: l10n.runningCoachFieldValidationQualityValue(
                    summary.qualityScore,
                  ),
                  foreground: statusColor,
                  background: statusColor.withValues(alpha: 0.12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _CompactPill(
                  text: l10n.runningCoachFieldValidationProfileValue(
                    _calibrationProfileLabel(
                      l10n,
                      summary.calibrationProfile,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _fieldValidationStatusBody(l10n, summary.status),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.runningCoachFieldValidationPrivacyNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.25,
                  ),
            ),
            const SizedBox(height: 12),
            if (checks.isEmpty)
              Text(
                l10n.runningCoachFieldValidationAllChecksPassed,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              )
            else ...[
              Text(
                l10n.runningCoachFieldValidationNextChecksTitle,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              for (var index = 0; index < checks.length; index += 1) ...[
                _FieldValidationCheckRow(check: checks[index]),
                if (index != checks.length - 1) const SizedBox(height: 8),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _FieldValidationCheckRow extends StatelessWidget {
  final LiveSprintFieldValidationCheck check;

  const _FieldValidationCheckRow({required this.check});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.radio_button_unchecked_rounded,
          size: 18,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _fieldValidationCheckLabel(l10n, check.kind),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                _fieldValidationCheckValue(l10n, check),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CalibrationReadinessCard extends StatelessWidget {
  final LiveSprintCalibrationReadinessSummary summary;

  const _CalibrationReadinessCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final statusColor = _calibrationReadinessStatusColor(
      scheme,
      summary.status,
    );
    final checks = summary.compactChecks;
    return Card(
      key: const ValueKey(
        'running-live-session-report-calibration-readiness',
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.tune_rounded, color: statusColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.runningCoachCalibrationReadinessTitle,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _calibrationReadinessStatusLabel(
                          l10n,
                          summary.status,
                        ),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _CompactPill(
                  text: l10n.runningCoachFieldValidationProfileValue(
                    _calibrationProfileLabel(
                      l10n,
                      summary.calibrationProfile,
                    ),
                  ),
                ),
                _CompactPill(
                  text: l10n.runningCoachCalibrationReadinessScoreValue(
                    summary.score,
                  ),
                  foreground: statusColor,
                  background: statusColor.withValues(alpha: 0.12),
                ),
                _CompactPill(
                  text: l10n.runningCoachCalibrationReadinessReadySessionsValue(
                    summary.readySessionCount,
                    summary.requiredReadySessionCount,
                  ),
                ),
                _CompactPill(
                  text: l10n
                      .runningCoachCalibrationReadinessSameProfileSessionsValue(
                    summary.sameProfileSessionCount,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _calibrationReadinessStatusBody(l10n, summary.status),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.runningCoachCalibrationReadinessPrivacyNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.25,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.runningCoachCalibrationReadinessChecksTitle,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < checks.length; index += 1) ...[
              _CalibrationReadinessCheckRow(check: checks[index]),
              if (index != checks.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _CalibrationReadinessCheckRow extends StatelessWidget {
  final LiveSprintCalibrationReadinessCheck check;

  const _CalibrationReadinessCheckRow({required this.check});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          check.passed
              ? Icons.check_circle_outline_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 18,
          color: check.passed ? scheme.primary : scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _calibrationReadinessCheckLabel(l10n, check.kind),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                _calibrationReadinessCheckValue(l10n, check),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FocusCard extends StatelessWidget {
  final RunningCoachingInsight? insight;
  final LiveSprintSessionReport? report;

  const _FocusCard({required this.insight, required this.report});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sprintCue = report?.feedbackCode == null
        ? null
        : _sprintFeedbackCue(l10n, report!.feedbackCode!);
    final copy = insight == null
        ? null
        : RunningCoachInsightCopy.fromInsight(insight!, l10n);
    final title = sprintCue == null
        ? copy?.title ?? l10n.runningCoachLiveSessionReportFocusTitle
        : l10n.runningCoachLiveSprintMetricsTitle;
    final body =
        sprintCue ?? copy?.cue ?? l10n.runningCoachLiveSessionReportNoFormData;
    final confidence = sprintCue == null
        ? insight?.quality.confidence ?? 0
        : report!.feedbackConfidence;
    return Card(
      key: const ValueKey('running-live-session-report-focus'),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.runningCoachLiveSessionReportFocusTitle,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
            if (confidence > 0) ...[
              const SizedBox(height: 10),
              _CompactPill(
                text: l10n.runningCoachConfidenceLabel(
                  (confidence * 100).round(),
                ),
                foreground: Theme.of(context).colorScheme.onPrimaryContainer,
                background: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RunningFormCard extends StatelessWidget {
  final List<RunningCoachingInsight> insights;

  const _RunningFormCard({required this.insights});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (insights.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.runningCoachLiveSessionReportNoFormData,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var index = 0; index < insights.length; index += 1) ...[
              _RunningFormMetricRow(insight: insights[index]),
              if (index != insights.length - 1) const Divider(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}

class _RunningFormMetricRow extends StatelessWidget {
  final RunningCoachingInsight insight;

  const _RunningFormMetricRow({required this.insight});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final copy = RunningCoachInsightCopy.fromInsight(insight, l10n);
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(_runningMetricIcon(insight.metric), color: scheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      copy.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  _StatusPill(status: insight.status, label: copy.statusLabel),
                ],
              ),
              const SizedBox(height: 4),
              Text(copy.summary, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _CompactPill(text: copy.value),
                  _CompactPill(
                    text: l10n.runningCoachMetricScore(insight.score),
                  ),
                  _CompactPill(
                    text: l10n.runningCoachConfidenceLabel(
                      (insight.quality.confidence * 100).round(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SprintMechanicsCard extends StatelessWidget {
  final LiveSprintSessionReport? report;

  const _SprintMechanicsCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final metrics = report?.metrics.where((metric) => metric.available).toList(
              growable: false,
            ) ??
        const <LiveSprintMetricSummary>[];
    if (metrics.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.runningCoachLiveSessionReportNoSprintData,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return Card(
      key: const ValueKey('running-live-session-report-mechanics'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var index = 0; index < metrics.length; index += 1) ...[
              _SprintMetricRow(metric: metrics[index]),
              if (index != metrics.length - 1) const Divider(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}

class _SprintMetricRow extends StatelessWidget {
  final LiveSprintMetricSummary metric;

  const _SprintMetricRow({required this.metric});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(_sprintMetricIcon(metric.kind),
            color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _sprintMetricLabel(l10n, metric.kind),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                _sprintMetricValue(l10n, metric),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (metric.confidence > 0 || metric.sampleCount > 0) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (metric.confidence > 0)
                      _CompactPill(
                        text: l10n.runningCoachConfidenceLabel(
                          (metric.confidence * 100).round(),
                        ),
                      ),
                    if (metric.sampleCount > 0)
                      _CompactPill(
                        text: l10n.runningCoachSprintQualityFrameValue(
                          metric.sampleCount,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _QualityCard extends StatelessWidget {
  final RunningCoachSessionAnalysis session;
  final LiveSprintSessionReport? report;

  const _QualityCard({required this.session, required this.report});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final liveReport = report;
    final duration = session.duration;
    final stats = <_ReportStatData>[
      _ReportStatData(
        label: l10n.runningCoachLiveSessionReportDurationLabel,
        value: l10n.runningCoachLiveSessionReportDurationValue(
          duration.inMinutes,
          duration.inSeconds.remainder(60),
        ),
      ),
      _ReportStatData(
        label: l10n.runningCoachLiveSessionReportAnalyzedFramesLabel,
        value: '${liveReport?.runningAnalyzedFrames ?? session.sampledFrames}',
      ),
      _ReportStatData(
        label: l10n.runningCoachSprintQualityTitle,
        value: liveReport == null
            ? l10n.runningCoachSprintMetricPending
            : l10n.runningCoachSprintQualityScore(
                (liveReport.analysisConfidence * 100).round(),
              ),
      ),
      _ReportStatData(
        label: l10n.runningCoachLiveSessionReportGaitEventsLabel,
        value: liveReport == null
            ? l10n.runningCoachSprintMetricPending
            : l10n.runningCoachLiveSessionReportGaitEventsValue(
                liveReport.touchdownEvents,
                liveReport.toeOffEvents,
              ),
      ),
      _ReportStatData(
        label: l10n.runningCoachLiveSessionReportStepEventsLabel,
        value: liveReport == null
            ? l10n.runningCoachSprintMetricPending
            : l10n.runningCoachSprintDetectedSteps(liveReport.detectedSteps),
      ),
      _ReportStatData(
        label: l10n.runningCoachLiveSessionReportCaptureLostLabel,
        value: liveReport == null
            ? l10n.runningCoachSprintMetricPending
            : l10n.runningCoachLiveSessionReportCaptureLostValue(
                (liveReport.bodyNotVisibleRatio * 100).round(),
              ),
      ),
      _ReportStatData(
        label: l10n.runningCoachLiveSessionReportFeedbackChangesLabel,
        value: liveReport == null
            ? l10n.runningCoachSprintMetricPending
            : l10n.runningCoachLiveSessionReportFeedbackChangesValue(
                liveReport.feedbackChanges,
              ),
      ),
    ];
    return Card(
      key: const ValueKey('running-live-session-report-quality'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final stat in stats)
                  SizedBox(width: itemWidth, child: _ReportStat(data: stat)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReportSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _ReportSectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}

class _ReportStatData {
  final String label;
  final String value;

  const _ReportStatData({required this.label, required this.value});
}

class _ReportStat extends StatelessWidget {
  final _ReportStatData data;

  const _ReportStat({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 4),
            Text(
              data.value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactPill extends StatelessWidget {
  final String text;
  final Color? foreground;
  final Color? background;

  const _CompactPill({
    required this.text,
    this.foreground,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background ?? scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final RunningCoachStatus status;
  final String label;

  const _StatusPill({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      RunningCoachStatus.good => Colors.green.shade700,
      RunningCoachStatus.watch => Colors.orange.shade800,
      RunningCoachStatus.needsWork => Colors.red.shade700,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

IconData _runningMetricIcon(RunningCoachMetric metric) {
  return switch (metric) {
    RunningCoachMetric.posture => Icons.accessibility_new_rounded,
    RunningCoachMetric.bounce => Icons.height_rounded,
    RunningCoachMetric.footStrike => Icons.directions_run_rounded,
    RunningCoachMetric.kneeFlexion => Icons.sports_gymnastics_rounded,
    RunningCoachMetric.armCarriage => Icons.sync_alt_rounded,
  };
}

IconData _sprintMetricIcon(LiveSprintMetricKind kind) {
  return switch (kind) {
    LiveSprintMetricKind.trunkAngle => Icons.straighten_rounded,
    LiveSprintMetricKind.kneeDrive => Icons.arrow_upward_rounded,
    LiveSprintMetricKind.cadence => Icons.speed_rounded,
    LiveSprintMetricKind.rhythm => Icons.graphic_eq_rounded,
    LiveSprintMetricKind.armBalance => Icons.compare_arrows_rounded,
    LiveSprintMetricKind.landing => Icons.south_rounded,
    LiveSprintMetricKind.flightRatio => Icons.flight_takeoff_rounded,
    LiveSprintMetricKind.lateForm => Icons.timer_outlined,
  };
}

String _sprintMetricLabel(
  AppLocalizations l10n,
  LiveSprintMetricKind kind,
) {
  return switch (kind) {
    LiveSprintMetricKind.trunkAngle => l10n.runningCoachSprintMetricTrunkLabel,
    LiveSprintMetricKind.kneeDrive =>
      l10n.runningCoachSprintMetricKneeDriveLabel,
    LiveSprintMetricKind.cadence => l10n.runningCoachSprintMetricCadenceLabel,
    LiveSprintMetricKind.rhythm => l10n.runningCoachSprintMetricRhythmLabel,
    LiveSprintMetricKind.armBalance =>
      l10n.runningCoachSprintMetricArmBalanceLabel,
    LiveSprintMetricKind.landing => l10n.runningCoachSprintMetricLandingLabel,
    LiveSprintMetricKind.flightRatio =>
      l10n.runningCoachSprintMetricFlightLabel,
    LiveSprintMetricKind.lateForm => l10n.runningCoachSprintMetricLateFormLabel,
  };
}

String _sprintMetricValue(
  AppLocalizations l10n,
  LiveSprintMetricSummary metric,
) {
  final value = metric.value;
  if (value == null) {
    return l10n.runningCoachSprintMetricPending;
  }
  return switch (metric.kind) {
    LiveSprintMetricKind.trunkAngle =>
      l10n.runningCoachSprintMetricTrunkValue(value.toStringAsFixed(1)),
    LiveSprintMetricKind.kneeDrive =>
      l10n.runningCoachSprintMetricKneeDriveValue(
        (value * 100).round(),
      ),
    LiveSprintMetricKind.cadence => l10n.runningCoachSprintMetricCadenceValue(
        value.round(),
      ),
    LiveSprintMetricKind.rhythm => l10n.runningCoachSprintMetricRhythmValue(
        value.toStringAsFixed(0),
      ),
    LiveSprintMetricKind.armBalance =>
      l10n.runningCoachSprintMetricArmBalanceValue(
        (value * 100).round(),
      ),
    LiveSprintMetricKind.landing => l10n.runningCoachSprintMetricLandingValue(
        (value * 100).round(),
        metric.secondaryValue?.toStringAsFixed(0) ??
            l10n.runningCoachSprintMetricPending,
      ),
    LiveSprintMetricKind.flightRatio =>
      l10n.runningCoachSprintMetricFlightValue(
        (value * 100).round(),
      ),
    LiveSprintMetricKind.lateForm => l10n.runningCoachSprintMetricLateFormValue(
        (value * 100).round(),
      ),
  };
}

String _sprintFeedbackCue(AppLocalizations l10n, SprintFeedbackCode code) {
  return switch (code) {
    SprintFeedbackCode.bodyNotVisible => l10n.runningCoachSprintCueBodyVisible,
    SprintFeedbackCode.leanForwardMore => l10n.runningCoachSprintCueLeanForward,
    SprintFeedbackCode.driveKneeHigher => l10n.runningCoachSprintCueDriveKnee,
    SprintFeedbackCode.keepRhythmSteady => l10n.runningCoachSprintCueKeepRhythm,
    SprintFeedbackCode.balanceArmSwing => l10n.runningCoachSprintCueBalanceArms,
    SprintFeedbackCode.landUnderHips => l10n.runningCoachSprintCueLandUnderHips,
    SprintFeedbackCode.liftOffQuickly =>
      l10n.runningCoachSprintCueLiftOffQuickly,
    SprintFeedbackCode.holdLateForm => l10n.runningCoachSprintCueHoldLateForm,
    SprintFeedbackCode.keepPushing => l10n.runningCoachSprintCueKeepPushing,
  };
}

String _fieldValidationStatusLabel(
  AppLocalizations l10n,
  LiveSprintFieldValidationStatus status,
) {
  return switch (status) {
    LiveSprintFieldValidationStatus.insufficient =>
      l10n.runningCoachFieldValidationStatusInsufficient,
    LiveSprintFieldValidationStatus.needsReview =>
      l10n.runningCoachFieldValidationStatusNeedsReview,
    LiveSprintFieldValidationStatus.readyForCalibration =>
      l10n.runningCoachFieldValidationStatusReady,
  };
}

String _fieldValidationStatusBody(
  AppLocalizations l10n,
  LiveSprintFieldValidationStatus status,
) {
  return switch (status) {
    LiveSprintFieldValidationStatus.insufficient =>
      l10n.runningCoachFieldValidationBodyInsufficient,
    LiveSprintFieldValidationStatus.needsReview =>
      l10n.runningCoachFieldValidationBodyNeedsReview,
    LiveSprintFieldValidationStatus.readyForCalibration =>
      l10n.runningCoachFieldValidationBodyReady,
  };
}

Color _fieldValidationStatusColor(
  ColorScheme scheme,
  LiveSprintFieldValidationStatus status,
) {
  return switch (status) {
    LiveSprintFieldValidationStatus.readyForCalibration => scheme.tertiary,
    LiveSprintFieldValidationStatus.needsReview => scheme.primary,
    LiveSprintFieldValidationStatus.insufficient => scheme.error,
  };
}

String _fieldValidationCheckLabel(
  AppLocalizations l10n,
  LiveSprintFieldValidationCheckKind kind,
) {
  return switch (kind) {
    LiveSprintFieldValidationCheckKind.captureReadiness =>
      l10n.runningCoachFieldValidationCheckCaptureReadiness,
    LiveSprintFieldValidationCheckKind.phaseCoverage =>
      l10n.runningCoachFieldValidationCheckPhaseCoverage,
    LiveSprintFieldValidationCheckKind.trackedFrames =>
      l10n.runningCoachFieldValidationCheckTrackedFrames,
    LiveSprintFieldValidationCheckKind.usablePoseSamples =>
      l10n.runningCoachFieldValidationCheckUsableSamples,
    LiveSprintFieldValidationCheckKind.timingConfidence =>
      l10n.runningCoachFieldValidationCheckTimingConfidence,
    LiveSprintFieldValidationCheckKind.sideViewConfidence =>
      l10n.runningCoachFieldValidationCheckSideViewConfidence,
    LiveSprintFieldValidationCheckKind.trackingConfidence =>
      l10n.runningCoachFieldValidationCheckTrackingConfidence,
    LiveSprintFieldValidationCheckKind.bodyVisibility =>
      l10n.runningCoachFieldValidationCheckBodyVisibility,
    LiveSprintFieldValidationCheckKind.stepEvidence =>
      l10n.runningCoachFieldValidationCheckStepEvidence,
    LiveSprintFieldValidationCheckKind.landingEvidence =>
      l10n.runningCoachFieldValidationCheckLandingEvidence,
  };
}

String _fieldValidationCheckValue(
  AppLocalizations l10n,
  LiveSprintFieldValidationCheck check,
) {
  final observedCount = check.observedCount;
  final requiredCount = check.requiredCount;
  if (observedCount != null && requiredCount != null) {
    return l10n.runningCoachFieldValidationCountValue(
      observedCount,
      requiredCount,
    );
  }

  final current = (check.value * 100).round();
  final target = (check.target * 100).round();
  if (check.lowerIsBetter) {
    return l10n.runningCoachFieldValidationPercentMaxValue(current, target);
  }
  return l10n.runningCoachFieldValidationPercentValue(current, target);
}

String _calibrationReadinessStatusLabel(
  AppLocalizations l10n,
  LiveSprintCalibrationReadinessStatus status,
) {
  return switch (status) {
    LiveSprintCalibrationReadinessStatus.currentCaptureNotReady =>
      l10n.runningCoachCalibrationReadinessStatusCurrentNotReady,
    LiveSprintCalibrationReadinessStatus.needsMoreSameProfileSessions =>
      l10n.runningCoachCalibrationReadinessStatusNeedsMore,
    LiveSprintCalibrationReadinessStatus.needsVariationReview =>
      l10n.runningCoachCalibrationReadinessStatusVariationReview,
    LiveSprintCalibrationReadinessStatus.readyForThresholdCalibration =>
      l10n.runningCoachCalibrationReadinessStatusReady,
  };
}

String _calibrationReadinessStatusBody(
  AppLocalizations l10n,
  LiveSprintCalibrationReadinessStatus status,
) {
  return switch (status) {
    LiveSprintCalibrationReadinessStatus.currentCaptureNotReady =>
      l10n.runningCoachCalibrationReadinessBodyCurrentNotReady,
    LiveSprintCalibrationReadinessStatus.needsMoreSameProfileSessions =>
      l10n.runningCoachCalibrationReadinessBodyNeedsMore,
    LiveSprintCalibrationReadinessStatus.needsVariationReview =>
      l10n.runningCoachCalibrationReadinessBodyVariationReview,
    LiveSprintCalibrationReadinessStatus.readyForThresholdCalibration =>
      l10n.runningCoachCalibrationReadinessBodyReady,
  };
}

Color _calibrationReadinessStatusColor(
  ColorScheme scheme,
  LiveSprintCalibrationReadinessStatus status,
) {
  return switch (status) {
    LiveSprintCalibrationReadinessStatus.readyForThresholdCalibration =>
      scheme.tertiary,
    LiveSprintCalibrationReadinessStatus.needsMoreSameProfileSessions ||
    LiveSprintCalibrationReadinessStatus.needsVariationReview =>
      scheme.primary,
    LiveSprintCalibrationReadinessStatus.currentCaptureNotReady => scheme.error,
  };
}

String _calibrationReadinessCheckLabel(
  AppLocalizations l10n,
  LiveSprintCalibrationReadinessCheckKind kind,
) {
  return switch (kind) {
    LiveSprintCalibrationReadinessCheckKind.currentFieldValidation =>
      l10n.runningCoachCalibrationReadinessCheckCurrentFieldValidation,
    LiveSprintCalibrationReadinessCheckKind.sameProfileReadySessions =>
      l10n.runningCoachCalibrationReadinessCheckSameProfileReadySessions,
    LiveSprintCalibrationReadinessCheckKind.averageFieldQuality =>
      l10n.runningCoachCalibrationReadinessCheckAverageFieldQuality,
    LiveSprintCalibrationReadinessCheckKind.timingConfidenceVariation =>
      l10n.runningCoachCalibrationReadinessCheckTimingVariation,
    LiveSprintCalibrationReadinessCheckKind.sideViewConfidenceVariation =>
      l10n.runningCoachCalibrationReadinessCheckSideViewVariation,
    LiveSprintCalibrationReadinessCheckKind.trackingConfidenceVariation =>
      l10n.runningCoachCalibrationReadinessCheckTrackingVariation,
    LiveSprintCalibrationReadinessCheckKind.trackedFrameRateVariation =>
      l10n.runningCoachCalibrationReadinessCheckTrackedFrameVariation,
    LiveSprintCalibrationReadinessCheckKind.eligiblePoseRateVariation =>
      l10n.runningCoachCalibrationReadinessCheckEligiblePoseVariation,
    LiveSprintCalibrationReadinessCheckKind.landingContactRateVariation =>
      l10n.runningCoachCalibrationReadinessCheckLandingContactVariation,
  };
}

String _calibrationReadinessCheckValue(
  AppLocalizations l10n,
  LiveSprintCalibrationReadinessCheck check,
) {
  final observedCount = check.observedCount;
  final requiredCount = check.requiredCount;
  if (observedCount != null && requiredCount != null) {
    return l10n.runningCoachCalibrationReadinessCheckCountValue(
      observedCount,
      requiredCount,
    );
  }

  final current = (check.value * 100).round();
  final target = (check.target * 100).round();
  if (check.lowerIsBetter) {
    return l10n.runningCoachCalibrationReadinessCheckPercentMaxValue(
      current,
      target,
    );
  }
  return l10n.runningCoachCalibrationReadinessCheckPercentValue(
    current,
    target,
  );
}

String _calibrationProfileLabel(
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

String _formatSessionDate(BuildContext context, DateTime value) {
  final local = value.toLocal();
  final material = MaterialLocalizations.of(context);
  return '${material.formatShortDate(local)} ${TimeOfDay.fromDateTime(local).format(context)}';
}
