import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';
import 'package:football_note/domain/services/running_analysis_v2.dart';

void main() {
  test('weighted aggregation resists outliers and returns a finite range', () {
    final estimate = runningWeightedEstimate(const <RunningWeightedValue>[
      RunningWeightedValue(
        value: 10,
        confidence: 0.9,
        timestamp: Duration(milliseconds: 100),
      ),
      RunningWeightedValue(
        value: 11,
        confidence: 0.8,
        timestamp: Duration(milliseconds: 200),
      ),
      RunningWeightedValue(
        value: 200,
        confidence: 0.05,
        timestamp: Duration(milliseconds: 300),
      ),
    ]);

    expect(estimate, isNotNull);
    expect(estimate!.value, 10);
    expect(estimate.range.lower, 10);
    expect(estimate.range.upper, 11);
    expect(estimate.value.isFinite, isTrue);
    expect(estimate.sampleCount, 3);
  });

  test('scale segmentation identifies an approaching runner', () {
    final frames = <RunningPoseFrame>[
      for (var index = 0; index < 8; index += 1)
        _poseFrame(
          timestampMs: index * 125,
          torsoScale: 0.18 + index * 0.025,
          hipY: 0.48,
        ),
    ];

    final segments = runningScaleSegments(frames);

    expect(segments, isNotEmpty);
    expect(segments.last.trend, RunningScaleTrend.approaching);
    expect(segments.last.sampleCount, greaterThanOrEqualTo(3));
    expect(segments.last.medianScale, greaterThan(0));
  });

  test('stable to approaching scale change creates separate segments', () {
    final frames = <RunningPoseFrame>[
      for (var index = 0; index < 6; index += 1)
        _poseFrame(timestampMs: index * 125, torsoScale: 0.18),
      for (var index = 0; index < 7; index += 1)
        _poseFrame(
          timestampMs: (index + 6) * 125,
          torsoScale: 0.18 + index * 0.035,
        ),
    ];

    final segments = runningScaleSegments(frames);

    expect(segments.length, greaterThanOrEqualTo(2));
    expect(segments.first.trend, RunningScaleTrend.stable);
    expect(segments.last.trend, RunningScaleTrend.approaching);
  });

  test('approaching to receding transition is not merged as stable', () {
    final frames = <RunningPoseFrame>[
      for (var index = 0; index < 7; index += 1)
        _poseFrame(
          timestampMs: index * 125,
          torsoScale: 0.18 + index * 0.025,
          leftFootY: 0.60,
          rightFootY: 0.60,
        ),
      for (var index = 1; index < 8; index += 1)
        _poseFrame(
          timestampMs: (index + 6) * 125,
          torsoScale: 0.33 - index * 0.022,
          leftFootY: 0.60,
          rightFootY: 0.60,
        ),
    ];

    final segments = runningScaleSegments(frames);

    expect(
      segments.map((segment) => segment.trend),
      containsAll(<RunningScaleTrend>[
        RunningScaleTrend.approaching,
        RunningScaleTrend.receding,
      ]),
    );
  });

  test('short gaps and isolated coordinate spikes are stabilized', () {
    final first = _poseFrame(timestampMs: 0, leftAnkleX: 0.43);
    final missing = _poseFrame(
      timestampMs: 125,
      leftAnkleX: 0.9,
      missingIndexes: const <int>{27},
    );
    final last = _poseFrame(timestampMs: 250, leftAnkleX: 0.45);
    final stabilized = runningStabilizedPoseFrames(<RunningPoseFrame>[
      last,
      missing,
      first,
    ]);

    final ankle = stabilized[1].landmarkByIndex(27)!;
    expect(ankle.x, closeTo(0.44, 0.0001));
    expect(ankle.confidence, closeTo(0.558, 0.001));

    final spike = _poseFrame(timestampMs: 125, leftAnkleX: 0.95);
    final spikeStabilized = runningStabilizedPoseFrames(
      <RunningPoseFrame>[first, spike, last],
    );
    expect(
      spikeStabilized[1].landmarkByIndex(27)!.x,
      closeTo(0.44, 0.0001),
    );
    expect(
      spikeStabilized[1].landmarkByIndex(27)!.confidence,
      lessThan(0.5),
    );
  });

  test('one-frame left-right identity swap is corrected and penalized', () {
    final before = _poseFrame(
      timestampMs: 0,
      leftAnkleX: 0.36,
      rightAnkleX: 0.62,
    );
    final swapped = _swapLeftRight(
      _poseFrame(
        timestampMs: 125,
        leftAnkleX: 0.37,
        rightAnkleX: 0.61,
      ),
    );
    final after = _poseFrame(
      timestampMs: 250,
      leftAnkleX: 0.38,
      rightAnkleX: 0.60,
    );

    final stabilized =
        runningStabilizedPoseFrames(<RunningPoseFrame>[before, swapped, after]);

    expect(stabilized[1].landmarkByIndex(27)!.x, closeTo(0.37, 0.0001));
    expect(stabilized[1].landmarkByIndex(28)!.x, closeTo(0.61, 0.0001));
    expect(stabilized[1].landmarkByIndex(27)!.confidence, lessThan(0.6));
  });

  test('local ground and fallback contacts preserve alternating sides', () {
    const leftY = <double>[
      0.74,
      0.80,
      0.74,
      0.74,
      0.74,
      0.80,
      0.74,
      0.74,
      0.74
    ];
    const rightY = <double>[
      0.74,
      0.74,
      0.74,
      0.80,
      0.74,
      0.74,
      0.74,
      0.80,
      0.74
    ];
    final frames = <RunningPoseFrame>[
      for (var index = 0; index < leftY.length; index += 1)
        _poseFrame(
          timestampMs: index * 125,
          leftFootY: leftY[index],
          rightFootY: rightY[index],
        ),
    ];
    final result = _baseResult(poseFrames: frames);

    final ground = runningLocalGroundLevel(
      frames,
      side: RunningContactSide.left,
      around: const Duration(milliseconds: 125),
    );
    final contacts = runningFallbackContacts(result);

    expect(ground, closeTo(0.80 * 1280, 0.01 * 1280));
    expect(contacts.length, greaterThanOrEqualTo(4));
    expect(contacts.every((contact) => !contact.isConfirmed), isTrue);
    expect(
      contacts.map((contact) => contact.side).take(4),
      orderedEquals(const <RunningContactSide>[
        RunningContactSide.left,
        RunningContactSide.right,
        RunningContactSide.left,
        RunningContactSide.right,
      ]),
    );
  });

  test('missing lower body does not block estimated upper-body metrics', () {
    final frames = <RunningPoseFrame>[
      for (var index = 0; index < 8; index += 1)
        _poseFrame(
          timestampMs: index * 125,
          hipY: 0.48 + (index.isEven ? 0.006 : -0.006),
          wristOffset: index.isEven ? 0.05 : -0.05,
          missingIndexes: const <int>{25, 26, 27, 28, 29, 30, 31, 32},
        ),
    ];

    final derived = deriveRunningAnalysisV2(_baseResult(poseFrames: frames));

    expect(derived.analysisVersion, runningAnalysisVersionV2);
    expect(
      derived.measurementFor(RunningAnalysisMetric.posture).state,
      RunningMeasurementState.estimated,
    );
    expect(
      derived.measurementFor(RunningAnalysisMetric.bounce).state,
      RunningMeasurementState.unavailable,
    );
    expect(
      derived.measurementFor(RunningAnalysisMetric.elbowAngle).state,
      RunningMeasurementState.estimated,
    );
    expect(
      derived.measurementFor(RunningAnalysisMetric.footStrike).state,
      RunningMeasurementState.unavailable,
    );
    expect(
      derived.measurementFor(RunningAnalysisMetric.kneeAtContact).state,
      RunningMeasurementState.unavailable,
    );
    expect(
      derived.measurements.values
          .where((measurement) => measurement.value != null)
          .every((measurement) => measurement.value!.isFinite),
      isTrue,
    );
  });

  test('kinematic-only payload keeps lower body and rhythm estimated', () {
    final frames = <RunningPoseFrame>[
      for (var index = 0; index < 9; index += 1)
        _poseFrame(
          timestampMs: index * 125,
          leftFootY: index.isEven ? 0.82 : 0.74,
          rightFootY: index.isOdd ? 0.82 : 0.74,
        ),
    ];
    const timestamps = <Duration>[
      Duration(milliseconds: 125),
      Duration(milliseconds: 375),
      Duration(milliseconds: 625),
    ];
    final source = _baseResult(
      poseFrames: frames,
      estimatedContacts: timestamps,
      contactWindows: <RunningContactWindow>[
        for (var index = 0; index < timestamps.length; index += 1)
          RunningContactWindow(
            start: timestamps[index] - const Duration(milliseconds: 80),
            center: timestamps[index],
            end: timestamps[index] + const Duration(milliseconds: 80),
            side: index.isEven
                ? RunningContactSide.left
                : RunningContactSide.right,
            denseSampleCount: 5,
            validatedContactTimestamps: const <Duration>[],
            estimatedContactTimestamps: <Duration>[timestamps[index]],
            selectionMethod: 'kinematic',
            confidence: 0,
          ),
      ],
      metricQualities: <RunningCoachMetric, RunningMetricQuality>{
        for (final metric in RunningCoachMetric.values)
          metric: RunningMetricQuality(
            confidence: 0.82,
            sampleCount: 6,
            reason: metric == RunningCoachMetric.footStrike ||
                    metric == RunningCoachMetric.kneeFlexion
                ? 'kinematic_contact_estimate'
                : null,
          ),
      },
    );
    final restored = RunningVideoAnalysisResult.fromMap(source.toMap());
    final fallback = runningFallbackContacts(restored);
    final derived = deriveRunningAnalysisV2(restored);

    expect(restored.validatedContactFrameTimestamps, isEmpty);
    expect(restored.estimatedContactFrameTimestamps, timestamps);
    expect(fallback.where((contact) => contact.isConfirmed), isEmpty);
    for (final metric in const <RunningAnalysisMetric>[
      RunningAnalysisMetric.footStrike,
      RunningAnalysisMetric.kneeAtContact,
      RunningAnalysisMetric.maximumKneeFlexion,
      RunningAnalysisMetric.recoveryKneeFlexion,
      RunningAnalysisMetric.cadence,
      RunningAnalysisMetric.stepTime,
      RunningAnalysisMetric.leftRightTiming,
    ]) {
      expect(
        derived.measurementFor(metric).state,
        isNot(RunningMeasurementState.confirmed),
        reason: metric.name,
      );
    }
  });

  test('pixel-space measurements are invariant to frame aspect and resize', () {
    final portrait = deriveRunningAnalysisV2(
      _physicalPoseResult(imageWidth: 1080, imageHeight: 1920, scale: 1),
    );
    final landscape = deriveRunningAnalysisV2(
      _physicalPoseResult(imageWidth: 1920, imageHeight: 1080, scale: 1),
    );
    final resized = deriveRunningAnalysisV2(
      _physicalPoseResult(imageWidth: 540, imageHeight: 960, scale: 0.5),
    );

    for (final metric in const <RunningAnalysisMetric>[
      RunningAnalysisMetric.posture,
      RunningAnalysisMetric.footStrike,
      RunningAnalysisMetric.kneeAtContact,
      RunningAnalysisMetric.elbowAngle,
    ]) {
      final base = portrait.measurementFor(metric);
      expect(base.state, RunningMeasurementState.confirmed,
          reason: metric.name);
      for (final candidate in <RunningVideoAnalysisResult>[
        landscape,
        resized,
      ]) {
        final compared = candidate.measurementFor(metric);
        expect(compared.state, base.state, reason: metric.name);
        expect(compared.value, isNotNull, reason: metric.name);
        expect(
          compared.value!,
          closeTo(base.value!, 0.001),
          reason: metric.name,
        );
      }
    }
  });

  test('foot pitch measurement folds reversed atan2 orientation into 0 to 90',
      () {
    final result = deriveRunningAnalysisV2(
      _physicalPoseResult(
        imageWidth: 1080,
        imageHeight: 1920,
        scale: 1,
        reverseFootPitch: true,
      ),
    );
    final rolling = result.measurementFor(RunningAnalysisMetric.footRolling);

    expect(rolling.value, isNotNull);
    expect(rolling.value!, inInclusiveRange(0, 90));
  });

  test('airborne recovery knee is not classified as a landing contact', () {
    final frames = <RunningPoseFrame>[
      _poseFrame(
        timestampMs: 0,
        leftFootY: 0.72,
        leftKneeX: 0.34,
        leftKneeY: 0.58,
      ),
      _poseFrame(
        timestampMs: 125,
        leftFootY: 0.61,
        leftKneeX: 0.34,
        leftKneeY: 0.57,
      ),
      _poseFrame(
        timestampMs: 250,
        leftFootY: 0.73,
        leftKneeX: 0.34,
        leftKneeY: 0.58,
      ),
      _poseFrame(timestampMs: 375, leftFootY: 0.82),
      _poseFrame(timestampMs: 500, leftFootY: 0.73),
    ];

    final contacts = runningFallbackContacts(_baseResult(poseFrames: frames));

    expect(
      contacts.map((contact) => contact.timestamp),
      isNot(contains(const Duration(milliseconds: 125))),
    );
  });

  test('recovery knee flexion is reported separately from contact knee', () {
    const contactTimes = <int>[600, 900, 1200];
    final frames = <RunningPoseFrame>[
      _poseFrame(
        timestampMs: 240,
        leftFootY: 0.62,
        leftKneeX: 0.34,
        leftKneeY: 0.59,
      ),
      _poseFrame(timestampMs: 600, leftFootY: 0.82, rightFootY: 0.70),
      _poseFrame(
        timestampMs: 680,
        leftFootY: 0.82,
        rightFootY: 0.70,
        leftKneeX: 0.39,
        leftKneeY: 0.64,
      ),
      _poseFrame(
        timestampMs: 700,
        rightFootY: 0.62,
        rightKneeX: 0.60,
        rightKneeY: 0.59,
      ),
      _poseFrame(timestampMs: 900, leftFootY: 0.70, rightFootY: 0.82),
      _poseFrame(
        timestampMs: 980,
        leftFootY: 0.70,
        rightFootY: 0.82,
        rightKneeX: 0.55,
        rightKneeY: 0.64,
      ),
      _poseFrame(
        timestampMs: 1000,
        leftFootY: 0.62,
        leftKneeX: 0.34,
        leftKneeY: 0.59,
      ),
      _poseFrame(timestampMs: 1200, leftFootY: 0.82, rightFootY: 0.70),
      _poseFrame(
        timestampMs: 1280,
        leftFootY: 0.82,
        rightFootY: 0.70,
        leftKneeX: 0.39,
        leftKneeY: 0.64,
      ),
    ];
    final contactWindows = <RunningContactWindow>[
      for (var index = 0; index < contactTimes.length; index += 1)
        RunningContactWindow(
          start: Duration(milliseconds: contactTimes[index] - 80),
          center: Duration(milliseconds: contactTimes[index]),
          end: Duration(milliseconds: contactTimes[index] + 160),
          side:
              index.isEven ? RunningContactSide.left : RunningContactSide.right,
          denseSampleCount: 5,
          validatedContactTimestamps: <Duration>[
            Duration(milliseconds: contactTimes[index]),
          ],
          confidence: 0.92,
        ),
    ];
    final result = deriveRunningAnalysisV2(
      _baseResult(
        poseFrames: frames,
        contactWindows: contactWindows,
        validatedContacts: <Duration>[
          for (final timestamp in contactTimes)
            Duration(milliseconds: timestamp),
        ],
        metricQualities: <RunningCoachMetric, RunningMetricQuality>{
          for (final metric in RunningCoachMetric.values)
            metric: const RunningMetricQuality(
              confidence: 0.90,
              sampleCount: 5,
            ),
        },
      ),
    );

    final contactKnee =
        result.measurementFor(RunningAnalysisMetric.kneeAtContact);
    final supportKnee =
        result.measurementFor(RunningAnalysisMetric.maximumKneeFlexion);
    final recoveryKnee =
        result.measurementFor(RunningAnalysisMetric.recoveryKneeFlexion);

    expect(contactKnee.state, isNot(RunningMeasurementState.unavailable));
    expect(supportKnee.state, isNot(RunningMeasurementState.unavailable));
    expect(recoveryKnee.state, isNot(RunningMeasurementState.unavailable));
    expect(recoveryKnee.value!, lessThan(contactKnee.value! - 20));
    expect(recoveryKnee.value!, isNot(closeTo(supportKnee.value!, 0.001)));
    expect(
      recoveryKnee.evidenceTimestamps,
      everyElement(
        isNot(
          isIn(<Duration>[
            for (final timestamp in contactTimes)
              Duration(milliseconds: timestamp),
          ]),
        ),
      ),
    );
  });

  test('signed lean distinguishes forward and backward in both directions', () {
    RunningMetricMeasurement posture(
      RunningDirection direction,
      double shoulderCenterX,
      double hipCenterX,
    ) {
      final frames = <RunningPoseFrame>[
        for (var index = 0; index < 6; index += 1)
          _poseFrame(
            timestampMs: index * 125,
            shoulderCenterX: shoulderCenterX,
            hipCenterX: hipCenterX,
            missingIndexes: const <int>{29, 30, 31, 32},
          ),
      ];
      return deriveRunningAnalysisV2(
        _baseResult(poseFrames: frames, direction: direction),
      ).measurementFor(RunningAnalysisMetric.posture);
    }

    expect(posture(RunningDirection.leftToRight, 0.52, 0.47).value,
        greaterThan(0));
    expect(
        posture(RunningDirection.leftToRight, 0.42, 0.47).value, lessThan(0));
    expect(posture(RunningDirection.rightToLeft, 0.42, 0.47).value,
        greaterThan(0));
    expect(
        posture(RunningDirection.rightToLeft, 0.52, 0.47).value, lessThan(0));
  });

  test('running window beats a stationary preparation segment', () {
    final frames = <RunningPoseFrame>[
      for (var index = 0; index < 6; index += 1)
        _poseFrame(timestampMs: index * 125),
      for (var index = 0; index < 8; index += 1)
        _poseFrame(
          timestampMs: 1000 + index * 125,
          leftAnkleX: 0.38 + (index.isEven ? -0.08 : 0.08),
          rightAnkleX: 0.56 + (index.isEven ? 0.08 : -0.08),
          leftFootY: index.isEven ? 0.82 : 0.70,
          rightFootY: index.isEven ? 0.70 : 0.82,
        ),
    ];
    final segments = <RunningScaleSegment>[
      const RunningScaleSegment(
        start: Duration.zero,
        end: Duration(milliseconds: 625),
        trend: RunningScaleTrend.stable,
        medianScale: 0.3,
        confidence: 0.95,
        sampleCount: 6,
      ),
      const RunningScaleSegment(
        start: Duration(milliseconds: 1000),
        end: Duration(milliseconds: 1875),
        trend: RunningScaleTrend.stable,
        medianScale: 0.3,
        confidence: 0.85,
        sampleCount: 8,
      ),
    ];

    final selected = runningBestAnalysisWindow(frames, segments);

    expect(runningMotionScore(frames.take(6).toList()), lessThan(0.1));
    expect(runningMotionScore(frames.skip(6).toList()), greaterThan(0.5));
    expect(selected?.$1, const Duration(milliseconds: 1000));
  });

  test('motion score accepts in-place cadence but rejects static jitter', () {
    final inPlaceRunning = <RunningPoseFrame>[
      for (var index = 0; index < 16; index += 1)
        _poseFrame(
          timestampMs: index * 125,
          leftAnkleX: 0.43 + (index.isEven ? -0.08 : 0.08),
          rightAnkleX: 0.51 + (index.isEven ? 0.08 : -0.08),
          leftFootY: index.isEven ? 0.82 : 0.70,
          rightFootY: index.isEven ? 0.70 : 0.82,
          leftKneeY: index.isEven ? 0.64 : 0.58,
          rightKneeY: index.isEven ? 0.58 : 0.64,
        ),
    ];
    final staticJitter = <RunningPoseFrame>[
      for (var index = 0; index < 16; index += 1)
        _poseFrame(
          timestampMs: index * 125,
          hipCenterX: 0.47 + (((index % 5) - 2) * 0.0004),
          leftAnkleX: 0.43 + (((index % 3) - 1) * 0.001),
          rightAnkleX: 0.51 - (((index % 3) - 1) * 0.001),
          leftFootY: 0.78 + (((index % 4) - 1.5) * 0.001),
          rightFootY: 0.75 - (((index % 4) - 1.5) * 0.001),
        ),
    ];

    expect(runningMotionScore(inPlaceRunning), greaterThan(0.5));
    expect(runningMotionScore(staticJitter), lessThan(0.1));
  });

  test('trajectory extrema estimate rhythm without validated contacts', () {
    const left = <double>[
      0.72,
      0.76,
      0.82,
      0.76,
      0.72,
      0.70,
      0.72,
      0.76,
      0.82,
      0.76,
      0.72,
      0.70,
      0.72,
      0.76,
      0.82,
      0.76,
      0.72,
    ];
    const right = <double>[
      0.72,
      0.70,
      0.72,
      0.76,
      0.78,
      0.82,
      0.78,
      0.74,
      0.72,
      0.70,
      0.72,
      0.76,
      0.78,
      0.82,
      0.78,
      0.74,
      0.72,
    ];
    final frames = <RunningPoseFrame>[
      for (var index = 0; index < left.length; index += 1)
        _poseFrame(
          timestampMs: index * 100,
          leftFootY: left[index],
          rightFootY: right[index],
        ),
    ];

    final estimate = runningTrajectoryRhythmEstimate(frames);
    final derived = deriveRunningAnalysisV2(_baseResult(poseFrames: frames));

    expect(estimate, isNotNull);
    expect(estimate!.cadenceSpm, closeTo(200, 15));
    expect(
      derived.measurementFor(RunningAnalysisMetric.cadence).state,
      RunningMeasurementState.estimated,
    );
    expect(
      derived.measurementFor(RunningAnalysisMetric.cadence).method,
      anyOf('pose_cycle_period_estimate', 'pose_trajectory_cycle_estimate'),
    );
  });

  test('v2 payload round-trips states, ranges, methods, and evidence', () {
    final derived = deriveRunningAnalysisV2(
      _baseResult(
        poseFrames: <RunningPoseFrame>[
          for (var index = 0; index < 8; index += 1)
            _poseFrame(timestampMs: index * 125),
        ],
      ),
    );

    final restored = RunningVideoAnalysisResult.fromMap(derived.toMap());
    final posture = restored.measurementFor(RunningAnalysisMetric.posture);

    expect(restored.analysisVersion, runningAnalysisVersionV2);
    expect(restored.measurements.length, RunningAnalysisMetric.values.length);
    expect(posture.state, RunningMeasurementState.estimated);
    expect(posture.expectedRange, isNotNull);
    expect(posture.method, 'stable_segment_trunk_median');
    expect(posture.evidenceTimestamps, isNotEmpty);
    expect(restored.scaleSegments, isNotEmpty);
  });
}

RunningVideoAnalysisResult _baseResult({
  required List<RunningPoseFrame> poseFrames,
  RunningDirection direction = RunningDirection.leftToRight,
  List<Duration> estimatedContacts = const <Duration>[],
  List<Duration> validatedContacts = const <Duration>[],
  List<RunningContactWindow> contactWindows = const <RunningContactWindow>[],
  Map<RunningCoachMetric, RunningMetricQuality>? metricQualities,
}) {
  return RunningVideoAnalysisResult(
    videoDuration: const Duration(seconds: 75),
    sampledFrames: poseFrames.length,
    validFrames: poseFrames.length,
    direction: direction,
    forwardLeanDegrees: 0,
    verticalBounceRatio: 0,
    footStrikeDistanceRatio: 0,
    stanceKneeAngleDegrees: 0,
    elbowAngleDegrees: 0,
    metricQualities: metricQualities ??
        <RunningCoachMetric, RunningMetricQuality>{
          for (final metric in RunningCoachMetric.values)
            metric: const RunningMetricQuality(
              confidence: 0.5,
              sampleCount: 8,
              reason: 'coarse_only',
            ),
        },
    poseFrames: poseFrames,
    contactWindows: contactWindows,
    validatedContactFrameTimestamps: validatedContacts,
    estimatedContactFrameTimestamps: estimatedContacts,
    contactConfidence: validatedContacts.isNotEmpty
        ? 0.90
        : estimatedContacts.isEmpty
            ? 0
            : 0.58,
  );
}

RunningVideoAnalysisResult _physicalPoseResult({
  required int imageWidth,
  required int imageHeight,
  required double scale,
  bool reverseFootPitch = false,
}) {
  const contactTimes = <int>[125, 375, 625];
  final frames = <RunningPoseFrame>[
    for (var index = 0; index < 6; index += 1)
      _physicalPoseFrame(
        timestampMs: index * 125,
        frameIndex: index,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        scale: scale,
        reverseFootPitch: reverseFootPitch,
      ),
  ];
  final contactDurations = <Duration>[
    for (final timestampMs in contactTimes) Duration(milliseconds: timestampMs),
  ];
  return _baseResult(
    poseFrames: frames,
    validatedContacts: contactDurations,
    contactWindows: <RunningContactWindow>[
      for (var index = 0; index < contactDurations.length; index += 1)
        RunningContactWindow(
          start: contactDurations[index] - const Duration(milliseconds: 70),
          center: contactDurations[index],
          end: contactDurations[index] + const Duration(milliseconds: 120),
          side:
              index.isEven ? RunningContactSide.left : RunningContactSide.right,
          denseSampleCount: 5,
          validatedContactTimestamps: <Duration>[contactDurations[index]],
          confidence: 0.92,
          selectionMethod: 'ground',
        ),
    ],
    metricQualities: <RunningCoachMetric, RunningMetricQuality>{
      for (final metric in RunningCoachMetric.values)
        metric: const RunningMetricQuality(confidence: 0.92, sampleCount: 6),
    },
  );
}

RunningPoseFrame _physicalPoseFrame({
  required int timestampMs,
  required int frameIndex,
  required int imageWidth,
  required int imageHeight,
  required double scale,
  required bool reverseFootPitch,
}) {
  final landmarks = List<RunningVideoPoseLandmark>.generate(
    mediaPipePoseLandmarkCount,
    (index) => RunningVideoPoseLandmark(
      index: index,
      x: 0,
      y: 0,
      z: 0,
      visibility: 0,
      presence: 0,
      confidence: 0,
    ),
  );
  void setPoint(int index, double x, double y) {
    landmarks[index] = RunningVideoPoseLandmark(
      index: index,
      x: x / imageWidth,
      y: y / imageHeight,
      z: 0,
      visibility: 0.96,
      presence: 0.96,
      confidence: 0.94,
    );
  }

  final hipX = (360 + frameIndex * 32) * scale;
  final hipY = 520 * scale;
  final torso = 220 * scale;
  final shoulderX = hipX + (50 * scale);
  final shoulderY = hipY - torso;
  setPoint(11, shoulderX - (50 * scale), shoulderY);
  setPoint(12, shoulderX + (50 * scale), shoulderY);
  setPoint(23, hipX - (42 * scale), hipY);
  setPoint(24, hipX + (42 * scale), hipY);

  setPoint(13, shoulderX - (88 * scale), shoulderY + (95 * scale));
  setPoint(14, shoulderX + (88 * scale), shoulderY + (98 * scale));
  setPoint(15, shoulderX - (44 * scale), shoulderY + (205 * scale));
  setPoint(16, shoulderX + (132 * scale), shoulderY + (208 * scale));

  setPoint(25, hipX - (24 * scale), hipY + (175 * scale));
  setPoint(26, hipX + (35 * scale), hipY + (170 * scale));
  setPoint(27, hipX + (10 * scale), hipY + (380 * scale));
  setPoint(28, hipX + (38 * scale), hipY + (372 * scale));
  final leftHeelX =
      reverseFootPitch ? hipX + (62 * scale) : hipX - (12 * scale);
  final leftToeX = reverseFootPitch ? hipX - (6 * scale) : hipX + (58 * scale);
  final rightHeelX =
      reverseFootPitch ? hipX + (88 * scale) : hipX + (16 * scale);
  final rightToeX =
      reverseFootPitch ? hipX + (22 * scale) : hipX + (86 * scale);
  setPoint(29, leftHeelX, hipY + (382 * scale));
  setPoint(30, rightHeelX, hipY + (374 * scale));
  setPoint(31, leftToeX, hipY + (382 * scale));
  setPoint(32, rightToeX, hipY + (374 * scale));

  return RunningPoseFrame(
    timestamp: Duration(milliseconds: timestampMs),
    imageWidth: imageWidth,
    imageHeight: imageHeight,
    landmarks: List<RunningVideoPoseLandmark>.unmodifiable(landmarks),
  );
}

RunningPoseFrame _poseFrame({
  required int timestampMs,
  double torsoScale = 0.22,
  double hipY = 0.48,
  double leftAnkleX = 0.43,
  double leftFootY = 0.78,
  double rightFootY = 0.75,
  double rightAnkleX = 0.51,
  double? leftKneeX,
  double? leftKneeY,
  double? rightKneeX,
  double? rightKneeY,
  double wristOffset = 0.04,
  double shoulderCenterX = 0.47,
  double hipCenterX = 0.47,
  Set<int> missingIndexes = const <int>{},
}) {
  final landmarks = List<RunningVideoPoseLandmark>.generate(
    mediaPipePoseLandmarkCount,
    (index) => RunningVideoPoseLandmark(
      index: index,
      x: 0,
      y: 0,
      z: 0,
      visibility: 0,
      presence: 0,
      confidence: 0,
    ),
  );
  void setPoint(int index, double x, double y) {
    if (missingIndexes.contains(index)) return;
    landmarks[index] = RunningVideoPoseLandmark(
      index: index,
      x: x,
      y: y,
      z: 0,
      visibility: 0.95,
      presence: 0.95,
      confidence: 0.9,
    );
  }

  final shoulderY = hipY - torsoScale;
  setPoint(11, shoulderCenterX - 0.05, shoulderY);
  setPoint(12, shoulderCenterX + 0.05, shoulderY);
  setPoint(23, hipCenterX - 0.04, hipY);
  setPoint(24, hipCenterX + 0.04, hipY);
  setPoint(13, 0.40, shoulderY + 0.10);
  setPoint(14, 0.54, shoulderY + 0.10);
  setPoint(15, 0.40 + wristOffset, shoulderY + 0.19);
  setPoint(16, 0.54 - wristOffset, shoulderY + 0.19);
  setPoint(25, leftKneeX ?? 0.44, leftKneeY ?? hipY + 0.16);
  setPoint(26, rightKneeX ?? 0.50, rightKneeY ?? hipY + 0.16);
  setPoint(27, leftAnkleX, leftFootY);
  setPoint(28, rightAnkleX, rightFootY);
  setPoint(29, leftAnkleX - 0.01, leftFootY);
  setPoint(30, rightAnkleX - 0.01, rightFootY);
  setPoint(31, leftAnkleX + 0.04, leftFootY);
  setPoint(32, rightAnkleX + 0.04, rightFootY);
  return RunningPoseFrame(
    timestamp: Duration(milliseconds: timestampMs),
    imageWidth: 720,
    imageHeight: 1280,
    landmarks: List<RunningVideoPoseLandmark>.unmodifiable(landmarks),
  );
}

RunningPoseFrame _swapLeftRight(RunningPoseFrame frame) {
  final byIndex = <int, RunningVideoPoseLandmark>{
    for (final landmark in frame.landmarks) landmark.index: landmark,
  };
  for (final pair in const <(int, int)>[
    (11, 12),
    (13, 14),
    (15, 16),
    (23, 24),
    (25, 26),
    (27, 28),
    (29, 30),
    (31, 32),
  ]) {
    final left = byIndex[pair.$1]!;
    final right = byIndex[pair.$2]!;
    byIndex[pair.$1] = RunningVideoPoseLandmark.fromObject(
      <String, Object?>{...right.toMap(), 'index': pair.$1},
    )!;
    byIndex[pair.$2] = RunningVideoPoseLandmark.fromObject(
      <String, Object?>{...left.toMap(), 'index': pair.$2},
    )!;
  }
  final landmarks = byIndex.values.toList(growable: false)
    ..sort((left, right) => left.index.compareTo(right.index));
  return RunningPoseFrame(
    timestamp: frame.timestamp,
    imageWidth: frame.imageWidth,
    imageHeight: frame.imageHeight,
    landmarks: landmarks,
  );
}
