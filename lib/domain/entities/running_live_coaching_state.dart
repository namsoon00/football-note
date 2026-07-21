import 'dart:ui';

import 'running_video_analysis_result.dart';

enum RunningPoseLandmarkType {
  nose,
  leftEar,
  rightEar,
  leftShoulder,
  rightShoulder,
  leftElbow,
  rightElbow,
  leftWrist,
  rightWrist,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
  leftHeel,
  rightHeel,
  leftFootIndex,
  rightFootIndex,
}

class RunningPoseLandmark {
  final Offset position;
  final double likelihood;

  const RunningPoseLandmark({
    required this.position,
    required this.likelihood,
  });
}

class RunningPoseObservation {
  final Size imageSize;
  final Map<RunningPoseLandmarkType, RunningPoseLandmark> landmarks;

  const RunningPoseObservation({
    required this.imageSize,
    required this.landmarks,
  });

  RunningPoseLandmark? landmark(
    RunningPoseLandmarkType type, {
    double minimumLikelihood = 0,
  }) {
    final landmark = landmarks[type];
    if (landmark == null || landmark.likelihood < minimumLikelihood) {
      return null;
    }
    return landmark;
  }
}

enum RunningLiveFramingIssue {
  noRunnerDetected,
  trackingUncertain,
  stepBack,
  moveCloser,
  centerRunner,
  turnSideways,
}

enum RunningLivePrimaryCue {
  noRunnerDetected,
  trackingUncertain,
  stepBack,
  moveCloser,
  centerRunner,
  turnSideways,
  keepRunning,
  lookingGood,
  postureTooUpright,
  postureTooLean,
  bounceTooHigh,
  footStrikeOverstride,
  kneeTooStraight,
  kneeTooCollapsed,
  armTooOpen,
  armTooTight,
}

enum RunningFootSide { left, right }

enum RunningGaitEventType { touchdown, toeOff }

enum RunningGaitPhase {
  unknown,
  flight,
  leftContact,
  rightContact,
  doubleContact,
}

class RunningGaitEvent {
  final RunningFootSide side;
  final RunningGaitEventType type;
  final DateTime timestamp;
  final double confidence;

  const RunningGaitEvent({
    required this.side,
    required this.type,
    required this.timestamp,
    required this.confidence,
  });
}

class RunningGaitMetric {
  final double? value;
  final double confidence;
  final bool available;
  final String? reasonIfUnavailable;
  final int sampleCount;

  const RunningGaitMetric({
    required this.value,
    required this.confidence,
    required this.available,
    required this.reasonIfUnavailable,
    required this.sampleCount,
  });

  const RunningGaitMetric.unavailable({
    this.confidence = 0,
    this.reasonIfUnavailable,
    this.sampleCount = 0,
  })  : value = null,
        available = false;

  const RunningGaitMetric.available({
    required this.value,
    required this.confidence,
    required this.sampleCount,
  })  : available = true,
        reasonIfUnavailable = null;
}

class RunningGaitAnalysis {
  final RunningGaitPhase currentPhase;
  final double phaseConfidence;
  final RunningGaitMetric cadence;
  final RunningGaitMetric leftContactDuration;
  final RunningGaitMetric rightContactDuration;
  final List<RunningGaitEvent> recentEvents;
  final int touchdownCount;
  final int toeOffCount;
  final int validFrameCount;
  final double timingConfidence;
  final double sideViewConfidence;

  const RunningGaitAnalysis({
    required this.currentPhase,
    required this.phaseConfidence,
    required this.cadence,
    required this.leftContactDuration,
    required this.rightContactDuration,
    required this.recentEvents,
    required this.touchdownCount,
    required this.toeOffCount,
    required this.validFrameCount,
    required this.timingConfidence,
    required this.sideViewConfidence,
  });

  const RunningGaitAnalysis.empty()
      : currentPhase = RunningGaitPhase.unknown,
        phaseConfidence = 0,
        cadence = const RunningGaitMetric.unavailable(
          reasonIfUnavailable: 'insufficient_gait_events',
        ),
        leftContactDuration = const RunningGaitMetric.unavailable(
          reasonIfUnavailable: 'insufficient_contact_events',
        ),
        rightContactDuration = const RunningGaitMetric.unavailable(
          reasonIfUnavailable: 'insufficient_contact_events',
        ),
        recentEvents = const <RunningGaitEvent>[],
        touchdownCount = 0,
        toeOffCount = 0,
        validFrameCount = 0,
        timingConfidence = 0,
        sideViewConfidence = 0;
}

class RunningLiveCoachingState {
  final RunningLiveFramingIssue? framingIssue;
  final RunningLivePrimaryCue primaryCue;
  final RunningVideoAnalysisResult? analysisResult;
  final RunningCoachingReport? coachingReport;
  final RunningCoachingInsight? highlightedInsight;
  final RunningPoseObservation? trackedObservation;
  final RunningGaitAnalysis gaitAnalysis;
  final int trackedFrames;

  const RunningLiveCoachingState({
    required this.primaryCue,
    this.framingIssue,
    this.analysisResult,
    this.coachingReport,
    this.highlightedInsight,
    this.trackedObservation,
    this.gaitAnalysis = const RunningGaitAnalysis.empty(),
    this.trackedFrames = 0,
  });

  bool get hasStableAnalysis =>
      framingIssue == null &&
      analysisResult != null &&
      coachingReport != null &&
      highlightedInsight != null &&
      !highlightedInsight!.quality.isLowConfidence;
}
