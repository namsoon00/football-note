import 'dart:convert';
import '../domain/entities/running_coach_session.dart';
import '../domain/entities/running_video_analysis_result.dart';
import '../domain/repositories/option_repository.dart';
import 'running_coach_video_archive.dart';
import 'sport_scoped_storage.dart';

class RunningCoachHistoryService {
  static const storageKey = 'running_coach_sessions_v1';
  static const maxStoredSessions = 20;

  final OptionRepository _options;
  final String? _sportId;

  const RunningCoachHistoryService(this._options, {String? sportId})
      : _sportId = sportId;

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

  Future<List<RunningCoachSessionAnalysis>> saveUploadAnalysis({
    required RunningVideoAnalysisResult result,
    required RunningCoachingReport report,
    String? sourceVideoPath,
    String? sourceVideoName,
    bool saveVideo = false,
    DateTime? analyzedAt,
  }) async {
    final timestamp = analyzedAt ?? DateTime.now();
    final primary = report.primaryFocus ?? report.rankedInsights.first;
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
        id: 'upload-${timestamp.microsecondsSinceEpoch}',
        analyzedAt: timestamp,
        source: RunningCoachSessionSource.uploadVideo,
        overallScore: report.overallScore,
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
        analysisResult: result.historySnapshot(),
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
    return List<RunningCoachSessionAnalysis>.unmodifiable(retained);
  }

  Future<void> _persist(List<RunningCoachSessionAnalysis> sessions) async {
    final payload = jsonEncode(
      sessions.map((session) => session.toMap()).toList(growable: false),
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

class _RunningCoachHistoryTrim {
  final List<RunningCoachSessionAnalysis> retained;
  final List<RunningCoachSessionAnalysis> removed;

  const _RunningCoachHistoryTrim({
    required this.retained,
    required this.removed,
  });
}
