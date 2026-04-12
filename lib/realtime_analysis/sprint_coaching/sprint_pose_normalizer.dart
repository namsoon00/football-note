import 'dart:math' as math;
import 'dart:ui';

import '../../domain/entities/sprint_pose_frame.dart';

class SprintNormalizedPoseFrame {
  final DateTime timestamp;
  final double bodyScale;
  final Offset hipCenter;
  final Offset shoulderCenter;
  final Map<SprintPoseLandmarkType, Offset> normalizedLandmarks;

  const SprintNormalizedPoseFrame({
    required this.timestamp,
    required this.bodyScale,
    required this.hipCenter,
    required this.shoulderCenter,
    required this.normalizedLandmarks,
  });

  Offset? landmark(SprintPoseLandmarkType type) => normalizedLandmarks[type];

  Offset? midpointOf(
    SprintPoseLandmarkType first,
    SprintPoseLandmarkType second,
  ) {
    final firstPoint = landmark(first);
    final secondPoint = landmark(second);
    if (firstPoint == null || secondPoint == null) {
      return null;
    }
    return Offset(
      (firstPoint.dx + secondPoint.dx) / 2,
      (firstPoint.dy + secondPoint.dy) / 2,
    );
  }
}

class SprintPoseNormalizer {
  SprintNormalizedPoseFrame? normalize(
    SprintPoseFrame frame, {
    required double minimumConfidence,
  }) {
    final leftShoulder = frame.landmark(
      SprintPoseLandmarkType.leftShoulder,
      minimumConfidence: minimumConfidence,
    );
    final rightShoulder = frame.landmark(
      SprintPoseLandmarkType.rightShoulder,
      minimumConfidence: minimumConfidence,
    );
    final leftHip = frame.landmark(
      SprintPoseLandmarkType.leftHip,
      minimumConfidence: minimumConfidence,
    );
    final rightHip = frame.landmark(
      SprintPoseLandmarkType.rightHip,
      minimumConfidence: minimumConfidence,
    );
    final leftAnkle = frame.landmark(
      SprintPoseLandmarkType.leftAnkle,
      minimumConfidence: minimumConfidence,
    );
    final rightAnkle = frame.landmark(
      SprintPoseLandmarkType.rightAnkle,
      minimumConfidence: minimumConfidence,
    );

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null ||
        leftAnkle == null ||
        rightAnkle == null) {
      return null;
    }

    final shoulderCenter = _midpoint(
      leftShoulder.position,
      rightShoulder.position,
    );
    final hipCenter = _midpoint(leftHip.position, rightHip.position);
    final ankleCenter = _midpoint(leftAnkle.position, rightAnkle.position);
    final torsoScale = _distance(shoulderCenter, hipCenter);
    final legScale = _distance(hipCenter, ankleCenter);
    final bodyScale = math.max(torsoScale, legScale);

    if (bodyScale <= 0) {
      return null;
    }

    final normalized = <SprintPoseLandmarkType, Offset>{};
    for (final entry in frame.landmarks.entries) {
      if (entry.value.confidence < minimumConfidence) {
        continue;
      }
      normalized[entry.key] = Offset(
        (entry.value.position.dx - hipCenter.dx) / bodyScale,
        (entry.value.position.dy - hipCenter.dy) / bodyScale,
      );
    }

    return SprintNormalizedPoseFrame(
      timestamp: frame.timestamp,
      bodyScale: bodyScale,
      hipCenter: hipCenter,
      shoulderCenter: shoulderCenter,
      normalizedLandmarks: normalized,
    );
  }

  Offset _midpoint(Offset first, Offset second) {
    return Offset((first.dx + second.dx) / 2, (first.dy + second.dy) / 2);
  }

  double _distance(Offset first, Offset second) {
    final dx = first.dx - second.dx;
    final dy = first.dy - second.dy;
    return math.sqrt((dx * dx) + (dy * dy));
  }
}
