import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_attack.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart'
    show ScanPassPoint;
import 'package:football_note/domain/scan_pass/scan_pass_possession_lesson.dart';

void main() {
  const engine = ScanPassPossessionLessonEngine();

  test(
      'catalog has twelve playable situations with six distinct spatial problems',
      () {
    const catalog = ScanPassPossessionLessonEngine.catalog;
    expect(catalog.length, 12);
    expect(catalog.map((s) => s.id).toSet().length, 12);
    final origins = <String>{};
    for (final item in catalog) {
      final scene =
          engine.scene(situation: item.situation, variant: item.variant);
      origins.add('${scene.reception.ball.x}/${scene.reception.ball.y}');
      expect(scene.situation, item.situation);
      expect(scene.reception.carrierNumber, 6);
      expect(scene.observation.duration, inExclusiveRange(.4, 1.5));
      expect(scene.observation.after, same(scene.reception));
    }
    expect(origins.length, 6);
  });

  test(
      'recommended attacks connect from reception to a real shot or safe reset',
      () {
    var shots = 0;
    for (final item in ScanPassPossessionLessonEngine.catalog) {
      final scene =
          engine.scene(situation: item.situation, variant: item.variant);
      final branch = engine.recommendedBranch(scene);
      expect(branch.recommended, isTrue);
      expect(branch.outcome, isNot(ScanPassPossessionOutcomeKind.turnover),
          reason: item.id);
      if (branch.outcome == ScanPassPossessionOutcomeKind.chanceCreated) {
        shots++;
        expect(branch.transitions.last.action.kind, AttackActionKind.shoot);
        expect(branch.finalState.end,
            anyOf(AttackEnd.goal, AttackEnd.saved, AttackEnd.blocked));
        expect(branch.evidence,
            contains(ScanPassPossessionEvidence.supportConnected));
      } else {
        expect(branch.finalState.carrierNumber, 4);
        expect(branch.finalState.finished, isFalse);
      }
      final transitions = branch.fullTransitions;
      for (var i = 1; i < transitions.length; i++) {
        expect(transitions[i].before, same(transitions[i - 1].after));
      }
      // A useful return can add another learner pass and support run.
      expect(branch.decisions.length, lessThanOrEqualTo(5));
      expect(
          transitions.fold<double>(0, (s, t) => s + t.duration), lessThan(20));
    }
    expect(shots, greaterThanOrEqualTo(8));
  });

  test(
      'defensive variations change decisions without moving the opening attackers',
      () {
    var differentFirstTouches = 0;
    for (final situation in ScanPassPossessionSituation.values) {
      final press = engine.scene(situation: situation);
      final cover = engine.scene(
          situation: situation, variant: ScanPassPossessionVariant.cover);
      expect(press.initial.attackers.map((p) => p.position.x),
          cover.initial.attackers.map((p) => p.position.x));
      expect(press.initial.attackers.map((p) => p.position.y),
          cover.initial.attackers.map((p) => p.position.y));
      expect(press.reception.defenders.first.position.x,
          isNot(cover.reception.defenders.first.position.x));
      if (engine.recommendedBranch(press).decisions.first !=
          engine.recommendedBranch(cover).decisions.first) {
        differentFirstTouches++;
      }
    }
    expect(differentFirstTouches, greaterThanOrEqualTo(3));
  });

  test('support direction and metre distance match the learner actual run', () {
    var checked = 0;
    for (final item in ScanPassPossessionLessonEngine.catalog) {
      final scene =
          engine.scene(situation: item.situation, variant: item.variant);
      final branch = engine.recommendedBranch(scene);
      var point = engine.firstPhase(scene);
      for (final choice in branch.decisions) {
        if (point.kind == ScanPassPossessionDecisionKind.support) {
          expect(point.activeNumber, 6);
          expect(point.state.carrierNumber, isNot(6));
          final origins =
              point.state.attackers.firstWhere((p) => p.number == 6).position;
          final destinations = <String>{};
          for (final option in point.choices) {
            final target = engine.targetFor(point, option);
            destinations.add('${target.x}/${target.y}');
            final run = engine.choose(point, option).transitions.first;
            if (!run.after.finished) {
              final end =
                  run.after.attackers.firstWhere((p) => p.number == 6).position;
              expect(ScanPassPossessionLessonEngine.distanceMetres(end, target),
                  lessThan(1e-7));
              final expected = ScanPassPossessionLessonEngine.distanceMetres(
                  origins, target);
              var travelled = 0.0;
              for (var i = 1; i < run.motionSamples.length; i++) {
                final a = run.motionSamples[i - 1].attackers
                    .firstWhere((p) => p.number == 6)
                    .position;
                final b = run.motionSamples[i].attackers
                    .firstWhere((p) => p.number == 6)
                    .position;
                travelled +=
                    ScanPassPossessionLessonEngine.distanceMetres(a, b);
              }
              expect(travelled, closeTo(expected, 1e-7));
              if (option == ScanPassPossessionChoice.supportHold) {
                expect(travelled, lessThan(1e-7));
              } else {
                expect(travelled, inInclusiveRange(3, 9));
              }
              checked++;
            }
          }
          expect(destinations.length, 4);
        }
        final result = engine.choose(point, choice);
        if (result.nextPoint == null) break;
        point = result.nextPoint!;
      }
    }
    expect(checked, greaterThan(15));
  });

  test('distances use pitch dimensions rather than pixels or normalized length',
      () {
    expect(
        ScanPassPossessionLessonEngine.distanceMetres(
            const ScanPassPoint(0, 0), const ScanPassPoint(1, 0)),
        105);
    expect(
        ScanPassPossessionLessonEngine.distanceMetres(
            const ScanPassPoint(0, 0), const ScanPassPoint(0, 1)),
        68);
    expect(
        ScanPassPossessionLessonEngine.distanceMetres(
            const ScanPassPoint(.4, .4),
            const ScanPassPoint(.4 + 3 / 105, .4 + 4 / 68)),
        closeTo(5, 1e-8));
  });

  test('arbitrary support targets are bounded and preserved in replay data',
      () {
    final scene =
        engine.scene(situation: ScanPassPossessionSituation.thirdPlayer);
    final point = _firstSupportPoint(engine, scene);
    final origin = _attacker(point.state, 6).position;
    final rawTarget = ScanPassPoint(origin.x + .037, origin.y - .029);
    final bounded = engine.boundedSupportTarget(rawTarget);

    final result = engine.chooseSupportTarget(point, rawTarget);
    expect(result.choice, ScanPassPossessionChoice.supportCustom);
    expect(result.decisionTarget!.distanceTo(bounded), lessThan(1e-12));
    final run = result.transitions.first;
    expect(run.action.kind, AttackActionKind.hold);
    expect(
      ScanPassPossessionLessonEngine.distanceMetres(
        _attacker(run.after, 6).position,
        bounded,
      ),
      lessThan(1e-7),
    );
    final storedTargets =
        result.branch?.decisionTargets ?? result.nextPoint!.decisionTargets;
    expect(storedTargets.last!.distanceTo(bounded), lessThan(1e-12));
    for (final preset in point.choices) {
      if (preset == ScanPassPossessionChoice.supportHold) continue;
      expect(
        ScanPassPossessionLessonEngine.distanceMetres(
          bounded,
          engine.targetFor(point, preset),
        ),
        greaterThan(.5),
      );
    }
  });

  test('support hold keeps number 6 still while the possession keeps moving',
      () {
    final scene = engine.scene(situation: ScanPassPossessionSituation.layoff);
    final point = _firstSupportPoint(engine, scene);
    final origin = _attacker(point.state, 6).position;

    final result = engine.chooseSupportHold(point);
    final run = result.transitions.first;

    expect(result.choice, ScanPassPossessionChoice.supportHold);
    expect(run.duration, greaterThanOrEqualTo(.75));
    expect(_attacker(run.after, 6).position.distanceTo(origin), lessThan(1e-8));
    expect(run.after.elapsed, greaterThan(run.before.elapsed));
    expect(
      run.motionSamples.any((sample) => sample.defenders.any((defender) =>
          ScanPassPossessionLessonEngine.distanceMetres(
            defender.position,
            run.before.defenders
                .firstWhere((before) => before.number == defender.number)
                .position,
          ) >
          .05)),
      isTrue,
    );
  });

  test('teammates use conditional return or forward continuation from geometry',
      () {
    var sawReturn = false;
    var sawForward = false;
    for (final item in ScanPassPossessionLessonEngine.catalog) {
      final scene =
          engine.scene(situation: item.situation, variant: item.variant);
      for (final point in _supportPoints(engine, scene)) {
        for (final choice in point.choices) {
          final result = engine.choose(point, choice);
          final afterSupport = result.transitions.skip(1).toList();
          final returned = result.nextPoint != null &&
              afterSupport.any((transition) =>
                  transition.action.kind == AttackActionKind.pass &&
                  transition.action.targetNumber == 6 &&
                  !transition.after.finished);
          if (returned) {
            sawReturn = true;
            final returnPass = afterSupport.firstWhere((transition) =>
                transition.action.kind == AttackActionKind.pass &&
                transition.action.targetNumber == 6);
            expect(result.nextPoint!.kind,
                ScanPassPossessionDecisionKind.nextAction);
            expect(result.nextPoint!.state.carrierNumber, 6);
            expect(result.nextPoint!.choices,
                contains(ScanPassPossessionChoice.passTo8));
            expect(
              _pressureGap(result.nextPoint!.state),
              greaterThan(1.7),
            );
            expect(
              engine
                  .availableConnections(scene, returnPass.after)
                  .where((number) => number != returnPass.before.carrierNumber),
              isNotEmpty,
            );
          } else if (afterSupport.any((transition) =>
              !transition.after.finished &&
              (transition.action.kind == AttackActionKind.carry ||
                  transition.action.kind == AttackActionKind.shoot ||
                  (transition.action.kind == AttackActionKind.pass &&
                      transition.action.targetNumber != 4)))) {
            sawForward = true;
          }
        }
      }
    }
    expect(sawReturn, isTrue);
    expect(sawForward, isTrue);
  });

  test('retargeted support preserves traversed route and continuous time', () {
    final scene =
        engine.scene(situation: ScanPassPossessionSituation.touchline);
    final point = _firstSupportPoint(engine, scene);
    final firstRun = engine
        .choose(point, ScanPassPossessionChoice.supportWide)
        .transitions
        .first;
    final mid = firstRun.frame(.42);
    final partial = AttackTransition(
      before: firstRun.before,
      after: mid,
      action: firstRun.action,
      duration: mid.elapsed - firstRun.before.elapsed,
      ballEnd: mid.ball,
      motionSamples: [firstRun.before, mid],
    );
    final retargetPoint = ScanPassPossessionDecisionPoint(
      scene: point.scene,
      kind: ScanPassPossessionDecisionKind.support,
      state: mid,
      activeNumber: 6,
      choices: point.choices,
      decisions: point.decisions,
      decisionTargets: point.decisionTargets,
      history: [...point.history, partial],
    );
    final target = engine.boundedSupportTarget(
      ScanPassPoint(_attacker(mid, 6).position.x + .045,
          _attacker(mid, 6).position.y + .035),
    );

    final result = engine.chooseSupportTarget(retargetPoint, target);
    final all = result.branch?.transitions ?? result.nextPoint!.history;

    expect(all[point.history.length], same(partial));
    expect(result.transitions.first.before, same(partial.after));
    expect(result.transitions.first.before.elapsed, partial.after.elapsed);
    expect(
      ScanPassPossessionLessonEngine.distanceMetres(
        _attacker(result.transitions.first.after, 6).position,
        target,
      ),
      lessThan(1e-7),
    );
    final storedTargets =
        result.branch?.decisionTargets ?? result.nextPoint!.decisionTargets;
    expect(storedTargets.last!.distanceTo(target), lessThan(1e-12));
  });

  test(
      'replaying and comparing branches is deterministic and preserves choices',
      () {
    final scene =
        engine.scene(situation: ScanPassPossessionSituation.halfSpace);
    final coach = engine.recommendedBranch(scene);
    ScanPassPossessionBranch play() {
      var point = engine.firstPhase(scene);
      for (final choice in coach.decisions) {
        final result = engine.choose(point, choice);
        if (result.branch != null) return result.branch!;
        point = result.nextPoint!;
      }
      throw StateError('Unfinished route');
    }

    final first = play(), second = play();
    expect(first.recommended, isFalse);
    expect(first.decisions, coach.decisions);
    expect(
        first.transitions.map((t) =>
            '${t.after.ball.x}/${t.after.ball.y}/${t.after.end}/${t.duration}'),
        second.transitions.map((t) =>
            '${t.after.ball.x}/${t.after.ball.y}/${t.after.end}/${t.duration}'));
    expect(identical(first, coach), isFalse);
  });
}

Iterable<ScanPassPossessionDecisionPoint> _supportPoints(
  ScanPassPossessionLessonEngine engine,
  ScanPassPossessionScene scene,
) sync* {
  final firstPoint = engine.firstPhase(scene);
  for (final first in firstPoint.choices) {
    final firstResult = engine.choose(firstPoint, first);
    final secondPoint = firstResult.nextPoint;
    if (secondPoint == null) continue;
    if (secondPoint.kind == ScanPassPossessionDecisionKind.support) {
      yield secondPoint;
      continue;
    }
    for (final second in secondPoint.choices) {
      final secondResult = engine.choose(secondPoint, second);
      final supportPoint = secondResult.nextPoint;
      if (supportPoint?.kind == ScanPassPossessionDecisionKind.support) {
        yield supportPoint!;
      }
    }
  }
}

ScanPassPossessionDecisionPoint _firstSupportPoint(
  ScanPassPossessionLessonEngine engine,
  ScanPassPossessionScene scene,
) =>
    _supportPoints(engine, scene).first;

AttackPlayer _attacker(AttackState state, int number) =>
    state.attackers.firstWhere((player) => player.number == number);

double _pressureGap(AttackState state) => state.defenders
    .where((player) => !player.goalkeeper)
    .map((player) => ScanPassPossessionLessonEngine.distanceMetres(
        player.position, state.ball))
    .reduce((a, b) => a < b ? a : b);
