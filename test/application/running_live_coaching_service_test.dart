import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/running_live_coaching_service.dart';
import 'package:football_note/domain/entities/running_live_coaching_state.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';

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

    test('waits for sustained lower-body crop before step back', () {
      final service = RunningLiveCoachingService();
      final start = DateTime(2026, 4, 11, 12);

      final first = service.ingestObservation(
        _cropSupportedMissingAnklesObservation(),
        timestamp: start,
      );
      service.ingestObservation(
        _cropSupportedMissingAnklesObservation(),
        timestamp: start.add(const Duration(milliseconds: 160)),
      );
      final sustained = service.ingestObservation(
        _cropSupportedMissingAnklesObservation(),
        timestamp: start.add(const Duration(milliseconds: 320)),
      );

      expect(first.framingIssue, RunningLiveFramingIssue.trackingUncertain);
      expect(first.primaryCue, RunningLivePrimaryCue.trackingUncertain);
      expect(sustained.framingIssue, RunningLiveFramingIssue.stepBack);
      expect(sustained.primaryCue, RunningLivePrimaryCue.stepBack);
    });

    test('treats brief ankle dropout as tracking uncertainty after stable body',
        () {
      final service = RunningLiveCoachingService();
      final start = DateTime(2026, 4, 11, 12);

      for (var index = 0; index < 4; index++) {
        service.ingestObservation(
          _observation(
            nose: const Offset(500, 160),
            leftShoulder: const Offset(470, 245),
            rightShoulder: const Offset(530, 245),
            leftElbow: const Offset(448, 330),
            rightElbow: const Offset(552, 330),
            leftWrist: const Offset(430, 420),
            rightWrist: const Offset(570, 420),
            leftHip: const Offset(480, 455),
            rightHip: const Offset(520, 455),
            leftKnee: const Offset(466, 625),
            rightKnee: const Offset(535, 610),
            leftAnkle: const Offset(450, 790),
            rightAnkle: const Offset(552, 775),
            leftHeel: const Offset(438, 805),
            rightHeel: const Offset(540, 790),
          ),
          timestamp: start.add(Duration(milliseconds: 160 * index)),
        );
      }

      final dropout = service.ingestObservation(
        _observation(
          nose: const Offset(500, 160),
          leftShoulder: const Offset(470, 245),
          rightShoulder: const Offset(530, 245),
          leftElbow: const Offset(448, 330),
          rightElbow: const Offset(552, 330),
          leftWrist: const Offset(430, 420),
          rightWrist: const Offset(570, 420),
          leftHip: const Offset(480, 455),
          rightHip: const Offset(520, 455),
          leftKnee: const Offset(466, 625),
          rightKnee: const Offset(535, 610),
        ),
        timestamp: start.add(const Duration(milliseconds: 720)),
      );

      expect(dropout.framingIssue, RunningLiveFramingIssue.trackingUncertain);
      expect(dropout.primaryCue, RunningLivePrimaryCue.trackingUncertain);
    });

    test('keeps sustained ankle dropout as tracking uncertainty', () {
      final service = RunningLiveCoachingService();
      final start = DateTime(2026, 4, 11, 12);

      for (var index = 0; index < 4; index++) {
        service.ingestObservation(
          _observation(
            nose: const Offset(500, 160),
            leftShoulder: const Offset(470, 245),
            rightShoulder: const Offset(530, 245),
            leftElbow: const Offset(448, 330),
            rightElbow: const Offset(552, 330),
            leftWrist: const Offset(430, 420),
            rightWrist: const Offset(570, 420),
            leftHip: const Offset(480, 455),
            rightHip: const Offset(520, 455),
            leftKnee: const Offset(466, 625),
            rightKnee: const Offset(535, 610),
            leftAnkle: const Offset(450, 790),
            rightAnkle: const Offset(552, 775),
            leftHeel: const Offset(438, 805),
            rightHeel: const Offset(540, 790),
          ),
          timestamp: start.add(Duration(milliseconds: 160 * index)),
        );
      }

      late RunningLiveCoachingState state;
      for (var index = 0; index < 4; index++) {
        state = service.ingestObservation(
          _observation(
            nose: const Offset(500, 160),
            leftShoulder: const Offset(470, 245),
            rightShoulder: const Offset(530, 245),
            leftElbow: const Offset(448, 330),
            rightElbow: const Offset(552, 330),
            leftWrist: const Offset(430, 420),
            rightWrist: const Offset(570, 420),
            leftHip: const Offset(480, 455),
            rightHip: const Offset(520, 455),
            leftKnee: const Offset(466, 625),
            rightKnee: const Offset(535, 610),
          ),
          timestamp: start.add(Duration(milliseconds: 720 + 160 * index)),
        );
      }

      expect(state.framingIssue, RunningLiveFramingIssue.trackingUncertain);
      expect(state.primaryCue, RunningLivePrimaryCue.trackingUncertain);
    });

    test('asks runner to step back when missing ankles are crop-supported', () {
      final service = RunningLiveCoachingService();
      final start = DateTime(2026, 4, 11, 12);

      late RunningLiveCoachingState state;
      for (var index = 0; index < 4; index++) {
        state = service.ingestObservation(
          _cropSupportedMissingAnklesObservation(),
          timestamp: start.add(Duration(milliseconds: 160 * index)),
        );
      }

      expect(state.framingIssue, RunningLiveFramingIssue.stepBack);
      expect(state.primaryCue, RunningLivePrimaryCue.stepBack);
    });

    test('does not ask a sufficiently detailed runner to move closer', () {
      final service = RunningLiveCoachingService();
      final start = DateTime(2026, 4, 11, 12);

      late RunningLiveCoachingState state;
      for (var index = 0; index < 5; index++) {
        state = service.ingestObservation(
          _moderatelySmallDetailedObservation(),
          timestamp: start.add(Duration(milliseconds: 160 * index)),
        );
      }

      expect(state.framingIssue, isNull);
      expect(state.primaryCue, isNot(RunningLivePrimaryCue.moveCloser));
    });

    test('asks runner to move closer only after sustained distant framing', () {
      final service = RunningLiveCoachingService();
      final start = DateTime(2026, 4, 11, 12);

      for (var index = 0; index < 3; index++) {
        final initial = service.ingestObservation(
          _distantDetailedObservation(),
          timestamp: start.add(Duration(milliseconds: 160 * index)),
        );
        expect(initial.framingIssue, isNull);
        expect(initial.primaryCue, isNot(RunningLivePrimaryCue.moveCloser));
      }

      final state = service.ingestObservation(
        _distantDetailedObservation(),
        timestamp: start.add(const Duration(milliseconds: 480)),
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

      for (var index = 0; index < 10; index++) {
        final xOffset = 300.0 + (index * 22);
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
          timestamp: start.add(Duration(milliseconds: 240 * index)),
        );
      }

      expect(lastState.hasStableAnalysis, isTrue);
      expect(
        lastState.primaryCue,
        RunningLivePrimaryCue.footStrikeOverstride,
      );
    });

    test('gates correction cues while required landmark confidence is low', () {
      final service = RunningLiveCoachingService();
      late RunningLiveCoachingState lastState;
      final start = DateTime(2026, 4, 11, 12);

      for (var index = 0; index < 10; index++) {
        final xOffset = 300.0 + (index * 22);
        lastState = service.ingestObservation(
          _observation(
            confidence: 0.50,
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
          timestamp: start.add(Duration(milliseconds: 240 * index)),
        );
      }

      expect(lastState.analysisResult, isNotNull);
      expect(lastState.highlightedInsight, isNotNull);
      expect(
        lastState.highlightedInsight!.finding,
        RunningCoachFinding.footStrikeOverstride,
      );
      expect(lastState.highlightedInsight!.quality.isLowConfidence, isTrue);
      expect(lastState.highlightedInsight!.quality.reason, 'low_confidence');
      expect(lastState.primaryCue, RunningLivePrimaryCue.keepRunning);
      expect(lastState.hasStableAnalysis, isFalse);
    });

    test('waits briefly before switching between correction cues', () {
      final service = RunningLiveCoachingService(
        cueDwellTime: const Duration(milliseconds: 600),
      );
      late RunningLiveCoachingState lastState;
      final start = DateTime(2026, 4, 11, 12);

      for (var index = 0; index < 10; index++) {
        final xOffset = 300.0 + (index * 22);
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
          timestamp: start.add(Duration(milliseconds: 240 * index)),
        );
      }

      expect(
        lastState.primaryCue,
        RunningLivePrimaryCue.footStrikeOverstride,
      );

      final quickSwitch = service.ingestObservation(
        _observation(
          nose: const Offset(500, 182),
          leftShoulder: const Offset(500, 252),
          rightShoulder: const Offset(532, 252),
          leftElbow: const Offset(500, 320),
          rightElbow: const Offset(532, 320),
          leftWrist: const Offset(454, 320),
          rightWrist: const Offset(587, 320),
          leftHip: const Offset(120, 432),
          rightHip: const Offset(148, 432),
          leftKnee: const Offset(98, 600),
          rightKnee: const Offset(184, 552),
          leftAnkle: const Offset(86, 758),
          rightAnkle: const Offset(240, 708),
          leftHeel: const Offset(80, 772),
          rightHeel: const Offset(228, 722),
        ),
        timestamp: start.add(const Duration(milliseconds: 2450)),
      );

      expect(
        quickSwitch.primaryCue,
        RunningLivePrimaryCue.footStrikeOverstride,
      );

      final settledSwitch = service.ingestObservation(
        _observation(
          nose: const Offset(500, 182),
          leftShoulder: const Offset(500, 252),
          rightShoulder: const Offset(532, 252),
          leftElbow: const Offset(500, 320),
          rightElbow: const Offset(532, 320),
          leftWrist: const Offset(454, 320),
          rightWrist: const Offset(587, 320),
          leftHip: const Offset(120, 432),
          rightHip: const Offset(148, 432),
          leftKnee: const Offset(98, 600),
          rightKnee: const Offset(184, 552),
          leftAnkle: const Offset(86, 758),
          rightAnkle: const Offset(240, 708),
          leftHeel: const Offset(80, 772),
          rightHeel: const Offset(228, 722),
        ),
        timestamp: start.add(const Duration(milliseconds: 3100)),
      );

      expect(settledSwitch.primaryCue, RunningLivePrimaryCue.postureTooUpright);
    });
  });
}

RunningPoseObservation _cropSupportedMissingAnklesObservation() {
  return _observation(
    nose: const Offset(500, 120),
    leftShoulder: const Offset(470, 205),
    rightShoulder: const Offset(530, 205),
    leftElbow: const Offset(448, 315),
    rightElbow: const Offset(552, 315),
    leftWrist: const Offset(430, 430),
    rightWrist: const Offset(570, 430),
    leftHip: const Offset(480, 610),
    rightHip: const Offset(520, 610),
    leftKnee: const Offset(466, 880),
    rightKnee: const Offset(535, 895),
  );
}

RunningPoseObservation _moderatelySmallDetailedObservation() {
  return _observation(
    nose: const Offset(500, 350),
    leftShoulder: const Offset(485, 395),
    rightShoulder: const Offset(515, 395),
    leftElbow: const Offset(470, 438),
    rightElbow: const Offset(530, 438),
    leftWrist: const Offset(462, 472),
    rightWrist: const Offset(538, 472),
    leftHip: const Offset(490, 475),
    rightHip: const Offset(510, 475),
    leftKnee: const Offset(486, 548),
    rightKnee: const Offset(516, 540),
    leftAnkle: const Offset(480, 620),
    rightAnkle: const Offset(522, 612),
    leftHeel: const Offset(474, 625),
    rightHeel: const Offset(516, 617),
  );
}

RunningPoseObservation _distantDetailedObservation() {
  return _observation(
    nose: const Offset(500, 390),
    leftShoulder: const Offset(487, 425),
    rightShoulder: const Offset(513, 425),
    leftElbow: const Offset(475, 452),
    rightElbow: const Offset(525, 452),
    leftWrist: const Offset(468, 477),
    rightWrist: const Offset(532, 477),
    leftHip: const Offset(491, 482),
    rightHip: const Offset(509, 482),
    leftKnee: const Offset(488, 538),
    rightKnee: const Offset(512, 532),
    leftAnkle: const Offset(484, 590),
    rightAnkle: const Offset(516, 584),
    leftHeel: const Offset(479, 595),
    rightHeel: const Offset(511, 589),
  );
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
  double confidence = 0.98,
}) {
  final landmarks = <RunningPoseLandmarkType, RunningPoseLandmark>{};

  void put(RunningPoseLandmarkType type, Offset? position) {
    if (position == null) {
      return;
    }
    landmarks[type] = _landmark(position.dx, position.dy, confidence);
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

RunningPoseLandmark _landmark(
  double x,
  double y, [
  double confidence = 0.98,
]) {
  return RunningPoseLandmark(
    position: Offset(x, y),
    likelihood: confidence,
  );
}
