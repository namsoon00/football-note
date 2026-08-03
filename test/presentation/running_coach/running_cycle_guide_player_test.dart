import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/running_coach/running_cycle_guide_player.dart';

void main() {
  testWidgets('running-cycle animation atlas is bundled and cached', (
    WidgetTester tester,
  ) async {
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

  testWidgets('playback controls contain both icon and Korean text', (
    WidgetTester tester,
  ) async {
    await _pumpPlayer(tester, locale: const Locale('ko'));

    final playPause = find.byKey(
      const ValueKey('running-coach-good-form-cycle-play-pause'),
    );
    final slowView = find.byKey(
      const ValueKey('running-coach-good-form-cycle-slow-view'),
    );
    final step = find.byKey(
      const ValueKey('running-coach-good-form-cycle-step'),
    );

    expect(
      find.descendant(
          of: playPause, matching: find.byIcon(Icons.play_arrow_rounded)),
      findsOneWidget,
    );
    expect(find.descendant(of: playPause, matching: find.text('재생')),
        findsOneWidget);
    expect(
      find.descendant(
        of: slowView,
        matching: find.byIcon(Icons.slow_motion_video_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: slowView, matching: find.text('천천히 보기')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: step, matching: find.byIcon(Icons.skip_next_rounded)),
      findsOneWidget,
    );
    expect(find.descendant(of: step, matching: find.text('한 단계씩')),
        findsOneWidget);

    await tester.tap(playPause);
    await tester.pump();

    expect(
      find.descendant(
          of: playPause, matching: find.byIcon(Icons.pause_rounded)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: playPause, matching: find.text('일시정지')),
      findsOneWidget,
    );

    await tester.tap(playPause);
    await tester.pump();
    expect(find.descendant(of: playPause, matching: find.text('재생')),
        findsOneWidget);
  });

  testWidgets('phase selection pauses and changes active phase content', (
    WidgetTester tester,
  ) async {
    await _pumpPlayer(tester);

    final playPause = find.byKey(
      const ValueKey('running-coach-good-form-cycle-play-pause'),
    );
    await tester.ensureVisible(playPause);
    await tester.pump();
    await tester.tap(playPause);
    await tester.pump();
    expect(find.text('Pause'), findsOneWidget);

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
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Pause'), findsNothing);
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

Future<void> _pumpPlayer(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  Size size = const Size(390, 844),
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
        data: MediaQueryData(size: size, disableAnimations: true),
        child: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: RunningCycleGuidePlayer(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
