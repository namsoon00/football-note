import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import '../../domain/entities/running_live_coaching_state.dart';
import 'running_live_timing_config.dart';

class RunningGaitEventDetectorConfig {
  final Duration analysisWindow;
  final Duration targetFrameInterval;
  final Duration maximumFrameGap;
  final Duration maximumTrackingGap;
  final Duration debounceDuration;
  final Duration minimumEventSpacing;
  final Duration minimumContactDuration;
  final Duration maximumContactDuration;
  final int minimumValidFrames;
  final int minimumTouchdownsForCadence;
  final int minimumContactDurationsPerSide;
  final double minimumLandmarkLikelihood;
  final double minimumMetricConfidence;
  final double minimumSideViewConfidence;
  final double touchdownClearanceRatio;
  final double toeOffClearanceRatio;
  final double touchdownMinimumVelocity;
  final double toeOffMaximumVelocity;

  const RunningGaitEventDetectorConfig({
    this.analysisWindow = const Duration(milliseconds: 2600),
    this.targetFrameInterval = runningLiveGaitTargetFrameInterval,
    this.maximumFrameGap = runningLiveGaitMaximumFrameGap,
    this.maximumTrackingGap = const Duration(milliseconds: 650),
    this.debounceDuration = const Duration(milliseconds: 50),
    this.minimumEventSpacing = const Duration(milliseconds: 80),
    this.minimumContactDuration = const Duration(milliseconds: 90),
    this.maximumContactDuration = const Duration(milliseconds: 650),
    this.minimumValidFrames = 8,
    this.minimumTouchdownsForCadence = 4,
    this.minimumContactDurationsPerSide = 2,
    this.minimumLandmarkLikelihood = 0.35,
    this.minimumMetricConfidence = 0.55,
    this.minimumSideViewConfidence = 0.55,
    this.touchdownClearanceRatio = 0.045,
    this.toeOffClearanceRatio = 0.105,
    this.touchdownMinimumVelocity = -0.35,
    this.toeOffMaximumVelocity = 0.12,
  });
}

class RunningGaitEventDetector {
  final RunningGaitEventDetectorConfig config;
  final Queue<_GaitFrameSample> _frames = Queue<_GaitFrameSample>();
  final List<RunningGaitEvent> _events = <RunningGaitEvent>[];
  final Map<RunningFootSide, _FootTracker> _feet =
      <RunningFootSide, _FootTracker>{
    RunningFootSide.left: _FootTracker(),
    RunningFootSide.right: _FootTracker(),
  };

  DateTime? _lastTimestamp;
  double? _groundY;

  RunningGaitEventDetector({
    this.config = const RunningGaitEventDetectorConfig(),
  });

  void reset() {
    _frames.clear();
    _events.clear();
    for (final foot in _feet.values) {
      foot.reset();
    }
    _lastTimestamp = null;
    _groundY = null;
  }

  RunningGaitAnalysis ingestObservation(
    RunningPoseObservation? observation, {
    required DateTime timestamp,
    required bool cameraSideViewFramingOk,
  }) {
    final previousTimestamp = _lastTimestamp;
    if (previousTimestamp != null && !timestamp.isAfter(previousTimestamp)) {
      reset();
    } else if (previousTimestamp != null &&
        timestamp.difference(previousTimestamp) > config.maximumTrackingGap) {
      reset();
    }
    _lastTimestamp = timestamp;

    final sample = observation == null ? null : _extractSample(observation);
    if (sample != null) {
      _frames.add(sample);
      _trim(timestamp);
      _groundY = _rollingGroundY();
      final groundY = _groundY;
      if (groundY != null) {
        _processFoot(
          RunningFootSide.left,
          sample: sample,
          groundY: groundY,
        );
        _processFoot(
          RunningFootSide.right,
          sample: sample,
          groundY: groundY,
        );
      }
    } else {
      _trim(timestamp);
    }

    return _buildAnalysis(
      timestamp: timestamp,
      cameraSideViewFramingOk: cameraSideViewFramingOk,
    );
  }

  void _processFoot(
    RunningFootSide side, {
    required _GaitFrameSample sample,
    required double groundY,
  }) {
    final tracker = _feet[side]!;
    final foot = sample.foot(side);
    if (foot == null || foot.confidence < config.minimumLandmarkLikelihood) {
      tracker.clearPending();
      return;
    }

    final previousFootY = tracker.lastFootY;
    final previousFootTimestamp = tracker.lastFootTimestamp;
    final velocity = previousFootY == null || previousFootTimestamp == null
        ? 0.0
        : _verticalVelocity(
            previousFootY: previousFootY,
            previousTimestamp: previousFootTimestamp,
            currentFootY: foot.groundPointY,
            currentTimestamp: sample.timestamp,
            bodyScale: sample.bodyScale,
          );
    final clearanceRatio =
        ((groundY - foot.groundPointY) / math.max(sample.bodyScale, 1.0))
            .clamp(0.0, double.infinity)
            .toDouble();
    tracker.lastFootY = foot.groundPointY;
    tracker.lastFootTimestamp = sample.timestamp;
    tracker.lastSignalConfidence = foot.confidence;

    final desiredContact = _classifyContact(
      clearanceRatio: clearanceRatio,
      verticalVelocity: velocity,
      currentContact: tracker.contact,
    );
    if (desiredContact == null) {
      tracker.clearPending();
      return;
    }

    final currentContact = tracker.contact;
    if (currentContact == null) {
      tracker.contact = desiredContact;
      tracker.clearPending();
      return;
    }

    if (desiredContact == currentContact) {
      tracker.clearPending();
      return;
    }

    if (tracker.pendingContact != desiredContact) {
      tracker.pendingContact = desiredContact;
      tracker.pendingSince = sample.timestamp;
      return;
    }

    final pendingSince = tracker.pendingSince;
    if (pendingSince == null ||
        sample.timestamp.difference(pendingSince) < config.debounceDuration) {
      return;
    }

    // Confirm a sustained state change without adding the debounce delay to
    // the recorded touchdown or toe-off time.
    _acceptTransition(
      side,
      contact: desiredContact,
      timestamp: pendingSince,
      confidence: foot.confidence,
    );
    tracker.contact = desiredContact;
    tracker.clearPending();
  }

  bool? _classifyContact({
    required double clearanceRatio,
    required double verticalVelocity,
    required bool? currentContact,
  }) {
    if (currentContact == true) {
      if (clearanceRatio >= config.toeOffClearanceRatio &&
          verticalVelocity <= config.toeOffMaximumVelocity) {
        return false;
      }
      return true;
    }

    if (clearanceRatio <= config.touchdownClearanceRatio &&
        verticalVelocity >= config.touchdownMinimumVelocity) {
      return true;
    }
    if (clearanceRatio >= config.toeOffClearanceRatio) {
      return false;
    }
    return currentContact;
  }

  void _acceptTransition(
    RunningFootSide side, {
    required bool contact,
    required DateTime timestamp,
    required double confidence,
  }) {
    final tracker = _feet[side]!;
    final type =
        contact ? RunningGaitEventType.touchdown : RunningGaitEventType.toeOff;

    if (type == RunningGaitEventType.touchdown &&
        tracker.lastEventType == RunningGaitEventType.touchdown) {
      _discardUnmatchedTouchdown(side);
    }

    final lastEventAt = tracker.lastEventAt;
    final meetsSpacing = lastEventAt == null ||
        timestamp.difference(lastEventAt) >= config.minimumEventSpacing;
    final validOrder = tracker.lastEventType != type;
    if (type == RunningGaitEventType.toeOff &&
        tracker.lastTouchdownAt == null) {
      return;
    }
    if (!meetsSpacing || !validOrder) {
      if (type == RunningGaitEventType.toeOff) {
        _discardUnmatchedTouchdown(side);
      }
      return;
    }

    if (type == RunningGaitEventType.toeOff) {
      final contactDuration = timestamp.difference(tracker.lastTouchdownAt!);
      if (contactDuration < config.minimumContactDuration ||
          contactDuration > config.maximumContactDuration) {
        _discardUnmatchedTouchdown(side);
        return;
      }
    }

    final event = RunningGaitEvent(
      side: side,
      type: type,
      timestamp: timestamp,
      confidence: confidence.clamp(0.0, 1.0).toDouble(),
    );
    _events.add(event);

    tracker.lastEventAt = timestamp;
    tracker.lastEventType = type;

    if (type == RunningGaitEventType.touchdown) {
      tracker.lastTouchdownAt = timestamp;
    } else {
      tracker.lastTouchdownAt = null;
    }
  }

  void _discardUnmatchedTouchdown(RunningFootSide side) {
    for (var index = _events.length - 1; index >= 0; index -= 1) {
      final event = _events[index];
      if (event.side != side) {
        continue;
      }
      if (event.type == RunningGaitEventType.touchdown) {
        _events.removeAt(index);
      }
      break;
    }

    final tracker = _feet[side]!;
    RunningGaitEvent? previousEvent;
    for (var index = _events.length - 1; index >= 0; index -= 1) {
      if (_events[index].side == side) {
        previousEvent = _events[index];
        break;
      }
    }
    tracker.lastEventAt = previousEvent?.timestamp;
    tracker.lastEventType = previousEvent?.type;
    tracker.lastTouchdownAt =
        previousEvent?.type == RunningGaitEventType.touchdown
            ? previousEvent?.timestamp
            : null;
  }

  RunningGaitAnalysis _buildAnalysis({
    required DateTime timestamp,
    required bool cameraSideViewFramingOk,
  }) {
    _trim(timestamp);
    final timingConfidence = _timingConfidence();
    final sideViewConfidence =
        cameraSideViewFramingOk ? _sideViewConfidence() : 0.0;
    final validFrameCount = _frames.length;
    final frameConfidence = _frameConfidence();
    final qualityReason = _qualityReason(
      validFrameCount: validFrameCount,
      timingConfidence: timingConfidence,
      sideViewConfidence: sideViewConfidence,
      frameConfidence: frameConfidence,
    );
    final currentPhase =
        qualityReason == null ? _currentPhase() : RunningGaitPhase.unknown;
    final phaseConfidence = currentPhase == RunningGaitPhase.unknown
        ? 0.0
        : math
            .min(frameConfidence, sideViewConfidence)
            .clamp(0.0, 1.0)
            .toDouble();
    final recentEvents = _recentEvents(timestamp);
    final touchdownEvents = recentEvents
        .where((event) => event.type == RunningGaitEventType.touchdown)
        .toList(growable: false);
    final toeOffCount = recentEvents
        .where((event) => event.type == RunningGaitEventType.toeOff)
        .length;

    return RunningGaitAnalysis(
      currentPhase: currentPhase,
      phaseConfidence: phaseConfidence,
      cadence: _cadenceMetric(
        touchdownEvents,
        qualityReason: qualityReason,
        timingConfidence: timingConfidence,
        sideViewConfidence: sideViewConfidence,
      ),
      leftContactDuration: _contactDurationMetric(
        RunningFootSide.left,
        qualityReason: qualityReason,
        timingConfidence: timingConfidence,
        sideViewConfidence: sideViewConfidence,
      ),
      rightContactDuration: _contactDurationMetric(
        RunningFootSide.right,
        qualityReason: qualityReason,
        timingConfidence: timingConfidence,
        sideViewConfidence: sideViewConfidence,
      ),
      recentEvents: recentEvents,
      touchdownCount: touchdownEvents.length,
      toeOffCount: toeOffCount,
      validFrameCount: validFrameCount,
      timingConfidence: timingConfidence,
      sideViewConfidence: sideViewConfidence,
    );
  }

  RunningGaitMetric _cadenceMetric(
    List<RunningGaitEvent> touchdownEvents, {
    required String? qualityReason,
    required double timingConfidence,
    required double sideViewConfidence,
  }) {
    if (qualityReason != null) {
      return RunningGaitMetric.unavailable(
        reasonIfUnavailable: qualityReason,
        sampleCount: touchdownEvents.length,
        confidence: math.min(timingConfidence, sideViewConfidence),
      );
    }
    if (touchdownEvents.length < config.minimumTouchdownsForCadence) {
      return RunningGaitMetric.unavailable(
        reasonIfUnavailable: 'insufficient_gait_events',
        sampleCount: touchdownEvents.length,
        confidence: math.min(timingConfidence, sideViewConfidence),
      );
    }
    if (!_touchdownsAlternate(touchdownEvents)) {
      return RunningGaitMetric.unavailable(
        reasonIfUnavailable: 'invalid_event_order',
        sampleCount: touchdownEvents.length,
        confidence: math.min(timingConfidence, sideViewConfidence),
      );
    }

    final intervalsMs = <double>[
      for (var index = 1; index < touchdownEvents.length; index += 1)
        touchdownEvents[index]
            .timestamp
            .difference(touchdownEvents[index - 1].timestamp)
            .inMilliseconds
            .toDouble(),
    ];
    if (intervalsMs.any((intervalMs) => intervalMs < 160 || intervalMs > 800)) {
      return RunningGaitMetric.unavailable(
        reasonIfUnavailable: 'implausible_event_timing',
        sampleCount: touchdownEvents.length,
        confidence: math.min(timingConfidence, sideViewConfidence),
      );
    }

    final averageIntervalMs = _average(intervalsMs);
    final cadence = 60000 / averageIntervalMs;
    final eventConfidence = _average(
      touchdownEvents.map((event) => event.confidence).toList(growable: false),
    );
    final confidence = (eventConfidence *
            timingConfidence *
            sideViewConfidence *
            math.min(1.0, touchdownEvents.length / 6.0))
        .clamp(0.0, 1.0)
        .toDouble();
    if (confidence < config.minimumMetricConfidence) {
      return RunningGaitMetric.unavailable(
        reasonIfUnavailable: 'low_confidence',
        sampleCount: touchdownEvents.length,
        confidence: confidence,
      );
    }
    return RunningGaitMetric.available(
      value: cadence,
      confidence: confidence,
      sampleCount: touchdownEvents.length,
    );
  }

  RunningGaitMetric _contactDurationMetric(
    RunningFootSide side, {
    required String? qualityReason,
    required double timingConfidence,
    required double sideViewConfidence,
  }) {
    final durations = _contactDurations(side);
    if (qualityReason != null) {
      return RunningGaitMetric.unavailable(
        reasonIfUnavailable: qualityReason,
        sampleCount: durations.length,
        confidence: math.min(timingConfidence, sideViewConfidence),
      );
    }
    if (durations.length < config.minimumContactDurationsPerSide) {
      return RunningGaitMetric.unavailable(
        reasonIfUnavailable: 'insufficient_contact_events',
        sampleCount: durations.length,
        confidence: math.min(timingConfidence, sideViewConfidence),
      );
    }

    final durationMs = durations
        .map((duration) => duration.inMilliseconds.toDouble())
        .toList(growable: false);
    final signalConfidence = _feet[side]!.lastSignalConfidence;
    final confidence = (signalConfidence *
            timingConfidence *
            sideViewConfidence *
            math.min(1.0, durations.length / 3.0))
        .clamp(0.0, 1.0)
        .toDouble();
    if (confidence < config.minimumMetricConfidence) {
      return RunningGaitMetric.unavailable(
        reasonIfUnavailable: 'low_confidence',
        sampleCount: durations.length,
        confidence: confidence,
      );
    }

    return RunningGaitMetric.available(
      value: _average(durationMs),
      confidence: confidence,
      sampleCount: durations.length,
    );
  }

  List<Duration> _contactDurations(RunningFootSide side) {
    final durations = <Duration>[];
    DateTime? touchdownAt;
    for (final event in _events) {
      if (event.side != side) {
        continue;
      }
      if (event.type == RunningGaitEventType.touchdown) {
        touchdownAt = event.timestamp;
        continue;
      }
      if (touchdownAt == null) {
        continue;
      }
      final duration = event.timestamp.difference(touchdownAt);
      touchdownAt = null;
      if (duration >= config.minimumContactDuration &&
          duration <= config.maximumContactDuration) {
        durations.add(duration);
      }
    }
    return durations;
  }

  bool _touchdownsAlternate(List<RunningGaitEvent> touchdowns) {
    for (var index = 1; index < touchdowns.length; index += 1) {
      if (touchdowns[index].side == touchdowns[index - 1].side) {
        return false;
      }
    }
    return true;
  }

  String? _qualityReason({
    required int validFrameCount,
    required double timingConfidence,
    required double sideViewConfidence,
    required double frameConfidence,
  }) {
    if (validFrameCount < config.minimumValidFrames) {
      return 'insufficient_timing_window';
    }
    if (timingConfidence < config.minimumMetricConfidence) {
      return 'insufficient_temporal_resolution';
    }
    if (sideViewConfidence < config.minimumSideViewConfidence) {
      return 'side_view_required';
    }
    if (frameConfidence < config.minimumMetricConfidence) {
      return 'low_confidence';
    }
    return null;
  }

  RunningGaitPhase _currentPhase() {
    final left = _feet[RunningFootSide.left]!.contact;
    final right = _feet[RunningFootSide.right]!.contact;
    return switch ((left, right)) {
      (true, true) => RunningGaitPhase.doubleContact,
      (true, false) => RunningGaitPhase.leftContact,
      (false, true) => RunningGaitPhase.rightContact,
      (false, false) => RunningGaitPhase.flight,
      _ => RunningGaitPhase.unknown,
    };
  }

  List<RunningGaitEvent> _recentEvents(DateTime timestamp) {
    final recent = <RunningGaitEvent>[
      for (final event in _events)
        if (timestamp.difference(event.timestamp) <= config.analysisWindow)
          event,
    ];
    _events
      ..clear()
      ..addAll(recent);
    return List<RunningGaitEvent>.unmodifiable(recent);
  }

  double _timingConfidence() {
    if (_frames.length < 2) {
      return 0;
    }
    final frames = _frames.toList(growable: false);
    var validGapCount = 0;
    var totalGapCount = 0;
    for (var index = 1; index < frames.length; index += 1) {
      totalGapCount += 1;
      final gap =
          frames[index].timestamp.difference(frames[index - 1].timestamp);
      if (gap > Duration.zero && gap <= config.maximumFrameGap) {
        validGapCount += 1;
      }
    }
    final span = frames.last.timestamp.difference(frames.first.timestamp);
    final spanFactor = (span.inMilliseconds / 900).clamp(0.0, 1.0).toDouble();
    final densityTarget = math.max(
      1.0,
      span.inMilliseconds /
          math.max(1, config.targetFrameInterval.inMilliseconds),
    );
    final densityFactor =
        (_frames.length / densityTarget).clamp(0.0, 1.0).toDouble();
    final gapFactor = totalGapCount == 0 ? 0.0 : validGapCount / totalGapCount;
    return (spanFactor * 0.38 + densityFactor * 0.27 + gapFactor * 0.35)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  double _sideViewConfidence() {
    if (_frames.isEmpty) {
      return 0;
    }
    final samples = _frames
        .map((frame) => frame.sideViewConfidence)
        .toList(growable: false);
    return _average(samples).clamp(0.0, 1.0).toDouble();
  }

  double _frameConfidence() {
    if (_frames.isEmpty) {
      return 0;
    }
    final samples =
        _frames.map((frame) => frame.averageConfidence).toList(growable: false);
    return _average(samples).clamp(0.0, 1.0).toDouble();
  }

  _GaitFrameSample? _extractSample(RunningPoseObservation observation) {
    final leftShoulder = observation.landmark(
      RunningPoseLandmarkType.leftShoulder,
      minimumLikelihood: config.minimumLandmarkLikelihood,
    );
    final rightShoulder = observation.landmark(
      RunningPoseLandmarkType.rightShoulder,
      minimumLikelihood: config.minimumLandmarkLikelihood,
    );
    final leftHip = observation.landmark(
      RunningPoseLandmarkType.leftHip,
      minimumLikelihood: config.minimumLandmarkLikelihood,
    );
    final rightHip = observation.landmark(
      RunningPoseLandmarkType.rightHip,
      minimumLikelihood: config.minimumLandmarkLikelihood,
    );
    final leftAnkle = observation.landmark(
      RunningPoseLandmarkType.leftAnkle,
      minimumLikelihood: config.minimumLandmarkLikelihood,
    );
    final rightAnkle = observation.landmark(
      RunningPoseLandmarkType.rightAnkle,
      minimumLikelihood: config.minimumLandmarkLikelihood,
    );
    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null ||
        leftAnkle == null ||
        rightAnkle == null) {
      return null;
    }

    final shoulderCenter =
        _midpoint(leftShoulder.position, rightShoulder.position);
    final hipCenter = _midpoint(leftHip.position, rightHip.position);
    final ankleCenter = _midpoint(leftAnkle.position, rightAnkle.position);
    final bodyScale = math.max(
      _distance(shoulderCenter, hipCenter),
      _distance(hipCenter, ankleCenter),
    );
    if (bodyScale <= 0) {
      return null;
    }

    final footSamples = <RunningFootSide, _FootSample>{};
    final leftFoot = _extractFoot(
      observation,
      ankleType: RunningPoseLandmarkType.leftAnkle,
      heelType: RunningPoseLandmarkType.leftHeel,
      footIndexType: RunningPoseLandmarkType.leftFootIndex,
    );
    final rightFoot = _extractFoot(
      observation,
      ankleType: RunningPoseLandmarkType.rightAnkle,
      heelType: RunningPoseLandmarkType.rightHeel,
      footIndexType: RunningPoseLandmarkType.rightFootIndex,
    );
    if (leftFoot != null) {
      footSamples[RunningFootSide.left] = leftFoot;
    }
    if (rightFoot != null) {
      footSamples[RunningFootSide.right] = rightFoot;
    }
    if (footSamples.length < 2) {
      return null;
    }

    final bodyBox = _bodyBox(observation);
    final bodyHeight = bodyBox?.height ?? bodyScale;
    final shoulderSpan =
        _distance(leftShoulder.position, rightShoulder.position);
    final hipSpan = _distance(leftHip.position, rightHip.position);
    final widthRatio =
        math.max(shoulderSpan, hipSpan) / math.max(bodyHeight, 1);
    final sideViewConfidence =
        (1.0 - ((widthRatio - 0.18) / 0.18)).clamp(0.0, 1.0).toDouble();
    final coreConfidence = _average(<double>[
      leftShoulder.likelihood,
      rightShoulder.likelihood,
      leftHip.likelihood,
      rightHip.likelihood,
      leftAnkle.likelihood,
      rightAnkle.likelihood,
    ]);
    final footConfidence = _average(
      footSamples.values.map((foot) => foot.confidence).toList(growable: false),
    );

    return _GaitFrameSample(
      timestamp: _lastTimestamp!,
      bodyScale: bodyScale,
      feet: footSamples,
      sideViewConfidence: sideViewConfidence,
      averageConfidence: ((coreConfidence * 0.52) + (footConfidence * 0.48))
          .clamp(0.0, 1.0)
          .toDouble(),
    );
  }

  _FootSample? _extractFoot(
    RunningPoseObservation observation, {
    required RunningPoseLandmarkType ankleType,
    required RunningPoseLandmarkType heelType,
    required RunningPoseLandmarkType footIndexType,
  }) {
    final points = <RunningPoseLandmark>[];
    for (final type in <RunningPoseLandmarkType>[
      ankleType,
      heelType,
      footIndexType,
    ]) {
      final landmark = observation.landmark(
        type,
        minimumLikelihood: config.minimumLandmarkLikelihood,
      );
      if (landmark != null) {
        points.add(landmark);
      }
    }
    if (points.isEmpty) {
      return null;
    }
    final groundPointY = points
        .map((landmark) => landmark.position.dy)
        .reduce((value, element) => value > element ? value : element);
    final confidence = _average(
      points.map((landmark) => landmark.likelihood).toList(growable: false),
    );
    return _FootSample(
      groundPointY: groundPointY,
      confidence: confidence,
    );
  }

  double? _rollingGroundY() {
    final footYs = <double>[
      for (final frame in _frames)
        for (final foot in frame.feet.values)
          if (foot.confidence >= config.minimumLandmarkLikelihood)
            foot.groundPointY,
    ];
    if (footYs.length < 2) {
      return null;
    }
    footYs.sort();
    final windowSize = math.max(1, (footYs.length * 0.22).ceil());
    return _average(footYs.sublist(footYs.length - windowSize));
  }

  void _trim(DateTime timestamp) {
    while (_frames.isNotEmpty &&
        timestamp.difference(_frames.first.timestamp) > config.analysisWindow) {
      _frames.removeFirst();
    }
  }

  double _verticalVelocity({
    required double previousFootY,
    required DateTime previousTimestamp,
    required double currentFootY,
    required DateTime currentTimestamp,
    required double bodyScale,
  }) {
    final elapsedSeconds =
        currentTimestamp.difference(previousTimestamp).inMicroseconds /
            Duration.microsecondsPerSecond;
    if (elapsedSeconds <= 0) {
      return 0;
    }
    return (currentFootY - previousFootY) /
        math.max(bodyScale, 1.0) /
        elapsedSeconds;
  }

  Rect? _bodyBox(RunningPoseObservation observation) {
    final points = <Offset>[
      for (final landmark in observation.landmarks.values)
        if (landmark.likelihood >= config.minimumLandmarkLikelihood)
          landmark.position,
    ];
    if (points.isEmpty) {
      return null;
    }
    final xs = points.map((point) => point.dx);
    final ys = points.map((point) => point.dy);
    return Rect.fromLTRB(
      xs.reduce(math.min),
      ys.reduce(math.min),
      xs.reduce(math.max),
      ys.reduce(math.max),
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

  double _average(List<double> values) {
    if (values.isEmpty) {
      return 0;
    }
    return values.reduce((sum, value) => sum + value) / values.length;
  }
}

class _GaitFrameSample {
  final DateTime timestamp;
  final double bodyScale;
  final Map<RunningFootSide, _FootSample> feet;
  final double sideViewConfidence;
  final double averageConfidence;

  const _GaitFrameSample({
    required this.timestamp,
    required this.bodyScale,
    required this.feet,
    required this.sideViewConfidence,
    required this.averageConfidence,
  });

  _FootSample? foot(RunningFootSide side) => feet[side];
}

class _FootSample {
  final double groundPointY;
  final double confidence;

  const _FootSample({
    required this.groundPointY,
    required this.confidence,
  });
}

class _FootTracker {
  bool? contact;
  bool? pendingContact;
  DateTime? pendingSince;
  DateTime? lastEventAt;
  RunningGaitEventType? lastEventType;
  DateTime? lastTouchdownAt;
  double? lastFootY;
  DateTime? lastFootTimestamp;
  double lastSignalConfidence = 0;

  void clearPending() {
    pendingContact = null;
    pendingSince = null;
  }

  void reset() {
    contact = null;
    pendingContact = null;
    pendingSince = null;
    lastEventAt = null;
    lastEventType = null;
    lastTouchdownAt = null;
    lastFootY = null;
    lastFootTimestamp = null;
    lastSignalConfidence = 0;
  }
}
