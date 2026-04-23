import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/fifa_world_overview_service.dart';
import 'package:football_note/domain/entities/fifa_world_overview.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('parseRankingEntries sorts results and prefers English labels', () {
    final entries = FifaWorldOverviewService.parseRankingEntries({
      'Results': [
        {
          'IdTeam': '724',
          'IdCountry': 'ESP',
          'ConfederationName': 'UEFA',
          'Rank': 2,
          'PrevRank': 3,
          'DecimalTotalPoints': 2012.55,
          'DecimalPrevPoints': 1997.10,
          'PubDate': '2026-04-03T00:00:00Z',
          'TeamName': [
            {'Locale': 'ko-KR', 'Description': '스페인'},
            {'Locale': 'en-GB', 'Description': 'Spain'},
          ],
        },
        {
          'IdTeam': '741',
          'IdCountry': 'ARG',
          'ConfederationName': 'CONMEBOL',
          'Rank': 1,
          'PrevRank': 1,
          'DecimalTotalPoints': 2040.71,
          'DecimalPrevPoints': 2040.71,
          'PubDate': '2026-04-03T00:00:00Z',
          'TeamName': [
            {'Locale': 'es', 'Description': 'Argentina'},
          ],
        },
      ],
    });

    expect(entries, hasLength(2));
    expect(entries.first.teamName, 'Argentina');
    expect(entries.first.rank, 1);
    expect(entries.last.teamName, 'Spain');
    expect(entries.last.rankMovement, 1);
  });

  test('parseNationalMatches keeps only senior national-team fixtures', () {
    final menMatches = FifaWorldOverviewService.parseNationalMatches([
      _match(
        matchId: 'men-live',
        gender: 1,
        period: 4,
        competition: 'FIFA World Cup Qualifiers',
        stage: 'Round 3',
        homeName: 'Japan',
        homeCode: 'JPN',
        awayName: 'Australia',
        awayCode: 'AUS',
        venue: 'Saitama Stadium',
        city: 'Saitama',
        date: '2026-06-09T10:35:00Z',
      ),
      _match(
        matchId: 'club-match',
        gender: 1,
        period: 10,
        competition: 'Club Friendly',
        stage: '',
        homeName: 'Club A',
        homeCode: 'AAA',
        awayName: 'Club B',
        awayCode: 'BBB',
        date: '2026-06-09T12:00:00Z',
        homeTeamType: 0,
        awayTeamType: 0,
      ),
      _match(
        matchId: 'women-fixture',
        gender: 2,
        period: 0,
        competition: 'Women Friendly',
        stage: 'Matchday 1',
        homeName: 'USA',
        homeCode: 'USA',
        awayName: 'Canada',
        awayCode: 'CAN',
        date: '2026-06-10T01:00:00Z',
      ),
    ], gender: FifaRankingGender.men);

    final womenMatches = FifaWorldOverviewService.parseNationalMatches([
      _match(
        matchId: 'men-live',
        gender: 1,
        period: 4,
        competition: 'FIFA World Cup Qualifiers',
        stage: 'Round 3',
        homeName: 'Japan',
        homeCode: 'JPN',
        awayName: 'Australia',
        awayCode: 'AUS',
        date: '2026-06-09T10:35:00Z',
      ),
      _match(
        matchId: 'women-fixture',
        gender: 2,
        period: 0,
        competition: 'Women Friendly',
        stage: 'Matchday 1',
        homeName: 'USA',
        homeCode: 'USA',
        awayName: 'Canada',
        awayCode: 'CAN',
        date: '2026-06-10T01:00:00Z',
      ),
    ], gender: FifaRankingGender.women);

    expect(menMatches, hasLength(1));
    expect(menMatches.single.matchId, 'men-live');
    expect(menMatches.single.status, FifaAMatchStatus.live);
    expect(menMatches.single.homeTeamName, 'Japan');

    expect(womenMatches, hasLength(1));
    expect(womenMatches.single.matchId, 'women-fixture');
    expect(womenMatches.single.status, FifaAMatchStatus.scheduled);
  });

  test(
    'fetchOverview combines ranking page, schedules, and worldwide A-matches',
    () async {
      final client = MockClient((request) async {
        if (request.url.host == 'api.fifa.com' &&
            request.url.path.endsWith('/rankings/')) {
          return http.Response(
            jsonEncode({
              'Results': [
                {
                  'IdTeam': '741',
                  'IdCountry': 'ARG',
                  'ConfederationName': 'CONMEBOL',
                  'Rank': 1,
                  'PrevRank': 1,
                  'DecimalTotalPoints': 2040.71,
                  'DecimalPrevPoints': 2040.71,
                  'PubDate': '2026-04-03T00:00:00Z',
                  'TeamName': [
                    {'Locale': 'en', 'Description': 'Argentina'},
                  ],
                },
                {
                  'IdTeam': '724',
                  'IdCountry': 'ESP',
                  'ConfederationName': 'UEFA',
                  'Rank': 2,
                  'PrevRank': 3,
                  'DecimalTotalPoints': 2012.55,
                  'DecimalPrevPoints': 1997.10,
                  'PubDate': '2026-04-03T00:00:00Z',
                  'TeamName': [
                    {'Locale': 'en', 'Description': 'Spain'},
                  ],
                },
              ],
            }),
            200,
          );
        }

        if (request.url.host == 'api.fifa.com' &&
            request.url.path.endsWith('/rankingschedules/all')) {
          return http.Response(
            jsonEncode({
              'Results': [
                {
                  'OfficialDate': '2026-04-03T00:00:00Z',
                  'MatchWindowEndDate': '2026-04-01',
                },
              ],
            }),
            200,
          );
        }

        if (request.url.host == 'inside.fifa.com') {
          return http.Response('''
          <html>
            <body>
              <script>
                window.__DATA__ = {
                  "lastUpdateDate":"2026-04-03T00:00:00Z",
                  "nextUpdateDate":"2026-06-11T00:00:00Z"
                };
              </script>
            </body>
          </html>
          ''', 200);
        }

        if (request.url.host == 'api.fifa.com' &&
            request.url.path.endsWith('/live/football/range')) {
          return http.Response(
            jsonEncode({
              'Results': [
                _match(
                  matchId: 'recent-result',
                  gender: 1,
                  period: 10,
                  competition: 'FIFA World Cup Qualifiers',
                  stage: 'Round 3',
                  homeName: 'Japan',
                  homeCode: 'JPN',
                  awayName: 'Australia',
                  awayCode: 'AUS',
                  date: '2026-04-01T10:35:00Z',
                  homeScore: 2,
                  awayScore: 1,
                  venue: 'Saitama Stadium',
                  city: 'Saitama',
                ),
                _match(
                  matchId: 'upcoming-fixture',
                  gender: 1,
                  period: 0,
                  competition: 'International Friendly',
                  stage: 'Matchday 1',
                  homeName: 'Brazil',
                  homeCode: 'BRA',
                  awayName: 'France',
                  awayCode: 'FRA',
                  date: '2026-06-08T19:00:00Z',
                  venue: 'Maracana',
                  city: 'Rio de Janeiro',
                ),
              ],
            }),
            200,
          );
        }

        return http.Response('Not found', 404);
      });

      final service = FifaWorldOverviewService(client: client);
      final overview = await service.fetchOverview(
        gender: FifaRankingGender.men,
        now: DateTime.utc(2026, 4, 23),
      );

      expect(overview.rankings, hasLength(2));
      expect(overview.leader?.teamName, 'Argentina');
      expect(overview.lastUpdatedAt, DateTime.utc(2026, 4, 3));
      expect(overview.nextUpdatedAt, DateTime.utc(2026, 6, 11));
      expect(overview.recentResults, hasLength(1));
      expect(overview.recentResults.single.matchId, 'recent-result');
      expect(overview.upcomingFixtures, hasLength(1));
      expect(overview.upcomingFixtures.single.matchId, 'upcoming-fixture');
    },
  );

  test('fetchRankingOverview does not wait for live match feeds', () async {
    var liveFeedRequested = false;
    final client = MockClient((request) async {
      if (request.url.host == 'api.fifa.com' &&
          request.url.path.endsWith('/rankings/')) {
        return http.Response(
          jsonEncode({
            'Results': [
              {
                'IdTeam': '741',
                'IdCountry': 'ARG',
                'ConfederationName': 'CONMEBOL',
                'Rank': 1,
                'PrevRank': 1,
                'DecimalTotalPoints': 2040.71,
                'DecimalPrevPoints': 2040.71,
                'PubDate': '2026-04-03T00:00:00Z',
                'TeamName': [
                  {'Locale': 'en', 'Description': 'Argentina'},
                ],
              },
            ],
          }),
          200,
        );
      }

      if (request.url.host == 'api.fifa.com' &&
          request.url.path.endsWith('/rankingschedules/all')) {
        return http.Response(
          jsonEncode({
            'Results': [
              {
                'OfficialDate': '2026-04-03T00:00:00Z',
                'MatchWindowEndDate': '2026-04-01',
              },
            ],
          }),
          200,
        );
      }

      if (request.url.host == 'inside.fifa.com') {
        return http.Response(
          '"lastUpdateDate":"2026-04-03T00:00:00Z"',
          200,
        );
      }

      if (request.url.host == 'api.fifa.com' &&
          request.url.path.endsWith('/live/football/range')) {
        liveFeedRequested = true;
      }

      return http.Response('Not found', 404);
    });

    final service = FifaWorldOverviewService(client: client);
    final overview = await service.fetchRankingOverview(
      gender: FifaRankingGender.men,
    );

    expect(overview.rankings, hasLength(1));
    expect(overview.leader?.teamName, 'Argentina');
    expect(overview.recentResults, isEmpty);
    expect(overview.upcomingFixtures, isEmpty);
    expect(liveFeedRequested, isFalse);
  });

  test('parseTeamDetail reads FIFA official team profile', () {
    final detail = FifaWorldOverviewService.parseTeamDetail({
      'IdTeam': '43922',
      'IdConfederation': 'CONMEBOL',
      'Name': [
        {'Locale': 'en-GB', 'Description': 'Argentina'},
      ],
      'IdCountry': 'ARG',
      'ShortClubName': 'Argentina',
      'Abbreviation': 'ARG',
      'City': 'BUENOS AIRES',
      'Street': 'Asociacion del Futbol Argentino',
      'FoundationYear': 1893,
      'OfficialSite': 'https://www.afa.com.ar',
      'Stadium': {
        'Name': [
          {'Locale': 'en', 'Description': 'Monumental'},
        ],
      },
    });

    expect(detail, isNotNull);
    expect(detail!.teamId, '43922');
    expect(detail.teamName, 'Argentina');
    expect(detail.countryCode, 'ARG');
    expect(detail.confederationCode, 'CONMEBOL');
    expect(detail.foundationYear, 1893);
    expect(detail.stadiumName, 'Monumental');
    expect(detail.hasTeamProfile, isTrue);
  });

  test('parseKfaMatchOverview keeps senior men Korea matches only', () {
    final overview = FifaWorldOverviewService.parseKfaMatchOverview(
      _kfaMatchHtml,
    );

    expect(overview.upcomingFixtures, hasLength(1));
    expect(
      overview.upcomingFixtures.single.competition,
      '2026 FIFA 북중미 월드컵 조별리그 1차전',
    );
    expect(overview.upcomingFixtures.single.homeTeamName, '대한민국');
    expect(overview.upcomingFixtures.single.awayTeamName, '체코');
    expect(overview.upcomingFixtures.single.dateLabel, '06-12 금요일');
    expect(overview.upcomingFixtures.single.timeLabel, 'AM 11 : 00');
    expect(
      overview.upcomingFixtures.single.status,
      KfaMatchStatus.scheduled,
    );

    expect(overview.recentResults, hasLength(1));
    expect(overview.recentResults.single.competition, '2026 축구 국가대표팀 친선경기');
    expect(overview.recentResults.single.homeTeamName, '대한민국');
    expect(overview.recentResults.single.awayTeamName, '오스트리아');
    expect(overview.recentResults.single.homeScore, 0);
    expect(overview.recentResults.single.awayScore, 1);
    expect(overview.recentResults.single.status, KfaMatchStatus.finished);
  });
}

const String _kfaMatchHtml = '''
<div class="next_match">
  <div class="list">
    <ul class="next_schedule">
      <li onclick="location.href='/live/live.php?act=match_schedule&date_div=next&now_date=2026-05';" style="cursor:pointer;">
        <p class="title">2026 FIFA 북중미 월드컵 조별리그 1차전</p>
        <span class="stadium">멕시코, 과달라하라</span>
        <p class="date"><b>06-12&nbsp;금요일</b><br>AM&nbsp;11&nbsp;:&nbsp;00<br><span></span></p>
        <ul class="country">
          <li><img alt="대한민국" />대한민국</li>
          <li><img alt="체코" />체코</li>
        </ul>
      </li>
      <li onclick="location.href='/live/live.php?act=match_schedule';" style="cursor:pointer;">
        <p class="title">2026 FIFA U-17 월드컵 조별리그 1차전</p>
        <span class="stadium">카타르, 도하</span>
        <p class="date"><b>11-04&nbsp;화요일</b><br>PM&nbsp;10&nbsp;:&nbsp;00</p>
        <ul class="country">
          <li><img alt="대한민국" />대한민국</li>
          <li><img alt="멕시코" />멕시코</li>
        </ul>
      </li>
    </ul>
  </div>
</div>
<!-- match result -->
<div class="match_result" id="main_match_result_view">
  <div class="result_info">
    <p class="result_title">2026 축구 국가대표팀 친선경기</p>
    <span class="stadium_en">오스트리아&nbsp;&nbsp;에른스트 하펠 경기장</span>
    <ul onclick="main_match_result('10483');" style="cursor:pointer;">
      <li><img alt="남자 국가대표팀" />남자 국가대표팀<span>0</span></li>
      <li class="result_win"><img alt="오스트리아" />오스트리아<span class="score_win">1</span></li>
    </ul>
    <em>04-01 수요일</em>
  </div>
  <div class="result_info">
    <p class="result_title">2026 AFC 여자 아시안컵</p>
    <span class="stadium_en">오스트레일리아&nbsp;&nbsp;스타디움 오스트레일리아</span>
    <ul onclick="main_match_result('10443');" style="cursor:pointer;">
      <li><img alt="여자 국가대표팀" />여자 국가대표팀<span>1</span></li>
      <li class="result_win"><img alt="일본" />일본<span class="score_win">4</span></li>
    </ul>
    <em>03-18 수요일</em>
  </div>
  <!-- //반복 -->
</div>
''';

Map<String, dynamic> _match({
  required String matchId,
  required int gender,
  required int period,
  required String competition,
  required String stage,
  required String homeName,
  required String homeCode,
  required String awayName,
  required String awayCode,
  required String date,
  int? homeScore,
  int? awayScore,
  String venue = '',
  String city = '',
  int homeTeamType = 1,
  int awayTeamType = 1,
}) {
  return {
    'IdMatch': matchId,
    'Date': date,
    'Period': period,
    'CompetitionName': [
      {'Locale': 'en', 'Description': competition},
    ],
    'StageName': [
      {'Locale': 'en', 'Description': stage},
    ],
    'Stadium': {
      'Name': [
        {'Locale': 'en', 'Description': venue},
      ],
      'CityName': [
        {'Locale': 'en', 'Description': city},
      ],
    },
    'HomeTeam': _team(
      gender: gender,
      name: homeName,
      countryCode: homeCode,
      score: homeScore,
      teamType: homeTeamType,
    ),
    'AwayTeam': _team(
      gender: gender,
      name: awayName,
      countryCode: awayCode,
      score: awayScore,
      teamType: awayTeamType,
    ),
  };
}

Map<String, dynamic> _team({
  required int gender,
  required String name,
  required String countryCode,
  required int? score,
  required int teamType,
}) {
  return {
    'Gender': gender,
    'TeamType': teamType,
    'AgeType': 7,
    'FootballType': 0,
    'IdCountry': countryCode,
    'Score': score,
    'TeamName': [
      {'Locale': 'en', 'Description': name},
    ],
  };
}
