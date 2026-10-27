import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/real_match_replay.dart';
import 'package:football_note/domain/scan_pass/scan_pass_spatial_library.dart';

void main() {
  late SpatialLibraryCatalog catalog;
  late Map<String, dynamic> quality;

  setUpAll(() {
    catalog = SpatialLibraryCatalog.fromJsonString(
      File('assets/scan_pass_spatial/catalog.json').readAsStringSync(),
    );
    quality = jsonDecode(
      File('assets/scan_pass_spatial/quality-proof.json').readAsStringSync(),
    ) as Map<String, dynamic>;
  });

  test('catalog is large, diverse, balanced, and non-overlapping', () {
    expect(catalog.scenes, hasLength(108));
    expect(catalog.matchIds, hasLength(9));
    expect(catalog.focalPlayers.length, greaterThanOrEqualTo(20));
    expect(catalog.themes, SpatialLearningTheme.values.toSet());
    expect(catalog.scenes.map((scene) => scene.home),
        isNot(contains('Brisbane Roar')));
    expect(catalog.scenes.map((scene) => scene.away),
        isNot(contains('Western United')));

    final byMatch = <int, List<SpatialLibraryScene>>{};
    for (final scene in catalog.scenes) {
      byMatch.putIfAbsent(scene.matchId, () => []).add(scene);
    }
    for (final scenes in byMatch.values) {
      expect(scenes, hasLength(12));
      final focalCounts = <int, int>{};
      final themeCounts = <SpatialLearningTheme, int>{};
      for (final scene in scenes) {
        focalCounts.update(scene.focusPlayerId, (value) => value + 1,
            ifAbsent: () => 1);
        themeCounts.update(scene.theme, (value) => value + 1,
            ifAbsent: () => 1);
      }
      expect(focalCounts.values.every((count) => count <= 3), isTrue);
      expect(themeCounts.values.every((count) => count <= 3), isTrue);
      final ordered = [...scenes]
        ..sort((a, b) => a.startFrame.compareTo(b.startFrame));
      for (var index = 1; index < ordered.length; index++) {
        expect(ordered[index].startFrame,
            greaterThan(ordered[index - 1].endFrame));
      }
    }

    for (var index = 1; index < catalog.scenes.length; index++) {
      expect(catalog.scenes[index].matchId,
          isNot(catalog.scenes[index - 1].matchId));
    }
  });

  test('every compact scene matches catalog and uses observed evidence anchors',
      () {
    final proofs = <String, Map<String, dynamic>>{
      for (final value in quality['scenes'] as List<dynamic>)
        (value as Map<String, dynamic>)['id'] as String: value,
    };
    expect(proofs, hasLength(catalog.scenes.length));

    for (final scene in catalog.scenes) {
      final file = File(scene.asset);
      expect(
          sha256.convert(file.readAsBytesSync()).toString(), scene.assetSha256,
          reason: scene.id);
      final replay =
          RealMatchReplayData.fromJsonString(file.readAsStringSync());
      scene.validateReplay(replay);
      expect(replay.events, isEmpty, reason: scene.id);
      expect(replay.poses, isEmpty, reason: scene.id);
      expect(
        replay.scene.steps.map((step) => step.kind),
        isNot(contains(RealMatchReplayStepKind.pass)),
        reason: scene.id,
      );
      expect(
        replay.scene.steps
            .firstWhere((step) => step.time >= scene.evidenceStart)
            .kind,
        anyOf(
          RealMatchReplayStepKind.receive,
          RealMatchReplayStepKind.carry,
        ),
        reason: scene.id,
      );
      expect(replay.ballHeightAvailable, isFalse, reason: scene.id);
      expect(replay.annotationSource, RealMatchReplayAnnotationSource.derived);
      expect(replay.coverage, RealMatchReplayCoverage.broadcastVisible);
      expect(replay.hasDisplayReconstruction, isTrue);
      expect(replay.scene.camera.minX, lessThan(-replay.pitchLength / 2));
      expect(replay.scene.camera.maxX, greaterThan(replay.pitchLength / 2));
      expect(replay.scene.camera.minY, lessThan(-replay.pitchWidth / 2));
      expect(replay.scene.camera.maxY, greaterThan(replay.pitchWidth / 2));
      for (var frame = 0; frame < replay.frames.length; frame++) {
        final display = replay.displayFrames[frame];
        for (var player = 0; player < replay.players.length; player++) {
          expect(
              display[player * 2] / 100,
              inInclusiveRange(
                  replay.scene.camera.minX, replay.scene.camera.maxX));
          expect(
              display[player * 2 + 1] / 100,
              inInclusiveRange(
                  replay.scene.camera.minY, replay.scene.camera.maxY));
        }
        expect(
            replay.frames[frame][replay.players.length * 2] / 100,
            inInclusiveRange(
                replay.scene.camera.minX, replay.scene.camera.maxX));
        expect(
            replay.frames[frame][replay.players.length * 2 + 1] / 100,
            inInclusiveRange(
                replay.scene.camera.minY, replay.scene.camera.maxY));
      }
      expect((scene.endFrame - scene.startFrame) / replay.fps,
          closeTo(scene.duration, 1e-6));
      if (scene.theme == SpatialLearningTheme.pressureSupport) {
        final gap = scene.observedNearbyDefender(replay, scene.evidenceStart);
        expect(gap, isNotNull, reason: scene.id);
        expect(gap!.meters, closeTo(scene.metrics.pressureMeters!, .02),
            reason: scene.id);
        expect(scene.highlightPlayerIds, contains(gap.defenderId),
            reason: scene.id);
      }

      final proof = proofs[scene.id]!;
      expect(proof['ballXYObservations'], replay.frames.length);
      expect(proof['ballHeightAvailable'], isFalse);
      expect(
          proof['maxSourcePlayerSpeedMetersPerSecond'], lessThanOrEqualTo(15));
      expect(
          proof['maxDisplayPlayerSpeedMetersPerSecond'], lessThanOrEqualTo(15));
      expect(proof['maxBallSpeedMetersPerSecond'], lessThanOrEqualTo(50));
      expect(
          (proof['reconstruction']
              as Map<String, dynamic>)['inferredExcludedFromEvidence'],
          isTrue);
      for (final value in proof['anchors'] as List<dynamic>) {
        final anchor = value as Map<String, dynamic>;
        expect(anchor['playerObserved'], isTrue, reason: scene.id);
        expect(anchor['ballObserved'], isTrue, reason: scene.id);
        expect(anchor['playerId'], anchor['possessionOwner'], reason: scene.id);
        expect(anchor['ballDistanceMeters'], lessThanOrEqualTo(3.5),
            reason: scene.id);
      }
    }
  });

  test('ordered anchors preserve return sequences and recovery endpoints', () {
    final returns = catalog.scenes.where((scene) {
      final ids =
          scene.evidenceAnchors.map((anchor) => anchor.playerId).toList();
      return ids.length == 3 && ids.first == ids.last;
    }).toList();
    expect(returns, isNotEmpty);
    for (final scene in returns) {
      expect(scene.highlightPlayerIds.toSet().length,
          scene.highlightPlayerIds.length);
      expect(scene.highlightPlayerIds.length, 2);
      expect(scene.evidenceAnchors.first.time, scene.evidenceStart);
      expect(scene.evidenceAnchors.last.time, scene.evidenceEnd);
    }

    final recoveries = catalog.scenes
        .where((scene) => scene.theme == SpatialLearningTheme.recovery);
    expect(recoveries, isNotEmpty);
    for (final scene in recoveries) {
      expect(scene.evidenceAnchors, hasLength(3));
      expect(scene.evidenceAnchors.last.playerId, scene.focusPlayerId);
      expect(scene.evidenceAnchors.last.time, scene.evidenceEnd);
    }
  });

  test('source is pinned MIT data and raw match files are not bundled', () {
    final manifest = jsonDecode(
      File('assets/scan_pass_spatial/source-manifest.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(manifest['provider'], 'SkillCorner Open Data');
    expect(manifest['license'], 'MIT');
    expect(manifest['commit'], SpatialLibraryCatalog.expectedSourceCommit);
    expect(manifest['rawDataBundled'], isFalse);
    expect(manifest['files'], hasLength(21));
    final licenseRecord = (manifest['files'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .singleWhere((record) => record['path'] == 'LICENSE');
    expect(
      sha256
          .convert(File('assets/scan_pass_spatial/LICENSE').readAsBytesSync())
          .toString(),
      licenseRecord['sha256'],
    );
    expect(
      Directory('assets/scan_pass_spatial')
          .listSync(recursive: true)
          .whereType<File>()
          .any((file) => file.path.endsWith('structured_data.json')),
      isFalse,
    );
    expect(
      Directory('assets/scan_pass_spatial')
          .listSync(recursive: true)
          .whereType<File>()
          .every((file) => !file.readAsStringSync().contains('StatsBomb')),
      isTrue,
    );
  });

  test('legacy replay and authored asset families remain byte-for-byte intact',
      () {
    final preservation = jsonDecode(
      File('assets/scan_pass_spatial/legacy-asset-preservation.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final records = preservation['files'] as List<dynamic>;
    expect(records, isNotEmpty);
    expect(
      records.map((value) => (value as Map<String, dynamic>)['path']),
      contains('assets/scan_pass_authored/first-touch-open-side.json'),
    );
    expect(
      records.map((value) => (value as Map<String, dynamic>)['path']),
      contains('assets/scan_pass_replay/catalog.json'),
    );
    for (final value in records) {
      final record = value as Map<String, dynamic>;
      final file = File(record['path'] as String);
      expect(file.lengthSync(), record['bytes'], reason: file.path);
      expect(
          sha256.convert(file.readAsBytesSync()).toString(), record['sha256'],
          reason: file.path);
    }
  });

  test('catalog rejects tampered source or evidence metadata', () {
    final source = jsonDecode(
      File('assets/scan_pass_spatial/catalog.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(
      () => SpatialLibraryCatalog.fromJson({
        ...source,
        'sourceCommit': 'not-the-pinned-source',
      }),
      throwsFormatException,
    );
    final scenes = (source['scenes'] as List<dynamic>)
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList();
    scenes.first['evidenceEnd'] = scenes.first['duration'];
    expect(
      () => SpatialLibraryCatalog.fromJson({...source, 'scenes': scenes}),
      throwsFormatException,
    );
  });
}
