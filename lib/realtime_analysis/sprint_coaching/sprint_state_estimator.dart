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
    final visibleLandmarkCount = lastRawFrame?.visibleLandmarkCount(
          minimumConfidence: config.minimumLandmarkConfidence,
        ) ??
        0;
    final visibleCoreLandmarkCount = lastRawFrame == null
        ? 0
        : sprintMvpCoreLandmarks
            .where(
              (type) =>
                  lastRawFrame.landmark(
                    type,
                    minimumConfidence: config.minimumLandmarkConfidence,
                  ) !=
                  null,
            )
            .length;
    final missingCoreLandmarkCount = lastRawFrame == null
        ? sprintMvpCoreLandmarks.length
        : sprintMvpCoreLandmarks
            .where(
              (type) =>
                  lastRawFrame.landmark(
                    type,
                    minimumConfidence: config.minimumLandmarkConfidence,
                  ) ==
                  null,
            )
            .length;
    final bodyVisibilityRatio =
        visibleCoreLandmarkCount / sprintMvpCoreLandmarkCount;
    final personBounds = lastRawFrame?.boundingBox(
      minimumConfidence: config.minimumLandmarkConfidence,
    );
    final personHeightRatio = personBounds == null || lastRawFrame == null
        ? 0.0
        : personBounds.height / lastRawFrame.imageSize.height;
    final personAreaRatio = personBounds == null || lastRawFrame == null
        ? 0.0
        : (personBounds.width * personBounds.height) /
            (lastRawFrame.imageSize.width * lastRawFrame.imageSize.height);
    final averageLandmarkConfidence = lastRawFrame?.averageVisibleConfidence(
          minimumConfidence: config.minimumLandmarkConfidence,
        ) ??
        0;
    final bodyTooSmall = personHeightRatio < config.minimumPersonHeightRatio ||
        personAreaRatio < config.minimumPersonAreaRatio;
    final bodyPartiallyOutOfFrame =
        _touchesFrameEdge(lastRawFrame, personBounds, config) ||
            (visibleCoreLandmarkCount > 0 && bodyVisibilityRatio < 1);
    final bodyFullyVisible = lastRawFrame != null &&
        visibleLandmarkCount >= config.minimumVisibleLandmarks &&
        bodyVisibilityRatio >= config.minimumBodyVisibilityRatio &&
        !bodyTooSmall &&
        !bodyPartiallyOutOfFrame;
    final bodyVisibilityStatus = visibleCoreLandmarkCount == 0
        ? SprintBodyVisibilityStatus.notVisible
        : bodyFullyVisible
            ? SprintBodyVisibilityStatus.full
            : SprintBodyVisibilityStatus.partial;
    final trackingConfidence = _trackingConfidence(rawFrames);
    final hipTravelRatio = _hipTravelRatio(
      rawFrames,
      config.minimumLandmarkConfidence,
    );
    final sideViewConfidence = _sideViewConfidence(
      rawFrames: rawFrames,
      minimumConfidence: config.minimumLandmarkConfidence,
      minimumTravelRatio: config.minimumSideViewTravelRatio,
    );
    final lowConfidence =
        trackingConfidence < config.minimumTrackingConfidence ||
            averageLandmarkConfidence < config.minimumTrackingConfidence ||
            normalizedFrames.length < config.minimumWindowFrames ||
            visibleLandmarkCount < config.minimumVisibleLandmarks ||
            visibleCoreLandmarkCount == 0;
    final trackingReadiness = _trackingReadiness(
      bodyTooSmall: bodyTooSmall,
      bodyPartiallyOutOfFrame: bodyPartiallyOutOfFrame,
      lowConfidence: lowConfidence,
      sideViewConfidence: sideViewConfidence,
      config: config,
    );
    final cadence = features.cadenceStepsPerMinute ?? 0;
    final cadenceSupportsRunning = features.detectedStepEvents == 0 ||
        cadence >= config.minimumRunningCadenceStepsPerMinute;
    final stepDrivenRunningDetected =
        features.detectedStepEvents >= config.minimumStepEventsForRunning &&
            cadence >= config.minimumRunningCadenceStepsPerMinute &&
            hipTravelRatio >= config.minimumStepDrivenTravelRatio;
    final runningDetected =
        trackingReadiness == SprintTrackingReadiness.readyForAnalysis &&
            cadenceSupportsRunning &&
            (hipTravelRatio >= config.minimumRunningTravelRatio ||
                stepDrivenRunningDetected);
    final accelerationPhaseDetected = runningDetected &&
        (features.trunkAngleDegrees ?? 0) >= config.minimumTrunkAngleDegrees &&
        (features.trunkAngleDegrees ?? 0) <=
            config.maximumAccelerationTrunkAngleDegrees;
    final feedbackCooldownActive = lastFeedbackAt != null &&
        now.difference(lastFeedbackAt) < config.feedbackCooldown;

    return SprintStateEstimate(
      runningDetected: runningDetected,
      accelerationPhaseDetected: accelerationPhaseDetected,
      feedbackCooldownActive: feedbackCooldownActive,
      lowConfidence: lowConfidence,
      bodyFullyVisible: bodyFullyVisible,
      bodyVisibilityStatus: bodyVisibilityStatus,
      trackingReadiness: trackingReadiness,
      trackingConfidence: trackingConfidence,
      stableFrameCount: normalizedFrames.length,
      visibleLandmarkCount: visibleLandmarkCount,
      visibleCoreLandmarkCount: visibleCoreLandmarkCount,
      missingCoreLandmarkCount: missingCoreLandmarkCount,
      bodyVisibilityRatio: bodyVisibilityRatio,
      hipTravelRatio: hipTravelRatio,
      personHeightRatio: personHeightRatio,
      personAreaRatio: personAreaRatio,
      averageLandmarkConfidence: averageLandmarkConfidence,
      sideViewConfidence: sideViewConfidence,
      personBounds: personBounds,
      suggestedCropRect: _suggestedCropRect(lastRawFrame, personBounds),
    );
  }

  SprintTrackingReadiness _trackingReadiness({
    required bool bodyTooSmall,
    required bool bodyPartiallyOutOfFrame,
    required bool lowConfidence,
    required double sideViewConfidence,
    required SprintPipelineConfig config,
  }) {
    if (bodyTooSmall) {
      return SprintTrackingReadiness.bodyTooSmall;
    }
    if (bodyPartiallyOutOfFrame) {
      return SprintTrackingReadiness.bodyPartiallyOutOfFrame;
    }
    if (lowConfidence) {
      return SprintTrackingReadiness.lowConfidence;
    }
    if (sideViewConfidence < config.minimumSideViewConfidence) {
      return SprintTrackingReadiness.sideViewUnstable;
    }
    return SprintTrackingReadiness.readyForAnalysis;
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

  double _sideViewConfidence({
    required List<SprintPoseFrame> rawFrames,
    required double minimumConfidence,
    required double minimumTravelRatio,
  }) {
    if (rawFrames.length < 3) {
      return 0;
    }

    final hipCenters = <Offset>[];
    final scales = <double>[];
    for (final frame in rawFrames) {
      final leftHip = frame.landmark(
        SprintPoseLandmarkType.leftHip,
        minimumConfidence: minimumConfidence,
      );
      final rightHip = frame.landmark(
        SprintPoseLandmarkType.rightHip,
        minimumConfidence: minimumConfidence,
      );
      final bounds = frame.boundingBox(minimumConfidence: minimumConfidence);
      if (leftHip == null || rightHip == null || bounds == null) {
        continue;
      }
      hipCenters.add(
        Offset(
          (leftHip.position.dx + rightHip.position.dx) / 2,
          (leftHip.position.dy + rightHip.position.dy) / 2,
        ),
      );
      scales.add(bounds.height > 0 ? bounds.height : bounds.width);
    }

    if (hipCenters.length < 3 || scales.isEmpty) {
      return 0;
    }

    final horizontalTravel = (hipCenters.last.dx - hipCenters.first.dx).abs();
    final verticalTravel = (hipCenters.last.dy - hipCenters.first.dy).abs();
    final averageScale = _average(scales);
    if (averageScale <= 0) {
      return 0;
    }

    final normalizedHorizontal = horizontalTravel / averageScale;
    final directionality =
        horizontalTravel / (horizontalTravel + verticalTravel + 0.001);
    final normalizedTravel =
        (normalizedHorizontal / minimumTravelRatio).clamp(0.0, 1.0);
    return (0.65 * directionality) + (0.35 * normalizedTravel);
  }

  bool _touchesFrameEdge(
    SprintPoseFrame? frame,
    Rect? bounds,
    SprintPipelineConfig config,
  ) {
    if (frame == null || bounds == null) {
      return false;
    }

    final marginX = frame.imageSize.width * config.frameEdgePaddingRatio;
    final marginY = frame.imageSize.height * config.frameEdgePaddingRatio;
    return bounds.left <= marginX ||
        bounds.top <= marginY ||
        bounds.right >= frame.imageSize.width - marginX ||
        bounds.bottom >= frame.imageSize.height - marginY;
  }

  Rect? _suggestedCropRect(SprintPoseFrame? frame, Rect? bounds) {
    if (frame == null || bounds == null) {
      return null;
    }

    final expandedWidth = bounds.width * 1.2;
    final expandedHeight = bounds.height * 1.16;
    final center = bounds.center;
    final desired = Rect.fromCenter(
      center: center,
      width: expandedWidth,
      height: expandedHeight,
    );
    return Rect.fromLTRB(
      desired.left.clamp(0.0, frame.imageSize.width),
      desired.top.clamp(0.0, frame.imageSize.height),
      desired.right.clamp(0.0, frame.imageSize.width),
      desired.bottom.clamp(0.0, frame.imageSize.height),
    );
  }

  double _average(List<double> values) {
    return values.reduce((sum, value) => sum + value) / values.length;
  }

  double _distance(Offset first, Offset second) {
    final dx = first.dx - second.dx;
    final dy = first.dy - second.dy;
    return math.sqrt((dx * dx) + (dy * dy));
  }
}
