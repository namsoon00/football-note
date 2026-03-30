import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive/hive.dart';
import 'package:football_note/application/meal_log_service.dart';
import 'package:football_note/domain/entities/meal_entry.dart';
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
  late MealLogService mealLogService;
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
    mealLogService = MealLogService(HiveOptionRepository(optionBox));
    localeService = LocaleService(HiveOptionRepository(optionBox))..load();
    settingsService = SettingsService(HiveOptionRepository(optionBox))..load();
  });

  tearDownAll(() async {
    await box.close();
    await optionBox.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('Stats screen shows summary after save', (
    WidgetTester tester,
  ) async {
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
          supportedLocales: const [Locale('en'), Locale('ko', 'KR')],
          home: StatsScreen(
            trainingService: service,
            mealLogService: mealLogService,
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
    expect(find.text('훈련'), findsOneWidget);
    expect(find.text('시합'), findsOneWidget);
    expect(find.text('훈련 횟수'), findsOneWidget);
    expect(find.textContaining('1회'), findsOneWidget);
    expect(find.text('전체 요약'), findsOneWidget);
    expect(find.byTooltip('다이어리'), findsNothing);
  });

  testWidgets('Stats screen separates match records in match tab', (
    WidgetTester tester,
  ) async {
    await box.clear();
    await service.add(
      TrainingEntry(
        date: DateTime.now(),
        durationMinutes: 80,
        intensity: 3,
        type: '경기',
        mood: 3,
        injury: false,
        notes: '전반 압박 좋았음',
        location: '메인 구장',
        opponentTeam: '라이벌 FC',
        scoredGoals: 3,
        concededGoals: 1,
        playerGoals: 1,
        playerAssists: 1,
        minutesPlayed: 70,
      ),
    );

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
          home: StatsScreen(
            trainingService: service,
            mealLogService: mealLogService,
            localeService: localeService,
            onCreate: () {},
            optionRepository: HiveOptionRepository(optionBox),
            settingsService: settingsService,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('시합'));
    await tester.pumpAndSettle();

    expect(find.text('시합 요약'), findsOneWidget);
    expect(find.text('전체 시합 기록'), findsOneWidget);
    expect(find.textContaining('라이벌 FC'), findsOneWidget);
  });

  testWidgets('Stats screen applies provided initial range label', (
    WidgetTester tester,
  ) async {
    await box.clear();

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
          home: StatsScreen(
            trainingService: service,
            mealLogService: mealLogService,
            localeService: localeService,
            onCreate: () {},
            optionRepository: HiveOptionRepository(optionBox),
            settingsService: settingsService,
            initialRange: DateTimeRange(
              start: DateTime(2026, 3, 16),
              end: DateTime(2026, 3, 22),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('3/16~3/22'), findsOneWidget);
  });

  testWidgets('Stats screen shows meal averages from standalone logs', (
    WidgetTester tester,
  ) async {
    await box.clear();
    await optionBox.clear();
    await mealLogService.save(
      MealEntry(
        date: DateTime.now(),
        breakfastRiceBowls: 1,
        lunchRiceBowls: 0.5,
        dinnerRiceBowls: 1,
      ),
    );

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
          home: StatsScreen(
            trainingService: service,
            mealLogService: mealLogService,
            localeService: localeService,
            onCreate: () {},
            optionRepository: HiveOptionRepository(optionBox),
            settingsService: settingsService,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('식사 기록'), findsOneWidget);
    expect(find.textContaining('평균 기대치 3공기'), findsOneWidget);
    expect(find.textContaining('평균 실제 2.5공기'), findsOneWidget);
  });
}
