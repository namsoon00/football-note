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
        home: const WorldCupScreen(refreshOfficialDataOnOpen: false),
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
    expect(find.text('토너먼트'), findsOneWidget);
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
        home: const WorldCupScreen(refreshOfficialDataOnOpen: false),
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

  testWidgets('standings and tournament views show structured plan cards', (
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

    final scrollable = find.byType(Scrollable).first;
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
    expect(find.text('조별 팀 구성'), findsOneWidget);
    expect(find.text('A조'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('토너먼트'),
      180,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('토너먼트'));
    await tester.pumpAndSettle();

    expect(find.text('토너먼트 대진표'), findsOneWidget);
    expect(find.text('32강'), findsOneWidget);
    expect(find.text('A조 2위'), findsOneWidget);
    expect(find.text('B조 2위'), findsOneWidget);
    expect(find.text('M73 승자'), findsOneWidget);
    expect(find.text('M73: A조 2위 대 B조 2위'), findsOneWidget);
    expect(find.text('결승'), findsOneWidget);
  });

  testWidgets('team roster sheet shows expanded squad and formation data', (
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
    expect(find.text('4-3-3 포메이션'), findsOneWidget);
    expect(find.text('Raul Rangel'), findsOneWidget);
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
    expect(find.text('Cesar Huerta'), findsOneWidget);
    expect(find.text('RSC Anderlecht'), findsOneWidget);
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
      final homeVisible =
          find.text('🇲🇽 멕시코').hitTestable().evaluate().isNotEmpty;
      final awayVisible =
          find.text('🇿🇦 남아프리카공화국').hitTestable().evaluate().isNotEmpty;
      if (homeVisible && awayVisible) {
        break;
      }
      await tester.drag(scrollable, const Offset(0, -240));
      await tester.pumpAndSettle();
    }

    final homeTop =
        tester.getTopLeft(find.text('🇲🇽 멕시코').hitTestable().first).dy;
    final awayTop =
        tester.getTopLeft(find.text('🇿🇦 남아프리카공화국').hitTestable().first).dy;

    expect((homeTop - awayTop).abs(), lessThan(2));
  });

  testWidgets('fixture team blocks show FIFA ranking and keep live status', (
    tester,
  ) async {
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
    expect(find.text('진행 중'), findsWidgets);
    expect(find.text('1 : 0'), findsOneWidget);
  });

  testWidgets('match detail localizes lineup players and shows club and image',
      (
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
            pictureUrl: 'https://example.com/son.png',
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
    await tester.scrollUntilVisible(
      find.text('2 : 1'),
      180,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('2 : 1').hitTestable().first);
    await tester.pumpAndSettle();

    expect(liveDataService.lastDetailLanguage, 'ko');
    expect(find.text('출전 명단'), findsOneWidget);
    expect(find.textContaining('손흥민'), findsWidgets);
    expect(find.text('Los Angeles FC'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
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

  testWidgets('past unscored fixtures wait for result update', (tester) async {
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

    expect(find.text('결과 갱신 대기'), findsWidgets);
    expect(find.textContaining('FIFA 공식 결과가 아직 반영되지 않았어요'), findsWidgets);
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
