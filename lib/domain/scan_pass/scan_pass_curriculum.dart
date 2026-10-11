import 'dart:math' as math;

import 'scan_pass_attack.dart';
import 'scan_pass_game.dart' show ScanPassPoint;

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
    if (before.carrierNumber != after.carrierNumber ||
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

  const PracticeAction({
    required this.id,
    required this.kind,
    required this.target,
    this.receiver,
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

  const PracticeSession({
    required this.lesson,
    required this.state,
    required this.phase,
    this.decisions = const [],
    this.history = const [],
    this.outcome,
    this.reachedGate,
  });

  bool get finished => phase == PracticePhase.finished;
  bool get goalDemonstrated => decisions.any((d) => d.goalDemonstrated);
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
  static const double _step = .025;
  static final List<PracticeCase> catalog = List.unmodifiable([
    for (final skill in PracticeSkill.values)
      for (var variant = 0; variant < 2; variant++) _createCase(skill, variant),
  ]);

  const PracticeEngine();

  PracticeSession start(PracticeCase lesson) => PracticeSession(
        lesson: lesson,
        state: lesson.reception,
        phase: PracticePhase.firstTouch,
        history: [lesson.observation],
      );

  PracticeSession beforeDecision(PracticeSession session, int index) {
    final decision = session.decisions[index];
    return PracticeSession(
      lesson: session.lesson,
      state: decision.before,
      phase: decision.phaseBefore,
      decisions: List.unmodifiable(
          session.decisions.take(decision.decisionsLengthBefore)),
      history:
          List.unmodifiable(session.history.take(decision.historyLengthBefore)),
    );
  }

  List<PracticeAction> choices(PracticeSession session) {
    if (session.finished) return const [];
    final state = session.state;
    final learner = _player(state, 6);
    if (session.phase == PracticePhase.firstTouch) {
      return [
        for (final entry in [
          ('forward', const ScanPassPoint(2.1, 0)),
          ('upper', const ScanPassPoint(.7, -2.1)),
          ('lower', const ScanPassPoint(.7, 2.1)),
        ])
          PracticeAction(
              id: 'touch-${entry.$1}',
              kind: PracticeActionKind.touch,
              target: boundedTarget(learner.position + _normalized(entry.$2))),
      ];
    }
    if (session.phase == PracticePhase.support) {
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
    return _ballChoices(session.lesson, state);
  }

  PracticeStep moveTo(PracticeSession session, ScanPassPoint target) => choose(
      session,
      PracticeAction(
          id: session.phase == PracticePhase.support
              ? 'move-custom'
              : 'carry-custom',
          kind: session.phase == PracticePhase.support
              ? PracticeActionKind.move
              : PracticeActionKind.carry,
          target: _toward(
              _player(session.state, 6).position,
              boundedTarget(target),
              session.phase == PracticePhase.support ? 8 : 5.8)));

  PracticeStep choose(PracticeSession session, PracticeAction action) {
    if (session.finished) {
      throw StateError('Cannot choose after a completed exercise');
    }
    if (action.kind == PracticeActionKind.move &&
        session.phase != PracticePhase.support) {
      throw ArgumentError('Off-ball movement requires support phase');
    }
    if (session.phase == PracticePhase.support &&
        action.kind != PracticeActionKind.move &&
        action.kind != PracticeActionKind.hold) {
      throw ArgumentError(
          'Choose a learner movement while a teammate has ball');
    }
    final result = _execute(session.lesson, session.state, action);
    final transitions = <AttackTransition>[result.transition];
    var state = result.transition.after;
    var gate = result.gate;
    // A support choice grants the teammate one independent football decision.
    // The learner never receives a forced return and never runs automatically.
    if (session.phase == PracticePhase.support &&
        state.end == null &&
        gate == null) {
      final continuation = _teammateAction(session.lesson, state);
      final continued = _execute(session.lesson, state, continuation,
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
                : decisions.length >= decisionLimit
                    ? PracticeOutcome.retained
                    : null;
    final updated = PracticeSession(
      lesson: session.lesson,
      state: state,
      phase: outcome != null
          ? PracticePhase.finished
          : state.carrierNumber == 6
              ? PracticePhase.onBall
              : PracticePhase.support,
      decisions: List.unmodifiable(decisions),
      history: List.unmodifiable([...session.history, ...transitions]),
      outcome: outcome,
      reachedGate: gate,
    );
    return PracticeStep(
        session: updated,
        transitions: List.unmodifiable(transitions),
        decision: decision);
  }

  List<PracticeAction> rankedChoices(PracticeSession session) {
    final scored = [
      for (final action in choices(session))
        (action: action, value: _rankValue(session, choose(session, action))),
    ]..sort((a, b) => b.value.compareTo(a.value));
    return List.unmodifiable(scored.map((entry) => entry.action));
  }

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
  PracticeSession coachRun(PracticeCase lesson) {
    var session = start(lesson);
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
    var beam = [(session: start(lesson), value: 0.0)];
    for (var depth = 0; depth < decisionLimit; depth++) {
      final next = <({PracticeSession session, double value})>[];
      final completed = <({PracticeSession session, double value})>[];
      for (final branch in beam) {
        for (final action in choices(branch.session)) {
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

  List<PracticeAction> _ballChoices(PracticeCase lesson, AttackState state) => [
        for (final gate in lesson.gates)
          PracticeAction(
            id: 'carry-${gate.id}',
            kind: PracticeActionKind.carry,
            target: _toward(state.carrier.position,
                ScanPassPoint(gate.center.x + .045, gate.center.y), 5.8),
          ),
        for (final p in state.attackers
            .where((player) => player.number != state.carrierNumber)) ...[
          PracticeAction(
              id: 'pass-${p.number}',
              kind: PracticeActionKind.pass,
              target: p.position,
              receiver: p.number),
          PracticeAction(
              id: 'through-${p.number}',
              kind: PracticeActionKind.through,
              target: _throughTarget(state, p),
              receiver: p.number),
        ],
        PracticeAction(
            id: 'hold',
            kind: PracticeActionKind.hold,
            target: state.carrier.position),
      ];

  PracticeAction _teammateAction(PracticeCase lesson, AttackState state) {
    final candidates = _ballChoices(lesson, state);
    var best = candidates.last;
    var value = double.negativeInfinity;
    for (final action in candidates) {
      final result = _execute(lesson, state, action);
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
    final support = session.phase == PracticePhase.support;
    final learnerBefore = _player(before, 6).position;
    final movementEnd = support ? transitions.last.after : immediate;
    final learnerAfter = _player(movementEnd, 6).position;
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
              : PracticeReason.carryIntoCover;
      evidencePlayer = first.interceptorNumber;
      useful = false;
    } else if (support) {
      final angleOpened =
          laneAfter >= session.lesson.learning.rubric.minimumLaneClearance &&
              (laneAfter > laneBefore + .4 ||
                  distanceMetres(learnerAfter, immediate.ball) >= 3);
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
      final running = _metres(receiver.velocity).distance >= 1.6 &&
          receiver.velocity.x > .015;
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
    final goalDemonstrated = useful &&
        switch (session.lesson.skill) {
          PracticeSkill.firstTouch => action.kind == PracticeActionKind.touch,
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
                        return distanceMetres(d.position, learnerBefore) + .6 <
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
          PracticeSkill.switchPlay => reason == PracticeReason.farSideOpened,
        };
    var travelled = 0.0;
    for (final transition in support ? transitions : [transitions.first]) {
      final samples = transition.motionSamples;
      for (var i = 1; i < samples.length; i++) {
        travelled += distanceMetres(
            support ? _player(samples[i - 1], 6).position : samples[i - 1].ball,
            support ? _player(samples[i], 6).position : samples[i].ball);
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
    );
  }

  ({AttackTransition transition, String? gate}) _execute(
      PracticeCase lesson, AttackState before, PracticeAction action,
      {ScanPassPoint? learnerTarget}) {
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
    final runNumber = isMove ? 6 : before.carrierNumber;
    final flight = distanceMetres(before.ball, target) / 17;
    final runDistance =
        distanceMetres(_player(before, runNumber).position, target);
    final duration = isPass
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
          aim = target;
          speed = 6.4;
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
        attackers.add(_advance(p, aim, dt, speed));
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
      if (isPass &&
          elapsed >= flight &&
          distanceMetres(_player(current, receiver).position, ball) <= .6) {
        caught = true;
        break;
      }
    }
    // A loose ball is resolved on the same visible samples, never awarded to a
    // distant receiver. Usually the extra .85 s already permits collection.
    if (isPass && !caught && interceptor == null) {
      var extra = 0.0;
      while (extra < 2.4 && !caught && interceptor == null) {
        extra += _step;
        final attackers = [
          for (final p in current.attackers)
            _advance(p, p.number == receiver ? target : p.position, _step,
                p.number == receiver ? 6.4 : 0),
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
        caught =
            distanceMetres(_player(current, receiver).position, target) <= .6;
      }
    }
    final after = current.copyWith(
      carrierNumber:
          caught && interceptor == null ? receiver : before.carrierNumber,
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

  static AttackPlayer _advance(
      AttackPlayer player, ScanPassPoint target, double dt, double maxSpeed) {
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
    if (movement.distance > delta.distance && movement.dot(delta) > 0) {
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
    List<AttackPlayer> people(List<AttackPlayer> x, List<AttackPlayer> y) => [
          for (final p in x)
            p.copyWith(
              position: p.position
                  .lerp(y.firstWhere((q) => q.number == p.number).position, t),
              velocity: p.velocity
                  .lerp(y.firstWhere((q) => q.number == p.number).velocity, t),
              facingRadians:
                  y.firstWhere((q) => q.number == p.number).facingRadians,
            ),
        ];
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
