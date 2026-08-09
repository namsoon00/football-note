import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/running_coach_evidence_archive.dart';
import 'package:football_note/application/running_coach_history_service.dart';
import 'package:football_note/domain/entities/running_coach_session.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';
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
      captureContext: const RunningCoachCaptureContext(
        effort: RunningCoachRunEffort.steady,
        surface: RunningCoachRunningSurface.treadmill,
      ),
    );

    final sessions = service.allSessions();
    expect(sessions, hasLength(1));
    expect(sessions.first.overallScore, 62);
    expect(sessions.first.primaryMetric, RunningCoachMetric.footStrike);
    expect(sessions.first.primaryConfidence, 0.72);
    expect(sessions.first.primarySampleCount, 3);
    expect(
      sessions.first.captureContext?.isComparableTo(
        const RunningCoachCaptureContext(
          effort: RunningCoachRunEffort.steady,
          surface: RunningCoachRunningSurface.treadmill,
        ),
      ),
      isTrue,
    );
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
        for (var frameIndex = 0; frameIndex < 30; frameIndex += 1)
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
    expect(
      restored!.poseFrames,
      hasLength(RunningCoachHistoryService.historyPoseFrameLimit),
    );
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

  test('does not retain source-video metadata unless video saving is opted in',
      () async {
    final repository = _MemoryOptionRepository();
    final service = RunningCoachHistoryService(repository);
    const report = RunningCoachingReport(
      overallScore: 86,
      insights: [
        RunningCoachingInsight(
          metric: RunningCoachMetric.posture,
          finding: RunningCoachFinding.postureAligned,
          status: RunningCoachStatus.good,
          score: 86,
          value: 10,
          quality: RunningMetricQuality(confidence: 0.90, sampleCount: 12),
        ),
      ],
    );
    const result = RunningVideoAnalysisResult(
      videoDuration: Duration(seconds: 5),
      sampledFrames: 14,
      validFrames: 12,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 10,
      verticalBounceRatio: 0.06,
      footStrikeDistanceRatio: 0.08,
      stanceKneeAngleDegrees: 155,
      elbowAngleDegrees: 90,
    );

    final saved = await service.saveUploadAnalysis(
      result: result,
      report: report,
      sourceVideoPath: '/private/runner-name-2026.mp4',
      sourceVideoName: 'runner-name-2026.mp4',
      analyzedAt: DateTime(2026, 7, 31, 9),
    );

    expect(saved.single.videoPath, isNull);
    expect(saved.single.videoName, isNull);

    final retained = await service.deleteSession(saved.single.id);
    expect(retained, isEmpty);
    expect(service.allSessions(), isEmpty);
  });

  test('retains selected evidence frames without source video opt-in',
      () async {
    final repository = _MemoryOptionRepository();
    var deletedEvidenceCount = 0;
    final capturedRequestTimestamps = <int>[];
    final service = RunningCoachHistoryService(
      repository,
      archiveEvidenceImages: ({
        required sourceVideo,
        required sessionId,
        required requests,
      }) async {
        capturedRequestTimestamps.addAll(
          requests.map((request) => request.timestamp.inMilliseconds),
        );
        return RunningCoachEvidenceArchiveResult.fromImages(
          requestedCount: requests.length,
          images: <RunningCoachEvidenceImage>[
            for (final request in requests)
              RunningCoachEvidenceImage(
                id: request.id,
                timestamp: request.timestamp,
                kind: request.kind,
                role: request.role,
                storageReference: 'test://${request.id}',
                width: 120,
                height: 80,
              ),
          ],
        );
      },
      deleteEvidenceImages: (images) async {
        deletedEvidenceCount += images.length;
      },
    );
    const report = RunningCoachingReport(
      overallScore: 86,
      insights: [
        RunningCoachingInsight(
          metric: RunningCoachMetric.posture,
          finding: RunningCoachFinding.postureAligned,
          status: RunningCoachStatus.good,
          score: 86,
          value: 10,
          quality: RunningMetricQuality(confidence: 0.90, sampleCount: 6),
        ),
      ],
    );
    final result = RunningVideoAnalysisResult(
      videoDuration: const Duration(seconds: 5),
      sampledFrames: 14,
      validFrames: 12,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 10,
      verticalBounceRatio: 0.06,
      footStrikeDistanceRatio: 0.08,
      stanceKneeAngleDegrees: 155,
      elbowAngleDegrees: 90,
      metricQualities: const <RunningCoachMetric, RunningMetricQuality>{
        RunningCoachMetric.posture: RunningMetricQuality(
          confidence: 0.90,
          sampleCount: 6,
        ),
      },
      poseFrames: [
        for (var frameIndex = 0; frameIndex < 8; frameIndex += 1)
          _poseFrame(frameIndex),
      ],
    );

    final saved = await service.saveUploadAnalysis(
      result: result,
      report: report,
      sourceVideoPath: '/private/not-retained.mp4',
      sourceVideoName: 'not-retained.mp4',
      analyzedAt: DateTime(2026, 8, 2, 9),
    );

    final session = saved.single;
    expect(session.videoPath, isNull);
    expect(session.videoName, isNull);
    expect(session.evidenceImages, isNotEmpty);
    expect(
      session.evidenceImages.map((image) => image.timestamp.inMilliseconds),
      orderedEquals(capturedRequestTimestamps),
    );
    expect(
        capturedRequestTimestamps.toSet(),
        hasLength(
          capturedRequestTimestamps.length,
        ));
    expect(
      session.analysisResult!.poseFrames.map(
        (frame) => frame.timestamp.inMilliseconds,
      ),
      containsAll(capturedRequestTimestamps),
    );

    final retained = await service.deleteSession(session.id);
    expect(retained, isEmpty);
    expect(deletedEvidenceCount, session.evidenceImages.length);
  });

  test('persists evidence archive failure without failing analysis', () async {
    final repository = _MemoryOptionRepository();
    final service = RunningCoachHistoryService(
      repository,
      archiveEvidenceImages: ({
        required sourceVideo,
        required sessionId,
        required requests,
      }) async {
        return RunningCoachEvidenceArchiveResult.failed(
          requestedCount: requests.length,
          failureCode: 'file_write_failed',
        );
      },
    );
    const report = RunningCoachingReport(
      overallScore: 86,
      insights: [
        RunningCoachingInsight(
          metric: RunningCoachMetric.posture,
          finding: RunningCoachFinding.postureAligned,
          status: RunningCoachStatus.good,
          score: 86,
          value: 10,
          quality: RunningMetricQuality(confidence: 0.90, sampleCount: 6),
        ),
      ],
    );
    final result = RunningVideoAnalysisResult(
      videoDuration: const Duration(seconds: 5),
      sampledFrames: 14,
      validFrames: 12,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 10,
      verticalBounceRatio: 0.06,
      footStrikeDistanceRatio: 0.08,
      stanceKneeAngleDegrees: 155,
      elbowAngleDegrees: 90,
      metricQualities: const <RunningCoachMetric, RunningMetricQuality>{
        RunningCoachMetric.posture: RunningMetricQuality(
          confidence: 0.90,
          sampleCount: 6,
        ),
      },
      poseFrames: [
        for (var frameIndex = 0; frameIndex < 3; frameIndex += 1)
          _poseFrame(frameIndex),
      ],
    );

    final saved = await service.saveUploadAnalysis(
      result: result,
      report: report,
      analyzedAt: DateTime(2026, 8, 3, 9),
    );

    final session = saved.single;
    expect(session.evidenceImages, isEmpty);
    expect(session.evidenceArchive.requestedCount, greaterThan(0));
    expect(session.evidenceArchive.savedCount, 0);
    expect(
      session.evidenceArchive.status,
      RunningCoachEvidenceArchiveStatus.failed,
    );
    expect(session.evidenceArchive.failureCode, 'file_write_failed');

    final restored = service.allSessions().single;
    expect(restored.evidenceArchive.requestedCount,
        session.evidenceArchive.requestedCount);
    expect(restored.evidenceArchive.status,
        RunningCoachEvidenceArchiveStatus.failed);
    expect(restored.analysisResult, isNotNull);
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
