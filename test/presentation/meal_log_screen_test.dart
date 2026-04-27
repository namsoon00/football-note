import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/family_access_service.dart';
import 'package:football_note/application/meal_log_service.dart';
import 'package:football_note/application/settings_service.dart';
import 'package:football_note/domain/entities/meal_entry.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/infrastructure/hive_option_repository.dart';
import 'package:football_note/presentation/screens/meal_log_screen.dart';
import 'package:hive/hive.dart';

import '../helpers/test_asset_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box optionBox;
  late HiveOptionRepository optionRepository;
  late MealLogService mealLogService;
  late SettingsService settingsService;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('football_note_meal_log');
    Hive.init(tempDir.path);
    optionBox = await Hive.openBox('options');
  });

  setUp(() async {
    await optionBox.clear();
    optionRepository = HiveOptionRepository(optionBox);
    mealLogService = MealLogService(optionRepository);
    settingsService = SettingsService(optionRepository)..load();
  });

  tearDown(() async {
    await mealLogService.dispose();
  });

  tearDownAll(() async {
    await optionBox.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  Future<void> pumpMealLogScreen(
    WidgetTester tester, {
    required DateTime initialDate,
    MealEntry? initialEntry,
  }) async {
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: MaterialApp(
          locale: const Locale('ko', 'KR'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('ko', 'KR')],
          home: MealLogScreen(
            mealLogService: mealLogService,
            optionRepository: optionRepository,
            settingsService: settingsService,
            initialDate: initialDate,
            initialEntry: initialEntry,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('meal log screen auto saves after rice bowl tap', (tester) async {
    final day = DateTime(2026, 3, 31);

    await pumpMealLogScreen(tester, initialDate: day);

    expect(find.text('저장'), findsNothing);

    final increment = find.byKey(const ValueKey('meal-breakfast-increment'));
    await tester.tap(increment);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(increment);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(increment);
    await tester.pump(const Duration(milliseconds: 400));

    final saved = mealLogService.entryForDay(day);
    expect(saved, isNotNull);
    expect(saved!.breakfastRiceBowls, 1.5);
    expect(saved.lunchRiceBowls, 0);
    expect(saved.dinnerRiceBowls, 0);
  });

  testWidgets('parent mode can view meal log without editing it', (
    tester,
  ) async {
    final day = DateTime(2026, 3, 31);
    await optionRepository.setValue(
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.parent.name,
    );
    await mealLogService.save(
      MealEntry(
        date: day,
        breakfastRiceBowls: 1.5,
        lunchRiceBowls: 1,
        dinnerRiceBowls: 0.5,
      ),
    );

    await pumpMealLogScreen(tester, initialDate: day);

    expect(find.text('식사 기록은 읽기 전용이에요.'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('meal-breakfast-increment')),
      warnIfMissed: false,
    );
    await tester.pump();

    final saved = mealLogService.entryForDay(day);
    expect(saved, isNotNull);
    expect(saved!.breakfastRiceBowls, 1.5);
  });
}
