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

    final loseOut = _pathScenarioFor(
      scenarios,
      const [WorldCupFixtureTeamResult.loss, WorldCupFixtureTeamResult.loss],
    );
    expect(loseOut.remainingPoints, 0);
    expect(loseOut.finalPoints, 3);
    expect(loseOut.thirdPlaceCases, greaterThan(0));
    expect(loseOut.eliminatedCases, greaterThan(0));
  });

  test('round of 32 opponent paths follow bracket slots by group rank', () {
    expect(
      worldCupRoundOf32OpponentPathsForGroupRank('A', 1).map(_opponentPathKey),
      ['1:79:3C/E/F/H/I'],
    );
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
