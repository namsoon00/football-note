import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/football_education_screen.dart';

void main() {
  testWidgets(
    'football education screen keeps the long father-to-son story scrollable on small displays',
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
      expect(find.text('아빠가 태오에게 들려주는 월드컵 이야기'), findsOneWidget);
      expect(find.text('이전 장'), findsNothing);
      expect(find.text('다음 장'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('education-book-page-view')),
        findsNothing,
      );
      expect(
        find.textContaining('책장을 열었다 닫았다 하는 식보다 한 번에 길게 읽을 수 있게'),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.text('2026 이후, 아직 안 열린 페이지를 읽는 방법'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('48개국, 104경기, 세 나라 공동 개최라는 조건만으로도'),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.textContaining('1930년의 첫 항해부터 2026년의 다음 질문까지'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('숫자보다 사람을, 결과보다 공기를, 한 경기보다 한 시대를'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
