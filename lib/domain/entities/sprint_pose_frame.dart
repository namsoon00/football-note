import 'dart:ui';

enum SprintPoseLandmarkType {
  nose,
  leftEar,
  rightEar,
  leftShoulder,
  rightShoulder,
  leftElbow,
  rightElbow,
  leftWrist,
  rightWrist,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
  leftHeel,
  rightHeel,
  leftFootIndex,
  rightFootIndex,
}

const Set<SprintPoseLandmarkType> sprintMvpCoreLandmarks = {
  SprintPoseLandmarkType.leftShoulder,
  SprintPoseLandmarkType.rightShoulder,
  SprintPoseLandmarkType.leftElbow,
  SprintPoseLandmarkType.rightElbow,
  SprintPoseLandmarkType.leftWrist,
  SprintPoseLandmarkType.rightWrist,
  SprintPoseLandmarkType.leftHip,
  SprintPoseLandmarkType.rightHip,
  SprintPoseLandmarkType.leftKnee,
  SprintPoseLandmarkType.rightKnee,
  SprintPoseLandmarkType.leftAnkle,
  SprintPoseLandmarkType.rightAnkle,
};

class SprintPoseLandmark {
  final Offset position;
  final double confidence;

  const SprintPoseLandmark({required this.position, required this.confidence});
}

class SprintPoseFrame {
  final Size imageSize;
  final DateTime timestamp;
  final Map<SprintPoseLandmarkType, SprintPoseLandmark> landmarks;

  const SprintPoseFrame({
    required this.imageSize,
    required this.timestamp,
    required this.landmarks,
  });

  SprintPoseLandmark? landmark(
    SprintPoseLandmarkType type, {
    double minimumConfidence = 0,
  }) {
    final landmark = landmarks[type];
    if (landmark == null || landmark.confidence < minimumConfidence) {
      return null;
    }
    return landmark;
  }

  int visibleLandmarkCount({double minimumConfidence = 0}) {
    return landmarks.values
        .where((landmark) => landmark.confidence >= minimumConfidence)
        .length;
  }

  bool hasAllLandmarks(
    Iterable<SprintPoseLandmarkType> requiredTypes, {
    double minimumConfidence = 0,
  }) {
    for (final type in requiredTypes) {
      if (landmark(type, minimumConfidence: minimumConfidence) == null) {
        return false;
      }
    }
    return true;
  }

  double averageConfidence(Iterable<SprintPoseLandmarkType> types) {
    var total = 0.0;
    var count = 0;
    for (final type in types) {
      final landmark = landmarks[type];
      if (landmark == null) {
        continue;
      }
      total += landmark.confidence;
      count += 1;
    }
    if (count == 0) {
      return 0;
    }
    return total / count;
  }

  SprintPoseFrame copyWith({
    Size? imageSize,
    DateTime? timestamp,
    Map<SprintPoseLandmarkType, SprintPoseLandmark>? landmarks,
  }) {
    return SprintPoseFrame(
      imageSize: imageSize ?? this.imageSize,
      timestamp: timestamp ?? this.timestamp,
      landmarks: landmarks ?? this.landmarks,
    );
  }
}
