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

  test('club lookup covers non-Korean managed roster players', () {
    expect(
      worldCupRosterClubForPlayer('Mexico', 'Santiago Gimenez'),
      'AC Milan',
    );
    expect(
      worldCupRosterClubForPlayer('Mexico', 'Raul Rangel'),
      'Deportivo Guadalajara',
    );
    expect(
      worldCupRosterClubForPlayer('Mexico', 'Cesar Huerta'),
      'RSC Anderlecht',
    );
  });

  test('club lookup covers every scheduled roster country', () {
    for (final team in worldCupCountries()) {
      final roster = worldCupRosterPoolForTeam(team);

      expect(roster, isNotNull, reason: team);
      for (final player in _rosterPlayers(roster!)) {
        expect(
          worldCupRosterClubForPlayer(team, player),
          isNotEmpty,
          reason: '$team / $player',
        );
      }
    }
  });

  test('club lookup matches official names with diacritics', () {
    expect(
      worldCupRosterClubForPlayer('Portugal', 'João Félix'),
      'Al-Nassr FC',
    );
    expect(
      worldCupRosterClubForPlayer('France', 'Kylian Mbappé'),
      'Real Madrid',
    );
    expect(
      worldCupRosterClubForPlayer('England', 'Marc Guéhi'),
      'Manchester City',
    );
    expect(
      worldCupRosterClubForPlayer('Spain', 'Yéremy Pino'),
      'Crystal Palace',
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

Iterable<String> _rosterPlayers(WorldCupRosterPool roster) sync* {
  yield* roster.goalkeepers;
  yield* roster.defenders;
  yield* roster.midfielders;
  yield* roster.forwards;
}
