import 'dart:collection';
import 'dart:math' as math;

import '../domain/entities/running_live_coaching_state.dart';

enum RunningLiveSkippedFrameReason {
  detectorBusy,
  throttled,
  invalidInput,
  analysisError,
}

class RunningLiveGaitEventLogEntry {
  final RunningFootSide side;
  final RunningGaitEventType type;
  final DateTime timestamp;
  final double confidence;

  const RunningLiveGaitEventLogEntry({
    required this.side,
    required this.type,
    required this.timestamp,
    required this.confidence,
  });

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'side': side.name,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'timestampMs': timestamp.millisecondsSinceEpoch,
      'confidence': confidence.toStringAsFixed(3),
    };
  }
}

class RunningLiveSessionMetricsSnapshot {
  final Duration elapsed;
  final int cameraInputFrames;
  final int analyzedFrames;
  final int skippedFrames;
  final int busySkippedFrames;
  final int throttledSkippedFrames;
  final int invalidInputFrames;
  final int analysisErrorFrames;
  final double cameraInputFps;
  final double analyzedFps;
  final int analyzedFrameIntervalSampleCount;
  final double analyzedFrameIntervalP50Ms;
  final double analyzedFrameIntervalP95Ms;
  final int processingLatencySampleCount;
  final double averageProcessingLatencyMs;
  final double processingLatencyP50Ms;
  final double processingLatencyP95Ms;
  final double averageTimingConfidence;
  final double averageSideViewConfidence;
  final int cadenceAvailableFrames;
  final int cadenceUnavailableFrames;
  final int leftContactAvailableFrames;
  final int leftContactUnavailableFrames;
  final int rightContactAvailableFrames;
  final int rightContactUnavailableFrames;
  final int touchdownEvents;
  final int toeOffEvents;
  final List<RunningLiveGaitEventLogEntry> eventTimeline;

  const RunningLiveSessionMetricsSnapshot({
    required this.elapsed,
    required this.cameraInputFrames,
    required this.analyzedFrames,
    required this.skippedFrames,
    required this.busySkippedFrames,
    required this.throttledSkippedFrames,
    required this.invalidInputFrames,
    required this.analysisErrorFrames,
    required this.cameraInputFps,
    required this.analyzedFps,
    required this.analyzedFrameIntervalSampleCount,
    required this.analyzedFrameIntervalP50Ms,
    required this.analyzedFrameIntervalP95Ms,
    required this.processingLatencySampleCount,
    required this.averageProcessingLatencyMs,
    required this.processingLatencyP50Ms,
    required this.processingLatencyP95Ms,
    required this.averageTimingConfidence,
    required this.averageSideViewConfidence,
    required this.cadenceAvailableFrames,
    required this.cadenceUnavailableFrames,
    required this.leftContactAvailableFrames,
    required this.leftContactUnavailableFrames,
    required this.rightContactAvailableFrames,
    required this.rightContactUnavailableFrames,
    required this.touchdownEvents,
    required this.toeOffEvents,
    required this.eventTimeline,
  });

  const RunningLiveSessionMetricsSnapshot.initial()
      : elapsed = Duration.zero,
        cameraInputFrames = 0,
        analyzedFrames = 0,
        skippedFrames = 0,
        busySkippedFrames = 0,
        throttledSkippedFrames = 0,
        invalidInputFrames = 0,
        analysisErrorFrames = 0,
        cameraInputFps = 0,
        analyzedFps = 0,
        analyzedFrameIntervalSampleCount = 0,
        analyzedFrameIntervalP50Ms = 0,
        analyzedFrameIntervalP95Ms = 0,
        processingLatencySampleCount = 0,
        averageProcessingLatencyMs = 0,
        processingLatencyP50Ms = 0,
        processingLatencyP95Ms = 0,
        averageTimingConfidence = 0,
        averageSideViewConfidence = 0,
        cadenceAvailableFrames = 0,
        cadenceUnavailableFrames = 0,
        leftContactAvailableFrames = 0,
        leftContactUnavailableFrames = 0,
        rightContactAvailableFrames = 0,
        rightContactUnavailableFrames = 0,
        touchdownEvents = 0,
        toeOffEvents = 0,
        eventTimeline = const <RunningLiveGaitEventLogEntry>[];

  int get eventCount => touchdownEvents + toeOffEvents;
}

class RunningLiveSessionMetricsCollector {
  final int maxTimingSamples;
  final int maxEventTimelineLength;
  final int maxSeenEventKeys;

  DateTime? _startedAt;
  int _cameraInputFrames = 0;
  int _analyzedFrames = 0;
  int _busySkippedFrames = 0;
  int _throttledSkippedFrames = 0;
  int _invalidInputFrames = 0;
  int _analysisErrorFrames = 0;
  int _totalProcessingMicros = 0;
  int _cadenceAvailableFrames = 0;
  int _cadenceUnavailableFrames = 0;
  int _leftContactAvailableFrames = 0;
  int _leftContactUnavailableFrames = 0;
  int _rightContactAvailableFrames = 0;
  int _rightContactUnavailableFrames = 0;
  int _touchdownEvents = 0;
  int _toeOffEvents = 0;
  double _totalTimingConfidence = 0;
  double _totalSideViewConfidence = 0;
  DateTime? _lastAnalyzedAt;

  final Queue<int> _analyzedFrameIntervalMicros = Queue<int>();
  final Queue<int> _processingLatencyMicros = Queue<int>();
  final Queue<RunningLiveGaitEventLogEntry> _eventTimeline =
      Queue<RunningLiveGaitEventLogEntry>();
  final Queue<String> _seenEventKeyOrder = Queue<String>();
  final Set<String> _seenEventKeys = <String>{};

  RunningLiveSessionMetricsCollector({
    this.maxTimingSamples = 600,
    this.maxEventTimelineLength = 96,
    this.maxSeenEventKeys = 256,
  })  : assert(maxTimingSamples > 0),
        assert(maxEventTimelineLength > 0),
        assert(maxSeenEventKeys > 0);

  void reset() {
    _startedAt = null;
    _cameraInputFrames = 0;
    _analyzedFrames = 0;
    _busySkippedFrames = 0;
    _throttledSkippedFrames = 0;
    _invalidInputFrames = 0;
    _analysisErrorFrames = 0;
    _totalProcessingMicros = 0;
    _cadenceAvailableFrames = 0;
    _cadenceUnavailableFrames = 0;
    _leftContactAvailableFrames = 0;
    _leftContactUnavailableFrames = 0;
    _rightContactAvailableFrames = 0;
    _rightContactUnavailableFrames = 0;
    _touchdownEvents = 0;
    _toeOffEvents = 0;
    _totalTimingConfidence = 0;
    _totalSideViewConfidence = 0;
    _lastAnalyzedAt = null;
    _analyzedFrameIntervalMicros.clear();
    _processingLatencyMicros.clear();
    _eventTimeline.clear();
    _seenEventKeyOrder.clear();
    _seenEventKeys.clear();
  }

  void recordCameraInputFrame({DateTime? timestamp}) {
    _ensureStarted(timestamp ?? DateTime.now());
    _cameraInputFrames += 1;
  }

  void recordSkippedFrame(RunningLiveSkippedFrameReason reason) {
    switch (reason) {
      case RunningLiveSkippedFrameReason.detectorBusy:
        _busySkippedFrames += 1;
      case RunningLiveSkippedFrameReason.throttled:
        _throttledSkippedFrames += 1;
      case RunningLiveSkippedFrameReason.invalidInput:
        _invalidInputFrames += 1;
      case RunningLiveSkippedFrameReason.analysisError:
        _analysisErrorFrames += 1;
    }
  }

  void recordAnalyzedFrame({
    required DateTime timestamp,
    required Duration processingTime,
    required RunningLiveCoachingState state,
  }) {
    _ensureStarted(timestamp);
    _analyzedFrames += 1;
    _totalProcessingMicros += processingTime.inMicroseconds;
    _addBoundedSample(
      _processingLatencyMicros,
      processingTime.inMicroseconds,
      maxTimingSamples,
    );

    final lastAnalyzedAt = _lastAnalyzedAt;
    if (lastAnalyzedAt != null && timestamp.isAfter(lastAnalyzedAt)) {
      _addBoundedSample(
        _analyzedFrameIntervalMicros,
        timestamp.difference(lastAnalyzedAt).inMicroseconds,
        maxTimingSamples,
      );
    }
    _lastAnalyzedAt = timestamp;

    final gait = state.gaitAnalysis;
    _totalTimingConfidence += gait.timingConfidence;
    _totalSideViewConfidence += gait.sideViewConfidence;
    _recordAvailability(gait);
    _recordEvents(gait.recentEvents);
  }

  RunningLiveSessionMetricsSnapshot snapshot({DateTime? now}) {
    final end = now ?? DateTime.now();
    final startedAt = _startedAt;
    final elapsed =
        startedAt == null ? Duration.zero : end.difference(startedAt);
    final elapsedSeconds = math.max(elapsed.inMilliseconds / 1000, 0.001);
    final analyzedFrames = _analyzedFrames;
    final skippedFrames = _busySkippedFrames +
        _throttledSkippedFrames +
        _invalidInputFrames +
        _analysisErrorFrames;

    return RunningLiveSessionMetricsSnapshot(
      elapsed: elapsed,
      cameraInputFrames: _cameraInputFrames,
      analyzedFrames: analyzedFrames,
      skippedFrames: skippedFrames,
      busySkippedFrames: _busySkippedFrames,
      throttledSkippedFrames: _throttledSkippedFrames,
      invalidInputFrames: _invalidInputFrames,
      analysisErrorFrames: _analysisErrorFrames,
      cameraInputFps: _cameraInputFrames / elapsedSeconds,
      analyzedFps: analyzedFrames / elapsedSeconds,
      analyzedFrameIntervalSampleCount: _analyzedFrameIntervalMicros.length,
      analyzedFrameIntervalP50Ms: _percentileMs(
        _analyzedFrameIntervalMicros,
        0.50,
      ),
      analyzedFrameIntervalP95Ms: _percentileMs(
        _analyzedFrameIntervalMicros,
        0.95,
      ),
      processingLatencySampleCount: _processingLatencyMicros.length,
      averageProcessingLatencyMs: analyzedFrames == 0
          ? 0
          : (_totalProcessingMicros / analyzedFrames) / 1000,
      processingLatencyP50Ms: _percentileMs(_processingLatencyMicros, 0.50),
      processingLatencyP95Ms: _percentileMs(_processingLatencyMicros, 0.95),
      averageTimingConfidence:
          analyzedFrames == 0 ? 0 : _totalTimingConfidence / analyzedFrames,
      averageSideViewConfidence:
          analyzedFrames == 0 ? 0 : _totalSideViewConfidence / analyzedFrames,
      cadenceAvailableFrames: _cadenceAvailableFrames,
      cadenceUnavailableFrames: _cadenceUnavailableFrames,
      leftContactAvailableFrames: _leftContactAvailableFrames,
      leftContactUnavailableFrames: _leftContactUnavailableFrames,
      rightContactAvailableFrames: _rightContactAvailableFrames,
      rightContactUnavailableFrames: _rightContactUnavailableFrames,
      touchdownEvents: _touchdownEvents,
      toeOffEvents: _toeOffEvents,
      eventTimeline: List<RunningLiveGaitEventLogEntry>.unmodifiable(
        _eventTimeline,
      ),
    );
  }

  Map<String, Object?> buildLogPayload({
    required String event,
    required String sessionId,
    required DateTime timestamp,
    required Duration targetFrameInterval,
    required RunningLiveSessionMetricsSnapshot snapshot,
    required RunningLiveCoachingState state,
    Map<String, Object?>? details,
  }) {
    final gait = state.gaitAnalysis;
    return <String, Object?>{
      'sessionId': sessionId,
      'event': event,
      'timestamp': timestamp.toIso8601String(),
      'elapsedMs': snapshot.elapsed.inMilliseconds,
      'targetFrameIntervalMs': targetFrameInterval.inMilliseconds,
      'state': <String, Object?>{
        'primaryCue': state.primaryCue.name,
        'framingIssue': state.framingIssue?.name,
        'stableAnalysis': state.hasStableAnalysis,
        'trackedFrames': state.trackedFrames,
      },
      'gait': <String, Object?>{
        'phase': gait.currentPhase.name,
        'phaseConfidence': gait.phaseConfidence.toStringAsFixed(3),
        'timingConfidence': gait.timingConfidence.toStringAsFixed(3),
        'sideViewConfidence': gait.sideViewConfidence.toStringAsFixed(3),
        'validFrameCount': gait.validFrameCount,
        'cadence': _metricPayload(gait.cadence),
        'leftContactDuration': _metricPayload(gait.leftContactDuration),
        'rightContactDuration': _metricPayload(gait.rightContactDuration),
      },
      'metrics': <String, Object?>{
        'cameraInputFrames': snapshot.cameraInputFrames,
        'analyzedFrames': snapshot.analyzedFrames,
        'cameraInputFps': snapshot.cameraInputFps.toStringAsFixed(2),
        'analyzedFps': snapshot.analyzedFps.toStringAsFixed(2),
        'skippedFrames': <String, Object?>{
          'total': snapshot.skippedFrames,
          'busy': snapshot.busySkippedFrames,
          'throttled': snapshot.throttledSkippedFrames,
          'invalidInput': snapshot.invalidInputFrames,
          'analysisError': snapshot.analysisErrorFrames,
        },
        'analyzedFrameIntervalMs': <String, Object?>{
          'sampleCount': snapshot.analyzedFrameIntervalSampleCount,
          'p50': snapshot.analyzedFrameIntervalP50Ms.toStringAsFixed(2),
          'p95': snapshot.analyzedFrameIntervalP95Ms.toStringAsFixed(2),
        },
        'processingLatencyMs': <String, Object?>{
          'sampleCount': snapshot.processingLatencySampleCount,
          'average': snapshot.averageProcessingLatencyMs.toStringAsFixed(2),
          'p50': snapshot.processingLatencyP50Ms.toStringAsFixed(2),
          'p95': snapshot.processingLatencyP95Ms.toStringAsFixed(2),
        },
        'averageConfidence': <String, Object?>{
          'timing': snapshot.averageTimingConfidence.toStringAsFixed(3),
          'sideView': snapshot.averageSideViewConfidence.toStringAsFixed(3),
        },
        'availability': <String, Object?>{
          'cadence': <String, Object?>{
            'available': snapshot.cadenceAvailableFrames,
            'unavailable': snapshot.cadenceUnavailableFrames,
          },
          'leftContactDuration': <String, Object?>{
            'available': snapshot.leftContactAvailableFrames,
            'unavailable': snapshot.leftContactUnavailableFrames,
          },
          'rightContactDuration': <String, Object?>{
            'available': snapshot.rightContactAvailableFrames,
            'unavailable': snapshot.rightContactUnavailableFrames,
          },
        },
      },
      'events': <String, Object?>{
        'total': snapshot.eventCount,
        'touchdown': snapshot.touchdownEvents,
        'toeOff': snapshot.toeOffEvents,
        'timeline': [
          for (final event in snapshot.eventTimeline) event.toJson(),
        ],
      },
      if (details != null && details.isNotEmpty) 'details': details,
    };
  }

  void _recordAvailability(RunningGaitAnalysis gait) {
    if (gait.cadence.available) {
      _cadenceAvailableFrames += 1;
    } else {
      _cadenceUnavailableFrames += 1;
    }
    if (gait.leftContactDuration.available) {
      _leftContactAvailableFrames += 1;
    } else {
      _leftContactUnavailableFrames += 1;
    }
    if (gait.rightContactDuration.available) {
      _rightContactAvailableFrames += 1;
    } else {
      _rightContactUnavailableFrames += 1;
    }
  }

  void _recordEvents(List<RunningGaitEvent> events) {
    for (final event in events) {
      final key = _eventKey(event);
      if (_seenEventKeys.contains(key)) {
        continue;
      }
      _seenEventKeys.add(key);
      _seenEventKeyOrder.addLast(key);
      while (_seenEventKeyOrder.length > maxSeenEventKeys) {
        _seenEventKeys.remove(_seenEventKeyOrder.removeFirst());
      }

      switch (event.type) {
        case RunningGaitEventType.touchdown:
          _touchdownEvents += 1;
        case RunningGaitEventType.toeOff:
          _toeOffEvents += 1;
      }
      _eventTimeline.addLast(
        RunningLiveGaitEventLogEntry(
          side: event.side,
          type: event.type,
          timestamp: event.timestamp,
          confidence: event.confidence,
        ),
      );
      while (_eventTimeline.length > maxEventTimelineLength) {
        _eventTimeline.removeFirst();
      }
    }
  }

  Map<String, Object?> _metricPayload(RunningGaitMetric metric) {
    return <String, Object?>{
      'available': metric.available,
      'value': metric.value?.toStringAsFixed(2),
      'confidence': metric.confidence.toStringAsFixed(3),
      'sampleCount': metric.sampleCount,
      'reasonIfUnavailable': metric.reasonIfUnavailable,
    };
  }

  void _ensureStarted(DateTime timestamp) {
    _startedAt ??= timestamp;
  }

  void _addBoundedSample(Queue<int> samples, int value, int maximumLength) {
    samples.addLast(value);
    while (samples.length > maximumLength) {
      samples.removeFirst();
    }
  }

  double _percentileMs(Iterable<int> micros, double percentile) {
    final values = micros.toList(growable: false)..sort();
    if (values.isEmpty) {
      return 0;
    }
    final rank = ((values.length - 1) * percentile).ceil();
    return values[rank.clamp(0, values.length - 1)] / 1000;
  }

  String _eventKey(RunningGaitEvent event) {
    return '${event.side.name}|${event.type.name}|'
        '${event.timestamp.microsecondsSinceEpoch}';
  }
}
