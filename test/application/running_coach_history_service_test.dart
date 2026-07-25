import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/running_coach_history_service.dart';
import 'package:football_note/application/running_live_session_metrics.dart';
import 'package:football_note/application/sprint_live_session_metrics.dart';
import 'package:football_note/domain/entities/running_live_coaching_state.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';
import 'package:football_note/domain/entities/sprint_realtime_coaching_state.dart';
import 'package:football_note/domain/repositories/option_repository.dart';

void main() {
  test('saves recent upload analyses with primary focus', () async {
    final repository = _MemoryOptionRepository();
    final service = RunningCoachHistoryService(repository);
    const report = RunningCoachingReport(
      overallScore: 62,
      insights: [
        RunningCoachingInsight(
          metric: RunningCoachMetric.footStrike,
          finding: RunningCoachFinding.footStrikeOverstride,
          status: RunningCoachStatus.needsWork,
          score: 58,
          value: 0.22,
          quality: RunningMetricQuality(confidence: 0.72, sampleCount: 3),
        ),
      ],
    );
    const result = RunningVideoAnalysisResult(
      videoDuration: Duration(seconds: 5),
      sampledFrames: 14,
      validFrames: 10,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 9,
      verticalBounceRatio: 0.07,
      footStrikeDistanceRatio: 0.22,
      stanceKneeAngleDegrees: 160,
      elbowAngleDegrees: 88,
    );

    await service.saveUploadAnalysis(
      result: result,
      report: report,
      analyzedAt: DateTime(2026, 5, 5, 12),
    );

    final sessions = service.allSessions();
    expect(sessions, hasLength(1));
    expect(sessions.first.overallScore, 62);
    expect(sessions.first.primaryMetric, RunningCoachMetric.footStrike);
    expect(sessions.first.primaryConfidence, 0.72);
  });

  test('persists a compact measured replay with an upload analysis', () async {
    final repository = _MemoryOptionRepository();
    final service = RunningCoachHistoryService(repository);
    const report = RunningCoachingReport(
      overallScore: 71,
      insights: [
        RunningCoachingInsight(
          metric: RunningCoachMetric.footStrike,
          finding: RunningCoachFinding.footStrikeOverstride,
          status: RunningCoachStatus.watch,
          score: 68,
          value: 0.21,
          quality: RunningMetricQuality(confidence: 0.84, sampleCount: 10),
        ),
      ],
    );
    final result = RunningVideoAnalysisResult(
      videoDuration: const Duration(seconds: 5),
      sampledFrames: 14,
      validFrames: 12,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 10,
      verticalBounceRatio: 0.07,
      footStrikeDistanceRatio: 0.21,
      stanceKneeAngleDegrees: 154,
      elbowAngleDegrees: 92,
      metricQualities: const <RunningCoachMetric, RunningMetricQuality>{
        RunningCoachMetric.footStrike: RunningMetricQuality(
          confidence: 0.84,
          sampleCount: 10,
        ),
      },
      poseFrames: [
        for (var frameIndex = 0; frameIndex < 12; frameIndex += 1)
          _poseFrame(frameIndex),
      ],
      validatedContactFrameTimestamps: const <Duration>[
        Duration(milliseconds: 500),
        Duration(milliseconds: 900),
      ],
      contactConfidence: 0.84,
    );

    await service.saveUploadAnalysis(
      result: result,
      report: report,
      analyzedAt: DateTime(2026, 7, 26, 12),
    );

    final restored = service.allSessions().single.analysisResult;
    expect(restored, isNotNull);
    expect(restored!.poseFrames, hasLength(8));
    expect(restored.poseFrames.first.timestamp, Duration.zero);
    expect(
      restored.poseFrames.map((frame) => frame.timestamp.inMilliseconds),
      containsAll(<int>[500, 900]),
    );
    expect(restored.qualityFor(RunningCoachMetric.footStrike)!.confidence,
        closeTo(0.84, 0.0001));
    expect(restored.validatedContactFrameTimestamps, const <Duration>[
      Duration(milliseconds: 500),
      Duration(milliseconds: 900),
    ]);
  });

  test('retains a longer lightweight live sprint history for trends', () async {
    final repository = _MemoryOptionRepository();
    final service = RunningCoachHistoryService(repository);
    const runningSnapshot = RunningLiveSessionMetricsSnapshot.initial();
    const sprintSnapshot = SprintLiveSessionMetricsSnapshot.initial();
    const runningState = RunningLiveCoachingState(
      primaryCue: RunningLivePrimaryCue.keepRunning,
    );
    const sprintState = SprintRealtimeCoachingState.initial();

    for (var index = 0;
        index <= RunningCoachHistoryService.maxStoredLiveSprintSessions;
        index += 1) {
      await service.saveLiveSprintSession(
        sessionId: 'live-$index',
        completedAt: DateTime(2026, 7, 1).add(Duration(minutes: index)),
        runningSnapshot: runningSnapshot,
        sprintSnapshot: sprintSnapshot,
        runningState: runningState,
        sprintState: sprintState,
      );
    }

    final sessions = service.allSessions();
    expect(
      sessions,
      hasLength(RunningCoachHistoryService.maxStoredLiveSprintSessions),
    );
    expect(sessions.first.id, 'live-24');
    expect(sessions.map((session) => session.id), isNot(contains('live-0')));
  });
}

RunningPoseFrame _poseFrame(int frameIndex) {
  return RunningPoseFrame(
    timestamp: Duration(milliseconds: frameIndex * 100),
    imageWidth: 720,
    imageHeight: 1280,
    landmarks: List<RunningVideoPoseLandmark>.unmodifiable(
      List<RunningVideoPoseLandmark>.generate(
        mediaPipePoseLandmarkCount,
        (index) => RunningVideoPoseLandmark(
          index: index,
          x: 0.20 + (index * 0.009) + (frameIndex * 0.002),
          y: 0.15 + (index * 0.011),
          z: 0,
          visibility: 0.96,
          presence: 0.96,
          confidence: 0.96,
        ),
      ),
    ),
  );
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> values = <String, dynamic>{};

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = values[key];
    if (value is List) {
      return value.map((item) => int.tryParse('$item') ?? 0).toList();
    }
    return List<int>.from(defaults);
  }

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = values[key];
    if (value is List) {
      return value.map((item) => '$item').toList();
    }
    return List<String>.from(defaults);
  }

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
