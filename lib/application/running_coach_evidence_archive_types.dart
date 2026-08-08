import '../domain/entities/running_video_analysis_result.dart';

/// A timestamp selected by the analysis engine for a compact history replay.
class RunningCoachEvidenceFrameRequest {
  final String id;
  final Duration timestamp;
  final RunningMetricEvidenceKind kind;
  final RunningMetricEvidenceFrameRole role;

  const RunningCoachEvidenceFrameRequest({
    required this.id,
    required this.timestamp,
    required this.kind,
    required this.role,
  });
}
