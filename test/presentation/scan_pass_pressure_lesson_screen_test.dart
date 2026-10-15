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
    final firstFacts = tester
        .widget<Text>(
            find.byKey(const ValueKey<String>('pressure-situation-facts')))
        .data;
    final firstCamera = _painter(tester).viewBounds as Rect;
    expect(firstCamera.width * ScanPassPressureEngine.fieldLengthMetres,
        lessThan(46));
    expect(
        firstCamera.right,
        lessThan(ScanPassPressureEngine.localOffsideReferenceMetres /
            ScanPassPressureEngine.fieldLengthMetres));
    for (final option in const ScanPassPressureEngine()
        .optionsFor(firstState, PressureDecisionStage.firstContact)) {
      final x =
          option.action.target.x / ScanPassPressureEngine.fieldLengthMetres;
      final y =
          option.action.target.y / ScanPassPressureEngine.fieldWidthMetres;
      expect(x, inInclusiveRange(firstCamera.left, firstCamera.right),
          reason: option.key);
      expect(y, inInclusiveRange(firstCamera.top, firstCamera.bottom),
          reason: option.key);
    }

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
    final nextFacts = tester
        .widget<Text>(
            find.byKey(const ValueKey<String>('pressure-situation-facts')))
        .data;
    expect(nextFacts, isNot(firstFacts));
    expect(
        tester
            .widget<Text>(
                find.byKey(const ValueKey<String>('pressure-situation-task')))
            .data,
        contains('#'));
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
    final l10n = AppLocalizations.of(
        tester.element(find.byType(ScanPassPressureLessonScreen)))!;
    await _tap(tester, 'pressure-action-touch-inside');
    final lastDecision = _painter(tester).displayWorld as PressureWorld;
    final retryFacts = tester
        .widget<Text>(
            find.byKey(const ValueKey<String>('pressure-situation-facts')))
        .data;
    await _tap(tester, 'pressure-action-pass-support');

    expect(find.byKey(const ValueKey<String>('pressure-review-panel')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('pressure-review-action')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('pressure-review-benefit')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('pressure-review-limitation')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('pressure-review-alternative')),
        findsOneWidget);
    expect(
        (_painter(tester).reviewResult as PressureSimulationResult).action.kind,
        PressureActionKind.pass,
        reason: 'Review should first explain the action that just finished.');
    await _tap(tester, 'pressure-review-first');
    final firstAction = tester
        .widget<Text>(
            find.byKey(const ValueKey<String>('pressure-review-action')))
        .data;
    final firstBenefit = tester
        .widget<Text>(
            find.byKey(const ValueKey<String>('pressure-review-benefit')))
        .data;
    expect(
        (_painter(tester).reviewResult as PressureSimulationResult).action.kind,
        PressureActionKind.firstTouch);

    await _tap(tester, 'pressure-review-next-action');
    final nextAction = tester
        .widget<Text>(
            find.byKey(const ValueKey<String>('pressure-review-action')))
        .data;
    final nextBenefit = tester
        .widget<Text>(
            find.byKey(const ValueKey<String>('pressure-review-benefit')))
        .data;
    expect(nextAction, contains('#'));
    expect(nextAction, isNot(firstAction));
    expect(firstBenefit, l10n.pressureLessonBenefitRetainedControl);
    expect(nextBenefit, l10n.pressureLessonBenefitNone,
        reason: 'An intercepted pass must not claim a completed connection.');
    final reviewedPass =
        _painter(tester).reviewResult as PressureSimulationResult;
    expect(reviewedPass.action.kind, PressureActionKind.pass);
    expect(reviewedPass.contact, isNotNull);
    expect((_painter(tester).displayWorld as PressureWorld).ball.position,
        reviewedPass.contact!.point);
    final reviewBounds = _painter(tester).viewBounds as Rect;
    for (final world in [reviewedPass.before, reviewedPass.after]) {
      final receiver = world.actorByRole(reviewedPass.intendedReceiverRole!);
      expect(
          reviewBounds.contains(Offset(
            receiver.position.x / ScanPassPressureEngine.fieldLengthMetres,
            receiver.position.y / ScanPassPressureEngine.fieldWidthMetres,
          )),
          isTrue,
          reason:
              'A blocked-pass review must still show the intended receiver.');
    }
    await _tap(tester, 'pressure-compare');
    expect(find.byKey(const ValueKey<String>('pressure-return-attempt')),
        findsOneWidget);
    await _tap(tester, 'pressure-return-attempt');
    expect(
        tester
            .widget<Text>(
                find.byKey(const ValueKey<String>('pressure-review-benefit')))
            .data,
        nextBenefit);

    await _tap(tester, 'pressure-retry');
    final retryState = _painter(tester).displayWorld as PressureWorld;
    expect(identical(retryState, lastDecision), isTrue);
    expect(
        find
            .byKey(const ValueKey<String>('pressure-action-pass-support'))
            .hitTestable(),
        findsOneWidget);
    expect(
        tester
            .widget<Text>(
                find.byKey(const ValueKey<String>('pressure-situation-facts')))
            .data,
        retryFacts);
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
    final limitation = tester
        .widget<Text>(
            find.byKey(const ValueKey<String>('pressure-review-limitation')))
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
            .widget<Text>(find
                .byKey(const ValueKey<String>('pressure-review-limitation')))
            .data,
        limitation);
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
      expect(_progressText(tester), startsWith('Situation ${index + 1}/8'));
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
    await _tap(tester, 'pressure-more', settle: false);
    await tester.pumpAndSettle();
    await _tap(tester, 'pressure-menu-situation-8');
    expect(_progressText(tester), startsWith('Situation 8/8'));

    await _tap(tester, 'pressure-action-pass-now');
    await _tap(tester, 'pressure-next');

    expect(
        find.byKey(const ValueKey<String>('pressure-summary')), findsNothing);
    expect(_progressText(tester), startsWith('Situation 1/8'));
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
      final ribbon = tester.getRect(
          find.byKey(const ValueKey<String>('pressure-situation-ribbon')));
      final overview = tester
          .getRect(find.byKey(const ValueKey<String>('pressure-overview')));
      expect(pitch.height, greaterThan(config.size.height < 500 ? 150 : 280));
      expect(pitch.overlaps(ribbon), isFalse);
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
        expect(rect.overlaps(overview), isFalse,
            reason: 'The context map must not hide the $key control.');
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

String _progressText(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const ValueKey<String>('pressure-progress')))
    .data!;

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
