import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/entities/fifa_world_overview.dart';

class FifaWorldOverviewService {
  static final Uri _baseApiUri = Uri.parse('https://api.fifa.com/api/v3');
  static const int _rankingPageSize = 250;
  static const int _matchPageSize = 100;
  static const int _matchPageLimit = 8;
  static const int _matchWindowDays = 13;
  static const int _defaultRecentResultLimit = 12;
  static const int _defaultUpcomingFixtureLimit = 12;

  final http.Client _client;
  final bool _ownsClient;

  FifaWorldOverviewService({http.Client? client})
      : _client = client ?? http.Client(),
        _ownsClient = client == null;

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  Future<FifaWorldOverview> fetchOverview({
    required FifaRankingGender gender,
    DateTime? now,
    int recentResultLimit = _defaultRecentResultLimit,
    int upcomingFixtureLimit = _defaultUpcomingFixtureLimit,
  }) async {
    final referenceNow = (now ?? DateTime.now()).toUtc();
    final snapshot = await _fetchRankingSnapshot(gender);
    final matches = await _fetchMatchSnapshot(
      gender: gender,
      referenceNow: referenceNow,
      recentWindowEnd: snapshot.recentWindowEnd,
      nextUpdatedAt: snapshot.nextUpdatedAt,
      recentResultLimit: recentResultLimit,
      upcomingFixtureLimit: upcomingFixtureLimit,
    );

    return FifaWorldOverview(
      gender: gender,
      rankings: snapshot.rankings,
      lastUpdatedAt: snapshot.lastUpdatedAt,
      nextUpdatedAt: snapshot.nextUpdatedAt,
      recentResults: matches.recentResults,
      upcomingFixtures: matches.upcomingFixtures,
    );
  }

  Future<FifaWorldOverview> fetchRankingOverview({
    required FifaRankingGender gender,
  }) async {
    final snapshot = await _fetchRankingSnapshot(gender);
    return FifaWorldOverview(
      gender: gender,
      rankings: snapshot.rankings,
      lastUpdatedAt: snapshot.lastUpdatedAt,
      nextUpdatedAt: snapshot.nextUpdatedAt,
      recentResults: const <FifaAMatchEntry>[],
      upcomingFixtures: const <FifaAMatchEntry>[],
    );
  }

  Future<FifaWorldOverview> fetchMatchOverview({
    required FifaRankingGender gender,
    DateTime? now,
    int recentResultLimit = _defaultRecentResultLimit,
    int upcomingFixtureLimit = _defaultUpcomingFixtureLimit,
  }) async {
    final referenceNow = (now ?? DateTime.now()).toUtc();
    final scheduleFuture = _fetchRankingSchedules(gender);
    final metadataFuture = _fetchRankingPageMetadata(gender);

    final schedules = await scheduleFuture;
    final metadata = await metadataFuture;
    final matches = await _fetchMatchSnapshot(
      gender: gender,
      referenceNow: referenceNow,
      recentWindowEnd: schedules.firstOrNull?.matchWindowEndDate,
      nextUpdatedAt: metadata.nextUpdatedAt,
      recentResultLimit: recentResultLimit,
      upcomingFixtureLimit: upcomingFixtureLimit,
    );

    return FifaWorldOverview(
      gender: gender,
      rankings: const <FifaRankingEntry>[],
      lastUpdatedAt:
          metadata.lastUpdatedAt ?? schedules.firstOrNull?.officialDate,
      nextUpdatedAt: metadata.nextUpdatedAt,
      recentResults: matches.recentResults,
      upcomingFixtures: matches.upcomingFixtures,
    );
  }

  Future<_FifaRankingSnapshot> _fetchRankingSnapshot(
    FifaRankingGender gender,
  ) async {
    final rankingFuture = _fetchRankings(gender);
    final scheduleFuture = _fetchRankingSchedules(gender);
    final metadataFuture = _fetchRankingPageMetadata(gender);

    final rankings = await rankingFuture;
    final schedules = await scheduleFuture;
    final metadata = await metadataFuture;

    final lastUpdatedAt = metadata.lastUpdatedAt ??
        rankings.firstOrNull?.publishedAt ??
        schedules.firstOrNull?.officialDate;
    final nextUpdatedAt = metadata.nextUpdatedAt;

    return _FifaRankingSnapshot(
      rankings: rankings,
      lastUpdatedAt: lastUpdatedAt,
      nextUpdatedAt: nextUpdatedAt,
      recentWindowEnd: schedules.firstOrNull?.matchWindowEndDate,
    );
  }

  Future<_FifaMatchSnapshot> _fetchMatchSnapshot({
    required FifaRankingGender gender,
    required DateTime referenceNow,
    required DateTime? recentWindowEnd,
    required DateTime? nextUpdatedAt,
    required int recentResultLimit,
    required int upcomingFixtureLimit,
  }) async {
    final recentResultsFuture = recentWindowEnd == null
        ? _scanRecentResults(
            gender: gender,
            anchor: referenceNow,
            limit: recentResultLimit,
          )
        : _fetchRecentResultsForWindow(
            gender: gender,
            windowEnd: recentWindowEnd,
            limit: recentResultLimit,
          );

    final upcomingFixturesFuture = nextUpdatedAt == null
        ? _scanUpcomingFixtures(
            gender: gender,
            anchor: referenceNow,
            limit: upcomingFixtureLimit,
          )
        : _fetchUpcomingFixturesForWindow(
            gender: gender,
            windowEnd: nextUpdatedAt,
            limit: upcomingFixtureLimit,
          );

    return _FifaMatchSnapshot(
      recentResults: await recentResultsFuture,
      upcomingFixtures: await upcomingFixturesFuture,
    );
  }

  Future<List<FifaRankingEntry>> _fetchRankings(
    FifaRankingGender gender,
  ) async {
    final uri = _baseApiUri.replace(
      path: '${_baseApiUri.path}/rankings/',
      queryParameters: {
        'gender': '${gender.apiValue}',
        'count': '$_rankingPageSize',
        'language': 'en',
      },
    );
    try {
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return const <FifaRankingEntry>[];
      }
      return parseRankingEntries(jsonDecode(response.body));
    } catch (_) {
      return const <FifaRankingEntry>[];
    }
  }

  Future<List<_FifaRankingSchedule>> _fetchRankingSchedules(
    FifaRankingGender gender,
  ) async {
    final uri = _baseApiUri.replace(
      path: '${_baseApiUri.path}/rankingschedules/all',
      queryParameters: {
        'type': '0',
        'gender': '${gender.apiValue}',
        'idClient': '64e9afa8-c5c0-413d-882b-bc9e6a81e264',
        'language': 'en',
      },
    );
    try {
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return const <_FifaRankingSchedule>[];
      }
      return _parseRankingSchedules(jsonDecode(response.body));
    } catch (_) {
      return const <_FifaRankingSchedule>[];
    }
  }

  Future<_FifaRankingPageMetadata> _fetchRankingPageMetadata(
    FifaRankingGender gender,
  ) async {
    try {
      final response = await _client
          .get(Uri.parse(gender.officialRankingUrl))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return const _FifaRankingPageMetadata();
      }
      return _parseRankingPageMetadataHtml(response.body);
    } catch (_) {
      return const _FifaRankingPageMetadata();
    }
  }

  Future<List<FifaAMatchEntry>> _fetchRecentResultsForWindow({
    required FifaRankingGender gender,
    required DateTime windowEnd,
    required int limit,
  }) async {
    final end = _endOfDayUtc(windowEnd);
    final start = end.subtract(const Duration(days: _matchWindowDays));
    final matches = await _fetchNationalMatchesWindow(
      gender: gender,
      start: start,
      end: end,
    );
    final results = matches
        .where((match) => match.status == FifaAMatchStatus.finished)
        .toList(growable: false)
      ..sort((a, b) => b.kickoffAt.compareTo(a.kickoffAt));
    return results.take(limit).toList(growable: false);
  }

  Future<List<FifaAMatchEntry>> _fetchUpcomingFixturesForWindow({
    required FifaRankingGender gender,
    required DateTime windowEnd,
    required int limit,
  }) async {
    final end = _endOfDayUtc(windowEnd.toUtc());
    final start = end.subtract(const Duration(days: _matchWindowDays));
    final matches = await _fetchNationalMatchesWindow(
      gender: gender,
      start: start,
      end: end,
    );
    final fixtures = matches
        .where((match) => match.status != FifaAMatchStatus.finished)
        .toList(growable: false)
      ..sort((a, b) => a.kickoffAt.compareTo(b.kickoffAt));
    return fixtures.take(limit).toList(growable: false);
  }

  Future<List<FifaAMatchEntry>> _scanRecentResults({
    required FifaRankingGender gender,
    required DateTime anchor,
    required int limit,
  }) async {
    final collected = <FifaAMatchEntry>[];
    final seenIds = <String>{};
    var cursor = anchor;
    for (var window = 0; window < 12 && collected.length < limit; window++) {
      final end = _endOfDayUtc(cursor);
      final start = end.subtract(const Duration(days: 6));
      final matches = await _fetchNationalMatchesWindow(
        gender: gender,
        start: start,
        end: end,
      );
      for (final match in matches) {
        if (match.status != FifaAMatchStatus.finished ||
            !seenIds.add(match.matchId)) {
          continue;
        }
        collected.add(match);
      }
      cursor = start.subtract(const Duration(seconds: 1));
    }
    collected.sort((a, b) => b.kickoffAt.compareTo(a.kickoffAt));
    return collected.take(limit).toList(growable: false);
  }

  Future<List<FifaAMatchEntry>> _scanUpcomingFixtures({
    required FifaRankingGender gender,
    required DateTime anchor,
    required int limit,
  }) async {
    final collected = <FifaAMatchEntry>[];
    final seenIds = <String>{};
    var cursor = anchor;
    for (var window = 0; window < 12 && collected.length < limit; window++) {
      final start = cursor;
      final end = _endOfDayUtc(start.add(const Duration(days: 6)));
      final matches = await _fetchNationalMatchesWindow(
        gender: gender,
        start: start,
        end: end,
      );
      for (final match in matches) {
        if (match.status == FifaAMatchStatus.finished ||
            !seenIds.add(match.matchId)) {
          continue;
        }
        collected.add(match);
      }
      cursor = end.add(const Duration(seconds: 1));
    }
    collected.sort((a, b) => a.kickoffAt.compareTo(b.kickoffAt));
    return collected.take(limit).toList(growable: false);
  }

  Future<List<FifaAMatchEntry>> _fetchNationalMatchesWindow({
    required FifaRankingGender gender,
    required DateTime start,
    required DateTime end,
  }) async {
    final baseUri = _baseApiUri.replace(
      path: '${_baseApiUri.path}/live/football/range',
      queryParameters: {
        'from': _formatApiDate(start),
        'to': _formatApiDate(end),
        'count': '$_matchPageSize',
        'language': 'en',
      },
    );
    var nextToken = '';
    var nextHash = '';
    var page = 0;
    final deduped = <String, FifaAMatchEntry>{};

    while (page < _matchPageLimit) {
      final uri = nextHash.isEmpty
          ? baseUri
          : baseUri.replace(
              queryParameters: {
                ...baseUri.queryParameters,
                'continuationHash': nextHash,
              },
            );
      try {
        final response = await _client
            .get(
              uri,
              headers: nextToken.isEmpty
                  ? null
                  : {'x-mdp-continuation-token': nextToken},
            )
            .timeout(const Duration(seconds: 8));
        if (response.statusCode != 200) {
          break;
        }
        final decoded = jsonDecode(response.body);
        final matches = parseNationalMatches(decoded, gender: gender);
        for (final match in matches) {
          deduped[match.matchId] = match;
        }
        nextToken = _asString(
          decoded is Map ? decoded['ContinuationToken'] : null,
        );
        nextHash = _asString(
          decoded is Map ? decoded['ContinuationHash'] : null,
        );
        if (nextToken.isEmpty || nextHash.isEmpty) {
          break;
        }
      } catch (_) {
        break;
      }
      page++;
    }

    return deduped.values.toList(growable: false);
  }

  static List<FifaRankingEntry> parseRankingEntries(dynamic decoded) {
    if (decoded is! Map || decoded['Results'] is! List) {
      return const <FifaRankingEntry>[];
    }
    final items = <FifaRankingEntry>[];
    for (final raw in decoded['Results'] as List<dynamic>) {
      if (raw is! Map) continue;
      final item = raw.cast<String, dynamic>();
      final teamName = _localizedDescription(item['TeamName']);
      final countryCode = _asString(item['IdCountry']);
      final teamId = _asString(item['IdTeam']);
      final confederation = _asString(item['ConfederationName']);
      final rank = _asInt(item['Rank']);
      final previousRank = _asInt(item['PrevRank']);
      final points = _asDouble(item['DecimalTotalPoints']);
      final previousPoints = _asDouble(item['DecimalPrevPoints']);
      if (teamName.isEmpty ||
          countryCode.isEmpty ||
          teamId.isEmpty ||
          confederation.isEmpty ||
          rank == null ||
          previousRank == null ||
          points == null ||
          previousPoints == null) {
        continue;
      }
      items.add(
        FifaRankingEntry(
          teamId: teamId,
          teamName: teamName,
          countryCode: countryCode,
          confederation: confederation,
          rank: rank,
          previousRank: previousRank,
          points: points,
          previousPoints: previousPoints,
          publishedAt: DateTime.tryParse(
            _asString(item['PubDate']),
          ).toUtcOrNull(),
        ),
      );
    }
    items.sort((a, b) => a.rank.compareTo(b.rank));
    return items;
  }

  static List<_FifaRankingSchedule> _parseRankingSchedules(dynamic decoded) {
    if (decoded is! Map || decoded['Results'] is! List) {
      return const <_FifaRankingSchedule>[];
    }
    final items = <_FifaRankingSchedule>[];
    for (final raw in decoded['Results'] as List<dynamic>) {
      if (raw is! Map) continue;
      final item = raw.cast<String, dynamic>();
      final officialDate = DateTime.tryParse(
        _asString(item['OfficialDate']),
      ).toUtcOrNull();
      final matchWindowEndDate = _parseDateOnlyUtc(item['MatchWindowEndDate']);
      if (officialDate == null || matchWindowEndDate == null) {
        continue;
      }
      items.add(
        _FifaRankingSchedule(
          officialDate: officialDate,
          matchWindowEndDate: matchWindowEndDate,
        ),
      );
    }
    items.sort((a, b) => b.officialDate.compareTo(a.officialDate));
    return items;
  }

  static _FifaRankingPageMetadata _parseRankingPageMetadataHtml(String html) {
    final lastUpdatedAt = DateTime.tryParse(
      _firstGroup(html, RegExp(r'"lastUpdateDate":"([^"]+)"')),
    ).toUtcOrNull();
    final nextUpdatedAt = DateTime.tryParse(
      _firstGroup(html, RegExp(r'"nextUpdateDate":"([^"]+)"')),
    ).toUtcOrNull();
    return _FifaRankingPageMetadata(
      lastUpdatedAt: lastUpdatedAt,
      nextUpdatedAt: nextUpdatedAt,
    );
  }

  static List<FifaAMatchEntry> parseNationalMatches(
    dynamic decoded, {
    required FifaRankingGender gender,
  }) {
    if (decoded is Map && decoded['Results'] is List) {
      return parseNationalMatches(decoded['Results'], gender: gender);
    }
    if (decoded is! List) {
      return const <FifaAMatchEntry>[];
    }
    final items = <FifaAMatchEntry>[];
    for (final raw in decoded) {
      if (raw is! Map) continue;
      final match = _parseNationalMatch(raw.cast<String, dynamic>());
      if (match == null || match.gender != gender) {
        continue;
      }
      items.add(match);
    }
    return items;
  }

  static FifaAMatchEntry? _parseNationalMatch(Map<String, dynamic> raw) {
    final home = _asMap(raw['HomeTeam']);
    final away = _asMap(raw['AwayTeam']);
    if (!_isSeniorNationalTeam(home) || !_isSeniorNationalTeam(away)) {
      return null;
    }
    final homeGender = _asInt(home['Gender']);
    final awayGender = _asInt(away['Gender']);
    if (homeGender == null || awayGender == null || homeGender != awayGender) {
      return null;
    }
    final gender = homeGender == FifaRankingGender.women.apiValue
        ? FifaRankingGender.women
        : FifaRankingGender.men;
    final kickoffAt = DateTime.tryParse(_asString(raw['Date'])).toUtcOrNull();
    final matchId = _asString(raw['IdMatch']);
    final competition = _localizedDescription(raw['CompetitionName']);
    final homeTeamName = _localizedDescription(home['TeamName']);
    final awayTeamName = _localizedDescription(away['TeamName']);
    final homeCountryCode = _asString(home['IdCountry']);
    final awayCountryCode = _asString(away['IdCountry']);
    if (kickoffAt == null ||
        matchId.isEmpty ||
        competition.isEmpty ||
        homeTeamName.isEmpty ||
        awayTeamName.isEmpty ||
        homeCountryCode.isEmpty ||
        awayCountryCode.isEmpty) {
      return null;
    }
    final homeScore = _asInt(home['Score']);
    final awayScore = _asInt(away['Score']);
    final period = _asInt(raw['Period']) ?? 0;
    final stadium = _asMap(raw['Stadium']);
    return FifaAMatchEntry(
      matchId: matchId,
      gender: gender,
      competition: competition,
      stage: _localizedDescription(raw['StageName']),
      venue: _localizedDescription(stadium['Name']),
      city: _localizedDescription(stadium['CityName']),
      kickoffAt: kickoffAt,
      homeTeamName: homeTeamName,
      homeCountryCode: homeCountryCode,
      awayTeamName: awayTeamName,
      awayCountryCode: awayCountryCode,
      homeScore: homeScore,
      awayScore: awayScore,
      status: _parseMatchStatus(
        period: period,
        homeScore: homeScore,
        awayScore: awayScore,
      ),
    );
  }

  static FifaAMatchStatus _parseMatchStatus({
    required int period,
    required int? homeScore,
    required int? awayScore,
  }) {
    const livePeriods = <int>{3, 4, 5, 6, 7, 8, 9, 11, 14, 15, 16, 17};
    const finishedPeriods = <int>{10, 12, 13};
    if (livePeriods.contains(period)) {
      return FifaAMatchStatus.live;
    }
    if (finishedPeriods.contains(period) ||
        (homeScore != null && awayScore != null)) {
      return FifaAMatchStatus.finished;
    }
    return FifaAMatchStatus.scheduled;
  }

  static bool _isSeniorNationalTeam(Map<String, dynamic> team) {
    return _asInt(team['TeamType']) == 1 &&
        _asInt(team['AgeType']) == 7 &&
        _asInt(team['FootballType']) == 0;
  }

  static DateTime _endOfDayUtc(DateTime value) {
    final utc = value.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day, 23, 59, 59);
  }

  static String _formatApiDate(DateTime value) =>
      '${value.toUtc().toIso8601String().split('.').first}Z';

  static DateTime? _parseDateOnlyUtc(dynamic raw) {
    final value = _asString(raw);
    if (value.isEmpty) return null;
    return DateTime.tryParse('${value}T00:00:00Z');
  }

  static String _firstGroup(String input, RegExp pattern) {
    final match = pattern.firstMatch(input);
    if (match == null || match.groupCount < 1) {
      return '';
    }
    return match.group(1) ?? '';
  }

  static String _localizedDescription(dynamic raw) {
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final map = item.cast<String, dynamic>();
        final locale = _asString(map['Locale']).toLowerCase();
        final description = _asString(map['Description']);
        if (description.isEmpty) continue;
        if (locale == 'en-gb' || locale == 'en' || locale == 'en-us') {
          return description;
        }
      }
      for (final item in raw) {
        if (item is! Map) continue;
        final description = _asString(item['Description']);
        if (description.isNotEmpty) {
          return description;
        }
      }
    }
    return _asString(raw);
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return raw.cast<String, dynamic>();
    }
    return const <String, dynamic>{};
  }

  static String _asString(dynamic value) {
    if (value == null) return '';
    return '$value'.trim();
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(_asString(value));
  }

  static double? _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(_asString(value));
  }
}

class _FifaRankingSchedule {
  final DateTime officialDate;
  final DateTime matchWindowEndDate;

  const _FifaRankingSchedule({
    required this.officialDate,
    required this.matchWindowEndDate,
  });
}

class _FifaRankingSnapshot {
  final List<FifaRankingEntry> rankings;
  final DateTime? lastUpdatedAt;
  final DateTime? nextUpdatedAt;
  final DateTime? recentWindowEnd;

  const _FifaRankingSnapshot({
    required this.rankings,
    required this.lastUpdatedAt,
    required this.nextUpdatedAt,
    required this.recentWindowEnd,
  });
}

class _FifaMatchSnapshot {
  final List<FifaAMatchEntry> recentResults;
  final List<FifaAMatchEntry> upcomingFixtures;

  const _FifaMatchSnapshot({
    required this.recentResults,
    required this.upcomingFixtures,
  });
}

class _FifaRankingPageMetadata {
  final DateTime? lastUpdatedAt;
  final DateTime? nextUpdatedAt;

  const _FifaRankingPageMetadata({this.lastUpdatedAt, this.nextUpdatedAt});
}

extension on DateTime? {
  DateTime? toUtcOrNull() => this?.toUtc();
}

extension<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
