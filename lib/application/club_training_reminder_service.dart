import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Locale;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../domain/repositories/option_repository.dart';
import 'club_schedule_service.dart';
import 'notification_app_link.dart';
import 'settings_service.dart';
import 'sport_scoped_storage.dart';
import 'training_plan_reminder_service.dart';

class ClubTrainingReminderService {
  static void Function(String? payload)? onNotificationPayloadTap;

  static const String reminderIdsKey = 'club_training_reminder_ids_v1';
  static const String messageLogKey = 'club_training_message_log_v1';
  static const String messageReadIdsKey = 'club_training_message_read_ids_v1';
  static const String _localeOptionKey = 'locale';
  static const String _androidChannelId = 'club_training_reminders';

  final OptionRepository _options;
  final SettingsService _settings;
  final FlutterLocalNotificationsPlugin _plugin;
  final String? _sportId;

  bool _initialized = false;

  ClubTrainingReminderService(
    this._options,
    this._settings, {
    FlutterLocalNotificationsPlugin? plugin,
    String? sportId,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _sportId = sportId;

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
        l10n.clubTrainingNotificationChannelName,
        description: l10n.clubTrainingNotificationChannelDescription,
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
        !_settings.clubTrainingAlertEnabled ||
        await _isAlarmMutedNow()) {
      await _replaceClubTrainingMessages(const <Map<String, dynamic>>[]);
      return 0;
    }

    final profile = ClubScheduleService(
      _options,
      sportId: _sportId,
    ).loadProfile();
    final enabledSchedules = profile.weekdaySchedules
        .where((schedule) => schedule.enabled)
        .toList(growable: false);
    if (enabledSchedules.isEmpty) {
      await _replaceClubTrainingMessages(const <Map<String, dynamic>>[]);
      return 0;
    }

    await initialize();
    final l10n = _localizations();
    final minutesBefore = _settings.clubTrainingAlertMinutesBefore;
    final clubName = profile.clubName.trim().isEmpty
        ? l10n.clubScheduleTitle
        : profile.clubName.trim();
    final title = l10n.clubTrainingNotificationTitle(clubName);
    final sportId = currentSportIdForOptions(_options, sportId: _sportId);
    final now = DateTime.now();
    final scheduledIds = <int>[];
    final messages = <Map<String, dynamic>>[];

    for (final schedule in enabledSchedules) {
      final scheduledAt = _nextWeeklyReminderTime(
        schedule,
        minutesBefore: minutesBefore,
      );
      final payload = NotificationAppLink.clubTraining(
        weekday: schedule.weekday,
      );
      final id = _notificationIdForScope(
        'club_training',
        '$sportId:${schedule.weekday}',
      );
      final timeRange = _timeRange(schedule);
      final uniform = _uniformColorToken(schedule.uniformColorValue);
      final body = l10n.clubTrainingNotificationBody(
        minutesBefore,
        timeRange,
        uniform,
      );

      try {
        await _scheduleWeeklyReminder(
          id: id,
          title: title,
          body: body,
          scheduledAt: scheduledAt,
          payload: payload,
        );
      } catch (error) {
        debugPrint('Club training reminder schedule failed: $error');
        continue;
      }

      scheduledIds.add(id);
      messages.add({
        'id':
            'club:$sportId:${schedule.weekday}:${schedule.startMinutes}:${schedule.endMinutes}:${schedule.uniformColorValue}:$minutesBefore',
        'payload': payload,
        'createdAt': now.toIso8601String(),
        'scheduledAt': scheduledAt.toIso8601String(),
        'title': title,
        'body': body,
        'weekday': schedule.weekday,
        'time': timeRange,
        'uniform': uniform,
      });
    }

    await _options.setValue(reminderIdsKey, scheduledIds);
    await _replaceClubTrainingMessages(messages);
    return scheduledIds.length;
  }

  Future<void> clearAllReminders({bool clearMessages = true}) async {
    final hasIds = _hasStoredNotificationIds();
    if (!hasIds) {
      await _options.setValue(reminderIdsKey, <int>[]);
      if (clearMessages) {
        await _replaceClubTrainingMessages(const <Map<String, dynamic>>[]);
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
      await _replaceClubTrainingMessages(const <Map<String, dynamic>>[]);
    }
  }

  int unreadClubTrainingMessageCountSync() {
    final logs = _options.getValue<List>(messageLogKey) ?? const [];
    final readRaw = _options.getValue<List>(messageReadIdsKey) ?? const [];
    final readIds = readRaw.map((e) => e.toString()).toSet();
    return logs.whereType<Map>().where((item) {
      final id = item['id']?.toString() ?? '';
      if (id.isEmpty) return false;
      return !readIds.contains(id);
    }).length;
  }

  Future<void> markAllClubTrainingMessagesRead() async {
    final ids = loadClubTrainingMessageLogSync()
        .map((item) => item['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    await _options.setValue(messageReadIdsKey, ids);
  }

  List<Map<String, dynamic>> loadClubTrainingMessageLogSync() {
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

  Future<void> deleteClubTrainingMessage(String id) async {
    final logs = loadClubTrainingMessageLogSync()
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

  Future<void> _scheduleWeeklyReminder({
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
        l10n.clubTrainingNotificationChannelName,
        channelDescription: l10n.clubTrainingNotificationChannelDescription,
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
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }

    try {
      await schedule(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (_) {
      await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<void> _replaceClubTrainingMessages(
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

  tz.TZDateTime _nextWeeklyReminderTime(
    ClubTrainingSchedule schedule, {
    required int minutesBefore,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    final startHour = schedule.startMinutes ~/ 60;
    final startMinute = schedule.startMinutes % 60;
    final todayStart = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      startHour,
      startMinute,
    );
    final delta = (schedule.weekday - now.weekday + 7) % 7;
    final nextStart = todayStart.add(Duration(days: delta));
    var reminderAt = nextStart.subtract(Duration(minutes: minutesBefore));
    if (!reminderAt.isAfter(now)) {
      reminderAt = reminderAt.add(const Duration(days: 7));
    }
    return reminderAt;
  }

  String _timeRange(ClubTrainingSchedule schedule) {
    return '${_timeLabel(schedule.startMinutes)}-${_timeLabel(schedule.endMinutes)}';
  }

  String _timeLabel(int minutes) {
    final normalized = ClubScheduleService.normalizeMinutes(
      minutes,
      fallback: ClubTrainingSchedule.defaultStartMinutes,
    );
    final hour = (normalized ~/ 60).toString().padLeft(2, '0');
    final minute = (normalized % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _uniformColorToken(int colorValue) {
    final rgb = colorValue & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
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
