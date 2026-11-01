import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/real_match_replay.dart';
import 'package:football_note/domain/scan_pass/scan_pass_spatial_library.dart';

void main() {
  late SpatialLibraryCatalog catalog;
  late Map<String, dynamic> catalogJson;
  late Map<String, dynamic> quality;

  setUpAll(() {
    catalogJson = _json('assets/scan_pass_spatial/catalog.json');
    catalog = SpatialLibraryCatalog.fromJson(catalogJson);
    quality = _json('assets/scan_pass_spatial/quality-proof.json');
  });

  test('catalogue exposes only representative source-supported objectives', () {
    expect(catalog.scenes, hasLength(72));
    expect(catalog.scenes.first.id, '2269-34881-mbappe-combination');
    expect(catalog.matchIds.length, 9);
    expect(catalog.focalPlayers.length, 62);
    expect(
      catalog.themes,
      {
        SpatialLearningTheme.lateralSwitch,
        SpatialLearningTheme.pressureSupport,
        SpatialLearningTheme.combination,
      },
    );
    expect(
      catalog.scenes.length,
      (quality['counts'] as Map<String, dynamic>)['scenes'],
    );

    for (final scene in catalog.scenes) {
      expect(scene.duration, inInclusiveRange(20, 40), reason: scene.id);
      expect(scene.evidenceStart, greaterThanOrEqualTo(4), reason: scene.id);
      expect(
        scene.duration - scene.evidenceEnd,
        greaterThanOrEqualTo(4),
        reason: scene.id,
      );
      expect(scene.coreStart, closeTo(scene.evidenceStart - .5, .001));
      expect(scene.coreEnd, closeTo(scene.evidenceEnd + .5, .001));
      expect(scene.corePlayerIds, hasLength(greaterThanOrEqualTo(2)));
      expect(scene.supportPlayerIds, isNotEmpty);
      expect(scene.opponentContextPlayerIds, isNotEmpty);
      expect(
        scene.highlightPlayerIds.toSet(),
        containsAll(<int>{
          ...scene.corePlayerIds,
          ...scene.supportPlayerIds,
          ...scene.opponentContextPlayerIds,
        }),
      );
    }
  });

  test('discovery folds accents and combines localized team/player tokens', () {
    expect(SpatialLibraryDiscovery.normalize('  Mbappé '), 'mbappe');
    expect(SpatialLibraryDiscovery.normalize('GÜN DOĞAN'), 'gundogan');
    expect(SpatialLibraryDiscovery.normalize('Real-Madrid'), 'realmadrid');

    final realKroos = catalog.scenes
        .where(
          (scene) => SpatialLibraryDiscovery.matchesScene(scene, '레알 크로스'),
        )
        .toList(growable: false);
    expect(realKroos, isNotEmpty);
    expect(
      realKroos.every(
        (scene) =>
            <String>{scene.home, scene.away}.contains('Real Madrid') &&
            scene.involvesPlayer('Toni Kroos'),
      ),
      isTrue,
    );

    final parisMbappe = catalog.scenes
        .where(
          (scene) => SpatialLibraryDiscovery.matchesScene(
            scene,
            'PSG Mbappé',
          ),
        )
        .toList(growable: false);
    expect(parisMbappe, isNotEmpty);
    expect(parisMbappe.every((scene) => scene.involvesPlayer('Kylian Mbappe')),
        isTrue);
  });

  test('discovery indexes evidence participants but not the match roster', () {
    final messiEvidence = catalog.scenes.firstWhere(
      (scene) =>
          scene.focusPlayerName != 'Lionel Messi' &&
          scene.evidenceAnchors.any(
            (anchor) => anchor.playerName == 'Lionel Messi',
          ),
    );
    expect(
      SpatialLibraryDiscovery.matchesScene(messiEvidence, '메시'),
      isTrue,
    );

    final rosterOnly = catalog.scenes.firstWhere(
      (scene) =>
          <String>{scene.home, scene.away}.contains('FC Barcelona') &&
          !scene.involvesPlayer('Lionel Messi'),
    );
    expect(
      SpatialLibraryDiscovery.matchesScene(rosterOnly, '메시'),
      isFalse,
    );
  });

  test('attacking-team and participant filters use actual scene evidence', () {
    final realPlayers = catalog.participants(attackingTeam: 'Real Madrid');
    expect(realPlayers, contains('Toni Kroos'));
    expect(realPlayers, isNot(contains('Kylian Mbappe')));

    final values = catalog.filtered(
      attackingTeam: 'Real Madrid',
      player: 'Toni Kroos',
    );
    expect(values, isNotEmpty);
    expect(
      values.every(
        (scene) =>
            scene.attackingTeam == 'Real Madrid' &&
            scene.involvesPlayer('Toni Kroos'),
      ),
      isTrue,
    );
  });

  test('shipped passages recompute guarded actors and owned-ball visibility',
      () {
    final proofs = <String, Map<String, dynamic>>{
      for (final value in quality['scenes'] as List<dynamic>)
        (value as Map<String, dynamic>)['id'] as String: value,
    };
    expect(proofs, hasLength(catalog.scenes.length));

    for (final scene in catalog.scenes) {
      final file = File(scene.asset);
      expect(
        sha256.convert(file.readAsBytesSync()).toString(),
        scene.assetSha256,
        reason: scene.id,
      );
      final replay =
          RealMatchReplayData.fromJsonString(file.readAsStringSync());
      scene.validateReplay(replay);
      expect(replay.match.id, scene.matchId);
      expect(replay.duration, closeTo(scene.duration, 1e-6));
      expect(replay.hasDisplayReconstruction, isFalse);
      expect(replay.missingPlayerCoordinate, isNotNull);
      expect(replay.sourcePossessionOwners, hasLength(replay.frames.length));
      expect(replay.events, isEmpty);
      expect(replay.poses, isEmpty);
      expect(replay.annotationSource, RealMatchReplayAnnotationSource.derived);
      expect(replay.coverage, RealMatchReplayCoverage.broadcastVisible);
      expect(replay.ballHeightAvailable, isFalse);

      for (var frame = 0; frame < replay.frames.length; frame++) {
        for (var player = 0; player < replay.players.length; player++) {
          final x = replay.frames[frame][player * 2];
          final y = replay.frames[frame][player * 2 + 1];
          if (replay.isVisibleAtFrame(frame, player)) {
            expect(x, isNot(replay.missingPlayerCoordinate), reason: scene.id);
            expect(y, isNot(replay.missingPlayerCoordinate), reason: scene.id);
          } else {
            expect(x, replay.missingPlayerCoordinate, reason: scene.id);
            expect(y, replay.missingPlayerCoordinate, reason: scene.id);
          }
        }
      }

      final proof = proofs[scene.id]!;
      expect(proof['ballXYObservations'], replay.frames.length);
      expect(proof['guardWindows'], hasLength(scene.evidenceAnchors.length));
      expect(
        (proof['displayEvidence']
            as Map<String, dynamic>)['reconstructionIncluded'],
        isFalse,
      );
      expect(
        (proof['ownedBallVisibility']
            as Map<String, dynamic>)['meaningfulFrames'],
        greaterThan(0),
      );
      expect(
          proof['maxSourcePlayerSpeedMetersPerSecond'], lessThanOrEqualTo(15));
      expect(proof['maxBallSpeedMetersPerSecond'], lessThanOrEqualTo(50));
    }
  });

  test('theme claims remain limited to measured geometry', () {
    for (final scene in catalog.scenes) {
      switch (scene.theme) {
        case SpatialLearningTheme.lateralSwitch:
          expect(scene.metrics.lateralMeters, greaterThanOrEqualTo(22));
          break;
        case SpatialLearningTheme.pressureSupport:
          expect(scene.metrics.pressureMeters, lessThanOrEqualTo(6));
          expect(scene.metrics.forwardMeters, lessThan(10));
          break;
        case SpatialLearningTheme.combination:
          expect(scene.evidenceAnchors, hasLength(3));
          expect(scene.metrics.sequenceSeconds, lessThanOrEqualTo(16));
          break;
        case SpatialLearningTheme.forwardConnection:
        case SpatialLearningTheme.carryThenConnect:
        case SpatialLearningTheme.wideToInside:
        case SpatialLearningTheme.turnover:
        case SpatialLearningTheme.recovery:
          fail('Unreviewed theme was exposed: ${scene.theme.name}');
      }
    }
  });

  test('service validation rejects guard, core, and owned-owner gaps', () {
    final scene = catalog.scenes.first;
    final source = _json(scene.asset);
    final replay = RealMatchReplayData.fromJson(source);
    scene.validateReplay(replay);

    Map<String, dynamic> tamperedAt(int frame, int playerId) {
      final changed = jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
      final players =
          (changed['players'] as List<dynamic>).cast<Map<String, dynamic>>();
      final index = players.indexWhere((value) => value['id'] == playerId);
      final visibility = changed['visibility'] as List<dynamic>;
      final frames = changed['frames'] as List<dynamic>;
      (visibility[frame] as List<dynamic>)[index] = 0;
      (frames[frame] as List<dynamic>)[index * 2] =
          changed['missingPlayerCoordinate'];
      (frames[frame] as List<dynamic>)[index * 2 + 1] =
          changed['missingPlayerCoordinate'];
      return changed;
    }

    final anchor = scene.evidenceAnchors.first;
    final anchorFrame = (anchor.time * replay.fps).round();
    expect(
      () => scene.validateReplay(
        RealMatchReplayData.fromJson(tamperedAt(anchorFrame, anchor.playerId)),
      ),
      throwsFormatException,
    );

    final coreFrame = (scene.coreStart * replay.fps).round() + 1;
    expect(
      () => scene.validateReplay(
        RealMatchReplayData.fromJson(
          tamperedAt(coreFrame, scene.corePlayerIds.last),
        ),
      ),
      throwsFormatException,
    );

    final ownerFrame = replay.sourcePossessionOwners.indexWhere(
      (value) => value != null,
    );
    final owner = replay.sourcePossessionOwners[ownerFrame]!;
    expect(
      () => scene.validateReplay(
        RealMatchReplayData.fromJson(tamperedAt(ownerFrame, owner)),
      ),
      throwsFormatException,
    );
  });

  test('quality proof records post-filter and source-limit rejections', () {
    final reasons = ((quality['counts']
            as Map<String, dynamic>)['rejectedReasons'] as Map<String, dynamic>)
        .keys;
    expect(reasons,
        contains('departure-or-arrival-actor-missing-in-guard-window'));
    expect(reasons, contains('core-actor-has-a-central-visibility-gap'));
    expect(
      reasons.any((value) => value.contains('Owned-ball actor failed')),
      isTrue,
    );
    expect(
      reasons,
      contains('no-20-to-40-second-source-clip-with-four-second-context'),
    );
    expect(
      reasons.any((value) => value.contains('motion-continuity filter')),
      isTrue,
    );
  });

  test('catalog rejects shortened or discontinuous teaching metadata', () {
    final shortened =
        jsonDecode(jsonEncode(catalogJson)) as Map<String, dynamic>;
    ((shortened['scenes'] as List<dynamic>).first
        as Map<String, dynamic>)['duration'] = 19.9;
    expect(
      () => SpatialLibraryCatalog.fromJson(shortened),
      throwsFormatException,
    );

    final noContext =
        jsonDecode(jsonEncode(catalogJson)) as Map<String, dynamic>;
    ((noContext['scenes'] as List<dynamic>).first
        as Map<String, dynamic>)['evidenceStart'] = 3.9;
    expect(
      () => SpatialLibraryCatalog.fromJson(noContext),
      throwsFormatException,
    );
  });

  test('pinned MIT source and preserved asset families remain intact', () {
    final manifest = _json('assets/scan_pass_spatial/source-manifest.json');
    expect(manifest['commit'], SpatialLibraryCatalog.expectedSourceCommit);
    expect(manifest['license'], 'MIT');
    expect(manifest['rawDataBundled'], isFalse);
    expect(manifest['files'], hasLength(21));

    final preservation =
        _json('assets/scan_pass_spatial/legacy-asset-preservation.json');
    final records = preservation['files'] as List<dynamic>;
    expect(
      records.map((value) => (value as Map<String, dynamic>)['path']),
      containsAll(<String>[
        'assets/video_learning/catalog.json',
        'assets/scan_pass_replay/catalog.json',
        'assets/scan_pass_authored/first-touch-open-side.json',
      ]),
    );
    for (final value in records) {
      final record = value as Map<String, dynamic>;
      final file = File(record['path'] as String);
      expect(file.lengthSync(), record['bytes'], reason: file.path);
      expect(
        sha256.convert(file.readAsBytesSync()).toString(),
        record['sha256'],
        reason: file.path,
      );
    }
  });
}

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
