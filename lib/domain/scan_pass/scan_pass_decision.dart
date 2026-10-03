import 'dart:math' as math;

import 'scan_pass_attack.dart';
import 'scan_pass_game.dart' show ScanPassPoint;

enum DecisionLesson { rearPressure, passingLane, receiverSupport }

enum DecisionAction { forward, wide, reset, carry }

enum DecisionQuality { advantage, secure, difficult, lost }

enum DecisionReason {
  pressureEscaped,
  pressureArriving,
  laneOpen,
  laneBlocked,
  receiverCanTurn,
  receiverTrapped,
  thirdPlayerAvailable,
  possessionKept,
  windowClosed,
  offside,
}

/// One paired teaching scene. The two versions share their opening geometry;
/// only one actor's movement changes. This is not a gaze or skill measurement.
class DecisionScenario {
  final DecisionLesson lesson;
  final bool changed;
  final int variation;
  final AttackState initial;
  final AttackState reception;
  final int cueNumber;
  final bool cueIsOpponent;

  const DecisionScenario({
    required this.lesson,
    required this.changed,
    required this.variation,
    required this.initial,
    required this.reception,
    required this.cueNumber,
    required this.cueIsOpponent,
  });

  double get observationSeconds => 2.4;
  double get liveWindowSeconds => 2.8;

  ScanPassPoint get cueFrom => _cue(initial).position;
  ScanPassPoint get cueTo => _cue(reception).position;

  AttackPlayer _cue(AttackState state) =>
      (cueIsOpponent ? state.defenders : state.attackers)
          .firstWhere((player) => player.number == cueNumber);

  AttackState observationFrame(double progress) => progress <= 0
      ? initial
      : AttackTransition(
          before: initial,
          after: reception,
          action: const AttackAction.pass(6),
          duration: observationSeconds,
          ballEnd: reception.ball,
        ).frame(progress);

  /// Only the caller's active simulation time belongs here. Reading in either
  /// self-paced mode, replay, help and time in the background do not advance it.
  AttackState decisionState(double delaySeconds) =>
      _advance(reception, _safeSeconds(delaySeconds));
}

class DecisionAssessment {
  final DecisionAction action;
  final DecisionQuality quality;
  final DecisionReason reason;
  final bool passCompleted;
  final bool laneOpen;
  final bool receiverHasTime;
  final bool progressed;
  final bool inWindow;
  final List<int> availableOutlets;
  final AttackState before;
  final AttackState received;
  final AttackState after;
  final List<AttackTransition> transitions;
  final ScanPassPoint pressurePoint;

  DecisionAssessment({
    required this.action,
    required this.quality,
    required this.reason,
    required this.passCompleted,
    required this.laneOpen,
    required this.receiverHasTime,
    required this.progressed,
    required this.inWindow,
    required List<int> availableOutlets,
    required this.before,
    required this.received,
    required this.after,
    required List<AttackTransition> transitions,
    required this.pressurePoint,
  })  : availableOutlets = List.unmodifiable(availableOutlets),
        transitions = List.unmodifiable(transitions);

  double get duration => transitions.fold(0, (sum, leg) => sum + leg.duration);

  AttackState frame(double progress) {
    if (progress >= 1) return after;
    var remaining = progress.clamp(0.0, 1.0) * duration;
    for (final leg in transitions) {
      if (remaining <= leg.duration) {
        return leg.frame(leg.duration <= 0 ? 1 : remaining / leg.duration);
      }
      remaining -= leg.duration;
    }
    return after;
  }
}

/// A small transparent tactical model: lanes are sampled against moving
/// defenders; receiving pressure, orientation and reachable next passes are
/// evaluated separately from pass completion. There is no action-id answer
/// table, random success roll, goal reward or numeric skill score.
class DecisionEngine {
  static const double _passSpeed = .53;
  static const double _passReach = .021;
  static const double _carryReach = .038;

  const DecisionEngine();

  DecisionScenario scenario(DecisionLesson lesson,
      {bool changed = false, int variation = 0}) {
    // Match a pair before varying it. Mirroring and small translations preserve
    // its causal relation but remove dependence on one screen location.
    final shift = ((variation.abs() ~/ 2) % 3 - 1) * .008;
    final mirror = variation.isOdd;
    ScanPassPoint point(double x, double y) =>
        ScanPassPoint(x + shift, mirror ? 1 - y : y);
    ScanPassPoint velocity(double x, double y) =>
        ScanPassPoint(x, mirror ? -y : y);
    AttackPlayer player(int number, double x, double y,
            {bool opponent = false,
            bool keeper = false,
            double facing = 0,
            double vx = 0,
            double vy = 0}) =>
        AttackPlayer(
          number: number,
          position: point(x, y),
          opponent: opponent,
          goalkeeper: keeper,
          facingRadians: mirror ? -facing : facing,
          velocity: velocity(vx, vy),
        );

    late List<AttackPlayer> initialAttackers;
    late List<AttackPlayer> receivedAttackers;
    late List<AttackPlayer> initialDefenders;
    late List<AttackPlayer> receivedDefenders;
    var cueNumber = 2;
    var cueIsOpponent = true;

    switch (lesson) {
      case DecisionLesson.rearPressure:
        initialAttackers = [
          player(4, .16, .54),
          player(6, .38, .50, facing: math.pi),
          player(8, .64, .27),
          player(7, .40, .79),
          player(10, .78, .30),
        ];
        receivedAttackers = initialAttackers;
        initialDefenders = [
          player(2, .53, .50, opponent: true, facing: math.pi),
          player(3, .78, .57, opponent: true, facing: math.pi),
          player(5, .85, .82, opponent: true, facing: math.pi),
          player(1, .96, .50, opponent: true, keeper: true),
        ];
        receivedDefenders = [
          changed
              ? player(2, .65, .50, opponent: true, vx: .035)
              : player(2, .426, .50,
                  opponent: true, facing: math.pi, vx: -.054),
          ...initialDefenders.skip(1),
        ];
      case DecisionLesson.passingLane:
        initialAttackers = [
          player(4, .16, .57),
          player(6, .38, .54, facing: math.pi),
          player(8, .68, .42),
          player(7, .42, .17),
          player(10, .80, .51),
        ];
        receivedAttackers = initialAttackers;
        initialDefenders = [
          player(2, .53, .57, opponent: true, facing: math.pi),
          player(3, .79, .20, opponent: true, facing: math.pi),
          player(5, .87, .80, opponent: true, facing: math.pi),
          player(1, .96, .50, opponent: true, keeper: true),
        ];
        receivedDefenders = [
          changed
              ? player(2, .425, .615,
                  opponent: true, facing: -2.1, vx: -.030, vy: -.052)
              : player(2, .52, .484,
                  opponent: true, facing: math.pi, vy: -.003),
          ...initialDefenders.skip(1),
        ];
      case DecisionLesson.receiverSupport:
        cueNumber = 10;
        cueIsOpponent = false;
        initialAttackers = [
          player(4, .14, .59),
          player(6, .36, .55, facing: math.pi),
          player(8, .64, .47, facing: math.pi),
          player(7, .40, .82),
          player(10, .68, .21),
        ];
        receivedAttackers = [
          ...initialAttackers.take(4),
          changed ? player(10, .84, .24) : player(10, .57, .24),
        ];
        initialDefenders = [
          player(2, .50, .60,
              opponent: true, facing: -1.4, vx: .018, vy: -.105),
          player(3, .703, .46, opponent: true, facing: math.pi, vx: -.040),
          player(5, .90, .24, opponent: true, facing: math.pi),
          player(1, .96, .50, opponent: true, keeper: true),
        ];
        receivedDefenders = initialDefenders;
    }
    final initial = AttackState(
      attackers: initialAttackers,
      defenders: initialDefenders,
      ball: initialAttackers.first.position,
      carrierNumber: 4,
    );
    final reception = AttackState(
      attackers: receivedAttackers,
      defenders: receivedDefenders,
      ball: receivedAttackers.firstWhere((p) => p.number == 6).position,
      carrierNumber: 6,
      completedPasses: 1,
      actionCount: 1,
      elapsed: 2.4,
      cue: AttackCue.received,
    );
    return DecisionScenario(
      lesson: lesson,
      changed: changed,
      variation: variation,
      initial: initial,
      reception: reception,
      cueNumber: cueNumber,
      cueIsOpponent: cueIsOpponent,
    );
  }

  int? targetNumber(DecisionAction action) => switch (action) {
        DecisionAction.forward => 8,
        DecisionAction.wide => 7,
        DecisionAction.reset => 4,
        DecisionAction.carry => null,
      };

  ScanPassPoint target(AttackState state, DecisionAction action) {
    final number = targetNumber(action);
    return number == null
        ? _field(state.carrier.position + const ScanPassPoint(.15, 0))
        : state.attackers.firstWhere((p) => p.number == number).position;
  }

  List<DecisionAssessment> alternatives(DecisionScenario scenario,
          {double delaySeconds = 0}) =>
      [
        for (final action in DecisionAction.values)
          assess(scenario, action, delaySeconds: delaySeconds),
      ];

  DecisionAssessment assess(DecisionScenario scenario, DecisionAction action,
      {double delaySeconds = 0}) {
    final delay = _safeSeconds(delaySeconds);
    final before = scenario.decisionState(delay);
    final number = targetNumber(action);
    final inWindow = delay <= scenario.liveWindowSeconds &&
        _nearest(before, before.ball).position.distanceTo(before.ball) > .025;
    final first = number == null
        ? _carry(before, target(before, action), duration: 1.35)
        : _pass(before, number);
    final received = first.after;
    final completed = !received.finished;
    final pressure = _nearest(received, received.ball);
    final hasTime = completed && _hasTime(received);
    final outlets = completed ? _outlets(received, hasTime) : <int>[];
    final progressed = received.ball.x - before.ball.x >= .075 && completed;
    late DecisionQuality quality;
    late DecisionReason reason;

    if (!completed) {
      quality = DecisionQuality.lost;
      reason = received.end == AttackEnd.offside
          ? DecisionReason.offside
          : !inWindow
              ? DecisionReason.windowClosed
              : number == null
                  ? DecisionReason.pressureArriving
                  : DecisionReason.laneBlocked;
    } else if (!hasTime && outlets.isEmpty) {
      quality = DecisionQuality.difficult;
      reason = number == null
          ? DecisionReason.pressureArriving
          : DecisionReason.receiverTrapped;
    } else if (!hasTime) {
      // A pressured receiver is a useful wall player when a short, reachable
      // outlet exists in the direction their body permits a one-touch pass.
      final forwardSupport = outlets.any((n) =>
          received.attackers.firstWhere((p) => p.number == n).position.x >
          before.ball.x + .075);
      quality =
          forwardSupport ? DecisionQuality.advantage : DecisionQuality.secure;
      reason = DecisionReason.thirdPlayerAvailable;
    } else if (progressed) {
      quality = DecisionQuality.advantage;
      reason = number == null
          ? DecisionReason.pressureEscaped
          : scenario.lesson == DecisionLesson.passingLane
              ? DecisionReason.laneOpen
              : DecisionReason.receiverCanTurn;
    } else {
      quality = DecisionQuality.secure;
      reason =
          _nearest(before, before.ball).position.distanceTo(before.ball) < .11
              ? DecisionReason.pressureEscaped
              : DecisionReason.possessionKept;
    }

    final legs = <AttackTransition>[first];
    var after = received;
    if (completed) {
      if (!hasTime && outlets.isNotEmpty) {
        // Continue immediately, before the pressure arrives. This is an
        // illustrated possible continuation, not another learner decision.
        final follow = _pass(after, _bestOutlet(after, outlets));
        legs.add(follow);
        after = follow.after;
      } else if (hasTime) {
        final touch = _safeFirstTouch(after);
        legs.add(touch);
        after = touch.after;
        final next = _outlets(after, _hasTime(after));
        if (next.isNotEmpty) {
          final follow = _pass(after, _bestOutlet(after, next));
          legs.add(follow);
          after = follow.after;
        }
      } else {
        // Retain the ball for this freeze frame: the feedback says that the
        // receiver is trapped, not that an unplayed next action was lost.
        final close = _advance(after, .35);
        final leg = AttackTransition(
            before: after,
            after: close,
            action: const AttackAction.hold(),
            duration: .35,
            ballEnd: close.ball);
        legs.add(leg);
        after = close;
      }
    }

    return DecisionAssessment(
      action: action,
      quality: quality,
      reason: reason,
      passCompleted: completed && number != null,
      laneOpen: completed,
      receiverHasTime: hasTime,
      progressed: progressed,
      inWindow: inWindow,
      availableOutlets: outlets,
      before: before,
      received: received,
      after: after,
      transitions: legs,
      pressurePoint: pressure.position,
    );
  }

  AttackTransition _pass(AttackState before, int receiverNumber) {
    final receiver =
        before.attackers.firstWhere((p) => p.number == receiverNumber);
    final offside = const AttackEngine().checkOffside(before, receiverNumber);
    if (offside.offside) {
      return AttackTransition(
        before: before,
        after: before.copyWith(end: AttackEnd.offside, cue: AttackCue.offside),
        action: AttackAction.pass(receiverNumber),
        duration: .55,
        ballEnd: before.ball,
        offside: offside,
      );
    }
    var duration = before.ball.distanceTo(receiver.position) / _passSpeed;
    var destination = receiver.position;
    for (var i = 0; i < 3; i++) {
      destination = _field(receiver.position + receiver.velocity * duration);
      duration =
          (before.ball.distanceTo(destination) / _passSpeed).clamp(.22, 1.7);
    }
    return _travel(before,
        destination: destination,
        duration: duration,
        receiverNumber: receiverNumber,
        action: AttackAction.pass(receiverNumber),
        reach: _passReach);
  }

  AttackTransition _carry(AttackState before, ScanPassPoint destination,
          {required double duration}) =>
      _travel(before,
          destination: destination,
          duration: duration,
          receiverNumber: before.carrierNumber,
          action: const AttackAction.carry(AttackCarryDirection.forward),
          reach: _carryReach);

  AttackTransition _travel(AttackState before,
      {required ScanPassPoint destination,
      required double duration,
      required int receiverNumber,
      required AttackAction action,
      required double reach}) {
    final carrying = action.kind == AttackActionKind.carry;
    // Turning with the ball exposes it for the first part of a carry. A pass
    // travels immediately, preserving the value of having a plan at receipt.
    final turnFraction =
        carrying && before.carrier.facingRadians.abs() > 1.5 ? .24 : 0.0;
    for (var sample = 1; sample <= 100; sample++) {
      final fraction = sample / 100;
      final ballProgress =
          ((fraction - turnFraction) / (1 - turnFraction)).clamp(0.0, 1.0);
      final ball = before.ball.lerp(destination, ballProgress);
      final time = duration * fraction;
      final world = _advance(before, time);
      final opponent = _nearest(world, ball);
      if (opponent.position.distanceTo(ball) < reach) {
        return AttackTransition(
          before: before,
          after: world.copyWith(
              ball: ball,
              attackers: carrying
                  ? _movePlayer(world.attackers, before.carrierNumber, ball)
                  : world.attackers,
              actionCount: before.actionCount + 1,
              end: AttackEnd.intercepted,
              cue: AttackCue.intercepted),
          action: action,
          duration: time,
          ballEnd: ball,
          interceptorNumber: opponent.number,
        );
      }
    }
    final world = _advance(before, duration);
    final after = world.copyWith(
      attackers: _movePlayer(world.attackers, receiverNumber, destination,
          faceForward: carrying),
      ball: destination,
      carrierNumber: receiverNumber,
      completedPasses: before.completedPasses + (carrying ? 0 : 1),
      actionCount: before.actionCount + 1,
      furthestX: math.max(before.furthestX, destination.x),
      cue: carrying ? AttackCue.carried : AttackCue.received,
    );
    return AttackTransition(
      before: before,
      after: after,
      action: action,
      duration: duration,
      ballEnd: destination,
    );
  }

  bool _hasTime(AttackState state) {
    final at = state.carrier.position;
    final now = _nearest(state, at).position.distanceTo(at);
    final soon = _nearest(_advance(state, .40), at).position.distanceTo(at);
    final turn = math.cos(state.carrier.facingRadians) < 0 ? .018 : 0;
    return math.min(now, soon) > .09 + turn;
  }

  List<int> _outlets(AttackState state, bool hasTime) {
    final from = state.carrier;
    final result = <int>[];
    for (final teammate in state.attackers) {
      if (teammate.number == from.number) continue;
      final delta = teammate.position - from.position;
      if (delta.distance < .045 || delta.distance > (hasTime ? .48 : .28)) {
        continue;
      }
      if (!hasTime) {
        final facing = ScanPassPoint(
            math.cos(from.facingRadians), math.sin(from.facingRadians));
        if (delta.dot(facing) / delta.distance < -.25) continue;
      }
      final leg = _pass(state, teammate.number);
      if (!leg.after.finished && _hasTime(leg.after)) {
        result.add(teammate.number);
      }
    }
    return result;
  }

  int _bestOutlet(AttackState state, List<int> options) {
    final players = state.attackers
        .where((p) => options.contains(p.number))
        .toList()
      ..sort((a, b) => b.position.x.compareTo(a.position.x));
    return players.first.number;
  }

  AttackTransition _safeFirstTouch(AttackState state) {
    AttackTransition? best;
    var separation = -1.0;
    for (final direction in [
      const ScanPassPoint(.06, 0),
      const ScanPassPoint(.035, -.065),
      const ScanPassPoint(.035, .065),
    ]) {
      final leg = _carry(state, _field(state.ball + direction), duration: .48);
      if (leg.after.finished) continue;
      final gap = _nearest(leg.after, leg.after.ball)
          .position
          .distanceTo(leg.after.ball);
      if (gap > separation) {
        best = leg;
        separation = gap;
      }
    }
    return best ??
        AttackTransition(
          before: state,
          after: state,
          action: const AttackAction.hold(),
          duration: .25,
          ballEnd: state.ball,
        );
  }
}

double _safeSeconds(double seconds) =>
    seconds.isFinite ? seconds.clamp(0.0, 8.0) : 0;

ScanPassPoint _field(ScanPassPoint point) =>
    point.clampToField(minX: .035, maxX: .965, minY: .06, maxY: .94);

AttackState _advance(AttackState state, double seconds) {
  List<AttackPlayer> move(List<AttackPlayer> players) => [
        for (final player in players) _moveInTime(player, state.ball, seconds),
      ];
  final attackers = move(state.attackers);
  return state.copyWith(
    attackers: attackers,
    defenders: move(state.defenders),
    ball: attackers.firstWhere((p) => p.number == state.carrierNumber).position,
    elapsed: state.elapsed + seconds,
  );
}

AttackPlayer _moveInTime(
    AttackPlayer player, ScanPassPoint ball, double seconds) {
  var travelTime = seconds;
  var stopped = false;
  final speedSquared = player.velocity.dot(player.velocity);
  if (player.opponent && speedSquared > .000001) {
    // A presser arriving at the ball holds that pressure rather than running
    // through the carrier and magically reopening every option after a wait.
    final timeAtBall =
        (ball - player.position).dot(player.velocity) / speedSquared;
    final closest = player.position + player.velocity * math.max(0, timeAtBall);
    if (timeAtBall >= 0 && closest.distanceTo(ball) < .032) {
      final stopAt = math.max(0.0, timeAtBall - .026 / math.sqrt(speedSquared));
      if (travelTime >= stopAt) {
        travelTime = stopAt;
        stopped = true;
      }
    }
  }
  return player.copyWith(
    position: _field(player.position + player.velocity * travelTime),
    velocity: stopped ? const ScanPassPoint(0, 0) : player.velocity,
  );
}

AttackPlayer _nearest(AttackState state, ScanPassPoint point) {
  final defenders = state.defenders.where((p) => !p.goalkeeper).toList()
    ..sort((a, b) =>
        a.position.distanceTo(point).compareTo(b.position.distanceTo(point)));
  return defenders.first;
}

List<AttackPlayer> _movePlayer(
        List<AttackPlayer> players, int number, ScanPassPoint position,
        {bool faceForward = false}) =>
    [
      for (final player in players)
        player.number == number
            ? player.copyWith(
                position: position,
                facingRadians: faceForward ? 0 : player.facingRadians,
                velocity: const ScanPassPoint(0, 0))
            : player,
    ];
