import '../domain/entities/sprint_capture_calibration_profile.dart';
import '../domain/repositories/option_repository.dart';
import '../realtime_analysis/sprint_coaching/sprint_pipeline_config.dart';

class SprintCaptureEvidenceThresholds {
  final double minimumLandmarkConfidence;
  final double minimumAverageLandmarkConfidence;
  final double minimumTrackingConfidence;
  final double minimumSideViewConfidence;
  final double minimumPhaseConfidence;
  final Duration maximumTouchdownCaptureDelay;

  const SprintCaptureEvidenceThresholds({
    required this.minimumLandmarkConfidence,
    required this.minimumAverageLandmarkConfidence,
    required this.minimumTrackingConfidence,
    required this.minimumSideViewConfidence,
    required this.minimumPhaseConfidence,
    required this.maximumTouchdownCaptureDelay,
  });

  const SprintCaptureEvidenceThresholds.balanced()
      : this(
          minimumLandmarkConfidence: 0.58,
          minimumAverageLandmarkConfidence: 0.70,
          minimumTrackingConfidence: 0.70,
          minimumSideViewConfidence: 0.65,
          minimumPhaseConfidence: 0.62,
          maximumTouchdownCaptureDelay: const Duration(milliseconds: 150),
        );
}

class SprintCaptureCalibrationProfileService {
  static const selectedProfileOptionKey =
      'sprint_capture_calibration_profile_v1';

  final OptionRepository? _repository;

  const SprintCaptureCalibrationProfileService([this._repository]);

  SprintCaptureCalibrationProfile loadSelectedProfile() {
    return sprintCaptureCalibrationProfileFromName(
      _repository?.getValue<String>(selectedProfileOptionKey),
    );
  }

  Future<void> saveSelectedProfile(
    SprintCaptureCalibrationProfile profile,
  ) async {
    final repository = _repository;
    if (repository == null) {
      return;
    }
    await repository.setValue(selectedProfileOptionKey, profile.name);
  }

  static SprintPipelineConfig pipelineConfigFor(
    SprintCaptureCalibrationProfile profile,
  ) {
    return switch (profile) {
      SprintCaptureCalibrationProfile.conservative =>
        const SprintPipelineConfig.conservative(),
      SprintCaptureCalibrationProfile.balanced => const SprintPipelineConfig(),
      SprintCaptureCalibrationProfile.responsive =>
        const SprintPipelineConfig.responsive(),
    };
  }

  static SprintCaptureEvidenceThresholds evidenceThresholdsFor(
    SprintCaptureCalibrationProfile profile,
  ) {
    return switch (profile) {
      SprintCaptureCalibrationProfile.conservative =>
        const SprintCaptureEvidenceThresholds(
          minimumLandmarkConfidence: 0.62,
          minimumAverageLandmarkConfidence: 0.76,
          minimumTrackingConfidence: 0.76,
          minimumSideViewConfidence: 0.70,
          minimumPhaseConfidence: 0.68,
          maximumTouchdownCaptureDelay: Duration(milliseconds: 130),
        ),
      SprintCaptureCalibrationProfile.balanced =>
        const SprintCaptureEvidenceThresholds.balanced(),
      SprintCaptureCalibrationProfile.responsive =>
        const SprintCaptureEvidenceThresholds(
          minimumLandmarkConfidence: 0.52,
          minimumAverageLandmarkConfidence: 0.64,
          minimumTrackingConfidence: 0.62,
          minimumSideViewConfidence: 0.58,
          minimumPhaseConfidence: 0.56,
          maximumTouchdownCaptureDelay: Duration(milliseconds: 180),
        ),
    };
  }
}
