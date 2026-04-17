import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/football_education_screen.dart';

void main() {
  testWidgets(
    'football education screen shows quiz-linked history study cards',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FootballEducationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable);
      expect(find.text('유소년 축구 교육'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('퀴즈 대비 역사'),
        400,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      expect(find.text('퀴즈 대비 역사'), findsOneWidget);
      expect(
        find.textContaining('퀴즈에 자주 나오는 연도, 대회 이름, 상징 장면'),
        findsOneWidget,
      );
      expect(find.text('월드컵 시작점'), findsOneWidget);
      expect(find.textContaining('1930년 첫 FIFA 월드컵은 우루과이'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('대회 이름과 출범'),
        300,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      expect(find.text('대회 이름과 출범'), findsOneWidget);
      expect(find.textContaining('프리미어리그는 1992년에 출범'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('역사 장면과 여자 축구'),
        300,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      expect(find.text('역사 장면과 여자 축구'), findsOneWidget);
      expect(find.textContaining('첫 FIFA 여자 월드컵은 1991년 중국'), findsOneWidget);
    },
  );
}
