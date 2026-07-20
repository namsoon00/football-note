import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../application/running_coach_history_service.dart';
import '../../application/running_coaching_service.dart';
import '../../application/running_video_analysis_service.dart';
import '../../application/sport_service.dart';
import '../../domain/entities/running_coach_session.dart';
import '../../domain/entities/running_video_analysis_result.dart';
import '../../domain/repositories/option_repository.dart';
import '../../gen/app_localizations.dart';
import '../running_coach/running_pose_overlay.dart';
import '../models/sample_runner_pose.dart';
import 'running_coach_insight_copy.dart';
import 'running_live_coach_screen.dart';
import 'sprint_live_coaching_screen.dart';
import '../widgets/app_bar_action_button.dart';
import '../widgets/app_feedback.dart';

class RunningCoachScreen extends StatefulWidget {
  final OptionRepository? optionRepository;
  final RunningVideoAnalysisService analysisService;
  final RunningCoachSampleVideoPreparer sampleVideoPreparer;

  const RunningCoachScreen({
    super.key,
    this.optionRepository,
    this.analysisService = const RunningVideoAnalysisService(),
    this.sampleVideoPreparer = prepareRunningCoachSampleVideoForAnalysis,
  });

  @override
  State<RunningCoachScreen> createState() => _RunningCoachScreenState();
}

typedef RunningCoachSampleVideoPreparer
    = Future<RunningCoachPreparedSampleVideo> Function(String assetPath);

class RunningCoachPreparedSampleVideo {
  final File file;
  final Future<void> Function() dispose;

  const RunningCoachPreparedSampleVideo({
    required this.file,
    required this.dispose,
  });
}

Future<RunningCoachPreparedSampleVideo>
    prepareRunningCoachSampleVideoForAnalysis(String assetPath) async {
  final tempDirectory = await Directory.systemTemp.createTemp(
    'football_note_running_sample_',
  );
  final bytes = await rootBundle.load(assetPath);
  final file = File('${tempDirectory.path}/${assetPath.split('/').last}');
  await file.writeAsBytes(
    bytes.buffer.asUint8List(
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    ),
    flush: true,
  );
  return RunningCoachPreparedSampleVideo(
    file: file,
    dispose: () async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    },
  );
}

@visibleForTesting
Widget runningAnalysisResultScreenForTesting({
  required RunningVideoAnalysisResult result,
  required RunningCoachingReport report,
  required RunningCoachSessionAnalysis session,
}) {
  return _RunningAnalysisResultScreen(
    result: result,
    report: report,
    session: session,
  );
}

@visibleForTesting
Widget runningArchivedAnalysisVideoCardForTesting({
  required RunningCoachSessionAnalysis session,
}) {
  return _ArchivedAnalysisVideoCard(session: session);
}

class _RunningCoachScreenState extends State<RunningCoachScreen> {
  final ImagePicker _picker = ImagePicker();
  final RunningCoachingService _coachingService =
      const RunningCoachingService();

  RunningCoachHistoryService? _historyService;
  XFile? _selectedVideo;
  List<RunningCoachSessionAnalysis> _recentSessions =
      const <RunningCoachSessionAnalysis>[];
  _RunningCoachSampleAnalysisBundle? _sampleAnalysisCache;
  Future<_RunningCoachSampleAnalysisBundle>? _sampleAnalysisFuture;
  int _sampleAnalysisRequestId = 0;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    final optionRepository = widget.optionRepository;
    if (optionRepository != null) {
      final sportId = SportService(optionRepository).currentSportId();
      _historyService = RunningCoachHistoryService(
        optionRepository,
        sportId: sportId,
      );
      _recentSessions = _historyService!.allSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(l10n.runningCoachScreenTitle),
      ),
      body: _buildCoachPage(l10n),
    );
  }

  Widget _buildCoachPage(AppLocalizations l10n) {
    final mission = _missionForToday(DateTime.now());
    return ListView(
      key: const PageStorageKey('running-coach-simple-page'),
      padding: const EdgeInsets.all(16),
      children: [
        _HeroCard(
          title: l10n.runningCoachHeroTitle,
          body: l10n.runningCoachHeroBody,
        ),
        const SizedBox(height: 12),
        _RunningMissionCard(
          mission: mission,
          onStartLiveCoach: _openLiveCoach,
          onStartSprintCoach: _openSprintCoach,
        ),
        const SizedBox(height: 12),
        _RunningCoachUploadGuideCard(
          title: l10n.runningCoachUploadGuideTitle,
          body: l10n.runningCoachUploadGuideBody,
          onShowSampleGuide: _showSampleAnalysis,
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
          _RecentSessionsCard(
            sessions: _recentSessions.take(3).toList(),
            totalCount: _recentSessions.length,
            onShowAll: _showAnalysisHistory,
            onSessionTap: _openAnalysisHistoryDetail,
          ),
        ],
      ],
    );
  }

  bool get _canAnalyze => !_isAnalyzing && _selectedVideo != null;

  void _openLiveCoach() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RunningLiveCoachScreen()),
    );
  }

  void _openSprintCoach() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SprintLiveCoachingScreen()),
    );
  }

  Future<void> _showSampleAnalysis() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _RunningCoachSampleAnalysisSheet(
        loadAnalysis: _loadSampleAnalysis,
        messageForException: _messageForException,
      ),
    );
  }

  Future<_RunningCoachSampleAnalysisBundle> _loadSampleAnalysis({
    bool forceRefresh = false,
  }) {
    final cached = _sampleAnalysisCache;
    if (!forceRefresh && cached != null) {
      return Future.value(cached);
    }
    final inFlight = _sampleAnalysisFuture;
    if (!forceRefresh && inFlight != null) {
      return inFlight;
    }

    if (forceRefresh) {
      _sampleAnalysisCache = null;
    }
    final requestId = ++_sampleAnalysisRequestId;
    final future = _analyzeBundledSampleVideos().then((bundle) {
      if (requestId == _sampleAnalysisRequestId) {
        _sampleAnalysisCache = bundle;
      }
      return bundle;
    });
    _sampleAnalysisFuture = future;
    unawaited(
      future.then<void>((_) {}, onError: (_) {}).whenComplete(() {
        if (_sampleAnalysisFuture == future) {
          _sampleAnalysisFuture = null;
        }
      }),
    );
    return future;
  }

  Future<_RunningCoachSampleAnalysisBundle>
      _analyzeBundledSampleVideos() async {
    final referenceResult = await _analyzeBundledSampleVideo(
      _sampleReferenceVideoAsset,
    );
    final mistakeResult = await _analyzeBundledSampleVideo(
      _sampleMistakeVideoAsset,
    );
    return _RunningCoachSampleAnalysisBundle(
      result: referenceResult,
      report: _coachingService.buildReport(referenceResult),
      mistakeResult: mistakeResult,
      mistakeReport: _coachingService.buildReport(mistakeResult),
    );
  }

  Future<RunningVideoAnalysisResult> _analyzeBundledSampleVideo(
    String assetPath,
  ) async {
    final preparedVideo = await widget.sampleVideoPreparer(assetPath);
    try {
      return await widget.analysisService.analyzeVideo(preparedVideo.file.path);
    } finally {
      unawaited(
        preparedVideo.dispose().catchError((_) {}),
      );
    }
  }

  Future<void> _showAnalysisHistory() {
    final sessions = _recentSessions;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.82,
          child: _AnalysisHistorySheet(
            sessions: sessions,
            onSessionSelected: (session) {
              Navigator.of(sheetContext).pop();
              _openAnalysisHistoryDetail(session);
            },
          ),
        ),
      ),
    );
  }

  void _openAnalysisHistoryDetail(RunningCoachSessionAnalysis session) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _AnalysisHistoryDetailScreen(session: session),
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
      final analyzedAt = DateTime.now();
      final analysis = await widget.analysisService.analyzeVideo(selected.path);
      final report = _coachingService.buildReport(analysis);
      final historyService = _historyService;
      final updatedSessions = historyService == null
          ? _recentSessions
          : await historyService.saveUploadAnalysis(
              result: analysis,
              report: report,
              sourceVideoPath: selected.path,
              sourceVideoName: selected.name,
              analyzedAt: analyzedAt,
            );
      final session = updatedSessions.isNotEmpty
          ? updatedSessions.first
          : _transientSessionForAnalysis(
              result: analysis,
              report: report,
              selectedVideo: selected,
              analyzedAt: analyzedAt,
            );
      if (!mounted) return;
      setState(() {
        _recentSessions = updatedSessions;
        _selectedVideo = null;
      });
      _openAnalysisResult(
        result: analysis,
        report: report,
        session: session,
      );
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

  RunningCoachSessionAnalysis _transientSessionForAnalysis({
    required RunningVideoAnalysisResult result,
    required RunningCoachingReport report,
    required XFile selectedVideo,
    required DateTime analyzedAt,
  }) {
    final primary = report.primaryFocus ?? report.rankedInsights.first;
    return RunningCoachSessionAnalysis(
      id: 'preview-${analyzedAt.microsecondsSinceEpoch}',
      analyzedAt: analyzedAt,
      source: RunningCoachSessionSource.uploadVideo,
      overallScore: report.overallScore,
      duration: result.videoDuration,
      sampledFrames: result.sampledFrames,
      validFrames: result.validFrames,
      primaryMetric: primary.metric,
      primaryFinding: primary.finding,
      primaryStatus: primary.status,
      primaryScore: primary.score,
      primaryValue: primary.value,
      primaryConfidence: primary.quality.confidence,
      videoPath: selectedVideo.path,
      videoName: selectedVideo.name,
    );
  }

  void _openAnalysisResult({
    required RunningVideoAnalysisResult result,
    required RunningCoachingReport report,
    required RunningCoachSessionAnalysis session,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _RunningAnalysisResultScreen(
          result: result,
          report: report,
          session: session,
        ),
      ),
    );
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
      'insufficient_contact_evidence' =>
        l10n.runningCoachInsufficientContactEvidence,
      _ => l10n.runningCoachAnalysisFailedGeneric,
    };
  }
}

class _InsightRegionSection {
  final String title;
  final List<RunningCoachingInsight> insights;

  const _InsightRegionSection({required this.title, required this.insights});
}

List<_InsightRegionSection> _buildRunningInsightSections(
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

String _bodyRegionTitle(AppLocalizations l10n, RunningCoachBodyRegion region) {
  return switch (region) {
    RunningCoachBodyRegion.upperBody => l10n.runningCoachBodyRegionUpper,
    RunningCoachBodyRegion.lowerBody => l10n.runningCoachBodyRegionLower,
    RunningCoachBodyRegion.wholeBody => l10n.runningCoachBodyRegionWhole,
  };
}

enum _RunningMissionKind {
  breakaway,
  pressureEscape,
  looseBall,
  firstThreeSteps,
}

class _RunningMission {
  final _RunningMissionKind kind;
  final int distanceMeters;
  final IconData icon;

  const _RunningMission({
    required this.kind,
    required this.distanceMeters,
    required this.icon,
  });

  String title(AppLocalizations l10n) {
    return switch (kind) {
      _RunningMissionKind.breakaway => l10n.runningCoachMissionBreakawayTitle,
      _RunningMissionKind.pressureEscape =>
        l10n.runningCoachMissionPressureTitle,
      _RunningMissionKind.looseBall => l10n.runningCoachMissionLooseBallTitle,
      _RunningMissionKind.firstThreeSteps =>
        l10n.runningCoachMissionFirstStepsTitle,
    };
  }

  String body(AppLocalizations l10n) {
    return switch (kind) {
      _RunningMissionKind.breakaway => l10n.runningCoachMissionBreakawayBody,
      _RunningMissionKind.pressureEscape =>
        l10n.runningCoachMissionPressureBody,
      _RunningMissionKind.looseBall => l10n.runningCoachMissionLooseBallBody,
      _RunningMissionKind.firstThreeSteps =>
        l10n.runningCoachMissionFirstStepsBody,
    };
  }

  String focus(AppLocalizations l10n) {
    return switch (kind) {
      _RunningMissionKind.breakaway => l10n.runningCoachMissionBreakawayFocus,
      _RunningMissionKind.pressureEscape =>
        l10n.runningCoachMissionPressureFocus,
      _RunningMissionKind.looseBall => l10n.runningCoachMissionLooseBallFocus,
      _RunningMissionKind.firstThreeSteps =>
        l10n.runningCoachMissionFirstStepsFocus,
    };
  }

  String reward(AppLocalizations l10n) {
    return switch (kind) {
      _RunningMissionKind.breakaway => l10n.runningCoachMissionBreakawayReward,
      _RunningMissionKind.pressureEscape =>
        l10n.runningCoachMissionPressureReward,
      _RunningMissionKind.looseBall => l10n.runningCoachMissionLooseBallReward,
      _RunningMissionKind.firstThreeSteps =>
        l10n.runningCoachMissionFirstStepsReward,
    };
  }
}

_RunningMission _missionForToday(DateTime now) {
  const missions = <_RunningMission>[
    _RunningMission(
      kind: _RunningMissionKind.breakaway,
      distanceMeters: 20,
      icon: Icons.keyboard_double_arrow_right_rounded,
    ),
    _RunningMission(
      kind: _RunningMissionKind.pressureEscape,
      distanceMeters: 10,
      icon: Icons.change_circle_outlined,
    ),
    _RunningMission(
      kind: _RunningMissionKind.looseBall,
      distanceMeters: 30,
      icon: Icons.sports_soccer_outlined,
    ),
    _RunningMission(
      kind: _RunningMissionKind.firstThreeSteps,
      distanceMeters: 10,
      icon: Icons.bolt_outlined,
    ),
  ];
  final daySeed = DateTime(now.year, now.month, now.day)
      .difference(DateTime(2026))
      .inDays
      .abs();
  return missions[daySeed % missions.length];
}

class _RunningMissionCard extends StatelessWidget {
  final _RunningMission mission;
  final VoidCallback onStartLiveCoach;
  final VoidCallback onStartSprintCoach;

  const _RunningMissionCard({
    required this.mission,
    required this.onStartLiveCoach,
    required this.onStartSprintCoach,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: const ValueKey('running-coach-today-mission-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(mission.icon, color: scheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.runningCoachMissionCardTitle,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mission.title(l10n),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(mission.body(l10n),
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MissionChip(
                  icon: Icons.straighten_rounded,
                  label: l10n.runningCoachMissionDistance(
                    mission.distanceMeters,
                  ),
                ),
                _MissionChip(
                  icon: Icons.center_focus_strong_rounded,
                  label: mission.focus(l10n),
                ),
                _MissionChip(
                  icon: Icons.auto_awesome_outlined,
                  label: mission.reward(l10n),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: onStartSprintCoach,
                  icon: const Icon(Icons.bolt_outlined),
                  label: Text(l10n.runningCoachMissionStartSprint),
                ),
                OutlinedButton.icon(
                  onPressed: onStartLiveCoach,
                  icon: const Icon(Icons.videocam_outlined),
                  label: Text(l10n.runningCoachMissionStartLive),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MissionChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.secondary.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: scheme.secondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunningCoachUploadGuideCard extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onShowSampleGuide;

  const _RunningCoachUploadGuideCard({
    required this.title,
    required this.body,
    required this.onShowSampleGuide,
  });

  @override
  Widget build(BuildContext context) {
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
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onShowSampleGuide,
                child: Text(l10n.runningCoachSampleGuideAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatRunningDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  if (minutes == 0) return '${seconds}s';
  return '${minutes}m ${seconds}s';
}

const int _sampleTimelineFrameCount = 24;
const int _sampleAnalysisPhaseCount = 6;
const String _sampleReferenceVideoAsset =
    'assets/videos/running_coach_reference_sample.mp4';
const String _sampleMistakeVideoAsset =
    'assets/videos/running_coach_mistake_sample.mp4';

enum _SampleVideoMode { reference, mistake }

enum _SampleDecisionMetricKind { posture, arms, landing, bounce }

class _RunningCoachSampleAnalysisBundle {
  final RunningVideoAnalysisResult result;
  final RunningCoachingReport report;
  final RunningVideoAnalysisResult mistakeResult;
  final RunningCoachingReport mistakeReport;

  const _RunningCoachSampleAnalysisBundle({
    required this.result,
    required this.report,
    required this.mistakeResult,
    required this.mistakeReport,
  });
}

class _RunningCoachSampleAnalysisSheet extends StatefulWidget {
  final Future<_RunningCoachSampleAnalysisBundle> Function({
    bool forceRefresh,
  }) loadAnalysis;
  final String Function(
    AppLocalizations l10n,
    RunningVideoAnalysisException error,
  ) messageForException;

  const _RunningCoachSampleAnalysisSheet({
    required this.loadAnalysis,
    required this.messageForException,
  });

  @override
  State<_RunningCoachSampleAnalysisSheet> createState() =>
      _RunningCoachSampleAnalysisSheetState();
}

class _RunningCoachSampleAnalysisSheetState
    extends State<_RunningCoachSampleAnalysisSheet> {
  late Future<_RunningCoachSampleAnalysisBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loadAnalysis();
  }

  void _retry() {
    setState(() {
      _future = widget.loadAnalysis(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: FutureBuilder<_RunningCoachSampleAnalysisBundle>(
          future: _future,
          builder: (context, snapshot) {
            final data = snapshot.data;
            if (snapshot.connectionState == ConnectionState.done &&
                !snapshot.hasError &&
                data != null) {
              return _RunningCoachSampleCard(
                title: l10n.runningCoachSampleTitle,
                body: l10n.runningCoachSampleBody,
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
                result: data.result,
                report: data.report,
                mistakeResult: data.mistakeResult,
                mistakeReport: data.mistakeReport,
              );
            }

            if (snapshot.hasError) {
              final error = snapshot.error;
              final body = error is RunningVideoAnalysisException
                  ? widget.messageForException(l10n, error)
                  : l10n.runningCoachAnalysisFailedGeneric;
              return _RunningCoachSampleStatusCard(
                key: const ValueKey('running-coach-sample-analysis-error'),
                title: l10n.runningCoachSampleAnalysisFailedTitle,
                body: body,
                actionLabel: l10n.runningCoachSampleAnalysisRetryAction,
                onAction: _retry,
              );
            }

            return _RunningCoachSampleStatusCard(
              key: const ValueKey('running-coach-sample-analysis-loading'),
              title: l10n.runningCoachSampleAnalysisLoadingTitle,
              body: l10n.runningCoachSampleAnalysisLoadingBody,
              showProgress: true,
            );
          },
        ),
      ),
    );
  }
}

class _RunningCoachSampleStatusCard extends StatelessWidget {
  final String title;
  final String body;
  final bool showProgress;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _RunningCoachSampleStatusCard({
    super.key,
    required this.title,
    required this.body,
    this.showProgress = false,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BackButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
            if (showProgress) ...[
              const SizedBox(height: 18),
              const Center(child: CircularProgressIndicator()),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const ValueKey('running-coach-sample-analysis-retry'),
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RunningCoachSampleCard extends StatefulWidget {
  final String title;
  final String body;
  final List<String> tips;
  final List<String> steps;
  final RunningVideoAnalysisResult result;
  final RunningCoachingReport report;
  final RunningVideoAnalysisResult mistakeResult;
  final RunningCoachingReport mistakeReport;

  const _RunningCoachSampleCard({
    required this.title,
    required this.body,
    required this.tips,
    required this.steps,
    required this.result,
    required this.report,
    required this.mistakeResult,
    required this.mistakeReport,
  });

  @override
  State<_RunningCoachSampleCard> createState() =>
      _RunningCoachSampleCardState();
}

class _RunningCoachSampleCardState extends State<_RunningCoachSampleCard> {
  _SampleVideoMode _mode = _SampleVideoMode.reference;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeResult = _mode == _SampleVideoMode.reference
        ? widget.result
        : widget.mistakeResult;
    final activeReport = _mode == _SampleVideoMode.reference
        ? widget.report
        : widget.mistakeReport;
    final modeTitle = _mode == _SampleVideoMode.reference
        ? l10n.runningCoachSampleReferenceTitle
        : l10n.runningCoachSampleMistakeTitle;
    final modeBody = _mode == _SampleVideoMode.reference
        ? l10n.runningCoachSampleReferenceBody
        : l10n.runningCoachSampleMistakeBody;
    final primaryFocus = activeReport.primaryFocus;
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
                BackButton(
                  key: const ValueKey('running-coach-sample-back-button'),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(widget.body, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<_SampleVideoMode>(
                segments: [
                  ButtonSegment<_SampleVideoMode>(
                    value: _SampleVideoMode.reference,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: Text(l10n.runningCoachSampleReferenceTab),
                  ),
                  ButtonSegment<_SampleVideoMode>(
                    value: _SampleVideoMode.mistake,
                    icon: const Icon(Icons.report_problem_outlined),
                    label: Text(l10n.runningCoachSampleMistakeTab),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) {
                  setState(() => _mode = selection.first);
                },
              ),
            ),
            const SizedBox(height: 12),
            _SampleVideoFrame(
              score: activeReport.overallScore,
              mode: _mode,
              result: activeResult,
              report: activeReport,
            ),
            const SizedBox(height: 12),
            _SampleAnalysisProcessPanel(
              title: l10n.runningCoachSampleProcessTitle,
              body: l10n.runningCoachSampleProcessBody,
              steps: [
                _SampleAnalysisStep(
                  icon: Icons.video_camera_back_outlined,
                  label: l10n.runningCoachSamplePhaseFrame,
                ),
                _SampleAnalysisStep(
                  icon: Icons.scatter_plot_outlined,
                  label: l10n.runningCoachSamplePhaseJoints,
                ),
                _SampleAnalysisStep(
                  icon: Icons.accessibility_new_rounded,
                  label: l10n.runningCoachSamplePhaseMuscles,
                ),
                _SampleAnalysisStep(
                  icon: Icons.polyline_outlined,
                  label: l10n.runningCoachSamplePhaseSkeleton,
                ),
                _SampleAnalysisStep(
                  icon: Icons.architecture_rounded,
                  label: l10n.runningCoachSamplePhaseAngles,
                ),
                _SampleAnalysisStep(
                  icon: Icons.speed_rounded,
                  label: l10n.runningCoachSamplePhaseContactScore,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SampleFrameCuePanel(
              panelKey: const ValueKey('running-coach-sample-joint-readouts'),
              title: modeTitle,
              body: modeBody,
              cues: _modeReadouts(l10n, activeReport),
            ),
            const SizedBox(height: 12),
            _SampleFrameCuePanel(
              title: l10n.runningCoachSampleFrameGuideTitle,
              body: l10n.runningCoachSampleFrameGuideBody,
              cues: [
                _SampleFrameCue(
                  icon: Icons.show_chart_rounded,
                  text: l10n.runningCoachSampleCueLean,
                ),
                _SampleFrameCue(
                  icon: Icons.center_focus_strong_rounded,
                  text: l10n.runningCoachSampleCueFrame,
                ),
                _SampleFrameCue(
                  icon: Icons.directions_run_rounded,
                  text: l10n.runningCoachSampleCueFoot,
                ),
                _SampleFrameCue(
                  icon: Icons.sync_alt_rounded,
                  text: l10n.runningCoachSampleCueArms,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SampleFrameCuePanel(
              panelKey: const ValueKey('running-coach-sample-analysis-method'),
              title: l10n.runningCoachSampleAnalysisMethodTitle,
              body: l10n.runningCoachSampleAnalysisMethodBody,
              cues: [
                _SampleFrameCue(
                  icon: Icons.accessibility_new_rounded,
                  text: l10n.runningCoachSampleMethodPose,
                ),
                _SampleFrameCue(
                  icon: Icons.architecture_rounded,
                  text: l10n.runningCoachSampleMethodAngles,
                ),
                _SampleFrameCue(
                  icon: Icons.ads_click_rounded,
                  text: l10n.runningCoachSampleMethodContact,
                ),
                _SampleFrameCue(
                  icon: Icons.verified_outlined,
                  text: l10n.runningCoachSampleMethodConfidence,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SampleRecordingGuidePanel(
              title: l10n.runningCoachSampleRecordingGuideTitle,
              tips: widget.tips,
              steps: widget.steps,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatChip(
                  label: l10n.runningCoachDurationLabel,
                  value: _formatRunningDuration(activeResult.videoDuration),
                ),
                _StatChip(
                  label: l10n.runningCoachFramesAnalyzedLabel,
                  value:
                      '${activeResult.validFrames}/${activeResult.sampledFrames}',
                ),
                _StatChip(
                  label: l10n.runningCoachOverallScoreLabel,
                  value: '${activeReport.overallScore}',
                ),
              ],
            ),
            if (activeResult.denseSamples.attemptedFrames > 0 ||
                activeResult.contactWindows.isNotEmpty) ...[
              const SizedBox(height: 12),
              _DenseContactEvidencePanel(result: activeResult),
            ],
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

  List<_SampleFrameCue> _modeReadouts(
    AppLocalizations l10n,
    RunningCoachingReport report,
  ) {
    const order = [
      RunningCoachMetric.posture,
      RunningCoachMetric.footStrike,
      RunningCoachMetric.kneeFlexion,
      RunningCoachMetric.armCarriage,
      RunningCoachMetric.bounce,
    ];
    return [
      for (final metric in order)
        if (_insightForMetric(report, metric) case final insight?)
          _SampleFrameCue(
            icon: _sampleMetricIcon(metric),
            text: _sampleReadoutText(l10n, insight),
          ),
    ];
  }
}

RunningCoachingInsight? _insightForMetric(
  RunningCoachingReport report,
  RunningCoachMetric metric,
) {
  for (final insight in report.insights) {
    if (insight.metric == metric) return insight;
  }
  return null;
}

IconData _sampleMetricIcon(RunningCoachMetric metric) {
  return switch (metric) {
    RunningCoachMetric.posture => Icons.show_chart_rounded,
    RunningCoachMetric.bounce => Icons.swap_vert_rounded,
    RunningCoachMetric.footStrike => Icons.ads_click_rounded,
    RunningCoachMetric.kneeFlexion => Icons.timeline_rounded,
    RunningCoachMetric.armCarriage => Icons.sync_alt_rounded,
  };
}

String _sampleReadoutText(
  AppLocalizations l10n,
  RunningCoachingInsight insight,
) {
  final copy = RunningCoachInsightCopy.fromInsight(insight, l10n);
  return l10n.runningCoachSampleReadoutValue(
    copy.title,
    copy.value,
    copy.statusLabel,
  );
}

List<_SampleDecisionMetric> _sampleDecisionMetrics(
  AppLocalizations l10n,
  RunningCoachingReport report,
) {
  final configs = <({
    RunningCoachMetric metric,
    _SampleDecisionMetricKind kind,
    String label,
  })>[
    (
      metric: RunningCoachMetric.posture,
      kind: _SampleDecisionMetricKind.posture,
      label: l10n.runningCoachSampleMetricPosture,
    ),
    (
      metric: RunningCoachMetric.armCarriage,
      kind: _SampleDecisionMetricKind.arms,
      label: l10n.runningCoachSampleMetricArms,
    ),
    (
      metric: RunningCoachMetric.footStrike,
      kind: _SampleDecisionMetricKind.landing,
      label: l10n.runningCoachSampleMetricLanding,
    ),
    (
      metric: RunningCoachMetric.bounce,
      kind: _SampleDecisionMetricKind.bounce,
      label: l10n.runningCoachSampleMetricBounce,
    ),
  ];

  return [
    for (final config in configs)
      if (_insightForMetric(report, config.metric) case final insight?)
        _sampleDecisionMetricFromInsight(
          l10n,
          insight: insight,
          kind: config.kind,
          label: config.label,
        ),
  ];
}

_SampleDecisionMetric _sampleDecisionMetricFromInsight(
  AppLocalizations l10n, {
  required RunningCoachingInsight insight,
  required _SampleDecisionMetricKind kind,
  required String label,
}) {
  final copy = RunningCoachInsightCopy.fromInsight(insight, l10n);
  return _SampleDecisionMetric(
    kind: kind,
    icon: _sampleMetricIcon(insight.metric),
    label: label,
    value: copy.value,
    status: insight.status,
    statusLabel: copy.statusLabel,
  );
}

class _SampleAnalysisStep {
  final IconData icon;
  final String label;

  const _SampleAnalysisStep({required this.icon, required this.label});
}

class _SampleAnalysisProcessPanel extends StatelessWidget {
  final String title;
  final String body;
  final List<_SampleAnalysisStep> steps;

  const _SampleAnalysisProcessPanel({
    required this.title,
    required this.body,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('running-coach-sample-analysis-process'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.24)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(body, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          Column(
            children: [
              for (var index = 0; index < steps.length; index += 1)
                _SampleAnalysisProcessRow(
                  step: steps[index],
                  index: index,
                  isLast: index == steps.length - 1,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SampleAnalysisProcessRow extends StatelessWidget {
  final _SampleAnalysisStep step;
  final int index;
  final bool isLast;

  const _SampleAnalysisProcessRow({
    required this.step,
    required this.index,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final markerColor = scheme.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            SizedBox.square(
              dimension: 30,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: markerColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: markerColor.withValues(alpha: 0.36),
                  ),
                ),
                child: Icon(step.icon, size: 17, color: markerColor),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 18,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: markerColor.withValues(alpha: 0.20),
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 5, bottom: isLast ? 0 : 14),
            child: Text(
              '${index + 1}. ${step.label}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SampleFrameCue {
  final IconData icon;
  final String text;

  const _SampleFrameCue({required this.icon, required this.text});
}

class _SampleFrameCuePanel extends StatelessWidget {
  final Key panelKey;
  final String title;
  final String body;
  final List<_SampleFrameCue> cues;

  const _SampleFrameCuePanel({
    this.panelKey = const ValueKey('running-coach-sample-frame-guide'),
    required this.title,
    required this.body,
    required this.cues,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: panelKey,
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withAlpha(120),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.secondary.withValues(alpha: 0.22)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(body, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final cue in cues) _SampleFrameCueChip(cue: cue)],
          ),
        ],
      ),
    );
  }
}

class _SampleRecordingGuidePanel extends StatelessWidget {
  final String title;
  final List<String> tips;
  final List<String> steps;

  const _SampleRecordingGuidePanel({
    required this.title,
    required this.tips,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('running-coach-sample-recording-guide'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          for (final tip in tips) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 17,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 2),
          for (var index = 0; index < steps.length; index += 1) ...[
            _SampleGuideStep(number: index + 1, text: steps[index]),
            if (index != steps.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _SampleGuideStep extends StatelessWidget {
  final int number;
  final String text;

  const _SampleGuideStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox.square(
          dimension: 22,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
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

class _SampleFrameCueChip extends StatelessWidget {
  final _SampleFrameCue cue;

  const _SampleFrameCueChip({required this.cue});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxChipWidth = math.max(
      160.0,
      math.min(320.0, MediaQuery.sizeOf(context).width - 72),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxChipWidth),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(cue.icon, size: 16, color: scheme.secondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  cue.text,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SampleVideoFrame extends StatefulWidget {
  final int score;
  final _SampleVideoMode mode;
  final RunningVideoAnalysisResult result;
  final RunningCoachingReport report;

  const _SampleVideoFrame({
    required this.score,
    required this.mode,
    required this.result,
    required this.report,
  });

  @override
  State<_SampleVideoFrame> createState() => _SampleVideoFrameState();
}

class _SampleVideoFrameState extends State<_SampleVideoFrame> {
  VideoPlayerController? _videoController;
  bool _isVideoReady = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  @override
  void didUpdateWidget(covariant _SampleVideoFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      _loadVideo();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _loadVideo() {
    final previousController = _videoController;
    _videoController = null;
    _isVideoReady = false;
    unawaited(previousController?.dispose());

    final asset = widget.mode == _SampleVideoMode.mistake
        ? _sampleMistakeVideoAsset
        : _sampleReferenceVideoAsset;
    final controller = VideoPlayerController.asset(asset);
    _videoController = controller;
    controller.initialize().then((_) async {
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (!mounted || _videoController != controller) return;
      setState(() => _isVideoReady = true);
    }).catchError((Object _) {
      if (!mounted || _videoController != controller) return;
      setState(() => _isVideoReady = false);
    });
  }

  double _sampleProgressFor(VideoPlayerController controller) {
    final value = controller.value;
    if (!value.isInitialized) return 0;
    final durationMs = value.duration.inMilliseconds;
    if (durationMs <= 0) return 0;
    final positionMs = value.position.inMilliseconds % durationMs;
    return (positionMs / durationMs).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isMistake = widget.mode == _SampleVideoMode.mistake;
    final runnerColor = isMistake ? scheme.error : scheme.primary;
    final videoController = _videoController;
    final hasVideo = _isVideoReady &&
        videoController != null &&
        videoController.value.isInitialized;
    final decisionMetrics = _sampleDecisionMetrics(l10n, widget.report);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          key: const ValueKey('running-coach-sample-video-frame'),
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Stack(
                children: [
                  if (hasVideo) ...[
                    Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: videoController.value.size.width,
                          height: videoController.value.size.height,
                          child: VideoPlayer(videoController),
                        ),
                      ),
                    ),
                    if (widget.result.poseFrames.isNotEmpty)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: videoController,
                            builder: (context, _) {
                              final poseFrame = runningPoseFrameAtPosition(
                                frames: widget.result.poseFrames,
                                position: videoController.value.position,
                              );
                              return CustomPaint(
                                key: const ValueKey(
                                  'running-coach-sample-real-pose-overlay',
                                ),
                                painter: _RunningPoseOverlayPainter(
                                  poseFrame: poseFrame,
                                  primaryColor: runnerColor,
                                  secondaryColor: scheme.secondary,
                                  contactColor: scheme.tertiary,
                                  warningColor: scheme.error,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    Positioned(
                      left: 12,
                      right: 12,
                      top: 12,
                      child: AnimatedBuilder(
                        animation: videoController,
                        builder: (context, _) {
                          final position = videoController.value.position;
                          final progress = _sampleProgressFor(videoController);
                          final poseFrames = widget.result.poseFrames;
                          final poseFrameIndex = nearestRunningPoseFrameIndex(
                            frames: poseFrames,
                            position: position,
                          );
                          final contactTimestamp = widget.result
                              .nearestValidatedContactTimestamp(position);
                          final frameNumber = poseFrameIndex == null
                              ? ((progress * _sampleTimelineFrameCount)
                                          .floor() %
                                      _sampleTimelineFrameCount) +
                                  1
                              : poseFrameIndex + 1;
                          final frameCount = poseFrames.isEmpty
                              ? _sampleTimelineFrameCount
                              : poseFrames.length;
                          return Row(
                            children: [
                              Flexible(
                                flex: 3,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _VideoOverlayPill(
                                    text: contactTimestamp != null
                                        ? l10n
                                            .runningCoachSampleContactFrameLabel(
                                            _formatContactTimestamp(
                                              contactTimestamp,
                                            ),
                                          )
                                        : poseFrames.isEmpty
                                            ? l10n
                                                .runningCoachSamplePoseOverlayUnavailable
                                            : l10n.runningCoachSampleFrameLabel(
                                                frameNumber,
                                                frameCount,
                                              ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                flex: 4,
                                child: Center(
                                  child: _VideoOverlayPill(
                                    key: const ValueKey(
                                      'running-coach-sample-analysis-phase',
                                    ),
                                    text: _sampleAnalysisPhaseLabel(
                                      l10n,
                                      result: widget.result,
                                      position: position,
                                      progress: progress,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: _VideoOverlayPill(
                                    text: '${widget.score}',
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 10,
                      child: AnimatedBuilder(
                        animation: videoController,
                        builder: (context, _) => ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: _sampleProgressFor(videoController),
                            minHeight: 4,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.20),
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ] else
                    Center(
                      child: SizedBox.square(
                        dimension: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: runnerColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _SampleDecisionOverlay(
          compact: true,
          score: widget.score,
          title: l10n.runningCoachSampleDecisionTitle,
          scoreLabel: l10n.runningCoachOverallScoreLabel,
          metrics: decisionMetrics,
          onMetricTap: _openMetricDetail,
        ),
      ],
    );
  }

  void _openMetricDetail(_SampleDecisionMetric metric) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _SampleMetricDetailScreen(
          metric: metric,
          mode: widget.mode,
        ),
      ),
    );
  }
}

String _sampleAnalysisPhaseLabel(
  AppLocalizations l10n, {
  required RunningVideoAnalysisResult result,
  required Duration position,
  required double progress,
}) {
  if (result.nearestValidatedContactTimestamp(position) != null) {
    return l10n.runningCoachSamplePhaseDenseContact;
  }
  final phase = (progress * _sampleAnalysisPhaseCount)
      .floor()
      .clamp(0, _sampleAnalysisPhaseCount - 1)
      .toInt();
  return switch (phase) {
    0 => l10n.runningCoachSamplePhaseFrame,
    1 => l10n.runningCoachSamplePhaseJoints,
    2 => l10n.runningCoachSamplePhaseMuscles,
    3 => l10n.runningCoachSamplePhaseSkeleton,
    4 => l10n.runningCoachSamplePhaseAngles,
    _ => l10n.runningCoachSamplePhaseContactScore,
  };
}

String _formatContactTimestamp(Duration timestamp) {
  final seconds = timestamp.inMilliseconds / 1000.0;
  return '${seconds.toStringAsFixed(2)}s';
}

class _SampleDecisionMetric {
  final _SampleDecisionMetricKind kind;
  final IconData icon;
  final String label;
  final String value;
  final RunningCoachStatus status;
  final String statusLabel;

  const _SampleDecisionMetric({
    required this.kind,
    required this.icon,
    required this.label,
    required this.value,
    required this.status,
    required this.statusLabel,
  });

  bool get isPass => status == RunningCoachStatus.good;
}

class _SampleDecisionOverlay extends StatelessWidget {
  final bool compact;
  final int score;
  final String title;
  final String scoreLabel;
  final List<_SampleDecisionMetric> metrics;
  final ValueChanged<_SampleDecisionMetric>? onMetricTap;

  const _SampleDecisionOverlay({
    required this.compact,
    required this.score,
    required this.title,
    required this.scoreLabel,
    required this.metrics,
    this.onMetricTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '$scoreLabel $score',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (compact)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final metric in metrics)
                    _SampleDecisionMetricTile(
                      metric: metric,
                      compact: true,
                      onTap: onMetricTap == null
                          ? null
                          : () => onMetricTap!(metric),
                    ),
                ],
              )
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final metric in metrics)
                    _SampleDecisionMetricTile(
                      metric: metric,
                      compact: false,
                      onTap: onMetricTap == null
                          ? null
                          : () => onMetricTap!(metric),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SampleDecisionMetricTile extends StatelessWidget {
  final _SampleDecisionMetric metric;
  final bool compact;
  final VoidCallback? onTap;

  const _SampleDecisionMetricTile({
    required this.metric,
    required this.compact,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = _statusAccentColor(metric.status);
    final status = metric.statusLabel;
    final borderRadius = BorderRadius.circular(8);
    final tile = Material(
      color: statusColor.withValues(alpha: metric.isPass ? 0.10 : 0.14),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: statusColor.withValues(alpha: 0.42)),
      ),
      child: InkWell(
        key: ValueKey('running-coach-sample-decision-${metric.kind.name}'),
        borderRadius: borderRadius,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 7 : 8,
            vertical: compact ? 6 : 7,
          ),
          child: Row(
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Icon(metric.icon, size: 15, color: statusColor),
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      metric.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    if (compact)
                      Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 8),
                Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    if (compact) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 128, maxWidth: 180),
        child: tile,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: tile,
    );
  }
}

class _SampleMetricDetailScreen extends StatelessWidget {
  final _SampleDecisionMetric metric;
  final _SampleVideoMode mode;

  const _SampleMetricDetailScreen({
    required this.metric,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isMistake = mode == _SampleVideoMode.mistake;
    final sampleLabel = isMistake
        ? l10n.runningCoachSampleMistakeTab
        : l10n.runningCoachSampleReferenceTab;
    final status = metric.statusLabel;
    final detail = _SampleMetricDetailCopy.forKind(l10n, metric.kind);
    return Scaffold(
      key: const ValueKey('running-coach-sample-metric-detail'),
      appBar: AppBar(title: Text(metric.label)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.runningCoachSampleMetricDetailScreenTitle,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.runningCoachSampleMetricDetailHeroBody,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          _SampleMetricDetailVisual(
            kind: metric.kind,
            isMistake: isMistake,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatChip(
                label: l10n.runningCoachSampleMetricDetailSampleLabel,
                value: sampleLabel,
              ),
              _StatChip(
                label: l10n.runningCoachSampleMetricDetailValueLabel,
                value: metric.value,
              ),
              _StatChip(
                label: l10n.runningCoachSampleMetricDetailStatusLabel,
                value: status,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SampleMetricDetailSection(
            icon: Icons.rule_rounded,
            title: l10n.runningCoachSampleMetricDetailGoodRangeTitle,
            body: detail.goodRange,
          ),
          const SizedBox(height: 10),
          _SampleMetricDetailSection(
            icon: Icons.center_focus_strong_rounded,
            title: l10n.runningCoachSampleMetricDetailKeyPositionTitle,
            body: detail.keyPosition,
          ),
          const SizedBox(height: 10),
          _SampleMetricDetailSection(
            icon: Icons.check_circle_outline_rounded,
            title: l10n.runningCoachSampleMetricDetailReferenceTitle,
            body: detail.referenceMotion,
          ),
          const SizedBox(height: 10),
          _SampleMetricDetailSection(
            icon: Icons.report_problem_outlined,
            title: l10n.runningCoachSampleMetricDetailReviewTitle,
            body: detail.reviewTrigger,
          ),
          const SizedBox(height: 10),
          _SampleMetricDetailSection(
            icon: Icons.polyline_outlined,
            title: l10n.runningCoachSampleMetricDetailHowReadTitle,
            body: detail.howRead,
          ),
        ],
      ),
    );
  }
}

class _SampleMetricDetailCopy {
  final String goodRange;
  final String keyPosition;
  final String referenceMotion;
  final String reviewTrigger;
  final String howRead;

  const _SampleMetricDetailCopy({
    required this.goodRange,
    required this.keyPosition,
    required this.referenceMotion,
    required this.reviewTrigger,
    required this.howRead,
  });

  factory _SampleMetricDetailCopy.forKind(
    AppLocalizations l10n,
    _SampleDecisionMetricKind kind,
  ) {
    return switch (kind) {
      _SampleDecisionMetricKind.posture => _SampleMetricDetailCopy(
          goodRange: l10n.runningCoachSamplePostureDetailGoodRange,
          keyPosition: l10n.runningCoachSamplePostureDetailKeyPosition,
          referenceMotion: l10n.runningCoachSamplePostureDetailReference,
          reviewTrigger: l10n.runningCoachSamplePostureDetailReview,
          howRead: l10n.runningCoachSamplePostureDetailHowRead,
        ),
      _SampleDecisionMetricKind.arms => _SampleMetricDetailCopy(
          goodRange: l10n.runningCoachSampleArmsDetailGoodRange,
          keyPosition: l10n.runningCoachSampleArmsDetailKeyPosition,
          referenceMotion: l10n.runningCoachSampleArmsDetailReference,
          reviewTrigger: l10n.runningCoachSampleArmsDetailReview,
          howRead: l10n.runningCoachSampleArmsDetailHowRead,
        ),
      _SampleDecisionMetricKind.landing => _SampleMetricDetailCopy(
          goodRange: l10n.runningCoachSampleLandingDetailGoodRange,
          keyPosition: l10n.runningCoachSampleLandingDetailKeyPosition,
          referenceMotion: l10n.runningCoachSampleLandingDetailReference,
          reviewTrigger: l10n.runningCoachSampleLandingDetailReview,
          howRead: l10n.runningCoachSampleLandingDetailHowRead,
        ),
      _SampleDecisionMetricKind.bounce => _SampleMetricDetailCopy(
          goodRange: l10n.runningCoachSampleBounceDetailGoodRange,
          keyPosition: l10n.runningCoachSampleBounceDetailKeyPosition,
          referenceMotion: l10n.runningCoachSampleBounceDetailReference,
          reviewTrigger: l10n.runningCoachSampleBounceDetailReview,
          howRead: l10n.runningCoachSampleBounceDetailHowRead,
        ),
    };
  }
}

class _SampleMetricDetailSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _SampleMetricDetailSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(body, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SampleMetricDetailVisual extends StatelessWidget {
  final _SampleDecisionMetricKind kind;
  final bool isMistake;

  const _SampleMetricDetailVisual({
    required this.kind,
    required this.isMistake,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final highlight = isMistake ? scheme.error : scheme.primary;
    return AspectRatio(
      key: const ValueKey('running-coach-sample-metric-detail-visual'),
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: CustomPaint(
            painter: _SampleMetricDetailPainter(
              kind: kind,
              isMistake: isMistake,
              baseColor: scheme.onSurfaceVariant,
              highlightColor: highlight,
              secondaryColor: scheme.secondary,
              contactColor: scheme.tertiary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SampleMetricDetailPainter extends CustomPainter {
  final _SampleDecisionMetricKind kind;
  final bool isMistake;
  final Color baseColor;
  final Color highlightColor;
  final Color secondaryColor;
  final Color contactColor;

  const _SampleMetricDetailPainter({
    required this.kind,
    required this.isMistake,
    required this.baseColor,
    required this.highlightColor,
    required this.secondaryColor,
    required this.contactColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final progress = switch (kind) {
      _SampleDecisionMetricKind.posture => 0.16,
      _SampleDecisionMetricKind.arms => 0.32,
      _SampleDecisionMetricKind.landing => 0.54,
      _SampleDecisionMetricKind.bounce => 0.74,
    };
    final runner = _SampleVideoRunnerGeometry(
      size,
      progress,
      isMistake: isMistake,
    );
    _drawGround(canvas, runner);
    _drawRunner(canvas, runner);
    switch (kind) {
      case _SampleDecisionMetricKind.posture:
        _drawPostureRead(canvas, runner);
        break;
      case _SampleDecisionMetricKind.arms:
        _drawArmRead(canvas, runner);
        break;
      case _SampleDecisionMetricKind.landing:
        _drawLandingRead(canvas, runner);
        break;
      case _SampleDecisionMetricKind.bounce:
        _drawBounceRead(canvas, runner);
        break;
    }
  }

  void _drawGround(Canvas canvas, _SampleVideoRunnerGeometry runner) {
    canvas.drawLine(
      Offset(runner.size.width * 0.08, runner.groundY),
      Offset(runner.size.width * 0.92, runner.groundY),
      Paint()
        ..color = baseColor.withValues(alpha: 0.22)
        ..strokeWidth = math.max(1.0, runner.scale * 0.008)
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawRunner(Canvas canvas, _SampleVideoRunnerGeometry runner) {
    final bonePaint = Paint()
      ..color = baseColor.withValues(alpha: 0.34)
      ..strokeWidth = math.max(2.0, runner.scale * 0.010)
      ..strokeCap = StrokeCap.round;
    for (final bone in runner.bones) {
      canvas.drawLine(bone.$1, bone.$2, bonePaint);
    }
    canvas.drawLine(runner.neck, runner.hip, bonePaint);
    canvas.drawCircle(
      runner.head,
      runner.scale * 0.038,
      Paint()
        ..color = baseColor.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill,
    );
    for (final joint in runner.joints) {
      canvas.drawCircle(
        joint,
        runner.scale * 0.008,
        Paint()..color = baseColor.withValues(alpha: 0.48),
      );
    }
  }

  void _drawPostureRead(Canvas canvas, _SampleVideoRunnerGeometry runner) {
    final readPaint = Paint()
      ..color = highlightColor.withValues(alpha: 0.82)
      ..strokeWidth = math.max(2.0, runner.scale * 0.012)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(runner.hip, runner.shoulderMid, readPaint);
    canvas.drawLine(
      runner.hip,
      runner.postureVerticalTop,
      readPaint..color = highlightColor.withValues(alpha: 0.42),
    );
    _drawAngleArc(
      canvas,
      center: runner.hip,
      start: runner.postureVerticalTop,
      end: runner.shoulderMid,
      radius: runner.scale * 0.090,
      color: highlightColor.withValues(alpha: 0.88),
      strokeWidth: runner.scale * 0.012,
    );
    _drawHalo(canvas, runner.shoulderMid, runner.scale * 0.060);
    _drawHalo(canvas, runner.hip, runner.scale * 0.066);
  }

  void _drawArmRead(Canvas canvas, _SampleVideoRunnerGeometry runner) {
    final armPaint = Paint()
      ..color = highlightColor.withValues(alpha: 0.78)
      ..strokeWidth = math.max(3.0, runner.scale * 0.018)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(runner.frontShoulder, runner.frontElbow, armPaint);
    canvas.drawLine(runner.frontElbow, runner.frontWrist, armPaint);
    canvas.drawLine(
      runner.rearShoulder,
      runner.rearElbow,
      armPaint..color = secondaryColor.withValues(alpha: 0.70),
    );
    canvas.drawLine(runner.rearElbow, runner.rearWrist, armPaint);
    _drawAngleArc(
      canvas,
      center: runner.frontElbow,
      start: runner.frontShoulder,
      end: runner.frontWrist,
      radius: runner.scale * 0.060,
      color: highlightColor.withValues(alpha: 0.88),
      strokeWidth: runner.scale * 0.010,
    );
    _drawAngleArc(
      canvas,
      center: runner.rearElbow,
      start: runner.rearShoulder,
      end: runner.rearWrist,
      radius: runner.scale * 0.052,
      color: secondaryColor.withValues(alpha: 0.76),
      strokeWidth: runner.scale * 0.009,
    );
    _drawHalo(canvas, runner.frontElbow, runner.scale * 0.056);
    _drawHalo(canvas, runner.rearElbow, runner.scale * 0.050);
  }

  void _drawLandingRead(Canvas canvas, _SampleVideoRunnerGeometry runner) {
    final readColor = isMistake ? highlightColor : contactColor;
    final hipFootStart = Offset(
      runner.hip.dx,
      runner.groundY + runner.scale * 0.028,
    );
    final hipFootEnd = Offset(
      runner.contactAnkle.dx,
      runner.groundY + runner.scale * 0.028,
    );
    canvas.drawLine(
      Offset(runner.hip.dx, runner.hip.dy),
      Offset(runner.hip.dx, runner.groundY),
      Paint()
        ..color = readColor.withValues(alpha: 0.52)
        ..strokeWidth = math.max(1.5, runner.scale * 0.008)
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center:
            Offset(runner.contactToe.dx - runner.scale * 0.030, runner.groundY),
        width: runner.scale * 0.170,
        height: runner.scale * 0.046,
      ),
      Paint()..color = readColor.withValues(alpha: 0.22),
    );
    _drawBracket(canvas, hipFootStart, hipFootEnd, readColor);
    _drawArrow(
      canvas,
      Offset(runner.contactToe.dx, runner.groundY - runner.scale * 0.010),
      Offset(runner.hip.dx, runner.hip.dy + runner.scale * 0.030),
      readColor.withValues(alpha: 0.82),
      runner.scale * 0.012,
    );
    _drawHalo(canvas, runner.contactAnkle, runner.scale * 0.056);
    _drawHalo(canvas, runner.hip, runner.scale * 0.060);
  }

  void _drawBounceRead(Canvas canvas, _SampleVideoRunnerGeometry runner) {
    final top = runner.head.dy - runner.scale * 0.020;
    final bottom = runner.head.dy + runner.scale * (isMistake ? 0.130 : 0.088);
    final left = runner.head.dx - runner.scale * 0.180;
    final right = runner.head.dx + runner.scale * 0.200;
    final guidePaint = Paint()
      ..color = highlightColor.withValues(alpha: 0.50)
      ..strokeWidth = math.max(1.0, runner.scale * 0.007)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(left, top), Offset(right, top), guidePaint);
    canvas.drawLine(Offset(left, bottom), Offset(right, bottom), guidePaint);
    _drawDoubleArrow(
      canvas,
      Offset(right - runner.scale * 0.030, top),
      Offset(right - runner.scale * 0.030, bottom),
      highlightColor.withValues(alpha: 0.82),
      runner.scale * 0.010,
    );
    final hipBandTop = runner.hip.dy - runner.scale * 0.032;
    final hipBandBottom = runner.hip.dy + runner.scale * 0.032;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          runner.hip.dx - runner.scale * 0.115,
          hipBandTop,
          runner.hip.dx + runner.scale * 0.115,
          hipBandBottom,
        ),
        Radius.circular(runner.scale * 0.016),
      ),
      Paint()
        ..color = contactColor.withValues(alpha: 0.16)
        ..style = PaintingStyle.fill,
    );
    _drawHalo(canvas, runner.head, runner.scale * 0.060);
    _drawHalo(canvas, runner.hip, runner.scale * 0.064);
  }

  void _drawHalo(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = highlightColor.withValues(alpha: 0.10)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = highlightColor.withValues(alpha: 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, radius * 0.10),
    );
  }

  void _drawBracket(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
  ) {
    final height = math.max(7.0, (end - start).distance * 0.16);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.78)
      ..strokeWidth = math.max(1.2, height * 0.20)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, paint);
    canvas.drawLine(Offset(start.dx, start.dy - height),
        Offset(start.dx, start.dy + height), paint);
    canvas.drawLine(Offset(end.dx, end.dy - height),
        Offset(end.dx, end.dy + height), paint);
  }

  void _drawDoubleArrow(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
    double strokeWidth,
  ) {
    _drawArrow(canvas, start, end, color, strokeWidth);
    _drawArrow(canvas, end, start, color, strokeWidth);
  }

  void _drawArrow(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
    double strokeWidth,
  ) {
    final delta = end - start;
    final distance = delta.distance;
    if (distance == 0) return;
    final direction = delta / distance;
    final normal = Offset(-direction.dy, direction.dx);
    final headLength = math.max(5.0, strokeWidth * 4.0);
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawLine(start, end, paint);
    canvas.drawLine(
      end,
      end - direction * headLength + normal * headLength * 0.52,
      paint,
    );
    canvas.drawLine(
      end,
      end - direction * headLength - normal * headLength * 0.52,
      paint,
    );
  }

  void _drawAngleArc(
    Canvas canvas, {
    required Offset center,
    required Offset start,
    required Offset end,
    required double radius,
    required Color color,
    required double strokeWidth,
  }) {
    final startAngle = math.atan2(start.dy - center.dy, start.dx - center.dx);
    final endAngle = math.atan2(end.dy - center.dy, end.dx - center.dx);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      _shortestAngleSweep(startAngle, endAngle),
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  double _shortestAngleSweep(double start, double end) {
    var sweep = (end - start) % (math.pi * 2);
    if (sweep > math.pi) sweep -= math.pi * 2;
    if (sweep < -math.pi) sweep += math.pi * 2;
    return sweep;
  }

  @override
  bool shouldRepaint(covariant _SampleMetricDetailPainter oldDelegate) {
    return oldDelegate.kind != kind ||
        oldDelegate.isMistake != isMistake ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.highlightColor != highlightColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.contactColor != contactColor;
  }
}

class _VideoOverlayPill extends StatelessWidget {
  final String text;

  const _VideoOverlayPill({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
    );
  }
}

class _RunningPoseOverlayPainter extends CustomPainter {
  final RunningPoseFrame? poseFrame;
  final Color primaryColor;
  final Color secondaryColor;
  final Color contactColor;
  final Color warningColor;

  const _RunningPoseOverlayPainter({
    required this.poseFrame,
    required this.primaryColor,
    required this.secondaryColor,
    required this.contactColor,
    required this.warningColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final frame = poseFrame;
    if (frame == null) return;

    for (final connection in _mediaPipePoseConnections) {
      _drawConnection(canvas, size, frame, connection);
    }
    for (final landmark in frame.landmarks) {
      _drawLandmark(canvas, size, frame, landmark);
    }
  }

  void _drawConnection(
    Canvas canvas,
    Size size,
    RunningPoseFrame frame,
    _PoseConnection connection,
  ) {
    final first = frame.landmarkByIndex(connection.first);
    final second = frame.landmarkByIndex(connection.second);
    if (first == null || second == null) return;
    final confidence = math.min(first.confidence, second.confidence);
    if (confidence < runningPoseOverlayMinimumConnectionConfidence) return;

    final confidenceT =
        ((confidence - runningPoseOverlayMinimumConnectionConfidence) /
                (1.0 - runningPoseOverlayMinimumConnectionConfidence))
            .clamp(0.0, 1.0)
            .toDouble();
    final alpha = _sampleLerpDouble(0.24, 0.86, confidenceT);
    final width = switch (connection.kind) {
      _PoseConnectionKind.face => size.shortestSide * 0.0048,
      _PoseConnectionKind.hand ||
      _PoseConnectionKind.foot =>
        size.shortestSide * 0.0054,
      _PoseConnectionKind.torso => size.shortestSide * 0.0074,
      _ => size.shortestSide * 0.0064,
    };
    final color = switch (connection.kind) {
      _PoseConnectionKind.face => secondaryColor,
      _PoseConnectionKind.arm || _PoseConnectionKind.hand => secondaryColor,
      _PoseConnectionKind.torso => primaryColor,
      _PoseConnectionKind.leg || _PoseConnectionKind.foot => contactColor,
    };

    canvas.drawLine(
      _coverPoint(size, frame, first),
      _coverPoint(size, frame, second),
      Paint()
        ..color = color.withValues(alpha: alpha)
        ..strokeWidth = math.max(1.1, width)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawLandmark(
    Canvas canvas,
    Size size,
    RunningPoseFrame frame,
    RunningVideoPoseLandmark landmark,
  ) {
    if (landmark.confidence < runningPoseOverlayMinimumJointConfidence) {
      return;
    }
    final confidenceT =
        ((landmark.confidence - runningPoseOverlayMinimumJointConfidence) /
                (1.0 - runningPoseOverlayMinimumJointConfidence))
            .clamp(0.0, 1.0)
            .toDouble();
    final center = _coverPoint(size, frame, landmark);
    final radius = _jointRadius(size, landmark.index);
    final alpha = _sampleLerpDouble(0.22, 0.92, confidenceT);
    final color = _jointColor(landmark.index);
    canvas.drawCircle(
      center,
      radius * 1.62,
      Paint()..color = Colors.black.withValues(alpha: 0.18 * alpha),
    );
    canvas.drawCircle(
      center,
      radius * 1.18,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.54 * alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, radius * 0.34),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = color.withValues(alpha: alpha),
    );
    if (landmark.confidence < 0.45) {
      canvas.drawCircle(
        center,
        radius * 1.55,
        Paint()
          ..color = warningColor.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, radius * 0.28),
      );
    }
  }

  Offset _coverPoint(
    Size size,
    RunningPoseFrame frame,
    RunningVideoPoseLandmark landmark,
  ) {
    return runningPoseCoverOffset(
      landmark: landmark,
      imageWidth: frame.imageWidth,
      imageHeight: frame.imageHeight,
      outputSize: size,
    );
  }

  Color _jointColor(int index) {
    if (index <= 10) return secondaryColor;
    if (index >= 23) return contactColor;
    return primaryColor;
  }

  double _jointRadius(Size size, int index) {
    final base = size.shortestSide;
    if (index <= 10 || index >= 17 && index <= 22) {
      return math.max(2.0, base * 0.0060);
    }
    return math.max(2.4, base * 0.0072);
  }

  @override
  bool shouldRepaint(covariant _RunningPoseOverlayPainter oldDelegate) {
    return oldDelegate.poseFrame != poseFrame ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.contactColor != contactColor ||
        oldDelegate.warningColor != warningColor;
  }
}

enum _PoseConnectionKind { face, arm, hand, torso, leg, foot }

class _PoseConnection {
  final int first;
  final int second;
  final _PoseConnectionKind kind;

  const _PoseConnection(this.first, this.second, this.kind);
}

const _mediaPipePoseConnections = <_PoseConnection>[
  _PoseConnection(0, 2, _PoseConnectionKind.face),
  _PoseConnection(0, 5, _PoseConnectionKind.face),
  _PoseConnection(2, 7, _PoseConnectionKind.face),
  _PoseConnection(5, 8, _PoseConnectionKind.face),
  _PoseConnection(9, 10, _PoseConnectionKind.face),
  _PoseConnection(11, 12, _PoseConnectionKind.torso),
  _PoseConnection(11, 23, _PoseConnectionKind.torso),
  _PoseConnection(12, 24, _PoseConnectionKind.torso),
  _PoseConnection(23, 24, _PoseConnectionKind.torso),
  _PoseConnection(11, 13, _PoseConnectionKind.arm),
  _PoseConnection(13, 15, _PoseConnectionKind.arm),
  _PoseConnection(15, 17, _PoseConnectionKind.hand),
  _PoseConnection(15, 19, _PoseConnectionKind.hand),
  _PoseConnection(15, 21, _PoseConnectionKind.hand),
  _PoseConnection(17, 19, _PoseConnectionKind.hand),
  _PoseConnection(12, 14, _PoseConnectionKind.arm),
  _PoseConnection(14, 16, _PoseConnectionKind.arm),
  _PoseConnection(16, 18, _PoseConnectionKind.hand),
  _PoseConnection(16, 20, _PoseConnectionKind.hand),
  _PoseConnection(16, 22, _PoseConnectionKind.hand),
  _PoseConnection(18, 20, _PoseConnectionKind.hand),
  _PoseConnection(23, 25, _PoseConnectionKind.leg),
  _PoseConnection(25, 27, _PoseConnectionKind.leg),
  _PoseConnection(27, 29, _PoseConnectionKind.foot),
  _PoseConnection(29, 31, _PoseConnectionKind.foot),
  _PoseConnection(27, 31, _PoseConnectionKind.foot),
  _PoseConnection(24, 26, _PoseConnectionKind.leg),
  _PoseConnection(26, 28, _PoseConnectionKind.leg),
  _PoseConnection(28, 30, _PoseConnectionKind.foot),
  _PoseConnection(30, 32, _PoseConnectionKind.foot),
  _PoseConnection(28, 32, _PoseConnectionKind.foot),
];

double _sampleLerpDouble(double a, double b, double t) => a + ((b - a) * t);

class _SampleVideoRunnerGeometry {
  final Size size;
  final double progress;
  final _SampleVideoPoseKeyframe _pose;

  _SampleVideoRunnerGeometry(
    this.size,
    this.progress, {
    required bool isMistake,
  }) : _pose = _SampleVideoPoseKeyframe.at(
          progress,
          isMistake: isMistake,
        );

  double get scale => size.height;

  double get groundY => size.height * _pose.groundY;

  Offset p(Offset point) =>
      Offset(size.width * point.dx, size.height * point.dy);

  Offset get head => p(_pose.head);
  Offset get neck => p(_pose.neck);
  Offset get rearShoulder => p(_pose.rearShoulder);
  Offset get frontShoulder => p(_pose.frontShoulder);
  Offset get rearElbow => p(_pose.rearElbow);
  Offset get rearWrist => _oppositeArmWrist(
        elbow: rearElbow,
        rawWrist: p(_pose.rearWrist),
        swingsForward: false,
      );
  Offset get frontElbow => p(_pose.frontElbow);
  Offset get frontWrist => _oppositeArmWrist(
        elbow: frontElbow,
        rawWrist: p(_pose.frontWrist),
        swingsForward: true,
      );
  Offset get rearHip => p(_pose.rearHip);
  Offset get frontHip => p(_pose.frontHip);
  Offset get rearKnee => p(_pose.rearKnee);
  Offset get rearAnkle => p(_pose.rearAnkle);
  Offset get rearToe => _forwardToe(ankle: rearAnkle, rawToe: p(_pose.rearToe));
  Offset get frontKnee => p(_pose.frontKnee);
  Offset get frontAnkle => p(_pose.frontAnkle);
  Offset get frontToe =>
      _forwardToe(ankle: frontAnkle, rawToe: p(_pose.frontToe));

  Offset get shoulderMid => Offset.lerp(rearShoulder, frontShoulder, 0.5)!;
  Offset get hip => Offset.lerp(rearHip, frontHip, 0.5)!;
  Offset get postureVerticalTop => Offset(hip.dx, hip.dy - scale * 0.28);
  bool get _frontLegIsContact => frontToe.dy >= rearToe.dy;
  Offset get contactHip => _frontLegIsContact ? frontHip : rearHip;
  Offset get contactKnee => _frontLegIsContact ? frontKnee : rearKnee;
  Offset get contactAnkle => _frontLegIsContact ? frontAnkle : rearAnkle;
  Offset get contactToe => _frontLegIsContact ? frontToe : rearToe;
  Offset get swingHip => _frontLegIsContact ? rearHip : frontHip;
  Offset get swingKnee => _frontLegIsContact ? rearKnee : frontKnee;
  Offset get swingAnkle => _frontLegIsContact ? rearAnkle : frontAnkle;
  Offset get ankleLine => contactAnkle;

  Rect get bounds {
    final trackedPoints = <Offset>[
      ...joints,
      rearToe,
      frontToe,
    ];
    var left = trackedPoints.first.dx;
    var top = trackedPoints.first.dy;
    var right = trackedPoints.first.dx;
    var bottom = trackedPoints.first.dy;
    for (final point in trackedPoints.skip(1)) {
      left = math.min(left, point.dx);
      top = math.min(top, point.dy);
      right = math.max(right, point.dx);
      bottom = math.max(bottom, point.dy);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  List<Offset> get joints => [
        head,
        neck,
        rearShoulder,
        frontShoulder,
        rearElbow,
        rearWrist,
        frontElbow,
        frontWrist,
        shoulderMid,
        rearHip,
        frontHip,
        hip,
        rearKnee,
        rearAnkle,
        rearToe,
        frontKnee,
        frontAnkle,
        frontToe,
      ];

  List<(Offset, Offset)> get bones => [
        (rearShoulder, frontShoulder),
        (rearHip, frontHip),
        (rearShoulder, rearElbow),
        (rearElbow, rearWrist),
        (frontShoulder, frontElbow),
        (frontElbow, frontWrist),
        (rearHip, rearKnee),
        (rearKnee, rearAnkle),
        (rearAnkle, rearToe),
        (frontHip, frontKnee),
        (frontKnee, frontAnkle),
        (frontAnkle, frontToe),
      ];

  Offset _forwardToe({required Offset ankle, required Offset rawToe}) {
    final forwardDx = (rawToe.dx - ankle.dx)
        .abs()
        .clamp(size.width * 0.018, size.width * 0.070)
        .toDouble();
    return Offset(ankle.dx + forwardDx, rawToe.dy);
  }

  Offset _oppositeArmWrist({
    required Offset elbow,
    required Offset rawWrist,
    required bool swingsForward,
  }) {
    final wristDx = (rawWrist.dx - elbow.dx)
        .abs()
        .clamp(size.width * 0.020, size.width * 0.085)
        .toDouble();
    final resolvedX = swingsForward ? elbow.dx + wristDx : elbow.dx - wristDx;
    return Offset(resolvedX, rawWrist.dy);
  }
}

class _SampleVideoPoseKeyframe {
  final double time;
  final Offset head;
  final Offset neck;
  final Offset rearShoulder;
  final Offset frontShoulder;
  final Offset rearElbow;
  final Offset rearWrist;
  final Offset frontElbow;
  final Offset frontWrist;
  final Offset rearHip;
  final Offset frontHip;
  final Offset rearKnee;
  final Offset rearAnkle;
  final Offset rearToe;
  final Offset frontKnee;
  final Offset frontAnkle;
  final Offset frontToe;
  final double groundY;

  const _SampleVideoPoseKeyframe({
    required this.time,
    required this.head,
    required this.neck,
    required this.rearShoulder,
    required this.frontShoulder,
    required this.rearElbow,
    required this.rearWrist,
    required this.frontElbow,
    required this.frontWrist,
    required this.rearHip,
    required this.frontHip,
    required this.rearKnee,
    required this.rearAnkle,
    required this.rearToe,
    required this.frontKnee,
    required this.frontAnkle,
    required this.frontToe,
    required this.groundY,
  });

  static const _referenceClipKeyframes = <_SampleVideoPoseKeyframe>[
    _SampleVideoPoseKeyframe(
      time: 0.000,
      head: Offset(0.527, 0.365),
      neck: Offset(0.512, 0.435),
      rearShoulder: Offset(0.484, 0.480),
      frontShoulder: Offset(0.536, 0.470),
      rearElbow: Offset(0.480, 0.575),
      rearWrist: Offset(0.530, 0.585),
      frontElbow: Offset(0.560, 0.570),
      frontWrist: Offset(0.584, 0.570),
      rearHip: Offset(0.498, 0.672),
      frontHip: Offset(0.548, 0.675),
      rearKnee: Offset(0.475, 0.760),
      rearAnkle: Offset(0.410, 0.815),
      rearToe: Offset(0.384, 0.800),
      frontKnee: Offset(0.560, 0.790),
      frontAnkle: Offset(0.570, 0.965),
      frontToe: Offset(0.585, 0.975),
      groundY: 0.965,
    ),
    _SampleVideoPoseKeyframe(
      time: 0.120,
      head: Offset(0.540, 0.360),
      neck: Offset(0.526, 0.440),
      rearShoulder: Offset(0.490, 0.493),
      frontShoulder: Offset(0.552, 0.488),
      rearElbow: Offset(0.482, 0.565),
      rearWrist: Offset(0.540, 0.575),
      frontElbow: Offset(0.585, 0.520),
      frontWrist: Offset(0.606, 0.495),
      rearHip: Offset(0.505, 0.638),
      frontHip: Offset(0.565, 0.638),
      rearKnee: Offset(0.475, 0.780),
      rearAnkle: Offset(0.430, 0.930),
      rearToe: Offset(0.420, 0.905),
      frontKnee: Offset(0.610, 0.750),
      frontAnkle: Offset(0.540, 0.870),
      frontToe: Offset(0.520, 0.855),
      groundY: 0.915,
    ),
    _SampleVideoPoseKeyframe(
      time: 0.250,
      head: Offset(0.500, 0.465),
      neck: Offset(0.490, 0.540),
      rearShoulder: Offset(0.460, 0.560),
      frontShoulder: Offset(0.515, 0.555),
      rearElbow: Offset(0.452, 0.635),
      rearWrist: Offset(0.480, 0.635),
      frontElbow: Offset(0.530, 0.610),
      frontWrist: Offset(0.555, 0.630),
      rearHip: Offset(0.475, 0.735),
      frontHip: Offset(0.515, 0.735),
      rearKnee: Offset(0.455, 0.820),
      rearAnkle: Offset(0.400, 0.815),
      rearToe: Offset(0.380, 0.815),
      frontKnee: Offset(0.530, 0.815),
      frontAnkle: Offset(0.545, 0.990),
      frontToe: Offset(0.550, 0.998),
      groundY: 0.990,
    ),
    _SampleVideoPoseKeyframe(
      time: 0.370,
      head: Offset(0.438, 0.405),
      neck: Offset(0.425, 0.492),
      rearShoulder: Offset(0.395, 0.525),
      frontShoulder: Offset(0.450, 0.520),
      rearElbow: Offset(0.380, 0.585),
      rearWrist: Offset(0.420, 0.640),
      frontElbow: Offset(0.485, 0.535),
      frontWrist: Offset(0.505, 0.520),
      rearHip: Offset(0.395, 0.678),
      frontHip: Offset(0.445, 0.678),
      rearKnee: Offset(0.345, 0.800),
      rearAnkle: Offset(0.305, 0.970),
      rearToe: Offset(0.300, 0.985),
      frontKnee: Offset(0.490, 0.760),
      frontAnkle: Offset(0.430, 0.865),
      frontToe: Offset(0.415, 0.890),
      groundY: 0.968,
    ),
    _SampleVideoPoseKeyframe(
      time: 0.500,
      head: Offset(0.428, 0.360),
      neck: Offset(0.416, 0.448),
      rearShoulder: Offset(0.378, 0.475),
      frontShoulder: Offset(0.440, 0.475),
      rearElbow: Offset(0.350, 0.510),
      rearWrist: Offset(0.420, 0.520),
      frontElbow: Offset(0.468, 0.500),
      frontWrist: Offset(0.485, 0.485),
      rearHip: Offset(0.390, 0.630),
      frontHip: Offset(0.440, 0.632),
      rearKnee: Offset(0.400, 0.755),
      rearAnkle: Offset(0.305, 0.680),
      rearToe: Offset(0.260, 0.670),
      frontKnee: Offset(0.440, 0.765),
      frontAnkle: Offset(0.470, 0.905),
      frontToe: Offset(0.498, 0.900),
      groundY: 0.905,
    ),
    _SampleVideoPoseKeyframe(
      time: 0.620,
      head: Offset(0.440, 0.350),
      neck: Offset(0.430, 0.440),
      rearShoulder: Offset(0.390, 0.470),
      frontShoulder: Offset(0.452, 0.468),
      rearElbow: Offset(0.385, 0.535),
      rearWrist: Offset(0.440, 0.520),
      frontElbow: Offset(0.478, 0.485),
      frontWrist: Offset(0.500, 0.440),
      rearHip: Offset(0.400, 0.620),
      frontHip: Offset(0.450, 0.620),
      rearKnee: Offset(0.360, 0.780),
      rearAnkle: Offset(0.335, 0.910),
      rearToe: Offset(0.318, 0.900),
      frontKnee: Offset(0.480, 0.695),
      frontAnkle: Offset(0.395, 0.765),
      frontToe: Offset(0.385, 0.795),
      groundY: 0.900,
    ),
    _SampleVideoPoseKeyframe(
      time: 0.750,
      head: Offset(0.465, 0.320),
      neck: Offset(0.455, 0.420),
      rearShoulder: Offset(0.420, 0.450),
      frontShoulder: Offset(0.480, 0.450),
      rearElbow: Offset(0.395, 0.525),
      rearWrist: Offset(0.430, 0.548),
      frontElbow: Offset(0.500, 0.440),
      frontWrist: Offset(0.520, 0.410),
      rearHip: Offset(0.425, 0.610),
      frontHip: Offset(0.480, 0.610),
      rearKnee: Offset(0.395, 0.695),
      rearAnkle: Offset(0.280, 0.720),
      rearToe: Offset(0.260, 0.740),
      frontKnee: Offset(0.515, 0.755),
      frontAnkle: Offset(0.535, 0.885),
      frontToe: Offset(0.575, 0.865),
      groundY: 0.865,
    ),
    _SampleVideoPoseKeyframe(
      time: 0.870,
      head: Offset(0.480, 0.360),
      neck: Offset(0.470, 0.455),
      rearShoulder: Offset(0.435, 0.485),
      frontShoulder: Offset(0.495, 0.485),
      rearElbow: Offset(0.425, 0.560),
      rearWrist: Offset(0.482, 0.590),
      frontElbow: Offset(0.520, 0.515),
      frontWrist: Offset(0.555, 0.500),
      rearHip: Offset(0.445, 0.625),
      frontHip: Offset(0.495, 0.625),
      rearKnee: Offset(0.430, 0.780),
      rearAnkle: Offset(0.405, 0.760),
      rearToe: Offset(0.370, 0.720),
      frontKnee: Offset(0.510, 0.755),
      frontAnkle: Offset(0.425, 0.910),
      frontToe: Offset(0.430, 0.955),
      groundY: 0.940,
    ),
    _SampleVideoPoseKeyframe(
      time: 1.000,
      head: Offset(0.520, 0.250),
      neck: Offset(0.505, 0.350),
      rearShoulder: Offset(0.458, 0.382),
      frontShoulder: Offset(0.525, 0.375),
      rearElbow: Offset(0.420, 0.430),
      rearWrist: Offset(0.500, 0.450),
      frontElbow: Offset(0.560, 0.375),
      frontWrist: Offset(0.580, 0.335),
      rearHip: Offset(0.460, 0.555),
      frontHip: Offset(0.520, 0.555),
      rearKnee: Offset(0.410, 0.690),
      rearAnkle: Offset(0.320, 0.745),
      rearToe: Offset(0.310, 0.790),
      frontKnee: Offset(0.575, 0.675),
      frontAnkle: Offset(0.555, 0.850),
      frontToe: Offset(0.605, 0.840),
      groundY: 0.845,
    ),
  ];

  static const _mistakeClipKeyframes = <_SampleVideoPoseKeyframe>[
    _SampleVideoPoseKeyframe(
      time: 0.000,
      head: Offset(0.253, 0.196),
      neck: Offset(0.209, 0.257),
      rearShoulder: Offset(0.213, 0.255),
      frontShoulder: Offset(0.204, 0.259),
      rearElbow: Offset(0.189, 0.342),
      rearWrist: Offset(0.188, 0.430),
      frontElbow: Offset(0.195, 0.359),
      frontWrist: Offset(0.244, 0.353),
      rearHip: Offset(0.191, 0.447),
      frontHip: Offset(0.177, 0.448),
      rearKnee: Offset(0.219, 0.547),
      rearAnkle: Offset(0.147, 0.540),
      rearToe: Offset(0.133, 0.597),
      frontKnee: Offset(0.188, 0.563),
      frontAnkle: Offset(0.154, 0.681),
      frontToe: Offset(0.182, 0.718),
      groundY: 0.720,
    ),
    _SampleVideoPoseKeyframe(
      time: 0.105,
      head: Offset(0.308, 0.177),
      neck: Offset(0.278, 0.239),
      rearShoulder: Offset(0.270, 0.235),
      frontShoulder: Offset(0.286, 0.242),
      rearElbow: Offset(0.236, 0.286),
      rearWrist: Offset(0.258, 0.272),
      frontElbow: Offset(0.286, 0.340),
      frontWrist: Offset(0.316, 0.302),
      rearHip: Offset(0.257, 0.430),
      frontHip: Offset(0.245, 0.431),
      rearKnee: Offset(0.311, 0.505),
      rearAnkle: Offset(0.263, 0.607),
      rearToe: Offset(0.284, 0.663),
      frontKnee: Offset(0.216, 0.553),
      frontAnkle: Offset(0.166, 0.657),
      frontToe: Offset(0.181, 0.715),
      groundY: 0.720,
    ),
    _SampleVideoPoseKeyframe(
      time: 0.237,
      head: Offset(0.404, 0.176),
      neck: Offset(0.366, 0.224),
      rearShoulder: Offset(0.353, 0.226),
      frontShoulder: Offset(0.378, 0.222),
      rearElbow: Offset(0.320, 0.284),
      rearWrist: Offset(0.353, 0.313),
      frontElbow: Offset(0.371, 0.313),
      frontWrist: Offset(0.397, 0.304),
      rearHip: Offset(0.345, 0.422),
      frontHip: Offset(0.336, 0.423),
      rearKnee: Offset(0.382, 0.528),
      rearAnkle: Offset(0.401, 0.660),
      rearToe: Offset(0.438, 0.659),
      frontKnee: Offset(0.305, 0.551),
      frontAnkle: Offset(0.226, 0.566),
      frontToe: Offset(0.212, 0.633),
      groundY: 0.715,
    ),
    _SampleVideoPoseKeyframe(
      time: 0.368,
      head: Offset(0.491, 0.197),
      neck: Offset(0.457, 0.244),
      rearShoulder: Offset(0.456, 0.243),
      frontShoulder: Offset(0.457, 0.245),
      rearElbow: Offset(0.436, 0.307),
      rearWrist: Offset(0.457, 0.338),
      frontElbow: Offset(0.422, 0.311),
      frontWrist: Offset(0.457, 0.364),
      rearHip: Offset(0.436, 0.438),
      frontHip: Offset(0.429, 0.446),
      rearKnee: Offset(0.449, 0.547),
      rearAnkle: Offset(0.438, 0.677),
      rearToe: Offset(0.471, 0.715),
      frontKnee: Offset(0.434, 0.557),
      frontAnkle: Offset(0.364, 0.508),
      frontToe: Offset(0.337, 0.552),
      groundY: 0.715,
    ),
    _SampleVideoPoseKeyframe(
      time: 0.500,
      head: Offset(0.570, 0.189),
      neck: Offset(0.546, 0.239),
      rearShoulder: Offset(0.551, 0.239),
      frontShoulder: Offset(0.540, 0.239),
      rearElbow: Offset(0.579, 0.286),
      rearWrist: Offset(0.599, 0.302),
      frontElbow: Offset(0.494, 0.281),
      frontWrist: Offset(0.525, 0.337),
      rearHip: Offset(0.507, 0.424),
      frontHip: Offset(0.511, 0.428),
      rearKnee: Offset(0.491, 0.554),
      rearAnkle: Offset(0.449, 0.665),
      rearToe: Offset(0.471, 0.714),
      frontKnee: Offset(0.573, 0.505),
      frontAnkle: Offset(0.506, 0.572),
      frontToe: Offset(0.516, 0.630),
      groundY: 0.715,
    ),
    _SampleVideoPoseKeyframe(
      time: 0.605,
      head: Offset(0.647, 0.163),
      neck: Offset(0.613, 0.229),
      rearShoulder: Offset(0.617, 0.234),
      frontShoulder: Offset(0.609, 0.223),
      rearElbow: Offset(0.644, 0.282),
      rearWrist: Offset(0.659, 0.294),
      frontElbow: Offset(0.566, 0.280),
      frontWrist: Offset(0.614, 0.329),
      rearHip: Offset(0.583, 0.418),
      frontHip: Offset(0.595, 0.422),
      rearKnee: Offset(0.544, 0.543),
      rearAnkle: Offset(0.482, 0.614),
      rearToe: Offset(0.479, 0.669),
      frontKnee: Offset(0.647, 0.509),
      frontAnkle: Offset(0.635, 0.644),
      frontToe: Offset(0.668, 0.670),
      groundY: 0.715,
    ),
    _SampleVideoPoseKeyframe(
      time: 0.737,
      head: Offset(0.728, 0.183),
      neck: Offset(0.693, 0.244),
      rearShoulder: Offset(0.692, 0.242),
      frontShoulder: Offset(0.693, 0.245),
      rearElbow: Offset(0.695, 0.316),
      rearWrist: Offset(0.723, 0.328),
      frontElbow: Offset(0.667, 0.324),
      frontWrist: Offset(0.714, 0.356),
      rearHip: Offset(0.673, 0.449),
      frontHip: Offset(0.677, 0.452),
      rearKnee: Offset(0.651, 0.562),
      rearAnkle: Offset(0.583, 0.537),
      rearToe: Offset(0.559, 0.587),
      frontKnee: Offset(0.720, 0.564),
      frontAnkle: Offset(0.729, 0.696),
      frontToe: Offset(0.746, 0.718),
      groundY: 0.720,
    ),
    _SampleVideoPoseKeyframe(
      time: 0.868,
      head: Offset(0.815, 0.197),
      neck: Offset(0.783, 0.267),
      rearShoulder: Offset(0.776, 0.264),
      frontShoulder: Offset(0.789, 0.269),
      rearElbow: Offset(0.780, 0.353),
      rearWrist: Offset(0.811, 0.325),
      frontElbow: Offset(0.791, 0.371),
      frontWrist: Offset(0.817, 0.335),
      rearHip: Offset(0.760, 0.457),
      frontHip: Offset(0.763, 0.462),
      rearKnee: Offset(0.784, 0.573),
      rearAnkle: Offset(0.717, 0.558),
      rearToe: Offset(0.703, 0.611),
      frontKnee: Offset(0.781, 0.586),
      frontAnkle: Offset(0.744, 0.702),
      frontToe: Offset(0.771, 0.735),
      groundY: 0.735,
    ),
    _SampleVideoPoseKeyframe(
      time: 1.000,
      head: Offset(0.880, 0.176),
      neck: Offset(0.850, 0.247),
      rearShoulder: Offset(0.829, 0.244),
      frontShoulder: Offset(0.871, 0.250),
      rearElbow: Offset(0.792, 0.304),
      rearWrist: Offset(0.820, 0.314),
      frontElbow: Offset(0.877, 0.357),
      frontWrist: Offset(0.888, 0.310),
      rearHip: Offset(0.832, 0.443),
      frontHip: Offset(0.834, 0.447),
      rearKnee: Offset(0.880, 0.525),
      rearAnkle: Offset(0.826, 0.621),
      rearToe: Offset(0.840, 0.682),
      frontKnee: Offset(0.810, 0.574),
      frontAnkle: Offset(0.757, 0.681),
      frontToe: Offset(0.776, 0.736),
      groundY: 0.736,
    ),
  ];

  static _SampleVideoPoseKeyframe at(
    double progress, {
    required bool isMistake,
  }) {
    final keyframes =
        isMistake ? _mistakeClipKeyframes : _referenceClipKeyframes;
    final normalized = progress.clamp(0.0, 0.999999).toDouble();
    for (var index = 0; index < keyframes.length - 1; index += 1) {
      final current = keyframes[index];
      final next = keyframes[index + 1];
      if (normalized >= current.time && normalized <= next.time) {
        final localT = (normalized - current.time) / (next.time - current.time);
        return _SampleVideoPoseKeyframe.lerp(current, next, localT);
      }
    }
    return keyframes.last;
  }

  static _SampleVideoPoseKeyframe lerp(
    _SampleVideoPoseKeyframe a,
    _SampleVideoPoseKeyframe b,
    double t,
  ) {
    return _SampleVideoPoseKeyframe(
      time: _lerpDouble(a.time, b.time, t),
      head: Offset.lerp(a.head, b.head, t)!,
      neck: Offset.lerp(a.neck, b.neck, t)!,
      rearShoulder: Offset.lerp(a.rearShoulder, b.rearShoulder, t)!,
      frontShoulder: Offset.lerp(a.frontShoulder, b.frontShoulder, t)!,
      rearElbow: Offset.lerp(a.rearElbow, b.rearElbow, t)!,
      rearWrist: Offset.lerp(a.rearWrist, b.rearWrist, t)!,
      frontElbow: Offset.lerp(a.frontElbow, b.frontElbow, t)!,
      frontWrist: Offset.lerp(a.frontWrist, b.frontWrist, t)!,
      rearHip: Offset.lerp(a.rearHip, b.rearHip, t)!,
      frontHip: Offset.lerp(a.frontHip, b.frontHip, t)!,
      rearKnee: Offset.lerp(a.rearKnee, b.rearKnee, t)!,
      rearAnkle: Offset.lerp(a.rearAnkle, b.rearAnkle, t)!,
      rearToe: Offset.lerp(a.rearToe, b.rearToe, t)!,
      frontKnee: Offset.lerp(a.frontKnee, b.frontKnee, t)!,
      frontAnkle: Offset.lerp(a.frontAnkle, b.frontAnkle, t)!,
      frontToe: Offset.lerp(a.frontToe, b.frontToe, t)!,
      groundY: _lerpDouble(a.groundY, b.groundY, t),
    );
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

// ignore: unused_element
class _SampleRunnerPainter extends CustomPainter {
  final double progress;
  final Color lineColor;
  final Color trackColor;
  final Color ghostColor;
  final Color frameColor;
  final Color markerColor;
  final SampleRunnerPoseVariant poseVariant;

  const _SampleRunnerPainter({
    required this.progress,
    required this.lineColor,
    required this.trackColor,
    required this.ghostColor,
    required this.frameColor,
    required this.markerColor,
    required this.poseVariant,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawTrackEnvironment(canvas, size, progress);

    for (final offset in const <double>[0.72, 0.54, 0.36, 0.18]) {
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

  void _drawTrackEnvironment(Canvas canvas, Size size, double progress) {
    final rect = Offset.zero & size;
    final skyTop = Color.lerp(trackColor, Colors.white, 0.86)!;
    final skyBottom = Color.lerp(trackColor, lineColor, 0.20)!;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [skyTop, skyBottom],
        ).createShader(rect),
    );

    final laneTop = size.height * 0.70;
    canvas.drawRect(
      Rect.fromLTWH(0, laneTop, size.width, size.height - laneTop),
      Paint()..color = Color.lerp(trackColor, Colors.black, 0.10)!,
    );
    for (final yFactor in const <double>[0.76, 0.86]) {
      canvas.drawLine(
        Offset(size.width * 0.04, size.height * yFactor),
        Offset(size.width * 0.96, size.height * yFactor),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.30)
          ..strokeWidth = math.max(1.0, size.height * 0.006),
      );
    }
    final laneDashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.44)
      ..strokeWidth = math.max(1.2, size.height * 0.008)
      ..strokeCap = StrokeCap.round;
    final dashWidth = size.width * 0.13;
    final dashGap = size.width * 0.11;
    final dashCycle = dashWidth + dashGap;
    final dashOffset = (progress * dashCycle * 5) % dashCycle;
    for (final yFactor in const <double>[0.805, 0.925]) {
      for (var index = -1; index < 7; index += 1) {
        final startX = (index * dashCycle) - dashOffset;
        canvas.drawLine(
          Offset(startX, size.height * yFactor),
          Offset(startX + dashWidth, size.height * yFactor),
          laneDashPaint,
        );
      }
    }

    final safeFrame = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.16,
        size.height * 0.10,
        size.width * 0.68,
        size.height * 0.64,
      ),
      const Radius.circular(18),
    );
    canvas.drawRRect(
      safeFrame,
      Paint()
        ..color = frameColor.withValues(alpha: 0.33)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.4, size.height * 0.010),
    );
    for (final xFactor in const <double>[0.33, 0.50, 0.67]) {
      canvas.drawLine(
        Offset(size.width * xFactor, size.height * 0.12),
        Offset(size.width * xFactor, size.height * 0.72),
        Paint()
          ..color = frameColor.withValues(alpha: 0.14)
          ..strokeWidth = 1,
      );
    }
    for (final yFactor in const <double>[0.22, 0.34, 0.48]) {
      final start = Offset(
        size.width * (0.15 - progress * 0.10),
        size.height * yFactor,
      );
      canvas.drawLine(
        start,
        Offset(start.dx - size.width * 0.12, start.dy + size.height * 0.018),
        Paint()
          ..color = lineColor.withValues(alpha: 0.08)
          ..strokeWidth = math.max(1.0, size.height * 0.006)
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawRunner(
    Canvas canvas,
    Size size, {
    required double progress,
    required Color color,
    required double strokeWidth,
  }) {
    final pose = buildSampleRunnerPose(
      progress: progress,
      size: size,
      variant: poseVariant,
    );
    final scale = size.height;
    final isGhost = strokeWidth < 4;
    final baseAlpha = isGhost ? 0.18 : 0.96;
    final kitColor = color.withValues(alpha: baseAlpha);
    final shortsColor = Color.lerp(
      color,
      Colors.black,
      0.34,
    )!
        .withValues(alpha: baseAlpha);
    final skinColor =
        isGhost ? color.withValues(alpha: 0.16) : const Color(0xFFE8B98E);
    final hairColor =
        isGhost ? color.withValues(alpha: 0.12) : const Color(0xFF3A2A24);
    final outlineColor = isGhost
        ? color.withValues(alpha: 0.10)
        : Color.lerp(color, Colors.black, 0.20)!.withValues(alpha: 0.72);
    final tankTrimColor = isGhost
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.58);
    final groundY = pose.groundY;
    final hip = pose.hip;
    final chest = pose.chest;
    final neck = pose.neck;
    final head = pose.head;
    final shoulderFront = pose.shoulderFront;
    final shoulderRear = pose.shoulderRear;
    final hipFront = pose.hipFront;
    final hipRear = pose.hipRear;
    final frontLeg = pose.frontLeg;
    final rearLeg = pose.rearLeg;
    final frontArm = pose.frontArm;
    final rearArm = pose.rearArm;
    final upperLimbWidth = math.max(7.0, scale * (isGhost ? 0.030 : 0.045));
    final lowerLimbWidth = math.max(6.0, scale * (isGhost ? 0.026 : 0.038));
    final footWidth = math.max(5.0, scale * (isGhost ? 0.026 : 0.034));
    final handRadius = math.max(3.6, scale * (isGhost ? 0.014 : 0.021));

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(hip.dx + scale * 0.04, groundY + scale * 0.025),
        width: scale * 0.52,
        height: scale * 0.08,
      ),
      Paint()..color = color.withValues(alpha: isGhost ? 0.04 : 0.10),
    );

    for (final line in <double>[0.0, 0.045, 0.09]) {
      final start = Offset(
        hip.dx - scale * (0.34 + line),
        hip.dy + scale * (0.02 + line),
      );
      canvas.drawLine(
        start,
        Offset(start.dx - scale * 0.18, start.dy + scale * 0.012),
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
    _drawHand(canvas, rearArm.wrist, rearSkin, handRadius * 0.84);
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

    final waistFront = Offset(
      hipFront.dx + scale * 0.010,
      hipFront.dy + scale * 0.014,
    );
    final waistRear = Offset(
      hipRear.dx - scale * 0.006,
      hipRear.dy + scale * 0.018,
    );
    final torso = Path()
      ..moveTo(shoulderRear.dx + scale * 0.012, shoulderRear.dy)
      ..quadraticBezierTo(
        chest.dx - scale * 0.048,
        chest.dy + scale * 0.040,
        waistRear.dx,
        waistRear.dy,
      )
      ..lineTo(waistFront.dx, waistFront.dy)
      ..quadraticBezierTo(
        chest.dx + scale * 0.086,
        chest.dy + scale * 0.040,
        shoulderFront.dx - scale * 0.012,
        shoulderFront.dy,
      )
      ..quadraticBezierTo(
        chest.dx + scale * 0.026,
        chest.dy - scale * 0.026,
        shoulderRear.dx + scale * 0.012,
        shoulderRear.dy,
      )
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
    final neckline = Path()
      ..moveTo(shoulderRear.dx + scale * 0.036, shoulderRear.dy + scale * 0.002)
      ..quadraticBezierTo(
        chest.dx + scale * 0.010,
        chest.dy + scale * 0.036,
        shoulderFront.dx - scale * 0.040,
        shoulderFront.dy + scale * 0.002,
      );
    canvas.drawPath(
      neckline,
      Paint()
        ..color = tankTrimColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, strokeWidth * 0.28)
        ..strokeCap = StrokeCap.round,
    );
    _drawSegment(
      canvas,
      Offset(
        shoulderFront.dx - scale * 0.010,
        shoulderFront.dy + scale * 0.006,
      ),
      Offset(waistFront.dx - scale * 0.002, waistFront.dy - scale * 0.004),
      tankTrimColor,
      math.max(1.0, strokeWidth * 0.22),
    );
    _drawSegment(
      canvas,
      Offset(shoulderRear.dx + scale * 0.010, shoulderRear.dy + scale * 0.008),
      Offset(waistRear.dx + scale * 0.006, waistRear.dy - scale * 0.004),
      tankTrimColor.withValues(alpha: isGhost ? 0.04 : 0.36),
      math.max(1.0, strokeWidth * 0.18),
    );
    canvas.drawPath(
      Path()
        ..moveTo(waistRear.dx - scale * 0.012, waistRear.dy - scale * 0.004)
        ..lineTo(waistFront.dx + scale * 0.016, waistFront.dy - scale * 0.004)
        ..quadraticBezierTo(
          hipFront.dx + scale * 0.070,
          hipFront.dy + scale * 0.046,
          hip.dx + scale * 0.014,
          hip.dy + scale * 0.058,
        )
        ..quadraticBezierTo(
          hipRear.dx - scale * 0.048,
          hipRear.dy + scale * 0.058,
          waistRear.dx - scale * 0.012,
          waistRear.dy - scale * 0.004,
        )
        ..close(),
      Paint()..color = shortsColor,
    );
    _drawSegment(
      canvas,
      waistRear,
      waistFront,
      outlineColor.withValues(alpha: isGhost ? 0.05 : 0.50),
      math.max(1.0, strokeWidth * 0.30),
    );
    _drawSegment(
      canvas,
      Offset(hip.dx - scale * 0.018, hip.dy + scale * 0.050),
      Offset(hip.dx + scale * 0.044, hip.dy + scale * 0.050),
      tankTrimColor.withValues(alpha: isGhost ? 0.04 : 0.30),
      math.max(1.0, strokeWidth * 0.18),
    );
    _drawSegment(
      canvas,
      neck,
      chest,
      skinColor.withValues(alpha: isGhost ? 0.12 : 0.86),
      math.max(5.0, scale * (isGhost ? 0.020 : 0.030)),
    );
    _drawHead(
      canvas,
      head: head,
      scale: scale,
      skinColor: skinColor,
      hairColor: hairColor,
      outlineColor: outlineColor,
      isGhost: isGhost,
      strokeWidth: strokeWidth,
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
    _drawHand(
      canvas,
      frontArm.wrist,
      skinColor.withValues(alpha: isGhost ? 0.15 : 0.94),
      handRadius,
    );

    _drawSegment(
      canvas,
      Offset(chest.dx - scale * 0.018, chest.dy + scale * 0.030),
      Offset(hip.dx + scale * 0.012, hip.dy - scale * 0.018),
      Colors.white.withValues(alpha: isGhost ? 0.04 : 0.28),
      math.max(1.0, strokeWidth * 0.34),
    );

    if (!isGhost) {
      _drawPoseGuides(
        canvas,
        size,
        head: head,
        neck: neck,
        chest: chest,
        hip: hip,
        groundY: groundY,
        joints: [
          shoulderFront,
          shoulderRear,
          hipFront,
          hipRear,
          frontArm.elbow,
          frontArm.wrist,
          frontLeg.knee,
          frontLeg.ankle,
          rearLeg.knee,
          rearLeg.ankle,
        ],
        frontLeg: frontLeg,
        rearLeg: rearLeg,
        frontArm: frontArm,
        rearArm: rearArm,
      );
    }
  }

  void _drawHead(
    Canvas canvas, {
    required Offset head,
    required double scale,
    required Color skinColor,
    required Color hairColor,
    required Color outlineColor,
    required bool isGhost,
    required double strokeWidth,
  }) {
    final faceRect = Rect.fromCenter(
      center: head,
      width: scale * (isGhost ? 0.076 : 0.090),
      height: scale * (isGhost ? 0.092 : 0.108),
    );
    canvas.drawOval(
      faceRect,
      Paint()
        ..color = skinColor.withValues(alpha: isGhost ? 0.12 : 0.96)
        ..style = PaintingStyle.fill,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(head.dx - scale * 0.034, head.dy + scale * 0.004),
        width: scale * 0.020,
        height: scale * 0.028,
      ),
      Paint()..color = skinColor.withValues(alpha: isGhost ? 0.08 : 0.74),
    );
    final hair = Path()
      ..moveTo(head.dx - scale * 0.044, head.dy - scale * 0.018)
      ..quadraticBezierTo(
        head.dx - scale * 0.010,
        head.dy - scale * 0.070,
        head.dx + scale * 0.046,
        head.dy - scale * 0.026,
      )
      ..quadraticBezierTo(
        head.dx + scale * 0.020,
        head.dy - scale * 0.050,
        head.dx - scale * 0.034,
        head.dy - scale * 0.044,
      )
      ..close();
    canvas.drawPath(hair, Paint()..color = hairColor);
    canvas.drawCircle(
      Offset(head.dx + scale * 0.030, head.dy - scale * 0.008),
      math.max(1.4, scale * 0.006),
      Paint()..color = outlineColor,
    );
    _drawSegment(
      canvas,
      Offset(head.dx + scale * 0.038, head.dy + scale * 0.006),
      Offset(head.dx + scale * 0.054, head.dy + scale * 0.010),
      outlineColor.withValues(alpha: isGhost ? 0.06 : 0.46),
      math.max(1.0, strokeWidth * 0.22),
    );
  }

  void _drawPoseGuides(
    Canvas canvas,
    Size size, {
    required Offset head,
    required Offset neck,
    required Offset chest,
    required Offset hip,
    required double groundY,
    required List<Offset> joints,
    required SampleRunnerLegPose frontLeg,
    required SampleRunnerLegPose rearLeg,
    required SampleRunnerArmPose frontArm,
    required SampleRunnerArmPose rearArm,
  }) {
    final guidePaint = Paint()
      ..color = markerColor.withValues(alpha: 0.74)
      ..strokeWidth = math.max(1.2, size.height * 0.010)
      ..strokeCap = StrokeCap.round;
    final subtleGuidePaint = Paint()
      ..color = markerColor.withValues(alpha: 0.26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, size.height * 0.008);
    final contactLeg = (groundY - frontLeg.ankle.dy).abs() <=
            (groundY - rearLeg.ankle.dy).abs()
        ? frontLeg
        : rearLeg;
    final contactPatchPaint = Paint()
      ..color = markerColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    canvas.drawLine(neck, hip, guidePaint);
    canvas.drawLine(
      Offset(hip.dx, hip.dy + size.height * 0.018),
      Offset(hip.dx + size.height * 0.058, groundY),
      subtleGuidePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          hip.dx - size.height * 0.270,
          head.dy - size.height * 0.060,
          size.height * 0.600,
          groundY - head.dy + size.height * 0.030,
        ),
        const Radius.circular(18),
      ),
      Paint()
        ..color = markerColor.withValues(alpha: 0.34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, size.height * 0.007),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          hip.dx + size.height * 0.068,
          groundY - size.height * 0.030,
        ),
        width: size.height * 0.250,
        height: size.height * 0.090,
      ),
      subtleGuidePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          (contactLeg.ankle.dx + contactLeg.toe.dx) / 2,
          groundY + size.height * 0.006,
        ),
        width: size.height * 0.132,
        height: size.height * 0.034,
      ),
      contactPatchPaint,
    );
    _drawSegment(
      canvas,
      Offset(contactLeg.hip.dx, groundY - size.height * 0.012),
      Offset(contactLeg.hip.dx, groundY + size.height * 0.030),
      markerColor.withValues(alpha: 0.54),
      math.max(1.0, size.height * 0.008),
    );
    _drawSegment(
      canvas,
      Offset(contactLeg.hip.dx, groundY + size.height * 0.020),
      Offset(contactLeg.ankle.dx, groundY + size.height * 0.020),
      markerColor.withValues(alpha: 0.52),
      math.max(1.0, size.height * 0.008),
    );
    _drawAngleArc(
      canvas,
      center: contactLeg.knee,
      first: contactLeg.hip,
      second: contactLeg.ankle,
      radius: size.height * 0.052,
      color: markerColor.withValues(alpha: 0.70),
      strokeWidth: math.max(1.0, size.height * 0.010),
    );
    _drawAngleArc(
      canvas,
      center: frontArm.elbow,
      first: frontArm.shoulder,
      second: frontArm.wrist,
      radius: size.height * 0.034,
      color: markerColor.withValues(alpha: 0.58),
      strokeWidth: math.max(1.0, size.height * 0.008),
    );
    _drawAngleArc(
      canvas,
      center: rearArm.elbow,
      first: rearArm.shoulder,
      second: rearArm.wrist,
      radius: size.height * 0.030,
      color: markerColor.withValues(alpha: 0.38),
      strokeWidth: math.max(1.0, size.height * 0.007),
    );
    for (final joint in joints) {
      canvas.drawCircle(
        joint,
        math.max(2.4, size.height * 0.010),
        Paint()..color = Colors.white.withValues(alpha: 0.76),
      );
      canvas.drawCircle(
        joint,
        math.max(1.5, size.height * 0.006),
        Paint()..color = markerColor.withValues(alpha: 0.92),
      );
    }
  }

  void _drawAngleArc(
    Canvas canvas, {
    required Offset center,
    required Offset first,
    required Offset second,
    required double radius,
    required Color color,
    required double strokeWidth,
  }) {
    final startAngle = math.atan2(first.dy - center.dy, first.dx - center.dx);
    final endAngle = math.atan2(second.dy - center.dy, second.dx - center.dx);
    final sweep = _shortestAngleSweep(startAngle, endAngle);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  double _shortestAngleSweep(double start, double end) {
    var sweep = (end - start) % (math.pi * 2);
    if (sweep > math.pi) sweep -= math.pi * 2;
    if (sweep < -math.pi) sweep += math.pi * 2;
    return sweep;
  }

  void _drawHand(Canvas canvas, Offset center, Color color, double radius) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
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
        oldDelegate.ghostColor != ghostColor ||
        oldDelegate.frameColor != frameColor ||
        oldDelegate.markerColor != markerColor ||
        oldDelegate.poseVariant != poseVariant;
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
  final int totalCount;
  final VoidCallback onShowAll;
  final ValueChanged<RunningCoachSessionAnalysis> onSessionTap;

  const _RecentSessionsCard({
    required this.sessions,
    required this.totalCount,
    required this.onShowAll,
    required this.onSessionTap,
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
              children: [
                Icon(Icons.history_rounded, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.runningCoachAnalysisHistoryTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onShowAll,
                  icon: const Icon(Icons.list_alt_rounded),
                  label: Text(
                    l10n.runningCoachAnalysisHistoryAction(totalCount),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.runningCoachAnalysisHistoryBody,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < sessions.length; index += 1) ...[
              _RecentSessionTile(
                session: sessions[index],
                onTap: () => onSessionTap(sessions[index]),
              ),
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
  final VoidCallback? onTap;

  const _RecentSessionTile({required this.session, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final copy = RunningCoachInsightCopy.fromInsight(
      session.primaryInsight,
      l10n,
    );
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Text(
                  '${session.overallScore}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
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
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
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
                      _TinySessionPill(
                        text: _sessionSourceLabel(l10n, session),
                      ),
                      if (session.videoPath != null)
                        _TinySessionPill(
                          text: l10n.runningCoachHistoryVideoSaved,
                        ),
                      _TinySessionPill(
                        text: _formatSessionDate(context, session),
                      ),
                      _TinySessionPill(
                        text: l10n.runningCoachConfidenceLabel(
                          (session.primaryConfidence * 100).round(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: scheme.outline),
            ],
          ],
        ),
      ),
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

class _AnalysisHistorySheet extends StatelessWidget {
  final List<RunningCoachSessionAnalysis> sessions;
  final ValueChanged<RunningCoachSessionAnalysis> onSessionSelected;

  const _AnalysisHistorySheet({
    required this.sessions,
    required this.onSessionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.runningCoachAnalysisHistoryTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.runningCoachAnalysisHistoryBody,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              AppBarActionButton.icon(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
                icon: Icons.close_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (sessions.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  l10n.runningCoachAnalysisHistoryEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: sessions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return _AnalysisHistoryTile(
                    session: session,
                    onTap: () => onSessionSelected(session),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _AnalysisHistoryTile extends StatelessWidget {
  final RunningCoachSessionAnalysis session;
  final VoidCallback onTap;

  const _AnalysisHistoryTile({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final insight = session.primaryInsight;
    final copy = RunningCoachInsightCopy.fromInsight(insight, l10n);
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.58),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InsightGuideThumbnail(insight: insight),
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
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        _ScoreBadge(score: session.overallScore),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      copy.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _TinySessionPill(
                          text: _sessionSourceLabel(l10n, session),
                        ),
                        if (session.videoPath != null)
                          _TinySessionPill(
                            text: l10n.runningCoachHistoryVideoSaved,
                          ),
                        _TinySessionPill(
                          text: _formatSessionDate(context, session),
                        ),
                        _TinySessionPill(
                          text: l10n.runningCoachMetricScore(
                            session.primaryScore,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _RunningAnalysisResultScreen extends StatelessWidget {
  final RunningVideoAnalysisResult result;
  final RunningCoachingReport report;
  final RunningCoachSessionAnalysis session;

  const _RunningAnalysisResultScreen({
    required this.result,
    required this.report,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final insightSections = _buildRunningInsightSections(l10n, report);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.runningCoachAnalysisResultScreenTitle)),
      body: ListView(
        key: const ValueKey('running-coach-analysis-result-list'),
        padding: const EdgeInsets.all(16),
        children: [
          if (session.videoPath != null) ...[
            _ArchivedAnalysisVideoCard(session: session),
            const SizedBox(height: 12),
          ],
          _ResultsSummaryCard(result: result, report: report),
          const SizedBox(height: 12),
          Text(
            l10n.runningCoachResultsTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          for (var sectionIndex = 0;
              sectionIndex < insightSections.length;
              sectionIndex += 1) ...[
            _InsightRegionSectionCard(
              title: insightSections[sectionIndex].title,
              insights: insightSections[sectionIndex].insights,
              priorities: report.focusPriorityByMetric,
            ),
            if (sectionIndex != insightSections.length - 1)
              const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _AnalysisHistoryDetailScreen extends StatelessWidget {
  final RunningCoachSessionAnalysis session;

  const _AnalysisHistoryDetailScreen({required this.session});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final insight = session.primaryInsight;
    final copy = RunningCoachInsightCopy.fromInsight(insight, l10n);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.runningCoachAnalysisHistoryDetailTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (session.videoPath != null) ...[
            _ArchivedAnalysisVideoCard(session: session),
            const SizedBox(height: 12),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.runningCoachAnalysisHistoryPrimaryFocus,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _StatChip(
                        label: l10n.runningCoachOverallScoreLabel,
                        value: '${session.overallScore}',
                      ),
                      _StatChip(
                        label: l10n.runningCoachMetricScoreLabel,
                        value: '${session.primaryScore}',
                      ),
                      _StatChip(
                        label: l10n.runningCoachMetricValueLabel,
                        value: copy.value,
                      ),
                      _StatChip(
                        label: l10n.runningCoachCoverageLabel,
                        value:
                            '${(session.coverage * 100).toStringAsFixed(0)}%',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _TinySessionPill(
                          text: _sessionSourceLabel(l10n, session)),
                      if (session.videoPath != null)
                        _TinySessionPill(
                          text: l10n.runningCoachHistoryVideoSaved,
                        ),
                      _TinySessionPill(
                        text: _formatSessionDate(context, session),
                      ),
                      _TinySessionPill(
                        text: l10n.runningCoachConfidenceLabel(
                          (session.primaryConfidence * 100).round(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _InsightGuidePanel(insight: insight),
        ],
      ),
    );
  }
}

class _ArchivedAnalysisVideoCard extends StatefulWidget {
  final RunningCoachSessionAnalysis session;

  const _ArchivedAnalysisVideoCard({required this.session});

  @override
  State<_ArchivedAnalysisVideoCard> createState() =>
      _ArchivedAnalysisVideoCardState();
}

class _ArchivedAnalysisVideoCardState
    extends State<_ArchivedAnalysisVideoCard> {
  VideoPlayerController? _controller;
  bool _isInitializing = true;
  bool _isUnavailable = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeVideo());
  }

  @override
  void didUpdateWidget(covariant _ArchivedAnalysisVideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.videoPath != widget.session.videoPath) {
      unawaited(_controller?.dispose());
      _controller = null;
      _isInitializing = true;
      _isUnavailable = false;
      unawaited(_initializeVideo());
    }
  }

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    final path = widget.session.videoPath;
    if (path == null || path.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _isUnavailable = true;
      });
      return;
    }
    try {
      final file = File(path);
      if (!await file.exists()) {
        if (!mounted) return;
        setState(() {
          _isInitializing = false;
          _isUnavailable = true;
        });
        return;
      }
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      await controller.setLooping(true);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _isUnavailable = true;
      });
    }
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final controller = _controller;
    final isReady = controller != null && controller.value.isInitialized;
    final readyController = isReady ? controller : null;
    return Card(
      key: const ValueKey('running-coach-archived-video-card'),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.movie_filter_outlined,
                  color: scheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.runningCoachArchivedVideoTitle,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      if (widget.session.videoName case final videoName?) ...[
                        const SizedBox(height: 3),
                        Text(
                          videoName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (isReady) ...[
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.icon(
                  onPressed: _togglePlayback,
                  icon: Icon(
                    controller.value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  label: Text(
                    controller.value.isPlaying
                        ? l10n.runningCoachArchivedVideoPause
                        : l10n.runningCoachArchivedVideoPlay,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: readyController?.value.aspectRatio ?? 16 / 9,
                  child: _isInitializing
                      ? const Center(child: CircularProgressIndicator())
                      : _isUnavailable || readyController == null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  l10n.runningCoachArchivedVideoUnavailable,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.white),
                                ),
                              ),
                            )
                          : VideoPlayer(readyController),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.runningCoachArchivedVideoBody,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightGuidePanel extends StatelessWidget {
  final RunningCoachingInsight insight;

  const _InsightGuidePanel({required this.insight});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final copy = RunningCoachInsightCopy.fromInsight(insight, l10n);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _metricGuideIcon(insight.metric),
                  color: _statusAccentColor(insight.status),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.runningCoachAnalysisGuideTitle,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.runningCoachAnalysisGuideBody,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _InsightGuideVisual(insight: insight),
            const SizedBox(height: 14),
            _GuideTextRow(
              icon: Icons.analytics_outlined,
              label: l10n.runningCoachAnalysisGuideRangeLabel,
              body: _metricGoodRange(l10n, insight.metric),
            ),
            const SizedBox(height: 10),
            _GuideTextRow(
              icon: Icons.notes_outlined,
              label: l10n.runningCoachAnalysisGuideFindingLabel,
              body: copy.summary,
            ),
            const SizedBox(height: 10),
            _GuideTextRow(
              icon: Icons.flag_outlined,
              label: l10n.runningCoachAnalysisGuideCueLabel,
              body: copy.cue,
            ),
            const SizedBox(height: 10),
            _GuideTextRow(
              icon: Icons.fitness_center_outlined,
              label: l10n.runningCoachAnalysisGuideDrillLabel,
              body: copy.drill,
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideTextRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String body;

  const _GuideTextRow({
    required this.icon,
    required this.label,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 3),
              Text(body, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightGuideVisual extends StatelessWidget {
  final RunningCoachingInsight insight;

  const _InsightGuideVisual({required this.insight});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      key:
          ValueKey('running-coach-insight-guide-visual-${insight.metric.name}'),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _metricGuideIcon(insight.metric),
                  size: 18,
                  color: _statusAccentColor(insight.status),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _metricGoodRange(l10n, insight.metric),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 190,
              width: double.infinity,
              child: CustomPaint(
                painter: _RunningInsightGuidePainter(
                  metric: insight.metric,
                  finding: insight.finding,
                  status: insight.status,
                  surfaceColor: scheme.surface,
                  mutedColor: scheme.outline,
                  guideColor: scheme.primary.withValues(alpha: 0.34),
                  accentColor: _statusAccentColor(insight.status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightGuideThumbnail extends StatelessWidget {
  final RunningCoachingInsight insight;

  const _InsightGuideThumbnail({required this.insight});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: SizedBox(
        width: 72,
        height: 72,
        child: CustomPaint(
          painter: _RunningInsightGuidePainter(
            metric: insight.metric,
            finding: insight.finding,
            status: insight.status,
            surfaceColor: scheme.surface,
            mutedColor: scheme.outline,
            guideColor: scheme.primary.withValues(alpha: 0.28),
            accentColor: _statusAccentColor(insight.status),
            compact: true,
          ),
        ),
      ),
    );
  }
}

class _RunningInsightGuidePainter extends CustomPainter {
  final RunningCoachMetric metric;
  final RunningCoachFinding finding;
  final RunningCoachStatus status;
  final Color surfaceColor;
  final Color mutedColor;
  final Color guideColor;
  final Color accentColor;
  final bool compact;

  const _RunningInsightGuidePainter({
    required this.metric,
    required this.finding,
    required this.status,
    required this.surfaceColor,
    required this.mutedColor,
    required this.guideColor,
    required this.accentColor,
    this.compact = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 300, size.height / 178);
    final center = Offset(size.width * 0.50, size.height * 0.54);
    final groundY = center.dy + 54 * scale;
    final lean = switch (finding) {
      RunningCoachFinding.postureTooUpright => 8.0,
      RunningCoachFinding.postureTooLean => 48.0,
      _ => 28.0,
    };
    final footReach = switch (finding) {
      RunningCoachFinding.footStrikeOverstride => 72.0,
      _ => 42.0,
    };
    final kneeDrop = switch (finding) {
      RunningCoachFinding.kneeTooStraight => 8.0,
      RunningCoachFinding.kneeTooCollapsed => 28.0,
      _ => 18.0,
    };
    final armOpen = switch (finding) {
      RunningCoachFinding.armTooOpen => 34.0,
      RunningCoachFinding.armTooTight => 12.0,
      _ => 24.0,
    };

    final hip = center + Offset(-12 * scale, -8 * scale);
    final shoulder = hip + Offset(lean * scale, -54 * scale);
    final bodyNormal = _normalVector(shoulder, hip);
    final hipFront = hip - bodyNormal * 11 * scale;
    final hipRear = hip + bodyNormal * 11 * scale;
    final shoulderFront = shoulder - bodyNormal * 10 * scale;
    final shoulderRear = shoulder + bodyNormal * 10 * scale;
    final chest = Offset.lerp(shoulder, hip, 0.42)!;
    final neck = shoulder + Offset(8 * scale, -12 * scale);
    final head = neck + Offset(5 * scale, -14 * scale);
    final frontKnee = hipFront + Offset(30 * scale, (32 + kneeDrop) * scale);
    final frontAnkle = hipFront + Offset((footReach - 10) * scale, 50 * scale);
    final frontToe = hipFront + Offset(footReach * scale, 58 * scale);
    final frontHeel = frontAnkle + Offset(-12 * scale, 5 * scale);
    final backKnee = hipRear + Offset(-45 * scale, 32 * scale);
    final backAnkle = hipRear + Offset(-76 * scale, 53 * scale);
    final backToe = backAnkle + Offset(-16 * scale, 3 * scale);
    final backHeel = backAnkle + Offset(10 * scale, 6 * scale);
    final frontElbow = shoulderFront + Offset(armOpen * scale, 28 * scale);
    final frontHand = frontElbow + Offset(18 * scale, 26 * scale);
    final backElbow = shoulderRear + Offset(-armOpen * scale, 20 * scale);
    final backHand = backElbow + Offset(-20 * scale, 26 * scale);

    final guidePaint = Paint()
      ..color = guideColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 1.4 : 1.8
      ..strokeCap = StrokeCap.round;
    final bodyPaint = Paint()
      ..color = mutedColor.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 3.2 : 4.4
      ..strokeCap = StrokeCap.round;
    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 3.4 : 4.8
      ..strokeCap = StrokeCap.round;
    final jointPaint = Paint()
      ..color = surfaceColor
      ..style = PaintingStyle.fill;
    final jointStroke = Paint()
      ..color = mutedColor.withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 1.2 : 1.6;
    final accentJointStroke = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 1.5 : 2;

    if (!compact) {
      _drawBiomechanicsGrid(canvas, size, guidePaint);
    }
    canvas.drawLine(
      Offset(size.width * 0.08, groundY),
      Offset(size.width * 0.92, groundY),
      guidePaint,
    );
    _drawTorsoBiomechanics(canvas, shoulder, hip, scale);
    _drawBodySegment(canvas, hip, shoulder, bodyPaint, accentPaint,
        active: metric == RunningCoachMetric.posture);
    _drawShoulderPelvisBars(
      canvas,
      shoulderFront,
      shoulderRear,
      hipFront,
      hipRear,
      bodyPaint,
    );
    _drawBodySegment(canvas, shoulderFront, frontElbow, bodyPaint, accentPaint,
        active: metric == RunningCoachMetric.armCarriage);
    _drawBodySegment(canvas, frontElbow, frontHand, bodyPaint, accentPaint,
        active: metric == RunningCoachMetric.armCarriage);
    _drawBodySegment(canvas, shoulderRear, backElbow, bodyPaint, accentPaint,
        active: metric == RunningCoachMetric.armCarriage);
    _drawBodySegment(canvas, backElbow, backHand, bodyPaint, accentPaint,
        active: metric == RunningCoachMetric.armCarriage);
    _drawBodySegment(canvas, hipFront, frontKnee, bodyPaint, accentPaint,
        active: metric == RunningCoachMetric.kneeFlexion);
    _drawBodySegment(canvas, frontKnee, frontAnkle, bodyPaint, accentPaint,
        active: metric == RunningCoachMetric.kneeFlexion ||
            metric == RunningCoachMetric.footStrike);
    _drawFoot(
      canvas,
      ankle: frontAnkle,
      heel: frontHeel,
      toe: frontToe,
      bodyPaint: bodyPaint,
      accentPaint: accentPaint,
      active: metric == RunningCoachMetric.footStrike,
    );
    _drawBodySegment(canvas, hipRear, backKnee, bodyPaint, accentPaint);
    _drawBodySegment(canvas, backKnee, backAnkle, bodyPaint, accentPaint);
    _drawFoot(
      canvas,
      ankle: backAnkle,
      heel: backHeel,
      toe: backToe,
      bodyPaint: bodyPaint,
      accentPaint: accentPaint,
    );

    canvas.drawCircle(head, compact ? 7 * scale : 10 * scale, jointPaint);
    canvas.drawCircle(head, compact ? 7 * scale : 10 * scale, jointStroke);
    for (final joint in <({Offset point, bool active})>[
      (point: neck, active: false),
      (point: shoulderFront, active: metric == RunningCoachMetric.posture),
      (point: shoulderRear, active: metric == RunningCoachMetric.posture),
      (point: chest, active: metric == RunningCoachMetric.posture),
      (point: hipFront, active: metric == RunningCoachMetric.footStrike),
      (point: hipRear, active: metric == RunningCoachMetric.footStrike),
      (point: frontElbow, active: metric == RunningCoachMetric.armCarriage),
      (point: frontHand, active: metric == RunningCoachMetric.armCarriage),
      (point: backElbow, active: metric == RunningCoachMetric.armCarriage),
      (point: backHand, active: metric == RunningCoachMetric.armCarriage),
      (point: frontKnee, active: metric == RunningCoachMetric.kneeFlexion),
      (point: frontAnkle, active: metric == RunningCoachMetric.footStrike),
      (point: frontToe, active: metric == RunningCoachMetric.footStrike),
      (point: backKnee, active: false),
      (point: backAnkle, active: false),
      (point: backToe, active: false),
    ]) {
      _drawDetailedJoint(
        canvas,
        joint.point,
        scale,
        jointPaint,
        joint.active ? accentJointStroke : jointStroke,
        active: joint.active,
      );
    }

    switch (metric) {
      case RunningCoachMetric.posture:
        final verticalTop = Offset(hip.dx, hip.dy - 62 * scale);
        canvas.drawLine(verticalTop, hip + Offset(0, 18 * scale), guidePaint);
        _drawAngleArc(
          canvas,
          center: hip,
          radius: 30 * scale,
          startRadians: -math.pi / 2,
          sweepRadians: lean / 90,
          paint: accentPaint,
        );
        _drawArrow(
            canvas, shoulder - Offset(10 * scale, 0), shoulder, accentPaint);
      case RunningCoachMetric.bounce:
        final topLine = groundY - 76 * scale;
        final bottomLine = groundY - 58 * scale;
        canvas.drawLine(
          Offset(size.width * 0.20, topLine),
          Offset(size.width * 0.82, topLine),
          guidePaint,
        );
        canvas.drawLine(
          Offset(size.width * 0.20, bottomLine),
          Offset(size.width * 0.82, bottomLine),
          guidePaint,
        );
        _drawArrow(
          canvas,
          Offset(shoulder.dx + 36 * scale, bottomLine),
          Offset(shoulder.dx + 36 * scale, topLine),
          accentPaint,
        );
        _drawArrow(
          canvas,
          Offset(shoulder.dx + 36 * scale, topLine),
          Offset(shoulder.dx + 36 * scale, bottomLine),
          accentPaint,
        );
      case RunningCoachMetric.footStrike:
        final targetLeft = hip.dx - 12 * scale;
        final targetRight = hip.dx + 46 * scale;
        final targetRect = Rect.fromLTRB(
          targetLeft,
          groundY - 16 * scale,
          targetRight,
          groundY + 6 * scale,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(targetRect, Radius.circular(8 * scale)),
          Paint()
            ..color = guideColor
            ..style = PaintingStyle.fill,
        );
        canvas.drawLine(
          Offset(hip.dx, hip.dy + 5 * scale),
          Offset(hip.dx, groundY + 4 * scale),
          guidePaint,
        );
        canvas.drawCircle(frontToe, compact ? 6 * scale : 8 * scale,
            Paint()..color = accentColor.withValues(alpha: 0.18));
        canvas.drawCircle(
            frontToe, compact ? 6 * scale : 8 * scale, accentJointStroke);
      case RunningCoachMetric.kneeFlexion:
        _drawAngleArc(
          canvas,
          center: frontKnee,
          radius: 24 * scale,
          startRadians: -2.35,
          sweepRadians: 1.45,
          paint: accentPaint,
        );
        canvas.drawCircle(frontKnee, compact ? 7 * scale : 9 * scale,
            Paint()..color = accentColor.withValues(alpha: 0.16));
        canvas.drawCircle(
            frontKnee, compact ? 7 * scale : 9 * scale, accentJointStroke);
      case RunningCoachMetric.armCarriage:
        _drawAngleArc(
          canvas,
          center: frontElbow,
          radius: 18 * scale,
          startRadians: -2.1,
          sweepRadians: 1.6,
          paint: accentPaint,
        );
        canvas.drawCircle(frontElbow, compact ? 7 * scale : 9 * scale,
            Paint()..color = accentColor.withValues(alpha: 0.16));
        canvas.drawCircle(
            frontElbow, compact ? 7 * scale : 9 * scale, accentJointStroke);
    }
  }

  void _drawShoulderPelvisBars(
    Canvas canvas,
    Offset shoulderFront,
    Offset shoulderRear,
    Offset hipFront,
    Offset hipRear,
    Paint bodyPaint,
  ) {
    final paint = Paint()
      ..color = bodyPaint.color.withValues(alpha: compact ? 0.36 : 0.48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 2.0 : 2.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(shoulderRear, shoulderFront, paint);
    canvas.drawLine(hipRear, hipFront, paint);
  }

  void _drawFoot(
    Canvas canvas, {
    required Offset ankle,
    required Offset heel,
    required Offset toe,
    required Paint bodyPaint,
    required Paint accentPaint,
    bool active = false,
  }) {
    final paint = Paint()
      ..color = active
          ? accentPaint.color.withValues(alpha: 0.92)
          : bodyPaint.color.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = active ? (compact ? 4.0 : 5.4) : (compact ? 3.0 : 4.2)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final footPath = Path()
      ..moveTo(heel.dx, heel.dy)
      ..quadraticBezierTo(ankle.dx, ankle.dy, toe.dx, toe.dy);
    canvas.drawPath(
      footPath.shift(Offset(0, paint.strokeWidth * 0.24)),
      Paint()
        ..color = Colors.black.withValues(alpha: compact ? 0.04 : 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = paint.strokeWidth + 1.8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(footPath, paint);
  }

  void _drawDetailedJoint(
    Canvas canvas,
    Offset center,
    double scale,
    Paint fillPaint,
    Paint strokePaint, {
    bool active = false,
  }) {
    final outerRadius = compact ? 3.0 * scale : 4.4 * scale;
    if (active) {
      canvas.drawCircle(
        center,
        outerRadius + (compact ? 2.4 * scale : 3.2 * scale),
        Paint()
          ..color = strokePaint.color.withValues(alpha: 0.14)
          ..style = PaintingStyle.fill,
      );
    }
    canvas.drawCircle(center, outerRadius, fillPaint);
    canvas.drawCircle(center, outerRadius, strokePaint);
    if (!compact) {
      canvas.drawCircle(
        center,
        math.max(1.4, outerRadius * 0.34),
        Paint()
          ..color = strokePaint.color.withValues(alpha: active ? 0.92 : 0.52)
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _drawBodySegment(
    Canvas canvas,
    Offset from,
    Offset to,
    Paint bodyPaint,
    Paint accentPaint, {
    bool active = false,
  }) {
    final width = active ? (compact ? 6.0 : 9.0) : (compact ? 4.3 : 6.4);
    final bounds = Rect.fromPoints(from, to).inflate(width * 1.6);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: compact ? 0.06 : 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width + 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from + Offset(0, width * 0.24),
        to + Offset(0, width * 0.24), shadowPaint);
    final musclePaint = Paint()
      ..shader = LinearGradient(
        colors: active
            ? [
                accentPaint.color.withValues(alpha: 0.92),
                bodyPaint.color.withValues(alpha: 0.72),
              ]
            : [
                bodyPaint.color.withValues(alpha: 0.76),
                bodyPaint.color.withValues(alpha: 0.42),
              ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from, to, musclePaint);
    if (!compact) {
      canvas.drawLine(
        from,
        to,
        Paint()
          ..color = surfaceColor.withValues(alpha: active ? 0.38 : 0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, width * 0.18)
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawBiomechanicsGrid(Canvas canvas, Size size, Paint guidePaint) {
    final gridPaint = Paint()
      ..color = guidePaint.color.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (var fraction = 0.22; fraction < 0.86; fraction += 0.16) {
      canvas.drawLine(
        Offset(size.width * 0.08, size.height * fraction),
        Offset(size.width * 0.92, size.height * fraction),
        gridPaint,
      );
    }
  }

  void _drawTorsoBiomechanics(
    Canvas canvas,
    Offset shoulder,
    Offset hip,
    double scale,
  ) {
    final normal = _normalVector(shoulder, hip);
    final path = Path()
      ..moveTo(
        shoulder.dx + normal.dx * 13 * scale,
        shoulder.dy + normal.dy * 13 * scale,
      )
      ..lineTo(
        shoulder.dx - normal.dx * 11 * scale,
        shoulder.dy - normal.dy * 11 * scale,
      )
      ..lineTo(hip.dx - normal.dx * 15 * scale, hip.dy - normal.dy * 15 * scale)
      ..lineTo(hip.dx + normal.dx * 13 * scale, hip.dy + normal.dy * 13 * scale)
      ..close();
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          metric == RunningCoachMetric.posture
              ? accentColor.withValues(alpha: 0.84)
              : mutedColor.withValues(alpha: 0.70),
          mutedColor.withValues(alpha: 0.34),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(path.getBounds().inflate(6 * scale));
    canvas.drawPath(
      path.shift(Offset(0, 2 * scale)),
      Paint()..color = Colors.black.withValues(alpha: 0.10),
    );
    canvas.drawPath(path, paint);
    canvas.drawPath(
      path,
      Paint()
        ..color = mutedColor.withValues(alpha: 0.58)
        ..style = PaintingStyle.stroke
        ..strokeWidth = compact ? 0.8 : 1.2,
    );
  }

  Offset _normalVector(Offset from, Offset to) {
    final direction = to - from;
    final length = direction.distance;
    if (length == 0) {
      return Offset.zero;
    }
    return Offset(-direction.dy / length, direction.dx / length);
  }

  void _drawAngleArc(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double startRadians,
    required double sweepRadians,
    required Paint paint,
  }) {
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startRadians,
      sweepRadians,
      false,
      paint,
    );
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    canvas.drawLine(from, to, paint);
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    final size = compact ? 6.0 : 8.0;
    final first = Offset(
      to.dx - math.cos(angle - math.pi / 6) * size,
      to.dy - math.sin(angle - math.pi / 6) * size,
    );
    final second = Offset(
      to.dx - math.cos(angle + math.pi / 6) * size,
      to.dy - math.sin(angle + math.pi / 6) * size,
    );
    canvas.drawLine(to, first, paint);
    canvas.drawLine(to, second, paint);
  }

  @override
  bool shouldRepaint(covariant _RunningInsightGuidePainter oldDelegate) {
    return oldDelegate.metric != metric ||
        oldDelegate.finding != finding ||
        oldDelegate.status != status ||
        oldDelegate.surfaceColor != surfaceColor ||
        oldDelegate.mutedColor != mutedColor ||
        oldDelegate.guideColor != guideColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.compact != compact;
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
            if (result.denseSamples.attemptedFrames > 0 ||
                result.contactWindows.isNotEmpty) ...[
              const SizedBox(height: 16),
              _DenseContactEvidencePanel(result: result),
            ],
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
            for (var index = 0;
                index < prioritizedInsights.length;
                index += 1) ...[
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

class _DenseContactEvidencePanel extends StatelessWidget {
  final RunningVideoAnalysisResult result;

  const _DenseContactEvidencePanel({required this.result});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final contactTimes = result.validatedContactFrameTimestamps;
    final contactTimesText = contactTimes.isEmpty
        ? l10n.runningCoachDenseContactUnavailable
        : contactTimes.take(4).map(_formatContactTimestamp).join(', ');
    return Container(
      key: const ValueKey('running-coach-dense-contact-evidence'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.tertiary.withValues(alpha: 0.24)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.runningCoachDenseContactEvidenceTitle,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.runningCoachDenseContactEvidenceBody,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatChip(
                label: l10n.runningCoachDenseContactCoarseSamplesLabel,
                value:
                    '${result.coarseSamples.validFrames}/${result.coarseSamples.attemptedFrames}',
              ),
              _StatChip(
                label: l10n.runningCoachDenseContactDenseSamplesLabel,
                value:
                    '${result.denseSamples.validFrames}/${result.denseSamples.attemptedFrames}',
              ),
              _StatChip(
                label: l10n.runningCoachDenseContactWindowsLabel,
                value: '${result.contactWindows.length}',
              ),
              _StatChip(
                label: l10n.runningCoachDenseContactFramesLabel,
                value: '${contactTimes.length}',
              ),
              _StatChip(
                label: l10n.runningCoachDenseContactConfidenceLabel,
                value:
                    '${(result.contactConfidence * 100).clamp(0, 100).toStringAsFixed(0)}%',
              ),
              _StatChip(
                label: l10n.runningCoachDenseContactTimesLabel,
                value: contactTimesText,
              ),
            ],
          ),
        ],
      ),
    );
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
            const SizedBox(height: 12),
            _InsightGuideVisual(insight: insight),
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
          Text(
            copy.title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            copy.value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: insight.score / 100,
              minHeight: 8,
              color: accent,
              backgroundColor: accent.withAlpha(30),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ScoreBadge(score: insight.score),
              _QualityBadge(quality: insight.quality),
              if (priority != null) _PriorityBadge(priority: priority!),
            ],
          ),
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
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
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
          AppLocalizations.of(
            context,
          )!
              .runningCoachConfidenceLabel(quality.confidencePercent),
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

String _qualityReasonText(BuildContext context, RunningMetricQuality quality) {
  final l10n = AppLocalizations.of(context)!;
  return switch (quality.reason) {
    'low_coverage' => l10n.runningCoachQualityReasonLowCoverage,
    'limited_samples' => l10n.runningCoachQualityReasonLimitedSamples,
    'contact_phase_proxy' => l10n.runningCoachQualityReasonContactPhaseProxy,
    'low_confidence' => l10n.runningCoachQualityReasonLowConfidence,
    _ => l10n.runningCoachQualityReasonGeneric,
  };
}

String _sessionSourceLabel(
  AppLocalizations l10n,
  RunningCoachSessionAnalysis session,
) {
  return switch (session.source) {
    RunningCoachSessionSource.uploadVideo =>
      l10n.runningCoachSessionSourceUploadVideo,
    RunningCoachSessionSource.liveRun => l10n.runningCoachSessionSourceLiveRun,
    RunningCoachSessionSource.sprintLive =>
      l10n.runningCoachSessionSourceSprintLive,
  };
}

IconData _metricGuideIcon(RunningCoachMetric metric) {
  return switch (metric) {
    RunningCoachMetric.posture => Icons.accessibility_new_rounded,
    RunningCoachMetric.bounce => Icons.height_rounded,
    RunningCoachMetric.footStrike => Icons.directions_run_rounded,
    RunningCoachMetric.kneeFlexion => Icons.sports_gymnastics_rounded,
    RunningCoachMetric.armCarriage => Icons.sync_alt_rounded,
  };
}

Color _statusAccentColor(RunningCoachStatus status) {
  return switch (status) {
    RunningCoachStatus.good => Colors.green.shade700,
    RunningCoachStatus.watch => Colors.orange.shade700,
    RunningCoachStatus.needsWork => Colors.red.shade700,
  };
}

String _metricGoodRange(AppLocalizations l10n, RunningCoachMetric metric) {
  return switch (metric) {
    RunningCoachMetric.posture => l10n.runningCoachGuideRangePosture,
    RunningCoachMetric.bounce => l10n.runningCoachGuideRangeBounce,
    RunningCoachMetric.footStrike => l10n.runningCoachGuideRangeFootStrike,
    RunningCoachMetric.kneeFlexion => l10n.runningCoachGuideRangeKnee,
    RunningCoachMetric.armCarriage => l10n.runningCoachGuideRangeArm,
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
