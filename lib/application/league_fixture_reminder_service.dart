import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../domain/entities/league_standings.dart';
import '../domain/repositories/option_repository.dart';
import 'settings_service.dart';

class LeagueFixtureReminderService {
  static const String favoriteTeamKeysKey =
      'league_fixture_favorite_team_keys_v1';
  static const String reminderIdsKey = 'league_fixture_reminder_ids_v1';
  static const String _androidChannelId = 'league_fixture_reminders';

  final OptionRepository _options;
  final SettingsService _settings;
  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialized = false;

  LeagueFixtureReminderService(
    this._options,
    this._settings, {
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static String teamKey(LeagueStandingsType type, String teamName) {
    return '${type.name}:${_normalizeTeamName(teamName)}';
  }

  Set<String> favoriteTeamKeysSync() {
    final raw = _options.getValue<List>(favoriteTeamKeysKey) ?? const [];
    return raw
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  Future<void> saveFavoriteTeamKeys(Set<String> keys) async {
    final sorted = keys.where((key) => key.trim().isNotEmpty).toList()..sort();
    await _options.setValue(favoriteTeamKeysKey, sorted);
  }

  Future<int> syncReminders({
    required Iterable<LeagueFixtureSnapshot> snapshots,
    required String title,
    required String androidChannelName,
    required String androidChannelDescription,
    required String Function(
      LeagueFixtureEntry entry,
      String teamName,
      String opponentName,
    )
    bodyBuilder,
    Duration reminderOffset = const Duration(hours: 2),
    DateTime? now,
  }) async {
    await clearAllReminders();
    final favoriteKeys = favoriteTeamKeysSync();
    if (favoriteKeys.isEmpty || !_settings.reminderEnabled || kIsWeb) {
      return 0;
    }

    await initialize();
    await _ensureNotificationChannel(
      name: androidChannelName,
      description: androidChannelDescription,
    );

    final tzNow = tz.TZDateTime.from(now ?? DateTime.now(), tz.local);
    final scheduledIds = <int>[];
    final seenFixtureKeys = <String>{};

    for (final snapshot in snapshots) {
      for (final entry in snapshot.entries) {
        if (entry.status != LeagueFixtureStatus.scheduled) continue;
        final favoriteMatch = _favoriteMatch(
          type: snapshot.type,
          entry: entry,
          favoriteKeys: favoriteKeys,
        );
        if (favoriteMatch == null) continue;
        final fixtureKey =
            '${snapshot.type.name}:${entry.id}:${favoriteMatch.teamKey}';
        if (!seenFixtureKeys.add(fixtureKey)) continue;

        final kickoffAt = tz.TZDateTime.from(entry.kickoffAt, tz.local);
        var scheduledAt = kickoffAt.subtract(reminderOffset);
        if (!scheduledAt.isAfter(tzNow)) {
          scheduledAt = kickoffAt;
        }
        if (!scheduledAt.isAfter(tzNow)) continue;

        final id = _notificationIdForScope('league_fixture', fixtureKey);
        try {
          await _scheduleZonedReminder(
            id: id,
            title: title,
            androidChannelName: androidChannelName,
            androidChannelDescription: androidChannelDescription,
            body: bodyBuilder(
              entry,
              favoriteMatch.teamName,
              favoriteMatch.opponentName,
            ),
            scheduledAt: scheduledAt,
            payload: fixtureKey,
          );
          scheduledIds.add(id);
        } catch (error) {
          debugPrint('League fixture reminder failed for $fixtureKey: $error');
        }
      }
    }

    await _options.setValue(reminderIdsKey, scheduledIds);
    return scheduledIds.length;
  }

  Future<void> clearAllReminders() async {
    if (!_hasStoredNotificationIds()) {
      await _options.setValue(reminderIdsKey, <int>[]);
      return;
    }
    await initialize();
    if (kIsWeb) {
      await _options.setValue(reminderIdsKey, <int>[]);
      return;
    }
    await _clearNotificationIds();
  }

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
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();

    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<void> _ensureNotificationChannel({
    required String name,
    required String description,
  }) async {
    if (kIsWeb) return;
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.createNotificationChannel(
      AndroidNotificationChannel(
        _androidChannelId,
        name,
        description: description,
        importance: Importance.high,
        enableVibration: _settings.reminderVibrationEnabled,
      ),
    );
  }

  Future<void> _scheduleZonedReminder({
    required int id,
    required String title,
    required String androidChannelName,
    required String androidChannelDescription,
    required String body,
    required tz.TZDateTime scheduledAt,
    required String payload,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelId,
        androidChannelName,
        channelDescription: androidChannelDescription,
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
      );
    }

    try {
      await schedule(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (_) {
      await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
    }
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

  _LeagueFavoriteMatch? _favoriteMatch({
    required LeagueStandingsType type,
    required LeagueFixtureEntry entry,
    required Set<String> favoriteKeys,
  }) {
    final homeKey = teamKey(type, entry.homeTeamName);
    if (favoriteKeys.contains(homeKey)) {
      return _LeagueFavoriteMatch(
        teamKey: homeKey,
        teamName: entry.homeTeamName,
        opponentName: entry.awayTeamName,
      );
    }
    final awayKey = teamKey(type, entry.awayTeamName);
    if (favoriteKeys.contains(awayKey)) {
      return _LeagueFavoriteMatch(
        teamKey: awayKey,
        teamName: entry.awayTeamName,
        opponentName: entry.homeTeamName,
      );
    }
    return null;
  }

  int _notificationIdForScope(String scope, String value) {
    var hash = 23;
    for (final code in '$scope:$value'.codeUnits) {
      hash = 41 * hash + code;
    }
    return hash & 0x7fffffff;
  }

  static String _normalizeTeamName(String value) {
    return value.trim().toLowerCase();
  }
}

class _LeagueFavoriteMatch {
  final String teamKey;
  final String teamName;
  final String opponentName;

  const _LeagueFavoriteMatch({
    required this.teamKey,
    required this.teamName,
    required this.opponentName,
  });
}
