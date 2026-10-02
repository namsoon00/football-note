import 'dart:convert';
import 'dart:math' as math;

enum ScanPassMatchObjective { protectPossession, chaseGoal }

enum ScanPassFieldRegion {
  centralMidfield,
  leftHalfSpace,
  rightHalfSpace,
  defensiveThird,
  attackingHalf,
}

enum ScanPassScenarioFamily {
  rearPressUpper,
  rearPressLower,
  retreatingPressure,
  markedSupport,
  closingForwardLane,
  returnReceive,
}

enum ScanPassPlayerRole { centerBack4, midfielder6, support8, forward9 }

enum ScanPassFirstTouch { upperTouch, lowerTouch, turnForward, returnTo4 }

enum ScanPassNextAction {
  passTo4,
  passTo8,
  passTo9,
  holdPassTo8,
  supportUpper,
  supportForward,
  holdPocket,
}

enum ScanPassOutcomeType {
  kept,
  progressed,
  recycled,
  contested,
  intercepted,
  timeout
}

enum ScanPassTimeoutPhase { firstTouch, nextAction }

enum ScanPassScoreComponentKind {
  control,
  pressureEscape,
  continuation,
  contextFit
}

enum ScanPassReason {
  controlledFirstTouch,
  exposedFirstTouch,
  pressureEscaped,
  pressureStayed,
  clearLane,
  laneClosed,
  receiverAvailable,
  receiverCrowded,
  supportAngleCreated,
  supportAngleWeak,
  holdOpenedLane,
  holdInvitedPressure,
  objectiveProtected,
  objectiveProgressed,
}

enum ScanPassPathType { incoming, firstTouch, pass, offBallRun, hold }

class ScanPassPoint {
  final double x;
  final double y;

  const ScanPassPoint(this.x, this.y);

  ScanPassPoint operator +(ScanPassPoint other) =>
      ScanPassPoint(x + other.x, y + other.y);

  ScanPassPoint operator -(ScanPassPoint other) =>
      ScanPassPoint(x - other.x, y - other.y);

  ScanPassPoint operator *(double scale) => ScanPassPoint(x * scale, y * scale);

  double dot(ScanPassPoint other) => x * other.x + y * other.y;

  double get distance => math.sqrt((x * x) + (y * y));

  double distanceTo(ScanPassPoint other) => (this - other).distance;

  ScanPassPoint lerp(ScanPassPoint other, double t) {
    final clamped = t.clamp(0.0, 1.0).toDouble();
    return ScanPassPoint(
      x + ((other.x - x) * clamped),
      y + ((other.y - y) * clamped),
    );
  }

  ScanPassPoint clampToField({
    double minX = ScanPassScenarioLibrary.fieldMinX,
    double maxX = ScanPassScenarioLibrary.fieldMaxX,
    double minY = ScanPassScenarioLibrary.fieldMinY,
    double maxY = ScanPassScenarioLibrary.fieldMaxY,
  }) {
    return ScanPassPoint(
      x.clamp(minX, maxX).toDouble(),
      y.clamp(minY, maxY).toDouble(),
    );
  }

  Map<String, double> toMap() => <String, double>{'x': x, 'y': y};
}

class ScanPassPlayer {
  final int id;
  final int number;
  final ScanPassPlayerRole role;
  final ScanPassPoint position;
  final ScanPassPoint velocity;
  final double facingRadians;

  const ScanPassPlayer({
    required this.id,
    required this.number,
    required this.role,
    required this.position,
    this.velocity = const ScanPassPoint(0, 0),
    required this.facingRadians,
  });

  ScanPassPlayer at(double seconds) {
    return copyWith(position: (position + (velocity * seconds)).clampToField());
  }

  ScanPassPlayer copyWith({
    ScanPassPoint? position,
    ScanPassPoint? velocity,
    double? facingRadians,
  }) {
    return ScanPassPlayer(
      id: id,
      number: number,
      role: role,
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      facingRadians: facingRadians ?? this.facingRadians,
    );
  }
}

class ScanPassDefender {
  final int id;
  final ScanPassPoint position;
  final ScanPassPoint velocity;

  const ScanPassDefender({
    required this.id,
    required this.position,
    this.velocity = const ScanPassPoint(0, 0),
  });

  ScanPassDefender at(double seconds) {
    return ScanPassDefender(
      id: id,
      position: (position + (velocity * seconds)).clampToField(),
      velocity: velocity,
    );
  }
}

class ScanPassScenario {
  final int roundNumber;
  final String id;
  final ScanPassScenarioFamily family;
  final ScanPassFieldRegion region;
  final ScanPassMatchObjective objective;
  final String matchClockLabel;
  final String scoreLabel;
  final String? pairKey;
  final double ballTravelTime;
  final ScanPassPlayer centerBack;
  final ScanPassPlayer receiver;
  final ScanPassPlayer support;
  final ScanPassPlayer forward;
  final List<ScanPassDefender> defenders;

  const ScanPassScenario({
    required this.roundNumber,
    required this.id,
    required this.family,
    required this.region,
    required this.objective,
    required this.matchClockLabel,
    required this.scoreLabel,
    this.pairKey,
    this.ballTravelTime = 1.05,
    required this.centerBack,
    required this.receiver,
    required this.support,
    required this.forward,
    required this.defenders,
  });

  List<ScanPassPlayer> attackersAt(double seconds) => <ScanPassPlayer>[
        centerBack.at(seconds),
        receiver.at(seconds),
        support.at(seconds),
        forward.at(seconds),
      ];

  List<ScanPassDefender> defendersAt(double seconds) {
    return defenders.map((defender) => defender.at(seconds)).toList();
  }

  ScanPassPlayer playerAt(ScanPassPlayerRole role, double seconds) {
    return switch (role) {
      ScanPassPlayerRole.centerBack4 => centerBack.at(seconds),
      ScanPassPlayerRole.midfielder6 => receiver.at(seconds),
      ScanPassPlayerRole.support8 => support.at(seconds),
      ScanPassPlayerRole.forward9 => forward.at(seconds),
    };
  }

  ScanPassScenario copyWithRoundNumber(int roundNumber) {
    return ScanPassScenario(
      roundNumber: roundNumber,
      id: id,
      family: family,
      region: region,
      objective: objective,
      matchClockLabel: matchClockLabel,
      scoreLabel: scoreLabel,
      pairKey: pairKey,
      ballTravelTime: ballTravelTime,
      centerBack: centerBack,
      receiver: receiver,
      support: support,
      forward: forward,
      defenders: defenders,
    );
  }
}

class ScanPassScenarioLibrary {
  static const double fieldMinX = 0.07;
  static const double fieldMaxX = 0.93;
  static const double fieldMinY = 0.08;
  static const double fieldMaxY = 0.92;
  static const int roundCount = 10;

  static const ScanPassPlayer _centerBackBase = ScanPassPlayer(
    id: 4,
    number: 4,
    role: ScanPassPlayerRole.centerBack4,
    position: ScanPassPoint(0.18, 0.62),
    facingRadians: -0.12,
  );
  static const ScanPassPlayer _receiverBase = ScanPassPlayer(
    id: 6,
    number: 6,
    role: ScanPassPlayerRole.midfielder6,
    position: ScanPassPoint(0.42, 0.54),
    facingRadians: math.pi,
  );
  static const ScanPassPlayer _supportBase = ScanPassPlayer(
    id: 8,
    number: 8,
    role: ScanPassPlayerRole.support8,
    position: ScanPassPoint(0.49, 0.30),
    velocity: ScanPassPoint(0.018, 0.006),
    facingRadians: 0.18,
  );
  static const ScanPassPlayer _forwardBase = ScanPassPlayer(
    id: 9,
    number: 9,
    role: ScanPassPlayerRole.forward9,
    position: ScanPassPoint(0.77, 0.46),
    velocity: ScanPassPoint(0.010, -0.012),
    facingRadians: 0,
  );

  static final List<ScanPassScenario> scenarios = <ScanPassScenario>[
    const ScanPassScenario(
      roundNumber: 1,
      id: 'rear-upper-protect',
      family: ScanPassScenarioFamily.rearPressUpper,
      region: ScanPassFieldRegion.centralMidfield,
      objective: ScanPassMatchObjective.protectPossession,
      matchClockLabel: '68',
      scoreLabel: '1-1',
      centerBack: _centerBackBase,
      receiver: _receiverBase,
      support: _supportBase,
      forward: _forwardBase,
      defenders: <ScanPassDefender>[
        ScanPassDefender(
          id: 1,
          position: ScanPassPoint(0.50, 0.43),
          velocity: ScanPassPoint(-0.050, 0.075),
        ),
        ScanPassDefender(
          id: 2,
          position: ScanPassPoint(0.58, 0.30),
          velocity: ScanPassPoint(-0.012, 0.030),
        ),
        ScanPassDefender(
          id: 3,
          position: ScanPassPoint(0.66, 0.57),
          velocity: ScanPassPoint(-0.020, -0.020),
        ),
      ],
    ),
    ScanPassScenario(
      roundNumber: 2,
      id: 'rear-lower-protect',
      family: ScanPassScenarioFamily.rearPressLower,
      region: ScanPassFieldRegion.leftHalfSpace,
      objective: ScanPassMatchObjective.protectPossession,
      matchClockLabel: '24',
      scoreLabel: '0-0',
      centerBack:
          _centerBackBase.copyWith(position: const ScanPassPoint(0.17, 0.50)),
      receiver:
          _receiverBase.copyWith(position: const ScanPassPoint(0.41, 0.50)),
      support: _supportBase.copyWith(position: const ScanPassPoint(0.50, 0.24)),
      forward: _forwardBase.copyWith(position: const ScanPassPoint(0.76, 0.40)),
      defenders: const <ScanPassDefender>[
        ScanPassDefender(
          id: 1,
          position: ScanPassPoint(0.50, 0.66),
          velocity: ScanPassPoint(-0.055, -0.070),
        ),
        ScanPassDefender(
          id: 2,
          position: ScanPassPoint(0.59, 0.32),
          velocity: ScanPassPoint(-0.010, 0.010),
        ),
        ScanPassDefender(
          id: 3,
          position: ScanPassPoint(0.67, 0.54),
          velocity: ScanPassPoint(-0.020, -0.010),
        ),
      ],
    ),
    ScanPassScenario(
      roundNumber: 3,
      id: 'rear-upper-chase',
      family: ScanPassScenarioFamily.rearPressUpper,
      region: ScanPassFieldRegion.attackingHalf,
      objective: ScanPassMatchObjective.chaseGoal,
      matchClockLabel: '82',
      scoreLabel: '1-2',
      centerBack:
          _centerBackBase.copyWith(position: const ScanPassPoint(0.20, 0.60)),
      receiver:
          _receiverBase.copyWith(position: const ScanPassPoint(0.44, 0.52)),
      support: _supportBase.copyWith(position: const ScanPassPoint(0.54, 0.29)),
      forward: _forwardBase.copyWith(position: const ScanPassPoint(0.80, 0.44)),
      defenders: const <ScanPassDefender>[
        ScanPassDefender(
          id: 1,
          position: ScanPassPoint(0.52, 0.42),
          velocity: ScanPassPoint(-0.060, 0.075),
        ),
        ScanPassDefender(
          id: 2,
          position: ScanPassPoint(0.62, 0.31),
          velocity: ScanPassPoint(-0.020, 0.020),
        ),
        ScanPassDefender(
          id: 3,
          position: ScanPassPoint(0.70, 0.58),
          velocity: ScanPassPoint(-0.012, -0.040),
        ),
      ],
    ),
    ScanPassScenario(
      roundNumber: 4,
      id: 'retreat-turn-chase',
      family: ScanPassScenarioFamily.retreatingPressure,
      region: ScanPassFieldRegion.centralMidfield,
      objective: ScanPassMatchObjective.chaseGoal,
      matchClockLabel: '76',
      scoreLabel: '2-3',
      centerBack:
          _centerBackBase.copyWith(position: const ScanPassPoint(0.18, 0.56)),
      receiver: _receiverBase.copyWith(
        position: const ScanPassPoint(0.40, 0.48),
        facingRadians: 0.08,
      ),
      support: _supportBase.copyWith(position: const ScanPassPoint(0.52, 0.26)),
      forward: _forwardBase.copyWith(position: const ScanPassPoint(0.78, 0.50)),
      defenders: const <ScanPassDefender>[
        ScanPassDefender(
          id: 1,
          position: ScanPassPoint(0.50, 0.51),
          velocity: ScanPassPoint(0.080, 0.080),
        ),
        ScanPassDefender(
          id: 2,
          position: ScanPassPoint(0.62, 0.32),
          velocity: ScanPassPoint(0.010, 0.020),
        ),
        ScanPassDefender(
          id: 3,
          position: ScanPassPoint(0.68, 0.72),
          velocity: ScanPassPoint(0.020, 0.018),
        ),
      ],
    ),
    ScanPassScenario(
      roundNumber: 5,
      id: 'retreat-hold-window',
      family: ScanPassScenarioFamily.retreatingPressure,
      region: ScanPassFieldRegion.rightHalfSpace,
      objective: ScanPassMatchObjective.protectPossession,
      matchClockLabel: '51',
      scoreLabel: '1-0',
      centerBack:
          _centerBackBase.copyWith(position: const ScanPassPoint(0.20, 0.65)),
      receiver:
          _receiverBase.copyWith(position: const ScanPassPoint(0.43, 0.58)),
      support: _supportBase.copyWith(
        position: const ScanPassPoint(0.52, 0.36),
        velocity: const ScanPassPoint(0.020, -0.022),
      ),
      forward: _forwardBase.copyWith(position: const ScanPassPoint(0.78, 0.50)),
      defenders: const <ScanPassDefender>[
        ScanPassDefender(
          id: 1,
          position: ScanPassPoint(0.51, 0.60),
          velocity: ScanPassPoint(-0.020, -0.020),
        ),
        ScanPassDefender(
          id: 2,
          position: ScanPassPoint(0.57, 0.34),
          velocity: ScanPassPoint(0.045, -0.050),
        ),
        ScanPassDefender(
          id: 3,
          position: ScanPassPoint(0.69, 0.58),
          velocity: ScanPassPoint(-0.018, -0.010),
        ),
      ],
    ),
    ScanPassScenario(
      roundNumber: 6,
      id: 'marked-eight-protect',
      family: ScanPassScenarioFamily.markedSupport,
      region: ScanPassFieldRegion.defensiveThird,
      objective: ScanPassMatchObjective.protectPossession,
      matchClockLabel: '37',
      scoreLabel: '0-0',
      centerBack:
          _centerBackBase.copyWith(position: const ScanPassPoint(0.16, 0.58)),
      receiver:
          _receiverBase.copyWith(position: const ScanPassPoint(0.38, 0.52)),
      support: _supportBase.copyWith(position: const ScanPassPoint(0.48, 0.29)),
      forward: _forwardBase.copyWith(position: const ScanPassPoint(0.74, 0.42)),
      defenders: const <ScanPassDefender>[
        ScanPassDefender(
          id: 1,
          position: ScanPassPoint(0.47, 0.58),
          velocity: ScanPassPoint(-0.045, -0.015),
        ),
        ScanPassDefender(
          id: 2,
          position: ScanPassPoint(0.50, 0.31),
          velocity: ScanPassPoint(0.006, -0.010),
        ),
        ScanPassDefender(
          id: 3,
          position: ScanPassPoint(0.66, 0.46),
          velocity: ScanPassPoint(-0.020, -0.005),
        ),
      ],
    ),
    ScanPassScenario(
      roundNumber: 7,
      id: 'marked-eight-chase',
      family: ScanPassScenarioFamily.markedSupport,
      region: ScanPassFieldRegion.attackingHalf,
      objective: ScanPassMatchObjective.chaseGoal,
      matchClockLabel: '88',
      scoreLabel: '1-2',
      centerBack:
          _centerBackBase.copyWith(position: const ScanPassPoint(0.20, 0.55)),
      receiver:
          _receiverBase.copyWith(position: const ScanPassPoint(0.42, 0.50)),
      support: _supportBase.copyWith(position: const ScanPassPoint(0.52, 0.28)),
      forward: _forwardBase.copyWith(
        position: const ScanPassPoint(0.82, 0.39),
        velocity: const ScanPassPoint(0.018, -0.010),
      ),
      defenders: const <ScanPassDefender>[
        ScanPassDefender(
          id: 1,
          position: ScanPassPoint(0.51, 0.55),
          velocity: ScanPassPoint(-0.050, -0.018),
        ),
        ScanPassDefender(
          id: 2,
          position: ScanPassPoint(0.54, 0.29),
          velocity: ScanPassPoint(0.004, 0.006),
        ),
        ScanPassDefender(
          id: 3,
          position: ScanPassPoint(0.70, 0.48),
          velocity: ScanPassPoint(-0.005, 0.020),
        ),
      ],
    ),
    const ScanPassScenario(
      roundNumber: 8,
      id: 'forward-lane-closing',
      family: ScanPassScenarioFamily.closingForwardLane,
      region: ScanPassFieldRegion.centralMidfield,
      objective: ScanPassMatchObjective.protectPossession,
      matchClockLabel: '61',
      scoreLabel: '1-1',
      pairKey: 'forward-lane-motion-pair',
      centerBack: _centerBackBase,
      receiver: _receiverBase,
      support: _supportBase,
      forward: _forwardBase,
      defenders: <ScanPassDefender>[
        ScanPassDefender(
          id: 1,
          position: ScanPassPoint(0.50, 0.58),
          velocity: ScanPassPoint(-0.050, -0.030),
        ),
        ScanPassDefender(
          id: 2,
          position: ScanPassPoint(0.59, 0.31),
          velocity: ScanPassPoint(-0.010, 0.025),
        ),
        ScanPassDefender(
          id: 3,
          position: ScanPassPoint(0.66, 0.53),
          velocity: ScanPassPoint(0.000, 0.000),
        ),
      ],
    ),
    const ScanPassScenario(
      roundNumber: 9,
      id: 'forward-lane-retreating',
      family: ScanPassScenarioFamily.closingForwardLane,
      region: ScanPassFieldRegion.centralMidfield,
      objective: ScanPassMatchObjective.chaseGoal,
      matchClockLabel: '61',
      scoreLabel: '1-2',
      pairKey: 'forward-lane-motion-pair',
      centerBack: _centerBackBase,
      receiver: _receiverBase,
      support: _supportBase,
      forward: _forwardBase,
      defenders: <ScanPassDefender>[
        ScanPassDefender(
          id: 1,
          position: ScanPassPoint(0.50, 0.58),
          velocity: ScanPassPoint(-0.050, -0.030),
        ),
        ScanPassDefender(
          id: 2,
          position: ScanPassPoint(0.59, 0.31),
          velocity: ScanPassPoint(-0.010, 0.025),
        ),
        ScanPassDefender(
          id: 3,
          position: ScanPassPoint(0.66, 0.53),
          velocity: ScanPassPoint(0.060, 0.045),
        ),
      ],
    ),
    ScanPassScenario(
      roundNumber: 10,
      id: 'return-wall-upper',
      family: ScanPassScenarioFamily.returnReceive,
      region: ScanPassFieldRegion.defensiveThird,
      objective: ScanPassMatchObjective.protectPossession,
      matchClockLabel: '43',
      scoreLabel: '0-1',
      centerBack:
          _centerBackBase.copyWith(position: const ScanPassPoint(0.17, 0.63)),
      receiver:
          _receiverBase.copyWith(position: const ScanPassPoint(0.39, 0.56)),
      support: _supportBase.copyWith(position: const ScanPassPoint(0.48, 0.34)),
      forward: _forwardBase.copyWith(position: const ScanPassPoint(0.76, 0.50)),
      defenders: const <ScanPassDefender>[
        ScanPassDefender(
          id: 1,
          position: ScanPassPoint(0.48, 0.42),
          velocity: ScanPassPoint(-0.035, 0.045),
        ),
        ScanPassDefender(
          id: 2,
          position: ScanPassPoint(0.57, 0.34),
          velocity: ScanPassPoint(-0.012, 0.012),
        ),
        ScanPassDefender(
          id: 3,
          position: ScanPassPoint(0.66, 0.58),
          velocity: ScanPassPoint(-0.030, -0.015),
        ),
      ],
    ),
    ScanPassScenario(
      roundNumber: 11,
      id: 'return-forward-chase',
      family: ScanPassScenarioFamily.returnReceive,
      region: ScanPassFieldRegion.rightHalfSpace,
      objective: ScanPassMatchObjective.chaseGoal,
      matchClockLabel: '79',
      scoreLabel: '2-2',
      centerBack:
          _centerBackBase.copyWith(position: const ScanPassPoint(0.19, 0.57)),
      receiver:
          _receiverBase.copyWith(position: const ScanPassPoint(0.42, 0.53)),
      support: _supportBase.copyWith(position: const ScanPassPoint(0.52, 0.37)),
      forward: _forwardBase.copyWith(position: const ScanPassPoint(0.79, 0.44)),
      defenders: const <ScanPassDefender>[
        ScanPassDefender(
          id: 1,
          position: ScanPassPoint(0.52, 0.36),
          velocity: ScanPassPoint(-0.025, 0.030),
        ),
        ScanPassDefender(
          id: 2,
          position: ScanPassPoint(0.60, 0.39),
          velocity: ScanPassPoint(-0.020, -0.010),
        ),
        ScanPassDefender(
          id: 3,
          position: ScanPassPoint(0.71, 0.51),
          velocity: ScanPassPoint(-0.006, -0.020),
        ),
      ],
    ),
    ScanPassScenario(
      roundNumber: 12,
      id: 'central-hold-window',
      family: ScanPassScenarioFamily.markedSupport,
      region: ScanPassFieldRegion.centralMidfield,
      objective: ScanPassMatchObjective.protectPossession,
      matchClockLabel: '55',
      scoreLabel: '2-1',
      centerBack:
          _centerBackBase.copyWith(position: const ScanPassPoint(0.19, 0.60)),
      receiver:
          _receiverBase.copyWith(position: const ScanPassPoint(0.43, 0.55)),
      support: _supportBase.copyWith(
        position: const ScanPassPoint(0.50, 0.35),
        velocity: const ScanPassPoint(0.028, -0.018),
      ),
      forward: _forwardBase.copyWith(position: const ScanPassPoint(0.78, 0.48)),
      defenders: const <ScanPassDefender>[
        ScanPassDefender(
          id: 1,
          position: ScanPassPoint(0.52, 0.57),
          velocity: ScanPassPoint(-0.070, -0.015),
        ),
        ScanPassDefender(
          id: 2,
          position: ScanPassPoint(0.55, 0.34),
          velocity: ScanPassPoint(-0.050, 0.050),
        ),
        ScanPassDefender(
          id: 3,
          position: ScanPassPoint(0.69, 0.54),
          velocity: ScanPassPoint(-0.012, -0.008),
        ),
      ],
    ),
  ];

  final int seed;

  const ScanPassScenarioLibrary({required this.seed});

  List<ScanPassScenario> generateSession({int count = roundCount}) {
    final random = math.Random(seed);
    final ordered = List<ScanPassScenario>.from(scenarios)..shuffle(random);
    final selected = <ScanPassScenario>[];
    var cursor = 0;
    while (selected.length < count) {
      selected.add(
        ordered[cursor % ordered.length].copyWithRoundNumber(
          selected.length + 1,
        ),
      );
      cursor += 1;
    }
    return selected;
  }

  static ScanPassScenario byId(String id) {
    return scenarios.firstWhere((scenario) => scenario.id == id);
  }
}

class ScanPassScoreWeights {
  static const int control = 30;
  static const int pressureEscape = 22;
  static const int continuation = 24;
  static const int contextFit = 24;
  static const int total = 100;

  const ScanPassScoreWeights._();
}

class ScanPassPathSegment {
  final ScanPassPoint from;
  final ScanPassPoint to;
  final ScanPassPathType type;
  final double startTime;
  final double endTime;
  final bool contested;

  const ScanPassPathSegment({
    required this.from,
    required this.to,
    required this.type,
    required this.startTime,
    required this.endTime,
    this.contested = false,
  });
}

class ScanPassFirstTouchState {
  final ScanPassScenario scenario;
  final ScanPassFirstTouch action;
  final Duration decisionTime;
  final double touchStartTime;
  final double completedAt;
  final ScanPassPoint startPosition;
  final ScanPassPoint receiverPosition;
  final ScanPassPoint ballPosition;
  final ScanPassPlayerRole ballHolder;
  final double receiverFacingRadians;
  final double controlRaw;
  final double pressureEscapeRaw;
  final bool contested;
  final bool returnIntercepted;
  final ScanPassPoint? returnInterceptionPoint;
  final List<ScanPassPathSegment> pathSegments;

  const ScanPassFirstTouchState({
    required this.scenario,
    required this.action,
    required this.decisionTime,
    required this.touchStartTime,
    required this.completedAt,
    required this.startPosition,
    required this.receiverPosition,
    required this.ballPosition,
    required this.ballHolder,
    required this.receiverFacingRadians,
    required this.controlRaw,
    required this.pressureEscapeRaw,
    required this.contested,
    this.returnIntercepted = false,
    this.returnInterceptionPoint,
    required this.pathSegments,
  });

  bool get returned => ballHolder == ScanPassPlayerRole.centerBack4;

  bool get ballLost => returnIntercepted;
}

class ScanPassScoreComponent {
  final ScanPassScoreComponentKind kind;
  final int earned;
  final int max;
  final double raw;

  const ScanPassScoreComponent({
    required this.kind,
    required this.earned,
    required this.max,
    required this.raw,
  });
}

class ScanPassPlanResult {
  final ScanPassScenario scenario;
  final ScanPassFirstTouch firstTouch;
  final ScanPassNextAction nextAction;
  final Duration firstDecisionTime;
  final Duration secondDecisionTime;
  final ScanPassFirstTouchState firstTouchState;
  final ScanPassOutcomeType outcome;
  final List<ScanPassScoreComponent> components;
  final List<ScanPassReason> reasons;
  final List<ScanPassPathSegment> pathSegments;
  final ScanPassPoint finalBallPosition;
  final ScanPassPoint? interceptionPoint;
  final ScanPassPlayerRole? finalReceiverRole;
  final double finalTime;

  const ScanPassPlanResult({
    required this.scenario,
    required this.firstTouch,
    required this.nextAction,
    required this.firstDecisionTime,
    required this.secondDecisionTime,
    required this.firstTouchState,
    required this.outcome,
    required this.components,
    required this.reasons,
    required this.pathSegments,
    required this.finalBallPosition,
    required this.interceptionPoint,
    required this.finalReceiverRole,
    required this.finalTime,
  });

  String get planId => '${firstTouch.name}.${nextAction.name}';

  int get totalScore {
    return components.fold<int>(
        0, (total, component) => total + component.earned);
  }

  ScanPassScoreComponent component(ScanPassScoreComponentKind kind) {
    return components.firstWhere((component) => component.kind == kind);
  }

  bool get isLoss => outcome == ScanPassOutcomeType.intercepted;
}

class ScanPassPlanEvaluation {
  static const int comparableScoreWindow = 8;

  final ScanPassScenario scenario;
  final ScanPassPlanResult? selected;
  final List<ScanPassPlanResult> alternatives;

  const ScanPassPlanEvaluation({
    required this.scenario,
    required this.selected,
    required this.alternatives,
  });

  int get bestScore {
    if (alternatives.isEmpty) return 0;
    return alternatives
        .map((plan) => plan.totalScore)
        .fold<int>(0, (best, score) => math.max(best, score));
  }

  ScanPassPlanResult get bestPlan {
    return alternatives.reduce((a, b) => a.totalScore >= b.totalScore ? a : b);
  }

  bool isComparableToBest(ScanPassPlanResult result) {
    return bestScore - result.totalScore <= comparableScoreWindow;
  }

  ScanPassPlanResult? strongAlternativeFor(ScanPassPlanResult? result) {
    if (alternatives.isEmpty) return null;
    final filtered = alternatives
        .where((plan) => result == null || plan.planId != result.planId)
        .toList();
    if (filtered.isEmpty) return null;
    final better = filtered.where(
      (plan) => result == null || plan.totalScore >= result.totalScore,
    );
    final pool = better.isEmpty ? filtered : better;
    return pool.reduce((a, b) => a.totalScore >= b.totalScore ? a : b);
  }
}

class ScanPassMatchSnapshot {
  final double time;
  final List<ScanPassPlayer> attackers;
  final List<ScanPassDefender> defenders;
  final ScanPassPoint ball;
  final ScanPassPlayerRole? ballHolder;
  final bool ballLost;

  const ScanPassMatchSnapshot({
    required this.time,
    required this.attackers,
    required this.defenders,
    required this.ball,
    required this.ballHolder,
    required this.ballLost,
  });

  ScanPassPlayer attacker(ScanPassPlayerRole role) {
    return attackers.firstWhere((player) => player.role == role);
  }
}

class ScanPassTimeline {
  const ScanPassTimeline._();

  static ScanPassMatchSnapshot snapshot({
    required ScanPassScenario scenario,
    required double time,
    ScanPassFirstTouchState? firstTouchState,
    ScanPassPlanResult? result,
  }) {
    final modelTime =
        time.clamp(0.0, _timelineEnd(firstTouchState, result)).toDouble();
    final effectiveFirst = result?.firstTouchState ?? firstTouchState;
    final segments = result?.pathSegments ?? effectiveFirst?.pathSegments;
    final receiver = _receiverAt(
      scenario,
      modelTime,
      effectiveFirst,
      result,
    );
    final ballHolder =
        _ballHolderAt(scenario, modelTime, effectiveFirst, result);
    final ball = ballHolder == ScanPassPlayerRole.centerBack4 &&
            effectiveFirst?.returned == true &&
            modelTime >= effectiveFirst!.completedAt
        ? scenario.centerBack.at(modelTime).position
        : _ballAt(scenario, modelTime, segments);
    return ScanPassMatchSnapshot(
      time: modelTime,
      attackers: <ScanPassPlayer>[
        scenario.centerBack.at(modelTime),
        receiver,
        scenario.support.at(modelTime),
        scenario.forward.at(modelTime),
      ],
      defenders: scenario.defendersAt(modelTime),
      ball: ball,
      ballHolder: ballHolder,
      ballLost: _ballLostAt(modelTime, effectiveFirst, result),
    );
  }

  static double _timelineEnd(
    ScanPassFirstTouchState? firstTouchState,
    ScanPassPlanResult? result,
  ) {
    if (result != null) return math.max(0.01, result.finalTime);
    if (firstTouchState?.returnIntercepted == true) {
      return firstTouchState!.completedAt;
    }
    // A completed touch does not stop the world during the next decision.
    return double.infinity;
  }

  static ScanPassPlayer _receiverAt(
    ScanPassScenario scenario,
    double time,
    ScanPassFirstTouchState? first,
    ScanPassPlanResult? result,
  ) {
    var player = scenario.receiver.at(time);
    final state = result?.firstTouchState ?? first;
    if (state == null || time < state.touchStartTime) return player;
    var position = state.receiverPosition;
    var facing = state.receiverFacingRadians;
    for (final segment in state.pathSegments) {
      if (segment.type != ScanPassPathType.firstTouch) continue;
      if (time < segment.startTime) break;
      if (time <= segment.endTime) {
        position = segment.from.lerp(
          segment.to,
          _segmentProgress(segment, time),
        );
      } else {
        position = segment.to;
      }
    }
    final plan = result;
    if (plan != null) {
      for (final segment in plan.pathSegments) {
        if (segment.type != ScanPassPathType.offBallRun &&
            segment.type != ScanPassPathType.hold) {
          continue;
        }
        if (time < segment.startTime) continue;
        if (time <= segment.endTime) {
          position = segment.type == ScanPassPathType.hold
              ? segment.from
              : segment.from.lerp(segment.to, _segmentProgress(segment, time));
        } else {
          position = segment.to;
        }
      }
    }
    return player.copyWith(position: position, facingRadians: facing);
  }

  static ScanPassPoint _ballAt(
    ScanPassScenario scenario,
    double time,
    List<ScanPassPathSegment>? segments,
  ) {
    if (segments == null || segments.isEmpty) {
      final progress =
          (time / scenario.ballTravelTime).clamp(0.0, 1.0).toDouble();
      return scenario.centerBack.position.lerp(
        scenario.receiver.position,
        progress,
      );
    }
    var ball = segments.first.from;
    for (final segment in segments) {
      if (time < segment.startTime) return ball;
      if (time <= segment.endTime) {
        return switch (segment.type) {
          ScanPassPathType.offBallRun || ScanPassPathType.hold => ball,
          ScanPassPathType.incoming ||
          ScanPassPathType.firstTouch ||
          ScanPassPathType.pass =>
            segment.from.lerp(segment.to, _segmentProgress(segment, time)),
        };
      }
      if (segment.type != ScanPassPathType.offBallRun &&
          segment.type != ScanPassPathType.hold) {
        ball = segment.to;
      }
    }
    return ball;
  }

  static ScanPassPlayerRole? _ballHolderAt(
    ScanPassScenario scenario,
    double time,
    ScanPassFirstTouchState? first,
    ScanPassPlanResult? result,
  ) {
    if (_ballLostAt(time, first, result)) return null;
    if (time <= 0) return ScanPassPlayerRole.centerBack4;
    if (time < scenario.ballTravelTime) return null;
    if (first?.returned == true &&
        time >= first!.touchStartTime &&
        time < first.completedAt) {
      return null;
    }
    if (result != null && time >= result.finalTime) {
      return result.finalReceiverRole;
    }
    if (first == null || time < first.completedAt) {
      return ScanPassPlayerRole.midfielder6;
    }
    if (first.returned) {
      final passBack = result?.pathSegments.where(
        (segment) =>
            segment.type == ScanPassPathType.pass &&
            segment.startTime >= first.completedAt,
      );
      if (passBack != null && passBack.isNotEmpty) {
        final segment = passBack.first;
        if (time >= segment.startTime && time < segment.endTime) {
          return null;
        }
        if (time >= segment.endTime) return result?.finalReceiverRole;
      }
      return ScanPassPlayerRole.centerBack4;
    }
    final laterPass = result?.pathSegments.where(
      (segment) =>
          segment.type == ScanPassPathType.pass &&
          segment.startTime >= first.completedAt,
    );
    if (laterPass != null && laterPass.isNotEmpty) {
      final segment = laterPass.first;
      if (time >= segment.startTime && time < segment.endTime) return null;
      if (time >= segment.endTime) return result?.finalReceiverRole;
    }
    return ScanPassPlayerRole.midfielder6;
  }

  static bool _ballLostAt(
    double time,
    ScanPassFirstTouchState? first,
    ScanPassPlanResult? result,
  ) {
    if (first?.returnIntercepted == true && time >= first!.completedAt) {
      return true;
    }
    return result?.outcome == ScanPassOutcomeType.intercepted &&
        time >= result!.finalTime;
  }

  static double _segmentProgress(ScanPassPathSegment segment, double time) {
    final duration = segment.endTime - segment.startTime;
    if (duration <= 0) return 1;
    return ((time - segment.startTime) / duration).clamp(0.0, 1.0).toDouble();
  }
}

class ScanPassMatchEngine {
  static const Duration defaultChoiceWindow = Duration(milliseconds: 3200);
  static const double _ballSpeed = 0.86;
  static const double _defenderClosingSpeed = 0.38;
  static const double _interceptDistance = 0.048;
  static const double _contestDistance = 0.085;

  const ScanPassMatchEngine();

  ScanPassFirstTouchState applyFirstTouch(
    ScanPassScenario scenario,
    ScanPassFirstTouch action, {
    Duration decisionTime = const Duration(milliseconds: 900),
  }) {
    final decisionSeconds = _seconds(decisionTime);
    final touchStart = scenario.ballTravelTime + decisionSeconds;
    final start = scenario.receiver.at(touchStart).position;
    final defendersAtStart = scenario.defendersAt(touchStart);
    final nearestStart = _nearestDistance(start, defendersAtStart);
    final receiverPosition = switch (action) {
      ScanPassFirstTouch.upperTouch =>
        (start + const ScanPassPoint(0.045, -0.118)).clampToField(),
      ScanPassFirstTouch.lowerTouch =>
        (start + const ScanPassPoint(0.045, 0.118)).clampToField(),
      ScanPassFirstTouch.turnForward =>
        (start + const ScanPassPoint(0.080, 0.000)).clampToField(),
      ScanPassFirstTouch.returnTo4 => start,
    };
    final intendedTouchTarget = action == ScanPassFirstTouch.returnTo4
        ? scenario.centerBack.at(touchStart).position
        : receiverPosition;
    final touchAngle = _angleBetween(start, intendedTouchTarget);
    final turnLoad = _angleDifference(
          scenario.receiver.facingRadians,
          touchAngle,
        ) /
        math.pi;
    final touchDuration = action == ScanPassFirstTouch.returnTo4
        ? math.max(0.22, start.distanceTo(intendedTouchTarget) / _ballSpeed)
        : switch (action) {
            ScanPassFirstTouch.upperTouch ||
            ScanPassFirstTouch.lowerTouch =>
              0.32 + (turnLoad * 0.18),
            ScanPassFirstTouch.turnForward => 0.36 + (turnLoad * 0.26),
            ScanPassFirstTouch.returnTo4 => 0.28,
          };
    var completedAt = touchStart + touchDuration;
    _PassAnalysis? returnPass;
    if (action == ScanPassFirstTouch.returnTo4) {
      returnPass = _analyzePass(
        start,
        scenario.centerBack.at(completedAt).position,
        touchStart,
        scenario,
      );
      completedAt = returnPass.endTime;
    }
    final ballHolder = action == ScanPassFirstTouch.returnTo4
        ? ScanPassPlayerRole.centerBack4
        : ScanPassPlayerRole.midfielder6;
    final ballPosition = action == ScanPassFirstTouch.returnTo4
        ? returnPass!.endPoint
        : receiverPosition;
    final defendersAtEnd = scenario.defendersAt(completedAt);
    final nearestEnd = _nearestDistance(receiverPosition, defendersAtEnd);
    final nearestBall = _nearestDistance(ballPosition, defendersAtEnd);
    final exposure = switch (action) {
      ScanPassFirstTouch.upperTouch ||
      ScanPassFirstTouch.lowerTouch =>
        0.024 + (turnLoad * 0.018),
      ScanPassFirstTouch.turnForward => 0.050 + (turnLoad * 0.040),
      ScanPassFirstTouch.returnTo4 => 0.014 + (turnLoad * 0.014),
    };
    final directionEscape =
        _directionalEscapeBonus(action, start, defendersAtStart);
    final baseControl = switch (action) {
      ScanPassFirstTouch.upperTouch || ScanPassFirstTouch.lowerTouch => 66.0,
      ScanPassFirstTouch.turnForward => 60.0,
      ScanPassFirstTouch.returnTo4 => 78.0,
    };
    final controlRaw = _clampScore(
      baseControl +
          (_normalize(nearestBall - exposure, low: 0.015, high: 0.190) * 0.34) +
          directionEscape -
          (turnLoad * 6),
    );
    final pressureEscapeRaw = _clampScore(
      (_normalize(nearestEnd - nearestStart, low: -0.055, high: 0.125) * 0.50) +
          (_normalize(nearestEnd, low: 0.060, high: 0.240) * 0.40) +
          directionEscape,
    );
    final returnIntercepted = returnPass?.intercepted ?? false;
    final contested = !returnIntercepted &&
            (action == ScanPassFirstTouch.turnForward &&
                nearestEnd < _contestDistance + 0.018) ||
        (!returnIntercepted &&
            action != ScanPassFirstTouch.returnTo4 &&
            nearestEnd < _contestDistance);
    final paths = <ScanPassPathSegment>[
      ScanPassPathSegment(
        from: scenario.centerBack.position,
        to: scenario.receiver.position,
        type: ScanPassPathType.incoming,
        startTime: 0,
        endTime: scenario.ballTravelTime,
      ),
      if (action == ScanPassFirstTouch.returnTo4)
        ScanPassPathSegment(
          from: start,
          to: ballPosition,
          type: ScanPassPathType.pass,
          startTime: touchStart,
          endTime: completedAt,
          contested: returnIntercepted,
        )
      else
        ScanPassPathSegment(
          from: start,
          to: receiverPosition,
          type: ScanPassPathType.firstTouch,
          startTime: touchStart,
          endTime: completedAt,
          contested: contested,
        ),
    ];
    return ScanPassFirstTouchState(
      scenario: scenario,
      action: action,
      decisionTime: decisionTime,
      touchStartTime: touchStart,
      completedAt: completedAt,
      startPosition: start,
      receiverPosition: receiverPosition,
      ballPosition: ballPosition,
      ballHolder: ballHolder,
      receiverFacingRadians: switch (action) {
        ScanPassFirstTouch.upperTouch ||
        ScanPassFirstTouch.lowerTouch ||
        ScanPassFirstTouch.turnForward ||
        ScanPassFirstTouch.returnTo4 =>
          touchAngle,
      },
      controlRaw: returnIntercepted
          ? math.min(controlRaw, 42)
          : contested
              ? math.min(controlRaw, 58)
              : controlRaw,
      pressureEscapeRaw: returnIntercepted
          ? math.min(pressureEscapeRaw, 42)
          : contested
              ? math.min(pressureEscapeRaw, 45)
              : pressureEscapeRaw,
      contested: contested,
      returnIntercepted: returnIntercepted,
      returnInterceptionPoint: returnPass?.interceptionPoint,
      pathSegments: paths,
    );
  }

  ScanPassPlanResult evaluatePlan(
    ScanPassScenario scenario,
    ScanPassFirstTouch firstTouch,
    ScanPassNextAction nextAction, {
    Duration firstDecisionTime = const Duration(milliseconds: 900),
    Duration secondDecisionTime = const Duration(milliseconds: 900),
  }) {
    final firstState = applyFirstTouch(
      scenario,
      firstTouch,
      decisionTime: firstDecisionTime,
    );
    if (!_isNextActionAvailable(firstState.returned, nextAction)) {
      throw ArgumentError.value(
        nextAction,
        'nextAction',
        'Action is not available after $firstTouch',
      );
    }
    if (firstState.returnIntercepted) {
      return _firstReturnLossResult(
        scenario,
        firstTouch,
        nextAction,
        firstDecisionTime,
        secondDecisionTime,
        firstState,
      );
    }
    final decisionSeconds = _seconds(secondDecisionTime);
    var actionStart = firstState.completedAt + decisionSeconds;
    final ballFrom = firstState.ballPosition;
    var finalBall = ballFrom;
    var finalTime = actionStart;
    ScanPassPlayerRole? finalReceiverRole = firstState.ballHolder;
    var outcome = firstState.contested
        ? ScanPassOutcomeType.contested
        : ScanPassOutcomeType.kept;
    var continuationRaw = 0.0;
    var contextRaw = 0.0;
    ScanPassPoint? interceptionPoint;
    var passLaneRaw = 0.0;
    var receiverSpaceRaw = 0.0;
    var progressRaw = 0.0;
    var holdDelta = 0.0;
    final paths = <ScanPassPathSegment>[...firstState.pathSegments];
    final reasons = <ScanPassReason>{};

    reasons.add(
      firstState.controlRaw >= 68
          ? ScanPassReason.controlledFirstTouch
          : ScanPassReason.exposedFirstTouch,
    );
    reasons.add(
      firstState.pressureEscapeRaw >= 62
          ? ScanPassReason.pressureEscaped
          : ScanPassReason.pressureStayed,
    );

    if (firstState.returned) {
      final move = _supportMove(firstState.receiverPosition, nextAction);
      final moveDuration = switch (nextAction) {
        ScanPassNextAction.supportUpper => 0.62,
        ScanPassNextAction.supportForward => 0.70,
        ScanPassNextAction.holdPocket => 0.34,
        _ => 0.0,
      };
      final movedAt = actionStart + moveDuration;
      paths.add(
        ScanPassPathSegment(
          from: firstState.receiverPosition,
          to: move,
          type: nextAction == ScanPassNextAction.holdPocket
              ? ScanPassPathType.hold
              : ScanPassPathType.offBallRun,
          startTime: actionStart,
          endTime: movedAt,
        ),
      );
      final pass = _analyzePass(
        scenario.centerBack.at(movedAt).position,
        move,
        movedAt,
        scenario,
      );
      finalBall = pass.endPoint;
      finalTime = pass.endTime;
      finalReceiverRole =
          pass.intercepted ? null : ScanPassPlayerRole.midfielder6;
      interceptionPoint = pass.interceptionPoint;
      passLaneRaw = pass.laneSafety;
      receiverSpaceRaw = pass.receiverSpace;
      final angleRaw = _receivingAngleValue(
        scenario.centerBack.at(movedAt).position,
        move,
      );
      progressRaw =
          _progressValue(scenario.receiver.position, move, nextAction);
      continuationRaw = _clampScore(
        (pass.laneSafety * 0.36) +
            (pass.arrivalMargin * 0.22) +
            (pass.receiverSpace * 0.24) +
            (angleRaw * 0.18),
      );
      paths.add(
        ScanPassPathSegment(
          from: scenario.centerBack.at(movedAt).position,
          to: pass.endPoint,
          type: ScanPassPathType.pass,
          startTime: movedAt,
          endTime: pass.endTime,
          contested: pass.intercepted,
        ),
      );
      if (pass.intercepted) {
        outcome = ScanPassOutcomeType.intercepted;
      } else {
        outcome = nextAction == ScanPassNextAction.supportForward
            ? ScanPassOutcomeType.progressed
            : ScanPassOutcomeType.recycled;
      }
      reasons.add(
        angleRaw >= 58 && receiverSpaceRaw >= 50 && !pass.intercepted
            ? ScanPassReason.supportAngleCreated
            : ScanPassReason.supportAngleWeak,
      );
    } else {
      final hold = nextAction == ScanPassNextAction.holdPassTo8 ? 0.56 : 0.0;
      if (hold > 0) {
        paths.add(
          ScanPassPathSegment(
            from: firstState.ballPosition,
            to: firstState.ballPosition,
            type: ScanPassPathType.hold,
            startTime: actionStart,
            endTime: actionStart + hold,
          ),
        );
        holdDelta = _holdDelta(scenario, firstState, actionStart);
        actionStart += hold;
      }
      final targetRole = switch (nextAction) {
        ScanPassNextAction.passTo4 => ScanPassPlayerRole.centerBack4,
        ScanPassNextAction.passTo8 ||
        ScanPassNextAction.holdPassTo8 =>
          ScanPassPlayerRole.support8,
        ScanPassNextAction.passTo9 => ScanPassPlayerRole.forward9,
        _ => ScanPassPlayerRole.support8,
      };
      final pass = _analyzePassToRole(
        ballFrom,
        targetRole,
        actionStart,
        scenario,
      );
      finalBall = pass.endPoint;
      finalTime = pass.endTime;
      finalReceiverRole = pass.intercepted ? null : targetRole;
      interceptionPoint = pass.interceptionPoint;
      passLaneRaw = pass.laneSafety;
      receiverSpaceRaw = pass.receiverSpace;
      progressRaw = _progressValue(
        firstState.startPosition,
        pass.intendedPoint,
        nextAction,
      );
      continuationRaw = _clampScore(
        (pass.laneSafety * 0.28) +
            (pass.arrivalMargin * 0.20) +
            (pass.receiverSpace * 0.20) +
            (_recipientOrientationValue(
                  targetRole,
                  scenario.playerAt(targetRole, pass.endTime).facingRadians,
                ) *
                0.08) +
            (_releaseAlignmentValue(
                  firstState.receiverFacingRadians,
                  ballFrom,
                  pass.intendedPoint,
                ) *
                0.16) +
            (holdDelta * 0.16),
      );
      paths.add(
        ScanPassPathSegment(
          from: ballFrom,
          to: pass.endPoint,
          type: ScanPassPathType.pass,
          startTime: actionStart,
          endTime: pass.endTime,
          contested: pass.intercepted,
        ),
      );
      if (pass.intercepted) {
        outcome = ScanPassOutcomeType.intercepted;
      } else if (firstState.contested) {
        outcome = ScanPassOutcomeType.contested;
      } else if (targetRole == ScanPassPlayerRole.forward9) {
        outcome = ScanPassOutcomeType.progressed;
      } else if (targetRole == ScanPassPlayerRole.centerBack4) {
        outcome = ScanPassOutcomeType.recycled;
      } else {
        outcome = ScanPassOutcomeType.kept;
      }
      if (hold > 0) {
        reasons.add(
          holdDelta >= 52
              ? ScanPassReason.holdOpenedLane
              : ScanPassReason.holdInvitedPressure,
        );
      }
    }

    reasons.add(passLaneRaw >= 62
        ? ScanPassReason.clearLane
        : ScanPassReason.laneClosed);
    reasons.add(
      receiverSpaceRaw >= 58
          ? ScanPassReason.receiverAvailable
          : ScanPassReason.receiverCrowded,
    );

    final lossPenalty = outcome == ScanPassOutcomeType.intercepted
        ? 42.0
        : outcome == ScanPassOutcomeType.contested
            ? 18.0
            : 0.0;
    final safetyRaw = _clampScore(
      (firstState.controlRaw * 0.36) +
          (firstState.pressureEscapeRaw * 0.24) +
          (passLaneRaw * 0.22) +
          (receiverSpaceRaw * 0.18) -
          lossPenalty,
    );
    contextRaw = switch (scenario.objective) {
      ScanPassMatchObjective.protectPossession => _clampScore(
          (safetyRaw * 0.64) + (continuationRaw * 0.24) + (progressRaw * 0.12),
        ),
      ScanPassMatchObjective.chaseGoal => _clampScore(
          (safetyRaw * 0.18) + (progressRaw * 0.60) + (continuationRaw * 0.22),
        ),
    };
    if (scenario.objective == ScanPassMatchObjective.protectPossession &&
        outcome != ScanPassOutcomeType.intercepted &&
        safetyRaw >= 58) {
      reasons.add(ScanPassReason.objectiveProtected);
    } else if (scenario.objective == ScanPassMatchObjective.chaseGoal &&
        outcome != ScanPassOutcomeType.intercepted &&
        progressRaw >= 56) {
      reasons.add(ScanPassReason.objectiveProgressed);
    }

    var controlRaw = firstState.controlRaw;
    var pressureRaw = firstState.pressureEscapeRaw;
    if (outcome == ScanPassOutcomeType.intercepted) {
      controlRaw = math.min(controlRaw, 52);
      pressureRaw = math.min(pressureRaw, 48);
      continuationRaw = math.min(continuationRaw, 30);
      contextRaw = math.min(contextRaw, 34);
    } else if (outcome == ScanPassOutcomeType.contested) {
      controlRaw = math.min(controlRaw, 62);
      pressureRaw = math.min(pressureRaw, 54);
      continuationRaw = math.min(continuationRaw, 64);
    }

    return ScanPassPlanResult(
      scenario: scenario,
      firstTouch: firstTouch,
      nextAction: nextAction,
      firstDecisionTime: firstDecisionTime,
      secondDecisionTime: secondDecisionTime,
      firstTouchState: firstState,
      outcome: outcome,
      components: <ScanPassScoreComponent>[
        _component(ScanPassScoreComponentKind.control,
            ScanPassScoreWeights.control, controlRaw),
        _component(
          ScanPassScoreComponentKind.pressureEscape,
          ScanPassScoreWeights.pressureEscape,
          pressureRaw,
        ),
        _component(
          ScanPassScoreComponentKind.continuation,
          ScanPassScoreWeights.continuation,
          continuationRaw,
        ),
        _component(
          ScanPassScoreComponentKind.contextFit,
          ScanPassScoreWeights.contextFit,
          contextRaw,
        ),
      ],
      reasons: reasons.toList(growable: false),
      pathSegments: paths,
      finalBallPosition: finalBall,
      interceptionPoint: interceptionPoint,
      finalReceiverRole: finalReceiverRole,
      finalTime: finalTime,
    );
  }

  ScanPassPlanEvaluation evaluateAlternatives(
    ScanPassScenario scenario, {
    ScanPassFirstTouch? selectedFirstTouch,
    ScanPassNextAction? selectedNextAction,
    Duration firstDecisionTime = const Duration(milliseconds: 900),
    Duration secondDecisionTime = const Duration(milliseconds: 900),
  }) {
    final alternatives = <ScanPassPlanResult>[];
    for (final touch in ScanPassFirstTouch.values) {
      for (final next in availableNextActions(touch)) {
        alternatives.add(
          evaluatePlan(
            scenario,
            touch,
            next,
            firstDecisionTime: firstDecisionTime,
            secondDecisionTime: secondDecisionTime,
          ),
        );
      }
    }
    final selected = selectedFirstTouch == null || selectedNextAction == null
        ? null
        : alternatives.firstWhere(
            (plan) =>
                plan.firstTouch == selectedFirstTouch &&
                plan.nextAction == selectedNextAction,
          );
    return ScanPassPlanEvaluation(
      scenario: scenario,
      selected: selected,
      alternatives: alternatives,
    );
  }

  List<ScanPassNextAction> availableNextActions(ScanPassFirstTouch firstTouch) {
    if (firstTouch == ScanPassFirstTouch.returnTo4) {
      return const <ScanPassNextAction>[
        ScanPassNextAction.supportUpper,
        ScanPassNextAction.supportForward,
        ScanPassNextAction.holdPocket,
      ];
    }
    return const <ScanPassNextAction>[
      ScanPassNextAction.passTo4,
      ScanPassNextAction.passTo8,
      ScanPassNextAction.passTo9,
      ScanPassNextAction.holdPassTo8,
    ];
  }

  static bool _isNextActionAvailable(bool returned, ScanPassNextAction action) {
    return returned
        ? action == ScanPassNextAction.supportUpper ||
            action == ScanPassNextAction.supportForward ||
            action == ScanPassNextAction.holdPocket
        : action == ScanPassNextAction.passTo4 ||
            action == ScanPassNextAction.passTo8 ||
            action == ScanPassNextAction.passTo9 ||
            action == ScanPassNextAction.holdPassTo8;
  }

  static ScanPassScoreComponent _component(
    ScanPassScoreComponentKind kind,
    int max,
    double raw,
  ) {
    final earned = ((raw.clamp(0.0, 100.0).toDouble() / 100) * max).round();
    return ScanPassScoreComponent(
      kind: kind,
      earned: earned.clamp(0, max),
      max: max,
      raw: raw.clamp(0.0, 100.0).toDouble(),
    );
  }

  static ScanPassPlanResult _firstReturnLossResult(
    ScanPassScenario scenario,
    ScanPassFirstTouch firstTouch,
    ScanPassNextAction nextAction,
    Duration firstDecisionTime,
    Duration secondDecisionTime,
    ScanPassFirstTouchState firstState,
  ) {
    final controlRaw = math.min(firstState.controlRaw, 42.0);
    final pressureRaw = math.min(firstState.pressureEscapeRaw, 42.0);
    final reasons = <ScanPassReason>[
      controlRaw >= 68
          ? ScanPassReason.controlledFirstTouch
          : ScanPassReason.exposedFirstTouch,
      pressureRaw >= 62
          ? ScanPassReason.pressureEscaped
          : ScanPassReason.pressureStayed,
      ScanPassReason.laneClosed,
    ];
    return ScanPassPlanResult(
      scenario: scenario,
      firstTouch: firstTouch,
      nextAction: nextAction,
      firstDecisionTime: firstDecisionTime,
      secondDecisionTime: secondDecisionTime,
      firstTouchState: firstState,
      outcome: ScanPassOutcomeType.intercepted,
      components: <ScanPassScoreComponent>[
        _component(
          ScanPassScoreComponentKind.control,
          ScanPassScoreWeights.control,
          controlRaw,
        ),
        _component(
          ScanPassScoreComponentKind.pressureEscape,
          ScanPassScoreWeights.pressureEscape,
          pressureRaw,
        ),
        _component(
          ScanPassScoreComponentKind.continuation,
          ScanPassScoreWeights.continuation,
          8,
        ),
        _component(
          ScanPassScoreComponentKind.contextFit,
          ScanPassScoreWeights.contextFit,
          10,
        ),
      ],
      reasons: reasons,
      pathSegments: firstState.pathSegments,
      finalBallPosition:
          firstState.returnInterceptionPoint ?? firstState.ballPosition,
      interceptionPoint: firstState.returnInterceptionPoint,
      finalReceiverRole: null,
      finalTime: firstState.completedAt,
    );
  }

  static ScanPassPoint _supportMove(
      ScanPassPoint from, ScanPassNextAction action) {
    return switch (action) {
      ScanPassNextAction.supportUpper =>
        (from + const ScanPassPoint(-0.015, -0.145)).clampToField(),
      ScanPassNextAction.supportForward =>
        (from + const ScanPassPoint(0.150, -0.030)).clampToField(),
      ScanPassNextAction.holdPocket => from,
      _ => from,
    };
  }

  static double _directionalEscapeBonus(
    ScanPassFirstTouch action,
    ScanPassPoint receiver,
    List<ScanPassDefender> defenders,
  ) {
    final nearest = defenders.reduce(
      (a, b) =>
          a.position.distanceTo(receiver) <= b.position.distanceTo(receiver)
              ? a
              : b,
    );
    if (action == ScanPassFirstTouch.turnForward) {
      final pressureReceding = defenders.any(
        (defender) =>
            defender.velocity.x > 0.035 &&
            defender.position.distanceTo(receiver) < 0.34 &&
            defender.position.distanceTo(receiver) > _contestDistance,
      );
      return pressureReceding ? 32 : -5;
    }
    if (action == ScanPassFirstTouch.returnTo4) return 2;
    final defenderAbove = nearest.position.y < receiver.y;
    if (action == ScanPassFirstTouch.upperTouch) {
      return defenderAbove ? -6 : 12;
    }
    if (action == ScanPassFirstTouch.lowerTouch) {
      return defenderAbove ? 12 : -6;
    }
    return 0;
  }

  static double _holdDelta(
    ScanPassScenario scenario,
    ScanPassFirstTouchState firstState,
    double actionStart,
  ) {
    final immediate = _distanceToSegment(
      scenario.defendersAt(actionStart)[1].position,
      firstState.ballPosition,
      scenario.support.at(actionStart).position,
    );
    final later = _distanceToSegment(
      scenario.defendersAt(actionStart + 0.56)[1].position,
      firstState.ballPosition,
      scenario.support.at(actionStart + 0.56).position,
    );
    return _clampScore(48 + ((later - immediate) * 260));
  }

  static double _recipientOrientationValue(
    ScanPassPlayerRole role,
    double facingRadians,
  ) {
    if (role == ScanPassPlayerRole.centerBack4) return 72;
    final forwardAlignment =
        math.cos(facingRadians).clamp(-1.0, 1.0).toDouble();
    return _clampScore(48 + (forwardAlignment * 38));
  }

  static double _receivingAngleValue(ScanPassPoint from, ScanPassPoint to) {
    final angle = to - from;
    final central = 1 - ((to.y - 0.50).abs() * 1.35);
    final width = (angle.y.abs() * 2.6).clamp(0.0, 1.0).toDouble();
    return _clampScore((central * 52) + (width * 48));
  }

  static double _releaseAlignmentValue(
    double facingRadians,
    ScanPassPoint from,
    ScanPassPoint to,
  ) {
    final passAngle = _angleBetween(from, to);
    final alignment = math.cos(_angleDifference(facingRadians, passAngle));
    return _clampScore(50 + (alignment * 50));
  }

  static double _progressValue(
    ScanPassPoint start,
    ScanPassPoint end,
    ScanPassNextAction action,
  ) {
    final gain = end.x - start.x;
    final central = (1 - ((end.y - 0.50).abs() * 1.35)).clamp(0.0, 1.0);
    final actionBonus = switch (action) {
      ScanPassNextAction.passTo9 => 18.0,
      ScanPassNextAction.supportForward => 14.0,
      ScanPassNextAction.passTo8 || ScanPassNextAction.holdPassTo8 => 5.0,
      ScanPassNextAction.passTo4 || ScanPassNextAction.holdPocket => -8.0,
      ScanPassNextAction.supportUpper => 2.0,
    };
    return _clampScore(
      (_normalize(gain, low: -0.18, high: 0.42) * 0.74) +
          (central * 18) +
          actionBonus,
    );
  }

  static _PassAnalysis _analyzePass(
    ScanPassPoint from,
    ScanPassPoint intendedTo,
    double startTime,
    ScanPassScenario scenario,
  ) {
    final distance = from.distanceTo(intendedTo);
    final duration = math.max(0.18, distance / _ballSpeed);
    final endTime = startTime + duration;
    var minLaneDistance = 1.0;
    ScanPassPoint? interception;
    double? interceptionTime;
    for (var i = 1; i <= 12; i += 1) {
      final t = i / 12;
      final sampleTime = startTime + (duration * t);
      final ball = from.lerp(intendedTo, t);
      for (final defender in scenario.defendersAt(sampleTime)) {
        final defenderDistance = defender.position.distanceTo(ball);
        minLaneDistance = math.min(minLaneDistance, defenderDistance);
        if (interception == null && defenderDistance < _interceptDistance) {
          interception = ball;
          interceptionTime = sampleTime;
        }
      }
    }
    final defendersAtStart = scenario.defendersAt(startTime);
    final defendersAtEnd = scenario.defendersAt(endTime);
    final nearestArrival = defendersAtStart
        .map((defender) =>
            defender.position.distanceTo(intendedTo) / _defenderClosingSpeed)
        .fold<double>(10, math.min);
    return _PassAnalysis(
      intendedPoint: intendedTo,
      endPoint: interception ?? intendedTo,
      endTime: interceptionTime ?? endTime,
      laneSafety: _normalize(minLaneDistance, low: 0.035, high: 0.165),
      arrivalMargin: _normalize(
        nearestArrival - duration,
        low: -0.10,
        high: 0.80,
      ),
      receiverSpace: _normalize(
        _nearestDistance(intendedTo, defendersAtEnd),
        low: 0.065,
        high: 0.250,
      ),
      intercepted: interception != null,
      interceptionPoint: interception,
    );
  }

  static _PassAnalysis _analyzePassToRole(
    ScanPassPoint from,
    ScanPassPlayerRole targetRole,
    double startTime,
    ScanPassScenario scenario,
  ) {
    final currentTarget = scenario.playerAt(targetRole, startTime).position;
    final estimatedDuration =
        math.max(0.18, from.distanceTo(currentTarget) / _ballSpeed);
    final intendedTo =
        scenario.playerAt(targetRole, startTime + estimatedDuration).position;
    return _analyzePass(from, intendedTo, startTime, scenario);
  }

  static double _nearestDistance(
      ScanPassPoint point, List<ScanPassDefender> defenders) {
    return defenders
        .map((defender) => defender.position.distanceTo(point))
        .fold<double>(1, math.min);
  }

  static double _distanceToSegment(
    ScanPassPoint point,
    ScanPassPoint a,
    ScanPassPoint b,
  ) {
    final ab = b - a;
    final lengthSquared = ab.dot(ab);
    if (lengthSquared == 0) return point.distanceTo(a);
    final t = ((point - a).dot(ab) / lengthSquared).clamp(0.0, 1.0).toDouble();
    final projected = a + (ab * t);
    return point.distanceTo(projected);
  }

  static double _normalize(
    double value, {
    required double low,
    required double high,
  }) {
    if (high <= low) return 0;
    return _clampScore(((value - low) / (high - low)) * 100);
  }

  static double _clampScore(double value) => value.clamp(0.0, 100.0).toDouble();

  static double _angleBetween(ScanPassPoint from, ScanPassPoint to) {
    final delta = to - from;
    return math.atan2(delta.y, delta.x);
  }

  static double _angleDifference(double a, double b) {
    final diff = (a - b).abs() % (math.pi * 2);
    return diff > math.pi ? (math.pi * 2) - diff : diff;
  }

  static double _seconds(Duration duration) =>
      duration.inMilliseconds.clamp(0, 1 << 30) / 1000;
}

class _PassAnalysis {
  final ScanPassPoint intendedPoint;
  final ScanPassPoint endPoint;
  final double endTime;
  final double laneSafety;
  final double arrivalMargin;
  final double receiverSpace;
  final bool intercepted;
  final ScanPassPoint? interceptionPoint;

  const _PassAnalysis({
    required this.intendedPoint,
    required this.endPoint,
    required this.endTime,
    required this.laneSafety,
    required this.arrivalMargin,
    required this.receiverSpace,
    required this.intercepted,
    required this.interceptionPoint,
  });
}

class ScanPassChoiceClock {
  final DateTime startedAt;
  final Duration choiceWindow;

  const ScanPassChoiceClock({
    required this.startedAt,
    required this.choiceWindow,
  });

  Duration elapsedAt(DateTime now) {
    final elapsed = now.difference(startedAt);
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  Duration remainingAt(DateTime now) {
    final remaining = choiceWindow - elapsedAt(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool isExpiredAt(DateTime now) => remainingAt(now) == Duration.zero;

  Duration responseTimeAt(DateTime now) {
    final elapsed = elapsedAt(now);
    return elapsed > choiceWindow ? choiceWindow : elapsed;
  }
}

class ScanPassScanObservation {
  final Duration observedAt;
  final List<ScanPassDefender> defenders;

  const ScanPassScanObservation({
    required this.observedAt,
    required this.defenders,
  });
}

class ScanPassRoundResult {
  final int roundNumber;
  final String scenarioId;
  final String? planId;
  final int chosenScore;
  final int bestScore;
  final Duration decisionTime;
  final bool timedOut;
  final ScanPassTimeoutPhase? timeoutPhase;
  final int pressureEarned;
  final int pressureMax;
  final int continuationEarned;
  final int continuationMax;

  const ScanPassRoundResult({
    required this.roundNumber,
    required this.scenarioId,
    required this.planId,
    required this.chosenScore,
    required this.bestScore,
    required this.decisionTime,
    required this.pressureEarned,
    required this.pressureMax,
    required this.continuationEarned,
    required this.continuationMax,
    this.timedOut = false,
    this.timeoutPhase,
  });

  double get decisionAccuracyPercent {
    if (bestScore <= 0) return 0;
    return ((chosenScore / bestScore) * 100).clamp(0.0, 100.0).toDouble();
  }
}

class ScanPassSessionSummary {
  final int roundsPlayed;
  final int completedRounds;
  final int timeouts;
  final double averageScore;
  final double decisionAccuracyPercent;
  final double pressureHandlingPercent;
  final double continuationPercent;
  final int averageDecisionMs;

  const ScanPassSessionSummary({
    required this.roundsPlayed,
    required this.completedRounds,
    required this.timeouts,
    required this.averageScore,
    required this.decisionAccuracyPercent,
    required this.pressureHandlingPercent,
    required this.continuationPercent,
    required this.averageDecisionMs,
  });

  static ScanPassSessionSummary fromResults(List<ScanPassRoundResult> results) {
    if (results.isEmpty) {
      return const ScanPassSessionSummary(
        roundsPlayed: 0,
        completedRounds: 0,
        timeouts: 0,
        averageScore: 0,
        decisionAccuracyPercent: 0,
        pressureHandlingPercent: 0,
        continuationPercent: 0,
        averageDecisionMs: 0,
      );
    }
    var scoreTotal = 0;
    var accuracyTotal = 0.0;
    var decisionTotal = 0;
    var pressureEarned = 0;
    var pressureMax = 0;
    var continuationEarned = 0;
    var continuationMax = 0;
    var timeouts = 0;
    for (final result in results) {
      scoreTotal += result.chosenScore;
      accuracyTotal += result.decisionAccuracyPercent;
      decisionTotal += result.decisionTime.inMilliseconds;
      pressureEarned += result.pressureEarned;
      pressureMax += result.pressureMax;
      continuationEarned += result.continuationEarned;
      continuationMax += result.continuationMax;
      if (result.timedOut) timeouts += 1;
    }
    return ScanPassSessionSummary(
      roundsPlayed: results.length,
      completedRounds: results.length - timeouts,
      timeouts: timeouts,
      averageScore: scoreTotal / results.length,
      decisionAccuracyPercent: accuracyTotal / results.length,
      pressureHandlingPercent:
          pressureMax == 0 ? 0 : (pressureEarned / pressureMax) * 100,
      continuationPercent: continuationMax == 0
          ? 0
          : (continuationEarned / continuationMax) * 100,
      averageDecisionMs: (decisionTotal / results.length).round(),
    );
  }
}

class ScanPassPersonalSummary {
  final int sessionsPlayed;
  final double lastAverageScore;
  final double bestAverageScore;
  final double lastDecisionAccuracyPercent;
  final double bestDecisionAccuracyPercent;
  final double lastPressureHandlingPercent;
  final double bestPressureHandlingPercent;
  final double lastContinuationPercent;
  final double bestContinuationPercent;
  final int lastAverageDecisionMs;
  final String updatedAtIso;

  const ScanPassPersonalSummary({
    required this.sessionsPlayed,
    required this.lastAverageScore,
    required this.bestAverageScore,
    required this.lastDecisionAccuracyPercent,
    required this.bestDecisionAccuracyPercent,
    required this.lastPressureHandlingPercent,
    required this.bestPressureHandlingPercent,
    required this.lastContinuationPercent,
    required this.bestContinuationPercent,
    required this.lastAverageDecisionMs,
    required this.updatedAtIso,
  });

  const ScanPassPersonalSummary.empty()
      : sessionsPlayed = 0,
        lastAverageScore = 0,
        bestAverageScore = 0,
        lastDecisionAccuracyPercent = 0,
        bestDecisionAccuracyPercent = 0,
        lastPressureHandlingPercent = 0,
        bestPressureHandlingPercent = 0,
        lastContinuationPercent = 0,
        bestContinuationPercent = 0,
        lastAverageDecisionMs = 0,
        updatedAtIso = '';

  factory ScanPassPersonalSummary.fromJson(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const ScanPassPersonalSummary.empty();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const ScanPassPersonalSummary.empty();
      return ScanPassPersonalSummary(
        sessionsPlayed: _asInt(decoded['sessionsPlayed']),
        lastAverageScore: _asDouble(decoded['lastAverageScore']),
        bestAverageScore: _asDouble(decoded['bestAverageScore']),
        lastDecisionAccuracyPercent:
            _asDouble(decoded['lastDecisionAccuracyPercent']),
        bestDecisionAccuracyPercent:
            _asDouble(decoded['bestDecisionAccuracyPercent']),
        lastPressureHandlingPercent:
            _asDouble(decoded['lastPressureHandlingPercent']),
        bestPressureHandlingPercent:
            _asDouble(decoded['bestPressureHandlingPercent']),
        lastContinuationPercent: _asDouble(decoded['lastContinuationPercent']),
        bestContinuationPercent: _asDouble(decoded['bestContinuationPercent']),
        lastAverageDecisionMs: _asInt(decoded['lastAverageDecisionMs']),
        updatedAtIso: decoded['updatedAtIso']?.toString() ?? '',
      );
    } catch (_) {
      return const ScanPassPersonalSummary.empty();
    }
  }

  ScanPassPersonalSummary recordSession(
    ScanPassSessionSummary session, {
    required DateTime updatedAt,
  }) {
    return ScanPassPersonalSummary(
      sessionsPlayed: sessionsPlayed + 1,
      lastAverageScore: session.averageScore,
      bestAverageScore: math.max(bestAverageScore, session.averageScore),
      lastDecisionAccuracyPercent: session.decisionAccuracyPercent,
      bestDecisionAccuracyPercent: math.max(
        bestDecisionAccuracyPercent,
        session.decisionAccuracyPercent,
      ),
      lastPressureHandlingPercent: session.pressureHandlingPercent,
      bestPressureHandlingPercent: math.max(
        bestPressureHandlingPercent,
        session.pressureHandlingPercent,
      ),
      lastContinuationPercent: session.continuationPercent,
      bestContinuationPercent: math.max(
        bestContinuationPercent,
        session.continuationPercent,
      ),
      lastAverageDecisionMs: session.averageDecisionMs,
      updatedAtIso: updatedAt.toIso8601String(),
    );
  }

  String toJson() => jsonEncode(<String, dynamic>{
        'version': 2,
        'sessionsPlayed': sessionsPlayed,
        'lastAverageScore': lastAverageScore,
        'bestAverageScore': bestAverageScore,
        'lastDecisionAccuracyPercent': lastDecisionAccuracyPercent,
        'bestDecisionAccuracyPercent': bestDecisionAccuracyPercent,
        'lastPressureHandlingPercent': lastPressureHandlingPercent,
        'bestPressureHandlingPercent': bestPressureHandlingPercent,
        'lastContinuationPercent': lastContinuationPercent,
        'bestContinuationPercent': bestContinuationPercent,
        'lastAverageDecisionMs': lastAverageDecisionMs,
        'updatedAtIso': updatedAtIso,
      });

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
