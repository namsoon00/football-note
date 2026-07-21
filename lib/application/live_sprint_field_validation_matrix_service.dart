import '../domain/entities/running_coach_session.dart';
import '../domain/entities/sprint_capture_calibration_profile.dart';
import 'live_sprint_field_validation_service.dart';

enum LiveSprintFieldValidationMatrixStatus {
  notReady,
  buildingCoverage,
  recommendationCoverageReady,
  matrixComplete,
}

enum LiveSprintFieldValidationMatrixScenario {
  rearPhoneNormalClearSide,
  rearPhoneCloseClearSide,
  rearPhoneFarClearSide,
  rearPhoneNormalPartialSide,
}

class LiveSprintFieldValidationMatrixSummary {
  final LiveSprintFieldValidationMatrixStatus status;
  final SprintCaptureCalibrationProfile calibrationProfile;
  final int eligibleSessionCount;
  final int unknownContextSessionCount;
  final int coveredScenarioCount;
  final int requiredScenarioCount;
  final int coverageScore;
  final Set<LiveSprintFieldValidationMatrixScenario> coveredScenarios;
  final List<LiveSprintFieldValidationMatrixScenario> missingScenarios;

  const LiveSprintFieldValidationMatrixSummary({
    required this.status,
    required this.calibrationProfile,
    required this.eligibleSessionCount,
    required this.unknownContextSessionCount,
    required this.coveredScenarioCount,
    required this.requiredScenarioCount,
    required this.coverageScore,
    required this.coveredScenarios,
    required this.missingScenarios,
  });

  bool get hasBaselineCoverage => coveredScenarios.contains(
        LiveSprintFieldValidationMatrixScenario.rearPhoneNormalClearSide,
      );

  bool get hasMeaningfulGeometryVariation =>
      coveredScenarios.contains(
        LiveSprintFieldValidationMatrixScenario.rearPhoneCloseClearSide,
      ) ||
      coveredScenarios.contains(
        LiveSprintFieldValidationMatrixScenario.rearPhoneFarClearSide,
      ) ||
      coveredScenarios.contains(
        LiveSprintFieldValidationMatrixScenario.rearPhoneNormalPartialSide,
      );

  bool get isRecommendationCoverageReady =>
      hasBaselineCoverage && hasMeaningfulGeometryVariation;

  bool get isMatrixComplete => missingScenarios.isEmpty;
}

class LiveSprintFieldValidationMatrixService {
  static const int requiredScenarioCount = 4;
  static const List<LiveSprintFieldValidationMatrixScenario> requiredScenarios =
      <LiveSprintFieldValidationMatrixScenario>[
    LiveSprintFieldValidationMatrixScenario.rearPhoneNormalClearSide,
    LiveSprintFieldValidationMatrixScenario.rearPhoneCloseClearSide,
    LiveSprintFieldValidationMatrixScenario.rearPhoneFarClearSide,
    LiveSprintFieldValidationMatrixScenario.rearPhoneNormalPartialSide,
  ];

  final LiveSprintFieldValidationService _fieldValidationService;

  const LiveSprintFieldValidationMatrixService({
    LiveSprintFieldValidationService fieldValidationService =
        const LiveSprintFieldValidationService(),
  }) : _fieldValidationService = fieldValidationService;

  LiveSprintFieldValidationMatrixSummary build(
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
      return _emptySummary();
    }

    final currentReport = current.liveSprintReport!;
    final profile = currentReport.calibrationProfile;
    final sessionsAtOrBeforeCurrent = liveSessions
        .where(
          (session) =>
              session.id == current.id ||
              !session.analyzedAt.isAfter(current.analyzedAt),
        )
        .toList(growable: false);
    final sameProfileReadySessions = sessionsAtOrBeforeCurrent
        .where(
          (session) =>
              session.liveSprintReport!.calibrationProfile == profile &&
              _fieldValidationService.build(session.liveSprintReport!).isReady,
        )
        .toList(growable: false);

    final covered = <LiveSprintFieldValidationMatrixScenario>{};
    var unknownContextCount = 0;
    for (final session in sameProfileReadySessions) {
      final context = session.liveSprintReport!.captureContext;
      final scenario = _scenarioFor(context);
      if (scenario == null) {
        unknownContextCount += 1;
      } else {
        covered.add(scenario);
      }
    }

    final missing = requiredScenarios
        .where((scenario) => !covered.contains(scenario))
        .toList(growable: false);
    final coverageScore = ((covered.length / requiredScenarioCount) * 100)
        .round()
        .clamp(0, 100)
        .toInt();
    final status = _statusFor(
      eligibleSessionCount: sameProfileReadySessions.length,
      covered: covered,
      missing: missing,
    );
    return LiveSprintFieldValidationMatrixSummary(
      status: status,
      calibrationProfile: profile,
      eligibleSessionCount: sameProfileReadySessions.length,
      unknownContextSessionCount: unknownContextCount,
      coveredScenarioCount: covered.length,
      requiredScenarioCount: requiredScenarioCount,
      coverageScore: coverageScore,
      coveredScenarios:
          Set<LiveSprintFieldValidationMatrixScenario>.unmodifiable(covered),
      missingScenarios:
          List<LiveSprintFieldValidationMatrixScenario>.unmodifiable(missing),
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

  LiveSprintFieldValidationMatrixScenario? _scenarioFor(
    LiveSprintCaptureContext context,
  ) {
    if (!context.hasKnownMatrixContext ||
        context.deviceClass != LiveSprintDeviceClass.phone ||
        context.cameraLensDirection != LiveSprintCameraLensDirection.rear) {
      return null;
    }
    if (context.distanceBand == LiveSprintCaptureDistanceBand.normal &&
        context.viewBand == LiveSprintViewBand.clearSide) {
      return LiveSprintFieldValidationMatrixScenario.rearPhoneNormalClearSide;
    }
    if (context.distanceBand == LiveSprintCaptureDistanceBand.close &&
        context.viewBand == LiveSprintViewBand.clearSide) {
      return LiveSprintFieldValidationMatrixScenario.rearPhoneCloseClearSide;
    }
    if (context.distanceBand == LiveSprintCaptureDistanceBand.far &&
        context.viewBand == LiveSprintViewBand.clearSide) {
      return LiveSprintFieldValidationMatrixScenario.rearPhoneFarClearSide;
    }
    if (context.distanceBand == LiveSprintCaptureDistanceBand.normal &&
        context.viewBand == LiveSprintViewBand.partialSide) {
      return LiveSprintFieldValidationMatrixScenario.rearPhoneNormalPartialSide;
    }
    return null;
  }

  LiveSprintFieldValidationMatrixStatus _statusFor({
    required int eligibleSessionCount,
    required Set<LiveSprintFieldValidationMatrixScenario> covered,
    required List<LiveSprintFieldValidationMatrixScenario> missing,
  }) {
    if (eligibleSessionCount == 0 || covered.isEmpty) {
      return LiveSprintFieldValidationMatrixStatus.notReady;
    }
    final hasBaseline = covered.contains(
      LiveSprintFieldValidationMatrixScenario.rearPhoneNormalClearSide,
    );
    final hasVariation = covered.contains(
          LiveSprintFieldValidationMatrixScenario.rearPhoneCloseClearSide,
        ) ||
        covered.contains(
          LiveSprintFieldValidationMatrixScenario.rearPhoneFarClearSide,
        ) ||
        covered.contains(
          LiveSprintFieldValidationMatrixScenario.rearPhoneNormalPartialSide,
        );
    if (missing.isEmpty) {
      return LiveSprintFieldValidationMatrixStatus.matrixComplete;
    }
    if (hasBaseline && hasVariation) {
      return LiveSprintFieldValidationMatrixStatus.recommendationCoverageReady;
    }
    return LiveSprintFieldValidationMatrixStatus.buildingCoverage;
  }

  LiveSprintFieldValidationMatrixSummary _emptySummary() {
    return const LiveSprintFieldValidationMatrixSummary(
      status: LiveSprintFieldValidationMatrixStatus.notReady,
      calibrationProfile: SprintCaptureCalibrationProfile.balanced,
      eligibleSessionCount: 0,
      unknownContextSessionCount: 0,
      coveredScenarioCount: 0,
      requiredScenarioCount: requiredScenarioCount,
      coverageScore: 0,
      coveredScenarios: <LiveSprintFieldValidationMatrixScenario>{},
      missingScenarios: requiredScenarios,
    );
  }
}
