import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/presentation/models/space_speed_pass_state.dart';

void main() {
  test('pass cycle keeps control with the ball owner after receive starts', () {
    const heldByA = SpaceSpeedPassState(
      attackerAIsPasser: true,
      ballPhase: SpaceSpeedBallPhase.held,
      goalChanceActive: false,
    );
    expect(heldByA.isControllingPasser, isTrue);
    expect(heldByA.controllableAttackerIsA, isTrue);
    expect(heldByA.activeReceiverIsA, isFalse);

    const flyingToB = SpaceSpeedPassState(
      attackerAIsPasser: true,
      ballPhase: SpaceSpeedBallPhase.flying,
      goalChanceActive: false,
    );
    expect(flyingToB.isControllingPasser, isFalse);
    expect(flyingToB.controllableAttackerIsA, isFalse);
    expect(flyingToB.activeReceiverIsA, isFalse);

    const settlingOnB = SpaceSpeedPassState(
      attackerAIsPasser: false,
      ballPhase: SpaceSpeedBallPhase.settling,
      goalChanceActive: false,
    );
    expect(settlingOnB.isControllingPasser, isTrue);
    expect(settlingOnB.controllableAttackerIsA, isFalse);
    expect(settlingOnB.activeReceiverIsA, isTrue);

    const heldByB = SpaceSpeedPassState(
      attackerAIsPasser: false,
      ballPhase: SpaceSpeedBallPhase.held,
      goalChanceActive: false,
    );
    expect(heldByB.isControllingPasser, isTrue);
    expect(heldByB.controllableAttackerIsA, isFalse);
    expect(heldByB.activeReceiverIsA, isTrue);

    const flyingBackToA = SpaceSpeedPassState(
      attackerAIsPasser: false,
      ballPhase: SpaceSpeedBallPhase.flying,
      goalChanceActive: false,
    );
    expect(flyingBackToA.isControllingPasser, isFalse);
    expect(flyingBackToA.controllableAttackerIsA, isTrue);
    expect(flyingBackToA.activeReceiverIsA, isTrue);
  });

  test('goal chance keeps shooter control while the ball is flying', () {
    const shotState = SpaceSpeedPassState(
      attackerAIsPasser: true,
      ballPhase: SpaceSpeedBallPhase.flying,
      goalChanceActive: true,
    );

    expect(shotState.isControllingPasser, isTrue);
    expect(shotState.controllableAttackerIsA, isTrue);
    expect(shotState.passerControllable, isTrue);
    expect(shotState.receiverControllable, isFalse);
  });
}
