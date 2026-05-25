import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/running_coach_screen.dart';

void main() {
  testWidgets('sample sheet shows framed runner posture cues', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: RunningCoachScreen(),
      ),
    );

    await tester.tap(find.text('Open sample video guide'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey('running-coach-sample-video-frame')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('running-coach-sample-frame-guide')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('running-coach-sample-recording-guide')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('running-coach-sample-back-button')),
      findsOneWidget,
    );
    expect(find.text('What to compare in the video'), findsOneWidget);
    expect(find.textContaining('Frame '), findsOneWidget);
    expect(find.text('Landing 0.08'), findsOneWidget);
    expect(
      find.text('Foot lands under the hip with toes forward'),
      findsOneWidget,
    );
  });
}
