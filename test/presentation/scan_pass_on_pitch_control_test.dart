import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_attack.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart'
    show ScanPassPoint;
import 'package:football_note/domain/scan_pass/scan_pass_possession_lesson.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/scan_pass_game_screen.dart';

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  for (final size in [
    const Size(320, 568),
    const Size(568, 320),
    const Size(1280, 800)
  ]) {
    testWidgets(
        'every scenario first-touch target is distinct and executes the intended action at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: const ScanPassPossessionLessonScreen(
            observationDuration: Duration.zero,
            executionDuration: Duration.zero),
      ));
      await tester.pumpAndSettle();
      const engine = ScanPassPossessionLessonEngine();
      for (final item in ScanPassPossessionLessonEngine.catalog) {
        final card = find.byKey(ValueKey('possession-card-${item.id}'));
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        await tester.tapAt(tester.getTopLeft(card) + const Offset(20, 20));
        await tester.pumpAndSettle();
        final scene =
            engine.scene(situation: item.situation, variant: item.variant);
        final point = engine.firstPhase(scene);
        final rects = <Rect>[];
        for (final choice in point.choices) {
          final control =
              find.byKey(ValueKey('possession-action-${choice.name}'));
          expect(control.hitTestable(), findsOneWidget,
              reason: '${item.id} ${choice.name}');
          final rect = tester.getRect(control);
          expect(rect.width, closeTo(48, 1e-7));
          expect(rect.height, closeTo(48, 1e-7));
          for (final other in rects) {
            expect(rect.overlaps(other), isFalse,
                reason: '${item.id}: choices must not overlap');
          }
          rects.add(rect);
        }
        await tester
            .tap(find.byKey(const ValueKey('possession-action-touchAway')));
        await tester.pumpAndSettle();
        final expected =
            engine.choose(point, ScanPassPossessionChoice.touchAway).after;
        final actual = _pitch(tester).displayState as AttackState;
        expect(
            ScanPassPossessionLessonEngine.distanceMetres(
                actual.ball, expected.ball),
            lessThan(1e-7),
            reason: item.id);
        expect(actual.carrierNumber, expected.carrierNumber);
        expect(actual.end, expected.end);
        await tester
            .tap(find.byKey(const ValueKey('possession-return-catalog')));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in [const Size(320, 568), const Size(568, 320)]) {
    testWidgets('support and hold targets remain separate at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ScanPassPossessionLessonScreen(
            observationDuration: Duration.zero,
            executionDuration: Duration.zero),
      ));
      await tester.pumpAndSettle();
      final card =
          find.byKey(const ValueKey('possession-card-centralReceive-pressure'));
      await tester.ensureVisible(card);
      await tester.tapAt(tester.getTopLeft(card) + const Offset(20, 20));
      await tester.pumpAndSettle();
      for (final key in ['touchAway', 'passTo9']) {
        await tester.tap(find.byKey(ValueKey('possession-action-$key')));
        await tester.pumpAndSettle();
      }
      final rects = <Rect>[];
      for (final key in [
        'supportInside',
        'supportWide',
        'supportBehind',
        'supportHold'
      ]) {
        final f = find.byKey(ValueKey('possession-action-$key'));
        expect(f.hitTestable(), findsOneWidget, reason: key);
        final rect = tester.getRect(f);
        for (final other in rects) {
          expect(rect.overlaps(other), isFalse, reason: key);
        }
        rects.add(rect);
      }
    });
  }

  testWidgets(
      'on-pitch arbitrary movement can retarget without rewinding any actor',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('ko'),
      home: ScanPassPossessionLessonScreen(observationDuration: Duration.zero),
    ));
    await tester.pumpAndSettle();
    final card =
        find.byKey(const ValueKey('possession-card-centralReceive-pressure'));
    await tester.ensureVisible(card);
    await tester.tapAt(tester.getTopLeft(card) + const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('possession-dock-touchAway')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('possession-action-touchAway')));
    await tester.pumpAndSettle();
    final pass = find.byKey(const ValueKey('possession-action-passTo8'));
    final receiver = (_pitch(tester).displayState as AttackState)
        .attackers
        .firstWhere((p) => p.number == 8);
    expect(
        (tester.getCenter(pass) - _offset(tester, receiver.position)).distance,
        lessThan(2));
    await tester.tap(pass);
    await tester.pumpAndSettle();
    final supportBefore = _pitch(tester).displayState as AttackState;
    final me =
        supportBefore.attackers.firstWhere((p) => p.number == 6).position;
    final first = ScanPassPoint(me.x + .061, me.y + .071);
    await tester.tapAt(_offset(tester, first));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    final prior = _pitch(tester).displayState as AttackState;
    expect(prior.elapsed, greaterThan(supportBefore.elapsed));
    final next = ScanPassPoint(me.x + .097, me.y - .083);
    await tester.tapAt(_offset(tester, next));
    await tester.pump();
    final after = _pitch(tester).displayState as AttackState;
    expect(after.elapsed, closeTo(prior.elapsed, .002));
    for (final p in [...prior.attackers, ...prior.defenders]) {
      final q = (p.opponent ? after.defenders : after.attackers)
          .firstWhere((q) => q.number == p.number);
      expect(
          ScanPassPossessionLessonEngine.distanceMetres(p.position, q.position),
          lessThan(.02),
          reason: 'Actor ${p.number} must not jump when retargeting');
    }
    expect(
        ScanPassPossessionLessonEngine.distanceMetres(prior.ball, after.ball),
        lessThan(.02));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

dynamic _pitch(WidgetTester tester) => tester
    .widget<CustomPaint>(find.byKey(const ValueKey('possession-pitch')))
    .painter;
Offset _offset(WidgetTester tester, ScanPassPoint p) {
  final rect = tester.getRect(find.byKey(const ValueKey('possession-pitch')));
  return rect.topLeft +
      Offset(rect.width * (.035 + .93 * p.x / 1.04),
          rect.height * (.065 + .86 * p.y));
}
