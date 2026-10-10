import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_attack.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart'
    show ScanPassPoint;
import 'package:football_note/domain/scan_pass/scan_pass_possession_lesson.dart';

void main() {
  const engine = ScanPassPossessionLessonEngine();
  test('all possession branches use continuous real flights and carries', () {
    var count = 0;
    for (final item in ScanPassPossessionLessonEngine.catalog) {
      final scene =
          engine.scene(variant: item.variant, situation: item.situation);
      for (final branch in _branches(engine, engine.firstPhase(scene))) {
        count++;
        var previous = scene.initial;
        for (final t in branch.fullTransitions) {
          expect(_signature(t.before), _signature(previous));
          expect(t.after.elapsed, greaterThanOrEqualTo(t.before.elapsed));
          if (t.action.kind == AttackActionKind.pass &&
              !identical(t.before, scene.initial)) {
            expect(t.offside, isNotNull);
          }
          if (!t.after.finished) {
            expect(t.after.ball.distanceTo(t.after.carrier.position),
                lessThan(1e-8));
          }
          if (t.interceptorNumber != null) {
            final defender = t.after.defenders
                .firstWhere((p) => p.number == t.interceptorNumber);
            expect(
                ScanPassPossessionLessonEngine.distanceMetres(
                    t.after.ball, defender.position),
                lessThanOrEqualTo((defender.goalkeeper ? 1.5 : .90) + 1e-8));
          }
          if (t.action.kind == AttackActionKind.hold ||
              t.action.kind == AttackActionKind.carry) {
            for (final progress in [0.0, .25, .5, .75]) {
              final frame = t.frame(progress);
              expect(frame.ball.distanceTo(frame.carrier.position),
                  lessThan(1e-8));
            }
          }
          previous = t.after;
        }
      }
    }
    expect(count, greaterThanOrEqualTo(140));
  });
  test(
      'geometry rather than scene label determines outcomes and recommendations',
      () {
    for (final variant in ScanPassPossessionVariant.values) {
      final original = engine.scene(variant: variant);
      final relabeled = ScanPassPossessionScene(
          variant: variant == ScanPassPossessionVariant.pressure
              ? ScanPassPossessionVariant.cover
              : ScanPassPossessionVariant.pressure,
          initial: original.initial,
          reception: original.reception,
          spotlights: original.spotlights);
      final a = _branches(engine, engine.firstPhase(original));
      final b = _branches(engine, engine.firstPhase(relabeled));
      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].decisions, b[i].decisions);
        expect(a[i].outcome, b[i].outcome);
        expect(a[i].evidence, b[i].evidence);
        expect(a[i].transitions.map((t) => _signature(t.after)),
            b[i].transitions.map((t) => _signature(t.after)));
      }
      expect(engine.recommendedBranch(original).decisions,
          engine.recommendedBranch(relabeled).decisions);
    }
  });
  test('early first-touch loss has no fictitious link or support review', () {
    final original = engine.scene();
    final scene = ScanPassPossessionScene(
        variant: original.variant,
        initial: original.initial,
        spotlights: original.spotlights,
        reception: original.reception.copyWith(defenders: [
          for (final p in original.reception.defenders)
            p.number == 2
                ? p.copyWith(
                    position:
                        original.reception.ball + const ScanPassPoint(.008, 0))
                : p
        ]));
    final result = engine.choose(
        engine.firstPhase(scene), ScanPassPossessionChoice.turnForward);
    expect(result.branch, isNotNull);
    expect(result.after.end, AttackEnd.intercepted);
    expect(result.branch!.availableMoments, [
      ScanPassPossessionMoment.receive,
      ScanPassPossessionMoment.touch,
      ScanPassPossessionMoment.finish
    ]);
    expect(result.branch!.evidence,
        contains(ScanPassPossessionEvidence.pressureStayed));
  });
  test('offside is tested at kick and does not become a completed pass', () {
    final original = engine.scene();
    final before = original.reception.copyWith(attackers: [
      for (final p in original.reception.attackers)
        p.number == 9 ? p.copyWith(position: const ScanPassPoint(.96, .85)) : p
    ], defenders: [
      for (final p in original.reception.defenders)
        p.goalkeeper
            ? p
            : p.copyWith(
                position: ScanPassPoint(
                    p.number == 5
                        ? .7
                        : p.number == 3
                            ? .6
                            : .45,
                    .1))
    ]);
    final scene = ScanPassPossessionScene(
        variant: original.variant,
        initial: original.initial,
        reception: before,
        spotlights: original.spotlights);
    final point = ScanPassPossessionDecisionPoint(
        scene: scene,
        kind: ScanPassPossessionDecisionKind.nextAction,
        state: before,
        activeNumber: 6,
        choices: const [ScanPassPossessionChoice.passTo9],
        decisions: const [],
        history: const []);
    final result = engine.choose(point, ScanPassPossessionChoice.passTo9);
    expect(result.after.end, AttackEnd.offside);
    expect(result.transitions.single.offside!.atKick, same(before));
    expect(result.after.completedPasses, before.completedPasses);
  });
  test('each receiver connection shown in coaching survives the model flight',
      () {
    final scene = engine.scene();
    final branch = engine.recommendedBranch(scene);
    for (final t in branch.transitions) {
      final connections = engine.availableConnections(scene, t.after);
      expect(connections, isNot(contains(t.after.carrierNumber)));
      if (t.after.finished) expect(connections, isEmpty);
    }
    expect(engine.availableConnections(scene, branch.transitions.first.after),
        isNotEmpty);
  });
}

List<ScanPassPossessionBranch> _branches(
        ScanPassPossessionLessonEngine e, ScanPassPossessionDecisionPoint p) =>
    [
      for (final choice in p.choices)
        ...(() {
          final r = e.choose(p, choice);
          return r.branch != null ? [r.branch!] : _branches(e, r.nextPoint!);
        })(),
    ];
String _signature(AttackState s) => [
      s.ball.x,
      s.ball.y,
      s.carrierNumber,
      s.end,
      s.elapsed,
      s.completedPasses,
      s.actionCount,
      for (final p in [...s.attackers, ...s.defenders]) ...[
        p.number,
        p.opponent,
        p.goalkeeper,
        p.position.x,
        p.position.y,
        p.velocity.x,
        p.velocity.y,
        p.facingRadians
      ],
    ].join('|');
