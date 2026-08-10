import 'dart:convert';
import 'dart:typed_data';

import 'dart:js_interop';

import 'package:image_picker/image_picker.dart';

import '../domain/entities/running_coach_session.dart';
import 'running_video_analysis_service.dart';
import 'running_coach_evidence_archive_types.dart';

@JS('runningVideoPoseAnalysis')
external _RunningEvidenceFrameExtractor? get _runningEvidenceFrameExtractor;

const _maximumWebEvidenceFrames = 24;
const _maximumWebEvidenceDataUrlCharacters = 360000;
const _maximumWebEvidenceArchiveCharacters = 6 * 1024 * 1024;
const _maximumWebEvidenceByteFallback = 32 * 1024 * 1024;

extension type _RunningEvidenceFrameExtractor._(JSObject _)
    implements JSObject {
  external JSPromise<JSAny?> extractEvidenceFrames(
    JSUint8Array bytes,
    JSString name,
    JSString timestampsJson,
  );
  external JSPromise<JSAny?> extractEvidenceFramesFromUrl(
    JSString url,
    JSString name,
    JSString timestampsJson,
  );
}

Future<RunningCoachEvidenceArchiveResult> archiveRunningCoachEvidenceImages({
  required XFile? sourceVideo,
  required String sessionId,
  required List<RunningCoachEvidenceFrameRequest> requests,
}) async {
  final source = sourceVideo;
  final bridge = _runningEvidenceFrameExtractor;
  if (requests.isEmpty) {
    return RunningCoachEvidenceArchiveResult.notRequested();
  }
  if (source == null) {
    return RunningCoachEvidenceArchiveResult.failed(
      requestedCount: requests.length,
      failureCode: 'source_video_unavailable',
    );
  }
  if (bridge == null) {
    return RunningCoachEvidenceArchiveResult.failed(
      requestedCount: requests.length,
      failureCode: 'web_evidence_bridge_unavailable',
    );
  }
  try {
    final uniqueTimestamps = requests
        .map((request) => request.timestamp.inMilliseconds)
        .toSet()
        .take(_maximumWebEvidenceFrames)
        .toList(growable: false)
      ..sort();
    final timestampsJson = jsonEncode(uniqueTimestamps).toJS;
    final path = source.path.trim();
    final JSAny? raw;
    if (RunningVideoAnalysisService.isReusableBrowserVideoUrl(path)) {
      raw = await bridge
          .extractEvidenceFramesFromUrl(
            path.toJS,
            source.name.toJS,
            timestampsJson,
          )
          .toDart;
    } else {
      final length = await source.length();
      if (length > _maximumWebEvidenceByteFallback) {
        return RunningCoachEvidenceArchiveResult.failed(
          requestedCount: requests.length,
          failureCode: 'web_evidence_url_required',
        );
      }
      final bytes = await source.readAsBytes();
      if (bytes.isEmpty) {
        return RunningCoachEvidenceArchiveResult.failed(
          requestedCount: requests.length,
          failureCode: 'source_video_unavailable',
        );
      }
      raw = await bridge
          .extractEvidenceFrames(
            bytes.toJS,
            source.name.toJS,
            timestampsJson,
          )
          .toDart;
    }
    final converted = raw.dartify();
    if (converted is! List) {
      return RunningCoachEvidenceArchiveResult.failed(
        requestedCount: requests.length,
        failureCode: 'web_evidence_extraction_failed',
      );
    }
    final requestsByTimestamp = <int, List<RunningCoachEvidenceFrameRequest>>{};
    for (final request in requests) {
      requestsByTimestamp
          .putIfAbsent(request.timestamp.inMilliseconds, () => [])
          .add(request);
    }
    final archived = <RunningCoachEvidenceImage>[];
    var totalDataUrlCharacters = 0;
    var failureCode = converted.length < uniqueTimestamps.length
        ? 'partial_evidence_frames_extracted'
        : null;
    for (final item in converted) {
      if (item is! Map) continue;
      final timestampMs = _intValue(item['timestampMs']);
      final timestampRequests = requestsByTimestamp[timestampMs];
      final dataUrl = item['dataUrl']?.toString() ?? '';
      if (timestampRequests == null || !_isImageDataUrl(dataUrl)) continue;
      final nextTotal = totalDataUrlCharacters + dataUrl.length;
      if (dataUrl.length > _maximumWebEvidenceDataUrlCharacters ||
          nextTotal > _maximumWebEvidenceArchiveCharacters) {
        failureCode ??= 'web_evidence_storage_limit';
        continue;
      }
      totalDataUrlCharacters = nextTotal;
      for (final request in timestampRequests) {
        archived.add(
          RunningCoachEvidenceImage(
            id: request.id,
            timestamp: request.timestamp,
            kind: request.kind,
            role: request.role,
            storageReference: dataUrl,
            width: _intValue(item['width']),
            height: _intValue(item['height']),
            side: request.side,
            values: request.values,
            confidence: request.confidence,
            poseFrame: request.poseFrame,
          ),
        );
      }
    }
    return RunningCoachEvidenceArchiveResult.fromImages(
      requestedCount: requests.length,
      images: archived,
      failureCode: failureCode,
    );
  } catch (_) {
    return RunningCoachEvidenceArchiveResult.failed(
      requestedCount: requests.length,
      failureCode: 'web_evidence_archive_failed',
    );
  }
}

Future<Uint8List?> readArchivedRunningCoachEvidenceImage(
  RunningCoachEvidenceImage image,
) async {
  final dataUrl = image.storageReference;
  if (!_isImageDataUrl(dataUrl)) return null;
  final comma = dataUrl.indexOf(',');
  if (comma < 0 || comma == dataUrl.length - 1) return null;
  try {
    return base64Decode(dataUrl.substring(comma + 1));
  } on FormatException {
    return null;
  }
}

Future<void> deleteArchivedRunningCoachEvidenceImages(
  Iterable<RunningCoachEvidenceImage> images,
) async {}

bool _isImageDataUrl(String value) =>
    value.startsWith('data:image/jpeg;base64,') ||
    value.startsWith('data:image/webp;base64,');

int _intValue(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

Future<Uint8List?> extractRunningVideoThumbnail(
  XFile video, {
  Duration timestamp = const Duration(milliseconds: 200),
}) async {
  final bridge = _runningEvidenceFrameExtractor;
  if (bridge == null) return null;
  try {
    final timestamps = jsonEncode(<int>[timestamp.inMilliseconds]).toJS;
    final path = video.path.trim();
    final JSAny? raw;
    if (RunningVideoAnalysisService.isReusableBrowserVideoUrl(path)) {
      raw = await bridge
          .extractEvidenceFramesFromUrl(path.toJS, video.name.toJS, timestamps)
          .toDart;
    } else {
      if (await video.length() > 8 * 1024 * 1024) return null;
      final bytes = await video.readAsBytes();
      if (bytes.isEmpty) return null;
      raw = await bridge
          .extractEvidenceFrames(bytes.toJS, video.name.toJS, timestamps)
          .toDart;
    }
    final converted = raw.dartify();
    if (converted is! List || converted.isEmpty || converted.first is! Map) {
      return null;
    }
    final dataUrl = (converted.first as Map)['dataUrl']?.toString() ?? '';
    if (!_isImageDataUrl(dataUrl)) return null;
    final comma = dataUrl.indexOf(',');
    return comma < 0 ? null : base64Decode(dataUrl.substring(comma + 1));
  } catch (_) {
    return null;
  }
}
