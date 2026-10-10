import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_attack.dart';
import 'package:football_note/domain/scan_pass/scan_pass_possession_lesson.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/scan_pass_game_screen.dart';

void main() {
  const engine = ScanPassPossessionLessonEngine();
  testWidgets(
      'all catalog cards open their actual distinct spatial configuration',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    for (final item in ScanPassPossessionLessonEngine.catalog) {
      final card = find.byKey(ValueKey('possession-card-${item.id}'));
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pumpAndSettle();
      final state = _pitch(tester).displayState as AttackState;
      final expected = engine
          .scene(situation: item.situation, variant: item.variant)
          .reception;
      expect(state.ball.x, closeTo(expected.ball.x, 1e-9), reason: item.id);
      expect(state.ball.y, closeTo(expected.ball.y, 1e-9), reason: item.id);
      for (final p in expected.defenders) {
        final actual = state.defenders.firstWhere((q) => q.number == p.number);
        expect(actual.position.x, closeTo(p.position.x, 1e-9), reason: item.id);
        expect(actual.position.y, closeTo(p.position.y, 1e-9), reason: item.id);
      }
      await tester.tap(find.byKey(const ValueKey('possession-return-catalog')));
      await tester.pumpAndSettle();
    }
  });

  testWidgets(
      'support labels report real metres with a decimal, not ten times the distance',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await _tapCard(tester);
    await tester.pumpAndSettle();
    final scene = engine.scene();
    var point = engine.firstPhase(scene);
    for (final choice in engine.recommendedBranch(scene).decisions) {
      if (point.kind == ScanPassPossessionDecisionKind.support) {
        final routes = _overlay(tester).routes as List;
        for (var i = 0; i < point.choices.length; i++) {
          final from =
              point.state.attackers.firstWhere((p) => p.number == 6).position;
          final to = engine.targetFor(point, point.choices[i]);
          final expected =
              ScanPassPossessionLessonEngine.distanceMetres(from, to);
          expect(routes[i].distanceMetres, closeTo(expected, 1e-8));
          expect(
              routes[i].label as String, contains(expected.toStringAsFixed(1)));
          final finder =
              find.byKey(ValueKey('possession-dock-${point.choices[i].name}'));
          expect(
              find.descendant(
                  of: finder,
                  matching: find.textContaining(expected.toStringAsFixed(1))),
              findsOneWidget);
        }
        return;
      }
      await tester.tap(find.byKey(ValueKey('possession-dock-${choice.name}')));
      await tester.pumpAndSettle();
      point = engine.choose(point, choice).nextPoint!;
    }
    fail('Recommended route must include a support decision');
  });

  testWidgets(
      'executing overlays advance with the actual return pass, not the preceding run',
      (tester) async {
    await tester.pumpWidget(_app(animated: true));
    await tester.pumpAndSettle();
    await _tapCard(tester);
    await tester.pumpAndSettle();
    final scene = engine.scene();
    var point = engine.firstPhase(scene);
    for (final choice in engine.recommendedBranch(scene).decisions) {
      final result = engine.choose(point, choice);
      await tester.tap(find.byKey(ValueKey('possession-dock-${choice.name}')));
      await tester.pump();
      if (point.kind == ScanPassPossessionDecisionKind.support) {
        await tester.pump(Duration(
            milliseconds:
                (result.transitions.first.duration * 1000).ceil() + 200));
        final active = _pitch(tester).activeTransition as AttackTransition;
        expect(active.action.kind, AttackActionKind.pass);
        final routes = _overlay(tester).routes as List;
        final pass = routes.where((dynamic r) => r.ballPath == true).single;
        expect(
            ScanPassPossessionLessonEngine.distanceMetres(
                pass.from, active.before.ball),
            lessThan(1e-8));
        expect(
            ScanPassPossessionLessonEngine.distanceMetres(
                pass.to, active.ballEnd),
            lessThan(1e-8));
        await tester.pumpAndSettle();
        return;
      }
      await tester.pumpAndSettle();
      point = result.nextPoint!;
    }
    fail('Expected a support and return sequence');
  });
  testWidgets(
      'manual pause survives background and slow mode preserves model timing',
      (tester) async {
    await tester.pumpWidget(_app(animated: true));
    await tester.pumpAndSettle();
    await _tapCard(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.byKey(const ValueKey('possession-pause')));
    await tester.pump();
    final paused = (_pitch(tester).displayState as AttackState).elapsed;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 2));
    expect((_pitch(tester).displayState as AttackState).elapsed, paused);
    await tester.tap(find.byKey(const ValueKey('possession-pause')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('possession-speed-toggle')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('possession-dock-touchAway')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('possession-pause')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    expect(
        find.byKey(const ValueKey('possession-dock-passTo9')), findsOneWidget);
  });

  testWidgets(
      'changing speed during motion takes effect without restarting the action',
      (tester) async {
    await tester.pumpWidget(_app(animated: true));
    await tester.pumpAndSettle();
    await _tapCard(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('possession-dock-touchAway')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final before = (_pitch(tester).displayState as AttackState).elapsed;
    await tester.tap(find.byKey(const ValueKey('possession-speed-toggle')));
    await tester.pump();
    expect((_pitch(tester).displayState as AttackState).elapsed,
        closeTo(before, .001));
    await tester.pump(const Duration(milliseconds: 200));
    final after = (_pitch(tester).displayState as AttackState).elapsed;
    expect(after - before, closeTo(.13, .015));
    await tester.pumpAndSettle();
  });

  testWidgets(
      'coach replay preserves own route and earlier review hides later trails',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await _tapCard(tester);
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('possession-dock-oneTouchLayoff')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('possession-dock-supportBehind')));
    await tester.pumpAndSettle();
    final mine = _pitch(tester).displayState as AttackState;
    await tester.tap(find.byKey(const ValueKey('possession-compare-coach')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('possession-replay')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('possession-compare-mine')));
    await tester.pumpAndSettle();
    expect(_pitch(tester).displayState, same(mine));
    await tester.tap(find.byKey(const ValueKey('possession-moment-touch')));
    await tester.pumpAndSettle();
    expect((_pitch(tester).history as List).length, 1);
  });

  for (final size in [const Size(320, 568), const Size(568, 320)]) {
    testWidgets(
        'every choice and review control is reachable at $size and large text',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(scale: 1.3));
      await tester.pumpAndSettle();
      await _tapCard(tester);
      await tester.pumpAndSettle();
      for (final key in [
        'possession-dock-touchAway',
        'possession-dock-turnForward',
        'possession-dock-oneTouchLayoff'
      ]) {
        final f = find.byKey(ValueKey(key));
        expect(f.hitTestable(), findsOneWidget);
        final r = tester.getRect(f);
        expect(r.left, greaterThanOrEqualTo(0));
        expect(r.right, lessThanOrEqualTo(size.width));
      }
      final bounds =
          tester.getRect(find.byKey(const ValueKey('possession-pitch')));
      await tester.tap(find.byKey(const ValueKey('possession-coach-demo')));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(const ValueKey('possession-pitch'))),
          bounds);
      for (final key in [
        'possession-return-catalog',
        'possession-retry',
        'possession-next-scenario'
      ]) {
        final f = find.byKey(ValueKey(key));
        expect(f.hitTestable(), findsOneWidget, reason: key);
        expect(tester.getRect(f).bottom, lessThanOrEqualTo(size.height),
            reason: key);
      }
      expect(tester.takeException(), isNull);
    });
  }
}

Widget _app({bool animated = false, double scale = 1}) => MaterialApp(
    builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: ScanPassPossessionLessonScreen(
        observationDuration: animated ? null : Duration.zero,
        executionDuration:
            animated ? const Duration(milliseconds: 1000) : Duration.zero));
dynamic _pitch(WidgetTester tester) => tester
    .widget<CustomPaint>(find.byKey(const ValueKey('possession-pitch')))
    .painter;
dynamic _overlay(WidgetTester tester) => tester
    .widget<CustomPaint>(find.byKey(const ValueKey('possession-route-overlay')))
    .painter;

Future<void> _tapCard(WidgetTester tester) async {
  final card =
      find.byKey(const ValueKey('possession-card-centralReceive-pressure'));
  await tester.ensureVisible(card);
  await tester.pumpAndSettle();
  await tester.tapAt(tester.getTopLeft(card) + const Offset(20, 20));
}
