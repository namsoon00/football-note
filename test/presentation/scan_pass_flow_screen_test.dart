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
    expect(find.textContaining('Goal ·'), findsOneWidget);
    expect(find.textContaining('Now ·'), findsOneWidget);
  });

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
      'one support click launches the pass and run, then restores receiving control',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    var session = await _touch(tester, engine.start(FlowEngine.catalog.first));
    final before = session.state;
    await tester.tap(find.byKey(const ValueKey('flow-pass')));
    await tester.pumpAndSettle();
    _expectState(_state(tester), before);
    expect(find.textContaining('move after passing'), findsOneWidget);
    const destination = ScanPassPoint(.78, .83);
    final expected = engine.passAndMove(session, runTarget: destination);
    await _tapSpace(tester, destination);
    session = expected.session;
    _expectState(_state(tester), session.state);
    if (!session.finished) {
      expect(session.phase, PracticePhase.firstTouch);
      expect(_painter(tester).touchOrigin, isNotNull);
      final run = (_painter(tester).runTargets
          as Map<int, ScanPassPoint>)[before.carrierNumber];
      expect(run!.distanceTo(destination), closeTo(0, .000001));
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
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'retrying a pass restores its exact starting world and asks for a new support point',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    var session = await _touch(tester, engine.start(FlowEngine.catalog.first));
    await tester.tap(find.byKey(const ValueKey('flow-pass')));
    await tester.pumpAndSettle();
    const destination = ScanPassPoint(.7, .86);
    session = engine.passAndMove(session, runTarget: destination).session;
    await _tapSpace(tester, destination);
    if (!session.finished) await _menu(tester, 'flow-review-now');
    final index = session.decisions.length - 1;
    final restored = engine.beforeDecision(session, index);
    await tester.tap(find.byKey(const ValueKey('flow-retry')));
    await tester.pumpAndSettle();
    _expectState(_state(tester), restored.state);
    expect(find.textContaining('move after passing'), findsOneWidget);
    expect(find.byKey(const ValueKey('flow-feedback')), findsNothing);
    const other = ScanPassPoint(.63, .16);
    final second = engine.passAndMove(restored, runTarget: other).session;
    await _tapSpace(tester, other);
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
    expect(find.textContaining('Next move queued'), findsOneWidget);
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
      'a through return points at the commanded endpoint and is playable on a phone',
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
    await tester.tap(find.byKey(const ValueKey('flow-pass')));
    await tester.pumpAndSettle();
    const run = ScanPassPoint(.6475, .65);
    session = engine.passAndMove(session, runTarget: run).session;
    await _tapSpace(tester, run);
    const second = ScanPassPoint(.5675, .38);
    session = engine.touchTo(session, second).session;
    await _tapSpace(tester, second);
    expect(find.byKey(const ValueKey('flow-through')).hitTestable(),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('flow-through')));
    await tester.pumpAndSettle();
    expect(
        (_painter(tester).pendingPassTarget as ScanPassPoint).distanceTo(run),
        closeTo(0, .000001));
    const nextRun = ScanPassPoint(.8675, .38);
    session =
        engine.passAndMove(session, runTarget: nextRun, through: true).session;
    await _tapSpace(tester, nextRun);
    _expectState(_state(tester), session.state);
    expect(session.goalDemonstrated, isTrue);
    expect(session.state.completedPasses,
        engine.start(FlowEngine.catalog[6]).state.completedPasses + 2);
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
        {Key? key, Duration execution = Duration.zero, double textScale = 1}) =>
    MaterialApp(
      key: key,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!),
      home: ScanPassFlowScreen(
          observationDuration: Duration.zero, executionDuration: execution),
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
