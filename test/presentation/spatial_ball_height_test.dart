import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/real_match_replay.dart';
import 'package:football_note/domain/scan_pass/scan_pass_spatial_focus.dart';
import 'package:football_note/domain/scan_pass/scan_pass_spatial_library.dart';
import 'package:football_note/presentation/screens/scan_pass_game_screen.dart';

void main() {
  late SpatialLibraryScene scene;
  late RealMatchReplayData data;
  late SpatialFocusPlan focusPlan;
  late int groundFrame;
  late int highFrame;
  late int unknownFrame;

  setUpAll(() {
    final catalog = SpatialLibraryCatalog.fromJsonString(
      File('assets/scan_pass_spatial/education-catalog.json')
          .readAsStringSync(),
    );
    scene = catalog.scenes.firstWhere(
      (value) => value.id == '2269-32665-caleta-car-lateralSwitch',
    );
    data = RealMatchReplayData.fromJsonString(
      File(scene.asset).readAsStringSync(),
    );
    focusPlan = SpatialFocusPlan.build(data, scene);
    groundFrame = <int>[
      for (var index = 0; index < data.frames.length; index++)
        if (data.isBallHeightValidAtFrame(index) &&
            data.frames[index].last == 0)
          index,
    ].first;
    highFrame = <int>[
      for (var index = 0; index < data.frames.length; index++)
        if (data.isBallHeightValidAtFrame(index)) index,
    ].reduce(
      (first, second) =>
          data.frames[first].last >= data.frames[second].last ? first : second,
    );
    unknownFrame = <int>[
      for (var index = 0; index < data.frames.length; index++)
        if (!data.isBallHeightValidAtFrame(index)) index,
    ].first;
  });

  for (final size in const <Size>[
    Size(390, 844),
    Size(320, 740),
    Size(667, 320),
  ]) {
    test('ground, high and unknown ball geometry stays safe at $size', () {
      SpatialBallScreenGeometry geometryAt(int frame) {
        final time = frame / data.fps;
        final viewport = SpatialPitchViewport.fit(
          focusPlan.cameraAt(time),
          size,
          portrait: SpatialPitchViewport.bestRotation(
            focusPlan.teachingCamera,
            size,
          ),
          fieldLength: data.pitchLength,
          fieldWidth: data.pitchWidth,
        );
        final geometry = SpatialBallScreenGeometry.forReplay(
          data: data,
          time: time,
          viewport: viewport,
        );
        expect(geometry.groundAnchor, viewport.project(data.sample(time).ball));
        expect(viewport.view.contains(geometry.shadowRect.topLeft), isTrue);
        expect(viewport.view.contains(geometry.shadowRect.bottomRight), isTrue);
        expect(viewport.view.contains(geometry.ballRect.topLeft), isTrue);
        expect(viewport.view.contains(geometry.ballRect.bottomRight), isTrue);
        expect(viewport.view.contains(geometry.safetyRect.topLeft), isTrue);
        expect(viewport.view.contains(geometry.safetyRect.bottomRight), isTrue);
        return geometry;
      }

      final ground = geometryAt(groundFrame);
      final high = geometryAt(highFrame);
      final unknown = geometryAt(unknownFrame);

      expect(ground.heightKnown, isTrue);
      expect(ground.heightMeters, 0);
      expect(
        ground.groundAnchor.dy - ground.ballRect.center.dy,
        closeTo(4, .001),
      );
      expect(high.heightKnown, isTrue);
      expect(high.heightMeters, 9.74);
      final expectedHighLift = math.min(
        58.0,
        math.max(
          0.0,
          high.groundAnchor.dy -
              2 -
              high.ballRect.width / 2 -
              SpatialBallScreenGeometry.safetyPadding,
        ),
      );
      expect(
        high.groundAnchor.dy - high.ballRect.center.dy,
        closeTo(expectedHighLift, .001),
      );
      expect(expectedHighLift, greaterThan(4));
      expect(high.ballRect.width, greaterThan(ground.ballRect.width));
      expect(high.shadowRect.width, lessThan(ground.shadowRect.width));
      expect(unknown.heightKnown, isFalse);
      expect(unknown.heightMeters, isNull);
      expect(
        unknown.groundAnchor.dy - unknown.ballRect.center.dy,
        closeTo(10, .001),
      );
    });
  }

  test('painter exposes the full elevated footprint for labels and cues', () {
    final time = highFrame / data.fps;
    const size = Size(390, 640);
    final viewport = SpatialPitchViewport.fit(
      focusPlan.cameraAt(time),
      size,
      portrait: SpatialPitchViewport.bestRotation(
        focusPlan.teachingCamera,
        size,
      ),
      fieldLength: data.pitchLength,
      fieldWidth: data.pitchWidth,
    );
    final lesson = scene.education!;
    final names = <int>{
      lesson.focusActor.playerId,
      ...lesson.supportActors.map((actor) => actor.playerId),
      ...lesson.opponentActors.map((actor) => actor.playerId),
    };
    final painter = SpatialLibraryPitchPainter(
      data: data,
      scene: scene,
      focusPlan: focusPlan,
      viewport: viewport,
      time: time,
      brightness: Brightness.dark,
      portrait: viewport.portrait,
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      roles: scene.observedRoles(data, time),
      requiredPlayerIds: names,
      nameLabelPlayerIds: names,
    );

    expect(painter.ballSafetyRect, painter.ballGeometry.safetyRect);
    expect(
        painter.ballSafetyRect.contains(painter.ballGeometry.ballRect.center),
        isTrue);
    expect(
      painter.ballSafetyRect.contains(painter.ballGeometry.groundAnchor),
      isTrue,
    );
    expect(
      painter.playerNameLabels
          .any((label) => label.rect.overlaps(painter.ballSafetyRect)),
      isFalse,
    );
  });

  test('backward seeks and repeated samples use one source clock', () {
    final highTime = highFrame / data.fps;
    final unknownTime = unknownFrame / data.fps;
    final firstHigh = data.renderSample(highTime);
    final gap = data.renderSample(unknownTime);
    final secondHigh = data.renderSample(highTime);

    expect(firstHigh.sourceFrame, highFrame);
    expect(firstHigh.ballHeightKnown, isTrue);
    expect(firstHigh.ball.z, 9.74);
    expect(gap.sourceFrame, unknownFrame);
    expect(gap.ballHeightKnown, isFalse);
    expect(gap.ball.z, 0);
    expect(secondHigh.sourceFrame, firstHigh.sourceFrame);
    expect(secondHigh.ball.z, firstHigh.ball.z);
    expect(data.heightAt(highTime), secondHigh.ball.z);
  });
}
