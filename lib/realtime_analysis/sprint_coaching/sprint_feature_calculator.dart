import 'dart:math' as math;
import 'dart:ui';

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

    final trunkSamples = <_WeightedSample>[
      for (final frame in frames)
        if (_trunkAngleDegrees(frame) case final sample?) sample,
    ];
    final kneeDriveSamples = <_WeightedSample>[
      for (final frame in frames)
        if (_kneeDriveHeightRatio(frame) case final sample?) sample,
    ];
    final armExcursions = _armExcursions(frames);
    final stepDetection = _detectStepEvents(
      frames,
      minimumStepEventInterval: minimumStepEventInterval,
      stepDetectionHysteresis: stepDetectionHysteresis,
      minimumStepDetectionVelocity: minimumStepDetectionVelocity,
    );
    final stepEvents = stepDetection.acceptedEvents;
    final stepIntervalsMs = <double>[
      for (var index = 1; index < stepEvents.length; index += 1)
        stepEvents[index]
            .difference(stepEvents[index - 1])
            .inMilliseconds
            .toDouble(),
    ];

    final averageStepIntervalMs =
        stepIntervalsMs.isEmpty ? null : _average(stepIntervalsMs);
    final cadence = averageStepIntervalMs == null || averageStepIntervalMs <= 0
        ? null
        : 60000 / averageStepIntervalMs;
    final rhythmStd =
        stepIntervalsMs.isEmpty ? null : _standardDeviation(stepIntervalsMs);
    final cadenceConfidence = _stepMetricConfidence(stepDetection, stepEvents);

    return SprintFeatureSnapshot(
      trunkAngle: _measurementFromSamples(
        trunkSamples,
        reasonIfUnavailable: 'insufficient_joint_window',
        summary: _trimmedAverage,
      ),
      kneeDrive: _measurementFromSamples(
        kneeDriveSamples,
        reasonIfUnavailable: 'insufficient_joint_window',
        summary: _upperWindowAverage,
      ),
      cadence: cadence == null
          ? const SprintMeasuredValue.unavailable(
              reasonIfUnavailable: 'insufficient_step_events',
            )
          : SprintMeasuredValue.available(
              value: cadence,
              confidence: cadenceConfidence,
              sampleCount: stepEvents.length,
            ),
      rhythm: rhythmStd == null
          ? const SprintMeasuredValue.unavailable(
              reasonIfUnavailable: 'insufficient_step_events',
            )
          : SprintMeasuredValue.available(
              value: rhythmStd,
              confidence: cadenceConfidence,
              sampleCount: stepIntervalsMs.length,
            ),
      armBalance: armExcursions == null
          ? const SprintMeasuredValue.unavailable(
              reasonIfUnavailable: 'insufficient_joint_window',
            )
          : SprintMeasuredValue.available(
              value: _asymmetryRatio(
                armExcursions.leftAverage,
                armExcursions.rightAverage,
              ),
              confidence: armExcursions.confidence,
              sampleCount: armExcursions.sampleCount,
            ),
      stepInterval: averageStepIntervalMs == null
          ? null
          : Duration(milliseconds: averageStepIntervalMs.round()),
      detectedStepEvents: stepEvents.length,
      stepCrossoverCount: stepDetection.leadSwitchCount,
      rejectedStepEventsLowVelocity: stepDetection.rejectedForLowVelocityCount,
      rejectedStepEventsMinInterval:
          stepDetection.rejectedForMinimumIntervalCount,
    );
  }

  _WeightedSample? _trunkAngleDegrees(SprintNormalizedPoseFrame frame) {
    final leftShoulder = frame.landmark(SprintPoseLandmarkType.leftShoulder);
    final rightShoulder = frame.landmark(SprintPoseLandmarkType.rightShoulder);
    final leftHip = frame.landmark(SprintPoseLandmarkType.leftHip);
    final rightHip = frame.landmark(SprintPoseLandmarkType.rightHip);
    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null) {
      return null;
    }

    final shoulderCenter = Offset(
      (leftShoulder.dx + rightShoulder.dx) / 2,
      (leftShoulder.dy + rightShoulder.dy) / 2,
    );
    final hipCenter = Offset(
      (leftHip.dx + rightHip.dx) / 2,
      (leftHip.dy + rightHip.dy) / 2,
    );
    final axis = shoulderCenter - hipCenter;
    final verticalMagnitude = axis.dy.abs();
    if (verticalMagnitude <= 0) {
      return null;
    }

    final horizontalMagnitude = axis.dx.abs();
    final confidence = _average(<double>[
      frame.landmarkConfidence(SprintPoseLandmarkType.leftShoulder) ?? 0,
      frame.landmarkConfidence(SprintPoseLandmarkType.rightShoulder) ?? 0,
      frame.landmarkConfidence(SprintPoseLandmarkType.leftHip) ?? 0,
      frame.landmarkConfidence(SprintPoseLandmarkType.rightHip) ?? 0,
    ]);
    return _WeightedSample(
      value: math.atan2(horizontalMagnitude, verticalMagnitude) * 180 / math.pi,
      confidence: confidence,
    );
  }

  _WeightedSample? _kneeDriveHeightRatio(SprintNormalizedPoseFrame frame) {
    final leftKnee = frame.landmark(SprintPoseLandmarkType.leftKnee);
    final rightKnee = frame.landmark(SprintPoseLandmarkType.rightKnee);
    final leftHip = frame.landmark(SprintPoseLandmarkType.leftHip);
    final rightHip = frame.landmark(SprintPoseLandmarkType.rightHip);
    if (leftKnee == null ||
        rightKnee == null ||
        leftHip == null ||
        rightHip == null) {
      return null;
    }

    final leftDrive = (leftHip.dy - leftKnee.dy).clamp(0.0, double.infinity);
    final rightDrive = (rightHip.dy - rightKnee.dy).clamp(0.0, double.infinity);
    final confidence = _average(<double>[
      frame.landmarkConfidence(SprintPoseLandmarkType.leftHip) ?? 0,
      frame.landmarkConfidence(SprintPoseLandmarkType.rightHip) ?? 0,
      frame.landmarkConfidence(SprintPoseLandmarkType.leftKnee) ?? 0,
      frame.landmarkConfidence(SprintPoseLandmarkType.rightKnee) ?? 0,
    ]);
    return _WeightedSample(
      value: math.max(leftDrive, rightDrive),
      confidence: confidence,
    );
  }

  _ArmExcursions? _armExcursions(List<SprintNormalizedPoseFrame> frames) {
    final left = <double>[];
    final right = <double>[];
    final confidences = <double>[];

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
      confidences.add(
        _average(<double>[
          frame.landmarkConfidence(SprintPoseLandmarkType.leftShoulder) ?? 0,
          frame.landmarkConfidence(SprintPoseLandmarkType.rightShoulder) ?? 0,
          frame.landmarkConfidence(SprintPoseLandmarkType.leftWrist) ?? 0,
          frame.landmarkConfidence(SprintPoseLandmarkType.rightWrist) ?? 0,
        ]),
      );
    }

    if (left.isEmpty || right.isEmpty) {
      return null;
    }

    return _ArmExcursions(
      leftAverage: _trimmedAverage(left),
      rightAverage: _trimmedAverage(right),
      confidence: _average(confidences),
      sampleCount: math.min(left.length, right.length),
    );
  }

  _StepDetectionSummary _detectStepEvents(
    List<SprintNormalizedPoseFrame> frames, {
    required Duration minimumStepEventInterval,
    required double stepDetectionHysteresis,
    required double minimumStepDetectionVelocity,
  }) {
    final acceptedEvents = <DateTime>[];
    double? previousDelta;
    DateTime? previousTimestamp;
    _LeadFootState? previousLeadFoot;
    DateTime? lastAcceptedEventAt;
    var leadSwitchCount = 0;
    var rejectedForLowVelocityCount = 0;
    var rejectedForMinimumIntervalCount = 0;

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
        leadSwitchCount += 1;
        final deltaTimeSeconds =
            frame.timestamp.difference(previousTimestamp).inMicroseconds /
                Duration.microsecondsPerSecond;
        final velocity = deltaTimeSeconds <= 0
            ? 0
            : (delta - previousDelta).abs() / deltaTimeSeconds;
        final meetsInterval = lastAcceptedEventAt == null ||
            frame.timestamp.difference(lastAcceptedEventAt) >=
                minimumStepEventInterval;
        if (!meetsInterval) {
          rejectedForMinimumIntervalCount += 1;
        } else if (velocity < minimumStepDetectionVelocity) {
          rejectedForLowVelocityCount += 1;
        } else {
          acceptedEvents.add(frame.timestamp);
          lastAcceptedEventAt = frame.timestamp;
        }
      }

      previousDelta = delta;
      previousTimestamp = frame.timestamp;
      if (leadFoot != null) {
        previousLeadFoot = leadFoot;
      }
    }

    return _StepDetectionSummary(
      acceptedEvents: acceptedEvents,
      leadSwitchCount: leadSwitchCount,
      rejectedForLowVelocityCount: rejectedForLowVelocityCount,
      rejectedForMinimumIntervalCount: rejectedForMinimumIntervalCount,
    );
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

  SprintMeasuredValue _measurementFromSamples(
    List<_WeightedSample> samples, {
    required String reasonIfUnavailable,
    required double Function(List<double> values) summary,
  }) {
    if (samples.length < 3) {
      return SprintMeasuredValue.unavailable(
        reasonIfUnavailable: reasonIfUnavailable,
        sampleCount: samples.length,
      );
    }

    final values =
        samples.map((sample) => sample.value).toList(growable: false);
    final confidences = samples
        .map((sample) => sample.confidence.clamp(0.0, 1.0))
        .toList(growable: false);
    final value = summary(values);
    final confidence =
        (_average(confidences) * math.min(1.0, samples.length / 6.0))
            .clamp(0.0, 1.0);
    return SprintMeasuredValue.available(
      value: value,
      confidence: confidence,
      sampleCount: samples.length,
    );
  }

  double _stepMetricConfidence(
    _StepDetectionSummary summary,
    List<DateTime> stepEvents,
  ) {
    if (stepEvents.length < 2) {
      return 0;
    }

    final totalAttempts = math.max(1, summary.leadSwitchCount);
    final rejectionPenalty = (summary.rejectedForLowVelocityCount +
            summary.rejectedForMinimumIntervalCount) /
        totalAttempts;
    final confidence = math.min(1.0, stepEvents.length / 4.0) *
        (1.0 - rejectionPenalty).clamp(0.2, 1.0);
    return confidence.clamp(0.0, 1.0);
  }

  double _average(List<double> values) {
    final total = values.reduce((sum, value) => sum + value);
    return total / values.length;
  }

  double _trimmedAverage(List<double> values) {
    if (values.length <= 2) {
      return _average(values);
    }
    final sorted = values.toList()..sort();
    final start = values.length >= 5 ? 1 : 0;
    final end = values.length >= 5 ? sorted.length - 1 : sorted.length;
    return _average(sorted.sublist(start, end));
  }

  double _upperWindowAverage(List<double> values) {
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
    final variance = values
            .map((value) => math.pow(value - mean, 2).toDouble())
            .reduce((sum, value) => sum + value) /
        values.length;
    return math.sqrt(variance);
  }
}

class _WeightedSample {
  final double value;
  final double confidence;

  const _WeightedSample({required this.value, required this.confidence});
}

class _ArmExcursions {
  final double leftAverage;
  final double rightAverage;
  final double confidence;
  final int sampleCount;

  const _ArmExcursions({
    required this.leftAverage,
    required this.rightAverage,
    required this.confidence,
    required this.sampleCount,
  });
}

enum _LeadFootState { leftLead, rightLead }

class _StepDetectionSummary {
  final List<DateTime> acceptedEvents;
  final int leadSwitchCount;
  final int rejectedForLowVelocityCount;
  final int rejectedForMinimumIntervalCount;

  const _StepDetectionSummary({
    required this.acceptedEvents,
    required this.leadSwitchCount,
    required this.rejectedForLowVelocityCount,
    required this.rejectedForMinimumIntervalCount,
  });
}
