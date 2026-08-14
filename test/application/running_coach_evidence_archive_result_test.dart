import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/running_coach_evidence_archive_types.dart';
import 'package:football_note/domain/entities/running_coach_session.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';

void main() {
  test('archive result preserves partial success and data URL fallback images',
      () {
    const image = RunningCoachEvidenceImage(
      id: 'posture-500',
      timestamp: Duration(milliseconds: 500),
      kind: RunningMetricEvidenceKind.posture,
      role: RunningMetricEvidenceFrameRole.representativePosture,
      storageReference: 'data:image/jpeg;base64,abc=',
      width: 320,
      height: 180,
      confidence: 0.55,
    );

    final result = RunningCoachEvidenceArchiveResult.fromImages(
      requestedCount: 2,
      images: const <RunningCoachEvidenceImage>[image],
      failureCode: 'web_evidence_storage_failed',
    );

    expect(result.status, RunningCoachEvidenceArchiveStatus.partialFailure);
    expect(result.savedCount, 1);
    expect(result.failureCode, 'web_evidence_storage_failed');
    expect(result.images.single.storageReference, startsWith('data:image/'));
  });
}
