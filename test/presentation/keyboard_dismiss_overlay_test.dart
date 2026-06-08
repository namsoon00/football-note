import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/widgets/keyboard_dismiss_overlay.dart';

void main() {
  testWidgets('builds from MaterialApp builder without overlay ancestor', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => KeyboardDismissOverlay(
          child: child ?? const SizedBox.shrink(),
        ),
        home: const Scaffold(body: Text('home')),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('home'), findsOneWidget);
  });
}
