import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/scan_pass/scan_pass_attack.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart'
    show ScanPassPoint;
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/scan_pass_game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'an actual possession reaches goal and replay preserves every step',
      (tester) async {
    await tester.pumpWidget(_app());
    await _tap(tester, 'attack-start');
    final received = _base(tester);
    final pitchBounds =
        tester.getRect(find.byKey(const ValueKey('attack-pitch')));
    expect(received.carrierNumber, 6);
    await _tap(tester, 'attack-pass-9');
    expect(identical(_base(tester), received), isTrue);
    expect(
        tester.getRect(find.byKey(const ValueKey('attack-pitch'))), pitchBounds,
        reason:
            'Choosing a route must not move or resize the playing surface.');
    await _tap(tester, 'attack-execute');
    final readyToShoot = _base(tester);
    expect(
        tester.getRect(find.byKey(const ValueKey('attack-pitch'))), pitchBounds,
        reason: 'Receiving a pass must preserve the learner’s spatial frame.');
    expect(readyToShoot.carrierNumber, 9);
    expect(readyToShoot.completedPasses, 2);
    await _tap(tester, 'attack-shoot-upper');
    await _tap(tester, 'attack-execute');
    final ended = _base(tester);
    expect(ended.end, AttackEnd.goal);
    expect(ended.actionCount, 3);

    await tester.tap(find.byKey(const ValueKey('attack-replay')));
    await tester.pump();
    expect(find.byKey(const ValueKey('attack-execute')), findsNothing);
    expect(identical(_base(tester), ended), isTrue);
    await tester.pumpAndSettle();
    expect(identical(_base(tester), ended), isTrue);
    expect((_painter(tester).history as List).length, 3);

    await _tap(tester, 'attack-undo');
    expect(identical(_base(tester), readyToShoot), isTrue);
    expect((_painter(tester).history as List).length, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'an offside-position receiver does not freeze an intercepted pass',
      (tester) async {
    final state = _interceptedOffsidePass();
    final transition =
        const AttackEngine().play(state, const AttackAction.pass(9));
    expect(transition.offside!.offside, isTrue);
    expect(transition.after.end, AttackEnd.intercepted);
    await tester
        .pumpWidget(_app(initial: state, duration: const Duration(seconds: 2)));
    await _tap(tester, 'attack-pass-9');
    await tester.tap(find.byKey(const ValueKey('attack-execute')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));
    final shown = _painter(tester).displayState as AttackState;
    expect(shown.ball.x, greaterThan(state.ball.x),
        reason:
            'Show the interception flight; an offside position alone is not a whistle.');
    await tester.pumpAndSettle();
    expect(_base(tester).end, AttackEnd.intercepted);
  });

  testWidgets(
      'offside review retains the kick moment and undo restores the choice',
      (tester) async {
    await tester.pumpWidget(_app(duration: Duration.zero));
    await _tap(tester, 'attack-start');
    await _tap(tester, 'attack-hold');
    await _tap(tester, 'attack-execute');
    final atKick = _base(tester);
    await _tap(tester, 'attack-pass-9');
    await tester.pump(const Duration(seconds: 40));
    expect(identical(_base(tester), atKick), isTrue);
    await _tap(tester, 'attack-execute');
    expect(_base(tester).end, AttackEnd.offside);
    expect(_base(tester).ball.distanceTo(atKick.ball), 0);
    final last = (_painter(tester).history as List).last as AttackTransition;
    expect(identical(last.offside!.atKick, atKick), isTrue);
    await _tap(tester, 'attack-replay');
    expect((_painter(tester).history as List).length, 3,
        reason:
            'Zero-duration replay must neither duplicate nor skip stored decisions.');
    await _tap(tester, 'attack-undo');
    expect(identical(_base(tester), atKick), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('help remains paused after a background and foreground cycle',
      (tester) async {
    await tester.pumpWidget(_app(duration: const Duration(seconds: 2)));
    await tester.tap(find.byKey(const ValueKey('attack-start')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final beforeHelp = (_painter(tester).displayState as AttackState).ball;
    await tester.tap(find.byKey(const ValueKey('attack-help')));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 30));
    final painter = tester
        .widget<CustomPaint>(
            find.byKey(const ValueKey('attack-pitch'), skipOffstage: false))
        .painter as dynamic;
    expect((painter.displayState as AttackState).ball.distanceTo(beforeHelp),
        lessThan(1e-8));
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(_base(tester).carrierNumber, 6);
    expect(tester.takeException(), isNull);
  });
}

dynamic _painter(WidgetTester tester) => tester
    .widget<CustomPaint>(find.byKey(const ValueKey('attack-pitch')))
    .painter;
AttackState _base(WidgetTester tester) =>
    _painter(tester).baseState as AttackState;

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Widget _app(
        {AttackState? initial,
        Duration duration = const Duration(milliseconds: 300)}) =>
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ScanPassGameScreen(
        optionRepository: _Options(),
        seed: 7,
        previewDuration: duration,
        passAnimationDuration: duration,
        initialAttack: initial,
      ),
    );

AttackState _interceptedOffsidePass() => AttackState(
      attackers: const [
        AttackPlayer(number: 4, position: ScanPassPoint(.40, .70)),
        AttackPlayer(number: 6, position: ScanPassPoint(.66, .50)),
        AttackPlayer(number: 8, position: ScanPassPoint(.45, .15)),
        AttackPlayer(number: 9, position: ScanPassPoint(.86, .50)),
      ],
      defenders: const [
        AttackPlayer(
            number: 2, opponent: true, position: ScanPassPoint(.73, .50)),
        AttackPlayer(
            number: 3, opponent: true, position: ScanPassPoint(.65, .80)),
        AttackPlayer(
            number: 5, opponent: true, position: ScanPassPoint(.75, .80)),
        AttackPlayer(
            number: 1,
            opponent: true,
            goalkeeper: true,
            position: ScanPassPoint(.955, .50)),
      ],
      ball: const ScanPassPoint(.66, .50),
      carrierNumber: 6,
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
