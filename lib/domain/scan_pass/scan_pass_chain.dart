import 'dart:math' as math;

import 'scan_pass_attack.dart';
import 'scan_pass_game.dart' show ScanPassPoint;

enum ChainPhase {
  prepareTouch,
  receiving,
  touching,
  decide,
  acting,
  prepareRun,
  running,
  complete,
}

enum ChainActionKind { pass, carry, turn }

enum ChainEnd {
  linked,
  lostTouch,
  intercepted,
  crowded,
  noReturnLane,
  supportPressed,
}

enum ChainMoment {
  beforeTouch,
  afterTouch,
  afterAction,
  afterRun,
  returnReady,
}

class ChainAction {
  final ChainActionKind kind;
  final int? receiverNumber;
  final ScanPassPoint? target;

  const ChainAction.pass(int receiver)
      : kind = ChainActionKind.pass,
        receiverNumber = receiver,
        target = null;

  const ChainAction.carry(this.target)
      : kind = ChainActionKind.carry,
        receiverNumber = null;

  const ChainAction.turn(this.target)
      : kind = ChainActionKind.turn,
        receiverNumber = null;
}

class ChainSnapshot {
  final ChainMoment moment;
  final AttackState pitch;
  final List<int> openPasses;
  final double pressureMetres;
  final int cycle;
  final ChainActionKind? action;
  final ScanPassPoint? target;

  ChainSnapshot({
    required this.moment,
    required this.pitch,
    required List<int> openPasses,
    required this.pressureMetres,
    required this.cycle,
    this.action,
    this.target,
  }) : openPasses = List<int>.unmodifiable(openPasses);
}

class ChainState {
  final int seed;
  final AttackState pitch;
  final ChainPhase phase;
  final double elapsed;
  final int returns;
  final bool returning;
  final ScanPassPoint? touchTarget;
  final ScanPassPoint? runTarget;
  final ChainAction? action;
  final ChainEnd? end;
  final List<ChainSnapshot> moments;

  final ScanPassPoint? _flightStart;
  final ScanPassPoint? _flightTarget;
  final double _flightElapsed;
  final double _flightDuration;
  final int _flightReceiverNumber;
  final bool _flightIsReturn;
  final ScanPassPoint? _touchStart;
  final ScanPassPoint? _touchEnd;
  final double _touchElapsed;
  final double _touchDuration;
  final ScanPassPoint? _motionStart;
  final ScanPassPoint? _motionEnd;
  final double _motionElapsed;
  final double _motionDuration;
  final double _turnDelayRemaining;
  final int? _passReceiverNumber;

  ChainState({
    required this.seed,
    required this.pitch,
    required this.phase,
    required this.elapsed,
    this.returns = 0,
    this.returning = false,
    this.touchTarget,
    this.runTarget,
    this.action,
    this.end,
    List<ChainSnapshot> moments = const <ChainSnapshot>[],
    ScanPassPoint? flightStart,
    ScanPassPoint? flightTarget,
    double flightElapsed = 0,
    double flightDuration = 0,
    int flightReceiverNumber = 0,
    bool flightIsReturn = false,
    ScanPassPoint? touchStart,
    ScanPassPoint? touchEnd,
    double touchElapsed = 0,
    double touchDuration = 0,
    ScanPassPoint? motionStart,
    ScanPassPoint? motionEnd,
    double motionElapsed = 0,
    double motionDuration = 0,
    double turnDelayRemaining = 0,
    int? passReceiverNumber,
  })  : moments = List<ChainSnapshot>.unmodifiable(moments),
        _flightStart = flightStart,
        _flightTarget = flightTarget,
        _flightElapsed = flightElapsed,
        _flightDuration = flightDuration,
        _flightReceiverNumber = flightReceiverNumber,
        _flightIsReturn = flightIsReturn,
        _touchStart = touchStart,
        _touchEnd = touchEnd,
        _touchElapsed = touchElapsed,
        _touchDuration = touchDuration,
        _motionStart = motionStart,
        _motionEnd = motionEnd,
        _motionElapsed = motionElapsed,
        _motionDuration = motionDuration,
        _turnDelayRemaining = turnDelayRemaining,
        _passReceiverNumber = passReceiverNumber;

  bool get finished => phase == ChainPhase.complete;
  bool get ballInFlight =>
      phase == ChainPhase.receiving ||
      (phase == ChainPhase.acting && _flightTarget != null);

  ChainState _copyWith({
    int? seed,
    AttackState? pitch,
    ChainPhase? phase,
    double? elapsed,
    int? returns,
    bool? returning,
    Object? touchTarget = _unchanged,
    Object? runTarget = _unchanged,
    Object? action = _unchanged,
    Object? end = _unchanged,
    List<ChainSnapshot>? moments,
    Object? flightStart = _unchanged,
    Object? flightTarget = _unchanged,
    double? flightElapsed,
    double? flightDuration,
    int? flightReceiverNumber,
    bool? flightIsReturn,
    Object? touchStart = _unchanged,
    Object? touchEnd = _unchanged,
    double? touchElapsed,
    double? touchDuration,
    Object? motionStart = _unchanged,
    Object? motionEnd = _unchanged,
    double? motionElapsed,
    double? motionDuration,
    double? turnDelayRemaining,
    Object? passReceiverNumber = _unchanged,
  }) {
    return ChainState(
      seed: seed ?? this.seed,
      pitch: pitch ?? this.pitch,
      phase: phase ?? this.phase,
      elapsed: elapsed ?? this.elapsed,
      returns: returns ?? this.returns,
      returning: returning ?? this.returning,
      touchTarget: identical(touchTarget, _unchanged)
          ? this.touchTarget
          : touchTarget as ScanPassPoint?,
      runTarget: identical(runTarget, _unchanged)
          ? this.runTarget
          : runTarget as ScanPassPoint?,
      action:
          identical(action, _unchanged) ? this.action : action as ChainAction?,
      end: identical(end, _unchanged) ? this.end : end as ChainEnd?,
      moments: moments ?? this.moments,
      flightStart: identical(flightStart, _unchanged)
          ? _flightStart
          : flightStart as ScanPassPoint?,
      flightTarget: identical(flightTarget, _unchanged)
          ? _flightTarget
          : flightTarget as ScanPassPoint?,
      flightElapsed: flightElapsed ?? _flightElapsed,
      flightDuration: flightDuration ?? _flightDuration,
      flightReceiverNumber: flightReceiverNumber ?? _flightReceiverNumber,
      flightIsReturn: flightIsReturn ?? _flightIsReturn,
      touchStart: identical(touchStart, _unchanged)
          ? _touchStart
          : touchStart as ScanPassPoint?,
      touchEnd: identical(touchEnd, _unchanged)
          ? _touchEnd
          : touchEnd as ScanPassPoint?,
      touchElapsed: touchElapsed ?? _touchElapsed,
      touchDuration: touchDuration ?? _touchDuration,
      motionStart: identical(motionStart, _unchanged)
          ? _motionStart
          : motionStart as ScanPassPoint?,
      motionEnd: identical(motionEnd, _unchanged)
          ? _motionEnd
          : motionEnd as ScanPassPoint?,
      motionElapsed: motionElapsed ?? _motionElapsed,
      motionDuration: motionDuration ?? _motionDuration,
      turnDelayRemaining: turnDelayRemaining ?? _turnDelayRemaining,
      passReceiverNumber: identical(passReceiverNumber, _unchanged)
          ? _passReceiverNumber
          : passReceiverNumber as int?,
    );
  }
}

class TouchChainEngine {
  const TouchChainEngine();

  ChainState start({int seed = 0}) {
    final pitch = _startPitch(seed);
    return ChainState(
      seed: seed,
      pitch: pitch,
      phase: ChainPhase.prepareTouch,
      elapsed: 0,
    );
  }

  ChainState takeTouch(ChainState state, ScanPassPoint target) {
    if (state.phase != ChainPhase.prepareTouch || state.finished) {
      return state;
    }
    final learner = _attacker(state.pitch, 6);
    final safeTarget = _boundedTarget(
      learner.position,
      _cleanPoint(target, learner.position),
      _maxTouchMetres,
    );
    final snapshot = _snapshot(
      state,
      ChainMoment.beforeTouch,
      target: safeTarget,
    );
    final carrier = state.pitch.carrier;
    return state._copyWith(
      phase: ChainPhase.receiving,
      touchTarget: safeTarget,
      moments: <ChainSnapshot>[...state.moments, snapshot],
      flightStart: state.pitch.ball,
      flightTarget: learner.position,
      flightElapsed: 0,
      flightDuration: _flightDuration(
        state.pitch.ball,
        learner.position,
        _passSpeed,
      ),
      flightReceiverNumber: 6,
      flightIsReturn: state.returning || carrier.number != 4,
      touchStart: null,
      touchEnd: null,
      touchElapsed: 0,
      touchDuration: 0,
      action: null,
      runTarget: null,
    );
  }

  ChainState act(ChainState state, ChainAction action) {
    if (state.phase != ChainPhase.decide ||
        state.finished ||
        state.pitch.carrierNumber != 6) {
      return state;
    }
    final learner = _attacker(state.pitch, 6);
    switch (action.kind) {
      case ChainActionKind.pass:
        final receiverNumber = action.receiverNumber;
        if (receiverNumber == null ||
            receiverNumber == state.pitch.carrierNumber ||
            (receiverNumber != 4 && receiverNumber != 8)) {
          return state;
        }
        final receiver = _attackerOrNull(state.pitch, receiverNumber);
        if (receiver == null) return state;
        final delay = _passTurnDelay(learner, receiver.position);
        return state._copyWith(
          phase: ChainPhase.acting,
          action: action,
          turnDelayRemaining: delay,
          passReceiverNumber: receiverNumber,
          flightStart: null,
          flightTarget: null,
          flightElapsed: 0,
          flightDuration: 0,
          flightReceiverNumber: 0,
          flightIsReturn: false,
          motionStart: null,
          motionEnd: null,
          motionElapsed: 0,
          motionDuration: 0,
        );
      case ChainActionKind.carry:
      case ChainActionKind.turn:
        final rawTarget = action.target;
        if (rawTarget == null) return state;
        final maxDistance = action.kind == ChainActionKind.carry
            ? _maxCarryMetres
            : _maxTurnMetres;
        final safeTarget = _boundedTarget(
          learner.position,
          _cleanPoint(rawTarget, learner.position),
          maxDistance,
        );
        final distance = distanceMetres(learner.position, safeTarget);
        final speed =
            action.kind == ChainActionKind.carry ? _carrySpeed : _turnMoveSpeed;
        final duration = (distance / speed)
            .clamp(_minimumMotionDuration, _maximumCarryDuration)
            .toDouble();
        return state._copyWith(
          phase: ChainPhase.acting,
          action: action,
          motionStart: learner.position,
          motionEnd: safeTarget,
          motionElapsed: 0,
          motionDuration: duration,
          turnDelayRemaining: 0,
          passReceiverNumber: null,
          flightStart: null,
          flightTarget: null,
          flightElapsed: 0,
          flightDuration: 0,
          flightReceiverNumber: 0,
          flightIsReturn: false,
        );
    }
  }

  ChainState run(ChainState state, ScanPassPoint target) {
    if (state.phase != ChainPhase.prepareRun ||
        state.finished ||
        state.pitch.carrierNumber == 6) {
      return state;
    }
    final learner = _attacker(state.pitch, 6);
    final safeTarget = _boundedTarget(
      learner.position,
      _cleanPoint(target, learner.position),
      _maxRunMetres,
    );
    final distance = distanceMetres(learner.position, safeTarget);
    final duration = (distance / _learnerRunSpeed)
        .clamp(_minimumMotionDuration, _maximumRunDuration)
        .toDouble();
    return state._copyWith(
      phase: ChainPhase.running,
      runTarget: safeTarget,
      motionStart: learner.position,
      motionEnd: safeTarget,
      motionElapsed: 0,
      motionDuration: duration,
      action: null,
      flightStart: null,
      flightTarget: null,
      flightElapsed: 0,
      flightDuration: 0,
      flightReceiverNumber: 0,
      flightIsReturn: false,
    );
  }

  ChainState advance(ChainState state, double seconds) {
    final safeSeconds = _safeSeconds(seconds);
    if (safeSeconds <= 0 || state.finished || _isHoldPhase(state.phase)) {
      return state;
    }

    var current = state;
    var remaining = safeSeconds;
    while (remaining > _epsilon && !current.finished) {
      if (_isHoldPhase(current.phase)) return current;
      final dt = _stepFor(current, remaining);
      if (dt <= _epsilon) return current;
      current = _advanceStep(current, dt);
      remaining -= dt;
    }
    return current;
  }

  double distanceMetres(ScanPassPoint a, ScanPassPoint b) =>
      _distanceMetres(a, b);

  List<int> openPasses(AttackState pitch) => _openPasses(pitch);

  ChainState _advanceStep(ChainState state, double seconds) {
    return switch (state.phase) {
      ChainPhase.receiving => _advanceFlightStep(state, seconds),
      ChainPhase.touching => _advanceTouchStep(state, seconds),
      ChainPhase.acting => _advanceActionStep(state, seconds),
      ChainPhase.running => _advanceRunStep(state, seconds),
      ChainPhase.prepareTouch ||
      ChainPhase.decide ||
      ChainPhase.prepareRun ||
      ChainPhase.complete =>
        state,
    };
  }

  ChainState _advanceFlightStep(ChainState state, double seconds) {
    final start = state._flightStart;
    final target = state._flightTarget;
    if (start == null || target == null || state._flightDuration <= 0) {
      return _complete(state, ChainEnd.intercepted);
    }

    final progress = ((state._flightElapsed + seconds) / state._flightDuration)
        .clamp(0.0, 1.0)
        .toDouble();
    final ball = start.lerp(target, progress);
    final attackers = List<AttackPlayer>.from(state.pitch.attackers);
    final defenders = _moveDefenders(
      state: state,
      attackers: attackers,
      ball: ball,
      receiverNumber: state._flightReceiverNumber,
      seconds: seconds,
    );
    final nextPitch = _copyPitch(
      state.pitch,
      attackers: attackers,
      defenders: defenders,
      ball: ball,
      carrierNumber: state.pitch.carrierNumber,
      seconds: seconds,
    );
    var next = state._copyWith(
      pitch: nextPitch,
      elapsed: state.elapsed + seconds,
      flightElapsed: state._flightElapsed + seconds,
    );

    final interceptor = _interceptorOnBall(
      next.pitch,
      state._flightReceiverNumber,
      progress,
    );
    if (interceptor != null && progress < 0.88) {
      return _complete(next, ChainEnd.intercepted);
    }

    if (progress >= 1 - _epsilon) {
      if (state.phase == ChainPhase.receiving) {
        return _finishIncomingFlight(next, target);
      }
      return _finishOutgoingPass(next, target);
    }
    return next;
  }

  ChainState _finishIncomingFlight(ChainState state, ScanPassPoint target) {
    final receiver = _attacker(state.pitch, 6);
    final nearest = _nearestDefender(state.pitch.defenders, target);
    final receiverGap = distanceMetres(receiver.position, target);
    final pressure = distanceMetres(nearest.position, target);
    if (receiverGap > _receiveRadius) {
      return _complete(state, ChainEnd.lostTouch);
    }
    if (pressure < _receiveCrowdedRadius &&
        pressure + _interceptAdvantage < receiverGap + 0.25) {
      return _complete(state, ChainEnd.intercepted);
    }

    final attackers = List<AttackPlayer>.from(state.pitch.attackers);
    final six = receiver.copyWith(
      position: target,
      velocity: const ScanPassPoint(0, 0),
    );
    _replace(attackers, six);
    final returns = state._flightIsReturn ? state.returns + 1 : state.returns;
    final pitch = state.pitch.copyWith(
      attackers: attackers,
      ball: target,
      carrierNumber: 6,
      completedPasses: state.pitch.completedPasses + 1,
      actionCount: state.pitch.actionCount + 1,
      furthestX: math.max(state.pitch.furthestX, target.x),
      cue: AttackCue.received,
    );
    return _beginTouch(
      state._copyWith(
        pitch: pitch,
        returns: returns,
        returning: state._flightIsReturn,
        flightStart: null,
        flightTarget: null,
        flightElapsed: 0,
        flightDuration: 0,
        flightReceiverNumber: 0,
        flightIsReturn: false,
      ),
    );
  }

  ChainState _beginTouch(ChainState state) {
    final learner = _attacker(state.pitch, 6);
    final target = state.touchTarget ?? learner.position;
    // Compare the same learner immediately before and after contact, rather
    // than comparing the passer's pressure with the receiver's pressure.
    // The provisional selection snapshot still covers an intercepted arrival.
    final moments = List<ChainSnapshot>.from(state.moments);
    if (moments.isNotEmpty && moments.last.moment == ChainMoment.beforeTouch) {
      moments.removeLast();
    }
    moments.add(_snapshot(state, ChainMoment.beforeTouch, target: target));
    final distance = distanceMetres(learner.position, target);
    final duration = (distance / _touchSpeed)
        .clamp(_minimumTouchDuration, _maximumTouchDuration)
        .toDouble();
    return state._copyWith(
      phase: ChainPhase.touching,
      moments: moments,
      touchStart: learner.position,
      touchEnd: target,
      touchElapsed: 0,
      touchDuration: duration,
    );
  }

  ChainState _advanceTouchStep(ChainState state, double seconds) {
    final start = state._touchStart;
    final target = state._touchEnd;
    if (start == null || target == null || state._touchDuration <= 0) {
      return state._copyWith(phase: ChainPhase.decide);
    }

    final progress = ((state._touchElapsed + seconds) / state._touchDuration)
        .clamp(0.0, 1.0)
        .toDouble();
    final position = start.lerp(target, progress);
    final attackers = List<AttackPlayer>.from(state.pitch.attackers);
    final six = _attacker(state.pitch, 6);
    _replace(attackers, _movedExactly(six, position, seconds));
    final defenders = _moveDefenders(
      state: state,
      attackers: attackers,
      ball: position,
      receiverNumber: 6,
      seconds: seconds,
    );
    final pitch = _copyPitch(
      state.pitch,
      attackers: attackers,
      defenders: defenders,
      ball: position,
      carrierNumber: 6,
      seconds: seconds,
    );
    var next = state._copyWith(
      pitch: pitch,
      elapsed: state.elapsed + seconds,
      touchElapsed: state._touchElapsed + seconds,
    );
    final pressure = _pressureMetres(next.pitch, position);
    if (progress > 0.25 && pressure < _touchLostRadius) {
      return _complete(next, ChainEnd.lostTouch);
    }

    if (progress >= 1 - _epsilon) {
      final snapshot = _snapshot(
        next,
        ChainMoment.afterTouch,
        target: target,
      );
      if (next.returning && next.returns >= _requiredReturns) {
        return _complete(
          next._copyWith(
            moments: <ChainSnapshot>[...next.moments, snapshot],
            touchStart: null,
            touchEnd: null,
            touchElapsed: 0,
            touchDuration: 0,
          ),
          ChainEnd.linked,
        );
      }
      return next._copyWith(
        phase: ChainPhase.decide,
        returning: false,
        moments: <ChainSnapshot>[...next.moments, snapshot],
        touchStart: null,
        touchEnd: null,
        touchElapsed: 0,
        touchDuration: 0,
        action: null,
      );
    }
    return next;
  }

  ChainState _advanceActionStep(ChainState state, double seconds) {
    final action = state.action;
    if (action == null) return state._copyWith(phase: ChainPhase.decide);

    if (action.kind == ChainActionKind.pass) {
      if (state._flightTarget != null) {
        return _advanceFlightStep(state, seconds);
      }
      if (state._turnDelayRemaining > _epsilon) {
        return _advancePassTurnStep(state, seconds);
      }
      return _startOutgoingPass(state);
    }
    return _advanceCarrierMotionStep(state, seconds);
  }

  ChainState _advancePassTurnStep(ChainState state, double seconds) {
    final receiverNumber = state._passReceiverNumber;
    if (receiverNumber == null) {
      return state._copyWith(phase: ChainPhase.decide);
    }
    final receiver = _attackerOrNull(state.pitch, receiverNumber);
    if (receiver == null) return _complete(state, ChainEnd.intercepted);
    final learner = _attacker(state.pitch, 6);
    final facing = _turnToward(
      learner.facingRadians,
      _angleMetres(learner.position, receiver.position),
      _turnRate * seconds,
    );
    final attackers = List<AttackPlayer>.from(state.pitch.attackers);
    _replace(
      attackers,
      learner.copyWith(
        facingRadians: facing,
        velocity: const ScanPassPoint(0, 0),
      ),
    );
    final defenders = _moveDefenders(
      state: state,
      attackers: attackers,
      ball: learner.position,
      receiverNumber: receiverNumber,
      seconds: seconds,
    );
    final pitch = _copyPitch(
      state.pitch,
      attackers: attackers,
      defenders: defenders,
      ball: learner.position,
      carrierNumber: 6,
      seconds: seconds,
    );
    final next = state._copyWith(
      pitch: pitch,
      elapsed: state.elapsed + seconds,
      turnDelayRemaining: math.max(0, state._turnDelayRemaining - seconds),
    );
    if (_pressureMetres(next.pitch, learner.position) < _releaseLostRadius) {
      return _complete(next, ChainEnd.crowded);
    }
    if (next._turnDelayRemaining <= _epsilon) {
      return _startOutgoingPass(next);
    }
    return next;
  }

  ChainState _startOutgoingPass(ChainState state) {
    final receiverNumber = state._passReceiverNumber;
    if (receiverNumber == null) {
      return state._copyWith(phase: ChainPhase.decide);
    }
    final receiver = _attackerOrNull(state.pitch, receiverNumber);
    if (receiver == null) return _complete(state, ChainEnd.intercepted);
    final start = state.pitch.ball;
    return state._copyWith(
      flightStart: start,
      flightTarget: receiver.position,
      flightElapsed: 0,
      flightDuration: _flightDuration(start, receiver.position, _passSpeed),
      flightReceiverNumber: receiverNumber,
      flightIsReturn: false,
      turnDelayRemaining: 0,
    );
  }

  ChainState _finishOutgoingPass(ChainState state, ScanPassPoint target) {
    final receiverNumber = state._flightReceiverNumber;
    final receiver = _attackerOrNull(state.pitch, receiverNumber);
    if (receiver == null) return _complete(state, ChainEnd.intercepted);
    final pressure = _pressureMetres(state.pitch, target);
    if (pressure < _receiveCrowdedRadius) {
      return _complete(state, ChainEnd.intercepted);
    }
    final attackers = List<AttackPlayer>.from(state.pitch.attackers);
    final passer = _attacker(state.pitch, 6);
    final arrived = receiver.copyWith(
      position: target,
      velocity: const ScanPassPoint(0, 0),
      facingRadians: _angleMetres(target, passer.position),
    );
    _replace(attackers, arrived);
    final pitch = state.pitch.copyWith(
      attackers: attackers,
      ball: target,
      carrierNumber: receiverNumber,
      completedPasses: state.pitch.completedPasses + 1,
      actionCount: state.pitch.actionCount + 1,
      furthestX: math.max(state.pitch.furthestX, target.x),
      cue: AttackCue.received,
    );
    final withPitch = state._copyWith(
      pitch: pitch,
      phase: ChainPhase.prepareRun,
      action: null,
      flightStart: null,
      flightTarget: null,
      flightElapsed: 0,
      flightDuration: 0,
      flightReceiverNumber: 0,
      flightIsReturn: false,
      passReceiverNumber: null,
    );
    return withPitch._copyWith(
      moments: <ChainSnapshot>[
        ...withPitch.moments,
        _snapshot(
          withPitch,
          ChainMoment.afterAction,
          action: ChainActionKind.pass,
          target: target,
        ),
      ],
    );
  }

  ChainState _advanceCarrierMotionStep(ChainState state, double seconds) {
    final start = state._motionStart;
    final target = state._motionEnd;
    final action = state.action;
    if (start == null ||
        target == null ||
        action == null ||
        state._motionDuration <= 0) {
      return state._copyWith(phase: ChainPhase.decide);
    }
    final progress = ((state._motionElapsed + seconds) / state._motionDuration)
        .clamp(0.0, 1.0)
        .toDouble();
    final position = start.lerp(target, progress);
    final attackers = List<AttackPlayer>.from(state.pitch.attackers);
    final learner = _attacker(state.pitch, 6);
    final moved = _movedExactly(learner, position, seconds);
    _replace(attackers, moved);
    final defenders = _moveDefenders(
      state: state,
      attackers: attackers,
      ball: position,
      receiverNumber: 6,
      seconds: seconds,
    );
    final pitch = _copyPitch(
      state.pitch,
      attackers: attackers,
      defenders: defenders,
      ball: position,
      carrierNumber: 6,
      seconds: seconds,
    );
    var next = state._copyWith(
      pitch: pitch,
      elapsed: state.elapsed + seconds,
      motionElapsed: state._motionElapsed + seconds,
    );
    final pressure = _pressureMetres(next.pitch, position);
    final protected = action.kind == ChainActionKind.turn &&
        next._motionElapsed < _turnProtectionSeconds;
    final lostRadius = protected ? _protectedLostRadius : _touchLostRadius;
    if (progress > 0.20 && pressure < lostRadius) {
      return _complete(next, ChainEnd.lostTouch);
    }
    if (progress >= 1 - _epsilon) {
      final snapshot = _snapshot(
        next,
        ChainMoment.afterAction,
        action: action.kind,
        target: target,
      );
      return next._copyWith(
        phase: ChainPhase.decide,
        moments: <ChainSnapshot>[...next.moments, snapshot],
        motionStart: null,
        motionEnd: null,
        motionElapsed: 0,
        motionDuration: 0,
        action: null,
      );
    }
    return next;
  }

  ChainState _advanceRunStep(ChainState state, double seconds) {
    final start = state._motionStart;
    final target = state._motionEnd;
    if (start == null || target == null || state._motionDuration <= 0) {
      return state._copyWith(phase: ChainPhase.prepareRun);
    }
    final progress = ((state._motionElapsed + seconds) / state._motionDuration)
        .clamp(0.0, 1.0)
        .toDouble();
    final position = start.lerp(target, progress);
    final attackers = List<AttackPlayer>.from(state.pitch.attackers);
    final learner = _attacker(state.pitch, 6);
    _replace(attackers, _movedExactly(learner, position, seconds));
    final carrier = state.pitch.carrier;
    final defenders = _moveDefenders(
      state: state,
      attackers: attackers,
      ball: carrier.position,
      receiverNumber: 6,
      seconds: seconds,
    );
    final pitch = _copyPitch(
      state.pitch,
      attackers: attackers,
      defenders: defenders,
      ball: carrier.position,
      carrierNumber: carrier.number,
      seconds: seconds,
    );
    var next = state._copyWith(
      pitch: pitch,
      elapsed: state.elapsed + seconds,
      motionElapsed: state._motionElapsed + seconds,
    );

    if (next._motionElapsed > 0.20 &&
        _pressureMetres(next.pitch, next.pitch.carrier.position) <
            _supportPressedRadius) {
      return _completeRun(next, ChainEnd.supportPressed);
    }

    if (progress >= 1 - _epsilon) {
      final pressure = _pressureMetres(next.pitch, position);
      if (pressure < _runCrowdedRadius) {
        return _completeRun(next, ChainEnd.crowded);
      }
      if (!_returnLaneOpen(next.pitch)) {
        return _completeRun(next, ChainEnd.noReturnLane);
      }
      final afterRun = _snapshot(
        next,
        ChainMoment.afterRun,
        target: target,
      );
      final ready = next._copyWith(
        phase: ChainPhase.prepareTouch,
        returning: true,
        moments: <ChainSnapshot>[...next.moments, afterRun],
        motionStart: null,
        motionEnd: null,
        motionElapsed: 0,
        motionDuration: 0,
      );
      return ready._copyWith(
        moments: <ChainSnapshot>[
          ...ready.moments,
          _snapshot(
            ready,
            ChainMoment.returnReady,
            target: target,
          ),
        ],
      );
    }
    return next;
  }

  ChainState _completeRun(ChainState state, ChainEnd end) {
    final snapshot = _snapshot(
      state,
      ChainMoment.afterRun,
      target: state.runTarget,
    );
    return _complete(
      state._copyWith(
        moments: <ChainSnapshot>[...state.moments, snapshot],
        motionStart: null,
        motionEnd: null,
        motionElapsed: 0,
        motionDuration: 0,
      ),
      end,
    );
  }

  ChainState _complete(ChainState state, ChainEnd end) {
    final finalMoment = switch (state.phase) {
      ChainPhase.touching => ChainMoment.afterTouch,
      ChainPhase.running => ChainMoment.afterRun,
      _ => ChainMoment.afterAction,
    };
    final moments = List<ChainSnapshot>.from(state.moments);
    // Failed actions need a real arrival frame too, not only a before frame.
    if (moments.isEmpty || moments.last.pitch != state.pitch) {
      moments.add(_snapshot(state, finalMoment,
          action: state.action?.kind,
          target: switch (state.phase) {
            ChainPhase.touching => state.touchTarget,
            ChainPhase.running => state.runTarget,
            _ => state.action?.target,
          }));
    }
    return state._copyWith(
      phase: ChainPhase.complete,
      end: end,
      moments: moments,
      flightStart: null,
      flightTarget: null,
      flightElapsed: 0,
      flightDuration: 0,
      flightReceiverNumber: 0,
      flightIsReturn: false,
      touchStart: null,
      touchEnd: null,
      touchElapsed: 0,
      touchDuration: 0,
      motionStart: null,
      motionEnd: null,
      motionElapsed: 0,
      motionDuration: 0,
      turnDelayRemaining: 0,
      passReceiverNumber: null,
    );
  }

  ChainSnapshot _snapshot(
    ChainState state,
    ChainMoment moment, {
    ChainActionKind? action,
    ScanPassPoint? target,
  }) {
    final focus = state.pitch.carrierNumber == 6
        ? _attacker(state.pitch, 6).position
        : state.pitch.ball;
    // A planned return belongs to the next touch even if its flight is
    // intercepted. Keep its provisional before frame out of the previous
    // completed touch's comparison; the reception count still changes only
    // after a real arrival.
    final pendingReturn = (moment == ChainMoment.beforeTouch &&
            state.phase == ChainPhase.prepareTouch &&
            state.returning) ||
        (state.phase == ChainPhase.receiving && state._flightIsReturn);
    return ChainSnapshot(
      moment: moment,
      pitch: state.pitch,
      openPasses: openPasses(state.pitch),
      pressureMetres: _pressureMetres(state.pitch, focus),
      cycle: state.returns + (pendingReturn ? 1 : 0),
      action: action,
      target: target,
    );
  }
}

const Object _unchanged = Object();
const double _pitchWidthMetres = 30;
const double _pitchHeightMetres = 20;
const double _stepSeconds = 1 / 60;
const double _maximumAdvanceSeconds = 30;
const double _passSpeed = 15.5;
const double _touchSpeed = 4.0;
const double _carrySpeed = 4.8;
const double _turnMoveSpeed = 2.8;
const double _learnerRunSpeed = 5.2;
const double _markerSpeed = 3.95;
const double _coverSpeed = 3.2;
const double _turnRate = math.pi * 1.85;
const double _defenderTurnRate = math.pi * 1.6;
const double _maxTouchMetres = 3.0;
const double _maxCarryMetres = 4.0;
const double _maxTurnMetres = 1.5;
const double _maxRunMetres = 7.0;
const double _minimumTouchDuration = 0.14;
const double _maximumTouchDuration = 0.95;
const double _minimumMotionDuration = 0.16;
const double _maximumCarryDuration = 1.2;
const double _maximumRunDuration = 1.8;
const double _turnProtectionSeconds = 0.38;
const double _receiveRadius = 1.25;
const double _receiveCrowdedRadius = 0.62;
const double _touchLostRadius = 0.55;
const double _protectedLostRadius = 0.38;
const double _releaseLostRadius = 0.52;
const double _supportPressedRadius = 0.52;
const double _runCrowdedRadius = 0.78;
const double _dynamicInterceptRadius = 0.24;
const double _interceptAdvantage = 0.18;
const double _laneOpenRadius = 0.76;
const double _receiverSpaceRadius = 0.85;
const double _requiredReturns = 2;
const double _epsilon = 1e-9;

bool _isHoldPhase(ChainPhase phase) =>
    phase == ChainPhase.prepareTouch ||
    phase == ChainPhase.decide ||
    phase == ChainPhase.prepareRun ||
    phase == ChainPhase.complete;

double _stepFor(ChainState state, double remaining) {
  var step = math.min(_stepSeconds, remaining);
  if (state.phase == ChainPhase.receiving ||
      (state.phase == ChainPhase.acting && state._flightTarget != null)) {
    final left = state._flightDuration - state._flightElapsed;
    if (left > _epsilon) step = math.min(step, left);
  } else if (state.phase == ChainPhase.touching) {
    final left = state._touchDuration - state._touchElapsed;
    if (left > _epsilon) step = math.min(step, left);
  } else if (state.phase == ChainPhase.acting &&
      state._turnDelayRemaining > _epsilon) {
    step = math.min(step, state._turnDelayRemaining);
  } else if (state.phase == ChainPhase.acting ||
      state.phase == ChainPhase.running) {
    final left = state._motionDuration - state._motionElapsed;
    if (left > _epsilon) step = math.min(step, left);
  }
  return step;
}

AttackState _startPitch(int seed) {
  if (seed == 0) {
    return _stateFromPlayers(
      attackers: const <AttackPlayer>[
        AttackPlayer(
          number: 4,
          position: ScanPassPoint(0.20, 0.56),
          facingRadians: -0.10,
        ),
        AttackPlayer(
          number: 6,
          position: ScanPassPoint(0.40, 0.54),
          facingRadians: math.pi,
        ),
        AttackPlayer(
          number: 8,
          position: ScanPassPoint(0.60, 0.36),
          facingRadians: math.pi * 0.85,
        ),
      ],
      defenders: const <AttackPlayer>[
        AttackPlayer(
          number: 2,
          position: ScanPassPoint(0.50, 0.70),
          opponent: true,
          facingRadians: math.pi,
        ),
        AttackPlayer(
          number: 3,
          position: ScanPassPoint(0.65, 0.64),
          opponent: true,
          facingRadians: math.pi,
        ),
      ],
      carrierNumber: 4,
    );
  }

  final random = _SeededNoise(seed);
  final mirror = random.nextBool();
  final pressureHigh = random.nextBool();
  final pressureSign = (pressureHigh ? -1.0 : 1.0) * (mirror ? -1.0 : 1.0);
  final centreY = 0.52 + random.range(-0.07, 0.07);
  ScanPassPoint point(double x, double y) => _field(ScanPassPoint(
      x + random.range(-0.015, 0.015),
      _mirrorY(y + random.range(-0.018, 0.018), mirror)));
  final four = point(0.19, centreY + 0.02);
  final six = point(0.39, centreY);
  final eight = point(0.59, centreY - 0.17 * pressureSign);
  final marker = _field(ScanPassPoint(
    six.x + 0.095 + random.range(-0.018, 0.025),
    _fieldY(six.y + 0.13 * pressureSign + random.range(-0.025, 0.025)),
  ));
  final cover = _field(ScanPassPoint(
    eight.x + 0.045 + random.range(-0.025, 0.03),
    _fieldY((six.y + eight.y) / 2 + random.range(-0.05, 0.05)),
  ));
  return _stateFromPlayers(
    attackers: <AttackPlayer>[
      AttackPlayer(number: 4, position: four, facingRadians: 0),
      AttackPlayer(number: 6, position: six, facingRadians: math.pi),
      AttackPlayer(number: 8, position: eight, facingRadians: math.pi * 0.85),
    ],
    defenders: <AttackPlayer>[
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
  );
}

AttackState _stateFromPlayers({
  required List<AttackPlayer> attackers,
  required List<AttackPlayer> defenders,
  required int carrierNumber,
}) {
  final carrier =
      attackers.firstWhere((player) => player.number == carrierNumber);
  return AttackState(
    attackers: attackers,
    defenders: defenders,
    ball: carrier.position,
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
  required ChainState state,
  required List<AttackPlayer> attackers,
  required ScanPassPoint ball,
  required int receiverNumber,
  required double seconds,
}) {
  final marker = _defenderFrom(state.pitch.defenders, 2);
  final cover = _defenderFrom(state.pitch.defenders, 3);
  final learner = attackers.firstWhere((player) => player.number == 6);
  final receiver =
      attackers.firstWhere((player) => player.number == receiverNumber);
  final carrier = attackers.firstWhere(
    (player) => player.number == state.pitch.carrierNumber,
    orElse: () => learner,
  );

  final markerTarget = switch (state.phase) {
    ChainPhase.prepareTouch ||
    ChainPhase.decide ||
    ChainPhase.prepareRun =>
      marker.position,
    ChainPhase.receiving => _markingPoint(learner.position, ball, 0.60),
    ChainPhase.touching ||
    ChainPhase.acting =>
      _markingPoint(learner.position, ball, 0.42),
    ChainPhase.running =>
      _markingPoint(learner.position, carrier.position, 0.55),
    ChainPhase.complete => marker.position,
  };
  final coverTarget = switch (state.phase) {
    ChainPhase.prepareTouch ||
    ChainPhase.decide ||
    ChainPhase.prepareRun =>
      cover.position,
    ChainPhase.receiving => _lanePoint(ball, receiver.position, 0.62),
    ChainPhase.touching || ChainPhase.acting => _actionCoverTarget(
        state,
        attackers,
        ball,
        receiver.position,
      ),
    ChainPhase.running => _lanePoint(carrier.position, learner.position, 0.48),
    ChainPhase.complete => cover.position,
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

ScanPassPoint _actionCoverTarget(
  ChainState state,
  List<AttackPlayer> attackers,
  ScanPassPoint ball,
  ScanPassPoint fallbackReceiver,
) {
  final passReceiver = state._passReceiverNumber;
  final target = passReceiver == null
      ? attackers.firstWhere((player) => player.number == 8).position
      : attackers
          .firstWhere(
            (player) => player.number == passReceiver,
            orElse: () => AttackPlayer(
              number: 0,
              position: fallbackReceiver,
              facingRadians: 0,
            ),
          )
          .position;
  return _lanePoint(ball, target, passReceiver == null ? 0.55 : 0.50);
}

AttackPlayer? _interceptorOnBall(
  AttackState pitch,
  int receiverNumber,
  double progress,
) {
  if (progress < 0.10) return null;
  final receiver = _attackerOrNull(pitch, receiverNumber);
  if (receiver == null) return null;
  final receiverGap = _distanceMetres(receiver.position, pitch.ball);
  if (receiverGap < 0.9) return null;
  for (final defender in pitch.defenders) {
    final defenderGap = _distanceMetres(defender.position, pitch.ball);
    if (defenderGap <= _dynamicInterceptRadius &&
        defenderGap + _interceptAdvantage < receiverGap) {
      return defender;
    }
  }
  return null;
}

bool _returnLaneOpen(AttackState pitch) {
  if (pitch.carrierNumber == 6) return false;
  final carrier = pitch.carrier;
  final learner = _attacker(pitch, 6);
  return _passFeasible(pitch, carrier, learner, returnLane: true);
}

List<int> _openPasses(AttackState pitch) {
  final carrier = pitch.carrier;
  final open = <int>[];
  for (final candidate in pitch.attackers) {
    if (candidate.number == carrier.number) continue;
    if (_passFeasible(pitch, carrier, candidate)) {
      open.add(candidate.number);
    }
  }
  open.sort();
  return open;
}

bool _passFeasible(
  AttackState pitch,
  AttackPlayer carrier,
  AttackPlayer receiver, {
  bool returnLane = false,
}) {
  final pressure = _pressureMetres(pitch, carrier.position);
  final lane =
      _laneClearance(pitch.defenders, carrier.position, receiver.position);
  final receiverSpace = _pressureMetres(pitch, receiver.position);
  final delay = _passTurnDelay(carrier, receiver.position);
  final adjustedPressure = pressure - delay * _markerSpeed * 0.90;
  final adjustedLane = lane - delay * _coverSpeed * 0.32;
  final minLane = returnLane ? _laneOpenRadius - 0.02 : _laneOpenRadius;
  const minSpace = _receiverSpaceRadius;
  if (adjustedPressure < _releaseLostRadius) return false;
  if (adjustedLane < minLane) return false;
  if (receiverSpace < minSpace) return false;
  return true;
}

double _pressureMetres(AttackState pitch, ScanPassPoint point) {
  if (pitch.defenders.isEmpty) return double.infinity;
  return _distanceMetres(
      _nearestDefender(pitch.defenders, point).position, point);
}

double _laneClearance(
  List<AttackPlayer> defenders,
  ScanPassPoint start,
  ScanPassPoint end,
) {
  var clearance = double.infinity;
  for (final defender in defenders) {
    clearance = math.min(
      clearance,
      _pointSegmentDistanceMetres(defender.position, start, end),
    );
  }
  return clearance;
}

AttackPlayer _attacker(AttackState state, int number) =>
    state.attackers.firstWhere((player) => player.number == number);

AttackPlayer? _attackerOrNull(AttackState state, int number) {
  for (final player in state.attackers) {
    if (player.number == number) return player;
  }
  return null;
}

AttackPlayer _defenderFrom(List<AttackPlayer> defenders, int number) =>
    defenders.firstWhere((player) => player.number == number);

AttackPlayer _nearestDefender(
  List<AttackPlayer> defenders,
  ScanPassPoint point,
) {
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
  final distance = _distanceMetres(player.position, position);
  return player.copyWith(
    position: _field(position),
    velocity: delta * (1 / safeSeconds),
    facingRadians: distance > 0.05
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
  if (seconds <= _epsilon || speedMetresPerSecond <= 0) return player;
  final safeTarget = _field(target);
  final distance = _distanceMetres(player.position, safeTarget);
  if (distance <= 0.04) {
    return player.copyWith(velocity: const ScanPassPoint(0, 0));
  }

  final desired = _angleMetres(player.position, safeTarget);
  final current =
      player.facingRadians.isFinite ? player.facingRadians : desired;
  final facing = _turnToward(current, desired, turnRate * seconds);
  final error = _angleDelta(facing, desired).abs();
  final alignment =
      (0.34 + 0.66 * math.max(0, math.cos(error))).clamp(0.34, 1.0).toDouble();
  final step = math.min(distance, speedMetresPerSecond * seconds * alignment);
  final next = _translateMetres(
    player.position,
    math.cos(facing) * step,
    math.sin(facing) * step,
  );
  return player.copyWith(
    position: next,
    velocity: ScanPassPoint(
      (next.x - player.position.x) / seconds,
      (next.y - player.position.y) / seconds,
    ),
    facingRadians: facing,
  );
}

ScanPassPoint _markingPoint(
  ScanPassPoint receiver,
  ScanPassPoint ball,
  double cushionMetres,
) {
  final dx = (ball.x - receiver.x) * _pitchWidthMetres;
  final dy = (ball.y - receiver.y) * _pitchHeightMetres;
  final length = math.sqrt(dx * dx + dy * dy);
  if (length <= _epsilon) return _field(receiver);
  return _translateMetres(
    receiver,
    dx / length * cushionMetres,
    dy / length * cushionMetres,
  );
}

ScanPassPoint _lanePoint(
        ScanPassPoint from, ScanPassPoint to, double fraction) =>
    _field(from.lerp(to, fraction));

ScanPassPoint _boundedTarget(
  ScanPassPoint from,
  ScanPassPoint target,
  double maxMetres,
) {
  final distance = _distanceMetres(from, target);
  if (distance <= maxMetres || distance <= _epsilon) return _field(target);
  final dx = (target.x - from.x) * _pitchWidthMetres / distance;
  final dy = (target.y - from.y) * _pitchHeightMetres / distance;
  return _translateMetres(from, dx * maxMetres, dy * maxMetres);
}

double _flightDuration(
  ScanPassPoint start,
  ScanPassPoint target,
  double speedMetresPerSecond,
) {
  final distance = _distanceMetres(start, target);
  return (distance / speedMetresPerSecond).clamp(0.16, 1.35).toDouble();
}

double _passTurnDelay(AttackPlayer carrier, ScanPassPoint target) {
  final angle = _angleMetres(carrier.position, target);
  final facing = carrier.facingRadians.isFinite ? carrier.facingRadians : angle;
  final delta = _angleDelta(angle, facing).abs();
  if (delta < 0.34) return 0.04;
  return (0.04 + (delta - 0.34) / math.pi * 0.58).clamp(0.04, 0.62).toDouble();
}

double _distanceMetres(ScanPassPoint a, ScanPassPoint b) {
  final ax = a.x.isFinite ? a.x : 0.0;
  final ay = a.y.isFinite ? a.y : 0.0;
  final bx = b.x.isFinite ? b.x : 0.0;
  final by = b.y.isFinite ? b.y : 0.0;
  final dx = (ax - bx) * _pitchWidthMetres;
  final dy = (ay - by) * _pitchHeightMetres;
  return math.sqrt(dx * dx + dy * dy);
}

double _pointSegmentDistanceMetres(
  ScanPassPoint point,
  ScanPassPoint start,
  ScanPassPoint end,
) {
  final px = (point.x.isFinite ? point.x : 0.0) * _pitchWidthMetres;
  final py = (point.y.isFinite ? point.y : 0.0) * _pitchHeightMetres;
  final ax = (start.x.isFinite ? start.x : 0.0) * _pitchWidthMetres;
  final ay = (start.y.isFinite ? start.y : 0.0) * _pitchHeightMetres;
  final bx = (end.x.isFinite ? end.x : 0.0) * _pitchWidthMetres;
  final by = (end.y.isFinite ? end.y : 0.0) * _pitchHeightMetres;
  final dx = bx - ax;
  final dy = by - ay;
  final lengthSquared = dx * dx + dy * dy;
  if (lengthSquared <= _epsilon) {
    return math.sqrt((px - ax) * (px - ax) + (py - ay) * (py - ay));
  }
  final t = (((px - ax) * dx + (py - ay) * dy) / lengthSquared)
      .clamp(0.0, 1.0)
      .toDouble();
  final cx = ax + dx * t;
  final cy = ay + dy * t;
  return math.sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy));
}

ScanPassPoint _translateMetres(
  ScanPassPoint point,
  double dxMetres,
  double dyMetres,
) {
  return _field(ScanPassPoint(
    point.x + dxMetres / _pitchWidthMetres,
    point.y + dyMetres / _pitchHeightMetres,
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
  return current + delta.sign * maxTurn;
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

double _fieldY(double y) => y.clamp(0.07, 0.93).toDouble();

double _mirrorY(double y, bool mirror) => mirror ? 1 - y : y;

double _safeSeconds(double seconds) {
  if (!seconds.isFinite || seconds <= 0) return 0;
  return seconds.clamp(0.0, _maximumAdvanceSeconds).toDouble();
}

class _SeededNoise {
  int _state;

  _SeededNoise(int seed) : _state = seed == 0 ? 1 : seed & 0x7fffffff;

  bool nextBool() => nextDouble() >= 0.5;

  double range(double min, double max) => min + (max - min) * nextDouble();

  double nextDouble() {
    _state = ((_state * 1664525) + 1013904223) & 0x7fffffff;
    return _state / 0x7fffffff;
  }
}
