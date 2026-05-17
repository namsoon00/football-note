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

  static String _fallbackLeagueName(LeagueStandingsType type) {
    return switch (type) {
      LeagueStandingsType.premierLeague => 'Premier League',
      LeagueStandingsType.championsLeague => 'UEFA Champions League',
      LeagueStandingsType.laLiga => 'LaLiga',
      LeagueStandingsType.bundesliga => 'Bundesliga',
    };
  }
}
