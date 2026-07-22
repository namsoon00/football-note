import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../application/live_sprint_calibration_readiness_service.dart';
import '../../application/live_sprint_calibration_candidate_service.dart';
import '../../application/live_sprint_field_validation_matrix_service.dart';
import '../../application/live_sprint_trend_service.dart';
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
import 'running_live_session_result_screen.dart';
import '../widgets/app_bar_action_button.dart';
import '../widgets/app_feedback.dart';
import '../widgets/live_sprint_trend_card.dart';

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
  final LiveSprintTrendService _liveSprintTrendService =
      const LiveSprintTrendService();
  final LiveSprintCalibrationReadinessService
      _liveSprintCalibrationReadinessService =
      const LiveSprintCalibrationReadinessService();
  final LiveSprintFieldValidationMatrixService
      _liveSprintFieldValidationMatrixService =
      const LiveSprintFieldValidationMatrixService();
  final LiveSprintCalibrationCandidateService
      _liveSprintCalibrationCandidateService =
      const LiveSprintCalibrationCandidateService();

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
    final trendSummary = _liveSprintTrendService.build(_recentSessions);
    return ListView(
      key: const PageStorageKey('running-coach-simple-page'),
      padding: const EdgeInsets.all(16),
      children: [
        _HeroCard(
          title: l10n.runningCoachHeroTitle,
          body: l10n.runningCoachHeroBody,
        ),
        if (trendSummary.hasLiveSessions) ...[
          const SizedBox(height: 12),
          LiveSprintTrendCard(
            summary: trendSummary,
            cardKey: const ValueKey('running-coach-live-trend-card'),
          ),
        ],
        const SizedBox(height: 12),
        _RunningMissionCard(
          mission: mission,
          onStartLiveSprintCoach: () => unawaited(_openLiveCoach()),
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

  Future<void> _openLiveCoach() async {
    final optionRepository = widget.optionRepository;
    final sportId = optionRepository == null
        ? null
        : SportService(optionRepository).currentSportId();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => RunningLiveCoachScreen(
          optionRepository: optionRepository,
          sportId: sportId,
        ),
      ),
    );
    if (!mounted || _historyService == null) {
      return;
    }
    setState(() {
      _recentSessions = _historyService!.allSessions();
    });
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
    final trendSummary = _liveSprintTrendService.build(
      _recentSessions,
      currentSessionId: session.id,
    );
    final calibrationReadinessSummary =
        _liveSprintCalibrationReadinessService.build(
      _recentSessions,
      currentSessionId: session.id,
    );
    final fieldValidationMatrixSummary =
        _liveSprintFieldValidationMatrixService.build(
      _recentSessions,
      currentSessionId: session.id,
    );
    final calibrationCandidateSummary =
        _liveSprintCalibrationCandidateService.build(
      _recentSessions,
      currentSessionId: session.id,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => session.liveSprintReport == null
            ? _AnalysisHistoryDetailScreen(session: session)
            : RunningLiveSessionResultScreen(
                session: session,
                trendSummary: trendSummary,
                calibrationReadinessSummary: calibrationReadinessSummary,
                fieldValidationMatrixSummary: fieldValidationMatrixSummary,
                calibrationCandidateSummary: calibrationCandidateSummary,
              ),
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
      'video_too_blurry' => l10n.runningCoachVideoTooBlurry,
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
  final VoidCallback onStartLiveSprintCoach;

  const _RunningMissionCard({
    required this.mission,
    required this.onStartLiveSprintCoach,
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
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.center_focus_strong_outlined,
                      size: 20,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.runningCoachLiveSetupTitle,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.runningCoachLiveSetupBody,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
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
                FilledButton.icon(
                  onPressed: onStartLiveSprintCoach,
                  icon: const Icon(Icons.bolt_outlined),
                  label: Text(l10n.runningCoachMissionStartSprint),
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
                                              l10n,
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

String _formatContactTimestamp(
  AppLocalizations l10n,
  Duration timestamp,
) {
  final seconds = timestamp.inMilliseconds / 1000.0;
  return l10n.runningCoachContactTimestampSeconds(
    seconds.toStringAsFixed(2),
  );
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
  final RunningCoachMetric? highlightedMetric;
  final RunningCoachFinding? finding;
  final RunningDirection direction;
  final bool useContainFit;

  const _RunningPoseOverlayPainter({
    required this.poseFrame,
    required this.primaryColor,
    required this.secondaryColor,
    required this.contactColor,
    required this.warningColor,
    this.highlightedMetric,
    this.finding,
    this.direction = RunningDirection.stationary,
    this.useContainFit = false,
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
    final metric = highlightedMetric;
    if (metric != null) {
      _drawMetricGuide(canvas, size, frame, metric);
    }
  }

  void _drawMetricGuide(
    Canvas canvas,
    Size size,
    RunningPoseFrame frame,
    RunningCoachMetric metric,
  ) {
    final accent = _usesWarningAccent ? warningColor : contactColor;
    final accentPaint = Paint()
      ..color = accent.withValues(alpha: 0.94)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, size.shortestSide * 0.009)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final guidePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.76)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, size.shortestSide * 0.0048)
      ..strokeCap = StrokeCap.round;

    switch (metric) {
      case RunningCoachMetric.posture:
        final torso = _torsoPoints(size, frame);
        if (torso == null) return;
        final verticalTop = torso.hip - Offset(0, size.shortestSide * 0.20);
        _drawDashedLine(
          canvas,
          verticalTop,
          torso.hip + Offset(0, size.shortestSide * 0.055),
          guidePaint,
        );
        canvas.drawLine(torso.hip, torso.shoulder, accentPaint);
        _drawMetricArc(
          canvas: canvas,
          center: torso.hip,
          start: verticalTop,
          end: torso.shoulder,
          radius: math.max(14, size.shortestSide * 0.075),
          paint: accentPaint,
        );
      case RunningCoachMetric.bounce:
        final torso = _torsoPoints(size, frame);
        if (torso == null) return;
        final horizontalOffset = direction == RunningDirection.rightToLeft
            ? -size.shortestSide * 0.10
            : size.shortestSide * 0.10;
        final x = torso.shoulder.dx + horizontalOffset;
        final upper = Offset(x, torso.shoulder.dy - size.shortestSide * 0.065);
        final lower = Offset(x, torso.shoulder.dy + size.shortestSide * 0.065);
        _drawDoubleArrow(canvas, upper, lower, accentPaint);
        canvas.drawLine(
          Offset(x - size.shortestSide * 0.032, upper.dy),
          Offset(x + size.shortestSide * 0.032, upper.dy),
          guidePaint,
        );
        canvas.drawLine(
          Offset(x - size.shortestSide * 0.032, lower.dy),
          Offset(x + size.shortestSide * 0.032, lower.dy),
          guidePaint,
        );
      case RunningCoachMetric.footStrike:
        final torso = _torsoPoints(size, frame);
        final leg = _leadLegPoints(size, frame);
        if (torso == null || leg == null) return;
        final groundY = math.max(leg.toe.dy, leg.ankle.dy);
        final targetWidth = math.max(18.0, size.shortestSide * 0.11);
        final target = Rect.fromCenter(
          center: Offset(torso.hip.dx, groundY),
          width: targetWidth,
          height: math.max(12.0, size.shortestSide * 0.042),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(target, const Radius.circular(999)),
          Paint()..color = contactColor.withValues(alpha: 0.24),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(target, const Radius.circular(999)),
          guidePaint,
        );
        _drawDashedLine(
          canvas,
          torso.hip,
          Offset(torso.hip.dx, groundY),
          guidePaint,
        );
        canvas.drawLine(
          Offset(torso.hip.dx, groundY),
          leg.toe,
          accentPaint,
        );
        _drawFocusPoint(canvas, leg.toe, accent, size);
      case RunningCoachMetric.kneeFlexion:
        final leg = _leadLegPoints(size, frame);
        if (leg == null) return;
        canvas.drawLine(leg.hip, leg.knee, accentPaint);
        canvas.drawLine(leg.knee, leg.ankle, accentPaint);
        _drawMetricArc(
          canvas: canvas,
          center: leg.knee,
          start: leg.hip,
          end: leg.ankle,
          radius: math.max(14, size.shortestSide * 0.065),
          paint: accentPaint,
        );
        _drawFocusPoint(canvas, leg.knee, accent, size);
      case RunningCoachMetric.armCarriage:
        final arm = _leadArmPoints(size, frame);
        if (arm == null) return;
        canvas.drawLine(arm.shoulder, arm.elbow, accentPaint);
        canvas.drawLine(arm.elbow, arm.wrist, accentPaint);
        _drawMetricArc(
          canvas: canvas,
          center: arm.elbow,
          start: arm.shoulder,
          end: arm.wrist,
          radius: math.max(12, size.shortestSide * 0.058),
          paint: accentPaint,
        );
        _drawFocusPoint(canvas, arm.elbow, accent, size);
    }
  }

  bool get _usesWarningAccent => switch (finding) {
        RunningCoachFinding.postureAligned ||
        RunningCoachFinding.bounceEfficient ||
        RunningCoachFinding.footStrikeUnderBody ||
        RunningCoachFinding.kneeFlexionLoaded ||
        RunningCoachFinding.armCompact =>
          false,
        _ => true,
      };

  ({Offset shoulder, Offset hip})? _torsoPoints(
    Size size,
    RunningPoseFrame frame,
  ) {
    final leftShoulder = _pointForIndex(size, frame, 11);
    final rightShoulder = _pointForIndex(size, frame, 12);
    final leftHip = _pointForIndex(size, frame, 23);
    final rightHip = _pointForIndex(size, frame, 24);
    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null) {
      return null;
    }
    return (
      shoulder: Offset.lerp(leftShoulder, rightShoulder, 0.5)!,
      hip: Offset.lerp(leftHip, rightHip, 0.5)!,
    );
  }

  ({Offset hip, Offset knee, Offset ankle, Offset toe})? _leadLegPoints(
    Size size,
    RunningPoseFrame frame,
  ) {
    final left = _legPointsForSide(size, frame, isLeft: true);
    final right = _legPointsForSide(size, frame, isLeft: false);
    if (left == null) return right;
    if (right == null) return left;
    return switch (direction) {
      RunningDirection.leftToRight =>
        left.toe.dx >= right.toe.dx ? left : right,
      RunningDirection.rightToLeft =>
        left.toe.dx <= right.toe.dx ? left : right,
      RunningDirection.stationary => left.toe.dy >= right.toe.dy ? left : right,
    };
  }

  ({Offset hip, Offset knee, Offset ankle, Offset toe})? _legPointsForSide(
    Size size,
    RunningPoseFrame frame, {
    required bool isLeft,
  }) {
    final hip = _pointForIndex(size, frame, isLeft ? 23 : 24);
    final knee = _pointForIndex(size, frame, isLeft ? 25 : 26);
    final ankle = _pointForIndex(size, frame, isLeft ? 27 : 28);
    if (hip == null || knee == null || ankle == null) return null;
    final toe = _pointForIndex(size, frame, isLeft ? 31 : 32) ?? ankle;
    return (hip: hip, knee: knee, ankle: ankle, toe: toe);
  }

  ({Offset shoulder, Offset elbow, Offset wrist})? _leadArmPoints(
    Size size,
    RunningPoseFrame frame,
  ) {
    final left = _armPointsForSide(size, frame, isLeft: true);
    final right = _armPointsForSide(size, frame, isLeft: false);
    if (left == null) return right;
    if (right == null) return left;
    return switch (direction) {
      RunningDirection.leftToRight =>
        left.wrist.dx >= right.wrist.dx ? left : right,
      RunningDirection.rightToLeft =>
        left.wrist.dx <= right.wrist.dx ? left : right,
      RunningDirection.stationary =>
        left.elbow.dy >= right.elbow.dy ? left : right,
    };
  }

  ({Offset shoulder, Offset elbow, Offset wrist})? _armPointsForSide(
    Size size,
    RunningPoseFrame frame, {
    required bool isLeft,
  }) {
    final shoulder = _pointForIndex(size, frame, isLeft ? 11 : 12);
    final elbow = _pointForIndex(size, frame, isLeft ? 13 : 14);
    final wrist = _pointForIndex(size, frame, isLeft ? 15 : 16);
    if (shoulder == null || elbow == null || wrist == null) return null;
    return (shoulder: shoulder, elbow: elbow, wrist: wrist);
  }

  Offset? _pointForIndex(Size size, RunningPoseFrame frame, int index) {
    final landmark = frame.landmarkByIndex(index);
    if (landmark == null ||
        landmark.confidence < runningPoseOverlayMinimumJointConfidence) {
      return null;
    }
    return _coverPoint(size, frame, landmark);
  }

  void _drawFocusPoint(Canvas canvas, Offset point, Color color, Size size) {
    final radius = math.max(5.0, size.shortestSide * 0.018);
    canvas.drawCircle(
      point,
      radius * 1.8,
      Paint()..color = color.withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      point,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.6, radius * 0.34),
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    final distance = (end - start).distance;
    if (distance <= 0) return;
    final direction = (end - start) / distance;
    const dashLength = 6.0;
    const gapLength = 4.0;
    for (var offset = 0.0;
        offset < distance;
        offset += dashLength + gapLength) {
      canvas.drawLine(
        start + direction * offset,
        start + direction * math.min(offset + dashLength, distance),
        paint,
      );
    }
  }

  void _drawMetricArc({
    required Canvas canvas,
    required Offset center,
    required Offset start,
    required Offset end,
    required double radius,
    required Paint paint,
  }) {
    final startAngle = math.atan2(start.dy - center.dy, start.dx - center.dx);
    final endAngle = math.atan2(end.dy - center.dy, end.dx - center.dx);
    var sweep = (endAngle - startAngle) % (math.pi * 2);
    if (sweep > math.pi) sweep -= math.pi * 2;
    if (sweep < -math.pi) sweep += math.pi * 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      paint,
    );
  }

  void _drawDoubleArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    final direction = (end - start);
    if (direction.distance <= 0) return;
    final unit = direction / direction.distance;
    final perpendicular = Offset(-unit.dy, unit.dx);
    const arrowSize = 7.0;
    for (final point in <Offset>[start, end]) {
      final facing = point == start ? unit : -unit;
      final base = point + facing * arrowSize;
      canvas.drawLine(point, base + perpendicular * (arrowSize * 0.58), paint);
      canvas.drawLine(point, base - perpendicular * (arrowSize * 0.58), paint);
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
    if (useContainFit) {
      return runningPoseContainOffset(
        landmark: landmark,
        imageWidth: frame.imageWidth,
        imageHeight: frame.imageHeight,
        outputSize: size,
      );
    }
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
        oldDelegate.warningColor != warningColor ||
        oldDelegate.highlightedMetric != highlightedMetric ||
        oldDelegate.finding != finding ||
        oldDelegate.direction != direction ||
        oldDelegate.useContainFit != useContainFit;
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
    final isMetricReliable = !insight.quality.isLowConfidence;
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
                          text: isMetricReliable
                              ? l10n.runningCoachMetricScore(
                                  session.primaryScore,
                                )
                              : l10n.runningCoachEvidenceQualityLimitedBadge,
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
    final primaryInsight = report.primaryFocus ??
        (report.rankedInsights.isEmpty ? null : report.rankedInsights.first);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.runningCoachAnalysisResultScreenTitle)),
      body: ListView(
        key: const ValueKey('running-coach-analysis-result-list'),
        padding: const EdgeInsets.all(16),
        children: [
          if (primaryInsight != null) ...[
            _BeginnerActionCard(insight: primaryInsight),
            const SizedBox(height: 12),
            _AnalysisEvidenceCard(
              result: result,
              session: session,
              insight: primaryInsight,
            ),
            const SizedBox(height: 12),
          ],
          _ResultsSummaryCard(result: result, report: report),
          const SizedBox(height: 12),
          Text(
            l10n.runningCoachResultDetailsTitle,
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
              result: result,
            ),
            if (sectionIndex != insightSections.length - 1)
              const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _BeginnerActionCard extends StatelessWidget {
  final RunningCoachingInsight insight;

  const _BeginnerActionCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final copy = RunningCoachInsightCopy.fromInsight(insight, l10n);
    final needsChange = insight.status != RunningCoachStatus.good;
    final foreground =
        needsChange ? scheme.onPrimaryContainer : scheme.onTertiaryContainer;
    final background =
        needsChange ? scheme.primaryContainer : scheme.tertiaryContainer;
    final actionTitle = needsChange
        ? l10n.runningCoachResultOneChangeTitle
        : l10n.runningCoachMaintainTitle;
    final actionBody = needsChange
        ? l10n.runningCoachResultOneChangeBody
        : l10n.runningCoachResultKeepOneThingBody;
    return Semantics(
      container: true,
      label: actionTitle,
      child: Container(
        key: const ValueKey('running-coach-beginner-action-card'),
        width: double.infinity,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: foreground.withValues(alpha: 0.18)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  needsChange
                      ? Icons.directions_run_rounded
                      : Icons.check_circle_outline_rounded,
                  color: foreground,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    actionTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              copy.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.runningCoachResultNextRunCueLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              copy.cue,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              actionBody,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisEvidenceCard extends StatefulWidget {
  final RunningVideoAnalysisResult result;
  final RunningCoachSessionAnalysis session;
  final RunningCoachingInsight insight;

  const _AnalysisEvidenceCard({
    required this.result,
    required this.session,
    required this.insight,
  });

  @override
  State<_AnalysisEvidenceCard> createState() => _AnalysisEvidenceCardState();
}

class _AnalysisEvidenceCardState extends State<_AnalysisEvidenceCard> {
  VideoPlayerController? _controller;
  bool _isVideoReady = false;
  bool _isVideoUnavailable = false;
  late List<_AnalysisEvidenceFrame> _evidenceFrames;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _evidenceFrames = _analysisEvidenceFramesFor(
      result: widget.result,
      insight: widget.insight,
    );
    unawaited(_initializeVideo());
  }

  @override
  void didUpdateWidget(covariant _AnalysisEvidenceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result != widget.result ||
        oldWidget.insight != widget.insight) {
      _evidenceFrames = _analysisEvidenceFramesFor(
        result: widget.result,
        insight: widget.insight,
      );
      _selectedIndex = 0;
    }
    if (oldWidget.session.videoPath != widget.session.videoPath) {
      unawaited(_controller?.dispose());
      _controller = null;
      _isVideoReady = false;
      _isVideoUnavailable = false;
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
      setState(() => _isVideoUnavailable = true);
      return;
    }
    try {
      final file = File(path);
      if (!await file.exists()) {
        if (!mounted) return;
        setState(() => _isVideoUnavailable = true);
        return;
      }
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _isVideoReady = true;
      });
      _seekToSelectedFrame();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isVideoUnavailable = true);
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
      await controller.seekTo(_selectedFrame.timestamp);
      await controller.play();
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _selectFrame(int index) {
    if (_evidenceFrames.isEmpty) {
      return;
    }
    setState(() {
      _selectedIndex = index.clamp(0, _evidenceFrames.length - 1);
    });
    _seekToSelectedFrame();
  }

  Future<void> _seekToSelectedFrame() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    await controller.pause();
    await controller.seekTo(_selectedFrame.timestamp);
    if (mounted) {
      setState(() {});
    }
  }

  _AnalysisEvidenceFrame get _selectedFrame =>
      _evidenceFrames[_selectedIndex.clamp(0, _evidenceFrames.length - 1)];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final copy = RunningCoachInsightCopy.fromInsight(widget.insight, l10n);
    final gate = _metricEvidenceGate(widget.result, widget.insight);

    return Card(
      key: const ValueKey('running-coach-analysis-evidence-card'),
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
                  gate.isReliable
                      ? Icons.fact_check_outlined
                      : Icons.video_camera_back_outlined,
                  color: gate.isReliable ? scheme.primary : scheme.error,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gate.isReliable
                            ? l10n.runningCoachEvidenceTitle
                            : l10n.runningCoachEvidenceInsufficientTitle,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        gate.isReliable
                            ? l10n.runningCoachEvidenceBody
                            : l10n.runningCoachEvidenceInsufficientBody,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!gate.isReliable || _evidenceFrames.isEmpty)
              _EvidenceRetakePanel(gate: gate)
            else ...[
              _EvidenceVideoPreview(
                result: widget.result,
                insight: widget.insight,
                selectedFrame: _selectedFrame,
                controller: _isVideoReady ? _controller : null,
                isVideoUnavailable: _isVideoUnavailable,
              ),
              const SizedBox(height: 10),
              _EvidenceFrameCaption(
                frame: _selectedFrame,
                value: copy.value,
              ),
              const SizedBox(height: 10),
              _EvidenceControls(
                frames: _evidenceFrames,
                selectedIndex: _selectedIndex,
                isPlaying: _controller?.value.isPlaying ?? false,
                onPrevious: () => _selectFrame(_selectedIndex - 1),
                onNext: () => _selectFrame(_selectedIndex + 1),
                onPlayPause: _togglePlayback,
                onScrub: _selectNearestEvidenceFrame,
              ),
              const SizedBox(height: 12),
              _EvidenceTextPanel(
                insight: widget.insight,
                copy: copy,
                timestamp: _selectedFrame.timestamp,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _selectNearestEvidenceFrame(double timestampMs) {
    if (_evidenceFrames.isEmpty) {
      return;
    }
    var nearestIndex = 0;
    var nearestDistance =
        (_evidenceFrames.first.timestamp.inMilliseconds - timestampMs.round())
            .abs();
    for (var index = 1; index < _evidenceFrames.length; index += 1) {
      final distance = (_evidenceFrames[index].timestamp.inMilliseconds -
              timestampMs.round())
          .abs();
      if (distance < nearestDistance) {
        nearestIndex = index;
        nearestDistance = distance;
      }
    }
    _selectFrame(nearestIndex);
  }
}

class _EvidenceVideoPreview extends StatelessWidget {
  final RunningVideoAnalysisResult result;
  final RunningCoachingInsight insight;
  final _AnalysisEvidenceFrame selectedFrame;
  final VideoPlayerController? controller;
  final bool isVideoUnavailable;

  const _EvidenceVideoPreview({
    required this.result,
    required this.insight,
    required this.selectedFrame,
    required this.controller,
    required this.isVideoUnavailable,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final videoController = controller;
    final poseAspectRatio = selectedFrame.poseFrame == null
        ? 16 / 9
        : selectedFrame.poseFrame!.imageWidth /
            selectedFrame.poseFrame!.imageHeight;
    final aspectRatio = (videoController?.value.aspectRatio ?? poseAspectRatio)
        .clamp(0.45, 2.2)
        .toDouble();
    return LayoutBuilder(
      builder: (context, constraints) {
        final maximumHeight = math.min(
          320.0,
          MediaQuery.sizeOf(context).height * 0.44,
        );
        final naturalHeight = constraints.maxWidth / aspectRatio;
        final previewHeight = math.min(naturalHeight, maximumHeight);
        final previewWidth = math.min(
          constraints.maxWidth,
          previewHeight * aspectRatio,
        );
        return Center(
          child: SizedBox(
            key: const ValueKey('running-coach-analysis-evidence-preview'),
            width: previewWidth,
            height: previewHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (videoController != null &&
                        videoController.value.isInitialized)
                      FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: videoController.value.size.width,
                          height: videoController.value.size.height,
                          child: VideoPlayer(videoController),
                        ),
                      )
                    else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            isVideoUnavailable
                                ? l10n.runningCoachEvidenceVideoUnavailable
                                : l10n.runningCoachEvidencePoseFrameOnly,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.white70),
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation:
                              videoController ?? kAlwaysDismissedAnimation,
                          builder: (context, _) {
                            final position = videoController?.value.position ??
                                selectedFrame.timestamp;
                            final poseFrame = runningPoseFrameAtPosition(
                                  frames: result.poseFrames,
                                  position: position,
                                ) ??
                                selectedFrame.poseFrame;
                            return CustomPaint(
                              key: const ValueKey(
                                'running-coach-analysis-evidence-overlay',
                              ),
                              painter: _RunningPoseOverlayPainter(
                                poseFrame: poseFrame,
                                primaryColor: scheme.primary,
                                secondaryColor: scheme.secondary,
                                contactColor: scheme.tertiary,
                                warningColor: scheme.error,
                                highlightedMetric: insight.metric,
                                finding: insight.finding,
                                direction: result.direction,
                                useContainFit: true,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EvidenceFrameCaption extends StatelessWidget {
  final _AnalysisEvidenceFrame frame;
  final String value;

  const _EvidenceFrameCaption({required this.frame, required this.value});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('running-coach-analysis-evidence-caption'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.straighten_rounded, size: 18, color: scheme.primary),
              Text(
                l10n.runningCoachEvidenceTimestamp(
                  _formatContactTimestamp(l10n, frame.timestamp),
                ),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                frame.label(l10n),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            l10n.runningCoachEvidenceOverlayBody,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _EvidenceControls extends StatelessWidget {
  final List<_AnalysisEvidenceFrame> frames;
  final int selectedIndex;
  final bool isPlaying;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPlayPause;
  final ValueChanged<double> onScrub;

  const _EvidenceControls({
    required this.frames,
    required this.selectedIndex,
    required this.isPlaying,
    required this.onPrevious,
    required this.onNext,
    required this.onPlayPause,
    required this.onScrub,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selected = frames[selectedIndex.clamp(0, frames.length - 1)];
    final minMs = frames.first.timestamp.inMilliseconds.toDouble();
    final maxMs = frames.last.timestamp.inMilliseconds.toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton.filledTonal(
              key: const ValueKey('running-coach-evidence-previous'),
              tooltip: l10n.runningCoachEvidencePreviousFrame,
              onPressed: selectedIndex <= 0 ? null : onPrevious,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              key: const ValueKey('running-coach-evidence-play-pause'),
              tooltip: isPlaying
                  ? l10n.runningCoachEvidencePause
                  : l10n.runningCoachEvidencePlay,
              onPressed: onPlayPause,
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              key: const ValueKey('running-coach-evidence-next'),
              tooltip: l10n.runningCoachEvidenceNextFrame,
              onPressed: selectedIndex >= frames.length - 1 ? null : onNext,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.runningCoachEvidenceFrameCount(
                  selectedIndex + 1,
                  frames.length,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
        Slider(
          key: const ValueKey('running-coach-evidence-scrubber'),
          min: minMs,
          max: math.max(minMs + 1, maxMs),
          divisions: frames.length > 1 ? frames.length - 1 : null,
          value: selected.timestamp.inMilliseconds
              .clamp(minMs.round(), math.max(minMs + 1, maxMs).round())
              .toDouble(),
          onChanged: frames.length <= 1 ? null : onScrub,
        ),
      ],
    );
  }
}

class _EvidenceTextPanel extends StatelessWidget {
  final RunningCoachingInsight insight;
  final RunningCoachInsightCopy copy;
  final Duration timestamp;

  const _EvidenceTextPanel({
    required this.insight,
    required this.copy,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _GuideTextRow(
          icon: Icons.visibility_outlined,
          label: l10n.runningCoachEvidenceWhatSeenLabel,
          body: l10n.runningCoachEvidenceWhatSeenBody(
            copy.title,
            _formatContactTimestamp(l10n, timestamp),
          ),
        ),
        const SizedBox(height: 10),
        _GuideTextRow(
          icon: Icons.info_outline_rounded,
          label: l10n.runningCoachEvidenceWhyMattersLabel,
          body: copy.summary,
        ),
        const SizedBox(height: 10),
        _GuideTextRow(
          icon: Icons.flag_outlined,
          label: l10n.runningCoachEvidenceTryLabel,
          body: copy.cue,
        ),
        const SizedBox(height: 10),
        _GuideTextRow(
          icon: Icons.video_camera_back_outlined,
          label: l10n.runningCoachEvidenceRetakeLabel,
          body: l10n.runningCoachEvidenceRetakeBody,
        ),
      ],
    );
  }
}

class _EvidenceRetakePanel extends StatelessWidget {
  final _MetricEvidenceGate gate;

  const _EvidenceRetakePanel({required this.gate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('running-coach-analysis-evidence-retake'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.error.withValues(alpha: 0.28)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GuideTextRow(
            icon: Icons.visibility_off_outlined,
            label: l10n.runningCoachEvidenceQualityLimitedBadge,
            body: _evidenceGateReasonText(l10n, gate.reason),
          ),
          const SizedBox(height: 10),
          _GuideTextRow(
            icon: Icons.video_camera_back_outlined,
            label: l10n.runningCoachEvidenceRetakeLabel,
            body: l10n.runningCoachEvidenceRetakeBody,
          ),
        ],
      ),
    );
  }
}

class _AnalysisEvidenceFrame {
  final Duration timestamp;
  final RunningCoachMetric metric;
  final RunningPoseFrame? poseFrame;
  final bool isContact;

  const _AnalysisEvidenceFrame({
    required this.timestamp,
    required this.metric,
    required this.poseFrame,
    this.isContact = false,
  });

  String label(AppLocalizations l10n) {
    if (isContact) {
      return l10n.runningCoachEvidenceContactLabel;
    }
    return switch (metric) {
      RunningCoachMetric.posture => l10n.runningCoachEvidencePostureLabel,
      RunningCoachMetric.bounce => l10n.runningCoachEvidenceBounceLabel,
      RunningCoachMetric.footStrike => l10n.runningCoachEvidenceLandingLabel,
      RunningCoachMetric.kneeFlexion => l10n.runningCoachEvidenceKneeLabel,
      RunningCoachMetric.armCarriage => l10n.runningCoachEvidenceArmLabel,
    };
  }
}

enum _MetricEvidenceGateReason {
  ready,
  lowConfidence,
  limitedFrames,
  missingPoseFrames,
  missingContact,
}

class _MetricEvidenceGate {
  final bool isReliable;
  final _MetricEvidenceGateReason reason;

  const _MetricEvidenceGate({
    required this.isReliable,
    required this.reason,
  });
}

_MetricEvidenceGate _metricEvidenceGate(
  RunningVideoAnalysisResult result,
  RunningCoachingInsight insight,
) {
  final quality = result.qualityFor(insight.metric) ?? insight.quality;
  if (quality.confidence < 0.65 || quality.isLowConfidence) {
    return const _MetricEvidenceGate(
      isReliable: false,
      reason: _MetricEvidenceGateReason.lowConfidence,
    );
  }
  if (result.poseFrames.isEmpty) {
    return const _MetricEvidenceGate(
      isReliable: false,
      reason: _MetricEvidenceGateReason.missingPoseFrames,
    );
  }
  final minimumSamples = switch (insight.metric) {
    RunningCoachMetric.footStrike || RunningCoachMetric.kneeFlexion => 2,
    RunningCoachMetric.posture ||
    RunningCoachMetric.bounce ||
    RunningCoachMetric.armCarriage =>
      5,
  };
  if (quality.sampleCount < minimumSamples) {
    return const _MetricEvidenceGate(
      isReliable: false,
      reason: _MetricEvidenceGateReason.limitedFrames,
    );
  }
  if ((insight.metric == RunningCoachMetric.footStrike ||
          insight.metric == RunningCoachMetric.kneeFlexion) &&
      (result.contactWindows.isEmpty ||
          result.validatedContactFrameTimestamps.isEmpty)) {
    return const _MetricEvidenceGate(
      isReliable: false,
      reason: _MetricEvidenceGateReason.missingContact,
    );
  }
  return const _MetricEvidenceGate(
    isReliable: true,
    reason: _MetricEvidenceGateReason.ready,
  );
}

String _evidenceGateReasonText(
  AppLocalizations l10n,
  _MetricEvidenceGateReason reason,
) {
  return switch (reason) {
    _MetricEvidenceGateReason.lowConfidence =>
      l10n.runningCoachEvidenceReasonLowConfidence,
    _MetricEvidenceGateReason.limitedFrames =>
      l10n.runningCoachEvidenceReasonLimitedFrames,
    _MetricEvidenceGateReason.missingPoseFrames =>
      l10n.runningCoachEvidenceReasonMissingPoseFrames,
    _MetricEvidenceGateReason.missingContact =>
      l10n.runningCoachEvidenceReasonMissingContact,
    _MetricEvidenceGateReason.ready => l10n.runningCoachEvidenceBody,
  };
}

List<_AnalysisEvidenceFrame> _analysisEvidenceFramesFor({
  required RunningVideoAnalysisResult result,
  required RunningCoachingInsight insight,
}) {
  if (result.poseFrames.isEmpty) {
    return const <_AnalysisEvidenceFrame>[];
  }

  final timestamps = <Duration>[];
  final isContactMetric = insight.metric == RunningCoachMetric.footStrike ||
      insight.metric == RunningCoachMetric.kneeFlexion;
  if (isContactMetric) {
    for (final window in result.contactWindows.take(3)) {
      if (window.validatedContactTimestamps.isNotEmpty) {
        timestamps.add(window.validatedContactTimestamps.first);
      } else {
        timestamps.add(window.center);
      }
    }
    if (timestamps.isEmpty) {
      timestamps.addAll(result.validatedContactFrameTimestamps.take(3));
    }
  } else if (insight.metric == RunningCoachMetric.bounce) {
    final frames = result.poseFrames;
    timestamps
      ..add(frames.first.timestamp)
      ..add(frames[frames.length ~/ 2].timestamp)
      ..add(frames.last.timestamp);
  } else {
    final frames = result.poseFrames;
    timestamps.add(frames[frames.length ~/ 2].timestamp);
    if (frames.length >= 3) {
      timestamps
        ..add(frames[frames.length ~/ 3].timestamp)
        ..add(frames[(frames.length * 2) ~/ 3].timestamp);
    }
  }

  final uniqueMs = <int>{};
  final evidence = <_AnalysisEvidenceFrame>[];
  for (final timestamp in timestamps) {
    if (!uniqueMs.add(timestamp.inMilliseconds)) {
      continue;
    }
    final poseFrame = runningPoseFrameAtPosition(
      frames: result.poseFrames,
      position: timestamp,
    );
    evidence.add(
      _AnalysisEvidenceFrame(
        timestamp: poseFrame?.timestamp ?? timestamp,
        metric: insight.metric,
        poseFrame: poseFrame,
        isContact: isContactMetric,
      ),
    );
  }
  if (evidence.isEmpty) {
    final fallback = result.poseFrames[result.poseFrames.length ~/ 2];
    evidence.add(
      _AnalysisEvidenceFrame(
        timestamp: fallback.timestamp,
        metric: insight.metric,
        poseFrame: fallback,
      ),
    );
  }
  evidence.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return List<_AnalysisEvidenceFrame>.unmodifiable(evidence.take(4));
}

class _AnalysisHistoryDetailScreen extends StatelessWidget {
  final RunningCoachSessionAnalysis session;

  const _AnalysisHistoryDetailScreen({required this.session});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final insight = session.primaryInsight;
    final copy = RunningCoachInsightCopy.fromInsight(insight, l10n);
    final isMetricReliable = !insight.quality.isLowConfidence;
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
                        value: isMetricReliable
                            ? '${session.primaryScore}'
                            : l10n.runningCoachEvidenceQualityLimitedBadge,
                      ),
                      _StatChip(
                        label: l10n.runningCoachMetricValueLabel,
                        value: isMetricReliable
                            ? copy.value
                            : l10n.runningCoachEvidenceQualityLimitedBadge,
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
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(8),
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
                  Icons.track_changes_outlined,
                  size: 18,
                  color: scheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.runningCoachTargetGuideTitle,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _metricGoodRange(l10n, insight.metric),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: ColoredBox(
                  color: scheme.surface.withValues(alpha: 0.34),
                  child: _RunningTargetGuideArtwork(insight: insight),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.runningCoachTargetGuideBody,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunningTargetGuideArtwork extends StatelessWidget {
  final RunningCoachingInsight insight;
  final bool compact;

  const _RunningTargetGuideArtwork({
    required this.insight,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final targetAsset = _targetGuideAssetFor(insight.metric);
    final fallback = CustomPaint(
      painter: _RunningInsightGuidePainter(
        metric: insight.metric,
        finding: insight.finding,
        status: insight.status,
        surfaceColor: scheme.surface,
        mutedColor: scheme.outline,
        guideColor: scheme.primary.withValues(alpha: 0.28),
        accentColor: scheme.primary,
        compact: compact,
      ),
    );

    return Semantics(
      image: true,
      child: AspectRatio(
        aspectRatio: compact ? 1 : 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              targetAsset,
              key: ValueKey(
                'running-coach-target-guide-artwork-${insight.metric.name}',
              ),
              fit: compact ? BoxFit.cover : BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => fallback,
            ),
            if (!compact)
              IgnorePointer(
                child: CustomPaint(
                  painter: _RunningTargetGuideAnnotationPainter(
                    metric: insight.metric,
                    accentColor: scheme.primary,
                    guideColor: scheme.primary.withValues(alpha: 0.38),
                    mutedColor: scheme.outline.withValues(alpha: 0.52),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _targetGuideAssetFor(RunningCoachMetric metric) {
  return switch (metric) {
    RunningCoachMetric.posture =>
      'assets/images/running_guides/target_posture.png',
    RunningCoachMetric.armCarriage =>
      'assets/images/running_guides/target_posture.png',
    RunningCoachMetric.bounce =>
      'assets/images/running_guides/target_landing.png',
    RunningCoachMetric.footStrike =>
      'assets/images/running_guides/target_landing.png',
    RunningCoachMetric.kneeFlexion =>
      'assets/images/running_guides/target_landing.png',
  };
}

class _RunningTargetGuideAnnotationPainter extends CustomPainter {
  final RunningCoachMetric metric;
  final Color accentColor;
  final Color guideColor;
  final Color mutedColor;

  const _RunningTargetGuideAnnotationPainter({
    required this.metric,
    required this.accentColor,
    required this.guideColor,
    required this.mutedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final isLandingGuide = metric != RunningCoachMetric.posture &&
        metric != RunningCoachMetric.armCarriage;
    Offset point(double x, double y) => Offset(size.width * x, size.height * y);
    final shoulder = point(
      isLandingGuide ? 0.54 : 0.545,
      isLandingGuide ? 0.20 : 0.185,
    );
    final hip = point(
      isLandingGuide ? 0.515 : 0.489,
      isLandingGuide ? 0.43 : 0.42,
    );
    final knee = point(
      isLandingGuide ? 0.60 : 0.613,
      isLandingGuide ? 0.60 : 0.59,
    );
    final ankle = point(
      isLandingGuide ? 0.56 : 0.555,
      isLandingGuide ? 0.85 : 0.79,
    );
    final frontElbow = point(
      isLandingGuide ? 0.62 : 0.64,
      isLandingGuide ? 0.32 : 0.35,
    );
    final frontHand = point(
      isLandingGuide ? 0.67 : 0.69,
      isLandingGuide ? 0.29 : 0.28,
    );
    final basePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, size.shortestSide * 0.014)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final guidePaint = Paint()
      ..color = guideColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, size.shortestSide * 0.007)
      ..strokeCap = StrokeCap.round;

    switch (metric) {
      case RunningCoachMetric.posture:
        _drawFocusRing(canvas, shoulder, basePaint);
        _drawFocusRing(canvas, hip, basePaint);
        _drawFocusRing(canvas, ankle, basePaint);
        _drawDashedLine(
          canvas,
          ankle + Offset(-size.width * 0.014, 0),
          shoulder + Offset(size.width * 0.012, 0),
          guidePaint,
        );
      case RunningCoachMetric.bounce:
        final top = point(0.24, 0.32);
        final bottom = point(0.24, 0.56);
        _drawDoubleArrow(canvas, top, bottom, basePaint);
        final band = Rect.fromCenter(
          center: hip,
          width: size.width * 0.17,
          height: size.height * 0.11,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(band, Radius.circular(band.height / 2)),
          Paint()..color = accentColor.withValues(alpha: 0.13),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(band, Radius.circular(band.height / 2)),
          guidePaint,
        );
        _drawFocusRing(canvas, hip, basePaint);
      case RunningCoachMetric.footStrike:
        final groundY = size.height * 0.91;
        final landingZone = Rect.fromCenter(
          center: Offset(hip.dx, groundY),
          width: size.width * 0.18,
          height: math.max(12.0, size.height * 0.06),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            landingZone,
            Radius.circular(landingZone.height / 2),
          ),
          Paint()..color = accentColor.withValues(alpha: 0.14),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            landingZone,
            Radius.circular(landingZone.height / 2),
          ),
          basePaint,
        );
        _drawDashedLine(
          canvas,
          hip,
          Offset(hip.dx, groundY - landingZone.height * 0.54),
          guidePaint,
        );
        _drawFocusRing(canvas, ankle, basePaint);
      case RunningCoachMetric.kneeFlexion:
        _drawFocusRing(canvas, knee, basePaint);
        canvas.drawArc(
          Rect.fromCircle(
            center: knee,
            radius: math.max(18.0, size.shortestSide * 0.14),
          ),
          -2.1,
          1.2,
          false,
          basePaint,
        );
        canvas.drawLine(knee, hip, guidePaint);
        canvas.drawLine(knee, ankle, guidePaint);
      case RunningCoachMetric.armCarriage:
        _drawFocusRing(canvas, shoulder, basePaint);
        _drawFocusRing(canvas, frontElbow, basePaint);
        _drawCurvedArrow(
          canvas,
          shoulder + Offset(-size.width * 0.055, size.height * 0.025),
          frontHand,
          basePaint,
        );
    }
  }

  void _drawFocusRing(Canvas canvas, Offset center, Paint paint) {
    final outer = paint.strokeWidth * 2.25;
    canvas.drawCircle(
      center,
      outer,
      Paint()..color = paint.color.withValues(alpha: 0.15),
    );
    canvas.drawCircle(center, outer, paint);
    canvas.drawCircle(
      center,
      math.max(2.0, paint.strokeWidth * 0.6),
      Paint()..color = paint.color,
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset from,
    Offset to,
    Paint paint,
  ) {
    final vector = to - from;
    final distance = vector.distance;
    if (distance == 0) return;
    final direction = vector / distance;
    const dash = 7.0;
    const gap = 5.0;
    for (var offset = 0.0; offset < distance; offset += dash + gap) {
      canvas.drawLine(
        from + direction * offset,
        from + direction * math.min(offset + dash, distance),
        paint,
      );
    }
  }

  void _drawDoubleArrow(
    Canvas canvas,
    Offset from,
    Offset to,
    Paint paint,
  ) {
    canvas.drawLine(from, to, paint);
    _drawArrowHead(canvas, from, to - from, paint);
    _drawArrowHead(canvas, to, from - to, paint);
  }

  void _drawCurvedArrow(
    Canvas canvas,
    Offset from,
    Offset to,
    Paint paint,
  ) {
    final control = Offset(
      (from.dx + to.dx) / 2,
      math.min(from.dy, to.dy) - (to - from).distance * 0.18,
    );
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);
    canvas.drawPath(path, paint);
    _drawArrowHead(canvas, to, to - control, paint);
  }

  void _drawArrowHead(
    Canvas canvas,
    Offset tip,
    Offset direction,
    Paint paint,
  ) {
    final length = direction.distance;
    if (length == 0) return;
    final unit = direction / length;
    final perpendicular = Offset(-unit.dy, unit.dx);
    final head = paint.strokeWidth * 3.2;
    canvas.drawLine(
        tip, tip - unit * head + perpendicular * (head * 0.5), paint);
    canvas.drawLine(
        tip, tip - unit * head - perpendicular * (head * 0.5), paint);
  }

  @override
  bool shouldRepaint(
      covariant _RunningTargetGuideAnnotationPainter oldDelegate) {
    return oldDelegate.metric != metric ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.guideColor != guideColor ||
        oldDelegate.mutedColor != mutedColor;
  }
}

class _MeasuredPoseGuideVisual extends StatelessWidget {
  final RunningCoachingInsight insight;
  final RunningPoseFrame poseFrame;
  final RunningDirection direction;

  const _MeasuredPoseGuideVisual({
    required this.insight,
    required this.poseFrame,
    required this.direction,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final copy = RunningCoachInsightCopy.fromInsight(insight, l10n);
    final actualAccent = scheme.error;
    final targetAccent = scheme.primary;
    return Container(
      key: ValueKey(
        'running-coach-insight-evidence-diagram-${insight.metric.name}',
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.runningCoachMeasuredPoseTitle,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.runningCoachMeasuredPoseBody,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PoseMovementLabel(
                  icon: Icons.radio_button_checked_rounded,
                  color: actualAccent,
                  label: l10n.runningCoachMeasuredPoseActualLabel,
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PoseMovementLabel(
                  icon: Icons.adjust_rounded,
                  color: targetAccent,
                  label: l10n.runningCoachMeasuredPoseTargetLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            key: ValueKey(
              'running-coach-insight-change-map-${insight.metric.name}',
            ),
            height: 264,
            width: double.infinity,
            child: CustomPaint(
              painter: _MeasuredPoseMovementMapPainter(
                frame: poseFrame,
                insight: insight,
                direction: direction,
                surfaceColor: scheme.surface,
                mutedColor: scheme.outline,
                actualAccent: actualAccent,
                targetAccent: targetAccent,
              ),
            ),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              color: targetAccent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.near_me_outlined,
                    size: 18,
                    color: targetAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.runningCoachMeasuredPoseCueLabel,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: targetAccent,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          copy.cue,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.runningCoachMeasuredPoseFootnote,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PoseMovementLabel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _PoseMovementLabel({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}

class _MeasuredPoseMovementMapPainter extends CustomPainter {
  final RunningPoseFrame frame;
  final RunningCoachingInsight insight;
  final RunningDirection direction;
  final Color surfaceColor;
  final Color mutedColor;
  final Color actualAccent;
  final Color targetAccent;

  const _MeasuredPoseMovementMapPainter({
    required this.frame,
    required this.insight,
    required this.direction,
    required this.surfaceColor,
    required this.mutedColor,
    required this.actualAccent,
    required this.targetAccent,
  });

  RunningCoachMetric get metric => insight.metric;

  bool get _needsMovement => insight.status != RunningCoachStatus.good;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final panel = Offset.zero & size;
    _drawPanel(canvas, panel);
    final actualPoints = _mapPoints(panel);
    if (actualPoints.isEmpty) return;
    _drawGround(canvas, panel, actualPoints);
    _drawSkeleton(
      canvas,
      actualPoints,
      focusColor: actualAccent,
      baseColor: mutedColor,
    );
    _drawMovementMap(canvas, panel, actualPoints);
  }

  void _drawPanel(Canvas canvas, Rect rect) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(
      rrect,
      Paint()..color = surfaceColor.withValues(alpha: 0.52),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = mutedColor.withValues(alpha: 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawGround(
    Canvas canvas,
    Rect panel,
    Map<int, Offset> points,
  ) {
    final contactPoints = <Offset>[
      if (points[31] case final Offset point) point,
      if (points[32] case final Offset point) point,
      if (points[27] case final Offset point) point,
      if (points[28] case final Offset point) point,
    ];
    final lowestContact = contactPoints.isEmpty
        ? panel.top + panel.height * 0.78
        : contactPoints
            .map((point) => point.dy)
            .reduce((current, next) => math.max(current, next));
    final groundY = math.min(
      panel.bottom - 16,
      math.max(panel.top + panel.height * 0.66, lowestContact + 8),
    );
    canvas.drawLine(
      Offset(panel.left + 14, groundY),
      Offset(panel.right - 14, groundY),
      Paint()
        ..color = mutedColor.withValues(alpha: 0.32)
        ..strokeWidth = 1.4,
    );
  }

  Map<int, Offset> _mapPoints(Rect panel) {
    final visible = frame.landmarks
        .where(
          (landmark) =>
              landmark.confidence >= runningPoseOverlayMinimumJointConfidence,
        )
        .toList(growable: false);
    if (visible.isEmpty) return const <int, Offset>{};

    var minX = visible.first.x;
    var maxX = visible.first.x;
    var minY = visible.first.y;
    var maxY = visible.first.y;
    for (final landmark in visible.skip(1)) {
      minX = math.min(minX, landmark.x);
      maxX = math.max(maxX, landmark.x);
      minY = math.min(minY, landmark.y);
      maxY = math.max(maxY, landmark.y);
    }
    final bodyWidth = math.max(0.08, maxX - minX);
    final bodyHeight = math.max(0.12, maxY - minY);
    final content = panel.deflate(22);
    final scale =
        math.min(content.width / bodyWidth, content.height / bodyHeight);
    final displayWidth = bodyWidth * scale;
    final displayHeight = bodyHeight * scale;
    final origin = Offset(
      content.left + (content.width - displayWidth) / 2 - minX * scale,
      content.top + (content.height - displayHeight) / 2 - minY * scale,
    );
    return <int, Offset>{
      for (final landmark in visible)
        landmark.index: origin + Offset(landmark.x * scale, landmark.y * scale),
    };
  }

  void _drawSkeleton(
    Canvas canvas,
    Map<int, Offset> points, {
    required Color focusColor,
    required Color baseColor,
  }) {
    final focus = _focusIndices;
    for (final connection in _mediaPipePoseConnections) {
      final first = points[connection.first];
      final second = points[connection.second];
      if (first == null || second == null) continue;
      final active =
          focus.contains(connection.first) || focus.contains(connection.second);
      canvas.drawLine(
        first,
        second,
        Paint()
          ..color = (active ? focusColor : baseColor).withValues(
            alpha: active ? 0.92 : 0.48,
          )
          ..strokeWidth = active ? 3.4 : 2.1
          ..strokeCap = StrokeCap.round,
      );
    }
    for (final entry in points.entries) {
      final active = focus.contains(entry.key);
      final radius = entry.key <= 10 ? 2.3 : 3.1;
      canvas.drawCircle(
        entry.value,
        radius,
        Paint()
          ..color = (active ? focusColor : baseColor).withValues(
            alpha: active ? 0.96 : 0.62,
          ),
      );
    }
  }

  Set<int> get _focusIndices => switch (metric) {
        RunningCoachMetric.posture => const <int>{11, 12, 23, 24},
        RunningCoachMetric.bounce => const <int>{
            11,
            12,
            23,
            24,
            25,
            26,
            27,
            28
          },
        RunningCoachMetric.footStrike => const <int>{
            23,
            24,
            25,
            26,
            27,
            28,
            29,
            30,
            31,
            32
          },
        RunningCoachMetric.kneeFlexion => const <int>{23, 24, 25, 26, 27, 28},
        RunningCoachMetric.armCarriage => const <int>{11, 12, 13, 14, 15, 16},
      };

  void _drawMovementMap(
    Canvas canvas,
    Rect panel,
    Map<int, Offset> points,
  ) {
    switch (metric) {
      case RunningCoachMetric.posture:
        _drawPostureMovement(canvas, panel, points);
      case RunningCoachMetric.bounce:
        _drawBounceMovement(canvas, panel, points);
      case RunningCoachMetric.footStrike:
        _drawFootStrikeMovement(canvas, panel, points);
      case RunningCoachMetric.kneeFlexion:
        _drawKneeMovement(canvas, panel, points);
      case RunningCoachMetric.armCarriage:
        _drawArmMovement(canvas, panel, points);
    }
  }

  void _drawPostureMovement(
    Canvas canvas,
    Rect panel,
    Map<int, Offset> points,
  ) {
    final torso = _torso(points);
    if (torso == null) return;
    final torsoLength = math.max(32.0, (torso.shoulder - torso.hip).distance);
    final verticalTop = _constrainPoint(
      panel,
      torso.hip - Offset(0, torsoLength),
    );
    const targetLeanRadians = 10 * math.pi / 180;
    final targetShoulder = _constrainPoint(
      panel,
      torso.hip +
          Offset(
            _forwardSign(torso) * torsoLength * math.sin(targetLeanRadians),
            -torsoLength * math.cos(targetLeanRadians),
          ),
    );
    final targetPaint = _stroke(targetAccent, width: 3.2);
    _drawDashedLine(
      canvas,
      verticalTop,
      torso.hip,
      _stroke(mutedColor, width: 1.4, opacity: 0.50),
    );
    final targetFan = Path()
      ..moveTo(torso.hip.dx, torso.hip.dy)
      ..lineTo(verticalTop.dx, verticalTop.dy)
      ..lineTo(targetShoulder.dx, targetShoulder.dy)
      ..close();
    canvas.drawPath(
      targetFan,
      Paint()..color = targetAccent.withValues(alpha: 0.12),
    );
    canvas.drawLine(torso.hip, targetShoulder, targetPaint);
    _drawArc(
      canvas,
      torso.hip,
      verticalTop,
      targetShoulder,
      math.min(24, torsoLength * 0.28),
      targetPaint,
    );
    _drawCurrentDot(canvas, torso.shoulder);
    _drawTargetDot(canvas, targetShoulder);
    if (_needsMovement) {
      _drawDirectionalArrow(
        canvas,
        torso.shoulder,
        targetShoulder,
        targetPaint,
      );
    }
  }

  void _drawBounceMovement(
    Canvas canvas,
    Rect panel,
    Map<int, Offset> points,
  ) {
    final torso = _torso(points);
    if (torso == null) return;
    final markerSign = _annotationSign(
      panel,
      torso.shoulder,
      _forwardSign(torso),
    );
    final currentSpan = (panel.height * (insight.value / 100) * 2.6)
        .clamp(36.0, 96.0)
        .toDouble();
    final targetSpan = _needsMovement
        ? (currentSpan * 0.48).clamp(20.0, 42.0).toDouble()
        : currentSpan;
    final currentX = _constrainPoint(
      panel,
      Offset(
        torso.shoulder.dx + markerSign * math.min(panel.width * 0.08, 24),
        torso.shoulder.dy,
      ),
    ).dx;
    final targetX = _constrainPoint(
      panel,
      Offset(
        currentX + markerSign * math.min(panel.width * 0.17, 48),
        torso.shoulder.dy,
      ),
    ).dx;
    final currentPaint = _stroke(actualAccent, width: 2.8);
    final targetPaint = _stroke(targetAccent, width: 2.4);
    _drawDoubleArrow(
      canvas,
      Offset(currentX, torso.shoulder.dy - currentSpan / 2),
      Offset(currentX, torso.shoulder.dy + currentSpan / 2),
      currentPaint,
    );
    _drawCurrentDot(canvas, Offset(currentX, torso.shoulder.dy));
    final targetRect = Rect.fromCenter(
      center: Offset(targetX, torso.shoulder.dy),
      width: 18,
      height: targetSpan,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(targetRect, const Radius.circular(99)),
      Paint()..color = targetAccent.withValues(alpha: 0.22),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(targetRect, const Radius.circular(99)),
      targetPaint,
    );
    if (_needsMovement) {
      _drawDirectionalArrow(
        canvas,
        Offset(currentX, torso.shoulder.dy),
        Offset(targetX, torso.shoulder.dy),
        targetPaint,
      );
    }
  }

  void _drawFootStrikeMovement(
    Canvas canvas,
    Rect panel,
    Map<int, Offset> points,
  ) {
    final torso = _torso(points);
    final leg = _leadLeg(points);
    if (torso == null || leg == null) return;
    final groundY = math.min(
      panel.bottom - 18,
      math.max(
        panel.top + panel.height * 0.66,
        math.max(leg.toe.dy, leg.ankle.dy) + 8,
      ),
    );
    final targetCenter = _constrainPoint(
      panel,
      Offset(torso.hip.dx, groundY - 7),
    );
    final targetRect = Rect.fromCenter(
      center: targetCenter,
      width: math.min(panel.width * 0.30, 96),
      height: 16,
    );
    final targetPaint = _stroke(targetAccent, width: 2.2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(targetRect, const Radius.circular(99)),
      Paint()..color = targetAccent.withValues(alpha: 0.22),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(targetRect, const Radius.circular(99)),
      targetPaint,
    );
    _drawDashedLine(
      canvas,
      torso.hip,
      Offset(torso.hip.dx, targetCenter.dy),
      _stroke(targetAccent, width: 1.6, opacity: 0.70),
    );
    _drawCurrentDot(canvas, leg.toe);
    if (_needsMovement) {
      _drawDirectionalArrow(canvas, leg.toe, targetCenter, targetPaint);
    }
  }

  void _drawKneeMovement(
    Canvas canvas,
    Rect panel,
    Map<int, Offset> points,
  ) {
    final leg = _leadLeg(points);
    if (leg == null) return;
    final targetAngle =
        _needsMovement ? 155.0 : insight.value.clamp(60.0, 175.0).toDouble();
    final targetAnkle = _targetJointPoint(
      pivot: leg.knee,
      fixed: leg.hip,
      moving: leg.ankle,
      targetAngleDegrees: targetAngle,
      panel: panel,
    );
    if (targetAnkle == null) return;
    final targetPaint = _stroke(targetAccent, width: 2.6);
    _drawDashedLine(canvas, leg.knee, targetAnkle, targetPaint);
    _drawArc(
      canvas,
      leg.knee,
      leg.ankle,
      targetAnkle,
      math.min(30, (leg.ankle - leg.knee).distance * 0.32),
      targetPaint,
    );
    _drawCurrentDot(canvas, leg.ankle);
    _drawTargetDot(canvas, targetAnkle);
    if (_needsMovement) {
      _drawCurvedArrow(canvas, leg.ankle, targetAnkle, targetPaint);
    }
  }

  void _drawArmMovement(
    Canvas canvas,
    Rect panel,
    Map<int, Offset> points,
  ) {
    final arm = _leadArm(points);
    if (arm == null) return;
    final targetAngle =
        _needsMovement ? 90.0 : insight.value.clamp(50.0, 135.0).toDouble();
    final targetWrist = _targetJointPoint(
      pivot: arm.elbow,
      fixed: arm.shoulder,
      moving: arm.wrist,
      targetAngleDegrees: targetAngle,
      panel: panel,
    );
    if (targetWrist == null) return;
    final targetPaint = _stroke(targetAccent, width: 2.6);
    _drawDashedLine(canvas, arm.elbow, targetWrist, targetPaint);
    _drawArc(
      canvas,
      arm.elbow,
      arm.wrist,
      targetWrist,
      math.min(28, (arm.wrist - arm.elbow).distance * 0.34),
      targetPaint,
    );
    final laneHalfWidth = math.min(28.0, panel.width * 0.10);
    _drawDoubleArrow(
      canvas,
      targetWrist - Offset(laneHalfWidth, 0),
      targetWrist + Offset(laneHalfWidth, 0),
      _stroke(targetAccent, width: 1.8, opacity: 0.76),
    );
    _drawCurrentDot(canvas, arm.wrist);
    _drawTargetDot(canvas, targetWrist);
    if (_needsMovement) {
      _drawCurvedArrow(canvas, arm.wrist, targetWrist, targetPaint);
    }
  }

  ({Offset shoulder, Offset hip})? _torso(Map<int, Offset> points) {
    final leftShoulder = points[11];
    final rightShoulder = points[12];
    final leftHip = points[23];
    final rightHip = points[24];
    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null) {
      return null;
    }
    return (
      shoulder: Offset.lerp(leftShoulder, rightShoulder, 0.5)!,
      hip: Offset.lerp(leftHip, rightHip, 0.5)!,
    );
  }

  ({Offset hip, Offset knee, Offset ankle, Offset toe})? _leadLeg(
    Map<int, Offset> points,
  ) {
    final left = _leg(points, isLeft: true);
    final right = _leg(points, isLeft: false);
    if (left == null) return right;
    if (right == null) return left;
    return switch (direction) {
      RunningDirection.leftToRight =>
        left.toe.dx >= right.toe.dx ? left : right,
      RunningDirection.rightToLeft =>
        left.toe.dx <= right.toe.dx ? left : right,
      RunningDirection.stationary => left.toe.dy >= right.toe.dy ? left : right,
    };
  }

  ({Offset hip, Offset knee, Offset ankle, Offset toe})? _leg(
    Map<int, Offset> points, {
    required bool isLeft,
  }) {
    final hip = points[isLeft ? 23 : 24];
    final knee = points[isLeft ? 25 : 26];
    final ankle = points[isLeft ? 27 : 28];
    if (hip == null || knee == null || ankle == null) return null;
    final toe = points[isLeft ? 31 : 32] ?? ankle;
    return (hip: hip, knee: knee, ankle: ankle, toe: toe);
  }

  ({Offset shoulder, Offset elbow, Offset wrist})? _leadArm(
    Map<int, Offset> points,
  ) {
    final left = _arm(points, isLeft: true);
    final right = _arm(points, isLeft: false);
    if (left == null) return right;
    if (right == null) return left;
    return switch (direction) {
      RunningDirection.leftToRight =>
        left.wrist.dx >= right.wrist.dx ? left : right,
      RunningDirection.rightToLeft =>
        left.wrist.dx <= right.wrist.dx ? left : right,
      RunningDirection.stationary =>
        left.elbow.dy >= right.elbow.dy ? left : right,
    };
  }

  ({Offset shoulder, Offset elbow, Offset wrist})? _arm(
    Map<int, Offset> points, {
    required bool isLeft,
  }) {
    final shoulder = points[isLeft ? 11 : 12];
    final elbow = points[isLeft ? 13 : 14];
    final wrist = points[isLeft ? 15 : 16];
    if (shoulder == null || elbow == null || wrist == null) return null;
    return (shoulder: shoulder, elbow: elbow, wrist: wrist);
  }

  double _forwardSign(({Offset shoulder, Offset hip}) torso) {
    return switch (direction) {
      RunningDirection.leftToRight => 1,
      RunningDirection.rightToLeft => -1,
      RunningDirection.stationary => torso.shoulder.dx >= torso.hip.dx ? 1 : -1,
    };
  }

  Paint _stroke(
    Color color, {
    required double width,
    double opacity = 1,
  }) {
    return Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
  }

  double _annotationSign(Rect panel, Offset anchor, double preferred) {
    final room =
        preferred >= 0 ? panel.right - anchor.dx : anchor.dx - panel.left;
    return room >= panel.width * 0.24 ? preferred : -preferred;
  }

  Offset _constrainPoint(Rect panel, Offset point, {double inset = 10}) {
    final bounds = panel.deflate(inset);
    return Offset(
      point.dx.clamp(bounds.left, bounds.right).toDouble(),
      point.dy.clamp(bounds.top, bounds.bottom).toDouble(),
    );
  }

  Offset? _targetJointPoint({
    required Offset pivot,
    required Offset fixed,
    required Offset moving,
    required double targetAngleDegrees,
    required Rect panel,
  }) {
    final fixedVector = fixed - pivot;
    final movingVector = moving - pivot;
    final fixedLength = fixedVector.distance;
    final movingLength = movingVector.distance;
    if (fixedLength < 1 || movingLength < 1) return null;
    final signedAngle = _signedAngle(fixedVector, movingVector);
    final turn = signedAngle.abs() < 0.001
        ? _fallbackTurnSign
        : signedAngle >= 0
            ? 1.0
            : -1.0;
    final targetRadians =
        targetAngleDegrees.clamp(1.0, 179.0).toDouble() * math.pi / 180;
    final fixedRadians = math.atan2(fixedVector.dy, fixedVector.dx);
    final targetVector = Offset(
      math.cos(fixedRadians + turn * targetRadians) * movingLength,
      math.sin(fixedRadians + turn * targetRadians) * movingLength,
    );
    return _constrainPoint(panel, pivot + targetVector);
  }

  double _signedAngle(Offset first, Offset second) {
    return math.atan2(
      first.dx * second.dy - first.dy * second.dx,
      first.dx * second.dx + first.dy * second.dy,
    );
  }

  double get _fallbackTurnSign => switch (direction) {
        RunningDirection.leftToRight => 1,
        RunningDirection.rightToLeft => -1,
        RunningDirection.stationary => 1,
      };

  void _drawCurrentDot(Canvas canvas, Offset point) {
    canvas.drawCircle(
      point,
      9,
      Paint()..color = actualAccent.withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      point,
      5.5,
      Paint()
        ..color = actualAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(point, 2.6, Paint()..color = actualAccent);
  }

  void _drawTargetDot(Canvas canvas, Offset point) {
    canvas.drawCircle(
      point,
      11,
      Paint()..color = targetAccent.withValues(alpha: 0.14),
    );
    canvas.drawCircle(
      point,
      6.5,
      Paint()
        ..color = targetAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    canvas.drawCircle(point, 2.6, Paint()..color = targetAccent);
  }

  void _drawDirectionalArrow(
    Canvas canvas,
    Offset from,
    Offset to,
    Paint paint,
  ) {
    final vector = to - from;
    final distance = vector.distance;
    if (distance < 20) return;
    final unit = vector / distance;
    final start = from + unit * 9;
    final end = to - unit * 11;
    canvas.drawLine(start, end, paint);
    _drawArrowHead(canvas, end, unit, paint);
  }

  void _drawCurvedArrow(
    Canvas canvas,
    Offset from,
    Offset to,
    Paint paint,
  ) {
    final vector = to - from;
    final distance = vector.distance;
    if (distance < 20) return;
    final unit = vector / distance;
    final start = from + unit * 9;
    final end = to - unit * 11;
    final perpendicular = Offset(-unit.dy, unit.dx);
    final control = Offset.lerp(start, end, 0.5)! +
        perpendicular * math.min(24, distance * 0.24);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
    canvas.drawPath(path, paint);
    _drawArrowHead(canvas, end, end - control, paint);
  }

  void _drawArrowHead(
    Canvas canvas,
    Offset tip,
    Offset direction,
    Paint paint,
  ) {
    final length = direction.distance;
    if (length == 0) return;
    final unit = direction / length;
    final perpendicular = Offset(-unit.dy, unit.dx);
    final head = math.max(7.0, paint.strokeWidth * 3.1);
    canvas.drawLine(
      tip,
      tip - unit * head + perpendicular * (head * 0.5),
      paint,
    );
    canvas.drawLine(
      tip,
      tip - unit * head - perpendicular * (head * 0.5),
      paint,
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    final vector = end - start;
    final distance = vector.distance;
    if (distance <= 0) return;
    final unit = vector / distance;
    for (var offset = 0.0; offset < distance; offset += 9) {
      canvas.drawLine(
        start + unit * offset,
        start + unit * math.min(offset + 5, distance),
        paint,
      );
    }
  }

  void _drawArc(
    Canvas canvas,
    Offset center,
    Offset start,
    Offset end,
    double radius,
    Paint paint,
  ) {
    final startAngle = math.atan2(start.dy - center.dy, start.dx - center.dx);
    final endAngle = math.atan2(end.dy - center.dy, end.dx - center.dx);
    var sweep = (endAngle - startAngle) % (math.pi * 2);
    if (sweep > math.pi) sweep -= math.pi * 2;
    if (sweep < -math.pi) sweep += math.pi * 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      paint,
    );
  }

  void _drawDoubleArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    final vector = end - start;
    final distance = vector.distance;
    if (distance <= 0) return;
    final unit = vector / distance;
    final perpendicular = Offset(-unit.dy, unit.dx);
    for (final point in <Offset>[start, end]) {
      final facing = point == start ? unit : -unit;
      final base = point + facing * 7;
      canvas.drawLine(point, base + perpendicular * 4, paint);
      canvas.drawLine(point, base - perpendicular * 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeasuredPoseMovementMapPainter oldDelegate) {
    return oldDelegate.frame != frame ||
        oldDelegate.insight != insight ||
        oldDelegate.direction != direction ||
        oldDelegate.surfaceColor != surfaceColor ||
        oldDelegate.mutedColor != mutedColor ||
        oldDelegate.actualAccent != actualAccent ||
        oldDelegate.targetAccent != targetAccent;
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: _RunningTargetGuideArtwork(
            insight: insight,
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
    if (size.isEmpty) {
      return;
    }

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    final horizontalPadding = compact ? 8.0 : 18.0;
    final verticalPadding = compact ? 8.0 : 12.0;
    final scale = math.min(
      math.max(1, size.width - horizontalPadding * 2) / 320,
      math.max(1, size.height - verticalPadding * 2) / 190,
    );
    final center = Offset(
      size.width * (compact ? 0.50 : 0.47),
      size.height * 0.55,
    );
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
      _drawCoachingDiagramBase(canvas, size, groundY, guidePaint);
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

    canvas.restore();
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

  void _drawCoachingDiagramBase(
    Canvas canvas,
    Size size,
    double groundY,
    Paint guidePaint,
  ) {
    final laneRect = Rect.fromLTRB(
      size.width * 0.08,
      groundY - 10,
      size.width * 0.92,
      groundY + 10,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(laneRect, const Radius.circular(10)),
      Paint()
        ..color = guidePaint.color.withValues(alpha: 0.10)
        ..style = PaintingStyle.fill,
    );

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
        : contactTimes
            .take(4)
            .map((timestamp) => _formatContactTimestamp(l10n, timestamp))
            .join(', ');
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
  final RunningVideoAnalysisResult result;

  const _InsightRegionSectionCard({
    required this.title,
    required this.insights,
    required this.priorities,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 10),
        for (var index = 0; index < insights.length; index += 1) ...[
          _InsightCard(
            insight: insights[index],
            priority: priorities[insights[index].metric],
            poseFrame: _detailPoseFrameFor(result, insights[index]),
            direction: result.direction,
          ),
          if (index != insights.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

RunningPoseFrame? _detailPoseFrameFor(
  RunningVideoAnalysisResult result,
  RunningCoachingInsight insight,
) {
  if (!_metricEvidenceGate(result, insight).isReliable) {
    return null;
  }
  final frames = _analysisEvidenceFramesFor(result: result, insight: insight);
  return frames.isEmpty ? null : frames.first.poseFrame;
}

class _InsightCard extends StatelessWidget {
  final RunningCoachingInsight insight;
  final int? priority;
  final RunningPoseFrame? poseFrame;
  final RunningDirection direction;

  const _InsightCard({
    required this.insight,
    required this.poseFrame,
    required this.direction,
    this.priority,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final copy = RunningCoachInsightCopy.fromInsight(insight, l10n);
    final isMetricReliable = !insight.quality.isLowConfidence;
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
                _ScoreBadge(
                  score: insight.score,
                  isReliable: isMetricReliable,
                ),
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
              value: isMetricReliable
                  ? copy.value
                  : l10n.runningCoachEvidenceQualityLimitedBadge,
            ),
            const SizedBox(height: 12),
            if (poseFrame != null)
              _MeasuredPoseGuideVisual(
                insight: insight,
                poseFrame: poseFrame!,
                direction: direction,
              )
            else
              _InsightGuideVisual(insight: insight),
            if (poseFrame != null &&
                insight.status != RunningCoachStatus.good) ...[
              const SizedBox(height: 12),
              _InsightGuideVisual(insight: insight),
            ],
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
    final l10n = AppLocalizations.of(context)!;
    final isMetricReliable = !insight.quality.isLowConfidence;
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
            isMetricReliable
                ? copy.value
                : l10n.runningCoachEvidenceQualityLimitedBadge,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          if (isMetricReliable) ...[
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
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ScoreBadge(
                score: insight.score,
                isReliable: isMetricReliable,
              ),
              _QualityBadge(quality: insight.quality),
              if (priority != null) _PriorityBadge(priority: priority!),
            ],
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
    final l10n = AppLocalizations.of(context)!;
    final label = isLow
        ? l10n.runningCoachEvidenceQualityLimitedBadge
        : quality.confidence >= 0.82
            ? l10n.runningCoachEvidenceQualityStableBadge
            : l10n.runningCoachEvidenceQualityCheckBadge;
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
          label,
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
  final bool isReliable;

  const _ScoreBadge({
    required this.score,
    this.isReliable = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            isReliable ? scheme.surfaceContainerHighest : scheme.errorContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isReliable ? scheme.outlineVariant : scheme.error,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          isReliable
              ? l10n.runningCoachMetricScore(score)
              : l10n.runningCoachEvidenceQualityLimitedBadge,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(
                color: isReliable ? null : scheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}
