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
      'continuous attack ${config.size} ${config.locale.languageCode} keeps pitch and controls reachable',
      (tester) async {
        tester.view.physicalSize = config.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildApp(
            locale: config.locale,
            textScale: config.scale,
            optionRepository: _MemoryOptions(),
          ),
        );

        final pitch = find.byKey(const ValueKey<String>('attack-pitch'));
        expect(pitch, findsOneWidget);
        expect(tester.getRect(pitch).height, greaterThan(110));

        Future<void> tapReachable(String key) async {
          final finder = find.byKey(ValueKey<String>(key));
          await tester.ensureVisible(finder);
          final bounds = tester.getRect(finder);
          expect(bounds.height, greaterThanOrEqualTo(44), reason: key);
          expect(bounds.width, greaterThanOrEqualTo(44), reason: key);
          await tester.tap(finder);
          await tester.pumpAndSettle();
        }

        await tapReachable('attack-start');
        await tapReachable('attack-scan');

        for (final key in <String>[
          'attack-pass-4',
          'attack-carry-upper',
          'attack-carry-forward',
          'attack-carry-lower',
          'attack-hold',
        ]) {
          final finder = find.byKey(ValueKey<String>(key));
          await tester.ensureVisible(finder);
          final bounds = tester.getRect(finder);
          expect(bounds.height, greaterThanOrEqualTo(44), reason: key);
        }

        await tapReachable('attack-carry-forward');
        await tapReachable('attack-execute');

        expect(
            find.byKey(const ValueKey<String>('attack-pitch')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey<String>('attack-restart')));
        await tester.pumpAndSettle();
        await tapReachable('attack-start');
        await tapReachable('attack-pass-9');
        await tapReachable('attack-execute');
        final shotRects = <Rect>[];
        for (final target in ['upper', 'center', 'lower']) {
          final shot = find.byKey(ValueKey<String>('attack-shoot-$target'));
          expect(shot.hitTestable(), findsOneWidget,
              reason: 'Every goal target must be visible without scrolling.');
          final rect = tester.getRect(shot);
          expect(rect.height, greaterThanOrEqualTo(44));
          expect(rect.width, greaterThanOrEqualTo(44));
          for (final previous in shotRects) {
            expect(previous.overlaps(rect), isFalse,
                reason: 'Goal target hit areas must not overlap.');
          }
          shotRects.add(rect);
        }
        await tapReachable('attack-shoot-upper');
        expect(
            find.byKey(const ValueKey<String>('attack-execute')).hitTestable(),
            findsOneWidget);
        final selectedPitch = tester.getRect(pitch);
        expect(selectedPitch.height,
            greaterThan(config.size.width < config.size.height ? 210 : 120));
        expect(selectedPitch.top, greaterThanOrEqualTo(0));
        expect(selectedPitch.bottom, lessThanOrEqualTo(config.size.height));
        await tapReachable('attack-execute');
        expect(find.byKey(const ValueKey<String>('attack-replay')),
            findsOneWidget);
        await tester.tap(find.byKey(const ValueKey<String>('attack-help')));
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
            tester.element(find.byType(ScanPassGameScreen)))!;
        expect(find.text(l10n.scanPassHelpCloseAction).hitTestable(),
            findsOneWidget);
        await tester.tap(find.text(l10n.scanPassHelpCloseAction));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
      'desktop pitch takes the board instead of a side explanation panel',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildApp(
        locale: const Locale('en'),
        optionRepository: _MemoryOptions(),
      ),
    );

    final pitchRect = tester.getRect(
      find.byKey(const ValueKey<String>('attack-pitch')),
    );
    expect(pitchRect.width, greaterThan(1000));
    expect(pitchRect.height, greaterThan(450));
    expect(find.textContaining('Score breakdown'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Widget _buildApp({
  required Locale locale,
  required OptionRepository optionRepository,
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
    home: ScanPassGameScreen(
      optionRepository: optionRepository,
      seed: 7,
      previewDuration: Duration.zero,
      passAnimationDuration: Duration.zero,
    ),
  );
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
