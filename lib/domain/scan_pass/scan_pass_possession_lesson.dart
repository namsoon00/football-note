import 'dart:math' as math;

import 'package:football_note/domain/scan_pass/scan_pass_attack.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart'
    show ScanPassPoint;

enum ScanPassPossessionVariant { pressure, cover }

enum ScanPassPossessionSituation {
  centralReceive,
  halfSpace,
  touchline,
  layoff,
  thirdPlayer,
  transition
}

class ScanPassPossessionScenario {
  final String id;
  final ScanPassPossessionSituation situation;
  final ScanPassPossessionVariant variant;
  const ScanPassPossessionScenario(this.id, this.situation, this.variant);
}

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
  supportHold,
  supportCustom,
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
  final ScanPassPossessionSituation situation;
  final AttackState initial;
  final AttackState reception;
  final List<ScanPassPossessionSpotlight> spotlights;

  ScanPassPossessionScene({
    required this.variant,
    this.situation = ScanPassPossessionSituation.centralReceive,
    required this.initial,
    required this.reception,
    required List<ScanPassPossessionSpotlight> spotlights,
  }) : spotlights = List.unmodifiable(spotlights);

  AttackTransition get observation => AttackTransition(
        before: initial,
        after: reception,
        action: const AttackAction.pass(6),
        duration: reception.elapsed - initial.elapsed,
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
  final List<ScanPassPoint?> decisionTargets;
  final List<AttackTransition> history;

  ScanPassPossessionDecisionPoint({
    required this.scene,
    required this.kind,
    required this.state,
    required this.activeNumber,
    required List<ScanPassPossessionChoice> choices,
    required List<ScanPassPossessionChoice> decisions,
    List<ScanPassPoint?> decisionTargets = const <ScanPassPoint?>[],
    required List<AttackTransition> history,
  })  : choices = List.unmodifiable(choices),
        decisions = List.unmodifiable(decisions),
        decisionTargets = List.unmodifiable(decisionTargets),
        history = List.unmodifiable(history);

  ScanPassPossessionChoice? get firstTouch =>
      decisions.isEmpty ? null : decisions.first;

  ScanPassPossessionChoice? get nextAction =>
      decisions.length < 2 ? null : decisions[1];
}

class ScanPassPossessionStepResult {
  final ScanPassPossessionDecisionPoint point;
  final ScanPassPossessionChoice choice;
  final ScanPassPoint? decisionTarget;
  final List<AttackTransition> transitions;
  final ScanPassPossessionDecisionPoint? nextPoint;
  final ScanPassPossessionBranch? branch;

  ScanPassPossessionStepResult({
    required this.point,
    required this.choice,
    this.decisionTarget,
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
  final List<ScanPassPoint?> decisionTargets;
  final List<AttackTransition> transitions;
  final ScanPassPossessionOutcomeKind outcome;
  final List<ScanPassPossessionEvidence> evidence;
  final bool recommended;

  ScanPassPossessionBranch({
    required this.scene,
    required List<ScanPassPossessionChoice> decisions,
    List<ScanPassPoint?> decisionTargets = const <ScanPassPoint?>[],
    required List<AttackTransition> transitions,
    required this.outcome,
    required List<ScanPassPossessionEvidence> evidence,
    this.recommended = false,
  })  : decisions = List.unmodifiable(decisions),
        decisionTargets = List.unmodifiable(decisionTargets),
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
        decisionTargets: decisionTargets,
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

class _PossessionContinuation {
  final List<AttackTransition> transitions;
  final bool returnedToLearner;

  _PossessionContinuation({
    required List<AttackTransition> transitions,
    this.returnedToLearner = false,
  }) : transitions = List.unmodifiable(transitions);
}

class _PossessionContinuationCandidate {
  final List<AttackTransition> transitions;
  final double value;
  final bool returnedToLearner;

  _PossessionContinuationCandidate({
    required List<AttackTransition> transitions,
    required this.value,
    this.returnedToLearner = false,
  }) : transitions = List.unmodifiable(transitions);
}

class ScanPassPossessionLessonEngine {
  const ScanPassPossessionLessonEngine();

  static const double pitchLengthMetres = 105;
  static const double pitchWidthMetres = 68;
  static const int _maxLearnerDecisions = 5;
  static double distanceMetres(ScanPassPoint a, ScanPassPoint b) =>
      _metres(b - a).distance;
  static ScanPassPoint _metres(ScanPassPoint p) =>
      ScanPassPoint(p.x * pitchLengthMetres, p.y * pitchWidthMetres);
  static ScanPassPoint _normalized(ScanPassPoint p) =>
      ScanPassPoint(p.x / pitchLengthMetres, p.y / pitchWidthMetres);

  static const catalog = <ScanPassPossessionScenario>[
    ScanPassPossessionScenario(
        'centralReceive-pressure',
        ScanPassPossessionSituation.centralReceive,
        ScanPassPossessionVariant.pressure),
    ScanPassPossessionScenario(
        'centralReceive-cover',
        ScanPassPossessionSituation.centralReceive,
        ScanPassPossessionVariant.cover),
    ScanPassPossessionScenario(
        'halfSpace-pressure',
        ScanPassPossessionSituation.halfSpace,
        ScanPassPossessionVariant.pressure),
    ScanPassPossessionScenario('halfSpace-cover',
        ScanPassPossessionSituation.halfSpace, ScanPassPossessionVariant.cover),
    ScanPassPossessionScenario(
        'touchline-pressure',
        ScanPassPossessionSituation.touchline,
        ScanPassPossessionVariant.pressure),
    ScanPassPossessionScenario('touchline-cover',
        ScanPassPossessionSituation.touchline, ScanPassPossessionVariant.cover),
    ScanPassPossessionScenario('layoff-pressure',
        ScanPassPossessionSituation.layoff, ScanPassPossessionVariant.pressure),
    ScanPassPossessionScenario('layoff-cover',
        ScanPassPossessionSituation.layoff, ScanPassPossessionVariant.cover),
    ScanPassPossessionScenario(
        'thirdPlayer-pressure',
        ScanPassPossessionSituation.thirdPlayer,
        ScanPassPossessionVariant.pressure),
    ScanPassPossessionScenario(
        'thirdPlayer-cover',
        ScanPassPossessionSituation.thirdPlayer,
        ScanPassPossessionVariant.cover),
    ScanPassPossessionScenario(
        'transition-pressure',
        ScanPassPossessionSituation.transition,
        ScanPassPossessionVariant.pressure),
    ScanPassPossessionScenario(
        'transition-cover',
        ScanPassPossessionSituation.transition,
        ScanPassPossessionVariant.cover),
  ];

  ScanPassPossessionScene scene({
    ScanPassPossessionVariant variant = ScanPassPossessionVariant.pressure,
    ScanPassPossessionSituation situation =
        ScanPassPossessionSituation.centralReceive,
  }) {
    // Six spatial problems, each with the same initial attacking shape in its
    // two defensive variations. Geometry, not the name, drives later policy.
    final (origin, supportOffset, strikerOffset) = switch (situation) {
      ScanPassPossessionSituation.centralReceive => (
          const ScanPassPoint(.43, .55),
          const ScanPassPoint(.16, -.16),
          const ScanPassPoint(.32, -.02)
        ),
      ScanPassPossessionSituation.halfSpace => (
          const ScanPassPoint(.55, .32),
          const ScanPassPoint(.14, .16),
          const ScanPassPoint(.24, -.05)
        ),
      ScanPassPossessionSituation.touchline => (
          const ScanPassPoint(.48, .82),
          const ScanPassPoint(.15, -.23),
          const ScanPassPoint(.31, -.30)
        ),
      ScanPassPossessionSituation.layoff => (
          const ScanPassPoint(.58, .48),
          const ScanPassPoint(.09, .22),
          const ScanPassPoint(.21, -.13)
        ),
      ScanPassPossessionSituation.thirdPlayer => (
          const ScanPassPoint(.60, .65),
          const ScanPassPoint(.10, -.17),
          const ScanPassPoint(.20, .06)
        ),
      ScanPassPossessionSituation.transition => (
          const ScanPassPoint(.56, .47),
          const ScanPassPoint(.19, -.22),
          const ScanPassPoint(.28, .16)
        ),
    };
    final side = supportOffset.y < 0 ? -1.0 : 1.0;
    final a8 = _field(origin + supportOffset);
    final a9 = _field(origin + strikerOffset);
    final a4 = _field(origin + ScanPassPoint(-.17, -side * .045));
    final d2 = variant == ScanPassPossessionVariant.pressure
        ? origin + _normalized(ScanPassPoint(2.7, side * 1.5))
        : origin + _normalized(ScanPassPoint(8.0, side * 6.0));
    final d3 = variant == ScanPassPossessionVariant.pressure
        ? a8 + _normalized(ScanPassPoint(4.8, side * 4.5))
        : origin.lerp(a8, .70) + _normalized(const ScanPassPoint(1.0, 0));
    final d5 = a9 + _normalized(ScanPassPoint(5.0, -side * 4.5));
    AttackPlayer player(int n, ScanPassPoint pos,
            {bool opponent = false, bool keeper = false}) =>
        AttackPlayer(
            number: n,
            position: _field(pos),
            opponent: opponent,
            goalkeeper: keeper,
            facingRadians: opponent ? math.pi : 0);
    final receptionAttackers = [
      player(4, a4),
      player(6, origin),
      player(8, a8),
      player(9, a9)
    ];
    final receptionDefenders = [
      player(2, d2, opponent: true),
      player(3, d3, opponent: true),
      player(5, d5, opponent: true),
      player(1, const ScanPassPoint(.965, .5), opponent: true, keeper: true)
    ];
    final initialAttackers = [
      for (final p in receptionAttackers)
        p.copyWith(
            position: p.number == 6
                ? _field(p.position - _normalized(const ScanPassPoint(1.0, 0)))
                : p.number == 8
                    ? _field(
                        p.position + _normalized(ScanPassPoint(2, -side * 1.5)))
                    : p.number == 9
                        ? _field(
                            p.position - _normalized(ScanPassPoint(2.0, side)))
                        : p.position)
    ];
    final initialDefenders = [
      for (final p in receptionDefenders)
        p.copyWith(
            position: p.number == 2
                ? _field(p.position +
                    _normalized(ScanPassPoint(
                        variant == ScanPassPossessionVariant.pressure
                            ? 3.0
                            : -2.0,
                        -side)))
                : p.number == 3
                    ? _field(p.position +
                        _normalized(ScanPassPoint(1.5, side * 1.5)))
                    : p.position)
    ];
    final duration =
        distanceMetres(initialAttackers.first.position, origin) / 19;
    final initial = AttackState(
        attackers: initialAttackers,
        defenders: initialDefenders,
        ball: initialAttackers.first.position,
        carrierNumber: 4);
    final reception = AttackState(
        attackers: [
          for (var i = 0; i < 4; i++)
            _moved(
                initialAttackers[i], receptionAttackers[i].position, duration)
        ],
        defenders: [
          for (var i = 0; i < 4; i++)
            _moved(
                initialDefenders[i], receptionDefenders[i].position, duration)
        ],
        ball: origin,
        carrierNumber: 6,
        elapsed: duration,
        completedPasses: 1,
        furthestX: origin.x,
        cue: AttackCue.received);
    return ScanPassPossessionScene(
        variant: variant,
        situation: situation,
        initial: initial,
        reception: reception,
        spotlights: [
          ScanPassPossessionSpotlight(
              kind: ScanPassPossessionSpotlightKind.pressure,
              actorNumber: 2,
              opponent: true,
              from: initialDefenders[0].position,
              to: d2,
              focus: d2),
          ScanPassPossessionSpotlight(
              kind: ScanPassPossessionSpotlightKind.support,
              actorNumber: 8,
              opponent: false,
              from: initialAttackers[2].position,
              to: a8,
              focus: a8),
          ScanPassPossessionSpotlight(
              kind: ScanPassPossessionSpotlightKind.futureSpace,
              actorNumber: 6,
              opponent: false,
              from: origin,
              to: _field(origin + _normalized(ScanPassPoint(7, -side * 4))),
              focus: _field(origin + _normalized(ScanPassPoint(7, -side * 4))))
        ]);
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
        decisionTargets: const <ScanPassPoint?>[],
        history: const <AttackTransition>[],
      );

  ScanPassPoint boundedSupportTarget(ScanPassPoint target) => _field(target);

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
        _passTarget(state, 4),
      ScanPassPossessionChoice.passTo8 => _passTarget(state, 8),
      ScanPassPossessionChoice.passTo9 => _passTarget(state, 9),
      ScanPassPossessionChoice.supportInside =>
        _supportTarget(point.state, ScanPassPossessionChoice.supportInside),
      ScanPassPossessionChoice.supportWide =>
        _supportTarget(point.state, ScanPassPossessionChoice.supportWide),
      ScanPassPossessionChoice.supportBehind =>
        _supportTarget(point.state, ScanPassPossessionChoice.supportBehind),
      ScanPassPossessionChoice.supportHold ||
      ScanPassPossessionChoice.supportCustom =>
        _attacker(state, 6).position,
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

  ScanPassPossessionStepResult chooseSupportTarget(
    ScanPassPossessionDecisionPoint point,
    ScanPassPoint target,
  ) {
    if (point.kind != ScanPassPossessionDecisionKind.support) {
      throw ArgumentError.value(point.kind, 'kind', 'Support point expected');
    }
    return _chooseSupport(
      point,
      ScanPassPossessionChoice.supportCustom,
      target: boundedSupportTarget(target),
    );
  }

  ScanPassPossessionStepResult chooseSupportHold(
    ScanPassPossessionDecisionPoint point,
  ) {
    if (point.kind != ScanPassPossessionDecisionKind.support) {
      throw ArgumentError.value(point.kind, 'kind', 'Support point expected');
    }
    return _chooseSupport(
      point,
      ScanPassPossessionChoice.supportHold,
      target: _attacker(point.state, 6).position,
    );
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
    final target = targetFor(point, choice);
    final transition = choice == ScanPassPossessionChoice.oneTouchLayoff
        ? _passTransition(point.scene, point.state, 4, duration: .48)
        : _touchTransition(point.scene, point.state, target);
    if (transition.after.finished) {
      return _ended(point, choice, [transition], decisionTarget: target);
    }
    final layoff = choice == ScanPassPossessionChoice.oneTouchLayoff;
    return ScanPassPossessionStepResult(
      point: point,
      choice: choice,
      decisionTarget: target,
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
        decisionTargets: [...point.decisionTargets, target],
        history: [...point.history, transition],
      ),
    );
  }

  ScanPassPossessionStepResult _chooseNextAction(
    ScanPassPossessionDecisionPoint point,
    ScanPassPossessionChoice choice,
  ) {
    final target = targetFor(point, choice);
    final receiver = switch (choice) {
      ScanPassPossessionChoice.passTo8 => 8,
      ScanPassPossessionChoice.passTo9 => 9,
      _ => 4,
    };
    final transition =
        _passTransition(point.scene, point.state, receiver, duration: .7);
    if (transition.after.finished || receiver == 4) {
      return _ended(point, choice, [transition], decisionTarget: target);
    }
    if (point.decisions.length + 1 >= _maxLearnerDecisions) {
      return _ended(
        point,
        choice,
        [transition, ..._automaticFinish(point.scene, transition.after)],
        decisionTarget: target,
      );
    }
    return ScanPassPossessionStepResult(
      point: point,
      choice: choice,
      decisionTarget: target,
      transitions: [transition],
      nextPoint: ScanPassPossessionDecisionPoint(
        scene: point.scene,
        kind: ScanPassPossessionDecisionKind.support,
        state: transition.after,
        activeNumber: 6,
        choices: _supportChoices,
        decisions: [...point.decisions, choice],
        decisionTargets: [...point.decisionTargets, target],
        history: [...point.history, transition],
      ),
    );
  }

  ScanPassPossessionStepResult _chooseSupport(
      ScanPassPossessionDecisionPoint point, ScanPassPossessionChoice choice,
      {ScanPassPoint? target}) {
    final decisionTarget = target ?? targetFor(point, choice);
    final transitions = <AttackTransition>[
      _supportRun(point.scene, point.state, decisionTarget)
    ];
    var state = transitions.last.after;
    if (state.finished) {
      return _ended(point, choice, transitions, decisionTarget: decisionTarget);
    }
    final continuation = _teammateContinuation(
      point.scene,
      state,
      allowReturn: point.decisions.length + 1 < _maxLearnerDecisions,
    );
    transitions.addAll(continuation.transitions);
    state = transitions.last.after;
    if (continuation.returnedToLearner &&
        !state.finished &&
        point.decisions.length + 1 < _maxLearnerDecisions) {
      return ScanPassPossessionStepResult(
        point: point,
        choice: choice,
        decisionTarget: decisionTarget,
        transitions: transitions,
        nextPoint: ScanPassPossessionDecisionPoint(
          scene: point.scene,
          kind: ScanPassPossessionDecisionKind.nextAction,
          state: state,
          activeNumber: 6,
          choices: const [
            ScanPassPossessionChoice.passTo8,
            ScanPassPossessionChoice.passTo9,
            ScanPassPossessionChoice.recycle4
          ],
          decisions: [...point.decisions, choice],
          decisionTargets: [...point.decisionTargets, decisionTarget],
          history: [...point.history, ...transitions],
        ),
      );
    }
    return _ended(point, choice, transitions, decisionTarget: decisionTarget);
  }

  ScanPassPossessionStepResult _ended(
    ScanPassPossessionDecisionPoint point,
    ScanPassPossessionChoice choice,
    List<AttackTransition> transitions, {
    ScanPassPoint? decisionTarget,
  }) {
    final all = [...point.history, ...transitions];
    final finalState = all.last.after;
    final hasShot = all.any((t) => t.action.kind == AttackActionKind.shoot);
    final outcome = hasShot
        ? ScanPassPossessionOutcomeKind.chanceCreated
        : finalState.finished
            ? ScanPassPossessionOutcomeKind.turnover
            : ScanPassPossessionOutcomeKind.recycled;
    final first = all.first;
    final escaped = !first.after.finished && _pressureGap(first.after) > 3.0;
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
        all.skip(runIndex + 1).any((t) {
          if (t.after.finished) return false;
          if (t.action.kind == AttackActionKind.pass) {
            return t.action.targetNumber == 6 || t.action.targetNumber != 4;
          }
          return t.action.kind == AttackActionKind.carry ||
              t.action.kind == AttackActionKind.shoot;
        })) {
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
        decisionTarget: decisionTarget,
        transitions: transitions,
        branch: _branch(point, choice, transitions, outcome, evidence,
            decisionTarget: decisionTarget));
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
      .map((p) => distanceMetres(p.position, state.ball))
      .reduce(math.min);

  List<AttackTransition> _automaticFinish(
    ScanPassPossessionScene scene,
    AttackState state,
  ) =>
      _teammateContinuation(scene, state, allowReturn: false).transitions;

  _PossessionContinuation _teammateContinuation(
    ScanPassPossessionScene scene,
    AttackState state, {
    required bool allowReturn,
  }) {
    if (state.finished) {
      return _PossessionContinuation(transitions: const <AttackTransition>[]);
    }
    final candidates = <_PossessionContinuationCandidate>[];

    for (final number in const [8, 9]) {
      if (number == state.carrierNumber) continue;
      final pass = _passTransition(scene, state, number, duration: .7);
      if (pass.after.finished || pass.after.ball.x < state.ball.x + .012) {
        continue;
      }
      final path = <AttackTransition>[pass];
      path.addAll(_finishAdvantage(scene, pass.after));
      candidates.add(_PossessionContinuationCandidate(
        transitions: path,
        value: _candidateValue(scene, path, base: 88),
      ));
    }

    final carry = _carryTransition(
      state,
      _field(state.ball + const ScanPassPoint(.052, 0)),
      duration: .8,
    );
    if (!carry.after.finished && carry.after.ball.x > state.ball.x + .018) {
      final path = <AttackTransition>[carry];
      path.addAll(_finishAdvantage(scene, carry.after));
      candidates.add(_PossessionContinuationCandidate(
        transitions: path,
        value: _candidateValue(scene, path, base: 76),
      ));
    }

    if (allowReturn && state.carrierNumber != 6) {
      final back = _passTransition(scene, state, 6, duration: .5);
      if (!back.after.finished && _returnIsUseful(scene, state, back.after)) {
        candidates.add(_PossessionContinuationCandidate(
          transitions: <AttackTransition>[back],
          value: _candidateValue(scene, <AttackTransition>[back], base: 58),
          returnedToLearner: true,
        ));
      }
    }

    final reset = _passTransition(scene, state, 4, duration: .7);
    candidates.add(_PossessionContinuationCandidate(
      transitions: <AttackTransition>[reset],
      value: reset.after.finished
          ? -20
          : _candidateValue(scene, <AttackTransition>[reset], base: 34),
    ));

    candidates.sort((a, b) => b.value.compareTo(a.value));
    final best = candidates.first;
    return _PossessionContinuation(
      transitions: best.transitions,
      returnedToLearner: best.returnedToLearner,
    );
  }

  List<AttackTransition> _finishAdvantage(
    ScanPassPossessionScene scene,
    AttackState state,
  ) {
    if (state.finished) return const <AttackTransition>[];
    final path = <AttackTransition>[];
    var current = state;
    if (current.ball.x < .69) {
      final carry = _carryTransition(
        current,
        _field(current.ball + const ScanPassPoint(.045, 0)),
        duration: .8,
      );
      path.add(carry);
      current = carry.after;
    }
    if (!current.finished && current.ball.x >= .66) {
      path.add(_shotTransition(scene, current));
    }
    return path;
  }

  double _candidateValue(
    ScanPassPossessionScene scene,
    List<AttackTransition> path, {
    required double base,
  }) {
    if (path.isEmpty) return base;
    final state = path.last.after;
    final endValue = switch (state.end) {
      AttackEnd.goal => 30,
      AttackEnd.saved || AttackEnd.blocked => 22,
      AttackEnd.wide => 14,
      AttackEnd.intercepted || AttackEnd.offside => -60,
      null => 0,
    };
    final connections =
        state.finished ? 0 : availableConnections(scene, state).length;
    return base +
        endValue +
        state.ball.x * 24 +
        (state.finished ? 0 : _pressureGap(state).clamp(0, 8) * 1.6) +
        connections * 3;
  }

  bool _returnIsUseful(
    ScanPassPossessionScene scene,
    AttackState before,
    AttackState after,
  ) {
    final beforeGap = _pressureGap(before);
    final afterGap = _pressureGap(after);
    final next = availableConnections(scene, after)
        .where((number) => number != before.carrierNumber)
        .length;
    return after.carrierNumber == 6 &&
        next > 0 &&
        afterGap > 1.7 &&
        (afterGap > beforeGap + .45 || after.ball.x >= before.ball.x - .015);
  }

  ScanPassPossessionBranch _branch(
    ScanPassPossessionDecisionPoint point,
    ScanPassPossessionChoice choice,
    List<AttackTransition> newTransitions,
    ScanPassPossessionOutcomeKind outcome,
    List<ScanPassPossessionEvidence> evidence, {
    ScanPassPoint? decisionTarget,
  }) =>
      ScanPassPossessionBranch(
        scene: point.scene,
        decisions: <ScanPassPossessionChoice>[...point.decisions, choice],
        decisionTargets: <ScanPassPoint?>[
          ...point.decisionTargets,
          decisionTarget
        ],
        transitions: <AttackTransition>[...point.history, ...newTransitions],
        outcome: outcome,
        evidence: evidence,
      );

  static const List<ScanPassPossessionChoice> _supportChoices =
      <ScanPassPossessionChoice>[
    ScanPassPossessionChoice.supportInside,
    ScanPassPossessionChoice.supportWide,
    ScanPassPossessionChoice.supportBehind,
    ScanPassPossessionChoice.supportHold,
  ];

  AttackTransition _touchTransition(ScanPassPossessionScene scene,
          AttackState before, ScanPassPoint target) =>
      _carryTransition(before, target, duration: .7);

  AttackTransition _carryTransition(AttackState before, ScanPassPoint target,
          {required double duration}) =>
      _simulate(
          before,
          const AttackAction.carry(AttackCarryDirection.forward),
          distanceMetres(before.ball, target) / 4.2 + .22,
          target,
          before.carrierNumber,
          learnerTarget: target);

  AttackTransition _passTransition(
      ScanPassPossessionScene scene, AttackState before, int targetNumber,
      {required double duration}) {
    final plan = _passPlan(before, targetNumber);
    return _simulate(before, AttackAction.pass(targetNumber), plan.flight,
        plan.target, targetNumber,
        receiverTarget: plan.target);
  }

  ScanPassPoint _passTarget(AttackState before, int targetNumber) =>
      _passPlan(before, targetNumber).target;

  ({ScanPassPoint target, double flight}) _passPlan(
      AttackState before, int targetNumber) {
    final receiver = _attacker(before, targetNumber);
    var flight = distanceMetres(before.ball, receiver.position) / 19;
    var target = receiver.position;
    for (var i = 0; i < 3; i++) {
      // The receiver comes to the ball or runs across/beyond the line. The
      // release-time offside snapshot is checked independently of the run.
      final aim = _attackingAim(before, receiver,
          receiving: true, releasing: before.carrierNumber);
      target = _towardMetres(receiver.position, aim,
          math.min(4.8 * flight, distanceMetres(receiver.position, aim)));
      flight = (distanceMetres(before.ball, target) / 19).clamp(.18, 4.0);
    }
    return (target: target, flight: flight);
  }

  AttackTransition _supportRun(
      ScanPassPossessionScene scene, AttackState before, ScanPassPoint target) {
    final duration = math.max(
        .75, distanceMetres(_attacker(before, 6).position, target) / 4.8 + .25);
    return _simulate(before, const AttackAction.hold(), duration, before.ball,
        before.carrierNumber,
        learnerTarget: target);
  }

  AttackTransition _shotTransition(
      ScanPassPossessionScene scene, AttackState before) {
    final keeper = _defender(before, 1);
    final target = ScanPassPoint(1.008, keeper.position.y <= .5 ? .542 : .458);
    return _simulate(
        before,
        AttackAction.shoot(
            target.y > .5 ? AttackShotTarget.lower : AttackShotTarget.upper),
        distanceMetres(before.ball, target) / 25,
        target,
        before.carrierNumber);
  }

  /// A single trajectory is used for collision tests AND rendered frames.
  /// Roles react every 25 ms; nobody teleports to a new authored formation.
  AttackTransition _simulate(AttackState before, AttackAction action,
      double duration, ScanPassPoint destination, int receiver,
      {ScanPassPoint? learnerTarget, ScanPassPoint? receiverTarget}) {
    final offside = action.kind == AttackActionKind.pass
        ? const AttackEngine().checkOffside(before, receiver)
        : null;
    final samples = <AttackState>[before];
    var current = before;
    int? interceptor;
    final steps = math.max(1, (duration / .025).ceil());
    final dt = duration / steps;
    // Keep the presser committed to the receiver during a pass, with cover
    // behind. The others track separate threats, not a swarm toward the ball.
    final pressurePoint =
        action.kind == AttackActionKind.pass ? destination : before.ball;
    final presser = before.defenders
        .where((p) => !p.goalkeeper)
        .reduce((a, b) => distanceMetres(a.position, pressurePoint) <
                distanceMetres(b.position, pressurePoint)
            ? a
            : b)
        .number;
    for (var step = 1; step <= steps; step++) {
      final t = step / steps;
      final attackers = <AttackPlayer>[];
      for (final p in current.attackers) {
        final start = _attacker(before, p.number);
        final planned = p.number ==
                    (action.kind == AttackActionKind.carry
                        ? before.carrierNumber
                        : 6) &&
                learnerTarget != null
            ? learnerTarget
            : p.number == receiver && receiverTarget != null
                ? receiverTarget
                : null;
        if (planned != null) {
          final pos = _plannedPosition(start, planned, t, duration);
          attackers.add(_moved(p, pos, dt));
        } else if (p.number == 6 && action.kind != AttackActionKind.pass) {
          attackers.add(_advance(p, p.position, dt, maxSpeed: 5.8));
        } else {
          final aim = _attackingAim(current, p,
              releasing: before.carrierNumber,
              carrying: action.kind == AttackActionKind.hold &&
                  p.number == before.carrierNumber);
          attackers
              .add(_advance(p, aim, dt, maxSpeed: p.number == 9 ? 7.0 : 6.2));
        }
      }
      final ball = action.kind == AttackActionKind.pass ||
              action.kind == AttackActionKind.shoot
          ? before.ball.lerp(destination, t)
          : attackers
              .firstWhere((p) => p.number == before.carrierNumber)
              .position;
      final defenders = <AttackPlayer>[];
      for (final p in current.defenders) {
        final reacting =
            step * dt > (action.kind == AttackActionKind.shoot ? .16 : .12);
        final aim = !reacting
            ? p.position + p.velocity * .14
            : _defendingAim(current, p, presser, action, destination, ball);
        defenders.add(_advance(p, aim, dt,
            maxSpeed: p.goalkeeper
                ? 4.7
                : p.number == presser
                    ? 7.0
                    : 6.0));
      }
      var next = current.copyWith(
          attackers: attackers,
          defenders: defenders,
          ball: ball,
          elapsed: before.elapsed + duration * t);
      double collision = 2;
      for (final d in current.defenders) {
        if (d.goalkeeper && action.kind != AttackActionKind.shoot) continue;
        final endD = defenders.firstWhere((p) => p.number == d.number);
        final startRelative = _metres(current.ball - d.position);
        final endRelative = _metres(ball - endD.position);
        final delta = endRelative - startRelative;
        final fraction = delta.distance < .00001
            ? 0.0
            : (-(startRelative.x * delta.x + startRelative.y * delta.y) /
                    (delta.distance * delta.distance))
                .clamp(0.0, 1.0);
        final closest = startRelative.lerp(endRelative, fraction).distance;
        final radius = d.goalkeeper ? 1.5 : .90;
        if (closest <= radius && fraction < collision) {
          collision = fraction;
          interceptor = d.number;
        }
      }
      if (interceptor != null) {
        // Interpolate the collision instant, not just a sampled end point.
        next = _interpolateStates(current, next, collision);
        current = next;
        samples.add(next);
        break;
      }
      current = next;
      samples.add(next);
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
    final after = current.copyWith(
        carrierNumber: end == null && action.kind == AttackActionKind.pass
            ? receiver
            : before.carrierNumber,
        completedPasses: before.completedPasses +
            (action.kind == AttackActionKind.pass && end == null ? 1 : 0),
        actionCount: before.actionCount + 1,
        furthestX: math.max(before.furthestX, current.ball.x),
        end: end,
        cue: switch (end) {
          AttackEnd.intercepted => AttackCue.intercepted,
          AttackEnd.saved => AttackCue.saved,
          AttackEnd.blocked => AttackCue.blocked,
          AttackEnd.goal => AttackCue.goal,
          _ => action.kind == AttackActionKind.pass
              ? AttackCue.received
              : AttackCue.carried
        });
    samples[samples.length - 1] = after;
    return AttackTransition(
        before: before,
        after: after,
        action: action,
        duration: after.elapsed - before.elapsed,
        ballEnd: after.ball,
        offside: offside,
        interceptorNumber: interceptor,
        motionSamples: List.unmodifiable(samples));
  }

  ScanPassPoint _attackingAim(AttackState state, AttackPlayer player,
      {bool receiving = false, bool carrying = false, int? releasing}) {
    final ball = state.ball;
    final nearest = state.defenders.where((p) => !p.goalkeeper).reduce((a, b) =>
        distanceMetres(a.position, player.position) <
                distanceMetres(b.position, player.position)
            ? a
            : b);
    final side = player.position.y >= .5 ? 1.0 : -1.0;
    if (carrying) {
      final away = _metres(player.position - nearest.position);
      final direction = away.distance < .01
          ? const ScanPassPoint(1, 0)
          : away * (1 / away.distance);
      return _field(player.position +
          _normalized(ScanPassPoint(direction.x * 4 + 1, direction.y * 4)));
    }
    if (player.number == 4) {
      return _field(
          ball + _normalized(ScanPassPoint(-14, ball.y > .5 ? -7 : 7)));
    }
    if (player.number == 6) {
      if (receiving) {
        return _field(
            player.position + _normalized(ScanPassPoint(1.2, -side * 1.2)));
      }
      return player.position;
    }
    if (player.number == 8) {
      // An angle below the striker supports a bounce pass; when the ball is
      // behind, check toward it instead of always drifting straight forward.
      final x = receiving
          ? player.position.x - .022
          : math.max(ball.x + .09, player.position.x - .015);
      final y = ball.y + (player.position.y < ball.y ? -.16 : .16);
      return _field(ScanPassPoint(x, y));
    }
    final line = const AttackEngine().offsideLine(state);
    final ready = receiving || state.carrierNumber == 6 && ball.x > .60;
    final x = ready
        ? player.position.x + .10
        : math.min(line - .012, math.max(ball.x + .18, player.position.x));
    // Diagonal, onside checking runs rather than a static striker or a
    // guaranteed offside trap. Once a pass is released the target can break.
    final y = player.position.y +
        (player.position.y < nearest.position.y ? -.055 : .055);
    return _field(ScanPassPoint(x, y));
  }

  ScanPassPoint _defendingAim(
      AttackState state,
      AttackPlayer player,
      int presser,
      AttackAction action,
      ScanPassPoint destination,
      ScanPassPoint travellingBall) {
    if (player.goalkeeper) {
      final y = action.kind == AttackActionKind.shoot
          ? destination.y
          : .5 + (travellingBall.y - .5) * .28;
      return ScanPassPoint(.965, y.clamp(.445, .555));
    }
    if (player.number == presser) {
      // Anticipate a short distance along the flight; recover toward goal
      // when the ball has beaten the first line.
      final target = action.kind == AttackActionKind.pass
          ? travellingBall.lerp(destination, .22)
          : travellingBall;
      return _field(target);
    }
    final covers = state.defenders
        .where((p) => !p.goalkeeper && p.number != presser)
        .toList()
      ..sort((a, b) => b.position.x.compareTo(a.position.x));
    final threatNumber = player.number == covers.first.number ? 9 : 8;
    final threat = _attacker(state, threatNumber).position;
    final lane = travellingBall.lerp(threat, .72);
    final goalSide = threat + _normalized(const ScanPassPoint(2.5, 0));
    final cover = lane.lerp(goalSide, .38);
    // Ball-side compactness and staggered depth: retain a cover position
    // between receiver and goal rather than stand beside the pressing player.
    return _field(
        ScanPassPoint(math.max(cover.x, travellingBall.x + .027), cover.y));
  }

  AttackPlayer _advance(AttackPlayer p, ScanPassPoint target, double dt,
      {required double maxSpeed}) {
    final delta = _metres(target - p.position);
    final old = _metres(p.velocity);
    const acceleration = 5.5;
    final speed =
        math.min(maxSpeed, math.sqrt(2 * acceleration * delta.distance));
    final desired = delta.distance < .025
        ? const ScanPassPoint(0, 0)
        : delta * (speed / delta.distance);
    final change = desired - old;
    final velocity = old +
        (change.distance <= acceleration * dt
            ? change
            : change * (acceleration * dt / change.distance));
    final bounded = velocity;
    final pos = _field(p.position + _normalized(bounded * dt));
    return p.copyWith(
      position: pos,
      velocity: _normalized(bounded),
      facingRadians: bounded.distance < .001
          ? p.facingRadians
          : math.atan2(bounded.y, bounded.x),
    );
  }

  ScanPassPoint _plannedPosition(
      AttackPlayer p, ScanPassPoint target, double t, double duration) {
    final delta = _metres(target - p.position);
    final distance = delta.distance;
    if (distance < .001) return target;
    final old = _metres(p.velocity);
    final direction = delta * (1 / distance);
    final startSpeed = (old.x * direction.x + old.y * direction.y)
        .clamp(0.0, math.min(3.5, distance / duration));
    final endSpeed = math.min(2.0, distance / duration);
    final t2 = t * t, t3 = t2 * t;
    final progress = (startSpeed * duration * (t3 - 2 * t2 + t) +
            distance * (-2 * t3 + 3 * t2) +
            endSpeed * duration * (t3 - t2)) /
        distance;
    // The displayed run vector and metre label are the exact travelled path.
    return _field(p.position.lerp(target, progress));
  }

  static AttackState _interpolateStates(
          AttackState a, AttackState b, double t) =>
      a.copyWith(
          attackers: [
            for (final p in a.attackers)
              p.copyWith(
                  position: p.position.lerp(
                      b.attackers
                          .firstWhere((q) => q.number == p.number)
                          .position,
                      t),
                  velocity: p.velocity.lerp(
                      b.attackers
                          .firstWhere((q) => q.number == p.number)
                          .velocity,
                      t))
          ],
          defenders: [
            for (final p in a.defenders)
              p.copyWith(
                  position: p.position.lerp(
                      b.defenders
                          .firstWhere((q) => q.number == p.number)
                          .position,
                      t),
                  velocity: p.velocity.lerp(
                      b.defenders
                          .firstWhere((q) => q.number == p.number)
                          .velocity,
                      t))
          ],
          ball: a.ball.lerp(b.ball, t),
          elapsed: a.elapsed + (b.elapsed - a.elapsed) * t);

  ScanPassPoint _touchAwayTarget(ScanPassPossessionScene scene) {
    final state = scene.reception;
    final defender = state.defenders.where((p) => !p.goalkeeper).reduce(
        (a, b) => distanceMetres(a.position, state.ball) <
                distanceMetres(b.position, state.ball)
            ? a
            : b);
    final away = _metres(state.ball - defender.position);
    final direction = ScanPassPoint(.65, away.y >= 0 ? 1 : -1);
    return _field(
        state.ball + _normalized(direction * (2.8 / direction.distance)));
  }

  ScanPassPoint _turnForwardTarget(ScanPassPossessionScene scene) =>
      _field(scene.reception.ball + _normalized(const ScanPassPoint(3.2, 0)));

  ScanPassPoint _supportTarget(
      AttackState state, ScanPassPossessionChoice choice) {
    final origin = _attacker(state, 6).position;
    final side = origin.y >= .5 ? 1.0 : -1.0;
    final delta = switch (choice) {
      ScanPassPossessionChoice.supportInside => ScanPassPoint(7, -side * 4),
      ScanPassPossessionChoice.supportWide => ScanPassPoint(5, side * 6),
      ScanPassPossessionChoice.supportBehind => ScanPassPoint(-4, -side * 4),
      ScanPassPossessionChoice.supportHold ||
      ScanPassPossessionChoice.supportCustom =>
        const ScanPassPoint(0, 0),
      _ => throw StateError('Not a support choice: $choice')
    };
    return _field(origin + _normalized(delta));
  }

  static ScanPassPoint _towardMetres(
      ScanPassPoint from, ScanPassPoint to, double distance) {
    final delta = _metres(to - from);
    return delta.distance <= distance || delta.distance < .00001
        ? _field(to)
        : _field(from + _normalized(delta * (distance / delta.distance)));
  }

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

  static ScanPassPoint _field(ScanPassPoint point) =>
      point.clampToField(minX: .055, maxX: .975, minY: .08, maxY: .92);
}
