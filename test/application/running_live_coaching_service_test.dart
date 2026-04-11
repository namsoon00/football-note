import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/running_live_coaching_service.dart';
import 'package:football_note/domain/entities/running_live_coaching_state.dart';

void main() {
  group('RunningLiveCoachingService', () {
    test('flags missing runner when core landmarks are absent', () {
      final service = RunningLiveCoachingService();

      final state = service.ingestObservation(
        RunningPoseObservation(
          imageSize: const Size(1000, 1000),
          landmarks: {
            RunningPoseLandmarkType.leftHip: _landmark(480, 520),
            RunningPoseLandmarkType.rightHip: _landmark(520, 520),
          },
        ),
        timestamp: DateTime(2026, 4, 11, 12),
      );

      expect(state.framingIssue, RunningLiveFramingIssue.noRunnerDetected);
      expect(state.primaryCue, RunningLivePrimaryCue.noRunnerDetected);
    });

    test('asks runner to step back when lower body is clipped', () {
      final service = RunningLiveCoachingService();

      final state = service.ingestObservation(
        _observation(
          leftShoulder: const Offset(470, 260),
          rightShoulder: const Offset(530, 265),
          leftHip: const Offset(480, 470),
          rightHip: const Offset(520, 470),
        ),
        timestamp: DateTime(2026, 4, 11, 12),
      );

      expect(state.framingIssue, RunningLiveFramingIssue.stepBack);
      expect(state.primaryCue, RunningLivePrimaryCue.stepBack);
    });

    test('asks runner to move closer when the body is too small', () {
      final service = RunningLiveCoachingService();

      final state = service.ingestObservation(
        _observation(
          nose: const Offset(500, 340),
          leftShoulder: const Offset(485, 390),
          rightShoulder: const Offset(515, 390),
          leftHip: const Offset(490, 470),
          rightHip: const Offset(510, 470),
          leftKnee: const Offset(492, 540),
          rightKnee: const Offset(508, 540),
          leftAnkle: const Offset(494, 615),
          rightAnkle: const Offset(506, 615),
        ),
        timestamp: DateTime(2026, 4, 11, 12),
      );

      expect(state.framingIssue, RunningLiveFramingIssue.moveCloser);
      expect(state.primaryCue, RunningLivePrimaryCue.moveCloser);
    });

    test('builds stable live analysis after enough good frames', () {
      final service = RunningLiveCoachingService();
      late RunningLiveCoachingState lastState;
      final start = DateTime(2026, 4, 11, 12);

      for (var index = 0; index < 7; index++) {
        final xOffset = 360.0 + (index * 24);
        lastState = service.ingestObservation(
          _observation(
            nose: Offset(xOffset + 130, 180),
            leftShoulder: Offset(xOffset + 105, 250),
            rightShoulder: Offset(xOffset + 145, 252),
            leftElbow: Offset(xOffset + 85, 320),
            rightElbow: Offset(xOffset + 180, 330),
            leftWrist: Offset(xOffset + 65, 395),
            rightWrist: Offset(xOffset + 198, 410),
            leftHip: Offset(xOffset + 115, 430),
            rightHip: Offset(xOffset + 145, 432),
            leftKnee: Offset(xOffset + 100, 585),
            rightKnee: Offset(xOffset + 160, 555),
            leftAnkle: Offset(xOffset + 85, 760),
            rightAnkle: Offset(xOffset + 190, 710),
            leftHeel: Offset(xOffset + 80, 772),
            rightHeel: Offset(xOffset + 180, 722),
          ),
          timestamp: start.add(Duration(milliseconds: 320 * index)),
        );
      }

      expect(lastState.framingIssue, isNull);
      expect(lastState.hasStableAnalysis, isTrue);
      expect(lastState.analysisResult, isNotNull);
      expect(lastState.coachingReport, isNotNull);
      expect(lastState.trackedFrames, 7);
    });

    test('surfaces overstride cue when lead foot reaches too far forward', () {
      final service = RunningLiveCoachingService();
      late RunningLiveCoachingState lastState;
      final start = DateTime(2026, 4, 11, 12);

      for (var index = 0; index < 7; index++) {
        final xOffset = 340.0 + (index * 26);
        lastState = service.ingestObservation(
          _observation(
            nose: Offset(xOffset + 150, 182),
            leftShoulder: Offset(xOffset + 138, 252),
            rightShoulder: Offset(xOffset + 170, 252),
            leftElbow: Offset(xOffset + 138, 320),
            rightElbow: Offset(xOffset + 170, 320),
            leftWrist: Offset(xOffset + 88, 320),
            rightWrist: Offset(xOffset + 225, 320),
            leftHip: Offset(xOffset + 120, 432),
            rightHip: Offset(xOffset + 148, 432),
            leftKnee: Offset(xOffset + 98, 600),
            rightKnee: Offset(xOffset + 184, 552),
            leftAnkle: Offset(xOffset + 86, 758),
            rightAnkle: Offset(xOffset + 240, 708),
            leftHeel: Offset(xOffset + 80, 772),
            rightHeel: Offset(xOffset + 228, 722),
          ),
          timestamp: start.add(Duration(milliseconds: 320 * index)),
        );
      }

      expect(lastState.hasStableAnalysis, isTrue);
      expect(
        lastState.primaryCue,
        RunningLivePrimaryCue.footStrikeOverstride,
      );
    });
  });
}

RunningPoseObservation _observation({
  Offset? nose,
  Offset? leftShoulder,
  Offset? rightShoulder,
  Offset? leftElbow,
  Offset? rightElbow,
  Offset? leftWrist,
  Offset? rightWrist,
  Offset? leftHip,
  Offset? rightHip,
  Offset? leftKnee,
  Offset? rightKnee,
  Offset? leftAnkle,
  Offset? rightAnkle,
  Offset? leftHeel,
  Offset? rightHeel,
}) {
  final landmarks = <RunningPoseLandmarkType, RunningPoseLandmark>{};

  void put(RunningPoseLandmarkType type, Offset? position) {
    if (position == null) {
      return;
    }
    landmarks[type] = _landmark(position.dx, position.dy);
  }

  put(RunningPoseLandmarkType.nose, nose);
  put(RunningPoseLandmarkType.leftShoulder, leftShoulder);
  put(RunningPoseLandmarkType.rightShoulder, rightShoulder);
  put(RunningPoseLandmarkType.leftElbow, leftElbow);
  put(RunningPoseLandmarkType.rightElbow, rightElbow);
  put(RunningPoseLandmarkType.leftWrist, leftWrist);
  put(RunningPoseLandmarkType.rightWrist, rightWrist);
  put(RunningPoseLandmarkType.leftHip, leftHip);
  put(RunningPoseLandmarkType.rightHip, rightHip);
  put(RunningPoseLandmarkType.leftKnee, leftKnee);
  put(RunningPoseLandmarkType.rightKnee, rightKnee);
  put(RunningPoseLandmarkType.leftAnkle, leftAnkle);
  put(RunningPoseLandmarkType.rightAnkle, rightAnkle);
  put(RunningPoseLandmarkType.leftHeel, leftHeel);
  put(RunningPoseLandmarkType.rightHeel, rightHeel);

  return RunningPoseObservation(
    imageSize: const Size(1000, 1000),
    landmarks: landmarks,
  );
}

RunningPoseLandmark _landmark(double x, double y) {
  return RunningPoseLandmark(
    position: Offset(x, y),
    likelihood: 0.98,
  );
}
