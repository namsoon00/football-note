import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/entities/running_live_coaching_state.dart';
import 'package:football_note/presentation/models/running_pose_anatomy.dart';
import 'package:football_note/realtime_analysis/running_coaching/running_visual_pose_tracker.dart';

void main() {
  group('buildRunningPoseAnatomyGeometry', () {
    test('builds running-specific head, torso, limb, joint, and foot geometry',
        () {
      final geometry = buildRunningPoseAnatomyGeometry(
        landmarks: _displayPose(),
        canvasSize: const Size(400, 800),
      );

      expect(geometry.headEllipse, isNotNull);
      expect(geometry.torsoPolygon, hasLength(4));
      expect(geometry.centerline, isNotNull);
      expect(geometry.segments, isNotEmpty);
      expect(geometry.joints.length, greaterThanOrEqualTo(12));
      expect(geometry.feet, hasLength(2));
      expect(geometry.bodyScale, greaterThan(150));
    });

    test('marks inferred and low-confidence segments as dashed', () {
      final geometry = buildRunningPoseAnatomyGeometry(
        landmarks: _displayPose(
          overrides: {
            RunningPoseLandmarkType.leftWrist: _landmark(
              const Offset(152, 315),
              confidence: 0.36,
              state: RunningVisualPoseLandmarkState.inferred,
            ),
          },
        ),
        canvasSize: const Size(400, 800),
      );

      final lowerArm = geometry.segments.singleWhere(
        (segment) =>
            segment.fromType == RunningPoseLandmarkType.leftElbow &&
            segment.toType == RunningPoseLandmarkType.leftWrist,
      );
      final wrist = geometry.joints.singleWhere(
        (joint) => joint.type == RunningPoseLandmarkType.leftWrist,
      );

      expect(lowerArm.dashed, isTrue);
      expect(lowerArm.opacity, greaterThan(0));
      expect(wrist.inferred, isTrue);
    });

    test('keeps nearer depth side more opaque than the far side', () {
      final geometry = buildRunningPoseAnatomyGeometry(
        landmarks: _displayPose(
          z: {
            RunningPoseLandmarkType.leftHip: -0.24,
            RunningPoseLandmarkType.leftKnee: -0.24,
            RunningPoseLandmarkType.rightHip: 0.22,
            RunningPoseLandmarkType.rightKnee: 0.22,
          },
        ),
        canvasSize: const Size(400, 800),
      );

      final leftThigh = geometry.segments.singleWhere(
        (segment) =>
            segment.fromType == RunningPoseLandmarkType.leftHip &&
            segment.toType == RunningPoseLandmarkType.leftKnee,
      );
      final rightThigh = geometry.segments.singleWhere(
        (segment) =>
            segment.fromType == RunningPoseLandmarkType.rightHip &&
            segment.toType == RunningPoseLandmarkType.rightKnee,
      );

      expect(leftThigh.opacity, greaterThan(rightThigh.opacity));
    });
  });
}

Map<RunningPoseLandmarkType, RunningVisualPoseLandmark> _displayPose({
  Map<RunningPoseLandmarkType, RunningVisualPoseLandmark> overrides = const {},
  Map<RunningPoseLandmarkType, RunningVisualPoseLandmarkState> states =
      const {},
  Map<RunningPoseLandmarkType, double> z = const {},
}) {
  return {
    for (final entry in _points.entries)
      entry.key: overrides[entry.key] ??
          _landmark(
            entry.value,
            z: z[entry.key] ?? _baseDepth(entry.key),
            state: states[entry.key] ?? RunningVisualPoseLandmarkState.observed,
          ),
  };
}

RunningVisualPoseLandmark _landmark(
  Offset position, {
  double confidence = 0.92,
  double z = 0,
  RunningVisualPoseLandmarkState state =
      RunningVisualPoseLandmarkState.observed,
}) {
  return RunningVisualPoseLandmark(
    position: position,
    confidence: confidence,
    rawConfidence: confidence,
    z: z,
    worldZ: z,
    visibility: confidence,
    presence: confidence,
    state: state,
  );
}

double _baseDepth(RunningPoseLandmarkType type) {
  return switch (type) {
    RunningPoseLandmarkType.leftShoulder ||
    RunningPoseLandmarkType.leftElbow ||
    RunningPoseLandmarkType.leftWrist ||
    RunningPoseLandmarkType.leftHip ||
    RunningPoseLandmarkType.leftKnee ||
    RunningPoseLandmarkType.leftAnkle ||
    RunningPoseLandmarkType.leftHeel ||
    RunningPoseLandmarkType.leftFootIndex =>
      -0.04,
    _ => 0.06,
  };
}

const Map<RunningPoseLandmarkType, Offset> _points = {
  RunningPoseLandmarkType.nose: Offset(200, 75),
  RunningPoseLandmarkType.leftEar: Offset(180, 86),
  RunningPoseLandmarkType.rightEar: Offset(220, 86),
  RunningPoseLandmarkType.leftShoulder: Offset(168, 150),
  RunningPoseLandmarkType.rightShoulder: Offset(232, 150),
  RunningPoseLandmarkType.leftElbow: Offset(145, 230),
  RunningPoseLandmarkType.rightElbow: Offset(260, 225),
  RunningPoseLandmarkType.leftWrist: Offset(158, 315),
  RunningPoseLandmarkType.rightWrist: Offset(282, 300),
  RunningPoseLandmarkType.leftHip: Offset(180, 345),
  RunningPoseLandmarkType.rightHip: Offset(224, 345),
  RunningPoseLandmarkType.leftKnee: Offset(145, 485),
  RunningPoseLandmarkType.rightKnee: Offset(255, 470),
  RunningPoseLandmarkType.leftAnkle: Offset(115, 625),
  RunningPoseLandmarkType.rightAnkle: Offset(300, 590),
  RunningPoseLandmarkType.leftHeel: Offset(92, 645),
  RunningPoseLandmarkType.rightHeel: Offset(275, 612),
  RunningPoseLandmarkType.leftFootIndex: Offset(155, 650),
  RunningPoseLandmarkType.rightFootIndex: Offset(340, 608),
};
