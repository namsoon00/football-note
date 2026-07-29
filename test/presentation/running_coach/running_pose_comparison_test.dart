import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';
import 'package:football_note/presentation/running_coach/running_pose_comparison.dart';
import 'package:football_note/presentation/running_coach/running_professional_runner_art.dart';

void main() {
  const panel = Rect.fromLTWH(0, 0, 320, 248);

  test('foot-strike target keeps the torso fixed and solves the lead leg', () {
    final snapshot = buildRunningPoseComparisonSnapshot(
      frame: _runningFrame(),
      insight: const RunningCoachingInsight(
        metric: RunningCoachMetric.footStrike,
        finding: RunningCoachFinding.footStrikeOverstride,
        status: RunningCoachStatus.needsWork,
        score: 24,
        value: 0.35,
      ),
      direction: RunningDirection.leftToRight,
      panel: panel,
    );

    expect(snapshot.forward, 1);
    expect(snapshot.targetPoints[11], snapshot.currentPoints[11]);
    expect(snapshot.targetPoints[23], snapshot.currentPoints[23]);
    expect(snapshot.movedIndices, containsAll(<int>{25, 27, 31}));
    expect(
      snapshot.targetPoints[31]!.dx - snapshot.targetPoints[23]!.dx,
      lessThan(snapshot.currentPoints[31]!.dx - snapshot.currentPoints[23]!.dx),
    );
  });

  test('a good result does not invent a red-to-blue correction', () {
    final snapshot = buildRunningPoseComparisonSnapshot(
      frame: _runningFrame(),
      insight: const RunningCoachingInsight(
        metric: RunningCoachMetric.footStrike,
        finding: RunningCoachFinding.footStrikeUnderBody,
        status: RunningCoachStatus.good,
        score: 96,
        value: 0.08,
      ),
      direction: RunningDirection.leftToRight,
      panel: panel,
    );

    expect(snapshot.movedIndices, isEmpty);
    for (final entry in snapshot.currentPoints.entries) {
      expect(snapshot.targetPoints[entry.key], entry.value);
    }
  });

  test('each metric highlights only its relevant coordinate group', () {
    expect(
      focusIndicesForRunningPoseMetric(RunningCoachMetric.posture),
      containsAll(<int>{0, 11, 12, 23, 24}),
    );
    expect(
      focusIndicesForRunningPoseMetric(RunningCoachMetric.footStrike),
      containsAll(<int>{23, 25, 27, 31}),
    );
    expect(
      focusIndicesForRunningPoseMetric(RunningCoachMetric.armCarriage),
      containsAll(<int>{11, 13, 15, 14, 16}),
    );
  });

  testWidgets('repaints when the professional runner art atlas resolves', (
    WidgetTester tester,
  ) async {
    final atlas = await tester.runAsync(loadProfessionalRunnerArtAtlas);
    final pendingPainter = _comparisonPainter();
    final loadedPainter = _comparisonPainter(artAtlas: atlas);

    expect(pendingPainter.usesIllustratedRunnerReference, isFalse);
    expect(loadedPainter.usesIllustratedRunnerReference, isTrue);
    expect(loadedPainter.shouldRepaint(pendingPainter), isTrue);
  });

  testWidgets('coordinate comparison paints in a narrow result card', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 248,
            width: 320,
            child: RunningPoseCoordinateComparison(
              frame: _runningFrame(),
              insight: const RunningCoachingInsight(
                metric: RunningCoachMetric.footStrike,
                finding: RunningCoachFinding.footStrikeOverstride,
                status: RunningCoachStatus.needsWork,
                score: 24,
                value: 0.35,
              ),
              direction: RunningDirection.leftToRight,
              progress: const AlwaysStoppedAnimation<double>(1),
              surfaceColor: Colors.white,
              mutedColor: Colors.blueGrey,
              actualAccent: Colors.red,
              targetAccent: Colors.blue,
              successAccent: Colors.green,
              semanticLabel: 'Coordinate comparison',
              currentLabel: 'Current',
              nextStepLabel: 'Next step',
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('running-coach-coordinate-pose-comparison')),
      findsOneWidget,
    );
    expect(
      find.text('Current'),
      findsOneWidget,
    );
    expect(
      find.text('Next step'),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate((widget) => widget is FutureBuilder<ui.Image>),
      findsOneWidget,
    );
    await tester.runAsync(loadProfessionalRunnerArtAtlas);
    await tester.pump();
    final comparison = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('running-coach-coordinate-pose-comparison')),
    );
    final painter =
        comparison.painter! as RunningPoseCoordinateComparisonPainter;
    expect(painter.usesIllustratedRunnerReference, isTrue);
    final paintedAvatarPixels = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      painter.paint(canvas, const Size(320, 216));
      final image = await recorder.endRecording().toImage(320, 216);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      final rgba = bytes!.buffer.asUint8List();
      var brightBluePixels = 0;
      for (var offset = 0; offset < rgba.lengthInBytes; offset += 4) {
        final red = rgba[offset];
        final green = rgba[offset + 1];
        final blue = rgba[offset + 2];
        if (blue > red + 35 && blue > green + 10 && blue > 125) {
          brightBluePixels += 1;
        }
      }
      return brightBluePixels;
    });
    expect(paintedAvatarPixels, greaterThan(200));
    expect(tester.takeException(), isNull);
  });
}

RunningPoseCoordinateComparisonPainter _comparisonPainter({
  ui.Image? artAtlas,
}) {
  return RunningPoseCoordinateComparisonPainter(
    frame: _runningFrame(),
    insight: const RunningCoachingInsight(
      metric: RunningCoachMetric.footStrike,
      finding: RunningCoachFinding.footStrikeOverstride,
      status: RunningCoachStatus.needsWork,
      score: 24,
      value: 0.35,
    ),
    direction: RunningDirection.leftToRight,
    progress: 1,
    surfaceColor: Colors.white,
    mutedColor: Colors.blueGrey,
    actualAccent: Colors.red,
    targetAccent: Colors.blue,
    successAccent: Colors.green,
    artAtlas: artAtlas,
  );
}

RunningPoseFrame _runningFrame() {
  const points = <int, Offset>{
    0: Offset(0.68, 0.12),
    7: Offset(0.65, 0.16),
    8: Offset(0.69, 0.16),
    11: Offset(0.53, 0.25),
    12: Offset(0.57, 0.25),
    13: Offset(0.47, 0.37),
    14: Offset(0.62, 0.34),
    15: Offset(0.42, 0.48),
    16: Offset(0.68, 0.45),
    17: Offset(0.41, 0.49),
    18: Offset(0.69, 0.46),
    19: Offset(0.43, 0.48),
    20: Offset(0.67, 0.45),
    21: Offset(0.44, 0.49),
    22: Offset(0.70, 0.46),
    23: Offset(0.53, 0.54),
    24: Offset(0.57, 0.54),
    25: Offset(0.68, 0.66),
    26: Offset(0.45, 0.67),
    27: Offset(0.78, 0.82),
    28: Offset(0.34, 0.85),
    29: Offset(0.74, 0.85),
    30: Offset(0.30, 0.88),
    31: Offset(0.84, 0.86),
    32: Offset(0.39, 0.89),
  };
  return RunningPoseFrame(
    timestamp: Duration.zero,
    imageWidth: 720,
    imageHeight: 1280,
    landmarks: List<RunningVideoPoseLandmark>.unmodifiable([
      for (var index = 0; index < mediaPipePoseLandmarkCount; index += 1)
        RunningVideoPoseLandmark(
          index: index,
          x: points[index]?.dx ?? 0.5,
          y: points[index]?.dy ?? 0.5,
          z: 0,
          visibility: points.containsKey(index) ? 0.95 : 0,
          presence: points.containsKey(index) ? 0.95 : 0,
          confidence: points.containsKey(index) ? 0.95 : 0,
        ),
    ]),
  );
}
