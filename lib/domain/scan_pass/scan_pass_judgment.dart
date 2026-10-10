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
  }) : assert(configuration >= 0 && configuration < 3);

  JudgmentSceneSpec nextConfiguration() => JudgmentSceneSpec(
        family: family,
        configuration: (configuration + 1) % 3,
        variation: variation + 1,
      );

  String get id => '${family.name}-$configuration';
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

  List<JudgmentSceneSpec> catalog({int variation = 0}) => [
        for (final family in JudgmentFamily.values)
          for (var configuration = 0; configuration < 3; configuration += 1)
            JudgmentSceneSpec(
              family: family,
              configuration: configuration,
              variation: variation,
            ),
      ];

  List<JudgmentSceneSpec> session({int seed = 0, int length = 10}) {
    const families = JudgmentFamily.values;
    final start = seed.abs() % families.length;
    return [
      for (var index = 0; index < length; index += 1)
        JudgmentSceneSpec(
          family: families[(start + index) % families.length],
          configuration: (seed + index * 2).abs() % 3,
          variation: seed + index,
        ),
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
    var receivedAttackers = attackers;
    var defenders = <AttackPlayer>[
      player(2, .51, .65, opponent: true, facing: math.pi),
      player(3, .68, .34, opponent: true, facing: math.pi),
      player(5, .76, .72, opponent: true, facing: math.pi),
      player(1, .96, .50, opponent: true, keeper: true, facing: math.pi),
    ];
    var receivedDefenders = defenders;
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

    void replaceDefender(AttackPlayer defender) {
      receivedDefenders = [
        defender,
        ...defenders.where((item) => item.number != defender.number),
      ]..sort((a, b) => a.number.compareTo(b.number));
      cueFrom = defenders
          .firstWhere((item) => item.number == defender.number)
          .position;
      cueTo = defender.position;
    }

    void replaceAttacker(AttackPlayer attacker) {
      receivedAttackers = [
        attacker,
        ...attackers.where((item) => item.number != attacker.number),
      ]..sort((a, b) => a.number.compareTo(b.number));
      cueFrom = attackers
          .firstWhere((item) => item.number == attacker.number)
          .position;
      cueTo = attacker.position;
      cueIsOpponent = false;
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

          case 1:
            replaceDefender(
                player(2, .56, .52, opponent: true, facing: math.pi, vx: .018));

          case 2:
            replaceDefender(player(2, .43, .44,
                opponent: true, facing: 2.45, vx: -.030, vy: .055));
        }
      case JudgmentFamily.sidePressure:
        switch (spec.configuration) {
          case 0:
            replaceDefender(player(2, .39, .36,
                opponent: true, facing: 1.3, vx: .012, vy: .070));

          case 1:
            replaceDefender(player(2, .39, .68,
                opponent: true, facing: -1.3, vx: .010, vy: -.070));

          case 2:
            replaceDefender(player(2, .45, .62,
                opponent: true, facing: -2.2, vx: -.036, vy: -.040));
        }
      case JudgmentFamily.openFrontSecondDefender:
        switch (spec.configuration) {
          case 0:
            replaceDefender(
                player(3, .71, .35, opponent: true, facing: math.pi, vx: .004));

          case 1:
            replaceDefender(player(3, .54, .50,
                opponent: true, facing: math.pi, vx: -.028));

          case 2:
            replaceDefender(player(3, .58, .40,
                opponent: true, facing: math.pi, vx: -.020, vy: .035));
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
            replaceDefender(player(2, .46, .56,
                opponent: true, facing: math.pi, vx: -.045));

          case 1:
            replaceDefender(player(2, .53, .48,
                opponent: true, facing: math.pi, vx: -.010));

          case 2:
            replaceDefender(
                player(2, .30, .56, opponent: true, facing: 0, vx: -.020));
        }
      case JudgmentFamily.receiverSupport:
        switch (spec.configuration) {
          case 0:
            replaceAttacker(player(10, .72, .61));

          case 1:
            replaceAttacker(player(10, .90, .79));
            replaceDefender(
                player(5, .70, .51, opponent: true, facing: math.pi));

          case 2:
            replaceAttacker(player(7, .58, .28));

            supportWide = true;
        }
      case JudgmentFamily.numericalAdvantage:
        switch (spec.configuration) {
          case 0:
            replaceDefender(player(5, .82, .72, opponent: true));

          case 1:
            replaceAttacker(player(7, .57, .24));
            replaceDefender(player(3, .67, .47, opponent: true, vx: -.020));

            supportWide = true;
          case 2:
            replaceDefender(player(2, .42, .52,
                opponent: true, facing: math.pi, vx: -.050));

            supportBack = true;
        }
      case JudgmentFamily.postPassSupportAngle:
        switch (spec.configuration) {
          case 0:
            break;
          case 1:
            replaceDefender(player(3, .60, .35,
                opponent: true, facing: math.pi, vx: -.018));

          case 2:
            replaceAttacker(player(8, .72, .28, facing: math.pi));
            replaceDefender(
                player(3, .60, .27, opponent: true, facing: math.pi));
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

            supportBack = true;
          case 1:
            replaceDefender(player(5, .73, .62,
                opponent: true, facing: math.pi, vx: -.060));

          case 2:
            replaceAttacker(player(9, .87, .50));
            replaceDefender(player(5, .73, .72, opponent: true));

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

  JudgmentResult _firstTouch(JudgmentPhase phase, JudgmentChoice choice) {
    final before = phase.state;
    final transition = choice.action == JudgmentAction.oneTouchReturn
        ? _pass(before, 4)
        : _carry(before, choice.target,
            duration: .62, shielding: choice.action == JudgmentAction.shield);
    final after = transition.after;
    final assessment = _assess(before, after);
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
    final assessment = _assess(before, after);
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
      AttackState before, AttackState after) {
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
    if (gap < .065) {
      return (
        JudgmentQuality.possessionRetained,
        JudgmentReason.pressureRemains
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
      return (JudgmentQuality.spaceGained, JudgmentReason.spaceCreated);
    }
    if (options >= 2) {
      return (
        JudgmentQuality.optionsPreserved,
        before.carrierNumber != after.carrierNumber
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
      (state.ball + ScanPassPoint(-.105, state.ball.y < .5 ? .085 : -.085))
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
  final duration = (before.ball.distanceTo(receiver.position) / .55)
      .clamp(.25, 1.45)
      .toDouble();
  final destination = (receiver.position + receiver.velocity * duration)
      .clampToField(minX: .04, maxX: .95, minY: .08, maxY: .92);
  for (var sample = 1; sample <= 64; sample++) {
    final fraction = sample / 64;
    final ball = before.ball.lerp(destination, fraction);
    final world = _advance(before, duration * fraction, focus: ball);
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
  final world = _advance(before, duration, focus: destination);
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

AttackState _advance(AttackState state, double seconds,
    {ScanPassPoint? focus}) {
  final ball = focus ?? state.ball;
  final attackers = [
    for (final p in state.attackers)
      p.copyWith(
          position: (p.position + p.velocity * seconds)
              .clampToField(minX: .04, maxX: .96, minY: .08, maxY: .92))
  ];
  final defenders = [
    for (final p in state.defenders)
      (() {
        final delta = ball - p.position;
        final distance = delta.distance;
        final response = distance > .001
            ? delta * (.035 / distance)
            : const ScanPassPoint(0, 0);
        // Preserve the observed press/drop intention; nearby markers adjust to
        // the ball after the learner's action rather than moving independently.
        final velocity = p.goalkeeper
            ? p.velocity
            : p.velocity.distance > .002
                ? (distance < .17
                    ? p.velocity * .8 + response * .2
                    : p.velocity)
                : distance < .24
                    ? response
                    : p.velocity;
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
