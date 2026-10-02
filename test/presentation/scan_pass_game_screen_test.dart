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
  }

  Future<void> chooseFirstTarget(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(find.byKey(const ValueKey<String>('scan-pass-target-1')));
    await tester.pump();
  }

  testWidgets('opens on intro without autostarting timers', (tester) async {
    await tester.pumpWidget(buildScreen());

    expect(find.byKey(const ValueKey<String>('scan-pass-intro-title')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('scan-pass-practice-button')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey<String>('scan-pass-start-challenge-button')),
        findsOneWidget);

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

  testWidgets('practice is user paced and never persists', (tester) async {
    await tester.pumpWidget(buildScreen());

    await tapByKey(tester, 'scan-pass-practice-button');
    expect(
      find.text('Practice 1. Observe the shape'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 5));
    expect(find.byKey(const ValueKey<String>('scan-pass-ready-button')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('scan-pass-route-comparison')),
        findsNothing);

    await tapByKey(tester, 'scan-pass-ready-button');
    expect(
      find.text('Practice 2. Select a route'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 4));
    expect(
      find.text('Practice 2. Select a route'),
      findsOneWidget,
    );
    expect(find.textContaining('No pass selected'), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('scan-pass-target-1')));
    await tester.pump();

    expect(find.byKey(const ValueKey<String>('scan-pass-route-comparison')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('scan-pass-route-1')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('scan-pass-route-2')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('scan-pass-route-3')),
        findsOneWidget);
    expect(find.text('Selected'), findsWidgets);
    expect(find.text('Top score group'), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('scan-pass-route-1')),
        matching: find.text('Practice total'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('scan-pass-route-2')),
        matching: find.text('Practice total'),
      ),
      findsNothing,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('scan-pass-route-details-2')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('scan-pass-route-details-2')),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('scan-pass-route-2')),
        matching: find.text('Practice total'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Lane clearance'), findsWidgets);
    expect(find.textContaining('Connection stability'), findsWidgets);
    expect(
      find.byKey(
        const ValueKey<String>('scan-pass-practice-start-challenge-button'),
      ),
      findsOneWidget,
    );
    expect(
        find.byKey(const ValueKey<String>('scan-pass-retry-practice-button')),
        findsOneWidget);
    expect(
      optionRepository.getValue<String>(ScanPassHistoryService.summaryKey),
      isNull,
    );
    expect(optionRepository.summaryWriteCount, 0);
  });

  testWidgets('help cancels an incomplete challenge without saving', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen(seed: 9));

    await startChallenge(tester);
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.text('2. Select a passing route'), findsOneWidget);

    await tapByKey(tester, 'scan-pass-help-button');
    await tester.pump(const Duration(seconds: 4));

    expect(find.byKey(const ValueKey<String>('scan-pass-intro-title')),
        findsOneWidget);
    expect(
      optionRepository.getValue<String>(ScanPassHistoryService.summaryKey),
      isNull,
    );
    expect(optionRepository.summaryWriteCount, 0);
  });

  testWidgets('completes ten challenge rounds and persists summary once', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen(seed: 11));
    await startChallenge(tester);

    for (var round = 0; round < ScanPassRoundGenerator.roundCount; round += 1) {
      await chooseFirstTarget(tester);
      expect(find.byKey(const ValueKey<String>('scan-pass-route-comparison')),
          findsOneWidget);
      await tapByKey(tester, 'scan-pass-next-button');
    }
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('scan-pass-result-title')),
        findsOneWidget);
    final raw = optionRepository.getValue<String>(
      ScanPassHistoryService.summaryKey,
    );
    expect(raw, isNotNull);
    expect(
      ScanPassPersonalSummary.fromJson(raw).sessionsPlayed,
      1,
    );
    expect(optionRepository.summaryWriteCount, 1);
  });

  testWidgets('compact portrait layout renders without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildScreen(seed: 21));

    expect(find.byKey(const ValueKey<String>('scan-pass-intro-title')),
        findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    await tapByKey(tester, 'scan-pass-practice-button');
    await tapByKey(tester, 'scan-pass-ready-button');
    expect(find.byKey(const ValueKey<String>('scan-pass-bottom-text')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact Korean feedback keeps detailed scoring readable',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildScreen(seed: 21, locale: const Locale('ko')),
    );

    await tapByKey(tester, 'scan-pass-practice-button');
    await tapByKey(tester, 'scan-pass-ready-button');
    await tester.tap(find.byKey(const ValueKey<String>('scan-pass-target-1')));
    await tester.pump();

    expect(find.text('루트 비교'), findsOneWidget);
    expect(find.text('상위 점수군'), findsWidgets);
    expect(find.text('판단 소계'), findsOneWidget);
    expect(find.text('연습 총점'), findsOneWidget);
    // The fixed practice scenario scores this route at 9 of 90; numerator
    // order must survive the generated localization argument ordering.
    expect(find.text('9/90'), findsWidgets);
    expect(find.text('90/9'), findsNothing);
    expect(find.text('0.0/26점'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide light-theme layout keeps field and analysis side by side',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildScreen(seed: 23, themeMode: ThemeMode.light));

    await startChallenge(tester);
    await tester.pump(const Duration(milliseconds: 40));

    expect(find.byKey(const ValueKey<String>('scan-pass-wide-layout')),
        findsOneWidget);
    final fieldSize = tester.getSize(
      find.byKey(const ValueKey<String>('scan-pass-active-field')),
    );
    expect(fieldSize.width, greaterThan(fieldSize.height));
    expect(fieldSize.width, greaterThan(450));
    expect(find.text('2. Select a passing route'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('scan-pass-target-1')));
    await tester.pump();

    expect(find.text('Route comparison'), findsOneWidget);
    expect(find.text('Judgment subtotal'), findsOneWidget);
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
