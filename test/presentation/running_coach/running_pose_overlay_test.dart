import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';
import 'package:football_note/presentation/running_coach/running_pose_overlay.dart';

void main() {
  test('interpolates adjacent pose frames by video timestamp', () {
    final frames = [
      _poseFrame(timestampMs: 0, x: 0.20, confidence: 0.9),
      _poseFrame(timestampMs: 1000, x: 0.40, confidence: 0.9),
    ];

    final sampled = runningPoseFrameAtPosition(
      frames: frames,
      position: const Duration(milliseconds: 500),
    );

    expect(sampled, isNotNull);
    expect(sampled!.timestampMs, 500);
    expect(sampled.landmarkByIndex(0)!.x, closeTo(0.30, 0.0001));
    expect(
      runningPoseFrameAtPosition(
        frames: frames,
        position: const Duration(milliseconds: 1600),
      ),
      isNull,
    );
  });

  test('smoothing weights nearby higher-confidence landmarks more strongly',
      () {
    final frames = [
      _poseFrame(timestampMs: 0, x: 0.0, confidence: 0.1),
      _poseFrame(timestampMs: 1000, x: 1.0, confidence: 1.0),
    ];

    final sampled = runningPoseFrameAtPosition(
      frames: frames,
      position: const Duration(milliseconds: 500),
    );

    expect(sampled, isNotNull);
    expect(sampled!.landmarkByIndex(0)!.x, greaterThan(0.5));
    expect(sampled.landmarkByIndex(0)!.confidence, greaterThan(0.55));
  });

  test('maps normalized landmarks through BoxFit.cover crop', () {
    final point = runningPoseCoverOffset(
      landmark: const RunningVideoPoseLandmark(
        index: 0,
        x: 0.5,
        y: 0.0,
        z: 0,
        visibility: 1,
        presence: 1,
        confidence: 1,
      ),
      imageWidth: 100,
      imageHeight: 200,
      outputSize: const Size(300, 300),
    );

    expect(point.dx, closeTo(150, 0.0001));
    expect(point.dy, closeTo(-150, 0.0001));
  });

  test('maps normalized landmarks through BoxFit.contain without cropping', () {
    final point = runningPoseContainOffset(
      landmark: const RunningVideoPoseLandmark(
        index: 0,
        x: 0.5,
        y: 0.0,
        z: 0,
        visibility: 1,
        presence: 1,
        confidence: 1,
      ),
      imageWidth: 100,
      imageHeight: 200,
      outputSize: const Size(300, 300),
    );

    expect(point.dx, closeTo(150, 0.0001));
    expect(point.dy, closeTo(0, 0.0001));
  });
}

RunningPoseFrame _poseFrame({
  required int timestampMs,
  required double x,
  required double confidence,
}) {
  return RunningPoseFrame(
    timestamp: Duration(milliseconds: timestampMs),
    imageWidth: 640,
    imageHeight: 360,
    landmarks: List<RunningVideoPoseLandmark>.unmodifiable([
      for (var index = 0; index < mediaPipePoseLandmarkCount; index += 1)
        RunningVideoPoseLandmark(
          index: index,
          x: x,
          y: 0.25 + (index * 0.01),
          z: 0,
          visibility: confidence,
          presence: confidence,
          confidence: confidence,
        ),
    ]),
  );
}
