import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/locale_service.dart';
import 'package:football_note/application/settings_service.dart';
import 'package:football_note/application/training_service.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/infrastructure/hive_option_repository.dart';
import 'package:football_note/infrastructure/hive_training_repository.dart';
import 'package:football_note/presentation/screens/calendar_screen.dart';
import 'package:hive/hive.dart';
import 'package:table_calendar/table_calendar.dart';

import '../helpers/test_asset_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<TrainingEntry> trainingBox;
  late Box optionBox;
  late TrainingService trainingService;
  late HiveOptionRepository optionRepository;
  late LocaleService localeService;
  late SettingsService settingsService;

  Future<void> pumpCalendar(WidgetTester tester) async {
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
          home: CalendarScreen(
            trainingService: trainingService,
            localeService: localeService,
            optionRepository: optionRepository,
            settingsService: settingsService,
            onEdit: (_) {},
            onCreate: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('football_note_calendar');
    Hive.init(tempDir.path);
    Hive.registerAdapter(TrainingEntryAdapter());
    trainingBox = await Hive.openBox<TrainingEntry>('training_entries');
    optionBox = await Hive.openBox('options');
  });

  setUp(() async {
    await trainingBox.clear();
    await optionBox.clear();
    trainingService = TrainingService(HiveTrainingRepository(trainingBox));
    optionRepository = HiveOptionRepository(optionBox);
    localeService = LocaleService(optionRepository)..load();
    settingsService = SettingsService(optionRepository)..load();
  });

  tearDownAll(() async {
    await trainingBox.close();
    await optionBox.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('기록이 있으면 캘린더를 접고 펼칠 수 있다', (tester) async {
    final today = DateTime.now();
    await trainingService.add(
      TrainingEntry(
        date: DateTime(today.year, today.month, today.day, 7),
        durationMinutes: 45,
        intensity: 3,
        type: '슛',
        mood: 3,
        injury: false,
        notes: '',
        location: '',
      ),
    );

    await pumpCalendar(tester);

    expect(find.byType(TableCalendar<TrainingEntry>), findsOneWidget);
    expect(find.text('캘린더 접기'), findsOneWidget);

    await tester.tap(find.text('캘린더 접기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(TableCalendar<TrainingEntry>), findsNothing);
    expect(find.text('캘린더 펼치기'), findsOneWidget);
  });

  testWidgets('기록이 없으면 저장된 상태와 무관하게 캘린더를 펼쳐둔다', (tester) async {
    await optionRepository.setValue('calendar_expanded_v1', false);

    await pumpCalendar(tester);

    expect(find.byType(TableCalendar<TrainingEntry>), findsOneWidget);
    expect(find.text('캘린더 접기'), findsOneWidget);

    await tester.tap(find.text('캘린더 접기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(TableCalendar<TrainingEntry>), findsOneWidget);
    expect(find.text('캘린더 접기'), findsOneWidget);
    expect(find.text('캘린더 펼치기'), findsNothing);
  });

  testWidgets('경기 기록은 상대 팀과 결과를 캘린더 목록에 보여준다', (tester) async {
    final today = DateTime.now();
    await trainingService.add(
      TrainingEntry(
        date: DateTime(today.year, today.month, today.day, 9),
        durationMinutes: 90,
        intensity: 4,
        type: '경기',
        mood: 4,
        injury: false,
        notes: '',
        location: '메인 구장',
        program: '경기',
        club: '라이벌 FC',
        opponentTeam: '라이벌 FC',
        scoredGoals: 3,
        concededGoals: 2,
      ),
    );

    await pumpCalendar(tester);

    expect(find.textContaining('vs 라이벌 FC'), findsOneWidget);
    expect(find.textContaining('결과 3:2'), findsOneWidget);
  });
}
