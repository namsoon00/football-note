import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/sprint_capture_calibration_service.dart';
import 'package:football_note/domain/entities/sprint_capture_calibration_profile.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/realtime_analysis/sprint_coaching/sprint_pipeline_config.dart';

void main() {
  test('loads balanced when no local profile has been selected', () {
    final service = SprintCaptureCalibrationProfileService(
      _MemoryOptionRepository(),
    );

    expect(
      service.loadSelectedProfile(),
      SprintCaptureCalibrationProfile.balanced,
    );
  });

  test('persists and parses the selected local capture profile', () async {
    final repository = _MemoryOptionRepository();
    final service = SprintCaptureCalibrationProfileService(repository);

    await service
        .saveSelectedProfile(SprintCaptureCalibrationProfile.responsive);

    expect(
      repository.getValue<String>(
        SprintCaptureCalibrationProfileService.selectedProfileOptionKey,
      ),
      'responsive',
    );
    expect(
      service.loadSelectedProfile(),
      SprintCaptureCalibrationProfile.responsive,
    );
  });

  test('falls back to balanced for legacy or invalid option values', () async {
    final repository = _MemoryOptionRepository();
    await repository.setValue(
      SprintCaptureCalibrationProfileService.selectedProfileOptionKey,
      'legacy-fast',
    );

    expect(
      SprintCaptureCalibrationProfileService(repository).loadSelectedProfile(),
      SprintCaptureCalibrationProfile.balanced,
    );
  });

  test('maps profiles to sprint pipeline and evidence thresholds', () {
    final strictConfig =
        SprintCaptureCalibrationProfileService.pipelineConfigFor(
            SprintCaptureCalibrationProfile.conservative);
    final responsiveConfig =
        SprintCaptureCalibrationProfileService.pipelineConfigFor(
            SprintCaptureCalibrationProfile.responsive);
    final strictEvidence =
        SprintCaptureCalibrationProfileService.evidenceThresholdsFor(
            SprintCaptureCalibrationProfile.conservative);
    final responsiveEvidence =
        SprintCaptureCalibrationProfileService.evidenceThresholdsFor(
            SprintCaptureCalibrationProfile.responsive);

    expect(strictConfig.preset, SprintPipelineTuningPreset.conservative);
    expect(responsiveConfig.preset, SprintPipelineTuningPreset.responsive);
    expect(
      strictEvidence.minimumAverageLandmarkConfidence,
      greaterThan(responsiveEvidence.minimumAverageLandmarkConfidence),
    );
    expect(
      strictEvidence.maximumTouchdownCaptureDelay,
      lessThan(responsiveEvidence.maximumTouchdownCaptureDelay),
    );
  });
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    if (value is List) {
      return value.map((item) => item.toString()).toList(growable: false);
    }
    return defaults;
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    if (value is List) {
      return value
          .map((item) => int.tryParse(item.toString()) ?? 0)
          .toList(growable: false);
    }
    return defaults;
  }

  @override
  T? getValue<T>(String key) => _values[key] as T?;

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    _values[key] = options;
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    _values[key] = value;
  }
}
