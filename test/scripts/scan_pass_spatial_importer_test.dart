import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('asset verifier recomputes the shipped source guarantees', () {
    final result = Process.runSync(
      'python3',
      ['tool/scan_pass_replay/prepare_spatial_library.py', '--verify-assets'],
      workingDirectory: Directory.current.path,
    );
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, matches(RegExp(r'VERIFIED \d+ scenes, \d+ matches')));
    expect(result.stdout, contains('3 themes'));
  });

  test('pinned manifest records upstream blobs without raw match bundling', () {
    final manifest = _json('assets/scan_pass_spatial/source-manifest.json');
    final records =
        (manifest['files'] as List<dynamic>).cast<Map<String, dynamic>>();
    expect(manifest['commit'], '1ed50b775f93075c2a6d00d0d795f13b7b89709e');
    expect(manifest['license'], 'MIT');
    expect(manifest['rawDataBundled'], isFalse);
    expect(records, hasLength(21));
    for (final record in records) {
      expect(record['bytes'], greaterThan(0));
      expect(record['sha256'], matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(record['gitBlobSha'], matches(RegExp(r'^[0-9a-f]{40}$')));
    }
  });

  test('approved theme labels follow measured source geometry', () {
    final catalog = _json('assets/scan_pass_spatial/catalog.json');
    final scenes =
        (catalog['scenes'] as List<dynamic>).cast<Map<String, dynamic>>();
    expect(scenes.map((value) => value['theme']).toSet(), {
      'lateralSwitch',
      'pressureSupport',
      'combination',
    });
    final themeCounts = <String, int>{};
    for (final scene in scenes) {
      final theme = scene['theme'] as String;
      themeCounts[theme] = (themeCounts[theme] ?? 0) + 1;
    }
    expect(
      themeCounts.values.reduce((left, right) => left > right ? left : right) -
          themeCounts.values
              .reduce((left, right) => left < right ? left : right),
      lessThanOrEqualTo(1),
    );
    for (final scene in scenes) {
      final metrics = scene['metrics'] as Map<String, dynamic>;
      final anchors = (scene['evidenceAnchors'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(scene['duration'], inInclusiveRange(20, 40));
      expect(scene['evidenceStart'], greaterThanOrEqualTo(4));
      expect(
        (scene['duration'] as num) - (scene['evidenceEnd'] as num),
        greaterThanOrEqualTo(4),
      );
      switch (scene['theme']) {
        case 'lateralSwitch':
          expect(metrics['lateralMeters'], greaterThanOrEqualTo(22));
          break;
        case 'pressureSupport':
          expect(metrics['pressureMeters'], lessThanOrEqualTo(6));
          expect(metrics['forwardMeters'], lessThan(10));
          expect(metrics['connectionMeters'], greaterThanOrEqualTo(4));
          break;
        case 'combination':
          expect(anchors, hasLength(3));
          expect(
            (metrics['legMeters'] as List<dynamic>)
                .every((value) => (value as num) >= 5),
            isTrue,
          );
          break;
        default:
          fail('Unapproved generated theme ${scene['theme']}');
      }
    }
  });

  test('quality proof records precise guards, context, owners, and limits', () {
    final proof = _json('assets/scan_pass_spatial/quality-proof.json');
    final scenes =
        (proof['scenes'] as List<dynamic>).cast<Map<String, dynamic>>();
    final reasons = ((proof['counts']
            as Map<String, dynamic>)['rejectedReasons'] as Map<String, dynamic>)
        .keys;
    final safeThemes =
        ((proof['counts'] as Map<String, dynamic>)['validatedSafeThemes']
            as Map<String, dynamic>);
    expect(safeThemes.keys.toSet(), {
      'lateralSwitch',
      'pressureSupport',
      'combination',
    });
    expect(safeThemes.values.every((value) => (value as num) > 0), isTrue);
    expect(scenes, isNotEmpty);
    expect(reasons,
        contains('departure-or-arrival-actor-missing-in-guard-window'));
    expect(reasons, contains('core-actor-has-a-central-visibility-gap'));
    expect(reasons, contains('combination-leg-under-five-metres'));
    expect(reasons, contains('pressure-support-connection-under-four-metres'));
    expect(
      reasons,
      contains('no-20-to-40-second-source-clip-with-four-second-context'),
    );
    for (final scene in scenes) {
      expect(scene['durationSeconds'], inInclusiveRange(20, 40));
      expect(
          scene['maxSourcePlayerSpeedMetersPerSecond'], lessThanOrEqualTo(15));
      expect(scene['maxBallSpeedMetersPerSecond'], lessThanOrEqualTo(50));
      expect(scene['guardWindows'], isNotEmpty);
      expect(
        (scene['guardWindows'] as List<dynamic>).every(
          (value) => (value as Map<String, dynamic>)['coverage'] == 1,
        ),
        isTrue,
      );
      expect(
        (scene['ownedBallVisibility']
            as Map<String, dynamic>)['meaningfulFrames'],
        greaterThan(0),
      );
      expect(
        (scene['opponentContext'] as Map<String, dynamic>)[
            'minimumDirectlyObservedOpponentsPerFrame'],
        greaterThanOrEqualTo(2),
      );
      expect(
        (scene['displayEvidence']
            as Map<String, dynamic>)['reconstructionIncluded'],
        isFalse,
      );
    }
  });

  test('source gates reject short clips and missing guarded/owned actors', () {
    final result = Process.runSync(
      'python3',
      [
        '-c',
        '''from tool.scan_pass_replay.prepare_spatial_library import clip_bounds, guarded_anchor, ownership_visibility
def frame(i, actor=True, owner=2):
 data=[{'trackable_object':1,'x':0.0,'y':0.0}]
 if actor: data.append({'trackable_object':2,'x':1.0,'y':1.0})
 return {'frame':i,'period':1,'time':'0:00','data':data,'possession':{'trackable_object':owner,'group':'home team'}}
short=[frame(i) for i in range(150)]
assert clip_bounds(short,1,1,50,90) is None
guard=[frame(i) for i in range(40)]
guard[20]=frame(20,actor=False)
assert guarded_anchor(guard,2,20) is None
owned=[frame(i) for i in range(20)]
owned[8]=frame(8,actor=False)
assert ownership_visibility(owned,{2:{}},0,19) is None
print('REJECTED')''',
      ],
      workingDirectory: Directory.current.path,
    );
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('REJECTED'));
  });

  test('theme-specific score scales cannot crowd safe themes out', () {
    final result = Process.runSync(
      'python3',
      [
        '-c',
        '''import collections
import tool.scan_pass_replay.prepare_spatial_library as p
p.MAX_VALIDATED_CANDIDATES_PER_MATCH = 3
p.MAX_CATALOG_SCENES = 6
themes = ['lateralSwitch', 'pressureSupport', 'combination']
def candidate(theme, index, score):
 start = index * 10000 + themes.index(theme) * 1000
 return {'theme':theme,'score':score,'matchId':index + 1,'anchorFrame':start,'focusId':index * 10 + themes.index(theme),'startFrame':start,'endFrame':start + 50}
values = []
for index in range(8):
 values.append(candidate('lateralSwitch', index, 100 - index))
 values.append(candidate('pressureSupport', index, 2 - index / 10))
 values.append(candidate('combination', index, 1 - index / 10))
validated, _ = p.validate_candidates(values, 1)
assert {item['theme'] for item in validated} == set(themes), validated
selected, _ = p.choose_catalog_candidates(values)
counts = collections.Counter(item['theme'] for item in selected)
assert counts == collections.Counter({theme:2 for theme in themes}), counts
print('BALANCED')''',
      ],
      workingDirectory: Directory.current.path,
    );
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('BALANCED'));
  });

  test('tiny ownership flips are not selected as teaching connections', () {
    final result = Process.runSync(
      'python3',
      [
        '-c',
        '''from tool.scan_pass_replay.prepare_spatial_library import teaching_travel_rejection
assert teaching_travel_rejection('combination', [4.999, 20]) == 'combination-leg-under-five-metres'
assert teaching_travel_rejection('combination', [5, 5]) is None
assert teaching_travel_rejection('pressureSupport', [3.999]) == 'pressure-support-connection-under-four-metres'
assert teaching_travel_rejection('pressureSupport', [4]) is None
print('REJECTED_TINY_FLIPS')''',
      ],
      workingDirectory: Directory.current.path,
    );
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('REJECTED_TINY_FLIPS'));
  });

  test('generator ships gaps, not zero or reconstructed player positions', () {
    final source = File('tool/scan_pass_replay/prepare_spatial_library.py')
        .readAsStringSync();
    expect(source, contains('MISSING_COORDINATE = -(2**31)'));
    expect(source, contains('"displayFrames": []'));
    expect(source, contains('sourcePossessionOwners'));
    expect(source, contains('validate_ball_speed'));
    expect(source, isNot(contains('reconstruct_display(')));
    expect(source, isNot(contains('StatsBomb')));
  });

  test('raw ball teleport above 50 metres per second is rejected', () {
    final result = Process.runSync(
      'python3',
      [
        '-c',
        'from tool.scan_pass_replay.prepare_spatial_library import '
            'validate_ball_speed\n'
            'try:\n validate_ball_speed([[0,0,0],[501,0,0]])\n'
            'except ValueError:\n print("REJECTED")\n'
            'else:\n raise SystemExit("teleport was accepted")',
      ],
      workingDirectory: Directory.current.path,
    );
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('REJECTED'));
  });
}

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
