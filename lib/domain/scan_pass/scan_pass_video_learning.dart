import 'dart:convert';

enum FootballKitPattern {
  solid,
  verticalStripes,
  halves,
  centerStripe,
  checkerboard,
}

enum VideoLearningArrowKind { pass, run, carry, shot }

class FootballKit {
  final String primary;
  final String secondary;
  final String accent;
  final String number;
  final FootballKitPattern pattern;

  const FootballKit({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.number,
    required this.pattern,
  });
}

class VideoLearningTeam {
  final String id;
  final String name;
  final FootballKit kit;

  const VideoLearningTeam({
    required this.id,
    required this.name,
    required this.kit,
  });
}

class VideoLearningPoint {
  final double x;
  final double y;

  const VideoLearningPoint(this.x, this.y);
}

class VideoLearningDiagramPlayer {
  final String id;
  final String name;
  final int number;
  final bool home;
  final VideoLearningPoint position;

  const VideoLearningDiagramPlayer({
    required this.id,
    required this.name,
    required this.number,
    required this.home,
    required this.position,
  });
}

class VideoLearningDiagramArrow {
  final VideoLearningPoint from;
  final VideoLearningPoint to;
  final VideoLearningArrowKind kind;

  const VideoLearningDiagramArrow({
    required this.from,
    required this.to,
    required this.kind,
  });
}

class VideoLearningOpenSpace {
  final double x;
  final double y;
  final double width;
  final double height;

  const VideoLearningOpenSpace({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

class VideoLearningDiagram {
  final List<VideoLearningDiagramPlayer> players;
  final VideoLearningPoint ball;
  final List<VideoLearningDiagramArrow> arrows;
  final VideoLearningOpenSpace? space;
  final List<String> focusIds;

  const VideoLearningDiagram({
    required this.players,
    required this.ball,
    required this.arrows,
    required this.space,
    this.focusIds = const <String>[],
  });
}

class VideoLearningClipRange {
  final double start;
  final double end;

  const VideoLearningClipRange({required this.start, required this.end});

  double get duration => end - start;

  double clamp(double value) => value.clamp(start, end).toDouble();

  bool contains(double value, {double tolerance = 0}) =>
      value >= start - tolerance && value <= end + tolerance;
}

class VideoLearningPhase {
  final String id;
  final String titleKey;
  final String watchKey;
  final VideoLearningClipRange range;
  final VideoLearningDiagram diagram;

  const VideoLearningPhase({
    required this.id,
    required this.titleKey,
    required this.watchKey,
    required this.range,
    required this.diagram,
  });
}

class VideoLearningScene {
  final String id;
  final String titleKey;
  final String focusKey;
  final String date;
  final VideoLearningTeam homeTeam;
  final VideoLearningTeam awayTeam;
  final String videoId;
  final String channel;
  final Uri channelUrl;
  final double sourceDuration;
  final VideoLearningClipRange clip;
  final double goalTime;
  final int goalMinute;
  final Uri reportUrl;
  final String reviewedOn;
  final String reviewMethod;
  final double timestampTolerance;
  final int attackDirection;
  final List<VideoLearningPhase> phases;

  const VideoLearningScene({
    required this.id,
    required this.titleKey,
    required this.focusKey,
    required this.date,
    required this.homeTeam,
    required this.awayTeam,
    required this.videoId,
    required this.channel,
    required this.channelUrl,
    required this.sourceDuration,
    required this.clip,
    required this.goalTime,
    required this.goalMinute,
    required this.reportUrl,
    required this.reviewedOn,
    required this.reviewMethod,
    required this.timestampTolerance,
    this.attackDirection = 1,
    required this.phases,
  });

  Uri get officialVideoUrl => officialVideoUrlAt(clip.start);

  Uri officialVideoUrlAt(double mediaTime) =>
      Uri.https('www.youtube.com', '/watch', <String, String>{
        'v': videoId,
        't': '${clip.clamp(mediaTime).floor()}s',
      });

  Set<String> get teamIds => <String>{homeTeam.id, awayTeam.id};

  VideoLearningPhase phaseAt(double mediaTime) {
    final time = clip.clamp(mediaTime);
    for (final phase in phases) {
      if (time < phase.range.end || identical(phase, phases.last)) {
        return phase;
      }
    }
    return phases.last;
  }
}

class VideoLearningCatalog {
  final int version;
  final List<VideoLearningScene> scenes;

  const VideoLearningCatalog({required this.version, required this.scenes});

  factory VideoLearningCatalog.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Video catalogue must be a JSON object.');
    }
    return VideoLearningCatalog.fromJson(decoded);
  }

  factory VideoLearningCatalog.fromJson(Map<String, dynamic> json) {
    final scenes = _list(json, 'scenes')
        .map((value) => _scene(_mapValue(value, 'scene')))
        .toList(growable: false);
    final catalog = VideoLearningCatalog(
      version: _integer(json, 'version'),
      scenes: scenes,
    );
    catalog._validate();
    return catalog;
  }

  List<VideoLearningTeam> get teams {
    final result = <VideoLearningTeam>[];
    final ids = <String>{};
    for (final scene in scenes) {
      for (final team in <VideoLearningTeam>[
        scene.homeTeam,
        scene.awayTeam,
      ]) {
        if (ids.add(team.id)) result.add(team);
      }
    }
    return List.unmodifiable(result);
  }

  List<VideoLearningScene> filtered({
    String? teamId,
    VideoLearningWatchFilter watchFilter = VideoLearningWatchFilter.all,
    required bool Function(String sceneId) isWatched,
  }) =>
      scenes.where((scene) {
        if (teamId != null && !scene.teamIds.contains(teamId)) return false;
        final watched = isWatched(scene.id);
        return switch (watchFilter) {
          VideoLearningWatchFilter.all => true,
          VideoLearningWatchFilter.watched => watched,
          VideoLearningWatchFilter.unwatched => !watched,
        };
      }).toList(growable: false);

  int? adjacentIndex({
    required String currentSceneId,
    required List<VideoLearningScene> filteredScenes,
    required int delta,
  }) {
    final index = filteredScenes.indexWhere(
      (scene) => scene.id == currentSceneId,
    );
    if (index < 0) return filteredScenes.isEmpty ? null : 0;
    final target = index + delta;
    if (target < 0 || target >= filteredScenes.length) return null;
    return target;
  }

  VideoLearningScene? nextUnseen({
    required String currentSceneId,
    required List<VideoLearningScene> filteredScenes,
    required bool Function(String sceneId) isWatched,
  }) {
    final index = filteredScenes.indexWhere(
      (scene) => scene.id == currentSceneId,
    );
    if (index < 0) return null;
    for (var next = index + 1; next < filteredScenes.length; next++) {
      if (!isWatched(filteredScenes[next].id)) return filteredScenes[next];
    }
    return null;
  }

  void _validate() {
    final ids = <String>{};
    if (version != 1 || scenes.isEmpty) {
      throw const FormatException('Invalid video catalogue metadata.');
    }
    for (final scene in scenes) {
      if (!ids.add(scene.id) ||
          !_identifier.hasMatch(scene.id) ||
          !_copyKey.hasMatch(scene.titleKey) ||
          !_copyKey.hasMatch(scene.focusKey) ||
          !_youtubeId.hasMatch(scene.videoId) ||
          scene.homeTeam.id == scene.awayTeam.id ||
          scene.channel.isEmpty ||
          !_isHttps(scene.channelUrl) ||
          !_isHttps(scene.reportUrl) ||
          scene.sourceDuration <= 0 ||
          scene.clip.start < 0 ||
          scene.clip.end > scene.sourceDuration ||
          scene.clip.duration < 3 ||
          !scene.clip.contains(
            scene.goalTime,
            tolerance: scene.timestampTolerance,
          ) ||
          scene.goalMinute < 0 ||
          scene.timestampTolerance < 0 ||
          (scene.attackDirection != 1 && scene.attackDirection != -1) ||
          scene.reviewedOn.isEmpty ||
          scene.reviewMethod.isEmpty ||
          scene.phases.length != 3) {
        throw FormatException('Invalid video scene: ${scene.id}.');
      }
      var boundary = scene.clip.start;
      final phaseIds = <String>{};
      for (final phase in scene.phases) {
        if (!phaseIds.add(phase.id) ||
            !_identifier.hasMatch(phase.id) ||
            !_copyKey.hasMatch(phase.titleKey) ||
            !_copyKey.hasMatch(phase.watchKey) ||
            (phase.range.start - boundary).abs() > .001 ||
            phase.range.duration <= 0 ||
            phase.diagram.players.length < 2 ||
            phase.diagram.players.length > 7) {
          throw FormatException('Invalid phase in ${scene.id}.');
        }
        _validateDiagram(phase.diagram, scene.id);
        boundary = phase.range.end;
      }
      if ((boundary - scene.clip.end).abs() > .001) {
        throw FormatException('Phases do not partition ${scene.id}.');
      }
    }
  }
}

enum VideoLearningWatchFilter { all, watched, unwatched }

VideoLearningScene _scene(Map<String, dynamic> json) {
  final start = _number(json, 'start');
  final end = _number(json, 'end');
  return VideoLearningScene(
    id: _string(json, 'id'),
    titleKey: _string(json, 'titleKey'),
    focusKey: _string(json, 'focusKey'),
    date: _string(json, 'date'),
    homeTeam: _team(_map(json, 'homeTeam')),
    awayTeam: _team(_map(json, 'awayTeam')),
    videoId: _string(json, 'videoId'),
    channel: _string(json, 'channel'),
    channelUrl: Uri.parse(_string(json, 'channelUrl')),
    sourceDuration: _number(json, 'sourceDuration'),
    clip: VideoLearningClipRange(start: start, end: end),
    goalTime: _number(json, 'goalTime'),
    goalMinute: _integer(json, 'goalMinute'),
    reportUrl: Uri.parse(_string(json, 'reportUrl')),
    reviewedOn: _string(json, 'reviewedOn'),
    reviewMethod: _string(json, 'reviewMethod'),
    timestampTolerance: _number(json, 'timestampTolerance'),
    attackDirection:
        json['attackDirection'] == null ? 1 : _integer(json, 'attackDirection'),
    phases: _list(json, 'phases').map((value) {
      final phase = _mapValue(value, 'phase');
      return VideoLearningPhase(
        id: _string(phase, 'id'),
        titleKey: _string(phase, 'titleKey'),
        watchKey: _string(phase, 'watchKey'),
        range: VideoLearningClipRange(
          start: _number(phase, 'start'),
          end: _number(phase, 'end'),
        ),
        diagram: _diagram(_map(phase, 'diagram')),
      );
    }).toList(growable: false),
  );
}

VideoLearningTeam _team(Map<String, dynamic> json) {
  final kit = _map(json, 'kit');
  return VideoLearningTeam(
    id: _string(json, 'id'),
    name: _string(json, 'name'),
    kit: FootballKit(
      primary: _color(kit, 'primary'),
      secondary: _color(kit, 'secondary'),
      accent: _color(kit, 'accent'),
      number: _color(kit, 'number'),
      pattern: _enumValue(
        FootballKitPattern.values,
        _string(kit, 'pattern'),
        'kit pattern',
      ),
    ),
  );
}

VideoLearningDiagram _diagram(Map<String, dynamic> json) {
  final ball = _map(json, 'ball');
  final spaceValue = json['space'];
  return VideoLearningDiagram(
    players: _list(json, 'players').map((value) {
      final player = _mapValue(value, 'diagram player');
      return VideoLearningDiagramPlayer(
        id: _string(player, 'id'),
        name: _string(player, 'name'),
        number: _integer(player, 'number'),
        home: _boolean(player, 'home'),
        position: VideoLearningPoint(
          _number(player, 'x'),
          _number(player, 'y'),
        ),
      );
    }).toList(growable: false),
    ball: VideoLearningPoint(_number(ball, 'x'), _number(ball, 'y')),
    arrows: _list(json, 'arrows').map((value) {
      final arrow = _mapValue(value, 'diagram arrow');
      final from = _pointList(arrow, 'from');
      final to = _pointList(arrow, 'to');
      return VideoLearningDiagramArrow(
        from: from,
        to: to,
        kind: _enumValue(
          VideoLearningArrowKind.values,
          _string(arrow, 'kind'),
          'arrow kind',
        ),
      );
    }).toList(growable: false),
    space: spaceValue == null
        ? null
        : () {
            final space = _mapValue(spaceValue, 'open space');
            return VideoLearningOpenSpace(
              x: _number(space, 'x'),
              y: _number(space, 'y'),
              width: _number(space, 'width'),
              height: _number(space, 'height'),
            );
          }(),
    focusIds: json['focusIds'] == null
        ? const <String>[]
        : _list(json, 'focusIds').map((value) {
            if (value is! String || value.trim().isEmpty) {
              throw const FormatException(
                'focusIds must contain player ids.',
              );
            }
            return value;
          }).toList(growable: false),
  );
}

void _validateDiagram(VideoLearningDiagram diagram, String sceneId) {
  final playerIds = <String>{};
  bool pointValid(VideoLearningPoint point) =>
      point.x >= 0 && point.x <= 1 && point.y >= 0 && point.y <= 1;
  if (!pointValid(diagram.ball) ||
      diagram.players.any(
        (player) =>
            !playerIds.add(player.id) ||
            !_identifier.hasMatch(player.id) ||
            player.name.isEmpty ||
            player.number <= 0 ||
            !pointValid(player.position),
      ) ||
      diagram.arrows.any(
        (arrow) => !pointValid(arrow.from) || !pointValid(arrow.to),
      ) ||
      diagram.focusIds.toSet().length != diagram.focusIds.length ||
      diagram.focusIds.any((id) => !playerIds.contains(id))) {
    throw FormatException('Invalid authored diagram in $sceneId.');
  }
  final space = diagram.space;
  if (space != null &&
      (space.x < 0 ||
          space.y < 0 ||
          space.width <= 0 ||
          space.height <= 0 ||
          space.x + space.width > 1 ||
          space.y + space.height > 1)) {
    throw FormatException('Invalid open space in $sceneId.');
  }
}

VideoLearningPoint _pointList(Map<String, dynamic> json, String key) {
  final value = _list(json, key);
  if (value.length != 2 || value[0] is! num || value[1] is! num) {
    throw FormatException('$key must contain two coordinates.');
  }
  return VideoLearningPoint(
    (value[0] as num).toDouble(),
    (value[1] as num).toDouble(),
  );
}

bool _isHttps(Uri uri) => uri.scheme == 'https' && uri.host.isNotEmpty;

final RegExp _identifier = RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]*$');
final RegExp _copyKey = RegExp(r'^video[A-Za-z0-9]+$');
final RegExp _youtubeId = RegExp(r'^[A-Za-z0-9_-]{11}$');
final RegExp _hexColor = RegExp(r'^#[0-9A-Fa-f]{6}$');

String _color(Map<String, dynamic> json, String key) {
  final value = _string(json, key);
  if (!_hexColor.hasMatch(value)) {
    throw FormatException('$key must be a six-digit hex color.');
  }
  return value;
}

Map<String, dynamic> _map(Map<String, dynamic> json, String key) =>
    _mapValue(json[key], key);

Map<String, dynamic> _mapValue(Object? value, String description) {
  if (value is! Map<String, dynamic>) {
    throw FormatException('$description must be an object.');
  }
  return value;
}

List<dynamic> _list(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List) throw FormatException('$key must be a list.');
  return value;
}

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value;
}

double _number(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num || !value.isFinite) {
    throw FormatException('$key must be a finite number.');
  }
  return value.toDouble();
}

int _integer(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num || value.toInt() != value) {
    throw FormatException('$key must be an integer.');
  }
  return value.toInt();
}

bool _boolean(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! bool) throw FormatException('$key must be a boolean.');
  return value;
}

T _enumValue<T extends Enum>(List<T> values, String name, String label) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw FormatException('Unknown $label: $name.');
}
