import 'dart:math' as math;

import '../../domain/entities/sprint_pose_frame.dart';
import '../../domain/entities/sprint_realtime_coaching_state.dart';
import 'sprint_pose_normalizer.dart';

class SprintFeatureCalculator {
  SprintFeatureSnapshot calculate(
    List<SprintNormalizedPoseFrame> frames, {
    Duration minimumStepEventInterval = const Duration(milliseconds: 110),
    double stepDetectionHysteresis = 0.08,
    double minimumStepDetectionVelocity = 0.9,
  }) {
    if (frames.isEmpty) {
      return const SprintFeatureSnapshot.empty();
    }

    final trunkAngles = <double>[
      for (final frame in frames)
        if (_trunkAngleDegrees(frame) case final angle?) angle,
    ];
    final kneeDriveHeights = <double>[
      for (final frame in frames)
        if (_kneeDriveHeightRatio(frame) case final height?) height,
    ];
    final armExcursions = _armExcursions(frames);
    final stepEvents = _detectStepEvents(
      frames,
      minimumStepEventInterval: minimumStepEventInterval,
      stepDetectionHysteresis: stepDetectionHysteresis,
      minimumStepDetectionVelocity: minimumStepDetectionVelocity,
    );
    final stepIntervalsMs = <double>[
      for (var index = 1; index < stepEvents.length; index += 1)
        stepEvents[index]
            .difference(stepEvents[index - 1])
            .inMilliseconds
            .toDouble(),
    ];

    final averageStepIntervalMs = stepIntervalsMs.isEmpty
        ? null
        : _average(stepIntervalsMs);
    final cadence = averageStepIntervalMs == null || averageStepIntervalMs <= 0
        ? null
        : 60000 / averageStepIntervalMs;

    return SprintFeatureSnapshot(
      trunkAngleDegrees: trunkAngles.isEmpty ? null : _average(trunkAngles),
      kneeDriveHeightRatio: kneeDriveHeights.isEmpty
          ? null
          : _averageTopWindow(kneeDriveHeights),
      stepInterval: averageStepIntervalMs == null
          ? null
          : Duration(milliseconds: averageStepIntervalMs.round()),
      cadenceStepsPerMinute: cadence,
      stepIntervalStdMs: stepIntervalsMs.isEmpty
          ? null
          : _standardDeviation(stepIntervalsMs),
      armSwingAsymmetryRatio: armExcursions == null
          ? null
          : _asymmetryRatio(
              armExcursions.leftAverage,
              armExcursions.rightAverage,
            ),
      detectedStepEvents: stepEvents.length,
    );
  }

  double? _trunkAngleDegrees(SprintNormalizedPoseFrame frame) {
    final shoulderCenter = frame.midpointOf(
      SprintPoseLandmarkType.leftShoulder,
      SprintPoseLandmarkType.rightShoulder,
    );
    if (shoulderCenter == null) {
      return null;
    }

    final verticalMagnitude = shoulderCenter.dy.abs();
    if (verticalMagnitude <= 0) {
      return null;
    }

    final horizontalMagnitude = shoulderCenter.dx.abs();
    return math.atan2(horizontalMagnitude, verticalMagnitude) * 180 / math.pi;
  }

  double? _kneeDriveHeightRatio(SprintNormalizedPoseFrame frame) {
    final leftKnee = frame.landmark(SprintPoseLandmarkType.leftKnee);
    final rightKnee = frame.landmark(SprintPoseLandmarkType.rightKnee);
    if (leftKnee == null || rightKnee == null) {
      return null;
    }

    return math.max(-leftKnee.dy, -rightKnee.dy);
  }

  _ArmExcursions? _armExcursions(List<SprintNormalizedPoseFrame> frames) {
    final left = <double>[];
    final right = <double>[];

    for (final frame in frames) {
      final leftShoulder = frame.landmark(SprintPoseLandmarkType.leftShoulder);
      final rightShoulder = frame.landmark(
        SprintPoseLandmarkType.rightShoulder,
      );
      final leftWrist = frame.landmark(SprintPoseLandmarkType.leftWrist);
      final rightWrist = frame.landmark(SprintPoseLandmarkType.rightWrist);
      if (leftShoulder == null ||
          rightShoulder == null ||
          leftWrist == null ||
          rightWrist == null) {
        continue;
      }

      left.add((leftWrist.dx - leftShoulder.dx).abs());
      right.add((rightWrist.dx - rightShoulder.dx).abs());
    }

    if (left.isEmpty || right.isEmpty) {
      return null;
    }

    return _ArmExcursions(
      leftAverage: _average(left),
      rightAverage: _average(right),
    );
  }

  List<DateTime> _detectStepEvents(
    List<SprintNormalizedPoseFrame> frames, {
    required Duration minimumStepEventInterval,
    required double stepDetectionHysteresis,
    required double minimumStepDetectionVelocity,
  }) {
    final events = <DateTime>[];
    double? previousDelta;
    DateTime? previousTimestamp;
    _LeadFootState? previousLeadFoot;
    DateTime? lastAcceptedEventAt;

    for (final frame in frames) {
      final leftAnkle = frame.landmark(SprintPoseLandmarkType.leftAnkle);
      final rightAnkle = frame.landmark(SprintPoseLandmarkType.rightAnkle);
      if (leftAnkle == null || rightAnkle == null) {
        continue;
      }

      final delta = leftAnkle.dx - rightAnkle.dx;
      final leadFoot = _leadFootState(
        delta: delta,
        hysteresis: stepDetectionHysteresis,
      );
      if (previousDelta != null &&
          previousTimestamp != null &&
          leadFoot != null &&
          previousLeadFoot != null &&
          previousLeadFoot != leadFoot) {
        final deltaTimeSeconds =
            frame.timestamp.difference(previousTimestamp).inMicroseconds /
            Duration.microsecondsPerSecond;
        final velocity = deltaTimeSeconds <= 0
            ? 0
            : (delta - previousDelta).abs() / deltaTimeSeconds;
        final meetsInterval =
            lastAcceptedEventAt == null ||
            frame.timestamp.difference(lastAcceptedEventAt) >=
                minimumStepEventInterval;
        if (meetsInterval && velocity >= minimumStepDetectionVelocity) {
          events.add(frame.timestamp);
          lastAcceptedEventAt = frame.timestamp;
        }
      }

      previousDelta = delta;
      previousTimestamp = frame.timestamp;
      if (leadFoot != null) {
        previousLeadFoot = leadFoot;
      }
    }

    return events;
  }

  _LeadFootState? _leadFootState({
    required double delta,
    required double hysteresis,
  }) {
    if (delta >= hysteresis) {
      return _LeadFootState.leftLead;
    }
    if (delta <= -hysteresis) {
      return _LeadFootState.rightLead;
    }
    return null;
  }

  double _average(List<double> values) {
    final total = values.reduce((sum, value) => sum + value);
    return total / values.length;
  }

  double _averageTopWindow(List<double> values) {
    final sorted = values.toList()..sort();
    final windowSize = math.max(1, sorted.length ~/ 3);
    final topWindow = sorted.sublist(sorted.length - windowSize);
    return _average(topWindow);
  }

  double _asymmetryRatio(double left, double right) {
    final baseline = math.max(math.max(left, right), 0.001);
    return (left - right).abs() / baseline;
  }

  double _standardDeviation(List<double> values) {
    if (values.length <= 1) {
      return 0;
    }
    final mean = _average(values);
    final variance =
        values
            .map((value) => math.pow(value - mean, 2).toDouble())
            .reduce((sum, value) => sum + value) /
        values.length;
    return math.sqrt(variance);
  }
}

class _ArmExcursions {
  final double leftAverage;
  final double rightAverage;

  const _ArmExcursions({required this.leftAverage, required this.rightAverage});
}

enum _LeadFootState { leftLead, rightLead }
