import 'dart:convert';
import 'dart:math' as math;

enum AuthoredTouchContinuation { openSide, pressureSide }

enum AuthoredTouchTeam { attack, defense }

enum AuthoredTouchRole {
  initialPasser,
  receiver,
  forwardSupport,
  pressingDefender,
  coveringDefender,
}

enum AuthoredTouchFoot { left, right }

enum AuthoredTouchEventType {
  initialPass,
  firstTouch,
  carryTouch,
  forwardPass,
  receive,
  steal,
  defenderCarry,
}

enum AuthoredTouchPhase {
  prepare,
  incomingPass,
  firstTouch,
  turnAndCarry,
  forwardPass,
  forwardReceive,
  pressureSteal,
  defenderCarry,
  complete,
}

class AuthoredTouchPoint {
  final double x;
  final double y;
  final double z;

  const AuthoredTouchPoint(this.x, this.y, [this.z = 0]);

  bool get isFinite => x.isFinite && y.isFinite && z.isFinite;

  double distanceTo(AuthoredTouchPoint other) {
    final dx = x - other.x;
    final dy = y - other.y;
    final dz = z - other.z;
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  AuthoredTouchPoint operator +(AuthoredTouchPoint other) =>
      AuthoredTouchPoint(x + other.x, y + other.y, z + other.z);

  AuthoredTouchPoint operator -(AuthoredTouchPoint other) =>
      AuthoredTouchPoint(x - other.x, y - other.y, z - other.z);

  AuthoredTouchPoint scaled(double factor) =>
      AuthoredTouchPoint(x * factor, y * factor, z * factor);

  double dot(AuthoredTouchPoint other) =>
      x * other.x + y * other.y + z * other.z;

  double get magnitude => math.sqrt(x * x + y * y + z * z);

  AuthoredTouchPoint normalized() {
    final length = magnitude;
    return length <= 1e-9
        ? const AuthoredTouchPoint(0, 0, 0)
        : scaled(1 / length);
  }

  static AuthoredTouchPoint lerp(
    AuthoredTouchPoint a,
    AuthoredTouchPoint b,
    double t,
  ) =>
      AuthoredTouchPoint(
        a.x + (b.x - a.x) * t,
        a.y + (b.y - a.y) * t,
        a.z + (b.z - a.z) * t,
      );

  factory AuthoredTouchPoint.fromJson(List<Object?> json) => AuthoredTouchPoint(
        (json[0] as num).toDouble(),
        (json[1] as num).toDouble(),
        json.length > 2 ? (json[2] as num).toDouble() : 0,
      );
}

class AuthoredTouchBounds {
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  const AuthoredTouchBounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  double get width => maxX - minX;
  double get height => maxY - minY;

  bool contains(AuthoredTouchPoint point, {double margin = 0}) =>
      point.x >= minX - margin &&
      point.x <= maxX + margin &&
      point.y >= minY - margin &&
      point.y <= maxY + margin;

  factory AuthoredTouchBounds.fromJson(Map<String, Object?> json) =>
      AuthoredTouchBounds(
        minX: (json['minX'] as num).toDouble(),
        maxX: (json['maxX'] as num).toDouble(),
        minY: (json['minY'] as num).toDouble(),
        maxY: (json['maxY'] as num).toDouble(),
      );
}

class AuthoredTouchProvenance {
  final bool capturedTracking;
  final bool aiMeasurement;
  final bool coachCertified;
  final bool fictionalPlayers;
  final String method;

  const AuthoredTouchProvenance({
    required this.capturedTracking,
    required this.aiMeasurement,
    required this.coachCertified,
    required this.fictionalPlayers,
    required this.method,
  });

  factory AuthoredTouchProvenance.fromJson(Map<String, Object?> json) =>
      AuthoredTouchProvenance(
        capturedTracking: json['capturedTracking']! as bool,
        aiMeasurement: json['aiMeasurement']! as bool,
        coachCertified: json['coachCertified']! as bool,
        fictionalPlayers: json['fictionalPlayers']! as bool,
        method: json['method']! as String,
      );
}

class AuthoredTouchPlayer {
  final String id;
  final int number;
  final AuthoredTouchTeam team;
  final AuthoredTouchRole role;

  const AuthoredTouchPlayer({
    required this.id,
    required this.number,
    required this.team,
    required this.role,
  });

  factory AuthoredTouchPlayer.fromJson(Map<String, Object?> json) =>
      AuthoredTouchPlayer(
        id: json['id']! as String,
        number: json['number']! as int,
        team: AuthoredTouchTeam.values.byName(json['team']! as String),
        role: AuthoredTouchRole.values.byName(json['role']! as String),
      );
}

class AuthoredTouchPose {
  final AuthoredTouchPoint root;
  final double bodyFacing;
  final AuthoredTouchPoint leftFoot;
  final AuthoredTouchPoint rightFoot;

  const AuthoredTouchPose({
    required this.root,
    required this.bodyFacing,
    required this.leftFoot,
    required this.rightFoot,
  });

  AuthoredTouchPoint foot(AuthoredTouchFoot foot) =>
      foot == AuthoredTouchFoot.left ? leftFoot : rightFoot;
}

/// A deterministic metric body rig derived from an authored root, facing and
/// shoe-contact pair. The shoes remain the source pose points: this rig never
/// rescales or moves them to make an unreachable pose look valid.
class AuthoredTouchBodyPose {
  final AuthoredTouchPoint pelvisCenter;
  final AuthoredTouchPoint chestCenter;
  final AuthoredTouchPoint shoulderCenter;
  final AuthoredTouchPoint headCenter;
  final AuthoredTouchPoint leftHip;
  final AuthoredTouchPoint rightHip;
  final AuthoredTouchPoint leftKnee;
  final AuthoredTouchPoint rightKnee;
  final AuthoredTouchPoint leftAnkle;
  final AuthoredTouchPoint rightAnkle;
  final AuthoredTouchPoint leftShoulder;
  final AuthoredTouchPoint rightShoulder;
  final AuthoredTouchPoint leftElbow;
  final AuthoredTouchPoint rightElbow;
  final AuthoredTouchPoint leftHand;
  final AuthoredTouchPoint rightHand;
  final List<AuthoredTouchPoint> torsoVertices;
  final double leftLegReach;
  final double rightLegReach;

  const AuthoredTouchBodyPose({
    required this.pelvisCenter,
    required this.chestCenter,
    required this.shoulderCenter,
    required this.headCenter,
    required this.leftHip,
    required this.rightHip,
    required this.leftKnee,
    required this.rightKnee,
    required this.leftAnkle,
    required this.rightAnkle,
    required this.leftShoulder,
    required this.rightShoulder,
    required this.leftElbow,
    required this.rightElbow,
    required this.leftHand,
    required this.rightHand,
    required this.torsoVertices,
    required this.leftLegReach,
    required this.rightLegReach,
  });

  Iterable<AuthoredTouchPoint> get joints sync* {
    yield pelvisCenter;
    yield chestCenter;
    yield shoulderCenter;
    yield headCenter;
    yield leftHip;
    yield rightHip;
    yield leftKnee;
    yield rightKnee;
    yield leftAnkle;
    yield rightAnkle;
    yield leftShoulder;
    yield rightShoulder;
    yield leftElbow;
    yield rightElbow;
    yield leftHand;
    yield rightHand;
    yield* torsoVertices;
  }

  bool get isFinite => joints.every((point) => point.isFinite);
}

class AuthoredTouchBodyRig {
  static const double upperLegLength = .52;
  static const double lowerLegLength = .52;
  static const double maximumLegReach = upperLegLength + lowerLegLength;
  static const double pelvisHeight = .84;
  static const double torsoDepth = .16;
  static const double hipHalfWidth = .16;
  static const double shoulderHalfWidth = .34;

  const AuthoredTouchBodyRig();

  AuthoredTouchBodyPose solve(AuthoredTouchPose pose) {
    final forward = AuthoredTouchPoint(
      math.cos(pose.bodyFacing),
      math.sin(pose.bodyFacing),
    );
    final side = AuthoredTouchPoint(-forward.y, forward.x);
    // Balance over the stance feet and crouch for a lunge instead of
    // stretching the leg bones to reach a planted shoe.
    final stanceCenter = AuthoredTouchPoint(
      (pose.leftFoot.x + pose.rightFoot.x) / 2,
      (pose.leftFoot.y + pose.rightFoot.y) / 2,
    );
    final pelvisGround = AuthoredTouchPoint.lerp(pose.root, stanceCenter, .7) +
        forward.scaled(.015);
    double reachableHeight(AuthoredTouchPoint hip, AuthoredTouchPoint ankle) {
      final dx = hip.x - ankle.x;
      final dy = hip.y - ankle.y;
      const safeReach = maximumLegReach * .98;
      return ankle.z +
          math.sqrt(math.max(.04, safeReach * safeReach - dx * dx - dy * dy));
    }

    final height = math.min(
      pelvisHeight,
      math.min(
        reachableHeight(
            pelvisGround + side.scaled(hipHalfWidth), pose.leftFoot),
        reachableHeight(
            pelvisGround - side.scaled(hipHalfWidth), pose.rightFoot),
      ),
    );
    final pelvis = pelvisGround + AuthoredTouchPoint(0, 0, height);
    final chest =
        pelvis + forward.scaled(.04) + const AuthoredTouchPoint(0, 0, .36);
    final shoulders =
        pelvis + forward.scaled(.06) + const AuthoredTouchPoint(0, 0, .55);
    final head =
        pelvis + forward.scaled(.07) + const AuthoredTouchPoint(0, 0, .86);
    final leftHip = pelvis + side.scaled(hipHalfWidth);
    final rightHip = pelvis - side.scaled(hipHalfWidth);
    final leftLeg = _solveLeg(leftHip, pose.leftFoot, forward);
    final rightLeg = _solveLeg(rightHip, pose.rightFoot, forward);
    final leftShoulder = shoulders + side.scaled(shoulderHalfWidth);
    final rightShoulder = shoulders - side.scaled(shoulderHalfWidth);
    final leftElbow = leftShoulder +
        side.scaled(.16) +
        forward.scaled(.05) -
        const AuthoredTouchPoint(0, 0, .31);
    final rightElbow = rightShoulder -
        side.scaled(.16) +
        forward.scaled(.05) -
        const AuthoredTouchPoint(0, 0, .31);
    final leftHand = leftElbow -
        side.scaled(.04) +
        forward.scaled(.06) -
        const AuthoredTouchPoint(0, 0, .31);
    final rightHand = rightElbow +
        side.scaled(.04) +
        forward.scaled(.06) -
        const AuthoredTouchPoint(0, 0, .31);

    List<AuthoredTouchPoint> ring(
      AuthoredTouchPoint center,
      double halfWidth,
    ) =>
        <AuthoredTouchPoint>[
          center + side.scaled(halfWidth) + forward.scaled(torsoDepth),
          center + side.scaled(halfWidth) - forward.scaled(torsoDepth),
          center - side.scaled(halfWidth) - forward.scaled(torsoDepth),
          center - side.scaled(halfWidth) + forward.scaled(torsoDepth),
        ];

    return AuthoredTouchBodyPose(
      pelvisCenter: pelvis,
      chestCenter: chest,
      shoulderCenter: shoulders,
      headCenter: head,
      leftHip: leftHip,
      rightHip: rightHip,
      leftKnee: leftLeg.knee,
      rightKnee: rightLeg.knee,
      leftAnkle: pose.leftFoot,
      rightAnkle: pose.rightFoot,
      leftShoulder: leftShoulder,
      rightShoulder: rightShoulder,
      leftElbow: leftElbow,
      rightElbow: rightElbow,
      leftHand: leftHand,
      rightHand: rightHand,
      torsoVertices: <AuthoredTouchPoint>[
        ...ring(pelvis, .22),
        ...ring(shoulders, shoulderHalfWidth),
      ],
      leftLegReach: leftLeg.reach,
      rightLegReach: rightLeg.reach,
    );
  }

  _AuthoredTouchLegSolution _solveLeg(
    AuthoredTouchPoint hip,
    AuthoredTouchPoint ankle,
    AuthoredTouchPoint forward,
  ) {
    final hipToAnkle = ankle - hip;
    final reach = hipToAnkle.magnitude;
    final direction = hipToAnkle.normalized();
    final halfReach = math.min(reach, maximumLegReach - 1e-6) / 2;
    final bendHeight = math.sqrt(math.max(
      0,
      upperLegLength * upperLegLength - halfReach * halfReach,
    ));
    var bend = forward - direction.scaled(forward.dot(direction));
    if (bend.magnitude < 1e-6) {
      bend = const AuthoredTouchPoint(0, 0, 1) - direction.scaled(direction.z);
    }
    final knee = AuthoredTouchPoint.lerp(hip, ankle, .5) +
        bend.normalized().scaled(bendHeight);
    return _AuthoredTouchLegSolution(knee: knee, reach: reach);
  }
}

class _AuthoredTouchLegSolution {
  final AuthoredTouchPoint knee;
  final double reach;

  const _AuthoredTouchLegSolution({required this.knee, required this.reach});
}

class AuthoredTouchPoseKeyframe extends AuthoredTouchPose {
  final double time;

  const AuthoredTouchPoseKeyframe({
    required this.time,
    required super.root,
    required super.bodyFacing,
    required super.leftFoot,
    required super.rightFoot,
  });

  factory AuthoredTouchPoseKeyframe.fromJson(Map<String, Object?> json) =>
      AuthoredTouchPoseKeyframe(
        time: (json['t'] as num).toDouble(),
        root: AuthoredTouchPoint.fromJson(json['root']! as List<Object?>),
        bodyFacing: (json['facing'] as num).toDouble(),
        leftFoot:
            AuthoredTouchPoint.fromJson(json['leftFoot']! as List<Object?>),
        rightFoot:
            AuthoredTouchPoint.fromJson(json['rightFoot']! as List<Object?>),
      );
}

class AuthoredTouchBallKeyframe {
  final double time;
  final AuthoredTouchPoint point;
  final double rotation;

  const AuthoredTouchBallKeyframe({
    required this.time,
    required this.point,
    required this.rotation,
  });

  factory AuthoredTouchBallKeyframe.fromJson(Map<String, Object?> json) =>
      AuthoredTouchBallKeyframe(
        time: (json['t'] as num).toDouble(),
        point: AuthoredTouchPoint.fromJson(json['point']! as List<Object?>),
        rotation: (json['rotation'] as num).toDouble(),
      );
}

class AuthoredTouchBallState {
  final AuthoredTouchPoint point;
  final double rotation;

  const AuthoredTouchBallState(this.point, this.rotation);
}

class AuthoredTouchEvent {
  final String id;
  final double time;
  final AuthoredTouchEventType type;
  final String actorId;
  final String? targetId;
  final AuthoredTouchFoot? foot;

  const AuthoredTouchEvent({
    required this.id,
    required this.time,
    required this.type,
    required this.actorId,
    this.targetId,
    this.foot,
  });

  factory AuthoredTouchEvent.fromJson(Map<String, Object?> json) =>
      AuthoredTouchEvent(
        id: json['id']! as String,
        time: (json['t'] as num).toDouble(),
        type: AuthoredTouchEventType.values.byName(json['type']! as String),
        actorId: json['actor']! as String,
        targetId: json['target'] as String?,
        foot: json['foot'] == null
            ? null
            : AuthoredTouchFoot.values.byName(json['foot']! as String),
      );
}

class AuthoredTouchPlantWindow {
  final String playerId;
  final AuthoredTouchFoot foot;
  final double start;
  final double end;
  final AuthoredTouchPoint point;

  const AuthoredTouchPlantWindow({
    required this.playerId,
    required this.foot,
    required this.start,
    required this.end,
    required this.point,
  });

  factory AuthoredTouchPlantWindow.fromJson(Map<String, Object?> json) =>
      AuthoredTouchPlantWindow(
        playerId: json['player']! as String,
        foot: AuthoredTouchFoot.values.byName(json['foot']! as String),
        start: (json['start'] as num).toDouble(),
        end: (json['end'] as num).toDouble(),
        point: AuthoredTouchPoint.fromJson(json['point']! as List<Object?>),
      );
}

class AuthoredTouchPhaseMarker {
  final double time;
  final AuthoredTouchPhase phase;

  const AuthoredTouchPhaseMarker(this.time, this.phase);

  factory AuthoredTouchPhaseMarker.fromJson(Map<String, Object?> json) =>
      AuthoredTouchPhaseMarker(
        (json['t'] as num).toDouble(),
        AuthoredTouchPhase.values.byName(json['phase']! as String),
      );
}

class AuthoredTouchMotion {
  final Map<String, List<AuthoredTouchPoseKeyframe>> players;
  final List<AuthoredTouchBallKeyframe> ball;

  const AuthoredTouchMotion({required this.players, required this.ball});

  factory AuthoredTouchMotion.fromJson(Map<String, Object?> json) {
    final playerJson = json['players']! as Map<String, Object?>;
    return AuthoredTouchMotion(
      players: <String, List<AuthoredTouchPoseKeyframe>>{
        for (final entry in playerJson.entries)
          entry.key: (entry.value! as List<Object?>)
              .cast<Map<String, Object?>>()
              .map(AuthoredTouchPoseKeyframe.fromJson)
              .toList(growable: false),
      },
      ball: (json['ball']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(AuthoredTouchBallKeyframe.fromJson)
          .toList(growable: false),
    );
  }

  AuthoredTouchPose poseAt(String playerId, double time) =>
      _samplePose(players[playerId]!, time);

  AuthoredTouchBallState ballAt(double time) => _sampleBall(ball, time);
}

class AuthoredTouchBranch {
  final AuthoredTouchContinuation continuation;
  final AuthoredTouchMotion motion;
  final List<AuthoredTouchEvent> events;
  final List<AuthoredTouchPlantWindow> plantWindows;
  final List<AuthoredTouchPhaseMarker> phases;

  const AuthoredTouchBranch({
    required this.continuation,
    required this.motion,
    required this.events,
    required this.plantWindows,
    required this.phases,
  });

  factory AuthoredTouchBranch.fromJson(
    AuthoredTouchContinuation continuation,
    Map<String, Object?> json,
  ) =>
      AuthoredTouchBranch(
        continuation: continuation,
        motion: AuthoredTouchMotion.fromJson(
          json['motion']! as Map<String, Object?>,
        ),
        events: (json['events']! as List<Object?>)
            .cast<Map<String, Object?>>()
            .map(AuthoredTouchEvent.fromJson)
            .toList(growable: false),
        plantWindows: (json['plantWindows']! as List<Object?>)
            .cast<Map<String, Object?>>()
            .map(AuthoredTouchPlantWindow.fromJson)
            .toList(growable: false),
        phases: (json['phases']! as List<Object?>)
            .cast<Map<String, Object?>>()
            .map(AuthoredTouchPhaseMarker.fromJson)
            .toList(growable: false),
      );

  AuthoredTouchPhase phaseAt(double time) {
    var phase = phases.first.phase;
    for (final marker in phases) {
      if (marker.time > time) break;
      phase = marker.phase;
    }
    return phase;
  }
}

class AuthoredTouchFrame {
  final double time;
  final AuthoredTouchContinuation continuation;
  final Map<String, AuthoredTouchPose> players;
  final AuthoredTouchBallState ball;
  final AuthoredTouchPhase phase;
  final String? possessionPlayerId;

  const AuthoredTouchFrame({
    required this.time,
    required this.continuation,
    required this.players,
    required this.ball,
    required this.phase,
    required this.possessionPlayerId,
  });
}

class AuthoredTouchSample {
  final int schemaVersion;
  final String id;
  final String kind;
  final AuthoredTouchProvenance provenance;
  final double duration;
  final double sharedUntil;
  final double playbackRate;
  final AuthoredTouchBounds contextBounds;
  final List<AuthoredTouchPlayer> players;
  final AuthoredTouchMotion sharedMotion;
  final List<AuthoredTouchEvent> sharedEvents;
  final List<AuthoredTouchPlantWindow> sharedPlantWindows;
  final Map<AuthoredTouchContinuation, AuthoredTouchBranch> branches;

  const AuthoredTouchSample({
    required this.schemaVersion,
    required this.id,
    required this.kind,
    required this.provenance,
    required this.duration,
    required this.sharedUntil,
    required this.playbackRate,
    required this.contextBounds,
    required this.players,
    required this.sharedMotion,
    required this.sharedEvents,
    required this.sharedPlantWindows,
    required this.branches,
  });

  factory AuthoredTouchSample.fromJsonString(String source) =>
      AuthoredTouchSample.fromJson(
        jsonDecode(source)! as Map<String, Object?>,
      );

  factory AuthoredTouchSample.fromJson(Map<String, Object?> json) {
    final branchJson = json['continuations']! as Map<String, Object?>;
    final sample = AuthoredTouchSample(
      schemaVersion: json['schemaVersion']! as int,
      id: json['id']! as String,
      kind: json['kind']! as String,
      provenance: AuthoredTouchProvenance.fromJson(
        json['source']! as Map<String, Object?>,
      ),
      duration: (json['duration'] as num).toDouble(),
      sharedUntil: (json['sharedUntil'] as num).toDouble(),
      playbackRate: (json['playbackRate'] as num).toDouble(),
      contextBounds: AuthoredTouchBounds.fromJson(
        json['contextBounds']! as Map<String, Object?>,
      ),
      players: (json['players']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(AuthoredTouchPlayer.fromJson)
          .toList(growable: false),
      sharedMotion: AuthoredTouchMotion.fromJson(
        json['sharedMotion']! as Map<String, Object?>,
      ),
      sharedEvents: (json['sharedEvents']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(AuthoredTouchEvent.fromJson)
          .toList(growable: false),
      sharedPlantWindows: (json['sharedPlantWindows']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(AuthoredTouchPlantWindow.fromJson)
          .toList(growable: false),
      branches: <AuthoredTouchContinuation, AuthoredTouchBranch>{
        for (final continuation in AuthoredTouchContinuation.values)
          continuation: AuthoredTouchBranch.fromJson(
            continuation,
            branchJson[continuation.name]! as Map<String, Object?>,
          ),
      },
    );
    final errors = sample.validationErrors();
    if (errors.isNotEmpty) {
      throw FormatException(
          'Invalid authored touch sample: ${errors.join('; ')}');
    }
    return sample;
  }

  AuthoredTouchPlayer player(String id) =>
      players.firstWhere((player) => player.id == id);

  AuthoredTouchFrame sampleAt(
    double requestedTime,
    AuthoredTouchContinuation continuation,
  ) {
    final time = requestedTime.clamp(0.0, duration);
    final branch = branches[continuation]!;
    final motion = time <= sharedUntil ? sharedMotion : branch.motion;
    return AuthoredTouchFrame(
      time: time,
      continuation: continuation,
      players: <String, AuthoredTouchPose>{
        for (final player in players) player.id: motion.poseAt(player.id, time),
      },
      ball: motion.ballAt(time),
      phase: time <= sharedUntil ? _sharedPhaseAt(time) : branch.phaseAt(time),
      possessionPlayerId: possessionAt(time, continuation),
    );
  }

  List<AuthoredTouchEvent> eventsFor(
    AuthoredTouchContinuation continuation,
  ) =>
      <AuthoredTouchEvent>[
        ...sharedEvents,
        ...branches[continuation]!.events,
      ]..sort((a, b) => a.time.compareTo(b.time));

  AuthoredTouchEvent? eventFor(
    AuthoredTouchContinuation continuation,
    AuthoredTouchEventType type,
  ) {
    for (final event in eventsFor(continuation)) {
      if (event.type == type) return event;
    }
    return null;
  }

  List<AuthoredTouchBallKeyframe> ballKeyframesFor(
    AuthoredTouchContinuation continuation,
  ) =>
      <AuthoredTouchBallKeyframe>[
        ...sharedMotion.ball,
        ...branches[continuation]!.motion.ball.skip(1),
      ];

  /// Samples the declared ball track without duplicating painter coordinates.
  /// Exact endpoints are included even when they fall between asset keyframes.
  List<AuthoredTouchPoint> ballPathBetween(
    AuthoredTouchContinuation continuation, {
    required double start,
    required double end,
  }) {
    final from = start.clamp(0.0, duration);
    final to = end.clamp(from, duration);
    final points = <AuthoredTouchPoint>[
      sampleAt(from, continuation).ball.point,
      for (final keyframe in ballKeyframesFor(continuation))
        if (keyframe.time > from + 1e-9 && keyframe.time < to - 1e-9)
          keyframe.point,
      sampleAt(to, continuation).ball.point,
    ];
    return <AuthoredTouchPoint>[
      for (var index = 0; index < points.length; index++)
        if (index == 0 || points[index].distanceTo(points[index - 1]) > 1e-9)
          points[index],
    ];
  }

  String? possessionAt(
    double requestedTime,
    AuthoredTouchContinuation continuation,
  ) {
    final time = requestedTime.clamp(0.0, duration);
    String? possession = 'passer';
    for (final event in eventsFor(continuation)) {
      if (event.time > time + 1e-9) break;
      switch (event.type) {
        case AuthoredTouchEventType.initialPass:
        case AuthoredTouchEventType.forwardPass:
          possession = null;
        case AuthoredTouchEventType.firstTouch:
        case AuthoredTouchEventType.carryTouch:
        case AuthoredTouchEventType.receive:
        case AuthoredTouchEventType.steal:
        case AuthoredTouchEventType.defenderCarry:
          possession = event.actorId;
      }
    }
    return possession;
  }

  List<String> validationErrors() {
    final errors = <String>[];
    if (schemaVersion != 1) errors.add('schemaVersion must be 1');
    if (kind != 'manually-authored-educational-reconstruction' ||
        provenance.capturedTracking ||
        provenance.aiMeasurement ||
        provenance.coachCertified ||
        !provenance.fictionalPlayers ||
        provenance.method.trim().isEmpty) {
      errors.add('authored provenance declaration is invalid');
    }
    if (duration <= 0 || sharedUntil <= 0 || sharedUntil >= duration) {
      errors.add('timeline bounds are invalid');
    }
    if (playbackRate <= 0 || playbackRate > 1) {
      errors.add('playbackRate must be in (0, 1]');
    }
    final ids = players.map((player) => player.id).toSet();
    if (players.length != 5 || ids.length != players.length) {
      errors.add('exactly five unique players are required');
    }
    _validateMotion(
      errors,
      sharedMotion,
      ids,
      expectedStart: 0,
      expectedEnd: sharedUntil,
      label: 'shared',
    );
    for (final continuation in AuthoredTouchContinuation.values) {
      final branch = branches[continuation];
      if (branch == null) {
        errors.add('missing ${continuation.name} branch');
        continue;
      }
      _validateMotion(
        errors,
        branch.motion,
        ids,
        expectedStart: sharedUntil,
        expectedEnd: duration,
        label: continuation.name,
      );
      for (final id in ids) {
        final shared = sharedMotion.players[id]!.last;
        final split = branch.motion.players[id]!.first;
        if (!_samePose(shared, split, .0001)) {
          errors.add('${continuation.name}/$id is discontinuous at split');
        }
      }
      final sharedBall = sharedMotion.ball.last;
      final splitBall = branch.motion.ball.first;
      if (sharedBall.point.distanceTo(splitBall.point) > .0001 ||
          (sharedBall.rotation - splitBall.rotation).abs() > .0001) {
        errors.add('${continuation.name} ball is discontinuous at split');
      }
      _validateEvents(errors, branch.events, ids, continuation);
      _validatePlants(
        errors,
        branch.plantWindows,
        continuation,
      );
    }
    _validateEvents(errors, sharedEvents, ids, null);
    _validatePlants(errors, sharedPlantWindows, null);
    return errors;
  }

  void _validateMotion(
    List<String> errors,
    AuthoredTouchMotion motion,
    Set<String> ids, {
    required double expectedStart,
    required double expectedEnd,
    required String label,
  }) {
    if (!motion.players.keys.toSet().containsAll(ids) ||
        motion.players.length != ids.length) {
      errors.add('$label player tracks do not match roster');
    }
    for (final id in ids) {
      final frames = motion.players[id];
      if (frames == null || frames.length < 2) {
        errors.add('$label/$id needs at least two pose keyframes');
        continue;
      }
      if ((frames.first.time - expectedStart).abs() > 1e-6 ||
          (frames.last.time - expectedEnd).abs() > 1e-6) {
        errors.add('$label/$id does not cover its time range');
      }
      for (var i = 0; i < frames.length; i++) {
        final frame = frames[i];
        if (!frame.time.isFinite ||
            !frame.root.isFinite ||
            !frame.leftFoot.isFinite ||
            !frame.rightFoot.isFinite ||
            !frame.bodyFacing.isFinite) {
          errors.add('$label/$id has non-finite pose data');
        }
        if (!contextBounds.contains(frame.root, margin: .01) ||
            !contextBounds.contains(frame.leftFoot, margin: .75) ||
            !contextBounds.contains(frame.rightFoot, margin: .75)) {
          errors.add('$label/$id leaves context bounds');
        }
        if (frame.root.distanceTo(frame.leftFoot) > 1.15 ||
            frame.root.distanceTo(frame.rightFoot) > 1.15) {
          errors.add('$label/$id has an implausible leg reach');
        }
        final body = const AuthoredTouchBodyRig().solve(frame);
        if (!body.isFinite ||
            body.leftLegReach > AuthoredTouchBodyRig.maximumLegReach + 1e-6 ||
            body.rightLegReach > AuthoredTouchBodyRig.maximumLegReach + 1e-6) {
          errors.add('$label/$id cannot be solved by the authored body rig');
        }
        if (i > 0 && frame.time <= frames[i - 1].time) {
          errors.add('$label/$id keyframe times are not increasing');
        }
      }
    }
    if (motion.ball.length < 2 ||
        (motion.ball.first.time - expectedStart).abs() > 1e-6 ||
        (motion.ball.last.time - expectedEnd).abs() > 1e-6) {
      errors.add('$label ball does not cover its time range');
    }
    for (var i = 0; i < motion.ball.length; i++) {
      final frame = motion.ball[i];
      if (!frame.time.isFinite ||
          !frame.point.isFinite ||
          !frame.rotation.isFinite ||
          !contextBounds.contains(frame.point, margin: .5)) {
        errors.add('$label has invalid ball data');
      }
      if (i > 0 && frame.time <= motion.ball[i - 1].time) {
        errors.add('$label ball keyframe times are not increasing');
      }
    }
  }

  void _validateEvents(
    List<String> errors,
    List<AuthoredTouchEvent> events,
    Set<String> ids,
    AuthoredTouchContinuation? continuation,
  ) {
    final branch = continuation ?? AuthoredTouchContinuation.openSide;
    for (final event in events) {
      if (!ids.contains(event.actorId) ||
          (event.targetId != null && !ids.contains(event.targetId))) {
        errors.add('${event.id} references an unknown player');
      }
      if (!event.time.isFinite || event.time < 0 || event.time > duration) {
        errors.add('${event.id} has invalid time');
      }
      if (event.foot != null && ids.contains(event.actorId)) {
        final frame = sampleAt(event.time, branch);
        final contact = frame.players[event.actorId]!.foot(event.foot!);
        if (contact.distanceTo(frame.ball.point) > .055) {
          errors.add('${event.id} foot does not meet the ball');
        }
      }
    }
  }

  void _validatePlants(
    List<String> errors,
    List<AuthoredTouchPlantWindow> plants,
    AuthoredTouchContinuation? continuation,
  ) {
    final branch = continuation ?? AuthoredTouchContinuation.openSide;
    for (final plant in plants) {
      if (plant.start >= plant.end || !plant.point.isFinite) {
        errors.add('${plant.playerId} has invalid plant window');
        continue;
      }
      for (final time in <double>[
        plant.start,
        (plant.start + plant.end) / 2,
        plant.end,
      ]) {
        final pose = sampleAt(time, branch).players[plant.playerId];
        if (pose == null ||
            pose.foot(plant.foot).distanceTo(plant.point) > .025) {
          errors.add('${plant.playerId} planted foot slides');
          break;
        }
      }
    }
  }

  AuthoredTouchPhase _sharedPhaseAt(double time) {
    if (time >= sharedUntil - 1e-9) return AuthoredTouchPhase.firstTouch;
    AuthoredTouchEvent? initialPass;
    for (final event in sharedEvents) {
      if (event.type == AuthoredTouchEventType.initialPass) {
        initialPass = event;
        break;
      }
    }
    if (initialPass != null && time >= initialPass.time) {
      return AuthoredTouchPhase.incomingPass;
    }
    return AuthoredTouchPhase.prepare;
  }
}

AuthoredTouchPose _samplePose(
  List<AuthoredTouchPoseKeyframe> frames,
  double time,
) {
  if (time <= frames.first.time) return frames.first;
  if (time >= frames.last.time) return frames.last;
  final index = frames.indexWhere((frame) => frame.time >= time);
  final a = frames[index - 1];
  final b = frames[index];
  if ((time - a.time).abs() < 1e-9) return a;
  if ((b.time - time).abs() < 1e-9) return b;
  final raw = (time - a.time) / (b.time - a.time);
  final t = raw * raw * (3 - 2 * raw);
  return AuthoredTouchPose(
    root: AuthoredTouchPoint.lerp(a.root, b.root, t),
    bodyFacing: _lerpAngle(a.bodyFacing, b.bodyFacing, t),
    leftFoot: _samePoint(a.leftFoot, b.leftFoot)
        ? a.leftFoot
        : AuthoredTouchPoint.lerp(a.leftFoot, b.leftFoot, t),
    rightFoot: _samePoint(a.rightFoot, b.rightFoot)
        ? a.rightFoot
        : AuthoredTouchPoint.lerp(a.rightFoot, b.rightFoot, t),
  );
}

AuthoredTouchBallState _sampleBall(
  List<AuthoredTouchBallKeyframe> frames,
  double time,
) {
  if (time <= frames.first.time) {
    return AuthoredTouchBallState(frames.first.point, frames.first.rotation);
  }
  if (time >= frames.last.time) {
    return AuthoredTouchBallState(frames.last.point, frames.last.rotation);
  }
  final index = frames.indexWhere((frame) => frame.time >= time);
  final a = frames[index - 1];
  final b = frames[index];
  if ((time - a.time).abs() < 1e-9) {
    return AuthoredTouchBallState(a.point, a.rotation);
  }
  if ((b.time - time).abs() < 1e-9) {
    return AuthoredTouchBallState(b.point, b.rotation);
  }
  // A rolling ball must not brake to zero at every authored waypoint.
  // Velocity changes at explicit contacts represent kick impulses.
  final t = (time - a.time) / (b.time - a.time);
  return AuthoredTouchBallState(
    AuthoredTouchPoint.lerp(a.point, b.point, t),
    a.rotation + (b.rotation - a.rotation) * t,
  );
}

double _lerpAngle(double a, double b, double t) {
  final delta = math.atan2(math.sin(b - a), math.cos(b - a));
  return a + delta * t;
}

bool _samePoint(AuthoredTouchPoint a, AuthoredTouchPoint b,
        [double e = 1e-9]) =>
    a.distanceTo(b) <= e;

bool _samePose(
  AuthoredTouchPose a,
  AuthoredTouchPose b,
  double epsilon,
) =>
    a.root.distanceTo(b.root) <= epsilon &&
    a.leftFoot.distanceTo(b.leftFoot) <= epsilon &&
    a.rightFoot.distanceTo(b.rightFoot) <= epsilon &&
    math
            .atan2(
              math.sin(a.bodyFacing - b.bodyFacing),
              math.cos(a.bodyFacing - b.bodyFacing),
            )
            .abs() <=
        epsilon;
