import 'dart:ui';

import '../../domain/entities/sprint_pose_frame.dart';

class SprintLandmarkSmoother {
  final Map<SprintPoseLandmarkType, Offset> _previousPositions =
      <SprintPoseLandmarkType, Offset>{};

  void reset() => _previousPositions.clear();

  SprintPoseFrame smooth(
    SprintPoseFrame frame, {
    required double alpha,
    double maxDisplacementRatio = 0.44,
  }) {
    final smoothed = <SprintPoseLandmarkType, SprintPoseLandmark>{};
    final bodyScale = frame.bodyScaleEstimate();

    for (final entry in frame.landmarks.entries) {
      final previous = _previousPositions[entry.key];
      final displacement =
          previous == null ? 0.0 : (previous - entry.value.position).distance;
      final exceedsOutlierThreshold = previous != null &&
          bodyScale > 0 &&
          displacement > (bodyScale * maxDisplacementRatio);
      final nextPosition = previous == null
          ? entry.value.position
          : exceedsOutlierThreshold
              ? previous
              : _lerp(previous, entry.value.position, alpha);
      _previousPositions[entry.key] = nextPosition;
      smoothed[entry.key] = SprintPoseLandmark(
        position: nextPosition,
        confidence: entry.value.confidence,
      );
    }

    return frame.copyWith(landmarks: smoothed);
  }

  Offset _lerp(Offset from, Offset to, double alpha) {
    final factor = alpha.clamp(0.0, 1.0);
    return Offset(
      from.dx + ((to.dx - from.dx) * factor),
      from.dy + ((to.dy - from.dy) * factor),
    );
  }
}
