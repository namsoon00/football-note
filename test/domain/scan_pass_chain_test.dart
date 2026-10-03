import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_attack.dart';
import 'package:football_note/domain/scan_pass/scan_pass_chain.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart';

void main() {
  const engine = TouchChainEngine();

  group('first touch planning', () {
    test('prepare phase waits for a user-planned touch', () {
      final start = engine.start();
      final waited = engine.advance(start, 2);

      expect(waited, same(start));
      expect(start.phase, ChainPhase.prepareTouch);
      expect(start.ballInFlight, isFalse);
      expect(start.touchTarget, isNull);
      expect(start.moments, isEmpty);

      final receiving =
          engine.takeTouch(start, const ScanPassPoint(0.46, 0.43));
      expect(receiving.phase, ChainPhase.receiving);
      expect(receiving.ballInFlight, isTrue);
      expect(receiving.pitch.carrierNumber, 4);
      expect(receiving.touchTarget!.x, closeTo(0.46, 1e-9));
      expect(receiving.touchTarget!.y, closeTo(0.43, 1e-9));
      expect(receiving.moments.single.moment, ChainMoment.beforeTouch);

      final midFlight = engine.advance(receiving, 0.12);
      expect(midFlight.phase, ChainPhase.receiving);
      expect(_player(midFlight.pitch, 6).position.x, closeTo(0.40, 1e-9));

      final decided = engine.advance(receiving, 3);
      expect(decided.phase, ChainPhase.decide);
      expect(decided.pitch.carrierNumber, 6);
      expect(_player(decided.pitch, 6).position.x, closeTo(0.46, 1e-9));
      expect(_player(decided.pitch, 6).position.y, closeTo(0.43, 1e-9));
    });

    test('different touches in the same geometry change pressure and passes',
        () {
      final upper = _touchSeedZero(const ScanPassPoint(0.46, 0.43));
      final central = _touchSeedZero(const ScanPassPoint(0.48, 0.54));
      final back = _touchSeedZero(const ScanPassPoint(0.33, 0.60));
      final lower = _touchSeedZero(const ScanPassPoint(0.42, 0.68));

      expect(upper.phase, ChainPhase.decide);
      expect(central.phase, ChainPhase.decide);
      expect(back.phase, ChainPhase.decide);
      expect(lower.end, ChainEnd.lostTouch);
      expect(engine.openPasses(upper.pitch), contains(8));
      expect(engine.openPasses(central.pitch), isEmpty);
      expect(engine.openPasses(back.pitch), contains(4));
      expect(_pressure(upper), greaterThan(_pressure(central) + 1.0));
    });

    test('nearby useful touches are neighborhoods, not one exact pixel', () {
      for (final target in const <ScanPassPoint>[
        ScanPassPoint(0.45, 0.42),
        ScanPassPoint(0.46, 0.43),
        ScanPassPoint(0.47, 0.44),
      ]) {
        final state = _touchSeedZero(target);
        expect(state.phase, ChainPhase.decide,
            reason: target.toMap().toString());
        expect(engine.openPasses(state.pitch), contains(8));
      }
    });
  });

  group('decisions and pass consequences', () {
    test('body direction and turn delay change pass results', () {
      final facingEight = _touchSeedZero(const ScanPassPoint(0.46, 0.43));
      final facingFour = _touchSeedZero(const ScanPassPoint(0.33, 0.60));

      final delayedBackPass =
          engine.advance(engine.act(facingEight, const ChainAction.pass(4)), 3);
      final preparedBackPass =
          engine.advance(engine.act(facingFour, const ChainAction.pass(4)), 3);
      final forwardPass =
          engine.advance(engine.act(facingEight, const ChainAction.pass(8)), 3);

      expect(delayedBackPass.phase, ChainPhase.complete);
      expect(delayedBackPass.end, ChainEnd.crowded);
      expect(preparedBackPass.phase, ChainPhase.prepareRun);
      expect(preparedBackPass.pitch.carrierNumber, 4);
      expect(forwardPass.phase, ChainPhase.prepareRun);
      expect(forwardPass.pitch.carrierNumber, 8);
    });

    test('pass, carry and turn are all explicit selectable actions', () {
      final decided = _touchSeedZero(const ScanPassPoint(0.46, 0.43));
      final pass = engine.act(decided, const ChainAction.pass(8));
      final carry = engine.advance(
        engine.act(decided, const ChainAction.carry(ScanPassPoint(0.50, 0.40))),
        2,
      );
      final turn = engine.advance(
        engine.act(decided, const ChainAction.turn(ScanPassPoint(0.44, 0.39))),
        2,
      );

      expect(pass.phase, ChainPhase.acting);
      expect(pass.action!.kind, ChainActionKind.pass);
      expect(carry.phase, ChainPhase.decide);
      expect(carry.pitch.carrierNumber, 6);
      expect(_player(carry.pitch, 6).position.x, greaterThan(0.46));
      expect(turn.phase, ChainPhase.decide);
      expect(turn.pitch.carrierNumber, 6);
      expect(_player(turn.pitch, 6).position.y, lessThan(0.43));
    });

    test('successful pass enters prepareRun while #6 remains controlled', () {
      final passed = _passSeedZeroToEight();

      expect(passed.phase, ChainPhase.prepareRun);
      expect(passed.pitch.carrierNumber, 8);
      expect(_player(passed.pitch, 6).position.x, closeTo(0.46, 1e-9));
      expect(engine.advance(passed, 1), same(passed));

      final running = engine.run(passed, const ScanPassPoint(0.55, 0.60));
      expect(running.phase, ChainPhase.running);
      expect(running.pitch.carrierNumber, 8);
    });
  });

  group('off-ball reconnection', () {
    test('chosen off-ball destinations create different return outcomes', () {
      final passed = _passSeedZeroToEight();

      final crowded = engine.advance(
          engine.run(passed, const ScanPassPoint(0.49, 0.44)), 3);
      final blocked = engine.advance(
          engine.run(passed, const ScanPassPoint(0.46, 0.48)), 3);
      final ready = engine.advance(
          engine.run(passed, const ScanPassPoint(0.55, 0.60)), 3);

      expect(crowded.phase, ChainPhase.complete);
      expect(crowded.end, ChainEnd.crowded);
      expect(blocked.phase, ChainPhase.complete);
      expect(blocked.end, ChainEnd.noReturnLane);
      expect(ready.phase, ChainPhase.prepareTouch);
      expect(ready.returning, isTrue);
      expect(ready.pitch.carrierNumber, 8);
      expect(engine.openPasses(ready.pitch), contains(6));
      expect(ready.moments.last.moment, ChainMoment.returnReady);
    });

    test('a good run enables a real return without resetting the actors', () {
      final ready = _firstReturnReady();
      final before = _signature(ready.pitch);
      final receiving =
          engine.takeTouch(ready, const ScanPassPoint(0.50, 0.63));

      expect(receiving.phase, ChainPhase.receiving);
      expect(receiving.ballInFlight, isTrue);
      expect(receiving.pitch.carrierNumber, 8);
      expect(receiving.returns, 0);

      final returned = engine.advance(receiving, 3);
      expect(returned.phase, ChainPhase.decide);
      expect(returned.returns, 1);
      expect(returned.pitch.carrierNumber, 6);
      expect(_player(returned.pitch, 4).position.x, closeTo(0.20, 1e-9));
      expect(_player(returned.pitch, 8).position.x, closeTo(0.60, 1e-9));
      expect(before, isNot(_signature(returned.pitch)));
      expect(returned.moments.map((m) => m.moment),
          contains(ChainMoment.afterTouch));
    });

    test('two successive return receptions complete the chain', () {
      final complete = _completeSeedZeroChain();

      expect(complete.phase, ChainPhase.complete);
      expect(complete.end, ChainEnd.linked);
      expect(complete.returns, 2);
      expect(complete.pitch.carrierNumber, 6);
      expect(_player(complete.pitch, 6).position.x, closeTo(0.32, 1e-9));
      expect(_player(complete.pitch, 6).position.y, closeTo(0.41, 1e-9));
    });

    test('snapshot history records actual chain moments immutably', () {
      final complete = _completeSeedZeroChain();

      expect(
        complete.moments.map((snapshot) => snapshot.moment),
        <ChainMoment>[
          ChainMoment.beforeTouch,
          ChainMoment.afterTouch,
          ChainMoment.afterAction,
          ChainMoment.afterRun,
          ChainMoment.returnReady,
          ChainMoment.beforeTouch,
          ChainMoment.afterTouch,
          ChainMoment.afterAction,
          ChainMoment.afterRun,
          ChainMoment.returnReady,
          ChainMoment.beforeTouch,
          ChainMoment.afterTouch,
        ],
      );
      expect(complete.moments.first.pitch.carrierNumber, 6);
      expect(complete.moments[2].pitch.carrierNumber, 8);
      expect(complete.moments[6].cycle, 1);
      expect(complete.moments.last.cycle, 2);
      expect(complete.end, ChainEnd.linked);
      for (var cycle = 0; cycle <= 2; cycle++) {
        final before = complete.moments.singleWhere(
            (m) => m.cycle == cycle && m.moment == ChainMoment.beforeTouch);
        final after = complete.moments.singleWhere(
            (m) => m.cycle == cycle && m.moment == ChainMoment.afterTouch);
        expect(before.pitch.carrierNumber, 6);
        expect(after.pitch.carrierNumber, 6);
        expect(before.pitch.elapsed, lessThan(after.pitch.elapsed));
        final pressure = before.pitch.defenders
            .map((p) => engine.distanceMetres(
                p.position, _player(before.pitch, 6).position))
            .reduce(math.min);
        expect(before.pressureMetres, closeTo(pressure, 1e-9));
        expect(before.openPasses, engine.openPasses(before.pitch));
      }
      expect(() => complete.moments.clear(), throwsUnsupportedError);
      expect(() => complete.moments.first.openPasses.add(99),
          throwsUnsupportedError);
    });
  });

  test('a failed touch has an actual after frame for causal comparison', () {
    final result = engine.advance(
        engine.takeTouch(engine.start(), const ScanPassPoint(.42, .68)), 3);
    expect(result.end, ChainEnd.lostTouch);
    expect(result.moments.last.moment, ChainMoment.afterTouch);
    expect(result.moments.last.pitch, same(result.pitch));
    expect(result.moments.first.cycle, result.moments.last.cycle);
    expect(result.moments.first.pitch.carrierNumber, 6);
  });

  test(
      'an intercepted return cannot pair its before frame with the previous touch',
      () {
    final ready = _firstReturnReady();
    final receiveAt = _player(ready.pitch, 6).position;
    final facing = math.atan2((receiveAt.y - ready.pitch.ball.y) * 20,
        (receiveAt.x - ready.pitch.ball.x) * 30);
    final blockedPitch = ready.pitch.copyWith(defenders: [
      ready.pitch.defenders.first.copyWith(
          position: ready.pitch.ball.lerp(receiveAt, .4),
          facingRadians: facing),
      ready.pitch.defenders.last,
    ]);
    final blocked = ChainState(
        seed: ready.seed,
        pitch: blockedPitch,
        phase: ChainPhase.prepareTouch,
        elapsed: ready.elapsed,
        returns: ready.returns,
        returning: true,
        moments: ready.moments);
    final incoming = engine.takeTouch(blocked, const ScanPassPoint(.50, .63));
    expect(incoming.returns, 0);
    expect(incoming.moments.last.cycle, 1);
    final interrupted = engine.advance(incoming, 3);
    expect(interrupted.end, ChainEnd.intercepted);
    expect(interrupted.returns, 0);
    expect(interrupted.moments.last.cycle, 1);
    expect(
        interrupted.moments
            .where((m) => m.cycle == 1 && m.moment == ChainMoment.afterTouch),
        isEmpty);
    expect(
        interrupted.moments
            .where((m) => m.cycle == 0 && m.moment == ChainMoment.beforeTouch)
            .length,
        1);
    expect(
        interrupted.moments
            .where((m) => m.cycle == 0 && m.moment == ChainMoment.afterTouch)
            .length,
        1);
  });

  group('continuity, seeded variety and guards', () {
    test('fixed substeps preserve continuous positions', () {
      final start =
          engine.takeTouch(engine.start(), const ScanPassPoint(0.46, 0.43));
      final once = engine.advance(start, 1.0);
      var split = start;
      for (var i = 0; i < 60; i++) {
        split = engine.advance(split, 1 / 60);
      }

      expect(once.phase, split.phase);
      expect(
        engine.distanceMetres(
          _player(once.pitch, 6).position,
          _player(split.pitch, 6).position,
        ),
        lessThan(0.12),
      );
      expect(
        engine.distanceMetres(once.pitch.ball, split.pitch.ball),
        lessThan(0.12),
      );
      expect(
          once.pitch.attackers.map((player) => player.number), <int>[4, 6, 8]);
      expect(once.pitch.defenders.map((player) => player.number), <int>[2, 3]);
    });

    test('seeded starts vary and retain several viable one-return paths', () {
      final signatures = <String>{};
      for (var seed = 0; seed < 6; seed++) {
        final start = engine.start(seed: seed);
        signatures.add(_signature(start.pitch));
        final oneReturn = _findOneReturn(seed);
        expect(oneReturn, isNotNull, reason: 'seed $seed');
        expect(oneReturn!.phase, ChainPhase.decide);
        expect(oneReturn.returns, 1);
      }
      expect(signatures.length, greaterThan(4));
    });

    test('invalid inputs and wrong phases do not corrupt state', () {
      final start = engine.start();
      expect(engine.act(start, const ChainAction.pass(8)), same(start));
      expect(engine.run(start, const ScanPassPoint(0.4, 0.4)), same(start));
      expect(engine.advance(start, -1), same(start));
      expect(engine.advance(start, double.nan), same(start));

      final receiving = engine.takeTouch(
        start,
        const ScanPassPoint(double.nan, double.infinity),
      );
      final decided = engine.advance(receiving, 3);
      expect(decided.pitch.ball.x.isFinite, isTrue);
      expect(decided.pitch.ball.y.isFinite, isTrue);

      final invalidPass = engine.act(decided, const ChainAction.pass(6));
      expect(invalidPass, same(decided));
      final carry = engine.advance(
        engine.act(
          decided,
          const ChainAction.carry(ScanPassPoint(double.infinity, double.nan)),
        ),
        2,
      );
      expect(_player(carry.pitch, 6).position.x.isFinite, isTrue);
      expect(_player(carry.pitch, 6).position.y.isFinite, isTrue);
      expect(
        engine
            .distanceMetres(
              const ScanPassPoint(double.nan, 0.2),
              const ScanPassPoint(0.3, double.infinity),
            )
            .isFinite,
        isTrue,
      );
    });
  });
}

ChainState _touchSeedZero(ScanPassPoint target) {
  const engine = TouchChainEngine();
  return engine.advance(engine.takeTouch(engine.start(), target), 3);
}

ChainState _passSeedZeroToEight() {
  const engine = TouchChainEngine();
  final decided = _touchSeedZero(const ScanPassPoint(0.46, 0.43));
  final passed =
      engine.advance(engine.act(decided, const ChainAction.pass(8)), 3);
  expect(passed.phase, ChainPhase.prepareRun);
  return passed;
}

ChainState _firstReturnReady() {
  const engine = TouchChainEngine();
  final passed = _passSeedZeroToEight();
  final ready =
      engine.advance(engine.run(passed, const ScanPassPoint(0.55, 0.60)), 3);
  expect(ready.phase, ChainPhase.prepareTouch);
  return ready;
}

ChainState _afterFirstReturnPassToFour() {
  const engine = TouchChainEngine();
  final ready = _firstReturnReady();
  final returned = engine.advance(
    engine.takeTouch(ready, const ScanPassPoint(0.50, 0.63)),
    3,
  );
  expect(returned.phase, ChainPhase.decide);
  final passed =
      engine.advance(engine.act(returned, const ChainAction.pass(4)), 3);
  expect(passed.phase, ChainPhase.prepareRun);
  return passed;
}

ChainState _completeSeedZeroChain() {
  const engine = TouchChainEngine();
  final passed = _afterFirstReturnPassToFour();
  final ready =
      engine.advance(engine.run(passed, const ScanPassPoint(0.28, 0.44)), 3);
  expect(ready.phase, ChainPhase.prepareTouch);
  return engine.advance(
    engine.takeTouch(ready, const ScanPassPoint(0.32, 0.41)),
    3,
  );
}

ChainState? _findOneReturn(int seed) {
  const engine = TouchChainEngine();
  final start = engine.start(seed: seed);
  final six = _player(start.pitch, 6);
  final nearest = _nearestDefender(start.pitch, six.position);
  final touchCandidates = <ScanPassPoint>[
    _awayFrom(six.position, nearest.position, metres: 2.7),
    _field(ScanPassPoint(six.position.x + 0.06, six.position.y - 0.10)),
    _field(ScanPassPoint(six.position.x + 0.06, six.position.y + 0.10)),
    _field(ScanPassPoint(six.position.x - 0.07, six.position.y + 0.06)),
    _field(ScanPassPoint(six.position.x - 0.07, six.position.y - 0.06)),
  ];

  for (final touch in touchCandidates) {
    final decided =
        engine.advance(engine.takeTouch(engine.start(seed: seed), touch), 3);
    if (decided.phase != ChainPhase.decide) continue;
    for (final receiver in const <int>[8, 4]) {
      final passed =
          engine.advance(engine.act(decided, ChainAction.pass(receiver)), 3);
      if (passed.phase != ChainPhase.prepareRun) continue;
      final learner = _player(passed.pitch, 6).position;
      final carrier = passed.pitch.carrier.position;
      final runCandidates = <ScanPassPoint>[
        for (final dx in const <double>[-0.14, -0.10, -0.06, 0.06, 0.10, 0.14])
          for (final dy in const <double>[-0.16, -0.10, 0.10, 0.16])
            _field(ScanPassPoint(learner.x + dx, learner.y + dy)),
        _field(ScanPassPoint((learner.x + carrier.x) / 2, learner.y + 0.14)),
        _field(ScanPassPoint((learner.x + carrier.x) / 2, learner.y - 0.14)),
      ];
      for (final run in runCandidates) {
        final ready = engine.advance(engine.run(passed, run), 3);
        if (ready.phase != ChainPhase.prepareTouch) continue;
        final runPoint = _player(ready.pitch, 6).position;
        final pressure = _nearestDefender(ready.pitch, runPoint).position;
        final returnTouches = <ScanPassPoint>[
          _awayFrom(runPoint, pressure, metres: 1.3),
          _field(ScanPassPoint(runPoint.x + 0.04, runPoint.y - 0.03)),
          _field(ScanPassPoint(runPoint.x + 0.04, runPoint.y + 0.03)),
          _field(ScanPassPoint(runPoint.x - 0.05, runPoint.y + 0.03)),
        ];
        for (final returnTouch in returnTouches) {
          final returned =
              engine.advance(engine.takeTouch(ready, returnTouch), 3);
          if (returned.phase == ChainPhase.decide && returned.returns == 1) {
            return returned;
          }
        }
      }
    }
  }
  return null;
}

AttackPlayer _player(AttackState state, int number) =>
    state.attackers.firstWhere((player) => player.number == number);

AttackPlayer _nearestDefender(AttackState state, ScanPassPoint point) {
  var nearest = state.defenders.first;
  var nearestDistance = const TouchChainEngine().distanceMetres(
    nearest.position,
    point,
  );
  for (final defender in state.defenders.skip(1)) {
    final distance = const TouchChainEngine().distanceMetres(
      defender.position,
      point,
    );
    if (distance < nearestDistance) {
      nearest = defender;
      nearestDistance = distance;
    }
  }
  return nearest;
}

double _pressure(ChainState state) {
  final point = _player(state.pitch, 6).position;
  return const TouchChainEngine().distanceMetres(
    _nearestDefender(state.pitch, point).position,
    point,
  );
}

ScanPassPoint _awayFrom(
  ScanPassPoint point,
  ScanPassPoint pressure, {
  required double metres,
}) {
  final dx = (point.x - pressure.x) * 30;
  final dy = (point.y - pressure.y) * 20;
  final length = math.sqrt(dx * dx + dy * dy);
  if (length <= 1e-9) return point;
  return _field(ScanPassPoint(
    point.x + dx / length * metres / 30,
    point.y + dy / length * metres / 20,
  ));
}

ScanPassPoint _field(ScanPassPoint point) => ScanPassPoint(
      point.x.clamp(0.0, 1.0).toDouble(),
      point.y.clamp(0.0, 1.0).toDouble(),
    );

String _signature(AttackState state) {
  return <String>[
    'ball:${state.ball.x.toStringAsFixed(3)},${state.ball.y.toStringAsFixed(3)}',
    'carrier:${state.carrierNumber}',
    for (final player in state.attackers)
      '${player.number}:${player.position.x.toStringAsFixed(3)},${player.position.y.toStringAsFixed(3)}',
    for (final player in state.defenders)
      '${player.number}:${player.position.x.toStringAsFixed(3)},${player.position.y.toStringAsFixed(3)}',
  ].join('|');
}
