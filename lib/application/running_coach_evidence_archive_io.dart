import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/entities/running_coach_session.dart';
import 'running_coach_evidence_archive_types.dart';

const _channel = MethodChannel('football_note/running_pose_analysis');
const _maximumImageDimension = 640;

Future<RunningCoachEvidenceArchiveResult> archiveRunningCoachEvidenceImages({
  required XFile? sourceVideo,
  required String sessionId,
  required List<RunningCoachEvidenceFrameRequest> requests,
}) async {
  if (requests.isEmpty) {
    return RunningCoachEvidenceArchiveResult.notRequested();
  }
  if (sourceVideo == null) {
    return RunningCoachEvidenceArchiveResult.failed(
      requestedCount: requests.length,
      failureCode: 'source_video_unavailable',
    );
  }
  final sourcePath = sourceVideo.path.trim();
  if (sourcePath.isEmpty || !await File(sourcePath).exists()) {
    return RunningCoachEvidenceArchiveResult.failed(
      requestedCount: requests.length,
      failureCode: 'source_video_unavailable',
    );
  }
  try {
    final raw = await _channel.invokeMethod<List<Object?>>(
      'extractRunningEvidenceFrames',
      <String, Object?>{
        'path': sourcePath,
        'timestampsMs': requests
            .map((request) => request.timestamp.inMilliseconds)
            .toList(growable: false),
        'maxDimension': _maximumImageDimension,
      },
    );
    if (raw == null || raw.isEmpty) {
      return RunningCoachEvidenceArchiveResult.failed(
        requestedCount: requests.length,
        failureCode: 'no_evidence_frames_extracted',
      );
    }
    final archiveDirectory = await _archiveDirectory(create: true);
    if (archiveDirectory == null) {
      return RunningCoachEvidenceArchiveResult.failed(
        requestedCount: requests.length,
        failureCode: 'archive_directory_unavailable',
      );
    }
    final requestsByTimestamp = <int, RunningCoachEvidenceFrameRequest>{
      for (final request in requests) request.timestamp.inMilliseconds: request,
    };
    final archived = <RunningCoachEvidenceImage>[];
    var failureCode = raw.length < requests.length
        ? 'partial_evidence_frames_extracted'
        : null;
    for (final item in raw) {
      if (item is! Map) continue;
      final timestampMs = _intValue(item['timestampMs']);
      final request = requestsByTimestamp[timestampMs];
      final bytes = item['bytes'];
      if (request == null || bytes is! Uint8List || bytes.isEmpty) continue;
      final safeId = request.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final filename = '$sessionId-$safeId.jpg';
      final destination = File(
        '${archiveDirectory.path}${Platform.pathSeparator}$filename',
      );
      try {
        await destination.writeAsBytes(bytes, flush: true);
      } on FileSystemException {
        failureCode ??= 'file_write_failed';
        continue;
      }
      archived.add(
        RunningCoachEvidenceImage(
          id: request.id,
          timestamp: request.timestamp,
          kind: request.kind,
          role: request.role,
          storageReference: destination.path,
          width: _intValue(item['width']),
          height: _intValue(item['height']),
        ),
      );
    }
    return RunningCoachEvidenceArchiveResult.fromImages(
      requestedCount: requests.length,
      images: archived,
      failureCode: failureCode,
    );
  } on PlatformException catch (error) {
    return RunningCoachEvidenceArchiveResult.failed(
      requestedCount: requests.length,
      failureCode:
          error.code.isEmpty ? 'platform_extraction_failed' : error.code,
    );
  } on FileSystemException {
    return RunningCoachEvidenceArchiveResult.failed(
      requestedCount: requests.length,
      failureCode: 'file_system_failed',
    );
  } catch (_) {
    // Saving a history still is optional. An unsupported platform channel or
    // a decoder failure must not turn a completed pose analysis into a failed
    // coaching result.
    return RunningCoachEvidenceArchiveResult.failed(
      requestedCount: requests.length,
      failureCode: 'evidence_archive_failed',
    );
  }
}

Future<Uint8List?> readArchivedRunningCoachEvidenceImage(
  RunningCoachEvidenceImage image,
) async {
  final path = image.storageReference;
  if (path.isEmpty) return null;
  final archiveDirectory = await _archiveDirectory();
  if (archiveDirectory == null || !await archiveDirectory.exists()) return null;
  try {
    final archiveRoot = await archiveDirectory.resolveSymbolicLinks();
    final file = File(path);
    if (!await file.exists()) return null;
    final resolvedFile = await file.resolveSymbolicLinks();
    if (!_isManagedArchivePath(resolvedFile, archiveRoot)) return null;
    return file.readAsBytes();
  } on FileSystemException {
    return null;
  } catch (_) {
    return null;
  }
}

Future<void> deleteArchivedRunningCoachEvidenceImages(
  Iterable<RunningCoachEvidenceImage> images,
) async {
  // Most normal history writes do not evict a session. Avoid touching the
  // platform path-provider channel when there is nothing to delete so this
  // optional cleanup stays a no-op in pure Dart tests and unsupported hosts.
  if (images.isEmpty) return;
  final archiveDirectory = await _archiveDirectory();
  if (archiveDirectory == null || !await archiveDirectory.exists()) return;
  String archiveRoot;
  try {
    archiveRoot = await archiveDirectory.resolveSymbolicLinks();
  } on FileSystemException {
    return;
  } catch (_) {
    return;
  }
  for (final image in images) {
    if (image.storageReference.isEmpty) continue;
    try {
      final file = File(image.storageReference);
      if (!await file.exists()) continue;
      final resolvedFile = await file.resolveSymbolicLinks();
      if (!_isManagedArchivePath(resolvedFile, archiveRoot)) continue;
      await file.delete();
    } on FileSystemException {
      // History cleanup is best effort.
    } catch (_) {
      // A stale or unsupported reference must not prevent the rest of the
      // evidence archive from being cleaned up.
    }
  }
}

Future<Directory?> _archiveDirectory({bool create = false}) async {
  try {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}running_coach_evidence',
    );
    if (create && !await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  } on FileSystemException {
    return null;
  }
}

bool _isManagedArchivePath(String resolvedFilePath, String archiveRoot) {
  final prefix = archiveRoot.endsWith(Platform.pathSeparator)
      ? archiveRoot
      : '$archiveRoot${Platform.pathSeparator}';
  return resolvedFilePath.startsWith(prefix);
}

int _intValue(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
