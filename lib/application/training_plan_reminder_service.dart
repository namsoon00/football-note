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

  static const String _androidChannelId = 'training_plan_reminders';
  static const String _androidChannelName = 'Training Plan Reminders';
  static const String _androidChannelDescription =
      'Reminder notifications before scheduled training plans';

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
      ),
    );
    await androidImpl?.requestNotificationsPermission();

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

    final now = DateTime.now();
    final scheduledIds = <int>[];

    for (final raw in plans) {
      final plan = _PlanLite.fromMap(raw);
      final reminderAt = plan.scheduledAt
          .subtract(Duration(minutes: plan.reminderMinutesBefore));
      if (!reminderAt.isAfter(now)) continue;

      final id = _notificationIdForPlan(plan.id);
      const title = 'SoccerNote';
      final body = kIsWeb
          ? 'Training starts soon: ${plan.category}'
          : 'Training in ${plan.reminderMinutesBefore} min: ${plan.category}';

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(reminderAt, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannelId,
            _androidChannelName,
            channelDescription: _androidChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: plan.id,
      );
      scheduledIds.add(id);
    }

    await _options.setValue(reminderIdsKey, scheduledIds);
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

  int _notificationIdForPlan(String planId) {
    var hash = 17;
    for (final code in planId.codeUnits) {
      hash = 37 * hash + code;
    }
    return hash & 0x7fffffff;
  }
}

class _PlanLite {
  final String id;
  final DateTime scheduledAt;
  final String category;
  final int reminderMinutesBefore;

  const _PlanLite({
    required this.id,
    required this.scheduledAt,
    required this.category,
    required this.reminderMinutesBefore,
  });

  factory _PlanLite.fromMap(Map<String, dynamic> map) {
    return _PlanLite(
      id: map['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      scheduledAt: DateTime.tryParse(map['scheduledAt']?.toString() ?? '') ??
          DateTime.now(),
      category: map['category']?.toString() ?? '',
      reminderMinutesBefore:
          (map['reminderMinutesBefore'] as num?)?.toInt() ?? 30,
    );
  }
}
