import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive/hive.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/infrastructure/hive_training_repository.dart';
import 'package:football_note/application/training_service.dart';
import 'package:football_note/presentation/screens/stats_screen.dart';
import 'package:football_note/infrastructure/hive_option_repository.dart';
import 'package:football_note/application/locale_service.dart';
import 'package:football_note/application/settings_service.dart';

import '../helpers/test_asset_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<TrainingEntry> box;
  late TrainingService service;
  late LocaleService localeService;
  late SettingsService settingsService;
  late Box optionBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('football_note_stats');
    Hive.init(tempDir.path);
    Hive.registerAdapter(TrainingEntryAdapter());
    box = await Hive.openBox<TrainingEntry>('training_entries');
    optionBox = await Hive.openBox('options');
    service = TrainingService(HiveTrainingRepository(box));
    localeService = LocaleService(HiveOptionRepository(optionBox))..load();
    settingsService = SettingsService(HiveOptionRepository(optionBox))..load();
  });

  tearDownAll(() async {
    await box.close();
    await optionBox.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('Stats screen shows summary after save',
      (WidgetTester tester) async {
    final entry = TrainingEntry(
      date: DateTime.now(),
      durationMinutes: 60,
      intensity: 3,
      type: '기술',
      mood: 3,
      injury: false,
      notes: '',
      location: '학교 운동장',
      heightCm: 150,
      weightKg: 42.5,
    );
    await service.add(entry);

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
          supportedLocales: const [
            Locale('en'),
            Locale('ko', 'KR'),
          ],
          home: StatsScreen(
            trainingService: service,
            localeService: localeService,
            onCreate: () {},
            optionRepository: HiveOptionRepository(optionBox),
            settingsService: settingsService,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('최근 7일'), findsOneWidget);
    expect(find.text('훈련 횟수'), findsOneWidget);
    expect(find.textContaining('1회'), findsWidgets);
    expect(find.text('성장 히스토리'), findsOneWidget);
  });
}
