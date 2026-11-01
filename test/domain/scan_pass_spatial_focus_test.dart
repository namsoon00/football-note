import 'dart:io';
import 'dart:math' as math;

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

  test('confirmed possession requires source ownership and close observations',
      () {
    const owner = 42;
    const ball = RealMatchReplayPoint(10, 10);
    const nearby = RealMatchReplayPoint(12, 10);

    expect(
      resolveConfirmedPossessionOwner(
        sourceOwnerId: owner,
        observedOwnerPoint: nearby,
        observedBall: ball,
      ),
      owner,
    );
    expect(
      resolveConfirmedPossessionOwner(
        sourceOwnerId: null,
        observedOwnerPoint: nearby,
        observedBall: ball,
      ),
      isNull,
      reason: 'proximity cannot replace a missing/pass-flight source record',
    );
    expect(
      resolveConfirmedPossessionOwner(
        sourceOwnerId: owner,
        observedOwnerPoint: null,
        observedBall: ball,
      ),
      isNull,
      reason: 'a hidden owner is not observed possession',
    );
    expect(
      resolveConfirmedPossessionOwner(
        sourceOwnerId: owner,
        observedOwnerPoint: nearby,
        observedBall: null,
      ),
      isNull,
      reason: 'a missing ball observation cannot confirm possession',
    );
    expect(
      resolveConfirmedPossessionOwner(
        sourceOwnerId: owner,
        observedOwnerPoint: const RealMatchReplayPoint(13.51, 10),
        observedBall: ball,
      ),
      isNull,
      reason: 'an implausibly distant source label is not possession',
    );
  });

  test('real clips never promote nearby fallback or stale source ownership',
      () {
    var nearbyWithoutSourceRecord = 0;
    var rejectedDistantSourceRecords = 0;
    for (final scene in catalog.scenes) {
      final replay = _replay(scene);
      for (var frame = 0; frame < replay.frames.length; frame++) {
        final time = frame / replay.fps;
        final sample = replay.sample(time);
        final sourceOwner = replay.sourcePossessionOwners[frame];
        final confirmed = replay.confirmedPossessionOwnerIdAt(time);
        if (sourceOwner == null) {
          expect(confirmed, isNull, reason: '${scene.id} pass frame $frame');
          if (scene
                  .observedRoles(replay, time)
                  .role(SpatialObservedRoleKind.ballSidePlayer) !=
              null) {
            nearbyWithoutSourceRecord++;
          }
          continue;
        }
        final point = sample.players[replay.playerIndex(sourceOwner)];
        final distance =
            point == null ? double.infinity : _distance(point, sample.ball);
        if (point == null ||
            distance > spatialConfirmedPossessionMaximumDistanceMeters) {
          expect(confirmed, isNull,
              reason: '${scene.id} rejected owner frame $frame');
          if (point != null) rejectedDistantSourceRecords++;
        } else {
          expect(confirmed, sourceOwner,
              reason: '${scene.id} confirmed owner frame $frame');
        }
      }
    }
    expect(nearbyWithoutSourceRecord, greaterThan(0));
    expect(rejectedDistantSourceRecords, greaterThan(0));
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

double _distance(RealMatchReplayPoint a, RealMatchReplayPoint b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return math.sqrt(dx * dx + dy * dy);
}
