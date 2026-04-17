import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/football_education_screen.dart';

void main() {
  testWidgets(
    'football education screen keeps long history pages scrollable on small displays',
    (tester) async {
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      await tester.binding.setSurfaceSize(const Size(390, 640));

      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FootballEducationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('태오의 축구 역사책'), findsOneWidget);
      expect(
        find.text(
          '공놀이의 뿌리, 규칙의 탄생, 월드컵과 클럽 축구, 전술 혁신, 여자 축구, 한국과 아시아의 흐름까지 길게 읽는 책 형식의 교육 화면입니다.',
        ),
        findsNothing,
      );

      await tester.drag(
        find.byKey(const ValueKey<String>('education-page-scroll-0')),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('1863년, 1904년, 1930년, 1991년, 2002년, 2018년'),
        findsOneWidget,
      );

      await tester.drag(
        find.byKey(const ValueKey<String>('education-page-scroll-0')),
        const Offset(0, -700),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('1863년부터 2018년까지 이어지는 기준 연도'), findsOneWidget);

      await tester.drag(
        find.byKey(const ValueKey<String>('education-book-page-view')),
        const Offset(-350, 0),
      );
      await tester.pumpAndSettle();

      expect(find.text('공놀이의 뿌리와 규칙의 탄생'), findsNWidgets(2));
      expect(
        find.textContaining('1848년 케임브리지 규칙, 1863년 축구협회 규칙'),
        findsOneWidget,
      );

      await tester.drag(
        find.byKey(const ValueKey<String>('education-page-scroll-1')),
        const Offset(0, -900),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('1848년과 1863년, 1871년과 1872년'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
