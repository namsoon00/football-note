import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('general running live coach screen is strict MediaPipe-only', () {
    final source = File(
      'lib/presentation/screens/running_live_coach_screen.dart',
    ).readAsStringSync();
    final visualTrackerSource = File(
      'lib/realtime_analysis/running_coaching/running_visual_pose_tracker.dart',
    ).readAsStringSync();
    final painterSource = File(
      'lib/presentation/painters/running_pose_anatomical_painter.dart',
    ).readAsStringSync();
    final combinedSource = '$source\n$visualTrackerSource\n$painterSource';

    expect(source, contains('MediaPipePoseLandmarkerService'));
    expect(source, contains('detectPoseFromCameraImage'));
    expect(source, contains('runningPoseObservationFromMediaPipeDetection'));
    expect(source, contains('RunningVisualPoseTracker'));
    expect(source, contains('ingestDetection'));
    expect(source, contains('ingestGaitEvents'));
    expect(source, contains('_poseOverlayTicker'));
    expect(source, contains('_poseOverlayFrame'));
    expect(source, contains('RunningPoseAnatomicalPainter'));
    expect(source, contains('_showLiveCoachError'));
    expect(source, contains('runningCoachLivePoseFailed'));
    expect(source, contains('Duration(milliseconds: 120)'));
    expect(source, contains('_isProcessingFrame'));
    expect(source, contains('_monotonicFrameTimestamp'));
    expect(source, contains('RunningLiveSessionMetricsCollector'));
    expect(source, contains('RunningLiveSkippedFrameReason.detectorBusy'));
    expect(source, contains('RunningLiveSkippedFrameReason.throttled'));
    expect(source, contains('RunningLiveSkippedFrameReason.invalidInput'));
    expect(source, contains('RunningLiveSkippedFrameReason.analysisError'));
    expect(source, contains('recordAnalyzedFrame'));
    expect(source, contains('[RunningLiveSession]'));
    expect(source, contains('jsonEncode(payload)'));
    expect(source, contains('_startSessionLogging'));
    expect(source, contains('_endSessionLogging'));
    expect(source, isNot(contains('state.trackedObservation')));
    expect(source, isNot(contains('_RunningPosePainter')));
    expect(source, isNot(contains('_translatePoint')));
    expect(painterSource, contains('CameraViewportTransform.cover'));
    expect(painterSource, contains('buildRunningPoseAnatomyGeometry'));
    expect(visualTrackerSource, contains('RunningVisualPoseLandmarkState'));
    expect(visualTrackerSource, contains('maximumPrediction'));
    expect(visualTrackerSource, contains('maximumStanceLockDuration'));
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
        combinedSource,
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
