import 'dart:ui';

import 'sprint_pose_frame.dart';

enum SprintCoachingStatus { collecting, lowConfidence, ready, coaching }

enum SprintFeedbackCode {
  bodyNotVisible,
  leanForwardMore,
  driveKneeHigher,
  keepRhythmSteady,
  balanceArmSwing,
  keepPushing,
}

enum SprintBodyVisibilityStatus { notVisible, partial, full }

enum SprintTrackingReadiness {
  bodyTooSmall,
  bodyPartiallyOutOfFrame,
  lowConfidence,
  sideViewUnstable,
  readyForAnalysis,
}

enum SprintFeedbackSeverity { info, caution, warning }

class SprintMeasuredValue {
  final double? value;
  final double confidence;
  final bool available;
  final String? reasonIfUnavailable;
  final int sampleCount;

  const SprintMeasuredValue({
    required this.value,
    required this.confidence,
    required this.available,
    required this.reasonIfUnavailable,
    required this.sampleCount,
  });

  const SprintMeasuredValue.unavailable({
    this.confidence = 0,
    this.reasonIfUnavailable,
    this.sampleCount = 0,
  })  : value = null,
        available = false;

  const SprintMeasuredValue.available({
    required this.value,
    required this.confidence,
    required this.sampleCount,
  })  : available = true,
        reasonIfUnavailable = null;
}

class SprintFeatureSnapshot {
  final SprintMeasuredValue trunkAngle;
  final SprintMeasuredValue kneeDrive;
  final SprintMeasuredValue cadence;
  final SprintMeasuredValue rhythm;
  final SprintMeasuredValue armBalance;
  final Duration? stepInterval;
  final int detectedStepEvents;
  final int stepCrossoverCount;
  final int rejectedStepEventsLowVelocity;
  final int rejectedStepEventsMinInterval;

  const SprintFeatureSnapshot({
    this.trunkAngle = const SprintMeasuredValue.unavailable(
      reasonIfUnavailable: 'insufficient_joint_window',
    ),
    this.kneeDrive = const SprintMeasuredValue.unavailable(
      reasonIfUnavailable: 'insufficient_joint_window',
    ),
    this.cadence = const SprintMeasuredValue.unavailable(
      reasonIfUnavailable: 'insufficient_step_events',
    ),
    this.rhythm = const SprintMeasuredValue.unavailable(
      reasonIfUnavailable: 'insufficient_step_events',
    ),
    this.armBalance = const SprintMeasuredValue.unavailable(
      reasonIfUnavailable: 'insufficient_joint_window',
    ),
    this.stepInterval,
    this.detectedStepEvents = 0,
    this.stepCrossoverCount = 0,
    this.rejectedStepEventsLowVelocity = 0,
    this.rejectedStepEventsMinInterval = 0,
  });

  const SprintFeatureSnapshot.empty() : this();

  double? get trunkAngleDegrees => trunkAngle.value;

  double? get kneeDriveHeightRatio => kneeDrive.value;

  double? get cadenceStepsPerMinute => cadence.value;

  double? get stepIntervalStdMs => rhythm.value;

  double? get armSwingAsymmetryRatio => armBalance.value;

  bool get hasEnoughSignal =>
      trunkAngle.available ||
      kneeDrive.available ||
      rhythm.available ||
      armBalance.available;
}

class SprintStateEstimate {
  final bool runningDetected;
  final bool accelerationPhaseDetected;
  final bool feedbackCooldownActive;
  final bool lowConfidence;
  final bool bodyFullyVisible;
  final SprintBodyVisibilityStatus bodyVisibilityStatus;
  final SprintTrackingReadiness trackingReadiness;
  final double trackingConfidence;
  final int stableFrameCount;
  final int visibleLandmarkCount;
  final int visibleCoreLandmarkCount;
  final int missingCoreLandmarkCount;
  final double bodyVisibilityRatio;
  final double hipTravelRatio;
  final double personHeightRatio;
  final double personAreaRatio;
  final double averageLandmarkConfidence;
  final double sideViewConfidence;
  final Rect? personBounds;
  final Rect? suggestedCropRect;

  const SprintStateEstimate({
    required this.runningDetected,
    required this.accelerationPhaseDetected,
    required this.feedbackCooldownActive,
    required this.lowConfidence,
    required this.bodyFullyVisible,
    required this.bodyVisibilityStatus,
    required this.trackingReadiness,
    required this.trackingConfidence,
    required this.stableFrameCount,
    required this.visibleLandmarkCount,
    required this.visibleCoreLandmarkCount,
    required this.missingCoreLandmarkCount,
    required this.bodyVisibilityRatio,
    required this.hipTravelRatio,
    required this.personHeightRatio,
    required this.personAreaRatio,
    required this.averageLandmarkConfidence,
    required this.sideViewConfidence,
    required this.personBounds,
    required this.suggestedCropRect,
  });

  const SprintStateEstimate.initial()
      : runningDetected = false,
        accelerationPhaseDetected = false,
        feedbackCooldownActive = false,
        lowConfidence = true,
        bodyFullyVisible = false,
        bodyVisibilityStatus = SprintBodyVisibilityStatus.notVisible,
        trackingReadiness = SprintTrackingReadiness.lowConfidence,
        trackingConfidence = 0,
        stableFrameCount = 0,
        visibleLandmarkCount = 0,
        visibleCoreLandmarkCount = 0,
        missingCoreLandmarkCount = sprintMvpCoreLandmarkCount,
        bodyVisibilityRatio = 0,
        hipTravelRatio = 0,
        personHeightRatio = 0,
        personAreaRatio = 0,
        averageLandmarkConfidence = 0,
        sideViewConfidence = 0,
        personBounds = null,
        suggestedCropRect = null;

  bool get bodyTooSmall =>
      trackingReadiness == SprintTrackingReadiness.bodyTooSmall;

  bool get bodyPartiallyOutOfFrame =>
      trackingReadiness == SprintTrackingReadiness.bodyPartiallyOutOfFrame;
}

class SprintFeedbackMessage {
  final SprintFeedbackCode code;
  final int priority;
  final String cueKey;
  final String diagnosisKey;
  final String actionTipKey;
  final SprintFeedbackSeverity severity;
  final double confidence;
  final List<String> sourceFeatures;
  final String cooldownKey;
  final String debugLabel;

  const SprintFeedbackMessage({
    required this.code,
    required this.priority,
    required this.cueKey,
    required this.diagnosisKey,
    required this.actionTipKey,
    required this.severity,
    required this.confidence,
    required this.sourceFeatures,
    required this.cooldownKey,
    required this.debugLabel,
  });

  String get localizationKey => cueKey;
}

class SprintRealtimeCoachingState {
  final SprintCoachingStatus status;
  final SprintFeatureSnapshot features;
  final SprintStateEstimate stateEstimate;
  final SprintFeedbackMessage? feedback;
  final int processedFrames;
  final int trackedFrames;
  final DateTime? lastFeedbackAt;
  final bool feedbackSwitchSuppressedByCooldown;

  const SprintRealtimeCoachingState({
    required this.status,
    required this.features,
    required this.stateEstimate,
    this.feedback,
    this.processedFrames = 0,
    this.trackedFrames = 0,
    this.lastFeedbackAt,
    this.feedbackSwitchSuppressedByCooldown = false,
  });

  const SprintRealtimeCoachingState.initial()
      : status = SprintCoachingStatus.collecting,
        features = const SprintFeatureSnapshot.empty(),
        stateEstimate = const SprintStateEstimate.initial(),
        feedback = null,
        processedFrames = 0,
        trackedFrames = 0,
        lastFeedbackAt = null,
        feedbackSwitchSuppressedByCooldown = false;

  String? get activeFeedbackKey => feedback?.cueKey;

  String? get activeFeedbackDebugText => feedback?.debugLabel;

  bool get bodyNotVisibleActive =>
      stateEstimate.trackingReadiness !=
      SprintTrackingReadiness.readyForAnalysis;
}
