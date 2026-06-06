import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/locale_service.dart';
import 'package:football_note/application/meal_log_service.dart';
import 'package:football_note/application/settings_service.dart';
import 'package:football_note/application/training_service.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/repositories/training_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/challenge_screen.dart';

void main() {
  testWidgets('challenge screen starts a template and shows round calendar', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.view.devicePixelRatio = 1;
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetDevicePixelRatio();
    });
    final optionRepository = _MemoryOptionRepository();
    final trainingService = TrainingService(_MemoryTrainingRepository());
    final mealLogService = MealLogService(optionRepository);
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChallengeScreen(
          trainingService: trainingService,
          mealLogService: mealLogService,
          optionRepository: optionRepository,
          localeService: localeService,
          settingsService: settingsService,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('1. 기간 선택'), findsOneWidget);
    expect(find.text('3일 챌린지'), findsOneWidget);
    expect(find.text('2. 단계 선택'), findsNothing);
    expect(find.widgetWithText(FilledButton, '챌린지 시작'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.history));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('챌린지 히스토리'), findsOneWidget);
    expect(find.text('아직 챌린지 기록이 없어요.'), findsOneWidget);
    Navigator.of(tester.element(find.text('챌린지 히스토리'))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const ValueKey('challenge-template-starter_3')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('2. 단계 선택'), findsOneWidget);
    expect(find.text('3. 미션 선택'), findsNothing);
    expect(find.text('훈련 프로그램 편집'), findsNothing);
    expect(find.widgetWithText(FilledButton, '챌린지 시작'), findsNothing);
    expect(find.text('라운드'), findsNothing);

    final rookieLevel = find.byKey(const ValueKey('challenge-level-rookie'));
    await tester.ensureVisible(rookieLevel);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(rookieLevel);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('3. 미션 선택'), findsOneWidget);
    expect(find.text('훈련 프로그램 편집'), findsOneWidget);
    expect(find.text('미션별 목표량'), findsOneWidget);
    expect(find.text('4. 시작 준비'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(FilledButton, '챌린지 시작'));
    await tester.pump(const Duration(milliseconds: 300));
    final startButton = find.widgetWithText(FilledButton, '챌린지 시작');
    await tester.tap(startButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('라운드'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('challenge-rounds-calendar')),
      findsOneWidget,
    );
    expect(find.text('R1'), findsOneWidget);
    expect(find.text('줄넘기'), findsAtLeastNWidgets(1));
    expect(find.text('리프팅'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await mealLogService.dispose();
  });
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    if (value is List<String>) return value;
    return defaults;
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    if (value is List<int>) return value;
    return defaults;
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

  _MemoryTrainingRepository() {
    _controller.add(const <TrainingEntry>[]);
  }

  @override
  Future<void> add(TrainingEntry entry) async {
    _entries.add(entry);
    _controller.add(List<TrainingEntry>.unmodifiable(_entries));
  }

  @override
  Future<void> delete(TrainingEntry entry) async {
    _entries.remove(entry);
    _controller.add(List<TrainingEntry>.unmodifiable(_entries));
  }

  @override
  Future<List<TrainingEntry>> getAll() async {
    return List<TrainingEntry>.unmodifiable(_entries);
  }

  @override
  Future<void> update(int key, TrainingEntry entry) async {
    if (key >= 0 && key < _entries.length) {
      _entries[key] = entry;
    }
    _controller.add(List<TrainingEntry>.unmodifiable(_entries));
  }

  @override
  Stream<List<TrainingEntry>> watchAll() => _controller.stream;
}
