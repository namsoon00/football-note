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

  test('current roles only use current direct observations and reached links',
      () {
    for (final scene in catalog.scenes) {
      final replay = RealMatchReplayData.fromJsonString(
        File(scene.asset).readAsStringSync(),
      );
      for (var frame = 0; frame < replay.frames.length; frame += 3) {
        final time = frame / replay.fps;
        final sample = replay.renderSample(time);
        final roles = scene.observedRoles(replay, time);
        expect(roles.values.length, lessThanOrEqualTo(3), reason: scene.id);
        expect(roles.playerIds.toSet().length, roles.playerIds.length);
        for (final role in roles.values) {
          final index = replay.playerIndex(role.playerId);
          expect(sample.players[index], isNotNull,
              reason: '${scene.id} frame $frame');
        }
        final actor = roles.role(SpatialObservedRoleKind.ballSidePlayer);
        if (actor == null) {
          expect(roles.values, isEmpty, reason: '${scene.id} frame $frame');
          continue;
        }
        expect(actor.distanceMeters, lessThanOrEqualTo(3.5));
        final link = roles.role(SpatialObservedRoleKind.connectedTeammate);
        if (link != null) {
          expect(
            scene.evidenceAnchors.any(
              (anchor) =>
                  anchor.playerId == actor.playerId && anchor.time <= time,
            ),
            isTrue,
            reason: '${scene.id} frame $frame',
          );
          expect(
            scene.evidenceAnchors.any(
              (anchor) =>
                  anchor.playerId == link.playerId && anchor.time <= time,
            ),
            isTrue,
            reason: '${scene.id} frame $frame',
          );
        }
      }
    }
  });

  test('Muller pressure frame keeps Bayern and Dortmund roles on correct sides',
      () {
    final scene = catalog.scenes.firstWhere(
      (value) => value.id == '2417-16459-müller-pressureSupport',
    );
    final replay = RealMatchReplayData.fromJsonString(
      File(scene.asset).readAsStringSync(),
    );
    final roles = scene.observedRoles(replay, scene.evidenceStart + .5);
    final actor = roles.role(SpatialObservedRoleKind.ballSidePlayer);
    final defender = roles.role(SpatialObservedRoleKind.nearbyDefender);

    expect(actor, isNotNull);
    expect(actor!.playerName, 'Thomas Müller');
    expect(replay.players[replay.playerIndex(actor.playerId)].home, isTrue);
    expect(defender, isNotNull);
    expect(defender!.playerName, 'Mats Hummels');
    expect(replay.players[replay.playerIndex(defender.playerId)].home, isFalse);
  });

  test('focus plans are deterministic, teaching-stable, and locally framed',
      () {
    var locallyFramed = 0;
    for (final scene in catalog.scenes) {
      final replay = RealMatchReplayData.fromJsonString(
        File(scene.asset).readAsStringSync(),
      );
      final first = SpatialFocusPlan.build(replay, scene);
      final second = SpatialFocusPlan.build(replay, scene);
      expect(first.keyframes.length, second.keyframes.length, reason: scene.id);
      for (var index = 0; index < first.keyframes.length; index++) {
        final a = first.keyframes[index];
        final b = second.keyframes[index];
        expect(a.time, b.time, reason: scene.id);
        expect(a.camera.minX, b.camera.minX, reason: scene.id);
        expect(a.camera.maxY, b.camera.maxY, reason: scene.id);
      }
      final start = first.cameraAt(scene.evidenceStart);
      final middle = first.cameraAt(
        (scene.evidenceStart + scene.evidenceEnd) / 2,
      );
      final end = first.cameraAt(scene.evidenceEnd);
      expect(start.minX, closeTo(middle.minX, 1e-9), reason: scene.id);
      expect(middle.maxY, closeTo(end.maxY, 1e-9), reason: scene.id);
      final majorSpan = start.width > start.height ? start.width : start.height;
      if (majorSpan <= 60) locallyFramed++;
      expect(majorSpan, lessThan(108), reason: scene.id);
    }
    expect(locallyFramed, greaterThanOrEqualTo(90));
  });
}
