import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_attack.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/scan_pass_game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('watches the situation before one-tap choices appear',
      (tester) async {
    await tester.pumpWidget(_app(
      home: const JudgmentEpisodeTrainingScreen(
        seed: 0,
        observationDuration: Duration(milliseconds: 500),
        executionDuration: Duration.zero,
      ),
    ));
    await tester.pump();

    expect(
        find.byKey(const ValueKey<String>('judgment-pitch')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('judgment-action-touchLeft')),
        findsNothing);
    expect(find.byKey(const ValueKey<String>('judgment-replay-observation')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('judgment-coach-detail')),
        findsNothing);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('judgment-action-touchLeft')),
        findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey<String>('judgment-replay-observation')));
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('judgment-action-touchLeft')),
        findsNothing);
  });

  testWidgets('one tap executes without mode selection or confirmation',
      (tester) async {
    await tester.pumpWidget(_app(
      home: const JudgmentEpisodeTrainingScreen(
        seed: 0,
        observationDuration: Duration.zero,
        executionDuration: Duration.zero,
      ),
    ));
    await tester.pump();

    expect(find.byKey(const ValueKey<String>('decision-commit')), findsNothing);
    expect(find.byKey(const ValueKey<String>('chain-commit')), findsNothing);
    expect(find.byKey(const ValueKey<String>('judgment-action-oneTouchReturn')),
        findsOneWidget);

    await tester.tap(
        find.byKey(const ValueKey<String>('judgment-action-oneTouchReturn')));
    await tester.pump();

    expect(_displayState(tester).carrierNumber, 4);
    expect(find.byKey(const ValueKey<String>('judgment-dock-supportInside')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('chain-commit')), findsNothing);
    await _finishScene(tester);
    expect(find.byKey(const ValueKey<String>('judgment-next')), findsOneWidget);
  });

  testWidgets('first touch changes the next available state', (tester) async {
    await tester.pumpWidget(_app(
      home: const JudgmentEpisodeTrainingScreen(
        seed: 0,
        observationDuration: Duration.zero,
        executionDuration: Duration.zero,
      ),
    ));
    await tester.pump();

    final before = _displayState(tester);
    await tester
        .tap(find.byKey(const ValueKey<String>('judgment-action-touchLeft')));
    await tester.pump();

    expect(find.byKey(const ValueKey<String>('judgment-dock-passWide')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('judgment-review-result')),
        findsNothing);
    final afterTouch = _displayState(tester);
    expect(afterTouch.ball.distanceTo(before.ball), greaterThan(.04));

    await tester
        .tap(find.byKey(const ValueKey<String>('judgment-dock-passWide')));
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('judgment-review-result')),
        findsOneWidget);
  });

  testWidgets('alternative replay uses the identical decision snapshot',
      (tester) async {
    await tester.pumpWidget(_app(
      home: const JudgmentEpisodeTrainingScreen(
        seed: 0,
        observationDuration: Duration.zero,
        executionDuration: Duration.zero,
      ),
    ));
    await tester.pump();

    await tester.tap(
        find.byKey(const ValueKey<String>('judgment-action-oneTouchReturn')));
    await tester.pump();
    await _finishScene(tester);
    await tester.tap(find.byKey(const ValueKey('judgment-moment-0')));
    await tester.pump();
    final ownBefore = _baseState(tester);

    await tester
        .tap(find.byKey(const ValueKey<String>('judgment-view-alternative')));
    await tester.pump();
    final alternativeBefore = _baseState(tester);

    expect(_stateMatches(alternativeBefore, ownBefore), isTrue);
    expect(
      (_judgmentPainter(tester).decisionBranchLabel as String)
          .startsWith('Other choice'),
      isTrue,
    );
  });

  testWidgets('review opens coach detail and cue-pair practice after choice',
      (tester) async {
    await tester.pumpWidget(_app(
      home: const JudgmentEpisodeTrainingScreen(
        seed: 0,
        observationDuration: Duration.zero,
        executionDuration: Duration.zero,
      ),
    ));
    await tester.pump();

    expect(_judgmentPainter(tester).focusFrame, isNotNull);
    await tester.tap(find.byKey(const ValueKey('judgment-overview-toggle')));
    await tester.pump();
    expect(_judgmentPainter(tester).focusFrame, isNull);
    expect(find.byKey(const ValueKey<String>('judgment-coach-detail')),
        findsNothing);

    await _finishScene(tester);
    expect(find.byKey(const ValueKey<String>('judgment-coach-detail')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('judgment-cue-pair')),
        findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey<String>('judgment-coach-detail')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('judgment-coach-detail-sheet')),
        findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('judgment-cue-pair')));
    await tester.pump();
    await tester.pump();
    expect(
        find.byKey(const ValueKey<String>('judgment-pitch')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('judgment-summary-title')),
        findsNothing);
  });

  testWidgets(
      'replaying the lead-in preserves the current next-action decision',
      (tester) async {
    await tester.pumpWidget(_app(
        home: const JudgmentEpisodeTrainingScreen(
            seed: 0,
            observationDuration: Duration.zero,
            executionDuration: Duration.zero)));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('judgment-dock-touchLeft')));
    await tester.pump();
    final current = _displayState(tester);
    await tester.tap(find.byKey(const ValueKey('judgment-replay-observation')));
    await tester.pump();
    expect(_stateMatches(_displayState(tester), current), isTrue);
    expect(find.byKey(const ValueKey('judgment-dock-passForward')),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('judgment-dock-passForward')));
    await tester.pump();
    await _finishScene(tester);
    await tester.tap(find.byKey(const ValueKey('judgment-moment-0')));
    await tester.pump();
    expect((_judgmentPainter(tester).history as List).length, 1);
    expect(_baseState(tester).carrierNumber, 6);
    await tester.tap(find.byKey(const ValueKey('judgment-view-alternative')));
    await tester.pump();
    expect(_baseState(tester).carrierNumber, 6);
  });

  testWidgets(
      'retries count once and errors preserve all eight scenario families',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(
        home: const JudgmentEpisodeTrainingScreen(
            seed: 0,
            observationDuration: Duration.zero,
            executionDuration: Duration.zero)));
    await tester.pump();
    for (var attempt = 0; attempt < 2; attempt++) {
      await tester
          .tap(find.byKey(const ValueKey('judgment-dock-touchForward')));
      await tester.pump();
      if (attempt == 0) {
        await tester.tap(find.byKey(const ValueKey('judgment-retry')));
        await tester.pump();
        await tester.pump();
      }
    }
    final families = <String>{};
    for (var index = 0; index < 10; index++) {
      await tester.pump();
      if (index < 8) {
        final labels = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? '')
            .where((t) => t.startsWith('${index + 1}/10 · '));
        expect(labels, hasLength(1));
        families.add(labels.single.split(' · ').last);
      }
      await _finishScene(tester);
      await tester.tap(find.byKey(const ValueKey('judgment-next')));
      await tester.pump();
    }
    expect(families, hasLength(8));
    expect(find.text('10/10 situations completed.'), findsOneWidget);
    expect(find.text('11/10 situations completed.'), findsNothing);
  });

  testWidgets('completes ten scenes and starts a fresh session',
      (tester) async {
    await tester.pumpWidget(_app(
      home: const JudgmentEpisodeTrainingScreen(
        seed: 2,
        observationDuration: Duration.zero,
        executionDuration: Duration.zero,
      ),
    ));
    await tester.pump();

    for (var scene = 0; scene < 10; scene += 1) {
      await _finishScene(tester);
      await tester.tap(find.byKey(const ValueKey<String>('judgment-next')));
      await tester.pump();
    }

    expect(find.byKey(const ValueKey<String>('judgment-summary-title')),
        findsOneWidget);
    await tester
        .tap(find.byKey(const ValueKey<String>('judgment-fresh-session')));
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('judgment-summary-title')),
        findsNothing);
    expect(
        find.byKey(const ValueKey<String>('judgment-pitch')), findsOneWidget);
  });

  for (final config in [
    (size: const Size(320, 568), scale: 1.0, locale: const Locale('ko')),
    (size: const Size(390, 844), scale: 1.3, locale: const Locale('en')),
    (size: const Size(568, 320), scale: 1.0, locale: const Locale('ja')),
    (size: const Size(1280, 800), scale: 1.0, locale: const Locale('en')),
  ]) {
    testWidgets('judgment controls fit ${config.size}', (tester) async {
      tester.view.physicalSize = config.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_app(
        locale: config.locale,
        textScale: config.scale,
        home: const JudgmentEpisodeTrainingScreen(
          seed: 0,
          observationDuration: Duration.zero,
          executionDuration: Duration.zero,
        ),
      ));
      await tester.pump();

      final pitch = find.byKey(const ValueKey<String>('judgment-pitch'));
      expect(pitch, findsOneWidget);
      final pitchHeight = tester.getRect(pitch).height;
      final minimumPitch = config.size.height < 430
          ? 105.0
          : config.size.width < 360
              ? 220.0
              : config.size.width < 700
                  ? 450.0
                  : 460.0;
      expect(pitchHeight, greaterThan(minimumPitch));
      for (final key in [
        'judgment-dock-touchLeft',
        'judgment-dock-touchForward',
        'judgment-replay-observation',
      ]) {
        final finder = find.byKey(ValueKey<String>(key));
        await tester.ensureVisible(finder);
        final rect = tester.getRect(finder);
        expect(rect.width, greaterThanOrEqualTo(44), reason: key);
        expect(rect.height, greaterThanOrEqualTo(44), reason: key);
      }
      final targets = find.byWidgetPredicate((w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('judgment-action-'));
      final rects = targets
          .evaluate()
          .map((e) => tester.getRect(find.byWidget(e.widget)))
          .toList();
      for (var i = 0; i < rects.length; i++) {
        expect(rects[i].width, greaterThanOrEqualTo(44));
        for (var j = i + 1; j < rects.length; j++) {
          expect(rects[i].overlaps(rects[j]), isFalse,
              reason: 'Distinct touch targets');
        }
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('action buttons expose distinct screen-reader labels',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_app(
        home: const JudgmentEpisodeTrainingScreen(
          seed: 0,
          observationDuration: Duration.zero,
          executionDuration: Duration.zero,
        ),
      ));
      await tester.pump();

      final touchLeft =
          find.bySemanticsLabel('Take the first touch to your left');
      final oneTouch = find.bySemanticsLabel('Play a one-touch return pass');
      expect(touchLeft, findsWidgets);
      expect(oneTouch, findsWidgets);
      expect(_hasTapSemantics(tester, touchLeft), isTrue);
      expect(_hasTapSemantics(tester, oneTouch), isTrue);
    } finally {
      semantics.dispose();
    }
  });
}

Future<void> _finishScene(WidgetTester tester) async {
  for (var step = 0; step < 5; step += 1) {
    if (find
        .byKey(const ValueKey<String>('judgment-next'))
        .evaluate()
        .isNotEmpty) {
      return;
    }
    final key = _firstVisibleAction(tester);
    if (key == null) {
      await tester.pump();
      continue;
    }
    await tester.tap(find.byKey(ValueKey<String>(key)));
    await tester.pump();
  }
  fail('Scene did not reach review');
}

String? _firstVisibleAction(WidgetTester tester) {
  const keys = [
    'judgment-dock-oneTouchReturn',
    'judgment-dock-touchLeft',
    'judgment-dock-touchRight',
    'judgment-dock-touchForward',
    'judgment-dock-shield',
    'judgment-dock-passForward',
    'judgment-dock-passWide',
    'judgment-dock-passBack',
    'judgment-dock-carryForward',
    'judgment-dock-protect',
    'judgment-dock-supportInside',
    'judgment-dock-supportWide',
    'judgment-dock-supportBehind',
  ];
  for (final key in keys) {
    if (find.byKey(ValueKey<String>(key)).evaluate().isNotEmpty) return key;
  }
  return null;
}

dynamic _judgmentPainter(WidgetTester tester) => tester
    .widget<CustomPaint>(find.byKey(const ValueKey<String>('judgment-pitch')))
    .painter;

AttackState _baseState(WidgetTester tester) =>
    _judgmentPainter(tester).baseState as AttackState;

AttackState _displayState(WidgetTester tester) =>
    _judgmentPainter(tester).displayState as AttackState;

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
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: home,
  );
}
