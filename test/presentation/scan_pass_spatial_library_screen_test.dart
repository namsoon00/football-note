import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/scan_pass/real_match_replay.dart';
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

  testWidgets('scene picker searches players and filters one theme',
      (tester) async {
    await tester.pumpWidget(_catalogApp(fullCatalog, data));
    await _pumpLoaded(tester);
    final target = fullCatalog.scenes
        .firstWhere((scene) => scene.focusPlayerName.contains('Messi'));

    await _openMenu(tester);
    await tester
        .tap(find.byKey(const ValueKey<String>('spatial-choose-scene')));
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

    await _openMenu(tester);
    await tester
        .tap(find.byKey(const ValueKey<String>('spatial-choose-scene')));
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

    expect(_painter(tester).currentDefenderGap, isNotNull);
    expect(find.textContaining('지원 간격'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
      final expected = configuration.size.height > configuration.size.width
          ? data[catalog.scenes.first.id]!.pitchWidth /
              data[catalog.scenes.first.id]!.pitchLength
          : data[catalog.scenes.first.id]!.pitchLength /
              data[catalog.scenes.first.id]!.pitchWidth;
      expect(bounds.width / bounds.height, closeTo(expected, .001));
      final canvasRect = tester.getRect(paint);
      final contextRect = tester.getRect(
        find.byKey(const ValueKey<String>('spatial-context')),
      );
      final controlsRect = tester.getRect(
        find.byKey(const ValueKey<String>('spatial-controls')),
      );
      expect(canvasRect.overlaps(contextRect), isFalse);
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
      final sceneHeader = _textValue(tester, 'spatial-scene-line');
      final cue = _textValue(tester, 'spatial-cue-line');
      expect(match, contains(scene.home));
      expect(match, contains(scene.away));
      expect(match, contains(scene.date));
      expect(sceneHeader, contains(scene.focusPlayerName));
      if (scene.theme == SpatialLearningTheme.pressureSupport) {
        final gap = scene.observedNearbyDefender(replay, configuration.time)!;
        expect(cue, contains(gap.defenderName));
        expect(cue, contains(gap.actorName));
      } else {
        for (final anchor in scene.evidenceAnchors) {
          expect(cue, contains(anchor.playerName));
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
      _expectTextWraps(tester, 'spatial-match-line');
      _expectTextWraps(tester, 'spatial-cue-line');
      for (final key in <String>[
        'spatial-match-line',
        'spatial-scene-line',
        'spatial-cue-line',
      ]) {
        _expectRectWithin(tester, key, 'spatial-context');
      }
      for (final key in <String>['spatial-clock', 'spatial-direction']) {
        _expectRectWithin(tester, key, 'spatial-controls');
      }
      expect(find.byKey(const ValueKey<String>('spatial-play')).hitTestable(),
          findsOneWidget);
      expect(find.byKey(const ValueKey<String>('spatial-next')).hitTestable(),
          findsOneWidget);
      expect(find.byKey(const ValueKey<String>('spatial-more')).hitTestable(),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('short landscape scrolls a long context above pinned controls',
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
    await tester.tap(find.byKey(const ValueKey<String>('spatial-play')));
    await tester.pump();
    await tester.pump(
      Duration(milliseconds: ((scene.evidenceEnd + .1) * 1000).round()),
    );

    final cue = _textValue(tester, 'spatial-cue-line');
    for (final anchor in scene.evidenceAnchors) {
      expect(cue, contains(anchor.playerName));
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
    _expectTextWraps(tester, 'spatial-cue-line');
    final scroll = find.byKey(
      const ValueKey<String>('spatial-context-scroll'),
    );
    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: scroll, matching: find.byType(Scrollable)),
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    final controlsBefore = tester.getRect(
      find.byKey(const ValueKey<String>('spatial-controls')),
    );
    await tester.drag(scroll, Offset(0, -scrollable.position.maxScrollExtent));
    await tester.pumpAndSettle();

    _expectRectWithin(tester, 'spatial-cue-line', 'spatial-context');
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
      isFalse,
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

  test('evidence is time-gated and future recovery actors stay unhighlighted',
      () {
    final opening = fullCatalog.scenes.first;
    final openingData = RealMatchReplayData.fromJsonString(
      File(opening.asset).readAsStringSync(),
    );
    final before = SpatialLibraryPitchPainter(
      data: openingData,
      scene: opening,
      time: opening.evidenceStart - .1,
      brightness: Brightness.light,
      portrait: true,
      textDirection: TextDirection.ltr,
    );
    expect(before.showsRecordedTrace, isFalse);
    expect(before.showsEndpointRegion, isFalse);
    expect(before.currentHighlightPlayerIds,
        [opening.evidenceAnchors.first.playerId]);

    final during = SpatialLibraryPitchPainter(
      data: openingData,
      scene: opening,
      time: (opening.evidenceStart + opening.evidenceEnd) / 2,
      brightness: Brightness.light,
      portrait: true,
      textDirection: TextDirection.ltr,
    );
    expect(during.showsRecordedTrace, isTrue);
    expect(during.showsEndpointRegion, isFalse);

    final recovery = fullCatalog.scenes.firstWhere(
      (scene) => scene.theme == SpatialLearningTheme.recovery,
    );
    final recoveryData = RealMatchReplayData.fromJsonString(
      File(recovery.asset).readAsStringSync(),
    );
    final recoveryBefore = SpatialLibraryPitchPainter(
      data: recoveryData,
      scene: recovery,
      time: 0,
      brightness: Brightness.light,
      portrait: false,
      textDirection: TextDirection.ltr,
    );
    expect(recoveryBefore.currentHighlightPlayerIds,
        [recovery.evidenceAnchors.first.playerId]);
    expect(recoveryBefore.currentHighlightPlayerIds,
        isNot(contains(recovery.evidenceAnchors.last.playerId)));

    final recoveryAfter = SpatialLibraryPitchPainter(
      data: recoveryData,
      scene: recovery,
      time: recovery.evidenceEnd,
      brightness: Brightness.light,
      portrait: false,
      textDirection: TextDirection.ltr,
    );
    expect(recoveryAfter.showsEndpointRegion, isTrue);
    expect(recoveryAfter.currentHighlightPlayerIds,
        contains(recovery.evidenceAnchors.last.playerId));

    final nearby = fullCatalog.scenes.firstWhere(
      (scene) => scene.theme == SpatialLearningTheme.pressureSupport,
    );
    final nearbyData = RealMatchReplayData.fromJsonString(
      File(nearby.asset).readAsStringSync(),
    );
    final nearbyDuring = SpatialLibraryPitchPainter(
      data: nearbyData,
      scene: nearby,
      time: nearby.evidenceStart + .1,
      brightness: Brightness.light,
      portrait: false,
      textDirection: TextDirection.ltr,
    );
    expect(nearbyDuring.currentHighlightPlayerIds,
        isNot(contains(nearby.evidenceAnchors.last.playerId)));
    expect(nearbyDuring.currentHighlightPlayerIds.length, 2);
    expect(nearbyDuring.currentDefenderGap, isNotNull);
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

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey<String>('spatial-more')));
  await tester.pumpAndSettle();
}

SpatialLibraryPitchPainter _painter(WidgetTester tester) => tester
    .widget<CustomPaint>(
      find.byKey(const ValueKey<String>('spatial-pitch')),
    )
    .painter! as SpatialLibraryPitchPainter;

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
  expect(paragraph.didExceedMaxLines, isFalse, reason: key);
}

void _expectTextWraps(WidgetTester tester, String key) {
  final paragraph = tester.renderObject<RenderParagraph>(
    find.byKey(ValueKey<String>(key)),
  );
  final text = paragraph.text.toPlainText();
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: text.length),
  );
  expect(
    boxes.any((box) => box.top > boxes.first.top + .5),
    isTrue,
    reason: '$key should use more than one rendered line',
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
