import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_attack.dart';
import 'package:football_note/domain/scan_pass/scan_pass_curriculum.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart'
    show ScanPassPoint;

void main() {
  const engine = PracticeEngine();
  final lesson = PracticeEngine.catalog.first;
  AttackPlayer attacker(AttackState state, int number) =>
      state.attackers.firstWhere((p) => p.number == number);
  PracticeSession setup({
    PracticeSettings settings = const PracticeSettings(),
    PracticePhase phase = PracticePhase.onBall,
    PracticeCase? exercise,
    int carrier = 6,
    List<AttackPlayer>? players,
    List<AttackPlayer>? defenders,
  }) {
    final team = players ??
        const [
          AttackPlayer(number: 6, position: ScanPassPoint(.20, .30)),
          AttackPlayer(number: 8, position: ScanPassPoint(.36, .18)),
          AttackPlayer(number: 9, position: ScanPassPoint(.35, .42)),
          AttackPlayer(number: 4, position: ScanPassPoint(.17, .62)),
        ];
    return PracticeSession(
      lesson: exercise ?? lesson,
      settings: settings,
      state: AttackState(
        attackers: team,
        defenders: defenders ??
            const [
              AttackPlayer(
                  number: 2, opponent: true, position: ScanPassPoint(.90, .85)),
            ],
        carrierNumber: carrier,
        ball: team.firstWhere((p) => p.number == carrier).position,
        elapsed: 2,
      ),
      phase: phase,
    );
  }

  PracticeAction named(PracticeSession session, String id) =>
      engine.choices(session).firstWhere((a) => a.id == id);

  test('manual is default and every first touch identifies its real end point',
      () {
    for (final item in PracticeEngine.catalog) {
      expect(engine.start(item).settings.controlAllAttackers, isTrue);
    }
    final start = setup(phase: PracticePhase.firstTouch, carrier: 9);
    for (final choice in engine.choices(start)) {
      expect(choice.actorNumber, 9);
      final step = engine.choose(start, choice);
      expect(step.session.finished, isFalse);
      expect(step.transitions, hasLength(1));
      expect(
          PracticeEngine.distanceMetres(step.session.state.ball, choice.target),
          lessThan(.008));
      expect(step.session.state.carrierNumber, 9);
      for (final p in start.state.attackers.where((p) => p.number != 9)) {
        expect(
            attacker(step.session.state, p.number)
                .position
                .distanceTo(p.position),
            closeTo(0, 1e-9));
      }
    }
  });

  test(
      'manual coaching demonstrates each case through reproducible user actions',
      () {
    for (final item in PracticeEngine.catalog) {
      final initial = engine.start(item);
      expect(
          engine.choices(initial).any(
              (action) => !engine.choose(initial, action).session.finished),
          isTrue,
          reason: item.id);
      final complete = engine.coachRun(item);
      expect(complete.finished, isTrue, reason: item.id);
      expect(complete.settings.controlAllAttackers, isTrue);
      expect(complete.outcome,
          anyOf(PracticeOutcome.gateReached, PracticeOutcome.retained),
          reason: item.id);
      expect(complete.goalDemonstrated, isTrue, reason: item.id);
      expect(complete.decisions.length, lessThanOrEqualTo(16));
      expect(complete.history.length, complete.decisions.length + 1,
          reason: 'one user action produces one transition, never an AI turn');
      for (final decision in complete.decisions) {
        expect(decision.transitions, hasLength(1));
        expect(
            decision.before.attackers
                .any((p) => p.number == decision.action.actorNumber),
            isTrue);
      }
    }
  });

  test('completed pass transfers user control and never issues the next action',
      () {
    final start = setup();
    final release = engine.choose(start, named(start, 'pass-8'));
    expect(release.session.phase, PracticePhase.onBall);
    expect(release.session.state.carrierNumber, 8);
    expect(release.session.state.completedPasses, 1);
    expect(release.transitions, hasLength(1));
    for (final p in start.state.attackers) {
      expect(
          attacker(release.session.state, p.number)
              .position
              .distanceTo(p.position),
          closeTo(0, 1e-9));
    }
    expect(engine.choices(release.session).every((a) => a.actorNumber == 8),
        isTrue);
    expect(
        engine
            .choices(release.session)
            .where((a) => a.kind == PracticeActionKind.pass)
            .map((a) => a.receiver)
            .toSet(),
        {6, 9, 4});
    final wait = engine.choose(release.session, named(release.session, 'hold'));
    expect(wait.session.state.carrierNumber, 8);
    expect(wait.session.state.completedPasses, 1);
    expect(wait.transitions, hasLength(1));
    for (final p in release.session.state.attackers) {
      expect(
          attacker(wait.session.state, p.number)
              .position
              .distanceTo(p.position),
          closeTo(0, 1e-9));
    }
    expect(
        wait.session.state.defenders.first.position
            .distanceTo(release.session.state.defenders.first.position),
        greaterThan(.01));
  });

  test(
      'queued runs are bounded explicit plans; cancelling does not advance time',
      () {
    final start = setup();
    final plan = engine.planRun(start, 9, const ScanPassPoint(.9, .7));
    expect(plan.state, same(start.state));
    expect(plan.history, same(start.history));
    expect(plan.decisions, same(start.decisions));
    expect(
        PracticeEngine.distanceMetres(
            attacker(start.state, 9).position, plan.runTargets[9]!),
        closeTo(8, 1e-8));
    expect(start.runTargets, isEmpty);
    final canceled = engine.cancelRun(plan, 9);
    expect(canceled.runTargets, isEmpty);
    expect(canceled.state, same(start.state));
    final wait = engine.choose(plan, named(plan, 'hold'));
    expect(wait.session.state.elapsed - plan.state.elapsed, closeTo(.5, 1e-9));
    expect(attacker(wait.session.state, 9).position.x,
        greaterThan(attacker(start.state, 9).position.x));
    expect(
        attacker(wait.session.state, 8)
            .position
            .distanceTo(attacker(start.state, 8).position),
        closeTo(0, 1e-9));
    expect(wait.session.state.completedPasses, 0);
    expect(wait.decision.runTargetsBefore[9], same(plan.runTargets[9]));
    expect(() => engine.planRun(start, 6, const ScanPassPoint(.3, .3)),
        throwsArgumentError);
    expect(() => engine.planRun(start, 2, const ScanPassPoint(.3, .3)),
        throwsArgumentError);
    expect(() => engine.moveTo(start, const ScanPassPoint(double.nan, .4)),
        throwsArgumentError);
  });

  test(
      'moveTo uses selected attacker and carry uses the actual current carrier',
      () {
    final start = setup(carrier: 8);
    final carry = engine.moveTo(start, const ScanPassPoint(.8, .18));
    expect(carry.decision.action.actorNumber, 8);
    expect(carry.decision.action.kind, PracticeActionKind.carry);
    expect(
        PracticeEngine.distanceMetres(
            attacker(start.state, 8).position, carry.decision.action.target),
        closeTo(5.8, 1e-8));
    expect(
        PracticeEngine.distanceMetres(
            carry.session.state.ball, carry.decision.action.target),
        lessThan(.008));
    expect(
        attacker(carry.session.state, 6)
            .position
            .distanceTo(attacker(start.state, 6).position),
        closeTo(0, 1e-9));
    final movement =
        engine.moveTo(start, const ScanPassPoint(.46, .50), playerNumber: 9);
    expect(movement.decision.action.actorNumber, 9);
    expect(movement.decision.action.kind, PracticeActionKind.move);
    expect(
        movement.decision.distance,
        closeTo(
            PracticeEngine.distanceMetres(attacker(start.state, 9).position,
                movement.decision.action.target),
            .02));
    expect(
        PracticeEngine.distanceMetres(
            attacker(movement.session.state, 9).position,
            movement.decision.action.target),
        lessThan(.008));
    expect(movement.session.state.carrierNumber, 8);
    expect(movement.session.state.ball.distanceTo(start.state.ball),
        closeTo(0, 1e-9));
  });

  test(
      'through pass follows a planned run and feedback recognizes its intention',
      () {
    final start = setup();
    final plan = engine.planRun(start, 8, const ScanPassPoint(.47, .18));
    final through = named(plan, 'through-8');
    expect(through.target, same(plan.runTargets[8]));
    final release = engine.choose(plan, through);
    expect(release.session.state.carrierNumber, 8);
    expect(release.session.state.carrierIsDefender, isFalse);
    expect(release.decision.reason, PracticeReason.runnerMetInStride);
    expect(release.decision.useful, isTrue);
    expect(release.session.runTargets.containsKey(8), isFalse);
    expect(
        PracticeEngine.distanceMetres(
            attacker(release.session.state, 8).position, through.target),
        lessThanOrEqualTo(.6));
    final feet = engine.choose(plan, named(plan, 'pass-8'));
    expect(
        attacker(feet.session.state, 8)
            .position
            .distanceTo(attacker(start.state, 8).position),
        closeTo(0, 1e-9),
        reason: 'a chosen pass to feet overrides the receiver run target');
    expect(feet.session.runTargets.containsKey(8), isFalse);
  });

  test(
      'pass-and-move constrains the receiver but leaves timing and movement manual',
      () {
    final start = setup(settings: const PracticeSettings(passAndMove: true));
    final release = engine.choose(start, named(start, 'pass-8')).session;
    expect(release.returnTarget, 6);
    expect(release.state.carrierNumber, 8);
    expect(
        engine
            .choices(release)
            .where((a) => a.receiver != null)
            .map((a) => a.receiver)
            .toSet(),
        {6});
    expect(
        engine.choices(release).any((a) => a.kind == PracticeActionKind.carry),
        isTrue);
    final plan = engine.planRun(release, 6, const ScanPassPoint(.25, .30));
    final hold = engine.choose(plan, named(plan, 'hold')).session;
    expect(hold.state.carrierNumber, 8);
    expect(hold.state.completedPasses, 1);
    expect(hold.returnTarget, 6);
    final thirdPlayerPass = PracticeAction(
        id: 'invalid-third-player',
        kind: PracticeActionKind.pass,
        target: attacker(hold.state, 9).position,
        receiver: 9,
        actorNumber: 8);
    expect(() => engine.choose(hold, thirdPlayerPass), throwsArgumentError);
    expect(() => engine.choose(release, named(start, 'pass-8')),
        throwsArgumentError,
        reason: 'stale actor cannot pass on behalf of 8');
    final returned = engine.choose(hold, named(hold, 'pass-6')).session;
    expect(returned.state.carrierNumber, 6);
    expect(returned.state.completedPasses, 2);
    expect(returned.returnTarget, 8);
  });

  test(
      'pass-and-move credits a useful moved return, not the authored case goal',
      () {
    final thirdPlayerCase = PracticeEngine.catalog[8];
    final free = setup(exercise: thirdPlayerCase);
    final freePass = engine.choose(free, named(free, 'pass-8'));
    expect(freePass.decision.goalDemonstrated, isTrue,
        reason: 'the same free-play case accepts a clear direct connection');
    final mode = setup(
        exercise: thirdPlayerCase,
        settings: const PracticeSettings(passAndMove: true));
    final outgoing = engine.choose(mode, named(mode, 'pass-8'));
    expect(outgoing.decision.useful, isTrue);
    expect(outgoing.decision.goalDemonstrated, isFalse);
    final stationaryReturn =
        engine.choose(outgoing.session, named(outgoing.session, 'pass-6'));
    expect(stationaryReturn.session.state.completedPasses, 2);
    expect(stationaryReturn.decision.useful, isTrue);
    expect(stationaryReturn.decision.goalDemonstrated, isFalse,
        reason:
            'an immediate stationary return has created no new receiving space');
    final moved = engine.moveTo(outgoing.session, const ScanPassPoint(.20, .42),
        playerNumber: 6);
    expect(moved.decision.goalDemonstrated, isFalse,
        reason: 'movement alone does not demonstrate the completed return');
    final returned =
        engine.choose(moved.session, named(moved.session, 'pass-6'));
    expect(returned.decision.useful, isTrue);
    expect(returned.decision.goalDemonstrated, isTrue);
    expect(returned.session.goalDemonstrated, isTrue);
    expect(returned.decision.settingsBefore.passAndMove, isTrue);
    expect(returned.decision.returnTargetBefore, 6);
    final alternatives = engine.rankedChoices(outgoing.session);
    expect(
        alternatives.any(
            (a) => a.kind == PracticeActionKind.move && a.actorNumber == 6),
        isTrue,
        reason:
            'coaching can explicitly propose moving the required return receiver');
    final initialTouch = setup(
        phase: PracticePhase.firstTouch,
        settings: const PracticeSettings(passAndMove: true));
    expect(
        engine
            .choose(initialTouch, named(initialTouch, 'touch-forward'))
            .decision
            .goalDemonstrated,
        isFalse);
  });

  test('comparison restores plans, mode, receiver constraint and trajectory',
      () {
    final start = setup(settings: const PracticeSettings(passAndMove: true));
    final released = engine.choose(start, named(start, 'pass-8')).session;
    final plan = engine.planRun(released, 6, const ScanPassPoint(.28, .3));
    final result = engine.choose(plan, named(plan, 'hold')).session;
    final restored = engine.beforeDecision(result, 1);
    expect(restored.state, same(plan.state));
    expect(restored.settings, same(plan.settings));
    expect(restored.returnTarget, 6);
    expect(restored.runTargets[6], same(plan.runTargets[6]));
    expect(restored.history.length, plan.history.length);
    final repeated = engine.choose(restored, result.decisions[1].action);
    expect(repeated.session.state.elapsed, result.state.elapsed);
    for (final p in result.state.attackers) {
      expect(
          attacker(repeated.session.state, p.number)
              .position
              .distanceTo(p.position),
          closeTo(0, 1e-9));
    }
    expect(result.decisions, hasLength(2));
  });

  test(
      'queued support feedback describes the runner who actually opened a lane',
      () {
    final start = setup(exercise: PracticeEngine.catalog[6], players: const [
      AttackPlayer(number: 6, position: ScanPassPoint(.20, .50)),
      AttackPlayer(number: 9, position: ScanPassPoint(.45, .50)),
    ], defenders: const [
      AttackPlayer(
          number: 2, opponent: true, position: ScanPassPoint(.38, .50)),
    ]);
    final plan = engine.planRun(start, 9, const ScanPassPoint(.45, .25));
    PracticeStep waitForRunner(PracticeSession session) => engine.choose(
        session,
        PracticeAction(
            id: 'hold',
            kind: PracticeActionKind.hold,
            target: session.state.ball,
            actorNumber: 9));
    final first = waitForRunner(plan);
    expect(first.decision.evidencePlayer, 9);
    expect(first.decision.cue, PracticeCue.supportLane);
    expect(first.decision.goalDemonstrated, isFalse);
    expect(first.decision.distance, greaterThan(.5));
    final second = waitForRunner(first.session);
    expect(second.decision.evidencePlayer, 9);
    expect(second.decision.reason, PracticeReason.supportLaneOpened);
    expect(second.decision.goalDemonstrated, isTrue);
    expect(second.decision.laneAfter,
        greaterThan(second.decision.laneBefore + .4));
    expect(second.session.state.carrierNumber, 6);
    expect(second.session.state.completedPasses, 0);
  });

  test(
      'manual control has room for movement without the old eight-choice cutoff',
      () {
    var session = setup();
    expect(session.decisionLimit, 16);
    for (var i = 0; i < 8; i++) {
      session = engine.choose(session, named(session, 'hold')).session;
    }
    expect(session.decisions, hasLength(8));
    expect(session.finished, isFalse);
    expect(
        engine
            .start(lesson,
                settings: const PracticeSettings(controlAllAttackers: false))
            .decisionLimit,
        8);
  });

  test(
      'interception and tackle transfer real possession with continuous samples',
      () {
    final start = setup(players: const [
      AttackPlayer(number: 6, position: ScanPassPoint(.20, .50)),
      AttackPlayer(number: 8, position: ScanPassPoint(.60, .50)),
    ], defenders: const [
      AttackPlayer(
          number: 2, opponent: true, position: ScanPassPoint(.34, .50)),
    ]);
    final pass = engine.choose(start, named(start, 'pass-8'));
    final carry = engine.moveTo(start, const ScanPassPoint(.60, .50));
    for (final step in [pass, carry]) {
      expect(step.session.outcome, PracticeOutcome.intercepted);
      expect(step.session.stolenBy, 2);
      expect(step.session.state.carrierNumber, 2);
      expect(step.session.state.carrierIsDefender, isTrue);
      expect(step.session.state.carrier.opponent, isTrue);
      expect(step.session.state.completedPasses, 0);
      expect(
          step.session.state.ball
              .distanceTo(step.session.state.carrier.position),
          closeTo(0, 1e-9));
      final samples = step.transitions.single.motionSamples;
      final firstContact = samples.firstWhere((s) => s.carrierIsDefender);
      expect(
          PracticeEngine.distanceMetres(
              firstContact.ball, firstContact.carrier.position),
          closeTo(identical(step, pass) ? .72 : .65, 1e-7));
      expect(
          step.session.state.elapsed - firstContact.elapsed, closeTo(.4, 1e-9));
      expect(
          step.session.state.carrier.position
              .distanceTo(firstContact.carrier.position),
          greaterThan(.003));
      for (var i = 1; i < samples.length; i++) {
        final dt = samples[i].elapsed - samples[i - 1].elapsed;
        if (dt <= 1e-9) continue;
        expect(
            PracticeEngine.distanceMetres(
                    samples[i - 1].ball, samples[i].ball) /
                dt,
            lessThanOrEqualTo(17.01));
      }
      expect(engine.choices(step.session), isEmpty);
    }
    expect(pass.decision.reason, PracticeReason.passLaneClosed);
    expect(carry.decision.reason, PracticeReason.carryIntoCover);
  });
}
