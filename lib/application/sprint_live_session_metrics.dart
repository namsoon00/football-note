import 'dart:math' as math;

import '../domain/entities/sprint_pose_frame.dart';
import '../domain/entities/sprint_realtime_coaching_state.dart';
import '../realtime_analysis/sprint_coaching/sprint_pipeline_config.dart';

const List<String> sprintConfidenceBucketLabels = <String>[
  '0.0-0.2',
  '0.2-0.4',
  '0.4-0.6',
  '0.6-0.8',
  '0.8-1.0',
];

enum SprintSkippedFrameReason {
  detectorBusy,
  throttled,
  invalidInput,
  analysisError,
}

class SprintLiveSessionMetricsSnapshot {
  final Duration elapsed;
  final int cameraInputFrames;
  final int analyzedFrames;
  final int skippedFrames;
  final int busySkippedFrames;
  final int throttledSkippedFrames;
  final int invalidInputFrames;
  final int analysisErrorFrames;
  final int bodyNotVisibleCount;
  final int feedbackChangeCount;
  final int feedbackSuppressedByCooldownCount;
  final double cameraInputFps;
  final double analyzedFps;
  final double averageProcessingTimeMs;
  final double bodyNotVisibleRatio;
  final double feedbackChangesPerMinute;
  final List<int> confidenceBucketCounts;

  const SprintLiveSessionMetricsSnapshot({
    required this.elapsed,
    required this.cameraInputFrames,
    required this.analyzedFrames,
    required this.skippedFrames,
    required this.busySkippedFrames,
    required this.throttledSkippedFrames,
    required this.invalidInputFrames,
    required this.analysisErrorFrames,
    required this.bodyNotVisibleCount,
    required this.feedbackChangeCount,
    required this.feedbackSuppressedByCooldownCount,
    required this.cameraInputFps,
    required this.analyzedFps,
    required this.averageProcessingTimeMs,
    required this.bodyNotVisibleRatio,
    required this.feedbackChangesPerMinute,
    required this.confidenceBucketCounts,
  });

  const SprintLiveSessionMetricsSnapshot.initial()
    : elapsed = Duration.zero,
      cameraInputFrames = 0,
      analyzedFrames = 0,
      skippedFrames = 0,
      busySkippedFrames = 0,
      throttledSkippedFrames = 0,
      invalidInputFrames = 0,
      analysisErrorFrames = 0,
      bodyNotVisibleCount = 0,
      feedbackChangeCount = 0,
      feedbackSuppressedByCooldownCount = 0,
      cameraInputFps = 0,
      analyzedFps = 0,
      averageProcessingTimeMs = 0,
      bodyNotVisibleRatio = 0,
      feedbackChangesPerMinute = 0,
      confidenceBucketCounts = const <int>[0, 0, 0, 0, 0];

  int get confidenceSampleCount =>
      confidenceBucketCounts.fold<int>(0, (sum, value) => sum + value);

  double confidenceBucketRatio(int index) {
    final total = confidenceSampleCount;
    if (total == 0 || index < 0 || index >= confidenceBucketCounts.length) {
      return 0;
    }
    return confidenceBucketCounts[index] / total;
  }
}

class SprintLiveSessionMetricsCollector {
  DateTime? _startedAt;
  int _cameraInputFrames = 0;
  int _analyzedFrames = 0;
  int _busySkippedFrames = 0;
  int _throttledSkippedFrames = 0;
  int _invalidInputFrames = 0;
  int _analysisErrorFrames = 0;
  int _bodyNotVisibleCount = 0;
  int _feedbackChangeCount = 0;
  int _feedbackSuppressedByCooldownCount = 0;
  int _totalProcessingMicros = 0;
  String? _lastFeedbackKey;
  final List<int> _confidenceBucketCounts = List<int>.filled(
    sprintConfidenceBucketLabels.length,
    0,
  );

  void reset() {
    _startedAt = null;
    _cameraInputFrames = 0;
    _analyzedFrames = 0;
    _busySkippedFrames = 0;
    _throttledSkippedFrames = 0;
    _invalidInputFrames = 0;
    _analysisErrorFrames = 0;
    _bodyNotVisibleCount = 0;
    _feedbackChangeCount = 0;
    _feedbackSuppressedByCooldownCount = 0;
    _totalProcessingMicros = 0;
    _lastFeedbackKey = null;
    for (var index = 0; index < _confidenceBucketCounts.length; index += 1) {
      _confidenceBucketCounts[index] = 0;
    }
  }

  void recordCameraInputFrame({DateTime? timestamp}) {
    _ensureStarted(timestamp ?? DateTime.now());
    _cameraInputFrames += 1;
  }

  void recordSkippedFrame(SprintSkippedFrameReason reason) {
    switch (reason) {
      case SprintSkippedFrameReason.detectorBusy:
        _busySkippedFrames += 1;
      case SprintSkippedFrameReason.throttled:
        _throttledSkippedFrames += 1;
      case SprintSkippedFrameReason.invalidInput:
        _invalidInputFrames += 1;
      case SprintSkippedFrameReason.analysisError:
        _analysisErrorFrames += 1;
    }
  }

  void recordAnalyzedFrame({
    required DateTime timestamp,
    required Duration processingTime,
    required SprintPoseFrame? frame,
    required SprintRealtimeCoachingState state,
  }) {
    _ensureStarted(timestamp);
    _analyzedFrames += 1;
    _totalProcessingMicros += processingTime.inMicroseconds;

    if (state.feedback?.code == SprintFeedbackCode.bodyNotVisible) {
      _bodyNotVisibleCount += 1;
    }
    if (state.feedbackSwitchSuppressedByCooldown) {
      _feedbackSuppressedByCooldownCount += 1;
    }

    final feedbackKey = state.feedback?.localizationKey;
    if (feedbackKey != null && feedbackKey.isNotEmpty) {
      if (feedbackKey != _lastFeedbackKey) {
        _feedbackChangeCount += 1;
        _lastFeedbackKey = feedbackKey;
      }
    } else {
      _lastFeedbackKey = null;
    }

    if (frame == null) {
      return;
    }

    for (final landmark in frame.landmarks.values) {
      _confidenceBucketCounts[_bucketIndex(landmark.confidence)] += 1;
    }
  }

  SprintLiveSessionMetricsSnapshot snapshot({DateTime? now}) {
    final end = now ?? DateTime.now();
    final startedAt = _startedAt;
    final elapsed = startedAt == null
        ? Duration.zero
        : end.difference(startedAt);
    final elapsedSeconds = math.max(elapsed.inMilliseconds / 1000, 0.001);
    final analyzedFrames = _analyzedFrames;
    final skippedFrames =
        _busySkippedFrames +
        _throttledSkippedFrames +
        _invalidInputFrames +
        _analysisErrorFrames;

    return SprintLiveSessionMetricsSnapshot(
      elapsed: elapsed,
      cameraInputFrames: _cameraInputFrames,
      analyzedFrames: analyzedFrames,
      skippedFrames: skippedFrames,
      busySkippedFrames: _busySkippedFrames,
      throttledSkippedFrames: _throttledSkippedFrames,
      invalidInputFrames: _invalidInputFrames,
      analysisErrorFrames: _analysisErrorFrames,
      bodyNotVisibleCount: _bodyNotVisibleCount,
      feedbackChangeCount: _feedbackChangeCount,
      feedbackSuppressedByCooldownCount: _feedbackSuppressedByCooldownCount,
      cameraInputFps: _cameraInputFrames / elapsedSeconds,
      analyzedFps: analyzedFrames / elapsedSeconds,
      averageProcessingTimeMs: analyzedFrames == 0
          ? 0
          : (_totalProcessingMicros / analyzedFrames) / 1000,
      bodyNotVisibleRatio: analyzedFrames == 0
          ? 0
          : _bodyNotVisibleCount / analyzedFrames,
      feedbackChangesPerMinute: _feedbackChangeCount / (elapsedSeconds / 60),
      confidenceBucketCounts: List<int>.unmodifiable(_confidenceBucketCounts),
    );
  }

  Map<String, Object?> buildLogPayload({
    required String event,
    required String sessionId,
    required DateTime timestamp,
    required SprintPipelineConfig config,
    required SprintLiveSessionMetricsSnapshot snapshot,
    required SprintRealtimeCoachingState state,
    String? feedbackText,
    Map<String, Object?>? details,
  }) {
    return <String, Object?>{
      'sessionId': sessionId,
      'event': event,
      'timestamp': timestamp.toIso8601String(),
      'configPreset': config.preset.name,
      'elapsedMs': snapshot.elapsed.inMilliseconds,
      'status': state.status.name,
      'state': <String, Object?>{
        'bodyFullyVisible': state.stateEstimate.bodyFullyVisible,
        'bodyVisibilityStatus': state.stateEstimate.bodyVisibilityStatus.name,
        'visibleLandmarks': state.stateEstimate.visibleLandmarkCount,
        'visibleCoreLandmarks': state.stateEstimate.visibleCoreLandmarkCount,
        'missingCoreLandmarks': state.stateEstimate.missingCoreLandmarkCount,
        'bodyVisibilityRatio': state.stateEstimate.bodyVisibilityRatio
            .toStringAsFixed(3),
        'stableFrames': state.stateEstimate.stableFrameCount,
        'trackingConfidence': state.stateEstimate.trackingConfidence
            .toStringAsFixed(3),
        'hipTravelRatio': state.stateEstimate.hipTravelRatio.toStringAsFixed(3),
        'runningDetected': state.stateEstimate.runningDetected,
        'accelerationPhaseDetected':
            state.stateEstimate.accelerationPhaseDetected,
        'feedbackCooldownActive': state.stateEstimate.feedbackCooldownActive,
      },
      'features': <String, Object?>{
        'trunkAngleDegrees': state.features.trunkAngleDegrees?.toStringAsFixed(
          2,
        ),
        'kneeDriveHeight': state.features.kneeDriveHeightRatio?.toStringAsFixed(
          3,
        ),
        'cadenceStepsPerMinute': state.features.cadenceStepsPerMinute
            ?.toStringAsFixed(2),
        'stepIntervalMs': state.features.stepInterval?.inMilliseconds,
        'stepIntervalStdMs': state.features.stepIntervalStdMs?.toStringAsFixed(
          2,
        ),
        'armAsymmetryRatio': state.features.armSwingAsymmetryRatio
            ?.toStringAsFixed(3),
      },
      'stepDetector': <String, Object?>{
        'leadSwitches': state.features.stepCrossoverCount,
        'acceptedEvents': state.features.detectedStepEvents,
        'rejectedLowVelocity': state.features.rejectedStepEventsLowVelocity,
        'rejectedMinInterval': state.features.rejectedStepEventsMinInterval,
      },
      'feedback': <String, Object?>{
        'key': state.activeFeedbackKey,
        'text': feedbackText,
        'suppressedByCooldown': state.feedbackSwitchSuppressedByCooldown,
      },
      'metrics': <String, Object?>{
        'cameraInputFps': snapshot.cameraInputFps.toStringAsFixed(2),
        'analyzedFps': snapshot.analyzedFps.toStringAsFixed(2),
        'averageProcessingTimeMs': snapshot.averageProcessingTimeMs
            .toStringAsFixed(2),
        'skippedFrames': <String, Object?>{
          'total': snapshot.skippedFrames,
          'busy': snapshot.busySkippedFrames,
          'throttled': snapshot.throttledSkippedFrames,
          'invalidInput': snapshot.invalidInputFrames,
          'analysisError': snapshot.analysisErrorFrames,
        },
        'bodyNotVisibleRatio': snapshot.bodyNotVisibleRatio.toStringAsFixed(3),
        'feedbackChanges': <String, Object?>{
          'count': snapshot.feedbackChangeCount,
          'perMinute': snapshot.feedbackChangesPerMinute.toStringAsFixed(2),
          'suppressedByCooldown': snapshot.feedbackSuppressedByCooldownCount,
        },
      },
      'landmarkConfidenceDistribution': <String, Object?>{
        for (
          var index = 0;
          index < sprintConfidenceBucketLabels.length;
          index += 1
        )
          sprintConfidenceBucketLabels[index]:
              snapshot.confidenceBucketCounts[index],
      },
      if (details != null && details.isNotEmpty) 'details': details,
    };
  }

  void _ensureStarted(DateTime timestamp) {
    _startedAt ??= timestamp;
  }

  int _bucketIndex(double confidence) {
    if (confidence < 0.2) {
      return 0;
    }
    if (confidence < 0.4) {
      return 1;
    }
    if (confidence < 0.6) {
      return 2;
    }
    if (confidence < 0.8) {
      return 3;
    }
    return 4;
  }
}
