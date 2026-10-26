import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/real_match_replay.dart';
import 'package:football_note/presentation/scan_pass/replay_pitch_geometry.dart';

void main() {
  late RealMatchReplayCatalog catalog;
  late Map<String, RealMatchReplayData> scenes;

  setUpAll(() {
    catalog = RealMatchReplayCatalog.fromJsonString(
      File('assets/scan_pass_replay/catalog.json').readAsStringSync(),
    );
    scenes = <String, RealMatchReplayData>{
      for (final entry in catalog.scenes)
        entry.id: RealMatchReplayData.fromJsonString(
          File(entry.asset).readAsStringSync(),
        ),
    };
  });

  test('both attack directions normalize forward play right or up', () {
    const camera = RealMatchReplayCamera(
      minX: -40,
      maxX: 40,
      minY: -25,
      maxY: 25,
    );
    final right = ReplayPitchGeometry.forSize(
      const Size(1000, 620),
      camera: camera,
      attackDirection: 1,
    );
    final reversed = ReplayPitchGeometry.forSize(
      const Size(1000, 620),
      camera: camera,
      attackDirection: -1,
    );
    final portrait = ReplayPitchGeometry.forSize(
      const Size(380, 640),
      camera: camera,
      attackDirection: -1,
    );

    expect(right.project(20, 0).dx, greaterThan(right.project(-20, 0).dx));
    expect(
      reversed.project(-20, 0).dx,
      greaterThan(reversed.project(20, 0).dx),
    );
    expect(
      portrait.project(-20, 0).dy,
      lessThan(portrait.project(20, 0).dy),
    );
  });

  test('coaching geometry preserves deliberate tight camera bounds', () {
    const camera = RealMatchReplayCamera(
      minX: 5,
      maxX: 35,
      minY: -11,
      maxY: 11,
    );
    final context = ReplayPitchGeometry.forSize(
      const Size(1200, 700),
      camera: camera,
    );
    final close = ReplayPitchGeometry.forSize(
      const Size(1200, 700),
      camera: camera,
      view: ReplayPitchView.close,
    );
    final coaching = ReplayPitchGeometry.forSize(
      const Size(1200, 700),
      camera: camera,
      view: ReplayPitchView.coaching,
    );
    final full = ReplayPitchGeometry.forSize(
      const Size(1200, 700),
      camera: camera,
      view: ReplayPitchView.full,
    );

    expect(context.camera.width, greaterThanOrEqualTo(65));
    expect(close.camera.width, 44);
    expect(coaching.camera.width, 30);
    expect(coaching.camera.height, 22);
    expect(full.camera.minX, lessThan(-52.5));
    expect(full.camera.maxX, greaterThan(52.5));
  });

  test('automatic cameras stay continuous and keep ball and actors visible',
      () {
    for (final entry in catalog.scenes) {
      final data = scenes[entry.id]!;
      final plan = RealMatchReplayCoachingPlan.forData(data);
      for (final moment in plan.moments.skip(1)) {
        final before = plan.cameraAt(data, moment.time - .00002);
        final after = plan.cameraAt(
          data,
          math.min(data.duration, moment.time + .00002),
        );
        for (final edgeDelta in <double>[
          (before.minX - after.minX).abs(),
          (before.maxX - after.maxX).abs(),
          (before.minY - after.minY).abs(),
          (before.maxY - after.maxY).abs(),
        ]) {
          expect(edgeDelta, lessThan(.02),
              reason: '${entry.id} camera boundary t=${moment.time}');
        }
      }
      RealMatchReplayCamera? previous;
      for (var time = 0.0; time <= data.duration; time += .1) {
        final sourceTime = math.min(time, data.duration);
        final camera = plan.cameraAt(data, sourceTime);
        if (previous != null) {
          expect((camera.minX - previous.minX).abs(), lessThan(4),
              reason: '${entry.id} minX t=$time');
          expect((camera.maxX - previous.maxX).abs(), lessThan(4),
              reason: '${entry.id} maxX t=$time');
          expect((camera.minY - previous.minY).abs(), lessThan(4),
              reason: '${entry.id} minY t=$time');
          expect((camera.maxY - previous.maxY).abs(), lessThan(4),
              reason: '${entry.id} maxY t=$time');
        }
        previous = camera;
        final moment = plan.moments[plan.momentIndexAt(sourceTime)];
        final sample = data.renderSample(sourceTime);
        for (final size in const <Size>[
          Size(320, 520),
          Size(844, 230),
          Size(1400, 760),
        ]) {
          final geometry = ReplayPitchGeometry.forSize(
            size,
            camera: camera,
            attackDirection: data.scene.attackDirection,
            view: ReplayPitchView.coaching,
            pitchLength: data.pitchLength,
            pitchWidth: data.pitchWidth,
            headerInset: 58,
            bottomInset: 18,
          );
          final canvas = Offset.zero & size;
          final ball = geometry.project(
            sample.ball.x,
            sample.ball.y,
            sample.ball.z,
          );
          expect(canvas.inflate(3).contains(ball), isTrue,
              reason: '${entry.id} $size ball t=$time $ball');
          final relevantIds = switch (moment.step.kind) {
            RealMatchReplayStepKind.pass => <int>{
                if (moment.step.targetId != null) moment.step.targetId!,
              },
            RealMatchReplayStepKind.outcome => const <int>{},
            RealMatchReplayStepKind.carry ||
            RealMatchReplayStepKind.receive ||
            RealMatchReplayStepKind.run =>
              <int>{moment.step.actorId},
            RealMatchReplayStepKind.pressure => <int>{
                moment.step.actorId,
                if (moment.step.secondaryId != null) moment.step.secondaryId!,
              },
            _ => <int>{
                moment.step.actorId,
                if (moment.step.targetId != null) moment.step.targetId!,
              },
          };
          for (final id in relevantIds) {
            final player = sample.players[data.playerIndex(id)];
            final projected = geometry.project(player.x, player.y);
            expect(canvas.inflate(3).contains(projected), isTrue,
                reason: '${entry.id} $size player=$id t=$time $projected');
          }
        }
      }
    }
  });

  test('close teaching moments tighten then return to source context', () {
    for (final entry in catalog.scenes) {
      final data = scenes[entry.id]!;
      final plan = RealMatchReplayCoachingPlan.forData(data);
      for (var index = 0; index < plan.moments.length; index++) {
        final moment = plan.moments[index];
        if (moment.view != RealMatchReplayCoachingView.close) continue;
        final close = plan.cameraAt(data, moment.time);
        expect(close.width, lessThan(data.scene.camera.width),
            reason: '${entry.id} t=${moment.time}');
        final nextContext = plan.moments.skip(index + 1).where(
              (candidate) =>
                  candidate.view == RealMatchReplayCoachingView.context,
            );
        if (nextContext.isNotEmpty) {
          final context = plan.cameraAt(data, nextContext.first.time);
          expect(context.width, closeTo(data.scene.camera.width, 1e-6),
              reason: '${entry.id} context after t=${moment.time}');
        }
      }
    }
  });

  test('single cue layout avoids the ball and relevant bodies at 320px', () {
    const stage = Size(320, 500);
    const ball = Rect.fromLTWH(148, 220, 20, 20);
    const actor = Rect.fromLTWH(190, 175, 38, 56);
    final labels = ReplayLabelLayout.place(
      stageSize: stage,
      topInset: 66,
      bottomInset: 22,
      labelSizes: const <Size>[Size(158, 52)],
      anchors: const <Offset>[Offset(205, 205)],
      obstacles: const <Rect>[ball, actor],
      protectedObstacles: const <Rect>[ball, actor],
    );

    expect(labels.single.isEmpty, isFalse);
    expect(labels.single.overlaps(ball), isFalse);
    expect(labels.single.overlaps(actor), isFalse);
    expect((Offset.zero & stage).contains(labels.single.topLeft), isTrue);
    expect((Offset.zero & stage).contains(labels.single.bottomRight), isTrue);
  });
}
