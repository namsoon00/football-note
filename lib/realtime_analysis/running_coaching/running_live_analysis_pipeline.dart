import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import '../../domain/entities/running_live_coaching_state.dart';
import '../../domain/entities/running_video_analysis_result.dart';

class RunningLiveAnalysisPipeline {
  final RunningLiveAnalysisConfig config;
  final Queue<_TimedFrameSample> _samples = Queue<_TimedFrameSample>();

  RunningLiveAnalysisPipeline({
    this.config = const RunningLiveAnalysisConfig(),
  });

  void reset() => _samples.clear();

  RunningLiveAnalysisSnapshot ingestObservation(
    RunningPoseObservation? observation, {
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    _trimSamples(now);

    RunningLiveFramingIssue? framingIssue;
    if (observation == null) {
      framingIssue = RunningLiveFramingIssue.noRunnerDetected;
    } else {
      final extractor = _RunningFrameExtractor(config.minimumLikelihood);
      final sample = extractor.extract(observation);
      framingIssue = _RunningFramingPolicy(
        config.minimumLikelihood,
        extractor,
      ).resolve(observation, sample: sample);
      if (framingIssue == null && sample != null) {
        _samples.add(_TimedFrameSample(sample: sample, timestamp: now));
        _trimSamples(now);
      } else {
        framingIssue ??= RunningLiveFramingIssue.noRunnerDetected;
      }
    }

    return RunningLiveAnalysisSnapshot(
      framingIssue: framingIssue,
      analysisResult: _RunningMetricAggregator(
        minimumTrackedFrames: config.minimumTrackedFrames,
      ).build(_samples.toList(growable: false)),
      trackedFrames: _samples.length,
    );
  }

  void _trimSamples(DateTime now) {
    while (_samples.isNotEmpty &&
        now.difference(_samples.first.timestamp) > config.analysisWindow) {
      _samples.removeFirst();
    }
  }
}

class RunningLiveAnalysisConfig {
  final Duration analysisWindow;
  final int minimumTrackedFrames;
  final double minimumLikelihood;
  final Duration cueDwellTime;

  const RunningLiveAnalysisConfig({
    this.analysisWindow = const Duration(milliseconds: 2400),
    this.minimumTrackedFrames = 7,
    this.minimumLikelihood = 0.45,
    this.cueDwellTime = const Duration(milliseconds: 600),
  });
}

class RunningLiveAnalysisSnapshot {
  final RunningLiveFramingIssue? framingIssue;
  final RunningVideoAnalysisResult? analysisResult;
  final int trackedFrames;

  const RunningLiveAnalysisSnapshot({
    required this.framingIssue,
    required this.analysisResult,
    required this.trackedFrames,
  });
}

class _RunningFramingPolicy {
  final double minimumLikelihood;
  final _RunningFrameExtractor extractor;

  const _RunningFramingPolicy(this.minimumLikelihood, this.extractor);

  RunningLiveFramingIssue? resolve(
    RunningPoseObservation observation, {
    required _FrameSample? sample,
  }) {
    final imageSize = observation.imageSize;
    if (imageSize.width <= 0 || imageSize.height <= 0) {
      return RunningLiveFramingIssue.noRunnerDetected;
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
      return RunningLiveFramingIssue.noRunnerDetected;
    }

    final leftAnkle = observation.landmark(
      RunningPoseLandmarkType.leftAnkle,
      minimumLikelihood: minimumLikelihood,
    );
    final rightAnkle = observation.landmark(
      RunningPoseLandmarkType.rightAnkle,
      minimumLikelihood: minimumLikelihood,
    );
    if (leftAnkle == null || rightAnkle == null) {
      return RunningLiveFramingIssue.stepBack;
    }

    final visibleLandmarks = <RunningPoseLandmark>[
      for (final type in RunningPoseLandmarkType.values)
        if (observation.landmark(type, minimumLikelihood: minimumLikelihood)
            case final landmark?)
          landmark,
    ];
    if (visibleLandmarks.length < 6) {
      return RunningLiveFramingIssue.noRunnerDetected;
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

    if (boxHeightRatio > 0.9 ||
        boxWidthRatio > 0.82 ||
        topMarginRatio < 0.03 ||
        bottomMarginRatio < 0.03) {
      return RunningLiveFramingIssue.stepBack;
    }

    if (boxHeightRatio < 0.36) {
      return RunningLiveFramingIssue.moveCloser;
    }

    if (centerXRatio < 0.28 || centerXRatio > 0.72) {
      return RunningLiveFramingIssue.centerRunner;
    }

    final extractedSample = sample ?? extractor.extract(observation);
    if (extractedSample == null) {
      return RunningLiveFramingIssue.noRunnerDetected;
    }

    final bodyHeight = maxY - minY;
    final shoulderWidthRatio =
        extractedSample.shoulderSpan / math.max(bodyHeight, 1);
    final hipWidthRatio = extractedSample.hipSpan / math.max(bodyHeight, 1);
    if (math.max(shoulderWidthRatio, hipWidthRatio) > 0.34) {
      return RunningLiveFramingIssue.turnSideways;
    }

    return null;
  }
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
      leftHeel: observation
          .landmark(
            RunningPoseLandmarkType.leftHeel,
            minimumLikelihood: minimumLikelihood,
          )
          ?.position,
      rightHeel: observation
          .landmark(
            RunningPoseLandmarkType.rightHeel,
            minimumLikelihood: minimumLikelihood,
          )
          ?.position,
      leftElbow: observation
          .landmark(
            RunningPoseLandmarkType.leftElbow,
            minimumLikelihood: minimumLikelihood,
          )
          ?.position,
      rightElbow: observation
          .landmark(
            RunningPoseLandmarkType.rightElbow,
            minimumLikelihood: minimumLikelihood,
          )
          ?.position,
      leftWrist: observation
          .landmark(
            RunningPoseLandmarkType.leftWrist,
            minimumLikelihood: minimumLikelihood,
          )
          ?.position,
      rightWrist: observation
          .landmark(
            RunningPoseLandmarkType.rightWrist,
            minimumLikelihood: minimumLikelihood,
          )
          ?.position,
      bodyScale: bodyScale,
      shoulderSpan: _distance(
        leftShoulder.position,
        rightShoulder.position,
      ),
      hipSpan: _distance(leftHip.position, rightHip.position),
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
    final elbowAngles = <double>[
      for (final sample in samples)
        if (sample.averageElbowAngleDegrees case final angle?) angle,
    ];
    if (kneeAngles.isEmpty || elbowAngles.isEmpty) {
      return null;
    }
    final stanceKneeAngle =
        kneeAngles.reduce((sum, value) => sum + value) / kneeAngles.length;
    final elbowAngle =
        elbowAngles.reduce((sum, value) => sum + value) / elbowAngles.length;
    final sharedQuality = RunningMetricQuality(
      confidence: (samples.length / 10).clamp(0.0, 1.0),
      sampleCount: samples.length,
      reason: samples.length < 7 ? 'limited_samples' : null,
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
        RunningCoachMetric.armCarriage: sharedQuality,
      },
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
    final reachSpread = (maxRatio - minRatio).abs();
    final sampleFactor = (stanceSamples.length / 3).clamp(0.0, 1.0);
    final spreadFactor = (reachSpread / 0.08).clamp(0.0, 1.0);
    final contactConfidence =
        ((sampleFactor * 0.65) + (spreadFactor * 0.20) + 0.15).clamp(0.0, 1.0);
    final confidence = math.min(fallback.confidence, contactConfidence);
    return RunningMetricQuality(
      confidence: confidence,
      sampleCount: stanceSamples.length,
      reason: confidence < 0.65 ? 'contact_phase_proxy' : fallback.reason,
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
