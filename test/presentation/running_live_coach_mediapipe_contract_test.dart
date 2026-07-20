import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('general running live coach screen is strict MediaPipe-only', () {
    final source = File(
      'lib/presentation/screens/running_live_coach_screen.dart',
    ).readAsStringSync();

    expect(source, contains('MediaPipePoseLandmarkerService'));
    expect(source, contains('detectPoseFromCameraImage'));
    expect(source, contains('runningPoseObservationFromMediaPipeDetection'));
    expect(source, contains('_showLiveCoachError'));
    expect(source, contains('runningCoachLivePoseFailed'));
    expect(source, contains('Duration(milliseconds: 120)'));
    expect(source, contains('_isProcessingFrame'));
    expect(source, contains('_monotonicFrameTimestamp'));
    expect(source, contains('state.trackedObservation'));
    expect(source, contains('runningCoachLiveGaitCadenceValue'));
    expect(source, contains('runningCoachLiveGaitContactValue'));
    expect(source, isNot(contains('Duration(milliseconds: 350)')));

    for (final forbidden in <String>[
      'google_mlkit_pose_detection',
      'PoseDetector',
      'PoseDetectorOptions',
      'processImage',
      'InputImage.fromBytes',
      'InputImageMetadata',
      'InputImageFormatValue',
    ]) {
      expect(
        source,
        isNot(contains(forbidden)),
        reason: 'RunningLiveCoachScreen must not use $forbidden.',
      );
    }

    expect(
      source,
      isNot(contains('Ignore transient pose errors')),
      reason: 'MediaPipe inference failures must surface as retryable errors.',
    );
  });
}
