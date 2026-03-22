import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

import '../../application/settings_service.dart';
import '../../application/training_plan_reminder_service.dart';
import '../../domain/repositories/option_repository.dart';

class NotificationCenterScreen extends StatefulWidget {
  final OptionRepository optionRepository;
  final SettingsService settingsService;

  const NotificationCenterScreen({
    super.key,
    required this.optionRepository,
    required this.settingsService,
  });

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  late final TrainingPlanReminderService _reminderService;
  bool _permissionGranted = true;
  bool _loading = true;
  bool _mutedNow = false;
  List<PendingNotificationRequest> _pending = const [];
  List<_PlanAlarmRow> _planRows = const [];
  String? _lastTrainingLogAt;

  @override
  void initState() {
    super.initState();
    _reminderService = TrainingPlanReminderService(
      widget.optionRepository,
      widget.settingsService,
    );
    _load();
  }

  Future<void> _load() async {
    try {
      await _reminderService.markAllRemindersRead();
      final permission = await _reminderService.hasNotificationPermission();
      final muted = await _reminderService.isAlarmMutedNow();
      final pending = await _reminderService.pendingReminders();
      final planRows = _loadPlanRows();
      final lastTrainingLogAt = widget.optionRepository.getValue<String>(
        TrainingPlanReminderService.lastTrainingLogAtKey,
      );
      if (!mounted) return;
      setState(() {
        _permissionGranted = permission;
        _mutedNow = muted;
        _pending = [...pending]..sort((a, b) => a.id.compareTo(b.id));
        _planRows = planRows;
        _lastTrainingLogAt = lastTrainingLogAt;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pending = const [];
        _planRows = _loadPlanRows();
        _loading = false;
      });
    }
  }

  List<_PlanAlarmRow> _loadPlanRows() {
    final raw = widget.optionRepository.getValue<String>(
      TrainingPlanReminderService.plansStorageKey,
    );
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final rows = decoded
          .whereType<Map>()
          .map((e) => _PlanAlarmRow.fromMap(e.cast<String, dynamic>()))
          .where((e) => e.scheduledAt.isAfter(DateTime.now()))
          .toList(growable: false)
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      final dismissed = _reminderService.dismissedMessageKeysSync().toSet();
      return rows
          .where((row) => !dismissed.contains(row.messageKey))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _deleteMessage(_PlanAlarmRow row) async {
    await _reminderService.dismissMessageKey(row.messageKey);
    if (!mounted) return;
    setState(() {
      _planRows = _planRows
          .where((item) => item.messageKey != row.messageKey)
          .toList(growable: false);
    });
  }

  Future<void> _muteForHours(int hours) async {
    await _reminderService.muteAlarmsUntil(
      DateTime.now().add(Duration(hours: hours)),
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _resumeAlerts() async {
    await _reminderService.clearAlarmMute();
    await _reminderService.syncSettingsDrivenReminders();
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    return Scaffold(
      appBar: AppBar(
        title: Text(isKo ? '알림' : 'Notifications'),
        actions: [
          IconButton(
            onPressed: _openNotificationSettingsSheet,
            icon: const Icon(Icons.tune),
            tooltip: isKo ? '알림 설정' : 'Alert settings',
          ),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: isKo ? '새로고침' : 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Card(
                  child: ListTile(
                    leading: Icon(
                      _permissionGranted
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_off_outlined,
                    ),
                    title: Text(
                      _permissionGranted
                          ? (isKo
                              ? '알림 권한 허용됨'
                              : 'Notification permission granted')
                          : (isKo
                              ? '알림 권한 꺼짐'
                              : 'Notification permission is off'),
                    ),
                    subtitle: Text(
                      _permissionGranted
                          ? (isKo
                              ? '훈련 계획 알림을 받을 수 있어요.'
                              : 'You can receive training plan reminders.')
                          : (isKo
                              ? '설정 > 알림에서 권한을 켜 주세요.'
                              : 'Enable permission in Settings > Notifications.'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _mutedNow
                              ? (isKo ? '알림 일시중지됨' : 'Alerts are paused')
                              : (isKo ? '반복 알림 제어' : 'Repeating alert control'),
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed:
                                    _mutedNow ? null : () => _muteForHours(8),
                                icon: const Icon(
                                  Icons.notifications_off_outlined,
                                ),
                                label: Text(isKo ? '8시간 끄기' : 'Mute 8h'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _mutedNow ? _resumeAlerts : null,
                                icon: const Icon(
                                  Icons.notifications_active_outlined,
                                ),
                                label: Text(isKo ? '다시 켜기' : 'Resume'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.bedtime_outlined),
                    title: Text(
                      widget.settingsService.wakeAlarmEnabled
                          ? (isKo ? '새벽 기상 알람 사용 중' : 'Wake alarm is on')
                          : (isKo ? '새벽 기상 알람 꺼짐' : 'Wake alarm is off'),
                    ),
                    subtitle: Text(
                      widget.settingsService.wakeAlarmEnabled
                          ? (isKo
                              ? '${widget.settingsService.wakeAlarmTime.format(context)} · 주 ${widget.settingsService.wakeAlarmWeekdays.length}일 · ${widget.settingsService.wakeAlarmRepeatCount}회 반복'
                              : '${widget.settingsService.wakeAlarmTime.format(context)} · ${widget.settingsService.wakeAlarmWeekdays.length} days/week · ${widget.settingsService.wakeAlarmRepeatCount} repeats')
                          : (isKo
                              ? '설정에서 켜면 새벽 훈련용 반복 알람을 예약합니다.'
                              : 'Enable it in Settings to schedule repeated morning alarms.'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.edit_calendar_outlined),
                    title: Text(
                      widget.settingsService.inactivityAlertEnabled
                          ? (isKo
                              ? '기록 공백 리마인드 사용 중'
                              : 'Inactivity reminder is on')
                          : (isKo
                              ? '기록 공백 리마인드 꺼짐'
                              : 'Inactivity reminder is off'),
                    ),
                    subtitle: Text(_buildInactivitySubtitle(isKo)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isKo
                      ? '훈련 알림 ${_planRows.length}개'
                      : '${_planRows.length} training alerts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                if (_planRows.isEmpty)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.inbox_outlined),
                      title: Text(
                        isKo ? '예약된 알림이 없어요.' : 'No scheduled alerts.',
                      ),
                      subtitle: Text(
                        isKo
                            ? '훈련 계획을 추가하면 알림이 여기에 표시돼요.'
                            : 'Add a training plan to see reminders here.',
                      ),
                    ),
                  )
                else
                  ..._planRows.map(
                    (item) => Dismissible(
                      key: ValueKey('alarm-msg-${item.messageKey}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      onDismissed: (_) => _deleteMessage(item),
                      child: Card(
                        child: ListTile(
                          leading: const Icon(Icons.alarm_outlined),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.category.isEmpty
                                      ? (isKo ? '훈련 계획' : 'Training plan')
                                      : item.category,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                  DateFormat('HH:mm').format(item.scheduledAt)),
                            ],
                          ),
                          subtitle: Text(
                            '${DateFormat(isKo ? 'M/d(E)' : 'EEE, M/d').format(item.scheduledAt)}'
                            '${item.scheduleSummary.isEmpty ? '' : '\n${item.scheduleSummary}'}',
                          ),
                          trailing: IconButton(
                            tooltip: isKo ? '삭제' : 'Delete',
                            onPressed: () => _deleteMessage(item),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_pending.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    isKo
                        ? '시스템 예약 알림 ${_pending.length}개'
                        : '${_pending.length} system-scheduled alerts',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
    );
  }

  String _buildInactivitySubtitle(bool isKo) {
    final raw = _lastTrainingLogAt;
    final parsed = raw == null ? null : DateTime.tryParse(raw);
    final base = widget.settingsService.inactivityAlertEnabled
        ? (isKo
            ? '${widget.settingsService.inactivityAlertDays}일 동안 기록이 없으면 ${widget.settingsService.reminderTime.format(context)}에 알림'
            : 'Alert at ${widget.settingsService.reminderTime.format(context)} after ${widget.settingsService.inactivityAlertDays} inactive days')
        : (isKo
            ? '설정에서 켜면 훈련 기록 공백을 알려줍니다.'
            : 'Enable it in Settings to get nudges after quiet periods.');
    if (parsed == null) return base;
    final formatted = DateFormat(
      isKo ? 'M/d HH:mm' : 'MMM d HH:mm',
    ).format(parsed);
    return isKo ? '$base\n마지막 기록: $formatted' : '$base\nLast log: $formatted';
  }

  Future<void> _syncNotificationSettings() async {
    await _reminderService.syncSettingsDrivenReminders();
    if (!mounted) return;
    await _load();
  }

  Future<void> _openNotificationSettingsSheet() async {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> refreshSheet() async {
              await _syncNotificationSettings();
              if (mounted) {
                setSheetState(() {});
              }
            }

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
                        isKo ? '알림 설정' : 'Alert settings',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(isKo ? '전체 알림' : 'All notifications'),
                        value: widget.settingsService.reminderEnabled,
                        onChanged: (value) async {
                          await widget.settingsService.setReminderEnabled(
                            value,
                          );
                          await refreshSheet();
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          isKo ? '훈련 계획 진동 알림' : 'Training plan vibration',
                        ),
                        value: widget.settingsService.reminderVibrationEnabled,
                        onChanged: widget.settingsService.reminderEnabled
                            ? (value) async {
                                await widget.settingsService
                                    .setReminderVibrationEnabled(value);
                                await refreshSheet();
                              }
                            : null,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(isKo ? '경험치 알림' : 'XP alerts'),
                        subtitle: Text(
                          isKo
                              ? '경험치를 얻으면 바로 알림을 보냅니다.'
                              : 'Show an alert whenever XP is earned.',
                        ),
                        value: widget.settingsService.xpAlertEnabled,
                        onChanged: widget.settingsService.reminderEnabled
                            ? (value) async {
                                await widget.settingsService.setXpAlertEnabled(
                                  value,
                                );
                                await refreshSheet();
                              }
                            : null,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          isKo ? '레벨 업 알림' : 'Level-up notifications',
                        ),
                        value: widget.settingsService.levelUpAlertEnabled,
                        onChanged: widget.settingsService.reminderEnabled
                            ? (value) async {
                                await widget.settingsService
                                    .setLevelUpAlertEnabled(value);
                                await refreshSheet();
                              }
                            : null,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          isKo ? '기록 공백 리마인드' : 'Inactivity reminders',
                        ),
                        value: widget.settingsService.inactivityAlertEnabled,
                        onChanged: widget.settingsService.reminderEnabled
                            ? (value) async {
                                await widget.settingsService
                                    .setInactivityAlertEnabled(value);
                                await refreshSheet();
                              }
                            : null,
                      ),
                      if (widget.settingsService.inactivityAlertEnabled)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            isKo ? '기록 리마인드 시간' : 'Training reminder time',
                          ),
                          subtitle: Text(
                            '${widget.settingsService.reminderTime.format(context)} · '
                            '${isKo ? '${widget.settingsService.inactivityAlertDays}일 기준' : '${widget.settingsService.inactivityAlertDays} day threshold'}',
                          ),
                          trailing: OutlinedButton(
                            onPressed: widget.settingsService.reminderEnabled
                                ? () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime:
                                          widget.settingsService.reminderTime,
                                    );
                                    if (picked == null) return;
                                    await widget.settingsService
                                        .setReminderTime(picked);
                                    await refreshSheet();
                                  }
                                : null,
                            child: Text(isKo ? '시간 변경' : 'Change'),
                          ),
                        ),
                      if (widget.settingsService.inactivityAlertEnabled)
                        DropdownButtonFormField<int>(
                          initialValue:
                              widget.settingsService.inactivityAlertDays,
                          decoration: InputDecoration(
                            labelText:
                                isKo ? '기록 공백 기준' : 'Inactivity threshold',
                          ),
                          items: const [1, 2, 3, 5, 7, 10, 14]
                              .map(
                                (value) => DropdownMenuItem<int>(
                                  value: value,
                                  child: Text(
                                    isKo
                                        ? '$value일'
                                        : '$value day${value == 1 ? '' : 's'}',
                                  ),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: widget.settingsService.reminderEnabled
                              ? (value) async {
                                  if (value == null) return;
                                  await widget.settingsService
                                      .setInactivityAlertDays(value);
                                  await refreshSheet();
                                }
                              : null,
                        ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(isKo ? '새벽 기상 알람' : 'Wake alarm'),
                        value: widget.settingsService.wakeAlarmEnabled,
                        onChanged: widget.settingsService.reminderEnabled
                            ? (value) async {
                                await widget.settingsService
                                    .setWakeAlarmEnabled(value);
                                await refreshSheet();
                              }
                            : null,
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
    if (!mounted) return;
    await _load();
  }
}

class _PlanAlarmRow {
  final String id;
  final DateTime scheduledAt;
  final String category;
  final String scheduleSummary;
  final String messageKey;

  const _PlanAlarmRow({
    required this.id,
    required this.scheduledAt,
    required this.category,
    required this.scheduleSummary,
    required this.messageKey,
  });

  factory _PlanAlarmRow.fromMap(Map<String, dynamic> map) {
    final weekdays = ((map['repeatWeekdays'] as List?) ?? const [])
        .map((e) => (e as num?)?.toInt() ?? 0)
        .where((value) => value >= DateTime.monday && value <= DateTime.sunday)
        .toList(growable: false);
    final seriesStart = DateTime.tryParse(
      map['seriesStartDate']?.toString() ?? '',
    );
    final seriesEnd = DateTime.tryParse(map['seriesEndDate']?.toString() ?? '');
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    final weekdayText = weekdays.isEmpty
        ? ''
        : weekdays.map((value) => labels[value - 1]).join('·');
    final rangeText = (seriesStart == null || seriesEnd == null)
        ? ''
        : '${DateFormat('M/d').format(seriesStart)}-${DateFormat('M/d').format(seriesEnd)}';
    return _PlanAlarmRow(
      id: map['id']?.toString() ?? '',
      scheduledAt: DateTime.tryParse(map['scheduledAt']?.toString() ?? '') ??
          DateTime.now(),
      category: map['category']?.toString() ?? '',
      scheduleSummary: [
        weekdayText,
        rangeText,
      ].where((value) => value.trim().isNotEmpty).join(' · '),
      messageKey:
          '${map['id']?.toString() ?? ''}|${map['scheduledAt']?.toString() ?? ''}',
    );
  }
}
