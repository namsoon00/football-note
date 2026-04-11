import 'dart:ui';

import 'running_video_analysis_result.dart';

enum RunningPoseLandmarkType {
  nose,
  leftEar,
  rightEar,
  leftShoulder,
  rightShoulder,
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
  stepBack,
  moveCloser,
  centerRunner,
  turnSideways,
}

enum RunningLivePrimaryCue {
  noRunnerDetected,
  stepBack,
  moveCloser,
  centerRunner,
  turnSideways,
  keepRunning,
  lookingGood,
  postureTooUpright,
  postureTooLean,
  bounceTooHigh,
  strideTooShort,
  strideOverstride,
}

class RunningLiveCoachingState {
  final RunningLiveFramingIssue? framingIssue;
  final RunningLivePrimaryCue primaryCue;
  final RunningVideoAnalysisResult? analysisResult;
  final RunningCoachingReport? coachingReport;
  final RunningCoachingInsight? highlightedInsight;
  final int trackedFrames;

  const RunningLiveCoachingState({
    required this.primaryCue,
    this.framingIssue,
    this.analysisResult,
    this.coachingReport,
    this.highlightedInsight,
    this.trackedFrames = 0,
  });

  bool get hasStableAnalysis =>
      framingIssue == null &&
      analysisResult != null &&
      coachingReport != null &&
      highlightedInsight != null;
}
