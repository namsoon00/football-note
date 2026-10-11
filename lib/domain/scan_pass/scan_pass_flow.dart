import 'dart:math' as math;

import 'scan_pass_attack.dart';
import 'scan_pass_curriculum.dart';
import 'scan_pass_game.dart' show ScanPassPoint;

/// Every focus can be learned with two attackers and two actual defenders.
enum FlowFocus {
  firstTouch,
  drawDefender,
  supportAngle,
  throughPass,
  beatCover,
  changeLane,
}

class FlowCase {
  final PracticeCase lesson;
  final FlowFocus focus;

  const FlowCase({required this.lesson, required this.focus});
}

/// Focus is typed lesson data, never inferred from a case id or its label.
class _FlowLesson extends PracticeCase {
  final FlowFocus focus;

  _FlowLesson(FlowCase item)
      : focus = item.focus,
        super(
          id: item.lesson.id,
          skill: item.lesson.skill,
          variant: item.lesson.variant,
          stage: item.lesson.stage,
          offsideEnabled: item.lesson.offsideEnabled,
          gates: item.lesson.gates,
          observation: item.lesson.observation,
          learning: item.lesson.learning,
        );
}

/// One field, one clicked destination, and one decision at each reception.
/// Opposition, ball collisions and replay share PracticeEngine's samples.
class FlowEngine {
  static const touchLimitMetres = PracticeEngine.freeFlowTouchLimit;
  static final List<FlowCase> catalog = List.unmodifiable([
    for (final focus in FlowFocus.values)
      for (var variant = 0; variant < 2; variant++) _createCase(focus, variant),
  ]);
  static const _settings = PracticeSettings(freeFlow: true);
  static const _engine = PracticeEngine();

  const FlowEngine();

  PracticeSession start(FlowCase item) {
    if (item.lesson.reception.attackers.length != 2 ||
        item.lesson.reception.defenders.length != 2) {
      throw ArgumentError(
          'A flow case requires two attackers and two defenders');
    }
    return _engine.start(_FlowLesson(item), settings: _settings);
  }

  /// The UI draws this exact 2.3 m physical range and endpoint.
  ScanPassPoint touchTarget(PracticeSession session, ScanPassPoint target) {
    _finite(target);
    final origin = session.state.carrier.position;
    final bounded = PracticeEngine.boundedTarget(target);
    final distance = PracticeEngine.distanceMetres(origin, bounded);
    return origin.lerp(bounded,
        distance <= touchLimitMetres ? 1 : touchLimitMetres / distance);
  }

  PracticeStep touchTo(PracticeSession session, ScanPassPoint target) =>
      _result(
          session,
          _engine.choose(
              session,
              PracticeAction(
                id: 'flow-touch',
                kind: PracticeActionKind.touch,
                actorNumber: session.state.carrierNumber,
                target: touchTarget(session, target),
              )));

  /// Carries and explicit off-ball runs retain the entire bounded destination.
  PracticeStep moveTo(PracticeSession session, ScanPassPoint target,
          {int? playerNumber}) =>
      _result(
          session, _engine.moveTo(session, target, playerNumber: playerNumber));

  ScanPassPoint? throughTarget(PracticeSession session) {
    final receiver = _other(session);
    final target = session.runTargets[receiver.number];
    return target != null &&
            PracticeEngine.distanceMetres(receiver.position, target) > .08
        ? target
        : null;
  }

  /// Selecting the pass alone does not advance time. Once its passer's support
  /// destination is supplied, both commands begin on the same first sample.
  PracticeStep passAndMove(PracticeSession session,
      {required ScanPassPoint runTarget, bool through = false}) {
    _finite(runTarget);
    final receiver = _other(session);
    final target = through ? throughTarget(session) : receiver.position;
    if (target == null) {
      throw ArgumentError('Lead a run that the player has already commanded');
    }
    final planned = _copy(session,
        runTargets: Map.unmodifiable({
          ...session.runTargets,
          session.state.carrierNumber: PracticeEngine.boundedTarget(runTarget),
        }));
    return _result(
        planned,
        _engine.choose(
            planned,
            PracticeAction(
              id: through ? 'flow-through' : 'flow-pass',
              kind: through
                  ? PracticeActionKind.through
                  : PracticeActionKind.pass,
              actorNumber: session.state.carrierNumber,
              receiver: receiver.number,
              target: target,
            )));
  }

  PracticeStep hold(PracticeSession session) => _result(
      session,
      _engine.choose(
          session,
          PracticeAction(
            id: 'flow-hold',
            kind: PracticeActionKind.hold,
            actorNumber: session.state.carrierNumber,
            target: session.state.ball,
          )));

  PracticeSession beforeDecision(PracticeSession session, int index) =>
      _engine.beforeDecision(session, index);

  static AttackPlayer _other(PracticeSession session) => session.state.attackers
      .firstWhere((p) => p.number != session.state.carrierNumber);

  static void _finite(ScanPassPoint point) {
    if (!point.x.isFinite || !point.y.isFinite) {
      throw ArgumentError('A field destination must be finite');
    }
  }

  PracticeStep _result(PracticeSession before, PracticeStep step) {
    final lesson = before.lesson;
    if (lesson is! _FlowLesson) {
      throw ArgumentError('Start this session through FlowEngine');
    }
    final d = step.decision;
    final after = step.session.state;
    final actor = d.action.actorNumber ?? before.state.carrierNumber;
    final actorBefore =
        before.state.attackers.firstWhere((p) => p.number == actor);
    final actorAfter = after.attackers.firstWhere((p) => p.number == actor);
    final pass = d.action.kind == PracticeActionKind.pass ||
        d.action.kind == PracticeActionKind.through;
    final movement = d.action.kind == PracticeActionKind.touch ||
        d.action.kind == PracticeActionKind.carry;
    final safe = d.useful && after.end == null;
    final goal = safe &&
        switch (lesson.focus) {
          FlowFocus.firstTouch => d.action.kind == PracticeActionKind.touch &&
              d.pressureAfter >= lesson.learning.rubric.minimumPressureGap &&
              (d.pressureAfter > d.pressureBefore + .2 || d.optionsAfter > 0),
          FlowFocus.drawDefender => d.reason == PracticeReason.defenderDrawn ||
              (pass &&
                  d.laneBefore >= 1 &&
                  after.ball.x >
                      before.state.defenders
                              .map((p) => p.position.x)
                              .reduce(math.min) +
                          .02),
          FlowFocus.supportAngle => _receivedInNewSpace(before, d),
          FlowFocus.throughPass =>
            d.action.kind == PracticeActionKind.through &&
                before.runTargets[d.action.receiver] != null &&
                after.completedPasses > before.state.completedPasses &&
                PracticeEngine.distanceMetres(
                        before.state.attackers
                            .firstWhere((p) => p.number == d.action.receiver)
                            .position,
                        after.carrier.position) >=
                    1,
          FlowFocus.beatCover => movement &&
              d.pressureAfter >= 1.5 &&
              d.laneAfter >= 1 &&
              (d.pressureAfter > d.pressureBefore + .7 ||
                  d.laneAfter > d.laneBefore + .6),
          FlowFocus.changeLane => movement &&
              (actorAfter.position.y - actorBefore.position.y).abs() *
                      PracticeEngine.fieldWidth >=
                  1.5 &&
              (d.laneAfter > d.laneBefore + .5 ||
                  d.pressureAfter > d.pressureBefore + .7),
        };
    // Keep factual metrics at reception. A pending support target is not
    // reported as reached merely because the accompanying pass completed.
    final decision = PracticeDecision(
      before: d.before,
      phaseBefore: d.phaseBefore,
      action: d.action,
      transitions: d.transitions,
      reason: d.reason,
      cue: d.cue,
      useful: d.useful,
      goalDemonstrated: goal,
      pressureBefore: d.pressureBefore,
      pressureAfter: d.pressureAfter,
      laneBefore: d.laneBefore,
      laneAfter: d.laneAfter,
      distance: d.distance,
      optionsBefore: d.optionsBefore,
      optionsAfter: d.optionsAfter,
      evidencePlayer: d.evidencePlayer,
      historyLengthBefore: d.historyLengthBefore,
      decisionsLengthBefore: d.decisionsLengthBefore,
      settingsBefore: d.settingsBefore,
      runTargetsBefore: d.runTargetsBefore,
      returnTargetBefore: d.returnTargetBefore,
    );
    return PracticeStep(
      session: _copy(step.session,
          decisions: List.unmodifiable([
            ...step.session.decisions.take(step.session.decisions.length - 1),
            decision,
          ])),
      transitions: step.transitions,
      decision: decision,
    );
  }

  bool _receivedInNewSpace(PracticeSession before, PracticeDecision decision) {
    if (decision.action.receiver == null ||
        decision.after.completedPasses <= before.state.completedPasses ||
        decision.laneBefore <
            before.lesson.learning.rubric.minimumLaneClearance) {
      return false;
    }
    final receiver = decision.action.receiver!;
    final released = before.history.where((t) =>
        t.before.carrierNumber == receiver &&
        t.after.end == null &&
        t.after.completedPasses > t.before.completedPasses);
    if (released.isEmpty) return false;
    final origin = released.last.before.carrier.position;
    return PracticeEngine.distanceMetres(
            origin, decision.after.carrier.position) >=
        1;
  }

  static PracticeSession _copy(PracticeSession session,
          {Map<int, ScanPassPoint>? runTargets,
          List<PracticeDecision>? decisions}) =>
      PracticeSession(
        lesson: session.lesson,
        state: session.state,
        phase: session.phase,
        settings: session.settings,
        runTargets: runTargets ?? session.runTargets,
        returnTarget: session.returnTarget,
        decisions: decisions ?? session.decisions,
        history: session.history,
        outcome: session.outcome,
        reachedGate: session.reachedGate,
      );

  static FlowCase _createCase(FlowFocus focus, int variant) {
    // Six distinct spacings and pressure problems. The second condition shifts
    // one defensive approach/cover, retaining the same two attacking positions.
    final geometry = switch (focus) {
      FlowFocus.firstTouch => (
          const ScanPassPoint(.28, .54),
          const ScanPassPoint(.45, .23),
          ScanPassPoint(variant == 0 ? .365 : .245, variant == 0 ? .66 : .72),
          const ScanPassPoint(.60, .31)
        ),
      FlowFocus.drawDefender => (
          const ScanPassPoint(.25, .60),
          const ScanPassPoint(.48, .31),
          ScanPassPoint(variant == 0 ? .40 : .44, variant == 0 ? .66 : .51),
          const ScanPassPoint(.66, .32)
        ),
      FlowFocus.supportAngle => (
          const ScanPassPoint(.32, .65),
          const ScanPassPoint(.52, .37),
          const ScanPassPoint(.43, .74),
          ScanPassPoint(.66, variant == 0 ? .33 : .52)
        ),
      FlowFocus.throughPass => (
          const ScanPassPoint(.29, .65),
          const ScanPassPoint(.51, .38),
          const ScanPassPoint(.40, .75),
          ScanPassPoint(variant == 0 ? .66 : .57, variant == 0 ? .46 : .23)
        ),
      FlowFocus.beatCover => (
          const ScanPassPoint(.42, .40),
          const ScanPassPoint(.61, .69),
          const ScanPassPoint(.50, .25),
          ScanPassPoint(.65, variant == 0 ? .43 : .59)
        ),
      FlowFocus.changeLane => (
          const ScanPassPoint(.36, .29),
          const ScanPassPoint(.57, .57),
          ScanPassPoint(.46, variant == 0 ? .17 : .32),
          const ScanPassPoint(.66, .43)
        ),
    };
    final pressure = focus == FlowFocus.supportAngle ||
            focus == FlowFocus.throughPass ||
            focus == FlowFocus.beatCover ||
            variant == 0
        ? const ScanPassPoint(-.060, -.025)
        : const ScanPassPoint(-.025, .045);
    final players = [
      AttackPlayer(number: 6, position: geometry.$1),
      AttackPlayer(number: 8, position: geometry.$2),
    ];
    final defenders = [
      AttackPlayer(
          number: 2, opponent: true, position: geometry.$3, velocity: pressure),
      AttackPlayer(
          number: 3,
          opponent: true,
          position: geometry.$4,
          velocity: const ScanPassPoint(-.012, -.010)),
    ];
    const observeDuration = .65;
    final samples = <AttackState>[];
    for (var i = 0; i <= 26; i++) {
      final t = i / 26;
      final elapsed = t * observeDuration;
      samples.add(AttackState(
        attackers: players,
        defenders: [
          for (final d in defenders)
            d.copyWith(
                position: PracticeEngine.boundedTarget(
                    d.position + d.velocity * elapsed))
        ],
        ball: geometry.$2.lerp(geometry.$1, t),
        carrierNumber: i == 26 ? 6 : 8,
        elapsed: elapsed,
        completedPasses: i == 26 ? 1 : 0,
        cue: i == 26 ? AttackCue.received : AttackCue.opening,
      ));
    }
    final skill = switch (focus) {
      FlowFocus.firstTouch => PracticeSkill.firstTouch,
      FlowFocus.supportAngle => PracticeSkill.supportAngle,
      FlowFocus.throughPass => PracticeSkill.throughPass,
      _ => PracticeSkill.drawDefender,
    };
    final cues = switch (focus) {
      FlowFocus.firstTouch => [
          PracticeCue.pressureSide,
          PracticeCue.passingLane
        ],
      FlowFocus.drawDefender => [
          PracticeCue.defenderCommitment,
          PracticeCue.passingLane
        ],
      FlowFocus.supportAngle => [
          PracticeCue.supportLane,
          PracticeCue.pressureSide
        ],
      FlowFocus.throughPass => [
          PracticeCue.runnerTiming,
          PracticeCue.passingLane
        ],
      FlowFocus.beatCover => [
          PracticeCue.pressureSide,
          PracticeCue.passingLane
        ],
      FlowFocus.changeLane => [
          PracticeCue.passingLane,
          PracticeCue.pressureSide
        ],
    };
    return FlowCase(
        focus: focus,
        lesson: PracticeCase(
          id: 'flow-${focus.name}-$variant',
          skill: skill,
          variant: variant,
          stage: 2,
          offsideEnabled: false,
          gates: const [
            PracticeGate(id: 'upper', center: ScanPassPoint(.88, .23)),
            PracticeGate(id: 'lower', center: ScanPassPoint(.88, .77)),
          ],
          observation: AttackTransition(
            before: samples.first,
            after: samples.last,
            action: const AttackAction.pass(6),
            duration: observeDuration,
            ballEnd: geometry.$1,
            motionSamples: List.unmodifiable(samples),
          ),
          learning: PracticeLearningDefinition(
              goal: skill,
              cues: List.unmodifiable(cues),
              mistakes: const [
                PracticeReason.touchIntoPressure,
                PracticeReason.passLaneClosed,
                PracticeReason.supportStillHidden
              ],
              rubric: const PracticeRubric()),
        ));
  }
}
