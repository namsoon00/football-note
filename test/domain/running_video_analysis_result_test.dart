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

  test('requires three fresh samples before a metric can guide coaching', () {
    const legacy = RunningMetricQuality(confidence: 0.90, sampleCount: 0);
    const sparse = RunningMetricQuality(confidence: 0.90, sampleCount: 2);
    const sufficient = RunningMetricQuality(confidence: 0.90, sampleCount: 3);
    const proxy = RunningMetricQuality(
      confidence: 0.90,
      sampleCount: 3,
      reason: 'contact_phase_proxy',
    );

    expect(legacy.isReliableForCoaching, isTrue);
    expect(sparse.isReliableForCoaching, isFalse);
    expect(sufficient.isReliableForCoaching, isTrue);
    expect(proxy.isReliableForCoaching, isFalse);
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
      {RunningMetricEvidenceFrameRole.initialContact},
    );
    expect(
        byKind[RunningMetricEvidenceKind.landing]!
            .frames
            .map((frame) => frame.timestampMs),
        [600, 900, 1200]);
    expect(
      byKind[RunningMetricEvidenceKind.knee]!
          .frames
          .map((frame) => frame.role)
          .toSet(),
      {RunningMetricEvidenceFrameRole.maximumKneeFlexion},
    );
    expect(
        byKind[RunningMetricEvidenceKind.knee]!
            .frames
            .map((frame) => frame.timestampMs),
        [680, 980, 1280]);
    expect(
      {
        for (final frame in byKind[RunningMetricEvidenceKind.bounce]!.frames)
          frame.role: frame.timestampMs,
      },
      {
        RunningMetricEvidenceFrameRole.trajectoryHigh: 100,
        RunningMetricEvidenceFrameRole.trajectoryLow: 300,
      },
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
  setPoint(27, hipX + 0.05, hipY + 0.31);
  setPoint(28, hipX + 0.07, hipY + 0.31);

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
