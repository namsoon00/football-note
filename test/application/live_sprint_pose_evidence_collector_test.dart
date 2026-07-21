import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/live_sprint_pose_evidence_collector.dart';
import 'package:football_note/domain/entities/running_coach_session.dart';
import 'package:football_note/domain/entities/running_live_coaching_state.dart';
import 'package:football_note/domain/entities/sprint_realtime_coaching_state.dart';
import 'package:football_note/realtime_analysis/running_coaching/running_visual_pose_tracker.dart';

void main() {
  test('retains the strongest observed joint evidence for each sprint phase',
      () {
    final collector = LiveSprintPoseEvidenceCollector();
    final startedAt = DateTime(2026, 7, 21, 10);
    collector.reset(startedAt: startedAt);

    collector.record(
      visualFrame: _frame(startedAt.add(const Duration(seconds: 1))),
      gaitAnalysis: _gait(phase: RunningGaitPhase.flight),
      sprintState: _sprintState(),
      timestamp: startedAt.add(const Duration(seconds: 1)),
    );
    collector.record(
      visualFrame: _frame(startedAt.add(const Duration(seconds: 2))),
      gaitAnalysis: _gait(
        phase: RunningGaitPhase.leftContact,
        events: <RunningGaitEvent>[
          RunningGaitEvent(
            side: RunningFootSide.left,
            type: RunningGaitEventType.touchdown,
            timestamp: startedAt.add(const Duration(seconds: 2)),
            confidence: 0.91,
          ),
        ],
      ),
      sprintState: _sprintState(),
      timestamp: startedAt.add(const Duration(seconds: 2)),
    );
    collector.record(
      visualFrame: _frame(startedAt.add(const Duration(seconds: 3))),
      gaitAnalysis: _gait(phase: RunningGaitPhase.rightContact),
      sprintState: _sprintState(),
      timestamp: startedAt.add(const Duration(seconds: 3)),
    );

    final evidence = collector.snapshot();
    expect(
      evidence.map((frame) => frame.phase),
      <LiveSprintPoseEvidencePhase>[
        LiveSprintPoseEvidencePhase.touchdown,
        LiveSprintPoseEvidencePhase.support,
        LiveSprintPoseEvidencePhase.flight,
      ],
    );
    expect(evidence[0].leadFoot, RunningFootSide.left);
    expect(evidence[0].capturedOffsetMs, 2000);
    expect(
        evidence[0].joints, hasLength(RunningPoseLandmarkType.values.length));
    expect(evidence.every((frame) => frame.quality >= 0.7), isTrue);
    expect(collector.diagnosticSnapshot().capturedPhaseCount, 3);
    expect(collector.diagnosticSnapshot().eligibleFrames, 3);

    final restored =
        LiveSprintPoseEvidenceFrame.fromMap(evidence.first.toMap());
    expect(restored.phase, LiveSprintPoseEvidencePhase.touchdown);
    expect(restored.leadFoot, RunningFootSide.left);
    expect(restored.joints, hasLength(RunningPoseLandmarkType.values.length));
  });

  test('rejects inferred core joints even when other tracking is ready', () {
    final collector = LiveSprintPoseEvidenceCollector();
    final timestamp = DateTime(2026, 7, 21, 10);

    collector.record(
      visualFrame: _frame(
        timestamp,
        state: RunningVisualPoseLandmarkState.inferred,
      ),
      gaitAnalysis: _gait(phase: RunningGaitPhase.flight),
      sprintState: _sprintState(),
      timestamp: timestamp,
    );

    expect(collector.snapshot(), isEmpty);
    final diagnostic = collector.diagnosticSnapshot();
    expect(
      diagnostic.currentBlocker,
      LiveSprintPoseEvidenceBlocker.observedCoreJoints,
    );
    expect(diagnostic.coreJointsBlockedFrames, 1);
  });

  test('records each actionable capture blocker without retaining pose data',
      () {
    final collector = LiveSprintPoseEvidenceCollector();
    final timestamp = DateTime(2026, 7, 21, 10);

    collector.record(
      visualFrame: _frame(timestamp),
      gaitAnalysis: _gait(phase: RunningGaitPhase.flight),
      sprintState: _sprintState(
        trackingReadiness: SprintTrackingReadiness.bodyPartiallyOutOfFrame,
        bodyFullyVisible: false,
      ),
      timestamp: timestamp,
    );
    collector.record(
      visualFrame: _frame(timestamp.add(const Duration(milliseconds: 50))),
      gaitAnalysis: _gait(phase: RunningGaitPhase.flight),
      sprintState: _sprintState(
        trackingReadiness: SprintTrackingReadiness.sideViewUnstable,
      ),
      timestamp: timestamp.add(const Duration(milliseconds: 50)),
    );
    collector.record(
      visualFrame: _frame(timestamp.add(const Duration(milliseconds: 100))),
      gaitAnalysis: _gait(phase: RunningGaitPhase.flight),
      sprintState: _sprintState(
        trackingReadiness: SprintTrackingReadiness.lowConfidence,
      ),
      timestamp: timestamp.add(const Duration(milliseconds: 100)),
    );
    collector.record(
      visualFrame: _frame(timestamp.add(const Duration(milliseconds: 150))),
      gaitAnalysis: _gait(
        phase: RunningGaitPhase.flight,
        phaseConfidence: 0.3,
      ),
      sprintState: _sprintState(),
      timestamp: timestamp.add(const Duration(milliseconds: 150)),
    );

    final diagnostic = collector.diagnosticSnapshot();
    expect(collector.snapshot(), isEmpty);
    expect(diagnostic.evaluatedFrames, 4);
    expect(diagnostic.eligibleFrames, 0);
    expect(diagnostic.fullBodyBlockedFrames, 1);
    expect(diagnostic.sideViewBlockedFrames, 1);
    expect(diagnostic.coreJointsBlockedFrames, 1);
    expect(diagnostic.gaitPhaseBlockedFrames, 1);
    expect(
      diagnostic.currentBlocker,
      LiveSprintPoseEvidenceBlocker.gaitPhaseReadiness,
    );
    expect(
      diagnostic.dominantBlocker,
      LiveSprintPoseEvidenceBlocker.fullBodyVisibility,
    );
  });
}

RunningVisualPoseFrame _frame(
  DateTime timestamp, {
  RunningVisualPoseLandmarkState state =
      RunningVisualPoseLandmarkState.observed,
}) {
  return RunningVisualPoseFrame(
    imageSize: const Size(720, 1280),
    timestamp: timestamp,
    observedAt: timestamp,
    landmarks: <RunningPoseLandmarkType, RunningVisualPoseLandmark>{
      for (final type in RunningPoseLandmarkType.values)
        type: RunningVisualPoseLandmark(
          position: Offset(
            120 + ((type.index % 5) * 90),
            100 + ((type.index ~/ 5) * 170),
          ),
          confidence: 0.91,
          rawConfidence: 0.91,
          z: type.index / 100,
          worldZ: null,
          visibility: 0.91,
          presence: 0.91,
          state: state,
        ),
    },
  );
}

RunningGaitAnalysis _gait({
  required RunningGaitPhase phase,
  List<RunningGaitEvent> events = const <RunningGaitEvent>[],
  double phaseConfidence = 0.88,
  double timingConfidence = 0.86,
}) {
  return RunningGaitAnalysis(
    currentPhase: phase,
    phaseConfidence: phaseConfidence,
    cadence: const RunningGaitMetric.unavailable(),
    leftContactDuration: const RunningGaitMetric.unavailable(),
    rightContactDuration: const RunningGaitMetric.unavailable(),
    recentEvents: events,
    touchdownCount: 4,
    toeOffCount: 4,
    validFrameCount: 40,
    timingConfidence: timingConfidence,
    sideViewConfidence: 0.9,
  );
}

SprintRealtimeCoachingState _sprintState({
  SprintTrackingReadiness trackingReadiness =
      SprintTrackingReadiness.readyForAnalysis,
  bool bodyFullyVisible = true,
}) {
  return SprintRealtimeCoachingState(
    status: SprintCoachingStatus.coaching,
    features: const SprintFeatureSnapshot.empty(),
    stateEstimate: SprintStateEstimate(
      runningDetected: true,
      accelerationPhaseDetected: true,
      feedbackCooldownActive: false,
      lowConfidence: trackingReadiness == SprintTrackingReadiness.lowConfidence,
      bodyFullyVisible: bodyFullyVisible,
      bodyVisibilityStatus: bodyFullyVisible
          ? SprintBodyVisibilityStatus.full
          : SprintBodyVisibilityStatus.partial,
      trackingReadiness: trackingReadiness,
      trackingConfidence: 0.9,
      stableFrameCount: 20,
      visibleLandmarkCount: 33,
      visibleCoreLandmarkCount: 11,
      missingCoreLandmarkCount: 0,
      bodyVisibilityRatio: 1,
      hipTravelRatio: 0.12,
      personHeightRatio: 0.66,
      personAreaRatio: 0.24,
      averageLandmarkConfidence: 0.91,
      sideViewConfidence: 0.9,
      personBounds: null,
      suggestedCropRect: null,
    ),
    trackedFrames: 40,
  );
}
