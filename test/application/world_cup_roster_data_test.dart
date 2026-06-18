import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/world_cup_roster_data.dart';
import 'package:football_note/application/world_cup_schedule.dart';

void main() {
  test('club lookup prefers FIFA player id and keeps name fallback', () {
    expect(
      worldCupRosterClubForPlayer(
        'Korea Republic',
        'Unmatched player name',
        playerId: '307849',
      ),
      'Los Angeles FC',
    );
    expect(
      worldCupRosterClubForPlayer(
        'Korea Republic',
        'Son Heung-min',
        playerId: 'unknown',
      ),
      'Los Angeles FC',
    );
    expect(
      worldCupRosterClubForPlayer('Korea Republic', '손흥민'),
      'Los Angeles FC',
    );
  });

  test('all scheduled World Cup countries have roster and formation data', () {
    for (final country in worldCupCountries()) {
      final roster = worldCupRosterPoolForTeam(country);

      expect(roster, isNotNull, reason: country);
      expect(roster!.formation, matches(RegExp(r'^\d-\d(?:-\d){1,3}$')));
      expect(roster.goalkeepers.length, greaterThanOrEqualTo(3));
      expect(roster.defenders.length, greaterThanOrEqualTo(4));
      expect(roster.midfielders.length, greaterThanOrEqualTo(3));
      expect(roster.forwards.length, greaterThanOrEqualTo(3));
    }
  });
}
