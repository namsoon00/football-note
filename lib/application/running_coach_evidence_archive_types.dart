import '../domain/entities/running_video_analysis_result.dart';
import '../domain/entities/running_coach_session.dart';

/// A timestamp selected by the analysis engine for a compact history replay.
class RunningCoachEvidenceFrameRequest {
  final String id;
  final Duration timestamp;
  final RunningMetricEvidenceKind kind;
  final RunningMetricEvidenceFrameRole role;
  final RunningContactSide side;
  final Map<String, double> values;
  final double confidence;
  final RunningPoseFrame? poseFrame;

  const RunningCoachEvidenceFrameRequest({
    required this.id,
    required this.timestamp,
    required this.kind,
    required this.role,
    this.side = RunningContactSide.unknown,
    this.values = const <String, double>{},
    this.confidence = 0,
    this.poseFrame,
  });
}

class RunningCoachEvidenceArchiveResult {
  final int requestedCount;
  final List<RunningCoachEvidenceImage> images;
  final RunningCoachEvidenceArchiveStatus status;
  final String? failureCode;

  const RunningCoachEvidenceArchiveResult({
    required this.requestedCount,
    required this.images,
    required this.status,
    this.failureCode,
  });

  int get savedCount => images.length;

  bool get hasFailure =>
      status == RunningCoachEvidenceArchiveStatus.failed ||
      status == RunningCoachEvidenceArchiveStatus.partialFailure;

  factory RunningCoachEvidenceArchiveResult.notRequested() {
    return const RunningCoachEvidenceArchiveResult(
      requestedCount: 0,
      images: <RunningCoachEvidenceImage>[],
      status: RunningCoachEvidenceArchiveStatus.notRequested,
    );
  }

  factory RunningCoachEvidenceArchiveResult.failed({
    required int requestedCount,
    required String failureCode,
  }) {
    return RunningCoachEvidenceArchiveResult(
      requestedCount: requestedCount,
      images: const <RunningCoachEvidenceImage>[],
      status: requestedCount == 0
          ? RunningCoachEvidenceArchiveStatus.notRequested
          : RunningCoachEvidenceArchiveStatus.failed,
      failureCode: requestedCount == 0 ? null : failureCode,
    );
  }

  factory RunningCoachEvidenceArchiveResult.fromImages({
    required int requestedCount,
    required List<RunningCoachEvidenceImage> images,
    String? failureCode,
  }) {
    final archived = List<RunningCoachEvidenceImage>.unmodifiable(images);
    if (requestedCount <= 0) {
      return RunningCoachEvidenceArchiveResult.notRequested();
    }
    if (archived.isEmpty) {
      return RunningCoachEvidenceArchiveResult.failed(
        requestedCount: requestedCount,
        failureCode: failureCode ?? 'no_evidence_frames_saved',
      );
    }
    final status = archived.length >= requestedCount
        ? RunningCoachEvidenceArchiveStatus.success
        : RunningCoachEvidenceArchiveStatus.partialFailure;
    return RunningCoachEvidenceArchiveResult(
      requestedCount: requestedCount,
      images: archived,
      status: status,
      failureCode: status == RunningCoachEvidenceArchiveStatus.success
          ? null
          : failureCode ?? 'partial_evidence_frames_saved',
    );
  }
}
