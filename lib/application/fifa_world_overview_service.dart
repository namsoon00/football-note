import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/entities/fifa_world_overview.dart';

class FifaWorldOverviewService {
  static final Uri _baseApiUri = Uri.parse('https://api.fifa.com/api/v3');
  static final Uri _kfaHomeUri = Uri.parse('https://www.kfa.or.kr/');
  static const int _rankingPageSize = 250;
  static const int _footballSportType = 0;
  static const int _matchPageSize = 100;
  static const int _matchPageLimit = 16;
  static const int _competitionMatchPageLimit = 6;
  static const int _defaultRecentResultLimit = 12;
  static const int _defaultUpcomingFixtureLimit = 80;

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

  Future<KfaMatchOverview> fetchKfaMatchOverview({int limit = 8}) async {
    try {
      final response =
          await _client.get(_kfaHomeUri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return const KfaMatchOverview(
          recentResults: <KfaMatchEntry>[],
          upcomingFixtures: <KfaMatchEntry>[],
        );
      }
      return parseKfaMatchOverview(response.body, limit: limit);
    } catch (_) {
      return const KfaMatchOverview(
        recentResults: <KfaMatchEntry>[],
        upcomingFixtures: <KfaMatchEntry>[],
      );
    }
  }

  Future<FifaWorldOverview> fetchRankingOverview({
    required FifaRankingGender gender,
  }) async {
    final scheduleFuture = _fetchRankingSchedules(gender);
    final metadataFuture = _fetchRankingPageMetadata(gender);

    final schedules = await scheduleFuture;
    final rankings = await _fetchLatestRankings(gender, schedules);
    final metadata = await metadataFuture;

    return FifaWorldOverview(
      gender: gender,
      rankings: rankings,
      lastUpdatedAt: metadata.lastUpdatedAt ??
          rankings.firstOrNull?.publishedAt ??
          schedules.firstOrNull?.visibilityDate ??
          schedules.firstOrNull?.officialDate,
      nextUpdatedAt: metadata.nextUpdatedAt,
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

  Future<FifaTeamDetail?> fetchTeamDetail({required String teamId}) async {
    final uri = _baseApiUri.replace(
      path: '${_baseApiUri.path}/teams/$teamId',
      queryParameters: {'language': 'en'},
    );
    try {
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return null;
      }
      return parseTeamDetail(jsonDecode(response.body));
    } catch (_) {
      return null;
    }
  }

  Future<FifaAMatchDetail?> fetchMatchDetail({
    required FifaAMatchEntry match,
    String language = 'en',
  }) async {
    final uri = _baseApiUri.replace(
      path: '${_baseApiUri.path}/live/football/${match.matchId}',
      queryParameters: {'language': language.trim().isEmpty ? 'en' : language},
    );
    try {
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return null;
      }
      return parseFifaMatchDetail(jsonDecode(response.body), fallback: match);
    } catch (_) {
      return null;
    }
  }

  Future<List<FifaAMatchEntry>> fetchNationalMatches({
    required FifaRankingGender gender,
    required DateTime start,
    required DateTime end,
  }) {
    return _fetchNationalMatchesWindow(gender: gender, start: start, end: end);
  }

  Future<List<FifaAMatchEntry>> fetchCompetitionMatches({
    required FifaRankingGender gender,
    required String competitionId,
    required String seasonId,
    required DateTime start,
    required DateTime end,
  }) async {
    final baseUri = _baseApiUri.replace(
      path: '${_baseApiUri.path}/calendar/matches',
      queryParameters: {
        'idCompetition': competitionId,
        'idSeason': seasonId,
        'from': _formatApiDay(start),
        'to': _formatApiDay(end),
        'count': '$_matchPageSize',
        'language': 'en',
      },
    );
    var nextToken = '';
    var nextHash = '';
    var page = 0;
    final deduped = <String, FifaAMatchEntry>{};

    while (page < _competitionMatchPageLimit) {
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

    final matches = deduped.values.toList(growable: false)
      ..sort((a, b) => a.kickoffAt.compareTo(b.kickoffAt));
    return matches;
  }

  Future<_FifaRankingSnapshot> _fetchRankingSnapshot(
    FifaRankingGender gender,
  ) async {
    final scheduleFuture = _fetchRankingSchedules(gender);
    final metadataFuture = _fetchRankingPageMetadata(gender);

    final schedules = await scheduleFuture;
    final rankings = await _fetchLatestRankings(gender, schedules);
    final metadata = await metadataFuture;

    final lastUpdatedAt = metadata.lastUpdatedAt ??
        rankings.firstOrNull?.publishedAt ??
        schedules.firstOrNull?.visibilityDate ??
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
    required int recentResultLimit,
    required int upcomingFixtureLimit,
  }) async {
    final recentResultsFuture = _scanRecentResults(
      gender: gender,
      anchor: referenceNow,
      limit: recentResultLimit,
    );
    final upcomingFixturesFuture = _scanUpcomingFixtures(
      gender: gender,
      anchor: referenceNow,
      limit: upcomingFixtureLimit,
    );

    return _FifaMatchSnapshot(
      recentResults: await recentResultsFuture,
      upcomingFixtures: await upcomingFixturesFuture,
    );
  }

  Future<List<FifaRankingEntry>> _fetchRankings(
    FifaRankingGender gender, {
    String? scheduleId,
  }) async {
    final queryParameters = {
      'gender': '${gender.apiValue}',
      'count': '$_rankingPageSize',
      'language': 'en',
      if (scheduleId != null && scheduleId.trim().isNotEmpty)
        'idSchedule': scheduleId.trim(),
    };
    final uri = _baseApiUri.replace(
      path: '${_baseApiUri.path}/rankings/',
      queryParameters: queryParameters,
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

  Future<List<FifaRankingEntry>> _fetchLiveRankings(
    FifaRankingGender gender,
  ) async {
    final uri = _baseApiUri.replace(
      path: '${_baseApiUri.path}/fifarankings/rankings/live',
      queryParameters: {
        'gender': '${gender.apiValue}',
        'sportType': '$_footballSportType',
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

  Future<List<FifaRankingEntry>> _fetchLatestRankings(
    FifaRankingGender gender,
    List<_FifaRankingSchedule> schedules,
  ) async {
    final liveRankings = await _fetchLiveRankings(gender);
    if (liveRankings.isNotEmpty) {
      return liveRankings;
    }

    final latestScheduleId = schedules.firstOrNull?.id;
    if (latestScheduleId != null && latestScheduleId.isNotEmpty) {
      final scheduledRankings = await _fetchRankings(
        gender,
        scheduleId: latestScheduleId,
      );
      if (scheduledRankings.isNotEmpty) {
        return scheduledRankings;
      }
    }
    return _fetchRankings(gender);
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

  Future<List<FifaAMatchEntry>> _scanRecentResults({
    required FifaRankingGender gender,
    required DateTime anchor,
    required int limit,
  }) async {
    final collected = <FifaAMatchEntry>[];
    final seenIds = <String>{};
    var cursor = anchor;
    for (var window = 0; window < 24 && collected.length < limit; window++) {
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
    collected.sort((a, b) => b.kickoffAt.compareTo(a.kickoffAt));
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
      final points = _asDouble(item['DecimalTotalPoints']) ??
          _asDouble(item['TotalPoints']);
      final previousPoints =
          _asDouble(item['DecimalPrevPoints']) ?? _asDouble(item['PrevPoints']);
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

  static FifaTeamDetail? parseTeamDetail(dynamic decoded) {
    if (decoded is! Map) return null;
    final item = decoded.cast<String, dynamic>();
    final teamId = _asString(item['IdTeam']);
    final teamName = _localizedDescription(item['Name']).isNotEmpty
        ? _localizedDescription(item['Name'])
        : _asString(item['ShortClubName']);
    final countryCode = _asString(item['IdCountry']);
    if (teamId.isEmpty || teamName.isEmpty || countryCode.isEmpty) {
      return null;
    }
    final stadium = _asMap(item['Stadium']);
    return FifaTeamDetail(
      teamId: teamId,
      teamName: teamName,
      countryCode: countryCode,
      abbreviation: _asString(item['Abbreviation']),
      confederationCode: _asString(item['IdConfederation']),
      city: _asString(item['City']),
      street: _asString(item['Street']),
      officialSite: _asString(item['OfficialSite']),
      stadiumName: _localizedDescription(stadium['Name']),
      foundationYear: _asInt(item['FoundationYear']),
    );
  }

  static FifaAMatchDetail? parseFifaMatchDetail(
    dynamic decoded, {
    required FifaAMatchEntry fallback,
  }) {
    if (decoded is! Map) return null;
    final item = decoded.cast<String, dynamic>();
    final home = _asMap(item['HomeTeam']);
    final away = _asMap(item['AwayTeam']);
    final possession = _parsePossession(item['BallPossession']);
    return FifaAMatchDetail(
      match: _parseNationalMatch(item) ?? fallback,
      homeScorers: _parseGoalScorers(home),
      awayScorers: _parseGoalScorers(away),
      homeAssists: _parseGoalAssists(home),
      awayAssists: _parseGoalAssists(away),
      homeBookings: _parseBookings(home),
      awayBookings: _parseBookings(away),
      homePlayers: _parseMatchPlayers(home),
      awayPlayers: _parseMatchPlayers(away),
      homeTactics: _asString(home['Tactics']),
      awayTactics: _asString(away['Tactics']),
      homePossession: possession[0],
      awayPossession: possession[1],
      attendance: _asInt(item['Attendance']),
    );
  }

  static KfaMatchOverview parseKfaMatchOverview(String html, {int limit = 8}) {
    final upcoming = <KfaMatchEntry>[];
    final upcomingSection = _between(
      html,
      '<div class="next_match">',
      '<!-- match result -->',
    );
    final upcomingPattern = RegExp(
      r'''<li\s+onclick="location\.href='([^']*)';"[^>]*>(.*?</ul>\s*</li>)''',
      dotAll: true,
    );
    for (final match in upcomingPattern.allMatches(upcomingSection)) {
      final block = match.group(2) ?? '';
      final entry = _parseKfaUpcomingMatch(
        block: block,
        sourcePath: match.group(1) ?? '',
        index: upcoming.length,
      );
      if (entry == null) continue;
      upcoming.add(entry);
      if (upcoming.length >= limit) break;
    }

    final recent = <KfaMatchEntry>[];
    final resultSection = _between(
      html,
      '<div class="match_result"',
      '<!-- //반복 -->',
    );
    final resultPattern = RegExp(
      r'''<div class="result_info">\s*(.*?)\s*</div>''',
      dotAll: true,
    );
    for (final match in resultPattern.allMatches(resultSection)) {
      final entry = _parseKfaResultMatch(
        block: match.group(1) ?? '',
        index: recent.length,
      );
      if (entry == null) continue;
      recent.add(entry);
      if (recent.length >= limit) break;
    }

    return KfaMatchOverview(recentResults: recent, upcomingFixtures: upcoming);
  }

  static KfaMatchEntry? _parseKfaUpcomingMatch({
    required String block,
    required String sourcePath,
    required int index,
  }) {
    if (!_isSeniorMenKfaMatch(block)) return null;
    final competition = _htmlText(
      _firstGroup(
        block,
        RegExp(r'<p class="title">\s*(.*?)\s*</p>', dotAll: true),
      ),
    );
    final venue = _htmlText(
      _firstGroup(
        block,
        RegExp(r'<span class="stadium">\s*(.*?)\s*</span>', dotAll: true),
      ),
    );
    final dateBlock = _firstGroup(
      block,
      RegExp(r'<p class="date">\s*(.*?)\s*</p>', dotAll: true),
    );
    final dateLabel = _htmlText(
      _firstGroup(dateBlock, RegExp(r'<b>\s*(.*?)\s*</b>', dotAll: true)),
    );
    final timeLabel = _htmlText(
      dateBlock
          .replaceAll(RegExp(r'<b>.*?</b>', dotAll: true), ' ')
          .replaceAll(RegExp(r'<span>.*?</span>', dotAll: true), ' '),
    );
    final teams = _parseKfaTeams(block);
    if (competition.isEmpty ||
        dateLabel.isEmpty ||
        teams.length < 2 ||
        !_hasKoreaTeam(teams)) {
      return null;
    }
    return KfaMatchEntry(
      matchId: 'kfa-upcoming-$index-$dateLabel-${teams.join('-')}',
      competition: competition,
      venue: venue,
      dateLabel: dateLabel,
      timeLabel: timeLabel,
      homeTeamName: _normalizeKfaTeamName(teams[0].name),
      awayTeamName: _normalizeKfaTeamName(teams[1].name),
      homeScore: null,
      awayScore: null,
      status: KfaMatchStatus.scheduled,
      sourceUrl: _resolveKfaSource(sourcePath),
    );
  }

  static KfaMatchEntry? _parseKfaResultMatch({
    required String block,
    required int index,
  }) {
    if (!_isSeniorMenKfaMatch(block)) return null;
    final competition = _htmlText(
      _firstGroup(
        block,
        RegExp(r'<p class="result_title">\s*(.*?)\s*</p>', dotAll: true),
      ),
    );
    final venue = _htmlText(
      _firstGroup(
        block,
        RegExp(r'<span class="stadium_en">\s*(.*?)\s*</span>', dotAll: true),
      ),
    );
    final dateLabel = _htmlText(
      _firstGroup(block, RegExp(r'<em>\s*(.*?)\s*</em>', dotAll: true)),
    );
    final teams = _parseKfaTeams(block);
    if (competition.isEmpty ||
        dateLabel.isEmpty ||
        teams.length < 2 ||
        !_hasKoreaTeam(teams)) {
      return null;
    }
    return KfaMatchEntry(
      matchId: 'kfa-result-$index-$dateLabel-${teams.join('-')}',
      competition: competition,
      venue: venue,
      dateLabel: dateLabel,
      timeLabel: '',
      homeTeamName: _normalizeKfaTeamName(teams[0].name),
      awayTeamName: _normalizeKfaTeamName(teams[1].name),
      homeScore: teams[0].score,
      awayScore: teams[1].score,
      status: KfaMatchStatus.finished,
      sourceUrl: _kfaHomeUri,
    );
  }

  static List<_KfaTeamToken> _parseKfaTeams(String block) {
    final countryBlock = _firstGroup(
      block,
      RegExp(r'<ul[^>]*>\s*(.*?)\s*</ul>', dotAll: true),
    );
    if (countryBlock.isEmpty) return const <_KfaTeamToken>[];
    final teams = <_KfaTeamToken>[];
    final teamPattern = RegExp(r'<li[^>]*>\s*(.*?)\s*</li>', dotAll: true);
    for (final match in teamPattern.allMatches(countryBlock)) {
      final teamBlock = match.group(1) ?? '';
      final scoreText = _htmlText(
        _firstGroup(
          teamBlock,
          RegExp(r'<span[^>]*>\s*([^<]*)\s*</span>', dotAll: true),
        ),
      );
      final labelBlock = teamBlock.replaceAll(
        RegExp(r'<span[^>]*>.*?</span>', dotAll: true),
        ' ',
      );
      final name = _htmlText(labelBlock);
      if (name.isEmpty) continue;
      teams.add(_KfaTeamToken(name: name, score: int.tryParse(scoreText)));
    }
    return teams;
  }

  static bool _isSeniorMenKfaMatch(String block) {
    final text = _htmlText(block).replaceAll(RegExp(r'\s+'), '');
    if (text.isEmpty || !_hasKoreaText(text)) return false;
    return !RegExp(r'여자|U-?\d|유니버시아드|풋살').hasMatch(text);
  }

  static bool _hasKoreaTeam(List<_KfaTeamToken> teams) =>
      teams.any((team) => _hasKoreaText(team.name));

  static bool _hasKoreaText(String value) {
    final normalized = value.replaceAll(RegExp(r'\s+'), '');
    return normalized.contains('대한민국') || normalized.contains('남자국가대표팀');
  }

  static String _normalizeKfaTeamName(String value) {
    final name = value.trim();
    if (name.contains('남자 국가대표팀') || name.contains('남자국가대표팀')) {
      return '대한민국';
    }
    return name;
  }

  static Uri _resolveKfaSource(String sourcePath) {
    if (sourcePath.trim().isEmpty) return _kfaHomeUri;
    return _kfaHomeUri.resolve(sourcePath.trim());
  }

  static String _between(String input, String start, String end) {
    final startIndex = input.indexOf(start);
    if (startIndex < 0) return '';
    final contentStart = startIndex + start.length;
    final endIndex = input.indexOf(end, contentStart);
    if (endIndex < 0) return input.substring(contentStart);
    return input.substring(contentStart, endIndex);
  }

  static List<_FifaRankingSchedule> _parseRankingSchedules(dynamic decoded) {
    if (decoded is! Map || decoded['Results'] is! List) {
      return const <_FifaRankingSchedule>[];
    }
    final items = <_FifaRankingSchedule>[];
    for (final raw in decoded['Results'] as List<dynamic>) {
      if (raw is! Map) continue;
      final item = raw.cast<String, dynamic>();
      final id = _firstNonEmpty([
        _asString(item['IdRankingSchedule']),
        _asString(item['IdSchedule']),
      ]);
      final officialDate = DateTime.tryParse(
        _asString(item['OfficialDate']),
      ).toUtcOrNull();
      final visibilityDate = DateTime.tryParse(
        _asString(item['VisibilityDate']),
      ).toUtcOrNull();
      final matchWindowEndDate = _parseDateOnlyUtc(item['MatchWindowEndDate']);
      if (officialDate == null || matchWindowEndDate == null) {
        continue;
      }
      items.add(
        _FifaRankingSchedule(
          id: id,
          officialDate: officialDate,
          visibilityDate: visibilityDate,
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
    final home = _firstMap([raw['HomeTeam'], raw['Home']]);
    final away = _firstMap([raw['AwayTeam'], raw['Away']]);
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
    final homeScore = _firstInt([
      home['Score'],
      home['TeamScore'],
      home['Goals'],
      home['Result'],
      raw['HomeScore'],
      raw['HomeTeamScore'],
      raw['ScoreHome'],
    ]);
    final awayScore = _firstInt([
      away['Score'],
      away['TeamScore'],
      away['Goals'],
      away['Result'],
      raw['AwayScore'],
      raw['AwayTeamScore'],
      raw['ScoreAway'],
    ]);
    final homePenaltyScore = _firstInt([
      home['PenaltyScore'],
      home['PenaltyShootoutScore'],
      home['ShootoutScore'],
      home['TeamPenaltyScore'],
      home['ScorePenalty'],
      home['PenaltyGoals'],
      raw['HomePenaltyScore'],
      raw['HomeTeamPenaltyScore'],
      raw['HomePenaltyShootoutScore'],
      raw['HomeShootoutScore'],
      raw['PenaltyScoreHome'],
      raw['ScoreHomePenalty'],
    ]);
    final awayPenaltyScore = _firstInt([
      away['PenaltyScore'],
      away['PenaltyShootoutScore'],
      away['ShootoutScore'],
      away['TeamPenaltyScore'],
      away['ScorePenalty'],
      away['PenaltyGoals'],
      raw['AwayPenaltyScore'],
      raw['AwayTeamPenaltyScore'],
      raw['AwayPenaltyShootoutScore'],
      raw['AwayShootoutScore'],
      raw['PenaltyScoreAway'],
      raw['ScoreAwayPenalty'],
    ]);
    final period = _asInt(raw['Period']) ?? 0;
    final statusCode = _firstInt([
      raw['MatchStatus'],
      raw['Status'],
      raw['StatusCode'],
    ]);
    final statusText = _firstNonEmpty([
      _localizedDescription(raw['Status']),
      _localizedDescription(raw['MatchStatus']),
      _localizedDescription(raw['MatchStatusName']),
      _localizedDescription(raw['MatchStatusDescription']),
      _localizedDescription(raw['PeriodName']),
      _asString(raw['StatusText']),
    ]);
    final stadium = _asMap(raw['Stadium']);
    return FifaAMatchEntry(
      matchId: matchId,
      matchNumber: _asInt(raw['MatchNumber']),
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
      homePenaltyScore: homePenaltyScore,
      awayPenaltyScore: awayPenaltyScore,
      status: _parseMatchStatus(
        period: period,
        statusCode: statusCode,
        statusText: statusText,
        homeScore: homeScore,
        awayScore: awayScore,
      ),
    );
  }

  static List<FifaMatchPlayer> _parseMatchPlayers(Map<String, dynamic> team) {
    final rawPlayers = team['Players'];
    if (rawPlayers is! List) return const <FifaMatchPlayer>[];
    final players = <FifaMatchPlayer>[];
    for (final raw in rawPlayers) {
      if (raw is! Map) continue;
      final player = raw.cast<String, dynamic>();
      final playerId = _asString(player['IdPlayer']);
      final shortName = _localizedDescription(player['ShortName']);
      final fullName = _localizedDescription(player['PlayerName']);
      final playerName = shortName.isNotEmpty ? shortName : fullName;
      if (playerId.isEmpty || playerName.isEmpty) continue;
      players.add(
        FifaMatchPlayer(
          playerId: playerId,
          playerName: playerName,
          fullName: fullName,
          shirtNumber: _asInt(player['ShirtNumber']),
          position: _parsePlayerPosition(_asInt(player['Position'])),
          isStarting: _asInt(player['Status']) == 1,
          isCaptain: player['Captain'] == true,
          pictureUrl: _asString(_asMap(player['PlayerPicture'])['PictureUrl']),
        ),
      );
    }
    players.sort((a, b) {
      final starting = (b.isStarting ? 1 : 0).compareTo(a.isStarting ? 1 : 0);
      if (starting != 0) return starting;
      final shirtA = a.shirtNumber ?? 999;
      final shirtB = b.shirtNumber ?? 999;
      final shirt = shirtA.compareTo(shirtB);
      if (shirt != 0) return shirt;
      return a.playerName.compareTo(b.playerName);
    });
    return players.toList(growable: false);
  }

  static FifaMatchPlayerPosition _parsePlayerPosition(int? raw) {
    return switch (raw) {
      0 => FifaMatchPlayerPosition.goalkeeper,
      1 => FifaMatchPlayerPosition.defender,
      2 => FifaMatchPlayerPosition.midfielder,
      3 => FifaMatchPlayerPosition.forward,
      _ => FifaMatchPlayerPosition.unknown,
    };
  }

  static FifaAMatchStatus _parseMatchStatus({
    required int period,
    required int? statusCode,
    required String statusText,
    required int? homeScore,
    required int? awayScore,
  }) {
    final normalizedStatus = statusText.toLowerCase();
    if (_looksLiveStatus(normalizedStatus)) {
      return FifaAMatchStatus.live;
    }
    if (_looksFinishedStatus(normalizedStatus)) {
      return FifaAMatchStatus.finished;
    }
    if (_looksScheduledStatus(normalizedStatus)) {
      return FifaAMatchStatus.scheduled;
    }
    if (statusCode == 3) {
      return FifaAMatchStatus.live;
    }
    if (statusCode == 0) {
      return FifaAMatchStatus.finished;
    }
    if (statusCode == 1) {
      return FifaAMatchStatus.scheduled;
    }
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

  static bool _looksLiveStatus(String value) {
    return value.contains('live') ||
        value.contains('in progress') ||
        value.contains('first half') ||
        value.contains('second half') ||
        value.contains('half-time') ||
        value.contains('half time') ||
        value.contains('extra time') ||
        value.contains('penalty shootout') ||
        value.contains('playing');
  }

  static bool _looksFinishedStatus(String value) {
    return value.contains('finished') ||
        value.contains('full-time') ||
        value.contains('full time') ||
        value == 'ft' ||
        value.contains('final') ||
        value.contains('ended') ||
        value.contains('after penalties') ||
        value == 'aet';
  }

  static bool _looksScheduledStatus(String value) {
    return value.contains('scheduled') ||
        value.contains('not started') ||
        value.contains('pre-match') ||
        value.contains('pre match') ||
        value.contains('upcoming') ||
        value == 'fixture';
  }

  static List<FifaMatchScorer> _parseGoalScorers(Map<String, dynamic> team) {
    final rawGoals = team['Goals'];
    if (rawGoals is! List) return const <FifaMatchScorer>[];
    final playerNames = _playerNamesById(team);
    final scorers = <FifaMatchScorer>[];
    for (final raw in rawGoals) {
      if (raw is! Map) continue;
      final goal = raw.cast<String, dynamic>();
      final playerId = _asString(goal['IdPlayer']);
      final playerName = playerNames[playerId] ??
          _firstNonEmpty([
            _localizedDescription(goal['PlayerName']),
            _localizedDescription(goal['ScorerName']),
          ]);
      scorers.add(
        FifaMatchScorer(
          playerName: playerName,
          minute: _asString(goal['Minute']),
        ),
      );
    }
    return scorers;
  }

  static List<FifaMatchAssist> _parseGoalAssists(Map<String, dynamic> team) {
    final rawGoals = team['Goals'];
    if (rawGoals is! List) return const <FifaMatchAssist>[];
    final playerNames = _playerNamesById(team);
    final assists = <FifaMatchAssist>[];
    for (final raw in rawGoals) {
      if (raw is! Map) continue;
      final goal = raw.cast<String, dynamic>();
      final assistPlayerId = _firstNonEmpty([
        _asString(goal['IdAssistPlayer']),
        _asString(goal['IdPlayerAssist']),
        _asString(goal['AssistPlayerId']),
      ]);
      if (assistPlayerId.isEmpty) continue;
      final assistPlayerName = playerNames[assistPlayerId] ??
          _firstNonEmpty([
            _localizedDescription(goal['AssistPlayerName']),
            _localizedDescription(goal['AssistantName']),
          ]);
      if (assistPlayerName.isEmpty) continue;
      assists.add(
        FifaMatchAssist(
          playerName: assistPlayerName,
          minute: _asString(goal['Minute']),
        ),
      );
    }
    return assists;
  }

  static List<FifaMatchBooking> _parseBookings(Map<String, dynamic> team) {
    final rawBookings = team['Bookings'];
    if (rawBookings is! List) return const <FifaMatchBooking>[];
    final playerNames = _playerNamesById(team);
    final bookings = <FifaMatchBooking>[];
    for (final raw in rawBookings) {
      if (raw is! Map) continue;
      final booking = raw.cast<String, dynamic>();
      final playerId = _asString(booking['IdPlayer']);
      final playerName = playerNames[playerId] ??
          _firstNonEmpty([
            _localizedDescription(booking['PlayerName']),
            _localizedDescription(booking['Name']),
          ]);
      if (playerName.isEmpty) continue;
      final cardType = _parseBookingCardType(_asInt(booking['Card']));
      if (cardType == FifaMatchCardType.unknown) continue;
      bookings.add(
        FifaMatchBooking(
          playerName: playerName,
          minute: _asString(booking['Minute']),
          cardType: cardType,
        ),
      );
    }
    return bookings;
  }

  static FifaMatchCardType _parseBookingCardType(int? raw) {
    return switch (raw) {
      1 => FifaMatchCardType.yellow,
      2 => FifaMatchCardType.red,
      _ => FifaMatchCardType.unknown,
    };
  }

  static Map<String, String> _playerNamesById(Map<String, dynamic> team) {
    final rawPlayers = team['Players'];
    if (rawPlayers is! List) return const <String, String>{};
    final names = <String, String>{};
    for (final raw in rawPlayers) {
      if (raw is! Map) continue;
      final player = raw.cast<String, dynamic>();
      final playerId = _asString(player['IdPlayer']);
      if (playerId.isEmpty) continue;
      final shortName = _localizedDescription(player['ShortName']);
      final fullName = _localizedDescription(player['PlayerName']);
      final name = shortName.isNotEmpty ? shortName : fullName;
      if (name.isNotEmpty) {
        names[playerId] = name;
      }
    }
    return names;
  }

  static List<double?> _parsePossession(dynamic raw) {
    final possession = _asMap(raw);
    var home = _asDouble(possession['OverallHome']);
    var away = _asDouble(possession['OverallAway']);
    if (home == null && away != null) {
      home = 100 - away;
    } else if (away == null && home != null) {
      away = 100 - home;
    }
    if (home == null || away == null || home < 0 || away < 0) {
      return const <double?>[null, null];
    }
    return <double?>[
      home.clamp(0, 100).toDouble(),
      away.clamp(0, 100).toDouble(),
    ];
  }

  static String _firstNonEmpty(Iterable<String> values) {
    for (final value in values) {
      if (value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  static int? _firstInt(Iterable<dynamic> values) {
    for (final value in values) {
      final parsed = _asInt(value);
      if (parsed != null) return parsed;
    }
    return null;
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

  static String _formatApiDay(DateTime value) {
    final utc = value.toUtc();
    final month = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    return '${utc.year}-$month-$day';
  }

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

  static String _htmlText(String html) {
    final withBreaks = html.replaceAll(
      RegExp(r'<br\s*/?>', caseSensitive: false),
      ' ',
    );
    final withoutTags = withBreaks.replaceAll(RegExp(r'<[^>]+>'), ' ');
    return _decodeHtmlEntities(
      withoutTags,
    ).replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _decodeHtmlEntities(String value) {
    return value
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
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

  static Map<String, dynamic> _firstMap(Iterable<dynamic> values) {
    for (final value in values) {
      final map = _asMap(value);
      if (map.isNotEmpty) return map;
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
  final String id;
  final DateTime officialDate;
  final DateTime? visibilityDate;
  final DateTime matchWindowEndDate;

  const _FifaRankingSchedule({
    required this.id,
    required this.officialDate,
    required this.visibilityDate,
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

class _KfaTeamToken {
  final String name;
  final int? score;

  const _KfaTeamToken({required this.name, required this.score});

  @override
  String toString() => name;
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
