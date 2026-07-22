import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';
import 'package:football_note/presentation/running_coach/running_pose_overlay.dart';

void main() {
  test('renders a refined joint overlay from measured pose joints', () async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    paintRunningPoseHumanForm(
      canvas,
      points: _humanFormPoints,
      canvasSize: const Size(240, 360),
      style: const RunningPoseHumanFormStyle(
        bodyColor: Color(0xFFE8F2FF),
        leftSideColor: Color(0xFF72B7FF),
        rightSideColor: Color(0xFF7EE2BF),
        jointColor: Color(0xFFFFFFFF),
        focusColor: Color(0xFFFF6B72),
      ),
      focusIndices: const <int>{23, 25, 27},
    );

    final image = await recorder.endRecording().toImage(240, 360);
    final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);

    expect(bytes, isNotNull);
    final pixels = bytes!.buffer.asUint8List();
    final paintedPixels = <int>[
      for (var offset = 3; offset < pixels.length; offset += 4)
        if (pixels[offset] > 0) pixels[offset],
    ];
    expect(paintedPixels.length, greaterThan(900));
    image.dispose();
  });

  test('interpolates adjacent pose frames by video timestamp', () {
    final frames = [
      _poseFrame(timestampMs: 0, x: 0.20, confidence: 0.9),
      _poseFrame(timestampMs: 1000, x: 0.40, confidence: 0.9),
    ];

    final sampled = runningPoseFrameAtPosition(
      frames: frames,
      position: const Duration(milliseconds: 500),
    );

    expect(sampled, isNotNull);
    expect(sampled!.timestampMs, 500);
    expect(sampled.landmarkByIndex(0)!.x, closeTo(0.30, 0.0001));
    expect(
      runningPoseFrameAtPosition(
        frames: frames,
        position: const Duration(milliseconds: 1600),
      ),
      isNull,
    );
  });

  test('smoothing weights nearby higher-confidence landmarks more strongly',
      () {
    final frames = [
      _poseFrame(timestampMs: 0, x: 0.0, confidence: 0.1),
      _poseFrame(timestampMs: 1000, x: 1.0, confidence: 1.0),
    ];

    final sampled = runningPoseFrameAtPosition(
      frames: frames,
      position: const Duration(milliseconds: 500),
    );

    expect(sampled, isNotNull);
    expect(sampled!.landmarkByIndex(0)!.x, greaterThan(0.5));
    expect(sampled.landmarkByIndex(0)!.confidence, greaterThan(0.55));
  });

  test('maps normalized landmarks through BoxFit.cover crop', () {
    final point = runningPoseCoverOffset(
      landmark: const RunningVideoPoseLandmark(
        index: 0,
        x: 0.5,
        y: 0.0,
        z: 0,
        visibility: 1,
        presence: 1,
        confidence: 1,
      ),
      imageWidth: 100,
      imageHeight: 200,
      outputSize: const Size(300, 300),
    );

    expect(point.dx, closeTo(150, 0.0001));
    expect(point.dy, closeTo(-150, 0.0001));
  });

  test('maps normalized landmarks through BoxFit.contain without cropping', () {
    final point = runningPoseContainOffset(
      landmark: const RunningVideoPoseLandmark(
        index: 0,
        x: 0.5,
        y: 0.0,
        z: 0,
        visibility: 1,
        presence: 1,
        confidence: 1,
      ),
      imageWidth: 100,
      imageHeight: 200,
      outputSize: const Size(300, 300),
    );

    expect(point.dx, closeTo(150, 0.0001));
    expect(point.dy, closeTo(0, 0.0001));
  });
}

const Map<int, Offset> _humanFormPoints = <int, Offset>{
  0: Offset(128, 44),
  7: Offset(116, 54),
  8: Offset(136, 54),
  11: Offset(106, 96),
  12: Offset(148, 96),
  13: Offset(88, 142),
  14: Offset(166, 138),
  15: Offset(78, 188),
  16: Offset(178, 180),
  23: Offset(112, 194),
  24: Offset(144, 194),
  25: Offset(90, 258),
  26: Offset(164, 252),
  27: Offset(72, 326),
  28: Offset(180, 316),
  29: Offset(62, 334),
  30: Offset(170, 324),
  31: Offset(92, 338),
  32: Offset(204, 326),
};

RunningPoseFrame _poseFrame({
  required int timestampMs,
  required double x,
  required double confidence,
}) {
  return RunningPoseFrame(
    timestamp: Duration(milliseconds: timestampMs),
    imageWidth: 640,
    imageHeight: 360,
    landmarks: List<RunningVideoPoseLandmark>.unmodifiable([
      for (var index = 0; index < mediaPipePoseLandmarkCount; index += 1)
        RunningVideoPoseLandmark(
          index: index,
          x: x,
          y: 0.25 + (index * 0.01),
          z: 0,
          visibility: confidence,
          presence: confidence,
          confidence: confidence,
        ),
    ]),
  );
}
