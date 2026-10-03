import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_attack.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart';

void main() {
  const engine = AttackEngine();

  test('a possession carries its players, ball and receiver across actions',
      () {
    final opening = engine.initial();
    final receive = engine.play(opening, const AttackAction.pass(6));
    expect(receive.after.finished, isFalse);
    expect(receive.after.carrierNumber, 6);
    final next = engine.play(receive.after, const AttackAction.pass(9));
    expect(identical(next.before, receive.after), isTrue);
    expect(next.after.carrierNumber, 9);
    expect(next.after.completedPasses, 2);
    expect(next.after.elapsed, greaterThan(receive.after.elapsed));
    expect(next.after.ball.distanceTo(next.after.carrier.position),
        lessThan(1e-8));
    expect(opening.carrierNumber, 4);
    expect(opening.elapsed, 0);
    expect(
        () => opening.attackers.add(opening.carrier), throwsUnsupportedError);
  });

  test('preview shows requested receiver rather than an interception point',
      () {
    final state = _state(
        receiver: const ScanPassPoint(.82, .50),
        defender: const ScanPassPoint(.72, .50));
    const action = AttackAction.pass(9);
    final preview = engine.intendedTarget(state, action);
    final actual = engine.play(state, action);
    expect(preview.distanceTo(state.attackers.last.position), lessThan(1e-8));
    expect(actual.after.end, AttackEnd.intercepted);
    expect(actual.ballEnd.x, lessThan(preview.x));
    expect(state.actionCount, 0);
    expect(state.elapsed, 0);
  });

  test('offside uses the second-last opponent including a keeper out of goal',
      () {
    final state = _state(receiver: const ScanPassPoint(.83, .25), defenders: [
      const AttackPlayer(
          number: 2, opponent: true, position: ScanPassPoint(.93, .80)),
      const AttackPlayer(
          number: 3, opponent: true, position: ScanPassPoint(.81, .80)),
      const AttackPlayer(
          number: 5, opponent: true, position: ScanPassPoint(.65, .85)),
      const AttackPlayer(
          number: 1,
          opponent: true,
          goalkeeper: true,
          position: ScanPassPoint(.72, .75)),
    ]);
    final check = engine.checkOffside(state, 9);
    expect(check.secondLastX, .81);
    expect(check.lineX, .81);
    expect(check.offside, isTrue);
  });

  test('own half, halfway, level defender and level ball are onside', () {
    for (final receiverX in [.30, .50, .75]) {
      final state = _state(receiver: ScanPassPoint(receiverX, .25));
      expect(engine.checkOffside(state, 9).offside, isFalse);
    }
    final aheadBall = _state(
        carrier: const ScanPassPoint(.84, .50),
        receiver: const ScanPassPoint(.84, .25));
    expect(engine.offsideLine(aheadBall), .84);
    expect(engine.checkOffside(aheadBall, 9).offside, isFalse);
    final overBall = _state(
        carrier: const ScanPassPoint(.84, .50),
        receiver: const ScanPassPoint(.841, .25));
    expect(engine.checkOffside(overBall, 9).offside, isTrue);
  });

  test('a legal runner may cross the defensive line after the kick', () {
    final state = _state(
        carrier: const ScanPassPoint(.60, .50),
        receiver: const ScanPassPoint(.74, .25),
        receiverVelocity: const ScanPassPoint(.14, 0));
    final play = engine.play(state, const AttackAction.pass(9));
    expect(play.offside!.offside, isFalse);
    expect(play.after.end, isNull);
    expect(play.after.carrierNumber, 9);
    expect(
        play.after.carrier.position.x, greaterThan(play.offside!.secondLastX));
  });

  test('position warning does not penalize an uninvolved player', () {
    final state = _state(receiver: const ScanPassPoint(.86, .25));
    expect(engine.checkOffside(state, 9).offside, isTrue);
    final backPass = engine.play(state, const AttackAction.pass(4));
    expect(backPass.after.end, isNull);
    expect(backPass.after.carrierNumber, 4);
    expect(backPass.offside!.receiverNumber, 4);
  });

  test('offside receipt freezes the actual release snapshot', () {
    final state = _state(receiver: const ScanPassPoint(.84, .25));
    final play = engine.play(state, const AttackAction.pass(9));
    expect(play.after.end, AttackEnd.offside);
    expect(identical(play.offside!.atKick, state), isTrue);
    expect(play.offside!.lineX, .75);
    expect(play.after.ball.distanceTo(state.ball), 0);
    expect(
        play.after.attackers.last.position
            .distanceTo(state.attackers.last.position),
        0);
    expect(play.frame(.5).ball.distanceTo(state.ball), 0);
    expect(play.after.completedPasses, 0);
  });

  test('a defender reaching a pass before an offside target is a turnover', () {
    final state = _state(
        receiver: const ScanPassPoint(.86, .50),
        defender: const ScanPassPoint(.73, .50));
    final play = engine.play(state, const AttackAction.pass(9));
    expect(play.offside!.offside, isTrue);
    expect(play.after.end, AttackEnd.intercepted);
    expect(play.interceptorNumber, 2);
    expect(play.ballEnd.x, lessThan(.86));
  });

  test('waiting moves runners and can change the next release decision', () {
    final state =
        engine.play(engine.initial(), const AttackAction.pass(6)).after;
    expect(engine.checkOffside(state, 9).offside, isFalse);
    final held = engine.play(state, const AttackAction.hold()).after;
    expect(held.end, isNull);
    expect(held.elapsed, greaterThan(state.elapsed));
    expect(engine.checkOffside(held, 9).offside, isTrue);
    expect(engine.play(held, const AttackAction.pass(9)).after.end,
        AttackEnd.offside);
  });

  test('goal is awarded only to an unblocked shot through the goal mouth', () {
    for (final variant in [0, 1, 8, 9]) {
      var state = engine.initial(variant: variant);
      for (final action in [
        const AttackAction.pass(6),
        const AttackAction.pass(9)
      ]) {
        state = engine.play(state, action).after;
        expect(state.end, isNull);
      }
      expect(state.canShoot, isTrue);
      final shot =
          engine.play(state, const AttackAction.shoot(AttackShotTarget.upper));
      expect(shot.after.end, AttackEnd.goal);
      expect(shot.after.ball.x, greaterThan(AttackEngine.goalX));
      expect(shot.after.completedPasses, 2);
      expect(engine.availableActions(shot.after), isEmpty);
    }
  });

  test('keeper saves central shot while an uncovered corner can score', () {
    final state = _state(carrier: const ScanPassPoint(.80, .50));
    final central =
        engine.play(state, const AttackAction.shoot(AttackShotTarget.center));
    final corner =
        engine.play(state, const AttackAction.shoot(AttackShotTarget.upper));
    expect(central.after.end, AttackEnd.saved);
    expect(central.interceptorNumber, 1);
    expect(central.ballEnd.x, lessThan(1));
    expect(corner.after.end, AttackEnd.goal);
  });

  test('backward recycling can develop into a goal without resetting players',
      () {
    var state = engine.initial();
    final originalFour = state.attackers.first.position;
    for (final action in const [
      AttackAction.pass(6),
      AttackAction.pass(4),
      AttackAction.hold(),
      AttackAction.pass(6),
      AttackAction.pass(9),
    ]) {
      final previous = state;
      final play = engine.play(state, action);
      expect(identical(play.before, previous), isTrue);
      state = play.after;
      expect(state.end, isNull);
    }
    expect(state.actionCount, 5);
    expect(state.completedPasses, 4);
    expect(state.attackers.first.position.distanceTo(originalFour),
        greaterThan(.01));
    state = engine
        .play(state, const AttackAction.shoot(AttackShotTarget.upper))
        .after;
    expect(state.end, AttackEnd.goal);
  });

  test('a different dribbling route reaches goal only after an explicit shot',
      () {
    var state = engine.play(engine.initial(), const AttackAction.pass(6)).after;
    for (final action in const [
      AttackAction.carry(AttackCarryDirection.forward),
      AttackAction.carry(AttackCarryDirection.upper),
      AttackAction.hold(),
      AttackAction.carry(AttackCarryDirection.forward),
    ]) {
      state = engine.play(state, action).after;
      expect(state.end, isNull);
      expect(state.carrierNumber, 6);
    }
    expect(state.canShoot, isTrue);
    expect(
        engine
            .play(state, const AttackAction.shoot(AttackShotTarget.upper))
            .after
            .end,
        AttackEnd.goal);
  });

  test('outfield block stops the shot before the goal', () {
    final state = _state(
        carrier: const ScanPassPoint(.80, .50),
        defender: const ScanPassPoint(.87, .46));
    final shot =
        engine.play(state, const AttackAction.shoot(AttackShotTarget.upper));
    expect(shot.after.end, AttackEnd.blocked);
    expect(shot.interceptorNumber, 2);
    expect(shot.ballEnd.x, lessThan(.90));
  });

  test('extreme-angle outside shot can miss the mouth without random rolls',
      () {
    final state = _state(carrier: const ScanPassPoint(.66, .10));
    final first =
        engine.play(state, const AttackAction.shoot(AttackShotTarget.upper));
    final second =
        engine.play(state, const AttackAction.shoot(AttackShotTarget.upper));
    expect(first.after.end, AttackEnd.wide);
    expect(first.after.end, second.after.end);
    expect(first.ballEnd.distanceTo(second.ballEnd), 0);
  });

  test('replay frames preserve exact endpoints without mutating possession',
      () {
    final state = engine.initial();
    final play = engine.play(state, const AttackAction.pass(6));
    final halfway = play.frame(.5);
    expect(play.frame(0).ball.distanceTo(state.ball), 0);
    expect(identical(play.frame(1), play.after), isTrue);
    expect(halfway.ball.distanceTo(state.ball), greaterThan(0));
    expect(halfway.ball.distanceTo(play.after.ball), greaterThan(0));
    expect(state.carrierNumber, 4);
    expect(play.after.carrierNumber, 6);
    expect(play.frame(.5).actionCount, 0);
  });

  test('unavailable shots, self passes and actions after end are rejected', () {
    final initial = engine.initial();
    expect(initial.canShoot, isFalse);
    expect(
        () => engine.play(
            initial, const AttackAction.shoot(AttackShotTarget.center)),
        throwsArgumentError);
    expect(() => engine.play(initial, const AttackAction.pass(4)),
        throwsArgumentError);
    expect(
        () => engine.play(
            initial.copyWith(end: AttackEnd.goal), const AttackAction.hold()),
        throwsStateError);
  });
}

AttackState _state({
  ScanPassPoint carrier = const ScanPassPoint(.66, .50),
  ScanPassPoint receiver = const ScanPassPoint(.73, .25),
  ScanPassPoint receiverVelocity = const ScanPassPoint(0, 0),
  ScanPassPoint defender = const ScanPassPoint(.30, .85),
  List<AttackPlayer>? defenders,
}) =>
    AttackState(
      attackers: [
        const AttackPlayer(number: 4, position: ScanPassPoint(.35, .50)),
        AttackPlayer(number: 6, position: carrier),
        const AttackPlayer(number: 8, position: ScanPassPoint(.51, .22)),
        AttackPlayer(number: 9, position: receiver, velocity: receiverVelocity),
      ],
      defenders: defenders ??
          [
            AttackPlayer(number: 2, opponent: true, position: defender),
            const AttackPlayer(
                number: 3, opponent: true, position: ScanPassPoint(.70, .80)),
            const AttackPlayer(
                number: 5, opponent: true, position: ScanPassPoint(.75, .80)),
            const AttackPlayer(
                number: 1,
                opponent: true,
                goalkeeper: true,
                position: ScanPassPoint(.955, .50)),
          ],
      ball: carrier,
      carrierNumber: 6,
    );
