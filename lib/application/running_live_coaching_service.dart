import '../domain/entities/running_live_coaching_state.dart';
import '../domain/entities/running_video_analysis_result.dart';
import '../realtime_analysis/running_coaching/running_live_analysis_pipeline.dart';
import 'running_coaching_service.dart';

class RunningLiveCoachingService {
  final RunningCoachingService _coachingService;
  final RunningLiveAnalysisPipeline _analysisPipeline;
  final Duration _cueDwellTime;

  RunningLivePrimaryCue? _activeCue;
  RunningLivePrimaryCue? _candidateCue;
  DateTime? _candidateCueSince;

  RunningLiveCoachingService({
    RunningCoachingService coachingService = const RunningCoachingService(),
    Duration analysisWindow = const Duration(milliseconds: 2400),
    int minimumTrackedFrames = 7,
    double minimumLikelihood = 0.45,
    Duration cueDwellTime = const Duration(milliseconds: 600),
    int sustainedStepBackFrames = 3,
  })  : _coachingService = coachingService,
        _analysisPipeline = RunningLiveAnalysisPipeline(
          config: RunningLiveAnalysisConfig(
            analysisWindow: analysisWindow,
            minimumTrackedFrames: minimumTrackedFrames,
            minimumLikelihood: minimumLikelihood,
            cueDwellTime: cueDwellTime,
            sustainedStepBackFrames: sustainedStepBackFrames,
          ),
        ),
        _cueDwellTime = cueDwellTime;

  void reset() {
    _analysisPipeline.reset();
    _activeCue = null;
    _candidateCue = null;
    _candidateCueSince = null;
  }

  RunningLiveCoachingState ingestObservation(
    RunningPoseObservation? observation, {
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    final snapshot = _analysisPipeline.ingestObservation(
      observation,
      timestamp: now,
    );
    final analysisResult = snapshot.analysisResult;
    final coachingReport = analysisResult == null
        ? null
        : _coachingService.buildReport(analysisResult);
    final highlightedInsight =
        coachingReport == null ? null : _pickHighlightedInsight(coachingReport);
    final rawCue = _resolvePrimaryCue(
      framingIssue: snapshot.framingIssue,
      coachingReport: coachingReport,
      highlightedInsight: highlightedInsight,
    );

    return RunningLiveCoachingState(
      framingIssue: snapshot.framingIssue,
      primaryCue: _stabilizeCue(
        rawCue,
        now: now,
        framingIssue: snapshot.framingIssue,
      ),
      analysisResult: analysisResult,
      coachingReport: coachingReport,
      highlightedInsight: highlightedInsight,
      trackedObservation: snapshot.trackedObservation,
      gaitAnalysis: snapshot.gaitAnalysis,
      trackedFrames: snapshot.trackedFrames,
    );
  }

  RunningCoachingInsight _pickHighlightedInsight(RunningCoachingReport report) {
    final primaryFocus = report.primaryFocus;
    if (primaryFocus != null) {
      return primaryFocus;
    }
    return report.insights.first;
  }

  RunningLivePrimaryCue _stabilizeCue(
    RunningLivePrimaryCue nextCue, {
    required DateTime now,
    required RunningLiveFramingIssue? framingIssue,
  }) {
    final activeCue = _activeCue;
    if (framingIssue != null ||
        activeCue == null ||
        activeCue == nextCue ||
        !_requiresDwell(activeCue, nextCue)) {
      _activeCue = nextCue;
      _candidateCue = null;
      _candidateCueSince = null;
      return nextCue;
    }

    if (_candidateCue != nextCue) {
      _candidateCue = nextCue;
      _candidateCueSince = now;
      return activeCue;
    }

    final candidateSince = _candidateCueSince;
    if (candidateSince != null &&
        now.difference(candidateSince) >= _cueDwellTime) {
      _activeCue = nextCue;
      _candidateCue = null;
      _candidateCueSince = null;
      return nextCue;
    }

    return activeCue;
  }

  bool _requiresDwell(
    RunningLivePrimaryCue activeCue,
    RunningLivePrimaryCue nextCue,
  ) {
    return _isCorrectionCue(activeCue) && _isCorrectionCue(nextCue);
  }

  bool _isCorrectionCue(RunningLivePrimaryCue cue) {
    return switch (cue) {
      RunningLivePrimaryCue.postureTooUpright ||
      RunningLivePrimaryCue.postureTooLean ||
      RunningLivePrimaryCue.bounceTooHigh ||
      RunningLivePrimaryCue.footStrikeOverstride ||
      RunningLivePrimaryCue.kneeTooStraight ||
      RunningLivePrimaryCue.kneeTooCollapsed ||
      RunningLivePrimaryCue.armTooOpen ||
      RunningLivePrimaryCue.armTooTight =>
        true,
      _ => false,
    };
  }

  RunningLivePrimaryCue _resolvePrimaryCue({
    required RunningLiveFramingIssue? framingIssue,
    required RunningCoachingReport? coachingReport,
    required RunningCoachingInsight? highlightedInsight,
  }) {
    if (framingIssue != null) {
      return switch (framingIssue) {
        RunningLiveFramingIssue.noRunnerDetected =>
          RunningLivePrimaryCue.noRunnerDetected,
        RunningLiveFramingIssue.trackingUncertain =>
          RunningLivePrimaryCue.trackingUncertain,
        RunningLiveFramingIssue.stepBack => RunningLivePrimaryCue.stepBack,
        RunningLiveFramingIssue.moveCloser => RunningLivePrimaryCue.moveCloser,
        RunningLiveFramingIssue.centerRunner =>
          RunningLivePrimaryCue.centerRunner,
        RunningLiveFramingIssue.turnSideways =>
          RunningLivePrimaryCue.turnSideways,
      };
    }

    if (coachingReport == null || highlightedInsight == null) {
      return RunningLivePrimaryCue.keepRunning;
    }

    if (highlightedInsight.quality.isLowConfidence) {
      return RunningLivePrimaryCue.keepRunning;
    }

    if (coachingReport.overallScore >= 88 &&
        highlightedInsight.status == RunningCoachStatus.good) {
      return RunningLivePrimaryCue.lookingGood;
    }

    return switch (highlightedInsight.finding) {
      RunningCoachFinding.postureTooUpright =>
        RunningLivePrimaryCue.postureTooUpright,
      RunningCoachFinding.postureTooLean =>
        RunningLivePrimaryCue.postureTooLean,
      RunningCoachFinding.bounceTooHigh => RunningLivePrimaryCue.bounceTooHigh,
      RunningCoachFinding.footStrikeOverstride =>
        RunningLivePrimaryCue.footStrikeOverstride,
      RunningCoachFinding.kneeTooStraight =>
        RunningLivePrimaryCue.kneeTooStraight,
      RunningCoachFinding.kneeTooCollapsed =>
        RunningLivePrimaryCue.kneeTooCollapsed,
      RunningCoachFinding.armTooOpen => RunningLivePrimaryCue.armTooOpen,
      RunningCoachFinding.armTooTight => RunningLivePrimaryCue.armTooTight,
      _ => RunningLivePrimaryCue.lookingGood,
    };
  }
}
