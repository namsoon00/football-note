import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../application/backup_service.dart';
import '../../application/locale_service.dart';
import '../../application/settings_service.dart';
import '../../application/training_plan_reminder_service.dart';
import '../../application/training_service.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/repositories/option_repository.dart';
import '../widgets/app_background.dart';
import '../widgets/app_drawer.dart';
import '../widgets/status_style.dart';
import '../widgets/watch_cart/constants.dart';
import '../widgets/watch_cart/main_app_bar.dart';
import '../widgets/watch_cart/watch_cart_card.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class CalendarScreen extends StatefulWidget {
  final TrainingService trainingService;
  final LocaleService localeService;
  final OptionRepository optionRepository;
  final SettingsService settingsService;
  final BackupService? driveBackupService;
  final ValueChanged<TrainingEntry> onEdit;
  final VoidCallback? onCreate;

  const CalendarScreen({
    super.key,
    required this.trainingService,
    required this.localeService,
    required this.optionRepository,
    required this.settingsService,
    this.driveBackupService,
    required this.onEdit,
    this.onCreate,
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
    unawaited(_syncPlanReminders());
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
        currentIndex: 1,
      ),
      body: AppBackground(
        child: SafeArea(
          child: StreamBuilder<List<TrainingEntry>>(
            stream: widget.trainingService.watchEntries(),
            builder: (context, snapshot) {
              final isKo = Localizations.localeOf(context).languageCode == 'ko';
              final entries = snapshot.data ?? [];
              final entryMap = _groupByDay(entries);
              final planMap = _groupPlansByDay(_plans);
              final holidayMap = isKo
                  ? _buildKoreanHolidayMap(DateTime(2022), DateTime(2032))
                  : const <DateTime, String>{};
              final selected = _normalizeDay(_selectedDay ?? _focusedDay);
              final dayEntries = entryMap[selected] ?? const <TrainingEntry>[];
              final dayPlans = planMap[selected] ?? const <_TrainingPlan>[];
              final selectedHolidayName = holidayMap[selected];

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Builder(
                      builder: (context) => WatchCartAppBar(
                        onMenuTap: () => Scaffold.of(context).openDrawer(),
                        profilePhotoSource: widget.optionRepository
                                .getValue<String>('profile_photo_url') ??
                            '',
                        onProfileTap: () => _openProfile(context),
                        onSettingsTap: () => _openSettings(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.calendar,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => _openPlanSheet(
                            day: _selectedDay ?? _focusedDay,
                          ),
                          icon: const Icon(Icons.add_alarm_outlined, size: 20),
                          label: Text(
                            Localizations.localeOf(context).languageCode == 'ko'
                                ? '훈련 계획 추가'
                                : 'Add Training Plan',
                          ),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            minimumSize: const Size(1, 40),
                            maximumSize: const Size(210, 40),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: _calendarExpanded
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: WatchCartCard(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: TableCalendar<TrainingEntry>(
                                  locale: Localizations.localeOf(context)
                                      .toString(),
                                  focusedDay: _focusedDay,
                                  firstDay: DateTime(2022),
                                  lastDay: DateTime(2032),
                                  sixWeekMonthsEnforced: false,
                                  rowHeight: 35,
                                  daysOfWeekHeight: 18,
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
                                  },
                                  eventLoader: (day) {
                                    final key = _normalizeDay(day);
                                    return entryMap[key] ??
                                        const <TrainingEntry>[];
                                  },
                                  holidayPredicate: (day) =>
                                      isKo &&
                                      holidayMap
                                          .containsKey(_normalizeDay(day)),
                                  calendarBuilders: CalendarBuilders(
                                    holidayBuilder: isKo
                                        ? (context, day, focusedDay) {
                                            return Center(
                                              child: Text(
                                                '${day.day}',
                                                style: TextStyle(
                                                  color: Colors.red.shade500,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            );
                                          }
                                        : null,
                                  ),
                                  calendarStyle: CalendarStyle(
                                    outsideDaysVisible: false,
                                    markerDecoration: const BoxDecoration(
                                      color: WatchCartConstants.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    holidayTextStyle: TextStyle(
                                      color: Colors.red.shade500,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  headerStyle: const HeaderStyle(
                                    formatButtonVisible: false,
                                    titleCentered: true,
                                    titleTextStyle: TextStyle(
                                      fontSize: 14,
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
                    child: GestureDetector(
                      onTap: () => _setCalendarExpanded(!_calendarExpanded),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _calendarExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            Localizations.localeOf(context).languageCode == 'ko'
                                ? (_calendarExpanded ? '캘린더 접기' : '캘린더 펼치기')
                                : (_calendarExpanded
                                    ? 'Collapse calendar'
                                    : 'Expand calendar'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _DayTimeline(
                      holidayName: selectedHolidayName,
                      dayPlans: dayPlans,
                      dayEntries: dayEntries,
                      onEditEntry: widget.onEdit,
                      onEditPlan: (plan) => _openPlanSheet(
                          day: plan.scheduledAt, editingPlan: plan),
                      onDeletePlan: _deletePlan,
                      onAddPlan: () => _openPlanSheet(day: selected),
                      onListScrollUp: () {
                        if (_calendarExpanded) {
                          _setCalendarExpanded(false);
                        }
                      },
                      onListReachedBottom: () {
                        if (!_calendarExpanded) {
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
    );
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
    final categories = widget.optionRepository.getOptions(
      'programs',
      [l10n.defaultProgram1, l10n.defaultProgram2, l10n.defaultProgram3],
    );
    var planDay = editingPlan?.scheduledAt ?? day;
    var category = editingPlan?.category ?? categories.first;
    var time = TimeOfDay(
      hour: (editingPlan?.scheduledAt.hour ?? 18),
      minute: (editingPlan?.scheduledAt.minute ?? 0),
    );
    var duration = editingPlan?.durationMinutes ?? 60;
    var reminderBefore = editingPlan?.reminderMinutesBefore ?? 30;
    final noteController = TextEditingController(text: editingPlan?.note ?? '');
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
                              if (picked == null) return;
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
                            label:
                                Text(DateFormat('yyyy-MM-dd').format(planDay)),
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
                              if (picked == null) return;
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
                            decoration: InputDecoration(
                              labelText: isKo ? '훈련 시간' : 'Duration',
                            ),
                            items: const [30, 45, 60, 90, 120]
                                .map(
                                  (value) => DropdownMenuItem<int>(
                                    value: value,
                                    child: Text(_formatDurationText(
                                      value,
                                      isKo: isKo,
                                    )),
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
                      decoration: InputDecoration(
                        labelText: isKo ? '사전 알림' : 'Reminder',
                      ),
                      items: const [10, 20, 30, 60]
                          .map(
                            (value) => DropdownMenuItem<int>(
                              value: value,
                              child: Text(
                                isKo ? '$value분 전' : '$value min before',
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
                    TextField(
                      controller: noteController,
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
                            note: noteController.text.trim(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check),
                      label: Text(isKo ? '저장' : 'Save'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    noteController.dispose();
    if (saved == null) return;
    setState(() {
      if (editingPlan == null) {
        _plans = [..._plans, saved];
      } else {
        _plans = _plans
            .map((plan) => plan.id == saved.id ? saved : plan)
            .toList(growable: false);
      }
      _plans = [..._plans]..sort(
          (a, b) => a.scheduledAt.compareTo(b.scheduledAt),
        );
    });
    await _savePlans();
    await _syncPlanReminders();
  }

  Future<void> _deletePlan(String id) async {
    setState(() {
      _plans = _plans.where((plan) => plan.id != id).toList(growable: false);
    });
    await _savePlans();
    await _syncPlanReminders();
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
              (rawMap) => _TrainingPlan.fromMap(rawMap.cast<String, dynamic>()))
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
      List<_TrainingPlan> plans) {
    final Map<DateTime, List<_TrainingPlan>> map = {};
    for (final plan in plans) {
      final key = _normalizeDay(plan.scheduledAt);
      map.putIfAbsent(key, () => []).add(plan);
    }
    return map;
  }

  DateTime _normalizeDay(DateTime day) =>
      DateTime(day.year, day.month, day.day);

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
        builder: (_) => ProfileScreen(
          optionRepository: widget.optionRepository,
        ),
      ),
    );
    if (mounted) setState(() {});
  }
}

class _DayTimeline extends StatelessWidget {
  final String? holidayName;
  final List<_TrainingPlan> dayPlans;
  final List<TrainingEntry> dayEntries;
  final ValueChanged<TrainingEntry> onEditEntry;
  final ValueChanged<_TrainingPlan> onEditPlan;
  final ValueChanged<String> onDeletePlan;
  final VoidCallback onAddPlan;
  final VoidCallback onListScrollUp;
  final VoidCallback onListReachedBottom;

  const _DayTimeline({
    this.holidayName,
    required this.dayPlans,
    required this.dayEntries,
    required this.onEditEntry,
    required this.onEditPlan,
    required this.onDeletePlan,
    required this.onAddPlan,
    required this.onListScrollUp,
    required this.onListReachedBottom,
  });

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final sortedPlans = [...dayPlans]
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final sortedEntries = [...dayEntries]
      ..sort((a, b) => b.date.compareTo(a.date));
    if (sortedPlans.isEmpty && sortedEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if ((holidayName ?? '').isNotEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            Text(
              isKo ? '이 날짜의 기록이 없습니다.' : 'No records for this day.',
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onAddPlan,
              icon: const Icon(Icons.add_alarm_outlined),
              label: Text(isKo ? '훈련 계획 추가' : 'Add training plan'),
            ),
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
            ...sortedPlans.map((plan) => _PlanTile(
                  plan: plan,
                  onEdit: () => onEditPlan(plan),
                  onDelete: () => onDeletePlan(plan.id),
                )),
            const SizedBox(height: 12),
          ],
          if (sortedEntries.isNotEmpty) ...[
            _SectionLabel(
              title: isKo ? '훈련 일지' : 'Training Logs',
              icon: Icons.event_note,
            ),
            const SizedBox(height: 8),
            ...sortedEntries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _EntryTile(
                  entry: entry,
                  onTap: () => onEditEntry(entry),
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PlanTile({
    required this.plan,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final timeText = DateFormat('HH:mm').format(plan.scheduledAt);
    return WatchCartCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
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
        trailing: Wrap(
          spacing: 2,
          children: [
            IconButton(
              tooltip: isKo ? '계획 수정' : 'Edit plan',
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: isKo ? '계획 삭제' : 'Delete plan',
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final TrainingEntry entry;
  final VoidCallback onTap;

  const _EntryTile({
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final durationText = _formatDurationText(
      entry.durationMinutes,
      isKo: isKo,
      fallback: l10n.durationNotSet,
    );
    return WatchCartCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        leading: _StatusIcon(status: entry.status),
        title: Text('${entry.type} · $durationText'),
        subtitle: Text(
          '${l10n.intensity} ${entry.intensity} · ${l10n.condition} ${entry.mood}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
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
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
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
