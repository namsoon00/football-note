import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/scan_pass/real_match_replay.dart';
import 'package:football_note/domain/scan_pass/scan_pass_spatial_focus.dart';
import 'package:football_note/domain/scan_pass/scan_pass_spatial_library.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/scan_pass_game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SpatialLibraryCatalog fullCatalog;
  late SpatialLibraryCatalog catalog;
  late Map<String, RealMatchReplayData> data;

  setUpAll(() {
    fullCatalog = SpatialLibraryCatalog.fromJsonString(
      File('assets/scan_pass_spatial/catalog.json').readAsStringSync(),
    );
    catalog = _catalogWith(fullCatalog, fullCatalog.scenes.take(4).toList());
    data = {
      for (final scene in catalog.scenes)
        scene.id: RealMatchReplayData.fromJsonString(
          File(scene.asset).readAsStringSync(),
        ),
    };
  });

  testWidgets('public entry opens the pitch-first famous-match library',
      (tester) async {
    await tester.pumpWidget(_app(
      home: ScanPassGameScreen(optionRepository: _Options()),
    ));
    await _pumpLoaded(tester);

    expect(find.byType(ScanPassSpatialLibraryScreen), findsOneWidget);
    expect(find.byType(ScanPassRealMatchReplayScreen), findsNothing);
    expect(find.byKey(const ValueKey<String>('spatial-pitch')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('spatial-play')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('spatial-next')), findsOneWidget);
    expect(
        find.byKey(const ValueKey<String>('spatial-minimap')), findsOneWidget);
    expect(find.text('Inferred display position'), findsNothing);
    expect(find.byKey(const ValueKey<String>('replay-pitch')), findsNothing);
    expect(find.textContaining('Brisbane Roar'), findsNothing);
    final systemUi = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byKey(const ValueKey<String>('spatial-system-ui')),
    );
    expect(systemUi.value.statusBarIconBrightness, Brightness.light);
    expect(systemUi.value.systemNavigationBarIconBrightness, Brightness.light);
    final opener = fullCatalog.scenes.first;
    expect(find.textContaining(opener.date), findsOneWidget);
    expect(find.textContaining('BEFORE'), findsOneWidget);
    expect(find.textContaining(opener.evidenceAnchors.last.playerName),
        findsNothing);
    expect(
        find.textContaining(opener.period == 1 ? '1H' : '2H'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('whole passage plays at source speed and pauses with lifecycle',
      (tester) async {
    await tester.pumpWidget(_catalogApp(catalog, data));
    await _pumpLoaded(tester);
    expect(_sourceTime(tester), 0);

    await tester.tap(find.byKey(const ValueKey<String>('spatial-play')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    expect(_sourceTime(tester), closeTo(1.1, .15));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    final paused = _sourceTime(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(_sourceTime(tester), closeTo(paused, .01));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.tap(find.byKey(const ValueKey<String>('spatial-play')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(_sourceTime(tester), greaterThan(paused + .5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('play control has names for play, pause, and replay states',
      (tester) async {
    await tester.pumpWidget(_catalogApp(catalog, data));
    await _pumpLoaded(tester);
    final play = find.byKey(const ValueKey<String>('spatial-play'));
    final l10n = AppLocalizations.of(tester.element(play))!;

    expect(tester.getSemantics(play).label, contains(l10n.realMatchReplayPlay));
    await tester.tap(play);
    await tester.pump();
    expect(tester.getSemantics(play).label,
        contains(l10n.realMatchReplayPauseAction));

    await tester.pump(
      Duration(
        milliseconds: (catalog.scenes.first.duration * 1000).round() + 1000,
      ),
    );
    await tester.pump();
    expect(tester.getSemantics(play).label,
        contains(l10n.realMatchReplayReplayAction));
    expect(tester.takeException(), isNull);
  });

  testWidgets('focused replay is half speed only for the evidenced moment',
      (tester) async {
    await tester.pumpWidget(_catalogApp(catalog, data));
    await _pumpLoaded(tester);
    final scene = catalog.scenes.first;

    await _openMenu(tester);
    await tester
        .tap(find.byKey(const ValueKey<String>('spatial-focus-replay')));
    await tester.pump();
    expect(_sourceTime(tester), closeTo(scene.evidenceStart, .05));
    expect(find.text('Key moment at 0.5×, then source speed'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(_sourceTime(tester), closeTo(scene.evidenceStart + .5, .12));
    expect(tester.takeException(), isNull);
  });

  testWidgets('rapid scene requests ignore a stale asynchronous load',
      (tester) async {
    final slow = Completer<RealMatchReplayData>();
    await tester.pumpWidget(_app(
      home: ScanPassSpatialLibraryScreen(
        catalogLoader: () async => catalog,
        sceneLoader: (scene) {
          if (scene.id == catalog.scenes[1].id) return slow.future;
          return Future.value(data[scene.id]!);
        },
      ),
    ));
    await _pumpLoaded(tester);

    final next = find.byKey(const ValueKey<String>('spatial-next'));
    await tester.tap(next);
    await tester.tap(next);
    await tester.pump();
    await _pumpLoaded(tester);
    expect(_painter(tester).scene.id, catalog.scenes[2].id);

    slow.complete(data[catalog.scenes[1].id]!);
    await tester.pump();
    expect(_painter(tester).scene.id, catalog.scenes[2].id);
    expect(tester.takeException(), isNull);
  });

  testWidgets('previous wraps and bottom title opens the picker',
      (tester) async {
    await tester.pumpWidget(_catalogApp(catalog, data));
    await _pumpLoaded(tester);
    final previous = find.byKey(const ValueKey<String>('spatial-previous'));
    final l10n = AppLocalizations.of(tester.element(previous))!;
    expect(tester.getSemantics(previous).label,
        contains(l10n.spatialPreviousScene));

    await tester.tap(previous);
    await _pumpScene(tester, catalog.scenes.last.id);
    expect(_painter(tester).scene.id, catalog.scenes.last.id);

    await tester
        .tap(find.byKey(const ValueKey<String>('spatial-scene-selector')));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey<String>('spatial-search')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scene picker searches players and filters one theme',
      (tester) async {
    await tester.pumpWidget(_catalogApp(fullCatalog, data));
    await _pumpLoaded(tester);
    final target = fullCatalog.scenes
        .firstWhere((scene) => scene.focusPlayerName.contains('Messi'));

    await tester
        .tap(find.byKey(const ValueKey<String>('spatial-scene-selector')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Famous-match library · 108 scenes'),
        findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey<String>('spatial-search')),
      'Messi',
    );
    await tester.pump();
    expect(find.byKey(ValueKey<String>('spatial-scene-${target.id}')),
        findsOneWidget);
    expect(find.textContaining('Salah'), findsNothing);

    await tester.tap(
      find.byKey(ValueKey<String>('spatial-theme-${target.theme.name}')),
    );
    await tester.pump();
    expect(find.byKey(ValueKey<String>('spatial-scene-${target.id}')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scene picker matches localized themes and star aliases',
      (tester) async {
    await tester.pumpWidget(_catalogApp(
      fullCatalog,
      data,
      locale: const Locale('ko'),
    ));
    await _pumpLoaded(tester);
    final forward = fullCatalog.scenes.firstWhere(
      (scene) => scene.theme == SpatialLearningTheme.forwardConnection,
    );
    final messi = fullCatalog.scenes.firstWhere(
      (scene) => scene.focusPlayerName == 'Lionel Messi',
    );

    await tester
        .tap(find.byKey(const ValueKey<String>('spatial-scene-selector')));
    await tester.pumpAndSettle();
    final search = find.byKey(const ValueKey<String>('spatial-search'));
    await tester.enterText(search, '전진');
    await tester.pump();
    expect(find.byKey(ValueKey<String>('spatial-scene-${forward.id}')),
        findsOneWidget);

    await tester.enterText(search, '메시');
    await tester.pump();
    expect(find.byKey(ValueKey<String>('spatial-scene-${messi.id}')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nearby-defender scene shows a localized factual gap cue',
      (tester) async {
    final scene = fullCatalog.scenes.firstWhere(
      (value) => value.theme == SpatialLearningTheme.pressureSupport,
    );
    final single = _catalogWith(fullCatalog, [scene]);
    final replay = RealMatchReplayData.fromJsonString(
      File(scene.asset).readAsStringSync(),
    );
    await tester.pumpWidget(_catalogApp(
      single,
      {scene.id: replay},
      locale: const Locale('ko'),
    ));
    await _pumpLoaded(tester);
    await tester.tap(find.byKey(const ValueKey<String>('spatial-play')));
    await tester.pump();
    await tester.pump(
      Duration(milliseconds: ((scene.evidenceStart + .1) * 1000).round()),
    );

    final gap = _painter(tester).currentDefenderGap!;
    expect(_textValue(tester, 'spatial-cue-line'), contains(gap.defenderName));
    expect(_textValue(tester, 'spatial-cue-line'), contains(gap.actorName));
    expect(tester.takeException(), isNull);
  });

  testWidgets('all eight themes use reached, scene-specific phase cues',
      (tester) async {
    for (final theme in SpatialLearningTheme.values) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      final scene = fullCatalog.scenes.firstWhere(
        (candidate) => candidate.theme == theme,
      );
      final replay = RealMatchReplayData.fromJsonString(
        File(scene.asset).readAsStringSync(),
      );
      await tester.pumpWidget(_catalogApp(
        _catalogWith(fullCatalog, [scene]),
        {scene.id: replay},
      ));
      await _pumpLoaded(tester);
      expect(_textValue(tester, 'spatial-cue-line'), startsWith('BEFORE'));

      _seekToSceneTime(tester, scene, scene.evidenceStart + .1);
      await tester.pump();
      final movement = _textValue(tester, 'spatial-cue-line');
      expect(movement, isNot(contains('Track')), reason: theme.name);
      expect(movement, isNot(contains('follow')), reason: theme.name);

      _seekToSceneTime(tester, scene, scene.evidenceEnd + .1);
      await tester.pump();
      final result = _textValue(tester, 'spatial-cue-line');
      expect(result, startsWith('AFTER'), reason: theme.name);
      if (theme == SpatialLearningTheme.combination) {
        expect(
          result,
          contains(scene.metrics.sequenceSeconds.toStringAsFixed(1)),
          reason: theme.name,
        );
      } else {
        expect(result, contains(scene.evidenceAnchors.last.playerName),
            reason: theme.name);
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
      'single More menu exposes source, legacy, and authored references',
      (tester) async {
    await tester.pumpWidget(_catalogApp(catalog, data));
    await _pumpLoaded(tester);
    expect(find.byType(TabBar), findsNothing);

    await _openMenu(tester);
    expect(find.byKey(const ValueKey<String>('spatial-source-info')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('spatial-legacy-viewer')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('spatial-authored-sample')),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('spatial-source-info')));
    await tester.pumpAndSettle();
    expect(find.textContaining('SkillCorner Open Data'), findsOneWidget);
    expect(find.textContaining('MIT License'), findsOneWidget);
    expect(find.textContaining('geometric interpretations'), findsOneWidget);
    expect(find.textContaining('pitch plane (XY)'), findsAtLeastNWidgets(1));
    expect(
        find.textContaining('only player positions observed'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('spatial-open-source')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pitch stays metric and usable at compact portrait and landscape',
      (tester) async {
    for (final configuration in <({Size size, Locale locale, bool dark})>[
      (size: const Size(320, 700), locale: const Locale('ja'), dark: false),
      (size: const Size(667, 320), locale: const Locale('ko'), dark: true),
    ]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = configuration.size;
      await tester.pumpWidget(_catalogApp(
        catalog,
        data,
        locale: configuration.locale,
        textScale: 1.4,
        dark: configuration.dark,
      ));
      await _pumpLoaded(tester);
      final paint = find.byKey(const ValueKey<String>('spatial-pitch'));
      final size = tester.getSize(paint);
      final painter = _painter(tester);
      final bounds = painter.pitchBounds(size);
      final expected = painter.portrait
          ? data[catalog.scenes.first.id]!.pitchWidth /
              data[catalog.scenes.first.id]!.pitchLength
          : data[catalog.scenes.first.id]!.pitchLength /
              data[catalog.scenes.first.id]!.pitchWidth;
      expect(bounds.width / bounds.height, closeTo(expected, .001));
      for (final overlay in painter.reservedOverlayRects) {
        expect(painter.viewport.view.overlaps(overlay), isFalse);
        expect(painter.ballSafetyRect.overlaps(overlay), isFalse);
        expect(
          painter.keyPlayerSafetyRects.any((shirt) => shirt.overlaps(overlay)),
          isFalse,
        );
      }
      final canvasRect = tester.getRect(paint);
      final contextRect = tester.getRect(
        find.byKey(const ValueKey<String>('spatial-context')),
      );
      final controlsRect = tester.getRect(
        find.byKey(const ValueKey<String>('spatial-controls')),
      );
      expect(canvasRect.contains(contextRect.topLeft), isTrue);
      expect(canvasRect.contains(contextRect.bottomRight), isTrue);
      expect(canvasRect.overlaps(controlsRect), isFalse);
      for (final key in <String>[
        'spatial-match-line',
        'spatial-scene-line',
        'spatial-cue-line',
        'spatial-clock',
        'spatial-direction',
      ]) {
        _expectTextFits(tester, key);
      }
      expect(find.byKey(const ValueKey<String>('spatial-play')).hitTestable(),
          findsOneWidget);
      expect(
          find.byKey(const ValueKey<String>('spatial-previous')).hitTestable(),
          findsOneWidget);
      expect(find.byKey(const ValueKey<String>('spatial-next')).hitTestable(),
          findsOneWidget);
      expect(find.byKey(const ValueKey<String>('spatial-more')).hitTestable(),
          findsOneWidget);
      final next = find.byKey(const ValueKey<String>('spatial-next'));
      final l10n = AppLocalizations.of(tester.element(next))!;
      expect(tester.getSemantics(next).label, contains(l10n.spatialNextScene));
      expect(tester.takeException(), isNull);
    }
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  testWidgets('real mobile context wraps long match and phase cues',
      (tester) async {
    final pressure = fullCatalog.scenes.firstWhere(
      (scene) => scene.id == '2417-16459-müller-pressureSupport',
    );
    final combination = fullCatalog.scenes.firstWhere(
      (scene) => scene.id == '2417-13350-goretzka-combination',
    );
    final replays = <String, RealMatchReplayData>{
      for (final scene in <SpatialLibraryScene>[pressure, combination])
        scene.id: RealMatchReplayData.fromJsonString(
          File(scene.asset).readAsStringSync(),
        ),
    };
    final configurations = <({
      Size size,
      Locale locale,
      SpatialLibraryScene scene,
      double time,
    })>[
      (
        size: const Size(390, 844),
        locale: const Locale('en'),
        scene: pressure,
        time: pressure.evidenceStart + .1,
      ),
      (
        size: const Size(412, 915),
        locale: const Locale('ko'),
        scene: combination,
        time: combination.evidenceEnd + .1,
      ),
      (
        size: const Size(390, 844),
        locale: const Locale('ja'),
        scene: combination,
        time: combination.evidenceEnd + .1,
      ),
    ];

    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    for (final configuration in configurations) {
      tester.view.physicalSize = configuration.size;
      await tester.pumpWidget(const SizedBox.shrink());
      final scene = configuration.scene;
      final replay = replays[scene.id]!;
      final reordered = _catalogWith(fullCatalog, [
        scene,
        ...fullCatalog.scenes.where((candidate) => candidate.id != scene.id),
      ]);
      await tester.pumpWidget(_catalogApp(
        reordered,
        {scene.id: replay},
        locale: configuration.locale,
        textScale: 1.4,
      ));
      await _pumpLoaded(tester);
      _seekToSceneTime(tester, scene, configuration.time);
      await tester.pump();

      final match = _textValue(tester, 'spatial-match-line');
      final clock = _textValue(tester, 'spatial-clock');
      final sceneHeader = _textValue(tester, 'spatial-scene-line');
      final cue = _textValue(tester, 'spatial-cue-line');
      expect(match, contains(scene.home));
      expect(match, contains(scene.away));
      expect(clock, contains(scene.date));
      expect(sceneHeader, contains(scene.focusPlayerName));
      if (scene.theme == SpatialLearningTheme.pressureSupport) {
        final gap = scene.observedNearbyDefender(replay, configuration.time)!;
        expect(cue, contains(gap.defenderName));
        expect(cue, contains(gap.actorName));
      } else {
        if (scene.theme == SpatialLearningTheme.combination) {
          expect(
            cue,
            contains(scene.metrics.sequenceSeconds.toStringAsFixed(1)),
          );
        } else {
          expect(
            scene.evidenceAnchors.any(
              (anchor) => cue.contains(anchor.playerName),
            ),
            isTrue,
          );
        }
      }
      for (final key in <String>[
        'spatial-match-line',
        'spatial-scene-line',
        'spatial-cue-line',
        'spatial-clock',
        'spatial-direction',
      ]) {
        _expectTextFits(tester, key);
      }
      _expectRectWithin(tester, 'spatial-cue-line', 'spatial-context');
      _expectRectWithin(tester, 'spatial-scene-line', 'spatial-controls');
      final pitchRect = tester.getRect(
        find.byKey(const ValueKey<String>('spatial-pitch')),
      );
      final directionRect = tester.getRect(
        find.byKey(const ValueKey<String>('spatial-direction')),
      );
      expect(pitchRect.contains(directionRect.topLeft), isTrue);
      expect(pitchRect.contains(directionRect.bottomRight), isTrue);
      expect(find.byKey(const ValueKey<String>('spatial-play')).hitTestable(),
          findsOneWidget);
      expect(find.byKey(const ValueKey<String>('spatial-next')).hitTestable(),
          findsOneWidget);
      expect(find.byKey(const ValueKey<String>('spatial-more')).hitTestable(),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('short landscape keeps teaching inside pitch and controls pinned',
      (tester) async {
    final scene = fullCatalog.scenes.firstWhere(
      (candidate) => candidate.id == '2417-13350-goretzka-combination',
    );
    final replay = RealMatchReplayData.fromJsonString(
      File(scene.asset).readAsStringSync(),
    );
    final reordered = _catalogWith(fullCatalog, [
      scene,
      ...fullCatalog.scenes.where((candidate) => candidate.id != scene.id),
    ]);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(667, 320);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(_catalogApp(
      reordered,
      {scene.id: replay},
      locale: const Locale('ja'),
      textScale: 1.4,
      dark: true,
    ));
    await _pumpLoaded(tester);
    _seekToSceneTime(tester, scene, scene.evidenceStart + .5);
    await tester.pump();
    _expectTextFits(tester, 'spatial-cue-line');

    _seekToSceneTime(tester, scene, scene.evidenceEnd + .1);
    await tester.pump();

    final cue = _textValue(tester, 'spatial-cue-line');
    expect(cue, contains(scene.metrics.sequenceSeconds.toStringAsFixed(1)));
    for (final key in <String>[
      'spatial-match-line',
      'spatial-scene-line',
      'spatial-cue-line',
      'spatial-clock',
      'spatial-direction',
    ]) {
      _expectTextFits(tester, key);
    }
    final controlsBefore = tester.getRect(
      find.byKey(const ValueKey<String>('spatial-controls')),
    );
    _expectRectWithin(tester, 'spatial-cue-line', 'spatial-context');
    final pitchRect = tester.getRect(
      find.byKey(const ValueKey<String>('spatial-pitch')),
    );
    final contextRect = tester.getRect(
      find.byKey(const ValueKey<String>('spatial-context')),
    );
    expect(pitchRect.contains(contextRect.topLeft), isTrue);
    expect(pitchRect.contains(contextRect.bottomRight), isTrue);
    expect(
      tester.getRect(find.byKey(const ValueKey<String>('spatial-controls'))),
      controlsBefore,
    );
    expect(find.byKey(const ValueKey<String>('spatial-play')).hitTestable(),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('spatial-next')).hitTestable(),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('spatial-more')).hitTestable(),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tall landscape keeps critical context full width and legible',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(_catalogApp(
      catalog,
      data,
      locale: const Locale('ko'),
      textScale: 1.4,
      dark: true,
    ));
    await _pumpLoaded(tester);

    expect(
        find.byKey(const ValueKey<String>('spatial-side-panel')), findsNothing);
    final pitch = tester.getRect(
      find.byKey(const ValueKey<String>('spatial-pitch')),
    );
    expect(
      pitch.overlaps(tester.getRect(
        find.byKey(const ValueKey<String>('spatial-context')),
      )),
      isTrue,
    );
    expect(
      pitch.overlaps(tester.getRect(
        find.byKey(const ValueKey<String>('spatial-controls')),
      )),
      isFalse,
    );
    for (final key in <String>[
      'spatial-match-line',
      'spatial-scene-line',
      'spatial-cue-line',
      'spatial-clock',
      'spatial-direction',
    ]) {
      _expectTextFits(tester, key);
    }
    expect(tester.takeException(), isNull);
  });

  test('draw participants are observed and roles are current, not cumulative',
      () {
    final opening = fullCatalog.scenes.first;
    final openingData = RealMatchReplayData.fromJsonString(
      File(opening.asset).readAsStringSync(),
    );
    final before = _directPainter(
      opening,
      openingData,
      opening.evidenceStart - .1,
      portrait: true,
    );
    expect(before.showsRecordedTrace, isFalse);
    expect(before.showsEndpointRegion, isFalse);
    expect(
      before.observedPlayerIds,
      [
        for (var index = 0; index < openingData.players.length; index++)
          if (openingData
                  .renderSample(opening.evidenceStart - .1)
                  .players[index] !=
              null)
            openingData.players[index].id,
      ],
    );
    final minimap = SpatialLibraryMinimapPainter(
      data: openingData,
      time: opening.evidenceStart - .1,
      viewportCamera: before.viewport.camera,
      portrait: true,
    );
    expect(minimap.observedPlayerIds, before.observedPlayerIds);
    expect(
        minimap.observedPlayerIds.length, lessThan(openingData.players.length));
    expect(
      before.currentHighlightPlayerIds,
      everyElement(isIn(before.observedPlayerIds)),
    );

    final duringTime = (opening.evidenceStart + opening.evidenceEnd) / 2;
    final during = _directPainter(
      opening,
      openingData,
      duringTime,
      portrait: true,
    );
    expect(during.showsRecordedTrace, isTrue);
    expect(during.showsEndpointRegion, isFalse);
    expect(during.recordedBallTrace, isNotEmpty);
    expect(
      during.recordedBallTrace.last.x,
      closeTo(openingData.sample(duringTime).ball.x, .1),
    );
    final later = _directPainter(
      opening,
      openingData,
      math.min(openingData.duration, opening.evidenceEnd + 2),
      portrait: true,
    );
    expect(later.showsRecordedTrace, isFalse);
    expect(later.recordedBallTrace, isEmpty);

    final recovery = fullCatalog.scenes.firstWhere(
      (scene) => scene.theme == SpatialLearningTheme.recovery,
    );
    final recoveryData = RealMatchReplayData.fromJsonString(
      File(recovery.asset).readAsStringSync(),
    );
    final recoveryBefore = _directPainter(recovery, recoveryData, 0);
    expect(recoveryBefore.currentHighlightPlayerIds,
        isNot(contains(recovery.evidenceAnchors.last.playerId)));

    final recoveryAfter = _directPainter(
      recovery,
      recoveryData,
      recovery.evidenceEnd,
    );
    expect(recoveryAfter.showsEndpointRegion, isTrue);
    expect(
      recoveryAfter.currentHighlightPlayerIds,
      everyElement(isIn(recoveryAfter.observedPlayerIds)),
    );
    expect(
      recoveryAfter.roles
          .role(SpatialObservedRoleKind.ballSidePlayer)
          ?.playerId,
      recovery.evidenceAnchors.last.playerId,
    );
  });

  test('all real scenes keep ball and relevant observed players in metric view',
      () {
    for (final scene in fullCatalog.scenes) {
      final replay = RealMatchReplayData.fromJsonString(
        File(scene.asset).readAsStringSync(),
      );
      final plan = SpatialFocusPlan.build(replay, scene);
      expect(plan.keyframes, isNotEmpty, reason: scene.id);
      for (var frame = 0; frame < replay.frames.length; frame++) {
        final time = frame / replay.fps;
        final sample = replay.renderSample(time);
        for (final configuration in <({Size size, bool portrait})>[
          (size: const Size(390, 520), portrait: true),
          (size: const Size(667, 210), portrait: false),
          (size: const Size(1100, 690), portrait: false),
        ]) {
          final viewport = SpatialPitchViewport.fit(
            plan.cameraAt(time),
            configuration.size,
            portrait: configuration.portrait,
            fieldLength: replay.pitchLength,
            fieldWidth: replay.pitchWidth,
          );
          expect(
            viewport.metricScaleX,
            closeTo(viewport.metricScaleY, 1e-9),
            reason: '${scene.id} frame $frame',
          );
          expect(
            viewport.contains(sample.ball, safetyPixels: 5),
            isTrue,
            reason: '${scene.id} ball frame $frame',
          );
          for (final id in plan.relevantPlayerIdsAt(time)) {
            final point = sample.players[replay.playerIndex(id)];
            if (point == null) continue;
            expect(
              viewport.contains(point, safetyPixels: 14),
              isTrue,
              reason:
                  '${scene.id} player $id frame $frame point (${point.x}, ${point.y}) camera (${viewport.camera.minX}, ${viewport.camera.maxX}, ${viewport.camera.minY}, ${viewport.camera.maxY}) projected ${viewport.project(point)} view ${viewport.view}',
            );
          }
          for (final role in scene.observedRoles(replay, time).values) {
            expect(
              viewport.contains(role.point, safetyPixels: 20),
              isTrue,
              reason: '${scene.id} ${role.kind.name} frame $frame',
            );
          }
        }
      }
      for (final keyframe in plan.keyframes) {
        final left = plan.cameraAt(math.max(0, keyframe.time - .001));
        final right = plan.cameraAt(
          math.min(replay.duration, keyframe.time + .001),
        );
        expect((left.minX - right.minX).abs(), lessThan(.2), reason: scene.id);
        expect((left.maxY - right.maxY).abs(), lessThan(.2), reason: scene.id);
      }
    }
  });

  testWidgets('wide view uses spare framing room for the pitch at a touchline',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(_catalogApp(catalog, data));
    await _pumpLoaded(tester);
    final painter = _painter(tester);
    final canvasSize = tester.getSize(find.byKey(
      const ValueKey<String>('spatial-pitch'),
    ));
    final view = painter.viewport.view;
    final pitch = painter.pitchBounds(canvasSize).intersect(view);
    expect(pitch.width * pitch.height / (view.width * view.height),
        greaterThan(.7));
    expect(
        painter.viewport.contains(data[catalog.scenes.first.id]!.sample(0).ball,
            safetyPixels: 20),
        isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('teaching phase changes do not resize or rotate the held view',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      _catalogApp(catalog, data, locale: const Locale('ko')),
    );
    await _pumpLoaded(tester);
    final scene = catalog.scenes.first;
    SpatialLibraryPitchPainter? previous;
    for (final time in [
      scene.evidenceStart - .1,
      scene.evidenceStart + .1,
      scene.evidenceEnd + .1,
    ]) {
      _seekToSceneTime(tester, scene, time);
      await tester.pump();
      final current = _painter(tester);
      if (previous != null) {
        expect(current.viewport.view, previous.viewport.view);
        expect(current.portrait, previous.portrait);
        expect(current.viewport.camera.minX,
            closeTo(previous.viewport.camera.minX, .001));
        expect(current.viewport.camera.maxY,
            closeTo(previous.viewport.camera.maxY, .001));
      }
      previous = current;
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('crowded phone situation keeps its current role labels readable',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester
        .pumpWidget(_catalogApp(catalog, data, locale: const Locale('ko')));
    await _pumpLoaded(tester);
    final scene = catalog.scenes.first;
    _seekToSceneTime(tester, scene, scene.evidenceStart + .5);
    await tester.pump();

    final painter = _painter(tester);
    expect(painter.roles.values.length, greaterThanOrEqualTo(2));
    expect(painter.calloutRects.length, painter.roles.values.length);
    expect(tester.takeException(), isNull);
  });

  test('minimap preserves metric scale and matches the main view orientation',
      () {
    final scene = catalog.scenes.first;
    final replay = data[scene.id]!;
    const size = Size(142, 92);
    for (final rotated in [false, true]) {
      final minimap = SpatialLibraryMinimapPainter(
        data: replay,
        time: scene.evidenceStart,
        viewportCamera: SpatialFocusPlan.build(replay, scene).teachingCamera,
        portrait: rotated,
      );
      final field = minimap.fieldBounds(size);
      expect(
          field.width / field.height,
          closeTo(
              rotated
                  ? replay.pitchWidth / replay.pitchLength
                  : replay.pitchLength / replay.pitchWidth,
              1e-9));
      final center =
          minimap.projectPoint(size, const RealMatchReplayPoint(0, 0));
      final x = minimap.projectPoint(size, const RealMatchReplayPoint(1, 0));
      final y = minimap.projectPoint(size, const RealMatchReplayPoint(0, 1));
      expect((x - center).distance, closeTo((y - center).distance, 1e-9));
      if (rotated) {
        expect(x.dy, lessThan(center.dy));
        expect(y.dx, greaterThan(center.dx));
      } else {
        expect(x.dx, greaterThan(center.dx));
        expect(y.dy, greaterThan(center.dy));
      }
    }
  });

  test('role callouts never cover the ball, key shirts, or each other', () {
    final scenes = <SpatialLibraryScene>[
      fullCatalog.scenes.firstWhere(
        (scene) => scene.id == '2417-16459-müller-pressureSupport',
      ),
      fullCatalog.scenes.firstWhere(
        (scene) => scene.theme == SpatialLearningTheme.lateralSwitch,
      ),
      fullCatalog.scenes.firstWhere(
        (scene) => scene.theme == SpatialLearningTheme.combination,
      ),
    ];
    for (final scene in scenes) {
      final replay = RealMatchReplayData.fromJsonString(
        File(scene.asset).readAsStringSync(),
      );
      final time = (scene.evidenceStart + .5).clamp(0.0, replay.duration);
      for (final configuration in <({Size size, bool rotated})>[
        (size: const Size(390, 500), rotated: true),
        (size: const Size(667, 210), rotated: false),
      ]) {
        final painter = _directPainter(
          scene,
          replay,
          time,
          portrait: configuration.rotated,
          size: configuration.size,
        );
        final callouts = painter.calloutRects;
        for (var index = 0; index < callouts.length; index++) {
          expect(callouts[index].overlaps(painter.ballSafetyRect), isFalse,
              reason: '${scene.id} ball');
          expect(
            painter.keyPlayerSafetyRects
                .any((shirt) => callouts[index].overlaps(shirt)),
            isFalse,
            reason: '${scene.id} key shirt',
          );
          for (var other = index + 1; other < callouts.length; other++) {
            expect(callouts[index].overlaps(callouts[other]), isFalse,
                reason: '${scene.id} callouts $index/$other');
          }
        }
      }
    }
  });

  test('scene orientation favors the long lateral teaching route on phone', () {
    final scene = fullCatalog.scenes.firstWhere(
      (scene) => scene.id == '3442-50134-messi-lateralSwitch',
    );
    final replay = RealMatchReplayData.fromJsonString(
      File(scene.asset).readAsStringSync(),
    );
    final plan = SpatialFocusPlan.build(replay, scene);
    expect(
      SpatialPitchViewport.bestRotation(
        plan.teachingCamera,
        const Size(390, 500),
      ),
      isFalse,
    );
  });

  test('observed tails split at a real source visibility gap', () {
    SpatialLibraryScene? gapScene;
    RealMatchReplayData? gapReplay;
    int? gapPlayerId;
    double? gapTime;
    for (final scene in fullCatalog.scenes) {
      final replay = RealMatchReplayData.fromJsonString(
        File(scene.asset).readAsStringSync(),
      );
      for (var player = 0; player < replay.players.length; player++) {
        for (var end = 9; end < replay.frames.length; end++) {
          final values = <bool>[
            for (var frame = end - 9; frame <= end; frame++)
              replay.isVisibleAtFrame(frame, player),
          ];
          final firstMissing = values.indexOf(false);
          if (firstMissing < 2) continue;
          final resumed = values.indexOf(true, firstMissing + 1);
          if (resumed < 0 || values.length - resumed < 2) continue;
          gapScene = scene;
          gapReplay = replay;
          gapPlayerId = replay.players[player].id;
          gapTime = end / replay.fps;
          break;
        }
        if (gapScene != null) break;
      }
      if (gapScene != null) break;
    }

    expect(gapScene, isNotNull);
    final painter = _directPainter(gapScene!, gapReplay!, gapTime!);
    final segments = painter.observedTailSegments(gapPlayerId!);
    expect(segments.length, greaterThanOrEqualTo(2));
    expect(segments, everyElement(hasLength(greaterThanOrEqualTo(2))));
  });

  testWidgets('dispose cancels an unfinished initial load', (tester) async {
    final pending = Completer<SpatialLibraryCatalog>();
    await tester.pumpWidget(_app(
      home: ScanPassSpatialLibraryScreen(catalogLoader: () => pending.future),
    ));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(catalog);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

SpatialLibraryCatalog _catalogWith(
  SpatialLibraryCatalog source,
  List<SpatialLibraryScene> scenes,
) =>
    SpatialLibraryCatalog(
      version: source.version,
      provider: source.provider,
      license: source.license,
      sourceCommit: source.sourceCommit,
      sourceUrl: source.sourceUrl,
      matchCount: source.matchCount,
      scenes: scenes,
    );

Widget _catalogApp(
  SpatialLibraryCatalog catalog,
  Map<String, RealMatchReplayData> data, {
  Locale locale = const Locale('en'),
  double textScale = 1,
  bool dark = false,
}) =>
    _app(
      locale: locale,
      textScale: textScale,
      dark: dark,
      home: ScanPassSpatialLibraryScreen(
        catalogLoader: () async => catalog,
        sceneLoader: (scene) async =>
            data[scene.id] ??
            RealMatchReplayData.fromJsonString(
              File(scene.asset).readAsStringSync(),
            ),
      ),
    );

Widget _app({
  required Widget home,
  Locale locale = const Locale('en'),
  double textScale = 1,
  bool dark = false,
}) =>
    MaterialApp(
      locale: locale,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: home,
    );

Future<void> _pumpLoaded(WidgetTester tester) async {
  for (var attempt = 0; attempt < 60; attempt++) {
    await tester.pump();
    if (find
        .byKey(const ValueKey<String>('spatial-pitch'))
        .evaluate()
        .isNotEmpty) {
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 15)),
    );
  }
  fail('Spatial library did not load.');
}

Future<void> _pumpScene(WidgetTester tester, String sceneId) async {
  for (var attempt = 0; attempt < 60; attempt++) {
    await tester.pump();
    if (find
            .byKey(const ValueKey<String>('spatial-pitch'))
            .evaluate()
            .isNotEmpty &&
        _painter(tester).scene.id == sceneId) {
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 15)),
    );
  }
  fail('Spatial scene $sceneId did not load.');
}

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey<String>('spatial-more')));
  await tester.pumpAndSettle();
}

SpatialLibraryPitchPainter _painter(WidgetTester tester) => tester
    .widget<CustomPaint>(
      find.byKey(const ValueKey<String>('spatial-pitch')),
    )
    .painter! as SpatialLibraryPitchPainter;

SpatialLibraryPitchPainter _directPainter(
  SpatialLibraryScene scene,
  RealMatchReplayData data,
  double time, {
  bool portrait = false,
  Size size = const Size(390, 500),
}) {
  final plan = SpatialFocusPlan.build(data, scene);
  return SpatialLibraryPitchPainter(
    data: data,
    scene: scene,
    focusPlan: plan,
    viewport: SpatialPitchViewport.fit(
      plan.cameraAt(time),
      size,
      portrait: portrait,
    ),
    time: time,
    brightness: Brightness.light,
    portrait: portrait,
    textDirection: TextDirection.ltr,
    textScaler: TextScaler.noScaling,
    roles: scene.observedRoles(data, time),
    roleLabels: const {
      SpatialObservedRoleKind.ballSidePlayer: 'Near ball',
      SpatialObservedRoleKind.connectedTeammate: 'Previous link',
      SpatialObservedRoleKind.nearbyDefender: 'Nearby defender',
    },
  );
}

double _sourceTime(WidgetTester tester) => _painter(tester).time;

void _seekToSceneTime(
  WidgetTester tester,
  SpatialLibraryScene scene,
  double time,
) {
  final progress = tester.widget<Slider>(
    find.byKey(const ValueKey<String>('spatial-progress')),
  );
  progress.onChanged!(time / scene.duration);
}

String _textValue(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(ValueKey<String>(key))).data!;

void _expectTextFits(WidgetTester tester, String key) {
  final paragraph = tester.renderObject<RenderParagraph>(
    find.byKey(ValueKey<String>(key)),
  );
  expect(
    paragraph.didExceedMaxLines,
    isFalse,
    reason: '$key "${paragraph.text.toPlainText()}" ${paragraph.size}',
  );
}

void _expectRectWithin(WidgetTester tester, String key, String containerKey) {
  final rect = tester.getRect(find.byKey(ValueKey<String>(key)));
  final container = tester.getRect(
    find.byKey(ValueKey<String>(containerKey)),
  );
  expect(container.contains(rect.topLeft), isTrue, reason: '$key top-left');
  expect(container.contains(rect.bottomRight), isTrue,
      reason: '$key bottom-right');
}

class _Options implements OptionRepository {
  @override
  List<String> getOptions(String key, List<String> defaults) => defaults;

  @override
  List<int> getIntOptions(String key, List<int> defaults) => defaults;

  @override
  T? getValue<T>(String key) => null;

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {}

  @override
  Future<void> setValue(String key, dynamic value) async {}
}
