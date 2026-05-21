import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/running_coach_history_service.dart';
import '../../application/running_coaching_service.dart';
import '../../application/running_video_analysis_service.dart';
import '../../domain/entities/running_coach_session.dart';
import '../../domain/entities/running_video_analysis_result.dart';
import '../../domain/repositories/option_repository.dart';
import '../../gen/app_localizations.dart';
import 'running_coach_insight_copy.dart';
import '../widgets/app_feedback.dart';

class RunningCoachScreen extends StatefulWidget {
  final OptionRepository? optionRepository;

  const RunningCoachScreen({super.key, this.optionRepository});

  @override
  State<RunningCoachScreen> createState() => _RunningCoachScreenState();
}

class _RunningCoachScreenState extends State<RunningCoachScreen> {
  final ImagePicker _picker = ImagePicker();
  final RunningVideoAnalysisService _analysisService =
      const RunningVideoAnalysisService();
  final RunningCoachingService _coachingService =
      const RunningCoachingService();

  RunningCoachHistoryService? _historyService;
  XFile? _selectedVideo;
  RunningVideoAnalysisResult? _analysisResult;
  RunningCoachingReport? _coachingReport;
  List<RunningCoachSessionAnalysis> _recentSessions =
      const <RunningCoachSessionAnalysis>[];
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    final optionRepository = widget.optionRepository;
    if (optionRepository != null) {
      _historyService = RunningCoachHistoryService(optionRepository);
      _recentSessions = _historyService!.allSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final insightSections = _coachingReport == null
        ? const <_InsightRegionSection>[]
        : _buildInsightSections(l10n, _coachingReport!);
    final sampleResult = _sampleAnalysisResult();
    final sampleReport = _coachingService.buildReport(sampleResult);
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
          _RunningCoachUploadGuideCard(
            title: l10n.runningCoachUploadGuideTitle,
            body: l10n.runningCoachUploadGuideBody,
            onShowGuide: () => _showRecordingGuide(l10n),
            onShowSample: () => _showSampleAnalysis(
              l10n,
              result: sampleResult,
              report: sampleReport,
            ),
          ),
          const SizedBox(height: 12),
          _VideoAnalysisIntentCard(
            selectedVideoName: _selectedVideo?.name,
            isAnalyzing: _isAnalyzing,
            canAnalyze: _canAnalyze,
            onPickVideo: _pickVideo,
            onAnalyzeVideo: _analyzeVideo,
          ),
          if (_recentSessions.isNotEmpty) ...[
            const SizedBox(height: 12),
            _RecentSessionsCard(sessions: _recentSessions.take(3).toList()),
          ],
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

  Future<void> _showRecordingGuide(AppLocalizations l10n) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: _RunningCoachGuideSheet(
            title: l10n.runningCoachTipsTitle,
            tips: [
              l10n.runningCoachTipWholeBody,
              l10n.runningCoachTipSideView,
              l10n.runningCoachTipSteadyCamera,
            ],
            steps: [
              l10n.runningCoachUploadGuideStepSide,
              l10n.runningCoachUploadGuideStepDistance,
              l10n.runningCoachUploadGuideStepDuration,
              l10n.runningCoachUploadGuideStepLight,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSampleAnalysis(
    AppLocalizations l10n, {
    required RunningVideoAnalysisResult result,
    required RunningCoachingReport report,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: _RunningCoachSampleCard(
            title: l10n.runningCoachSampleTitle,
            body: l10n.runningCoachSampleBody,
            result: result,
            report: report,
          ),
        ),
      ),
    );
  }

  RunningVideoAnalysisResult _sampleAnalysisResult() {
    return const RunningVideoAnalysisResult(
      videoDuration: Duration(seconds: 8),
      sampledFrames: 16,
      validFrames: 14,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 4.5,
      verticalBounceRatio: 0.085,
      footStrikeDistanceRatio: 0.18,
      stanceKneeAngleDegrees: 168,
      elbowAngleDegrees: 108,
      metricQualities: <RunningCoachMetric, RunningMetricQuality>{
        RunningCoachMetric.posture: RunningMetricQuality(
          confidence: 0.88,
          sampleCount: 14,
        ),
        RunningCoachMetric.bounce: RunningMetricQuality(
          confidence: 0.84,
          sampleCount: 14,
        ),
        RunningCoachMetric.footStrike: RunningMetricQuality(
          confidence: 0.82,
          sampleCount: 13,
        ),
        RunningCoachMetric.kneeFlexion: RunningMetricQuality(
          confidence: 0.80,
          sampleCount: 12,
        ),
        RunningCoachMetric.armCarriage: RunningMetricQuality(
          confidence: 0.78,
          sampleCount: 12,
        ),
      },
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
      final historyService = _historyService;
      final updatedSessions = historyService == null
          ? _recentSessions
          : await historyService.saveUploadAnalysis(
              result: analysis,
              report: report,
            );
      if (!mounted) return;
      setState(() {
        _analysisResult = analysis;
        _coachingReport = report;
        _recentSessions = updatedSessions;
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

class _RunningCoachUploadGuideCard extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onShowGuide;
  final VoidCallback onShowSample;

  const _RunningCoachUploadGuideCard({
    required this.title,
    required this.body,
    required this.onShowGuide,
    required this.onShowSample,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.video_camera_back_outlined,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(body, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.runningCoachTipsTitle,
                  onPressed: onShowGuide,
                  icon: const Icon(Icons.info_outline),
                ),
                IconButton(
                  tooltip: l10n.runningCoachSampleTitle,
                  onPressed: onShowSample,
                  icon: const Icon(Icons.analytics_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RunningCoachGuideSheet extends StatelessWidget {
  final String title;
  final List<String> tips;
  final List<String> steps;

  const _RunningCoachGuideSheet({
    required this.title,
    required this.tips,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        for (final tip in tips) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.check_circle_outline, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(tip)),
            ],
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        for (var index = 0; index < steps.length; index += 1) ...[
          _NumberedGuideStep(number: index + 1, text: steps[index]),
          if (index != steps.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _NumberedGuideStep extends StatelessWidget {
  final int number;
  final String text;

  const _NumberedGuideStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: scheme.primary.withValues(alpha: 0.12),
          child: Text(
            '$number',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

String _formatRunningDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  if (minutes == 0) return '${seconds}s';
  return '${minutes}m ${seconds}s';
}

class _RunningCoachSampleCard extends StatelessWidget {
  final String title;
  final String body;
  final RunningVideoAnalysisResult result;
  final RunningCoachingReport report;

  const _RunningCoachSampleCard({
    required this.title,
    required this.body,
    required this.result,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final primaryFocus = report.primaryFocus;
    final focusCopy = primaryFocus == null
        ? null
        : RunningCoachInsightCopy.fromInsight(primaryFocus, l10n);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.analytics_outlined,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(body, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SampleVideoFrame(score: report.overallScore),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatChip(
                  label: l10n.runningCoachDurationLabel,
                  value: _formatRunningDuration(result.videoDuration),
                ),
                _StatChip(
                  label: l10n.runningCoachFramesAnalyzedLabel,
                  value: '${result.validFrames}/${result.sampledFrames}',
                ),
                _StatChip(
                  label: l10n.runningCoachOverallScoreLabel,
                  value: '${report.overallScore}',
                ),
              ],
            ),
            if (focusCopy != null) ...[
              const SizedBox(height: 12),
              Text(
                focusCopy.title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                focusCopy.summary,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SampleVideoFrame extends StatefulWidget {
  final int score;

  const _SampleVideoFrame({required this.score});

  @override
  State<_SampleVideoFrame> createState() => _SampleVideoFrameState();
}

class _SampleVideoFrameState extends State<_SampleVideoFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 16 / 7,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  painter: _SampleRunnerPainter(
                    progress: _controller.value,
                    lineColor: scheme.primary,
                    trackColor: scheme.outlineVariant,
                    ghostColor: scheme.primary.withValues(alpha: 0.18),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Text(
                    '${widget.score}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SampleRunnerPainter extends CustomPainter {
  final double progress;
  final Color lineColor;
  final Color trackColor;
  final Color ghostColor;

  const _SampleRunnerPainter({
    required this.progress,
    required this.lineColor,
    required this.trackColor,
    required this.ghostColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.78),
      Offset(size.width * 0.92, size.height * 0.78),
      trackPaint,
    );

    for (final offset in const <double>[0.66, 0.33]) {
      final ghostProgress = (progress - offset) % 1.0;
      _drawRunner(
        canvas,
        size,
        progress: ghostProgress,
        color: ghostColor,
        strokeWidth: 3,
      );
    }
    _drawRunner(
      canvas,
      size,
      progress: progress,
      color: lineColor,
      strokeWidth: 4,
    );
  }

  void _drawRunner(
    Canvas canvas,
    Size size, {
    required double progress,
    required Color color,
    required double strokeWidth,
  }) {
    final phase = progress * 2 * math.pi;
    final stride = math.sin(phase);
    final drive = (stride + 1) / 2;
    final recovery = 1 - drive;
    final bob = math.cos(phase * 2) * size.height * 0.010;
    final isGhost = strokeWidth < 4;
    final baseAlpha = isGhost ? 0.18 : 0.96;
    final kitColor = color.withValues(alpha: baseAlpha);
    final shortsColor = Color.lerp(
      color,
      Colors.black,
      0.34,
    )!.withValues(alpha: baseAlpha);
    final skinColor = isGhost
        ? color.withValues(alpha: 0.16)
        : const Color(0xFFE8B98E);
    final hairColor = isGhost
        ? color.withValues(alpha: 0.12)
        : const Color(0xFF3A2A24);
    final outlineColor = isGhost
        ? color.withValues(alpha: 0.10)
        : Color.lerp(color, Colors.black, 0.20)!.withValues(alpha: 0.72);
    final groundY = size.height * 0.78;
    final x = size.width * (0.17 + progress * 0.60);
    final hip = Offset(x, groundY - size.height * 0.28 + bob);
    final chest = Offset(
      hip.dx - size.width * 0.044,
      hip.dy - size.height * 0.18,
    );
    final neck = Offset(
      chest.dx - size.width * 0.010,
      chest.dy - size.height * 0.064,
    );
    final head = Offset(
      neck.dx - size.width * 0.016,
      neck.dy - size.height * 0.044,
    );
    final shoulderFront = Offset(
      chest.dx + size.width * 0.040,
      chest.dy + size.height * 0.006,
    );
    final shoulderRear = Offset(
      chest.dx - size.width * 0.036,
      chest.dy + size.height * 0.018,
    );
    final hipFront = Offset(hip.dx + size.width * 0.032, hip.dy);
    final hipRear = Offset(
      hip.dx - size.width * 0.032,
      hip.dy + size.height * 0.006,
    );

    double mix(double a, double b, double t) => a + (b - a) * t;

    ({Offset knee, Offset ankle, Offset toe}) legPose(
      Offset anchor,
      double amount,
    ) {
      final knee = Offset(
        anchor.dx + size.width * mix(-0.088, 0.135, amount),
        anchor.dy + size.height * mix(0.152, 0.074, amount),
      );
      final ankle = Offset(
        anchor.dx + size.width * mix(-0.205, 0.154, amount),
        groundY - size.height * mix(0.004, 0.118, amount),
      );
      final toe = Offset(
        ankle.dx + size.width * mix(-0.058, 0.074, amount),
        groundY - size.height * mix(0.000, 0.038, amount),
      );
      return (knee: knee, ankle: ankle, toe: toe);
    }

    ({Offset elbow, Offset wrist}) armPose(
      Offset anchor,
      double amount,
      double direction,
    ) {
      final elbow = Offset(
        anchor.dx + direction * size.width * mix(0.045, 0.122, amount),
        anchor.dy + size.height * mix(0.074, 0.128, 1 - amount),
      );
      final wrist = Offset(
        elbow.dx - direction * size.width * mix(0.052, 0.020, amount),
        elbow.dy + size.height * mix(0.078, 0.032, amount),
      );
      return (elbow: elbow, wrist: wrist);
    }

    final frontLeg = legPose(hipFront, drive);
    final rearLeg = legPose(hipRear, recovery);
    final frontArm = armPose(shoulderFront, recovery, -1);
    final rearArm = armPose(shoulderRear, drive, 1);
    final upperLimbWidth = math.max(
      7.0,
      size.height * (isGhost ? 0.030 : 0.045),
    );
    final lowerLimbWidth = math.max(
      6.0,
      size.height * (isGhost ? 0.026 : 0.038),
    );
    final footWidth = math.max(5.0, size.height * (isGhost ? 0.026 : 0.034));

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          hip.dx + size.width * 0.02,
          groundY + size.height * 0.025,
        ),
        width: size.width * 0.30,
        height: size.height * 0.08,
      ),
      Paint()..color = color.withValues(alpha: isGhost ? 0.04 : 0.10),
    );

    for (final line in <double>[0.0, 0.045, 0.09]) {
      final start = Offset(
        hip.dx - size.width * (0.20 + line),
        hip.dy + size.height * (0.02 + line),
      );
      canvas.drawLine(
        start,
        Offset(start.dx - size.width * 0.10, start.dy + size.height * 0.012),
        Paint()
          ..color = color.withValues(alpha: isGhost ? 0.05 : 0.16)
          ..strokeWidth = math.max(1.0, strokeWidth * 0.32)
          ..strokeCap = StrokeCap.round,
      );
    }

    final rearSkin = isGhost
        ? color.withValues(alpha: 0.11)
        : skinColor.withValues(alpha: 0.56);
    final rearShoe = isGhost
        ? color.withValues(alpha: 0.12)
        : outlineColor.withValues(alpha: 0.62);
    _drawLimb(
      canvas,
      color: rearSkin,
      a: shoulderRear,
      b: rearArm.elbow,
      c: rearArm.wrist,
      upperWidth: upperLimbWidth * 0.82,
      lowerWidth: lowerLimbWidth * 0.78,
    );
    _drawLimb(
      canvas,
      color: rearSkin,
      a: hipRear,
      b: rearLeg.knee,
      c: rearLeg.ankle,
      upperWidth: upperLimbWidth,
      lowerWidth: lowerLimbWidth,
    );
    _drawShoe(canvas, rearLeg.ankle, rearLeg.toe, rearShoe, footWidth);

    final torso = Path()
      ..moveTo(shoulderRear.dx, shoulderRear.dy)
      ..lineTo(shoulderFront.dx, shoulderFront.dy)
      ..lineTo(hipFront.dx, hipFront.dy)
      ..lineTo(hipRear.dx, hipRear.dy)
      ..close();
    canvas.drawPath(
      torso,
      Paint()
        ..color = kitColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      torso,
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, strokeWidth * 0.42)
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      Path()
        ..moveTo(
          hipRear.dx - size.width * 0.004,
          hipRear.dy - size.height * 0.006,
        )
        ..lineTo(
          hipFront.dx + size.width * 0.008,
          hipFront.dy - size.height * 0.002,
        )
        ..lineTo(
          hipFront.dx + size.width * 0.030,
          hipFront.dy + size.height * 0.064,
        )
        ..lineTo(hip.dx + size.width * 0.002, hip.dy + size.height * 0.044)
        ..lineTo(
          hipRear.dx - size.width * 0.034,
          hipRear.dy + size.height * 0.068,
        )
        ..close(),
      Paint()..color = shortsColor,
    );
    _drawSegment(
      canvas,
      neck,
      chest,
      skinColor.withValues(alpha: isGhost ? 0.12 : 0.86),
      math.max(5.0, size.height * (isGhost ? 0.020 : 0.030)),
    );
    canvas.drawCircle(
      head,
      size.height * (isGhost ? 0.045 : 0.054),
      Paint()
        ..color = skinColor.withValues(alpha: isGhost ? 0.12 : 0.96)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(head.dx - size.width * 0.006, head.dy - size.height * 0.014),
      size.height * (isGhost ? 0.030 : 0.036),
      Paint()..color = hairColor,
    );
    canvas.drawCircle(
      Offset(head.dx + size.width * 0.020, head.dy - size.height * 0.006),
      math.max(1.5, size.height * 0.006),
      Paint()..color = outlineColor,
    );

    _drawLimb(
      canvas,
      color: skinColor.withValues(alpha: isGhost ? 0.15 : 0.94),
      a: hipFront,
      b: frontLeg.knee,
      c: frontLeg.ankle,
      upperWidth: upperLimbWidth * 1.06,
      lowerWidth: lowerLimbWidth * 1.02,
    );
    _drawShoe(
      canvas,
      frontLeg.ankle,
      frontLeg.toe,
      isGhost ? color.withValues(alpha: 0.15) : outlineColor,
      footWidth * 1.08,
    );
    _drawLimb(
      canvas,
      color: skinColor.withValues(alpha: isGhost ? 0.15 : 0.94),
      a: shoulderFront,
      b: frontArm.elbow,
      c: frontArm.wrist,
      upperWidth: upperLimbWidth * 0.86,
      lowerWidth: lowerLimbWidth * 0.82,
    );

    _drawSegment(
      canvas,
      Offset(chest.dx - size.width * 0.010, chest.dy + size.height * 0.030),
      Offset(hip.dx + size.width * 0.006, hip.dy - size.height * 0.018),
      Colors.white.withValues(alpha: isGhost ? 0.04 : 0.28),
      math.max(1.0, strokeWidth * 0.34),
    );
  }

  void _drawLimb(
    Canvas canvas, {
    required Color color,
    required Offset a,
    required Offset b,
    required Offset c,
    required double upperWidth,
    required double lowerWidth,
  }) {
    _drawSegment(canvas, a, b, color, upperWidth);
    _drawSegment(canvas, b, c, color, lowerWidth);
    canvas.drawCircle(
      b,
      math.max(2.2, lowerWidth * 0.42),
      Paint()..color = color,
    );
  }

  void _drawSegment(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
    double width,
  ) {
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawShoe(
    Canvas canvas,
    Offset ankle,
    Offset toe,
    Color color,
    double width,
  ) {
    _drawSegment(canvas, ankle, toe, color, width);
  }

  @override
  bool shouldRepaint(covariant _SampleRunnerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.ghostColor != ghostColor;
  }
}

class _VideoAnalysisIntentCard extends StatelessWidget {
  final String? selectedVideoName;
  final bool isAnalyzing;
  final bool canAnalyze;
  final VoidCallback onPickVideo;
  final VoidCallback onAnalyzeVideo;

  const _VideoAnalysisIntentCard({
    required this.selectedVideoName,
    required this.isAnalyzing,
    required this.canAnalyze,
    required this.onPickVideo,
    required this.onAnalyzeVideo,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.video_library_outlined,
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.runningCoachAnalyzeAction,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.runningCoachAnalyzeBody,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.movie_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedVideoName ?? l10n.runningCoachNoVideoSelected,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: isAnalyzing ? null : onPickVideo,
                  icon: const Icon(Icons.video_library_outlined),
                  label: Text(l10n.runningCoachPickVideoAction),
                ),
                FilledButton.icon(
                  onPressed: canAnalyze ? onAnalyzeVideo : null,
                  icon: isAnalyzing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_circle_outline),
                  label: Text(
                    isAnalyzing
                        ? l10n.runningCoachAnalysisInProgress
                        : l10n.runningCoachAnalyzeAction,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentSessionsCard extends StatelessWidget {
  final List<RunningCoachSessionAnalysis> sessions;

  const _RecentSessionsCard({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history_rounded, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  _recentSessionsTitle(context),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < sessions.length; index += 1) ...[
              _RecentSessionTile(session: sessions[index]),
              if (index != sessions.length - 1) const Divider(height: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecentSessionTile extends StatelessWidget {
  final RunningCoachSessionAnalysis session;

  const _RecentSessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final copy = RunningCoachInsightCopy.fromInsight(
      session.primaryInsight,
      l10n,
    );
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              '${session.overallScore}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                copy.title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                copy.cue,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _TinySessionPill(text: _sessionSourceLabel(context, session)),
                  _TinySessionPill(text: _formatSessionDate(context, session)),
                  _TinySessionPill(
                    text:
                        '${_confidenceLabel(context)} ${(session.primaryConfidence * 100).round()}%',
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

class _TinySessionPill extends StatelessWidget {
  final String text;

  const _TinySessionPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(150),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(text, style: Theme.of(context).textTheme.labelSmall),
      ),
    );
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
            if (report.primaryFocus case final primaryFocus?) ...[
              const SizedBox(height: 16),
              _PrimaryFocusCard(insight: primaryFocus),
            ],
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
                _QualityBadge(quality: insight.quality),
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
            if (insight.quality.isLowConfidence) ...[
              const SizedBox(height: 10),
              Text(
                _qualityReasonText(context, insight.quality),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
              const SizedBox(width: 8),
              _QualityBadge(quality: insight.quality),
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

class _PrimaryFocusCard extends StatelessWidget {
  final RunningCoachingInsight insight;

  const _PrimaryFocusCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final copy = RunningCoachInsightCopy.fromInsight(insight, l10n);
    final scheme = Theme.of(context).colorScheme;
    final isFix = insight.status != RunningCoachStatus.good;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isFix ? scheme.primaryContainer : scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isFix
                      ? Icons.priority_high_rounded
                      : Icons.check_circle_outline_rounded,
                  color: isFix
                      ? scheme.onPrimaryContainer
                      : scheme.onTertiaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFix
                            ? l10n.runningCoachFocusTitle
                            : l10n.runningCoachMaintainTitle,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: isFix
                              ? scheme.onPrimaryContainer
                              : scheme.onTertiaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        copy.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _QualityBadge(quality: insight.quality),
              ],
            ),
            const SizedBox(height: 12),
            Text(copy.summary, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            Text(
              copy.cue,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(copy.drill, style: Theme.of(context).textTheme.bodySmall),
            if (insight.quality.isLowConfidence) ...[
              const SizedBox(height: 8),
              Text(
                _qualityReasonText(context, insight.quality),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
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

class _QualityBadge extends StatelessWidget {
  final RunningMetricQuality quality;

  const _QualityBadge({required this.quality});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLow = quality.isLowConfidence;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isLow ? scheme.errorContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isLow ? scheme.error.withAlpha(120) : scheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          '${_confidenceLabel(context)} ${quality.confidencePercent}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isLow ? scheme.onErrorContainer : null,
            fontWeight: FontWeight.w700,
          ),
        ),
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

String _confidenceLabel(BuildContext context) {
  return Localizations.localeOf(context).languageCode == 'ko'
      ? '신뢰도'
      : 'Confidence';
}

String _qualityReasonText(BuildContext context, RunningMetricQuality quality) {
  final isKorean = Localizations.localeOf(context).languageCode == 'ko';
  return switch (quality.reason) {
    'low_coverage' =>
      isKorean
          ? '추적된 프레임 비율이 낮아 이 지표는 보수적으로 봐 주세요.'
          : 'Tracking coverage is low, so treat this metric conservatively.',
    'limited_samples' =>
      isKorean
          ? '안정적으로 읽은 프레임이 적어 같은 구도로 한 번 더 확인하는 것이 좋아요.'
          : 'Only a small set of stable frames was read; confirm once more from the same angle.',
    'contact_phase_proxy' =>
      isKorean
          ? '접지 구간을 추정한 프레임이 적어 착지와 무릎 지표는 한 번 더 확인해 주세요.'
          : 'The contact phase used only a small proxy window; confirm foot strike and knee metrics again.',
    _ =>
      isKorean
          ? '촬영 품질이 낮아 같은 구도로 다시 확인하는 것이 좋아요.'
          : 'Capture quality is low; confirm again from the same angle.',
  };
}

String _recentSessionsTitle(BuildContext context) {
  return Localizations.localeOf(context).languageCode == 'ko'
      ? '최근 분석 기록'
      : 'Recent analyses';
}

String _sessionSourceLabel(
  BuildContext context,
  RunningCoachSessionAnalysis session,
) {
  final isKorean = Localizations.localeOf(context).languageCode == 'ko';
  return switch (session.source) {
    RunningCoachSessionSource.uploadVideo =>
      isKorean ? '영상 분석' : 'Video analysis',
    RunningCoachSessionSource.liveRun => isKorean ? '실시간 코치' : 'Live run',
    RunningCoachSessionSource.sprintLive =>
      isKorean ? '스프린트 코칭' : 'Sprint live',
  };
}

String _formatSessionDate(
  BuildContext context,
  RunningCoachSessionAnalysis session,
) {
  final local = session.analyzedAt.toLocal();
  final material = MaterialLocalizations.of(context);
  return '${material.formatShortDate(local)} ${TimeOfDay.fromDateTime(local).format(context)}';
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
