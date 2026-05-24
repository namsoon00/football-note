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
  };
  static const int _fixtureLookBackDays = 14;
  static const int _fixtureLookAheadDays = 90;

  Future<LeagueStandingsSnapshot> fetch(LeagueStandingsType type) async {
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
    final leagueId = _espnLeagueIds[type]!;
    final reference = now ?? DateTime.now();
    final start = reference.subtract(
      const Duration(days: _fixtureLookBackDays),
    );
    final end = reference.add(const Duration(days: _fixtureLookAheadDays));
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
      LeagueStandingsType.premierLeague => 'Premier League',
      LeagueStandingsType.championsLeague => 'UEFA Champions League',
      LeagueStandingsType.laLiga => 'LaLiga',
      LeagueStandingsType.bundesliga => 'Bundesliga',
    };
  }
}
