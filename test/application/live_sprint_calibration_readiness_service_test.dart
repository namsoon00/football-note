import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/live_sprint_calibration_readiness_service.dart';
import 'package:football_note/domain/entities/running_coach_session.dart';
import 'package:football_note/domain/entities/running_live_coaching_state.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';
import 'package:football_note/domain/entities/sprint_capture_calibration_profile.dart';
import 'package:football_note/domain/entities/sprint_realtime_coaching_state.dart';

void main() {
  const service = LiveSprintCalibrationReadinessService();

  test('marks three stable same-profile field-ready sessions as ready', () {
    final summary = service.build(
      <RunningCoachSessionAnalysis>[
        _session(id: 'current', at: DateTime(2026, 7, 21)),
        _session(id: 'baseline-2', at: DateTime(2026, 7, 20)),
        _session(id: 'baseline-1', at: DateTime(2026, 7, 19)),
      ],
      currentSessionId: 'current',
    );

    expect(
      summary.status,
      LiveSprintCalibrationReadinessStatus.readyForThresholdCalibration,
    );
    expect(
        summary.calibrationProfile, SprintCaptureCalibrationProfile.balanced);
    expect(summary.liveSessionCount, 3);
    expect(summary.sameProfileSessionCount, 3);
    expect(summary.readySessionCount, 3);
    expect(summary.score, greaterThanOrEqualTo(95));
    expect(summary.blockers, isEmpty);
  });

  test('requires more same-profile sessions at or before the current one', () {
    final summary = service.build(
      <RunningCoachSessionAnalysis>[
        _session(id: 'future-same-profile', at: DateTime(2026, 7, 22)),
        _session(id: 'current', at: DateTime(2026, 7, 21)),
        _session(id: 'baseline', at: DateTime(2026, 7, 20)),
        _session(
          id: 'mixed-profile',
          at: DateTime(2026, 7, 19),
          profile: SprintCaptureCalibrationProfile.responsive,
        ),
      ],
      currentSessionId: 'current',
    );

    expect(
      summary.status,
      LiveSprintCalibrationReadinessStatus.needsMoreSameProfileSessions,
    );
    expect(summary.liveSessionCount, 4);
    expect(summary.sameProfileSessionCount, 2);
    expect(summary.readySessionCount, 2);
    expect(summary.additionalReadySessionsNeeded, 1);
    expect(summary.blockers.single.kind,
        LiveSprintCalibrationReadinessCheckKind.sameProfileReadySessions);
  });

  test('excludes mixed profiles from repeatability variation', () {
    final summary = service.build(
      <RunningCoachSessionAnalysis>[
        _session(id: 'current', at: DateTime(2026, 7, 21)),
        _session(id: 'baseline-2', at: DateTime(2026, 7, 20)),
        _session(id: 'baseline-1', at: DateTime(2026, 7, 19)),
        _session(
          id: 'responsive-outlier',
          at: DateTime(2026, 7, 18),
          profile: SprintCaptureCalibrationProfile.responsive,
          timingConfidence: 0.75,
          sideViewConfidence: 0.96,
          trackingConfidence: 0.76,
          sprintTrackedFrames: 48,
          sprintAnalyzedFrames: 96,
          eligibleFrames: 12,
          evaluatedFrames: 60,
          landingEvents: 4,
          detectedSteps: 9,
        ),
      ],
      currentSessionId: 'current',
    );

    expect(
      summary.status,
      LiveSprintCalibrationReadinessStatus.readyForThresholdCalibration,
    );
    expect(summary.liveSessionCount, 4);
    expect(summary.sameProfileSessionCount, 3);
    expect(summary.readySessionCount, 3);
    expect(summary.blockers, isEmpty);
  });

  test('requires review when same-profile ready sessions vary too much', () {
    final summary = service.build(
      <RunningCoachSessionAnalysis>[
        _session(id: 'current', at: DateTime(2026, 7, 21)),
        _session(id: 'baseline-2', at: DateTime(2026, 7, 20)),
        _session(
          id: 'baseline-outlier',
          at: DateTime(2026, 7, 19),
          timingConfidence: 0.75,
        ),
      ],
      currentSessionId: 'current',
    );

    expect(
      summary.status,
      LiveSprintCalibrationReadinessStatus.needsVariationReview,
    );
    expect(
      summary.blockers.map((check) => check.kind),
      contains(
        LiveSprintCalibrationReadinessCheckKind.timingConfidenceVariation,
      ),
    );
  });

  test('handles old serialized reports without calibration diagnostics safely',
      () {
    final sessionMap = _session(
      id: 'legacy-current',
      at: DateTime(2026, 7, 21),
    ).toMap();
    final reportMap = sessionMap['liveSprintReport']! as Map<String, Object?>;
    reportMap.remove('calibrationProfile');
    reportMap.remove('poseEvidenceDiagnostic');

    final restored = RunningCoachSessionAnalysis.fromMap(
      Map<String, dynamic>.from(sessionMap),
    );
    final summary = service.build(
      <RunningCoachSessionAnalysis>[
        restored,
        _session(id: 'baseline-2', at: DateTime(2026, 7, 20)),
        _session(id: 'baseline-1', at: DateTime(2026, 7, 19)),
      ],
      currentSessionId: restored.id,
    );

    expect(
      restored.liveSprintReport!.calibrationProfile,
      SprintCaptureCalibrationProfile.balanced,
    );
    expect(
      summary.status,
      LiveSprintCalibrationReadinessStatus.currentCaptureNotReady,
    );
    expect(
        summary.calibrationProfile, SprintCaptureCalibrationProfile.balanced);
    expect(summary.blockers.first.kind,
        LiveSprintCalibrationReadinessCheckKind.currentFieldValidation);
  });
}

RunningCoachSessionAnalysis _session({
  required String id,
  required DateTime at,
  SprintCaptureCalibrationProfile profile =
      SprintCaptureCalibrationProfile.balanced,
  int sprintTrackedFrames = 72,
  int sprintAnalyzedFrames = 72,
  int detectedSteps = 8,
  int landingEvents = 8,
  double timingConfidence = 0.88,
  double sideViewConfidence = 0.86,
  double trackingConfidence = 0.87,
  int eligibleFrames = 24,
  int evaluatedFrames = 30,
}) {
  return RunningCoachSessionAnalysis(
    id: id,
    analyzedAt: at,
    source: RunningCoachSessionSource.sprintLive,
    overallScore: 82,
    duration: const Duration(seconds: 16),
    sampledFrames: 180,
    validFrames: 160,
    primaryMetric: RunningCoachMetric.footStrike,
    primaryFinding: RunningCoachFinding.footStrikeUnderBody,
    primaryStatus: RunningCoachStatus.good,
    primaryScore: 82,
    primaryValue: 0.18,
    primaryConfidence: 0.86,
    liveSprintReport: LiveSprintSessionReport(
      calibrationProfile: profile,
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
      bodyNotVisibleRatio: 0.04,
      status: SprintCoachingStatus.coaching,
      trackingReadiness: SprintTrackingReadiness.readyForAnalysis,
      feedbackCode: null,
      feedbackSeverity: null,
      feedbackConfidence: 0,
      metrics: const <LiveSprintMetricSummary>[
        LiveSprintMetricSummary(
          kind: LiveSprintMetricKind.landing,
          value: 0.20,
          secondaryValue: 66,
          confidence: 0.86,
          sampleCount: 8,
        ),
      ],
      poseEvidence: _poseEvidence(),
      poseEvidenceDiagnostic: _diagnostic(
        eligibleFrames: eligibleFrames,
        evaluatedFrames: evaluatedFrames,
      ),
    ),
  );
}

LiveSprintPoseEvidenceDiagnostic _diagnostic({
  required int eligibleFrames,
  required int evaluatedFrames,
}) {
  return LiveSprintPoseEvidenceDiagnostic(
    evaluatedFrames: evaluatedFrames,
    eligibleFrames: eligibleFrames,
    capturedPhaseCount: 3,
    fullBodyBlockedFrames: 0,
    sideViewBlockedFrames: 0,
    coreJointsBlockedFrames: 0,
    gaitPhaseBlockedFrames: 0,
    currentBlocker: null,
    readinessSummary: const LiveSprintCaptureReadinessSummary(
      framing: LiveSprintCaptureReadinessCheck(
        ready: true,
        value: 1,
        threshold: 1,
      ),
      sideView: LiveSprintCaptureReadinessCheck(
        ready: true,
        value: 0.86,
        threshold: 0.65,
      ),
      coreJointConfidence: LiveSprintCaptureReadinessCheck(
        ready: true,
        value: 0.88,
        threshold: 0.70,
        observedCount: 15,
        requiredCount: 15,
      ),
      gaitPhase: LiveSprintCaptureReadinessCheck(
        ready: true,
        value: 0.86,
        threshold: 0.62,
      ),
    ),
  );
}

List<LiveSprintPoseEvidenceFrame> _poseEvidence() {
  return <LiveSprintPoseEvidenceFrame>[
    for (final phase in LiveSprintPoseEvidencePhase.values)
      LiveSprintPoseEvidenceFrame(
        phase: phase,
        capturedOffsetMs: 1400 + (phase.index * 260),
        quality: 0.86,
        sideViewConfidence: 0.86,
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
