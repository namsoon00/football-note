import 'dart:math' as math;

import 'scan_pass_attack.dart';
import 'scan_pass_game.dart' show ScanPassPoint;

enum JudgmentFamily {
  rearPressure,
  sidePressure,
  openFrontSecondDefender,
  passingLane,
  receiverSupport,
  numericalAdvantage,
  postPassSupportAngle,
  transitionBackSpace,
}

enum JudgmentDecisionKind { firstTouch, nextAction, support }

enum JudgmentAction {
  touchLeft,
  touchRight,
  touchForward,
  shield,
  oneTouchReturn,
  passForward,
  passWide,
  passBack,
  carryForward,
  protect,
  supportInside,
  supportWide,
  supportBehind,
}

enum JudgmentQuality { spaceGained, possessionRetained, optionsPreserved, lost }

enum JudgmentReason {
  rearPressureEscaped,
  rearPressureArrived,
  sidePressureUsed,
  sidePressureTrap,
  secondDefenderContained,
  secondDefenderStepped,
  laneOpened,
  laneScreened,
  receiverSupported,
  receiverIsolated,
  overloadUsed,
  sparePlayerMissed,
  supportAngleOpened,
  supportAngleBlocked,
  transitionSecured,
  backSpaceExposed,
  possessionKept,
  pressureRemains,
  spaceCreated,
  optionsReduced,
  intercepted,
  offside,
}

class JudgmentSceneSpec {
  final JudgmentFamily family;
  final int configuration;
  final int variation;

  const JudgmentSceneSpec({
    required this.family,
    required this.configuration,
    this.variation = 0,
  }) : assert(configuration >= 0 && configuration < 6);

  JudgmentSceneSpec nextConfiguration() => JudgmentSceneSpec(
        family: family,
        configuration: pairedCueConfiguration,
        variation: variation + 1,
      );

  int get pairedCueConfiguration => switch (configuration) {
        0 => 3,
        3 => 0,
        1 => 4,
        4 => 1,
        2 => 5,
        _ => 2,
      };

  JudgmentSceneSpec pairedCue() => JudgmentSceneSpec(
        family: family,
        configuration: pairedCueConfiguration,
        variation: variation,
      );

  String get id => '${family.name}-$configuration';
}

enum JudgmentCueKind {
  pressure,
  coverLane,
  supportRun,
  receiverMovement,
  recoveryRun,
  offsideLine,
  pressureRetreating,
  pressureHolding,
}

enum JudgmentHabit {
  firstTouchAway,
  scanCover,
  supportReceiver,
  useSparePlayer,
  secureBehindBall,
  adjustReturnAngle,
}

class JudgmentActorCue {
  final int number;
  final bool opponent;
  final JudgmentCueKind kind;
  final ScanPassPoint from;
  final ScanPassPoint to;

  const JudgmentActorCue({
    required this.number,
    required this.opponent,
    required this.kind,
    required this.from,
    required this.to,
  });
}

class JudgmentCoachingEvidence {
  final JudgmentActorCue observedCue;
  final JudgmentHabit nextHabit;
  final bool technicalPassCompleted;
  final bool receiverSupportUseful;
  final JudgmentAction? supportedAlternative;
  final JudgmentQuality? supportedAlternativeQuality;
  final JudgmentReason? supportedAlternativeReason;

  const JudgmentCoachingEvidence({
    required this.observedCue,
    required this.nextHabit,
    required this.technicalPassCompleted,
    required this.receiverSupportUseful,
    this.supportedAlternative,
    this.supportedAlternativeQuality,
    this.supportedAlternativeReason,
  });

  bool get hasSupportedAlternative => supportedAlternative != null;
}

class JudgmentScene {
  final JudgmentSceneSpec spec;
  final AttackState initial;
  final AttackState reception;
  final ScanPassPoint cueFrom;
  final ScanPassPoint cueTo;
  final bool cueIsOpponent;
  final List<JudgmentAction> firstActions;
  final int forwardNumber;
  final bool supportAfterForwardPass;
  final bool supportAfterWidePass;
  final bool supportAfterBackPass;

  JudgmentScene({
    required this.spec,
    required this.initial,
    required this.reception,
    required this.cueFrom,
    required this.cueTo,
    required this.cueIsOpponent,
    required List<JudgmentAction> firstActions,
    this.forwardNumber = 8,
    this.supportAfterForwardPass = true,
    this.supportAfterWidePass = false,
    this.supportAfterBackPass = false,
  }) : firstActions = List.unmodifiable(firstActions);
}

class JudgmentChoice {
  final JudgmentAction action;
  final ScanPassPoint target;
  final int? targetNumber;

  const JudgmentChoice({
    required this.action,
    required this.target,
    this.targetNumber,
  });
}

class JudgmentPhase {
  final JudgmentScene scene;
  final JudgmentDecisionKind kind;
  final AttackState state;
  final int activeNumber;
  final int step;
  final List<JudgmentChoice> choices;
  final JudgmentAction? priorAction;

  JudgmentPhase({
    required this.scene,
    required this.kind,
    required this.state,
    required this.activeNumber,
    required this.step,
    required List<JudgmentChoice> choices,
    this.priorAction,
  }) : choices = List.unmodifiable(choices);
}

class JudgmentResult {
  final JudgmentPhase phase;
  final JudgmentChoice choice;
  final JudgmentQuality quality;
  final JudgmentReason reason;
  final AttackState before;
  final AttackState after;
  final List<AttackTransition> transitions;
  final JudgmentPhase? nextPhase;
  final ScanPassPoint pressurePoint;
  final List<ScanPassPoint> outletPoints;

  JudgmentResult({
    required this.phase,
    required this.choice,
    required this.quality,
    required this.reason,
    required this.before,
    required this.after,
    required List<AttackTransition> transitions,
    required this.nextPhase,
    required this.pressurePoint,
    required List<ScanPassPoint> outletPoints,
  })  : transitions = List.unmodifiable(transitions),
        outletPoints = List.unmodifiable(outletPoints);

  double get duration =>
      transitions.fold(0, (sum, transition) => sum + transition.duration);

  AttackState frame(double progress) {
    if (transitions.isEmpty) return after;
    if (progress >= 1) return after;
    var remaining = duration * progress.clamp(0.0, 1.0);
    for (final transition in transitions) {
      if (remaining <= transition.duration) {
        return transition.frame(
          transition.duration <= 0 ? 1 : remaining / transition.duration,
        );
      }
      remaining -= transition.duration;
    }
    return after;
  }
}

class JudgmentEngine {
  const JudgmentEngine();

  List<int> availableConnections(AttackState state) {
    final points = _outletPoints(state, state.carrierNumber);
    return List.unmodifiable([
      for (final player in state.attackers)
        if (player.number != state.carrierNumber &&
            points.any((point) => point.distanceTo(player.position) < 1e-8))
          player.number,
    ]);
  }

  List<JudgmentSceneSpec> catalog({int variation = 0}) => [
        for (final family in JudgmentFamily.values)
          for (var configuration = 0; configuration < 6; configuration += 1)
            JudgmentSceneSpec(
              family: family,
              configuration: configuration,
              variation: variation,
            ),
      ];

  List<JudgmentSceneSpec> session({int seed = 0, int length = 10}) {
    const families = JudgmentFamily.values;
    final start = seed.abs() % families.length;
    final firstEight = [
      for (var index = 0; index < math.min(8, length); index += 1)
        JudgmentSceneSpec(
          family: families[(start + index) % families.length],
          configuration: (seed + index * 2).abs() % 6,
          variation: seed + index,
        ),
    ];
    if (length <= firstEight.length) return firstEight;
    final delayed = <JudgmentSceneSpec>[
      for (var index = 0;
          index < firstEight.length && firstEight.length + index < length;
          index += 1)
        JudgmentSceneSpec(
          family: firstEight[index].family,
          configuration: firstEight[index].pairedCueConfiguration,
          variation: seed + 31 + index,
        ),
    ];
    return [
      ...firstEight,
      for (var index = 0; firstEight.length + index < length; index += 1)
        delayed[index % delayed.length],
    ];
  }

  JudgmentScene scene(JudgmentSceneSpec spec) {
    final mirror = spec.variation.isOdd;
    final yShift = (((spec.variation.abs() ~/ 2) % 3) - 1) * .018;
    ScanPassPoint point(double x, double y) => ScanPassPoint(
          x,
          (mirror ? 1 - y : y) + (mirror ? -yShift : yShift),
        ).clampToField(minX: .04, maxX: .96, minY: .08, maxY: .92);
    ScanPassPoint velocity(double x, double y) =>
        ScanPassPoint(x, mirror ? -y : y);
    AttackPlayer player(
      int number,
      double x,
      double y, {
      bool opponent = false,
      bool keeper = false,
      double facing = 0,
      double vx = 0,
      double vy = 0,
    }) =>
        AttackPlayer(
          number: number,
          position: point(x, y),
          opponent: opponent,
          goalkeeper: keeper,
          facingRadians: mirror ? -facing : facing,
          velocity: velocity(vx, vy),
        );

    final attackers = <AttackPlayer>[
      player(4, .16, .56),
      player(6, .38, .52, facing: math.pi),
      player(7, .48, .22),
      player(8, .65, .44, facing: math.pi),
      player(9, .82, .50),
      player(10, .70, .76),
    ];
    var receivedAttackers = <AttackPlayer>[
      player(4, .18, .55, vx: .010, vy: -.004),
      player(6, .38, .52, facing: math.pi),
      player(7, .505, .205, vx: .026, vy: -.018),
      player(8, .655, .435, facing: math.pi, vx: .018, vy: .006),
      player(9, .835, .50, vx: .018),
      player(10, .715, .735, vx: .016, vy: -.024),
    ];
    var defenders = <AttackPlayer>[
      player(2, .51, .65, opponent: true, facing: math.pi),
      player(3, .68, .34, opponent: true, facing: math.pi),
      player(5, .76, .72, opponent: true, facing: math.pi),
      player(1, .96, .50, opponent: true, keeper: true, facing: math.pi),
    ];
    var receivedDefenders = <AttackPlayer>[
      player(2, .50, .61,
          opponent: true, facing: math.pi, vx: -.026, vy: -.030),
      player(3, .67, .35, opponent: true, facing: math.pi, vx: -.020, vy: .015),
      player(5, .75, .69,
          opponent: true, facing: math.pi, vx: -.022, vy: -.016),
      player(1, .955, .50, opponent: true, keeper: true, facing: math.pi),
    ];
    var cueFrom = defenders.first.position;
    var cueTo = defenders.first.position;
    var cueIsOpponent = true;
    var firstActions = const <JudgmentAction>[
      JudgmentAction.touchLeft,
      JudgmentAction.touchRight,
      JudgmentAction.touchForward,
      JudgmentAction.shield,
    ];
    var forwardNumber = 8;
    var supportForward = true;
    var supportWide = false;
    var supportBack = false;

    void replaceDefender(AttackPlayer defender, {bool cue = true}) {
      receivedDefenders = [
        defender,
        ...receivedDefenders.where((item) => item.number != defender.number),
      ]..sort((a, b) => a.number.compareTo(b.number));
      if (cue) {
        cueFrom = defenders
            .firstWhere((item) => item.number == defender.number)
            .position;
        cueTo = defender.position;
        cueIsOpponent = true;
      }
    }

    void replaceAttacker(AttackPlayer attacker, {bool cue = true}) {
      receivedAttackers = [
        attacker,
        ...receivedAttackers.where((item) => item.number != attacker.number),
      ]..sort((a, b) => a.number.compareTo(b.number));
      if (cue) {
        cueFrom = attackers
            .firstWhere((item) => item.number == attacker.number)
            .position;
        cueTo = attacker.position;
        cueIsOpponent = false;
      }
    }

    switch (spec.family) {
      case JudgmentFamily.rearPressure:
        firstActions = const [
          JudgmentAction.touchLeft,
          JudgmentAction.touchRight,
          JudgmentAction.touchForward,
          JudgmentAction.oneTouchReturn,
        ];

        switch (spec.configuration) {
          case 0:
            replaceDefender(player(2, .423, .52,
                opponent: true, facing: math.pi, vx: -.050));
            replaceDefender(
                player(3, .64, .43, opponent: true, vx: -.020, vy: .010),
                cue: false);

          case 1:
            replaceDefender(
                player(2, .56, .52, opponent: true, facing: math.pi, vx: .018));
            replaceAttacker(
                player(8, .61, .44, facing: math.pi, vx: -.032, vy: .004),
                cue: false);

          case 2:
            replaceDefender(player(2, .43, .44,
                opponent: true, facing: 2.45, vx: -.030, vy: .055));
            replaceDefender(
                player(5, .69, .60, opponent: true, vx: -.030, vy: -.018),
                cue: false);
          case 3:
            replaceDefender(player(2, .425, .52,
                opponent: true, facing: math.pi, vx: -.018, vy: -.006));
            replaceAttacker(
                player(8, .58, .44, facing: math.pi, vx: -.044, vy: .004),
                cue: false);
            replaceDefender(
                player(3, .62, .46, opponent: true, vx: -.034, vy: .012),
                cue: false);
          case 4:
            replaceDefender(player(2, .555, .52,
                opponent: true, facing: math.pi, vx: -.050));
            replaceAttacker(player(9, .85, .49, vx: .034, vy: -.004),
                cue: false);
            replaceDefender(
                player(5, .74, .62, opponent: true, vx: -.050, vy: -.010),
                cue: false);
          case 5:
            replaceDefender(player(2, .43, .45,
                opponent: true, facing: 2.45, vx: -.055, vy: .030));
            replaceAttacker(player(7, .56, .24, vx: .052, vy: -.014),
                cue: false);
            replaceDefender(
                player(3, .61, .34, opponent: true, vx: -.030, vy: .034),
                cue: false);
        }
      case JudgmentFamily.sidePressure:
        switch (spec.configuration) {
          case 0:
            replaceDefender(player(2, .39, .36,
                opponent: true, facing: 1.3, vx: .012, vy: .070));
            replaceDefender(
                player(3, .59, .43, opponent: true, vx: -.024, vy: .020),
                cue: false);

          case 1:
            replaceDefender(player(2, .39, .68,
                opponent: true, facing: -1.3, vx: .010, vy: -.070));
            replaceDefender(
                player(5, .60, .60, opponent: true, vx: -.022, vy: -.020),
                cue: false);

          case 2:
            replaceDefender(player(2, .45, .62,
                opponent: true, facing: -2.2, vx: -.036, vy: -.040));
            replaceAttacker(player(10, .66, .67, vx: .040, vy: -.054),
                cue: false);
          case 3:
            replaceDefender(player(2, .39, .36,
                opponent: true, facing: 1.3, vx: .036, vy: .044));
            replaceAttacker(player(7, .55, .18, vx: .050, vy: -.010),
                cue: false);
            replaceDefender(
                player(3, .62, .32, opponent: true, vx: -.028, vy: .036),
                cue: false);
          case 4:
            replaceDefender(player(2, .39, .68,
                opponent: true, facing: -1.3, vx: .035, vy: -.043));
            replaceAttacker(player(10, .60, .63, vx: .052, vy: -.060),
                cue: false);
            replaceDefender(
                player(5, .63, .62, opponent: true, vx: -.038, vy: -.030),
                cue: false);
          case 5:
            replaceDefender(player(2, .47, .60,
                opponent: true, facing: -2.2, vx: -.058, vy: -.010));
            replaceAttacker(player(8, .62, .52, vx: -.038, vy: -.004),
                cue: false);
            replaceDefender(
                player(3, .63, .46, opponent: true, vx: -.040, vy: .006),
                cue: false);
        }
      case JudgmentFamily.openFrontSecondDefender:
        switch (spec.configuration) {
          case 0:
            replaceDefender(
                player(3, .71, .35, opponent: true, facing: math.pi, vx: .004));
            replaceAttacker(player(8, .66, .43, vx: .024, vy: .006),
                cue: false);

          case 1:
            replaceDefender(player(3, .54, .50,
                opponent: true, facing: math.pi, vx: -.028));
            replaceDefender(
                player(2, .46, .56, opponent: true, vx: -.020, vy: -.016),
                cue: false);

          case 2:
            replaceDefender(player(3, .58, .40,
                opponent: true, facing: math.pi, vx: -.020, vy: .035));
            replaceAttacker(player(10, .68, .64, vx: .030, vy: -.044),
                cue: false);
          case 3:
            replaceDefender(player(3, .70, .35,
                opponent: true, facing: math.pi, vx: -.045, vy: .012));
            replaceAttacker(
                player(8, .61, .42, facing: math.pi, vx: -.038, vy: .004),
                cue: false);
            replaceDefender(
                player(5, .72, .63, opponent: true, vx: -.022, vy: -.036),
                cue: false);
          case 4:
            replaceDefender(player(3, .55, .49,
                opponent: true, facing: math.pi, vx: .010, vy: -.020));
            replaceAttacker(player(7, .57, .22, vx: .048, vy: -.006),
                cue: false);
            replaceDefender(
                player(2, .48, .56, opponent: true, vx: -.050, vy: -.006),
                cue: false);
          case 5:
            replaceDefender(player(3, .58, .40,
                opponent: true, facing: math.pi, vx: -.052, vy: .040));
            replaceAttacker(player(10, .63, .58, vx: .046, vy: -.052),
                cue: false);
            replaceDefender(
                player(5, .69, .62, opponent: true, vx: -.046, vy: -.040),
                cue: false);
        }
      case JudgmentFamily.passingLane:
        firstActions = const [
          JudgmentAction.touchLeft,
          JudgmentAction.touchRight,
          JudgmentAction.touchForward,
          JudgmentAction.oneTouchReturn,
        ];
        switch (spec.configuration) {
          case 0:
            replaceDefender(player(2, .46, .62,
                opponent: true, facing: math.pi, vx: -.045, vy: -.030));
            replaceDefender(
                player(3, .62, .43, opponent: true, vx: -.012, vy: .006),
                cue: false);

          case 1:
            replaceDefender(player(2, .53, .48,
                opponent: true, facing: math.pi, vx: -.010));
            replaceDefender(
                player(3, .61, .45, opponent: true, vx: -.034, vy: .002),
                cue: false);

          case 2:
            replaceDefender(
                player(2, .30, .56, opponent: true, facing: 0, vx: -.020));
            replaceAttacker(player(8, .62, .43, vx: -.028, vy: .002),
                cue: false);
          case 3:
            replaceDefender(player(2, .46, .56,
                opponent: true, facing: math.pi, vx: .018, vy: -.052));
            replaceAttacker(player(8, .61, .42, vx: -.046, vy: .000),
                cue: false);
            replaceDefender(
                player(3, .61, .39, opponent: true, vx: -.028, vy: .038),
                cue: false);
          case 4:
            replaceDefender(player(2, .525, .48,
                opponent: true, facing: math.pi, vx: -.050, vy: .016));
            replaceAttacker(player(7, .57, .20, vx: .046, vy: -.008),
                cue: false);
            replaceDefender(
                player(3, .60, .44, opponent: true, vx: -.044, vy: .006),
                cue: false);
          case 5:
            replaceDefender(player(2, .31, .56,
                opponent: true, facing: 0, vx: .048, vy: -.004));
            replaceAttacker(player(10, .64, .64, vx: .052, vy: -.044),
                cue: false);
            replaceDefender(
                player(5, .66, .60, opponent: true, vx: -.050, vy: -.030),
                cue: false);
        }
      case JudgmentFamily.receiverSupport:
        switch (spec.configuration) {
          case 0:
            replaceAttacker(player(10, .72, .61, vx: .030, vy: -.038));
            replaceDefender(
                player(3, .70, .24, opponent: true, vx: -.012, vy: .008),
                cue: false);
            replaceDefender(
                player(5, .74, .66, opponent: true, vx: -.024, vy: -.032),
                cue: false);

          case 1:
            replaceAttacker(player(10, .90, .79, vx: -.010, vy: -.010));
            replaceDefender(
                player(5, .70, .51, opponent: true, facing: math.pi));

          case 2:
            replaceAttacker(player(7, .58, .28, vx: .040, vy: -.015));
            replaceDefender(
                player(3, .62, .36, opponent: true, vx: -.020, vy: .020),
                cue: false);

            supportWide = true;
          case 3:
            replaceAttacker(player(10, .69, .60, vx: -.046, vy: -.026));
            replaceAttacker(player(8, .59, .43, vx: -.040, vy: .000),
                cue: false);
            replaceDefender(
                player(5, .70, .56, opponent: true, vx: -.044, vy: -.018),
                cue: false);
          case 4:
            replaceAttacker(player(10, .84, .72, vx: .030, vy: -.052));
            replaceDefender(
                player(5, .68, .50, opponent: true, vx: -.050, vy: .010),
                cue: false);
            replaceDefender(
                player(3, .64, .43, opponent: true, vx: -.032, vy: -.005),
                cue: false);
          case 5:
            replaceAttacker(player(7, .56, .30, vx: .052, vy: .022));
            replaceAttacker(player(10, .64, .59, vx: .042, vy: -.052),
                cue: false);
            replaceDefender(
                player(3, .61, .39, opponent: true, vx: -.052, vy: .026),
                cue: false);
            supportWide = true;
        }
      case JudgmentFamily.numericalAdvantage:
        switch (spec.configuration) {
          case 0:
            replaceDefender(player(5, .82, .72, opponent: true, vx: -.016));
            replaceAttacker(player(10, .68, .66, vx: .036, vy: -.044),
                cue: false);

          case 1:
            replaceAttacker(player(7, .57, .24, vx: .046, vy: -.012));
            replaceDefender(player(3, .67, .47, opponent: true, vx: -.020));

            supportWide = true;
          case 2:
            replaceDefender(player(2, .42, .52,
                opponent: true, facing: math.pi, vx: -.050));
            replaceAttacker(player(4, .19, .55, vx: .016, vy: -.004),
                cue: false);

            supportBack = true;
          case 3:
            replaceDefender(
                player(5, .82, .72, opponent: true, vx: -.054, vy: -.032));
            replaceAttacker(player(10, .61, .60, vx: -.040, vy: -.030),
                cue: false);
            replaceDefender(
                player(3, .62, .41, opponent: true, vx: -.034, vy: .024),
                cue: false);
          case 4:
            replaceAttacker(player(7, .58, .25, vx: -.020, vy: .030));
            replaceAttacker(player(10, .61, .61, vx: .050, vy: -.054),
                cue: false);
            replaceDefender(
                player(3, .66, .47, opponent: true, vx: -.058, vy: -.006),
                cue: false);
            supportWide = true;
          case 5:
            replaceDefender(player(2, .42, .52,
                opponent: true, facing: math.pi, vx: -.020));
            replaceDefender(
                player(5, .69, .62, opponent: true, vx: -.060, vy: -.018),
                cue: false);
            replaceAttacker(player(4, .20, .57, vx: .010, vy: .000),
                cue: false);
            supportBack = true;
        }
      case JudgmentFamily.postPassSupportAngle:
        switch (spec.configuration) {
          case 0:
            replaceAttacker(player(8, .66, .43, vx: .024, vy: .006),
                cue: false);
            replaceDefender(
                player(3, .66, .35, opponent: true, vx: -.020, vy: .018),
                cue: false);
          case 1:
            replaceDefender(player(3, .60, .35,
                opponent: true, facing: math.pi, vx: -.018));
            replaceAttacker(player(10, .68, .64, vx: .026, vy: -.036),
                cue: false);

          case 2:
            replaceAttacker(player(8, .66, .28, facing: math.pi, vx: .014));
            replaceDefender(
                player(3, .56, .14, opponent: true, facing: math.pi));
          case 3:
            replaceAttacker(
                player(8, .62, .43, facing: math.pi, vx: -.046, vy: .000));
            replaceDefender(
                player(3, .62, .40, opponent: true, vx: -.050, vy: .010),
                cue: false);
            replaceDefender(
                player(5, .70, .59, opponent: true, vx: -.040, vy: -.030),
                cue: false);
          case 4:
            replaceDefender(player(3, .60, .35,
                opponent: true, facing: math.pi, vx: -.052, vy: .038));
            replaceAttacker(player(10, .63, .58, vx: .048, vy: -.050),
                cue: false);
          case 5:
            replaceAttacker(
                player(8, .71, .29, facing: math.pi, vx: -.042, vy: .030));
            replaceDefender(player(3, .60, .28,
                opponent: true, facing: math.pi, vx: -.052, vy: .048));
            replaceDefender(
                player(5, .68, .58, opponent: true, vx: -.042, vy: -.020),
                cue: false);
        }
      case JudgmentFamily.transitionBackSpace:
        firstActions = const [
          JudgmentAction.touchLeft,
          JudgmentAction.touchRight,
          JudgmentAction.touchForward,
          JudgmentAction.oneTouchReturn,
        ];
        switch (spec.configuration) {
          case 0:
            replaceDefender(player(2, .42, .52,
                opponent: true, facing: math.pi, vx: -.055));
            replaceDefender(
                player(5, .72, .63, opponent: true, vx: -.050, vy: -.010),
                cue: false);

            supportBack = true;
          case 1:
            replaceDefender(player(5, .73, .62,
                opponent: true, facing: math.pi, vx: -.060));
            replaceAttacker(player(4, .18, .54, vx: .004, vy: .000),
                cue: false);

          case 2:
            replaceAttacker(player(9, .87, .50, vx: .028));
            replaceDefender(player(5, .73, .72, opponent: true));

            forwardNumber = 9;
            supportBack = true;
          case 3:
            replaceDefender(player(2, .42, .52,
                opponent: true, facing: math.pi, vx: -.020, vy: .008));
            replaceDefender(
                player(5, .70, .61, opponent: true, vx: -.065, vy: -.024),
                cue: false);
            replaceAttacker(player(4, .20, .57, vx: -.006, vy: .000),
                cue: false);
            supportBack = true;
          case 4:
            replaceDefender(player(5, .74, .62,
                opponent: true, facing: math.pi, vx: -.026, vy: -.002));
            replaceAttacker(player(8, .62, .43, vx: -.046, vy: .000),
                cue: false);
            replaceDefender(
                player(3, .60, .42, opponent: true, vx: -.048, vy: .010),
                cue: false);
          case 5:
            replaceAttacker(player(9, .86, .50, vx: -.040));
            replaceDefender(
                player(5, .72, .71, opponent: true, vx: -.062, vy: -.032));
            replaceDefender(
                player(3, .63, .42, opponent: true, vx: -.042, vy: .006),
                cue: false);
            forwardNumber = 9;
            supportBack = true;
        }
    }

    final initial = AttackState(
      attackers: attackers,
      defenders: defenders,
      ball: attackers.firstWhere((player) => player.number == 4).position,
      carrierNumber: 4,
    );
    final reception = AttackState(
      attackers: receivedAttackers,
      defenders: receivedDefenders,
      ball:
          receivedAttackers.firstWhere((player) => player.number == 6).position,
      carrierNumber: 6,
      completedPasses: 1,
      actionCount: 1,
      elapsed: 2.4,
      cue: AttackCue.received,
    );
    return JudgmentScene(
      spec: spec,
      initial: initial,
      reception: reception,
      cueFrom: cueFrom,
      cueTo: cueTo,
      cueIsOpponent: cueIsOpponent,
      firstActions: firstActions
          .map((action) => mirror
              ? switch (action) {
                  JudgmentAction.touchLeft => JudgmentAction.touchRight,
                  JudgmentAction.touchRight => JudgmentAction.touchLeft,
                  _ => action
                }
              : action)
          .toList(),
      forwardNumber: forwardNumber,
      supportAfterForwardPass: supportForward,
      supportAfterWidePass: supportWide,
      supportAfterBackPass: supportBack,
    );
  }

  AttackState observationFrame(JudgmentScene scene, double progress) {
    return AttackTransition(
      before: scene.initial,
      after: scene.reception,
      action: const AttackAction.pass(6),
      duration: 2.4,
      ballEnd: scene.reception.ball,
    ).frame(progress);
  }

  JudgmentPhase firstPhase(JudgmentScene scene) => JudgmentPhase(
        scene: scene,
        kind: JudgmentDecisionKind.firstTouch,
        state: scene.reception,
        activeNumber: 6,
        step: 1,
        choices: [
          for (final action in scene.firstActions)
            JudgmentChoice(
              action: action,
              target: _targetFor(scene.reception, 6, action, scene),
              targetNumber: action == JudgmentAction.oneTouchReturn ? 4 : null,
            ),
        ],
      );

  List<JudgmentResult> alternatives(JudgmentPhase phase) => [
        for (final choice in phase.choices) choose(phase, choice),
      ];

  JudgmentResult choose(JudgmentPhase phase, JudgmentChoice choice) {
    return switch (phase.kind) {
      JudgmentDecisionKind.firstTouch => _firstTouch(phase, choice),
      JudgmentDecisionKind.nextAction => _nextAction(phase, choice),
      JudgmentDecisionKind.support => _support(phase, choice),
    };
  }

  ScanPassPoint targetFor(
    AttackState state,
    int activeNumber,
    JudgmentAction action,
    JudgmentScene scene,
  ) =>
      _targetFor(state, activeNumber, action, scene);

  JudgmentCoachingEvidence coachingEvidence(
    JudgmentResult result, {
    List<JudgmentResult> alternatives = const <JudgmentResult>[],
  }) {
    final cue = _actorCueFor(result);
    final technicalPassCompleted = result.transitions.any((transition) =>
        transition.action.kind == AttackActionKind.pass &&
        transition.after.end == null &&
        transition.after.carrierNumber == transition.action.targetNumber);
    final receiverSupportUseful = !result.after.finished &&
        (!technicalPassCompleted ||
            (_outletPoints(result.after, result.after.carrierNumber)
                    .isNotEmpty &&
                _nearestDefender(result.after, result.after.ball)
                        .position
                        .distanceTo(result.after.ball) >
                    .060));
    final supported = _supportedAlternative(result, alternatives);
    return JudgmentCoachingEvidence(
      observedCue: cue,
      nextHabit: _nextHabitFor(result),
      technicalPassCompleted: technicalPassCompleted,
      receiverSupportUseful: receiverSupportUseful,
      supportedAlternative: supported?.choice.action,
      supportedAlternativeQuality: supported?.quality,
      supportedAlternativeReason: supported?.reason,
    );
  }

  JudgmentResult _firstTouch(JudgmentPhase phase, JudgmentChoice choice) {
    final before = phase.state;
    final transition = choice.action == JudgmentAction.oneTouchReturn
        ? _pass(before, 4)
        : _carry(before, choice.target,
            duration: .62, shielding: choice.action == JudgmentAction.shield);
    final after = transition.after;
    final assessment = _assess(phase, choice, before, after);
    final next = after.finished
        ? null
        : choice.action == JudgmentAction.oneTouchReturn
            ? _supportPhase(phase.scene, after, phase.step + 1, choice.action)
            : _nextActionPhase(
                phase.scene, after, phase.step + 1, choice.action);
    return _result(
        phase, choice, [transition], assessment.$1, assessment.$2, next);
  }

  JudgmentResult _nextAction(JudgmentPhase phase, JudgmentChoice choice) {
    final before = phase.state;
    final transition = switch (choice.action) {
      JudgmentAction.passForward ||
      JudgmentAction.passWide ||
      JudgmentAction.passBack =>
        _pass(before, choice.targetNumber!),
      JudgmentAction.carryForward =>
        _carry(before, choice.target, duration: .95),
      JudgmentAction.protect =>
        _carry(before, choice.target, duration: .70, shielding: true),
      _ => throw ArgumentError.value(
          choice.action, 'action', 'Not an action decision'),
    };
    final after = transition.after;
    final assessment = _assess(phase, choice, before, after);
    final next = !after.finished &&
            transition.action.kind == AttackActionKind.pass &&
            _needsSupport(phase.scene, choice.action)
        ? _supportPhase(phase.scene, after, phase.step + 1, choice.action)
        : null;
    return _result(
        phase, choice, [transition], assessment.$1, assessment.$2, next);
  }

  JudgmentResult _support(JudgmentPhase phase, JudgmentChoice choice) {
    final before = phase.state;
    final runner = _attacker(before, 6);
    final duration = (runner.position.distanceTo(choice.target) / .18)
        .clamp(.5, 2.1)
        .toDouble();
    for (var sample = 1; sample <= 48; sample++) {
      final t = sample / 48;
      final frame = _advance(before, duration * t, focus: before.ball);
      final carrier = _attacker(frame, frame.carrierNumber);
      final defender = _nearestDefender(frame, carrier.position);
      if (defender.position.distanceTo(carrier.position) < .018) {
        final lost = frame.copyWith(
            attackers: _movePlayer(
                frame.attackers, 6, runner.position.lerp(choice.target, t)),
            ball: carrier.position,
            end: AttackEnd.intercepted,
            cue: AttackCue.intercepted,
            actionCount: before.actionCount + 1);
        return _result(
            phase,
            choice,
            [
              AttackTransition(
                  before: before,
                  after: lost,
                  action: const AttackAction.hold(),
                  duration: duration * t,
                  ballEnd: lost.ball,
                  interceptorNumber: defender.number)
            ],
            JudgmentQuality.lost,
            JudgmentReason.receiverIsolated,
            null);
      }
    }
    var world = _advance(before, duration, focus: before.ball);
    world = world.copyWith(
      attackers: _movePlayer(world.attackers, 6, choice.target),
      ball: _attacker(world, world.carrierNumber).position,
      cue: AttackCue.waited,
      actionCount: before.actionCount + 1,
    );
    final move = AttackTransition(
        before: before,
        after: world,
        action: const AttackAction.hold(),
        duration: duration,
        ballEnd: world.ball);
    // The selected support run is followed by an actual return attempt. All
    // branches use the same passer skill and moving interception model.
    final pass = _pass(world, 6);
    final retained = !pass.after.finished;
    return _result(
        phase,
        choice,
        [move, pass],
        retained ? JudgmentQuality.optionsPreserved : JudgmentQuality.lost,
        retained
            ? JudgmentReason.supportAngleOpened
            : pass.after.end == AttackEnd.offside
                ? JudgmentReason.offside
                : JudgmentReason.supportAngleBlocked,
        null);
  }

  JudgmentResult _result(
      JudgmentPhase phase,
      JudgmentChoice choice,
      List<AttackTransition> transitions,
      JudgmentQuality quality,
      JudgmentReason reason,
      JudgmentPhase? next) {
    final after = transitions.last.after;
    return JudgmentResult(
        phase: phase,
        choice: choice,
        quality: quality,
        reason: reason,
        before: phase.state,
        after: after,
        transitions: transitions,
        nextPhase: next,
        pressurePoint: _nearestDefender(after, after.ball).position,
        outletPoints: after.finished
            ? const []
            : _outletPoints(after, after.carrierNumber));
  }

  (JudgmentQuality, JudgmentReason) _assess(
    JudgmentPhase phase,
    JudgmentChoice choice,
    AttackState before,
    AttackState after,
  ) {
    if (after.finished) {
      return (
        JudgmentQuality.lost,
        after.end == AttackEnd.offside
            ? JudgmentReason.offside
            : JudgmentReason.intercepted
      );
    }
    final oldGap =
        _nearestDefender(before, before.ball).position.distanceTo(before.ball);
    final gap =
        _nearestDefender(after, after.ball).position.distanceTo(after.ball);
    final oldOptions = _outletPoints(before, before.carrierNumber).length;
    final options = _outletPoints(after, after.carrierNumber).length;
    final passCompleted = before.carrierNumber != after.carrierNumber;
    final beforePressure = _nearestDefender(before, before.ball);
    final pressureDelta = before.ball - beforePressure.position;
    final pressureBehind = beforePressure.position.x > before.ball.x - .015 &&
        pressureDelta.y.abs() < .12;
    final pressureSide = pressureDelta.y.abs() >= .08;
    if (gap < .065) {
      return (
        JudgmentQuality.possessionRetained,
        phase.kind == JudgmentDecisionKind.firstTouch
            ? pressureBehind
                ? JudgmentReason.rearPressureArrived
                : pressureSide
                    ? JudgmentReason.sidePressureTrap
                    : JudgmentReason.pressureRemains
            : JudgmentReason.pressureRemains
      );
    }
    if (options < oldOptions && options < 2) {
      return (
        JudgmentQuality.possessionRetained,
        JudgmentReason.optionsReduced
      );
    }
    if (gap > oldGap + .025 ||
        (after.ball.x > before.ball.x + .055 && gap > .10)) {
      return (
        JudgmentQuality.spaceGained,
        phase.kind == JudgmentDecisionKind.firstTouch
            ? pressureBehind
                ? JudgmentReason.rearPressureEscaped
                : pressureSide
                    ? JudgmentReason.sidePressureUsed
                    : JudgmentReason.spaceCreated
            : switch (choice.action) {
                JudgmentAction.passWide => JudgmentReason.laneOpened,
                JudgmentAction.passBack => JudgmentReason.transitionSecured,
                JudgmentAction.carryForward => JudgmentReason.spaceCreated,
                _ => JudgmentReason.spaceCreated,
              }
      );
    }
    if (options >= 2) {
      return (
        JudgmentQuality.optionsPreserved,
        passCompleted
            ? JudgmentReason.receiverSupported
            : JudgmentReason.possessionKept
      );
    }
    return (JudgmentQuality.possessionRetained, JudgmentReason.possessionKept);
  }

  JudgmentPhase _nextActionPhase(
    JudgmentScene scene,
    AttackState state,
    int step,
    JudgmentAction priorAction,
  ) {
    final actions = <JudgmentAction>[
      JudgmentAction.passForward,
      JudgmentAction.passWide,
      JudgmentAction.carryForward,
      JudgmentAction.protect,
    ];
    if (scene.supportAfterBackPass ||
        scene.spec.family == JudgmentFamily.rearPressure) {
      actions[3] = JudgmentAction.passBack;
    }
    return JudgmentPhase(
      scene: scene,
      kind: JudgmentDecisionKind.nextAction,
      state: state,
      activeNumber: state.carrierNumber,
      step: step,
      priorAction: priorAction,
      choices: [
        for (final action in actions)
          JudgmentChoice(
            action: action,
            target: _targetFor(state, state.carrierNumber, action, scene),
            targetNumber: switch (action) {
              JudgmentAction.passForward => scene.forwardNumber,
              JudgmentAction.passWide => 7,
              JudgmentAction.passBack => 4,
              _ => null,
            },
          ),
      ],
    );
  }

  JudgmentPhase _supportPhase(
    JudgmentScene scene,
    AttackState state,
    int step,
    JudgmentAction priorAction,
  ) {
    const actions = <JudgmentAction>[
      JudgmentAction.supportInside,
      JudgmentAction.supportWide,
      JudgmentAction.supportBehind,
    ];
    return JudgmentPhase(
      scene: scene,
      kind: JudgmentDecisionKind.support,
      state: state,
      activeNumber: 6,
      step: step,
      priorAction: priorAction,
      choices: [
        for (final action in actions)
          JudgmentChoice(
            action: action,
            target: _targetFor(state, 6, action, scene),
          ),
      ],
    );
  }

  bool _needsSupport(JudgmentScene scene, JudgmentAction action) {
    return switch (action) {
      JudgmentAction.passForward => scene.supportAfterForwardPass,
      JudgmentAction.passWide => scene.supportAfterWidePass,
      JudgmentAction.passBack => scene.supportAfterBackPass,
      _ => false,
    };
  }

  JudgmentResult? _supportedAlternative(
    JudgmentResult result,
    List<JudgmentResult> alternatives,
  ) {
    final baseRank = _qualityRank(result.quality);
    final available = alternatives
        .where((item) =>
            item.choice.action != result.choice.action &&
            item.phase.kind == result.phase.kind &&
            item.phase.step == result.phase.step &&
            _sameDecisionSnapshot(item.before, result.before))
        .toList()
      ..sort((a, b) => _qualityRank(b.quality).compareTo(
            _qualityRank(a.quality),
          ));
    for (final item in available) {
      if (_qualityRank(item.quality) > baseRank) return item;
    }
    return available.isEmpty ? null : available.first;
  }

  JudgmentActorCue _actorCueFor(JudgmentResult result) {
    final last = result.transitions.last;
    // The first-touch review refers to movement during the incoming pass,
    // before the decision, rather than calling its consequence an observed cue.
    if (result.phase.kind == JudgmentDecisionKind.firstTouch &&
        result.choice.action != JudgmentAction.oneTouchReturn) {
      final number = last.interceptorNumber ??
          _nearestDefender(result.before, result.before.ball).number;
      final start = result.phase.scene.initial.defenders
          .firstWhere((p) => p.number == number);
      final end = result.before.defenders.firstWhere((p) => p.number == number);
      final closure = start.position.distanceTo(result.before.ball) -
          end.position.distanceTo(result.before.ball);
      return _defenderCue(
          result.phase.scene.initial,
          result.before,
          number,
          closure > .01
              ? JudgmentCueKind.pressure
              : closure < -.01
                  ? JudgmentCueKind.pressureRetreating
                  : JudgmentCueKind.pressureHolding);
    }
    final interceptedBy = last.interceptorNumber;
    if (interceptedBy != null) {
      return _defenderCue(
        result.before,
        result.after,
        interceptedBy,
        last.action.kind == AttackActionKind.pass
            ? JudgmentCueKind.coverLane
            : JudgmentCueKind.pressure,
      );
    }
    if (result.after.end == AttackEnd.offside) {
      final number = last.offside?.receiverNumber ?? result.choice.targetNumber;
      if (number != null) {
        return _attackerCue(
          result.before,
          result.before,
          number,
          JudgmentCueKind.offsideLine,
        );
      }
    }
    if (result.phase.kind == JudgmentDecisionKind.support) {
      return _attackerCue(
        result.before,
        result.after,
        6,
        JudgmentCueKind.supportRun,
      );
    }
    if (last.action.kind == AttackActionKind.pass &&
        last.action.targetNumber != null &&
        !result.after.finished) {
      return _attackerCue(
        result.before,
        result.after,
        last.action.targetNumber!,
        JudgmentCueKind.receiverMovement,
      );
    }
    final beforeDefender = _nearestDefender(result.before, result.before.ball);
    return _defenderCue(
      result.before,
      result.after,
      beforeDefender.number,
      beforeDefender.position.distanceTo(result.after.ball) >
              result.after.defenders
                      .firstWhere((p) => p.number == beforeDefender.number)
                      .position
                      .distanceTo(result.after.ball) +
                  .01
          ? JudgmentCueKind.pressure
          : JudgmentCueKind.pressureHolding,
    );
  }

  JudgmentActorCue _defenderCue(
    AttackState before,
    AttackState after,
    int number,
    JudgmentCueKind kind,
  ) {
    final start =
        before.defenders.firstWhere((player) => player.number == number);
    final end = after.defenders.firstWhere(
      (player) => player.number == number,
      orElse: () => start,
    );
    return JudgmentActorCue(
      number: number,
      opponent: true,
      kind: kind,
      from: start.position,
      to: end.position,
    );
  }

  JudgmentActorCue _attackerCue(
    AttackState before,
    AttackState after,
    int number,
    JudgmentCueKind kind,
  ) {
    final start =
        before.attackers.firstWhere((player) => player.number == number);
    final end = after.attackers.firstWhere(
      (player) => player.number == number,
      orElse: () => start,
    );
    return JudgmentActorCue(
      number: number,
      opponent: false,
      kind: kind,
      from: start.position,
      to: end.position,
    );
  }

  JudgmentHabit _nextHabitFor(JudgmentResult result) {
    if (result.after.end == AttackEnd.offside) {
      return JudgmentHabit.scanCover;
    }
    return switch (result.phase.kind) {
      JudgmentDecisionKind.firstTouch => JudgmentHabit.firstTouchAway,
      JudgmentDecisionKind.support => JudgmentHabit.adjustReturnAngle,
      JudgmentDecisionKind.nextAction => switch (
            result.phase.scene.spec.family) {
          JudgmentFamily.receiverSupport => JudgmentHabit.supportReceiver,
          JudgmentFamily.numericalAdvantage => JudgmentHabit.useSparePlayer,
          JudgmentFamily.transitionBackSpace => JudgmentHabit.secureBehindBall,
          _ => JudgmentHabit.scanCover,
        },
    };
  }
}

int _qualityRank(JudgmentQuality quality) => switch (quality) {
      JudgmentQuality.lost => 0,
      JudgmentQuality.possessionRetained => 1,
      JudgmentQuality.spaceGained => 2,
      JudgmentQuality.optionsPreserved => 3,
    };

bool _sameDecisionSnapshot(AttackState a, AttackState b) {
  if (a.carrierNumber != b.carrierNumber ||
      a.ball.distanceTo(b.ball) > 1e-8 ||
      a.elapsed != b.elapsed ||
      a.end != b.end) {
    return false;
  }
  bool playersMatch(List<AttackPlayer> left, List<AttackPlayer> right) {
    if (left.length != right.length) return false;
    for (final player in left) {
      final other = right.firstWhere(
        (item) => item.number == player.number,
        orElse: () => player.copyWith(
          position: ScanPassPoint(player.position.x + 1, player.position.y),
        ),
      );
      if (player.position.distanceTo(other.position) > 1e-8 ||
          player.velocity.distanceTo(other.velocity) > 1e-8 ||
          (player.facingRadians - other.facingRadians).abs() > 1e-8 ||
          player.goalkeeper != other.goalkeeper) {
        return false;
      }
    }
    return true;
  }

  return playersMatch(a.attackers, b.attackers) &&
      playersMatch(a.defenders, b.defenders);
}

ScanPassPoint _targetFor(
  AttackState state,
  int activeNumber,
  JudgmentAction action,
  JudgmentScene scene,
) {
  final active = _attacker(state, activeNumber);
  ScanPassPoint offset(double x, double y) =>
      (active.position + ScanPassPoint(x, y))
          .clampToField(minX: .04, maxX: .94, minY: .08, maxY: .92);
  return switch (action) {
    JudgmentAction.touchLeft => offset(.030, -.085),
    JudgmentAction.touchRight => offset(.030, .085),
    JudgmentAction.touchForward => offset(.090, 0),
    JudgmentAction.shield => _shieldTarget(state, active.position, .045),
    JudgmentAction.oneTouchReturn => _attacker(state, 4).position,
    JudgmentAction.passForward =>
      _attacker(state, scene.forwardNumber).position,
    JudgmentAction.passWide => _attacker(state, 7).position,
    JudgmentAction.passBack => _attacker(state, 4).position,
    JudgmentAction.carryForward => offset(.120, 0),
    JudgmentAction.protect => _shieldTarget(state, active.position, .050),
    JudgmentAction.supportInside =>
      (state.ball + ScanPassPoint(-.105, state.ball.y < .5 ? .125 : -.125))
          .clampToField(minX: .04, maxX: .94, minY: .08, maxY: .92),
    JudgmentAction.supportWide =>
      (state.ball + ScanPassPoint(-.080, state.ball.y < .5 ? -.145 : .145))
          .clampToField(minX: .04, maxX: .94, minY: .08, maxY: .92),
    JudgmentAction.supportBehind => (state.ball + const ScanPassPoint(-.155, 0))
        .clampToField(minX: .04, maxX: .94, minY: .08, maxY: .92),
  };
}

AttackTransition _pass(AttackState before, int receiverNumber) {
  final receiver = _attacker(before, receiverNumber);
  final offside = const AttackEngine().checkOffside(before, receiverNumber);
  final frozenNumber =
      before.carrierNumber == 6 && receiverNumber != 6 ? 6 : null;
  final duration = (before.ball.distanceTo(receiver.position) / .55)
      .clamp(.25, 1.45)
      .toDouble();
  final destination = (receiver.position + receiver.velocity * duration)
      .clampToField(minX: .04, maxX: .95, minY: .08, maxY: .92);
  for (var sample = 1; sample <= 64; sample++) {
    final fraction = sample / 64;
    final ball = before.ball.lerp(destination, fraction);
    final world = _advance(
      before,
      duration * fraction,
      focus: ball,
      frozenNumber: frozenNumber,
    );
    final defender = _nearestDefender(world, ball);
    if (defender.position.distanceTo(ball) < .026) {
      return AttackTransition(
          before: before,
          after: world.copyWith(
              ball: ball,
              end: AttackEnd.intercepted,
              cue: AttackCue.intercepted,
              actionCount: before.actionCount + 1),
          action: AttackAction.pass(receiverNumber),
          duration: duration * fraction,
          ballEnd: ball,
          interceptorNumber: defender.number);
    }
  }
  // Position at the kick matters, and an opponent intercepting before the
  // target becomes involved ends the play before an offside offence.
  if (offside.offside) {
    return AttackTransition(
        before: before,
        after: before.copyWith(
            end: AttackEnd.offside,
            cue: AttackCue.offside,
            actionCount: before.actionCount + 1),
        action: AttackAction.pass(receiverNumber),
        duration: .42,
        ballEnd: before.ball,
        offside: offside);
  }
  final world = _advance(
    before,
    duration,
    focus: destination,
    frozenNumber: frozenNumber,
  );
  final after = world.copyWith(
      attackers: _movePlayer(world.attackers, receiverNumber, destination),
      ball: destination,
      carrierNumber: receiverNumber,
      completedPasses: before.completedPasses + 1,
      actionCount: before.actionCount + 1,
      furthestX: math.max(before.furthestX, destination.x),
      cue: AttackCue.received);
  return AttackTransition(
      before: before,
      after: after,
      action: AttackAction.pass(receiverNumber),
      duration: duration,
      ballEnd: destination);
}

AttackTransition _carry(AttackState before, ScanPassPoint target,
    {required double duration, bool shielding = false}) {
  final destination =
      target.clampToField(minX: .04, maxX: .94, minY: .08, maxY: .92);
  final direction = destination - before.ball;
  List<AttackPlayer> attackersAt(AttackState world, ScanPassPoint ball) => [
        for (final p in world.attackers)
          p.number == before.carrierNumber
              ? p.copyWith(
                  position: ball,
                  velocity: const ScanPassPoint(0, 0),
                  facingRadians: math.atan2(direction.y, direction.x))
              : p,
      ];
  for (var sample = 1; sample <= 48; sample++) {
    final fraction = sample / 48;
    final ball = before.ball.lerp(destination, fraction);
    final world = _advance(before, duration * fraction, focus: ball);
    final defender = _nearestDefender(world, ball);
    if (defender.position.distanceTo(ball) < (shielding ? .018 : .026)) {
      return AttackTransition(
          before: before,
          after: world.copyWith(
              attackers: attackersAt(world, ball),
              ball: ball,
              end: AttackEnd.intercepted,
              cue: AttackCue.intercepted,
              actionCount: before.actionCount + 1),
          action: const AttackAction.carry(AttackCarryDirection.forward),
          duration: duration * fraction,
          ballEnd: ball,
          interceptorNumber: defender.number);
    }
  }
  final world = _advance(before, duration, focus: destination);
  return AttackTransition(
      before: before,
      after: world.copyWith(
          attackers: attackersAt(world, destination),
          ball: destination,
          actionCount: before.actionCount + 1,
          furthestX: math.max(before.furthestX, destination.x),
          cue: AttackCue.carried),
      action: const AttackAction.carry(AttackCarryDirection.forward),
      duration: duration,
      ballEnd: destination);
}

AttackState _advance(
  AttackState state,
  double seconds, {
  ScanPassPoint? focus,
  int? frozenNumber,
}) {
  final ball = focus ?? state.ball;
  final attackers = [
    for (final p in state.attackers)
      (() {
        if (p.number == frozenNumber) {
          return p.copyWith(velocity: const ScanPassPoint(0, 0));
        }
        final position = (p.position + p.velocity * seconds)
            .clampToField(minX: .04, maxX: .96, minY: .08, maxY: .92);
        final delta = position - p.position;
        return p.copyWith(
          position: position,
          facingRadians: delta.distance > .001
              ? math.atan2(delta.y, delta.x)
              : p.facingRadians,
        );
      })()
  ];
  final nearest = state.defenders.where((player) => !player.goalkeeper).reduce(
      (a, b) =>
          a.position.distanceTo(ball) <= b.position.distanceTo(ball) ? a : b);
  final defenders = [
    for (final p in state.defenders)
      (() {
        if (p.goalkeeper) {
          final targetY = (.5 + (ball.y - .5) * .35).clamp(.40, .60).toDouble();
          final target = ScanPassPoint(.955, targetY);
          final delta = target - p.position;
          final step = _limitedStep(delta, .060 * seconds);
          return p.copyWith(
            position: (p.position + p.velocity * seconds * .35 + step)
                .clampToField(minX: .04, maxX: .96, minY: .08, maxY: .92),
            facingRadians: step.distance > .001
                ? math.atan2(step.y, step.x)
                : p.facingRadians,
          );
        }
        final delta = ball - p.position;
        final distance = delta.distance;
        final response = distance > .001 ? delta * (1 / distance) : delta;
        final cover = _coverIntent(state, p, ball);
        final coverDelta = cover - p.position;
        final coverUnit = coverDelta.distance > .001
            ? coverDelta * (1 / coverDelta.distance)
            : const ScanPassPoint(0, 0);
        final isPresser = p.number == nearest.number || distance < .115;
        final base =
            p.velocity.distance > .002 ? p.velocity : const ScanPassPoint(0, 0);
        final velocity = isPresser
            ? base * .48 + response * .055
            : base * .58 + coverUnit * .042;
        return p.copyWith(
            position: (p.position + velocity * seconds)
                .clampToField(minX: .04, maxX: .96, minY: .08, maxY: .92),
            facingRadians: velocity.distance > .002
                ? math.atan2(velocity.y, velocity.x)
                : p.facingRadians);
      })()
  ];
  return state.copyWith(
      attackers: attackers,
      defenders: defenders,
      ball:
          attackers.firstWhere((p) => p.number == state.carrierNumber).position,
      elapsed: state.elapsed + seconds);
}

AttackPlayer _attacker(AttackState state, int number) =>
    state.attackers.firstWhere((player) => player.number == number);

AttackPlayer _nearestDefender(AttackState state, ScanPassPoint point) {
  final defenders =
      state.defenders.where((player) => !player.goalkeeper).toList()
        ..sort(
          (a, b) => a.position.distanceTo(point).compareTo(
                b.position.distanceTo(point),
              ),
        );
  return defenders.first;
}

ScanPassPoint _coverIntent(
  AttackState state,
  AttackPlayer defender,
  ScanPassPoint ball,
) {
  final forwardTargets = state.attackers
      .where((player) => player.number != state.carrierNumber)
      .toList()
    ..sort((a, b) => b.position.x.compareTo(a.position.x));
  final primary = forwardTargets.isEmpty ? state.carrier : forwardTargets.first;
  final wide = forwardTargets.firstWhere(
    (player) => player.number == 7 || player.number == 10,
    orElse: () => primary,
  );
  final target = switch (defender.number) {
    3 => ball.lerp(primary.position, .58),
    5 => ball.lerp(wide.position, .62),
    _ => ScanPassPoint(
        math.max(defender.position.x, math.min(.90, ball.x + .10)),
        defender.position.y + (ball.y - defender.position.y) * .25,
      ),
  };
  return target.clampToField(minX: .04, maxX: .96, minY: .08, maxY: .92);
}

ScanPassPoint _limitedStep(ScanPassPoint delta, double limit) {
  if (delta.distance <= limit || delta.distance < .00001) return delta;
  return delta * (limit / delta.distance);
}

List<AttackPlayer> _movePlayer(
  List<AttackPlayer> players,
  int number,
  ScanPassPoint position, {
  bool faceForward = false,
}) =>
    [
      for (final player in players)
        player.number == number
            ? player.copyWith(
                position: position,
                velocity: const ScanPassPoint(0, 0),
                facingRadians: faceForward ? 0 : player.facingRadians,
              )
            : player,
    ];

List<ScanPassPoint> _outletPoints(AttackState state, int carrierNumber) {
  if (state.finished) return const [];
  final carrier = _attacker(state, carrierNumber);
  return [
    for (final teammate in state.attackers)
      if (teammate.number != carrierNumber &&
          teammate.position.distanceTo(carrier.position) >= .07 &&
          teammate.position.distanceTo(carrier.position) <= .40 &&
          !_pass(state, teammate.number).after.finished)
        teammate.position
  ];
}

ScanPassPoint _shieldTarget(
    AttackState state, ScanPassPoint position, double distance) {
  final delta = position - _nearestDefender(state, position).position;
  final unit = delta.distance > .001
      ? delta * (1 / delta.distance)
      : const ScanPassPoint(-1, 0);
  return (position + unit * distance)
      .clampToField(minX: .04, maxX: .94, minY: .08, maxY: .92);
}
