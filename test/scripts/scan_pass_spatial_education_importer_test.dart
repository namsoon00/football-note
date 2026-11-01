import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('education asset verifier recomputes every accepted lesson', () async {
    final result = await Process.run(
      'python3',
      <String>[
        'tool/scan_pass_replay/prepare_spatial_education.py',
        '--verify-assets',
      ],
      workingDirectory: Directory.current.path,
    );
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('Verified education catalogue'));
  });

  test('audit records proof failures instead of quotas or fabricated lessons',
      () {
    final proof = jsonDecode(
      File('assets/scan_pass_spatial/education-proof.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final archive =
        (proof['archiveAudit'] as List<dynamic>).cast<Map<String, dynamic>>();
    final recent = (proof['recentRejections'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(archive, hasLength(72));
    expect(
      archive.where((value) => value['accepted'] == false),
      isNotEmpty,
    );
    expect(
      archive
          .where((value) => value['accepted'] == false)
          .every((value) => value['rejectedRules'] is Map<String, dynamic>),
      isTrue,
    );
    expect(
      recent.map((value) => value['reason']),
      contains('overlaps-stronger-observed-lesson'),
    );
    expect(
      proof['rules']['tolerance'],
      contains('0.01 m two-point quantization bound'),
    );
    final rejectedRules = <String>{
      for (final decision in archive)
        ...((decision['rejectedRules'] as Map<String, dynamic>)
            .values
            .cast<String>()),
      for (final decision in recent)
        if (decision['rules'] is Map<String, dynamic>)
          ...((decision['rules'] as Map<String, dynamic>)
              .values
              .cast<String>()),
    };
    expect(
      rejectedRules,
      containsAll(<String>{
        'no-defender-on-finite-passing-segment',
        'receiver-motion-angle-contribution-under-1-degree',
        'defender-too-far-from-baseline-pass-line',
        'receiver-does-not-create-line-clearance',
        'no-uninterrupted-controlled-same-team-connection',
        'third-player-sequence-is-interrupted',
      }),
    );
    expect(
      (proof['attemptedRecentMatches'] as List<dynamic>)
          .map((value) => value['matchId'])
          .toSet(),
      <int>{1925299, 1996435},
    );
  });

  test(
      'recent source manifest pins full tracking and direct detection semantics',
      () {
    final manifest = jsonDecode(
      File('assets/scan_pass_spatial/education-source-manifest.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(manifest['commit'], '4340d274572876239c154c90bc507a9b3250a656');
    expect(manifest['matchIds'], <int>[1925299, 1996435]);
    expect(manifest['sourceSemantics'], contains('is_detected'));
    expect(manifest['archivePreservation']['fileCount'], 115);
    final tracking = (manifest['files'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where(
          (value) => (value['path'] as String).endsWith(
            'tracking_extrapolated.jsonl',
          ),
        )
        .toList(growable: false);
    expect(tracking, hasLength(2));
    for (final file in tracking) {
      expect(file['bytes'], greaterThan(80 * 1024 * 1024));
      expect(file['sha256'], hasLength(64));
      expect(
        file['url'],
        'https://media.githubusercontent.com/media/SkillCorner/opendata/'
        '4340d274572876239c154c90bc507a9b3250a656/${file['path']}',
      );
    }
  });
}
