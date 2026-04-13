import 'dart:ui' show Offset, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/entities/sprint_pose_frame.dart';
import 'package:football_note/domain/entities/sprint_realtime_coaching_state.dart';
import 'package:football_note/realtime_analysis/sprint_coaching/sprint_pipeline_config.dart';
import 'package:football_note/realtime_analysis/sprint_coaching/sprint_realtime_coaching_pipeline.dart';

void main() {
  group('SprintRealtimeCoachingPipeline', () {
    test('keeps the active cue until cooldown expires', () {
      final pipeline = SprintRealtimeCoachingPipeline(
        config: const SprintPipelineConfig(
          analysisWindow: Duration(milliseconds: 400),
          feedbackCooldown: Duration(milliseconds: 1800),
          minimumWindowFrames: 4,
        ),
      );
      final start = DateTime(2026, 4, 13, 9);

      SprintRealtimeCoachingState state =
          const SprintRealtimeCoachingState.initial();

      for (var index = 0; index < 4; index += 1) {
        state = pipeline.ingest(
          _poseFrame(
            timestamp: start.add(Duration(milliseconds: 120 * index)),
            hipCenterX: 220.0 + (30 * index),
            trunkLeanX: 0.08,
            kneeDriveHeight: 0.36,
            leftAnkleX: index.isEven ? 0.22 : -0.22,
            rightAnkleX: index.isEven ? -0.22 : 0.22,
          ),
        );
      }

      expect(state.status, SprintCoachingStatus.coaching);
      expect(state.feedback?.code, SprintFeedbackCode.leanForwardMore);
      expect(state.features.trunkAngleDegrees, lessThan(8));

      for (var index = 0; index < 4; index += 1) {
        state = pipeline.ingest(
          _poseFrame(
            timestamp: start.add(Duration(milliseconds: 480 + (120 * index))),
            hipCenterX: 360.0 + (30 * index),
            trunkLeanX: 0.22,
            kneeDriveHeight: 0.04,
            leftAnkleX: index.isEven ? 0.24 : -0.24,
            rightAnkleX: index.isEven ? -0.24 : 0.24,
          ),
        );
      }

      expect(state.features.trunkAngleDegrees, greaterThan(8));
      expect(state.stateEstimate.feedbackCooldownActive, isTrue);
      expect(state.feedback?.code, SprintFeedbackCode.leanForwardMore);

      for (var index = 0; index < 4; index += 1) {
        state = pipeline.ingest(
          _poseFrame(
            timestamp: start.add(Duration(milliseconds: 2400 + (120 * index))),
            hipCenterX: 520.0 + (30 * index),
            trunkLeanX: 0.22,
            kneeDriveHeight: 0.04,
            leftAnkleX: index.isEven ? 0.24 : -0.24,
            rightAnkleX: index.isEven ? -0.24 : 0.24,
          ),
        );
      }

      expect(state.stateEstimate.feedbackCooldownActive, isFalse);
      expect(state.features.kneeDriveHeightRatio, lessThan(0.24));
      expect(state.feedback?.code, SprintFeedbackCode.driveKneeHigher);
    });

    test('falls back to body-visible guidance when landmarks disappear', () {
      final pipeline = SprintRealtimeCoachingPipeline(
        config: const SprintPipelineConfig(
          analysisWindow: Duration(milliseconds: 400),
          minimumWindowFrames: 4,
        ),
      );
      final state = pipeline.ingest(
        SprintPoseFrame(
          imageSize: const Size(1000, 1000),
          timestamp: DateTime(2026, 4, 13, 9),
          landmarks: <SprintPoseLandmarkType, SprintPoseLandmark>{
            SprintPoseLandmarkType.leftHip: _landmark(430, 500),
            SprintPoseLandmarkType.rightHip: _landmark(470, 500),
            SprintPoseLandmarkType.leftShoulder: _landmark(430, 320),
            SprintPoseLandmarkType.rightShoulder: _landmark(470, 320),
          },
        ),
      );

      expect(state.status, SprintCoachingStatus.lowConfidence);
      expect(state.stateEstimate.bodyFullyVisible, isFalse);
      expect(state.feedback?.code, SprintFeedbackCode.bodyNotVisible);
    });
  });
}

SprintPoseFrame _poseFrame({
  required DateTime timestamp,
  required double hipCenterX,
  required double trunkLeanX,
  required double kneeDriveHeight,
  required double leftAnkleX,
  required double rightAnkleX,
}) {
  const imageSize = Size(1000, 1000);
  const scale = 180.0;
  const hipCenterY = 500.0;

  Offset point(double normalizedX, double normalizedY) {
    return Offset(
      hipCenterX + (normalizedX * scale),
      hipCenterY + (normalizedY * scale),
    );
  }

  final leftShoulderX = trunkLeanX - 0.18;
  final rightShoulderX = trunkLeanX + 0.18;

  return SprintPoseFrame(
    imageSize: imageSize,
    timestamp: timestamp,
    landmarks: <SprintPoseLandmarkType, SprintPoseLandmark>{
      SprintPoseLandmarkType.leftShoulder: _landmarkFromOffset(
        point(leftShoulderX, -1),
      ),
      SprintPoseLandmarkType.rightShoulder: _landmarkFromOffset(
        point(rightShoulderX, -1),
      ),
      SprintPoseLandmarkType.leftElbow: _landmarkFromOffset(
        point(leftShoulderX - 0.1, -0.62),
      ),
      SprintPoseLandmarkType.rightElbow: _landmarkFromOffset(
        point(rightShoulderX + 0.1, -0.62),
      ),
      SprintPoseLandmarkType.leftWrist: _landmarkFromOffset(
        point(leftShoulderX - 0.42, -0.28),
      ),
      SprintPoseLandmarkType.rightWrist: _landmarkFromOffset(
        point(rightShoulderX + 0.44, -0.28),
      ),
      SprintPoseLandmarkType.leftHip: _landmarkFromOffset(point(-0.14, 0)),
      SprintPoseLandmarkType.rightHip: _landmarkFromOffset(point(0.14, 0)),
      SprintPoseLandmarkType.leftKnee: _landmarkFromOffset(point(-0.16, -0.18)),
      SprintPoseLandmarkType.rightKnee: _landmarkFromOffset(
        point(0.16, -kneeDriveHeight),
      ),
      SprintPoseLandmarkType.leftAnkle: _landmarkFromOffset(
        point(leftAnkleX, 1),
      ),
      SprintPoseLandmarkType.rightAnkle: _landmarkFromOffset(
        point(rightAnkleX, 1),
      ),
    },
  );
}

SprintPoseLandmark _landmark(double x, double y) {
  return SprintPoseLandmark(position: Offset(x, y), confidence: 0.98);
}

SprintPoseLandmark _landmarkFromOffset(Offset offset) {
  return _landmark(offset.dx, offset.dy);
}
