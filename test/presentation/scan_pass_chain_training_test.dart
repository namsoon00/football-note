import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_chain.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/scan_pass_game_screen.dart';

const _pitchKey = ValueKey('chain-pitch');
Widget _app({double scale = 1, bool dark = false, WidgetBuilder? freeAttack}) =>
    MaterialApp(
      theme: dark ? ThemeData.dark() : ThemeData.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: TouchChainTrainingScreen(seed: 0, freeAttackBuilder: freeAttack),
    );

dynamic _painter(WidgetTester tester) => tester
    .widget<CustomPaint>(
        find.byKey(const ValueKey('chain-painter'), skipOffstage: false))
    .painter;
ChainState _state(WidgetTester tester) => _painter(tester).state as ChainState;
Offset _point(WidgetTester tester, ScanPassPoint point) {
  final rect = tester.getRect(find.byKey(_pitchKey));
  return Offset(rect.left + rect.width * (.06 + .88 * point.x),
      rect.top + rect.height * (.06 + .88 * point.y));
}

Future<void> _aim(WidgetTester tester, ScanPassPoint point) async {
  await tester.ensureVisible(find.byKey(_pitchKey));
  await tester.tapAt(_point(tester, point));
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _runFor(WidgetTester tester, double seconds) async {
  for (var i = 0; i < (seconds / .02).ceil(); i++) {
    await tester.pump(const Duration(milliseconds: 40));
  }
}

Future<void> _firstTouch(WidgetTester tester) async {
  await _aim(tester, const ScanPassPoint(.42, .42));
  await _tap(tester, 'chain-commit');
  await _runFor(tester, 3);
  expect(_state(tester).phase, ChainPhase.decide);
}

void main() {
  testWidgets(
      'first touch is planned before arrival, with distinct pointer and keyboard aims',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app());
    expect(_state(tester).phase, ChainPhase.prepareTouch);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('chain-commit')))
            .onPressed,
        isNull);
    await _aim(tester, const ScanPassPoint(.42, .42));
    var target = _painter(tester).selectedTarget as ScanPassPoint;
    expect(target.x, closeTo(.42, .001));
    expect(target.y, closeTo(.42, .001));
    expect(_state(tester).touchTarget, isNull);
    await _runFor(tester, 1);
    expect(_state(tester).elapsed, 0);
    await _aim(tester, const ScanPassPoint(.35, .56));
    target = _painter(tester).selectedTarget as ScanPassPoint;
    expect(target.x, closeTo(.35, .001));
    expect(target.y, closeTo(.56, .001));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    target = _painter(tester).selectedTarget as ScanPassPoint;
    expect(target.y, lessThan(.56));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(_state(tester).phase, ChainPhase.receiving);
    expect(_state(tester).touchTarget!.x, closeTo(target.x, .001));
    expect(find.byKey(const ValueKey('chain-outcome')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    semantics.dispose();
  });

  testWidgets('drag distance is bounded and short touches are retained',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.ensureVisible(find.byKey(_pitchKey));
    final start = _point(tester, const ScanPassPoint(.4, .54));
    final end = _point(tester, const ScanPassPoint(.43, .45));
    await tester.dragFrom(start, end - start);
    await tester.pump();
    final target = _painter(tester).selectedTarget as ScanPassPoint;
    expect(target.x, closeTo(.43, .015));
    expect(target.y, closeTo(.45, .015));
    await _aim(tester, const ScanPassPoint(.9, .10));
    final long = _painter(tester).selectedTarget as ScanPassPoint;
    expect(
        const TouchChainEngine()
            .distanceMetres(const ScanPassPoint(.4, .54), long),
        closeTo(3, .001));
    await _aim(tester, const ScanPassPoint(.40, .52));
    final short = _painter(tester).selectedTarget as ScanPassPoint;
    expect(short.y, closeTo(.52, .001));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'pass keeps control of 6 and requires a personal off-ball destination and next touch',
      (tester) async {
    await tester.pumpWidget(_app());
    await _firstTouch(tester);
    final touched = _state(tester);
    await _runFor(tester, 2);
    expect(_state(tester).elapsed, touched.elapsed);
    expect(_state(tester).action, isNull);
    await _tap(tester, 'chain-pass-8');
    expect(_state(tester).phase, ChainPhase.decide);
    await _tap(tester, 'chain-commit');
    await _runFor(tester, 3);
    expect(_state(tester).phase, ChainPhase.prepareRun);
    expect(_state(tester).pitch.carrierNumber, 8);
    expect(_state(tester).runTarget, isNull);
    expect(_state(tester).returns, 0);
    final oldSix = _state(tester)
        .pitch
        .attackers
        .firstWhere((p) => p.number == 6)
        .position;
    await _aim(tester, const ScanPassPoint(.48, .23));
    await _tap(tester, 'chain-commit');
    await _runFor(tester, 3);
    expect(_state(tester).phase, ChainPhase.prepareTouch);
    expect(_state(tester).returning, isTrue);
    expect(_state(tester).pitch.carrierNumber, 8);
    expect(_state(tester).returns, 0);
    final six = _state(tester).pitch.attackers.firstWhere((p) => p.number == 6);
    expect(six.position.distanceTo(oldSix), greaterThan(.1));
    final ball = _state(tester).pitch.ball;
    await _aim(tester, const ScanPassPoint(.46, .16));
    await _tap(tester, 'chain-commit');
    expect(_state(tester).phase, ChainPhase.receiving);
    expect(_state(tester).returns, 0);
    await _runFor(tester, .1);
    expect(_state(tester).pitch.ball.distanceTo(ball), greaterThan(.005));
    await _runFor(tester, 3);
    expect(_state(tester).returns, 1);
    expect(_state(tester).pitch.carrierNumber, 6);
    expect(_state(tester).phase, ChainPhase.decide);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'two return receptions finish the same player chain and show paired touch evidence',
      (tester) async {
    await tester.pumpWidget(_app());
    Future<void> commitPoint(ScanPassPoint point) async {
      await _aim(tester, point);
      await _tap(tester, 'chain-commit');
      await _runFor(tester, 3);
    }

    Future<void> pass(int number) async {
      await _tap(tester, 'chain-pass-$number');
      await _tap(tester, 'chain-commit');
      await _runFor(tester, 3);
    }

    await commitPoint(const ScanPassPoint(.46, .43));
    await pass(8);
    await commitPoint(const ScanPassPoint(.55, .60));
    expect(_state(tester).phase, ChainPhase.prepareTouch);
    await commitPoint(const ScanPassPoint(.50, .63));
    expect(_state(tester).returns, 1);
    await pass(4);
    await commitPoint(const ScanPassPoint(.28, .44));
    expect(_state(tester).phase, ChainPhase.prepareTouch);
    await commitPoint(const ScanPassPoint(.32, .41));
    expect(_state(tester).end, ChainEnd.linked);
    expect(_state(tester).returns, 2);
    expect(find.byKey(const ValueKey('chain-pressure-comparison')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('chain-lanes-comparison')), findsOneWidget);
    await _tap(tester, 'chain-moment-0');
    expect(_painter(tester).pitch.carrierNumber, 6);
    await _tap(tester, 'chain-moment-1');
    expect(_painter(tester).pitch, _state(tester).moments[1].pitch);
    await _tap(tester, 'chain-new-layout');
    expect(_state(tester).seed, 1);
    expect(_state(tester).returns, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('carry and shielding turn remain explicit next actions',
      (tester) async {
    await tester.pumpWidget(_app());
    await _firstTouch(tester);
    await _tap(tester, 'chain-mode-carry');
    await _aim(tester, const ScanPassPoint(.40, .33));
    await _tap(tester, 'chain-commit');
    expect(_state(tester).action!.kind, ChainActionKind.carry);
    await _runFor(tester, 2);
    expect(_state(tester).phase, ChainPhase.decide);
    expect(_painter(tester).selectedTarget, isNull);
    await _tap(tester, 'chain-mode-turn');
    await _aim(tester, const ScanPassPoint(.37, .34));
    await _tap(tester, 'chain-commit');
    expect(_state(tester).action!.kind, ChainActionKind.turn);
    await _runFor(tester, 2);
    expect(_state(tester).phase, ChainPhase.decide);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'pause, step, help, free attack and app background preserve reading time',
      (tester) async {
    await tester.pumpWidget(_app(
        freeAttack: (_) => const Scaffold(body: Text('Free attack fixture'))));
    await _aim(tester, const ScanPassPoint(.42, .42));
    await _tap(tester, 'chain-commit');
    await _runFor(tester, .12);
    await _tap(tester, 'chain-pause');
    final before = _state(tester).elapsed;
    await _runFor(tester, .5);
    expect(_state(tester).elapsed, before);
    await _tap(tester, 'chain-step');
    expect(_state(tester).elapsed, closeTo(before + .2, .001));
    await _tap(tester, 'chain-pause');
    await _tap(tester, 'chain-help');
    final helpTime = _state(tester).elapsed;
    await _runFor(tester, .5);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(_state(tester).elapsed, helpTime);
    await _tap(tester, 'chain-pause');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    final hidden = _state(tester).elapsed;
    await _runFor(tester, .5);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(_state(tester).elapsed, hidden);
    await _tap(tester, 'chain-pause');
    await _tap(tester, 'chain-free-attack');
    await tester.pumpAndSettle();
    final routeTime = _state(tester).elapsed;
    await _runFor(tester, 1);
    Navigator.of(tester.element(find.text('Free attack fixture'))).pop();
    await tester.pumpAndSettle();
    expect(_state(tester).elapsed, routeTime);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'failed touch reviews actual snapshots and retries the same geometry',
      (tester) async {
    await tester.pumpWidget(_app());
    await _aim(tester, const ScanPassPoint(.46, .62));
    await _tap(tester, 'chain-commit');
    await _runFor(tester, 3);
    expect(_state(tester).finished, isTrue);
    expect(find.byKey(const ValueKey('chain-outcome')), findsOneWidget);
    await _tap(tester, 'chain-moment-0');
    final dynamic painter = _painter(tester);
    expect(painter.pitch, _state(tester).moments.first.pitch);
    await _tap(tester, 'chain-replay');
    await _runFor(tester, .2);
    expect(_state(tester).elapsed, greaterThan(0));
    await _tap(tester, 'chain-retry');
    expect(_state(tester).phase, ChainPhase.prepareTouch);
    expect(_state(tester).seed, 0);
    expect(_state(tester).touchTarget, isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(568, 320),
    const Size(1280, 800)
  ]) {
    testWidgets('touch-chain pitch and controls fit $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
          _app(dark: size.width == 390, scale: size.width == 390 ? 1.3 : 1));
      await tester.pumpAndSettle();
      final pitch = tester.getSize(find.byKey(_pitchKey));
      expect(pitch.width / pitch.height, closeTo(1.5, .001));
      await _aim(tester, const ScanPassPoint(.42, .42));
      await tester.ensureVisible(find.byKey(const ValueKey('chain-commit')));
      final rect = tester.getRect(find.byKey(const ValueKey('chain-commit')));
      expect(rect.height, greaterThanOrEqualTo(48));
      expect(rect.right, lessThanOrEqualTo(size.width));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
