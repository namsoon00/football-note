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

    await _pumpSportStartSelection(
      tester,
      onSelected: (sportId) => selectedSportId = sportId,
    );

    final startButton = find.byKey(
      const ValueKey('startup-sport-start-button'),
    );
    expect(find.text('시작할 종목 선택'), findsOneWidget);
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

  testWidgets('startup sport selection follows the active app theme', (
    WidgetTester tester,
  ) async {
    const startButtonKey = ValueKey('startup-sport-start-button');

    await _pumpSportStartSelection(tester, themeMode: ThemeMode.light);

    expect(
      Theme.of(tester.element(find.byKey(startButtonKey)))
          .colorScheme
          .brightness,
      Brightness.light,
    );

    await _pumpSportStartSelection(tester, themeMode: ThemeMode.dark);

    expect(
      Theme.of(tester.element(find.byKey(startButtonKey)))
          .colorScheme
          .brightness,
      Brightness.dark,
    );
  });
}

Future<void> _pumpSportStartSelection(
  WidgetTester tester, {
  ThemeMode themeMode = ThemeMode.light,
  ValueChanged<String>? onSelected,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: _testTheme(Brightness.light),
      darkTheme: _testTheme(Brightness.dark),
      themeMode: themeMode,
      home: SportStartSelectionScreen(onSelected: onSelected ?? (_) {}),
    ),
  );
  await tester.pumpAndSettle();
}

ThemeData _testTheme(Brightness brightness) {
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: brightness,
    ),
  );
}
