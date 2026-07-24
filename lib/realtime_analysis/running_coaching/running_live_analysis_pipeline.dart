import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import '../../domain/entities/running_live_coaching_state.dart';
import '../../domain/entities/running_video_analysis_result.dart';
import 'running_gait_event_detector.dart';
import 'running_temporal_pose_tracker.dart';

class RunningLiveAnalysisPipeline {
  final RunningLiveAnalysisConfig config;
  final Queue<_TimedFrameSample> _samples = Queue<_TimedFrameSample>();
  final RunningTemporalPoseTracker _poseTracker;
  final RunningGaitEventDetector _gaitEventDetector;
  DateTime? _lastReliableFullBodyEvidenceAt;
  RunningLiveFramingIssue? _lastRawFramingIssue;
  int _sameRawFramingIssueFrames = 0;

  RunningLiveAnalysisPipeline({
    this.config = const RunningLiveAnalysisConfig(),
    RunningTemporalPoseTracker? poseTracker,
    RunningGaitEventDetector? gaitEventDetector,
  })  : _poseTracker = poseTracker ?? RunningTemporalPoseTracker(),
        _gaitEventDetector = gaitEventDetector ??
            RunningGaitEventDetector(
              config: RunningGaitEventDetectorConfig(
                minimumLandmarkLikelihood: config.minimumLikelihood,
              ),
            );

  void reset() {
    _samples.clear();
    _poseTracker.reset();
    _gaitEventDetector.reset();
    _lastReliableFullBodyEvidenceAt = null;
    _lastRawFramingIssue = null;
    _sameRawFramingIssueFrames = 0;
  }

  RunningLiveAnalysisSnapshot ingestObservation(
    RunningPoseObservation? observation, {
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    _trimSamples(now);

    RunningLiveFramingIssue? framingIssue;
    final trackedObservation = _poseTracker.track(
      observation,
      timestamp: now,
    );
    if (trackedObservation == null) {
      framingIssue = RunningLiveFramingIssue.noRunnerDetected;
    } else {
      final extractor = _RunningFrameExtractor(config.minimumLikelihood);
      final sample = extractor.extract(trackedObservation);
      final framingDecision = _RunningFramingPolicy(
        config.minimumLikelihood,
        extractor,
      ).resolve(trackedObservation, sample: sample);
      framingIssue = _stabilizeFramingIssue(framingDecision, now);
      if (framingIssue == null && sample != null) {
        _samples.add(_TimedFrameSample(sample: sample, timestamp: now));
        _trimSamples(now);
      } else {
        framingIssue ??= RunningLiveFramingIssue.noRunnerDetected;
      }
    }

    final gaitAnalysis = _gaitEventDetector.ingestObservation(
      trackedObservation,
      timestamp: now,
      cameraSideViewFramingOk: framingIssue == null,
    );

    return RunningLiveAnalysisSnapshot(
      framingIssue: framingIssue,
      analysisResult: _RunningMetricAggregator(
        minimumTrackedFrames: config.minimumTrackedFrames,
      ).build(_samples.toList(growable: false)),
      trackedObservation: trackedObservation,
      gaitAnalysis: gaitAnalysis,
      trackedFrames: _samples.length,
    );
  }

  void _trimSamples(DateTime now) {
    while (_samples.isNotEmpty &&
        now.difference(_samples.first.timestamp) > config.analysisWindow) {
      _samples.removeFirst();
    }
  }

  RunningLiveFramingIssue? _stabilizeFramingIssue(
    _RunningFramingDecision decision,
    DateTime now,
  ) {
    final rawIssue = decision.issue;
    if (decision.reliableFullBodyEvidence) {
      _lastReliableFullBodyEvidenceAt = now;
    }
    if (rawIssue == null) {
      _lastRawFramingIssue = null;
      _sameRawFramingIssueFrames = 0;
      return null;
    }

    if (_lastRawFramingIssue == rawIssue) {
      _sameRawFramingIssueFrames += 1;
    } else {
      _lastRawFramingIssue = rawIssue;
      _sameRawFramingIssueFrames = 1;
    }

    if (rawIssue == RunningLiveFramingIssue.noRunnerDetected) {
      return rawIssue;
    }

    if (rawIssue == RunningLiveFramingIssue.stepBack) {
      if (!decision.stepBackCropSupported) {
        return RunningLiveFramingIssue.trackingUncertain;
      }
      if (_sameRawFramingIssueFrames < config.sustainedStepBackFrames) {
        return RunningLiveFramingIssue.trackingUncertain;
      }
      return rawIssue;
    }

    if (rawIssue == RunningLiveFramingIssue.moveCloser) {
      final lastReliableAt = _lastReliableFullBodyEvidenceAt;
      final hasRecentReliableBodyEvidence = lastReliableAt != null &&
          now.difference(lastReliableAt) <= const Duration(milliseconds: 1200);
      if (_sameRawFramingIssueFrames < config.sustainedMoveCloserFrames) {
        return hasRecentReliableBodyEvidence
            ? null
            : RunningLiveFramingIssue.trackingUncertain;
      }
      return rawIssue;
    }

    if (decision.hardFailure) {
      return rawIssue;
    }

    final lastReliableAt = _lastReliableFullBodyEvidenceAt;
    final hasRecentReliableBodyEvidence = lastReliableAt != null &&
        now.difference(lastReliableAt) <= const Duration(milliseconds: 1200);

    if (decision.trackingUncertainCandidate &&
        hasRecentReliableBodyEvidence &&
        _sameRawFramingIssueFrames <= 3) {
      return RunningLiveFramingIssue.trackingUncertain;
    }

    if (decision.softFailure &&
        hasRecentReliableBodyEvidence &&
        _sameRawFramingIssueFrames <= 2) {
      return null;
    }

    return rawIssue;
  }
}

class RunningLiveAnalysisConfig {
  final Duration analysisWindow;
  final int minimumTrackedFrames;
  final double minimumLikelihood;
  final Duration cueDwellTime;
  final int sustainedStepBackFrames;
  final int sustainedMoveCloserFrames;

  const RunningLiveAnalysisConfig({
    this.analysisWindow = const Duration(milliseconds: 2400),
    this.minimumTrackedFrames = 7,
    this.minimumLikelihood = 0.35,
    this.cueDwellTime = const Duration(milliseconds: 600),
    this.sustainedStepBackFrames = 3,
    this.sustainedMoveCloserFrames = 4,
  });
}

class RunningLiveAnalysisSnapshot {
  final RunningLiveFramingIssue? framingIssue;
  final RunningVideoAnalysisResult? analysisResult;
  final RunningPoseObservation? trackedObservation;
  final RunningGaitAnalysis gaitAnalysis;
  final int trackedFrames;

  const RunningLiveAnalysisSnapshot({
    required this.framingIssue,
    required this.analysisResult,
    required this.trackedObservation,
    required this.gaitAnalysis,
    required this.trackedFrames,
  });
}

class _RunningFramingPolicy {
  final double minimumLikelihood;
  final _RunningFrameExtractor extractor;

  const _RunningFramingPolicy(this.minimumLikelihood, this.extractor);

  _RunningFramingDecision resolve(
    RunningPoseObservation observation, {
    required _FrameSample? sample,
  }) {
    final imageSize = observation.imageSize;
    if (imageSize.width <= 0 || imageSize.height <= 0) {
      return const _RunningFramingDecision(
        issue: RunningLiveFramingIssue.noRunnerDetected,
        hardFailure: true,
      );
    }

    final leftShoulder = observation.landmark(
      RunningPoseLandmarkType.leftShoulder,
      minimumLikelihood: minimumLikelihood,
    );
    final rightShoulder = observation.landmark(
      RunningPoseLandmarkType.rightShoulder,
      minimumLikelihood: minimumLikelihood,
    );
    final leftHip = observation.landmark(
      RunningPoseLandmarkType.leftHip,
      minimumLikelihood: minimumLikelihood,
    );
    final rightHip = observation.landmark(
      RunningPoseLandmarkType.rightHip,
      minimumLikelihood: minimumLikelihood,
    );

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null) {
      return const _RunningFramingDecision(
        issue: RunningLiveFramingIssue.noRunnerDetected,
        hardFailure: true,
      );
    }

    final visibleLandmarks = <RunningPoseLandmark>[
      for (final type in RunningPoseLandmarkType.values)
        if (observation.landmark(type, minimumLikelihood: minimumLikelihood)
            case final landmark?)
          landmark,
    ];

    final leftAnkle = observation.landmark(
      RunningPoseLandmarkType.leftAnkle,
      minimumLikelihood: minimumLikelihood,
    );
    final rightAnkle = observation.landmark(
      RunningPoseLandmarkType.rightAnkle,
      minimumLikelihood: minimumLikelihood,
    );
    final leftKnee = observation.landmark(
      RunningPoseLandmarkType.leftKnee,
      minimumLikelihood: minimumLikelihood,
    );
    final rightKnee = observation.landmark(
      RunningPoseLandmarkType.rightKnee,
      minimumLikelihood: minimumLikelihood,
    );
    if (leftAnkle == null || rightAnkle == null) {
      final hasKneeEvidence = leftKnee != null && rightKnee != null;
      final kneeBottomRatio = hasKneeEvidence
          ? math.max(leftKnee.position.dy, rightKnee.position.dy) /
              imageSize.height
          : 0.0;
      final visibleBottomRatio = visibleLandmarks
              .map((landmark) => landmark.position.dy)
              .reduce(math.max) /
          imageSize.height;
      final cropSupported = hasKneeEvidence &&
          visibleLandmarks.length >= 8 &&
          (kneeBottomRatio >= 0.84 || visibleBottomRatio >= 0.92);
      return _RunningFramingDecision(
        issue: cropSupported
            ? RunningLiveFramingIssue.stepBack
            : RunningLiveFramingIssue.trackingUncertain,
        trackingUncertainCandidate: true,
        stepBackCropSupported: cropSupported,
      );
    }

    if (visibleLandmarks.length < 6) {
      return const _RunningFramingDecision(
        issue: RunningLiveFramingIssue.noRunnerDetected,
        hardFailure: true,
      );
    }

    final xs = visibleLandmarks.map((landmark) => landmark.position.dx);
    final ys = visibleLandmarks.map((landmark) => landmark.position.dy);
    final minX = xs.reduce(math.min);
    final maxX = xs.reduce(math.max);
    final minY = ys.reduce(math.min);
    final maxY = ys.reduce(math.max);
    final boxHeightRatio = (maxY - minY) / imageSize.height;
    final boxWidthRatio = (maxX - minX) / imageSize.width;
    final centerXRatio = ((minX + maxX) / 2) / imageSize.width;
    final topMarginRatio = minY / imageSize.height;
    final bottomMarginRatio = (imageSize.height - maxY) / imageSize.height;

    final extractedSample = sample ?? extractor.extract(observation);
    final reliableFullBodyEvidence = extractedSample != null &&
        visibleLandmarks.length >= 10 &&
        extractedSample.requiredLandmarkConfidence >=
            math.max(0.62, minimumLikelihood + 0.15);

    final hardFitFailure = boxHeightRatio > 0.94 ||
        boxWidthRatio > 0.88 ||
        topMarginRatio < 0.015 ||
        bottomMarginRatio < 0.015;
    final softFitFailure = boxHeightRatio > 0.9 ||
        boxWidthRatio > 0.82 ||
        topMarginRatio < 0.03 ||
        bottomMarginRatio < 0.03;
    if (hardFitFailure || softFitFailure) {
      return _RunningFramingDecision(
        issue: RunningLiveFramingIssue.stepBack,
        reliableFullBodyEvidence: reliableFullBodyEvidence,
        softFailure: !hardFitFailure && reliableFullBodyEvidence,
        hardFailure: hardFitFailure,
        stepBackCropSupported: true,
      );
    }

    final bodyScaleRatio = extractedSample == null
        ? 0.0
        : extractedSample.bodyScale / imageSize.height;
    final sufficientMetricScale =
        reliableFullBodyEvidence && bodyScaleRatio >= 0.14;
    if (boxHeightRatio < 0.28 && !sufficientMetricScale) {
      final hardSmallFailure = boxHeightRatio < 0.22;
      return _RunningFramingDecision(
        issue: RunningLiveFramingIssue.moveCloser,
        reliableFullBodyEvidence: reliableFullBodyEvidence,
        softFailure: !hardSmallFailure && reliableFullBodyEvidence,
        hardFailure: hardSmallFailure,
      );
    }

    if (centerXRatio < 0.28 || centerXRatio > 0.72) {
      final hardCenterFailure = centerXRatio < 0.22 || centerXRatio > 0.78;
      return _RunningFramingDecision(
        issue: RunningLiveFramingIssue.centerRunner,
        reliableFullBodyEvidence: reliableFullBodyEvidence,
        softFailure: !hardCenterFailure && reliableFullBodyEvidence,
        hardFailure: hardCenterFailure,
      );
    }

    if (extractedSample == null) {
      return const _RunningFramingDecision(
        issue: RunningLiveFramingIssue.noRunnerDetected,
        hardFailure: true,
      );
    }

    final bodyHeight = maxY - minY;
    final shoulderWidthRatio =
        extractedSample.shoulderSpan / math.max(bodyHeight, 1);
    final hipWidthRatio = extractedSample.hipSpan / math.max(bodyHeight, 1);
    if (math.max(shoulderWidthRatio, hipWidthRatio) > 0.34) {
      return _RunningFramingDecision(
        issue: RunningLiveFramingIssue.turnSideways,
        reliableFullBodyEvidence: reliableFullBodyEvidence,
      );
    }

    return _RunningFramingDecision(
      reliableFullBodyEvidence: reliableFullBodyEvidence,
    );
  }
}

class _RunningFramingDecision {
  final RunningLiveFramingIssue? issue;
  final bool reliableFullBodyEvidence;
  final bool trackingUncertainCandidate;
  final bool softFailure;
  final bool hardFailure;
  final bool stepBackCropSupported;

  const _RunningFramingDecision({
    this.issue,
    this.reliableFullBodyEvidence = false,
    this.trackingUncertainCandidate = false,
    this.softFailure = false,
    this.hardFailure = false,
    this.stepBackCropSupported = false,
  });
}

class _RunningFrameExtractor {
  final double minimumLikelihood;

  const _RunningFrameExtractor(this.minimumLikelihood);

  _FrameSample? extract(RunningPoseObservation observation) {
    final leftShoulder = observation.landmark(
      RunningPoseLandmarkType.leftShoulder,
      minimumLikelihood: minimumLikelihood,
    );
    final rightShoulder = observation.landmark(
      RunningPoseLandmarkType.rightShoulder,
      minimumLikelihood: minimumLikelihood,
    );
    final leftHip = observation.landmark(
      RunningPoseLandmarkType.leftHip,
      minimumLikelihood: minimumLikelihood,
    );
    final rightHip = observation.landmark(
      RunningPoseLandmarkType.rightHip,
      minimumLikelihood: minimumLikelihood,
    );
    final leftKnee = observation.landmark(
      RunningPoseLandmarkType.leftKnee,
      minimumLikelihood: minimumLikelihood,
    );
    final rightKnee = observation.landmark(
      RunningPoseLandmarkType.rightKnee,
      minimumLikelihood: minimumLikelihood,
    );
    final leftAnkle = observation.landmark(
      RunningPoseLandmarkType.leftAnkle,
      minimumLikelihood: minimumLikelihood,
    );
    final rightAnkle = observation.landmark(
      RunningPoseLandmarkType.rightAnkle,
      minimumLikelihood: minimumLikelihood,
    );
    final leftHeel = observation.landmark(
      RunningPoseLandmarkType.leftHeel,
      minimumLikelihood: minimumLikelihood,
    );
    final rightHeel = observation.landmark(
      RunningPoseLandmarkType.rightHeel,
      minimumLikelihood: minimumLikelihood,
    );
    final leftElbow = observation.landmark(
      RunningPoseLandmarkType.leftElbow,
      minimumLikelihood: minimumLikelihood,
    );
    final rightElbow = observation.landmark(
      RunningPoseLandmarkType.rightElbow,
      minimumLikelihood: minimumLikelihood,
    );
    final leftWrist = observation.landmark(
      RunningPoseLandmarkType.leftWrist,
      minimumLikelihood: minimumLikelihood,
    );
    final rightWrist = observation.landmark(
      RunningPoseLandmarkType.rightWrist,
      minimumLikelihood: minimumLikelihood,
    );
    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null ||
        leftKnee == null ||
        rightKnee == null ||
        leftAnkle == null ||
        rightAnkle == null) {
      return null;
    }

    final shoulderCenter = _midpoint(
      leftShoulder.position,
      rightShoulder.position,
    );
    final hipCenter = _midpoint(leftHip.position, rightHip.position);
    final ankleCenter = _midpoint(leftAnkle.position, rightAnkle.position);
    final torsoScale = _distance(shoulderCenter, hipCenter);
    final legScale = _distance(hipCenter, ankleCenter);
    final bodyScale = math.max(torsoScale, legScale);
    if (bodyScale < observation.imageSize.height * 0.1) {
      return null;
    }

    return _FrameSample(
      leftShoulder: leftShoulder.position,
      rightShoulder: rightShoulder.position,
      leftHip: leftHip.position,
      rightHip: rightHip.position,
      leftKnee: leftKnee.position,
      rightKnee: rightKnee.position,
      shoulderCenter: shoulderCenter,
      hipCenter: hipCenter,
      leftAnkle: leftAnkle.position,
      rightAnkle: rightAnkle.position,
      leftHeel: leftHeel?.position,
      rightHeel: rightHeel?.position,
      leftElbow: leftElbow?.position,
      rightElbow: rightElbow?.position,
      leftWrist: leftWrist?.position,
      rightWrist: rightWrist?.position,
      bodyScale: bodyScale,
      shoulderSpan: _distance(
        leftShoulder.position,
        rightShoulder.position,
      ),
      hipSpan: _distance(leftHip.position, rightHip.position),
      requiredLandmarkConfidence: _minimumLikelihood([
        leftShoulder,
        rightShoulder,
        leftHip,
        rightHip,
        leftKnee,
        rightKnee,
        leftAnkle,
        rightAnkle,
      ]),
      armLandmarkConfidence: _armLandmarkConfidence(
        leftShoulder: leftShoulder,
        rightShoulder: rightShoulder,
        leftElbow: leftElbow,
        rightElbow: rightElbow,
        leftWrist: leftWrist,
        rightWrist: rightWrist,
      ),
    );
  }
}

class _RunningMetricAggregator {
  final int minimumTrackedFrames;

  const _RunningMetricAggregator({required this.minimumTrackedFrames});

  RunningVideoAnalysisResult? build(List<_TimedFrameSample> timedSamples) {
    if (timedSamples.length < minimumTrackedFrames) {
      return null;
    }

    final samples =
        timedSamples.map((entry) => entry.sample).toList(growable: false);
    final duration =
        timedSamples.last.timestamp.difference(timedSamples.first.timestamp);
    final direction = _resolveDirection(samples);
    final averageScale = samples
            .map((sample) => sample.bodyScale)
            .reduce((sum, value) => sum + value) /
        samples.length;
    final leanDegrees = samples
            .map((sample) => sample.forwardLeanDegrees(direction))
            .reduce((sum, value) => sum + value) /
        samples.length;
    final shoulderYs = samples
        .map((sample) => sample.shoulderCenter.dy)
        .toList(growable: false);
    final bounceRatio =
        ((shoulderYs.reduce(math.max) - shoulderYs.reduce(math.min)) /
                math.max(averageScale, 1))
            .clamp(0.0, double.infinity);
    final loadingSamples = samples.toList(growable: false)
      ..sort(
        (first, second) => first
            .leadFootStrikeRatio(direction)
            .compareTo(second.leadFootStrikeRatio(direction)),
      );
    final loadingWindowSize = math.max(1, loadingSamples.length ~/ 3);
    final stanceSamples =
        loadingSamples.sublist(loadingSamples.length - loadingWindowSize);
    final footStrikeRatio = stanceSamples
            .map((sample) => sample.leadFootStrikeRatio(direction))
            .reduce((sum, value) => sum + value) /
        stanceSamples.length;
    final kneeAngles = <double>[
      for (final sample in stanceSamples)
        if (sample.leadKneeAngleDegrees(direction) case final angle?) angle,
    ];
    final elbowAngleSamples = <({double angle, double confidence})>[
      for (final sample in samples)
        if (sample.averageElbowAngleDegrees case final angle?)
          (
            angle: angle,
            confidence: sample.armLandmarkConfidence ??
                sample.requiredLandmarkConfidence,
          ),
    ];
    if (kneeAngles.isEmpty || elbowAngleSamples.isEmpty) {
      return null;
    }
    final stanceKneeAngle =
        kneeAngles.reduce((sum, value) => sum + value) / kneeAngles.length;
    final elbowAngle = _average(
      elbowAngleSamples.map((sample) => sample.angle).toList(growable: false),
    );
    final sharedQuality = _landmarkQuality(
      sampleCount: samples.length,
      landmarkConfidence: _average(
        samples
            .map((sample) => sample.requiredLandmarkConfidence)
            .toList(growable: false),
      ),
    );
    final armQuality = _landmarkQuality(
      sampleCount: elbowAngleSamples.length,
      landmarkConfidence: _average(
        elbowAngleSamples
            .map((sample) => sample.confidence)
            .toList(growable: false),
      ),
    );
    final contactQuality = _contactPhaseQuality(
      stanceSamples,
      direction: direction,
      fallback: sharedQuality,
    );

    return RunningVideoAnalysisResult(
      videoDuration: duration < const Duration(milliseconds: 400)
          ? const Duration(milliseconds: 400)
          : duration,
      sampledFrames: samples.length,
      validFrames: samples.length,
      direction: direction,
      forwardLeanDegrees: _roundTo3(leanDegrees),
      verticalBounceRatio: _roundTo3(bounceRatio),
      footStrikeDistanceRatio: _roundTo3(footStrikeRatio),
      stanceKneeAngleDegrees: _roundTo3(stanceKneeAngle),
      elbowAngleDegrees: _roundTo3(elbowAngle),
      metricQualities: <RunningCoachMetric, RunningMetricQuality>{
        RunningCoachMetric.posture: sharedQuality,
        RunningCoachMetric.bounce: sharedQuality,
        RunningCoachMetric.footStrike: contactQuality,
        RunningCoachMetric.kneeFlexion: contactQuality,
        RunningCoachMetric.armCarriage: armQuality,
      },
    );
  }

  RunningMetricQuality _landmarkQuality({
    required int sampleCount,
    required double landmarkConfidence,
  }) {
    final sampleFactor = (sampleCount / 10).clamp(0.0, 1.0).toDouble();
    final confidence =
        math.min(sampleFactor, landmarkConfidence).clamp(0.0, 1.0).toDouble();
    final reason = sampleCount < minimumTrackedFrames
        ? 'limited_samples'
        : landmarkConfidence < 0.6
            ? 'low_confidence'
            : null;
    return RunningMetricQuality(
      confidence: confidence,
      sampleCount: sampleCount,
      reason: reason,
    );
  }

  RunningMetricQuality _contactPhaseQuality(
    List<_FrameSample> stanceSamples, {
    required RunningDirection direction,
    required RunningMetricQuality fallback,
  }) {
    if (stanceSamples.isEmpty) {
      return const RunningMetricQuality(
        confidence: 0,
        sampleCount: 0,
        reason: 'contact_phase_proxy',
      );
    }
    final ratios = stanceSamples
        .map((sample) => sample.leadFootStrikeRatio(direction))
        .toList(growable: false);
    final minRatio = ratios.reduce(math.min);
    final maxRatio = ratios.reduce(math.max);
    final landmarkConfidence = _average(
      stanceSamples
          .map((sample) => sample.requiredLandmarkConfidence)
          .toList(growable: false),
    );
    final reachSpread = (maxRatio - minRatio).abs();
    final sampleFactor = (stanceSamples.length / 3).clamp(0.0, 1.0);
    final spreadFactor = (reachSpread / 0.08).clamp(0.0, 1.0);
    final contactConfidence =
        ((sampleFactor * 0.65) + (spreadFactor * 0.20) + 0.15).clamp(0.0, 1.0);
    final confidence = math
        .min(math.min(fallback.confidence, contactConfidence),
            landmarkConfidence)
        .clamp(0.0, 1.0)
        .toDouble();
    final reason = confidence < 0.65
        ? landmarkConfidence < 0.6 || fallback.reason == 'low_confidence'
            ? 'low_confidence'
            : 'contact_phase_proxy'
        : fallback.reason;
    return RunningMetricQuality(
      confidence: confidence,
      sampleCount: stanceSamples.length,
      reason: reason,
    );
  }

  RunningDirection _resolveDirection(List<_FrameSample> samples) {
    final hipMovement = samples.last.hipCenter.dx - samples.first.hipCenter.dx;
    final averageScale = samples
            .map((sample) => sample.bodyScale)
            .reduce((sum, value) => sum + value) /
        samples.length;
    if (hipMovement.abs() < averageScale * 0.12) {
      return RunningDirection.stationary;
    }
    return hipMovement > 0
        ? RunningDirection.leftToRight
        : RunningDirection.rightToLeft;
  }
}

class _TimedFrameSample {
  final _FrameSample sample;
  final DateTime timestamp;

  const _TimedFrameSample({
    required this.sample,
    required this.timestamp,
  });
}

class _FrameSample {
  final Offset leftShoulder;
  final Offset rightShoulder;
  final Offset leftHip;
  final Offset rightHip;
  final Offset leftKnee;
  final Offset rightKnee;
  final Offset shoulderCenter;
  final Offset hipCenter;
  final Offset leftAnkle;
  final Offset rightAnkle;
  final Offset? leftHeel;
  final Offset? rightHeel;
  final Offset? leftElbow;
  final Offset? rightElbow;
  final Offset? leftWrist;
  final Offset? rightWrist;
  final double bodyScale;
  final double shoulderSpan;
  final double hipSpan;
  final double requiredLandmarkConfidence;
  final double? armLandmarkConfidence;

  const _FrameSample({
    required this.leftShoulder,
    required this.rightShoulder,
    required this.leftHip,
    required this.rightHip,
    required this.leftKnee,
    required this.rightKnee,
    required this.shoulderCenter,
    required this.hipCenter,
    required this.leftAnkle,
    required this.rightAnkle,
    required this.leftHeel,
    required this.rightHeel,
    required this.leftElbow,
    required this.rightElbow,
    required this.leftWrist,
    required this.rightWrist,
    required this.bodyScale,
    required this.shoulderSpan,
    required this.hipSpan,
    required this.requiredLandmarkConfidence,
    required this.armLandmarkConfidence,
  });

  double forwardLeanDegrees(RunningDirection direction) {
    final verticalTravel = math.max(1.0, hipCenter.dy - shoulderCenter.dy);
    final forwardOffset = switch (direction) {
      RunningDirection.leftToRight => shoulderCenter.dx - hipCenter.dx,
      RunningDirection.rightToLeft => hipCenter.dx - shoulderCenter.dx,
      RunningDirection.stationary => (shoulderCenter.dx - hipCenter.dx).abs(),
    };
    if (direction != RunningDirection.stationary && forwardOffset <= 0) {
      return 0;
    }
    return math.atan2(forwardOffset.abs(), verticalTravel) * 180 / math.pi;
  }

  double leadFootStrikeRatio(RunningDirection direction) {
    final leftFoot = leftHeel ?? leftAnkle;
    final rightFoot = rightHeel ?? rightAnkle;
    final forwardReach = switch (direction) {
      RunningDirection.leftToRight =>
        math.max(leftFoot.dx, rightFoot.dx) - hipCenter.dx,
      RunningDirection.rightToLeft =>
        hipCenter.dx - math.min(leftFoot.dx, rightFoot.dx),
      RunningDirection.stationary => math.max(
          (leftFoot.dx - hipCenter.dx).abs(),
          (rightFoot.dx - hipCenter.dx).abs(),
        ),
    };
    return forwardReach / math.max(bodyScale, 1.0);
  }

  double? get averageElbowAngleDegrees {
    final angles = <double>[
      if (leftElbow != null && leftWrist != null)
        _jointAngle(leftShoulder, leftElbow!, leftWrist!),
      if (rightElbow != null && rightWrist != null)
        _jointAngle(rightShoulder, rightElbow!, rightWrist!),
    ];
    if (angles.isEmpty) {
      return null;
    }
    return angles.reduce((sum, value) => sum + value) / angles.length;
  }

  double? leadKneeAngleDegrees(RunningDirection direction) {
    final useLeft = switch (direction) {
      RunningDirection.leftToRight =>
        (leftHeel ?? leftAnkle).dx >= (rightHeel ?? rightAnkle).dx,
      RunningDirection.rightToLeft =>
        (leftHeel ?? leftAnkle).dx <= (rightHeel ?? rightAnkle).dx,
      RunningDirection.stationary =>
        ((leftHeel ?? leftAnkle).dx - hipCenter.dx).abs() >=
            ((rightHeel ?? rightAnkle).dx - hipCenter.dx).abs(),
    };
    return useLeft
        ? _jointAngle(leftHip, leftKnee, leftAnkle)
        : _jointAngle(rightHip, rightKnee, rightAnkle);
  }
}

Offset _midpoint(Offset first, Offset second) {
  return Offset((first.dx + second.dx) / 2, (first.dy + second.dy) / 2);
}

double _distance(Offset first, Offset second) {
  final dx = first.dx - second.dx;
  final dy = first.dy - second.dy;
  return math.sqrt((dx * dx) + (dy * dy));
}

double _minimumLikelihood(Iterable<RunningPoseLandmark> landmarks) {
  var minimum = 1.0;
  var hasLandmark = false;
  for (final landmark in landmarks) {
    hasLandmark = true;
    minimum = math.min(minimum, landmark.likelihood);
  }
  return hasLandmark ? minimum.clamp(0.0, 1.0).toDouble() : 0.0;
}

double? _armLandmarkConfidence({
  required RunningPoseLandmark leftShoulder,
  required RunningPoseLandmark rightShoulder,
  required RunningPoseLandmark? leftElbow,
  required RunningPoseLandmark? rightElbow,
  required RunningPoseLandmark? leftWrist,
  required RunningPoseLandmark? rightWrist,
}) {
  final armConfidences = <double>[
    if (leftElbow != null && leftWrist != null)
      _minimumLikelihood([leftShoulder, leftElbow, leftWrist]),
    if (rightElbow != null && rightWrist != null)
      _minimumLikelihood([rightShoulder, rightElbow, rightWrist]),
  ];
  if (armConfidences.isEmpty) {
    return null;
  }
  return _average(armConfidences);
}

double _average(List<double> values) {
  if (values.isEmpty) {
    return 0;
  }
  return values.reduce((sum, value) => sum + value) / values.length;
}

double _jointAngle(Offset first, Offset vertex, Offset third) {
  final firstVector = first - vertex;
  final secondVector = third - vertex;
  final firstLength = firstVector.distance;
  final secondLength = secondVector.distance;
  if (firstLength <= 0 || secondLength <= 0) {
    return 180;
  }
  final cosine = ((firstVector.dx * secondVector.dx) +
          (firstVector.dy * secondVector.dy)) /
      (firstLength * secondLength);
  return math.acos(cosine.clamp(-1.0, 1.0)) * 180 / math.pi;
}

double _roundTo3(double value) {
  return (value * 1000).truncateToDouble() / 1000;
}
