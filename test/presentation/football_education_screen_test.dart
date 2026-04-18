import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/football_education_screen.dart';

void main() {
  testWidgets(
    'football education screen shows a hub layout and expandable story chapters on small displays',
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
      expect(find.text('바로 지도할 수 있는 유소년 축구 컨텐츠'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('education-track-history')),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('education-track-history')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('education-track-lessons')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('education-track-story')),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('education-lessons-section')),
        260,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('터치 수 늘리기'), findsOneWidget);
      expect(find.text('한 번에 한 가지'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('education-story-section')),
        320,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('아빠가 태오에게 들려주는 월드컵 이야기'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('education-book-chapter-0')),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester
          .tap(find.byKey(const ValueKey<String>('education-book-chapter-0')));
      await tester.pumpAndSettle();

      expect(find.text('핵심 연표'), findsOneWidget);
      expect(find.textContaining('1904년 FIFA가 창설되며'), findsOneWidget);
      expect(find.textContaining('우승국 리스트가 아니라'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
