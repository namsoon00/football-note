import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/locale_service.dart';
import 'package:football_note/application/local_fortune_service.dart';
import 'package:football_note/application/settings_service.dart';
import 'package:football_note/application/training_service.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/infrastructure/hive_option_repository.dart';
import 'package:football_note/infrastructure/hive_training_repository.dart';
import 'package:football_note/presentation/screens/entry_form_screen.dart';
import 'package:hive/hive.dart';

import '../helpers/test_asset_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<TrainingEntry> trainingBox;
  late Box optionBox;
  late TrainingService trainingService;
  late LocaleService localeService;
  late SettingsService settingsService;
  late HiveOptionRepository optionRepository;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('football_note_entry_form');
    Hive.init(tempDir.path);
    Hive.registerAdapter(TrainingEntryAdapter());
    trainingBox = await Hive.openBox<TrainingEntry>('training_entries');
    optionBox = await Hive.openBox('options');
    optionRepository = HiveOptionRepository(optionBox);
    trainingService = TrainingService(HiveTrainingRepository(trainingBox));
    localeService = LocaleService(optionRepository)..load();
    settingsService = SettingsService(optionRepository)..load();
  });

  tearDown(() async {
    await trainingBox.clear();
    await optionBox.clear();
  });

  tearDownAll(() async {
    await trainingBox.close();
    await optionBox.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('entry edit save does not reopen fortune dialog', (
    WidgetTester tester,
  ) async {
    final original = TrainingEntry(
      date: DateTime(2026, 3, 15, 18),
      createdAt: DateTime(2026, 3, 15, 18),
      durationMinutes: 70,
      intensity: 4,
      type: '드리블',
      mood: 4,
      injury: false,
      notes: '기존 메모',
      location: '학교 운동장',
      program: '볼터치',
      fortuneComment: '[행운 정보]\n행운 색상: 에메랄드\n행운 시간대: 오전 후반 08:10~08:50',
      fortuneRecommendation: '전진 패스 연계로 리듬을 이어가세요.',
    );
    await trainingService.add(original);
    final storedEntry = (await trainingService.allEntries()).single;

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
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => EntryFormScreen(
                          trainingService: trainingService,
                          optionRepository: optionRepository,
                          localeService: localeService,
                          settingsService: settingsService,
                          entry: storedEntry,
                        ),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('오늘의 운세'), findsNothing);
    expect(find.text('오늘의 행운 정보를 확인해 보세요.'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('fortune dialog shows pool size and lucky info only', (
    WidgetTester tester,
  ) async {
    final original = TrainingEntry(
      date: DateTime(2026, 3, 15, 18),
      createdAt: DateTime(2026, 3, 15, 18),
      durationMinutes: 70,
      intensity: 4,
      type: '드리블',
      mood: 4,
      injury: false,
      notes: '기존 메모',
      location: '학교 운동장',
      program: '볼터치',
      fortuneComment: '[행운 정보]\n행운 색상: 에메랄드\n행운 시간대: 오전 후반 08:10~08:50',
      fortuneRecommendation: '전진 패스 연계로 리듬을 이어가세요.',
      fortuneRecommendedProgram: '전진 패스 연계',
    );
    await trainingService.add(original);
    final storedEntry = (await trainingService.allEntries()).single;
    final formattedPoolSize = LocalFortuneService.formatFortunePoolCount('ko');

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
          home: EntryFormScreen(
            trainingService: trainingService,
            optionRepository: optionRepository,
            localeService: localeService,
            settingsService: settingsService,
            entry: storedEntry,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('오늘의 운세'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('오늘의 운세'), findsOneWidget);
    expect(find.text('오늘의 행운 정보를 확인해 보세요.'), findsOneWidget);
    expect(find.text('전체 운세 pool'), findsOneWidget);
    expect(find.text('$formattedPoolSize개'), findsOneWidget);
    expect(find.textContaining('행운 색상: 에메랄드'), findsOneWidget);
    expect(find.textContaining('행운 시간대: 오전 후반 08:10~08:50'), findsOneWidget);
    expect(find.text('추천 훈련'), findsNothing);
    expect(find.text('운세 코멘트'), findsNothing);
  });
}
