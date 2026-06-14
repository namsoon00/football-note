import '../domain/entities/fifa_world_overview.dart';
import 'fifa_world_overview_service.dart';
import 'world_cup_schedule.dart';

class WorldCupLiveData {
  final List<WorldCupFixture> fixtures;
  final Map<int, FifaAMatchEntry> officialMatchesByFixtureNumber;
  final DateTime refreshedAt;

  const WorldCupLiveData({
    required this.fixtures,
    required this.officialMatchesByFixtureNumber,
    required this.refreshedAt,
  });

  bool get hasOfficialMatches => officialMatchesByFixtureNumber.isNotEmpty;
}

class WorldCupLiveDataService {
  static const Duration _windowSize = Duration(days: 6);
  static const Duration _fixtureMatchTolerance = Duration(hours: 4);

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

    final referenceNow = (now ?? DateTime.now()).toUtc();
    final firstKickoff = fixtures.first.kickoffUtc.toUtc();
    final lastKickoff = fixtures.last.kickoffUtc.toUtc();
    final start = firstKickoff.subtract(const Duration(hours: 12));
    final end = _fetchEnd(
      referenceNow: referenceNow,
      firstKickoff: firstKickoff,
      lastKickoff: lastKickoff,
    );
    final officialMatches = await _fetchWorldCupMatches(start: start, end: end);
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
      refreshedAt: DateTime.now().toUtc(),
    );
  }

  Future<FifaAMatchDetail?> fetchMatchDetail(FifaAMatchEntry match) {
    return _fifaService.fetchMatchDetail(match: match);
  }

  DateTime _fetchEnd({
    required DateTime referenceNow,
    required DateTime firstKickoff,
    required DateTime lastKickoff,
  }) {
    final tournamentEnd = lastKickoff.add(const Duration(hours: 12));
    if (referenceNow.isBefore(firstKickoff)) {
      return _minDateTime(
        firstKickoff.add(const Duration(days: 7)),
        tournamentEnd,
      );
    }
    return _minDateTime(
      referenceNow.add(const Duration(days: 1)),
      tournamentEnd,
    );
  }

  Future<List<FifaAMatchEntry>> _fetchWorldCupMatches({
    required DateTime start,
    required DateTime end,
  }) async {
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
      FifaAMatchEntry? bestMatch;
      Duration? bestDelta;
      for (final match in officialMatches) {
        if (usedMatchIds.contains(match.matchId)) continue;
        if (!_teamsMatchFixture(fixture, match)) continue;
        final delta = _absoluteDuration(
          fixture.kickoffUtc.toUtc().difference(match.kickoffAt.toUtc()),
        );
        if (delta > _fixtureMatchTolerance) continue;
        if (bestDelta == null || delta < bestDelta) {
          bestMatch = match;
          bestDelta = delta;
        }
      }
      if (bestMatch != null) {
        matchesByFixtureNumber[fixture.matchNumber] = bestMatch;
        usedMatchIds.add(bestMatch.matchId);
      }
    }

    return matchesByFixtureNumber;
  }

  WorldCupFixture _fixtureWithOfficialResult(
    WorldCupFixture fixture,
    FifaAMatchEntry? officialMatch,
  ) {
    if (officialMatch == null) return fixture;
    if (officialMatch.status != FifaAMatchStatus.finished ||
        !officialMatch.hasScore) {
      return fixture.copyWithScore(homeScore: null, awayScore: null);
    }
    final sameDirection =
        _teamKey(fixture.homeTeam) == _teamKey(officialMatch.homeTeamName) &&
        _teamKey(fixture.awayTeam) == _teamKey(officialMatch.awayTeamName);
    if (sameDirection) {
      return fixture.copyWithScore(
        homeScore: officialMatch.homeScore,
        awayScore: officialMatch.awayScore,
      );
    }
    return fixture.copyWithScore(
      homeScore: officialMatch.awayScore,
      awayScore: officialMatch.homeScore,
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
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'\s+'), ' ');
    return switch (normalized) {
      "cote d'ivoire" => 'ivory coast',
      'cote divoire' => 'ivory coast',
      'united states' => 'usa',
      _ => normalized,
    };
  }

  DateTime _minDateTime(DateTime a, DateTime b) => a.isBefore(b) ? a : b;

  Duration _absoluteDuration(Duration value) =>
      value.isNegative ? -value : value;
}
