import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/locale_service.dart';
import 'package:football_note/application/meal_log_service.dart';
import 'package:football_note/application/settings_service.dart';
import 'package:football_note/application/training_service.dart';
import 'package:football_note/domain/entities/training_board.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/repositories/training_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/models/training_method_layout.dart';
import 'package:football_note/presentation/screens/home_hub_screen.dart';
import 'package:football_note/presentation/screens/training_method_board_screen.dart';

void main() {
  testWidgets('today task sketch opens today saved board before entry editor', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final trainingService = TrainingService(_MemoryTrainingRepository());
    final mealLogService = MealLogService(optionRepository);
    final now = DateTime.now();
    final todayBoard = TrainingBoard(
      id: 'board-today',
      title: '오늘 스케치',
      layoutJson: const TrainingMethodLayout(
        pages: <TrainingMethodPage>[
          TrainingMethodPage(name: '오늘 스케치', items: <TrainingMethodItem>[]),
        ],
      ).encode(),
      createdAt: now.subtract(const Duration(hours: 2)),
      updatedAt: now,
    );
    await optionRepository.setValue(
      'training_boards_v1',
      jsonEncode([todayBoard.toMap()]),
    );

    var editTrainingBoardCalled = false;
    var createTrainingBoardCalled = false;

    await tester.pumpWidget(
      _buildApp(
        HomeHubScreen(
          trainingService: trainingService,
          mealLogService: mealLogService,
          localeService: localeService,
          optionRepository: optionRepository,
          settingsService: settingsService,
          onCreate: () {},
          onQuickPlan: () {},
          onQuickMatch: () {},
          onQuickQuiz: () {},
          onQuickMeal: () {},
          onQuickBoard: () {},
          onOpenPlans: () {},
          onOpenLogs: () {},
          onOpenDiary: () {},
          onOpenWeeklyStats: () {},
          onEdit: (_) {},
          onEditTrainingBoard: (_) => editTrainingBoardCalled = true,
          onCreateTrainingBoard: ({DateTime? initialDate}) async {
            createTrainingBoardCalled = true;
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final sketchChip = find.text('훈련스케치');
    await tester.scrollUntilVisible(
      sketchChip,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(sketchChip);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(editTrainingBoardCalled, isFalse);
    expect(createTrainingBoardCalled, isFalse);
    expect(find.byType(TrainingMethodBoardScreen), findsOneWidget);
    expect(find.text('오늘 스케치'), findsWidgets);
  });
}

Widget _buildApp(Widget home) {
  return MaterialApp(
    locale: const Locale('ko', 'KR'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    if (value is List<String>) {
      return value;
    }
    return defaults;
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    if (value is List<int>) {
      return value;
    }
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
    _entries.sort(TrainingEntry.compareByRecentCreated);
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
    _entries.sort(TrainingEntry.compareByRecentCreated);
    _controller.add(List<TrainingEntry>.unmodifiable(_entries));
  }

  @override
  Stream<List<TrainingEntry>> watchAll() => _controller.stream;
}
