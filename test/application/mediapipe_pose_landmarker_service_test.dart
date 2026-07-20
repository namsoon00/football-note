import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/mediapipe_pose_landmarker_service.dart';
import 'package:football_note/domain/entities/running_live_coaching_state.dart';

void main() {
  group('runningPoseObservationFromMediaPipeDetection', () {
    test('parses MediaPipe z and world-depth fields from native maps', () {
      final detection = MediaPipePoseDetection.fromMap({
        'imageWidth': 360,
        'imageHeight': 640,
        'landmarks': [
          {
            'index': 0,
            'x': 10.0,
            'y': 20.0,
            'z': -0.12,
            'visibility': 0.67,
            'presence': 0.87,
            'worldX': 0.1,
            'worldY': 0.2,
            'worldZ': -0.72,
            'worldVisibility': 0.66,
          },
        ],
      });

      final landmark = detection.landmarks.single;
      expect(landmark.z, closeTo(-0.12, 0.001));
      expect(landmark.visibility, closeTo(0.67, 0.001));
      expect(landmark.presence, closeTo(0.87, 0.001));
      expect(landmark.worldLandmark, isNotNull);
      expect(landmark.worldLandmark!.z, closeTo(-0.72, 0.001));
      expect(landmark.worldLandmark!.visibility, closeTo(0.66, 0.001));
    });

    test('uses conservative visibility and presence confidence', () {
      final detection = MediaPipePoseDetection.fromMap({
        'imageWidth': 360,
        'imageHeight': 640,
        'landmarks': [
          {
            'index': 0,
            'x': 10.0,
            'y': 20.0,
            'visibility': 0.84,
            'presence': 0.31,
          },
          {
            'index': 11,
            'x': 12.0,
            'y': 22.0,
            'visibility': 0.63,
          },
          {
            'index': 12,
            'x': 14.0,
            'y': 24.0,
            'presence': 0.72,
          },
          {
            'index': 23,
            'x': 16.0,
            'y': 26.0,
          },
        ],
      });

      expect(detection.landmarks[0].confidence, closeTo(0.31, 0.001));
      expect(detection.landmarks[1].confidence, closeTo(0.63, 0.001));
      expect(detection.landmarks[2].confidence, closeTo(0.72, 0.001));
      expect(detection.landmarks[3].confidence, 0);
    });

    test('returns null for an ordinary frame with zero detected poses', () {
      final observation = runningPoseObservationFromMediaPipeDetection(
        const MediaPipePoseDetection(
          imageSize: Size(360, 640),
          landmarks: <MediaPipePoseLandmark>[],
        ),
      );

      expect(observation, isNull);
    });

    test('maps all supported running outline joints from MediaPipe indices',
        () {
      final landmarks = <MediaPipePoseLandmark>[
        _landmark(index: 99),
        _landmark(index: 0, x: 10, y: 20, confidence: 0.50),
        _landmark(index: 7, x: 17, y: 27, confidence: 0.57),
        _landmark(index: 8, x: 18, y: 28, confidence: 0.58),
        _landmark(index: 11, x: 21, y: 31, confidence: 0.61),
        _landmark(index: 12, x: 22, y: 32, confidence: 0.62),
        _landmark(index: 13, x: 23, y: 33, confidence: 0.63),
        _landmark(index: 14, x: 24, y: 34, confidence: 0.64),
        _landmark(index: 15, x: 25, y: 35, confidence: 0.65),
        _landmark(index: 16, x: 26, y: 36, confidence: 0.66),
        _landmark(index: 23, x: 33, y: 43, confidence: 0.73),
        _landmark(index: 24, x: 34, y: 44, confidence: 0.74),
        _landmark(index: 25, x: 35, y: 45, confidence: 0.75),
        _landmark(index: 26, x: 36, y: 46, confidence: 0.76),
        _landmark(index: 27, x: 37, y: 47, confidence: 0.77),
        _landmark(index: 28, x: 38, y: 48, confidence: 0.78),
        _landmark(index: 29, x: 39, y: 49, confidence: 0.79),
        _landmark(index: 30, x: 40, y: 50, confidence: 0.80),
        _landmark(index: 31, x: 41, y: 51, confidence: 0.81),
        _landmark(index: 32, x: 42, y: 52, confidence: 0.82),
      ];

      final observation = runningPoseObservationFromMediaPipeDetection(
        MediaPipePoseDetection(
          imageSize: const Size(360, 640),
          landmarks: landmarks,
        ),
      );

      expect(observation, isNotNull);
      expect(observation!.imageSize, const Size(360, 640));
      expect(
        observation.landmarks.keys.toSet(),
        RunningPoseLandmarkType.values.toSet(),
      );
      expect(
        observation.landmarks[RunningPoseLandmarkType.nose]!.position,
        const Offset(10, 20),
      );
      expect(
        observation.landmarks[RunningPoseLandmarkType.nose]!.likelihood,
        0.50,
      );
      expect(
        observation.landmarks[RunningPoseLandmarkType.rightFootIndex]!.position,
        const Offset(42, 52),
      );
      expect(
        observation
            .landmarks[RunningPoseLandmarkType.rightFootIndex]!.likelihood,
        0.82,
      );
    });
  });
}

MediaPipePoseLandmark _landmark({
  required int index,
  double x = 0,
  double y = 0,
  double confidence = 1,
}) {
  return MediaPipePoseLandmark(
    index: index,
    position: Offset(x, y),
    z: 0,
    confidence: confidence,
    visibility: confidence,
    presence: confidence,
    worldLandmark: null,
  );
}
