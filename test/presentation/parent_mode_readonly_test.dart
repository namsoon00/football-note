import 'dart:async';

import 'package:football_note/application/family_access_service.dart';
import 'package:football_note/application/locale_service.dart';
import 'package:football_note/application/meal_log_service.dart';
import 'package:football_note/application/settings_service.dart';
import 'package:football_note/application/training_service.dart';
import 'package:football_note/domain/entities/meal_entry.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/repositories/training_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/entry_form_screen.dart';
import 'package:football_note/presentation/screens/meal_log_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_asset_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('parent mode meal log stays visible and read-only', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    await optionRepository.setValue(
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.parent.name,
    );
    final mealLogService = MealLogService(optionRepository);
    final settingsService = SettingsService(optionRepository)..load();
    final day = DateTime(2026, 3, 31);

    await mealLogService.save(
      MealEntry(
        date: day,
        breakfastRiceBowls: 1.5,
        lunchRiceBowls: 1,
        dinnerRiceBowls: 0.5,
      ),
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
        home: MealLogScreen(
          mealLogService: mealLogService,
          optionRepository: optionRepository,
          settingsService: settingsService,
          initialDate: day,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('부모 모드에서는 식사 기록을 수정할 수 없어요. 식사 입력은 선수 모드에서 진행해 주세요.'),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('meal-breakfast-increment')),
      warnIfMissed: false,
    );
    await tester.pump();

    final saved = mealLogService.entryForDay(day);
    expect(saved, isNotNull);
    expect(saved!.breakfastRiceBowls, 1.5);
  });

  testWidgets('parent mode entry detail stays visible and read-only', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    await optionRepository.setValue(
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.parent.name,
    );
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final trainingRepository = _MemoryTrainingRepository();
    final trainingService = TrainingService(trainingRepository);
    final entry = TrainingEntry(
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
    await trainingService.add(entry);
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

    expect(find.text('부모 모드 읽기 전용'), findsOneWidget);
    expect(find.text('퍼스트 터치가 안정적이었다.'), findsOneWidget);
    expect(find.text('압박 회피가 늦었다.'), findsOneWidget);
    expect(find.text('턴 동작을 더 빠르게 가져간다.'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '저장'), findsNothing);
    expect(find.widgetWithText(TextButton, '기록 삭제'), findsNothing);
  });
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    return value is List<String>
        ? List<String>.of(value)
        : List<String>.of(defaults);
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    return value is List<int> ? List<int>.of(value) : List<int>.of(defaults);
  }

  @override
  T? getValue<T>(String key) => _values[key] as T?;

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    _values[key] = options;
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    _values[key] = value;
  }
}

class _MemoryTrainingRepository implements TrainingRepository {
  final List<TrainingEntry> _entries = <TrainingEntry>[];
  final StreamController<List<TrainingEntry>> _controller =
      StreamController<List<TrainingEntry>>.broadcast();

  @override
  Future<void> add(TrainingEntry entry) async {
    _entries.add(entry);
    _emit();
  }

  @override
  Future<void> delete(TrainingEntry entry) async {
    _entries.removeWhere((item) => item.key == entry.key);
    _emit();
  }

  @override
  Future<List<TrainingEntry>> getAll() async =>
      List<TrainingEntry>.of(_entries);

  @override
  Future<void> update(int key, TrainingEntry entry) async {
    if (_entries.isEmpty) return;
    _entries[0] = entry;
    _emit();
  }

  @override
  Stream<List<TrainingEntry>> watchAll() => _controller.stream;

  void _emit() {
    _controller.add(List<TrainingEntry>.unmodifiable(_entries));
  }
}
