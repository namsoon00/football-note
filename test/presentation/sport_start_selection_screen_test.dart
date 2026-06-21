import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/entities/sport_definition.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/sport_start_selection_screen.dart';

void main() {
  testWidgets('startup sport selection requires a sport before continuing', (
    WidgetTester tester,
  ) async {
    String? selectedSportId;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SportStartSelectionScreen(
          onSelected: (sportId) => selectedSportId = sportId,
        ),
      ),
    );

    final startButton = find.byKey(
      const ValueKey('startup-sport-start-button'),
    );
    expect(find.text('먼저 사용할 종목을 골라요'), findsOneWidget);
    expect(find.text('축구'), findsOneWidget);
    expect(find.text('야구'), findsOneWidget);
    expect(find.text('농구'), findsOneWidget);
    expect(find.text('테니스'), findsOneWidget);
    expect(tester.widget<FilledButton>(startButton).enabled, isFalse);

    await tester.tap(
      find.byKey(
        const ValueKey('startup-sport-choice-basketball'),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<FilledButton>(startButton).enabled, isTrue);

    await tester.tap(startButton);
    await tester.pump();

    expect(selectedSportId, SportCatalog.basketballId);
  });
}
