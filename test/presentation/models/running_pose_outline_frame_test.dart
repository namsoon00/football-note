import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/entities/running_live_coaching_state.dart';
import 'package:football_note/presentation/models/running_pose_outline_frame.dart';

void main() {
  test('builds an upright runner outline frame for a standing pose', () {
    final frame = buildRunningPoseOutlineFrame(
      visiblePoints: <RunningPoseLandmarkType, Offset>{
        RunningPoseLandmarkType.nose: const Offset(100, 56),
        RunningPoseLandmarkType.leftShoulder: const Offset(80, 96),
        RunningPoseLandmarkType.rightShoulder: const Offset(120, 96),
        RunningPoseLandmarkType.leftElbow: const Offset(72, 138),
        RunningPoseLandmarkType.rightElbow: const Offset(128, 140),
        RunningPoseLandmarkType.leftHip: const Offset(86, 160),
        RunningPoseLandmarkType.rightHip: const Offset(114, 160),
        RunningPoseLandmarkType.leftKnee: const Offset(88, 212),
        RunningPoseLandmarkType.rightKnee: const Offset(112, 214),
        RunningPoseLandmarkType.leftAnkle: const Offset(90, 286),
        RunningPoseLandmarkType.rightAnkle: const Offset(110, 286),
      },
      canvasSize: const Size(240, 360),
    );

    expect(frame, isNotNull);
    expect(frame!.rect.height, greaterThan(frame.rect.width));
    expect(frame.rect.center.dx, closeTo(100, 6));
    expect(frame.rect.top, lessThan(70));
    expect(frame.rect.bottom, greaterThan(286));
  });

  test(
    'keeps the runner outline frame vertical during a wide sprint stance',
    () {
      final frame = buildRunningPoseOutlineFrame(
        visiblePoints: <RunningPoseLandmarkType, Offset>{
          RunningPoseLandmarkType.leftShoulder: const Offset(150, 110),
          RunningPoseLandmarkType.rightShoulder: const Offset(192, 112),
          RunningPoseLandmarkType.leftWrist: const Offset(110, 176),
          RunningPoseLandmarkType.rightWrist: const Offset(238, 184),
          RunningPoseLandmarkType.leftHip: const Offset(158, 184),
          RunningPoseLandmarkType.rightHip: const Offset(188, 186),
          RunningPoseLandmarkType.leftKnee: const Offset(144, 246),
          RunningPoseLandmarkType.rightKnee: const Offset(208, 258),
          RunningPoseLandmarkType.leftAnkle: const Offset(138, 314),
          RunningPoseLandmarkType.rightAnkle: const Offset(224, 326),
        },
        canvasSize: const Size(320, 420),
      );

      expect(frame, isNotNull);
      expect(frame!.rect.height, greaterThan(frame.rect.width));
      expect(frame.rect.center.dx, closeTo(174, 10));
      expect(frame.rect.left, greaterThanOrEqualTo(0));
      expect(frame.rect.right, lessThanOrEqualTo(320));
    },
  );
}
