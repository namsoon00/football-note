import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../domain/entities/running_coach_session.dart';
import 'running_coach_evidence_archive_types.dart';

Future<RunningCoachEvidenceArchiveResult> archiveRunningCoachEvidenceImages({
  required XFile? sourceVideo,
  required String sessionId,
  required List<RunningCoachEvidenceFrameRequest> requests,
}) async =>
    requests.isEmpty
        ? RunningCoachEvidenceArchiveResult.notRequested()
        : RunningCoachEvidenceArchiveResult.failed(
            requestedCount: requests.length,
            failureCode: 'evidence_archive_unavailable',
          );

Future<Uint8List?> readArchivedRunningCoachEvidenceImage(
  RunningCoachEvidenceImage image,
) async =>
    null;

Future<void> deleteArchivedRunningCoachEvidenceImages(
  Iterable<RunningCoachEvidenceImage> images,
) async {}

Future<Uint8List?> extractRunningVideoThumbnail(
  XFile video, {
  Duration timestamp = const Duration(milliseconds: 200),
}) async =>
    null;
