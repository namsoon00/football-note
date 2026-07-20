import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';

void main() {
  test('fromMap keeps legacy payload compatibility without poseFrames', () {
    final result = RunningVideoAnalysisResult.fromMap({
      'durationMs': 4200,
      'sampledFrames': 14,
      'validFrames': 12,
      'direction': 'leftToRight',
      'forwardLeanDegrees': 11.4,
      'verticalBounceRatio': 0.071,
      'footStrikeDistanceRatio': 0.12,
      'stanceKneeAngleDegrees': 151,
      'elbowAngleDegrees': 94,
    });

    expect(result.videoDuration, const Duration(milliseconds: 4200));
    expect(result.direction, RunningDirection.leftToRight);
    expect(result.poseFrames, isEmpty);
  });

  test('fromMap parses complete MediaPipe poseFrames robustly', () {
    final result = RunningVideoAnalysisResult.fromMap({
      'durationMs': 4000,
      'sampledFrames': 14,
      'validFrames': 12,
      'direction': 'rightToLeft',
      'forwardLeanDegrees': 'bad',
      'verticalBounceRatio': 0.07,
      'footStrikeDistanceRatio': 0.11,
      'stanceKneeAngleDegrees': 152,
      'elbowAngleDegrees': 96,
      'poseFrames': [
        _poseFrameMap(timestampMs: 800, imageWidth: 640, imageHeight: 360),
        {
          'timestampMs': 900,
          'imageWidth': 640,
          'imageHeight': 360,
          'landmarks': [_landmarkMap(0)],
        },
        _poseFrameMap(timestampMs: 500, imageWidth: 640, imageHeight: 360),
      ],
    });

    expect(result.forwardLeanDegrees, 0);
    expect(result.direction, RunningDirection.rightToLeft);
    expect(result.poseFrames, hasLength(2));
    expect(result.poseFrames.map((frame) => frame.timestampMs), [500, 800]);
    final frame = result.poseFrames.last;
    expect(frame.imageWidth, 640);
    expect(frame.imageHeight, 360);
    expect(frame.landmarks, hasLength(mediaPipePoseLandmarkCount));
    expect(frame.landmarkByIndex(11)!.x, closeTo(0.21, 0.0001));
    expect(frame.landmarkByIndex(11)!.visibility, closeTo(0.71, 0.0001));
    expect(frame.landmarkByIndex(11)!.presence, closeTo(0.61, 0.0001));
    expect(frame.landmarkByIndex(32)!.confidence, 1);
  });
}

Map<String, Object?> _poseFrameMap({
  required int timestampMs,
  required int imageWidth,
  required int imageHeight,
}) {
  return {
    'timestampMs': timestampMs,
    'imageWidth': imageWidth,
    'imageHeight': imageHeight,
    'landmarks': [
      for (var index = 0; index < mediaPipePoseLandmarkCount; index += 1)
        _landmarkMap(index),
    ],
  };
}

Map<String, Object?> _landmarkMap(int index) {
  return {
    'index': index,
    'x': 0.10 + (index * 0.01),
    'y': 0.20 + (index * 0.01),
    'z': -0.01 * index,
    'visibility': 0.60 + (index * 0.01),
    'presence': 0.50 + (index * 0.01),
    'confidence': 0.40 + (index * 0.03),
  };
}
