import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_attack.dart';
import 'package:football_note/domain/scan_pass/scan_pass_curriculum.dart';
import 'package:football_note/domain/scan_pass/scan_pass_flow.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/scan_pass_game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  const engine = FlowEngine();

  for (final locale in ['en', 'ko', 'ja']) {
    for (final size in [
      const Size(390, 844),
      const Size(568, 320),
      const Size(320, 568)
    ]) {
      testWidgets('pitch stays fixed through actions for $locale at $size',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(_app(
            locale: Locale(locale),
            textScale: 1.3,
            execution: const Duration(milliseconds: 400)));
        await tester.pumpAndSettle();
        final pitch = find.byKey(const ValueKey('flow-pitch'));
        final original = tester.getRect(pitch);
        final start = const FlowEngine().start(FlowEngine.catalog.first);
        final touch = start.state.ball + const ScanPassPoint(2.3 / 40, 0);
        await _tapSpace(tester, touch, settle: false);
        await tester.pumpAndSettle();
        expect(tester.getRect(pitch), original,
            reason: 'first touch to pass-ready');
        await tester.tap(find.byKey(const ValueKey('flow-pass')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 30));
        expect(tester.getRect(pitch), original, reason: 'pass in flight');
        final touched = const FlowEngine().touchTo(start, touch).session;
        final receipt = const FlowEngine().pass(touched).session;
        await _tapSpace(tester, _safeTouch(receipt), settle: false);
        expect(tester.getRect(pitch), original,
            reason: 'queued touch cancel changes trailing header');
        await tester.pumpAndSettle();
        expect(tester.getRect(pitch), original,
            reason: 'receipt and queued touch');
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('the opening pass accepts a clearly prepared first touch',
      (tester) async {
    await tester.pumpWidget(_app(
        observation: const Duration(milliseconds: 650),
        execution: const Duration(milliseconds: 400)));
    await tester.pump(const Duration(milliseconds: 80));
    final start = engine.start(FlowEngine.catalog.first);
    final target = _safeTouch(start);
    final l =
        AppLocalizations.of(tester.element(find.byType(ScanPassFlowScreen)))!;
    expect(
        find.text(l.flowNowLine(l.flowPrepareTouch(start.state.carrierNumber))),
        findsOneWidget);
    expect(_painter(tester).selectedPlayer, _state(tester).carrierNumber);
    await _tapSpace(tester, target, settle: false);
    expect(find.byKey(const ValueKey('flow-cancel')), findsOneWidget);
    await tester.pumpAndSettle();
    _expectState(_state(tester), engine.touchTo(start, target).session.state);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'executing a first touch describes the next action instead of asking for another touch',
      (tester) async {
    await tester.pumpWidget(_app(execution: const Duration(milliseconds: 500)));
    await tester.pumpAndSettle();
    final start = engine.start(FlowEngine.catalog.first);
    final target = _safeTouch(start);
    await _tapSpace(tester, target, settle: false);
    final l =
        AppLocalizations.of(tester.element(find.byType(ScanPassFlowScreen)))!;
    expect(find.text(l.flowNowLine(l.flowTouchInMotion)), findsOneWidget);
    const next = ScanPassPoint(.20, .80);
    await _tapSpace(tester, next, settle: false);
    await tester.pumpAndSettle();
    final touched = engine.touchTo(start, target).session;
    _expectState(_state(tester), engine.moveTo(touched, next).session.state);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens straight into 2v2 with a free first-touch surface',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final state = _state(tester);
    expect(state.attackers, hasLength(2));
    expect(state.defenders, hasLength(2));
    expect(find.byKey(const ValueKey('practice-catalog')), findsNothing);
    expect(find.byKey(const ValueKey('practice-position-mode')), findsNothing);
    expect(find.byKey(const ValueKey('flow-review-actions')), findsNothing);
    expect(find.byKey(const ValueKey('flow-pitch')), findsOneWidget);
    expect(_painter(tester).touchOrigin, isNotNull);
    expect(
        find.byKey(const ValueKey('flow-first-touch-badge')), findsOneWidget);
    expect(find.textContaining('FIRST TOUCH'), findsWidgets);
    expect(find.textContaining('Choose where No. 6'), findsOneWidget);
    expect(find.byKey(const ValueKey('flow-pass')), findsNothing);
    expect(find.textContaining('Goal ·'), findsOneWidget);
    expect(find.textContaining('Now ·'), findsOneWidget);
  });

  for (final size in [const Size(568, 320), const Size(320, 568)]) {
    for (final action in [PracticeActionKind.pass, PracticeActionKind.hold]) {
      testWidgets(
          'nearby receiver keeps $action independently tappable at $size',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(_app());
        await tester.pumpAndSettle();
        var session = engine.start(FlowEngine.catalog.first);
        final touch = session.state.ball + const ScanPassPoint(2.3 / 40, 0);
        await _tapSpace(tester, touch);
        session = engine.touchTo(session, touch).session;
        final pass = find.byKey(const ValueKey('flow-pass'));
        final hold = find.byKey(const ValueKey('flow-hold'));
        expect(tester.getRect(pass).overlaps(tester.getRect(hold)), isFalse);
        expect(pass.hitTestable(), findsOneWidget);
        expect(hold.hitTestable(), findsOneWidget);
        final expected = action == PracticeActionKind.pass
            ? engine.pass(session)
            : engine.hold(session);
        await tester.tap(action == PracticeActionKind.pass ? pass : hold);
        await tester.pumpAndSettle();
        _expectState(_state(tester), expected.session.state);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('all twelve cases accept arbitrary first-touch coordinates',
      (tester) async {
    for (var index = 0; index < FlowEngine.catalog.length; index++) {
      await tester.pumpWidget(_app(key: ValueKey(index)));
      await tester.pumpAndSettle();
      if (index > 0) await _openCase(tester, index);
      final before = engine.start(FlowEngine.catalog[index]);
      final target = ScanPassPoint(
          before.state.ball.x + .0167, before.state.ball.y + .047);
      final expected = engine.touchTo(before, target);
      await _tapSpace(tester, target);
      _expectState(_state(tester), expected.session.state);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
      'visible pass ring launches one-tap automatic support and restores receiving control',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    var session = await _touch(tester, engine.start(FlowEngine.catalog.first));
    final before = session.state;
    expect(find.text('Pass'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('flow-pass')).hitTestable(), findsOneWidget);
    final expected = engine.pass(session);
    await tester.tap(find.byKey(const ValueKey('flow-pass')));
    await tester.pumpAndSettle();
    session = expected.session;
    _expectState(_state(tester), session.state);
    if (!session.finished) {
      expect(session.phase, PracticePhase.firstTouch);
      expect(_painter(tester).touchOrigin, isNotNull);
      final run = (_painter(tester).runTargets
          as Map<int, ScanPassPoint>)[before.carrierNumber];
      expect(run, isNotNull);
      expect(
          PracticeEngine.distanceMetres(
              before.carrier.position,
              session.state.attackers
                  .firstWhere((p) => p.number == before.carrierNumber)
                  .position),
          greaterThan(.1));
      final oldRunner = session.state.attackers
          .firstWhere((p) => p.number == before.carrierNumber)
          .position;
      session = await _touch(tester, session);
      expect(
          PracticeEngine.distanceMetres(
              oldRunner,
              session.state.attackers
                  .firstWhere((p) => p.number == before.carrierNumber)
                  .position),
          greaterThan(.1));
    }
    expect(
        find.byKey(const ValueKey('flow-pass')).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'mid-pass keeps passer selected while a receiver first touch can be prepared',
      (tester) async {
    await tester.pumpWidget(_app(execution: const Duration(milliseconds: 900)));
    await tester.pumpAndSettle();
    var session = await _touch(tester, engine.start(FlowEngine.catalog.first));
    final pass = engine.pass(session);
    await tester.tap(find.byKey(const ValueKey('flow-pass')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(_state(tester).carrierNumber, session.state.carrierNumber);
    expect(
        find.textContaining(
            'Pass travelling to No. ${pass.session.state.carrierNumber}'),
        findsOneWidget);
    expect(find.text('PREP TOUCH'), findsOneWidget);
    final target = pass.session.state.ball + const ScanPassPoint(.018, -.035);
    await _tapSpace(tester, target, settle: false);
    await tester.pump();
    expect(
        find.textContaining(
            'First touch for No. ${pass.session.state.carrierNumber}'),
        findsOneWidget);
    await tester.pumpAndSettle();
    session = engine.touchTo(pass.session, target).session;
    _expectState(_state(tester), session.state);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a normal pass can be queued while first touch is still moving',
      (tester) async {
    await tester.pumpWidget(_app(execution: const Duration(milliseconds: 900)));
    await tester.pumpAndSettle();
    final start = engine.start(FlowEngine.catalog.first);
    final target = _safeTouch(start);
    final touched = engine.touchTo(start, target).session;
    await _tapSpace(tester, target, settle: false);
    await tester.pump(const Duration(milliseconds: 80));
    expect(
        find.byKey(const ValueKey('flow-pass')).hitTestable(), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('flow-pass')));
    await tester.pump();
    expect(find.textContaining('Next action queued'), findsOneWidget);
    await tester.pumpAndSettle();
    final expected = engine.pass(touched).session;
    _expectState(_state(tester), expected.state);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pass ring is hollow and its label avoids the receiver body',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final session =
        await _touch(tester, engine.start(FlowEngine.catalog.first));
    final decoration = tester
        .widget<DecoratedBox>(
            find.byKey(const ValueKey('flow-pass-ring-visual')))
        .decoration as BoxDecoration;
    expect(decoration.shape, BoxShape.circle);
    expect(decoration.color, Colors.transparent);
    expect(decoration.boxShadow, isNull);
    expect(tester.getSize(find.byKey(const ValueKey('flow-pass'))).width,
        greaterThanOrEqualTo(44));
    final pitchRect = tester.getRect(find.byKey(const ValueKey('flow-pitch')));
    final receiver = session.state.attackers
        .firstWhere((p) => p.number != session.state.carrierNumber);
    final receiverCenter = pitchRect.topLeft +
        (_painter(tester).offsetFor(receiver.position, pitchRect.size)
            as Offset);
    final receiverBody =
        Rect.fromCenter(center: receiverCenter, width: 44, height: 58);
    expect(
        tester
            .getRect(find.byKey(const ValueKey('flow-pass-label')))
            .overlaps(receiverBody),
        isFalse);
    await tester.tapAt(receiverCenter);
    await tester.pumpAndSettle();
    _expectState(_state(tester), engine.pass(session).session.state);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'retrying an automatic pass restores the exact world without run placement',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    var session = await _touch(tester, engine.start(FlowEngine.catalog.first));
    session = engine.pass(session).session;
    await tester.tap(find.byKey(const ValueKey('flow-pass')));
    await tester.pumpAndSettle();
    if (!session.finished) await _menu(tester, 'flow-review-now');
    final index = session.decisions.length - 1;
    final restored = engine.beforeDecision(session, index);
    await tester.tap(find.byKey(const ValueKey('flow-retry')));
    await tester.pumpAndSettle();
    _expectState(_state(tester), restored.state);
    expect(find.byKey(const ValueKey('flow-feedback')), findsNothing);
    expect(
        find.byKey(const ValueKey('flow-pass')).hitTestable(), findsOneWidget);
    final second = engine.pass(restored).session;
    await tester.tap(find.byKey(const ValueKey('flow-pass')));
    await tester.pumpAndSettle();
    _expectState(_state(tester), second.state);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(390, 844),
    const Size(320, 568),
    const Size(568, 320)
  ]) {
    testWidgets('review has two fixed actions and structured feedback at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(textScale: 1.3));
      await tester.pumpAndSettle();
      var session =
          await _touch(tester, engine.start(FlowEngine.catalog.first));
      while (!session.finished) {
        session = engine.hold(session).session;
        await tester.tap(find.byKey(const ValueKey('flow-hold')));
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const ValueKey('flow-feedback')), findsOneWidget);
      expect(find.text('Result'), findsOneWidget);
      expect(find.text('Why'), findsOneWidget);
      expect(find.text('Try next'), findsOneWidget);
      final footer = find.byKey(const ValueKey('flow-review-actions'));
      expect(find.descendant(of: footer, matching: find.byType(FilledButton)),
          findsOneWidget);
      expect(find.descendant(of: footer, matching: find.byType(OutlinedButton)),
          findsOneWidget);
      expect(find.text('Replay my play'), findsNothing);
      expect(find.byKey(const ValueKey('flow-retry')).hitTestable(),
          findsOneWidget);
      expect(find.byKey(const ValueKey('flow-next')).hitTestable(),
          findsOneWidget);
      expect(_state(tester).carrierIsDefender, isTrue);
      final restored =
          engine.beforeDecision(session, session.decisions.length - 1);
      await tester.tap(find.byKey(const ValueKey('flow-retry')));
      await tester.pumpAndSettle();
      _expectState(_state(tester), restored.state);
      expect(find.byKey(const ValueKey('flow-feedback')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('one next movement can be replaced during animation',
      (tester) async {
    await tester.pumpWidget(_app(execution: const Duration(milliseconds: 650)));
    await tester.pumpAndSettle();
    final first = engine.start(FlowEngine.catalog.first);
    final target = _safeTouch(first);
    final touched = engine.touchTo(first, target).session;
    await _tapSpace(tester, target, settle: false);
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.byKey(const ValueKey('flow-pause')), findsOneWidget);
    await _tapSpace(tester, const ScanPassPoint(.22, .86), settle: false);
    const replaced = ScanPassPoint(.20, .80);
    await _tapSpace(tester, replaced, settle: false);
    expect(find.textContaining('Next action queued'), findsOneWidget);
    await tester.pumpAndSettle();
    final expected = engine.moveTo(touched, replaced).session;
    _expectState(_state(tester), expected.state);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'replay and prior attempt live in More without changing the new session',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    var session = await _touch(tester, engine.start(FlowEngine.catalog.first));
    await _menu(tester, 'flow-review-now');
    await tester.tap(find.byKey(const ValueKey('flow-retry')));
    await tester.pumpAndSettle();
    session = engine.beforeDecision(session, 0);
    session = await _touch(tester, session);
    await _menu(tester, 'flow-review-now');
    final current = _state(tester);
    await _menu(tester, 'flow-replay-previous');
    _expectState(_state(tester), current);
    await _menu(tester, 'flow-replay');
    _expectState(_state(tester), current);
    await tester.tap(find.byKey(const ValueKey('flow-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('flow-feedback')), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'a through pass points at the visible automatic endpoint and is playable on a phone',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await _openCase(tester, 6);
    var session = engine.start(FlowEngine.catalog[6]);
    const first = ScanPassPoint(.3475, .65);
    session = engine.touchTo(session, first).session;
    await _tapSpace(tester, first);
    final run = engine.throughTarget(session);
    expect(run, isNotNull);
    expect(find.byKey(const ValueKey('flow-through')).hitTestable(),
        findsOneWidget);
    final expected = engine.pass(session, through: true);
    await tester.tap(find.byKey(const ValueKey('flow-through')));
    await tester.pumpAndSettle();
    session = expected.session;
    _expectState(_state(tester), session.state);
    expect(expected.decision.action.kind, PracticeActionKind.through);
    expect(expected.decision.action.target.distanceTo(run!), closeTo(0, 1e-9));
    expect(session.phase, PracticePhase.firstTouch);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening a case picker pauses motion until the picker closes',
      (tester) async {
    await tester.pumpWidget(_app(execution: const Duration(milliseconds: 800)));
    await tester.pumpAndSettle();
    final session = engine.start(FlowEngine.catalog.first);
    await _tapSpace(tester, _safeTouch(session), settle: false);
    await tester.pump(const Duration(milliseconds: 40));
    await _menu(tester, 'flow-cases');
    final elapsed = _state(tester).elapsed;
    await tester.pump(const Duration(seconds: 3));
    expect(_state(tester).elapsed, closeTo(elapsed, .000001));
    await tester.tapAt(const Offset(12, 80));
    await tester.pumpAndSettle();
    expect(_state(tester).elapsed, greaterThan(elapsed));
    expect(tester.takeException(), isNull);
  });
}

Widget _app(
        {Key? key,
        Duration execution = Duration.zero,
        Duration observation = Duration.zero,
        double textScale = 1,
        Locale locale = const Locale('en')}) =>
    MaterialApp(
      key: key,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!),
      home: ScanPassFlowScreen(
          observationDuration: observation, executionDuration: execution),
    );
dynamic _painter(WidgetTester tester) => tester
    .widget<CustomPaint>(find.byKey(const ValueKey('flow-pitch-paint')))
    .painter;
AttackState _state(WidgetTester tester) =>
    _painter(tester).state as AttackState;
void _expectState(AttackState actual, AttackState expected) {
  expect(actual.elapsed, closeTo(expected.elapsed, .000001));
  expect(actual.ball.distanceTo(expected.ball), closeTo(0, .000001));
  expect(actual.carrierNumber, expected.carrierNumber);
  expect(actual.carrierIsDefender, expected.carrierIsDefender);
  for (final player in [...actual.attackers, ...actual.defenders]) {
    final other = [...expected.attackers, ...expected.defenders].firstWhere(
        (p) => p.number == player.number && p.opponent == player.opponent);
    expect(player.position.distanceTo(other.position), closeTo(0, .000001));
  }
}

ScanPassPoint _safeTouch(PracticeSession session) {
  const engine = FlowEngine();
  for (final delta in [
    const ScanPassPoint(.012, .055),
    const ScanPassPoint(.035, -.045),
    const ScanPassPoint(-.035, .04)
  ]) {
    final target = ScanPassPoint(
        session.state.ball.x + delta.x, session.state.ball.y + delta.y);
    if (!engine.touchTo(session, target).session.finished) return target;
  }
  throw StateError('No safe first touch in this fixture');
}

Future<PracticeSession> _touch(
    WidgetTester tester, PracticeSession session) async {
  final target = _safeTouch(session);
  final next = const FlowEngine().touchTo(session, target).session;
  await _tapSpace(tester, target);
  return next;
}

Future<void> _tapSpace(WidgetTester tester, ScanPassPoint point,
    {bool settle = true}) async {
  final rect = tester.getRect(find.byKey(const ValueKey('flow-pitch')));
  await tester.tapAt(
      rect.topLeft + (_painter(tester).offsetFor(point, rect.size) as Offset));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Future<void> _menu(WidgetTester tester, String item) async {
  await tester.tap(find.byKey(const ValueKey('flow-more')));
  await tester.pumpAndSettle();
  final entry = find.byKey(ValueKey(item));
  await tester.ensureVisible(entry);
  await tester.tap(entry);
  await tester.pumpAndSettle();
}

Future<void> _openCase(WidgetTester tester, int index) async {
  await _menu(tester, 'flow-cases');
  final entry = find.byKey(ValueKey('flow-case-$index'));
  await tester.scrollUntilVisible(entry, 200);
  await tester.ensureVisible(entry);
  await tester.pumpAndSettle();
  await tester.tap(entry);
  await tester.pumpAndSettle();
}
