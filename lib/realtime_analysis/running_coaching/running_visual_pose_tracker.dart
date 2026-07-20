import 'dart:math' as math;
import 'dart:ui';

import '../../application/mediapipe_pose_landmarker_service.dart';
import '../../domain/entities/running_live_coaching_state.dart';

enum RunningVisualPoseLandmarkState { observed, inferred, occluded }

class RunningVisualPoseTrackerConfig {
  final double minimumInputConfidence;
  final double appearConfidence;
  final double releaseConfidence;
  final Duration smoothingTimeConstant;
  final Duration displayPredictionLead;
  final Duration maximumPrediction;
  final Duration maximumInferredGap;
  final Duration maximumOccludedGap;
  final Duration maximumTrackingGap;
  final Duration maximumStanceLockDuration;
  final double velocitySmoothing;
  final double segmentLengthSmoothing;
  final double segmentMinimumRatio;
  final double segmentMaximumRatio;

  const RunningVisualPoseTrackerConfig({
    this.minimumInputConfidence = 0.04,
    this.appearConfidence = 0.34,
    this.releaseConfidence = 0.18,
    this.smoothingTimeConstant = const Duration(milliseconds: 58),
    this.displayPredictionLead = const Duration(milliseconds: 60),
    this.maximumPrediction = const Duration(milliseconds: 80),
    this.maximumInferredGap = const Duration(milliseconds: 210),
    this.maximumOccludedGap = const Duration(milliseconds: 420),
    this.maximumTrackingGap = const Duration(milliseconds: 700),
    this.maximumStanceLockDuration = const Duration(milliseconds: 680),
    this.velocitySmoothing = 0.48,
    this.segmentLengthSmoothing = 0.22,
    this.segmentMinimumRatio = 0.58,
    this.segmentMaximumRatio = 1.34,
  });
}

class RunningVisualPoseLandmark {
  final Offset position;
  final double confidence;
  final double rawConfidence;
  final double z;
  final double? worldZ;
  final double? visibility;
  final double? presence;
  final RunningVisualPoseLandmarkState state;

  const RunningVisualPoseLandmark({
    required this.position,
    required this.confidence,
    required this.rawConfidence,
    required this.z,
    required this.worldZ,
    required this.visibility,
    required this.presence,
    required this.state,
  });

  bool get isInferred => state != RunningVisualPoseLandmarkState.observed;
}

class RunningVisualPoseFrame {
  final Size imageSize;
  final Map<RunningPoseLandmarkType, RunningVisualPoseLandmark> landmarks;
  final DateTime timestamp;
  final DateTime observedAt;

  RunningVisualPoseFrame({
    required this.imageSize,
    required Map<RunningPoseLandmarkType, RunningVisualPoseLandmark> landmarks,
    required this.timestamp,
    required this.observedAt,
  }) : landmarks = Map.unmodifiable(landmarks);

  RunningVisualPoseLandmark? landmark(
    RunningPoseLandmarkType type, {
    double minimumConfidence = 0,
  }) {
    final landmark = landmarks[type];
    if (landmark == null || landmark.confidence < minimumConfidence) {
      return null;
    }
    return landmark;
  }
}

class RunningVisualPoseTracker {
  final RunningVisualPoseTrackerConfig config;
  final Map<RunningPoseLandmarkType, _TrackedVisualLandmark> _tracked =
      <RunningPoseLandmarkType, _TrackedVisualLandmark>{};
  final Map<_SegmentKey, _SegmentLengthState> _segmentLengths =
      <_SegmentKey, _SegmentLengthState>{};
  final Map<RunningFootSide, _StanceLock> _stanceLocks =
      <RunningFootSide, _StanceLock>{};
  final Map<String, DateTime> _lastAppliedGaitEventAt = <String, DateTime>{};

  DateTime? _lastTimestamp;
  Size? _lastImageSize;
  double? _bodyScale;

  RunningVisualPoseTracker({
    this.config = const RunningVisualPoseTrackerConfig(),
  });

  void reset() {
    _tracked.clear();
    _segmentLengths.clear();
    _stanceLocks.clear();
    _lastAppliedGaitEventAt.clear();
    _lastTimestamp = null;
    _lastImageSize = null;
    _bodyScale = null;
  }

  RunningVisualPoseFrame? ingestDetection(
    MediaPipePoseDetection detection, {
    required DateTime timestamp,
    Size? fallbackImageSize,
  }) {
    final previousTimestamp = _lastTimestamp;
    if (previousTimestamp != null && !timestamp.isAfter(previousTimestamp)) {
      reset();
    } else if (previousTimestamp != null &&
        timestamp.difference(previousTimestamp) > config.maximumTrackingGap) {
      reset();
    }

    final imageSize = detection.imageSize.isEmpty
        ? (fallbackImageSize ?? _lastImageSize)
        : detection.imageSize;
    if (imageSize == null || imageSize.isEmpty) {
      _lastTimestamp = timestamp;
      return null;
    }
    _lastImageSize = imageSize;

    final elapsed = previousTimestamp == null
        ? Duration.zero
        : timestamp.difference(previousTimestamp);
    final observed = _stabilizedObservedLandmarks(
      _observedLandmarks(detection),
    );
    _updateBodyScale(imageSize: imageSize, observedLandmarks: observed);
    _updateSegmentLengths(observed);

    final candidateTypes = <RunningPoseLandmarkType>{
      ..._tracked.keys,
      ...observed.keys,
    };
    for (final type in candidateTypes) {
      final next = observed[type];
      if (next == null) {
        continue;
      }
      _tracked[type] = _updateObserved(
        type: type,
        observed: next,
        previous: _tracked[type],
        elapsed: elapsed,
        timestamp: timestamp,
      );
    }

    _lastTimestamp = timestamp;
    _dropExpired(timestamp);
    return frameAt(timestamp);
  }

  void ingestGaitEvents(Iterable<RunningGaitEvent> events) {
    final sortedEvents = events.toList(growable: false)
      ..sort((first, second) => first.timestamp.compareTo(second.timestamp));
    for (final event in sortedEvents) {
      final key = '${event.side.name}:${event.type.name}';
      final lastAppliedAt = _lastAppliedGaitEventAt[key];
      if (lastAppliedAt != null && !event.timestamp.isAfter(lastAppliedAt)) {
        continue;
      }
      _lastAppliedGaitEventAt[key] = event.timestamp;

      switch (event.type) {
        case RunningGaitEventType.touchdown:
          _lockFoot(event.side, event.timestamp);
        case RunningGaitEventType.toeOff:
          _stanceLocks.remove(event.side);
      }
    }
  }

  RunningVisualPoseFrame? frameAt(DateTime timestamp) {
    final imageSize = _lastImageSize;
    final observedAt = _lastTimestamp;
    if (imageSize == null || observedAt == null || imageSize.isEmpty) {
      return null;
    }

    _dropExpired(timestamp);
    _dropExpiredStanceLocks(timestamp);

    final displayLandmarks =
        <RunningPoseLandmarkType, RunningVisualPoseLandmark>{};
    for (final entry in _tracked.entries) {
      final landmark = _displayLandmark(entry.value, timestamp);
      if (landmark != null && landmark.confidence > 0.025) {
        displayLandmarks[entry.key] = landmark;
      }
    }

    if (displayLandmarks.isEmpty) {
      return null;
    }

    _applySegmentLengthConstraints(displayLandmarks);
    _applyStanceLocks(displayLandmarks);
    return RunningVisualPoseFrame(
      imageSize: imageSize,
      landmarks: displayLandmarks,
      timestamp: timestamp,
      observedAt: observedAt,
    );
  }

  Map<RunningPoseLandmarkType, _ObservedVisualLandmark> _observedLandmarks(
    MediaPipePoseDetection detection,
  ) {
    final observed = <RunningPoseLandmarkType, _ObservedVisualLandmark>{};
    for (final landmark in detection.landmarks) {
      final type = runningPoseLandmarkTypeForMediaPipeIndex(landmark.index);
      if (type == null || landmark.confidence < config.minimumInputConfidence) {
        continue;
      }
      observed[type] = _ObservedVisualLandmark(
        position: landmark.position,
        confidence: landmark.confidence.clamp(0.0, 1.0).toDouble(),
        z: landmark.z,
        worldZ: landmark.worldLandmark?.z,
        visibility: landmark.visibility,
        presence: landmark.presence,
      );
    }
    return observed;
  }

  Map<RunningPoseLandmarkType, _ObservedVisualLandmark>
      _stabilizedObservedLandmarks(
    Map<RunningPoseLandmarkType, _ObservedVisualLandmark> observed,
  ) {
    if (observed.isEmpty || _tracked.isEmpty) {
      return observed;
    }

    final stabilized = Map<RunningPoseLandmarkType, _ObservedVisualLandmark>.of(
      observed,
    );
    for (final pair in _sidePairs) {
      _stabilizeSidePair(
        stabilized,
        leftType: pair.left,
        rightType: pair.right,
      );
    }
    return stabilized;
  }

  void _stabilizeSidePair(
    Map<RunningPoseLandmarkType, _ObservedVisualLandmark> observed, {
    required RunningPoseLandmarkType leftType,
    required RunningPoseLandmarkType rightType,
  }) {
    final observedLeft = observed[leftType];
    final observedRight = observed[rightType];
    final previousLeft = _tracked[leftType];
    final previousRight = _tracked[rightType];
    if (observedLeft == null ||
        observedRight == null ||
        previousLeft == null ||
        previousRight == null) {
      return;
    }

    final directCost = _distance(observedLeft.position, previousLeft.position) +
        _distance(observedRight.position, previousRight.position);
    final swapCost = _distance(observedLeft.position, previousRight.position) +
        _distance(observedRight.position, previousLeft.position);
    final bodyScale = math.max(_bodyScale ?? 1.0, 1.0);
    final switchMargin = math.max(3.0, bodyScale * 0.08);
    final previousDepthOrder = _depthOrder(previousLeft.z, previousRight.z);
    final directDepthOrder = _depthOrder(observedLeft.z, observedRight.z);
    final swappedDepthOrder = -directDepthOrder;
    final depthSupportsSwap = previousDepthOrder != 0 &&
        swappedDepthOrder == previousDepthOrder &&
        directDepthOrder != previousDepthOrder;
    final temporalSupportsSwap = swapCost + switchMargin < directCost;
    final temporalStronglySupportsSwap =
        swapCost + (switchMargin * 2.0) < directCost * 0.66;

    if (temporalSupportsSwap &&
        (depthSupportsSwap || temporalStronglySupportsSwap)) {
      observed[leftType] = observedRight;
      observed[rightType] = observedLeft;
    }
  }

  _TrackedVisualLandmark _updateObserved({
    required RunningPoseLandmarkType type,
    required _ObservedVisualLandmark observed,
    required _TrackedVisualLandmark? previous,
    required Duration elapsed,
    required DateTime timestamp,
  }) {
    final isVisible = previous?.isVisible == true
        ? observed.confidence >= config.releaseConfidence
        : observed.confidence >= config.appearConfidence;

    final observationElapsed =
        previous == null ? elapsed : timestamp.difference(previous.lastInputAt);
    if (previous == null || observationElapsed <= Duration.zero) {
      return _TrackedVisualLandmark(
        position: observed.position,
        velocity: Offset.zero,
        confidence: observed.confidence,
        rawConfidence: observed.confidence,
        z: observed.z,
        worldZ: observed.worldZ,
        visibility: observed.visibility,
        presence: observed.presence,
        isVisible: isVisible,
        lastInputAt: timestamp,
      );
    }

    final elapsedSeconds =
        observationElapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final predicted = previous.position +
        Offset(
          previous.velocity.dx * elapsedSeconds,
          previous.velocity.dy * elapsedSeconds,
        );
    final displacement = _distance(predicted, observed.position);
    final bodyScale = math.max(_bodyScale ?? displacement, 1.0);
    final speedRatio =
        elapsedSeconds <= 0 ? 0.0 : displacement / bodyScale / elapsedSeconds;
    final adaptiveAlpha =
        (_baseAlpha(observationElapsed) + ((speedRatio - 0.65) * 0.12))
            .clamp(0.18, 0.82)
            .toDouble();
    final position = _lerp(predicted, observed.position, adaptiveAlpha);
    final observedVelocity = elapsedSeconds <= 0
        ? Offset.zero
        : Offset(
            (position.dx - previous.position.dx) / elapsedSeconds,
            (position.dy - previous.position.dy) / elapsedSeconds,
          );
    final velocity = _lerp(
      previous.velocity,
      observedVelocity,
      config.velocitySmoothing,
    );
    final confidenceTarget =
        isVisible ? observed.confidence : observed.confidence * 0.42;
    final confidence = _lerpDouble(
      previous.confidence,
      confidenceTarget,
      isVisible ? 0.56 : 0.34,
    );

    return _TrackedVisualLandmark(
      position: position,
      velocity: velocity,
      confidence: confidence.clamp(0.0, 1.0).toDouble(),
      rawConfidence: observed.confidence,
      z: _lerpDouble(previous.z, observed.z, 0.44),
      worldZ: _lerpNullableDouble(previous.worldZ, observed.worldZ, 0.44),
      visibility: observed.visibility,
      presence: observed.presence,
      isVisible: isVisible,
      lastInputAt: timestamp,
    );
  }

  RunningVisualPoseLandmark? _displayLandmark(
    _TrackedVisualLandmark tracked,
    DateTime timestamp,
  ) {
    final missingFor = timestamp.difference(tracked.lastInputAt);
    if (missingFor < Duration.zero) {
      return RunningVisualPoseLandmark(
        position: tracked.position,
        confidence: tracked.confidence,
        rawConfidence: tracked.rawConfidence,
        z: tracked.z,
        worldZ: tracked.worldZ,
        visibility: tracked.visibility,
        presence: tracked.presence,
        state: tracked.isVisible
            ? RunningVisualPoseLandmarkState.observed
            : RunningVisualPoseLandmarkState.occluded,
      );
    }
    if (missingFor > config.maximumOccludedGap) {
      return null;
    }

    final state = _displayState(tracked, missingFor);
    final confidence = tracked.confidence *
        _confidenceFade(missingFor: missingFor, state: state);
    final prediction = _predictionDuration(missingFor);
    final seconds = prediction.inMicroseconds / Duration.microsecondsPerSecond;
    final predictedPosition = tracked.position +
        Offset(
          tracked.velocity.dx * seconds,
          tracked.velocity.dy * seconds,
        );

    return RunningVisualPoseLandmark(
      position: predictedPosition,
      confidence: confidence.clamp(0.0, 1.0).toDouble(),
      rawConfidence: tracked.rawConfidence,
      z: tracked.z,
      worldZ: tracked.worldZ,
      visibility: tracked.visibility,
      presence: tracked.presence,
      state: state,
    );
  }

  RunningVisualPoseLandmarkState _displayState(
    _TrackedVisualLandmark tracked,
    Duration missingFor,
  ) {
    if (!tracked.isVisible) {
      return RunningVisualPoseLandmarkState.occluded;
    }
    if (missingFor <= Duration.zero) {
      return RunningVisualPoseLandmarkState.observed;
    }
    if (missingFor <= config.maximumInferredGap) {
      return RunningVisualPoseLandmarkState.inferred;
    }
    return RunningVisualPoseLandmarkState.occluded;
  }

  double _confidenceFade({
    required Duration missingFor,
    required RunningVisualPoseLandmarkState state,
  }) {
    if (state == RunningVisualPoseLandmarkState.observed) {
      return 1;
    }
    if (state == RunningVisualPoseLandmarkState.inferred) {
      final ratio = _durationRatio(missingFor, config.maximumInferredGap);
      return (1.0 - (ratio * 0.34)).clamp(0.0, 1.0).toDouble();
    }

    final occludedSpan = config.maximumOccludedGap - config.maximumInferredGap;
    final occludedFor = missingFor - config.maximumInferredGap;
    final ratio = _durationRatio(occludedFor, occludedSpan);
    return (0.48 * (1.0 - ratio)).clamp(0.0, 0.48).toDouble();
  }

  Duration _predictionDuration(Duration missingFor) {
    final micros = math.max(
      0,
      missingFor.inMicroseconds + config.displayPredictionLead.inMicroseconds,
    );
    return Duration(
      microseconds: math.min(micros, config.maximumPrediction.inMicroseconds),
    );
  }

  void _updateBodyScale({
    required Size imageSize,
    required Map<RunningPoseLandmarkType, _ObservedVisualLandmark>
        observedLandmarks,
  }) {
    final rawScale = _estimateBodyScale(
      imageSize: imageSize,
      observedLandmarks: observedLandmarks,
    );
    if (rawScale <= 0) {
      return;
    }
    _bodyScale = _bodyScale == null
        ? rawScale
        : (_bodyScale! * 0.78) + (rawScale * 0.22);
  }

  void _updateSegmentLengths(
    Map<RunningPoseLandmarkType, _ObservedVisualLandmark> observed,
  ) {
    for (final segment in _bodySegments) {
      final from = observed[segment.from];
      final to = observed[segment.to];
      if (from == null ||
          to == null ||
          from.confidence < config.appearConfidence ||
          to.confidence < config.appearConfidence) {
        continue;
      }
      final length = _distance(from.position, to.position);
      if (length <= 1) {
        continue;
      }
      final state = _segmentLengths[segment];
      if (state == null) {
        _segmentLengths[segment] = _SegmentLengthState(length: length);
      } else {
        if (length > state.length * 1.55 || length < state.length * 0.45) {
          continue;
        }
        _segmentLengths[segment] = _SegmentLengthState(
          length: _lerpDouble(
            state.length,
            length,
            config.segmentLengthSmoothing,
          ),
          sampleCount: state.sampleCount + 1,
        );
      }
    }
  }

  void _applySegmentLengthConstraints(
    Map<RunningPoseLandmarkType, RunningVisualPoseLandmark> landmarks,
  ) {
    for (final segment in _bodySegments) {
      final state = _segmentLengths[segment];
      final from = landmarks[segment.from];
      final to = landmarks[segment.to];
      if (state == null || from == null || to == null) {
        continue;
      }
      final vector = to.position - from.position;
      final distance = vector.distance;
      if (distance <= 0) {
        continue;
      }
      final minLength = state.length * config.segmentMinimumRatio;
      final maxLength = state.length * config.segmentMaximumRatio;
      final constrainedLength = distance.clamp(minLength, maxLength).toDouble();
      if ((constrainedLength - distance).abs() < 0.001) {
        continue;
      }
      final direction = Offset(vector.dx / distance, vector.dy / distance);
      landmarks[segment.to] = RunningVisualPoseLandmark(
        position: from.position + (direction * constrainedLength),
        confidence: math.min(from.confidence, to.confidence),
        rawConfidence: to.rawConfidence,
        z: to.z,
        worldZ: to.worldZ,
        visibility: to.visibility,
        presence: to.presence,
        state: to.state == RunningVisualPoseLandmarkState.observed &&
                from.state == RunningVisualPoseLandmarkState.observed
            ? RunningVisualPoseLandmarkState.observed
            : RunningVisualPoseLandmarkState.inferred,
      );
    }
  }

  void _lockFoot(RunningFootSide side, DateTime timestamp) {
    final positions = <RunningPoseLandmarkType, Offset>{};
    for (final type in _footTypes(side)) {
      final tracked = _tracked[type];
      if (tracked != null) {
        positions[type] = tracked.position;
      }
    }
    if (positions.isEmpty) {
      return;
    }
    _stanceLocks[side] = _StanceLock(
      positions: Map.unmodifiable(positions),
      lockedAt: timestamp,
    );
  }

  void _applyStanceLocks(
    Map<RunningPoseLandmarkType, RunningVisualPoseLandmark> landmarks,
  ) {
    for (final lock in _stanceLocks.values) {
      for (final entry in lock.positions.entries) {
        final current = landmarks[entry.key];
        if (current == null) {
          continue;
        }
        landmarks[entry.key] = RunningVisualPoseLandmark(
          position: entry.value,
          confidence: current.confidence,
          rawConfidence: current.rawConfidence,
          z: current.z,
          worldZ: current.worldZ,
          visibility: current.visibility,
          presence: current.presence,
          state: current.state,
        );
      }
    }
  }

  void _dropExpired(DateTime timestamp) {
    _tracked.removeWhere(
      (_, tracked) =>
          timestamp.difference(tracked.lastInputAt) > config.maximumOccludedGap,
    );
  }

  void _dropExpiredStanceLocks(DateTime timestamp) {
    _stanceLocks.removeWhere(
      (_, lock) =>
          timestamp.difference(lock.lockedAt) >
          config.maximumStanceLockDuration,
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
        .clamp(0.18, 0.86)
        .toDouble();
  }

  double _estimateBodyScale({
    required Size imageSize,
    required Map<RunningPoseLandmarkType, _ObservedVisualLandmark>
        observedLandmarks,
  }) {
    final leftShoulder =
        observedLandmarks[RunningPoseLandmarkType.leftShoulder];
    final rightShoulder =
        observedLandmarks[RunningPoseLandmarkType.rightShoulder];
    final leftHip = observedLandmarks[RunningPoseLandmarkType.leftHip];
    final rightHip = observedLandmarks[RunningPoseLandmarkType.rightHip];
    final leftAnkle = observedLandmarks[RunningPoseLandmarkType.leftAnkle];
    final rightAnkle = observedLandmarks[RunningPoseLandmarkType.rightAnkle];
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

    if (observedLandmarks.isEmpty) {
      return 0;
    }
    final xs = observedLandmarks.values.map((landmark) => landmark.position.dx);
    final ys = observedLandmarks.values.map((landmark) => landmark.position.dy);
    final width = xs.reduce(math.max) - xs.reduce(math.min);
    final height = ys.reduce(math.max) - ys.reduce(math.min);
    return math.max(math.max(width, height), imageSize.shortestSide * 0.08);
  }
}

class _ObservedVisualLandmark {
  final Offset position;
  final double confidence;
  final double z;
  final double? worldZ;
  final double? visibility;
  final double? presence;

  const _ObservedVisualLandmark({
    required this.position,
    required this.confidence,
    required this.z,
    required this.worldZ,
    required this.visibility,
    required this.presence,
  });
}

class _TrackedVisualLandmark {
  final Offset position;
  final Offset velocity;
  final double confidence;
  final double rawConfidence;
  final double z;
  final double? worldZ;
  final double? visibility;
  final double? presence;
  final bool isVisible;
  final DateTime lastInputAt;

  const _TrackedVisualLandmark({
    required this.position,
    required this.velocity,
    required this.confidence,
    required this.rawConfidence,
    required this.z,
    required this.worldZ,
    required this.visibility,
    required this.presence,
    required this.isVisible,
    required this.lastInputAt,
  });
}

class _SegmentLengthState {
  final double length;
  final int sampleCount;

  const _SegmentLengthState({required this.length, this.sampleCount = 1});
}

class _StanceLock {
  final Map<RunningPoseLandmarkType, Offset> positions;
  final DateTime lockedAt;

  const _StanceLock({required this.positions, required this.lockedAt});
}

typedef _SegmentKey = ({
  RunningPoseLandmarkType from,
  RunningPoseLandmarkType to,
});

const List<_SegmentKey> _bodySegments = [
  (
    from: RunningPoseLandmarkType.leftShoulder,
    to: RunningPoseLandmarkType.leftElbow,
  ),
  (
    from: RunningPoseLandmarkType.leftElbow,
    to: RunningPoseLandmarkType.leftWrist,
  ),
  (
    from: RunningPoseLandmarkType.rightShoulder,
    to: RunningPoseLandmarkType.rightElbow,
  ),
  (
    from: RunningPoseLandmarkType.rightElbow,
    to: RunningPoseLandmarkType.rightWrist,
  ),
  (
    from: RunningPoseLandmarkType.leftShoulder,
    to: RunningPoseLandmarkType.leftHip,
  ),
  (
    from: RunningPoseLandmarkType.rightShoulder,
    to: RunningPoseLandmarkType.rightHip,
  ),
  (
    from: RunningPoseLandmarkType.leftHip,
    to: RunningPoseLandmarkType.leftKnee,
  ),
  (
    from: RunningPoseLandmarkType.leftKnee,
    to: RunningPoseLandmarkType.leftAnkle,
  ),
  (
    from: RunningPoseLandmarkType.rightHip,
    to: RunningPoseLandmarkType.rightKnee,
  ),
  (
    from: RunningPoseLandmarkType.rightKnee,
    to: RunningPoseLandmarkType.rightAnkle,
  ),
  (
    from: RunningPoseLandmarkType.leftAnkle,
    to: RunningPoseLandmarkType.leftHeel,
  ),
  (
    from: RunningPoseLandmarkType.leftAnkle,
    to: RunningPoseLandmarkType.leftFootIndex,
  ),
  (
    from: RunningPoseLandmarkType.rightAnkle,
    to: RunningPoseLandmarkType.rightHeel,
  ),
  (
    from: RunningPoseLandmarkType.rightAnkle,
    to: RunningPoseLandmarkType.rightFootIndex,
  ),
];

typedef _SidePair = ({
  RunningPoseLandmarkType left,
  RunningPoseLandmarkType right,
});

const List<_SidePair> _sidePairs = [
  (
    left: RunningPoseLandmarkType.leftShoulder,
    right: RunningPoseLandmarkType.rightShoulder,
  ),
  (
    left: RunningPoseLandmarkType.leftElbow,
    right: RunningPoseLandmarkType.rightElbow,
  ),
  (
    left: RunningPoseLandmarkType.leftWrist,
    right: RunningPoseLandmarkType.rightWrist,
  ),
  (
    left: RunningPoseLandmarkType.leftHip,
    right: RunningPoseLandmarkType.rightHip,
  ),
  (
    left: RunningPoseLandmarkType.leftKnee,
    right: RunningPoseLandmarkType.rightKnee,
  ),
  (
    left: RunningPoseLandmarkType.leftAnkle,
    right: RunningPoseLandmarkType.rightAnkle,
  ),
  (
    left: RunningPoseLandmarkType.leftHeel,
    right: RunningPoseLandmarkType.rightHeel,
  ),
  (
    left: RunningPoseLandmarkType.leftFootIndex,
    right: RunningPoseLandmarkType.rightFootIndex,
  ),
];

List<RunningPoseLandmarkType> _footTypes(RunningFootSide side) {
  return switch (side) {
    RunningFootSide.left => const <RunningPoseLandmarkType>[
        RunningPoseLandmarkType.leftAnkle,
        RunningPoseLandmarkType.leftHeel,
        RunningPoseLandmarkType.leftFootIndex,
      ],
    RunningFootSide.right => const <RunningPoseLandmarkType>[
        RunningPoseLandmarkType.rightAnkle,
        RunningPoseLandmarkType.rightHeel,
        RunningPoseLandmarkType.rightFootIndex,
      ],
  };
}

int _depthOrder(double firstZ, double secondZ) {
  final delta = firstZ - secondZ;
  if (delta.abs() < 0.0005) {
    return 0;
  }
  return delta < 0 ? -1 : 1;
}

double _distance(Offset first, Offset second) {
  final dx = first.dx - second.dx;
  final dy = first.dy - second.dy;
  return math.sqrt((dx * dx) + (dy * dy));
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

double _lerpDouble(double from, double to, double alpha) {
  return from + ((to - from) * alpha);
}

double? _lerpNullableDouble(double? from, double? to, double alpha) {
  if (from == null) {
    return to;
  }
  if (to == null) {
    return from;
  }
  return _lerpDouble(from, to, alpha);
}

Offset _midpoint(Offset first, Offset second) {
  return Offset((first.dx + second.dx) / 2, (first.dy + second.dy) / 2);
}
