import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/running_coach_history_service.dart';
import 'package:football_note/application/running_coach_runner_profile_service.dart';
import 'package:football_note/domain/entities/running_coach_runner_profile.dart';
import 'package:football_note/domain/entities/running_coach_session.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';
import 'package:football_note/domain/repositories/option_repository.dart';

void main() {
  test('creates a default runner without blocking first analysis', () async {
    final repository = _MemoryOptionRepository();
    final service = RunningCoachRunnerProfileService(repository);

    final selected = await service.ensureDefaultRunner(
      defaultDisplayName: 'Me',
    );

    expect(selected.id, runningCoachDefaultRunnerId);
    expect(selected.displayName, 'Me');
    expect(service.profiles(defaultDisplayName: 'Me'), hasLength(1));
    expect(
      repository
          .values[RunningCoachRunnerProfileService.selectedRunnerStorageKey],
      runningCoachDefaultRunnerId,
    );
  });

  test('restores the last runner and safely archives non-default runners',
      () async {
    final repository = _MemoryOptionRepository();
    final service = RunningCoachRunnerProfileService(repository);
    await service.ensureDefaultRunner(defaultDisplayName: 'Me');
    final added = await service.addRunner(
      displayName: 'Minjun',
      defaultDisplayName: 'Me',
      createdAt: DateTime(2026, 8, 10),
    );

    final restored = RunningCoachRunnerProfileService(repository)
        .selectedProfile(defaultDisplayName: 'Me');
    expect(restored.id, added.id);

    await service.archiveRunner(
      runnerId: added.id,
      defaultDisplayName: 'Me',
    );
    expect(
      service.selectedProfile(defaultDisplayName: 'Me').id,
      runningCoachDefaultRunnerId,
    );
    await service.archiveRunner(
      runnerId: runningCoachDefaultRunnerId,
      defaultDisplayName: 'Me',
    );
    expect(
      service.profiles(defaultDisplayName: 'Me').single.archived,
      isFalse,
    );
  });

  test('legacy sessions migrate to default runner without losing evidence',
      () async {
    final repository = _MemoryOptionRepository();
    final legacy = _sessionMap(id: 'legacy')
      ..remove('runnerId')
      ..['evidenceImages'] = <Map<String, Object?>>[
        <String, Object?>{
          'id': 'legacy-image',
          'timestampMs': 900,
          'kind': RunningMetricEvidenceKind.posture.name,
          'role': RunningMetricEvidenceFrameRole.representativePosture.name,
          'storageReference': '/local/legacy.jpg',
          'confidence': 0.9,
        },
      ];
    await repository.setValue(
      RunningCoachHistoryService.storageKey,
      jsonEncode(<Map<String, Object?>>[legacy]),
    );

    final restored =
        RunningCoachHistoryService(repository).allSessions().single;

    expect(restored.runnerId, runningCoachDefaultRunnerId);
    expect(restored.evidenceImages.single.id, 'legacy-image');
    expect(restored.copyWith(runnerId: 'runner-a').runnerId, 'runner-a');
    expect(restored.toMap()['runnerId'], runningCoachDefaultRunnerId);
  });

  test('comparison queries never mix runner, version, or score status',
      () async {
    final repository = _MemoryOptionRepository();
    const context = RunningCoachCaptureContext(
      effort: RunningCoachRunEffort.steady,
      surface: RunningCoachRunningSurface.trackOrRoad,
    );
    final maps = <Map<String, Object?>>[
      _sessionMap(id: 'same-runner', runnerId: 'runner-a'),
      _sessionMap(id: 'other-runner', runnerId: 'runner-b'),
      _sessionMap(
        id: 'estimated',
        runnerId: 'runner-a',
        eligibility: RunningCoachScoreEligibility.estimated,
      ),
      _sessionMap(id: 'old-analysis', runnerId: 'runner-a')
        ..['analysisVersion'] = 1,
    ];
    await repository.setValue(
      RunningCoachHistoryService.storageKey,
      jsonEncode(maps),
    );
    final service = RunningCoachHistoryService(repository);

    final comparable = service.comparableVerifiedSessions(
      runnerId: 'runner-a',
      scoreVersion: RunningCoachHistoryService.runningScoreVersion,
      analysisVersion: 2,
      captureContext: context,
    );

    expect(comparable.map((session) => session.id), <String>['same-runner']);
    expect(service.sessionsForRunner('runner-b').single.id, 'other-runner');
  });
}

Map<String, Object?> _sessionMap({
  required String id,
  String runnerId = runningCoachDefaultRunnerId,
  RunningCoachScoreEligibility eligibility =
      RunningCoachScoreEligibility.verified,
}) {
  return RunningCoachSessionAnalysis(
    id: id,
    runnerId: runnerId,
    analyzedAt: DateTime(2026, 8, 10, 10),
    source: RunningCoachSessionSource.uploadVideo,
    overallScore: 82,
    scoreEligibility: eligibility,
    scoreVersion: RunningCoachHistoryService.runningScoreVersion,
    analysisVersion: 2,
    duration: const Duration(seconds: 6),
    sampledFrames: 20,
    validFrames: 18,
    primaryMetric: RunningCoachMetric.posture,
    primaryFinding: RunningCoachFinding.postureAligned,
    primaryStatus: RunningCoachStatus.good,
    primaryScore: 88,
    primaryValue: 9,
    primaryConfidence: 0.9,
    captureContext: const RunningCoachCaptureContext(
      effort: RunningCoachRunEffort.steady,
      surface: RunningCoachRunningSurface.trackOrRoad,
    ),
  ).toMap();
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, Object?> values = <String, Object?>{};

  @override
  List<int> getIntOptions(String key, List<int> defaults) => defaults;

  @override
  List<String> getOptions(String key, List<String> defaults) => defaults;

  @override
  T? getValue<T>(String key) {
    final value = values[key];
    return value is T ? value : null;
  }

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    values[key] = options;
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    values[key] = value;
  }
}
