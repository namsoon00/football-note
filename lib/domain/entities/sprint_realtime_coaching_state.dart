enum SprintCoachingStatus { collecting, lowConfidence, ready, coaching }

enum SprintFeedbackCode {
  bodyNotVisible,
  leanForwardMore,
  driveKneeHigher,
  keepRhythmSteady,
  balanceArmSwing,
  keepPushing,
}

class SprintFeatureSnapshot {
  final double? trunkAngleDegrees;
  final double? kneeDriveHeightRatio;
  final Duration? stepInterval;
  final double? cadenceStepsPerMinute;
  final double? stepIntervalStdMs;
  final double? armSwingAsymmetryRatio;
  final int detectedStepEvents;

  const SprintFeatureSnapshot({
    this.trunkAngleDegrees,
    this.kneeDriveHeightRatio,
    this.stepInterval,
    this.cadenceStepsPerMinute,
    this.stepIntervalStdMs,
    this.armSwingAsymmetryRatio,
    this.detectedStepEvents = 0,
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
  final double trackingConfidence;
  final int stableFrameCount;

  const SprintStateEstimate({
    required this.runningDetected,
    required this.accelerationPhaseDetected,
    required this.feedbackCooldownActive,
    required this.lowConfidence,
    required this.bodyFullyVisible,
    required this.trackingConfidence,
    required this.stableFrameCount,
  });

  const SprintStateEstimate.initial()
    : runningDetected = false,
      accelerationPhaseDetected = false,
      feedbackCooldownActive = false,
      lowConfidence = true,
      bodyFullyVisible = false,
      trackingConfidence = 0,
      stableFrameCount = 0;
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

  const SprintRealtimeCoachingState({
    required this.status,
    required this.features,
    required this.stateEstimate,
    this.feedback,
    this.processedFrames = 0,
    this.trackedFrames = 0,
    this.lastFeedbackAt,
  });

  const SprintRealtimeCoachingState.initial()
    : status = SprintCoachingStatus.collecting,
      features = const SprintFeatureSnapshot.empty(),
      stateEstimate = const SprintStateEstimate.initial(),
      feedback = null,
      processedFrames = 0,
      trackedFrames = 0,
      lastFeedbackAt = null;
}
