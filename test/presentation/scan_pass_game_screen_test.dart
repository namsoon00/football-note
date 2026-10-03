import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/scan_pass_history_service.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
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
      ),
    );
  }

  Future<void> tapByKey(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey<String>(key));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enterFirstTouch(WidgetTester tester) async {
    await tapByKey(tester, 'scan-pass-understand-scene-button');
    await tapByKey(tester, 'scan-pass-scan-button');
    await tapByKey(tester, 'scan-pass-receive-button');
  }

  Future<void> playToReview(WidgetTester tester) async {
    await enterFirstTouch(tester);
    await tapByKey(tester, 'scan-pass-touch-lower');
    await tapByKey(tester, 'scan-pass-execute-first-touch');
    await tapByKey(tester, 'scan-pass-next-pass-8');
    await tapByKey(tester, 'scan-pass-execute-next-action');
  }

  testWidgets('opens on a self-paced scene intro without score pressure',
      (tester) async {
    await tester.pumpWidget(buildScreen());

    expect(
      find.byKey(const ValueKey<String>('scan-pass-intro-title')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('scan-pass-understand-scene-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('scan-pass-other-scene-button')),
      findsOneWidget,
    );
    expect(find.textContaining('/100'), findsNothing);
    expect(find.text('Score breakdown'), findsNothing);

    await tester.pump(const Duration(seconds: 30));

    expect(
      find.byKey(const ValueKey<String>('scan-pass-intro-title')),
      findsOneWidget,
    );
    expect(optionRepository.summaryWriteCount, 0);
  });

  testWidgets('waiting while reading does not advance or change the result',
      (tester) async {
    await tester.pumpWidget(buildScreen());

    await tapByKey(tester, 'scan-pass-understand-scene-button');
    expect(find.byKey(const ValueKey<String>('scan-pass-scan-button')),
        findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
    expect(find.byKey(const ValueKey<String>('scan-pass-scan-button')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('scan-pass-touch-upper')),
        findsNothing);

    await tapByKey(tester, 'scan-pass-scan-button');
    expect(find.textContaining('Closest defender'), findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
    expect(find.byKey(const ValueKey<String>('scan-pass-receive-button')),
        findsOneWidget);

    await tapByKey(tester, 'scan-pass-receive-button');
    expect(find.byKey(const ValueKey<String>('scan-pass-touch-lower')),
        findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
    expect(find.byKey(const ValueKey<String>('scan-pass-touch-lower')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('scan-pass-review-panel')),
        findsNothing);
  });

  testWidgets('selecting previews only; execute commits and details collapse',
      (tester) async {
    await tester.pumpWidget(buildScreen());

    await enterFirstTouch(tester);
    await tapByKey(tester, 'scan-pass-touch-lower');

    expect(find.byKey(const ValueKey<String>('scan-pass-execute-first-touch')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('scan-pass-review-panel')),
        findsNothing);
    await tester.pump(const Duration(seconds: 30));
    expect(find.byKey(const ValueKey<String>('scan-pass-execute-first-touch')),
        findsOneWidget);

    await tapByKey(tester, 'scan-pass-execute-first-touch');
    expect(find.textContaining('kept possession'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('scan-pass-next-pass-8')),
        findsOneWidget);

    await tapByKey(tester, 'scan-pass-next-pass-8');
    expect(find.byKey(const ValueKey<String>('scan-pass-execute-next-action')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('scan-pass-review-panel')),
        findsNothing);

    await tapByKey(tester, 'scan-pass-execute-next-action');
    expect(find.byKey(const ValueKey<String>('scan-pass-review-panel')),
        findsOneWidget);
    expect(find.text('Viewing my committed choice'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('scan-pass-total-score')),
        findsNothing);

    await tapByKey(tester, 'scan-pass-details-expansion');
    expect(find.byKey(const ValueKey<String>('scan-pass-total-score')),
        findsOneWidget);
    expect(optionRepository.summaryWriteCount, 0);
  });

  testWidgets('help opens without discarding current scene progress',
      (tester) async {
    await tester.pumpWidget(buildScreen());

    await tapByKey(tester, 'scan-pass-understand-scene-button');
    await tapByKey(tester, 'scan-pass-scan-button');
    expect(find.byKey(const ValueKey<String>('scan-pass-receive-button')),
        findsOneWidget);

    await tapByKey(tester, 'scan-pass-help-button');
    expect(find.text('How Scan Pass works'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('scan-pass-receive-button')),
        findsOneWidget);
    expect(optionRepository.summaryWriteCount, 0);
  });

  testWidgets('alternative replay keeps committed choice and history unchanged',
      (tester) async {
    await tester.pumpWidget(buildScreen(seed: 13));

    await playToReview(tester);
    expect(find.text('Viewing my committed choice'), findsOneWidget);
    expect(find.text('My choice'), findsOneWidget);

    await tapByKey(tester, 'scan-pass-review-alternative');

    expect(find.text('Viewing another plausible choice'), findsOneWidget);
    expect(find.text('My choice'), findsNothing);
    expect(find.byKey(const ValueKey<String>('scan-pass-review-panel')),
        findsOneWidget);
    expect(optionRepository.summaryWriteCount, 0);

    await tapByKey(tester, 'scan-pass-review-mine');
    expect(find.text('Viewing my committed choice'), findsOneWidget);
    expect(find.text('My choice'), findsOneWidget);
  });

  testWidgets('next scene advances to a purposeful different situation',
      (tester) async {
    await tester.pumpWidget(buildScreen(seed: 23, themeMode: ThemeMode.light));

    await playToReview(tester);
    expect(find.text('Scene 1 / 10'), findsOneWidget);

    await tapByKey(tester, 'scan-pass-next-button');

    expect(find.text('Scene 2 / 10'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('scan-pass-scan-button')),
        findsOneWidget);
    expect(optionRepository.summaryWriteCount, 0);
  });

  testWidgets('Korean desktop review keeps primary text causal, not numeric',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildScreen(locale: const Locale('ko'), themeMode: ThemeMode.light),
    );

    await playToReview(tester);

    expect(find.text('확인한 상황'), findsOneWidget);
    expect(find.text('내가 한 선택'), findsOneWidget);
    expect(find.text('달라진 다음 장면'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('scan-pass-total-score')),
        findsNothing);
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
