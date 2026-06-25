import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/family_access_service.dart';
import 'package:football_note/application/locale_service.dart';
import 'package:football_note/application/settings_service.dart';
import 'package:football_note/application/training_board_service.dart';
import 'package:football_note/application/training_service.dart';
import 'package:football_note/domain/entities/training_board.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/infrastructure/hive_training_repository.dart';
import 'package:football_note/presentation/models/training_board_link_codec.dart';
import 'package:football_note/presentation/models/training_method_layout.dart';
import 'package:football_note/presentation/screens/entry_form_screen.dart';
import 'package:football_note/presentation/screens/training_method_board_screen.dart';
import 'package:football_note/presentation/widgets/app_page_route.dart';
import 'package:hive/hive.dart';

import '../helpers/test_asset_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<TrainingEntry> trainingBox;
  late TrainingService trainingService;
  late LocaleService localeService;
  late SettingsService settingsService;
  late _MemoryOptionRepository optionRepository;
  var storageGeneration = 0;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('football_note_entry_form');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TrainingEntryAdapter());
    }
  });

  tearDownAll(() {
    unawaited(Hive.close());
    unawaited(tempDir.delete(recursive: true));
  });

  Future<void> resetStorage(WidgetTester tester) async {
    final generation = storageGeneration++;
    await tester.runAsync(() async {
      trainingBox = await Hive.openBox<TrainingEntry>(
        'training_entries_$generation',
      );
    });
    optionRepository = _MemoryOptionRepository();
    trainingService = TrainingService(HiveTrainingRepository(trainingBox));
    localeService = LocaleService(optionRepository)..load();
    settingsService = SettingsService(optionRepository)..load();
  }

  Future<void> addEntry(WidgetTester tester, TrainingEntry entry) async {
    await tester.runAsync(() => trainingService.add(entry));
  }

  Future<List<TrainingEntry>> allEntries(WidgetTester tester) async {
    return await tester.runAsync(trainingService.allEntries) ??
        const <TrainingEntry>[];
  }

  Future<void> setOptionValue(
    WidgetTester _,
    String key,
    Object? value,
  ) async {
    await optionRepository.setValue(key, value);
  }

  Future<TrainingBoard> createBoard(
    WidgetTester _, {
    required String title,
    required String layoutJson,
  }) async {
    return TrainingBoardService(
      optionRepository,
    ).createBoard(title: title, layoutJson: layoutJson);
  }

  Future<void> tapSaveAndFinish(WidgetTester tester) async {
    final saveButton = find.widgetWithText(FilledButton, '저장');
    await tester.ensureVisible(saveButton);
    await tester.pump();
    await tester.tap(saveButton);
    for (var i = 0; i < 20; i += 1) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pump(const Duration(milliseconds: 100));

      final xpAction = find.widgetWithText(FilledButton, '확인');
      if (xpAction.evaluate().isNotEmpty) {
        await tester.tap(xpAction.last);
        continue;
      }

      final streakAction = find.widgetWithText(FilledButton, '계속하기');
      if (streakAction.evaluate().isNotEmpty) {
        await tester.tap(streakAction.last);
        continue;
      }

      if (find.widgetWithText(FilledButton, '저장').evaluate().isEmpty) {
        break;
      }
    }
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
  }

  testWidgets('entry form saves lesson flag and detail without icon', (
    WidgetTester tester,
  ) async {
    await resetStorage(tester);
    final original = TrainingEntry(
      date: DateTime(2026, 3, 14, 18),
      createdAt: DateTime(2026, 3, 14, 18),
      durationMinutes: 60,
      intensity: 3,
      type: '패스',
      mood: 4,
      injury: false,
      notes: '',
      location: '학교 운동장',
      program: '패스',
    );
    await addEntry(tester, original);
    final storedEntry = (await allEntries(tester)).single;

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
    await tester.pump(const Duration(milliseconds: 300));

    final lessonToggle = find.widgetWithText(SwitchListTile, '레슨 여부');
    await tester.ensureVisible(lessonToggle);
    expect(
      find.descendant(
        of: lessonToggle,
        matching: find.byIcon(Icons.school_outlined),
      ),
      findsNothing,
    );
    await tester.tap(lessonToggle);
    await tester.pump();
    final lessonDetailField = find.widgetWithText(TextFormField, '어떤 레슨인가요?');
    await tester.ensureVisible(lessonDetailField);
    await tester.enterText(lessonDetailField, '드리블 개인레슨');
    await tapSaveAndFinish(tester);

    final savedEntry = (await allEntries(tester)).single;
    expect(savedEntry.isLesson, isTrue);
    expect(savedEntry.lessonDetail, '드리블 개인레슨');
  });

  testWidgets('entry edit save does not reopen fortune dialog', (
    WidgetTester tester,
  ) async {
    await resetStorage(tester);
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
    await addEntry(tester, original);
    final storedEntry = (await allEntries(tester)).single;

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

    await tapSaveAndFinish(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('생일과 이름으로 고른 오늘의 가벼운 운세예요.'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('entry edit save resolves missing Hive key from stored entry', (
    WidgetTester tester,
  ) async {
    await resetStorage(tester);
    final original = TrainingEntry(
      date: DateTime(2026, 3, 16, 18),
      createdAt: DateTime(2026, 3, 16, 18),
      durationMinutes: 65,
      intensity: 3,
      type: '패스',
      mood: 4,
      injury: false,
      notes: '기존 아쉬운 점',
      location: '학교 운동장',
      program: '패스',
      goodPoints: '시야가 좋았다.',
      improvements: '기존 아쉬운 점',
      nextGoal: '압박 전 고개 들기',
    );
    await addEntry(tester, original);
    final detachedEntry = TrainingEntry(
      date: original.date,
      createdAt: original.createdAt,
      durationMinutes: original.durationMinutes,
      intensity: original.intensity,
      type: original.type,
      mood: original.mood,
      injury: original.injury,
      notes: original.notes,
      location: original.location,
      program: original.program,
      goodPoints: original.goodPoints,
      improvements: original.improvements,
      nextGoal: original.nextGoal,
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
                          entry: detachedEntry,
                        ),
                      ),
                    );
                  },
                  child: const Text('open-detached'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open-detached'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final improvementsField = find.ancestor(
      of: find.text('아쉬운 점'),
      matching: find.byType(TextFormField),
    );
    await tester.ensureVisible(improvementsField);
    await tester.enterText(improvementsField, '압박이 오기 전에 선택지를 더 빨리 봤다.');
    await tester.pump();
    await tapSaveAndFinish(tester);

    expect(trainingBox.length, 1);
    expect(trainingBox.values.single.improvements, '압박이 오기 전에 선택지를 더 빨리 봤다.');
    expect(find.text('open-detached'), findsOneWidget);
  });

  testWidgets(
    'initial training sketch flow returns to previous screen after back',
    (WidgetTester tester) async {
      await resetStorage(tester);
      final board = await createBoard(
        tester,
        title: '오늘 스케치',
        layoutJson: const TrainingMethodLayout(
          pages: <TrainingMethodPage>[
            TrainingMethodPage(name: '오늘 스케치', items: <TrainingMethodItem>[]),
          ],
        ).encode(),
      );
      await addEntry(
        tester,
        TrainingEntry(
          date: DateTime(2026, 3, 15),
          createdAt: DateTime(2026, 3, 15, 18),
          durationMinutes: 50,
          intensity: 3,
          type: '패스',
          mood: 3,
          injury: false,
          notes: '',
          location: '학교 운동장',
          drills: TrainingBoardLinkCodec.encodeBoardIds([board.id]),
        ),
      );
      final storedEntry = (await allEntries(tester)).single;

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
                      Navigator.of(context).push<void>(
                        AppPageRoute(
                          builder: (_) => EntryFormScreen(
                            trainingService: trainingService,
                            optionRepository: optionRepository,
                            localeService: localeService,
                            settingsService: settingsService,
                            entry: storedEntry,
                            initialOpenTrainingBoardEditor: true,
                            closeAfterInitialTrainingBoardEditor: true,
                          ),
                        ),
                      );
                    },
                    child: const Text('open-board-flow'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open-board-flow'));
      for (var i = 0;
          i < 12 && find.byType(TrainingMethodBoardScreen).evaluate().isEmpty;
          i += 1) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.byType(TrainingMethodBoardScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back).first);
      for (var i = 0;
          i < 12 &&
              (find.byType(EntryFormScreen).evaluate().isNotEmpty ||
                  find.byType(TrainingMethodBoardScreen).evaluate().isNotEmpty);
          i += 1) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.text('open-board-flow'), findsOneWidget);
      expect(find.byType(EntryFormScreen), findsNothing);
      expect(find.byType(TrainingMethodBoardScreen), findsNothing);
    },
  );

  testWidgets('fortune dialog hides overview and compacts lucky info', (
    WidgetTester tester,
  ) async {
    await resetStorage(tester);
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
    await addEntry(tester, original);
    final storedEntry = (await allEntries(tester)).single;

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

    expect(find.text('오늘의 운세'), findsWidgets);
    expect(find.text('생일과 이름으로 고른 오늘의 가벼운 운세예요.'), findsOneWidget);
    expect(find.text('운세 보기'), findsNothing);
    expect(find.text('운세 조합'), findsNothing);
    expect(
      find.textContaining('재미 포인트는 에메랄드 컬러예요'),
      findsOneWidget,
    );
    expect(find.textContaining('시간대 오전 후반'), findsNothing);
    expect(find.textContaining('행운 색상: 에메랄드'), findsNothing);
    expect(find.text('추천 훈련'), findsNothing);
    expect(find.text('플레이 코멘트'), findsNothing);

    await tester.ensureVisible(find.text('전체 데이터 보기'));
    await tester.tap(find.text('전체 데이터 보기'));
    await tester.pumpAndSettle();

    expect(find.text('전체 운세 데이터 베이스'), findsOneWidget);
    expect(find.text('명리 코드'), findsOneWidget);
  });

  testWidgets(
    'parent mode can view existing entry without save or delete actions',
    (WidgetTester tester) async {
      await resetStorage(tester);
      final original = TrainingEntry(
        date: DateTime(2026, 3, 15, 18),
        createdAt: DateTime(2026, 3, 15, 18),
        durationMinutes: 70,
        intensity: 4,
        type: '드리블',
        mood: 4,
        injury: false,
        notes: '기존 메모',
        goodPoints: '퍼스트 터치가 안정적이었다.',
        improvements: '압박 회피가 늦었다.',
        nextGoal: '턴 동작을 더 빠르게 가져간다.',
        location: '학교 운동장',
        program: '볼터치',
      );
      await addEntry(tester, original);
      final storedEntry = (await allEntries(tester)).single;
      await setOptionValue(
        tester,
        FamilyAccessService.currentRoleLocalKey,
        FamilyRole.parent.name,
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
      await tester.pumpAndSettle();

      expect(find.text('보호자 모드 읽기 전용'), findsNothing);
      expect(find.text('퍼스트 터치가 안정적이었다.'), findsOneWidget);
      expect(find.text('압박 회피가 늦었다.'), findsOneWidget);
      expect(find.text('턴 동작을 더 빠르게 가져간다.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '저장'), findsNothing);
      expect(find.widgetWithText(TextButton, '기록 삭제'), findsNothing);
    },
  );

  testWidgets(
    'parent feedback saves separately and is visible in player mode',
    (WidgetTester tester) async {
      await resetStorage(tester);
      final original = TrainingEntry(
        date: DateTime(2026, 4, 22, 18),
        createdAt: DateTime(2026, 4, 22, 18),
        durationMinutes: 70,
        intensity: 4,
        type: '드리블',
        mood: 4,
        injury: false,
        notes: '기존 메모',
        goodPoints: '터치가 안정적이었다.',
        improvements: '압박 회피가 늦었다.',
        nextGoal: '고개를 더 들고 시작한다.',
        location: '학교 운동장',
        program: '볼터치',
      );
      await addEntry(tester, original);
      final storedEntry = (await allEntries(tester)).single;
      await setOptionValue(
        tester,
        FamilyAccessService.currentRoleLocalKey,
        FamilyRole.parent.name,
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
      await tester.pumpAndSettle();

      final feedbackAction = find.byTooltip('피드백 입력');
      await tester.ensureVisible(feedbackAction);
      expect(feedbackAction, findsOneWidget);

      await tester.tap(feedbackAction);
      await tester.pumpAndSettle();

      expect(find.text('보호자 피드백'), findsWidgets);

      final feedbackField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == '보호자 피드백 입력',
      );
      expect(feedbackField, findsOneWidget);

      await tester.enterText(feedbackField, '턴 타이밍이 좋아졌고 시야가 더 넓어졌어요.');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, '피드백 저장'));
      await tester.pumpAndSettle();

      final raw = optionRepository.getValue<Map>(
        FamilyAccessService.parentTrainingFeedbackKey,
      );
      expect(raw, isA<Map>());
      expect(
        ((raw as Map).values.single as Map)['message'],
        '턴 타이밍이 좋아졌고 시야가 더 넓어졌어요.',
      );

      await setOptionValue(
        tester,
        FamilyAccessService.currentRoleLocalKey,
        FamilyRole.child.name,
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
      await tester.pumpAndSettle();

      expect(find.text('보호자 피드백'), findsOneWidget);
      expect(find.text('턴 타이밍이 좋아졌고 시야가 더 넓어졌어요.'), findsOneWidget);
    },
  );

  testWidgets('parent mode can open saved fortune dialog', (
    WidgetTester tester,
  ) async {
    await resetStorage(tester);
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
    await addEntry(tester, original);
    final storedEntry = (await allEntries(tester)).single;
    await setOptionValue(
      tester,
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.parent.name,
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
    await tester.pumpAndSettle();

    await tester.tap(find.text('오늘의 운세'));
    await tester.pumpAndSettle();

    expect(find.text('오늘의 운세'), findsWidgets);
    expect(find.text('생일과 이름으로 고른 오늘의 가벼운 운세예요.'), findsOneWidget);
    expect(find.textContaining('재미 포인트는 에메랄드 컬러예요'), findsOneWidget);
  });

  testWidgets('parent mode keeps training sketch action visible', (
    WidgetTester tester,
  ) async {
    await resetStorage(tester);
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
    );
    await addEntry(tester, original);
    final storedEntry = (await allEntries(tester)).single;
    await setOptionValue(
      tester,
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.parent.name,
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

    expect(find.text('훈련 스케치'), findsOneWidget);
  });

  testWidgets('training sketch screen is read-only in parent mode', (
    WidgetTester tester,
  ) async {
    await resetStorage(tester);
    final board = await createBoard(
      tester,
      title: '패스 패턴',
      layoutJson: const TrainingMethodLayout(
        pages: <TrainingMethodPage>[
          TrainingMethodPage(
            name: '패스 패턴',
            methodText: '원터치 패스',
            items: <TrainingMethodItem>[],
          ),
        ],
      ).encode(),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ko', 'KR')],
        home: TrainingMethodBoardScreen(
          boardTitle: '',
          initialLayoutJson: '',
          optionRepository: optionRepository,
          initialSelectedBoardIds: <String>[board.id],
          initialBoardId: board.id,
          readOnly: true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TrainingMethodBoardScreen), findsOneWidget);
    expect(find.text('패스 패턴'), findsWidgets);
    expect(find.text('보호자 모드에서는 훈련 스케치를 수정할 수 없어요.'), findsOneWidget);
  });
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    final stored = List<String>.of(defaults);
    _values[key] = stored;
    return stored;
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    if (value is List) {
      return value.map((item) => int.tryParse(item.toString()) ?? 0).toList();
    }
    final stored = List<int>.of(defaults);
    _values[key] = stored;
    return stored;
  }

  @override
  T? getValue<T>(String key) {
    final value = _values[key];
    return value is T ? value : null;
  }

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    _values[key] = List<dynamic>.of(options);
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    _values[key] = value;
  }
}
