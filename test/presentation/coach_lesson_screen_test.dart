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
  testWidgets('coach lesson screen turns training records into diary text', (
    WidgetTester tester,
  ) async {
    final trainingService = TrainingService(
      _FakeTrainingRepository(<TrainingEntry>[
        TrainingEntry(
          date: DateTime.now().subtract(const Duration(days: 1)),
          durationMinutes: 70,
          intensity: 4,
          type: '드리블',
          mood: 4,
          injury: false,
          notes: '압박 상황에서 볼을 길게 두지 않으려고 집중했다',
          location: '학교 운동장',
          program: '볼터치',
          goodPoints: '터치 수를 일정하게 유지했다',
          nextGoal: '왼발 퍼스트터치 안정화',
        ),
        TrainingEntry(
          date: DateTime.now().subtract(const Duration(days: 3)),
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
            optionRepository: _FakeOptionRepository(),
            trainingService: trainingService,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('훈련 기록 일기 변환'), findsOneWidget);
    expect(find.text('훈련 일기'), findsOneWidget);
    expect(find.textContaining('총 2회'), findsOneWidget);
    expect(find.textContaining('누적 120분'), findsOneWidget);
    expect(find.textContaining('가장 자주 나온 주제'), findsOneWidget);
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

    expect(find.text('아직 훈련 기록이 없습니다.'), findsOneWidget);
    expect(find.textContaining('기록을 남기면 여기서 자동으로'), findsOneWidget);
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
