import '../domain/entities/running_live_coaching_state.dart';
import 'running_live_session_metrics.dart';

enum RunningLiveRuntimeReadinessStatus {
  ready,
  stabilizing,
  fixSetup,
}

enum RunningLiveRuntimeReadinessReason {
  warmingUp,
  slowProcessing,
  frameGaps,
  unstableTracking,
  setup,
  noRunner,
}

class RunningLiveRuntimeReadiness {
  final RunningLiveRuntimeReadinessStatus status;
  final RunningLiveRuntimeReadinessReason reason;

  const RunningLiveRuntimeReadiness({
    required this.status,
    required this.reason,
  });

  const RunningLiveRuntimeReadiness.initial()
      : status = RunningLiveRuntimeReadinessStatus.stabilizing,
        reason = RunningLiveRuntimeReadinessReason.warmingUp;

  bool get canEmitFormCoaching =>
      status == RunningLiveRuntimeReadinessStatus.ready;
}

class RunningLiveRuntimeQualityGate {
  final int minimumAnalyzedFrames;
  final int minimumIntervalSamples;
  final int minimumTrackedFrames;
  final double maximumProcessingP95Ms;
  final double maximumFrameIntervalP95Ms;
  final double minimumAverageTimingConfidence;
  final double minimumAverageSideViewConfidence;

  const RunningLiveRuntimeQualityGate({
    this.minimumAnalyzedFrames = 6,
    this.minimumIntervalSamples = 4,
    this.minimumTrackedFrames = 6,
    this.maximumProcessingP95Ms = 160,
    this.maximumFrameIntervalP95Ms = 170,
    this.minimumAverageTimingConfidence = 0.45,
    this.minimumAverageSideViewConfidence = 0.45,
  });

  RunningLiveRuntimeReadiness evaluate({
    required RunningLiveSessionMetricsSnapshot snapshot,
    required RunningLiveCoachingState state,
  }) {
    final framingIssue = state.framingIssue;
    if (framingIssue == RunningLiveFramingIssue.noRunnerDetected) {
      return const RunningLiveRuntimeReadiness(
        status: RunningLiveRuntimeReadinessStatus.fixSetup,
        reason: RunningLiveRuntimeReadinessReason.noRunner,
      );
    }
    if (framingIssue != null &&
        framingIssue != RunningLiveFramingIssue.trackingUncertain) {
      return const RunningLiveRuntimeReadiness(
        status: RunningLiveRuntimeReadinessStatus.fixSetup,
        reason: RunningLiveRuntimeReadinessReason.setup,
      );
    }
    if (framingIssue == RunningLiveFramingIssue.trackingUncertain) {
      return const RunningLiveRuntimeReadiness(
        status: RunningLiveRuntimeReadinessStatus.stabilizing,
        reason: RunningLiveRuntimeReadinessReason.unstableTracking,
      );
    }

    if (snapshot.analyzedFrames < minimumAnalyzedFrames ||
        snapshot.analyzedFrameIntervalSampleCount < minimumIntervalSamples ||
        state.trackedFrames < minimumTrackedFrames) {
      return const RunningLiveRuntimeReadiness.initial();
    }

    if (snapshot.processingLatencySampleCount >= minimumIntervalSamples &&
        snapshot.processingLatencyP95Ms > maximumProcessingP95Ms) {
      return const RunningLiveRuntimeReadiness(
        status: RunningLiveRuntimeReadinessStatus.stabilizing,
        reason: RunningLiveRuntimeReadinessReason.slowProcessing,
      );
    }

    if (snapshot.analyzedFrameIntervalP95Ms > maximumFrameIntervalP95Ms) {
      return const RunningLiveRuntimeReadiness(
        status: RunningLiveRuntimeReadinessStatus.stabilizing,
        reason: RunningLiveRuntimeReadinessReason.frameGaps,
      );
    }

    if (snapshot.averageTimingConfidence < minimumAverageTimingConfidence ||
        snapshot.averageSideViewConfidence < minimumAverageSideViewConfidence) {
      return const RunningLiveRuntimeReadiness(
        status: RunningLiveRuntimeReadinessStatus.stabilizing,
        reason: RunningLiveRuntimeReadinessReason.unstableTracking,
      );
    }

    return const RunningLiveRuntimeReadiness(
      status: RunningLiveRuntimeReadinessStatus.ready,
      reason: RunningLiveRuntimeReadinessReason.warmingUp,
    );
  }
}
