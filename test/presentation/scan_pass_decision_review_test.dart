import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/scan_pass/scan_pass_attack.dart';
import 'package:football_note/domain/scan_pass/scan_pass_decision.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/scan_pass_game_screen.dart';

void main() {
  testWidgets('changing a queued plan returns the new choice to preview',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DecisionTrainingScreen(
        optionRepository: _Options(),
        observationDuration: const Duration(seconds: 2),
        assessmentDuration: Duration.zero,
      ),
    ));
    await tester.pump();
    await _tap(tester, 'decision-action-forward', settle: false);
    await _tap(tester, 'decision-commit', settle: false);
    await _tap(tester, 'decision-action-wide', settle: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('decision-review-result')), findsNothing);
    expect((_painter(tester).displayState as AttackState).carrierNumber, 6);
    await _tap(tester, 'decision-commit');
    expect(
        find.byKey(const ValueKey('decision-review-result')), findsOneWidget);
  });

  testWidgets('comparison replays from the same release and preserves choice',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await _tap(tester, 'decision-action-carry');
    final before = _painter(tester).baseState as AttackState;
    await _tap(tester, 'decision-commit');
    final ownLabel = _painter(tester).decisionBranchLabel as String;
    await _tap(tester, 'decision-view-alternative', settle: false);
    expect(find.byKey(const ValueKey('decision-next')), findsNothing,
        reason: 'A comparison must play, not jump straight to its result.');
    final release = _painter(tester).displayState as AttackState;
    expect(release.ball.distanceTo(before.ball), lessThan(.00001));
    await tester.pump(const Duration(milliseconds: 400));
    final moving = _painter(tester).displayState as AttackState;
    expect(moving.ball.distanceTo(before.ball), greaterThan(.02));
    await tester.pumpAndSettle();
    expect(_painter(tester).decisionBranchLabel, isNot(ownLabel));
    await _tap(tester, 'decision-view-own', settle: false);
    await tester.pumpAndSettle();
    expect(_painter(tester).decisionBranchLabel, ownLabel);
    final l10n = AppLocalizations.of(
        tester.element(find.byType(DecisionTrainingScreen)))!;
    expect(find.text(l10n.scanPassDecisionQualityLost), findsOneWidget);
    await _tap(tester, 'decision-next');
    expect(find.textContaining('2/6'), findsOneWidget,
        reason: 'Comparisons must not create extra learner decisions.');
  });

  testWidgets('support review freezes the receiving moment with actual outlets',
      (tester) async {
    await tester.pumpWidget(_app(duration: Duration.zero));
    await tester.pumpAndSettle();
    for (var step = 0; step < 4; step++) {
      await _tap(tester, 'decision-action-forward');
      await _tap(tester, 'decision-commit');
      await _tap(tester, 'decision-next');
    }
    await _tap(tester, 'decision-action-forward');
    await _tap(tester, 'decision-commit');
    final shown = _painter(tester).displayState as AttackState;
    final expected = const DecisionEngine().assess(
        const DecisionEngine().scenario(DecisionLesson.receiverSupport),
        DecisionAction.forward);
    expect(shown.carrierNumber, 8,
        reason: 'The cause is pressure on the receiver, before the wall pass.');
    expect(shown.ball.distanceTo(expected.received.ball), lessThan(.00001));
    expect((_painter(tester).decisionOutletPoints as List).length, 1);
    final l10n = AppLocalizations.of(
        tester.element(find.byType(DecisionTrainingScreen)))!;
    expect(
        find.text(l10n.scanPassDecisionIndicatorOutlets('10')), findsOneWidget,
        reason:
            'The next outlet is the lesson, not a hidden fourth indicator.');
  });

  testWidgets('desktop commit and next buttons are visible without scrolling',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(duration: Duration.zero));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('decision-action-forward')));
    await tester.pump();
    expect(tester.getRect(find.byKey(const ValueKey('decision-commit'))).bottom,
        lessThanOrEqualTo(800));
    await tester.tap(find.byKey(const ValueKey('decision-commit')));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const ValueKey('decision-next'))).bottom,
        lessThanOrEqualTo(800));
  });

  for (final size in [const Size(390, 844), const Size(1280, 800)]) {
    testWidgets('review keeps a stable spatial frame at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(duration: Duration.zero));
      await tester.pumpAndSettle();
      final bounds =
          tester.getRect(find.byKey(const ValueKey('decision-pitch')));
      await _tap(tester, 'decision-action-forward');
      await _tap(tester, 'decision-commit');
      expect(
          tester.getRect(find.byKey(const ValueKey('decision-pitch'))), bounds);
      await _tap(tester, 'decision-view-alternative');
      expect(
          tester.getRect(find.byKey(const ValueKey('decision-pitch'))), bounds);
    });
  }

  testWidgets('opening free attack pauses live practice until returning',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ScanPassGameScreen(
        optionRepository: _Options(),
        previewDuration: Duration.zero,
        passAnimationDuration: Duration.zero,
      ),
    ));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
        tester.element(find.byType(DecisionTrainingScreen)))!;
    await tester.tap(find.text(l10n.scanPassDecisionModeLive));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final before = (_painter(tester).displayState as AttackState).elapsed;
    await tester.tap(find.byKey(const ValueKey('decision-free-attack')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    final hidden = tester
        .widget<CustomPaint>(
            find.byKey(const ValueKey('decision-pitch'), skipOffstage: false))
        .painter as dynamic;
    expect((hidden.displayState as AttackState).elapsed, before);
    Navigator.of(tester.element(find.byType(ScanPassFreeAttackScreen))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect((_painter(tester).displayState as AttackState).elapsed,
        greaterThan(before));
    await tester.pumpWidget(const SizedBox());
  });
}

dynamic _painter(WidgetTester tester) => tester
    .widget<CustomPaint>(find.byKey(const ValueKey('decision-pitch')))
    .painter;

Future<void> _tap(WidgetTester tester, String key, {bool settle = true}) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
  if (settle) await tester.pumpAndSettle();
}

Widget _app({Duration duration = const Duration(seconds: 3)}) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DecisionTrainingScreen(
        optionRepository: _Options(),
        seed: 0,
        observationDuration: Duration.zero,
        assessmentDuration: duration,
      ),
    );

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
