import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/running_live_session_metrics.dart';
import 'package:football_note/domain/entities/running_live_coaching_state.dart';

void main() {
  group('RunningLiveSessionMetricsCollector', () {
    test('tracks bounded timing, availability, skip, and deduped gait events',
        () {
      final collector = RunningLiveSessionMetricsCollector(
        maxTimingSamples: 3,
        maxEventTimelineLength: 2,
      );
      final start = DateTime(2026, 7, 20, 9);
      final touchdown = RunningGaitEvent(
        side: RunningFootSide.left,
        type: RunningGaitEventType.touchdown,
        timestamp: start.add(const Duration(milliseconds: 120)),
        confidence: 0.9,
      );
      final toeOff = RunningGaitEvent(
        side: RunningFootSide.left,
        type: RunningGaitEventType.toeOff,
        timestamp: start.add(const Duration(milliseconds: 240)),
        confidence: 0.8,
      );
      final rightTouchdown = RunningGaitEvent(
        side: RunningFootSide.right,
        type: RunningGaitEventType.touchdown,
        timestamp: start.add(const Duration(milliseconds: 380)),
        confidence: 0.85,
      );

      for (var index = 0; index < 6; index += 1) {
        collector.recordCameraInputFrame(
          timestamp: start.add(Duration(milliseconds: index * 40)),
        );
      }
      collector
        ..recordSkippedFrame(RunningLiveSkippedFrameReason.detectorBusy)
        ..recordSkippedFrame(RunningLiveSkippedFrameReason.throttled)
        ..recordSkippedFrame(RunningLiveSkippedFrameReason.invalidInput)
        ..recordSkippedFrame(RunningLiveSkippedFrameReason.analysisError);

      collector.recordAnalyzedFrame(
        timestamp: start,
        processingTime: const Duration(milliseconds: 30),
        state: _state(
          timingConfidence: 0.6,
          sideViewConfidence: 0.7,
          events: <RunningGaitEvent>[touchdown],
        ),
      );
      collector.recordAnalyzedFrame(
        timestamp: start.add(const Duration(milliseconds: 120)),
        processingTime: const Duration(milliseconds: 50),
        state: _state(
          cadenceAvailable: true,
          leftContactAvailable: true,
          timingConfidence: 0.8,
          sideViewConfidence: 0.9,
          events: <RunningGaitEvent>[touchdown, toeOff],
        ),
      );
      collector.recordAnalyzedFrame(
        timestamp: start.add(const Duration(milliseconds: 260)),
        processingTime: const Duration(milliseconds: 70),
        state: _state(
          cadenceAvailable: true,
          rightContactAvailable: true,
          timingConfidence: 1,
          sideViewConfidence: 0.8,
          events: <RunningGaitEvent>[toeOff, rightTouchdown],
        ),
      );
      collector.recordAnalyzedFrame(
        timestamp: start.add(const Duration(milliseconds: 500)),
        processingTime: const Duration(milliseconds: 90),
        state: _state(
          timingConfidence: 0.4,
          sideViewConfidence: 0.6,
        ),
      );

      final snapshot = collector.snapshot(
        now: start.add(const Duration(seconds: 1)),
      );

      expect(snapshot.cameraInputFrames, 6);
      expect(snapshot.analyzedFrames, 4);
      expect(snapshot.skippedFrames, 4);
      expect(snapshot.busySkippedFrames, 1);
      expect(snapshot.throttledSkippedFrames, 1);
      expect(snapshot.invalidInputFrames, 1);
      expect(snapshot.analysisErrorFrames, 1);
      expect(snapshot.analyzedFrameIntervalSampleCount, 3);
      expect(snapshot.analyzedFrameIntervalP50Ms, 140);
      expect(snapshot.analyzedFrameIntervalP95Ms, 240);
      expect(snapshot.processingLatencySampleCount, 3);
      expect(snapshot.averageProcessingLatencyMs, 60);
      expect(snapshot.processingLatencyP50Ms, 70);
      expect(snapshot.processingLatencyP95Ms, 90);
      expect(snapshot.averageTimingConfidence, closeTo(0.7, 0.0001));
      expect(snapshot.averageSideViewConfidence, closeTo(0.75, 0.0001));
      expect(snapshot.cadenceAvailableFrames, 2);
      expect(snapshot.cadenceUnavailableFrames, 2);
      expect(snapshot.leftContactAvailableFrames, 1);
      expect(snapshot.leftContactUnavailableFrames, 3);
      expect(snapshot.rightContactAvailableFrames, 1);
      expect(snapshot.rightContactUnavailableFrames, 3);
      expect(snapshot.touchdownEvents, 2);
      expect(snapshot.toeOffEvents, 1);
      expect(snapshot.eventTimeline, hasLength(2));
      expect(snapshot.eventTimeline.first.type, RunningGaitEventType.toeOff);
      expect(snapshot.eventTimeline.last.side, RunningFootSide.right);

      final payload = collector.buildLogPayload(
        event: 'periodic',
        sessionId: 'running-session',
        timestamp: start.add(const Duration(seconds: 1)),
        targetFrameInterval: const Duration(milliseconds: 120),
        snapshot: snapshot,
        state: _state(
          cadenceAvailable: true,
          leftContactAvailable: true,
          rightContactAvailable: true,
          events: <RunningGaitEvent>[rightTouchdown],
        ),
      );

      expect(payload['sessionId'], 'running-session');
      expect(payload['targetFrameIntervalMs'], 120);
      expect((payload['metrics'] as Map<String, Object?>)['skippedFrames'], {
        'total': 4,
        'busy': 1,
        'throttled': 1,
        'invalidInput': 1,
        'analysisError': 1,
      });
      expect((payload['events'] as Map<String, Object?>)['touchdown'], 2);
      expect((payload['events'] as Map<String, Object?>)['toeOff'], 1);
    });

    test('reset clears all session counters and bounded samples', () {
      final collector = RunningLiveSessionMetricsCollector();
      final start = DateTime(2026, 7, 20, 9);

      collector.recordCameraInputFrame(timestamp: start);
      collector.recordAnalyzedFrame(
        timestamp: start,
        processingTime: const Duration(milliseconds: 42),
        state: _state(
          events: <RunningGaitEvent>[
            RunningGaitEvent(
              side: RunningFootSide.left,
              type: RunningGaitEventType.touchdown,
              timestamp: start,
              confidence: 0.7,
            ),
          ],
        ),
      );

      collector.reset();

      const initial = RunningLiveSessionMetricsSnapshot.initial();
      final snapshot = collector.snapshot(now: start);
      expect(snapshot.cameraInputFrames, initial.cameraInputFrames);
      expect(snapshot.analyzedFrames, initial.analyzedFrames);
      expect(snapshot.eventCount, initial.eventCount);
      expect(snapshot.processingLatencySampleCount, 0);
      expect(snapshot.eventTimeline, isEmpty);
    });
  });
}

RunningLiveCoachingState _state({
  bool cadenceAvailable = false,
  bool leftContactAvailable = false,
  bool rightContactAvailable = false,
  double timingConfidence = 0,
  double sideViewConfidence = 0,
  List<RunningGaitEvent> events = const <RunningGaitEvent>[],
}) {
  return RunningLiveCoachingState(
    primaryCue: RunningLivePrimaryCue.keepRunning,
    gaitAnalysis: RunningGaitAnalysis(
      currentPhase: RunningGaitPhase.flight,
      phaseConfidence: 0.8,
      cadence: cadenceAvailable
          ? const RunningGaitMetric.available(
              value: 172,
              confidence: 0.8,
              sampleCount: 4,
            )
          : const RunningGaitMetric.unavailable(
              reasonIfUnavailable: 'insufficient_gait_events',
            ),
      leftContactDuration: leftContactAvailable
          ? const RunningGaitMetric.available(
              value: 220,
              confidence: 0.82,
              sampleCount: 2,
            )
          : const RunningGaitMetric.unavailable(
              reasonIfUnavailable: 'insufficient_contact_events',
            ),
      rightContactDuration: rightContactAvailable
          ? const RunningGaitMetric.available(
              value: 230,
              confidence: 0.84,
              sampleCount: 2,
            )
          : const RunningGaitMetric.unavailable(
              reasonIfUnavailable: 'insufficient_contact_events',
            ),
      recentEvents: events,
      touchdownCount: events
          .where((event) => event.type == RunningGaitEventType.touchdown)
          .length,
      toeOffCount: events
          .where((event) => event.type == RunningGaitEventType.toeOff)
          .length,
      validFrameCount: 8,
      timingConfidence: timingConfidence,
      sideViewConfidence: sideViewConfidence,
    ),
    trackedFrames: 8,
  );
}
