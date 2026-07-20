import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/entities/running_live_coaching_state.dart';
import 'package:football_note/realtime_analysis/running_coaching/running_temporal_pose_tracker.dart';

void main() {
  group('RunningTemporalPoseTracker', () {
    test('reduces landmark jitter with timestamp-aware smoothing', () {
      final tracker = RunningTemporalPoseTracker();
      final start = DateTime(2026, 7, 20, 9);

      final first = tracker.track(
        _observation(leftAnkle: const Offset(470, 800)),
        timestamp: start,
      )!;
      final second = tracker.track(
        _observation(leftAnkle: const Offset(482, 800)),
        timestamp: start.add(const Duration(milliseconds: 120)),
      )!;

      final firstX =
          first.landmarks[RunningPoseLandmarkType.leftAnkle]!.position.dx;
      final secondX =
          second.landmarks[RunningPoseLandmarkType.leftAnkle]!.position.dx;

      expect(secondX, greaterThan(firstX));
      expect(secondX, lessThan(482));
      expect(secondX - firstX, lessThan(12));
    });

    test('bridges only short landmark gaps with decaying confidence', () {
      final tracker = RunningTemporalPoseTracker();
      final start = DateTime(2026, 7, 20, 9);

      final first = tracker.track(
        _observation(leftAnkle: const Offset(470, 800)),
        timestamp: start,
      )!;
      final bridged = tracker.track(
        _observation(includeLeftAnkle: false),
        timestamp: start.add(const Duration(milliseconds: 120)),
      )!;
      final expired = tracker.track(
        _observation(includeLeftAnkle: false),
        timestamp: start.add(const Duration(milliseconds: 260)),
      )!;

      final firstConfidence =
          first.landmarks[RunningPoseLandmarkType.leftAnkle]!.likelihood;
      final bridgedLandmark =
          bridged.landmarks[RunningPoseLandmarkType.leftAnkle];

      expect(bridgedLandmark, isNotNull);
      expect(bridgedLandmark!.position, const Offset(470, 800));
      expect(bridgedLandmark.likelihood, lessThan(firstConfidence));
      expect(bridgedLandmark.likelihood, greaterThan(0.45));
      expect(expired.landmarks[RunningPoseLandmarkType.leftAnkle], isNull);
    });

    test('rejects implausible one-frame jumps relative to body scale', () {
      final tracker = RunningTemporalPoseTracker();
      final start = DateTime(2026, 7, 20, 9);

      tracker.track(
        _observation(leftAnkle: const Offset(470, 800)),
        timestamp: start,
      );
      final outlier = tracker.track(
        _observation(leftAnkle: const Offset(850, 800)),
        timestamp: start.add(const Duration(milliseconds: 120)),
      )!;

      final leftAnkle = outlier.landmarks[RunningPoseLandmarkType.leftAnkle]!;
      expect(leftAnkle.position.dx, closeTo(470, 0.001));
      expect(leftAnkle.likelihood, greaterThan(0.45));
    });

    test('reset clears temporal state across camera sessions', () {
      final tracker = RunningTemporalPoseTracker();
      final start = DateTime(2026, 7, 20, 9);

      tracker.track(
        _observation(leftAnkle: const Offset(470, 800)),
        timestamp: start,
      );
      tracker.reset();
      final restarted = tracker.track(
        _observation(leftAnkle: const Offset(850, 800)),
        timestamp: start.add(const Duration(milliseconds: 120)),
      )!;

      expect(
        restarted.landmarks[RunningPoseLandmarkType.leftAnkle]!.position.dx,
        850,
      );
    });
  });
}

RunningPoseObservation _observation({
  Offset leftAnkle = const Offset(470, 800),
  bool includeLeftAnkle = true,
}) {
  final landmarks = <RunningPoseLandmarkType, RunningPoseLandmark>{
    RunningPoseLandmarkType.leftShoulder: _landmark(const Offset(480, 250)),
    RunningPoseLandmarkType.rightShoulder: _landmark(const Offset(520, 250)),
    RunningPoseLandmarkType.leftHip: _landmark(const Offset(485, 500)),
    RunningPoseLandmarkType.rightHip: _landmark(const Offset(515, 500)),
    RunningPoseLandmarkType.rightAnkle: _landmark(const Offset(530, 800)),
  };
  if (includeLeftAnkle) {
    landmarks[RunningPoseLandmarkType.leftAnkle] = _landmark(leftAnkle);
  }
  return RunningPoseObservation(
    imageSize: const Size(1000, 1000),
    landmarks: landmarks,
  );
}

RunningPoseLandmark _landmark(Offset position) {
  return RunningPoseLandmark(position: position, likelihood: 0.98);
}
