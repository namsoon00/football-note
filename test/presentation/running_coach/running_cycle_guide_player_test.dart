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

  test('static guide maps each phase to inspected representative frames', () {
    expect(
      RunningCycleGuidePhase.values
          .map<int>(
            runningCycleGuideRepresentativeFrameForPhase,
          )
          .toList(),
      [3, 4, 5, 6],
    );
  });

  test('static guide presentations share a bounded ground baseline', () {
    final presentations = RunningCycleGuidePhase.values
        .map(runningCycleGuidePresentationForPhase)
        .toList();

    expect(presentations.map((presentation) => presentation.frame), [
      3,
      4,
      5,
      6,
    ]);
    expect(
      presentations.map((presentation) => presentation.targetGroundY).toSet(),
      {403.0},
    );
    expect(presentations.first.sourceGroundY, 425.0);
    expect(
      presentations.skip(1).map((presentation) => presentation.sourceGroundY),
      everyElement(403.0),
    );
    expect(presentations.first.scale, closeTo(1.025, 0.0001));
    expect(
      presentations.skip(1).map((presentation) => presentation.scale),
      everyElement(1.0),
    );

    final scales = presentations
        .map((presentation) => presentation.scale)
        .toList(growable: false);
    final scaleRange = scales.reduce((a, b) => a > b ? a : b) -
        scales.reduce((a, b) => a < b ? a : b);
    expect(scaleRange, lessThanOrEqualTo(0.025));

    const size = Size(320, 360);
    const aspectRatio = 418 / 470.5;
    final mappedGroundYs = presentations.map((presentation) {
      final destination = runningCycleGuideDestinationRectForPhase(
        size,
        aspectRatio,
        presentation.phase,
      );
      expect(destination.left, greaterThanOrEqualTo(-size.width * 0.03));
      expect(destination.right, lessThanOrEqualTo(size.width * 1.03));
      expect(destination.top, greaterThanOrEqualTo(-size.height * 0.08));
      expect(destination.bottom, lessThanOrEqualTo(size.height));
      return destination.top +
          destination.height * presentation.sourceGroundY / 470.5;
    }).toList();
    for (final groundY in mappedGroundYs.skip(1)) {
      expect(groundY, closeTo(mappedGroundYs.first, 0.001));
    }
  });

  testWidgets('static guide uses ordered v2 atlas source rects', (
    WidgetTester tester,
  ) async {
    final atlas = await tester.runAsync(loadRunningCycleAnimationAtlas);

    expect(
      RunningCycleGuidePhase.values
          .map(runningCycleGuideRepresentativeFrameForPhase)
          .map((frame) => runningCycleGuideSourceRectForFrame(atlas!, frame))
          .toList(),
      [
        const Rect.fromLTWH(1254, 0, 418, 470.5),
        const Rect.fromLTWH(0, 470.5, 418, 470.5),
        const Rect.fromLTWH(418, 470.5, 418, 470.5),
        const Rect.fromLTWH(836, 470.5, 418, 470.5),
      ],
    );
  });

  testWidgets('renders one static atlas frame and does not autoplay', (
    WidgetTester tester,
  ) async {
    await _pumpPlayer(tester, disableAnimations: false);

    expect(
      find.text(
        'The four reference images are static frames, not continuous video '
        'or your uploaded run. Each selected runner is displayed at the same '
        'scale on the same ground line; use the blue mark to inspect that '
        'phase relationship.',
      ),
      findsOneWidget,
    );
    await _expectStaticSourceRect(tester, RunningCycleGuidePhase.landing);

    await tester.pump(const Duration(seconds: 2));

    await _expectStaticSourceRect(tester, RunningCycleGuidePhase.landing);
  });

  testWidgets('does not expose autoplay, play pause, or slow controls', (
    WidgetTester tester,
  ) async {
    await _pumpPlayer(tester, locale: const Locale('ko'));

    final controls = find.byKey(
      const ValueKey('running-coach-good-form-cycle-controls'),
    );
    final step = find.byKey(
      const ValueKey('running-coach-good-form-cycle-step'),
    );

    expect(
      find.byKey(const ValueKey('running-coach-good-form-cycle-play-pause')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('running-coach-good-form-cycle-slow-view')),
      findsNothing,
    );
    expect(
        find.descendant(of: controls, matching: find.text('재생')), findsNothing);
    expect(find.descendant(of: controls, matching: find.text('일시정지')),
        findsNothing);
    expect(find.descendant(of: controls, matching: find.text('천천히 보기')),
        findsNothing);
    expect(
        find.descendant(
            of: controls, matching: find.byIcon(Icons.play_arrow_rounded)),
        findsNothing);
    expect(
        find.descendant(
            of: controls, matching: find.byIcon(Icons.pause_rounded)),
        findsNothing);
    expect(
        find.descendant(
            of: controls,
            matching: find.byIcon(Icons.slow_motion_video_rounded)),
        findsNothing);
    expect(
      find.descendant(of: step, matching: find.byIcon(Icons.skip_next_rounded)),
      findsOneWidget,
    );
    expect(find.descendant(of: step, matching: find.text('다음 단계')),
        findsOneWidget);
  });

  testWidgets('recovery action is labeled as restarting the references', (
    WidgetTester tester,
  ) async {
    await _pumpPlayer(tester);

    final step = find.byKey(
      const ValueKey('running-coach-good-form-cycle-step'),
    );
    await tester.ensureVisible(step);

    for (var i = 0; i < 3; i++) {
      await tester.tap(step);
      await tester.pump();
    }

    expect(
      find.byKey(
        const ValueKey('running-coach-good-form-active-phase-recovery'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: step, matching: find.text('Next phase')),
      findsNothing,
    );
    expect(
      find.descendant(of: step, matching: find.text('Restart four steps')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: step, matching: find.byIcon(Icons.replay_rounded)),
      findsOneWidget,
    );
    await _expectStaticSourceRect(tester, RunningCycleGuidePhase.recovery);

    await tester.tap(step);
    await tester.pump();

    expect(
      find.byKey(
        const ValueKey('running-coach-good-form-active-phase-landing'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: step, matching: find.text('Next phase')),
      findsOneWidget,
    );
    await _expectStaticSourceRect(tester, RunningCycleGuidePhase.landing);
  });

  testWidgets('phase selection and next action show one static source rect', (
    WidgetTester tester,
  ) async {
    await _pumpPlayer(tester);

    await _expectStaticSourceRect(tester, RunningCycleGuidePhase.landing);

    final pushOffPhase = find.byKey(
      const ValueKey('running-coach-good-form-phase-2'),
    );
    await tester.ensureVisible(pushOffPhase);
    await tester.pump();
    await tester.tap(pushOffPhase);
    await tester.pump();

    expect(
      find.byKey(
        const ValueKey('running-coach-good-form-active-phase-pushOff'),
      ),
      findsOneWidget,
    );
    expect(
      find.text(
          'Press down, then let the foot travel behind as the body moves forward.'),
      findsOneWidget,
    );
    expect(
      find.text('Blue mark: Push-off toe and foot against the ground line'),
      findsOneWidget,
    );
    await _expectStaticSourceRect(tester, RunningCycleGuidePhase.pushOff);

    await tester.pump(const Duration(seconds: 2));
    await _expectStaticSourceRect(tester, RunningCycleGuidePhase.pushOff);

    final step = find.byKey(
      const ValueKey('running-coach-good-form-cycle-step'),
    );
    await tester.ensureVisible(step);
    await tester.pump();
    await tester.tap(step);
    await tester.pump();

    expect(
      find.byKey(
        const ValueKey('running-coach-good-form-active-phase-recovery'),
      ),
      findsOneWidget,
    );
    await _expectStaticSourceRect(tester, RunningCycleGuidePhase.recovery);
  });

  testWidgets('focus overlay and localized legend change with selected phase', (
    WidgetTester tester,
  ) async {
    await _pumpPlayer(tester);

    expect(_focusOverlayPaint(RunningCycleGuidePhase.landing), findsOneWidget);
    expect(
      _focusOverlayPaint(RunningCycleGuidePhase.landing),
      paintsExactlyCountTimes(#drawCircle, 3),
    );
    expect(
      find.text('Blue mark: Landing foot near the shared ground line'),
      findsOneWidget,
    );

    final supportPhase = find.byKey(
      const ValueKey('running-coach-good-form-phase-1'),
    );
    await tester.ensureVisible(supportPhase);
    await tester.tap(supportPhase);
    await tester.pump();

    expect(_focusOverlayPaint(RunningCycleGuidePhase.support), findsOneWidget);
    expect(
      find.text('Blue mark: Supporting knee over the loading leg'),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('running-coach-good-form-focus-legend-support'),
      ),
      findsOneWidget,
    );

    final recoveryPhase = find.byKey(
      const ValueKey('running-coach-good-form-phase-3'),
    );
    await tester.ensureVisible(recoveryPhase);
    await tester.tap(recoveryPhase);
    await tester.pump();

    expect(_focusOverlayPaint(RunningCycleGuidePhase.recovery), findsOneWidget);
    expect(
      _focusOverlayPaint(RunningCycleGuidePhase.recovery),
      paintsExactlyCountTimes(#drawCircle, 6),
    );
    expect(
      find.text('Blue mark: Recovery knee and heel moving through together'),
      findsOneWidget,
    );
  });

  testWidgets('step control travels landing support push-off recovery', (
    WidgetTester tester,
  ) async {
    await _pumpPlayer(tester);

    final step = find.byKey(
      const ValueKey('running-coach-good-form-cycle-step'),
    );
    await tester.ensureVisible(step);

    expect(
      find.byKey(
        const ValueKey('running-coach-good-form-active-phase-landing'),
      ),
      findsOneWidget,
    );

    await tester.tap(step);
    await tester.pump();
    expect(
      find.byKey(
        const ValueKey('running-coach-good-form-active-phase-support'),
      ),
      findsOneWidget,
    );

    await tester.tap(step);
    await tester.pump();
    expect(
      find.byKey(
        const ValueKey('running-coach-good-form-active-phase-pushOff'),
      ),
      findsOneWidget,
    );

    await tester.tap(step);
    await tester.pump();
    expect(
      find.byKey(
        const ValueKey('running-coach-good-form-active-phase-recovery'),
      ),
      findsOneWidget,
    );

    await tester.tap(step);
    await tester.pump();
    expect(
      find.byKey(
        const ValueKey('running-coach-good-form-active-phase-landing'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('fits the running-cycle guide at 320px without overflow', (
    WidgetTester tester,
  ) async {
    await _pumpPlayer(tester, size: const Size(320, 780));

    expect(
      find.byKey(const ValueKey('running-coach-good-form-cycle')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Finder get _atlasFramePaint => find.byKey(
      const ValueKey('running-coach-good-form-cycle-atlas-frame'),
      skipOffstage: false,
    );

Finder _focusOverlayPaint(RunningCycleGuidePhase phase) => find.byKey(
      ValueKey(
        'running-coach-good-form-cycle-focus-overlay-${phase.name}',
      ),
      skipOffstage: false,
    );

Future<void> _expectStaticSourceRect(
  WidgetTester tester,
  RunningCycleGuidePhase phase,
) async {
  final atlas = await tester.runAsync(loadRunningCycleAnimationAtlas);
  final frame = runningCycleGuideRepresentativeFrameForPhase(phase);
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
