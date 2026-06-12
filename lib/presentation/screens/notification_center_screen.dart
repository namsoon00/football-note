import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../application/league_fixture_reminder_service.dart';
import '../../application/notification_app_link.dart';
import '../../application/settings_service.dart';
import '../../application/training_plan_badge_service.dart';
import '../../application/training_plan_reminder_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../../gen/app_localizations.dart';
import '../navigation/notification_tap_router.dart';

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
  static const _seenXpIdsStorageKey = 'notification_seen_xp_ids_v1';
  static const _showInactivitySectionKey =
      'notification_show_inactivity_section_v1';
  static const _showXpSectionKey = 'notification_show_xp_section_v1';
  static const _showPlanSectionKey = 'notification_show_plan_section_v1';
  static const _showFamilySectionKey = 'notification_show_family_section_v1';
  static const _showFixtureSectionKey = 'notification_show_fixture_section_v1';

  late final TrainingPlanReminderService _reminderService;
  late final LeagueFixtureReminderService _fixtureReminderService;
  bool _permissionGranted = true;
  bool _loading = true;
  bool _mutedNow = false;
  bool _showInactivitySection = true;
  bool _showXpSection = true;
  bool _showPlanSection = true;
  bool _showFamilySection = true;
  bool _showFixtureSection = true;
  List<_PlanAlarmRow> _planRows = const [];
  List<_XpMessageRow> _xpRows = const [];
  List<_FamilyMessageRow> _familyRows = const [];
  List<_FixtureMessageRow> _fixtureRows = const [];
  String? _lastTrainingLogAt;

  @override
  void initState() {
    super.initState();
    _reminderService = TrainingPlanReminderService(
      widget.optionRepository,
      widget.settingsService,
    );
    _fixtureReminderService = LeagueFixtureReminderService(
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
    _showFamilySection =
        widget.optionRepository.getValue<bool>(_showFamilySectionKey) ??
        _showFamilySection;
    _showFixtureSection =
        widget.optionRepository.getValue<bool>(_showFixtureSectionKey) ??
        _showFixtureSection;
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
      final seenXpIds = _loadSeenIds(_seenXpIdsStorageKey);
      await _reminderService.markAllRemindersRead();
      final permission = await _reminderService.hasNotificationPermission();
      final muted = await _reminderService.isAlarmMutedNow();
      final planRows = _loadPlanRows();
      final xpRows = _loadXpRows(seenXpIds);
      final familyRows = _loadFamilyRows();
      final fixtureRows = _loadFixtureRows();
      await _fixtureReminderService.markAllFixtureMessagesRead();
      final lastTrainingLogAt = widget.optionRepository.getValue<String>(
        TrainingPlanReminderService.lastTrainingLogAtKey,
      );
      await TrainingPlanBadgeService(widget.optionRepository).syncFromStorage();
      if (!mounted) return;
      setState(() {
        _permissionGranted = permission;
        _mutedNow = muted;
        _planRows = planRows;
        _xpRows = xpRows;
        _familyRows = familyRows;
        _fixtureRows = fixtureRows;
        _lastTrainingLogAt = lastTrainingLogAt;
        _loading = false;
      });
      await _markRowsSeen(xpRows: xpRows);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _planRows = _loadPlanRows();
        _xpRows = _loadXpRows(const <String>{});
        _familyRows = _loadFamilyRows();
        _fixtureRows = _loadFixtureRows();
        _loading = false;
      });
    }
  }

  Set<String> _loadSeenIds(String key) {
    final raw = widget.optionRepository.getValue<List>(key) ?? const [];
    return raw.map((item) => item.toString()).toSet();
  }

  Future<void> _markRowsSeen({required List<_XpMessageRow> xpRows}) async {
    await widget.optionRepository.setValue(
      _seenXpIdsStorageKey,
      xpRows.map((row) => row.id).toList(growable: false),
    );
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

  List<_FamilyMessageRow> _loadFamilyRows() {
    final logs = _reminderService.loadFamilyMessageLogSync();
    return logs.map(_FamilyMessageRow.fromMap).toList(growable: false);
  }

  List<_FixtureMessageRow> _loadFixtureRows() {
    final logs = _fixtureReminderService.loadFixtureMessageLogSync();
    return logs.map(_FixtureMessageRow.fromMap).toList(growable: false);
  }

  Future<void> _deleteMessage(_PlanAlarmRow row) async {
    await _reminderService.dismissMessageKey(row.messageKey);
    await TrainingPlanBadgeService(widget.optionRepository).syncFromStorage();
    if (!mounted) return;
    setState(() {
      _planRows = _planRows
          .where((item) => item.messageKey != row.messageKey)
          .toList(growable: false);
    });
  }

  Future<void> _deleteXpMessage(_XpMessageRow row) async {
    await _reminderService.deleteXpMessage(row.id);
    await TrainingPlanBadgeService(widget.optionRepository).syncFromStorage();
    if (!mounted) return;
    setState(() {
      _xpRows = _xpRows
          .where((item) => item.id != row.id)
          .toList(growable: false);
    });
  }

  Future<void> _deleteFamilyMessage(_FamilyMessageRow row) async {
    await _reminderService.deleteFamilyMessage(row.id);
    await TrainingPlanBadgeService(widget.optionRepository).syncFromStorage();
    if (!mounted) return;
    setState(() {
      _familyRows = _familyRows
          .where((item) => item.id != row.id)
          .toList(growable: false);
    });
  }

  Future<void> _deleteFixtureMessage(_FixtureMessageRow row) async {
    await _fixtureReminderService.deleteFixtureMessage(row.id);
    await TrainingPlanBadgeService(widget.optionRepository).syncFromStorage();
    if (!mounted) return;
    setState(() {
      _fixtureRows = _fixtureRows
          .where((item) => item.id != row.id)
          .toList(growable: false);
    });
  }

  Widget _deleteBackground(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
    );
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
    final l10n = AppLocalizations.of(context)!;
    final xpNewCount = _xpRows.where((row) => row.isNew).length;
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(l10n.notifications),
        actions: [
          _buildHeaderAction(
            label: l10n.notificationSettingsAction,
            icon: Icons.tune_rounded,
            onPressed: _openNotificationSettingsSheet,
          ),
          const SizedBox(width: 6),
          _buildHeaderAction(
            label: l10n.notificationRefreshAction,
            icon: Icons.refresh_rounded,
            onPressed: _load,
          ),
          const SizedBox(width: 8),
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
                          ? (isKo ? '폰 알림 활성화' : 'Phone notifications are on')
                          : (isKo
                                ? '폰 알림 비활성화'
                                : 'Phone notifications are off'),
                    ),
                    subtitle: Text(
                      _permissionGranted
                          ? (widget.settingsService.reminderEnabled
                                ? (isKo
                                      ? '기기 알림과 앱 알림이 모두 켜져 있습니다.'
                                      : 'Both device notifications and in-app alerts are enabled.')
                                : (isKo
                                      ? '기기 알림은 켜져 있지만 앱 내 전체 알림은 꺼져 있습니다.'
                                      : 'Device notifications are on, but in-app alerts are turned off.'))
                          : (isKo
                                ? '설정 > 알림에서 이 앱의 알림을 허용해야 실제 알림이 도착합니다.'
                                : 'Allow notifications for this app in Settings > Notifications to receive alerts.'),
                    ),
                    trailing: _permissionGranted
                        ? const Icon(Icons.check_circle_outline)
                        : const Icon(Icons.error_outline),
                  ),
                ),
                const SizedBox(height: 8),
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
                                  background: _deleteBackground(context),
                                  onDismissed: (_) => _deleteXpMessage(item),
                                  child: Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      onTap: () =>
                                          NotificationTapRouter.handlePayload(
                                            NotificationAppLink.xpHistory(
                                              totalXp: item.totalXp,
                                            ),
                                          ),
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
                  title: l10n.notificationFamilySectionTitle(
                    _familyRows.length,
                  ),
                  icon: Icons.family_restroom_outlined,
                  expanded: _showFamilySection,
                  onTap: () => _toggleSection(
                    storageKey: _showFamilySectionKey,
                    currentValue: _showFamilySection,
                    apply: (next) => _showFamilySection = next,
                  ),
                  child: _familyRows.isEmpty
                      ? ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.family_restroom_outlined),
                          title: Text(l10n.notificationFamilyEmpty),
                        )
                      : Column(
                          children: _familyRows
                              .map(
                                (item) => Dismissible(
                                  key: ValueKey('family-msg-${item.id}'),
                                  direction: DismissDirection.endToStart,
                                  background: _deleteBackground(context),
                                  onDismissed: (_) =>
                                      _deleteFamilyMessage(item),
                                  child: Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      onTap: () =>
                                          NotificationTapRouter.handlePayload(
                                            item.payload,
                                          ),
                                      leading: const Icon(
                                        Icons.sync_alt_rounded,
                                      ),
                                      title: Text(item.title),
                                      subtitle: Text(
                                        '${item.body}\n${DateFormat(isKo ? 'M/d HH:mm' : 'MMM d HH:mm').format(item.createdAt)}',
                                      ),
                                      trailing: IconButton(
                                        tooltip: l10n.delete,
                                        onPressed: () =>
                                            _deleteFamilyMessage(item),
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
                  title: l10n.notificationFixtureSectionTitle(
                    _fixtureRows.length,
                  ),
                  icon: Icons.sports_soccer_rounded,
                  expanded: _showFixtureSection,
                  onTap: () => _toggleSection(
                    storageKey: _showFixtureSectionKey,
                    currentValue: _showFixtureSection,
                    apply: (next) => _showFixtureSection = next,
                  ),
                  child: _fixtureRows.isEmpty
                      ? ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.sports_soccer_outlined),
                          title: Text(l10n.notificationFixtureEmpty),
                        )
                      : Column(
                          children: _fixtureRows
                              .map(
                                (item) => Dismissible(
                                  key: ValueKey('fixture-msg-${item.id}'),
                                  direction: DismissDirection.endToStart,
                                  background: _deleteBackground(context),
                                  onDismissed: (_) =>
                                      _deleteFixtureMessage(item),
                                  child: Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      onTap: () =>
                                          NotificationTapRouter.handlePayload(
                                            item.payload,
                                          ),
                                      leading: Icon(
                                        item.isWorldCup
                                            ? Icons.emoji_events_outlined
                                            : Icons.sports_soccer_rounded,
                                      ),
                                      title: Text(
                                        item.title.isEmpty
                                            ? item.leagueName
                                            : item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        '${item.body}\n${DateFormat(isKo ? 'M/d(E) HH:mm' : 'EEE, M/d HH:mm').format(item.kickoffAt)}',
                                      ),
                                      trailing: IconButton(
                                        tooltip: l10n.delete,
                                        onPressed: () =>
                                            _deleteFixtureMessage(item),
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
                                  background: _deleteBackground(context),
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
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatPlanTime(
                                              item.scheduledAt,
                                              isKo: isKo,
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Text(
                                        '${DateFormat(isKo ? 'M/d(E)' : 'EEE, M/d').format(item.scheduledAt)}'
                                        '${item.scheduleSummary.isEmpty ? '' : '\n${item.scheduleSummary}'}',
                                      ),
                                      onTap: () =>
                                          NotificationTapRouter.handlePayload(
                                            NotificationAppLink.calendarPlan(
                                              planId: item.id,
                                              scheduledAt: item.scheduledAt,
                                              atStartTime: false,
                                            ),
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

  Widget _buildHeaderAction({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      icon: Icon(icon, size: 17),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }

  Future<void> _syncNotificationSettings() async {
    await _reminderService.syncSettingsDrivenReminders();
    if (!mounted) return;
    await _load();
  }

  Future<void> _openNotificationSettingsSheet() async {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final l10n = AppLocalizations.of(context)!;
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
                      Row(
                        children: [
                          IconButton.filledTonal(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back),
                            tooltip: l10n.notificationSettingsCloseTooltip,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.notificationSettingsTitle,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
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
                                  ? l10n.notificationMuteStatusPaused
                                  : l10n.notificationMuteControlTitle,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.notificationMuteControlSubtitle,
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
                                    label: Text(
                                      l10n.notificationMute8HoursAction,
                                    ),
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
                                    label: Text(l10n.notificationResumeAction),
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
                        title: Text(l10n.notificationAllSettingsTitle),
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
                          l10n.notificationTrainingPlanVibrationTitle,
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
                        title: Text(l10n.notificationXpAlertSettingsTitle),
                        subtitle: Text(
                          l10n.notificationXpAlertSettingsSubtitle,
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
                        title: Text(l10n.notificationLevelUpSettingsTitle),
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
                        title: Text(l10n.notificationFamilySettingsTitle),
                        subtitle: Text(l10n.notificationFamilySettingsSubtitle),
                        value: widget.settingsService.familySyncAlertEnabled,
                        onChanged: widget.settingsService.reminderEnabled
                            ? (value) async {
                                await widget.settingsService
                                    .setFamilySyncAlertEnabled(value);
                                await refreshSheet();
                              }
                            : null,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          l10n.notificationLeagueFixtureSettingsTitle,
                        ),
                        subtitle: Text(
                          l10n.notificationLeagueFixtureSettingsSubtitle,
                        ),
                        value: widget.settingsService.leagueFixtureAlertEnabled,
                        onChanged: widget.settingsService.reminderEnabled
                            ? (value) async {
                                await widget.settingsService
                                    .setLeagueFixtureAlertEnabled(value);
                                if (!value) {
                                  await LeagueFixtureReminderService(
                                    widget.optionRepository,
                                    widget.settingsService,
                                  ).clearAllReminders();
                                }
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
                            labelText: isKo
                                ? '기록 공백 기준'
                                : 'Inactivity threshold',
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
                        style: Theme.of(context).textTheme.titleMedium
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
            if (expanded) ...[const SizedBox(height: 8), child],
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
    final messageKey =
        '${map['id']?.toString() ?? ''}|${map['scheduledAt']?.toString() ?? ''}';
    return _PlanAlarmRow(
      id: map['id']?.toString() ?? '',
      scheduledAt:
          DateTime.tryParse(map['scheduledAt']?.toString() ?? '') ??
          DateTime.now(),
      category: map['category']?.toString() ?? '',
      scheduleSummary: [
        weekdayText,
        rangeText,
      ].where((value) => value.trim().isNotEmpty).join(' · '),
      messageKey: messageKey,
    );
  }
}

String _formatPlanTime(DateTime value, {required bool isKo}) {
  return isKo
      ? DateFormat('a h:mm', 'ko').format(value)
      : DateFormat('h:mm a', 'en').format(value);
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
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      gainedXp: (map['gainedXp'] as num?)?.toInt() ?? 0,
      totalXp: (map['totalXp'] as num?)?.toInt() ?? 0,
      label: map['label']?.toString() ?? '',
      isNew: !seenIds.contains(id),
    );
  }
}

class _FamilyMessageRow {
  final String id;
  final DateTime createdAt;
  final String title;
  final String body;
  final String payload;

  const _FamilyMessageRow({
    required this.id,
    required this.createdAt,
    required this.title,
    required this.body,
    required this.payload,
  });

  factory _FamilyMessageRow.fromMap(Map<String, dynamic> map) {
    return _FamilyMessageRow(
      id: map['id']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      payload: map['payload']?.toString() ?? '',
    );
  }
}

class _FixtureMessageRow {
  final String id;
  final String payload;
  final DateTime scheduledAt;
  final DateTime kickoffAt;
  final String title;
  final String body;
  final String leagueName;
  final bool isWorldCup;

  const _FixtureMessageRow({
    required this.id,
    required this.payload,
    required this.scheduledAt,
    required this.kickoffAt,
    required this.title,
    required this.body,
    required this.leagueName,
    required this.isWorldCup,
  });

  factory _FixtureMessageRow.fromMap(Map<String, dynamic> map) {
    final kickoffAt =
        DateTime.tryParse(map['kickoffAt']?.toString() ?? '') ??
        DateTime.tryParse(map['scheduledAt']?.toString() ?? '') ??
        DateTime.now();
    return _FixtureMessageRow(
      id: map['id']?.toString() ?? '',
      payload: map['payload']?.toString() ?? '',
      scheduledAt:
          DateTime.tryParse(map['scheduledAt']?.toString() ?? '') ?? kickoffAt,
      kickoffAt: kickoffAt,
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      leagueName: map['leagueName']?.toString() ?? '',
      isWorldCup: (map['kind']?.toString() ?? '') == 'worldCup',
    );
  }
}
