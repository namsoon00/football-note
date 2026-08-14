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
const _maximumWebEvidenceByteFallback = 32 * 1024 * 1024;
const _webEvidenceRetryQualities = <int>[72, 64, 56];

extension type _RunningEvidenceFrameExtractor._(JSObject _)
    implements JSObject {
  external JSPromise<JSAny?> extractEvidenceFrames(
    JSUint8Array bytes,
    JSString name,
    JSString timestampsJson,
    JSNumber jpegQuality,
  );
  external JSPromise<JSAny?> extractEvidenceFramesFromUrl(
    JSString url,
    JSString name,
    JSString timestampsJson,
    JSNumber jpegQuality,
  );
  external JSPromise<JSAny?> storeEvidenceFrame(
    JSString reference,
    JSString dataUrl,
  );
  external JSPromise<JSAny?> readEvidenceFrame(JSString reference);
  external JSPromise<JSAny?> deleteEvidenceFrames(JSString referencesJson);
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
    final allUniqueTimestamps = requests
        .map((request) => request.timestamp.inMilliseconds)
        .toSet()
        .toList(growable: false)
      ..sort();
    final uniqueTimestamps =
        allUniqueTimestamps.take(_maximumWebEvidenceFrames).toList(
              growable: false,
            );
    final path = source.path.trim();
    final requestsByTimestamp = <int, List<RunningCoachEvidenceFrameRequest>>{};
    for (final request in requests) {
      requestsByTimestamp
          .putIfAbsent(request.timestamp.inMilliseconds, () => [])
          .add(request);
    }
    final archived = <RunningCoachEvidenceImage>[];
    var failureCode = allUniqueTimestamps.length > _maximumWebEvidenceFrames
        ? 'evidence_frame_limit'
        : null;
    final unresolved = uniqueTimestamps.toSet();
    Uint8List? sourceBytes;
    Future<JSAny?> extractRawFrames(
      JSString timestampsJson,
      int quality,
    ) async {
      if (RunningVideoAnalysisService.isReusableBrowserVideoUrl(path)) {
        try {
          return await bridge
              .extractEvidenceFramesFromUrl(
                path.toJS,
                source.name.toJS,
                timestampsJson,
                quality.toJS,
              )
              .toDart;
        } catch (_) {
          failureCode ??= 'web_evidence_url_failed';
        }
      }
      final length = await source.length();
      if (length > _maximumWebEvidenceByteFallback) {
        failureCode ??= 'web_evidence_url_required';
        return null;
      }
      sourceBytes ??= await source.readAsBytes();
      if (sourceBytes == null || sourceBytes!.isEmpty) {
        failureCode ??= 'source_video_unavailable';
        return null;
      }
      try {
        return await bridge
            .extractEvidenceFrames(
              sourceBytes!.toJS,
              source.name.toJS,
              timestampsJson,
              quality.toJS,
            )
            .toDart;
      } catch (_) {
        failureCode ??= 'web_evidence_extraction_failed';
        return null;
      }
    }

    for (final quality in _webEvidenceRetryQualities) {
      if (unresolved.isEmpty) break;
      final timestampsJson = jsonEncode(
        unresolved.toList(growable: false)..sort(),
      ).toJS;
      final raw = await extractRawFrames(timestampsJson, quality);
      final converted = raw?.dartify();
      if (converted is! List) {
        failureCode ??= 'web_evidence_extraction_failed';
        continue;
      }
      for (final item in converted) {
        if (item is! Map) continue;
        final timestampMs = _intValue(item['timestampMs']);
        if (!unresolved.contains(timestampMs)) continue;
        final timestampRequests = requestsByTimestamp[timestampMs];
        final dataUrl = item['dataUrl']?.toString() ?? '';
        final width = _intValue(item['width']);
        final height = _intValue(item['height']);
        if (timestampRequests == null ||
            !_isImageDataUrl(dataUrl) ||
            width <= 0 ||
            height <= 0) {
          failureCode ??= 'web_evidence_extraction_failed';
          continue;
        }
        if (dataUrl.length > _maximumWebEvidenceDataUrlCharacters) {
          failureCode ??= 'web_evidence_storage_limit';
          continue;
        }
        final idbReference = 'idb:$sessionId:$timestampMs';
        var storageReference = idbReference;
        try {
          final stored = await bridge
              .storeEvidenceFrame(idbReference.toJS, dataUrl.toJS)
              .toDart;
          if (stored.dartify()?.toString() != idbReference) {
            failureCode ??= 'web_evidence_storage_failed';
            storageReference = dataUrl;
          }
        } catch (_) {
          failureCode ??= 'web_evidence_storage_failed';
          storageReference = dataUrl;
        }
        unresolved.remove(timestampMs);
        for (final request in timestampRequests) {
          archived.add(
            RunningCoachEvidenceImage(
              id: request.id,
              timestamp: request.timestamp,
              kind: request.kind,
              role: request.role,
              storageReference: storageReference,
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
    }
    if (unresolved.isNotEmpty) {
      failureCode ??= 'partial_evidence_frames_extracted';
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
  if (dataUrl.startsWith('idb:')) {
    final bridge = _runningEvidenceFrameExtractor;
    if (bridge == null) return null;
    try {
      final raw = await bridge.readEvidenceFrame(dataUrl.toJS).toDart;
      return _decodeImageDataUrl(raw.dartify()?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }
  return _decodeImageDataUrl(dataUrl);
}

Uint8List? _decodeImageDataUrl(String dataUrl) {
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
) async {
  final bridge = _runningEvidenceFrameExtractor;
  if (bridge == null) return;
  final references = images
      .map((image) => image.storageReference)
      .where((reference) => reference.startsWith('idb:'))
      .toSet()
      .toList(growable: false);
  if (references.isEmpty) return;
  try {
    await bridge.deleteEvidenceFrames(jsonEncode(references).toJS).toDart;
  } catch (_) {
    // History cleanup is best effort.
  }
}

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
    Future<JSAny?> extractFromBytes() async {
      if (await video.length() > 8 * 1024 * 1024) return null;
      final bytes = await video.readAsBytes();
      if (bytes.isEmpty) return null;
      return bridge
          .extractEvidenceFrames(
            bytes.toJS,
            video.name.toJS,
            timestamps,
            72.toJS,
          )
          .toDart;
    }

    JSAny? raw;
    if (RunningVideoAnalysisService.isReusableBrowserVideoUrl(path)) {
      try {
        raw = await bridge
            .extractEvidenceFramesFromUrl(
              path.toJS,
              video.name.toJS,
              timestamps,
              72.toJS,
            )
            .toDart;
      } catch (_) {
        raw = await extractFromBytes();
      }
    } else {
      raw = await extractFromBytes();
    }
    final converted = raw?.dartify();
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
