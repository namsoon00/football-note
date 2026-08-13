import 'dart:ui';

import 'package:flutter/material.dart' show BoxFit;
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
    expect(paintedPixels.length, greaterThan(1400));
    for (final index in <int>[11, 12, 13, 14, 23, 24, 25, 26, 27, 28]) {
      final point = _humanFormPoints[index]!;
      expect(
        _alphaAt(pixels, 240, point.dx.round(), point.dy.round()),
        greaterThan(0),
        reason: 'Measured joint $index must remain on its exact coordinate.',
      );
    }
    expect(_alphaAt(pixels, 240, 5, 5), 0);
    image.dispose();
  });

  test('renders a sports runner avatar from measured pose joints', () async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    paintRunningPoseHumanForm(
      canvas,
      points: _humanFormPoints,
      canvasSize: const Size(240, 360),
      style: runningPoseSportsAvatarStyle(
        accentColor: const Color(0xFF2E7CF6),
        secondaryAccent: const Color(0xFF87B9FF),
        focusColor: const Color(0xFFFF646B),
        jointColor: const Color(0xFFF8FBFF),
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
    expect(paintedPixels.length, greaterThan(3000));
    expect(_alphaAt(pixels, 240, 97, 119), greaterThan(160));
    for (final index in <int>[11, 12, 23, 24, 25, 26, 27, 28]) {
      final point = _humanFormPoints[index]!;
      expect(
        _alphaAt(pixels, 240, point.dx.round(), point.dy.round()),
        greaterThan(0),
        reason: 'Measured joint $index must anchor the runner avatar.',
      );
    }
    image.dispose();
  });

  test('keeps the runner avatar readable for a narrow side profile', () async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    paintRunningPoseHumanForm(
      canvas,
      points: _sideProfileHumanFormPoints,
      canvasSize: const Size(240, 360),
      style: runningPoseSportsAvatarStyle(
        accentColor: const Color(0xFF2E7CF6),
        secondaryAccent: const Color(0xFF87B9FF),
        focusColor: const Color(0xFFFF646B),
        jointColor: const Color(0xFFF8FBFF),
      ),
    );

    final image = await recorder.endRecording().toImage(240, 360);
    final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);

    expect(bytes, isNotNull);
    final pixels = bytes!.buffer.asUint8List();
    final paintedPixels = <int>[
      for (var offset = 3; offset < pixels.length; offset += 4)
        if (pixels[offset] > 0) pixels[offset],
    ];
    expect(paintedPixels.length, greaterThan(2800));
    // The paired shoulder points are only two pixels apart. This pixel sits
    // inside the rendered shirt, proving that the side-profile silhouette did
    // not collapse to a landmark line.
    expect(_alphaAt(pixels, 240, 118, 140), greaterThan(0));
    for (final index in <int>[11, 12, 23, 24, 25, 26, 27, 28]) {
      final point = _sideProfileHumanFormPoints[index]!;
      expect(
        _alphaAt(pixels, 240, point.dx.round(), point.dy.round()),
        greaterThan(0),
        reason: 'Measured joint $index must remain an avatar anchor.',
      );
    }
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

  test('shared overlay mapping matches contain and cover media transforms', () {
    final frame = _poseFrame(timestampMs: 0, x: 0.5, confidence: 1);
    final landmark = frame.landmarkByIndex(0)!;

    final contain = mapRunningPoseLandmarkToCanvas(
      frame: frame,
      landmark: landmark,
      canvasSize: const Size(300, 300),
      fit: BoxFit.contain,
    );
    final cover = mapRunningPoseLandmarkToCanvas(
      frame: frame,
      landmark: landmark,
      canvasSize: const Size(300, 300),
      fit: BoxFit.cover,
    );

    expect(contain.dx, closeTo(150, 0.0001));
    expect(cover.dx, closeTo(150, 0.0001));
    expect(contain.dy, closeTo(107.8125, 0.0001));
    expect(cover.dy, closeTo(75, 0.0001));
    expect(
      mapRunningPoseLandmarkToCanvas(
        frame: frame,
        landmark: landmark,
        canvasSize: const Size(300, 300),
        fit: BoxFit.contain,
        mirrorHorizontally: true,
      ).dx,
      closeTo(150, 0.0001),
    );
  });
}

int _alphaAt(List<int> pixels, int width, int x, int y) {
  return pixels[((y * width + x) * 4) + 3];
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

const Map<int, Offset> _sideProfileHumanFormPoints = <int, Offset>{
  0: Offset(128, 43),
  7: Offset(125, 52),
  8: Offset(131, 52),
  11: Offset(127, 96),
  12: Offset(129, 96),
  13: Offset(106, 136),
  14: Offset(150, 132),
  15: Offset(92, 110),
  16: Offset(176, 160),
  23: Offset(127, 188),
  24: Offset(129, 188),
  25: Offset(104, 250),
  26: Offset(152, 234),
  27: Offset(74, 320),
  28: Offset(176, 314),
  29: Offset(64, 328),
  30: Offset(166, 321),
  31: Offset(98, 332),
  32: Offset(201, 318),
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
