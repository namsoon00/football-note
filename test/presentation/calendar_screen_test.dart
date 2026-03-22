import 'dart:io';
import 'dart:convert';

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
          supportedLocales: const [Locale('en'), Locale('ko', 'KR')],
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

  testWidgets('경기 기록은 승패와 상대 팀 결과를 캘린더 목록에 보여준다', (tester) async {
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
        playerGoals: 1,
        playerAssists: 2,
        minutesPlayed: 70,
        matchLocation: '메인 구장',
      ),
    );

    await pumpCalendar(tester);

    expect(find.text('승'), findsOneWidget);
    expect(find.textContaining('vs 라이벌 FC'), findsOneWidget);
    expect(find.textContaining('메인 구장'), findsOneWidget);
    expect(find.textContaining('결과 3:2'), findsOneWidget);
    expect(find.textContaining('골 1'), findsOneWidget);
    expect(find.textContaining('어시스트 2'), findsOneWidget);
    expect(find.textContaining('출전 70분'), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events), findsOneWidget);
  });

  testWidgets('캘린더 기록 추가 버튼은 아이콘만 표시하고 훈련 노트 메뉴를 연다', (tester) async {
    await pumpCalendar(tester);

    expect(find.text('기록 추가'), findsNothing);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('훈련 노트'), findsOneWidget);
    expect(find.text('훈련 계획'), findsOneWidget);
    expect(find.text('시합'), findsOneWidget);
  });

  testWidgets('캘린더 상단바는 홈과 동일하게 다이어리 버튼을 숨긴다', (tester) async {
    await pumpCalendar(tester);

    expect(find.byTooltip('다이어리'), findsNothing);
  });

  testWidgets('계획 마커는 유지하고 파란 마커는 시합이 있는 날에만 표시한다', (tester) async {
    final today = DateTime.now();
    await trainingService.add(
      TrainingEntry(
        date: DateTime(today.year, today.month, today.day, 7),
        durationMinutes: 45,
        intensity: 3,
        type: '패스',
        mood: 3,
        injury: false,
        notes: '',
        location: '',
      ),
    );
    await trainingService.add(
      TrainingEntry(
        date: DateTime(today.year, today.month, today.day, 18),
        durationMinutes: 90,
        intensity: 4,
        type: '시합',
        mood: 4,
        injury: false,
        notes: '',
        location: '주 경기장',
        opponentTeam: '블루 FC',
        scoredGoals: 2,
        concededGoals: 1,
        matchLocation: '주 경기장',
      ),
    );
    await optionRepository.setValue(
      'training_plans_v1',
      jsonEncode([
        {
          'id': 'series_1',
          'scheduledAt': DateTime(
            today.year,
            today.month,
            today.day,
            18,
          ).toIso8601String(),
          'category': '슛',
          'durationMinutes': 60,
          'reminderMinutesBefore': 30,
          'repeatWeekdays': [today.weekday],
          'alarmLoopEnabled': false,
          'note': '',
          'seriesId': 'series',
          'seriesStartDate': DateTime(
            today.year,
            today.month,
            today.day,
          ).toIso8601String(),
          'seriesEndDate': DateTime(
            today.year,
            today.month,
            today.day,
          ).toIso8601String(),
        },
      ]),
    );

    await pumpCalendar(tester);

    expect(
      find.byKey(ValueKey('calendar_day_entry_marker_${today.day}')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('calendar_day_plan_marker_${today.day}')),
      findsOneWidget,
    );
  });

  testWidgets('훈련 기록만 있는 날에는 파란 마커를 표시하지 않는다', (tester) async {
    final today = DateTime.now();
    await trainingService.add(
      TrainingEntry(
        date: DateTime(today.year, today.month, today.day, 7),
        durationMinutes: 45,
        intensity: 3,
        type: '패스',
        mood: 3,
        injury: false,
        notes: '',
        location: '',
      ),
    );

    await pumpCalendar(tester);

    expect(
      find.byKey(ValueKey('calendar_day_entry_marker_${today.day}')),
      findsNothing,
    );
  });
}
