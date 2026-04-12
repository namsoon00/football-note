import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import '../domain/entities/running_live_coaching_state.dart';
import '../domain/entities/running_video_analysis_result.dart';
import 'running_coaching_service.dart';

class RunningLiveCoachingService {
  final RunningCoachingService _coachingService;
  final Duration _analysisWindow;
  final int _minimumTrackedFrames;
  final double _minimumLikelihood;

  final Queue<_TimedFrameSample> _samples = Queue<_TimedFrameSample>();

  RunningLiveCoachingService({
    RunningCoachingService coachingService = const RunningCoachingService(),
    Duration analysisWindow = const Duration(seconds: 2),
    int minimumTrackedFrames = 6,
    double minimumLikelihood = 0.45,
  })  : _coachingService = coachingService,
        _analysisWindow = analysisWindow,
        _minimumTrackedFrames = minimumTrackedFrames,
        _minimumLikelihood = minimumLikelihood;

  void reset() => _samples.clear();

  RunningLiveCoachingState ingestObservation(
    RunningPoseObservation? observation, {
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    _trimSamples(now);

    RunningLiveFramingIssue? framingIssue;
    if (observation == null) {
      framingIssue = RunningLiveFramingIssue.noRunnerDetected;
    } else {
      framingIssue = _resolveFramingIssue(observation);
      if (framingIssue == null) {
        final sample = _extractFrameSample(observation);
        if (sample != null) {
          _samples.add(_TimedFrameSample(sample: sample, timestamp: now));
          _trimSamples(now);
        } else {
          framingIssue = RunningLiveFramingIssue.noRunnerDetected;
        }
      }
    }

    final analysisResult = _buildAnalysisResult();
    final coachingReport = analysisResult == null
        ? null
        : _coachingService.buildReport(analysisResult);
    final highlightedInsight =
        coachingReport == null ? null : _pickHighlightedInsight(coachingReport);

    return RunningLiveCoachingState(
      framingIssue: framingIssue,
      primaryCue: _resolvePrimaryCue(
        framingIssue: framingIssue,
        coachingReport: coachingReport,
        highlightedInsight: highlightedInsight,
      ),
      analysisResult: analysisResult,
      coachingReport: coachingReport,
      highlightedInsight: highlightedInsight,
      trackedFrames: _samples.length,
    );
  }

  void _trimSamples(DateTime now) {
    while (_samples.isNotEmpty &&
        now.difference(_samples.first.timestamp) > _analysisWindow) {
      _samples.removeFirst();
    }
  }

  RunningLiveFramingIssue? _resolveFramingIssue(
      RunningPoseObservation observation) {
    final imageSize = observation.imageSize;
    if (imageSize.width <= 0 || imageSize.height <= 0) {
      return RunningLiveFramingIssue.noRunnerDetected;
    }

    final leftShoulder = observation.landmark(
      RunningPoseLandmarkType.leftShoulder,
      minimumLikelihood: _minimumLikelihood,
    );
    final rightShoulder = observation.landmark(
      RunningPoseLandmarkType.rightShoulder,
      minimumLikelihood: _minimumLikelihood,
    );
    final leftHip = observation.landmark(
      RunningPoseLandmarkType.leftHip,
      minimumLikelihood: _minimumLikelihood,
    );
    final rightHip = observation.landmark(
      RunningPoseLandmarkType.rightHip,
      minimumLikelihood: _minimumLikelihood,
    );

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null) {
      return RunningLiveFramingIssue.noRunnerDetected;
    }

    final leftAnkle = observation.landmark(
      RunningPoseLandmarkType.leftAnkle,
      minimumLikelihood: _minimumLikelihood,
    );
    final rightAnkle = observation.landmark(
      RunningPoseLandmarkType.rightAnkle,
      minimumLikelihood: _minimumLikelihood,
    );
    if (leftAnkle == null || rightAnkle == null) {
      return RunningLiveFramingIssue.stepBack;
    }

    final visibleLandmarks = <RunningPoseLandmark>[
      for (final type in RunningPoseLandmarkType.values)
        if (observation.landmark(type, minimumLikelihood: _minimumLikelihood)
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

    final sample = _extractFrameSample(observation);
    if (sample == null) {
      return RunningLiveFramingIssue.noRunnerDetected;
    }

    final bodyHeight = maxY - minY;
    final shoulderWidthRatio = sample.shoulderSpan / math.max(bodyHeight, 1);
    final hipWidthRatio = sample.hipSpan / math.max(bodyHeight, 1);
    if (math.max(shoulderWidthRatio, hipWidthRatio) > 0.34) {
      return RunningLiveFramingIssue.turnSideways;
    }

    return null;
  }

  _FrameSample? _extractFrameSample(RunningPoseObservation observation) {
    final leftShoulder = observation.landmark(
      RunningPoseLandmarkType.leftShoulder,
      minimumLikelihood: _minimumLikelihood,
    );
    final rightShoulder = observation.landmark(
      RunningPoseLandmarkType.rightShoulder,
      minimumLikelihood: _minimumLikelihood,
    );
    final leftHip = observation.landmark(
      RunningPoseLandmarkType.leftHip,
      minimumLikelihood: _minimumLikelihood,
    );
    final rightHip = observation.landmark(
      RunningPoseLandmarkType.rightHip,
      minimumLikelihood: _minimumLikelihood,
    );
    final leftAnkle = observation.landmark(
      RunningPoseLandmarkType.leftAnkle,
      minimumLikelihood: _minimumLikelihood,
    );
    final rightAnkle = observation.landmark(
      RunningPoseLandmarkType.rightAnkle,
      minimumLikelihood: _minimumLikelihood,
    );
    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null ||
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
      shoulderCenter: shoulderCenter,
      hipCenter: hipCenter,
      leftAnkle: leftAnkle.position,
      rightAnkle: rightAnkle.position,
      bodyScale: bodyScale,
      shoulderSpan: _distance(
        leftShoulder.position,
        rightShoulder.position,
      ),
      hipSpan: _distance(leftHip.position, rightHip.position),
    );
  }

  RunningVideoAnalysisResult? _buildAnalysisResult() {
    if (_samples.length < _minimumTrackedFrames) {
      return null;
    }

    final samples =
        _samples.map((entry) => entry.sample).toList(growable: false);
    final duration =
        _samples.last.timestamp.difference(_samples.first.timestamp);
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
    final strideRatio = _topAverage(
      samples
          .map((sample) => sample.strideReachRatio(direction))
          .toList(growable: false),
    ).clamp(0.0, double.infinity);

    return RunningVideoAnalysisResult(
      videoDuration: duration < const Duration(milliseconds: 400)
          ? const Duration(milliseconds: 400)
          : duration,
      sampledFrames: samples.length,
      validFrames: samples.length,
      direction: direction,
      forwardLeanDegrees: _roundTo3(leanDegrees),
      verticalBounceRatio: _roundTo3(bounceRatio),
      strideReachRatio: _roundTo3(strideRatio),
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

  RunningCoachingInsight _pickHighlightedInsight(RunningCoachingReport report) {
    var highlighted = report.insights.first;
    for (final insight in report.insights.skip(1)) {
      if (insight.score < highlighted.score) {
        highlighted = insight;
      }
    }
    return highlighted;
  }

  RunningLivePrimaryCue _resolvePrimaryCue({
    required RunningLiveFramingIssue? framingIssue,
    required RunningCoachingReport? coachingReport,
    required RunningCoachingInsight? highlightedInsight,
  }) {
    if (framingIssue != null) {
      return switch (framingIssue) {
        RunningLiveFramingIssue.noRunnerDetected =>
          RunningLivePrimaryCue.noRunnerDetected,
        RunningLiveFramingIssue.stepBack => RunningLivePrimaryCue.stepBack,
        RunningLiveFramingIssue.moveCloser => RunningLivePrimaryCue.moveCloser,
        RunningLiveFramingIssue.centerRunner =>
          RunningLivePrimaryCue.centerRunner,
        RunningLiveFramingIssue.turnSideways =>
          RunningLivePrimaryCue.turnSideways,
      };
    }

    if (coachingReport == null || highlightedInsight == null) {
      return RunningLivePrimaryCue.keepRunning;
    }

    if (coachingReport.overallScore >= 88 &&
        highlightedInsight.status == RunningCoachStatus.good) {
      return RunningLivePrimaryCue.lookingGood;
    }

    return switch (highlightedInsight.finding) {
      RunningCoachFinding.postureTooUpright =>
        RunningLivePrimaryCue.postureTooUpright,
      RunningCoachFinding.postureTooLean =>
        RunningLivePrimaryCue.postureTooLean,
      RunningCoachFinding.bounceTooHigh => RunningLivePrimaryCue.bounceTooHigh,
      RunningCoachFinding.strideTooShort =>
        RunningLivePrimaryCue.strideTooShort,
      RunningCoachFinding.strideOverstride =>
        RunningLivePrimaryCue.strideOverstride,
      _ => RunningLivePrimaryCue.lookingGood,
    };
  }

  Offset _midpoint(Offset first, Offset second) {
    return Offset((first.dx + second.dx) / 2, (first.dy + second.dy) / 2);
  }

  double _distance(Offset first, Offset second) {
    final dx = first.dx - second.dx;
    final dy = first.dy - second.dy;
    return math.sqrt((dx * dx) + (dy * dy));
  }

  double _topAverage(List<double> values) {
    if (values.isEmpty) {
      return 0;
    }
    final clipped = values.map((value) => math.max(0, value)).toList()..sort();
    final windowSize = math.max(1, clipped.length ~/ 3);
    final slice = clipped.sublist(clipped.length - windowSize);
    return slice.reduce((sum, value) => sum + value) / slice.length;
  }

  double _roundTo3(double value) {
    return (value * 1000).truncateToDouble() / 1000;
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
  final Offset shoulderCenter;
  final Offset hipCenter;
  final Offset leftAnkle;
  final Offset rightAnkle;
  final double bodyScale;
  final double shoulderSpan;
  final double hipSpan;

  const _FrameSample({
    required this.shoulderCenter,
    required this.hipCenter,
    required this.leftAnkle,
    required this.rightAnkle,
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

  double strideReachRatio(RunningDirection direction) {
    final forwardReach = switch (direction) {
      RunningDirection.leftToRight =>
        math.max(leftAnkle.dx, rightAnkle.dx) - hipCenter.dx,
      RunningDirection.rightToLeft =>
        hipCenter.dx - math.min(leftAnkle.dx, rightAnkle.dx),
      RunningDirection.stationary => math.max(
          (leftAnkle.dx - hipCenter.dx).abs(),
          (rightAnkle.dx - hipCenter.dx).abs(),
        ),
    };
    return math.max(0, forwardReach) / math.max(bodyScale, 1.0);
  }
}
