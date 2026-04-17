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
      expect(find.text('태오의 월드컵 역사책'), findsOneWidget);
      expect(find.text('핵심 연표'), findsNothing);
      expect(find.text('기억할 데이터'), findsNothing);
      expect(find.text('이전 장'), findsNothing);
      expect(find.text('다음 장'), findsNothing);

      await tester.drag(
        find.byKey(const ValueKey<String>('education-page-scroll-0')),
        const Offset(0, -700),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('그 방들의 문손잡이를 하나씩 만져 보기로 한다'), findsOneWidget);

      await tester.drag(
        find.byKey(const ValueKey<String>('education-book-page-view')),
        const Offset(-350, 0),
      );
      await tester.pumpAndSettle();

      expect(find.text('배를 타고 도착한 첫 번째 여름'), findsNWidgets(2));
      expect(
        find.textContaining('유럽 팀들은 몇 주씩 바다를 건너 우루과이로 향했고'),
        findsOneWidget,
      );

      await tester.drag(
        find.byKey(const ValueKey<String>('education-page-scroll-1')),
        const Offset(0, -900),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('물비린내와 연설문과 불안한 박수 소리로 기억해 두기로 한다'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
