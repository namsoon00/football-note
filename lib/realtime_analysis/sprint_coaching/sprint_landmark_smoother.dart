import 'dart:ui';

import '../../domain/entities/sprint_pose_frame.dart';

class SprintLandmarkSmoother {
  final Map<SprintPoseLandmarkType, Offset> _previousPositions =
      <SprintPoseLandmarkType, Offset>{};

  void reset() => _previousPositions.clear();

  SprintPoseFrame smooth(SprintPoseFrame frame, {required double alpha}) {
    final smoothed = <SprintPoseLandmarkType, SprintPoseLandmark>{};

    for (final entry in frame.landmarks.entries) {
      final previous = _previousPositions[entry.key];
      final nextPosition = previous == null
          ? entry.value.position
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
