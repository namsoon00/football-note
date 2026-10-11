import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_attack.dart';
import 'package:football_note/domain/scan_pass/scan_pass_curriculum.dart';
import 'package:football_note/domain/scan_pass/scan_pass_flow.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart'
    show ScanPassPoint;

void main() {
  const engine = FlowEngine();
  AttackPlayer player(AttackState state, int number) =>
      state.attackers.firstWhere((p) => p.number == number);
  PracticeSession setup({
    FlowFocus focus = FlowFocus.supportAngle,
    List<AttackPlayer>? attackers,
    List<AttackPlayer>? defenders,
    bool firstTouch = false,
  }) {
    final team = attackers ??
        const [
          AttackPlayer(number: 6, position: ScanPassPoint(.15, .75)),
          AttackPlayer(number: 8, position: ScanPassPoint(.37, .75)),
        ];
    final state = AttackState(
        attackers: team,
        defenders: defenders ??
            const [
              AttackPlayer(
                  number: 2, opponent: true, position: ScanPassPoint(.85, .15)),
              AttackPlayer(
                  number: 3, opponent: true, position: ScanPassPoint(.90, .25)),
            ],
        ball: team.first.position,
        carrierNumber: 6,
        elapsed: 2);
    final base = FlowEngine.catalog.first.lesson;
    final started = engine.start(FlowCase(
        focus: focus,
        lesson: PracticeCase(
          id: 'test-world',
          skill: base.skill,
          variant: 0,
          stage: 2,
          offsideEnabled: false,
          gates: base.gates,
          learning: base.learning,
          observation: AttackTransition(
              before: state,
              after: state,
              action: const AttackAction.pass(6),
              duration: 0,
              ballEnd: state.ball,
              motionSamples: [state]),
        )));
    return PracticeSession(
        lesson: started.lesson,
        state: started.state,
        phase: firstTouch ? PracticePhase.firstTouch : PracticePhase.onBall,
        settings: started.settings,
        runTargets: started.runTargets,
        history: started.history);
  }

  test(
      'twelve defined cases start 2v2 with clear incoming passes and an escape',
      () {
    expect(FlowEngine.catalog, hasLength(12));
    expect(FlowEngine.catalog.map((c) => c.lesson.id).toSet(), hasLength(12));
    expect(FlowEngine.catalog.map((c) => c.focus).toSet(),
        FlowFocus.values.toSet());
    for (final item in FlowEngine.catalog) {
      final start = engine.start(item);
      expect(start.settings.freeFlow, isTrue);
      expect(start.settings.controlAllAttackers, isTrue);
      expect(start.settings.automaticSupport, isTrue);
      expect(start.settings.passAndMove, isFalse);
      expect(start.phase, PracticePhase.firstTouch);
      expect(start.state.attackers, hasLength(2));
      expect(start.state.defenders, hasLength(2));
      final teammate = start.state.attackers
          .firstWhere((p) => p.number != start.state.carrierNumber);
      expect(start.runTargets[teammate.number], isNotNull);
      expect(item.lesson.learning.rubric.requireThirdPlayer, isFalse);
      expect(item.lesson.learning.rubric.requireSwitch, isFalse);
      expect(item.lesson.learning.cues.length, greaterThanOrEqualTo(2));
      expect(item.lesson.offsideEnabled, isFalse);
      for (final frame in item.lesson.observation.motionSamples) {
        expect(
            PracticeEngine.nearestDefender(frame, frame.ball), greaterThan(.72),
            reason: '${item.lesson.id} opening ${frame.elapsed}');
      }
      var safeTouches = 0;
      for (var angle = 0; angle < 12; angle++) {
        final radians = angle * math.pi / 6;
        final target = start.state.ball +
            ScanPassPoint(
                math.cos(radians) *
                    FlowEngine.touchLimitMetres /
                    PracticeEngine.fieldLength,
                math.sin(radians) *
                    FlowEngine.touchLimitMetres /
                    PracticeEngine.fieldWidth);
        final step = engine.touchTo(start, target);
        if (step.session.outcome == null) {
          safeTouches++;
          expect(
              PracticeEngine.distanceMetres(teammate.position,
                  player(step.session.state, teammate.number).position),
              greaterThan(.02),
              reason:
                  '${item.lesson.id} teammate should move during first touch');
          expect(
              PracticeEngine.distanceMetres(
                  step.session.state.ball, engine.touchTarget(start, target)),
              lessThan(.008));
        }
      }
      expect(safeTouches, greaterThan(0), reason: item.lesson.id);
    }
  });

  test('every authored focus is achievable through automatic public controls',
      () {
    for (final item in FlowEngine.catalog) {
      final session = _findGoal(engine.start(item));
      expect(session, isNotNull, reason: item.lesson.id);
      expect(session!.goalDemonstrated, isTrue, reason: item.lesson.id);
      expect(
          session.decisions
              .any((d) => d.action.kind == PracticeActionKind.move),
          isFalse,
          reason: 'public auto support does not require selecting a runner');
      expect(session.goalDemonstrated, isTrue, reason: item.lesson.id);
    }
  });

  test(
      'touch range is physical and free in any direction; preview equals action',
      () {
    final start = setup(firstTouch: true);
    const far = ScanPassPoint(.70, .20);
    final bounded = engine.touchTarget(start, far);
    expect(PracticeEngine.distanceMetres(start.state.ball, bounded),
        closeTo(2.3, 1e-9));
    final touch = engine.touchTo(start, far);
    expect(touch.decision.action.target.distanceTo(bounded), closeTo(0, 1e-9));
    expect(touch.session.state.ball.distanceTo(bounded), closeTo(0, 1e-6));
    final backwards = engine.touchTo(start, const ScanPassPoint(.11, .78));
    expect(backwards.session.state.ball.x, lessThan(start.state.ball.x));
    expect(backwards.session.phase, PracticePhase.onBall);
    expect(() => engine.touchTo(start, const ScanPassPoint(double.nan, .4)),
        throwsArgumentError);
  });

  test('clicked carries are exact while automatic support moves independently',
      () {
    final start = setup();
    const carryTarget = ScanPassPoint(.45, .80);
    final carry = engine.moveTo(start, carryTarget);
    expect(carry.session.finished, isFalse);
    expect(
        carry.decision.action.target.distanceTo(carryTarget), closeTo(0, 1e-9));
    expect(PracticeEngine.distanceMetres(start.state.ball, carryTarget),
        greaterThan(5.8));
    expect(PracticeEngine.distanceMetres(carry.session.state.ball, carryTarget),
        lessThan(.008));
    expect(
        PracticeEngine.distanceMetres(player(carry.session.state, 8).position,
            player(start.state, 8).position),
        greaterThan(.05));
    expect(carry.decision.runTargetsBefore[8], isNotNull);
    const runTarget = ScanPassPoint(.68, .82);
    final run = engine.moveTo(start, runTarget, playerNumber: 8);
    expect(run.session.finished, isFalse);
    expect(run.decision.action.target.distanceTo(runTarget), closeTo(0, 1e-9));
    expect(
        PracticeEngine.distanceMetres(
            player(start.state, 8).position, runTarget),
        greaterThan(8));
    expect(
        PracticeEngine.distanceMetres(
            player(run.session.state, 8).position, runTarget),
        lessThan(.008));
    expect(
        run.session.state.ball.distanceTo(start.state.ball), closeTo(0, 1e-9));
    expect(run.transitions, hasLength(1));
  });

  test(
      'pass and support start together and pause at reception with the run pending',
      () {
    final start = setup();
    const destination = ScanPassPoint(.70, .85);
    final step = engine.passAndMove(start, runTarget: destination);
    expect(step.transitions, hasLength(1));
    expect(step.session.state.carrierNumber, 8);
    expect(step.session.phase, PracticePhase.firstTouch);
    expect(step.session.state.completedPasses, 1);
    expect(step.session.returnTarget, isNull);
    expect(
        step.session.runTargets[6]!.distanceTo(destination), closeTo(0, 1e-9));
    final frames = step.transitions.single.motionSamples;
    expect(player(frames[1], 6).position.x,
        greaterThan(player(frames.first, 6).position.x));
    expect(frames[1].ball.x, greaterThan(frames.first.ball.x));
    expect(
        PracticeEngine.distanceMetres(
            player(step.session.state, 6).position, destination),
        greaterThan(10),
        reason: 'reception does not finish the support run');
    expect(step.decision.goalDemonstrated, isFalse);
    for (final d in start.state.defenders) {
      expect(
          step.session.state.defenders
              .firstWhere((p) => p.number == d.number)
              .position
              .distanceTo(d.position),
          greaterThan(.001),
          reason: 'both opponents react during the same action');
    }
    final touch = engine.touchTo(step.session, const ScanPassPoint(.40, .75));
    expect(player(touch.session.state, 6).position.x,
        greaterThan(player(step.session.state, 6).position.x));
    expect(
        touch.session.runTargets[6]!.distanceTo(destination), closeTo(0, 1e-9));
    expect(touch.session.state.carrierNumber, 8);
    expect(touch.session.phase, PracticePhase.onBall);
    expect(touch.session.state.completedPasses, 1);
  });

  test('ordinary and through passes keep distinct automatic receiver targets',
      () {
    final start = setup(focus: FlowFocus.throughPass);
    final automaticRun = engine.throughTarget(start);
    expect(automaticRun, isNotNull);
    final ordinary = engine.pass(start);
    expect(ordinary.decision.action.kind, PracticeActionKind.pass);
    expect(
        PracticeEngine.distanceMetres(
            ordinary.decision.action.target, automaticRun!),
        greaterThan(1),
        reason: 'ordinary passes use a short receiving lead, not the run end');
    expect(
        PracticeEngine.distanceMetres(ordinary.decision.action.target,
            player(start.state, ordinary.decision.action.receiver!).position),
        lessThanOrEqualTo(1.61));
    const destination = ScanPassPoint(.45, .82);
    final first = engine.passAndMove(start, runTarget: destination).session;
    final touched =
        engine.touchTo(first, const ScanPassPoint(.40, .75)).session;
    expect(engine.throughTarget(touched)!.distanceTo(destination),
        closeTo(0, 1e-9));
    final returned = engine.passAndMove(touched,
        runTarget: touched.state.carrier.position, through: true);
    expect(returned.decision.action.kind, PracticeActionKind.through);
    expect(returned.decision.action.target.distanceTo(destination),
        closeTo(0, 1e-9));
    expect(returned.session.state.carrierNumber, 6);
    expect(returned.session.phase, PracticePhase.firstTouch);
    expect(returned.session.state.completedPasses, 2);
    expect(returned.session.runTargets.containsKey(6), isFalse);
    final returnedCarrier = player(returned.session.state, 6);
    expect(
        PracticeEngine.distanceMetres(
            returned.session.state.ball, returnedCarrier.position),
        lessThan(.08));
    expect(_speedMetres(returnedCarrier), greaterThan(.2),
        reason: 'the through-pass receiver keeps running after collection');
    final restored = engine.beforeDecision(returned.session, 2);
    expect(restored.runTargets.keys.toSet(), {6, 8});
    expect(restored.state, same(touched.state));
    final repeated = engine.passAndMove(restored,
        runTarget: touched.state.carrier.position, through: true);
    expect(repeated.session.state.elapsed, returned.session.state.elapsed);
    for (final p in returned.session.state.attackers) {
      expect(
          player(repeated.session.state, p.number)
              .position
              .distanceTo(p.position),
          closeTo(0, 1e-9));
    }
  });

  test('automatic support is deterministic and reacts to defender arrangement',
      () {
    final highCover = setup(defenders: const [
      AttackPlayer(
          number: 2, opponent: true, position: ScanPassPoint(.34, .72)),
      AttackPlayer(
          number: 3, opponent: true, position: ScanPassPoint(.58, .62)),
    ]);
    final lowCover = setup(defenders: const [
      AttackPlayer(
          number: 2, opponent: true, position: ScanPassPoint(.34, .78)),
      AttackPlayer(
          number: 3, opponent: true, position: ScanPassPoint(.58, .90)),
    ]);
    expect(highCover.runTargets[8], isNotNull);
    expect(lowCover.runTargets[8], isNotNull);
    expect(highCover.runTargets[8]!.distanceTo(lowCover.runTargets[8]!),
        greaterThan(.02),
        reason: 'support target is derived from defender geometry');
    final repeated = setup(defenders: const [
      AttackPlayer(
          number: 2, opponent: true, position: ScanPassPoint(.34, .72)),
      AttackPlayer(
          number: 3, opponent: true, position: ScanPassPoint(.58, .62)),
    ]);
    expect(repeated.runTargets[8]!.distanceTo(highCover.runTargets[8]!),
        closeTo(0, 1e-9));
  });

  test('ordinary safe passes collect moving receivers without teleporting', () {
    for (final item in FlowEngine.catalog) {
      final start = engine.start(item);
      final touched = engine.touchTo(start, _safeTouch(start)).session;
      if (touched.finished) continue;
      final pass = engine.pass(touched);
      expect(pass.transitions.single.duration, greaterThan(0),
          reason: item.lesson.id);
      if (pass.session.outcome != null) continue;
      final receiver =
          player(pass.session.state, pass.session.state.carrierNumber);
      expect(_speedMetres(receiver), greaterThan(.2),
          reason: '${item.lesson.id} receiver should keep stride');
      expect(
          PracticeEngine.distanceMetres(
              pass.session.state.ball, receiver.position),
          lessThan(.08),
          reason: '${item.lesson.id} ball should settle at the receiver foot');
      final samples = pass.transitions.single.motionSamples;
      for (var i = 1; i < samples.length; i++) {
        final before = player(samples[i - 1], receiver.number);
        final after = player(samples[i], receiver.number);
        expect(PracticeEngine.distanceMetres(before.position, after.position),
            lessThan(.45),
            reason: '${item.lesson.id} sample $i moved continuously');
      }
    }
  });

  test('sampled frames turn faces through the shortest angle', () {
    final before = AttackState(
      attackers: const [
        AttackPlayer(
            number: 6,
            position: ScanPassPoint(.2, .5),
            facingRadians: math.pi - .08),
      ],
      defenders: const [
        AttackPlayer(
            number: 2, opponent: true, position: ScanPassPoint(.6, .5)),
      ],
      ball: const ScanPassPoint(.2, .5),
      carrierNumber: 6,
    );
    final after = AttackState(
      attackers: const [
        AttackPlayer(
            number: 6,
            position: ScanPassPoint(.22, .5),
            facingRadians: -math.pi + .08),
      ],
      defenders: const [
        AttackPlayer(
            number: 2, opponent: true, position: ScanPassPoint(.58, .5)),
      ],
      ball: const ScanPassPoint(.22, .5),
      carrierNumber: 6,
      elapsed: 1,
    );
    final mid = AttackTransition(
      before: before,
      after: after,
      action: const AttackAction.hold(),
      duration: 1,
      ballEnd: after.ball,
      motionSamples: [before, after],
    ).frame(.5);
    final facing = player(mid, 6).facingRadians.abs();
    expect(facing, greaterThan(3.0));
  });

  test('automatic pass swaps roles, preserves retry, and can still be stolen',
      () {
    final start = setup();
    final pass = engine.pass(start);
    expect(pass.decision.action.kind, PracticeActionKind.pass);
    expect(
        pass.decision.runTargetsBefore[start.state.carrierNumber], isNotNull);
    expect(pass.session.phase, PracticePhase.firstTouch);
    expect(pass.session.state.carrierNumber, 8);
    expect(pass.session.runTargets[start.state.carrierNumber], isNotNull);
    expect(
        PracticeEngine.distanceMetres(
            player(pass.transitions.single.motionSamples[1], 6).position,
            player(pass.transitions.single.motionSamples.first, 6).position),
        greaterThan(.001));
    final restored = engine.beforeDecision(pass.session, 0);
    final repeated = engine.pass(restored);
    expect(repeated.session.state.elapsed,
        closeTo(pass.session.state.elapsed, 1e-9));
    for (final p in pass.session.state.attackers) {
      expect(
          player(repeated.session.state, p.number)
              .position
              .distanceTo(p.position),
          closeTo(0, 1e-9));
    }

    final trapped = setup(attackers: const [
      AttackPlayer(number: 6, position: ScanPassPoint(.20, .50)),
      AttackPlayer(number: 8, position: ScanPassPoint(.60, .50)),
    ], defenders: const [
      AttackPlayer(
          number: 2, opponent: true, position: ScanPassPoint(.34, .54)),
      AttackPlayer(
          number: 3, opponent: true, position: ScanPassPoint(.70, .30)),
    ]);
    final stolen = engine.pass(trapped);
    expect(stolen.session.outcome, PracticeOutcome.intercepted);
    expect(stolen.session.stolenBy, 2);
  });

  test('automatic running alone does not earn support-angle credit', () {
    var session = engine.start(FlowEngine.catalog
        .firstWhere((item) => item.focus == FlowFocus.supportAngle));
    session = engine.touchTo(session, _safeTouch(session)).session;
    final before = player(session.state, 8).position;
    final held = engine.hold(session);
    expect(
        PracticeEngine.distanceMetres(
            before, player(held.session.state, 8).position),
        greaterThan(.05));
    expect(held.decision.action.kind, PracticeActionKind.hold);
    expect(held.decision.goalDemonstrated, isFalse);
  });

  test(
      'retry restores pending support plans and exactly repeats a combined pass',
      () {
    final start = setup();
    const destination = ScanPassPoint(.68, .85);
    final original = engine.passAndMove(start, runTarget: destination);
    final restored = engine.beforeDecision(original.session, 0);
    expect(restored.state, same(start.state));
    expect(restored.phase, start.phase);
    expect(restored.settings.freeFlow, isTrue);
    expect(restored.outcome, isNull);
    expect(restored.history, hasLength(start.history.length));
    expect(restored.runTargets[6]!.distanceTo(destination), closeTo(0, 1e-9));
    final repeated = engine.passAndMove(restored, runTarget: destination);
    expect(repeated.session.state.elapsed, original.session.state.elapsed);
    expect(repeated.transitions.single.motionSamples.length,
        original.transitions.single.motionSamples.length);
    for (var i = 0; i < original.transitions.single.motionSamples.length; i++) {
      final a = original.transitions.single.motionSamples[i];
      final b = repeated.transitions.single.motionSamples[i];
      expect(a.ball.distanceTo(b.ball), closeTo(0, 1e-9));
      for (final p in a.attackers) {
        expect(p.position.distanceTo(player(b, p.number).position),
            closeTo(0, 1e-9));
      }
    }
    final changed =
        engine.passAndMove(restored, runTarget: const ScanPassPoint(.15, .50));
    expect(player(changed.session.state, 6).position.y,
        lessThan(player(original.session.state, 6).position.y));
    expect(original.session.history.length, start.history.length + 1);
  });

  test(
      'steals really transfer possession; a moving ball alone cannot finish a gate',
      () {
    final trapped = setup(attackers: const [
      AttackPlayer(number: 6, position: ScanPassPoint(.20, .50)),
      AttackPlayer(number: 8, position: ScanPassPoint(.60, .50)),
    ], defenders: const [
      AttackPlayer(
          number: 2, opponent: true, position: ScanPassPoint(.34, .54)),
      AttackPlayer(
          number: 3, opponent: true, position: ScanPassPoint(.70, .30)),
    ]);
    final stolen =
        engine.passAndMove(trapped, runTarget: const ScanPassPoint(.20, .70));
    expect(stolen.session.outcome, PracticeOutcome.intercepted);
    expect(stolen.session.stolenBy, 2);
    expect(stolen.session.state.carrier.opponent, isTrue);
    expect(
        stolen.session.state.ball
            .distanceTo(stolen.session.state.carrier.position),
        closeTo(0, 1e-9));
    final gateWorld = setup(attackers: const [
      AttackPlayer(number: 6, position: ScanPassPoint(.75, .23)),
      AttackPlayer(number: 8, position: ScanPassPoint(.93, .23)),
    ], defenders: const [
      AttackPlayer(
          number: 2, opponent: true, position: ScanPassPoint(.20, .80)),
      AttackPlayer(
          number: 3, opponent: true, position: ScanPassPoint(.15, .70)),
    ]);
    final pass = engine.passAndMove(gateWorld, runTarget: gateWorld.state.ball);
    expect(pass.session.outcome, isNull);
    expect(pass.session.phase, PracticePhase.firstTouch);
    final carried = engine.moveTo(gateWorld, const ScanPassPoint(.94, .23));
    expect(carried.session.outcome, PracticeOutcome.gateReached);
    expect(carried.session.state.ball.x, closeTo(.88, 1e-9));
    expect(carried.decision.action.target.x, .94,
        reason:
            'a real event interrupts the requested path; its endpoint is not silently shortened');
  });
}

PracticeSession? _findGoal(PracticeSession start) {
  const engine = FlowEngine();
  var frontier = <PracticeSession>[start];
  final seen = <String>{};
  for (var depth = 0; depth <= 7; depth++) {
    final next = <PracticeSession>[];
    for (final session in frontier) {
      if (session.goalDemonstrated) return session;
      if (session.finished) continue;
      for (final step in _publicSteps(engine, session)) {
        final nextSession = step.session;
        if (nextSession.outcome == PracticeOutcome.intercepted ||
            nextSession.outcome == PracticeOutcome.offside) {
          continue;
        }
        final key = '${nextSession.phase}-${nextSession.state.carrierNumber}-'
            '${nextSession.state.ball.x.toStringAsFixed(3)}-'
            '${nextSession.state.ball.y.toStringAsFixed(3)}-'
            '${nextSession.decisions.length}';
        if (seen.add(key)) next.add(nextSession);
      }
    }
    frontier = next.take(90).toList();
  }
  return null;
}

Iterable<PracticeStep> _publicSteps(
    FlowEngine engine, PracticeSession session) sync* {
  if (session.phase == PracticePhase.firstTouch) {
    for (var angle = 0; angle < 12; angle++) {
      final radians = angle * math.pi / 6;
      final target = session.state.ball +
          ScanPassPoint(
            math.cos(radians) *
                FlowEngine.touchLimitMetres /
                PracticeEngine.fieldLength,
            math.sin(radians) *
                FlowEngine.touchLimitMetres /
                PracticeEngine.fieldWidth,
          );
      try {
        yield engine.touchTo(session, target);
      } catch (_) {}
    }
    return;
  }
  for (final target in const [
    ScanPassPoint(.88, .23),
    ScanPassPoint(.88, .77),
    ScanPassPoint(.62, .25),
    ScanPassPoint(.62, .75),
    ScanPassPoint(.50, .50),
  ]) {
    try {
      yield engine.moveTo(session, target);
    } catch (_) {}
  }
  try {
    yield engine.pass(session);
  } catch (_) {}
  if (engine.throughTarget(session) != null) {
    try {
      yield engine.pass(session, through: true);
    } catch (_) {}
  }
  try {
    yield engine.hold(session);
  } catch (_) {}
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

double _speedMetres(AttackPlayer player) => ScanPassPoint(
      player.velocity.x * PracticeEngine.fieldLength,
      player.velocity.y * PracticeEngine.fieldWidth,
    ).distance;
