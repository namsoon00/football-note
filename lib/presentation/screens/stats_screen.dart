import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../application/benchmark_service.dart';
import '../../application/match_competition_service.dart';
import '../../application/meal_calorie_estimator.dart';
import '../../application/meal_log_service.dart';
import '../../application/news_badge_service.dart';
import '../../application/sport_capabilities.dart';
import '../../application/sport_defaults.dart';
import '../../application/sport_service.dart';
import '../../application/training_service.dart';
import '../../application/settings_service.dart';
import '../../application/backup_service.dart';
import '../../application/player_profile_service.dart';
import '../../application/training_plan_reminder_service.dart';
import '../../domain/entities/meal_entry.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/entities/player_profile.dart';
import '../../domain/entities/sport_definition.dart';
import '../widgets/app_page_route.dart';
import '../theme/app_theme.dart';
import 'package:football_note/gen/app_localizations.dart';
import '../../application/locale_service.dart';
import '../widgets/app_drawer.dart';
import '../utils/match_entry_format.dart';
import '../widgets/shared_tab_header.dart';
import '../widgets/coach_mark_target.dart';
import '../../domain/repositories/option_repository.dart';
import 'average_benchmark_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'news_screen.dart';
import 'skill_quiz_screen.dart';
import 'notification_center_screen.dart';

enum StatsCoachAnchor { range, tabs }

class StatsScreen extends StatefulWidget {
  final TrainingService trainingService;
  final MealLogService mealLogService;
  final LocaleService localeService;
  final VoidCallback onCreate;
  final OptionRepository optionRepository;
  final SettingsService settingsService;
  final BackupService? driveBackupService;
  final DateTimeRange? initialRange;
  final int initialRangeRequestKey;
  final int initialTabIndex;
  final int initialTabRequestKey;
  final VoidCallback? onOpenMatchHub;
  final Map<StatsCoachAnchor, CoachMarkTargetHandle> coachGuideAnchors;

  const StatsScreen({
    super.key,
    required this.trainingService,
    required this.mealLogService,
    required this.localeService,
    required this.onCreate,
    required this.optionRepository,
    required this.settingsService,
    this.driveBackupService,
    this.initialRange,
    this.initialRangeRequestKey = 0,
    this.initialTabIndex = 0,
    this.initialTabRequestKey = 0,
    this.onOpenMatchHub,
    this.coachGuideAnchors = const <StatsCoachAnchor, CoachMarkTargetHandle>{},
  });

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late final BenchmarkService _benchmarkService;
  late DateTimeRange _selectedRange;
  late Stream<List<TrainingEntry>> _trainingEntriesStream;
  int _statsTabIndex = 0;
  bool _routePushInFlight = false;

  Widget _coachTarget(
    StatsCoachAnchor anchor,
    Widget child, {
    Key? key,
    VoidCallback? onActivate,
  }) {
    final handle = widget.coachGuideAnchors[anchor];
    if (handle == null) return child;
    return CoachMarkTarget(
      key: key,
      handle: handle,
      onActivate: onActivate,
      child: child,
    );
  }

  void _toggleStatsTab() {
    setState(() => _statsTabIndex = _statsTabIndex == 0 ? 1 : 0);
  }

  String get _plansStorageKey =>
      TrainingPlanReminderService.plansStorageKeyFor(widget.optionRepository);

  @override
  void initState() {
    super.initState();
    _benchmarkService = BenchmarkService(widget.optionRepository);
    _statsTabIndex = widget.initialTabIndex.clamp(0, 1).toInt();
    _selectedRange = widget.initialRange ?? _recentWeekRange();
    _trainingEntriesStream = _watchSelectedTrainingEntries();
    NewsBadgeService.refresh(widget.optionRepository);
    _refreshBenchmarks();
  }

  @override
  void didUpdateWidget(covariant StatsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextRange = widget.initialRange;
    final previousRange = oldWidget.initialRange;
    final forceApplyRange =
        widget.initialRangeRequestKey != oldWidget.initialRangeRequestKey;
    final rangeChanged = nextRange != null &&
        (forceApplyRange || !_sameRange(previousRange, nextRange));
    if (rangeChanged) {
      _selectedRange = nextRange;
    }
    if (rangeChanged || widget.trainingService != oldWidget.trainingService) {
      _trainingEntriesStream = _watchSelectedTrainingEntries();
    }
    final tabChanged =
        widget.initialTabRequestKey != oldWidget.initialTabRequestKey ||
            widget.initialTabIndex != oldWidget.initialTabIndex;
    if (tabChanged) {
      _statsTabIndex = widget.initialTabIndex.clamp(0, 1).toInt();
    }
  }

  Future<void> _refreshBenchmarks() async {
    await _benchmarkService.refreshFromExternalIfNeeded();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _pushPageSafely(Route<void> route) async {
    if (!mounted || _routePushInFlight) return;
    _routePushInFlight = true;
    try {
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      await Navigator.of(context).push(route);
    } finally {
      _routePushInFlight = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        trainingService: widget.trainingService,
        optionRepository: widget.optionRepository,
        localeService: widget.localeService,
        settingsService: widget.settingsService,
        driveBackupService: widget.driveBackupService,
        currentIndex: 3,
      ),
      body: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: StreamBuilder<List<TrainingEntry>>(
            stream: _trainingEntriesStream,
            builder: (context, snapshot) {
              final l10n = AppLocalizations.of(context)!;
              if (snapshot.hasError) {
                return _buildStatsContent(
                  context,
                  entries: const [],
                  mealEntries: const <MealEntry>[],
                  topMessage: l10n.statsLoadFailedMessage,
                );
              }
              if (!snapshot.hasData &&
                  snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState(context);
              }
              final entries = snapshot.data ?? const <TrainingEntry>[];
              return StreamBuilder<List<MealEntry>>(
                stream: widget.mealLogService.watchEntries(),
                builder: (context, mealSnapshot) {
                  final mealEntries = mealSnapshot.data ?? const <MealEntry>[];
                  try {
                    return _buildStatsContent(
                      context,
                      entries: entries,
                      mealEntries: mealEntries,
                    );
                  } catch (_) {
                    return _buildStatsContent(
                      context,
                      entries: entries,
                      mealEntries: mealEntries,
                      topMessage: l10n.statsFallbackMessage,
                    );
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context)!.statsLoadingMessage,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildStatsContent(
    BuildContext context, {
    required List<TrainingEntry> entries,
    required List<MealEntry> mealEntries,
    String? topMessage,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final sportId = SportService(widget.optionRepository).currentSportId();
    final sportEntries = filterEntriesForSport(entries, sportId);
    final profileService = PlayerProfileService(
      widget.optionRepository,
      sportId: sportId,
    );
    final reminderUnreadCount = TrainingPlanReminderService(
      widget.optionRepository,
      widget.settingsService,
    ).unreadReminderCountSync();
    final profile = profileService.load();
    final now = DateTime.now();
    final ageYears = profileService.ageInYears(profile, now);
    final soccerYears = profileService.soccerYears(profile, now);
    final canShowAverage = ageYears != null && soccerYears != null;
    final rangeStart = _rangeStartFor(_selectedRange);
    final rangeEndExclusive = _rangeEndExclusiveFor(_selectedRange);
    final filteredEntries = sportEntries
        .where(
          (entry) =>
              !entry.date.isBefore(rangeStart) &&
              entry.date.isBefore(rangeEndExclusive),
        )
        .toList(growable: false);
    final trainingEntries = filteredEntries
        .where((entry) => !entry.isMatch)
        .toList(growable: false);
    final filteredMealEntries = widget.mealLogService
        .mergedEntries(
          directEntries: mealEntries,
          legacyEntries: filteredEntries,
        )
        .where(
          (entry) =>
              !entry.date.isBefore(rangeStart) &&
              entry.date.isBefore(rangeEndExclusive),
        )
        .toList(growable: false);
    final matchEntries =
        filteredEntries.where((entry) => entry.isMatch).toList(growable: false);
    final plansInRange = _loadPlansInRange(
      rangeStart: rangeStart,
      rangeEndExclusive: rangeEndExclusive,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ValueListenableBuilder<int>(
            valueListenable: NewsBadgeService.listenable(
              widget.optionRepository,
            ),
            builder: (context, newsCount, _) => Builder(
              builder: (context) => SharedTabHeader(
                padding: EdgeInsets.zero,
                onLeadingTap: () => Scaffold.of(context).openDrawer(),
                onNewsTap: () => _openNews(context),
                newsBadgeCount: newsCount,
                onQuizTap: () => _openQuiz(context),
                onMatchTap: widget.onOpenMatchHub,
                onNotificationTap: () => _openNotifications(context),
                notificationBadgeCount: reminderUnreadCount,
                profilePhotoSource: PlayerProfileService(
                  widget.optionRepository,
                  sportId: sportId,
                ).load().photoUrl,
                onProfileTap: () => _openProfile(context),
                onSettingsTap: () => _openSettings(context),
                title: '${l10n.statsHeadline1} ${l10n.statsHeadline2}',
                titleTrailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: _setRecentWeekRange,
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size(1, 38),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      child: Text(l10n.statsRecent7),
                    ),
                    const SizedBox(width: 8),
                    _coachTarget(
                      StatsCoachAnchor.range,
                      OutlinedButton.icon(
                        onPressed: () => _pickRange(context),
                        icon: const Icon(Icons.date_range_outlined, size: 18),
                        label: Text(_rangeLabel()),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          minimumSize: const Size(1, 38),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                      ),
                      key: const ValueKey<String>('stats-coach-range-target'),
                      onActivate: () => unawaited(_pickRange(context)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (topMessage != null) ...[
            _InlineNotice(text: topMessage),
            const SizedBox(height: 12),
          ],
          _buildStatsTabBar(context),
          const SizedBox(height: 16),
          if (_statsTabIndex == 0)
            _buildTrainingStatsTab(
              context,
              profile: profile,
              ageYears: ageYears,
              soccerYears: soccerYears,
              canShowAverage: canShowAverage,
              trainingEntries: trainingEntries,
              mealEntries: filteredMealEntries,
              plansInRange: plansInRange,
              sportId: sportId,
            )
          else
            _buildMatchStatsTab(
              context,
              filteredEntries: filteredEntries,
              matchEntries: matchEntries,
              sportId: sportId,
            ),
        ],
      ),
    );
  }

  Widget _buildStatsTabBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _coachTarget(
      StatsCoachAnchor.tabs,
      SegmentedButton<int>(
        segments: [
          ButtonSegment<int>(
            value: 0,
            icon: const Icon(Icons.fitness_center_outlined),
            label: Text(l10n.statsTrainingTab),
          ),
          ButtonSegment<int>(
            value: 1,
            icon: const Icon(Icons.sports_soccer_outlined),
            label: Text(l10n.statsMatchesTab),
          ),
        ],
        selected: {_statsTabIndex},
        onSelectionChanged: (selection) {
          setState(() {
            _statsTabIndex = selection.first;
          });
        },
        showSelectedIcon: false,
      ),
      key: const ValueKey<String>('stats-coach-tabs-target'),
      onActivate: _toggleStatsTab,
    );
  }

  Widget _buildTrainingStatsTab(
    BuildContext context, {
    required PlayerProfile profile,
    required int? ageYears,
    required int? soccerYears,
    required bool canShowAverage,
    required List<TrainingEntry> trainingEntries,
    required List<MealEntry> mealEntries,
    required List<_StatsPlanLite> plansInRange,
    required String sportId,
  }) {
    final l10n = AppLocalizations.of(context)!;
    if (trainingEntries.isEmpty && mealEntries.isEmpty) {
      return _InlineNotice(
        text: l10n.mealStatsNoTrainingOrMealEntries,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (trainingEntries.isNotEmpty) ...[
          _StatsPanel(
            child: _TrainingReportSection(
              entries: trainingEntries,
              mealEntries: mealEntries,
              plans: plansInRange,
              range: _selectedRange,
              sportId: sportId,
              ageYears: ageYears,
              soccerYears: soccerYears,
              showTarget: canShowAverage,
            ),
          ),
          const SizedBox(height: 18),
        ],
        if (!canShowAverage) ...[
          _InlineNotice(
            text: l10n.averageComparisonProfileMissingMessage,
            title: l10n.averageComparisonProfileMissingTitle,
            trailing: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => _openProfile(context),
                icon: const Icon(Icons.person_outline),
                label: Text(l10n.averageComparisonOpenProfileAction),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (trainingEntries.isNotEmpty) ...[
          _StatsPanel(
            child: _TargetGrowthChart(
              entries: trainingEntries,
              ageYears: ageYears,
              soccerYears: soccerYears,
              sportId: sportId,
              showAverage: canShowAverage,
              range: _selectedRange,
            ),
          ),
          const SizedBox(height: 18),
          _StatsPanel(
            child: _BodyAndLiftingBenchmarkCard(
              entries: trainingEntries,
              profile: profile,
              ageYears: ageYears,
              sportId: sportId,
              benchmarkService: _benchmarkService,
              showAverage: canShowAverage,
              onReferenceTap: canShowAverage
                  ? () => _openAverageBenchmark(
                        context,
                        trainingEntries,
                        ageYears,
                        soccerYears,
                        sportId,
                      )
                  : null,
            ),
          ),
          const SizedBox(height: 18),
          _StatsPanel(
            child: _LiftingSummaryCard(
              entries: trainingEntries,
              sportId: sportId,
            ),
          ),
          const SizedBox(height: 18),
          _StatsPanel(
            child: _JumpRopeSummaryCard(
              entries: trainingEntries,
              range: _selectedRange,
              sportId: sportId,
            ),
          ),
        ],
        if (mealEntries.isNotEmpty) ...[
          if (trainingEntries.isNotEmpty) const SizedBox(height: 18),
          _StatsPanel(
            child: _MealTrendCard(
              mealEntries: mealEntries,
              range: _selectedRange,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMatchStatsTab(
    BuildContext context, {
    required List<TrainingEntry> filteredEntries,
    required List<TrainingEntry> matchEntries,
    required String sportId,
  }) {
    if (filteredEntries.isEmpty || matchEntries.isEmpty) {
      return _InlineNotice(
        text: AppLocalizations.of(context)!.statsNoMatchesSelectedPeriod,
      );
    }

    final competitionRecords = MatchCompetitionService(
      widget.optionRepository,
      sportId: sportId,
    ).allCompetitions();
    final hasCompetitionRecords = competitionRecords.any(
      (record) =>
          record.kind == MatchCompetitionRecord.kindLeague ||
          record.kind == MatchCompetitionRecord.kindTournament,
    );
    final hasCompetitionEntries = matchEntries.any(
      (entry) => entry.isLeagueMatch || entry.isTournamentMatch,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatsPanel(
          child: _MatchSummaryCard(
            entries: matchEntries,
            sportId: sportId,
          ),
        ),
        if (hasCompetitionRecords || hasCompetitionEntries) ...[
          const SizedBox(height: 18),
          _StatsPanel(
            child: _MatchCompetitionStatsSection(
              entries: matchEntries,
              competitionRecords: competitionRecords,
            ),
          ),
        ],
        const SizedBox(height: 18),
        _StatsPanel(child: _MatchHistorySection(entries: matchEntries)),
      ],
    );
  }

  Future<void> _pickRange(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final rangeColor = theme.colorScheme.primary.withValues(alpha: 0.22);
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedRange,
      firstDate: DateTime(2022, 1, 1),
      lastDate: DateTime(2032, 12, 31),
      helpText: l10n.statsRangePickerHelp,
      confirmText: l10n.filterApply,
      cancelText: l10n.cancel,
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            datePickerTheme: DatePickerThemeData(
              rangeSelectionBackgroundColor: rangeColor,
              rangeSelectionOverlayColor: WidgetStateProperty.resolveWith(
                (states) => theme.colorScheme.primary.withValues(alpha: 0.12),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null || !mounted) return;
    _setSelectedRange(
      DateTimeRange(
        start: DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        ),
        end: DateTime(picked.end.year, picked.end.month, picked.end.day),
      ),
    );
  }

  String _rangeLabel() {
    final start = _selectedRange.start;
    final end = _selectedRange.end;
    final startText = '${start.month}/${start.day}';
    final endText = '${end.month}/${end.day}';
    return '$startText-$endText';
  }

  void _setRecentWeekRange() {
    _setSelectedRange(_recentWeekRange());
  }

  void _setSelectedRange(DateTimeRange range) {
    setState(() {
      _selectedRange = range;
      _trainingEntriesStream = _watchSelectedTrainingEntries();
    });
  }

  Stream<List<TrainingEntry>> _watchSelectedTrainingEntries() {
    return widget.trainingService.watchEntriesInRange(
      _rangeStartFor(_selectedRange),
      _rangeEndExclusiveFor(_selectedRange),
    );
  }

  DateTime _rangeStartFor(DateTimeRange range) =>
      DateTime(range.start.year, range.start.month, range.start.day);

  DateTime _rangeEndExclusiveFor(DateTimeRange range) => DateTime(
        range.end.year,
        range.end.month,
        range.end.day,
      ).add(const Duration(days: 1));

  DateTimeRange _recentWeekRange() {
    final today = DateTime.now();
    final end = DateTime(today.year, today.month, today.day);
    final start = end.subtract(const Duration(days: 6));
    return DateTimeRange(start: start, end: end);
  }

  bool _sameRange(DateTimeRange? left, DateTimeRange? right) {
    if (left == null || right == null) return left == right;
    return left.start == right.start && left.end == right.end;
  }

  List<_StatsPlanLite> _loadPlansInRange({
    required DateTime rangeStart,
    required DateTime rangeEndExclusive,
  }) {
    final raw = widget.optionRepository.getValue<String>(_plansStorageKey);
    if (raw == null || raw.trim().isEmpty) return const <_StatsPlanLite>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <_StatsPlanLite>[];
      return decoded
          .whereType<Map>()
          .map((item) => _StatsPlanLite.fromMap(item.cast<String, dynamic>()))
          .where(
            (plan) =>
                !plan.scheduledAt.isBefore(rangeStart) &&
                plan.scheduledAt.isBefore(rangeEndExclusive),
          )
          .toList(growable: false);
    } catch (_) {
      return const <_StatsPlanLite>[];
    }
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => SettingsScreen(
          localeService: widget.localeService,
          settingsService: widget.settingsService,
          optionRepository: widget.optionRepository,
          driveBackupService: widget.driveBackupService,
        ),
      ),
    );
  }

  Future<void> _openProfile(BuildContext context) async {
    await _pushPageSafely(
      AppPageRoute(
        builder: (_) =>
            ProfileScreen(optionRepository: widget.optionRepository),
      ),
    );
  }

  Future<void> _openNews(BuildContext context) async {
    await _pushPageSafely(
      AppPageRoute(
        builder: (_) => NewsScreen(
          trainingService: widget.trainingService,
          localeService: widget.localeService,
          optionRepository: widget.optionRepository,
          settingsService: widget.settingsService,
          driveBackupService: widget.driveBackupService,
          isActive: true,
        ),
      ),
    );
    if (mounted) {
      await NewsBadgeService.refresh(widget.optionRepository);
    }
  }

  Future<void> _openQuiz(BuildContext context) async {
    await _pushPageSafely(
      AppPageRoute(
        builder: (_) =>
            SkillQuizScreen(optionRepository: widget.optionRepository),
      ),
    );
  }

  Future<void> _openNotifications(BuildContext context) async {
    await Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => NotificationCenterScreen(
          optionRepository: widget.optionRepository,
          settingsService: widget.settingsService,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void _openAverageBenchmark(
    BuildContext context,
    List<TrainingEntry> entries,
    int? ageYears,
    int? soccerYears,
    String sportId,
  ) {
    Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => AverageBenchmarkScreen(
          entries: entries,
          ageYears: ageYears,
          soccerYears: soccerYears,
          sportId: sportId,
          benchmarkService: _benchmarkService,
        ),
      ),
    );
  }
}

class _TargetGrowthChart extends StatelessWidget {
  final List<TrainingEntry> entries;
  final int? ageYears;
  final int? soccerYears;
  final String sportId;
  final bool showAverage;
  final DateTimeRange range;

  const _TargetGrowthChart({
    required this.entries,
    required this.ageYears,
    required this.soccerYears,
    required this.sportId,
    required this.showAverage,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final target = benchmarkTargetForSport(
      sportId: sportId,
      ageYears: ageYears,
      sportYears: soccerYears,
    );
    final periodStart = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final periodEnd = DateTime(range.end.year, range.end.month, range.end.day);
    final dayPoints = <DateTime>[];
    var cursor = periodStart;
    while (!cursor.isAfter(periodEnd)) {
      dayPoints.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }

    final actualSpots = <FlSpot>[];
    final targetSpots = <FlSpot>[];
    final labels = <int, String>{};
    final workedDays = <DateTime>{};
    final dailyTarget = (target.weeklyMinutesTarget / 7).round();
    final labelStep =
        dayPoints.length <= 10 ? 1 : (dayPoints.length <= 20 ? 2 : 3);

    for (var i = 0; i < dayPoints.length; i++) {
      final start = dayPoints[i];
      final end = start.add(const Duration(days: 1));
      final minutes = entries
          .where((e) => !e.date.isBefore(start) && e.date.isBefore(end))
          .fold<int>(0, (sum, entry) => sum + entry.durationMinutes);
      if (minutes > 0) workedDays.add(start);
      actualSpots.add(FlSpot(i.toDouble(), minutes.toDouble()));
      if (showAverage) {
        targetSpots.add(FlSpot(i.toDouble(), dailyTarget.toDouble()));
      }
      if (i == 0 || i == dayPoints.length - 1 || i % labelStep == 0) {
        labels[i] = '${start.month}/${start.day}';
      }
    }
    final workedDateText = workedDays.toList()..sort((a, b) => a.compareTo(b));
    final workedLabel = workedDateText.isEmpty
        ? l10n.statsWorkoutDaysNone
        : l10n.statsWorkoutDaysValue(
            workedDateText.map((d) => '${d.month}/${d.day}').join(', '),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.show_chart,
          title: l10n.statsGrowthChartTitle,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final label = spot.barIndex == 0
                          ? l10n.statsActualLabel
                          : l10n.statsTargetLabel;
                      final timeText = _formatMinutesAsTime(
                        spot.y.round(),
                        l10n: l10n,
                      );
                      return LineTooltipItem(
                        '$label: $timeText',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (value, meta) {
                      if (value < 0) return const SizedBox.shrink();
                      return Text(
                        _compactHourTick(value, l10n: l10n),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final label = labels[value.toInt()];
                      if (label == null) return const SizedBox.shrink();
                      return Text(label, style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: actualSpots,
                  isCurved: true,
                  color: const Color(0xFF3DDC84),
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
                if (showAverage)
                  LineChartBarData(
                    spots: targetSpots,
                    isCurved: false,
                    color: const Color(0xFFFFC857),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    dashArray: const [6, 4],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: [
            _LegendDot(
              color: const Color(0xFF3DDC84),
              label: l10n.statsActualTimeDailyLabel,
            ),
            if (showAverage)
              _LegendDot(
                color: const Color(0xFFFFC857),
                label: l10n.statsAverageTargetTimeDailyLabel,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(workedLabel, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _BodyAndLiftingBenchmarkCard extends StatelessWidget {
  final List<TrainingEntry> entries;
  final PlayerProfile profile;
  final int? ageYears;
  final String sportId;
  final BenchmarkService benchmarkService;
  final bool showAverage;
  final VoidCallback? onReferenceTap;

  const _BodyAndLiftingBenchmarkCard({
    required this.entries,
    required this.profile,
    required this.ageYears,
    required this.sportId,
    required this.benchmarkService,
    required this.showAverage,
    required this.onReferenceTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final latestHeight = profile.heightCm;
    final latestWeight = profile.weightKg;
    final conditioningLabel = SportDefaults.secondaryConditioningLabel(
      l10n: l10n,
      sportId: sportId,
    );

    final totalLifts = entries.fold<int>(
      0,
      (sum, e) =>
          sum +
          e.liftingByPart.values.fold<int>(0, (acc, count) => acc + count),
    );
    final avgLiftPerSession =
        entries.isEmpty ? 0 : (totalLifts / entries.length).round();
    final benchmark = benchmarkService.physicalBenchmarkForAge(
      ageYears,
      sportId: sportId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.balance,
          title: l10n.averageComparisonTitle,
          trailing: onReferenceTap == null
              ? null
              : OutlinedButton.icon(
                  onPressed: onReferenceTap,
                  icon: const Icon(Icons.analytics_outlined, size: 16),
                  label: Text(l10n.averageComparisonReferenceAction),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(1, 34),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        if (!showAverage) ...[
          Text(l10n.averageComparisonHiddenMessage),
          const SizedBox(height: 10),
        ],
        _ComparisonRow(
          label: l10n.averageComparisonHeightLabel,
          current: latestHeight == null
              ? l10n.averageComparisonNotSet
              : '${latestHeight.toStringAsFixed(1)}cm',
          average: showAverage
              ? '${benchmark.heightCmAvg.toStringAsFixed(1)}cm'
              : l10n.averageComparisonHiddenValue,
          gap: latestHeight == null
              ? l10n.averageComparisonUnavailableValue
              : showAverage
                  ? _gapText(latestHeight - benchmark.heightCmAvg, l10n)
                  : l10n.averageComparisonHiddenGap,
          isPositive: showAverage &&
              latestHeight != null &&
              latestHeight - benchmark.heightCmAvg >= 0,
        ),
        const SizedBox(height: 8),
        _ComparisonRow(
          label: l10n.averageComparisonWeightLabel,
          current: latestWeight == null
              ? l10n.averageComparisonNotSet
              : '${latestWeight.toStringAsFixed(1)}kg',
          average: showAverage
              ? '${benchmark.weightKgAvg.toStringAsFixed(1)}kg'
              : l10n.averageComparisonHiddenValue,
          gap: latestWeight == null
              ? l10n.averageComparisonUnavailableValue
              : showAverage
                  ? _gapText(latestWeight - benchmark.weightKgAvg, l10n)
                  : l10n.averageComparisonHiddenGap,
          isPositive: showAverage &&
              latestWeight != null &&
              latestWeight - benchmark.weightKgAvg >= 0,
        ),
        const SizedBox(height: 8),
        _ComparisonRow(
          label: l10n.averageComparisonConditioningPerSessionLabel(
            conditioningLabel,
          ),
          current: '$avgLiftPerSession',
          average: showAverage
              ? '${benchmark.liftsPerSessionAvg}'
              : l10n.averageComparisonHiddenValue,
          gap: showAverage
              ? _gapText(
                  (avgLiftPerSession - benchmark.liftsPerSessionAvg).toDouble(),
                  l10n,
                )
              : l10n.averageComparisonHiddenGap,
          isPositive: showAverage &&
              avgLiftPerSession - benchmark.liftsPerSessionAvg >= 0,
        ),
      ],
    );
  }
}

String _gapText(double gap, AppLocalizations l10n) {
  final sign = gap >= 0 ? '+' : '';
  return l10n.averageComparisonGapValue('$sign${gap.toStringAsFixed(1)}');
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _LiftingSummaryCard extends StatelessWidget {
  final List<TrainingEntry> entries;
  final String sportId;

  const _LiftingSummaryCard({required this.entries, required this.sportId});

  @override
  Widget build(BuildContext context) {
    final bestByPart = <String, _PartBest>{};
    final recordsByPart = <String, List<_PartRecord>>{};
    final totalsByDay = <DateTime, int>{};
    for (final entry in entries) {
      final dayKey = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      final totalForEntry = entry.liftingByPart.values.fold<int>(
        0,
        (sum, count) => sum + count,
      );
      if (totalForEntry > 0) {
        totalsByDay.update(
          dayKey,
          (value) => value + totalForEntry,
          ifAbsent: () => totalForEntry,
        );
      }
      entry.liftingByPart.forEach((part, count) {
        if (count <= 0) return;
        recordsByPart
            .putIfAbsent(part, () => <_PartRecord>[])
            .add(_PartRecord(count: count, date: entry.date));
        final current = bestByPart[part];
        if (current == null || count > current.count) {
          bestByPart[part] = _PartBest(
            count: count,
            date: entry.date,
            increase: 0,
          );
        }
      });
    }
    recordsByPart.forEach((part, records) {
      records.sort((a, b) => b.count.compareTo(a.count));
      final best = records.first.count;
      final prev = records.length > 1 ? records[1].count : 0;
      final current = bestByPart[part];
      if (current != null) {
        bestByPart[part] = _PartBest(
          count: current.count,
          date: current.date,
          increase: (best - prev).clamp(0, 999999),
        );
      }
    });
    final sorted = bestByPart.entries.toList()
      ..sort((a, b) => b.value.count.compareTo(a.value.count));
    final trendEntries = totalsByDay.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final maxTotal = trendEntries.isEmpty
        ? 0
        : trendEntries.map((entry) => entry.value).reduce(math.max);
    final yInterval = _niceLiftingAxisInterval(maxTotal);
    final yMax = trendEntries.isEmpty
        ? yInterval.toDouble()
        : ((maxTotal / yInterval).ceil() * yInterval).toDouble();
    final l10n = AppLocalizations.of(context)!;
    final secondaryLabel = SportDefaults.secondaryConditioningLabel(
      l10n: l10n,
      sportId: sportId,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.sports_soccer_outlined,
          title: SportDefaults.secondaryConditioningDetailTitle(
            l10n: l10n,
            sportId: sportId,
          ),
        ),
        const SizedBox(height: 12),
        if (sorted.isEmpty)
          Text(l10n.statsSecondaryConditioningNoRecords(secondaryLabel))
        else ...[
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: yMax,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: yInterval.toDouble(),
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.16),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: yInterval.toDouble(),
                      getTitlesWidget: (value, _) => Text(
                        value.toInt().toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index < 0 || index >= trendEntries.length) {
                          return const SizedBox.shrink();
                        }
                        final date = trendEntries[index].key;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('M/d').format(date),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: trendEntries.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value.toDouble(),
                        width: 16,
                        borderRadius: BorderRadius.circular(6),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  );
                }).toList(growable: false),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.statsSecondaryConditioningDailyTotals(secondaryLabel),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ...sorted.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _partLabel(entry.key, l10n),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    l10n.times(entry.value.count),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (entry.value.increase > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      '(+${entry.value.increase})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                  const SizedBox(width: 10),
                  Text(
                    _dateText(entry.value.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _partLabel(String key, AppLocalizations l10n) {
    final detailLabels = SportDefaults.secondaryConditioningDetailLabels(
      l10n: l10n,
      sportId: sportId,
    );
    switch (key) {
      case 'infront':
        return detailLabels[0];
      case 'inside':
        return detailLabels[1];
      case 'outside':
        return detailLabels[2];
      case 'muple':
        return detailLabels[3];
      case 'head':
        return detailLabels[4];
      case 'chest':
        return detailLabels[5];
      // Legacy keys from earlier lifting implementations.
      case 'left_foot':
        return '${detailLabels[0]} (${l10n.legacyLabel})';
      case 'right_foot':
        return '${detailLabels[1]} (${l10n.legacyLabel})';
      case 'left_thigh':
        return '${detailLabels[2]} (${l10n.legacyLabel})';
      case 'right_thigh':
        return '${detailLabels[3]} (${l10n.legacyLabel})';
      case 'back':
        return '${detailLabels[1]} (${l10n.oldLabel})';
      case 'legs':
        return '${detailLabels[2]} (${l10n.oldLabel})';
      case 'shoulders':
        return '${detailLabels[3]} (${l10n.oldLabel})';
      case 'arms':
        return '${detailLabels[4]} (${l10n.legacyLabel})';
      case 'core':
        return '${detailLabels[5]} (${l10n.legacyLabel})';
      default:
        return key;
    }
  }

  String _dateText(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y.$m.$d';
  }

  int _niceLiftingAxisInterval(int maxValue) {
    if (maxValue <= 20) return 10;
    if (maxValue <= 40) return 20;
    if (maxValue <= 80) return 25;
    if (maxValue <= 160) return 50;
    if (maxValue <= 320) return 100;
    final scaled = maxValue / 4;
    var magnitude = 1;
    while (magnitude * 10 <= scaled) {
      magnitude *= 10;
    }
    return ((scaled / magnitude).ceil() * magnitude).toInt();
  }
}

class _JumpRopeSummaryCard extends StatelessWidget {
  final List<TrainingEntry> entries;
  final DateTimeRange range;
  final String sportId;

  const _JumpRopeSummaryCard({
    required this.entries,
    required this.range,
    required this.sportId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primaryLabel = SportDefaults.primaryConditioningLabel(
      l10n: l10n,
      sportId: sportId,
    );
    final start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    final days = <DateTime>[];
    for (var current = start;
        !current.isAfter(end);
        current = current.add(const Duration(days: 1))) {
      days.add(current);
    }
    final countByDay = <DateTime, int>{for (final day in days) day: 0};
    final minutesByDay = <DateTime, int>{for (final day in days) day: 0};
    for (final entry in entries) {
      final key = DateTime(entry.date.year, entry.date.month, entry.date.day);
      countByDay.update(
        key,
        (value) => value + entry.jumpRopeCount,
        ifAbsent: () => entry.jumpRopeCount,
      );
      minutesByDay.update(
        key,
        (value) => value + entry.jumpRopeMinutes,
        ifAbsent: () => entry.jumpRopeMinutes,
      );
    }
    final countPoints = days
        .map((day) => MapEntry(day, countByDay[day] ?? 0))
        .toList(growable: false);
    final minutePoints = days
        .map((day) => MapEntry(day, minutesByDay[day] ?? 0))
        .toList(growable: false);
    final totalCount =
        countPoints.fold<int>(0, (sum, item) => sum + item.value);
    final totalMinutes =
        minutePoints.fold<int>(0, (sum, item) => sum + item.value);
    final useMinutes = totalCount == 0 && totalMinutes > 0;
    final points = useMinutes ? minutePoints : countPoints;
    final bestCount =
        points.isEmpty ? 0 : points.map((item) => item.value).reduce(math.max);
    final bestDay = points.firstWhere(
      (item) => item.value == bestCount,
      orElse: () => MapEntry(start, 0),
    );
    final maxY =
        bestCount <= 0 ? 5.0 : (bestCount * 1.25).clamp(5, 1000000).toDouble();
    final labelStride = math.max(1, (days.length / 6).ceil());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.fitness_center_outlined,
          title: l10n.statsPrimaryConditioningStatsTitle(primaryLabel),
        ),
        const SizedBox(height: 10),
        if (totalCount == 0 && totalMinutes == 0)
          _InlineNotice(
            text: l10n.statsPrimaryConditioningNoRecords(primaryLabel),
          )
        else ...[
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY <= 10 ? 2 : null,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.18),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.black87,
                    getTooltipItem: (group, _, rod, __) {
                      final day = days[group.x.toInt()];
                      final dateLabel = '${day.month}/${day.day}';
                      final count = rod.toY.round();
                      return BarTooltipItem(
                        useMinutes
                            ? '$dateLabel\n${l10n.statsPrimaryConditioningTooltipMinutes(primaryLabel, count)}'
                            : '$dateLabel\n${l10n.statsPrimaryConditioningTooltipCount(primaryLabel, count)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= days.length) {
                          return const SizedBox.shrink();
                        }
                        if (index % labelStride != 0 &&
                            index != days.length - 1) {
                          return const SizedBox.shrink();
                        }
                        final day = days[index];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${day.month}/${day.day}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < points.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: points[i].value.toDouble(),
                          width: days.length <= 10 ? 18 : 10,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                          color: const Color(0xFF3DDC84),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _LegendDot(
                color: const Color(0xFF3DDC84),
                label: useMinutes
                    ? l10n.statsPrimaryConditioningDailyMinutes(primaryLabel)
                    : l10n.statsPrimaryConditioningDailyCount(primaryLabel),
              ),
              if (totalCount > 0)
                Text(
                  l10n.statsPrimaryConditioningTotalCount(totalCount),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (totalMinutes > 0)
                Text(
                  l10n.statsPrimaryConditioningTotalMinutes(totalMinutes),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              Text(
                useMinutes
                    ? l10n.statsPrimaryConditioningBestMinutes(
                        bestDay.key.month,
                        bestDay.key.day,
                        bestCount,
                      )
                    : l10n.statsPrimaryConditioningBestCount(
                        bestDay.key.month,
                        bestDay.key.day,
                        bestCount,
                      ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _TrainingReportSection extends StatefulWidget {
  final List<TrainingEntry> entries;
  final List<MealEntry> mealEntries;
  final List<_StatsPlanLite> plans;
  final DateTimeRange range;
  final String sportId;
  final int? ageYears;
  final int? soccerYears;
  final bool showTarget;

  const _TrainingReportSection({
    required this.entries,
    required this.mealEntries,
    required this.plans,
    required this.range,
    required this.sportId,
    required this.ageYears,
    required this.soccerYears,
    required this.showTarget,
  });

  @override
  State<_TrainingReportSection> createState() => _TrainingReportSectionState();
}

class _TrainingReportSectionState extends State<_TrainingReportSection> {
  bool _detailsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sportLabel = SportDefaults.label(l10n: l10n, sportId: widget.sportId);
    final primaryConditioningLabel = SportDefaults.primaryConditioningLabel(
      l10n: l10n,
      sportId: widget.sportId,
    );
    final secondaryConditioningLabel = SportDefaults.secondaryConditioningLabel(
      l10n: l10n,
      sportId: widget.sportId,
    );
    final periodDays = _periodDayCount(widget.range);
    final activeDays =
        widget.entries.map((entry) => _dayOnly(entry.date)).toSet();
    final mealDays =
        widget.mealEntries.map((entry) => _dayOnly(entry.date)).toSet();
    final fullMealDays = widget.mealEntries
        .where((entry) => entry.completedMeals >= 3)
        .map((entry) => _dayOnly(entry.date))
        .toSet()
        .length;
    final lessonCount = widget.entries.where((entry) => entry.isLesson).length;
    final totalMinutes = widget.entries.fold<int>(
      0,
      (sum, entry) => sum + entry.durationMinutes,
    );
    final focus = _topFocusLabel(widget.entries, l10n);
    final streak = _currentTrainingStreak(widget.entries);
    final target = benchmarkTargetForSport(
      sportId: widget.sportId,
      ageYears: widget.ageYears,
      sportYears: widget.soccerYears,
    );
    final targetMinutes = widget.showTarget
        ? ((target.weeklyMinutesTarget / 7) * periodDays).round()
        : 0;
    final targetPercent = targetMinutes > 0
        ? ((totalMinutes / targetMinutes) * 100).round()
        : null;
    final plannedDays =
        widget.plans.map((plan) => _dayOnly(plan.scheduledAt)).toSet();
    final completedPlanDays = plannedDays.where(activeDays.contains).length;
    final planPercent = plannedDays.isEmpty
        ? null
        : ((completedPlanDays / plannedDays.length) * 100).round();
    final avgIntensity = widget.entries.fold<double>(
          0,
          (sum, entry) => sum + entry.intensity,
        ) /
        widget.entries.length;
    final avgMood = widget.entries.fold<double>(
          0,
          (sum, entry) => sum + entry.mood,
        ) /
        widget.entries.length;
    final injuryDays = widget.entries
        .where((entry) => entry.injury)
        .map((entry) {
          return _dayOnly(entry.date);
        })
        .toSet()
        .length;
    final primaryMinutes = widget.entries.fold<int>(
      0,
      (sum, entry) => sum + entry.jumpRopeMinutes,
    );
    final primaryCount = widget.entries.fold<int>(
      0,
      (sum, entry) => sum + entry.jumpRopeCount,
    );
    final secondaryMinutes = widget.entries.fold<int>(
      0,
      (sum, entry) => sum + entry.liftingMinutes,
    );
    final secondaryCount = widget.entries.fold<int>(
      0,
      (sum, entry) =>
          sum +
          entry.liftingByPart.values.fold<int>(
            0,
            (partSum, value) => partSum + value,
          ),
    );
    final conditioningTotal =
        primaryMinutes + primaryCount + secondaryMinutes + secondaryCount;
    final totalTimeText = _formatMinutesAsTime(totalMinutes, l10n: l10n);
    final planText = planPercent == null
        ? l10n.statsReportNoPlanValue
        : l10n.statsReportTargetPercentValue(planPercent);
    final insight = _trainingInsight(
      l10n: l10n,
      sportLabel: sportLabel,
      targetPercent: targetPercent,
      activeDayCount: activeDays.length,
      periodDays: periodDays,
      mealDayCount: mealDays.length,
      injuryDays: injuryDays,
      avgMood: avgMood,
      conditioningTotal: conditioningTotal,
      primaryConditioningLabel: primaryConditioningLabel,
      secondaryConditioningLabel: secondaryConditioningLabel,
    );

    final progressLabel =
        targetPercent != null ? l10n.statsReportTargetProgressLabel : null;
    final progressPercent = targetPercent ?? planPercent;
    final progressValue = progressPercent == null
        ? null
        : l10n.statsReportTargetPercentValue(progressPercent);
    final progressTitle = progressLabel ??
        (planPercent != null ? l10n.statsReportPlanExecutionLabel : null);
    final progressFraction = progressPercent == null
        ? null
        : (progressPercent / 100).clamp(0.0, 1.0).toDouble();
    final coreRows = <_ReportMetric>[
      _ReportMetric(
        key: const ValueKey('stats-report-focus-row'),
        icon: Icons.center_focus_strong_outlined,
        label: l10n.statsReportFocusLabel,
        value: focus,
      ),
      _ReportMetric(
        key: const ValueKey('stats-report-lesson-row'),
        icon: Icons.school_outlined,
        label: l10n.statsReportLessonCountLabel,
        value: l10n.statsReportLessonCountValue(lessonCount),
      ),
    ];
    final detailRows = <_ReportMetric>[
      _ReportMetric(
        key: const ValueKey('stats-report-meal-row'),
        icon: Icons.restaurant_outlined,
        label: l10n.statsReportMealCoverageLabel,
        value: l10n.statsReportMealCoverageValue(
          mealDays.length,
          periodDays,
          fullMealDays,
        ),
      ),
      _ReportMetric(
        key: const ValueKey('stats-report-condition-row'),
        icon: Icons.favorite_border,
        label: l10n.statsReportConditionLabel,
        value: l10n.statsReportConditionValue(
          _oneDecimal(avgIntensity),
          _oneDecimal(avgMood),
          injuryDays,
        ),
      ),
      _ReportMetric(
        key: const ValueKey('stats-report-conditioning-row'),
        icon: Icons.fitness_center_outlined,
        label: l10n.statsReportConditioningLabel,
        value: l10n.statsReportConditioningValue(
          primaryMinutes + secondaryMinutes,
          primaryCount + secondaryCount,
        ),
      ),
      _ReportMetric(
        key: const ValueKey('stats-report-plan-row'),
        icon: Icons.event_available_outlined,
        label: l10n.statsReportPlanExecutionLabel,
        value: planText,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          icon: Icons.summarize_outlined,
          title: l10n.statsReportTrainingTitle(sportLabel),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.statsReportSummarySentence(
            totalTimeText,
            widget.entries.length,
            streak,
          ),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.statsReportActivityPeriodSummary(activeDays.length, periodDays),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
        ),
        if (progressTitle != null &&
            progressValue != null &&
            progressFraction != null) ...[
          const SizedBox(height: 12),
          _ReportProgressSummary(
            label: progressTitle,
            value: progressValue,
            progress: progressFraction,
          ),
        ],
        const SizedBox(height: 12),
        _ReportMetricList(
          key: const ValueKey('stats-report-core-metric-list'),
          metrics: coreRows,
        ),
        const SizedBox(height: 10),
        _CoachMessage(
          icon: Icons.tips_and_updates_outlined,
          title: l10n.statsReportInsightTitle,
          message: insight,
          maxLines: _detailsExpanded ? null : 2,
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Semantics(
            expanded: _detailsExpanded,
            child: TextButton(
              key: const ValueKey('stats-report-details-toggle'),
              onPressed: () {
                setState(() {
                  _detailsExpanded = !_detailsExpanded;
                });
              },
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _detailsExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _detailsExpanded
                        ? l10n.statsReportCollapseDetailsAction
                        : l10n.statsReportExpandDetailsAction,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_detailsExpanded) ...[
          const SizedBox(height: 6),
          _ReportMetricList(
            key: const ValueKey('stats-report-detail-metric-list'),
            metrics: detailRows,
          ),
        ],
      ],
    );
  }

  String _trainingInsight({
    required AppLocalizations l10n,
    required String sportLabel,
    required int? targetPercent,
    required int activeDayCount,
    required int periodDays,
    required int mealDayCount,
    required int injuryDays,
    required double avgMood,
    required int conditioningTotal,
    required String primaryConditioningLabel,
    required String secondaryConditioningLabel,
  }) {
    if (injuryDays > 0 || avgMood < 2.6) {
      return l10n.statsReportInsightRecovery(
        injuryDays,
        _oneDecimal(avgMood),
      );
    }
    if (targetPercent != null && targetPercent < 70) {
      return l10n.statsReportInsightNeedsVolume(
        sportLabel,
        targetPercent,
        activeDayCount,
        periodDays,
      );
    }
    if (activeDayCount > 0 && mealDayCount < activeDayCount) {
      return l10n.statsReportInsightMealGap(mealDayCount, activeDayCount);
    }
    if (conditioningTotal == 0) {
      return l10n.statsReportInsightNoConditioning(
        primaryConditioningLabel,
        secondaryConditioningLabel,
      );
    }
    return l10n.statsReportInsightBalanced(
      sportLabel,
      activeDayCount,
      periodDays,
    );
  }
}

class _ReportProgressSummary extends StatelessWidget {
  final String label;
  final String value;
  final double progress;

  const _ReportProgressSummary({
    required this.label,
    required this.value,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              value,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            key: const ValueKey('stats-report-progress-indicator'),
            minHeight: 4,
            value: progress,
          ),
        ),
      ],
    );
  }
}

class _ReportMetric {
  final Key? key;
  final IconData icon;
  final String label;
  final String value;

  const _ReportMetric({
    this.key,
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _ReportMetricList extends StatelessWidget {
  final List<_ReportMetric> metrics;

  const _ReportMetricList({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final dividerColor =
        Theme.of(context).colorScheme.outline.withValues(alpha: 0.18);
    return Column(
      children: [
        for (var i = 0; i < metrics.length; i++) ...[
          _ReportMetricRow(
            key: metrics[i].key,
            icon: metrics[i].icon,
            label: metrics[i].label,
            value: metrics[i].value,
          ),
          if (i < metrics.length - 1)
            Divider(height: 1, thickness: 1, color: dividerColor),
        ],
      ],
    );
  }
}

class _ReportMetricRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ReportMetricRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final labelStyle = theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                );
                final valueStyle = theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                );
                if (constraints.maxWidth < 260) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: labelStyle),
                      const SizedBox(height: 2),
                      Text(value, style: valueStyle),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(label, style: labelStyle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 5,
                      child: Text(
                        value,
                        textAlign: TextAlign.end,
                        style: valueStyle,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MealTrendCard extends StatelessWidget {
  final List<MealEntry> mealEntries;
  final DateTimeRange range;

  const _MealTrendCard({required this.mealEntries, required this.range});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dayStart = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final dayEnd = DateTime(range.end.year, range.end.month, range.end.day);
    final days = <DateTime>[];
    for (var cursor = dayStart;
        !cursor.isAfter(dayEnd);
        cursor = cursor.add(const Duration(days: 1))) {
      days.add(cursor);
    }

    final mealByDay = <String, MealEntry>{};
    for (final entry in mealEntries) {
      mealByDay[_dayToken(entry.date)] = entry;
    }
    final maxMeal = mealByDay.values.fold<double>(
      MealLogService.expectedBowlsPerDay,
      (maxValue, entry) => math.max(maxValue, entry.totalRiceBowls),
    );
    final chartMaxY = math.max(3.5, (maxMeal + 0.5).ceilToDouble());
    final labelStride = math.max(1, (days.length / 6).ceil());
    const breakfastColor = Color(0xFFF59E0B);
    const lunchColor = Color(0xFFD97706);
    const dinnerColor = Color(0xFF92400E);
    final barGroups = <BarChartGroupData>[
      for (var i = 0; i < days.length; i++)
        _buildMealBarGroup(
          index: i,
          entry: mealByDay[_dayToken(days[i])],
          breakfastColor: breakfastColor,
          lunchColor: lunchColor,
          dinnerColor: dinnerColor,
        ),
    ];

    final totalBowls = mealEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.totalRiceBowls,
    );
    final averageActual = totalBowls / mealEntries.length;
    final bestDay = mealEntries.reduce(
      (best, current) =>
          current.totalRiceBowls > best.totalRiceBowls ? current : best,
    );
    final totalNutrition = mealEntries
        .map(MealCalorieEstimator.estimate)
        .fold<MealNutritionEstimate>(
          const MealNutritionEstimate(kcal: 0),
          (sum, estimate) => sum.plus(
            MealNutritionEstimate(
              kcal: estimate.totalKcal,
              carbs: estimate.totalCarbs,
              protein: estimate.totalProtein,
              fat: estimate.totalFat,
            ),
          ),
        );
    final averageNutrition = totalNutrition.scaled(1 / mealEntries.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.rice_bowl_outlined,
          title: l10n.mealStatsSectionTitle,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.mealStatsTrendTitle,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: chartMaxY,
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.16),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: BarTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final entry = mealByDay[_dayToken(days[group.x.toInt()])];
                    final day = days[group.x.toInt()];
                    final breakfast = entry?.breakfastRiceBowls ?? 0;
                    final lunch = entry?.lunchRiceBowls ?? 0;
                    final dinner = entry?.dinnerRiceBowls ?? 0;
                    return BarTooltipItem(
                      '${day.month}/${day.day}\n'
                      '${l10n.mealBreakfast} ${_formatBowls(breakfast)}\n'
                      '${l10n.mealLunch} ${_formatBowls(lunch)}\n'
                      '${l10n.mealDinner} ${_formatBowls(dinner)}\n'
                      '${l10n.mealShortLabel} ${_formatBowls(rod.toY)}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 1,
                    getTitlesWidget: (value, meta) => Text(
                      _formatBowls(value),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= days.length) {
                        return const SizedBox.shrink();
                      }
                      if (index % labelStride != 0 &&
                          index != days.length - 1) {
                        return const SizedBox.shrink();
                      }
                      final day = days[index];
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${day.month}/${day.day}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: barGroups,
              alignment: BarChartAlignment.spaceAround,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Center(
                child: _LegendDot(
                  color: breakfastColor,
                  label: l10n.mealBreakfast,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: _LegendDot(color: lunchColor, label: l10n.mealLunch),
              ),
            ),
            Expanded(
              child: Center(
                child: _LegendDot(color: dinnerColor, label: l10n.mealDinner),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _CompactMetricChip(
                label: l10n.mealStatsLoggedDays,
                value: '${mealEntries.length}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CompactMetricChip(
                label: l10n.mealStatsActualAverage,
                value: l10n.mealAverageActualValue(_formatBowls(averageActual)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CompactMetricChip(
                label: l10n.mealStatsBestDay,
                value:
                    '${bestDay.date.month}/${bestDay.date.day} · ${_formatBowls(bestDay.totalRiceBowls)}',
              ),
            ),
          ],
        ),
        if (totalNutrition.kcal > 0) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _CompactMetricChip(
                  label: l10n.mealStatsAverageCalories,
                  value: l10n.mealCalorieEstimateValue(
                    averageNutrition.kcal,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompactMetricChip(
                  label: l10n.mealStatsTotalCalories,
                  value: l10n.mealCalorieEstimateValue(totalNutrition.kcal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _CompactMetricChip(
            label: l10n.mealStatsAverageNutrition,
            value: l10n.mealNutritionEstimateValue(
              averageNutrition.carbs.round(),
              averageNutrition.protein.round(),
              averageNutrition.fat.round(),
            ),
          ),
        ],
      ],
    );
  }

  BarChartGroupData _buildMealBarGroup({
    required int index,
    required MealEntry? entry,
    required Color breakfastColor,
    required Color lunchColor,
    required Color dinnerColor,
  }) {
    final breakfast = entry?.breakfastRiceBowls ?? 0;
    final lunch = entry?.lunchRiceBowls ?? 0;
    final dinner = entry?.dinnerRiceBowls ?? 0;
    final hasValue = breakfast > 0 || lunch > 0 || dinner > 0;
    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: hasValue ? breakfast + lunch + dinner : 0,
          width: 18,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          color: breakfastColor.withValues(alpha: 0.2),
          rodStackItems: [
            if (breakfast > 0)
              BarChartRodStackItem(0, breakfast, breakfastColor),
            if (lunch > 0)
              BarChartRodStackItem(breakfast, breakfast + lunch, lunchColor),
            if (dinner > 0)
              BarChartRodStackItem(
                breakfast + lunch,
                breakfast + lunch + dinner,
                dinnerColor,
              ),
          ],
        ),
      ],
    );
  }

  static String _dayToken(DateTime day) {
    return '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
  }

  static String _formatBowls(double bowls) {
    return bowls == bowls.truncateToDouble()
        ? bowls.toStringAsFixed(0)
        : bowls.toStringAsFixed(1);
  }
}

class _CompactMetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _CompactMetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _statsFlatDecoration(context, accentAlpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchCompetitionStatsSection extends StatelessWidget {
  final List<TrainingEntry> entries;
  final List<MatchCompetitionRecord> competitionRecords;

  const _MatchCompetitionStatsSection({
    required this.entries,
    required this.competitionRecords,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final leagueSummaries = _buildCompetitionSummaries(
      kind: MatchCompetitionRecord.kindLeague,
      entries: entries,
      competitionRecords: competitionRecords,
    );
    final tournamentSummaries = _buildCompetitionSummaries(
      kind: MatchCompetitionRecord.kindTournament,
      entries: entries,
      competitionRecords: competitionRecords,
    );

    if (leagueSummaries.isEmpty && tournamentSummaries.isEmpty) {
      return _InlineNotice(text: l10n.matchCompetitionNoMatches);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          icon: Icons.emoji_events_outlined,
          title: l10n.statsCompetitionDashboardTitle,
        ),
        if (leagueSummaries.isNotEmpty) ...[
          const SizedBox(height: 14),
          _CompetitionGroupHeader(
            icon: Icons.table_chart_outlined,
            title: l10n.statsCompetitionLeagueSectionTitle,
            count: leagueSummaries.length,
          ),
          const SizedBox(height: 10),
          ...leagueSummaries.map(
            (summary) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LeagueCompetitionCard(summary: summary),
            ),
          ),
        ],
        if (tournamentSummaries.isNotEmpty) ...[
          const SizedBox(height: 14),
          _CompetitionGroupHeader(
            icon: Icons.account_tree_outlined,
            title: l10n.statsCompetitionTournamentSectionTitle,
            count: tournamentSummaries.length,
          ),
          const SizedBox(height: 10),
          ...tournamentSummaries.map(
            (summary) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TournamentCompetitionCard(summary: summary),
            ),
          ),
        ],
      ],
    );
  }
}

class _CompetitionSummary {
  final String kind;
  final String name;
  final List<String> teams;
  final List<TrainingEntry> entries;
  final MatchCompetitionRecord? record;

  const _CompetitionSummary({
    required this.kind,
    required this.name,
    required this.teams,
    required this.entries,
    required this.record,
  });

  bool get isFinished => record?.isFinished ?? false;

  DateTime get updatedAt =>
      record?.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
}

class _CompetitionMetric {
  final String label;
  final String value;

  const _CompetitionMetric({required this.label, required this.value});
}

List<_CompetitionSummary> _buildCompetitionSummaries({
  required String kind,
  required List<TrainingEntry> entries,
  required List<MatchCompetitionRecord> competitionRecords,
}) {
  final recordsByKey = <String, MatchCompetitionRecord>{};
  final namesByKey = <String, String>{};
  final entriesByKey = <String, List<TrainingEntry>>{};

  for (final record in competitionRecords) {
    if (record.kind != kind) continue;
    final name = record.name.trim();
    final key = _competitionKey(name);
    if (key.isEmpty) continue;
    recordsByKey[key] = record;
    namesByKey[key] = name;
  }

  for (final entry in entries) {
    final matchesKind = kind == MatchCompetitionRecord.kindTournament
        ? entry.isTournamentMatch
        : entry.isLeagueMatch;
    if (!matchesKind) continue;
    final name = entry.matchCompetitionName.trim();
    final key = _competitionKey(name);
    if (key.isEmpty) continue;
    namesByKey.putIfAbsent(key, () => name);
    entriesByKey.putIfAbsent(key, () => <TrainingEntry>[]).add(entry);
  }

  final summaries = <_CompetitionSummary>[];
  for (final key in namesByKey.keys) {
    final record = recordsByKey[key];
    final groupedEntries =
        entriesByKey[key]?.toList(growable: false) ?? const <TrainingEntry>[];
    final teams = MatchCompetitionService.normalizeTeams([
      ...?record?.teams,
      for (final entry in groupedEntries) ...entry.leagueTeamNames,
      for (final entry in groupedEntries) entry.opponentTeam,
    ]);
    summaries.add(
      _CompetitionSummary(
        kind: kind,
        name: record?.name.trim().isNotEmpty == true
            ? record!.name.trim()
            : namesByKey[key]!,
        teams: teams,
        entries: groupedEntries,
        record: record,
      ),
    );
  }

  summaries.sort((a, b) {
    final statusCompare =
        (a.isFinished ? 1 : 0).compareTo(b.isFinished ? 1 : 0);
    if (statusCompare != 0) return statusCompare;
    final entryCompare = b.entries.length.compareTo(a.entries.length);
    if (entryCompare != 0) return entryCompare;
    final updatedCompare = b.updatedAt.compareTo(a.updatedAt);
    if (updatedCompare != 0) return updatedCompare;
    return a.name.compareTo(b.name);
  });
  return summaries;
}

String _competitionKey(String value) => value.trim().toLowerCase();

class _CompetitionGroupHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;

  const _CompetitionGroupHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _CompetitionStatusPill(text: '$count'),
      ],
    );
  }
}

class _LeagueCompetitionCard extends StatelessWidget {
  final _CompetitionSummary summary;

  const _LeagueCompetitionCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final standings = MatchCompetitionService.buildLeagueStandings(
      competitionName: summary.name,
      registeredTeams: summary.teams,
      entries: summary.entries,
      ownTeamName: l10n.matchCompetitionMyTeamFallback,
    );
    final leader = standings.isEmpty
        ? l10n.matchCompetitionNoLeader
        : standings.first.team;
    final expectedMatches = summary.teams.length <= 1
        ? summary.entries.length
        : math.max(summary.entries.length, summary.teams.length - 1);
    final topRows = standings.take(4).toList(growable: false);

    return _CompetitionCardShell(
      icon: Icons.table_rows_outlined,
      title: summary.name,
      statusText: summary.isFinished
          ? l10n.matchCompetitionStatusFinished
          : l10n.matchCompetitionStatusActive,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CompetitionMetricGrid(
            metrics: [
              _CompetitionMetric(
                label: l10n.matchCompetitionSummaryTeams,
                value: '${summary.teams.length}',
              ),
              _CompetitionMetric(
                label: l10n.matchCompetitionSummaryMatches,
                value: '${summary.entries.length}',
              ),
              _CompetitionMetric(
                label: l10n.matchCompetitionSummaryLeader,
                value: leader,
              ),
              _CompetitionMetric(
                label: l10n.matchCompetitionSummaryProgress,
                value: l10n.statsCompetitionProgressValue(
                  summary.entries.length,
                  expectedMatches,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MiniSectionHeader(
            icon: Icons.leaderboard_outlined,
            title: l10n.matchLeagueStandingsTitle,
          ),
          const SizedBox(height: 8),
          if (topRows.isEmpty)
            _InlineNotice(text: l10n.matchCompetitionNoMatches)
          else ...[
            ...topRows.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _LeagueStandingCompactRow(
                      rank: entry.key + 1,
                      row: entry.value,
                    ),
                  ),
                ),
            if (standings.length > topRows.length)
              _MoreCountLine(
                text: l10n.statsCompetitionMoreCount(
                  standings.length - topRows.length,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TournamentCompetitionCard extends StatelessWidget {
  final _CompetitionSummary summary;

  const _TournamentCompetitionCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pairs = MatchCompetitionService.buildTournamentBracketPairs(
      summary.teams,
    );
    final expectedSlots = math.max(pairs.length, summary.entries.length);
    final visiblePairs = pairs.take(4).toList(growable: false);
    final recentEntries = summary.entries.toList(growable: false)
      ..sort(TrainingEntry.compareByRecentCreated);
    final visibleEntries = recentEntries.take(3).toList(growable: false);

    return _CompetitionCardShell(
      icon: Icons.account_tree_outlined,
      title: summary.name,
      statusText: summary.isFinished
          ? l10n.matchCompetitionStatusFinished
          : l10n.matchCompetitionStatusActive,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CompetitionMetricGrid(
            metrics: [
              _CompetitionMetric(
                label: l10n.matchCompetitionSummaryTeams,
                value: '${summary.teams.length}',
              ),
              _CompetitionMetric(
                label: l10n.matchTournamentSummarySlots,
                value: '${pairs.length}',
              ),
              _CompetitionMetric(
                label: l10n.matchCompetitionSummaryRecorded,
                value: '${summary.entries.length}',
              ),
              _CompetitionMetric(
                label: l10n.matchCompetitionSummaryProgress,
                value: l10n.statsCompetitionProgressValue(
                  summary.entries.length,
                  expectedSlots,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MiniSectionHeader(
            icon: Icons.schema_outlined,
            title: l10n.matchTournamentBracketTitle,
          ),
          const SizedBox(height: 8),
          if (visiblePairs.isEmpty)
            _InlineNotice(text: l10n.matchCompetitionNoTeams)
          else ...[
            ...visiblePairs.map(
              (pair) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TournamentPairCompactRow(pair: pair),
              ),
            ),
            if (pairs.length > visiblePairs.length)
              _MoreCountLine(
                text: l10n.statsCompetitionMoreCount(
                  pairs.length - visiblePairs.length,
                ),
              ),
          ],
          const SizedBox(height: 10),
          _MiniSectionHeader(
            icon: Icons.history_toggle_off_outlined,
            title: l10n.matchTournamentRecordedProgressTitle,
          ),
          const SizedBox(height: 8),
          if (visibleEntries.isEmpty)
            _InlineNotice(text: l10n.matchCompetitionNoMatches)
          else ...[
            ...visibleEntries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TournamentProgressCompactRow(entry: entry),
              ),
            ),
            if (recentEntries.length > visibleEntries.length)
              _MoreCountLine(
                text: l10n.statsCompetitionMoreCount(
                  recentEntries.length - visibleEntries.length,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _CompetitionCardShell extends StatelessWidget {
  final IconData icon;
  final String title;
  final String statusText;
  final Widget child;

  const _CompetitionCardShell({
    required this.icon,
    required this.title,
    required this.statusText,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _statsFlatDecoration(context, accentAlpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.small,
                ),
                child: Icon(icon, size: 18, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _CompetitionStatusPill(text: statusText),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CompetitionMetricGrid extends StatelessWidget {
  final List<_CompetitionMetric> metrics;

  const _CompetitionMetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 ? 4 : 2;
        final width = (constraints.maxWidth - (8 * (columns - 1))) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: width,
                  child: _CompactMetricChip(
                    label: metric.label,
                    value: metric.value,
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _MiniSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _MiniSectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompetitionStatusPill extends StatelessWidget {
  final String text;

  const _CompetitionStatusPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LeagueStandingCompactRow extends StatelessWidget {
  final int rank;
  final LeagueStandingRow row;

  const _LeagueStandingCompactRow({required this.rank, required this.row});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return _CompetitionDataRow(
      leading: Text(
        '#$rank',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
      title: row.team,
      subtitle: [
        l10n.matchLeaguePlayedSummary(row.played),
        l10n.matchLeagueRecordSummary(row.wins, row.draws, row.losses),
        l10n.matchLeagueGoalDifferenceSummary(row.goalDifference),
      ].join(' · '),
      trailing: l10n.matchLeaguePointsSummary(row.points),
    );
  }
}

class _TournamentPairCompactRow extends StatelessWidget {
  final TournamentBracketPair pair;

  const _TournamentPairCompactRow({required this.pair});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _CompetitionDataRow(
      leading: const Icon(Icons.sports_outlined, size: 18),
      title: pair.hasBye
          ? pair.teamA
          : l10n.matchTournamentPairText(pair.teamA, pair.teamB),
      subtitle: l10n.matchTournamentPairLabel(pair.slotNumber),
      trailing: pair.hasBye
          ? l10n.matchTournamentPairByeStatus
          : l10n.matchTournamentPairPending,
    );
  }
}

class _TournamentProgressCompactRow extends StatelessWidget {
  final TrainingEntry entry;

  const _TournamentProgressCompactRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final opponent = entry.opponentTeam.trim().isEmpty
        ? l10n.statsCompetitionOpponentUnset
        : entry.opponentTeam.trim();
    final stage = matchTournamentStageLabel(l10n, entry.matchStage);
    final outcome = matchTournamentOutcomeLabel(l10n, entry.tournamentOutcome);
    return _CompetitionDataRow(
      leading: Icon(
        Icons.flag_outlined,
        size: 18,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: l10n.matchTournamentRecordedProgress(stage, opponent, outcome),
      subtitle: DateFormat.yMMMd(Localizations.localeOf(context).toString())
          .format(entry.date),
      trailing: entry.tournamentWins == null
          ? null
          : l10n.matchTournamentWinsValue(entry.tournamentWins!),
    );
  }
}

class _CompetitionDataRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final String? trailing;

  const _CompetitionDataRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.42),
        borderRadius: AppRadius.small,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 34, child: Center(child: leading)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Text(
              trailing!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MoreCountLine extends StatelessWidget {
  final String text;

  const _MoreCountLine({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MatchSummaryCard extends StatelessWidget {
  final List<TrainingEntry> entries;
  final String sportId;

  const _MatchSummaryCard({required this.entries, required this.sportId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sportLabel = SportDefaults.label(l10n: l10n, sportId: sportId);
    final labels = SportMatchLabels.forSport(
      l10n: l10n,
      sportId: sportId,
    );
    final resultEntries = entries
        .where(
          (entry) => entry.scoredGoals != null || entry.concededGoals != null,
        )
        .toList(growable: false);
    final wins =
        resultEntries.where((entry) => _matchOutcome(entry) == 1).length;
    final draws =
        resultEntries.where((entry) => _matchOutcome(entry) == 0).length;
    final losses =
        resultEntries.where((entry) => _matchOutcome(entry) == -1).length;
    final scoredEntries = entries
        .where(
          (entry) => entry.scoredGoals != null && entry.concededGoals != null,
        )
        .toList(growable: false);
    final scored = scoredEntries.fold<int>(
      0,
      (sum, entry) => sum + (entry.scoredGoals ?? 0),
    );
    final conceded = scoredEntries.fold<int>(
      0,
      (sum, entry) => sum + (entry.concededGoals ?? 0),
    );
    final winRate = resultEntries.isEmpty
        ? null
        : ((wins / resultEntries.length) * 100).round();
    final scoredAverage = scoredEntries.isEmpty
        ? null
        : scoredEntries.fold<double>(
              0,
              (sum, entry) => sum + (entry.scoredGoals ?? 0),
            ) /
            scoredEntries.length;
    final concededAverage = scoredEntries.isEmpty
        ? null
        : scoredEntries.fold<double>(
              0,
              (sum, entry) => sum + (entry.concededGoals ?? 0),
            ) /
            scoredEntries.length;
    final playerGoals = entries.fold<int>(
      0,
      (sum, entry) => sum + (entry.playerGoals ?? 0),
    );
    final playerAssists = entries.fold<int>(
      0,
      (sum, entry) => sum + (entry.playerAssists ?? 0),
    );
    final shotsOnTarget = entries.fold<int>(
      0,
      (sum, entry) => sum + (entry.shotsOnTarget ?? 0),
    );
    final ballsWon = entries.fold<int>(
      0,
      (sum, entry) => sum + (entry.ballsWon ?? 0),
    );
    final yellowCards = entries.fold<int>(
      0,
      (sum, entry) => sum + (entry.yellowCards ?? 0),
    );
    final redCards = entries.fold<int>(
      0,
      (sum, entry) => sum + (entry.redCards ?? 0),
    );
    final friendlyCount = entries
        .where((entry) => !entry.isLeagueMatch && !entry.isTournamentMatch)
        .length;
    final leagueCount = entries.where((entry) => entry.isLeagueMatch).length;
    final tournamentCount =
        entries.where((entry) => entry.isTournamentMatch).length;
    final leaguePoints = entries
        .where((entry) => entry.isLeagueMatch)
        .fold<int>(0, (sum, entry) => sum + (entry.leaguePoints ?? 0));
    final tournamentWins = entries
        .where((entry) => entry.isTournamentMatch)
        .fold<int>(0, (sum, entry) => sum + (entry.tournamentWins ?? 0));
    final totalMinutes = entries.fold<int>(
      0,
      (sum, entry) => sum + (entry.minutesPlayed ?? 0),
    );
    final primaryAverage = playerGoals / entries.length;
    final secondaryAverage = playerAssists / entries.length;
    final rateMinutes = _matchRateMinutesForSport(sportId);
    final canShowRate = rateMinutes != null && totalMinutes > 0;
    final recentResults = [...resultEntries]
      ..sort((a, b) => b.date.compareTo(a.date));
    final form = _matchFormText(recentResults.take(5).toList(), l10n);
    final insight = winRate == null
        ? l10n.statsMatchFormInsightNoResults(sportLabel)
        : winRate >= 50
            ? l10n.statsMatchFormInsightPositive(sportLabel, form, winRate)
            : l10n.statsMatchFormInsightNeedsWork(sportLabel, form, winRate);
    final resultCards = <_MetricCard>[
      _MetricCard(
        label: l10n.statsMatchTotalMatchesLabel,
        value: l10n.statsMatchTotalMatchesValue(entries.length),
      ),
      _MetricCard(
        label: l10n.statsMatchRecordLabel,
        value: resultEntries.isEmpty
            ? l10n.statsMatchUnsetValue
            : l10n.statsMatchRecordValue(wins, draws, losses),
      ),
      _MetricCard(
        label: l10n.statsMatchWinRateLabel,
        value: winRate == null
            ? l10n.statsMatchUnsetValue
            : l10n.statsMatchWinRateValue(winRate),
      ),
      _MetricCard(
        label: l10n.statsMatchAverageScoreLabel,
        value: scoredAverage == null || concededAverage == null
            ? l10n.statsMatchUnsetValue
            : l10n.statsMatchAverageScoreValue(
                _oneDecimal(scoredAverage),
                _oneDecimal(concededAverage),
              ),
      ),
      _MetricCard(
        label: l10n.statsMatchTypeLabel,
        value:
            '${l10n.matchKindFriendly} $friendlyCount · ${l10n.matchKindLeague} $leagueCount · ${l10n.matchKindTournament} $tournamentCount',
      ),
      if (leagueCount > 0)
        _MetricCard(
          label: l10n.matchKindLeague,
          value: l10n.matchLeaguePointsValue(leaguePoints),
        ),
      if (tournamentCount > 0)
        _MetricCard(
          label: l10n.matchKindTournament,
          value: l10n.matchTournamentWinsValue(tournamentWins),
        ),
      _MetricCard(
        label: l10n.statsMatchGoalsLabel,
        value: '$scored:$conceded',
      ),
    ];
    final personalCards = <_MetricCard>[
      _MetricCard(
        label: l10n.statsMatchFormLabel,
        value: form,
      ),
      _MetricCard(
        label: l10n.statsMatchPersonalPerMatchLabel,
        value: l10n.statsMatchPersonalPerMatchValue(
          labels.primary.label,
          _oneDecimal(primaryAverage),
          labels.secondary.label,
          _oneDecimal(secondaryAverage),
        ),
      ),
      if (canShowRate)
        _MetricCard(
          label: l10n.statsMatchPerUnitLabel(rateMinutes),
          value: l10n.statsMatchPerUnitValue(
            labels.primary.label,
            _oneDecimal(playerGoals * rateMinutes / totalMinutes),
            labels.secondary.label,
            _oneDecimal(playerAssists * rateMinutes / totalMinutes),
          ),
        )
      else
        _MetricCard(
          label: l10n.statsMatchMinutesLabel,
          value: totalMinutes > 0
              ? l10n.minutes(totalMinutes)
              : l10n.statsMatchNoMinutesValue,
        ),
      _MetricCard(
        label: l10n.statsMatchPersonalTotalLabel,
        value: l10n.statsMatchPersonalPerMatchValue(
          labels.primary.label,
          '$playerGoals',
          labels.secondary.label,
          '$playerAssists',
        ),
      ),
      _MetricCard(
        label: l10n.statsMatchPersonalDetailLabel,
        value: l10n.statsMatchPersonalPerMatchValue(
          labels.tertiary.label,
          '$shotsOnTarget',
          labels.quaternary.label,
          '$ballsWon',
        ),
      ),
      if (yellowCards > 0 || redCards > 0)
        _MetricCard(
          label: l10n.matchDisciplineSummaryLabel,
          value: l10n.matchDisciplineSummary(yellowCards, redCards),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.scoreboard_outlined,
          title: l10n.statsMatchSummaryTitle,
        ),
        const SizedBox(height: 12),
        _CoachMessage(
          icon: Icons.insights_outlined,
          title: l10n.statsMatchFormInsightTitle,
          message: insight,
        ),
        const SizedBox(height: 14),
        _MetricGroup(
          icon: Icons.query_stats_outlined,
          title: l10n.statsMatchResultGroupTitle,
          cards: resultCards,
        ),
        const SizedBox(height: 14),
        _MetricGroup(
          icon: Icons.person_search_outlined,
          title: l10n.statsMatchPersonalGroupTitle,
          cards: personalCards,
        ),
      ],
    );
  }

  String _matchFormText(
    List<TrainingEntry> recentResultEntries,
    AppLocalizations l10n,
  ) {
    if (recentResultEntries.isEmpty) return l10n.statsMatchFormUnsetValue;
    final chronological = recentResultEntries.toList(growable: false)
      ..sort((a, b) => a.date.compareTo(b.date));
    return chronological.map((entry) {
      return switch (_matchOutcome(entry)) {
        1 => l10n.statsMatchOutcomeWinShort,
        -1 => l10n.statsMatchOutcomeLossShort,
        _ => l10n.statsMatchOutcomeDrawShort,
      };
    }).join(' ');
  }
}

class _MatchHistorySection extends StatelessWidget {
  final List<TrainingEntry> entries;

  const _MatchHistorySection({required this.entries});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sorted = [...entries]..sort(TrainingEntry.compareByRecentCreated);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.format_list_bulleted_outlined,
          title: l10n.statsAllMatchRecordsTitle,
        ),
        const SizedBox(height: 12),
        ...sorted.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MatchHistoryTile(entry: entry),
          ),
        ),
      ],
    );
  }
}

class _MatchHistoryTile extends StatelessWidget {
  final TrainingEntry entry;

  const _MatchHistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final l10n = AppLocalizations.of(context)!;
    final labels = SportMatchLabels.forSport(
      l10n: l10n,
      sportId: entry.sportId,
    );
    final opponent = entry.opponentTeam.trim().isEmpty
        ? l10n.statsCompetitionOpponentUnset
        : entry.opponentTeam.trim();
    final competitionLine =
        matchCompetitionDetailParts(entry, l10n, teamLimit: 4).join(' · ');
    final detailLine = [
      if (competitionLine.isNotEmpty) competitionLine,
      ...labels.personalRecordParts(entry),
      if (entry.yellowCards != null)
        '${l10n.matchYellowCardsLabel} ${entry.yellowCards}',
      if (entry.redCards != null)
        '${l10n.matchRedCardsLabel} ${entry.redCards}',
      if (entry.minutesPlayed != null)
        l10n.statsMatchMinutesPlayedValue(entry.minutesPlayed!),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _statsFlatDecoration(context, accentAlpha: 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat.yMMMd(locale).add_E().format(entry.date),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${matchKindLabel(entry, l10n)} · $opponent',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            _matchResultLabel(entry, l10n: l10n),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (detailLine.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(detailLine),
          ],
          if (entry.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              entry.notes.trim(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricGroup extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<_MetricCard> cards;

  const _MetricGroup({
    required this.icon,
    required this.title,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MiniSectionHeader(icon: icon, title: title),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 760 ? 4 : 2;
            final width =
                (constraints.maxWidth - (10 * (columns - 1))) / columns;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: cards
                  .map((card) => SizedBox(width: width, child: card))
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;

  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: _statsFlatDecoration(context, accentAlpha: 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

int _matchOutcome(TrainingEntry entry) {
  final scored = entry.scoredGoals;
  final conceded = entry.concededGoals;
  if (scored == null || conceded == null) return 0;
  if (scored > conceded) return 1;
  if (scored < conceded) return -1;
  return 0;
}

int? _matchRateMinutesForSport(String? sportId) {
  switch (SportCatalog.normalizeSportId(sportId)) {
    case SportCatalog.footballId:
      return 90;
    case SportCatalog.basketballId:
      return 40;
    default:
      return null;
  }
}

String _matchResultLabel(TrainingEntry entry,
    {required AppLocalizations l10n}) {
  final scored = entry.scoredGoals;
  final conceded = entry.concededGoals;
  if (scored == null && conceded == null) {
    return l10n.statsResultUnset;
  }
  final resultLabel = switch (_matchOutcome(entry)) {
    1 => l10n.statsOutcomeWin,
    -1 => l10n.statsOutcomeLoss,
    _ => l10n.statsOutcomeDraw,
  };
  return '$resultLabel ${scored ?? '-'}:${conceded ?? '-'}';
}

class _InlineNotice extends StatelessWidget {
  final String text;
  final String? title;
  final Widget? trailing;

  const _InlineNotice({required this.text, this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outline = theme.colorScheme.outline.withValues(alpha: 0.3);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            width: 3,
            color: theme.colorScheme.primary.withValues(alpha: 0.75),
          ),
        ),
        color: AppSurfaces.subtleColor(theme.colorScheme, theme.brightness),
        borderRadius: AppRadius.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
          ],
          Text(text),
          if (trailing != null) ...[const SizedBox(height: 8), trailing!],
          const SizedBox(height: 2),
          Divider(height: 1, color: outline),
        ],
      ),
    );
  }
}

class _PartBest {
  final int count;
  final DateTime date;
  final int increase;

  const _PartBest({
    required this.count,
    required this.date,
    required this.increase,
  });
}

class _StatsPlanLite {
  final DateTime scheduledAt;

  const _StatsPlanLite({required this.scheduledAt});

  factory _StatsPlanLite.fromMap(Map<String, dynamic> map) {
    return _StatsPlanLite(
      scheduledAt: DateTime.tryParse(map['scheduledAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

String _topFocusLabel(List<TrainingEntry> entries, AppLocalizations l10n) {
  final counts = <String, int>{};
  for (final entry in entries) {
    for (final value in <String>[
      ...entry.goalFocuses,
      entry.program,
      ...entry.effectiveTrainingProgramMinutes.keys,
      entry.type,
    ]) {
      final text = value.trim();
      if (text.isEmpty) continue;
      counts[text] = (counts[text] ?? 0) + 1;
    }
  }
  if (counts.isEmpty) {
    return l10n.statsReportDefaultFocus;
  }
  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return sorted.first.key;
}

int _currentTrainingStreak(List<TrainingEntry> entries) {
  final workedDays = entries
      .map(
        (entry) => DateTime(entry.date.year, entry.date.month, entry.date.day),
      )
      .toSet()
      .toList(growable: false)
    ..sort((a, b) => b.compareTo(a));
  if (workedDays.isEmpty) return 0;
  var streak = 1;
  for (var i = 1; i < workedDays.length; i++) {
    final gap = workedDays[i - 1].difference(workedDays[i]).inDays;
    if (gap == 1) {
      streak += 1;
      continue;
    }
    break;
  }
  return streak;
}

class _PartRecord {
  final int count;
  final DateTime date;

  const _PartRecord({required this.count, required this.date});
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const _SectionTitle({required this.icon, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 18, color: accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

BoxDecoration _statsFlatDecoration(
  BuildContext context, {
  Color? accent,
  double accentAlpha = 0.06,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final brightness = theme.brightness;
  final tint = accent ?? scheme.primary;
  final base = AppSurfaces.cardColor(scheme, brightness);
  final overlayAlpha = brightness == Brightness.dark
      ? (accentAlpha + 0.05).clamp(0.0, 1.0).toDouble()
      : accentAlpha;
  return BoxDecoration(
    color: Color.alphaBlend(tint.withValues(alpha: overlayAlpha), base),
    borderRadius: AppRadius.surface,
    border: Border.all(
      color:
          tint.withValues(alpha: brightness == Brightness.dark ? 0.28 : 0.18),
    ),
    boxShadow: AppShadows.surface(brightness),
  );
}

class _StatsPanel extends StatelessWidget {
  final Widget child;

  const _StatsPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brightness = theme.brightness;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: AppSurfaces.cardDecoration(colorScheme, brightness),
      child: child,
    );
  }
}

class _CoachMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final int? maxLines;

  const _CoachMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _statsFlatDecoration(context, accentAlpha: 0.05),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  maxLines: maxLines,
                  overflow: maxLines == null
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatMinutesAsTime(int minutes, {required AppLocalizations l10n}) {
  if (minutes <= 0) return l10n.statsDurationZeroMinutes;
  final hours = minutes ~/ 60;
  final remain = minutes % 60;
  if (hours <= 0) {
    return l10n.statsDurationMinutes(remain);
  }
  if (remain <= 0) {
    return l10n.statsDurationHours(hours);
  }
  return l10n.statsDurationHoursMinutes(hours, remain);
}

String _compactHourTick(double minuteValue, {required AppLocalizations l10n}) {
  final minutes = minuteValue.round();
  if (minutes <= 0) return l10n.statsCompactDurationZero;
  final hours = minutes ~/ 60;
  final remain = minutes % 60;
  if (hours <= 0) return l10n.statsCompactDurationMinutes(remain);
  if (remain <= 0) return l10n.statsCompactDurationHours(hours);
  return l10n.statsCompactDurationHoursMinutes(hours, remain);
}

DateTime _dayOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

int _periodDayCount(DateTimeRange range) {
  final start = _dayOnly(range.start);
  final end = _dayOnly(range.end);
  return math.max(1, end.difference(start).inDays + 1);
}

String _oneDecimal(double value) => value.toStringAsFixed(1);

class _ComparisonRow extends StatelessWidget {
  final String label;
  final String current;
  final String average;
  final String gap;
  final bool isPositive;

  const _ComparisonRow({
    required this.label,
    required this.current,
    required this.average,
    required this.gap,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final gapColor =
        isPositive ? const Color(0xFF3DDC84) : theme.colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: _statsFlatDecoration(
        context,
        accent: gapColor,
        accentAlpha: 0.04,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Text(
                gap,
                style: TextStyle(fontWeight: FontWeight.w700, color: gapColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${l10n.statsComparisonCurrentLabel}: $current'),
              Text('${l10n.statsComparisonAverageLabel}: $average'),
            ],
          ),
        ],
      ),
    );
  }
}
