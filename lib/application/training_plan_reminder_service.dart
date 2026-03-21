import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../domain/repositories/option_repository.dart';
import 'settings_service.dart';

class TrainingPlanReminderService {
  static const String plansStorageKey = 'training_plans_v1';
  static const String reminderIdsKey = 'training_plan_reminder_ids_v1';
  static const String alarmMutedUntilKey = 'training_plan_alarm_muted_until_v1';

  static const String _androidChannelId = 'training_plan_reminders';
  static const String _androidChannelIdVibrate =
      'training_plan_reminders_vibrate';
  static const String _androidChannelName = 'Training Plan Reminders';
  static const String _androidChannelDescription =
      'Reminder notifications before scheduled training plans';
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
          final id = _notificationIdForPlan(plan.id,
              slot: at.millisecondsSinceEpoch ^ i);
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
            alert: true, badge: true, sound: true);
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
    final ids = _options.getValue<List>(reminderIdsKey) ?? const [];
    for (final rawId in ids) {
      final id = (rawId is num) ? rawId.toInt() : int.tryParse('$rawId');
      if (id == null) continue;
      await _plugin.cancel(id);
    }
    await _options.setValue(reminderIdsKey, <int>[]);
  }

  int _notificationIdForPlan(String planId, {required int slot}) {
    var hash = 17;
    for (final code in planId.codeUnits) {
      hash = 37 * hash + code;
    }
    hash = 37 * hash + slot;
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
    );
  }
}
