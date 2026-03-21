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
  static const String alarmMutedUntilKey = 'training_plan_alarm_muted_until_v1';
  static const String wakeAlarmIdsKey = 'wake_alarm_notification_ids_v1';
  static const String inactivityReminderIdsKey =
      'training_inactivity_notification_ids_v1';
  static const String lastTrainingLogAtKey = 'last_training_log_at_v1';

  static const String _androidChannelId = 'training_plan_reminders';
  static const String _androidChannelIdVibrate =
      'training_plan_reminders_vibrate';
  static const String _androidWakeChannelId = 'training_wake_alarms';
  static const String _androidRoutineChannelId = 'training_routine_alerts';
  static const String _androidChannelName = 'Training Plan Reminders';
  static const String _androidChannelDescription =
      'Reminder notifications before scheduled training plans';
  static const String _androidWakeChannelName = 'Training Wake Alarms';
  static const String _androidWakeChannelDescription =
      'Repeated wake alarms for scheduled training routines';
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

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
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
        _androidWakeChannelId,
        _androidWakeChannelName,
        description: _androidWakeChannelDescription,
        importance: Importance.max,
        enableVibration: true,
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

    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
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
      final baseTimes = _buildBaseTimes(plan, now);
      if (baseTimes.isEmpty) continue;

      for (final baseAt in baseTimes) {
        final ringTimes = plan.alarmLoopEnabled
            ? List<tz.TZDateTime>.generate(
                16,
                (index) => baseAt.add(Duration(minutes: index * 2)),
              )
            : <tz.TZDateTime>[baseAt];
        for (var i = 0; i < ringTimes.length; i++) {
          final at = ringTimes[i];
          if (plan.repeatWeekdays.isEmpty &&
              !at.isAfter(tz.TZDateTime.now(tz.local))) {
            continue;
          }
          final id = _notificationIdForPlan(
            plan.id,
            slot: at.millisecondsSinceEpoch ^ i,
          );
          const title = 'SoccerNote';
          final body = plan.alarmLoopEnabled
              ? 'Training time: ${plan.category}'
              : (plan.reminderMinutesBefore <= 0
                    ? 'Training starts now: ${plan.category}'
                    : 'Training in ${plan.reminderMinutesBefore} min: ${plan.category}');
          try {
            final vibrationEnabled = _settings.reminderVibrationEnabled;
            await _plugin.zonedSchedule(
              id,
              title,
              body,
              at,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  vibrationEnabled
                      ? _androidChannelIdVibrate
                      : _androidChannelId,
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
              matchDateTimeComponents: plan.repeatWeekdays.isNotEmpty
                  ? DateTimeComponents.dayOfWeekAndTime
                  : null,
            );
            scheduledIds.add(id);
          } catch (_) {
            // Keep syncing the rest of reminders even if one schedule fails.
          }
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

  Future<void> syncWakeAlarms() async {
    await initialize();
    if (kIsWeb) return;
    await _clearNotificationIds(wakeAlarmIdsKey);
    if (!_settings.reminderEnabled || !_settings.wakeAlarmEnabled) return;
    if (await isAlarmMutedNow()) return;

    final scheduledIds = <int>[];
    final weekdays = _settings.wakeAlarmWeekdays;
    final repeatCount = _settings.wakeAlarmRepeatCount;
    final intervalMinutes = _settings.wakeAlarmRepeatIntervalMinutes;
    final baseTime = _settings.wakeAlarmTime;
    final now = tz.TZDateTime.now(tz.local);

    for (final weekday in weekdays) {
      for (var ring = 0; ring < repeatCount; ring++) {
        final minuteOffset = ring * intervalMinutes;
        final totalMinutes =
            baseTime.hour * 60 + baseTime.minute + minuteOffset;
        final hour = (totalMinutes ~/ 60) % 24;
        final minute = totalMinutes % 60;
        final dayShift = totalMinutes ~/ (24 * 60);
        final scheduledWeekday = ((weekday - 1 + dayShift) % 7) + 1;
        var next = _nextWeekdayTime(
          now,
          weekday: scheduledWeekday,
          hour: hour,
          minute: minute,
        );
        if (!next.isAfter(now)) {
          next = next.add(const Duration(days: 7));
        }
        final id = _notificationIdForScope(
          'wake',
          '$scheduledWeekday:$ring:$hour:$minute',
        );
        try {
          await _plugin.zonedSchedule(
            id,
            'SoccerNote',
            'Wake up for training.',
            next,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _androidWakeChannelId,
                _androidWakeChannelName,
                channelDescription: _androidWakeChannelDescription,
                importance: Importance.max,
                priority: Priority.high,
                enableVibration: true,
                vibrationPattern: _vibrationPattern,
              ),
              iOS: const DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.alarmClock,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: 'wake:$scheduledWeekday:$ring',
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
          scheduledIds.add(id);
        } catch (_) {
          // Keep scheduling the remaining wake alarms.
        }
      }
    }
    await _options.setValue(wakeAlarmIdsKey, scheduledIds);
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
            vibrationPattern: _settings.reminderVibrationEnabled
                ? _vibrationPattern
                : null,
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
    await syncWakeAlarms();
    await syncInactivityFromEntries(entries);
  }

  Future<void> syncSettingsDrivenReminders() async {
    await syncFromPlans(loadPlansFromStorage());
    await syncWakeAlarms();
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
    final trainingEntries = entries
        .where((entry) => !entry.isMatch)
        .toList(growable: false);
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
            vibrationPattern: _settings.reminderVibrationEnabled
                ? _vibrationPattern
                : null,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: 'levelup:$level',
      );
    } catch (_) {
      // Ignore immediate notification failures.
    }
  }

  List<tz.TZDateTime> _buildBaseTimes(_PlanLite plan, DateTime now) {
    final tzNow = tz.TZDateTime.from(now, tz.local);
    final reminderOffset = plan.alarmLoopEnabled
        ? Duration.zero
        : Duration(minutes: plan.reminderMinutesBefore);
    if (plan.repeatWeekdays.isEmpty) {
      final single = tz.TZDateTime.from(
        plan.scheduledAt.subtract(reminderOffset),
        tz.local,
      );
      return single.isAfter(tzNow) ? <tz.TZDateTime>[single] : const [];
    }
    final result = <tz.TZDateTime>[];
    for (final weekday in plan.repeatWeekdays) {
      final next = _nextWeekdayTime(
        tzNow,
        weekday: weekday,
        hour: plan.scheduledAt.hour,
        minute: plan.scheduledAt.minute,
      ).subtract(reminderOffset);
      if (next.isAfter(tzNow)) {
        result.add(next);
      } else {
        result.add(next.add(const Duration(days: 7)));
      }
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
        final androidImpl = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        return await androidImpl?.areNotificationsEnabled() ?? true;
      case TargetPlatform.iOS:
        final iosImpl = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
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
        final androidImpl = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        await androidImpl?.requestNotificationsPermission();
        return await androidImpl?.areNotificationsEnabled() ?? true;
      case TargetPlatform.iOS:
        final iosImpl = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
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
    return scheduled.difference(read).length;
  }

  Future<void> markAllRemindersRead() async {
    final scheduledRaw = _options.getValue<List>(reminderIdsKey) ?? const [];
    final scheduled = scheduledRaw
        .map((e) => (e as num?)?.toInt() ?? -1)
        .where((id) => id >= 0)
        .toList(growable: false);
    await _options.setValue(reminderReadIdsKey, scheduled);
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

class _PlanLite {
  final String id;
  final DateTime scheduledAt;
  final String category;
  final int reminderMinutesBefore;
  final List<int> repeatWeekdays;
  final bool alarmLoopEnabled;

  const _PlanLite({
    required this.id,
    required this.scheduledAt,
    required this.category,
    required this.reminderMinutesBefore,
    required this.repeatWeekdays,
    required this.alarmLoopEnabled,
  });

  factory _PlanLite.fromMap(Map<String, dynamic> map) {
    final repeatWeekdays =
        ((map['repeatWeekdays'] as List?) ?? const [])
            .map((e) => (e as num?)?.toInt() ?? 0)
            .where((v) => v >= DateTime.monday && v <= DateTime.sunday)
            .toSet()
            .toList(growable: false)
          ..sort();
    return _PlanLite(
      id:
          map['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      scheduledAt:
          DateTime.tryParse(map['scheduledAt']?.toString() ?? '') ??
          DateTime.now(),
      category: map['category']?.toString() ?? '',
      reminderMinutesBefore:
          (map['reminderMinutesBefore'] as num?)?.toInt() ?? 30,
      repeatWeekdays: repeatWeekdays,
      alarmLoopEnabled: (map['alarmLoopEnabled'] as bool?) ?? true,
    );
  }
}
