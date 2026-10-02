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
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ScanPassGameScreen(
        optionRepository: optionRepository,
        seed: seed,
        previewDuration: previewDuration,
        choiceDuration: choiceDuration,
        passAnimationDuration: Duration.zero,
      ),
    );
  }

  testWidgets('ignores target taps until the choice phase', (tester) async {
    await tester.pumpWidget(buildScreen());

    await tester.tap(find.byKey(const ValueKey<String>('scan-pass-target-1')));
    await tester.pump();
    expect(find.textContaining('Route score'), findsNothing);

    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(find.byKey(const ValueKey<String>('scan-pass-target-1')));
    await tester.pump();

    expect(find.textContaining('Route score'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('scan-pass-next-button')),
        findsOneWidget);
  });

  testWidgets('completes ten rounds and persists summary', (tester) async {
    await tester.pumpWidget(buildScreen(seed: 11));

    for (var round = 0; round < ScanPassRoundGenerator.roundCount; round += 1) {
      await tester.pump(const Duration(milliseconds: 40));
      await tester
          .tap(find.byKey(const ValueKey<String>('scan-pass-target-1')));
      await tester.pump();
      await tester
          .tap(find.byKey(const ValueKey<String>('scan-pass-next-button')));
      await tester.pump();
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
  });

  testWidgets('compact portrait layout renders without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildScreen(seed: 21));
    await tester.pump(const Duration(milliseconds: 40));

    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.byKey(const ValueKey<String>('scan-pass-bottom-text')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _MemoryOptionRepository implements OptionRepository {
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
  }
}
