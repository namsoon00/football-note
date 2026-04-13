enum SprintPipelineTuningPreset { conservative, balanced, responsive }

class SprintPipelineConfig {
  final SprintPipelineTuningPreset preset;
  final Duration analysisWindow;
  final Duration feedbackCooldown;
  final Duration minimumAnalysisInterval;
  final double minimumLandmarkConfidence;
  final double minimumTrackingConfidence;
  final double smoothingFactor;
  final int minimumVisibleLandmarks;
  final double minimumBodyVisibilityRatio;
  final int minimumWindowFrames;
  final double minimumRunningTravelRatio;
  final int minimumStepEventsForRunning;
  final double minimumRunningCadenceStepsPerMinute;
  final double minimumStepDrivenTravelRatio;
  final double minimumTrunkAngleDegrees;
  final double maximumAccelerationTrunkAngleDegrees;
  final double minimumKneeDriveHeight;
  final double maximumStepIntervalStdMs;
  final double maximumArmAsymmetryRatio;
  final Duration minimumStepEventInterval;
  final double stepDetectionHysteresis;
  final double minimumStepDetectionVelocity;

  const SprintPipelineConfig({
    this.preset = SprintPipelineTuningPreset.balanced,
    this.analysisWindow = const Duration(milliseconds: 1400),
    this.feedbackCooldown = const Duration(seconds: 2),
    this.minimumAnalysisInterval = const Duration(milliseconds: 100),
    this.minimumLandmarkConfidence = 0.45,
    this.minimumTrackingConfidence = 0.58,
    this.smoothingFactor = 0.34,
    this.minimumVisibleLandmarks = 8,
    this.minimumBodyVisibilityRatio = 1,
    this.minimumWindowFrames = 6,
    this.minimumRunningTravelRatio = 0.12,
    this.minimumStepEventsForRunning = 3,
    this.minimumRunningCadenceStepsPerMinute = 150,
    this.minimumStepDrivenTravelRatio = 0.04,
    this.minimumTrunkAngleDegrees = 8,
    this.maximumAccelerationTrunkAngleDegrees = 24,
    this.minimumKneeDriveHeight = 0.24,
    this.maximumStepIntervalStdMs = 110,
    this.maximumArmAsymmetryRatio = 0.18,
    this.minimumStepEventInterval = const Duration(milliseconds: 110),
    this.stepDetectionHysteresis = 0.08,
    this.minimumStepDetectionVelocity = 0.9,
  });

  const SprintPipelineConfig.conservative()
    : this(
        preset: SprintPipelineTuningPreset.conservative,
        analysisWindow: const Duration(milliseconds: 1500),
        feedbackCooldown: const Duration(milliseconds: 2200),
        minimumAnalysisInterval: const Duration(milliseconds: 120),
        minimumLandmarkConfidence: 0.5,
        minimumTrackingConfidence: 0.62,
        smoothingFactor: 0.3,
        minimumVisibleLandmarks: 9,
        minimumBodyVisibilityRatio: 1,
        minimumWindowFrames: 7,
        minimumRunningTravelRatio: 0.14,
        minimumStepEventsForRunning: 4,
        minimumRunningCadenceStepsPerMinute: 158,
        minimumStepDrivenTravelRatio: 0.05,
        minimumTrunkAngleDegrees: 9,
        maximumAccelerationTrunkAngleDegrees: 22,
        minimumKneeDriveHeight: 0.27,
        maximumStepIntervalStdMs: 100,
        maximumArmAsymmetryRatio: 0.16,
        minimumStepEventInterval: const Duration(milliseconds: 120),
        stepDetectionHysteresis: 0.09,
        minimumStepDetectionVelocity: 1.0,
      );

  const SprintPipelineConfig.responsive()
    : this(
        preset: SprintPipelineTuningPreset.responsive,
        analysisWindow: const Duration(milliseconds: 1100),
        feedbackCooldown: const Duration(milliseconds: 1600),
        minimumAnalysisInterval: const Duration(milliseconds: 80),
        minimumLandmarkConfidence: 0.4,
        minimumTrackingConfidence: 0.52,
        smoothingFactor: 0.42,
        minimumVisibleLandmarks: 7,
        minimumBodyVisibilityRatio: 0.92,
        minimumWindowFrames: 5,
        minimumRunningTravelRatio: 0.1,
        minimumStepEventsForRunning: 3,
        minimumRunningCadenceStepsPerMinute: 145,
        minimumStepDrivenTravelRatio: 0.03,
        minimumTrunkAngleDegrees: 7,
        maximumAccelerationTrunkAngleDegrees: 26,
        minimumKneeDriveHeight: 0.22,
        maximumStepIntervalStdMs: 125,
        maximumArmAsymmetryRatio: 0.2,
        minimumStepEventInterval: const Duration(milliseconds: 95),
        stepDetectionHysteresis: 0.06,
        minimumStepDetectionVelocity: 0.75,
      );

  SprintPipelineConfig copyWith({
    SprintPipelineTuningPreset? preset,
    Duration? analysisWindow,
    Duration? feedbackCooldown,
    Duration? minimumAnalysisInterval,
    double? minimumLandmarkConfidence,
    double? minimumTrackingConfidence,
    double? smoothingFactor,
    int? minimumVisibleLandmarks,
    double? minimumBodyVisibilityRatio,
    int? minimumWindowFrames,
    double? minimumRunningTravelRatio,
    int? minimumStepEventsForRunning,
    double? minimumRunningCadenceStepsPerMinute,
    double? minimumStepDrivenTravelRatio,
    double? minimumTrunkAngleDegrees,
    double? maximumAccelerationTrunkAngleDegrees,
    double? minimumKneeDriveHeight,
    double? maximumStepIntervalStdMs,
    double? maximumArmAsymmetryRatio,
    Duration? minimumStepEventInterval,
    double? stepDetectionHysteresis,
    double? minimumStepDetectionVelocity,
  }) {
    return SprintPipelineConfig(
      preset: preset ?? this.preset,
      analysisWindow: analysisWindow ?? this.analysisWindow,
      feedbackCooldown: feedbackCooldown ?? this.feedbackCooldown,
      minimumAnalysisInterval:
          minimumAnalysisInterval ?? this.minimumAnalysisInterval,
      minimumLandmarkConfidence:
          minimumLandmarkConfidence ?? this.minimumLandmarkConfidence,
      minimumTrackingConfidence:
          minimumTrackingConfidence ?? this.minimumTrackingConfidence,
      smoothingFactor: smoothingFactor ?? this.smoothingFactor,
      minimumVisibleLandmarks:
          minimumVisibleLandmarks ?? this.minimumVisibleLandmarks,
      minimumBodyVisibilityRatio:
          minimumBodyVisibilityRatio ?? this.minimumBodyVisibilityRatio,
      minimumWindowFrames: minimumWindowFrames ?? this.minimumWindowFrames,
      minimumRunningTravelRatio:
          minimumRunningTravelRatio ?? this.minimumRunningTravelRatio,
      minimumStepEventsForRunning:
          minimumStepEventsForRunning ?? this.minimumStepEventsForRunning,
      minimumRunningCadenceStepsPerMinute:
          minimumRunningCadenceStepsPerMinute ??
          this.minimumRunningCadenceStepsPerMinute,
      minimumStepDrivenTravelRatio:
          minimumStepDrivenTravelRatio ?? this.minimumStepDrivenTravelRatio,
      minimumTrunkAngleDegrees:
          minimumTrunkAngleDegrees ?? this.minimumTrunkAngleDegrees,
      maximumAccelerationTrunkAngleDegrees:
          maximumAccelerationTrunkAngleDegrees ??
          this.maximumAccelerationTrunkAngleDegrees,
      minimumKneeDriveHeight:
          minimumKneeDriveHeight ?? this.minimumKneeDriveHeight,
      maximumStepIntervalStdMs:
          maximumStepIntervalStdMs ?? this.maximumStepIntervalStdMs,
      maximumArmAsymmetryRatio:
          maximumArmAsymmetryRatio ?? this.maximumArmAsymmetryRatio,
      minimumStepEventInterval:
          minimumStepEventInterval ?? this.minimumStepEventInterval,
      stepDetectionHysteresis:
          stepDetectionHysteresis ?? this.stepDetectionHysteresis,
      minimumStepDetectionVelocity:
          minimumStepDetectionVelocity ?? this.minimumStepDetectionVelocity,
    );
  }
}
