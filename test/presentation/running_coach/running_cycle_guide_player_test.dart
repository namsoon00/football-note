import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/running_coach/running_cycle_guide_player.dart';

void main() {
  testWidgets('running-cycle v2 atlas remains bundled and cached', (
    WidgetTester tester,
  ) async {
    expect(
      runningCycleAnimationAtlasAsset,
      'assets/images/running_guides/professional_runner/'
      'running_cycle_continuous_atlas_v2.png',
    );

    final bytes = await rootBundle.load(runningCycleAnimationAtlasAsset);
    expect(bytes.lengthInBytes, greaterThan(100000));

    final result = await tester.runAsync(() async {
      final firstLoad = loadRunningCycleAnimationAtlas();
      final secondLoad = loadRunningCycleAnimationAtlas();
      final atlas = await firstLoad;
      return (
        isCached: identical(firstLoad, secondLoad),
        width: atlas.width,
        height: atlas.height,
      );
    });

    expect(result!.isCached, isTrue);
    expect(result.width, 1672);
    expect(result.height, 941);
  });

  test('continuous guide crosses landing support push-off recovery landing',
      () {
    final frames = runningCycleGuideLoopFrameOrderForTesting();
    expect(frames, <int>[4, 5, 6, 7, 0, 1, 2, 3]);
    expect(
      frames.map(runningCycleGuidePhaseForFrame).toList(growable: false),
      <RunningCycleGuidePhase>[
        RunningCycleGuidePhase.landing,
        RunningCycleGuidePhase.support,
        RunningCycleGuidePhase.pushOff,
        RunningCycleGuidePhase.recovery,
        RunningCycleGuidePhase.landing,
        RunningCycleGuidePhase.support,
        RunningCycleGuidePhase.pushOff,
        RunningCycleGuidePhase.recovery,
      ],
    );
  });

  test('continuous guide aligns per-row ground and normalizes runner scale',
      () {
    final presentations = runningCycleGuideLoopFrameOrderForTesting()
        .map(runningCycleGuidePresentationForFrame)
        .toList(growable: false);

    expect(
      presentations.map((item) => item.scale).every((scale) {
        return scale >= 0.99 && scale <= 1.02;
      }),
      isTrue,
    );
    expect(
      presentations.map((item) => item.sourceGroundY).toSet(),
      <double>{403.0, 425.0},
    );
    expect(
      presentations.map((item) => item.targetGroundY).toSet(),
      <double>{414.0},
    );

    const size = Size(320, 360);
    const aspectRatio = 418 / 470.5;
    final destinations = runningCycleGuideLoopFrameOrderForTesting()
        .map(
          (frame) => runningCycleGuideDestinationRectForFrame(
            size,
            aspectRatio,
            frame,
          ),
        )
        .toList(growable: false);
    final groundYs = destinations.map((rect) {
      final presentation = runningCycleGuidePresentationForFrame(
        runningCycleGuideLoopFrameOrderForTesting()[destinations.indexOf(rect)],
      );
      return rect.top + rect.height * presentation.sourceGroundY / 470.5;
    }).toList(growable: false);

    final widths = destinations.map((rect) => rect.width).toList();
    expect(
      widths.reduce((a, b) => a > b ? a : b) /
          widths.reduce((a, b) => a < b ? a : b),
      lessThan(1.04),
    );
    for (final groundY in groundYs.skip(1)) {
      expect(groundY, closeTo(groundYs.first, 0.001));
    }
  });

  testWidgets('reduced motion starts paused with explicit controls', (
    WidgetTester tester,
  ) async {
    await _pumpPlayer(tester, disableAnimations: true);

    expect(find.text('Continuous form loop'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('running-coach-good-form-cycle-play-pause')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('running-coach-good-form-cycle-speed')),
      findsOneWidget,
    );
    expect(find.text('Play'), findsOneWidget);
    await _expectSourceRectForFrame(tester, 4);

    await tester.pump(const Duration(seconds: 1));
    await _expectSourceRectForFrame(tester, 4);
  });

  testWidgets('normal motion plays through the next phase', (
    WidgetTester tester,
  ) async {
    await _pumpPlayer(tester, disableAnimations: false);

    expect(find.text('Pause'), findsOneWidget);
    await _expectSourceRectForFrame(tester, 4);

    await tester.pump(const Duration(milliseconds: 360));
    expect(
      find.byKey(
        const ValueKey('running-coach-good-form-active-phase-support'),
      ),
      findsOneWidget,
    );
    await _expectSourceRectForFrame(tester, 5);
  });

  testWidgets('phase selector and frame step update labels and frame', (
    WidgetTester tester,
  ) async {
    await _pumpPlayer(tester, disableAnimations: true);

    final pushOffPhase = find.byKey(
      const ValueKey('running-coach-good-form-phase-2'),
    );
    await tester.ensureVisible(pushOffPhase);
    await tester.tap(pushOffPhase);
    await tester.pump();

    expect(
      find.byKey(
        const ValueKey('running-coach-good-form-active-phase-pushOff'),
      ),
      findsOneWidget,
    );
    await _expectSourceRectForFrame(tester, 6);

    final step = find.byKey(
      const ValueKey('running-coach-good-form-cycle-step'),
    );
    await tester.ensureVisible(step);
    await tester.tap(step);
    await tester.pump();

    expect(
      find.byKey(
        const ValueKey('running-coach-good-form-active-phase-recovery'),
      ),
      findsOneWidget,
    );
    await _expectSourceRectForFrame(tester, 7);
  });

  testWidgets('localized controls fit compact Korean layout', (
    WidgetTester tester,
  ) async {
    await _pumpPlayer(
      tester,
      locale: const Locale('ko'),
      size: const Size(320, 780),
      disableAnimations: true,
    );

    expect(find.text('재생'), findsOneWidget);
    expect(find.text('다음 프레임'), findsOneWidget);
    expect(find.text('보통'), findsOneWidget);
    expect(find.text('느리게'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Finder get _atlasFramePaint => find.byKey(
      const ValueKey('running-coach-good-form-cycle-atlas-frame'),
      skipOffstage: false,
    );

Future<void> _expectSourceRectForFrame(
  WidgetTester tester,
  int frame,
) async {
  final atlas = await tester.runAsync(loadRunningCycleAnimationAtlas);
  final atlasPaint = _atlasFramePaint;

  expect(atlasPaint, paintsExactlyCountTimes(#drawImageRect, 1));
  expect(
    atlasPaint,
    paints
      ..drawImageRect(
        source: runningCycleGuideSourceRectForFrame(atlas!, frame),
      ),
  );
}

Future<void> _pumpPlayer(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  Size size = const Size(390, 844),
  bool disableAnimations = true,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.runAsync(() async {
    await loadRunningCycleAnimationAtlas();
  });
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          disableAnimations: disableAnimations,
        ),
        child: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: RunningCycleGuidePlayer(),
          ),
        ),
      ),
    ),
  );
  for (var i = 0; i < 10 && _atlasFramePaint.evaluate().isEmpty; i++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    await tester.pump(const Duration(milliseconds: 16));
  }
}
