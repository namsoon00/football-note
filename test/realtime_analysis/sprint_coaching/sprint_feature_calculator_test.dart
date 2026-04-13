import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/entities/sprint_pose_frame.dart';
import 'package:football_note/realtime_analysis/sprint_coaching/sprint_feature_calculator.dart';
import 'package:football_note/realtime_analysis/sprint_coaching/sprint_pose_normalizer.dart';

void main() {
  group('SprintFeatureCalculator', () {
    test('calculates stable sprint metrics from normalized frames', () {
      final calculator = SprintFeatureCalculator();
      final start = DateTime(2026, 4, 13, 9);

      final snapshot = calculator.calculate(<SprintNormalizedPoseFrame>[
        _frame(
          timestamp: start,
          leftAnkleX: 0.24,
          rightAnkleX: -0.24,
          kneeDriveHeight: 0.34,
        ),
        _frame(
          timestamp: start.add(const Duration(milliseconds: 250)),
          leftAnkleX: -0.22,
          rightAnkleX: 0.22,
          kneeDriveHeight: 0.38,
        ),
        _frame(
          timestamp: start.add(const Duration(milliseconds: 500)),
          leftAnkleX: 0.26,
          rightAnkleX: -0.26,
          kneeDriveHeight: 0.41,
        ),
        _frame(
          timestamp: start.add(const Duration(milliseconds: 750)),
          leftAnkleX: -0.21,
          rightAnkleX: 0.21,
          kneeDriveHeight: 0.37,
        ),
        _frame(
          timestamp: start.add(const Duration(milliseconds: 1000)),
          leftAnkleX: 0.23,
          rightAnkleX: -0.23,
          kneeDriveHeight: 0.35,
        ),
      ]);

      expect(snapshot.trunkAngleDegrees, closeTo(11.3099, 0.001));
      expect(snapshot.kneeDriveHeightRatio, closeTo(0.41, 0.001));
      expect(snapshot.stepInterval, const Duration(milliseconds: 250));
      expect(snapshot.cadenceStepsPerMinute, closeTo(240, 0.001));
      expect(snapshot.stepIntervalStdMs, closeTo(0, 0.001));
      expect(snapshot.armSwingAsymmetryRatio, closeTo(0.0434, 0.001));
      expect(snapshot.detectedStepEvents, 4);
      expect(snapshot.hasEnoughSignal, isTrue);
    });
  });
}

SprintNormalizedPoseFrame _frame({
  required DateTime timestamp,
  required double leftAnkleX,
  required double rightAnkleX,
  required double kneeDriveHeight,
}) {
  const shoulderCenter = Offset(0.2, -1);
  const leftShoulder = Offset(0.0, -1);
  const rightShoulder = Offset(0.4, -1);

  return SprintNormalizedPoseFrame(
    timestamp: timestamp,
    bodyScale: 1,
    hipCenter: Offset.zero,
    shoulderCenter: shoulderCenter,
    normalizedLandmarks: <SprintPoseLandmarkType, Offset>{
      SprintPoseLandmarkType.leftShoulder: leftShoulder,
      SprintPoseLandmarkType.rightShoulder: rightShoulder,
      SprintPoseLandmarkType.leftHip: const Offset(-0.14, 0),
      SprintPoseLandmarkType.rightHip: const Offset(0.14, 0),
      SprintPoseLandmarkType.leftElbow: const Offset(-0.12, -0.62),
      SprintPoseLandmarkType.rightElbow: const Offset(0.52, -0.62),
      SprintPoseLandmarkType.leftWrist: const Offset(-0.44, -0.26),
      SprintPoseLandmarkType.rightWrist: const Offset(0.86, -0.26),
      SprintPoseLandmarkType.leftKnee: const Offset(-0.16, -0.18),
      SprintPoseLandmarkType.rightKnee: Offset(0.16, -kneeDriveHeight),
      SprintPoseLandmarkType.leftAnkle: Offset(leftAnkleX, 1),
      SprintPoseLandmarkType.rightAnkle: Offset(rightAnkleX, 1),
    },
  );
}
