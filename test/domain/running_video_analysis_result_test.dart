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
    expect(timestamps, containsAll(<int>[0, 300, 1900, 3900]));
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
