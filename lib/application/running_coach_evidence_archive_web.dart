import 'dart:convert';
import 'dart:typed_data';

import 'dart:js_interop';

import 'package:image_picker/image_picker.dart';

import '../domain/entities/running_coach_session.dart';
import 'running_coach_evidence_archive_types.dart';

@JS('runningVideoPoseAnalysis')
external _RunningEvidenceFrameExtractor? get _runningEvidenceFrameExtractor;

extension type _RunningEvidenceFrameExtractor._(JSObject _)
    implements JSObject {
  external JSPromise<JSAny?> extractEvidenceFrames(
    JSUint8Array bytes,
    JSString name,
    JSString timestampsJson,
  );
}

Future<List<RunningCoachEvidenceImage>> archiveRunningCoachEvidenceImages({
  required XFile? sourceVideo,
  required String sessionId,
  required List<RunningCoachEvidenceFrameRequest> requests,
}) async {
  final source = sourceVideo;
  final bridge = _runningEvidenceFrameExtractor;
  if (source == null || bridge == null || requests.isEmpty) {
    return const <RunningCoachEvidenceImage>[];
  }
  try {
    final bytes = await source.readAsBytes();
    if (bytes.isEmpty) return const <RunningCoachEvidenceImage>[];
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
    if (converted is! List) return const <RunningCoachEvidenceImage>[];
    final requestsByTimestamp = <int, RunningCoachEvidenceFrameRequest>{
      for (final request in requests) request.timestamp.inMilliseconds: request,
    };
    final archived = <RunningCoachEvidenceImage>[];
    for (final item in converted) {
      if (item is! Map) continue;
      final timestampMs = _intValue(item['timestampMs']);
      final request = requestsByTimestamp[timestampMs];
      final dataUrl = item['dataUrl']?.toString() ?? '';
      if (request == null || !_isImageDataUrl(dataUrl)) continue;
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
    return List<RunningCoachEvidenceImage>.unmodifiable(archived);
  } catch (_) {
    return const <RunningCoachEvidenceImage>[];
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
