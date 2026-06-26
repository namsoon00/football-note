import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Locale, TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../domain/repositories/option_repository.dart';
import 'notification_app_link.dart';
import 'settings_service.dart';
import 'training_plan_reminder_service.dart';

class WeatherReminderService {
  static void Function(String? payload)? onNotificationPayloadTap;

  static const String reminderIdsKey = 'weather_reminder_ids_v1';
  static const String messageLogKey = 'weather_message_log_v1';
  static const String messageReadIdsKey = 'weather_message_read_ids_v1';
  static const String _localeOptionKey = 'locale';
  static const String _androidChannelId = 'weather_reminders';

  final OptionRepository _options;
  final SettingsService _settings;
  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialized = false;

  WeatherReminderService(
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
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        onNotificationPayloadTap?.call(response.payload);
      },
    );

    final l10n = _localizations();
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      AndroidNotificationChannel(
        _androidChannelId,
        l10n.weatherNotificationChannelName,
        description: l10n.weatherNotificationChannelDescription,
        importance: Importance.high,
        enableVibration: _settings.reminderVibrationEnabled,
      ),
    );
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();

    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<String?> launchPayload() async {
    await initialize();
    if (kIsWeb) return null;
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return details?.notificationResponse?.payload;
  }

  Future<int> syncSettingsDrivenReminders() async {
    await clearAllReminders(clearMessages: false);
    if (kIsWeb ||
        !_settings.reminderEnabled ||
        !_settings.weatherAlertEnabled ||
        await _isAlarmMutedNow()) {
      await _replaceWeatherMessages(const <Map<String, dynamic>>[]);
      return 0;
    }

    await initialize();
    final l10n = _localizations();
    final scheduledAt = _nextDailyTime(_settings.weatherAlertTime);
    final payload = NotificationAppLink.weatherToday();
    final id = _notificationIdForScope('weather_daily', 'today');
    final body = l10n.weatherNotificationDailyBody;
    try {
      await _scheduleDailyReminder(
        id: id,
        title: l10n.notificationAppTitle,
        body: body,
        scheduledAt: scheduledAt,
        payload: payload,
      );
      await _options.setValue(reminderIdsKey, <int>[id]);
      await _replaceWeatherMessages([
        {
          'id': payload,
          'payload': payload,
          'createdAt': DateTime.now().toIso8601String(),
          'scheduledAt': scheduledAt.toIso8601String(),
          'title': l10n.homeWeatherTitle,
          'body': body,
          'action': 'today',
        },
      ]);
      return 1;
    } catch (error) {
      debugPrint('Weather reminder schedule failed: $error');
      await _options.setValue(reminderIdsKey, <int>[]);
      await _replaceWeatherMessages(const <Map<String, dynamic>>[]);
      return 0;
    }
  }

  Future<void> clearAllReminders({bool clearMessages = true}) async {
    final hasIds = _hasStoredNotificationIds();
    if (!hasIds) {
      await _options.setValue(reminderIdsKey, <int>[]);
      if (clearMessages) {
        await _replaceWeatherMessages(const <Map<String, dynamic>>[]);
      }
      return;
    }
    await initialize();
    if (!kIsWeb) {
      await _clearNotificationIds();
    } else {
      await _options.setValue(reminderIdsKey, <int>[]);
    }
    if (clearMessages) {
      await _replaceWeatherMessages(const <Map<String, dynamic>>[]);
    }
  }

  int unreadWeatherMessageCountSync() {
    final logs = _options.getValue<List>(messageLogKey) ?? const [];
    final readRaw = _options.getValue<List>(messageReadIdsKey) ?? const [];
    final readIds = readRaw.map((e) => e.toString()).toSet();
    return logs.whereType<Map>().where((item) {
      final id = item['id']?.toString() ?? '';
      if (id.isEmpty) return false;
      return !readIds.contains(id);
    }).length;
  }

  Future<void> markAllWeatherMessagesRead() async {
    final ids = loadWeatherMessageLogSync()
        .map((item) => item['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    await _options.setValue(messageReadIdsKey, ids);
  }

  List<Map<String, dynamic>> loadWeatherMessageLogSync() {
    final raw = _options.getValue<List>(messageLogKey) ?? const [];
    final logs = raw
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false)
      ..sort((a, b) {
        final aAt = DateTime.tryParse(a['scheduledAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bAt = DateTime.tryParse(b['scheduledAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return aAt.compareTo(bAt);
      });
    return logs;
  }

  Future<void> deleteWeatherMessage(String id) async {
    final logs = loadWeatherMessageLogSync()
        .where((item) => (item['id']?.toString() ?? '') != id)
        .toList(growable: false);
    await _options.setValue(messageLogKey, logs);
    final readRaw = _options.getValue<List>(messageReadIdsKey) ?? const [];
    final readIds = readRaw.map((e) => e.toString()).toSet()..remove(id);
    await _options.setValue(
      messageReadIdsKey,
      readIds.toList(growable: false),
    );
  }

  Future<void> _scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledAt,
    required String payload,
  }) async {
    final l10n = _localizations();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelId,
        l10n.weatherNotificationChannelName,
        channelDescription: l10n.weatherNotificationChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: _settings.reminderVibrationEnabled,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    Future<void> schedule(AndroidScheduleMode mode) {
      return _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledAt,
        details,
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    try {
      await schedule(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (_) {
      await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<void> _replaceWeatherMessages(
    List<Map<String, dynamic>> nextRows,
  ) async {
    final rows = nextRows.toList(growable: false);
    await _options.setValue(messageLogKey, rows);
    final activeIds = rows
        .map((item) => item['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    final readRaw = _options.getValue<List>(messageReadIdsKey) ?? const [];
    final readIds = readRaw
        .map((e) => e.toString())
        .where(activeIds.contains)
        .toList(growable: false);
    await _options.setValue(messageReadIdsKey, readIds);
  }

  Future<void> _clearNotificationIds() async {
    final ids = _options.getValue<List>(reminderIdsKey) ?? const [];
    for (final rawId in ids) {
      final id = (rawId is num) ? rawId.toInt() : int.tryParse('$rawId');
      if (id == null) continue;
      await _plugin.cancel(id);
    }
    await _options.setValue(reminderIdsKey, <int>[]);
  }

  bool _hasStoredNotificationIds() {
    final ids = _options.getValue<List>(reminderIdsKey) ?? const [];
    return ids.any((rawId) {
      if (rawId is num) return rawId.toInt() >= 0;
      return int.tryParse('$rawId') != null;
    });
  }

  Future<bool> _isAlarmMutedNow() async {
    final raw = _options.getValue<String>(
      TrainingPlanReminderService.alarmMutedUntilKey,
    );
    if (raw == null || raw.isEmpty) return false;
    final until = DateTime.tryParse(raw);
    if (until == null) return false;
    return until.isAfter(DateTime.now());
  }

  tz.TZDateTime _nextDailyTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledAt = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!scheduledAt.isAfter(now)) {
      scheduledAt = scheduledAt.add(const Duration(days: 1));
    }
    return scheduledAt;
  }

  AppLocalizations _localizations() {
    final languageCode = _options
        .getOptions(_localeOptionKey, const <String>[])
        .firstOrNull
        ?.trim()
        .toLowerCase();
    final locale = switch (languageCode) {
      'en' => const Locale('en'),
      'ja' => const Locale('ja'),
      _ => const Locale('ko'),
    };
    return lookupAppLocalizations(locale);
  }

  int _notificationIdForScope(String scope, String value) {
    var hash = 23;
    for (final code in '$scope:$value'.codeUnits) {
      hash = 41 * hash + code;
    }
    return hash & 0x7fffffff;
  }
}
