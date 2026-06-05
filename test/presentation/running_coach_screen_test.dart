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
      find.byKey(const ValueKey('running-coach-sample-joint-readouts')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('running-coach-sample-analysis-method')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('running-coach-sample-back-button')),
      findsOneWidget,
    );
    expect(find.text('Reference sample'), findsOneWidget);
    expect(find.text('Wrong form sample'), findsOneWidget);
    expect(find.text('What to compare in the video'), findsOneWidget);
    expect(find.text('Reference readouts'), findsOneWidget);
    expect(find.textContaining('Frame '), findsWidgets);
    expect(find.text('Landing 0.08'), findsOneWidget);
    expect(
      find.text('Foot lands under the hip with toes forward'),
      findsOneWidget,
    );
    expect(find.textContaining('landing distance is 0.08'), findsOneWidget);

    await tester.tap(find.text('Wrong form sample'));
    await tester.pump();

    expect(find.text('Wrong-form readouts'), findsOneWidget);
    expect(find.text('Overstride 0.24'), findsOneWidget);
    expect(find.text('Bounce 12%'), findsOneWidget);
    expect(
      find.textContaining('overstride is 0.24 ahead of the hip'),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('running-coach-sample-back-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('running-coach-sample-video-frame')),
      findsNothing,
    );
    expect(find.text('Running Coach'), findsOneWidget);
  });
}
