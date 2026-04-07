import 'dart:async';

import 'package:flutter/material.dart';
import '../../application/training_service.dart';
import '../../application/meal_log_service.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/repositories/option_repository.dart';
import '../../application/locale_service.dart';
import '../../application/settings_service.dart';
import '../../application/backup_service.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'calendar_screen.dart';
import 'logs_screen.dart';
import 'stats_screen.dart';
import 'entry_form_screen.dart';
import 'meal_log_screen.dart';
import '../widgets/app_page_route.dart';
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
    this.calendarQuickCreateAction,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _index;
  DateTime? _calendarSelectedDay;
  DateTimeRange? _statsInitialRange;
  int _statsInitialRangeRequestKey = 0;
  int _openTodayDiaryRequestKey = 0;
  CalendarQuickCreateAction? _pendingCalendarQuickCreateAction;
  final Set<int> _guideCheckedInSession = <int>{};
  bool _routePushInFlight = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showTabGuideIfNeeded(_index));
    });
  }

  @override
  Widget build(BuildContext context) {
    final navBackground = Theme.of(context).colorScheme.surface;
    final pages = <Widget>[
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
        onOpenLogs: () => _onDestinationSelected(1),
        onOpenDiary: _openTodayDiary,
        onOpenWeeklyStats: _openWeeklyStatsForCurrentWeek,
        onEdit: _openEdit,
        onEditTrainingBoard: _openEditTrainingBoard,
        onCreateTrainingBoard: _openCreateTrainingBoard,
      ),
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
        quickCreateAction:
            _pendingCalendarQuickCreateAction ??
            widget.calendarQuickCreateAction,
        onQuickCreateHandled: _clearCalendarQuickCreateAction,
        onSelectedDayChanged: (day) {
          _calendarSelectedDay = DateTime(day.year, day.month, day.day);
        },
      ),
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
      CoachLessonScreen(
        optionRepository: widget.optionRepository,
        trainingService: widget.trainingService,
        mealLogService: widget.mealLogService,
        localeService: widget.localeService,
        settingsService: widget.settingsService,
        driveBackupService: widget.driveBackupService,
        embeddedInHomeTab: true,
        openTodayDiaryRequestKey: _openTodayDiaryRequestKey,
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

  void _onDestinationSelected(int value) {
    if (_index == value) return;
    setState(() => _index = value);
    unawaited(_showTabGuideIfNeeded(value));
  }

  void _openWeeklyStatsForCurrentWeek() {
    setState(() {
      _statsInitialRange = _currentWeekRange();
      _statsInitialRangeRequestKey++;
      _index = 3;
    });
    unawaited(_showTabGuideIfNeeded(3));
  }

  void _openTodayDiary() {
    setState(() {
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
      final completer = Completer<void>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });
      await completer.future;
      if (!mounted) return;
      await Navigator.of(context).push(route);
    } finally {
      _routePushInFlight = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _showTabGuideIfNeeded(int tabIndex) async {
    if (!mounted) return;
    if (_guideCheckedInSession.contains(tabIndex)) return;
    _guideCheckedInSession.add(tabIndex);
    final key = 'tab_quick_guide_seen_v1_$tabIndex';
    final alreadySeen = widget.optionRepository.getValue<bool>(key) ?? false;
    if (alreadySeen) return;
    await widget.optionRepository.setValue(key, true);
    if (!mounted) return;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final (title, body) = _tabGuideCopy(tabIndex, isKo);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(isKo ? '확인' : 'OK'),
          ),
        ],
      ),
    );
  }

  (String, String) _tabGuideCopy(int tabIndex, bool isKo) {
    switch (tabIndex) {
      case 0:
        return (
          isKo ? '홈 가이드' : 'Home Guide',
          isKo
              ? '오늘 해야 할 일, 빠른 실행, 오늘의 훈련 계획과 주간 훈련 현황을 한 번에 확인할 수 있어요.'
              : 'See today’s priorities, quick actions, training plans, and weekly activity in one place.',
        );
      case 1:
        return (
          isKo ? '훈련기록 가이드' : 'Logs Guide',
          isKo
              ? '기록추가에서 훈련 노트를 만들고, 카드/리스트로 과거 기록을 빠르게 확인할 수 있어요.'
              : 'Create training notes from Add, then review past records in card/list views.',
        );
      case 2:
        return (
          isKo ? '캘린더 가이드' : 'Calendar Guide',
          isKo
              ? '날짜를 누르면 해당일 기록과 계획을 함께 볼 수 있어요. + 버튼으로 계획/시합/노트를 추가하세요.'
              : 'Tap a date to view that day’s notes and plans. Use + to add plan/match/note.',
        );
      case 3:
        return (
          isKo ? '통계 가이드' : 'Stats Guide',
          isKo
              ? '기간을 바꿔 성장 추이를 비교하고, 약한 지표를 다음 훈련 목표로 연결해보세요.'
              : 'Change period to compare trends and turn weak metrics into next training goals.',
        );
      case 4:
        return (
          isKo ? '다이어리 가이드' : 'Diary Guide',
          isKo
              ? '훈련, 시합, 계획, 회복 기록을 날짜별로 모아 하루 흐름을 한 번에 돌아볼 수 있어요.'
              : 'Review training, match, plan, and recovery notes together by day in one diary flow.',
        );
      default:
        return ('Guide', 'Quick guide');
    }
  }

  Future<void> _openCreate({
    DateTime? initialDate,
    bool initialOpenTrainingBoardEditor = false,
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
    final today = DateTime.now();
    setState(() {
      _calendarSelectedDay = DateTime(today.year, today.month, today.day);
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
        ),
      ),
    );
  }

  Future<void> _openEditTrainingBoard(TrainingEntry entry) async {
    await _openEdit(entry, initialOpenTrainingBoardEditor: true);
  }

  Future<void> _openCreateTrainingBoard({DateTime? initialDate}) async {
    await _openCreate(
      initialDate: initialDate,
      initialOpenTrainingBoardEditor: true,
    );
  }
}
