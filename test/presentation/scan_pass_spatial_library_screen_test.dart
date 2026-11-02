import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/scan_pass_spatial_library_service.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/scan_pass/real_match_replay.dart';
import 'package:football_note/domain/scan_pass/scan_pass_spatial_focus.dart';
import 'package:football_note/domain/scan_pass/scan_pass_spatial_library.dart';
import 'package:football_note/domain/scan_pass/scan_pass_spatial_personalization.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/scan_pass_game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SpatialLibraryCatalog catalog;
  late SpatialLibraryScene firstScene;
  late RealMatchReplayData firstData;

  setUpAll(() {
    final loaded = SpatialLibraryCatalog.fromJsonString(
      File('assets/scan_pass_spatial/catalog.json').readAsStringSync(),
    );
    firstScene = loaded.scenes.firstWhere(
      (scene) => scene.id == '2417-59318-hummels-lateralSwitch',
    );
    catalog = _catalogStartingWith(loaded, firstScene);
    firstData = _replay(firstScene);
  });

  testWidgets(
    'public root is 2D and official video is one secondary route',
    (tester) async {
      final options = _Options();
      await tester.pumpWidget(_app(
        home: ScanPassGameScreen(optionRepository: options),
      ));
      await _pumpLoaded(tester);

      expect(find.byType(ScanPassSpatialLibraryScreen), findsOneWidget);
      expect(find.byType(ScanPassVideoLearningScreen), findsNothing);
      await _openMenu(tester);
      expect(
        find.byKey(const ValueKey<String>('spatial-official-video')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('spatial-legacy-viewer')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('spatial-authored-sample')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('spatial-official-video')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ScanPassVideoLearningScreen), findsOneWidget);
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();
      expect(find.byType(ScanPassSpatialLibraryScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    tags: 'prelaunch-smoke',
  );

  testWidgets(
    'ordinary replay stays 1x and lifecycle, seek, next are safe',
    (tester) async {
      await tester.pumpWidget(_catalogApp(catalog));
      await _pumpLoaded(tester);

      await tester.tap(find.byKey(const ValueKey<String>('spatial-play')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));
      expect(_sourceTime(tester), closeTo(1.1, .15));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      final paused = _sourceTime(tester);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 900));
      expect(_sourceTime(tester), closeTo(paused, .01));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey<String>('spatial-progress')),
      );
      slider.onChanged!(.5);
      await tester.pump();
      expect(_sourceTime(tester), closeTo(firstScene.duration / 2, .05));

      await tester.tap(find.byKey(const ValueKey<String>('spatial-next')));
      await _pumpScene(tester, catalog.scenes[1].id);
      expect(_sourceTime(tester), 0);
      expect(tester.takeException(), isNull);
    },
    tags: 'prelaunch-smoke',
  );

  testWidgets(
    'recreation restores exact source time paused',
    (tester) async {
      final options = _Options();
      await tester.pumpWidget(_catalogApp(catalog, options: options));
      await _pumpLoaded(tester);

      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey<String>('spatial-progress')),
      );
      slider.onChanged!(.4);
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      await tester.pumpWidget(_catalogApp(
        catalog,
        key: const ValueKey<String>('restored-spatial-viewer'),
        options: options,
      ));
      await _pumpLoaded(tester);

      expect(_sourceTime(tester), closeTo(firstScene.duration * .4, .01));
      final restored = _sourceTime(tester);
      await tester.pump(const Duration(milliseconds: 600));
      expect(_sourceTime(tester), closeTo(restored, .01));
      await tester.tap(find.byKey(const ValueKey<String>('spatial-play')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        _sourceTime(tester),
        closeTo(restored + .6, .12),
        reason: 'ordinary playback must continue from the restored source time',
      );
    },
    tags: 'prelaunch-smoke',
  );

  testWidgets('real source playback creates progress and bookmark filtering',
      (tester) async {
    final options = _Options();
    await tester.pumpWidget(_catalogApp(catalog, options: options));
    await _pumpLoaded(tester);
    await tester.tap(find.byKey(const ValueKey<String>('spatial-play')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const ValueKey<String>('spatial-play')));
    await tester.pump();
    await _openMenu(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('spatial-bookmark-toggle')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('spatial-scene-selector')),
    );
    await tester.pumpAndSettle();

    expect(
      _textValue(tester, 'spatial-watch-text-${firstScene.id}'),
      contains('2'),
    );
    final bookmarkFilter =
        find.byKey(const ValueKey<String>('spatial-watch-filter-bookmarked'));
    await tester.ensureVisible(bookmarkFilter);
    await tester.tap(bookmarkFilter);
    await tester.pump();
    expect(
      find.byKey(ValueKey<String>('spatial-scene-${firstScene.id}')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey<String>('spatial-bookmark-state-${firstScene.id}')),
      findsOneWidget,
    );
  });

  testWidgets('natural completed playback auto-loads next unfinished paused',
      (tester) async {
    final options = _Options();
    await tester.pumpWidget(_catalogApp(catalog, options: options));
    await _pumpLoaded(tester);
    await tester.tap(find.byKey(const ValueKey<String>('spatial-play')));
    await tester.pump();
    for (var elapsed = 0;
        elapsed <= firstScene.duration.ceil() + 1 &&
            _painter(tester).scene.id == firstScene.id;
        elapsed++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await _pumpScene(tester, catalog.scenes[1].id);

    expect(_sourceTime(tester), 0);
    await tester.pump(const Duration(milliseconds: 500));
    expect(_sourceTime(tester), 0);
    final persisted =
        options.getValue<String>(ScanPassSpatialLibraryService.storageKey);
    expect(persisted, isNotNull);
  });

  testWidgets('seeked final playback can complete but never auto-advances',
      (tester) async {
    final options = _Options();
    options.values[ScanPassSpatialLibraryService.storageKey] = jsonEncode(
      SpatialLibraryPreferences(
        lastSceneIdentity: firstScene.spatialHistoryIdentity,
        records: <String, SpatialLibrarySceneRecord>{
          firstScene.spatialHistoryIdentity: SpatialLibrarySceneRecord(
            coverage: SpatialLibraryCoverage(
              intervals: <SpatialLibraryViewedInterval>[
                SpatialLibraryViewedInterval(0, firstScene.duration * .9),
              ],
            ),
          ),
        },
      ).toJson(),
    );
    await tester.pumpWidget(_catalogApp(catalog, options: options));
    await _pumpLoaded(tester);
    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey<String>('spatial-progress')),
    );
    slider.onChanged!(.95);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('spatial-play')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(_painter(tester).scene.id, firstScene.id);
    expect(_sourceTime(tester), closeTo(firstScene.duration, .01));
  });

  testWidgets('save failure offers localized retry without blocking playback',
      (tester) async {
    final options = _FailOnceOptions();
    await tester.pumpWidget(_catalogApp(catalog, options: options));
    await _pumpLoaded(tester);
    await tester.pump();
    final context = tester.element(
      find.byKey(const ValueKey<String>('spatial-play')),
    );
    final l10n = AppLocalizations.of(context)!;

    expect(find.text(l10n.spatialHistorySaveFailed), findsOneWidget);
    final retry = tester.widget<SnackBarAction>(find.byType(SnackBarAction));
    expect(retry.label, l10n.spatialHistoryRetry);
    retry.onPressed();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('spatial-play')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(_sourceTime(tester), greaterThan(0));
    expect(options.failNext, isFalse);
  });

  testWidgets('guided replay covers setup, 0.5x core, and 1x aftermath',
      (tester) async {
    await tester.pumpWidget(_catalogApp(catalog));
    await _pumpLoaded(tester);
    await _openMenu(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('spatial-focus-replay')),
    );
    await tester.pump();
    expect(_sourceTime(tester), 0);

    await tester.pump(const Duration(seconds: 1));
    expect(_sourceTime(tester), closeTo(1, .12));
    await tester.pump(
      Duration(milliseconds: ((firstScene.evidenceStart - 1) * 1000).round()),
    );
    await tester.pump();
    expect(_sourceTime(tester), closeTo(firstScene.evidenceStart, .12));

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 900));
    expect(
      _sourceTime(tester),
      closeTo(firstScene.evidenceStart + .5, .14),
    );
    final criticalWallMilliseconds =
        ((firstScene.evidenceEnd - firstScene.evidenceStart) * 2000).round();
    await tester.pump(
      Duration(milliseconds: criticalWallMilliseconds - 1000),
    );
    await tester.pump();
    expect(_sourceTime(tester), closeTo(firstScene.evidenceEnd, .15));

    for (var i = 0;
        i < 30 && _sourceTime(tester) <= firstScene.evidenceEnd;
        i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final aftermathStart = _sourceTime(tester);
    expect(aftermathStart, greaterThan(firstScene.evidenceEnd));
    await tester.pump(const Duration(seconds: 1));
    expect(_sourceTime(tester), closeTo(aftermathStart + 1, .15));
    expect(tester.takeException(), isNull);
  });

  testWidgets('picker shows real duration, match, player, and reviewed themes',
      (tester) async {
    await tester.pumpWidget(_catalogApp(catalog));
    await _pumpLoaded(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('spatial-scene-selector')),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('${catalog.scenes.length}'),
      findsWidgets,
    );
    expect(find.textContaining(firstScene.focusPlayerName), findsWidgets);
    expect(find.textContaining(firstScene.home), findsWidgets);
    expect(
      find.textContaining(firstScene.duration.toStringAsFixed(1)),
      findsWidgets,
    );
    expect(
      find.byKey(
        ValueKey<String>('spatial-duration-${firstScene.id}'),
      ),
      findsOneWidget,
    );
    _expectTextFits(tester, 'spatial-duration-text-${firstScene.id}');
    for (final theme in catalog.themes) {
      expect(
        find.byKey(ValueKey<String>('spatial-theme-${theme.name}')),
        findsOneWidget,
      );
    }
    expect(
      find.byKey(const ValueKey<String>('spatial-theme-turnover')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('participant search shows the actual connection and focal player',
      (tester) async {
    await tester.pumpWidget(_catalogApp(catalog, locale: const Locale('ko')));
    await _pumpLoaded(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('spatial-scene-selector')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('spatial-search')),
      '하키미',
    );
    await tester.pump();

    final row = find.byKey(
      ValueKey<String>('spatial-scene-${firstScene.id}'),
    );
    expect(row, findsOneWidget);
    expect(
      tester
          .widget<Text>(
            find.byKey(
              ValueKey<String>('spatial-focus-player-${firstScene.id}'),
            ),
          )
          .data,
      firstScene.focusPlayerName,
    );
    expect(
      find.byKey(
        ValueKey<String>('spatial-participants-${firstScene.id}'),
      ),
      findsOneWidget,
    );
    expect(find.text('Hummels → Hakimi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final configuration in <({Size size, String label})>[
    (size: const Size(320, 740), label: 'narrow portrait'),
    (size: const Size(390, 844), label: 'mobile portrait'),
    (size: const Size(667, 320), label: 'short landscape'),
  ]) {
    testWidgets(
        'secondary participant result keeps full identity in ${configuration.label}',
        (tester) async {
      await tester.binding.setSurfaceSize(configuration.size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final target = catalog.scenes.firstWhere(
        (scene) => scene.id == '2841-22836-benzema-lateralSwitch',
      );
      await tester.pumpWidget(_catalogApp(
        catalog,
        locale: const Locale('ko'),
        textScale: 1.4,
      ));
      await _pumpLoaded(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('spatial-scene-selector')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('spatial-search')),
        '크로스',
      );
      await tester.pump();

      final scroll = find.byKey(
        const ValueKey<String>('spatial-library-scroll'),
      );
      final scrollable =
          find.descendant(of: scroll, matching: find.byType(Scrollable)).first;
      final result = find.byKey(
        ValueKey<String>('spatial-scene-${target.id}'),
      );
      await tester.scrollUntilVisible(
        result,
        80,
        scrollable: scrollable,
      );
      await tester.pump();

      final l10n = AppLocalizations.of(tester.element(result))!;
      _expectResultTextWithinCard(
        tester,
        result,
        key: 'spatial-focus-player-${target.id}',
        expectedText: 'Karim Benzema',
      );
      final matchText = _expectResultTextWithinCard(
        tester,
        result,
        key: 'spatial-match-${target.id}',
      );
      expect(matchText, contains('FC Barcelona'));
      expect(matchText, contains('Real Madrid'));
      _expectResultTextWithinCard(
        tester,
        result,
        key: 'spatial-result-theme-${target.id}',
        expectedText: l10n.spatialThemeLateralSwitch,
      );
      _expectResultTextWithinCard(
        tester,
        result,
        key: 'spatial-duration-text-${target.id}',
        expectedText: l10n.spatialDurationBadge(
          target.duration.toStringAsFixed(1),
        ),
      );
      _expectResultTextWithinCard(
        tester,
        result,
        key: 'spatial-participants-${target.id}',
        expectedText: 'Benzema → Kroos',
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'query and selectors survive close and scene selection until reset',
      (tester) async {
    final target = catalog.scenes.firstWhere(
      (scene) => scene.id == '3442-50144-messi-lateralSwitch',
    );
    const query = '바르셀로나 메시';
    await tester.pumpWidget(_catalogApp(catalog, locale: const Locale('ko')));
    await _pumpLoaded(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('spatial-scene-selector')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('spatial-search')),
      query,
    );
    await tester.tap(
      find.byKey(
        const ValueKey<String>('spatial-theme-lateralSwitch'),
      ),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('spatial-team-filter')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('FC Barcelona').last);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('spatial-player-filter')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lionel Messi').last);
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey<String>('spatial-scene-${target.id}')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('spatial-library-close')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('spatial-scene-selector')),
    );
    await tester.pumpAndSettle();
    _expectRetainedSpatialFilters(tester, query);

    await tester.tap(
      find.byKey(ValueKey<String>('spatial-scene-${target.id}')),
    );
    await _pumpScene(tester, target.id);
    await tester.tap(
      find.byKey(const ValueKey<String>('spatial-scene-selector')),
    );
    await tester.pumpAndSettle();
    _expectRetainedSpatialFilters(tester, query);

    await tester.tap(
      find.byKey(const ValueKey<String>('spatial-reset-filters')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('spatial-library-close')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('spatial-scene-selector')),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('spatial-search')),
          )
          .controller!
          .text,
      isEmpty,
    );
    expect(
      tester
          .widget<DropdownButtonFormField<String?>>(
            find.byKey(const ValueKey<String>('spatial-team-filter')),
          )
          .initialValue,
      isNull,
    );
    expect(
      tester
          .widget<DropdownButtonFormField<String?>>(
            find.byKey(const ValueKey<String>('spatial-player-filter')),
          )
          .initialValue,
      isNull,
    );
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(const ValueKey<String>('spatial-theme-all')),
          )
          .selected,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('localized mixed search clears, resets, and opens scene identity',
      (tester) async {
    final target = catalog.scenes.firstWhere(
      (scene) => scene.id == '2269-32665-caleta-car-lateralSwitch',
    );
    await tester.pumpWidget(_catalogApp(catalog, locale: const Locale('ko')));
    await _pumpLoaded(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('spatial-scene-selector')),
    );
    await tester.pumpAndSettle();

    final search = find.byKey(const ValueKey<String>('spatial-search'));
    await tester.enterText(search, '레알 크로스');
    await tester.pump();
    final mixedCount = catalog.scenes
        .where(
          (scene) => SpatialLibraryDiscovery.matchesScene(scene, '레알 크로스'),
        )
        .length;
    final l10n = AppLocalizations.of(tester.element(search))!;
    expect(
      find.text(l10n.spatialFilteredResultCount(mixedCount)),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('spatial-clear-search')),
    );
    await tester.pump();
    expect(
      find.text(l10n.spatialFilteredResultCount(catalog.scenes.length)),
      findsOneWidget,
    );

    await tester.enterText(search, '존재하지않는선수');
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('spatial-empty-results')),
      findsOneWidget,
    );
    expect(find.text(l10n.spatialFilteredResultCount(0)), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('spatial-reset-filters')),
    );
    await tester.pump();
    expect(
      find.text(l10n.spatialFilteredResultCount(catalog.scenes.length)),
      findsOneWidget,
    );

    await tester.enterText(search, '마르세유 칼레타카르');
    await tester.pump();
    expect(
      find.byKey(ValueKey<String>('spatial-scene-${target.id}')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(ValueKey<String>('spatial-scene-${target.id}')),
    );
    await _pumpScene(tester, target.id);
    expect(_painter(tester).scene.id, target.id);
    expect(tester.takeException(), isNull);
  });

  testWidgets('attacking team narrows players and clears an incompatible one',
      (tester) async {
    await tester.pumpWidget(_catalogApp(catalog));
    await _pumpLoaded(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('spatial-scene-selector')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('spatial-team-filter')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paris').last);
    await tester.pumpAndSettle();
    final playerField = tester.widget<DropdownButtonFormField<String?>>(
      find.byKey(const ValueKey<String>('spatial-player-filter')),
    );
    playerField.onChanged!('Kylian Mbappe');
    await tester.pump();
    final parisMbappe = catalog.scenes
        .where(
          (scene) =>
              scene.attackingTeam == 'Paris' &&
              scene.involvesPlayer('Kylian Mbappe'),
        )
        .length;
    final l10n = AppLocalizations.of(
      tester.element(
        find.byKey(const ValueKey<String>('spatial-result-count')),
      ),
    )!;
    expect(
      find.text(l10n.spatialFilteredResultCount(parisMbappe)),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('spatial-team-filter')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Real Madrid').last);
    await tester.pumpAndSettle();
    final realCount = catalog.scenes
        .where((scene) => scene.attackingTeam == 'Real Madrid')
        .length;
    expect(
      find.text(l10n.spatialFilteredResultCount(realCount)),
      findsOneWidget,
    );
    expect(find.text('Kylian Mbappe'), findsNothing);
    expect(find.text(l10n.spatialAllPlayers), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final configuration in <({Size size, double scale})>[
    (size: const Size(320, 640), scale: 1.4),
    (size: const Size(667, 320), scale: 1.4),
  ]) {
    testWidgets(
        'picker remains scrollable with keyboard at ${configuration.size}',
        (tester) async {
      await tester.binding.setSurfaceSize(configuration.size);
      addTearDown(() {
        tester.binding.setSurfaceSize(null);
        tester.view.resetViewInsets();
      });
      await tester.pumpWidget(_catalogApp(
        catalog,
        locale: const Locale('ja'),
        textScale: configuration.scale,
      ));
      await _pumpLoaded(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('spatial-scene-selector')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('spatial-search')));
      tester.view.viewInsets = const FakeViewPadding(bottom: 180);
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey<String>('spatial-search')),
        'Messi Barcelona',
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('spatial-library-scroll')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('spatial-team-filter')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('spatial-player-filter')),
        findsOneWidget,
      );
      final scroll =
          find.byKey(const ValueKey<String>('spatial-library-scroll'));
      final scrollable =
          find.descendant(of: scroll, matching: find.byType(Scrollable)).first;
      final reset = find.byKey(const ValueKey<String>('spatial-reset-filters'));
      await tester.scrollUntilVisible(
        reset,
        80,
        scrollable: scrollable,
      );
      await tester.pump();
      expect(
        tester.getRect(reset).bottom,
        lessThanOrEqualTo(configuration.size.height - 180),
      );

      final target = catalog.scenes.firstWhere(
        (scene) => scene.id == '3442-50144-messi-lateralSwitch',
      );
      final result = find.byKey(ValueKey<String>('spatial-scene-${target.id}'));
      await tester.scrollUntilVisible(
        result,
        80,
        scrollable: scrollable,
      );
      await tester.pump();
      expect(
        tester.getRect(result).bottom,
        lessThanOrEqualTo(configuration.size.height - 180),
      );
      await tester.tap(result);
      await _pumpScene(tester, target.id);
      expect(_painter(tester).scene.id, target.id);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('scene stays laid out behind a DPR 1 landscape library keyboard',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    await tester.binding.setSurfaceSize(const Size(667, 320));
    addTearDown(() async {
      tester.view.resetViewInsets();
      tester.view.resetDevicePixelRatio();
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(_catalogApp(
      catalog,
      locale: const Locale('ja'),
      textScale: 1.4,
    ));
    await _pumpLoaded(tester);

    final pitch = find.byKey(const ValueKey<String>('spatial-pitch'));
    final cue = find.byKey(const ValueKey<String>('spatial-context'));
    final pitchRectBeforeKeyboard = tester.getRect(pitch);
    final cueRectBeforeKeyboard = tester.getRect(cue);

    await tester.tap(
      find.byKey(const ValueKey<String>('spatial-scene-selector')),
    );
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 160);
    await tester.pump();

    final search = find.byKey(const ValueKey<String>('spatial-search'));
    expect(MediaQuery.viewInsetsOf(tester.element(search)).bottom, 160);
    expect(tester.getRect(pitch), pitchRectBeforeKeyboard);
    expect(tester.getRect(cue), cueRectBeforeKeyboard);
    expect(tester.takeException(), isNull);
  });

  testWidgets('source sheet reports actual counts and duration range',
      (tester) async {
    await tester.pumpWidget(_catalogApp(catalog));
    await _pumpLoaded(tester);
    await _openMenu(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('spatial-source-info')),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('${catalog.scenes.length}'), findsWidgets);
    final l10n = AppLocalizations.of(
      tester.element(
        find.byKey(const ValueKey<String>('spatial-info-scroll')),
      ),
    )!;
    final minimum = catalog.scenes
        .map((scene) => scene.duration)
        .reduce((left, right) => left < right ? left : right);
    final maximum = catalog.scenes
        .map((scene) => scene.duration)
        .reduce((left, right) => left > right ? left : right);
    expect(
      find.text(l10n.spatialDurationRange(
        minimum.toStringAsFixed(1),
        maximum.toStringAsFixed(1),
      )),
      findsOneWidget,
    );
    expect(find.textContaining('SkillCorner'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('spatial-open-source')),
      findsOneWidget,
    );
  });

  for (final configuration in <({
    Size size,
    double scale,
    Locale locale,
  })>[
    (size: const Size(320, 640), scale: 1.4, locale: const Locale('en')),
    (size: const Size(390, 844), scale: 1, locale: const Locale('ko')),
    (size: const Size(667, 320), scale: 1.4, locale: const Locale('ja')),
    (size: const Size(1280, 900), scale: 1, locale: const Locale('en')),
  ]) {
    testWidgets(
        'fixed subtitle and source overlays stay separate at ${configuration.size} '
        '${configuration.locale.languageCode}', (tester) async {
      await tester.binding.setSurfaceSize(configuration.size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_catalogApp(
        catalog,
        locale: configuration.locale,
        textScale: configuration.scale,
      ));
      await _pumpLoaded(tester);
      _seekTo(
          firstScene, (firstScene.coreStart + firstScene.coreEnd) / 2, tester);
      await tester.pump();

      final painter = _painter(tester);
      final subtitleRect = tester.getRect(
        find.byKey(const ValueKey<String>('spatial-context')),
      );
      final pitchRect = tester.getRect(
        find.byKey(const ValueKey<String>('spatial-pitch')),
      );
      final controlsRect = tester.getRect(
        find.byKey(const ValueKey<String>('spatial-controls')),
      );
      expect(subtitleRect.top, greaterThanOrEqualTo(pitchRect.bottom));
      expect(subtitleRect.bottom, lessThanOrEqualTo(controlsRect.top));
      expect(
        find.byKey(const ValueKey<String>('spatial-attack-direction')),
        findsOneWidget,
      );
      final l10n = lookupAppLocalizations(configuration.locale);
      final attackingTeamName =
          firstScene.attackingHome ? firstScene.home : firstScene.away;
      final direction = painter.portrait
          ? (firstScene.attackDirection > 0
              ? l10n.spatialDirectionUp
              : l10n.spatialDirectionDown)
          : (firstScene.attackDirection > 0
              ? l10n.spatialDirectionRight
              : l10n.spatialDirectionLeft);
      final directionSemantics = tester.getSemantics(
        find.byKey(const ValueKey<String>('spatial-attack-direction')),
      );
      expect(
        directionSemantics.label,
        startsWith(l10n.spatialAttackDirection(attackingTeamName, direction)),
      );
      final directionRect = painter.reservedOverlayRects.single;
      expect(directionRect.overlaps(painter.ballSafetyRect), isFalse);
      for (final actorRect in painter.keyPlayerSafetyRects) {
        expect(directionRect.overlaps(actorRect), isFalse);
      }
      final sample = firstData.sample(painter.time);
      for (final id in firstScene.highlightPlayerIds) {
        final point = sample.players[firstData.playerIndex(id)];
        expect(point, isNotNull);
        final projected = painter.viewport.project(point!);
        expect(painter.viewport.view.deflate(20).contains(projected), isTrue);
      }
      _expectNameLabelsAreCollisionFree(painter);
      final labelIds =
          painter.playerNameLabels.map((label) => label.playerId).toSet();
      expect(labelIds.difference(painter.nameLabelPlayerIds), isEmpty);
      expect(labelIds.length, lessThanOrEqualTo(4));
      _expectTextFits(tester, 'spatial-cue-line');
      expect(
        find.byKey(const ValueKey<String>('spatial-minimap')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('spatial-controls')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('cue flow never previews a future ball path', (tester) async {
    await tester.pumpWidget(_catalogApp(catalog));
    await _pumpLoaded(tester);
    final setupPainter = _painter(tester);
    expect(setupPainter.recordedBallTrace, isEmpty);
    expect(
      setupPainter.observedTailSegments(firstScene.focusPlayerId),
      isEmpty,
    );

    final middle = (firstScene.evidenceStart + firstScene.evidenceEnd) / 2;
    _seekTo(firstScene, middle, tester);
    await tester.pump();
    final trace = _painter(tester).recordedBallTrace;
    expect(trace, isNotEmpty);
    expect(
      _painter(tester).observedTailSegments(firstScene.focusPlayerId),
      isNotEmpty,
    );
    final maximumExpectedPoints =
        ((middle - firstScene.evidenceStart) * firstData.fps).floor() + 2;
    expect(trace.length, lessThanOrEqualTo(maximumExpectedPoints));

    _seekTo(firstScene, firstScene.evidenceEnd + 2, tester);
    await tester.pump();
    expect(_painter(tester).recordedBallTrace, isEmpty);
    expect(
      _painter(tester).observedTailSegments(firstScene.focusPlayerId),
      isEmpty,
    );
    expect(
      _textValue(tester, 'spatial-cue-line'),
      AppLocalizations.of(
        tester.element(find.byKey(const ValueKey<String>('spatial-cue-line'))),
      )!
          .spatialLateralContinuationCue,
    );
  });

  testWidgets('gold source ownership and blue teaching focus stay independent',
      (tester) async {
    ({SpatialLibraryScene scene, double time, int playerId})? confirmed;
    ({SpatialLibraryScene scene, double time, int playerId})? nearbyOnly;
    for (final scene in catalog.scenes) {
      final data = _replay(scene);
      for (var frame = 0; frame < data.frames.length; frame++) {
        final time = math.min(data.duration, (frame + .25) / data.fps);
        final ballSide = scene
            .observedRoles(data, time)
            .role(SpatialObservedRoleKind.ballSidePlayer);
        if (ballSide == null) continue;
        final owner = data.confirmedPossessionOwnerIdAt(time);
        if (owner == ballSide.playerId && confirmed == null) {
          confirmed = (scene: scene, time: time, playerId: owner!);
        }
        if (data.sourcePossessionOwners[frame] == null &&
            owner == null &&
            nearbyOnly == null) {
          nearbyOnly = (
            scene: scene,
            time: time,
            playerId: ballSide.playerId,
          );
        }
        if (confirmed != null && nearbyOnly != null) break;
      }
      if (confirmed != null && nearbyOnly != null) break;
    }
    expect(confirmed, isNotNull);
    expect(nearbyOnly, isNotNull);

    final owned = confirmed!;
    await tester.pumpWidget(_catalogApp(
      _catalogStartingWith(catalog, owned.scene),
      key: const ValueKey<String>('confirmed-owner-cues'),
    ));
    await _pumpLoaded(tester);
    _seekTo(owned.scene, owned.time, tester);
    await tester.pump();
    var painter = _painter(tester);
    expect(painter.currentConfirmedOwnerId, owned.playerId);
    expect(painter.goldOwnershipPlayerIds, <int>{owned.playerId});
    expect(painter.blueTeachingFocusPlayerIds, contains(owned.playerId));
    expect(painter.ownershipCueColor, const Color(0xFFFFD15C));
    expect(painter.teachingFocusCueColor, const Color(0xFF73CFFF));
    final ownerBadge = painter.badgeGeometryForPlayer(owned.playerId);
    expect(ownerBadge, isNotNull);
    final pitchPixels = await tester.runAsync(
      () => _renderPitchPixels(
        painter,
        tester.getSize(
          find.byKey(const ValueKey<String>('spatial-pitch')),
        ),
      ),
    );
    expect(
      pitchPixels!.nearInAnnulus(
        painter.ownershipCueColor,
        center: ownerBadge!.center,
        innerRadius: ownerBadge.radius + 3.5,
        outerRadius: ownerBadge.radius + 7.2,
      ),
      greaterThan(20),
    );

    final nearby = nearbyOnly!;
    await tester.pumpWidget(_catalogApp(
      _catalogStartingWith(catalog, nearby.scene),
      key: const ValueKey<String>('nearby-only-cues'),
    ));
    await _pumpLoaded(tester);
    _seekTo(nearby.scene, nearby.time, tester);
    await tester.pump();
    painter = _painter(tester);
    expect(painter.currentConfirmedOwnerId, isNull);
    expect(painter.goldOwnershipPlayerIds, isEmpty);
    expect(
      painter.blueTeachingFocusPlayerIds,
      contains(nearby.playerId),
    );
  });

  testWidgets('pitch kits and minimap markers resolve the same team colors',
      (tester) async {
    await tester.pumpWidget(_catalogApp(catalog));
    await _pumpLoaded(tester);
    final pitch = _painter(tester);
    final minimap = SpatialLibraryMinimapPainter(
      data: pitch.data,
      scene: pitch.scene,
      time: pitch.time,
      viewportCamera: pitch.viewport.camera,
      portrait: pitch.portrait,
    );

    for (final player in pitch.data.players) {
      expect(
        minimap.markerColorForPlayer(player),
        pitch.kitForPlayer(player).mainColor,
        reason: '${player.name} (${player.id})',
      );
      if (player.keeper) {
        expect(pitch.kitForPlayer(player).curated, isFalse);
      }
    }
  });

  testWidgets('approved themes use stable source-named phase cues',
      (tester) async {
    for (final theme in <SpatialLearningTheme>[
      SpatialLearningTheme.lateralSwitch,
      SpatialLearningTheme.pressureSupport,
      SpatialLearningTheme.combination,
    ]) {
      final scene = catalog.scenes.firstWhere((value) => value.theme == theme);
      final data = _replay(scene);
      final ordered = _catalogStartingWith(catalog, scene);
      await tester.pumpWidget(_catalogApp(
        ordered,
        key: ValueKey<String>('phase-${theme.name}'),
      ));
      await _pumpLoaded(tester);

      final values = <String>[];
      for (final time in <double>[
        scene.evidenceStart - .1,
        scene.evidenceStart + .1,
        scene.evidenceEnd + .4,
        scene.duration - .5,
        scene.duration,
      ]) {
        _seekTo(scene, time, tester);
        await tester.pump();
        values.add(_textValue(tester, 'spatial-cue-line'));
      }
      expect(values.toSet(), hasLength(5), reason: theme.name);
      expect(values[0], startsWith('CONTEXT'), reason: theme.name);
      final returnsToFirst = scene.evidenceAnchors.first.playerId ==
          scene.evidenceAnchors.last.playerId;
      expect(
        values[1],
        startsWith(
          theme == SpatialLearningTheme.combination && returnsToFirst
              ? 'RETURN'
              : 'CONNECTION',
        ),
        reason: theme.name,
      );
      expect(values[2], startsWith('AFTER'), reason: theme.name);
      expect(values[3], startsWith('CONTINUE'), reason: theme.name);
      expect(values[4], startsWith('REPLAY'), reason: theme.name);
      expect(values.join(' '), isNot(matches(RegExp(r'\d+[.,]\d+\s*m'))));
      for (final anchor in scene.evidenceAnchors) {
        expect(
          values[1],
          contains(_cueLabel(data, anchor.playerId)),
          reason: theme.name,
        );
      }

      _seekTo(scene, scene.evidenceStart + .1, tester);
      await tester.pump();
      expect(
        _painter(tester).cuePlayerId,
        scene.evidenceAnchors.first.playerId,
        reason: theme.name,
      );
      _seekTo(scene, scene.evidenceEnd + .4, tester);
      await tester.pump();
      expect(
        _painter(tester).cuePlayerId,
        scene.evidenceAnchors.last.playerId,
        reason: theme.name,
      );
    }
  });

  testWidgets('return combinations and three-player links use honest copy',
      (tester) async {
    final returnScene = catalog.scenes.firstWhere(
      (scene) =>
          scene.theme == SpatialLearningTheme.combination &&
          scene.evidenceAnchors.first.playerId ==
              scene.evidenceAnchors.last.playerId,
    );
    final distinctScene = catalog.scenes.firstWhere(
      (scene) =>
          scene.theme == SpatialLearningTheme.combination &&
          scene.evidenceAnchors.first.playerId !=
              scene.evidenceAnchors.last.playerId,
    );
    for (final scene in <SpatialLibraryScene>[returnScene, distinctScene]) {
      await tester.pumpWidget(_catalogApp(
        _catalogStartingWith(catalog, scene),
        key: ValueKey<String>('combination-${scene.id}'),
      ));
      await _pumpLoaded(tester);
      _seekTo(scene, scene.evidenceStart + .1, tester);
      await tester.pump();
      final text = _textValue(tester, 'spatial-cue-line');
      if (scene.id == returnScene.id) {
        expect(text, startsWith('RETURN'));
        expect(
          RegExp(RegExp.escape(_cueLabel(
                  _replay(scene), scene.evidenceAnchors.first.playerId)))
              .allMatches(text),
          hasLength(2),
        );
      } else {
        expect(text, startsWith('CONNECTION'));
        expect(scene.evidenceAnchors.map((anchor) => anchor.playerId).toSet(),
            hasLength(3));
      }
    }
  });

  testWidgets('long context does not name actors before they are visible',
      (tester) async {
    final hiddenAtStart = catalog.scenes
        .where((scene) {
          final data = _replay(scene);
          return data.sample(0).players[
                  data.playerIndex(scene.evidenceAnchors.first.playerId)] ==
              null;
        })
        .take(2)
        .toList(growable: false);
    expect(hiddenAtStart, hasLength(2));
    for (final scene in hiddenAtStart) {
      final data = _replay(scene);
      expect(
        data
            .sample(0)
            .players[data.playerIndex(scene.evidenceAnchors.first.playerId)],
        isNull,
      );
      await tester.pumpWidget(_catalogApp(
        _catalogStartingWith(catalog, scene),
        key: ValueKey<String>('hidden-${scene.id}'),
      ));
      await _pumpLoaded(tester);
      final painter = _painter(tester);
      expect(painter.cuePlayerId, isNull);
      expect(
        painter.playerNameLabels.map((label) => label.playerId),
        isNot(contains(scene.evidenceAnchors.first.playerId)),
      );
      expect(
        _textValue(tester, 'spatial-cue-line'),
        isNot(contains(scene.evidenceAnchors.first.playerName.split(' ').last)),
      );
      expect(
        painter.cueTarget,
        painter.viewport.project(data.sample(0).ball),
      );

      _seekTo(scene, scene.evidenceStart - .1, tester);
      await tester.pump();
      expect(
        _painter(tester).cuePlayerId,
        scene.evidenceAnchors.first.playerId,
      );
    }
  });

  testWidgets('compound source surname stays stable in dark scaled view',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final scene = catalog.scenes.firstWhere(
      (scene) => scene.id == '2841-4790-de-jong-pressureSupport',
    );
    await tester.pumpWidget(_catalogApp(
      _catalogStartingWith(catalog, scene),
      locale: const Locale('ja'),
      textScale: 1.4,
      themeMode: ThemeMode.dark,
    ));
    await _pumpLoaded(tester);
    _seekTo(scene, scene.evidenceStart + .1, tester);
    await tester.pump();

    final firstPainter = _painter(tester);
    final firstLabel = firstPainter.playerNameLabels.singleWhere(
      (label) => label.playerId == scene.focusPlayerId,
    );
    expect(firstPainter.brightness, Brightness.dark);
    expect(firstLabel.sourceName, 'Frenkie de Jong');
    expect(firstLabel.displayName, 'de Jong');
    _expectNameLabelsAreCollisionFree(firstPainter);

    _seekTo(scene, scene.evidenceStart + .12, tester);
    await tester.pump();
    final secondPainter = _painter(tester);
    final secondLabel = secondPainter.playerNameLabels.singleWhere(
      (label) => label.playerId == scene.focusPlayerId,
    );
    expect(secondLabel.placementIndex, firstLabel.placementIndex);
    expect(
      (secondLabel.badgeRect.center - firstLabel.badgeRect.center).distance,
      lessThan(8),
    );
    _expectNameLabelsAreCollisionFree(secondPainter);
    expect(tester.takeException(), isNull);
  });

  test('cue placement retains a clear phase position and moves when blocked',
      () {
    const bounds = Rect.fromLTWH(0, 0, 320, 220);
    const size = Size(150, 48);
    const firstTarget = Offset(150, 120);
    final occupied = <Rect>[
      Rect.fromCircle(center: firstTarget, radius: 14),
      const Rect.fromLTWH(24, 100, 35, 35),
    ];
    final first = SpatialCuePlacement.place(
      bounds: bounds,
      size: size,
      target: firstTarget,
      occupied: occupied,
    );
    const movedTarget = Offset(154, 122);
    final retained = SpatialCuePlacement.place(
      bounds: bounds,
      size: size,
      target: movedTarget,
      occupied: <Rect>[
        Rect.fromCircle(center: movedTarget, radius: 14),
        occupied.last,
      ],
      preferred: first,
    );
    expect(retained, first);

    final nearestCardEdge = Offset(
      movedTarget.dx.clamp(first.left, first.right),
      movedTarget.dy.clamp(first.top, first.bottom),
    );
    final unrelatedSpaceBetweenCardAndSubject = Rect.fromCircle(
      center: Offset.lerp(nearestCardEdge, movedTarget, .5)!,
      radius: 3,
    );
    final retainedWithoutConnectorConstraint = SpatialCuePlacement.place(
      bounds: bounds,
      size: size,
      target: movedTarget,
      occupied: <Rect>[
        Rect.fromCircle(center: movedTarget, radius: 14),
        unrelatedSpaceBetweenCardAndSubject,
      ],
      preferred: first,
    );
    expect(retainedWithoutConnectorConstraint, first);

    final blocked = <Rect>[
      Rect.fromCircle(center: movedTarget, radius: 14),
      occupied.last,
      first.deflate(4),
    ];
    final relocated = SpatialCuePlacement.place(
      bounds: bounds,
      size: size,
      target: movedTarget,
      occupied: blocked,
      preferred: first,
    );
    expect(relocated, isNot(first));
    expect(
      SpatialCuePlacement.isClear(
        rect: relocated,
        occupied: blocked,
      ),
      isTrue,
    );

    const fullViewport = Rect.fromLTWH(0, 0, 320, 220);
    const pannedPitch = Rect.fromLTWH(-80, 20, 210, 180);
    const stationaryFreeBox = Rect.fromLTWH(162, 12, 150, 48);
    final retainedWhilePitchPans = SpatialCuePlacement.place(
      bounds: pannedPitch,
      fallbackBounds: fullViewport,
      size: size,
      target: movedTarget,
      occupied: <Rect>[
        Rect.fromCircle(center: movedTarget, radius: 25),
      ],
      preferred: stationaryFreeBox,
    );
    expect(retainedWhilePitchPans, stationaryFreeBox);

    const filledPitch = Rect.fromLTWH(0, 20, 160, 180);
    final viewportFallback = SpatialCuePlacement.place(
      bounds: filledPitch,
      fallbackBounds: fullViewport,
      size: size,
      target: const Offset(80, 110),
      occupied: <Rect>[filledPitch],
    );
    expect(viewportFallback.overlaps(filledPitch), isFalse);
    expect(fullViewport.contains(viewportFallback.topLeft), isTrue);
    expect(fullViewport.contains(viewportFallback.bottomRight), isTrue);
  });

  testWidgets('dense landscape names stay attached or are safely suppressed',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(667, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final sceneId in <String>[
      '2841-3915-kroos-lateralSwitch',
      '3442-16202-kroos-pressureSupport',
      '2841-64724-modric-combination',
    ]) {
      final scene = catalog.scenes.firstWhere((value) => value.id == sceneId);
      await tester.pumpWidget(_catalogApp(
        _catalogStartingWith(catalog, scene),
        key: ValueKey<String>('dense-landscape-$sceneId'),
        locale: const Locale('ko'),
      ));
      await _pumpLoaded(tester);
      final firstSample = (scene.evidenceStart * 4).ceil();
      final lastSample = (scene.evidenceEnd * 4).floor();
      for (var sampleIndex = firstSample;
          sampleIndex <= lastSample;
          sampleIndex++) {
        final time = sampleIndex / 4;
        _seekTo(scene, time, tester);
        await tester.pump();

        final painter = _painter(tester);
        final labelIds =
            painter.playerNameLabels.map((label) => label.playerId).toSet();
        expect(labelIds.difference(painter.nameLabelPlayerIds), isEmpty);
        _expectNameLabelsAreCollisionFree(painter);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets(
      'Griezmann pressure aftermath keeps the subtitle outside the pitch',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(667, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final scene = catalog.scenes.firstWhere(
      (value) => value.id == '3442-17463-griezmann-pressureSupport',
    );
    final ordered = _catalogStartingWith(catalog, scene);
    await tester.pumpWidget(_catalogApp(
      ordered,
      locale: const Locale('ko'),
    ));
    await _pumpLoaded(tester);
    _seekTo(scene, 14.5, tester);
    await tester.pump();

    final painter = _painter(tester);
    expect(painter.scene.id, scene.id);
    expect(painter.time, closeTo(14.5, .01));
    expect(painter.keyPlayerSafetyRects, isNotEmpty);
    final subtitleRect = tester.getRect(
      find.byKey(const ValueKey<String>('spatial-context')),
    );
    final pitchRect = tester.getRect(
      find.byKey(const ValueKey<String>('spatial-pitch')),
    );
    final controlsRect = tester.getRect(
      find.byKey(const ValueKey<String>('spatial-controls')),
    );
    expect(subtitleRect.top, greaterThanOrEqualTo(pitchRect.bottom));
    expect(subtitleRect.bottom, lessThanOrEqualTo(controlsRect.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('rapid requests and dispose ignore stale asynchronous loads',
      (tester) async {
    final delayed = Completer<RealMatchReplayData>();
    await tester.pumpWidget(_app(
      home: ScanPassSpatialLibraryScreen(
        catalogLoader: () async => catalog,
        sceneLoader: (scene) {
          if (scene.id == catalog.scenes[1].id) return delayed.future;
          return Future.value(_replay(scene));
        },
      ),
    ));
    await _pumpLoaded(tester);
    await tester.tap(find.byKey(const ValueKey<String>('spatial-next')));
    await tester.tap(find.byKey(const ValueKey<String>('spatial-next')));
    await tester.pump();
    await _pumpScene(tester, catalog.scenes[2].id);
    delayed.complete(_replay(catalog.scenes[1]));
    await tester.pump();
    expect(_painter(tester).scene.id, catalog.scenes[2].id);

    final pending = Completer<SpatialLibraryCatalog>();
    await tester.pumpWidget(_app(
      home: ScanPassSpatialLibraryScreen(catalogLoader: () => pending.future),
    ));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(catalog);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

Widget _catalogApp(
  SpatialLibraryCatalog catalog, {
  Key? key,
  Locale locale = const Locale('en'),
  double textScale = 1,
  ThemeMode themeMode = ThemeMode.system,
  OptionRepository? options,
}) =>
    _app(
      locale: locale,
      textScale: textScale,
      themeMode: themeMode,
      home: ScanPassSpatialLibraryScreen(
        key: key,
        optionRepository: options,
        catalogLoader: () async => catalog,
        sceneLoader: (scene) async => _replay(scene),
      ),
    );

Widget _app({
  required Widget home,
  Locale locale = const Locale('en'),
  double textScale = 1,
  ThemeMode themeMode = ThemeMode.system,
}) =>
    MaterialApp(
      locale: locale,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: home,
    );

void _expectRetainedSpatialFilters(WidgetTester tester, String query) {
  expect(
    tester
        .widget<TextField>(
          find.byKey(const ValueKey<String>('spatial-search')),
        )
        .controller!
        .text,
    query,
  );
  expect(
    tester
        .widget<DropdownButtonFormField<String?>>(
          find.byKey(const ValueKey<String>('spatial-team-filter')),
        )
        .initialValue,
    'FC Barcelona',
  );
  expect(
    tester
        .widget<DropdownButtonFormField<String?>>(
          find.byKey(const ValueKey<String>('spatial-player-filter')),
        )
        .initialValue,
    'Lionel Messi',
  );
  expect(
    tester
        .widget<ChoiceChip>(
          find.byKey(
            const ValueKey<String>('spatial-theme-lateralSwitch'),
          ),
        )
        .selected,
    isTrue,
  );
}

RealMatchReplayData _replay(SpatialLibraryScene scene) =>
    RealMatchReplayData.fromJsonString(File(scene.asset).readAsStringSync());

void _expectNameLabelsAreCollisionFree(SpatialLibraryPitchPainter painter) {
  final labels = painter.playerNameLabels;
  final sample = painter.data.renderSample(painter.time);
  for (var index = 0; index < labels.length; index++) {
    final label = labels[index];
    expect(label.sourceName, painter.data.player(label.playerId).name);
    expect(label.attachmentDistance, lessThanOrEqualTo(18));
    expect(label.placementIndex, lessThan(40));
    expect(
      sample.players[painter.data.playerIndex(label.playerId)],
      isNotNull,
    );
    expect(painter.viewport.view.contains(label.rect.topLeft), isTrue);
    expect(painter.viewport.view.contains(label.rect.bottomRight), isTrue);
    expect(label.rect.overlaps(painter.ballSafetyRect), isFalse);
    for (final overlay in painter.reservedOverlayRects) {
      expect(label.rect.overlaps(overlay), isFalse);
    }
    for (final badge in painter.playerBadgeSafetyRects) {
      expect(label.rect.overlaps(badge), isFalse);
    }
    for (var other = index + 1; other < labels.length; other++) {
      expect(label.rect.overlaps(labels[other].rect), isFalse);
    }
  }
}

String _cueLabel(RealMatchReplayData data, int id) {
  final player = data.player(id);
  final shortName = player.name!.trim().split(' ').last;
  return player.number == null ? shortName : '#${player.number} $shortName';
}

Future<_PitchPixels> _renderPitchPixels(
  SpatialLibraryPitchPainter painter,
  Size size,
) async {
  final width = size.width.ceil();
  final height = size.height.ceil();
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), Size(width.toDouble(), height.toDouble()));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  picture.dispose();
  return _PitchPixels(width, height, bytes!.buffer.asUint8List());
}

class _PitchPixels {
  final int width;
  final int height;
  final List<int> rgba;

  const _PitchPixels(this.width, this.height, this.rgba);

  int nearInAnnulus(
    Color color, {
    required Offset center,
    required double innerRadius,
    required double outerRadius,
    int tolerance = 12,
  }) {
    final value = color.toARGB32();
    final red = value >> 16 & 0xff;
    final green = value >> 8 & 0xff;
    final blue = value & 0xff;
    final innerSquared = innerRadius * innerRadius;
    final outerSquared = outerRadius * outerRadius;
    final left = math.max(0, (center.dx - outerRadius).floor());
    final right = math.min(width - 1, (center.dx + outerRadius).ceil());
    final top = math.max(0, (center.dy - outerRadius).floor());
    final bottom = math.min(height - 1, (center.dy + outerRadius).ceil());
    var count = 0;
    for (var y = top; y <= bottom; y++) {
      for (var x = left; x <= right; x++) {
        final dx = x + .5 - center.dx;
        final dy = y + .5 - center.dy;
        final distanceSquared = dx * dx + dy * dy;
        if (distanceSquared < innerSquared || distanceSquared > outerSquared) {
          continue;
        }
        final offset = (y * width + x) * 4;
        if ((rgba[offset] - red).abs() <= tolerance &&
            (rgba[offset + 1] - green).abs() <= tolerance &&
            (rgba[offset + 2] - blue).abs() <= tolerance &&
            rgba[offset + 3] > 220) {
          count++;
        }
      }
    }
    return count;
  }
}

SpatialLibraryCatalog _catalogStartingWith(
  SpatialLibraryCatalog catalog,
  SpatialLibraryScene scene,
) =>
    SpatialLibraryCatalog(
      version: catalog.version,
      provider: catalog.provider,
      license: catalog.license,
      sourceCommit: catalog.sourceCommit,
      sourceUrl: catalog.sourceUrl,
      matchCount: catalog.matchCount,
      scenes: <SpatialLibraryScene>[
        scene,
        ...catalog.scenes.where((value) => value.id != scene.id),
      ],
    );

Future<void> _pumpLoaded(WidgetTester tester) async {
  for (var attempt = 0; attempt < 80; attempt++) {
    await tester.pump();
    if (find
        .byKey(const ValueKey<String>('spatial-pitch'))
        .evaluate()
        .isNotEmpty) {
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  fail('Spatial library did not load.');
}

Future<void> _pumpScene(WidgetTester tester, String sceneId) async {
  for (var attempt = 0; attempt < 80; attempt++) {
    await tester.pump();
    if (find
            .byKey(const ValueKey<String>('spatial-pitch'))
            .evaluate()
            .isNotEmpty &&
        _painter(tester).scene.id == sceneId) {
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
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

double _sourceTime(WidgetTester tester) => _painter(tester).time;

void _seekTo(
  SpatialLibraryScene scene,
  double time,
  WidgetTester tester,
) {
  final slider = tester.widget<Slider>(
    find.byKey(const ValueKey<String>('spatial-progress')),
  );
  slider.onChanged!(time / scene.duration);
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

String _expectResultTextWithinCard(
  WidgetTester tester,
  Finder card, {
  required String key,
  String? expectedText,
}) {
  final text = find.byKey(ValueKey<String>(key));
  expect(text, findsOneWidget);
  final paragraph = tester.renderObject<RenderParagraph>(text);
  final renderedText = paragraph.text.toPlainText();
  if (expectedText != null) expect(renderedText, expectedText);
  expect(
    paragraph.didExceedMaxLines,
    isFalse,
    reason: '$key "$renderedText" ${paragraph.size}',
  );
  final cardRect = tester.getRect(card);
  final textRect = tester.getRect(text);
  expect(textRect.left, greaterThanOrEqualTo(cardRect.left));
  expect(textRect.right, lessThanOrEqualTo(cardRect.right));
  expect(textRect.top, greaterThanOrEqualTo(cardRect.top));
  expect(textRect.bottom, lessThanOrEqualTo(cardRect.bottom));
  return renderedText;
}

class _Options implements OptionRepository {
  final Map<String, dynamic> values = <String, dynamic>{};

  @override
  List<String> getOptions(String key, List<String> defaults) => defaults;

  @override
  List<int> getIntOptions(String key, List<int> defaults) => defaults;

  @override
  T? getValue<T>(String key) => values[key] is T ? values[key] as T : null;

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    values[key] = options;
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    values[key] = value;
  }
}

class _FailOnceOptions extends _Options {
  bool failNext = true;

  @override
  Future<void> setValue(String key, dynamic value) async {
    if (failNext) {
      failNext = false;
      throw StateError('storage unavailable');
    }
    await super.setValue(key, value);
  }
}
