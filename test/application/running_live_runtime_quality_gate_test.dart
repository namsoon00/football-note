import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/running_live_runtime_quality_gate.dart';
import 'package:football_note/application/running_live_session_metrics.dart';
import 'package:football_note/domain/entities/running_live_coaching_state.dart';

void main() {
  group('RunningLiveRuntimeQualityGate', () {
    test('allows form coaching after enough stable runtime evidence', () {
      const gate = RunningLiveRuntimeQualityGate();

      final readiness = gate.evaluate(
        snapshot: _snapshot(),
        state: _state(),
      );

      expect(readiness.status, RunningLiveRuntimeReadinessStatus.ready);
      expect(readiness.canEmitFormCoaching, isTrue);
    });

    test('pauses coaching while recent processing is too slow', () {
      const gate = RunningLiveRuntimeQualityGate();

      final readiness = gate.evaluate(
        snapshot: _snapshot(processingLatencyP95Ms: 220),
        state: _state(),
      );

      expect(readiness.status, RunningLiveRuntimeReadinessStatus.stabilizing);
      expect(
          readiness.reason, RunningLiveRuntimeReadinessReason.slowProcessing);
      expect(readiness.canEmitFormCoaching, isFalse);
    });

    test('pauses coaching when analyzed frame cadence has gaps', () {
      const gate = RunningLiveRuntimeQualityGate();

      final readiness = gate.evaluate(
        snapshot: _snapshot(analyzedFrameIntervalP95Ms: 230),
        state: _state(),
      );

      expect(readiness.status, RunningLiveRuntimeReadinessStatus.stabilizing);
      expect(readiness.reason, RunningLiveRuntimeReadinessReason.frameGaps);
      expect(readiness.canEmitFormCoaching, isFalse);
    });

    test('asks for setup fix for geometry-supported framing issues', () {
      const gate = RunningLiveRuntimeQualityGate();

      final readiness = gate.evaluate(
        snapshot: _snapshot(),
        state: _state(framingIssue: RunningLiveFramingIssue.stepBack),
      );

      expect(readiness.status, RunningLiveRuntimeReadinessStatus.fixSetup);
      expect(readiness.reason, RunningLiveRuntimeReadinessReason.setup);
      expect(readiness.canEmitFormCoaching, isFalse);
    });

    test('keeps ankle tracking recovery as stabilizing, not setup blame', () {
      const gate = RunningLiveRuntimeQualityGate();

      final readiness = gate.evaluate(
        snapshot: _snapshot(),
        state: _state(framingIssue: RunningLiveFramingIssue.trackingUncertain),
      );

      expect(readiness.status, RunningLiveRuntimeReadinessStatus.stabilizing);
      expect(
        readiness.reason,
        RunningLiveRuntimeReadinessReason.unstableTracking,
      );
      expect(readiness.canEmitFormCoaching, isFalse);
    });
  });
}

RunningLiveCoachingState _state({
  RunningLiveFramingIssue? framingIssue,
  int trackedFrames = 8,
}) {
  return RunningLiveCoachingState(
    framingIssue: framingIssue,
    primaryCue: switch (framingIssue) {
      RunningLiveFramingIssue.noRunnerDetected =>
        RunningLivePrimaryCue.noRunnerDetected,
      RunningLiveFramingIssue.trackingUncertain =>
        RunningLivePrimaryCue.trackingUncertain,
      RunningLiveFramingIssue.stepBack => RunningLivePrimaryCue.stepBack,
      RunningLiveFramingIssue.moveCloser => RunningLivePrimaryCue.moveCloser,
      RunningLiveFramingIssue.centerRunner =>
        RunningLivePrimaryCue.centerRunner,
      RunningLiveFramingIssue.turnSideways =>
        RunningLivePrimaryCue.turnSideways,
      null => RunningLivePrimaryCue.lookingGood,
    },
    trackedFrames: trackedFrames,
  );
}

RunningLiveSessionMetricsSnapshot _snapshot({
  int analyzedFrames = 8,
  int analyzedFrameIntervalSampleCount = 7,
  double analyzedFrameIntervalP95Ms = 80,
  int processingLatencySampleCount = 8,
  double processingLatencyP95Ms = 48,
  double averageTimingConfidence = 0.82,
  double averageSideViewConfidence = 0.84,
}) {
  return RunningLiveSessionMetricsSnapshot(
    elapsed: const Duration(seconds: 2),
    cameraInputFrames: 12,
    analyzedFrames: analyzedFrames,
    skippedFrames: 0,
    busySkippedFrames: 0,
    throttledSkippedFrames: 0,
    invalidInputFrames: 0,
    analysisErrorFrames: 0,
    cameraInputFps: 30,
    analyzedFps: 20,
    analyzedFrameIntervalSampleCount: analyzedFrameIntervalSampleCount,
    analyzedFrameIntervalP50Ms: 60,
    analyzedFrameIntervalP95Ms: analyzedFrameIntervalP95Ms,
    processingLatencySampleCount: processingLatencySampleCount,
    averageProcessingLatencyMs: 38,
    processingLatencyP50Ms: 40,
    processingLatencyP95Ms: processingLatencyP95Ms,
    averageTimingConfidence: averageTimingConfidence,
    averageSideViewConfidence: averageSideViewConfidence,
    cadenceAvailableFrames: 6,
    cadenceUnavailableFrames: 1,
    leftContactAvailableFrames: 4,
    leftContactUnavailableFrames: 2,
    rightContactAvailableFrames: 4,
    rightContactUnavailableFrames: 2,
    touchdownEvents: 4,
    toeOffEvents: 4,
    eventTimeline: const <RunningLiveGaitEventLogEntry>[],
  );
}
