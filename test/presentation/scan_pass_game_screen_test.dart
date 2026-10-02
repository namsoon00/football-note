import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/scan_pass_history_service.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart';
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
    Duration previewDuration = const Duration(milliseconds: 30),
    Duration choiceDuration = const Duration(seconds: 3),
    Locale locale = const Locale('en'),
    ThemeMode themeMode = ThemeMode.dark,
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
        choiceDuration: choiceDuration,
        passAnimationDuration: Duration.zero,
      ),
    );
  }

  Future<void> tapByKey(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey<String>(key));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
  }

  Future<void> startChallenge(WidgetTester tester) async {
    await tapByKey(tester, 'scan-pass-start-challenge-button');
    await tester.pump(const Duration(milliseconds: 40));
  }

  Future<void> playSimpleRound(WidgetTester tester) async {
    await tapByKey(tester, 'scan-pass-touch-lower');
    await tapByKey(tester, 'scan-pass-next-pass-4');
    expect(find.byKey(const ValueKey<String>('scan-pass-review-panel')),
        findsOneWidget);
  }

  String reviewSummary(WidgetTester tester) {
    final text = tester.widget<Text>(
      find.byKey(const ValueKey<String>('scan-pass-review-summary')),
    );
    return text.data ?? '';
  }

  testWidgets('opens on intro without autostarting timers', (tester) async {
    await tester.pumpWidget(buildScreen());

    expect(find.byKey(const ValueKey<String>('scan-pass-intro-title')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('scan-pass-practice-button')),
        findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('scan-pass-start-challenge-button')),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 5));

    expect(find.byKey(const ValueKey<String>('scan-pass-intro-title')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('scan-pass-route-comparison')),
        findsNothing);
    expect(
      optionRepository.getValue<String>(ScanPassHistoryService.summaryKey),
      isNull,
    );
  });

  testWidgets(
      'practice supports scan touch next action and review without saving',
      (tester) async {
    await tester.pumpWidget(buildScreen());

    await tapByKey(tester, 'scan-pass-practice-button');
    expect(find.text('Practice 1. Observe the shape'), findsOneWidget);
    expect(find.text('Rear pressure around #6'), findsNothing);
    expect(find.textContaining('Last observed pressure'), findsNothing);
    expect(
        find.text('Rear pressure is not currently observed.'), findsOneWidget);

    await tapByKey(tester, 'scan-pass-scan-button');
    expect(find.textContaining('Last observed pressure'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    expect(find.byKey(const ValueKey<String>('scan-pass-ready-button')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('scan-pass-review-panel')),
        findsNothing);

    await tapByKey(tester, 'scan-pass-ready-button');
    expect(find.text('Practice 2. Choose the first touch'), findsOneWidget);

    await tapByKey(tester, 'scan-pass-touch-return');
    expect(find.text('Practice 3. Choose the next action'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('scan-pass-next-support-upper')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('scan-pass-next-pass-9')),
        findsNothing);

    await tapByKey(tester, 'scan-pass-next-support-upper');

    expect(find.byKey(const ValueKey<String>('scan-pass-review-panel')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('scan-pass-route-comparison')),
        findsOneWidget);
    expect(find.text('Score breakdown'), findsOneWidget);
    expect(find.text('Decision cues'), findsOneWidget);
    expect(find.textContaining('/100'), findsWidgets);
    expect(
      find.byKey(
          const ValueKey<String>('scan-pass-practice-start-challenge-button')),
      findsOneWidget,
    );
    expect(
        find.byKey(const ValueKey<String>('scan-pass-retry-practice-button')),
        findsOneWidget);
    expect(optionRepository.getValue<String>(ScanPassHistoryService.summaryKey),
        isNull);
    expect(optionRepository.summaryWriteCount, 0);
  });

  testWidgets('alternative review changes the displayed computed assessment',
      (tester) async {
    await tester.pumpWidget(buildScreen(seed: 13));

    await tapByKey(tester, 'scan-pass-practice-button');
    await tapByKey(tester, 'scan-pass-ready-button');
    await tapByKey(tester, 'scan-pass-touch-lower');
    await tapByKey(tester, 'scan-pass-next-pass-4');

    final mine = reviewSummary(tester);
    await tapByKey(tester, 'scan-pass-review-alternative');
    final alternative = reviewSummary(tester);

    expect(find.text('Strong alternative'), findsOneWidget);
    expect(alternative, isNot(mine));
    expect(find.byKey(const ValueKey<String>('scan-pass-route-comparison')),
        findsOneWidget);
    expect(optionRepository.summaryWriteCount, 0);
  });

  testWidgets('help cancels an incomplete challenge without saving',
      (tester) async {
    await tester.pumpWidget(buildScreen(seed: 9));

    await startChallenge(tester);
    expect(find.text('2. Choose the first touch'), findsOneWidget);

    await tapByKey(tester, 'scan-pass-help-button');
    await tester.pump(const Duration(seconds: 4));

    expect(find.byKey(const ValueKey<String>('scan-pass-intro-title')),
        findsOneWidget);
    expect(optionRepository.getValue<String>(ScanPassHistoryService.summaryKey),
        isNull);
    expect(optionRepository.summaryWriteCount, 0);
  });

  testWidgets('completes ten challenge rounds and persists v2 summary once',
      (tester) async {
    await tester.pumpWidget(buildScreen(seed: 11));
    await startChallenge(tester);

    for (var round = 0;
        round < ScanPassScenarioLibrary.roundCount;
        round += 1) {
      await playSimpleRound(tester);
      await tapByKey(tester, 'scan-pass-next-button');
      if (round != ScanPassScenarioLibrary.roundCount - 1) {
        await tester.pump(const Duration(milliseconds: 40));
      }
    }
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('scan-pass-result-title')),
        findsOneWidget);
    final raw =
        optionRepository.getValue<String>(ScanPassHistoryService.summaryKey);
    expect(raw, isNotNull);
    expect(ScanPassPersonalSummary.fromJson(raw).sessionsPlayed, 1);
    expect(
        optionRepository
            .getValue<String>(ScanPassHistoryService.legacySummaryKey),
        isNull);
    expect(optionRepository.summaryWriteCount, 1);
  });

  testWidgets('timeout records zero and advances to review', (tester) async {
    await tester.pumpWidget(
      buildScreen(
        seed: 15,
        previewDuration: const Duration(milliseconds: 10),
        choiceDuration: const Duration(milliseconds: 120),
      ),
    );

    await tapByKey(tester, 'scan-pass-start-challenge-button');
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.text('2. Choose the first touch'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 360));

    expect(find.byKey(const ValueKey<String>('scan-pass-review-panel')),
        findsOneWidget);
    expect(find.text('Timeout review'), findsOneWidget);
    expect(find.textContaining('No first touch was chosen'), findsOneWidget);
    expect(optionRepository.summaryWriteCount, 0);
  });

  testWidgets('lifecycle pause does not grant a fresh full decision window',
      (tester) async {
    await tester.pumpWidget(
      buildScreen(
        seed: 17,
        previewDuration: const Duration(milliseconds: 10),
        choiceDuration: const Duration(milliseconds: 400),
      ),
    );

    await tapByKey(tester, 'scan-pass-start-challenge-button');
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 250));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 360));

    expect(find.byKey(const ValueKey<String>('scan-pass-review-panel')),
        findsOneWidget);
    expect(find.text('Timeout review'), findsOneWidget);
    expect(optionRepository.summaryWriteCount, 0);
  });

  testWidgets('compact Korean layout renders action flow without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildScreen(seed: 21, locale: const Locale('ko')));

    await tapByKey(tester, 'scan-pass-practice-button');
    await tapByKey(tester, 'scan-pass-scan-button');
    await tapByKey(tester, 'scan-pass-ready-button');
    await tapByKey(tester, 'scan-pass-touch-lower');
    await tapByKey(tester, 'scan-pass-next-pass-8');

    expect(find.text('점수 구성'), findsOneWidget);
    expect(find.text('판단 단서'), findsOneWidget);
    expect(find.textContaining('/100'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide light-theme challenge keeps field and panel side by side',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildScreen(seed: 23, themeMode: ThemeMode.light));

    await startChallenge(tester);

    expect(find.byKey(const ValueKey<String>('scan-pass-wide-layout')),
        findsOneWidget);
    final fieldSize = tester.getSize(
      find.byKey(const ValueKey<String>('scan-pass-active-field')),
    );
    expect(fieldSize.width, greaterThan(fieldSize.height));
    expect(fieldSize.width, greaterThan(450));
    expect(find.text('2. Choose the first touch'), findsOneWidget);

    await playSimpleRound(tester);

    expect(find.text('Route comparison'), findsOneWidget);
    expect(find.text('Score breakdown'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('scan-pass-next-button')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
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
