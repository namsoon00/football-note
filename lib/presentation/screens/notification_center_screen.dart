import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../application/league_fixture_reminder_service.dart';
import '../../application/notification_app_link.dart';
import '../../application/settings_service.dart';
import '../../application/training_plan_badge_service.dart';
import '../../application/training_plan_reminder_service.dart';
import '../../application/weather_reminder_service.dart';
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

  late final TrainingPlanReminderService _reminderService;
  late final LeagueFixtureReminderService _fixtureReminderService;
  late final WeatherReminderService _weatherReminderService;
  bool _permissionGranted = true;
  bool _loading = true;
  bool _mutedNow = false;
  List<_PlanAlarmRow> _planRows = const [];
  List<_XpMessageRow> _xpRows = const [];
  List<_FamilyMessageRow> _familyRows = const [];
  List<_FixtureMessageRow> _fixtureRows = const [];
  List<_WeatherMessageRow> _weatherRows = const [];
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
    _weatherReminderService = WeatherReminderService(
      widget.optionRepository,
      widget.settingsService,
    );
    _load();
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
      final weatherRows = _loadWeatherRows();
      await _fixtureReminderService.markAllFixtureMessagesRead();
      await _weatherReminderService.markAllWeatherMessagesRead();
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
        _weatherRows = weatherRows;
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
        _weatherRows = _loadWeatherRows();
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

  List<_WeatherMessageRow> _loadWeatherRows() {
    final logs = _weatherReminderService.loadWeatherMessageLogSync();
    return logs.map(_WeatherMessageRow.fromMap).toList(growable: false);
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
      _xpRows =
          _xpRows.where((item) => item.id != row.id).toList(growable: false);
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

  Future<void> _deleteWeatherMessage(_WeatherMessageRow row) async {
    await _weatherReminderService.deleteWeatherMessage(row.id);
    await TrainingPlanBadgeService(widget.optionRepository).syncFromStorage();
    if (!mounted) return;
    setState(() {
      _weatherRows = _weatherRows
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
    await _weatherReminderService.clearAllReminders();
    if (!mounted) return;
    await _load();
  }

  Future<void> _resumeAlerts() async {
    await _reminderService.clearAlarmMute();
    await _reminderService.syncSettingsDrivenReminders();
    await _weatherReminderService.syncSettingsDrivenReminders();
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final l10n = AppLocalizations.of(context)!;
    final feedItems = _buildFeedItems(l10n: l10n, isKo: isKo);
    final feedSections = _buildFeedSections(feedItems, l10n: l10n);
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
                _NotificationOverviewCard(
                  permissionGranted: _permissionGranted,
                  appNotificationEnabled:
                      widget.settingsService.reminderEnabled,
                  mutedNow: _mutedNow,
                  countLabel: l10n.notificationOverviewCountLabel(
                    feedItems.length,
                  ),
                  l10n: l10n,
                ),
                const SizedBox(height: 16),
                _NotificationFeedHeader(
                  title: l10n.notificationFeedTitle,
                  subtitle: l10n.notificationFeedSubtitle(feedItems.length),
                ),
                const SizedBox(height: 10),
                if (feedItems.isEmpty)
                  _NotificationEmptyCard(
                    title: l10n.notificationFeedEmptyTitle,
                    subtitle: l10n.notificationFeedEmptySubtitle,
                  )
                else
                  for (final section in feedSections) ...[
                    _NotificationCategorySectionHeader(section: section),
                    const SizedBox(height: 8),
                    ...section.items.map(
                      (item) => _NotificationFeedTile(
                        item: item,
                        newLabel: l10n.notificationNewBadge,
                        deleteTooltip: l10n.delete,
                        deleteBackground: _deleteBackground(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
    );
  }

  List<_NotificationFeedItem> _buildFeedItems({
    required AppLocalizations l10n,
    required bool isKo,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final items = <_NotificationFeedItem>[];
    for (final item in _weatherRows) {
      items.add(
        _NotificationFeedItem(
          key: 'weather-msg-${item.id}',
          category: _NotificationCategory.weather,
          title: item.title.isEmpty ? l10n.homeWeatherTitle : item.title,
          subtitle: item.body,
          time: item.scheduledAt,
          timeLabel: _formatFeedTime(item.scheduledAt, isKo: isKo),
          icon: Icons.cloud_outlined,
          color: scheme.tertiary,
          payload: item.payload,
          upcoming: true,
          onDelete: () => _deleteWeatherMessage(item),
        ),
      );
    }
    for (final item in _planRows) {
      items.add(
        _NotificationFeedItem(
          key: 'alarm-msg-${item.messageKey}',
          category: _NotificationCategory.trainingPlan,
          title: item.category.isEmpty
              ? l10n.notificationPlanFallbackTitle
              : item.category,
          subtitle: _buildPlanSubtitle(item),
          time: item.scheduledAt,
          timeLabel: _formatFeedTime(item.scheduledAt, isKo: isKo),
          icon: Icons.alarm_outlined,
          color: scheme.primary,
          payload: NotificationAppLink.calendarPlan(
            planId: item.id,
            scheduledAt: item.scheduledAt,
            atStartTime: false,
          ),
          upcoming: true,
          onDelete: () => _deleteMessage(item),
        ),
      );
    }
    for (final item in _fixtureRows) {
      items.add(
        _NotificationFeedItem(
          key: 'fixture-msg-${item.id}',
          category: _NotificationCategory.fixture,
          title: item.title.isEmpty ? item.leagueName : item.title,
          subtitle: item.body,
          time: item.kickoffAt,
          timeLabel: _formatFeedTime(item.kickoffAt, isKo: isKo),
          icon: item.isWorldCup
              ? Icons.emoji_events_outlined
              : Icons.sports_soccer_rounded,
          color: scheme.secondary,
          payload: item.payload,
          upcoming: true,
          onDelete: () => _deleteFixtureMessage(item),
        ),
      );
    }
    for (final item in _xpRows) {
      items.add(
        _NotificationFeedItem(
          key: 'xp-msg-${item.id}',
          category: _NotificationCategory.xp,
          title: item.label.isEmpty
              ? l10n.notificationXpFallbackTitle
              : item.label,
          subtitle: l10n.notificationXpSubtitle(
            item.gainedXp,
            item.totalXp,
          ),
          time: item.createdAt,
          timeLabel: _formatFeedTime(item.createdAt, isKo: isKo),
          icon: Icons.stars_rounded,
          color: scheme.primary,
          payload: NotificationAppLink.xpHistory(totalXp: item.totalXp),
          isNew: item.isNew,
          upcoming: false,
          onDelete: () => _deleteXpMessage(item),
        ),
      );
    }
    for (final item in _familyRows) {
      items.add(
        _NotificationFeedItem(
          key: 'family-msg-${item.id}',
          category: _NotificationCategory.family,
          title: item.title,
          subtitle: item.body,
          time: item.createdAt,
          timeLabel: _formatFeedTime(item.createdAt, isKo: isKo),
          icon: Icons.sync_alt_rounded,
          color: scheme.secondary,
          payload: item.payload,
          upcoming: false,
          onDelete: () => _deleteFamilyMessage(item),
        ),
      );
    }
    items.sort((a, b) {
      if (a.upcoming != b.upcoming) return a.upcoming ? -1 : 1;
      if (a.upcoming) return a.time.compareTo(b.time);
      return b.time.compareTo(a.time);
    });
    return items;
  }

  List<_NotificationFeedSection> _buildFeedSections(
    List<_NotificationFeedItem> items, {
    required AppLocalizations l10n,
  }) {
    return _NotificationCategory.values.expand((category) {
      final categoryItems = items
          .where((item) => item.category == category)
          .toList(growable: false);
      if (categoryItems.isEmpty) return const <_NotificationFeedSection>[];
      return [
        _NotificationFeedSection(
          title: l10n.notificationCategorySectionTitle(
            _categoryLabel(category, l10n),
            categoryItems.length,
          ),
          icon: _categoryIcon(category),
          items: categoryItems,
        ),
      ];
    }).toList(growable: false);
  }

  String _categoryLabel(
    _NotificationCategory category,
    AppLocalizations l10n,
  ) {
    switch (category) {
      case _NotificationCategory.trainingPlan:
        return l10n.notificationCategoryTrainingPlan;
      case _NotificationCategory.weather:
        return l10n.notificationCategoryWeather;
      case _NotificationCategory.fixture:
        return l10n.notificationCategoryFixture;
      case _NotificationCategory.xp:
        return l10n.notificationCategoryXp;
      case _NotificationCategory.family:
        return l10n.notificationCategoryFamily;
    }
  }

  IconData _categoryIcon(_NotificationCategory category) {
    switch (category) {
      case _NotificationCategory.trainingPlan:
        return Icons.alarm_outlined;
      case _NotificationCategory.weather:
        return Icons.cloud_outlined;
      case _NotificationCategory.fixture:
        return Icons.sports_soccer_rounded;
      case _NotificationCategory.xp:
        return Icons.stars_rounded;
      case _NotificationCategory.family:
        return Icons.sync_alt_rounded;
    }
  }

  String _buildPlanSubtitle(_PlanAlarmRow item) {
    return item.scheduleSummary;
  }

  String _formatFeedTime(DateTime value, {required bool isKo}) {
    return DateFormat(
      isKo ? 'M/d(E) HH:mm' : 'EEE, MMM d HH:mm',
      isKo ? 'ko' : 'en',
    ).format(value);
  }

  String _buildInactivitySubtitle(AppLocalizations l10n) {
    final raw = _lastTrainingLogAt;
    final parsed = raw == null ? null : DateTime.tryParse(raw);
    final time = widget.settingsService.reminderTime.format(context);
    final base = widget.settingsService.inactivityAlertEnabled
        ? l10n.notificationInactivityOnSubtitle(
            widget.settingsService.inactivityAlertDays,
            time,
          )
        : l10n.notificationInactivityOffSubtitle;
    if (parsed == null) return base;
    final formatted = DateFormat(
      Localizations.localeOf(context).languageCode == 'ko'
          ? 'M/d HH:mm'
          : 'MMM d HH:mm',
    ).format(parsed);
    return '$base\n${l10n.notificationLastTrainingLog(formatted)}';
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
    await _weatherReminderService.syncSettingsDrivenReminders();
    if (!mounted) return;
    await _load();
  }

  Future<void> _openNotificationSettingsSheet() async {
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
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
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
                        title: Text(l10n.notificationWeatherSettingsTitle),
                        subtitle:
                            Text(l10n.notificationWeatherSettingsSubtitle),
                        value: widget.settingsService.weatherAlertEnabled,
                        onChanged: widget.settingsService.reminderEnabled
                            ? (value) async {
                                await widget.settingsService
                                    .setWeatherAlertEnabled(value);
                                if (!value) {
                                  await _weatherReminderService
                                      .clearAllReminders();
                                }
                                await refreshSheet();
                              }
                            : null,
                      ),
                      if (widget.settingsService.weatherAlertEnabled)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.notificationWeatherTimeTitle),
                          subtitle: Text(
                            l10n.notificationWeatherTimeSubtitle(
                              widget.settingsService.weatherAlertTime.format(
                                context,
                              ),
                            ),
                          ),
                          trailing: OutlinedButton(
                            onPressed: widget.settingsService.reminderEnabled
                                ? () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: widget
                                          .settingsService.weatherAlertTime,
                                    );
                                    if (picked == null) return;
                                    await widget.settingsService
                                        .setWeatherAlertTime(picked);
                                    await refreshSheet();
                                  }
                                : null,
                            child: Text(l10n.notificationChangeTimeAction),
                          ),
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
                                  await _fixtureReminderService
                                      .clearAllReminders();
                                  await _fixtureReminderService
                                      .clearWorldCupReminders();
                                }
                                await refreshSheet();
                              }
                            : null,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.notificationInactivitySettingsTitle),
                        subtitle: Text(_buildInactivitySubtitle(l10n)),
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
                          title: Text(l10n.notificationInactivityTimeTitle),
                          subtitle: Text(
                            l10n.notificationInactivityTimeSubtitle(
                              widget.settingsService.inactivityAlertDays,
                              widget.settingsService.reminderTime.format(
                                context,
                              ),
                            ),
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
                            child: Text(l10n.notificationChangeTimeAction),
                          ),
                        ),
                      if (widget.settingsService.inactivityAlertEnabled)
                        DropdownButtonFormField<int>(
                          initialValue:
                              widget.settingsService.inactivityAlertDays,
                          decoration: InputDecoration(
                            labelText:
                                l10n.notificationInactivityThresholdLabel,
                          ),
                          items: const [1, 2, 3, 5, 7, 10, 14]
                              .map(
                                (value) => DropdownMenuItem<int>(
                                  value: value,
                                  child: Text(
                                    l10n.notificationInactivityThresholdDayOption(
                                      value,
                                    ),
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

class _NotificationOverviewCard extends StatelessWidget {
  final bool permissionGranted;
  final bool appNotificationEnabled;
  final bool mutedNow;
  final String countLabel;
  final AppLocalizations l10n;

  const _NotificationOverviewCard({
    required this.permissionGranted,
    required this.appNotificationEnabled,
    required this.mutedNow,
    required this.countLabel,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isFullyEnabled = permissionGranted && appNotificationEnabled;
    final title = permissionGranted
        ? l10n.notificationOverviewOnTitle
        : l10n.notificationOverviewOffTitle;
    final subtitle = permissionGranted
        ? (appNotificationEnabled
            ? l10n.notificationOverviewAllOnSubtitle
            : l10n.notificationOverviewAppOffSubtitle)
        : l10n.notificationOverviewPermissionOffSubtitle;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (isFullyEnabled ? scheme.primary : scheme.error)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isFullyEnabled
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                color: isFullyEnabled ? scheme.primary : scheme.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      _StatusPill(
                        label: mutedNow
                            ? l10n.notificationOverviewPausedLabel
                            : countLabel,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationFeedHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _NotificationFeedHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _NotificationEmptyCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _NotificationEmptyCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.inbox_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCategorySectionHeader extends StatelessWidget {
  final _NotificationFeedSection section;

  const _NotificationCategorySectionHeader({required this.section});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 0),
      child: Row(
        children: [
          Icon(section.icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              section.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationFeedSection {
  final String title;
  final IconData icon;
  final List<_NotificationFeedItem> items;

  const _NotificationFeedSection({
    required this.title,
    required this.icon,
    required this.items,
  });
}

class _NotificationFeedTile extends StatelessWidget {
  final _NotificationFeedItem item;
  final String newLabel;
  final String deleteTooltip;
  final Widget deleteBackground;

  const _NotificationFeedTile({
    required this.item,
    required this.newLabel,
    required this.deleteTooltip,
    required this.deleteBackground,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = item.subtitle.trim();
    final subtitleText =
        subtitle.isEmpty ? item.timeLabel : '$subtitle\n${item.timeLabel}';
    final tile = Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        onTap: item.payload.trim().isEmpty
            ? null
            : () => NotificationTapRouter.handlePayload(item.payload),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(item.icon, color: item.color),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            if (item.isNew) ...[
              const SizedBox(width: 6),
              _NewBadge(label: newLabel),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitleText),
        ),
        trailing: item.onDelete == null
            ? null
            : IconButton(
                tooltip: deleteTooltip,
                onPressed: () => unawaited(item.onDelete!()),
                icon: const Icon(Icons.delete_outline),
              ),
      ),
    );
    if (item.onDelete == null) return tile;
    return Dismissible(
      key: ValueKey(item.key),
      direction: DismissDirection.endToStart,
      background: deleteBackground,
      onDismissed: (_) => unawaited(item.onDelete!()),
      child: tile,
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  final String label;

  const _NewBadge({required this.label});

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

enum _NotificationCategory {
  trainingPlan,
  weather,
  fixture,
  xp,
  family,
}

class _NotificationFeedItem {
  final String key;
  final _NotificationCategory category;
  final String title;
  final String subtitle;
  final DateTime time;
  final String timeLabel;
  final IconData icon;
  final Color color;
  final String payload;
  final bool isNew;
  final bool upcoming;
  final Future<void> Function()? onDelete;

  const _NotificationFeedItem({
    required this.key,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.timeLabel,
    required this.icon,
    required this.color,
    required this.payload,
    required this.upcoming,
    this.isNew = false,
    this.onDelete,
  });
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
      scheduledAt: DateTime.tryParse(map['scheduledAt']?.toString() ?? '') ??
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
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
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
    final kickoffAt = DateTime.tryParse(map['kickoffAt']?.toString() ?? '') ??
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

class _WeatherMessageRow {
  final String id;
  final String payload;
  final DateTime createdAt;
  final DateTime scheduledAt;
  final String title;
  final String body;

  const _WeatherMessageRow({
    required this.id,
    required this.payload,
    required this.createdAt,
    required this.scheduledAt,
    required this.title,
    required this.body,
  });

  factory _WeatherMessageRow.fromMap(Map<String, dynamic> map) {
    final scheduledAt =
        DateTime.tryParse(map['scheduledAt']?.toString() ?? '') ??
            DateTime.now();
    return _WeatherMessageRow(
      id: map['id']?.toString() ?? '',
      payload: map['payload']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? scheduledAt,
      scheduledAt: scheduledAt,
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
    );
  }
}
