import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/entities/running_live_coaching_state.dart';

class MediaPipePoseLandmarkerService {
  static const MethodChannel _channel = MethodChannel(
    'football_note/mediapipe_pose_landmarker',
  );
  static const bool strictFailureMode = bool.fromEnvironment(
    'SPRINT_MEDIAPIPE_STRICT',
    defaultValue: true,
  );

  const MediaPipePoseLandmarkerService();

  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<MediaPipePoseDetection> detectPoseFromCameraImage({
    required CameraImage image,
    required int rotationDegrees,
    required DateTime timestamp,
  }) async {
    if (!isSupported) {
      throw UnsupportedError(
        'MediaPipe pose detection is only available on Android and iOS.',
      );
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _detectPoseFromNv21(
          image: image,
          rotationDegrees: rotationDegrees,
          timestamp: timestamp,
        ),
      TargetPlatform.iOS => _detectPoseFromBgra8888(
          image: image,
          rotationDegrees: rotationDegrees,
          timestamp: timestamp,
        ),
      _ => throw UnsupportedError(
          'MediaPipe pose detection is not available on this platform.',
        ),
    };
  }

  Future<MediaPipePoseDetection> _detectPoseFromNv21({
    required CameraImage image,
    required int rotationDegrees,
    required DateTime timestamp,
  }) async {
    if (image.planes.length != 1) {
      throw ArgumentError.value(
        image.planes.length,
        'image.planes.length',
        'MediaPipe Android pose detection requires one NV21 plane.',
      );
    }
    final bytes = image.planes.first.bytes;
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'detectPoseFromNv21',
      <String, Object?>{
        'bytes': bytes,
        'width': image.width,
        'height': image.height,
        'rotationDegrees': rotationDegrees,
        'timestampMs': timestamp.millisecondsSinceEpoch,
      },
    );
    if (result == null) {
      throw StateError('Native MediaPipe pose detection returned no result.');
    }
    return MediaPipePoseDetection.fromMap(result);
  }

  Future<MediaPipePoseDetection> _detectPoseFromBgra8888({
    required CameraImage image,
    required int rotationDegrees,
    required DateTime timestamp,
  }) async {
    if (image.planes.length != 1) {
      throw ArgumentError.value(
        image.planes.length,
        'image.planes.length',
        'MediaPipe iOS pose detection requires one BGRA8888 plane.',
      );
    }

    final plane = image.planes.first;
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'detectPoseFromBgra8888',
      <String, Object?>{
        'bytes': plane.bytes,
        'width': image.width,
        'height': image.height,
        'bytesPerRow': plane.bytesPerRow,
        'rotationDegrees': rotationDegrees,
        'timestampMs': timestamp.millisecondsSinceEpoch,
      },
    );
    if (result == null) {
      throw StateError('Native MediaPipe pose detection returned no result.');
    }
    return MediaPipePoseDetection.fromMap(result);
  }

  Future<void> close() async {
    if (!isSupported) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('close');
    } on PlatformException {
      // The detector is best-effort and can be recreated on the next screen open.
    } on MissingPluginException {
      // Native MediaPipe may be unavailable during teardown.
    }
  }
}

class MediaPipePoseDetection {
  final Size imageSize;
  final List<MediaPipePoseLandmark> landmarks;

  const MediaPipePoseDetection({
    required this.imageSize,
    required this.landmarks,
  });

  factory MediaPipePoseDetection.fromMap(Map<Object?, Object?> map) {
    final imageWidth = (map['imageWidth'] as num?)?.toDouble() ?? 0;
    final imageHeight = (map['imageHeight'] as num?)?.toDouble() ?? 0;
    final rawLandmarks =
        (map['landmarks'] as List<Object?>?) ?? const <Object?>[];
    return MediaPipePoseDetection(
      imageSize: Size(imageWidth, imageHeight),
      landmarks: [
        for (final raw in rawLandmarks)
          if (raw is Map<Object?, Object?>) MediaPipePoseLandmark.fromMap(raw),
      ],
    );
  }
}

RunningPoseObservation? runningPoseObservationFromMediaPipeDetection(
  MediaPipePoseDetection detection,
) {
  if (detection.imageSize.isEmpty || detection.landmarks.isEmpty) {
    return null;
  }

  final landmarks = <RunningPoseLandmarkType, RunningPoseLandmark>{};
  for (final landmark in detection.landmarks) {
    final type = runningPoseLandmarkTypeForMediaPipeIndex(landmark.index);
    if (type == null) {
      continue;
    }
    landmarks[type] = RunningPoseLandmark(
      position: landmark.position,
      likelihood: landmark.confidence,
    );
  }

  if (landmarks.isEmpty) {
    return null;
  }
  return RunningPoseObservation(
    imageSize: detection.imageSize,
    landmarks: landmarks,
  );
}

RunningPoseLandmarkType? runningPoseLandmarkTypeForMediaPipeIndex(int index) {
  return switch (index) {
    0 => RunningPoseLandmarkType.nose,
    7 => RunningPoseLandmarkType.leftEar,
    8 => RunningPoseLandmarkType.rightEar,
    11 => RunningPoseLandmarkType.leftShoulder,
    12 => RunningPoseLandmarkType.rightShoulder,
    13 => RunningPoseLandmarkType.leftElbow,
    14 => RunningPoseLandmarkType.rightElbow,
    15 => RunningPoseLandmarkType.leftWrist,
    16 => RunningPoseLandmarkType.rightWrist,
    23 => RunningPoseLandmarkType.leftHip,
    24 => RunningPoseLandmarkType.rightHip,
    25 => RunningPoseLandmarkType.leftKnee,
    26 => RunningPoseLandmarkType.rightKnee,
    27 => RunningPoseLandmarkType.leftAnkle,
    28 => RunningPoseLandmarkType.rightAnkle,
    29 => RunningPoseLandmarkType.leftHeel,
    30 => RunningPoseLandmarkType.rightHeel,
    31 => RunningPoseLandmarkType.leftFootIndex,
    32 => RunningPoseLandmarkType.rightFootIndex,
    _ => null,
  };
}

class MediaPipePoseLandmark {
  final int index;
  final Offset position;
  final double z;
  final double confidence;
  final double? visibility;
  final double? presence;
  final MediaPipeWorldLandmark? worldLandmark;

  const MediaPipePoseLandmark({
    required this.index,
    required this.position,
    required this.z,
    required this.confidence,
    required this.visibility,
    required this.presence,
    required this.worldLandmark,
  });

  factory MediaPipePoseLandmark.fromMap(Map<Object?, Object?> map) {
    final visibility = (map['visibility'] as num?)?.toDouble();
    final presence = (map['presence'] as num?)?.toDouble();
    final worldX = (map['worldX'] as num?)?.toDouble();
    final worldY = (map['worldY'] as num?)?.toDouble();
    final worldZ = (map['worldZ'] as num?)?.toDouble();
    final worldVisibility = (map['worldVisibility'] as num?)?.toDouble();
    return MediaPipePoseLandmark(
      index: (map['index'] as num?)?.toInt() ?? -1,
      position: Offset(
        (map['x'] as num?)?.toDouble() ?? 0,
        (map['y'] as num?)?.toDouble() ?? 0,
      ),
      z: (map['z'] as num?)?.toDouble() ?? 0,
      confidence: _mediaPipeLandmarkConfidence(
        visibility: visibility,
        presence: presence,
      ),
      visibility: visibility,
      presence: presence,
      worldLandmark: worldX == null || worldY == null || worldZ == null
          ? null
          : MediaPipeWorldLandmark(
              x: worldX,
              y: worldY,
              z: worldZ,
              visibility: worldVisibility,
            ),
    );
  }
}

double _mediaPipeLandmarkConfidence({
  required double? visibility,
  required double? presence,
}) {
  final confidence = switch ((visibility, presence)) {
    (final visibility?, final presence?) =>
      visibility < presence ? visibility : presence,
    (final visibility?, null) => visibility,
    (null, final presence?) => presence,
    _ => 0.0,
  };
  return confidence.clamp(0.0, 1.0).toDouble();
}

class MediaPipeWorldLandmark {
  final double x;
  final double y;
  final double z;
  final double? visibility;

  const MediaPipeWorldLandmark({
    required this.x,
    required this.y,
    required this.z,
    required this.visibility,
  });
}
