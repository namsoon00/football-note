import 'dart:math' as math;

import '../domain/entities/running_coach_session.dart';
import '../domain/entities/running_live_coaching_state.dart';
import '../domain/entities/sprint_realtime_coaching_state.dart';
import '../realtime_analysis/running_coaching/running_visual_pose_tracker.dart';
import 'sprint_capture_calibration_service.dart';

/// Retains only high-confidence joint geometry for three useful sprint phases.
/// Camera pixels are deliberately never retained in a session report.
class LiveSprintPoseEvidenceCollector {
  static const List<RunningPoseLandmarkType> _requiredJoints =
      <RunningPoseLandmarkType>[
    RunningPoseLandmarkType.nose,
    RunningPoseLandmarkType.leftShoulder,
    RunningPoseLandmarkType.rightShoulder,
    RunningPoseLandmarkType.leftElbow,
    RunningPoseLandmarkType.rightElbow,
    RunningPoseLandmarkType.leftHip,
    RunningPoseLandmarkType.rightHip,
    RunningPoseLandmarkType.leftKnee,
    RunningPoseLandmarkType.rightKnee,
    RunningPoseLandmarkType.leftAnkle,
    RunningPoseLandmarkType.rightAnkle,
    RunningPoseLandmarkType.leftHeel,
    RunningPoseLandmarkType.rightHeel,
    RunningPoseLandmarkType.leftFootIndex,
    RunningPoseLandmarkType.rightFootIndex,
  ];

  SprintCaptureEvidenceThresholds _thresholds;
  final Map<LiveSprintPoseEvidencePhase, LiveSprintPoseEvidenceFrame>
      _bestByPhase =
      <LiveSprintPoseEvidencePhase, LiveSprintPoseEvidenceFrame>{};
  final Set<String> _seenTouchdowns = <String>{};
  DateTime? _sessionStartedAt;
  int _evaluatedFrames = 0;
  int _eligibleFrames = 0;
  int _fullBodyBlockedFrames = 0;
  int _sideViewBlockedFrames = 0;
  int _coreJointsBlockedFrames = 0;
  int _gaitPhaseBlockedFrames = 0;
  LiveSprintPoseEvidenceBlocker? _currentBlocker;
  LiveSprintCaptureReadinessSummary _latestReadiness;

  LiveSprintPoseEvidenceCollector({
    SprintCaptureEvidenceThresholds thresholds =
        const SprintCaptureEvidenceThresholds.balanced(),
  })  : _thresholds = thresholds,
        _latestReadiness = _initialReadinessSummary(thresholds);

  void updateThresholds(SprintCaptureEvidenceThresholds thresholds) {
    _thresholds = thresholds;
    _latestReadiness = _initialReadinessSummary(thresholds);
  }

  void reset({DateTime? startedAt}) {
    _bestByPhase.clear();
    _seenTouchdowns.clear();
    _sessionStartedAt = startedAt;
    _evaluatedFrames = 0;
    _eligibleFrames = 0;
    _fullBodyBlockedFrames = 0;
    _sideViewBlockedFrames = 0;
    _coreJointsBlockedFrames = 0;
    _gaitPhaseBlockedFrames = 0;
    _currentBlocker = null;
    _latestReadiness = _initialReadinessSummary(_thresholds);
  }

  void record({
    required RunningVisualPoseFrame? visualFrame,
    required RunningGaitAnalysis gaitAnalysis,
    required SprintRealtimeCoachingState sprintState,
    required DateTime timestamp,
  }) {
    final frame = visualFrame;
    _evaluatedFrames += 1;
    if (frame == null || frame.imageSize.isEmpty) {
      _latestReadiness = _readinessFor(
        frame: null,
        gaitAnalysis: gaitAnalysis,
        sprintState: sprintState,
      );
      _recordBlocker(LiveSprintPoseEvidenceBlocker.fullBodyVisibility);
      return;
    }
    final validation = _validationFor(
      frame: frame,
      gaitAnalysis: gaitAnalysis,
      sprintState: sprintState,
    );
    if (validation.blocker case final blocker?) {
      _recordBlocker(blocker);
      return;
    }
    final quality = validation.quality!;
    _eligibleFrames += 1;
    _sessionStartedAt ??= timestamp;

    final touchdown = _recentTouchdown(gaitAnalysis.recentEvents, timestamp);
    if (touchdown != null) {
      final eventKey =
          '${touchdown.side.name}:${touchdown.timestamp.microsecondsSinceEpoch}';
      if (_seenTouchdowns.add(eventKey)) {
        _consider(
          _buildEvidence(
            frame: frame,
            phase: LiveSprintPoseEvidencePhase.touchdown,
            quality: math.min(quality, touchdown.confidence),
            sideViewConfidence: sprintState.stateEstimate.sideViewConfidence,
            timestamp: timestamp,
            leadFoot: touchdown.side,
          ),
        );
      }
      _currentBlocker = null;
      return;
    }

    final phase = switch (gaitAnalysis.currentPhase) {
      RunningGaitPhase.leftContact ||
      RunningGaitPhase.rightContact ||
      RunningGaitPhase.doubleContact =>
        LiveSprintPoseEvidencePhase.support,
      RunningGaitPhase.flight => LiveSprintPoseEvidencePhase.flight,
      RunningGaitPhase.unknown => null,
    };
    if (phase == null) {
      _recordBlocker(LiveSprintPoseEvidenceBlocker.gaitPhaseReadiness);
      return;
    }
    _consider(
      _buildEvidence(
        frame: frame,
        phase: phase,
        quality: quality,
        sideViewConfidence: sprintState.stateEstimate.sideViewConfidence,
        timestamp: timestamp,
        leadFoot: switch (gaitAnalysis.currentPhase) {
          RunningGaitPhase.leftContact => RunningFootSide.left,
          RunningGaitPhase.rightContact => RunningFootSide.right,
          _ => null,
        },
      ),
    );
    _currentBlocker = null;
  }

  List<LiveSprintPoseEvidenceFrame> snapshot() {
    return List<LiveSprintPoseEvidenceFrame>.unmodifiable(
      LiveSprintPoseEvidencePhase.values
          .map((phase) => _bestByPhase[phase])
          .whereType<LiveSprintPoseEvidenceFrame>()
          .toList(growable: false),
    );
  }

  LiveSprintPoseEvidenceDiagnostic diagnosticSnapshot() {
    return LiveSprintPoseEvidenceDiagnostic(
      evaluatedFrames: _evaluatedFrames,
      eligibleFrames: _eligibleFrames,
      capturedPhaseCount: _bestByPhase.length,
      fullBodyBlockedFrames: _fullBodyBlockedFrames,
      sideViewBlockedFrames: _sideViewBlockedFrames,
      coreJointsBlockedFrames: _coreJointsBlockedFrames,
      gaitPhaseBlockedFrames: _gaitPhaseBlockedFrames,
      currentBlocker: _currentBlocker,
      readinessSummary: _latestReadiness,
    );
  }

  _EvidenceValidation _validationFor({
    required RunningVisualPoseFrame frame,
    required RunningGaitAnalysis gaitAnalysis,
    required SprintRealtimeCoachingState sprintState,
  }) {
    final readiness = _readinessFor(
      frame: frame,
      gaitAnalysis: gaitAnalysis,
      sprintState: sprintState,
    );
    _latestReadiness = readiness;

    if (!readiness.framing.ready) {
      return const _EvidenceValidation.blocked(
        LiveSprintPoseEvidenceBlocker.fullBodyVisibility,
      );
    }
    if (!readiness.sideView.ready) {
      return const _EvidenceValidation.blocked(
        LiveSprintPoseEvidenceBlocker.stableSideView,
      );
    }
    if (!readiness.coreJointConfidence.ready) {
      return const _EvidenceValidation.blocked(
        LiveSprintPoseEvidenceBlocker.observedCoreJoints,
      );
    }
    if (!readiness.gaitPhase.ready) {
      return const _EvidenceValidation.blocked(
        LiveSprintPoseEvidenceBlocker.gaitPhaseReadiness,
      );
    }

    return _eligibleValidation(readiness);
  }

  LiveSprintCaptureReadinessSummary _readinessFor({
    required RunningVisualPoseFrame? frame,
    required RunningGaitAnalysis gaitAnalysis,
    required SprintRealtimeCoachingState sprintState,
  }) {
    final state = sprintState.stateEstimate;
    final hasFrame = frame != null && !frame.imageSize.isEmpty;
    final framingReady = hasFrame &&
        state.bodyFullyVisible &&
        state.trackingReadiness != SprintTrackingReadiness.bodyTooSmall &&
        state.trackingReadiness !=
            SprintTrackingReadiness.bodyPartiallyOutOfFrame;
    final sideViewValue = state.sideViewConfidence.clamp(0.0, 1.0).toDouble();
    final sideViewReady = hasFrame &&
        state.trackingReadiness != SprintTrackingReadiness.sideViewUnstable &&
        sideViewValue >= _thresholds.minimumSideViewConfidence;

    var totalConfidence = 0.0;
    var observedRequiredJoints = 0;
    if (frame != null && !frame.imageSize.isEmpty) {
      for (final type in _requiredJoints) {
        final joint = frame.landmarks[type];
        if (joint != null &&
            joint.state == RunningVisualPoseLandmarkState.observed) {
          totalConfidence += joint.confidence.clamp(0.0, 1.0).toDouble();
          if (joint.confidence >= _thresholds.minimumLandmarkConfidence) {
            observedRequiredJoints += 1;
          }
        }
      }
    }
    final averageConfidence = hasFrame
        ? (totalConfidence / _requiredJoints.length).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final coreConfidence = math
        .min(
          averageConfidence,
          state.trackingConfidence.clamp(0.0, 1.0).toDouble(),
        )
        .clamp(0.0, 1.0)
        .toDouble();
    final coreJointsReady = hasFrame &&
        state.trackingReadiness != SprintTrackingReadiness.lowConfidence &&
        state.trackingConfidence >= _thresholds.minimumTrackingConfidence &&
        observedRequiredJoints == _requiredJoints.length &&
        averageConfidence >= _thresholds.minimumAverageLandmarkConfidence;
    final gaitPhaseValue = math
        .min(
          gaitAnalysis.phaseConfidence.clamp(0.0, 1.0).toDouble(),
          gaitAnalysis.timingConfidence.clamp(0.0, 1.0).toDouble(),
        )
        .clamp(0.0, 1.0)
        .toDouble();
    final gaitPhaseReady =
        gaitAnalysis.currentPhase != RunningGaitPhase.unknown &&
            gaitPhaseValue >= _thresholds.minimumPhaseConfidence;

    return LiveSprintCaptureReadinessSummary(
      framing: LiveSprintCaptureReadinessCheck(
        ready: framingReady,
        value: hasFrame
            ? state.bodyVisibilityRatio.clamp(0.0, 1.0).toDouble()
            : 0.0,
        threshold: 1,
      ),
      sideView: LiveSprintCaptureReadinessCheck(
        ready: sideViewReady,
        value: sideViewValue,
        threshold: _thresholds.minimumSideViewConfidence,
      ),
      coreJointConfidence: LiveSprintCaptureReadinessCheck(
        ready: coreJointsReady,
        value: coreConfidence,
        threshold: _thresholds.minimumAverageLandmarkConfidence,
        observedCount: observedRequiredJoints,
        requiredCount: _requiredJoints.length,
      ),
      gaitPhase: LiveSprintCaptureReadinessCheck(
        ready: gaitPhaseReady,
        value: gaitPhaseValue,
        threshold: _thresholds.minimumPhaseConfidence,
      ),
    );
  }

  static LiveSprintCaptureReadinessSummary _initialReadinessSummary(
    SprintCaptureEvidenceThresholds thresholds,
  ) {
    return LiveSprintCaptureReadinessSummary(
      framing: const LiveSprintCaptureReadinessCheck(
        ready: false,
        value: 0,
        threshold: 1,
      ),
      sideView: LiveSprintCaptureReadinessCheck(
        ready: false,
        value: 0,
        threshold: thresholds.minimumSideViewConfidence,
      ),
      coreJointConfidence: LiveSprintCaptureReadinessCheck(
        ready: false,
        value: 0,
        threshold: thresholds.minimumAverageLandmarkConfidence,
        observedCount: 0,
        requiredCount: _requiredJoints.length,
      ),
      gaitPhase: LiveSprintCaptureReadinessCheck(
        ready: false,
        value: 0,
        threshold: thresholds.minimumPhaseConfidence,
      ),
    );
  }

  double _qualityFor({
    required LiveSprintCaptureReadinessSummary readiness,
  }) {
    var totalConfidence = 0.0;
    totalConfidence += readiness.framing.value;
    totalConfidence += readiness.sideView.value;
    totalConfidence += readiness.coreJointConfidence.value;
    totalConfidence += readiness.gaitPhase.value;
    return (totalConfidence / 4).clamp(0.0, 1.0).toDouble();
  }

  _EvidenceValidation _eligibleValidation(
    LiveSprintCaptureReadinessSummary readiness,
  ) {
    return _EvidenceValidation.eligible(
      math.min(
        _qualityFor(readiness: readiness),
        <double>[
          readiness.coreJointConfidence.value,
          readiness.sideView.value,
          readiness.gaitPhase.value,
        ].reduce(math.min),
      ),
    );
  }

  RunningGaitEvent? _recentTouchdown(
    Iterable<RunningGaitEvent> events,
    DateTime timestamp,
  ) {
    RunningGaitEvent? selected;
    for (final event in events) {
      if (event.type != RunningGaitEventType.touchdown ||
          event.confidence < _thresholds.minimumPhaseConfidence) {
        continue;
      }
      final delay = timestamp.difference(event.timestamp);
      if (delay.isNegative ||
          delay > _thresholds.maximumTouchdownCaptureDelay) {
        continue;
      }
      if (selected == null || event.timestamp.isAfter(selected.timestamp)) {
        selected = event;
      }
    }
    return selected;
  }

  LiveSprintPoseEvidenceFrame _buildEvidence({
    required RunningVisualPoseFrame frame,
    required LiveSprintPoseEvidencePhase phase,
    required double quality,
    required double sideViewConfidence,
    required DateTime timestamp,
    required RunningFootSide? leadFoot,
  }) {
    final sourceWidth = frame.imageSize.width;
    final sourceHeight = frame.imageSize.height;
    final sessionStartedAt = _sessionStartedAt ?? timestamp;
    return LiveSprintPoseEvidenceFrame(
      phase: phase,
      capturedOffsetMs: math.max(
        0,
        timestamp.difference(sessionStartedAt).inMilliseconds,
      ),
      quality: quality.clamp(0.0, 1.0),
      sideViewConfidence: sideViewConfidence.clamp(0.0, 1.0),
      imageAspectRatio: (sourceWidth / sourceHeight).clamp(0.2, 4.0),
      leadFoot: leadFoot,
      joints: frame.landmarks.entries
          .map(
            (entry) => LiveSprintPoseEvidenceJoint(
              type: entry.key,
              x: (entry.value.position.dx / sourceWidth).clamp(0.0, 1.0),
              y: (entry.value.position.dy / sourceHeight).clamp(0.0, 1.0),
              z: entry.value.z,
              confidence: entry.value.confidence.clamp(0.0, 1.0),
              observed:
                  entry.value.state == RunningVisualPoseLandmarkState.observed,
            ),
          )
          .toList(growable: false),
    );
  }

  void _consider(LiveSprintPoseEvidenceFrame candidate) {
    final current = _bestByPhase[candidate.phase];
    if (current == null || candidate.quality > current.quality) {
      _bestByPhase[candidate.phase] = candidate;
    }
  }

  void _recordBlocker(LiveSprintPoseEvidenceBlocker blocker) {
    _currentBlocker = blocker;
    switch (blocker) {
      case LiveSprintPoseEvidenceBlocker.fullBodyVisibility:
        _fullBodyBlockedFrames += 1;
      case LiveSprintPoseEvidenceBlocker.stableSideView:
        _sideViewBlockedFrames += 1;
      case LiveSprintPoseEvidenceBlocker.observedCoreJoints:
        _coreJointsBlockedFrames += 1;
      case LiveSprintPoseEvidenceBlocker.gaitPhaseReadiness:
        _gaitPhaseBlockedFrames += 1;
    }
  }
}

class _EvidenceValidation {
  final double? quality;
  final LiveSprintPoseEvidenceBlocker? blocker;

  const _EvidenceValidation.eligible(this.quality) : blocker = null;

  const _EvidenceValidation.blocked(this.blocker) : quality = null;
}
