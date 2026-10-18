import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart'
    show ScanPassPoint;
import 'package:football_note/domain/scan_pass/scan_pass_pressure_lesson.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/scan_pass_game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets('public lesson carries a retained pass into one-tap support',
      (tester) async {
    await tester.pumpWidget(_app(
      home: ScanPassGameScreen(
        optionRepository: _Options(),
        seed: 19,
        previewDuration: Duration.zero,
        passAnimationDuration: Duration.zero,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(ScanPassPressureLessonScreen), findsOneWidget);
    expect(
        find.byKey(const ValueKey<String>('pressure-pitch')), findsOneWidget);
    expect(
        find.byKey(const ValueKey<String>('match-moment-pitch')), findsNothing);
    expect(_progressText(tester), startsWith('Situation 1/18'));
    expect(find.textContaining('pressure reception'), findsOneWidget);

    final received = _world(tester);
    await _tapBestOnBall(tester);
    expect(_world(tester).clock, greaterThan(received.clock));

    if (find
        .byKey(const ValueKey<String>('pressure-support-surface'))
        .hitTestable()
        .evaluate()
        .isEmpty) {
      await _tapBestOnBall(tester);
    }
    expect(
      find
          .byKey(const ValueKey<String>('pressure-support-surface'))
          .hitTestable(),
      findsOneWidget,
      reason: 'A retained pass must continue to the passer support judgment.',
    );
    final supportWorld = _world(tester);
    expect(supportWorld.carrier?.number, isNot(19));
    expect(
      tester
          .widget<Text>(
              find.byKey(const ValueKey<String>('pressure-situation-facts')))
          .data,
      contains('learner #19'),
    );
    await _tapSupport(
        tester,
        supportWorld.actorByRole(PressureActorRole.receiver).position +
            const ScanPassPoint(4.5, 4));
    expect(_world(tester).clock, greaterThan(supportWorld.clock));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'representative attack reaches 3+ decisions with variable replay and exact suffix retry',
      (tester) async {
    await tester.pumpWidget(_app(
      home: const ScanPassPressureLessonScreen(
        seed: 19,
        observationDuration: Duration.zero,
        executionDuration: Duration.zero,
      ),
    ));
    await tester.pumpAndSettle();
    await _playToReview(tester);

    expect(find.byKey(const ValueKey<String>('pressure-review-panel')),
        findsOneWidget);
    final timelineCount = _timelineCount(tester);
    expect(timelineCount, greaterThanOrEqualTo(3));
    expect(timelineCount, lessThanOrEqualTo(5));
    expect(
      find
          .byKey(
              ValueKey<String>('pressure-review-decision-${timelineCount - 1}'))
          .hitTestable(),
      findsOneWidget,
      reason: 'The just-finished judgment must be visible by default.',
    );
    expect(find.byKey(const ValueKey<String>('pressure-episode-outcome')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('pressure-review-action')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('pressure-review-benefit')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('pressure-review-limitation')),
        findsOneWidget);

    await _tap(tester, 'pressure-review-decision-0');
    final reviewed = _painter(tester).reviewResult as PressureSimulationResult;
    final exactSnapshot = reviewed.before;
    final firstAction = tester
        .widget<Text>(
            find.byKey(const ValueKey<String>('pressure-review-action')))
        .data;
    await _tap(tester, 'pressure-replay');
    expect(find.byKey(const ValueKey<String>('pressure-review-panel')),
        findsOneWidget);
    expect(
      tester
          .widget<Text>(
              find.byKey(const ValueKey<String>('pressure-review-action')))
          .data,
      firstAction,
    );

    await _tap(tester, 'pressure-retry');
    expect(identical(_world(tester), exactSnapshot), isTrue);
    expect(_timelineCount(tester), 0,
        reason:
            'Review chips are hidden while only the retained prefix remains.');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'support starts with teammate ownership and a distant tap shows the bounded endpoint',
      (tester) async {
    await tester.pumpWidget(_app(
      home: const ScanPassPressureLessonScreen(
        seed: 19,
        observationDuration: Duration.zero,
        executionDuration: Duration.zero,
      ),
    ));
    await tester.pumpAndSettle();
    await _openSituation(tester, 5);

    final before = _world(tester);
    final learner = before.actorByRole(PressureActorRole.receiver);
    expect(before.carrier?.role, PressureActorRole.support);
    expect(before.carrier?.id, isNot(learner.id));
    expect(find.byKey(const ValueKey<String>('pressure-support-surface')),
        findsOneWidget);

    await _tapSupport(
      tester,
      learner.position + const ScanPassPoint(30, 24),
    );
    final painter = _painter(tester);
    final endpoint = painter.supportTarget as ScanPassPoint?;
    expect(endpoint, isNotNull);
    expect(learner.position.distanceTo(endpoint!), lessThanOrEqualTo(8.01));
    expect(learner.position.distanceTo(endpoint), greaterThan(.2));
    expect(_world(tester).clock, greaterThan(before.clock));
    expect(tester.takeException(), isNull);
  });

  testWidgets('timeline comparison preserves the selected original frame',
      (tester) async {
    await tester.pumpWidget(_app(
      home: const ScanPassPressureLessonScreen(
        seed: 19,
        observationDuration: Duration.zero,
        executionDuration: Duration.zero,
      ),
    ));
    await tester.pumpAndSettle();
    await _playToReview(tester);
    await _tap(tester, 'pressure-review-decision-0');
    final originalAction = tester
        .widget<Text>(
            find.byKey(const ValueKey<String>('pressure-review-action')))
        .data;
    final originalResult = _painter(tester).reviewResult;

    await _tap(tester, 'pressure-compare');
    expect(find.byKey(const ValueKey<String>('pressure-return-attempt')),
        findsOneWidget);
    await _tap(tester, 'pressure-return-attempt');
    expect(
      tester
          .widget<Text>(
              find.byKey(const ValueKey<String>('pressure-review-action')))
          .data,
      originalAction,
    );
    expect(identical(_painter(tester).reviewResult, originalResult), isTrue);
  });

  testWidgets('historical reference returns to the unchanged timeline review',
      (tester) async {
    await tester.pumpWidget(_app(
      home: const ScanPassPressureLessonScreen(
        seed: 19,
        observationDuration: Duration.zero,
        executionDuration: Duration.zero,
      ),
    ));
    await tester.pumpAndSettle();
    await _playToReview(tester);
    final action = tester
        .widget<Text>(
            find.byKey(const ValueKey<String>('pressure-review-action')))
        .data;

    await _tap(tester, 'pressure-reference', settle: false);
    await tester.pumpAndSettle();
    expect(find.byType(ScanPassMatchMomentScreen), findsOneWidget);
    expect(
      tester
          .widget<ScanPassMatchMomentScreen>(
              find.byType(ScanPassMatchMomentScreen))
          .referenceOnly,
      isTrue,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('pressure-review-panel')),
        findsOneWidget);
    expect(
      tester
          .widget<Text>(
              find.byKey(const ValueKey<String>('pressure-review-action')))
          .data,
      action,
    );
  });

  testWidgets('guided support range fades while family and task remain visible',
      (tester) async {
    await tester.pumpWidget(_app(
      home: const ScanPassPressureLessonScreen(
        seed: 19,
        observationDuration: Duration.zero,
        executionDuration: Duration.zero,
      ),
    ));
    await tester.pumpAndSettle();
    await _openSituation(tester, 5);
    expect(_painter(tester).showSupportRange, isTrue);
    expect(_progressText(tester), contains('support after passing'));
    expect(
      tester
          .widget<Text>(
              find.byKey(const ValueKey<String>('pressure-situation-task')))
          .data,
      contains('#19'),
    );

    await _openSituation(tester, 6);
    expect(_painter(tester).showSupportRange, isFalse);
    expect(_progressText(tester), contains('support after passing'));
    expect(find.byKey(const ValueKey<String>('pressure-support-surface')),
        findsOneWidget);
  });

  testWidgets('each judgment shows one neutral family-relevant cue',
      (tester) async {
    await tester.pumpWidget(_app(
      home: const ScanPassPressureLessonScreen(
        seed: 19,
        observationDuration: Duration.zero,
        executionDuration: Duration.zero,
      ),
    ));
    await tester.pumpAndSettle();

    await _openSituation(tester, 5);
    expect(_situationFacts(tester), contains('Return to #19'));
    expect(_situationFacts(tester), contains('from lane'));

    await _openSituation(tester, 7);
    expect(_situationFacts(tester), contains('Runner #17'));

    await _openSituation(tester, 9);
    expect(_situationFacts(tester), contains('To #10'));
    expect(_situationFacts(tester), contains('from pass lane'));
    expect(_situationFacts(tester), isNot(contains('Return to')));
  });

  testWidgets('jumping to situation 18 cannot skip missing first attempts',
      (tester) async {
    await tester.pumpWidget(_app(
      home: const ScanPassPressureLessonScreen(
        seed: 19,
        observationDuration: Duration.zero,
        executionDuration: Duration.zero,
      ),
    ));
    await tester.pumpAndSettle();
    await _openSituation(tester, 18);
    expect(_progressText(tester), startsWith('Situation 18/18'));
    await _playToReview(tester);
    await _tap(tester, 'pressure-next');
    expect(
        find.byKey(const ValueKey<String>('pressure-summary')), findsNothing);
    expect(_progressText(tester), startsWith('Situation 1/18'));
  });

  for (final config in [
    (size: const Size(390, 844), locale: const Locale('ko')),
    (size: const Size(360, 640), locale: const Locale('ko')),
    (size: const Size(844, 390), locale: const Locale('ja')),
    (size: const Size(1280, 800), locale: const Locale('en')),
  ]) {
    testWidgets(
        'responsive ${config.size} ${config.locale.languageCode} keeps context and targets clear',
        (tester) async {
      tester.view.physicalSize = config.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(
        locale: config.locale,
        textScale: 1.25,
        home: const ScanPassPressureLessonScreen(
          seed: 19,
          observationDuration: Duration.zero,
          executionDuration: Duration.zero,
        ),
      ));
      await tester.pumpAndSettle();

      final pitch =
          tester.getRect(find.byKey(const ValueKey<String>('pressure-pitch')));
      final ribbon = tester.getRect(
          find.byKey(const ValueKey<String>('pressure-situation-ribbon')));
      final instruction = tester
          .getRect(find.byKey(const ValueKey<String>('pressure-instruction')));
      final overview = tester
          .getRect(find.byKey(const ValueKey<String>('pressure-overview')));
      expect(pitch.height, greaterThan(config.size.height < 500 ? 120 : 210));
      expect(pitch.overlaps(ribbon), isFalse);
      expect(pitch.overlaps(instruction), isFalse);
      final rects = <Rect>[];
      for (final key in [
        'pressure-action-touch-inside',
        'pressure-action-touch-outside',
        'pressure-action-pass-now',
        'pressure-action-pass-runner-now',
        'pressure-action-pass-back-now',
      ]) {
        final finder = find.byKey(ValueKey<String>(key));
        expect(finder.hitTestable(), findsOneWidget, reason: key);
        final rect = tester.getRect(finder);
        expect(rect.overlaps(overview), isFalse, reason: key);
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, greaterThanOrEqualTo(48));
        for (final previous in rects) {
          expect(rect.overlaps(previous), isFalse, reason: key);
        }
        rects.add(rect);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('pause, menu and lifecycle preserve active observation',
      (tester) async {
    await tester.pumpWidget(_app(
      home: const ScanPassPressureLessonScreen(
        seed: 19,
        observationDuration: Duration(seconds: 2),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 200));
    await _tap(tester, 'pressure-more', settle: false);
    await tester.pumpAndSettle();
    final menuPaused = _world(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(_world(tester).clock, closeTo(menuPaused.clock, 1e-7));
    await tester.tapAt(const Offset(4, 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_world(tester).clock, greaterThan(menuPaused.clock));

    final beforePause = _world(tester);
    await _tap(tester, 'pressure-pause', settle: false);
    await tester.pump(const Duration(milliseconds: 300));
    expect(_world(tester).clock, closeTo(beforePause.clock, 1e-7));
    await _tap(tester, 'pressure-pause', settle: false);
    await tester.pump(const Duration(milliseconds: 100));
    final resumed = _world(tester);
    expect(resumed.clock, greaterThan(beforePause.clock));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(milliseconds: 200));
    expect(_world(tester).clock, closeTo(resumed.clock, 1e-7));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_world(tester).clock, greaterThan(resumed.clock));
  });
}

Future<void> _playToReview(WidgetTester tester) async {
  for (var decision = 0; decision < 6; decision++) {
    if (find
        .byKey(const ValueKey<String>('pressure-review-panel'))
        .evaluate()
        .isNotEmpty) {
      return;
    }
    final support = find
        .byKey(const ValueKey<String>('pressure-support-surface'))
        .hitTestable();
    if (support.evaluate().isNotEmpty) {
      final world = _world(tester);
      await _tapBestSupport(tester, world);
    } else {
      await _tapBestOnBall(tester);
    }
  }
  expect(find.byKey(const ValueKey<String>('pressure-review-panel')),
      findsOneWidget);
}

Future<void> _tapBestSupport(WidgetTester tester, PressureWorld world) async {
  const engine = ScanPassPressureEngine();
  final focus = world.actorByRole(PressureActorRole.receiver);
  final targets = [
    focus.position + const ScanPassPoint(4.5, 4),
    focus.position + const ScanPassPoint(4.5, -4),
    focus.position + const ScanPassPoint(-3.5, 4),
  ];
  var best = targets.first;
  var bestScore = -double.infinity;
  for (final target in targets) {
    final result = engine.simulateSupport(world, target);
    final automatic = result.continuation?.result;
    final score = (result.after.possession == PressurePossession.attack
            ? 1000.0
            : -1000.0) +
        (automatic?.assessment.actionProgressMetres ?? 0) * 5;
    if (score > bestScore) {
      best = target;
      bestScore = score;
    }
  }
  await _tapSupport(tester, best);
}

Future<void> _tapBestOnBall(WidgetTester tester) async {
  const engine = ScanPassPressureEngine();
  final world = _world(tester);
  final firstContact = find
      .byKey(const ValueKey<String>('pressure-action-touch-inside'))
      .evaluate()
      .isNotEmpty;
  final options = engine.optionsFor(
    world,
    firstContact
        ? PressureDecisionStage.firstContact
        : PressureDecisionStage.reRead,
  );
  PressureDecisionOption? best;
  var score = -double.infinity;
  for (final option in options) {
    final finder =
        find.byKey(ValueKey<String>('pressure-action-${option.key}'));
    if (finder.hitTestable().evaluate().isEmpty) continue;
    final result = engine.simulate(world, option.action);
    final value = (result.after.possession == PressurePossession.attack
            ? 1000.0
            : -1000.0) +
        result.assessment.actionProgressMetres * 5 +
        result.assessment.pressureClearanceMetres;
    if (value > score) {
      score = value;
      best = option;
    }
  }
  expect(best, isNotNull);
  await _tap(tester, 'pressure-action-${best!.key}');
}

Future<void> _tapSupport(
    WidgetTester tester, ScanPassPoint targetMetres) async {
  final pitchFinder = find.byKey(const ValueKey<String>('pressure-pitch'));
  final rect = tester.getRect(pitchFinder);
  final painter = _painter(tester);
  final bounds = painter.viewBounds as Rect;
  final vertical = rect.width < rect.height * 1.25;
  final available = Rect.fromLTWH(
      12, 16, math.max(1, rect.width - 24), math.max(1, rect.height - 28));
  final lengthMetres = 105 * bounds.width;
  final widthMetres = 68 * bounds.height;
  final scale = vertical
      ? math.min(available.width / widthMetres, available.height / lengthMetres)
      : math.min(
          available.width / lengthMetres, available.height / widthMetres);
  final viewport = Rect.fromCenter(
    center: available.center,
    width: (vertical ? widthMetres : lengthMetres) * scale,
    height: (vertical ? lengthMetres : widthMetres) * scale,
  );
  final x = targetMetres.x / 105;
  final y = targetMetres.y / 68;
  final local = vertical
      ? Offset(viewport.right - (y - bounds.top) * 68 * scale,
          viewport.bottom - (x - bounds.left) * 105 * scale)
      : Offset(viewport.left + (x - bounds.left) * 105 * scale,
          viewport.bottom - (y - bounds.top) * 68 * scale);
  final clamped = Offset(
    local.dx.clamp(viewport.left + 2, viewport.right - 2),
    local.dy.clamp(viewport.top + 2, viewport.bottom - 2),
  );
  await tester.tapAt(rect.topLeft + clamped);
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<void> _openSituation(WidgetTester tester, int number) async {
  await _tap(tester, 'pressure-more', settle: false);
  await tester.pumpAndSettle();
  final item = find.byKey(ValueKey<String>('pressure-menu-situation-$number'));
  if (item.hitTestable().evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      item,
      160,
      scrollable: find.byType(Scrollable).last,
    );
  }
  await _tap(tester, 'pressure-menu-situation-$number');
}

int _timelineCount(WidgetTester tester) {
  final finder = find.byKey(const ValueKey<String>('pressure-review-count'));
  if (finder.evaluate().isEmpty) return 0;
  final value = tester.widget<Text>(finder).data!;
  return int.parse(RegExp(r'\d+').firstMatch(value)!.group(0)!);
}

dynamic _painter(WidgetTester tester) => tester
    .widget<CustomPaint>(find.byKey(const ValueKey<String>('pressure-pitch')))
    .painter;

PressureWorld _world(WidgetTester tester) =>
    _painter(tester).displayWorld as PressureWorld;

String _progressText(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const ValueKey<String>('pressure-progress')))
    .data!;

String _situationFacts(WidgetTester tester) => tester
    .widget<Text>(
        find.byKey(const ValueKey<String>('pressure-situation-facts')))
    .data!;

Future<void> _tap(WidgetTester tester, String key, {bool settle = true}) async {
  final finder = find.byKey(ValueKey<String>(key));
  if (finder.evaluate().isNotEmpty && finder.hitTestable().evaluate().isEmpty) {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }
  expect(finder.hitTestable(), findsOneWidget, reason: key);
  await tester.tap(finder);
  await tester.pump();
  if (settle) await tester.pumpAndSettle();
}

Widget _app({
  required Widget home,
  Locale locale = const Locale('en'),
  double textScale = 1,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: home,
  );
}

class _Options implements OptionRepository {
  @override
  List<int> getIntOptions(String key, List<int> defaults) => defaults;

  @override
  List<String> getOptions(String key, List<String> defaults) => defaults;

  @override
  T? getValue<T>(String key) => null;

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {}

  @override
  Future<void> setValue(String key, dynamic value) async {}
}
