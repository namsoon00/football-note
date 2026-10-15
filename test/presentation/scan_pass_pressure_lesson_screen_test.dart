import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/scan_pass/scan_pass_pressure_lesson.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/scan_pass_game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets(
      'public entry observes immediately, then one touch reaches a new-state choice',
      (tester) async {
    await tester.pumpWidget(_app(
      home: ScanPassGameScreen(
        optionRepository: _Options(),
        seed: 19,
        previewDuration: Duration.zero,
        passAnimationDuration: Duration.zero,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(ScanPassPressureLessonScreen), findsOneWidget);
    expect(
        find.byKey(const ValueKey<String>('pressure-pitch')), findsOneWidget);
    expect(
        find.byKey(const ValueKey<String>('match-moment-pitch')), findsNothing);
    expect(
        find
            .byKey(const ValueKey<String>('pressure-action-touch-inside'))
            .hitTestable(),
        findsOneWidget);
    final firstState = _painter(tester).displayWorld as PressureWorld;

    await _tap(tester, 'pressure-action-touch-inside');

    expect(
        find
            .byKey(const ValueKey<String>('pressure-action-pass-support'))
            .hitTestable(),
        findsOneWidget);
    final nextState = _painter(tester).displayWorld as PressureWorld;
    expect(nextState.clock, greaterThan(firstState.clock));
    expect(nextState.ball.position.distanceTo(firstState.ball.position),
        greaterThan(1));
    expect(nextState.carrier?.role, PressureActorRole.receiver);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'terminal feedback keeps exact retry state and comparison preserves mine',
      (tester) async {
    await tester.pumpWidget(_app(
      home: const ScanPassPressureLessonScreen(
        seed: 19,
        observationDuration: Duration.zero,
        executionDuration: Duration.zero,
      ),
    ));
    await tester.pumpAndSettle();
    await _tap(tester, 'pressure-action-touch-inside');
    final lastDecision = _painter(tester).displayWorld as PressureWorld;
    await _tap(tester, 'pressure-action-pass-support');

    expect(find.byKey(const ValueKey<String>('pressure-review-panel')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('pressure-review-observed')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('pressure-review-effect')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('pressure-review-alternative')),
        findsOneWidget);
    final mineEffect = tester
        .widget<Text>(
            find.byKey(const ValueKey<String>('pressure-review-effect')))
        .data;

    await _tap(tester, 'pressure-compare');
    expect(find.byKey(const ValueKey<String>('pressure-return-attempt')),
        findsOneWidget);
    await _tap(tester, 'pressure-return-attempt');
    expect(
        tester
            .widget<Text>(
                find.byKey(const ValueKey<String>('pressure-review-effect')))
            .data,
        mineEffect);

    await _tap(tester, 'pressure-retry');
    final retryState = _painter(tester).displayWorld as PressureWorld;
    expect(identical(retryState, lastDecision), isTrue);
    expect(
        find
            .byKey(const ValueKey<String>('pressure-action-pass-support'))
            .hitTestable(),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('historical reference returns to the unchanged learner review',
      (tester) async {
    await tester.pumpWidget(_app(
      home: const ScanPassPressureLessonScreen(
        seed: 19,
        observationDuration: Duration.zero,
        executionDuration: Duration.zero,
      ),
    ));
    await tester.pumpAndSettle();
    await _tap(tester, 'pressure-action-pass-now');
    final effect = tester
        .widget<Text>(
            find.byKey(const ValueKey<String>('pressure-review-effect')))
        .data;

    await _tap(tester, 'pressure-reference', settle: false);
    await tester.pumpAndSettle();
    expect(find.byType(ScanPassMatchMomentScreen), findsOneWidget);
    expect(
        tester
            .widget<ScanPassMatchMomentScreen>(
                find.byType(ScanPassMatchMomentScreen))
            .referenceOnly,
        isTrue);
    expect(find.byKey(const ValueKey<String>('match-moment-pitch')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('match-choice-receive-inside')),
        findsNothing);
    expect(find.byKey(const ValueKey<String>('match-reference-replay')),
        findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('pressure-review-panel')),
        findsOneWidget);
    expect(
        tester
            .widget<Text>(
                find.byKey(const ValueKey<String>('pressure-review-effect')))
            .data,
        effect);
  });

  testWidgets('next situation cycles through six learning and two unseen cases',
      (tester) async {
    await tester.pumpWidget(_app(
      home: const ScanPassPressureLessonScreen(
        seed: 19,
        observationDuration: Duration.zero,
        executionDuration: Duration.zero,
      ),
    ));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
        tester.element(find.byType(ScanPassPressureLessonScreen)))!;

    for (var index = 0; index < 8; index++) {
      expect(
          find.text(l10n.pressureLessonProgress(index + 1, 8)), findsOneWidget);
      await _tap(tester, 'pressure-action-pass-now');
      expect(find.byKey(const ValueKey<String>('pressure-review-panel')),
          findsOneWidget);
      await _tap(tester, 'pressure-next');
    }

    expect(
        find.byKey(const ValueKey<String>('pressure-summary')), findsOneWidget);
    expect(find.text(l10n.pressureLessonSummaryConnections(0, 8)), findsNothing,
        reason: 'Summary must derive the recorded first attempts.');
    expect(tester.takeException(), isNull);
  });

  testWidgets('jumping to situation eight cannot skip missing first attempts',
      (tester) async {
    await tester.pumpWidget(_app(
      home: const ScanPassPressureLessonScreen(
        seed: 19,
        observationDuration: Duration.zero,
        executionDuration: Duration.zero,
      ),
    ));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
        tester.element(find.byType(ScanPassPressureLessonScreen)))!;

    await _tap(tester, 'pressure-more', settle: false);
    await tester.pumpAndSettle();
    await _tap(tester, 'pressure-menu-situation-8');
    expect(find.text(l10n.pressureLessonProgress(8, 8)), findsOneWidget);

    await _tap(tester, 'pressure-action-pass-now');
    await _tap(tester, 'pressure-next');

    expect(
        find.byKey(const ValueKey<String>('pressure-summary')), findsNothing);
    expect(find.text(l10n.pressureLessonProgress(1, 8)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final config in [
    (size: const Size(390, 844), locale: const Locale('ko')),
    (size: const Size(844, 390), locale: const Locale('ja')),
    (size: const Size(1280, 800), locale: const Locale('en')),
  ]) {
    testWidgets(
        'responsive ${config.size} ${config.locale.languageCode} keeps pitch, panel and targets separate',
        (tester) async {
      tester.view.physicalSize = config.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(
        locale: config.locale,
        textScale: 1.25,
        home: const ScanPassPressureLessonScreen(
          seed: 19,
          observationDuration: Duration.zero,
          executionDuration: Duration.zero,
        ),
      ));
      await tester.pumpAndSettle();

      final pitch =
          tester.getRect(find.byKey(const ValueKey<String>('pressure-pitch')));
      final panel = tester
          .getRect(find.byKey(const ValueKey<String>('pressure-instruction')));
      expect(pitch.height, greaterThan(config.size.height < 500 ? 150 : 280));
      expect(pitch.overlaps(panel), isFalse);
      final rects = <Rect>[];
      for (final key in [
        'pressure-action-touch-inside',
        'pressure-action-touch-outside',
        'pressure-action-pass-now',
        'pressure-action-pass-runner-now',
        'pressure-action-pass-back-now',
      ]) {
        final finder = find.byKey(ValueKey<String>(key));
        expect(finder.hitTestable(), findsOneWidget, reason: key);
        final rect = tester.getRect(finder);
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, greaterThanOrEqualTo(48));
        for (final previous in rects) {
          expect(rect.overlaps(previous), isFalse, reason: key);
        }
        rects.add(rect);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('pause, menu and lifecycle preserve the active observation',
      (tester) async {
    await tester.pumpWidget(_app(
      home: const ScanPassPressureLessonScreen(
        seed: 19,
        observationDuration: Duration(seconds: 2),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 200));
    await _tap(tester, 'pressure-more', settle: false);
    await tester.pumpAndSettle();
    final menuPaused = _painter(tester).displayWorld as PressureWorld;
    await tester.pump(const Duration(milliseconds: 300));
    expect((_painter(tester).displayWorld as PressureWorld).clock,
        closeTo(menuPaused.clock, 1e-7));
    await tester.tapAt(const Offset(4, 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect((_painter(tester).displayWorld as PressureWorld).clock,
        greaterThan(menuPaused.clock));

    final beforePause = _painter(tester).displayWorld as PressureWorld;
    await _tap(tester, 'pressure-pause', settle: false);
    await tester.pump(const Duration(milliseconds: 400));
    final paused = _painter(tester).displayWorld as PressureWorld;
    expect(paused.clock, closeTo(beforePause.clock, 1e-7));

    await _tap(tester, 'pressure-pause', settle: false);
    await tester.pump(const Duration(milliseconds: 120));
    final resumed = _painter(tester).displayWorld as PressureWorld;
    expect(resumed.clock, greaterThan(paused.clock));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(milliseconds: 250));
    final background = _painter(tester).displayWorld as PressureWorld;
    expect(background.clock, closeTo(resumed.clock, 1e-7));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect((_painter(tester).displayWorld as PressureWorld).clock,
        greaterThan(background.clock));
    expect(tester.takeException(), isNull);
  });
}

dynamic _painter(WidgetTester tester) => tester
    .widget<CustomPaint>(find.byKey(const ValueKey<String>('pressure-pitch')))
    .painter;

Future<void> _tap(WidgetTester tester, String key, {bool settle = true}) async {
  final finder = find.byKey(ValueKey<String>(key));
  expect(finder.hitTestable(), findsOneWidget, reason: key);
  await tester.tap(finder);
  await tester.pump();
  if (settle) await tester.pumpAndSettle();
}

Widget _app({
  required Widget home,
  Locale locale = const Locale('en'),
  double textScale = 1,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: home,
  );
}

class _Options implements OptionRepository {
  @override
  List<int> getIntOptions(String key, List<int> defaults) => defaults;

  @override
  List<String> getOptions(String key, List<String> defaults) => defaults;

  @override
  T? getValue<T>(String key) => null;

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {}

  @override
  Future<void> setValue(String key, dynamic value) async {}
}
