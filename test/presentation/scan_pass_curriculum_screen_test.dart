import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_attack.dart';
import 'package:football_note/domain/scan_pass/scan_pass_curriculum.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/scan_pass_game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  const engine = PracticeEngine();

  testWidgets(
      'setup filters actual teams before a case and exposes passing modes',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();
    expect(find.byKey(const ValueKey('practice-catalog')), findsOneWidget);
    expect(find.text('2 attackers · 1 defenders'), findsNWidgets(4));
    expect(find.text('3 attackers · 2 defenders'), findsNothing);
    expect(find.text('4 attackers · 3 defenders'), findsNothing);
    expect(find.textContaining('Set up your next action'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('attack-start')), findsNothing);
    expect(find.byKey(const ValueKey('practice-mode-free')), findsOneWidget);
    expect(find.byKey(const ValueKey('practice-mode-return')), findsOneWidget);
    for (final count in [2, 3, 4]) {
      await tester.tap(find.byKey(ValueKey('practice-count-$count')));
      await tester.pumpAndSettle();
      for (final lesson in PracticeEngine.catalog) {
        expect(find.byKey(ValueKey('practice-case-${lesson.id}')),
            lesson.stage == count ? findsOneWidget : findsNothing);
      }
    }
  });

  for (final size in [
    const Size(1280, 800),
    const Size(390, 844),
    const Size(568, 320)
  ]) {
    testWidgets(
        'all twelve first-touch controls are separate and clickable at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final lesson in PracticeEngine.catalog) {
        await tester.pumpWidget(_app(key: ValueKey(lesson.id)));
        await tester.pump();
        await _open(tester, lesson.id);
        final buttons = _buttons();
        final rects = buttons
            .evaluate()
            .map((e) => tester.getRect(find.byWidget(e.widget)))
            .toList();
        for (var i = 0; i < rects.length; i++) {
          expect(rects[i].width, closeTo(48, .0001));
          expect(rects[i].height, closeTo(48, .0001));
          for (var j = i + 1; j < rects.length; j++) {
            // Circular controls must not overlap, and neither centre is obscured.
            expect((rects[i].center - rects[j].center).distance,
                greaterThanOrEqualTo(50.9));
          }
        }
        final session = engine.start(lesson);
        final visibleTargets =
            _painter(tester).touchOptions as List<PracticeAction>;
        expect(visibleTargets, hasLength(3));
        for (final target in visibleTargets) {
          final action =
              engine.choices(session).firstWhere((a) => a.id == target.id);
          expect(target.target.distanceTo(action.target), closeTo(0, .000001),
              reason: 'the drawn arrival ball is the actual action target');
        }
        final choice = engine.recommended(session);
        final expected = engine.choose(session, choice).session;
        await tester.tap(find.byKey(ValueKey('practice-action-${choice.id}')));
        await tester.pumpAndSettle();
        final state = _painter(tester).state as AttackState;
        if (expected.finished &&
            expected.outcome != PracticeOutcome.intercepted) {
          expect(state.ball, session.state.ball);
        } else {
          expect(state.ball.x, closeTo(expected.state.ball.x, .000001));
          expect(state.ball.y, closeTo(expected.state.ball.y, .000001));
        }
        expect(tester.takeException(), isNull, reason: lesson.id);
      }
    });
  }

  testWidgets(
      'all twelve live paths retain player control and reach review on phone',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final lesson in PracticeEngine.catalog) {
      await tester.pumpWidget(_app(key: ValueKey('full-${lesson.id}')));
      await _open(tester, lesson.id);
      var session = engine.start(lesson);
      while (!session.finished) {
        final choice = engine.recommended(session);
        final buttons = _buttons()
            .evaluate()
            .map((e) => tester.getRect(find.byWidget(e.widget)))
            .toList();
        for (var i = 0; i < buttons.length; i++) {
          for (var j = i + 1; j < buttons.length; j++) {
            expect((buttons[i].center - buttons[j].center).distance,
                greaterThan(50),
                reason: lesson.id);
          }
        }
        session = await _perform(tester, session, choice);
        final shown = _painter(tester).state as AttackState;
        if (!session.finished) {
          expect(shown.ball.x, closeTo(session.state.ball.x, .00001),
              reason: '${lesson.id}: ${choice.id}');
          expect(shown.ball.y, closeTo(session.state.ball.y, .00001),
              reason: '${lesson.id}: ${choice.id}');
        }
        expect(tester.takeException(), isNull, reason: lesson.id);
      }
      expect(find.byKey(const ValueKey('practice-review')), findsOneWidget,
          reason: lesson.id);
    }
  });

  testWidgets(
      'metres keep the same screen scale on both axes in portrait and landscape',
      (tester) async {
    for (final size in [
      const Size(390, 844),
      const Size(1280, 800),
      const Size(568, 320)
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(_app(key: ValueKey(size)));
      await _open(tester, 'firstTouch-0');
      final rect = tester.getRect(find.byKey(const ValueKey('practice-pitch')));
      final dynamic painter = _painter(tester);
      final zero =
          painter.offsetFor(const ScanPassPoint(.3, .3), rect.size) as Offset;
      final x =
          painter.offsetFor(const ScanPassPoint(.55, .3), rect.size) as Offset;
      final y = painter.offsetFor(
          const ScanPassPoint(.3, .3 + 10 / 28), rect.size) as Offset;
      expect((x - zero).distance, closeTo((y - zero).distance, .000001));
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('empty-space click carries the learner and does not fire a pass',
      (tester) async {
    await tester.pumpWidget(_app());
    await _open(tester, 'firstTouch-0');
    var session = engine.start(PracticeEngine.catalog.first);
    final first = engine.recommended(session);
    session = engine.choose(session, first).session;
    await tester.tap(find.byKey(ValueKey('practice-action-${first.id}')));
    await tester.pumpAndSettle();
    const target = ScanPassPoint(.57, .83);
    final expected = engine.moveTo(session, target);
    await _tapPoint(tester, target);
    final state = _painter(tester).state as AttackState;
    if (!expected.session.finished) {
      expect(state.ball.x, closeTo(expected.session.state.ball.x, .000001));
      expect(state.carrierNumber, 6);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'full choices reach causal review; comparison preserves own record and retry',
      (tester) async {
    await tester.pumpWidget(_app());
    final lesson = PracticeEngine.catalog.first;
    await _open(tester, lesson.id);
    var session = engine.start(lesson);
    while (!session.finished) {
      final choice = engine.recommended(session);
      session = await _perform(tester, session, choice);
      expect(tester.takeException(), isNull);
    }
    expect(find.byKey(const ValueKey('practice-review')), findsOneWidget);
    expect(find.text('What to read'), findsWidgets);
    expect(find.text('What your choice changed'), findsWidgets);
    final own = _painter(tester).review as PracticeDecision;
    final compare = find.byKey(const ValueKey('practice-compare'));
    await tester.ensureVisible(compare);
    await tester.tap(compare);
    await tester.pumpAndSettle();
    expect(find.text('Another choice from the same moment'), findsOneWidget);
    expect((_painter(tester).review as PracticeDecision).before.ball.x,
        closeTo(own.before.ball.x, .000001));
    final continuation = find.byKey(const ValueKey('practice-continuation'));
    await tester.ensureVisible(continuation);
    await tester.tap(continuation);
    await tester.pumpAndSettle();
    expect(
        find.textContaining('Later decisions are an example'), findsOneWidget);
    await tester.ensureVisible(find.text('Back to my review'));
    await tester.tap(find.text('Back to my review'));
    await tester.pumpAndSettle();
    expect(identical(_painter(tester).review, own), isTrue);
    final retry = find.byKey(const ValueKey('practice-retry'));
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('practice-review')), findsNothing);
    expect(_buttons(), findsWidgets);
  });

  testWidgets(
      'background and help pause observation without advancing a decision',
      (tester) async {
    await tester.pumpWidget(_app(observation: const Duration(seconds: 3)));
    final card = find.byKey(const ValueKey('practice-case-firstTouch-0'));
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pump(const Duration(milliseconds: 250));
    final before = (_painter(tester).state as AttackState).elapsed;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 4));
    expect((_painter(tester).state as AttackState).elapsed,
        closeTo(before, .000001));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(_buttons(), findsWidgets);
  });

  for (final count in [2, 3, 4]) {
    testWidgets('$count attackers can be selected, assigned a run and stopped',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app());
      final lesson = PracticeEngine.catalog.firstWhere((c) => c.stage == count);
      await _open(tester, lesson.id);
      var session = engine.start(lesson);
      final touch = engine.recommended(session);
      session = engine.choose(session, touch).session;
      await tester.tap(find.byKey(ValueKey('practice-action-${touch.id}')));
      await tester.pumpAndSettle();
      final mover = session.state.attackers.last.number;
      final before = session.state;
      await tester.tap(find.byKey(const ValueKey('practice-position-mode')));
      await tester.pumpAndSettle();
      for (final p in before.attackers) {
        expect(find.byKey(ValueKey('practice-player-${p.number}')),
            findsOneWidget);
      }
      await tester.tap(find.byKey(ValueKey('practice-player-$mover')));
      await tester.pumpAndSettle();
      const target = ScanPassPoint(.90, .88);
      await _tapPoint(tester, target);
      session = engine.planRun(session, mover, target);
      final plans = _painter(tester).runTargets as Map<int, ScanPassPoint>;
      expect(plans[mover]!.distanceTo(session.runTargets[mover]!),
          closeTo(0, .000001));
      await tester.pump(const Duration(seconds: 3));
      expect((_painter(tester).state as AttackState).elapsed, before.elapsed,
          reason: 'setting a path does not secretly move anybody');
      await tester.tap(find.byKey(const ValueKey('practice-position-mode')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('practice-player-$mover')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('practice-cancel-run')));
      await tester.pumpAndSettle();
      expect((_painter(tester).runTargets as Map), isEmpty);
      expect((_painter(tester).state as AttackState).elapsed, before.elapsed);
      await _tapPoint(tester, target);
      await tester.tap(find.byKey(const ValueKey('practice-action-hold')));
      await tester.pumpAndSettle();
      final expected = engine.choose(
          session,
          engine
              .choices(session)
              .firstWhere((a) => a.kind == PracticeActionKind.hold));
      final shown = _painter(tester).state as AttackState;
      expect(shown.elapsed, closeTo(expected.session.state.elapsed, .000001));
      expect(
          shown.attackers.last.position
              .distanceTo(before.attackers.last.position),
          greaterThan(.001));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'pass and move returns control to receiver and restricts only the next target',
      (tester) async {
    await tester.pumpWidget(_app());
    final mode = find.byKey(const ValueKey('practice-mode-return'));
    await tester.ensureVisible(mode);
    await tester.tap(mode);
    await tester.pumpAndSettle();
    final lesson = PracticeEngine.catalog.firstWhere((c) => c.stage == 3);
    await _open(tester, lesson.id);
    var session = engine.start(lesson,
        settings: const PracticeSettings(passAndMove: true));
    final first = engine.recommended(session);
    session = engine.choose(session, first).session;
    await tester.tap(find.byKey(ValueKey('practice-action-${first.id}')));
    await tester.pumpAndSettle();
    final pass = engine.choices(session).firstWhere((a) =>
        a.kind == PracticeActionKind.pass &&
        !engine.choose(session, a).session.finished);
    final passer = session.state.carrierNumber;
    session = engine.choose(session, pass).session;
    await tester.tap(find.byKey(ValueKey('practice-action-${pass.id}')));
    await tester.pumpAndSettle();
    final after = _painter(tester).state as AttackState;
    expect(after.carrierNumber, pass.receiver);
    expect(
        find.byKey(ValueKey('practice-action-pass-$passer')), findsOneWidget);
    for (final p in after.attackers
        .where((p) => p.number != after.carrierNumber && p.number != passer)) {
      expect(find.byKey(ValueKey('practice-action-pass-${p.number}')),
          findsNothing);
      expect(find.byKey(ValueKey('practice-action-through-${p.number}')),
          findsNothing);
    }
    await tester.pump(const Duration(seconds: 4));
    expect((_painter(tester).state as AttackState).elapsed, after.elapsed);
    expect((_painter(tester).state as AttackState).completedPasses,
        after.completedPasses);
    expect(find.textContaining('Next pass → $passer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'a steal shows defensive possession immediately in the final frame',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app());
    await _open(tester, 'firstTouch-0');
    var session = engine.start(PracticeEngine.catalog.first);
    final first = engine.recommended(session);
    session = engine.choose(session, first).session;
    await tester.tap(find.byKey(ValueKey('practice-action-${first.id}')));
    await tester.pumpAndSettle();
    while (!session.finished) {
      final hold = engine
          .choices(session)
          .firstWhere((a) => a.kind == PracticeActionKind.hold);
      session = engine.choose(session, hold).session;
      await tester.tap(find.byKey(const ValueKey('practice-action-hold')));
      await tester.pumpAndSettle();
    }
    expect(session.outcome, PracticeOutcome.intercepted);
    final shown = _painter(tester).state as AttackState;
    expect(shown.carrierIsDefender, isTrue);
    expect(shown.carrier.opponent, isTrue);
    expect(_painter(tester).portrait, isTrue,
        reason: 'opening review must not rotate a portrait field');
    expect(PracticeEngine.distanceMetres(shown.ball, shown.carrier.position),
        lessThan(.66));
    expect(find.text('Defender ${shown.carrierNumber} won the ball'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('practice-review')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'whole-play replay does not project a later run plan onto earlier frames',
      (tester) async {
    await tester.pumpWidget(_app(execution: const Duration(milliseconds: 350)));
    await _open(tester, 'firstTouch-0');
    var session = engine.start(PracticeEngine.catalog.first);
    final first = engine.recommended(session);
    session = await _perform(tester, session, first);
    await tester.tap(find.byKey(const ValueKey('practice-position-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('practice-player-8')));
    await tester.pumpAndSettle();
    const target = ScanPassPoint(.9, .88);
    await _tapPoint(tester, target);
    session = engine.planRun(session, 8, target);
    while (!session.finished) {
      final hold = engine
          .choices(session)
          .firstWhere((a) => a.kind == PracticeActionKind.hold);
      session = await _perform(tester, session, hold);
    }
    expect(session.outcome, PracticeOutcome.intercepted);
    expect((_painter(tester).runTargets as Map), isNotEmpty,
        reason: 'the reviewed decision still shows the plan that caused it');
    final replay = find.byKey(const ValueKey('practice-replay'));
    await tester.ensureVisible(replay);
    await tester.tap(replay);
    await tester.pump(const Duration(milliseconds: 20));
    expect((_painter(tester).state as AttackState).elapsed,
        lessThan(session.state.elapsed));
    expect((_painter(tester).runTargets as Map), isEmpty,
        reason: 'a later queued plan did not exist at the opening reception');
    await tester.pumpAndSettle();
    expect((_painter(tester).runTargets as Map), isNotEmpty);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(
        {Key? key,
        Duration observation = Duration.zero,
        Duration execution = Duration.zero}) =>
    MaterialApp(
      key: key,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ScanPassCurriculumScreen(
          observationDuration: observation, executionDuration: execution),
    );
Finder _buttons() => find.byWidgetPredicate((widget) =>
    widget is OutlinedButton &&
    widget.key is ValueKey<String> &&
    (widget.key! as ValueKey<String>).value.startsWith('practice-action-'));
dynamic _painter(WidgetTester tester) => tester
    .widget<CustomPaint>(find.byKey(const ValueKey('practice-pitch-paint')))
    .painter;
Future<void> _open(WidgetTester tester, String id) async {
  await tester.pump();
  final count = PracticeEngine.catalog.firstWhere((c) => c.id == id).stage;
  final chip = find.byKey(ValueKey('practice-count-$count'));
  await tester.ensureVisible(chip);
  await tester.tap(chip);
  await tester.pumpAndSettle();
  final card = find.byKey(ValueKey('practice-case-$id'));
  await tester.ensureVisible(card);
  await tester.tap(card);
  await tester.pumpAndSettle();
}

Future<void> _tapPoint(WidgetTester tester, ScanPassPoint target) async {
  final rect = tester.getRect(find.byKey(const ValueKey('practice-pitch')));
  final point =
      rect.topLeft + (_painter(tester).offsetFor(target, rect.size) as Offset);
  await tester.tapAt(point);
  await tester.pumpAndSettle();
}

Future<PracticeSession> _perform(
    WidgetTester tester, PracticeSession session, PracticeAction action) async {
  const engine = PracticeEngine();
  if (action.kind == PracticeActionKind.carry ||
      action.kind == PracticeActionKind.move) {
    final actor = action.actorNumber ?? session.state.carrierNumber;
    await tester.tap(find.byKey(const ValueKey('practice-position-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('practice-player-$actor')));
    await tester.pumpAndSettle();
    await _tapPoint(tester, action.target);
    if (action.kind == PracticeActionKind.move) {
      session = engine.planRun(session, actor, action.target);
      final planned = PracticeAction(
          id: 'run-$actor',
          kind: PracticeActionKind.move,
          actorNumber: actor,
          target: session.runTargets[actor]!);
      await tester.tap(find.byKey(ValueKey('practice-action-run-$actor')));
      await tester.pumpAndSettle();
      return engine.choose(session, planned).session;
    }
    return engine.moveTo(session, action.target, playerNumber: actor).session;
  }
  await tester.tap(find.byKey(ValueKey('practice-action-${action.id}')));
  await tester.pumpAndSettle();
  return engine.choose(session, action).session;
}
