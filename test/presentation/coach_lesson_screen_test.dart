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
          goodPoints: '터치 수를 일정하게 유지했다',
          nextGoal: '왼발 퍼스트터치 안정화',
          liftingByPart: const {'inside': 80, 'outside': 60},
          jumpRopeCount: 200,
          jumpRopeMinutes: 8,
          jumpRopeEnabled: true,
          fortuneComment: '전체 흐름: 작은 노력도 큰 힘이 돼요.\n행운 색상: 에메랄드',
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
          fortuneComment: '패스 각도: 오늘은 빠른 판단이 빛나요.\n행운 구역: 오른쪽 하프스페이스',
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
    expect(find.text('오늘의 일기'), findsOneWidget);
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
    expect(find.textContaining('운세 · 볼터치'), findsOneWidget);
    expect(find.textContaining('시합 · Blue FC전'), findsOneWidget);
    expect(find.text('식사'), findsWidgets);
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
      find.textContaining('다이어리를 직접 만들기 전에는 페이지를 보여주지 않습니다.'),
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
                '{"2026-03-15":{"title":"다크 다이어리","story":"야간 페이지","sections":[],"moodId":"calm","stickers":[],"updatedAt":"2026-03-15T21:00:00.000"}}',
              ),
            trainingService: TrainingService(
              _FakeTrainingRepository(<TrainingEntry>[
                TrainingEntry(
                  date: DateTime(2026, 3, 15, 18, 0),
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

    await tester.tap(find.byKey(const ValueKey('diary-edit-2026-03-15')));
    await tester.pumpAndSettle();

    expect(find.textContaining('운세 · 볼터치'), findsOneWidget);
  });

  testWidgets('coach lesson screen saves personal diary writing and stickers', (
    WidgetTester tester,
  ) async {
    final optionRepository = _FakeOptionRepository()
      ..setRawValue(
        'custom_diary_entries_v3',
        '{"2026-03-15":{"title":"초안","story":"기존 페이지","sections":[],"moodId":"calm","stickers":[],"updatedAt":"2026-03-15T20:00:00.000"}}',
      );
    final trainingService = TrainingService(
      _FakeTrainingRepository(<TrainingEntry>[
        TrainingEntry(
          date: DateTime(2026, 3, 15, 18, 0),
          durationMinutes: 45,
          intensity: 4,
          type: '패스',
          mood: 4,
          injury: false,
          notes: '개인 다이어리 저장 테스트',
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
      find.byKey(const ValueKey('diary-add-section-button')),
    );
    await tester.tap(find.byKey(const ValueKey('diary-add-section-button')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('diary-section-title-field-0')),
      '오늘의 하이라이트',
    );
    await tester.enterText(
      find.byKey(const ValueKey('diary-section-body-field-0')),
      '원터치로 템포를 살린 장면이 가장 좋았다.',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('diary-add-section-button')),
    );
    await tester.tap(find.byKey(const ValueKey('diary-add-section-button')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('diary-section-title-field-1')),
      '고마운 순간',
    );
    await tester.enterText(
      find.byKey(const ValueKey('diary-section-body-field-1')),
      '같이 패스 템포를 맞춰 준 팀원에게 고마웠다.',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('diary-mood-proud')));
    await tester.tap(find.byKey(const ValueKey('diary-mood-proud')));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('diary-sticker-star')),
    );
    await tester.tap(find.byKey(const ValueKey('diary-sticker-star')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('diary-save-button')));
    await tester.tap(find.byKey(const ValueKey('diary-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('비 온 날의 패스 노트'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('diary-story-2026-03-15')),
      findsOneWidget,
    );
    expect(find.text('오늘의 하이라이트'), findsOneWidget);
    expect(find.textContaining('원터치로 템포를 살린 장면'), findsOneWidget);
    expect(find.text('고마운 순간'), findsOneWidget);
    expect(find.textContaining('같이 패스 템포를 맞춰 준 팀원'), findsOneWidget);
    expect(find.textContaining('오늘의 무드: 뿌듯함'), findsOneWidget);

    final raw = optionRepository.getValue<String>('custom_diary_entries_v3');
    expect(raw, isNotNull);
    expect(raw, contains('비 온 날의 패스 노트'));
    expect(raw, contains('sections'));
    expect(raw, contains('star'));
    expect(raw, contains('proud'));
    expect(raw, contains('recordStickers'));
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
      await tester.tap(find.text('본문에 넣기').first);
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
    await tester.tap(find.text('확인'));
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
