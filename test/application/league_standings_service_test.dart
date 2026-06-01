import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/league_standings_service.dart';
import 'package:football_note/domain/entities/league_standings.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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
                      'logo': 'https://example.com/arsenal-fixture.png',
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
    expect(
      snapshot.entries.last.homeLogoUrl,
      'https://example.com/arsenal-fixture.png',
    );
    expect(snapshot.entries.last.awayTeamName, 'Atlético Madrid');
  });

  test('parses K League standings payload', () {
    final snapshot = LeagueStandingsService.parseKLeagueSnapshotForTesting(
      fetchedAt: DateTime(2026, 5, 26, 12),
      payload: {
        'resultCode': '200',
        'data': {
          'teamRank': [
            {
              'year': 2026,
              'teamId': 'K09',
              'teamName': '서울',
              'rank': 1,
              'gameCount': 15,
              'gainPoint': 32,
              'winCnt': 10,
              'tieCnt': 2,
              'lossCnt': 3,
              'gainGoal': 27,
              'lossGoal': 12,
              'gapCnt': 15,
            },
          ],
        },
      },
    );

    expect(snapshot.type, LeagueStandingsType.kLeague1);
    expect(snapshot.leagueName, 'K League 1');
    expect(snapshot.seasonName, '2026 K League 1');
    expect(snapshot.sourceUrl, contains('kleague.com'));
    expect(snapshot.entries.single.teamName, '서울');
    expect(snapshot.entries.single.logoUrl, contains('emblem_K09.png'));
    expect(snapshot.entries.single.points, '32');
    expect(snapshot.entries.single.goalDifference, '15');
  });

  test(
    'K League standings falls back to previous season when current is empty',
    () async {
      final requestedYears = <String>[];
      final currentYear = DateTime.now().year;
      final previousYear = currentYear - 1;
      final service = LeagueStandingsService(
        client: MockClient((request) async {
          requestedYears.add(request.url.queryParameters['year'] ?? '');
          final year = request.url.queryParameters['year'];
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'resultCode': '200',
                'data': {
                  'teamRank': year == previousYear.toString()
                      ? [
                          {
                            'year': previousYear,
                            'teamId': 'K09',
                            'teamName': '서울',
                            'rank': 1,
                            'gameCount': 33,
                            'gainPoint': 61,
                            'winCnt': 18,
                            'tieCnt': 7,
                            'lossCnt': 8,
                            'gainGoal': 52,
                            'lossGoal': 30,
                            'gapCnt': 22,
                          },
                        ]
                      : const [],
                },
              }),
            ),
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(service.dispose);

      final snapshot = await service.fetch(LeagueStandingsType.kLeague1);

      expect(requestedYears, [currentYear.toString(), previousYear.toString()]);
      expect(snapshot.seasonName, '$previousYear K League 1');
      expect(snapshot.entries.single.teamName, '서울');
    },
  );

  test('parses K League fixture payload', () {
    final snapshot =
        LeagueStandingsService.parseKLeagueFixtureSnapshotsForTesting(
          fetchedAt: DateTime(2026, 5, 26, 12),
          payloads: [
            {
              'resultCode': '200',
              'data': {
                'scheduleList': [
                  {
                    'year': 2026,
                    'leagueId': 1,
                    'roundId': 11,
                    'gameId': 61,
                    'gameDate': '2026.05.02',
                    'gameTime': '14:00',
                    'endYn': 'Y',
                    'gameStatus': 'FE',
                    'homeTeamName': '서울',
                    'homeTeam': 'K09',
                    'awayTeamName': '김천',
                    'awayTeam': 'K35',
                    'homeGoal': 2,
                    'awayGoal': 3,
                    'fieldName': '서울 월드컵',
                    'fieldNameFull': '서울 월드컵 경기장',
                    'codeName': '스플릿일반',
                    'meetSeq': 1,
                  },
                ],
              },
            },
          ],
        );

    expect(snapshot.type, LeagueStandingsType.kLeague1);
    expect(snapshot.entries, hasLength(1));
    expect(snapshot.entries.single.id, '2026-1-61-1');
    expect(snapshot.entries.single.status, LeagueFixtureStatus.finished);
    expect(snapshot.entries.single.stage, 'R11');
    expect(snapshot.entries.single.homeTeamName, '서울');
    expect(snapshot.entries.single.homeLogoUrl, contains('emblem_K09.png'));
    expect(snapshot.entries.single.awayTeamName, '김천');
    expect(snapshot.entries.single.awayLogoUrl, contains('emblem_K35.png'));
    expect(snapshot.entries.single.homeScore, 2);
    expect(snapshot.entries.single.awayScore, 3);
    expect(snapshot.entries.single.sourceUrl, contains('/match.do'));
  });

  test('filters K League fixtures to the requested schedule window', () {
    final snapshot =
        LeagueStandingsService.parseKLeagueFixtureSnapshotsForTesting(
          fetchedAt: DateTime(2026, 5, 26, 12),
          start: DateTime.utc(2026, 5, 12),
          end: DateTime.utc(2026, 6, 9),
          payloads: [
            {
              'resultCode': '200',
              'data': {
                'scheduleList': [
                  {
                    'year': 2026,
                    'leagueId': 1,
                    'roundId': 10,
                    'gameId': 50,
                    'gameDate': '2026.05.01',
                    'gameTime': '14:00',
                    'endYn': 'Y',
                    'gameStatus': 'FE',
                    'homeTeamName': '서울',
                    'homeTeam': 'K09',
                    'awayTeamName': '김천',
                    'awayTeam': 'K35',
                    'meetSeq': 1,
                  },
                  {
                    'year': 2026,
                    'leagueId': 1,
                    'roundId': 15,
                    'gameId': 80,
                    'gameDate': '2026.05.30',
                    'gameTime': '19:00',
                    'endYn': 'N',
                    'gameStatus': 'BE',
                    'homeTeamName': '서울',
                    'homeTeam': 'K09',
                    'awayTeamName': '울산',
                    'awayTeam': 'K01',
                    'meetSeq': 1,
                  },
                  {
                    'year': 2026,
                    'leagueId': 1,
                    'roundId': 20,
                    'gameId': 95,
                    'gameDate': '2026.06.20',
                    'gameTime': '19:00',
                    'endYn': 'N',
                    'gameStatus': 'BE',
                    'homeTeamName': '서울',
                    'homeTeam': 'K09',
                    'awayTeamName': '전북',
                    'awayTeam': 'K05',
                    'meetSeq': 1,
                  },
                ],
              },
            },
          ],
        );

    expect(snapshot.entries, hasLength(1));
    expect(snapshot.entries.single.id, '2026-1-80-1');
  });
}
