import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';
import 'package:football_note/presentation/running_coach/running_three_d_runner.dart';

void main() {
  const insight = RunningCoachingInsight(
    metric: RunningCoachMetric.footStrike,
    finding: RunningCoachFinding.footStrikeOverstride,
    status: RunningCoachStatus.needsWork,
    score: 24,
    value: 0.35,
    quality: RunningMetricQuality(confidence: 0.90, sampleCount: 2),
  );

  test('builds a WebGL payload with all 33 source landmarks and world data',
      () {
    final frames = <RunningPoseFrame>[
      _runningFrame(timestampMs: 0),
      _runningFrame(timestampMs: 33, hipShift: 0.01),
    ];
    final payload = const RunningThreeDRunnerRetargeter()
        .buildComparisonPayload(
          poseFrames: frames,
          selectedFrame: frames.first,
          insight: insight,
          direction: RunningDirection.leftToRight,
          currentLabel: 'Current',
          targetLabel: 'Next',
          confidenceLabel: 'Tracking',
          loadingLabel: 'Loading',
          errorLabel: 'Error',
          referenceNotice: 'Generic',
          currentColor: '#ff0000',
          targetColor: '#0000ff',
          successColor: '#008000',
          playbackActive: false,
        )
        .data;

    expect(payload['rendererVersion'], runningThreeDRendererVersion);
    expect(payload['hasMotion'], isTrue);
    expect(payload['playbackActive'], isFalse);
    final payloadFrames = payload['frames']! as List<Object?>;
    expect(payloadFrames, hasLength(2));
    final firstFrame = payloadFrames.first! as Map<Object?, Object?>;
    final sourceLandmarks = firstFrame['sourceLandmarks']! as List<Object?>;
    expect(sourceLandmarks, hasLength(mediaPipePoseLandmarkCount));
    expect(
      sourceLandmarks.cast<Map<Object?, Object?>>().every(
            (landmark) =>
                landmark.containsKey('worldX') &&
                landmark.containsKey('worldY') &&
                landmark.containsKey('worldZ') &&
                landmark.containsKey('worldConfidence'),
          ),
      isTrue,
    );
    final currentRig = firstFrame['current']! as Map<Object?, Object?>;
    final joints = currentRig['joints']! as Map<Object?, Object?>;
    expect(
        joints.keys,
        containsAll(<String>[
          'pelvisCenter',
          'chest',
          'head',
          'leftIndex',
          'rightThumb',
          'leftToe',
          'rightHeel',
        ]));
  });

  test('moves only the lead foot-strike channel toward the target zone', () {
    final frame = _runningFrame(timestampMs: 0);
    final retargeted =
        const RunningThreeDRunnerRetargeter().retargetSequenceForTesting(
      frames: <RunningPoseFrame>[frame],
      insight: insight,
      direction: RunningDirection.leftToRight,
    ).single;
    final current = retargeted['current']! as Map<Object?, Object?>;
    final target = retargeted['target']! as Map<Object?, Object?>;
    final currentToeX = _jointX(current, 'leftToe');
    final targetToeX = _jointX(target, 'leftToe');
    final currentChestX = _jointX(current, 'chest');
    final targetChestX = _jointX(target, 'chest');

    expect(
        target['modifiedChannels'],
        containsAll(<String>[
          'leftKnee',
          'leftAnkle',
          'leftToe',
          'leftHeel',
        ]));
    expect(targetToeX, lessThan(currentToeX));
    expect(targetChestX, closeTo(currentChestX, 0.0001));
  });

  test('holds low-confidence landmarks briefly and locks grounded feet', () {
    final frames = <RunningPoseFrame>[
      _runningFrame(timestampMs: 0, leftWristX: 0.42),
      _runningFrame(
        timestampMs: 33,
        leftWristX: 0.88,
        lowConfidenceIndices: const <int>{15, 17, 19, 21},
      ),
    ];
    final retargeted =
        const RunningThreeDRunnerRetargeter().retargetSequenceForTesting(
      frames: frames,
      insight: insight,
      direction: RunningDirection.leftToRight,
    );
    final firstCurrent = retargeted.first['current']! as Map<Object?, Object?>;
    final secondCurrent = retargeted.last['current']! as Map<Object?, Object?>;
    final firstWristX = _jointX(firstCurrent, 'leftWrist');
    final secondWristX = _jointX(secondCurrent, 'leftWrist');
    final footLocks = secondCurrent['footLocks']! as List<Object?>;

    expect((secondWristX - firstWristX).abs(), lessThan(0.08));
    expect(
      footLocks.cast<Map<Object?, Object?>>().any(
            (decision) =>
                decision['side'] == 'left' && decision['locked'] == true,
          ),
      isTrue,
    );
  });
}

double _jointX(Map<Object?, Object?> rig, String name) {
  final joints = rig['joints']! as Map<Object?, Object?>;
  final point = joints[name]! as List<Object?>;
  return point[0]! as double;
}

RunningPoseFrame _runningFrame({
  required int timestampMs,
  double hipShift = 0,
  double leftWristX = 0.42,
  Set<int> lowConfidenceIndices = const <int>{},
}) {
  final points = <int, ({double x, double y})>{
    0: (x: 0.68 + hipShift, y: 0.12),
    1: (x: 0.67 + hipShift, y: 0.13),
    2: (x: 0.69 + hipShift, y: 0.13),
    3: (x: 0.66 + hipShift, y: 0.14),
    4: (x: 0.70 + hipShift, y: 0.14),
    5: (x: 0.65 + hipShift, y: 0.16),
    6: (x: 0.71 + hipShift, y: 0.16),
    7: (x: 0.64 + hipShift, y: 0.17),
    8: (x: 0.70 + hipShift, y: 0.17),
    9: (x: 0.66 + hipShift, y: 0.19),
    10: (x: 0.69 + hipShift, y: 0.19),
    11: (x: 0.53 + hipShift, y: 0.25),
    12: (x: 0.57 + hipShift, y: 0.25),
    13: (x: 0.47 + hipShift, y: 0.37),
    14: (x: 0.62 + hipShift, y: 0.34),
    15: (x: leftWristX + hipShift, y: 0.48),
    16: (x: 0.68 + hipShift, y: 0.45),
    17: (x: leftWristX - 0.01 + hipShift, y: 0.49),
    18: (x: 0.69 + hipShift, y: 0.46),
    19: (x: leftWristX + 0.01 + hipShift, y: 0.48),
    20: (x: 0.67 + hipShift, y: 0.45),
    21: (x: leftWristX + 0.02 + hipShift, y: 0.49),
    22: (x: 0.70 + hipShift, y: 0.46),
    23: (x: 0.53 + hipShift, y: 0.54),
    24: (x: 0.57 + hipShift, y: 0.54),
    25: (x: 0.68 + hipShift, y: 0.66),
    26: (x: 0.45 + hipShift, y: 0.67),
    27: (x: 0.78 + hipShift, y: 0.82),
    28: (x: 0.34 + hipShift, y: 0.85),
    29: (x: 0.74 + hipShift, y: 0.86),
    30: (x: 0.30 + hipShift, y: 0.89),
    31: (x: 0.84 + hipShift, y: 0.86),
    32: (x: 0.39 + hipShift, y: 0.90),
  };
  return RunningPoseFrame(
    timestamp: Duration(milliseconds: timestampMs),
    imageWidth: 720,
    imageHeight: 1280,
    landmarks: List<RunningVideoPoseLandmark>.unmodifiable([
      for (var index = 0; index < mediaPipePoseLandmarkCount; index += 1)
        RunningVideoPoseLandmark(
          index: index,
          x: points[index]!.x,
          y: points[index]!.y,
          z: -0.01 * index,
          visibility: lowConfidenceIndices.contains(index) ? 0.12 : 0.95,
          presence: lowConfidenceIndices.contains(index) ? 0.12 : 0.95,
          confidence: lowConfidenceIndices.contains(index) ? 0.12 : 0.95,
          worldX: points[index]!.x - 0.55,
          worldY: 0.54 - points[index]!.y,
          worldZ: -0.012 * index,
          worldVisibility: lowConfidenceIndices.contains(index) ? 0.12 : 0.93,
          worldPresence: lowConfidenceIndices.contains(index) ? 0.12 : 0.92,
          worldConfidence: lowConfidenceIndices.contains(index) ? 0.12 : 0.92,
        ),
    ]),
  );
}
