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
}
