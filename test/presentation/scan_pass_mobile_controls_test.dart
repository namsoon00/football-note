import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/scan_pass_game_screen.dart';

void main() {
  for (final config in [
    (size: const Size(320, 568), scale: 1.0),
    (size: const Size(390, 844), scale: 1.3),
  ]) {
    testWidgets(
        'phone ${config.size} keeps both timed decision grids within reach',
        (tester) async {
      tester.view.physicalSize = config.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(config.scale),
          ),
          child: child!,
        ),
        home: ScanPassGameScreen(
          optionRepository: _MemoryOptions(),
          seed: 7,
          previewDuration: const Duration(milliseconds: 200),
          passAnimationDuration: Duration.zero,
        ),
      ));
      final start = find.byKey(
        const ValueKey<String>('scan-pass-start-challenge-button'),
      );
      // Only the untimed intro may scroll. Timed choices must already be visible.
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pump(const Duration(milliseconds: 20));
      final scan = find.byKey(const ValueKey<String>('scan-pass-scan-button'));
      expect(scan.hitTestable(), findsOneWidget);
      expect(
          tester.getRect(scan).bottom, lessThanOrEqualTo(config.size.height));
      expect(
        find.text('소유 지키기').evaluate().isNotEmpty ||
            find.text('득점 추격').evaluate().isNotEmpty,
        isTrue,
      );
      await tester.pump(const Duration(milliseconds: 250));

      void expectVisibleControls(List<String> keys) {
        final screenHeight =
            tester.view.physicalSize.height / tester.view.devicePixelRatio;
        for (final key in keys) {
          final finder = find.byKey(ValueKey<String>(key));
          expect(finder.hitTestable(), findsOneWidget, reason: key);
          final bounds = tester.getRect(finder);
          expect(bounds.top, greaterThanOrEqualTo(0), reason: key);
          expect(bounds.bottom, lessThanOrEqualTo(screenHeight), reason: key);
          expect(bounds.height, greaterThanOrEqualTo(44), reason: key);
        }
      }

      expectVisibleControls(<String>[
        'scan-pass-scan-button',
        'scan-pass-touch-upper',
        'scan-pass-touch-lower',
        'scan-pass-touch-turn',
        'scan-pass-touch-return',
      ]);
      await tester.tap(find.byKey(
        const ValueKey<String>('scan-pass-touch-upper'),
      ));
      await tester.pump();
      expectVisibleControls(<String>[
        'scan-pass-scan-button',
        'scan-pass-next-pass-4',
        'scan-pass-next-pass-8',
        'scan-pass-next-pass-9',
        'scan-pass-next-hold-8',
      ]);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('first touch finishes before the next choice, including resume',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_transitionApp());
    await tester.ensureVisible(find.byKey(
      const ValueKey<String>('scan-pass-practice-button'),
    ));
    await tester.tap(find.byKey(
      const ValueKey<String>('scan-pass-practice-button'),
    ));
    await tester.pump();
    await tester.tap(find.byKey(
      const ValueKey<String>('scan-pass-ready-button'),
    ));
    await tester.pump();
    await tester.tap(find.byKey(
      const ValueKey<String>('scan-pass-touch-upper'),
    ));
    await tester.pump();
    final next = find.byKey(
      const ValueKey<String>('scan-pass-next-pass-8'),
    );
    expect(next.hitTestable(), findsNothing);
    await tester.pump(const Duration(milliseconds: 100));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump(const Duration(seconds: 2));
    expect(next.hitTestable(), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(next.hitTestable(), findsOneWidget);
    await tester.tap(next);
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('scan-pass-review-panel')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('intercepted first return goes directly to review',
      (tester) async {
    const engine = ScanPassMatchEngine();
    final seed = List<int>.generate(100, (index) => index).firstWhere((seed) {
      final scenario =
          ScanPassScenarioLibrary(seed: seed).generateSession().first;
      return <Duration>[Duration.zero, const Duration(milliseconds: 150)].every(
          (time) => engine
              .applyFirstTouch(scenario, ScanPassFirstTouch.returnTo4,
                  decisionTime: time)
              .ballLost);
    });
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_transitionApp(seed: seed, animate: false));
    await tester.ensureVisible(find.byKey(
      const ValueKey<String>('scan-pass-start-challenge-button'),
    ));
    await tester.tap(find.byKey(
      const ValueKey<String>('scan-pass-start-challenge-button'),
    ));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.tap(find.byKey(
      const ValueKey<String>('scan-pass-touch-return'),
    ));
    await tester.pump();

    expect(find.byKey(const ValueKey<String>('scan-pass-review-panel')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('scan-pass-next-support-upper')),
        findsNothing);
    final summary = tester.widget<Text>(
      find.byKey(const ValueKey<String>('scan-pass-review-summary')),
    );
    expect(summary.data, contains('intercepted'));
    expect(summary.data, isNot(contains(' -> ')));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Widget _transitionApp({int seed = 7, bool animate = true}) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ScanPassGameScreen(
        optionRepository: _MemoryOptions(),
        seed: seed,
        previewDuration: const Duration(milliseconds: 1),
        passAnimationDuration:
            animate ? const Duration(seconds: 2) : Duration.zero,
      ),
    );

class _MemoryOptions implements OptionRepository {
  final _values = <String, dynamic>{};

  @override
  T? getValue<T>(String key) => _values[key] as T?;

  @override
  Future<void> setValue(String key, dynamic value) async =>
      _values[key] = value;

  @override
  List<String> getOptions(String key, List<String> defaults) => defaults;

  @override
  List<int> getIntOptions(String key, List<int> defaults) => defaults;

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async =>
      _values[key] = options;
}
