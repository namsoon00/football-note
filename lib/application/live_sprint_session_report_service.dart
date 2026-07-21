import '../domain/entities/running_coach_session.dart';
import '../domain/entities/running_live_coaching_state.dart';
import '../domain/entities/sprint_capture_calibration_profile.dart';
import '../domain/entities/running_video_analysis_result.dart';
import '../domain/entities/sprint_realtime_coaching_state.dart';
import 'running_live_session_metrics.dart';
import 'sprint_live_session_metrics.dart';

class LiveSprintSessionReportService {
  const LiveSprintSessionReportService();

  RunningCoachSessionAnalysis buildSession({
    required String sessionId,
    required DateTime completedAt,
    required RunningLiveSessionMetricsSnapshot runningSnapshot,
    required SprintLiveSessionMetricsSnapshot sprintSnapshot,
    required RunningLiveCoachingState runningState,
    required SprintRealtimeCoachingState sprintState,
    SprintCaptureCalibrationProfile calibrationProfile =
        SprintCaptureCalibrationProfile.balanced,
    List<LiveSprintPoseEvidenceFrame> poseEvidence =
        const <LiveSprintPoseEvidenceFrame>[],
    LiveSprintPoseEvidenceDiagnostic poseEvidenceDiagnostic =
        const LiveSprintPoseEvidenceDiagnostic.initial(),
  }) {
    final runningReport = runningState.coachingReport;
    final insights =
        runningReport?.rankedInsights ?? const <RunningCoachingInsight>[];
    final primary = runningReport?.primaryFocus ??
        (insights.isNotEmpty ? insights.first : _fallbackPrimaryInsight);
    final analyzedFrames = runningSnapshot.analyzedFrames;
    final validFrames = runningState.trackedFrames.clamp(0, analyzedFrames);

    return RunningCoachSessionAnalysis(
      id: sessionId,
      analyzedAt: completedAt,
      source: RunningCoachSessionSource.sprintLive,
      overallScore: runningReport?.overallScore ?? 0,
      duration: runningSnapshot.elapsed,
      sampledFrames: analyzedFrames,
      validFrames: validFrames,
      primaryMetric: primary.metric,
      primaryFinding: primary.finding,
      primaryStatus: primary.status,
      primaryScore: primary.score,
      primaryValue: primary.value,
      primaryConfidence: primary.quality.confidence,
      metricSnapshots: insights
          .map(RunningCoachSessionMetric.fromInsight)
          .toList(growable: false),
      liveSprintReport: _buildLiveReport(
        runningSnapshot: runningSnapshot,
        sprintSnapshot: sprintSnapshot,
        runningState: runningState,
        sprintState: sprintState,
        calibrationProfile: calibrationProfile,
        poseEvidence: poseEvidence,
        poseEvidenceDiagnostic: poseEvidenceDiagnostic,
      ),
    );
  }

  LiveSprintSessionReport _buildLiveReport({
    required RunningLiveSessionMetricsSnapshot runningSnapshot,
    required SprintLiveSessionMetricsSnapshot sprintSnapshot,
    required RunningLiveCoachingState runningState,
    required SprintRealtimeCoachingState sprintState,
    required SprintCaptureCalibrationProfile calibrationProfile,
    required List<LiveSprintPoseEvidenceFrame> poseEvidence,
    required LiveSprintPoseEvidenceDiagnostic poseEvidenceDiagnostic,
  }) {
    final features = sprintState.features;
    final feedback = sprintState.feedback;
    final actionableFeedback =
        feedback?.severity == SprintFeedbackSeverity.info ? null : feedback;
    return LiveSprintSessionReport(
      calibrationProfile: calibrationProfile,
      runningTrackedFrames: runningState.trackedFrames,
      runningAnalyzedFrames: runningSnapshot.analyzedFrames,
      sprintTrackedFrames: sprintState.trackedFrames,
      sprintAnalyzedFrames: sprintSnapshot.analyzedFrames,
      touchdownEvents: runningSnapshot.touchdownEvents,
      toeOffEvents: runningSnapshot.toeOffEvents,
      detectedSteps: features.detectedStepEvents,
      landingEvents: features.landingEventCount,
      feedbackChanges: sprintSnapshot.feedbackChangeCount,
      timingConfidence: runningSnapshot.averageTimingConfidence,
      sideViewConfidence: runningSnapshot.averageSideViewConfidence,
      sprintTrackingConfidence: sprintState.stateEstimate.trackingConfidence,
      bodyNotVisibleRatio: sprintSnapshot.bodyNotVisibleRatio,
      status: sprintState.status,
      trackingReadiness: sprintState.stateEstimate.trackingReadiness,
      feedbackCode: actionableFeedback?.code,
      feedbackSeverity: actionableFeedback?.severity,
      feedbackConfidence: actionableFeedback?.confidence ?? 0,
      poseEvidence: poseEvidence,
      poseEvidenceDiagnostic: poseEvidenceDiagnostic,
      metrics: <LiveSprintMetricSummary>[
        _metric(LiveSprintMetricKind.trunkAngle, features.trunkAngle),
        _metric(LiveSprintMetricKind.kneeDrive, features.kneeDrive),
        _metric(LiveSprintMetricKind.cadence, features.cadence),
        _metric(LiveSprintMetricKind.rhythm, features.rhythm),
        _metric(LiveSprintMetricKind.armBalance, features.armBalance),
        _metric(
          LiveSprintMetricKind.landing,
          features.overstride,
          secondary: features.shinAngle.value,
        ),
        _metric(LiveSprintMetricKind.flightRatio, features.flightRatio),
        _metric(LiveSprintMetricKind.lateForm, features.lateFormDrop),
      ],
    );
  }

  LiveSprintMetricSummary _metric(
    LiveSprintMetricKind kind,
    SprintMeasuredValue measured, {
    double? secondary,
  }) {
    return LiveSprintMetricSummary(
      kind: kind,
      value: measured.value,
      secondaryValue: secondary,
      confidence: measured.confidence,
      sampleCount: measured.sampleCount,
    );
  }

  static const _fallbackPrimaryInsight = RunningCoachingInsight(
    metric: RunningCoachMetric.posture,
    finding: RunningCoachFinding.postureAligned,
    status: RunningCoachStatus.watch,
    score: 0,
    value: 0,
    quality: RunningMetricQuality(confidence: 0, sampleCount: 0),
  );
}
