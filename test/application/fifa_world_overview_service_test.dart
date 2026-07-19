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

  test('parseRankingEntries accepts live FIFA ranking fields', () {
    final entries = FifaWorldOverviewService.parseRankingEntries({
      'Results': [
        {
          'IdTeam': '43822',
          'IdCountry': 'KOR',
          'ConfederationName': 'AFC',
          'Rank': 21,
          'PrevRank': 25,
          'TotalPoints': 1612.547459,
          'PrevPoints': 1591.630886,
          'TeamName': [
            {'Locale': 'en-GB', 'Description': 'Korea Republic'},
          ],
        },
      ],
    });

    expect(entries, hasLength(1));
    expect(entries.single.teamName, 'Korea Republic');
    expect(entries.single.rank, 21);
    expect(entries.single.previousRank, 25);
    expect(entries.single.rankMovement, 4);
    expect(entries.single.points, closeTo(1612.547459, 0.000001));
    expect(entries.single.previousPoints, closeTo(1591.630886, 0.000001));
    expect(entries.single.publishedAt, isNull);
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

  test('parseNationalMatches treats numeric FIFA live status as live', () {
    final matches = FifaWorldOverviewService.parseNationalMatches([
      _match(
        matchId: 'live-score',
        gender: 1,
        period: 0,
        matchStatus: 3,
        competition: 'FIFA World Cup',
        stage: 'First Stage',
        homeName: 'England',
        homeCode: 'ENG',
        awayName: 'Croatia',
        awayCode: 'CRO',
        date: '2026-06-17T20:00:00Z',
        homeScore: 3,
        awayScore: 2,
      ),
    ], gender: FifaRankingGender.men);

    expect(matches, hasLength(1));
    expect(matches.single.hasScore, isTrue);
    expect(matches.single.status, FifaAMatchStatus.live);
  });

  test('parseFifaMatchDetail extracts scorers assists and possession', () {
    final raw = _match(
      matchId: 'detail-match',
      gender: 1,
      period: 10,
      competition: 'International Friendly',
      stage: 'Final',
      homeName: 'Korea Republic',
      homeCode: 'KOR',
      awayName: 'Japan',
      awayCode: 'JPN',
      date: '2026-04-01T11:00:00Z',
      homeScore: 2,
      awayScore: 1,
    );
    final homeTeam = raw['HomeTeam'] as Map<String, dynamic>;
    final awayTeam = raw['AwayTeam'] as Map<String, dynamic>;
    homeTeam['Players'] = [
      {
        'IdPlayer': 'home-9',
        'ShirtNumber': 7,
        'Status': 1,
        'Captain': true,
        'Position': 3,
        'ShortName': [
          {'Locale': 'en-gb', 'Description': 'S. Son'},
        ],
        'PlayerName': [
          {'Locale': 'en-gb', 'Description': 'Son Heungmin'},
        ],
        'PlayerPicture': {'PictureUrl': 'https://example.com/son.png'},
      },
      {
        'IdPlayer': 'home-18',
        'ShirtNumber': 18,
        'Status': 1,
        'Captain': false,
        'Position': 2,
        'ShortName': [
          {'Locale': 'en-gb', 'Description': 'K. Lee'},
        ],
        'PlayerName': [
          {'Locale': 'en-gb', 'Description': 'Lee Kang-in'},
        ],
      },
    ];
    homeTeam['Goals'] = [
      {'IdPlayer': 'home-9', 'IdAssistPlayer': 'home-18', 'Minute': "21'"},
      {'IdPlayer': 'home-9', 'Minute': "64'"},
    ];
    homeTeam['Bookings'] = [
      {'IdPlayer': 'home-18', 'Minute': "33'", 'Card': 1},
      {'IdPlayer': 'home-9', 'Minute': "88'", 'Card': 2},
      {'IdPlayer': 'home-18', 'Minute': "90'+4'", 'Card': 3},
    ];
    awayTeam['Players'] = [
      {
        'IdPlayer': 'away-10',
        'ShirtNumber': 20,
        'Status': 2,
        'Captain': false,
        'Position': 2,
        'ShortName': [
          {'Locale': 'en-gb', 'Description': 'T. Kubo'},
        ],
      },
    ];
    awayTeam['Goals'] = [
      {'IdPlayer': 'away-10', 'Minute': "77'"},
    ];
    awayTeam['Bookings'] = [
      {'IdPlayer': 'away-10', 'Minute': "80'", 'Card': 1},
    ];
    raw['BallPossession'] = {'OverallHome': 58.2, 'OverallAway': 41.8};

    final fallback = FifaWorldOverviewService.parseNationalMatches([
      raw,
    ], gender: FifaRankingGender.men)
        .single;
    final detail = FifaWorldOverviewService.parseFifaMatchDetail(
      raw,
      fallback: fallback,
    );

    expect(detail, isNotNull);
    expect(detail!.homeScorers, hasLength(2));
    expect(detail.homeScorers.first.playerName, 'S. Son');
    expect(detail.homeScorers.first.minute, "21'");
    expect(detail.homeAssists, hasLength(1));
    expect(detail.homeAssists.single.playerName, 'K. Lee');
    expect(detail.homeAssists.single.minute, "21'");
    expect(detail.homeBookings, hasLength(3));
    expect(detail.homeBookings.first.playerName, 'K. Lee');
    expect(detail.homeBookings.first.minute, "33'");
    expect(detail.homeBookings.first.cardType, FifaMatchCardType.yellow);
    expect(detail.homeBookings[1].playerName, 'S. Son');
    expect(detail.homeBookings[1].cardType, FifaMatchCardType.red);
    expect(detail.homeBookings.last.playerName, 'K. Lee');
    expect(detail.homeBookings.last.cardType, FifaMatchCardType.red);
    expect(detail.awayAssists, isEmpty);
    expect(detail.awayScorers.single.playerName, 'T. Kubo');
    expect(detail.awayBookings.single.playerName, 'T. Kubo');
    expect(detail.awayBookings.single.cardType, FifaMatchCardType.yellow);
    final homeScorer = detail.homePlayers.firstWhere(
      (player) => player.playerName == 'S. Son',
    );
    expect(homeScorer.fullName, 'Son Heungmin');
    expect(homeScorer.pictureUrl, 'https://example.com/son.png');
    expect(homeScorer.shirtNumber, 7);
    expect(homeScorer.isStarting, isTrue);
    expect(homeScorer.isCaptain, isTrue);
    expect(homeScorer.position, FifaMatchPlayerPosition.forward);
    expect(
      detail.awayPlayers.single.position,
      FifaMatchPlayerPosition.midfielder,
    );
    expect(detail.homePossession, 58.2);
    expect(detail.awayPossession, 41.8);
  });

  test(
    'fetchOverview combines ranking page, schedules, and worldwide A-matches',
    () async {
      final liveRanges = <Map<String, String>>[];
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
          liveRanges.add(request.url.queryParameters);
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
      expect(
        liveRanges,
        contains(
          predicate<Map<String, String>>(
            (range) =>
                range['from'] == '2026-04-17T23:59:59Z' &&
                range['to'] == '2026-04-23T23:59:59Z',
          ),
        ),
      );
      expect(
        liveRanges,
        contains(
          predicate<Map<String, String>>(
            (range) =>
                range['from'] == '2026-04-23T00:00:00Z' &&
                range['to'] == '2026-04-29T23:59:59Z',
          ),
        ),
      );
      expect(
        liveRanges.any((range) => range['to'] == '2026-06-11T00:00:00Z'),
        isFalse,
      );
    },
  );

  test('fetchRankingOverview prefers the official live ranking feed', () async {
    var scheduleRequested = false;
    var metadataRequested = false;
    var liveRankingRequested = false;
    var scheduledRankingRequested = false;
    final client = MockClient((request) async {
      if (request.url.host == 'api.fifa.com' &&
          request.url.path.endsWith('/fifarankings/rankings/live')) {
        liveRankingRequested = true;
        return http.Response(
          jsonEncode({
            'Results': [
              {
                'IdTeam': '43822',
                'IdCountry': 'KOR',
                'ConfederationName': 'AFC',
                'Rank': 21,
                'PrevRank': 25,
                'TotalPoints': 1612.547459,
                'PrevPoints': 1591.630886,
                'TeamName': [
                  {'Locale': 'en', 'Description': 'Korea Republic'},
                ],
              },
            ],
          }),
          200,
        );
      }

      if (request.url.host == 'api.fifa.com' &&
          request.url.path.endsWith('/rankings/')) {
        scheduledRankingRequested = true;
        return http.Response('Unexpected scheduled ranking request', 500);
      }

      if (request.url.host == 'api.fifa.com' &&
          request.url.path.endsWith('/rankingschedules/all')) {
        scheduleRequested = true;
        return http.Response(
          jsonEncode({
            'Results': [
              {
                'IdRankingSchedule': 'id15136',
                'OfficialDate': '2026-06-11T00:00:00Z',
                'VisibilityDate': '2026-06-11T10:00:00Z',
                'MatchWindowEndDate': '2026-06-10',
              },
            ],
          }),
          200,
        );
      }

      if (request.url.host == 'inside.fifa.com') {
        metadataRequested = true;
        return http.Response(
          '''
          "lastUpdateDate":"2026-06-11T10:00:59.636Z",
          "nextUpdateDate":"2026-07-20T00:00:00.000Z"
          ''',
          200,
        );
      }

      return http.Response('Not found', 404);
    });

    final service = FifaWorldOverviewService(client: client);
    final overview = await service.fetchRankingOverview(
      gender: FifaRankingGender.men,
    );

    expect(overview.rankings, hasLength(1));
    expect(overview.rankings.single.teamName, 'Korea Republic');
    expect(overview.rankings.single.rank, 21);
    expect(overview.rankings.single.rankMovement, 4);
    expect(overview.lastUpdatedAt, DateTime.utc(2026, 6, 11, 10, 0, 59, 636));
    expect(overview.nextUpdatedAt, DateTime.utc(2026, 7, 20));
    expect(scheduleRequested, isTrue);
    expect(metadataRequested, isTrue);
    expect(liveRankingRequested, isTrue);
    expect(scheduledRankingRequested, isFalse);
  });

  test('fetchRankingOverview falls back to the latest official schedule',
      () async {
    var scheduleRequested = false;
    var metadataRequested = false;
    var liveRankingRequested = false;
    var liveFeedRequested = false;
    String? requestedScheduleId;
    final client = MockClient((request) async {
      if (request.url.host == 'api.fifa.com' &&
          request.url.path.endsWith('/fifarankings/rankings/live')) {
        liveRankingRequested = true;
        return http.Response('Unavailable', 503);
      }

      if (request.url.host == 'api.fifa.com' &&
          request.url.path.endsWith('/rankings/')) {
        requestedScheduleId = request.url.queryParameters['idSchedule'];
        return http.Response(
          jsonEncode({
            'Results': [
              {
                'IdTeam': '741',
                'IdCountry': 'ARG',
                'ConfederationName': 'CONMEBOL',
                'Rank': 1,
                'PrevRank': 3,
                'DecimalTotalPoints': 1877.27,
                'DecimalPrevPoints': 1874.81,
                'PubDate': '2026-06-11T10:00:00Z',
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
        scheduleRequested = true;
        return http.Response(
          jsonEncode({
            'Results': [
              {
                'IdRankingSchedule': 'id15136',
                'OfficialDate': '2026-06-11T00:00:00Z',
                'VisibilityDate': '2026-06-11T10:00:00Z',
                'MatchWindowEndDate': '2026-06-10',
              },
              {
                'IdRankingSchedule': 'id15065',
                'OfficialDate': '2026-04-01T00:00:00Z',
                'VisibilityDate': '2026-04-01T13:00:00Z',
                'MatchWindowEndDate': '2026-03-31',
              },
            ],
          }),
          200,
        );
      }

      if (request.url.host == 'inside.fifa.com') {
        metadataRequested = true;
        return http.Response(
          '''
          "lastUpdateDate":"2026-06-11T10:00:59.636Z",
          "nextUpdateDate":"2026-07-20T00:00:00.000Z"
          ''',
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
    expect(overview.lastUpdatedAt, DateTime.utc(2026, 6, 11, 10, 0, 59, 636));
    expect(overview.nextUpdatedAt, DateTime.utc(2026, 7, 20));
    expect(overview.recentResults, isEmpty);
    expect(overview.upcomingFixtures, isEmpty);
    expect(scheduleRequested, isTrue);
    expect(metadataRequested, isTrue);
    expect(liveRankingRequested, isTrue);
    expect(requestedScheduleId, 'id15136');
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
    expect(overview.upcomingFixtures.single.status, KfaMatchStatus.scheduled);

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
  int? matchStatus,
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
    if (matchStatus != null) 'MatchStatus': matchStatus,
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
