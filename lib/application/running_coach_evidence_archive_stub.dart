import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../domain/entities/running_coach_session.dart';
import 'running_coach_evidence_archive_types.dart';

Future<List<RunningCoachEvidenceImage>> archiveRunningCoachEvidenceImages({
  required XFile? sourceVideo,
  required String sessionId,
  required List<RunningCoachEvidenceFrameRequest> requests,
}) async =>
    const <RunningCoachEvidenceImage>[];

Future<Uint8List?> readArchivedRunningCoachEvidenceImage(
  RunningCoachEvidenceImage image,
) async =>
    null;

Future<void> deleteArchivedRunningCoachEvidenceImages(
  Iterable<RunningCoachEvidenceImage> images,
) async {}
