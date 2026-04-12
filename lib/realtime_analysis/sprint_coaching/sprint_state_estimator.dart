import 'dart:math' as math;
import 'dart:ui';

import '../../domain/entities/sprint_pose_frame.dart';
import '../../domain/entities/sprint_realtime_coaching_state.dart';
import 'sprint_pipeline_config.dart';
import 'sprint_pose_normalizer.dart';

class SprintStateEstimator {
  SprintStateEstimate estimate({
    required List<SprintPoseFrame> rawFrames,
    required List<SprintNormalizedPoseFrame> normalizedFrames,
    required SprintFeatureSnapshot features,
    required SprintPipelineConfig config,
    required DateTime now,
    required DateTime? lastFeedbackAt,
  }) {
    final lastRawFrame = rawFrames.isEmpty ? null : rawFrames.last;
    final bodyFullyVisible =
        lastRawFrame != null &&
        lastRawFrame.visibleLandmarkCount(
              minimumConfidence: config.minimumLandmarkConfidence,
            ) >=
            config.minimumVisibleLandmarks &&
        lastRawFrame.hasAllLandmarks(
          sprintMvpCoreLandmarks,
          minimumConfidence: config.minimumLandmarkConfidence,
        );
    final trackingConfidence = _trackingConfidence(rawFrames);
    final lowConfidence =
        !bodyFullyVisible ||
        trackingConfidence < config.minimumTrackingConfidence ||
        normalizedFrames.length < config.minimumWindowFrames;
    final runningDetected =
        !lowConfidence &&
        (_hipTravelRatio(rawFrames, config.minimumLandmarkConfidence) >=
                config.minimumRunningTravelRatio ||
            features.detectedStepEvents >= 2);
    final accelerationPhaseDetected =
        runningDetected &&
        (features.trunkAngleDegrees ?? 0) >= config.minimumTrunkAngleDegrees &&
        (features.trunkAngleDegrees ?? 0) <=
            config.maximumAccelerationTrunkAngleDegrees;
    final feedbackCooldownActive =
        lastFeedbackAt != null &&
        now.difference(lastFeedbackAt) < config.feedbackCooldown;

    return SprintStateEstimate(
      runningDetected: runningDetected,
      accelerationPhaseDetected: accelerationPhaseDetected,
      feedbackCooldownActive: feedbackCooldownActive,
      lowConfidence: lowConfidence,
      bodyFullyVisible: bodyFullyVisible,
      trackingConfidence: trackingConfidence,
      stableFrameCount: normalizedFrames.length,
    );
  }

  double _trackingConfidence(List<SprintPoseFrame> rawFrames) {
    if (rawFrames.isEmpty) {
      return 0;
    }

    final values = <double>[
      for (final frame in rawFrames)
        frame.averageConfidence(sprintMvpCoreLandmarks),
    ];
    final total = values.reduce((sum, value) => sum + value);
    return total / values.length;
  }

  double _hipTravelRatio(
    List<SprintPoseFrame> rawFrames,
    double minimumConfidence,
  ) {
    if (rawFrames.length < 2) {
      return 0;
    }

    final hipCenters = <Offset>[];
    final bodyScales = <double>[];

    for (final frame in rawFrames) {
      final leftHip = frame.landmark(
        SprintPoseLandmarkType.leftHip,
        minimumConfidence: minimumConfidence,
      );
      final rightHip = frame.landmark(
        SprintPoseLandmarkType.rightHip,
        minimumConfidence: minimumConfidence,
      );
      final leftShoulder = frame.landmark(
        SprintPoseLandmarkType.leftShoulder,
        minimumConfidence: minimumConfidence,
      );
      final rightShoulder = frame.landmark(
        SprintPoseLandmarkType.rightShoulder,
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

      if (leftHip == null ||
          rightHip == null ||
          leftShoulder == null ||
          rightShoulder == null ||
          leftAnkle == null ||
          rightAnkle == null) {
        continue;
      }

      final hipCenter = Offset(
        (leftHip.position.dx + rightHip.position.dx) / 2,
        (leftHip.position.dy + rightHip.position.dy) / 2,
      );
      final shoulderCenter = Offset(
        (leftShoulder.position.dx + rightShoulder.position.dx) / 2,
        (leftShoulder.position.dy + rightShoulder.position.dy) / 2,
      );
      final ankleCenter = Offset(
        (leftAnkle.position.dx + rightAnkle.position.dx) / 2,
        (leftAnkle.position.dy + rightAnkle.position.dy) / 2,
      );

      hipCenters.add(hipCenter);
      bodyScales.add(
        math.max(
          _distance(shoulderCenter, hipCenter),
          _distance(hipCenter, ankleCenter),
        ),
      );
    }

    if (hipCenters.length < 2 || bodyScales.isEmpty) {
      return 0;
    }

    final travel = (hipCenters.last.dx - hipCenters.first.dx).abs();
    final averageScale =
        bodyScales.reduce((sum, value) => sum + value) / bodyScales.length;
    if (averageScale <= 0) {
      return 0;
    }
    return travel / averageScale;
  }

  double _distance(Offset first, Offset second) {
    final dx = first.dx - second.dx;
    final dy = first.dy - second.dy;
    return math.sqrt((dx * dx) + (dy * dy));
  }
}
