enum SprintCaptureCalibrationProfile { conservative, balanced, responsive }

SprintCaptureCalibrationProfile sprintCaptureCalibrationProfileFromName(
  String? name,
) {
  for (final profile in SprintCaptureCalibrationProfile.values) {
    if (profile.name == name) {
      return profile;
    }
  }
  return SprintCaptureCalibrationProfile.balanced;
}
