import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/scan_pass_game_screen.dart';

void main() {
  for (final config in [
    (size: const Size(320, 568), scale: 1.0, locale: const Locale('ko')),
    (size: const Size(390, 844), scale: 1.3, locale: const Locale('en')),
    (size: const Size(568, 320), scale: 1.0, locale: const Locale('ja')),
  ]) {
    testWidgets(
      'mobile ${config.size} ${config.locale.languageCode} keeps self-paced controls reachable',
      (tester) async {
        tester.view.physicalSize = config.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            locale: config.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(config.scale),
              ),
              child: child!,
            ),
            home: ScanPassGameScreen(
              optionRepository: _MemoryOptions(),
              seed: 7,
              previewDuration: Duration.zero,
              passAnimationDuration: Duration.zero,
            ),
          ),
        );

        Future<void> tapReachable(String key) async {
          final finder = find.byKey(ValueKey<String>(key));
          await tester.ensureVisible(finder);
          final bounds = tester.getRect(finder);
          expect(bounds.height, greaterThanOrEqualTo(44), reason: key);
          await tester.tap(finder);
          await tester.pumpAndSettle();
        }

        await tapReachable('scan-pass-understand-scene-button');
        await tapReachable('scan-pass-scan-button');
        await tapReachable('scan-pass-receive-button');

        for (final key in <String>[
          'scan-pass-touch-upper',
          'scan-pass-touch-lower',
          'scan-pass-touch-turn',
          'scan-pass-touch-return',
        ]) {
          final finder = find.byKey(ValueKey<String>(key));
          await tester.ensureVisible(finder);
          expect(tester.getRect(finder).height, greaterThanOrEqualTo(44));
        }

        await tapReachable('scan-pass-touch-upper');
        await tapReachable('scan-pass-execute-first-touch');

        for (final key in <String>[
          'scan-pass-next-pass-4',
          'scan-pass-next-pass-8',
          'scan-pass-next-pass-9',
          'scan-pass-next-hold-8',
        ]) {
          final finder = find.byKey(ValueKey<String>(key));
          await tester.ensureVisible(finder);
          expect(tester.getRect(finder).height, greaterThanOrEqualTo(44));
        }

        await tapReachable('scan-pass-next-pass-8');
        await tapReachable('scan-pass-execute-next-action');
        expect(
          find.byKey(const ValueKey<String>('scan-pass-review-panel')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
      'first touch execution gates next action until animation completes',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ScanPassGameScreen(
          optionRepository: _MemoryOptions(),
          seed: 7,
          previewDuration: Duration.zero,
          passAnimationDuration: const Duration(seconds: 2),
        ),
      ),
    );

    Future<void> tap(String key) async {
      final finder = find.byKey(ValueKey<String>(key));
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pump();
    }

    await tap('scan-pass-understand-scene-button');
    await tester.pumpAndSettle();
    await tap('scan-pass-scan-button');
    await tester.pumpAndSettle();
    await tap('scan-pass-receive-button');
    await tester.pumpAndSettle();
    await tap('scan-pass-touch-upper');
    await tester.pumpAndSettle();
    await tap('scan-pass-execute-first-touch');

    expect(
      find.byKey(const ValueKey<String>('scan-pass-next-pass-8')),
      findsNothing,
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.byKey(const ValueKey<String>('scan-pass-next-pass-8')),
      findsNothing,
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(
      find.byKey(const ValueKey<String>('scan-pass-next-pass-8')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('return to #4 asks for #6 off-ball receiving movement',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ScanPassGameScreen(
          optionRepository: _MemoryOptions(),
          seed: 7,
          previewDuration: Duration.zero,
          passAnimationDuration: Duration.zero,
        ),
      ),
    );

    Future<void> tap(String key) async {
      final finder = find.byKey(ValueKey<String>(key));
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    await tap('scan-pass-understand-scene-button');
    await tap('scan-pass-scan-button');
    await tap('scan-pass-receive-button');
    await tap('scan-pass-touch-return');
    await tap('scan-pass-execute-first-touch');

    expect(find.text('#4 has possession'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('scan-pass-next-support-upper')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('scan-pass-next-pass-9')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}

class _MemoryOptions implements OptionRepository {
  final _values = <String, dynamic>{};

  @override
  T? getValue<T>(String key) => _values[key] as T?;

  @override
  Future<void> setValue(String key, dynamic value) async =>
      _values[key] = value;

  @override
  List<String> getOptions(String key, List<String> defaults) => defaults;

  @override
  List<int> getIntOptions(String key, List<int> defaults) => defaults;

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async =>
      _values[key] = options;
}
