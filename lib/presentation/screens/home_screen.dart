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
import '../../application/health_connect_jump_rope_sync_service.dart';
import '../../application/news_badge_service.dart';
import '../../application/notification_app_link.dart';
import '../../application/sport_capabilities.dart';
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
import 'match_hub_screen.dart';
import 'match_record_screen.dart';
import 'training_board_list_screen.dart';
import 'coach_lesson_screen.dart';

enum _HomeCoachAnchor {
  tabHome,
  tabLogs,
  tabCalendar,
  tabStats,
  tabDiary,
  homeDailyFlow,
  homeMeal,
}

class HomeScreen extends StatefulWidget {
  final TrainingService trainingService;
  final MealLogService mealLogService;
  final OptionRepository optionRepository;
  final LocaleService localeService;
  final SettingsService settingsService;
  final BackupService? driveBackupService;
  final HealthConnectJumpRopeSyncService? healthConnectJumpRopeSyncService;
  final int initialIndex;
  final DateTime? initialCalendarSelectedDay;
  final String? initialCalendarPlanId;
  final CalendarQuickCreateAction? calendarQuickCreateAction;

  const HomeScreen({
    super.key,
    required this.trainingService,
    required this.mealLogService,
    required this.optionRepository,
    required this.localeService,
    required this.settingsService,
    this.driveBackupService,
    this.healthConnectJumpRopeSyncService,
    this.initialIndex = 0,
    this.initialCalendarSelectedDay,
    this.initialCalendarPlanId,
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
  int _statsInitialTabIndex = 0;
  int _statsInitialTabRequestKey = 0;
  int _openTodayDiaryRequestKey = 0;
  late final Set<int> _builtTabIndices;
  CalendarQuickCreateAction? _pendingCalendarQuickCreateAction;
  final Set<int> _guideCheckedInSession = <int>{};
  bool _routePushInFlight = false;
  Timer? _familySyncTimer;
  bool _familySyncInFlight = false;
  StreamSubscription<void>? _backupDataChangeSubscription;
  int _dataRevision = 0;
  String? _activeSportId;
  final Map<_HomeCoachAnchor, GlobalKey> _coachAnchorKeys =
      <_HomeCoachAnchor, GlobalKey>{
    for (final anchor in _HomeCoachAnchor.values)
      anchor: GlobalKey(debugLabel: 'home-coach-anchor-${anchor.name}'),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activeSportId = SportService(widget.optionRepository).currentSportId();
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sportId = SportScope.maybeOf(context)?.currentSportId ??
        SportService(widget.optionRepository).currentSportId();
    final previousSportId = _activeSportId;
    if (previousSportId == null || previousSportId == sportId) {
      _activeSportId = sportId;
      return;
    }
    _activeSportId = sportId;
    _resetActivityForSportChange();
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

  GlobalKey _coachAnchorKey(_HomeCoachAnchor anchor) {
    return _coachAnchorKeys[anchor]!;
  }

  Map<HomeHubCoachAnchor, GlobalKey> get _homeHubCoachAnchors {
    return <HomeHubCoachAnchor, GlobalKey>{
      HomeHubCoachAnchor.dailyFlow:
          _coachAnchorKey(_HomeCoachAnchor.homeDailyFlow),
      HomeHubCoachAnchor.meal: _coachAnchorKey(_HomeCoachAnchor.homeMeal),
    };
  }

  _CoachMarkAnchor _coachMarkAnchor(
    _HomeCoachAnchor anchor, {
    Alignment fallbackAlignment = Alignment.center,
    double fallbackTopFactor = 0.34,
    double scrollAlignment = 0.28,
  }) {
    return _CoachMarkAnchor(
      key: _coachAnchorKey(anchor),
      fallbackAlignment: fallbackAlignment,
      fallbackTopFactor: fallbackTopFactor,
      scrollAlignment: scrollAlignment,
    );
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

  void _resetActivityForSportChange() {
    widget.mealLogService.reloadFromStorage();
    NewsBadgeService.clearUnreadCount();
    unawaited(NewsBadgeService.refresh(widget.optionRepository, force: true));
    _index = 0;
    _calendarSelectedDay = null;
    _statsInitialRange = null;
    _statsInitialTabIndex = 0;
    _statsInitialRangeRequestKey++;
    _statsInitialTabRequestKey++;
    _pendingCalendarQuickCreateAction = null;
    _guideCheckedInSession.clear();
    _builtTabIndices
      ..clear()
      ..add(0);
    _dataRevision++;
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
    final supportsTeamManagement =
        SportCapabilities.forSport(sportId).supportsTeamManagement;
    final openTeamManagementHub = supportsTeamManagement ? _openMatchHub : null;
    Future<void> openMatchRecord(DateTime initialDate) => supportsTeamManagement
        ? _openMatchHubRecord(initialDate)
        : _openDirectMatchRecord(initialDate);
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
          healthConnectJumpRopeSyncService:
              widget.healthConnectJumpRopeSyncService,
          onCreate: _openCreate,
          onQuickPlan: () =>
              _openCalendarQuickCreate(CalendarQuickCreateAction.plan),
          onQuickMatch: () => openMatchRecord(DateTime.now()),
          onQuickQuiz: _openQuiz,
          onQuickMeal: () => _openMealLog(initialDate: DateTime.now()),
          onQuickBoard: _openTrainingBoards,
          onOpenMatchHub: openTeamManagementHub,
          onOpenLogs: () => _onDestinationSelected(1),
          onOpenDiary: _openTodayDiary,
          onOpenWeeklyStats: _openWeeklyStatsForCurrentWeek,
          onEdit: _openEdit,
          onEditTrainingBoard: _openEditTrainingBoard,
          onCreateTrainingBoard: _openCreateTrainingBoard,
          coachGuideAnchors: _homeHubCoachAnchors,
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
          onQuickMatch: () => openMatchRecord(DateTime.now()),
          onQuickQuiz: _openQuiz,
          onOpenMatchHub: openTeamManagementHub,
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
          initialPlanId: widget.initialCalendarPlanId,
          onEdit: _openEdit,
          onCreate: () => _openCreate(initialDate: _calendarSelectedDay),
          onCreateMeal: () => _openMealLog(initialDate: _calendarSelectedDay),
          quickCreateAction: _pendingCalendarQuickCreateAction ??
              widget.calendarQuickCreateAction,
          onQuickCreateHandled: _clearCalendarQuickCreateAction,
          onOpenMatchHub: openTeamManagementHub,
          onOpenMatchRecord: openMatchRecord,
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
          initialTabIndex: _statsInitialTabIndex,
          initialTabRequestKey: _statsInitialTabRequestKey,
          onOpenMatchHub: openTeamManagementHub,
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
          onOpenMatchHub: openTeamManagementHub,
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
            key: _coachAnchorKey(_HomeCoachAnchor.tabHome),
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.tabHome,
          ),
          NavigationDestination(
            key: _coachAnchorKey(_HomeCoachAnchor.tabLogs),
            icon: const Icon(Icons.list_alt_outlined),
            selectedIcon: const Icon(Icons.list_alt),
            label: l10n.tabLogs,
          ),
          NavigationDestination(
            key: _coachAnchorKey(_HomeCoachAnchor.tabCalendar),
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: l10n.tabCalendar,
          ),
          NavigationDestination(
            key: _coachAnchorKey(_HomeCoachAnchor.tabStats),
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: l10n.tabStats,
          ),
          NavigationDestination(
            key: _coachAnchorKey(_HomeCoachAnchor.tabDiary),
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
      _statsInitialTabIndex = 0;
      _statsInitialTabRequestKey++;
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
    await _ensureGuideTargetVisible(
      guide.steps.isEmpty ? null : guide.steps.first.targetAnchor,
    );
    if (!mounted) return;
    final action = await showGeneralDialog<VoidCallback>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) =>
          _TabCoachMarkDialog(guide: guide),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: child,
        );
      },
    );
    if (!mounted || action == null) return;
    action();
  }

  Future<void> _ensureGuideTargetVisible(_CoachMarkAnchor? targetAnchor) async {
    final targetContext = targetAnchor?.key.currentContext;
    if (targetContext == null) return;
    await Scrollable.ensureVisible(
      targetContext,
      alignment: targetAnchor?.scrollAlignment ?? 0.28,
      duration: Duration.zero,
      curve: Curves.easeOutCubic,
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
            targetAnchor: _coachMarkAnchor(
              _HomeCoachAnchor.tabLogs,
              fallbackAlignment: Alignment.bottomLeft,
              fallbackTopFactor: 0.86,
            ),
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
              targetAnchor: _coachMarkAnchor(
                _HomeCoachAnchor.homeDailyFlow,
                fallbackAlignment: Alignment.center,
                fallbackTopFactor: 0.32,
              ),
            ),
            _TabGuideStep(
              icon: Icons.rice_bowl_outlined,
              actionLabel: l10n.guideActionMeal,
              description: l10n.welcomeHomeStepMeal,
              onTry: () => unawaited(_openMealLog(initialDate: DateTime.now())),
              targetAnchor: _coachMarkAnchor(
                _HomeCoachAnchor.homeMeal,
                fallbackAlignment: Alignment.center,
                fallbackTopFactor: 0.42,
              ),
            ),
            _TabGuideStep(
              icon: Icons.bar_chart_outlined,
              actionLabel: l10n.homePriorityStatsAction,
              description: l10n.welcomeHomeStepStats,
              onTry: _openWeeklyStatsForCurrentWeek,
              targetAnchor: _coachMarkAnchor(
                _HomeCoachAnchor.tabStats,
                fallbackAlignment: Alignment.bottomCenter,
                fallbackTopFactor: 0.86,
              ),
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
              onTry: () => unawaited(_openCreate()),
              targetAnchor: _coachMarkAnchor(
                _HomeCoachAnchor.tabLogs,
                fallbackAlignment: Alignment.bottomLeft,
                fallbackTopFactor: 0.86,
              ),
            ),
            _TabGuideStep(
              icon: Icons.developer_board_outlined,
              actionLabel: l10n.homePriorityBoardAction,
              description: l10n.welcomeLogsStepBoard,
              onTry: () => unawaited(_openCreateTrainingBoard()),
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
              targetAnchor: _coachMarkAnchor(
                _HomeCoachAnchor.tabCalendar,
                fallbackAlignment: Alignment.bottomCenter,
                fallbackTopFactor: 0.86,
              ),
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
              onTry: () =>
                  unawaited(_openMealLog(initialDate: _calendarSelectedDay)),
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
              targetAnchor: _coachMarkAnchor(
                _HomeCoachAnchor.tabStats,
                fallbackAlignment: Alignment.bottomCenter,
                fallbackTopFactor: 0.86,
              ),
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
              onTry: _openTodayDiary,
              targetAnchor: _coachMarkAnchor(
                _HomeCoachAnchor.tabDiary,
                fallbackAlignment: Alignment.bottomRight,
                fallbackTopFactor: 0.86,
              ),
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
      _builtTabIndices.add(2);
      _pendingCalendarQuickCreateAction = action;
      _index = 2;
    });
    unawaited(_showTabGuideIfNeeded(2));
  }

  Future<void> _openMatchHub() async {
    await _pushPageSafely(
      AppPageRoute(
        builder: (_) => MatchHubScreen(
          trainingService: widget.trainingService,
          localeService: widget.localeService,
          optionRepository: widget.optionRepository,
          settingsService: widget.settingsService,
          driveBackupService: widget.driveBackupService,
          onOpenCalendar: _openMatchHubCalendar,
          onOpenMatchStats: _openMatchHubStats,
        ),
      ),
    );
  }

  Future<void> _openMatchHubRecord(DateTime initialDate) async {
    await _pushPageSafely(
      AppPageRoute(
        builder: (_) => MatchHubScreen(
          trainingService: widget.trainingService,
          localeService: widget.localeService,
          optionRepository: widget.optionRepository,
          settingsService: widget.settingsService,
          driveBackupService: widget.driveBackupService,
          onOpenCalendar: _openMatchHubCalendar,
          onOpenMatchStats: _openMatchHubStats,
          openRecordOnStart: true,
          initialRecordDate: initialDate,
        ),
      ),
    );
  }

  Future<void> _openDirectMatchRecord(DateTime initialDate) async {
    await _pushPageSafely(
      AppPageRoute(
        builder: (_) => MatchRecordScreen(
          trainingService: widget.trainingService,
          localeService: widget.localeService,
          optionRepository: widget.optionRepository,
          settingsService: widget.settingsService,
          initialDate: initialDate,
        ),
      ),
    );
  }

  void _openMatchHubCalendar() {
    setState(() {
      _builtTabIndices.add(2);
      _index = 2;
    });
    unawaited(_showTabGuideIfNeeded(2));
  }

  void _openMatchHubStats() {
    setState(() {
      _builtTabIndices.add(3);
      _statsInitialTabIndex = 1;
      _statsInitialTabRequestKey += 1;
      _index = 3;
    });
    unawaited(_showTabGuideIfNeeded(3));
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

class _CoachMarkAnchor {
  final GlobalKey key;
  final Alignment fallbackAlignment;
  final double fallbackTopFactor;
  final double scrollAlignment;

  const _CoachMarkAnchor({
    required this.key,
    required this.fallbackAlignment,
    required this.fallbackTopFactor,
    required this.scrollAlignment,
  });
}

class _TabGuideStep {
  final IconData icon;
  final String actionLabel;
  final String description;
  final VoidCallback? onTry;
  final _CoachMarkAnchor? targetAnchor;

  const _TabGuideStep({
    required this.icon,
    required this.actionLabel,
    required this.description,
    this.onTry,
    this.targetAnchor,
  });
}

class _TabCoachMarkDialog extends StatefulWidget {
  final _TabGuideData guide;

  const _TabCoachMarkDialog({required this.guide});

  @override
  State<_TabCoachMarkDialog> createState() => _TabCoachMarkDialogState();
}

class _TabCoachMarkDialogState extends State<_TabCoachMarkDialog> {
  static const double _screenPadding = 14;
  static const double _targetInflate = 8;
  static const Size _fallbackTargetSize = Size(220, 76);
  static const double _floatingWidth = 260;
  static const double _floatingHeightEstimate = 78;
  static const double _bottomPanelReserve = 286;
  int _stepIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshCurrentTarget());
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = widget.guide.steps;
    if (steps.isEmpty) {
      return const SizedBox.shrink();
    }
    final step = steps[_stepIndex];
    final isLast = _stepIndex == steps.length - 1;
    return Material(
      key: const ValueKey('tab-coach-mark-dialog'),
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = Size(constraints.maxWidth, constraints.maxHeight);
          final spotlightRect = _spotlightRectForStep(
            step: step,
            stepIndex: _stepIndex,
            totalSteps: steps.length,
            viewport: viewport,
          );
          final floatingOffset = _floatingOffsetFor(
            spotlightRect,
            viewport,
            MediaQuery.paddingOf(context),
          );
          return Stack(
            key: const ValueKey('tab-coach-mark-screen-overlay'),
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: CustomPaint(
                    painter: _CoachMarkScrimPainter(
                      spotlightRect: spotlightRect,
                      color: Colors.black.withValues(
                        alpha:
                            theme.brightness == Brightness.dark ? 0.50 : 0.42,
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: spotlightRect.left,
                top: spotlightRect.top,
                width: spotlightRect.width,
                height: spotlightRect.height,
                child: IgnorePointer(
                  child: DecoratedBox(
                    key: const ValueKey('tab-coach-mark-highlight'),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.42,
                          ),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: floatingOffset.dx,
                top: floatingOffset.dy,
                width: _floatingWidth,
                child: Align(
                  child: _CoachMarkFloatingTarget(
                    key: const ValueKey('tab-coach-mark-floating-target'),
                    step: step,
                    label: AppLocalizations.of(
                      context,
                    )!
                        .welcomeGuideCoachMarkLabel,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  minimum: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  child: _CoachMarkExplanationPanel(
                    guide: widget.guide,
                    step: step,
                    currentStep: _stepIndex + 1,
                    totalSteps: steps.length,
                    isLast: isLast,
                    onSkip: () => Navigator.of(context).pop(),
                    onBack: _stepIndex == 0
                        ? null
                        : () => unawaited(_showStep(_stepIndex - 1)),
                    onTry: step.onTry == null
                        ? null
                        : () => Navigator.of(context).pop(step.onTry),
                    onNext: isLast
                        ? () => Navigator.of(context).pop()
                        : () => unawaited(_showStep(_stepIndex + 1)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _refreshCurrentTarget() async {
    if (widget.guide.steps.isEmpty) return;
    await _ensureTargetVisible(
      widget.guide.steps[_stepIndex].targetAnchor,
      duration: Duration.zero,
    );
    if (mounted) setState(() {});
  }

  Future<void> _showStep(int nextIndex) async {
    final steps = widget.guide.steps;
    if (nextIndex < 0 || nextIndex >= steps.length || nextIndex == _stepIndex) {
      return;
    }
    await _ensureTargetVisible(steps[nextIndex].targetAnchor);
    if (!mounted) return;
    setState(() => _stepIndex = nextIndex);
  }

  Future<void> _ensureTargetVisible(
    _CoachMarkAnchor? targetAnchor, {
    Duration duration = const Duration(milliseconds: 220),
  }) async {
    final targetContext = targetAnchor?.key.currentContext;
    if (targetContext == null) return;
    await Scrollable.ensureVisible(
      targetContext,
      alignment: targetAnchor?.scrollAlignment ?? 0.28,
      duration: duration,
      curve: Curves.easeOutCubic,
    );
  }

  Rect _spotlightRectForStep({
    required _TabGuideStep step,
    required int stepIndex,
    required int totalSteps,
    required Size viewport,
  }) {
    final targetRect = _targetRectForStep(step);
    final rect = (targetRect ??
            _fallbackRectForStep(
              step: step,
              stepIndex: stepIndex,
              totalSteps: totalSteps,
              viewport: viewport,
            ))
        .inflate(_targetInflate);
    return _clampRect(rect, viewport, margin: 0);
  }

  Rect? _targetRectForStep(_TabGuideStep step) {
    final targetContext = step.targetAnchor?.key.currentContext;
    if (targetContext == null) return null;
    final renderObject = targetContext.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return null;
    }
    final topLeft = renderObject.localToGlobal(Offset.zero);
    return topLeft & renderObject.size;
  }

  Rect _fallbackRectForStep({
    required _TabGuideStep step,
    required int stepIndex,
    required int totalSteps,
    required Size viewport,
  }) {
    final anchor = step.targetAnchor;
    final top = anchor == null
        ? _spotlightTopForStep(
            stepIndex: stepIndex,
            totalSteps: totalSteps,
            maxHeight: viewport.height,
          )
        : ((viewport.height * anchor.fallbackTopFactor) -
            (_fallbackTargetSize.height / 2));
    final availableWidth =
        (viewport.width - (_screenPadding * 2) - _fallbackTargetSize.width)
            .clamp(0.0, double.infinity)
            .toDouble();
    final horizontalProgress = anchor == null
        ? switch (stepIndex % 3) {
            0 => 0.0,
            1 => 0.5,
            _ => 1.0,
          }
        : ((anchor.fallbackAlignment.x + 1) / 2).clamp(0.0, 1.0).toDouble();
    final left = _screenPadding + (availableWidth * horizontalProgress);
    return Rect.fromLTWH(
      left,
      top,
      _fallbackTargetSize.width,
      _fallbackTargetSize.height,
    );
  }

  Rect _clampRect(
    Rect rect,
    Size viewport, {
    double margin = _screenPadding,
  }) {
    final maxWidth =
        (viewport.width - (margin * 2)).clamp(0.0, double.infinity).toDouble();
    final maxHeight =
        (viewport.height - (margin * 2)).clamp(0.0, double.infinity).toDouble();
    final width = rect.width.clamp(0.0, maxWidth).toDouble();
    final height = rect.height.clamp(0.0, maxHeight).toDouble();
    final left = _clampDouble(
      rect.center.dx - (width / 2),
      margin,
      viewport.width - margin - width,
    );
    final top = _clampDouble(
      rect.center.dy - (height / 2),
      margin,
      viewport.height - margin - height,
    );
    return Rect.fromLTWH(left, top, width, height);
  }

  Offset _floatingOffsetFor(
    Rect spotlightRect,
    Size viewport,
    EdgeInsets safePadding,
  ) {
    final left = _clampDouble(
      spotlightRect.center.dx - (_floatingWidth / 2),
      _screenPadding,
      viewport.width - _screenPadding - _floatingWidth,
    );
    final safeTop = safePadding.top + _screenPadding;
    final safeBottom = viewport.height - safePadding.bottom - _screenPadding;
    final bottomPanelTop = safeBottom - _bottomPanelReserve;
    final belowTop = spotlightRect.bottom + 12;
    final aboveTop = spotlightRect.top - _floatingHeightEstimate - 12;
    final top = belowTop + _floatingHeightEstimate <= bottomPanelTop
        ? belowTop
        : aboveTop >= safeTop
            ? aboveTop
            : _clampDouble(
                belowTop,
                safeTop,
                safeBottom - _floatingHeightEstimate,
              );
    return Offset(left, top);
  }

  double _clampDouble(double value, double min, double max) {
    if (max < min) return min;
    return value.clamp(min, max).toDouble();
  }

  double _spotlightTopForStep({
    required int stepIndex,
    required int totalSteps,
    required double maxHeight,
  }) {
    final safeMax = maxHeight <= 0 ? 640.0 : maxHeight;
    const upper = 72.0;
    final lower = (safeMax - 318).clamp(upper, safeMax).toDouble();
    if (totalSteps <= 1) return safeMax * 0.24;
    final progress = stepIndex / (totalSteps - 1);
    return upper + ((lower - upper) * progress);
  }
}

class _CoachMarkScrimPainter extends CustomPainter {
  final Rect spotlightRect;
  final Color color;

  const _CoachMarkScrimPainter({
    required this.spotlightRect,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final screenPath = Path()..addRect(Offset.zero & size);
    final spotlightPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          spotlightRect,
          const Radius.circular(20),
        ),
      );
    final scrimPath = Path.combine(
      PathOperation.difference,
      screenPath,
      spotlightPath,
    );
    canvas.drawPath(scrimPath, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _CoachMarkScrimPainter oldDelegate) {
    return oldDelegate.spotlightRect != spotlightRect ||
        oldDelegate.color != color;
  }
}

class _CoachMarkFloatingTarget extends StatelessWidget {
  final _TabGuideStep step;
  final String label;

  const _CoachMarkFloatingTarget({
    super.key,
    required this.step,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.34),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(step.icon, color: scheme.onPrimary),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.actionLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachMarkExplanationPanel extends StatelessWidget {
  final _TabGuideData guide;
  final _TabGuideStep step;
  final int currentStep;
  final int totalSteps;
  final bool isLast;
  final VoidCallback onSkip;
  final VoidCallback? onBack;
  final VoidCallback? onTry;
  final VoidCallback onNext;

  const _CoachMarkExplanationPanel({
    required this.guide,
    required this.step,
    required this.currentStep,
    required this.totalSteps,
    required this.isLast,
    required this.onSkip,
    required this.onBack,
    required this.onTry,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(step.icon, color: scheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          guide.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          l10n.tabGuideCoachMarkStep(
                            currentStep,
                            totalSteps,
                          ),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                guide.intro,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                step.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.38,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (var index = 0; index < totalSteps; index += 1) ...[
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 4,
                        decoration: BoxDecoration(
                          color: index < currentStep
                              ? scheme.primary
                              : scheme.outlineVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    if (index != totalSteps - 1) const SizedBox(width: 6),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    key: const ValueKey('tab-coach-mark-skip-button'),
                    onPressed: onSkip,
                    child: Text(l10n.tabGuideCoachMarkSkip),
                  ),
                  if (onBack != null)
                    TextButton(
                      key: const ValueKey('tab-coach-mark-back-button'),
                      onPressed: onBack,
                      child: Text(l10n.tabGuideCoachMarkBack),
                    ),
                  if (onTry != null)
                    FilledButton.tonalIcon(
                      key: const ValueKey('tab-coach-mark-try-button'),
                      onPressed: onTry,
                      icon: const Icon(Icons.touch_app_rounded),
                      label: Text(l10n.tabGuideCoachMarkTry),
                    ),
                  FilledButton.icon(
                    key: const ValueKey('tab-coach-mark-next-button'),
                    onPressed: onNext,
                    icon: Icon(
                      isLast
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(
                      isLast
                          ? l10n.tabGuideCoachMarkDone
                          : l10n.tabGuideCoachMarkNext,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
