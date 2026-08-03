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
      [4, 5, 2, 3],
    );
  });

  testWidgets('renders one static atlas frame and does not autoplay', (
    WidgetTester tester,
  ) async {
    await _pumpPlayer(tester, disableAnimations: false);

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
