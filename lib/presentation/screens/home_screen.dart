import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../application/training_service.dart';
import '../../application/family_access_service.dart';
import '../../application/meal_log_service.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/repositories/option_repository.dart';
import '../../application/locale_service.dart';
import '../../application/settings_service.dart';
import '../../application/backup_service.dart';
import '../../application/notification_app_link.dart';
import '../../application/sport_service.dart';
import '../../application/training_plan_reminder_service.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'calendar_screen.dart';
import 'logs_screen.dart';
import 'stats_screen.dart';
import 'entry_form_screen.dart';
import 'meal_log_screen.dart';
import '../widgets/app_page_route.dart';
import '../widgets/sport_scope.dart';
import 'skill_quiz_screen.dart';
import 'home_hub_screen.dart';
import 'training_board_list_screen.dart';
import 'coach_lesson_screen.dart';

class HomeScreen extends StatefulWidget {
  final TrainingService trainingService;
  final MealLogService mealLogService;
  final OptionRepository optionRepository;
  final LocaleService localeService;
  final SettingsService settingsService;
  final BackupService? driveBackupService;
  final int initialIndex;
  final DateTime? initialCalendarSelectedDay;
  final CalendarQuickCreateAction? calendarQuickCreateAction;

  const HomeScreen({
    super.key,
    required this.trainingService,
    required this.mealLogService,
    required this.optionRepository,
    required this.localeService,
    required this.settingsService,
    this.driveBackupService,
    this.initialIndex = 0,
    this.initialCalendarSelectedDay,
    this.calendarQuickCreateAction,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const Duration _familySyncInterval = Duration(minutes: 15);
  late int _index;
  DateTime? _calendarSelectedDay;
  DateTimeRange? _statsInitialRange;
  int _statsInitialRangeRequestKey = 0;
  int _openTodayDiaryRequestKey = 0;
  late final Set<int> _builtTabIndices;
  CalendarQuickCreateAction? _pendingCalendarQuickCreateAction;
  final Set<int> _guideCheckedInSession = <int>{};
  bool _routePushInFlight = false;
  Timer? _familySyncTimer;
  bool _familySyncInFlight = false;
  StreamSubscription<void>? _backupDataChangeSubscription;
  int _dataRevision = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _index = widget.initialIndex;
    _calendarSelectedDay = widget.initialCalendarSelectedDay == null
        ? null
        : DateTime(
            widget.initialCalendarSelectedDay!.year,
            widget.initialCalendarSelectedDay!.month,
            widget.initialCalendarSelectedDay!.day,
          );
    _builtTabIndices = <int>{_index};
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showTabGuideIfNeeded(_index));
      unawaited(_syncFamilySharedDataIfNeeded());
    });
    _familySyncTimer = Timer.periodic(
      _familySyncInterval,
      (_) => unawaited(_syncFamilySharedDataIfNeeded()),
    );
    _backupDataChangeSubscription = widget.driveBackupService
        ?.dataChanges()
        .listen((_) => _handleBackupDataChanged());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _familySyncTimer?.cancel();
    unawaited(_backupDataChangeSubscription?.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncFamilySharedDataIfNeeded());
    }
  }

  Future<void> _syncFamilySharedDataIfNeeded() async {
    final backup = widget.driveBackupService;
    if (backup == null || _familySyncInFlight) return;
    _familySyncInFlight = true;
    try {
      try {
        await backup.autoBackupDaily();
      } catch (_) {
        // Daily backup can retry on the next timer tick or resume.
      }
      final pushedPending = backup.hasPendingParentSharedChanges()
          ? await backup.backupIfSignedIn()
          : false;
      final result = await backup.refreshFamilySharedDataIfNeeded();
      if (!mounted) return;
      if (pushedPending || result.refreshed) {
        widget.localeService.load();
        widget.settingsService.load();
        widget.mealLogService.reloadFromStorage();
        SportScope.read(context)?.reloadFromStorage();
        setState(() {});
      }
      if (!result.hasUserVisibleChanges) return;
      final l10n = AppLocalizations.of(context)!;
      final body = _familySyncAlertBody(result, l10n);
      if (body.trim().isEmpty) return;
      final syncedAt = DateTime.now();
      await TrainingPlanReminderService(
        widget.optionRepository,
        widget.settingsService,
      ).showFamilySyncAlert(
        body: body,
        payload: NotificationAppLink.familySync(
          role: result.role.name,
          syncedAt: syncedAt,
        ),
      );
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      // Shared sync can retry on the next timer tick or resume.
    } finally {
      _familySyncInFlight = false;
    }
  }

  void _handleBackupDataChanged() {
    widget.localeService.load();
    widget.settingsService.load();
    widget.mealLogService.reloadFromStorage();
    SportScope.read(context)?.reloadFromStorage();
    if (mounted) {
      setState(() => _dataRevision++);
    } else {
      _dataRevision++;
    }
  }

  String _familySyncAlertBody(
    FamilySharedSyncResult result,
    AppLocalizations l10n,
  ) {
    if (result.role == FamilyRole.child) {
      if (result.newParentFeedbackCount > 0 && result.rewardNamesChanged) {
        return l10n.familySyncChildFeedbackAndReward(
          result.newParentFeedbackCount,
        );
      }
      if (result.newParentFeedbackCount > 0) {
        return l10n.familySyncChildFeedbackAdded(result.newParentFeedbackCount);
      }
      if (result.rewardNamesChanged) {
        return l10n.familySyncChildRewardUpdated;
      }
      return '';
    }
    if (result.newTrainingEntryCount > 0 && result.newRewardClaimCount > 0) {
      return l10n.familySyncParentTrainingAndRewardClaimed(
        result.newTrainingEntryCount,
        result.newRewardClaimCount,
      );
    }
    if (result.newTrainingEntryCount > 0) {
      return l10n.familySyncParentTrainingAdded(result.newTrainingEntryCount);
    }
    if (result.newRewardClaimCount > 0) {
      return l10n.familySyncParentRewardClaimed(result.newRewardClaimCount);
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final sportId = SportScope.maybeOf(context)?.currentSportId ??
        SportService(widget.optionRepository).currentSportId();
    final navBackground = Theme.of(context).colorScheme.surface;
    final pages = <Widget>[
      _buildTabChild(
        0,
        sportId,
        HomeHubScreen(
          trainingService: widget.trainingService,
          mealLogService: widget.mealLogService,
          localeService: widget.localeService,
          optionRepository: widget.optionRepository,
          settingsService: widget.settingsService,
          driveBackupService: widget.driveBackupService,
          onCreate: _openCreate,
          onQuickPlan: () =>
              _openCalendarQuickCreate(CalendarQuickCreateAction.plan),
          onQuickMatch: () =>
              _openCalendarQuickCreate(CalendarQuickCreateAction.match),
          onQuickQuiz: _openQuiz,
          onQuickMeal: () => _openMealLog(initialDate: DateTime.now()),
          onQuickBoard: _openTrainingBoards,
          onOpenPlans: _openPlans,
          onOpenPlansForDay: _openPlansForDay,
          onOpenLogs: () => _onDestinationSelected(1),
          onOpenDiary: _openTodayDiary,
          onOpenWeeklyStats: _openWeeklyStatsForCurrentWeek,
          onEdit: _openEdit,
          onEditTrainingBoard: _openEditTrainingBoard,
          onCreateTrainingBoard: _openCreateTrainingBoard,
        ),
      ),
      _buildTabChild(
        1,
        sportId,
        LogsScreen(
          trainingService: widget.trainingService,
          localeService: widget.localeService,
          optionRepository: widget.optionRepository,
          settingsService: widget.settingsService,
          driveBackupService: widget.driveBackupService,
          onEdit: _openEdit,
          onCreate: _openCreate,
          onQuickPlan: () =>
              _openCalendarQuickCreate(CalendarQuickCreateAction.plan),
          onQuickMatch: () =>
              _openCalendarQuickCreate(CalendarQuickCreateAction.match),
          onQuickQuiz: _openQuiz,
        ),
      ),
      _buildTabChild(
        2,
        sportId,
        CalendarScreen(
          trainingService: widget.trainingService,
          mealLogService: widget.mealLogService,
          localeService: widget.localeService,
          optionRepository: widget.optionRepository,
          settingsService: widget.settingsService,
          driveBackupService: widget.driveBackupService,
          initialSelectedDay: _calendarSelectedDay,
          onEdit: _openEdit,
          onCreate: () => _openCreate(initialDate: _calendarSelectedDay),
          onCreateMeal: () => _openMealLog(initialDate: _calendarSelectedDay),
          quickCreateAction: _pendingCalendarQuickCreateAction ??
              widget.calendarQuickCreateAction,
          onQuickCreateHandled: _clearCalendarQuickCreateAction,
          onSelectedDayChanged: (day) {
            _calendarSelectedDay = DateTime(day.year, day.month, day.day);
          },
        ),
      ),
      _buildTabChild(
        3,
        sportId,
        StatsScreen(
          trainingService: widget.trainingService,
          mealLogService: widget.mealLogService,
          localeService: widget.localeService,
          onCreate: _openCreate,
          optionRepository: widget.optionRepository,
          settingsService: widget.settingsService,
          driveBackupService: widget.driveBackupService,
          initialRange: _statsInitialRange,
          initialRangeRequestKey: _statsInitialRangeRequestKey,
        ),
      ),
      _buildTabChild(
        4,
        sportId,
        CoachLessonScreen(
          optionRepository: widget.optionRepository,
          trainingService: widget.trainingService,
          mealLogService: widget.mealLogService,
          localeService: widget.localeService,
          settingsService: widget.settingsService,
          driveBackupService: widget.driveBackupService,
          embeddedInHomeTab: true,
          openTodayDiaryRequestKey: _openTodayDiaryRequestKey,
          dataRevision: _dataRevision,
        ),
      ),
    ];
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        height: 62,
        backgroundColor: navBackground,
        indicatorColor: Theme.of(context).colorScheme.primary.withAlpha(38),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        selectedIndex: _index,
        onDestinationSelected: _onDestinationSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.tabHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.list_alt_outlined),
            selectedIcon: const Icon(Icons.list_alt),
            label: l10n.tabLogs,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: l10n.tabCalendar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: l10n.tabStats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.auto_stories_outlined),
            selectedIcon: const Icon(Icons.auto_stories),
            label: l10n.tabDiary,
          ),
        ],
      ),
      floatingActionButton: null,
    );
  }

  Widget _buildTabChild(int index, String sportId, Widget child) {
    if (!_builtTabIndices.contains(index)) {
      return const SizedBox.shrink();
    }
    return TickerMode(
      enabled: _index == index,
      child: KeyedSubtree(
        key: ValueKey<String>('home-tab-$index-$sportId'),
        child: child,
      ),
    );
  }

  void _onDestinationSelected(int value) {
    if (_index == value) return;
    setState(() {
      _builtTabIndices.add(value);
      _index = value;
    });
    unawaited(_showTabGuideIfNeeded(value));
  }

  void _openWeeklyStatsForCurrentWeek() {
    setState(() {
      _builtTabIndices.add(3);
      _statsInitialRange = _currentWeekRange();
      _statsInitialRangeRequestKey++;
      _index = 3;
    });
    unawaited(_showTabGuideIfNeeded(3));
  }

  void _openTodayDiary() {
    setState(() {
      _builtTabIndices.add(4);
      _openTodayDiaryRequestKey++;
      _index = 4;
    });
    unawaited(_showTabGuideIfNeeded(4));
  }

  DateTimeRange _currentWeekRange() {
    final today = DateTime.now();
    final start = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: today.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return DateTimeRange(start: start, end: end);
  }

  Future<void> _pushPageSafely(Route<void> route) async {
    if (!mounted || _routePushInFlight) return;
    _routePushInFlight = true;
    try {
      if (SchedulerBinding.instance.schedulerPhase ==
          SchedulerPhase.persistentCallbacks) {
        final completer = Completer<void>();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!completer.isCompleted) {
            completer.complete();
          }
        });
        await completer.future;
      }
      if (!mounted) return;
      await Navigator.of(context).push(route);
    } finally {
      _routePushInFlight = false;
    }
  }

  Future<void> _showTabGuideIfNeeded(int tabIndex) async {
    if (!mounted) return;
    if (_guideCheckedInSession.contains(tabIndex)) return;
    _guideCheckedInSession.add(tabIndex);
    final isParentMode = FamilyAccessService(
      widget.optionRepository,
    ).loadState().isParentMode;
    final key = isParentMode
        ? 'tab_quick_guide_seen_parent_mode_v1'
        : 'tab_quick_guide_seen_v1_$tabIndex';
    final alreadySeen = widget.optionRepository.getValue<bool>(key) ?? false;
    if (alreadySeen) return;
    await widget.optionRepository.setValue(key, true);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final guide = _tabGuideData(tabIndex, l10n, isParentMode: isParentMode);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(guide.title),
        content: _TabGuideDialogContent(guide: guide),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );
  }

  _TabGuideData _tabGuideData(
    int tabIndex,
    AppLocalizations l10n, {
    required bool isParentMode,
  }) {
    if (isParentMode) {
      return _TabGuideData(
        title: l10n.parentWelcomeGuideTitle,
        intro: l10n.parentWelcomeGuideIntro,
        steps: [
          _TabGuideStep(
            icon: Icons.list_alt_outlined,
            actionLabel: l10n.tabLogs,
            description: l10n.parentWelcomeGuideStepLogs,
          ),
          _TabGuideStep(
            icon: Icons.rate_review_outlined,
            actionLabel: l10n.parentFeedbackWriteAction,
            description: l10n.parentWelcomeGuideStepFeedback,
          ),
          _TabGuideStep(
            icon: Icons.cloud_sync_outlined,
            actionLabel: l10n.settingsDriveConnectionTitle,
            description: l10n.parentWelcomeGuideStepSync,
          ),
        ],
      );
    }
    switch (tabIndex) {
      case 0:
        return _TabGuideData(
          title: l10n.tabGuideTitle(l10n.tabHome),
          intro: l10n.welcomeHomeOverview,
          steps: [
            _TabGuideStep(
              icon: Icons.today_outlined,
              actionLabel: l10n.guideActionToday,
              description: l10n.welcomeHomeStepToday,
            ),
            _TabGuideStep(
              icon: Icons.rice_bowl_outlined,
              actionLabel: l10n.guideActionMeal,
              description: l10n.welcomeHomeStepMeal,
            ),
            _TabGuideStep(
              icon: Icons.bar_chart_outlined,
              actionLabel: l10n.homePriorityStatsAction,
              description: l10n.welcomeHomeStepStats,
            ),
          ],
        );
      case 1:
        return _TabGuideData(
          title: l10n.tabGuideTitle(l10n.tabLogs),
          intro: l10n.welcomeLogsOverview,
          steps: [
            _TabGuideStep(
              icon: Icons.add_circle_outline,
              actionLabel: l10n.addEntry,
              description: l10n.welcomeLogsStepAdd,
            ),
            _TabGuideStep(
              icon: Icons.developer_board_outlined,
              actionLabel: l10n.homePriorityBoardAction,
              description: l10n.welcomeLogsStepBoard,
            ),
            _TabGuideStep(
              icon: Icons.view_agenda_outlined,
              actionLabel: l10n.guideActionCardList,
              description: l10n.welcomeLogsStepReview,
            ),
          ],
        );
      case 2:
        return _TabGuideData(
          title: l10n.tabGuideTitle(l10n.tabCalendar),
          intro: l10n.welcomeCalendarOverview,
          steps: [
            _TabGuideStep(
              icon: Icons.touch_app_outlined,
              actionLabel: l10n.guideActionSelectDate,
              description: l10n.welcomeCalendarStepDate,
            ),
            _TabGuideStep(
              icon: Icons.add,
              actionLabel: l10n.guideActionPlus,
              description: l10n.welcomeCalendarStepPlus,
            ),
            _TabGuideStep(
              icon: Icons.rice_bowl_outlined,
              actionLabel: l10n.guideActionMeal,
              description: l10n.welcomeCalendarStepMeal,
            ),
          ],
        );
      case 3:
        return _TabGuideData(
          title: l10n.tabGuideTitle(l10n.tabStats),
          intro: l10n.welcomeStatsOverview,
          steps: [
            _TabGuideStep(
              icon: Icons.date_range_outlined,
              actionLabel: l10n.guideActionPeriod,
              description: l10n.welcomeStatsStepPeriod,
            ),
            _TabGuideStep(
              icon: Icons.stacked_line_chart,
              actionLabel: l10n.guideActionBenchmark,
              description: l10n.welcomeStatsStepAverage,
            ),
            _TabGuideStep(
              icon: Icons.flag_outlined,
              actionLabel: l10n.guideActionWeakPoint,
              description: l10n.welcomeStatsStepFocus,
            ),
          ],
        );
      case 4:
        return _TabGuideData(
          title: l10n.tabGuideTitle(l10n.tabDiary),
          intro: l10n.welcomeDiaryOverview,
          steps: [
            _TabGuideStep(
              icon: Icons.today_outlined,
              actionLabel: l10n.guideActionOpenToday,
              description: l10n.welcomeDiaryStepToday,
            ),
            _TabGuideStep(
              icon: Icons.sticky_note_2_outlined,
              actionLabel: l10n.guideActionRecordSticker,
              description: l10n.welcomeDiaryStepSticker,
            ),
            _TabGuideStep(
              icon: Icons.save_outlined,
              actionLabel: l10n.guideActionSaveDiary,
              description: l10n.welcomeDiaryStepSave,
            ),
          ],
        );
      default:
        return _TabGuideData(
          title: l10n.tabGuideTitle(l10n.tabHome),
          intro: l10n.welcomeHomeOverview,
          steps: const [],
        );
    }
  }

  Future<void> _openCreate({
    DateTime? initialDate,
    bool initialOpenTrainingBoardEditor = false,
    bool closeAfterInitialTrainingBoardEditor = false,
  }) async {
    await _pushPageSafely(
      AppPageRoute(
        builder: (_) => EntryFormScreen(
          trainingService: widget.trainingService,
          optionRepository: widget.optionRepository,
          localeService: widget.localeService,
          settingsService: widget.settingsService,
          driveBackupService: widget.driveBackupService,
          initialDate: initialDate,
          initialOpenTrainingBoardEditor: initialOpenTrainingBoardEditor,
          closeAfterInitialTrainingBoardEditor:
              closeAfterInitialTrainingBoardEditor,
        ),
      ),
    );
  }

  Future<void> _openMealLog({DateTime? initialDate}) async {
    final normalizedDate = initialDate ?? DateTime.now();
    final existingEntry = widget.mealLogService.entryForDay(normalizedDate);
    await _pushPageSafely(
      AppPageRoute(
        builder: (_) => MealLogScreen(
          mealLogService: widget.mealLogService,
          optionRepository: widget.optionRepository,
          settingsService: widget.settingsService,
          initialDate: normalizedDate,
          initialEntry: existingEntry,
        ),
      ),
    );
  }

  void _openCalendarQuickCreate(CalendarQuickCreateAction action) {
    setState(() {
      _builtTabIndices.add(1);
      _pendingCalendarQuickCreateAction = action;
      _index = 1;
    });
    unawaited(_showTabGuideIfNeeded(1));
  }

  Future<void> _openTrainingBoards() async {
    await _pushPageSafely(
      AppPageRoute(
        builder: (_) => TrainingBoardListScreen(
          optionRepository: widget.optionRepository,
          trainingService: widget.trainingService,
        ),
      ),
    );
  }

  void _openPlans() {
    _openPlansForDay(DateTime.now());
  }

  void _openPlansForDay(DateTime day) {
    setState(() {
      _builtTabIndices.add(2);
      _calendarSelectedDay = DateTime(day.year, day.month, day.day);
      _index = 2;
    });
    unawaited(_showTabGuideIfNeeded(2));
  }

  void _clearCalendarQuickCreateAction() {
    if (_pendingCalendarQuickCreateAction == null) return;
    setState(() => _pendingCalendarQuickCreateAction = null);
  }

  Future<void> _openQuiz() async {
    await _pushPageSafely(
      AppPageRoute(
        builder: (_) =>
            SkillQuizScreen(optionRepository: widget.optionRepository),
      ),
    );
  }

  Future<void> _openEdit(
    entry, {
    bool initialOpenTrainingBoardEditor = false,
    bool closeAfterInitialTrainingBoardEditor = false,
  }) async {
    await _pushPageSafely(
      AppPageRoute(
        builder: (_) => EntryFormScreen(
          trainingService: widget.trainingService,
          optionRepository: widget.optionRepository,
          entry: entry,
          localeService: widget.localeService,
          settingsService: widget.settingsService,
          driveBackupService: widget.driveBackupService,
          initialOpenTrainingBoardEditor: initialOpenTrainingBoardEditor,
          closeAfterInitialTrainingBoardEditor:
              closeAfterInitialTrainingBoardEditor,
        ),
      ),
    );
  }

  Future<void> _openEditTrainingBoard(TrainingEntry entry) async {
    await _openEdit(
      entry,
      initialOpenTrainingBoardEditor: true,
      closeAfterInitialTrainingBoardEditor: true,
    );
  }

  Future<void> _openCreateTrainingBoard({DateTime? initialDate}) async {
    await _openCreate(
      initialDate: initialDate,
      initialOpenTrainingBoardEditor: true,
      closeAfterInitialTrainingBoardEditor: true,
    );
  }
}

class _TabGuideData {
  final String title;
  final String intro;
  final List<_TabGuideStep> steps;

  const _TabGuideData({
    required this.title,
    required this.intro,
    required this.steps,
  });
}

class _TabGuideStep {
  final IconData icon;
  final String actionLabel;
  final String description;

  const _TabGuideStep({
    required this.icon,
    required this.actionLabel,
    required this.description,
  });
}

class _TabGuideDialogContent extends StatelessWidget {
  final _TabGuideData guide;

  const _TabGuideDialogContent({required this.guide});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(guide.intro, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 14),
          for (var index = 0; index < guide.steps.length; index += 1) ...[
            _TabGuideStepTile(number: index + 1, step: guide.steps[index]),
            if (index != guide.steps.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _TabGuideStepTile extends StatelessWidget {
  final int number;
  final _TabGuideStep step;

  const _TabGuideStepTile({required this.number, required this.step});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: scheme.primary,
            child: Text(
              '$number',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(step.icon, size: 15, color: scheme.primary),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            step.actionLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  step.description,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
