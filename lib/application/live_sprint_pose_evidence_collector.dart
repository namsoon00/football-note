import 'dart:math' as math;

import '../domain/entities/running_coach_session.dart';
import '../domain/entities/running_live_coaching_state.dart';
import '../domain/entities/sprint_realtime_coaching_state.dart';
import '../realtime_analysis/running_coaching/running_visual_pose_tracker.dart';

/// Retains only high-confidence joint geometry for three useful sprint phases.
/// Camera pixels are deliberately never retained in a session report.
class LiveSprintPoseEvidenceCollector {
  static const double _minimumLandmarkConfidence = 0.58;
  static const double _minimumAverageLandmarkConfidence = 0.70;
  static const double _minimumTrackingConfidence = 0.70;
  static const double _minimumSideViewConfidence = 0.65;
  static const double _minimumPhaseConfidence = 0.62;
  static const Duration _maximumTouchdownCaptureDelay = Duration(
    milliseconds: 150,
  );

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

  final Map<LiveSprintPoseEvidencePhase, LiveSprintPoseEvidenceFrame>
      _bestByPhase =
      <LiveSprintPoseEvidencePhase, LiveSprintPoseEvidenceFrame>{};
  final Set<String> _seenTouchdowns = <String>{};
  DateTime? _sessionStartedAt;

  void reset({DateTime? startedAt}) {
    _bestByPhase.clear();
    _seenTouchdowns.clear();
    _sessionStartedAt = startedAt;
  }

  void record({
    required RunningVisualPoseFrame? visualFrame,
    required RunningGaitAnalysis gaitAnalysis,
    required SprintRealtimeCoachingState sprintState,
    required DateTime timestamp,
  }) {
    final frame = visualFrame;
    if (frame == null || frame.imageSize.isEmpty) {
      return;
    }
    final quality = _qualityFor(
      frame: frame,
      gaitAnalysis: gaitAnalysis,
      sprintState: sprintState,
    );
    if (quality == null) {
      return;
    }
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
  }

  List<LiveSprintPoseEvidenceFrame> snapshot() {
    return List<LiveSprintPoseEvidenceFrame>.unmodifiable(
      LiveSprintPoseEvidencePhase.values
          .map((phase) => _bestByPhase[phase])
          .whereType<LiveSprintPoseEvidenceFrame>()
          .toList(growable: false),
    );
  }

  double? _qualityFor({
    required RunningVisualPoseFrame frame,
    required RunningGaitAnalysis gaitAnalysis,
    required SprintRealtimeCoachingState sprintState,
  }) {
    final state = sprintState.stateEstimate;
    if (state.trackingReadiness != SprintTrackingReadiness.readyForAnalysis ||
        !state.bodyFullyVisible ||
        state.trackingConfidence < _minimumTrackingConfidence ||
        state.sideViewConfidence < _minimumSideViewConfidence ||
        gaitAnalysis.phaseConfidence < _minimumPhaseConfidence) {
      return null;
    }

    var totalConfidence = 0.0;
    for (final type in _requiredJoints) {
      final joint = frame.landmarks[type];
      if (joint == null ||
          joint.state != RunningVisualPoseLandmarkState.observed ||
          joint.confidence < _minimumLandmarkConfidence) {
        return null;
      }
      totalConfidence += joint.confidence;
    }
    final averageConfidence = totalConfidence / _requiredJoints.length;
    if (averageConfidence < _minimumAverageLandmarkConfidence) {
      return null;
    }
    return <double>[
      averageConfidence,
      state.trackingConfidence,
      state.sideViewConfidence,
      gaitAnalysis.phaseConfidence,
      gaitAnalysis.timingConfidence,
    ].reduce(math.min);
  }

  RunningGaitEvent? _recentTouchdown(
    Iterable<RunningGaitEvent> events,
    DateTime timestamp,
  ) {
    RunningGaitEvent? selected;
    for (final event in events) {
      if (event.type != RunningGaitEventType.touchdown ||
          event.confidence < _minimumPhaseConfidence) {
        continue;
      }
      final delay = timestamp.difference(event.timestamp);
      if (delay.isNegative || delay > _maximumTouchdownCaptureDelay) {
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
}
