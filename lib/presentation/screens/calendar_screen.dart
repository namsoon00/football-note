import 'dart:async';
import 'dart:convert';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../application/backup_service.dart';
import '../../application/family_access_service.dart';
import '../../application/meal_log_service.dart';
import '../../application/localized_option_defaults.dart';
import '../../application/locale_service.dart';
import '../../application/match_competition_service.dart';
import '../../application/news_badge_service.dart';
import '../../application/player_level_service.dart';
import '../../application/player_profile_service.dart';
import '../../application/parent_shared_feedback_service.dart';
import '../../application/settings_service.dart';
import '../../application/sport_capabilities.dart';
import '../../application/sport_defaults.dart';
import '../../application/sport_service.dart';
import '../../application/training_plan_reminder_service.dart';
import '../../application/training_plan_badge_service.dart';
import '../../application/training_plan_series_builder.dart';
import '../../application/training_service.dart';
import '../../domain/entities/meal_entry.dart';
import '../../domain/entities/sport_definition.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/repositories/option_repository.dart';
import '../meal_food_labels.dart';
import '../widgets/app_background.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_page_route.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_tab_header.dart';
import '../widgets/status_style.dart';
import '../widgets/watch_cart/watch_cart_card.dart';
import '../utils/match_entry_format.dart';
import '../utils/training_entry_summary.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'news_screen.dart';
import 'skill_quiz_screen.dart';
import 'notification_center_screen.dart';
import 'meal_log_screen.dart';

enum _CalendarCreateAction { entry, meal, plan, match }

enum CalendarQuickCreateAction { plan, match }

enum _PlanEditScope { single, afterThis, series }

class CalendarScreen extends StatefulWidget {
  final TrainingService trainingService;
  final MealLogService mealLogService;
  final LocaleService localeService;
  final OptionRepository optionRepository;
  final SettingsService settingsService;
  final BackupService? driveBackupService;
  final DateTime? initialSelectedDay;
  final String? initialPlanId;
  final ValueChanged<TrainingEntry> onEdit;
  final VoidCallback? onCreate;
  final VoidCallback? onCreateMeal;
  final ValueChanged<DateTime>? onSelectedDayChanged;
  final CalendarQuickCreateAction? quickCreateAction;
  final VoidCallback? onQuickCreateHandled;
  final VoidCallback? onOpenMatchHub;
  final ValueChanged<DateTime>? onOpenMatchRecord;

  const CalendarScreen({
    super.key,
    required this.trainingService,
    required this.mealLogService,
    required this.localeService,
    required this.optionRepository,
    required this.settingsService,
    this.driveBackupService,
    this.initialSelectedDay,
    this.initialPlanId,
    required this.onEdit,
    this.onCreate,
    this.onCreateMeal,
    this.onSelectedDayChanged,
    this.quickCreateAction,
    this.onQuickCreateHandled,
    this.onOpenMatchHub,
    this.onOpenMatchRecord,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const _calendarExpandedKey = 'calendar_expanded_v1';
  static const _calendarFormatKey = 'calendar_format_v1';
  static const _lastPlanReminderKey =
      'training_plan_last_reminder_minutes_before_v1';
  static const _lastPlanTemplateKey = 'last_training_plan_template_v1';
  static const double _calendarDayNumberFontSize = 17;
  static const int _sheetContextEntryLimit = 300;
  static const int _twoWeekRangePaddingDays = 21;
  static const Map<String, String> _krFixedHolidayLabels = <String, String>{
    '01-01': '신정',
    '03-01': '삼일절',
    '05-05': '어린이날',
    '06-06': '현충일',
    '08-15': '광복절',
    '10-03': '개천절',
    '10-09': '한글날',
    '12-25': '성탄절',
  };

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _calendarExpanded = true;

  late final TrainingPlanReminderService _reminderService;
  late final TrainingPlanBadgeService _badgeService;
  late final Stream<List<MealEntry>> _mealEntriesStream;
  StreamSubscription<List<TrainingEntry>>? _trainingEntriesSubscription;
  List<TrainingEntry> _visibleTrainingEntries = const <TrainingEntry>[];
  DateTimeRange? _loadedTrainingRange;
  List<_TrainingPlan> _plans = const <_TrainingPlan>[];
  String _plansStorageRaw = '';
  bool _quickCreateHandled = false;
  bool _initialPlanLinkHandled = false;
  bool _overlayOpenInFlight = false;
  double _calendarVerticalDragDistance = 0;

  String get _plansStorageKey =>
      TrainingPlanReminderService.plansStorageKeyFor(widget.optionRepository);
  String get _lastPlanReminderStorageKey => SportCatalog.optionKey(
        _lastPlanReminderKey,
        sportId: SportService(widget.optionRepository).currentSportId(),
      );
  String get _lastPlanTemplateStorageKey => SportCatalog.optionKey(
        _lastPlanTemplateKey,
        sportId: SportService(widget.optionRepository).currentSportId(),
      );

  @override
  void initState() {
    super.initState();
    _reminderService = TrainingPlanReminderService(
      widget.optionRepository,
      widget.settingsService,
    );
    _badgeService = TrainingPlanBadgeService(widget.optionRepository);
    _mealEntriesStream = widget.mealLogService.watchEntries();
    _reloadPlansFromStorage();
    _calendarExpanded =
        widget.optionRepository.getValue<bool>(_calendarExpandedKey) ?? true;
    _calendarFormat = _loadCalendarFormat();
    final initialSelectedDay = widget.initialSelectedDay;
    if (initialSelectedDay != null) {
      final normalizedDay = _normalizeDay(initialSelectedDay);
      _selectedDay = normalizedDay;
      _focusedDay = normalizedDay;
    }
    _watchFocusedTrainingRange();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSelectedDayChanged?.call(
        _normalizeDay(_selectedDay ?? _focusedDay),
      );
      unawaited(_maybeOpenInitialPlanLink());
      unawaited(_maybeRunQuickCreateAction());
    });
  }

  @override
  void dispose() {
    unawaited(_trainingEntriesSubscription?.cancel());
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameNormalizedDay(
      widget.initialSelectedDay,
      oldWidget.initialSelectedDay,
    )) {
      final nextSelectedDay = widget.initialSelectedDay;
      if (nextSelectedDay != null) {
        final normalizedDay = _normalizeDay(nextSelectedDay);
        setState(() {
          _selectedDay = normalizedDay;
          _focusedDay = normalizedDay;
        });
        _watchFocusedTrainingRange();
        widget.onSelectedDayChanged?.call(normalizedDay);
      }
    }
    if (widget.trainingService != oldWidget.trainingService) {
      _loadedTrainingRange = null;
      _watchFocusedTrainingRange();
    }
    if (widget.quickCreateAction != oldWidget.quickCreateAction) {
      _quickCreateHandled = false;
    }
    if (widget.quickCreateAction == null) return;
    if (widget.quickCreateAction == oldWidget.quickCreateAction) return;
    unawaited(_maybeRunQuickCreateAction());
  }

  Future<void> _maybeOpenInitialPlanLink() async {
    if (_initialPlanLinkHandled) return;
    final planId = widget.initialPlanId?.trim();
    if (planId == null || planId.isEmpty) return;
    _initialPlanLinkHandled = true;
    final plan = _planForId(planId);
    if (plan == null || !mounted) return;
    final normalizedDay = _normalizeDay(plan.scheduledAt);
    setState(() {
      _selectedDay = normalizedDay;
      _focusedDay = normalizedDay;
    });
    widget.onSelectedDayChanged?.call(normalizedDay);
    await _openPlanSheet(day: plan.scheduledAt, editingPlan: plan);
  }

  _TrainingPlan? _planForId(String planId) {
    for (final plan in _plans) {
      if (plan.id == planId) return plan;
    }
    return null;
  }

  Future<void> _maybeRunQuickCreateAction() async {
    if (_quickCreateHandled) return;
    final action = widget.quickCreateAction;
    if (action == null) return;
    _quickCreateHandled = true;
    final selectedDay = _selectedDay ?? _focusedDay;
    switch (action) {
      case CalendarQuickCreateAction.plan:
        await _openPlanSheet(day: selectedDay);
        break;
      case CalendarQuickCreateAction.match:
        if (widget.onOpenMatchRecord != null) {
          widget.onOpenMatchRecord!(selectedDay);
        } else {
          final entries = await _contextEntries();
          if (!mounted) return;
          await _openMatchSheet(day: selectedDay, entries: entries);
        }
        break;
    }
    widget.onQuickCreateHandled?.call();
  }

  Future<List<TrainingEntry>> _contextEntries() {
    return widget.trainingService.recentEntries(
      limit: _sheetContextEntryLimit,
      sportId: SportService(widget.optionRepository).currentSportId(),
    );
  }

  void _watchFocusedTrainingRange() {
    final range = _trainingLoadRangeFor(_focusedDay);
    if (_sameDateTimeRange(_loadedTrainingRange, range)) return;
    _loadedTrainingRange = range;
    unawaited(_trainingEntriesSubscription?.cancel());
    _trainingEntriesSubscription = widget.trainingService
        .watchEntriesInRange(range.start, range.end)
        .listen((entries) {
      if (!mounted || !_sameDateTimeRange(_loadedTrainingRange, range)) {
        return;
      }
      final sportId = SportService(widget.optionRepository).currentSportId();
      setState(
        () => _visibleTrainingEntries = filterEntriesForSport(entries, sportId),
      );
    });
  }

  DateTimeRange _trainingLoadRangeFor(DateTime focusedDay) {
    final focused = _normalizeDay(focusedDay);
    if (_calendarFormat == CalendarFormat.twoWeeks) {
      return DateTimeRange(
        start: focused.subtract(const Duration(days: _twoWeekRangePaddingDays)),
        end: focused.add(const Duration(days: _twoWeekRangePaddingDays + 1)),
      );
    }
    final monthStart = DateTime(focused.year, focused.month);
    final nextMonthStart = DateTime(focused.year, focused.month + 1);
    return DateTimeRange(
      start: DateTime(monthStart.year, monthStart.month - 1),
      end: DateTime(nextMonthStart.year, nextMonthStart.month + 1),
    );
  }

  bool _sameDateTimeRange(DateTimeRange? a, DateTimeRange b) {
    return a != null && a.start == b.start && a.end == b.end;
  }

  Future<void> _setCalendarExpanded(
    bool expanded, {
    bool persist = true,
  }) async {
    if (_calendarExpanded == expanded) return;
    setState(() => _calendarExpanded = expanded);
    if (!persist) return;
    await widget.optionRepository.setValue(_calendarExpandedKey, expanded);
  }

  Future<void> _setCalendarFormat(CalendarFormat format) async {
    if (_calendarFormat == format) return;
    setState(() {
      _calendarFormat = format;
      _focusedDay = _selectedDay ?? _focusedDay;
    });
    _watchFocusedTrainingRange();
    await widget.optionRepository.setValue(
      _calendarFormatKey,
      _serializeCalendarFormat(format),
    );
  }

  CalendarFormat _loadCalendarFormat() {
    final raw =
        widget.optionRepository.getValue<String>(_calendarFormatKey) ?? '';
    switch (raw) {
      case 'twoWeeks':
        return CalendarFormat.twoWeeks;
      case 'month':
      default:
        return CalendarFormat.month;
    }
  }

  String _serializeCalendarFormat(CalendarFormat format) {
    switch (format) {
      case CalendarFormat.twoWeeks:
        return 'twoWeeks';
      case CalendarFormat.month:
      default:
        return 'month';
    }
  }

  Future<T?> _showModalBottomSheetSafely<T>({
    required WidgetBuilder builder,
    bool showDragHandle = false,
  }) async {
    if (!mounted || _overlayOpenInFlight) return null;
    _overlayOpenInFlight = true;
    try {
      final completer = Completer<void>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });
      await completer.future;
      if (!mounted) return null;
      return showModalBottomSheet<T>(
        context: context,
        showDragHandle: showDragHandle,
        builder: builder,
      );
    } finally {
      _overlayOpenInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isParentMode = FamilyAccessService(
      widget.optionRepository,
    ).loadState().isParentMode;
    _refreshPlansFromStorageIfChanged();
    return Scaffold(
      drawer: AppDrawer(
        trainingService: widget.trainingService,
        optionRepository: widget.optionRepository,
        localeService: widget.localeService,
        settingsService: widget.settingsService,
        driveBackupService: widget.driveBackupService,
        currentIndex: 2,
      ),
      body: AppBackground(
        child: SafeArea(
          child: Builder(
            builder: (context) {
              final isKo = Localizations.localeOf(context).languageCode == 'ko';
              final entries = _visibleTrainingEntries;
              return StreamBuilder<List<MealEntry>>(
                stream: _mealEntriesStream,
                builder: (context, mealSnapshot) {
                  final mealEntries = widget.mealLogService.mergedEntries(
                    directEntries: mealSnapshot.data ?? const <MealEntry>[],
                    legacyEntries: entries,
                  );
                  final mealEntryMap = _groupMealEntriesByDay(mealEntries);
                  final entryMap = _groupByDay(entries);
                  final parentFeedbackByEntryId = ParentSharedFeedbackService(
                    widget.optionRepository,
                  ).loadAll();
                  final planMap = _groupPlansByDay(_plans);
                  final holidayMap = isKo
                      ? _buildKoreanHolidayMap(DateTime(2022), DateTime(2032))
                      : const <DateTime, String>{};
                  final selected = _normalizeDay(_selectedDay ?? _focusedDay);
                  final dayEntries =
                      entryMap[selected] ?? const <TrainingEntry>[];
                  final dayMealEntry = mealEntryMap[selected];
                  final dayPlans = planMap[selected] ?? const <_TrainingPlan>[];
                  final hasDaySchedule = dayEntries.isNotEmpty ||
                      dayPlans.isNotEmpty ||
                      dayMealEntry != null;
                  final isCalendarExpanded =
                      hasDaySchedule ? _calendarExpanded : true;
                  final selectedHolidayName = holidayMap[selected];
                  final reminderUnreadCount = TrainingPlanReminderService(
                    widget.optionRepository,
                    widget.settingsService,
                  ).unreadReminderCountSync();

                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onVerticalDragStart: (_) {
                      _calendarVerticalDragDistance = 0;
                    },
                    onVerticalDragUpdate: (details) {
                      _handleCalendarSurfaceDrag(
                        details,
                        hasDaySchedule: hasDaySchedule,
                        isCalendarExpanded: isCalendarExpanded,
                      );
                    },
                    child: Column(
                      children: [
                        ValueListenableBuilder<int>(
                          valueListenable: NewsBadgeService.listenable(
                            widget.optionRepository,
                          ),
                          builder: (context, newsCount, _) => Builder(
                            builder: (context) => SharedTabHeader(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              onLeadingTap: () =>
                                  Scaffold.of(context).openDrawer(),
                              onNewsTap: () => _openNews(context),
                              newsBadgeCount: newsCount,
                              onQuizTap: () => _openQuiz(context),
                              onMatchTap: widget.onOpenMatchHub,
                              onNotificationTap: () =>
                                  _openNotifications(context),
                              notificationBadgeCount: reminderUnreadCount,
                              profilePhotoSource:
                                  PlayerProfileService(widget.optionRepository)
                                      .load()
                                      .photoUrl,
                              onProfileTap: () => _openProfile(context),
                              onSettingsTap: () => _openSettings(context),
                              title: AppLocalizations.of(context)!.calendar,
                              titleTrailing: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                alignment: WrapAlignment.end,
                                children: [
                                  _CalendarHeaderChipButton(
                                    label: isKo ? '2주' : '2W',
                                    selected: _calendarFormat ==
                                        CalendarFormat.twoWeeks,
                                    onPressed: () => _setCalendarFormat(
                                      CalendarFormat.twoWeeks,
                                    ),
                                  ),
                                  _CalendarHeaderChipButton(
                                    label: isKo ? '1개월' : '1M',
                                    selected:
                                        _calendarFormat == CalendarFormat.month,
                                    onPressed: () => _setCalendarFormat(
                                      CalendarFormat.month,
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      minimumSize: const Size(72, 40),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                    ),
                                    onPressed: () {
                                      final today = _normalizeDay(
                                        DateTime.now(),
                                      );
                                      setState(() {
                                        _selectedDay = today;
                                        _focusedDay = today;
                                      });
                                      _watchFocusedTrainingRange();
                                      widget.onSelectedDayChanged?.call(today);
                                    },
                                    icon: const Icon(
                                      Icons.today_outlined,
                                      size: 18,
                                    ),
                                    label: Text(
                                      Localizations.localeOf(
                                                context,
                                              ).languageCode ==
                                              'ko'
                                          ? '오늘'
                                          : 'Today',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          child: isCalendarExpanded
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: WatchCartCard(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        8,
                                        2,
                                        8,
                                        10,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TableCalendar<TrainingEntry>(
                                            key: ValueKey(
                                              'calendar-${_calendarFormat.name}',
                                            ),
                                            locale: Localizations.localeOf(
                                              context,
                                            ).toString(),
                                            focusedDay: _focusedDay,
                                            firstDay: DateTime(2022),
                                            lastDay: DateTime(2032),
                                            sixWeekMonthsEnforced: false,
                                            availableCalendarFormats: const {
                                              CalendarFormat.twoWeeks: '2W',
                                              CalendarFormat.month: '1M',
                                            },
                                            rowHeight: 44,
                                            daysOfWeekHeight: 20,
                                            startingDayOfWeek:
                                                StartingDayOfWeek.sunday,
                                            calendarFormat: _calendarFormat,
                                            onPageChanged: (focusedDay) {
                                              setState(() {
                                                _focusedDay = focusedDay;
                                              });
                                              _watchFocusedTrainingRange();
                                            },
                                            selectedDayPredicate: (day) =>
                                                isSameDay(day, _selectedDay),
                                            onDaySelected:
                                                (selectedDay, focusedDay) {
                                              setState(() {
                                                _selectedDay = selectedDay;
                                                _focusedDay = focusedDay;
                                              });
                                              _watchFocusedTrainingRange();
                                              widget.onSelectedDayChanged?.call(
                                                _normalizeDay(
                                                  selectedDay,
                                                ),
                                              );
                                            },
                                            holidayPredicate: (day) =>
                                                isKo &&
                                                holidayMap.containsKey(
                                                  _normalizeDay(day),
                                                ),
                                            calendarBuilders: CalendarBuilders(
                                              defaultBuilder:
                                                  (context, day, focusedDay) {
                                                final key = _normalizeDay(
                                                  day,
                                                );
                                                final dayEntries =
                                                    entryMap[key] ??
                                                        const <TrainingEntry>[];
                                                return _CalendarStatusDayCell(
                                                  dayNumber: day.day,
                                                  hasTraining:
                                                      _hasTrainingForDay(
                                                    dayEntries,
                                                  ),
                                                  hasMeal:
                                                      mealEntryMap[key] != null,
                                                  hasMatch: _hasMatchForDay(
                                                    dayEntries,
                                                  ),
                                                  hasPlan: (planMap[key] ??
                                                          const <_TrainingPlan>[])
                                                      .isNotEmpty,
                                                  isSelected: isSameDay(
                                                    day,
                                                    _selectedDay,
                                                  ),
                                                  isToday: isSameDay(
                                                    day,
                                                    DateTime.now(),
                                                  ),
                                                  isHoliday: isKo &&
                                                      holidayMap
                                                          .containsKey(key),
                                                );
                                              },
                                              todayBuilder:
                                                  (context, day, focusedDay) {
                                                final key = _normalizeDay(
                                                  day,
                                                );
                                                final dayEntries =
                                                    entryMap[key] ??
                                                        const <TrainingEntry>[];
                                                return _CalendarStatusDayCell(
                                                  dayNumber: day.day,
                                                  hasTraining:
                                                      _hasTrainingForDay(
                                                    dayEntries,
                                                  ),
                                                  hasMeal:
                                                      mealEntryMap[key] != null,
                                                  hasMatch: _hasMatchForDay(
                                                    dayEntries,
                                                  ),
                                                  hasPlan: (planMap[key] ??
                                                          const <_TrainingPlan>[])
                                                      .isNotEmpty,
                                                  isSelected: isSameDay(
                                                    day,
                                                    _selectedDay,
                                                  ),
                                                  isToday: true,
                                                  isHoliday: isKo &&
                                                      holidayMap
                                                          .containsKey(key),
                                                );
                                              },
                                              selectedBuilder:
                                                  (context, day, focusedDay) {
                                                final key = _normalizeDay(
                                                  day,
                                                );
                                                final dayEntries =
                                                    entryMap[key] ??
                                                        const <TrainingEntry>[];
                                                return _CalendarStatusDayCell(
                                                  dayNumber: day.day,
                                                  hasTraining:
                                                      _hasTrainingForDay(
                                                    dayEntries,
                                                  ),
                                                  hasMeal:
                                                      mealEntryMap[key] != null,
                                                  hasMatch: _hasMatchForDay(
                                                    dayEntries,
                                                  ),
                                                  hasPlan: (planMap[key] ??
                                                          const <_TrainingPlan>[])
                                                      .isNotEmpty,
                                                  isSelected: true,
                                                  isToday: isSameDay(
                                                    day,
                                                    DateTime.now(),
                                                  ),
                                                  isHoliday: isKo &&
                                                      holidayMap
                                                          .containsKey(key),
                                                );
                                              },
                                              holidayBuilder:
                                                  (context, day, focusedDay) {
                                                final key = _normalizeDay(
                                                  day,
                                                );
                                                final dayEntries =
                                                    entryMap[key] ??
                                                        const <TrainingEntry>[];
                                                return _CalendarStatusDayCell(
                                                  dayNumber: day.day,
                                                  hasTraining:
                                                      _hasTrainingForDay(
                                                    dayEntries,
                                                  ),
                                                  hasMeal:
                                                      mealEntryMap[key] != null,
                                                  hasMatch: _hasMatchForDay(
                                                    dayEntries,
                                                  ),
                                                  hasPlan: (planMap[key] ??
                                                          const <_TrainingPlan>[])
                                                      .isNotEmpty,
                                                  isSelected: isSameDay(
                                                    day,
                                                    _selectedDay,
                                                  ),
                                                  isToday: isSameDay(
                                                    day,
                                                    DateTime.now(),
                                                  ),
                                                  isHoliday: true,
                                                );
                                              },
                                            ),
                                            calendarStyle: CalendarStyle(
                                              outsideDaysVisible: false,
                                              defaultTextStyle: TextStyle(
                                                fontSize:
                                                    _calendarDayNumberFontSize,
                                                fontWeight: FontWeight.w700,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                              ),
                                              weekendTextStyle: TextStyle(
                                                fontSize:
                                                    _calendarDayNumberFontSize,
                                                fontWeight: FontWeight.w700,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                              ),
                                              outsideTextStyle: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.35),
                                              ),
                                              todayTextStyle: TextStyle(
                                                fontSize:
                                                    _calendarDayNumberFontSize,
                                                fontWeight: FontWeight.w800,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onPrimary,
                                              ),
                                              selectedTextStyle: TextStyle(
                                                fontSize:
                                                    _calendarDayNumberFontSize,
                                                fontWeight: FontWeight.w800,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onPrimary,
                                              ),
                                              holidayTextStyle: TextStyle(
                                                fontSize:
                                                    _calendarDayNumberFontSize,
                                                color: Colors.red.shade500,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            headerStyle: const HeaderStyle(
                                              formatButtonVisible: false,
                                              titleCentered: true,
                                              titleTextStyle: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              headerPadding:
                                                  EdgeInsets.fromLTRB(
                                                0,
                                                0,
                                                0,
                                                6,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 6, bottom: 2),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: hasDaySchedule
                                  ? () => _setCalendarExpanded(
                                        !isCalendarExpanded,
                                      )
                                  : null,
                              borderRadius: BorderRadius.circular(999),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isCalendarExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      Localizations.localeOf(
                                                context,
                                              ).languageCode ==
                                              'ko'
                                          ? (isCalendarExpanded
                                              ? '캘린더 접기'
                                              : '캘린더 펼치기')
                                          : (isCalendarExpanded
                                              ? 'Collapse calendar'
                                              : 'Expand calendar'),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: _DayTimeline(
                            holidayName: selectedHolidayName,
                            dayPlans: dayPlans,
                            dayEntries: dayEntries,
                            parentFeedbackByEntryId: parentFeedbackByEntryId,
                            dayMealEntry: dayMealEntry,
                            isReadOnly: isParentMode,
                            onEditEntry: (entry) {
                              if (entry.isMatch) {
                                unawaited(
                                  _openMatchSheet(
                                    day: entry.date,
                                    editingEntry: entry,
                                    entries: entries,
                                  ),
                                );
                                return;
                              }
                              widget.onEdit(entry);
                            },
                            onEditPlan: (plan) {
                              _openPlanSheet(
                                day: plan.scheduledAt,
                                editingPlan: plan,
                              );
                            },
                            onEditMealEntry: (entry) => unawaited(
                              _openMealLog(day: entry.date, entry: entry),
                            ),
                            onMovePlan: _movePlanSchedule,
                            onDeleteEntry: _confirmDeleteEntry,
                            onDeleteMealEntry: _confirmDeleteMealEntry,
                            onDeletePlan: _confirmDeletePlan,
                            onListScrollUp: () {
                              if (hasDaySchedule && isCalendarExpanded) {
                                _setCalendarExpanded(false, persist: false);
                              }
                            },
                            onListReachedBottom: () {
                              if (hasDaySchedule && !isCalendarExpanded) {
                                _setCalendarExpanded(true, persist: false);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: widget.onCreate == null || isParentMode
          ? null
          : FloatingActionButton(
              heroTag: 'calendar_fab',
              onPressed: () async {
                final entries = await _contextEntries();
                if (!mounted) return;
                await _showCreateActionSheet(entries);
              },
              child: const Icon(Icons.add),
            ),
    );
  }

  void _handleCalendarSurfaceDrag(
    DragUpdateDetails details, {
    required bool hasDaySchedule,
    required bool isCalendarExpanded,
  }) {
    if (!hasDaySchedule) return;
    _calendarVerticalDragDistance += details.primaryDelta ?? 0;
    if (_calendarVerticalDragDistance <= -18 && isCalendarExpanded) {
      _calendarVerticalDragDistance = 0;
      unawaited(_setCalendarExpanded(false, persist: false));
    } else if (_calendarVerticalDragDistance >= 18 && !isCalendarExpanded) {
      _calendarVerticalDragDistance = 0;
      unawaited(_setCalendarExpanded(true, persist: false));
    }
  }

  Future<void> _showCreateActionSheet(List<TrainingEntry> entries) async {
    if (_isParentMode) {
      _showParentReadOnlyMessage();
      return;
    }
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final l10n = AppLocalizations.of(context)!;
    final selectedDay = _selectedDay ?? _focusedDay;
    final action = await _showModalBottomSheetSafely<_CalendarCreateAction>(
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_alarm_outlined),
                title: Text(l10n.drawerTrainingPlan),
                onTap: () =>
                    Navigator.of(context).pop(_CalendarCreateAction.plan),
              ),
              ListTile(
                leading: const Icon(Icons.note_add_outlined),
                title: Text(isKo ? '훈련 노트' : 'Training note'),
                onTap: () =>
                    Navigator.of(context).pop(_CalendarCreateAction.entry),
              ),
              ListTile(
                leading: const Icon(Icons.rice_bowl_outlined),
                title: Text(l10n.mealLogScreenTitle),
                onTap: () =>
                    Navigator.of(context).pop(_CalendarCreateAction.meal),
              ),
              ListTile(
                leading: const Icon(Icons.sports_score_outlined),
                title: Text(l10n.matchHubRecordButton),
                onTap: () =>
                    Navigator.of(context).pop(_CalendarCreateAction.match),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isKo ? '빠른 계획 추가' : 'Quick plan add',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(
                      Icons.self_improvement_outlined,
                      size: 16,
                    ),
                    label: Text(isKo ? '회복 30분' : 'Recovery 30m'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _createQuickTemplatePlan(
                        day: selectedDay,
                        category: isKo ? '회복 훈련' : 'Recovery',
                        durationMinutes: 30,
                      );
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.sports_outlined, size: 16),
                    label: Text(isKo ? '기술 60분' : 'Skill 60m'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _createQuickTemplatePlan(
                        day: selectedDay,
                        category: isKo ? '기술 훈련' : 'Skill',
                        durationMinutes: 60,
                      );
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.sports_soccer_outlined, size: 16),
                    label: Text(isKo ? '게임 90분' : 'Game 90m'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _createQuickTemplatePlan(
                        day: selectedDay,
                        category: isKo ? '게임 훈련' : 'Game',
                        durationMinutes: 90,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _CalendarCreateAction.entry:
        widget.onCreate?.call();
        break;
      case _CalendarCreateAction.meal:
        await _openMealLog(day: selectedDay);
        break;
      case _CalendarCreateAction.plan:
        await _openPlanSheet(day: selectedDay);
        break;
      case _CalendarCreateAction.match:
        if (widget.onOpenMatchRecord != null) {
          widget.onOpenMatchRecord!(selectedDay);
        } else {
          await _openMatchSheet(day: selectedDay, entries: entries);
        }
        break;
    }
  }

  Future<void> _openMealLog({required DateTime day, MealEntry? entry}) async {
    if (!mounted) return;
    final existingEntry = entry ?? widget.mealLogService.entryForDay(day);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MealLogScreen(
          mealLogService: widget.mealLogService,
          optionRepository: widget.optionRepository,
          settingsService: widget.settingsService,
          initialDate: day,
          initialEntry: existingEntry,
        ),
      ),
    );
  }

  Future<bool> _confirmDeleteMealEntry(MealEntry entry) async {
    if (_isParentMode) {
      _showParentReadOnlyMessage();
      return false;
    }
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.mealDeleteAction),
        content: Text(l10n.mealDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.mealDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    await PlayerLevelService(widget.optionRepository).revokeMealLogAward(entry);
    await widget.mealLogService.deleteDay(entry.date);
    if (!mounted) return true;
    AppFeedback.showSuccess(context, text: l10n.mealDeletedFeedback);
    return true;
  }

  Future<void> _createQuickTemplatePlan({
    required DateTime day,
    required String category,
    required int durationMinutes,
  }) async {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final normalized = _normalizeDay(day);
    final seedPlan = _lastSavedPlanTemplate();
    final seedTime = seedPlan?.scheduledAt;
    final scheduledAt = DateTime(
      normalized.year,
      normalized.month,
      normalized.day,
      seedTime?.hour ?? 18,
      seedTime?.minute ?? 0,
    );
    final hasConflict = _plans.any(
      (plan) =>
          _normalizeDay(plan.scheduledAt) == normalized &&
          plan.scheduledAt.hour == scheduledAt.hour &&
          plan.scheduledAt.minute == scheduledAt.minute,
    );
    if (hasConflict) {
      AppFeedback.showMessage(
        context,
        text: isKo
            ? '같은 시간에 이미 등록된 계획이 있어요.'
            : 'Another plan already exists at that time.',
      );
      return;
    }
    final idSeed = DateTime.now().microsecondsSinceEpoch.toString();
    final seedNote =
        seedPlan == null ? '' : _visiblePlanNote(seedPlan, isKo: isKo);
    final quickPlan = _TrainingPlan(
      id: '${idSeed}_${DateFormat('yyyyMMddHHmm').format(scheduledAt)}',
      scheduledAt: scheduledAt,
      category: (seedPlan?.category.trim().isNotEmpty ?? false)
          ? seedPlan!.category
          : category,
      durationMinutes: seedPlan?.durationMinutes ?? durationMinutes,
      reminderMinutesBefore:
          seedPlan?.reminderMinutesBefore ?? _lastPlanReminderMinutes(),
      repeatWeekdays: const <int>[],
      alarmLoopEnabled: seedPlan?.alarmLoopEnabled ?? false,
      location: '',
      note: seedNote,
    );
    setState(() {
      _plans = [..._plans, quickPlan]
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    });
    await _savePlans();
    await widget.optionRepository.setValue(
      _lastPlanTemplateStorageKey,
      jsonEncode(quickPlan.toMap()),
    );
    await _requestReminderPermissionIfNeeded();
    await _syncPlanReminders();
    if (!mounted) return;
    AppFeedback.showSuccess(
      context,
      text: isKo
          ? '${quickPlan.category} 계획을 빠르게 추가했어요.'
          : 'Added ${quickPlan.category} quickly.',
    );
  }

  Future<void> _syncPlanReminders() async {
    await _reminderService.syncFromPlans(
      _plans.map((plan) => plan.toMap()).toList(growable: false),
    );
  }

  Future<void> _showReminderPermissionNoticeIfNeeded() async {
    if (!widget.settingsService.reminderEnabled) return;
    final granted = await _reminderService.hasNotificationPermission();
    if (!mounted || granted) return;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    AppFeedback.showMessage(
      context,
      text: isKo
          ? '알림 권한이 꺼져 있어 훈련 계획 알림이 오지 않을 수 있어요. 설정 > 알림에서 허용해 주세요.'
          : 'Notification permission is off, so training plan alerts may not arrive. Enable it in Settings > Notifications.',
    );
  }

  Future<void> _requestReminderPermissionIfNeeded() async {
    if (!widget.settingsService.reminderEnabled) return;
    final granted = await _reminderService.hasNotificationPermission();
    if (!mounted || granted) return;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isKo ? '알림 권한 필요' : 'Notification permission needed'),
        content: Text(
          isKo
              ? '훈련 계획 알림을 받으려면 알림 권한을 허용해야 해요. 지금 허용할까요?'
              : 'To receive training plan reminders, notification permission is required. Allow now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isKo ? '나중에' : 'Later'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isKo ? '허용하기' : 'Allow'),
          ),
        ],
      ),
    );
    if (!mounted || shouldRequest != true) return;
    await _reminderService.requestNotificationPermission();
  }

  Future<void> _openPlanSheet({
    required DateTime day,
    _TrainingPlan? editingPlan,
  }) async {
    final readOnly = _isParentMode && editingPlan != null;
    if (_isParentMode && !readOnly) {
      _showParentReadOnlyMessage();
      return;
    }
    if (!readOnly) {
      await _showReminderPermissionNoticeIfNeeded();
    }
    if (!mounted) return;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final l10n = AppLocalizations.of(context)!;
    final sportId = SportService(widget.optionRepository).currentSportId();
    final programOptionsKey = SportCatalog.optionKey(
      'programs',
      sportId: sportId,
    );
    final localizedProgramDefaults = SportDefaults.programOptions(
      l10n: l10n,
      sportId: sportId,
    );
    final rawCategories = widget.optionRepository.getOptions(
      programOptionsKey,
      localizedProgramDefaults,
    );
    final categories = LocalizedOptionDefaults.normalizeOptions(
      key: programOptionsKey,
      stored: rawCategories,
      localizedDefaults: localizedProgramDefaults,
    );
    final dedupedCategories = LinkedHashSet<String>.from(
      categories.map((item) => item.trim()).where((item) => item.isNotEmpty),
    ).toList(growable: false);
    if (!_sameStringList(rawCategories, categories)) {
      widget.optionRepository.saveOptions(programOptionsKey, categories);
    }
    final hasSeries = editingPlan?.seriesId != null;
    final seriesPlans =
        hasSeries ? _plansInSameSeries(editingPlan!) : const <_TrainingPlan>[];
    final seriesSeed = seriesPlans.isNotEmpty ? seriesPlans.first : editingPlan;
    final baseScheduledAt = editingPlan?.scheduledAt ?? day;
    final baseSeriesStartDate = editingPlan?.seriesStartDate ?? baseScheduledAt;
    final baseSeriesEndDate = editingPlan?.seriesEndDate ?? baseScheduledAt;
    var planDay = hasSeries
        ? (seriesSeed?.seriesStartDate ?? baseSeriesStartDate)
        : baseScheduledAt;
    var planEndDay = hasSeries
        ? (seriesSeed?.seriesEndDate ?? baseSeriesEndDate)
        : baseSeriesEndDate;
    final fallbackCategory = dedupedCategories.isEmpty
        ? (isKo ? '훈련' : 'Training')
        : dedupedCategories.first;
    var category = (editingPlan?.category ?? fallbackCategory).trim();
    if (category.isEmpty) {
      category = fallbackCategory;
    }
    final availableCategories = LinkedHashSet<String>.from(dedupedCategories);
    if (!availableCategories.contains(category)) {
      availableCategories.add(category);
    }
    final categoryItems = availableCategories.toList(growable: false);
    final preservedLocation = editingPlan?.location.trim() ?? '';
    final lastSavedPlan = editingPlan == null ? _lastSavedPlanTemplate() : null;
    final initialTimeSource =
        editingPlan?.scheduledAt ?? lastSavedPlan?.scheduledAt;
    var time = TimeOfDay(
      hour: initialTimeSource?.hour ?? 18,
      minute: initialTimeSource?.minute ?? 0,
    );
    var duration = editingPlan?.durationMinutes ?? 60;
    var reminderBefore = editingPlan?.reminderMinutesBefore ??
        seriesSeed?.reminderMinutesBefore ??
        _lastPlanReminderMinutes();
    final seedWeekdays = hasSeries
        ? (seriesSeed?.repeatWeekdays ?? const <int>[])
        : (editingPlan?.repeatWeekdays ?? const <int>[]);
    var repeatWeekdays =
        seedWeekdays.isNotEmpty ? seedWeekdays.toSet() : <int>{planDay.weekday};
    var showRepeatRangePicker = hasSeries ||
        !_isSameDay(planDay, planEndDay) ||
        seedWeekdays.length > 1 ||
        (seedWeekdays.length == 1 && !seedWeekdays.contains(planDay.weekday));
    var alarmLoopEnabled = editingPlan?.alarmLoopEnabled ?? false;
    var noteText = editingPlan?.note ?? '';
    if (!mounted) return;
    final saved = await showModalBottomSheet<_PlanSheetResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        readOnly
                            ? l10n.trainingPlanViewTitle
                            : editingPlan == null
                                ? l10n.trainingPlanAddTitle
                                : l10n.trainingPlanEditTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      IgnorePointer(
                        ignoring: readOnly,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: category,
                              decoration: InputDecoration(
                                labelText: isKo ? '훈련 항목' : 'Category',
                              ),
                              items: categoryItems
                                  .map(
                                    (item) => DropdownMenuItem<String>(
                                      value: item,
                                      child: Text(item),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: (value) {
                                if (value == null) return;
                                setSheetState(() => category = value);
                              },
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: planDay,
                                        firstDate: DateTime(2022),
                                        lastDate: DateTime(2032),
                                      );
                                      if (picked == null || !context.mounted) {
                                        return;
                                      }
                                      setSheetState(() {
                                        planDay = DateTime(
                                          picked.year,
                                          picked.month,
                                          picked.day,
                                        );
                                        if (planEndDay.isBefore(planDay)) {
                                          planEndDay = planDay;
                                        }
                                        if (editingPlan == null) {
                                          repeatWeekdays = <int>{
                                            planDay.weekday,
                                          };
                                        }
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.calendar_today_outlined,
                                    ),
                                    label: Text(
                                      editingPlan == null
                                          ? (isKo
                                              ? '날짜 ${DateFormat('yyyy-MM-dd').format(planDay)}'
                                              : 'Date ${DateFormat('yyyy-MM-dd').format(planDay)}')
                                          : DateFormat(
                                              'yyyy-MM-dd',
                                            ).format(planDay),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: time,
                                      );
                                      if (picked == null || !context.mounted) {
                                        return;
                                      }
                                      setSheetState(() => time = picked);
                                    },
                                    icon: const Icon(Icons.access_time),
                                    label: Text(
                                      isKo
                                          ? '시간 ${time.format(context)}'
                                          : 'Time ${time.format(context)}',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    initialValue: duration,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      labelText: isKo ? '훈련 시간' : 'Duration',
                                    ),
                                    items: const [30, 45, 60, 90, 120]
                                        .map(
                                          (value) => DropdownMenuItem<int>(
                                            value: value,
                                            child: Text(
                                              _formatDurationText(
                                                value,
                                                isKo: isKo,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        )
                                        .toList(growable: false),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setSheetState(() => duration = value);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int>(
                              initialValue: reminderBefore,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: isKo ? '사전 알림' : 'Reminder',
                              ),
                              items: const [10, 20, 30, 60]
                                  .map(
                                    (value) => DropdownMenuItem<int>(
                                      value: value,
                                      child: Text(
                                        isKo
                                            ? '$value분 전'
                                            : '$value min before',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: (value) {
                                if (value == null) return;
                                setSheetState(() => reminderBefore = value);
                              },
                            ),
                            const SizedBox(height: 8),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                isKo
                                    ? '훈련 시작 시각에도 노티 한 번 더 보내기'
                                    : 'Send one more notification at start time',
                              ),
                              value: alarmLoopEnabled,
                              onChanged: (value) {
                                setSheetState(() => alarmLoopEnabled = value);
                              },
                            ),
                            Text(
                              editingPlan == null
                                  ? (isKo
                                      ? '기간과 요일을 고르면 실제 계획이 날짜별로 생성돼요.'
                                      : 'Pick a range and weekdays to create real plans on each matching date.')
                                  : hasSeries
                                      ? (isKo
                                          ? '반복 기간을 켜면 요일과 기간을 함께 바꾸고, 저장할 때 적용 범위를 고릅니다.'
                                          : 'Turn on the repeat range to edit weekdays and date span, then choose the save scope.')
                                      : (isKo
                                          ? '이번 계획만 따로 수정해요.'
                                          : 'Edit only this occurrence.'),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 6),
                            if (!showRepeatRangePicker)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () {
                                    setSheetState(() {
                                      showRepeatRangePicker = true;
                                      if (_isSameDay(planDay, planEndDay)) {
                                        planEndDay = planDay.add(
                                          const Duration(days: 7),
                                        );
                                      }
                                    });
                                  },
                                  icon: const Icon(Icons.event_repeat_outlined),
                                  label: Text(
                                    isKo ? '반복 기간 설정' : 'Set repeat range',
                                  ),
                                ),
                              ),
                            if (showRepeatRangePicker) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: planDay,
                                          firstDate: DateTime(2022),
                                          lastDate: DateTime(2032),
                                        );
                                        if (picked == null ||
                                            !context.mounted) {
                                          return;
                                        }
                                        setSheetState(() {
                                          planDay = DateTime(
                                            picked.year,
                                            picked.month,
                                            picked.day,
                                          );
                                          if (planEndDay.isBefore(planDay)) {
                                            planEndDay = planDay;
                                          }
                                          if (repeatWeekdays.isEmpty) {
                                            repeatWeekdays = <int>{
                                              planDay.weekday,
                                            };
                                          }
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.calendar_today_outlined,
                                      ),
                                      label: Text(
                                        isKo
                                            ? '시작 ${DateFormat('yyyy-MM-dd').format(planDay)}'
                                            : 'From ${DateFormat('yyyy-MM-dd').format(planDay)}',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              planEndDay.isBefore(planDay)
                                                  ? planDay
                                                  : planEndDay,
                                          firstDate: DateTime(
                                            planDay.year,
                                            planDay.month,
                                            planDay.day,
                                          ),
                                          lastDate: DateTime(2032),
                                        );
                                        if (picked == null ||
                                            !context.mounted) {
                                          return;
                                        }
                                        setSheetState(() {
                                          planEndDay = DateTime(
                                            picked.year,
                                            picked.month,
                                            picked.day,
                                          );
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.event_repeat_outlined,
                                      ),
                                      label: Text(
                                        isKo
                                            ? '종료 ${DateFormat('yyyy-MM-dd').format(planEndDay)}'
                                            : 'Until ${DateFormat('yyyy-MM-dd').format(planEndDay)}',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  isKo ? '반복 요일' : 'Repeat weekdays',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: List<Widget>.generate(7, (index) {
                                  final weekday = index + 1;
                                  final selected = repeatWeekdays.contains(
                                    weekday,
                                  );
                                  const koLabels = [
                                    '월',
                                    '화',
                                    '수',
                                    '목',
                                    '금',
                                    '토',
                                    '일',
                                  ];
                                  const enLabels = [
                                    'Mon',
                                    'Tue',
                                    'Wed',
                                    'Thu',
                                    'Fri',
                                    'Sat',
                                    'Sun',
                                  ];
                                  return ChoiceChip(
                                    label: Text(
                                      isKo ? koLabels[index] : enLabels[index],
                                    ),
                                    selected: selected,
                                    onSelected: (value) {
                                      setSheetState(() {
                                        if (value) {
                                          repeatWeekdays.add(weekday);
                                        } else if (repeatWeekdays.length > 1) {
                                          repeatWeekdays.remove(weekday);
                                        }
                                      });
                                    },
                                  );
                                }),
                              ),
                            ],
                            TextFormField(
                              initialValue: noteText,
                              onChanged: (value) => noteText = value,
                              maxLength: 60,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) =>
                                  FocusScope.of(context).unfocus(),
                              decoration: _calendarInputDecorationWithDone(
                                context,
                                InputDecoration(
                                  labelText:
                                      isKo ? '메모(선택)' : 'Note (optional)',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (readOnly)
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          label: Text(
                            MaterialLocalizations.of(context).closeButtonLabel,
                          ),
                        )
                      else
                        FilledButton.icon(
                          onPressed: () async {
                            final editScope = editingPlan == null || !hasSeries
                                ? _PlanEditScope.single
                                : await _pickPlanEditScope(editingPlan);
                            if (editScope == null || !context.mounted) return;
                            final editingSeries =
                                editScope == _PlanEditScope.series;
                            final editingAfterThis =
                                editScope == _PlanEditScope.afterThis;
                            final useRepeatRangeForSave =
                                TrainingPlanSeriesBuilder
                                    .shouldUseRepeatRangeForSave(
                              isCreatingPlan: editingPlan == null,
                              showRepeatRangePicker: showRepeatRangePicker,
                              isSingleEditScope:
                                  editScope == _PlanEditScope.single,
                            );
                            final scheduledAt = DateTime(
                              planDay.year,
                              planDay.month,
                              planDay.day,
                              time.hour,
                              time.minute,
                            );
                            final occurrenceDates = !useRepeatRangeForSave
                                ? <DateTime>[scheduledAt]
                                : TrainingPlanSeriesBuilder
                                    .buildOccurrenceDates(
                                    startDate: planDay,
                                    endDate: planEndDay,
                                    weekdays: repeatWeekdays.toList(),
                                    hour: time.hour,
                                    minute: time.minute,
                                  );
                            if (occurrenceDates.isEmpty) {
                              AppFeedback.showMessage(
                                context,
                                text: isKo
                                    ? '선택한 기간 안에 맞는 요일이 없어요.'
                                    : 'No matching weekdays exist in that date range.',
                              );
                              return;
                            }
                            final isRecurring = useRepeatRangeForSave &&
                                TrainingPlanSeriesBuilder.isRecurringSelection(
                                  startDate: planDay,
                                  endDate: planEndDay,
                                  weekdays: repeatWeekdays.toList(),
                                );
                            final hasTimeConflict = occurrenceDates.any((date) {
                              final onSameDay = _plans.where((plan) {
                                if (_normalizeDay(plan.scheduledAt) !=
                                    _normalizeDay(date)) {
                                  return false;
                                }
                                if (editingPlan == null) return true;
                                if (editingSeries &&
                                    editingPlan.seriesId != null &&
                                    plan.seriesId == editingPlan.seriesId) {
                                  return false;
                                }
                                if (editingAfterThis &&
                                    editingPlan.seriesId != null &&
                                    plan.seriesId == editingPlan.seriesId &&
                                    !plan.scheduledAt.isBefore(
                                      editingPlan.scheduledAt,
                                    )) {
                                  return false;
                                }
                                if (!editingSeries &&
                                    !editingAfterThis &&
                                    plan.id == editingPlan.id) {
                                  return false;
                                }
                                return true;
                              }).toList(growable: false);
                              return onSameDay.any(
                                (plan) =>
                                    plan.scheduledAt.hour == date.hour &&
                                    plan.scheduledAt.minute == date.minute,
                              );
                            });
                            if (hasTimeConflict) {
                              AppFeedback.showMessage(
                                context,
                                text: isKo
                                    ? '같은 시간에 이미 등록된 계획이 있어요.'
                                    : 'Another plan already exists at that time.',
                              );
                              return;
                            }
                            Navigator.of(context).pop(
                              _PlanSheetResult(
                                plans: editingPlan == null
                                    ? _buildPlanDrafts(
                                        occurrenceDates: occurrenceDates,
                                        category: category,
                                        durationMinutes: duration,
                                        reminderMinutesBefore: reminderBefore,
                                        repeatWeekdays: repeatWeekdays.toList(),
                                        alarmLoopEnabled: alarmLoopEnabled,
                                        location: '',
                                        note: noteText.trim(),
                                        isRecurring: isRecurring,
                                        seriesStartDate: planDay,
                                        seriesEndDate: planEndDay,
                                      )
                                    : editScope == _PlanEditScope.single
                                        ? <_TrainingPlan>[
                                            _TrainingPlan(
                                              id: editingPlan.id,
                                              scheduledAt: scheduledAt,
                                              category: category,
                                              durationMinutes: duration,
                                              reminderMinutesBefore:
                                                  reminderBefore,
                                              repeatWeekdays:
                                                  editingPlan.repeatWeekdays,
                                              alarmLoopEnabled:
                                                  alarmLoopEnabled,
                                              location: preservedLocation,
                                              note: noteText.trim(),
                                              seriesId: editingPlan.seriesId,
                                              seriesStartDate:
                                                  editingPlan.seriesStartDate,
                                              seriesEndDate:
                                                  editingPlan.seriesEndDate,
                                            ),
                                          ]
                                        : _buildPlanDrafts(
                                            occurrenceDates: occurrenceDates,
                                            category: category,
                                            durationMinutes: duration,
                                            reminderMinutesBefore:
                                                reminderBefore,
                                            repeatWeekdays:
                                                repeatWeekdays.toList(),
                                            alarmLoopEnabled: alarmLoopEnabled,
                                            location: preservedLocation,
                                            note: noteText.trim(),
                                            isRecurring: isRecurring,
                                            seriesStartDate: planDay,
                                            seriesEndDate: planEndDay,
                                            existingSeriesId: isRecurring
                                                ? editingPlan.seriesId
                                                : null,
                                          ),
                                scope: editScope,
                              ),
                            );
                          },
                          icon: const Icon(Icons.check),
                          label: Text(isKo ? '저장' : 'Save'),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (saved == null || saved.plans.isEmpty) return;
    await widget.optionRepository.setValue(
      _lastPlanReminderStorageKey,
      saved.plans.first.reminderMinutesBefore,
    );
    await widget.optionRepository.setValue(
      _lastPlanTemplateStorageKey,
      jsonEncode(saved.plans.first.toMap()),
    );
    setState(() {
      if (editingPlan == null) {
        _plans = [..._plans, ...saved.plans];
      } else if (saved.scope == _PlanEditScope.series &&
          editingPlan.seriesId != null) {
        _plans = _replacePlansForSeries(editingPlan.seriesId!, saved.plans);
      } else if (saved.scope == _PlanEditScope.afterThis &&
          editingPlan.seriesId != null) {
        _plans = _replacePlansAfterDateForSeries(
          editingPlan.seriesId!,
          editingPlan.scheduledAt,
          saved.plans,
        );
      } else {
        _plans = _plans
            .map(
              (plan) =>
                  plan.id == saved.plans.first.id ? saved.plans.first : plan,
            )
            .toList(growable: false);
      }
      _plans = [..._plans]
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    });
    await _savePlans();
    await _requestReminderPermissionIfNeeded();
    await _syncPlanReminders();
    await _showReminderPermissionNoticeIfNeeded();
    if (editingPlan == null) {
      final award =
          await PlayerLevelService(widget.optionRepository).awardForPlanCreated(
        planId: saved.plans.first.id,
        planIds: saved.plans.map((plan) => plan.id).toList(growable: false),
      );
      if (award.didLevelUp) {
        final reminderService = TrainingPlanReminderService(
          widget.optionRepository,
          widget.settingsService,
        );
        await reminderService.showXpGainAlert(
          gainedXp: award.gainedXp,
          totalXp: award.after.totalXp,
          isKo: isKo,
          sourceLabel: isKo ? '훈련 계획' : 'Training plan',
        );
        await reminderService.showLevelUpAlert(
          level: award.after.level,
          isKo: isKo,
        );
      } else {
        await TrainingPlanReminderService(
          widget.optionRepository,
          widget.settingsService,
        ).showXpGainAlert(
          gainedXp: award.gainedXp,
          totalXp: award.after.totalXp,
          isKo: isKo,
          sourceLabel: isKo ? '훈련 계획' : 'Training plan',
        );
      }
    }
  }

  Future<void> _openMatchSheet({
    required DateTime day,
    TrainingEntry? editingEntry,
    required List<TrainingEntry> entries,
  }) async {
    final readOnly = _isParentMode && editingEntry != null;
    if (_isParentMode && !readOnly) {
      _showParentReadOnlyMessage();
      return;
    }
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final l10n = AppLocalizations.of(context)!;
    final sportId = editingEntry?.sportId ??
        SportService(widget.optionRepository).currentSportId();
    final matchLabels = SportMatchLabels.forSport(
      l10n: l10n,
      sportId: sportId,
    );
    final initialDay = editingEntry?.date ?? day;
    var matchDay = DateTime(initialDay.year, initialDay.month, initialDay.day);
    var matchKind = editingEntry?.isTournamentMatch == true
        ? 'tournament'
        : editingEntry?.isLeagueMatch == true
            ? 'league'
            : 'friendly';
    var opponent = editingEntry?.opponentTeam ?? editingEntry?.club ?? '';
    var location = editingEntry?.effectiveMatchLocation ?? '';
    final opponentOptions = _matchOpponentOptions(entries);
    final locationOptions = _matchLocationOptions(entries, sportId);
    final matchCompetitionService = MatchCompetitionService(
      widget.optionRepository,
      sportId: sportId,
    );
    var leagueTeamsText = editingEntry?.leagueTeamNames.join('\n') ?? '';
    var competitionNameText = editingEntry?.matchCompetitionName ?? '';
    final leagueTeamsController = TextEditingController(text: leagueTeamsText);
    final competitionNameController = TextEditingController(
      text: competitionNameText,
    );
    final initialCompetition = matchCompetitionService.findCompetition(
      kind: matchKind,
      name: competitionNameText,
    );
    var selectedCompetitionId = initialCompetition?.id ?? '';
    var competitionStatus =
        initialCompetition?.status ?? MatchCompetitionRecord.statusActive;
    var leagueRoundText = editingEntry?.isLeagueMatch == true
        ? editingEntry?.matchStage ?? ''
        : '';
    var tournamentStage = normalizeMatchTournamentStage(
      editingEntry?.isTournamentMatch == true
          ? editingEntry?.matchStage ?? ''
          : '',
    );
    var tournamentOutcome = normalizeMatchTournamentOutcome(
      editingEntry?.isTournamentMatch == true
          ? editingEntry?.tournamentOutcome ?? ''
          : '',
    );
    var leaguePointsText = editingEntry?.leaguePoints?.toString() ?? '';
    var tournamentWinsText = editingEntry?.tournamentWins?.toString() ?? '';
    final ourScoreController = TextEditingController(
      text: editingEntry?.scoredGoals?.toString() ?? '',
    );
    final opponentScoreController = TextEditingController(
      text: editingEntry?.concededGoals?.toString() ?? '',
    );
    var sheetControllersDisposeScheduled = false;
    var playerGoalsText = editingEntry?.playerGoals?.toString() ?? '';
    var playerAssistsText = editingEntry?.playerAssists?.toString() ?? '';
    var shotsOnTargetText = editingEntry?.shotsOnTarget?.toString() ?? '';
    var ballsWonText = editingEntry?.ballsWon?.toString() ?? '';
    var minutesPlayedText = editingEntry?.minutesPlayed?.toString() ?? '';
    var memoText = editingEntry?.notes ?? '';

    void scheduleSheetControllerDispose() {
      if (sheetControllersDisposeScheduled) return;
      sheetControllersDisposeScheduled = true;
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 350), () {
          ourScoreController.dispose();
          opponentScoreController.dispose();
          leagueTeamsController.dispose();
          competitionNameController.dispose();
        }),
      );
    }

    const matchResultUnset = 'unset';
    const matchResultWin = 'win';
    const matchResultDraw = 'draw';
    const matchResultLoss = 'loss';

    String matchResultValue() {
      final scored = _parseSheetInt(ourScoreController.text);
      final conceded = _parseSheetInt(opponentScoreController.text);
      if (scored == null || conceded == null) {
        return matchResultUnset;
      }
      if (scored > conceded) return matchResultWin;
      if (scored < conceded) return matchResultLoss;
      return matchResultDraw;
    }

    void applyMatchResult(String result) {
      switch (result) {
        case matchResultWin:
          ourScoreController.text = '1';
          opponentScoreController.text = '0';
          break;
        case matchResultDraw:
          ourScoreController.text = '1';
          opponentScoreController.text = '1';
          break;
        case matchResultLoss:
          ourScoreController.text = '0';
          opponentScoreController.text = '1';
          break;
        default:
          ourScoreController.clear();
          opponentScoreController.clear();
      }
    }

    final saved = await showModalBottomSheet<TrainingEntry>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            List<MatchCompetitionRecord> availableCompetitions() {
              if (matchKind != MatchCompetitionRecord.kindLeague &&
                  matchKind != MatchCompetitionRecord.kindTournament) {
                return const <MatchCompetitionRecord>[];
              }
              return matchCompetitionService.competitionsForKind(matchKind);
            }

            MatchCompetitionRecord? selectedCompetition() {
              final byId = matchCompetitionService.findCompetitionById(
                selectedCompetitionId,
              );
              if (byId != null && byId.kind == matchKind) return byId;
              return matchCompetitionService.findCompetition(
                kind: matchKind,
                name: competitionNameText,
              );
            }

            void applyCompetition(MatchCompetitionRecord record) {
              selectedCompetitionId = record.id;
              competitionStatus = record.status;
              competitionNameText = record.name;
              competitionNameController.text = record.name;
              leagueTeamsText = record.teams.join('\n');
              leagueTeamsController.text = leagueTeamsText;
              if (!record.teams.any((team) => team == opponent.trim())) {
                opponent = '';
              }
            }

            String competitionOptionLabel(MatchCompetitionRecord record) {
              return record.isFinished
                  ? l10n.matchCompetitionOptionFinished(record.name)
                  : l10n.matchCompetitionOptionActive(record.name);
            }

            List<String> registeredMatchTeams() {
              if (matchKind != 'league' && matchKind != 'tournament') {
                return const <String>[];
              }
              final selected = selectedCompetition();
              final inlineTeams = MatchCompetitionService.parseTeams(
                leagueTeamsText,
              );
              return MatchCompetitionService.normalizeTeams([
                ...inlineTeams,
                ...?selected?.teams,
              ]);
            }

            Widget buildCountStepper({
              required String label,
              required String valueText,
              required ValueChanged<String> onChanged,
            }) {
              final parsed = _parseSheetInt(valueText);
              final value = parsed ?? 0;
              void updateValue(int nextValue) {
                onChanged(nextValue <= 0 ? '' : nextValue.toString());
              }

              return _MatchCountStepper(
                label: label,
                value: value,
                hasValue: parsed != null,
                enabled: !readOnly,
                increaseTooltip: l10n.matchCountIncreaseTooltip(label),
                decreaseTooltip: l10n.matchCountDecreaseTooltip(label),
                onIncrement: () {
                  setSheetState(() => updateValue(value + 1));
                },
                onDecrement: value <= 0
                    ? null
                    : () {
                        setSheetState(() => updateValue(value - 1));
                      },
              );
            }

            Widget buildScoreStepper({
              required String label,
              required TextEditingController controller,
            }) {
              final parsed = _parseSheetInt(controller.text);
              final value = parsed ?? 0;
              void updateValue(int nextValue) {
                controller.text = nextValue < 0 ? '0' : nextValue.toString();
              }

              return _MatchCountStepper(
                label: label,
                value: value,
                hasValue: parsed != null,
                enabled: !readOnly,
                increaseTooltip: l10n.matchCountIncreaseTooltip(label),
                decreaseTooltip: l10n.matchCountDecreaseTooltip(label),
                onIncrement: () {
                  setSheetState(() => updateValue(value + 1));
                },
                onDecrement: value <= 0
                    ? null
                    : () {
                        setSheetState(() => updateValue(value - 1));
                      },
              );
            }

            Widget buildTwoColumnCounters(List<Widget> children) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 8) / 2;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final child in children)
                        SizedBox(width: itemWidth, child: child),
                    ],
                  );
                },
              );
            }

            void closeSheet() {
              FocusScope.of(context).unfocus();
              Navigator.of(context).pop();
            }

            final registeredOpponentOptions = registeredMatchTeams();
            final opponentFieldOptions = registeredOpponentOptions.isNotEmpty
                ? registeredOpponentOptions
                : opponentOptions;
            final competitionOptions = availableCompetitions();
            final selectedCompetitionRecord = selectedCompetition();
            final selectedCompetitionFinished =
                selectedCompetitionRecord?.isFinished == true ||
                    competitionStatus == MatchCompetitionRecord.statusFinished;
            final hasCompetitionFlow =
                matchKind == MatchCompetitionRecord.kindLeague ||
                    matchKind == MatchCompetitionRecord.kindTournament;
            final opponentStep = hasCompetitionFlow ? 3 : 2;
            final resultStep = hasCompetitionFlow ? 4 : 3;
            final personalStep = hasCompetitionFlow ? 5 : 4;

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.9,
              minChildSize: 0.45,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return SafeArea(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      16 + MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                readOnly
                                    ? l10n.matchViewTitle
                                    : editingEntry == null
                                        ? l10n.matchAddTitle
                                        : l10n.matchEditTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            IconButton(
                              onPressed: closeSheet,
                              tooltip: MaterialLocalizations.of(context)
                                  .closeButtonTooltip,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        IgnorePointer(
                          ignoring: readOnly,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _MatchSheetSection(
                                step: 1,
                                icon: Icons.event_available_outlined,
                                title: l10n.matchFlowBasicSectionTitle,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: readOnly
                                        ? null
                                        : () async {
                                            final picked = await showDatePicker(
                                              context: context,
                                              initialDate: matchDay,
                                              firstDate: DateTime(2022),
                                              lastDate: DateTime(2032),
                                            );
                                            if (picked == null ||
                                                !context.mounted) {
                                              return;
                                            }
                                            setSheetState(() {
                                              matchDay = DateTime(
                                                picked.year,
                                                picked.month,
                                                picked.day,
                                              );
                                            });
                                          },
                                    icon: const Icon(
                                      Icons.calendar_today_outlined,
                                    ),
                                    label: Text(
                                      DateFormat('yyyy-MM-dd').format(matchDay),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SegmentedButton<String>(
                                    segments: [
                                      ButtonSegment<String>(
                                        value: 'friendly',
                                        icon: const Icon(
                                          Icons.handshake_outlined,
                                        ),
                                        label: Text(l10n.matchKindFriendly),
                                      ),
                                      ButtonSegment<String>(
                                        value: 'league',
                                        icon: const Icon(
                                          Icons.emoji_events_outlined,
                                        ),
                                        label: Text(l10n.matchKindLeague),
                                      ),
                                      ButtonSegment<String>(
                                        value: 'tournament',
                                        icon: const Icon(
                                          Icons.account_tree_outlined,
                                        ),
                                        label: Text(l10n.matchKindTournament),
                                      ),
                                    ],
                                    selected: {matchKind},
                                    showSelectedIcon: false,
                                    onSelectionChanged: readOnly
                                        ? null
                                        : (selection) {
                                            setSheetState(() {
                                              final nextKind = selection.first;
                                              if (nextKind == matchKind) {
                                                return;
                                              }
                                              matchKind = nextKind;
                                              selectedCompetitionId = '';
                                              competitionStatus =
                                                  MatchCompetitionRecord
                                                      .statusActive;
                                              competitionNameText = '';
                                              competitionNameController.clear();
                                              leagueTeamsText = '';
                                              leagueTeamsController.clear();
                                              opponent = '';
                                            });
                                          },
                                  ),
                                  const SizedBox(height: 8),
                                  _CalendarAutocompleteField(
                                    initialValue: location,
                                    options: locationOptions,
                                    onChanged: (value) => location = value,
                                    textInputAction: TextInputAction.next,
                                    labelText: l10n.location,
                                    hintText: l10n.matchLocationHint,
                                    maxLength: 40,
                                    enabled: !readOnly,
                                  ),
                                ],
                              ),
                              if (hasCompetitionFlow) ...[
                                const SizedBox(height: 10),
                                _MatchSheetSection(
                                  step: 2,
                                  icon: matchKind ==
                                          MatchCompetitionRecord.kindTournament
                                      ? Icons.account_tree_outlined
                                      : Icons.leaderboard_outlined,
                                  title: l10n.matchFlowCompetitionSectionTitle,
                                  helper:
                                      l10n.matchFlowCompetitionSectionHelper,
                                  children: [
                                    if (competitionOptions.isNotEmpty) ...[
                                      Text(
                                        l10n.matchCompetitionSelectLabel,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          for (final record
                                              in competitionOptions)
                                            ChoiceChip(
                                              avatar: Icon(
                                                record.isFinished
                                                    ? Icons.flag_circle_outlined
                                                    : Icons.play_circle_outline,
                                                size: 18,
                                              ),
                                              label: Text(
                                                competitionOptionLabel(record),
                                              ),
                                              selected:
                                                  selectedCompetitionRecord
                                                          ?.id ==
                                                      record.id,
                                              onSelected: readOnly
                                                  ? null
                                                  : (_) {
                                                      setSheetState(() {
                                                        applyCompetition(
                                                          record,
                                                        );
                                                      });
                                                    },
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      if (selectedCompetitionFinished)
                                        _matchCompetitionEmptyMessage(
                                          context: context,
                                          message: l10n
                                              .matchCompetitionFinishedNotice,
                                        ),
                                      if (selectedCompetitionFinished)
                                        const SizedBox(height: 8),
                                    ],
                                    TextFormField(
                                      controller: competitionNameController,
                                      readOnly: readOnly,
                                      onChanged: (value) {
                                        setSheetState(() {
                                          competitionNameText = value;
                                          final matched =
                                              matchCompetitionService
                                                  .findCompetition(
                                            kind: matchKind,
                                            name: value,
                                          );
                                          if (matched == null) {
                                            selectedCompetitionId = '';
                                            competitionStatus =
                                                MatchCompetitionRecord
                                                    .statusActive;
                                          } else {
                                            applyCompetition(matched);
                                          }
                                        });
                                      },
                                      textInputAction: TextInputAction.next,
                                      decoration:
                                          _calendarInputDecorationWithDone(
                                        context,
                                        InputDecoration(
                                          labelText:
                                              l10n.matchCompetitionNameLabel,
                                          hintText: matchKind ==
                                                  MatchCompetitionRecord
                                                      .kindTournament
                                              ? l10n.matchTournamentNameHint
                                              : l10n.matchLeagueNameHint,
                                        ),
                                        enabled: !readOnly,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        final result =
                                            await _openMatchCompetitionManagerSheet(
                                          kind: matchKind,
                                          competitionName: competitionNameText,
                                          teamsText: leagueTeamsText,
                                          entries: entries,
                                          readOnly: readOnly,
                                          sportId: sportId,
                                        );
                                        if (result == null ||
                                            !context.mounted) {
                                          return;
                                        }
                                        setSheetState(() {
                                          competitionNameText = result.name;
                                          competitionNameController.text =
                                              result.name;
                                          leagueTeamsText =
                                              result.teams.join('\n');
                                          leagueTeamsController.text =
                                              leagueTeamsText;
                                          competitionStatus = result.status;
                                          selectedCompetitionId =
                                              MatchCompetitionService
                                                  .competitionId(
                                            kind: matchKind,
                                            name: result.name,
                                          );
                                        });
                                      },
                                      icon: Icon(
                                        matchKind ==
                                                MatchCompetitionRecord
                                                    .kindTournament
                                            ? Icons.account_tree_outlined
                                            : Icons.leaderboard_outlined,
                                      ),
                                      label: Text(
                                        l10n.matchCompetitionManageButton,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (matchKind ==
                                        MatchCompetitionRecord.kindLeague)
                                      TextFormField(
                                        initialValue: leagueRoundText,
                                        readOnly: readOnly,
                                        onChanged: (value) =>
                                            leagueRoundText = value,
                                        textInputAction: TextInputAction.next,
                                        decoration:
                                            _calendarInputDecorationWithDone(
                                          context,
                                          InputDecoration(
                                            labelText:
                                                l10n.matchLeagueRoundLabel,
                                            hintText: l10n.matchLeagueRoundHint,
                                          ),
                                          enabled: !readOnly,
                                        ),
                                      )
                                    else
                                      DropdownButtonFormField<String>(
                                        initialValue: tournamentStage,
                                        items: [
                                          for (final value
                                              in matchTournamentStageValues)
                                            DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(
                                                matchTournamentStageLabel(
                                                  l10n,
                                                  value,
                                                ),
                                              ),
                                            ),
                                        ],
                                        onChanged: readOnly
                                            ? null
                                            : (value) {
                                                if (value == null) return;
                                                setSheetState(() {
                                                  tournamentStage = value;
                                                });
                                              },
                                        decoration:
                                            _calendarInputDecorationWithDone(
                                          context,
                                          InputDecoration(
                                            labelText:
                                                l10n.matchTournamentStageLabel,
                                          ),
                                          enabled: !readOnly,
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: leagueTeamsController,
                                      readOnly: readOnly,
                                      onChanged: (value) {
                                        setSheetState(() {
                                          leagueTeamsText = value;
                                        });
                                      },
                                      textInputAction: TextInputAction.next,
                                      decoration:
                                          _calendarInputDecorationWithDone(
                                        context,
                                        InputDecoration(
                                          labelText: matchKind ==
                                                  MatchCompetitionRecord
                                                      .kindTournament
                                              ? l10n.matchTournamentTeamsLabel
                                              : l10n.matchLeagueTeamsLabel,
                                          hintText: matchKind ==
                                                  MatchCompetitionRecord
                                                      .kindTournament
                                              ? l10n.matchTournamentTeamsHint
                                              : l10n.matchLeagueTeamsHint,
                                        ),
                                        enabled: !readOnly,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 10),
                              _MatchSheetSection(
                                step: opponentStep,
                                icon: Icons.groups_2_outlined,
                                title: l10n.matchFlowOpponentSectionTitle,
                                helper: registeredOpponentOptions.isNotEmpty
                                    ? l10n.matchFlowOpponentSectionHelper
                                    : null,
                                children: [
                                  _CalendarAutocompleteField(
                                    key: ValueKey<String>(
                                      'match-opponent-$matchKind-$opponent',
                                    ),
                                    initialValue: opponent,
                                    options: opponentFieldOptions,
                                    onChanged: (value) => opponent = value,
                                    textInputAction: TextInputAction.next,
                                    labelText: l10n.matchOpponentTeamLabel,
                                    hintText: l10n.matchOpponentTeamHint,
                                    maxLength: 40,
                                    enabled: !readOnly,
                                  ),
                                  if (registeredOpponentOptions.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (final team
                                            in registeredOpponentOptions)
                                          ChoiceChip(
                                            label: Text(team),
                                            selected: opponent.trim() == team,
                                            onSelected: readOnly
                                                ? null
                                                : (_) {
                                                    setSheetState(() {
                                                      opponent = team;
                                                    });
                                                  },
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 10),
                              _MatchSheetSection(
                                step: resultStep,
                                icon: Icons.scoreboard_outlined,
                                title: l10n.matchFlowResultSectionTitle,
                                helper: l10n.matchFlowResultSectionHelper,
                                children: [
                                  Text(
                                    l10n.matchResultLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      ChoiceChip(
                                        avatar: const Icon(
                                          Icons.remove_circle_outline,
                                          size: 18,
                                        ),
                                        label: Text(l10n.matchResultUnset),
                                        selected: matchResultValue() ==
                                            matchResultUnset,
                                        onSelected: readOnly
                                            ? null
                                            : (_) {
                                                setSheetState(() {
                                                  applyMatchResult(
                                                    matchResultUnset,
                                                  );
                                                });
                                              },
                                      ),
                                      ChoiceChip(
                                        avatar: const Icon(
                                          Icons.emoji_events_outlined,
                                          size: 18,
                                        ),
                                        label: Text(l10n.matchResultWin),
                                        selected: matchResultValue() ==
                                            matchResultWin,
                                        onSelected: readOnly
                                            ? null
                                            : (_) {
                                                setSheetState(() {
                                                  applyMatchResult(
                                                    matchResultWin,
                                                  );
                                                });
                                              },
                                      ),
                                      ChoiceChip(
                                        avatar: const Icon(
                                          Icons.drag_handle,
                                          size: 18,
                                        ),
                                        label: Text(l10n.matchResultDraw),
                                        selected: matchResultValue() ==
                                            matchResultDraw,
                                        onSelected: readOnly
                                            ? null
                                            : (_) {
                                                setSheetState(() {
                                                  applyMatchResult(
                                                    matchResultDraw,
                                                  );
                                                });
                                              },
                                      ),
                                      ChoiceChip(
                                        avatar:
                                            const Icon(Icons.close, size: 18),
                                        label: Text(l10n.matchResultLoss),
                                        selected: matchResultValue() ==
                                            matchResultLoss,
                                        onSelected: readOnly
                                            ? null
                                            : (_) {
                                                setSheetState(() {
                                                  applyMatchResult(
                                                    matchResultLoss,
                                                  );
                                                });
                                              },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  buildTwoColumnCounters([
                                    buildScoreStepper(
                                      label: l10n.matchOurScoreLabel,
                                      controller: ourScoreController,
                                    ),
                                    buildScoreStepper(
                                      label: l10n.matchOpponentScoreLabel,
                                      controller: opponentScoreController,
                                    ),
                                  ]),
                                  if (matchKind ==
                                      MatchCompetitionRecord
                                          .kindTournament) ...[
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      initialValue: tournamentOutcome,
                                      items: [
                                        for (final value
                                            in matchTournamentOutcomeValues)
                                          DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(
                                              matchTournamentOutcomeLabel(
                                                l10n,
                                                value,
                                              ),
                                            ),
                                          ),
                                      ],
                                      onChanged: readOnly
                                          ? null
                                          : (value) {
                                              if (value == null) return;
                                              setSheetState(() {
                                                tournamentOutcome = value;
                                              });
                                            },
                                      decoration:
                                          _calendarInputDecorationWithDone(
                                        context,
                                        InputDecoration(
                                          labelText:
                                              l10n.matchTournamentOutcomeLabel,
                                        ),
                                        enabled: !readOnly,
                                      ),
                                    ),
                                  ],
                                  if (hasCompetitionFlow) ...[
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      initialValue: matchKind ==
                                              MatchCompetitionRecord.kindLeague
                                          ? leaguePointsText
                                          : tournamentWinsText,
                                      key: ValueKey<String>(matchKind),
                                      readOnly: readOnly,
                                      onChanged: (value) {
                                        if (matchKind ==
                                            MatchCompetitionRecord.kindLeague) {
                                          leaguePointsText = value;
                                        } else {
                                          tournamentWinsText = value;
                                        }
                                      },
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) =>
                                          FocusScope.of(context).unfocus(),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration:
                                          _calendarInputDecorationWithDone(
                                        context,
                                        InputDecoration(
                                          labelText: matchKind ==
                                                  MatchCompetitionRecord
                                                      .kindLeague
                                              ? l10n.matchLeaguePointsLabel
                                              : l10n.matchTournamentWinsLabel,
                                        ),
                                        enabled: !readOnly,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 10),
                              _MatchSheetSection(
                                step: personalStep,
                                icon: Icons.person_outline,
                                title: l10n.matchFlowPersonalSectionTitle,
                                helper: l10n.matchFlowPersonalSectionHelper,
                                children: [
                                  buildTwoColumnCounters([
                                    buildCountStepper(
                                      label: matchLabels.primary.label,
                                      valueText: playerGoalsText,
                                      onChanged: (value) =>
                                          playerGoalsText = value,
                                    ),
                                    buildCountStepper(
                                      label: matchLabels.secondary.label,
                                      valueText: playerAssistsText,
                                      onChanged: (value) =>
                                          playerAssistsText = value,
                                    ),
                                    buildCountStepper(
                                      label: matchLabels.tertiary.label,
                                      valueText: shotsOnTargetText,
                                      onChanged: (value) =>
                                          shotsOnTargetText = value,
                                    ),
                                    buildCountStepper(
                                      label: matchLabels.quaternary.label,
                                      valueText: ballsWonText,
                                      onChanged: (value) =>
                                          ballsWonText = value,
                                    ),
                                  ]),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    initialValue: minutesPlayedText,
                                    readOnly: readOnly,
                                    onChanged: (value) =>
                                        minutesPlayedText = value,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) =>
                                        FocusScope.of(context).unfocus(),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration:
                                        _calendarInputDecorationWithDone(
                                      context,
                                      InputDecoration(
                                        labelText: l10n.matchMinutesPlayedLabel,
                                        hintText: l10n.matchMinutesPlayedHint,
                                      ),
                                      enabled: !readOnly,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    initialValue: memoText,
                                    readOnly: readOnly,
                                    onChanged: (value) => memoText = value,
                                    maxLength: 60,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) =>
                                        FocusScope.of(context).unfocus(),
                                    decoration:
                                        _calendarInputDecorationWithDone(
                                      context,
                                      InputDecoration(
                                        labelText: l10n.matchNoteOptionalLabel,
                                      ),
                                      enabled: !readOnly,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (readOnly)
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                            label: Text(
                              MaterialLocalizations.of(context)
                                  .closeButtonLabel,
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: closeSheet,
                                  icon: const Icon(Icons.arrow_back),
                                  label: Text(
                                    l10n.matchCompetitionBackButton,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () {
                                    final leagueTeams = _parseSheetStringList(
                                      leagueTeamsText,
                                    );
                                    final trimmedOpponent = opponent.trim();
                                    if (matchKind == 'friendly' &&
                                        trimmedOpponent.isEmpty) {
                                      return;
                                    }
                                    if (matchKind == 'league' &&
                                        trimmedOpponent.isEmpty &&
                                        leagueTeams.isEmpty) {
                                      return;
                                    }
                                    if (matchKind == 'tournament' &&
                                        trimmedOpponent.isEmpty &&
                                        leagueTeams.isEmpty) {
                                      return;
                                    }
                                    final savedOpponent =
                                        trimmedOpponent.isNotEmpty
                                            ? trimmedOpponent
                                            : leagueTeams.first;
                                    Navigator.of(context).pop(
                                      TrainingEntry(
                                        date: matchDay,
                                        durationMinutes:
                                            editingEntry?.durationMinutes ?? 90,
                                        intensity: editingEntry?.intensity ?? 3,
                                        type: l10n.typeMatch,
                                        mood: editingEntry?.mood ?? 3,
                                        injury: editingEntry?.injury ?? false,
                                        notes: memoText.trim(),
                                        location: location.trim(),
                                        program: l10n.typeMatch,
                                        club: savedOpponent,
                                        opponentTeam: savedOpponent,
                                        status:
                                            editingEntry?.status ?? 'normal',
                                        goodPoints:
                                            editingEntry?.goodPoints ?? '',
                                        improvements:
                                            editingEntry?.improvements ?? '',
                                        nextGoal: editingEntry?.nextGoal ?? '',
                                        goalFocuses:
                                            editingEntry?.goalFocuses ??
                                                const [],
                                        createdAt: editingEntry?.createdAt,
                                        scoredGoals: _parseSheetInt(
                                          ourScoreController.text,
                                        ),
                                        concededGoals: _parseSheetInt(
                                          opponentScoreController.text,
                                        ),
                                        playerGoals:
                                            _parseSheetInt(playerGoalsText),
                                        playerAssists: _parseSheetInt(
                                          playerAssistsText,
                                        ),
                                        shotsOnTarget: _parseSheetInt(
                                          shotsOnTargetText,
                                        ),
                                        ballsWon: _parseSheetInt(ballsWonText),
                                        minutesPlayed: _parseSheetInt(
                                          minutesPlayedText,
                                        ),
                                        matchLocation: location.trim(),
                                        matchKind: matchKind,
                                        leagueTeamNames: leagueTeams,
                                        leagueResultMode:
                                            matchKind == 'tournament'
                                                ? 'tournamentWins'
                                                : 'points',
                                        leaguePoints: matchKind == 'league'
                                            ? _parseSheetInt(leaguePointsText)
                                            : null,
                                        tournamentWins:
                                            matchKind == 'tournament'
                                                ? _parseSheetInt(
                                                    tournamentWinsText,
                                                  )
                                                : null,
                                        matchCompetitionName:
                                            matchKind == 'friendly'
                                                ? ''
                                                : competitionNameText.trim(),
                                        matchStage: matchKind == 'tournament'
                                            ? tournamentStage
                                            : matchKind == 'league'
                                                ? leagueRoundText.trim()
                                                : '',
                                        tournamentOutcome:
                                            matchKind == 'tournament'
                                                ? tournamentOutcome
                                                : '',
                                        sportId: sportId,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.check),
                                  label: Text(l10n.save),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    ).whenComplete(scheduleSheetControllerDispose);
    if (saved == null) return;
    final trimmedMatchLocation = saved.effectiveMatchLocation.trim();
    if (trimmedMatchLocation.isNotEmpty) {
      await _storeMatchLocation(trimmedMatchLocation, saved.sportId);
    }
    await MatchCompetitionService(
      widget.optionRepository,
      sportId: saved.sportId,
    ).upsertFromEntry(saved);
    final previousEntry = editingEntry;
    if (editingEntry?.key is int) {
      await widget.trainingService.update(editingEntry!.key as int, saved);
    } else {
      await widget.trainingService.add(saved);
    }
    final award = await PlayerLevelService(
      widget.optionRepository,
      sportId: saved.sportId,
    ).awardForMatchLog(previousEntry: previousEntry, updatedEntry: saved);
    if (!mounted) return;
    AppFeedback.showSuccess(
      context,
      text: award.gainedXp > 0
          ? l10n.matchSavedWithXpFeedback(award.gainedXp)
          : previousEntry == null
              ? l10n.matchSavedFeedback
              : l10n.matchUpdatedFeedback,
    );
    if (award.gainedXp <= 0) return;
    final reminderService = TrainingPlanReminderService(
      widget.optionRepository,
      widget.settingsService,
      sportId: saved.sportId,
    );
    await reminderService.showXpGainAlert(
      gainedXp: award.gainedXp,
      totalXp: award.after.totalXp,
      isKo: isKo,
      sourceLabel: l10n.calendarMatchXpSourceLabel,
    );
    if (award.didLevelUp) {
      await reminderService.showLevelUpAlert(
        level: award.after.level,
        isKo: isKo,
      );
    }
  }

  Future<_MatchCompetitionSheetResult?> _openMatchCompetitionManagerSheet({
    required String kind,
    required String competitionName,
    required String teamsText,
    required List<TrainingEntry> entries,
    required bool readOnly,
    required String sportId,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final service = MatchCompetitionService(
      widget.optionRepository,
      sportId: sportId,
    );
    final existing = service.findCompetition(
      kind: kind,
      name: competitionName,
    );
    final nameController = TextEditingController(
      text: competitionName.trim().isNotEmpty
          ? competitionName.trim()
          : existing?.name ?? '',
    );
    final initialTeamsText = teamsText.trim().isNotEmpty
        ? teamsText
        : existing?.teams.join('\n') ?? '';
    var draftTeams = MatchCompetitionService.parseTeams(initialTeamsText);
    var competitionStatus =
        existing?.status ?? MatchCompetitionRecord.statusActive;
    final teamNameController = TextEditingController();
    var controllersDisposeScheduled = false;

    void scheduleControllerDispose() {
      if (controllersDisposeScheduled) return;
      controllersDisposeScheduled = true;
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 350), () {
          nameController.dispose();
          teamNameController.dispose();
        }),
      );
    }

    try {
      return await showModalBottomSheet<_MatchCompetitionSheetResult>(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        showDragHandle: true,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              final currentName = nameController.text.trim();
              final currentTeams = draftTeams;
              final title = currentName.isEmpty
                  ? l10n.matchCompetitionManagerNewTitle
                  : l10n.matchCompetitionManagerTitle(currentName);
              void addTeamFromField() {
                final additions = MatchCompetitionService.parseTeams(
                  teamNameController.text,
                );
                if (additions.isEmpty) {
                  AppFeedback.showMessage(
                    context,
                    text: l10n.matchCompetitionTeamNameRequired,
                  );
                  return;
                }
                final next = MatchCompetitionService.normalizeTeams([
                  ...draftTeams,
                  ...additions,
                ]);
                if (next.length == draftTeams.length) {
                  AppFeedback.showMessage(
                    context,
                    text: l10n.matchCompetitionTeamAlreadyAdded,
                  );
                  return;
                }
                setSheetState(() {
                  draftTeams = next;
                  teamNameController.clear();
                });
              }

              void removeTeam(String team) {
                setSheetState(() {
                  draftTeams = draftTeams
                      .where((current) => current != team)
                      .toList(growable: false);
                });
              }

              void closeSheet() {
                FocusScope.of(context).unfocus();
                Navigator.of(context).pop();
              }

              Future<void> saveCompetition() async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  AppFeedback.showMessage(
                    context,
                    text: l10n.matchCompetitionNameRequired,
                  );
                  return;
                }
                FocusScope.of(context).unfocus();
                await service.upsertCompetition(
                  MatchCompetitionRecord.create(
                    kind: kind,
                    name: name,
                    teams: draftTeams,
                    status: competitionStatus,
                  ),
                );
                if (!context.mounted) return;
                AppFeedback.showSuccess(
                  context,
                  text: l10n.matchCompetitionSavedFeedback,
                );
                Navigator.of(context).pop(
                  _MatchCompetitionSheetResult(
                    name: name,
                    teams: draftTeams,
                    status: competitionStatus,
                  ),
                );
              }

              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    16 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.82,
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                onPressed: closeSheet,
                                tooltip: MaterialLocalizations.of(context)
                                    .closeButtonTooltip,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: nameController,
                            readOnly: readOnly,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => setSheetState(() {}),
                            decoration: _calendarInputDecorationWithDone(
                              context,
                              InputDecoration(
                                labelText: l10n.matchCompetitionNameLabel,
                              ),
                              enabled: !readOnly,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.matchCompetitionStatusLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          SegmentedButton<String>(
                            segments: [
                              ButtonSegment<String>(
                                value: MatchCompetitionRecord.statusActive,
                                icon: const Icon(Icons.play_circle_outline),
                                label: Text(
                                  l10n.matchCompetitionStatusActive,
                                ),
                              ),
                              ButtonSegment<String>(
                                value: MatchCompetitionRecord.statusFinished,
                                icon: const Icon(Icons.flag_circle_outlined),
                                label: Text(
                                  l10n.matchCompetitionStatusFinished,
                                ),
                              ),
                            ],
                            selected: {competitionStatus},
                            showSelectedIcon: false,
                            onSelectionChanged: readOnly
                                ? null
                                : (selection) {
                                    setSheetState(() {
                                      competitionStatus = selection.first;
                                    });
                                  },
                          ),
                          const SizedBox(height: 8),
                          _buildMatchCompetitionTeamPreview(
                            context: context,
                            l10n: l10n,
                            teams: currentTeams,
                          ),
                          const SizedBox(height: 8),
                          TabBar(
                            tabs: [
                              Tab(text: l10n.matchCompetitionTeamsTab),
                              Tab(text: l10n.matchCompetitionResultsTab),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: TabBarView(
                              children: [
                                SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (!readOnly) ...[
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller: teamNameController,
                                                textInputAction:
                                                    TextInputAction.done,
                                                onFieldSubmitted: (_) =>
                                                    addTeamFromField(),
                                                decoration:
                                                    _calendarInputDecorationWithDone(
                                                  context,
                                                  InputDecoration(
                                                    labelText: l10n
                                                        .matchCompetitionTeamNameLabel,
                                                  ),
                                                  enabled: true,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 2,
                                              ),
                                              child: FilledButton.icon(
                                                onPressed: addTeamFromField,
                                                icon: const Icon(Icons.add),
                                                label: Text(
                                                  l10n.matchCompetitionAddTeamButton,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                      _buildMatchCompetitionTeamList(
                                        context: context,
                                        l10n: l10n,
                                        teams: currentTeams,
                                        readOnly: readOnly,
                                        onRemove: removeTeam,
                                      ),
                                    ],
                                  ),
                                ),
                                SingleChildScrollView(
                                  child: _buildMatchCompetitionResultView(
                                    context: context,
                                    l10n: l10n,
                                    kind: kind,
                                    competitionName: currentName,
                                    status: competitionStatus,
                                    teams: currentTeams,
                                    entries: entries,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: closeSheet,
                                  icon: const Icon(Icons.arrow_back),
                                  label: Text(
                                    l10n.matchCompetitionBackButton,
                                  ),
                                ),
                              ),
                              if (!readOnly) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: saveCompetition,
                                    icon: const Icon(Icons.save_outlined),
                                    label: Text(
                                      l10n.matchCompetitionSaveTeams,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      scheduleControllerDispose();
    }
  }

  Widget _buildMatchCompetitionTeamPreview({
    required BuildContext context,
    required AppLocalizations l10n,
    required List<String> teams,
  }) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.matchCompetitionTeamPreviewTitle,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  l10n.matchCompetitionTeamCount(teams.length),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (teams.isEmpty)
              Text(
                l10n.matchCompetitionNoTeams,
                style: theme.textTheme.bodySmall,
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 96),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final team in teams)
                        Chip(
                          avatar: const Icon(Icons.groups_2_outlined),
                          label: Text(team),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCompetitionTeamList({
    required BuildContext context,
    required AppLocalizations l10n,
    required List<String> teams,
    required bool readOnly,
    required ValueChanged<String> onRemove,
  }) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.matchCompetitionTeamsListTitle,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            if (teams.isEmpty)
              Text(
                l10n.matchCompetitionNoTeams,
                style: theme.textTheme.bodySmall,
              )
            else
              ...teams.map(
                (team) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.groups_2_outlined),
                      title: Text(team),
                      trailing: readOnly
                          ? null
                          : IconButton(
                              tooltip:
                                  l10n.matchCompetitionRemoveTeamTooltip(team),
                              onPressed: () => onRemove(team),
                              icon: const Icon(Icons.close),
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

  Widget _buildMatchCompetitionResultView({
    required BuildContext context,
    required AppLocalizations l10n,
    required String kind,
    required String competitionName,
    required String status,
    required List<String> teams,
    required List<TrainingEntry> entries,
  }) {
    if (kind == MatchCompetitionRecord.kindTournament) {
      return _buildTournamentBracketView(
        context: context,
        l10n: l10n,
        competitionName: competitionName,
        status: status,
        teams: teams,
        entries: entries,
      );
    }
    return _buildLeagueStandingsView(
      context: context,
      l10n: l10n,
      competitionName: competitionName,
      status: status,
      teams: teams,
      entries: entries,
    );
  }

  Widget _buildLeagueStandingsView({
    required BuildContext context,
    required AppLocalizations l10n,
    required String competitionName,
    required String status,
    required List<String> teams,
    required List<TrainingEntry> entries,
  }) {
    final competitionEntries = MatchCompetitionService.competitionEntries(
      kind: MatchCompetitionRecord.kindLeague,
      competitionName: competitionName,
      entries: entries,
    );
    final standings = MatchCompetitionService.buildLeagueStandings(
      competitionName: competitionName,
      registeredTeams: teams,
      entries: entries,
      ownTeamName: l10n.matchCompetitionMyTeamFallback,
    );
    final leader = standings.isEmpty
        ? l10n.matchCompetitionNoLeader
        : standings.first.team;
    final leaderPoints = standings.isEmpty
        ? '-'
        : l10n.matchLeaguePointsSummary(
            standings.first.points,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCompetitionResultOverview(
          context: context,
          l10n: l10n,
          icon: Icons.leaderboard_outlined,
          competitionName: competitionName,
          kindLabel: l10n.matchKindLeague,
          status: status,
        ),
        const SizedBox(height: 12),
        _buildCompetitionResultHeader(
          context: context,
          icon: Icons.leaderboard_outlined,
          title: l10n.matchLeagueStandingsTitle,
        ),
        const SizedBox(height: 10),
        _buildCompetitionMetricGrid(
          context: context,
          metrics: [
            _CompetitionMetric(
              icon: Icons.groups_2_outlined,
              label: l10n.matchCompetitionSummaryTeams,
              value: '${standings.length}',
            ),
            _CompetitionMetric(
              icon: Icons.sports_soccer_outlined,
              label: l10n.matchCompetitionSummaryMatches,
              value: '${competitionEntries.length}',
            ),
            _CompetitionMetric(
              icon: Icons.emoji_events_outlined,
              label: l10n.matchCompetitionSummaryLeader,
              value: leader,
            ),
            _CompetitionMetric(
              icon: Icons.military_tech_outlined,
              label: l10n.newsLeagueStandingsPointsColumn,
              value: leaderPoints,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (standings.isEmpty)
          _matchCompetitionEmptyMessage(
            context: context,
            message: l10n.matchCompetitionNoTeams,
          )
        else
          ...standings.indexed.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildLeagueStandingCard(
                context: context,
                l10n: l10n,
                rank: item.$1 + 1,
                row: item.$2,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTournamentBracketView({
    required BuildContext context,
    required AppLocalizations l10n,
    required String competitionName,
    required String status,
    required List<String> teams,
    required List<TrainingEntry> entries,
  }) {
    final pairs = MatchCompetitionService.buildTournamentBracketPairs(teams);
    final progressEntries = MatchCompetitionService.competitionEntries(
      kind: MatchCompetitionRecord.kindTournament,
      competitionName: competitionName,
      entries: entries,
    ).toList(growable: false)
      ..sort((a, b) => a.date.compareTo(b.date));
    final recordedProgress = pairs.isEmpty
        ? '-'
        : l10n.matchTournamentSlotProgress(
            progressEntries.length,
            pairs.length,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCompetitionResultOverview(
          context: context,
          l10n: l10n,
          icon: Icons.account_tree_outlined,
          competitionName: competitionName,
          kindLabel: l10n.matchKindTournament,
          status: status,
        ),
        const SizedBox(height: 12),
        _buildCompetitionResultHeader(
          context: context,
          icon: Icons.account_tree_outlined,
          title: l10n.matchTournamentBracketTitle,
        ),
        const SizedBox(height: 10),
        _buildCompetitionMetricGrid(
          context: context,
          metrics: [
            _CompetitionMetric(
              icon: Icons.groups_2_outlined,
              label: l10n.matchCompetitionSummaryTeams,
              value: '${teams.length}',
            ),
            _CompetitionMetric(
              icon: Icons.account_tree_outlined,
              label: l10n.matchTournamentSummarySlots,
              value: '${pairs.length}',
            ),
            _CompetitionMetric(
              icon: Icons.fact_check_outlined,
              label: l10n.matchCompetitionSummaryRecorded,
              value: '${progressEntries.length}',
            ),
            _CompetitionMetric(
              icon: Icons.timeline_outlined,
              label: l10n.matchCompetitionSummaryProgress,
              value: recordedProgress,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (pairs.isEmpty)
          _matchCompetitionEmptyMessage(
            context: context,
            message: l10n.matchCompetitionNoTeams,
          )
        else ...[
          ...pairs.map(
            (pair) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildTournamentPairCard(
                context: context,
                l10n: l10n,
                pair: pair,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        _buildCompetitionResultHeader(
          context: context,
          icon: Icons.timeline_outlined,
          title: l10n.matchTournamentRecordedProgressTitle,
        ),
        const SizedBox(height: 8),
        if (progressEntries.isEmpty)
          _matchCompetitionEmptyMessage(
            context: context,
            message: l10n.matchCompetitionNoMatches,
          )
        else
          ...progressEntries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildTournamentProgressCard(
                context: context,
                l10n: l10n,
                entry: entry,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompetitionResultOverview({
    required BuildContext context,
    required AppLocalizations l10n,
    required IconData icon,
    required String competitionName,
    required String kindLabel,
    required String status,
  }) {
    final theme = Theme.of(context);
    final title = competitionName.trim().isEmpty
        ? l10n.matchCompetitionManagerNewTitle
        : competitionName.trim();
    final statusLabel = status == MatchCompetitionRecord.statusFinished
        ? l10n.matchCompetitionStatusFinished
        : l10n.matchCompetitionStatusActive;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildCompetitionInfoPill(
                        context: context,
                        text: kindLabel,
                      ),
                      _buildCompetitionInfoPill(
                        context: context,
                        text: statusLabel,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetitionResultHeader({
    required BuildContext context,
    required IconData icon,
    required String title,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompetitionMetricGrid({
    required BuildContext context,
    required List<_CompetitionMetric> metrics,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: itemWidth,
                child: _buildCompetitionMetricCard(
                  context: context,
                  metric: metric,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCompetitionMetricCard({
    required BuildContext context,
    required _CompetitionMetric metric,
  }) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Icon(metric.icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    metric.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
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

  Widget _buildLeagueStandingCard({
    required BuildContext context,
    required AppLocalizations l10n,
    required int rank,
    required LeagueStandingRow row,
  }) {
    final theme = Theme.of(context);
    final isLeader = rank == 1;
    final background = isLeader
        ? theme.colorScheme.primaryContainer.withAlpha(122)
        : theme.colorScheme.surfaceContainerHighest;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border.all(
          color: isLeader
              ? theme.colorScheme.primary.withAlpha(115)
              : theme.colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isLeader
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                  child: Text(
                    '$rank',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isLeader
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    row.team,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.matchLeaguePointsSummary(row.points),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildCompetitionInfoPill(
                  context: context,
                  text: l10n.matchLeaguePlayedSummary(row.played),
                ),
                _buildCompetitionInfoPill(
                  context: context,
                  text: l10n.matchLeagueRecordSummary(
                    row.wins,
                    row.draws,
                    row.losses,
                  ),
                ),
                _buildCompetitionInfoPill(
                  context: context,
                  text: l10n.matchLeagueGoalDifferenceSummary(
                    row.goalDifference,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentPairCard({
    required BuildContext context,
    required AppLocalizations l10n,
    required TournamentBracketPair pair,
  }) {
    final theme = Theme.of(context);
    final teamB = pair.hasBye ? l10n.matchTournamentByeLabel : pair.teamB;
    final status = pair.hasBye
        ? l10n.matchTournamentPairByeStatus
        : l10n.matchTournamentPairPending;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.matchTournamentPairLabel(pair.slotNumber),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _buildCompetitionInfoPill(
                  context: context,
                  text: status,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildTournamentTeamName(
                    context: context,
                    team: pair.teamA,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    l10n.matchTournamentVersusLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildTournamentTeamName(
                    context: context,
                    team: teamB,
                    isBye: pair.hasBye,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.matchTournamentPairText(pair.teamA, teamB),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentTeamName({
    required BuildContext context,
    required String team,
    bool isBye = false,
  }) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isBye
            ? theme.colorScheme.secondaryContainer.withAlpha(140)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          team,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildTournamentProgressCard({
    required BuildContext context,
    required AppLocalizations l10n,
    required TrainingEntry entry,
  }) {
    final theme = Theme.of(context);
    final opponent = entry.opponentTeam.trim().isEmpty
        ? l10n.matchCompetitionMyTeamFallback
        : entry.opponentTeam.trim();
    final stage = matchTournamentStageLabel(l10n, entry.matchStage);
    final outcome = matchTournamentOutcomeLabel(l10n, entry.tournamentOutcome);
    final score = _formatMatchScore(entry);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.sports_score_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stage,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _buildCompetitionInfoPill(
                  context: context,
                  text: outcome,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.matchTournamentRecordedProgress(
                stage,
                opponent,
                outcome,
              ),
              style: theme.textTheme.bodyMedium,
            ),
            if (score != null || entry.tournamentWins != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (score != null)
                    _buildCompetitionInfoPill(
                      context: context,
                      text: score,
                    ),
                  if (entry.tournamentWins != null)
                    _buildCompetitionInfoPill(
                      context: context,
                      text: l10n.matchTournamentWinsValue(
                        entry.tournamentWins!,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompetitionInfoPill({
    required BuildContext context,
    required String text,
  }) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String? _formatMatchScore(TrainingEntry entry) {
    final scored = entry.scoredGoals;
    final conceded = entry.concededGoals;
    if (scored == null || conceded == null) return null;
    return '$scored:$conceded';
  }

  Widget _matchCompetitionEmptyMessage({
    required BuildContext context,
    required String message,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  List<String> _matchOpponentOptions(List<TrainingEntry> entries) {
    return _dedupeAutocompleteValues(
      entries.where((entry) => entry.isMatch).map(
            (entry) => entry.opponentTeam.trim().isNotEmpty
                ? entry.opponentTeam
                : entry.club,
          ),
    );
  }

  List<String> _matchLocationOptions(
      List<TrainingEntry> entries, String sportId) {
    final storedLocations = widget.optionRepository.getOptions(
      SportCatalog.optionKey('match_locations', sportId: sportId),
      [],
    );
    return _dedupeAutocompleteValues([
      ...storedLocations,
      ...entries
          .where((entry) => entry.isMatch)
          .map((entry) => entry.effectiveMatchLocation),
    ]);
  }

  Future<void> _storeMatchLocation(String location, String sportId) async {
    final key = SportCatalog.optionKey('match_locations', sportId: sportId);
    final existing = widget.optionRepository.getOptions(key, []);
    final updated = _dedupeAutocompleteValues([...existing, location]);
    await widget.optionRepository.saveOptions(key, updated);
  }

  List<String> _dedupeAutocompleteValues(Iterable<String> values) {
    final unique = <String>{};
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) continue;
      unique.add(trimmed);
    }
    return unique.toList(growable: false);
  }

  Future<void> _deletePlan(String id) async {
    await PlayerLevelService(widget.optionRepository).revokePlanAward(id);
    setState(() {
      _plans = _plans.where((plan) => plan.id != id).toList(growable: false);
    });
    await _savePlans();
    await _syncPlanReminders();
  }

  Future<void> _movePlanSchedule(_TrainingPlan plan) async {
    if (_isParentMode) {
      _showParentReadOnlyMessage();
      return;
    }
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: plan.scheduledAt,
      firstDate: DateTime(2022),
      lastDate: DateTime(2032),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(plan.scheduledAt),
    );
    if (pickedTime == null || !mounted) return;
    final movedAt = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    final hasConflict = _plans.any(
      (item) =>
          item.id != plan.id &&
          _normalizeDay(item.scheduledAt) == _normalizeDay(movedAt) &&
          item.scheduledAt.hour == movedAt.hour &&
          item.scheduledAt.minute == movedAt.minute,
    );
    if (hasConflict) {
      AppFeedback.showMessage(
        context,
        text: isKo
            ? '같은 시간에 이미 등록된 계획이 있어요.'
            : 'Another plan already exists at that time.',
      );
      return;
    }
    setState(() {
      _plans = _plans
          .map(
            (item) =>
                item.id == plan.id ? item.copyWith(scheduledAt: movedAt) : item,
          )
          .toList(growable: false)
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    });
    await _savePlans();
    await _syncPlanReminders();
    if (!mounted) return;
    AppFeedback.showSuccess(
      context,
      text: isKo ? '계획 시간을 이동했어요.' : 'Plan time moved.',
    );
  }

  Future<bool> _confirmDeletePlan(_TrainingPlan plan) async {
    if (_isParentMode) {
      _showParentReadOnlyMessage();
      return false;
    }
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final scope = await _pickPlanDeleteScope(plan);
    if (!mounted) return false;
    if (scope == null) return false;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isKo ? '계획 삭제' : 'Delete plan'),
        content: Text(
          scope == _PlanEditScope.series
              ? (isKo
                  ? '이 묶음에 포함된 훈련 계획을 모두 삭제할까요?'
                  : 'Delete every training plan in this series?')
              : scope == _PlanEditScope.afterThis
                  ? (isKo
                      ? '선택한 일정부터 이후 계획을 모두 삭제할까요?'
                      : 'Delete this plan and all following plans?')
                  : (isKo
                      ? '이 훈련 계획을 정말 삭제할까요?'
                      : 'Are you sure you want to delete this training plan?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isKo ? '취소' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isKo ? '삭제' : 'Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      if (scope == _PlanEditScope.series && plan.seriesId != null) {
        final deletedPlanIds = _plans
            .where((item) => item.seriesId == plan.seriesId)
            .map((item) => item.id)
            .toList(growable: false);
        final levelService = PlayerLevelService(widget.optionRepository);
        for (final id in deletedPlanIds) {
          await levelService.revokePlanAward(id);
        }
        setState(() {
          _plans = _plans
              .where((item) => item.seriesId != plan.seriesId)
              .toList(growable: false);
        });
        await _savePlans();
        await _syncPlanReminders();
      } else if (scope == _PlanEditScope.afterThis && plan.seriesId != null) {
        final deletedPlanIds = _plans
            .where(
              (item) =>
                  item.seriesId == plan.seriesId &&
                  !item.scheduledAt.isBefore(plan.scheduledAt),
            )
            .map((item) => item.id)
            .toList(growable: false);
        final levelService = PlayerLevelService(widget.optionRepository);
        for (final id in deletedPlanIds) {
          await levelService.revokePlanAward(id);
        }
        setState(() {
          _plans = _plans
              .where(
                (item) =>
                    item.seriesId != plan.seriesId ||
                    item.scheduledAt.isBefore(plan.scheduledAt),
              )
              .toList(growable: false);
        });
        await _savePlans();
        await _syncPlanReminders();
      } else {
        await _deletePlan(plan.id);
      }
      return true;
    }
    return false;
  }

  bool _sameStringList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  int? _parseSheetInt(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  List<String> _parseSheetStringList(String text) {
    final seen = <String>{};
    final values = <String>[];
    for (final raw in text.split(RegExp(r'[,/\n]'))) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty || seen.contains(trimmed)) continue;
      seen.add(trimmed);
      values.add(trimmed);
    }
    return values;
  }

  List<_TrainingPlan> _buildPlanDrafts({
    required List<DateTime> occurrenceDates,
    required String category,
    required int durationMinutes,
    required int reminderMinutesBefore,
    required List<int> repeatWeekdays,
    required bool alarmLoopEnabled,
    required String location,
    required String note,
    required bool isRecurring,
    required DateTime seriesStartDate,
    required DateTime seriesEndDate,
    String? existingSeriesId,
  }) {
    final sortedDates = [...occurrenceDates]..sort();
    final idSeed =
        existingSeriesId ?? DateTime.now().microsecondsSinceEpoch.toString();
    final seriesId = isRecurring ? idSeed : null;
    final normalizedWeekdays = repeatWeekdays.toSet().toList(growable: false)
      ..sort();
    return sortedDates.map((scheduledAt) {
      final dateToken = DateFormat('yyyyMMddHHmm').format(scheduledAt);
      return _TrainingPlan(
        id: '${seriesId ?? idSeed}_$dateToken',
        scheduledAt: scheduledAt,
        category: category,
        durationMinutes: durationMinutes,
        reminderMinutesBefore: reminderMinutesBefore,
        repeatWeekdays: isRecurring ? normalizedWeekdays : const <int>[],
        alarmLoopEnabled: alarmLoopEnabled,
        location: location,
        note: note,
        seriesId: seriesId,
        seriesStartDate: isRecurring ? _normalizeDay(seriesStartDate) : null,
        seriesEndDate: isRecurring ? _normalizeDay(seriesEndDate) : null,
      );
    }).toList(growable: false);
  }

  List<_TrainingPlan> _plansInSameSeries(_TrainingPlan plan) {
    final seriesId = plan.seriesId;
    if (seriesId == null || seriesId.isEmpty) return <_TrainingPlan>[plan];
    return _plans
        .where((item) => item.seriesId == seriesId)
        .toList(growable: false)
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  List<_TrainingPlan> _replacePlansForSeries(
    String seriesId,
    List<_TrainingPlan> replacement,
  ) {
    final next =
        _plans.where((plan) => plan.seriesId != seriesId).toList(growable: true)
          ..addAll(replacement)
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return next;
  }

  List<_TrainingPlan> _replacePlansAfterDateForSeries(
    String seriesId,
    DateTime pivotDateTime,
    List<_TrainingPlan> replacement,
  ) {
    final next = _plans
        .where(
          (plan) =>
              plan.seriesId != seriesId ||
              plan.scheduledAt.isBefore(pivotDateTime),
        )
        .toList(growable: true)
      ..addAll(replacement)
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return next;
  }

  Future<_PlanEditScope?> _pickPlanEditScope(_TrainingPlan? plan) async {
    if (plan == null || plan.seriesId == null) return _PlanEditScope.single;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    return showModalBottomSheet<_PlanEditScope>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isKo ? '변경 범위 선택' : 'Choose edit scope',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.event_available_outlined),
                title: Text(isKo ? '이번 계획만' : 'Only this plan'),
                subtitle: Text(
                  isKo
                      ? '선택한 날짜의 계획만 수정합니다.'
                      : 'Edit only the selected occurrence.',
                ),
                onTap: () => Navigator.of(context).pop(_PlanEditScope.single),
              ),
              ListTile(
                leading: const Icon(Icons.trending_flat_outlined),
                title: Text(isKo ? '이번 이후 일정' : 'This and following'),
                subtitle: Text(
                  isKo
                      ? '선택한 일정부터 이후 일정을 수정합니다.'
                      : 'Update this occurrence and following ones.',
                ),
                onTap: () =>
                    Navigator.of(context).pop(_PlanEditScope.afterThis),
              ),
              ListTile(
                leading: const Icon(Icons.layers_outlined),
                title: Text(isKo ? '묶음 전체' : 'Whole series'),
                subtitle: Text(
                  isKo
                      ? '같은 묶음의 일정 전체를 한 번에 수정합니다.'
                      : 'Edit every plan in the same series.',
                ),
                onTap: () => Navigator.of(context).pop(_PlanEditScope.series),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<_PlanEditScope?> _pickPlanDeleteScope(_TrainingPlan plan) async {
    if (plan.seriesId == null) return _PlanEditScope.single;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    return showModalBottomSheet<_PlanEditScope>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isKo ? '삭제 범위 선택' : 'Choose delete scope',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(isKo ? '이번 계획만 삭제' : 'Delete this plan'),
                onTap: () => Navigator.of(context).pop(_PlanEditScope.single),
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever_outlined),
                title: Text(isKo ? '이번 이후 삭제' : 'Delete this and following'),
                onTap: () =>
                    Navigator.of(context).pop(_PlanEditScope.afterThis),
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep_outlined),
                title: Text(isKo ? '묶음 전체 삭제' : 'Delete whole series'),
                onTap: () => Navigator.of(context).pop(_PlanEditScope.series),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDeleteEntry(TrainingEntry entry) async {
    if (_isParentMode) {
      _showParentReadOnlyMessage();
      return false;
    }
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isKo ? '일지 삭제' : 'Delete log'),
        content: Text(
          isKo
              ? '이 훈련 일지를 정말 삭제할까요?'
              : 'Are you sure you want to delete this training log?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isKo ? '취소' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isKo ? '삭제' : 'Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      await PlayerLevelService(
        widget.optionRepository,
        sportId: entry.sportId,
      ).revokeTrainingEntryAward(entry);
      await widget.trainingService.delete(entry);
      return true;
    }
    return false;
  }

  void _reloadPlansFromStorage() {
    final raw = widget.optionRepository.getValue<String>(_plansStorageKey);
    _plansStorageRaw = raw ?? '';
    _plans = _decodePlans(_plansStorageRaw);
  }

  void _refreshPlansFromStorageIfChanged() {
    final raw =
        widget.optionRepository.getValue<String>(_plansStorageKey) ?? '';
    if (raw == _plansStorageRaw) return;
    _plansStorageRaw = raw;
    _plans = _decodePlans(raw);
    unawaited(_badgeService.syncFromStorage());
    unawaited(_syncPlanReminders());
  }

  List<_TrainingPlan> _decodePlans(String raw) {
    if (raw.isEmpty) return const <_TrainingPlan>[];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const <_TrainingPlan>[];
      return list
          .whereType<Map>()
          .map(
            (rawMap) => _TrainingPlan.fromMap(rawMap.cast<String, dynamic>()),
          )
          .toList(growable: false);
    } catch (_) {
      return const <_TrainingPlan>[];
    }
  }

  Future<void> _savePlans() async {
    if (_isParentMode) {
      _showParentReadOnlyMessage();
      return;
    }
    final raw = jsonEncode(_plans.map((plan) => plan.toMap()).toList());
    await widget.optionRepository.setValue(_plansStorageKey, raw);
    _plansStorageRaw = raw;
    await _badgeService.syncFromStorage();
  }

  bool get _isParentMode {
    return FamilyAccessService(
      widget.optionRepository,
    ).loadState().isParentMode;
  }

  void _showParentReadOnlyMessage() {
    AppFeedback.showMessage(
      context,
      text: AppLocalizations.of(context)!.parentReadOnlyCalendarMessage,
    );
  }

  Map<DateTime, List<TrainingEntry>> _groupByDay(List<TrainingEntry> entries) {
    final Map<DateTime, List<TrainingEntry>> map = {};
    for (final entry in entries) {
      final key = _normalizeDay(entry.date);
      map.putIfAbsent(key, () => []).add(entry);
    }
    return map;
  }

  Map<DateTime, List<_TrainingPlan>> _groupPlansByDay(
    List<_TrainingPlan> plans,
  ) {
    final Map<DateTime, List<_TrainingPlan>> map = {};
    for (final plan in plans) {
      final key = _normalizeDay(plan.scheduledAt);
      map.putIfAbsent(key, () => []).add(plan);
    }
    return map;
  }

  Map<DateTime, MealEntry> _groupMealEntriesByDay(List<MealEntry> entries) {
    final Map<DateTime, MealEntry> map = {};
    for (final entry in entries) {
      map[_normalizeDay(entry.date)] = entry;
    }
    return map;
  }

  DateTime _normalizeDay(DateTime day) =>
      DateTime(day.year, day.month, day.day);

  int _lastPlanReminderMinutes() {
    return widget.optionRepository.getValue<int>(
          _lastPlanReminderStorageKey,
        ) ??
        10;
  }

  _TrainingPlan? _lastSavedPlanTemplate() {
    final raw =
        widget.optionRepository.getValue<String>(_lastPlanTemplateStorageKey);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return _TrainingPlan.fromMap(decoded.cast<String, dynamic>());
        }
      } catch (_) {
        // Fall back to the latest scheduled plan below.
      }
    }
    if (_plans.isEmpty) return null;
    return _plans.reduce(
      (latest, plan) =>
          plan.scheduledAt.isAfter(latest.scheduledAt) ? plan : latest,
    );
  }

  String _visiblePlanNote(_TrainingPlan plan, {required bool isKo}) {
    final note = plan.note.trim();
    if (note == (isKo ? '빠른 추가' : 'Quick add')) return '';
    if (note.toLowerCase() == 'quick add') return '';
    if (note == '빠른 추가') return '';
    return note;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _hasMatchForDay(List<TrainingEntry> entries) =>
      entries.any((entry) => entry.isMatch);

  bool _hasTrainingForDay(List<TrainingEntry> entries) =>
      entries.any((entry) => !entry.isMatch);

  Map<DateTime, String> _buildKoreanHolidayMap(DateTime from, DateTime to) {
    final result = <DateTime, String>{};
    for (var year = from.year; year <= to.year; year++) {
      for (final entry in _krFixedHolidayLabels.entries) {
        final parts = entry.key.split('-');
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        result[DateTime(year, month, day)] = entry.value;
      }
    }
    return result;
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
    await Navigator.of(context).push(
      AppPageRoute(
        builder: (_) =>
            ProfileScreen(optionRepository: widget.optionRepository),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openNews(BuildContext context) async {
    await Navigator.of(context).push(
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
    await Navigator.of(context).push(
      AppPageRoute(
        builder: (_) =>
            SkillQuizScreen(optionRepository: widget.optionRepository),
      ),
    );
    if (mounted) setState(() {});
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
}

class _CalendarStatusDayCell extends StatelessWidget {
  final int dayNumber;
  final bool hasTraining;
  final bool hasMeal;
  final bool hasMatch;
  final bool hasPlan;
  final bool isSelected;
  final bool isToday;
  final bool isHoliday;

  const _CalendarStatusDayCell({
    required this.dayNumber,
    required this.hasTraining,
    required this.hasMeal,
    required this.hasMatch,
    required this.hasPlan,
    required this.isSelected,
    required this.isToday,
    required this.isHoliday,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final todayColor = colorScheme.tertiary;
    final dayTextColor = isSelected
        ? colorScheme.primary
        : (isToday
            ? todayColor
            : (isHoliday ? Colors.red.shade500 : colorScheme.onSurface));
    final borderColor = isSelected
        ? colorScheme.primary
        : (isToday ? todayColor.withAlpha(210) : Colors.transparent);
    final backgroundColor = isSelected
        ? colorScheme.primary.withAlpha(28)
        : (isToday ? todayColor.withAlpha(24) : Colors.transparent);

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        width: 40,
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: AppRadius.small,
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$dayNumber',
              style: TextStyle(
                fontSize: _CalendarScreenState._calendarDayNumberFontSize,
                fontWeight: FontWeight.w800,
                color: dayTextColor,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CalendarMarkerStrip(
                  hasTraining: hasTraining,
                  hasMeal: hasMeal,
                  hasMatch: hasMatch,
                  hasPlan: hasPlan,
                  trainingColor: const Color(0xFF0FA968),
                  mealColor: const Color(0xFFB45309),
                  matchColor: const Color(0xFF2F80ED),
                  planColor: const Color(0xFFE3A008),
                  dayNumber: dayNumber,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarHeaderChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _CalendarHeaderChipButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const Size(64, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        backgroundColor: selected
            ? colorScheme.primary.withValues(alpha: 0.12)
            : colorScheme.surface.withValues(alpha: 0.68),
        side: BorderSide(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.65)
              : colorScheme.outlineVariant,
        ),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? colorScheme.primary : colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _CalendarMarkerStrip extends StatelessWidget {
  final bool hasTraining;
  final bool hasMeal;
  final bool hasMatch;
  final bool hasPlan;
  final Color trainingColor;
  final Color mealColor;
  final Color matchColor;
  final Color planColor;
  final int dayNumber;

  const _CalendarMarkerStrip({
    required this.hasTraining,
    required this.hasMeal,
    required this.hasMatch,
    required this.hasPlan,
    required this.trainingColor,
    required this.mealColor,
    required this.matchColor,
    required this.planColor,
    required this.dayNumber,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 4,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasTraining)
            _CalendarMarkerSegment(
              key: Key('calendar_day_training_marker_$dayNumber'),
              color: trainingColor,
            ),
          if (hasTraining && (hasMeal || hasMatch || hasPlan))
            const SizedBox(width: 3),
          if (hasMeal)
            _CalendarMarkerSegment(
              key: Key('calendar_day_meal_marker_$dayNumber'),
              color: mealColor,
            ),
          if (hasMeal && (hasMatch || hasPlan)) const SizedBox(width: 3),
          if (hasMatch)
            _CalendarMarkerSegment(
              key: Key('calendar_day_match_marker_$dayNumber'),
              color: matchColor,
            ),
          if (hasMatch && hasPlan) const SizedBox(width: 3),
          if (hasPlan)
            _CalendarMarkerSegment(
              key: Key('calendar_day_plan_marker_$dayNumber'),
              color: planColor,
            ),
        ],
      ),
    );
  }
}

class _CalendarMarkerSegment extends StatelessWidget {
  final Color color;

  const _CalendarMarkerSegment({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.full,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

TextStyle? _calendarTimelineTitleStyle(BuildContext context) {
  return Theme.of(
    context,
  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700);
}

TextStyle? _calendarTimelineSubtitleStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodyMedium;
}

bool _isSameNormalizedDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return a == b;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayTimeline extends StatelessWidget {
  final String? holidayName;
  final List<_TrainingPlan> dayPlans;
  final List<TrainingEntry> dayEntries;
  final Map<String, ParentTrainingFeedback> parentFeedbackByEntryId;
  final MealEntry? dayMealEntry;
  final bool isReadOnly;
  final ValueChanged<TrainingEntry> onEditEntry;
  final ValueChanged<MealEntry> onEditMealEntry;
  final ValueChanged<_TrainingPlan> onEditPlan;
  final ValueChanged<_TrainingPlan> onMovePlan;
  final Future<bool> Function(TrainingEntry) onDeleteEntry;
  final Future<bool> Function(MealEntry) onDeleteMealEntry;
  final Future<bool> Function(_TrainingPlan) onDeletePlan;
  final VoidCallback onListScrollUp;
  final VoidCallback onListReachedBottom;

  const _DayTimeline({
    this.holidayName,
    required this.dayPlans,
    required this.dayEntries,
    required this.parentFeedbackByEntryId,
    required this.dayMealEntry,
    required this.isReadOnly,
    required this.onEditEntry,
    required this.onEditMealEntry,
    required this.onEditPlan,
    required this.onMovePlan,
    required this.onDeleteEntry,
    required this.onDeleteMealEntry,
    required this.onDeletePlan,
    required this.onListScrollUp,
    required this.onListReachedBottom,
  });

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final sortedPlans = [...dayPlans]
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final sortedEntries = [...dayEntries]
      ..sort(TrainingEntry.compareByRecentCreated);
    final sortedMatchEntries =
        sortedEntries.where((entry) => entry.isMatch).toList(growable: false);
    final sortedTrainingEntries =
        sortedEntries.where((entry) => !entry.isMatch).toList(growable: false);
    if (sortedPlans.isEmpty &&
        sortedMatchEntries.isEmpty &&
        sortedTrainingEntries.isEmpty &&
        dayMealEntry == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if ((holidayName ?? '').isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: AppRadius.full,
                  border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
                ),
                child: Text(
                  isKo ? '공휴일 · $holidayName' : 'Holiday · $holidayName',
                  style: TextStyle(
                    color: Colors.red.shade500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(isKo ? '이 날짜의 기록이 없습니다.' : 'No records for this day.'),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final metrics = notification.metrics;

        if (notification is UserScrollNotification &&
            notification.direction == ScrollDirection.reverse) {
          onListScrollUp();
        }

        if (notification is ScrollUpdateNotification) {
          final delta = notification.scrollDelta ?? 0;
          final atTop = metrics.pixels <= 0.5;
          if (atTop && delta < -0.4) {
            onListReachedBottom();
          }
        }

        if (notification is OverscrollNotification) {
          final atTop = metrics.pixels <= 0.5;
          if (atTop && notification.overscroll < 0) {
            onListReachedBottom();
          }
        }
        return false;
      },
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          if ((holidayName ?? '').isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: AppRadius.small,
                border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
              ),
              child: Text(
                isKo ? '공휴일: $holidayName' : 'Holiday: $holidayName',
                style: TextStyle(
                  color: Colors.red.shade500,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (sortedPlans.isNotEmpty) ...[
            _SectionLabel(
              title: isKo ? '훈련 계획' : 'Training Plans',
              icon: Icons.alarm,
            ),
            const SizedBox(height: 8),
            ...sortedPlans.map(
              (plan) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: isReadOnly
                    ? _PlanTile(plan: plan, onTap: () => onEditPlan(plan))
                    : Dismissible(
                        key: ValueKey('plan-${plan.id}'),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => onDeletePlan(plan),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: AppRadius.control,
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                        ),
                        child: _PlanTile(
                          plan: plan,
                          onTap: () => onEditPlan(plan),
                          onMove: () => onMovePlan(plan),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (sortedMatchEntries.isNotEmpty) ...[
            _SectionLabel(
              title: isKo ? '시합' : 'Matches',
              icon: Icons.sports_soccer,
            ),
            const SizedBox(height: 8),
            ...sortedMatchEntries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: isReadOnly
                    ? _EntryTile(
                        entry: entry,
                        parentFeedbackMessage: _parentFeedbackFor(entry),
                        onTap: () => onEditEntry(entry),
                      )
                    : Dismissible(
                        key: ValueKey(
                          'match-entry-${entry.key ?? '${entry.date.millisecondsSinceEpoch}-${entry.type}-${entry.notes.hashCode}'}',
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => onDeleteEntry(entry),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: AppRadius.control,
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                        ),
                        child: _EntryTile(
                          entry: entry,
                          parentFeedbackMessage: _parentFeedbackFor(entry),
                          onTap: () => onEditEntry(entry),
                        ),
                      ),
              ),
            ),
            if (sortedTrainingEntries.isNotEmpty) const SizedBox(height: 12),
          ],
          if (sortedTrainingEntries.isNotEmpty) ...[
            _SectionLabel(
              title: isKo ? '훈련 일지' : 'Training Logs',
              icon: Icons.event_note,
            ),
            const SizedBox(height: 8),
            ...sortedTrainingEntries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: isReadOnly
                    ? _EntryTile(
                        entry: entry,
                        parentFeedbackMessage: _parentFeedbackFor(entry),
                        onTap: () => onEditEntry(entry),
                      )
                    : Dismissible(
                        key: ValueKey(
                          'entry-${entry.key ?? '${entry.date.millisecondsSinceEpoch}-${entry.type}-${entry.notes.hashCode}'}',
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => onDeleteEntry(entry),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: AppRadius.control,
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                        ),
                        child: _EntryTile(
                          entry: entry,
                          parentFeedbackMessage: _parentFeedbackFor(entry),
                          onTap: () => onEditEntry(entry),
                        ),
                      ),
              ),
            ),
          ],
          if (dayMealEntry != null) ...[
            if (sortedTrainingEntries.isNotEmpty ||
                sortedMatchEntries.isNotEmpty ||
                sortedPlans.isNotEmpty)
              const SizedBox(height: 12),
            _SectionLabel(
              title: AppLocalizations.of(context)!.mealLogScreenTitle,
              icon: Icons.rice_bowl_outlined,
            ),
            const SizedBox(height: 8),
            isReadOnly
                ? _MealEntryTile(
                    entry: dayMealEntry!,
                    onTap: () => onEditMealEntry(dayMealEntry!),
                  )
                : Dismissible(
                    key: ValueKey(
                      'meal-entry-${dayMealEntry!.date.millisecondsSinceEpoch}',
                    ),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) => onDeleteMealEntry(dayMealEntry!),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: AppRadius.control,
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                    child: _MealEntryTile(
                      entry: dayMealEntry!,
                      onTap: () => onEditMealEntry(dayMealEntry!),
                    ),
                  ),
          ],
        ],
      ),
    );
  }

  String _parentFeedbackFor(TrainingEntry entry) {
    return parentFeedbackByEntryId[ParentSharedFeedbackService.entryIdFor(
          entry,
        )]
            ?.message
            .trim() ??
        '';
  }
}

class _PlanTile extends StatelessWidget {
  final _TrainingPlan plan;
  final VoidCallback? onTap;
  final VoidCallback? onMove;

  const _PlanTile({required this.plan, this.onTap, this.onMove});

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final timeText = _formatPlanTime(plan.scheduledAt, isKo: isKo);
    final repeatText = _planScheduleText(plan, isKo: isKo);
    final visibleNote = _visiblePlanNoteForTile(plan);
    final reminderText = plan.alarmLoopEnabled
        ? (isKo ? '시작 시각에도 노티' : 'also notify at start time')
        : (isKo
            ? '${plan.reminderMinutesBefore}분 전 알림'
            : 'alert ${plan.reminderMinutesBefore} min before');
    final subtitleParts = <String>[
      if (repeatText.trim().isNotEmpty) repeatText,
      _formatDurationText(plan.durationMinutes, isKo: isKo),
      reminderText,
      if (visibleNote.isNotEmpty) visibleNote,
    ];
    return WatchCartCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap: onTap,
        onLongPress: onMove,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.14),
          child: const Icon(Icons.alarm, size: 16),
        ),
        title: Text(
          '$timeText · ${plan.category}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _calendarTimelineTitleStyle(context),
        ),
        subtitle: Text(
          subtitleParts.join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: _calendarTimelineSubtitleStyle(context),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

String _weekdayText(List<int> weekdays, {required bool isKo}) {
  const ko = ['월', '화', '수', '목', '금', '토', '일'];
  const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final labels = weekdays
      .where((d) => d >= 1 && d <= 7)
      .map((d) => isKo ? ko[d - 1] : en[d - 1])
      .toList(growable: false);
  if (labels.isEmpty) return '';
  return labels.join(isKo ? '·' : ', ');
}

String _visiblePlanNoteForTile(_TrainingPlan plan) {
  final note = plan.note.trim();
  if (note.isEmpty) return '';
  if (note == '빠른 추가' || note.toLowerCase() == 'quick add') return '';
  return note;
}

String _planScheduleText(_TrainingPlan plan, {required bool isKo}) {
  final weekdayText = _weekdayText(plan.repeatWeekdays, isKo: isKo);
  if (plan.seriesStartDate == null || plan.seriesEndDate == null) {
    return weekdayText;
  }
  final rangeText =
      '${DateFormat('M/d').format(plan.seriesStartDate!)}-${DateFormat('M/d').format(plan.seriesEndDate!)}';
  if (weekdayText.isEmpty) return rangeText;
  return '$weekdayText · $rangeText';
}

String _formatPlanTime(DateTime value, {required bool isKo}) {
  return isKo
      ? DateFormat('a h:mm', 'ko').format(value)
      : DateFormat('h:mm a', 'en').format(value);
}

class _EntryTile extends StatelessWidget {
  final TrainingEntry entry;
  final String parentFeedbackMessage;
  final VoidCallback? onTap;

  const _EntryTile({
    required this.entry,
    this.parentFeedbackMessage = '',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final hasParentFeedback = parentFeedbackMessage.trim().isNotEmpty;
    if (entry.isMatch) {
      return _buildMatchTile(
        context,
        l10n: l10n,
        isKo: isKo,
        hasParentFeedback: hasParentFeedback,
      );
    }

    final focusText = _entryFocusText(entry);
    final focusTextColor = Theme.of(context).colorScheme.primary;
    final titleParts = <String>[
      _trainingTitle(entry, l10n),
      _trainingProgramDurationText(entry, l10n: l10n),
    ].where((part) => part.trim().isNotEmpty).toList(growable: false);
    final trainingSummaryParts = [
      trainingEntryLessonLabel(entry, l10n),
      ...trainingEntryConditioningParts(entry, l10n, includeEmptyMessage: true),
      trainingEntryInjuryLabel(entry, l10n),
      trainingEntryLocationWeatherLabel(entry),
    ].where((part) => part.trim().isNotEmpty).toList(growable: false);
    return WatchCartCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Stack(
        children: [
          ListTile(
            contentPadding: EdgeInsets.fromLTRB(
              6,
              2,
              hasParentFeedback ? 34 : 6,
              2,
            ),
            leading: _StatusIcon(status: entry.status),
            title: Text(
              titleParts.join(' · '),
              style: _calendarTimelineTitleStyle(context),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trainingSummaryParts.isNotEmpty)
                  Text(
                    trainingSummaryParts.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _calendarTimelineSubtitleStyle(context),
                  ),
                if (focusText.isNotEmpty)
                  Text(
                    focusText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _calendarTimelineSubtitleStyle(
                      context,
                    )?.copyWith(color: focusTextColor),
                  ),
              ],
            ),
            trailing: onTap == null ? null : const Icon(Icons.chevron_right),
            onTap: onTap,
          ),
          if (hasParentFeedback)
            const Positioned(
              top: 2,
              right: 2,
              child: _CalendarParentFeedbackCornerMark(),
            ),
        ],
      ),
    );
  }

  Widget _buildMatchTile(
    BuildContext context, {
    required AppLocalizations l10n,
    required bool isKo,
    required bool hasParentFeedback,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final opponentText = entry.opponentTeam.trim().isEmpty
        ? ''
        : 'vs ${entry.opponentTeam.trim()}';
    final scoreText = _matchScoreText(entry);
    final detailParts = [
      ...matchCompetitionDetailParts(entry, l10n),
      if (entry.effectiveMatchLocation.trim().isNotEmpty)
        entry.effectiveMatchLocation.trim(),
    ].where((part) => part.trim().isNotEmpty).toList(growable: false);
    final personalParts = _matchPersonalRecordParts(
      entry,
      l10n: l10n,
      isKo: isKo,
    );
    final outcomeLabel = _matchOutcomeLabel(entry, isKo: isKo);

    return WatchCartCard(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                10,
                hasParentFeedback ? 36 : 12,
                10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _MatchResultIcon(entry: entry),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _matchInfoPill(
                                  context,
                                  matchKindLabel(entry, l10n),
                                  icon: Icons.sports_soccer,
                                  backgroundColor:
                                      scheme.surfaceContainerHighest,
                                  foregroundColor: scheme.onSurfaceVariant,
                                ),
                                _matchInfoPill(
                                  context,
                                  outcomeLabel,
                                  backgroundColor:
                                      _matchOutcomeColor(entry).withValues(
                                    alpha: 0.12,
                                  ),
                                  foregroundColor: _matchOutcomeColor(entry),
                                ),
                              ],
                            ),
                            if (opponentText.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                opponentText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _calendarTimelineTitleStyle(context),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (scoreText.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _matchScoreBadge(context, scoreText),
                      ],
                      if (onTap != null) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                  if (detailParts.isNotEmpty) ...[
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final part in detailParts)
                          _matchInfoPill(context, part),
                      ],
                    ),
                  ],
                  if (personalParts.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final part in personalParts)
                          _matchInfoPill(
                            context,
                            part,
                            backgroundColor:
                                scheme.primary.withValues(alpha: 0.08),
                            foregroundColor: scheme.primary,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (hasParentFeedback)
            const Positioned(
              top: 6,
              right: 6,
              child: _CalendarParentFeedbackCornerMark(),
            ),
        ],
      ),
    );
  }

  Widget _matchInfoPill(
    BuildContext context,
    String text, {
    IconData? icon,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final resolvedForeground = foregroundColor ?? scheme.onSurfaceVariant;
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor ?? scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: resolvedForeground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: resolvedForeground,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _matchScoreBadge(BuildContext context, String scoreText) {
    return Container(
      constraints: const BoxConstraints(minWidth: 54),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _matchOutcomeColor(entry).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _matchOutcomeColor(entry).withValues(alpha: 0.24),
        ),
      ),
      child: Text(
        scoreText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _matchOutcomeColor(entry),
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }

  String _matchScoreText(TrainingEntry entry) {
    if (entry.scoredGoals == null && entry.concededGoals == null) return '';
    return '${entry.scoredGoals ?? '-'}:${entry.concededGoals ?? '-'}';
  }

  Color _matchOutcomeColor(TrainingEntry entry) {
    final scored = entry.scoredGoals;
    final conceded = entry.concededGoals;
    if (scored != null && conceded != null && scored > conceded) {
      return const Color(0xFF0FA968);
    }
    if (scored != null && conceded != null && scored < conceded) {
      return const Color(0xFFEB5757);
    }
    return const Color(0xFF2F80ED);
  }

  String _entryFocusText(TrainingEntry entry) {
    if (!entry.isMatch && entry.opponentTeam.trim().isNotEmpty) {
      return entry.opponentTeam.trim();
    }
    if (entry.goalFocuses.isNotEmpty) return entry.goalFocuses.join(', ');
    if (entry.nextGoal.trim().isNotEmpty) return entry.nextGoal.trim();
    if (entry.goodPoints.trim().isNotEmpty) return entry.goodPoints.trim();
    if (entry.improvements.trim().isNotEmpty) return entry.improvements.trim();
    if (entry.goal.trim().isNotEmpty) return entry.goal.trim();
    final notesWithoutWeather = trainingEntryNotesWithoutWeather(entry);
    if (notesWithoutWeather.isNotEmpty) return notesWithoutWeather;
    return '';
  }

  String _trainingTitle(TrainingEntry entry, AppLocalizations l10n) {
    return trainingEntryPrimaryLabel(entry, l10n);
  }

  String _trainingProgramDurationText(
    TrainingEntry entry, {
    required AppLocalizations l10n,
  }) {
    return trainingEntryDurationLabel(entry, l10n);
  }

  String _matchOutcomeLabel(TrainingEntry entry, {required bool isKo}) {
    final scored = entry.scoredGoals;
    final conceded = entry.concededGoals;
    if (scored == null || conceded == null) {
      return isKo ? '결과 미입력' : 'Result unset';
    }
    if (scored > conceded) {
      return isKo ? '승' : 'Win';
    }
    if (scored < conceded) {
      return isKo ? '패' : 'Loss';
    }
    return isKo ? '무' : 'Draw';
  }

  List<String> _matchPersonalRecordParts(
    TrainingEntry entry, {
    required AppLocalizations l10n,
    required bool isKo,
  }) {
    final matchLabels = SportMatchLabels.forSport(
      l10n: l10n,
      sportId: entry.sportId,
    );
    final parts = matchLabels.personalRecordParts(entry);
    if (entry.minutesPlayed != null) {
      parts.add(
        isKo
            ? '출전 ${entry.minutesPlayed}분'
            : '${entry.minutesPlayed} min played',
      );
    }
    return parts;
  }
}

class _CalendarParentFeedbackCornerMark extends StatelessWidget {
  const _CalendarParentFeedbackCornerMark();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: l10n.parentFeedbackSectionTitle,
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.72),
          shape: BoxShape.circle,
          border: Border.all(color: scheme.primary.withValues(alpha: 0.28)),
        ),
        child: Icon(
          Icons.chat_bubble_outline_rounded,
          size: 15,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _MealEntryTile extends StatelessWidget {
  final MealEntry entry;
  final VoidCallback? onTap;

  const _MealEntryTile({required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return WatchCartCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFFB45309).withValues(alpha: 0.14),
          child: const Icon(Icons.rice_bowl_outlined, size: 16),
        ),
        title: Text(
          l10n.mealLogScreenTitle,
          style: _calendarTimelineTitleStyle(context),
        ),
        subtitle: Text(
          _mealSummary(l10n, entry),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: _calendarTimelineSubtitleStyle(context),
        ),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  String _mealSummary(AppLocalizations l10n, MealEntry entry) {
    final parts = <String>[
      _mealLine(
        l10n,
        l10n.mealBreakfast,
        entry.breakfastRiceBowls,
        entry.breakfastMenu,
        entry.breakfastDishId,
        entry.breakfastFoodIds,
      ),
      _mealLine(
        l10n,
        l10n.mealLunch,
        entry.lunchRiceBowls,
        entry.lunchMenu,
        entry.lunchDishId,
        entry.lunchFoodIds,
      ),
      _mealLine(
        l10n,
        l10n.mealDinner,
        entry.dinnerRiceBowls,
        entry.dinnerMenu,
        entry.dinnerDishId,
        entry.dinnerFoodIds,
      ),
    ];
    return parts.join(' · ');
  }

  String _mealLine(
    AppLocalizations l10n,
    String label,
    double bowls,
    String menu,
    String dishId,
    List<String> foodIds,
  ) {
    final trimmedMenu = menu.trim();
    final menuItems = <String>[
      if (dishId.trim().isNotEmpty) mealFoodLabel(l10n, dishId),
      for (final foodId in foodIds) mealFoodLabel(l10n, foodId),
      if (trimmedMenu.isNotEmpty) trimmedMenu,
    ].where((item) => item.trim().isNotEmpty).toList(growable: false);
    final menuText = _joinedMenuText(l10n, menuItems);
    if (bowls <= 0) {
      if (menuText.isNotEmpty) {
        return l10n.mealSummaryMenuOnly(label, menuText);
      }
      return l10n.mealCompactSkipped(label);
    }
    final count = bowls == bowls.truncateToDouble()
        ? bowls.toStringAsFixed(0)
        : bowls.toStringAsFixed(1);
    final rice = l10n.mealRiceBowlsValue(count);
    if (menuText.isEmpty) return l10n.mealSummaryRiceOnly(label, rice);
    return l10n.mealSummaryRiceWithMenu(label, rice, menuText);
  }

  String _joinedMenuText(AppLocalizations l10n, List<String> items) {
    return items.fold<String>('', (current, item) {
      if (current.isEmpty) return item;
      return l10n.mealSummaryMenuPair(current, item);
    });
  }
}

class _MatchResultIcon extends StatelessWidget {
  final TrainingEntry entry;

  const _MatchResultIcon({required this.entry});

  @override
  Widget build(BuildContext context) {
    final scored = entry.scoredGoals;
    final conceded = entry.concededGoals;
    IconData icon;
    Color bg;
    Color fg;

    if (scored != null && conceded != null && scored > conceded) {
      icon = Icons.emoji_events;
      bg = const Color(0x1A0FA968);
      fg = const Color(0xFF0FA968);
    } else if (scored != null && conceded != null && scored < conceded) {
      icon = Icons.sentiment_dissatisfied_outlined;
      bg = const Color(0x1AEB5757);
      fg = const Color(0xFFEB5757);
    } else {
      icon = Icons.handshake_outlined;
      bg = const Color(0x1A2F80ED);
      fg = const Color(0xFF2F80ED);
    }

    return CircleAvatar(
      radius: 16,
      backgroundColor: bg,
      child: Icon(icon, size: 17, color: fg),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionLabel({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final String status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final meta = trainingStatusVisual(status);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [meta.gradientStart, meta.gradientEnd],
        ),
        border: Border.all(color: Colors.white.withAlpha(170), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: meta.gradientEnd.withAlpha(80),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(meta.icon, size: 19, color: Colors.white),
          Positioned(
            right: 5,
            top: 5,
            child: Icon(
              meta.sparkleIcon,
              size: 10,
              color: Colors.white.withAlpha(230),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchSheetSection extends StatelessWidget {
  final int step;
  final IconData icon;
  final String title;
  final String? helper;
  final List<Widget> children;

  const _MatchSheetSection({
    required this.step,
    required this.icon,
    required this.title,
    required this.children,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    step.toString(),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(icon, size: 19, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            if (helper != null) ...[
              const SizedBox(height: 6),
              Text(
                helper!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _MatchCountStepper extends StatelessWidget {
  final String label;
  final int value;
  final bool hasValue;
  final bool enabled;
  final String increaseTooltip;
  final String decreaseTooltip;
  final VoidCallback onIncrement;
  final VoidCallback? onDecrement;

  const _MatchCountStepper({
    required this.label,
    required this.value,
    required this.hasValue,
    required this.enabled,
    required this.increaseTooltip,
    required this.decreaseTooltip,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final valueColor = hasValue ? scheme.primary : scheme.onSurfaceVariant;
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MatchCountIconButton(
                tooltip: decreaseTooltip,
                icon: Icons.remove_rounded,
                enabled: enabled && value > 0,
                onPressed: onDecrement,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: hasValue
                        ? scheme.primary.withValues(alpha: 0.08)
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value.toString(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: valueColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _MatchCountIconButton(
                tooltip: increaseTooltip,
                icon: Icons.add_rounded,
                enabled: enabled,
                onPressed: onIncrement,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MatchCountIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onPressed;

  const _MatchCountIconButton({
    required this.tooltip,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: 40,
      child: IconButton(
        tooltip: tooltip,
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 20),
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: enabled
              ? scheme.primary.withValues(alpha: 0.10)
              : scheme.surfaceContainerHighest,
          foregroundColor: enabled ? scheme.primary : scheme.onSurfaceVariant,
          disabledBackgroundColor: scheme.surfaceContainerHighest,
          disabledForegroundColor: scheme.onSurfaceVariant.withValues(
            alpha: 0.5,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _CalendarAutocompleteField extends StatelessWidget {
  final String initialValue;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final String labelText;
  final String hintText;
  final TextInputAction textInputAction;
  final int? maxLength;
  final bool enabled;

  const _CalendarAutocompleteField({
    super.key,
    required this.initialValue,
    required this.options,
    required this.onChanged,
    required this.labelText,
    required this.textInputAction,
    this.hintText = '',
    this.maxLength,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: initialValue),
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) {
          return options.take(6);
        }
        return options
            .where((option) => option.toLowerCase().contains(query))
            .take(6);
      },
      onSelected: onChanged,
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
        if (textEditingController.text != initialValue &&
            textEditingController.text.isEmpty) {
          textEditingController.value = TextEditingValue(
            text: initialValue,
            selection: TextSelection.collapsed(offset: initialValue.length),
          );
        }
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          enabled: enabled,
          textInputAction: textInputAction,
          maxLength: maxLength,
          onChanged: onChanged,
          onSubmitted: (_) {
            onFieldSubmitted();
            if (textInputAction == TextInputAction.done) {
              FocusScope.of(context).unfocus();
            }
          },
          decoration: _calendarInputDecorationWithDone(
            context,
            InputDecoration(
              labelText: labelText,
              hintText: hintText.isEmpty ? null : hintText,
            ),
            enabled: enabled,
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, displayedOptions) {
        final items = displayedOptions.toList(growable: false);
        if (items.isEmpty) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320, maxHeight: 220),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: theme.colorScheme.outlineVariant),
                itemBuilder: (context, index) {
                  final option = items[index];
                  return ListTile(
                    dense: true,
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

InputDecoration _calendarInputDecorationWithDone(
  BuildContext context,
  InputDecoration decoration, {
  bool enabled = true,
}) {
  return decoration;
}

String _formatDurationText(
  int minutes, {
  required bool isKo,
  String? fallback,
}) {
  if (minutes <= 0) return fallback ?? (isKo ? '미설정' : 'Not set');
  final hours = minutes ~/ 60;
  final remain = minutes % 60;
  if (hours <= 0) {
    return isKo ? '$remain분' : '${remain}m';
  }
  if (remain <= 0) {
    return isKo ? '$hours시간' : '${hours}h';
  }
  return isKo ? '$hours시간 $remain분' : '${hours}h ${remain}m';
}

class _PlanSheetResult {
  final List<_TrainingPlan> plans;
  final _PlanEditScope scope;

  const _PlanSheetResult({
    required this.plans,
    this.scope = _PlanEditScope.single,
  });
}

class _MatchCompetitionSheetResult {
  final String name;
  final List<String> teams;
  final String status;

  const _MatchCompetitionSheetResult({
    required this.name,
    required this.teams,
    this.status = MatchCompetitionRecord.statusActive,
  });
}

class _CompetitionMetric {
  final IconData icon;
  final String label;
  final String value;

  const _CompetitionMetric({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _TrainingPlan {
  final String id;
  final DateTime scheduledAt;
  final String category;
  final int durationMinutes;
  final int reminderMinutesBefore;
  final List<int> repeatWeekdays;
  final bool alarmLoopEnabled;
  final String location;
  final String note;
  final String? seriesId;
  final DateTime? seriesStartDate;
  final DateTime? seriesEndDate;

  const _TrainingPlan({
    required this.id,
    required this.scheduledAt,
    required this.category,
    required this.durationMinutes,
    required this.reminderMinutesBefore,
    required this.repeatWeekdays,
    required this.alarmLoopEnabled,
    required this.location,
    required this.note,
    this.seriesId,
    this.seriesStartDate,
    this.seriesEndDate,
  });

  _TrainingPlan copyWith({
    String? id,
    DateTime? scheduledAt,
    String? category,
    int? durationMinutes,
    int? reminderMinutesBefore,
    List<int>? repeatWeekdays,
    bool? alarmLoopEnabled,
    String? location,
    String? note,
    String? seriesId,
    DateTime? seriesStartDate,
    DateTime? seriesEndDate,
  }) {
    return _TrainingPlan(
      id: id ?? this.id,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      category: category ?? this.category,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
      alarmLoopEnabled: alarmLoopEnabled ?? this.alarmLoopEnabled,
      location: location ?? this.location,
      note: note ?? this.note,
      seriesId: seriesId ?? this.seriesId,
      seriesStartDate: seriesStartDate ?? this.seriesStartDate,
      seriesEndDate: seriesEndDate ?? this.seriesEndDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scheduledAt': scheduledAt.toIso8601String(),
      'category': category,
      'durationMinutes': durationMinutes,
      'reminderMinutesBefore': reminderMinutesBefore,
      'repeatWeekdays': repeatWeekdays,
      'alarmLoopEnabled': alarmLoopEnabled,
      'location': location,
      'note': note,
      'seriesId': seriesId,
      'seriesStartDate': seriesStartDate?.toIso8601String(),
      'seriesEndDate': seriesEndDate?.toIso8601String(),
    };
  }

  factory _TrainingPlan.fromMap(Map<String, dynamic> map) {
    final rawDate = map['scheduledAt']?.toString() ?? '';
    return _TrainingPlan(
      id: map['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      scheduledAt: DateTime.tryParse(rawDate) ?? DateTime.now(),
      category: map['category']?.toString() ?? '',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 60,
      reminderMinutesBefore:
          (map['reminderMinutesBefore'] as num?)?.toInt() ?? 30,
      repeatWeekdays: ((map['repeatWeekdays'] as List?) ?? const [])
          .map((e) => (e as num?)?.toInt() ?? 0)
          .where((v) => v >= DateTime.monday && v <= DateTime.sunday)
          .toSet()
          .toList(growable: false)
        ..sort(),
      alarmLoopEnabled: (map['alarmLoopEnabled'] as bool?) ?? true,
      location: map['location']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
      seriesId: map['seriesId']?.toString(),
      seriesStartDate: DateTime.tryParse(
        map['seriesStartDate']?.toString() ?? '',
      ),
      seriesEndDate: DateTime.tryParse(map['seriesEndDate']?.toString() ?? ''),
    );
  }
}
