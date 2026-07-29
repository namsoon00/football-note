import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';
import 'package:football_note/presentation/running_coach/running_professional_runner.dart';
import 'package:football_note/presentation/running_coach/running_professional_runner_art.dart';

void main() {
  test('retargets measured joints into stable athlete proportions', () {
    final pose = retargetProfessionalRunnerPose(
      measuredPoints: _overstridePoints,
      forward: 1,
    );

    expect(pose, isNotNull);
    final retargeted = pose!;
    expect(retargeted.points[23], _overstridePoints[23]);
    expect(retargeted.points[27], _overstridePoints[27]);
    expect(retargeted.points[25], isNot(_overstridePoints[25]));
    final thigh = (retargeted.points[25]! - retargeted.points[23]!).distance;
    final shin = (retargeted.points[27]! - retargeted.points[25]!).distance;
    expect(thigh / (thigh + shin), closeTo(0.525, 0.015));
    expect(retargeted.headCenter.dy, lessThan(retargeted.neck.dy));
  });

  test('does not build a professional runner without core joints', () {
    final pose = retargetProfessionalRunnerPose(
      measuredPoints: const <int, Offset>{
        11: Offset(80, 90),
        12: Offset(84, 90),
      },
      forward: 1,
    );

    expect(pose, isNull);
  });

  test('uses face position to orient a stationary treadmill runner', () {
    final rightFacing = <int, Offset>{
      0: const Offset(155, 40),
      11: const Offset(100, 90),
      12: const Offset(112, 90),
      23: const Offset(102, 168),
      24: const Offset(114, 168),
    };
    final leftFacing = <int, Offset>{
      0: const Offset(57, 40),
      11: const Offset(100, 90),
      12: const Offset(112, 90),
      23: const Offset(102, 168),
      24: const Offset(114, 168),
    };

    expect(
      resolveRunningVisualForward(
        measuredPoints: rightFacing,
        direction: RunningDirection.stationary,
      ),
      1,
    );
    expect(
      resolveRunningVisualForward(
        measuredPoints: leftFacing,
        direction: RunningDirection.stationary,
      ),
      -1,
    );
  });

  test('uses travel direction when face landmarks are unavailable', () {
    final points = <int, Offset>{
      11: const Offset(100, 90),
      12: const Offset(112, 90),
      23: const Offset(102, 168),
      24: const Offset(114, 168),
    };

    expect(
      resolveRunningVisualForward(
        measuredPoints: points,
        direction: RunningDirection.rightToLeft,
      ),
      -1,
    );
  });

  test('mirrors the native right-facing reference only for leftward motion',
      () {
    expect(shouldMirrorProfessionalRunnerArt(1), isFalse);
    expect(shouldMirrorProfessionalRunnerArt(-1), isTrue);
  });

  test('keeps a readable professional reference when evidence loses limbs', () {
    final pose = retargetProfessionalRunnerPose(
      measuredPoints: const <int, Offset>{
        11: Offset(48, 34),
        12: Offset(56, 35),
        23: Offset(50, 96),
        24: Offset(58, 96),
      },
      forward: 1,
    );

    expect(pose, isNotNull);
    expect(pose!.measuredIndices, equals(const <int>{11, 12, 23, 24}));
    expect(pose.points[27], isNotNull);
    expect(pose.points[28], isNotNull);
    expect(pose.points[15], isNotNull);
    expect(pose.points[16], isNotNull);
  });

  testWidgets('loads and paints the professional runner illustration atlas',
      (tester) async {
    final paintedPixels = await tester.runAsync(() async {
      final atlas = await loadProfessionalRunnerArtAtlas();
      final pose = retargetProfessionalRunnerPose(
        measuredPoints: _overstridePoints,
        forward: 1,
      )!;
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      paintIllustratedProfessionalRunner(
        canvas,
        atlas: atlas,
        pose: pose,
        accentColor: const Color(0xFFFA6E7A),
        isTarget: false,
        focusIndices: const <int>{23, 25, 27, 29, 31},
      );

      final image = await recorder.endRecording().toImage(260, 360);
      final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);
      image.dispose();
      return <int>[
        for (var offset = 3; offset < bytes!.lengthInBytes; offset += 4)
          if (bytes.buffer.asUint8List()[offset] > 0)
            bytes.buffer.asUint8List()[offset],
      ].length;
    });

    expect(paintedPixels, greaterThan(6000));
  });

  testWidgets('renders the goal reference when running right to left',
      (tester) async {
    final paintedPixels = await tester.runAsync(() async {
      final atlas = await loadProfessionalRunnerArtAtlas();
      final pose = retargetProfessionalRunnerPose(
        measuredPoints: <int, Offset>{
          for (final entry in _overstridePoints.entries)
            entry.key: Offset(260 - entry.value.dx, entry.value.dy),
        },
        forward: -1,
      )!;
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      paintIllustratedProfessionalRunner(
        canvas,
        atlas: atlas,
        pose: pose,
        accentColor: const Color(0xFFA8C5FF),
        isTarget: true,
        focusIndices: const <int>{23, 25, 27, 29, 31},
      );

      final image = await recorder.endRecording().toImage(260, 360);
      final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);
      image.dispose();
      return <int>[
        for (var offset = 3; offset < bytes!.lengthInBytes; offset += 4)
          if (bytes.buffer.asUint8List()[offset] > 0)
            bytes.buffer.asUint8List()[offset],
      ].length;
    });

    expect(paintedPixels, greaterThan(6000));
  });

  testWidgets('fits a sparse-evidence reference inside a report panel',
      (tester) async {
    final paintedPixels = await tester.runAsync(() async {
      final atlas = await loadProfessionalRunnerArtAtlas();
      final pose = retargetProfessionalRunnerPose(
        measuredPoints: const <int, Offset>{
          11: Offset(48, 34),
          12: Offset(56, 35),
          23: Offset(50, 96),
          24: Offset(58, 96),
        },
        forward: 1,
      )!;
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      paintIllustratedProfessionalRunner(
        canvas,
        atlas: atlas,
        pose: pose,
        accentColor: const Color(0xFFFA6E7A),
        isTarget: false,
        bounds: const Rect.fromLTWH(0, 0, 108, 214),
      );

      final image = await recorder.endRecording().toImage(108, 214);
      final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);
      image.dispose();
      return <int>[
        for (var offset = 3; offset < bytes!.lengthInBytes; offset += 4)
          if (bytes.buffer.asUint8List()[offset] > 0)
            bytes.buffer.asUint8List()[offset],
      ].length;
    });

    expect(paintedPixels, greaterThan(1800));
  });
}

const Map<int, Offset> _overstridePoints = <int, Offset>{
  0: Offset(132, 44),
  7: Offset(126, 53),
  8: Offset(137, 53),
  11: Offset(121, 94),
  12: Offset(131, 96),
  13: Offset(151, 132),
  14: Offset(106, 137),
  15: Offset(171, 162),
  16: Offset(88, 116),
  23: Offset(122, 180),
  24: Offset(132, 181),
  25: Offset(162, 224),
  26: Offset(108, 232),
  27: Offset(205, 298),
  28: Offset(76, 300),
  29: Offset(194, 306),
  30: Offset(67, 307),
  31: Offset(221, 308),
  32: Offset(91, 308),
};
