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
    expect(find.text('전체 경기 캘린더'), findsOneWidget);
    expect(find.text('일정'), findsOneWidget);
    expect(find.text('순위'), findsOneWidget);
    expect(find.text('토너먼트'), findsOneWidget);
    expect(find.text('대회 개요'), findsNothing);
    expect(find.text('결승까지의 흐름'), findsNothing);

    await tester.tap(find.byIcon(Icons.info_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.text('대회 개요'), findsOneWidget);
    expect(find.text('결승까지의 흐름'), findsOneWidget);
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

    await tester.tap(find.text('순위'));
    await tester.pumpAndSettle();

    expect(find.text('조별 순위'), findsOneWidget);
    expect(find.text('조별 팀 구성'), findsOneWidget);
    expect(find.text('A조'), findsWidgets);

    await tester.tap(find.text('토너먼트'));
    await tester.pumpAndSettle();

    expect(find.text('토너먼트 계획'), findsOneWidget);
    expect(find.text('32강'), findsOneWidget);
    expect(find.text('결승'), findsOneWidget);
  });

  testWidgets('interest country editor actions use finite button width', (
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
    expect(find.widgetWithText(FilledButton, '저장'), findsOneWidget);
  });
}
