import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive/hive.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/infrastructure/hive_training_repository.dart';
import 'package:football_note/application/training_service.dart';
import 'package:football_note/presentation/screens/logs_screen.dart';
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
    tempDir = await Directory.systemTemp.createTemp('football_note_logs');
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

  testWidgets('Logs screen shows saved entry', (WidgetTester tester) async {
    final entry = TrainingEntry(
      date: DateTime(2024, 1, 1),
      durationMinutes: 60,
      intensity: 3,
      type: '기술',
      mood: 3,
      injury: false,
      notes: '메모',
      location: '학교 운동장',
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
          home: LogsScreen(
            trainingService: service,
            localeService: localeService,
            optionRepository: HiveOptionRepository(optionBox),
            settingsService: settingsService,
            onEdit: (_) {},
            onCreate: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('기술'), findsOneWidget);
    expect(find.text('60분'), findsOneWidget);
    expect(find.text('학교 운동장'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '메모');
    await tester.pump();
    expect(find.text('기술'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '없는검색');
    await tester.pump();
    expect(find.text('검색 결과가 없습니다.'), findsOneWidget);
  });

  testWidgets('Logs screen excludes match entries',
      (WidgetTester tester) async {
    await box.clear();
    await service.add(
      TrainingEntry(
        date: DateTime(2024, 1, 2),
        durationMinutes: 90,
        intensity: 4,
        type: '경기',
        mood: 4,
        injury: false,
        notes: '시합 메모',
        location: '보조 경기장',
        program: '경기',
        opponentTeam: '라이벌 FC',
        scoredGoals: 2,
        concededGoals: 1,
        playerGoals: 1,
        playerAssists: 1,
        minutesPlayed: 80,
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
          supportedLocales: const [
            Locale('en'),
            Locale('ko', 'KR'),
          ],
          home: LogsScreen(
            trainingService: service,
            localeService: localeService,
            optionRepository: HiveOptionRepository(optionBox),
            settingsService: settingsService,
            onEdit: (_) {},
            onCreate: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('기록이 없습니다.'), findsOneWidget);
    expect(find.textContaining('라이벌 FC'), findsNothing);
    expect(find.textContaining('시합 메모'), findsNothing);
  });
}
