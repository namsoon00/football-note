import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../domain/entities/running_coach_session.dart';
import 'running_coach_evidence_archive_types.dart';
import 'running_coach_evidence_archive_stub.dart'
    if (dart.library.io) 'running_coach_evidence_archive_io.dart'
    if (dart.library.js_interop) 'running_coach_evidence_archive_web.dart'
    as platform;

export 'running_coach_evidence_archive_types.dart';

/// Extracts a small, deduplicated set of real frames from the analyzed clip.
///
/// The original video remains optional. These images are kept only as local
/// coaching evidence, alongside the timestamp and pose metadata already held
/// by a [RunningCoachSessionAnalysis].
Future<List<RunningCoachEvidenceImage>> archiveRunningCoachEvidenceImages({
  required XFile? sourceVideo,
  required String sessionId,
  required List<RunningCoachEvidenceFrameRequest> requests,
}) {
  return platform.archiveRunningCoachEvidenceImages(
    sourceVideo: sourceVideo,
    sessionId: sessionId,
    requests: requests,
  );
}

/// Reads a locally retained evidence image for display in history.
Future<Uint8List?> readArchivedRunningCoachEvidenceImage(
  RunningCoachEvidenceImage image,
) {
  return platform.readArchivedRunningCoachEvidenceImage(image);
}

/// Removes locally managed evidence image files when a session is deleted.
Future<void> deleteArchivedRunningCoachEvidenceImages(
  Iterable<RunningCoachEvidenceImage> images,
) {
  return platform.deleteArchivedRunningCoachEvidenceImages(images);
}
