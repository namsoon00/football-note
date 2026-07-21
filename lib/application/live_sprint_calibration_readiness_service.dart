import 'dart:math' as math;

import '../domain/entities/running_coach_session.dart';
import '../domain/entities/sprint_capture_calibration_profile.dart';
import 'live_sprint_field_validation_service.dart';
import 'live_sprint_trend_service.dart';

enum LiveSprintCalibrationReadinessStatus {
  currentCaptureNotReady,
  needsMoreSameProfileSessions,
  needsVariationReview,
  readyForThresholdCalibration,
}

enum LiveSprintCalibrationReadinessCheckKind {
  currentFieldValidation,
  sameProfileReadySessions,
  averageFieldQuality,
  timingConfidenceVariation,
  sideViewConfidenceVariation,
  trackingConfidenceVariation,
  trackedFrameRateVariation,
  eligiblePoseRateVariation,
  landingContactRateVariation,
}

class LiveSprintCalibrationReadinessCheck {
  final LiveSprintCalibrationReadinessCheckKind kind;
  final bool passed;
  final double value;
  final double target;
  final bool lowerIsBetter;
  final int? observedCount;
  final int? requiredCount;
  final int priority;

  const LiveSprintCalibrationReadinessCheck({
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

class LiveSprintCalibrationReadinessSummary {
  final LiveSprintCalibrationReadinessStatus status;
  final SprintCaptureCalibrationProfile calibrationProfile;
  final int score;
  final int liveSessionCount;
  final int sameProfileSessionCount;
  final int readySessionCount;
  final int requiredReadySessionCount;
  final List<LiveSprintCalibrationReadinessCheck> checks;

  const LiveSprintCalibrationReadinessSummary({
    required this.status,
    required this.calibrationProfile,
    required this.score,
    required this.liveSessionCount,
    required this.sameProfileSessionCount,
    required this.readySessionCount,
    required this.requiredReadySessionCount,
    required this.checks,
  });

  bool get isReady =>
      status ==
      LiveSprintCalibrationReadinessStatus.readyForThresholdCalibration;

  int get additionalReadySessionsNeeded => math.max(
        0,
        requiredReadySessionCount - readySessionCount,
      );

  List<LiveSprintCalibrationReadinessCheck> get blockers {
    final failed = checks.where((check) => !check.passed).toList();
    failed.sort((a, b) => a.priority.compareTo(b.priority));
    return List<LiveSprintCalibrationReadinessCheck>.unmodifiable(failed);
  }

  List<LiveSprintCalibrationReadinessCheck> get compactChecks {
    final failed = blockers;
    if (failed.isNotEmpty) {
      return List<LiveSprintCalibrationReadinessCheck>.unmodifiable(
        failed.take(3),
      );
    }
    final ordered = List<LiveSprintCalibrationReadinessCheck>.from(checks)
      ..sort((a, b) => a.priority.compareTo(b.priority));
    return List<LiveSprintCalibrationReadinessCheck>.unmodifiable(
      ordered.take(4),
    );
  }
}

class LiveSprintCalibrationReadinessService {
  static const int defaultRequiredReadySessions =
      LiveSprintTrendService.minimumComparableSessions;
  static const double defaultMinimumAverageQuality = 0.80;
  static const double defaultMaximumQualityVariation = 0.06;
  static const double defaultMaximumConfidenceVariation = 0.05;
  static const double defaultMaximumTrackedFrameRateVariation = 0.10;
  static const double defaultMaximumEligiblePoseRateVariation = 0.12;
  static const double defaultMaximumLandingContactRateVariation = 0.15;

  final LiveSprintFieldValidationService _fieldValidationService;
  final int requiredReadySessions;
  final double minimumAverageQuality;
  final double maximumQualityVariation;
  final double maximumConfidenceVariation;
  final double maximumTrackedFrameRateVariation;
  final double maximumEligiblePoseRateVariation;
  final double maximumLandingContactRateVariation;

  const LiveSprintCalibrationReadinessService({
    LiveSprintFieldValidationService fieldValidationService =
        const LiveSprintFieldValidationService(),
    this.requiredReadySessions = defaultRequiredReadySessions,
    this.minimumAverageQuality = defaultMinimumAverageQuality,
    this.maximumQualityVariation = defaultMaximumQualityVariation,
    this.maximumConfidenceVariation = defaultMaximumConfidenceVariation,
    this.maximumTrackedFrameRateVariation =
        defaultMaximumTrackedFrameRateVariation,
    this.maximumEligiblePoseRateVariation =
        defaultMaximumEligiblePoseRateVariation,
    this.maximumLandingContactRateVariation =
        defaultMaximumLandingContactRateVariation,
  }) : _fieldValidationService = fieldValidationService;

  LiveSprintCalibrationReadinessSummary build(
    List<RunningCoachSessionAnalysis> sessions, {
    String? currentSessionId,
  }) {
    final liveSessions = sessions
        .where(
          (session) =>
              session.source == RunningCoachSessionSource.sprintLive &&
              session.liveSprintReport != null,
        )
        .toList(growable: false)
      ..sort((left, right) => right.analyzedAt.compareTo(left.analyzedAt));
    final current = _currentSessionFor(liveSessions, currentSessionId);
    if (current == null) {
      return _emptySummary(liveSessionCount: liveSessions.length);
    }

    final currentReport = current.liveSprintReport!;
    final currentFieldValidation = _fieldValidationService.build(currentReport);
    final profile = currentReport.calibrationProfile;
    final sessionsAtOrBeforeCurrent = liveSessions
        .where(
          (session) =>
              session.id == current.id ||
              !session.analyzedAt.isAfter(current.analyzedAt),
        )
        .toList(growable: false);
    final sameProfileSessions = sessionsAtOrBeforeCurrent
        .where(
          (session) => session.liveSprintReport!.calibrationProfile == profile,
        )
        .toList(growable: false);
    final readySessions = sameProfileSessions
        .where(
          (session) =>
              _fieldValidationService.build(session.liveSprintReport!).isReady,
        )
        .toList(growable: false);
    final currentReady = currentFieldValidation.isReady;
    final checks = <LiveSprintCalibrationReadinessCheck>[
      LiveSprintCalibrationReadinessCheck(
        kind: LiveSprintCalibrationReadinessCheckKind.currentFieldValidation,
        passed: currentReady,
        value: currentFieldValidation.qualityScore / 100,
        target: minimumAverageQuality,
        priority: 10,
      ),
      LiveSprintCalibrationReadinessCheck(
        kind: LiveSprintCalibrationReadinessCheckKind.sameProfileReadySessions,
        passed: currentReady && readySessions.length >= requiredReadySessions,
        value: _countRatio(readySessions.length, requiredReadySessions),
        target: 1,
        observedCount: readySessions.length,
        requiredCount: requiredReadySessions,
        priority: 20,
      ),
    ];

    if (!currentReady) {
      return _summary(
        status: LiveSprintCalibrationReadinessStatus.currentCaptureNotReady,
        calibrationProfile: profile,
        score: currentFieldValidation.qualityScore,
        liveSessionCount: liveSessions.length,
        sameProfileSessionCount: sameProfileSessions.length,
        readySessionCount: readySessions.length,
        checks: checks,
      );
    }

    final measurements = readySessions
        .map(_measurementFor)
        .whereType<_CalibrationReadinessMeasurement>()
        .toList(growable: false);
    final averageFieldQuality = _average(
      measurements.map((measurement) => measurement.fieldQuality).toList(),
    );
    if (readySessions.length < requiredReadySessions) {
      final score = (averageFieldQuality * 70 +
              _countRatio(readySessions.length, requiredReadySessions) * 30)
          .round()
          .clamp(0, 100)
          .toInt();
      return _summary(
        status:
            LiveSprintCalibrationReadinessStatus.needsMoreSameProfileSessions,
        calibrationProfile: profile,
        score: score,
        liveSessionCount: liveSessions.length,
        sameProfileSessionCount: sameProfileSessions.length,
        readySessionCount: readySessions.length,
        checks: checks,
      );
    }

    checks.addAll(
      _repeatabilityChecks(
        measurements,
        averageFieldQuality: averageFieldQuality,
      ),
    );
    final repeatabilityScore = _repeatabilityScore(checks);
    final score = (averageFieldQuality * 55 + repeatabilityScore * 45)
        .round()
        .clamp(0, 100)
        .toInt();
    final hasBlockers = checks.any((check) => !check.passed);
    return _summary(
      status: hasBlockers
          ? LiveSprintCalibrationReadinessStatus.needsVariationReview
          : LiveSprintCalibrationReadinessStatus.readyForThresholdCalibration,
      calibrationProfile: profile,
      score: score,
      liveSessionCount: liveSessions.length,
      sameProfileSessionCount: sameProfileSessions.length,
      readySessionCount: readySessions.length,
      checks: checks,
    );
  }

  RunningCoachSessionAnalysis? _currentSessionFor(
    List<RunningCoachSessionAnalysis> sessions,
    String? sessionId,
  ) {
    if (sessions.isEmpty) {
      return null;
    }
    if (sessionId == null) {
      return sessions.first;
    }
    for (final session in sessions) {
      if (session.id == sessionId) {
        return session;
      }
    }
    return null;
  }

  _CalibrationReadinessMeasurement? _measurementFor(
    RunningCoachSessionAnalysis session,
  ) {
    final report = session.liveSprintReport;
    if (report == null) {
      return null;
    }
    final diagnostic = report.poseEvidenceDiagnostic;
    final fieldValidation = _fieldValidationService.build(report);
    return _CalibrationReadinessMeasurement(
      fieldQuality: fieldValidation.qualityScore / 100,
      timingConfidence: _ratio(report.timingConfidence),
      sideViewConfidence: _ratio(report.sideViewConfidence),
      trackingConfidence: _ratio(report.sprintTrackingConfidence),
      trackedFrameRate: _trackedFrameRate(report),
      eligiblePoseRate: _eligiblePoseRate(diagnostic),
      landingContactRate: _landingContactRate(report),
    );
  }

  List<LiveSprintCalibrationReadinessCheck> _repeatabilityChecks(
    List<_CalibrationReadinessMeasurement> measurements, {
    required double averageFieldQuality,
  }) {
    return <LiveSprintCalibrationReadinessCheck>[
      LiveSprintCalibrationReadinessCheck(
        kind: LiveSprintCalibrationReadinessCheckKind.averageFieldQuality,
        passed: averageFieldQuality >= minimumAverageQuality,
        value: averageFieldQuality,
        target: minimumAverageQuality,
        priority: 30,
      ),
      _variationCheck(
        kind: LiveSprintCalibrationReadinessCheckKind.timingConfidenceVariation,
        values: measurements
            .map((measurement) => measurement.timingConfidence)
            .toList(),
        target: maximumConfidenceVariation,
        priority: 40,
      ),
      _variationCheck(
        kind:
            LiveSprintCalibrationReadinessCheckKind.sideViewConfidenceVariation,
        values: measurements
            .map((measurement) => measurement.sideViewConfidence)
            .toList(),
        target: maximumConfidenceVariation,
        priority: 50,
      ),
      _variationCheck(
        kind:
            LiveSprintCalibrationReadinessCheckKind.trackingConfidenceVariation,
        values: measurements
            .map((measurement) => measurement.trackingConfidence)
            .toList(),
        target: maximumConfidenceVariation,
        priority: 60,
      ),
      _variationCheck(
        kind: LiveSprintCalibrationReadinessCheckKind.trackedFrameRateVariation,
        values: measurements
            .map((measurement) => measurement.trackedFrameRate)
            .toList(),
        target: maximumTrackedFrameRateVariation,
        priority: 70,
      ),
      _variationCheck(
        kind: LiveSprintCalibrationReadinessCheckKind.eligiblePoseRateVariation,
        values: measurements
            .map((measurement) => measurement.eligiblePoseRate)
            .toList(),
        target: maximumEligiblePoseRateVariation,
        priority: 80,
      ),
      _variationCheck(
        kind:
            LiveSprintCalibrationReadinessCheckKind.landingContactRateVariation,
        values: measurements
            .map((measurement) => measurement.landingContactRate)
            .toList(),
        target: maximumLandingContactRateVariation,
        priority: 90,
      ),
    ];
  }

  LiveSprintCalibrationReadinessCheck _variationCheck({
    required LiveSprintCalibrationReadinessCheckKind kind,
    required List<double> values,
    required double target,
    required int priority,
  }) {
    final variation = _standardDeviation(values);
    return LiveSprintCalibrationReadinessCheck(
      kind: kind,
      passed: variation <= target,
      value: variation,
      target: target,
      lowerIsBetter: true,
      priority: priority,
    );
  }

  double _repeatabilityScore(
    List<LiveSprintCalibrationReadinessCheck> checks,
  ) {
    final variationScores = checks
        .where((check) => check.lowerIsBetter)
        .map((check) => (1 - (check.value / check.target)).clamp(0.0, 1.0))
        .toList(growable: false);
    if (variationScores.isEmpty) {
      return 0;
    }
    return _average(variationScores);
  }

  double _trackedFrameRate(LiveSprintSessionReport report) {
    final denominator = math.max(
      report.sprintAnalyzedFrames,
      _fieldValidationService.minimumTrackedFrames,
    );
    return _countRatio(report.sprintTrackedFrames, denominator);
  }

  double _eligiblePoseRate(LiveSprintPoseEvidenceDiagnostic diagnostic) {
    if (diagnostic.evaluatedFrames <= 0) {
      return 0;
    }
    return _countRatio(diagnostic.eligibleFrames, diagnostic.evaluatedFrames);
  }

  double _landingContactRate(LiveSprintSessionReport report) {
    final contactCount = math.max(
      report.touchdownEvents,
      math.max(report.detectedSteps, report.landingEvents),
    );
    return _countRatio(report.landingEvents, contactCount);
  }

  LiveSprintCalibrationReadinessSummary _emptySummary({
    required int liveSessionCount,
  }) {
    return LiveSprintCalibrationReadinessSummary(
      status: LiveSprintCalibrationReadinessStatus.currentCaptureNotReady,
      calibrationProfile: SprintCaptureCalibrationProfile.balanced,
      score: 0,
      liveSessionCount: liveSessionCount,
      sameProfileSessionCount: 0,
      readySessionCount: 0,
      requiredReadySessionCount: requiredReadySessions,
      checks: <LiveSprintCalibrationReadinessCheck>[
        LiveSprintCalibrationReadinessCheck(
          kind: LiveSprintCalibrationReadinessCheckKind.currentFieldValidation,
          passed: false,
          value: 0,
          target: minimumAverageQuality,
          priority: 10,
        ),
      ],
    );
  }

  LiveSprintCalibrationReadinessSummary _summary({
    required LiveSprintCalibrationReadinessStatus status,
    required SprintCaptureCalibrationProfile calibrationProfile,
    required int score,
    required int liveSessionCount,
    required int sameProfileSessionCount,
    required int readySessionCount,
    required List<LiveSprintCalibrationReadinessCheck> checks,
  }) {
    return LiveSprintCalibrationReadinessSummary(
      status: status,
      calibrationProfile: calibrationProfile,
      score: score,
      liveSessionCount: liveSessionCount,
      sameProfileSessionCount: sameProfileSessionCount,
      readySessionCount: readySessionCount,
      requiredReadySessionCount: requiredReadySessions,
      checks: List<LiveSprintCalibrationReadinessCheck>.unmodifiable(checks),
    );
  }
}

class _CalibrationReadinessMeasurement {
  final double fieldQuality;
  final double timingConfidence;
  final double sideViewConfidence;
  final double trackingConfidence;
  final double trackedFrameRate;
  final double eligiblePoseRate;
  final double landingContactRate;

  const _CalibrationReadinessMeasurement({
    required this.fieldQuality,
    required this.timingConfidence,
    required this.sideViewConfidence,
    required this.trackingConfidence,
    required this.trackedFrameRate,
    required this.eligiblePoseRate,
    required this.landingContactRate,
  });
}

double _countRatio(int observed, int required) {
  if (required <= 0) {
    return 1;
  }
  return (observed / required).clamp(0.0, 1.0).toDouble();
}

double _ratio(double value) {
  if (!value.isFinite) {
    return 0;
  }
  return value.clamp(0.0, 1.0).toDouble();
}

double _average(List<double> values) {
  if (values.isEmpty) {
    return 0;
  }
  return values.reduce((sum, value) => sum + value) / values.length;
}

double _standardDeviation(List<double> values) {
  if (values.length < 2) {
    return 0;
  }
  final mean = _average(values);
  final variance = values
          .map((value) => math.pow(value - mean, 2).toDouble())
          .reduce((sum, value) => sum + value) /
      values.length;
  return math.sqrt(variance);
}
