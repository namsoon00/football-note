import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';

void main() {
  test('fromMap keeps legacy payload compatibility without poseFrames', () {
    final result = RunningVideoAnalysisResult.fromMap({
      'durationMs': 4200,
      'sampledFrames': 14,
      'validFrames': 12,
      'direction': 'leftToRight',
      'forwardLeanDegrees': 11.4,
      'verticalBounceRatio': 0.071,
      'footStrikeDistanceRatio': 0.12,
      'stanceKneeAngleDegrees': 151,
      'elbowAngleDegrees': 94,
    });

    expect(result.videoDuration, const Duration(milliseconds: 4200));
    expect(result.direction, RunningDirection.leftToRight);
    expect(result.poseFrames, isEmpty);
    expect(result.coarseSamples.attemptedFrames, 14);
    expect(result.coarseSamples.validFrames, 12);
    expect(result.denseSamples.attemptedFrames, 0);
    expect(result.contactWindows, isEmpty);
  });

  test('fromMap parses complete MediaPipe poseFrames robustly', () {
    final result = RunningVideoAnalysisResult.fromMap({
      'durationMs': 4000,
      'sampledFrames': 14,
      'validFrames': 12,
      'direction': 'rightToLeft',
      'forwardLeanDegrees': 'bad',
      'verticalBounceRatio': 0.07,
      'footStrikeDistanceRatio': 0.11,
      'stanceKneeAngleDegrees': 152,
      'elbowAngleDegrees': 96,
      'poseFrames': [
        _poseFrameMap(timestampMs: 800, imageWidth: 640, imageHeight: 360),
        {
          'timestampMs': 900,
          'imageWidth': 640,
          'imageHeight': 360,
          'landmarks': [_landmarkMap(0)],
        },
        _poseFrameMap(timestampMs: 500, imageWidth: 640, imageHeight: 360),
      ],
    });

    expect(result.forwardLeanDegrees, 0);
    expect(result.direction, RunningDirection.rightToLeft);
    expect(result.poseFrames, hasLength(2));
    expect(result.poseFrames.map((frame) => frame.timestampMs), [500, 800]);
    final frame = result.poseFrames.last;
    expect(frame.imageWidth, 640);
    expect(frame.imageHeight, 360);
    expect(frame.landmarks, hasLength(mediaPipePoseLandmarkCount));
    expect(frame.landmarkByIndex(11)!.x, closeTo(0.21, 0.0001));
    expect(frame.landmarkByIndex(11)!.visibility, closeTo(0.71, 0.0001));
    expect(frame.landmarkByIndex(11)!.presence, closeTo(0.61, 0.0001));
    expect(frame.landmarkByIndex(11)!.worldX, closeTo(1.1, 0.0001));
    expect(frame.landmarkByIndex(11)!.worldY, closeTo(-0.55, 0.0001));
    expect(frame.landmarkByIndex(11)!.worldZ, closeTo(0.22, 0.0001));
    expect(frame.landmarkByIndex(11)!.worldVisibility, closeTo(0.755, 0.0001));
    expect(frame.landmarkByIndex(11)!.worldPresence, closeTo(0.705, 0.0001));
    expect(frame.landmarkByIndex(11)!.worldConfidence, closeTo(0.735, 0.0001));
    expect(frame.landmarkByIndex(32)!.confidence, 1);
    final serializedLandmarks =
        (frame.toMap()['landmarks']! as List<Object?>).cast<Map>();
    expect(serializedLandmarks, hasLength(mediaPipePoseLandmarkCount));
    expect(serializedLandmarks[32]['worldX'], closeTo(3.2, 0.0001));
  });

  test('preview pose result parses bounded payload without coaching fields',
      () {
    final preview = RunningVideoPosePreviewResult.fromMap({
      'durationMs': 4000,
      'sampledFrames': 4,
      'validFrames': 2,
      'poseFrames': [
        _poseFrameMap(timestampMs: 1000, imageWidth: 640, imageHeight: 360),
        _poseFrameMap(timestampMs: 0, imageWidth: 640, imageHeight: 360),
      ],
      'perspectiveQuality': {
        'evaluatedFrameCount': 2,
        'medianBodyScaleRatio': 0.22,
        'minBodyScaleRatio': 0.18,
        'visibilityCoverage': 0.75,
        'sideViewScore': 0.64,
        'scaleDriftRatio': 0.08,
        'cutOffFrameRatio': 0.1,
        'issues': ['bodyCutOff'],
      },
      'metricQualities': {
        'posture': {'confidence': 1, 'sampleCount': 2},
      },
      'contactWindows': [
        {'centerTimestampMs': 500},
      ],
    });

    expect(preview.videoDuration, const Duration(seconds: 4));
    expect(preview.validFrameCoverage, 0.5);
    expect(preview.poseFrames.map((frame) => frame.timestampMs), [0, 1000]);
    expect(
      preview.perspectiveQuality.issues,
      contains(RunningVideoQualityIssue.bodyCutOff),
    );
    final serialized = preview.toMap();
    expect(serialized.containsKey('metricQualities'), isFalse);
    expect(serialized.containsKey('contactWindows'), isFalse);
  });

  test('fromMap parses dense contact contract immutably', () {
    final result = RunningVideoAnalysisResult.fromMap({
      'durationMs': 3200,
      'sampledFrames': 14,
      'validFrames': 11,
      'direction': 'leftToRight',
      'forwardLeanDegrees': 10,
      'verticalBounceRatio': 0.06,
      'footStrikeDistanceRatio': 0.09,
      'stanceKneeAngleDegrees': 154,
      'elbowAngleDegrees': 92,
      'coarseSamples': {
        'attemptedFrames': 14,
        'validFrames': 11,
        'poseFrameCount': 11,
      },
      'denseSamples': {
        'attemptedFrames': 18,
        'validFrames': 16,
        'poseFrameCount': 16,
        'maxFrameBudget': 48,
        'targetFps': 30,
      },
      'contactWindows': [
        {
          'side': 'right',
          'startTimestampMs': 900,
          'centerTimestampMs': 1030,
          'endTimestampMs': 1190,
          'denseSampleCount': 9,
          'candidateFrameCount': 7,
          'rejectedFrameCounts': {
            'unstable_foot_motion': 4,
            'outside_ground_band': 2,
          },
          'validatedContactFrameTimestampsMs': [1033, 1033],
          'confidence': 0.82,
        },
        {
          'side': 'left',
          'startTimestampMs': 1400,
          'centerTimestampMs': 1560,
          'endTimestampMs': 1740,
          'denseSampleCount': 9,
          'validatedContactFrameTimestampsMs': [1560],
          'confidence': 0.84,
        },
        {
          'side': 'right',
          'startTimestampMs': 1780,
          'centerTimestampMs': 1930,
          'endTimestampMs': 2100,
          'denseSampleCount': 8,
          'validatedContactFrameTimestampsMs': [1933],
          'confidence': 0.83,
        },
      ],
      'validatedContactFrameTimestampsMs': [1560, 1033, 1033, 1933],
      'contactConfidence': 0.81,
      'metricQualities': {
        'footStrike': {'confidence': 0.82, 'sampleCount': 3},
        'kneeFlexion': {'confidence': 0.80, 'sampleCount': 3},
      },
      'poseFrames': [
        _poseFrameMap(timestampMs: 1033, imageWidth: 640, imageHeight: 360),
        _poseFrameMap(timestampMs: 1000, imageWidth: 640, imageHeight: 360),
        _poseFrameMap(timestampMs: 1033, imageWidth: 1280, imageHeight: 720),
        _poseFrameMap(timestampMs: 1560, imageWidth: 640, imageHeight: 360),
        _poseFrameMap(timestampMs: 1933, imageWidth: 640, imageHeight: 360),
      ],
    });

    expect(result.hasDenseContactEvidence, isTrue);
    expect(result.denseSamples.attemptedFrames, 18);
    expect(result.denseSamples.maxFrameBudget, 48);
    expect(result.denseSamples.targetFps, 30);
    expect(result.contactWindows, hasLength(3));
    expect(result.contactWindows.first.side, RunningContactSide.right);
    expect(result.contactWindows.first.candidateFrameCount, 7);
    expect(
      result.contactWindows.first.primaryRejectedFrameReason,
      'unstable_foot_motion',
    );
    expect(result.contactCandidateFrameCount, 7);
    expect(result.primaryContactRejectionReason, 'unstable_foot_motion');
    expect(
      result.contactWindows.first.validatedContactTimestamps
          .map((timestamp) => timestamp.inMilliseconds),
      [1033],
    );
    expect(
      result.contactWindows[1].validatedContactTimestamps
          .map((timestamp) => timestamp.inMilliseconds),
      [1560],
    );
    expect(
      result.validatedContactFrameTimestamps
          .map((timestamp) => timestamp.inMilliseconds),
      [1033, 1560, 1933],
    );
    expect(
      result.validatedContactFrameTimestamps.length,
      lessThanOrEqualTo(result.contactWindows.length),
    );
    expect(result.contactConfidence, closeTo(0.81, 0.0001));
    expect(
      result.qualityFor(RunningCoachMetric.footStrike)!.confidence,
      closeTo(0.82, 0.0001),
    );
    expect(
      result.poseFrames.map((frame) => frame.timestampMs),
      [1000, 1033, 1560, 1933],
    );
    expect(result.poseFrames[1].imageWidth, 1280);
    expect(
      result.nearestValidatedContactTimestamp(
        const Duration(milliseconds: 1050),
      ),
      const Duration(milliseconds: 1033),
    );
    expect(
      result.nearestValidatedContactTimestamp(
        const Duration(milliseconds: 1400),
      ),
      isNull,
    );
    expect(
      () => result.validatedContactFrameTimestamps.add(Duration.zero),
      throwsUnsupportedError,
    );
    expect(
      () => result.contactWindows.add(
        const RunningContactWindow(
          start: Duration.zero,
          center: Duration.zero,
          end: Duration.zero,
          side: RunningContactSide.unknown,
          denseSampleCount: 0,
          validatedContactTimestamps: <Duration>[],
          confidence: 0,
        ),
      ),
      throwsUnsupportedError,
    );
  });

  test('explicit v2 contact contract preserves strict and estimated contacts',
      () {
    final result = RunningVideoAnalysisResult.fromMap({
      'analysisVersion': 2,
      'durationMs': 2000,
      'sampledFrames': 12,
      'validFrames': 10,
      'metricQualities': {
        'footStrike': {
          'confidence': 0.7,
          'sampleCount': 4,
          'reason': 'kinematic_contact_estimate',
        },
      },
      'validatedContactFrameTimestampsMs': [400],
      'estimatedContactFrameTimestampsMs': [800],
      'contactWindows': [
        {
          'startTimestampMs': 300,
          'centerTimestampMs': 400,
          'endTimestampMs': 500,
          'side': 'left',
          'denseSampleCount': 5,
          'validatedContactFrameTimestampsMs': [400],
          'estimatedContactFrameTimestampsMs': <int>[],
          'selectionMethod': 'ground',
          'confidence': 0.8,
        },
        {
          'startTimestampMs': 700,
          'centerTimestampMs': 800,
          'endTimestampMs': 900,
          'side': 'right',
          'denseSampleCount': 5,
          'validatedContactFrameTimestampsMs': <int>[],
          'estimatedContactFrameTimestampsMs': [800],
          'selectionMethod': 'kinematic',
          'confidence': 0.5,
        },
      ],
    });

    expect(result.validatedContactFrameTimestamps,
        const <Duration>[Duration(milliseconds: 400)]);
    expect(result.estimatedContactFrameTimestamps,
        const <Duration>[Duration(milliseconds: 800)]);
    expect(result.contactWindows.first.selectionMethod, 'ground');
    expect(result.contactWindows.last.selectionMethod, 'kinematic');
  });

  test('early v2 kinematic history is demoted on load', () {
    final result = RunningVideoAnalysisResult.fromMap({
      'analysisVersion': 2,
      'durationMs': 2000,
      'sampledFrames': 12,
      'validFrames': 10,
      'metricQualities': {
        'footStrike': {
          'confidence': 0.82,
          'sampleCount': 3,
          'reason': 'kinematic_contact_estimate',
        },
      },
      'validatedContactFrameTimestampsMs': [400, 800, 1200],
      'contactWindows': [
        {
          'startTimestampMs': 300,
          'centerTimestampMs': 400,
          'endTimestampMs': 500,
          'side': 'left',
          'denseSampleCount': 5,
          'validatedContactFrameTimestampsMs': [400],
          'confidence': 0.82,
        },
      ],
      'measurements': [
        {
          'metric': 'cadence',
          'state': 'confirmed',
          'value': 176,
          'confidence': 0.82,
          'sampleCount': 3,
          'method': 'validated_contacts',
          'evidenceTimestampsMs': [400, 800, 1200],
        },
      ],
    });

    expect(result.validatedContactFrameTimestamps, isEmpty);
    expect(result.estimatedContactFrameTimestamps, const <Duration>[
      Duration(milliseconds: 400),
      Duration(milliseconds: 800),
      Duration(milliseconds: 1200),
    ]);
    expect(result.contactWindows.single.validatedContactTimestamps, isEmpty);
    expect(result.contactWindows.single.selectionMethod, 'kinematic');
    expect(
      result.measurementFor(RunningAnalysisMetric.cadence).state,
      RunningMeasurementState.estimated,
    );
  });

  test('fromMap parses perspective quality limitations and metric gates', () {
    final result = RunningVideoAnalysisResult.fromMap({
      'durationMs': 60000,
      'sampledFrames': 481,
      'validFrames': 430,
      'direction': 'leftToRight',
      'forwardLeanDegrees': 10,
      'verticalBounceRatio': 0.06,
      'footStrikeDistanceRatio': 0.10,
      'stanceKneeAngleDegrees': 154,
      'elbowAngleDegrees': 92,
      'perspectiveQuality': {
        'evaluatedFrameCount': 430,
        'medianBodyScaleRatio': 0.08,
        'minBodyScaleRatio': 0.05,
        'visibilityCoverage': 0.88,
        'sideViewScore': 0.44,
        'scaleDriftRatio': 1.8,
        'cutOffFrameRatio': 0.12,
        'issues': [
          'too_small_runner',
          'not_side_on',
          'scale_drift',
          'bodyCutOff',
          'not_side_on',
        ],
      },
      'metricQualities': {
        'footStrike': {'confidence': 0.9, 'sampleCount': 5},
      },
    });

    expect(result.sampledFrames, 481);
    expect(result.videoDuration, const Duration(seconds: 60));
    expect(result.perspectiveQuality.evaluatedFrameCount, 430);
    expect(result.perspectiveQuality.issues, <RunningVideoQualityIssue>[
      RunningVideoQualityIssue.tooSmall,
      RunningVideoQualityIssue.notSideOn,
      RunningVideoQualityIssue.scaleDrift,
      RunningVideoQualityIssue.bodyCutOff,
    ]);
    expect(result.perspectiveQuality.primaryReasonCode, 'too_small_runner');
    expect(
      result.perspectiveQuality.limitationReasonForMetric(
        RunningCoachMetric.footStrike,
      ),
      'too_small_runner',
    );
    expect(
      result.evidenceForMetric(RunningCoachMetric.footStrike)!.reliability,
      closeTo(0.55, 0.0001),
    );
  });

  test('perspective fixtures gate small diagonal drift and valid side-on cases',
      () {
    const smallRunner = RunningVideoPerspectiveQuality(
      evaluatedFrameCount: 120,
      medianBodyScaleRatio: 0.08,
      minBodyScaleRatio: 0.06,
      visibilityCoverage: 0.9,
      sideViewScore: 0.9,
      scaleDriftRatio: 1,
      cutOffFrameRatio: 0,
      issues: <RunningVideoQualityIssue>[RunningVideoQualityIssue.tooSmall],
    );
    const diagonalView = RunningVideoPerspectiveQuality(
      evaluatedFrameCount: 120,
      medianBodyScaleRatio: 0.22,
      minBodyScaleRatio: 0.20,
      visibilityCoverage: 0.9,
      sideViewScore: 0.42,
      scaleDriftRatio: 1,
      cutOffFrameRatio: 0,
      issues: <RunningVideoQualityIssue>[RunningVideoQualityIssue.notSideOn],
    );
    const scaleDrift = RunningVideoPerspectiveQuality(
      evaluatedFrameCount: 120,
      medianBodyScaleRatio: 0.22,
      minBodyScaleRatio: 0.18,
      visibilityCoverage: 0.9,
      sideViewScore: 0.85,
      scaleDriftRatio: 1.7,
      cutOffFrameRatio: 0,
      issues: <RunningVideoQualityIssue>[RunningVideoQualityIssue.scaleDrift],
    );
    const validSideOn = RunningVideoPerspectiveQuality(
      evaluatedFrameCount: 120,
      medianBodyScaleRatio: 0.22,
      minBodyScaleRatio: 0.20,
      visibilityCoverage: 0.94,
      sideViewScore: 0.9,
      scaleDriftRatio: 1.04,
      cutOffFrameRatio: 0.01,
    );

    expect(
      smallRunner.limitationReasonForMetric(RunningCoachMetric.armCarriage),
      'too_small_runner',
    );
    expect(
      diagonalView.limitationReasonForMetric(RunningCoachMetric.footStrike),
      'not_side_on',
    );
    expect(
      diagonalView.limitationReasonForMetric(RunningCoachMetric.armCarriage),
      isNull,
    );
    expect(
      scaleDrift.limitationReasonForMetric(RunningCoachMetric.bounce),
      'scale_drift',
    );
    expect(validSideOn.hasLimitations, isFalse);
    expect(
      validSideOn.limitationReasonForMetric(RunningCoachMetric.footStrike),
      isNull,
    );
  });

  test('history snapshot keeps the beginning, end, and contact frames', () {
    final result = RunningVideoAnalysisResult.fromMap({
      'durationMs': 4000,
      'sampledFrames': 40,
      'validFrames': 40,
      'direction': 'leftToRight',
      'forwardLeanDegrees': 10,
      'verticalBounceRatio': 0.06,
      'footStrikeDistanceRatio': 0.10,
      'stanceKneeAngleDegrees': 152,
      'elbowAngleDegrees': 94,
      'poseFrames': [
        for (var frameIndex = 0; frameIndex < 40; frameIndex += 1)
          _poseFrameMap(
            timestampMs: frameIndex * 100,
            imageWidth: 720,
            imageHeight: 1280,
          ),
      ],
      'validatedContactFrameTimestampsMs': [300, 1900, 3900],
    });

    final snapshot = result.historySnapshot();
    final timestamps = snapshot.poseFrames
        .map((frame) => frame.timestamp.inMilliseconds)
        .toList(growable: false);

    expect(snapshot.poseFrames.length, lessThanOrEqualTo(24));
    expect(
      timestamps,
      containsAll(<int>[0, 200, 300, 400, 500, 1800, 1900, 2000, 2100, 3900]),
    );
    expect(snapshot.validatedContactFrameTimestamps,
        result.validatedContactFrameTimestamps);
  });

  test('history snapshot keeps selected evidence-frame timestamps', () {
    final result = RunningVideoAnalysisResult.fromMap({
      'durationMs': 4000,
      'sampledFrames': 40,
      'validFrames': 40,
      'direction': 'leftToRight',
      'forwardLeanDegrees': 10,
      'verticalBounceRatio': 0.06,
      'footStrikeDistanceRatio': 0.10,
      'stanceKneeAngleDegrees': 152,
      'elbowAngleDegrees': 94,
      'poseFrames': [
        for (var frameIndex = 0; frameIndex < 40; frameIndex += 1)
          _poseFrameMap(
            timestampMs: frameIndex * 100,
            imageWidth: 720,
            imageHeight: 1280,
          ),
      ],
      'validatedContactFrameTimestampsMs': [300],
    });

    final snapshot = result.historySnapshot(
      maxPoseFrames: 5,
      evidenceTimestamps: const <Duration>[Duration(milliseconds: 2900)],
    );

    expect(
      snapshot.poseFrames.map((frame) => frame.timestamp.inMilliseconds),
      contains(2900),
    );
  });

  test('requires three fresh samples before a metric can guide coaching', () {
    const legacy = RunningMetricQuality(confidence: 0.90, sampleCount: 0);
    const sparse = RunningMetricQuality(confidence: 0.90, sampleCount: 2);
    const sufficient = RunningMetricQuality(confidence: 0.90, sampleCount: 3);
    const proxy = RunningMetricQuality(
      confidence: 0.90,
      sampleCount: 3,
      reason: 'contact_phase_proxy',
    );
    const kinematicEstimate = RunningMetricQuality(
      confidence: 0.74,
      sampleCount: 3,
      reason: 'kinematic_contact_estimate',
    );

    expect(legacy.isReliableForCoaching, isTrue);
    expect(sparse.isReliableForCoaching, isFalse);
    expect(sufficient.isReliableForCoaching, isTrue);
    expect(proxy.isReliableForCoaching, isFalse);
    expect(kinematicEstimate.isReliableForCoaching, isFalse);
    expect(
      const RunningMetricQuality(
        confidence: 0.90,
        sampleCount: 3,
        reason: 'missing_contact_evidence',
      ).isReliableForCoaching,
      isFalse,
    );
  });

  test('derives step, side, and phase measurements only from contacts', () {
    const contactTimes = <int>[600, 900, 1200, 1500, 1800, 2100];
    final frames = <RunningPoseFrame>[
      for (var index = 0; index < contactTimes.length; index += 1) ...[
        _gaitPoseFrame(
          timestampMs: contactTimes[index],
          side:
              index.isEven ? RunningContactSide.left : RunningContactSide.right,
          flexed: false,
        ),
        _gaitPoseFrame(
          timestampMs: contactTimes[index] + 80,
          side:
              index.isEven ? RunningContactSide.left : RunningContactSide.right,
          flexed: true,
        ),
      ],
    ];
    final result = RunningVideoAnalysisResult(
      videoDuration: const Duration(seconds: 3),
      sampledFrames: 14,
      validFrames: 12,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 10,
      verticalBounceRatio: 0.06,
      footStrikeDistanceRatio: 0.10,
      stanceKneeAngleDegrees: 154,
      elbowAngleDegrees: 90,
      poseFrames: frames,
      denseSamples: const RunningAnalysisSampleSummary(
        attemptedFrames: 12,
        validFrames: 12,
        poseFrameCount: 12,
        targetFps: 30,
      ),
      contactWindows: [
        for (var index = 0; index < contactTimes.length; index += 1)
          RunningContactWindow(
            start: Duration(milliseconds: contactTimes[index] - 80),
            center: Duration(milliseconds: contactTimes[index]),
            end: Duration(milliseconds: contactTimes[index] + 160),
            side: index.isEven
                ? RunningContactSide.left
                : RunningContactSide.right,
            denseSampleCount: 5,
            validatedContactTimestamps: [
              Duration(milliseconds: contactTimes[index]),
            ],
            confidence: 0.92,
          ),
      ],
      validatedContactFrameTimestamps: const <Duration>[
        Duration(milliseconds: 600),
        Duration(milliseconds: 900),
        Duration(milliseconds: 1200),
        Duration(milliseconds: 1500),
        Duration(milliseconds: 1800),
        Duration(milliseconds: 2100),
      ],
      contactConfidence: 0.92,
    );

    final gait = result.gaitAnalysis;

    expect(gait, isNotNull);
    expect(gait!.steps, hasLength(6));
    expect(gait.reliableStepCount, 6);
    expect(gait.hasReliableStepSample, isTrue);
    expect(gait.hasBilateralSample, isTrue);
    expect(gait.cadenceSpm, closeTo(200, 0.1));
    expect(gait.medianStepTimeMs, 300);
    expect(gait.leftRightStepTimeAsymmetryPercent, closeTo(0, 0.001));
    expect(gait.footStrikeDistance, isNotNull);
    expect(gait.kneeAtContact, isNotNull);
    expect(gait.minimumKneeFlexion, isNotNull);
    expect(
      gait.minimumKneeFlexion!.median,
      lessThan(gait.kneeAtContact!.median),
    );
    expect(gait.steps.first.preContact, isNull);
    expect(gait.steps.first.maximumKneeFlexion, isNotNull);
    expect(gait.steps.first.contactExit, isNotNull);
  });

  test('overlapping empty windows cannot claim another side contact', () {
    const contactTimes = <int>[600, 900, 1200];
    final result = RunningVideoAnalysisResult(
      videoDuration: const Duration(seconds: 2),
      sampledFrames: 12,
      validFrames: 9,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 10,
      verticalBounceRatio: 0.06,
      footStrikeDistanceRatio: 0.10,
      stanceKneeAngleDegrees: 154,
      elbowAngleDegrees: 90,
      poseFrames: <RunningPoseFrame>[
        for (var index = 0; index < contactTimes.length; index += 1)
          _gaitPoseFrame(
            timestampMs: contactTimes[index],
            side: index.isEven
                ? RunningContactSide.left
                : RunningContactSide.right,
            flexed: false,
          ),
      ],
      denseSamples: const RunningAnalysisSampleSummary(
        attemptedFrames: 9,
        validFrames: 9,
        poseFrameCount: 3,
        targetFps: 30,
      ),
      contactWindows: <RunningContactWindow>[
        const RunningContactWindow(
          start: Duration(milliseconds: 300),
          center: Duration(milliseconds: 590),
          end: Duration(milliseconds: 1400),
          side: RunningContactSide.right,
          denseSampleCount: 9,
          validatedContactTimestamps: <Duration>[],
          confidence: 0,
        ),
        for (var index = 0; index < contactTimes.length; index += 1)
          RunningContactWindow(
            start: Duration(milliseconds: contactTimes[index] - 500),
            center: Duration(milliseconds: contactTimes[index]),
            end: Duration(milliseconds: contactTimes[index] + 500),
            side: index.isEven
                ? RunningContactSide.left
                : RunningContactSide.right,
            denseSampleCount: 9,
            validatedContactTimestamps: <Duration>[
              Duration(milliseconds: contactTimes[index]),
            ],
            confidence: 0.92,
          ),
      ],
      validatedContactFrameTimestamps: const <Duration>[
        Duration(milliseconds: 600),
        Duration(milliseconds: 900),
        Duration(milliseconds: 1200),
      ],
      contactConfidence: 0.92,
    );

    expect(
      result.gaitAnalysis!.steps.map((step) => step.side),
      <RunningContactSide>[
        RunningContactSide.left,
        RunningContactSide.right,
        RunningContactSide.left,
      ],
    );
    expect(
      result.rhythmAnalysis!.contacts.map((contact) => contact.side),
      <RunningContactSide>[
        RunningContactSide.left,
        RunningContactSide.right,
        RunningContactSide.left,
      ],
    );
  });

  test('keeps verified rhythm available when pose pairing is unavailable', () {
    const contactTimes = <int>[600, 900, 1200, 1500, 1800, 2100];
    final result = RunningVideoAnalysisResult(
      videoDuration: const Duration(seconds: 3),
      sampledFrames: 14,
      validFrames: 12,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 10,
      verticalBounceRatio: 0.06,
      footStrikeDistanceRatio: 0.10,
      stanceKneeAngleDegrees: 154,
      elbowAngleDegrees: 90,
      denseSamples: const RunningAnalysisSampleSummary(
        attemptedFrames: 12,
        validFrames: 12,
        poseFrameCount: 0,
        targetFps: 30,
      ),
      contactWindows: [
        for (var index = 0; index < contactTimes.length; index += 1)
          RunningContactWindow(
            start: Duration(milliseconds: contactTimes[index] - 80),
            center: Duration(milliseconds: contactTimes[index]),
            end: Duration(milliseconds: contactTimes[index] + 160),
            side: index.isEven
                ? RunningContactSide.left
                : RunningContactSide.right,
            denseSampleCount: 5,
            validatedContactTimestamps: [
              Duration(milliseconds: contactTimes[index]),
            ],
            confidence: 0.92,
          ),
      ],
      validatedContactFrameTimestamps: const <Duration>[
        Duration(milliseconds: 600),
        Duration(milliseconds: 900),
        Duration(milliseconds: 1200),
        Duration(milliseconds: 1500),
        Duration(milliseconds: 1800),
        Duration(milliseconds: 2100),
      ],
      contactConfidence: 0.92,
    );

    final rhythm = result.rhythmAnalysis;

    expect(result.gaitAnalysis, isNull);
    expect(rhythm, isNotNull);
    expect(rhythm!.hasReliableSample, isTrue);
    expect(rhythm.hasBilateralSample, isTrue);
    expect(rhythm.cadenceSpm, closeTo(200, 0.1));
    expect(rhythm.medianStepTimeMs, 300);
    expect(rhythm.leftRightStepTimeAsymmetryPercent, closeTo(0, 0.001));
  });

  test('derives per-metric evidence from measured frames and phases', () {
    const contactTimes = <int>[600, 900, 1200];
    final result = RunningVideoAnalysisResult(
      videoDuration: const Duration(seconds: 3),
      sampledFrames: 16,
      validFrames: 14,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 10,
      verticalBounceRatio: 0.09,
      footStrikeDistanceRatio: 0.10,
      stanceKneeAngleDegrees: 132,
      elbowAngleDegrees: 118,
      metricQualities: const <RunningCoachMetric, RunningMetricQuality>{
        RunningCoachMetric.posture: RunningMetricQuality(
          confidence: 0.90,
          sampleCount: 6,
        ),
        RunningCoachMetric.bounce: RunningMetricQuality(
          confidence: 0.88,
          sampleCount: 6,
        ),
        RunningCoachMetric.footStrike: RunningMetricQuality(
          confidence: 0.91,
          sampleCount: 3,
        ),
        RunningCoachMetric.kneeFlexion: RunningMetricQuality(
          confidence: 0.91,
          sampleCount: 3,
        ),
        RunningCoachMetric.armCarriage: RunningMetricQuality(
          confidence: 0.89,
          sampleCount: 6,
        ),
      },
      poseFrames: [
        _evidencePoseFrame(
          timestampMs: 0,
          leanDegrees: 5,
          hipY: 0.54,
          elbowAngleDegrees: 82,
        ),
        _evidencePoseFrame(
          timestampMs: 100,
          leanDegrees: 10,
          hipY: 0.42,
          elbowAngleDegrees: 118,
        ),
        _evidencePoseFrame(
          timestampMs: 200,
          leanDegrees: 14,
          hipY: 0.50,
          elbowAngleDegrees: 132,
        ),
        _evidencePoseFrame(
          timestampMs: 300,
          leanDegrees: 12,
          hipY: 0.64,
          elbowAngleDegrees: 64,
        ),
        _evidencePoseFrame(
          timestampMs: 400,
          leanDegrees: 8,
          hipY: 0.56,
          elbowAngleDegrees: 96,
        ),
        for (var index = 0; index < contactTimes.length; index += 1) ...[
          _gaitPoseFrame(
            timestampMs: contactTimes[index],
            side: index.isEven
                ? RunningContactSide.left
                : RunningContactSide.right,
            flexed: false,
          ),
          _gaitPoseFrame(
            timestampMs: contactTimes[index] + 80,
            side: index.isEven
                ? RunningContactSide.left
                : RunningContactSide.right,
            flexed: true,
          ),
        ],
      ],
      denseSamples: const RunningAnalysisSampleSummary(
        attemptedFrames: 12,
        validFrames: 12,
        poseFrameCount: 12,
        targetFps: 30,
      ),
      contactWindows: [
        for (var index = 0; index < contactTimes.length; index += 1)
          RunningContactWindow(
            start: Duration(milliseconds: contactTimes[index] - 80),
            center: Duration(milliseconds: contactTimes[index]),
            end: Duration(milliseconds: contactTimes[index] + 160),
            side: index.isEven
                ? RunningContactSide.left
                : RunningContactSide.right,
            denseSampleCount: 5,
            validatedContactTimestamps: [
              Duration(milliseconds: contactTimes[index]),
            ],
            confidence: 0.92,
          ),
      ],
      validatedContactFrameTimestamps: const <Duration>[
        Duration(milliseconds: 600),
        Duration(milliseconds: 900),
        Duration(milliseconds: 1200),
      ],
      contactConfidence: 0.92,
    );

    final byKind = <RunningMetricEvidenceKind, RunningMetricEvidence>{
      for (final evidence in result.metricEvidence) evidence.kind: evidence,
    };

    expect(
        byKind[RunningMetricEvidenceKind.rhythm]!
            .frames
            .map((frame) => frame.timestampMs),
        [600, 900, 1200]);
    expect(
        byKind[RunningMetricEvidenceKind.posture]!
            .frames
            .map((frame) => frame.timestampMs),
        contains(100));
    expect(
      byKind[RunningMetricEvidenceKind.landing]!
          .frames
          .map((frame) => frame.role)
          .toSet(),
      containsAll(<RunningMetricEvidenceFrameRole>{
        RunningMetricEvidenceFrameRole.initialContact,
        RunningMetricEvidenceFrameRole.pushOff,
      }),
    );
    expect(
        byKind[RunningMetricEvidenceKind.landing]!
            .frames
            .map((frame) => frame.timestampMs),
        [600, 680]);
    expect(
      byKind[RunningMetricEvidenceKind.knee]!
          .frames
          .map((frame) => frame.role)
          .toSet(),
      containsAll(<RunningMetricEvidenceFrameRole>{
        RunningMetricEvidenceFrameRole.initialContact,
        RunningMetricEvidenceFrameRole.maximumKneeFlexion,
      }),
    );
    expect(
        byKind[RunningMetricEvidenceKind.knee]!
            .frames
            .map((frame) => frame.timestampMs),
        containsAll(<int>[600, 680]));
    expect(
      byKind[RunningMetricEvidenceKind.bounce]!
          .frames
          .map((frame) => frame.role)
          .toSet(),
      containsAll(<RunningMetricEvidenceFrameRole>{
        RunningMetricEvidenceFrameRole.trajectoryHigh,
        RunningMetricEvidenceFrameRole.trajectoryLow,
      }),
    );
    expect(
      byKind[RunningMetricEvidenceKind.arms]!
          .frames
          .map((frame) => frame.role)
          .toSet(),
      containsAll(<RunningMetricEvidenceFrameRole>{
        RunningMetricEvidenceFrameRole.armClosed,
        RunningMetricEvidenceFrameRole.armOpen,
      }),
    );
  });

  test('bounce trajectory is stable under screen translation and scale drift',
      () {
    final base = runningVerticalBounceRatioForPoseFrames(
      _perspectiveBounceFrames(),
    );
    final transformed = runningVerticalBounceRatioForPoseFrames(
      _perspectiveBounceFrames(
        xShift: 0.10,
        yShift: 0.05,
        scaleStart: 0.74,
        scaleEnd: 1.26,
      ),
    );

    expect(base, isNotNull);
    expect(transformed, isNotNull);
    expect(transformed!, closeTo(base!, 0.006));
  });

  test('bounce evidence ignores absolute hip y perspective drift', () {
    final frames = _perspectiveBounceFrames(
      yShift: 0.03,
      yDrift: 0.14,
      scaleStart: 0.78,
      scaleEnd: 1.22,
    );
    final result = RunningVideoAnalysisResult(
      videoDuration: const Duration(seconds: 3),
      sampledFrames: frames.length,
      validFrames: frames.length,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 10,
      verticalBounceRatio: runningVerticalBounceRatioForPoseFrames(frames) ?? 0,
      footStrikeDistanceRatio: 0.10,
      stanceKneeAngleDegrees: 154,
      elbowAngleDegrees: 90,
      metricQualities: const <RunningCoachMetric, RunningMetricQuality>{
        RunningCoachMetric.bounce: RunningMetricQuality(
          confidence: 0.90,
          sampleCount: 8,
        ),
      },
      poseFrames: frames,
    );

    final evidence = result.evidenceForMetric(RunningCoachMetric.bounce)!;
    final byRole = {
      for (final frame in evidence.frames) frame.role: frame.timestampMs,
    };

    expect(byRole[RunningMetricEvidenceFrameRole.trajectoryHigh], 1000);
    expect(byRole[RunningMetricEvidenceFrameRole.trajectoryLow], 600);
    expect(byRole.values, isNot(contains(0)));
    expect(byRole.values, isNot(contains(1100)));
  });

  test('keeps a single verified contact as an observed lower-body frame', () {
    final result = RunningVideoAnalysisResult(
      videoDuration: const Duration(seconds: 3),
      sampledFrames: 14,
      validFrames: 12,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 10,
      verticalBounceRatio: 0.06,
      footStrikeDistanceRatio: 0.10,
      stanceKneeAngleDegrees: 154,
      elbowAngleDegrees: 90,
      metricQualities: const <RunningCoachMetric, RunningMetricQuality>{
        RunningCoachMetric.footStrike: RunningMetricQuality(
          confidence: 0.92,
          sampleCount: 1,
        ),
        RunningCoachMetric.kneeFlexion: RunningMetricQuality(
          confidence: 0.92,
          sampleCount: 1,
        ),
      },
      poseFrames: <RunningPoseFrame>[
        _gaitPoseFrame(
          timestampMs: 600,
          side: RunningContactSide.left,
          flexed: false,
        ),
        _gaitPoseFrame(
          timestampMs: 680,
          side: RunningContactSide.left,
          flexed: true,
        ),
      ],
      denseSamples: const RunningAnalysisSampleSummary(
        attemptedFrames: 6,
        validFrames: 6,
        poseFrameCount: 6,
        targetFps: 30,
      ),
      contactWindows: <RunningContactWindow>[
        const RunningContactWindow(
          start: Duration(milliseconds: 520),
          center: Duration(milliseconds: 600),
          end: Duration(milliseconds: 760),
          side: RunningContactSide.left,
          denseSampleCount: 6,
          validatedContactTimestamps: <Duration>[
            Duration(milliseconds: 600),
          ],
          confidence: 0.92,
        ),
      ],
      validatedContactFrameTimestamps: const <Duration>[
        Duration(milliseconds: 600),
      ],
      contactConfidence: 0.92,
    );

    final gait = result.gaitAnalysis;
    final landing = result.evidenceForMetric(RunningCoachMetric.footStrike)!;
    final knee = result.evidenceForMetric(RunningCoachMetric.kneeFlexion)!;

    expect(result.hasObservedContactEvidence, isTrue);
    expect(result.hasDenseContactEvidence, isFalse);
    expect(gait, isNotNull);
    expect(gait!.steps, hasLength(1));
    expect(gait.hasReliableStepSample, isFalse);
    expect(landing.frames, hasLength(2));
    expect(knee.frames, hasLength(2));
    expect(
      landing.frames.map((frame) => frame.role),
      containsAll(<RunningMetricEvidenceFrameRole>[
        RunningMetricEvidenceFrameRole.initialContact,
        RunningMetricEvidenceFrameRole.pushOff,
      ]),
    );
    expect(
      knee.frames.map((frame) => frame.role),
      containsAll(<RunningMetricEvidenceFrameRole>[
        RunningMetricEvidenceFrameRole.initialContact,
        RunningMetricEvidenceFrameRole.maximumKneeFlexion,
      ]),
    );
    expect(
      landing.withheldReason,
      RunningMetricEvidenceWithheldReason.limitedSamples,
    );
    expect(
      knee.withheldReason,
      RunningMetricEvidenceWithheldReason.limitedSamples,
    );
    expect(landing.isReliable, isFalse);
    expect(knee.isReliable, isFalse);
  });

  test('withholds evidence for legacy summaries without saved pose frames', () {
    const result = RunningVideoAnalysisResult(
      videoDuration: Duration(seconds: 4),
      sampledFrames: 12,
      validFrames: 12,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 10,
      verticalBounceRatio: 0.06,
      footStrikeDistanceRatio: 0.10,
      stanceKneeAngleDegrees: 154,
      elbowAngleDegrees: 90,
      metricQualities: <RunningCoachMetric, RunningMetricQuality>{
        RunningCoachMetric.posture: RunningMetricQuality(
          confidence: 0.90,
          sampleCount: 8,
        ),
      },
    );

    final evidence = result.evidenceForMetric(RunningCoachMetric.posture)!;

    expect(evidence.isReliable, isFalse);
    expect(
      evidence.withheldReason,
      RunningMetricEvidenceWithheldReason.missingPoseFrames,
    );
    expect(evidence.frames, isEmpty);
  });
}

Map<String, Object?> _poseFrameMap({
  required int timestampMs,
  required int imageWidth,
  required int imageHeight,
}) {
  return {
    'timestampMs': timestampMs,
    'imageWidth': imageWidth,
    'imageHeight': imageHeight,
    'landmarks': [
      for (var index = 0; index < mediaPipePoseLandmarkCount; index += 1)
        _landmarkMap(index),
    ],
  };
}

RunningPoseFrame _gaitPoseFrame({
  required int timestampMs,
  required RunningContactSide side,
  required bool flexed,
}) {
  final landmarks = List<RunningVideoPoseLandmark>.generate(
    mediaPipePoseLandmarkCount,
    (index) => RunningVideoPoseLandmark(
      index: index,
      x: 0.45,
      y: 0.5,
      z: 0,
      visibility: 0.95,
      presence: 0.95,
      confidence: 0.95,
    ),
  );
  void setPoint(int index, double x, double y) {
    landmarks[index] = RunningVideoPoseLandmark(
      index: index,
      x: x,
      y: y,
      z: 0,
      visibility: 0.95,
      presence: 0.95,
      confidence: 0.95,
    );
  }

  setPoint(11, 0.40, 0.30);
  setPoint(12, 0.50, 0.30);
  setPoint(13, 0.37, 0.43);
  setPoint(14, 0.53, 0.43);
  setPoint(15, 0.34, 0.50);
  setPoint(16, 0.56, 0.50);
  setPoint(23, 0.40, 0.50);
  setPoint(24, 0.50, 0.50);
  setPoint(27, 0.48, 0.80);
  setPoint(28, 0.42, 0.80);
  if (side == RunningContactSide.left) {
    setPoint(25, flexed ? 0.56 : 0.44, 0.65);
  } else {
    setPoint(28, 0.48, 0.80);
    setPoint(26, flexed ? 0.40 : 0.52, 0.65);
  }
  return RunningPoseFrame(
    timestamp: Duration(milliseconds: timestampMs),
    imageWidth: 720,
    imageHeight: 1280,
    landmarks: List<RunningVideoPoseLandmark>.unmodifiable(landmarks),
  );
}

RunningPoseFrame _evidencePoseFrame({
  required int timestampMs,
  required double leanDegrees,
  required double hipY,
  required double elbowAngleDegrees,
}) {
  final landmarks = List<RunningVideoPoseLandmark>.generate(
    mediaPipePoseLandmarkCount,
    (index) => RunningVideoPoseLandmark(
      index: index,
      x: 0.45,
      y: 0.5,
      z: 0,
      visibility: 0.95,
      presence: 0.95,
      confidence: 0.95,
    ),
  );
  void setPoint(int index, double x, double y) {
    landmarks[index] = RunningVideoPoseLandmark(
      index: index,
      x: x,
      y: y,
      z: 0,
      visibility: 0.95,
      presence: 0.95,
      confidence: 0.95,
    );
  }

  const hipX = 0.45;
  const torsoHeight = 0.24;
  final shoulderX = hipX + math.tan(leanDegrees * math.pi / 180) * torsoHeight;
  final shoulderY = hipY - torsoHeight;
  setPoint(11, shoulderX - 0.04, shoulderY);
  setPoint(12, shoulderX + 0.04, shoulderY);
  setPoint(23, hipX - 0.04, hipY);
  setPoint(24, hipX + 0.04, hipY);
  setPoint(25, hipX - 0.02, hipY + 0.15);
  setPoint(26, hipX + 0.02, hipY + 0.15);
  setPoint(27, hipX + 0.05, 0.82);
  setPoint(28, hipX + 0.07, 0.82);
  setPoint(29, hipX + 0.03, 0.83);
  setPoint(30, hipX + 0.05, 0.83);
  setPoint(31, hipX + 0.09, 0.83);
  setPoint(32, hipX + 0.11, 0.83);

  void setArm(int shoulder, int elbow, int wrist, double side) {
    final shoulderPoint = landmarks[shoulder];
    final elbowX = shoulderPoint.x + side * 0.03;
    final elbowY = shoulderPoint.y + 0.13;
    final radians = (-math.pi / 2) + (elbowAngleDegrees * math.pi / 180);
    final wristX = elbowX + math.cos(radians) * 0.13 * side;
    final wristY = elbowY + math.sin(radians) * 0.13;
    setPoint(elbow, elbowX, elbowY);
    setPoint(wrist, wristX, wristY);
  }

  setArm(11, 13, 15, -1);
  setArm(12, 14, 16, 1);
  return RunningPoseFrame(
    timestamp: Duration(milliseconds: timestampMs),
    imageWidth: 720,
    imageHeight: 1280,
    landmarks: List<RunningVideoPoseLandmark>.unmodifiable(landmarks),
  );
}

List<RunningPoseFrame> _perspectiveBounceFrames({
  double xShift = 0,
  double yShift = 0,
  double yDrift = 0,
  double scaleStart = 1,
  double scaleEnd = 1,
}) {
  const wave = <double>[
    0.00,
    0.02,
    0.05,
    0.02,
    0.00,
    -0.02,
    -0.05,
    -0.02,
    0.00,
    0.02,
    0.05,
    0.02,
  ];
  return <RunningPoseFrame>[
    for (var index = 0; index < wave.length; index += 1)
      _perspectiveBounceFrame(
        timestampMs: index * 100,
        xShift: xShift,
        yShift: yShift + (yDrift * index / (wave.length - 1)),
        scale:
            scaleStart + ((scaleEnd - scaleStart) * index / (wave.length - 1)),
        clearanceOffset: wave[index],
      ),
  ];
}

RunningPoseFrame _perspectiveBounceFrame({
  required int timestampMs,
  required double xShift,
  required double yShift,
  required double scale,
  required double clearanceOffset,
}) {
  final landmarks = List<RunningVideoPoseLandmark>.generate(
    mediaPipePoseLandmarkCount,
    (index) => RunningVideoPoseLandmark(
      index: index,
      x: 0.45,
      y: 0.50,
      z: 0,
      visibility: 0.95,
      presence: 0.95,
      confidence: 0.95,
    ),
  );
  void setPoint(int index, double x, double y) {
    landmarks[index] = RunningVideoPoseLandmark(
      index: index,
      x: x,
      y: y,
      z: 0,
      visibility: 0.95,
      presence: 0.95,
      confidence: 0.95,
    );
  }

  final progress = timestampMs / 1100;
  final hipX = 0.42 + xShift + (progress * 0.12);
  final groundY = 0.86 + yShift;
  final torso = 0.18 * scale;
  final clearance = torso * (1.72 + clearanceOffset);
  final hipY = groundY - clearance;
  final shoulderY = hipY - torso;
  setPoint(11, hipX - (0.05 * scale), shoulderY);
  setPoint(12, hipX + (0.05 * scale), shoulderY);
  setPoint(23, hipX - (0.04 * scale), hipY);
  setPoint(24, hipX + (0.04 * scale), hipY);
  setPoint(25, hipX - (0.03 * scale), hipY + (0.15 * scale));
  setPoint(26, hipX + (0.03 * scale), hipY + (0.15 * scale));
  setPoint(27, hipX - (0.05 * scale), groundY - (0.01 * scale));
  setPoint(28, hipX + (0.05 * scale), groundY - (0.015 * scale));
  setPoint(29, hipX - (0.07 * scale), groundY);
  setPoint(30, hipX + (0.03 * scale), groundY);
  setPoint(31, hipX - (0.02 * scale), groundY);
  setPoint(32, hipX + (0.08 * scale), groundY);
  return RunningPoseFrame(
    timestamp: Duration(milliseconds: timestampMs),
    imageWidth: 1000,
    imageHeight: 1000,
    landmarks: List<RunningVideoPoseLandmark>.unmodifiable(landmarks),
  );
}

Map<String, Object?> _landmarkMap(int index) {
  return {
    'index': index,
    'x': 0.10 + (index * 0.01),
    'y': 0.20 + (index * 0.01),
    'z': -0.01 * index,
    'visibility': 0.60 + (index * 0.01),
    'presence': 0.50 + (index * 0.01),
    'confidence': 0.40 + (index * 0.03),
    'worldX': index * 0.10,
    'worldY': index * -0.05,
    'worldZ': index * 0.02,
    'worldVisibility': 0.70 + (index * 0.005),
    'worldPresence': 0.65 + (index * 0.005),
    'worldConfidence': 0.68 + (index * 0.005),
  };
}
