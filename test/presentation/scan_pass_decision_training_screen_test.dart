import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/scan_pass/scan_pass_attack.dart';
import 'package:football_note/domain/scan_pass/scan_pass_decision.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/scan_pass_game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('default entry opens first-touch chain and links free attack',
      (tester) async {
    await tester.pumpWidget(_app(
      home: ScanPassGameScreen(
        optionRepository: _Options(),
        seed: 7,
        previewDuration: Duration.zero,
        passAnimationDuration: Duration.zero,
      ),
    ));
    await tester.pump();

    expect(find.byKey(const ValueKey<String>('chain-pitch')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('decision-action-forward')),
        findsNothing);
    expect(find.byKey(const ValueKey<String>('attack-start')), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('chain-free-attack')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('attack-pitch')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('attack-start')), findsOneWidget);
  });

  testWidgets('pre-reception selection queues without revealing a verdict',
      (tester) async {
    await tester.pumpWidget(_decisionApp(
      observationDuration: const Duration(milliseconds: 500),
      assessmentDuration: Duration.zero,
    ));

    await tester
        .tap(find.byKey(const ValueKey<String>('decision-action-forward')));
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('decision-review-result')),
        findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('decision-commit')));
    await tester.pump();
    expect(find.text('Choice queued. Watch the reception.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('decision-review-result')),
        findsOneWidget);
  });

  testWidgets('preview stays self-paced and review reflects domain assessment',
      (tester) async {
    const engine = DecisionEngine();
    final scenario = engine.scenario(
      DecisionLesson.rearPressure,
      variation: 3,
    );
    final expected =
        engine.assess(scenario, DecisionAction.wide, delaySeconds: 0);

    await tester.pumpWidget(_decisionApp(
      seed: 3,
      observationDuration: Duration.zero,
      assessmentDuration: Duration.zero,
    ));
    await tester.pump();

    await tester
        .tap(find.byKey(const ValueKey<String>('decision-action-wide')));
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('decision-review-result')),
        findsNothing);
    expect(find.text('Preview only. Execute after the reception.'),
        findsOneWidget);

    await tester.pump(const Duration(seconds: 30));
    expect(find.byKey(const ValueKey<String>('decision-review-result')),
        findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('decision-commit')));
    await tester.pump();
    final l10n = AppLocalizations.of(
        tester.element(find.byType(DecisionTrainingScreen)))!;
    expect(find.text(_qualityLabel(l10n, expected.quality)), findsOneWidget);
    expect(find.text(_reasonLabel(l10n, expected.reason)), findsOneWidget);
  });

  testWidgets('paired cue and alternative review preserve original outcome',
      (tester) async {
    const seed = 4;
    const engine = DecisionEngine();
    final firstScenario = engine.scenario(
      DecisionLesson.rearPressure,
      variation: seed,
    );
    final original = engine.assess(firstScenario, DecisionAction.forward);

    await tester.pumpWidget(_decisionApp(
      seed: seed,
      observationDuration: Duration.zero,
      assessmentDuration: Duration.zero,
    ));
    await tester.pump();

    await _chooseAndCommit(tester, 'decision-action-forward');
    var painter = _decisionPainter(tester);
    expect((painter.history as List<AttackTransition>).first.action,
        original.transitions.first.action);

    await tester
        .tap(find.byKey(const ValueKey<String>('decision-view-alternative')));
    await tester.pump();
    painter = _decisionPainter(tester);
    expect((painter.history as List<AttackTransition>).first.action,
        isNot(original.transitions.first.action));
    expect((painter.decisionBranchLabel as String).startsWith('Other choice'),
        isTrue);

    await tester.tap(find.byKey(const ValueKey<String>('decision-view-own')));
    await tester.pump();
    painter = _decisionPainter(tester);
    expect((painter.history as List<AttackTransition>).first.action,
        original.transitions.first.action);

    await tester.tap(find.byKey(const ValueKey<String>('decision-next')));
    await tester.pump();
    final paired = engine.scenario(
      DecisionLesson.rearPressure,
      changed: true,
      variation: seed,
    );
    expect(_stateMatches(_baseState(tester), paired.reception), isTrue);
    expect(find.textContaining('2/6'), findsOneWidget);
  });

  testWidgets(
      'live reading advances only in foreground and cancels on mode change',
      (tester) async {
    await tester.pumpWidget(_decisionApp(
      observationDuration: Duration.zero,
      assessmentDuration: Duration.zero,
    ));
    await tester.pump();
    final l10n = AppLocalizations.of(
        tester.element(find.byType(DecisionTrainingScreen)))!;

    await tester.tap(find.text(l10n.scanPassDecisionModeLive));
    await tester.pump();
    await _pumpLive(tester, const Duration(milliseconds: 240));
    final moving = _displayState(tester);
    expect(moving.elapsed, greaterThan(0));

    await tester.tap(find.byKey(const ValueKey<String>('decision-help')));
    await tester.pumpAndSettle();
    final beforeHelp = _displayState(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(_displayState(tester).elapsed, beforeHelp.elapsed);
    await tester.tap(find.text(l10n.scanPassHelpCloseAction));
    await tester.pump(const Duration(milliseconds: 500));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    final beforeBackground = _displayState(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(_displayState(tester).elapsed, beforeBackground.elapsed);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    await tester.tap(find.text(l10n.scanPassDecisionModeSolo));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(find.byKey(const ValueKey<String>('decision-window-closed')),
        findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('live window closes without auto-executing a selected choice',
      (tester) async {
    const engine = DecisionEngine();
    final scenario = engine.scenario(DecisionLesson.rearPressure);

    await tester.pumpWidget(_decisionApp(
      observationDuration: Duration.zero,
      assessmentDuration: Duration.zero,
    ));
    await tester.pump();
    final l10n = AppLocalizations.of(
        tester.element(find.byType(DecisionTrainingScreen)))!;
    await tester.tap(find.text(l10n.scanPassDecisionModeLive));
    await tester.pump();
    await tester
        .tap(find.byKey(const ValueKey<String>('decision-action-reset')));
    await _pumpLive(
      tester,
      scenario.liveWindowSeconds.seconds + const Duration(milliseconds: 400),
    );

    expect(find.byKey(const ValueKey<String>('decision-window-closed')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('decision-review-result')),
        findsNothing);
  });

  testWidgets('reduced motion jumps observation and outcome to stable states',
      (tester) async {
    await tester.pumpWidget(_decisionApp(
      observationDuration: const Duration(seconds: 3),
      assessmentDuration: const Duration(seconds: 3),
      disableAnimations: true,
    ));
    await tester.pump();

    expect(find.text('Choose the next action after the reception.'),
        findsOneWidget);
    await _chooseAndCommit(tester, 'decision-action-carry');
    expect(find.byKey(const ValueKey<String>('decision-review-result')),
        findsOneWidget);
  });

  for (final config in [
    (size: const Size(320, 568), scale: 1.0, locale: const Locale('ko')),
    (size: const Size(390, 844), scale: 1.3, locale: const Locale('en')),
    (size: const Size(568, 320), scale: 1.0, locale: const Locale('ja')),
    (size: const Size(1280, 800), scale: 1.0, locale: const Locale('en')),
  ]) {
    testWidgets(
      'decision controls fit ${config.size} ${config.locale.languageCode}',
      (tester) async {
        tester.view.physicalSize = config.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_decisionApp(
          locale: config.locale,
          textScale: config.scale,
          observationDuration: Duration.zero,
          assessmentDuration: Duration.zero,
        ));
        await tester.pump();

        final pitch = find.byKey(const ValueKey<String>('decision-pitch'));
        expect(pitch, findsOneWidget);
        expect(tester.getRect(pitch).height,
            greaterThan(config.size.height < 430 ? 110 : 210));

        for (final key in [
          'decision-dock-forward',
          'decision-dock-wide',
          'decision-dock-reset',
          'decision-dock-carry',
          'decision-replay-observation',
          'decision-commit',
        ]) {
          final finder = find.byKey(ValueKey<String>(key));
          await tester.ensureVisible(finder);
          final rect = tester.getRect(finder);
          expect(rect.width, greaterThanOrEqualTo(44), reason: key);
          expect(rect.height, greaterThanOrEqualTo(44), reason: key);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('action buttons expose screen-reader labels', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_decisionApp(
        observationDuration: Duration.zero,
        assessmentDuration: Duration.zero,
      ));
      await tester.pump();

      final forward = find.bySemanticsLabel('Forward pass to #8');
      final carry = find.bySemanticsLabel('Carry forward into space');
      expect(forward, findsWidgets);
      expect(carry, findsWidgets);
      expect(_hasTapSemantics(tester, forward), isTrue);
      expect(_hasTapSemantics(tester, carry), isTrue);
    } finally {
      semantics.dispose();
    }
  });
}

Future<void> _pumpLive(WidgetTester tester, Duration duration) async {
  var elapsed = Duration.zero;
  const step = Duration(milliseconds: 80);
  while (elapsed < duration) {
    final remaining = duration - elapsed;
    final slice = remaining < step ? remaining : step;
    await tester.pump(slice);
    elapsed += slice;
  }
}

Future<void> _chooseAndCommit(WidgetTester tester, String actionKey) async {
  await tester.tap(find.byKey(ValueKey<String>(actionKey)));
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey<String>('decision-commit')));
  await tester.pump();
}

dynamic _decisionPainter(WidgetTester tester) => tester
    .widget<CustomPaint>(find.byKey(const ValueKey<String>('decision-pitch')))
    .painter;

AttackState _baseState(WidgetTester tester) =>
    _decisionPainter(tester).baseState as AttackState;

AttackState _displayState(WidgetTester tester) =>
    _decisionPainter(tester).displayState as AttackState;

bool _hasTapSemantics(WidgetTester tester, Finder finder) {
  final matches = finder.evaluate().length;
  for (var i = 0; i < matches; i += 1) {
    if (tester
        .getSemantics(finder.at(i))
        .getSemanticsData()
        .hasAction(SemanticsAction.tap)) {
      return true;
    }
  }
  return false;
}

bool _stateMatches(AttackState actual, AttackState expected) {
  if (actual.ball.distanceTo(expected.ball) > 1e-8) return false;
  if (actual.carrierNumber != expected.carrierNumber) return false;
  bool listMatches(List<AttackPlayer> a, List<AttackPlayer> b) {
    if (a.length != b.length) return false;
    for (final player in a) {
      final other = b.firstWhere((item) => item.number == player.number);
      if (player.position.distanceTo(other.position) > 1e-8) return false;
    }
    return true;
  }

  return listMatches(actual.attackers, expected.attackers) &&
      listMatches(actual.defenders, expected.defenders);
}

String _qualityLabel(AppLocalizations l10n, DecisionQuality quality) {
  return switch (quality) {
    DecisionQuality.advantage => l10n.scanPassDecisionQualityAdvantage,
    DecisionQuality.secure => l10n.scanPassDecisionQualitySecure,
    DecisionQuality.difficult => l10n.scanPassDecisionQualityDifficult,
    DecisionQuality.lost => l10n.scanPassDecisionQualityLost,
  };
}

String _reasonLabel(AppLocalizations l10n, DecisionReason reason) {
  return switch (reason) {
    DecisionReason.pressureEscaped =>
      l10n.scanPassDecisionReasonPressureEscaped,
    DecisionReason.pressureArriving =>
      l10n.scanPassDecisionReasonPressureArriving,
    DecisionReason.laneOpen => l10n.scanPassDecisionReasonLaneOpen,
    DecisionReason.laneBlocked => l10n.scanPassDecisionReasonLaneBlocked,
    DecisionReason.receiverCanTurn =>
      l10n.scanPassDecisionReasonReceiverCanTurn,
    DecisionReason.receiverTrapped =>
      l10n.scanPassDecisionReasonReceiverTrapped,
    DecisionReason.thirdPlayerAvailable =>
      l10n.scanPassDecisionReasonThirdPlayerAvailable,
    DecisionReason.possessionKept => l10n.scanPassDecisionReasonPossessionKept,
    DecisionReason.windowClosed => l10n.scanPassDecisionReasonWindowClosed,
    DecisionReason.offside => l10n.scanPassDecisionReasonOffside,
  };
}

Widget _decisionApp({
  int seed = 0,
  Locale locale = const Locale('en'),
  double textScale = 1,
  Duration observationDuration = Duration.zero,
  Duration assessmentDuration = Duration.zero,
  bool disableAnimations = false,
}) {
  return _app(
    locale: locale,
    textScale: textScale,
    disableAnimations: disableAnimations,
    home: DecisionTrainingScreen(
      optionRepository: _Options(),
      seed: seed,
      observationDuration: observationDuration,
      assessmentDuration: assessmentDuration,
    ),
  );
}

Widget _app({
  required Widget home,
  Locale locale = const Locale('en'),
  double textScale = 1,
  bool disableAnimations = false,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: disableAnimations,
      ),
      child: child!,
    ),
    home: home,
  );
}

class _Options implements OptionRepository {
  @override
  T? getValue<T>(String key) => null;

  @override
  List<String> getOptions(String key, List<String> defaults) => defaults;

  @override
  List<int> getIntOptions(String key, List<int> defaults) => defaults;

  @override
  Future<void> setValue(String key, dynamic value) async {}

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {}
}

extension on double {
  Duration get seconds => Duration(milliseconds: (this * 1000).round());
}
