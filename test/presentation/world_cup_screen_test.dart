import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/world_cup_screen.dart';
import 'package:football_note/presentation/theme/app_theme.dart';

void main() {
  testWidgets('overview and road to final open from title action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const WorldCupScreen(),
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

    expect(find.text('대회 개요'), findsOneWidget);
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
        home: const WorldCupScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('선택한 국가 경기만 보기'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('선택 국가 경기'), findsNothing);
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
        home: const WorldCupScreen(),
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

  testWidgets('interest country editor opens without layout exception', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const WorldCupScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('국가 편집'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('국가 편집'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
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
        home: const WorldCupScreen(),
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
