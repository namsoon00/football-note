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
        find.textContaining(
          '1930, 1950, 1958, 1970, 1986, 1998, 2002, 2010, 2018, 2022, 2026',
        ),
        findsOneWidget,
      );

      await tester.drag(
        find.byKey(const ValueKey<String>('education-page-scroll-0')),
        const Offset(0, -700),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('가장 최근 완료 대회인 2022와 다음 장의 문 앞에 선 2026'),
        findsOneWidget,
      );

      await tester.drag(
        find.byKey(const ValueKey<String>('education-book-page-view')),
        const Offset(-350, 0),
      );
      await tester.pumpAndSettle();

      expect(find.text('바다를 건너 시작된 첫 세 번의 월드컵'), findsNWidgets(2));
      expect(find.textContaining('유럽 팀들이 몇 주씩 항해해 우루과이로 향했고'), findsOneWidget);

      await tester.drag(
        find.byKey(const ValueKey<String>('education-page-scroll-1')),
        const Offset(0, -900),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('세계정치와 이동 기술이 함께 만든 무대였습니다.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
