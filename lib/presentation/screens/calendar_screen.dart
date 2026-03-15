import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../application/backup_service.dart';
import '../../application/localized_option_defaults.dart';
import '../../application/locale_service.dart';
import '../../application/player_level_service.dart';
import '../../application/settings_service.dart';
import '../../application/training_plan_reminder_service.dart';
import '../../application/training_service.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/repositories/option_repository.dart';
import '../widgets/app_background.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_feedback.dart';
import '../widgets/status_style.dart';
import '../widgets/watch_cart/main_app_bar.dart';
import '../widgets/watch_cart/watch_cart_card.dart';
import '../widgets/tab_screen_title.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'coach_lesson_screen.dart';
import 'news_screen.dart';
import 'space_speed_game_screen.dart';

enum _CalendarCreateAction { entry, plan, match }

enum CalendarQuickCreateAction { plan, match }

class CalendarScreen extends StatefulWidget {
  final TrainingService trainingService;
  final LocaleService localeService;
  final OptionRepository optionRepository;
  final SettingsService settingsService;
  final BackupService? driveBackupService;
  final ValueChanged<TrainingEntry> onEdit;
  final VoidCallback? onCreate;
  final ValueChanged<DateTime>? onSelectedDayChanged;
  final CalendarQuickCreateAction? quickCreateAction;
  final VoidCallback? onQuickCreateHandled;

  const CalendarScreen({
    super.key,
    required this.trainingService,
    required this.localeService,
    required this.optionRepository,
    required this.settingsService,
    this.driveBackupService,
    required this.onEdit,
    this.onCreate,
    this.onSelectedDayChanged,
    this.quickCreateAction,
    this.onQuickCreateHandled,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const _plansStorageKey = 'training_plans_v1';
  static const _calendarExpandedKey = 'calendar_expanded_v1';
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
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _calendarExpanded = true;

  late final TrainingPlanReminderService _reminderService;
  List<_TrainingPlan> _plans = const <_TrainingPlan>[];
  bool _quickCreateHandled = false;

  @override
  void initState() {
    super.initState();
    _reminderService = TrainingPlanReminderService(
      widget.optionRepository,
      widget.settingsService,
    );
    _plans = _loadPlans();
    _calendarExpanded =
        widget.optionRepository.getValue<bool>(_calendarExpandedKey) ?? true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSelectedDayChanged?.call(
        _normalizeDay(_selectedDay ?? _focusedDay),
      );
      unawaited(_maybeRunQuickCreateAction());
    });
    unawaited(_syncPlanReminders());
  }

  @override
  void didUpdateWidget(covariant CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quickCreateAction != oldWidget.quickCreateAction) {
      _quickCreateHandled = false;
    }
    if (widget.quickCreateAction == null) return;
    if (widget.quickCreateAction == oldWidget.quickCreateAction) return;
    unawaited(_maybeRunQuickCreateAction());
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
        final entries = await widget.trainingService.allEntries();
        if (!mounted) return;
        await _openMatchSheet(day: selectedDay, entries: entries);
        break;
    }
    widget.onQuickCreateHandled?.call();
  }

  Future<void> _setCalendarExpanded(bool expanded) async {
    if (_calendarExpanded == expanded) return;
    setState(() => _calendarExpanded = expanded);
    await widget.optionRepository.setValue(_calendarExpandedKey, expanded);
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
        currentIndex: 2,
      ),
      body: AppBackground(
        child: SafeArea(
          child: StreamBuilder<List<TrainingEntry>>(
            stream: widget.trainingService.watchEntries(),
            builder: (context, snapshot) {
              final isKo = Localizations.localeOf(context).languageCode == 'ko';
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final entries = snapshot.data ?? [];
              final entryMap = _groupByDay(entries);
              final planMap = _groupPlansByDay(_plans);
              final holidayMap = isKo
                  ? _buildKoreanHolidayMap(DateTime(2022), DateTime(2032))
                  : const <DateTime, String>{};
              final selected = _normalizeDay(_selectedDay ?? _focusedDay);
              final dayEntries = entryMap[selected] ?? const <TrainingEntry>[];
              final dayPlans = planMap[selected] ?? const <_TrainingPlan>[];
              final hasDaySchedule =
                  dayEntries.isNotEmpty || dayPlans.isNotEmpty;
              final isCalendarExpanded =
                  hasDaySchedule ? _calendarExpanded : true;
              final selectedHolidayName = holidayMap[selected];

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Builder(
                      builder: (context) => WatchCartAppBar(
                        onMenuTap: () => Scaffold.of(context).openDrawer(),
                        onNewsTap: () => _openNews(context),
                        onGameTap: () => _openGame(context),
                        profilePhotoSource:
                            widget.optionRepository.getValue<String>(
                                  'profile_photo_url',
                                ) ??
                                '',
                        onProfileTap: () => _openProfile(context),
                        onSettingsTap: () => _openSettings(context),
                        onCoachTap: () => _openCoach(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TabScreenTitle(
                      title: AppLocalizations.of(context)!.calendar,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              minimumSize: const Size(1, 40),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                            onPressed: () {
                              final today = _normalizeDay(DateTime.now());
                              setState(() {
                                _selectedDay = today;
                                _focusedDay = today;
                              });
                              widget.onSelectedDayChanged?.call(today);
                            },
                            icon: const Icon(Icons.today_outlined, size: 18),
                            label: Text(
                              Localizations.localeOf(context).languageCode ==
                                      'ko'
                                  ? '오늘'
                                  : 'Today',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: isCalendarExpanded
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: WatchCartCard(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: TableCalendar<TrainingEntry>(
                                  locale: Localizations.localeOf(
                                    context,
                                  ).toString(),
                                  focusedDay: _focusedDay,
                                  firstDay: DateTime(2022),
                                  lastDay: DateTime(2032),
                                  sixWeekMonthsEnforced: false,
                                  rowHeight: 44,
                                  daysOfWeekHeight: 20,
                                  calendarFormat: _calendarFormat,
                                  onPageChanged: (focusedDay) {
                                    _focusedDay = focusedDay;
                                  },
                                  selectedDayPredicate: (day) =>
                                      isSameDay(day, _selectedDay),
                                  onDaySelected: (selectedDay, focusedDay) {
                                    setState(() {
                                      _selectedDay = selectedDay;
                                      _focusedDay = focusedDay;
                                    });
                                    widget.onSelectedDayChanged?.call(
                                      _normalizeDay(selectedDay),
                                    );
                                  },
                                  eventLoader: (day) {
                                    final key = _normalizeDay(day);
                                    return entryMap[key] ??
                                        const <TrainingEntry>[];
                                  },
                                  holidayPredicate: (day) =>
                                      isKo &&
                                      holidayMap.containsKey(
                                        _normalizeDay(day),
                                      ),
                                  calendarBuilders: CalendarBuilders(
                                    defaultBuilder: (context, day, focusedDay) {
                                      final key = _normalizeDay(day);
                                      return _CalendarStatusDayCell(
                                        dayNumber: day.day,
                                        status: _bestStatusForDay(
                                          entryMap[key] ??
                                              const <TrainingEntry>[],
                                        ),
                                        isSelected: isSameDay(
                                          day,
                                          _selectedDay,
                                        ),
                                        isToday: isSameDay(day, DateTime.now()),
                                        isHoliday:
                                            isKo && holidayMap.containsKey(key),
                                      );
                                    },
                                    todayBuilder: (context, day, focusedDay) {
                                      final key = _normalizeDay(day);
                                      return _CalendarStatusDayCell(
                                        dayNumber: day.day,
                                        status: _bestStatusForDay(
                                          entryMap[key] ??
                                              const <TrainingEntry>[],
                                        ),
                                        isSelected: isSameDay(
                                          day,
                                          _selectedDay,
                                        ),
                                        isToday: true,
                                        isHoliday:
                                            isKo && holidayMap.containsKey(key),
                                      );
                                    },
                                    selectedBuilder:
                                        (context, day, focusedDay) {
                                      final key = _normalizeDay(day);
                                      return _CalendarStatusDayCell(
                                        dayNumber: day.day,
                                        status: _bestStatusForDay(
                                          entryMap[key] ??
                                              const <TrainingEntry>[],
                                        ),
                                        isSelected: true,
                                        isToday: isSameDay(
                                          day,
                                          DateTime.now(),
                                        ),
                                        isHoliday:
                                            isKo && holidayMap.containsKey(key),
                                      );
                                    },
                                    holidayBuilder: (context, day, focusedDay) {
                                      final key = _normalizeDay(day);
                                      return _CalendarStatusDayCell(
                                        dayNumber: day.day,
                                        status: _bestStatusForDay(
                                          entryMap[key] ??
                                              const <TrainingEntry>[],
                                        ),
                                        isSelected: isSameDay(
                                          day,
                                          _selectedDay,
                                        ),
                                        isToday: isSameDay(day, DateTime.now()),
                                        isHoliday: true,
                                      );
                                    },
                                  ),
                                  calendarStyle: CalendarStyle(
                                    outsideDaysVisible: false,
                                    markerSize: 6,
                                    markerDecoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.92)
                                          : Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.88),
                                      shape: BoxShape.circle,
                                    ),
                                    defaultTextStyle: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                    weekendTextStyle: TextStyle(
                                      fontSize: 15,
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                    ),
                                    selectedTextStyle: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                    ),
                                    holidayTextStyle: TextStyle(
                                      fontSize: 15,
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
                                  ),
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
                            ? () => _setCalendarExpanded(!isCalendarExpanded)
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
                                Localizations.localeOf(context).languageCode ==
                                        'ko'
                                    ? (isCalendarExpanded
                                        ? '캘린더 접기'
                                        : '캘린더 펼치기')
                                    : (isCalendarExpanded
                                        ? 'Collapse calendar'
                                        : 'Expand calendar'),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _DayTimeline(
                      holidayName: selectedHolidayName,
                      dayPlans: dayPlans,
                      dayEntries: dayEntries,
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
                      onEditPlan: (plan) => _openPlanSheet(
                        day: plan.scheduledAt,
                        editingPlan: plan,
                      ),
                      onDeleteEntry: _confirmDeleteEntry,
                      onDeletePlan: _confirmDeletePlan,
                      onListScrollUp: () {
                        if (hasDaySchedule && isCalendarExpanded) {
                          _setCalendarExpanded(false);
                        }
                      },
                      onListReachedBottom: () {
                        if (hasDaySchedule && !isCalendarExpanded) {
                          _setCalendarExpanded(true);
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: widget.onCreate == null
          ? null
          : FloatingActionButton(
              heroTag: 'calendar_fab',
              onPressed: () async {
                final entries = await widget.trainingService.allEntries();
                if (!mounted) return;
                await _showCreateActionSheet(entries);
              },
              child: const Icon(Icons.add),
            ),
    );
  }

  Future<void> _showCreateActionSheet(List<TrainingEntry> entries) async {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final selectedDay = _selectedDay ?? _focusedDay;
    final action = await showModalBottomSheet<_CalendarCreateAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.note_add_outlined),
              title: Text(isKo ? '훈련 노트' : 'Training note'),
              onTap: () =>
                  Navigator.of(context).pop(_CalendarCreateAction.entry),
            ),
            ListTile(
              leading: const Icon(Icons.add_alarm_outlined),
              title: Text(isKo ? '훈련 계획' : 'Training Plan'),
              onTap: () =>
                  Navigator.of(context).pop(_CalendarCreateAction.plan),
            ),
            ListTile(
              leading: const Icon(Icons.sports_soccer_outlined),
              title: Text(isKo ? '시합' : 'Match'),
              onTap: () =>
                  Navigator.of(context).pop(_CalendarCreateAction.match),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _CalendarCreateAction.entry:
        widget.onCreate?.call();
        break;
      case _CalendarCreateAction.plan:
        await _openPlanSheet(day: selectedDay);
        break;
      case _CalendarCreateAction.match:
        await _openMatchSheet(day: selectedDay, entries: entries);
        break;
    }
  }

  Future<void> _syncPlanReminders() async {
    await _reminderService.syncFromPlans(
      _plans.map((plan) => plan.toMap()).toList(growable: false),
    );
  }

  Future<void> _openPlanSheet({
    required DateTime day,
    _TrainingPlan? editingPlan,
  }) async {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final l10n = AppLocalizations.of(context)!;
    final rawCategories = widget.optionRepository.getOptions('programs', [
      l10n.defaultProgram1,
      l10n.defaultProgram2,
      l10n.defaultProgram3,
    ]);
    final categories = LocalizedOptionDefaults.normalizeOptions(
      key: 'programs',
      stored: rawCategories,
      localizedDefaults: [
        l10n.defaultProgram1,
        l10n.defaultProgram2,
        l10n.defaultProgram3,
      ],
    );
    if (!_sameStringList(rawCategories, categories)) {
      widget.optionRepository.saveOptions('programs', categories);
    }
    var planDay = editingPlan?.scheduledAt ?? day;
    var category = editingPlan?.category ?? categories.first;
    var time = TimeOfDay(
      hour: (editingPlan?.scheduledAt.hour ?? 18),
      minute: (editingPlan?.scheduledAt.minute ?? 0),
    );
    var duration = editingPlan?.durationMinutes ?? 60;
    var reminderBefore = editingPlan?.reminderMinutesBefore ?? 30;
    var noteText = editingPlan?.note ?? '';
    final saved = await showModalBottomSheet<_TrainingPlan>(
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
                        editingPlan == null
                            ? (isKo ? '훈련 계획 추가' : 'Add Training Plan')
                            : (isKo ? '훈련 계획 수정' : 'Edit Training Plan'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: InputDecoration(
                          labelText: isKo ? '훈련 항목' : 'Category',
                        ),
                        items: categories
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
                                if (picked == null || !context.mounted) return;
                                setSheetState(() {
                                  planDay = DateTime(
                                    picked.year,
                                    picked.month,
                                    picked.day,
                                    planDay.hour,
                                    planDay.minute,
                                  );
                                });
                              },
                              icon: const Icon(Icons.calendar_today_outlined),
                              label: Text(
                                DateFormat('yyyy-MM-dd').format(planDay),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: time,
                                );
                                if (picked == null || !context.mounted) return;
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
                                        _formatDurationText(value, isKo: isKo),
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
                                  isKo ? '$value분 전' : '$value min before',
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
                      TextFormField(
                        initialValue: noteText,
                        onChanged: (value) => noteText = value,
                        maxLength: 60,
                        decoration: InputDecoration(
                          labelText: isKo ? '메모(선택)' : 'Note (optional)',
                        ),
                      ),
                      const SizedBox(height: 6),
                      FilledButton.icon(
                        onPressed: () {
                          final scheduledAt = DateTime(
                            planDay.year,
                            planDay.month,
                            planDay.day,
                            time.hour,
                            time.minute,
                          );
                          Navigator.of(context).pop(
                            _TrainingPlan(
                              id: editingPlan?.id ??
                                  DateTime.now()
                                      .microsecondsSinceEpoch
                                      .toString(),
                              scheduledAt: scheduledAt,
                              category: category,
                              durationMinutes: duration,
                              reminderMinutesBefore: reminderBefore,
                              note: noteText.trim(),
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
    if (saved == null) return;
    setState(() {
      if (editingPlan == null) {
        _plans = [..._plans, saved];
      } else {
        _plans = _plans
            .map((plan) => plan.id == saved.id ? saved : plan)
            .toList(growable: false);
      }
      _plans = [..._plans]
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    });
    await _savePlans();
    await _syncPlanReminders();
    if (editingPlan == null) {
      final award = await PlayerLevelService(
        widget.optionRepository,
      ).awardForPlanCreated(planId: saved.id);
      if (!mounted || award.gainedXp <= 0) return;
      AppFeedback.showSuccess(
        context,
        text: isKo
            ? '훈련 계획 저장 +${award.gainedXp} XP'
            : 'Plan saved +${award.gainedXp} XP',
      );
    }
  }

  Future<void> _openMatchSheet({
    required DateTime day,
    TrainingEntry? editingEntry,
    required List<TrainingEntry> entries,
  }) async {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final l10n = AppLocalizations.of(context)!;
    final initialDay = editingEntry?.date ?? day;
    var matchDay = DateTime(initialDay.year, initialDay.month, initialDay.day);
    var opponent = editingEntry?.opponentTeam ?? editingEntry?.club ?? '';
    var location = editingEntry?.effectiveMatchLocation ?? '';
    final opponentOptions = _matchOpponentOptions(entries);
    final locationOptions = _matchLocationOptions(entries);
    var ourScoreText = editingEntry?.scoredGoals?.toString() ?? '';
    var opponentScoreText = editingEntry?.concededGoals?.toString() ?? '';
    var playerGoalsText = editingEntry?.playerGoals?.toString() ?? '';
    var playerAssistsText = editingEntry?.playerAssists?.toString() ?? '';
    var minutesPlayedText = editingEntry?.minutesPlayed?.toString() ?? '';
    var memoText = editingEntry?.notes ?? '';
    final saved = await showModalBottomSheet<TrainingEntry>(
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
                        editingEntry == null
                            ? (isKo ? '시합 등록' : 'Add Match')
                            : (isKo ? '시합 수정' : 'Edit Match'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: matchDay,
                            firstDate: DateTime(2022),
                            lastDate: DateTime(2032),
                          );
                          if (picked == null || !context.mounted) return;
                          setSheetState(() {
                            matchDay = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                            );
                          });
                        },
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(DateFormat('yyyy-MM-dd').format(matchDay)),
                      ),
                      const SizedBox(height: 8),
                      _MatchAutocompleteField(
                        initialValue: opponent,
                        options: opponentOptions,
                        onChanged: (value) => opponent = value,
                        textInputAction: TextInputAction.next,
                        labelText: isKo ? '상대 팀' : 'Opponent team',
                        hintText: isKo ? '예) 수원 U15' : 'e.g. Suwon U15',
                      ),
                      const SizedBox(height: 8),
                      _MatchAutocompleteField(
                        initialValue: location,
                        options: locationOptions,
                        onChanged: (value) => location = value,
                        textInputAction: TextInputAction.next,
                        labelText: l10n.location,
                        hintText: isKo ? '예) 메인 구장' : 'e.g. Main stadium',
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: ourScoreText,
                              onChanged: (value) => ourScoreText = value,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: isKo ? '우리 점수' : 'Our score',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: opponentScoreText,
                              onChanged: (value) => opponentScoreText = value,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: isKo ? '상대 점수' : 'Opponent score',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: playerGoalsText,
                              onChanged: (value) => playerGoalsText = value,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: isKo ? '골' : 'Goals',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: playerAssistsText,
                              onChanged: (value) => playerAssistsText = value,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: isKo ? '어시스트' : 'Assists',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: minutesPlayedText,
                        onChanged: (value) => minutesPlayedText = value,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(
                          labelText: isKo ? '출전 시간(분)' : 'Minutes played',
                          hintText: isKo ? '예) 70' : 'e.g. 70',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: memoText,
                        onChanged: (value) => memoText = value,
                        maxLength: 60,
                        decoration: InputDecoration(
                          labelText: isKo ? '메모(선택)' : 'Note (optional)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () {
                          final trimmedOpponent = opponent.trim();
                          if (trimmedOpponent.isEmpty) return;
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
                              club: trimmedOpponent,
                              opponentTeam: trimmedOpponent,
                              status: editingEntry?.status ?? 'normal',
                              goodPoints: editingEntry?.goodPoints ?? '',
                              improvements: editingEntry?.improvements ?? '',
                              nextGoal: editingEntry?.nextGoal ?? '',
                              goalFocuses:
                                  editingEntry?.goalFocuses ?? const [],
                              createdAt: editingEntry?.createdAt,
                              scoredGoals: _parseSheetInt(
                                ourScoreText,
                              ),
                              concededGoals: _parseSheetInt(
                                opponentScoreText,
                              ),
                              playerGoals: _parseSheetInt(
                                playerGoalsText,
                              ),
                              playerAssists: _parseSheetInt(
                                playerAssistsText,
                              ),
                              minutesPlayed: _parseSheetInt(
                                minutesPlayedText,
                              ),
                              matchLocation: location.trim(),
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
    if (saved == null) return;
    final trimmedMatchLocation = saved.effectiveMatchLocation.trim();
    if (trimmedMatchLocation.isNotEmpty) {
      await _storeMatchLocation(trimmedMatchLocation);
    }
    if (editingEntry?.key is int) {
      await widget.trainingService.update(editingEntry!.key as int, saved);
      return;
    }
    await widget.trainingService.add(saved);
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

  List<String> _matchLocationOptions(List<TrainingEntry> entries) {
    final storedLocations = widget.optionRepository.getOptions(
      'match_locations',
      [],
    );
    return _dedupeAutocompleteValues([
      ...storedLocations,
      ...entries
          .where((entry) => entry.isMatch)
          .map((entry) => entry.effectiveMatchLocation),
    ]);
  }

  Future<void> _storeMatchLocation(String location) async {
    final existing = widget.optionRepository.getOptions('match_locations', []);
    final updated = _dedupeAutocompleteValues([...existing, location]);
    await widget.optionRepository.saveOptions('match_locations', updated);
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
    setState(() {
      _plans = _plans.where((plan) => plan.id != id).toList(growable: false);
    });
    await _savePlans();
    await _syncPlanReminders();
  }

  Future<void> _confirmDeletePlan(_TrainingPlan plan) async {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isKo ? '계획 삭제' : 'Delete plan'),
        content: Text(
          isKo
              ? '이 훈련 계획을 정말 삭제할까요?'
              : 'Are you sure you want to delete this training plan?',
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
      await _deletePlan(plan.id);
    }
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

  Future<bool> _confirmDeleteEntry(TrainingEntry entry) async {
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
      await widget.trainingService.delete(entry);
      return true;
    }
    return false;
  }

  List<_TrainingPlan> _loadPlans() {
    final raw = widget.optionRepository.getValue<String>(_plansStorageKey);
    if (raw == null || raw.isEmpty) return const <_TrainingPlan>[];
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
    final raw = jsonEncode(_plans.map((plan) => plan.toMap()).toList());
    await widget.optionRepository.setValue(_plansStorageKey, raw);
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

  DateTime _normalizeDay(DateTime day) =>
      DateTime(day.year, day.month, day.day);

  String? _bestStatusForDay(List<TrainingEntry> entries) {
    if (entries.isEmpty) return null;
    String? bestStatus;
    var bestScore = -1;
    for (final entry in entries) {
      final score = _statusPriority(entry.status);
      if (score > bestScore) {
        bestScore = score;
        bestStatus = entry.status;
      }
    }
    return bestStatus;
  }

  int _statusPriority(String status) {
    switch (status) {
      case 'great':
        return 5;
      case 'good':
        return 4;
      case 'normal':
        return 3;
      case 'recovery':
        return 2;
      case 'tough':
        return 1;
      default:
        return 0;
    }
  }

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
      MaterialPageRoute(
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
      MaterialPageRoute(
        builder: (_) =>
            ProfileScreen(optionRepository: widget.optionRepository),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openCoach(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CoachLessonScreen(
          optionRepository: widget.optionRepository,
          trainingService: widget.trainingService,
          localeService: widget.localeService,
          settingsService: widget.settingsService,
          driveBackupService: widget.driveBackupService,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openNews(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
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
    if (mounted) setState(() {});
  }

  Future<void> _openGame(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SpaceSpeedGameScreen(
          trainingService: widget.trainingService,
          localeService: widget.localeService,
          optionRepository: widget.optionRepository,
          settingsService: widget.settingsService,
          driveBackupService: widget.driveBackupService,
        ),
      ),
    );
    if (mounted) setState(() {});
  }
}

class _CalendarStatusDayCell extends StatelessWidget {
  final int dayNumber;
  final String? status;
  final bool isSelected;
  final bool isToday;
  final bool isHoliday;

  const _CalendarStatusDayCell({
    required this.dayNumber,
    required this.status,
    required this.isSelected,
    required this.isToday,
    required this.isHoliday,
  });

  @override
  Widget build(BuildContext context) {
    final hasTraining = status != null;
    final colorScheme = Theme.of(context).colorScheme;
    final dayTextColor = isSelected
        ? colorScheme.primary
        : (isHoliday ? Colors.red.shade500 : colorScheme.onSurface);
    final borderColor = isSelected
        ? colorScheme.primary
        : (isHoliday
            ? Colors.red.shade400.withAlpha(170)
            : (isToday
                ? colorScheme.primary.withAlpha(150)
                : Colors.transparent));
    final backgroundColor = isSelected
        ? colorScheme.primary.withAlpha(28)
        : (isToday ? colorScheme.primary.withAlpha(14) : Colors.transparent);

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        width: 40,
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: hasTraining
            ? Center(child: _MiniStatusIcon(status: status!))
            : Center(
                child: Text(
                  '$dayNumber',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: dayTextColor,
                    height: 1.0,
                  ),
                ),
              ),
      ),
    );
  }
}

class _MiniStatusIcon extends StatelessWidget {
  final String status;

  const _MiniStatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final meta = trainingStatusVisual(status);
    return SizedBox(
      width: 22,
      height: 22,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [meta.gradientStart, meta.gradientEnd],
          ),
        ),
        child: Icon(meta.icon, size: 14, color: Colors.white),
      ),
    );
  }
}

class _DayTimeline extends StatelessWidget {
  final String? holidayName;
  final List<_TrainingPlan> dayPlans;
  final List<TrainingEntry> dayEntries;
  final ValueChanged<TrainingEntry> onEditEntry;
  final ValueChanged<_TrainingPlan> onEditPlan;
  final Future<bool> Function(TrainingEntry) onDeleteEntry;
  final ValueChanged<_TrainingPlan> onDeletePlan;
  final VoidCallback onListScrollUp;
  final VoidCallback onListReachedBottom;

  const _DayTimeline({
    this.holidayName,
    required this.dayPlans,
    required this.dayEntries,
    required this.onEditEntry,
    required this.onEditPlan,
    required this.onDeleteEntry,
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
        sortedTrainingEntries.isEmpty) {
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
                  borderRadius: BorderRadius.circular(999),
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
                borderRadius: BorderRadius.circular(12),
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
              (plan) => _PlanTile(
                plan: plan,
                onTap: () => onEditPlan(plan),
                onDelete: () => onDeletePlan(plan),
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
                child: Dismissible(
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
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  child: _EntryTile(
                    entry: entry,
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
                child: Dismissible(
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
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  child: _EntryTile(
                    entry: entry,
                    onTap: () => onEditEntry(entry),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  final _TrainingPlan plan;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PlanTile({
    required this.plan,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final timeText = DateFormat('HH:mm').format(plan.scheduledAt);
    return WatchCartCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap: onTap,
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
        ),
        subtitle: Text(
          '${_formatDurationText(plan.durationMinutes, isKo: isKo)} · '
          '${isKo ? '${plan.reminderMinutesBefore}분 전 알림' : 'alert ${plan.reminderMinutesBefore} min before'}'
          '${plan.note.isEmpty ? '' : ' · ${plan.note}'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          tooltip: isKo ? '계획 삭제' : 'Delete plan',
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final TrainingEntry entry;
  final VoidCallback onTap;

  const _EntryTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final focusText = _entryFocusText(entry);
    final focusTextColor = Theme.of(context).colorScheme.primary;
    final titleParts = entry.isMatch
        ? _matchTitleParts(entry, isKo: isKo)
        : <String>[
            entry.type.trim().isNotEmpty ? entry.type.trim() : l10n.program,
            _formatDurationText(
              entry.durationMinutes,
              isKo: isKo,
              fallback: l10n.durationNotSet,
            ),
            entry.location.trim().isNotEmpty ? entry.location.trim() : '-',
          ];
    return WatchCartCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        leading: entry.isMatch
            ? _MatchResultIcon(entry: entry)
            : _StatusIcon(status: entry.status),
        title: Text(titleParts.join(' · ')),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entry.isMatch) ...[
              if (_matchPersonalRecord(entry, isKo: isKo).isNotEmpty)
                Text(
                  _matchPersonalRecord(entry, isKo: isKo),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ] else
              Text(
                '${l10n.intensity} ${entry.intensity} · ${l10n.condition} ${entry.mood}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (focusText.isNotEmpty)
              Text(
                focusText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: focusTextColor),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
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
    if (entry.feedback.trim().isNotEmpty) return entry.feedback.trim();
    if (entry.fortuneComment.trim().isNotEmpty) {
      return entry.fortuneComment.trim();
    }
    if (entry.notes.trim().isNotEmpty) return entry.notes.trim();
    return '';
  }

  List<String> _matchTitleParts(TrainingEntry entry, {required bool isKo}) {
    final parts = <String>[];
    parts.add(_matchOutcomeLabel(entry, isKo: isKo));
    if (entry.opponentTeam.trim().isNotEmpty) {
      parts.add('vs ${entry.opponentTeam.trim()}');
    }
    final matchLocation = entry.effectiveMatchLocation.trim();
    if (matchLocation.isNotEmpty) {
      parts.add(matchLocation);
    }
    if (entry.scoredGoals != null || entry.concededGoals != null) {
      parts.add(
        isKo
            ? '결과 ${entry.scoredGoals ?? '-'}:${entry.concededGoals ?? '-'}'
            : 'Result ${entry.scoredGoals ?? '-'}:${entry.concededGoals ?? '-'}',
      );
    }
    return parts;
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

  String _matchPersonalRecord(TrainingEntry entry, {required bool isKo}) {
    final parts = <String>[];
    if (entry.playerGoals != null) {
      parts.add(isKo ? '골 ${entry.playerGoals}' : 'Goals ${entry.playerGoals}');
    }
    if (entry.playerAssists != null) {
      parts.add(
        isKo ? '어시스트 ${entry.playerAssists}' : 'Assists ${entry.playerAssists}',
      );
    }
    if (entry.minutesPlayed != null) {
      parts.add(
        isKo
            ? '출전 ${entry.minutesPlayed}분'
            : '${entry.minutesPlayed} min played',
      );
    }
    return parts.join(' · ');
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

class _MatchAutocompleteField extends StatelessWidget {
  final String initialValue;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final String labelText;
  final String hintText;
  final TextInputAction textInputAction;

  const _MatchAutocompleteField({
    required this.initialValue,
    required this.options,
    required this.onChanged,
    required this.labelText,
    required this.hintText,
    required this.textInputAction,
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
          textInputAction: textInputAction,
          onChanged: onChanged,
          onSubmitted: (_) => onFieldSubmitted(),
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
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

class _TrainingPlan {
  final String id;
  final DateTime scheduledAt;
  final String category;
  final int durationMinutes;
  final int reminderMinutesBefore;
  final String note;

  const _TrainingPlan({
    required this.id,
    required this.scheduledAt,
    required this.category,
    required this.durationMinutes,
    required this.reminderMinutesBefore,
    required this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scheduledAt': scheduledAt.toIso8601String(),
      'category': category,
      'durationMinutes': durationMinutes,
      'reminderMinutesBefore': reminderMinutesBefore,
      'note': note,
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
      note: map['note']?.toString() ?? '',
    );
  }
}
