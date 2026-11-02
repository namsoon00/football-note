import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/real_match_replay.dart';
import 'package:football_note/domain/scan_pass/scan_pass_spatial_library.dart';
import 'package:football_note/presentation/screens/scan_pass_game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all five athlete assets exist, decode, and retain transparency',
      () async {
    expect(
      SpatialActionPictogramAssets.specs.keys,
      containsAll(SpatialOnPitchActionKind.values),
    );
    expect(
      SpatialActionPictogramAssets.specs.values
          .map((spec) => spec.assetPath)
          .toSet(),
      hasLength(SpatialOnPitchActionKind.values.length),
    );

    for (final kind in SpatialOnPitchActionKind.values) {
      final spec = SpatialActionPictogramAssets.spec(kind);
      final file = File(spec.assetPath);
      expect(file.existsSync(), isTrue, reason: '${spec.assetPath} is missing');
      final codec = await ui.instantiateImageCodec(await file.readAsBytes());
      final frame = await codec.getNextFrame();
      final image = frame.image;
      expect(image.width, image.height,
          reason: '${spec.assetPath} is not square');
      expect(image.width, greaterThanOrEqualTo(256));
      final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(rgba, isNotNull);
      var transparentPixels = 0;
      var visiblePixels = 0;
      for (var offset = 3; offset < rgba!.lengthInBytes; offset += 4) {
        final alpha = rgba.getUint8(offset);
        if (alpha == 0) transparentPixels++;
        if (alpha > 0) visiblePixels++;
      }
      expect(transparentPixels, greaterThan(0));
      expect(visiblePixels, greaterThan(0));
      image.dispose();
      codec.dispose();
    }
  });

  testWidgets('all five athlete poses load through the runtime image provider',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: <Widget>[
              for (final kind in SpatialOnPitchActionKind.values)
                SizedBox.square(
                  dimension: 40,
                  child: SpatialActionPictogram(
                    kind: kind,
                    phase: const SpatialActionGesturePhase(
                      progress: 1,
                      elapsedSourceSeconds: 1,
                      reducedMotion: false,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final kind in SpatialOnPitchActionKind.values) {
      expect(
        find.byKey(ValueKey<String>('spatial-action-athlete-${kind.name}')),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  test('football stays inside every badge at the supplied contact anchor', () {
    for (final sizeValue in const <double>[32, 36, 40]) {
      final size = Size.square(sizeValue);
      final bounds = Offset.zero & size;
      for (final kind in SpatialOnPitchActionKind.values) {
        final painter = SpatialActionGesturePainter(
          kind: kind,
          phase: const SpatialActionGesturePhase(
            progress: 1,
            elapsedSourceSeconds: 1,
            reducedMotion: true,
          ),
          foreground: true,
        );
        final geometry = painter.gestureGeometry(size);
        final anchor = SpatialActionPictogramAssets.spec(kind).contactAnchor;
        expect(
          geometry.contactCenter,
          Offset(anchor.dx * size.width, anchor.dy * size.height),
        );
        expect(geometry.ballCenter, geometry.contactCenter);
        expect(bounds.contains(geometry.ballBounds.topLeft), isTrue);
        expect(bounds.contains(geometry.ballBounds.bottomRight), isTrue);
        expect(geometry.contactCount, 1);
        expect(geometry.loops, isFalse);
        for (final route in geometry.routePaths) {
          expect(bounds.contains(route.getBounds().topLeft), isTrue);
          expect(bounds.contains(route.getBounds().bottomRight), isTrue);
        }
      }
    }
  });

  test('receive arrives and holds while one-touch arrives then departs once',
      () {
    SpatialActionGestureGeometry geometry(
      SpatialOnPitchActionKind kind,
      double progress,
    ) =>
        SpatialActionGesturePainter(
          kind: kind,
          phase: SpatialActionGesturePhase(
            progress: progress,
            elapsedSourceSeconds:
                progress * SpatialActionMotion.durationSeconds,
            reducedMotion: false,
          ),
          foreground: true,
        ).gestureGeometry(const Size.square(40));

    final receiveIncoming = geometry(SpatialOnPitchActionKind.receive, .25);
    final receiveContact = geometry(
      SpatialOnPitchActionKind.receive,
      SpatialActionMotion.receiveContactFraction,
    );
    final receiveFinished = geometry(SpatialOnPitchActionKind.receive, 1);
    expect(receiveIncoming.ballCenter, isNot(receiveIncoming.contactCenter));
    expect(receiveContact.ballCenter, receiveContact.contactCenter);
    expect(receiveFinished.ballCenter, receiveFinished.contactCenter);
    expect(receiveFinished.holdsAtContact, isTrue);

    final passIncoming = geometry(SpatialOnPitchActionKind.oneTouchPass, .1);
    final passContact = geometry(
      SpatialOnPitchActionKind.oneTouchPass,
      SpatialActionMotion.oneTouchContactFraction,
    );
    final passDeparting = geometry(SpatialOnPitchActionKind.oneTouchPass, .7);
    final passFinished = geometry(SpatialOnPitchActionKind.oneTouchPass, 1);
    expect(passIncoming.ballCenter, isNot(passIncoming.contactCenter));
    expect(passContact.ballCenter, passContact.contactCenter);
    expect(passContact.holdsAtContact, isTrue);
    expect(passDeparting.ballCenter, isNot(passDeparting.contactCenter));
    expect(
      (passFinished.ballCenter - passFinished.contactCenter).distance,
      greaterThan(
        (passDeparting.ballCenter - passDeparting.contactCenter).distance,
      ),
    );
    expect(passFinished.contactCount, 1);
    expect(passFinished.loops, isFalse);
    expect(passFinished.holdsAtContact, isFalse);
  });

  test('gesture phase is deterministic under pause, backward seek, and reduce',
      () {
    final catalog = SpatialLibraryCatalog.fromJsonString(
      File('assets/scan_pass_spatial/education-catalog.json')
          .readAsStringSync(),
    );
    final scene = catalog.scenes.firstWhere(
      (value) => value.id == '1925299-185-560983-thirdPlayer',
    );
    final data = RealMatchReplayData.fromJsonString(
      File(scene.asset).readAsStringSync(),
    );
    final action = scene.sourceActionAt(data, 11.1)!;
    expect(action.kind, SpatialOnPitchActionKind.receive);

    SpatialActionGesturePhase phase(double time, {bool reduced = false}) =>
        SpatialActionMotion.phaseAt(
          action: action,
          scene: scene,
          data: data,
          time: time,
          reducedMotion: reduced,
        );

    final initial = phase(11.1);
    final paused = phase(11.1);
    final subframeAdvance = phase(11.15);
    final advanced = phase(11.5);
    final soughtBack = phase(11.1);
    expect(paused.progress, initial.progress);
    expect(paused.elapsedSourceSeconds, initial.elapsedSourceSeconds);
    expect(subframeAdvance.progress, greaterThan(initial.progress));
    expect(phase(11.15).progress, subframeAdvance.progress);
    expect(
      subframeAdvance.elapsedSourceSeconds - initial.elapsedSourceSeconds,
      closeTo(.05, .0001),
    );
    expect(advanced.progress, greaterThan(initial.progress));
    expect(soughtBack.progress, initial.progress);
    expect(soughtBack.elapsedSourceSeconds, initial.elapsedSourceSeconds);

    final reduced = phase(11.1, reduced: true);
    expect(reduced.progress, SpatialActionMotion.receiveContactFraction);
    expect(reduced.reducedMotion, isTrue);
    final staticGeometry = SpatialActionGesturePainter(
      kind: action.kind,
      phase: reduced,
      foreground: true,
    ).gestureGeometry(const Size.square(40));
    expect(staticGeometry.ballCenter, staticGeometry.contactCenter);
    expect(staticGeometry.holdsAtContact, isTrue);
  });

  test('clamped 44px hit target preserves the exact visual rectangle', () {
    const bounds = Rect.fromLTWH(0, 0, 100, 80);
    const visual = Rect.fromLTWH(0, 20, 40, 40);
    final hit = SpatialActionIconGeometry.clampTarget(
      Rect.fromCenter(center: visual.center, width: 44, height: 44),
      bounds,
    );
    final geometry = SpatialActionIconGeometry(
      actorPlayerId: 1,
      kind: SpatialOnPitchActionKind.carry,
      eventId: 'event',
      visualRect: visual,
      hitRect: hit,
      actorBadgeRect: const Rect.fromLTWH(46, 20, 30, 30),
      placementIndex: 0,
    );

    expect(hit, const Rect.fromLTWH(0, 18, 44, 44));
    expect(geometry.hitTargetContainsVisual, isTrue);
    expect(
      geometry.visualRectInsideHitTarget.shift(geometry.hitRect.topLeft),
      visual,
    );
  });
}
