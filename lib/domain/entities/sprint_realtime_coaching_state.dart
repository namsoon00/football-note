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

class SprintFeatureSnapshot {
  final double? trunkAngleDegrees;
  final double? kneeDriveHeightRatio;
  final Duration? stepInterval;
  final double? cadenceStepsPerMinute;
  final double? stepIntervalStdMs;
  final double? armSwingAsymmetryRatio;
  final int detectedStepEvents;
  final int stepCrossoverCount;
  final int rejectedStepEventsLowVelocity;
  final int rejectedStepEventsMinInterval;

  const SprintFeatureSnapshot({
    this.trunkAngleDegrees,
    this.kneeDriveHeightRatio,
    this.stepInterval,
    this.cadenceStepsPerMinute,
    this.stepIntervalStdMs,
    this.armSwingAsymmetryRatio,
    this.detectedStepEvents = 0,
    this.stepCrossoverCount = 0,
    this.rejectedStepEventsLowVelocity = 0,
    this.rejectedStepEventsMinInterval = 0,
  });

  const SprintFeatureSnapshot.empty() : this();

  bool get hasEnoughSignal =>
      trunkAngleDegrees != null ||
      kneeDriveHeightRatio != null ||
      stepInterval != null ||
      armSwingAsymmetryRatio != null;
}

class SprintStateEstimate {
  final bool runningDetected;
  final bool accelerationPhaseDetected;
  final bool feedbackCooldownActive;
  final bool lowConfidence;
  final bool bodyFullyVisible;
  final SprintBodyVisibilityStatus bodyVisibilityStatus;
  final double trackingConfidence;
  final int stableFrameCount;
  final int visibleLandmarkCount;
  final int visibleCoreLandmarkCount;
  final int missingCoreLandmarkCount;
  final double bodyVisibilityRatio;
  final double hipTravelRatio;

  const SprintStateEstimate({
    required this.runningDetected,
    required this.accelerationPhaseDetected,
    required this.feedbackCooldownActive,
    required this.lowConfidence,
    required this.bodyFullyVisible,
    required this.bodyVisibilityStatus,
    required this.trackingConfidence,
    required this.stableFrameCount,
    required this.visibleLandmarkCount,
    required this.visibleCoreLandmarkCount,
    required this.missingCoreLandmarkCount,
    required this.bodyVisibilityRatio,
    required this.hipTravelRatio,
  });

  const SprintStateEstimate.initial()
    : runningDetected = false,
      accelerationPhaseDetected = false,
      feedbackCooldownActive = false,
      lowConfidence = true,
      bodyFullyVisible = false,
      bodyVisibilityStatus = SprintBodyVisibilityStatus.notVisible,
      trackingConfidence = 0,
      stableFrameCount = 0,
      visibleLandmarkCount = 0,
      visibleCoreLandmarkCount = 0,
      missingCoreLandmarkCount = sprintMvpCoreLandmarkCount,
      bodyVisibilityRatio = 0,
      hipTravelRatio = 0;
}

class SprintFeedbackMessage {
  final SprintFeedbackCode code;
  final int priority;
  final String localizationKey;
  final String debugLabel;

  const SprintFeedbackMessage({
    required this.code,
    required this.priority,
    required this.localizationKey,
    required this.debugLabel,
  });
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

  String? get activeFeedbackKey => feedback?.localizationKey;

  String? get activeFeedbackDebugText => feedback?.debugLabel;

  bool get bodyNotVisibleActive =>
      stateEstimate.bodyVisibilityStatus != SprintBodyVisibilityStatus.full;
}
