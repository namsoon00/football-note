import 'dart:math' as math;
import 'dart:ui';

import '../../domain/entities/running_live_coaching_state.dart';
import 'running_live_timing_config.dart';

class RunningTemporalPoseTrackerConfig {
  final double minimumInputLikelihood;
  final Duration smoothingTimeConstant;
  final Duration targetFrameInterval;
  final Duration maximumBridgeGap;
  final Duration maximumTrackingGap;
  final double maxOneFrameDisplacementRatio;

  const RunningTemporalPoseTrackerConfig({
    this.minimumInputLikelihood = 0.12,
    this.smoothingTimeConstant = const Duration(milliseconds: 140),
    this.targetFrameInterval = runningLiveGaitTargetFrameInterval,
    this.maximumBridgeGap = const Duration(milliseconds: 180),
    this.maximumTrackingGap = const Duration(milliseconds: 650),
    this.maxOneFrameDisplacementRatio = 0.42,
  });
}

class RunningTemporalPoseTracker {
  final RunningTemporalPoseTrackerConfig config;
  final Map<RunningPoseLandmarkType, _TrackedLandmark> _tracked =
      <RunningPoseLandmarkType, _TrackedLandmark>{};

  DateTime? _lastTimestamp;
  Size? _lastImageSize;
  double? _bodyScale;

  RunningTemporalPoseTracker({
    this.config = const RunningTemporalPoseTrackerConfig(),
  });

  void reset() {
    _tracked.clear();
    _lastTimestamp = null;
    _lastImageSize = null;
    _bodyScale = null;
  }

  RunningPoseObservation? track(
    RunningPoseObservation? observation, {
    required DateTime timestamp,
  }) {
    final previousTimestamp = _lastTimestamp;
    if (previousTimestamp != null && !timestamp.isAfter(previousTimestamp)) {
      reset();
    }

    final effectivePreviousTimestamp = _lastTimestamp;
    final elapsed = effectivePreviousTimestamp == null
        ? Duration.zero
        : timestamp.difference(effectivePreviousTimestamp);
    if (elapsed > config.maximumTrackingGap) {
      reset();
    }

    final imageSize = observation?.imageSize ?? _lastImageSize;
    if (imageSize == null || imageSize.width <= 0 || imageSize.height <= 0) {
      _lastTimestamp = timestamp;
      return null;
    }

    _lastImageSize = imageSize;
    final observedLandmarks = _observedLandmarks(observation);
    final rawBodyScale = _estimateBodyScale(
      imageSize: imageSize,
      landmarks: observedLandmarks,
    );
    if (rawBodyScale > 0) {
      _bodyScale = _bodyScale == null
          ? rawBodyScale
          : (_bodyScale! * 0.72) + (rawBodyScale * 0.28);
    }
    final bodyScale = math.max(_bodyScale ?? rawBodyScale, 1.0);
    final alpha = _baseAlpha(elapsed);
    final output = <RunningPoseLandmarkType, RunningPoseLandmark>{};
    final candidateTypes = <RunningPoseLandmarkType>{
      ...observedLandmarks.keys,
      ..._tracked.keys,
    };

    for (final type in candidateTypes) {
      final observed = observedLandmarks[type];
      final previous = _tracked[type];
      if (observed != null) {
        final next = _updateObserved(
          observed,
          previous: previous,
          bodyScale: bodyScale,
          elapsed: elapsed,
          alpha: alpha,
          timestamp: timestamp,
        );
        if (next != null) {
          _tracked[type] = next;
          output[type] = RunningPoseLandmark(
            position: next.position,
            likelihood: next.confidence,
          );
        }
        continue;
      }

      if (previous == null) {
        continue;
      }
      final bridged = _bridge(previous, timestamp: timestamp);
      if (bridged == null) {
        _tracked.remove(type);
        continue;
      }
      output[type] = bridged;
    }

    _lastTimestamp = timestamp;
    if (output.isEmpty) {
      return null;
    }
    return RunningPoseObservation(imageSize: imageSize, landmarks: output);
  }

  Map<RunningPoseLandmarkType, RunningPoseLandmark> _observedLandmarks(
    RunningPoseObservation? observation,
  ) {
    if (observation == null) {
      return const <RunningPoseLandmarkType, RunningPoseLandmark>{};
    }
    return <RunningPoseLandmarkType, RunningPoseLandmark>{
      for (final entry in observation.landmarks.entries)
        if (entry.value.likelihood >= config.minimumInputLikelihood)
          entry.key: entry.value,
    };
  }

  _TrackedLandmark? _updateObserved(
    RunningPoseLandmark observed, {
    required _TrackedLandmark? previous,
    required double bodyScale,
    required Duration elapsed,
    required double alpha,
    required DateTime timestamp,
  }) {
    if (previous == null) {
      return _TrackedLandmark(
        position: observed.position,
        confidence: observed.likelihood,
        observedAt: timestamp,
      );
    }

    final displacement = (observed.position - previous.position).distance;
    final elapsedRatio = _durationRatio(elapsed, config.targetFrameInterval);
    final oneFrameLimit =
        bodyScale * config.maxOneFrameDisplacementRatio * elapsedRatio;
    final isOneFrameOutlier =
        elapsed <= config.maximumBridgeGap && displacement > oneFrameLimit;
    if (isOneFrameOutlier) {
      final bridged = _bridge(previous, timestamp: timestamp);
      if (bridged == null) {
        return null;
      }
      return _TrackedLandmark(
        position: bridged.position,
        confidence: bridged.likelihood,
        observedAt: previous.observedAt,
      );
    }

    final speed = elapsed.inMicroseconds <= 0
        ? 0.0
        : displacement /
            bodyScale /
            (elapsed.inMicroseconds / Duration.microsecondsPerSecond);
    final adaptiveAlpha = (alpha + ((speed - 0.45) / 3.4).clamp(0.0, 0.32))
        .clamp(0.06, 0.86)
        .toDouble();
    return _TrackedLandmark(
      position: _lerp(previous.position, observed.position, adaptiveAlpha),
      confidence: ((previous.confidence * 0.58) + (observed.likelihood * 0.42))
          .clamp(0.0, 1.0)
          .toDouble(),
      observedAt: timestamp,
    );
  }

  RunningPoseLandmark? _bridge(
    _TrackedLandmark previous, {
    required DateTime timestamp,
  }) {
    final missingFor = timestamp.difference(previous.observedAt);
    if (missingFor < Duration.zero || missingFor > config.maximumBridgeGap) {
      return null;
    }
    final gapRatio = _durationRatio(missingFor, config.maximumBridgeGap);
    final confidence = (previous.confidence * (1.0 - (gapRatio * 0.52)))
        .clamp(0.0, previous.confidence)
        .toDouble();
    return RunningPoseLandmark(
      position: previous.position,
      likelihood: confidence,
    );
  }

  double _baseAlpha(Duration elapsed) {
    if (elapsed <= Duration.zero) {
      return 1;
    }
    final timeConstantMs =
        math.max(1, config.smoothingTimeConstant.inMilliseconds);
    final elapsedMs =
        elapsed.inMicroseconds / Duration.microsecondsPerMillisecond;
    return (1 - math.exp(-elapsedMs / timeConstantMs))
        .clamp(0.06, 0.78)
        .toDouble();
  }

  double _estimateBodyScale({
    required Size imageSize,
    required Map<RunningPoseLandmarkType, RunningPoseLandmark> landmarks,
  }) {
    if (landmarks.isEmpty) {
      return 0;
    }

    final leftShoulder = landmarks[RunningPoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[RunningPoseLandmarkType.rightShoulder];
    final leftHip = landmarks[RunningPoseLandmarkType.leftHip];
    final rightHip = landmarks[RunningPoseLandmarkType.rightHip];
    final leftAnkle = landmarks[RunningPoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[RunningPoseLandmarkType.rightAnkle];
    if (leftShoulder != null &&
        rightShoulder != null &&
        leftHip != null &&
        rightHip != null &&
        leftAnkle != null &&
        rightAnkle != null) {
      final shoulderCenter = _midpoint(
        leftShoulder.position,
        rightShoulder.position,
      );
      final hipCenter = _midpoint(leftHip.position, rightHip.position);
      final ankleCenter = _midpoint(leftAnkle.position, rightAnkle.position);
      return math.max(
        _distance(shoulderCenter, hipCenter),
        _distance(hipCenter, ankleCenter),
      );
    }

    final xs = landmarks.values.map((landmark) => landmark.position.dx);
    final ys = landmarks.values.map((landmark) => landmark.position.dy);
    final width = xs.reduce(math.max) - xs.reduce(math.min);
    final height = ys.reduce(math.max) - ys.reduce(math.min);
    return math.max(math.max(width, height), imageSize.shortestSide * 0.08);
  }

  double _durationRatio(Duration value, Duration reference) {
    final denominator = reference.inMicroseconds;
    if (denominator <= 0) {
      return 1;
    }
    return (value.inMicroseconds / denominator).clamp(0.0, 1.0).toDouble();
  }

  Offset _lerp(Offset from, Offset to, double alpha) {
    return Offset(
      from.dx + ((to.dx - from.dx) * alpha),
      from.dy + ((to.dy - from.dy) * alpha),
    );
  }

  Offset _midpoint(Offset first, Offset second) {
    return Offset((first.dx + second.dx) / 2, (first.dy + second.dy) / 2);
  }

  double _distance(Offset first, Offset second) {
    final dx = first.dx - second.dx;
    final dy = first.dy - second.dy;
    return math.sqrt((dx * dx) + (dy * dy));
  }
}

class _TrackedLandmark {
  final Offset position;
  final double confidence;
  final DateTime observedAt;

  const _TrackedLandmark({
    required this.position,
    required this.confidence,
    required this.observedAt,
  });
}
