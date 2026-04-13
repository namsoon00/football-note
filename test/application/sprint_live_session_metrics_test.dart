import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/sprint_live_session_metrics.dart';
import 'package:football_note/domain/entities/sprint_pose_frame.dart';
import 'package:football_note/domain/entities/sprint_realtime_coaching_state.dart';
import 'package:football_note/realtime_analysis/sprint_coaching/sprint_pipeline_config.dart';

void main() {
  group('SprintLiveSessionMetricsCollector', () {
    test(
      'includes readiness and step-detector diagnostics in session logs',
      () {
        final collector = SprintLiveSessionMetricsCollector();
        final start = DateTime(2026, 4, 13, 9);

        collector.recordCameraInputFrame(timestamp: start);
        collector.recordCameraInputFrame(
          timestamp: start.add(const Duration(milliseconds: 100)),
        );
        collector.recordAnalyzedFrame(
          timestamp: start.add(const Duration(milliseconds: 120)),
          processingTime: const Duration(milliseconds: 28),
          frame: SprintPoseFrame(
            imageSize: const Size(1000, 1000),
            timestamp: start,
            landmarks: <SprintPoseLandmarkType, SprintPoseLandmark>{
              SprintPoseLandmarkType.leftHip: _landmark(460, 500),
              SprintPoseLandmarkType.rightHip: _landmark(540, 500),
            },
          ),
          state: const SprintRealtimeCoachingState(
            status: SprintCoachingStatus.coaching,
            features: SprintFeatureSnapshot(
              detectedStepEvents: 3,
              stepCrossoverCount: 5,
              rejectedStepEventsLowVelocity: 1,
              rejectedStepEventsMinInterval: 2,
            ),
            stateEstimate: SprintStateEstimate(
              runningDetected: true,
              accelerationPhaseDetected: true,
              feedbackCooldownActive: true,
              lowConfidence: false,
              bodyFullyVisible: true,
              bodyVisibilityStatus: SprintBodyVisibilityStatus.full,
              trackingConfidence: 0.84,
              stableFrameCount: 6,
              visibleLandmarkCount: 11,
              visibleCoreLandmarkCount: 11,
              missingCoreLandmarkCount: 1,
              bodyVisibilityRatio: 0.917,
              hipTravelRatio: 0.082,
            ),
            feedback: SprintFeedbackMessage(
              code: SprintFeedbackCode.keepRhythmSteady,
              priority: 70,
              localizationKey: 'runningCoachSprintCueKeepRhythm',
              debugLabel: '리듬을 일정하게 유지하세요',
            ),
            feedbackSwitchSuppressedByCooldown: true,
          ),
        );

        final snapshot = collector.snapshot(
          now: start.add(const Duration(seconds: 1)),
        );
        final payload = collector.buildLogPayload(
          event: 'periodic',
          sessionId: 'session-1',
          timestamp: start.add(const Duration(seconds: 1)),
          config: const SprintPipelineConfig(),
          snapshot: snapshot,
          state: const SprintRealtimeCoachingState(
            status: SprintCoachingStatus.coaching,
            features: SprintFeatureSnapshot(
              trunkAngleDegrees: 12.8,
              kneeDriveHeightRatio: 0.34,
              cadenceStepsPerMinute: 224,
              stepInterval: Duration(milliseconds: 268),
              stepIntervalStdMs: 14.2,
              armSwingAsymmetryRatio: 0.08,
              detectedStepEvents: 3,
              stepCrossoverCount: 5,
              rejectedStepEventsLowVelocity: 1,
              rejectedStepEventsMinInterval: 2,
            ),
            stateEstimate: SprintStateEstimate(
              runningDetected: true,
              accelerationPhaseDetected: true,
              feedbackCooldownActive: true,
              lowConfidence: false,
              bodyFullyVisible: true,
              bodyVisibilityStatus: SprintBodyVisibilityStatus.full,
              trackingConfidence: 0.84,
              stableFrameCount: 6,
              visibleLandmarkCount: 11,
              visibleCoreLandmarkCount: 11,
              missingCoreLandmarkCount: 1,
              bodyVisibilityRatio: 0.917,
              hipTravelRatio: 0.082,
            ),
            feedback: SprintFeedbackMessage(
              code: SprintFeedbackCode.keepRhythmSteady,
              priority: 70,
              localizationKey: 'runningCoachSprintCueKeepRhythm',
              debugLabel: '리듬을 일정하게 유지하세요',
            ),
            feedbackSwitchSuppressedByCooldown: true,
          ),
          feedbackText: 'Keep rhythm',
        );

        expect(snapshot.feedbackChangeCount, 1);
        expect(snapshot.feedbackSuppressedByCooldownCount, 1);
        expect(payload['sessionId'], 'session-1');
        expect(payload['event'], 'periodic');
        expect(
          payload['configPreset'],
          SprintPipelineTuningPreset.balanced.name,
        );
        expect(payload['state'], <String, Object?>{
          'bodyFullyVisible': true,
          'bodyVisibilityStatus': 'full',
          'visibleLandmarks': 11,
          'visibleCoreLandmarks': 11,
          'missingCoreLandmarks': 1,
          'bodyVisibilityRatio': '0.917',
          'stableFrames': 6,
          'trackingConfidence': '0.840',
          'hipTravelRatio': '0.082',
          'runningDetected': true,
          'accelerationPhaseDetected': true,
          'feedbackCooldownActive': true,
        });
        expect(payload['features'], <String, Object?>{
          'trunkAngleDegrees': '12.80',
          'kneeDriveHeight': '0.340',
          'cadenceStepsPerMinute': '224.00',
          'stepIntervalMs': 268,
          'stepIntervalStdMs': '14.20',
          'armAsymmetryRatio': '0.080',
        });
        expect(payload['stepDetector'], <String, Object?>{
          'leadSwitches': 5,
          'acceptedEvents': 3,
          'rejectedLowVelocity': 1,
          'rejectedMinInterval': 2,
        });
        expect(payload['feedback'], <String, Object?>{
          'key': 'runningCoachSprintCueKeepRhythm',
          'text': 'Keep rhythm',
          'suppressedByCooldown': true,
        });
        expect(payload['metrics'], <String, Object?>{
          'cameraInputFps': '2.00',
          'analyzedFps': '1.00',
          'averageProcessingTimeMs': '28.00',
          'skippedFrames': <String, Object?>{
            'total': 0,
            'busy': 0,
            'throttled': 0,
            'invalidInput': 0,
            'analysisError': 0,
          },
          'bodyNotVisibleRatio': '0.000',
          'feedbackChanges': <String, Object?>{
            'count': 1,
            'perMinute': '60.00',
            'suppressedByCooldown': 1,
          },
        });
      },
    );
  });
}

SprintPoseLandmark _landmark(double x, double y) {
  return SprintPoseLandmark(position: Offset(x, y), confidence: 0.98);
}
