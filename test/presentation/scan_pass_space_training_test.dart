import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart';
import 'package:football_note/domain/scan_pass/scan_pass_space.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/scan_pass_game_screen.dart';

const _pitchKey = ValueKey('space-pitch');

Widget _app({Key? captureKey, double scale = 1, bool dark = false}) =>
    RepaintBoundary(
      key: captureKey,
      child: MaterialApp(
        theme: dark ? ThemeData.dark() : ThemeData.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const SpaceTrainingScreen(seed: 0),
      ),
    );

dynamic _painter(WidgetTester tester) => tester
    .widget<CustomPaint>(find.byKey(const ValueKey('space-painter')))
    .painter;

SpaceState _state(WidgetTester tester) => _painter(tester).state as SpaceState;

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

void main() {
  testWidgets('free ground aiming is neutral and requires an explicit action',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app());
    expect(_state(tester).pitch.attackers.length, 3);
    expect(_state(tester).pitch.defenders.length, 2);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('space-commit')))
            .onPressed,
        isNull);
    await _aim(tester, const ScanPassPoint(.46, .72));
    final state = _state(tester);
    expect(state.receiveTarget!.x, closeTo(.46, .001));
    expect(state.receiveTarget!.y, closeTo(.72, .001));
    expect(state.outcome, isNull);
    await _runFor(tester, 2);
    expect(_state(tester).elapsed, 0);
    await _aim(tester, const ScanPassPoint(.66, .34));
    expect(_state(tester).receiveTarget!.x, closeTo(.66, .001));
    expect(_state(tester).receiveTarget!.y, closeTo(.34, .001));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(_state(tester).receiveTarget!.x, lessThan(.66));
    expect(find.byKey(const ValueKey('space-outcome')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    semantics.dispose();
  });

  testWidgets(
      'the chosen run moves players; pause, stepping, help and background protect reading time',
      (tester) async {
    await tester.pumpWidget(_app());
    await _aim(tester, const ScanPassPoint(.43, .69));
    await _tap(tester, 'space-commit');
    await _runFor(tester, .4);
    expect(
        _state(tester)
            .pitch
            .attackers
            .firstWhere((p) => p.number == 6)
            .position
            .y,
        greaterThan(.5));
    await _tap(tester, 'space-pause');
    final before = _state(tester);
    await _runFor(tester, 1);
    expect(_state(tester).elapsed, before.elapsed);
    await _tap(tester, 'space-step');
    expect(_state(tester).elapsed, closeTo(before.elapsed + .2, .001));
    await _tap(tester, 'space-pause');
    await _tap(tester, 'space-help');
    final paused = _state(tester).elapsed;
    await _runFor(tester, 1);
    expect(_state(tester).elapsed, paused);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(_state(tester).elapsed, paused);
    await _tap(tester, 'space-pause');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    final hidden = _state(tester).elapsed;
    await _runFor(tester, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(_state(tester).elapsed, hidden);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'bad space is not homed to receiver and review preserves the actual choice',
      (tester) async {
    await tester.pumpWidget(_app());
    await _aim(tester, const ScanPassPoint(.90, .85));
    await _tap(tester, 'space-commit');
    await _tap(tester, 'space-commit');
    await _runFor(tester, 5);
    final result = _state(tester);
    expect(result.finished, isTrue);
    expect(result.outcome,
        anyOf(SpaceOutcome.unreachable, SpaceOutcome.intercepted));
    expect(result.receiveTarget!.x, closeTo(.90, .001));
    await _tap(tester, 'space-at-choice');
    expect(_state(tester).elapsed, lessThan(result.elapsed));
    await _tap(tester, 'space-at-arrival');
    expect(_state(tester), same(result));
    await _tap(tester, 'space-replay');
    await _runFor(tester, 6);
    expect(_state(tester), same(result));
    await _tap(tester, 'space-replay');
    await _runFor(tester, .2);
    expect(_state(tester).elapsed, lessThan(result.elapsed));
    await _runFor(tester, 6);
    expect(_state(tester), same(result));
    await _tap(tester, 'space-retry');
    expect(_state(tester).scenario.seed, result.scenario.seed);
    expect(_state(tester).elapsed, 0);
    expect(_painter(tester).previousTarget, result.receiveTarget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'incoming ball is painted between players at its actual flight point',
      (tester) async {
    final captureKey = GlobalKey();
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(captureKey: captureKey));
    await _aim(tester, const ScanPassPoint(.9, .85));
    await _tap(tester, 'space-commit');
    await _tap(tester, 'space-commit');
    await _runFor(tester, .28);
    final state = _state(tester);
    expect(state.ballInFlight, isTrue);
    final center = _point(tester, state.pitch.ball);
    final boundary =
        captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final capture = (await tester.runAsync(() async {
      final picture = await boundary.toImage(pixelRatio: 1);
      final pixels =
          (await picture.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      final result = (picture.width, pixels);
      picture.dispose();
      return result;
    }))!;
    final pixels = capture.$2;
    var white = 0;
    var black = 0;
    for (var y = center.dy.round() - 5; y <= center.dy.round() + 5; y++) {
      for (var x = center.dx.round() - 5; x <= center.dx.round() + 5; x++) {
        final at = (y * capture.$1 + x) * 4;
        final r = pixels.getUint8(at);
        final g = pixels.getUint8(at + 1);
        final b = pixels.getUint8(at + 2);
        if (r > 225 && g > 225 && b > 225) white++;
        if (r < 70 && g < 70 && b < 70) black++;
      }
    }
    expect(white, greaterThan(8));
    expect(black, greaterThan(4));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'receipt, first touch and next destination are three learner decisions',
      (tester) async {
    await tester.pumpWidget(_app());
    await _aim(tester, const ScanPassPoint(.56, .74));
    await _tap(tester, 'space-commit');
    await _runFor(tester, .6);
    await _tap(tester, 'space-commit');
    await _runFor(tester, 2);
    expect(_state(tester).phase, SpacePhase.received);
    expect(_state(tester).touchTarget, isNull);
    final received = _state(tester);
    await _runFor(tester, 2);
    expect(_state(tester).elapsed, received.elapsed);
    final at = received.pitch.carrier.position;
    await _aim(tester, ScanPassPoint(at.x + .08, at.y - .10));
    await _tap(tester, 'space-commit');
    await _runFor(tester, 2);
    expect(_state(tester).phase, SpacePhase.releasing);
    expect(_state(tester).passTarget, isNull);
    expect(_state(tester).pitch.carrierNumber, 6);
    final support =
        _state(tester).pitch.attackers.firstWhere((p) => p.number == 8);
    final lead = support.position.lerp(_state(tester).scenario.supportEnd, .72);
    await _aim(tester, lead);
    await _tap(tester, 'space-commit');
    await _runFor(tester, 3);
    expect(_state(tester).finished, isTrue);
    expect(_state(tester).outcome,
        anyOf(SpaceOutcome.open, SpaceOutcome.pressured));
    expect(_state(tester).pitch.carrierNumber, 8);
    await _tap(tester, 'space-new-layout');
    expect(_state(tester).scenario.seed, 1);
    expect(_state(tester).phase, SpacePhase.positioning);
    await tester.pumpWidget(const SizedBox());
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(568, 320),
    const Size(1280, 800)
  ]) {
    testWidgets('pitch geometry and touch controls stay usable at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
          _app(scale: size.width == 390 ? 1.3 : 1, dark: size.width == 390));
      await tester.pumpAndSettle();
      final pitch = tester.getSize(find.byKey(_pitchKey));
      expect(pitch.width / pitch.height, closeTo(1.5, .001));
      await _aim(tester, const ScanPassPoint(.43, .69));
      await tester.ensureVisible(find.byKey(const ValueKey('space-commit')));
      final action = tester.getRect(find.byKey(const ValueKey('space-commit')));
      expect(action.height, greaterThanOrEqualTo(48));
      expect(action.left, greaterThanOrEqualTo(0));
      expect(action.right, lessThanOrEqualTo(size.width));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
