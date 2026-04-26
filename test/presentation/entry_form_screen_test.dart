import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/family_access_service.dart';
import 'package:football_note/application/locale_service.dart';
import 'package:football_note/application/local_fortune_service.dart';
import 'package:football_note/application/settings_service.dart';
import 'package:football_note/application/training_board_service.dart';
import 'package:football_note/application/training_service.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/infrastructure/hive_option_repository.dart';
import 'package:football_note/infrastructure/hive_training_repository.dart';
import 'package:football_note/presentation/models/training_method_layout.dart';
import 'package:football_note/presentation/screens/entry_form_screen.dart';
import 'package:football_note/presentation/screens/training_method_board_screen.dart';
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

  testWidgets(
    'parent mode can view existing entry without save or delete actions',
    (WidgetTester tester) async {
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
      await trainingService.add(original);
      final storedEntry = (await trainingService.allEntries()).single;
      await optionRepository.setValue(
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

      expect(find.text('공유 역할 읽기 전용'), findsOneWidget);
      expect(find.text('퍼스트 터치가 안정적이었다.'), findsOneWidget);
      expect(find.text('압박 회피가 늦었다.'), findsOneWidget);
      expect(find.text('턴 동작을 더 빠르게 가져간다.'), findsOneWidget);
      expect(find.widgetWithText(TextButton, '저장'), findsNothing);
      expect(find.widgetWithText(TextButton, '기록 삭제'), findsNothing);
    },
  );

  testWidgets('parent feedback saves separately and is visible in child mode', (
    WidgetTester tester,
  ) async {
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
    await trainingService.add(original);
    final storedEntry = (await trainingService.allEntries()).single;
    await optionRepository.setValue(
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

    expect(find.widgetWithText(FilledButton, '피드백 입력'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '피드백 입력'));
    await tester.pumpAndSettle();

    expect(find.text('보호자/코치 피드백'), findsWidgets);

    final feedbackField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == '보호자/코치 피드백 입력',
    );
    expect(feedbackField, findsOneWidget);

    await tester.enterText(feedbackField, '턴 타이밍이 좋아졌고 시야가 더 넓어졌어요.');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '피드백 저장'));
    await tester.pumpAndSettle();

    final raw = optionBox.get(FamilyAccessService.parentTrainingFeedbackKey);
    expect(raw, isA<Map>());
    expect(
      ((raw as Map).values.single as Map)['message'],
      '턴 타이밍이 좋아졌고 시야가 더 넓어졌어요.',
    );

    await optionRepository.setValue(
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

    expect(find.text('보호자/코치 피드백'), findsOneWidget);
    expect(find.text('턴 타이밍이 좋아졌고 시야가 더 넓어졌어요.'), findsOneWidget);
  });

  testWidgets('parent mode can open saved fortune dialog', (
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
    await optionRepository.setValue(
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

    expect(find.text('오늘의 운세'), findsOneWidget);
    expect(find.text('오늘의 행운 정보를 확인해 보세요.'), findsOneWidget);
    expect(find.textContaining('행운 색상: 에메랄드'), findsOneWidget);
  });

  testWidgets('parent mode keeps training sketch action visible', (
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
    );
    await trainingService.add(original);
    final storedEntry = (await trainingService.allEntries()).single;
    await optionRepository.setValue(
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
    final boardService = TrainingBoardService(optionRepository);
    final board = await boardService.createBoard(
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
    expect(find.text('공유 역할에서는 훈련 스케치를 수정할 수 없어요.'), findsOneWidget);
  });
}
