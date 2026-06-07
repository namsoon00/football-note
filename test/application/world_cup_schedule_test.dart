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
}
