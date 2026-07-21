import 'dart:math' as math;

import '../domain/entities/running_coach_session.dart';
import '../domain/entities/sprint_capture_calibration_profile.dart';
import 'live_sprint_calibration_readiness_service.dart';
import 'live_sprint_field_validation_matrix_service.dart';
import 'live_sprint_field_validation_service.dart';
import 'sprint_capture_calibration_service.dart';

enum LiveSprintCalibrationCandidateStatus {
  notReady,
  keepCurrent,
  safeRecommendation,
}

enum LiveSprintCalibrationCandidateBlockerKind {
  repeatabilityReadiness,
  fieldMatrixCoverage,
  noMoreStringentProfile,
  candidateEvidence,
  evidenceMargin,
  coverageRegression,
  holdoutRegression,
}

class LiveSprintCalibrationCandidateEvaluation {
  final SprintCaptureCalibrationProfile candidateProfile;
  final bool passed;
  final double evidenceMargin;
  final int passedSessionCount;
  final int eligibleSessionCount;
  final int projectedCoverageScore;
  final String? holdoutSessionId;
  final List<LiveSprintCalibrationCandidateBlockerKind> blockers;
  final List<String> failedSessionIds;

  const LiveSprintCalibrationCandidateEvaluation({
    required this.candidateProfile,
    required this.passed,
    required this.evidenceMargin,
    required this.passedSessionCount,
    required this.eligibleSessionCount,
    required this.projectedCoverageScore,
    required this.holdoutSessionId,
    required this.blockers,
    required this.failedSessionIds,
  });
}

class LiveSprintCalibrationCandidateSummary {
  final LiveSprintCalibrationCandidateStatus status;
  final SprintCaptureCalibrationProfile currentProfile;
  final SprintCaptureCalibrationProfile? recommendedProfile;
  final int score;
  final int eligibleSessionCount;
  final String? holdoutSessionId;
  final double evidenceMargin;
  final LiveSprintCalibrationReadinessSummary readinessSummary;
  final LiveSprintFieldValidationMatrixSummary fieldMatrixSummary;
  final List<LiveSprintCalibrationCandidateEvaluation> evaluations;
  final List<LiveSprintCalibrationCandidateBlockerKind> blockers;

  const LiveSprintCalibrationCandidateSummary({
    required this.status,
    required this.currentProfile,
    required this.recommendedProfile,
    required this.score,
    required this.eligibleSessionCount,
    required this.holdoutSessionId,
    required this.evidenceMargin,
    required this.readinessSummary,
    required this.fieldMatrixSummary,
    required this.evaluations,
    required this.blockers,
  });

  bool get hasRecommendation =>
      status == LiveSprintCalibrationCandidateStatus.safeRecommendation &&
      recommendedProfile != null;

  LiveSprintCalibrationCandidateEvaluation? get recommendedEvaluation {
    final target = recommendedProfile;
    if (target == null) {
      return null;
    }
    for (final evaluation in evaluations) {
      if (evaluation.candidateProfile == target) {
        return evaluation;
      }
    }
    return null;
  }
}

class LiveSprintCalibrationCandidateService {
  static const double defaultMinimumEvidenceMargin = 0.03;

  final LiveSprintCalibrationReadinessService _readinessService;
  final LiveSprintFieldValidationMatrixService _fieldMatrixService;
  final LiveSprintFieldValidationService _fieldValidationService;
  final double minimumEvidenceMargin;

  const LiveSprintCalibrationCandidateService({
    LiveSprintCalibrationReadinessService readinessService =
        const LiveSprintCalibrationReadinessService(),
    LiveSprintFieldValidationMatrixService fieldMatrixService =
        const LiveSprintFieldValidationMatrixService(),
    LiveSprintFieldValidationService fieldValidationService =
        const LiveSprintFieldValidationService(),
    this.minimumEvidenceMargin = defaultMinimumEvidenceMargin,
  })  : _readinessService = readinessService,
        _fieldMatrixService = fieldMatrixService,
        _fieldValidationService = fieldValidationService;

  LiveSprintCalibrationCandidateSummary build(
    List<RunningCoachSessionAnalysis> sessions, {
    String? currentSessionId,
  }) {
    final readiness = _readinessService.build(
      sessions,
      currentSessionId: currentSessionId,
    );
    final fieldMatrix = _fieldMatrixService.build(
      sessions,
      currentSessionId: currentSessionId,
    );
    final liveSessions = sessions
        .where(
          (session) =>
              session.source == RunningCoachSessionSource.sprintLive &&
              session.liveSprintReport != null,
        )
        .toList(growable: false)
      ..sort((left, right) => right.analyzedAt.compareTo(left.analyzedAt));
    final current = _currentSessionFor(liveSessions, currentSessionId);
    final currentProfile = current?.liveSprintReport?.calibrationProfile ??
        readiness.calibrationProfile;
    final eligibleSessions = current == null
        ? const <RunningCoachSessionAnalysis>[]
        : _eligibleSessionsAtOrBefore(
            liveSessions,
            current: current,
            profile: currentProfile,
          );

    if (!readiness.isReady) {
      return _summary(
        status: LiveSprintCalibrationCandidateStatus.notReady,
        currentProfile: currentProfile,
        score: readiness.score,
        eligibleSessions: eligibleSessions,
        readinessSummary: readiness,
        fieldMatrixSummary: fieldMatrix,
        evaluations: const <LiveSprintCalibrationCandidateEvaluation>[],
        blockers: const <LiveSprintCalibrationCandidateBlockerKind>[
          LiveSprintCalibrationCandidateBlockerKind.repeatabilityReadiness,
        ],
      );
    }

    final candidates = _moreStringentProfiles(currentProfile);
    if (candidates.isEmpty) {
      return _summary(
        status: LiveSprintCalibrationCandidateStatus.keepCurrent,
        currentProfile: currentProfile,
        score: _scoreFor(
          readinessScore: readiness.score,
          matrixScore: fieldMatrix.coverageScore,
          evidenceMargin: minimumEvidenceMargin,
        ),
        eligibleSessions: eligibleSessions,
        readinessSummary: readiness,
        fieldMatrixSummary: fieldMatrix,
        evaluations: const <LiveSprintCalibrationCandidateEvaluation>[],
        blockers: const <LiveSprintCalibrationCandidateBlockerKind>[
          LiveSprintCalibrationCandidateBlockerKind.noMoreStringentProfile,
        ],
      );
    }

    final evaluations = candidates
        .map((candidate) => _evaluateCandidate(candidate, eligibleSessions))
        .toList(growable: false);
    final matrixReady = fieldMatrix.isRecommendationCoverageReady;
    final recommended = matrixReady
        ? evaluations
            .where((evaluation) => evaluation.passed)
            .cast<LiveSprintCalibrationCandidateEvaluation?>()
            .firstWhere((evaluation) => evaluation != null, orElse: () => null)
        : null;

    if (recommended != null) {
      return _summary(
        status: LiveSprintCalibrationCandidateStatus.safeRecommendation,
        currentProfile: currentProfile,
        recommendedProfile: recommended.candidateProfile,
        score: _scoreFor(
          readinessScore: readiness.score,
          matrixScore: fieldMatrix.coverageScore,
          evidenceMargin: recommended.evidenceMargin,
        ),
        eligibleSessions: eligibleSessions,
        readinessSummary: readiness,
        fieldMatrixSummary: fieldMatrix,
        evaluations: evaluations,
        blockers: const <LiveSprintCalibrationCandidateBlockerKind>[],
        evidenceMargin: recommended.evidenceMargin,
      );
    }

    final blockers = <LiveSprintCalibrationCandidateBlockerKind>{
      if (!matrixReady)
        LiveSprintCalibrationCandidateBlockerKind.fieldMatrixCoverage,
      for (final evaluation in evaluations) ...evaluation.blockers,
    };
    return _summary(
      status: matrixReady
          ? LiveSprintCalibrationCandidateStatus.keepCurrent
          : LiveSprintCalibrationCandidateStatus.notReady,
      currentProfile: currentProfile,
      score: _scoreFor(
        readinessScore: readiness.score,
        matrixScore: fieldMatrix.coverageScore,
        evidenceMargin: _bestEvidenceMargin(evaluations),
      ),
      eligibleSessions: eligibleSessions,
      readinessSummary: readiness,
      fieldMatrixSummary: fieldMatrix,
      evaluations: evaluations,
      blockers: blockers.toList(growable: false),
      evidenceMargin: _bestEvidenceMargin(evaluations),
    );
  }

  List<RunningCoachSessionAnalysis> _eligibleSessionsAtOrBefore(
    List<RunningCoachSessionAnalysis> sessions, {
    required RunningCoachSessionAnalysis current,
    required SprintCaptureCalibrationProfile profile,
  }) {
    return sessions
        .where(
          (session) =>
              (session.id == current.id ||
                  !session.analyzedAt.isAfter(current.analyzedAt)) &&
              session.liveSprintReport!.calibrationProfile == profile &&
              _fieldValidationService.build(session.liveSprintReport!).isReady,
        )
        .toList(growable: false)
      ..sort((left, right) => right.analyzedAt.compareTo(left.analyzedAt));
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

  List<SprintCaptureCalibrationProfile> _moreStringentProfiles(
    SprintCaptureCalibrationProfile profile,
  ) {
    return switch (profile) {
      SprintCaptureCalibrationProfile.responsive =>
        const <SprintCaptureCalibrationProfile>[
          SprintCaptureCalibrationProfile.balanced,
          SprintCaptureCalibrationProfile.conservative,
        ],
      SprintCaptureCalibrationProfile.balanced =>
        const <SprintCaptureCalibrationProfile>[
          SprintCaptureCalibrationProfile.conservative,
        ],
      SprintCaptureCalibrationProfile.conservative =>
        const <SprintCaptureCalibrationProfile>[],
    };
  }

  LiveSprintCalibrationCandidateEvaluation _evaluateCandidate(
    SprintCaptureCalibrationProfile candidate,
    List<RunningCoachSessionAnalysis> eligibleSessions,
  ) {
    if (eligibleSessions.isEmpty) {
      return LiveSprintCalibrationCandidateEvaluation(
        candidateProfile: candidate,
        passed: false,
        evidenceMargin: 0,
        passedSessionCount: 0,
        eligibleSessionCount: 0,
        projectedCoverageScore: 0,
        holdoutSessionId: null,
        blockers: const <LiveSprintCalibrationCandidateBlockerKind>[
          LiveSprintCalibrationCandidateBlockerKind.candidateEvidence,
        ],
        failedSessionIds: const <String>[],
      );
    }

    final thresholds =
        SprintCaptureCalibrationProfileService.evidenceThresholdsFor(
      candidate,
    );
    final holdout = eligibleSessions.first;
    final failedSessionIds = <String>[];
    final blockers = <LiveSprintCalibrationCandidateBlockerKind>{};
    var minEvidenceMargin = double.infinity;
    var coveragePassedCount = 0;

    for (final session in eligibleSessions) {
      final report = session.liveSprintReport!;
      final result = _candidateSessionResult(report, thresholds);
      minEvidenceMargin = math.min(minEvidenceMargin, result.evidenceMargin);
      if (result.passed) {
        coveragePassedCount += 1;
      } else {
        failedSessionIds.add(session.id);
      }
      if (!result.evidencePassed) {
        blockers.add(
          LiveSprintCalibrationCandidateBlockerKind.candidateEvidence,
        );
      }
      if (!result.marginPassed) {
        blockers.add(
          LiveSprintCalibrationCandidateBlockerKind.evidenceMargin,
        );
      }
      if (!result.coveragePassed) {
        blockers.add(
          LiveSprintCalibrationCandidateBlockerKind.coverageRegression,
        );
      }
      if (session.id == holdout.id && !result.passed) {
        blockers.add(
          LiveSprintCalibrationCandidateBlockerKind.holdoutRegression,
        );
      }
    }

    final margin = minEvidenceMargin.isFinite ? minEvidenceMargin : 0.0;
    final projectedCoverageScore =
        ((coveragePassedCount / eligibleSessions.length) * 100)
            .round()
            .clamp(0, 100)
            .toInt();
    return LiveSprintCalibrationCandidateEvaluation(
      candidateProfile: candidate,
      passed: failedSessionIds.isEmpty && margin >= minimumEvidenceMargin,
      evidenceMargin: margin.clamp(0.0, 1.0).toDouble(),
      passedSessionCount: coveragePassedCount,
      eligibleSessionCount: eligibleSessions.length,
      projectedCoverageScore: projectedCoverageScore,
      holdoutSessionId: holdout.id,
      blockers: List<LiveSprintCalibrationCandidateBlockerKind>.unmodifiable(
        blockers,
      ),
      failedSessionIds: List<String>.unmodifiable(failedSessionIds),
    );
  }

  _CandidateSessionResult _candidateSessionResult(
    LiveSprintSessionReport report,
    SprintCaptureEvidenceThresholds thresholds,
  ) {
    final readiness = report.poseEvidenceDiagnostic.readinessSummary;
    final evidenceValues = <double>[
      _ratio(readiness.sideView.value) - thresholds.minimumSideViewConfidence,
      _ratio(readiness.coreJointConfidence.value) -
          thresholds.minimumAverageLandmarkConfidence,
      _ratio(readiness.gaitPhase.value) - thresholds.minimumPhaseConfidence,
      _ratio(report.sprintTrackingConfidence) -
          thresholds.minimumTrackingConfidence,
      _minimumPersistedJointMargin(report, thresholds),
    ];
    final evidenceMargin = evidenceValues.reduce(math.min);
    final evidencePassed = evidenceMargin >= 0;
    final marginPassed = evidenceMargin >= minimumEvidenceMargin;
    final coveragePassed = _hasNoCoverageRegression(report, thresholds);
    return _CandidateSessionResult(
      evidencePassed: evidencePassed,
      marginPassed: marginPassed,
      coveragePassed: coveragePassed,
      evidenceMargin: evidenceMargin,
    );
  }

  double _minimumPersistedJointMargin(
    LiveSprintSessionReport report,
    SprintCaptureEvidenceThresholds thresholds,
  ) {
    final observed = report.poseEvidence
        .expand((evidence) => evidence.joints)
        .where((joint) => joint.observed && joint.confidence.isFinite)
        .map((joint) => joint.confidence.clamp(0.0, 1.0).toDouble())
        .toList(growable: false);
    if (observed.isEmpty) {
      return 0 - thresholds.minimumLandmarkConfidence;
    }
    return observed.reduce(math.min) - thresholds.minimumLandmarkConfidence;
  }

  bool _hasNoCoverageRegression(
    LiveSprintSessionReport report,
    SprintCaptureEvidenceThresholds thresholds,
  ) {
    final currentPhaseCount = math.max(
      report.poseEvidence.map((evidence) => evidence.phase).toSet().length,
      report.poseEvidenceDiagnostic.capturedPhaseCount,
    );
    final candidatePhases = report.poseEvidence
        .where(
          (evidence) =>
              evidence.quality >= thresholds.minimumAverageLandmarkConfidence &&
              evidence.sideViewConfidence >=
                  thresholds.minimumSideViewConfidence &&
              evidence.joints.where((joint) => joint.observed).every(
                    (joint) =>
                        joint.confidence >=
                        thresholds.minimumLandmarkConfidence,
                  ),
        )
        .map((evidence) => evidence.phase)
        .toSet()
        .length;
    return candidatePhases >= currentPhaseCount &&
        candidatePhases >= LiveSprintPoseEvidencePhase.values.length;
  }

  LiveSprintCalibrationCandidateSummary _summary({
    required LiveSprintCalibrationCandidateStatus status,
    required SprintCaptureCalibrationProfile currentProfile,
    required int score,
    required List<RunningCoachSessionAnalysis> eligibleSessions,
    required LiveSprintCalibrationReadinessSummary readinessSummary,
    required LiveSprintFieldValidationMatrixSummary fieldMatrixSummary,
    required List<LiveSprintCalibrationCandidateEvaluation> evaluations,
    required List<LiveSprintCalibrationCandidateBlockerKind> blockers,
    SprintCaptureCalibrationProfile? recommendedProfile,
    double? evidenceMargin,
  }) {
    return LiveSprintCalibrationCandidateSummary(
      status: status,
      currentProfile: currentProfile,
      recommendedProfile: recommendedProfile,
      score: score.clamp(0, 100).toInt(),
      eligibleSessionCount: eligibleSessions.length,
      holdoutSessionId:
          eligibleSessions.isEmpty ? null : eligibleSessions.first.id,
      evidenceMargin: (evidenceMargin ?? 0).clamp(0.0, 1.0).toDouble(),
      readinessSummary: readinessSummary,
      fieldMatrixSummary: fieldMatrixSummary,
      evaluations: List<LiveSprintCalibrationCandidateEvaluation>.unmodifiable(
        evaluations,
      ),
      blockers: List<LiveSprintCalibrationCandidateBlockerKind>.unmodifiable(
        blockers,
      ),
    );
  }

  int _scoreFor({
    required int readinessScore,
    required int matrixScore,
    required double evidenceMargin,
  }) {
    final marginScore = (evidenceMargin / 0.12).clamp(0.0, 1.0).toDouble();
    return (readinessScore.clamp(0, 100) * 0.45 +
            matrixScore.clamp(0, 100) * 0.35 +
            marginScore * 100 * 0.20)
        .round()
        .clamp(0, 100)
        .toInt();
  }

  double _bestEvidenceMargin(
    List<LiveSprintCalibrationCandidateEvaluation> evaluations,
  ) {
    if (evaluations.isEmpty) {
      return 0;
    }
    return evaluations
        .map((evaluation) => evaluation.evidenceMargin)
        .reduce(math.max)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  double _ratio(double value) {
    if (!value.isFinite) {
      return 0;
    }
    return value.clamp(0.0, 1.0).toDouble();
  }
}

class _CandidateSessionResult {
  final bool evidencePassed;
  final bool marginPassed;
  final bool coveragePassed;
  final double evidenceMargin;

  const _CandidateSessionResult({
    required this.evidencePassed,
    required this.marginPassed,
    required this.coveragePassed,
    required this.evidenceMargin,
  });

  bool get passed => evidencePassed && marginPassed && coveragePassed;
}
