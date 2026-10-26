import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

enum RealMatchReplayPhase { prepare, spacePass, advance, recovery, outcome }

enum RealMatchReplayCategory {
  transition,
  buildUp,
  pressure,
  switchPlay,
  penetration,
  combination,
  wideAttack,
  turnover,
}

enum RealMatchReplayStepKind {
  observe,
  carry,
  pass,
  receive,
  run,
  pressure,
  outcome,
}

enum RealMatchReplayOutcome { shot, kept, lost, end }

class RealMatchReplayPoint {
  final double x;
  final double y;
  final double z;

  const RealMatchReplayPoint(this.x, this.y, [this.z = 0]);

  static RealMatchReplayPoint lerp(
    RealMatchReplayPoint a,
    RealMatchReplayPoint b,
    double t,
  ) =>
      RealMatchReplayPoint(
        a.x + (b.x - a.x) * t,
        a.y + (b.y - a.y) * t,
        a.z + (b.z - a.z) * t,
      );
}

class RealMatchReplayPlayer {
  final int id;
  final int number;
  final String name;
  final bool home;
  final bool keeper;

  const RealMatchReplayPlayer({
    required this.id,
    required this.number,
    required this.name,
    required this.home,
    required this.keeper,
  });
}

class RealMatchReplayMatch {
  final int id;
  final String date;
  final String home;
  final String away;

  const RealMatchReplayMatch({
    required this.id,
    required this.date,
    required this.home,
    required this.away,
  });
}

class RealMatchReplayEvent {
  final String id;
  final int playerId;
  final String playerName;
  final int? targetedPlayerId;
  final String? targetedPlayerName;
  final String endType;
  final String? passOutcome;
  final double start;
  final double end;

  const RealMatchReplayEvent({
    required this.id,
    required this.playerId,
    required this.playerName,
    required this.targetedPlayerId,
    required this.targetedPlayerName,
    required this.endType,
    required this.passOutcome,
    required this.start,
    required this.end,
  });
}

class RealMatchReplayStep {
  final double time;
  final RealMatchReplayStepKind kind;
  final int actorId;
  final int? targetId;
  final int? secondaryId;
  final String? eventId;
  final double? end;
  final String? runType;

  const RealMatchReplayStep({
    required this.time,
    required this.kind,
    required this.actorId,
    this.targetId,
    this.secondaryId,
    this.eventId,
    this.end,
    this.runType,
  });
}

class RealMatchReplayCamera {
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  const RealMatchReplayCamera({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  double get width => maxX - minX;
  double get height => maxY - minY;
}

class RealMatchReplayScene {
  final String id;
  final RealMatchReplayCategory category;
  final String titleKey;
  final String focusKey;
  final String homeColor;
  final String awayColor;
  final String homeNumberColor;
  final String awayNumberColor;
  final int attackDirection;
  final int focusPlayerId;
  final RealMatchReplayCamera camera;
  final List<RealMatchReplayStep> steps;
  final RealMatchReplayOutcome outcome;

  const RealMatchReplayScene({
    required this.id,
    required this.category,
    required this.titleKey,
    required this.focusKey,
    required this.homeColor,
    required this.awayColor,
    required this.homeNumberColor,
    required this.awayNumberColor,
    required this.attackDirection,
    required this.focusPlayerId,
    required this.camera,
    required this.steps,
    required this.outcome,
  });

  RealMatchReplayStep stepAt(double time) {
    var selected = steps.first;
    for (final step in steps) {
      if (step.time > time) break;
      selected = step;
    }
    return selected;
  }
}

class RealMatchReplayCatalogScene {
  final String id;
  final String asset;
  final RealMatchReplayCategory category;
  final String titleKey;
  final String focusKey;
  final int matchId;
  final String date;
  final String home;
  final String away;
  final double startClock;
  final double duration;
  final bool hasPose;

  const RealMatchReplayCatalogScene({
    required this.id,
    required this.asset,
    required this.category,
    required this.titleKey,
    required this.focusKey,
    required this.matchId,
    required this.date,
    required this.home,
    required this.away,
    required this.startClock,
    required this.duration,
    required this.hasPose,
  });
}

class RealMatchReplayCatalog {
  final int version;
  final String sourceCommit;
  final List<RealMatchReplayCatalogScene> scenes;

  const RealMatchReplayCatalog({
    required this.version,
    required this.sourceCommit,
    required this.scenes,
  });

  factory RealMatchReplayCatalog.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Replay catalog must be a JSON object.');
    }
    return RealMatchReplayCatalog.fromJson(decoded);
  }

  factory RealMatchReplayCatalog.fromJson(Map<String, dynamic> json) {
    final version = _integer(json, 'version');
    final sourceCommit = _string(json, 'sourceCommit');
    final scenes = _list(json, 'scenes').map((value) {
      final item = _asMap(value, 'catalog scene');
      return RealMatchReplayCatalogScene(
        id: _string(item, 'id'),
        asset: _string(item, 'asset'),
        category: _enumByName(
          RealMatchReplayCategory.values,
          _string(item, 'category'),
          'category',
        ),
        titleKey: _string(item, 'titleKey'),
        focusKey: _string(item, 'focusKey'),
        matchId: _integer(item, 'matchId'),
        date: _string(item, 'date'),
        home: _string(item, 'home'),
        away: _string(item, 'away'),
        startClock: _number(item, 'startClock'),
        duration: _number(item, 'duration'),
        hasPose: _boolean(item, 'hasPose'),
      );
    }).toList(growable: false);
    if (version != 1 || sourceCommit.isEmpty || scenes.isEmpty) {
      throw const FormatException('Unsupported or empty replay catalog.');
    }
    final ids = <String>{};
    for (final scene in scenes) {
      if (scene.id.isEmpty ||
          scene.asset.isEmpty ||
          scene.titleKey.isEmpty ||
          scene.focusKey.isEmpty ||
          scene.home.isEmpty ||
          scene.away.isEmpty ||
          !_finitePositive(scene.duration) ||
          !_finiteNonNegative(scene.startClock) ||
          !ids.add(scene.id)) {
        throw const FormatException(
            'Invalid or duplicate replay catalog scene.');
      }
    }
    return RealMatchReplayCatalog(
      version: version,
      sourceCommit: sourceCommit,
      scenes: scenes,
    );
  }

  factory RealMatchReplayCatalog.single(RealMatchReplayData data) =>
      RealMatchReplayCatalog(
        version: 1,
        sourceCommit: data.sourceCommit,
        scenes: <RealMatchReplayCatalogScene>[
          RealMatchReplayCatalogScene(
            id: data.scene.id,
            asset: '',
            category: data.scene.category,
            titleKey: data.scene.titleKey,
            focusKey: data.scene.focusKey,
            matchId: data.match.id,
            date: data.match.date,
            home: data.match.home,
            away: data.match.away,
            startClock: data.startClock,
            duration: data.duration,
            hasPose: data.hasRecordedPose,
          ),
        ],
      );
}

class RealMatchReplayPose {
  final List<RealMatchReplayPoint> joints;

  const RealMatchReplayPose(this.joints);
}

class RealMatchReplaySample {
  final double time;
  final double sourceFrame;
  final List<RealMatchReplayPoint> players;
  final RealMatchReplayPoint ball;

  const RealMatchReplaySample({
    required this.time,
    required this.sourceFrame,
    required this.players,
    required this.ball,
  });
}

class RealMatchReplayData {
  // Retained for compatibility with source-integrity tests for the original
  // clip. Runtime validation is deliberately generic.
  static const int expectedPlayerCount = 22;
  static const int expectedFrameCount = 309;
  static const int expectedPoseCount = 155;

  final int fps;
  final int poseStep;
  final double duration;
  final double startClock;
  final double pitchLength;
  final double pitchWidth;
  final RealMatchReplayMatch match;
  final List<RealMatchReplayPlayer> players;
  final List<String> joints;
  final List<Int32List> frames;
  final List<List<Int16List?>> poses;
  final List<RealMatchReplayEvent> events;
  final String sourceCommit;
  final RealMatchReplayScene scene;

  late final Map<int, int> _playerIndexById = <int, int>{
    for (var index = 0; index < players.length; index++)
      players[index].id: index,
  };
  late final RealMatchReplayMotionModel motion =
      RealMatchReplayMotionModel._(this);

  RealMatchReplayData._({
    required this.fps,
    required this.poseStep,
    required this.duration,
    required this.startClock,
    required this.pitchLength,
    required this.pitchWidth,
    required this.match,
    required this.players,
    required this.joints,
    required this.frames,
    required this.poses,
    required this.events,
    required this.sourceCommit,
    required this.scene,
  });

  factory RealMatchReplayData.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Replay payload must be a JSON object.');
    }
    return RealMatchReplayData.fromJson(decoded);
  }

  factory RealMatchReplayData.fromJson(Map<String, dynamic> json) {
    final playerJson = _list(json, 'players');
    final jointJson = _list(json, 'joints');
    final frameJson = _list(json, 'frames');
    final poseJson = _list(json, 'poses');
    final eventJson = _list(json, 'events');
    final pitch = _list(json, 'pitch');
    final matchJson = _map(json, 'match');

    final players = playerJson.map((value) {
      final item = _asMap(value, 'player');
      return RealMatchReplayPlayer(
        id: _integer(item, 'id'),
        number: _integer(item, 'number'),
        name: _string(item, 'name'),
        home: _boolean(item, 'home'),
        keeper: _boolean(item, 'keeper'),
      );
    }).toList(growable: false);
    final joints = jointJson
        .map((value) => value is String
            ? value
            : throw const FormatException('Joint names must be strings.'))
        .toList(growable: false);
    final frameWidth = players.length * 2 + 3;
    final frames = frameJson.map((value) {
      final row = _asList(value, 'frame');
      if (row.length != frameWidth) {
        throw FormatException(
          'Each replay frame must contain $frameWidth integers.',
        );
      }
      return Int32List.fromList(
        row.map((entry) => _asInteger(entry, 'frame value')).toList(),
      );
    }).toList(growable: false);
    final poseWidth = joints.length * 3;
    final poses = poseJson.map((value) {
      final row = _asList(value, 'pose frame');
      if (row.length != players.length) {
        throw const FormatException(
          'Each pose frame must match the active roster.',
        );
      }
      return row.map<Int16List?>((entry) {
        if (entry == null) return null;
        final values = _asList(entry, 'player pose');
        if (values.length != poseWidth) {
          throw FormatException(
            'Each player pose must contain $poseWidth integers.',
          );
        }
        return Int16List.fromList(
          values.map((item) => _asInteger(item, 'pose value')).toList(),
        );
      }).toList(growable: false);
    }).toList(growable: false);
    final events = eventJson.map((value) {
      final item = _asMap(value, 'event');
      final targetedId = item['player_targeted_id'];
      final targetedName = item['player_targeted_name'];
      final passOutcome = item['pass_outcome'];
      return RealMatchReplayEvent(
        id: _string(item, 'event_id'),
        playerId: _integerLike(item['player_id'], 'player_id'),
        playerName: _string(item, 'player_name'),
        targetedPlayerId: targetedId == null || targetedId == ''
            ? null
            : _integerLike(targetedId, 'player_targeted_id'),
        targetedPlayerName:
            targetedName == null || targetedName == '' ? null : '$targetedName',
        endType: _string(item, 'end_type'),
        passOutcome:
            passOutcome == null || passOutcome == '' ? null : '$passOutcome',
        start: _number(item, 'start'),
        end: _number(item, 'end'),
      );
    }).toList(growable: false);

    final duration = _number(json, 'duration');
    final sceneJson = json['scene'];
    final scene = sceneJson == null
        ? _legacyScene(duration)
        : _parseScene(_asMap(sceneJson, 'scene'));
    final data = RealMatchReplayData._(
      fps: _integer(json, 'fps'),
      poseStep: _integer(json, 'poseStep'),
      duration: duration,
      startClock: _number(json, 'startClock'),
      pitchLength: _asNumber(pitch.elementAtOrNull(0), 'pitch length'),
      pitchWidth: _asNumber(pitch.elementAtOrNull(1), 'pitch width'),
      match: RealMatchReplayMatch(
        id: _integer(matchJson, 'id'),
        date: _string(matchJson, 'date'),
        home: _string(matchJson, 'home'),
        away: _string(matchJson, 'away'),
      ),
      players: players,
      joints: joints,
      frames: frames,
      poses: poses,
      events: events,
      sourceCommit: _string(json, 'sourceCommit'),
      scene: scene,
    );
    data._validate();
    return data;
  }

  bool get hasRecordedPose =>
      poses.any((row) => row.any((pose) => pose != null));

  bool hasRecordedPoseFor(int playerId) {
    final index = playerIndex(playerId);
    return poses.any((row) => row[index] != null);
  }

  int playerIndex(int playerId) {
    final index = _playerIndexById[playerId];
    if (index == null) {
      throw ArgumentError.value(playerId, 'playerId', 'Unknown replay player');
    }
    return index;
  }

  RealMatchReplayPlayer player(int playerId) => players[playerIndex(playerId)];

  RealMatchReplayStep stepAt(double time) =>
      scene.stepAt(time.clamp(0, duration));

  RealMatchReplayPhase phaseAt(double time) {
    final step = stepAt(time);
    return switch (step.kind) {
      RealMatchReplayStepKind.observe => RealMatchReplayPhase.prepare,
      RealMatchReplayStepKind.pass ||
      RealMatchReplayStepKind.receive =>
        RealMatchReplayPhase.spacePass,
      RealMatchReplayStepKind.carry ||
      RealMatchReplayStepKind.run =>
        RealMatchReplayPhase.advance,
      RealMatchReplayStepKind.pressure => RealMatchReplayPhase.recovery,
      RealMatchReplayStepKind.outcome => RealMatchReplayPhase.outcome,
    };
  }

  RealMatchReplaySample sample(double time) =>
      _sample(time, smoothPlayers: false);

  RealMatchReplaySample renderSample(double time) =>
      _sample(time, smoothPlayers: true);

  RealMatchReplaySample _sample(double time, {required bool smoothPlayers}) {
    final clamped = time.clamp(0.0, duration);
    final sourceFrame = (clamped * fps).clamp(0.0, frames.length - 1.0);
    final lower = sourceFrame.floor();
    final upper = (lower + 1).clamp(0, frames.length - 1);
    final fraction = sourceFrame - lower;
    final a = frames[lower];
    final b = frames[upper];
    double linear(int index) =>
        (a[index] + (b[index] - a[index]) * fraction) / 100;
    double smooth(int index) {
      if (!smoothPlayers || lower == upper || fraction == 0) {
        return linear(index);
      }
      final previous = frames[math.max(0, lower - 1)][index].toDouble();
      final next =
          frames[math.min(frames.length - 1, upper + 1)][index].toDouble();
      final p0 = a[index].toDouble();
      final p1 = b[index].toDouble();
      final m0 = (p1 - previous) / 2;
      final m1 = (next - p0) / 2;
      final t2 = fraction * fraction;
      final t3 = t2 * fraction;
      final value = (2 * t3 - 3 * t2 + 1) * p0 +
          (t3 - 2 * t2 + fraction) * m0 +
          (-2 * t3 + 3 * t2) * p1 +
          (t3 - t2) * m1;
      return value.clamp(math.min(p0, p1), math.max(p0, p1)) / 100;
    }

    return RealMatchReplaySample(
      time: clamped,
      sourceFrame: sourceFrame,
      players: List<RealMatchReplayPoint>.generate(
        players.length,
        (index) => RealMatchReplayPoint(
          smooth(index * 2),
          smooth(index * 2 + 1),
        ),
        growable: false,
      ),
      // The recorded ball path remains linear; renderer smoothing never snaps
      // it to a player or invents a contact.
      ball: RealMatchReplayPoint(
        linear(players.length * 2),
        linear(players.length * 2 + 1),
        linear(players.length * 2 + 2),
      ),
    );
  }

  RealMatchReplayPose? poseAt(double time, int playerIndex) {
    if (playerIndex < 0 || playerIndex >= players.length) {
      throw RangeError.index(playerIndex, players, 'playerIndex');
    }
    if (poses.isEmpty) return null;
    final clamped = time.clamp(0.0, duration);
    final poseFrame = (clamped * fps / poseStep).clamp(0.0, poses.length - 1.0);
    final lower = poseFrame.floor();
    final upper = (lower + 1).clamp(0, poses.length - 1);
    final fraction = poseFrame - lower;
    final a = poses[lower][playerIndex];
    if (fraction == 0 || lower == upper) {
      return a == null ? null : _decodePose(a);
    }
    final b = poses[upper][playerIndex];
    if (a == null || b == null) return null;
    return RealMatchReplayPose(
      List<RealMatchReplayPoint>.generate(joints.length, (index) {
        final offset = index * 3;
        return RealMatchReplayPoint(
          (a[offset] + (b[offset] - a[offset]) * fraction) / 100,
          (a[offset + 1] + (b[offset + 1] - a[offset + 1]) * fraction) / 100,
          (a[offset + 2] + (b[offset + 2] - a[offset + 2]) * fraction) / 100,
        );
      }, growable: false),
    );
  }

  RealMatchReplayPose _decodePose(Int16List values) => RealMatchReplayPose(
        List<RealMatchReplayPoint>.generate(joints.length, (index) {
          final offset = index * 3;
          return RealMatchReplayPoint(
            values[offset] / 100,
            values[offset + 1] / 100,
            values[offset + 2] / 100,
          );
        }, growable: false),
      );

  void _validate() {
    if (fps <= 0 ||
        poseStep <= 0 ||
        !_finitePositive(duration) ||
        !_finiteNonNegative(startClock) ||
        !_finitePositive(pitchLength) ||
        !_finitePositive(pitchWidth) ||
        match.date.isEmpty ||
        match.home.isEmpty ||
        match.away.isEmpty ||
        players.isEmpty ||
        frames.isEmpty ||
        sourceCommit.isEmpty) {
      throw const FormatException('Invalid replay metadata.');
    }
    final lastFrameTime = (frames.length - 1) / fps;
    if ((lastFrameTime - duration).abs() > 1 / fps + 1e-6) {
      throw const FormatException('Replay duration does not match its frames.');
    }
    final ids = <int>{};
    for (final player in players) {
      if (!ids.add(player.id) || player.number < 0 || player.name.isEmpty) {
        throw const FormatException('Invalid or duplicate replay player.');
      }
    }
    if (joints.toSet().length != joints.length ||
        (poses.isNotEmpty && joints.isEmpty)) {
      throw const FormatException('Invalid replay joint names.');
    }
    final coordinateLimit = math.max(pitchLength, pitchWidth) * 2 * 100;
    for (final frame in frames) {
      for (var index = 0; index < players.length * 2; index++) {
        if (frame[index].abs() > coordinateLimit) {
          throw const FormatException(
              'Replay player coordinate is out of range.');
        }
      }
      final ballZ = frame.last;
      if (ballZ < -500 || ballZ > 10000) {
        throw const FormatException('Replay ball height is out of range.');
      }
    }
    final eventIds = <String>{};
    for (final event in events) {
      if (event.id.isEmpty ||
          !eventIds.add(event.id) ||
          !ids.contains(event.playerId) ||
          (event.targetedPlayerId != null &&
              !ids.contains(event.targetedPlayerId)) ||
          !event.start.isFinite ||
          event.start < -60 ||
          event.start > duration + 60 ||
          !event.end.isFinite ||
          event.end < event.start ||
          event.end < 0 ||
          event.end > duration + 60) {
        throw const FormatException('Invalid or duplicate replay event.');
      }
    }
    if (!ids.contains(scene.focusPlayerId) ||
        scene.attackDirection.abs() != 1 ||
        scene.id.isEmpty ||
        scene.titleKey.isEmpty ||
        scene.focusKey.isEmpty ||
        !_validColor(scene.homeColor) ||
        !_validColor(scene.awayColor) ||
        !_validColor(scene.homeNumberColor) ||
        !_validColor(scene.awayNumberColor) ||
        !scene.camera.minX.isFinite ||
        !scene.camera.maxX.isFinite ||
        !scene.camera.minY.isFinite ||
        !scene.camera.maxY.isFinite ||
        scene.camera.width <= 0 ||
        scene.camera.height <= 0 ||
        scene.camera.minX < -pitchLength ||
        scene.camera.maxX > pitchLength ||
        scene.camera.minY < -pitchWidth ||
        scene.camera.maxY > pitchWidth ||
        scene.steps.isEmpty ||
        scene.steps.first.time != 0 ||
        scene.steps.last.time >= duration) {
      throw const FormatException('Invalid replay scene metadata.');
    }
    var previous = -1.0;
    for (final step in scene.steps) {
      if (!step.time.isFinite ||
          step.time <= previous ||
          step.time < 0 ||
          step.time >= duration ||
          !ids.contains(step.actorId) ||
          (step.targetId != null && !ids.contains(step.targetId)) ||
          (step.secondaryId != null && !ids.contains(step.secondaryId)) ||
          (step.end != null &&
              (!step.end!.isFinite ||
                  step.end! < step.time ||
                  step.end! > duration)) ||
          (step.eventId != null && !eventIds.contains(step.eventId))) {
        throw const FormatException('Invalid replay scene step.');
      }
      previous = step.time;
    }
  }
}

class RealMatchReplayMotionState {
  final RealMatchReplayPoint position;
  final double speed;
  final double heading;
  final double gaitPhase;

  const RealMatchReplayMotionState({
    required this.position,
    required this.speed,
    required this.heading,
    required this.gaitPhase,
  });
}

/// Deterministic motion derived only from the recorded ground trajectory.
/// Gait phase is integrated by travelled distance, so playback speed changes
/// cannot reset limbs or introduce phase jumps.
class RealMatchReplayMotionModel {
  final RealMatchReplayData data;
  final List<List<double>> _speeds;
  final List<List<double>> _headings;
  final List<List<double>> _phases;

  RealMatchReplayMotionModel._(this.data)
      : _speeds = List<List<double>>.generate(
          data.players.length,
          (_) => List<double>.filled(data.frames.length, 0),
          growable: false,
        ),
        _headings = List<List<double>>.generate(
          data.players.length,
          (_) => List<double>.filled(data.frames.length, 0),
          growable: false,
        ),
        _phases = List<List<double>>.generate(
          data.players.length,
          (_) => List<double>.filled(data.frames.length, 0),
          growable: false,
        ) {
    _precompute();
  }

  void _precompute() {
    final dt = 1 / data.fps;
    for (var player = 0; player < data.players.length; player++) {
      var heading = 0.0;
      var hasHeading = false;
      var phase = player * .73;
      for (var frame = 0; frame < data.frames.length; frame++) {
        final before = math.max(0, frame - 2);
        final after = math.min(data.frames.length - 1, frame + 2);
        final elapsed = math.max(dt, (after - before) * dt);
        final dx =
            (data.frames[after][player * 2] - data.frames[before][player * 2]) /
                100;
        final dy = (data.frames[after][player * 2 + 1] -
                data.frames[before][player * 2 + 1]) /
            100;
        final speed = math.sqrt(dx * dx + dy * dy) / elapsed;
        if (speed > .18) {
          final target = math.atan2(dy, dx);
          if (!hasHeading) {
            heading = target;
            hasHeading = true;
          } else {
            final turnLimit = 4 * dt;
            final delta =
                _shortestAngle(target - heading).clamp(-turnLimit, turnLimit);
            heading = _shortestAngle(heading + delta);
          }
        }
        if (frame > 0 && speed > .18) {
          final stepX = (data.frames[frame][player * 2] -
                  data.frames[frame - 1][player * 2]) /
              100;
          final stepY = (data.frames[frame][player * 2 + 1] -
                  data.frames[frame - 1][player * 2 + 1]) /
              100;
          final distance = math.sqrt(stepX * stepX + stepY * stepY);
          // A full cycle includes both footfalls. Sprinting should be roughly
          // two cycles per second rather than many tiny, rapid steps.
          final strideLength = 1.2 + math.min(7.5, speed) * .36;
          phase += distance / strideLength * math.pi * 2;
        }
        _speeds[player][frame] = speed;
        _headings[player][frame] = heading;
        _phases[player][frame] = phase;
      }
    }
  }

  RealMatchReplayMotionState stateAt(double time, int playerIndex) {
    if (playerIndex < 0 || playerIndex >= data.players.length) {
      throw RangeError.index(playerIndex, data.players, 'playerIndex');
    }
    final sample = data.renderSample(time);
    final frame = sample.sourceFrame;
    final lower = frame.floor();
    final upper = (lower + 1).clamp(0, data.frames.length - 1);
    final fraction = frame - lower;
    final aHeading = _headings[playerIndex][lower];
    final heading = _shortestAngle(
      aHeading +
          _shortestAngle(_headings[playerIndex][upper] - aHeading) * fraction,
    );
    return RealMatchReplayMotionState(
      position: sample.players[playerIndex],
      speed: _lerp(
          _speeds[playerIndex][lower], _speeds[playerIndex][upper], fraction),
      heading: heading,
      gaitPhase: _lerp(
          _phases[playerIndex][lower], _phases[playerIndex][upper], fraction),
    );
  }

  RealMatchReplayPose simplifiedPoseAt(double time, int playerIndex) {
    final state = stateAt(time, playerIndex);
    final forward = RealMatchReplayPoint(
      math.cos(state.heading),
      math.sin(state.heading),
    );
    final side = RealMatchReplayPoint(-forward.y, forward.x);
    final motion = (state.speed / 5.5).clamp(0.0, 1.0);
    final leftSwing = math.sin(state.gaitPhase) * motion;
    final rightSwing = math.sin(state.gaitPhase + math.pi) * motion;
    final leftLift = math.max(0.0, math.sin(state.gaitPhase)) * motion;
    final rightLift =
        math.max(0.0, math.sin(state.gaitPhase + math.pi)) * motion;
    final lean = math.min(.16, state.speed * .018);
    RealMatchReplayPoint make(double lateral, double along, double z) =>
        RealMatchReplayPoint(
          side.x * lateral + forward.x * along,
          side.y * lateral + forward.y * along,
          z,
        );
    final fallback = <String, RealMatchReplayPoint>{
      'nose': make(0, .1 + lean, 1.67),
      'neck': make(0, lean, 1.45),
      'lShoulder': make(.21, lean, 1.43),
      'rShoulder': make(-.21, lean, 1.43),
      'lElbow': make(.28, -.20 * leftSwing + lean, 1.16),
      'rElbow': make(-.28, -.20 * rightSwing + lean, 1.16),
      'lWrist': make(.26, -.36 * leftSwing + lean, .92),
      'rWrist': make(-.26, -.36 * rightSwing + lean, .92),
      'lHip': make(.13, 0, .88),
      'rHip': make(-.13, 0, .88),
      'lKnee': make(.13, .32 * leftSwing, .48 + .18 * leftLift),
      'rKnee': make(-.13, .32 * rightSwing, .48 + .18 * rightLift),
      'lAnkle': make(.14, .56 * leftSwing, .08 + .14 * leftLift),
      'rAnkle': make(-.14, .56 * rightSwing, .08 + .14 * rightLift),
      'lHeel': make(.14, .56 * leftSwing - .1, .035 + .12 * leftLift),
      'rHeel': make(-.14, .56 * rightSwing - .1, .035 + .12 * rightLift),
      'lBigToe': make(.14, .56 * leftSwing + .16, .03 + .08 * leftLift),
      'rBigToe': make(-.14, .56 * rightSwing + .16, .03 + .08 * rightLift),
    };
    return RealMatchReplayPose(
      data.joints
          .map((joint) => fallback[joint] ?? const RealMatchReplayPoint(0, 0))
          .toList(growable: false),
    );
  }
}

RealMatchReplayScene _parseScene(Map<String, dynamic> json) {
  final camera = _list(json, 'camera');
  if (camera.length != 4) {
    throw const FormatException('Replay camera must contain four numbers.');
  }
  final steps = _list(json, 'steps').map((value) {
    final item = _asMap(value, 'scene step');
    return RealMatchReplayStep(
      time: _number(item, 'time'),
      kind: _enumByName(
        RealMatchReplayStepKind.values,
        _string(item, 'kind'),
        'step kind',
      ),
      actorId: _integer(item, 'actorId'),
      targetId: _optionalInteger(item, 'targetId'),
      secondaryId: _optionalInteger(item, 'secondaryId'),
      eventId: _optionalString(item, 'eventId'),
      end: _optionalNumber(item, 'end'),
      runType: _optionalString(item, 'runType'),
    );
  }).toList(growable: false);
  return RealMatchReplayScene(
    id: _string(json, 'id'),
    category: _enumByName(
      RealMatchReplayCategory.values,
      _string(json, 'category'),
      'category',
    ),
    titleKey: _string(json, 'titleKey'),
    focusKey: _string(json, 'focusKey'),
    homeColor: _string(json, 'homeColor'),
    awayColor: _string(json, 'awayColor'),
    homeNumberColor: _string(json, 'homeNumberColor'),
    awayNumberColor: _string(json, 'awayNumberColor'),
    attackDirection: _integer(json, 'attackDirection'),
    focusPlayerId: _integer(json, 'focusPlayerId'),
    camera: RealMatchReplayCamera(
      minX: _asNumber(camera[0], 'camera minX'),
      maxX: _asNumber(camera[1], 'camera maxX'),
      minY: _asNumber(camera[2], 'camera minY'),
      maxY: _asNumber(camera[3], 'camera maxY'),
    ),
    steps: steps,
    outcome: _enumByName(
      RealMatchReplayOutcome.values,
      _string(json, 'outcome'),
      'outcome',
    ),
  );
}

RealMatchReplayScene _legacyScene(double duration) =>
    const RealMatchReplayScene(
      id: 'transition-wing',
      category: RealMatchReplayCategory.transition,
      titleKey: 'replaySceneTransitionWing',
      focusKey: 'replayFocusTransitionWing',
      homeColor: '#FF8000',
      awayColor: '#FFFFFF',
      homeNumberColor: '#FFFFFF',
      awayNumberColor: '#17202D',
      attackDirection: 1,
      focusPlayerId: 965698,
      camera: RealMatchReplayCamera(
        minX: -5,
        maxX: 56,
        minY: -5,
        maxY: 35,
      ),
      steps: <RealMatchReplayStep>[
        RealMatchReplayStep(
          time: 0,
          kind: RealMatchReplayStepKind.observe,
          actorId: 287934,
          targetId: 965698,
        ),
        RealMatchReplayStep(
          time: 2.42,
          kind: RealMatchReplayStepKind.pass,
          actorId: 287934,
          targetId: 965698,
          eventId: '8_870',
          end: 2.42,
        ),
        RealMatchReplayStep(
          time: 4.22,
          kind: RealMatchReplayStepKind.carry,
          actorId: 965698,
          targetId: 11897,
        ),
        RealMatchReplayStep(
          time: 8,
          kind: RealMatchReplayStepKind.pressure,
          actorId: 11897,
          targetId: 965698,
          secondaryId: 795533,
        ),
        RealMatchReplayStep(
          time: 11.22,
          kind: RealMatchReplayStepKind.outcome,
          actorId: 965698,
          targetId: 560985,
          eventId: '8_871',
        ),
      ],
      outcome: RealMatchReplayOutcome.kept,
    );

T _enumByName<T extends Enum>(List<T> values, String name, String label) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw FormatException('Unknown $label: $name.');
}

double _shortestAngle(double angle) {
  while (angle > math.pi) {
    angle -= math.pi * 2;
  }
  while (angle < -math.pi) {
    angle += math.pi * 2;
  }
  return angle;
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

bool _finitePositive(double value) => value.isFinite && value > 0;

bool _finiteNonNegative(double value) => value.isFinite && value >= 0;

bool _validColor(String value) =>
    RegExp(r'^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$').hasMatch(value);

List<dynamic> _list(Map<String, dynamic> json, String key) =>
    _asList(json[key], key);

Map<String, dynamic> _map(Map<String, dynamic> json, String key) =>
    _asMap(json[key], key);

List<dynamic> _asList(Object? value, String label) {
  if (value is List<dynamic>) return value;
  throw FormatException('$label must be a list.');
}

Map<String, dynamic> _asMap(Object? value, String label) {
  if (value is Map<String, dynamic>) return value;
  throw FormatException('$label must be an object.');
}

int _integer(Map<String, dynamic> json, String key) =>
    _asInteger(json[key], key);

int _integerLike(Object? value, String label) {
  if (value is int) return value;
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException('$label must be an integer.');
}

int _asInteger(Object? value, String label) {
  if (value is int) return value;
  throw FormatException('$label must be an integer.');
}

int? _optionalInteger(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value == null ? null : _integerLike(value, key);
}

double _number(Map<String, dynamic> json, String key) =>
    _asNumber(json[key], key);

double _asNumber(Object? value, String label) {
  if (value is num && value.toDouble().isFinite) return value.toDouble();
  throw FormatException('$label must be a finite number.');
}

double? _optionalNumber(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value == null ? null : _asNumber(value, key);
}

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw FormatException('$key must be a string.');
}

String? _optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is String) return value;
  throw FormatException('$key must be a string.');
}

bool _boolean(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is bool) return value;
  throw FormatException('$key must be a boolean.');
}
