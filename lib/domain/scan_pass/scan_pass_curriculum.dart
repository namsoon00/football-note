import 'dart:math' as math;

import 'scan_pass_attack.dart';
import 'scan_pass_game.dart' show ScanPassPoint;

class PracticeSettings {
  final bool controlAllAttackers;
  final bool passAndMove;
  final bool freeFlow;
  final bool automaticSupport;

  const PracticeSettings({
    this.controlAllAttackers = true,
    this.passAndMove = false,
    this.freeFlow = false,
    this.automaticSupport = false,
  });
}

enum PracticeSkill {
  firstTouch,
  drawDefender,
  throughPass,
  supportAngle,
  thirdPlayer,
  switchPlay,
}

enum PracticePhase { firstTouch, onBall, support, finished }

enum PracticeActionKind { touch, carry, pass, through, move, hold }

enum PracticeOutcome { gateReached, retained, intercepted, offside }

enum PracticeCue {
  pressureSide,
  defenderCommitment,
  runnerTiming,
  passingLane,
  supportLane,
  thirdPlayerLane,
  farSideSpace,
}

enum PracticeReason {
  touchOpensView,
  touchIntoPressure,
  defenderDrawn,
  carryIntoCover,
  runnerMetInStride,
  runnerNotReady,
  passToFeet,
  receivedUnderPressure,
  passLaneClosed,
  supportLaneOpened,
  supportStillHidden,
  thirdPlayerConnected,
  farSideOpened,
  holdCreatesWindow,
  holdUnderPressure,
  possessionSecured,
  controlledGate,
  offsideAtKick,
}

/// Thresholds are instructional observations, not a hidden points system.
class PracticeRubric {
  final double minimumPressureGap;
  final double minimumLaneClearance;
  final bool requireMovingReceiver;
  final bool requireThirdPlayer;
  final bool requireSwitch;

  const PracticeRubric({
    this.minimumPressureGap = 1.5,
    this.minimumLaneClearance = 1,
    this.requireMovingReceiver = false,
    this.requireThirdPlayer = false,
    this.requireSwitch = false,
  });
}

class PracticeLearningDefinition {
  final PracticeSkill goal;
  final List<PracticeCue> cues;
  final List<PracticeReason> mistakes;
  final PracticeRubric rubric;

  const PracticeLearningDefinition({
    required this.goal,
    required this.cues,
    required this.mistakes,
    required this.rubric,
  });
}

class PracticeGate {
  final String id;
  final ScanPassPoint center;
  final double halfWidth;

  const PracticeGate({
    required this.id,
    required this.center,
    this.halfWidth = .075,
  });

  /// Only a forward crossing while the same player controls the ball counts.
  /// A ball travelling through on its own is explicitly excluded.
  bool crossed(AttackState before, AttackState after) {
    if (before.carrierIsDefender ||
        after.carrierIsDefender ||
        before.carrierNumber != after.carrierNumber ||
        before.ball.x >= center.x ||
        after.ball.x < center.x ||
        PracticeEngine.distanceMetres(before.ball, before.carrier.position) >
            .65 ||
        PracticeEngine.distanceMetres(after.ball, after.carrier.position) >
            .65) {
      return false;
    }
    final t = (center.x - before.ball.x) / (after.ball.x - before.ball.x);
    final y = before.ball.y + (after.ball.y - before.ball.y) * t;
    final carrierX = before.carrier.position.x +
        (after.carrier.position.x - before.carrier.position.x) * t;
    return (y - center.y).abs() < halfWidth - .008 &&
        (carrierX - center.x).abs() * PracticeEngine.fieldLength <= .65;
  }
}

class PracticeCase {
  final String id;
  final PracticeSkill skill;
  final int variant;
  final int stage;
  final bool offsideEnabled;
  final List<PracticeGate> gates;
  final AttackTransition observation;
  final PracticeLearningDefinition learning;

  const PracticeCase({
    required this.id,
    required this.skill,
    required this.variant,
    required this.stage,
    required this.offsideEnabled,
    required this.gates,
    required this.observation,
    required this.learning,
  });

  AttackState get initial => observation.before;
  AttackState get reception => observation.after;
}

class PracticeAction {
  final String id;
  final PracticeActionKind kind;
  final ScanPassPoint target;
  final int? receiver;
  final int? actorNumber;

  const PracticeAction({
    required this.id,
    required this.kind,
    required this.target,
    this.receiver,
    this.actorNumber,
  });
}

class PracticeDecision {
  final AttackState before;
  final PracticePhase phaseBefore;
  final PracticeAction action;
  final List<AttackTransition> transitions;
  final PracticeReason reason;
  final PracticeCue cue;
  final bool useful;
  final bool goalDemonstrated;
  final double pressureBefore;
  final double pressureAfter;
  final double laneBefore;
  final double laneAfter;
  final double distance;
  final int optionsBefore;
  final int optionsAfter;
  final int? evidencePlayer;
  final int historyLengthBefore;
  final int decisionsLengthBefore;
  final PracticeSettings settingsBefore;
  final Map<int, ScanPassPoint> runTargetsBefore;
  final int? returnTargetBefore;

  const PracticeDecision({
    required this.before,
    required this.phaseBefore,
    required this.action,
    required this.transitions,
    required this.reason,
    required this.cue,
    required this.useful,
    required this.goalDemonstrated,
    required this.pressureBefore,
    required this.pressureAfter,
    required this.laneBefore,
    required this.laneAfter,
    required this.distance,
    required this.optionsBefore,
    required this.optionsAfter,
    required this.evidencePlayer,
    required this.historyLengthBefore,
    required this.decisionsLengthBefore,
    this.settingsBefore = const PracticeSettings(),
    this.runTargetsBefore = const {},
    this.returnTargetBefore,
  });

  AttackState get after => transitions.last.after;
}

class PracticeSession {
  final PracticeCase lesson;
  final AttackState state;
  final PracticePhase phase;
  final List<PracticeDecision> decisions;
  final List<AttackTransition> history;
  final PracticeOutcome? outcome;
  final String? reachedGate;
  final PracticeSettings settings;
  final Map<int, ScanPassPoint> runTargets;
  final int? returnTarget;

  const PracticeSession({
    required this.lesson,
    required this.state,
    required this.phase,
    this.decisions = const [],
    this.history = const [],
    this.outcome,
    this.reachedGate,
    this.settings = const PracticeSettings(),
    this.runTargets = const {},
    this.returnTarget,
  });

  bool get finished => phase == PracticePhase.finished;
  int? get stolenBy => state.carrierIsDefender ? state.carrierNumber : null;
  bool get goalDemonstrated => decisions.any((d) => d.goalDemonstrated);
  int get decisionLimit => settings.controlAllAttackers
      ? PracticeEngine.manualDecisionLimit
      : PracticeEngine.decisionLimit;
}

class PracticeStep {
  final PracticeSession session;
  final List<AttackTransition> transitions;
  final PracticeDecision decision;

  const PracticeStep({
    required this.session,
    required this.transitions,
    required this.decision,
  });
}

/// A 40 x 28 metre, deterministic small-sided exercise. Choices pause time.
/// All motion, interceptions and controlled gate crossings use the same samples.
/// Case ids are never consulted by the movement or recommendation policies.
class PracticeEngine {
  static const double fieldLength = 40;
  static const double fieldWidth = 28;
  static const int decisionLimit = 8;
  static const int manualDecisionLimit = 16;
  static const double freeFlowTouchLimit = 2.3;
  static const double _step = .025;
  static final List<PracticeCase> catalog = List.unmodifiable([
    for (final skill in PracticeSkill.values)
      for (var variant = 0; variant < 2; variant++) _createCase(skill, variant),
  ]);

  const PracticeEngine();

  PracticeSession start(PracticeCase lesson,
      {PracticeSettings settings = const PracticeSettings()}) {
    final session = PracticeSession(
        lesson: lesson,
        settings: settings,
        state: lesson.reception,
        phase: PracticePhase.firstTouch,
        history: [lesson.observation]);
    return _withAutomaticSupport(session);
  }

  PracticeSession beforeDecision(PracticeSession session, int index) {
    final decision = session.decisions[index];
    return PracticeSession(
      lesson: session.lesson,
      state: decision.before,
      phase: decision.phaseBefore,
      settings: decision.settingsBefore,
      runTargets: decision.runTargetsBefore,
      returnTarget: decision.returnTargetBefore,
      decisions: List.unmodifiable(
          session.decisions.take(decision.decisionsLengthBefore)),
      history:
          List.unmodifiable(session.history.take(decision.historyLengthBefore)),
    );
  }

  List<PracticeAction> choices(PracticeSession session) {
    if (session.finished) return const [];
    session = _withAutomaticSupport(session);
    final state = session.state;
    final learner = session.settings.controlAllAttackers
        ? state.carrier
        : _player(state, 6);
    if (session.phase == PracticePhase.firstTouch) {
      return [
        for (final entry in [
          ('forward', const ScanPassPoint(2.1, 0)),
          ('upper', const ScanPassPoint(.7, -2.1)),
          ('lower', const ScanPassPoint(.7, 2.1)),
        ])
          PracticeAction(
              id: 'touch-${entry.$1}',
              actorNumber: learner.number,
              kind: PracticeActionKind.touch,
              target: boundedTarget(learner.position + _normalized(entry.$2))),
      ];
    }
    if (!session.settings.controlAllAttackers &&
        session.phase == PracticePhase.support) {
      final carrier = state.carrier.position;
      return [
        for (final entry in [
          ('upper', const ScanPassPoint(-3, -6)),
          ('lower', const ScanPassPoint(-3, 6)),
          ('beyond', const ScanPassPoint(6, 0)),
        ])
          PracticeAction(
              id: 'move-${entry.$1}',
              kind: PracticeActionKind.move,
              target: _toward(learner.position,
                  boundedTarget(carrier + _normalized(entry.$2)), 8)),
        PracticeAction(
            id: 'hold',
            kind: PracticeActionKind.hold,
            target: learner.position),
      ];
    }
    return _ballChoices(session.lesson, state,
        returnTarget:
            session.settings.passAndMove ? session.returnTarget : null,
        runTargets: session.runTargets,
        allowUnplannedThrough: !session.settings.freeFlow,
        leadPasses: session.settings.automaticSupport);
  }

  /// Plans change no time, history or possession. They execute only when the
  /// user commits a ball action or explicitly lets time advance with hold.
  PracticeSession planRun(
      PracticeSession session, int playerNumber, ScanPassPoint target) {
    _requireActiveAttacker(session, playerNumber);
    if (playerNumber == session.state.carrierNumber) {
      throw ArgumentError('A run plan is for an off-ball attacker');
    }
    _requireFinite(target);
    return _withRunTargets(session, {
      ...session.runTargets,
      playerNumber: session.settings.freeFlow
          ? boundedTarget(target)
          : _toward(_player(session.state, playerNumber).position,
              boundedTarget(target), 8),
    });
  }

  PracticeSession cancelRun(PracticeSession session, int playerNumber) {
    _requireActiveAttacker(session, playerNumber);
    final targets = {...session.runTargets}..remove(playerNumber);
    return _withRunTargets(session, targets);
  }

  PracticeSession _withRunTargets(
          PracticeSession session, Map<int, ScanPassPoint> targets) =>
      PracticeSession(
        lesson: session.lesson,
        state: session.state,
        phase: session.phase,
        settings: session.settings,
        runTargets: Map.unmodifiable(targets),
        returnTarget: session.returnTarget,
        decisions: session.decisions,
        history: session.history,
        outcome: session.outcome,
        reachedGate: session.reachedGate,
      );

  PracticeSession _withAutomaticSupport(PracticeSession session,
      {PracticeAction? pendingAction}) {
    if (!session.settings.automaticSupport ||
        session.finished ||
        session.state.carrierIsDefender) {
      return session;
    }
    final state = session.state;
    final actionIsPass = pendingAction?.kind == PracticeActionKind.pass ||
        pendingAction?.kind == PracticeActionKind.through;
    final targets = {
      for (final entry in session.runTargets.entries)
        if (state.attackers.any((p) => p.number == entry.key))
          entry.key: boundedTarget(entry.value),
    };
    targets.removeWhere((number, target) {
      final player = _player(state, number);
      final isCarrier = number == state.carrierNumber;
      if (isCarrier && !actionIsPass) return true;
      return distanceMetres(player.position, target) <= .18 ||
          !_supportTargetViable(state, player, target);
    });
    for (final player
        in state.attackers.where((p) => p.number != state.carrierNumber)) {
      final current = targets[player.number];
      if (current == null ||
          !_supportTargetViable(state, player, current) ||
          distanceMetres(player.position, current) <= .18) {
        targets[player.number] = _automaticSupportTarget(state, player,
            previousTarget: session.runTargets[player.number]);
      }
    }
    if (actionIsPass) {
      final actor = pendingAction?.actorNumber ?? state.carrierNumber;
      if (actor == state.carrierNumber) {
        final existingManualTarget = session.runTargets[actor];
        if (existingManualTarget != null) {
          targets[actor] = boundedTarget(existingManualTarget);
        } else {
          final receiver = pendingAction?.receiver;
          final anchor = receiver == null
              ? state.ball
              : pendingAction!.kind == PracticeActionKind.through
                  ? boundedTarget(pendingAction.target)
                  : _passTarget(state, receiver, targets);
          targets[actor] = _automaticSupportTarget(
            state,
            state.carrier,
            anchor: anchor,
            previousTarget: session.runTargets[actor],
          );
        }
      }
    }
    return _withRunTargets(session, targets);
  }

  static bool _supportTargetViable(
      AttackState state, AttackPlayer player, ScanPassPoint target) {
    final bounded = boundedTarget(target);
    if (bounded.distanceTo(target) > .001) return false;
    final fromCarrier = distanceMetres(state.ball, target);
    if (fromCarrier < 2.2 || fromCarrier > 15.0) return false;
    if (nearestDefender(state, target) < 1.15) return false;
    for (final teammate in state.attackers) {
      if (teammate.number == player.number) continue;
      if (distanceMetres(teammate.position, target) < 1.3) return false;
    }
    final run = distanceMetres(player.position, target);
    return run <= 7.2 || laneClearance(state, state.ball, target) >= 1.6;
  }

  static ScanPassPoint _automaticSupportTarget(
      AttackState state, AttackPlayer player,
      {ScanPassPoint? anchor, ScanPassPoint? previousTarget}) {
    final ball = anchor ?? state.ball;
    final nearest = state.defenders.reduce((a, b) =>
        distanceMetres(a.position, player.position) <
                distanceMetres(b.position, player.position)
            ? a
            : b);
    final awayY = player.position.y <= nearest.position.y ? -1.0 : 1.0;
    final boundaryAwareY = player.position.y < .18
        ? 1.0
        : player.position.y > .82
            ? -1.0
            : awayY;
    final currentLane = laneClearance(state, ball, player.position);
    final hiddenLane = currentLane < 1.15;
    final baseOffsets = hiddenLane
        ? const [
            ScanPassPoint(-1.3, -4.0),
            ScanPassPoint(-1.3, 4.0),
            ScanPassPoint(2.6, -4.8),
            ScanPassPoint(2.6, 4.8),
            ScanPassPoint(4.8, -2.8),
            ScanPassPoint(4.8, 2.8),
          ]
        : const [
            ScanPassPoint(4.2, -2.4),
            ScanPassPoint(4.2, 2.4),
            ScanPassPoint(2.0, -4.2),
            ScanPassPoint(2.0, 4.2),
            ScanPassPoint(-1.6, -3.2),
            ScanPassPoint(-1.6, 3.2),
          ];
    final candidates = <ScanPassPoint>[
      if (previousTarget != null) previousTarget,
      for (final offset in baseOffsets) ball + _normalized(offset),
      player.position + _normalized(ScanPassPoint(3.6, boundaryAwareY * 2.4)),
      player.position + _normalized(ScanPassPoint(-1.4, boundaryAwareY * 3.4)),
      player.position + _normalized(ScanPassPoint(1.8, -boundaryAwareY * 3.0)),
    ].map(boundedTarget).toList();
    var best = player.position;
    var value = double.negativeInfinity;
    for (final candidate in candidates) {
      final run = distanceMetres(player.position, candidate);
      if (run < .35 || run > 8.2) continue;
      if (nearestDefender(state, candidate) < 1.05) continue;
      if (distanceMetres(candidate, ball) < 2.4) continue;
      var crowded = false;
      for (final teammate in state.attackers) {
        if (teammate.number == player.number) continue;
        if (distanceMetres(teammate.position, candidate) < 1.15) {
          crowded = true;
          break;
        }
      }
      if (crowded) continue;
      final lane = laneClearance(state, ball, candidate);
      final pressure = nearestDefender(state, candidate);
      final lateral = (candidate.y - ball.y).abs() * fieldWidth;
      final distance = distanceMetres(ball, candidate);
      final angleScore =
          lateral >= 2.0 && lateral <= 9.0 && distance >= 4.0 ? 3.0 : 0.0;
      final forward = math.max(0.0, (candidate.x - player.position.x) * 40);
      final checking =
          math.max(0.0, (player.position.x - candidate.x) * 40) * .25;
      final stability = previousTarget == null
          ? 0.0
          : math.max(0.0, 1.8 - distanceMetres(previousTarget, candidate));
      final runCost = (run - 3.2).abs() * .28;
      final score = lane * 2.5 +
          pressure * 1.2 +
          angleScore +
          forward.clamp(0, 5) * (hiddenLane ? .35 : .55) +
          checking +
          stability * 1.6 -
          runCost -
          (candidate.y < .11 || candidate.y > .89 ? 2.0 : 0.0);
      if (score > value) {
        value = score;
        best = candidate;
      }
    }
    return boundedTarget(best);
  }

  void _requireActiveAttacker(PracticeSession session, int number) {
    if (session.finished) throw StateError('Exercise is already complete');
    if (!session.state.attackers.any((p) => p.number == number)) {
      throw ArgumentError.value(number, 'playerNumber', 'Unknown attacker');
    }
  }

  static void _requireFinite(ScanPassPoint target) {
    if (!target.x.isFinite || !target.y.isFinite) {
      throw ArgumentError('Target must contain finite coordinates');
    }
  }

  PracticeStep moveTo(PracticeSession session, ScanPassPoint target,
      {int? playerNumber}) {
    final number = playerNumber ??
        (session.settings.controlAllAttackers
            ? session.state.carrierNumber
            : 6);
    _requireActiveAttacker(session, number);
    _requireFinite(target);
    final offBall = number != session.state.carrierNumber;
    return choose(
        session,
        PracticeAction(
          id: offBall ? 'move-custom' : 'carry-custom',
          kind: offBall ? PracticeActionKind.move : PracticeActionKind.carry,
          actorNumber: number,
          target: session.settings.freeFlow
              ? boundedTarget(target)
              : _toward(_player(session.state, number).position,
                  boundedTarget(target), offBall ? 8 : 5.8),
        ));
  }

  PracticeAction _checkedAction(
      PracticeSession session, PracticeAction action) {
    _requireFinite(action.target);
    final state = session.state;
    final actor = action.actorNumber ??
        (action.kind == PracticeActionKind.move ? 6 : state.carrierNumber);
    _requireActiveAttacker(session, actor);
    final isPass = action.kind == PracticeActionKind.pass ||
        action.kind == PracticeActionKind.through;
    if (action.kind == PracticeActionKind.move) {
      if (actor == state.carrierNumber) {
        throw ArgumentError('Use carry to move the ball carrier');
      }
    } else if (actor != state.carrierNumber &&
        !(action.kind == PracticeActionKind.hold &&
            session.settings.controlAllAttackers &&
            session.runTargets.containsKey(actor))) {
      throw ArgumentError('This action belongs to the current ball carrier');
    }
    if (session.phase == PracticePhase.firstTouch &&
        action.kind != PracticeActionKind.touch) {
      throw ArgumentError('Choose the first touch before the next action');
    }
    if (action.kind == PracticeActionKind.touch &&
        session.phase != PracticePhase.firstTouch) {
      throw ArgumentError('The first touch has already been chosen');
    }
    if (isPass) {
      if (action.receiver == null ||
          action.receiver == state.carrierNumber ||
          !state.attackers.any((p) => p.number == action.receiver)) {
        throw ArgumentError('A pass requires another current attacker');
      }
      if (session.settings.passAndMove &&
          session.returnTarget != null &&
          action.receiver != session.returnTarget) {
        throw ArgumentError('The next pass must return to the previous passer');
      }
      if (session.settings.freeFlow &&
          action.kind == PracticeActionKind.through &&
          (session.runTargets[action.receiver] == null ||
              distanceMetres(
                      action.target, session.runTargets[action.receiver]!) >
                  .05)) {
        throw ArgumentError('A through pass needs a commanded receiver run');
      }
      if (action.kind == PracticeActionKind.pass &&
          !session.settings.automaticSupport &&
          distanceMetres(
                  action.target, _player(state, action.receiver!).position) >
              .05) {
        throw ArgumentError('Pass-to-feet target is stale');
      }
    }
    final target = switch (action.kind) {
      PracticeActionKind.move => session.settings.freeFlow
          ? boundedTarget(action.target)
          : _toward(
              _player(state, actor).position, boundedTarget(action.target), 8),
      PracticeActionKind.touch => _toward(_player(state, actor).position,
          boundedTarget(action.target), freeFlowTouchLimit),
      PracticeActionKind.carry => session.settings.freeFlow
          ? boundedTarget(action.target)
          : _toward(_player(state, actor).position,
              boundedTarget(action.target), 5.8),
      PracticeActionKind.pass => session.settings.automaticSupport
          ? _passTarget(state, action.receiver!, session.runTargets)
          : _player(state, action.receiver!).position,
      PracticeActionKind.through => session.settings.freeFlow
          ? boundedTarget(action.target)
          : _toward(_player(state, action.receiver!).position,
              boundedTarget(action.target), 8),
      PracticeActionKind.hold => state.carrier.position,
    };
    return PracticeAction(
        id: action.id,
        kind: action.kind,
        target: target,
        receiver: action.receiver,
        actorNumber: actor);
  }

  PracticeStep choose(PracticeSession session, PracticeAction action) {
    if (session.finished) {
      throw StateError('Cannot choose after a completed exercise');
    }
    session = _withAutomaticSupport(session, pendingAction: action);
    action = _checkedAction(session, action);
    if (!session.settings.controlAllAttackers &&
        action.kind == PracticeActionKind.move &&
        session.phase != PracticePhase.support) {
      throw ArgumentError('Off-ball movement requires support phase');
    }
    if (!session.settings.controlAllAttackers &&
        session.phase == PracticePhase.support &&
        action.kind != PracticeActionKind.move &&
        action.kind != PracticeActionKind.hold) {
      throw ArgumentError(
          'Choose a learner movement while a teammate has ball');
    }
    final result = _execute(session.lesson, session.state, action,
        settings: session.settings, runTargets: session.runTargets);
    final transitions = <AttackTransition>[result.transition];
    var state = result.transition.after;
    var gate = result.gate;
    // A support choice grants the teammate one independent football decision.
    // The learner never receives a forced return and never runs automatically.
    if (!session.settings.controlAllAttackers &&
        session.phase == PracticePhase.support &&
        state.end == null &&
        gate == null) {
      final continuation = _teammateAction(session.lesson, state);
      final continued = _execute(session.lesson, state, continuation,
          settings: session.settings,
          learnerTarget:
              action.kind == PracticeActionKind.move ? action.target : null);
      transitions.add(continued.transition);
      state = continued.transition.after;
      gate = continued.gate;
    }
    final decision = _evaluate(session, action, transitions, gate);
    final decisions = [...session.decisions, decision];
    final outcome = state.end == AttackEnd.offside
        ? PracticeOutcome.offside
        : state.end == AttackEnd.intercepted
            ? PracticeOutcome.intercepted
            : gate != null
                ? PracticeOutcome.gateReached
                : decisions.length >= session.decisionLimit
                    ? PracticeOutcome.retained
                    : null;
    final updated = _withAutomaticSupport(PracticeSession(
      lesson: session.lesson,
      state: state,
      settings: session.settings,
      runTargets: Map.unmodifiable({
        for (final entry in session.runTargets.entries)
          if (entry.key != state.carrierNumber &&
              entry.key != action.receiver &&
              distanceMetres(_player(state, entry.key).position, entry.value) >
                  .08)
            entry.key: entry.value,
      }),
      returnTarget: session.settings.passAndMove &&
              state.completedPasses > session.state.completedPasses
          ? session.state.carrierNumber
          : session.returnTarget,
      phase: outcome != null
          ? PracticePhase.finished
          : session.settings.freeFlow &&
                  state.completedPasses > session.state.completedPasses
              ? PracticePhase.firstTouch
              : session.settings.controlAllAttackers || state.carrierNumber == 6
                  ? PracticePhase.onBall
                  : PracticePhase.support,
      decisions: List.unmodifiable(decisions),
      history: List.unmodifiable([...session.history, ...transitions]),
      outcome: outcome,
      reachedGate: gate,
    ));
    return PracticeStep(
        session: updated,
        transitions: List.unmodifiable(transitions),
        decision: decision);
  }

  List<PracticeAction> rankedChoices(PracticeSession session) {
    final scored = [
      for (final action in _analysisChoices(session))
        (action: action, value: _rankValue(session, choose(session, action))),
    ]..sort((a, b) => b.value.compareTo(a.value));
    return List.unmodifiable(scored.map((entry) => entry.action));
  }

  List<PracticeAction> _analysisChoices(PracticeSession session) => [
        ...choices(session),
        // Coaching may propose one explicitly selected off-ball movement.
        // This never changes the public carrier controls or runs automatically.
        if (session.settings.controlAllAttackers &&
            session.phase == PracticePhase.onBall &&
            (session.settings.passAndMove
                ? session.returnTarget != null
                : session.lesson.skill == PracticeSkill.supportAngle))
          for (final p in session.state.attackers.where((p) =>
              p.number != session.state.carrierNumber &&
              (!session.settings.passAndMove ||
                  p.number == session.returnTarget)))
            for (final direction in [-1, 1])
              PracticeAction(
                id: 'support-${p.number}-$direction',
                kind: PracticeActionKind.move,
                actorNumber: p.number,
                target: boundedTarget(p.position +
                    _normalized(ScanPassPoint(-.8, direction * 2.0))),
              ),
      ];

  double _rankValue(PracticeSession before, PracticeStep step) {
    final immediate = _learningValue(before, step);
    if (step.session.finished) return immediate;
    final next = [
      for (final a in choices(step.session)) choose(step.session, a)
    ];
    final bestNext =
        next.map((s) => _learningValue(step.session, s)).reduce(math.max);
    return immediate + bestNext * .3;
  }

  PracticeAction recommended(PracticeSession session) {
    final ranked = rankedChoices(session);
    if (ranked.isEmpty) throw StateError('No choice in a completed exercise');
    return ranked.first;
  }

  /// A comparison from exactly the same world; no privileged physics or pass.
  PracticeSession coachRun(PracticeCase lesson,
      {PracticeSettings settings = const PracticeSettings()}) {
    var session = start(lesson, settings: settings);
    while (!session.finished) {
      session = choose(session, recommended(session)).session;
    }
    if (session.outcome != PracticeOutcome.intercepted &&
        session.outcome != PracticeOutcome.offside) {
      return session;
    }
    // A complete comparison is planned through actual trajectories. Bounded
    // beam search avoids presenting a short-sighted recommendation as the only
    // correct route, with no privileged movement or immunity to interceptions.
    var beam = [(session: start(lesson, settings: settings), value: 0.0)];
    for (var depth = 0; depth < session.decisionLimit; depth++) {
      final next = <({PracticeSession session, double value})>[];
      final completed = <({PracticeSession session, double value})>[];
      for (final branch in beam) {
        for (final action in _analysisChoices(branch.session)) {
          final step = choose(branch.session, action);
          if (step.session.outcome == PracticeOutcome.intercepted ||
              step.session.outcome == PracticeOutcome.offside) {
            continue;
          }
          final value = branch.value + _learningValue(branch.session, step);
          final item = (session: step.session, value: value);
          if (step.session.finished) {
            completed.add(item);
          } else {
            next.add(item);
          }
        }
      }
      if (completed.isNotEmpty) {
        completed.sort((a, b) => b.value.compareTo(a.value));
        return completed.first.session;
      }
      next.sort((a, b) => b.value.compareTo(a.value));
      beam = next.take(14).toList();
      if (beam.isEmpty) break;
    }
    return session;
  }

  static ScanPassPoint boundedTarget(ScanPassPoint p) => ScanPassPoint(
      p.x.clamp(.055, .955).toDouble(), p.y.clamp(.075, .925).toDouble());

  static double distanceMetres(ScanPassPoint a, ScanPassPoint b) =>
      _metres(a - b).distance;

  static double nearestDefender(AttackState state, ScanPassPoint point) =>
      state.defenders
          .map((d) => distanceMetres(d.position, point))
          .reduce(math.min);

  static double laneClearance(
          AttackState state, ScanPassPoint from, ScanPassPoint to) =>
      state.defenders
          .map((d) => _segmentDistance(d.position, from, to))
          .reduce(math.min);

  static AttackOffsideSnapshot checkOffside(AttackState state, int receiver) {
    final ordered = state.defenders.map((p) => p.position.x).toList()
      ..sort((a, b) => b.compareTo(a));
    // No goalkeeper is invented. The two last actual defenders define the line.
    final secondLast = ordered.length >= 2 ? ordered[1] : 1.0;
    final line = math.max(.5, math.max(secondLast, state.ball.x));
    return AttackOffsideSnapshot(
      atKick: state,
      receiverNumber: receiver,
      secondLastX: secondLast,
      lineX: line,
      offside: _player(state, receiver).position.x > line + .0001,
    );
  }

  static ScanPassPoint _passTarget(
      AttackState state, int receiver, Map<int, ScanPassPoint> runTargets) {
    final player = _player(state, receiver);
    final runTarget = runTargets[receiver];
    if (runTarget == null) return player.position;
    final speed = _metres(player.velocity).distance;
    final runDistance = distanceMetres(player.position, runTarget);
    if (runDistance < .45 && speed < .4) return player.position;
    final receiveAim = _runThroughTarget(player, runTarget, runTarget);
    final distance = distanceMetres(player.position, receiveAim);
    var target = player.position;
    for (var i = 0; i < 5; i += 1) {
      final flight = distanceMetres(state.ball, target) / 17;
      final projected = _projectRunner(
          player, receiveAim, math.min(1.0, flight + .12),
          maxSpeed: 6.4);
      final leadLimit = math.min(2.8, math.max(.7, distance));
      target = _toward(player.position, projected.position, leadLimit);
    }
    return boundedTarget(target);
  }

  List<PracticeAction> _ballChoices(PracticeCase lesson, AttackState state,
          {int? returnTarget,
          Map<int, ScanPassPoint> runTargets = const {},
          bool allowUnplannedThrough = true,
          bool leadPasses = false}) =>
      [
        for (final gate in lesson.gates)
          PracticeAction(
            id: 'carry-${gate.id}',
            actorNumber: state.carrierNumber,
            kind: PracticeActionKind.carry,
            target: _toward(state.carrier.position,
                ScanPassPoint(gate.center.x + .045, gate.center.y), 5.8),
          ),
        for (final p in state.attackers.where((player) =>
            player.number != state.carrierNumber &&
            (returnTarget == null || player.number == returnTarget))) ...[
          PracticeAction(
              id: 'pass-${p.number}',
              actorNumber: state.carrierNumber,
              kind: PracticeActionKind.pass,
              target: leadPasses
                  ? _passTarget(state, p.number, runTargets)
                  : p.position,
              receiver: p.number),
          if (allowUnplannedThrough || runTargets.containsKey(p.number))
            PracticeAction(
                id: 'through-${p.number}',
                actorNumber: state.carrierNumber,
                kind: PracticeActionKind.through,
                target: runTargets[p.number] ?? _throughTarget(state, p),
                receiver: p.number),
        ],
        PracticeAction(
            id: 'hold',
            kind: PracticeActionKind.hold,
            target: state.carrier.position,
            actorNumber: state.carrierNumber),
      ];

  PracticeAction _teammateAction(PracticeCase lesson, AttackState state) {
    final candidates = _ballChoices(lesson, state);
    var best = candidates.last;
    var value = double.negativeInfinity;
    for (final action in candidates) {
      final result = _execute(lesson, state, action,
          settings: const PracticeSettings(controlAllAttackers: false));
      final after = result.transition.after;
      var score = _continuationValue(lesson, state, after, result.gate);
      if (action.kind == PracticeActionKind.pass ||
          action.kind == PracticeActionKind.through) {
        final returnToLearner = action.receiver == 6;
        if (returnToLearner) {
          // A return needs both a usable lane and a better next view/connection.
          final usefulReturn = _connections(lesson, after) > 0 &&
              (nearestDefender(after, after.ball) >
                      nearestDefender(state, state.ball) + .7 ||
                  after.ball.x > state.ball.x + .04);
          if (!usefulReturn) score -= 28;
        }
      }
      if (score > value) {
        value = score;
        best = action;
      }
    }
    return best;
  }

  double _continuationValue(PracticeCase lesson, AttackState before,
      AttackState after, String? gate) {
    if (after.end != null) return -150;
    final gap = nearestDefender(after, after.ball).clamp(0, 6);
    return (gate != null ? 35 : 0) +
        (after.ball.x - before.ball.x) * 75 +
        gap * 1.1 +
        _connections(lesson, after) * 2 +
        (_nearestGate(lesson, before.ball) - _nearestGate(lesson, after.ball)) *
            .7;
  }

  double _learningValue(PracticeSession before, PracticeStep step) {
    final decision = step.decision;
    final after = step.session.state;
    if (after.end != null) return -160 + after.elapsed - before.state.elapsed;
    final rubric = before.lesson.learning.rubric;
    var score = decision.useful ? 7.0 : 0.0;
    score +=
        (decision.pressureAfter.clamp(0, 5) - rubric.minimumPressureGap) * 1.3;
    if (before.settings.passAndMove) {
      if (decision.goalDemonstrated) score += 28;
      final receiver = before.returnTarget;
      if (receiver == null) {
        if (after.completedPasses > before.state.completedPasses) score += 5;
      } else {
        final laneBefore = laneClearance(before.state, before.state.ball,
            _player(before.state, receiver).position);
        final laneAfter = laneClearance(
            after,
            _player(after, before.state.carrierNumber).position,
            _player(after, receiver).position);
        score += (laneAfter - laneBefore).clamp(-3, 3) * 3;
        score += laneAfter.clamp(0, 4);
        if (decision.action.kind == PracticeActionKind.move ||
            decision.action.kind == PracticeActionKind.hold) {
          score += distanceMetres(_player(before.state, receiver).position,
                  _player(after, receiver).position)
              .clamp(0, 2);
        }
      }
      // Cone progress, unrelated passing options, and the authored free-play
      // case goal do not define success in the return-and-move exercise.
      return score;
    }
    score += decision.optionsAfter * 2;
    score += (step.session.reachedGate != null ? 10 : 0);
    switch (before.lesson.skill) {
      case PracticeSkill.firstTouch:
        score += (decision.pressureAfter - decision.pressureBefore) * 2;
        score += decision.optionsAfter * 2;
      case PracticeSkill.drawDefender:
        if (decision.reason == PracticeReason.defenderDrawn) score += 7;
        score += decision.laneAfter.clamp(0, 4);
      case PracticeSkill.throughPass:
        if (decision.reason == PracticeReason.runnerMetInStride) score += 12;
        if (decision.reason == PracticeReason.runnerNotReady) score -= 5;
        if (decision.reason == PracticeReason.holdCreatesWindow) score += 5;
      case PracticeSkill.supportAngle:
        score += (decision.laneAfter - decision.laneBefore) * 3;
        if (decision.reason == PracticeReason.supportLaneOpened) score += 9;
      case PracticeSkill.thirdPlayer:
        if (decision.reason == PracticeReason.thirdPlayerConnected) score += 14;
        score += decision.optionsAfter * 2;
      case PracticeSkill.switchPlay:
        if (decision.reason == PracticeReason.farSideOpened) score += 14;
        score += decision.laneAfter.clamp(0, 5);
    }
    // Progress is one consideration, never the definition of learning success.
    score += (_nearestGate(before.lesson, before.state.ball) -
            _nearestGate(before.lesson, after.ball)) *
        .9;
    return score;
  }

  PracticeDecision _evaluate(PracticeSession session, PracticeAction action,
      List<AttackTransition> transitions, String? gate) {
    final before = session.state;
    // Evidence belongs to the learner's action, before a later teammate error.
    final immediate = transitions.first.after;
    final after = transitions.last.after;
    final queuedRunner = action.kind == PracticeActionKind.hold &&
            session.settings.controlAllAttackers &&
            session.runTargets.isNotEmpty
        ? session.runTargets.containsKey(action.actorNumber)
            ? action.actorNumber
            : session.runTargets.keys.first
        : null;
    final support = action.kind == PracticeActionKind.move ||
        queuedRunner != null ||
        (!session.settings.controlAllAttackers &&
            session.phase == PracticePhase.support);
    final actor = support && !session.settings.controlAllAttackers
        ? 6
        : queuedRunner ?? action.actorNumber ?? before.carrierNumber;
    final learnerBefore = _player(before, actor).position;
    final movementEnd = support ? transitions.last.after : immediate;
    final learnerAfter = _player(movementEnd, actor).position;
    final pressureBefore = nearestDefender(before, before.ball);
    final pressureAfter = nearestDefender(immediate, immediate.ball);
    final laneReceiver = action.receiver ??
        before.attackers
            .where((p) => p.number != before.carrierNumber)
            .reduce((a, b) => laneClearance(before, before.ball, a.position) >
                    laneClearance(before, before.ball, b.position)
                ? a
                : b)
            .number;
    // Compare the same two players before/after, even after the ball changes
    // carrier. This is not a comparison with a different 'best' passing lane.
    final laneBefore = support
        ? laneClearance(before, before.ball, learnerBefore)
        : laneClearance(
            before, learnerBefore, _player(before, laneReceiver).position);
    final laneAfter = support
        ? laneClearance(movementEnd,
            _player(movementEnd, before.carrierNumber).position, learnerAfter)
        : laneClearance(
            immediate, learnerAfter, _player(immediate, laneReceiver).position);
    final optionsBefore = _connections(session.lesson, before);
    final optionsAfter = _connections(session.lesson, immediate);
    var reason = PracticeReason.possessionSecured;
    var useful = immediate.end == null &&
        pressureAfter >= session.lesson.learning.rubric.minimumPressureGap;
    int? evidencePlayer;
    var cue = session.lesson.learning.cues.first;
    final first = transitions.first;
    if (immediate.end == AttackEnd.offside) {
      reason = PracticeReason.offsideAtKick;
      evidencePlayer = action.receiver;
      useful = false;
    } else if (immediate.end != null) {
      reason = action.kind == PracticeActionKind.pass ||
              action.kind == PracticeActionKind.through
          ? PracticeReason.passLaneClosed
          : action.kind == PracticeActionKind.touch
              ? PracticeReason.touchIntoPressure
              : action.kind == PracticeActionKind.hold
                  ? PracticeReason.holdUnderPressure
                  : PracticeReason.carryIntoCover;
      evidencePlayer = first.interceptorNumber;
      useful = false;
    } else if (support) {
      evidencePlayer = actor;
      final angleOpened =
          laneAfter >= session.lesson.learning.rubric.minimumLaneClearance &&
              (laneAfter > laneBefore + .4 ||
                  (!session.settings.controlAllAttackers &&
                      distanceMetres(learnerAfter, immediate.ball) >= 3));
      useful = angleOpened;
      reason = angleOpened
          ? PracticeReason.supportLaneOpened
          : PracticeReason.supportStillHidden;
      cue = PracticeCue.supportLane;
      // Evidence is an actual chain involving three different attackers.
      if (transitions.length > 1 &&
          after.end == null &&
          transitions.last.action.kind == AttackActionKind.pass &&
          after.carrierNumber != 6 &&
          after.carrierNumber != before.carrierNumber &&
          session.history.any((t) =>
              t.before.carrierNumber == 6 &&
              t.after.carrierNumber == before.carrierNumber &&
              t.after.completedPasses > t.before.completedPasses)) {
        reason = PracticeReason.thirdPlayerConnected;
        cue = PracticeCue.thirdPlayerLane;
        evidencePlayer = after.carrierNumber;
        useful = angleOpened || optionsAfter > 0;
      }
    } else if (action.kind == PracticeActionKind.touch) {
      useful =
          pressureAfter >= session.lesson.learning.rubric.minimumPressureGap &&
              (pressureAfter > pressureBefore + .2 || optionsAfter > 0);
      reason = useful
          ? PracticeReason.touchOpensView
          : PracticeReason.touchIntoPressure;
      cue = PracticeCue.pressureSide;
    } else if (action.kind == PracticeActionKind.pass ||
        action.kind == PracticeActionKind.through) {
      final receiver = _player(before, action.receiver!);
      evidencePlayer = receiver.number;
      final travelled = distanceMetres(
          receiver.position, _player(immediate, receiver.number).position);
      final runTarget = session.runTargets[receiver.number];
      final plannedForwardRun = runTarget != null &&
          (runTarget.x - receiver.position.x) * fieldLength >= 1 &&
          distanceMetres(receiver.position, runTarget) >= 1.5;
      final running = plannedForwardRun ||
          (_metres(receiver.velocity).distance >= 1.6 &&
              receiver.velocity.x > .015);
      if (action.kind == PracticeActionKind.through) {
        useful = useful && running && travelled >= 1.0;
        reason = running && travelled >= 1
            ? PracticeReason.runnerMetInStride
            : PracticeReason.runnerNotReady;
        cue = PracticeCue.runnerTiming;
      } else {
        reason = useful
            ? PracticeReason.passToFeet
            : PracticeReason.receivedUnderPressure;
        cue = PracticeCue.passingLane;
      }
      final previousPasses = session.history.where((t) =>
          t.after.end == null &&
          t.after.completedPasses > t.before.completedPasses);
      if (previousPasses.isNotEmpty) {
        final previous = previousPasses.last;
        if (previous.after.carrierNumber == before.carrierNumber &&
            previous.before.carrierNumber != immediate.carrierNumber &&
            before.carrierNumber != immediate.carrierNumber &&
            useful) {
          reason = PracticeReason.thirdPlayerConnected;
          cue = PracticeCue.thirdPlayerLane;
        }
      }
      final lateralChange =
          (immediate.ball.y - before.ball.y).abs() * fieldWidth;
      final oldSide = before.ball.y < .5 ? 0 : 1;
      final defendersOnOldSide = before.defenders
          .where((d) => (d.position.y < .5 ? 0 : 1) == oldSide)
          .length;
      if (lateralChange >= 10 &&
          defendersOnOldSide > before.defenders.length / 2 &&
          pressureAfter > pressureBefore + 1) {
        reason = PracticeReason.farSideOpened;
        cue = PracticeCue.farSideSpace;
        useful = true;
      }
    } else if (action.kind == PracticeActionKind.hold) {
      useful = pressureAfter >= 1.5 &&
          (optionsAfter > optionsBefore || laneAfter > laneBefore + .4);
      reason = useful
          ? PracticeReason.holdCreatesWindow
          : pressureAfter < 2
              ? PracticeReason.holdUnderPressure
              : PracticeReason.possessionSecured;
      cue = PracticeCue.runnerTiming;
    } else {
      final nearest = before.defenders.reduce((a, b) =>
          distanceMetres(a.position, before.ball) <
                  distanceMetres(b.position, before.ball)
              ? a
              : b);
      final later =
          immediate.defenders.firstWhere((d) => d.number == nearest.number);
      final committed = distanceMetres(later.position, before.ball) <
              distanceMetres(nearest.position, before.ball) - .6 &&
          distanceMetres(later.position, nearest.position) > .7;
      if (committed &&
          pressureAfter >= 1.3 &&
          (optionsAfter > optionsBefore || laneAfter > laneBefore + .4)) {
        reason = PracticeReason.defenderDrawn;
        cue = PracticeCue.defenderCommitment;
        evidencePlayer = nearest.number;
        useful = true;
      } else if (pressureAfter < 1.5) {
        reason = PracticeReason.carryIntoCover;
        useful = false;
      }
    }
    if (gate != null && transitions.length == 1 && immediate.end == null) {
      // Finishing the exercise is factual; usefulness remains criterion based.
      reason = PracticeReason.controlledGate;
    }
    final goalDemonstrated = session.settings.passAndMove
        ? _returnGoalDemonstrated(session, action, immediate, useful)
        : useful &&
            switch (session.lesson.skill) {
              PracticeSkill.firstTouch =>
                action.kind == PracticeActionKind.touch,
              PracticeSkill.drawDefender => reason ==
                      PracticeReason.defenderDrawn ||
                  ((action.kind == PracticeActionKind.pass ||
                          action.kind == PracticeActionKind.through) &&
                      laneBefore >=
                          session.lesson.learning.rubric.minimumLaneClearance &&
                      (immediate.ball.x >
                              before.defenders
                                      .map((d) => d.position.x)
                                      .reduce(math.max) +
                                  .02 ||
                          before.defenders.any((d) {
                            final initial = session.lesson.reception.defenders
                                .firstWhere((p) => p.number == d.number);
                            return distanceMetres(d.position, learnerBefore) +
                                    .6 <
                                distanceMetres(initial.position, learnerBefore);
                          }))),
              PracticeSkill.throughPass =>
                reason == PracticeReason.runnerMetInStride ||
                    (reason == PracticeReason.passToFeet &&
                        action.receiver != null &&
                        _player(before, action.receiver!).velocity.x <= .015),
              PracticeSkill.supportAngle =>
                reason == PracticeReason.supportLaneOpened,
              PracticeSkill.thirdPlayer =>
                reason == PracticeReason.thirdPlayerConnected ||
                    ((action.kind == PracticeActionKind.pass ||
                            action.kind == PracticeActionKind.through) &&
                        laneBefore >= 2.5 &&
                        pressureAfter >= 3),
              PracticeSkill.switchPlay =>
                reason == PracticeReason.farSideOpened,
            };
    var travelled = 0.0;
    for (final transition in support ? transitions : [transitions.first]) {
      final samples = transition.motionSamples;
      for (var i = 1; i < samples.length; i++) {
        travelled += distanceMetres(
            support
                ? _player(samples[i - 1], actor).position
                : samples[i - 1].ball,
            support ? _player(samples[i], actor).position : samples[i].ball);
        if (samples[i].carrierIsDefender) break;
      }
    }
    return PracticeDecision(
      before: before,
      phaseBefore: session.phase,
      action: action,
      transitions: List.unmodifiable(transitions),
      reason: reason,
      cue: cue,
      useful: useful,
      goalDemonstrated: goalDemonstrated,
      pressureBefore: pressureBefore,
      pressureAfter: pressureAfter,
      laneBefore: laneBefore,
      laneAfter: laneAfter,
      distance: travelled,
      optionsBefore: optionsBefore,
      optionsAfter: optionsAfter,
      evidencePlayer: evidencePlayer,
      historyLengthBefore: session.history.length,
      decisionsLengthBefore: session.decisions.length,
      settingsBefore: session.settings,
      runTargetsBefore: Map.unmodifiable(session.runTargets),
      returnTargetBefore: session.returnTarget,
    );
  }

  bool _returnGoalDemonstrated(PracticeSession session, PracticeAction action,
      AttackState after, bool useful) {
    final receiver = session.returnTarget;
    if (!useful ||
        receiver == null ||
        action.receiver != receiver ||
        (action.kind != PracticeActionKind.pass &&
            action.kind != PracticeActionKind.through) ||
        after.end != null ||
        after.carrierIsDefender ||
        after.carrierNumber != receiver ||
        after.completedPasses <= session.state.completedPasses ||
        laneClearance(session.state, session.state.ball, action.target) <
            session.lesson.learning.rubric.minimumLaneClearance) {
      return false;
    }
    final outgoing = session.history.where((transition) =>
        transition.before.carrierNumber == receiver &&
        transition.after.carrierNumber == session.state.carrierNumber &&
        transition.after.end == null &&
        transition.after.completedPasses > transition.before.completedPasses);
    if (outgoing.isEmpty) return false;
    // Net relocation from the actual release position means receiving in a
    // different space; walking around and returning to the old spot is not
    // credited. An explicitly led return can complete the commanded run.
    return distanceMetres(_player(outgoing.last.before, receiver).position,
            _player(after, receiver).position) >=
        1;
  }

  ({AttackTransition transition, String? gate}) _execute(
      PracticeCase lesson, AttackState before, PracticeAction action,
      {ScanPassPoint? learnerTarget,
      PracticeSettings settings = const PracticeSettings(),
      Map<int, ScanPassPoint> runTargets = const {}}) {
    final isPass = action.kind == PracticeActionKind.pass ||
        action.kind == PracticeActionKind.through;
    final isMove = action.kind == PracticeActionKind.move;
    final moving = action.kind == PracticeActionKind.carry ||
        action.kind == PracticeActionKind.touch ||
        isMove;
    final receiver = action.receiver ?? before.carrierNumber;
    final target = boundedTarget(action.target);
    final attackAction = isPass
        ? AttackAction.pass(receiver)
        : moving && !isMove
            ? const AttackAction.carry(AttackCarryDirection.forward)
            : const AttackAction.hold();
    final offside =
        isPass && lesson.offsideEnabled ? checkOffside(before, receiver) : null;
    if (offside?.offside == true) {
      return (
        transition: AttackTransition(
            before: before,
            after: before.copyWith(
                end: AttackEnd.offside,
                cue: AttackCue.offside,
                actionCount: before.actionCount + 1),
            action: attackAction,
            duration: 0,
            ballEnd: before.ball,
            offside: offside),
        gate: null,
      );
    }
    final runNumber = isMove ? action.actorNumber ?? 6 : before.carrierNumber;
    final flight = distanceMetres(before.ball, target) / 17;
    final runDistance =
        distanceMetres(_player(before, runNumber).position, target);
    final controlledSpeed = isMove
        ? 6.4
        : action.kind == PracticeActionKind.touch
            ? 4.0
            : 6.0;
    final duration = settings.controlAllAttackers && moving
        ? (runDistance / controlledSpeed + controlledSpeed / 6.2 + .3)
            .clamp(.5, settings.freeFlow ? 12.0 : 5.5)
        : isPass
            ? math.max(.22, flight + .85)
            : isMove
                ? .45
                : moving
                    ? (runDistance /
                                (isMove
                                    ? 5.8
                                    : action.kind == PracticeActionKind.touch
                                        ? 4.6
                                        : 5.2) +
                            .4)
                        .clamp(.45, 5.5)
                    : .5;
    final samples = <AttackState>[before];
    var current = before;
    var caught = false;
    int? interceptor;
    String? gate;
    final steps = (duration / _step).ceil();
    final dt = duration / steps;
    final press = before.defenders
        .reduce((a, b) => distanceMetres(a.position, before.ball) <
                distanceMetres(b.position, before.ball)
            ? a
            : b)
        .number;
    final shield = _shieldTarget(before);
    for (var index = 1; index <= steps; index++) {
      final elapsed = index * dt;
      final attackers = <AttackPlayer>[];
      for (final p in current.attackers) {
        ScanPassPoint aim;
        double speed;
        if (moving && p.number == runNumber) {
          aim = target;
          speed = isMove
              ? 6.4
              : action.kind == PracticeActionKind.touch
                  ? 4
                  : 6.0;
        } else if (isPass && p.number == receiver) {
          aim = settings.freeFlow && settings.automaticSupport
              ? _runThroughTarget(p, runTargets[p.number], target)
              : target;
          speed = 6.4;
        } else if (settings.controlAllAttackers &&
            runTargets.containsKey(p.number) &&
            (p.number != before.carrierNumber ||
                (settings.freeFlow && isPass))) {
          aim = runTargets[p.number]!;
          speed = 6.4;
        } else if (settings.controlAllAttackers) {
          // Only physical braking remains after the scripted observation or a
          // user command. An attacker never invents a new run or shields away.
          aim = p.position;
          speed = 0;
        } else if (p.number == 6 && learnerTarget != null) {
          aim = learnerTarget;
          speed = 6.4;
        } else if (p.number == 6) {
          // Braking is allowed; no new off-ball learner run is invented.
          aim = _player(before, 6).position;
          speed = 0;
        } else if (p.number == before.carrierNumber && !isPass) {
          aim = shield;
          speed = 2.1;
        } else {
          aim = _attackingAim(current, p, lesson.gates, lesson.offsideEnabled);
          speed = 6.2;
        }
        final preserveMomentum = settings.freeFlow &&
            settings.controlAllAttackers &&
            ((moving && p.number == runNumber) ||
                (isPass &&
                    (p.number == receiver ||
                        runTargets.containsKey(p.number))));
        attackers.add(_advance(p, aim, dt, speed,
            stopAtTarget: settings.controlAllAttackers && !preserveMomentum));
      }
      final ball = isPass
          ? before.ball
              .lerp(target, (elapsed / math.max(.05, flight)).clamp(0, 1))
          : attackers
              .firstWhere((p) => p.number == before.carrierNumber)
              .position;
      final defenders = [
        for (final defender in current.defenders)
          _advance(
              defender,
              _defendingAim(current, defender, press, ball, isPass, target),
              dt,
              defender.number == press ? 5.6 : 5.3),
      ];
      var next = current.copyWith(
          attackers: attackers,
          defenders: defenders,
          ball: ball,
          elapsed: before.elapsed + elapsed);
      var collisionAt = 2.0;
      for (final d in current.defenders) {
        final nextD = defenders.firstWhere((p) => p.number == d.number);
        final hit = _collisionFraction(current.ball - d.position,
            next.ball - nextD.position, isPass ? .72 : .65);
        if (hit != null && hit < collisionAt) {
          collisionAt = hit;
          interceptor = d.number;
        }
      }
      var gateAt = 2.0;
      String? crossed;
      if (!isPass) {
        for (final candidate in lesson.gates) {
          if (candidate.crossed(current, next)) {
            final fraction = (candidate.center.x - current.ball.x) /
                (next.ball.x - current.ball.x);
            if (fraction < gateAt) {
              crossed = candidate.id;
              gateAt = fraction;
            }
          }
        }
      }
      if (crossed != null && gateAt < collisionAt) {
        next = _interpolate(current, next, gateAt);
        gate = crossed;
        interceptor = null;
      } else if (interceptor != null) {
        next = _interpolate(current, next, collisionAt);
      }
      current = next;
      samples.add(current);
      if (interceptor != null || gate != null) break;
      if (settings.controlAllAttackers &&
          moving &&
          distanceMetres(_player(current, runNumber).position, target) < .008 &&
          (settings.freeFlow ||
              _metres(_player(current, runNumber).velocity).distance < .1)) {
        break;
      }
      final catchRadius =
          settings.freeFlow && settings.automaticSupport ? .42 : .008;
      if (isPass &&
          elapsed >= flight &&
          distanceMetres(_player(current, receiver).position, ball) <=
              (settings.controlAllAttackers ? catchRadius : .6)) {
        caught = true;
        break;
      }
    }
    // A loose ball is resolved on the same visible samples, never awarded to a
    // distant receiver. Usually the extra .85 s already permits collection.
    if (isPass && !caught && interceptor == null) {
      var extra = 0.0;
      final collectionLimit = settings.freeFlow
          ? math.max(
              2.4,
              distanceMetres(_player(current, receiver).position, target) /
                      6.4 +
                  1.5)
          : 2.4;
      while (extra < collectionLimit && !caught && interceptor == null) {
        extra += _step;
        final attackers = [
          for (final p in current.attackers)
            _advance(
                p,
                p.number == receiver
                    ? settings.freeFlow && settings.automaticSupport
                        ? _runThroughTarget(p, runTargets[p.number], target)
                        : target
                    : runTargets[p.number] ?? p.position,
                _step,
                p.number == receiver || runTargets.containsKey(p.number)
                    ? 6.4
                    : 0,
                stopAtTarget: settings.controlAllAttackers &&
                    !(settings.freeFlow && settings.automaticSupport)),
        ];
        final defenders = [
          for (final d in current.defenders) _advance(d, target, _step, 5.9),
        ];
        var next = current.copyWith(
            attackers: attackers,
            defenders: defenders,
            elapsed: current.elapsed + _step);
        var hitAt = 2.0;
        for (final d in current.defenders) {
          final nextD = defenders.firstWhere((p) => p.number == d.number);
          final hit = _collisionFraction(
              current.ball - d.position, next.ball - nextD.position, .72);
          if (hit != null && hit < hitAt) {
            hitAt = hit;
            interceptor = d.number;
          }
        }
        if (interceptor != null) next = _interpolate(current, next, hitAt);
        current = next;
        samples.add(current);
        final catchRadius =
            settings.freeFlow && settings.automaticSupport ? .42 : .008;
        caught = distanceMetres(_player(current, receiver).position, target) <=
            (settings.controlAllAttackers ? catchRadius : .6);
      }
    }
    if (isPass &&
        caught &&
        interceptor == null &&
        settings.freeFlow &&
        settings.automaticSupport) {
      final receiverPlayer = _player(current, receiver);
      final ballGap = distanceMetres(current.ball, receiverPlayer.position);
      if (ballGap > .05) {
        final start = current;
        const settleSteps = 5;
        for (var i = 1; i <= settleSteps && interceptor == null; i += 1) {
          final attackers = [
            for (final p in current.attackers)
              _advance(
                p,
                p.number == receiver
                    ? _runThroughTarget(p, runTargets[p.number], target)
                    : runTargets[p.number] ?? p.position,
                _step,
                p.number == receiver || runTargets.containsKey(p.number)
                    ? 6.0
                    : 0,
              ),
          ];
          final receiverNow = attackers.firstWhere((p) => p.number == receiver);
          final defenders = [
            for (final d in current.defenders)
              _advance(
                d,
                _defendingAim(current, d, press, current.ball, true, target),
                _step,
                d.number == press ? 5.6 : 5.3,
              ),
          ];
          final next = current.copyWith(
            attackers: attackers,
            defenders: defenders,
            ball: start.ball.lerp(receiverNow.position, i / settleSteps),
            elapsed: current.elapsed + _step,
          );
          var hitAt = 2.0;
          for (final d in current.defenders) {
            final nextD = defenders.firstWhere((p) => p.number == d.number);
            final hit = _collisionFraction(
                current.ball - d.position, next.ball - nextD.position, .72);
            if (hit != null && hit < hitAt) {
              hitAt = hit;
              interceptor = d.number;
            }
          }
          current =
              interceptor == null ? next : _interpolate(current, next, hitAt);
          samples.add(current);
        }
        caught = interceptor == null;
      }
    }
    if (interceptor != null) {
      current = current.copyWith(
          carrierNumber: interceptor,
          carrierIsDefender: true,
          end: AttackEnd.intercepted,
          cue: AttackCue.intercepted);
      samples[samples.length - 1] = current;
      // Contact transfers possession at the real collision location. The ball
      // then settles at the defender's foot continuously while they take it
      // away; no attacker is falsely left as owner of a stolen ball.
      final defender = current.carrier;
      final collectOffset = current.ball - defender.position;
      final collectionStart = current.elapsed;
      final escape = boundedTarget(
          defender.position + _normalized(const ScanPassPoint(-1.3, .35)));
      for (var i = 1; i <= 16; i++) {
        final defenders = [
          for (final d in current.defenders)
            _advance(d, d.number == interceptor ? escape : d.position, _step,
                d.number == interceptor ? 4.0 : 0),
        ];
        final owner = defenders.firstWhere((d) => d.number == interceptor);
        final remainingOffset = (1 - i * _step / .16).clamp(0.0, 1.0);
        current = current.copyWith(
          attackers: [
            for (final p in current.attackers) _advance(p, p.position, _step, 0)
          ],
          defenders: defenders,
          ball: owner.position + collectOffset * remainingOffset,
          elapsed: collectionStart + i * _step,
        );
        samples.add(current);
      }
    }
    final after = current.copyWith(
      carrierNumber: interceptor ?? (caught ? receiver : before.carrierNumber),
      carrierIsDefender: interceptor != null,
      completedPasses:
          before.completedPasses + (caught && interceptor == null ? 1 : 0),
      actionCount: before.actionCount + 1,
      furthestX: math.max(before.furthestX, current.ball.x),
      end: interceptor == null ? null : AttackEnd.intercepted,
      cue: interceptor != null
          ? AttackCue.intercepted
          : isPass
              ? AttackCue.received
              : moving
                  ? AttackCue.carried
                  : AttackCue.waited,
    );
    samples[samples.length - 1] = after;
    return (
      transition: AttackTransition(
        before: before,
        after: after,
        action: attackAction,
        duration: after.elapsed - before.elapsed,
        ballEnd: after.ball,
        offside: offside,
        interceptorNumber: interceptor,
        motionSamples: List.unmodifiable(samples),
      ),
      gate: gate,
    );
  }

  static PracticeCase _createCase(PracticeSkill skill, int variant) {
    final count = switch (skill) {
      PracticeSkill.firstTouch ||
      PracticeSkill.drawDefender ||
      PracticeSkill.throughPass =>
        2,
      PracticeSkill.supportAngle || PracticeSkill.thirdPlayer => 3,
      PracticeSkill.switchPlay => 4,
    };
    final defenders = skill.index < 2
        ? 1
        : skill == PracticeSkill.switchPlay
            ? 3
            : 2;
    final middle = skill == PracticeSkill.switchPlay ? .25 : .52;
    final learner = ScanPassPoint(.34, middle);
    final attackers = [
      AttackPlayer(number: 6, position: learner),
      AttackPlayer(
          number: 8,
          position: ScanPassPoint(
              skill == PracticeSkill.firstTouch
                  ? .40
                  : skill == PracticeSkill.thirdPlayer
                      ? .425
                      : .46,
              skill == PracticeSkill.switchPlay
                  ? .38
                  : skill == PracticeSkill.thirdPlayer
                      ? .232
                      : .25),
          velocity: ScanPassPoint(
              skill == PracticeSkill.throughPass && variant == 1 ? -.05 : .085,
              .012)),
      if (count >= 3)
        AttackPlayer(
            number: 9,
            position: ScanPassPoint(
                skill == PracticeSkill.thirdPlayer ? .565 : .48,
                skill == PracticeSkill.switchPlay ? .78 : .75),
            velocity: const ScanPassPoint(.07, -.015)),
      if (count == 4)
        const AttackPlayer(number: 4, position: ScanPassPoint(.27, .84)),
    ];
    final opponents = [
      AttackPlayer(
          number: 2,
          opponent: true,
          position: switch (skill) {
            PracticeSkill.firstTouch =>
              ScanPassPoint(.435, variant == 0 ? .39 : .65),
            PracticeSkill.drawDefender => const ScanPassPoint(.55, .43),
            PracticeSkill.throughPass => const ScanPassPoint(.61, .43),
            PracticeSkill.supportAngle => const ScanPassPoint(.52, .43),
            PracticeSkill.thirdPlayer => const ScanPassPoint(.513, .345),
            PracticeSkill.switchPlay => const ScanPassPoint(.49, .25),
          },
          velocity: switch (skill) {
            PracticeSkill.drawDefender => variant == 0
                ? const ScanPassPoint(-.095, .025)
                : const ScanPassPoint(.075, -.085),
            PracticeSkill.supportAngle ||
            PracticeSkill.thirdPlayer =>
              variant == 0
                  ? const ScanPassPoint(-.035, .085)
                  : const ScanPassPoint(-.035, -.085),
            PracticeSkill.firstTouch =>
              ScanPassPoint(-.015, variant == 0 ? .012 : -.012),
            _ => const ScanPassPoint(-.035, .04),
          }),
      if (defenders >= 2)
        AttackPlayer(
            number: 3,
            opponent: true,
            position: skill == PracticeSkill.switchPlay
                ? const ScanPassPoint(.64, .38)
                : skill == PracticeSkill.thirdPlayer
                    ? const ScanPassPoint(.623, .562)
                    : const ScanPassPoint(.66, .68),
            velocity: const ScanPassPoint(-.02, -.018)),
      if (defenders == 3)
        AttackPlayer(
            number: 5,
            opponent: true,
            position: const ScanPassPoint(.62, .24),
            velocity: variant == 0
                ? const ScanPassPoint(-.02, -.06)
                : const ScanPassPoint(-.02, .14)),
    ];
    final before = AttackState(
      attackers: attackers,
      defenders: opponents,
      ball: attackers[1].position,
      carrierNumber: 8,
    );
    // Observe a genuine incoming pass. A short authored reaction phase keeps
    // the paired variable legible before the decision clock pauses.
    const duration = .65;
    final samples = <AttackState>[before];
    for (var index = 1; index <= 26; index++) {
      final t = index / 26;
      final seconds = duration * t;
      samples.add(before.copyWith(
        attackers: [
          for (final p in attackers)
            p.copyWith(
                position: boundedTarget(p.position + p.velocity * seconds)),
        ],
        defenders: [
          for (final p in opponents)
            p.copyWith(
                position: boundedTarget(p.position + p.velocity * seconds)),
        ],
        ball: before.ball.lerp(learner, t),
        elapsed: seconds,
      ));
    }
    final reception = samples.last.copyWith(
        carrierNumber: 6, completedPasses: 1, cue: AttackCue.received);
    samples[samples.length - 1] = reception;
    final cues = switch (skill) {
      PracticeSkill.firstTouch => [
          PracticeCue.pressureSide,
          PracticeCue.passingLane
        ],
      PracticeSkill.drawDefender => [
          PracticeCue.defenderCommitment,
          PracticeCue.passingLane
        ],
      PracticeSkill.throughPass => [
          PracticeCue.runnerTiming,
          PracticeCue.passingLane
        ],
      PracticeSkill.supportAngle => [
          PracticeCue.supportLane,
          PracticeCue.pressureSide
        ],
      PracticeSkill.thirdPlayer => [
          PracticeCue.thirdPlayerLane,
          PracticeCue.supportLane
        ],
      PracticeSkill.switchPlay => [
          PracticeCue.farSideSpace,
          PracticeCue.passingLane
        ],
    };
    return PracticeCase(
      id: '${skill.name}-$variant',
      skill: skill,
      variant: variant,
      stage: count,
      offsideEnabled: skill == PracticeSkill.switchPlay,
      gates: const [
        PracticeGate(id: 'upper', center: ScanPassPoint(.88, .23)),
        PracticeGate(id: 'lower', center: ScanPassPoint(.88, .77)),
      ],
      observation: AttackTransition(
        before: before,
        after: reception,
        action: const AttackAction.pass(6),
        duration: duration,
        ballEnd: learner,
        motionSamples: List.unmodifiable(samples),
      ),
      learning: PracticeLearningDefinition(
        goal: skill,
        cues: List.unmodifiable(cues),
        mistakes: List.unmodifiable(switch (skill) {
          PracticeSkill.firstTouch => [PracticeReason.touchIntoPressure],
          PracticeSkill.drawDefender => [PracticeReason.carryIntoCover],
          PracticeSkill.throughPass => [
              PracticeReason.runnerNotReady,
              PracticeReason.offsideAtKick
            ],
          PracticeSkill.supportAngle => [PracticeReason.supportStillHidden],
          PracticeSkill.thirdPlayer => [
              PracticeReason.passLaneClosed,
              PracticeReason.supportStillHidden
            ],
          PracticeSkill.switchPlay => [
              PracticeReason.carryIntoCover,
              PracticeReason.passLaneClosed
            ],
        }),
        rubric: PracticeRubric(
          requireMovingReceiver: skill == PracticeSkill.throughPass,
          requireThirdPlayer: skill == PracticeSkill.thirdPlayer,
          requireSwitch: skill == PracticeSkill.switchPlay,
        ),
      ),
    );
  }

  static ScanPassPoint _attackingAim(AttackState state, AttackPlayer player,
      List<PracticeGate> gates, bool offsideEnabled) {
    final ball = state.ball;
    final gap = distanceMetres(player.position, ball);
    // A checking runner first comes within supporting distance; then turns.
    if (player.velocity.x < -.012 && gap > 6.8) {
      return boundedTarget(ScanPassPoint(ball.x + .02, player.position.y));
    }
    final upper = player.position.y < .5;
    final line =
        offsideEnabled ? checkOffside(state, player.number).lineX - .025 : .94;
    final gate = gates.firstWhere((g) => upper == (g.center.y < .5));
    if (player.number == 4) {
      return boundedTarget(ScanPassPoint(ball.x - .08, player.position.y));
    }
    return boundedTarget(ScanPassPoint(
        math.min(math.min(gate.center.x - .055, line),
            math.max(player.position.x + .08, ball.x + .24)),
        gate.center.y + (upper ? .015 : -.015)));
  }

  static ScanPassPoint _defendingAim(AttackState state, AttackPlayer player,
      int presser, ScanPassPoint ball, bool pass, ScanPassPoint destination) {
    // Movement commitment remains visible for .8 s after reception. It is
    // derived from velocity, not a scenario-id condition switch.
    if (state.elapsed < 1.45) {
      return boundedTarget(player.position + player.velocity * .35);
    }
    if (player.number == presser) {
      return boundedTarget(pass ? ball.lerp(destination, .18) : ball);
    }
    final threats = state.attackers
        .where((p) => p.number != state.carrierNumber)
        .toList()
      ..sort((a, b) => distanceMetres(a.position, player.position)
          .compareTo(distanceMetres(b.position, player.position)));
    final threat = threats.first.position;
    return boundedTarget(ball.lerp(threat, .72) + const ScanPassPoint(.055, 0));
  }

  static ScanPassPoint _shieldTarget(AttackState state) {
    final nearest = state.defenders.reduce((a, b) =>
        distanceMetres(a.position, state.ball) <
                distanceMetres(b.position, state.ball)
            ? a
            : b);
    final away = _metres(state.ball - nearest.position);
    if (away.distance >= 3 || away.distance < .001) {
      return state.carrier.position;
    }
    return boundedTarget(
        state.carrier.position + _normalized(away * (1 / away.distance)));
  }

  static ScanPassPoint _throughTarget(
      AttackState state, AttackPlayer receiver) {
    final speed = _metres(receiver.velocity);
    final flight = distanceMetres(state.ball, receiver.position) / 17;
    // The pass is deliberately into future space. A checking runner takes time
    // to reverse direction and cannot be treated as already sprinting forwards.
    final lead = ScanPassPoint(
        math.max(2.5, math.max(0, speed.x) * (flight + .4)), speed.y * flight);
    final proposed = receiver.position + _normalized(lead);
    return boundedTarget(ScanPassPoint(math.min(.855, proposed.x), proposed.y));
  }

  static ScanPassPoint _runThroughTarget(
      AttackPlayer player, ScanPassPoint? runTarget, ScanPassPoint fallback) {
    final anchor = runTarget ?? fallback;
    var direction = _metres(anchor - player.position);
    if (direction.distance < .2) {
      direction = _metres(player.velocity);
    }
    if (direction.distance < .2) return anchor;
    final unit = direction * (1 / direction.distance);
    return boundedTarget(anchor + _normalized(unit * 1.4));
  }

  static AttackPlayer _advance(
      AttackPlayer player, ScanPassPoint target, double dt, double maxSpeed,
      {bool stopAtTarget = false}) {
    final delta = _metres(target - player.position);
    final old = _metres(player.velocity);
    const acceleration = 6.2;
    final speed =
        math.min(maxSpeed, math.sqrt(2 * acceleration * delta.distance));
    final desired = delta.distance < .005
        ? const ScanPassPoint(0, 0)
        : delta * (speed / delta.distance);
    final change = desired - old;
    var velocity = old +
        (change.distance <= acceleration * dt
            ? change
            : change * (acceleration * dt / change.distance));
    var movement = velocity * dt;
    if (stopAtTarget &&
        maxSpeed > 0 &&
        ((movement.distance >= delta.distance && movement.dot(delta) > 0) ||
            delta.distance < .005)) {
      movement = delta;
      velocity = const ScanPassPoint(0, 0);
    } else if (!stopAtTarget &&
        movement.distance > delta.distance &&
        movement.dot(delta) > 0) {
      movement = delta;
      velocity = movement * (1 / dt);
    }
    final position = boundedTarget(player.position + _normalized(movement));
    return player.copyWith(
      position: position,
      velocity: _normalized(velocity),
      facingRadians: velocity.distance < .02
          ? player.facingRadians
          : math.atan2(velocity.y, velocity.x),
    );
  }

  static double? _collisionFraction(
      ScanPassPoint relativeStart, ScanPassPoint relativeEnd, double radius) {
    final start = _metres(relativeStart);
    final delta = _metres(relativeEnd - relativeStart);
    final c = start.dot(start) - radius * radius;
    if (c <= 0) return 0;
    final a = delta.dot(delta);
    if (a < 1e-10) return null;
    final b = 2 * start.dot(delta);
    final discriminant = b * b - 4 * a * c;
    if (discriminant < 0) return null;
    final root = (-b - math.sqrt(discriminant)) / (2 * a);
    return root >= 0 && root <= 1 ? root : null;
  }

  static AttackState _interpolate(AttackState a, AttackState b, double t) {
    List<AttackPlayer> people(List<AttackPlayer> x, List<AttackPlayer> y) {
      final byNumber = {for (final p in y) p.number: p};
      return [
        for (final p in x)
          p.copyWith(
            position: p.position.lerp(byNumber[p.number]!.position, t),
            velocity: p.velocity.lerp(byNumber[p.number]!.velocity, t),
            facingRadians: _lerpRadians(
                p.facingRadians, byNumber[p.number]!.facingRadians, t),
          ),
      ];
    }

    return a.copyWith(
      attackers: people(a.attackers, b.attackers),
      defenders: people(a.defenders, b.defenders),
      ball: a.ball.lerp(b.ball, t),
      elapsed: a.elapsed + (b.elapsed - a.elapsed) * t,
    );
  }

  static int _connections(PracticeCase lesson, AttackState state) => state
      .attackers
      .where((p) =>
          p.number != state.carrierNumber &&
          distanceMetres(p.position, state.ball) > 2 &&
          laneClearance(state, state.ball, p.position) >=
              lesson.learning.rubric.minimumLaneClearance &&
          (!lesson.offsideEnabled || !checkOffside(state, p.number).offside))
      .length;

  static double _nearestGate(PracticeCase lesson, ScanPassPoint point) =>
      lesson.gates.map((g) => distanceMetres(point, g.center)).reduce(math.min);

  static AttackPlayer _player(AttackState state, int number) =>
      state.attackers.firstWhere((p) => p.number == number);
  static ScanPassPoint _metres(ScanPassPoint point) =>
      ScanPassPoint(point.x * fieldLength, point.y * fieldWidth);
  static ScanPassPoint _normalized(ScanPassPoint point) =>
      ScanPassPoint(point.x / fieldLength, point.y / fieldWidth);
  static AttackPlayer _projectRunner(
      AttackPlayer player, ScanPassPoint target, double seconds,
      {required double maxSpeed}) {
    var projected = player;
    var remaining = seconds.clamp(0.0, 1.2).toDouble();
    while (remaining > 1e-9) {
      final dt = math.min(_step, remaining);
      projected = _advance(projected, target, dt, maxSpeed);
      remaining -= dt;
    }
    return projected;
  }

  static double _lerpRadians(double start, double end, double t) =>
      start + _angleDelta(end, start) * t;
  static double _angleDelta(double target, double current) {
    var delta = (target - current) % (math.pi * 2);
    if (delta > math.pi) delta -= math.pi * 2;
    if (delta < -math.pi) delta += math.pi * 2;
    return delta;
  }

  static ScanPassPoint _toward(
      ScanPassPoint from, ScanPassPoint target, double metres) {
    final distance = distanceMetres(from, target);
    return boundedTarget(from.lerp(
        target, distance < .001 ? 1 : math.min(1, metres / distance)));
  }

  static double _segmentDistance(
      ScanPassPoint point, ScanPassPoint from, ScanPassPoint to) {
    final delta = _metres(to - from);
    final relative = _metres(point - from);
    final t = delta.dot(delta) < 1e-9
        ? 0.0
        : (relative.dot(delta) / delta.dot(delta)).clamp(0.0, 1.0);
    return (relative - delta * t).distance;
  }
}
