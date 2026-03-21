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
      _pending = pending..sort((a, b) => a.id.compareTo(b.id));
      _planRows = planRows;
      _lastTrainingLogAt = lastTrainingLogAt;
      _loading = false;
    });
  }

  List<_PlanAlarmRow> _loadPlanRows() {
    final raw = widget.optionRepository.getValue<String>(
      TrainingPlanReminderService.plansStorageKey,
    );
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final rows =
          decoded
              .whereType<Map>()
              .map((e) => _PlanAlarmRow.fromMap(e.cast<String, dynamic>()))
              .where((e) => e.scheduledAt.isAfter(DateTime.now()))
              .toList(growable: false)
            ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return rows;
    } catch (_) {
      return const [];
    }
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
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _mutedNow
                                    ? null
                                    : () => _muteForHours(8),
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
                    (item) => Card(
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
                            Text(DateFormat('HH:mm').format(item.scheduledAt)),
                          ],
                        ),
                        subtitle: Text(
                          DateFormat(
                            isKo ? 'M/d(E)' : 'EEE, M/d',
                          ).format(item.scheduledAt),
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
}

class _PlanAlarmRow {
  final DateTime scheduledAt;
  final String category;

  const _PlanAlarmRow({required this.scheduledAt, required this.category});

  factory _PlanAlarmRow.fromMap(Map<String, dynamic> map) {
    return _PlanAlarmRow(
      scheduledAt:
          DateTime.tryParse(map['scheduledAt']?.toString() ?? '') ??
          DateTime.now(),
      category: map['category']?.toString() ?? '',
    );
  }
}
