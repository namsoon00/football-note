class SprintPipelineConfig {
  final Duration analysisWindow;
  final Duration feedbackCooldown;
  final double minimumLandmarkConfidence;
  final double minimumTrackingConfidence;
  final double smoothingFactor;
  final int minimumVisibleLandmarks;
  final int minimumWindowFrames;
  final double minimumRunningTravelRatio;
  final double minimumTrunkAngleDegrees;
  final double maximumAccelerationTrunkAngleDegrees;
  final double minimumKneeDriveHeightRatio;
  final double maximumStepIntervalStdMs;
  final double maximumArmSwingAsymmetryRatio;
  final Duration minimumStepEventInterval;
  final double stepDetectionHysteresis;
  final double minimumStepDetectionVelocity;

  const SprintPipelineConfig({
    this.analysisWindow = const Duration(milliseconds: 1400),
    this.feedbackCooldown = const Duration(seconds: 2),
    this.minimumLandmarkConfidence = 0.45,
    this.minimumTrackingConfidence = 0.58,
    this.smoothingFactor = 0.34,
    this.minimumVisibleLandmarks = 8,
    this.minimumWindowFrames = 6,
    this.minimumRunningTravelRatio = 0.12,
    this.minimumTrunkAngleDegrees = 8,
    this.maximumAccelerationTrunkAngleDegrees = 24,
    this.minimumKneeDriveHeightRatio = 0.24,
    this.maximumStepIntervalStdMs = 110,
    this.maximumArmSwingAsymmetryRatio = 0.18,
    this.minimumStepEventInterval = const Duration(milliseconds: 110),
    this.stepDetectionHysteresis = 0.08,
    this.minimumStepDetectionVelocity = 0.9,
  });
}
