import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/mediapipe_pose_landmarker_service.dart';
import 'package:football_note/domain/entities/running_live_coaching_state.dart';
import 'package:football_note/realtime_analysis/running_coaching/running_visual_pose_tracker.dart';

void main() {
  group('RunningVisualPoseTracker', () {
    test('caps display velocity prediction at 80ms', () {
      final tracker = RunningVisualPoseTracker();
      final start = DateTime(2026, 7, 20, 9);

      tracker.ingestDetection(
        _detection(
          positions: {
            RunningPoseLandmarkType.leftWrist: const Offset(360, 380),
          },
        ),
        timestamp: start,
      );
      tracker.ingestDetection(
        _detection(
          positions: {
            RunningPoseLandmarkType.leftWrist: const Offset(420, 380),
          },
        ),
        timestamp: start.add(const Duration(milliseconds: 40)),
      );

      final capped = tracker.frameAt(
        start.add(const Duration(milliseconds: 60)),
      )!;
      final farFuture = tracker.frameAt(
        start.add(const Duration(milliseconds: 300)),
      )!;

      final cappedX =
          capped.landmarks[RunningPoseLandmarkType.leftWrist]!.position.dx;
      final farFutureX =
          farFuture.landmarks[RunningPoseLandmarkType.leftWrist]!.position.dx;
      expect(farFutureX, closeTo(cappedX, 0.001));
    });

    test('uses confidence hysteresis and fades missing landmarks', () {
      final tracker = RunningVisualPoseTracker();
      final start = DateTime(2026, 7, 20, 9);

      tracker.ingestDetection(
        _detection(
          confidences: {RunningPoseLandmarkType.leftWrist: 0.38},
        ),
        timestamp: start,
      );
      final held = tracker.ingestDetection(
        _detection(
          confidences: {RunningPoseLandmarkType.leftWrist: 0.22},
        ),
        timestamp: start.add(const Duration(milliseconds: 40)),
      )!;
      final inferred = tracker.ingestDetection(
        _detection(omitted: {RunningPoseLandmarkType.leftWrist}),
        timestamp: start.add(const Duration(milliseconds: 120)),
      )!;
      final occluded = tracker.frameAt(
        start.add(const Duration(milliseconds: 360)),
      )!;

      expect(
        held.landmarks[RunningPoseLandmarkType.leftWrist]!.state,
        RunningVisualPoseLandmarkState.observed,
      );
      expect(
        inferred.landmarks[RunningPoseLandmarkType.leftWrist]!.state,
        RunningVisualPoseLandmarkState.inferred,
      );
      expect(
        occluded.landmarks[RunningPoseLandmarkType.leftWrist]!.state,
        RunningVisualPoseLandmarkState.occluded,
      );
      expect(
        occluded.landmarks[RunningPoseLandmarkType.leftWrist]!.confidence,
        lessThan(
          inferred.landmarks[RunningPoseLandmarkType.leftWrist]!.confidence,
        ),
      );
    });

    test('uses each landmark missing time when reacquiring after a gap', () {
      final tracker = RunningVisualPoseTracker(
        config: const RunningVisualPoseTrackerConfig(
          smoothingTimeConstant: Duration(milliseconds: 120),
          displayPredictionLead: Duration.zero,
        ),
      );
      final start = DateTime(2026, 7, 20, 9);

      tracker.ingestDetection(_detection(), timestamp: start);
      tracker.ingestDetection(
        _detection(omitted: {RunningPoseLandmarkType.nose}),
        timestamp: start.add(const Duration(milliseconds: 120)),
      );
      final reacquired = tracker.ingestDetection(
        _detection(
          positions: {
            RunningPoseLandmarkType.nose: const Offset(520, 135),
          },
        ),
        timestamp: start.add(const Duration(milliseconds: 240)),
      )!;

      expect(
        reacquired.landmarks[RunningPoseLandmarkType.nose]!.position.dx,
        greaterThan(515),
      );
    });

    test('stabilizes conservative left-right swaps with depth and motion', () {
      final tracker = RunningVisualPoseTracker();
      final start = DateTime(2026, 7, 20, 9);

      tracker.ingestDetection(
        _detection(
          positions: {
            RunningPoseLandmarkType.leftAnkle: const Offset(450, 800),
            RunningPoseLandmarkType.rightAnkle: const Offset(550, 800),
          },
          z: {
            RunningPoseLandmarkType.leftAnkle: -0.20,
            RunningPoseLandmarkType.rightAnkle: 0.18,
          },
        ),
        timestamp: start,
      );
      final stabilized = tracker.ingestDetection(
        _detection(
          positions: {
            RunningPoseLandmarkType.leftAnkle: const Offset(548, 800),
            RunningPoseLandmarkType.rightAnkle: const Offset(452, 800),
          },
          z: {
            RunningPoseLandmarkType.leftAnkle: 0.18,
            RunningPoseLandmarkType.rightAnkle: -0.20,
          },
        ),
        timestamp: start.add(const Duration(milliseconds: 80)),
      )!;

      final left = stabilized.landmarks[RunningPoseLandmarkType.leftAnkle]!;
      final right = stabilized.landmarks[RunningPoseLandmarkType.rightAnkle]!;
      expect(left.position.dx, lessThan(right.position.dx));
      expect(left.z, lessThan(right.z));
    });

    test('limits implausible body segment lengths from rolling history', () {
      final tracker = RunningVisualPoseTracker();
      final start = DateTime(2026, 7, 20, 9);

      tracker.ingestDetection(_detection(), timestamp: start);
      final constrained = tracker.ingestDetection(
        _detection(
          positions: {
            RunningPoseLandmarkType.leftAnkle: const Offset(450, 1120),
          },
        ),
        timestamp: start.add(const Duration(milliseconds: 80)),
      )!;

      final knee =
          constrained.landmarks[RunningPoseLandmarkType.leftKnee]!.position;
      final ankle =
          constrained.landmarks[RunningPoseLandmarkType.leftAnkle]!.position;
      expect((ankle - knee).distance, lessThanOrEqualTo(242));
    });

    test('locks and releases stance foot from gait events', () {
      final tracker = RunningVisualPoseTracker();
      final start = DateTime(2026, 7, 20, 9);

      tracker.ingestDetection(_detection(), timestamp: start);
      tracker.ingestGaitEvents([
        RunningGaitEvent(
          side: RunningFootSide.left,
          type: RunningGaitEventType.touchdown,
          timestamp: start,
          confidence: 0.9,
        ),
      ]);
      final locked = tracker.ingestDetection(
        _detection(
          positions: {
            RunningPoseLandmarkType.leftAnkle: const Offset(520, 790),
            RunningPoseLandmarkType.leftHeel: const Offset(500, 815),
            RunningPoseLandmarkType.leftFootIndex: const Offset(570, 805),
          },
        ),
        timestamp: start.add(const Duration(milliseconds: 80)),
      )!;

      expect(
        locked.landmarks[RunningPoseLandmarkType.leftAnkle]!.position,
        const Offset(450, 800),
      );

      tracker.ingestGaitEvents([
        RunningGaitEvent(
          side: RunningFootSide.left,
          type: RunningGaitEventType.toeOff,
          timestamp: start.add(const Duration(milliseconds: 100)),
          confidence: 0.9,
        ),
      ]);
      final released = tracker.frameAt(
        start.add(const Duration(milliseconds: 120)),
      )!;
      expect(
        released.landmarks[RunningPoseLandmarkType.leftAnkle]!.position.dx,
        greaterThan(450),
      );
    });

    test('preserves MediaPipe z, world depth, confidence, and display state',
        () {
      final tracker = RunningVisualPoseTracker();
      final start = DateTime(2026, 7, 20, 9);

      final frame = tracker.ingestDetection(
        _detection(
          confidences: {RunningPoseLandmarkType.nose: 0.67},
          z: {RunningPoseLandmarkType.nose: -0.15},
          worldZ: {RunningPoseLandmarkType.nose: -0.75},
        ),
        timestamp: start,
      )!;

      final nose = frame.landmarks[RunningPoseLandmarkType.nose]!;
      expect(nose.z, closeTo(-0.15, 0.001));
      expect(nose.worldZ, closeTo(-0.75, 0.001));
      expect(nose.rawConfidence, closeTo(0.67, 0.001));
      expect(nose.state, RunningVisualPoseLandmarkState.observed);
    });

    test('reset clears lifecycle state and bounded visual memory', () {
      final tracker = RunningVisualPoseTracker();
      final start = DateTime(2026, 7, 20, 9);

      tracker.ingestDetection(_detection(), timestamp: start);
      tracker.reset();

      expect(
        tracker.frameAt(start.add(const Duration(milliseconds: 16))),
        isNull,
      );

      final restarted = tracker.ingestDetection(
        _detection(
          positions: {
            RunningPoseLandmarkType.leftAnkle: const Offset(700, 800),
          },
        ),
        timestamp: start.add(const Duration(milliseconds: 120)),
      )!;
      expect(
        restarted.landmarks[RunningPoseLandmarkType.leftAnkle]!.position.dx,
        greaterThan(695),
      );
    });
  });
}

MediaPipePoseDetection _detection({
  Map<RunningPoseLandmarkType, Offset> positions = const {},
  Map<RunningPoseLandmarkType, double> confidences = const {},
  Map<RunningPoseLandmarkType, double> z = const {},
  Map<RunningPoseLandmarkType, double> worldZ = const {},
  Set<RunningPoseLandmarkType> omitted = const {},
}) {
  return MediaPipePoseDetection(
    imageSize: const Size(1000, 1000),
    landmarks: [
      for (final entry in _basePose.entries)
        if (!omitted.contains(entry.key))
          MediaPipePoseLandmark(
            index: _mediaPipeIndexByType[entry.key]!,
            position: positions[entry.key] ?? entry.value,
            z: z[entry.key] ?? _baseDepth(entry.key),
            confidence: confidences[entry.key] ?? 0.92,
            visibility: confidences[entry.key] ?? 0.92,
            presence: confidences[entry.key] ?? 0.92,
            worldLandmark: MediaPipeWorldLandmark(
              x: (positions[entry.key] ?? entry.value).dx / 1000,
              y: (positions[entry.key] ?? entry.value).dy / 1000,
              z: worldZ[entry.key] ?? (z[entry.key] ?? _baseDepth(entry.key)),
              visibility: confidences[entry.key] ?? 0.92,
            ),
          ),
    ],
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
      -0.05,
    _ => 0.06,
  };
}

const Map<RunningPoseLandmarkType, Offset> _basePose = {
  RunningPoseLandmarkType.nose: Offset(500, 135),
  RunningPoseLandmarkType.leftEar: Offset(475, 145),
  RunningPoseLandmarkType.rightEar: Offset(525, 145),
  RunningPoseLandmarkType.leftShoulder: Offset(460, 235),
  RunningPoseLandmarkType.rightShoulder: Offset(540, 235),
  RunningPoseLandmarkType.leftElbow: Offset(420, 315),
  RunningPoseLandmarkType.rightElbow: Offset(585, 315),
  RunningPoseLandmarkType.leftWrist: Offset(382, 395),
  RunningPoseLandmarkType.rightWrist: Offset(610, 390),
  RunningPoseLandmarkType.leftHip: Offset(475, 445),
  RunningPoseLandmarkType.rightHip: Offset(525, 445),
  RunningPoseLandmarkType.leftKnee: Offset(455, 625),
  RunningPoseLandmarkType.rightKnee: Offset(545, 625),
  RunningPoseLandmarkType.leftAnkle: Offset(450, 800),
  RunningPoseLandmarkType.rightAnkle: Offset(550, 800),
  RunningPoseLandmarkType.leftHeel: Offset(425, 820),
  RunningPoseLandmarkType.rightHeel: Offset(525, 820),
  RunningPoseLandmarkType.leftFootIndex: Offset(495, 815),
  RunningPoseLandmarkType.rightFootIndex: Offset(595, 815),
};

const Map<RunningPoseLandmarkType, int> _mediaPipeIndexByType = {
  RunningPoseLandmarkType.nose: 0,
  RunningPoseLandmarkType.leftEar: 7,
  RunningPoseLandmarkType.rightEar: 8,
  RunningPoseLandmarkType.leftShoulder: 11,
  RunningPoseLandmarkType.rightShoulder: 12,
  RunningPoseLandmarkType.leftElbow: 13,
  RunningPoseLandmarkType.rightElbow: 14,
  RunningPoseLandmarkType.leftWrist: 15,
  RunningPoseLandmarkType.rightWrist: 16,
  RunningPoseLandmarkType.leftHip: 23,
  RunningPoseLandmarkType.rightHip: 24,
  RunningPoseLandmarkType.leftKnee: 25,
  RunningPoseLandmarkType.rightKnee: 26,
  RunningPoseLandmarkType.leftAnkle: 27,
  RunningPoseLandmarkType.rightAnkle: 28,
  RunningPoseLandmarkType.leftHeel: 29,
  RunningPoseLandmarkType.rightHeel: 30,
  RunningPoseLandmarkType.leftFootIndex: 31,
  RunningPoseLandmarkType.rightFootIndex: 32,
};
