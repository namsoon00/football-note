import 'dart:convert';

import 'package:image_picker/image_picker.dart';

import '../domain/entities/running_coach_session.dart';
import '../domain/entities/running_coach_runner_profile.dart';
import '../domain/entities/running_video_analysis_result.dart';
import '../domain/repositories/option_repository.dart';
import 'running_coach_evidence_archive.dart';
import 'running_coach_video_archive.dart';
import 'sport_scoped_storage.dart';

typedef RunningCoachEvidenceImageArchiver
    = Future<RunningCoachEvidenceArchiveResult> Function({
  required XFile? sourceVideo,
  required String sessionId,
  required List<RunningCoachEvidenceFrameRequest> requests,
});

typedef RunningCoachEvidenceImageDeleter = Future<void> Function(
  Iterable<RunningCoachEvidenceImage> images,
);

class RunningCoachHistoryService {
  static const storageKey = 'running_coach_sessions_v1';
  static const maxStoredSessions = 20;

  /// Keep enough timestamped poses for a compact history replay without
  /// exhausting browser-local storage once a runner reaches the history cap.
  static const historyPoseFrameLimit = 24;
  static const historyEvidenceImageLimit = 24;
  static const runningScoreVersion = 2;

  final OptionRepository _options;
  final String? _sportId;
  final RunningCoachEvidenceImageArchiver _archiveEvidenceImages;
  final RunningCoachEvidenceImageDeleter _deleteEvidenceImages;

  RunningCoachHistoryService(
    this._options, {
    String? sportId,
    RunningCoachEvidenceImageArchiver? archiveEvidenceImages,
    RunningCoachEvidenceImageDeleter? deleteEvidenceImages,
  })  : _sportId = sportId,
        _archiveEvidenceImages =
            archiveEvidenceImages ?? archiveRunningCoachEvidenceImages,
        _deleteEvidenceImages =
            deleteEvidenceImages ?? deleteArchivedRunningCoachEvidenceImages;

  String get _storageKey => sportScopedOptionKey(
        _options,
        storageKey,
        sportId: _sportId,
      );

  List<RunningCoachSessionAnalysis> allSessions() {
    final raw = _options.getValue<String>(_storageKey) ?? '[]';
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return const <RunningCoachSessionAnalysis>[];
    }
    if (decoded is! List) {
      return const <RunningCoachSessionAnalysis>[];
    }
    final sessions = decoded
        .whereType<Map>()
        .where((item) {
          final source = item['source']?.toString();
          return source == null ||
              source == RunningCoachSessionSource.uploadVideo.name;
        })
        .map((item) {
          return RunningCoachSessionAnalysis.fromMap(
            item.cast<String, dynamic>(),
          );
        })
        .where((session) => session.id.isNotEmpty)
        .toList(growable: false);
    sessions.sort((a, b) => b.analyzedAt.compareTo(a.analyzedAt));
    return List<RunningCoachSessionAnalysis>.unmodifiable(sessions);
  }

  List<RunningCoachSessionAnalysis> sessionsForRunner(String runnerId) {
    return List<RunningCoachSessionAnalysis>.unmodifiable(
      allSessions().where((session) => session.runnerId == runnerId),
    );
  }

  List<RunningCoachSessionAnalysis> comparableVerifiedSessions({
    required String runnerId,
    required int scoreVersion,
    required int analysisVersion,
    required RunningCoachCaptureContext captureContext,
  }) {
    return List<RunningCoachSessionAnalysis>.unmodifiable(
      sessionsForRunner(runnerId).where(
        (session) =>
            session.scoreEligibility == RunningCoachScoreEligibility.verified &&
            session.scoreVersion == scoreVersion &&
            session.analysisVersion == analysisVersion &&
            captureContext.isComparableTo(session.captureContext),
      ),
    );
  }

  Future<List<RunningCoachSessionAnalysis>> saveUploadAnalysis({
    String runnerId = runningCoachDefaultRunnerId,
    required RunningVideoAnalysisResult result,
    required RunningCoachingReport report,
    RunningCoachCaptureContext? captureContext,
    XFile? sourceVideo,
    String? sourceVideoPath,
    String? sourceVideoName,
    bool saveVideo = false,
    DateTime? analyzedAt,
  }) async {
    final timestamp = analyzedAt ?? DateTime.now();
    final sessionId = 'upload-${timestamp.microsecondsSinceEpoch}';
    final primary = report.primaryFocus ?? report.rankedInsights.first;
    final evidenceRequests = _historyEvidenceFrameRequests(
      result,
      report,
      limit: historyEvidenceImageLimit,
    );
    final evidenceArchiveResult = await _archiveEvidenceImages(
      sourceVideo: sourceVideo,
      sessionId: sessionId,
      requests: evidenceRequests,
    );
    final archivedVideo = saveVideo
        ? await archiveRunningCoachVideo(
            sourcePath: sourceVideoPath,
            sourceName: sourceVideoName,
            timestamp: timestamp,
          )
        : null;
    final existingSessions = allSessions();
    final next = <RunningCoachSessionAnalysis>[
      RunningCoachSessionAnalysis(
        id: sessionId,
        runnerId: runnerId,
        analyzedAt: timestamp,
        source: RunningCoachSessionSource.uploadVideo,
        overallScore: report.overallScore,
        scoreEligibility: _scoreEligibilityFor(result, report),
        scoreVersion: runningScoreVersion,
        analysisVersion: result.analysisVersion,
        duration: result.videoDuration,
        sampledFrames: result.sampledFrames,
        validFrames: result.validFrames,
        primaryMetric: primary.metric,
        primaryFinding: primary.finding,
        primaryStatus: primary.status,
        primaryScore: primary.score,
        primaryValue: primary.value,
        primaryConfidence: primary.quality.confidence,
        primarySampleCount: primary.quality.sampleCount,
        primaryQualityReason: primary.quality.reason,
        metricSnapshots: report.rankedInsights
            .map(RunningCoachSessionMetric.fromInsight)
            .toList(growable: false),
        evidenceImages: evidenceArchiveResult.images,
        evidenceArchive: RunningCoachEvidenceArchiveSummary(
          requestedCount: evidenceArchiveResult.requestedCount,
          savedCount: evidenceArchiveResult.savedCount,
          status: evidenceArchiveResult.status,
          failureCode: evidenceArchiveResult.failureCode,
        ),
        analysisResult: result.historySnapshot(
          maxPoseFrames: historyPoseFrameLimit,
          evidenceTimestamps: evidenceRequests.map(
            (request) => request.timestamp,
          ),
        ),
        captureContext: captureContext,
        videoPath: archivedVideo?.path,
        // Keep neither a reusable path nor the original filename unless the
        // runner explicitly opted into retaining the source video.
        videoName: archivedVideo?.name,
      ),
      ...existingSessions,
    ];
    return _saveTrimmedSessions(next);
  }

  Future<void> clear() async {
    final existingSessions = allSessions();
    await _persist(const <RunningCoachSessionAnalysis>[]);
    await deleteArchivedRunningCoachVideos(
      existingSessions.map((session) => session.videoPath),
    );
    await _deleteEvidenceImages(
      existingSessions.expand((session) => session.evidenceImages),
    );
  }

  Future<List<RunningCoachSessionAnalysis>> clearRunner(String runnerId) async {
    final existingSessions = allSessions();
    final removed = existingSessions
        .where((session) => session.runnerId == runnerId)
        .toList(growable: false);
    final retained = existingSessions
        .where((session) => session.runnerId != runnerId)
        .toList(growable: false);
    await _persist(retained);
    await deleteArchivedRunningCoachVideos(
      removed.map((session) => session.videoPath),
    );
    await _deleteEvidenceImages(
      removed.expand((session) => session.evidenceImages),
    );
    return List<RunningCoachSessionAnalysis>.unmodifiable(retained);
  }

  Future<List<RunningCoachSessionAnalysis>> deleteSession(
      String sessionId) async {
    final existingSessions = allSessions();
    final removed = existingSessions
        .where((session) => session.id == sessionId)
        .toList(growable: false);
    if (removed.isEmpty) return existingSessions;
    final retained = existingSessions
        .where((session) => session.id != sessionId)
        .toList(growable: false);
    await _persist(retained);
    await deleteArchivedRunningCoachVideos(
      removed.map((session) => session.videoPath),
    );
    await _deleteEvidenceImages(
      removed.expand((session) => session.evidenceImages),
    );
    return List<RunningCoachSessionAnalysis>.unmodifiable(retained);
  }

  Future<void> _persist(List<RunningCoachSessionAnalysis> sessions) async {
    final payload = jsonEncode(
      sessions
          .map(
            (session) => session.toMap(
              maxPoseFrames: historyPoseFrameLimit,
            ),
          )
          .toList(growable: false),
    );
    await _options.setValue(_storageKey, payload);
  }

  Future<List<RunningCoachSessionAnalysis>> _saveTrimmedSessions(
    List<RunningCoachSessionAnalysis> sessions,
  ) async {
    final trimmed = _trimSessions(sessions);
    await _persist(trimmed.retained);
    await deleteArchivedRunningCoachVideos(
      trimmed.removed.map((session) => session.videoPath),
    );
    await _deleteEvidenceImages(
      trimmed.removed.expand((session) => session.evidenceImages),
    );
    return List<RunningCoachSessionAnalysis>.unmodifiable(trimmed.retained);
  }

  _RunningCoachHistoryTrim _trimSessions(
    List<RunningCoachSessionAnalysis> sessions,
  ) {
    final ordered = List<RunningCoachSessionAnalysis>.from(sessions)
      ..sort((left, right) => right.analyzedAt.compareTo(left.analyzedAt));
    final retained = ordered.take(maxStoredSessions).toList(growable: false);
    final retainedIds = retained.map((session) => session.id).toSet();
    final removed = ordered
        .where((session) => !retainedIds.contains(session.id))
        .toList(growable: false);
    return _RunningCoachHistoryTrim(
      retained: List<RunningCoachSessionAnalysis>.unmodifiable(retained),
      removed: removed,
    );
  }
}

RunningCoachScoreEligibility _scoreEligibilityFor(
  RunningVideoAnalysisResult result,
  RunningCoachingReport report,
) {
  final hasCompleteEvidence =
      report.insights.length == RunningCoachMetric.values.length &&
          report.insights
              .every((insight) => insight.quality.isReliableForCoaching) &&
          RunningCoachMetric.values.every(
            (metric) => result.evidenceForMetric(metric)?.isReliable == true,
          );
  if (hasCompleteEvidence &&
      report.scoreStatus == RunningCoachScoreStatus.confirmed) {
    return RunningCoachScoreEligibility.verified;
  }
  if (report.scoreStatus == RunningCoachScoreStatus.estimated) {
    return RunningCoachScoreEligibility.estimated;
  }
  return RunningCoachScoreEligibility.unavailable;
}

List<RunningCoachEvidenceFrameRequest> _historyEvidenceFrameRequests(
  RunningVideoAnalysisResult result,
  RunningCoachingReport report, {
  required int limit,
}) {
  final orderedEvidence = result.metricEvidence
      .where(
        (evidence) => evidence.frames.any((frame) => frame.poseFrame != null),
      )
      .toList(growable: false);
  final requests = <RunningCoachEvidenceFrameRequest>[];
  // Distribute real captures across every available metric. Two passes first
  // guarantee up to two captures per metric; passes three and four fill the
  // remaining budget without allowing the primary metric to monopolize it.
  for (var round = 0; round < 4 && requests.length < limit; round += 1) {
    for (final evidence in orderedEvidence) {
      final frames = evidence.frames
          .where((frame) => frame.poseFrame != null)
          .take(4)
          .toList(growable: false);
      if (round >= frames.length) continue;
      final frame = frames[round];
      if (frame.poseFrame == null) continue;
      final timestampMs = frame.timestamp.inMilliseconds;
      requests.add(
        RunningCoachEvidenceFrameRequest(
          id: '${evidence.kind.name}-${frame.role.name}-$timestampMs-$round',
          timestamp: frame.timestamp,
          kind: evidence.kind,
          role: frame.role,
          side: frame.side,
          values: frame.values,
          confidence: frame.confidence,
          poseFrame: frame.poseFrame,
        ),
      );
      if (requests.length >= limit) {
        return List<RunningCoachEvidenceFrameRequest>.unmodifiable(requests);
      }
    }
  }
  return List<RunningCoachEvidenceFrameRequest>.unmodifiable(requests);
}

class _RunningCoachHistoryTrim {
  final List<RunningCoachSessionAnalysis> retained;
  final List<RunningCoachSessionAnalysis> removed;

  const _RunningCoachHistoryTrim({
    required this.retained,
    required this.removed,
  });
}
