import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/running_coach_history_service.dart';
import '../../application/running_coaching_service.dart';
import '../../application/running_growth_service.dart';
import '../../application/running_video_analysis_service.dart';
import '../../domain/entities/running_coach_session.dart';
import '../../domain/entities/running_video_analysis_result.dart';
import '../../domain/repositories/option_repository.dart';
import '../../gen/app_localizations.dart';
import '../models/sample_runner_pose.dart';
import 'running_coach_insight_copy.dart';
import 'running_live_coach_screen.dart';
import 'sprint_live_coaching_screen.dart';
import '../widgets/app_feedback.dart';

enum _RunningCoachSection { today, records, analysis }

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
  final TextEditingController _recordSecondsController =
      TextEditingController();

  RunningCoachHistoryService? _historyService;
  RunningGrowthService? _growthService;
  XFile? _selectedVideo;
  RunningVideoAnalysisResult? _analysisResult;
  RunningCoachingReport? _coachingReport;
  RunningGrowthSnapshot? _growthSnapshot;
  List<RunningCoachSessionAnalysis> _recentSessions =
      const <RunningCoachSessionAnalysis>[];
  RunningSprintDistance _selectedSprintDistance =
      RunningSprintDistance.twentyMeters;
  _RunningCoachSection _selectedSection = _RunningCoachSection.today;
  bool _isAnalyzing = false;
  bool _isSavingRecord = false;

  @override
  void initState() {
    super.initState();
    final optionRepository = widget.optionRepository;
    if (optionRepository != null) {
      _historyService = RunningCoachHistoryService(optionRepository);
      _growthService = RunningGrowthService(optionRepository);
      _recentSessions = _historyService!.allSessions();
      _growthSnapshot = _growthService!.snapshot();
    }
  }

  @override
  void dispose() {
    _recordSecondsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sections = _availableSections;
    final selectedSection =
        sections.contains(_selectedSection) ? _selectedSection : sections.first;
    final selectedIndex = sections.indexOf(selectedSection);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(l10n.runningCoachScreenTitle),
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: [
          for (final section in sections) _buildSectionPage(section, l10n),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedSection = sections[index]);
        },
        destinations: [
          for (final section in sections)
            NavigationDestination(
              icon: Icon(_sectionIcon(section)),
              selectedIcon: Icon(_sectionSelectedIcon(section)),
              label: _sectionLabel(l10n, section),
            ),
        ],
      ),
    );
  }

  List<_RunningCoachSection> get _availableSections => [
        _RunningCoachSection.today,
        if (_growthSnapshot != null) _RunningCoachSection.records,
        _RunningCoachSection.analysis,
      ];

  Widget _buildSectionPage(
    _RunningCoachSection section,
    AppLocalizations l10n,
  ) {
    return switch (section) {
      _RunningCoachSection.today => _buildTodayMissionPage(l10n),
      _RunningCoachSection.records => _buildRecordsPage(),
      _RunningCoachSection.analysis => _buildAnalysisPage(l10n),
    };
  }

  Widget _buildTodayMissionPage(AppLocalizations l10n) {
    final mission = _missionForToday(DateTime.now());
    return ListView(
      key: const PageStorageKey('running-coach-today-page'),
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
      ],
    );
  }

  Widget _buildRecordsPage() {
    final growthSnapshot = _growthSnapshot;
    if (growthSnapshot == null) {
      return const SizedBox.shrink();
    }
    return ListView(
      key: const PageStorageKey('running-coach-records-page'),
      padding: const EdgeInsets.all(16),
      children: [
        _RunningGrowthRecordCard(
          snapshot: growthSnapshot,
          selectedDistance: _selectedSprintDistance,
          secondsController: _recordSecondsController,
          isSaving: _isSavingRecord,
          onDistanceChanged: (distance) {
            setState(() => _selectedSprintDistance = distance);
          },
          onSave: _saveSprintRecord,
        ),
      ],
    );
  }

  Widget _buildAnalysisPage(AppLocalizations l10n) {
    final insightSections = _coachingReport == null
        ? const <_InsightRegionSection>[]
        : _buildInsightSections(l10n, _coachingReport!);
    final sampleResult = _sampleAnalysisResult();
    final sampleReport = _coachingService.buildReport(sampleResult);
    final mistakeSampleResult = _mistakeSampleAnalysisResult();
    final mistakeSampleReport = _coachingService.buildReport(
      mistakeSampleResult,
    );
    return ListView(
      key: const PageStorageKey('running-coach-analysis-page'),
      padding: const EdgeInsets.all(16),
      children: [
        _RunningCoachUploadGuideCard(
          title: l10n.runningCoachUploadGuideTitle,
          body: l10n.runningCoachUploadGuideBody,
          onShowSampleGuide: () => _showSampleAnalysis(
            l10n,
            result: sampleResult,
            report: sampleReport,
            mistakeResult: mistakeSampleResult,
            mistakeReport: mistakeSampleReport,
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
          for (var sectionIndex = 0;
              sectionIndex < insightSections.length;
              sectionIndex += 1) ...[
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
    );
  }

  IconData _sectionIcon(_RunningCoachSection section) {
    return switch (section) {
      _RunningCoachSection.today => Icons.flag_outlined,
      _RunningCoachSection.records => Icons.show_chart_outlined,
      _RunningCoachSection.analysis => Icons.video_camera_back_outlined,
    };
  }

  IconData _sectionSelectedIcon(_RunningCoachSection section) {
    return switch (section) {
      _RunningCoachSection.today => Icons.flag_rounded,
      _RunningCoachSection.records => Icons.show_chart_rounded,
      _RunningCoachSection.analysis => Icons.video_camera_back_rounded,
    };
  }

  String _sectionLabel(AppLocalizations l10n, _RunningCoachSection section) {
    return switch (section) {
      _RunningCoachSection.today => l10n.runningCoachSectionToday,
      _RunningCoachSection.records => l10n.runningCoachSectionRecords,
      _RunningCoachSection.analysis => l10n.runningCoachSectionAnalysis,
    };
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

  Future<void> _saveSprintRecord() async {
    final growthService = _growthService;
    if (growthService == null || _isSavingRecord) return;

    final l10n = AppLocalizations.of(context)!;
    final rawSeconds =
        _recordSecondsController.text.trim().replaceAll(',', '.');
    final seconds = double.tryParse(rawSeconds);
    if (seconds == null || seconds <= 0 || seconds > 60) {
      AppFeedback.showMessage(context, text: l10n.runningCoachRecordInvalid);
      return;
    }

    setState(() => _isSavingRecord = true);
    try {
      final snapshot = await growthService.saveRecord(
        distance: _selectedSprintDistance,
        seconds: seconds,
      );
      if (!mounted) return;
      setState(() {
        _growthSnapshot = snapshot;
        _recordSecondsController.clear();
      });
      AppFeedback.showMessage(context, text: l10n.runningCoachRecordSaved);
    } finally {
      if (mounted) {
        setState(() => _isSavingRecord = false);
      }
    }
  }

  Future<void> _showSampleAnalysis(
    AppLocalizations l10n, {
    required RunningVideoAnalysisResult result,
    required RunningCoachingReport report,
    required RunningVideoAnalysisResult mistakeResult,
    required RunningCoachingReport mistakeReport,
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
            result: result,
            report: report,
            mistakeResult: mistakeResult,
            mistakeReport: mistakeReport,
          ),
        ),
      ),
    );
  }

  RunningVideoAnalysisResult _sampleAnalysisResult() {
    return const RunningVideoAnalysisResult(
      videoDuration: Duration(seconds: 6),
      sampledFrames: 24,
      validFrames: 24,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 10,
      verticalBounceRatio: 0.06,
      footStrikeDistanceRatio: 0.08,
      stanceKneeAngleDegrees: 155,
      elbowAngleDegrees: 90,
      metricQualities: <RunningCoachMetric, RunningMetricQuality>{
        RunningCoachMetric.posture: RunningMetricQuality(
          confidence: 1,
          sampleCount: 24,
        ),
        RunningCoachMetric.bounce: RunningMetricQuality(
          confidence: 1,
          sampleCount: 24,
        ),
        RunningCoachMetric.footStrike: RunningMetricQuality(
          confidence: 1,
          sampleCount: 24,
        ),
        RunningCoachMetric.kneeFlexion: RunningMetricQuality(
          confidence: 1,
          sampleCount: 24,
        ),
        RunningCoachMetric.armCarriage: RunningMetricQuality(
          confidence: 1,
          sampleCount: 24,
        ),
      },
    );
  }

  RunningVideoAnalysisResult _mistakeSampleAnalysisResult() {
    return const RunningVideoAnalysisResult(
      videoDuration: Duration(seconds: 6),
      sampledFrames: 24,
      validFrames: 24,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 2,
      verticalBounceRatio: 0.12,
      footStrikeDistanceRatio: 0.24,
      stanceKneeAngleDegrees: 176,
      elbowAngleDegrees: 132,
      metricQualities: <RunningCoachMetric, RunningMetricQuality>{
        RunningCoachMetric.posture: RunningMetricQuality(
          confidence: 1,
          sampleCount: 24,
        ),
        RunningCoachMetric.bounce: RunningMetricQuality(
          confidence: 1,
          sampleCount: 24,
        ),
        RunningCoachMetric.footStrike: RunningMetricQuality(
          confidence: 1,
          sampleCount: 24,
        ),
        RunningCoachMetric.kneeFlexion: RunningMetricQuality(
          confidence: 1,
          sampleCount: 24,
        ),
        RunningCoachMetric.armCarriage: RunningMetricQuality(
          confidence: 1,
          sampleCount: 24,
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

class _RunningGrowthRecordCard extends StatelessWidget {
  final RunningGrowthSnapshot snapshot;
  final RunningSprintDistance selectedDistance;
  final TextEditingController secondsController;
  final bool isSaving;
  final ValueChanged<RunningSprintDistance> onDistanceChanged;
  final VoidCallback onSave;

  const _RunningGrowthRecordCard({
    required this.snapshot,
    required this.selectedDistance,
    required this.secondsController,
    required this.isSaving,
    required this.onDistanceChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final selectedBest = snapshot.bestFor(selectedDistance);
    final selectedDelta = snapshot.latestDeltaFor(selectedDistance);
    return Card(
      key: const ValueKey('running-coach-growth-record-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.flag_outlined, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.runningCoachGrowthTitle,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.runningCoachGrowthBody,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _GrowthStatsRow(snapshot: snapshot),
            const SizedBox(height: 14),
            _BestRecordGrid(snapshot: snapshot),
            const SizedBox(height: 14),
            Text(
              l10n.runningCoachRecordInputTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<RunningSprintDistance>(
              showSelectedIcon: false,
              segments: [
                for (final distance in RunningSprintDistance.values)
                  ButtonSegment<RunningSprintDistance>(
                    value: distance,
                    icon: const Icon(Icons.straighten_rounded),
                    label: Text(
                      l10n.runningCoachRecordDistance(distance.meters),
                    ),
                  ),
              ],
              selected: {selectedDistance},
              onSelectionChanged: isSaving
                  ? null
                  : (selection) => onDistanceChanged(selection.first),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('running-coach-record-seconds-field'),
              controller: secondsController,
              enabled: !isSaving,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.runningCoachRecordSecondsLabel,
                hintText: l10n.runningCoachRecordSecondsHint,
                suffixText: l10n.runningCoachRecordSecondsSuffix,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => onSave(),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('running-coach-record-save-button'),
                onPressed: isSaving ? null : onSave,
                icon: isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_task_outlined),
                label: Text(l10n.runningCoachRecordSaveAction),
              ),
            ),
            const SizedBox(height: 12),
            _GhostRunnerDeltaPanel(
              distance: selectedDistance,
              best: selectedBest,
              delta: selectedDelta,
            ),
            const SizedBox(height: 14),
            _RunningBadgePanel(snapshot: snapshot),
          ],
        ),
      ),
    );
  }
}

class _GrowthStatsRow extends StatelessWidget {
  final RunningGrowthSnapshot snapshot;

  const _GrowthStatsRow({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatChip(
          label: l10n.runningCoachGrowthAttemptsLabel,
          value: l10n.runningCoachGrowthAttempts(snapshot.totalAttempts),
        ),
        _StatChip(
          label: l10n.runningCoachGrowthStreakLabel,
          value: l10n.runningCoachGrowthStreak(snapshot.currentStreakDays),
        ),
        _StatChip(
          label: l10n.runningCoachGrowthDistancesLabel,
          value:
              l10n.runningCoachGrowthDistances(snapshot.completedDistanceCount),
        ),
      ],
    );
  }
}

class _BestRecordGrid extends StatelessWidget {
  final RunningGrowthSnapshot snapshot;

  const _BestRecordGrid({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final itemWidth = width >= 520 ? (width - 20) / 3 : width;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final distance in RunningSprintDistance.values)
              SizedBox(
                width: itemWidth,
                child: _BestRecordTile(
                  distance: distance,
                  record: snapshot.bestFor(distance),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BestRecordTile extends StatelessWidget {
  final RunningSprintDistance distance;
  final RunningSprintRecord? record;

  const _BestRecordTile({required this.distance, required this.record});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.runningCoachRecordDistance(distance.meters),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              record == null
                  ? l10n.runningCoachRecordEmpty
                  : l10n.runningCoachRecordSecondsValue(
                      record!.seconds.toStringAsFixed(2),
                    ),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GhostRunnerDeltaPanel extends StatelessWidget {
  final RunningSprintDistance distance;
  final RunningSprintRecord? best;
  final RunningRecordDelta? delta;

  const _GhostRunnerDeltaPanel({
    required this.distance,
    required this.best,
    required this.delta,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final title = best == null
        ? l10n.runningCoachGhostEmptyTitle
        : l10n.runningCoachGhostTitle(distance.meters);
    final body = _bodyText(l10n);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.compare_arrows_rounded,
                color: scheme.onPrimaryContainer),
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

  String _bodyText(AppLocalizations l10n) {
    if (best == null) {
      return l10n.runningCoachGhostEmptyBody;
    }
    final resolvedDelta = delta;
    if (resolvedDelta == null) {
      return l10n.runningCoachGhostFirstRecordBody(
        best!.seconds.toStringAsFixed(2),
      );
    }
    final gap = resolvedDelta.secondsImproved.abs().toStringAsFixed(2);
    if (resolvedDelta.isPersonalBest) {
      return l10n.runningCoachGhostImprovedBody(gap);
    }
    return l10n.runningCoachGhostChaseBody(gap);
  }
}

class _RunningBadgePanel extends StatelessWidget {
  final RunningGrowthSnapshot snapshot;

  const _RunningBadgePanel({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final earned = snapshot.earnedBadges.toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.runningCoachBadgesTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final badge in RunningGrowthBadge.values)
              _RunningBadgeChip(
                badge: badge,
                earned: earned.contains(badge),
              ),
          ],
        ),
      ],
    );
  }
}

class _RunningBadgeChip extends StatelessWidget {
  final RunningGrowthBadge badge;
  final bool earned;

  const _RunningBadgeChip({required this.badge, required this.earned});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            earned ? scheme.tertiaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: earned
              ? scheme.tertiary.withValues(alpha: 0.36)
              : scheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              earned ? Icons.workspace_premium_outlined : Icons.lock_outline,
              size: 16,
              color: earned ? scheme.onTertiaryContainer : scheme.outline,
            ),
            const SizedBox(width: 6),
            Text(
              _badgeTitle(l10n, badge),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: earned
                        ? scheme.onTertiaryContainer
                        : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _badgeTitle(AppLocalizations l10n, RunningGrowthBadge badge) {
    return switch (badge) {
      RunningGrowthBadge.firstRun => l10n.runningCoachBadgeFirstRun,
      RunningGrowthBadge.recordBreaker => l10n.runningCoachBadgeRecordBreaker,
      RunningGrowthBadge.threeDaySpark => l10n.runningCoachBadgeThreeDaySpark,
      RunningGrowthBadge.allRounder => l10n.runningCoachBadgeAllRounder,
    };
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
const Duration _sampleVideoLoopDuration = Duration(milliseconds: 2200);

enum _SampleVideoMode { reference, mistake }

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
                IconButton(
                  key: const ValueKey('running-coach-sample-back-button'),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  icon: const Icon(Icons.arrow_back_rounded),
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
            _SampleVideoFrame(score: activeReport.overallScore, mode: _mode),
            const SizedBox(height: 12),
            _SampleFrameCuePanel(
              panelKey: const ValueKey('running-coach-sample-joint-readouts'),
              title: modeTitle,
              body: modeBody,
              cues: _modeReadouts(l10n, _mode),
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
    _SampleVideoMode mode,
  ) {
    if (mode == _SampleVideoMode.mistake) {
      return [
        _SampleFrameCue(
          icon: Icons.straighten_rounded,
          text: l10n.runningCoachSampleMistakePosture,
        ),
        _SampleFrameCue(
          icon: Icons.ads_click_rounded,
          text: l10n.runningCoachSampleMistakeFoot,
        ),
        _SampleFrameCue(
          icon: Icons.timeline_rounded,
          text: l10n.runningCoachSampleMistakeKnee,
        ),
        _SampleFrameCue(
          icon: Icons.open_in_full_rounded,
          text: l10n.runningCoachSampleMistakeArms,
        ),
        _SampleFrameCue(
          icon: Icons.swap_vert_rounded,
          text: l10n.runningCoachSampleMistakeBounce,
        ),
      ];
    }
    return [
      _SampleFrameCue(
        icon: Icons.straighten_rounded,
        text: l10n.runningCoachSampleReferencePosture,
      ),
      _SampleFrameCue(
        icon: Icons.ads_click_rounded,
        text: l10n.runningCoachSampleReferenceFoot,
      ),
      _SampleFrameCue(
        icon: Icons.timeline_rounded,
        text: l10n.runningCoachSampleReferenceKnee,
      ),
      _SampleFrameCue(
        icon: Icons.sync_alt_rounded,
        text: l10n.runningCoachSampleReferenceArms,
      ),
      _SampleFrameCue(
        icon: Icons.center_focus_strong_rounded,
        text: l10n.runningCoachSampleReferenceFrame,
      ),
    ];
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

  const _SampleVideoFrame({required this.score, required this.mode});

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
      duration: _sampleVideoLoopDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isMistake = widget.mode == _SampleVideoMode.mistake;
    final runnerColor = isMistake ? scheme.error : scheme.primary;
    final postureOverlay = isMistake
        ? l10n.runningCoachSampleMistakeOverlayPosture
        : l10n.runningCoachSampleOverlayPosture;
    final armsOverlay = isMistake
        ? l10n.runningCoachSampleMistakeOverlayArms
        : l10n.runningCoachSampleOverlayArms;
    final footOverlay = isMistake
        ? l10n.runningCoachSampleMistakeOverlayFoot
        : l10n.runningCoachSampleOverlayFoot;
    final fourthOverlay = isMistake
        ? l10n.runningCoachSampleMistakeOverlayBounce
        : l10n.runningCoachSampleOverlayFrames;
    return AspectRatio(
      key: const ValueKey('running-coach-sample-video-frame'),
      aspectRatio: 16 / 7,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
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
                      lineColor: runnerColor,
                      trackColor: scheme.outlineVariant,
                      ghostColor: runnerColor.withValues(alpha: 0.18),
                      frameColor: scheme.tertiary,
                      markerColor: scheme.secondary,
                      poseVariant: isMistake
                          ? SampleRunnerPoseVariant.mistake
                          : SampleRunnerPoseVariant.reference,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final frameNumber =
                        ((_controller.value * _sampleTimelineFrameCount)
                                    .floor() %
                                _sampleTimelineFrameCount) +
                            1;
                    return _VideoOverlayPill(
                      text: l10n.runningCoachSampleFrameLabel(
                        frameNumber,
                        _sampleTimelineFrameCount,
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: _VideoOverlayPill(text: '${widget.score}'),
              ),
              Positioned(
                left: 12,
                top: 48,
                child: _VideoOverlayLabel(
                  text: postureOverlay,
                  color: runnerColor,
                ),
              ),
              Positioned(
                right: 12,
                top: 48,
                child: _VideoOverlayLabel(
                  text: armsOverlay,
                  color: scheme.secondary,
                ),
              ),
              Positioned(
                left: 12,
                bottom: 24,
                child: _VideoOverlayLabel(
                  text: footOverlay,
                  color: scheme.tertiary,
                ),
              ),
              Positioned(
                right: 12,
                bottom: 24,
                child: _VideoOverlayLabel(
                  text: fourthOverlay,
                  color: runnerColor,
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: _controller.value,
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.20),
                      color: scheme.primary,
                    ),
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

class _VideoOverlayLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _VideoOverlayLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.50)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
    );
  }
}

class _VideoOverlayPill extends StatelessWidget {
  final String text;

  const _VideoOverlayPill({required this.text});

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
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w900,
              ),
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
    'low_coverage' => isKorean
        ? '추적된 프레임 비율이 낮아 이 지표는 보수적으로 봐 주세요.'
        : 'Tracking coverage is low, so treat this metric conservatively.',
    'limited_samples' => isKorean
        ? '안정적으로 읽은 프레임이 적어 같은 구도로 한 번 더 확인하는 것이 좋아요.'
        : 'Only a small set of stable frames was read; confirm once more from the same angle.',
    'contact_phase_proxy' => isKorean
        ? '접지 구간을 추정한 프레임이 적어 착지와 무릎 지표는 한 번 더 확인해 주세요.'
        : 'The contact phase used only a small proxy window; confirm foot strike and knee metrics again.',
    _ => isKorean
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
