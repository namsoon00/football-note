import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/scan_pass/scan_pass_attack.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/scan_pass_game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('default entry opens possession lesson and keeps practice access',
      (tester) async {
    await tester.pumpWidget(_app(
      home: ScanPassGameScreen(
        optionRepository: _Options(),
        previewDuration: Duration.zero,
        passAnimationDuration: Duration.zero,
      ),
    ));
    await tester.pump();

    expect(
        find.byKey(const ValueKey<String>('possession-pitch')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('judgment-pitch')), findsNothing);
    expect(find.byKey(const ValueKey<String>('attack-start')), findsNothing);

    await tester
        .tap(find.byKey(const ValueKey<String>('possession-practice-menu')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('possession-open-free-attack')),
        findsOneWidget);
    expect(
        find.byKey(
          const ValueKey<String>('possession-open-judgment-practice'),
        ),
        findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('possession-open-judgment-practice')),
    );
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey<String>('judgment-pitch')), findsOneWidget);
  });

  testWidgets('guided route plays full possession before independent practice',
      (tester) async {
    await tester.pumpWidget(_lessonApp());
    await tester.pump();

    expect(
        find.byKey(const ValueKey<String>('possession-pitch')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('possession-action-touchAway')),
        findsNothing);
    expect(find.byKey(const ValueKey<String>('possession-guided-play')),
        findsOneWidget);

    await _playGuidedRoute(tester);

    expect(find.byKey(const ValueKey<String>('possession-review-result')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('possession-try-independent')),
        findsOneWidget);
    expect(
      (_possessionPainter(tester).decisionBranchLabel as String),
      'Coach’s suggested attack',
    );
  });

  testWidgets('independent practice hides recommendation until review',
      (tester) async {
    await tester.pumpWidget(_lessonApp());
    await tester.pump();
    await _playGuidedRoute(tester);
    await tester
        .tap(find.byKey(const ValueKey<String>('possession-try-independent')));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey<String>('possession-action-touchAway')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('possession-review-result')),
        findsNothing);
    expect(_possessionPainter(tester).decisionBranchLabel, isNull);

    await tester
        .tap(find.byKey(const ValueKey<String>('possession-dock-turnForward')));
    await tester.pump();

    expect(find.byKey(const ValueKey<String>('possession-review-result')),
        findsOneWidget);
    expect(
      (_possessionPainter(tester).decisionBranchLabel as String),
      'My attack',
    );

    await tester
        .tap(find.byKey(const ValueKey<String>('possession-compare-coach')));
    await tester.pump();
    final painter = _possessionPainter(tester);
    expect(painter.decisionBranchLabel as String, 'Coach’s suggested attack');
    expect((painter.history as List<AttackTransition>).length,
        greaterThanOrEqualTo(4));
  });

  testWidgets('changed-cue challenge starts from practice loop without leak',
      (tester) async {
    await tester.pumpWidget(_lessonApp());
    await tester.pump();
    await _playGuidedRoute(tester);
    await tester
        .tap(find.byKey(const ValueKey<String>('possession-changed-cue')));
    await tester.pump();
    await tester.pump();

    expect(find.text('Changed cue'), findsWidgets);
    expect(find.byKey(const ValueKey<String>('possession-action-turnForward')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('possession-review-result')),
        findsNothing);
    expect(_possessionPainter(tester).decisionBranchLabel, isNull);
  });

  testWidgets(
      'full demonstration is readable and manual pause survives background',
      (tester) async {
    await tester.pumpWidget(_app(
        disableAnimations: false,
        home: const ScanPassPossessionLessonScreen()));
    await tester.pump();
    final initialBounds =
        tester.getRect(find.byKey(const ValueKey('possession-pitch')));
    await _playGuidedRoute(tester);
    await tester.pump(const Duration(seconds: 4));
    expect(
        find.byKey(const ValueKey('possession-review-result')), findsNothing);
    expect(tester.getRect(find.byKey(const ValueKey('possession-pitch'))),
        initialBounds);
    await tester.tap(find.byKey(const ValueKey('possession-pause')));
    await tester.pump();
    final paused =
        (_possessionPainter(tester).displayState as AttackState).elapsed;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 3));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 3));
    expect((_possessionPainter(tester).displayState as AttackState).elapsed,
        paused);
    await tester.tap(find.byKey(const ValueKey('possession-pause')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect((_possessionPainter(tester).displayState as AttackState).elapsed,
        greaterThan(paused));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(
        find.byKey(const ValueKey('possession-review-result')), findsOneWidget);
    expect(tester.getRect(find.byKey(const ValueKey('possession-pitch'))),
        initialBounds);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'comparison and moment replay preserve the learner and hide future trails',
      (tester) async {
    await tester.pumpWidget(_lessonApp());
    await tester.pump();
    await _playGuidedRoute(tester);
    Future<void> tap(String key) async {
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pump();
    }

    await tap('possession-try-independent');
    await tester.pump();
    final bounds =
        tester.getRect(find.byKey(const ValueKey('possession-pitch')));
    await tap('possession-dock-touchAway');
    expect(
        tester.getRect(find.byKey(const ValueKey('possession-pitch'))), bounds);
    await tap('possession-dock-passTo9');
    await tap('possession-dock-supportWide');
    final original = (_possessionPainter(tester).displayState as AttackState);
    expect(original.end, isNull);
    expect(original.carrierNumber, 4);
    await tap('possession-compare-coach');
    expect((_possessionPainter(tester).displayState as AttackState).end,
        isNotNull);
    await tap('possession-replay');
    await tap('possession-compare-mine');
    expect((_possessionPainter(tester).displayState as AttackState),
        same(original));
    await tap('possession-moment-receive');
    expect(_possessionPainter(tester).history as List, isEmpty);
    await tap('possession-moment-touch');
    expect((_possessionPainter(tester).history as List).length, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'early loss cannot be reviewed as a pass or support that did not happen',
      (tester) async {
    await tester.pumpWidget(_lessonApp());
    await tester.pump();
    await _playGuidedRoute(tester);
    await tester.tap(find.byKey(const ValueKey('possession-try-independent')));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('possession-dock-turnForward')));
    await tester.pump();
    expect(find.byKey(const ValueKey('possession-moment-link')), findsNothing);
    expect(
        find.byKey(const ValueKey('possession-moment-support')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('possession-moment-touch')));
    await tester.pump();
    expect(find.textContaining('first-touch path'), findsOneWidget);
  });

  for (final config in <({Size size, double textScale})>[
    (size: const Size(390, 844), textScale: 1.3),
    (size: const Size(320, 568), textScale: 1.3),
    (size: const Size(568, 320), textScale: 1.3),
    (size: const Size(1280, 800), textScale: 1.3),
  ]) {
    testWidgets('possession lesson controls fit ${config.size}',
        (tester) async {
      tester.view.physicalSize = config.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_lessonApp(textScale: config.textScale));
      await tester.pump();
      await _playGuidedRoute(tester);
      for (final key in [
        'possession-replay',
        'possession-coach-detail',
        'possession-try-independent',
        'possession-changed-cue'
      ]) {
        final finder = find.byKey(ValueKey(key));
        expect(finder.hitTestable(), findsOneWidget, reason: key);
        expect(tester.getRect(finder).bottom,
            lessThanOrEqualTo(config.size.height));
      }
      await tester.tap(
        find.byKey(const ValueKey<String>('possession-try-independent')),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const ValueKey<String>('possession-pitch')),
          findsOneWidget);
      expect(find.byKey(const ValueKey<String>('possession-dock-touchAway')),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

Widget _lessonApp({
  double textScale = 1,
}) {
  return _app(
    textScale: textScale,
    home: const ScanPassPossessionLessonScreen(
      observationDuration: Duration.zero,
      executionDuration: Duration.zero,
    ),
  );
}

Widget _app({
  required Widget home,
  Locale locale = const Locale('en'),
  double textScale = 1,
  bool disableAnimations = true,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: disableAnimations,
      ),
      child: child!,
    ),
    home: home,
  );
}

dynamic _possessionPainter(WidgetTester tester) => tester
    .widget<CustomPaint>(find.byKey(const ValueKey<String>('possession-pitch')))
    .painter;

Future<void> _playGuidedRoute(WidgetTester tester) async {
  await tester
      .tap(find.byKey(const ValueKey<String>('possession-guided-next-cue')));
  await tester.pump();
  await tester
      .tap(find.byKey(const ValueKey<String>('possession-guided-next-cue')));
  await tester.pump();
  await tester
      .tap(find.byKey(const ValueKey<String>('possession-guided-play')));
  await tester.pump();
}

class _Options implements OptionRepository {
  @override
  T? getValue<T>(String key) => null;

  @override
  List<String> getOptions(String key, List<String> defaults) => defaults;

  @override
  List<int> getIntOptions(String key, List<int> defaults) => defaults;

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {}

  @override
  Future<void> setValue(String key, dynamic value) async {}
}
