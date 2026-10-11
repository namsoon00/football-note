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
      'catalog exposes learning objectives and actual 2 to 4 player progression',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();
    expect(find.byKey(const ValueKey('practice-catalog')), findsOneWidget);
    expect(find.text('2 attackers · 1 defenders'), findsNWidgets(4));
    expect(find.text('3 attackers · 2 defenders'), findsNWidgets(4));
    expect(find.text('4 attackers · 3 defenders'), findsNWidgets(2));
    expect(find.textContaining('Set up your next action'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('attack-start')), findsNothing);
    for (final lesson in PracticeEngine.catalog) {
      expect(
          find.byKey(ValueKey('practice-case-${lesson.id}')), findsOneWidget);
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
        final choice = engine.recommended(session);
        final expected = engine.choose(session, choice).session;
        await tester.tap(find.byKey(ValueKey('practice-action-${choice.id}')));
        await tester.pumpAndSettle();
        final state = _painter(tester).state as AttackState;
        if (expected.finished) {
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
        if (choice.kind == PracticeActionKind.carry ||
            choice.kind == PracticeActionKind.move) {
          await _tapPoint(tester, choice.target);
          session = engine.moveTo(session, choice.target).session;
        } else {
          await tester
              .tap(find.byKey(ValueKey('practice-action-${choice.id}')));
          await tester.pumpAndSettle();
          session = engine.choose(session, choice).session;
        }
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
      if (choice.kind == PracticeActionKind.carry ||
          choice.kind == PracticeActionKind.move) {
        await _tapPoint(tester, choice.target);
        session = engine.moveTo(session, choice.target).session;
      } else {
        await tester.tap(find.byKey(ValueKey('practice-action-${choice.id}')));
        await tester.pumpAndSettle();
        session = engine.choose(session, choice).session;
      }
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
    await tester.tap(find.byKey(const ValueKey('practice-case-firstTouch-0')));
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
}

Widget _app({Key? key, Duration observation = Duration.zero}) => MaterialApp(
      key: key,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ScanPassCurriculumScreen(
          observationDuration: observation, executionDuration: Duration.zero),
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
