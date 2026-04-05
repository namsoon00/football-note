import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/meal_log_service.dart';
import 'package:football_note/application/training_service.dart';
import 'package:football_note/domain/entities/meal_entry.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/repositories/training_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/coach_lesson_screen.dart';

import '../helpers/test_asset_bundle.dart';

void main() {
  testWidgets('coach lesson screen shows daily diary pages', (
    WidgetTester tester,
  ) async {
    final optionRepository = _FakeOptionRepository()
      ..setRawValue(
        'custom_diary_entries_v3',
        '{"2026-03-15":{"title":"3월 15일 다이어리","story":"오늘 장면을 남긴다.","sections":[],"moodId":"calm","recordStickers":[{"kind":"training","refId":"1742061600000"}],"stickers":["star"],"updatedAt":"2026-03-15T21:00:00.000"},"2026-03-13":{"title":"3월 13일 다이어리","story":"패스 감각 정리.","sections":[],"moodId":"calm","stickers":[],"updatedAt":"2026-03-13T21:00:00.000"}}',
      )
      ..setRawValue(
        'training_plans_v1',
        '[{"id":"plan-1","scheduledAt":"2026-03-15T17:30:00.000","category":"전술 훈련","durationMinutes":60,"note":"4대4 전환 패턴 확인"}]',
      )
      ..setRawValue(
        'training_boards_v1',
        '[{"id":"board-1","title":"측면 전개 보드","layoutJson":"{\\"version\\":1,\\"pages\\":[{\\"name\\":\\"측면 전개\\",\\"methodText\\":\\"측면에서 2:1 패턴 확인\\",\\"items\\":[{\\"type\\":\\"player\\",\\"x\\":0.2,\\"y\\":0.5,\\"size\\":32,\\"rotationDeg\\":0,\\"colorValue\\":4294967295}],\\"strokes\\":[],\\"playerPath\\":[{\\"x\\":0.2,\\"y\\":0.5},{\\"x\\":0.55,\\"y\\":0.4}],\\"ballPath\\":[{\\"x\\":0.25,\\"y\\":0.5},{\\"x\\":0.6,\\"y\\":0.45}]}]}","createdAt":"2026-03-14T10:00:00.000","updatedAt":"2026-03-15T20:00:00.000"}]',
      );
    final mealLogService = MealLogService(optionRepository);
    await mealLogService.save(
      MealEntry(
        date: DateTime(2026, 3, 15),
        breakfastRiceBowls: 1,
        lunchRiceBowls: 1,
        dinnerRiceBowls: 0.5,
      ),
    );
    final trainingService = TrainingService(
      _FakeTrainingRepository(<TrainingEntry>[
        TrainingEntry(
          date: DateTime(2026, 3, 15, 18, 0),
          createdAt: DateTime(2026, 3, 15, 18, 0),
          durationMinutes: 70,
          intensity: 4,
          type: '드리블',
          mood: 4,
          injury: false,
          notes: '압박 상황에서 볼을 길게 두지 않으려고 집중했다',
          location: '학교 운동장',
          program: '볼터치',
          drills: '{"version":2,"boardIds":["board-1"]}',
          goalFocuses: const ['왼발 퍼스트터치', '압박 탈출'],
          goodPoints: '터치 수를 일정하게 유지했다',
          improvements: '압박 직전 시선 확인이 늦었다',
          nextGoal: '왼발 퍼스트터치 안정화',
          liftingByPart: const {'inside': 80, 'outside': 60},
          jumpRopeCount: 200,
          jumpRopeMinutes: 8,
          jumpRopeEnabled: true,
          fortuneComment: '[행운 정보]\n행운 색상: 에메랄드\n행운 시간대: 오전 후반 08:10~08:50',
          fortuneRecommendation: '전진 패스 연계로 리듬을 이어가세요.',
        ),
        TrainingEntry(
          date: DateTime(2026, 3, 15, 19, 10),
          durationMinutes: 30,
          intensity: 3,
          type: '패스',
          mood: 4,
          injury: false,
          notes: '받기 전에 시야를 넓히는 연습을 했다',
          location: '학교 운동장',
          program: '원터치 패스',
          goodPoints: '패스 템포를 유지했다',
          fortuneComment: '[행운 정보]\n행운 구역: 오른쪽 하프스페이스',
          fortuneRecommendation: '첫 터치 후 전진 패스를 바로 연결해보세요.',
        ),
        TrainingEntry(
          date: DateTime(2026, 3, 15, 20, 0),
          durationMinutes: 90,
          intensity: 4,
          type: '연습경기',
          mood: 3,
          injury: true,
          notes: '후반 막판 압박 상황에서 집중력이 흔들렸다',
          location: '시립 구장',
          opponentTeam: 'Blue FC',
          scoredGoals: 2,
          concededGoals: 1,
          playerGoals: 1,
          playerAssists: 1,
          minutesPlayed: 90,
          injuryPart: '오른쪽 발목',
          painLevel: 3,
          rehab: true,
        ),
        TrainingEntry(
          date: DateTime(2026, 3, 13, 19, 0),
          durationMinutes: 50,
          intensity: 3,
          type: '패스',
          mood: 3,
          injury: false,
          notes: '원터치 패스 속도를 끌어올렸다',
          location: '실내 구장',
          program: '패스',
          improvements: '받기 전에 주변 확인',
        ),
      ]),
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
          home: CoachLessonScreen(
            optionRepository: optionRepository,
            trainingService: trainingService,
            mealLogService: mealLogService,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('다이어리'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.text('오늘의 응원'), findsNothing);
    expect(find.text('오늘의 일기'), findsNothing);
    expect(find.text('자기 전 다이어리'), findsNothing);
    expect(find.text('오늘의 운세 노트'), findsNothing);
    expect(find.textContaining('훈련 2개'), findsNothing);
    expect(find.textContaining('시합 1개'), findsNothing);
    expect(find.text('계획 1개'), findsNothing);
    expect(find.textContaining('합계 190분'), findsNothing);
    expect(find.textContaining('전체 흐름: 작은 노력도 큰 힘이 돼요.'), findsNothing);
    expect(find.text('훈련 운세'), findsNothing);
    expect(find.textContaining('측면에서 2:1 패턴 확인'), findsNothing);
    expect(find.textContaining('오른쪽 발목'), findsNothing);
    expect(find.textContaining('줄넘기: 200회'), findsNothing);
    expect(find.textContaining('Blue FC전'), findsNothing);
    expect(find.textContaining('훈련 목표: 왼발 퍼스트터치 안정화'), findsNothing);
    expect(find.textContaining('전술 훈련'), findsNothing);

    expect(find.byKey(const ValueKey('diary-page-view')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('diary-edit-2026-03-15')));
    await tester.pumpAndSettle();

    expect(find.textContaining('훈련 · 볼터치'), findsOneWidget);
    expect(find.text('운세'), findsWidgets);
    expect(find.textContaining('운세 · 볼터치'), findsNothing);
    expect(find.textContaining('전체 흐름: 작은 노력도 큰 힘이 돼요.'), findsNothing);
    expect(find.textContaining('행운 색상: 에메랄드'), findsOneWidget);
    expect(find.textContaining('전진 패스 연계로 리듬을 이어가세요.'), findsNothing);
    expect(find.textContaining('선택한 목표: 왼발 퍼스트터치, 압박 탈출'), findsOneWidget);
    expect(find.textContaining('잘한 점: 터치 수를 일정하게 유지했다'), findsOneWidget);
    expect(find.textContaining('아쉬운 점: 압박 직전 시선 확인이 늦었다'), findsOneWidget);
    expect(find.textContaining('다음 목표: 왼발 퍼스트터치 안정화'), findsOneWidget);
    expect(find.textContaining('Blue FC전'), findsOneWidget);
    expect(find.text('공기밥'), findsWidgets);
    expect(find.textContaining('훈련보드 · 측면 전개 보드'), findsOneWidget);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('이전 날짜'));
    await tester.pumpAndSettle();

    expect(find.textContaining('패스 감각 정리.'), findsOneWidget);
  });

  testWidgets('coach lesson screen shows empty guidance without records', (
    WidgetTester tester,
  ) async {
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
          home: CoachLessonScreen(
            optionRepository: _FakeOptionRepository(),
            trainingService: TrainingService(
              _FakeTrainingRepository(const <TrainingEntry>[]),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('아직 만든 다이어리가 없습니다.'), findsOneWidget);
    expect(
      find.textContaining('날짜를 골라 첫 페이지를 만들면 다이어리가 시작됩니다.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('diary-create-first-button')),
      findsOneWidget,
    );
  });

  testWidgets('coach lesson screen supports dark mode notebook layout', (
    WidgetTester tester,
  ) async {
    final createdAt = DateTime(2026, 3, 15, 18, 0);
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.dark,
          locale: const Locale('ko', 'KR'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('ko', 'KR')],
          home: CoachLessonScreen(
            optionRepository: _FakeOptionRepository()
              ..setRawValue(
                'custom_diary_entries_v3',
                '{"2026-03-15":{"title":"다크 다이어리","story":"야간 페이지","sections":[],"moodId":"calm","recordStickers":[{"kind":"training","refId":"${createdAt.millisecondsSinceEpoch}"}],"stickers":[],"updatedAt":"2026-03-15T21:00:00.000"}}',
              ),
            trainingService: TrainingService(
              _FakeTrainingRepository(<TrainingEntry>[
                TrainingEntry(
                  date: DateTime(2026, 3, 15, 18, 0),
                  createdAt: createdAt,
                  durationMinutes: 30,
                  intensity: 3,
                  type: '볼터치',
                  mood: 4,
                  injury: false,
                  notes: '다크모드 확인',
                  location: '실내 구장',
                ),
              ]),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('다이어리'), findsOneWidget);
    expect(find.text('오늘의 응원'), findsNothing);
    expect(find.text('오늘의 운세 노트'), findsNothing);
    expect(find.textContaining('행운'), findsNothing);

    expect(find.text('볼터치'), findsOneWidget);
    expect(find.textContaining('다크모드 확인'), findsWidgets);
  });

  testWidgets('coach lesson screen saves personal diary writing and stickers', (
    WidgetTester tester,
  ) async {
    final createdAt = DateTime(2026, 3, 15, 18, 0);
    final optionRepository = _FakeOptionRepository()
      ..setRawValue(
        'custom_diary_entries_v3',
        '{"2026-03-15":{"title":"초안","story":"기존 페이지","sections":[],"moodId":"calm","stickers":[],"updatedAt":"2026-03-15T20:00:00.000"}}',
      );
    final trainingService = TrainingService(
      _FakeTrainingRepository(<TrainingEntry>[
        TrainingEntry(
          date: DateTime(2026, 3, 15, 18, 0),
          createdAt: createdAt,
          durationMinutes: 45,
          intensity: 4,
          type: '패스',
          mood: 4,
          injury: false,
          notes: '개인 다이어리 저장 테스트',
          location: '학교 운동장',
          fortuneComment: '[행운 정보]\n행운 색상: 하늘색\n행운 루틴 큐: 짧게 시선 한 번 더 확인하기',
          fortuneRecommendation: '짧은 패스로 리듬을 유지해 보세요.',
        ),
      ]),
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
          home: CoachLessonScreen(
            optionRepository: optionRepository,
            trainingService: trainingService,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('초안'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('diary-edit-2026-03-15')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('diary-title-field')),
      '비 온 날의 패스 노트',
    );
    await tester.enterText(
      find.byKey(const ValueKey('diary-story-field')),
      '볼을 받기 전에 고개를 더 자주 들었고, 패스가 끊기지 않아서 기분이 좋았다.',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('diary-sticker-star')),
    );
    await tester.tap(find.byKey(const ValueKey('diary-sticker-star')));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(
        ValueKey(
          'diary-record-sticker-fortune-${createdAt.millisecondsSinceEpoch}',
        ),
      ),
    );
    await tester.tap(
      find.byKey(
        ValueKey(
          'diary-record-sticker-fortune-${createdAt.millisecondsSinceEpoch}',
        ),
      ),
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('diary-save-button')));
    await tester.tap(find.byKey(const ValueKey('diary-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('비 온 날의 패스 노트'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('diary-story-2026-03-15')),
      findsOneWidget,
    );
    expect(find.textContaining('볼을 받기 전에 고개를 더 자주 들었고'), findsOneWidget);
    expect(find.textContaining('행운 색상: 하늘색'), findsOneWidget);
    expect(find.textContaining('행운 루틴 큐: 짧게 시선 한 번 더 확인하기'), findsOneWidget);
    expect(find.textContaining('짧은 패스로 리듬을 유지해 보세요.'), findsNothing);

    final raw = optionRepository.getValue<String>('custom_diary_entries_v3');
    expect(raw, isNotNull);
    expect(raw, contains('비 온 날의 패스 노트'));
    expect(raw, contains('star'));
    expect(raw, contains('recordStickers'));
    expect(raw, contains('"kind":"fortune"'));
  });

  testWidgets(
    'coach lesson screen marks today diary only when today diary is saved',
    (WidgetTester tester) async {
      final today = DateTime.now();
      final optionRepository = _FakeOptionRepository()
        ..setRawValue(
          'custom_diary_entries_v3',
          '{"${CoachLessonScreen.todayViewedDayToken(today)}":{"title":"오늘 초안","story":"미완성","sections":[],"moodId":"calm","stickers":[],"updatedAt":"${DateTime(today.year, today.month, today.day, 12).toIso8601String()}"}}',
        );
      final trainingService = TrainingService(
        _FakeTrainingRepository(<TrainingEntry>[
          TrainingEntry(
            date: DateTime(today.year, today.month, today.day, 18, 0),
            durationMinutes: 40,
            intensity: 3,
            type: '볼터치',
            mood: 4,
            injury: false,
            notes: '오늘 기록',
            location: '학교 운동장',
          ),
          TrainingEntry(
            date: DateTime(today.year, today.month, today.day - 1, 18, 0),
            durationMinutes: 30,
            intensity: 3,
            type: '패스',
            mood: 3,
            injury: false,
            notes: '어제 기록',
            location: '학교 운동장',
          ),
        ]),
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
            home: CoachLessonScreen(
              optionRepository: optionRepository,
              trainingService: trainingService,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        optionRepository.getValue<String>(
          CoachLessonScreen.todayViewedDiaryDayKey,
        ),
        isNull,
      );

      await tester.tap(
        find.byKey(
          ValueKey(
            'diary-edit-${CoachLessonScreen.todayViewedDayToken(today)}',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('기록 스티커로 붙이기').first);
      await tester.tap(find.text('기록 스티커로 붙이기').first);
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('diary-save-button')),
      );
      await tester.tap(find.byKey(const ValueKey('diary-save-button')));
      await tester.pumpAndSettle();

      expect(
        optionRepository.getValue<String>(
          CoachLessonScreen.todayViewedDiaryDayKey,
        ),
        CoachLessonScreen.todayViewedDayToken(today),
      );
    },
  );

  testWidgets(
    'coach lesson screen shows saved diary page even with only today plans',
    (WidgetTester tester) async {
      final optionRepository = _FakeOptionRepository()
        ..setRawValue(
          'custom_diary_entries_v3',
          '{"2026-03-15":{"title":"계획 다이어리","story":"계획만 있는 날도 기록한다.","sections":[],"moodId":"calm","recordStickers":[{"kind":"plan","refId":"plan-1"}],"stickers":[],"updatedAt":"2026-03-15T18:00:00.000"}}',
        )
        ..setRawValue(
          'training_plans_v1',
          '[{"id":"plan-1","scheduledAt":"2026-03-15T17:30:00.000","category":"전술 훈련","durationMinutes":60,"note":"4대4 전환 패턴 확인"}]',
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
            home: CoachLessonScreen(
              optionRepository: optionRepository,
              trainingService: TrainingService(
                _FakeTrainingRepository(const <TrainingEntry>[]),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const ValueKey('diary-page-view')), findsOneWidget);
      expect(find.text('아직 기록이 없습니다.'), findsNothing);
      expect(find.text('계획 다이어리'), findsOneWidget);
      expect(find.text('계획 1개'), findsNothing);
      expect(find.textContaining('전술 훈련'), findsWidgets);
    },
  );

  testWidgets('coach lesson screen can create diary without training records', (
    WidgetTester tester,
  ) async {
    final optionRepository = _FakeOptionRepository();

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
          home: CoachLessonScreen(
            optionRepository: optionRepository,
            trainingService: TrainingService(
              _FakeTrainingRepository(const <TrainingEntry>[]),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('diary-create-first-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('${DateTime.now().day}').first);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('diary-title-field')),
      '훈련 없는 날의 다이어리',
    );
    await tester.enterText(
      find.byKey(const ValueKey('diary-story-field')),
      '오늘은 훈련이 없었지만 내일을 위해 생각을 정리했다.',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('diary-save-button')));
    await tester.tap(find.byKey(const ValueKey('diary-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('훈련 없는 날의 다이어리'), findsOneWidget);
    expect(
      optionRepository.getValue<String>('custom_diary_entries_v3'),
      contains('훈련 없는 날의 다이어리'),
    );
  });

  testWidgets('new diary calendar marks only saved diary dates', (
    WidgetTester tester,
  ) async {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final optionRepository = _FakeOptionRepository()
      ..setRawValue(
        'custom_diary_entries_v3',
        '{"${CoachLessonScreen.todayViewedDayToken(yesterday)}":{"title":"어제 다이어리","story":"저장된 페이지","sections":[],"moodId":"calm","stickers":[],"updatedAt":"${DateTime(yesterday.year, yesterday.month, yesterday.day, 20).toIso8601String()}"}}',
      );
    final trainingService = TrainingService(
      _FakeTrainingRepository(<TrainingEntry>[
        TrainingEntry(
          date: DateTime(today.year, today.month, today.day, 18, 0),
          createdAt: DateTime(today.year, today.month, today.day, 18, 0),
          durationMinutes: 40,
          intensity: 3,
          type: '패스',
          mood: 4,
          injury: false,
          notes: '오늘 훈련',
          location: '학교 운동장',
        ),
      ]),
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
          home: CoachLessonScreen(
            optionRepository: optionRepository,
            trainingService: trainingService,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('새 다이어리'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        ValueKey(
          'diary-calendar-marker-${CoachLessonScreen.todayViewedDayToken(yesterday)}-diary',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        ValueKey(
          'diary-calendar-marker-${CoachLessonScreen.todayViewedDayToken(today)}-training',
        ),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        ValueKey(
          'diary-calendar-marker-${CoachLessonScreen.todayViewedDayToken(today)}-match',
        ),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'new diary starts from previous record sticker order and saves selected order',
    (WidgetTester tester) async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final todayToken = CoachLessonScreen.todayViewedDayToken(today);
      final yesterdayToken = CoachLessonScreen.todayViewedDayToken(yesterday);
      final trainingCreatedAt = DateTime(
        today.year,
        today.month,
        today.day,
        18,
      ).millisecondsSinceEpoch;
      final optionRepository = _FakeOptionRepository()
        ..setRawValue(
          'custom_diary_entries_v3',
          '{"$yesterdayToken":{"title":"어제 다이어리","story":"순서 기준","sections":[],"moodId":"calm","recordStickers":[{"kind":"board","refId":"board-1"},{"kind":"meal","refId":"$yesterdayToken"},{"kind":"training","refId":"999"}],"stickers":[],"updatedAt":"${DateTime(yesterday.year, yesterday.month, yesterday.day, 21).toIso8601String()}"}}',
        )
        ..setRawValue(
          'training_boards_v1',
          '[{"id":"board-1","title":"측면 전개 보드","layoutJson":"{\\"version\\":1,\\"pages\\":[{\\"name\\":\\"측면 전개\\",\\"methodText\\":\\"측면 2:1 패턴\\",\\"items\\":[],\\"strokes\\":[],\\"playerPath\\":[],\\"ballPath\\":[]}]}","createdAt":"${DateTime(today.year, today.month, today.day, 9).toIso8601String()}","updatedAt":"${DateTime(today.year, today.month, today.day, 20).toIso8601String()}"}]',
        );
      final mealLogService = MealLogService(optionRepository);
      await mealLogService.save(
        MealEntry(
          date: DateTime(today.year, today.month, today.day),
          breakfastRiceBowls: 1,
          lunchRiceBowls: 1,
          dinnerRiceBowls: 1,
        ),
      );
      final trainingService = TrainingService(
        _FakeTrainingRepository(<TrainingEntry>[
          TrainingEntry(
            date: DateTime(today.year, today.month, today.day, 18, 0),
            createdAt: DateTime.fromMillisecondsSinceEpoch(trainingCreatedAt),
            durationMinutes: 50,
            intensity: 4,
            type: '패스',
            mood: 4,
            injury: false,
            notes: '오늘 훈련',
            location: '학교 운동장',
            program: '원터치 패스',
            drills: '{"version":2,"boardIds":["board-1"]}',
          ),
        ]),
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
            home: CoachLessonScreen(
              optionRepository: optionRepository,
              trainingService: trainingService,
              mealLogService: mealLogService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('새 다이어리'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('${today.day}').first);
      await tester.pumpAndSettle();

      expect(find.text('기록 스티커 구성'), findsNothing);

      final boardSeed = find.byKey(
        const ValueKey('diary-todo-seed-board-board-1'),
      );
      final mealSeed = find.byKey(ValueKey('diary-todo-seed-meal-$todayToken'));
      final trainingSeed = find.byKey(
        ValueKey('diary-todo-seed-training-$trainingCreatedAt'),
      );
      expect(boardSeed, findsOneWidget);
      expect(mealSeed, findsOneWidget);
      expect(trainingSeed, findsOneWidget);
      expect(
        tester.getTopLeft(boardSeed).dy,
        lessThan(tester.getTopLeft(mealSeed).dy),
      );
      expect(
        tester.getTopLeft(mealSeed).dy,
        lessThan(tester.getTopLeft(trainingSeed).dy),
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('diary-record-sticker-board-board-1')),
      );
      await tester.tap(
        find.byKey(const ValueKey('diary-record-sticker-board-board-1')),
      );
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(
          ValueKey('diary-record-sticker-training-$trainingCreatedAt'),
        ),
      );
      await tester.tap(
        find.byKey(
          ValueKey('diary-record-sticker-training-$trainingCreatedAt'),
        ),
      );
      await tester.pumpAndSettle();

      final selectedTraining = find.byKey(
        ValueKey('diary-selected-record-sticker-training-$trainingCreatedAt'),
      );
      final selectedBoard = find.byKey(
        const ValueKey('diary-selected-record-sticker-board-board-1'),
      );
      expect(selectedTraining, findsOneWidget);
      expect(selectedBoard, findsOneWidget);
      expect(
        tester.getTopLeft(selectedBoard).dy,
        lessThan(tester.getTopLeft(selectedTraining).dy),
      );

      final reorderableList = tester.widget<ReorderableListView>(
        find.byType(ReorderableListView),
      );
      reorderableList.onReorder(1, 0);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('diary-story-field')),
        '순서 저장 테스트',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('diary-save-button')),
      );
      await tester.tap(find.byKey(const ValueKey('diary-save-button')));
      await tester.pumpAndSettle();

      final raw = optionRepository.getValue<String>('custom_diary_entries_v3');
      expect(raw, isNotNull);
      final decoded = jsonDecode(raw!) as Map<String, dynamic>;
      final todayEntry = decoded[todayToken] as Map<String, dynamic>;
      final recordStickers = (todayEntry['recordStickers'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(recordStickers[0]['kind'], 'training');
      expect(recordStickers[1]['kind'], 'board');
    },
  );
}

class _FakeTrainingRepository implements TrainingRepository {
  _FakeTrainingRepository(this._entries);

  final List<TrainingEntry> _entries;

  @override
  Future<void> add(TrainingEntry entry) async {}

  @override
  Future<void> delete(TrainingEntry entry) async {}

  @override
  Future<List<TrainingEntry>> getAll() async => _entries;

  @override
  Future<void> update(int key, TrainingEntry entry) async {}

  @override
  Stream<List<TrainingEntry>> watchAll() =>
      Stream<List<TrainingEntry>>.value(_entries);
}

class _FakeOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  void setRawValue(String key, dynamic value) {
    _values[key] = value;
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) => defaults;

  @override
  List<String> getOptions(String key, List<String> defaults) => defaults;

  @override
  T? getValue<T>(String key) => _values[key] as T?;

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    _values[key] = options;
  }

  @override
  Future<void> setValue(String key, value) async {
    _values[key] = value;
  }
}
