import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class MediaPipePoseLandmarkerService {
  static const MethodChannel _channel = MethodChannel(
    'football_note/mediapipe_pose_landmarker',
  );

  const MediaPipePoseLandmarkerService();

  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<MediaPipePoseDetection?> detectPoseFromCameraImage({
    required CameraImage image,
    required int rotationDegrees,
    required DateTime timestamp,
  }) async {
    if (!isSupported) {
      return null;
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
      _ => null,
    };
  }

  Future<MediaPipePoseDetection?> _detectPoseFromNv21({
    required CameraImage image,
    required int rotationDegrees,
    required DateTime timestamp,
  }) async {
    if (image.planes.length != 1) {
      return null;
    }
    final bytes = image.planes.first.bytes;
    try {
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
        return null;
      }
      return MediaPipePoseDetection.fromMap(result);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<MediaPipePoseDetection?> _detectPoseFromBgra8888({
    required CameraImage image,
    required int rotationDegrees,
    required DateTime timestamp,
  }) async {
    if (image.planes.length != 1) {
      return null;
    }

    final plane = image.planes.first;
    try {
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
        return null;
      }
      return MediaPipePoseDetection.fromMap(result);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
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
      // Native MediaPipe is optional and the ML Kit fallback remains available.
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
      confidence: (visibility ?? presence ?? 1).clamp(0.0, 1.0),
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
