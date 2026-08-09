import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/running_live_framing_analysis.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(runningLiveFramingAnalysisChannel, null);
  });

  testWidgets('sends throttled live camera frame payload to pose channel',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    MethodCall? capturedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(runningLiveFramingAnalysisChannel,
            (call) async {
      capturedCall = call;
      return _poseFramePayload();
    });

    // ignore: deprecated_member_use
    final image = CameraImage.fromPlatformData(<dynamic, dynamic>{
      'width': 4,
      'height': 4,
      'format': 35,
      'planes': <Map<dynamic, dynamic>>[
        <dynamic, dynamic>{
          'bytes': Uint8List(16),
          'bytesPerRow': 4,
          'bytesPerPixel': 1,
        },
        <dynamic, dynamic>{
          'bytes': Uint8List(4),
          'bytesPerRow': 2,
          'bytesPerPixel': 1,
        },
        <dynamic, dynamic>{
          'bytes': Uint8List(4),
          'bytesPerRow': 2,
          'bytesPerPixel': 1,
        },
      ],
    });
    debugDefaultTargetPlatformOverride = null;

    final frame = await analyzeRunningLiveCameraImage(
      image: image,
      rotationDegrees: 90,
      isFrontCamera: false,
    );

    expect(capturedCall?.method, 'analyzeRunningLiveFrame');
    final arguments = capturedCall!.arguments! as Map<Object?, Object?>;
    expect(arguments['width'], 4);
    expect(arguments['height'], 4);
    expect(arguments['format'], 'yuv420');
    expect(arguments['rotationDegrees'], 90);
    expect(arguments['isFrontCamera'], isFalse);
    expect(arguments['maxDimension'], 360);
    expect(arguments['planes'], isA<List<Object?>>());
    expect(frame, isNotNull);
    expect(frame!.landmarks, hasLength(mediaPipePoseLandmarkCount));
  });
}

Map<String, Object?> _poseFramePayload() {
  return <String, Object?>{
    'timestampMs': 0,
    'imageWidth': 4,
    'imageHeight': 4,
    'landmarks': <Map<String, Object?>>[
      for (var index = 0; index < mediaPipePoseLandmarkCount; index += 1)
        <String, Object?>{
          'index': index,
          'x': 0.5,
          'y': 0.5,
          'z': 0.0,
          'visibility': 0.95,
          'presence': 0.95,
          'confidence': 0.95,
        },
    ],
  };
}
