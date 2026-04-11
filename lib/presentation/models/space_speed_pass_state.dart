enum SpaceSpeedBallPhase { held, flying, settling }

class SpaceSpeedPassState {
  final bool attackerAIsPasser;
  final SpaceSpeedBallPhase ballPhase;
  final bool goalChanceActive;

  const SpaceSpeedPassState({
    required this.attackerAIsPasser,
    required this.ballPhase,
    required this.goalChanceActive,
  });

  bool get isControllingPasser {
    if (ballPhase == SpaceSpeedBallPhase.settling) {
      return true;
    }
    return !(ballPhase == SpaceSpeedBallPhase.flying && !goalChanceActive);
  }

  bool get controllableAttackerIsA =>
      isControllingPasser ? attackerAIsPasser : !attackerAIsPasser;

  bool get controllableAttackerIsB => !controllableAttackerIsA;

  bool get ballOwnerAttackerIsA =>
      ballPhase == SpaceSpeedBallPhase.flying && !goalChanceActive
          ? !attackerAIsPasser
          : attackerAIsPasser;

  bool get ballOwnerAttackerIsB => !ballOwnerAttackerIsA;

  bool get activeReceiverIsA => !attackerAIsPasser;

  bool get passerControllable => controllableAttackerIsA == attackerAIsPasser;

  bool get receiverControllable => !passerControllable;
}
