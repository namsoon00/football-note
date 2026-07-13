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
  final _SprintSessionReferenceTracker _sessionReferenceTracker =
      _SprintSessionReferenceTracker();

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
    _sessionReferenceTracker.reset();
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
        maxDisplacementRatio: config.outlierJointDisplacementRatio,
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
    final calculatedFeatures = _featureCalculator.calculate(
      normalizedFrames,
      minimumStepEventInterval: config.minimumStepEventInterval,
      stepDetectionHysteresis: config.stepDetectionHysteresis,
      minimumStepDetectionVelocity: config.minimumStepDetectionVelocity,
      footContactGroundClearanceRatio: config.footContactGroundClearanceRatio,
      flightGroundClearanceRatio: config.flightGroundClearanceRatio,
    );
    final features = _sessionReferenceTracker.annotate(
      calculatedFeatures,
      config: config,
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
          !stateEstimate.runningDetected ||
          stateEstimate.trackingReadiness !=
              SprintTrackingReadiness.readyForAnalysis) {
        _activeFeedback = null;
      }
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
    if (stateEstimate.trackingReadiness !=
        SprintTrackingReadiness.readyForAnalysis) {
      return SprintCoachingStatus.lowConfidence;
    }

    if (!stateEstimate.runningDetected || !features.hasEnoughSignal) {
      return SprintCoachingStatus.collecting;
    }

    if (feedback == null || feedback.severity == SprintFeedbackSeverity.info) {
      return SprintCoachingStatus.ready;
    }

    return SprintCoachingStatus.coaching;
  }
}

class _SprintSessionReferenceTracker {
  double? _bestKneeDriveHeight;
  double? _bestTrunkAngleDegrees;
  double? _bestRhythmStdMs;
  int _referenceSampleCount = 0;

  void reset() {
    _bestKneeDriveHeight = null;
    _bestTrunkAngleDegrees = null;
    _bestRhythmStdMs = null;
    _referenceSampleCount = 0;
  }

  SprintFeatureSnapshot annotate(
    SprintFeatureSnapshot features, {
    required SprintPipelineConfig config,
  }) {
    final referenceReady = _referenceSampleCount >= 4;
    final kneeDeltaRatio = _deltaRatioFromBest(
      current: features.kneeDriveHeightRatio,
      best: _bestKneeDriveHeight,
    );
    final trunkDeltaDegrees = _deltaFromBest(
      current: features.trunkAngleDegrees,
      best: _bestTrunkAngleDegrees,
    );
    final rhythmDeltaMs = _increaseFromBest(
      current: features.stepIntervalStdMs,
      best: _bestRhythmStdMs,
    );
    final baselineDropScore = _baselineDropScore(
      kneeDeltaRatio: kneeDeltaRatio,
      trunkDeltaDegrees: trunkDeltaDegrees,
      rhythmDeltaMs: rhythmDeltaMs,
      config: config,
    );
    final annotated = features.copyWith(
      sessionReferenceReady: referenceReady,
      sessionKneeDriveDeltaRatio: referenceReady ? kneeDeltaRatio : null,
      clearSessionKneeDriveDeltaRatio: !referenceReady,
      sessionTrunkAngleDeltaDegrees: referenceReady ? trunkDeltaDegrees : null,
      clearSessionTrunkAngleDeltaDegrees: !referenceReady,
      sessionRhythmDeltaMs: referenceReady ? rhythmDeltaMs : null,
      clearSessionRhythmDeltaMs: !referenceReady,
      lateFormDrop: _combineLateFormDrop(
        features: features,
        baselineDropScore: referenceReady ? baselineDropScore : null,
        config: config,
      ),
    );

    _updateReference(features, config);
    return annotated;
  }

  double? _deltaRatioFromBest(
      {required double? current, required double? best}) {
    if (current == null || best == null || best <= 0) {
      return null;
    }
    return (current - best) / best;
  }

  double? _deltaFromBest({required double? current, required double? best}) {
    if (current == null || best == null) {
      return null;
    }
    return current - best;
  }

  double? _increaseFromBest({required double? current, required double? best}) {
    if (current == null || best == null) {
      return null;
    }
    return current - best;
  }

  double? _baselineDropScore({
    required double? kneeDeltaRatio,
    required double? trunkDeltaDegrees,
    required double? rhythmDeltaMs,
    required SprintPipelineConfig config,
  }) {
    final penalties = <double>[
      if (kneeDeltaRatio != null && kneeDeltaRatio < 0)
        (-kneeDeltaRatio / config.maximumSessionKneeDriveDropRatio)
            .clamp(0.0, 1.0),
      if (trunkDeltaDegrees != null && trunkDeltaDegrees < 0)
        (-trunkDeltaDegrees / config.maximumSessionTrunkAngleDropDegrees)
            .clamp(0.0, 1.0),
      if (rhythmDeltaMs != null && rhythmDeltaMs > 0)
        (rhythmDeltaMs / config.maximumStepIntervalStdMs).clamp(0.0, 1.0),
    ];
    if (penalties.isEmpty) {
      return null;
    }
    return penalties.reduce((sum, value) => sum + value) / penalties.length;
  }

  SprintMeasuredValue _combineLateFormDrop({
    required SprintFeatureSnapshot features,
    required double? baselineDropScore,
    required SprintPipelineConfig config,
  }) {
    final windowScore = features.lateFormDrop.value;
    if (windowScore == null && baselineDropScore == null) {
      return features.lateFormDrop;
    }

    final combined = <double>[
      if (windowScore != null) windowScore,
      if (baselineDropScore != null) baselineDropScore,
    ].reduce((first, second) => first > second ? first : second);
    final confidences = <double>[
      if (features.lateFormDrop.available) features.lateFormDrop.confidence,
      if (baselineDropScore != null) config.minimumFeatureConfidence,
    ];
    final confidence =
        confidences.reduce((sum, value) => sum + value) / confidences.length;
    return SprintMeasuredValue.available(
      value: combined,
      confidence: confidence.clamp(0.0, 1.0),
      sampleCount: features.lateFormDrop.sampleCount,
    );
  }

  void _updateReference(
    SprintFeatureSnapshot features,
    SprintPipelineConfig config,
  ) {
    var updated = false;
    if (features.kneeDrive.available &&
        features.kneeDrive.confidence >= config.minimumFeatureConfidence &&
        features.kneeDriveHeightRatio != null) {
      _bestKneeDriveHeight = _maxNullable(
        _bestKneeDriveHeight,
        features.kneeDriveHeightRatio!,
      );
      updated = true;
    }
    if (features.trunkAngle.available &&
        features.trunkAngle.confidence >= config.minimumFeatureConfidence &&
        features.trunkAngleDegrees != null) {
      _bestTrunkAngleDegrees = _maxNullable(
        _bestTrunkAngleDegrees,
        features.trunkAngleDegrees!,
      );
      updated = true;
    }
    if (features.rhythm.available &&
        features.rhythm.confidence >= config.minimumFeatureConfidence &&
        features.stepIntervalStdMs != null) {
      _bestRhythmStdMs = _minNullable(
        _bestRhythmStdMs,
        features.stepIntervalStdMs!,
      );
      updated = true;
    }
    if (updated) {
      _referenceSampleCount += 1;
    }
  }

  double _maxNullable(double? current, double next) {
    if (current == null) {
      return next;
    }
    return current > next ? current : next;
  }

  double _minNullable(double? current, double next) {
    if (current == null) {
      return next;
    }
    return current < next ? current : next;
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
