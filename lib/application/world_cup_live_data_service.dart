import '../domain/entities/fifa_world_overview.dart';
import 'fifa_world_overview_service.dart';
import 'world_cup_schedule.dart';

class WorldCupLiveData {
  final List<WorldCupFixture> fixtures;
  final Map<int, FifaAMatchEntry> officialMatchesByFixtureNumber;
  final Map<String, FifaRankingEntry> rankingsByTeam;
  final DateTime refreshedAt;

  const WorldCupLiveData({
    required this.fixtures,
    required this.officialMatchesByFixtureNumber,
    this.rankingsByTeam = const <String, FifaRankingEntry>{},
    required this.refreshedAt,
  });

  bool get hasOfficialMatches => officialMatchesByFixtureNumber.isNotEmpty;
}

class WorldCupLiveDataService {
  static const Duration _windowSize = Duration(days: 6);
  static const Duration _fixtureMatchTolerance = Duration(hours: 4);
  static const String _worldCupCompetitionId = '17';
  static const String _worldCupSeasonId = '285023';

  final FifaWorldOverviewService _fifaService;
  final bool _ownsFifaService;

  WorldCupLiveDataService({FifaWorldOverviewService? fifaService})
      : _fifaService = fifaService ?? FifaWorldOverviewService(),
        _ownsFifaService = fifaService == null;

  void dispose() {
    if (_ownsFifaService) {
      _fifaService.dispose();
    }
  }

  Future<WorldCupLiveData> fetchLatest({
    List<WorldCupFixture> baseFixtures = worldCupFixtures,
    DateTime? now,
  }) async {
    final fixtures = baseFixtures.toList(growable: false);
    if (fixtures.isEmpty) {
      return WorldCupLiveData(
        fixtures: fixtures,
        officialMatchesByFixtureNumber: const <int, FifaAMatchEntry>{},
        refreshedAt: DateTime.now().toUtc(),
      );
    }

    final firstKickoff = fixtures.first.kickoffUtc.toUtc();
    final lastKickoff = fixtures.last.kickoffUtc.toUtc();
    final start = firstKickoff.subtract(const Duration(hours: 12));
    final end = lastKickoff.add(const Duration(hours: 12));
    final officialMatchesFuture = _fetchWorldCupMatches(start: start, end: end);
    final rankingsFuture = _fifaService.fetchRankingOverview(
      gender: FifaRankingGender.men,
    );
    final officialMatches = await officialMatchesFuture;
    final rankingOverview = await rankingsFuture;
    final matchesByFixtureNumber = _matchOfficialMatches(
      fixtures,
      officialMatches,
    );
    final updatedFixtures = [
      for (final fixture in fixtures)
        _fixtureWithOfficialResult(
          fixture,
          matchesByFixtureNumber[fixture.matchNumber],
        ),
    ];

    return WorldCupLiveData(
      fixtures: updatedFixtures,
      officialMatchesByFixtureNumber: Map<int, FifaAMatchEntry>.unmodifiable(
        matchesByFixtureNumber,
      ),
      rankingsByTeam: Map<String, FifaRankingEntry>.unmodifiable(
        _rankingsByWorldCupTeam(
          rankings: rankingOverview.rankings,
          fixtures: fixtures,
        ),
      ),
      refreshedAt: DateTime.now().toUtc(),
    );
  }

  Future<FifaAMatchDetail?> fetchMatchDetail(
    FifaAMatchEntry match, {
    String language = 'en',
  }) {
    return _fifaService.fetchMatchDetail(match: match, language: language);
  }

  Future<FifaCompetitionPlayerStatRankings> fetchPlayerStatRankings({
    String language = 'en',
  }) {
    return _fifaService.fetchCompetitionPlayerStatRankings(
      competitionId: _worldCupSeasonId,
      language: language,
    );
  }

  Future<List<FifaAMatchEntry>> _fetchWorldCupMatches({
    required DateTime start,
    required DateTime end,
  }) async {
    final competitionMatches = await _fifaService.fetchCompetitionMatches(
      gender: FifaRankingGender.men,
      competitionId: _worldCupCompetitionId,
      seasonId: _worldCupSeasonId,
      start: start,
      end: end,
    );
    final worldCupCompetitionMatches =
        competitionMatches.where(_isWorldCupMatch).toList(growable: false);
    if (worldCupCompetitionMatches.isNotEmpty) {
      return worldCupCompetitionMatches;
    }

    final matches = <String, FifaAMatchEntry>{};
    var cursor = start.toUtc();
    final endUtc = end.toUtc();

    while (!cursor.isAfter(endUtc)) {
      final windowEnd = _minDateTime(cursor.add(_windowSize), endUtc);
      final windowMatches = await _fifaService.fetchNationalMatches(
        gender: FifaRankingGender.men,
        start: cursor,
        end: windowEnd,
      );
      for (final match in windowMatches) {
        if (_isWorldCupMatch(match)) {
          matches[match.matchId] = match;
        }
      }
      cursor = windowEnd.add(const Duration(seconds: 1));
    }

    final sorted = matches.values.toList()
      ..sort((a, b) => a.kickoffAt.compareTo(b.kickoffAt));
    return sorted.toList(growable: false);
  }

  Map<int, FifaAMatchEntry> _matchOfficialMatches(
    List<WorldCupFixture> fixtures,
    List<FifaAMatchEntry> officialMatches,
  ) {
    final matchesByFixtureNumber = <int, FifaAMatchEntry>{};
    final usedMatchIds = <String>{};

    for (final fixture in fixtures) {
      final match = _bestOfficialMatchForFixture(
        fixture: fixture,
        officialMatches: officialMatches,
        usedMatchIds: usedMatchIds,
        matchesFixture: (match) => _teamsMatchFixture(fixture, match),
      );
      if (match != null) {
        matchesByFixtureNumber[fixture.matchNumber] = match;
        usedMatchIds.add(match.matchId);
      }
    }

    for (final fixture in fixtures) {
      if (matchesByFixtureNumber.containsKey(fixture.matchNumber)) continue;
      final match = _bestOfficialMatchForFixture(
        fixture: fixture,
        officialMatches: officialMatches,
        usedMatchIds: usedMatchIds,
        matchesFixture: (match) => match.matchNumber == fixture.matchNumber,
      );
      if (match != null) {
        matchesByFixtureNumber[fixture.matchNumber] = match;
        usedMatchIds.add(match.matchId);
      }
    }

    return matchesByFixtureNumber;
  }

  FifaAMatchEntry? _bestOfficialMatchForFixture({
    required WorldCupFixture fixture,
    required List<FifaAMatchEntry> officialMatches,
    required Set<String> usedMatchIds,
    required bool Function(FifaAMatchEntry match) matchesFixture,
  }) {
    FifaAMatchEntry? bestMatch;
    Duration? bestDelta;
    for (final match in officialMatches) {
      if (usedMatchIds.contains(match.matchId)) continue;
      if (!matchesFixture(match)) continue;
      final delta = _absoluteDuration(
        fixture.kickoffUtc.toUtc().difference(match.kickoffAt.toUtc()),
      );
      if (delta > _fixtureMatchTolerance) continue;
      if (bestDelta == null || delta < bestDelta) {
        bestMatch = match;
        bestDelta = delta;
      }
    }
    return bestMatch;
  }

  Map<String, FifaRankingEntry> _rankingsByWorldCupTeam({
    required List<FifaRankingEntry> rankings,
    required List<WorldCupFixture> fixtures,
  }) {
    final teams = <String>{};
    for (final fixture in fixtures) {
      if (!fixture.isGroupStage) continue;
      teams
        ..add(fixture.homeTeam)
        ..add(fixture.awayTeam);
    }
    final rankingsByKey = <String, FifaRankingEntry>{
      for (final entry in rankings) _teamKey(entry.teamName): entry,
    };
    return <String, FifaRankingEntry>{
      for (final team in teams)
        if (rankingsByKey[_teamKey(team)] != null)
          team: rankingsByKey[_teamKey(team)]!,
    };
  }

  WorldCupFixture _fixtureWithOfficialResult(
    WorldCupFixture fixture,
    FifaAMatchEntry? officialMatch,
  ) {
    if (officialMatch == null) return fixture;
    if (officialMatch.status != FifaAMatchStatus.finished ||
        !officialMatch.hasScore) {
      return fixture;
    }
    final sameDirection =
        _teamKey(fixture.homeTeam) == _teamKey(officialMatch.homeTeamName) &&
            _teamKey(fixture.awayTeam) == _teamKey(officialMatch.awayTeamName);
    if (sameDirection || !fixture.isGroupStage) {
      return fixture.copyWithScore(
        homeScore: officialMatch.homeScore,
        awayScore: officialMatch.awayScore,
        homePenaltyScore: officialMatch.homePenaltyScore,
        awayPenaltyScore: officialMatch.awayPenaltyScore,
      );
    }
    final reverseDirection =
        _teamKey(fixture.homeTeam) == _teamKey(officialMatch.awayTeamName) &&
            _teamKey(fixture.awayTeam) == _teamKey(officialMatch.homeTeamName);
    if (!reverseDirection) return fixture;
    return fixture.copyWithScore(
      homeScore: officialMatch.awayScore,
      awayScore: officialMatch.homeScore,
      homePenaltyScore: officialMatch.awayPenaltyScore,
      awayPenaltyScore: officialMatch.homePenaltyScore,
    );
  }

  bool _isWorldCupMatch(FifaAMatchEntry match) {
    final competition = match.competition.toLowerCase();
    return competition.contains('world cup') &&
        !competition.contains('qualifier') &&
        !competition.contains('qualification') &&
        !competition.contains('club');
  }

  bool _teamsMatchFixture(WorldCupFixture fixture, FifaAMatchEntry match) {
    final fixtureHome = _teamKey(fixture.homeTeam);
    final fixtureAway = _teamKey(fixture.awayTeam);
    final officialHome = _teamKey(match.homeTeamName);
    final officialAway = _teamKey(match.awayTeamName);
    return (fixtureHome == officialHome && fixtureAway == officialAway) ||
        (fixtureHome == officialAway && fixtureAway == officialHome);
  }

  String _teamKey(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('å', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ı', 'i')
        .replaceAll('ç', 'c')
        .replaceAll('’', "'")
        .replaceAll(RegExp(r'\s+'), ' ');
    return switch (normalized) {
      "cote d'ivoire" => 'ivory coast',
      'cote divoire' => 'ivory coast',
      'cabo verde' => 'cape verde',
      'cape verde' => 'cape verde',
      'czech republic' => 'czechia',
      'czechia' => 'czechia',
      'dr congo' => 'congo dr',
      'congo dr' => 'congo dr',
      'democratic republic of congo' => 'congo dr',
      'iran' => 'iran',
      'ir iran' => 'iran',
      'turkey' => 'turkiye',
      'turkiye' => 'turkiye',
      'united states' => 'usa',
      'united states of america' => 'usa',
      'usa' => 'usa',
      _ => normalized,
    };
  }

  DateTime _minDateTime(DateTime a, DateTime b) => a.isBefore(b) ? a : b;

  Duration _absoluteDuration(Duration value) =>
      value.isNegative ? -value : value;
}
