import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/family_access_service.dart';
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
import 'package:football_note/presentation/screens/entry_form_screen.dart';
import 'package:football_note/presentation/screens/home_hub_screen.dart';
import 'package:football_note/presentation/screens/training_method_board_screen.dart';

void main() {
  testWidgets('today plan section can start a training log from plan', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final trainingService = TrainingService(_MemoryTrainingRepository());
    final mealLogService = MealLogService(optionRepository);
    final now = DateTime.now();
    final todayPlanAt = now.subtract(const Duration(hours: 2));

    await optionRepository.setValue(
      'training_plans_v1',
      jsonEncode([
        <String, dynamic>{
          'id': 'plan-issue-271',
          'scheduledAt': todayPlanAt.toIso8601String(),
          'category': '패스 훈련',
          'durationMinutes': 75,
          'location': '메인 구장',
          'reminderMinutesBefore': 30,
          'repeatWeekdays': <int>[todayPlanAt.weekday],
          'alarmLoopEnabled': true,
          'note': '짧은 패스 후 전진 타이밍 점검',
        },
      ]),
    );

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
          onEditTrainingBoard: (_) {},
          onCreateTrainingBoard: ({DateTime? initialDate}) async {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const ValueKey('today-plan-log-action')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(EntryFormScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('entry-plan-banner')), findsOneWidget);
    expect(find.textContaining('패스 훈련'), findsWidgets);
    expect(find.textContaining('메인 구장'), findsWidgets);
  });

  testWidgets('today plan section keeps training plan button before end time', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final trainingService = TrainingService(_MemoryTrainingRepository());
    final mealLogService = MealLogService(optionRepository);
    final now = DateTime.now();
    final activePlanAt = now.subtract(const Duration(minutes: 10));

    await optionRepository.setValue(
      'training_plans_v1',
      jsonEncode([
        <String, dynamic>{
          'id': 'plan-issue-272-active',
          'scheduledAt': activePlanAt.toIso8601String(),
          'category': '드리블',
          'durationMinutes': 60,
          'location': '보조 구장',
          'reminderMinutesBefore': 20,
          'repeatWeekdays': <int>[activePlanAt.weekday],
          'alarmLoopEnabled': false,
          'note': '',
        },
      ]),
    );

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
          onEditTrainingBoard: (_) {},
          onCreateTrainingBoard: ({DateTime? initialDate}) async {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey('today-plan-open-action')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('today-plan-log-action')), findsNothing);
    expect(find.text('훈련 계획'), findsWidgets);

    final summary = tester.widget<Text>(
      find.byKey(const ValueKey('today-plan-summary-text')),
    );
    expect(summary.data, contains('오늘 계획 1개'));
    expect(summary.data, contains('드리블'));
    expect(summary.data, contains('보조 구장'));
    expect(summary.maxLines, 2);
    expect(summary.overflow, isNot(TextOverflow.ellipsis));
  });

  testWidgets('completed today plan is hidden from home section', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final trainingRepository = _MemoryTrainingRepository();
    final trainingService = TrainingService(trainingRepository);
    final mealLogService = MealLogService(optionRepository);
    final now = DateTime.now();
    final pastPlanAt = now.subtract(const Duration(hours: 3));

    await optionRepository.setValue(
      'training_plans_v1',
      jsonEncode([
        <String, dynamic>{
          'id': 'plan-issue-272-complete',
          'scheduledAt': pastPlanAt.toIso8601String(),
          'category': '패스 훈련',
          'durationMinutes': 60,
          'location': '메인 구장',
          'reminderMinutesBefore': 20,
          'repeatWeekdays': <int>[pastPlanAt.weekday],
          'alarmLoopEnabled': false,
          'note': '',
        },
      ]),
    );

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
          onEditTrainingBoard: (_) {},
          onCreateTrainingBoard: ({DateTime? initialDate}) async {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await trainingService.add(
      TrainingEntry(
        date: DateTime(now.year, now.month, now.day),
        createdAt: now.subtract(const Duration(minutes: 30)),
        durationMinutes: 60,
        intensity: 4,
        type: '패스 훈련',
        mood: 4,
        injury: false,
        notes: '',
        location: '메인 구장',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('오늘의 훈련 계획'), findsNothing);
    expect(find.text('다음 훈련'), findsNothing);
    expect(find.byKey(const ValueKey('today-plan-log-action')), findsNothing);
  });

  testWidgets('next training card opens the calendar on the planned day', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final trainingService = TrainingService(_MemoryTrainingRepository());
    final mealLogService = MealLogService(optionRepository);
    final today = DateTime.now().copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );
    final nextPlanAt = today.add(const Duration(days: 2, hours: 9));
    DateTime? openedPlanDay;

    await optionRepository.setValue(
      'training_plans_v1',
      jsonEncode([
        <String, dynamic>{
          'id': 'plan-issue-274-next',
          'scheduledAt': nextPlanAt.toIso8601String(),
          'category': '슈팅 훈련',
          'durationMinutes': 60,
          'location': '메인 구장',
          'reminderMinutesBefore': 20,
          'repeatWeekdays': <int>[nextPlanAt.weekday],
          'alarmLoopEnabled': false,
          'note': '',
        },
      ]),
    );

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
          onOpenPlansForDay: (day) => openedPlanDay = day,
          onOpenLogs: () {},
          onOpenDiary: () {},
          onOpenWeeklyStats: () {},
          onEdit: (_) {},
          onEditTrainingBoard: (_) {},
          onCreateTrainingBoard: ({DateTime? initialDate}) async {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('다음 훈련'), findsOneWidget);
    final summary = tester.widget<Text>(
      find.byKey(const ValueKey('next-plan-summary-text')),
    );
    expect(summary.data, contains('오전 9:00'));
    expect(summary.data, contains('슈팅 훈련'));

    await tester.tap(find.byKey(const ValueKey('next-plan-card')));
    await tester.pump();

    expect(
      openedPlanDay,
      DateTime(nextPlanAt.year, nextPlanAt.month, nextPlanAt.day),
    );
  });

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

    final sketchChip = find.text('스케치');
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

  testWidgets('training streak flow shows short weekday labels', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final trainingService = TrainingService(_MemoryTrainingRepository());
    final mealLogService = MealLogService(optionRepository);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

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
          onEditTrainingBoard: (_) {},
          onCreateTrainingBoard: ({DateTime? initialDate}) async {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await trainingService.add(
      TrainingEntry(
        date: today,
        createdAt: today.add(const Duration(hours: 7)),
        durationMinutes: 60,
        intensity: 4,
        type: '패스',
        mood: 4,
        injury: false,
        notes: '',
        location: '메인 구장',
      ),
    );
    await trainingService.add(
      TrainingEntry(
        date: today.subtract(const Duration(days: 1)),
        createdAt: today
            .subtract(const Duration(days: 1))
            .add(const Duration(hours: 7)),
        durationMinutes: 55,
        intensity: 3,
        type: '드리블',
        mood: 4,
        injury: false,
        notes: '',
        location: '보조 구장',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    for (var i = 0; i < 5; i++) {
      final day = today.subtract(Duration(days: 4 - i));
      final labelFinder = find.byKey(ValueKey('streak-weekday-${day.weekday}'));
      expect(labelFinder, findsOneWidget);
      final widget = tester.widget<Text>(labelFinder);
      expect(widget.data, isNotEmpty);
      expect(widget.data!.length, lessThanOrEqualTo(3));
    }
  });

  testWidgets('parent mode continue actions stay read-only from home', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    await optionRepository.setValue(
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.parent.name,
    );
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final trainingService = TrainingService(_MemoryTrainingRepository());
    final mealLogService = MealLogService(optionRepository);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final board = TrainingBoard(
      id: 'board-parent',
      title: '보호자 확인용 스케치',
      layoutJson: const TrainingMethodLayout(
        pages: <TrainingMethodPage>[
          TrainingMethodPage(
            name: '보호자 확인용 스케치',
            methodText: '라인 간격 확인',
            items: <TrainingMethodItem>[],
          ),
        ],
      ).encode(),
      createdAt: now.subtract(const Duration(minutes: 30)),
      updatedAt: now,
    );
    await optionRepository.setValue(
      'training_boards_v1',
      jsonEncode([board.toMap()]),
    );

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
          onEdit: (_) {
            fail('parent mode should not route through editable onEdit');
          },
          onEditTrainingBoard: (_) {
            fail(
              'parent mode should not route through editable training board flow',
            );
          },
          onCreateTrainingBoard: ({DateTime? initialDate}) async {
            fail('parent mode should not create a board from continue');
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await trainingService.add(
      TrainingEntry(
        date: today,
        createdAt: now,
        durationMinutes: 55,
        intensity: 4,
        type: '패스',
        mood: 4,
        injury: false,
        notes: '오늘 기록',
        location: '메인 구장',
        program: '빌드업',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.ensureVisible(find.text('이어서 쓰기'));
    await tester.tap(find.text('이어서 쓰기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(EntryFormScreen), findsOneWidget);
    expect(find.widgetWithText(TextButton, '저장'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await tester.ensureVisible(find.text('바로 수정'));
    await tester.tap(find.text('바로 수정'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(TrainingMethodBoardScreen), findsOneWidget);
    expect(find.text('보호자 모드에서는 훈련 스케치를 수정할 수 없어요.'), findsOneWidget);
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
      return List<String>.of(value);
    }
    return List<String>.of(defaults);
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    if (value is List<int>) {
      return List<int>.of(value);
    }
    return List<int>.of(defaults);
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
