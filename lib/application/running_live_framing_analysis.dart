import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/entities/running_video_analysis_result.dart';

@visibleForTesting
const runningLiveFramingAnalysisChannel =
    MethodChannel('football_note/running_pose_analysis');

const _liveFrameMethodName = 'analyzeRunningLiveFrame';
const _defaultMaximumLiveFrameDimension = 360;

/// Runs a low-rate, single-frame pose pass through the native MediaPipe channel.
///
/// This is intentionally separate from upload analysis: the result is only a
/// framing aid before recording, and no scores are calculated from it.
Future<RunningPoseFrame?> analyzeRunningLiveCameraImage({
  required CameraImage image,
  required int rotationDegrees,
  required bool isFrontCamera,
  int maximumDimension = _defaultMaximumLiveFrameDimension,
}) async {
  final result = await runningLiveFramingAnalysisChannel
      .invokeMethod<Map<Object?, Object?>>(
    _liveFrameMethodName,
    <String, Object?>{
      'width': image.width,
      'height': image.height,
      'format': image.format.group.name,
      'rawFormat': image.format.raw?.toString(),
      'rotationDegrees': rotationDegrees,
      'isFrontCamera': isFrontCamera,
      'maxDimension': maximumDimension,
      'planes': image.planes
          .map(
            (plane) => <String, Object?>{
              'bytes': plane.bytes,
              'bytesPerRow': plane.bytesPerRow,
              if (plane.bytesPerPixel != null)
                'bytesPerPixel': plane.bytesPerPixel,
              if (plane.width != null) 'width': plane.width,
              if (plane.height != null) 'height': plane.height,
            },
          )
          .toList(growable: false),
    },
  );
  if (result == null) return null;
  return RunningPoseFrame.fromObject(result);
}
