import 'dart:convert';
import 'dart:typed_data';

import 'dart:js_interop';

import 'package:image_picker/image_picker.dart';

import '../domain/entities/running_coach_session.dart';
import 'running_coach_evidence_archive_types.dart';

@JS('runningVideoPoseAnalysis')
external _RunningEvidenceFrameExtractor? get _runningEvidenceFrameExtractor;

const _maximumWebEvidenceDataUrlCharacters = 220000;
const _maximumWebEvidenceArchiveCharacters = 900000;

extension type _RunningEvidenceFrameExtractor._(JSObject _)
    implements JSObject {
  external JSPromise<JSAny?> extractEvidenceFrames(
    JSUint8Array bytes,
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
    final bytes = await source.readAsBytes();
    if (bytes.isEmpty) {
      return RunningCoachEvidenceArchiveResult.failed(
        requestedCount: requests.length,
        failureCode: 'source_video_unavailable',
      );
    }
    final raw = await bridge
        .extractEvidenceFrames(
          bytes.toJS,
          source.name.toJS,
          jsonEncode(
            requests
                .map((request) => request.timestamp.inMilliseconds)
                .toList(growable: false),
          ).toJS,
        )
        .toDart;
    final converted = raw.dartify();
    if (converted is! List) {
      return RunningCoachEvidenceArchiveResult.failed(
        requestedCount: requests.length,
        failureCode: 'web_evidence_extraction_failed',
      );
    }
    final requestsByTimestamp = <int, RunningCoachEvidenceFrameRequest>{
      for (final request in requests) request.timestamp.inMilliseconds: request,
    };
    final archived = <RunningCoachEvidenceImage>[];
    var totalDataUrlCharacters = 0;
    var failureCode = converted.length < requests.length
        ? 'partial_evidence_frames_extracted'
        : null;
    for (final item in converted) {
      if (item is! Map) continue;
      final timestampMs = _intValue(item['timestampMs']);
      final request = requestsByTimestamp[timestampMs];
      final dataUrl = item['dataUrl']?.toString() ?? '';
      if (request == null || !_isImageDataUrl(dataUrl)) continue;
      final nextTotal = totalDataUrlCharacters + dataUrl.length;
      if (dataUrl.length > _maximumWebEvidenceDataUrlCharacters ||
          nextTotal > _maximumWebEvidenceArchiveCharacters) {
        failureCode ??= 'web_evidence_storage_limit';
        continue;
      }
      totalDataUrlCharacters = nextTotal;
      archived.add(
        RunningCoachEvidenceImage(
          id: request.id,
          timestamp: request.timestamp,
          kind: request.kind,
          role: request.role,
          storageReference: dataUrl,
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
