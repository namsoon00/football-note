import 'dart:math' as math;

import 'scan_pass_attack.dart';
import 'scan_pass_game.dart' show ScanPassPoint;

enum SpacePhase {
  positioning,
  incoming,
  received,
  touching,
  releasing,
  outgoing,
  complete,
}

enum SpaceOutcome { open, pressured, intercepted, unreachable }

enum SpaceReason {
  spaceHeld,
  defenderArrived,
  receiverLate,
  closedLane,
  touchIntoPressure,
}

class SpaceScenario {
  final int seed;
  final AttackState initial;
  final ScanPassPoint supportEnd;

  const SpaceScenario({
    required this.seed,
    required this.initial,
    required this.supportEnd,
  });
}

class SpaceReception {
  final ScanPassPoint target;
  final ScanPassPoint receiverPosition;
  final ScanPassPoint defenderStart;
  final ScanPassPoint defenderArrival;
  final double marginMetres;
  final int receiverNumber;

  const SpaceReception({
    required this.target,
    required this.receiverPosition,
    required this.defenderStart,
    required this.defenderArrival,
    required this.marginMetres,
    required this.receiverNumber,
  });
}

class SpaceState {
  final SpaceScenario scenario;
  final AttackState pitch;
  final SpacePhase phase;
  final double elapsed;
  final ScanPassPoint? receiveTarget;
  final ScanPassPoint? touchTarget;
  final ScanPassPoint? passTarget;
  final SpaceOutcome? outcome;
  final SpaceReason? reason;
  final SpaceReception? reception;
  final ScanPassPoint? _flightStart;
  final ScanPassPoint? _flightTarget;
  final double _flightElapsed;
  final double _flightDuration;
  final int _flightReceiverNumber;
  final List<AttackPlayer> _flightDefendersAtRelease;
  final ScanPassPoint? _touchStart;
  final ScanPassPoint? _touchEnd;
  final double _touchElapsed;
  final double _touchDuration;
  final List<AttackPlayer> _touchDefendersAtStart;

  SpaceState({
    required this.scenario,
    required this.pitch,
    required this.phase,
    required this.elapsed,
    this.receiveTarget,
    this.touchTarget,
    this.passTarget,
    this.outcome,
    this.reason,
    this.reception,
    ScanPassPoint? flightStart,
    ScanPassPoint? flightTarget,
    double flightElapsed = 0,
    double flightDuration = 0,
    int flightReceiverNumber = 0,
    List<AttackPlayer> flightDefendersAtRelease = const <AttackPlayer>[],
    ScanPassPoint? touchStart,
    ScanPassPoint? touchEnd,
    double touchElapsed = 0,
    double touchDuration = 0,
    List<AttackPlayer> touchDefendersAtStart = const <AttackPlayer>[],
  })  : _flightStart = flightStart,
        _flightTarget = flightTarget,
        _flightElapsed = flightElapsed,
        _flightDuration = flightDuration,
        _flightReceiverNumber = flightReceiverNumber,
        _flightDefendersAtRelease =
            List<AttackPlayer>.unmodifiable(flightDefendersAtRelease),
        _touchStart = touchStart,
        _touchEnd = touchEnd,
        _touchElapsed = touchElapsed,
        _touchDuration = touchDuration,
        _touchDefendersAtStart =
            List<AttackPlayer>.unmodifiable(touchDefendersAtStart);

  bool get finished => phase == SpacePhase.complete;
  bool get ballInFlight =>
      phase == SpacePhase.incoming || phase == SpacePhase.outgoing;

  SpaceState _copyWith({
    SpaceScenario? scenario,
    AttackState? pitch,
    SpacePhase? phase,
    double? elapsed,
    Object? receiveTarget = _unchanged,
    Object? touchTarget = _unchanged,
    Object? passTarget = _unchanged,
    Object? outcome = _unchanged,
    Object? reason = _unchanged,
    Object? reception = _unchanged,
    Object? flightStart = _unchanged,
    Object? flightTarget = _unchanged,
    double? flightElapsed,
    double? flightDuration,
    int? flightReceiverNumber,
    List<AttackPlayer>? flightDefendersAtRelease,
    Object? touchStart = _unchanged,
    Object? touchEnd = _unchanged,
    double? touchElapsed,
    double? touchDuration,
    List<AttackPlayer>? touchDefendersAtStart,
  }) {
    return SpaceState(
      scenario: scenario ?? this.scenario,
      pitch: pitch ?? this.pitch,
      phase: phase ?? this.phase,
      elapsed: elapsed ?? this.elapsed,
      receiveTarget: identical(receiveTarget, _unchanged)
          ? this.receiveTarget
          : receiveTarget as ScanPassPoint?,
      touchTarget: identical(touchTarget, _unchanged)
          ? this.touchTarget
          : touchTarget as ScanPassPoint?,
      passTarget: identical(passTarget, _unchanged)
          ? this.passTarget
          : passTarget as ScanPassPoint?,
      outcome: identical(outcome, _unchanged)
          ? this.outcome
          : outcome as SpaceOutcome?,
      reason:
          identical(reason, _unchanged) ? this.reason : reason as SpaceReason?,
      reception: identical(reception, _unchanged)
          ? this.reception
          : reception as SpaceReception?,
      flightStart: identical(flightStart, _unchanged)
          ? _flightStart
          : flightStart as ScanPassPoint?,
      flightTarget: identical(flightTarget, _unchanged)
          ? _flightTarget
          : flightTarget as ScanPassPoint?,
      flightElapsed: flightElapsed ?? _flightElapsed,
      flightDuration: flightDuration ?? _flightDuration,
      flightReceiverNumber: flightReceiverNumber ?? _flightReceiverNumber,
      flightDefendersAtRelease:
          flightDefendersAtRelease ?? _flightDefendersAtRelease,
      touchStart: identical(touchStart, _unchanged)
          ? _touchStart
          : touchStart as ScanPassPoint?,
      touchEnd: identical(touchEnd, _unchanged)
          ? _touchEnd
          : touchEnd as ScanPassPoint?,
      touchElapsed: touchElapsed ?? _touchElapsed,
      touchDuration: touchDuration ?? _touchDuration,
      touchDefendersAtStart: touchDefendersAtStart ?? _touchDefendersAtStart,
    );
  }
}

class SpaceEngine {
  const SpaceEngine();

  SpaceScenario scenario(int seed) {
    if (seed == 0) return _seedZeroScenario();

    final random = _SeededNoise(seed);
    final mirror = random.nextBool();
    final centreY = 0.48 + random.range(-0.08, 0.08);
    final passer = ScanPassPoint(
      0.18 + random.range(-0.025, 0.025),
      _mirrorY(centreY + random.range(-0.025, 0.025), mirror),
    );
    final receiver = ScanPassPoint(
      0.37 + random.range(-0.025, 0.035),
      _mirrorY(centreY + random.range(-0.04, 0.04), mirror),
    );
    final support = ScanPassPoint(
      0.58 + random.range(-0.04, 0.05),
      _mirrorY(centreY - 0.16 + random.range(-0.05, 0.06), mirror),
    );
    final pressureFromTop = random.nextBool();
    final pressureSign = (pressureFromTop ? -1.0 : 1.0) * (mirror ? -1 : 1);
    final marker = ScanPassPoint(
      receiver.x + 0.075 + random.range(-0.02, 0.035),
      _fieldY(receiver.y + (0.12 * pressureSign) + random.range(-0.025, 0.025)),
    );
    final cover = ScanPassPoint(
      support.x + 0.07 + random.range(-0.025, 0.035),
      _fieldY(0.50 + random.range(-0.10, 0.10)),
    );
    final supportEnd = _field(ScanPassPoint(
      support.x + 0.18 + random.range(-0.025, 0.055),
      _fieldY(support.y - (0.08 * pressureSign) + random.range(-0.03, 0.03)),
    ));

    return SpaceScenario(
      seed: seed,
      initial: _stateFromPlayers(
        attackers: <AttackPlayer>[
          AttackPlayer(
            number: 4,
            position: _field(passer),
            facingRadians: 0,
          ),
          AttackPlayer(
            number: 6,
            position: _field(receiver),
            facingRadians: 0,
          ),
          AttackPlayer(
            number: 8,
            position: _field(support),
            facingRadians: 0,
          ),
        ],
        defenders: <AttackPlayer>[
          AttackPlayer(
            number: 2,
            position: _field(marker),
            opponent: true,
            facingRadians: math.pi,
          ),
          AttackPlayer(
            number: 3,
            position: _field(cover),
            opponent: true,
            facingRadians: math.pi,
          ),
        ],
        carrierNumber: 4,
      ),
      supportEnd: supportEnd,
    );
  }

  SpaceState start(SpaceScenario scenario) {
    return SpaceState(
      scenario: scenario,
      pitch: scenario.initial,
      phase: SpacePhase.positioning,
      elapsed: 0,
    );
  }

  SpaceState aimReceive(SpaceState state, ScanPassPoint target) {
    if (state.phase != SpacePhase.positioning) return state;
    final learner = _attacker(state.pitch, 6);
    return state._copyWith(
      receiveTarget: _cleanPoint(target, learner.position),
      outcome: null,
      reason: null,
    );
  }

  SpaceState advance(SpaceState state, double seconds) {
    final safeSeconds = _safeSeconds(seconds);
    if (safeSeconds <= 0 || state.finished) return state;

    return switch (state.phase) {
      SpacePhase.positioning => _advanceOpenState(state, safeSeconds),
      SpacePhase.incoming => _advanceFlight(state, safeSeconds),
      SpacePhase.received => _advanceOpenState(state, safeSeconds),
      SpacePhase.touching => _advanceTouch(state, safeSeconds),
      SpacePhase.releasing => _advanceOpenState(state, safeSeconds),
      SpacePhase.outgoing => _advanceFlight(state, safeSeconds),
      SpacePhase.complete => state,
    };
  }

  SpaceState receive(SpaceState state) {
    if (state.phase != SpacePhase.positioning || state.receiveTarget == null) {
      return state;
    }
    final target =
        _cleanPoint(state.receiveTarget!, _attacker(state.pitch, 6).position);
    final start = state.pitch.ball;
    final duration = _flightDuration(start, target, _incomingPassSpeed);
    return state._copyWith(
      phase: SpacePhase.incoming,
      receiveTarget: target,
      outcome: null,
      reason: null,
      flightStart: start,
      flightTarget: target,
      flightElapsed: 0,
      flightDuration: duration,
      flightReceiverNumber: 6,
      flightDefendersAtRelease: state.pitch.defenders,
      touchStart: null,
      touchEnd: null,
      touchElapsed: 0,
      touchDuration: 0,
      touchDefendersAtStart: const <AttackPlayer>[],
    );
  }

  SpaceState touch(SpaceState state, ScanPassPoint target) {
    if (state.phase != SpacePhase.received) return state;
    final learner = _attacker(state.pitch, 6);
    final safeTarget = _boundedTouchTarget(
      learner.position,
      _cleanPoint(target, learner.position),
    );
    final distance = distanceMetres(learner.position, safeTarget);
    final duration = distance <= _epsilon
        ? _minimumTouchDuration
        : (distance / _touchSpeed)
            .clamp(_minimumTouchDuration, _maximumTouchDuration)
            .toDouble();
    return state._copyWith(
      phase: SpacePhase.touching,
      touchTarget: safeTarget,
      outcome: null,
      reason: null,
      touchStart: learner.position,
      touchEnd: safeTarget,
      touchElapsed: 0,
      touchDuration: duration,
      touchDefendersAtStart: state.pitch.defenders,
      flightStart: null,
      flightTarget: null,
      flightElapsed: 0,
      flightDuration: 0,
      flightReceiverNumber: 0,
      flightDefendersAtRelease: const <AttackPlayer>[],
    );
  }

  SpaceState pass(SpaceState state, ScanPassPoint target) {
    if (state.phase != SpacePhase.releasing) return state;
    final safeTarget = _cleanPoint(target, _attacker(state.pitch, 8).position);
    final start = state.pitch.ball;
    return state._copyWith(
      phase: SpacePhase.outgoing,
      passTarget: safeTarget,
      outcome: null,
      reason: null,
      flightStart: start,
      flightTarget: safeTarget,
      flightElapsed: 0,
      flightDuration: _flightDuration(start, safeTarget, _outgoingPassSpeed),
      flightReceiverNumber: 8,
      flightDefendersAtRelease: state.pitch.defenders,
    );
  }

  double distanceMetres(ScanPassPoint a, ScanPassPoint b) =>
      _distanceMetres(a, b);

  SpaceScenario _seedZeroScenario() {
    const passer = ScanPassPoint(0.20, 0.50);
    const learner = ScanPassPoint(0.40, 0.50);
    const support = ScanPassPoint(0.60, 0.40);
    const marker = ScanPassPoint(0.49, 0.37);
    const cover = ScanPassPoint(0.66, 0.55);
    const supportEnd = ScanPassPoint(0.86, 0.24);
    return SpaceScenario(
      seed: 0,
      initial: _stateFromPlayers(
        attackers: const <AttackPlayer>[
          AttackPlayer(number: 4, position: passer, facingRadians: 0),
          AttackPlayer(number: 6, position: learner, facingRadians: 0),
          AttackPlayer(number: 8, position: support, facingRadians: 0),
        ],
        defenders: const <AttackPlayer>[
          AttackPlayer(
            number: 2,
            position: marker,
            opponent: true,
            facingRadians: math.pi,
          ),
          AttackPlayer(
            number: 3,
            position: cover,
            opponent: true,
            facingRadians: math.pi,
          ),
        ],
        carrierNumber: 4,
      ),
      supportEnd: supportEnd,
    );
  }

  SpaceState _advanceOpenState(SpaceState state, double seconds) {
    var current = state;
    var remaining = seconds.clamp(0.0, _maximumAdvanceSeconds).toDouble();
    while (remaining > _epsilon) {
      final dt = math.min(_stepSeconds, remaining);
      current = _advanceOpenStep(current, dt);
      remaining -= dt;
    }
    return current;
  }

  SpaceState _advanceOpenStep(SpaceState state, double seconds) {
    final pitch = state.pitch;
    final attackers = List<AttackPlayer>.from(pitch.attackers);
    final four = _attacker(pitch, 4);
    final six = _attacker(pitch, 6);
    final eight = _attacker(pitch, 8);
    AttackPlayer nextSix = six;
    AttackPlayer nextEight = eight;

    if (state.phase == SpacePhase.positioning && state.receiveTarget != null) {
      nextSix = _movePlayer(
        six,
        state.receiveTarget!,
        _learnerRunSpeed,
        seconds,
      );
      nextEight = _movePlayer(
        eight,
        state.scenario.supportEnd,
        _supportDriftSpeed,
        seconds,
      );
    } else if (state.phase == SpacePhase.received ||
        state.phase == SpacePhase.releasing) {
      nextSix = six.copyWith(velocity: const ScanPassPoint(0, 0));
      nextEight = _movePlayer(
        eight,
        state.scenario.supportEnd,
        _supportRunSpeed,
        seconds,
      );
    }

    _replace(attackers, nextSix);
    _replace(attackers, nextEight);
    final ball = state.phase == SpacePhase.positioning
        ? four.position
        : nextSix.position;
    final defenders = _moveDefenders(
      state: state,
      attackers: attackers,
      ball: ball,
      receiverNumber: state.phase == SpacePhase.positioning ? 6 : 8,
      seconds: seconds,
    );
    final nextPitch = _copyPitch(
      pitch,
      attackers: attackers,
      defenders: defenders,
      ball: ball,
      carrierNumber: pitch.carrierNumber,
      seconds: seconds,
    );
    return state._copyWith(
      pitch: nextPitch,
      elapsed: state.elapsed + seconds,
    );
  }

  SpaceState _advanceFlight(SpaceState state, double seconds) {
    if (state._flightStart == null ||
        state._flightTarget == null ||
        state._flightDuration <= 0) {
      return _complete(
        state,
        outcome: SpaceOutcome.unreachable,
        reason: SpaceReason.receiverLate,
      );
    }

    var current = state;
    var remaining = seconds.clamp(0.0, _maximumAdvanceSeconds).toDouble();
    while (remaining > _epsilon) {
      final durationLeft =
          math.max(0.0, current._flightDuration - current._flightElapsed);
      final dt = math.min(_stepSeconds, math.min(remaining, durationLeft));
      current = _advanceFlightStep(current, dt);
      if (current.phase != state.phase || current.finished || dt <= _epsilon) {
        return current;
      }
      remaining -= dt;
    }
    return current;
  }

  SpaceState _advanceFlightStep(SpaceState state, double seconds) {
    final target = state._flightTarget!;
    final progress = ((state._flightElapsed + seconds) / state._flightDuration)
        .clamp(0.0, 1.0)
        .toDouble();
    final ball = state._flightStart!.lerp(target, progress);
    final pitch = state.pitch;
    final attackers = List<AttackPlayer>.from(pitch.attackers);
    final six = _attacker(pitch, 6);
    final eight = _attacker(pitch, 8);

    if (state.phase == SpacePhase.incoming) {
      _replace(
        attackers,
        _movePlayer(six, target, _learnerRunSpeed, seconds),
      );
      _replace(
        attackers,
        _movePlayer(
            eight, state.scenario.supportEnd, _supportDriftSpeed, seconds),
      );
    } else {
      _replace(
        attackers,
        six.copyWith(velocity: const ScanPassPoint(0, 0)),
      );
      _replace(
        attackers,
        _movePlayer(
            eight, state.scenario.supportEnd, _supportRunSpeed, seconds),
      );
    }

    final defenders = _moveDefenders(
      state: state,
      attackers: attackers,
      ball: ball,
      receiverNumber: state._flightReceiverNumber,
      seconds: seconds,
    );
    final nextPitch = _copyPitch(
      pitch,
      attackers: attackers,
      defenders: defenders,
      ball: ball,
      carrierNumber: pitch.carrierNumber,
      seconds: seconds,
    );
    final next = state._copyWith(
      pitch: nextPitch,
      elapsed: state.elapsed + seconds,
      flightElapsed: state._flightElapsed + seconds,
    );

    final interceptor = _interceptorOnBall(
      next.pitch,
      target,
      state._flightReceiverNumber,
      next._flightElapsed,
    );
    if (interceptor != null && progress < 0.98) {
      return _completeFlight(
        next,
        outcome: SpaceOutcome.intercepted,
        reason: SpaceReason.closedLane,
        defenderNumber: interceptor.number,
      );
    }

    if (progress >= 1 - _epsilon) {
      return _resolveFlightArrival(next);
    }
    return next;
  }

  SpaceState _resolveFlightArrival(SpaceState state) {
    final target = state._flightTarget!;
    final receiver = _attacker(state.pitch, state._flightReceiverNumber);
    final nearest = _nearestDefender(state.pitch.defenders, target);
    final receiverGap = distanceMetres(receiver.position, target);
    final defenderGap = distanceMetres(nearest.position, target);
    final margin = defenderGap - receiverGap;
    final reception = _reception(
      state,
      target: target,
      receiver: receiver,
      defenderNumber: nearest.number,
      marginMetres: margin,
    );

    if (receiverGap > _receiveControlRadius) {
      return _complete(
        state,
        outcome: SpaceOutcome.unreachable,
        reason: SpaceReason.receiverLate,
        reception: reception,
      );
    }
    if (defenderGap <= _defenderControlRadius &&
        defenderGap + _interceptAdvantage < receiverGap) {
      return _complete(
        state,
        outcome: SpaceOutcome.intercepted,
        reason: SpaceReason.defenderArrived,
        reception: reception,
      );
    }

    final outcome =
        margin >= _openMargin ? SpaceOutcome.open : SpaceOutcome.pressured;
    final reason = outcome == SpaceOutcome.open
        ? SpaceReason.spaceHeld
        : SpaceReason.defenderArrived;
    if (state.phase == SpacePhase.incoming) {
      final pitch = _completeReceivedPitch(state.pitch, receiver.position);
      return state._copyWith(
        pitch: pitch,
        phase: SpacePhase.received,
        outcome: outcome,
        reason: reason,
        reception: reception,
        flightStart: null,
        flightTarget: null,
        flightElapsed: 0,
        flightDuration: 0,
        flightReceiverNumber: 0,
        flightDefendersAtRelease: const <AttackPlayer>[],
      );
    }

    return _complete(
      state,
      outcome: outcome,
      reason: reason,
      reception: reception,
      pitch: _completeSupportPitch(state.pitch, receiver.position),
    );
  }

  SpaceState _advanceTouch(SpaceState state, double seconds) {
    if (state._touchStart == null ||
        state._touchEnd == null ||
        state._touchDuration <= 0) {
      return state._copyWith(phase: SpacePhase.releasing);
    }

    var current = state;
    var remaining = seconds.clamp(0.0, _maximumAdvanceSeconds).toDouble();
    while (remaining > _epsilon) {
      final durationLeft =
          math.max(0.0, current._touchDuration - current._touchElapsed);
      final dt = math.min(_stepSeconds, math.min(remaining, durationLeft));
      current = _advanceTouchStep(current, dt);
      if (current.phase != SpacePhase.touching || current.finished) {
        return current;
      }
      remaining -= dt;
    }
    return current;
  }

  SpaceState _advanceTouchStep(SpaceState state, double seconds) {
    final touchStart = state._touchStart;
    final touchEnd = state._touchEnd;
    if (touchStart == null || touchEnd == null) {
      return state._copyWith(phase: SpacePhase.releasing);
    }
    final progress = ((state._touchElapsed + seconds) / state._touchDuration)
        .clamp(0.0, 1.0)
        .toDouble();
    final nextSixPosition = touchStart.lerp(touchEnd, progress);
    final pitch = state.pitch;
    final attackers = List<AttackPlayer>.from(pitch.attackers);
    final six = _attacker(pitch, 6);
    final eight = _attacker(pitch, 8);
    final nextSix = _movedExactly(six, nextSixPosition, seconds);
    final nextEight = _movePlayer(
      eight,
      state.scenario.supportEnd,
      _supportRunSpeed,
      seconds,
    );
    _replace(attackers, nextSix);
    _replace(attackers, nextEight);

    final defenders = _moveDefenders(
      state: state,
      attackers: attackers,
      ball: nextSix.position,
      receiverNumber: 8,
      seconds: seconds,
    );
    final nextPitch = _copyPitch(
      pitch,
      attackers: attackers,
      defenders: defenders,
      ball: nextSix.position,
      carrierNumber: 6,
      seconds: seconds,
    );
    final next = state._copyWith(
      pitch: nextPitch,
      elapsed: state.elapsed + seconds,
      touchElapsed: state._touchElapsed + seconds,
    );
    final nearest = _nearestDefender(next.pitch.defenders, nextSix.position);
    final defenderGap = distanceMetres(nearest.position, nextSix.position);
    final startGap = distanceMetres(
        _touchDefender(next, nearest.number).position, touchStart);
    final ranIntoPressure = defenderGap < _touchTackleRadius ||
        (defenderGap < _touchDangerRadius && defenderGap + 0.45 < startGap);

    if (ranIntoPressure && progress > 0.25) {
      return _complete(
        next,
        outcome: SpaceOutcome.intercepted,
        reason: SpaceReason.touchIntoPressure,
        reception: _reception(
          next,
          target: touchEnd,
          receiver: _attacker(next.pitch, 6),
          defenderNumber: nearest.number,
          marginMetres: defenderGap,
          touchRelease: true,
        ),
      );
    }

    if (progress >= 1 - _epsilon) {
      final margin = defenderGap;
      final outcome =
          margin >= _openMargin ? SpaceOutcome.open : SpaceOutcome.pressured;
      return next._copyWith(
        phase: SpacePhase.releasing,
        outcome: outcome,
        reason: outcome == SpaceOutcome.open
            ? SpaceReason.spaceHeld
            : SpaceReason.defenderArrived,
        reception: _reception(
          next,
          target: touchEnd,
          receiver: _attacker(next.pitch, 6),
          defenderNumber: nearest.number,
          marginMetres: margin,
          touchRelease: true,
        ),
        touchStart: null,
        touchEnd: null,
        touchElapsed: 0,
        touchDuration: 0,
        touchDefendersAtStart: const <AttackPlayer>[],
      );
    }
    return next;
  }

  SpaceState _completeFlight(
    SpaceState state, {
    required SpaceOutcome outcome,
    required SpaceReason reason,
    required int defenderNumber,
  }) {
    final target = state._flightTarget!;
    final receiver = _attacker(state.pitch, state._flightReceiverNumber);
    final defender = _defender(state.pitch, defenderNumber);
    final margin = distanceMetres(defender.position, state.pitch.ball) -
        distanceMetres(receiver.position, state.pitch.ball);
    return _complete(
      state,
      outcome: outcome,
      reason: reason,
      reception: _reception(
        state,
        target: target,
        receiver: receiver,
        defenderNumber: defenderNumber,
        marginMetres: margin,
      ),
    );
  }

  SpaceState _complete(
    SpaceState state, {
    required SpaceOutcome outcome,
    required SpaceReason reason,
    SpaceReception? reception,
    AttackState? pitch,
  }) {
    return state._copyWith(
      pitch: pitch,
      phase: SpacePhase.complete,
      outcome: outcome,
      reason: reason,
      reception: reception ?? state.reception,
      flightStart: null,
      flightTarget: null,
      flightElapsed: 0,
      flightDuration: 0,
      flightReceiverNumber: 0,
      flightDefendersAtRelease: const <AttackPlayer>[],
      touchStart: null,
      touchEnd: null,
      touchElapsed: 0,
      touchDuration: 0,
      touchDefendersAtStart: const <AttackPlayer>[],
    );
  }

  SpaceReception _reception(
    SpaceState state, {
    required ScanPassPoint target,
    required AttackPlayer receiver,
    required int defenderNumber,
    required double marginMetres,
    bool touchRelease = false,
  }) {
    final releaseDefender = touchRelease
        ? _touchDefender(state, defenderNumber)
        : _releaseDefender(state, defenderNumber);
    final arrivalDefender = _defender(state.pitch, defenderNumber);
    return SpaceReception(
      target: target,
      receiverPosition: receiver.position,
      defenderStart: releaseDefender.position,
      defenderArrival: arrivalDefender.position,
      marginMetres: marginMetres,
      receiverNumber: receiver.number,
    );
  }

  AttackState _completeReceivedPitch(AttackState pitch, ScanPassPoint ball) {
    final attackers = List<AttackPlayer>.from(pitch.attackers);
    final six = _attacker(pitch, 6).copyWith(
      position: ball,
      velocity: const ScanPassPoint(0, 0),
    );
    _replace(attackers, six);
    return pitch.copyWith(
      attackers: attackers,
      ball: ball,
      carrierNumber: 6,
      actionCount: pitch.actionCount + 1,
      completedPasses: pitch.completedPasses + 1,
      furthestX: math.max(pitch.furthestX, ball.x),
      cue: AttackCue.received,
    );
  }

  AttackState _completeSupportPitch(AttackState pitch, ScanPassPoint ball) {
    final attackers = List<AttackPlayer>.from(pitch.attackers);
    final eight = _attacker(pitch, 8).copyWith(
      position: ball,
      velocity: const ScanPassPoint(0, 0),
    );
    _replace(attackers, eight);
    return pitch.copyWith(
      attackers: attackers,
      ball: ball,
      carrierNumber: 8,
      actionCount: pitch.actionCount + 1,
      completedPasses: pitch.completedPasses + 1,
      furthestX: math.max(pitch.furthestX, ball.x),
      cue: AttackCue.received,
    );
  }
}

const Object _unchanged = Object();
const double _pitchWidthMetres = 30;
const double _pitchHeightMetres = 20;
const double _stepSeconds = 1 / 60;
const double _maximumAdvanceSeconds = 30;
const double _incomingPassSpeed = 13.5;
const double _outgoingPassSpeed = 12.5;
const double _learnerRunSpeed = 5.0;
const double _supportRunSpeed = 4.7;
const double _supportDriftSpeed = 1.6;
const double _markerSpeed = 4.75;
const double _coverSpeed = 4.45;
const double _touchSpeed = 3.8;
const double _maxTouchMetres = 4.0;
const double _minimumTouchDuration = 0.16;
const double _maximumTouchDuration = 1.15;
const double _turnRate = math.pi * 1.9;
const double _defenderTurnRate = math.pi * 1.7;
const double _receiveControlRadius = 1.35;
const double _defenderControlRadius = 0.95;
const double _dynamicInterceptRadius = 0.85;
const double _interceptAdvantage = 0.18;
const double _openMargin = 1.7;
const double _touchTackleRadius = 0.62;
const double _touchDangerRadius = 1.15;
const double _epsilon = 1e-9;

AttackState _stateFromPlayers({
  required List<AttackPlayer> attackers,
  required List<AttackPlayer> defenders,
  required int carrierNumber,
}) {
  return AttackState(
    attackers: attackers,
    defenders: defenders,
    ball: attackers
        .firstWhere((player) => player.number == carrierNumber)
        .position,
    carrierNumber: carrierNumber,
  );
}

AttackState _copyPitch(
  AttackState pitch, {
  required List<AttackPlayer> attackers,
  required List<AttackPlayer> defenders,
  required ScanPassPoint ball,
  required int carrierNumber,
  required double seconds,
}) {
  return pitch.copyWith(
    attackers: attackers,
    defenders: defenders,
    ball: ball,
    carrierNumber: carrierNumber,
    elapsed: pitch.elapsed + seconds,
    furthestX: math.max(pitch.furthestX, ball.x),
  );
}

List<AttackPlayer> _moveDefenders({
  required SpaceState state,
  required List<AttackPlayer> attackers,
  required ScanPassPoint ball,
  required int receiverNumber,
  required double seconds,
}) {
  final marker = _defenderFrom(state.pitch.defenders, 2);
  final cover = _defenderFrom(state.pitch.defenders, 3);
  final receiver =
      attackers.firstWhere((player) => player.number == receiverNumber);
  final learner = attackers.firstWhere((player) => player.number == 6);
  final support = attackers.firstWhere((player) => player.number == 8);

  final markerTarget = switch (state.phase) {
    SpacePhase.positioning => _markingPoint(learner.position, ball, 1.15),
    SpacePhase.incoming =>
      _reactiveBallOrMark(marker.position, ball, receiver.position),
    SpacePhase.received ||
    SpacePhase.touching ||
    SpacePhase.releasing =>
      _markingPoint(learner.position, ball, 0.45),
    SpacePhase.outgoing =>
      _reactiveBallOrMark(marker.position, ball, receiver.position),
    SpacePhase.complete => marker.position,
  };
  final coverTarget = switch (state.phase) {
    SpacePhase.positioning => _lanePoint(ball, support.position, 0.58),
    SpacePhase.incoming => _lanePoint(ball, receiver.position, 0.68),
    SpacePhase.received ||
    SpacePhase.touching ||
    SpacePhase.releasing =>
      _lanePoint(ball, support.position, 0.60),
    SpacePhase.outgoing => _lanePoint(ball, receiver.position, 0.54),
    SpacePhase.complete => cover.position,
  };

  return <AttackPlayer>[
    _movePlayer(
      marker,
      markerTarget,
      _markerSpeed,
      seconds,
      turnRate: _defenderTurnRate,
    ),
    _movePlayer(
      cover,
      coverTarget,
      _coverSpeed,
      seconds,
      turnRate: _defenderTurnRate,
    ),
  ];
}

AttackPlayer? _interceptorOnBall(
  AttackState pitch,
  ScanPassPoint target,
  int receiverNumber,
  double flightElapsed,
) {
  if (flightElapsed < 0.08) return null;
  final receiver = _attacker(pitch, receiverNumber);
  final receiverBallGap = _distanceMetres(receiver.position, pitch.ball);
  for (final defender in pitch.defenders) {
    final defenderBallGap = _distanceMetres(defender.position, pitch.ball);
    final defenderTargetGap = _distanceMetres(defender.position, target);
    if (defenderBallGap <= _dynamicInterceptRadius &&
        defenderBallGap + _interceptAdvantage < receiverBallGap &&
        defenderTargetGap < receiverBallGap + 1.2) {
      return defender;
    }
  }
  return null;
}

AttackPlayer _attacker(AttackState state, int number) =>
    state.attackers.firstWhere((player) => player.number == number);

AttackPlayer _defender(AttackState state, int number) =>
    _defenderFrom(state.defenders, number);

AttackPlayer _defenderFrom(List<AttackPlayer> defenders, int number) =>
    defenders.firstWhere((player) => player.number == number);

AttackPlayer _releaseDefender(SpaceState state, int defenderNumber) {
  if (state._flightDefendersAtRelease.isEmpty) {
    return _defender(state.pitch, defenderNumber);
  }
  return state._flightDefendersAtRelease.firstWhere(
    (player) => player.number == defenderNumber,
    orElse: () => _defender(state.pitch, defenderNumber),
  );
}

AttackPlayer _touchDefender(SpaceState state, int defenderNumber) {
  if (state._touchDefendersAtStart.isEmpty) {
    return _defender(state.pitch, defenderNumber);
  }
  return state._touchDefendersAtStart.firstWhere(
    (player) => player.number == defenderNumber,
    orElse: () => _defender(state.pitch, defenderNumber),
  );
}

AttackPlayer _nearestDefender(
    List<AttackPlayer> defenders, ScanPassPoint point) {
  var nearest = defenders.first;
  var nearestDistance = _distanceMetres(nearest.position, point);
  for (final defender in defenders.skip(1)) {
    final distance = _distanceMetres(defender.position, point);
    if (distance < nearestDistance) {
      nearest = defender;
      nearestDistance = distance;
    }
  }
  return nearest;
}

void _replace(List<AttackPlayer> players, AttackPlayer replacement) {
  final index =
      players.indexWhere((player) => player.number == replacement.number);
  if (index >= 0) players[index] = replacement;
}

AttackPlayer _movedExactly(
  AttackPlayer player,
  ScanPassPoint position,
  double seconds,
) {
  final safeSeconds = seconds > _epsilon ? seconds : 1;
  final delta = position - player.position;
  return player.copyWith(
    position: _field(position),
    velocity: delta * (1 / safeSeconds),
    facingRadians: _distanceMetres(player.position, position) > 0.05
        ? _angleMetres(player.position, position)
        : player.facingRadians,
  );
}

AttackPlayer _movePlayer(
  AttackPlayer player,
  ScanPassPoint target,
  double speedMetresPerSecond,
  double seconds, {
  double turnRate = _turnRate,
}) {
  if (seconds <= _epsilon) return player;
  final safeTarget = _field(target);
  final distance = _distanceMetres(player.position, safeTarget);
  if (distance <= 0.05 || speedMetresPerSecond <= 0) {
    return player.copyWith(velocity: const ScanPassPoint(0, 0));
  }

  final desired = _angleMetres(player.position, safeTarget);
  final current =
      player.facingRadians.isFinite ? player.facingRadians : desired;
  final facing = _turnToward(current, desired, turnRate * seconds);
  final error = _angleDelta(facing, desired).abs();
  final alignment = (0.35 + (0.65 * math.max(0, math.cos(error))))
      .clamp(0.35, 1.0)
      .toDouble();
  final step = math.min(distance, speedMetresPerSecond * seconds * alignment);
  var next = _translateMetres(
    player.position,
    math.cos(facing) * step,
    math.sin(facing) * step,
  );
  if (_distanceMetres(next, safeTarget) > distance && error > math.pi / 2) {
    next = player.position;
  }
  final velocity = ScanPassPoint(
    (next.x - player.position.x) / seconds,
    (next.y - player.position.y) / seconds,
  );
  return player.copyWith(
    position: next,
    velocity: velocity,
    facingRadians: facing,
  );
}

ScanPassPoint _reactiveBallOrMark(
  ScanPassPoint defender,
  ScanPassPoint ball,
  ScanPassPoint receiver,
) {
  final ballGap = _distanceMetres(defender, ball);
  final receiverGap = _distanceMetres(defender, receiver);
  if (ballGap < receiverGap + 1.0) return ball;
  return _markingPoint(receiver, ball, 0.65);
}

ScanPassPoint _markingPoint(
  ScanPassPoint receiver,
  ScanPassPoint ball,
  double cushionMetres,
) {
  final dx = (ball.x - receiver.x) * _pitchWidthMetres;
  final dy = (ball.y - receiver.y) * _pitchHeightMetres;
  final length = math.sqrt((dx * dx) + (dy * dy));
  if (length <= _epsilon) return _field(receiver);
  return _translateMetres(
    receiver,
    dx / length * cushionMetres,
    dy / length * cushionMetres,
  );
}

ScanPassPoint _lanePoint(
    ScanPassPoint from, ScanPassPoint to, double fraction) {
  return _field(from.lerp(to, fraction));
}

ScanPassPoint _boundedTouchTarget(ScanPassPoint from, ScanPassPoint target) {
  final distance = _distanceMetres(from, target);
  if (distance <= _maxTouchMetres || distance <= _epsilon) {
    return _field(target);
  }
  final dx = (target.x - from.x) * _pitchWidthMetres / distance;
  final dy = (target.y - from.y) * _pitchHeightMetres / distance;
  return _translateMetres(from, dx * _maxTouchMetres, dy * _maxTouchMetres);
}

double _flightDuration(
  ScanPassPoint start,
  ScanPassPoint target,
  double speedMetresPerSecond,
) {
  final distance = _distanceMetres(start, target);
  return (distance / speedMetresPerSecond).clamp(0.18, 1.45).toDouble();
}

double _distanceMetres(ScanPassPoint a, ScanPassPoint b) {
  final ax = a.x.isFinite ? a.x : 0.0;
  final ay = a.y.isFinite ? a.y : 0.0;
  final bx = b.x.isFinite ? b.x : 0.0;
  final by = b.y.isFinite ? b.y : 0.0;
  final dx = (ax - bx) * _pitchWidthMetres;
  final dy = (ay - by) * _pitchHeightMetres;
  return math.sqrt((dx * dx) + (dy * dy));
}

ScanPassPoint _translateMetres(
  ScanPassPoint point,
  double dxMetres,
  double dyMetres,
) {
  return _field(ScanPassPoint(
    point.x + (dxMetres / _pitchWidthMetres),
    point.y + (dyMetres / _pitchHeightMetres),
  ));
}

double _angleMetres(ScanPassPoint from, ScanPassPoint to) {
  final dx = (to.x - from.x) * _pitchWidthMetres;
  final dy = (to.y - from.y) * _pitchHeightMetres;
  return math.atan2(dy, dx);
}

double _turnToward(double current, double target, double maxTurn) {
  final delta = _angleDelta(target, current);
  if (delta.abs() <= maxTurn) return target;
  return current + (delta.sign * maxTurn);
}

double _angleDelta(double target, double current) {
  var delta = target - current;
  while (delta > math.pi) {
    delta -= math.pi * 2;
  }
  while (delta < -math.pi) {
    delta += math.pi * 2;
  }
  return delta;
}

ScanPassPoint _cleanPoint(ScanPassPoint point, ScanPassPoint fallback) {
  return _field(ScanPassPoint(
    point.x.isFinite ? point.x : fallback.x,
    point.y.isFinite ? point.y : fallback.y,
  ));
}

ScanPassPoint _field(ScanPassPoint point) => ScanPassPoint(
      (point.x.isFinite ? point.x : 0.5).clamp(0.0, 1.0).toDouble(),
      (point.y.isFinite ? point.y : 0.5).clamp(0.0, 1.0).toDouble(),
    );

double _fieldY(double y) => y.clamp(0.06, 0.94).toDouble();

double _mirrorY(double y, bool mirror) => mirror ? 1 - y : y;

double _safeSeconds(double seconds) {
  if (!seconds.isFinite || seconds <= 0) return 0;
  return seconds.clamp(0.0, _maximumAdvanceSeconds).toDouble();
}

class _SeededNoise {
  int _state;

  _SeededNoise(int seed) : _state = seed == 0 ? 1 : seed & 0x7fffffff;

  bool nextBool() => nextDouble() >= 0.5;

  double range(double min, double max) => min + ((max - min) * nextDouble());

  double nextDouble() {
    _state = ((_state * 1664525) + 1013904223) & 0x7fffffff;
    return _state / 0x7fffffff;
  }
}
