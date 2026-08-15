import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/entities/running_coach_session.dart';
import 'running_coach_evidence_archive_types.dart';

const _channel = MethodChannel('football_note/running_pose_analysis');
const _maximumEvidenceFrames = 24;
const _maximumEvidenceJpegBytes = 700 * 1024;
const _maximumEvidenceArchiveBytes = 12 * 1024 * 1024;
const _evidenceRetryDimensions = <int>[640, 480, 360];
const _evidenceRetryQualities = <int>[72, 64, 56];
const _evidenceArchiveTimeoutFailureCode = 'evidence_archive_timeout';

Future<RunningCoachEvidenceArchiveResult> archiveRunningCoachEvidenceImages({
  required XFile? sourceVideo,
  required String sessionId,
  required List<RunningCoachEvidenceFrameRequest> requests,
  DateTime? deadline,
}) async {
  if (requests.isEmpty) {
    return RunningCoachEvidenceArchiveResult.notRequested();
  }
  if (_deadlineHasExpired(deadline)) {
    return RunningCoachEvidenceArchiveResult.failed(
      requestedCount: requests.length,
      failureCode: _evidenceArchiveTimeoutFailureCode,
    );
  }
  if (sourceVideo == null) {
    return RunningCoachEvidenceArchiveResult.failed(
      requestedCount: requests.length,
      failureCode: 'source_video_unavailable',
    );
  }
  final sourcePath = sourceVideo.path.trim();
  final sourceExists = await _beforeDeadline(
    File(sourcePath).exists(),
    deadline,
    fallback: false,
  );
  if (sourcePath.isEmpty || sourceExists != true) {
    return RunningCoachEvidenceArchiveResult.failed(
      requestedCount: requests.length,
      failureCode: 'source_video_unavailable',
    );
  }
  try {
    final uniqueTimestamps = requests
        .map((request) => request.timestamp.inMilliseconds)
        .toSet()
        .toList(growable: false)
      ..sort();
    final archiveDirectory = await _beforeDeadline(
      _archiveDirectory(create: true),
      deadline,
    );
    if (archiveDirectory == null) {
      return RunningCoachEvidenceArchiveResult.failed(
        requestedCount: requests.length,
        failureCode: 'archive_directory_unavailable',
      );
    }
    final requestsByTimestamp = <int, List<RunningCoachEvidenceFrameRequest>>{};
    for (final request in requests) {
      requestsByTimestamp
          .putIfAbsent(request.timestamp.inMilliseconds, () => [])
          .add(request);
    }
    final archived = <RunningCoachEvidenceImage>[];
    var totalBytes = 0;
    var failureCode = uniqueTimestamps.length > _maximumEvidenceFrames
        ? 'evidence_frame_limit'
        : null;
    final unresolved = uniqueTimestamps.take(_maximumEvidenceFrames).toSet();
    for (var attempt = 0;
        attempt < _evidenceRetryDimensions.length && unresolved.isNotEmpty;
        attempt += 1) {
      if (_deadlineHasExpired(deadline)) {
        failureCode ??= _evidenceArchiveTimeoutFailureCode;
        break;
      }
      final raw = await _beforeDeadline(
        _channel.invokeMethod<List<Object?>>(
          'extractRunningEvidenceFrames',
          <String, Object?>{
            'path': sourcePath,
            'timestampsMs': unresolved.toList(growable: false)..sort(),
            'maxDimension': _evidenceRetryDimensions[attempt],
            'jpegQuality': _evidenceRetryQualities[attempt],
            if (deadline != null)
              'deadlineEpochMs': deadline.millisecondsSinceEpoch,
          },
        ),
        deadline,
      );
      if (_deadlineHasExpired(deadline)) {
        failureCode ??= _evidenceArchiveTimeoutFailureCode;
      }
      if (raw == null || raw.isEmpty) {
        failureCode ??= _deadlineHasExpired(deadline)
            ? _evidenceArchiveTimeoutFailureCode
            : 'no_evidence_frames_extracted';
        continue;
      }
      final returnedTimestamps = <int>{};
      for (final item in raw) {
        if (item is! Map) continue;
        final timestampMs = _intValue(item['timestampMs']);
        returnedTimestamps.add(timestampMs);
        if (!unresolved.contains(timestampMs)) continue;
        final timestampRequests = requestsByTimestamp[timestampMs];
        final bytes = item['bytes'];
        final width = _intValue(item['width']);
        final height = _intValue(item['height']);
        if (timestampRequests == null ||
            bytes is! Uint8List ||
            bytes.isEmpty ||
            width <= 0 ||
            height <= 0) {
          failureCode ??= 'invalid_evidence_frame';
          continue;
        }
        if (bytes.length > _maximumEvidenceJpegBytes ||
            totalBytes + bytes.length > _maximumEvidenceArchiveBytes) {
          failureCode ??= 'evidence_storage_limit';
          continue;
        }
        if (_deadlineHasExpired(deadline)) {
          failureCode ??= _evidenceArchiveTimeoutFailureCode;
          break;
        }
        final filename = '$sessionId-frame-$timestampMs.jpg';
        final destination = File(
          '${archiveDirectory.path}${Platform.pathSeparator}$filename',
        );
        final saved = await _writeEvidenceImageAtomically(
          destination: destination,
          bytes: bytes,
          expectedWidth: width,
          expectedHeight: height,
        );
        if (!saved) {
          failureCode ??= 'file_write_failed';
          continue;
        }
        totalBytes += bytes.length;
        unresolved.remove(timestampMs);
        for (final request in timestampRequests) {
          archived.add(
            RunningCoachEvidenceImage(
              id: request.id,
              timestamp: request.timestamp,
              kind: request.kind,
              role: request.role,
              storageReference: destination.path,
              width: width,
              height: height,
              side: request.side,
              values: request.values,
              confidence: request.confidence,
              poseFrame: request.poseFrame,
            ),
          );
        }
      }
      if (returnedTimestamps.length < unresolved.length) {
        failureCode ??= 'partial_evidence_frames_extracted';
      }
    }
    if (unresolved.isNotEmpty) {
      failureCode ??= 'partial_evidence_frames_extracted';
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
  final deletedReferences = <String>{};
  for (final image in images) {
    if (image.storageReference.isEmpty) continue;
    if (!deletedReferences.add(image.storageReference)) continue;
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

Future<bool> _writeEvidenceImageAtomically({
  required File destination,
  required Uint8List bytes,
  required int expectedWidth,
  required int expectedHeight,
}) async {
  final temporary = File(
    '${destination.path}.tmp-${DateTime.now().microsecondsSinceEpoch}',
  );
  try {
    await temporary.writeAsBytes(bytes, flush: true);
    if (!await _evidenceImageFileIsReadable(
      temporary,
      expectedWidth: expectedWidth,
      expectedHeight: expectedHeight,
    )) {
      await _deleteIfExists(temporary);
      return false;
    }
    await temporary.rename(destination.path);
    return _evidenceImageFileIsReadable(
      destination,
      expectedWidth: expectedWidth,
      expectedHeight: expectedHeight,
    );
  } on FileSystemException {
    await _deleteIfExists(temporary);
    return false;
  } catch (_) {
    await _deleteIfExists(temporary);
    return false;
  }
}

Future<bool> _evidenceImageFileIsReadable(
  File file, {
  required int expectedWidth,
  required int expectedHeight,
}) async {
  try {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return false;
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      final image = frame.image;
      try {
        return image.width == expectedWidth && image.height == expectedHeight;
      } finally {
        image.dispose();
      }
    } finally {
      codec.dispose();
    }
  } catch (_) {
    return false;
  }
}

Future<void> _deleteIfExists(File file) async {
  try {
    if (await file.exists()) await file.delete();
  } on FileSystemException {
    // Best effort cleanup for a failed temp write.
  }
}

int _intValue(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _deadlineHasExpired(DateTime? deadline) =>
    deadline != null && !DateTime.now().isBefore(deadline);

Duration? _remainingUntil(DateTime? deadline) {
  if (deadline == null) return null;
  return deadline.difference(DateTime.now());
}

Future<T?> _beforeDeadline<T>(
  Future<T> future,
  DateTime? deadline, {
  T? fallback,
}) async {
  final remaining = _remainingUntil(deadline);
  if (remaining == null) return future;
  if (remaining <= Duration.zero) return fallback;
  try {
    return await future.timeout(remaining);
  } on TimeoutException {
    return fallback;
  }
}

Future<Uint8List?> extractRunningVideoThumbnail(
  XFile video, {
  Duration timestamp = const Duration(milliseconds: 200),
}) async {
  final path = video.path.trim();
  if (path.isEmpty || !await File(path).exists()) return null;
  try {
    final raw = await _channel.invokeMethod<List<Object?>>(
      'extractRunningEvidenceFrames',
      <String, Object?>{
        'path': path,
        'timestampsMs': <int>[timestamp.inMilliseconds],
        'maxDimension': 240,
        'jpegQuality': 72,
      },
    );
    if (raw == null || raw.isEmpty || raw.first is! Map) return null;
    final bytes = (raw.first as Map)['bytes'];
    return bytes is Uint8List && bytes.isNotEmpty ? bytes : null;
  } catch (_) {
    return null;
  }
}
