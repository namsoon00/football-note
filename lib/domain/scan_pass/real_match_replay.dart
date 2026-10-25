import 'dart:convert';
import 'dart:typed_data';

enum RealMatchReplayPhase { prepare, spacePass, advance, recovery, outcome }

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

  late final Map<int, int> _playerIndexById = <int, int>{
    for (var index = 0; index < players.length; index++)
      players[index].id: index,
  };

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
        playerId: int.parse(_string(item, 'player_id')),
        playerName: _string(item, 'player_name'),
        targetedPlayerId: targetedId == null || targetedId == ''
            ? null
            : int.parse(targetedId.toString()),
        targetedPlayerName:
            targetedName == null || targetedName == '' ? null : '$targetedName',
        endType: _string(item, 'end_type'),
        passOutcome:
            passOutcome == null || passOutcome == '' ? null : '$passOutcome',
        start: _number(item, 'start'),
        end: _number(item, 'end'),
      );
    }).toList(growable: false);

    final data = RealMatchReplayData._(
      fps: _integer(json, 'fps'),
      poseStep: _integer(json, 'poseStep'),
      duration: _number(json, 'duration'),
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
    );
    data._validateIdentity();
    return data;
  }

  int playerIndex(int playerId) {
    final index = _playerIndexById[playerId];
    if (index == null) {
      throw ArgumentError.value(playerId, 'playerId', 'Unknown replay player');
    }
    return index;
  }

  RealMatchReplayPlayer player(int playerId) => players[playerIndex(playerId)];

  RealMatchReplayPhase phaseAt(double time) {
    final clamped = time.clamp(0.0, duration);
    if (clamped < 2.42) return RealMatchReplayPhase.prepare;
    if (clamped < 4.22) return RealMatchReplayPhase.spacePass;
    if (clamped < 8) return RealMatchReplayPhase.advance;
    if (clamped < 11.22) return RealMatchReplayPhase.recovery;
    return RealMatchReplayPhase.outcome;
  }

  RealMatchReplaySample sample(double time) {
    final clamped = time.clamp(0.0, duration);
    final sourceFrame = (clamped * fps).clamp(0.0, frames.length - 1.0);
    final lower = sourceFrame.floor();
    final upper = (lower + 1).clamp(0, frames.length - 1);
    final fraction = sourceFrame - lower;
    final a = frames[lower];
    final b = frames[upper];
    double metres(int index) =>
        (a[index] + (b[index] - a[index]) * fraction) / 100;

    return RealMatchReplaySample(
      time: clamped,
      sourceFrame: sourceFrame,
      players: List<RealMatchReplayPoint>.generate(
        players.length,
        (index) => RealMatchReplayPoint(
          metres(index * 2),
          metres(index * 2 + 1),
        ),
        growable: false,
      ),
      ball: RealMatchReplayPoint(
        metres(players.length * 2),
        metres(players.length * 2 + 1),
        metres(players.length * 2 + 2),
      ),
    );
  }

  RealMatchReplayPose? poseAt(double time, int playerIndex) {
    if (playerIndex < 0 || playerIndex >= players.length) {
      throw RangeError.index(playerIndex, players, 'playerIndex');
    }
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

  void _validateIdentity() {
    if (fps != 25 ||
        poseStep != 2 ||
        duration != 12.32 ||
        startClock != 4654.48 ||
        pitchLength != 105 ||
        pitchWidth != 68 ||
        match.id != 1925299 ||
        players.length != expectedPlayerCount ||
        players.where((player) => player.home).length != 11 ||
        frames.length != expectedFrameCount ||
        poses.length != expectedPoseCount ||
        sourceCommit != '4340d274572876239c154c90bc507a9b3250a656') {
      throw const FormatException('Unexpected real-match replay identity.');
    }
  }
}

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

int _asInteger(Object? value, String label) {
  if (value is int) return value;
  throw FormatException('$label must be an integer.');
}

double _number(Map<String, dynamic> json, String key) =>
    _asNumber(json[key], key);

double _asNumber(Object? value, String label) {
  if (value is num) return value.toDouble();
  throw FormatException('$label must be numeric.');
}

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw FormatException('$key must be a string.');
}

bool _boolean(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is bool) return value;
  throw FormatException('$key must be a boolean.');
}
