import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/world_cup_schedule.dart';

void main() {
  test('fixture list covers the 2026 World Cup schedule', () {
    expect(worldCupFixtures, hasLength(104));
    expect(worldCupFixtures.first.homeTeam, 'Mexico');
    expect(worldCupFixtures.first.awayTeam, 'South Africa');
    expect(worldCupFixtures.last.stage, WorldCupStage.finalMatch);
    expect(worldCupFixtures.last.venue, 'MetLife Stadium, New York/New Jersey');
  });

  test('fixture list includes seeded group-stage results', () {
    const expectedScores = <int, (int, int)>{
      1: (2, 0),
      2: (2, 1),
      3: (1, 1),
      4: (4, 1),
      5: (1, 1),
      6: (1, 1),
      7: (0, 1),
      8: (2, 0),
      9: (7, 1),
      10: (2, 2),
      11: (1, 0),
      12: (5, 1),
      13: (0, 0),
      14: (1, 1),
      15: (1, 1),
      16: (2, 2),
      17: (3, 1),
      18: (1, 4),
      19: (3, 0),
      20: (3, 1),
      21: (1, 1),
      22: (2, 2),
    };

    for (final entry in expectedScores.entries) {
      final fixture = worldCupFixtures.singleWhere(
        (fixture) => fixture.matchNumber == entry.key,
      );
      expect(fixture.homeScore, entry.value.$1, reason: 'M${entry.key}');
      expect(fixture.awayScore, entry.value.$2, reason: 'M${entry.key}');
    }

    expect(
      worldCupFixtures
          .singleWhere((fixture) => fixture.matchNumber == 23)
          .hasScore,
      isFalse,
    );
  });

  test('country helpers expose Korea Republic group fixtures', () {
    final countries = worldCupCountries();
    final koreaFixtures = worldCupFixturesForCountries(const {
      'Korea Republic',
    });

    expect(countries, contains('Korea Republic'));
    expect(countries, contains('Brazil'));
    expect(koreaFixtures, hasLength(3));
    expect(
      koreaFixtures.map((fixture) => fixture.awayTeam),
      contains('Korea Republic'),
    );
  });

  test(
    'fixtures can expose flags and match results when scores are present',
    () {
      const fixture = WorldCupFixture(
        matchNumber: 999,
        kickoffUtcIso: '2026-06-11T19:00:00Z',
        stage: WorldCupStage.group,
        group: 'A',
        homeTeam: 'Korea Republic',
        awayTeam: 'Czechia',
        venue: 'Test Stadium',
        homeScore: 2,
        awayScore: 1,
      );

      expect(worldCupCountryFlag('Korea Republic'), isNotEmpty);
      expect(worldCupCountryFlag('England'), isNotEmpty);
      expect(fixture.hasScore, isTrue);
      expect(
        fixture.resultForTeam('Korea Republic'),
        WorldCupFixtureTeamResult.win,
      );
      expect(fixture.resultForTeam('Czechia'), WorldCupFixtureTeamResult.loss);
    },
  );

  test('day and country helper filters selected-country calendar counts', () {
    final koreaFixture = worldCupFixturesForCountries(const {
      'Korea Republic',
    }).first;
    final allFixturesOnDay = worldCupFixturesForDay(koreaFixture.localDay);
    final selectedFixturesOnDay = worldCupFixturesForDayAndCountries(
      koreaFixture.localDay,
      const {'Korea Republic'},
    );

    expect(allFixturesOnDay.length, greaterThanOrEqualTo(1));
    expect(selectedFixturesOnDay, isNotEmpty);
    expect(
      selectedFixturesOnDay.length,
      lessThanOrEqualTo(allFixturesOnDay.length),
    );
    expect(
      selectedFixturesOnDay.every(
        (fixture) => fixture.involvesCountry('Korea Republic'),
      ),
      isTrue,
    );
  });

  test('group standings derive rank and record from scored fixtures', () {
    final standings = worldCupGroupStandings();
    final groupA = standings['A']!;

    expect(groupA.map((standing) => standing.team).take(2), [
      'Mexico',
      'Korea Republic',
    ]);
    expect(groupA.first.played, 1);
    expect(groupA.first.wins, 1);
    expect(groupA.first.draws, 0);
    expect(groupA.first.losses, 0);
    expect(groupA.first.points, 3);

    final korea = groupA.singleWhere(
      (standing) => standing.team == 'Korea Republic',
    );
    expect(korea.played, 1);
    expect(korea.wins, 1);
    expect(korea.losses, 0);
    expect(korea.goalDifference, 1);
  });

  test('group standings break point ties by goal difference and goals for', () {
    const fixtures = [
      WorldCupFixture(
        matchNumber: 9001,
        kickoffUtcIso: '2026-06-11T19:00:00Z',
        stage: WorldCupStage.group,
        group: 'Z',
        homeTeam: 'Alpha',
        awayTeam: 'Bravo',
        venue: 'Test Stadium',
        homeScore: 2,
        awayScore: 1,
      ),
      WorldCupFixture(
        matchNumber: 9002,
        kickoffUtcIso: '2026-06-12T19:00:00Z',
        stage: WorldCupStage.group,
        group: 'Z',
        homeTeam: 'Charlie',
        awayTeam: 'Delta',
        venue: 'Test Stadium',
        homeScore: 4,
        awayScore: 2,
      ),
      WorldCupFixture(
        matchNumber: 9003,
        kickoffUtcIso: '2026-06-13T19:00:00Z',
        stage: WorldCupStage.group,
        group: 'Z',
        homeTeam: 'Echo',
        awayTeam: 'Foxtrot',
        venue: 'Test Stadium',
        homeScore: 3,
        awayScore: 2,
      ),
    ];

    final groupZ = worldCupGroupStandings(fixtures: fixtures)['Z']!;

    expect(groupZ.map((standing) => standing.team).take(3), [
      'Charlie',
      'Echo',
      'Alpha',
    ]);
    expect(groupZ.first.goalDifference, 2);
    expect(groupZ[1].goalDifference, 1);
    expect(groupZ[1].goalsFor, 3);
    expect(groupZ[2].goalDifference, 1);
    expect(groupZ[2].goalsFor, 2);
  });

  test('round of 32 scenarios group remaining points by qualification path',
      () {
    final scenarios = worldCupRoundOf32ScenariosForTeam('Korea Republic');

    expect(scenarios, isNotEmpty);
    expect(scenarios.map((scenario) => scenario.remainingPoints), [
      6,
      4,
      3,
      2,
      1,
      0,
    ]);

    final winOut = scenarios.singleWhere(
      (scenario) => scenario.remainingPoints == 6,
    );
    expect(winOut.group, 'A');
    expect(winOut.currentPoints, 3);
    expect(winOut.remainingMatches, 2);
    expect(winOut.finalPoints, 9);
    expect(winOut.automaticAdvanceCases, winOut.totalCases);
    expect(winOut.thirdPlaceCases, 0);
    expect(winOut.eliminatedCases, 0);

    final noMorePoints = scenarios.singleWhere(
      (scenario) => scenario.remainingPoints == 0,
    );
    expect(noMorePoints.finalPoints, 3);
    expect(noMorePoints.eliminatedCases, greaterThan(0));
  });

  test('round of 32 path scenarios map remaining match results to opponents',
      () {
    final scenarios = worldCupRoundOf32PathScenariosForTeam('Korea Republic');

    expect(scenarios, hasLength(9));

    final winOut = _pathScenarioFor(
      scenarios,
      const [WorldCupFixtureTeamResult.win, WorldCupFixtureTeamResult.win],
    );
    expect(winOut.remainingPoints, 6);
    expect(winOut.finalPoints, 9);
    expect(winOut.guaranteesAutomaticAdvance, isTrue);
    expect(
      winOut.opponentPaths.map(_opponentPathKey),
      contains('1:79:3C/E/F/H/I'),
    );
    final winOutOpponentPath = winOut.opponentPaths.singleWhere(
      (path) => path.opponentSlot == '3C/E/F/H/I',
    );
    expect(winOutOpponentPath.opponentTeams, hasLength(5));
    expect(
      winOutOpponentPath.opponentTeams.every(
        (team) => team.trim().isNotEmpty && !team.contains('/'),
      ),
      isTrue,
    );

    final loseOut = _pathScenarioFor(
      scenarios,
      const [WorldCupFixtureTeamResult.loss, WorldCupFixtureTeamResult.loss],
    );
    expect(loseOut.remainingPoints, 0);
    expect(loseOut.finalPoints, 3);
    expect(loseOut.thirdPlaceCases, greaterThan(0));
    expect(loseOut.eliminatedCases, greaterThan(0));
  });

  test('round of 32 path scenarios shrink to one remaining team match', () {
    final fixtures = _fixturesWithScores({
      28: (1, 1),
    });
    final scenarios = worldCupRoundOf32PathScenariosForTeam(
      'Korea Republic',
      fixtures: fixtures,
    );

    expect(scenarios, hasLength(3));
    expect(
      scenarios.map((scenario) => scenario.picks.single.result).toSet(),
      {
        WorldCupFixtureTeamResult.win,
        WorldCupFixtureTeamResult.draw,
        WorldCupFixtureTeamResult.loss,
      },
    );
    for (final scenario in scenarios) {
      expect(scenario.remainingMatches, 1);
      expect(scenario.remainingGroupMatches, 3);
      expect(scenario.remainingOtherMatches, 2);
      expect(scenario.totalCases, 9);
      expect(scenario.otherMatchPaths, hasLength(9));
      expect(
        scenario.otherMatchPaths.every((path) => path.picks.length == 2),
        isTrue,
      );
    }
    final sampleOtherPath = scenarios.first.otherMatchPaths.first;
    expect(
      sampleOtherPath.picks.map((pick) => pick.matchNumber),
      [25, 53],
    );
    expect(sampleOtherPath.rank, inInclusiveRange(1, 4));
  });

  test('round of 32 path scenarios keep updating after team fixtures end', () {
    final fixtures = _fixturesWithScores({
      28: (1, 1),
      54: (0, 2),
    });
    final scenarios = worldCupRoundOf32PathScenariosForTeam(
      'Korea Republic',
      fixtures: fixtures,
    );

    expect(scenarios, hasLength(1));
    final scenario = scenarios.single;
    expect(scenario.picks, isEmpty);
    expect(scenario.currentPoints, 7);
    expect(scenario.remainingMatches, 0);
    expect(scenario.remainingGroupMatches, 2);
    expect(scenario.remainingOtherMatches, 2);
    expect(scenario.totalCases, 9);
    expect(scenario.otherMatchPaths, hasLength(9));
    expect(
      scenario.otherMatchPaths.expand((path) => path.picks).map(
            (pick) => pick.matchNumber,
          ),
      everyElement(anyOf(25, 53)),
    );
    expect(scenario.canAdvance, isTrue);
  });

  test('round of 32 path scenarios show a fixed state when group is complete',
      () {
    final fixtures = _fixturesWithScores({
      25: (0, 0),
      28: (1, 1),
      53: (0, 1),
      54: (0, 2),
    });
    final scenarios = worldCupRoundOf32PathScenariosForTeam(
      'Korea Republic',
      fixtures: fixtures,
    );

    expect(scenarios, hasLength(1));
    final scenario = scenarios.single;
    expect(scenario.picks, isEmpty);
    expect(scenario.remainingMatches, 0);
    expect(scenario.remainingGroupMatches, 0);
    expect(scenario.remainingOtherMatches, 0);
    expect(scenario.totalCases, 1);
    expect(scenario.otherMatchPaths, hasLength(1));
    expect(scenario.otherMatchPaths.single.picks, isEmpty);
    expect(scenario.guaranteesAutomaticAdvance, isTrue);
  });

  test('round of 32 opponent paths follow bracket slots by group rank', () {
    final groupWinnerPaths = worldCupRoundOf32OpponentPathsForGroupRank(
      'A',
      1,
    );
    expect(groupWinnerPaths.map(_opponentPathKey), ['1:79:3C/E/F/H/I']);
    expect(groupWinnerPaths.single.opponentTeams, hasLength(5));
    expect(
      worldCupRoundOf32OpponentPathsForGroupRank('A', 2).map(_opponentPathKey),
      ['2:73:2B'],
    );
    expect(
      worldCupRoundOf32OpponentPathsForGroupRank('A', 3).map(_opponentPathKey),
      ['3:75:1E', '3:81:1G'],
    );
  });

  test('round of 32 scenarios ignore countries outside the group schedule', () {
    expect(
      worldCupRoundOf32ScenariosForTeam('Atlantis'),
      isEmpty,
    );
  });
}

WorldCupQualificationPathScenario _pathScenarioFor(
  List<WorldCupQualificationPathScenario> scenarios,
  List<WorldCupFixtureTeamResult> results,
) {
  return scenarios.singleWhere(
    (scenario) =>
        scenario.picks.length == results.length &&
        Iterable<int>.generate(results.length).every(
          (index) => scenario.picks[index].result == results[index],
        ),
  );
}

String _opponentPathKey(WorldCupQualificationOpponentPath path) {
  return '${path.rank}:${path.matchNumber}:${path.opponentSlot}';
}

List<WorldCupFixture> _fixturesWithScores(Map<int, (int, int)> scoresByMatch) {
  return [
    for (final fixture in worldCupFixtures)
      if (scoresByMatch[fixture.matchNumber] case final score?)
        fixture.copyWithScore(homeScore: score.$1, awayScore: score.$2)
      else
        fixture,
  ];
}
