import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/scan_pass_history_service.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/scan_pass/scan_pass_match_moment.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/scan_pass_game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets('public Scan Pass opens the Yamal real-match episode by default',
      (tester) async {
    await tester.pumpWidget(_app(home: _publicEntry()));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey<String>('match-moment-pitch')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('flow-pitch')), findsNothing);
    expect(find.byKey(const ValueKey('practice-catalog')), findsNothing);
    expect(find.byKey(const ValueKey<String>('attack-start')), findsNothing);
    expect(find.textContaining('Spain v England'), findsOneWidget);
    expect(find.textContaining("Yamal 19"), findsOneWidget);
  });

  testWidgets('three on-pitch decisions reach the historical goal review',
      (tester) async {
    await tester.pumpWidget(_app(home: _matchScreen()));
    await _settleOpening(tester);

    await _tapChoice(tester, 'match-choice-receive-inside');
    expect(find.byKey(const ValueKey<String>('match-choice-touch-inside')),
        findsOneWidget);
    await _tapChoice(tester, 'match-choice-touch-inside');
    expect(find.byKey(const ValueKey<String>('match-choice-pass-williams')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('match-choice-pass-morata')),
        findsOneWidget);

    await _tapChoice(tester, 'match-choice-pass-williams');

    final l10n = _l10n(tester);
    expect(find.text(l10n.matchMomentReviewTitle), findsOneWidget);
    expect(find.text(l10n.matchMomentReviewEffectGoal), findsOneWidget);
    expect(
        find.byKey(const ValueKey<String>('match-retry-last')), findsOneWidget);
    expect(
        find.byKey(const ValueKey<String>('match-reference')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('match-open-uefa-goal')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('risky branch turns over and retry restores the last decision',
      (tester) async {
    await tester.pumpWidget(_app(home: _matchScreen()));
    await _settleOpening(tester);

    await _tapChoice(tester, 'match-choice-receive-wide');
    await _tapChoice(tester, 'match-choice-touch-line');
    await _tapChoice(tester, 'match-choice-carry-inside');

    final l10n = _l10n(tester);
    expect(find.text(l10n.matchMomentReviewEffectTurnover), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('match-retry-last')));
    await tester.pump();

    expect(find.byKey(const ValueKey<String>('match-choice-pass-williams')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('match-choice-receive-inside')),
        findsNothing);

    await _tapChoice(tester, 'match-choice-pass-morata');
    expect(find.text(l10n.matchMomentReviewEffectRetained), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reference comparison preserves learner review and can return',
      (tester) async {
    await tester.pumpWidget(_app(home: _matchScreen()));
    await _settleOpening(tester);
    await _tapChoice(tester, 'match-choice-receive-wide');
    await _tapChoice(tester, 'match-choice-touch-line');
    await _tapChoice(tester, 'match-choice-carry-inside');

    await tester.tap(find.byKey(const ValueKey<String>('match-reference')));
    await tester.pump();
    final l10n = _l10n(tester);
    expect(find.text(l10n.matchMomentReferenceTitle), findsOneWidget);
    expect(find.text(l10n.matchMomentReferenceBody), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('match-return-review')));
    await tester.pump();
    expect(find.text(l10n.matchMomentReviewTitle), findsOneWidget);
    expect(find.text(l10n.matchMomentReviewEffectTurnover), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('official source buttons use injected launcher', (tester) async {
    final opened = <Uri>[];
    await tester.pumpWidget(_app(
      home: _matchScreen(sourceLauncher: (uri) async {
        opened.add(uri);
        return true;
      }),
    ));
    await _settleOpening(tester);
    await _completeHistorical(tester);

    await tester.ensureVisible(
        find.byKey(const ValueKey<String>('match-open-uefa-goal')));
    await tester
        .tap(find.byKey(const ValueKey<String>('match-open-uefa-goal')));
    await tester.pump();
    await tester.ensureVisible(
        find.byKey(const ValueKey<String>('match-open-england-highlight')));
    await tester.tap(
        find.byKey(const ValueKey<String>('match-open-england-highlight')));
    await tester.pump();

    expect(opened.any((uri) => uri.host.contains('uefa.com')), isTrue);
    expect(
      opened.map((uri) => uri.toString()),
      contains('https://www.youtube.com/watch?v=lBOS43RWfY0&t=110s'),
    );
  });

  testWidgets('opening sources during the lead-in resumes after closing',
      (tester) async {
    await tester.pumpWidget(_app(
      home: const ScanPassMatchMomentScreen(
        leadInDuration: Duration(seconds: 2),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const ValueKey<String>('match-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('match-sources')));
    await tester.pumpAndSettle();
    final close = find.text(_l10n(tester).close);
    await tester.ensureVisible(close);
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('match-choice-receive-inside')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final config in [
    (size: const Size(390, 844), scale: 1.25, locale: const Locale('en')),
    (size: const Size(844, 390), scale: 1.0, locale: const Locale('ko')),
    (size: const Size(1280, 800), scale: 1.0, locale: const Locale('ja')),
  ]) {
    testWidgets('Yamal stays on the attacking right flank ${config.size}',
        (tester) async {
      tester.view.physicalSize = config.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(home: _matchScreen()));
      await _settleOpening(tester);
      final field = find.byKey(const ValueKey<String>('match-moment-pitch'));
      final dynamic painter = tester.widget<CustomPaint>(field).painter;
      final size = tester.getSize(field);
      final frame = const MatchMomentEpisode().decisionStart;
      final Offset yamal = painter.offsetFor(
          frame.actor(MatchMomentEpisode.spain19).position, size);
      final Offset williams = painter.offsetFor(
          frame.actor(MatchMomentEpisode.spain17).position, size);
      if (config.size.width < config.size.height) {
        // Attacking upward: Spain's right winger belongs on screen right.
        expect(yamal.dx, greaterThan(williams.dx));
      } else {
        // Attacking rightward: Spain's right winger belongs below the left one.
        expect(yamal.dy, greaterThan(williams.dy));
      }
    });

    testWidgets('layout fits ${config.size} ${config.locale.languageCode}',
        (tester) async {
      tester.view.physicalSize = config.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_app(
        locale: config.locale,
        textScale: config.scale,
        home: _matchScreen(),
      ));
      await _settleOpening(tester);

      expect(
          find
              .byKey(const ValueKey<String>('match-choice-receive-inside'))
              .hitTestable(),
          findsOneWidget);
      expect(
          find
              .byKey(const ValueKey<String>('match-choice-receive-wide'))
              .hitTestable(),
          findsOneWidget);
      expect(
          find
              .byKey(const ValueKey<String>('match-choice-receive-check'))
              .hitTestable(),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

Widget _publicEntry() => ScanPassGameScreen(
      optionRepository: _Options(),
      previewDuration: Duration.zero,
      passAnimationDuration: Duration.zero,
    );

Widget _matchScreen({MatchMomentSourceLauncher? sourceLauncher}) =>
    ScanPassMatchMomentScreen(
      leadInDuration: Duration.zero,
      actionDuration: Duration.zero,
      sourceLauncher: sourceLauncher,
    );

Widget _app({
  required Widget home,
  Locale locale = const Locale('en'),
  double textScale = 1,
}) =>
    MaterialApp(
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

Future<void> _settleOpening(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

Future<void> _tapChoice(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey<String>(key));
  expect(finder.hitTestable(), findsOneWidget, reason: key);
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _completeHistorical(WidgetTester tester) async {
  await _tapChoice(tester, 'match-choice-receive-inside');
  await _tapChoice(tester, 'match-choice-touch-inside');
  await _tapChoice(tester, 'match-choice-pass-williams');
}

AppLocalizations _l10n(WidgetTester tester) => AppLocalizations.of(
    tester.element(find.byType(ScanPassMatchMomentScreen)))!;

class _Options implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    if (value is List) {
      return value.map((item) => int.tryParse(item.toString()) ?? 0).toList();
    }
    _values[key] = List<int>.from(defaults);
    return List<int>.from(defaults);
  }

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    _values[key] = List<String>.from(defaults);
    return List<String>.from(defaults);
  }

  @override
  T? getValue<T>(String key) {
    final value = _values[key];
    if (value is T) return value;
    return null;
  }

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    _values[key] = List<dynamic>.from(options);
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    _values[key] = value;
    if (key == ScanPassHistoryService.summaryKey) return;
  }
}
