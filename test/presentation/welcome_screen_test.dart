import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/welcome_screen.dart';

void main() {
  testWidgets('welcome screen swipes through strong mascot slides and starts', (
    WidgetTester tester,
  ) async {
    var started = false;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: WelcomeScreen(onStart: () => started = true),
      ),
    );

    expect(find.byKey(const ValueKey('welcome-page-view')), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/challenge_rinzy_cheer.png',
      ),
      findsOneWidget,
    );
    expect(find.text('린지'), findsNothing);
    expect(find.text('오늘 기록하면, 내일 더 강해져요'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('welcome-next-button')));
    await tester.pumpAndSettle();

    expect(find.text('보석'), findsNothing);
    expect(find.text('작은 기록이 큰 자신감이 돼요'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('welcome-next-button')));
    await tester.pumpAndSettle();

    expect(find.text('불꽃이'), findsNothing);
    expect(find.text('힘든 날에도 멈추지 마세요'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('welcome-start-button')));

    expect(started, isTrue);
  });
}
