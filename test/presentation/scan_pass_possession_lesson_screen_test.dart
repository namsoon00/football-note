import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_attack.dart';
import 'package:football_note/domain/scan_pass/scan_pass_possession_lesson.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/scan_pass_game_screen.dart';

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'legacy continuous situation catalog remains internally available',
      (tester) async {
    await tester.pumpWidget(_app(
      home: const ScanPassPossessionLessonScreen(
        observationDuration: Duration.zero,
        executionDuration: Duration.zero,
      ),
    ));
    await tester.pump();

    expect(find.byKey(const ValueKey<String>('possession-catalog')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey<String>('possession-pitch')), findsNothing);
    expect(find.byKey(const ValueKey<String>('judgment-pitch')), findsNothing);
    expect(find.byKey(const ValueKey<String>('attack-start')), findsNothing);
    expect(find.byKey(const ValueKey<String>('possession-practice-menu')),
        findsNothing);
    expect(
      find.byKey(
        const ValueKey<String>('possession-open-judgment-practice'),
      ),
      findsNothing,
    );

    for (final id in _scenarioIds) {
      expect(
          find.byKey(ValueKey<String>('possession-card-$id')), findsOneWidget,
          reason: id);
    }

    await _openScenario(tester, 'halfSpace-cover');
    expect(
        find.byKey(const ValueKey<String>('possession-pitch')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('possession-guided-play')),
        findsNothing);
    expect(find.byKey(const ValueKey<String>('possession-action-touchAway')),
        findsOneWidget);
    expect(find.textContaining('Passing-lane cover'), findsWidgets);
  });

  testWidgets('scenario starts independently and keeps coach demo next catalog',
      (tester) async {
    await tester.pumpWidget(_lessonApp());
    await tester.pump();

    await _openScenario(tester, 'centralReceive-pressure');
    expect(find.byKey(const ValueKey<String>('possession-coach-demo')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('possession-return-catalog')),
        findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey<String>('possession-coach-demo')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('possession-review-result')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('possession-compare-coach')),
        findsOneWidget);
    expect(
      (_possessionPainter(tester).decisionBranchLabel as String),
      'Coach’s suggested attack',
    );

    await tester
        .tap(find.byKey(const ValueKey<String>('possession-next-scenario')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('possession-action-touchAway')),
        findsOneWidget);
    expect(find.textContaining('2/12'), findsWidgets);

    await tester
        .tap(find.byKey(const ValueKey<String>('possession-return-catalog')));
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('possession-catalog')),
        findsOneWidget);
  });

  testWidgets('choice routes show actual metres and selected execution route',
      (tester) async {
    await tester.pumpWidget(_app(
      disableAnimations: false,
      home: const ScanPassPossessionLessonScreen(
        observationDuration: Duration.zero,
        executionDuration: Duration(milliseconds: 600),
      ),
    ));
    await tester.pump();
    await _openScenario(tester, 'centralReceive-pressure');

    final choiceOverlay = _routeOverlay(tester);
    expect(choiceOverlay.routes, hasLength(3));
    for (final dynamic route in choiceOverlay.routes as List<dynamic>) {
      expect(route.distanceMetres as double, greaterThan(0));
      expect(route.label as String, contains('m'));
    }

    await tester
        .tap(find.byKey(const ValueKey<String>('possession-action-touchAway')));
    await tester.pump();
    final executingOverlay = _routeOverlay(tester);
    expect(executingOverlay.routes, isNotEmpty);
    expect(
        find.byKey(const ValueKey<String>('possession-pause')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('possession-pause')));
    await tester.pump();
    final paused =
        (_possessionPainter(tester).displayState as AttackState).elapsed;
    await tester.pump(const Duration(seconds: 1));
    expect((_possessionPainter(tester).displayState as AttackState).elapsed,
        paused);
  });

  testWidgets('support phase draws number 6 off-ball run distances',
      (tester) async {
    await tester.pumpWidget(_app(
      disableAnimations: false,
      home: const ScanPassPossessionLessonScreen(
        observationDuration: Duration.zero,
        executionDuration: Duration(milliseconds: 80),
      ),
    ));
    await tester.pump();
    await _openScenario(tester, 'centralReceive-pressure');

    final path = _pathToSupportDecision();
    for (final choice in path) {
      await _tapChoiceAndFinish(tester, choice);
    }
    expect(
        find.byKey(const ValueKey<String>('possession-action-supportInside')),
        findsOneWidget);
    final supportOverlay = _routeOverlay(tester);
    expect(supportOverlay.routes, hasLength(4));
    for (final dynamic route in supportOverlay.routes as List<dynamic>) {
      expect(route.ballPath as bool, isFalse);
      expect(route.label as String, contains('Player movement'));
    }

    await tester.tap(find.byKey(ValueKey<String>(
        'possession-action-${_supportChoiceForCurrentScene().name}')));
    await tester.pump();
    final selectedOverlay = _routeOverlay(tester);
    expect(selectedOverlay.routes, isNotEmpty);
    expect(
      (selectedOverlay.routes as List<dynamic>)
          .any((dynamic route) => route.ballPath as bool),
      isFalse,
    );
  });

  testWidgets('open pitch support tap commits a custom movement destination',
      (tester) async {
    await tester.pumpWidget(_app(
      disableAnimations: false,
      home: const ScanPassPossessionLessonScreen(
        observationDuration: Duration.zero,
        executionDuration: Duration(milliseconds: 80),
      ),
    ));
    await tester.pump();
    await _openScenario(tester, 'centralReceive-pressure');

    for (final choice in _pathToSupportDecision()) {
      await _tapChoiceAndFinish(tester, choice);
    }

    final pitch = find.byKey(const ValueKey<String>('possession-pitch'));
    await tester.tapAt(tester.getCenter(pitch) + const Offset(34, 28));
    await tester.pump();

    final selectedOverlay = _routeOverlay(tester);
    expect(selectedOverlay.routes, isNotEmpty);
    expect(
      (selectedOverlay.routes as List<dynamic>)
          .any((dynamic route) => route.ballPath as bool),
      isFalse,
    );
  });

  for (final size in const [Size(320, 568), Size(568, 320)]) {
    testWidgets('pitch hitboxes execute decisions at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_app(
        disableAnimations: false,
        home: const ScanPassPossessionLessonScreen(
          observationDuration: Duration.zero,
          executionDuration: Duration(milliseconds: 80),
        ),
      ));
      await tester.pump();
      await _openScenario(tester, 'centralReceive-pressure');

      final touch = find.byKey(
        const ValueKey<String>('possession-action-touchAway'),
      );
      expect(touch, findsOneWidget);
      expect(tester.getSize(touch), const Size(48, 48));
      await tester.tap(touch);
      await tester.pumpAndSettle(const Duration(milliseconds: 40));

      final pass = find.byKey(
        const ValueKey<String>('possession-action-passTo8'),
      );
      expect(pass, findsOneWidget);
      expect(tester.getSize(pass), const Size(48, 48));
      await tester.tap(pass);
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('possession-pause')),
        findsOneWidget,
      );
    });
  }

  testWidgets('speed toggle is readable and changes state', (tester) async {
    await tester.pumpWidget(_lessonApp());
    await tester.pump();
    await _openScenario(tester, 'centralReceive-pressure');

    expect(find.text('1x'), findsOneWidget);
    await tester
        .tap(find.byKey(const ValueKey<String>('possession-speed-toggle')));
    await tester.pump();
    expect(find.text('0.65x'), findsOneWidget);
  });

  for (final config in <({Size size, double textScale})>[
    (size: const Size(390, 844), textScale: 1.3),
    (size: const Size(320, 568), textScale: 1.3),
    (size: const Size(568, 320), textScale: 1.3),
    (size: const Size(1280, 800), textScale: 1.3),
  ]) {
    testWidgets('catalog and play controls fit ${config.size}', (tester) async {
      tester.view.physicalSize = config.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_lessonApp(textScale: config.textScale));
      await tester.pump();
      expect(find.byKey(const ValueKey<String>('possession-catalog')),
          findsOneWidget);
      expect(tester.takeException(), isNull);

      await _openScenario(tester, 'centralReceive-pressure');
      for (final key in [
        'possession-coach-demo',
        'possession-return-catalog',
        'possession-action-touchAway',
      ]) {
        final finder = find.byKey(ValueKey<String>(key));
        expect(finder.hitTestable(), findsOneWidget, reason: key);
        expect(tester.getRect(finder).bottom,
            lessThanOrEqualTo(config.size.height));
      }
      expect(
        tester.getSize(
          find.byKey(const ValueKey<String>('possession-action-touchAway')),
        ),
        const Size(48, 48),
      );
      expect(tester.takeException(), isNull);
    });
  }
}

const _scenarioIds = <String>[
  'centralReceive-pressure',
  'centralReceive-cover',
  'halfSpace-pressure',
  'halfSpace-cover',
  'touchline-pressure',
  'touchline-cover',
  'layoff-pressure',
  'layoff-cover',
  'thirdPlayer-pressure',
  'thirdPlayer-cover',
  'transition-pressure',
  'transition-cover',
];

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

dynamic _routeOverlay(WidgetTester tester) => tester
    .widget<CustomPaint>(
        find.byKey(const ValueKey<String>('possession-route-overlay')))
    .painter;

Future<void> _openScenario(WidgetTester tester, String id) async {
  final card = find.byKey(ValueKey<String>('possession-card-$id'));
  await tester.ensureVisible(card);
  await tester.tap(card);
  await tester.pump();
  await tester.pump();
}

List<ScanPassPossessionChoice> _pathToSupportDecision() {
  const engine = ScanPassPossessionLessonEngine();
  final scenario = ScanPassPossessionLessonEngine.catalog.first;
  final scene =
      engine.scene(variant: scenario.variant, situation: scenario.situation);
  final firstPoint = engine.firstPhase(scene);
  for (final first in firstPoint.choices) {
    final firstResult = engine.choose(firstPoint, first);
    final secondPoint = firstResult.nextPoint;
    if (secondPoint == null) continue;
    if (secondPoint.kind == ScanPassPossessionDecisionKind.support) {
      return <ScanPassPossessionChoice>[first];
    }
    for (final second in secondPoint.choices) {
      final secondResult = engine.choose(secondPoint, second);
      final supportPoint = secondResult.nextPoint;
      if (supportPoint?.kind == ScanPassPossessionDecisionKind.support) {
        return <ScanPassPossessionChoice>[first, second];
      }
    }
  }
  fail('No route reached the support decision in the possession engine.');
}

ScanPassPossessionChoice _supportChoiceForCurrentScene() {
  const engine = ScanPassPossessionLessonEngine();
  final scenario = ScanPassPossessionLessonEngine.catalog.first;
  final scene =
      engine.scene(variant: scenario.variant, situation: scenario.situation);
  final firstPoint = engine.firstPhase(scene);
  for (final first in firstPoint.choices) {
    final firstResult = engine.choose(firstPoint, first);
    final next = firstResult.nextPoint;
    if (next?.kind == ScanPassPossessionDecisionKind.support) {
      return next!.choices.first;
    }
    if (next?.kind != ScanPassPossessionDecisionKind.nextAction) continue;
    for (final second in next!.choices) {
      final secondResult = engine.choose(next, second);
      final support = secondResult.nextPoint;
      if (support?.kind == ScanPassPossessionDecisionKind.support) {
        return support!.choices.first;
      }
    }
  }
  fail('No support choice available in the possession engine.');
}

Future<void> _tapChoiceAndFinish(
  WidgetTester tester,
  ScanPassPossessionChoice choice,
) async {
  await tester
      .tap(find.byKey(ValueKey<String>('possession-action-${choice.name}')));
  await tester.pumpAndSettle(const Duration(milliseconds: 40));
}
