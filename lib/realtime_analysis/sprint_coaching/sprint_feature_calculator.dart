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
    double footContactGroundClearanceRatio = 0.08,
    double flightGroundClearanceRatio = 0.14,
  }) {
    if (frames.isEmpty) {
      return const SprintFeatureSnapshot.empty();
    }

    final trunkSamples = _weightedValues(frames, _trunkAngleDegrees);
    final kneeDriveSamples = _weightedValues(frames, _kneeDriveHeightRatio);
    final armExcursions = _armExcursions(frames);
    final gaitPhase = _summarizeGaitPhase(
      frames,
      footContactGroundClearanceRatio: footContactGroundClearanceRatio,
      flightGroundClearanceRatio: flightGroundClearanceRatio,
    );
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
            .timestamp
            .difference(stepEvents[index - 1].timestamp)
            .inMilliseconds
            .toDouble(),
    ];
    final landingMetrics = _landingMetrics(stepEvents);
    final lateFormDrop = _lateFormDrop(frames);

    final averageStepIntervalMs =
        stepIntervalsMs.isEmpty ? null : _average(stepIntervalsMs);
    final cadence = averageStepIntervalMs == null || averageStepIntervalMs <= 0
        ? null
        : 60000 / averageStepIntervalMs;
    final rhythmStd =
        stepIntervalsMs.isEmpty ? null : _standardDeviation(stepIntervalsMs);
    final cadenceConfidence = _stepMetricConfidence(stepDetection, stepEvents);
    final hasFlightRatioEvidence = gaitPhase.validFrameCount >= 3 &&
        gaitPhase.stanceFrameCount > 0 &&
        gaitPhase.flightFrameCount > 0;

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
      overstride: landingMetrics == null
          ? const SprintMeasuredValue.unavailable(
              reasonIfUnavailable: 'insufficient_landing_events',
            )
          : SprintMeasuredValue.available(
              value: landingMetrics.overstrideRatio,
              confidence: landingMetrics.confidence,
              sampleCount: landingMetrics.sampleCount,
            ),
      shinAngle: landingMetrics == null
          ? const SprintMeasuredValue.unavailable(
              reasonIfUnavailable: 'insufficient_landing_events',
            )
          : SprintMeasuredValue.available(
              value: landingMetrics.shinAngleDegrees,
              confidence: landingMetrics.confidence,
              sampleCount: landingMetrics.sampleCount,
            ),
      flightRatio: !hasFlightRatioEvidence
          ? SprintMeasuredValue.unavailable(
              reasonIfUnavailable: 'insufficient_gait_phase',
              sampleCount: gaitPhase.validFrameCount,
            )
          : SprintMeasuredValue.available(
              value: gaitPhase.flightRatio,
              confidence: gaitPhase.confidence,
              sampleCount: gaitPhase.validFrameCount,
            ),
      contactBalance: gaitPhase.contactSampleCount < 3
          ? const SprintMeasuredValue.unavailable(
              reasonIfUnavailable: 'insufficient_gait_phase',
            )
          : SprintMeasuredValue.available(
              value: gaitPhase.contactBalanceAsymmetry,
              confidence: gaitPhase.confidence,
              sampleCount: gaitPhase.contactSampleCount,
            ),
      lateFormDrop: lateFormDrop,
      stepInterval: averageStepIntervalMs == null
          ? null
          : Duration(milliseconds: averageStepIntervalMs.round()),
      gaitPhase: gaitPhase.currentPhase,
      gaitPhaseConfidence: gaitPhase.confidence,
      detectedStepEvents: stepEvents.length,
      stepCrossoverCount: stepDetection.leadSwitchCount,
      rejectedStepEventsLowVelocity: stepDetection.rejectedForLowVelocityCount,
      rejectedStepEventsMinInterval:
          stepDetection.rejectedForMinimumIntervalCount,
      landingEventCount: landingMetrics?.sampleCount ?? 0,
      stanceFrameCount: gaitPhase.stanceFrameCount,
      flightFrameCount: gaitPhase.flightFrameCount,
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
    final acceptedEvents = <_StepEvent>[];
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
          acceptedEvents.add(
            _StepEvent(
              timestamp: frame.timestamp,
              leadFoot: leadFoot,
              frame: frame,
            ),
          );
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

  _GaitPhaseSummary _summarizeGaitPhase(
    List<SprintNormalizedPoseFrame> frames, {
    required double footContactGroundClearanceRatio,
    required double flightGroundClearanceRatio,
  }) {
    if (frames.length < 3) {
      return const _GaitPhaseSummary.empty();
    }

    final ankleYs = <double>[];
    for (final frame in frames) {
      final leftAnkle = frame.landmark(SprintPoseLandmarkType.leftAnkle);
      final rightAnkle = frame.landmark(SprintPoseLandmarkType.rightAnkle);
      if (leftAnkle != null) {
        ankleYs.add(leftAnkle.dy);
      }
      if (rightAnkle != null) {
        ankleYs.add(rightAnkle.dy);
      }
    }
    if (ankleYs.length < 4) {
      return const _GaitPhaseSummary.empty();
    }

    final groundY = ankleYs.reduce((value, element) {
      return value > element ? value : element;
    });
    var leftStanceCount = 0;
    var rightStanceCount = 0;
    var doubleSupportCount = 0;
    var flightCount = 0;
    var validFrameCount = 0;
    var confidenceTotal = 0.0;
    var currentPhase = SprintGaitPhase.unknown;

    for (final frame in frames) {
      final leftAnkle = frame.landmark(SprintPoseLandmarkType.leftAnkle);
      final rightAnkle = frame.landmark(SprintPoseLandmarkType.rightAnkle);
      if (leftAnkle == null || rightAnkle == null) {
        continue;
      }
      final leftGap = groundY - leftAnkle.dy;
      final rightGap = groundY - rightAnkle.dy;
      final leftContact = leftGap <= footContactGroundClearanceRatio;
      final rightContact = rightGap <= footContactGroundClearanceRatio;
      final leftAirborne = leftGap >= flightGroundClearanceRatio;
      final rightAirborne = rightGap >= flightGroundClearanceRatio;
      final phase = switch ((leftContact, rightContact)) {
        (true, true) => SprintGaitPhase.doubleSupport,
        (true, false) => SprintGaitPhase.leftStance,
        (false, true) => SprintGaitPhase.rightStance,
        (false, false) => leftAirborne && rightAirborne
            ? SprintGaitPhase.flight
            : SprintGaitPhase.unknown,
      };
      if (phase == SprintGaitPhase.unknown) {
        continue;
      }
      currentPhase = phase;
      validFrameCount += 1;
      confidenceTotal += _average(<double>[
        frame.landmarkConfidence(SprintPoseLandmarkType.leftAnkle) ?? 0,
        frame.landmarkConfidence(SprintPoseLandmarkType.rightAnkle) ?? 0,
      ]);
      switch (phase) {
        case SprintGaitPhase.leftStance:
          leftStanceCount += 1;
        case SprintGaitPhase.rightStance:
          rightStanceCount += 1;
        case SprintGaitPhase.doubleSupport:
          doubleSupportCount += 1;
        case SprintGaitPhase.flight:
          flightCount += 1;
        case SprintGaitPhase.unknown:
          break;
      }
    }

    if (validFrameCount == 0) {
      return const _GaitPhaseSummary.empty();
    }

    final stanceFrameCount =
        leftStanceCount + rightStanceCount + doubleSupportCount;
    final unilateralContactCount = leftStanceCount + rightStanceCount;
    final contactBalance = unilateralContactCount == 0
        ? 0.0
        : (leftStanceCount - rightStanceCount).abs() / unilateralContactCount;
    final sampleCoverage = validFrameCount / frames.length;
    return _GaitPhaseSummary(
      currentPhase: currentPhase,
      validFrameCount: validFrameCount,
      stanceFrameCount: stanceFrameCount,
      flightFrameCount: flightCount,
      contactSampleCount: stanceFrameCount,
      flightRatio: flightCount / validFrameCount,
      contactBalanceAsymmetry: contactBalance,
      confidence: ((confidenceTotal / validFrameCount) * sampleCoverage)
          .clamp(0.0, 1.0),
    );
  }

  _LandingMetrics? _landingMetrics(List<_StepEvent> stepEvents) {
    if (stepEvents.length < 2) {
      return null;
    }

    final overstrideValues = <double>[];
    final shinAngles = <double>[];
    final confidences = <double>[];

    for (final event in stepEvents) {
      final ankleType = event.leadFoot == _LeadFootState.leftLead
          ? SprintPoseLandmarkType.leftAnkle
          : SprintPoseLandmarkType.rightAnkle;
      final kneeType = event.leadFoot == _LeadFootState.leftLead
          ? SprintPoseLandmarkType.leftKnee
          : SprintPoseLandmarkType.rightKnee;
      final ankle = event.frame.landmark(ankleType);
      final knee = event.frame.landmark(kneeType);
      if (ankle == null || knee == null) {
        continue;
      }

      overstrideValues.add(ankle.dx.abs());
      shinAngles.add(_limbAngleFromVertical(knee, ankle));
      confidences.add(
        _average(<double>[
          event.frame.landmarkConfidence(ankleType) ?? 0,
          event.frame.landmarkConfidence(kneeType) ?? 0,
        ]),
      );
    }

    if (overstrideValues.length < 2 || shinAngles.length < 2) {
      return null;
    }

    return _LandingMetrics(
      overstrideRatio: _upperWindowAverage(overstrideValues),
      shinAngleDegrees: _upperWindowAverage(shinAngles),
      confidence:
          (_average(confidences) * math.min(1.0, overstrideValues.length / 4.0))
              .clamp(0.0, 1.0),
      sampleCount: math.min(overstrideValues.length, shinAngles.length),
    );
  }

  SprintMeasuredValue _lateFormDrop(List<SprintNormalizedPoseFrame> frames) {
    if (frames.length < 6) {
      return const SprintMeasuredValue.unavailable(
        reasonIfUnavailable: 'insufficient_session_reference',
      );
    }

    final windowSize = math.max(3, frames.length ~/ 3);
    final earlyFrames = frames.take(windowSize).toList(growable: false);
    final lateFrames = frames.skip(frames.length - windowSize).toList(
          growable: false,
        );
    final earlyKnee = _weightedValues(earlyFrames, _kneeDriveHeightRatio);
    final lateKnee = _weightedValues(lateFrames, _kneeDriveHeightRatio);
    final earlyTrunk = _weightedValues(earlyFrames, _trunkAngleDegrees);
    final lateTrunk = _weightedValues(lateFrames, _trunkAngleDegrees);
    if (earlyKnee.length < 2 ||
        lateKnee.length < 2 ||
        earlyTrunk.length < 2 ||
        lateTrunk.length < 2) {
      return const SprintMeasuredValue.unavailable(
        reasonIfUnavailable: 'insufficient_session_reference',
      );
    }

    final earlyKneeDrive = _upperWindowAverage(
      earlyKnee.map((sample) => sample.value).toList(growable: false),
    );
    final lateKneeDrive = _upperWindowAverage(
      lateKnee.map((sample) => sample.value).toList(growable: false),
    );
    final earlyTrunkAngle = _trimmedAverage(
      earlyTrunk.map((sample) => sample.value).toList(growable: false),
    );
    final lateTrunkAngle = _trimmedAverage(
      lateTrunk.map((sample) => sample.value).toList(growable: false),
    );
    final kneeDropRatio = earlyKneeDrive <= 0
        ? 0.0
        : ((earlyKneeDrive - lateKneeDrive) / earlyKneeDrive).clamp(0.0, 1.0);
    final trunkDropDegrees =
        (earlyTrunkAngle - lateTrunkAngle).clamp(0.0, double.infinity);
    final score =
        ((kneeDropRatio / 0.2) * 0.62) + ((trunkDropDegrees / 8) * 0.38);
    final confidences = <double>[
      ...earlyKnee.map((sample) => sample.confidence),
      ...lateKnee.map((sample) => sample.confidence),
      ...earlyTrunk.map((sample) => sample.confidence),
      ...lateTrunk.map((sample) => sample.confidence),
    ];
    return SprintMeasuredValue.available(
      value: score.clamp(0.0, 1.0),
      confidence: (_average(confidences) * math.min(1.0, frames.length / 9.0))
          .clamp(0.0, 1.0),
      sampleCount: frames.length,
    );
  }

  List<_WeightedSample> _weightedValues(
    List<SprintNormalizedPoseFrame> frames,
    _WeightedSample? Function(SprintNormalizedPoseFrame frame) mapper,
  ) {
    return <_WeightedSample>[
      for (final frame in frames)
        if (mapper(frame) case final sample?) sample,
    ];
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
    List<_StepEvent> stepEvents,
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

  double _limbAngleFromVertical(Offset proximal, Offset distal) {
    final axis = distal - proximal;
    final verticalMagnitude = axis.dy.abs();
    if (verticalMagnitude <= 0) {
      return 0;
    }
    return math.atan2(axis.dx.abs(), verticalMagnitude) * 180 / math.pi;
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

class _StepEvent {
  final DateTime timestamp;
  final _LeadFootState leadFoot;
  final SprintNormalizedPoseFrame frame;

  const _StepEvent({
    required this.timestamp,
    required this.leadFoot,
    required this.frame,
  });
}

class _StepDetectionSummary {
  final List<_StepEvent> acceptedEvents;
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

class _GaitPhaseSummary {
  final SprintGaitPhase currentPhase;
  final int validFrameCount;
  final int stanceFrameCount;
  final int flightFrameCount;
  final int contactSampleCount;
  final double flightRatio;
  final double contactBalanceAsymmetry;
  final double confidence;

  const _GaitPhaseSummary({
    required this.currentPhase,
    required this.validFrameCount,
    required this.stanceFrameCount,
    required this.flightFrameCount,
    required this.contactSampleCount,
    required this.flightRatio,
    required this.contactBalanceAsymmetry,
    required this.confidence,
  });

  const _GaitPhaseSummary.empty()
      : currentPhase = SprintGaitPhase.unknown,
        validFrameCount = 0,
        stanceFrameCount = 0,
        flightFrameCount = 0,
        contactSampleCount = 0,
        flightRatio = 0,
        contactBalanceAsymmetry = 0,
        confidence = 0;
}

class _LandingMetrics {
  final double overstrideRatio;
  final double shinAngleDegrees;
  final double confidence;
  final int sampleCount;

  const _LandingMetrics({
    required this.overstrideRatio,
    required this.shinAngleDegrees,
    required this.confidence,
    required this.sampleCount,
  });
}
