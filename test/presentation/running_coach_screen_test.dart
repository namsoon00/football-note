import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/running_coach_screen.dart';

void main() {
  testWidgets('growth loop records a sprint time and shows badges', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final optionRepository = _MemoryOptionRepository();
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
        home: RunningCoachScreen(optionRepository: optionRepository),
      ),
    );

    expect(
      find.byKey(const ValueKey('running-coach-today-mission-card')),
      findsOneWidget,
    );
    expect(find.text("Today's speed mission"), findsOneWidget);
    expect(find.text('Records'), findsOneWidget);
    expect(find.text('Analysis'), findsOneWidget);

    await tester.tap(find.text('Records'));
    await tester.pumpAndSettle();

    expect(find.text('Beat your own runner'), findsOneWidget);
    expect(find.text('No time yet'), findsWidgets);

    await tester.enterText(
      find.byKey(const ValueKey('running-coach-record-seconds-field')),
      '4.32',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('running-coach-record-save-button')),
      -220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const ValueKey('running-coach-record-save-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('4.32s'), findsOneWidget);
    expect(find.text('First sprint'), findsOneWidget);
    expect(find.text('Sprint time saved.'), findsOneWidget);
  });

  testWidgets('sample sheet shows framed runner posture cues', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
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

    await tester.tap(find.text('Analysis'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Open sample video guide'),
      -220,
      scrollable: find.byType(Scrollable).first,
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

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = {};

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    _values[key] = defaults;
    return List<String>.from(defaults);
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    if (value is List) {
      return value.map((item) => int.tryParse(item.toString()) ?? 0).toList();
    }
    _values[key] = defaults;
    return List<int>.from(defaults);
  }

  @override
  T? getValue<T>(String key) => _values[key] as T?;

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    _values[key] = options;
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    _values[key] = value;
  }
}
