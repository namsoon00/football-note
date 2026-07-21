import '../domain/entities/running_coach_session.dart';
import '../domain/entities/sprint_capture_calibration_profile.dart';

enum LiveSprintFieldValidationStatus {
  insufficient,
  needsReview,
  readyForCalibration,
}

enum LiveSprintFieldValidationCheckKind {
  captureReadiness,
  phaseCoverage,
  trackedFrames,
  usablePoseSamples,
  timingConfidence,
  sideViewConfidence,
  trackingConfidence,
  bodyVisibility,
  stepEvidence,
  landingEvidence,
}

class LiveSprintFieldValidationCheck {
  final LiveSprintFieldValidationCheckKind kind;
  final bool passed;
  final double value;
  final double target;
  final bool lowerIsBetter;
  final int? observedCount;
  final int? requiredCount;
  final int priority;

  const LiveSprintFieldValidationCheck({
    required this.kind,
    required this.passed,
    required this.value,
    required this.target,
    required this.priority,
    this.lowerIsBetter = false,
    this.observedCount,
    this.requiredCount,
  });
}

class LiveSprintFieldValidationSummary {
  final LiveSprintFieldValidationStatus status;
  final SprintCaptureCalibrationProfile calibrationProfile;
  final int qualityScore;
  final List<LiveSprintFieldValidationCheck> checks;

  const LiveSprintFieldValidationSummary({
    required this.status,
    required this.calibrationProfile,
    required this.qualityScore,
    required this.checks,
  });

  bool get isReady =>
      status == LiveSprintFieldValidationStatus.readyForCalibration;

  List<LiveSprintFieldValidationCheck> get blockers {
    final failed = checks.where((check) => !check.passed).toList();
    failed.sort((a, b) => a.priority.compareTo(b.priority));
    return List<LiveSprintFieldValidationCheck>.unmodifiable(failed);
  }

  List<LiveSprintFieldValidationCheck> get nextCaptureChecks {
    return List<LiveSprintFieldValidationCheck>.unmodifiable(
      blockers.take(3),
    );
  }
}

class LiveSprintFieldValidationService {
  static const int defaultMinimumTrackedFrames = 48;
  static const int defaultMinimumUsablePoseSamples = 12;
  static const int defaultMinimumDetectedSteps = 6;
  static const int defaultMinimumLandingEvents = 4;
  static const double defaultMinimumConfidence = 0.75;
  static const double defaultMaximumBodyNotVisibleRatio = 0.10;

  static const int _minimumReviewTrackedFrames = 18;
  static const int _minimumReviewPoseSamples = 4;
  static const int _minimumReviewDetectedSteps = 2;
  static const double _minimumReviewConfidence = 0.45;
  static const double _maximumReviewBodyNotVisibleRatio = 0.45;

  final int minimumTrackedFrames;
  final int minimumUsablePoseSamples;
  final int minimumDetectedSteps;
  final int minimumLandingEvents;
  final double minimumConfidence;
  final double maximumBodyNotVisibleRatio;

  const LiveSprintFieldValidationService({
    this.minimumTrackedFrames = defaultMinimumTrackedFrames,
    this.minimumUsablePoseSamples = defaultMinimumUsablePoseSamples,
    this.minimumDetectedSteps = defaultMinimumDetectedSteps,
    this.minimumLandingEvents = defaultMinimumLandingEvents,
    this.minimumConfidence = defaultMinimumConfidence,
    this.maximumBodyNotVisibleRatio = defaultMaximumBodyNotVisibleRatio,
  });

  LiveSprintFieldValidationSummary build(LiveSprintSessionReport report) {
    final diagnostic = report.poseEvidenceDiagnostic;
    final readinessReadyCount = _readinessReadyCount(
      diagnostic.readinessSummary,
    );
    final capturedPhaseCount = _capturedPhaseCount(report, diagnostic);
    final timingConfidence = _ratio(report.timingConfidence);
    final sideViewConfidence = _ratio(report.sideViewConfidence);
    final trackingConfidence = _ratio(report.sprintTrackingConfidence);
    final bodyNotVisibleRatio = _ratio(report.bodyNotVisibleRatio);
    final trackedFrames = _nonNegative(report.sprintTrackedFrames);
    final usablePoseSamples = _nonNegative(diagnostic.eligibleFrames);
    final detectedSteps = _nonNegative(report.detectedSteps);
    final landingEvents = _nonNegative(report.landingEvents);

    final checks = <LiveSprintFieldValidationCheck>[
      LiveSprintFieldValidationCheck(
        kind: LiveSprintFieldValidationCheckKind.captureReadiness,
        passed: readinessReadyCount == 4,
        value: readinessReadyCount / 4,
        target: 1,
        observedCount: readinessReadyCount,
        requiredCount: 4,
        priority: 10,
      ),
      LiveSprintFieldValidationCheck(
        kind: LiveSprintFieldValidationCheckKind.phaseCoverage,
        passed: capturedPhaseCount >= LiveSprintPoseEvidencePhase.values.length,
        value: capturedPhaseCount.toDouble(),
        target: LiveSprintPoseEvidencePhase.values.length.toDouble(),
        observedCount: capturedPhaseCount,
        requiredCount: LiveSprintPoseEvidencePhase.values.length,
        priority: 20,
      ),
      LiveSprintFieldValidationCheck(
        kind: LiveSprintFieldValidationCheckKind.trackedFrames,
        passed: trackedFrames >= minimumTrackedFrames,
        value: trackedFrames.toDouble(),
        target: minimumTrackedFrames.toDouble(),
        observedCount: trackedFrames,
        requiredCount: minimumTrackedFrames,
        priority: 30,
      ),
      LiveSprintFieldValidationCheck(
        kind: LiveSprintFieldValidationCheckKind.usablePoseSamples,
        passed: usablePoseSamples >= minimumUsablePoseSamples,
        value: usablePoseSamples.toDouble(),
        target: minimumUsablePoseSamples.toDouble(),
        observedCount: usablePoseSamples,
        requiredCount: minimumUsablePoseSamples,
        priority: 40,
      ),
      LiveSprintFieldValidationCheck(
        kind: LiveSprintFieldValidationCheckKind.timingConfidence,
        passed: timingConfidence >= minimumConfidence,
        value: timingConfidence,
        target: minimumConfidence,
        priority: 50,
      ),
      LiveSprintFieldValidationCheck(
        kind: LiveSprintFieldValidationCheckKind.sideViewConfidence,
        passed: sideViewConfidence >= minimumConfidence,
        value: sideViewConfidence,
        target: minimumConfidence,
        priority: 60,
      ),
      LiveSprintFieldValidationCheck(
        kind: LiveSprintFieldValidationCheckKind.trackingConfidence,
        passed: trackingConfidence >= minimumConfidence,
        value: trackingConfidence,
        target: minimumConfidence,
        priority: 70,
      ),
      LiveSprintFieldValidationCheck(
        kind: LiveSprintFieldValidationCheckKind.bodyVisibility,
        passed: bodyNotVisibleRatio <= maximumBodyNotVisibleRatio,
        value: bodyNotVisibleRatio,
        target: maximumBodyNotVisibleRatio,
        lowerIsBetter: true,
        priority: 80,
      ),
      LiveSprintFieldValidationCheck(
        kind: LiveSprintFieldValidationCheckKind.stepEvidence,
        passed: detectedSteps >= minimumDetectedSteps,
        value: detectedSteps.toDouble(),
        target: minimumDetectedSteps.toDouble(),
        observedCount: detectedSteps,
        requiredCount: minimumDetectedSteps,
        priority: 90,
      ),
      LiveSprintFieldValidationCheck(
        kind: LiveSprintFieldValidationCheckKind.landingEvidence,
        passed: landingEvents >= minimumLandingEvents,
        value: landingEvents.toDouble(),
        target: minimumLandingEvents.toDouble(),
        observedCount: landingEvents,
        requiredCount: minimumLandingEvents,
        priority: 100,
      ),
    ];
    final qualityScore = _qualityScore(
      readinessReadyCount: readinessReadyCount,
      capturedPhaseCount: capturedPhaseCount,
      trackedFrames: trackedFrames,
      usablePoseSamples: usablePoseSamples,
      timingConfidence: timingConfidence,
      sideViewConfidence: sideViewConfidence,
      trackingConfidence: trackingConfidence,
      bodyNotVisibleRatio: bodyNotVisibleRatio,
      detectedSteps: detectedSteps,
      landingEvents: landingEvents,
    );
    final status = _statusFor(
      checks: checks,
      qualityScore: qualityScore,
      readinessReadyCount: readinessReadyCount,
      capturedPhaseCount: capturedPhaseCount,
      trackedFrames: trackedFrames,
      usablePoseSamples: usablePoseSamples,
      timingConfidence: timingConfidence,
      sideViewConfidence: sideViewConfidence,
      trackingConfidence: trackingConfidence,
      bodyNotVisibleRatio: bodyNotVisibleRatio,
      detectedSteps: detectedSteps,
      landingEvents: landingEvents,
    );

    return LiveSprintFieldValidationSummary(
      status: status,
      calibrationProfile: report.calibrationProfile,
      qualityScore: qualityScore,
      checks: List<LiveSprintFieldValidationCheck>.unmodifiable(checks),
    );
  }

  int _qualityScore({
    required int readinessReadyCount,
    required int capturedPhaseCount,
    required int trackedFrames,
    required int usablePoseSamples,
    required double timingConfidence,
    required double sideViewConfidence,
    required double trackingConfidence,
    required double bodyNotVisibleRatio,
    required int detectedSteps,
    required int landingEvents,
  }) {
    final readinessScore = readinessReadyCount / 4;
    final phaseScore = _countRatio(
      capturedPhaseCount,
      LiveSprintPoseEvidencePhase.values.length,
    );
    final sampleScore = (_countRatio(trackedFrames, minimumTrackedFrames) +
            _countRatio(usablePoseSamples, minimumUsablePoseSamples)) /
        2;
    final confidenceScore =
        (timingConfidence + sideViewConfidence + trackingConfidence) / 3;
    final bodyScore = (1 - bodyNotVisibleRatio).clamp(0.0, 1.0).toDouble();
    final stepScore = _countRatio(detectedSteps, minimumDetectedSteps);
    final landingScore = _countRatio(landingEvents, minimumLandingEvents);

    return (readinessScore * 20 +
            phaseScore * 15 +
            sampleScore * 15 +
            confidenceScore * 20 +
            bodyScore * 10 +
            stepScore * 10 +
            landingScore * 10)
        .round()
        .clamp(0, 100)
        .toInt();
  }

  LiveSprintFieldValidationStatus _statusFor({
    required List<LiveSprintFieldValidationCheck> checks,
    required int qualityScore,
    required int readinessReadyCount,
    required int capturedPhaseCount,
    required int trackedFrames,
    required int usablePoseSamples,
    required double timingConfidence,
    required double sideViewConfidence,
    required double trackingConfidence,
    required double bodyNotVisibleRatio,
    required int detectedSteps,
    required int landingEvents,
  }) {
    if (checks.every((check) => check.passed) && qualityScore >= 80) {
      return LiveSprintFieldValidationStatus.readyForCalibration;
    }
    final hasCriticalGap = readinessReadyCount <= 1 ||
        capturedPhaseCount == 0 ||
        trackedFrames < _minimumReviewTrackedFrames ||
        usablePoseSamples < _minimumReviewPoseSamples ||
        timingConfidence < _minimumReviewConfidence ||
        sideViewConfidence < _minimumReviewConfidence ||
        trackingConfidence < _minimumReviewConfidence ||
        bodyNotVisibleRatio > _maximumReviewBodyNotVisibleRatio ||
        detectedSteps < _minimumReviewDetectedSteps ||
        landingEvents == 0;
    if (hasCriticalGap || qualityScore < 45) {
      return LiveSprintFieldValidationStatus.insufficient;
    }
    return LiveSprintFieldValidationStatus.needsReview;
  }

  int _readinessReadyCount(LiveSprintCaptureReadinessSummary summary) {
    return <LiveSprintCaptureReadinessCheck>[
      summary.framing,
      summary.sideView,
      summary.coreJointConfidence,
      summary.gaitPhase,
    ].where((check) => check.ready).length;
  }

  int _capturedPhaseCount(
    LiveSprintSessionReport report,
    LiveSprintPoseEvidenceDiagnostic diagnostic,
  ) {
    final capturedFromEvidence =
        report.poseEvidence.map((evidence) => evidence.phase).toSet().length;
    final captured = capturedFromEvidence > diagnostic.capturedPhaseCount
        ? capturedFromEvidence
        : diagnostic.capturedPhaseCount;
    return captured.clamp(0, LiveSprintPoseEvidencePhase.values.length).toInt();
  }

  double _countRatio(int observed, int required) {
    if (required <= 0) {
      return 1;
    }
    return (observed / required).clamp(0.0, 1.0).toDouble();
  }

  int _nonNegative(int value) => value < 0 ? 0 : value;

  double _ratio(double value) {
    if (!value.isFinite) {
      return 0;
    }
    return value.clamp(0.0, 1.0).toDouble();
  }
}
