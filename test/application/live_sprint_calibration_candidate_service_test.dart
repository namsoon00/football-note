import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/live_sprint_calibration_candidate_service.dart';
import 'package:football_note/application/sprint_capture_calibration_service.dart';
import 'package:football_note/domain/entities/running_coach_session.dart';
import 'package:football_note/domain/entities/running_live_coaching_state.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';
import 'package:football_note/domain/entities/sprint_capture_calibration_profile.dart';
import 'package:football_note/domain/entities/sprint_realtime_coaching_state.dart';
import 'package:football_note/domain/repositories/option_repository.dart';

void main() {
  const service = LiveSprintCalibrationCandidateService();

  test('recommends the next stricter profile only after all gates pass', () {
    final sessions = <RunningCoachSessionAnalysis>[
      _session(
        id: 'current',
        at: DateTime(2026, 7, 21),
        context: _context(distanceBand: LiveSprintCaptureDistanceBand.close),
      ),
      _session(
        id: 'baseline',
        at: DateTime(2026, 7, 20),
        context: _context(),
      ),
      _session(
        id: 'far',
        at: DateTime(2026, 7, 19),
        context: _context(distanceBand: LiveSprintCaptureDistanceBand.far),
      ),
    ];

    final summary = service.build(sessions, currentSessionId: 'current');

    expect(
      summary.status,
      LiveSprintCalibrationCandidateStatus.safeRecommendation,
    );
    expect(
      summary.currentProfile,
      SprintCaptureCalibrationProfile.balanced,
    );
    expect(
      summary.recommendedProfile,
      SprintCaptureCalibrationProfile.conservative,
    );
    expect(summary.eligibleSessionCount, 3);
    expect(summary.holdoutSessionId, 'current');
    expect(summary.blockers, isEmpty);
    expect(summary.fieldMatrixSummary.isRecommendationCoverageReady, isTrue);
    expect(summary.recommendedEvaluation!.passedSessionCount, 3);
  });

  test('rejects a candidate when the latest holdout regresses', () {
    final summary = service.build(
      <RunningCoachSessionAnalysis>[
        _session(
          id: 'current',
          at: DateTime(2026, 7, 21),
          context: _context(distanceBand: LiveSprintCaptureDistanceBand.close),
          coreConfidence: 0.77,
        ),
        _session(
          id: 'baseline',
          at: DateTime(2026, 7, 20),
          context: _context(),
        ),
        _session(
          id: 'legacy-variation',
          at: DateTime(2026, 7, 19),
          context: const LiveSprintCaptureContext.unknown(),
        ),
      ],
      currentSessionId: 'current',
    );

    expect(summary.status, LiveSprintCalibrationCandidateStatus.keepCurrent);
    expect(summary.recommendedProfile, isNull);
    expect(
      summary.blockers,
      contains(LiveSprintCalibrationCandidateBlockerKind.holdoutRegression),
    );
    expect(
      summary.blockers,
      contains(LiveSprintCalibrationCandidateBlockerKind.evidenceMargin),
    );
    expect(summary.evaluations.single.failedSessionIds, <String>['current']);
  });

  test('excludes mixed-profile sessions from candidate evaluation', () {
    final summary = service.build(
      <RunningCoachSessionAnalysis>[
        _session(
          id: 'current',
          at: DateTime(2026, 7, 21),
          context: _context(distanceBand: LiveSprintCaptureDistanceBand.close),
        ),
        _session(
          id: 'baseline',
          at: DateTime(2026, 7, 20),
          context: _context(),
        ),
        _session(
          id: 'far',
          at: DateTime(2026, 7, 19),
          context: _context(distanceBand: LiveSprintCaptureDistanceBand.far),
        ),
        _session(
          id: 'responsive-outlier',
          at: DateTime(2026, 7, 18),
          profile: SprintCaptureCalibrationProfile.responsive,
          context: _context(
            distanceBand: LiveSprintCaptureDistanceBand.normal,
            viewBand: LiveSprintViewBand.partialSide,
          ),
          coreConfidence: 0.30,
        ),
      ],
      currentSessionId: 'current',
    );

    expect(
      summary.status,
      LiveSprintCalibrationCandidateStatus.safeRecommendation,
    );
    expect(summary.eligibleSessionCount, 3);
    expect(summary.recommendedEvaluation!.eligibleSessionCount, 3);
  });

  test('legacy records without context block recommendation coverage safely',
      () {
    final legacyMap = _session(
      id: 'current',
      at: DateTime(2026, 7, 21),
      context: _context(distanceBand: LiveSprintCaptureDistanceBand.close),
    ).toMap();
    final reportMap = legacyMap['liveSprintReport']! as Map<String, Object?>;
    reportMap.remove('captureContext');
    final legacy = RunningCoachSessionAnalysis.fromMap(
      Map<String, dynamic>.from(legacyMap),
    );

    final summary = service.build(
      <RunningCoachSessionAnalysis>[
        legacy,
        _session(
          id: 'baseline',
          at: DateTime(2026, 7, 20),
          context: _context(),
        ),
        _session(
          id: 'legacy-variation',
          at: DateTime(2026, 7, 19),
          context: const LiveSprintCaptureContext.unknown(),
        ),
      ],
      currentSessionId: 'current',
    );

    expect(
      legacy.liveSprintReport!.captureContext,
      isA<LiveSprintCaptureContext>(),
    );
    expect(
      legacy.liveSprintReport!.captureContext.deviceClass,
      LiveSprintDeviceClass.unknown,
    );
    expect(summary.status, LiveSprintCalibrationCandidateStatus.notReady);
    expect(
      summary.blockers,
      contains(LiveSprintCalibrationCandidateBlockerKind.fieldMatrixCoverage),
    );
    expect(summary.fieldMatrixSummary.unknownContextSessionCount, 2);
  });

  test('does not mutate saved profile options or report profiles', () async {
    final repository = _MemoryOptionRepository();
    await SprintCaptureCalibrationProfileService(repository)
        .saveSelectedProfile(SprintCaptureCalibrationProfile.responsive);
    final sessions = <RunningCoachSessionAnalysis>[
      _session(
        id: 'current',
        at: DateTime(2026, 7, 21),
        context: _context(distanceBand: LiveSprintCaptureDistanceBand.close),
      ),
      _session(
        id: 'baseline',
        at: DateTime(2026, 7, 20),
        context: _context(),
      ),
      _session(
        id: 'far',
        at: DateTime(2026, 7, 19),
        context: _context(distanceBand: LiveSprintCaptureDistanceBand.far),
      ),
    ];

    final beforeProfiles = sessions
        .map((session) => session.liveSprintReport!.calibrationProfile)
        .toList(growable: false);
    final summary = service.build(sessions, currentSessionId: 'current');
    final afterProfiles = sessions
        .map((session) => session.liveSprintReport!.calibrationProfile)
        .toList(growable: false);

    expect(summary.hasRecommendation, isTrue);
    expect(afterProfiles, beforeProfiles);
    expect(
      SprintCaptureCalibrationProfileService(repository).loadSelectedProfile(),
      SprintCaptureCalibrationProfile.responsive,
    );
  });
}

RunningCoachSessionAnalysis _session({
  required String id,
  required DateTime at,
  required LiveSprintCaptureContext context,
  SprintCaptureCalibrationProfile profile =
      SprintCaptureCalibrationProfile.balanced,
  double coreConfidence = 0.90,
}) {
  return RunningCoachSessionAnalysis(
    id: id,
    analyzedAt: at,
    source: RunningCoachSessionSource.sprintLive,
    overallScore: 86,
    duration: const Duration(seconds: 16),
    sampledFrames: 180,
    validFrames: 160,
    primaryMetric: RunningCoachMetric.footStrike,
    primaryFinding: RunningCoachFinding.footStrikeUnderBody,
    primaryStatus: RunningCoachStatus.good,
    primaryScore: 86,
    primaryValue: 0.18,
    primaryConfidence: 0.9,
    liveSprintReport: LiveSprintSessionReport(
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
      timingConfidence: 0.90,
      sideViewConfidence: 0.88,
      sprintTrackingConfidence: 0.90,
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
          confidence: 0.88,
          sampleCount: 8,
        ),
      ],
      poseEvidence: _poseEvidence(jointConfidence: 0.92),
      poseEvidenceDiagnostic: _diagnostic(coreConfidence: coreConfidence),
      captureContext: context,
    ),
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
  required double coreConfidence,
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
      sideView: const LiveSprintCaptureReadinessCheck(
        ready: true,
        value: 0.88,
        threshold: 0.65,
      ),
      coreJointConfidence: LiveSprintCaptureReadinessCheck(
        ready: true,
        value: coreConfidence,
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
  required double jointConfidence,
}) {
  return <LiveSprintPoseEvidenceFrame>[
    for (final phase in LiveSprintPoseEvidencePhase.values)
      LiveSprintPoseEvidenceFrame(
        phase: phase,
        capturedOffsetMs: 1400 + phase.index * 220,
        quality: 0.90,
        sideViewConfidence: 0.88,
        imageAspectRatio: 0.5625,
        leadFoot: phase == LiveSprintPoseEvidencePhase.touchdown
            ? RunningFootSide.left
            : null,
        joints: <LiveSprintPoseEvidenceJoint>[
          for (final type in RunningPoseLandmarkType.values)
            LiveSprintPoseEvidenceJoint(
              type: type,
              x: 0.30 + (type.index % 5) * 0.08,
              y: 0.18 + (type.index ~/ 5) * 0.12,
              z: 0,
              confidence: jointConfidence,
              observed: true,
            ),
        ],
      ),
  ];
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> values = <String, dynamic>{};

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    return values[key] as List<int>? ?? defaults;
  }

  @override
  List<String> getOptions(String key, List<String> defaults) {
    return values[key] as List<String>? ?? defaults;
  }

  @override
  T? getValue<T>(String key) {
    return values[key] as T?;
  }

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    values[key] = options;
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    values[key] = value;
  }
}
