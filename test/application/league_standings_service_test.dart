import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/league_standings_service.dart';
import 'package:football_note/domain/entities/league_standings.dart';

void main() {
  test('parses ESPN standings payload', () {
    final snapshot = LeagueStandingsService.parseSnapshotForTesting(
      type: LeagueStandingsType.premierLeague,
      payload: {
        'name': 'English Premier League',
        'children': [
          {
            'name': 'English Premier League 2025-2026',
            'standings': {
              'seasonDisplayName': '2025-26 English Premier League',
              'links': [
                {'href': 'https://www.espn.com/soccer/table/_/league/eng.1'},
              ],
              'entries': [
                {
                  'team': {
                    'displayName': 'Arsenal',
                    'shortDisplayName': 'Arsenal',
                    'logos': [
                      {'href': 'https://example.com/arsenal.png'},
                    ],
                  },
                  'note': {'description': 'Champions League'},
                  'stats': [
                    {'type': 'rank', 'value': 1, 'displayValue': '1'},
                    {'type': 'gamesplayed', 'displayValue': '36'},
                    {'type': 'wins', 'displayValue': '24'},
                    {'type': 'ties', 'displayValue': '7'},
                    {'type': 'losses', 'displayValue': '5'},
                    {'type': 'pointsfor', 'displayValue': '68'},
                    {'type': 'pointsagainst', 'displayValue': '26'},
                    {'type': 'pointdifferential', 'displayValue': '+42'},
                    {'type': 'points', 'displayValue': '79'},
                  ],
                },
              ],
            },
          },
        ],
      },
    );

    expect(snapshot.leagueName, 'English Premier League');
    expect(snapshot.seasonName, '2025-26 English Premier League');
    expect(snapshot.sourceUrl, contains('espn.com'));
    expect(snapshot.entries, hasLength(1));
    expect(snapshot.entries.single.teamName, 'Arsenal');
    expect(snapshot.entries.single.rank, 1);
    expect(snapshot.entries.single.played, '36');
    expect(snapshot.entries.single.goalDifference, '+42');
    expect(snapshot.entries.single.points, '79');
  });
}
