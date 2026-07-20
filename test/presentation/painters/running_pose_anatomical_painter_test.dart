import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/entities/running_live_coaching_state.dart';
import 'package:football_note/presentation/painters/running_pose_anatomical_painter.dart';
import 'package:football_note/realtime_analysis/running_coaching/running_visual_pose_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('paints a MediaPipe display frame with depth and inferred state',
      () async {
    final frame = RunningVisualPoseFrame(
      imageSize: const ui.Size(400, 800),
      landmarks: _displayPose(),
      timestamp: DateTime(2026, 7, 20, 9),
      observedAt: DateTime(2026, 7, 20, 9),
    );
    final notifier = ValueNotifier<RunningVisualPoseFrame?>(frame);
    final painter = RunningPoseAnatomicalPainter(
      frameListenable: notifier,
      mirrorHorizontally: false,
    );
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    painter.paint(canvas, const ui.Size(240, 420));
    final image = await recorder.endRecording().toImage(240, 420);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    expect(bytes, isNotNull);
    expect(bytes!.lengthInBytes, greaterThan(1000));
    notifier.dispose();
  });
}

Map<RunningPoseLandmarkType, RunningVisualPoseLandmark> _displayPose() {
  return {
    for (final entry in _points.entries)
      entry.key: RunningVisualPoseLandmark(
        position: entry.value,
        confidence:
            entry.key == RunningPoseLandmarkType.rightWrist ? 0.42 : 0.92,
        rawConfidence:
            entry.key == RunningPoseLandmarkType.rightWrist ? 0.42 : 0.92,
        z: entry.key.name.startsWith('left') ? -0.06 : 0.08,
        worldZ: entry.key.name.startsWith('left') ? -0.06 : 0.08,
        visibility:
            entry.key == RunningPoseLandmarkType.rightWrist ? 0.42 : 0.92,
        presence: entry.key == RunningPoseLandmarkType.rightWrist ? 0.42 : 0.92,
        state: entry.key == RunningPoseLandmarkType.rightWrist
            ? RunningVisualPoseLandmarkState.inferred
            : RunningVisualPoseLandmarkState.observed,
      ),
  };
}

const Map<RunningPoseLandmarkType, ui.Offset> _points = {
  RunningPoseLandmarkType.nose: ui.Offset(200, 75),
  RunningPoseLandmarkType.leftEar: ui.Offset(180, 86),
  RunningPoseLandmarkType.rightEar: ui.Offset(220, 86),
  RunningPoseLandmarkType.leftShoulder: ui.Offset(168, 150),
  RunningPoseLandmarkType.rightShoulder: ui.Offset(232, 150),
  RunningPoseLandmarkType.leftElbow: ui.Offset(145, 230),
  RunningPoseLandmarkType.rightElbow: ui.Offset(260, 225),
  RunningPoseLandmarkType.leftWrist: ui.Offset(158, 315),
  RunningPoseLandmarkType.rightWrist: ui.Offset(282, 300),
  RunningPoseLandmarkType.leftHip: ui.Offset(180, 345),
  RunningPoseLandmarkType.rightHip: ui.Offset(224, 345),
  RunningPoseLandmarkType.leftKnee: ui.Offset(145, 485),
  RunningPoseLandmarkType.rightKnee: ui.Offset(255, 470),
  RunningPoseLandmarkType.leftAnkle: ui.Offset(115, 625),
  RunningPoseLandmarkType.rightAnkle: ui.Offset(300, 590),
  RunningPoseLandmarkType.leftHeel: ui.Offset(92, 645),
  RunningPoseLandmarkType.rightHeel: ui.Offset(275, 612),
  RunningPoseLandmarkType.leftFootIndex: ui.Offset(155, 650),
  RunningPoseLandmarkType.rightFootIndex: ui.Offset(340, 608),
};
