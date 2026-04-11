import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/running_coaching_service.dart';
import '../../application/running_video_analysis_service.dart';
import '../../domain/entities/running_video_analysis_result.dart';
import '../../gen/app_localizations.dart';
import 'running_live_coach_guide_screen.dart';
import 'running_live_coach_screen.dart';
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
            for (final insight in _coachingReport!.insights) ...[
              _InsightCard(insight: insight),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }

  bool get _canAnalyze => !_isAnalyzing && _selectedVideo != null;

  void _openLiveCoach() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RunningLiveCoachScreen(),
      ),
    );
  }

  void _openLiveGuide() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RunningLiveCoachGuideScreen(onStart: _openLiveCoach),
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
            colors: [
              scheme.primary.withAlpha(220),
              scheme.secondaryContainer,
            ],
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

class _InsightCard extends StatelessWidget {
  final RunningCoachingInsight insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final copy = _InsightCopy.fromInsight(insight, l10n);
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    copy.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
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
                label: l10n.runningCoachMetricValueLabel, value: copy.value),
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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

class _InsightCopy {
  final String title;
  final String summary;
  final String cue;
  final String drill;
  final String statusLabel;
  final String value;

  const _InsightCopy({
    required this.title,
    required this.summary,
    required this.cue,
    required this.drill,
    required this.statusLabel,
    required this.value,
  });

  factory _InsightCopy.fromInsight(
    RunningCoachingInsight insight,
    AppLocalizations l10n,
  ) {
    final statusLabel = switch (insight.status) {
      RunningCoachStatus.good => l10n.runningCoachStatusGood,
      RunningCoachStatus.watch => l10n.runningCoachStatusWatch,
      RunningCoachStatus.needsWork => l10n.runningCoachStatusNeedsWork,
    };
    final value = switch (insight.metric) {
      RunningCoachMetric.posture =>
        l10n.runningCoachLeanValue(insight.value.toStringAsFixed(1)),
      RunningCoachMetric.bounce =>
        l10n.runningCoachBounceValue(insight.value.toStringAsFixed(1)),
      RunningCoachMetric.footStrike =>
        l10n.runningCoachFootStrikeValue(insight.value.toStringAsFixed(2)),
      RunningCoachMetric.kneeFlexion =>
        l10n.runningCoachKneeValue(insight.value.toStringAsFixed(0)),
      RunningCoachMetric.armCarriage =>
        l10n.runningCoachArmValue(insight.value.toStringAsFixed(0)),
    };

    return switch (insight.finding) {
      RunningCoachFinding.postureAligned => _InsightCopy(
          title: l10n.runningCoachInsightPostureTitle,
          summary: l10n.runningCoachPostureGoodSummary,
          cue: l10n.runningCoachPostureGoodCue,
          drill: l10n.runningCoachPostureGoodDrill,
          statusLabel: statusLabel,
          value: value,
        ),
      RunningCoachFinding.postureTooUpright => _InsightCopy(
          title: l10n.runningCoachInsightPostureTitle,
          summary: l10n.runningCoachPostureUprightSummary,
          cue: l10n.runningCoachPostureUprightCue,
          drill: l10n.runningCoachPostureUprightDrill,
          statusLabel: statusLabel,
          value: value,
        ),
      RunningCoachFinding.postureTooLean => _InsightCopy(
          title: l10n.runningCoachInsightPostureTitle,
          summary: l10n.runningCoachPostureLeanSummary,
          cue: l10n.runningCoachPostureLeanCue,
          drill: l10n.runningCoachPostureLeanDrill,
          statusLabel: statusLabel,
          value: value,
        ),
      RunningCoachFinding.bounceEfficient => _InsightCopy(
          title: l10n.runningCoachInsightBounceTitle,
          summary: l10n.runningCoachBounceGoodSummary,
          cue: l10n.runningCoachBounceGoodCue,
          drill: l10n.runningCoachBounceGoodDrill,
          statusLabel: statusLabel,
          value: value,
        ),
      RunningCoachFinding.bounceTooHigh => _InsightCopy(
          title: l10n.runningCoachInsightBounceTitle,
          summary: l10n.runningCoachBounceHighSummary,
          cue: l10n.runningCoachBounceHighCue,
          drill: l10n.runningCoachBounceHighDrill,
          statusLabel: statusLabel,
          value: value,
        ),
      RunningCoachFinding.footStrikeUnderBody => _InsightCopy(
          title: l10n.runningCoachInsightFootStrikeTitle,
          summary: l10n.runningCoachFootStrikeGoodSummary,
          cue: l10n.runningCoachFootStrikeGoodCue,
          drill: l10n.runningCoachFootStrikeGoodDrill,
          statusLabel: statusLabel,
          value: value,
        ),
      RunningCoachFinding.footStrikeOverstride => _InsightCopy(
          title: l10n.runningCoachInsightFootStrikeTitle,
          summary: l10n.runningCoachFootStrikeOverSummary,
          cue: l10n.runningCoachFootStrikeOverCue,
          drill: l10n.runningCoachFootStrikeOverDrill,
          statusLabel: statusLabel,
          value: value,
        ),
      RunningCoachFinding.kneeFlexionLoaded => _InsightCopy(
          title: l10n.runningCoachInsightKneeTitle,
          summary: l10n.runningCoachKneeGoodSummary,
          cue: l10n.runningCoachKneeGoodCue,
          drill: l10n.runningCoachKneeGoodDrill,
          statusLabel: statusLabel,
          value: value,
        ),
      RunningCoachFinding.kneeTooStraight => _InsightCopy(
          title: l10n.runningCoachInsightKneeTitle,
          summary: l10n.runningCoachKneeStraightSummary,
          cue: l10n.runningCoachKneeStraightCue,
          drill: l10n.runningCoachKneeStraightDrill,
          statusLabel: statusLabel,
          value: value,
        ),
      RunningCoachFinding.kneeTooCollapsed => _InsightCopy(
          title: l10n.runningCoachInsightKneeTitle,
          summary: l10n.runningCoachKneeCollapseSummary,
          cue: l10n.runningCoachKneeCollapseCue,
          drill: l10n.runningCoachKneeCollapseDrill,
          statusLabel: statusLabel,
          value: value,
        ),
      RunningCoachFinding.armCompact => _InsightCopy(
          title: l10n.runningCoachInsightArmTitle,
          summary: l10n.runningCoachArmGoodSummary,
          cue: l10n.runningCoachArmGoodCue,
          drill: l10n.runningCoachArmGoodDrill,
          statusLabel: statusLabel,
          value: value,
        ),
      RunningCoachFinding.armTooOpen => _InsightCopy(
          title: l10n.runningCoachInsightArmTitle,
          summary: l10n.runningCoachArmOpenSummary,
          cue: l10n.runningCoachArmOpenCue,
          drill: l10n.runningCoachArmOpenDrill,
          statusLabel: statusLabel,
          value: value,
        ),
      RunningCoachFinding.armTooTight => _InsightCopy(
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
