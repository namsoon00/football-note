import 'dart:math' as math;

import 'package:football_note/domain/scan_pass/scan_pass_attack.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart'
    show ScanPassPoint;

enum ScanPassPossessionVariant { pressure, cover }

enum ScanPassPossessionDecisionKind { firstTouch, nextAction, support }

enum ScanPassPossessionChoice {
  touchAway,
  turnForward,
  oneTouchLayoff,
  passTo8,
  passTo9,
  recycle4,
  supportInside,
  supportWide,
  supportBehind,
}

enum ScanPassPossessionOutcomeKind { chanceCreated, recycled, turnover }

enum ScanPassPossessionEvidence {
  pressureEscaped,
  pressureStayed,
  receiverConnected,
  receiverIsolated,
  supportConnected,
  chanceCreated,
  recycled,
  turnover,
}

enum ScanPassPossessionMoment { receive, touch, link, support, finish }

enum ScanPassPossessionSpotlightKind { pressure, support, futureSpace }

class ScanPassPossessionSpotlight {
  final ScanPassPossessionSpotlightKind kind;
  final int actorNumber;
  final bool opponent;
  final ScanPassPoint from;
  final ScanPassPoint to;
  final ScanPassPoint focus;

  const ScanPassPossessionSpotlight({
    required this.kind,
    required this.actorNumber,
    required this.opponent,
    required this.from,
    required this.to,
    required this.focus,
  });
}

class ScanPassPossessionScene {
  final ScanPassPossessionVariant variant;
  final AttackState initial;
  final AttackState reception;
  final List<ScanPassPossessionSpotlight> spotlights;

  ScanPassPossessionScene({
    required this.variant,
    required this.initial,
    required this.reception,
    required List<ScanPassPossessionSpotlight> spotlights,
  }) : spotlights = List.unmodifiable(spotlights);

  AttackTransition get observation => AttackTransition(
        before: initial,
        after: reception,
        action: const AttackAction.pass(6),
        duration: 1.35,
        ballEnd: reception.ball,
      );
}

class ScanPassPossessionDecisionPoint {
  final ScanPassPossessionScene scene;
  final ScanPassPossessionDecisionKind kind;
  final AttackState state;
  final int activeNumber;
  final List<ScanPassPossessionChoice> choices;
  final List<ScanPassPossessionChoice> decisions;
  final List<AttackTransition> history;

  ScanPassPossessionDecisionPoint({
    required this.scene,
    required this.kind,
    required this.state,
    required this.activeNumber,
    required List<ScanPassPossessionChoice> choices,
    required List<ScanPassPossessionChoice> decisions,
    required List<AttackTransition> history,
  })  : choices = List.unmodifiable(choices),
        decisions = List.unmodifiable(decisions),
        history = List.unmodifiable(history);

  ScanPassPossessionChoice? get firstTouch =>
      decisions.isEmpty ? null : decisions.first;

  ScanPassPossessionChoice? get nextAction =>
      decisions.length < 2 ? null : decisions[1];
}

class ScanPassPossessionStepResult {
  final ScanPassPossessionDecisionPoint point;
  final ScanPassPossessionChoice choice;
  final List<AttackTransition> transitions;
  final ScanPassPossessionDecisionPoint? nextPoint;
  final ScanPassPossessionBranch? branch;

  ScanPassPossessionStepResult({
    required this.point,
    required this.choice,
    required List<AttackTransition> transitions,
    this.nextPoint,
    this.branch,
  }) : transitions = List.unmodifiable(transitions);

  bool get terminal => branch != null;

  AttackState get after =>
      transitions.isEmpty ? point.state : transitions.last.after;
}

class ScanPassPossessionBranch {
  final ScanPassPossessionScene scene;
  final List<ScanPassPossessionChoice> decisions;
  final List<AttackTransition> transitions;
  final ScanPassPossessionOutcomeKind outcome;
  final List<ScanPassPossessionEvidence> evidence;
  final bool recommended;

  ScanPassPossessionBranch({
    required this.scene,
    required List<ScanPassPossessionChoice> decisions,
    required List<AttackTransition> transitions,
    required this.outcome,
    required List<ScanPassPossessionEvidence> evidence,
    this.recommended = false,
  })  : decisions = List.unmodifiable(decisions),
        transitions = List.unmodifiable(transitions),
        evidence = List.unmodifiable(evidence);

  AttackState get finalState =>
      transitions.isEmpty ? scene.reception : transitions.last.after;

  List<AttackTransition> get fullTransitions =>
      <AttackTransition>[scene.observation, ...transitions];

  ScanPassPossessionBranch copyWith({bool? recommended}) =>
      ScanPassPossessionBranch(
        scene: scene,
        decisions: decisions,
        transitions: transitions,
        outcome: outcome,
        evidence: evidence,
        recommended: recommended ?? this.recommended,
      );

  int? transitionIndexAt(ScanPassPossessionMoment moment) => switch (moment) {
        ScanPassPossessionMoment.receive => -1,
        ScanPassPossessionMoment.touch => transitions.isEmpty ? null : 0,
        ScanPassPossessionMoment.link =>
          _indexOf((t) => t.action.kind == AttackActionKind.pass),
        ScanPassPossessionMoment.support =>
          _indexOf((t) => t.action.kind == AttackActionKind.hold),
        ScanPassPossessionMoment.finish =>
          transitions.isEmpty ? null : transitions.length - 1,
      };

  int? _indexOf(bool Function(AttackTransition) predicate) {
    final i = transitions.indexWhere(predicate);
    return i < 0 ? null : i;
  }

  List<ScanPassPossessionMoment> get availableMoments => [
        for (final moment in ScanPassPossessionMoment.values)
          if (transitionIndexAt(moment) != null) moment,
      ];

  AttackState stateAt(ScanPassPossessionMoment moment) {
    final index = transitionIndexAt(moment);
    return index == null || index < 0
        ? scene.reception
        : transitions[index].after;
  }
}

class ScanPassPossessionLessonEngine {
  const ScanPassPossessionLessonEngine();

  ScanPassPossessionScene scene({
    ScanPassPossessionVariant variant = ScanPassPossessionVariant.pressure,
  }) {
    final initialAttackers = <AttackPlayer>[
      const AttackPlayer(
        number: 4,
        position: ScanPassPoint(.20, .58),
        facingRadians: -.10,
      ),
      const AttackPlayer(
        number: 6,
        position: ScanPassPoint(.39, .54),
        facingRadians: math.pi,
      ),
      const AttackPlayer(
        number: 8,
        position: ScanPassPoint(.54, .34),
        facingRadians: .26,
        velocity: ScanPassPoint(.030, .035),
      ),
      const AttackPlayer(
        number: 9,
        position: ScanPassPoint(.72, .49),
        facingRadians: .04,
        velocity: ScanPassPoint(.030, -.012),
      ),
    ];
    final initialDefenders = <AttackPlayer>[
      AttackPlayer(
        number: 2,
        opponent: true,
        position: const ScanPassPoint(.50, .40),
        facingRadians: math.pi,
        velocity: variant == ScanPassPossessionVariant.pressure
            ? const ScanPassPoint(-.042, .070)
            : const ScanPassPoint(.052, -.018),
      ),
      const AttackPlayer(
        number: 3,
        opponent: true,
        position: ScanPassPoint(.64, .31),
        facingRadians: math.pi,
        velocity: ScanPassPoint(-.018, .042),
      ),
      const AttackPlayer(
        number: 5,
        opponent: true,
        position: ScanPassPoint(.86, .64),
        facingRadians: math.pi,
        velocity: ScanPassPoint(-.018, -.018),
      ),
      const AttackPlayer(
        number: 1,
        opponent: true,
        goalkeeper: true,
        position: ScanPassPoint(.955, .50),
        facingRadians: math.pi,
      ),
    ];
    final initial = AttackState(
      attackers: initialAttackers,
      defenders: initialDefenders,
      ball: initialAttackers.first.position,
      carrierNumber: 4,
    );

    final pressureTo = variant == ScanPassPossessionVariant.pressure
        ? const ScanPassPoint(.445, .49)
        : const ScanPassPoint(.56, .38);
    final coverTo = variant == ScanPassPossessionVariant.pressure
        ? const ScanPassPoint(.65, .30)
        : const ScanPassPoint(.605, .365);
    final reception = AttackState(
      attackers: <AttackPlayer>[
        _moved(initialAttackers[0], const ScanPassPoint(.225, .575), 1.35),
        _moved(initialAttackers[1], const ScanPassPoint(.405, .54), 1.35),
        _moved(initialAttackers[2], const ScanPassPoint(.58, .385), 1.35),
        _moved(initialAttackers[3], const ScanPassPoint(.755, .475), 1.35),
      ],
      defenders: <AttackPlayer>[
        _moved(initialDefenders[0], pressureTo, 1.35),
        _moved(initialDefenders[1], coverTo, 1.35),
        _moved(initialDefenders[2], const ScanPassPoint(.84, .615), 1.35),
        initialDefenders[3],
      ],
      ball: const ScanPassPoint(.405, .54),
      carrierNumber: 6,
      elapsed: 1.35,
      completedPasses: 1,
      furthestX: .405,
      cue: AttackCue.received,
    );
    return ScanPassPossessionScene(
      variant: variant,
      initial: initial,
      reception: reception,
      spotlights: <ScanPassPossessionSpotlight>[
        ScanPassPossessionSpotlight(
          kind: ScanPassPossessionSpotlightKind.pressure,
          actorNumber: 2,
          opponent: true,
          from: initialDefenders[0].position,
          to: pressureTo,
          focus: pressureTo,
        ),
        ScanPassPossessionSpotlight(
          kind: ScanPassPossessionSpotlightKind.support,
          actorNumber: 8,
          opponent: false,
          from: initialAttackers[2].position,
          to: const ScanPassPoint(.58, .385),
          focus: const ScanPassPoint(.58, .385),
        ),
        ScanPassPossessionSpotlight(
          kind: ScanPassPossessionSpotlightKind.futureSpace,
          actorNumber: 6,
          opponent: false,
          from: reception.attackers
              .firstWhere((player) => player.number == 6)
              .position,
          to: variant == ScanPassPossessionVariant.pressure
              ? const ScanPassPoint(.64, .49)
              : const ScanPassPoint(.66, .36),
          focus: variant == ScanPassPossessionVariant.pressure
              ? const ScanPassPoint(.64, .49)
              : const ScanPassPoint(.66, .36),
        ),
      ],
    );
  }

  ScanPassPossessionDecisionPoint firstPhase(
    ScanPassPossessionScene scene,
  ) =>
      ScanPassPossessionDecisionPoint(
        scene: scene,
        kind: ScanPassPossessionDecisionKind.firstTouch,
        state: scene.reception,
        activeNumber: 6,
        choices: const <ScanPassPossessionChoice>[
          ScanPassPossessionChoice.touchAway,
          ScanPassPossessionChoice.turnForward,
          ScanPassPossessionChoice.oneTouchLayoff,
        ],
        decisions: const <ScanPassPossessionChoice>[],
        history: const <AttackTransition>[],
      );

  ScanPassPoint targetFor(
    ScanPassPossessionDecisionPoint point,
    ScanPassPossessionChoice choice,
  ) {
    final state = point.state;
    return switch (choice) {
      ScanPassPossessionChoice.touchAway => _touchAwayTarget(point.scene),
      ScanPassPossessionChoice.turnForward => _turnForwardTarget(point.scene),
      ScanPassPossessionChoice.oneTouchLayoff ||
      ScanPassPossessionChoice.recycle4 =>
        _attacker(state, 4).position,
      ScanPassPossessionChoice.passTo8 => _attacker(state, 8).position,
      ScanPassPossessionChoice.passTo9 => _attacker(state, 9).position,
      ScanPassPossessionChoice.supportInside =>
        _supportTarget(point.scene, ScanPassPossessionChoice.supportInside),
      ScanPassPossessionChoice.supportWide =>
        _supportTarget(point.scene, ScanPassPossessionChoice.supportWide),
      ScanPassPossessionChoice.supportBehind =>
        _supportTarget(point.scene, ScanPassPossessionChoice.supportBehind),
    };
  }

  ScanPassPossessionStepResult choose(
    ScanPassPossessionDecisionPoint point,
    ScanPassPossessionChoice choice,
  ) {
    if (!point.choices.contains(choice)) {
      throw ArgumentError.value(choice, 'choice', 'Choice is not available');
    }
    return switch (point.kind) {
      ScanPassPossessionDecisionKind.firstTouch =>
        _chooseFirstTouch(point, choice),
      ScanPassPossessionDecisionKind.nextAction =>
        _chooseNextAction(point, choice),
      ScanPassPossessionDecisionKind.support => _chooseSupport(point, choice),
    };
  }

  ScanPassPossessionChoice recommendedChoice(
    ScanPassPossessionDecisionPoint point,
  ) =>
      _bestBranchFrom(point).decisions[point.decisions.length];

  ScanPassPossessionBranch recommendedBranch(
    ScanPassPossessionScene scene,
  ) =>
      _bestBranchFrom(firstPhase(scene)).copyWith(recommended: true);

  ScanPassPossessionBranch _bestBranchFrom(
    ScanPassPossessionDecisionPoint point,
  ) {
    ScanPassPossessionBranch? best;
    for (final choice in point.choices) {
      final result = choose(point, choice);
      final branch = result.branch ?? _bestBranchFrom(result.nextPoint!);
      if (best == null || _branchValue(branch) > _branchValue(best)) {
        best = branch;
      }
    }
    return best!;
  }

  int _branchValue(ScanPassPossessionBranch branch) {
    final base = switch (branch.outcome) {
      ScanPassPossessionOutcomeKind.chanceCreated => 100,
      ScanPassPossessionOutcomeKind.recycled => 44,
      ScanPassPossessionOutcomeKind.turnover => 0,
    };
    return base +
        ((branch.transitions.first.after.ball.x -
                    branch.scene.reception.ball.x) *
                30)
            .round() +
        (branch.evidence.contains(ScanPassPossessionEvidence.pressureEscaped)
            ? 10
            : 0) +
        (branch.evidence.contains(ScanPassPossessionEvidence.receiverConnected)
            ? 8
            : 0) +
        (branch.evidence.contains(ScanPassPossessionEvidence.supportConnected)
            ? 8
            : 0) -
        (branch.evidence.contains(ScanPassPossessionEvidence.receiverIsolated)
            ? 12
            : 0);
  }

  ScanPassPossessionStepResult _chooseFirstTouch(
    ScanPassPossessionDecisionPoint point,
    ScanPassPossessionChoice choice,
  ) {
    final transition = choice == ScanPassPossessionChoice.oneTouchLayoff
        ? _passTransition(point.scene, point.state, 4, duration: .48)
        : _touchTransition(point.scene, point.state, targetFor(point, choice));
    if (transition.after.finished) return _ended(point, choice, [transition]);
    final layoff = choice == ScanPassPossessionChoice.oneTouchLayoff;
    return ScanPassPossessionStepResult(
      point: point,
      choice: choice,
      transitions: [transition],
      nextPoint: ScanPassPossessionDecisionPoint(
        scene: point.scene,
        kind: layoff
            ? ScanPassPossessionDecisionKind.support
            : ScanPassPossessionDecisionKind.nextAction,
        state: transition.after,
        activeNumber: 6,
        choices: layoff
            ? _supportChoices
            : const [
                ScanPassPossessionChoice.passTo8,
                ScanPassPossessionChoice.passTo9,
                ScanPassPossessionChoice.recycle4
              ],
        decisions: [...point.decisions, choice],
        history: [...point.history, transition],
      ),
    );
  }

  ScanPassPossessionStepResult _chooseNextAction(
    ScanPassPossessionDecisionPoint point,
    ScanPassPossessionChoice choice,
  ) {
    final receiver = switch (choice) {
      ScanPassPossessionChoice.passTo8 => 8,
      ScanPassPossessionChoice.passTo9 => 9,
      _ => 4,
    };
    final transition =
        _passTransition(point.scene, point.state, receiver, duration: .7);
    if (transition.after.finished || receiver == 4) {
      return _ended(point, choice, [transition]);
    }
    return ScanPassPossessionStepResult(
      point: point,
      choice: choice,
      transitions: [transition],
      nextPoint: ScanPassPossessionDecisionPoint(
        scene: point.scene,
        kind: ScanPassPossessionDecisionKind.support,
        state: transition.after,
        activeNumber: 6,
        choices: _supportChoices,
        decisions: [...point.decisions, choice],
        history: [...point.history, transition],
      ),
    );
  }

  ScanPassPossessionStepResult _chooseSupport(
    ScanPassPossessionDecisionPoint point,
    ScanPassPossessionChoice choice,
  ) {
    final transitions = <AttackTransition>[
      _supportRun(point.scene, point.state, choice)
    ];
    var state = transitions.last.after;
    if (state.finished) return _ended(point, choice, transitions);
    final back = _passTransition(point.scene, state, 6, duration: .5);
    // Teammates can refuse a blocked return and reset. The same geometry and
    // teammate policy apply to learner and coach continuations.
    if (back.after.finished) {
      final reset = _passTransition(point.scene, state, 4, duration: .7);
      transitions.add(reset.after.finished ? back : reset);
      return _ended(point, choice, transitions);
    }
    transitions.add(back);
    state = back.after;
    // Use the support position to find a forward receiver with a useful next
    // action. Evaluate real pass flights and shots, not choice-name recipes.
    List<AttackTransition>? best;
    var bestValue = -1e9;
    for (final number in [8, 9]) {
      final pass = _passTransition(point.scene, state, number, duration: .7);
      if (pass.after.finished || pass.after.ball.x < state.ball.x + .015) {
        continue;
      }
      final path = <AttackTransition>[pass];
      var receiving = pass.after;
      if (receiving.ball.x < .69) {
        final carry = _carryTransition(
            receiving, _field(receiving.ball + const ScanPassPoint(.10, 0)),
            duration: .8);
        path.add(carry);
        receiving = carry.after;
      }
      if (receiving.finished || receiving.ball.x < .66) continue;
      final shot = _shotTransition(point.scene, receiving);
      path.add(shot);
      final value = receiving.ball.x * 20 +
          _pressureGap(receiving) * 10 +
          (shot.after.end == AttackEnd.goal ? 2 : 0);
      if (value > bestValue) {
        bestValue = value;
        best = path;
      }
    }
    if (best != null) {
      transitions.addAll(best);
    } else {
      transitions.add(_passTransition(point.scene, state, 4, duration: .7));
    }
    return _ended(point, choice, transitions);
  }

  ScanPassPossessionStepResult _ended(ScanPassPossessionDecisionPoint point,
      ScanPassPossessionChoice choice, List<AttackTransition> transitions) {
    final all = [...point.history, ...transitions];
    final finalState = all.last.after;
    final hasShot = all.any((t) => t.action.kind == AttackActionKind.shoot);
    final outcome = hasShot
        ? ScanPassPossessionOutcomeKind.chanceCreated
        : finalState.finished
            ? ScanPassPossessionOutcomeKind.turnover
            : ScanPassPossessionOutcomeKind.recycled;
    final first = all.first;
    final escaped = !first.after.finished && _pressureGap(first.after) > .075;
    final evidence = <ScanPassPossessionEvidence>[
      escaped
          ? ScanPassPossessionEvidence.pressureEscaped
          : ScanPassPossessionEvidence.pressureStayed,
    ];
    final receivingPasses = all
        .where((t) =>
            t.action.kind == AttackActionKind.pass &&
            t.action.targetNumber != 4)
        .toList();
    if (receivingPasses.isNotEmpty) {
      final reception = receivingPasses.first.after;
      final options = availableConnections(point.scene, reception);
      evidence.add(!reception.finished && options.isNotEmpty
          ? ScanPassPossessionEvidence.receiverConnected
          : ScanPassPossessionEvidence.receiverIsolated);
    }
    final runIndex =
        all.indexWhere((t) => t.action.kind == AttackActionKind.hold);
    if (runIndex >= 0 &&
        all.skip(runIndex + 1).any((t) =>
            t.action.kind == AttackActionKind.pass &&
            t.action.targetNumber == 6 &&
            !t.after.finished)) {
      evidence.add(ScanPassPossessionEvidence.supportConnected);
    }
    evidence.add(switch (outcome) {
      ScanPassPossessionOutcomeKind.chanceCreated =>
        ScanPassPossessionEvidence.chanceCreated,
      ScanPassPossessionOutcomeKind.turnover =>
        ScanPassPossessionEvidence.turnover,
      ScanPassPossessionOutcomeKind.recycled =>
        ScanPassPossessionEvidence.recycled,
    });
    return ScanPassPossessionStepResult(
        point: point,
        choice: choice,
        transitions: transitions,
        branch: _branch(point, choice, transitions, outcome, evidence));
  }

  List<int> availableConnections(
          ScanPassPossessionScene scene, AttackState state) =>
      state.finished
          ? []
          : [
              for (final player in state.attackers)
                if (player.number != state.carrierNumber &&
                    !_passTransition(scene, state, player.number, duration: .6)
                        .after
                        .finished)
                  player.number,
            ];

  double _pressureGap(AttackState state) => state.defenders
      .where((p) => !p.goalkeeper)
      .map((p) => p.position.distanceTo(state.ball))
      .reduce(math.min);

  ScanPassPossessionBranch _branch(
    ScanPassPossessionDecisionPoint point,
    ScanPassPossessionChoice choice,
    List<AttackTransition> newTransitions,
    ScanPassPossessionOutcomeKind outcome,
    List<ScanPassPossessionEvidence> evidence,
  ) =>
      ScanPassPossessionBranch(
        scene: point.scene,
        decisions: <ScanPassPossessionChoice>[...point.decisions, choice],
        transitions: <AttackTransition>[...point.history, ...newTransitions],
        outcome: outcome,
        evidence: evidence,
      );

  static const List<ScanPassPossessionChoice> _supportChoices =
      <ScanPassPossessionChoice>[
    ScanPassPossessionChoice.supportInside,
    ScanPassPossessionChoice.supportWide,
    ScanPassPossessionChoice.supportBehind,
  ];

  AttackTransition _touchTransition(ScanPassPossessionScene scene,
          AttackState before, ScanPassPoint target) =>
      _carryTransition(before, target, duration: .72);

  AttackTransition _carryTransition(AttackState before, ScanPassPoint target,
      {required double duration}) {
    final attackers = _attackingTargets(before, duration);
    attackers[before.carrierNumber] = target;
    return _resolve(
        before,
        const AttackAction.carry(AttackCarryDirection.forward),
        duration,
        attackers,
        _defendingTargets(before, duration, pressTarget: target),
        target,
        before.carrierNumber);
  }

  AttackTransition _passTransition(
      ScanPassPossessionScene scene, AttackState before, int targetNumber,
      {required double duration}) {
    // Flight duration and arrival are derived together from the receiver's run.
    var flight =
        before.ball.distanceTo(_attacker(before, targetNumber).position) / .52;
    var targets = _attackingTargets(before, flight);
    for (var i = 0; i < 3; i++) {
      flight = (before.ball.distanceTo(targets[targetNumber]!) / .52)
          .clamp(.28, 1.65);
      targets = _attackingTargets(before, flight);
    }
    return _resolve(
        before,
        AttackAction.pass(targetNumber),
        flight,
        targets,
        _defendingTargets(before, flight),
        targets[targetNumber]!,
        targetNumber);
  }

  AttackTransition _supportRun(ScanPassPossessionScene scene,
      AttackState before, ScanPassPossessionChoice support) {
    final target = _supportTarget(scene, support);
    final duration = (_attacker(before, 6).position.distanceTo(target) / .19)
        .clamp(.45, 1.5)
        .toDouble();
    final targets = _attackingTargets(before, duration);
    targets[6] = target;
    // The ball follows its carrier while the learner moves without it.
    return _resolve(
        before,
        const AttackAction.hold(),
        duration,
        targets,
        _defendingTargets(before, duration),
        targets[before.carrierNumber]!,
        before.carrierNumber);
  }

  AttackTransition _shotTransition(
      ScanPassPossessionScene scene, AttackState before) {
    final keeper = _defender(before, 1);
    final y = keeper.position.y <= .50 ? .585 : .415;
    final target = ScanPassPoint(1.025, y);
    final duration =
        (before.ball.distanceTo(target) / .85).clamp(.25, .65).toDouble();
    return _resolve(
        before,
        AttackAction.shoot(
            y > .5 ? AttackShotTarget.lower : AttackShotTarget.upper),
        duration,
        _attackingTargets(before, duration),
        _defendingTargets(before, duration, shotTarget: target),
        target,
        before.carrierNumber);
  }

  Map<int, ScanPassPoint> _attackingTargets(
      AttackState before, double duration) {
    final line = const AttackEngine().offsideLine(before);
    return {
      for (final player in before.attackers)
        player.number: player.number == 6
            ? player.position
            : player.number == 4
                ? _field(player.position + ScanPassPoint(.008 * duration, 0))
                : _field(ScanPassPoint(
                    math.min(player.position.x + .035 * duration,
                        math.max(player.position.x, line - .025)),
                    player.position.y +
                        (player.number == 8 ? .008 : -.004) * duration)),
    };
  }

  Map<int, ScanPassPoint> _defendingTargets(AttackState before, double duration,
      {ScanPassPoint? shotTarget, ScanPassPoint? pressTarget}) {
    final nearest = before.defenders.where((p) => !p.goalkeeper).reduce((a,
            b) =>
        a.position.distanceTo(before.ball) < b.position.distanceTo(before.ball)
            ? a
            : b);
    return {
      for (final p in before.defenders)
        p.number: p.goalkeeper
            ? _toward(
                p.position,
                ScanPassPoint(
                    .955, shotTarget?.y ?? (.5 + (before.ball.y - .5) * .3)),
                .095 * duration)
            : p.number == nearest.number
                ? _toward(p.position, pressTarget ?? before.ball,
                    (pressTarget == null ? .034 : .065) * duration)
                : _toward(
                    p.position,
                    p.number == 5
                        ? ScanPassPoint(_attacker(before, 9).position.x + .035,
                            _attacker(before, 9).position.y)
                        : p.number == 3
                            ? ScanPassPoint(
                                _attacker(before, 8).position.x + .035,
                                _attacker(before, 8).position.y)
                            : ScanPassPoint(
                                before.ball.x + .055, before.ball.y),
                    .022 * duration),
    };
  }

  AttackTransition _resolve(
      AttackState before,
      AttackAction action,
      double duration,
      Map<int, ScanPassPoint> attackers,
      Map<int, ScanPassPoint> defenders,
      ScanPassPoint destination,
      int receiver) {
    final offside = action.kind == AttackActionKind.pass
        ? const AttackEngine().checkOffside(before, receiver)
        : null;
    var fraction = 1.0;
    int? interceptor;
    for (var i = 1; i <= 80; i++) {
      final t = i / 80;
      final ball = before.ball.lerp(destination, t);
      for (final d in before.defenders) {
        if (d.goalkeeper && action.kind != AttackActionKind.shoot) continue;
        final pos = d.position.lerp(defenders[d.number] ?? d.position, t);
        final radius = d.goalkeeper
            ? .040
            : (action.kind == AttackActionKind.hold ? .020 : .022);
        if (ball.distanceTo(pos) <= radius) {
          fraction = t;
          interceptor = d.number;
          break;
        }
      }
      if (interceptor != null) break;
    }
    if (interceptor == null && offside?.offside == true) {
      return AttackTransition(
          before: before,
          after: before.copyWith(
              end: AttackEnd.offside,
              cue: AttackCue.offside,
              actionCount: before.actionCount + 1),
          action: action,
          duration: 0,
          ballEnd: before.ball,
          offside: offside);
    }
    final end = interceptor != null
        ? (action.kind == AttackActionKind.shoot
            ? interceptor == 1
                ? AttackEnd.saved
                : AttackEnd.blocked
            : AttackEnd.intercepted)
        : action.kind == AttackActionKind.shoot
            ? AttackEnd.goal
            : null;
    final elapsed = duration * fraction;
    final finalBall = before.ball.lerp(destination, fraction);
    final after = _stateAfterMovement(before,
        duration: elapsed,
        attackerTargets: {
          for (final p in before.attackers)
            p.number:
                p.position.lerp(attackers[p.number] ?? p.position, fraction)
        },
        defenderTargets: {
          for (final p in before.defenders)
            p.number:
                p.position.lerp(defenders[p.number] ?? p.position, fraction)
        },
        ball: finalBall,
        carrierNumber: interceptor == null ? receiver : before.carrierNumber,
        completedPasses: before.completedPasses +
            (action.kind == AttackActionKind.pass && end == null ? 1 : 0),
        cue: switch (end) {
          AttackEnd.intercepted => AttackCue.intercepted,
          AttackEnd.saved => AttackCue.saved,
          AttackEnd.blocked => AttackCue.blocked,
          AttackEnd.goal => AttackCue.goal,
          _ => action.kind == AttackActionKind.pass
              ? AttackCue.received
              : AttackCue.carried
        },
        end: end);
    return AttackTransition(
        before: before,
        after: after,
        action: action,
        duration: elapsed,
        ballEnd: finalBall,
        offside: offside,
        interceptorNumber: interceptor);
  }

  AttackState _stateAfterMovement(
    AttackState before, {
    required double duration,
    required Map<int, ScanPassPoint> attackerTargets,
    required Map<int, ScanPassPoint> defenderTargets,
    required ScanPassPoint ball,
    required int carrierNumber,
    required AttackCue cue,
    int? completedPasses,
    AttackEnd? end,
  }) {
    final attackers = <AttackPlayer>[
      for (final player in before.attackers)
        _moved(player, attackerTargets[player.number] ?? player.position,
            duration),
    ];
    final defenders = <AttackPlayer>[
      for (final player in before.defenders)
        _moved(player, defenderTargets[player.number] ?? player.position,
            duration),
    ];
    return before.copyWith(
      attackers: attackers,
      defenders: defenders,
      ball: ball,
      carrierNumber: carrierNumber,
      elapsed: before.elapsed + duration,
      actionCount: before.actionCount + 1,
      completedPasses: completedPasses ?? before.completedPasses,
      furthestX: math.max(before.furthestX, ball.x),
      end: end,
      cue: cue,
    );
  }

  ScanPassPoint _touchAwayTarget(ScanPassPossessionScene scene) =>
      _field(scene.reception.ball + const ScanPassPoint(.057, .075));

  ScanPassPoint _turnForwardTarget(ScanPassPossessionScene scene) =>
      _field(scene.reception.ball + const ScanPassPoint(.10, -.035));

  ScanPassPoint _supportTarget(
          ScanPassPossessionScene scene, ScanPassPossessionChoice support) =>
      switch (support) {
        ScanPassPossessionChoice.supportInside =>
          const ScanPassPoint(.642, .488),
        ScanPassPossessionChoice.supportWide => const ScanPassPoint(.662, .350),
        ScanPassPossessionChoice.supportBehind =>
          const ScanPassPoint(.505, .610),
        _ => throw StateError('Not a support choice: $support'),
      };

  static AttackPlayer _attacker(AttackState state, int number) =>
      state.attackers.firstWhere((player) => player.number == number);

  static AttackPlayer _defender(AttackState state, int number) =>
      state.defenders.firstWhere((player) => player.number == number);

  static AttackPlayer _moved(
    AttackPlayer player,
    ScanPassPoint target,
    double seconds,
  ) {
    final safe = _field(target);
    final delta = safe - player.position;
    return player.copyWith(
      position: safe,
      velocity: delta * (seconds <= 0 ? 0 : 1 / seconds),
      facingRadians: delta.distance < .0001
          ? player.facingRadians
          : math.atan2(delta.y, delta.x),
    );
  }

  static ScanPassPoint _toward(
    ScanPassPoint from,
    ScanPassPoint to,
    double distance,
  ) {
    final delta = to - from;
    if (delta.distance <= distance || delta.distance < .00001) {
      return _field(to);
    }
    return _field(from + delta * (distance / delta.distance));
  }

  static ScanPassPoint _field(ScanPassPoint point) =>
      point.clampToField(minX: .055, maxX: 1.025, minY: .08, maxY: .92);
}
