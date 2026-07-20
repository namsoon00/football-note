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
    expect(frame.landmarkByIndex(32)!.confidence, 1);
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
          'validatedContactFrameTimestampsMs': [1066, 1033, 1033],
          'confidence': 0.82,
        },
      ],
      'validatedContactFrameTimestampsMs': [1066, 1033, 1066],
      'contactConfidence': 0.81,
      'metricQualities': {
        'footStrike': {'confidence': 0.82, 'sampleCount': 2},
        'kneeFlexion': {'confidence': 0.80, 'sampleCount': 2},
      },
      'poseFrames': [
        _poseFrameMap(timestampMs: 1033, imageWidth: 640, imageHeight: 360),
        _poseFrameMap(timestampMs: 1000, imageWidth: 640, imageHeight: 360),
        _poseFrameMap(timestampMs: 1033, imageWidth: 1280, imageHeight: 720),
      ],
    });

    expect(result.hasDenseContactEvidence, isTrue);
    expect(result.denseSamples.attemptedFrames, 18);
    expect(result.denseSamples.maxFrameBudget, 48);
    expect(result.denseSamples.targetFps, 30);
    expect(result.contactWindows, hasLength(1));
    expect(result.contactWindows.single.side, RunningContactSide.right);
    expect(
      result.contactWindows.single.validatedContactTimestamps
          .map((timestamp) => timestamp.inMilliseconds),
      [1033, 1066],
    );
    expect(
      result.validatedContactFrameTimestamps
          .map((timestamp) => timestamp.inMilliseconds),
      [1033, 1066],
    );
    expect(result.contactConfidence, closeTo(0.81, 0.0001));
    expect(
      result.qualityFor(RunningCoachMetric.footStrike)!.confidence,
      closeTo(0.82, 0.0001),
    );
    expect(result.poseFrames.map((frame) => frame.timestampMs), [1000, 1033]);
    expect(result.poseFrames.last.imageWidth, 1280);
    expect(
      result.nearestValidatedContactTimestamp(
        const Duration(milliseconds: 1050),
      ),
      const Duration(milliseconds: 1066),
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
  };
}
