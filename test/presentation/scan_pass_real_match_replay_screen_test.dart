import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/real_match_replay.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/scan_pass_game_screen.dart';
import 'package:football_note/presentation/theme/app_theme.dart';
import 'package:football_note/presentation/widgets/app_bar_action_button.dart';

late RealMatchReplayData _testReplay;
late RealMatchReplayCatalog _testCatalog;
late Map<String, RealMatchReplayData> _testScenes;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  setUpAll(() {
    _testReplay = RealMatchReplayData.fromJsonString(
      File('assets/scan_pass_replay/replay-data.json').readAsStringSync(),
    );
    _testCatalog = RealMatchReplayCatalog.fromJsonString(
      File('assets/scan_pass_replay/catalog.json').readAsStringSync(),
    );
    _testScenes = <String, RealMatchReplayData>{
      for (final scene in _testCatalog.scenes)
        scene.id: RealMatchReplayData.fromJsonString(
          File(scene.asset).readAsStringSync(),
        ),
    };
  });

  testWidgets('loads paused with stable public controls and useful semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app());
    await _pumpLoaded(tester);

    expect(find.byKey(const ValueKey<String>('replay-pitch')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('replay-play')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('replay-scrub')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('replay-explanation')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('replay-speed')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('replay-zoom')), findsOneWidget);
    expect(
        find.byKey(const ValueKey<String>('replay-chapters')), findsOneWidget);
    expect(_slider(tester).value, 0);
    await tester.pump(const Duration(seconds: 1));
    expect(_slider(tester).value, 0);
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey<String>('replay-pitch')))
          .label,
      contains('actual tracked positions'),
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('play pause and half speed advance source time correctly',
      (tester) async {
    await tester.pumpWidget(_app());
    await _pumpLoaded(tester);

    final speed = tester.widget<DropdownButton<double>>(
      find.byKey(const ValueKey<String>('replay-speed')),
    );
    speed.onChanged!(.5);
    await tester.pump();
    await _tapVisible(tester, 'replay-play');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(_slider(tester).value, closeTo(.5, .08));

    await _tapVisible(tester, 'replay-play');
    await tester.pump();
    final pausedAt = _slider(tester).value;
    await tester.pump(const Duration(seconds: 1));
    expect(_slider(tester).value, pausedAt);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scrub and chapter jumps pause and enable commentary',
      (tester) async {
    await tester.pumpWidget(_app());
    await _pumpLoaded(tester);

    _slider(tester).onChanged!(7);
    await tester.pump();
    expect(_slider(tester).value, closeTo(7, .001));
    await _tapVisible(tester, 'replay-chapter-1');
    await tester.pump();
    expect(_slider(tester).value, closeTo(2.42, .001));
    expect(
      tester
          .widget<FilterChip>(
              find.byKey(const ValueKey<String>('replay-explanation')))
          .selected,
      isTrue,
    );
    expect(find.textContaining('Pass'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ordinary end offers a guided half-speed replay', (tester) async {
    await tester.pumpWidget(_app());
    await _pumpLoaded(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(ScanPassRealMatchReplayScreen)),
    )!;

    _slider(tester).onChanged!(12.32);
    await tester.pump();
    expect(find.text(l10n.realMatchReplayGuidedReplay), findsOneWidget);
    await _tapVisible(tester, 'replay-play');
    await tester.pump();
    expect(_slider(tester).value, 0);
    expect(
      tester
          .widget<DropdownButton<double>>(
              find.byKey(const ValueKey<String>('replay-speed')))
          .value,
      .5,
    );
    expect(
      tester
          .widget<FilterChip>(
              find.byKey(const ValueKey<String>('replay-explanation')))
          .selected,
      isTrue,
    );

    _slider(tester).onChanged!(12.32);
    await tester.pump();
    expect(find.text(l10n.realMatchReplayRestart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lifecycle pause preserves the current source frame',
      (tester) async {
    await tester.pumpWidget(_app());
    await _pumpLoaded(tester);
    await _tapVisible(tester, 'replay-play');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    final pausedAt = _slider(tester).value;
    await tester.pump(const Duration(seconds: 1));
    expect(_slider(tester).value, pausedAt);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'reduced motion preserves source timing and mid-play speed changes',
      (tester) async {
    await tester.pumpWidget(_app(reducedMotion: true));
    await _pumpLoaded(tester);
    await _tapVisible(tester, 'replay-play');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(_slider(tester).value, closeTo(1, .01));

    tester
        .widget<DropdownButton<double>>(
          find.byKey(const ValueKey<String>('replay-speed')),
        )
        .onChanged!(.5);
    await tester.pump();
    final before = _slider(tester).value;
    await tester.pump(const Duration(seconds: 1));
    expect(_slider(tester).value, closeTo(before + .5, .01));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('current situation stays visible without explanatory overlays',
      (tester) async {
    await tester.pumpWidget(_app());
    await _pumpLoaded(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(ScanPassRealMatchReplayScreen)),
    )!;
    _slider(tester).onChanged!(6);
    await tester.pump();
    expect(
      find.text(l10n.realMatchReplayStageWithPlayer(
        l10n.replayStepCarry,
        18,
      )),
      findsOneWidget,
    );
    expect(
      find.text(l10n.realMatchReplayObservationKicker(
        l10n.replayStepCarry,
      )),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilterChip>(
            find.byKey(const ValueKey<String>('replay-explanation')),
          )
          .selected,
      isFalse,
    );
    _slider(tester).onChanged!(9.4);
    await tester.pump();
    expect(
      find.text(l10n.realMatchReplayStageWithPlayer(
        l10n.replayStepPressure,
        19,
      )),
      findsOneWidget,
    );
  });

  testWidgets('pointer scrubbing pauses on the chosen source position',
      (tester) async {
    await tester.pumpWidget(_app());
    await _pumpLoaded(tester);
    await _tapVisible(tester, 'replay-play');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final scrub = find.byKey(const ValueKey<String>('replay-scrub'));
    await tester.ensureVisible(scrub);
    await tester.pump();
    final rect = tester.getRect(scrub);
    await tester.tapAt(Offset(rect.left + rect.width * .78, rect.center.dy));
    await tester.pump();
    final selected = _slider(tester).value;
    expect(selected, inExclusiveRange(8, 11));
    await tester.pump(const Duration(seconds: 1));
    expect(_slider(tester).value, selected);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scene library filters and opens a tracking-only situation',
      (tester) async {
    await tester.pumpWidget(_catalogApp());
    await _pumpLoaded(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(ScanPassRealMatchReplayScreen)),
    )!;

    expect(find.text(l10n.realMatchReplaySceneCount(1, 20)), findsOneWidget);
    await _tapVisible(tester, 'replay-choose-scene');
    await tester.pumpAndSettle();
    expect(find.text(l10n.realMatchReplaySceneLibraryTitle), findsOneWidget);
    final turnover =
        find.byKey(const ValueKey<String>('replay-category-turnover'));
    await tester.ensureVisible(turnover);
    await tester.pump();
    await tester.tap(turnover);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('replay-scene-carry-turnover')),
        findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('replay-scene-carry-turnover')),
    );
    await tester.pumpAndSettle();
    await _pumpLoaded(tester);

    expect(find.text(l10n.replaySceneCarryTurnover), findsOneWidget);
    expect(find.text(l10n.realMatchReplaySceneCount(20, 20)), findsOneWidget);
    expect(find.text('Sydney FC'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('replay-tracking-only')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('replay-zoom')), findsNothing);
    expect(_slider(tester).value, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scene navigation pauses and retains speed and commentary',
      (tester) async {
    await tester.pumpWidget(_catalogApp());
    await _pumpLoaded(tester);
    tester
        .widget<FilterChip>(
          find.byKey(const ValueKey<String>('replay-explanation')),
        )
        .onSelected!(true);
    tester
        .widget<DropdownButton<double>>(
          find.byKey(const ValueKey<String>('replay-speed')),
        )
        .onChanged!(.5);
    await tester.pump();
    await _tapVisible(tester, 'replay-play');
    await tester.pump(const Duration(milliseconds: 300));

    tester
        .widget<AppBarActionButton>(
          find.byKey(const ValueKey<String>('replay-next-scene')),
        )
        .onPressed!();
    await _pumpLoaded(tester);

    expect(_slider(tester).value, 0);
    expect(_slider(tester).max, _testScenes['keeper-build']!.duration);
    expect(
      tester
          .widget<FilterChip>(
            find.byKey(const ValueKey<String>('replay-explanation')),
          )
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<DropdownButton<double>>(
            find.byKey(const ValueKey<String>('replay-speed')),
          )
          .value,
      .5,
    );
    await tester.pump(const Duration(seconds: 1));
    expect(_slider(tester).value, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a late scene response cannot replace a newer selection',
      (tester) async {
    final keeper = Completer<RealMatchReplayData>();
    final central = Completer<RealMatchReplayData>();
    await tester.pumpWidget(_app(
      home: ScanPassRealMatchReplayScreen(
        catalogLoader: () async => _testCatalog,
        sceneLoader: (scene) {
          if (scene.id == 'transition-wing') {
            return Future<RealMatchReplayData>.value(
              _testScenes[scene.id]!,
            );
          }
          if (scene.id == 'keeper-build') return keeper.future;
          if (scene.id == 'central-build') return central.future;
          return Future<RealMatchReplayData>.value(_testScenes[scene.id]!);
        },
      ),
    ));
    await _pumpLoaded(tester);
    final next = tester.widget<AppBarActionButton>(
      find.byKey(const ValueKey<String>('replay-next-scene')),
    );
    next.onPressed!();
    next.onPressed!();
    await tester.pump();

    central.complete(_testScenes['central-build']!);
    await tester.pump();
    await tester.pump();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(ScanPassRealMatchReplayScreen)),
    )!;
    expect(find.text(l10n.replaySceneCentralBuild), findsOneWidget);
    keeper.complete(_testScenes['keeper-build']!);
    await tester.pump();
    await tester.pump();

    expect(find.text(l10n.replaySceneCentralBuild), findsOneWidget);
    expect(find.text(l10n.replaySceneKeeperBuild), findsNothing);
    expect(find.text(l10n.realMatchReplaySceneCount(3, 20)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog loading failure offers a working localized retry',
      (tester) async {
    var attempts = 0;
    await tester.pumpWidget(_app(
      home: ScanPassRealMatchReplayScreen(
        catalogLoader: () async {
          attempts++;
          if (attempts == 1) throw StateError('temporary');
          return _testCatalog;
        },
        sceneLoader: (scene) async => _testScenes[scene.id]!,
      ),
    ));
    await tester.pump();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(ScanPassRealMatchReplayScreen)),
    )!;
    expect(find.text(l10n.realMatchReplayLoadFailed), findsOneWidget);
    await tester.tap(find.text(l10n.realMatchReplayRetry));
    await _pumpLoaded(tester);
    expect(find.byKey(const ValueKey<String>('replay-pitch')), findsOneWidget);
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every catalog scene renders its midpoint without an exception',
      (tester) async {
    await tester.pumpWidget(_catalogApp());
    await _pumpLoaded(tester);
    for (var index = 0; index < _testCatalog.scenes.length; index++) {
      final entry = _testCatalog.scenes[index];
      _slider(tester).onChanged!(entry.duration / 2);
      await tester.pump();
      expect(
        _slider(tester).value,
        closeTo(entry.duration / 2, 1e-6),
        reason: entry.id,
      );
      expect(tester.takeException(), isNull, reason: entry.id);
      if (index + 1 == _testCatalog.scenes.length) break;
      tester
          .widget<AppBarActionButton>(
            find.byKey(const ValueKey<String>('replay-next-scene')),
          )
          .onPressed!();
      await _pumpLoaded(tester);
    }
  });

  testWidgets('desktop uses the wide stage and full-pitch view expands it',
      (tester) async {
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_catalogApp());
    await _pumpLoaded(tester);

    final pitch = find.byKey(const ValueKey<String>('replay-pitch'));
    expect(tester.getSize(pitch).width, greaterThan(1400));
    await tester.tap(
      find.byKey(const ValueKey<String>('replay-view-full')),
    );
    await tester.pump();
    expect(tester.getSize(pitch).height, greaterThan(700));
    expect(tester.takeException(), isNull);
  });

  testWidgets('expanded phone pitch keeps transport visible while playing',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(
      home: ScanPassRealMatchReplayScreen(
        catalogLoader: () async => _testCatalog,
        sceneLoader: (scene) async => _testScenes[scene.id]!,
      ),
      appTheme: true,
      locale: const Locale('ko'),
    ));
    await _pumpLoaded(tester);
    final pitch = find.byKey(const ValueKey<String>('replay-pitch'));
    final standardHeight = tester.getSize(pitch).height;
    await tester.tap(find.byKey(const ValueKey<String>('replay-expand')));
    await tester.pump();
    expect(tester.getSize(pitch).height, greaterThan(standardHeight + 150));
    expect(find.byKey(const ValueKey<String>('replay-chapters')), findsNothing);
    for (final key in ['replay-play', 'replay-scrub', 'replay-explanation']) {
      final button = find.byKey(ValueKey<String>(key));
      expect(button.hitTestable(), findsOneWidget);
      expect(tester.getRect(button).bottom, lessThanOrEqualTo(800));
    }
    await tester.tap(find.byKey(const ValueKey<String>('replay-play')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    final currentTime = _slider(tester).value;
    await tester.tap(find.byKey(const ValueKey<String>('replay-expand')));
    await tester.pump();
    expect(_slider(tester).value, greaterThanOrEqualTo(currentTime));
    expect(
        find.byKey(const ValueKey<String>('replay-chapters')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pose detail never covers the recorded pitch', (tester) async {
    await tester.pumpWidget(_app());
    await _pumpLoaded(tester);
    await _tapVisible(tester, 'replay-zoom');
    await tester.pump();
    final field = tester.getRect(
      find.byKey(const ValueKey<String>('replay-pitch')),
    );
    final detail = tester.getRect(
      find.byKey(const ValueKey<String>('replay-pose-detail')),
    );
    expect(field.overlaps(detail), isFalse);
    expect(detail.top, greaterThanOrEqualTo(field.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('expanded large-text landscape can play with commentary',
      (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(
      locale: const Locale('ja'),
      appTheme: true,
      textScale: 1.4,
    ));
    await _pumpLoaded(tester);
    await tester.tap(find.byKey(const ValueKey<String>('replay-expand')));
    await tester.pump();
    expect(
      tester.getSize(find.byKey(const ValueKey<String>('replay-pitch'))).height,
      390,
    );
    await tester.tap(find.byKey(const ValueKey<String>('replay-explanation')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('replay-play')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(_slider(tester).value, greaterThan(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('short Japanese landscape remains scrollable without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(
      home: ScanPassRealMatchReplayScreen(
        catalogLoader: () async => _testCatalog,
        sceneLoader: (scene) async => _testScenes[scene.id]!,
      ),
      locale: const Locale('ja'),
      appTheme: true,
      textScale: 1.3,
    ));
    await _pumpLoaded(tester);
    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  for (final width in <double>[320, 360]) {
    testWidgets('real app theme keeps core transport visible at ${width}px',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(
        locale: const Locale('ko'),
        appTheme: true,
        textScale: 1.3,
      ));
      await _pumpLoaded(tester);
      for (final key in <String>[
        'replay-play',
        'replay-scrub',
        'replay-explanation',
        'replay-speed',
      ]) {
        final finder = find.byKey(ValueKey<String>(key));
        final rect = tester.getRect(finder);
        expect(rect.top, greaterThanOrEqualTo(0), reason: key);
        expect(rect.bottom, lessThanOrEqualTo(800), reason: key);
        expect(finder.hitTestable(), findsOneWidget, reason: key);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('source failure is reported without claiming it opened',
      (tester) async {
    await tester.pumpWidget(_app(
      home: ScanPassRealMatchReplayScreen(
        sourceLauncher: (_) async => false,
        dataLoader: () async => _testReplay,
      ),
    ));
    await _pumpLoaded(tester);
    await _tapVisible(tester, 'replay-source');
    await tester.pump();
    expect(find.text('The source could not be opened on this device.'),
        findsOneWidget);
  });

  for (final locale in const <Locale>[
    Locale('en'),
    Locale('ko'),
    Locale('ja'),
  ]) {
    testWidgets('${locale.languageCode} has no overflow at 320px',
        (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(locale: locale, textScale: 1.3));
      await _pumpLoaded(tester);
      expect(
          find.byKey(const ValueKey<String>('replay-pitch')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

Slider _slider(WidgetTester tester) => tester.widget<Slider>(
      find.byKey(const ValueKey<String>('replay-scrub')),
    );

Future<void> _tapVisible(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey<String>(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

Future<void> _pumpLoaded(WidgetTester tester) async {
  await tester.pump();
  for (var attempt = 0; attempt < 20; attempt++) {
    if (find
        .byKey(const ValueKey<String>('replay-pitch'))
        .evaluate()
        .isNotEmpty) {
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump();
  }
  fail('Replay asset did not load.');
}

Widget _app({
  Widget? home,
  Locale locale = const Locale('en'),
  bool appTheme = false,
  bool reducedMotion = false,
  double textScale = 1,
}) =>
    MaterialApp(
      theme: appTheme ? AppTheme.light() : null,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reducedMotion,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: home ??
          ScanPassRealMatchReplayScreen(
            dataLoader: () async => _testReplay,
          ),
    );

Widget _catalogApp() => _app(
      home: ScanPassRealMatchReplayScreen(
        catalogLoader: () async => _testCatalog,
        sceneLoader: (scene) async => _testScenes[scene.id]!,
      ),
    );
