import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final rawRoot = Platform.environment['SCAN_PASS_HISTORICAL_RAW_DIR'] ??
      '.tmp/european-replay/source';
  final rawSourcesAvailable = File(
        '$rawRoot/data/matches/4039/structured_data.json',
      ).existsSync() &&
      File(
        '$rawRoot/data/matches/3442/structured_data.json',
      ).existsSync();

  test(
    'historical importer is byte-reproducible and preserves current scenes',
    () async {
      final historicalManifest = jsonDecode(
        File('assets/scan_pass_replay/historical-source-manifest.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      final catalog = jsonDecode(
        File('assets/scan_pass_replay/catalog.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final paths = <String>{
        'assets/scan_pass_replay/historical-source-manifest.json',
        'assets/scan_pass_replay/source-manifest.json',
        'assets/scan_pass_replay/replay-data.json',
        for (final value
            in historicalManifest['derivedAssets'] as List<dynamic>)
          (value as Map<String, dynamic>)['path'] as String,
        for (final value in catalog['scenes'] as List<dynamic>)
          if ((value as Map<String, dynamic>)['sourceCommit'] == null)
            value['asset'] as String,
      };
      final before = <String, List<int>>{
        for (final path in paths) path: File(path).readAsBytesSync(),
      };

      // Other Flutter suites read these assets in parallel. Rebuild in an
      // isolated fixture so this test never truncates a live repository asset.
      final temporaryRoot = Directory('.tmp')..createSync(recursive: true);
      final workspace = temporaryRoot.createTempSync('historical-importer-');
      try {
        final sourceAssets = Directory('assets/scan_pass_replay');
        for (final entry in sourceAssets.listSync(recursive: true)) {
          if (entry is! File) continue;
          final destination = File('${workspace.path}/${entry.path}');
          destination.parent.createSync(recursive: true);
          entry.copySync(destination.path);
        }
        for (final name in <String>[
          'prepare_historical.py',
          'historical_scenes.json',
        ]) {
          final destination =
              File('${workspace.path}/tool/scan_pass_replay/$name');
          destination.parent.createSync(recursive: true);
          File('tool/scan_pass_replay/$name').copySync(destination.path);
        }
        final result = await Process.run(
          'python3',
          <String>[
            'tool/scan_pass_replay/prepare_historical.py',
            Directory(rawRoot).absolute.path,
          ],
          workingDirectory: workspace.absolute.path,
        );
        expect(result.exitCode, 0,
            reason: '${result.stdout}\n${result.stderr}');
        expect(result.stdout, contains('Rebuilt 5 historical scenes'));
        for (final entry in before.entries) {
          expect(
            File('${workspace.path}/${entry.key}').readAsBytesSync(),
            orderedEquals(entry.value),
            reason: 'Rebuilt ${entry.key}',
          );
          expect(
            File(entry.key).readAsBytesSync(),
            orderedEquals(entry.value),
            reason: 'Untouched original ${entry.key}',
          );
        }
      } finally {
        workspace.deleteSync(recursive: true);
      }
    },
    skip: rawSourcesAvailable
        ? false
        : 'Pinned historical raw inputs are intentionally not committed.',
  );
}
