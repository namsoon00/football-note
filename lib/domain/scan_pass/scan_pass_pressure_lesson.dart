import 'dart:math' as math;

import 'scan_pass_game.dart' show ScanPassPoint;

enum PressureTeam { attack, defense }

enum PressureActorRole {
  passer,
  receiver,
  support,
  runner,
  presser,
  cover,
  tracker,
}

enum PressureDecisionStage { firstContact, nextConnection, support, reRead }

enum PressureActionKind { firstTouch, pass, carry, offBallRun }

/// The six football questions taught by the public Scan Pass lesson.
enum PressureLearningFamily {
  pressureReception,
  drawAndRelease,
  supportAfterPass,
  runnerTiming,
  thirdPlayer,
  recycleAndSwitch,
}

enum PressureLessonVariant { guided, contrast, unseen }

enum PressureLearningObjective {
  receiveAwayFromPressure,
  commitThenRelease,
  moveAfterPassing,
  timeTheThroughPass,
  connectTheThirdPlayer,
  recycleWhenForwardPlayCloses,
}

enum PressureObservationFact {
  pressureSide,
  pressureSpeed,
  coverLane,
  focusSupportLane,
  runnerSpeed,
  trackerDepth,
  farSideOutlet,
  offsideReference,
}

enum PressureContrastFeature {
  approachSide,
  presserCommitment,
  coverPosition,
  runnerStart,
  trackerReaction,
  farSideClosure,
}

enum PressureEpisodeDecisionKind { receive, onBall, support }

/// Declares who owns a key judgment without tying the scene to one learner.
///
/// On-ball beats always resolve [currentCarrier] from the live world. Off-ball
/// beats can name a role, or reuse the preceding decision actor after a pass
/// with a declared fallback when that actor still has the ball.
enum PressureSceneActorRule {
  currentCarrier,
  role,
  previousActorOrRole,
}

class PressureSceneJudgment {
  final PressureEpisodeDecisionKind kind;
  final PressureSceneActorRule actorRule;
  final PressureActorRole? actorRole;

  const PressureSceneJudgment.currentCarrier(this.kind)
      : actorRule = PressureSceneActorRule.currentCarrier,
        actorRole = null;

  const PressureSceneJudgment.role(
    this.kind,
    PressureActorRole declaredRole,
  )   : actorRole = declaredRole,
        actorRule = PressureSceneActorRule.role;

  const PressureSceneJudgment.previousActorOrRole(
    this.kind,
    PressureActorRole fallbackRole,
  )   : actorRole = fallbackRole,
        actorRule = PressureSceneActorRule.previousActorOrRole;
}

enum PressureEpisodeOutcome {
  penetration,
  pressureEscape,
  safeRecycle,
  intercepted,
  offside,
  loose,
  retainedUnresolved,
}

enum PressureAutomaticKind { pass, carry, recycle }

enum PressureRunPlanStatus { active, reached, interrupted }

enum PressureOptionKind {
  touchInside,
  touchOutside,
  touchLeft,
  touchRight,
  immediatePass,
  immediateRunnerPass,
  immediateBackPass,
  passSupport,
  passRunner,
  passFocus,
  passOther,
  recycle,
  carryForward,
}

enum PressurePossession { attack, defense, loose }

enum PressureResultKind { retained, progressed, intercepted, loose, offside }

enum PressureDecisionQuality { strong, sound, compromised, lost }

enum PressureSafety { safe, pressured, lost }

enum PressureProgress { opened, retained, missedOpportunity, stopped }

enum PressureFieldBand { middleThird, attackingThird }

enum PressureFieldChannel { right, central, left }

enum PressureApproachSide { outside, inside, level }

enum PressureMovement { closing, holding }

enum PressureRunnerMovement { breakingForward, movingForward, held }

enum PressureActionBenefit {
  none,
  increasedSeparation,
  passReceived,
  forwardPassReceived,
  openedSimulatedForwardLane,
  progressedWithControl,
  retainedControl,
}

enum PressureActionLimitation {
  interception,
  offside,
  looseBall,
  lostForwardWindow,
  closingPressure,
  limitedProgression,
  remainingPressure,
}

/// Measured situation facts for the persistent decision ribbon.
///
/// This deliberately contains no recommendation or scenario-authored answer.
/// Every value is derived from the current immutable world snapshot.
class PressureSituationContext {
  final PressureDecisionStage stage;
  final PressureFieldBand fieldBand;
  final PressureFieldChannel fieldChannel;
  final int carrierNumber;
  final int focusNumber;
  final int presserNumber;
  final PressureApproachSide approachSide;
  final PressureMovement pressureMovement;
  final double pressureDistanceMetres;
  final int coverNumber;
  final int supportNumber;
  final PressureMovement coverMovement;
  final double coverLaneDistanceMetres;
  final int runnerNumber;
  final PressureRunnerMovement runnerMovement;

  const PressureSituationContext({
    required this.stage,
    required this.fieldBand,
    required this.fieldChannel,
    required this.carrierNumber,
    required this.focusNumber,
    required this.presserNumber,
    required this.approachSide,
    required this.pressureMovement,
    required this.pressureDistanceMetres,
    required this.coverNumber,
    required this.supportNumber,
    required this.coverMovement,
    required this.coverLaneDistanceMetres,
    required this.runnerNumber,
    required this.runnerMovement,
  });
}

/// Per-action evidence used by review copy and spatial annotations.
///
/// Benefits are credited only for an observed change in this action or for a
/// pass that the intended teammate actually controlled. A projected connection
/// is named separately so it cannot be mistaken for a completed pass.
class PressureActionEvidence {
  final PressureActionBenefit benefit;
  final PressureActionLimitation limitation;
  final int actorNumber;
  final int? destinationNumber;
  final int? benefitReceiverNumber;
  final int? defenderNumber;
  final double separationChangeMetres;
  final double pressureClearanceMetres;
  final double progressMetres;
  final double? contactSeconds;
  final ScanPassPoint? contactPoint;
  final PressureWorld freezeFrame;

  const PressureActionEvidence({
    required this.benefit,
    required this.limitation,
    required this.actorNumber,
    required this.destinationNumber,
    required this.benefitReceiverNumber,
    required this.defenderNumber,
    required this.separationChangeMetres,
    required this.pressureClearanceMetres,
    required this.progressMetres,
    required this.contactSeconds,
    required this.contactPoint,
    required this.freezeFrame,
  });
}

/// A physical actor on the declared 105 m x 68 m field.
///
/// Identity and shirt number are evidence/display fields. Motion policy reads
/// [team], [role], positions, velocities and the stable physical parameters.
class PressureActor {
  final String id;
  final int number;
  final PressureTeam team;
  final PressureActorRole role;
  final ScanPassPoint position;
  final ScanPassPoint velocity;
  final ScanPassPoint intentVelocity;
  final ScanPassPoint home;
  final double maxSpeed;
  final double maxAcceleration;
  final double reactivity;

  const PressureActor({
    required this.id,
    required this.number,
    required this.team,
    required this.role,
    required this.position,
    this.velocity = const ScanPassPoint(0, 0),
    this.intentVelocity = const ScanPassPoint(0, 0),
    ScanPassPoint? home,
    this.maxSpeed = 6.4,
    this.maxAcceleration = 5.2,
    this.reactivity = 1,
  }) : home = home ?? position;

  PressureActor copyWith({
    String? id,
    int? number,
    ScanPassPoint? position,
    ScanPassPoint? velocity,
    ScanPassPoint? intentVelocity,
    ScanPassPoint? home,
    double? maxSpeed,
    double? maxAcceleration,
    double? reactivity,
  }) {
    return PressureActor(
      id: id ?? this.id,
      number: number ?? this.number,
      team: team,
      role: role,
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      intentVelocity: intentVelocity ?? this.intentVelocity,
      home: home ?? this.home,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      maxAcceleration: maxAcceleration ?? this.maxAcceleration,
      reactivity: reactivity ?? this.reactivity,
    );
  }
}

class PressureBall {
  final ScanPassPoint position;
  final ScanPassPoint velocity;
  final String? carrierId;

  const PressureBall({
    required this.position,
    this.velocity = const ScanPassPoint(0, 0),
    required this.carrierId,
  });

  bool get inFlight => carrierId == null && velocity.distance > .01;

  PressureBall copyWith({
    ScanPassPoint? position,
    ScanPassPoint? velocity,
    String? carrierId,
    bool clearCarrier = false,
  }) {
    return PressureBall(
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      carrierId: clearCarrier ? null : (carrierId ?? this.carrierId),
    );
  }
}

class PressureWorld {
  final double clock;
  final List<PressureActor> actors;
  final PressureBall ball;
  final PressurePossession possession;

  PressureWorld({
    required this.clock,
    required List<PressureActor> actors,
    required this.ball,
    required this.possession,
  }) : actors = List.unmodifiable(actors);

  PressureActor actorById(String id) =>
      actors.firstWhere((actor) => actor.id == id);

  PressureActor actorByRole(PressureActorRole role) =>
      actors.firstWhere((actor) => actor.role == role);

  PressureActor? get carrier {
    final id = ball.carrierId;
    if (id == null) return null;
    for (final actor in actors) {
      if (actor.id == id) return actor;
    }
    return null;
  }

  Iterable<PressureActor> team(PressureTeam team) =>
      actors.where((actor) => actor.team == team);

  PressureWorld copyWith({
    double? clock,
    List<PressureActor>? actors,
    PressureBall? ball,
    PressurePossession? possession,
  }) {
    return PressureWorld(
      clock: clock ?? this.clock,
      actors: actors ?? this.actors,
      ball: ball ?? this.ball,
      possession: possession ?? this.possession,
    );
  }
}

/// A selected off-ball route that remains part of the physical scene after
/// the short placement beat. It is carried into the next pass/carry and the
/// bounded end continuation until reached or interrupted by possession loss or
/// the moving player receiving the ball.
class PressureRunPlan {
  final String actorId;
  final PressureActorRole actorRole;
  final ScanPassPoint requestedTarget;
  final ScanPassPoint boundedTarget;
  final double startedAt;
  final PressureRunPlanStatus status;

  const PressureRunPlan({
    required this.actorId,
    required this.actorRole,
    required this.requestedTarget,
    required this.boundedTarget,
    required this.startedAt,
    this.status = PressureRunPlanStatus.active,
  });

  bool get isActive => status == PressureRunPlanStatus.active;

  PressureRunPlan copyWith({PressureRunPlanStatus? status}) => PressureRunPlan(
        actorId: actorId,
        actorRole: actorRole,
        requestedTarget: requestedTarget,
        boundedTarget: boundedTarget,
        startedAt: startedAt,
        status: status ?? this.status,
      );
}

class PressureAction {
  final String label;
  final PressureActionKind kind;
  final ScanPassPoint target;

  const PressureAction({
    this.label = '',
    required this.kind,
    required this.target,
  });

  PressureAction relabeled(String value) => PressureAction(
        label: value,
        kind: kind,
        target: target,
      );
}

class PressureDecisionOption {
  final String key;
  final PressureOptionKind kind;
  final PressureAction action;
  final PressureActorRole? targetRole;

  const PressureDecisionOption({
    required this.key,
    required this.kind,
    required this.action,
    this.targetRole,
  });
}

class PressureTrace {
  final List<PressureWorld> frames;

  PressureTrace(List<PressureWorld> frames)
      : assert(frames.isNotEmpty),
        frames = List.unmodifiable(frames);

  PressureWorld get first => frames.first;
  PressureWorld get last => frames.last;
  double get duration => math.max(0, last.clock - first.clock);

  List<ScanPassPoint> get ballPath =>
      List.unmodifiable(frames.map((frame) => frame.ball.position));

  List<ScanPassPoint> actorPath(PressureActorRole role) => List.unmodifiable(
        frames.map((frame) => frame.actorByRole(role).position),
      );

  PressureWorld frameAt(double progress) {
    final t = progress.clamp(0.0, 1.0).toDouble();
    if (t <= 0 || frames.length == 1) return first;
    if (t >= 1) return last;
    final target = first.clock + duration * t;
    var index = 1;
    while (index < frames.length - 1 && frames[index].clock < target) {
      index += 1;
    }
    final a = frames[index - 1];
    final b = frames[index];
    final span = b.clock - a.clock;
    final local = span <= 0 ? 0.0 : (target - a.clock) / span;
    final nextActors = <PressureActor>[];
    for (final actor in a.actors) {
      final other = b.actors.firstWhere((candidate) =>
          candidate.team == actor.team && candidate.role == actor.role);
      nextActors.add(actor.copyWith(
        position: actor.position.lerp(other.position, local),
        velocity: actor.velocity.lerp(other.velocity, local),
      ));
    }
    final carrierId = local >= 1 ? b.ball.carrierId : a.ball.carrierId;
    return PressureWorld(
      clock: target,
      actors: nextActors,
      ball: PressureBall(
        position: a.ball.position.lerp(b.ball.position, local),
        velocity: a.ball.velocity.lerp(b.ball.velocity, local),
        carrierId: carrierId,
      ),
      possession: local >= 1 ? b.possession : a.possession,
    );
  }

  static PressureTrace join(Iterable<PressureTrace> traces) {
    final frames = <PressureWorld>[];
    for (final trace in traces) {
      if (frames.isEmpty) {
        frames.addAll(trace.frames);
      } else {
        frames.addAll(trace.frames.skip(1));
      }
    }
    return PressureTrace(frames);
  }
}

class PressureConnectionEvidence {
  final PressureActorRole receiverRole;
  final ScanPassPoint target;
  final double forwardGainMetres;
  final double receiverClearanceMetres;
  final double closestDefenderMetres;
  final bool retainedByReceiver;
  final bool onsideAtRelease;
  final PressureActorRole? blockingDefenderRole;

  const PressureConnectionEvidence({
    required this.receiverRole,
    required this.target,
    required this.forwardGainMetres,
    required this.receiverClearanceMetres,
    required this.closestDefenderMetres,
    required this.retainedByReceiver,
    required this.onsideAtRelease,
    required this.blockingDefenderRole,
  });

  /// True only when the common pass simulation ends with this receiver still
  /// in possession. It is not a projected or catalog-authored lane score.
  bool get safe => onsideAtRelease && retainedByReceiver;
  bool get forward => forwardGainMetres >= 1.0;
}

class PressureAssessment {
  final PressureResultKind result;
  final PressureDecisionQuality quality;
  final PressureSafety safety;
  final PressureProgress progress;
  final double pressureClearanceMetres;
  final double availableTimeSeconds;
  final double actionProgressMetres;
  final PressureActorRole nearestDefenderRole;
  final List<PressureConnectionEvidence> connections;
  final bool forwardOpportunityBefore;
  final bool missedForwardOpportunity;

  PressureAssessment({
    required this.result,
    required this.quality,
    required this.safety,
    required this.progress,
    required this.pressureClearanceMetres,
    required this.availableTimeSeconds,
    required this.actionProgressMetres,
    required this.nearestDefenderRole,
    required List<PressureConnectionEvidence> connections,
    required this.forwardOpportunityBefore,
    required this.missedForwardOpportunity,
  }) : connections = List.unmodifiable(connections);

  Iterable<PressureConnectionEvidence> get safeConnections =>
      connections.where((connection) => connection.safe);
}

class PressureContactEvidence {
  final double clock;
  final int defenderNumber;
  final String defenderId;
  final ScanPassPoint point;

  const PressureContactEvidence({
    required this.clock,
    required this.defenderNumber,
    required this.defenderId,
    required this.point,
  });
}

class PressureSimulationResult {
  final PressureWorld before;
  final PressureWorld after;
  final PressureAction action;
  final PressureTrace trace;
  final PressureAssessment assessment;
  final PressureContactEvidence? contact;
  final PressureActorRole? intendedReceiverRole;
  final bool offside;

  const PressureSimulationResult({
    required this.before,
    required this.after,
    required this.action,
    required this.trace,
    required this.assessment,
    this.contact,
    this.intendedReceiverRole,
    this.offside = false,
  });
}

class PressureObservation {
  final PressureTrace trace;
  final PressureWorld decisionState;

  const PressureObservation({
    required this.trace,
    required this.decisionState,
  });
}

class PressureLessonScenario {
  final String id;
  final bool heldOut;
  final PressureLearningFamily family;
  final PressureLessonVariant variant;
  final PressureLearningObjective learningObjective;
  final List<PressureObservationFact> observationFacts;
  final PressureContrastFeature contrastFeature;
  final PressureEpisodeDecisionKind initialDecisionKind;
  final List<PressureSceneJudgment> sceneJudgments;
  final PressureActorRole focusRole;
  final PressureWorld observationStart;

  const PressureLessonScenario({
    required this.id,
    required this.heldOut,
    this.family = PressureLearningFamily.pressureReception,
    this.variant = PressureLessonVariant.guided,
    this.learningObjective = PressureLearningObjective.receiveAwayFromPressure,
    this.observationFacts = const [
      PressureObservationFact.pressureSide,
      PressureObservationFact.coverLane,
    ],
    this.contrastFeature = PressureContrastFeature.approachSide,
    this.initialDecisionKind = PressureEpisodeDecisionKind.receive,
    this.sceneJudgments = const [
      PressureSceneJudgment.currentCarrier(PressureEpisodeDecisionKind.receive),
      PressureSceneJudgment.currentCarrier(PressureEpisodeDecisionKind.onBall),
    ],
    this.focusRole = PressureActorRole.receiver,
    required this.observationStart,
  })  : assert(sceneJudgments.length > 0),
        assert(sceneJudgments.length <= 3);

  bool get showMovementGuidance => variant == PressureLessonVariant.guided;

  PressureLessonScenario relabeled(String value) => PressureLessonScenario(
        id: value,
        heldOut: heldOut,
        family: family,
        variant: variant,
        learningObjective: learningObjective,
        observationFacts: observationFacts,
        contrastFeature: contrastFeature,
        initialDecisionKind: initialDecisionKind,
        sceneJudgments: sceneJudgments,
        focusRole: focusRole,
        observationStart: observationStart,
      );
}

class PressureLessonAttempt {
  final int situationIndex;
  final PressureWorld firstDecisionState;
  final PressureSimulationResult firstDecision;
  final PressureWorld lastDecisionState;
  final PressureSimulationResult? nextDecision;

  const PressureLessonAttempt({
    required this.situationIndex,
    required this.firstDecisionState,
    required this.firstDecision,
    required this.lastDecisionState,
    this.nextDecision,
  });

  PressureSimulationResult get terminal => nextDecision ?? firstDecision;
  bool get usedNextConnection => nextDecision != null;
}

class PressureLessonSession {
  final List<PressureLessonScenario> situations;
  final Map<int, PressureLessonAttempt> firstAttempts;

  PressureLessonSession({
    required List<PressureLessonScenario> situations,
    Map<int, PressureLessonAttempt> firstAttempts = const {},
  })  : situations = List.unmodifiable(situations),
        firstAttempts = Map.unmodifiable(firstAttempts);

  PressureLessonSession recordFirstAttempt(PressureLessonAttempt attempt) {
    if (firstAttempts.containsKey(attempt.situationIndex)) return this;
    return PressureLessonSession(
      situations: situations,
      firstAttempts: <int, PressureLessonAttempt>{
        ...firstAttempts,
        attempt.situationIndex: attempt,
      },
    );
  }

  int get retainedFirstAttempts => firstAttempts.values
      .where((attempt) =>
          attempt.terminal.assessment.safety != PressureSafety.lost)
      .length;

  int get openedConnections => firstAttempts.values.where((attempt) {
        final assessment = attempt.terminal.assessment;
        return assessment.safety != PressureSafety.lost &&
            !assessment.missedForwardOpportunity &&
            (assessment.actionProgressMetres >= 1.5 ||
                assessment.connections.any(
                    (connection) => connection.safe && connection.forward));
      }).length;
}

/// One bounded automatic tail action by the current ball holder, produced by
/// the same physical pass and carry resolver as learner actions.
class PressureAutomaticContinuation {
  final PressureAutomaticKind kind;
  final PressureSimulationResult result;

  const PressureAutomaticContinuation({
    required this.kind,
    required this.result,
  });
}

class PressureLaneChange {
  final PressureActorRole receiverRole;
  final PressureActorRole? beforeDefenderRole;
  final PressureActorRole? afterDefenderRole;
  final bool usableBefore;
  final bool usableAfter;
  final double clearanceChangeMetres;

  const PressureLaneChange({
    required this.receiverRole,
    required this.beforeDefenderRole,
    required this.afterDefenderRole,
    required this.usableBefore,
    required this.usableAfter,
    required this.clearanceChangeMetres,
  });
}

/// Physical outcome of one off-ball support judgment.
class PressureSupportResult {
  final PressureWorld before;
  final PressureWorld afterMovement;
  final PressureWorld after;
  final String actorId;
  final String carrierId;
  final PressureActorRole focusRole;
  final ScanPassPoint requestedTarget;
  final ScanPassPoint boundedTarget;
  final ScanPassPoint executedTarget;
  final double movementDistanceMetres;
  final PressureTrace movementTrace;
  final PressureAutomaticContinuation? continuation;
  final List<PressureLaneChange> laneChanges;
  final PressureWorld stationaryCounterfactual;
  final double separationChangeMetres;
  final PressureActorRole separationDefenderRole;
  final PressureContactEvidence? contact;

  const PressureSupportResult({
    required this.before,
    required this.afterMovement,
    required this.after,
    required this.actorId,
    required this.carrierId,
    required this.focusRole,
    required this.requestedTarget,
    required this.boundedTarget,
    required this.executedTarget,
    required this.movementDistanceMetres,
    required this.movementTrace,
    required this.continuation,
    required this.laneChanges,
    required this.stationaryCounterfactual,
    required this.separationChangeMetres,
    required this.separationDefenderRole,
    required this.contact,
  });

  PressureTrace get trace => continuation == null
      ? movementTrace
      : PressureTrace.join([movementTrace, continuation!.result.trace]);

  PressureLaneChange? get demonstratedPositiveLaneChange {
    final changed = laneChanges
        .where((lane) =>
            lane.usableAfter &&
            (!lane.usableBefore || lane.clearanceChangeMetres >= .35))
        .toList()
      ..sort((a, b) {
        final opened = (b.usableBefore ? 0 : 1).compareTo(
          a.usableBefore ? 0 : 1,
        );
        if (opened != 0) return opened;
        return b.clearanceChangeMetres.compareTo(a.clearanceChangeMetres);
      });
    return changed.firstOrNull;
  }

  PressureLaneChange? get demonstratedNegativeLaneChange {
    final changed = laneChanges
        .where((lane) =>
            (lane.usableBefore && !lane.usableAfter) ||
            lane.clearanceChangeMetres <= -.35)
        .toList()
      ..sort((a, b) {
        final closed = (b.usableAfter ? 0 : 1).compareTo(
          a.usableAfter ? 0 : 1,
        );
        if (closed != 0) return closed;
        return a.clearanceChangeMetres.compareTo(b.clearanceChangeMetres);
      });
    return changed.firstOrNull;
  }

  PressureLaneChange? get demonstratedLaneChange =>
      demonstratedPositiveLaneChange ?? demonstratedNegativeLaneChange;
}

/// One selectable item in the complete learner-decision timeline.
class PressureEpisodeDecision {
  final int index;
  final PressureEpisodeDecisionKind kind;
  final String actorId;
  final PressureWorld before;
  final PressureWorld after;
  final List<PressureDecisionOption> availableOptions;
  final PressureDecisionOption? selectedOption;
  final ScanPassPoint requestedTarget;
  final ScanPassPoint executedTarget;
  final PressureTrace learnerTrace;
  final PressureSimulationResult? actionResult;
  final PressureSupportResult? supportResult;
  final PressureRunPlan? runPlanBefore;
  final PressureRunPlan? runPlanAfter;

  const PressureEpisodeDecision({
    required this.index,
    required this.kind,
    required this.actorId,
    required this.before,
    required this.after,
    required this.availableOptions,
    required this.selectedOption,
    required this.requestedTarget,
    required this.executedTarget,
    required this.learnerTrace,
    required this.actionResult,
    required this.supportResult,
    required this.runPlanBefore,
    required this.runPlanAfter,
  });

  int get actorNumber => before.actorById(actorId).number;

  PressureTrace get fullTrace => supportResult?.trace ?? learnerTrace;

  Iterable<PressureAutomaticContinuation> get automaticContinuations sync* {
    final automatic = supportResult?.continuation;
    if (automatic != null) yield automatic;
  }

  bool get lost => after.possession != PressurePossession.attack;
  bool get offside =>
      actionResult?.offside == true ||
      supportResult?.continuation?.result.offside == true;
}

/// Physically simulated play after the final key judgment. It is deliberately
/// separate from the learner timeline so it cannot be counted as another
/// judgment or consume an intended decision.
class PressureSceneTail {
  final PressureWorld before;
  final PressureWorld after;
  final PressureTrace trace;
  final List<PressureAutomaticContinuation> actions;
  final PressureRunPlan? runPlanBefore;
  final PressureRunPlan? runPlanAfter;

  PressureSceneTail({
    required this.before,
    required this.after,
    required this.trace,
    required List<PressureAutomaticContinuation> actions,
    required this.runPlanBefore,
    required this.runPlanAfter,
  }) : actions = List.unmodifiable(actions);

  bool get lost => after.possession != PressurePossession.attack;
  bool get offside => actions.any((action) => action.result.offside);
}

class PressureEpisodeState {
  final PressureLessonScenario scenario;
  final PressureObservation observation;
  final PressureWorld world;
  final PressureEpisodeDecisionKind? pendingDecision;
  final String? pendingActorId;
  final PressureRunPlan? runPlan;
  final List<PressureEpisodeDecision> timeline;
  final PressureSceneTail? tail;
  final PressureEpisodeOutcome? outcome;
  final double initialBallX;
  final int maxDecisions;

  PressureEpisodeState({
    required this.scenario,
    required this.observation,
    required this.world,
    required this.pendingDecision,
    required this.pendingActorId,
    required this.runPlan,
    required List<PressureEpisodeDecision> timeline,
    required this.tail,
    required this.outcome,
    required this.initialBallX,
    this.maxDecisions = 3,
  }) : timeline = List.unmodifiable(timeline);

  bool get isComplete => outcome != null;

  PressureEpisodeState copyWith({
    PressureWorld? world,
    PressureEpisodeDecisionKind? pendingDecision,
    String? pendingActorId,
    bool clearPendingDecision = false,
    PressureRunPlan? runPlan,
    bool clearRunPlan = false,
    List<PressureEpisodeDecision>? timeline,
    PressureSceneTail? tail,
    bool clearTail = false,
    PressureEpisodeOutcome? outcome,
    bool clearOutcome = false,
  }) =>
      PressureEpisodeState(
        scenario: scenario,
        observation: observation,
        world: world ?? this.world,
        pendingDecision: clearPendingDecision
            ? null
            : (pendingDecision ?? this.pendingDecision),
        pendingActorId: clearPendingDecision
            ? null
            : (pendingActorId ?? this.pendingActorId),
        runPlan: clearRunPlan ? null : (runPlan ?? this.runPlan),
        timeline: timeline ?? this.timeline,
        tail: clearTail ? null : (tail ?? this.tail),
        outcome: clearOutcome ? null : (outcome ?? this.outcome),
        initialBallX: initialBallX,
        maxDecisions: maxDecisions,
      );
}

class PressureEpisodeAttempt {
  final int situationIndex;
  final PressureLessonScenario scenario;
  final List<PressureEpisodeDecision> timeline;
  final PressureSceneTail? tail;
  final PressureEpisodeOutcome outcome;

  PressureEpisodeAttempt({
    required this.situationIndex,
    required this.scenario,
    required List<PressureEpisodeDecision> timeline,
    this.tail,
    required this.outcome,
  }) : timeline = List.unmodifiable(timeline);

  PressureWorld get terminal => tail?.after ?? timeline.last.after;
  int get decisionCount => timeline.length;
}

/// Session measurements intentionally retain only the first completed attack
/// for each catalog situation. Retry and comparison simulations never replace
/// this map.
class PressureEpisodeSession {
  final List<PressureLessonScenario> situations;
  final Map<int, PressureEpisodeAttempt> firstAttempts;

  PressureEpisodeSession({
    required List<PressureLessonScenario> situations,
    Map<int, PressureEpisodeAttempt> firstAttempts = const {},
  })  : situations = List.unmodifiable(situations),
        firstAttempts = Map.unmodifiable(firstAttempts);

  PressureEpisodeSession recordFirstAttempt(PressureEpisodeAttempt attempt) {
    if (firstAttempts.containsKey(attempt.situationIndex)) return this;
    return PressureEpisodeSession(
      situations: situations,
      firstAttempts: {...firstAttempts, attempt.situationIndex: attempt},
    );
  }

  int get retainedAttacks => firstAttempts.values
      .where(
          (attempt) => attempt.terminal.possession == PressurePossession.attack)
      .length;

  int get unseenRetained => firstAttempts.values
      .where((attempt) =>
          attempt.scenario.variant == PressureLessonVariant.unseen &&
          attempt.terminal.possession == PressurePossession.attack)
      .length;

  int get unseenAttempts => firstAttempts.values
      .where(
          (attempt) => attempt.scenario.variant == PressureLessonVariant.unseen)
      .length;

  int get firstAttemptJudgments => firstAttempts.values
      .fold(0, (total, attempt) => total + attempt.decisionCount);
}

class PressureTeachingExample {
  final PressureLessonScenario scenario;
  final PressureObservation observation;
  final List<PressureEpisodeDecision> timeline;
  final PressureSceneTail? tail;
  final PressureEpisodeOutcome outcome;

  PressureTeachingExample({
    required this.scenario,
    required this.observation,
    required List<PressureEpisodeDecision> timeline,
    required this.tail,
    required this.outcome,
  }) : timeline = List.unmodifiable(timeline);

  PressureWorld get terminal => tail?.after ?? timeline.last.after;

  PressureTrace get trace => PressureTrace.join([
        observation.trace,
        for (final decision in timeline) decision.fullTrace,
        if (tail != null) tail!.trace,
      ]);
}

class PressureLessonCatalog {
  static const int familyCount = 6;
  static const int variantsPerFamily = 3;
  static const int trainingCount = 12;
  static const int heldOutCount = 6;
  static const int situationCount = familyCount * variantsPerFamily;

  static List<PressureSceneJudgment> _judgmentsFor(
    PressureLearningFamily family,
  ) =>
      switch (family) {
        PressureLearningFamily.pressureReception => const [
            PressureSceneJudgment.currentCarrier(
              PressureEpisodeDecisionKind.receive,
            ),
            PressureSceneJudgment.currentCarrier(
              PressureEpisodeDecisionKind.onBall,
            ),
          ],
        PressureLearningFamily.drawAndRelease => const [
            PressureSceneJudgment.currentCarrier(
              PressureEpisodeDecisionKind.onBall,
            ),
            PressureSceneJudgment.previousActorOrRole(
              PressureEpisodeDecisionKind.support,
              PressureActorRole.support,
            ),
            PressureSceneJudgment.currentCarrier(
              PressureEpisodeDecisionKind.onBall,
            ),
          ],
        PressureLearningFamily.supportAfterPass => const [
            PressureSceneJudgment.role(
              PressureEpisodeDecisionKind.support,
              PressureActorRole.receiver,
            ),
            PressureSceneJudgment.currentCarrier(
              PressureEpisodeDecisionKind.onBall,
            ),
          ],
        PressureLearningFamily.runnerTiming => const [
            PressureSceneJudgment.role(
              PressureEpisodeDecisionKind.support,
              PressureActorRole.runner,
            ),
            PressureSceneJudgment.currentCarrier(
              PressureEpisodeDecisionKind.onBall,
            ),
          ],
        PressureLearningFamily.thirdPlayer => const [
            PressureSceneJudgment.currentCarrier(
              PressureEpisodeDecisionKind.onBall,
            ),
            PressureSceneJudgment.currentCarrier(
              PressureEpisodeDecisionKind.onBall,
            ),
            PressureSceneJudgment.currentCarrier(
              PressureEpisodeDecisionKind.onBall,
            ),
          ],
        PressureLearningFamily.recycleAndSwitch => const [
            PressureSceneJudgment.currentCarrier(
              PressureEpisodeDecisionKind.onBall,
            ),
            PressureSceneJudgment.currentCarrier(
              PressureEpisodeDecisionKind.onBall,
            ),
          ],
      };

  /// Guided and contrast cases stay paired. The six unseen combinations are
  /// deliberately placed after all learning pairs.
  static List<PressureLessonScenario> build({int seed = 19}) {
    final specs = <_PressureScenarioSpec>[
      for (final family in PressureLearningFamily.values) ...[
        _spec(family, PressureLessonVariant.guided),
        _spec(family, PressureLessonVariant.contrast),
      ],
      for (final family in PressureLearningFamily.values)
        _spec(family, PressureLessonVariant.unseen),
    ];
    return List.unmodifiable([
      for (final spec in specs)
        _scenario(
          spec,
          math.Random(
            seed * 997 +
                spec.family.index * 131 +
                (spec.variant == PressureLessonVariant.unseen ? 7919 : 0),
          ),
        ),
    ]);
  }

  static _PressureScenarioSpec _spec(
    PressureLearningFamily family,
    PressureLessonVariant variant,
  ) {
    final unseen = variant == PressureLessonVariant.unseen;
    switch (family) {
      case PressureLearningFamily.pressureReception:
        return _PressureScenarioSpec(
          family: family,
          variant: variant,
          objective: PressureLearningObjective.receiveAwayFromPressure,
          facts: const [
            PressureObservationFact.pressureSide,
            PressureObservationFact.pressureSpeed,
            PressureObservationFact.coverLane,
          ],
          contrastFeature: PressureContrastFeature.approachSide,
          initialDecisionKind: PressureEpisodeDecisionKind.receive,
          passer: unseen
              ? const ScanPassPoint(43, 45)
              : const ScanPassPoint(51, 20),
          focus: unseen
              ? const ScanPassPoint(56, 43)
              : const ScanPassPoint(63, 21),
          support: unseen
              ? const ScanPassPoint(62, 31)
              : const ScanPassPoint(68, 32),
          runner: unseen
              ? const ScanPassPoint(69, 47)
              : const ScanPassPoint(74, 17),
          presser: variant == PressureLessonVariant.contrast
              ? const ScanPassPoint(61.5, 25.2)
              : unseen
                  ? const ScanPassPoint(54.5, 38.5)
                  : const ScanPassPoint(61.8, 16.5),
          cover: unseen
              ? const ScanPassPoint(63, 39)
              : const ScanPassPoint(68, 25.5),
          tracker: unseen
              ? const ScanPassPoint(73, 46)
              : const ScanPassPoint(77, 18.5),
          presserIntent: variant == PressureLessonVariant.contrast
              ? const ScanPassPoint(.8, -2.2)
              : const ScanPassPoint(1.0, 2.1),
          runnerIntent: const ScanPassPoint(2.4, -.2),
        );
      case PressureLearningFamily.drawAndRelease:
        return _PressureScenarioSpec(
          family: family,
          variant: variant,
          objective: PressureLearningObjective.commitThenRelease,
          facts: const [
            PressureObservationFact.pressureSpeed,
            PressureObservationFact.coverLane,
            PressureObservationFact.focusSupportLane,
          ],
          contrastFeature: PressureContrastFeature.presserCommitment,
          initialDecisionKind: PressureEpisodeDecisionKind.onBall,
          initialCarrierRole: PressureActorRole.receiver,
          passer: unseen
              ? const ScanPassPoint(50, 14)
              : const ScanPassPoint(49, 35),
          focus: unseen
              ? const ScanPassPoint(60, 18)
              : const ScanPassPoint(59, 34),
          support: unseen
              ? const ScanPassPoint(68, 29)
              : const ScanPassPoint(68, 44),
          runner: unseen
              ? const ScanPassPoint(74, 12)
              : const ScanPassPoint(74, 29),
          presser: variant == PressureLessonVariant.guided
              ? const ScanPassPoint(64, 34)
              : unseen
                  ? const ScanPassPoint(62, 22)
                  : const ScanPassPoint(62, 34),
          cover: unseen
              ? const ScanPassPoint(65, 23)
              : const ScanPassPoint(68, 38),
          tracker: unseen
              ? const ScanPassPoint(76, 15)
              : const ScanPassPoint(77, 29),
          presserIntent: variant == PressureLessonVariant.contrast
              ? const ScanPassPoint(-.45, .05)
              : const ScanPassPoint(-2.4, 0),
          presserReactivity:
              variant == PressureLessonVariant.contrast ? .38 : .92,
          runnerIntent: const ScanPassPoint(2.7, -.1),
        );
      case PressureLearningFamily.supportAfterPass:
        return _PressureScenarioSpec(
          family: family,
          variant: variant,
          objective: PressureLearningObjective.moveAfterPassing,
          facts: const [
            PressureObservationFact.focusSupportLane,
            PressureObservationFact.coverLane,
            PressureObservationFact.pressureSpeed,
          ],
          contrastFeature: PressureContrastFeature.coverPosition,
          initialDecisionKind: PressureEpisodeDecisionKind.support,
          initialCarrierRole: PressureActorRole.support,
          passer: unseen
              ? const ScanPassPoint(52, 50)
              // Keep the recycling lane clear of the presser's return shadow
              // with enough margin for the paired cases' starting jitter.
              : const ScanPassPoint(54, 34.5),
          focus: unseen
              ? const ScanPassPoint(61, 46)
              : const ScanPassPoint(61, 27),
          support: unseen
              ? const ScanPassPoint(67, 40)
              : const ScanPassPoint(67, 34),
          runner: unseen
              ? const ScanPassPoint(76, 49)
              : const ScanPassPoint(76, 24),
          presser: unseen
              ? const ScanPassPoint(62.5, 43)
              : const ScanPassPoint(62.5, 29.5),
          cover: variant == PressureLessonVariant.contrast
              ? const ScanPassPoint(64, 25)
              : unseen
                  ? const ScanPassPoint(68, 48)
                  : const ScanPassPoint(70, 29),
          tracker: unseen
              ? const ScanPassPoint(78, 48)
              : const ScanPassPoint(79, 24),
          presserIntent: const ScanPassPoint(1.2, .25),
          coverIntent: variant == PressureLessonVariant.contrast
              ? const ScanPassPoint(-.8, .35)
              : const ScanPassPoint(-.35, -.1),
          coverReactivity:
              variant == PressureLessonVariant.contrast ? .82 : .68,
          runnerIntent: const ScanPassPoint(2.0, 0),
        );
      case PressureLearningFamily.runnerTiming:
        return _PressureScenarioSpec(
          family: family,
          variant: variant,
          objective: PressureLearningObjective.timeTheThroughPass,
          facts: const [
            PressureObservationFact.runnerSpeed,
            PressureObservationFact.trackerDepth,
            PressureObservationFact.offsideReference,
          ],
          contrastFeature: PressureContrastFeature.runnerStart,
          initialDecisionKind: PressureEpisodeDecisionKind.support,
          initialCarrierRole: PressureActorRole.receiver,
          passer: unseen
              ? const ScanPassPoint(55, 49)
              : const ScanPassPoint(53, 40),
          focus: unseen
              ? const ScanPassPoint(65, 47)
              : const ScanPassPoint(64, 39),
          support: unseen
              ? const ScanPassPoint(69, 34)
              : const ScanPassPoint(68, 49),
          runner: variant == PressureLessonVariant.contrast
              ? const ScanPassPoint(79, 34)
              : unseen
                  ? const ScanPassPoint(82, 53)
                  : const ScanPassPoint(75, 34),
          presser: unseen
              ? const ScanPassPoint(62, 51)
              : const ScanPassPoint(61, 44),
          cover: unseen
              ? const ScanPassPoint(72, 44)
              : const ScanPassPoint(72, 41),
          tracker: unseen
              ? const ScanPassPoint(87, 51)
              : const ScanPassPoint(80, 35),
          presserIntent: const ScanPassPoint(1.2, -.9),
          runnerIntent: variant == PressureLessonVariant.contrast
              ? const ScanPassPoint(.7, 0)
              : const ScanPassPoint(3.2, -.35),
        );
      case PressureLearningFamily.thirdPlayer:
        return _PressureScenarioSpec(
          family: family,
          variant: variant,
          objective: PressureLearningObjective.connectTheThirdPlayer,
          facts: const [
            PressureObservationFact.focusSupportLane,
            PressureObservationFact.runnerSpeed,
            PressureObservationFact.trackerDepth,
          ],
          contrastFeature: PressureContrastFeature.trackerReaction,
          initialDecisionKind: PressureEpisodeDecisionKind.onBall,
          initialCarrierRole: PressureActorRole.receiver,
          passer: unseen
              ? const ScanPassPoint(47, 47)
              : const ScanPassPoint(49, 20),
          focus: unseen
              ? const ScanPassPoint(57, 43)
              : const ScanPassPoint(58, 24),
          support: unseen
              ? const ScanPassPoint(66, 49)
              : const ScanPassPoint(67, 31),
          runner: unseen
              ? const ScanPassPoint(74, 40)
              : const ScanPassPoint(76, 21),
          presser: unseen
              ? const ScanPassPoint(59, 47)
              : const ScanPassPoint(59, 19),
          cover: unseen
              ? const ScanPassPoint(67, 44)
              : const ScanPassPoint(68, 26),
          tracker: unseen
              ? const ScanPassPoint(84, 49)
              : const ScanPassPoint(84, 26),
          presserIntent: const ScanPassPoint(.8, 1.4),
          runnerIntent: const ScanPassPoint(2.5, -.2),
          trackerReactivity:
              variant == PressureLessonVariant.contrast ? .95 : .55,
        );
      case PressureLearningFamily.recycleAndSwitch:
        return _PressureScenarioSpec(
          family: family,
          variant: variant,
          objective: PressureLearningObjective.recycleWhenForwardPlayCloses,
          facts: const [
            PressureObservationFact.coverLane,
            PressureObservationFact.farSideOutlet,
            PressureObservationFact.pressureSpeed,
          ],
          contrastFeature: PressureContrastFeature.farSideClosure,
          initialDecisionKind: PressureEpisodeDecisionKind.onBall,
          initialCarrierRole: PressureActorRole.receiver,
          passer: unseen
              ? const ScanPassPoint(61, 17)
              : const ScanPassPoint(61, 52),
          focus: unseen
              ? const ScanPassPoint(72, 19)
              : const ScanPassPoint(73, 50),
          support: unseen
              ? const ScanPassPoint(65, 46)
              : const ScanPassPoint(61, 22),
          runner: unseen
              ? const ScanPassPoint(82, 14)
              : const ScanPassPoint(83, 47),
          presser: unseen
              ? const ScanPassPoint(70, 23)
              : const ScanPassPoint(71, 45),
          cover: variant == PressureLessonVariant.contrast
              ? const ScanPassPoint(68, 35)
              : unseen
                  ? const ScanPassPoint(69, 40)
                  : const ScanPassPoint(76, 43),
          tracker: unseen
              ? const ScanPassPoint(78, 16)
              : const ScanPassPoint(79, 48),
          presserIntent: const ScanPassPoint(1.4, 1.0),
          runnerIntent: const ScanPassPoint(1.3, 0),
        );
    }
  }

  static PressureLessonScenario _scenario(
    _PressureScenarioSpec spec,
    math.Random random,
  ) {
    double jitter() => (random.nextDouble() - .5) * .22;
    ScanPassPoint j(ScanPassPoint point) =>
        ScanPassPoint(point.x + jitter(), point.y + jitter());
    final passer = j(spec.passer);
    final focus = j(spec.focus);
    final support = j(spec.support);
    final runner = j(spec.runner);
    final presser = j(spec.presser);
    final cover = j(spec.cover);
    final tracker = j(spec.tracker);
    final actors = <PressureActor>[
      PressureActor(
        id: 'esp-2-carvajal',
        number: 2,
        team: PressureTeam.attack,
        role: PressureActorRole.passer,
        position: passer,
        velocity: const ScanPassPoint(.45, .02),
        intentVelocity: const ScanPassPoint(.45, .02),
        maxSpeed: 5.8,
      ),
      PressureActor(
        id: 'esp-19-yamal',
        number: 19,
        team: PressureTeam.attack,
        role: PressureActorRole.receiver,
        position: focus,
        velocity: const ScanPassPoint(.35, .04),
        intentVelocity: const ScanPassPoint(.35, .04),
        maxSpeed: 7.2,
        maxAcceleration: 6.8,
      ),
      PressureActor(
        id: 'esp-10-olmo',
        number: 10,
        team: PressureTeam.attack,
        role: PressureActorRole.support,
        position: support,
        velocity: const ScanPassPoint(.65, -.1),
        intentVelocity: const ScanPassPoint(.65, -.1),
        maxSpeed: 6.5,
      ),
      PressureActor(
        id: 'esp-17-williams',
        number: 17,
        team: PressureTeam.attack,
        role: PressureActorRole.runner,
        position: runner,
        velocity: spec.runnerIntent,
        intentVelocity: spec.runnerIntent,
        maxSpeed: 8.6,
        maxAcceleration: 4.8,
      ),
      PressureActor(
        id: 'eng-3-shaw',
        number: 3,
        team: PressureTeam.defense,
        role: PressureActorRole.presser,
        position: presser,
        velocity: spec.presserIntent,
        intentVelocity: spec.presserIntent,
        home: presser,
        maxSpeed: 7.0,
        maxAcceleration: 5.4,
        reactivity: spec.presserReactivity,
      ),
      PressureActor(
        id: 'eng-4-rice',
        number: 4,
        team: PressureTeam.defense,
        role: PressureActorRole.cover,
        position: cover,
        velocity: spec.coverIntent,
        intentVelocity: spec.coverIntent,
        home: cover,
        maxSpeed: 6.8,
        maxAcceleration: 5.1,
        reactivity: spec.coverReactivity,
      ),
      PressureActor(
        id: 'eng-5-stones',
        number: 5,
        team: PressureTeam.defense,
        role: PressureActorRole.tracker,
        position: tracker,
        velocity: const ScanPassPoint(.2, 0),
        intentVelocity: const ScanPassPoint(.2, 0),
        home: tracker,
        maxSpeed: 6.9,
        maxAcceleration: 5.0,
        reactivity: spec.trackerReactivity,
      ),
    ];
    final carrier =
        actors.firstWhere((actor) => actor.role == spec.initialCarrierRole);
    return PressureLessonScenario(
      id: '${spec.family.name}-${spec.variant.name}',
      heldOut: spec.variant == PressureLessonVariant.unseen,
      family: spec.family,
      variant: spec.variant,
      learningObjective: spec.objective,
      observationFacts: spec.facts,
      contrastFeature: spec.contrastFeature,
      initialDecisionKind: spec.initialDecisionKind,
      sceneJudgments: _judgmentsFor(spec.family),
      observationStart: PressureWorld(
        clock: 0,
        actors: actors,
        ball: PressureBall(position: carrier.position, carrierId: carrier.id),
        possession: PressurePossession.attack,
      ),
    );
  }
}

class _PressureScenarioSpec {
  final PressureLearningFamily family;
  final PressureLessonVariant variant;
  final PressureLearningObjective objective;
  final List<PressureObservationFact> facts;
  final PressureContrastFeature contrastFeature;
  final PressureEpisodeDecisionKind initialDecisionKind;
  final PressureActorRole initialCarrierRole;
  final ScanPassPoint passer;
  final ScanPassPoint focus;
  final ScanPassPoint support;
  final ScanPassPoint runner;
  final ScanPassPoint presser;
  final ScanPassPoint cover;
  final ScanPassPoint tracker;
  final ScanPassPoint presserIntent;
  final ScanPassPoint coverIntent;
  final ScanPassPoint runnerIntent;
  final double presserReactivity;
  final double coverReactivity;
  final double trackerReactivity;

  const _PressureScenarioSpec({
    required this.family,
    required this.variant,
    required this.objective,
    required this.facts,
    required this.contrastFeature,
    required this.initialDecisionKind,
    this.initialCarrierRole = PressureActorRole.passer,
    required this.passer,
    required this.focus,
    required this.support,
    required this.runner,
    required this.presser,
    required this.cover,
    required this.tracker,
    required this.presserIntent,
    this.coverIntent = const ScanPassPoint(-.35, -.1),
    required this.runnerIntent,
    this.presserReactivity = .82,
    this.coverReactivity = .68,
    this.trackerReactivity = .72,
  });
}

class ScanPassPressureEngine {
  static const double fieldLengthMetres = 105;
  static const double fieldWidthMetres = 68;
  static const double passSpeedMetresPerSecond = 18;
  static const double maximumPlayerSpeed = 8.8;
  static const double touchMaximumMetres = 2.5;
  static const double touchMinimumMetres = 1.0;
  static const double contactRadiusMetres = .78;
  static const double localOffsideReferenceMetres = 92;

  final double stepSeconds;

  const ScanPassPressureEngine({this.stepSeconds = .025});

  PressureObservation observe(PressureLessonScenario scenario) {
    var world = scenario.observationStart;
    final frames = <PressureWorld>[world];
    if (scenario.initialDecisionKind != PressureEpisodeDecisionKind.receive) {
      final holdAt = world.ball.position;
      const horizon = .65;
      while (world.clock + 1e-8 < horizon) {
        final dt = math.min(stepSeconds, horizon - world.clock);
        world = _advanceCarried(world, dt, controlledTarget: holdAt);
        frames.add(world);
      }
      return PressureObservation(
        trace: PressureTrace(frames),
        decisionState: world,
      );
    }
    const preRelease = 1.65;
    while (world.clock + 1e-8 < preRelease) {
      final dt = math.min(stepSeconds, preRelease - world.clock);
      world = _advanceCarried(world, dt, controlledTarget: null);
      frames.add(world);
    }
    final receiver = world.actorByRole(PressureActorRole.receiver);
    final target = _leadTarget(world, receiver);
    final incoming = _simulatePass(
      world,
      const PressureAction(
          kind: PressureActionKind.pass, target: ScanPassPoint(0, 0)),
      forcedTarget: target,
      forcedReceiverRole: PressureActorRole.receiver,
      settleSeconds: 0,
    );
    frames.addAll(incoming.trace.frames.skip(1));
    return PressureObservation(
      trace: PressureTrace(frames),
      decisionState: incoming.after,
    );
  }

  List<PressureDecisionOption> optionsFor(
    PressureWorld world,
    PressureDecisionStage stage,
  ) {
    final carrier = world.carrier;
    if (carrier == null || carrier.team != PressureTeam.attack) return const [];
    if (stage == PressureDecisionStage.firstContact) {
      final channel = carrier.position.y < fieldWidthMetres / 3
          ? PressureFieldChannel.right
          : carrier.position.y > fieldWidthMetres * 2 / 3
              ? PressureFieldChannel.left
              : PressureFieldChannel.central;
      final firstKind = channel == PressureFieldChannel.central
          ? PressureOptionKind.touchLeft
          : PressureOptionKind.touchInside;
      final secondKind = channel == PressureFieldChannel.central
          ? PressureOptionKind.touchRight
          : PressureOptionKind.touchOutside;
      final towardCentre = channel == PressureFieldChannel.left ? -1.75 : 1.75;
      final firstTarget = _clamp(world.ball.position +
          ScanPassPoint(.9,
              channel == PressureFieldChannel.central ? 1.75 : towardCentre));
      final secondTarget = _clamp(world.ball.position +
          ScanPassPoint(.7,
              channel == PressureFieldChannel.central ? -1.75 : -towardCentre));
      final support = world.actorByRole(PressureActorRole.support);
      final runner = world.actorByRole(PressureActorRole.runner);
      final passer = world.actorByRole(PressureActorRole.passer);
      return List.unmodifiable([
        PressureDecisionOption(
          key: channel == PressureFieldChannel.central
              ? 'touch-left'
              : 'touch-inside',
          kind: firstKind,
          action: PressureAction(
              label:
                  channel == PressureFieldChannel.central ? 'left' : 'inside',
              kind: PressureActionKind.firstTouch,
              target: firstTarget),
        ),
        PressureDecisionOption(
          key: channel == PressureFieldChannel.central
              ? 'touch-right'
              : 'touch-outside',
          kind: secondKind,
          action: PressureAction(
              label:
                  channel == PressureFieldChannel.central ? 'right' : 'outside',
              kind: PressureActionKind.firstTouch,
              target: secondTarget),
        ),
        PressureDecisionOption(
          key: 'pass-now',
          kind: PressureOptionKind.immediatePass,
          action: PressureAction(
            label: 'immediate',
            kind: PressureActionKind.pass,
            target: _leadTarget(world, support),
          ),
          targetRole: PressureActorRole.support,
        ),
        PressureDecisionOption(
          key: 'pass-runner-now',
          kind: PressureOptionKind.immediateRunnerPass,
          action: PressureAction(
            label: 'runner-now',
            kind: PressureActionKind.pass,
            target: _leadTarget(world, runner),
          ),
          targetRole: PressureActorRole.runner,
        ),
        PressureDecisionOption(
          key: 'pass-back-now',
          kind: PressureOptionKind.immediateBackPass,
          action: PressureAction(
            label: 'back-now',
            kind: PressureActionKind.pass,
            target: _leadTarget(world, passer),
          ),
          targetRole: PressureActorRole.passer,
        ),
      ]);
    }
    final teammates = world
        .team(PressureTeam.attack)
        .where((actor) => actor.id != carrier.id)
        .toList();
    teammates.sort((a, b) => b.position.x.compareTo(a.position.x));
    return List.unmodifiable([
      for (final teammate in teammates)
        PressureDecisionOption(
          key: switch (teammate.role) {
            PressureActorRole.support => 'pass-support',
            PressureActorRole.runner => 'pass-runner',
            PressureActorRole.receiver => 'pass-focus',
            PressureActorRole.passer => 'pass-recycle',
            _ => 'pass-${teammate.role.name}',
          },
          kind: switch (teammate.role) {
            PressureActorRole.support => PressureOptionKind.passSupport,
            PressureActorRole.runner => PressureOptionKind.passRunner,
            PressureActorRole.receiver => PressureOptionKind.passFocus,
            PressureActorRole.passer => PressureOptionKind.recycle,
            _ => PressureOptionKind.passOther,
          },
          action: PressureAction(
            label: teammate.role.name,
            kind: PressureActionKind.pass,
            target: _leadTarget(world, teammate),
          ),
          targetRole: teammate.role,
        ),
      PressureDecisionOption(
        key: 'carry-space',
        kind: PressureOptionKind.carryForward,
        action: PressureAction(
          label: 'carry',
          kind: PressureActionKind.carry,
          target: _clamp(world.ball.position + const ScanPassPoint(2.2, 0)),
        ),
      ),
    ]);
  }

  PressureEpisodeState startEpisode(
    PressureLessonScenario scenario, {
    int maxDecisions = 3,
  }) {
    final observation = observe(scenario);
    final decisionLimit = math.min(
      3,
      math.min(maxDecisions, scenario.sceneJudgments.length),
    );
    final first = scenario.sceneJudgments.first;
    return PressureEpisodeState(
      scenario: scenario,
      observation: observation,
      world: observation.decisionState,
      pendingDecision: first.kind,
      pendingActorId: _judgmentActorId(
        observation.decisionState,
        first,
        const [],
      ),
      runPlan: null,
      timeline: const [],
      tail: null,
      outcome: null,
      initialBallX: observation.decisionState.ball.position.x,
      maxDecisions: decisionLimit,
    );
  }

  List<PressureDecisionOption> episodeOptions(PressureEpisodeState episode) {
    return switch (episode.pendingDecision) {
      PressureEpisodeDecisionKind.receive =>
        optionsFor(episode.world, PressureDecisionStage.firstContact),
      PressureEpisodeDecisionKind.onBall =>
        optionsFor(episode.world, PressureDecisionStage.reRead),
      PressureEpisodeDecisionKind.support || null => const [],
    };
  }

  PressureEpisodeState chooseEpisodeOption(
    PressureEpisodeState episode,
    PressureDecisionOption option,
  ) {
    final kind = episode.pendingDecision;
    if (episode.isComplete ||
        (kind != PressureEpisodeDecisionKind.receive &&
            kind != PressureEpisodeDecisionKind.onBall)) {
      return episode;
    }
    final options = episodeOptions(episode);
    if (!options.any((candidate) => candidate.key == option.key)) {
      return episode;
    }
    final actorId = episode.pendingActorId;
    if (actorId == null || episode.world.carrier?.id != actorId) return episode;
    final planBefore = episode.runPlan;
    final result = _simulateOption(
      episode.world,
      option,
      runPlan: planBefore,
    );
    final planAfter = _updatedRunPlan(planBefore, result.after);
    final decision = PressureEpisodeDecision(
      index: episode.timeline.length,
      kind: kind!,
      actorId: actorId,
      before: episode.world,
      after: result.after,
      availableOptions: options,
      selectedOption: option,
      requestedTarget: option.action.target,
      executedTarget: result.after.ball.position,
      learnerTrace: result.trace,
      actionResult: result,
      supportResult: null,
      runPlanBefore: planBefore,
      runPlanAfter: planAfter,
    );
    return _continueEpisode(episode, decision);
  }

  PressureEpisodeState chooseSupportTarget(
    PressureEpisodeState episode,
    ScanPassPoint requestedTarget,
  ) {
    if (episode.isComplete ||
        episode.pendingDecision != PressureEpisodeDecisionKind.support) {
      return episode;
    }
    final actorId = episode.pendingActorId;
    if (actorId == null || actorId == episode.world.ball.carrierId) {
      return episode;
    }
    final actor = episode.world.actorById(actorId);
    final result = simulateSupport(
      episode.world,
      requestedTarget,
      focusRole: actor.role,
      actorId: actorId,
    );
    final plan = PressureRunPlan(
      actorId: actorId,
      actorRole: actor.role,
      requestedTarget: requestedTarget,
      boundedTarget: result.boundedTarget,
      startedAt: episode.world.clock,
      status: _runPlanStatus(
        actorId,
        result.boundedTarget,
        result.after,
      ),
    );
    final decision = PressureEpisodeDecision(
      index: episode.timeline.length,
      kind: PressureEpisodeDecisionKind.support,
      actorId: actorId,
      before: episode.world,
      after: result.after,
      availableOptions: const [],
      selectedOption: null,
      requestedTarget: requestedTarget,
      executedTarget: result.executedTarget,
      learnerTrace: result.movementTrace,
      actionResult: null,
      supportResult: result,
      runPlanBefore: episode.runPlan,
      runPlanAfter: plan,
    );
    return _continueEpisode(episode, decision);
  }

  /// Restores the selected snapshot by identity and discards only its suffix.
  /// Earlier decisions are retained unchanged for causal retry.
  PressureEpisodeState retryFrom(
    PressureEpisodeState completed,
    int decisionIndex,
  ) {
    if (decisionIndex < 0 || decisionIndex >= completed.timeline.length) {
      return completed;
    }
    final selected = completed.timeline[decisionIndex];
    return PressureEpisodeState(
      scenario: completed.scenario,
      observation: completed.observation,
      world: selected.before,
      pendingDecision: selected.kind,
      pendingActorId: selected.actorId,
      runPlan: selected.runPlanBefore,
      timeline: completed.timeline.take(decisionIndex).toList(),
      tail: null,
      outcome: null,
      initialBallX: completed.initialBallX,
      maxDecisions: completed.maxDecisions,
    );
  }

  /// Runs another choice from the selected decision snapshot. It never mutates
  /// the original timeline and uses the same defender and teammate policy.
  PressureEpisodeDecision alternativeOption(
    PressureEpisodeDecision original,
    PressureDecisionOption option,
  ) {
    final result = _simulateOption(
      original.before,
      option,
      runPlan: original.runPlanBefore,
    );
    return PressureEpisodeDecision(
      index: original.index,
      kind: original.kind,
      actorId: original.actorId,
      before: original.before,
      after: result.after,
      availableOptions: original.availableOptions,
      selectedOption: option,
      requestedTarget: option.action.target,
      executedTarget: result.after.ball.position,
      learnerTrace: result.trace,
      actionResult: result,
      supportResult: null,
      runPlanBefore: original.runPlanBefore,
      runPlanAfter: _updatedRunPlan(original.runPlanBefore, result.after),
    );
  }

  PressureEpisodeDecision alternativeSupport(
    PressureEpisodeDecision original,
    ScanPassPoint target,
  ) {
    final result = simulateSupport(
      original.before,
      target,
      focusRole: original.before.actorById(original.actorId).role,
      actorId: original.actorId,
      stationaryMover: true,
    );
    final plan = PressureRunPlan(
      actorId: original.actorId,
      actorRole: result.focusRole,
      requestedTarget: target,
      boundedTarget: result.boundedTarget,
      startedAt: original.before.clock,
      status: _runPlanStatus(
        original.actorId,
        result.boundedTarget,
        result.after,
      ),
    );
    return PressureEpisodeDecision(
      index: original.index,
      kind: PressureEpisodeDecisionKind.support,
      actorId: original.actorId,
      before: original.before,
      after: result.after,
      availableOptions: const [],
      selectedOption: null,
      requestedTarget: target,
      executedTarget: result.executedTarget,
      learnerTrace: result.movementTrace,
      actionResult: null,
      supportResult: result,
      runPlanBefore: original.runPlanBefore,
      runPlanAfter: plan,
    );
  }

  PressureSupportResult simulateSupport(
    PressureWorld before,
    ScanPassPoint requestedTarget, {
    PressureActorRole focusRole = PressureActorRole.receiver,
    String? actorId,
    bool stationaryMover = false,
  }) {
    final focus = actorId == null
        ? before.actorByRole(focusRole)
        : before.actorById(actorId);
    final carrier = before.carrier;
    if (carrier == null || carrier.team != PressureTeam.attack) {
      throw StateError('Off-ball movement requires an attacking carrier.');
    }
    final delta = requestedTarget - focus.position;
    final boundedDistance = math.min(8.0, delta.distance);
    final boundedTarget = _clamp(focus.position +
        (delta.distance <= 1e-9
            ? const ScanPassPoint(0, 0)
            : _unit(delta) * boundedDistance));
    // Release before a holding carrier would be reached, rather than making
    // every support judgment consume a fixed half-second. This budget depends
    // only on the shared starting world, so stationary and moving alternatives
    // receive exactly the same teammate reaction time.
    final pressureArrival = _pressureArrivalSeconds(before);
    final releaseSeconds = (pressureArrival - .12).clamp(.24, .68).toDouble();
    final movement = _advanceSupportMovement(
      before,
      actorId: focus.id,
      target: boundedTarget,
      maximumDuration: releaseSeconds,
      reactToOpening: true,
      holdMoverStationary: stationaryMover,
    );
    final afterMovement = movement.after;
    final movementTrace = movement.trace;
    final stationaryMotion = _advanceSupportMovement(
      before,
      actorId: focus.id,
      target: focus.position,
      maximumDuration: afterMovement.clock - before.clock,
      reactToOpening: false,
      holdMoverStationary: true,
    );
    final stationary = stationaryMotion.after;
    final comparableLaneWorlds =
        stationary.possession == afterMovement.possession &&
            stationary.carrier?.role == afterMovement.carrier?.role;
    final focusPath = movementTrace.frames
        .map((frame) => frame.actorById(focus.id).position)
        .toList();
    var movementDistance = 0.0;
    for (var index = 1; index < focusPath.length; index++) {
      movementDistance += focusPath[index - 1].distanceTo(focusPath[index]);
    }
    final movedFocus = afterMovement.actorById(focus.id);
    final stationaryFocus = stationary.actorById(focus.id);
    final movedDefender = _nearestDefender(afterMovement, movedFocus.position);
    final stationaryDefender =
        _nearestDefender(stationary, stationaryFocus.position);
    return PressureSupportResult(
      before: before,
      afterMovement: afterMovement,
      after: afterMovement,
      actorId: focus.id,
      carrierId: carrier.id,
      focusRole: focus.role,
      requestedTarget: requestedTarget,
      boundedTarget: boundedTarget,
      executedTarget: afterMovement.actorById(focus.id).position,
      movementDistanceMetres: movementDistance,
      movementTrace: movementTrace,
      continuation: null,
      laneChanges: comparableLaneWorlds
          ? _laneChanges(stationary, afterMovement)
          : const [],
      stationaryCounterfactual: stationary,
      separationChangeMetres: comparableLaneWorlds
          ? movedDefender.position.distanceTo(movedFocus.position) -
              stationaryDefender.position.distanceTo(stationaryFocus.position)
          : 0,
      separationDefenderRole: movedDefender.role,
      contact: movement.contact,
    );
  }

  _PressureSupportMotion _advanceSupportMovement(
    PressureWorld before, {
    required String actorId,
    required ScanPassPoint target,
    required double maximumDuration,
    required bool reactToOpening,
    bool holdMoverStationary = false,
  }) {
    var world = before;
    final frames = <PressureWorld>[world];
    PressureContactEvidence? contact;
    final holdTarget = before.carrier?.position;
    final initiallySafe = connections(before)
        .where((connection) => connection.safe && connection.forward)
        .map((connection) => connection.receiverRole)
        .toSet();
    var nextOpeningCheck = math.min(.32, maximumDuration);
    while (world.clock < before.clock + maximumDuration - 1e-8 &&
        world.possession == PressurePossession.attack) {
      final elapsed = world.clock - before.clock;
      final dt = math.min(
        stepSeconds,
        before.clock + maximumDuration - world.clock,
      );
      final previous = world;
      world = _advanceCarried(
        world,
        dt,
        controlledTarget: holdTarget,
        controlledOffBallId: actorId,
        controlledOffBallTarget: target,
        holdControlledOffBallStationary: holdMoverStationary,
      );
      final hit = _carrierContact(previous, world);
      if (hit != null) {
        world = _contactWorldBetween(previous, world, hit);
        contact = PressureContactEvidence(
          clock: hit.clock,
          defenderNumber: hit.actor.number,
          defenderId: hit.actor.id,
          point: world.ball.position,
        );
      }
      frames.add(world);
      final now = elapsed + dt;
      if (reactToOpening && now + 1e-8 >= nextOpeningCheck) {
        final opened = connections(world).any((connection) =>
            connection.safe &&
            connection.forward &&
            !initiallySafe.contains(connection.receiverRole));
        if (opened) break;
        nextOpeningCheck += .12;
      }
    }
    return _PressureSupportMotion(
      after: world,
      trace: PressureTrace(frames),
      contact: contact,
    );
  }

  PressureEpisodeState _continueEpisode(
    PressureEpisodeState episode,
    PressureEpisodeDecision decision,
  ) {
    final timeline = [...episode.timeline, decision];
    var world = decision.after;
    var runPlan = decision.runPlanAfter;
    var outcome = _terminalOutcome(decision.offside, world);
    PressureSceneTail? tail;
    final scheduleComplete = timeline.length >= episode.maxDecisions ||
        timeline.length >= episode.scenario.sceneJudgments.length;
    if (outcome == null && scheduleComplete) {
      tail = _simulateTail(world, runPlan);
      world = tail.after;
      runPlan = tail.runPlanAfter;
      outcome = _terminalOutcome(tail.offside, world) ??
          _positiveOutcome(episode, timeline, tail) ??
          PressureEpisodeOutcome.retainedUnresolved;
    }
    PressureEpisodeDecisionKind? pending;
    String? pendingActorId;
    if (outcome == null) {
      final next = episode.scenario.sceneJudgments[timeline.length];
      pending = next.kind;
      pendingActorId = _judgmentActorId(world, next, timeline);
    }
    return PressureEpisodeState(
      scenario: episode.scenario,
      observation: episode.observation,
      world: world,
      pendingDecision: pending,
      pendingActorId: pendingActorId,
      runPlan: runPlan,
      timeline: timeline,
      tail: tail,
      outcome: outcome,
      initialBallX: episode.initialBallX,
      maxDecisions: episode.maxDecisions,
    );
  }

  String _judgmentActorId(
    PressureWorld world,
    PressureSceneJudgment judgment,
    List<PressureEpisodeDecision> timeline,
  ) {
    if (judgment.actorRule == PressureSceneActorRule.currentCarrier) {
      return world.carrier!.id;
    }
    if (judgment.actorRule == PressureSceneActorRule.previousActorOrRole &&
        timeline.isNotEmpty) {
      final previous = timeline.last.actorId;
      if (previous != world.ball.carrierId) return previous;
    }
    final declared = world.actorByRole(judgment.actorRole!);
    if (declared.id != world.ball.carrierId) return declared.id;
    return world
        .team(PressureTeam.attack)
        .firstWhere((actor) => actor.id != world.ball.carrierId)
        .id;
  }

  PressureEpisodeOutcome? _terminalOutcome(bool offside, PressureWorld world) {
    if (offside) return PressureEpisodeOutcome.offside;
    if (world.possession == PressurePossession.defense) {
      return PressureEpisodeOutcome.intercepted;
    }
    if (world.possession == PressurePossession.loose) {
      return PressureEpisodeOutcome.loose;
    }
    if (world.ball.position.x >= 90) {
      return PressureEpisodeOutcome.penetration;
    }
    return null;
  }

  PressureEpisodeOutcome? _positiveOutcome(
    PressureEpisodeState episode,
    List<PressureEpisodeDecision> timeline,
    PressureSceneTail tail,
  ) {
    final after = tail.after;
    final carrier = after.carrier;
    if (carrier == null || carrier.team != PressureTeam.attack) return null;
    final clearance = _nearestDefender(after, carrier.position)
        .position
        .distanceTo(carrier.position);
    final pressureLine = math.max(
      after.actorByRole(PressureActorRole.presser).position.x,
      after.actorByRole(PressureActorRole.cover).position.x,
    );
    final escaped = after.ball.position.x >= pressureLine + 3 &&
        after.ball.position.x - episode.initialBallX >= 8 &&
        clearance >= 2.1 &&
        connections(after).any(
          (connection) => connection.safe && connection.forward,
        );
    if (escaped) return PressureEpisodeOutcome.pressureEscape;
    final recycleDecision = timeline
        .where(
            (item) => item.selectedOption?.kind == PressureOptionKind.recycle)
        .firstOrNull;
    final tailRecycle = tail.actions
        .where(
          (action) => action.kind == PressureAutomaticKind.recycle,
        )
        .firstOrNull;
    final recycleBefore = recycleDecision?.before ?? tailRecycle?.result.before;
    final recycled = recycleBefore != null;
    final forwardWasClosed = recycleBefore != null &&
        !connections(recycleBefore).any(
          (connection) => connection.safe && connection.forward,
        );
    final switchedWidth = (after.ball.position.y -
                episode.observation.decisionState.ball.position.y)
            .abs() >=
        12;
    if (recycled && forwardWasClosed && switchedWidth && clearance >= 2) {
      return PressureEpisodeOutcome.safeRecycle;
    }
    return null;
  }

  PressureSceneTail _simulateTail(
    PressureWorld before,
    PressureRunPlan? runPlan,
  ) {
    if (before.possession != PressurePossession.attack ||
        before.carrier?.team != PressureTeam.attack) {
      return PressureSceneTail(
        before: before,
        after: before,
        trace: PressureTrace([before]),
        actions: const [],
        runPlanBefore: runPlan,
        runPlanAfter: _updatedRunPlan(runPlan, before),
      );
    }
    final continuation = _adaptiveContinuation(before, runPlan);
    final afterPlan = _updatedRunPlan(runPlan, continuation.result.after);
    return PressureSceneTail(
      before: before,
      after: continuation.result.after,
      trace: continuation.result.trace,
      actions: [continuation],
      runPlanBefore: runPlan,
      runPlanAfter: afterPlan,
    );
  }

  /// Builds a bounded learning example from the same scene start. Candidate
  /// selection may use the declared teaching objective, but every candidate is
  /// executed by the ordinary sampled resolver and no result is forced.
  PressureTeachingExample teachingExample(PressureLessonScenario scenario) {
    var episode = startEpisode(scenario);
    while (!episode.isComplete) {
      if (episode.pendingDecision == PressureEpisodeDecisionKind.support) {
        final actor = episode.world.actorById(episode.pendingActorId!);
        final targets = <ScanPassPoint>[
          actor.position + const ScanPassPoint(8, 0),
          actor.position + const ScanPassPoint(-8, 0),
          actor.position + const ScanPassPoint(0, 8),
          actor.position + const ScanPassPoint(0, -8),
          actor.position + const ScanPassPoint(6, 0),
          actor.position + const ScanPassPoint(4.5, 4.5),
          actor.position + const ScanPassPoint(4.5, -4.5),
          actor.position + const ScanPassPoint(-4.5, -4.5),
          actor.position + const ScanPassPoint(-3.5, 4.5),
          actor.position,
        ];
        PressureEpisodeState? selected;
        var bestScore = -double.infinity;
        for (final target in targets) {
          final candidate = chooseSupportTarget(episode, target);
          if (candidate.timeline.length == episode.timeline.length) continue;
          final support = candidate.timeline.last.supportResult!;
          var score = candidate.world.possession == PressurePossession.attack
              ? 1000.0
              : -1000.0;
          score += support.movementDistanceMetres * .4;
          score += support.laneChanges
                  .where((lane) => lane.usableAfter && !lane.usableBefore)
                  .length *
              30;
          score += support.laneChanges
              .map((lane) => lane.clearanceChangeMetres)
              .fold(0.0, math.max);
          score += math.max(0, support.separationChangeMetres) * 8;
          if (score > bestScore) {
            bestScore = score;
            selected = candidate;
          }
        }
        episode = selected!;
        continue;
      }
      PressureEpisodeState? selected;
      var bestScore = -double.infinity;
      for (final option in episodeOptions(episode)) {
        final candidate = chooseEpisodeOption(episode, option);
        if (candidate.timeline.length == episode.timeline.length) continue;
        final result = candidate.timeline.last.actionResult!;
        var score = result.after.possession == PressurePossession.attack
            ? 1000.0
            : -1000.0;
        if (candidate.isComplete) {
          score += candidate.world.possession == PressurePossession.attack
              ? 250
              : -1400;
          if (candidate.outcome == PressureEpisodeOutcome.offside) {
            score -= 800;
          }
        }
        if (result.offside) score -= 800;
        score += result.assessment.pressureClearanceMetres * 4;
        score += result.assessment.actionProgressMetres * 2;
        score += result.assessment.connections
                .where((connection) => connection.safe && connection.forward)
                .length *
            12;
        score += switch (scenario.learningObjective) {
          PressureLearningObjective.receiveAwayFromPressure =>
            result.assessment.pressureClearanceMetres * 3,
          PressureLearningObjective.commitThenRelease =>
            option.action.kind == PressureActionKind.carry ? 3 : 5,
          PressureLearningObjective.moveAfterPassing =>
            option.action.kind == PressureActionKind.pass ? 6 : 0,
          PressureLearningObjective.timeTheThroughPass =>
            result.intendedReceiverRole == PressureActorRole.runner ? 8 : 0,
          PressureLearningObjective.connectTheThirdPlayer =>
            option.action.kind == PressureActionKind.pass ? 7 : 0,
          PressureLearningObjective.recycleWhenForwardPlayCloses =>
            option.kind == PressureOptionKind.recycle ? 8 : 0,
        };
        if (score > bestScore) {
          bestScore = score;
          selected = candidate;
        }
      }
      episode = selected!;
    }
    return PressureTeachingExample(
      scenario: scenario,
      observation: episode.observation,
      timeline: episode.timeline,
      tail: episode.tail,
      outcome: episode.outcome!,
    );
  }

  PressureAutomaticContinuation _adaptiveContinuation(
    PressureWorld world,
    PressureRunPlan? runPlan,
  ) {
    final options = optionsFor(world, PressureDecisionStage.reRead);
    final candidates = <({
      PressureDecisionOption option,
      PressureSimulationResult result,
      double score,
    })>[];
    for (final option in options) {
      final result = _simulateOption(world, option, runPlan: runPlan);
      var score = result.after.possession == PressurePossession.attack
          ? 100.0
          : -1000.0;
      if (result.offside) score -= 800;
      score += result.assessment.actionProgressMetres * 1.35;
      score += result.assessment.pressureClearanceMetres * 3.0;
      score += result.assessment.connections
              .where((connection) => connection.safe && connection.forward)
              .length *
          7.0;
      if (option.kind == PressureOptionKind.recycle) {
        final forwardOpen = connections(world)
            .any((connection) => connection.safe && connection.forward);
        score += forwardOpen ? -7 : 9;
      }
      candidates.add((option: option, result: result, score: score));
    }
    candidates.sort((a, b) => b.score.compareTo(a.score));
    final selected = candidates.first;
    final kind = selected.option.action.kind == PressureActionKind.carry
        ? PressureAutomaticKind.carry
        : selected.option.kind == PressureOptionKind.recycle
            ? PressureAutomaticKind.recycle
            : PressureAutomaticKind.pass;
    return PressureAutomaticContinuation(kind: kind, result: selected.result);
  }

  PressureSimulationResult _simulateWithOffBallTarget(
    PressureWorld world,
    PressureDecisionOption option,
    PressureRunPlan runPlan,
  ) {
    final controlledId =
        world.carrier?.id == runPlan.actorId || !runPlan.isActive
            ? null
            : runPlan.actorId;
    final action = option.action;
    return switch (action.kind) {
      PressureActionKind.pass => _simulatePass(
          world,
          PressureAction(
            label: action.label,
            kind: action.kind,
            target:
                option.targetRole == runPlan.actorRole && controlledId != null
                    ? _controlledLeadTarget(
                        world,
                        world.actorById(runPlan.actorId),
                        runPlan.boundedTarget,
                      )
                    : action.target,
          ),
          forcedReceiverRole: option.targetRole,
          controlledOffBallId: controlledId,
          controlledOffBallTarget: runPlan.boundedTarget,
        ),
      PressureActionKind.carry => _simulateControlled(
          world,
          action,
          minimum: .4,
          maximum: 3,
          settleSeconds: .28,
          controlledOffBallId: controlledId,
          controlledOffBallTarget: runPlan.boundedTarget,
        ),
      PressureActionKind.firstTouch => _simulateControlled(
          world,
          action,
          minimum: touchMinimumMetres,
          maximum: touchMaximumMetres,
          settleSeconds: .34,
          controlledOffBallId: controlledId,
          controlledOffBallTarget: runPlan.boundedTarget,
        ),
      PressureActionKind.offBallRun => simulate(world, action),
    };
  }

  PressureRunPlan? _updatedRunPlan(
    PressureRunPlan? plan,
    PressureWorld world,
  ) {
    if (plan == null || !plan.isActive) return plan;
    return plan.copyWith(
      status: _runPlanStatus(plan.actorId, plan.boundedTarget, world),
    );
  }

  PressureRunPlanStatus _runPlanStatus(
    String actorId,
    ScanPassPoint target,
    PressureWorld world,
  ) {
    if (world.possession != PressurePossession.attack ||
        world.ball.carrierId == actorId) {
      return PressureRunPlanStatus.interrupted;
    }
    final actor = world.actorById(actorId);
    if (actor.position.distanceTo(target) <= .08 &&
        actor.velocity.distance <= .5) {
      return PressureRunPlanStatus.reached;
    }
    return PressureRunPlanStatus.active;
  }

  List<PressureLaneChange> _laneChanges(
    PressureWorld before,
    PressureWorld after,
  ) {
    final beforeByRole = {
      for (final lane in connections(before)) lane.receiverRole: lane,
    };
    final afterByRole = {
      for (final lane in connections(after)) lane.receiverRole: lane,
    };
    final roles = {...beforeByRole.keys, ...afterByRole.keys};
    return List.unmodifiable([
      for (final role in roles)
        PressureLaneChange(
          receiverRole: role,
          beforeDefenderRole: beforeByRole[role]?.blockingDefenderRole,
          afterDefenderRole: afterByRole[role]?.blockingDefenderRole,
          usableBefore: beforeByRole[role]?.safe ?? false,
          usableAfter: afterByRole[role]?.safe ?? false,
          clearanceChangeMetres:
              (afterByRole[role]?.closestDefenderMetres ?? 0) -
                  (beforeByRole[role]?.closestDefenderMetres ?? 0),
        ),
    ]);
  }

  PressureSituationContext situationContext(
    PressureWorld world,
    PressureDecisionStage stage, {
    String? decisionActorId,
  }) {
    final carrier = world.carrier;
    final receiver = world.actorByRole(PressureActorRole.receiver);
    final currentFocus = decisionActorId == null
        ? carrier ?? receiver
        : world.actorById(decisionActorId);
    final nearestPressure = _nearestDefender(world, currentFocus.position);
    final cover = world.actorByRole(PressureActorRole.cover);
    final support = world.actorByRole(PressureActorRole.support);
    final runner = world.actorByRole(PressureActorRole.runner);
    final pressureDelta = nearestPressure.position.y - currentFocus.position.y;
    final approachSide = pressureDelta < -1
        ? PressureApproachSide.outside
        : pressureDelta > 1
            ? PressureApproachSide.inside
            : PressureApproachSide.level;
    final laneTarget = support.id == carrier?.id ? receiver : support;
    final coverLanePoint = _closestPointOnSegment(
      cover.position,
      world.ball.position,
      laneTarget.position,
    );
    return PressureSituationContext(
      stage: stage,
      fieldBand: currentFocus.position.x >= fieldLengthMetres * 2 / 3
          ? PressureFieldBand.attackingThird
          : PressureFieldBand.middleThird,
      fieldChannel: currentFocus.position.y < fieldWidthMetres / 3
          ? PressureFieldChannel.right
          : currentFocus.position.y > fieldWidthMetres * 2 / 3
              ? PressureFieldChannel.left
              : PressureFieldChannel.central,
      carrierNumber: carrier?.number ?? currentFocus.number,
      focusNumber: currentFocus.number,
      presserNumber: nearestPressure.number,
      approachSide: approachSide,
      pressureMovement: _movingToward(
        nearestPressure,
        currentFocus.position,
        currentFocus.velocity,
      )
          ? PressureMovement.closing
          : PressureMovement.holding,
      pressureDistanceMetres:
          nearestPressure.position.distanceTo(currentFocus.position),
      coverNumber: cover.number,
      supportNumber: laneTarget.number,
      coverMovement: _movingToward(
        cover,
        coverLanePoint,
        const ScanPassPoint(0, 0),
      )
          ? PressureMovement.closing
          : PressureMovement.holding,
      coverLaneDistanceMetres: cover.position.distanceTo(coverLanePoint),
      runnerNumber: runner.number,
      runnerMovement: runner.velocity.x > 2.1
          ? PressureRunnerMovement.breakingForward
          : runner.velocity.x > .8
              ? PressureRunnerMovement.movingForward
              : PressureRunnerMovement.held,
    );
  }

  PressureActionEvidence actionEvidence(PressureSimulationResult result) {
    final beforeCarrier = result.before.carrier!;
    final beforeDefender =
        _nearestDefender(result.before, beforeCarrier.position);
    final afterCarrier = result.after.carrier;
    final retained = afterCarrier?.team == PressureTeam.attack;
    final beforeClearance =
        beforeDefender.position.distanceTo(beforeCarrier.position);
    final afterClearance =
        retained ? result.assessment.pressureClearanceMetres : 0.0;
    final separationChange = retained ? afterClearance - beforeClearance : 0.0;

    final destinationRole = result.intendedReceiverRole;
    final destinationNumber = destinationRole == null
        ? null
        : result.before.actorByRole(destinationRole).number;
    final received = result.action.kind == PressureActionKind.pass &&
        retained &&
        afterCarrier!.role == destinationRole;
    final beforeForwardRoles = connections(result.before)
        .where((connection) => connection.safe && connection.forward)
        .map((connection) => connection.receiverRole)
        .toSet();
    PressureConnectionEvidence? openedConnection;
    if (retained) {
      for (final connection in result.assessment.connections) {
        if (connection.safe &&
            connection.forward &&
            !beforeForwardRoles.contains(connection.receiverRole)) {
          openedConnection = connection;
          break;
        }
      }
    }

    late final PressureActionBenefit benefit;
    int? benefitReceiverNumber;
    if (received) {
      benefitReceiverNumber = afterCarrier.number;
      benefit = result.assessment.actionProgressMetres >= 1
          ? PressureActionBenefit.forwardPassReceived
          : PressureActionBenefit.passReceived;
    } else if (retained && separationChange >= .25) {
      benefit = PressureActionBenefit.increasedSeparation;
    } else if (openedConnection != null) {
      benefitReceiverNumber =
          result.after.actorByRole(openedConnection.receiverRole).number;
      benefit = PressureActionBenefit.openedSimulatedForwardLane;
    } else if (retained && result.assessment.actionProgressMetres >= 1) {
      benefit = PressureActionBenefit.progressedWithControl;
    } else if (retained) {
      benefit = PressureActionBenefit.retainedControl;
    } else {
      benefit = PressureActionBenefit.none;
    }

    late final PressureActionLimitation limitation;
    int? defenderNumber;
    if (result.offside) {
      limitation = PressureActionLimitation.offside;
    } else if (result.contact != null &&
        result.after.possession == PressurePossession.defense) {
      limitation = PressureActionLimitation.interception;
      defenderNumber = result.contact!.defenderNumber;
    } else if (!retained) {
      limitation = PressureActionLimitation.looseBall;
    } else if (result.assessment.missedForwardOpportunity) {
      limitation = PressureActionLimitation.lostForwardWindow;
    } else {
      final nearest = _nearestDefender(result.after, afterCarrier!.position);
      defenderNumber = nearest.number;
      if (afterClearance <= 1.5 || separationChange < -.2) {
        limitation = PressureActionLimitation.closingPressure;
      } else if (result.assessment.actionProgressMetres < 1 &&
          openedConnection == null) {
        limitation = PressureActionLimitation.limitedProgression;
      } else {
        limitation = PressureActionLimitation.remainingPressure;
      }
    }

    final contact = result.contact;
    final freezeFrame = contact == null
        ? result.after
        : result.trace.frames.reduce((a, b) =>
            (a.clock - contact.clock).abs() <= (b.clock - contact.clock).abs()
                ? a
                : b);
    return PressureActionEvidence(
      benefit: benefit,
      limitation: limitation,
      actorNumber: beforeCarrier.number,
      destinationNumber: destinationNumber,
      benefitReceiverNumber: benefitReceiverNumber,
      defenderNumber: defenderNumber,
      separationChangeMetres: separationChange,
      pressureClearanceMetres: afterClearance,
      progressMetres: result.assessment.actionProgressMetres,
      contactSeconds:
          contact == null ? null : contact.clock - result.before.clock,
      contactPoint: contact?.point,
      freezeFrame: freezeFrame,
    );
  }

  /// Uses an explicit local offside reference for this reduced-sided lesson.
  /// The reference represents the goal-side defenders outside the teaching
  /// crop; visible defenders can move the line farther goal-side. The line is
  /// shown on the pitch and is evaluated only when the intended receiver
  /// actually receives or plays the pass. Merely standing beyond it is not an
  /// offence, and a defender interception before reception remains an
  /// interception.
  bool receiverIsOnside(PressureWorld world, PressureActor receiver) {
    if (receiver.position.x <= world.ball.position.x + .01 ||
        receiver.position.x <= fieldLengthMetres / 2) {
      return true;
    }
    return receiver.position.x <= offsideReferenceX(world) + .01;
  }

  /// The visible reference used by the reduced-sided exercise. Equality is
  /// onside; the receiver must be beyond both this line and the ball in the
  /// opponents' half before involvement can be penalised.
  double offsideReferenceX(PressureWorld _) => localOffsideReferenceMetres;

  PressureSimulationResult simulate(
    PressureWorld before,
    PressureAction action,
  ) {
    return switch (action.kind) {
      PressureActionKind.pass => _simulatePass(before, action),
      PressureActionKind.firstTouch => _simulateControlled(
          before,
          action,
          minimum: touchMinimumMetres,
          maximum: touchMaximumMetres,
          settleSeconds: .34,
        ),
      PressureActionKind.carry => _simulateControlled(
          before,
          action,
          minimum: .4,
          maximum: 3.0,
          settleSeconds: .28,
        ),
      PressureActionKind.offBallRun => _stationaryResult(before, action),
    };
  }

  PressureSimulationResult _simulateOption(
    PressureWorld before,
    PressureDecisionOption option, {
    PressureRunPlan? runPlan,
  }) {
    if (runPlan?.isActive == true &&
        before.ball.carrierId != runPlan!.actorId) {
      return _simulateWithOffBallTarget(before, option, runPlan);
    }
    if (option.action.kind != PressureActionKind.pass ||
        option.targetRole == null) {
      return simulate(before, option.action);
    }
    return _simulatePass(
      before,
      option.action,
      forcedReceiverRole: option.targetRole,
    );
  }

  List<PressureSimulationResult> compare(
    PressureWorld snapshot,
    Iterable<PressureAction> actions,
  ) =>
      List.unmodifiable(actions.map((action) => simulate(snapshot, action)));

  List<PressureConnectionEvidence> connections(PressureWorld world) {
    final carrier = world.carrier;
    if (carrier == null || carrier.team != PressureTeam.attack) return const [];
    final values = <PressureConnectionEvidence>[];
    for (final receiver in world.team(PressureTeam.attack)) {
      if (receiver.id == carrier.id) continue;
      final target = _leadTarget(world, receiver);
      final distance = carrier.position.distanceTo(target);
      if (distance < 1) continue;
      final motion = _runPass(
        world,
        target,
        forcedReceiverRole: receiver.role,
        settleSeconds: .22,
      )!;
      final finalReceiver = motion.after.actorByRole(receiver.role);
      final receiverClearance = motion.after
          .team(PressureTeam.defense)
          .map((defender) =>
              defender.position.distanceTo(finalReceiver.position))
          .reduce(math.min);
      final closest = _closestFlightDefender(motion.trace);
      PressureActorRole? blockerRole = closest?.role;
      final contact = motion.contact;
      if (contact != null) {
        blockerRole = motion.after.actorById(contact.defenderId).role;
      }
      values.add(PressureConnectionEvidence(
        receiverRole: receiver.role,
        target: target,
        forwardGainMetres: target.x - carrier.position.x,
        receiverClearanceMetres: receiverClearance,
        closestDefenderMetres: closest?.distanceToBall ?? double.infinity,
        retainedByReceiver:
            motion.after.possession == PressurePossession.attack &&
                motion.after.carrier?.role == receiver.role,
        onsideAtRelease: motion.onsideAtRelease,
        blockingDefenderRole: blockerRole,
      ));
    }
    values.sort((a, b) {
      final safety = (b.safe ? 1 : 0).compareTo(a.safe ? 1 : 0);
      if (safety != 0) return safety;
      return b.forwardGainMetres.compareTo(a.forwardGainMetres);
    });
    return List.unmodifiable(values);
  }

  PressureSimulationResult _simulateControlled(
    PressureWorld before,
    PressureAction action, {
    required double minimum,
    required double maximum,
    required double settleSeconds,
    PressureActorRole? controlledOffBallRole,
    String? controlledOffBallId,
    ScanPassPoint? controlledOffBallTarget,
  }) {
    final carrier = before.carrier;
    if (carrier == null || carrier.team != PressureTeam.attack) {
      return _stationaryResult(before, action);
    }
    final footOffset = before.ball.position - carrier.position;
    final delta = action.target - before.ball.position;
    final length = delta.distance;
    final boundedLength = length.clamp(minimum, maximum).toDouble();
    final ballTarget = _clamp(
      before.ball.position + _unit(delta) * boundedLength,
    );
    final carrierTarget = _clamp(ballTarget - footOffset);
    var world = before;
    final frames = <PressureWorld>[world];
    PressureContactEvidence? contact;
    var movementSteps = 0;
    while (world.carrier!.position.distanceTo(carrierTarget) > .015 &&
        movementSteps < 200) {
      final dt = stepSeconds;
      final previous = world;
      world = _advanceCarried(
        world,
        dt,
        controlledTarget: carrierTarget,
        controlledOffBallRole: controlledOffBallRole,
        controlledOffBallId: controlledOffBallId,
        controlledOffBallTarget: controlledOffBallTarget,
      );
      final hit = _carrierContact(previous, world);
      if (hit != null) {
        world = _contactWorldBetween(previous, world, hit);
        frames.add(world);
        contact = PressureContactEvidence(
          clock: hit.clock,
          defenderNumber: hit.actor.number,
          defenderId: hit.actor.id,
          point: world.ball.position,
        );
        break;
      }
      frames.add(world);
      movementSteps += 1;
    }
    if (contact == null && world.possession == PressurePossession.attack) {
      var settled = 0.0;
      while (settled + 1e-8 < settleSeconds) {
        final dt = math.min(stepSeconds, settleSeconds - settled);
        final previous = world;
        world = _advanceCarried(
          world,
          dt,
          controlledTarget: carrierTarget,
          controlledOffBallRole: controlledOffBallRole,
          controlledOffBallId: controlledOffBallId,
          controlledOffBallTarget: controlledOffBallTarget,
        );
        final hit = _carrierContact(previous, world);
        if (hit != null) {
          world = _contactWorldBetween(previous, world, hit);
          contact = PressureContactEvidence(
            clock: hit.clock,
            defenderNumber: hit.actor.number,
            defenderId: hit.actor.id,
            point: world.ball.position,
          );
          frames.add(world);
          break;
        }
        frames.add(world);
        settled += dt;
      }
    }
    final assessment = _assess(before, world, action);
    return PressureSimulationResult(
      before: before,
      after: world,
      action: action,
      trace: PressureTrace(frames),
      assessment: assessment,
      contact: contact,
    );
  }

  PressureSimulationResult _simulatePass(
    PressureWorld before,
    PressureAction action, {
    ScanPassPoint? forcedTarget,
    PressureActorRole? forcedReceiverRole,
    double settleSeconds = .22,
    PressureActorRole? controlledOffBallRole,
    String? controlledOffBallId,
    ScanPassPoint? controlledOffBallTarget,
  }) {
    final motion = _runPass(
      before,
      _clamp(forcedTarget ?? action.target),
      forcedReceiverRole: forcedReceiverRole,
      settleSeconds: settleSeconds,
      controlledOffBallRole: controlledOffBallRole,
      controlledOffBallId: controlledOffBallId,
      controlledOffBallTarget: controlledOffBallTarget,
    );
    if (motion == null) return _stationaryResult(before, action);
    final intendedReceived = motion.intendedReception != null;
    final offside = intendedReceived && !motion.onsideAtRelease;
    final terminal = offside ? motion.intendedReception! : motion.after;
    final after = offside
        ? terminal.copyWith(
            ball: PressureBall(
              position: terminal.ball.position,
              velocity: const ScanPassPoint(0, 0),
              carrierId: null,
            ),
            possession: PressurePossession.defense,
          )
        : terminal;
    final trace = offside
        ? PressureTrace([
            ...motion.trace.frames.where(
              (frame) => frame.clock <= terminal.clock + 1e-9,
            ),
            after,
          ])
        : motion.trace;
    return PressureSimulationResult(
      before: before,
      after: after,
      action: action,
      trace: trace,
      assessment: _assess(before, after, action, offside: offside),
      contact: motion.contact,
      intendedReceiverRole: motion.intendedReceiverRole,
      offside: offside,
    );
  }

  _PressureMotion? _runPass(
    PressureWorld before,
    ScanPassPoint requestedTarget, {
    PressureActorRole? forcedReceiverRole,
    required double settleSeconds,
    PressureActorRole? controlledOffBallRole,
    String? controlledOffBallId,
    ScanPassPoint? controlledOffBallTarget,
  }) {
    final carrier = before.carrier;
    if (carrier == null || carrier.team != PressureTeam.attack) return null;
    final target = _clamp(requestedTarget);
    final teammates = before
        .team(PressureTeam.attack)
        .where((actor) => actor.id != carrier.id)
        .where((actor) =>
            forcedReceiverRole == null || actor.role == forcedReceiverRole)
        .toList();
    if (teammates.isEmpty) return null;
    teammates.sort((a, b) {
      final da = _leadTarget(before, a).distanceTo(target);
      final db = _leadTarget(before, b).distanceTo(target);
      return da.compareTo(db);
    });
    final intended = teammates.first;
    final onsideAtRelease = receiverIsOnside(before, intended);
    final distance = before.ball.position.distanceTo(target);
    final duration = distance / passSpeedMetresPerSecond;
    final direction = _unit(target - before.ball.position);
    var world = before.copyWith(
      ball: PressureBall(
        position: before.ball.position,
        velocity: direction * passSpeedMetresPerSecond,
        carrierId: null,
      ),
    );
    final frames = <PressureWorld>[before, world];
    var elapsed = 0.0;
    PressureContactEvidence? contact;
    PressureWorld? intendedReception;
    while (elapsed + 1e-8 < duration) {
      final dt = math.min(stepSeconds, duration - elapsed);
      final startBall = world.ball.position;
      final nextBall = elapsed + dt >= duration
          ? target
          : _clamp(startBall + direction * (passSpeedMetresPerSecond * dt));
      final nextActors = _advanceActors(
        world,
        dt,
        controlledTarget: null,
        controlledOffBallRole: controlledOffBallRole,
        controlledOffBallId: controlledOffBallId,
        controlledOffBallTarget: controlledOffBallTarget,
      );
      final next = PressureWorld(
        clock: world.clock + dt,
        actors: nextActors,
        ball: PressureBall(
          position: nextBall,
          velocity: direction * passSpeedMetresPerSecond,
          carrierId: null,
        ),
        possession: PressurePossession.loose,
      );
      final hit = _flightContact(world, next, startBall, nextBall, intended);
      if (hit != null) {
        final contacted = _contactWorldBetween(world, next, hit);
        world = contacted;
        frames.add(world);
        if (hit.actor.team == PressureTeam.defense) {
          contact = PressureContactEvidence(
            clock: hit.clock,
            defenderNumber: hit.actor.number,
            defenderId: hit.actor.id,
            point: world.ball.position,
          );
        } else if (hit.actor.role == intended.role) {
          intendedReception = world;
        }
        break;
      }
      world = next;
      frames.add(world);
      elapsed += dt;
    }
    if (world.ball.carrierId == null) {
      world = world.copyWith(
        ball: PressureBall(
          position: target,
          velocity: const ScanPassPoint(0, 0),
          carrierId: null,
        ),
        possession: PressurePossession.loose,
      );
      frames.add(world);
    }
    if (world.possession == PressurePossession.attack && settleSeconds > 0) {
      var settled = 0.0;
      final receivedAt = world.carrier!.position;
      while (settled + 1e-8 < settleSeconds) {
        final dt = math.min(stepSeconds, settleSeconds - settled);
        final previous = world;
        world = _advanceCarried(
          world,
          dt,
          controlledTarget: receivedAt,
          controlledOffBallRole: controlledOffBallRole,
          controlledOffBallId: controlledOffBallId,
          controlledOffBallTarget: controlledOffBallTarget,
        );
        final hit = _carrierContact(previous, world);
        if (hit != null) {
          world = _contactWorldBetween(previous, world, hit);
          contact = PressureContactEvidence(
            clock: hit.clock,
            defenderNumber: hit.actor.number,
            defenderId: hit.actor.id,
            point: world.ball.position,
          );
          frames.add(world);
          break;
        }
        frames.add(world);
        settled += dt;
      }
    }
    return _PressureMotion(
      after: world,
      trace: PressureTrace(frames),
      contact: contact,
      intendedReceiverRole: intended.role,
      onsideAtRelease: onsideAtRelease,
      intendedReception: intendedReception,
    );
  }

  PressureSimulationResult _stationaryResult(
      PressureWorld before, PressureAction action) {
    return PressureSimulationResult(
      before: before,
      after: before,
      action: action,
      trace: PressureTrace([before]),
      assessment: _assess(before, before, action),
    );
  }

  PressureAssessment _assess(
    PressureWorld before,
    PressureWorld after,
    PressureAction action, {
    bool offside = false,
  }) {
    final beforeConnections = connections(before);
    final forwardBefore = beforeConnections.any((c) => c.safe && c.forward);
    final carrier = after.carrier;
    final retained = carrier != null && carrier.team == PressureTeam.attack;
    final defenders = after.team(PressureTeam.defense).toList();
    final reference = carrier?.position ?? after.ball.position;
    defenders.sort((a, b) => a.position
        .distanceTo(reference)
        .compareTo(b.position.distanceTo(reference)));
    final nearest = defenders.first;
    final clearance = retained ? nearest.position.distanceTo(reference) : 0.0;
    final availableTime = retained ? _pressureArrivalSeconds(after) : 0.0;
    final afterConnections =
        retained ? connections(after) : const <PressureConnectionEvidence>[];
    final progressMetres = after.ball.position.x - before.ball.position.x;
    final progressiveConnection = afterConnections
        .any((connection) => connection.safe && connection.forward);
    final backwardsPass = action.kind == PressureActionKind.pass &&
        action.target.x < before.ball.position.x - .5;
    final missed = retained && forwardBefore && backwardsPass;
    final safety = !retained
        ? PressureSafety.lost
        : clearance >= 2.0
            ? PressureSafety.safe
            : PressureSafety.pressured;
    final progress = !retained
        ? PressureProgress.stopped
        : missed
            ? PressureProgress.missedOpportunity
            : progressiveConnection || progressMetres >= 1.5
                ? PressureProgress.opened
                : PressureProgress.retained;
    final quality = !retained
        ? PressureDecisionQuality.lost
        : safety == PressureSafety.safe &&
                !missed &&
                (progress == PressureProgress.opened ||
                    !forwardBefore ||
                    action.kind == PressureActionKind.pass)
            ? PressureDecisionQuality.strong
            : safety != PressureSafety.lost &&
                    (clearance >= 1.25 || afterConnections.any((c) => c.safe))
                ? PressureDecisionQuality.sound
                : PressureDecisionQuality.compromised;
    final result = offside
        ? PressureResultKind.offside
        : !retained
            ? after.possession == PressurePossession.defense
                ? PressureResultKind.intercepted
                : PressureResultKind.loose
            : progressMetres >= 1.5 || progressiveConnection
                ? PressureResultKind.progressed
                : PressureResultKind.retained;
    return PressureAssessment(
      result: result,
      quality: quality,
      safety: safety,
      progress: progress,
      pressureClearanceMetres: clearance,
      availableTimeSeconds: availableTime,
      actionProgressMetres: progressMetres,
      nearestDefenderRole: nearest.role,
      connections: afterConnections,
      forwardOpportunityBefore: forwardBefore,
      missedForwardOpportunity: missed,
    );
  }

  PressureWorld _advanceCarried(
    PressureWorld world,
    double dt, {
    required ScanPassPoint? controlledTarget,
    PressureActorRole? controlledOffBallRole,
    String? controlledOffBallId,
    ScanPassPoint? controlledOffBallTarget,
    bool holdControlledOffBallStationary = false,
  }) {
    final actors = _advanceActors(
      world,
      dt,
      controlledTarget: controlledTarget,
      controlledOffBallRole: controlledOffBallRole,
      controlledOffBallId: controlledOffBallId,
      controlledOffBallTarget: controlledOffBallTarget,
      holdControlledOffBallStationary: holdControlledOffBallStationary,
    );
    final carrierId = world.ball.carrierId;
    if (carrierId == null) {
      return world.copyWith(clock: world.clock + dt, actors: actors);
    }
    final previousCarrier = world.actorById(carrierId);
    final carrier = actors.firstWhere((actor) => actor.id == carrierId);
    final footOffset = world.ball.position - previousCarrier.position;
    return PressureWorld(
      clock: world.clock + dt,
      actors: actors,
      ball: PressureBall(
        position: carrier.position + footOffset,
        velocity: carrier.velocity,
        carrierId: carrier.id,
      ),
      possession: carrier.team == PressureTeam.attack
          ? PressurePossession.attack
          : PressurePossession.defense,
    );
  }

  List<PressureActor> _advanceActors(
    PressureWorld world,
    double dt, {
    required ScanPassPoint? controlledTarget,
    PressureActorRole? controlledOffBallRole,
    String? controlledOffBallId,
    ScanPassPoint? controlledOffBallTarget,
    bool holdControlledOffBallStationary = false,
  }) {
    final values = <PressureActor>[];
    final carrier = world.carrier;
    for (final actor in world.actors) {
      if (holdControlledOffBallStationary && actor.id == controlledOffBallId) {
        values.add(actor.copyWith(velocity: const ScanPassPoint(0, 0)));
        continue;
      }
      ScanPassPoint desired;
      final actorTarget = carrier?.id == actor.id
          ? controlledTarget
          : actor.id == controlledOffBallId ||
                  (controlledOffBallId == null &&
                      actor.role == controlledOffBallRole)
              ? controlledOffBallTarget
              : null;
      if (actorTarget != null) {
        final remaining = actorTarget - actor.position;
        final brakingSpeed = math.sqrt(
          math.max(0, 2 * actor.maxAcceleration * remaining.distance),
        );
        desired = remaining.distance <= .01
            ? const ScanPassPoint(0, 0)
            : _unit(remaining) *
                math.min(math.min(6.0, actor.maxSpeed), brakingSpeed);
      } else {
        desired = _desiredVelocity(actor, world);
      }
      desired = _withOffBallSeparation(actor, desired, world);
      var velocity = _approachVelocity(
        actor.velocity,
        _limit(desired, actor.maxSpeed),
        actor.maxAcceleration * dt,
      );
      var position = _clamp(actor.position + velocity * dt);
      if (actorTarget != null &&
          actor.position.distanceTo(actorTarget) <= .015 &&
          actor.velocity.distance <= actor.maxAcceleration * dt + .01) {
        position = actorTarget;
        velocity = const ScanPassPoint(0, 0);
      }
      values.add(actor.copyWith(position: position, velocity: velocity));
    }
    return List.unmodifiable(values);
  }

  ScanPassPoint _desiredVelocity(PressureActor actor, PressureWorld world) {
    if (actor.team == PressureTeam.attack) return actor.intentVelocity;
    final receiver = world.actorByRole(PressureActorRole.receiver);
    final ballCarrier = world.carrier;
    final ballFocus = ballCarrier?.team == PressureTeam.attack
        ? ballCarrier!.position
        : world.ball.position;
    switch (actor.role) {
      case PressureActorRole.presser:
        final passerHasBall = ballCarrier?.role == PressureActorRole.passer;
        final incoming = ballCarrier == null && world.ball.inFlight;
        final incomingShape = passerHasBall &&
            receiver.position.x > ballFocus.x + 4 &&
            actor.position.distanceTo(receiver.position) + 1 <
                actor.position.distanceTo(ballFocus);
        final incomingMark = incoming &&
            actor.position.distanceTo(receiver.position) <
                actor.position.distanceTo(ballFocus);
        final immediateBallThreat = ballCarrier?.team == PressureTeam.attack &&
            actor.position.distanceTo(ballFocus) <= 3.2;
        final target = !immediateBallThreat && (incomingShape || incomingMark)
            ? _markingPoint(
                actor,
                receiver,
                (actor.home.distanceTo(receiver.home) * .95)
                    .clamp(2.4, 4.8)
                    .toDouble(),
              )
            : ballFocus;
        final pursuit = _velocityToPoint(actor, target);
        return actor.intentVelocity * ((1 - actor.reactivity) * .2) +
            pursuit * math.max(.28, actor.reactivity);
      case PressureActorRole.cover:
        final support = world.actorByRole(PressureActorRole.support);
        final focus = world.actorByRole(PressureActorRole.receiver);
        final laneTarget = support.id == ballCarrier?.id ? focus : support;
        final midpoint = ScanPassPoint(
          ballFocus.x + (laneTarget.position.x - ballFocus.x) * .55,
          ballFocus.y + (laneTarget.position.y - ballFocus.y) * .55,
        );
        final nearestDistance = world
            .team(PressureTeam.defense)
            .map((defender) => defender.position.distanceTo(ballFocus))
            .reduce(math.min);
        final ballDistance = actor.position.distanceTo(ballFocus);
        final mustChallenge = ballCarrier?.team == PressureTeam.attack &&
            (ballDistance <= 3.2 || ballDistance <= nearestDistance + .75);
        final response =
            mustChallenge ? math.max(.68, actor.reactivity) : actor.reactivity;
        final target = mustChallenge
            ? ballFocus
            : actor.home.lerp(midpoint, actor.reactivity * .58);
        return actor.intentVelocity * (1 - response) +
            _velocityToPoint(actor, target) * response;
      case PressureActorRole.tracker:
        final runner = world.actorByRole(PressureActorRole.runner);
        final runnerHasBall = ballCarrier?.id == runner.id;
        final target = runnerHasBall
            ? ballFocus
            : world.ball.inFlight && ballCarrier == null
                ? world.ball.position
                : _markingPoint(
                    actor,
                    runner,
                    (actor.home.distanceTo(runner.home) * .42)
                        .clamp(2.4, 4.2)
                        .toDouble(),
                  );
        final response =
            runnerHasBall ? math.max(.72, actor.reactivity) : actor.reactivity;
        return actor.intentVelocity * ((1 - response) * .15) +
            _velocityToPoint(actor, target) * response;
      default:
        return actor.intentVelocity;
    }
  }

  _PressureHit? _carrierContact(PressureWorld before, PressureWorld after) {
    final carrierBefore = before.carrier;
    final carrierAfter = after.carrier;
    if (carrierBefore == null ||
        carrierAfter == null ||
        carrierAfter.team != PressureTeam.attack) {
      return null;
    }
    _PressureHit? first;
    for (final defenderBefore in before.team(PressureTeam.defense)) {
      final defenderAfter = after.actorByRole(defenderBefore.role);
      final contact = _movingContact(
        before.ball.position,
        after.ball.position,
        defenderBefore.position,
        defenderAfter.position,
        contactRadiusMetres,
      );
      if (contact == null) continue;
      final hit = _PressureHit(
        actor: defenderAfter,
        point: before.ball.position.lerp(after.ball.position, contact),
        clock: before.clock + (after.clock - before.clock) * contact,
        fraction: contact,
      );
      if (first == null || hit.fraction < first.fraction) {
        first = hit;
      }
    }
    return first;
  }

  _PressureHit? _flightContact(
    PressureWorld before,
    PressureWorld after,
    ScanPassPoint ballBefore,
    ScanPassPoint ballAfter,
    PressureActor intended,
  ) {
    _PressureHit? first;
    for (final actorBefore in before.actors) {
      if (actorBefore.team == PressureTeam.attack &&
          actorBefore.role != intended.role) {
        continue;
      }
      final actorAfter = after.actorByRole(actorBefore.role);
      // A teammate controls only when the ball reaches the player's feet;
      // defenders can make contact across a realistic tackle radius.
      final radius = actorBefore.team == PressureTeam.defense ? .76 : .55;
      final contact = _movingContact(
        ballBefore,
        ballAfter,
        actorBefore.position,
        actorAfter.position,
        radius,
      );
      if (contact == null) continue;
      final hit = _PressureHit(
        actor: actorAfter,
        point: ballBefore.lerp(ballAfter, contact),
        clock: before.clock + (after.clock - before.clock) * contact,
        fraction: contact,
      );
      if (first == null || hit.fraction < first.fraction) {
        first = hit;
      }
    }
    return first;
  }

  PressureWorld _contactWorldBetween(
    PressureWorld before,
    PressureWorld after,
    _PressureHit hit,
  ) {
    final actors = <PressureActor>[];
    for (final start in before.actors) {
      final finish = after.actorByRole(start.role);
      actors.add(start.copyWith(
        position: start.position.lerp(finish.position, hit.fraction),
        velocity: start.velocity.lerp(finish.velocity, hit.fraction),
      ));
    }
    final actor = actors.firstWhere((actor) => actor.role == hit.actor.role);
    return PressureWorld(
      clock: hit.clock,
      actors: actors,
      ball: PressureBall(
        position: hit.point,
        velocity: actor.velocity,
        carrierId: actor.id,
      ),
      possession: actor.team == PressureTeam.attack
          ? PressurePossession.attack
          : PressurePossession.defense,
    );
  }

  double _pressureArrivalSeconds(PressureWorld start) {
    if (start.carrier?.team != PressureTeam.attack) return 0;
    var world = start;
    const horizon = 2.5;
    while (world.clock < start.clock + horizon - 1e-8) {
      final dt = math.min(stepSeconds, start.clock + horizon - world.clock);
      final previous = world;
      world = _advanceCarried(
        world,
        dt,
        controlledTarget: start.carrier!.position,
      );
      final hit = _carrierContact(previous, world);
      if (hit != null) return hit.clock - start.clock;
    }
    return horizon;
  }

  ({PressureActorRole role, double distanceToBall})? _closestFlightDefender(
      PressureTrace trace) {
    ({PressureActorRole role, double distanceToBall})? closest;
    for (final frame in trace.frames) {
      if (frame.ball.carrierId != null) continue;
      for (final defender in frame.team(PressureTeam.defense)) {
        final distance = defender.position.distanceTo(frame.ball.position);
        if (closest == null || distance < closest.distanceToBall) {
          closest = (role: defender.role, distanceToBall: distance);
        }
      }
    }
    return closest;
  }

  ScanPassPoint _leadTarget(PressureWorld world, PressureActor receiver) {
    final carrier = world.carrier;
    if (carrier == null) return receiver.position;
    var target = receiver.position;
    for (var iteration = 0; iteration < 6; iteration++) {
      final flight =
          carrier.position.distanceTo(target) / passSpeedMetresPerSecond;
      target = _clamp(receiver.position +
          receiver.velocity * flight.clamp(0.0, 3.0).toDouble());
    }
    return target;
  }

  /// Predicts the receiver's position while they continue toward the selected
  /// support destination with the same acceleration, braking and separation
  /// rules used by the live pass simulation.
  ScanPassPoint _controlledLeadTarget(
    PressureWorld world,
    PressureActor receiver,
    ScanPassPoint controlledTarget,
  ) {
    var passTarget = receiver.position;
    for (var iteration = 0; iteration < 6; iteration++) {
      final flight = (world.ball.position.distanceTo(passTarget) /
              passSpeedMetresPerSecond)
          .clamp(0.0, 3.0)
          .toDouble();
      var projection = world;
      var elapsed = 0.0;
      while (elapsed + 1e-8 < flight) {
        final dt = math.min(stepSeconds, flight - elapsed);
        final heldCarrier = projection.carrier?.position;
        projection = projection.copyWith(
          clock: projection.clock + dt,
          actors: _advanceActors(
            projection,
            dt,
            controlledTarget: heldCarrier,
            controlledOffBallId: receiver.id,
            controlledOffBallTarget: controlledTarget,
          ),
        );
        elapsed += dt;
      }
      passTarget = projection.actorByRole(receiver.role).position;
    }
    return _clamp(passTarget);
  }

  ScanPassPoint _markingPoint(
    PressureActor defender,
    PressureActor attacker,
    double standOff,
  ) {
    var away = defender.position - attacker.position;
    if (away.distance <= 1e-9) {
      away = ScanPassPoint(
        defender.role.index.isEven ? 0 : .01,
        defender.role.index.isEven ? .01 : 0,
      );
    }
    return _clamp(attacker.position + _unit(away) * standOff);
  }

  ScanPassPoint _velocityToPoint(
    PressureActor actor,
    ScanPassPoint target,
  ) {
    final remaining = target - actor.position;
    if (remaining.distance <= .02) return const ScanPassPoint(0, 0);
    final brakingSpeed =
        math.sqrt(2 * actor.maxAcceleration * remaining.distance);
    final speed = math.min(actor.maxSpeed, brakingSpeed);
    return _unit(remaining) * speed;
  }

  ScanPassPoint _withOffBallSeparation(
    PressureActor actor,
    ScanPassPoint desired,
    PressureWorld world,
  ) {
    var adjusted = desired;
    if (actor.team == PressureTeam.attack) {
      for (final teammate in world.team(PressureTeam.attack)) {
        if (teammate.id == actor.id) continue;
        final delta = actor.position - teammate.position;
        const preferred = 1.8;
        if (delta.distance >= preferred) continue;
        final away = delta.distance <= 1e-9
            ? ScanPassPoint(0, actor.role.index.isEven ? 1 : -1)
            : _unit(delta);
        final strength = (preferred - delta.distance) / preferred;
        adjusted += away * (actor.maxSpeed * (.7 + strength));
      }
      return adjusted;
    }
    for (final attacker in world.team(PressureTeam.attack)) {
      if (attacker.id == world.ball.carrierId) continue;
      final delta = actor.position - attacker.position;
      const preferred = 1.6;
      if (delta.distance >= preferred) continue;
      final away = delta.distance <= 1e-9
          ? ScanPassPoint(0, actor.role.index.isEven ? 1 : -1)
          : _unit(delta);
      final strength = (preferred - delta.distance) / preferred;
      adjusted += away * (actor.maxSpeed * (1.15 + strength));
    }
    return adjusted;
  }

  static double? _movingContact(
    ScanPassPoint a0,
    ScanPassPoint a1,
    ScanPassPoint b0,
    ScanPassPoint b1,
    double radius,
  ) {
    final relativeStart = a0 - b0;
    final relativeDelta = (a1 - a0) - (b1 - b0);
    final qa = relativeDelta.dot(relativeDelta);
    final qb = 2 * relativeStart.dot(relativeDelta);
    final qc = relativeStart.dot(relativeStart) - radius * radius;
    if (qc <= 0) return 0;
    if (qa < 1e-10) return null;
    final discriminant = qb * qb - 4 * qa * qc;
    if (discriminant < 0) return null;
    final root = math.sqrt(discriminant);
    final first = (-qb - root) / (2 * qa);
    if (first >= 0 && first <= 1) return first;
    final second = (-qb + root) / (2 * qa);
    return second >= 0 && second <= 1 ? second : null;
  }

  static ScanPassPoint _approachVelocity(
    ScanPassPoint current,
    ScanPassPoint desired,
    double maximumChange,
  ) {
    final delta = desired - current;
    if (delta.distance <= maximumChange) return desired;
    return current + _unit(delta) * maximumChange;
  }

  static ScanPassPoint _unit(ScanPassPoint value) => value.distance <= 1e-9
      ? const ScanPassPoint(0, 0)
      : value * (1 / value.distance);

  static ScanPassPoint _limit(ScanPassPoint value, double maximum) =>
      value.distance <= maximum ? value : _unit(value) * maximum;

  static bool _movingToward(
    PressureActor actor,
    ScanPassPoint target,
    ScanPassPoint targetVelocity,
  ) {
    final delta = target - actor.position;
    if (delta.distance <= .01) return true;
    final relativeVelocity = actor.velocity - targetVelocity;
    return relativeVelocity.dot(_unit(delta)) > .15;
  }

  static ScanPassPoint _closestPointOnSegment(
    ScanPassPoint point,
    ScanPassPoint start,
    ScanPassPoint end,
  ) {
    final segment = end - start;
    final squared = segment.dot(segment);
    final fraction = squared <= 1e-10
        ? 0.0
        : ((point - start).dot(segment) / squared).clamp(0.0, 1.0).toDouble();
    return start + segment * fraction;
  }

  static PressureActor _nearestDefender(
    PressureWorld world,
    ScanPassPoint point,
  ) {
    final defenders = world.team(PressureTeam.defense).toList()
      ..sort((a, b) =>
          a.position.distanceTo(point).compareTo(b.position.distanceTo(point)));
    return defenders.first;
  }

  static ScanPassPoint _clamp(ScanPassPoint point) => ScanPassPoint(
        point.x.clamp(1.0, fieldLengthMetres - 1.0).toDouble(),
        point.y.clamp(1.0, fieldWidthMetres - 1.0).toDouble(),
      );
}

class _PressureMotion {
  final PressureWorld after;
  final PressureTrace trace;
  final PressureContactEvidence? contact;
  final PressureActorRole intendedReceiverRole;
  final bool onsideAtRelease;
  final PressureWorld? intendedReception;

  const _PressureMotion({
    required this.after,
    required this.trace,
    required this.contact,
    required this.intendedReceiverRole,
    required this.onsideAtRelease,
    required this.intendedReception,
  });
}

class _PressureSupportMotion {
  final PressureWorld after;
  final PressureTrace trace;
  final PressureContactEvidence? contact;

  const _PressureSupportMotion({
    required this.after,
    required this.trace,
    required this.contact,
  });
}

class _PressureHit {
  final PressureActor actor;
  final ScanPassPoint point;
  final double clock;
  final double fraction;

  const _PressureHit({
    required this.actor,
    required this.point,
    required this.clock,
    required this.fraction,
  });
}
