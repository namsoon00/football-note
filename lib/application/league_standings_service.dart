import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/entities/league_standings.dart';

class LeagueStandingsService {
  LeagueStandingsService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  static const Map<LeagueStandingsType, String> _espnLeagueIds = {
    LeagueStandingsType.premierLeague: 'eng.1',
    LeagueStandingsType.championsLeague: 'uefa.champions',
    LeagueStandingsType.laLiga: 'esp.1',
    LeagueStandingsType.bundesliga: 'ger.1',
    LeagueStandingsType.majorLeagueSoccer: 'usa.1',
    LeagueStandingsType.saudiProLeague: 'ksa.1',
  };
  static final Uri _kLeagueStandingsUri =
      Uri.https('www.kleague.com', '/record/teamRank.do', {
        'leagueId': '1',
        'stadium': 'all',
        'recordType': 'rank',
        'sortTargetId': '',
        'isSort': 'false',
      });
  static final Uri _kLeagueFixturesUri = Uri.https(
    'www.kleague.com',
    '/getScheduleList.do',
  );
  static const String _kLeagueStandingsSourceUrl =
      'https://www.kleague.com/record/team.do';
  static const String _kLeagueFixturesSourceUrl =
      'https://www.kleague.com/schedule.do?leagueId=1';
  static const int _fixtureLookBackDays = 14;
  static const int _fixtureLookAheadDays = 90;
  static const int _kLeagueFixtureLookAheadDays = 14;

  Future<LeagueStandingsSnapshot> fetch(LeagueStandingsType type) async {
    if (type == LeagueStandingsType.kLeague1) {
      return _fetchKLeagueStandings();
    }
    final leagueId = _espnLeagueIds[type]!;
    final uri = Uri.https(
      'site.api.espn.com',
      '/apis/v2/sports/soccer/$leagueId/standings',
    );
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw StateError('Standings request failed: ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Invalid standings payload.');
    }
    return parseSnapshotForTesting(type: type, payload: decoded);
  }

  Future<LeagueFixtureSnapshot> fetchFixtures(
    LeagueStandingsType type, {
    DateTime? now,
  }) async {
    if (type == LeagueStandingsType.kLeague1) {
      return _fetchKLeagueFixtures(now: now);
    }
    final leagueId = _espnLeagueIds[type]!;
    final reference = now ?? DateTime.now();
    final start = reference.subtract(
      const Duration(days: _fixtureLookBackDays),
    );
    final end = reference.add(
      const Duration(days: _kLeagueFixtureLookAheadDays),
    );
    final uri = Uri.https(
      'site.api.espn.com',
      '/apis/site/v2/sports/soccer/$leagueId/scoreboard',
      {
        'dates': '${_formatEspnDate(start)}-${_formatEspnDate(end)}',
        'limit': '100',
      },
    );
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw StateError('Fixtures request failed: ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Invalid fixtures payload.');
    }
    return parseFixtureSnapshotForTesting(type: type, payload: decoded);
  }

  Future<LeagueStandingsSnapshot> _fetchKLeagueStandings({
    DateTime? now,
  }) async {
    final currentYear = (now ?? DateTime.now()).year;
    StateError? lastStateError;
    for (final year in <int>[currentYear, currentYear - 1]) {
      try {
        final snapshot = await _fetchKLeagueStandingsForYear(year);
        if (snapshot.entries.isNotEmpty || year == currentYear - 1) {
          return snapshot;
        }
      } on StateError catch (error) {
        lastStateError = error;
      }
    }
    throw lastStateError ?? StateError('K League standings are unavailable.');
  }

  Future<LeagueStandingsSnapshot> _fetchKLeagueStandingsForYear(
    int year,
  ) async {
    final uri = _kLeagueStandingsUri.replace(
      queryParameters: {
        ..._kLeagueStandingsUri.queryParameters,
        'year': year.toString(),
      },
    );
    final response = await _client
        .post(uri)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw StateError(
        'K League standings request failed: '
        '${response.statusCode}',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Invalid K League standings payload.');
    }
    if (decoded['resultCode']?.toString() != '200') {
      throw StateError('K League standings returned an error.');
    }
    return parseKLeagueSnapshotForTesting(payload: decoded);
  }

  Future<LeagueFixtureSnapshot> _fetchKLeagueFixtures({DateTime? now}) async {
    final reference = now ?? DateTime.now();
    final start = reference.subtract(
      const Duration(days: _fixtureLookBackDays),
    );
    final end = reference.add(const Duration(days: _fixtureLookAheadDays));
    final payloads = <Map<String, dynamic>>[];
    for (final month in _monthsBetween(start, end)) {
      final response = await _client
          .post(
            _kLeagueFixturesUri,
            headers: const {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              'leagueId': '1',
              'year': month.year.toString(),
              'month': month.month.toString().padLeft(2, '0'),
              'ticketYn': '',
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw StateError(
          'K League fixtures request failed: '
          '${response.statusCode}',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw StateError('Invalid K League fixtures payload.');
      }
      if (decoded['resultCode']?.toString() != '200') {
        throw StateError('K League fixtures returned an error.');
      }
      payloads.add(decoded);
    }
    return parseKLeagueFixtureSnapshotsForTesting(
      payloads: payloads,
      start: start,
      end: end,
    );
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  static LeagueStandingsSnapshot parseSnapshotForTesting({
    required LeagueStandingsType type,
    required Map<String, dynamic> payload,
  }) {
    final children = payload['children'];
    final firstChild = children is List && children.isNotEmpty
        ? children.first
        : null;
    final child = firstChild is Map
        ? firstChild.cast<String, dynamic>()
        : <String, dynamic>{};
    final standings = (child['standings'] is Map)
        ? (child['standings'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final entriesRaw = standings['entries'];
    final entries = <LeagueStandingEntry>[];
    if (entriesRaw is List) {
      for (var index = 0; index < entriesRaw.length; index++) {
        final raw = entriesRaw[index];
        if (raw is! Map) continue;
        final entry = _parseEntry(raw.cast<String, dynamic>(), index);
        if (entry.teamName.trim().isNotEmpty) {
          entries.add(entry);
        }
      }
    }
    entries.sort((a, b) => a.rank.compareTo(b.rank));
    return LeagueStandingsSnapshot(
      type: type,
      leagueName: payload['name']?.toString().trim().isNotEmpty == true
          ? payload['name'].toString().trim()
          : _fallbackLeagueName(type),
      seasonName:
          standings['seasonDisplayName']?.toString().trim().isNotEmpty == true
          ? standings['seasonDisplayName'].toString().trim()
          : child['name']?.toString().trim() ?? '',
      sourceUrl: _sourceUrl(standings),
      fetchedAt: DateTime.now(),
      entries: entries,
    );
  }

  static LeagueFixtureSnapshot parseFixtureSnapshotForTesting({
    required LeagueStandingsType type,
    required Map<String, dynamic> payload,
    DateTime? fetchedAt,
  }) {
    final league = _firstMap(payload['leagues']);
    final season = _asMap(league['season']);
    final eventsRaw = payload['events'];
    final entries = <LeagueFixtureEntry>[];
    if (eventsRaw is List) {
      for (final raw in eventsRaw) {
        if (raw is! Map) continue;
        final entry = _parseFixtureEntry(raw.cast<String, dynamic>());
        if (entry != null) {
          entries.add(entry);
        }
      }
    }
    entries.sort(_compareFixtureEntries);
    return LeagueFixtureSnapshot(
      type: type,
      leagueName: league['name']?.toString().trim().isNotEmpty == true
          ? league['name'].toString().trim()
          : _fallbackLeagueName(type),
      seasonName: season['displayName']?.toString().trim() ?? '',
      sourceUrl: _fixtureSourceUrl(payload),
      fetchedAt: fetchedAt ?? DateTime.now(),
      entries: entries,
    );
  }

  static LeagueStandingsSnapshot parseKLeagueSnapshotForTesting({
    required Map<String, dynamic> payload,
    DateTime? fetchedAt,
  }) {
    final data = _asMap(payload['data']);
    final entriesRaw = data['teamRank'];
    final entries = <LeagueStandingEntry>[];
    if (entriesRaw is List) {
      for (var index = 0; index < entriesRaw.length; index++) {
        final raw = entriesRaw[index];
        if (raw is! Map) continue;
        final entry = _parseKLeagueStandingEntry(
          raw.cast<String, dynamic>(),
          index,
        );
        if (entry.teamName.trim().isNotEmpty) {
          entries.add(entry);
        }
      }
    }
    entries.sort((a, b) => a.rank.compareTo(b.rank));
    final seasonYear = entriesRaw is List && entriesRaw.isNotEmpty
        ? _asMap(entriesRaw.first)['year']?.toString().trim() ?? ''
        : '';
    return LeagueStandingsSnapshot(
      type: LeagueStandingsType.kLeague1,
      leagueName: 'K League 1',
      seasonName: seasonYear.isEmpty ? '' : '$seasonYear K League 1',
      sourceUrl: _kLeagueStandingsSourceUrl,
      fetchedAt: fetchedAt ?? DateTime.now(),
      entries: entries,
    );
  }

  static LeagueFixtureSnapshot parseKLeagueFixtureSnapshotsForTesting({
    required List<Map<String, dynamic>> payloads,
    DateTime? start,
    DateTime? end,
    DateTime? fetchedAt,
  }) {
    final entries = <LeagueFixtureEntry>[];
    String seasonName = '';
    for (final payload in payloads) {
      final data = _asMap(payload['data']);
      final fixturesRaw = data['scheduleList'];
      if (fixturesRaw is! List) continue;
      for (final raw in fixturesRaw) {
        if (raw is! Map) continue;
        final entry = _parseKLeagueFixtureEntry(raw.cast<String, dynamic>());
        if (entry == null) continue;
        if (start != null && entry.kickoffAt.isBefore(start)) continue;
        if (end != null && entry.kickoffAt.isAfter(end)) continue;
        entries.add(entry);
        if (seasonName.isEmpty) {
          final year = raw['year']?.toString().trim() ?? '';
          if (year.isNotEmpty) {
            seasonName = '$year K League 1';
          }
        }
      }
    }
    entries.sort(_compareFixtureEntries);
    return LeagueFixtureSnapshot(
      type: LeagueStandingsType.kLeague1,
      leagueName: 'K League 1',
      seasonName: seasonName,
      sourceUrl: _kLeagueFixturesSourceUrl,
      fetchedAt: fetchedAt ?? DateTime.now(),
      entries: entries,
    );
  }

  static LeagueStandingEntry _parseKLeagueStandingEntry(
    Map<String, dynamic> raw,
    int index,
  ) {
    return LeagueStandingEntry(
      rank: _asInt(raw['rank']) ?? index + 1,
      teamName: raw['teamName']?.toString().trim() ?? '',
      teamShortName: raw['teamName']?.toString().trim() ?? '',
      logoUrl: _kLeagueLogoUrl(raw['teamId']),
      played: _asDisplay(raw['gameCount']),
      wins: _asDisplay(raw['winCnt']),
      draws: _asDisplay(raw['tieCnt']),
      losses: _asDisplay(raw['lossCnt']),
      goalsFor: _asDisplay(raw['gainGoal']),
      goalsAgainst: _asDisplay(raw['lossGoal']),
      goalDifference: _asDisplay(raw['gapCnt']),
      points: _asDisplay(raw['gainPoint']),
      note: '',
    );
  }

  static LeagueFixtureEntry? _parseKLeagueFixtureEntry(
    Map<String, dynamic> raw,
  ) {
    final kickoffAt = _parseKLeagueKickoffAt(
      raw['gameDate']?.toString().trim() ?? '',
      raw['gameTime']?.toString().trim() ?? '',
    );
    final homeTeamName = raw['homeTeamName']?.toString().trim() ?? '';
    final awayTeamName = raw['awayTeamName']?.toString().trim() ?? '';
    final gameId = raw['gameId']?.toString().trim() ?? '';
    if (kickoffAt == null ||
        gameId.isEmpty ||
        homeTeamName.isEmpty ||
        awayTeamName.isEmpty) {
      return null;
    }
    final status = _kLeagueFixtureStatus(raw);
    final year = raw['year']?.toString().trim() ?? '';
    final leagueId = raw['leagueId']?.toString().trim() ?? '1';
    final meetSeq = raw['meetSeq']?.toString().trim() ?? '';
    final roundId = raw['roundId']?.toString().trim() ?? '';
    return LeagueFixtureEntry(
      id: _firstNonEmpty([
        if (year.isNotEmpty && meetSeq.isNotEmpty)
          '$year-$leagueId-$gameId-$meetSeq',
        gameId,
      ]),
      kickoffAt: kickoffAt,
      stage: roundId.isEmpty ? '' : 'R$roundId',
      leg: '',
      note: raw['codeName']?.toString().trim() ?? '',
      venue: raw['fieldNameFull']?.toString().trim() ?? '',
      city: raw['fieldName']?.toString().trim() ?? '',
      homeTeamName: homeTeamName,
      homeTeamShortName: homeTeamName,
      homeLogoUrl: _kLeagueLogoUrl(raw['homeTeam']),
      awayTeamName: awayTeamName,
      awayTeamShortName: awayTeamName,
      awayLogoUrl: _kLeagueLogoUrl(raw['awayTeam']),
      homeScore: status == LeagueFixtureStatus.scheduled
          ? null
          : _asInt(raw['homeGoal']),
      awayScore: status == LeagueFixtureStatus.scheduled
          ? null
          : _asInt(raw['awayGoal']),
      status: status,
      sourceUrl: _kLeagueFixtureSourceUrl(raw),
    );
  }

  static LeagueFixtureEntry? _parseFixtureEntry(Map<String, dynamic> raw) {
    final competition = _firstMap(raw['competitions']);
    final competitorsRaw = competition['competitors'];
    if (competitorsRaw is! List) return null;
    Map<String, dynamic>? home;
    Map<String, dynamic>? away;
    for (final rawCompetitor in competitorsRaw) {
      if (rawCompetitor is! Map) continue;
      final competitor = rawCompetitor.cast<String, dynamic>();
      final homeAway = competitor['homeAway']?.toString().trim();
      if (homeAway == 'home') {
        home = competitor;
      } else if (homeAway == 'away') {
        away = competitor;
      }
    }
    final mappedCompetitors = competitorsRaw
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false);
    if (home == null && mappedCompetitors.isNotEmpty) {
      home = mappedCompetitors.first;
    }
    if (away == null && mappedCompetitors.length > 1) {
      away = mappedCompetitors[1];
    }
    if (home == null || away == null) return null;
    final kickoffAt = DateTime.tryParse(
      competition['date']?.toString() ?? raw['date']?.toString() ?? '',
    );
    final id =
        raw['id']?.toString().trim() ?? competition['id']?.toString() ?? '';
    final homeTeam = _asMap(home['team']);
    final awayTeam = _asMap(away['team']);
    final homeName = _teamName(homeTeam);
    final awayName = _teamName(awayTeam);
    if (kickoffAt == null ||
        id.isEmpty ||
        homeName.isEmpty ||
        awayName.isEmpty) {
      return null;
    }
    final venue = _asMap(competition['venue']);
    final address = _asMap(venue['address']);
    final status = _fixtureStatus(competition['status']);
    final series = _asMap(competition['series']);
    final leg = _asMap(competition['leg']);
    return LeagueFixtureEntry(
      id: id,
      kickoffAt: kickoffAt,
      stage: _firstNonEmpty([
        series['title']?.toString().trim() ?? '',
        raw['season'] is Map ? _seasonSlugLabel(raw['season']) : '',
      ]),
      leg: leg['displayValue']?.toString().trim() ?? '',
      note: _fixtureNote(competition),
      venue: venue['fullName']?.toString().trim() ?? '',
      city: address['city']?.toString().trim() ?? '',
      homeTeamName: homeName,
      homeTeamShortName: homeTeam['shortDisplayName']?.toString().trim() ?? '',
      homeLogoUrl: _teamLogo(homeTeam),
      awayTeamName: awayName,
      awayTeamShortName: awayTeam['shortDisplayName']?.toString().trim() ?? '',
      awayLogoUrl: _teamLogo(awayTeam),
      homeScore: _asInt(home['score']),
      awayScore: _asInt(away['score']),
      status: status,
      sourceUrl: _sourceUrl(raw),
    );
  }

  static LeagueFixtureStatus _fixtureStatus(dynamic rawStatus) {
    final status = _asMap(rawStatus);
    final type = _asMap(status['type']);
    if (type['completed'] == true) {
      return LeagueFixtureStatus.finished;
    }
    final state = type['state']?.toString().trim().toLowerCase() ?? '';
    if (state == 'in') {
      return LeagueFixtureStatus.live;
    }
    return LeagueFixtureStatus.scheduled;
  }

  static String _fixtureNote(Map<String, dynamic> competition) {
    final notes = competition['notes'];
    if (notes is! List) return '';
    for (final raw in notes) {
      if (raw is! Map) continue;
      final note = raw.cast<String, dynamic>();
      final headline = note['headline']?.toString().trim() ?? '';
      if (headline.isNotEmpty) return headline;
      final text = note['text']?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static String _fixtureSourceUrl(Map<String, dynamic> payload) {
    final leagues = payload['leagues'];
    if (leagues is List) {
      for (final raw in leagues) {
        if (raw is! Map) continue;
        final url = _sourceUrl(raw.cast<String, dynamic>());
        if (url.isNotEmpty) return url;
      }
    }
    return '';
  }

  static LeagueStandingEntry _parseEntry(Map<String, dynamic> raw, int index) {
    final team = raw['team'] is Map
        ? (raw['team'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final note = raw['note'] is Map
        ? (raw['note'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final stats = raw['stats'] is List ? raw['stats'] as List : const [];
    final statByType = <String, Map<String, dynamic>>{};
    for (final item in stats) {
      if (item is! Map) continue;
      final stat = item.cast<String, dynamic>();
      final type = stat['type']?.toString().toLowerCase().trim() ?? '';
      final name = stat['name']?.toString().toLowerCase().trim() ?? '';
      if (type.isNotEmpty) statByType[type] = stat;
      if (name.isNotEmpty) statByType[name] = stat;
    }
    final rank = _statInt(statByType, 'rank') ?? index + 1;
    return LeagueStandingEntry(
      rank: rank,
      teamName: _teamName(team),
      teamShortName: team['shortDisplayName']?.toString().trim() ?? '',
      logoUrl: _teamLogo(team),
      played: _statDisplay(statByType, 'gamesplayed'),
      wins: _statDisplay(statByType, 'wins'),
      draws: _statDisplay(statByType, 'ties'),
      losses: _statDisplay(statByType, 'losses'),
      goalsFor: _statDisplay(statByType, 'pointsfor'),
      goalsAgainst: _statDisplay(statByType, 'pointsagainst'),
      goalDifference: _statDisplay(statByType, 'pointdifferential'),
      points: _statDisplay(statByType, 'points'),
      note: note['description']?.toString().trim() ?? '',
    );
  }

  static String _teamName(Map<String, dynamic> team) {
    final displayName = team['displayName']?.toString().trim() ?? '';
    if (displayName.isNotEmpty) return displayName;
    final name = team['name']?.toString().trim() ?? '';
    if (name.isNotEmpty) return name;
    return team['location']?.toString().trim() ?? '';
  }

  static String _teamLogo(Map<String, dynamic> team) {
    final logos = team['logos'];
    if (logos is! List || logos.isEmpty) return '';
    for (final logo in logos) {
      if (logo is! Map) continue;
      final href = logo['href']?.toString().trim() ?? '';
      if (href.startsWith('https://') || href.startsWith('http://')) {
        return href;
      }
    }
    return '';
  }

  static String _sourceUrl(Map<String, dynamic> standings) {
    final links = standings['links'];
    if (links is! List) return '';
    for (final link in links) {
      if (link is! Map) continue;
      final href = link['href']?.toString().trim() ?? '';
      if (href.startsWith('https://') || href.startsWith('http://')) {
        return href;
      }
    }
    return '';
  }

  static DateTime? _parseKLeagueKickoffAt(String rawDate, String rawTime) {
    final dateMatch = RegExp(
      r'^(\d{4})[.](\d{1,2})[.](\d{1,2})$',
    ).firstMatch(rawDate);
    if (dateMatch == null) return null;
    final year = int.tryParse(dateMatch.group(1) ?? '');
    final month = int.tryParse(dateMatch.group(2) ?? '');
    final day = int.tryParse(dateMatch.group(3) ?? '');
    if (year == null || month == null || day == null) return null;
    final timeMatch = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(rawTime);
    final hour = int.tryParse(timeMatch?.group(1) ?? '') ?? 0;
    final minute = int.tryParse(timeMatch?.group(2) ?? '') ?? 0;
    return DateTime.utc(
      year,
      month,
      day,
      hour,
      minute,
    ).subtract(const Duration(hours: 9));
  }

  static LeagueFixtureStatus _kLeagueFixtureStatus(Map<String, dynamic> raw) {
    final endYn = raw['endYn']?.toString().trim().toUpperCase() ?? '';
    final gameStatus = raw['gameStatus']?.toString().trim().toUpperCase() ?? '';
    if (endYn == 'Y' || gameStatus == 'FE') {
      return LeagueFixtureStatus.finished;
    }
    if (gameStatus.isNotEmpty &&
        gameStatus != 'BE' &&
        gameStatus != 'P' &&
        gameStatus != 'PE') {
      return LeagueFixtureStatus.live;
    }
    return LeagueFixtureStatus.scheduled;
  }

  static String _kLeagueFixtureSourceUrl(Map<String, dynamic> raw) {
    final year = raw['year']?.toString().trim() ?? '';
    final leagueId = raw['leagueId']?.toString().trim() ?? '';
    final gameId = raw['gameId']?.toString().trim() ?? '';
    final meetSeq = raw['meetSeq']?.toString().trim() ?? '';
    if (year.isEmpty || leagueId.isEmpty || gameId.isEmpty || meetSeq.isEmpty) {
      return _kLeagueFixturesSourceUrl;
    }
    return Uri.https('www.kleague.com', '/match.do', {
      'year': year,
      'leagueId': leagueId,
      'gameId': gameId,
      'meetSeq': meetSeq,
    }).toString();
  }

  static String _kLeagueLogoUrl(dynamic rawTeamId) {
    final teamId = rawTeamId?.toString().trim() ?? '';
    if (!RegExp(r'^K\d+$').hasMatch(teamId)) {
      return '';
    }
    return Uri.https(
      'www.kleague.com',
      '/assets/images/emblem/emblem_$teamId.png',
    ).toString();
  }

  static List<DateTime> _monthsBetween(DateTime start, DateTime end) {
    final months = <DateTime>[];
    var cursor = DateTime(start.year, start.month);
    final last = DateTime(end.year, end.month);
    while (!cursor.isAfter(last)) {
      months.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return months;
  }

  static Map<String, dynamic> _firstMap(dynamic raw) {
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) return item.cast<String, dynamic>();
      }
    }
    return <String, dynamic>{};
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    return raw is Map ? raw.cast<String, dynamic>() : <String, dynamic>{};
  }

  static String _firstNonEmpty(Iterable<String> values) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  static String _seasonSlugLabel(dynamic rawSeason) {
    if (rawSeason is! Map) return '';
    final slug = rawSeason['slug']?.toString().trim() ?? '';
    if (slug.isEmpty) return '';
    return slug
        .split('-')
        .where((part) => part.trim().isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  static String _statDisplay(
    Map<String, Map<String, dynamic>> statByType,
    String type,
  ) {
    final stat = statByType[type];
    if (stat == null) return '-';
    final display = stat['displayValue']?.toString().trim() ?? '';
    if (display.isNotEmpty) return display;
    final value = stat['value'];
    if (value is num) return value.round().toString();
    return value?.toString().trim().isNotEmpty == true
        ? value.toString().trim()
        : '-';
  }

  static int? _statInt(
    Map<String, Map<String, dynamic>> statByType,
    String type,
  ) {
    final stat = statByType[type];
    if (stat == null) return null;
    final value = stat['value'];
    if (value is num) return value.toInt();
    return int.tryParse(stat['displayValue']?.toString() ?? '');
  }

  static int? _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString().trim() ?? '');
  }

  static String _asDisplay(dynamic value) {
    if (value == null) return '-';
    final text = value.toString().trim();
    return text.isEmpty ? '-' : text;
  }

  static int _compareFixtureEntries(
    LeagueFixtureEntry a,
    LeagueFixtureEntry b,
  ) {
    final aDone = a.status == LeagueFixtureStatus.finished;
    final bDone = b.status == LeagueFixtureStatus.finished;
    if (aDone != bDone) {
      return aDone ? 1 : -1;
    }
    return aDone
        ? b.kickoffAt.compareTo(a.kickoffAt)
        : a.kickoffAt.compareTo(b.kickoffAt);
  }

  static String _formatEspnDate(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}$month$day';
  }

  static String _fallbackLeagueName(LeagueStandingsType type) {
    return switch (type) {
      LeagueStandingsType.kLeague1 => 'K League 1',
      LeagueStandingsType.premierLeague => 'Premier League',
      LeagueStandingsType.championsLeague => 'UEFA Champions League',
      LeagueStandingsType.laLiga => 'LaLiga',
      LeagueStandingsType.bundesliga => 'Bundesliga',
      LeagueStandingsType.majorLeagueSoccer => 'MLS',
      LeagueStandingsType.saudiProLeague => 'Saudi Pro League',
    };
  }
}
