import 'dart:math' as math;

import 'real_match_replay.dart';
import 'scan_pass_spatial_library.dart';

enum SpatialObservedRoleKind {
  ballSidePlayer,
  connectedTeammate,
  nearbyDefender,
}

class SpatialObservedRole {
  final SpatialObservedRoleKind kind;
  final int playerId;
  final String playerName;
  final RealMatchReplayPoint point;
  final double? distanceMeters;

  const SpatialObservedRole({
    required this.kind,
    required this.playerId,
    required this.playerName,
    required this.point,
    this.distanceMeters,
  });
}

class SpatialObservedRoles {
  final List<SpatialObservedRole> values;

  const SpatialObservedRoles(this.values);

  SpatialObservedRole? role(SpatialObservedRoleKind kind) {
    for (final value in values) {
      if (value.kind == kind) return value;
    }
    return null;
  }

  List<int> get playerIds =>
      values.map((value) => value.playerId).toList(growable: false);
}

class SpatialFocusKeyframe {
  final double time;
  final RealMatchReplayCamera camera;

  const SpatialFocusKeyframe({required this.time, required this.camera});
}

/// Precomputed metric framing for one spatial-library clip.
///
/// Construction scans the short source clip once. Painting only interpolates
/// between this small list of deliberate keyframes and reads the cached set of
/// relevant observed players for the current source frame.
class SpatialFocusPlan {
  final int fps;
  final double duration;
  final RealMatchReplayCamera teachingCamera;
  final List<SpatialFocusKeyframe> keyframes;
  final List<List<int>> _relevantPlayerIdsByFrame;

  const SpatialFocusPlan._({
    required this.fps,
    required this.duration,
    required this.teachingCamera,
    required this.keyframes,
    required List<List<int>> relevantPlayerIdsByFrame,
  }) : _relevantPlayerIdsByFrame = relevantPlayerIdsByFrame;

  factory SpatialFocusPlan.build(
    RealMatchReplayData data,
    SpatialLibraryScene scene,
  ) {
    final relevantByFrame = <List<int>>[];
    for (var frame = 0; frame < data.frames.length; frame++) {
      final time = frame / data.fps;
      final sample = data.sample(time);
      final activeHome = _activeHomeAt(data, scene, time);
      final namesLessonActors =
          (time >= scene.coreStart && time <= scene.evidenceEnd + 1.6) ||
              time >= data.duration - 1 / data.fps;
      final relevant = <int>{
        if (namesLessonActors) ...scene.highlightPlayerIds,
      };
      if (data.sourcePossessionOwners.isNotEmpty) {
        final owner = data.sourcePossessionOwners[frame];
        if (owner != null) relevant.add(owner);
      }
      final nearbyAttackers = <({int id, double meters})>[];
      final nearbyDefenders = <({int id, double meters})>[];
      for (var index = 0; index < data.players.length; index++) {
        final point = sample.players[index];
        if (point == null) continue;
        final player = data.players[index];
        final meters = _pointDistance(point, sample.ball);
        final attacks = player.home == activeHome;
        if (attacks && meters <= 11) {
          nearbyAttackers.add((id: player.id, meters: meters));
        } else if (!attacks && meters <= 13) {
          nearbyDefenders.add((id: player.id, meters: meters));
        }
      }
      for (final anchor in scene.evidenceAnchors) {
        if ((anchor.time - time) > .8 || (time - anchor.time) > 1.8) continue;
        final point = sample.players[data.playerIndex(anchor.playerId)];
        if (point != null) relevant.add(anchor.playerId);
      }
      nearbyAttackers.sort((a, b) => a.meters.compareTo(b.meters));
      nearbyDefenders.sort((a, b) => a.meters.compareTo(b.meters));
      relevant
        ..addAll(nearbyAttackers.take(4).map((value) => value.id))
        ..addAll(nearbyDefenders.take(3).map((value) => value.id));
      relevant.addAll(scene.observedRoles(data, time).playerIds);
      relevantByFrame.add(relevant.toList(growable: false));
    }

    RealMatchReplayCamera cameraFor(double start, double end) {
      final first = (start * data.fps).floor().clamp(0, data.frames.length - 1);
      final last = (end * data.fps).ceil().clamp(0, data.frames.length - 1);
      var minX = double.infinity;
      var maxX = double.negativeInfinity;
      var minY = double.infinity;
      var maxY = double.negativeInfinity;
      void include(RealMatchReplayPoint point) {
        minX = math.min(minX, point.x);
        maxX = math.max(maxX, point.x);
        minY = math.min(minY, point.y);
        maxY = math.max(maxY, point.y);
      }

      for (var frame = first; frame <= last; frame++) {
        final sample = data.sample(frame / data.fps);
        include(sample.ball);
        for (final id in relevantByFrame[frame]) {
          final point = sample.players[data.playerIndex(id)];
          if (point != null) include(point);
        }
      }
      if (!minX.isFinite) {
        return data.scene.camera;
      }

      minX -= 4;
      maxX += 4;
      minY -= 4;
      maxY += 4;
      if (scene.attackDirection > 0) {
        maxX += 3.5;
      } else {
        minX -= 3.5;
      }
      final xRange = _minimumRange(minX, maxX, 30);
      final yRange = _minimumRange(minY, maxY, 24);
      final constrainedX = _shiftInside(
        xRange.$1,
        xRange.$2,
        -data.pitchLength / 2 - 5,
        data.pitchLength / 2 + 5,
      );
      final constrainedY = _shiftInside(
        yRange.$1,
        yRange.$2,
        -data.pitchWidth / 2 - 5,
        data.pitchWidth / 2 + 5,
      );
      return RealMatchReplayCamera(
        minX: constrainedX.$1,
        maxX: constrainedX.$2,
        minY: constrainedY.$1,
        maxY: constrainedY.$2,
      );
    }

    // Two-second overlapping source windows keep the situation readable
    // without ever framing the union of an entire 20-40 second passage. A
    // point required at an interpolated time belongs to both neighbouring
    // four-second windows, so interpolating their bounds preserves its
    // containment while producing a gentle pan/zoom with fixed orientation.
    const keyframeSeconds = 2.0;
    const windowRadiusSeconds = 2.0;
    final keyframes = <SpatialFocusKeyframe>[];
    for (var time = 0.0; time < data.duration; time += keyframeSeconds) {
      keyframes.add(SpatialFocusKeyframe(
        time: time,
        camera: cameraFor(
          math.max(0, time - windowRadiusSeconds),
          math.min(data.duration, time + windowRadiusSeconds),
        ),
      ));
    }
    keyframes.add(SpatialFocusKeyframe(
      time: data.duration,
      camera: cameraFor(
        math.max(0, data.duration - windowRadiusSeconds),
        data.duration,
      ),
    ));
    final teachingCamera = cameraFor(scene.coreStart, scene.coreEnd);
    return SpatialFocusPlan._(
      fps: data.fps,
      duration: data.duration,
      teachingCamera: teachingCamera,
      keyframes: List.unmodifiable(keyframes),
      relevantPlayerIdsByFrame: List.unmodifiable(relevantByFrame),
    );
  }

  RealMatchReplayCamera cameraAt(double time) {
    final clamped = time.clamp(0.0, duration);
    if (clamped <= keyframes.first.time) return keyframes.first.camera;
    for (var index = 1; index < keyframes.length; index++) {
      final next = keyframes[index];
      if (clamped > next.time) continue;
      final previous = keyframes[index - 1];
      final span = next.time - previous.time;
      if (span <= 0) return next.camera;
      return RealMatchReplayCamera.lerp(
        previous.camera,
        next.camera,
        _smoothStep((clamped - previous.time) / span),
      );
    }
    return keyframes.last.camera;
  }

  List<int> relevantPlayerIdsAt(double time) {
    final frame = (time.clamp(0.0, duration) * fps)
        .floor()
        .clamp(0, _relevantPlayerIdsByFrame.length - 1);
    return _relevantPlayerIdsByFrame[frame];
  }
}

double _smoothStep(double value) => value * value * (3 - 2 * value);

extension SpatialLibrarySceneFocus on SpatialLibraryScene {
  SpatialObservedRoles observedRoles(
    RealMatchReplayData data,
    double time,
  ) {
    final sample = data.renderSample(time);
    SpatialEvidenceAnchor? latestReached;
    for (final anchor in evidenceAnchors) {
      if (anchor.time > time) break;
      latestReached = anchor;
    }
    final activeHome = latestReached == null
        ? attackingHome
        : data.players[data.playerIndex(latestReached.playerId)].home;
    ({int index, double meters})? ballSide;

    if (data.sourcePossessionOwners.isNotEmpty) {
      final frame = (time.clamp(0.0, data.duration) * data.fps)
          .floor()
          .clamp(0, data.sourcePossessionOwners.length - 1);
      final ownerId = data.sourcePossessionOwners[frame];
      if (ownerId != null) {
        final index = data.playerIndex(ownerId);
        final point = sample.players[index];
        if (point != null) {
          final meters = _pointDistance(point, sample.ball);
          if (meters <= 3.5) ballSide = (index: index, meters: meters);
        }
      }
    }
    if (ballSide == null && latestReached != null) {
      final index = data.playerIndex(latestReached.playerId);
      final point = sample.players[index];
      if (point != null) {
        final meters = _pointDistance(point, sample.ball);
        if (meters <= 3.5) ballSide = (index: index, meters: meters);
      }
    }
    if (ballSide == null) {
      for (var index = 0; index < data.players.length; index++) {
        final point = sample.players[index];
        if (point == null || data.players[index].home != activeHome) continue;
        final meters = _pointDistance(point, sample.ball);
        if (meters <= 3.5 && (ballSide == null || meters < ballSide.meters)) {
          ballSide = (index: index, meters: meters);
        }
      }
    }
    if (ballSide == null) return const SpatialObservedRoles([]);

    final actor = data.players[ballSide.index];
    final actorPoint = sample.players[ballSide.index]!;
    final roles = <SpatialObservedRole>[
      SpatialObservedRole(
        kind: SpatialObservedRoleKind.ballSidePlayer,
        playerId: actor.id,
        playerName: actor.name!,
        point: actorPoint,
        distanceMeters: ballSide.meters,
      ),
    ];

    SpatialEvidenceAnchor? linkedAnchor;
    if (latestReached?.playerId == actor.id &&
        time - latestReached!.time <= 1.8) {
      for (final candidate in evidenceAnchors.reversed) {
        if (candidate.time >= latestReached.time ||
            candidate.playerId == actor.id) {
          continue;
        }
        final candidatePlayer = data.players[data.playerIndex(
          candidate.playerId,
        )];
        if (candidatePlayer.home == activeHome) {
          linkedAnchor = candidate;
          break;
        }
      }
    }
    if (linkedAnchor != null) {
      final linkedIndex = data.playerIndex(linkedAnchor.playerId);
      final linkedPoint = sample.players[linkedIndex];
      final linkedPlayer = data.players[linkedIndex];
      if (linkedPoint != null && linkedPlayer.home == activeHome) {
        roles.add(SpatialObservedRole(
          kind: SpatialObservedRoleKind.connectedTeammate,
          playerId: linkedPlayer.id,
          playerName: linkedPlayer.name!,
          point: linkedPoint,
        ));
      }
    }

    ({int index, double meters})? defender;
    for (var index = 0; index < data.players.length; index++) {
      final point = sample.players[index];
      if (point == null || data.players[index].home == actor.home) continue;
      final meters = _pointDistance(actorPoint, point);
      if (meters <= 10 && (defender == null || meters < defender.meters)) {
        defender = (index: index, meters: meters);
      }
    }
    if (defender != null) {
      final player = data.players[defender.index];
      roles.add(SpatialObservedRole(
        kind: SpatialObservedRoleKind.nearbyDefender,
        playerId: player.id,
        playerName: player.name!,
        point: sample.players[defender.index]!,
        distanceMeters: defender.meters,
      ));
    }
    return SpatialObservedRoles(List.unmodifiable(roles));
  }
}

bool _activeHomeAt(
  RealMatchReplayData data,
  SpatialLibraryScene scene,
  double time,
) {
  SpatialEvidenceAnchor? latest;
  for (final anchor in scene.evidenceAnchors) {
    if (anchor.time > time) break;
    latest = anchor;
  }
  if (latest == null) return scene.attackingHome;
  return data.players[data.playerIndex(latest.playerId)].home;
}

(double, double) _minimumRange(double min, double max, double minimum) {
  final current = max - min;
  if (current >= minimum) return (min, max);
  final center = (min + max) / 2;
  return (center - minimum / 2, center + minimum / 2);
}

(double, double) _shiftInside(
  double min,
  double max,
  double outerMin,
  double outerMax,
) {
  final width = max - min;
  if (width >= outerMax - outerMin) return (min, max);
  if (min < outerMin) {
    return (outerMin, outerMin + width);
  }
  if (max > outerMax) {
    return (outerMax - width, outerMax);
  }
  return (min, max);
}

double _pointDistance(RealMatchReplayPoint a, RealMatchReplayPoint b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return math.sqrt(dx * dx + dy * dy);
}
