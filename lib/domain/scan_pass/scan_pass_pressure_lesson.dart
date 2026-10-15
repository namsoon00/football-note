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

enum PressureDecisionStage { firstContact, nextConnection }

enum PressureActionKind { firstTouch, pass, carry }

enum PressureOptionKind {
  touchInside,
  touchOutside,
  immediatePass,
  immediateRunnerPass,
  immediateBackPass,
  passSupport,
  passRunner,
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

  const PressureDecisionOption({
    required this.key,
    required this.kind,
    required this.action,
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
  final PressureWorld observationStart;

  const PressureLessonScenario({
    required this.id,
    required this.heldOut,
    required this.observationStart,
  });

  PressureLessonScenario relabeled(String value) => PressureLessonScenario(
        id: value,
        heldOut: heldOut,
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

class PressureLessonCatalog {
  static const int trainingCount = 6;
  static const int heldOutCount = 2;
  static const int situationCount = trainingCount + heldOutCount;

  static List<PressureLessonScenario> build({int seed = 19}) {
    final random = math.Random(seed);
    final training = <_PressureScenarioSpec>[
      const _PressureScenarioSpec(
        id: 'outside-arrival',
        presserOffset: ScanPassPoint(-1.1, -5.0),
        presserIntent: ScanPassPoint(1.2, 2.2),
        coverOffset: ScanPassPoint(6.0, 4.0),
        coverIntent: ScanPassPoint(-.4, -.3),
        coverReactivity: .55,
        runnerIntent: ScanPassPoint(2.7, .15),
        trackerOffset: ScanPassPoint(2.0, 2.0),
      ),
      const _PressureScenarioSpec(
        id: 'inside-arrival',
        presserOffset: ScanPassPoint(-.8, 3.4),
        presserIntent: ScanPassPoint(1.0, -2.3),
        coverOffset: ScanPassPoint(7.0, -3.6),
        coverIntent: ScanPassPoint(-.2, .2),
        runnerIntent: ScanPassPoint(2.3, -.25),
      ),
      const _PressureScenarioSpec(
        id: 'near-cover',
        presserOffset: ScanPassPoint(-1.5, -3.8),
        presserIntent: ScanPassPoint(1.35, 2.2),
        coverOffset: ScanPassPoint(3.0, 3.0),
        coverIntent: ScanPassPoint(-1.0, -1.1),
        coverReactivity: .55,
        runnerIntent: ScanPassPoint(2.9, .25),
        trackerOffset: ScanPassPoint(2.0, 1.0),
      ),
      const _PressureScenarioSpec(
        id: 'holding-line',
        presserOffset: ScanPassPoint(1.8, -5.4),
        presserIntent: ScanPassPoint(-.2, -.4),
        presserReactivity: .24,
        coverOffset: ScanPassPoint(8.0, 9.2),
        coverIntent: ScanPassPoint(-.3, -.2),
        coverReactivity: .35,
        runnerIntent: ScanPassPoint(3.1, -.15),
      ),
      const _PressureScenarioSpec(
        id: 'late-runner',
        presserOffset: ScanPassPoint(-1.0, 3.8),
        presserIntent: ScanPassPoint(1.0, -1.8),
        coverOffset: ScanPassPoint(8.5, 4.0),
        coverIntent: ScanPassPoint(.1, .7),
        runnerIntent: ScanPassPoint(.8, .1),
        trackerOffset: ScanPassPoint(10.0, -.8),
      ),
      const _PressureScenarioSpec(
        id: 'runner-breaks-cover',
        presserOffset: ScanPassPoint(-1.4, -3.5),
        presserIntent: ScanPassPoint(1.0, 1.7),
        coverOffset: ScanPassPoint(6.5, 6.2),
        coverIntent: ScanPassPoint(-.4, .8),
        runnerIntent: ScanPassPoint(3.6, -1.0),
        trackerOffset: ScanPassPoint(8.0, 2.5),
      ),
    ];
    training.shuffle(random);
    final heldOut = <_PressureScenarioSpec>[
      const _PressureScenarioSpec(
        id: 'combined-a',
        heldOut: true,
        presserOffset: ScanPassPoint(-2.0, -4.1),
        presserIntent: ScanPassPoint(1.7, 2.5),
        coverOffset: ScanPassPoint(4.8, 4.7),
        coverIntent: ScanPassPoint(-.8, -.6),
        runnerIntent: ScanPassPoint(3.2, -.7),
        trackerOffset: ScanPassPoint(8.5, 1.4),
      ),
      const _PressureScenarioSpec(
        id: 'combined-b',
        heldOut: true,
        presserOffset: ScanPassPoint(.8, 4.8),
        presserIntent: ScanPassPoint(.2, -1.2),
        presserReactivity: .58,
        coverOffset: ScanPassPoint(6.1, 7.6),
        coverIntent: ScanPassPoint(-1.1, -.7),
        runnerIntent: ScanPassPoint(1.4, .8),
        trackerOffset: ScanPassPoint(7.5, -1.8),
      ),
    ];
    return List.unmodifiable([
      for (final spec in [...training, ...heldOut]) _scenario(spec, random),
    ]);
  }

  static PressureLessonScenario _scenario(
    _PressureScenarioSpec spec,
    math.Random random,
  ) {
    double jitter() => (random.nextDouble() - .5) * .34;
    ScanPassPoint j(ScanPassPoint point) =>
        ScanPassPoint(point.x + jitter(), point.y + jitter());
    const receiver = ScanPassPoint(64.5, 22.0);
    final passer = j(const ScanPassPoint(52.5, 21.3));
    final receiverStart = j(receiver);
    final support = j(const ScanPassPoint(70.0, 32.7));
    final runner = j(const ScanPassPoint(73.8, 18.2));
    final presser = j(receiver + spec.presserOffset);
    final cover = j(receiver + spec.coverOffset);
    final tracker = j(runner + spec.trackerOffset);
    final actors = <PressureActor>[
      PressureActor(
        id: 'esp-2-carvajal',
        number: 2,
        team: PressureTeam.attack,
        role: PressureActorRole.passer,
        position: passer,
        velocity: const ScanPassPoint(.5, .05),
        intentVelocity: const ScanPassPoint(.5, .05),
        maxSpeed: 5.8,
      ),
      PressureActor(
        id: 'esp-19-yamal',
        number: 19,
        team: PressureTeam.attack,
        role: PressureActorRole.receiver,
        position: receiverStart,
        velocity: const ScanPassPoint(.45, .08),
        intentVelocity: const ScanPassPoint(.45, .08),
        maxSpeed: 7.2,
        maxAcceleration: 6.8,
      ),
      PressureActor(
        id: 'esp-10-olmo',
        number: 10,
        team: PressureTeam.attack,
        role: PressureActorRole.support,
        position: support,
        velocity: const ScanPassPoint(.75, -.2),
        intentVelocity: const ScanPassPoint(.75, -.2),
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
        reactivity: .74,
      ),
    ];
    return PressureLessonScenario(
      id: spec.id,
      heldOut: spec.heldOut,
      observationStart: PressureWorld(
        clock: 0,
        actors: actors,
        ball: PressureBall(position: passer, carrierId: 'esp-2-carvajal'),
        possession: PressurePossession.attack,
      ),
    );
  }
}

class _PressureScenarioSpec {
  final String id;
  final bool heldOut;
  final ScanPassPoint presserOffset;
  final ScanPassPoint presserIntent;
  final double presserReactivity;
  final ScanPassPoint coverOffset;
  final ScanPassPoint coverIntent;
  final double coverReactivity;
  final ScanPassPoint runnerIntent;
  final ScanPassPoint trackerOffset;

  const _PressureScenarioSpec({
    required this.id,
    this.heldOut = false,
    required this.presserOffset,
    required this.presserIntent,
    this.presserReactivity = .88,
    required this.coverOffset,
    required this.coverIntent,
    this.coverReactivity = .70,
    required this.runnerIntent,
    this.trackerOffset = const ScanPassPoint(7.0, 1.5),
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
      final inside =
          _clamp(world.ball.position + const ScanPassPoint(.9, 1.75));
      final outside =
          _clamp(world.ball.position + const ScanPassPoint(.7, -1.75));
      final support = world.actorByRole(PressureActorRole.support);
      final runner = world.actorByRole(PressureActorRole.runner);
      final passer = world.actorByRole(PressureActorRole.passer);
      return List.unmodifiable([
        PressureDecisionOption(
          key: 'touch-inside',
          kind: PressureOptionKind.touchInside,
          action: PressureAction(
              label: 'inside',
              kind: PressureActionKind.firstTouch,
              target: inside),
        ),
        PressureDecisionOption(
          key: 'touch-outside',
          kind: PressureOptionKind.touchOutside,
          action: PressureAction(
              label: 'outside',
              kind: PressureActionKind.firstTouch,
              target: outside),
        ),
        PressureDecisionOption(
          key: 'pass-now',
          kind: PressureOptionKind.immediatePass,
          action: PressureAction(
            label: 'immediate',
            kind: PressureActionKind.pass,
            target: _leadTarget(world, support),
          ),
        ),
        PressureDecisionOption(
          key: 'pass-runner-now',
          kind: PressureOptionKind.immediateRunnerPass,
          action: PressureAction(
            label: 'runner-now',
            kind: PressureActionKind.pass,
            target: _leadTarget(world, runner),
          ),
        ),
        PressureDecisionOption(
          key: 'pass-back-now',
          kind: PressureOptionKind.immediateBackPass,
          action: PressureAction(
            label: 'back-now',
            kind: PressureActionKind.pass,
            target: _leadTarget(world, passer),
          ),
        ),
      ]);
    }
    final support = world.actorByRole(PressureActorRole.support);
    final runner = world.actorByRole(PressureActorRole.runner);
    return List.unmodifiable([
      if (support.id != carrier.id)
        PressureDecisionOption(
          key: 'pass-support',
          kind: PressureOptionKind.passSupport,
          action: PressureAction(
            label: 'support',
            kind: PressureActionKind.pass,
            target: _leadTarget(world, support),
          ),
        ),
      if (runner.id != carrier.id)
        PressureDecisionOption(
          key: 'pass-runner',
          kind: PressureOptionKind.passRunner,
          action: PressureAction(
            label: 'runner',
            kind: PressureActionKind.pass,
            target: _leadTarget(world, runner),
          ),
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

  PressureSituationContext situationContext(
    PressureWorld world,
    PressureDecisionStage stage,
  ) {
    final carrier = world.carrier;
    final receiver = world.actorByRole(PressureActorRole.receiver);
    final focus = carrier == null || carrier.role == PressureActorRole.passer
        ? receiver
        : carrier;
    final presser = world.actorByRole(PressureActorRole.presser);
    final cover = world.actorByRole(PressureActorRole.cover);
    final support = world.actorByRole(PressureActorRole.support);
    final runner = world.actorByRole(PressureActorRole.runner);
    final pressureDelta = presser.position.y - focus.position.y;
    final approachSide = pressureDelta < -1
        ? PressureApproachSide.outside
        : pressureDelta > 1
            ? PressureApproachSide.inside
            : PressureApproachSide.level;
    final coverLanePoint = _closestPointOnSegment(
      cover.position,
      world.ball.position,
      support.position,
    );
    return PressureSituationContext(
      stage: stage,
      fieldBand: focus.position.x >= fieldLengthMetres * 2 / 3
          ? PressureFieldBand.attackingThird
          : PressureFieldBand.middleThird,
      fieldChannel: focus.position.y < fieldWidthMetres / 3
          ? PressureFieldChannel.right
          : focus.position.y > fieldWidthMetres * 2 / 3
              ? PressureFieldChannel.left
              : PressureFieldChannel.central,
      carrierNumber: (carrier ?? focus).number,
      focusNumber: focus.number,
      presserNumber: presser.number,
      approachSide: approachSide,
      pressureMovement: _movingToward(presser, focus.position, focus.velocity)
          ? PressureMovement.closing
          : PressureMovement.holding,
      pressureDistanceMetres: presser.position.distanceTo(focus.position),
      coverNumber: cover.number,
      supportNumber: support.number,
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
    };
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
      world = _advanceCarried(world, dt, controlledTarget: carrierTarget);
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
        world = _advanceCarried(world, dt, controlledTarget: carrierTarget);
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
  }) {
    final motion = _runPass(
      before,
      _clamp(forcedTarget ?? action.target),
      forcedReceiverRole: forcedReceiverRole,
      settleSeconds: settleSeconds,
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
      final nextActors = _advanceActors(world, dt, controlledTarget: null);
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
        world = _advanceCarried(world, dt, controlledTarget: receivedAt);
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
  }) {
    final actors =
        _advanceActors(world, dt, controlledTarget: controlledTarget);
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
  }) {
    final values = <PressureActor>[];
    final carrier = world.carrier;
    for (final actor in world.actors) {
      ScanPassPoint desired;
      if (carrier?.id == actor.id && controlledTarget != null) {
        final remaining = controlledTarget - actor.position;
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
      if (carrier?.id == actor.id &&
          controlledTarget != null &&
          actor.position.distanceTo(controlledTarget) <= .015 &&
          actor.velocity.distance <= actor.maxAcceleration * dt + .01) {
        position = controlledTarget;
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
        final target = passerHasBall || incoming
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
        final midpoint = ScanPassPoint(
          ballFocus.x + (support.position.x - ballFocus.x) * .55,
          ballFocus.y + (support.position.y - ballFocus.y) * .55,
        );
        final target = actor.home.lerp(midpoint, actor.reactivity * .58);
        return actor.intentVelocity * (1 - actor.reactivity) +
            _unit(target - actor.position) * actor.maxSpeed * actor.reactivity;
      case PressureActorRole.tracker:
        final runner = world.actorByRole(PressureActorRole.runner);
        final target = world.ball.inFlight && ballCarrier == null
            ? world.ball.position
            : _markingPoint(
                actor,
                runner,
                (actor.home.distanceTo(runner.home) * .42)
                    .clamp(2.4, 4.2)
                    .toDouble(),
              );
        return actor.intentVelocity * ((1 - actor.reactivity) * .15) +
            _velocityToPoint(actor, target) * actor.reactivity;
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
    if (actor.team != PressureTeam.defense) return desired;
    var adjusted = desired;
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
