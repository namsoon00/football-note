import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/live_sprint_capture_context_service.dart';
import 'package:football_note/application/live_sprint_field_validation_matrix_service.dart';
import 'package:football_note/domain/entities/running_coach_session.dart';
import 'package:football_note/domain/entities/running_live_coaching_state.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';
import 'package:football_note/domain/entities/sprint_capture_calibration_profile.dart';
import 'package:football_note/domain/entities/sprint_realtime_coaching_state.dart';

void main() {
  const service = LiveSprintFieldValidationMatrixService();

  test('reports recommendation coverage only after baseline and variation', () {
    final current = _session(
      id: 'current',
      at: DateTime(2026, 7, 21),
      context: _context(
        distanceBand: LiveSprintCaptureDistanceBand.close,
      ),
    );
    final summary = service.build(
      <RunningCoachSessionAnalysis>[
        current,
        _session(
          id: 'baseline',
          at: DateTime(2026, 7, 20),
          context: _context(),
        ),
        _session(
          id: 'unknown-legacy',
          at: DateTime(2026, 7, 19),
          context: const LiveSprintCaptureContext.unknown(),
        ),
      ],
      currentSessionId: 'current',
    );

    expect(
      summary.status,
      LiveSprintFieldValidationMatrixStatus.recommendationCoverageReady,
    );
    expect(summary.hasBaselineCoverage, isTrue);
    expect(summary.hasMeaningfulGeometryVariation, isTrue);
    expect(summary.isRecommendationCoverageReady, isTrue);
    expect(summary.isMatrixComplete, isFalse);
    expect(summary.coveredScenarioCount, 2);
    expect(summary.unknownContextSessionCount, 1);
    expect(
      summary.missingScenarios,
      contains(
        LiveSprintFieldValidationMatrixScenario.rearPhoneFarClearSide,
      ),
    );
  });

  test('does not let unknown legacy context satisfy baseline coverage', () {
    final summary = service.build(
      <RunningCoachSessionAnalysis>[
        _session(
          id: 'current',
          at: DateTime(2026, 7, 21),
          context: const LiveSprintCaptureContext.unknown(),
        ),
        _session(
          id: 'legacy-2',
          at: DateTime(2026, 7, 20),
          context: const LiveSprintCaptureContext.unknown(),
        ),
      ],
      currentSessionId: 'current',
    );

    expect(summary.status, LiveSprintFieldValidationMatrixStatus.notReady);
    expect(summary.coveredScenarioCount, 0);
    expect(summary.unknownContextSessionCount, 2);
    expect(summary.hasBaselineCoverage, isFalse);
  });

  test('marks the matrix complete only when all required scenarios exist', () {
    final summary = service.build(
      <RunningCoachSessionAnalysis>[
        _session(
          id: 'current',
          at: DateTime(2026, 7, 21),
          context: _context(
            distanceBand: LiveSprintCaptureDistanceBand.normal,
            viewBand: LiveSprintViewBand.partialSide,
          ),
        ),
        _session(
          id: 'close',
          at: DateTime(2026, 7, 20),
          context: _context(
            distanceBand: LiveSprintCaptureDistanceBand.close,
          ),
        ),
        _session(
          id: 'far',
          at: DateTime(2026, 7, 19),
          context: _context(
            distanceBand: LiveSprintCaptureDistanceBand.far,
          ),
        ),
        _session(
          id: 'baseline',
          at: DateTime(2026, 7, 18),
          context: _context(),
        ),
      ],
      currentSessionId: 'current',
    );

    expect(
        summary.status, LiveSprintFieldValidationMatrixStatus.matrixComplete);
    expect(summary.isMatrixComplete, isTrue);
    expect(summary.coverageScore, 100);
    expect(summary.missingScenarios, isEmpty);
  });

  test('derives coarse context from pose summaries without device identifiers',
      () {
    final context = const LiveSprintCaptureContextService().build(
      deviceClass:
          LiveSprintCaptureContextService.deviceClassForShortestSide(390),
      cameraLensDirection: LiveSprintCameraLensDirection.rear,
      poseEvidence: _poseEvidence(bodyHeight: 0.56),
      poseEvidenceDiagnostic: _diagnostic(sideViewValue: 0.84),
    );

    expect(context.deviceClass, LiveSprintDeviceClass.phone);
    expect(context.cameraLensDirection, LiveSprintCameraLensDirection.rear);
    expect(context.distanceBand, LiveSprintCaptureDistanceBand.normal);
    expect(context.viewBand, LiveSprintViewBand.clearSide);
    expect(context.toMap(), isNot(contains('cameraModel')));
  });
}

RunningCoachSessionAnalysis _session({
  required String id,
  required DateTime at,
  required LiveSprintCaptureContext context,
  SprintCaptureCalibrationProfile profile =
      SprintCaptureCalibrationProfile.balanced,
}) {
  return RunningCoachSessionAnalysis(
    id: id,
    analyzedAt: at,
    source: RunningCoachSessionSource.sprintLive,
    overallScore: 84,
    duration: const Duration(seconds: 16),
    sampledFrames: 180,
    validFrames: 160,
    primaryMetric: RunningCoachMetric.footStrike,
    primaryFinding: RunningCoachFinding.footStrikeUnderBody,
    primaryStatus: RunningCoachStatus.good,
    primaryScore: 84,
    primaryValue: 0.18,
    primaryConfidence: 0.9,
    liveSprintReport: _report(profile: profile, context: context),
  );
}

LiveSprintSessionReport _report({
  required SprintCaptureCalibrationProfile profile,
  required LiveSprintCaptureContext context,
}) {
  return LiveSprintSessionReport(
    calibrationProfile: profile,
    runningTrackedFrames: 160,
    runningAnalyzedFrames: 180,
    sprintTrackedFrames: 72,
    sprintAnalyzedFrames: 72,
    touchdownEvents: 8,
    toeOffEvents: 8,
    detectedSteps: 8,
    landingEvents: 8,
    feedbackChanges: 1,
    timingConfidence: 0.88,
    sideViewConfidence: 0.86,
    sprintTrackingConfidence: 0.88,
    bodyNotVisibleRatio: 0.04,
    status: SprintCoachingStatus.coaching,
    trackingReadiness: SprintTrackingReadiness.readyForAnalysis,
    feedbackCode: null,
    feedbackSeverity: null,
    feedbackConfidence: 0,
    metrics: const <LiveSprintMetricSummary>[],
    poseEvidence: _poseEvidence(bodyHeight: 0.56),
    poseEvidenceDiagnostic: _diagnostic(sideViewValue: 0.86),
    captureContext: context,
  );
}

LiveSprintCaptureContext _context({
  LiveSprintCaptureDistanceBand distanceBand =
      LiveSprintCaptureDistanceBand.normal,
  LiveSprintViewBand viewBand = LiveSprintViewBand.clearSide,
}) {
  return LiveSprintCaptureContext(
    deviceClass: LiveSprintDeviceClass.phone,
    cameraLensDirection: LiveSprintCameraLensDirection.rear,
    distanceBand: distanceBand,
    viewBand: viewBand,
  );
}

LiveSprintPoseEvidenceDiagnostic _diagnostic({
  required double sideViewValue,
}) {
  return LiveSprintPoseEvidenceDiagnostic(
    evaluatedFrames: 30,
    eligibleFrames: 24,
    capturedPhaseCount: 3,
    fullBodyBlockedFrames: 0,
    sideViewBlockedFrames: 0,
    coreJointsBlockedFrames: 0,
    gaitPhaseBlockedFrames: 0,
    currentBlocker: null,
    readinessSummary: LiveSprintCaptureReadinessSummary(
      framing: const LiveSprintCaptureReadinessCheck(
        ready: true,
        value: 1,
        threshold: 1,
      ),
      sideView: LiveSprintCaptureReadinessCheck(
        ready: true,
        value: sideViewValue,
        threshold: 0.65,
      ),
      coreJointConfidence: const LiveSprintCaptureReadinessCheck(
        ready: true,
        value: 0.90,
        threshold: 0.70,
        observedCount: 15,
        requiredCount: 15,
      ),
      gaitPhase: const LiveSprintCaptureReadinessCheck(
        ready: true,
        value: 0.88,
        threshold: 0.62,
      ),
    ),
  );
}

List<LiveSprintPoseEvidenceFrame> _poseEvidence({
  required double bodyHeight,
}) {
  final top = 0.5 - bodyHeight / 2;
  final bottom = 0.5 + bodyHeight / 2;
  return <LiveSprintPoseEvidenceFrame>[
    for (final phase in LiveSprintPoseEvidencePhase.values)
      LiveSprintPoseEvidenceFrame(
        phase: phase,
        capturedOffsetMs: 1200 + phase.index * 240,
        quality: 0.9,
        sideViewConfidence: 0.86,
        imageAspectRatio: 0.5625,
        leadFoot: null,
        joints: <LiveSprintPoseEvidenceJoint>[
          for (final type in RunningPoseLandmarkType.values)
            LiveSprintPoseEvidenceJoint(
              type: type,
              x: 0.32 + (type.index % 5) * 0.08,
              y: type.index.isEven ? top : bottom,
              z: 0,
              confidence: 0.92,
              observed: true,
            ),
        ],
      ),
  ];
}
