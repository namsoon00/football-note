import 'dart:convert';
import 'dart:async';

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
  static const _seenPlanKeysStorageKey = 'notification_seen_plan_keys_v1';
  static const _seenXpIdsStorageKey = 'notification_seen_xp_ids_v1';
  static const _showInactivitySectionKey =
      'notification_show_inactivity_section_v1';
  static const _showXpSectionKey = 'notification_show_xp_section_v1';
  static const _showPlanSectionKey = 'notification_show_plan_section_v1';
  static const _showSystemSectionKey = 'notification_show_system_section_v1';

  late final TrainingPlanReminderService _reminderService;
  bool _permissionGranted = true;
  bool _loading = true;
  bool _mutedNow = false;
  bool _showInactivitySection = true;
  bool _showXpSection = true;
  bool _showPlanSection = true;
  bool _showSystemSection = false;
  List<PendingNotificationRequest> _pending = const [];
  List<_PlanAlarmRow> _planRows = const [];
  List<_XpMessageRow> _xpRows = const [];
  String? _lastTrainingLogAt;

  @override
  void initState() {
    super.initState();
    _reminderService = TrainingPlanReminderService(
      widget.optionRepository,
      widget.settingsService,
    );
    _restoreSectionExpandedState();
    _load();
  }

  void _restoreSectionExpandedState() {
    _showInactivitySection =
        widget.optionRepository.getValue<bool>(_showInactivitySectionKey) ??
            _showInactivitySection;
    _showXpSection =
        widget.optionRepository.getValue<bool>(_showXpSectionKey) ??
            _showXpSection;
    _showPlanSection =
        widget.optionRepository.getValue<bool>(_showPlanSectionKey) ??
            _showPlanSection;
    _showSystemSection =
        widget.optionRepository.getValue<bool>(_showSystemSectionKey) ??
            _showSystemSection;
  }

  void _toggleSection({
    required String storageKey,
    required bool currentValue,
    required void Function(bool next) apply,
  }) {
    final next = !currentValue;
    setState(() => apply(next));
    unawaited(widget.optionRepository.setValue(storageKey, next));
  }

  Future<void> _load() async {
    try {
      final seenPlanKeys = _loadSeenIds(_seenPlanKeysStorageKey);
      final seenXpIds = _loadSeenIds(_seenXpIdsStorageKey);
      await _reminderService.markAllRemindersRead();
      final permission = await _reminderService.hasNotificationPermission();
      final muted = await _reminderService.isAlarmMutedNow();
      final pending = await _reminderService.pendingReminders();
      final planRows = _loadPlanRows(seenPlanKeys);
      final xpRows = _loadXpRows(seenXpIds);
      final lastTrainingLogAt = widget.optionRepository.getValue<String>(
        TrainingPlanReminderService.lastTrainingLogAtKey,
      );
      if (!mounted) return;
      setState(() {
        _permissionGranted = permission;
        _mutedNow = muted;
        _pending = [...pending]..sort((a, b) => a.id.compareTo(b.id));
        _planRows = planRows;
        _xpRows = xpRows;
        _lastTrainingLogAt = lastTrainingLogAt;
        _loading = false;
      });
      await _markRowsSeen(planRows: planRows, xpRows: xpRows);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pending = const [];
        _planRows = _loadPlanRows(const <String>{});
        _xpRows = _loadXpRows(const <String>{});
        _loading = false;
      });
    }
  }

  Set<String> _loadSeenIds(String key) {
    final raw = widget.optionRepository.getValue<List>(key) ?? const [];
    return raw.map((item) => item.toString()).toSet();
  }

  Future<void> _markRowsSeen({
    required List<_PlanAlarmRow> planRows,
    required List<_XpMessageRow> xpRows,
  }) async {
    await widget.optionRepository.setValue(
      _seenPlanKeysStorageKey,
      planRows.map((row) => row.messageKey).toList(growable: false),
    );
    await widget.optionRepository.setValue(
      _seenXpIdsStorageKey,
      xpRows.map((row) => row.id).toList(growable: false),
    );
  }

  List<_PlanAlarmRow> _loadPlanRows(Set<String> seenPlanKeys) {
    final raw = widget.optionRepository.getValue<String>(
      TrainingPlanReminderService.plansStorageKey,
    );
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final rows = decoded
          .whereType<Map>()
          .map(
            (e) => _PlanAlarmRow.fromMap(
              e.cast<String, dynamic>(),
              seenKeys: seenPlanKeys,
            ),
          )
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

  List<_XpMessageRow> _loadXpRows(Set<String> seenXpIds) {
    final logs = _reminderService.loadXpMessageLogSync();
    return logs
        .map((item) => _XpMessageRow.fromMap(item, seenIds: seenXpIds))
        .toList(growable: false);
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

  Future<void> _deleteXpMessage(_XpMessageRow row) async {
    await _reminderService.deleteXpMessage(row.id);
    if (!mounted) return;
    setState(() {
      _xpRows =
          _xpRows.where((item) => item.id != row.id).toList(growable: false);
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
    final xpNewCount = _xpRows.where((row) => row.isNew).length;
    final planNewCount = _planRows.where((row) => row.isNew).length;
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
                if (!_permissionGranted) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.notifications_off_outlined),
                      title: Text(
                        isKo ? '알림 권한 꺼짐' : 'Notification permission is off',
                      ),
                      subtitle: Text(
                        isKo
                            ? '설정 > 알림에서 권한을 켜 주세요.'
                            : 'Enable permission in Settings > Notifications.',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                _NotificationSectionCard(
                  title: isKo ? '기록 리마인드' : 'Inactivity reminder',
                  icon: Icons.edit_calendar_outlined,
                  expanded: _showInactivitySection,
                  onTap: () => _toggleSection(
                    storageKey: _showInactivitySectionKey,
                    currentValue: _showInactivitySection,
                    apply: (next) => _showInactivitySection = next,
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
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
                _NotificationSectionCard(
                  title: isKo
                      ? '경험치 알림 ${_xpRows.length}개'
                      : '${_xpRows.length} XP alerts',
                  icon: Icons.stars_rounded,
                  expanded: _showXpSection,
                  newCount: xpNewCount,
                  onTap: () => _toggleSection(
                    storageKey: _showXpSectionKey,
                    currentValue: _showXpSection,
                    apply: (next) => _showXpSection = next,
                  ),
                  child: _xpRows.isEmpty
                      ? ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.stars_outlined),
                          title: Text(
                            isKo ? '경험치 알림이 없어요.' : 'No XP alerts yet.',
                          ),
                        )
                      : Column(
                          children: _xpRows
                              .map(
                                (item) => Dismissible(
                                  key: ValueKey('xp-msg-${item.id}'),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .errorContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.delete_outline,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
                                    ),
                                  ),
                                  onDismissed: (_) => _deleteXpMessage(item),
                                  child: Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: const Icon(Icons.stars_rounded),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.label.isEmpty
                                                  ? (isKo
                                                      ? '경험치 알림'
                                                      : 'XP alert')
                                                  : item.label,
                                            ),
                                          ),
                                          if (item.isNew) const _NewBadge(),
                                        ],
                                      ),
                                      subtitle: Text(
                                        '${isKo ? '+${item.gainedXp} XP · 누적 ${item.totalXp} XP' : '+${item.gainedXp} XP · total ${item.totalXp} XP'}\n${DateFormat(isKo ? 'M/d HH:mm' : 'MMM d HH:mm').format(item.createdAt)}',
                                      ),
                                      trailing: IconButton(
                                        tooltip: isKo ? '삭제' : 'Delete',
                                        onPressed: () => _deleteXpMessage(item),
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                ),
                const SizedBox(height: 8),
                _NotificationSectionCard(
                  title: isKo
                      ? '훈련 알림 ${_planRows.length}개'
                      : '${_planRows.length} training alerts',
                  icon: Icons.alarm_outlined,
                  expanded: _showPlanSection,
                  newCount: planNewCount,
                  onTap: () => _toggleSection(
                    storageKey: _showPlanSectionKey,
                    currentValue: _showPlanSection,
                    apply: (next) => _showPlanSection = next,
                  ),
                  child: _planRows.isEmpty
                      ? ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.inbox_outlined),
                          title: Text(
                            isKo ? '예약된 알림이 없어요.' : 'No scheduled alerts.',
                          ),
                          subtitle: Text(
                            isKo
                                ? '훈련 계획을 추가하면 알림이 여기에 표시돼요.'
                                : 'Add a training plan to see reminders here.',
                          ),
                        )
                      : Column(
                          children: _planRows
                              .map(
                                (item) => Dismissible(
                                  key: ValueKey('alarm-msg-${item.messageKey}'),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .errorContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.delete_outline,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
                                    ),
                                  ),
                                  onDismissed: (_) => _deleteMessage(item),
                                  child: Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: const Icon(Icons.alarm_outlined),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.category.isEmpty
                                                  ? (isKo
                                                      ? '훈련 계획'
                                                      : 'Training plan')
                                                  : item.category,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (item.isNew) ...[
                                            const SizedBox(width: 8),
                                            const _NewBadge(),
                                          ],
                                          const SizedBox(width: 8),
                                          Text(
                                            DateFormat('HH:mm')
                                                .format(item.scheduledAt),
                                          ),
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
                              )
                              .toList(growable: false),
                        ),
                ),
                if (_pending.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _NotificationSectionCard(
                    title: isKo
                        ? '시스템 예약 알림 ${_pending.length}개'
                        : '${_pending.length} system-scheduled alerts',
                    icon: Icons.schedule_outlined,
                    expanded: _showSystemSection,
                    onTap: () => _toggleSection(
                      storageKey: _showSystemSectionKey,
                      currentValue: _showSystemSection,
                      apply: (next) => _showSystemSection = next,
                    ),
                    child: Text(
                      isKo
                          ? '시스템 예약 상태를 참고용으로 보여줍니다.'
                          : 'This shows the OS-level scheduled notification count.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _mutedNow
                                  ? (isKo
                                      ? '현재 알림이 일시중지되어 있어요.'
                                      : 'Alerts are currently paused.')
                                  : (isKo
                                      ? '반복 알림 제어'
                                      : 'Repeating alert control'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isKo
                                  ? '알림을 잠시 멈추거나 다시 켤 수 있어요.'
                                  : 'Temporarily mute alerts or resume anytime.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _mutedNow
                                        ? null
                                        : () async {
                                            await _muteForHours(8);
                                            if (!mounted) return;
                                            setSheetState(() {});
                                          },
                                    icon: const Icon(
                                      Icons.notifications_off_outlined,
                                    ),
                                    label: Text(isKo ? '8시간 끄기' : 'Mute 8h'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: _mutedNow
                                        ? () async {
                                            await _resumeAlerts();
                                            if (!mounted) return;
                                            setSheetState(() {});
                                          }
                                        : null,
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

class _NotificationSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;
  final int newCount;

  const _NotificationSectionCard({
    required this.title,
    required this.icon,
    required this.expanded,
    required this.onTap,
    required this.child,
    this.newCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (newCount > 0) ...[
                      _NewBadge(label: 'NEW $newCount'),
                      const SizedBox(width: 8),
                    ],
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                    ),
                  ],
                ),
              ),
            ),
            if (expanded) ...[
              const SizedBox(height: 8),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  final String label;

  const _NewBadge({this.label = 'NEW'});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _PlanAlarmRow {
  final String id;
  final DateTime scheduledAt;
  final String category;
  final String scheduleSummary;
  final String messageKey;
  final bool isNew;

  const _PlanAlarmRow({
    required this.id,
    required this.scheduledAt,
    required this.category,
    required this.scheduleSummary,
    required this.messageKey,
    required this.isNew,
  });

  factory _PlanAlarmRow.fromMap(
    Map<String, dynamic> map, {
    Set<String> seenKeys = const <String>{},
  }) {
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
    final messageKey =
        '${map['id']?.toString() ?? ''}|${map['scheduledAt']?.toString() ?? ''}';
    return _PlanAlarmRow(
      id: map['id']?.toString() ?? '',
      scheduledAt: DateTime.tryParse(map['scheduledAt']?.toString() ?? '') ??
          DateTime.now(),
      category: map['category']?.toString() ?? '',
      scheduleSummary: [
        weekdayText,
        rangeText,
      ].where((value) => value.trim().isNotEmpty).join(' · '),
      messageKey: messageKey,
      isNew: !seenKeys.contains(messageKey),
    );
  }
}

class _XpMessageRow {
  final String id;
  final DateTime createdAt;
  final int gainedXp;
  final int totalXp;
  final String label;
  final bool isNew;

  const _XpMessageRow({
    required this.id,
    required this.createdAt,
    required this.gainedXp,
    required this.totalXp,
    required this.label,
    required this.isNew,
  });

  factory _XpMessageRow.fromMap(
    Map<String, dynamic> map, {
    Set<String> seenIds = const <String>{},
  }) {
    final id = map['id']?.toString() ?? '';
    return _XpMessageRow(
      id: id,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      gainedXp: (map['gainedXp'] as num?)?.toInt() ?? 0,
      totalXp: (map['totalXp'] as num?)?.toInt() ?? 0,
      label: map['label']?.toString() ?? '',
      isNew: !seenIds.contains(id),
    );
  }
}
