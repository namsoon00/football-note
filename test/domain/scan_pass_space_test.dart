import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_attack.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart';
import 'package:football_note/domain/scan_pass/scan_pass_space.dart';

void main() {
  const engine = SpaceEngine();

  group('positioning and incoming pass', () {
    test('a chosen receiving space changes the learner trajectory', () {
      final scenario = engine.scenario(0);
      final upper = engine.advance(
        engine.aimReceive(
          engine.start(scenario),
          const ScanPassPoint(0.48, 0.30),
        ),
        0.9,
      );
      final lower = engine.advance(
        engine.aimReceive(
          engine.start(scenario),
          const ScanPassPoint(0.48, 0.72),
        ),
        0.9,
      );

      expect(_attacker(upper, 6).position.y, lessThan(0.48));
      expect(_attacker(lower, 6).position.y, greaterThan(0.52));
      expect(
        engine.distanceMetres(
          _attacker(upper, 6).position,
          _attacker(lower, 6).position,
        ),
        greaterThan(5),
      );
    });

    test('different destinations draw the marker into different pressure lanes',
        () {
      final scenario = engine.scenario(0);
      final upper = engine.advance(
        engine.aimReceive(
          engine.start(scenario),
          const ScanPassPoint(0.50, 0.32),
        ),
        1.15,
      );
      final lower = engine.advance(
        engine.aimReceive(
          engine.start(scenario),
          const ScanPassPoint(0.50, 0.70),
        ),
        1.15,
      );

      expect(_defender(upper, 2).position.y,
          lessThan(_defender(lower, 2).position.y));
      expect(
        engine.distanceMetres(
          _defender(upper, 2).position,
          _defender(lower, 2).position,
        ),
        greaterThan(2.0),
      );
    });

    test('early versus later release changes whether #6 can arrive', () {
      const target = ScanPassPoint(0.56, 0.74);
      final early = engine.advance(
        engine.receive(
          engine.aimReceive(engine.start(engine.scenario(0)), target),
        ),
        1.6,
      );
      final later = engine.advance(
        engine.receive(
          engine.advance(
            engine.aimReceive(engine.start(engine.scenario(0)), target),
            0.6,
          ),
        ),
        1.6,
      );

      expect(early.phase, SpacePhase.complete);
      expect(early.outcome, SpaceOutcome.unreachable);
      expect(early.reason, SpaceReason.receiverLate);
      expect(later.phase, SpacePhase.received);
      expect(engine.distanceMetres(later.reception!.target, target),
          lessThan(1e-9));
      expect(later.reception!.receiverNumber, 6);
    });

    test('receive with no target is a no-op', () {
      final opening = engine.start(engine.scenario(0));
      expect(engine.receive(opening), same(opening));
    });
  });

  group('touch and support release', () {
    test('received phase waits for an explicit first touch and pass', () {
      final received = _receiveSeedZero(engine);
      final waited = engine.advance(received, 1.4);

      expect(waited.phase, SpacePhase.received);
      expect(waited.touchTarget, isNull);
      expect(waited.passTarget, isNull);
      expect(waited.pitch.carrierNumber, 6);
      expect(_attacker(waited, 8).position.x,
          greaterThan(_attacker(received, 8).position.x));
    });

    test('chosen first touch changes pressure without auto-passing', () {
      final received = _receiveSeedZero(engine);
      final defender =
          _nearestDefender(received, _attacker(received, 6).position);
      final start = _attacker(received, 6).position;
      final awayTarget = _awayFrom(start, defender.position, metres: 3.5);

      final away = engine.advance(engine.touch(received, awayTarget), 1.4);
      final risky =
          engine.advance(engine.touch(received, defender.position), 1.4);

      expect(away.phase, SpacePhase.releasing);
      expect(away.passTarget, isNull);
      expect(away.pitch.carrierNumber, 6);
      expect(
        risky.phase == SpacePhase.complete ||
            risky.reception!.marginMetres < away.reception!.marginMetres,
        isTrue,
      );
      if (risky.phase == SpacePhase.complete) {
        expect(risky.reason, SpaceReason.touchIntoPressure);
      }
    });

    test('a forward support lead pass reaches moving #8', () {
      final releasing = _releaseSeedZero(engine);
      final lead = _leadForSupport(releasing, fraction: 0.55);
      final complete = engine.advance(engine.pass(releasing, lead), 1.6);

      expect(complete.phase, SpacePhase.complete);
      expect(complete.outcome,
          isIn(<SpaceOutcome>[SpaceOutcome.open, SpaceOutcome.pressured]));
      expect(
          complete.reason,
          isIn(<SpaceReason>[
            SpaceReason.spaceHeld,
            SpaceReason.defenderArrived
          ]));
      expect(engine.distanceMetres(complete.reception!.target, lead),
          lessThan(1e-9));
      expect(complete.reception!.receiverNumber, 8);
      expect(complete.pitch.carrierNumber, 8);
    });

    test('a poor destination to current feet misses the support runner', () {
      final releasing = _releaseSeedZero(engine);
      final support = _attacker(releasing, 8);
      final complete =
          engine.advance(engine.pass(releasing, support.position), 1.6);

      expect(complete.phase, SpacePhase.complete);
      expect(complete.outcome, SpaceOutcome.unreachable);
      expect(complete.reason, SpaceReason.receiverLate);
      expect(complete.reception!.target.x, closeTo(support.position.x, 1e-9));
    });
  });

  group('continuity, variation and robustness', () {
    test('continuous frames keep stable actor ids and tolerate timestep splits',
        () {
      const target = ScanPassPoint(0.51, 0.66);
      final once = engine.advance(
        engine.aimReceive(engine.start(engine.scenario(0)), target),
        1.2,
      );
      var split = engine.aimReceive(engine.start(engine.scenario(0)), target);
      for (var i = 0; i < 72; i++) {
        split = engine.advance(split, 1 / 60);
      }

      expect(
          once.pitch.attackers.map((player) => player.number), <int>[4, 6, 8]);
      expect(once.pitch.defenders.map((player) => player.number), <int>[2, 3]);
      expect(
          split.pitch.attackers.map((player) => player.number), <int>[4, 6, 8]);
      expect(split.pitch.defenders.map((player) => player.number), <int>[2, 3]);
      expect(
        engine.distanceMetres(
            _attacker(once, 6).position, _attacker(split, 6).position),
        lessThan(0.12),
      );
      expect(
        engine.distanceMetres(
            _defender(once, 2).position, _defender(split, 2).position),
        lessThan(0.12),
      );
    });

    test('seeded scenarios vary while retaining viable spatial solutions', () {
      final signatures = <String>{};
      for (var seed = 0; seed < 8; seed++) {
        final scenario = engine.scenario(seed);
        signatures.add(_signature(scenario.initial));
        expect(_findViableCompletion(engine, scenario), isNotNull,
            reason: 'seed $seed');
      }
      expect(signatures.length, greaterThan(5));
    });

    test('invalid inputs do not corrupt state or distances', () {
      final opening = engine.start(engine.scenario(0));
      final aimed = engine.aimReceive(
        opening,
        const ScanPassPoint(double.nan, double.infinity),
      );
      expect(aimed.receiveTarget!.x.isFinite, isTrue);
      expect(aimed.receiveTarget!.y.isFinite, isTrue);
      expect(engine.advance(aimed, -1), same(aimed));
      expect(engine.advance(aimed, double.nan), same(aimed));
      expect(
        engine
            .distanceMetres(
              const ScanPassPoint(double.nan, 0.2),
              const ScanPassPoint(0.3, double.infinity),
            )
            .isFinite,
        isTrue,
      );

      final received = _receiveSeedZero(engine);
      final touched = engine.advance(
        engine.touch(received, const ScanPassPoint(double.nan, double.nan)),
        0.5,
      );
      expect(touched.pitch.ball.x.isFinite, isTrue);
      expect(touched.pitch.ball.y.isFinite, isTrue);
    });
  });
}

SpaceState _receiveSeedZero(SpaceEngine engine) {
  var state = engine.start(engine.scenario(0));
  state = engine.aimReceive(state, const ScanPassPoint(0.56, 0.74));
  state = engine.advance(state, 0.6);
  state = engine.receive(state);
  state = engine.advance(state, 1.4);
  expect(state.phase, SpacePhase.received);
  return state;
}

SpaceState _releaseSeedZero(SpaceEngine engine) {
  final received = _receiveSeedZero(engine);
  final learner = _attacker(received, 6);
  final insideLeadTouch =
      ScanPassPoint(learner.position.x + 0.08, learner.position.y - 0.10);
  final releasing =
      engine.advance(engine.touch(received, insideLeadTouch), 1.4);
  expect(releasing.phase, SpacePhase.releasing);
  return releasing;
}

SpaceState? _findViableCompletion(SpaceEngine engine, SpaceScenario scenario) {
  final opening = engine.start(scenario);
  final learner = _attackerIn(opening.pitch, 6);
  final marker = _defenderIn(opening.pitch, 2);
  final yAway = learner.position.y >= marker.position.y ? 0.14 : -0.14;
  final receiveCandidates = <ScanPassPoint>[
    _field(
        ScanPassPoint(learner.position.x + 0.10, learner.position.y + yAway)),
    _field(ScanPassPoint(
        learner.position.x + 0.14, learner.position.y + yAway * 0.7)),
    _field(ScanPassPoint(
        learner.position.x + 0.16, learner.position.y + yAway * 1.7)),
    _field(ScanPassPoint(
        learner.position.x + 0.14, learner.position.y + yAway * 1.5)),
    _field(
        ScanPassPoint(learner.position.x + 0.08, learner.position.y - yAway)),
    _field(ScanPassPoint(learner.position.x + 0.15, learner.position.y)),
  ];
  for (final receiveTarget in receiveCandidates) {
    for (final wait in <double>[0.35, 0.6, 0.9, 1.15]) {
      var state = engine.aimReceive(opening, receiveTarget);
      state = engine.advance(state, wait);
      state = engine.advance(engine.receive(state), 1.6);
      if (state.phase != SpacePhase.received) continue;

      final defender = _nearestDefender(state, _attacker(state, 6).position);
      final touchCandidates = <ScanPassPoint>[
        _awayFrom(_attacker(state, 6).position, defender.position, metres: 3.6),
        _field(ScanPassPoint(_attacker(state, 6).position.x + 0.10,
            _attacker(state, 6).position.y)),
        _field(ScanPassPoint(_attacker(state, 6).position.x + 0.08,
            _attacker(state, 6).position.y + yAway * 0.55)),
        _field(ScanPassPoint(_attacker(state, 6).position.x + 0.08,
            _attacker(state, 6).position.y - yAway * 0.70)),
      ];
      for (final touchTarget in touchCandidates) {
        final releasing = engine.advance(engine.touch(state, touchTarget), 1.4);
        if (releasing.phase != SpacePhase.releasing) continue;
        final passCandidates = <ScanPassPoint>[
          _leadForSupport(releasing, fraction: 0.55),
          _leadForSupport(releasing, fraction: 0.75),
          scenario.supportEnd,
        ];
        for (final passTarget in passCandidates) {
          final complete =
              engine.advance(engine.pass(releasing, passTarget), 1.8);
          if (complete.phase == SpacePhase.complete &&
              (complete.outcome == SpaceOutcome.open ||
                  complete.outcome == SpaceOutcome.pressured)) {
            return complete;
          }
        }
      }
    }
  }
  return null;
}

AttackPlayer _attacker(SpaceState state, int number) =>
    _attackerIn(state.pitch, number);

AttackPlayer _defender(SpaceState state, int number) =>
    _defenderIn(state.pitch, number);

AttackPlayer _attackerIn(AttackState state, int number) =>
    state.attackers.firstWhere((player) => player.number == number);

AttackPlayer _defenderIn(AttackState state, int number) =>
    state.defenders.firstWhere((player) => player.number == number);

AttackPlayer _nearestDefender(SpaceState state, ScanPassPoint point) {
  var nearest = state.pitch.defenders.first;
  var nearestDistance =
      const SpaceEngine().distanceMetres(nearest.position, point);
  for (final defender in state.pitch.defenders.skip(1)) {
    final distance =
        const SpaceEngine().distanceMetres(defender.position, point);
    if (distance < nearestDistance) {
      nearest = defender;
      nearestDistance = distance;
    }
  }
  return nearest;
}

ScanPassPoint _awayFrom(
  ScanPassPoint point,
  ScanPassPoint pressure, {
  double metres = 3.4,
}) {
  final dx = (point.x - pressure.x) * 30;
  final dy = (point.y - pressure.y) * 20;
  final length =
      (dx * dx + dy * dy) == 0 ? 1.0 : math.sqrt((dx * dx) + (dy * dy));
  return _field(ScanPassPoint(
    point.x + (dx / length * metres / 30),
    point.y + (dy / length * metres / 20),
  ));
}

ScanPassPoint _leadForSupport(SpaceState state, {required double fraction}) {
  final support = _attacker(state, 8).position;
  return _field(support.lerp(state.scenario.supportEnd, fraction));
}

ScanPassPoint _field(ScanPassPoint point) => ScanPassPoint(
      point.x.clamp(0.0, 1.0).toDouble(),
      point.y.clamp(0.0, 1.0).toDouble(),
    );

String _signature(AttackState state) {
  return [
    for (final player in state.attackers)
      '${player.number}:${player.position.x.toStringAsFixed(3)},${player.position.y.toStringAsFixed(3)}',
    for (final player in state.defenders)
      '${player.number}:${player.position.x.toStringAsFixed(3)},${player.position.y.toStringAsFixed(3)}',
  ].join('|');
}
