import 'dart:math' as math;

import '../domain/entities/running_coach_session.dart';

class LiveSprintCaptureContextService {
  static const double tabletShortestSideThreshold = 600;
  static const double minimumReliableFrameQuality = 0.75;
  static const double minimumReliableJointConfidence = 0.70;
  static const int minimumReliablePoseFrames = 2;
  static const int minimumReliableObservedJoints = 8;

  const LiveSprintCaptureContextService();

  LiveSprintCaptureContext build({
    required LiveSprintDeviceClass deviceClass,
    required LiveSprintCameraLensDirection cameraLensDirection,
    required List<LiveSprintPoseEvidenceFrame> poseEvidence,
    required LiveSprintPoseEvidenceDiagnostic poseEvidenceDiagnostic,
  }) {
    return LiveSprintCaptureContext(
      deviceClass: deviceClass,
      cameraLensDirection: cameraLensDirection,
      distanceBand: _distanceBandFor(poseEvidence),
      viewBand: _viewBandFor(poseEvidence, poseEvidenceDiagnostic),
    );
  }

  static LiveSprintDeviceClass deviceClassForShortestSide(
    double shortestSide,
  ) {
    if (!shortestSide.isFinite || shortestSide <= 0) {
      return LiveSprintDeviceClass.unknown;
    }
    return shortestSide >= tabletShortestSideThreshold
        ? LiveSprintDeviceClass.tablet
        : LiveSprintDeviceClass.phone;
  }

  LiveSprintCaptureDistanceBand _distanceBandFor(
    List<LiveSprintPoseEvidenceFrame> poseEvidence,
  ) {
    final bodyHeights = poseEvidence
        .map(_reliableBodyHeight)
        .whereType<double>()
        .toList(growable: false);
    if (bodyHeights.length < minimumReliablePoseFrames) {
      return LiveSprintCaptureDistanceBand.unknown;
    }
    final averageHeight = _average(bodyHeights);
    if (averageHeight >= 0.68) {
      return LiveSprintCaptureDistanceBand.close;
    }
    if (averageHeight >= 0.46) {
      return LiveSprintCaptureDistanceBand.normal;
    }
    if (averageHeight >= 0.28) {
      return LiveSprintCaptureDistanceBand.far;
    }
    return LiveSprintCaptureDistanceBand.unknown;
  }

  double? _reliableBodyHeight(LiveSprintPoseEvidenceFrame frame) {
    if (frame.quality < minimumReliableFrameQuality) {
      return null;
    }
    final reliableJoints = frame.joints
        .where(
          (joint) =>
              joint.observed &&
              joint.confidence >= minimumReliableJointConfidence &&
              joint.x.isFinite &&
              joint.y.isFinite,
        )
        .toList(growable: false);
    if (reliableJoints.length < minimumReliableObservedJoints) {
      return null;
    }
    var minY = 1.0;
    var maxY = 0.0;
    for (final joint in reliableJoints) {
      minY = math.min(minY, joint.y.clamp(0.0, 1.0).toDouble());
      maxY = math.max(maxY, joint.y.clamp(0.0, 1.0).toDouble());
    }
    final height = (maxY - minY).clamp(0.0, 1.0).toDouble();
    if (height < 0.20 || height > 0.95) {
      return null;
    }
    return height;
  }

  LiveSprintViewBand _viewBandFor(
    List<LiveSprintPoseEvidenceFrame> poseEvidence,
    LiveSprintPoseEvidenceDiagnostic diagnostic,
  ) {
    final readinessValue =
        diagnostic.readinessSummary.sideView.value.clamp(0.0, 1.0).toDouble();
    final evidenceValues = poseEvidence
        .map((evidence) => evidence.sideViewConfidence)
        .where((value) => value.isFinite && value > 0)
        .map((value) => value.clamp(0.0, 1.0).toDouble())
        .toList(growable: false);
    final value = readinessValue > 0
        ? readinessValue
        : evidenceValues.isEmpty
            ? 0.0
            : _average(evidenceValues);
    if (value >= 0.80) {
      return LiveSprintViewBand.clearSide;
    }
    if (value >= 0.66) {
      return LiveSprintViewBand.partialSide;
    }
    if (value >= 0.45) {
      return LiveSprintViewBand.oblique;
    }
    return LiveSprintViewBand.unknown;
  }

  double _average(List<double> values) {
    if (values.isEmpty) {
      return 0;
    }
    return values.reduce((sum, value) => sum + value) / values.length;
  }
}
