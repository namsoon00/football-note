import 'dart:math' as math;

import 'scan_pass_game.dart' show ScanPassPoint;

enum AttackActionKind { pass, carry, hold, shoot }

enum AttackCarryDirection { upper, forward, lower }

enum AttackShotTarget { upper, center, lower }

enum AttackEnd { goal, intercepted, offside, saved, wide, blocked }

enum AttackCue {
  opening,
  received,
  carried,
  waited,
  goal,
  intercepted,
  offside,
  saved,
  wide,
  blocked,
}

/// Positions represent the playable part of each player in this 2D learning
/// game. Motion and shot outcomes are deterministic teaching approximations.
class AttackPlayer {
  final int number;
  final ScanPassPoint position;
  final bool opponent;
  final bool goalkeeper;
  final double facingRadians;
  final ScanPassPoint velocity;

  const AttackPlayer({
    required this.number,
    required this.position,
    this.opponent = false,
    this.goalkeeper = false,
    this.facingRadians = 0,
    this.velocity = const ScanPassPoint(0, 0),
  });

  AttackPlayer copyWith(
          {ScanPassPoint? position,
          ScanPassPoint? velocity,
          double? facingRadians}) =>
      AttackPlayer(
        number: number,
        position: position ?? this.position,
        opponent: opponent,
        goalkeeper: goalkeeper,
        facingRadians: facingRadians ?? this.facingRadians,
        velocity: velocity ?? this.velocity,
      );
}

class AttackState {
  final List<AttackPlayer> attackers;
  final List<AttackPlayer> defenders;
  final ScanPassPoint ball;
  final int carrierNumber;
  final double elapsed;
  final int actionCount;
  final int completedPasses;
  final double furthestX;
  final AttackEnd? end;
  final AttackCue cue;

  AttackState({
    required List<AttackPlayer> attackers,
    required List<AttackPlayer> defenders,
    required this.ball,
    required this.carrierNumber,
    this.elapsed = 0,
    this.actionCount = 0,
    this.completedPasses = 0,
    double? furthestX,
    this.end,
    this.cue = AttackCue.opening,
  })  : attackers = List.unmodifiable(attackers),
        defenders = List.unmodifiable(defenders),
        furthestX = furthestX ?? ball.x;

  AttackPlayer get carrier =>
      attackers.firstWhere((p) => p.number == carrierNumber);
  bool get finished => end != null;
  bool get canShoot => !finished && carrier.position.x >= .65;

  AttackState copyWith({
    List<AttackPlayer>? attackers,
    List<AttackPlayer>? defenders,
    ScanPassPoint? ball,
    int? carrierNumber,
    double? elapsed,
    int? actionCount,
    int? completedPasses,
    double? furthestX,
    AttackEnd? end,
    AttackCue? cue,
  }) =>
      AttackState(
        attackers: attackers ?? this.attackers,
        defenders: defenders ?? this.defenders,
        ball: ball ?? this.ball,
        carrierNumber: carrierNumber ?? this.carrierNumber,
        elapsed: elapsed ?? this.elapsed,
        actionCount: actionCount ?? this.actionCount,
        completedPasses: completedPasses ?? this.completedPasses,
        furthestX: furthestX ?? this.furthestX,
        end: end ?? this.end,
        cue: cue ?? this.cue,
      );
}

class AttackAction {
  final AttackActionKind kind;
  final int? targetNumber;
  final AttackCarryDirection? carryDirection;
  final AttackShotTarget? shotTarget;

  const AttackAction.pass(int number)
      : kind = AttackActionKind.pass,
        targetNumber = number,
        carryDirection = null,
        shotTarget = null;
  const AttackAction.carry(AttackCarryDirection direction)
      : kind = AttackActionKind.carry,
        targetNumber = null,
        carryDirection = direction,
        shotTarget = null;
  const AttackAction.hold()
      : kind = AttackActionKind.hold,
        targetNumber = null,
        carryDirection = null,
        shotTarget = null;
  const AttackAction.shoot(AttackShotTarget target)
      : kind = AttackActionKind.shoot,
        targetNumber = null,
        carryDirection = null,
        shotTarget = target;

  @override
  bool operator ==(Object other) =>
      other is AttackAction &&
      other.kind == kind &&
      other.targetNumber == targetNumber &&
      other.carryDirection == carryDirection &&
      other.shotTarget == shotTarget;
  @override
  int get hashCode =>
      Object.hash(kind, targetNumber, carryDirection, shotTarget);
}

class AttackOffsideSnapshot {
  final AttackState atKick;
  final int receiverNumber;
  final double secondLastX;
  final double lineX;
  final bool offside;
  const AttackOffsideSnapshot(
      {required this.atKick,
      required this.receiverNumber,
      required this.secondLastX,
      required this.lineX,
      required this.offside});
}

class AttackTransition {
  final AttackState before;
  final AttackState after;
  final AttackAction action;
  final double duration;
  final ScanPassPoint ballEnd;
  final AttackOffsideSnapshot? offside;
  final int? interceptorNumber;

  const AttackTransition(
      {required this.before,
      required this.after,
      required this.action,
      required this.duration,
      required this.ballEnd,
      this.offside,
      this.interceptorNumber});

  AttackState frame(double progress) {
    final t = progress.clamp(0.0, 1.0).toDouble();
    // The offside learning view deliberately freezes the release moment.
    if (after.end == AttackEnd.offside) return t >= 1 ? after : before;
    if (t >= 1) return after;
    List<AttackPlayer> interpolate(
            List<AttackPlayer> start, List<AttackPlayer> finish) =>
        [
          for (final p in start)
            p.copyWith(
                position: p.position.lerp(
                    finish.firstWhere((q) => q.number == p.number).position, t),
                facingRadians: finish
                    .firstWhere((q) => q.number == p.number)
                    .facingRadians,
                velocity:
                    finish.firstWhere((q) => q.number == p.number).velocity),
        ];
    return before.copyWith(
      attackers: interpolate(before.attackers, after.attackers),
      defenders: interpolate(before.defenders, after.defenders),
      ball: before.ball.lerp(ballEnd, t),
      elapsed: before.elapsed + duration * t,
    );
  }
}

/// Open-play possession: no elapsed wall time, random success roll or
/// independent scene resets. The caller commits only an explicit action.
class AttackEngine {
  static const double goalTop = .35;
  static const double goalBottom = .65;
  static const double goalX = 1;
  static const double _epsilon = 1e-8;
  const AttackEngine();

  AttackState initial({int variant = 0}) {
    final mirror = variant.isOdd;
    ScanPassPoint point(double x, double y) =>
        ScanPassPoint(x, mirror ? 1 - y : y);
    final attackers = [
      AttackPlayer(number: 4, position: point(.14, .56)),
      AttackPlayer(
          number: 6, position: point(.31, .56), facingRadians: math.pi),
      AttackPlayer(number: 8, position: point(.45, .25)),
      AttackPlayer(
          number: 9,
          position: point(.69, .51),
          velocity: const ScanPassPoint(.065, 0)),
    ];
    return AttackState(
        attackers: attackers,
        defenders: [
          AttackPlayer(
              number: 2,
              opponent: true,
              position: point(.40, .45),
              facingRadians: math.pi,
              velocity: ScanPassPoint(-.035, mirror ? -.03 : .03)),
          AttackPlayer(
              number: 3,
              opponent: true,
              position: point(.61, .24),
              facingRadians: math.pi),
          AttackPlayer(
              number: 5,
              opponent: true,
              position: point(.73, .71),
              facingRadians: math.pi),
          AttackPlayer(
              number: 1,
              opponent: true,
              goalkeeper: true,
              position: point(.955, .50),
              facingRadians: math.pi),
        ],
        ball: attackers.first.position,
        carrierNumber: 4);
  }

  List<AttackAction> availableActions(AttackState state) {
    if (state.finished) return const [];
    return [
      for (final player in state.attackers)
        if (player.number != state.carrierNumber)
          AttackAction.pass(player.number),
      for (final direction in AttackCarryDirection.values)
        AttackAction.carry(direction),
      const AttackAction.hold(),
      if (state.canShoot)
        for (final target in AttackShotTarget.values)
          AttackAction.shoot(target),
    ];
  }

  ScanPassPoint intendedTarget(AttackState state, AttackAction action) {
    return switch (action.kind) {
      AttackActionKind.pass => state.attackers
          .firstWhere((p) => p.number == action.targetNumber)
          .position,
      AttackActionKind.carry => _field(state.carrier.position +
          ScanPassPoint(
              .13,
              switch (action.carryDirection!) {
                AttackCarryDirection.upper => -.13,
                AttackCarryDirection.forward => 0,
                AttackCarryDirection.lower => .13,
              })),
      AttackActionKind.hold => state.ball,
      AttackActionKind.shoot => ScanPassPoint(
          1.025,
          switch (action.shotTarget!) {
            AttackShotTarget.upper => .40,
            AttackShotTarget.center => .50,
            AttackShotTarget.lower => .60,
          }),
    };
  }

  double _secondLastX(AttackState state) {
    if (state.defenders.length < 2) {
      throw StateError(
          'Offside needs at least two opponents, including the keeper.');
    }
    final xs = state.defenders.map((p) => p.position.x).toList()..sort();
    return xs[xs.length - 2];
  }

  double offsideLine(AttackState state) =>
      math.max(.5, math.max(state.ball.x, _secondLastX(state)));

  AttackOffsideSnapshot checkOffside(AttackState state, int receiverNumber) {
    final receiver =
        state.attackers.firstWhere((p) => p.number == receiverNumber);
    final secondLast = _secondLastX(state);
    final line = math.max(.5, math.max(state.ball.x, secondLast));
    return AttackOffsideSnapshot(
        atKick: state,
        receiverNumber: receiverNumber,
        secondLastX: secondLast,
        lineX: line,
        offside: receiver.position.x > line + _epsilon);
  }

  AttackTransition play(AttackState state, AttackAction action) {
    if (state.finished) throw StateError('This attack has ended.');
    if (!availableActions(state).contains(action)) {
      throw ArgumentError.value(action, 'action', 'Unavailable attack action');
    }
    var target = intendedTarget(state, action);
    var duration = switch (action.kind) {
      AttackActionKind.pass =>
        (state.ball.distanceTo(target) / .65).clamp(.28, 1.25).toDouble(),
      AttackActionKind.carry => .80,
      AttackActionKind.hold => .85,
      AttackActionKind.shoot =>
        (state.ball.distanceTo(target) / 1.1).clamp(.24, .70).toDouble(),
    };
    AttackOffsideSnapshot? offside;
    if (action.kind == AttackActionKind.pass) {
      offside = checkOffside(state, action.targetNumber!);
      final receiver =
          state.attackers.firstWhere((p) => p.number == action.targetNumber);
      target = _field(receiver.position + receiver.velocity * duration);
      duration =
          (state.ball.distanceTo(target) / .65).clamp(.28, 1.25).toDouble();
      target = _field(receiver.position + receiver.velocity * duration);
    }
    if (action.kind == AttackActionKind.shoot &&
        action.shotTarget != AttackShotTarget.center) {
      // Extreme angles and distance make the outside target harder to keep
      // inside the posts. This is deterministic, not a success percentage.
      final spread = (1 - state.ball.x) * .04 + (state.ball.y - .5).abs() * .12;
      target = ScanPassPoint(
          target.x,
          target.y +
              (action.shotTarget == AttackShotTarget.upper ? -spread : spread));
    }
    var attackers = _moveAttackers(state, action, target, duration);
    var defenders = _moveDefenders(state, action, target, duration);
    var end = action.kind == AttackActionKind.shoot ? AttackEnd.goal : null;
    var cue = switch (action.kind) {
      AttackActionKind.pass => AttackCue.received,
      AttackActionKind.carry => AttackCue.carried,
      AttackActionKind.hold => AttackCue.waited,
      AttackActionKind.shoot => AttackCue.goal,
    };
    int? interceptedBy;
    var fraction = 1.0;
    // Sample simultaneous player/ball movement; never test only the final
    // positions or draw a ball beyond its actual interception.
    for (var sample = 1; sample <= 80; sample++) {
      final t = sample / 80;
      final ball = state.ball.lerp(target, t);
      for (final defender in state.defenders) {
        final destination =
            defenders.firstWhere((p) => p.number == defender.number);
        final position = defender.position.lerp(destination.position, t);
        final radius = action.kind == AttackActionKind.shoot
            ? (defender.goalkeeper ? .048 : .029)
            : (defender.goalkeeper ? .032 : .026);
        if (position.distanceTo(ball) > radius) continue;
        fraction = t;
        interceptedBy = defender.number;
        end = action.kind == AttackActionKind.shoot
            ? (defender.goalkeeper ? AttackEnd.saved : AttackEnd.blocked)
            : AttackEnd.intercepted;
        cue = switch (end) {
          AttackEnd.saved => AttackCue.saved,
          AttackEnd.blocked => AttackCue.blocked,
          _ => AttackCue.intercepted,
        };
        break;
      }
      if (interceptedBy != null) break;
    }
    // Being in an offside position is not itself an offence. Here a targeted
    // receiver becomes involved only if the pass reaches them; a defender
    // intercepting first ends possession instead of inventing an offside call.
    if (interceptedBy == null && offside?.offside == true) {
      final after = state.copyWith(
          end: AttackEnd.offside,
          cue: AttackCue.offside,
          actionCount: state.actionCount + 1);
      return AttackTransition(
          before: state,
          after: after,
          action: action,
          duration: .35,
          ballEnd: state.ball,
          offside: offside);
    }
    if (interceptedBy != null) {
      target = state.ball.lerp(target, fraction);
      attackers = _truncate(state.attackers, attackers, fraction);
      defenders = _truncate(state.defenders, defenders, fraction);
      duration *= fraction;
    } else if (action.kind == AttackActionKind.shoot) {
      final crossing = (goalX - state.ball.x) / (target.x - state.ball.x);
      final crossingY = state.ball.y + (target.y - state.ball.y) * crossing;
      if (crossingY <= goalTop || crossingY >= goalBottom) {
        end = AttackEnd.wide;
        cue = AttackCue.wide;
      }
    }
    final completedPass = action.kind == AttackActionKind.pass && end == null;
    final after = state.copyWith(
      attackers: attackers,
      defenders: defenders,
      ball: target,
      carrierNumber: completedPass ? action.targetNumber : state.carrierNumber,
      elapsed: state.elapsed + duration,
      actionCount: state.actionCount + 1,
      completedPasses: state.completedPasses + (completedPass ? 1 : 0),
      furthestX: math.max(state.furthestX, target.x),
      end: end,
      cue: cue,
    );
    return AttackTransition(
        before: state,
        after: after,
        action: action,
        duration: duration,
        ballEnd: target,
        offside: offside,
        interceptorNumber: interceptedBy);
  }

  List<AttackPlayer> _moveAttackers(AttackState state, AttackAction action,
      ScanPassPoint ballTarget, double seconds) {
    final line = offsideLine(state);
    return [
      for (final player in state.attackers)
        (() {
          if (action.kind == AttackActionKind.pass &&
              player.number == action.targetNumber) {
            return _moved(player, ballTarget, seconds);
          }
          if (player.number == state.carrierNumber) {
            final position = action.kind == AttackActionKind.carry
                ? ballTarget
                : player.position;
            return _moved(player, position, seconds).copyWith(
                facingRadians: math.atan2(ballTarget.y - player.position.y,
                    ballTarget.x - player.position.x));
          }
          final targetX = switch (player.number) {
            4 => (ballTarget.x - .22).clamp(.14, .72).toDouble(),
            6 => (ballTarget.x - .08).clamp(.31, .84).toDouble(),
            8 => math
                .max(player.position.x + .03, ballTarget.x + .12)
                .clamp(.45, .91)
                .toDouble(),
            _ =>
              action.kind == AttackActionKind.hold && player.position.x > line
                  ? math.max(.51, line - .035)
                  : math
                      .max(player.position.x + .065, ballTarget.x + .20)
                      .clamp(.62, .96)
                      .toDouble(),
          };
          // Maintain width instead of teleporting to a fresh authored scene.
          final targetY = player.number == 6
              ? (state.attackers.firstWhere((p) => p.number == 8).position.y <
                      .5
                  ? .58
                  : .42)
              : player.position.y;
          return _moved(
              player,
              _toward(player.position, ScanPassPoint(targetX, targetY),
                  .10 * seconds),
              seconds);
        })()
    ];
  }

  List<AttackPlayer> _moveDefenders(AttackState state, AttackAction action,
      ScanPassPoint ballTarget, double seconds) {
    final outfield = state.defenders.where((p) => !p.goalkeeper).toList();
    final nearest = outfield.reduce((a, b) =>
        a.position.distanceTo(state.ball) <= b.position.distanceTo(state.ball)
            ? a
            : b);
    return [
      for (final player in state.defenders)
        (() {
          if (player.goalkeeper) {
            final targetY = action.kind == AttackActionKind.shoot
                ? ballTarget.y.clamp(.37, .63).toDouble()
                : (.5 + (state.ball.y - .5) * .34).clamp(.41, .59).toDouble();
            final reactionTime = action.kind == AttackActionKind.shoot
                ? math.max(0.0, seconds - .18)
                : seconds;
            return _moved(
                player,
                _toward(player.position, ScanPassPoint(.955, targetY),
                    .12 * reactionTime),
                seconds);
          }
          final isChasing = player.number == nearest.number;
          final target = isChasing
              ? (action.kind == AttackActionKind.shoot
                  ? state.ball
                  : ballTarget)
              : ScanPassPoint(
                  math.max(
                      player.position.x, math.min(.91, state.ball.x + .15)),
                  player.position.y + (state.ball.y - player.position.y) * .10,
                );
          return _moved(
              player,
              _toward(
                  player.position, target, (isChasing ? .073 : .045) * seconds),
              seconds);
        })()
    ];
  }

  static List<AttackPlayer> _truncate(
          List<AttackPlayer> before, List<AttackPlayer> after, double t) =>
      [
        for (final player in before)
          player.copyWith(
              position: player.position.lerp(
                  after.firstWhere((p) => p.number == player.number).position,
                  t),
              facingRadians: after
                  .firstWhere((p) => p.number == player.number)
                  .facingRadians,
              velocity:
                  after.firstWhere((p) => p.number == player.number).velocity),
      ];

  static AttackPlayer _moved(
      AttackPlayer player, ScanPassPoint target, double seconds) {
    final safe = _field(target);
    final delta = safe - player.position;
    return player.copyWith(
        position: safe,
        velocity: delta * (seconds > 0 ? 1 / seconds : 0),
        facingRadians: delta.distance > .001
            ? math.atan2(delta.y, delta.x)
            : player.facingRadians);
  }

  static ScanPassPoint _toward(
      ScanPassPoint from, ScanPassPoint to, double distance) {
    final delta = to - from;
    if (delta.distance <= distance || delta.distance < .00001) {
      return _field(to);
    }
    return _field(from + delta * (distance / delta.distance));
  }

  static ScanPassPoint _field(ScanPassPoint point) =>
      point.clampToField(minX: .055, maxX: .96, minY: .10, maxY: .90);
}
