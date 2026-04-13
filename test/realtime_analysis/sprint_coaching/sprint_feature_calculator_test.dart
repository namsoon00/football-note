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
      expect(snapshot.stepCrossoverCount, 4);
      expect(snapshot.rejectedStepEventsLowVelocity, 0);
      expect(snapshot.rejectedStepEventsMinInterval, 0);
      expect(snapshot.hasEnoughSignal, isTrue);
    });

    test('suppresses jitter that never clears hysteresis', () {
      final calculator = SprintFeatureCalculator();
      final start = DateTime(2026, 4, 13, 9);

      final snapshot = calculator.calculate(<SprintNormalizedPoseFrame>[
        _frame(
          timestamp: start,
          leftAnkleX: 0.03,
          rightAnkleX: -0.03,
          kneeDriveHeight: 0.28,
        ),
        _frame(
          timestamp: start.add(const Duration(milliseconds: 120)),
          leftAnkleX: -0.02,
          rightAnkleX: 0.02,
          kneeDriveHeight: 0.29,
        ),
        _frame(
          timestamp: start.add(const Duration(milliseconds: 240)),
          leftAnkleX: 0.04,
          rightAnkleX: -0.04,
          kneeDriveHeight: 0.31,
        ),
        _frame(
          timestamp: start.add(const Duration(milliseconds: 360)),
          leftAnkleX: -0.03,
          rightAnkleX: 0.03,
          kneeDriveHeight: 0.3,
        ),
      ]);

      expect(snapshot.detectedStepEvents, 0);
      expect(snapshot.stepCrossoverCount, 0);
      expect(snapshot.rejectedStepEventsLowVelocity, 0);
      expect(snapshot.rejectedStepEventsMinInterval, 0);
      expect(snapshot.stepInterval, isNull);
      expect(snapshot.cadenceStepsPerMinute, isNull);
    });

    test(
      'suppresses crossings that are slower than the velocity threshold',
      () {
        final calculator = SprintFeatureCalculator();
        final start = DateTime(2026, 4, 13, 9);

        final snapshot = calculator.calculate(<SprintNormalizedPoseFrame>[
          _frame(
            timestamp: start,
            leftAnkleX: 0.12,
            rightAnkleX: -0.12,
            kneeDriveHeight: 0.3,
          ),
          _frame(
            timestamp: start.add(const Duration(milliseconds: 400)),
            leftAnkleX: -0.12,
            rightAnkleX: 0.12,
            kneeDriveHeight: 0.31,
          ),
          _frame(
            timestamp: start.add(const Duration(milliseconds: 800)),
            leftAnkleX: 0.13,
            rightAnkleX: -0.13,
            kneeDriveHeight: 0.32,
          ),
        ], minimumStepDetectionVelocity: 1.4);

        expect(snapshot.detectedStepEvents, 0);
        expect(snapshot.stepCrossoverCount, 2);
        expect(snapshot.rejectedStepEventsLowVelocity, 2);
        expect(snapshot.rejectedStepEventsMinInterval, 0);
        expect(snapshot.stepInterval, isNull);
      },
    );

    test('tracks crossings rejected by the minimum event interval', () {
      final calculator = SprintFeatureCalculator();
      final start = DateTime(2026, 4, 13, 9);

      final snapshot = calculator.calculate(<SprintNormalizedPoseFrame>[
        _frame(
          timestamp: start,
          leftAnkleX: 0.16,
          rightAnkleX: -0.16,
          kneeDriveHeight: 0.32,
        ),
        _frame(
          timestamp: start.add(const Duration(milliseconds: 120)),
          leftAnkleX: -0.16,
          rightAnkleX: 0.16,
          kneeDriveHeight: 0.33,
        ),
        _frame(
          timestamp: start.add(const Duration(milliseconds: 180)),
          leftAnkleX: 0.16,
          rightAnkleX: -0.16,
          kneeDriveHeight: 0.34,
        ),
        _frame(
          timestamp: start.add(const Duration(milliseconds: 340)),
          leftAnkleX: -0.16,
          rightAnkleX: 0.16,
          kneeDriveHeight: 0.35,
        ),
      ], minimumStepEventInterval: const Duration(milliseconds: 110));

      expect(snapshot.stepCrossoverCount, 3);
      expect(snapshot.detectedStepEvents, 2);
      expect(snapshot.rejectedStepEventsLowVelocity, 0);
      expect(snapshot.rejectedStepEventsMinInterval, 1);
      expect(snapshot.stepInterval, const Duration(milliseconds: 220));
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
