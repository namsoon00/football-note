import 'dart:math' as math;

import '../../domain/scan_pass/scan_pass_game.dart';

/// This teaching view hides nearby rear pressure, while keeping the wider
/// tactical situation visible. It is not a measurement of a player's eyesight.
class ScanPassLearningSpace {
  static const double rearCheckRadius = 0.20;
  static const double rearHalfAngle = math.pi * 0.42;

  static bool needsRearCheck(
    ScanPassPoint point,
    ScanPassPlayer receiver,
  ) {
    final delta = point - receiver.position;
    if (delta.distance > rearCheckRadius || delta.distance < 0.001) {
      return false;
    }
    final behind = receiver.facingRadians + math.pi;
    final difference =
        (math.atan2(delta.y, delta.x) - behind + math.pi) % (2 * math.pi) -
            math.pi;
    return difference.abs() <= rearHalfAngle;
  }
}

/// A requested direction, before the outcome of an action is known.
///
/// These paths deliberately do not use interception points or score results.
/// The executed timeline remains the authority after the learner commits.
class ScanPassLearningIntent {
  final ScanPassPoint from;
  final ScanPassPoint to;
  final ScanPassPathType type;

  const ScanPassLearningIntent({
    required this.from,
    required this.to,
    required this.type,
  });

  static ScanPassLearningIntent firstTouch(ScanPassFirstTouchState state) {
    return ScanPassLearningIntent(
      from: state.startPosition,
      to: state.action == ScanPassFirstTouch.returnTo4
          ? state.scenario.centerBack.at(state.touchStartTime).position
          : state.receiverPosition,
      type: state.action == ScanPassFirstTouch.returnTo4
          ? ScanPassPathType.pass
          : ScanPassPathType.firstTouch,
    );
  }

  static List<ScanPassLearningIntent> nextAction(
    ScanPassFirstTouchState state,
    ScanPassNextAction action,
  ) {
    final from = state.receiverPosition;
    if (state.returned) {
      final to = ScanPassMatchEngine.supportPosition(from, action);
      return [
        ScanPassLearningIntent(
          from: from,
          to: to,
          type: action == ScanPassNextAction.holdPocket
              ? ScanPassPathType.hold
              : ScanPassPathType.offBallRun,
        ),
      ];
    }
    final role = switch (action) {
      ScanPassNextAction.passTo4 => ScanPassPlayerRole.centerBack4,
      ScanPassNextAction.passTo9 => ScanPassPlayerRole.forward9,
      _ => ScanPassPlayerRole.support8,
    };
    return [
      if (action == ScanPassNextAction.holdPassTo8)
        ScanPassLearningIntent(
          from: state.ballPosition,
          to: state.ballPosition,
          type: ScanPassPathType.hold,
        ),
      ScanPassLearningIntent(
        from: state.ballPosition,
        to: state.scenario.playerAt(role, state.completedAt).position,
        type: ScanPassPathType.pass,
      ),
    ];
  }
}
