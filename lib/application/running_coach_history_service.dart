import 'dart:convert';

import '../domain/entities/running_coach_session.dart';
import '../domain/entities/running_video_analysis_result.dart';
import '../domain/repositories/option_repository.dart';

class RunningCoachHistoryService {
  static const storageKey = 'running_coach_sessions_v1';
  static const maxStoredSessions = 8;

  final OptionRepository _options;

  const RunningCoachHistoryService(this._options);

  List<RunningCoachSessionAnalysis> allSessions() {
    final raw = _options.getValue<String>(storageKey) ?? '[]';
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
    DateTime? analyzedAt,
  }) async {
    final timestamp = analyzedAt ?? DateTime.now();
    final primary = report.primaryFocus ?? report.rankedInsights.first;
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
      ),
      ...allSessions(),
    ];
    final trimmed = next.take(maxStoredSessions).toList(growable: false);
    await _persist(trimmed);
    return List<RunningCoachSessionAnalysis>.unmodifiable(trimmed);
  }

  Future<void> clear() async {
    await _persist(const <RunningCoachSessionAnalysis>[]);
  }

  Future<void> _persist(List<RunningCoachSessionAnalysis> sessions) async {
    final payload = jsonEncode(
      sessions.map((session) => session.toMap()).toList(growable: false),
    );
    await _options.setValue(storageKey, payload);
  }
}
