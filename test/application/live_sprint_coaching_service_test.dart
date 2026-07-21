import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/live_sprint_coaching_service.dart';
import 'package:football_note/application/mediapipe_pose_landmarker_service.dart';
import 'package:football_note/domain/entities/sprint_pose_frame.dart';

void main() {
  group('LiveSprintCoachingService', () {
    test('fans one MediaPipe detection out to both live evaluators', () {
      final service = LiveSprintCoachingService();
      final timestamp = DateTime(2026, 7, 21, 10);

      final snapshot = service.ingestDetection(
        _fullBodyDetection(),
        timestamp: timestamp,
      );

      expect(snapshot.runningState.trackedObservation, isNotNull);
      expect(snapshot.sprintState.processedFrames, 1);
      expect(snapshot.sprintPoseFrame, isNotNull);
      expect(snapshot.sprintAnalysisUpdated, isTrue);
      expect(
        snapshot.sprintPoseFrame!.landmark(SprintPoseLandmarkType.leftHip),
        isNotNull,
      );
      expect(
        snapshot.sprintPoseFrame!
            .landmark(SprintPoseLandmarkType.leftHip)!
            .worldLandmark,
        isNotNull,
      );
    });

    test('resets both evaluators together for a new live session', () {
      final service = LiveSprintCoachingService();
      final timestamp = DateTime(2026, 7, 21, 10);

      service.ingestDetection(_fullBodyDetection(), timestamp: timestamp);
      service.reset();
      final resetSnapshot = service.ingestDetection(
        _fullBodyDetection(),
        timestamp: timestamp.add(const Duration(seconds: 1)),
      );

      expect(resetSnapshot.sprintState.processedFrames, 1);
      expect(resetSnapshot.runningState.trackedFrames, lessThanOrEqualTo(1));
    });

    test('keeps sprint feature timing at its configured analysis interval', () {
      final service = LiveSprintCoachingService();
      final timestamp = DateTime(2026, 7, 21, 10);

      service.ingestDetection(_fullBodyDetection(), timestamp: timestamp);
      final deferred = service.ingestDetection(
        _fullBodyDetection(),
        timestamp: timestamp.add(const Duration(milliseconds: 50)),
      );
      final nextSprintSample = service.ingestDetection(
        _fullBodyDetection(),
        timestamp: timestamp.add(const Duration(milliseconds: 100)),
      );

      expect(deferred.sprintAnalysisUpdated, isFalse);
      expect(deferred.sprintState.processedFrames, 1);
      expect(nextSprintSample.sprintAnalysisUpdated, isTrue);
      expect(nextSprintSample.sprintState.processedFrames, 2);
    });
  });

  test('sprint pose conversion ignores a detection without mapped joints', () {
    final frame = sprintPoseFrameFromMediaPipeDetection(
      const MediaPipePoseDetection(
        imageSize: Size(1000, 1000),
        landmarks: <MediaPipePoseLandmark>[
          MediaPipePoseLandmark(
            index: 1,
            position: Offset(500, 500),
            z: 0,
            confidence: 0.98,
            visibility: 0.98,
            presence: 0.98,
            worldLandmark: null,
          ),
        ],
      ),
      timestamp: DateTime(2026, 7, 21, 10),
    );

    expect(frame, isNull);
  });
}

MediaPipePoseDetection _fullBodyDetection() {
  const positions = <int, Offset>{
    0: Offset(500, 120),
    7: Offset(470, 145),
    8: Offset(530, 145),
    11: Offset(440, 240),
    12: Offset(560, 245),
    13: Offset(410, 330),
    14: Offset(590, 350),
    15: Offset(390, 415),
    16: Offset(610, 430),
    23: Offset(460, 460),
    24: Offset(540, 465),
    25: Offset(430, 640),
    26: Offset(570, 610),
    27: Offset(405, 830),
    28: Offset(600, 790),
    29: Offset(395, 842),
    30: Offset(592, 802),
    31: Offset(385, 845),
    32: Offset(616, 805),
  };
  return MediaPipePoseDetection(
    imageSize: const Size(1000, 1000),
    landmarks: [
      for (final entry in positions.entries)
        MediaPipePoseLandmark(
          index: entry.key,
          position: entry.value,
          z: 0,
          confidence: 0.98,
          visibility: 0.98,
          presence: 0.98,
          worldLandmark: entry.key == 23
              ? const MediaPipeWorldLandmark(
                  x: 0.02,
                  y: -0.08,
                  z: 0.03,
                  visibility: 0.98,
                )
              : null,
        ),
    ],
  );
}
