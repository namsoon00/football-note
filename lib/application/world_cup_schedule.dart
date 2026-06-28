enum WorldCupStage {
  group,
  roundOf32,
  roundOf16,
  quarterFinal,
  semiFinal,
  thirdPlace,
  finalMatch,
}

class WorldCupFixture {
  final int matchNumber;
  final String kickoffUtcIso;
  final WorldCupStage stage;
  final String? group;
  final String homeTeam;
  final String awayTeam;
  final String venue;
  final int? homeScore;
  final int? awayScore;

  const WorldCupFixture({
    required this.matchNumber,
    required this.kickoffUtcIso,
    required this.stage,
    this.group,
    required this.homeTeam,
    required this.awayTeam,
    required this.venue,
    this.homeScore,
    this.awayScore,
  });

  DateTime get kickoffUtc => DateTime.parse(kickoffUtcIso);

  DateTime get kickoffLocal => kickoffUtc.toLocal();

  DateTime get localDay {
    final local = kickoffLocal;
    return DateTime(local.year, local.month, local.day);
  }

  bool get isGroupStage => stage == WorldCupStage.group;

  bool get hasScore => homeScore != null && awayScore != null;

  WorldCupFixture copyWithScore({
    required int? homeScore,
    required int? awayScore,
  }) {
    return WorldCupFixture(
      matchNumber: matchNumber,
      kickoffUtcIso: kickoffUtcIso,
      stage: stage,
      group: group,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      venue: venue,
      homeScore: homeScore,
      awayScore: awayScore,
    );
  }

  bool involvesCountry(String country) {
    final normalized = country.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return homeTeam.toLowerCase() == normalized ||
        awayTeam.toLowerCase() == normalized;
  }

  WorldCupFixtureTeamResult resultForTeam(String country) {
    if (!hasScore || !involvesCountry(country)) {
      return WorldCupFixtureTeamResult.scheduled;
    }
    final isHome = homeTeam.toLowerCase() == country.trim().toLowerCase();
    final teamScore = isHome ? homeScore! : awayScore!;
    final opponentScore = isHome ? awayScore! : homeScore!;
    if (teamScore > opponentScore) return WorldCupFixtureTeamResult.win;
    if (teamScore < opponentScore) return WorldCupFixtureTeamResult.loss;
    return WorldCupFixtureTeamResult.draw;
  }
}

enum WorldCupFixtureTeamResult { scheduled, win, draw, loss }

class WorldCupGroupStanding {
  final String group;
  final String team;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;

  const WorldCupGroupStanding({
    required this.group,
    required this.team,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
  });

  int get goalDifference => goalsFor - goalsAgainst;

  int get points => wins * 3 + draws;
}

class WorldCupQualificationScenario {
  final String group;
  final String team;
  final int currentPoints;
  final int remainingMatches;
  final int remainingGroupMatches;
  final int remainingPoints;
  final int finalPoints;
  final int totalCases;
  final int automaticAdvanceCases;
  final int thirdPlaceCases;
  final int eliminatedCases;
  final int bestRank;
  final int worstRank;

  const WorldCupQualificationScenario({
    required this.group,
    required this.team,
    required this.currentPoints,
    required this.remainingMatches,
    required this.remainingGroupMatches,
    required this.remainingPoints,
    required this.finalPoints,
    required this.totalCases,
    required this.automaticAdvanceCases,
    required this.thirdPlaceCases,
    required this.eliminatedCases,
    required this.bestRank,
    required this.worstRank,
  });

  int get remainingOtherMatches => remainingGroupMatches - remainingMatches;
}

class WorldCupQualificationMatchPick {
  final int matchNumber;
  final String opponentTeam;
  final WorldCupFixtureTeamResult result;
  final int points;

  const WorldCupQualificationMatchPick({
    required this.matchNumber,
    required this.opponentTeam,
    required this.result,
    required this.points,
  });
}

class WorldCupQualificationOtherMatchPick {
  final int matchNumber;
  final String homeTeam;
  final String awayTeam;
  final WorldCupFixtureTeamResult resultForHomeTeam;

  const WorldCupQualificationOtherMatchPick({
    required this.matchNumber,
    required this.homeTeam,
    required this.awayTeam,
    required this.resultForHomeTeam,
  });
}

class WorldCupQualificationOtherMatchPath {
  final List<WorldCupQualificationOtherMatchPick> picks;
  final int finalPoints;
  final int rank;

  const WorldCupQualificationOtherMatchPath({
    required this.picks,
    required this.finalPoints,
    required this.rank,
  });

  bool get isAutomaticAdvance => rank <= 2;

  bool get isThirdPlaceRace => rank == 3;

  bool get isEliminated => rank > 3;
}

class WorldCupQualificationOpponentPath {
  final int rank;
  final int matchNumber;
  final String opponentSlot;
  final List<String> opponentTeams;

  const WorldCupQualificationOpponentPath({
    required this.rank,
    required this.matchNumber,
    required this.opponentSlot,
    this.opponentTeams = const <String>[],
  });
}

class WorldCupQualificationPathScenario {
  final String group;
  final String team;
  final int currentPoints;
  final int remainingMatches;
  final int remainingGroupMatches;
  final int remainingPoints;
  final int finalPoints;
  final List<WorldCupQualificationMatchPick> picks;
  final int totalCases;
  final int automaticAdvanceCases;
  final int thirdPlaceCases;
  final int eliminatedCases;
  final int bestRank;
  final int worstRank;
  final List<WorldCupQualificationOtherMatchPath> otherMatchPaths;
  final List<WorldCupQualificationOpponentPath> opponentPaths;

  const WorldCupQualificationPathScenario({
    required this.group,
    required this.team,
    required this.currentPoints,
    required this.remainingMatches,
    required this.remainingGroupMatches,
    required this.remainingPoints,
    required this.finalPoints,
    required this.picks,
    required this.totalCases,
    required this.automaticAdvanceCases,
    required this.thirdPlaceCases,
    required this.eliminatedCases,
    required this.bestRank,
    required this.worstRank,
    required this.otherMatchPaths,
    required this.opponentPaths,
  });

  int get advancingCases => automaticAdvanceCases + thirdPlaceCases;

  bool get canAdvance => advancingCases > 0;

  bool get guaranteesAutomaticAdvance =>
      totalCases > 0 && automaticAdvanceCases == totalCases;

  int get remainingOtherMatches => remainingGroupMatches - remainingMatches;
}

const Map<String, String> _worldCupCountryCodes = <String, String>{
  'Algeria': 'DZ',
  'Argentina': 'AR',
  'Australia': 'AU',
  'Austria': 'AT',
  'Belgium': 'BE',
  'Bosnia and Herzegovina': 'BA',
  'Brazil': 'BR',
  'Canada': 'CA',
  'Cape Verde': 'CV',
  'Colombia': 'CO',
  'Congo DR': 'CD',
  'Croatia': 'HR',
  'Curacao': 'CW',
  'Czechia': 'CZ',
  'Ecuador': 'EC',
  'Egypt': 'EG',
  'France': 'FR',
  'Germany': 'DE',
  'Ghana': 'GH',
  'Haiti': 'HT',
  'Iran': 'IR',
  'Iraq': 'IQ',
  'Ivory Coast': 'CI',
  'Japan': 'JP',
  'Jordan': 'JO',
  'Korea Republic': 'KR',
  'Mexico': 'MX',
  'Morocco': 'MA',
  'Netherlands': 'NL',
  'New Zealand': 'NZ',
  'Norway': 'NO',
  'Panama': 'PA',
  'Paraguay': 'PY',
  'Portugal': 'PT',
  'Qatar': 'QA',
  'Saudi Arabia': 'SA',
  'Senegal': 'SN',
  'South Africa': 'ZA',
  'Spain': 'ES',
  'Sweden': 'SE',
  'Switzerland': 'CH',
  'Tunisia': 'TN',
  'Turkiye': 'TR',
  'Uruguay': 'UY',
  'USA': 'US',
  'Uzbekistan': 'UZ',
};

String worldCupCountryFlag(String country) {
  final normalized = country.trim();
  if (normalized == 'England') return _subdivisionFlag('gbeng');
  if (normalized == 'Scotland') return _subdivisionFlag('gbsct');
  final code = _worldCupCountryCodes[normalized];
  if (code == null || code.length != 2) return '';
  return String.fromCharCodes(
    code.toUpperCase().codeUnits.map((unit) => 0x1F1E6 + unit - 0x41),
  );
}

String _subdivisionFlag(String tag) {
  return String.fromCharCodes(<int>[
    0x1F3F4,
    for (final unit in tag.codeUnits) 0xE0000 + unit,
    0xE007F,
  ]);
}

DateTime normalizeWorldCupDay(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

List<String> worldCupCountries() {
  final countries = <String>{};
  for (final fixture in worldCupFixtures) {
    if (fixture.isGroupStage) {
      countries
        ..add(fixture.homeTeam)
        ..add(fixture.awayTeam);
    }
  }
  return countries.toList()..sort();
}

List<WorldCupFixture> worldCupFixturesForDay(
  DateTime day, {
  List<WorldCupFixture>? fixtures,
}) {
  final normalized = normalizeWorldCupDay(day);
  return (fixtures ?? worldCupFixtures)
      .where((fixture) => fixture.localDay == normalized)
      .toList(growable: false);
}

List<WorldCupFixture> worldCupFixturesForDayAndCountries(
  DateTime day,
  Iterable<String> countries, {
  List<WorldCupFixture>? fixtures,
}) {
  final selected = countries
      .map((country) => country.trim().toLowerCase())
      .where((country) => country.isNotEmpty)
      .toSet();
  if (selected.isEmpty) return const <WorldCupFixture>[];
  return worldCupFixturesForDay(day, fixtures: fixtures)
      .where(
        (fixture) =>
            selected.contains(fixture.homeTeam.toLowerCase()) ||
            selected.contains(fixture.awayTeam.toLowerCase()),
      )
      .toList(growable: false);
}

List<WorldCupFixture> worldCupFixturesForCountries(
  Iterable<String> countries, {
  List<WorldCupFixture>? fixtures,
}) {
  final selected = countries
      .map((country) => country.trim().toLowerCase())
      .where((country) => country.isNotEmpty)
      .toSet();
  if (selected.isEmpty) return const <WorldCupFixture>[];
  return (fixtures ?? worldCupFixtures)
      .where(
        (fixture) =>
            selected.contains(fixture.homeTeam.toLowerCase()) ||
            selected.contains(fixture.awayTeam.toLowerCase()),
      )
      .toList(growable: false);
}

Map<String, List<WorldCupGroupStanding>> worldCupGroupStandings({
  List<WorldCupFixture>? fixtures,
}) {
  final groups = <String, Map<String, _WorldCupGroupStandingAccumulator>>{};
  for (final fixture in fixtures ?? worldCupFixtures) {
    final group = fixture.group;
    if (!fixture.isGroupStage || group == null) continue;
    final groupStats = groups.putIfAbsent(
      group,
      () => <String, _WorldCupGroupStandingAccumulator>{},
    );
    groupStats.putIfAbsent(
      fixture.homeTeam,
      () => _WorldCupGroupStandingAccumulator(group, fixture.homeTeam),
    );
    groupStats.putIfAbsent(
      fixture.awayTeam,
      () => _WorldCupGroupStandingAccumulator(group, fixture.awayTeam),
    );
    if (!fixture.hasScore) continue;
    final home = groupStats[fixture.homeTeam]!;
    final away = groupStats[fixture.awayTeam]!;
    home.record(fixture.homeScore!, fixture.awayScore!);
    away.record(fixture.awayScore!, fixture.homeScore!);
  }

  final entries = groups.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return {
    for (final entry in entries)
      entry.key: (entry.value.values.map((stats) => stats.toStanding()).toList()
            ..sort(_compareWorldCupGroupStandings))
          .toList(growable: false),
  };
}

bool worldCupGroupComplete(
  String group, {
  List<WorldCupFixture>? fixtures,
}) {
  final normalizedGroup = group.trim().toUpperCase();
  if (normalizedGroup.isEmpty) return false;
  final groupFixtures = (fixtures ?? worldCupFixtures)
      .where(
        (fixture) => fixture.isGroupStage && fixture.group == normalizedGroup,
      )
      .toList(growable: false);
  return groupFixtures.isNotEmpty &&
      groupFixtures.every((fixture) => fixture.hasScore);
}

bool worldCupGroupStageComplete({List<WorldCupFixture>? fixtures}) {
  final groupFixtures = <String, List<WorldCupFixture>>{};
  for (final fixture in fixtures ?? worldCupFixtures) {
    final group = fixture.group;
    if (!fixture.isGroupStage || group == null) continue;
    groupFixtures.putIfAbsent(group, () => <WorldCupFixture>[]).add(fixture);
  }
  return groupFixtures.isNotEmpty &&
      groupFixtures.values.every(
        (fixtures) =>
            fixtures.isNotEmpty &&
            fixtures.every((fixture) => fixture.hasScore),
      );
}

List<WorldCupGroupStanding> worldCupBestThirdPlaceStandings({
  List<WorldCupFixture>? fixtures,
}) {
  final sourceFixtures = fixtures ?? worldCupFixtures;
  if (!worldCupGroupStageComplete(fixtures: sourceFixtures)) {
    return const <WorldCupGroupStanding>[];
  }
  final thirdPlaceStandings = <WorldCupGroupStanding>[];
  final standingsByGroup = worldCupGroupStandings(fixtures: sourceFixtures);
  for (final standings in standingsByGroup.values) {
    if (standings.length >= 3) {
      thirdPlaceStandings.add(standings[2]);
    }
  }
  thirdPlaceStandings.sort(_compareWorldCupGroupStandings);
  return List<WorldCupGroupStanding>.unmodifiable(
    thirdPlaceStandings.take(8),
  );
}

List<WorldCupQualificationScenario> worldCupRoundOf32ScenariosForTeam(
  String team, {
  List<WorldCupFixture>? fixtures,
}) {
  final normalizedTeam = team.trim();
  if (normalizedTeam.isEmpty) return const <WorldCupQualificationScenario>[];
  final sourceFixtures = fixtures ?? worldCupFixtures;
  String? group;
  for (final fixture in sourceFixtures) {
    if (fixture.isGroupStage && fixture.involvesCountry(normalizedTeam)) {
      group = fixture.group;
      break;
    }
  }
  final targetGroup = group;
  if (targetGroup == null) return const <WorldCupQualificationScenario>[];

  final groupFixtures = sourceFixtures
      .where((fixture) => fixture.isGroupStage && fixture.group == targetGroup)
      .toList(growable: false);
  final currentStandings = worldCupGroupStandings(fixtures: sourceFixtures);
  WorldCupGroupStanding? currentStanding;
  for (final standing in currentStandings[targetGroup] ?? const []) {
    if (standing.team == normalizedTeam) {
      currentStanding = standing;
      break;
    }
  }
  final baseStanding = currentStanding;
  if (baseStanding == null) return const <WorldCupQualificationScenario>[];

  final remainingFixtures = groupFixtures
      .where((fixture) => !fixture.hasScore)
      .toList(growable: false);
  final teamRemainingMatches = remainingFixtures
      .where((fixture) => fixture.involvesCountry(normalizedTeam))
      .length;
  final accumulators = <int, _WorldCupQualificationScenarioAccumulator>{};

  void recordScenario(List<WorldCupFixture> scenarioFixtures) {
    final standings =
        worldCupGroupStandings(fixtures: scenarioFixtures)[targetGroup];
    if (standings == null) return;
    final rankIndex = standings.indexWhere(
      (standing) => standing.team == normalizedTeam,
    );
    if (rankIndex < 0) return;
    final rank = rankIndex + 1;
    final finalStanding = standings[rankIndex];
    final remainingPoints = finalStanding.points - baseStanding.points;
    final accumulator = accumulators.putIfAbsent(
      remainingPoints,
      () => _WorldCupQualificationScenarioAccumulator(
        group: targetGroup,
        team: normalizedTeam,
        currentPoints: baseStanding.points,
        remainingMatches: teamRemainingMatches,
        remainingGroupMatches: remainingFixtures.length,
        remainingPoints: remainingPoints,
        finalPoints: finalStanding.points,
      ),
    );
    accumulator.record(rank);
  }

  void walk(
    int fixtureIndex,
    List<WorldCupFixture> scenarioFixtures,
  ) {
    if (fixtureIndex >= remainingFixtures.length) {
      recordScenario(scenarioFixtures);
      return;
    }

    final fixture = remainingFixtures[fixtureIndex];
    for (final score in const <(int, int)>[(1, 0), (0, 0), (0, 1)]) {
      walk(
        fixtureIndex + 1,
        [
          for (final item in scenarioFixtures)
            if (item.matchNumber == fixture.matchNumber)
              item.copyWithScore(homeScore: score.$1, awayScore: score.$2)
            else
              item,
        ],
      );
    }
  }

  walk(0, sourceFixtures);

  return accumulators.values
      .map((accumulator) => accumulator.toScenario())
      .toList(growable: false)
    ..sort((a, b) => b.remainingPoints.compareTo(a.remainingPoints));
}

List<WorldCupQualificationPathScenario> worldCupRoundOf32PathScenariosForTeam(
  String team, {
  List<WorldCupFixture>? fixtures,
}) {
  final normalizedTeam = team.trim();
  if (normalizedTeam.isEmpty) {
    return const <WorldCupQualificationPathScenario>[];
  }
  final sourceFixtures = fixtures ?? worldCupFixtures;
  String? group;
  for (final fixture in sourceFixtures) {
    if (fixture.isGroupStage && fixture.involvesCountry(normalizedTeam)) {
      group = fixture.group;
      break;
    }
  }
  final targetGroup = group;
  if (targetGroup == null) {
    return const <WorldCupQualificationPathScenario>[];
  }

  final groupFixtures = sourceFixtures
      .where((fixture) => fixture.isGroupStage && fixture.group == targetGroup)
      .toList(growable: false);
  final currentStandings = worldCupGroupStandings(fixtures: sourceFixtures);
  WorldCupGroupStanding? currentStanding;
  for (final standing in currentStandings[targetGroup] ?? const []) {
    if (standing.team == normalizedTeam) {
      currentStanding = standing;
      break;
    }
  }
  final baseStanding = currentStanding;
  if (baseStanding == null) {
    return const <WorldCupQualificationPathScenario>[];
  }

  final remainingFixtures = groupFixtures
      .where((fixture) => !fixture.hasScore)
      .toList(growable: false);
  final teamRemainingFixtures = remainingFixtures
      .where((fixture) => fixture.involvesCountry(normalizedTeam))
      .toList()
    ..sort((a, b) => a.kickoffUtc.compareTo(b.kickoffUtc));

  final otherRemainingFixtures = remainingFixtures
      .where((fixture) => !fixture.involvesCountry(normalizedTeam))
      .toList(growable: false);
  final scenarios = <WorldCupQualificationPathScenario>[];

  void evaluateTeamPath(
    List<WorldCupFixture> teamPathFixtures,
    List<WorldCupQualificationMatchPick> picks,
  ) {
    final accumulator = _WorldCupQualificationPathAccumulator(
      group: targetGroup,
      team: normalizedTeam,
      currentPoints: baseStanding.points,
      remainingMatches: teamRemainingFixtures.length,
      remainingGroupMatches: remainingFixtures.length,
      remainingPoints: picks.fold<int>(0, (sum, pick) => sum + pick.points),
      picks: picks,
    );

    void recordCompletePath(
      List<WorldCupFixture> scenarioFixtures,
      List<WorldCupQualificationOtherMatchPick> otherPicks,
    ) {
      final standings =
          worldCupGroupStandings(fixtures: scenarioFixtures)[targetGroup];
      if (standings == null) return;
      final rankIndex = standings.indexWhere(
        (standing) => standing.team == normalizedTeam,
      );
      if (rankIndex < 0) return;
      accumulator.record(
        rankIndex + 1,
        List<WorldCupQualificationOtherMatchPick>.unmodifiable(otherPicks),
        worldCupRoundOf32OpponentPathsForGroupRank(
          targetGroup,
          rankIndex + 1,
          fixtures: sourceFixtures,
        ),
      );
    }

    void walkOtherFixtures(
      int fixtureIndex,
      List<WorldCupFixture> scenarioFixtures,
      List<WorldCupQualificationOtherMatchPick> otherPicks,
    ) {
      if (fixtureIndex >= otherRemainingFixtures.length) {
        recordCompletePath(scenarioFixtures, otherPicks);
        return;
      }

      final fixture = otherRemainingFixtures[fixtureIndex];
      for (final result in const <WorldCupFixtureTeamResult>[
        WorldCupFixtureTeamResult.win,
        WorldCupFixtureTeamResult.draw,
        WorldCupFixtureTeamResult.loss,
      ]) {
        final score = _scoreForFixtureTeamResult(
          fixture,
          fixture.homeTeam,
          result,
        );
        walkOtherFixtures(
          fixtureIndex + 1,
          _replaceFixtureScore(scenarioFixtures, fixture, score),
          [
            ...otherPicks,
            WorldCupQualificationOtherMatchPick(
              matchNumber: fixture.matchNumber,
              homeTeam: fixture.homeTeam,
              awayTeam: fixture.awayTeam,
              resultForHomeTeam: result,
            ),
          ],
        );
      }
    }

    walkOtherFixtures(
      0,
      teamPathFixtures,
      const <WorldCupQualificationOtherMatchPick>[],
    );
    scenarios.add(accumulator.toScenario());
  }

  void walkTeamFixtures(
    int fixtureIndex,
    List<WorldCupFixture> scenarioFixtures,
    List<WorldCupQualificationMatchPick> picks,
  ) {
    if (fixtureIndex >= teamRemainingFixtures.length) {
      evaluateTeamPath(scenarioFixtures, picks);
      return;
    }

    final fixture = teamRemainingFixtures[fixtureIndex];
    for (final result in const <WorldCupFixtureTeamResult>[
      WorldCupFixtureTeamResult.win,
      WorldCupFixtureTeamResult.draw,
      WorldCupFixtureTeamResult.loss,
    ]) {
      final score = _scoreForFixtureTeamResult(
        fixture,
        normalizedTeam,
        result,
      );
      walkTeamFixtures(
        fixtureIndex + 1,
        _replaceFixtureScore(scenarioFixtures, fixture, score),
        [
          ...picks,
          WorldCupQualificationMatchPick(
            matchNumber: fixture.matchNumber,
            opponentTeam: fixture.homeTeam == normalizedTeam
                ? fixture.awayTeam
                : fixture.homeTeam,
            result: result,
            points: _pointsForFixtureTeamResult(result),
          ),
        ],
      );
    }
  }

  walkTeamFixtures(
    0,
    sourceFixtures,
    const <WorldCupQualificationMatchPick>[],
  );

  return scenarios
    ..sort((a, b) {
      final points = b.remainingPoints.compareTo(a.remainingPoints);
      if (points != 0) return points;
      return b.advancingCases.compareTo(a.advancingCases);
    });
}

List<WorldCupQualificationOpponentPath>
    worldCupRoundOf32OpponentPathsForGroupRank(
  String group,
  int rank, {
  List<WorldCupFixture>? fixtures,
}) {
  final normalizedGroup = group.trim().toUpperCase();
  if (normalizedGroup.isEmpty || rank < 1 || rank > 3) {
    return const <WorldCupQualificationOpponentPath>[];
  }
  final sourceFixtures = fixtures ?? worldCupFixtures;
  final standingsByGroup = worldCupGroupStandings(fixtures: sourceFixtures);
  final seen = <String>{};
  final paths = <WorldCupQualificationOpponentPath>[];
  for (final fixture in sourceFixtures) {
    if (fixture.stage != WorldCupStage.roundOf32) continue;
    final homeMatches = _roundOf32SlotMatchesGroupRank(
      fixture.homeTeam,
      normalizedGroup,
      rank,
    );
    final awayMatches = _roundOf32SlotMatchesGroupRank(
      fixture.awayTeam,
      normalizedGroup,
      rank,
    );
    if (!homeMatches && !awayMatches) continue;
    final opponentSlot = homeMatches ? fixture.awayTeam : fixture.homeTeam;
    final key = '$rank:${fixture.matchNumber}:$opponentSlot';
    if (!seen.add(key)) continue;
    paths.add(
      WorldCupQualificationOpponentPath(
        rank: rank,
        matchNumber: fixture.matchNumber,
        opponentSlot: opponentSlot,
        opponentTeams: _roundOf32OpponentTeamsForSlot(
          opponentSlot,
          standingsByGroup,
        ),
      ),
    );
  }
  return paths..sort((a, b) => a.matchNumber.compareTo(b.matchNumber));
}

List<String> _roundOf32OpponentTeamsForSlot(
  String slot,
  Map<String, List<WorldCupGroupStanding>> standingsByGroup,
) {
  final match = RegExp(
    r'^([123])([A-L](?:/[A-L])*)$',
  ).firstMatch(slot.trim().toUpperCase());
  if (match == null) return const <String>[];
  final rank = int.parse(match.group(1)!);
  final groups = match.group(2)!.split('/');
  final seen = <String>{};
  final teams = <String>[];
  for (final group in groups) {
    final standings = standingsByGroup[group];
    if (standings == null || standings.length < rank) continue;
    final team = standings[rank - 1].team;
    if (seen.add(team)) teams.add(team);
  }
  return List<String>.unmodifiable(teams);
}

List<WorldCupFixture> _replaceFixtureScore(
  List<WorldCupFixture> fixtures,
  WorldCupFixture fixture,
  (int, int) score,
) {
  return [
    for (final item in fixtures)
      if (item.matchNumber == fixture.matchNumber)
        item.copyWithScore(homeScore: score.$1, awayScore: score.$2)
      else
        item,
  ];
}

(int, int) _scoreForFixtureTeamResult(
  WorldCupFixture fixture,
  String team,
  WorldCupFixtureTeamResult result,
) {
  final teamIsHome = fixture.homeTeam == team;
  return switch (result) {
    WorldCupFixtureTeamResult.win => teamIsHome ? (1, 0) : (0, 1),
    WorldCupFixtureTeamResult.draw => (0, 0),
    WorldCupFixtureTeamResult.loss => teamIsHome ? (0, 1) : (1, 0),
    WorldCupFixtureTeamResult.scheduled => (0, 0),
  };
}

int _pointsForFixtureTeamResult(WorldCupFixtureTeamResult result) {
  return switch (result) {
    WorldCupFixtureTeamResult.win => 3,
    WorldCupFixtureTeamResult.draw => 1,
    WorldCupFixtureTeamResult.loss => 0,
    WorldCupFixtureTeamResult.scheduled => 0,
  };
}

bool _roundOf32SlotMatchesGroupRank(String slot, String group, int rank) {
  if (rank == 1 || rank == 2) return slot == '$rank$group';
  final match = RegExp(r'^3([A-L](?:/[A-L])*)$').firstMatch(slot);
  if (match == null) return false;
  return match.group(1)!.split('/').contains(group);
}

int _compareWorldCupGroupStandings(
  WorldCupGroupStanding a,
  WorldCupGroupStanding b,
) {
  final points = b.points.compareTo(a.points);
  if (points != 0) return points;
  final goalDifference = b.goalDifference.compareTo(a.goalDifference);
  if (goalDifference != 0) return goalDifference;
  final goalsFor = b.goalsFor.compareTo(a.goalsFor);
  if (goalsFor != 0) return goalsFor;
  final wins = b.wins.compareTo(a.wins);
  if (wins != 0) return wins;
  final losses = a.losses.compareTo(b.losses);
  if (losses != 0) return losses;
  return a.team.compareTo(b.team);
}

class _WorldCupQualificationScenarioAccumulator {
  final String group;
  final String team;
  final int currentPoints;
  final int remainingMatches;
  final int remainingGroupMatches;
  final int remainingPoints;
  final int finalPoints;
  int totalCases = 0;
  int automaticAdvanceCases = 0;
  int thirdPlaceCases = 0;
  int eliminatedCases = 0;
  int bestRank = 4;
  int worstRank = 1;

  _WorldCupQualificationScenarioAccumulator({
    required this.group,
    required this.team,
    required this.currentPoints,
    required this.remainingMatches,
    required this.remainingGroupMatches,
    required this.remainingPoints,
    required this.finalPoints,
  });

  void record(int rank) {
    totalCases += 1;
    bestRank = _minInt(bestRank, rank);
    worstRank = _maxInt(worstRank, rank);
    if (rank <= 2) {
      automaticAdvanceCases += 1;
    } else if (rank == 3) {
      thirdPlaceCases += 1;
    } else {
      eliminatedCases += 1;
    }
  }

  WorldCupQualificationScenario toScenario() {
    return WorldCupQualificationScenario(
      group: group,
      team: team,
      currentPoints: currentPoints,
      remainingMatches: remainingMatches,
      remainingGroupMatches: remainingGroupMatches,
      remainingPoints: remainingPoints,
      finalPoints: finalPoints,
      totalCases: totalCases,
      automaticAdvanceCases: automaticAdvanceCases,
      thirdPlaceCases: thirdPlaceCases,
      eliminatedCases: eliminatedCases,
      bestRank: bestRank,
      worstRank: worstRank,
    );
  }
}

class _WorldCupQualificationPathAccumulator {
  final String group;
  final String team;
  final int currentPoints;
  final int remainingMatches;
  final int remainingGroupMatches;
  final int remainingPoints;
  final List<WorldCupQualificationMatchPick> picks;
  int totalCases = 0;
  int automaticAdvanceCases = 0;
  int thirdPlaceCases = 0;
  int eliminatedCases = 0;
  int bestRank = 4;
  int worstRank = 1;
  final List<WorldCupQualificationOtherMatchPath> otherMatchPaths =
      <WorldCupQualificationOtherMatchPath>[];
  final Map<String, WorldCupQualificationOpponentPath> opponentPaths =
      <String, WorldCupQualificationOpponentPath>{};

  _WorldCupQualificationPathAccumulator({
    required this.group,
    required this.team,
    required this.currentPoints,
    required this.remainingMatches,
    required this.remainingGroupMatches,
    required this.remainingPoints,
    required this.picks,
  });

  void record(
    int rank,
    List<WorldCupQualificationOtherMatchPick> otherPicks,
    List<WorldCupQualificationOpponentPath> paths,
  ) {
    totalCases += 1;
    bestRank = _minInt(bestRank, rank);
    worstRank = _maxInt(worstRank, rank);
    if (rank <= 2) {
      automaticAdvanceCases += 1;
    } else if (rank == 3) {
      thirdPlaceCases += 1;
    } else {
      eliminatedCases += 1;
    }

    otherMatchPaths.add(
      WorldCupQualificationOtherMatchPath(
        picks: otherPicks,
        finalPoints: currentPoints + remainingPoints,
        rank: rank,
      ),
    );

    if (rank <= 3) {
      for (final path in paths) {
        opponentPaths['${path.rank}:${path.matchNumber}:${path.opponentSlot}'] =
            path;
      }
    }
  }

  WorldCupQualificationPathScenario toScenario() {
    final sortedOpponentPaths = opponentPaths.values.toList()
      ..sort((a, b) {
        final rank = a.rank.compareTo(b.rank);
        if (rank != 0) return rank;
        return a.matchNumber.compareTo(b.matchNumber);
      });
    final sortedOtherMatchPaths = otherMatchPaths.toList()
      ..sort((a, b) {
        final rank = a.rank.compareTo(b.rank);
        if (rank != 0) return rank;
        for (var index = 0;
            index < a.picks.length && index < b.picks.length;
            index += 1) {
          final matchNumber =
              a.picks[index].matchNumber.compareTo(b.picks[index].matchNumber);
          if (matchNumber != 0) return matchNumber;
          final result = a.picks[index].resultForHomeTeam.index.compareTo(
            b.picks[index].resultForHomeTeam.index,
          );
          if (result != 0) return result;
        }
        return a.picks.length.compareTo(b.picks.length);
      });
    return WorldCupQualificationPathScenario(
      group: group,
      team: team,
      currentPoints: currentPoints,
      remainingMatches: remainingMatches,
      remainingGroupMatches: remainingGroupMatches,
      remainingPoints: remainingPoints,
      finalPoints: currentPoints + remainingPoints,
      picks: List<WorldCupQualificationMatchPick>.unmodifiable(picks),
      totalCases: totalCases,
      automaticAdvanceCases: automaticAdvanceCases,
      thirdPlaceCases: thirdPlaceCases,
      eliminatedCases: eliminatedCases,
      bestRank: bestRank,
      worstRank: worstRank,
      otherMatchPaths: List<WorldCupQualificationOtherMatchPath>.unmodifiable(
        sortedOtherMatchPaths,
      ),
      opponentPaths: List<WorldCupQualificationOpponentPath>.unmodifiable(
        sortedOpponentPaths,
      ),
    );
  }
}

int _minInt(int a, int b) => a < b ? a : b;

int _maxInt(int a, int b) => a > b ? a : b;

class _WorldCupGroupStandingAccumulator {
  final String group;
  final String team;
  int played = 0;
  int wins = 0;
  int draws = 0;
  int losses = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;

  _WorldCupGroupStandingAccumulator(this.group, this.team);

  void record(int teamScore, int opponentScore) {
    played += 1;
    goalsFor += teamScore;
    goalsAgainst += opponentScore;
    if (teamScore > opponentScore) {
      wins += 1;
    } else if (teamScore < opponentScore) {
      losses += 1;
    } else {
      draws += 1;
    }
  }

  WorldCupGroupStanding toStanding() {
    return WorldCupGroupStanding(
      group: group,
      team: team,
      played: played,
      wins: wins,
      draws: draws,
      losses: losses,
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
    );
  }
}

const List<WorldCupFixture> worldCupFixtures = <WorldCupFixture>[
  WorldCupFixture(
    matchNumber: 1,
    kickoffUtcIso: '2026-06-11T19:00:00Z',
    stage: WorldCupStage.group,
    group: 'A',
    homeTeam: 'Mexico',
    awayTeam: 'South Africa',
    venue: 'Estadio Azteca, Mexico City',
    homeScore: 2,
    awayScore: 0,
  ),
  WorldCupFixture(
    matchNumber: 2,
    kickoffUtcIso: '2026-06-12T02:00:00Z',
    stage: WorldCupStage.group,
    group: 'A',
    homeTeam: 'Korea Republic',
    awayTeam: 'Czechia',
    venue: 'Estadio Akron, Guadalajara',
    homeScore: 2,
    awayScore: 1,
  ),
  WorldCupFixture(
    matchNumber: 3,
    kickoffUtcIso: '2026-06-12T19:00:00Z',
    stage: WorldCupStage.group,
    group: 'B',
    homeTeam: 'Canada',
    awayTeam: 'Bosnia and Herzegovina',
    venue: 'BMO Field, Toronto',
    homeScore: 1,
    awayScore: 1,
  ),
  WorldCupFixture(
    matchNumber: 4,
    kickoffUtcIso: '2026-06-13T01:00:00Z',
    stage: WorldCupStage.group,
    group: 'D',
    homeTeam: 'USA',
    awayTeam: 'Paraguay',
    venue: 'SoFi Stadium, Los Angeles',
    homeScore: 4,
    awayScore: 1,
  ),
  WorldCupFixture(
    matchNumber: 5,
    kickoffUtcIso: '2026-06-13T19:00:00Z',
    stage: WorldCupStage.group,
    group: 'B',
    homeTeam: 'Qatar',
    awayTeam: 'Switzerland',
    venue: 'Levi\'s Stadium, San Francisco Bay Area',
    homeScore: 1,
    awayScore: 1,
  ),
  WorldCupFixture(
    matchNumber: 6,
    kickoffUtcIso: '2026-06-13T22:00:00Z',
    stage: WorldCupStage.group,
    group: 'C',
    homeTeam: 'Brazil',
    awayTeam: 'Morocco',
    venue: 'MetLife Stadium, New York/New Jersey',
    homeScore: 1,
    awayScore: 1,
  ),
  WorldCupFixture(
    matchNumber: 7,
    kickoffUtcIso: '2026-06-14T01:00:00Z',
    stage: WorldCupStage.group,
    group: 'C',
    homeTeam: 'Haiti',
    awayTeam: 'Scotland',
    venue: 'Gillette Stadium, Boston',
    homeScore: 0,
    awayScore: 1,
  ),
  WorldCupFixture(
    matchNumber: 8,
    kickoffUtcIso: '2026-06-14T04:00:00Z',
    stage: WorldCupStage.group,
    group: 'D',
    homeTeam: 'Australia',
    awayTeam: 'Turkiye',
    venue: 'BC Place, Vancouver',
    homeScore: 2,
    awayScore: 0,
  ),
  WorldCupFixture(
    matchNumber: 9,
    kickoffUtcIso: '2026-06-14T17:00:00Z',
    stage: WorldCupStage.group,
    group: 'E',
    homeTeam: 'Germany',
    awayTeam: 'Curacao',
    venue: 'NRG Stadium, Houston',
    homeScore: 7,
    awayScore: 1,
  ),
  WorldCupFixture(
    matchNumber: 10,
    kickoffUtcIso: '2026-06-14T20:00:00Z',
    stage: WorldCupStage.group,
    group: 'F',
    homeTeam: 'Netherlands',
    awayTeam: 'Japan',
    venue: 'AT&T Stadium, Dallas',
    homeScore: 2,
    awayScore: 2,
  ),
  WorldCupFixture(
    matchNumber: 11,
    kickoffUtcIso: '2026-06-14T23:00:00Z',
    stage: WorldCupStage.group,
    group: 'E',
    homeTeam: 'Ivory Coast',
    awayTeam: 'Ecuador',
    venue: 'Lincoln Financial Field, Philadelphia',
    homeScore: 1,
    awayScore: 0,
  ),
  WorldCupFixture(
    matchNumber: 12,
    kickoffUtcIso: '2026-06-15T02:00:00Z',
    stage: WorldCupStage.group,
    group: 'F',
    homeTeam: 'Sweden',
    awayTeam: 'Tunisia',
    venue: 'Estadio BBVA, Monterrey',
    homeScore: 5,
    awayScore: 1,
  ),
  WorldCupFixture(
    matchNumber: 13,
    kickoffUtcIso: '2026-06-15T16:00:00Z',
    stage: WorldCupStage.group,
    group: 'H',
    homeTeam: 'Spain',
    awayTeam: 'Cape Verde',
    venue: 'Mercedes-Benz Stadium, Atlanta',
    homeScore: 0,
    awayScore: 0,
  ),
  WorldCupFixture(
    matchNumber: 14,
    kickoffUtcIso: '2026-06-15T19:00:00Z',
    stage: WorldCupStage.group,
    group: 'G',
    homeTeam: 'Belgium',
    awayTeam: 'Egypt',
    venue: 'Lumen Field, Seattle',
    homeScore: 1,
    awayScore: 1,
  ),
  WorldCupFixture(
    matchNumber: 15,
    kickoffUtcIso: '2026-06-15T22:00:00Z',
    stage: WorldCupStage.group,
    group: 'H',
    homeTeam: 'Saudi Arabia',
    awayTeam: 'Uruguay',
    venue: 'Hard Rock Stadium, Miami',
    homeScore: 1,
    awayScore: 1,
  ),
  WorldCupFixture(
    matchNumber: 16,
    kickoffUtcIso: '2026-06-16T01:00:00Z',
    stage: WorldCupStage.group,
    group: 'G',
    homeTeam: 'Iran',
    awayTeam: 'New Zealand',
    venue: 'SoFi Stadium, Los Angeles',
    homeScore: 2,
    awayScore: 2,
  ),
  WorldCupFixture(
    matchNumber: 17,
    kickoffUtcIso: '2026-06-16T19:00:00Z',
    stage: WorldCupStage.group,
    group: 'I',
    homeTeam: 'France',
    awayTeam: 'Senegal',
    venue: 'MetLife Stadium, New York/New Jersey',
    homeScore: 3,
    awayScore: 1,
  ),
  WorldCupFixture(
    matchNumber: 18,
    kickoffUtcIso: '2026-06-16T22:00:00Z',
    stage: WorldCupStage.group,
    group: 'I',
    homeTeam: 'Iraq',
    awayTeam: 'Norway',
    venue: 'Gillette Stadium, Boston',
    homeScore: 1,
    awayScore: 4,
  ),
  WorldCupFixture(
    matchNumber: 19,
    kickoffUtcIso: '2026-06-17T01:00:00Z',
    stage: WorldCupStage.group,
    group: 'J',
    homeTeam: 'Argentina',
    awayTeam: 'Algeria',
    venue: 'GEHA Field at Arrowhead Stadium, Kansas City',
    homeScore: 3,
    awayScore: 0,
  ),
  WorldCupFixture(
    matchNumber: 20,
    kickoffUtcIso: '2026-06-17T04:00:00Z',
    stage: WorldCupStage.group,
    group: 'J',
    homeTeam: 'Austria',
    awayTeam: 'Jordan',
    venue: 'Levi\'s Stadium, San Francisco Bay Area',
    homeScore: 3,
    awayScore: 1,
  ),
  WorldCupFixture(
    matchNumber: 21,
    kickoffUtcIso: '2026-06-17T17:00:00Z',
    stage: WorldCupStage.group,
    group: 'K',
    homeTeam: 'Portugal',
    awayTeam: 'Congo DR',
    venue: 'NRG Stadium, Houston',
    homeScore: 1,
    awayScore: 1,
  ),
  WorldCupFixture(
    matchNumber: 22,
    kickoffUtcIso: '2026-06-17T20:00:00Z',
    stage: WorldCupStage.group,
    group: 'L',
    homeTeam: 'England',
    awayTeam: 'Croatia',
    venue: 'AT&T Stadium, Dallas',
    homeScore: 2,
    awayScore: 2,
  ),
  WorldCupFixture(
    matchNumber: 23,
    kickoffUtcIso: '2026-06-17T23:00:00Z',
    stage: WorldCupStage.group,
    group: 'L',
    homeTeam: 'Ghana',
    awayTeam: 'Panama',
    venue: 'BMO Field, Toronto',
  ),
  WorldCupFixture(
    matchNumber: 24,
    kickoffUtcIso: '2026-06-18T02:00:00Z',
    stage: WorldCupStage.group,
    group: 'K',
    homeTeam: 'Uzbekistan',
    awayTeam: 'Colombia',
    venue: 'Estadio Azteca, Mexico City',
  ),
  WorldCupFixture(
    matchNumber: 25,
    kickoffUtcIso: '2026-06-18T16:00:00Z',
    stage: WorldCupStage.group,
    group: 'A',
    homeTeam: 'Czechia',
    awayTeam: 'South Africa',
    venue: 'Mercedes-Benz Stadium, Atlanta',
  ),
  WorldCupFixture(
    matchNumber: 26,
    kickoffUtcIso: '2026-06-18T19:00:00Z',
    stage: WorldCupStage.group,
    group: 'B',
    homeTeam: 'Switzerland',
    awayTeam: 'Bosnia and Herzegovina',
    venue: 'SoFi Stadium, Los Angeles',
  ),
  WorldCupFixture(
    matchNumber: 27,
    kickoffUtcIso: '2026-06-18T22:00:00Z',
    stage: WorldCupStage.group,
    group: 'B',
    homeTeam: 'Canada',
    awayTeam: 'Qatar',
    venue: 'BC Place, Vancouver',
  ),
  WorldCupFixture(
    matchNumber: 28,
    kickoffUtcIso: '2026-06-19T01:00:00Z',
    stage: WorldCupStage.group,
    group: 'A',
    homeTeam: 'Mexico',
    awayTeam: 'Korea Republic',
    venue: 'Estadio Akron, Guadalajara',
  ),
  WorldCupFixture(
    matchNumber: 29,
    kickoffUtcIso: '2026-06-19T19:00:00Z',
    stage: WorldCupStage.group,
    group: 'D',
    homeTeam: 'USA',
    awayTeam: 'Australia',
    venue: 'Lumen Field, Seattle',
  ),
  WorldCupFixture(
    matchNumber: 30,
    kickoffUtcIso: '2026-06-19T22:00:00Z',
    stage: WorldCupStage.group,
    group: 'C',
    homeTeam: 'Scotland',
    awayTeam: 'Morocco',
    venue: 'Gillette Stadium, Boston',
  ),
  WorldCupFixture(
    matchNumber: 31,
    kickoffUtcIso: '2026-06-20T00:30:00Z',
    stage: WorldCupStage.group,
    group: 'C',
    homeTeam: 'Brazil',
    awayTeam: 'Haiti',
    venue: 'Lincoln Financial Field, Philadelphia',
  ),
  WorldCupFixture(
    matchNumber: 32,
    kickoffUtcIso: '2026-06-20T03:00:00Z',
    stage: WorldCupStage.group,
    group: 'D',
    homeTeam: 'Turkiye',
    awayTeam: 'Paraguay',
    venue: 'Levi\'s Stadium, San Francisco Bay Area',
  ),
  WorldCupFixture(
    matchNumber: 33,
    kickoffUtcIso: '2026-06-20T17:00:00Z',
    stage: WorldCupStage.group,
    group: 'F',
    homeTeam: 'Netherlands',
    awayTeam: 'Sweden',
    venue: 'NRG Stadium, Houston',
  ),
  WorldCupFixture(
    matchNumber: 34,
    kickoffUtcIso: '2026-06-20T20:00:00Z',
    stage: WorldCupStage.group,
    group: 'E',
    homeTeam: 'Germany',
    awayTeam: 'Ivory Coast',
    venue: 'BMO Field, Toronto',
  ),
  WorldCupFixture(
    matchNumber: 35,
    kickoffUtcIso: '2026-06-21T00:00:00Z',
    stage: WorldCupStage.group,
    group: 'E',
    homeTeam: 'Ecuador',
    awayTeam: 'Curacao',
    venue: 'GEHA Field at Arrowhead Stadium, Kansas City',
  ),
  WorldCupFixture(
    matchNumber: 36,
    kickoffUtcIso: '2026-06-21T04:00:00Z',
    stage: WorldCupStage.group,
    group: 'F',
    homeTeam: 'Tunisia',
    awayTeam: 'Japan',
    venue: 'Estadio BBVA, Monterrey',
  ),
  WorldCupFixture(
    matchNumber: 37,
    kickoffUtcIso: '2026-06-21T16:00:00Z',
    stage: WorldCupStage.group,
    group: 'H',
    homeTeam: 'Spain',
    awayTeam: 'Saudi Arabia',
    venue: 'Mercedes-Benz Stadium, Atlanta',
  ),
  WorldCupFixture(
    matchNumber: 38,
    kickoffUtcIso: '2026-06-21T19:00:00Z',
    stage: WorldCupStage.group,
    group: 'G',
    homeTeam: 'Belgium',
    awayTeam: 'Iran',
    venue: 'SoFi Stadium, Los Angeles',
  ),
  WorldCupFixture(
    matchNumber: 39,
    kickoffUtcIso: '2026-06-21T22:00:00Z',
    stage: WorldCupStage.group,
    group: 'H',
    homeTeam: 'Uruguay',
    awayTeam: 'Cape Verde',
    venue: 'Hard Rock Stadium, Miami',
  ),
  WorldCupFixture(
    matchNumber: 40,
    kickoffUtcIso: '2026-06-22T01:00:00Z',
    stage: WorldCupStage.group,
    group: 'G',
    homeTeam: 'New Zealand',
    awayTeam: 'Egypt',
    venue: 'BC Place, Vancouver',
  ),
  WorldCupFixture(
    matchNumber: 41,
    kickoffUtcIso: '2026-06-22T17:00:00Z',
    stage: WorldCupStage.group,
    group: 'J',
    homeTeam: 'Argentina',
    awayTeam: 'Austria',
    venue: 'AT&T Stadium, Dallas',
  ),
  WorldCupFixture(
    matchNumber: 42,
    kickoffUtcIso: '2026-06-22T21:00:00Z',
    stage: WorldCupStage.group,
    group: 'I',
    homeTeam: 'France',
    awayTeam: 'Iraq',
    venue: 'Lincoln Financial Field, Philadelphia',
  ),
  WorldCupFixture(
    matchNumber: 43,
    kickoffUtcIso: '2026-06-23T00:00:00Z',
    stage: WorldCupStage.group,
    group: 'I',
    homeTeam: 'Norway',
    awayTeam: 'Senegal',
    venue: 'MetLife Stadium, New York/New Jersey',
  ),
  WorldCupFixture(
    matchNumber: 44,
    kickoffUtcIso: '2026-06-23T03:00:00Z',
    stage: WorldCupStage.group,
    group: 'J',
    homeTeam: 'Jordan',
    awayTeam: 'Algeria',
    venue: 'Levi\'s Stadium, San Francisco Bay Area',
  ),
  WorldCupFixture(
    matchNumber: 45,
    kickoffUtcIso: '2026-06-23T17:00:00Z',
    stage: WorldCupStage.group,
    group: 'K',
    homeTeam: 'Portugal',
    awayTeam: 'Uzbekistan',
    venue: 'NRG Stadium, Houston',
  ),
  WorldCupFixture(
    matchNumber: 46,
    kickoffUtcIso: '2026-06-23T20:00:00Z',
    stage: WorldCupStage.group,
    group: 'L',
    homeTeam: 'England',
    awayTeam: 'Ghana',
    venue: 'Gillette Stadium, Boston',
  ),
  WorldCupFixture(
    matchNumber: 47,
    kickoffUtcIso: '2026-06-23T23:00:00Z',
    stage: WorldCupStage.group,
    group: 'L',
    homeTeam: 'Panama',
    awayTeam: 'Croatia',
    venue: 'BMO Field, Toronto',
  ),
  WorldCupFixture(
    matchNumber: 48,
    kickoffUtcIso: '2026-06-24T02:00:00Z',
    stage: WorldCupStage.group,
    group: 'K',
    homeTeam: 'Colombia',
    awayTeam: 'Congo DR',
    venue: 'Estadio Akron, Guadalajara',
  ),
  WorldCupFixture(
    matchNumber: 49,
    kickoffUtcIso: '2026-06-24T19:00:00Z',
    stage: WorldCupStage.group,
    group: 'B',
    homeTeam: 'Switzerland',
    awayTeam: 'Canada',
    venue: 'BC Place, Vancouver',
  ),
  WorldCupFixture(
    matchNumber: 50,
    kickoffUtcIso: '2026-06-24T19:00:00Z',
    stage: WorldCupStage.group,
    group: 'B',
    homeTeam: 'Bosnia and Herzegovina',
    awayTeam: 'Qatar',
    venue: 'Lumen Field, Seattle',
  ),
  WorldCupFixture(
    matchNumber: 51,
    kickoffUtcIso: '2026-06-24T22:00:00Z',
    stage: WorldCupStage.group,
    group: 'C',
    homeTeam: 'Scotland',
    awayTeam: 'Brazil',
    venue: 'Hard Rock Stadium, Miami',
  ),
  WorldCupFixture(
    matchNumber: 52,
    kickoffUtcIso: '2026-06-24T22:00:00Z',
    stage: WorldCupStage.group,
    group: 'C',
    homeTeam: 'Morocco',
    awayTeam: 'Haiti',
    venue: 'Mercedes-Benz Stadium, Atlanta',
  ),
  WorldCupFixture(
    matchNumber: 53,
    kickoffUtcIso: '2026-06-25T01:00:00Z',
    stage: WorldCupStage.group,
    group: 'A',
    homeTeam: 'Czechia',
    awayTeam: 'Mexico',
    venue: 'Estadio Azteca, Mexico City',
  ),
  WorldCupFixture(
    matchNumber: 54,
    kickoffUtcIso: '2026-06-25T01:00:00Z',
    stage: WorldCupStage.group,
    group: 'A',
    homeTeam: 'South Africa',
    awayTeam: 'Korea Republic',
    venue: 'Estadio BBVA, Monterrey',
  ),
  WorldCupFixture(
    matchNumber: 55,
    kickoffUtcIso: '2026-06-25T20:00:00Z',
    stage: WorldCupStage.group,
    group: 'E',
    homeTeam: 'Curacao',
    awayTeam: 'Ivory Coast',
    venue: 'Lincoln Financial Field, Philadelphia',
  ),
  WorldCupFixture(
    matchNumber: 56,
    kickoffUtcIso: '2026-06-25T20:00:00Z',
    stage: WorldCupStage.group,
    group: 'E',
    homeTeam: 'Ecuador',
    awayTeam: 'Germany',
    venue: 'MetLife Stadium, New York/New Jersey',
  ),
  WorldCupFixture(
    matchNumber: 57,
    kickoffUtcIso: '2026-06-25T23:00:00Z',
    stage: WorldCupStage.group,
    group: 'F',
    homeTeam: 'Japan',
    awayTeam: 'Sweden',
    venue: 'AT&T Stadium, Dallas',
  ),
  WorldCupFixture(
    matchNumber: 58,
    kickoffUtcIso: '2026-06-25T23:00:00Z',
    stage: WorldCupStage.group,
    group: 'F',
    homeTeam: 'Tunisia',
    awayTeam: 'Netherlands',
    venue: 'GEHA Field at Arrowhead Stadium, Kansas City',
  ),
  WorldCupFixture(
    matchNumber: 59,
    kickoffUtcIso: '2026-06-26T02:00:00Z',
    stage: WorldCupStage.group,
    group: 'D',
    homeTeam: 'Turkiye',
    awayTeam: 'USA',
    venue: 'SoFi Stadium, Los Angeles',
  ),
  WorldCupFixture(
    matchNumber: 60,
    kickoffUtcIso: '2026-06-26T02:00:00Z',
    stage: WorldCupStage.group,
    group: 'D',
    homeTeam: 'Paraguay',
    awayTeam: 'Australia',
    venue: 'Levi\'s Stadium, San Francisco Bay Area',
  ),
  WorldCupFixture(
    matchNumber: 61,
    kickoffUtcIso: '2026-06-26T19:00:00Z',
    stage: WorldCupStage.group,
    group: 'I',
    homeTeam: 'Norway',
    awayTeam: 'France',
    venue: 'Gillette Stadium, Boston',
  ),
  WorldCupFixture(
    matchNumber: 62,
    kickoffUtcIso: '2026-06-26T19:00:00Z',
    stage: WorldCupStage.group,
    group: 'I',
    homeTeam: 'Senegal',
    awayTeam: 'Iraq',
    venue: 'BMO Field, Toronto',
  ),
  WorldCupFixture(
    matchNumber: 63,
    kickoffUtcIso: '2026-06-27T00:00:00Z',
    stage: WorldCupStage.group,
    group: 'H',
    homeTeam: 'Cape Verde',
    awayTeam: 'Saudi Arabia',
    venue: 'NRG Stadium, Houston',
  ),
  WorldCupFixture(
    matchNumber: 64,
    kickoffUtcIso: '2026-06-27T00:00:00Z',
    stage: WorldCupStage.group,
    group: 'H',
    homeTeam: 'Uruguay',
    awayTeam: 'Spain',
    venue: 'Estadio Akron, Guadalajara',
  ),
  WorldCupFixture(
    matchNumber: 65,
    kickoffUtcIso: '2026-06-27T03:00:00Z',
    stage: WorldCupStage.group,
    group: 'G',
    homeTeam: 'Egypt',
    awayTeam: 'Iran',
    venue: 'Lumen Field, Seattle',
  ),
  WorldCupFixture(
    matchNumber: 66,
    kickoffUtcIso: '2026-06-27T03:00:00Z',
    stage: WorldCupStage.group,
    group: 'G',
    homeTeam: 'New Zealand',
    awayTeam: 'Belgium',
    venue: 'BC Place, Vancouver',
  ),
  WorldCupFixture(
    matchNumber: 67,
    kickoffUtcIso: '2026-06-27T21:00:00Z',
    stage: WorldCupStage.group,
    group: 'L',
    homeTeam: 'Panama',
    awayTeam: 'England',
    venue: 'MetLife Stadium, New York/New Jersey',
  ),
  WorldCupFixture(
    matchNumber: 68,
    kickoffUtcIso: '2026-06-27T21:00:00Z',
    stage: WorldCupStage.group,
    group: 'L',
    homeTeam: 'Croatia',
    awayTeam: 'Ghana',
    venue: 'Lincoln Financial Field, Philadelphia',
  ),
  WorldCupFixture(
    matchNumber: 69,
    kickoffUtcIso: '2026-06-27T23:30:00Z',
    stage: WorldCupStage.group,
    group: 'K',
    homeTeam: 'Colombia',
    awayTeam: 'Portugal',
    venue: 'Hard Rock Stadium, Miami',
  ),
  WorldCupFixture(
    matchNumber: 70,
    kickoffUtcIso: '2026-06-27T23:30:00Z',
    stage: WorldCupStage.group,
    group: 'K',
    homeTeam: 'Congo DR',
    awayTeam: 'Uzbekistan',
    venue: 'Mercedes-Benz Stadium, Atlanta',
  ),
  WorldCupFixture(
    matchNumber: 71,
    kickoffUtcIso: '2026-06-28T02:00:00Z',
    stage: WorldCupStage.group,
    group: 'J',
    homeTeam: 'Algeria',
    awayTeam: 'Austria',
    venue: 'GEHA Field at Arrowhead Stadium, Kansas City',
  ),
  WorldCupFixture(
    matchNumber: 72,
    kickoffUtcIso: '2026-06-28T02:00:00Z',
    stage: WorldCupStage.group,
    group: 'J',
    homeTeam: 'Jordan',
    awayTeam: 'Argentina',
    venue: 'AT&T Stadium, Dallas',
  ),
  WorldCupFixture(
    matchNumber: 73,
    kickoffUtcIso: '2026-06-28T19:00:00Z',
    stage: WorldCupStage.roundOf32,
    homeTeam: '2A',
    awayTeam: '2B',
    venue: 'SoFi Stadium, Los Angeles',
  ),
  WorldCupFixture(
    matchNumber: 74,
    kickoffUtcIso: '2026-06-29T17:00:00Z',
    stage: WorldCupStage.roundOf32,
    homeTeam: '1C',
    awayTeam: '2F',
    venue: 'NRG Stadium, Houston',
  ),
  WorldCupFixture(
    matchNumber: 75,
    kickoffUtcIso: '2026-06-29T20:30:00Z',
    stage: WorldCupStage.roundOf32,
    homeTeam: '1E',
    awayTeam: '3A/B/C/D/F',
    venue: 'Gillette Stadium, Boston',
  ),
  WorldCupFixture(
    matchNumber: 76,
    kickoffUtcIso: '2026-06-30T01:00:00Z',
    stage: WorldCupStage.roundOf32,
    homeTeam: '1F',
    awayTeam: '2C',
    venue: 'Estadio BBVA, Monterrey',
  ),
  WorldCupFixture(
    matchNumber: 77,
    kickoffUtcIso: '2026-06-30T17:00:00Z',
    stage: WorldCupStage.roundOf32,
    homeTeam: '2E',
    awayTeam: '2I',
    venue: 'AT&T Stadium, Dallas',
  ),
  WorldCupFixture(
    matchNumber: 78,
    kickoffUtcIso: '2026-06-30T21:00:00Z',
    stage: WorldCupStage.roundOf32,
    homeTeam: '1I',
    awayTeam: '3C/D/F/G/H',
    venue: 'MetLife Stadium, New York/New Jersey',
  ),
  WorldCupFixture(
    matchNumber: 79,
    kickoffUtcIso: '2026-07-01T01:00:00Z',
    stage: WorldCupStage.roundOf32,
    homeTeam: '1A',
    awayTeam: '3C/E/F/H/I',
    venue: 'Estadio Azteca, Mexico City',
  ),
  WorldCupFixture(
    matchNumber: 80,
    kickoffUtcIso: '2026-07-01T16:00:00Z',
    stage: WorldCupStage.roundOf32,
    homeTeam: '1L',
    awayTeam: '3E/H/I/J/K',
    venue: 'Mercedes-Benz Stadium, Atlanta',
  ),
  WorldCupFixture(
    matchNumber: 81,
    kickoffUtcIso: '2026-07-01T20:00:00Z',
    stage: WorldCupStage.roundOf32,
    homeTeam: '1G',
    awayTeam: '3A/E/H/I/J',
    venue: 'Lumen Field, Seattle',
  ),
  WorldCupFixture(
    matchNumber: 82,
    kickoffUtcIso: '2026-07-02T00:00:00Z',
    stage: WorldCupStage.roundOf32,
    homeTeam: '1D',
    awayTeam: '3B/E/F/I/J',
    venue: 'Levi\'s Stadium, San Francisco Bay Area',
  ),
  WorldCupFixture(
    matchNumber: 83,
    kickoffUtcIso: '2026-07-02T19:00:00Z',
    stage: WorldCupStage.roundOf32,
    homeTeam: '1H',
    awayTeam: '2J',
    venue: 'SoFi Stadium, Los Angeles',
  ),
  WorldCupFixture(
    matchNumber: 84,
    kickoffUtcIso: '2026-07-02T23:00:00Z',
    stage: WorldCupStage.roundOf32,
    homeTeam: '2K',
    awayTeam: '2L',
    venue: 'BMO Field, Toronto',
  ),
  WorldCupFixture(
    matchNumber: 85,
    kickoffUtcIso: '2026-07-03T03:00:00Z',
    stage: WorldCupStage.roundOf32,
    homeTeam: '1B',
    awayTeam: '3E/F/G/I/J',
    venue: 'BC Place, Vancouver',
  ),
  WorldCupFixture(
    matchNumber: 86,
    kickoffUtcIso: '2026-07-03T18:00:00Z',
    stage: WorldCupStage.roundOf32,
    homeTeam: '2D',
    awayTeam: '2G',
    venue: 'AT&T Stadium, Dallas',
  ),
  WorldCupFixture(
    matchNumber: 87,
    kickoffUtcIso: '2026-07-03T22:00:00Z',
    stage: WorldCupStage.roundOf32,
    homeTeam: '1J',
    awayTeam: '2H',
    venue: 'Hard Rock Stadium, Miami',
  ),
  WorldCupFixture(
    matchNumber: 88,
    kickoffUtcIso: '2026-07-04T01:30:00Z',
    stage: WorldCupStage.roundOf32,
    homeTeam: '1K',
    awayTeam: '3D/E/I/J/L',
    venue: 'GEHA Field at Arrowhead Stadium, Kansas City',
  ),
  WorldCupFixture(
    matchNumber: 89,
    kickoffUtcIso: '2026-07-04T17:00:00Z',
    stage: WorldCupStage.roundOf16,
    homeTeam: 'W73',
    awayTeam: 'W75',
    venue: 'NRG Stadium, Houston',
  ),
  WorldCupFixture(
    matchNumber: 90,
    kickoffUtcIso: '2026-07-04T21:00:00Z',
    stage: WorldCupStage.roundOf16,
    homeTeam: 'W74',
    awayTeam: 'W77',
    venue: 'Lincoln Financial Field, Philadelphia',
  ),
  WorldCupFixture(
    matchNumber: 91,
    kickoffUtcIso: '2026-07-05T20:00:00Z',
    stage: WorldCupStage.roundOf16,
    homeTeam: 'W76',
    awayTeam: 'W78',
    venue: 'MetLife Stadium, New York/New Jersey',
  ),
  WorldCupFixture(
    matchNumber: 92,
    kickoffUtcIso: '2026-07-06T00:00:00Z',
    stage: WorldCupStage.roundOf16,
    homeTeam: 'W79',
    awayTeam: 'W80',
    venue: 'Estadio Azteca, Mexico City',
  ),
  WorldCupFixture(
    matchNumber: 93,
    kickoffUtcIso: '2026-07-06T19:00:00Z',
    stage: WorldCupStage.roundOf16,
    homeTeam: 'W83',
    awayTeam: 'W84',
    venue: 'AT&T Stadium, Dallas',
  ),
  WorldCupFixture(
    matchNumber: 94,
    kickoffUtcIso: '2026-07-07T00:00:00Z',
    stage: WorldCupStage.roundOf16,
    homeTeam: 'W81',
    awayTeam: 'W82',
    venue: 'Lumen Field, Seattle',
  ),
  WorldCupFixture(
    matchNumber: 95,
    kickoffUtcIso: '2026-07-07T16:00:00Z',
    stage: WorldCupStage.roundOf16,
    homeTeam: 'W86',
    awayTeam: 'W88',
    venue: 'Mercedes-Benz Stadium, Atlanta',
  ),
  WorldCupFixture(
    matchNumber: 96,
    kickoffUtcIso: '2026-07-07T20:00:00Z',
    stage: WorldCupStage.roundOf16,
    homeTeam: 'W85',
    awayTeam: 'W87',
    venue: 'BC Place, Vancouver',
  ),
  WorldCupFixture(
    matchNumber: 97,
    kickoffUtcIso: '2026-07-09T20:00:00Z',
    stage: WorldCupStage.quarterFinal,
    homeTeam: 'W89',
    awayTeam: 'W90',
    venue: 'Gillette Stadium, Boston',
  ),
  WorldCupFixture(
    matchNumber: 98,
    kickoffUtcIso: '2026-07-10T19:00:00Z',
    stage: WorldCupStage.quarterFinal,
    homeTeam: 'W93',
    awayTeam: 'W94',
    venue: 'SoFi Stadium, Los Angeles',
  ),
  WorldCupFixture(
    matchNumber: 99,
    kickoffUtcIso: '2026-07-11T21:00:00Z',
    stage: WorldCupStage.quarterFinal,
    homeTeam: 'W91',
    awayTeam: 'W92',
    venue: 'Hard Rock Stadium, Miami',
  ),
  WorldCupFixture(
    matchNumber: 100,
    kickoffUtcIso: '2026-07-12T01:00:00Z',
    stage: WorldCupStage.quarterFinal,
    homeTeam: 'W95',
    awayTeam: 'W96',
    venue: 'GEHA Field at Arrowhead Stadium, Kansas City',
  ),
  WorldCupFixture(
    matchNumber: 101,
    kickoffUtcIso: '2026-07-14T19:00:00Z',
    stage: WorldCupStage.semiFinal,
    homeTeam: 'W97',
    awayTeam: 'W98',
    venue: 'AT&T Stadium, Dallas',
  ),
  WorldCupFixture(
    matchNumber: 102,
    kickoffUtcIso: '2026-07-15T19:00:00Z',
    stage: WorldCupStage.semiFinal,
    homeTeam: 'W99',
    awayTeam: 'W100',
    venue: 'Mercedes-Benz Stadium, Atlanta',
  ),
  WorldCupFixture(
    matchNumber: 103,
    kickoffUtcIso: '2026-07-18T21:00:00Z',
    stage: WorldCupStage.thirdPlace,
    homeTeam: 'L101',
    awayTeam: 'L102',
    venue: 'Hard Rock Stadium, Miami',
  ),
  WorldCupFixture(
    matchNumber: 104,
    kickoffUtcIso: '2026-07-19T19:00:00Z',
    stage: WorldCupStage.finalMatch,
    homeTeam: 'W101',
    awayTeam: 'W102',
    venue: 'MetLife Stadium, New York/New Jersey',
  ),
];
