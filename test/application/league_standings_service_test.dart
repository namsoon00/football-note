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

  test('parses ESPN fixture payload with Champions League bracket notes', () {
    final snapshot = LeagueStandingsService.parseFixtureSnapshotForTesting(
      type: LeagueStandingsType.championsLeague,
      fetchedAt: DateTime(2026, 5, 24, 12),
      payload: {
        'leagues': [
          {
            'name': 'UEFA Champions League',
            'season': {'displayName': '2025-26 UEFA Champions League'},
            'links': [
              {
                'href':
                    'https://www.espn.com/soccer/fixtures/_/league/uefa.champions',
              },
            ],
          },
        ],
        'events': [
          {
            'id': 'semi-2',
            'date': '2026-05-05T19:00Z',
            'season': {'slug': 'semifinals'},
            'links': [
              {'href': 'https://www.espn.com/soccer/match/_/gameId/semi-2'},
            ],
            'competitions': [
              {
                'id': 'semi-2',
                'date': '2026-05-05T19:00Z',
                'status': {
                  'type': {'state': 'post', 'completed': true},
                },
                'venue': {
                  'fullName': 'Emirates Stadium',
                  'address': {'city': 'London'},
                },
                'leg': {'displayValue': '2nd Leg'},
                'series': {'title': 'Semifinals'},
                'notes': [
                  {'headline': '2nd Leg - Arsenal advance 2-1 on aggregate'},
                ],
                'competitors': [
                  {
                    'homeAway': 'home',
                    'score': '1',
                    'team': {
                      'displayName': 'Arsenal',
                      'shortDisplayName': 'Arsenal',
                      'logos': [
                        {'href': 'https://example.com/arsenal.png'},
                      ],
                    },
                  },
                  {
                    'homeAway': 'away',
                    'score': '0',
                    'team': {
                      'displayName': 'Atlético Madrid',
                      'shortDisplayName': 'Atleti',
                    },
                  },
                ],
              },
            ],
          },
          {
            'id': 'final',
            'date': '2026-05-30T19:00Z',
            'season': {'slug': 'final'},
            'competitions': [
              {
                'id': 'final',
                'date': '2026-05-30T19:00Z',
                'status': {
                  'type': {'state': 'pre', 'completed': false},
                },
                'series': {'title': 'Final'},
                'competitors': [
                  {
                    'homeAway': 'home',
                    'team': {
                      'displayName': 'Arsenal',
                      'shortDisplayName': 'Arsenal',
                    },
                  },
                  {
                    'homeAway': 'away',
                    'team': {
                      'displayName': 'Barcelona',
                      'shortDisplayName': 'Barca',
                    },
                  },
                ],
              },
            ],
          },
        ],
      },
    );

    expect(snapshot.leagueName, 'UEFA Champions League');
    expect(snapshot.seasonName, '2025-26 UEFA Champions League');
    expect(snapshot.sourceUrl, contains('espn.com'));
    expect(snapshot.entries, hasLength(2));
    expect(snapshot.entries.first.id, 'final');
    expect(snapshot.entries.first.status, LeagueFixtureStatus.scheduled);
    expect(snapshot.entries.first.stage, 'Final');
    expect(snapshot.entries.last.status, LeagueFixtureStatus.finished);
    expect(snapshot.entries.last.leg, '2nd Leg');
    expect(snapshot.entries.last.note, contains('aggregate'));
    expect(snapshot.entries.last.homeScore, 1);
    expect(snapshot.entries.last.awayTeamName, 'Atlético Madrid');
  });
}
