import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/real_match_replay.dart';
import 'package:football_note/domain/scan_pass/scan_pass_spatial_focus.dart';
import 'package:football_note/domain/scan_pass/scan_pass_spatial_library.dart';

void main() {
  late SpatialLibraryCatalog catalog;

  setUpAll(() {
    catalog = SpatialLibraryCatalog.fromJsonString(
      File('assets/scan_pass_spatial/catalog.json').readAsStringSync(),
    );
  });

  test('current roles use only direct current observations', () {
    for (final scene in catalog.scenes) {
      final replay = _replay(scene);
      for (var frame = 0; frame < replay.frames.length; frame += 5) {
        final time = frame / replay.fps;
        final sample = replay.sample(time);
        final roles = scene.observedRoles(replay, time);
        expect(roles.values.length, lessThanOrEqualTo(3), reason: scene.id);
        expect(roles.playerIds.toSet(), hasLength(roles.playerIds.length));
        for (final role in roles.values) {
          final index = replay.playerIndex(role.playerId);
          expect(sample.players[index], isNotNull,
              reason: '${scene.id} $frame');
        }
      }
    }
  });

  test('pressure role is an observed opponent at the evidenced gap', () {
    final scene = catalog.scenes.firstWhere(
      (value) => value.theme == SpatialLearningTheme.pressureSupport,
    );
    final replay = _replay(scene);
    final gap = scene.observedNearbyDefender(replay, scene.evidenceStart);
    expect(gap, isNotNull);
    expect(gap!.meters, closeTo(scene.metrics.pressureMeters!, .02));
    expect(scene.opponentContextPlayerIds, contains(gap.defenderId));
    expect(
      replay.player(gap.actorId).home,
      isNot(replay.player(gap.defenderId).home),
    );
  });

  test('local camera contains current source-confirmed action on every frame',
      () {
    for (final scene in catalog.scenes) {
      final replay = _replay(scene);
      final plan = SpatialFocusPlan.build(replay, scene);
      expect(plan.keyframes.length, greaterThan(2), reason: scene.id);
      final centers = <String>{};

      for (var frame = 0; frame < replay.frames.length; frame++) {
        final time = frame / replay.fps;
        final camera = plan.cameraAt(time);
        final sample = replay.sample(time);
        centers.add(
          '${((camera.minX + camera.maxX) / 2).toStringAsFixed(2)}:'
          '${((camera.minY + camera.maxY) / 2).toStringAsFixed(2)}',
        );
        expect(camera.width, lessThan(replay.pitchLength + 10),
            reason: scene.id);
        expect(camera.height, lessThan(replay.pitchWidth + 10),
            reason: scene.id);
        expect(_contains(camera, sample.ball), isTrue,
            reason: '${scene.id} ball $frame');
        final relevant = <int>{
          ...plan.relevantPlayerIdsAt(time),
          if (replay.sourcePossessionOwners.isNotEmpty &&
              replay.sourcePossessionOwners[frame] != null)
            replay.sourcePossessionOwners[frame]!,
        };
        final owner = replay.sourcePossessionOwners.isEmpty
            ? null
            : replay.sourcePossessionOwners[frame];
        if (owner != null) {
          expect(relevant, contains(owner), reason: '${scene.id} owner $frame');
        }
        if (time >= scene.coreStart && time <= scene.coreEnd) {
          expect(
            relevant,
            containsAll(scene.highlightPlayerIds),
            reason: '${scene.id} guarded actors $frame',
          );
        }
        for (final id in relevant) {
          final point = sample.players[replay.playerIndex(id)];
          if (point != null) {
            expect(_contains(camera, point), isTrue,
                reason: '${scene.id} $id $frame');
          }
        }
      }
      expect(centers.length, greaterThan(1), reason: scene.id);
    }
  });
}

RealMatchReplayData _replay(SpatialLibraryScene scene) =>
    RealMatchReplayData.fromJsonString(File(scene.asset).readAsStringSync());

bool _contains(RealMatchReplayCamera camera, RealMatchReplayPoint point) =>
    point.x >= camera.minX &&
    point.x <= camera.maxX &&
    point.y >= camera.minY &&
    point.y <= camera.maxY;
