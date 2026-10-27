import 'dart:convert';
import 'dart:math' as math;

import 'real_match_replay.dart';

enum SpatialLearningTheme {
  lateralSwitch,
  forwardConnection,
  pressureSupport,
  carryThenConnect,
  wideToInside,
  combination,
  turnover,
  recovery,
}

class SpatialEvidenceAnchor {
  final double time;
  final int playerId;
  final String playerName;

  const SpatialEvidenceAnchor({
    required this.time,
    required this.playerId,
    required this.playerName,
  });
}

class SpatialEvidenceMetrics {
  final double forwardMeters;
  final double lateralMeters;
  final double startWidthMeters;
  final double insideGainMeters;
  final double? pressureMeters;
  final double carryMeters;
  final double sequenceSeconds;

  const SpatialEvidenceMetrics({
    required this.forwardMeters,
    required this.lateralMeters,
    required this.startWidthMeters,
    required this.insideGainMeters,
    required this.pressureMeters,
    required this.carryMeters,
    required this.sequenceSeconds,
  });
}

class SpatialObservedDefenderGap {
  final int actorId;
  final String actorName;
  final RealMatchReplayPoint actor;
  final int defenderId;
  final String defenderName;
  final RealMatchReplayPoint defender;
  final double meters;

  const SpatialObservedDefenderGap({
    required this.actorId,
    required this.actorName,
    required this.actor,
    required this.defenderId,
    required this.defenderName,
    required this.defender,
    required this.meters,
  });
}

class SpatialLibraryScene {
  final String id;
  final String asset;
  final String assetSha256;
  final SpatialLearningTheme theme;
  final int matchId;
  final String date;
  final String home;
  final String away;
  final int period;
  final int startFrame;
  final int endFrame;
  final double startClock;
  final double duration;
  final int focusPlayerId;
  final String focusPlayerName;
  final List<SpatialEvidenceAnchor> evidenceAnchors;
  final List<int> highlightPlayerIds;
  final bool attackingHome;
  final int attackDirection;
  final double evidenceStart;
  final double evidenceEnd;
  final SpatialEvidenceMetrics metrics;
  final String sourceCommit;
  final String sourceUrl;

  const SpatialLibraryScene({
    required this.id,
    required this.asset,
    required this.assetSha256,
    required this.theme,
    required this.matchId,
    required this.date,
    required this.home,
    required this.away,
    required this.period,
    required this.startFrame,
    required this.endFrame,
    required this.startClock,
    required this.duration,
    required this.focusPlayerId,
    required this.focusPlayerName,
    required this.evidenceAnchors,
    required this.highlightPlayerIds,
    required this.attackingHome,
    required this.attackDirection,
    required this.evidenceStart,
    required this.evidenceEnd,
    required this.metrics,
    required this.sourceCommit,
    required this.sourceUrl,
  });

  String get attackingTeam => attackingHome ? home : away;

  bool matchesSearch(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return <String>[
      home,
      away,
      focusPlayerName,
      ...evidenceAnchors.map((anchor) => anchor.playerName),
      theme.name,
    ].any((value) => value.toLowerCase().contains(normalized));
  }

  SpatialObservedDefenderGap? observedNearbyDefender(
    RealMatchReplayData data,
    double time,
  ) {
    if (theme != SpatialLearningTheme.pressureSupport) return null;
    final actorId = evidenceAnchors.first.playerId;
    final actorIndex = data.playerIndex(actorId);
    final actorMetadata = data.players[actorIndex];
    final sample = data.sample(time);
    final actor = sample.players[actorIndex];
    if (actor == null || _distance(actor, sample.ball) > 3.5) return null;

    SpatialObservedDefenderGap? nearest;
    for (var index = 0; index < data.players.length; index++) {
      final opponent = data.players[index];
      final point = sample.players[index];
      if (opponent.home == actorMetadata.home || point == null) continue;
      final meters = _distance(actor, point);
      if (nearest == null || meters < nearest.meters) {
        nearest = SpatialObservedDefenderGap(
          actorId: actorId,
          actorName: actorMetadata.name!,
          actor: actor,
          defenderId: opponent.id,
          defenderName: opponent.name!,
          defender: point,
          meters: meters,
        );
      }
    }
    return nearest != null && nearest.meters <= 8 ? nearest : null;
  }

  void validateReplay(RealMatchReplayData data) {
    if (data.scene.id != id ||
        data.match.id != matchId ||
        data.match.home != home ||
        data.match.away != away ||
        data.match.date != date ||
        data.sourceCommit != sourceCommit ||
        data.sourceUrl != sourceUrl ||
        data.scene.focusPlayerId != focusPlayerId ||
        data.scene.attackDirection != attackDirection ||
        (data.startClock - startClock).abs() > 1 / data.fps ||
        (data.duration - duration).abs() > 1 / data.fps ||
        data.annotationSource != RealMatchReplayAnnotationSource.derived ||
        data.coverage != RealMatchReplayCoverage.broadcastVisible ||
        data.ballHeightAvailable ||
        highlightPlayerIds
            .any((id) => !data.players.any((player) => player.id == id))) {
      throw const FormatException(
        'Spatial replay scene does not match its catalog evidence.',
      );
    }
    for (final anchor in evidenceAnchors) {
      final index = data.playerIndex(anchor.playerId);
      final frame = (anchor.time * data.fps).round();
      if (!data.isVisibleAtFrame(frame, index)) {
        throw const FormatException('Spatial evidence anchor is not observed.');
      }
      final sample = data.sample(anchor.time);
      final player = sample.players[index];
      if (player == null ||
          _distance(player, sample.ball) > 3.5 + 1 / data.fps) {
        throw const FormatException(
          'Spatial evidence owner is too far from the recorded ball.',
        );
      }
    }
  }
}

class SpatialLibraryCatalog {
  static const expectedSourceCommit =
      '1ed50b775f93075c2a6d00d0d795f13b7b89709e';

  final int version;
  final String provider;
  final String license;
  final String sourceCommit;
  final String sourceUrl;
  final int matchCount;
  final List<SpatialLibraryScene> scenes;

  const SpatialLibraryCatalog({
    required this.version,
    required this.provider,
    required this.license,
    required this.sourceCommit,
    required this.sourceUrl,
    required this.matchCount,
    required this.scenes,
  });

  factory SpatialLibraryCatalog.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Spatial catalog must be a JSON object.');
    }
    return SpatialLibraryCatalog.fromJson(decoded);
  }

  factory SpatialLibraryCatalog.fromJson(Map<String, dynamic> json) {
    final values = _list(json, 'scenes');
    final scenes = values.map((value) {
      final item = _mapValue(value, 'spatial scene');
      final metrics = _map(item, 'metrics');
      final evidenceAnchors = _list(item, 'evidenceAnchors').map((value) {
        final anchor = _mapValue(value, 'evidence anchor');
        return SpatialEvidenceAnchor(
          time: _number(anchor, 'time'),
          playerId: _integer(anchor, 'playerId'),
          playerName: _string(anchor, 'playerName'),
        );
      }).toList(growable: false);
      final highlightPlayerIds = _list(item, 'highlightPlayerIds')
          .map((value) => _integerValue(value, 'highlight player id'))
          .toList(growable: false);
      return SpatialLibraryScene(
        id: _string(item, 'id'),
        asset: _string(item, 'asset'),
        assetSha256: _string(item, 'assetSha256'),
        theme: _enumValue(
          SpatialLearningTheme.values,
          _string(item, 'theme'),
          'spatial theme',
        ),
        matchId: _integer(item, 'matchId'),
        date: _string(item, 'date'),
        home: _string(item, 'home'),
        away: _string(item, 'away'),
        period: _integer(item, 'period'),
        startFrame: _integer(item, 'startFrame'),
        endFrame: _integer(item, 'endFrame'),
        startClock: _number(item, 'startClock'),
        duration: _number(item, 'duration'),
        focusPlayerId: _integer(item, 'focusPlayerId'),
        focusPlayerName: _string(item, 'focusPlayerName'),
        evidenceAnchors: evidenceAnchors,
        highlightPlayerIds: highlightPlayerIds,
        attackingHome: _string(item, 'attackingTeam') == 'home',
        attackDirection: _integer(item, 'attackDirection'),
        evidenceStart: _number(item, 'evidenceStart'),
        evidenceEnd: _number(item, 'evidenceEnd'),
        metrics: SpatialEvidenceMetrics(
          forwardMeters: _number(metrics, 'forwardMeters'),
          lateralMeters: _number(metrics, 'lateralMeters'),
          startWidthMeters: _number(metrics, 'startWidthMeters'),
          insideGainMeters: _number(metrics, 'insideGainMeters'),
          pressureMeters: metrics['pressureMeters'] == null
              ? null
              : _number(metrics, 'pressureMeters'),
          carryMeters: _number(metrics, 'carryMeters'),
          sequenceSeconds: _number(metrics, 'sequenceSeconds'),
        ),
        sourceCommit: _string(item, 'sourceCommit'),
        sourceUrl: _string(item, 'sourceUrl'),
      );
    }).toList(growable: false);
    final catalog = SpatialLibraryCatalog(
      version: _integer(json, 'version'),
      provider: _string(json, 'provider'),
      license: _string(json, 'license'),
      sourceCommit: _string(json, 'sourceCommit'),
      sourceUrl: _string(json, 'sourceUrl'),
      matchCount: _integer(json, 'matchCount'),
      scenes: scenes,
    );
    catalog._validate();
    return catalog;
  }

  Set<int> get matchIds => scenes.map((scene) => scene.matchId).toSet();
  Set<String> get focalPlayers =>
      scenes.map((scene) => scene.focusPlayerName).toSet();
  Set<SpatialLearningTheme> get themes =>
      scenes.map((scene) => scene.theme).toSet();

  List<SpatialLibraryScene> filtered({
    SpatialLearningTheme? theme,
    String query = '',
  }) =>
      scenes
          .where((scene) => theme == null || scene.theme == theme)
          .where((scene) => scene.matchesSearch(query))
          .toList(growable: false);

  void _validate() {
    final ids = <String>{};
    if (version != 1 ||
        provider != 'SkillCorner Open Data' ||
        license != 'MIT' ||
        sourceCommit != expectedSourceCommit ||
        matchCount != 9 ||
        scenes.isEmpty ||
        !sourceUrl
            .startsWith('https://github.com/SkillCorner/opendata/tree/')) {
      throw const FormatException('Invalid spatial catalog metadata.');
    }
    for (final scene in scenes) {
      if (!ids.add(scene.id) ||
          !scene.asset.startsWith('assets/scan_pass_spatial/scenes/') ||
          scene.assetSha256.length != 64 ||
          scene.matchId <= 0 ||
          scene.date.isEmpty ||
          scene.home.isEmpty ||
          scene.away.isEmpty ||
          (scene.period != 1 && scene.period != 2) ||
          scene.startFrame < 0 ||
          scene.endFrame <= scene.startFrame ||
          scene.startClock < 0 ||
          scene.duration < 10 ||
          scene.duration > 30 ||
          scene.focusPlayerName.isEmpty ||
          scene.evidenceAnchors.length < 2 ||
          scene.evidenceAnchors.length > 3 ||
          scene.highlightPlayerIds.length < 2 ||
          scene.highlightPlayerIds.length > 4 ||
          scene.highlightPlayerIds.toSet().length !=
              scene.highlightPlayerIds.length ||
          !scene.highlightPlayerIds.contains(scene.focusPlayerId) ||
          scene.evidenceAnchors.any(
            (anchor) =>
                anchor.playerName.isEmpty ||
                !scene.highlightPlayerIds.contains(anchor.playerId),
          ) ||
          scene.attackDirection.abs() != 1 ||
          scene.evidenceStart <= 0 ||
          scene.evidenceEnd <= scene.evidenceStart ||
          scene.evidenceEnd >= scene.duration ||
          scene.sourceCommit != sourceCommit ||
          !scene.sourceUrl.startsWith('$sourceUrl/data/matches/')) {
        throw const FormatException('Invalid spatial catalog scene.');
      }
      for (var index = 0; index < scene.evidenceAnchors.length; index++) {
        final anchor = scene.evidenceAnchors[index];
        if (anchor.time <= 0 ||
            anchor.time >= scene.duration ||
            (index > 0 &&
                anchor.time <= scene.evidenceAnchors[index - 1].time)) {
          throw const FormatException('Invalid ordered spatial evidence.');
        }
      }
      if ((scene.evidenceAnchors.first.time - scene.evidenceStart).abs() >
              0.001 ||
          (scene.evidenceAnchors.last.time - scene.evidenceEnd).abs() > 0.001) {
        throw const FormatException('Spatial evidence bounds do not match.');
      }
    }
  }
}

double _distance(RealMatchReplayPoint a, RealMatchReplayPoint b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return math.sqrt(dx * dx + dy * dy);
}

T _enumValue<T extends Enum>(List<T> values, String name, String label) =>
    values.firstWhere(
      (value) => value.name == name,
      orElse: () => throw FormatException('Invalid $label.'),
    );

Map<String, dynamic> _map(Map<String, dynamic> map, String key) =>
    _mapValue(map[key], key);

Map<String, dynamic> _mapValue(Object? value, String label) {
  if (value is! Map<String, dynamic>) {
    throw FormatException('$label must be a JSON object.');
  }
  return value;
}

List<dynamic> _list(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is! List<dynamic>) {
    throw FormatException('$key must be a JSON array.');
  }
  return value;
}

String _string(Map<String, dynamic> map, String key) =>
    _stringValue(map[key], key);

String _stringValue(Object? value, String label) {
  if (value is! String || value.isEmpty) {
    throw FormatException('$label must be a non-empty string.');
  }
  return value;
}

int _integer(Map<String, dynamic> map, String key) =>
    _integerValue(map[key], key);

int _integerValue(Object? value, String label) {
  if (value is! int) throw FormatException('$label must be an integer.');
  return value;
}

double _number(Map<String, dynamic> map, String key) =>
    _numberValue(map[key], key);

double _numberValue(Object? value, String label) {
  if (value is! num || !value.isFinite) {
    throw FormatException('$label must be finite.');
  }
  return value.toDouble();
}
