import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/running_coaching_service.dart';
import '../../application/running_video_analysis_service.dart';
import '../../domain/entities/running_video_analysis_result.dart';
import '../../gen/app_localizations.dart';
import 'running_coach_insight_copy.dart';
import 'running_live_coach_guide_screen.dart';
import 'running_live_coach_screen.dart';
import 'sprint_live_coaching_screen.dart';
import '../widgets/app_feedback.dart';

class RunningCoachScreen extends StatefulWidget {
  const RunningCoachScreen({super.key});

  @override
  State<RunningCoachScreen> createState() => _RunningCoachScreenState();
}

class _RunningCoachScreenState extends State<RunningCoachScreen> {
  final ImagePicker _picker = ImagePicker();
  final RunningVideoAnalysisService _analysisService =
      const RunningVideoAnalysisService();
  final RunningCoachingService _coachingService =
      const RunningCoachingService();

  XFile? _selectedVideo;
  RunningVideoAnalysisResult? _analysisResult;
  RunningCoachingReport? _coachingReport;
  bool _isAnalyzing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final insightSections = _coachingReport == null
        ? const <_InsightRegionSection>[]
        : _buildInsightSections(l10n, _coachingReport!);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.runningCoachScreenTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeroCard(
            title: l10n.runningCoachHeroTitle,
            body: l10n.runningCoachHeroBody,
          ),
          const SizedBox(height: 12),
          _TipsCard(
            title: l10n.runningCoachTipsTitle,
            tips: [
              l10n.runningCoachTipWholeBody,
              l10n.runningCoachTipSideView,
              l10n.runningCoachTipSteadyCamera,
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.runningCoachLiveCardTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.runningCoachLiveCardBody,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _openLiveGuide,
                        icon: const Icon(Icons.info_outline_rounded),
                        label: Text(l10n.runningCoachLiveGuideAction),
                      ),
                      FilledButton.icon(
                        onPressed: _openLiveCoach,
                        icon: const Icon(Icons.videocam_outlined),
                        label: Text(l10n.runningCoachLiveAction),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.runningCoachSprintLiveCardTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.runningCoachSprintLiveCardBody,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _openSprintLiveGuide,
                        icon: const Icon(Icons.info_outline_rounded),
                        label: Text(l10n.runningCoachLiveGuideAction),
                      ),
                      FilledButton.icon(
                        onPressed: _openSprintLiveCoach,
                        icon: const Icon(Icons.flash_on_rounded),
                        label: Text(l10n.runningCoachSprintLiveAction),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.runningCoachSelectedVideoLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedVideo?.name ?? l10n.runningCoachNoVideoSelected,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isAnalyzing ? null : _pickVideo,
                          icon: const Icon(Icons.video_library_outlined),
                          label: Text(l10n.runningCoachPickVideoAction),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _canAnalyze ? _analyzeVideo : null,
                          icon: _isAnalyzing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.play_circle_outline),
                          label: Text(
                            _isAnalyzing
                                ? l10n.runningCoachAnalysisInProgress
                                : l10n.runningCoachAnalyzeAction,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_analysisResult != null && _coachingReport != null) ...[
            const SizedBox(height: 12),
            _ResultsSummaryCard(
              result: _analysisResult!,
              report: _coachingReport!,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.runningCoachResultsTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (
              var sectionIndex = 0;
              sectionIndex < insightSections.length;
              sectionIndex += 1
            ) ...[
              _InsightRegionSectionCard(
                title: insightSections[sectionIndex].title,
                insights: insightSections[sectionIndex].insights,
                priorities: _coachingReport!.focusPriorityByMetric,
              ),
              if (sectionIndex != insightSections.length - 1)
                const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }

  bool get _canAnalyze => !_isAnalyzing && _selectedVideo != null;

  void _openLiveCoach() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RunningLiveCoachScreen()));
  }

  void _openLiveGuide() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RunningLiveCoachGuideScreen(onStart: _openLiveCoach),
      ),
    );
  }

  void _openSprintLiveCoach() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SprintLiveCoachingScreen()));
  }

  void _openSprintLiveGuide() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            RunningLiveCoachGuideScreen(onStart: _openSprintLiveCoach),
      ),
    );
  }

  Future<void> _pickVideo() async {
    try {
      final selected = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 15),
      );
      if (!mounted || selected == null) return;
      setState(() {
        _selectedVideo = selected;
        _analysisResult = null;
        _coachingReport = null;
      });
    } catch (_) {
      if (!mounted) return;
      AppFeedback.showMessage(
        context,
        text: AppLocalizations.of(context)!.runningCoachPickVideoFailed,
      );
    }
  }

  Future<void> _analyzeVideo() async {
    final selected = _selectedVideo;
    if (selected == null || _isAnalyzing) return;
    setState(() => _isAnalyzing = true);
    try {
      final analysis = await _analysisService.analyzeVideo(selected.path);
      final report = _coachingService.buildReport(analysis);
      if (!mounted) return;
      setState(() {
        _analysisResult = analysis;
        _coachingReport = report;
      });
    } on RunningVideoAnalysisException catch (error) {
      if (!mounted) return;
      AppFeedback.showMessage(
        context,
        text: _messageForException(AppLocalizations.of(context)!, error),
      );
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  String _messageForException(
    AppLocalizations l10n,
    RunningVideoAnalysisException error,
  ) {
    return switch (error.code) {
      'unsupported_platform' => l10n.runningCoachUnsupportedPlatform,
      'native_analyzer_unavailable' =>
        l10n.runningCoachNativeAnalyzerUnavailable,
      'missing_file' => l10n.runningCoachVideoFileMissing,
      'video_too_short' => l10n.runningCoachVideoTooShort,
      'no_pose_detected' => l10n.runningCoachNoPoseDetected,
      _ => l10n.runningCoachAnalysisFailedGeneric,
    };
  }

  List<_InsightRegionSection> _buildInsightSections(
    AppLocalizations l10n,
    RunningCoachingReport report,
  ) {
    const order = [
      RunningCoachBodyRegion.upperBody,
      RunningCoachBodyRegion.lowerBody,
      RunningCoachBodyRegion.wholeBody,
    ];
    final rankedInsights = report.rankedInsights;
    return [
      for (final region in order)
        if (rankedInsights
                .where((insight) => insight.metric.bodyRegion == region)
                .toList(growable: false)
            case final insights when insights.isNotEmpty)
          _InsightRegionSection(
            title: _bodyRegionTitle(l10n, region),
            insights: insights,
          ),
    ];
  }

  String _bodyRegionTitle(
    AppLocalizations l10n,
    RunningCoachBodyRegion region,
  ) {
    return switch (region) {
      RunningCoachBodyRegion.upperBody => l10n.runningCoachBodyRegionUpper,
      RunningCoachBodyRegion.lowerBody => l10n.runningCoachBodyRegionLower,
      RunningCoachBodyRegion.wholeBody => l10n.runningCoachBodyRegionWhole,
    };
  }
}

class _InsightRegionSection {
  final String title;
  final List<RunningCoachingInsight> insights;

  const _InsightRegionSection({required this.title, required this.insights});
}

class _HeroCard extends StatelessWidget {
  final String title;
  final String body;

  const _HeroCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.primary.withAlpha(220), scheme.secondaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: scheme.onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  final String title;
  final List<String> tips;

  const _TipsCard({required this.title, required this.tips});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final tip in tips) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_circle_outline, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultsSummaryCard extends StatelessWidget {
  final RunningVideoAnalysisResult result;
  final RunningCoachingReport report;

  const _ResultsSummaryCard({required this.result, required this.report});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final score = report.overallScore;
    final prioritizedInsights = report.rankedInsights;
    final focusPriorities = report.focusPriorityByMetric;
    final focusInsights = report.focusInsights;
    final headline = score >= 85
        ? l10n.runningCoachOverallHeadlineStrong
        : score >= 70
        ? l10n.runningCoachOverallHeadlineSolid
        : l10n.runningCoachOverallHeadlineNeedsWork;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(headline, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              l10n.runningCoachOverallSummary(score),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatChip(
                  label: l10n.runningCoachDurationLabel,
                  value: _formatDuration(result.videoDuration),
                ),
                _StatChip(
                  label: l10n.runningCoachFramesAnalyzedLabel,
                  value: '${result.validFrames}/${result.sampledFrames}',
                ),
                _StatChip(
                  label: l10n.runningCoachCoverageLabel,
                  value:
                      '${(result.validFrameCoverage * 100).clamp(0, 100).toStringAsFixed(0)}%',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.runningCoachMetricScoresTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            for (
              var index = 0;
              index < prioritizedInsights.length;
              index += 1
            ) ...[
              _MetricScoreRow(
                insight: prioritizedInsights[index],
                priority: focusPriorities[prioritizedInsights[index].metric],
              ),
              if (index != prioritizedInsights.length - 1)
                const SizedBox(height: 10),
            ],
            if (focusInsights.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                l10n.runningCoachFocusTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              for (var index = 0; index < focusInsights.length; index += 1) ...[
                _FocusSummaryTile(
                  insight: focusInsights[index],
                  priority: focusPriorities[focusInsights[index].metric]!,
                ),
                if (index != focusInsights.length - 1)
                  const SizedBox(height: 8),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes == 0) return '${seconds}s';
    return '${minutes}m ${seconds}s';
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _InsightRegionSectionCard extends StatelessWidget {
  final String title;
  final List<RunningCoachingInsight> insights;
  final Map<RunningCoachMetric, int> priorities;

  const _InsightRegionSectionCard({
    required this.title,
    required this.insights,
    required this.priorities,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < insights.length; index += 1) ...[
              _InsightCard(
                insight: insights[index],
                priority: priorities[insights[index].metric],
              ),
              if (index != insights.length - 1) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final RunningCoachingInsight insight;
  final int? priority;

  const _InsightCard({required this.insight, this.priority});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final copy = RunningCoachInsightCopy.fromInsight(insight, l10n);
    final badgeColor = switch (insight.status) {
      RunningCoachStatus.good => Colors.green.shade100,
      RunningCoachStatus.watch => Colors.orange.shade100,
      RunningCoachStatus.needsWork => Colors.red.shade100,
    };
    final badgeTextColor = switch (insight.status) {
      RunningCoachStatus.good => Colors.green.shade900,
      RunningCoachStatus.watch => Colors.orange.shade900,
      RunningCoachStatus.needsWork => Colors.red.shade900,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(copy.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (priority != null) _PriorityBadge(priority: priority!),
                _ScoreBadge(score: insight.score),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(
                      copy.statusLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: badgeTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _StatChip(
              label: l10n.runningCoachMetricValueLabel,
              value: copy.value,
            ),
            const SizedBox(height: 12),
            Text(copy.summary, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer.withAlpha(180),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(12),
              child: Text(
                copy.cue,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            Text(copy.drill, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _MetricScoreRow extends StatelessWidget {
  final RunningCoachingInsight insight;
  final int? priority;

  const _MetricScoreRow({required this.insight, this.priority});

  @override
  Widget build(BuildContext context) {
    final copy = RunningCoachInsightCopy.fromInsight(
      insight,
      AppLocalizations.of(context)!,
    );
    final accent = switch (insight.status) {
      RunningCoachStatus.good => Colors.green.shade700,
      RunningCoachStatus.watch => Colors.orange.shade700,
      RunningCoachStatus.needsWork => Colors.red.shade700,
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  copy.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                copy.value,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: accent),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: insight.score / 100,
                    minHeight: 8,
                    color: accent,
                    backgroundColor: accent.withAlpha(30),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _ScoreBadge(score: insight.score),
            ],
          ),
          if (priority != null) ...[
            const SizedBox(height: 8),
            _PriorityBadge(priority: priority!),
          ],
        ],
      ),
    );
  }
}

class _FocusSummaryTile extends StatelessWidget {
  final RunningCoachingInsight insight;
  final int priority;

  const _FocusSummaryTile({required this.insight, required this.priority});

  @override
  Widget build(BuildContext context) {
    final copy = RunningCoachInsightCopy.fromInsight(
      insight,
      AppLocalizations.of(context)!,
    );
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withAlpha(140),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PriorityBadge(priority: priority),
              _ScoreBadge(score: insight.score),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            copy.title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(copy.summary, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(
            copy.cue,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final int priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          l10n.runningCoachPriorityLabel(priority),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int score;

  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          l10n.runningCoachMetricScore(score),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
