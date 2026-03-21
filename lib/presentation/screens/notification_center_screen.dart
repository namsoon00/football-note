import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
    final permission = await _reminderService.hasNotificationPermission();
    final muted = await _reminderService.isAlarmMutedNow();
    final pending = await _reminderService.pendingReminders();
    if (!mounted) return;
    setState(() {
      _permissionGranted = permission;
      _mutedNow = muted;
      _pending = pending..sort((a, b) => a.id.compareTo(b.id));
      _loading = false;
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
    await _reminderService.syncFromStorage();
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
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed:
                                    _mutedNow ? null : () => _muteForHours(8),
                                icon: const Icon(
                                    Icons.notifications_off_outlined),
                                label: Text(isKo ? '8시간 끄기' : 'Mute 8h'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _mutedNow ? _resumeAlerts : null,
                                icon: const Icon(
                                    Icons.notifications_active_outlined),
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
                Text(
                  isKo
                      ? '예약된 알림 ${_pending.length}개'
                      : '${_pending.length} scheduled alerts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                if (_pending.isEmpty)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.inbox_outlined),
                      title:
                          Text(isKo ? '예약된 알림이 없어요.' : 'No scheduled alerts.'),
                      subtitle: Text(
                        isKo
                            ? '훈련 계획을 추가하면 알림이 여기에 표시돼요.'
                            : 'Add a training plan to see reminders here.',
                      ),
                    ),
                  )
                else
                  ..._pending.map(
                    (item) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.alarm_outlined),
                        title: Text(item.title?.trim().isNotEmpty == true
                            ? item.title!
                            : (isKo ? '훈련 계획 알림' : 'Training plan reminder')),
                        subtitle: Text(
                          item.body?.trim().isNotEmpty == true
                              ? item.body!
                              : (isKo ? '알림 내용 없음' : 'No alert body'),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
