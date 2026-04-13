import 'dart:collection';

import '../../domain/entities/sprint_pose_frame.dart';
import '../../domain/entities/sprint_realtime_coaching_state.dart';
import 'sprint_feature_calculator.dart';
import 'sprint_feedback_rule_engine.dart';
import 'sprint_landmark_smoother.dart';
import 'sprint_pipeline_config.dart';
import 'sprint_pose_normalizer.dart';
import 'sprint_state_estimator.dart';

class SprintRealtimeCoachingPipeline {
  final SprintPipelineConfig config;
  final SprintLandmarkSmoother _smoother;
  final SprintPoseNormalizer _normalizer;
  final SprintFeatureCalculator _featureCalculator;
  final SprintStateEstimator _stateEstimator;
  final SprintFeedbackRuleEngine _feedbackRuleEngine;

  final Queue<SprintPoseFrame> _rawWindow = Queue<SprintPoseFrame>();
  final Queue<SprintNormalizedPoseFrame> _normalizedWindow =
      Queue<SprintNormalizedPoseFrame>();

  SprintFeedbackMessage? _activeFeedback;
  DateTime? _lastFeedbackAt;
  int _processedFrames = 0;

  SprintRealtimeCoachingPipeline({
    this.config = const SprintPipelineConfig(),
    SprintLandmarkSmoother? smoother,
    SprintPoseNormalizer? normalizer,
    SprintFeatureCalculator? featureCalculator,
    SprintStateEstimator? stateEstimator,
    SprintFeedbackRuleEngine? feedbackRuleEngine,
  })  : _smoother = smoother ?? SprintLandmarkSmoother(),
        _normalizer = normalizer ?? SprintPoseNormalizer(),
        _featureCalculator = featureCalculator ?? SprintFeatureCalculator(),
        _stateEstimator = stateEstimator ?? SprintStateEstimator(),
        _feedbackRuleEngine =
            feedbackRuleEngine ?? const SprintFeedbackRuleEngine();

  void reset() {
    _rawWindow.clear();
    _normalizedWindow.clear();
    _smoother.reset();
    _activeFeedback = null;
    _lastFeedbackAt = null;
    _processedFrames = 0;
  }

  SprintRealtimeCoachingState ingest(
    SprintPoseFrame? frame, {
    DateTime? timestamp,
  }) {
    final now = timestamp ?? frame?.timestamp ?? DateTime.now();
    _processedFrames += 1;

    if (frame != null) {
      final filteredFrame = _filterLowConfidenceLandmarks(frame);
      _rawWindow.add(filteredFrame);

      final smoothedFrame = _smoother.smooth(
        filteredFrame,
        alpha: config.smoothingFactor,
      );
      final normalizedFrame = _normalizer.normalize(
        smoothedFrame,
        minimumConfidence: config.minimumLandmarkConfidence,
      );
      if (normalizedFrame != null) {
        _normalizedWindow.add(normalizedFrame);
      }
    }

    _trimWindows(now);

    final rawFrames = _rawWindow.toList(growable: false);
    final normalizedFrames = _normalizedWindow.toList(growable: false);
    final features = _featureCalculator.calculate(
      normalizedFrames,
      minimumStepEventInterval: config.minimumStepEventInterval,
      stepDetectionHysteresis: config.stepDetectionHysteresis,
      minimumStepDetectionVelocity: config.minimumStepDetectionVelocity,
    );
    final stateEstimate = _stateEstimator.estimate(
      rawFrames: rawFrames,
      normalizedFrames: normalizedFrames,
      features: features,
      config: config,
      now: now,
      lastFeedbackAt: _lastFeedbackAt,
    );
    final feedbackResolution = _resolveFeedback(
      now: now,
      features: features,
      stateEstimate: stateEstimate,
    );
    final nextFeedback = feedbackResolution.feedback;

    return SprintRealtimeCoachingState(
      status: _resolveStatus(
        stateEstimate: stateEstimate,
        feedback: nextFeedback,
        features: features,
      ),
      features: features,
      stateEstimate: stateEstimate,
      feedback: nextFeedback,
      processedFrames: _processedFrames,
      trackedFrames: normalizedFrames.length,
      lastFeedbackAt: _lastFeedbackAt,
      feedbackSwitchSuppressedByCooldown:
          feedbackResolution.suppressedByCooldown,
    );
  }

  SprintPoseFrame _filterLowConfidenceLandmarks(SprintPoseFrame frame) {
    final filtered = <SprintPoseLandmarkType, SprintPoseLandmark>{
      for (final entry in frame.landmarks.entries)
        if (entry.value.confidence >= config.minimumLandmarkConfidence)
          entry.key: entry.value,
    };
    return frame.copyWith(landmarks: filtered);
  }

  void _trimWindows(DateTime now) {
    while (_rawWindow.isNotEmpty &&
        now.difference(_rawWindow.first.timestamp) > config.analysisWindow) {
      _rawWindow.removeFirst();
    }

    while (_normalizedWindow.isNotEmpty &&
        now.difference(_normalizedWindow.first.timestamp) >
            config.analysisWindow) {
      _normalizedWindow.removeFirst();
    }
  }

  _FeedbackResolution _resolveFeedback({
    required DateTime now,
    required SprintFeatureSnapshot features,
    required SprintStateEstimate stateEstimate,
  }) {
    final selected = _feedbackRuleEngine.selectFeedback(
      features: features,
      stateEstimate: stateEstimate,
      config: config,
      activeFeedback: _activeFeedback,
    );
    if (selected == null) {
      if (!stateEstimate.feedbackCooldownActive ||
          !stateEstimate.runningDetected) {
        _activeFeedback = null;
      }
      return _FeedbackResolution(
        feedback: _activeFeedback,
        suppressedByCooldown: false,
      );
    }

    if (selected.code == SprintFeedbackCode.bodyNotVisible) {
      _activeFeedback = selected;
      return _FeedbackResolution(
        feedback: _activeFeedback,
        suppressedByCooldown: false,
      );
    }

    if (stateEstimate.feedbackCooldownActive &&
        _activeFeedback != null &&
        _activeFeedback!.code != selected.code) {
      return _FeedbackResolution(
        feedback: _activeFeedback,
        suppressedByCooldown: true,
      );
    }

    if (_activeFeedback?.code != selected.code) {
      _lastFeedbackAt = now;
      _activeFeedback = selected;
      return _FeedbackResolution(
        feedback: _activeFeedback,
        suppressedByCooldown: false,
      );
    }

    _activeFeedback = selected;
    return _FeedbackResolution(
      feedback: _activeFeedback,
      suppressedByCooldown: false,
    );
  }

  SprintCoachingStatus _resolveStatus({
    required SprintStateEstimate stateEstimate,
    required SprintFeedbackMessage? feedback,
    required SprintFeatureSnapshot features,
  }) {
    if (stateEstimate.lowConfidence || !stateEstimate.bodyFullyVisible) {
      return SprintCoachingStatus.lowConfidence;
    }

    if (!stateEstimate.runningDetected || !features.hasEnoughSignal) {
      return SprintCoachingStatus.collecting;
    }

    if (feedback == null) {
      return SprintCoachingStatus.ready;
    }

    return SprintCoachingStatus.coaching;
  }
}

class _FeedbackResolution {
  final SprintFeedbackMessage? feedback;
  final bool suppressedByCooldown;

  const _FeedbackResolution({
    required this.feedback,
    required this.suppressedByCooldown,
  });
}
