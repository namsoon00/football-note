import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../domain/entities/training_entry.dart';
import '../domain/repositories/option_repository.dart';
import 'settings_service.dart';

class TrainingPlanReminderService {
  static const String plansStorageKey = 'training_plans_v1';
  static const String reminderIdsKey = 'training_plan_reminder_ids_v1';
  static const String reminderReadIdsKey = 'training_plan_reminder_read_ids_v1';
  static const String dismissedMessageKeysKey =
      'training_plan_dismissed_message_keys_v1';
  static const String xpMessageLogKey = 'xp_alert_message_log_v1';
  static const String xpMessageReadIdsKey = 'xp_alert_message_read_ids_v1';
  static const String alarmMutedUntilKey = 'training_plan_alarm_muted_until_v1';
  static const String inactivityReminderIdsKey =
      'training_inactivity_notification_ids_v1';
  static const String lastTrainingLogAtKey = 'last_training_log_at_v1';

  static const String _androidChannelId = 'training_plan_reminders';
  static const String _androidChannelIdVibrate =
      'training_plan_reminders_vibrate';
  static const String _androidRoutineChannelId = 'training_routine_alerts';
  static const String _androidChannelName = 'Training Plan Reminders';
  static const String _androidChannelDescription =
      'Reminder notifications before scheduled training plans';
  static const String _androidRoutineChannelName = 'Training Routine Alerts';
  static const String _androidRoutineChannelDescription =
      'Level-up and inactivity reminders for training consistency';
  static final Int64List _vibrationPattern = Int64List.fromList(<int>[
    0,
    250,
    120,
    250,
  ]);

  final OptionRepository _options;
  final SettingsService _settings;
  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialized = false;

  TrainingPlanReminderService(
    this._options,
    this._settings, {
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb) {
      _initialized = true;
      return;
    }
    tz.initializeTimeZones();
    try {
      final tzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      // Keep timezone default if local timezone lookup fails.
    }

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(initSettings);

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description: _androidChannelDescription,
        importance: Importance.high,
        enableVibration: false,
      ),
    );
    await androidImpl?.createNotificationChannel(
      AndroidNotificationChannel(
        _androidChannelIdVibrate,
        _androidChannelName,
        description: _androidChannelDescription,
        importance: Importance.high,
        enableVibration: true,
        vibrationPattern: _vibrationPattern,
      ),
    );
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _androidRoutineChannelId,
        _androidRoutineChannelName,
        description: _androidRoutineChannelDescription,
        importance: Importance.high,
        enableVibration: true,
      ),
    );
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();

    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<void> syncFromStorage() async {
    final raw = _options.getValue<String>(plansStorageKey);
    if (raw == null || raw.isEmpty) {
      await clearAllPlanReminders();
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        await clearAllPlanReminders();
        return;
      }
      final plans = decoded
          .whereType<Map>()
          .map((m) => m.cast<String, dynamic>())
          .toList(growable: false);
      await syncFromPlans(plans);
    } catch (_) {
      await clearAllPlanReminders();
    }
  }

  Future<void> syncFromPlans(List<Map<String, dynamic>> plans) async {
    await initialize();
    if (kIsWeb) return;
    await clearAllPlanReminders();
    if (!_settings.reminderEnabled) return;
    if (await isAlarmMutedNow()) return;

    final now = DateTime.now();
    final scheduledIds = <int>[];

    for (final raw in plans) {
      final plan = _PlanLite.fromMap(raw);
      final notifications = _buildNotifications(plan, now);
      if (notifications.isEmpty) continue;

      for (var i = 0; i < notifications.length; i++) {
        final item = notifications[i];
        final id = _notificationIdForPlan(
          plan.id,
          slot: item.at.millisecondsSinceEpoch ^ i,
        );
        const title = 'SoccerNote';
        final body = item.atStartTime
            ? 'Training starts now: ${plan.category}'
            : (plan.reminderMinutesBefore <= 0
                ? 'Training starts now: ${plan.category}'
                : 'Training in ${plan.reminderMinutesBefore} min: ${plan.category}');
        try {
          final vibrationEnabled = _settings.reminderVibrationEnabled;
          await _plugin.zonedSchedule(
            id,
            title,
            body,
            item.at,
            NotificationDetails(
              android: AndroidNotificationDetails(
                vibrationEnabled ? _androidChannelIdVibrate : _androidChannelId,
                _androidChannelName,
                channelDescription: _androidChannelDescription,
                importance: Importance.high,
                priority: Priority.high,
                enableVibration: vibrationEnabled,
                vibrationPattern: vibrationEnabled ? _vibrationPattern : null,
              ),
              iOS: const DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: plan.id,
            matchDateTimeComponents:
                item.repeatsWeekly ? DateTimeComponents.dayOfWeekAndTime : null,
          );
          scheduledIds.add(id);
        } catch (_) {
          // Keep syncing the rest of reminders even if one schedule fails.
        }
      }
    }

    await _options.setValue(reminderIdsKey, scheduledIds);
    final readIdsRaw = _options.getValue<List>(reminderReadIdsKey) ?? const [];
    final readIds = readIdsRaw
        .map((e) => (e as num?)?.toInt() ?? -1)
        .where((id) => id >= 0)
        .toSet();
    final active = scheduledIds.toSet();
    final pruned = readIds.where(active.contains).toList(growable: false);
    await _options.setValue(reminderReadIdsKey, pruned);
  }

  Future<void> syncInactivityReminder() async {
    await initialize();
    if (kIsWeb) return;
    await _clearNotificationIds(inactivityReminderIdsKey);
    if (!_settings.reminderEnabled || !_settings.inactivityAlertEnabled) return;

    final lastLoggedAt = DateTime.tryParse(
      _options.getValue<String>(lastTrainingLogAtKey) ?? '',
    );
    if (lastLoggedAt == null) return;

    final now = DateTime.now();
    final lastDay = DateTime(
      lastLoggedAt.year,
      lastLoggedAt.month,
      lastLoggedAt.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    final daysSince = today.difference(lastDay).inDays;
    if (daysSince < _settings.inactivityAlertDays) return;

    final reminderTime = _settings.reminderTime;
    var scheduledAt = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      reminderTime.hour,
      reminderTime.minute,
    );
    if (!scheduledAt.isAfter(tz.TZDateTime.now(tz.local))) {
      scheduledAt = scheduledAt.add(const Duration(days: 1));
    }
    final id = _notificationIdForScope(
      'habit',
      '${_settings.inactivityAlertDays}:${scheduledAt.year}${scheduledAt.month}${scheduledAt.day}',
    );
    try {
      await _plugin.zonedSchedule(
        id,
        'SoccerNote',
        'It has been a while since your last training log.',
        scheduledAt,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidRoutineChannelId,
            _androidRoutineChannelName,
            channelDescription: _androidRoutineChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: _settings.reminderVibrationEnabled,
            vibrationPattern:
                _settings.reminderVibrationEnabled ? _vibrationPattern : null,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'habit:$daysSince',
      );
      await _options.setValue(inactivityReminderIdsKey, <int>[id]);
    } catch (_) {
      await _options.setValue(inactivityReminderIdsKey, <int>[]);
    }
  }

  Future<void> syncAll({
    required List<TrainingEntry> entries,
    List<Map<String, dynamic>>? plans,
  }) async {
    await syncFromPlans(plans ?? loadPlansFromStorage());
    await syncInactivityFromEntries(entries);
  }

  Future<void> syncSettingsDrivenReminders() async {
    await syncFromPlans(loadPlansFromStorage());
    await syncInactivityReminder();
  }

  List<Map<String, dynamic>> loadPlansFromStorage() {
    final raw = _options.getValue<String>(plansStorageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> syncInactivityFromEntries(List<TrainingEntry> entries) async {
    final trainingEntries =
        entries.where((entry) => !entry.isMatch).toList(growable: false);
    if (trainingEntries.isEmpty) {
      await _options.setValue(lastTrainingLogAtKey, '');
      await _clearNotificationIds(inactivityReminderIdsKey);
      return;
    }
    trainingEntries.sort(TrainingEntry.compareByRecentCreated);
    await _options.setValue(
      lastTrainingLogAtKey,
      trainingEntries.first.createdAt.toIso8601String(),
    );
    await syncInactivityReminder();
  }

  Future<void> recordTrainingLog(DateTime loggedAt) async {
    await _options.setValue(lastTrainingLogAtKey, loggedAt.toIso8601String());
    await syncInactivityReminder();
  }

  Future<void> showLevelUpAlert({
    required int level,
    required bool isKo,
  }) async {
    await initialize();
    if (kIsWeb) return;
    if (!_settings.reminderEnabled || !_settings.levelUpAlertEnabled) return;
    if (!await hasNotificationPermission()) return;

    final id = _notificationIdForScope(
      'levelup',
      '$level:${DateTime.now().millisecondsSinceEpoch}',
    );
    try {
      await _plugin.show(
        id,
        'SoccerNote',
        isKo
            ? '레벨 $level 달성! 계속 훈련해요.'
            : 'Reached level $level. Keep training.',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidRoutineChannelId,
            _androidRoutineChannelName,
            channelDescription: _androidRoutineChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: _settings.reminderVibrationEnabled,
            vibrationPattern:
                _settings.reminderVibrationEnabled ? _vibrationPattern : null,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: 'levelup:$level',
      );
    } catch (_) {
      // Ignore immediate notification failures.
    }
  }

  Future<void> showXpGainAlert({
    required int gainedXp,
    required int totalXp,
    required bool isKo,
    String? sourceLabel,
  }) async {
    await initialize();
    if (kIsWeb) return;
    if (gainedXp <= 0) return;
    if (!_settings.reminderEnabled || !_settings.xpAlertEnabled) return;

    final label = sourceLabel?.trim() ?? '';
    final messageId = 'xp:${DateTime.now().microsecondsSinceEpoch}:$totalXp';
    await _appendXpMessageLog(
      id: messageId,
      gainedXp: gainedXp,
      totalXp: totalXp,
      label: label,
    );
    if (!await hasNotificationPermission()) return;
    final body = isKo
        ? '${label.isEmpty ? '경험치' : label} +$gainedXp XP · 누적 $totalXp XP'
        : '${label.isEmpty ? 'XP' : label} +$gainedXp XP · total $totalXp XP';
    final id = _notificationIdForScope(
      'xp',
      '$totalXp:${DateTime.now().millisecondsSinceEpoch}',
    );
    try {
      await _plugin.show(
        id,
        'SoccerNote',
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidRoutineChannelId,
            _androidRoutineChannelName,
            channelDescription: _androidRoutineChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: _settings.reminderVibrationEnabled,
            vibrationPattern:
                _settings.reminderVibrationEnabled ? _vibrationPattern : null,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: 'xp:$totalXp',
      );
    } catch (_) {
      // Ignore immediate notification failures.
    }
  }

  Future<void> _appendXpMessageLog({
    required String id,
    required int gainedXp,
    required int totalXp,
    required String label,
  }) async {
    final logs = loadXpMessageLogSync().toList(growable: true);
    logs.insert(0, {
      'id': id,
      'createdAt': DateTime.now().toIso8601String(),
      'gainedXp': gainedXp,
      'totalXp': totalXp,
      'label': label,
    });
    if (logs.length > 200) {
      logs.removeRange(200, logs.length);
    }
    await _options.setValue(xpMessageLogKey, logs);
  }

  List<_PendingPlanNotification> _buildNotifications(
    _PlanLite plan,
    DateTime now,
  ) {
    final tzNow = tz.TZDateTime.from(now, tz.local);
    final reminderOffset = Duration(minutes: plan.reminderMinutesBefore);
    if (plan.isConcreteOccurrence) {
      final result = <_PendingPlanNotification>[];
      final reminderAt = tz.TZDateTime.from(
        plan.scheduledAt.subtract(reminderOffset),
        tz.local,
      );
      if (reminderAt.isAfter(tzNow)) {
        result.add(
          _PendingPlanNotification(at: reminderAt, atStartTime: false),
        );
      }
      final startAt = tz.TZDateTime.from(plan.scheduledAt, tz.local);
      if (plan.alarmLoopEnabled && startAt.isAfter(tzNow)) {
        result.add(_PendingPlanNotification(at: startAt, atStartTime: true));
      }
      return result;
    }

    final result = <_PendingPlanNotification>[];
    for (final weekday in plan.repeatWeekdays) {
      final nextReminderAt = _nextWeekdayTime(
        tzNow,
        weekday: weekday,
        hour: plan.scheduledAt.hour,
        minute: plan.scheduledAt.minute,
      ).subtract(reminderOffset);
      result.add(
        _PendingPlanNotification(
          at: nextReminderAt.isAfter(tzNow)
              ? nextReminderAt
              : nextReminderAt.add(const Duration(days: 7)),
          repeatsWeekly: true,
          atStartTime: false,
        ),
      );
      if (!plan.alarmLoopEnabled) continue;
      final nextStartAt = _nextWeekdayTime(
        tzNow,
        weekday: weekday,
        hour: plan.scheduledAt.hour,
        minute: plan.scheduledAt.minute,
      );
      result.add(
        _PendingPlanNotification(
          at: nextStartAt.isAfter(tzNow)
              ? nextStartAt
              : nextStartAt.add(const Duration(days: 7)),
          repeatsWeekly: true,
          atStartTime: true,
        ),
      );
    }
    return result;
  }

  tz.TZDateTime _nextWeekdayTime(
    tz.TZDateTime now, {
    required int weekday,
    required int hour,
    required int minute,
  }) {
    final todayTarget = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    final delta = (weekday - now.weekday + 7) % 7;
    final candidate = todayTarget.add(Duration(days: delta));
    if (candidate.isAfter(now)) return candidate;
    return candidate.add(const Duration(days: 7));
  }

  Future<bool> hasNotificationPermission() async {
    await initialize();
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await androidImpl?.areNotificationsEnabled() ?? true;
      case TargetPlatform.iOS:
        final iosImpl = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final permissions = await iosImpl?.checkPermissions();
        return permissions?.isEnabled ?? false;
      default:
        return true;
    }
  }

  Future<bool> requestNotificationPermission() async {
    await initialize();
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.requestNotificationsPermission();
        return await androidImpl?.areNotificationsEnabled() ?? true;
      case TargetPlatform.iOS:
        final iosImpl = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        await iosImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        final permissions = await iosImpl?.checkPermissions();
        return permissions?.isEnabled ?? false;
      default:
        return true;
    }
  }

  Future<List<PendingNotificationRequest>> pendingReminders() async {
    await initialize();
    if (kIsWeb) return const <PendingNotificationRequest>[];
    return _plugin.pendingNotificationRequests();
  }

  Future<bool> isAlarmMutedNow() async {
    final raw = _options.getValue<String>(alarmMutedUntilKey);
    if (raw == null || raw.isEmpty) return false;
    final until = DateTime.tryParse(raw);
    if (until == null) return false;
    return until.isAfter(DateTime.now());
  }

  Future<void> muteAlarmsUntil(DateTime until) async {
    await _options.setValue(alarmMutedUntilKey, until.toIso8601String());
    await clearAllPlanReminders();
  }

  Future<void> clearAlarmMute() async {
    await _options.setValue(alarmMutedUntilKey, '');
  }

  Future<void> clearAllPlanReminders() async {
    await initialize();
    if (kIsWeb) return;
    await _clearNotificationIds(reminderIdsKey);
    await _options.setValue(reminderReadIdsKey, <int>[]);
  }

  int unreadReminderCountSync() {
    final scheduledRaw = _options.getValue<List>(reminderIdsKey) ?? const [];
    final readRaw = _options.getValue<List>(reminderReadIdsKey) ?? const [];
    final scheduled = scheduledRaw
        .map((e) => (e as num?)?.toInt() ?? -1)
        .where((id) => id >= 0)
        .toSet();
    final read = readRaw
        .map((e) => (e as num?)?.toInt() ?? -1)
        .where((id) => id >= 0)
        .toSet();
    final reminderUnread = scheduled.difference(read).length;
    final xpLogs = _options.getValue<List>(xpMessageLogKey) ?? const [];
    final xpReadRaw = _options.getValue<List>(xpMessageReadIdsKey) ?? const [];
    final xpReadIds = xpReadRaw.map((e) => e.toString()).toSet();
    final xpUnread = xpLogs.whereType<Map>().where((item) {
      final id = item['id']?.toString() ?? '';
      if (id.isEmpty) return false;
      return !xpReadIds.contains(id);
    }).length;
    return reminderUnread + xpUnread;
  }

  Future<void> markAllRemindersRead() async {
    final scheduledRaw = _options.getValue<List>(reminderIdsKey) ?? const [];
    final scheduled = scheduledRaw
        .map((e) => (e as num?)?.toInt() ?? -1)
        .where((id) => id >= 0)
        .toList(growable: false);
    await _options.setValue(reminderReadIdsKey, scheduled);
    final xpLogs = _options.getValue<List>(xpMessageLogKey) ?? const [];
    final xpIds = xpLogs
        .whereType<Map>()
        .map((item) => item['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    await _options.setValue(xpMessageReadIdsKey, xpIds);
  }

  List<String> dismissedMessageKeysSync() {
    final raw = _options.getValue<List>(dismissedMessageKeysKey) ?? const [];
    return raw.map((e) => e.toString()).toSet().toList(growable: false);
  }

  Future<void> dismissMessageKey(String key) async {
    final current = dismissedMessageKeysSync().toSet();
    current.add(key);
    await _options.setValue(
      dismissedMessageKeysKey,
      current.toList(growable: false),
    );
  }

  Future<void> clearDismissedMessageKeys() async {
    await _options.setValue(dismissedMessageKeysKey, <String>[]);
  }

  List<Map<String, dynamic>> loadXpMessageLogSync() {
    final raw = _options.getValue<List>(xpMessageLogKey) ?? const [];
    final logs = raw
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false)
      ..sort((a, b) {
        final aAt = DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bAt = DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bAt.compareTo(aAt);
      });
    return logs;
  }

  Future<void> deleteXpMessage(String id) async {
    final logs = loadXpMessageLogSync()
        .where((item) => (item['id']?.toString() ?? '') != id)
        .toList(growable: false);
    await _options.setValue(xpMessageLogKey, logs);
    final readRaw = _options.getValue<List>(xpMessageReadIdsKey) ?? const [];
    final readIds = readRaw.map((e) => e.toString()).toSet()..remove(id);
    await _options.setValue(
      xpMessageReadIdsKey,
      readIds.toList(growable: false),
    );
  }

  Future<void> _clearNotificationIds(String key) async {
    final ids = _options.getValue<List>(key) ?? const [];
    for (final rawId in ids) {
      final id = (rawId is num) ? rawId.toInt() : int.tryParse('$rawId');
      if (id == null) continue;
      await _plugin.cancel(id);
    }
    await _options.setValue(key, <int>[]);
  }

  int _notificationIdForPlan(String planId, {required int slot}) {
    var hash = 17;
    for (final code in planId.codeUnits) {
      hash = 37 * hash + code;
    }
    hash = 37 * hash + slot;
    return hash & 0x7fffffff;
  }

  int _notificationIdForScope(String scope, String value) {
    var hash = 23;
    for (final code in '$scope:$value'.codeUnits) {
      hash = 41 * hash + code;
    }
    return hash & 0x7fffffff;
  }
}

class _PendingPlanNotification {
  final tz.TZDateTime at;
  final bool repeatsWeekly;
  final bool atStartTime;

  const _PendingPlanNotification({
    required this.at,
    this.repeatsWeekly = false,
    required this.atStartTime,
  });
}

class _PlanLite {
  final String id;
  final DateTime scheduledAt;
  final String category;
  final int reminderMinutesBefore;
  final List<int> repeatWeekdays;
  final bool alarmLoopEnabled;
  final String? seriesId;

  const _PlanLite({
    required this.id,
    required this.scheduledAt,
    required this.category,
    required this.reminderMinutesBefore,
    required this.repeatWeekdays,
    required this.alarmLoopEnabled,
    this.seriesId,
  });

  bool get isConcreteOccurrence =>
      repeatWeekdays.isEmpty || (seriesId?.trim().isNotEmpty ?? false);

  factory _PlanLite.fromMap(Map<String, dynamic> map) {
    final repeatWeekdays = ((map['repeatWeekdays'] as List?) ?? const [])
        .map((e) => (e as num?)?.toInt() ?? 0)
        .where((v) => v >= DateTime.monday && v <= DateTime.sunday)
        .toSet()
        .toList(growable: false)
      ..sort();
    return _PlanLite(
      id: map['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      scheduledAt: DateTime.tryParse(map['scheduledAt']?.toString() ?? '') ??
          DateTime.now(),
      category: map['category']?.toString() ?? '',
      reminderMinutesBefore:
          (map['reminderMinutesBefore'] as num?)?.toInt() ?? 30,
      repeatWeekdays: repeatWeekdays,
      alarmLoopEnabled: (map['alarmLoopEnabled'] as bool?) ?? true,
      seriesId: map['seriesId']?.toString(),
    );
  }
}
