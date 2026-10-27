import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('importer verification command proves derived and legacy hashes', () {
    final result = Process.runSync(
      'python3',
      [
        'tool/scan_pass_replay/prepare_spatial_library.py',
        '--verify-assets',
      ],
      workingDirectory: Directory.current.path,
    );
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('VERIFIED 108 scenes, 9 matches'));
  });

  test('pinned manifest records upstream blobs without bundling raw matches',
      () {
    final manifest = _json('assets/scan_pass_spatial/source-manifest.json');
    final records =
        (manifest['files'] as List<dynamic>).cast<Map<String, dynamic>>();
    expect(manifest['commit'], '1ed50b775f93075c2a6d00d0d795f13b7b89709e');
    expect(manifest['license'], 'MIT');
    expect(manifest['rawDataBundled'], isFalse);
    expect(records.map((record) => record['path']).toSet(), hasLength(21));
    for (final record in records) {
      expect(record['bytes'], greaterThan(0));
      expect(record['sha256'], matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(record['gitBlobSha'], matches(RegExp(r'^[0-9a-f]{40}$')));
      expect(
        record['url'],
        startsWith(
          'https://raw.githubusercontent.com/SkillCorner/opendata/'
          '1ed50b775f93075c2a6d00d0d795f13b7b89709e/',
        ),
      );
    }
  });

  test('theme labels follow measured source geometry rather than cycling', () {
    final catalog = _json('assets/scan_pass_spatial/catalog.json');
    final scenes =
        (catalog['scenes'] as List<dynamic>).cast<Map<String, dynamic>>();
    for (final scene in scenes) {
      final metrics = scene['metrics'] as Map<String, dynamic>;
      final anchors = (scene['evidenceAnchors'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final highlights = scene['highlightPlayerIds'] as List<dynamic>;
      expect(highlights.toSet().length, highlights.length,
          reason: scene['id'] as String);
      expect(
        anchors.every((anchor) => highlights.contains(anchor['playerId'])),
        isTrue,
      );
      switch (scene['theme']) {
        case 'lateralSwitch':
          expect(metrics['lateralMeters'], greaterThanOrEqualTo(22),
              reason: scene['id'] as String);
          break;
        case 'forwardConnection':
          expect(metrics['forwardMeters'], greaterThanOrEqualTo(9),
              reason: scene['id'] as String);
          break;
        case 'pressureSupport':
          expect(metrics['pressureMeters'], lessThanOrEqualTo(6),
              reason: scene['id'] as String);
          expect(metrics['forwardMeters'], lessThan(10));
          break;
        case 'carryThenConnect':
          expect(metrics['carryMeters'], greaterThanOrEqualTo(3.5),
              reason: scene['id'] as String);
          break;
        case 'wideToInside':
          expect(metrics['startWidthMeters'], greaterThanOrEqualTo(20),
              reason: scene['id'] as String);
          expect(metrics['insideGainMeters'], greaterThanOrEqualTo(6));
          break;
        case 'combination':
          expect(anchors, hasLength(3));
          expect(metrics['sequenceSeconds'], lessThanOrEqualTo(16));
          break;
        case 'turnover':
          expect(anchors, hasLength(2));
          break;
        case 'recovery':
          expect(anchors, hasLength(3));
          expect(anchors.last['playerId'], scene['focusPlayerId']);
          break;
        default:
          fail('Unknown generated theme ${scene['theme']}');
      }
    }
  });

  test('quality proof retains clocks, direction, speeds, and rejection reasons',
      () {
    final proof = _json('assets/scan_pass_spatial/quality-proof.json');
    final scenes =
        (proof['scenes'] as List<dynamic>).cast<Map<String, dynamic>>();
    final rejected = (proof['rejectedCandidates'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(scenes, hasLength(108));
    expect(rejected.length, greaterThan(100));
    expect(
      rejected.map((item) => item['reason']),
      contains('focal-player-not-in-recognisable-default-set'),
    );
    expect(
      rejected.map((item) => item['reason']),
      contains('connection-does-not-pass-a-spatial-theme-threshold'),
    );
    for (final scene in scenes) {
      expect(scene['sourceStartClock'], isNotEmpty);
      expect(scene['sourceEndClock'], isNotEmpty);
      expect(scene['durationSeconds'], inInclusiveRange(10, 30));
      expect(
          scene['maxSourcePlayerSpeedMetersPerSecond'], lessThanOrEqualTo(15));
      expect(
          scene['maxDisplayPlayerSpeedMetersPerSecond'], lessThanOrEqualTo(15));
      expect(scene['maxBallSpeedMetersPerSecond'], lessThanOrEqualTo(50));
      for (final value in scene['anchors'] as List<dynamic>) {
        final anchor = value as Map<String, dynamic>;
        expect(anchor['ballDistanceMeters'], lessThanOrEqualTo(3.5));
      }
      final direction = scene['directionProof'] as Map<String, dynamic>;
      expect((direction['homeMedianX'] as num).abs(), greaterThan(20));
      expect((direction['awayMedianX'] as num).abs(), greaterThan(20));
      expect(
        (direction['homeMedianX'] as num).toDouble().sign,
        isNot((direction['awayMedianX'] as num).toDouble().sign),
      );
    }
  });

  test('generator reuses historical safety code and precomputes match indices',
      () {
    final source = File('tool/scan_pass_replay/prepare_spatial_library.py')
        .readAsStringSync();
    expect(source, contains('from prepare_historical import'));
    expect(source, contains('reconstruct_display'));
    expect(source,
        contains('direct_observations_by_entity(frames, set(metadata))'));
    expect(source, contains('possession_touches(match, frames)'));
    expect(source, isNot(contains('StatsBomb')));
    expect(source, contains('rejectedCandidates'));
  });

  test('generator rejects a raw ball teleport above 50 metres per second', () {
    final result = Process.runSync(
      'python3',
      [
        '-c',
        'from tool.scan_pass_replay.prepare_spatial_library import '
            'validate_ball_speed\n'
            'try:\n'
            ' validate_ball_speed([[0,0,0],[501,0,0]])\n'
            'except ValueError:\n'
            ' print("REJECTED")\n'
            'else:\n'
            ' raise SystemExit("teleport was accepted")',
      ],
      workingDirectory: Directory.current.path,
    );
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('REJECTED'));
  });
}

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
