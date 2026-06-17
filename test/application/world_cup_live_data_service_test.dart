import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/fifa_world_overview_service.dart';
import 'package:football_note/application/world_cup_live_data_service.dart';
import 'package:football_note/domain/entities/fifa_world_overview.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'fetchLatest overlays FIFA World Cup results onto local fixtures',
    () async {
      final parsed = FifaWorldOverviewService.parseNationalMatches([
        _worldCupMatch(
          matchId: 'parse-check',
          matchNumber: 7,
          period: 10,
          date: '2026-06-13T22:00:00Z',
          homeName: 'Brazil',
          homeCode: 'BRA',
          awayName: 'Morocco',
          awayCode: 'MAR',
          homeScore: 1,
          awayScore: 1,
          calendarShape: true,
        ),
      ], gender: FifaRankingGender.men);
      expect(parsed, hasLength(1));

      final requestedRanges = <Map<String, String>>[];
      final requestedCompetitionMatches = <Map<String, String>>[];
      final client = MockClient((request) async {
        if (request.url.host == 'api.fifa.com' &&
            request.url.path.endsWith('/rankingschedules/all')) {
          return http.Response(jsonEncode({'Results': []}), 200);
        }
        if (request.url.host == 'api.fifa.com' &&
            request.url.path.endsWith('/fifarankings/rankings/live')) {
          return http.Response(
            jsonEncode({
              'Results': [
                _rankingEntry(
                  teamId: '43822',
                  countryCode: 'KOR',
                  teamName: 'Korea Republic',
                  rank: 21,
                  previousRank: 25,
                ),
                _rankingEntry(
                  teamId: '43924',
                  countryCode: 'CPV',
                  teamName: 'Cabo Verde',
                  rank: 70,
                  previousRank: 72,
                ),
              ],
            }),
            200,
          );
        }
        if (request.url.host == 'inside.fifa.com') {
          return http.Response('', 200);
        }
        if (request.url.host == 'api.fifa.com' &&
            request.url.path.endsWith('/calendar/matches')) {
          requestedCompetitionMatches.add(request.url.queryParameters);
          return http.Response(
            jsonEncode({
              'Results': [
                _worldCupMatch(
                  matchId: 'official-mexico-calendar',
                  matchNumber: 1,
                  period: 0,
                  date: '2026-06-11T19:00:00Z',
                  homeName: 'Mexico',
                  homeCode: 'MEX',
                  awayName: 'South Africa',
                  awayCode: 'RSA',
                  calendarShape: true,
                ),
                _worldCupMatch(
                  matchId: 'official-brazil-calendar',
                  matchNumber: 7,
                  period: 10,
                  date: '2026-06-13T22:00:00Z',
                  homeName: 'Brazil',
                  homeCode: 'BRA',
                  awayName: 'Morocco',
                  awayCode: 'MAR',
                  homeScore: 1,
                  awayScore: 1,
                  calendarShape: true,
                ),
                _worldCupMatch(
                  matchId: 'official-australia-calendar',
                  matchNumber: 6,
                  period: 10,
                  date: '2026-06-14T04:00:00Z',
                  homeName: 'Australia',
                  homeCode: 'AUS',
                  awayName: 'Turkiye',
                  awayCode: 'TUR',
                  homeScore: 2,
                  awayScore: 0,
                  calendarShape: true,
                ),
                _worldCupMatch(
                  matchId: 'official-spain-calendar',
                  matchNumber: 14,
                  period: 10,
                  date: '2026-06-15T16:00:00Z',
                  homeName: 'Spain',
                  homeCode: 'ESP',
                  awayName: 'Cabo Verde',
                  awayCode: 'CPV',
                  homeScore: 0,
                  awayScore: 0,
                  calendarShape: true,
                ),
                _worldCupMatch(
                  matchId: 'official-iran-calendar',
                  matchNumber: 15,
                  period: 10,
                  date: '2026-06-16T01:00:00Z',
                  homeName: 'IR Iran',
                  homeCode: 'IRN',
                  awayName: 'New Zealand',
                  awayCode: 'NZL',
                  homeScore: 2,
                  awayScore: 2,
                  calendarShape: true,
                ),
              ],
            }),
            200,
          );
        }
        if (request.url.host == 'api.fifa.com' &&
            request.url.path.endsWith('/live/football/range')) {
          requestedRanges.add(request.url.queryParameters);
          return http.Response(
            jsonEncode({
              'Results': [
                _worldCupMatch(
                  matchId: 'official-mexico',
                  matchNumber: 1,
                  period: 0,
                  date: '2026-06-11T19:00:00Z',
                  homeName: 'Mexico',
                  homeCode: 'MEX',
                  awayName: 'South Africa',
                  awayCode: 'RSA',
                ),
                _worldCupMatch(
                  matchId: 'official-brazil',
                  matchNumber: 7,
                  period: 10,
                  date: '2026-06-13T22:00:00Z',
                  homeName: 'Brazil',
                  homeCode: 'BRA',
                  awayName: 'Morocco',
                  awayCode: 'MAR',
                  homeScore: 1,
                  awayScore: 1,
                ),
                _worldCupMatch(
                  matchId: 'official-australia',
                  matchNumber: 6,
                  period: 10,
                  date: '2026-06-14T04:00:00Z',
                  homeName: 'Australia',
                  homeCode: 'AUS',
                  awayName: 'Türkiye',
                  awayCode: 'TUR',
                  homeScore: 2,
                  awayScore: 0,
                ),
                _worldCupMatch(
                  matchId: 'official-spain',
                  matchNumber: 14,
                  period: 10,
                  date: '2026-06-15T16:00:00Z',
                  homeName: 'Spain',
                  homeCode: 'ESP',
                  awayName: 'Cabo Verde',
                  awayCode: 'CPV',
                  homeScore: 0,
                  awayScore: 0,
                ),
                _worldCupMatch(
                  matchId: 'official-iran',
                  matchNumber: 15,
                  period: 10,
                  date: '2026-06-16T01:00:00Z',
                  homeName: 'IR Iran',
                  homeCode: 'IRN',
                  awayName: 'New Zealand',
                  awayCode: 'NZL',
                  homeScore: 2,
                  awayScore: 2,
                ),
              ],
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });
      final fifaService = FifaWorldOverviewService(client: client);
      final fetchedMatches = await fifaService.fetchNationalMatches(
        gender: FifaRankingGender.men,
        start: DateTime.utc(2026, 6, 11, 7),
        end: DateTime.utc(2026, 6, 15, 5),
      );
      expect(fetchedMatches, hasLength(5));
      final service = WorldCupLiveDataService(fifaService: fifaService);

      final data = await service.fetchLatest(now: DateTime.utc(2026, 6, 16, 5));

      final brazil = data.fixtures.firstWhere(
        (fixture) =>
            fixture.homeTeam == 'Brazil' && fixture.awayTeam == 'Morocco',
      );
      final australia = data.fixtures.firstWhere(
        (fixture) =>
            fixture.homeTeam == 'Australia' && fixture.awayTeam == 'Turkiye',
      );
      final spain = data.fixtures.firstWhere(
        (fixture) =>
            fixture.homeTeam == 'Spain' && fixture.awayTeam == 'Cape Verde',
      );
      final iran = data.fixtures.firstWhere(
        (fixture) =>
            fixture.homeTeam == 'Iran' && fixture.awayTeam == 'New Zealand',
      );

      expect(brazil.homeScore, 1);
      expect(brazil.awayScore, 1);
      expect(australia.homeScore, 2);
      expect(australia.awayScore, 0);
      expect(spain.homeScore, 0);
      expect(spain.awayScore, 0);
      expect(iran.homeScore, 2);
      expect(iran.awayScore, 2);
      expect(
        data.officialMatchesByFixtureNumber[brazil.matchNumber]?.matchNumber,
        7,
      );
      expect(
        data.officialMatchesByFixtureNumber[spain.matchNumber]?.matchNumber,
        14,
      );
      expect(
        data.officialMatchesByFixtureNumber[iran.matchNumber]?.matchNumber,
        15,
      );
      expect(data.rankingsByTeam['Korea Republic']?.rank, 21);
      expect(data.rankingsByTeam['Cape Verde']?.rank, 70);
      expect(requestedCompetitionMatches, isNotEmpty);
      expect(requestedRanges, isNotEmpty);

      service.dispose();
    },
  );
}

Map<String, dynamic> _rankingEntry({
  required String teamId,
  required String countryCode,
  required String teamName,
  required int rank,
  required int previousRank,
}) {
  return {
    'IdTeam': teamId,
    'IdCountry': countryCode,
    'ConfederationName': 'TEST',
    'Rank': rank,
    'PrevRank': previousRank,
    'TotalPoints': 1600.0,
    'PrevPoints': 1500.0,
    'TeamName': [
      {'Locale': 'en-GB', 'Description': teamName},
    ],
  };
}

Map<String, dynamic> _worldCupMatch({
  required String matchId,
  required int matchNumber,
  required int period,
  required String date,
  required String homeName,
  required String homeCode,
  required String awayName,
  required String awayCode,
  int? homeScore,
  int? awayScore,
  bool calendarShape = false,
}) {
  final home = _team(name: homeName, countryCode: homeCode, score: homeScore);
  final away = _team(name: awayName, countryCode: awayCode, score: awayScore);
  return {
    'IdMatch': matchId,
    'MatchNumber': matchNumber,
    'Date': date,
    'Period': period,
    'CompetitionName': [
      {'Locale': 'en-GB', 'Description': 'FIFA World Cup'},
    ],
    'StageName': [
      {'Locale': 'en-GB', 'Description': 'First Stage'},
    ],
    'Stadium': {
      'Name': [
        {'Locale': 'en-GB', 'Description': 'Test Stadium'},
      ],
      'CityName': [
        {'Locale': 'en-GB', 'Description': 'Test City'},
      ],
    },
    if (calendarShape) 'Home': home else 'HomeTeam': home,
    if (calendarShape) 'Away': away else 'AwayTeam': away,
  };
}

Map<String, dynamic> _team({
  required String name,
  required String countryCode,
  required int? score,
}) {
  return {
    'Gender': 1,
    'TeamType': 1,
    'AgeType': 7,
    'FootballType': 0,
    'IdCountry': countryCode,
    'Score': score,
    'TeamName': [
      {'Locale': 'en-GB', 'Description': name},
    ],
  };
}
