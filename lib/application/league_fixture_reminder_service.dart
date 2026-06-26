import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../domain/entities/league_standings.dart';
import '../domain/repositories/option_repository.dart';
import 'notification_app_link.dart';
import 'settings_service.dart';
import 'world_cup_schedule.dart';

class LeagueFixtureReminderService {
  static void Function(String? payload)? onNotificationPayloadTap;

  static const String favoriteTeamKeysKey =
      'league_fixture_favorite_team_keys_v1';
  static const String reminderIdsKey = 'league_fixture_reminder_ids_v1';
  static const String worldCupReminderIdsKey =
      'world_cup_fixture_reminder_ids_v1';
  static const String fixtureMessageLogKey = 'league_fixture_message_log_v1';
  static const String fixtureMessageReadIdsKey =
      'league_fixture_message_read_ids_v1';
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
    required String androidChannelName,
    required String androidChannelDescription,
    required String Function(
      LeagueFixtureEntry entry,
      String teamName,
      String opponentName,
    ) bodyBuilder,
    Duration reminderOffset = const Duration(hours: 2),
    DateTime? now,
  }) async {
    await clearAllReminders();
    final favoriteKeys = favoriteTeamKeysSync();
    if (favoriteKeys.isEmpty ||
        !_settings.reminderEnabled ||
        !_settings.leagueFixtureAlertEnabled ||
        kIsWeb) {
      await _replaceFixtureMessagesForKind(
        'league',
        const <Map<String, dynamic>>[],
      );
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
    final messageRows = <Map<String, dynamic>>[];

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
        final body = bodyBuilder(
          entry,
          favoriteMatch.teamName,
          favoriteMatch.opponentName,
        );
        final payload = NotificationAppLink.leagueFixture(
          leagueType: snapshot.type.name,
          fixtureKey: fixtureKey,
          kickoffAt: entry.kickoffAt,
        );
        try {
          await _scheduleZonedReminder(
            id: id,
            title: NotificationAppLink.notificationTitle,
            androidChannelName: androidChannelName,
            androidChannelDescription: androidChannelDescription,
            body: body,
            scheduledAt: scheduledAt,
            payload: payload,
          );
          scheduledIds.add(id);
          messageRows.add({
            'id': payload,
            'kind': 'league',
            'payload': payload,
            'createdAt': DateTime.now().toIso8601String(),
            'scheduledAt': scheduledAt.toIso8601String(),
            'kickoffAt': entry.kickoffAt.toIso8601String(),
            'title': NotificationAppLink.notificationTitle,
            'body': body,
            'leagueType': snapshot.type.name,
            'leagueName': snapshot.leagueName,
            'teamName': favoriteMatch.teamName,
            'opponentName': favoriteMatch.opponentName,
            'venue': entry.venue,
          });
        } catch (error) {
          debugPrint('League fixture reminder failed for $fixtureKey: $error');
        }
      }
    }

    await _options.setValue(reminderIdsKey, scheduledIds);
    await _replaceFixtureMessagesForKind('league', messageRows);
    return scheduledIds.length;
  }

  Future<void> clearAllReminders() async {
    if (!_hasStoredNotificationIds(reminderIdsKey)) {
      await _options.setValue(reminderIdsKey, <int>[]);
      return;
    }
    await initialize();
    if (kIsWeb) {
      await _options.setValue(reminderIdsKey, <int>[]);
      return;
    }
    await _clearNotificationIds(reminderIdsKey);
  }

  Future<int> syncWorldCupReminders({
    required Iterable<WorldCupFixture> fixtures,
    required Set<String> selectedCountries,
    required String androidChannelName,
    required String androidChannelDescription,
    required String Function(
      WorldCupFixture fixture,
      String teamName,
      String opponentName,
    ) bodyBuilder,
    Duration reminderOffset = const Duration(hours: 2),
    DateTime? now,
  }) async {
    await clearWorldCupReminders();
    final countries = selectedCountries
        .map((country) => country.trim())
        .where((country) => country.isNotEmpty)
        .toSet();
    if (countries.isEmpty ||
        !_settings.reminderEnabled ||
        !_settings.leagueFixtureAlertEnabled ||
        kIsWeb) {
      await _replaceFixtureMessagesForKind(
        'worldCup',
        const <Map<String, dynamic>>[],
      );
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
    final messageRows = <Map<String, dynamic>>[];
    for (final fixture in fixtures) {
      if (fixture.hasScore) continue;
      final match = _worldCupFavoriteMatch(fixture, countries);
      if (match == null) continue;
      final fixtureKey = 'worldcup:${fixture.matchNumber}:${match.teamName}';
      if (!seenFixtureKeys.add(fixtureKey)) continue;
      final kickoffAt = tz.TZDateTime.from(fixture.kickoffLocal, tz.local);
      var scheduledAt = kickoffAt.subtract(reminderOffset);
      if (!scheduledAt.isAfter(tzNow)) {
        scheduledAt = kickoffAt;
      }
      if (!scheduledAt.isAfter(tzNow)) continue;
      final id = _notificationIdForScope('world_cup_fixture', fixtureKey);
      final body = bodyBuilder(fixture, match.teamName, match.opponentName);
      final payload = NotificationAppLink.worldCupFixture(
        matchNumber: fixture.matchNumber,
        teamName: match.teamName,
        kickoffAt: fixture.kickoffLocal,
      );
      try {
        await _scheduleZonedReminder(
          id: id,
          title: NotificationAppLink.notificationTitle,
          androidChannelName: androidChannelName,
          androidChannelDescription: androidChannelDescription,
          body: body,
          scheduledAt: scheduledAt,
          payload: payload,
        );
        scheduledIds.add(id);
        messageRows.add({
          'id': payload,
          'kind': 'worldCup',
          'payload': payload,
          'createdAt': DateTime.now().toIso8601String(),
          'scheduledAt': scheduledAt.toIso8601String(),
          'kickoffAt': fixture.kickoffLocal.toIso8601String(),
          'title': NotificationAppLink.notificationTitle,
          'body': body,
          'leagueType': 'worldCup',
          'leagueName': 'FIFA World Cup 2026',
          'teamName': match.teamName,
          'opponentName': match.opponentName,
          'venue': fixture.venue,
        });
      } catch (error) {
        debugPrint('World Cup reminder failed for $fixtureKey: $error');
      }
    }

    await _options.setValue(worldCupReminderIdsKey, scheduledIds);
    await _replaceFixtureMessagesForKind('worldCup', messageRows);
    return scheduledIds.length;
  }

  Future<void> clearWorldCupReminders() async {
    if (!_hasStoredNotificationIds(worldCupReminderIdsKey)) {
      await _options.setValue(worldCupReminderIdsKey, <int>[]);
      return;
    }
    await initialize();
    if (kIsWeb) {
      await _options.setValue(worldCupReminderIdsKey, <int>[]);
      return;
    }
    await _clearNotificationIds(worldCupReminderIdsKey);
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
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        onNotificationPayloadTap?.call(response.payload);
      },
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
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

  Future<void> _ensureNotificationChannel({
    required String name,
    required String description,
  }) async {
    if (kIsWeb) return;
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
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

  Future<void> _clearNotificationIds(String storageKey) async {
    final ids = _options.getValue<List>(storageKey) ?? const [];
    for (final rawId in ids) {
      final id = (rawId is num) ? rawId.toInt() : int.tryParse('$rawId');
      if (id == null) continue;
      await _plugin.cancel(id);
    }
    await _options.setValue(storageKey, <int>[]);
  }

  bool _hasStoredNotificationIds(String storageKey) {
    final ids = _options.getValue<List>(storageKey) ?? const [];
    return ids.any((rawId) {
      if (rawId is num) return rawId.toInt() >= 0;
      return int.tryParse('$rawId') != null;
    });
  }

  int unreadFixtureMessageCountSync() {
    final logs = _options.getValue<List>(fixtureMessageLogKey) ?? const [];
    final readRaw =
        _options.getValue<List>(fixtureMessageReadIdsKey) ?? const [];
    final readIds = readRaw.map((e) => e.toString()).toSet();
    return logs.whereType<Map>().where((item) {
      final id = item['id']?.toString() ?? '';
      if (id.isEmpty) return false;
      return !readIds.contains(id);
    }).length;
  }

  Future<void> markAllFixtureMessagesRead() async {
    final ids = loadFixtureMessageLogSync()
        .map((item) => item['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    await _options.setValue(fixtureMessageReadIdsKey, ids);
  }

  List<Map<String, dynamic>> loadFixtureMessageLogSync() {
    final raw = _options.getValue<List>(fixtureMessageLogKey) ?? const [];
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

  Future<void> deleteFixtureMessage(String id) async {
    final logs = loadFixtureMessageLogSync()
        .where((item) => (item['id']?.toString() ?? '') != id)
        .toList(growable: false);
    await _options.setValue(fixtureMessageLogKey, logs);
    final readRaw =
        _options.getValue<List>(fixtureMessageReadIdsKey) ?? const [];
    final readIds = readRaw.map((e) => e.toString()).toSet()..remove(id);
    await _options.setValue(
      fixtureMessageReadIdsKey,
      readIds.toList(growable: false),
    );
  }

  Future<void> _replaceFixtureMessagesForKind(
    String kind,
    List<Map<String, dynamic>> nextRows,
  ) async {
    final existing = loadFixtureMessageLogSync()
        .where((item) => (item['kind']?.toString() ?? '') != kind)
        .toList(growable: true);
    final combined = <Map<String, dynamic>>[...nextRows, ...existing]
      ..sort((a, b) {
        final aAt = DateTime.tryParse(a['scheduledAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bAt = DateTime.tryParse(b['scheduledAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return aAt.compareTo(bAt);
      });
    if (combined.length > 200) {
      combined.removeRange(200, combined.length);
    }
    await _options.setValue(fixtureMessageLogKey, combined);
    final activeIds = combined
        .map((item) => item['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    final readRaw =
        _options.getValue<List>(fixtureMessageReadIdsKey) ?? const [];
    final readIds = readRaw
        .map((e) => e.toString())
        .where(activeIds.contains)
        .toList(growable: false);
    await _options.setValue(fixtureMessageReadIdsKey, readIds);
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

  _LeagueFavoriteMatch? _worldCupFavoriteMatch(
    WorldCupFixture fixture,
    Set<String> selectedCountries,
  ) {
    for (final country in selectedCountries) {
      if (!fixture.involvesCountry(country)) continue;
      final normalized = country.trim().toLowerCase();
      final isHome = fixture.homeTeam.toLowerCase() == normalized;
      return _LeagueFavoriteMatch(
        teamKey: country,
        teamName: isHome ? fixture.homeTeam : fixture.awayTeam,
        opponentName: isHome ? fixture.awayTeam : fixture.homeTeam,
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
