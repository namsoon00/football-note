import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:football_note/application/world_cup_schedule.dart';
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
    expect(find.text('Cesar Huerta'), findsOneWidget);
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
    await tester.scrollUntilVisible(
      find.text('메트라이프 스타디움, 뉴욕/뉴저지'),
      180,
      scrollable: scrollable,
    );
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

    await tester.drag(
      find.textContaining(dayFormatter.format(firstDay)).first,
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
