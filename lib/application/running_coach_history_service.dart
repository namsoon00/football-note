import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/entities/running_coach_session.dart';
import '../domain/entities/running_video_analysis_result.dart';
import '../domain/repositories/option_repository.dart';
import 'sport_scoped_storage.dart';

class RunningCoachHistoryService {
  static const storageKey = 'running_coach_sessions_v1';
  static const maxStoredSessions = 8;

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
    DateTime? analyzedAt,
  }) async {
    final timestamp = analyzedAt ?? DateTime.now();
    final primary = report.primaryFocus ?? report.rankedInsights.first;
    final archivedVideo = await _archiveVideo(
      sourcePath: sourceVideoPath,
      sourceName: sourceVideoName,
      timestamp: timestamp,
    );
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
        videoPath: archivedVideo?.path,
        videoName: archivedVideo?.name ?? sourceVideoName,
      ),
      ...existingSessions,
    ];
    final trimmed = next.take(maxStoredSessions).toList(growable: false);
    final removed = next.skip(maxStoredSessions).toList(growable: false);
    await _persist(trimmed);
    await _deleteArchivedVideos(removed);
    return List<RunningCoachSessionAnalysis>.unmodifiable(trimmed);
  }

  Future<void> clear() async {
    final existingSessions = allSessions();
    await _persist(const <RunningCoachSessionAnalysis>[]);
    await _deleteArchivedVideos(existingSessions);
  }

  Future<void> _persist(List<RunningCoachSessionAnalysis> sessions) async {
    final payload = jsonEncode(
      sessions.map((session) => session.toMap()).toList(growable: false),
    );
    await _options.setValue(_storageKey, payload);
  }

  Future<_ArchivedRunningVideo?> _archiveVideo({
    required String? sourcePath,
    required String? sourceName,
    required DateTime timestamp,
  }) async {
    if (sourcePath == null || sourcePath.trim().isEmpty) {
      return null;
    }
    try {
      final source = File(sourcePath);
      if (!await source.exists()) {
        return null;
      }
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final archiveDirectory = Directory(
        '${documentsDirectory.path}${Platform.pathSeparator}running_coach_videos',
      );
      if (!await archiveDirectory.exists()) {
        await archiveDirectory.create(recursive: true);
      }
      final extension = _safeVideoExtension(sourceName ?? source.path);
      final archivedName =
          'running-coach-${timestamp.microsecondsSinceEpoch}$extension';
      final destination = File(
        '${archiveDirectory.path}${Platform.pathSeparator}$archivedName',
      );
      await source.copy(destination.path);
      return _ArchivedRunningVideo(
        path: destination.path,
        name:
            sourceName?.trim().isNotEmpty == true ? sourceName! : archivedName,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _deleteArchivedVideos(
    List<RunningCoachSessionAnalysis> sessions,
  ) async {
    for (final session in sessions) {
      final path = session.videoPath;
      if (path == null || path.isEmpty) {
        continue;
      }
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Best-effort cleanup; history persistence should not fail on storage IO.
      }
    }
  }

  String _safeVideoExtension(String name) {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == name.length - 1) {
      return '.mp4';
    }
    final extension = name.substring(dotIndex).toLowerCase();
    final safe = RegExp(r'^\.[a-z0-9]{2,8}$').hasMatch(extension);
    return safe ? extension : '.mp4';
  }
}

class _ArchivedRunningVideo {
  final String path;
  final String name;

  const _ArchivedRunningVideo({required this.path, required this.name});
}
