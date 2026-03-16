import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/training_service.dart';
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
        'training_plans_v1',
        '[{"id":"plan-1","scheduledAt":"2026-03-15T17:30:00.000","category":"전술 훈련","durationMinutes":60,"note":"4대4 전환 패턴 확인"}]',
      )
      ..setRawValue(
        'training_boards_v1',
        '[{"id":"board-1","title":"측면 전개 보드","layoutJson":"{}","createdAt":"2026-03-14T10:00:00.000","updatedAt":"2026-03-15T20:00:00.000"}]',
      );
    final trainingService = TrainingService(
      _FakeTrainingRepository(<TrainingEntry>[
        TrainingEntry(
          date: DateTime(2026, 3, 15, 18, 0),
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
          liftingByPart: const {'왼발': 80, '오른발': 60},
          jumpRopeCount: 200,
          jumpRopeMinutes: 8,
          jumpRopeEnabled: true,
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
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('다이어리'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.text('하루씩 넘겨보는 다이어리'), findsOneWidget);
    expect(find.text('자기 전 다이어리'), findsOneWidget);
    expect(find.textContaining('훈련 1개'), findsOneWidget);
    expect(find.textContaining('시합 1개'), findsOneWidget);
    expect(find.text('계획 1개'), findsOneWidget);
    expect(find.textContaining('합계 160분'), findsOneWidget);
    expect(find.textContaining('측면 전개 보드'), findsWidgets);
    expect(find.textContaining('오른쪽 발목'), findsWidgets);
    expect(find.textContaining('줄넘기: 200회'), findsWidgets);
    expect(find.textContaining('Blue FC전'), findsWidgets);

    expect(find.byKey(const ValueKey('diary-page-view')), findsOneWidget);

    await tester.tap(find.byTooltip('이전 날짜'));
    await tester.pumpAndSettle();

    expect(find.textContaining('합계 50분'), findsOneWidget);
    expect(find.textContaining('패스'), findsWidgets);
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

    expect(find.text('아직 기록이 없습니다.'), findsOneWidget);
    expect(find.textContaining('훈련이나 시합, 계획을 남기면'), findsOneWidget);
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
