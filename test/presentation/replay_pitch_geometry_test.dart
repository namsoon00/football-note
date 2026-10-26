import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/real_match_replay.dart';
import 'package:football_note/presentation/scan_pass/replay_pitch_geometry.dart';

void main() {
  test('focused camera rotates the same world view on narrow stages', () {
    final desktop = ReplayPitchGeometry.forSize(const Size(900, 560));
    final mobile = ReplayPitchGeometry.forSize(const Size(360, 520));

    expect(desktop.rotated, isFalse);
    expect(mobile.rotated, isTrue);
    expect(desktop.project(56, 0).dx, greaterThan(desktop.project(-5, 0).dx));
    expect(mobile.project(56, 0).dy, lessThan(mobile.project(-5, 0).dy));
    expect(mobile.project(0, 35).dx, greaterThan(mobile.project(0, -5).dx));
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

  test('context is broad, close is stable, and full view includes both goals',
      () {
    const camera = RealMatchReplayCamera(
      minX: 5,
      maxX: 35,
      minY: -12,
      maxY: 14,
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
    final full = ReplayPitchGeometry.forSize(
      const Size(1200, 700),
      camera: camera,
      view: ReplayPitchView.full,
    );

    expect(context.camera.width, greaterThanOrEqualTo(65));
    expect(context.camera.height, greaterThanOrEqualTo(48));
    expect(close.camera.width, 44);
    expect(close.camera.height, 34);
    expect(full.camera.minX, lessThan(-52.5));
    expect(full.camera.maxX, greaterThan(52.5));
  });

  test('scene context keeps the ball and focal player on screen', () {
    final catalog = RealMatchReplayCatalog.fromJsonString(
      File('assets/scan_pass_replay/catalog.json').readAsStringSync(),
    );
    for (final entry in catalog.scenes) {
      final data = RealMatchReplayData.fromJsonString(
        File(entry.asset).readAsStringSync(),
      );
      for (final size in const <Size>[Size(360, 520), Size(1400, 760)]) {
        final geometry = ReplayPitchGeometry.forSize(
          size,
          camera: data.scene.camera,
          attackDirection: data.scene.attackDirection,
          pitchLength: data.pitchLength,
          pitchWidth: data.pitchWidth,
        );
        for (final time in <double>[
          0,
          ...data.scene.steps.map((step) => step.time),
          data.duration,
        ]) {
          final sample = data.renderSample(time);
          final ball = geometry.project(
            sample.ball.x,
            sample.ball.y,
            sample.ball.z,
          );
          final focus = geometry.project(
            sample.players[data.playerIndex(data.scene.focusPlayerId)].x,
            sample.players[data.playerIndex(data.scene.focusPlayerId)].y,
          );
          final canvas = Offset.zero & size;
          expect(canvas.inflate(2).contains(ball), isTrue,
              reason: '${entry.id} $size ball t=$time $ball');
          expect(canvas.inflate(2).contains(focus), isTrue,
              reason: '${entry.id} $size focus t=$time $focus');
        }
      }
    }
  });

  test('annotation layout avoids ball, body, zoom and other labels', () {
    const zoom = Rect.fromLTWH(9, 88, 132, 190);
    const ball = Rect.fromLTWH(170, 210, 20, 20);
    const body = Rect.fromLTWH(250, 160, 30, 80);
    final labels = ReplayLabelLayout.place(
      stageSize: const Size(360, 520),
      labelSizes: const <Size>[Size(124, 42), Size(118, 42)],
      anchors: const <Offset>[Offset(180, 220), Offset(265, 195)],
      obstacles: const <Rect>[zoom, ball, body],
    );

    expect(labels, hasLength(2));
    expect(labels[0].overlaps(zoom), isFalse);
    expect(labels[0].overlaps(ball), isFalse);
    expect(labels[0].overlaps(body), isFalse);
    expect(labels[1].overlaps(zoom), isFalse);
    expect(labels[1].overlaps(ball), isFalse);
    expect(labels[1].overlaps(body), isFalse);
    expect(labels[0].overlaps(labels[1]), isFalse);
  });

  test(
      'actual match callouts stay clear of the ball and pose card in all locales',
      () {
    final data = RealMatchReplayData.fromJsonString(
      File('assets/scan_pass_replay/replay-data.json').readAsStringSync(),
    );
    final receiver = data.playerIndex(965698);
    final carrier = data.playerIndex(287934);
    final defender19 = data.playerIndex(11897);
    final defender17 = data.playerIndex(795533);
    final keeper = data.playerIndex(560985);
    const labelKeys = <RealMatchReplayPhase, List<String>>{
      RealMatchReplayPhase.prepare: [
        'realMatchReplayAnnotationCarry8',
        'realMatchReplayAnnotationMove18',
      ],
      RealMatchReplayPhase.spacePass: [
        'realMatchReplayAnnotationReceivingSpace',
        'realMatchReplayAnnotationConnect18',
      ],
      RealMatchReplayPhase.advance: [
        'realMatchReplayAnnotationAdvance18',
        'realMatchReplayAnnotationRecover19',
      ],
      RealMatchReplayPhase.recovery: [
        'realMatchReplayAnnotationTurn18',
        'realMatchReplayAnnotationClose1917',
      ],
      RealMatchReplayPhase.outcome: [
        'realMatchReplayAnnotationShotPath',
        'realMatchReplayAnnotationKeeperPossession',
      ],
    };
    for (final locale in <String>['en', 'ko', 'ja']) {
      final copy =
          jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
              as Map<String, dynamic>;
      for (final stageSize in <Size>[
        const Size(304, 380),
        const Size(344, 404),
        const Size(304, 520),
        const Size(344, 520),
        const Size(744, 560),
        const Size(980, 620),
      ]) {
        final geometry = ReplayPitchGeometry.forSize(stageSize);
        for (final time in <double>[0, 2.8, 5, 6, 9.4, 11.22, 12.32]) {
          final sample = data.sample(time);
          final phase = data.phaseAt(time);
          final points = switch (phase) {
            RealMatchReplayPhase.prepare => [
                sample.players[carrier],
                sample.players[receiver]
              ],
            RealMatchReplayPhase.spacePass => [
                data.sample(4.22).ball,
                sample.players[receiver]
              ],
            RealMatchReplayPhase.advance => [
                sample.players[receiver],
                sample.players[defender19]
              ],
            RealMatchReplayPhase.recovery => [
                sample.players[receiver],
                sample.players[defender17]
              ],
            RealMatchReplayPhase.outcome => [
                sample.ball,
                sample.players[keeper]
              ],
          };
          final anchors =
              points.map((p) => geometry.project(p.x, p.y, p.z)).toList();
          final ball = Rect.fromCircle(
            center:
                geometry.project(sample.ball.x, sample.ball.y, sample.ball.z),
            radius: 10,
          );
          for (final scale in <double>[1, 1.4]) {
            // The screen gives larger text a minimum 520px pitch so labels
            // and its optional pose card can remain readable together.
            if (scale > 1.2 && stageSize.height < 520) continue;
            final labelSizes = labelKeys[phase]!.map((key) {
              final painter = TextPainter(
                text: TextSpan(
                    text: copy[key] as String,
                    style: const TextStyle(
                        fontSize: 11,
                        height: 1.25,
                        fontWeight: FontWeight.w600)),
                textDirection: TextDirection.ltr,
                textScaler: TextScaler.linear(scale),
                maxLines: 3,
              )..layout(maxWidth: 128);
              final size = Size(painter.width + 16, painter.height + 12);
              painter.dispose();
              return size;
            }).toList();
            for (final zoomVisible in <bool>[false, true]) {
              final zoom = geometry.zoomRect(
                  visible: zoomVisible,
                  finalPhase: phase == RealMatchReplayPhase.outcome);
              final labels = ReplayLabelLayout.place(
                stageSize: stageSize,
                topInset: geometry.origin.dy + 4,
                labelSizes: labelSizes,
                anchors: anchors,
                protectedObstacles: [ball, if (zoomVisible) zoom],
                obstacles: [
                  for (final p in sample.players)
                    Rect.fromLTWH(geometry.project(p.x, p.y).dx - 14,
                        geometry.project(p.x, p.y).dy - 32, 28, 42),
                  ball,
                  if (zoomVisible) zoom,
                ],
              );
              final reason =
                  '$locale $stageSize t=$time scale=$scale zoom=$zoomVisible '
                  'sizes=$labelSizes labels=$labels ball=$ball card=$zoom';
              expect(labels[0].overlaps(labels[1]), isFalse, reason: reason);
              for (final rect in labels) {
                expect(rect.isEmpty, isFalse, reason: reason);
                expect(rect.overlaps(ball), isFalse, reason: reason);
                if (zoomVisible) {
                  expect(rect.overlaps(zoom), isFalse, reason: reason);
                }
                expect((Offset.zero & stageSize).contains(rect.topLeft), isTrue,
                    reason: reason);
                expect((Offset.zero & stageSize).contains(rect.bottomRight),
                    isTrue,
                    reason: reason);
                expect(
                    rect.bottom,
                    lessThanOrEqualTo(stageSize.height -
                        ReplayLabelLayout.bottomControlsInset),
                    reason: reason);
              }
            }
          }
        }
      }
    }
  });
}
