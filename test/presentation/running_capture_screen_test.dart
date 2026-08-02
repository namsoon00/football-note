import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/running_capture_screen.dart';

void main() {
  test('allows a 60-second recording by default', () {
    const screen = RunningCaptureScreen();

    expect(screen.maximumDuration, const Duration(seconds: 60));
  });

  testWidgets('shows a recoverable state when no camera is available', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: RunningCaptureScreen(cameraProvider: () async => []),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No camera is available.'), findsOneWidget);
    expect(find.text('Open camera again'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
