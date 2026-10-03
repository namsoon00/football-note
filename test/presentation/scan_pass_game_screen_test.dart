import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/scan_pass_history_service.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/scan_pass/scan_pass_attack.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart'
    show ScanPassPoint;
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/scan_pass_game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MemoryOptionRepository optionRepository;

  setUp(() {
    optionRepository = _MemoryOptionRepository();
  });

  Widget buildScreen({
    int seed = 7,
    Locale locale = const Locale('en'),
    ThemeMode themeMode = ThemeMode.dark,
    Duration previewDuration = Duration.zero,
    Duration passAnimationDuration = Duration.zero,
    AttackState? initialAttack,
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: themeMode,
      home: ScanPassGameScreen(
        optionRepository: optionRepository,
        seed: seed,
        previewDuration: previewDuration,
        passAnimationDuration: passAnimationDuration,
        initialAttack: initialAttack,
      ),
    );
  }

  Future<void> tapByKey(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey<String>(key));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('opens on a spacious self-paced attack intro without scores',
      (tester) async {
    await tester.pumpWidget(buildScreen());

    expect(find.byKey(const ValueKey<String>('attack-pitch')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('attack-start')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('attack-scan')), findsOneWidget);
    expect(find.textContaining('/100'), findsNothing);
    expect(find.text('Score breakdown'), findsNothing);

    await tester.pump(const Duration(seconds: 30));

    expect(find.byKey(const ValueKey<String>('attack-start')), findsOneWidget);
    expect(optionRepository.summaryWriteCount, 0);
  });

  testWidgets('preview does not commit; execute keeps possession continuous',
      (tester) async {
    await tester.pumpWidget(buildScreen());

    await tapByKey(tester, 'attack-start');
    expect(find.byKey(const ValueKey<String>('attack-pass-4')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('attack-start')), findsNothing);

    await tapByKey(tester, 'attack-pass-4');
    expect(
        find.byKey(const ValueKey<String>('attack-execute')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('attack-review')), findsNothing);

    await tester.pump(const Duration(seconds: 30));
    expect(
        find.byKey(const ValueKey<String>('attack-execute')), findsOneWidget);

    await tapByKey(tester, 'attack-change');
    expect(find.byKey(const ValueKey<String>('attack-execute')), findsNothing);
    expect(find.byKey(const ValueKey<String>('attack-pass-4')), findsOneWidget);

    await tapByKey(tester, 'attack-pass-4');
    await tapByKey(tester, 'attack-execute');

    expect(find.byKey(const ValueKey<String>('attack-pass-6')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('attack-review')), findsNothing);
    expect(optionRepository.summaryWriteCount, 0);
  });

  testWidgets('shooting range is explicit and terminal actions replay or undo',
      (tester) async {
    await tester.pumpWidget(buildScreen());
    await tapByKey(tester, 'attack-start');
    expect(find.byKey(const ValueKey<String>('attack-shoot-center')),
        findsNothing);

    await tester.pumpWidget(buildScreen(initialAttack: _shootingState()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('attack-shoot-center')),
        findsOneWidget);
    await tapByKey(tester, 'attack-shoot-center');
    expect(
        find.byKey(const ValueKey<String>('attack-execute')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('attack-replay')), findsNothing);

    await tapByKey(tester, 'attack-execute');

    expect(find.byKey(const ValueKey<String>('attack-replay')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('attack-undo')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('attack-new')), findsOneWidget);

    await tapByKey(tester, 'attack-replay');
    expect(find.byKey(const ValueKey<String>('attack-replay')), findsOneWidget);

    await tapByKey(tester, 'attack-undo');
    expect(find.byKey(const ValueKey<String>('attack-shoot-center')),
        findsOneWidget);
    expect(optionRepository.summaryWriteCount, 0);
  });

  testWidgets('help and scan overlay do not discard the current attack',
      (tester) async {
    await tester.pumpWidget(buildScreen());

    await tapByKey(tester, 'attack-start');
    await tapByKey(tester, 'attack-scan');
    expect(
      find.text('Arrows show the current direction of movement.'),
      findsOneWidget,
    );

    await tapByKey(tester, 'attack-help');
    expect(find.text('How Scan Pass works'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('attack-pass-4')), findsOneWidget);
    expect(optionRepository.summaryWriteCount, 0);
  });

  testWidgets('app lifecycle pauses opening pass animation', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildScreen(
        previewDuration: const Duration(seconds: 2),
        passAnimationDuration: const Duration(seconds: 2),
      ),
    );

    final start = find.byKey(const ValueKey<String>('attack-start'));
    await tester.tap(start);
    await tester.pump();

    expect(find.byKey(const ValueKey<String>('attack-pass-4')), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey<String>('attack-pass-4')), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('attack-pass-4')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

AttackState _shootingState() {
  final base = const AttackEngine().initial();
  const point = ScanPassPoint(.72, .50);
  return base.copyWith(
    attackers: [
      for (final player in base.attackers)
        if (player.number == base.carrierNumber)
          player.copyWith(position: point, facingRadians: 0)
        else
          player,
    ],
    ball: point,
    furthestX: point.x,
  );
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};
  int summaryWriteCount = 0;

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
    if (key == ScanPassHistoryService.summaryKey) {
      summaryWriteCount += 1;
    }
    _values[key] = value;
  }
}
