import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/live_sprint_field_validation_service.dart';
import 'package:football_note/domain/entities/running_coach_session.dart';
import 'package:football_note/domain/entities/running_live_coaching_state.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';
import 'package:football_note/domain/entities/sprint_capture_calibration_profile.dart';
import 'package:football_note/domain/entities/sprint_realtime_coaching_state.dart';

void main() {
  const service = LiveSprintFieldValidationService();

  test('classifies complete field evidence as ready for calibration', () {
    final summary = service.build(_report());

    expect(
      summary.status,
      LiveSprintFieldValidationStatus.readyForCalibration,
    );
    expect(
      summary.calibrationProfile,
      SprintCaptureCalibrationProfile.responsive,
    );
    expect(summary.qualityScore, 96);
    expect(summary.blockers, isEmpty);
    expect(summary.nextCaptureChecks, isEmpty);
  });

  test('classifies partial but usable field evidence as needing review', () {
    final summary = service.build(
      _report(
        sprintTrackedFrames: 30,
        detectedSteps: 4,
        landingEvents: 2,
        timingConfidence: 0.66,
        sideViewConfidence: 0.66,
        trackingConfidence: 0.66,
        bodyNotVisibleRatio: 0.18,
        poseEvidence: _evidencePhases(
          <LiveSprintPoseEvidencePhase>[
            LiveSprintPoseEvidencePhase.touchdown,
            LiveSprintPoseEvidencePhase.support,
          ],
        ),
        diagnostic: _diagnostic(
          capturedPhaseCount: 2,
          eligibleFrames: 8,
        ),
      ),
    );

    expect(summary.status, LiveSprintFieldValidationStatus.needsReview);
    expect(summary.qualityScore, 73);
    expect(
      summary.nextCaptureChecks.map((check) => check.kind),
      <LiveSprintFieldValidationCheckKind>[
        LiveSprintFieldValidationCheckKind.phaseCoverage,
        LiveSprintFieldValidationCheckKind.trackedFrames,
        LiveSprintFieldValidationCheckKind.usablePoseSamples,
      ],
    );
  });

  test('classifies unstable field captures as insufficient', () {
    final summary = service.build(
      _report(
        sprintTrackedFrames: 3,
        detectedSteps: 0,
        landingEvents: 0,
        timingConfidence: 0.2,
        sideViewConfidence: 0.2,
        trackingConfidence: 0.2,
        bodyNotVisibleRatio: 0.7,
        poseEvidence: const <LiveSprintPoseEvidenceFrame>[],
        diagnostic: _diagnostic(
          capturedPhaseCount: 0,
          eligibleFrames: 0,
          readiness: _readiness(readyCount: 0),
        ),
      ),
    );

    expect(summary.status, LiveSprintFieldValidationStatus.insufficient);
    expect(summary.qualityScore, 7);
    expect(
      summary.nextCaptureChecks.map((check) => check.kind),
      <LiveSprintFieldValidationCheckKind>[
        LiveSprintFieldValidationCheckKind.captureReadiness,
        LiveSprintFieldValidationCheckKind.phaseCoverage,
        LiveSprintFieldValidationCheckKind.trackedFrames,
      ],
    );
  });

  test('derives a safe summary from older serialized sessions', () {
    final sessionMap = _session(_report()).toMap();
    final reportMap = sessionMap['liveSprintReport']! as Map<String, Object?>;
    reportMap.remove('calibrationProfile');
    reportMap.remove('poseEvidenceDiagnostic');

    final restored = RunningCoachSessionAnalysis.fromMap(
      Map<String, dynamic>.from(sessionMap),
    );
    final summary = service.build(restored.liveSprintReport!);

    expect(
      restored.liveSprintReport!.calibrationProfile,
      SprintCaptureCalibrationProfile.balanced,
    );
    expect(summary.status, LiveSprintFieldValidationStatus.insufficient);
    expect(
      summary.blockers.map((check) => check.kind),
      contains(LiveSprintFieldValidationCheckKind.usablePoseSamples),
    );
  });
}

RunningCoachSessionAnalysis _session(LiveSprintSessionReport report) {
  return RunningCoachSessionAnalysis(
    id: 'field-validation',
    analyzedAt: DateTime(2026, 7, 21, 10, 30),
    source: RunningCoachSessionSource.sprintLive,
    overallScore: 76,
    duration: const Duration(seconds: 12),
    sampledFrames: 180,
    validFrames: 160,
    primaryMetric: RunningCoachMetric.footStrike,
    primaryFinding: RunningCoachFinding.footStrikeOverstride,
    primaryStatus: RunningCoachStatus.needsWork,
    primaryScore: 58,
    primaryValue: 0.24,
    primaryConfidence: 0.82,
    liveSprintReport: report,
  );
}

LiveSprintSessionReport _report({
  SprintCaptureCalibrationProfile calibrationProfile =
      SprintCaptureCalibrationProfile.responsive,
  int sprintTrackedFrames = 60,
  int sprintAnalyzedFrames = 72,
  int detectedSteps = 8,
  int landingEvents = 6,
  double timingConfidence = 0.84,
  double sideViewConfidence = 0.80,
  double trackingConfidence = 0.82,
  double bodyNotVisibleRatio = 0.05,
  List<LiveSprintPoseEvidenceFrame>? poseEvidence,
  LiveSprintPoseEvidenceDiagnostic? diagnostic,
}) {
  return LiveSprintSessionReport(
    calibrationProfile: calibrationProfile,
    runningTrackedFrames: 160,
    runningAnalyzedFrames: 180,
    sprintTrackedFrames: sprintTrackedFrames,
    sprintAnalyzedFrames: sprintAnalyzedFrames,
    touchdownEvents: detectedSteps,
    toeOffEvents: detectedSteps,
    detectedSteps: detectedSteps,
    landingEvents: landingEvents,
    feedbackChanges: 1,
    timingConfidence: timingConfidence,
    sideViewConfidence: sideViewConfidence,
    sprintTrackingConfidence: trackingConfidence,
    bodyNotVisibleRatio: bodyNotVisibleRatio,
    status: SprintCoachingStatus.coaching,
    trackingReadiness: SprintTrackingReadiness.readyForAnalysis,
    feedbackCode: null,
    feedbackSeverity: null,
    feedbackConfidence: 0,
    metrics: const <LiveSprintMetricSummary>[
      LiveSprintMetricSummary(
        kind: LiveSprintMetricKind.landing,
        value: 0.22,
        secondaryValue: 68,
        confidence: 0.82,
        sampleCount: 6,
      ),
    ],
    poseEvidence: poseEvidence ??
        _evidencePhases(
          LiveSprintPoseEvidencePhase.values,
        ),
    poseEvidenceDiagnostic: diagnostic ?? _diagnostic(),
  );
}

LiveSprintPoseEvidenceDiagnostic _diagnostic({
  int capturedPhaseCount = 3,
  int eligibleFrames = 16,
  LiveSprintCaptureReadinessSummary? readiness,
}) {
  return LiveSprintPoseEvidenceDiagnostic(
    evaluatedFrames: 24,
    eligibleFrames: eligibleFrames,
    capturedPhaseCount: capturedPhaseCount,
    fullBodyBlockedFrames: 0,
    sideViewBlockedFrames: 0,
    coreJointsBlockedFrames: 0,
    gaitPhaseBlockedFrames: 0,
    currentBlocker: null,
    readinessSummary: readiness ?? _readiness(),
  );
}

LiveSprintCaptureReadinessSummary _readiness({int readyCount = 4}) {
  return LiveSprintCaptureReadinessSummary(
    framing: LiveSprintCaptureReadinessCheck(
      ready: readyCount > 0,
      value: readyCount > 0 ? 1 : 0.25,
      threshold: 1,
    ),
    sideView: LiveSprintCaptureReadinessCheck(
      ready: readyCount > 1,
      value: readyCount > 1 ? 0.82 : 0.3,
      threshold: 0.65,
    ),
    coreJointConfidence: LiveSprintCaptureReadinessCheck(
      ready: readyCount > 2,
      value: readyCount > 2 ? 0.84 : 0.3,
      threshold: 0.70,
      observedCount: readyCount > 2 ? 15 : 4,
      requiredCount: 15,
    ),
    gaitPhase: LiveSprintCaptureReadinessCheck(
      ready: readyCount > 3,
      value: readyCount > 3 ? 0.82 : 0.3,
      threshold: 0.62,
    ),
  );
}

List<LiveSprintPoseEvidenceFrame> _evidencePhases(
  Iterable<LiveSprintPoseEvidencePhase> phases,
) {
  return <LiveSprintPoseEvidenceFrame>[
    for (final phase in phases)
      LiveSprintPoseEvidenceFrame(
        phase: phase,
        capturedOffsetMs: 1200 + (phase.index * 250),
        quality: 0.84,
        sideViewConfidence: 0.80,
        imageAspectRatio: 0.5625,
        leadFoot: phase == LiveSprintPoseEvidencePhase.touchdown
            ? RunningFootSide.left
            : null,
        joints: const <LiveSprintPoseEvidenceJoint>[
          LiveSprintPoseEvidenceJoint(
            type: RunningPoseLandmarkType.leftHip,
            x: 0.45,
            y: 0.5,
            z: 0,
            confidence: 0.9,
            observed: true,
          ),
        ],
      ),
  ];
}
