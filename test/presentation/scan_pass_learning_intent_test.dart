import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/scan_pass_game_screen.dart';
import 'package:football_note/presentation/screens/scan_pass_learning_intent.dart';

void main() {
  const engine = ScanPassMatchEngine();

  test('opening view hides local rear pressure but keeps the wider scene', () {
    final scenario = ScanPassScenarioLibrary.byId('rear-upper-protect');
    final time = scenario.ballTravelTime * 0.3;
    final receiver = scenario.receiver.at(time);
    final hidden = scenario.defendersAt(time).where(
          (defender) => ScanPassLearningSpace.needsRearCheck(
            defender.position,
            receiver,
          ),
        );
    expect(hidden.map((defender) => defender.id), [1]);
    expect(scenario.defenders.length - hidden.length, 2);
  });

  test('front-facing retreat scene does not hide visible front defenders', () {
    final scenario = ScanPassScenarioLibrary.byId('retreat-turn-chase');
    final time = scenario.ballTravelTime * 0.3;
    final receiver = scenario.receiver.at(time);
    expect(
      scenario.defendersAt(time).any(
            (defender) => ScanPassLearningSpace.needsRearCheck(
              defender.position,
              receiver,
            ),
          ),
      isFalse,
    );
  });

  test('a pass preview points to the chosen teammate even if it will be lost',
      () {
    final scenario = ScanPassScenarioLibrary.byId('return-wall-upper');
    final first = engine.applyFirstTouch(
      scenario,
      ScanPassFirstTouch.lowerTouch,
      decisionTime: Duration.zero,
    );
    final outcome = engine.evaluatePlan(
      scenario,
      first.action,
      ScanPassNextAction.passTo8,
      firstDecisionTime: Duration.zero,
      secondDecisionTime: Duration.zero,
    );
    expect(outcome.outcome, ScanPassOutcomeType.intercepted);

    final intent = ScanPassLearningIntent.nextAction(
      first,
      ScanPassNextAction.passTo8,
    ).single;
    final teammate = scenario.support.at(first.completedAt).position;
    expect(intent.to.distanceTo(teammate), lessThan(0.0001));
    expect(intent.to.distanceTo(outcome.interceptionPoint!), greaterThan(0.02));
  });

  test('return preview reaches number four without revealing interception', () {
    final first = ScanPassScenarioLibrary.scenarios
        .map((scenario) => engine.applyFirstTouch(
              scenario,
              ScanPassFirstTouch.returnTo4,
              decisionTime: Duration.zero,
            ))
        .firstWhere((state) => state.returnIntercepted);
    final intent = ScanPassLearningIntent.firstTouch(first);
    final teammate =
        first.scenario.centerBack.at(first.touchStartTime).position;
    expect(intent.to.distanceTo(teammate), lessThan(0.0001));
    expect(intent.to.distanceTo(first.returnInterceptionPoint!),
        greaterThan(0.02));
  });

  test('off-ball preview shows the run, without revealing the following pass',
      () {
    final scenario = ScanPassScenarioLibrary.byId('return-wall-upper');
    final first = engine.applyFirstTouch(
      scenario,
      ScanPassFirstTouch.returnTo4,
      decisionTime: Duration.zero,
    );
    expect(first.ballLost, isFalse);
    final outcome = engine.evaluatePlan(
      scenario,
      first.action,
      ScanPassNextAction.supportForward,
      firstDecisionTime: Duration.zero,
      secondDecisionTime: Duration.zero,
    );
    expect(outcome.outcome, ScanPassOutcomeType.intercepted);
    final intentions = ScanPassLearningIntent.nextAction(
      first,
      ScanPassNextAction.supportForward,
    );
    expect(intentions, hasLength(1));
    expect(intentions.single.type, ScanPassPathType.offBallRun);
    expect(intentions.single.to.x, greaterThan(first.receiverPosition.x));
    expect(intentions.single.to.distanceTo(outcome.interceptionPoint!),
        greaterThan(0.02));
  });

  testWidgets('phone selection keeps its field preview and execute in view',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_learningApp());
    await tester.pumpAndSettle();
    for (final key in [
      'scan-pass-understand-scene-button',
      'scan-pass-scan-button',
      'scan-pass-receive-button',
      'scan-pass-touch-lower',
    ]) {
      await _tap(tester, key);
    }
    final field = find.byKey(
      const ValueKey<String>('scan-pass-active-field'),
    );
    final execute = find.byKey(
      const ValueKey<String>('scan-pass-execute-first-touch'),
    );
    expect(execute.hitTestable(), findsOneWidget,
        reason: 'The learner must see the action that commits this preview.');
    final fieldBounds = tester.getRect(field);
    expect(fieldBounds.top, greaterThanOrEqualTo(0),
        reason: 'Do not leave the preview above the scrolled choice list.');
    expect(fieldBounds.bottom, lessThanOrEqualTo(568),
        reason: 'The intended route must be visible before execution.');
    expect(tester.takeException(), isNull);
  });

  testWidgets('help pauses a receive animation and continues the same scene',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_learningApp(
      receiveDuration: const Duration(seconds: 2),
    ));
    await tester.pumpAndSettle();
    await _tap(tester, 'scan-pass-understand-scene-button');
    await _tap(tester, 'scan-pass-scan-button');
    await tester.tap(find.byKey(
      const ValueKey<String>('scan-pass-receive-button'),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    final l10n = AppLocalizations.of(
      tester.element(find.byType(ScanPassGameScreen)),
    )!;
    await tester.tap(find.byKey(
      const ValueKey<String>('scan-pass-help-button'),
    ));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump(const Duration(milliseconds: 50));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 30));
    expect(
      find.byKey(const ValueKey<String>('scan-pass-touch-upper'),
          skipOffstage: false),
      findsNothing,
      reason: 'Reading help must not move the scene past the receive.',
    );
    await tester.tap(find.text(l10n.scanPassHelpCloseAction));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('scan-pass-touch-upper')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey<String>(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Widget _learningApp({Duration receiveDuration = Duration.zero}) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ScanPassGameScreen(
        optionRepository: _LearningOptions(),
        seed: 7,
        previewDuration: receiveDuration,
        passAnimationDuration: Duration.zero,
      ),
    );

class _LearningOptions implements OptionRepository {
  @override
  T? getValue<T>(String key) => null;
  @override
  Future<void> setValue(String key, dynamic value) async {}
  @override
  List<String> getOptions(String key, List<String> defaults) => defaults;
  @override
  List<int> getIntOptions(String key, List<int> defaults) => defaults;
  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {}
}
