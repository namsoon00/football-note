import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/real_match_replay.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/scan_pass_game_screen.dart';
import 'package:football_note/presentation/theme/app_theme.dart';

late RealMatchReplayData _testReplay;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  setUpAll(() {
    _testReplay = RealMatchReplayData.fromJsonString(
      File('assets/scan_pass_replay/replay-data.json').readAsStringSync(),
    );
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
    expect(_slider(tester).value, closeTo(2.44, .001));
    expect(
      tester
          .widget<FilterChip>(
              find.byKey(const ValueKey<String>('replay-explanation')))
          .selected,
      isTrue,
    );
    expect(find.textContaining('Pass into space'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ordinary end becomes guided replay then restart',
      (tester) async {
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
    expect(find.text(l10n.realMatchReplayPhaseAdvanceTitle), findsOneWidget);
    expect(
      find.text(l10n.realMatchReplayObservationKicker(
        l10n.realMatchReplayPhaseAdvance,
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
    expect(find.text(l10n.realMatchReplayPhaseRecoveryTitle), findsOneWidget);
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
      await tester.pumpWidget(_app(locale: locale));
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
}) =>
    MaterialApp(
      theme: appTheme ? AppTheme.light() : null,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
        child: child!,
      ),
      home: home ??
          ScanPassRealMatchReplayScreen(
            dataLoader: () async => _testReplay,
          ),
    );
