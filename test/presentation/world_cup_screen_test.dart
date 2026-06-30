import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:football_note/application/world_cup_live_data_service.dart';
import 'package:football_note/application/world_cup_schedule.dart';
import 'package:football_note/domain/entities/fifa_world_overview.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/world_cup_screen.dart';
import 'package:football_note/presentation/theme/app_theme.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  testWidgets('overview and road to final open from title action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WorldCupScreen(
          refreshOfficialDataOnOpen: false,
          currentTime: DateTime.utc(2026, 6, 20),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('월드컵 보기'), findsOneWidget);
    expect(find.text('설명'), findsOneWidget);
    expect(find.text('FIFA'), findsOneWidget);
    final countrySettingsY = tester.getTopLeft(find.text('내 월드컵 국가')).dy;
    final calendarY = tester.getTopLeft(find.text('전체 경기 캘린더')).dy;
    expect(countrySettingsY, lessThan(calendarY));
    expect(find.text('전체 경기 캘린더'), findsOneWidget);
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('일정'),
      180,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('일정'), findsOneWidget);
    expect(find.text('순위'), findsOneWidget);
    expect(find.text('토너먼트'), findsNothing);
    expect(find.text('대회 개요'), findsNothing);
    expect(find.text('결승까지의 흐름'), findsNothing);

    await tester.tap(find.byIcon(Icons.info_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.text('대회 개요'), findsWidgets);
    expect(find.text('이번 월드컵 진행 방식'), findsOneWidget);
    expect(find.text('VAR과 경기 기술'), findsOneWidget);
    expect(find.text('결승까지의 흐름'), findsOneWidget);
  });

  testWidgets('selected-country filter stays in the calendar flow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WorldCupScreen(
          refreshOfficialDataOnOpen: false,
          currentTime: DateTime.utc(2026, 6, 20),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('선택한 국가 경기만 보기'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('선택 국가 경기'), findsNothing);
  });

  testWidgets('calendar marks interest country fixture count', (tester) async {
    final optionRepository = _MemoryOptionRepository();
    await optionRepository.saveOptions(
      'world_cup_interest_countries_v1',
      const <String>['Korea Republic'],
    );
    final fixture = worldCupFixturesForCountries(const {
      'Korea Republic',
    }).first;
    final day = fixture.localDay;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WorldCupScreen(
          refreshOfficialDataOnOpen: false,
          optionRepository: optionRepository,
          initialSelectedDay: day,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final countBadge = find.byKey(
      ValueKey<String>(
        'world-cup-calendar-day-count-${day.year}-${day.month}-${day.day}',
      ),
    );

    expect(countBadge, findsOneWidget);
    expect(
      find.descendant(of: countBadge, matching: find.text('1')),
      findsOneWidget,
    );
  });

  testWidgets('before knockouts schedule and standings tabs are visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WorldCupScreen(
          refreshOfficialDataOnOpen: false,
          currentTime: DateTime.utc(2026, 6, 20),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('일정'),
      180,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('일정'), findsOneWidget);
    expect(find.text('순위'), findsOneWidget);
    expect(find.text('토너먼트'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('순위'),
      180,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('순위'));
    await tester.pumpAndSettle();

    expect(find.text('조별 순위'), findsOneWidget);
    expect(find.text('조별 순위표'), findsOneWidget);
    expect(find.text('승-무-패'), findsWidgets);
    expect(find.text('득실'), findsWidgets);
    expect(find.text('득점'), findsWidgets);
    expect(find.text('동률 비교: 득실차 +2 · 득점 2'), findsNothing);
    expect(find.text('조별 팀 구성'), findsOneWidget);
    expect(find.text('A조'), findsWidgets);
  });

  testWidgets('after knockouts schedule and tournament tabs are visible', (
    tester,
  ) async {
    final navigatorObserver = _RecordingNavigatorObserver();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        navigatorObservers: [navigatorObserver],
        home: WorldCupScreen(
          refreshOfficialDataOnOpen: false,
          currentTime: DateTime.utc(2026, 6, 29),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('토너먼트'),
      180,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('일정'), findsOneWidget);
    expect(find.text('순위'), findsNothing);
    expect(find.text('토너먼트'), findsOneWidget);

    await tester.tap(find.text('토너먼트'));
    await tester.pumpAndSettle();

    expect(find.text('토너먼트 대진표'), findsOneWidget);
    expect(find.text('결승'), findsOneWidget);
    expect(find.text('3위 결정전'), findsOneWidget);
    expect(find.text('준결승'), findsOneWidget);
    expect(find.text('8강'), findsOneWidget);
    expect(find.text('16강'), findsOneWidget);
    expect(find.text('32강'), findsOneWidget);
    expect(find.text('진출팀 확정 전'), findsWidgets);
    expect(find.text('승자 확정 전'), findsWidgets);
    expect(find.text('A조 2위'), findsNothing);
    expect(find.text('B조 2위'), findsNothing);
    expect(find.text('M73 승자'), findsNothing);
    expect(find.text('M73: A조 2위 대 B조 2위'), findsNothing);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    final thirdPlaceStrip = find.byKey(
      const ValueKey('world-cup-third-place-strip'),
    );
    expect(thirdPlaceStrip, findsNothing);
    final bracketViewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(bracketViewer.minScale, lessThan(1));
    expect(bracketViewer.maxScale, greaterThan(1));
    expect(find.byIcon(Icons.zoom_out_rounded), findsOneWidget);
    expect(find.byIcon(Icons.restart_alt_rounded), findsOneWidget);
    expect(find.byIcon(Icons.zoom_in_rounded), findsOneWidget);
    expect(find.byIcon(Icons.open_in_full_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.zoom_in_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.zoom_out_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.restart_alt_rounded));
    await tester.pumpAndSettle();

    navigatorObserver.reset();
    await tester.tap(find.byIcon(Icons.open_in_full_rounded));
    await tester.pumpAndSettle();

    expect(navigatorObserver.pushedRouteCount, 1);
    expect(find.text('토너먼트 대진표'), findsWidgets);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byIcon(Icons.open_in_full_rounded), findsNothing);
  });

  testWidgets('tournament bracket resolves completed group slots to countries',
      (
    tester,
  ) async {
    final fixtures = _worldCupFixturesWithScores({
      25: (0, 0),
      26: (2, 0),
      27: (2, 0),
      28: (1, 1),
      49: (0, 1),
      50: (0, 0),
      53: (0, 1),
      54: (0, 2),
    });
    final liveDataService = _FakeWorldCupLiveDataService(
      data: WorldCupLiveData(
        fixtures: fixtures,
        officialMatchesByFixtureNumber: const {},
        rankingsByTeam: const {},
        refreshedAt: DateTime.utc(2026, 6, 28, 12),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WorldCupScreen(
          liveDataService: liveDataService,
          initialSelectedDay: worldCupFixtures.first.localDay,
          currentTime: DateTime.utc(2026, 6, 29),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('토너먼트'),
      180,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('토너먼트'));
    await tester.pumpAndSettle();

    expect(find.text('🇲🇽 멕시코'), findsWidgets);
    expect(find.text('🇨🇭 스위스'), findsWidgets);
    expect(find.text('A조 2위 기준 진출'), findsNothing);
    expect(find.text('B조 2위 기준 진출'), findsNothing);
    expect(find.text('M73'), findsNothing);
  });

  testWidgets('tournament bracket uses official round-of-32 countries', (
    tester,
  ) async {
    final fixture = worldCupFixtures.singleWhere(
      (fixture) => fixture.matchNumber == 79,
    );
    final officialMatch = FifaAMatchEntry(
      matchId: 'official-round-of-32',
      matchNumber: fixture.matchNumber,
      gender: FifaRankingGender.men,
      competition: 'FIFA World Cup',
      stage: 'Round of 32',
      venue: fixture.venue,
      city: 'Mexico City',
      kickoffAt: fixture.kickoffUtc,
      homeTeamName: 'Mexico',
      homeCountryCode: 'MEX',
      awayTeamName: 'Germany',
      awayCountryCode: 'GER',
      homeScore: 2,
      awayScore: 1,
      status: FifaAMatchStatus.finished,
    );
    final liveDataService = _FakeWorldCupLiveDataService(
      data: WorldCupLiveData(
        fixtures: worldCupFixtures,
        officialMatchesByFixtureNumber: {fixture.matchNumber: officialMatch},
        rankingsByTeam: const {},
        refreshedAt: DateTime.utc(2026, 7, 1),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WorldCupScreen(
          liveDataService: liveDataService,
          initialSelectedDay: worldCupFixtures.first.localDay,
          currentTime: DateTime.utc(2026, 6, 29),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('토너먼트'),
      180,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('토너먼트'));
    await tester.pumpAndSettle();

    expect(find.text('🇲🇽 멕시코'), findsWidgets);
    expect(find.text('🇩🇪 독일'), findsWidgets);
    expect(find.text('2 : 1', findRichText: true), findsWidgets);
    expect(find.text('승'), findsWidgets);
    expect(find.text('패'), findsWidgets);
    expect(find.text('승자 확정'), findsWidgets);
    expect(find.text('A조 1위 기준 진출'), findsNothing);
    expect(find.text('M79'), findsNothing);
  });

  testWidgets('match list uses bracket-resolved tournament countries', (
    tester,
  ) async {
    final fixtures = _worldCupFixturesWithScores({
      25: (0, 0),
      26: (2, 0),
      27: (2, 0),
      28: (1, 1),
      49: (0, 1),
      50: (0, 0),
      53: (0, 1),
      54: (0, 2),
    });
    final fixture = fixtures.singleWhere(
      (fixture) => fixture.matchNumber == 73,
    );
    final liveDataService = _FakeWorldCupLiveDataService(
      data: WorldCupLiveData(
        fixtures: fixtures,
        officialMatchesByFixtureNumber: const {},
        rankingsByTeam: const {},
        refreshedAt: DateTime.utc(2026, 6, 28, 12),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WorldCupScreen(
          liveDataService: liveDataService,
          initialSelectedDay: fixture.localDay,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    await tester.drag(scrollable, const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(find.text('멕시코'), findsWidgets);
    expect(find.text('스위스'), findsWidgets);
    expect(find.text('2A'), findsNothing);
    expect(find.text('2B'), findsNothing);
  });

  testWidgets('match list uses official round-of-32 countries', (
    tester,
  ) async {
    final fixture = worldCupFixtures.singleWhere(
      (fixture) => fixture.matchNumber == 79,
    );
    final officialMatch = FifaAMatchEntry(
      matchId: 'official-round-of-32-list',
      matchNumber: fixture.matchNumber,
      gender: FifaRankingGender.men,
      competition: 'FIFA World Cup',
      stage: 'Round of 32',
      venue: fixture.venue,
      city: 'Mexico City',
      kickoffAt: fixture.kickoffUtc,
      homeTeamName: 'Mexico',
      homeCountryCode: 'MEX',
      awayTeamName: 'Germany',
      awayCountryCode: 'GER',
      homeScore: null,
      awayScore: null,
      status: FifaAMatchStatus.scheduled,
    );
    final liveDataService = _FakeWorldCupLiveDataService(
      data: WorldCupLiveData(
        fixtures: worldCupFixtures,
        officialMatchesByFixtureNumber: {fixture.matchNumber: officialMatch},
        rankingsByTeam: const {},
        refreshedAt: DateTime.utc(2026, 7, 1),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WorldCupScreen(
          liveDataService: liveDataService,
          initialSelectedDay: fixture.localDay,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('멕시코'),
      220,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();

    expect(find.text('멕시코'), findsWidgets);
    expect(find.text('독일'), findsWidgets);
    expect(find.text('1A'), findsNothing);
    expect(find.text('3C/E/F/H/I'), findsNothing);
  });

  testWidgets('team roster sheet shows expanded squad and club data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WorldCupScreen(
          refreshOfficialDataOnOpen: false,
          currentTime: DateTime.utc(2026, 6, 20),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('순위'),
      180,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('순위'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('조별 순위표'),
      180,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('멕시코').hitTestable().first);
    await tester.pumpAndSettle();

    expect(find.text('멕시코 선수 명단'), findsOneWidget);
    expect(find.text('축구 역사와 설명'), findsNothing);
    expect(find.textContaining('멕시코의 축구사'), findsNothing);
    expect(find.text('국가 경기 정보'), findsOneWidget);
    expect(find.text('현재 승점'), findsOneWidget);
    expect(find.text('상대별 결과'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('32강 경우의 수'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('32강 경우의 수'), findsOneWidget);
    expect(find.textContaining('대한민국전 승'), findsWidgets);
    expect(find.textContaining('각 행은 이 팀의 남은 경기 결과 조합'), findsOneWidget);
    expect(find.textContaining('32강 상대 후보(현재 순위)'), findsWidgets);
    expect(find.textContaining('32강 상대 후보(현재 순위): M'), findsNothing);
    expect(find.textContaining('→'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('골키퍼'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('나의 베스트 11'), findsNothing);
    expect(find.text('포메이션'), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.text('라울 랑헬'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Deportivo Guadalajara'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Deportivo Guadalajara'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('RSC Anderlecht'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('세사르 우에르타'), findsOneWidget);
    expect(find.text('RSC Anderlecht'), findsOneWidget);
  });

  testWidgets('team roster hides round-of-32 scenarios after knockouts start', (
    tester,
  ) async {
    final fixture = worldCupFixtures.singleWhere(
      (fixture) => fixture.matchNumber == 79,
    );
    final officialMatch = FifaAMatchEntry(
      matchId: 'official-round-of-32-roster',
      matchNumber: fixture.matchNumber,
      gender: FifaRankingGender.men,
      competition: 'FIFA World Cup',
      stage: 'Round of 32',
      venue: fixture.venue,
      city: 'Mexico City',
      kickoffAt: fixture.kickoffUtc,
      homeTeamName: 'Mexico',
      homeCountryCode: 'MEX',
      awayTeamName: 'Germany',
      awayCountryCode: 'GER',
      homeScore: null,
      awayScore: null,
      status: FifaAMatchStatus.scheduled,
    );
    final liveDataService = _FakeWorldCupLiveDataService(
      data: WorldCupLiveData(
        fixtures: worldCupFixtures,
        officialMatchesByFixtureNumber: {fixture.matchNumber: officialMatch},
        rankingsByTeam: const {},
        refreshedAt: DateTime.utc(2026, 7, 1),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WorldCupScreen(
          liveDataService: liveDataService,
          initialSelectedDay: fixture.localDay,
          currentTime: DateTime.utc(2026, 6, 29),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('멕시코'),
      220,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('멕시코').hitTestable().first);
    await tester.pumpAndSettle();

    expect(find.text('멕시코 선수 명단'), findsOneWidget);
    expect(find.text('32강 경우의 수'), findsNothing);
  });

  testWidgets('qualification scenarios adapt to one remaining team match', (
    tester,
  ) async {
    final fixtures = _worldCupFixturesWithScores({
      28: (1, 1),
    });
    final liveDataService = _FakeWorldCupLiveDataService(
      data: WorldCupLiveData(
        fixtures: fixtures,
        officialMatchesByFixtureNumber: const {},
        rankingsByTeam: const {},
        refreshedAt: DateTime.utc(2026, 6, 19, 3),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WorldCupScreen(
          liveDataService: liveDataService,
          initialSelectedDay: worldCupFixtures.first.localDay,
          currentTime: DateTime.utc(2026, 6, 20),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('순위'),
      180,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('순위'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('조별 순위표'),
      180,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('대한민국').hitTestable().first);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('32강 경우의 수'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('마지막 1경기'), findsOneWidget);
    expect(find.textContaining('남아프리카공화국전 승'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('다른 경기 결과 9가지').first,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('다른 경기 결과 9가지'), findsWidgets);
    await tester.tap(find.textContaining('다른 경기 결과 9가지').hitTestable().first);
    await tester.pumpAndSettle();
    expect(find.textContaining('체코 - 남아프리카공화국'), findsWidgets);
    expect(find.textContaining('체코 - 멕시코'), findsWidgets);
    expect(find.textContaining('위 ·'), findsWidgets);
    expect(find.text('이 팀 남은 경기 없음'), findsNothing);
  });

  testWidgets('qualification scenarios group waiting other match outcomes', (
    tester,
  ) async {
    final fixtures = _worldCupFixturesWithScores({
      28: (1, 0),
      54: (1, 0),
    });
    final liveDataService = _FakeWorldCupLiveDataService(
      data: WorldCupLiveData(
        fixtures: fixtures,
        officialMatchesByFixtureNumber: const {},
        rankingsByTeam: const {},
        refreshedAt: DateTime.utc(2026, 6, 25, 3),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WorldCupScreen(
          liveDataService: liveDataService,
          initialSelectedDay: worldCupFixtures.first.localDay,
          currentTime: DateTime.utc(2026, 6, 25),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('순위'),
      180,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('순위'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('조별 순위표'),
      180,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('대한민국').hitTestable().first);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('32강 경우의 수'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('기다리는 경기 결과별 경우의 수'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('이 팀 남은 경기 없음'), findsOneWidget);
    expect(find.text('기다리는 경기 결과별 경우의 수'), findsOneWidget);
    expect(find.textContaining('3위 비교로 남는 경우'), findsOneWidget);
    expect(find.textContaining('탈락하는 경우'), findsOneWidget);
    expect(find.textContaining('체코 - 남아프리카공화국'), findsWidgets);
    expect(find.textContaining('체코 - 멕시코'), findsWidgets);
  });

  testWidgets('team match history country opens that team roster', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WorldCupScreen(
          refreshOfficialDataOnOpen: false,
          currentTime: DateTime.utc(2026, 6, 20),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('순위'),
      180,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('순위'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('조별 순위표'),
      180,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('멕시코').hitTestable().first);
    await tester.pumpAndSettle();

    expect(find.text('멕시코 선수 명단'), findsOneWidget);
    expect(find.text('상대별 결과'), findsOneWidget);
    final rosterScroll = find.byType(Scrollable).last;
    await tester.drag(rosterScroll, const Offset(0, -140));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('남아프리카').hitTestable().first);
    await tester.pumpAndSettle();

    expect(find.text('남아프리카공화국 선수 명단').hitTestable(), findsOneWidget);
    expect(find.text('멕시코 선수 명단'), findsNothing);
  });

  testWidgets('Korean roster names render in Korean locale', (tester) async {
    final koreaFixture = worldCupFixtures.firstWhere(
      (fixture) => fixture.involvesCountry('Korea Republic'),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WorldCupScreen(
          refreshOfficialDataOnOpen: false,
          initialSelectedDay: koreaFixture.localDay,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.textContaining('대한민국'),
      180,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('대한민국').hitTestable().first);
    await tester.pumpAndSettle();

    expect(find.text('대한민국 선수 명단'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('손흥민'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('손흥민'), findsOneWidget);
    expect(find.text('Son Heung-min'), findsNothing);
  });

  testWidgets('fixture calendar localizes teams and venue labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WorldCupScreen(
          refreshOfficialDataOnOpen: false,
          initialSelectedDay: worldCupFixtures.first.localDay,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('에스타디오 아스테카, 멕시코시티'),
      180,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('멕시코'), findsWidgets);
    expect(find.textContaining('남아프리카공화국'), findsWidgets);
    expect(find.text('M1'), findsNothing);
    expect(find.text('에스타디오 아스테카, 멕시코시티'), findsOneWidget);
    expect(find.textContaining('Mexico'), findsNothing);
  });

  testWidgets('narrow fixture rows keep teams on the same line', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WorldCupScreen(
          refreshOfficialDataOnOpen: false,
          initialSelectedDay: worldCupFixtures.first.localDay,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    for (var attempt = 0; attempt < 6; attempt += 1) {
      final homeVisible = find.text('멕시코').hitTestable().evaluate().isNotEmpty;
      final awayVisible =
          find.text('남아프리카공화국').hitTestable().evaluate().isNotEmpty;
      if (homeVisible && awayVisible) {
        break;
      }
      await tester.drag(scrollable, const Offset(0, -240));
      await tester.pumpAndSettle();
    }

    final homeTop = tester.getTopLeft(find.text('멕시코').hitTestable().first).dy;
    final awayTop =
        tester.getTopLeft(find.text('남아프리카공화국').hitTestable().first).dy;

    expect((homeTop - awayTop).abs(), lessThan(2));
  });

  testWidgets('fixture team blocks show FIFA ranking and live score', (
    tester,
  ) async {
    final navigatorObserver = _RecordingNavigatorObserver();
    final fixture = worldCupFixtures.first;
    final officialMatch = FifaAMatchEntry(
      matchId: 'live-match',
      matchNumber: fixture.matchNumber,
      gender: FifaRankingGender.men,
      competition: 'FIFA World Cup',
      stage: 'First Stage',
      venue: fixture.venue,
      city: 'Mexico City',
      kickoffAt: fixture.kickoffUtc,
      homeTeamName: fixture.homeTeam,
      homeCountryCode: 'MEX',
      awayTeamName: fixture.awayTeam,
      awayCountryCode: 'RSA',
      homeScore: 1,
      awayScore: 0,
      status: FifaAMatchStatus.live,
    );
    final liveDataService = _FakeWorldCupLiveDataService(
      data: WorldCupLiveData(
        fixtures: worldCupFixtures,
        officialMatchesByFixtureNumber: {fixture.matchNumber: officialMatch},
        rankingsByTeam: {
          fixture.homeTeam: _rankingEntry(fixture.homeTeam, 'MEX', 12),
          fixture.awayTeam: _rankingEntry(fixture.awayTeam, 'RSA', 56),
        },
        refreshedAt: DateTime.utc(2026, 6, 11, 19, 30),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        navigatorObservers: [navigatorObserver],
        home: WorldCupScreen(
          liveDataService: liveDataService,
          initialSelectedDay: fixture.localDay,
          currentTime: fixture.kickoffUtc.add(const Duration(minutes: 30)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('1 : 0'),
      180,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();

    expect(find.text('FIFA 12위'), findsOneWidget);
    expect(find.text('FIFA 56위'), findsOneWidget);
    expect(find.text('진행 중'), findsNothing);
    expect(find.text('1 : 0'), findsOneWidget);

    navigatorObserver.reset();
    final rankingTapTarget = find.ancestor(
      of: find.text('FIFA 12위'),
      matching: find.byType(InkWell),
    );
    await tester.tap(rankingTapTarget.first);
    await tester.pump();

    expect(navigatorObserver.pushedRouteCount, 1);
  });

  testWidgets('finished penalty shootout fixture shows shootout score', (
    tester,
  ) async {
    final fixture = worldCupFixtures.singleWhere(
      (fixture) => fixture.matchNumber == 79,
    );
    final officialMatch = FifaAMatchEntry(
      matchId: 'penalty-match',
      matchNumber: fixture.matchNumber,
      gender: FifaRankingGender.men,
      competition: 'FIFA World Cup',
      stage: 'Round of 32',
      venue: fixture.venue,
      city: 'Mexico City',
      kickoffAt: fixture.kickoffUtc,
      homeTeamName: 'Mexico',
      homeCountryCode: 'MEX',
      awayTeamName: 'Germany',
      awayCountryCode: 'GER',
      homeScore: 1,
      awayScore: 1,
      homePenaltyScore: 4,
      awayPenaltyScore: 3,
      status: FifaAMatchStatus.finished,
    );
    final liveDataService = _FakeWorldCupLiveDataService(
      data: WorldCupLiveData(
        fixtures: worldCupFixtures,
        officialMatchesByFixtureNumber: {fixture.matchNumber: officialMatch},
        refreshedAt: DateTime.utc(2026, 7, 1, 4),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WorldCupScreen(
          liveDataService: liveDataService,
          initialSelectedDay: fixture.localDay,
          currentTime: fixture.kickoffUtc.add(const Duration(hours: 3)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('승부차기 4 : 3'),
      180,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();

    expect(find.text('1 : 1', findRichText: true), findsOneWidget);
    expect(find.text('승부차기 4 : 3'), findsOneWidget);
  });

  testWidgets('finished draw fixture highlights tied score', (tester) async {
    final fixture = worldCupFixtures.firstWhere(
      (fixture) => fixture.hasScore && fixture.homeScore == fixture.awayScore,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WorldCupScreen(
          refreshOfficialDataOnOpen: false,
          initialSelectedDay: fixture.localDay,
          currentTime: fixture.kickoffUtc.add(const Duration(hours: 3)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final score = '${fixture.homeScore} : ${fixture.awayScore}';
    final scrollable = find.byType(Scrollable).first;
    for (var i = 0;
        i < 8 && find.text(score).hitTestable().evaluate().isEmpty;
        i += 1) {
      await tester.drag(scrollable, const Offset(0, -220));
      await tester.pumpAndSettle();
    }

    final scoreText = tester.widget<Text>(find.text(score).hitTestable().first);
    expect(scoreText.style?.color, AppTheme.light().colorScheme.tertiary);
  });

  testWidgets('scheduled fixture hides status beside time', (tester) async {
    final fixture = worldCupFixtures.firstWhere((fixture) => !fixture.hasScore);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WorldCupScreen(
          refreshOfficialDataOnOpen: false,
          initialSelectedDay: fixture.localDay,
          currentTime: fixture.kickoffUtc.subtract(const Duration(days: 1)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    for (var i = 0; i < 6 && find.text('- : -').evaluate().isEmpty; i += 1) {
      await tester.drag(scrollable, const Offset(0, -260));
      await tester.pumpAndSettle();
    }

    final scoreText = find.text('- : -').first;
    expect(scoreText, findsOneWidget);
    await tester.ensureVisible(scoreText);
    await tester.pumpAndSettle();

    expect(find.text('경기 전'), findsNothing);
    expect(find.text('예정'), findsNothing);

    final scoreTapTarget = find.ancestor(
      of: scoreText,
      matching: find.byType(InkWell),
    );
    await tester.tap(scoreTapTarget.first);
    await tester.pumpAndSettle();

    expect(find.text('- : -'), findsWidgets);
    expect(find.text('경기 전'), findsNothing);
    expect(find.text('예정'), findsNothing);
  });

  testWidgets(
      'match detail localizes lineup players and shows club without image', (
    tester,
  ) async {
    final fixture = worldCupFixtures.firstWhere(
      (fixture) => fixture.involvesCountry('Korea Republic'),
    );
    final officialMatch = FifaAMatchEntry(
      matchId: 'korea-detail-match',
      matchNumber: fixture.matchNumber,
      gender: FifaRankingGender.men,
      competition: 'FIFA World Cup',
      stage: 'First Stage',
      venue: fixture.venue,
      city: 'Guadalajara',
      kickoffAt: fixture.kickoffUtc,
      homeTeamName: fixture.homeTeam,
      homeCountryCode: 'KOR',
      awayTeamName: fixture.awayTeam,
      awayCountryCode: 'CZE',
      homeScore: 2,
      awayScore: 1,
      status: FifaAMatchStatus.finished,
    );
    final liveDataService = _FakeWorldCupLiveDataService(
      data: WorldCupLiveData(
        fixtures: worldCupFixtures,
        officialMatchesByFixtureNumber: {fixture.matchNumber: officialMatch},
        refreshedAt: DateTime.utc(2026, 6, 12, 4),
      ),
      detail: FifaAMatchDetail(
        match: officialMatch,
        homeScorers: const <FifaMatchScorer>[],
        awayScorers: const <FifaMatchScorer>[],
        homePlayers: const [
          FifaMatchPlayer(
            playerId: '307849',
            playerName: '손흥민',
            fullName: '손흥민',
            shirtNumber: 7,
            position: FifaMatchPlayerPosition.forward,
            isStarting: true,
            isCaptain: true,
            pictureUrl: '',
          ),
        ],
        awayPlayers: const <FifaMatchPlayer>[],
        homeTactics: '4-3-3',
        awayTactics: '',
        homePossession: null,
        awayPossession: null,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WorldCupScreen(
          liveDataService: liveDataService,
          initialSelectedDay: fixture.localDay,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    final scoreFinder = find.text('2 : 1', findRichText: true);
    await tester.scrollUntilVisible(
      scoreFinder,
      180,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();

    final scoreTapTarget = find.ancestor(
      of: scoreFinder.first,
      matching: find.byType(InkWell),
    );
    await tester.tap(scoreTapTarget.first);
    await tester.pumpAndSettle();

    expect(liveDataService.lastDetailLanguage, 'ko');
    expect(find.text('출전 명단'), findsOneWidget);
    expect(find.textContaining('손흥민'), findsWidgets);
    expect(find.text('Los Angeles FC'), findsOneWidget);
    expect(find.byIcon(Icons.face_rounded), findsNothing);
    expect(find.textContaining('공식 사진'), findsNothing);
  });

  testWidgets('fixture calendar localizes month and weekday labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WorldCupScreen(
          refreshOfficialDataOnOpen: false,
          initialSelectedDay: worldCupFixtures.first.localDay,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2026년 6월'), findsOneWidget);
    expect(find.text('월'), findsWidgets);
    expect(find.text('June 2026'), findsNothing);
    expect(find.text('Mon'), findsNothing);
  });

  testWidgets('past unscored fixtures hide result update copy', (tester) async {
    final fixture = worldCupFixtures.firstWhere((fixture) => !fixture.hasScore);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WorldCupScreen(
          refreshOfficialDataOnOpen: false,
          initialSelectedDay: fixture.localDay,
          currentTime: fixture.kickoffUtc.add(const Duration(hours: 3)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.textContaining('가나'), 180,
        scrollable: scrollable);
    await tester.pumpAndSettle();

    expect(find.text('- : -'), findsWidgets);
    expect(find.text('결과 갱신 대기'), findsNothing);
    expect(find.textContaining('FIFA 공식 결과가 아직 반영되지 않았어요'), findsNothing);
  });

  testWidgets('swiping match list moves selected date', (tester) async {
    final firstDay = worldCupFixtures.first.localDay;
    final nextDay = firstDay.add(const Duration(days: 1));
    final dayFormatter = DateFormat.yMMMd('ko-KR');

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WorldCupScreen(
          refreshOfficialDataOnOpen: false,
          initialSelectedDay: firstDay,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    await tester.drag(scrollable, const Offset(0, -720));
    await tester.pumpAndSettle();

    expect(find.textContaining(dayFormatter.format(firstDay)), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('world-cup-day-match-pager')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('world-cup-day-match-pager')),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
    expect(
      find.textContaining(
        dayFormatter.format(nextDay),
        skipOffstage: false,
      ),
      findsWidgets,
    );

    await tester.drag(
      find.byKey(const ValueKey<String>('world-cup-day-match-pager')),
      const Offset(-260, 0),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining(dayFormatter.format(nextDay)), findsOneWidget);
  });

  testWidgets('match list height fits selected day fixture count', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sortedDays = worldCupFixtures
        .map((fixture) => fixture.localDay)
        .toSet()
        .toList()
      ..sort();
    DateTime? selectedDay;
    DateTime? largerNeighborDay;
    Offset? swipeOffset;
    for (var index = 0; index < sortedDays.length; index += 1) {
      final day = sortedDays[index];
      final matchCount = worldCupFixturesForDay(day).length;
      if (index > 0 &&
          worldCupFixturesForDay(sortedDays[index - 1]).length > matchCount) {
        selectedDay = day;
        largerNeighborDay = sortedDays[index - 1];
        swipeOffset = const Offset(700, 0);
        break;
      }
      if (index < sortedDays.length - 1 &&
          worldCupFixturesForDay(sortedDays[index + 1]).length > matchCount) {
        selectedDay = day;
        largerNeighborDay = sortedDays[index + 1];
        swipeOffset = const Offset(-700, 0);
        break;
      }
    }
    expect(selectedDay, isNotNull);
    expect(largerNeighborDay, isNotNull);
    expect(swipeOffset, isNotNull);
    final selectedFixtureDay = selectedDay!;
    final targetDay = largerNeighborDay!;
    final pageSwipeOffset = swipeOffset!;
    final dayFormatter = DateFormat.yMMMd('ko-KR');

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WorldCupScreen(
          refreshOfficialDataOnOpen: false,
          initialSelectedDay: selectedFixtureDay,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final pager = find.byKey(
      const ValueKey<String>('world-cup-day-match-pager'),
    );
    final scrollable = find.byType(Scrollable).first;
    for (var i = 0; i < 4 && pager.evaluate().isEmpty; i += 1) {
      await tester.drag(scrollable, const Offset(0, -260));
      await tester.pumpAndSettle();
    }

    expect(pager, findsOneWidget);
    expect(
      find.textContaining(dayFormatter.format(selectedFixtureDay)),
      findsOneWidget,
    );
    final selectedHeight = tester.getSize(pager).height;

    await tester.drag(pager, pageSwipeOffset);
    await tester.pumpAndSettle();

    expect(find.textContaining(dayFormatter.format(targetDay)), findsOneWidget);
    final targetHeight = tester.getSize(pager).height;
    expect(targetHeight, greaterThan(selectedHeight));

    await tester.drag(
      pager,
      Offset(-pageSwipeOffset.dx, -pageSwipeOffset.dy),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining(dayFormatter.format(selectedFixtureDay)),
      findsOneWidget,
    );
    expect(tester.getSize(pager).height, lessThan(targetHeight));
    expect(tester.getSize(pager).height, closeTo(selectedHeight, 2));
  });

  testWidgets('interest country editor opens without layout exception', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const WorldCupScreen(refreshOfficialDataOnOpen: false),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('국가 편집'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('국가 편집'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(
      find.byKey(const ValueKey('world-cup-country-editor-top-actions')),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('world-cup-country-editor-bottom-actions')),
      320,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('world-cup-country-editor-bottom-actions')),
      findsOneWidget,
    );
  });

  testWidgets('interest country editor saves on country tap', (tester) async {
    final optionRepository = _MemoryOptionRepository();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WorldCupScreen(
          refreshOfficialDataOnOpen: false,
          optionRepository: optionRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('국가 편집'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('국가 편집'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('알제리').first);
    await tester.pumpAndSettle();

    expect(
      optionRepository.getOptions(
        'world_cup_interest_countries_v1',
        const <String>[],
      ),
      contains('Algeria'),
    );
  });

  testWidgets('interest country editor dismisses when dragged down', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const WorldCupScreen(refreshOfficialDataOnOpen: false),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('국가 편집'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('국가 편집'));
    await tester.pumpAndSettle();

    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsWidgets);

    await tester.drag(
      find.byType(DraggableScrollableSheet),
      const Offset(0, 900),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CheckboxListTile), findsNothing);
  });
}

class _FakeWorldCupLiveDataService extends WorldCupLiveDataService {
  final WorldCupLiveData data;
  final FifaAMatchDetail? detail;
  String lastDetailLanguage = '';

  _FakeWorldCupLiveDataService({required this.data, this.detail});

  @override
  Future<WorldCupLiveData> fetchLatest({
    List<WorldCupFixture> baseFixtures = worldCupFixtures,
    DateTime? now,
  }) async {
    return data;
  }

  @override
  Future<FifaAMatchDetail?> fetchMatchDetail(
    FifaAMatchEntry match, {
    String language = 'en',
  }) async {
    lastDetailLanguage = language;
    return detail;
  }

  @override
  void dispose() {}
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  int pushedRouteCount = 0;

  void reset() {
    pushedRouteCount = 0;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRouteCount += 1;
    super.didPush(route, previousRoute);
  }
}

FifaRankingEntry _rankingEntry(String teamName, String countryCode, int rank) {
  return FifaRankingEntry(
    teamId: '$countryCode-team',
    teamName: teamName,
    countryCode: countryCode,
    confederation: 'TEST',
    rank: rank,
    previousRank: rank,
    points: 1600,
    previousPoints: 1600,
    publishedAt: null,
  );
}

List<WorldCupFixture> _worldCupFixturesWithScores(
  Map<int, (int, int)> scoresByMatch,
) {
  return [
    for (final fixture in worldCupFixtures)
      if (scoresByMatch[fixture.matchNumber] case final score?)
        fixture.copyWithScore(homeScore: score.$1, awayScore: score.$2)
      else
        fixture,
  ];
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return defaults;
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    if (value is List) {
      return value.whereType<int>().toList();
    }
    return defaults;
  }

  @override
  T? getValue<T>(String key) {
    final value = _values[key];
    return value is T ? value : null;
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    _values[key] = value;
  }

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    _values[key] = List<dynamic>.from(options);
  }
}
