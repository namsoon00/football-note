import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_attack.dart';
import 'package:football_note/domain/scan_pass/scan_pass_curriculum.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart'
    show ScanPassPoint;

void main() {
  const engine = PracticeEngine();
  // Regression coverage for the retained single-player assisted curriculum.
  // The public all-attacker default is exercised in team_control_test.
  const assisted = PracticeSettings(controlAllAttackers: false);
  PracticeSession begin(PracticeCase lesson) =>
      engine.start(lesson, settings: assisted);
  PracticeSession example(PracticeCase lesson) =>
      engine.coachRun(lesson, settings: assisted);

  test('twelve cases define six goals, paired variables and 2 to 4 attackers',
      () {
    final cases = PracticeEngine.catalog;
    expect(cases.length, 12);
    expect(cases.map((c) => c.id).toSet().length, 12);
    for (final lesson in cases) {
      final expected = switch (lesson.skill) {
        PracticeSkill.firstTouch ||
        PracticeSkill.drawDefender ||
        PracticeSkill.throughPass =>
          2,
        PracticeSkill.supportAngle || PracticeSkill.thirdPlayer => 3,
        PracticeSkill.switchPlay => 4,
      };
      expect(lesson.stage, expected);
      expect(lesson.initial.attackers.length, expected);
      expect(
          lesson.initial.defenders.length,
          lesson.skill.index < 2
              ? 1
              : expected == 4
                  ? 3
                  : 2);
      expect(lesson.initial.defenders.any((d) => d.goalkeeper), isFalse);
      expect(lesson.reception.carrierNumber, 6);
      expect(lesson.learning.goal, lesson.skill);
      expect(lesson.learning.cues.length, greaterThanOrEqualTo(2));
      expect(lesson.learning.mistakes, isNotEmpty);
      expect(lesson.learning.rubric.minimumLaneClearance, greaterThan(0));
      expect(lesson.offsideEnabled, lesson.skill == PracticeSkill.switchPlay);
      expect(lesson.gates, hasLength(2));
    }
    for (var i = 0; i < cases.length; i += 2) {
      final first = cases[i].initial;
      final paired = cases[i + 1].initial;
      final changed = <int>[];
      for (final p in [...first.attackers, ...first.defenders]) {
        final q = [...paired.attackers, ...paired.defenders]
            .firstWhere((q) => q.number == p.number);
        if (p.position.distanceTo(q.position) > 1e-9 ||
            p.velocity.distanceTo(q.velocity) > 1e-9) {
          changed.add(p.number);
        }
      }
      expect(changed, hasLength(1), reason: cases[i].id);
      expect(first.ball.distanceTo(paired.ball), closeTo(0, 1e-9));
    }
  });

  test('observation really moves the incoming ball and surrounding players',
      () {
    for (final lesson in PracticeEngine.catalog) {
      final observation = lesson.observation;
      expect(observation.motionSamples, hasLength(greaterThan(20)));
      expect(observation.before.carrierNumber, 8);
      expect(observation.after.carrierNumber, 6);
      expect(observation.frame(.5).ball.distanceTo(observation.before.ball),
          greaterThan(.03));
      expect(
          observation.after.attackers[1].position
              .distanceTo(observation.before.attackers[1].position),
          greaterThan(.01));
      expect(
          observation.after.defenders.first.position
              .distanceTo(observation.before.defenders.first.position),
          greaterThan(.01));
      for (final sample in observation.motionSamples) {
        expect(PracticeEngine.nearestDefender(sample, sample.ball),
            greaterThan(.72),
            reason: lesson.id);
      }
    }
  });

  test(
      'pressure direction changes first touch without changing other attackers',
      () {
    final upperPressure = begin(PracticeEngine.catalog[0]);
    final lowerPressure = begin(PracticeEngine.catalog[1]);
    final awayLower = engine.recommended(upperPressure);
    final awayUpper = engine.recommended(lowerPressure);
    expect(awayLower.id, 'touch-lower');
    expect(awayUpper.id, 'touch-upper');
    final correct = engine.choose(upperPressure, awayLower);
    final intoPressure = engine.choose(upperPressure,
        engine.choices(upperPressure).firstWhere((a) => a.id == 'touch-upper'));
    expect(correct.decision.useful, isTrue);
    expect(correct.decision.goalDemonstrated, isTrue);
    final forward = engine.choose(
        upperPressure,
        engine
            .choices(upperPressure)
            .firstWhere((a) => a.id == 'touch-forward'));
    expect(forward.decision.useful, isTrue,
        reason: 'a second viable touch is accepted, not a single fixed answer');
    expect(intoPressure.decision.useful, isFalse);
    expect(intoPressure.decision.reason, PracticeReason.touchIntoPressure);
  });

  test('runner timing distinguishes a through ball from a pass to feet', () {
    final runningCase = PracticeEngine.catalog[4];
    final checkingCase = PracticeEngine.catalog[5];
    PracticeSession onBall(PracticeCase lesson) {
      final start = begin(lesson);
      return engine
          .choose(start,
              engine.choices(start).firstWhere((a) => a.id == 'touch-forward'))
          .session;
    }

    final running = onBall(runningCase);
    final checking = onBall(checkingCase);
    final through =
        engine.choices(running).firstWhere((a) => a.id == 'through-8');
    final feet = engine.choices(running).firstWhere((a) => a.id == 'pass-8');
    expect(through.target.x, greaterThan(feet.target.x + .03));
    final release = engine.choose(running, through);
    expect(release.decision.reason, PracticeReason.runnerMetInStride);
    expect(release.decision.goalDemonstrated, isTrue);
    final early = engine.choose(checking,
        engine.choices(checking).firstWhere((a) => a.id == 'through-8'));
    expect(early.decision.reason,
        anyOf(PracticeReason.runnerNotReady, PracticeReason.passLaneClosed));
    expect(early.decision.useful, isFalse);
    final firstChoice = engine.recommended(running);
    final secondChoice = engine.recommended(checking);
    expect(firstChoice.kind, PracticeActionKind.through);
    expect(secondChoice.id, isNot(firstChoice.id));
    final hold = engine.choose(
        checking,
        engine
            .choices(checking)
            .firstWhere((a) => a.kind == PracticeActionKind.hold));
    expect(
        hold.session.state.elapsed - checking.state.elapsed, closeTo(.5, 1e-7));
    expect(
        hold.session.state.attackers[1].position
            .distanceTo(checking.state.attackers[1].position),
        greaterThan(.005));
  });

  test(
      'all examples complete physically; case evidence is separate from cone finish',
      () {
    var retained = 0;
    var gates = 0;
    var thirdPlayer = false;
    var switchPlay = false;
    var advancedReturn = false;
    var teammateProgress = false;
    for (final lesson in PracticeEngine.catalog) {
      final complete = example(lesson);
      expect(complete.finished, isTrue, reason: lesson.id);
      expect(complete.decisions.length, lessThanOrEqualTo(8));
      expect(complete.outcome,
          anyOf(PracticeOutcome.gateReached, PracticeOutcome.retained),
          reason: lesson.id);
      expect(complete.goalDemonstrated, isTrue, reason: lesson.id);
      if (complete.outcome == PracticeOutcome.retained) retained++;
      if (complete.outcome == PracticeOutcome.gateReached) gates++;
      if (lesson.skill == PracticeSkill.thirdPlayer) {
        thirdPlayer |= complete.decisions
            .any((d) => d.reason == PracticeReason.thirdPlayerConnected);
      }
      if (lesson.skill == PracticeSkill.switchPlay) {
        switchPlay |= complete.decisions
            .any((d) => d.reason == PracticeReason.farSideOpened);
      }
      for (final t in complete.history.skip(1)) {
        if (t.action.kind == AttackActionKind.pass &&
            t.before.carrierNumber != 6 &&
            t.after.end == null) {
          advancedReturn |= t.after.carrierNumber == 6;
          teammateProgress |= t.after.carrierNumber != 6;
        }
      }
    }
    expect(gates, greaterThan(0));
    expect(retained, greaterThan(0));
    expect(thirdPlayer, isTrue);
    expect(switchPlay, isTrue);
    expect(advancedReturn, isTrue);
    expect(teammateProgress, isTrue);
  });

  test(
      'a gate requires controlled player and ball crossing, never just the pass',
      () {
    const gate = PracticeGate(id: 'test', center: ScanPassPoint(.88, .23));
    AttackState state(double ballX, double carrierX, {double y = .23}) =>
        AttackState(
          attackers: [
            AttackPlayer(number: 6, position: ScanPassPoint(carrierX, y))
          ],
          defenders: const [
            AttackPlayer(
                number: 2, opponent: true, position: ScanPassPoint(.2, .8))
          ],
          ball: ScanPassPoint(ballX, y),
          carrierNumber: 6,
        );
    expect(gate.crossed(state(.875, .875), state(.885, .885)), isTrue);
    expect(gate.crossed(state(.875, .70), state(.885, .70)), isFalse);
    expect(gate.crossed(state(.875, .875, y: .40), state(.885, .885, y: .40)),
        isFalse);
    expect(gate.crossed(state(.885, .885), state(.875, .875)), isFalse);
    expect(gate.crossed(state(.875, .875), state(.885, .80)), isFalse);
  });

  test(
      'rendered samples stop at exact controlled crossing and actual interception',
      () {
    final complete = example(PracticeEngine.catalog.first);
    expect(complete.outcome, PracticeOutcome.gateReached);
    final t = complete.history.last;
    final gate =
        complete.lesson.gates.firstWhere((g) => g.id == complete.reachedGate);
    expect(t.after.ball.x, closeTo(gate.center.x, 1e-8));
    expect(
        PracticeEngine.distanceMetres(t.after.ball, t.after.carrier.position),
        lessThanOrEqualTo(.65));
    expect(t.motionSamples.last, same(t.after));
    expect(t.frame(1), same(t.after));
    for (var i = 1; i < t.motionSamples.length; i++) {
      final a = t.motionSamples[i - 1], b = t.motionSamples[i];
      for (final p in [...a.attackers, ...a.defenders]) {
        final q = [...b.attackers, ...b.defenders]
            .firstWhere((q) => q.number == p.number);
        final speed = PracticeEngine.distanceMetres(p.position, q.position) /
            (b.elapsed - a.elapsed);
        expect(speed, lessThanOrEqualTo(6.5),
            reason: '${p.number} ${b.elapsed}');
      }
    }
    final initial = begin(PracticeEngine.catalog.first);
    final lost = engine.choose(initial,
        engine.choices(initial).firstWhere((a) => a.id == 'touch-upper'));
    expect(lost.session.outcome, PracticeOutcome.intercepted);
    final hit = lost.transitions.first;
    final contact = hit.motionSamples.firstWhere((s) => s.carrierIsDefender);
    expect(
        PracticeEngine.distanceMetres(contact.carrier.position, contact.ball),
        closeTo(.65, 1e-7));
    expect(hit.after.carrierIsDefender, isTrue);
    expect(hit.after.carrierNumber, hit.interceptorNumber);
    expect(hit.motionSamples.last, same(hit.after));
  });

  test('kick-time offside uses ball, halfway and actual second-last defender',
      () {
    AttackState world(double receiverX, {double ballX = .45}) => AttackState(
          attackers: [
            AttackPlayer(number: 6, position: ScanPassPoint(ballX, .55)),
            AttackPlayer(number: 8, position: ScanPassPoint(receiverX, .22)),
          ],
          defenders: const [
            AttackPlayer(
                number: 2, opponent: true, position: ScanPassPoint(.72, .7)),
            AttackPlayer(
                number: 3, opponent: true, position: ScanPassPoint(.62, .7)),
            AttackPlayer(
                number: 5, opponent: true, position: ScanPassPoint(.40, .7)),
          ],
          ball: ScanPassPoint(ballX, .55),
          carrierNumber: 6,
        );
    expect(PracticeEngine.checkOffside(world(.61), 8).offside, isFalse);
    expect(PracticeEngine.checkOffside(world(.63), 8).offside, isTrue);
    expect(PracticeEngine.checkOffside(world(.49), 8).offside, isFalse);
    expect(
        PracticeEngine.checkOffside(world(.68, ballX: .7), 8).offside, isFalse);
    final lesson = PracticeEngine.catalog.last;
    final before = world(.61);
    final session = PracticeSession(
        settings: assisted,
        lesson: lesson,
        state: before,
        phase: PracticePhase.onBall);
    final legal = engine.choose(
        session,
        const PracticeAction(
            id: 'legal-run',
            kind: PracticeActionKind.through,
            target: ScanPassPoint(.78, .22),
            receiver: 8));
    expect(legal.transitions.first.offside!.atKick, same(before));
    expect(legal.transitions.first.offside!.offside, isFalse);
    expect(legal.session.state.attackers[1].position.x, greaterThan(.62));
    final illegal = engine.choose(
        PracticeSession(
            settings: assisted,
            lesson: lesson,
            state: world(.63),
            phase: PracticePhase.onBall),
        const PracticeAction(
            id: 'late',
            kind: PracticeActionKind.pass,
            target: ScanPassPoint(.63, .22),
            receiver: 8));
    expect(illegal.session.outcome, PracticeOutcome.offside);
    expect(illegal.transitions.first.duration, 0);
    expect(illegal.decision.reason, PracticeReason.offsideAtKick);
  });

  test('learner number stays 6 and no run is invented after releasing a pass',
      () {
    final lesson = PracticeEngine.catalog[4];
    final source = lesson.reception;
    final stationary = source.copyWith(attackers: [
      for (final p in source.attackers)
        p.number == 6 ? p.copyWith(velocity: const ScanPassPoint(0, 0)) : p,
    ]);
    final session = PracticeSession(
        settings: assisted,
        lesson: lesson,
        state: stationary,
        phase: PracticePhase.onBall);
    final action = engine.choices(session).firstWhere((a) => a.id == 'pass-8');
    final result = engine.choose(session, action);
    final origin =
        stationary.attackers.firstWhere((p) => p.number == 6).position;
    for (final t in result.transitions) {
      for (final sample in t.motionSamples) {
        expect(
            sample.attackers
                .firstWhere((p) => p.number == 6)
                .position
                .distanceTo(origin),
            closeTo(0, 1e-9));
      }
    }
    expect(result.session.phase, PracticePhase.support);
    final moving = engine.moveTo(result.session, const ScanPassPoint(.95, .85));
    expect(moving.decision.action.kind, PracticeActionKind.move);
    expect(PracticeEngine.distanceMetres(origin, moving.decision.action.target),
        lessThanOrEqualTo(8.000001));
    expect(moving.decision.distance, greaterThan(.1));
    final onBall = engine.moveTo(session, const ScanPassPoint(.95, .2));
    expect(onBall.decision.action.kind, PracticeActionKind.carry);
    expect(PracticeEngine.distanceMetres(origin, onBall.decision.action.target),
        lessThanOrEqualTo(5.800001));
  });

  test(
      'same-moment alternatives restore the exact world and leave history unchanged',
      () {
    final original = example(PracticeEngine.catalog[8]);
    final frozenHistory = original.history.length;
    final index = original.decisions.length > 3 ? 2 : 1;
    final restored = engine.beforeDecision(original, index);
    final decision = original.decisions[index];
    expect(restored.state, same(decision.before));
    expect(restored.phase, decision.phaseBefore);
    expect(restored.decisions.length, index);
    expect(restored.history.length, decision.historyLengthBefore);
    final repeated = engine.choose(restored, decision.action);
    expect(
        repeated.session.state.elapsed, closeTo(decision.after.elapsed, 1e-9));
    expect(repeated.session.state.ball.distanceTo(decision.after.ball),
        closeTo(0, 1e-9));
    final ranked = engine.rankedChoices(restored);
    expect(ranked.map((a) => a.id).toSet().length, ranked.length);
    expect(ranked.first.id, engine.recommended(restored).id);
    expect(original.history.length, frozenHistory);
    expect(engine.choices(original), isEmpty);
  });

  test(
      'ids and condition labels cannot change a simulated choice or recommendation',
      () {
    final source = PracticeEngine.catalog[4];
    final renamed = PracticeCase(
      id: 'different-label',
      skill: source.skill,
      variant: 99,
      stage: source.stage,
      offsideEnabled: source.offsideEnabled,
      gates: source.gates,
      observation: source.observation,
      learning: source.learning,
    );
    final a = begin(source), b = begin(renamed);
    expect(engine.recommended(a).id, engine.recommended(b).id);
    final action = engine.choices(a)[1];
    final ra = engine.choose(a, action), rb = engine.choose(b, action);
    expect(ra.session.state.ball.distanceTo(rb.session.state.ball),
        closeTo(0, 1e-9));
    expect(ra.decision.reason, rb.decision.reason);
    expect(ra.decision.useful, rb.decision.useful);
  });
}
