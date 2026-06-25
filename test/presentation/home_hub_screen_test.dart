import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/backup_service.dart';
import 'package:football_note/application/family_access_service.dart';
import 'package:football_note/application/locale_service.dart';
import 'package:football_note/application/meal_log_service.dart';
import 'package:football_note/application/settings_service.dart';
import 'package:football_note/application/sport_state_controller.dart';
import 'package:football_note/application/training_service.dart';
import 'package:football_note/application/weather_shared_resource.dart';
import 'package:football_note/domain/entities/sport_definition.dart';
import 'package:football_note/domain/entities/training_board.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/domain/repositories/backup_repository.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/repositories/training_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/main.dart' as app;
import 'package:football_note/presentation/models/home_hub_section_settings.dart';
import 'package:football_note/presentation/models/training_method_layout.dart';
import 'package:football_note/presentation/screens/entry_form_screen.dart';
import 'package:football_note/presentation/screens/home_hub_screen.dart';
import 'package:football_note/presentation/screens/home_screen.dart';
import 'package:football_note/presentation/screens/meal_log_screen.dart';
import 'package:football_note/presentation/screens/training_method_board_screen.dart';

void main() {
  setUp(WeatherSharedResource.debugClearCache);

  testWidgets('app recreates the home tree when the sport changes', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    await optionRepository.setValue(
      SportCatalog.currentSportOptionKey,
      SportCatalog.footballId,
    );
    await optionRepository.setValue('welcome_seen_v1', true);
    await optionRepository.setValue('tab_quick_guide_seen_v1_0', true);
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final sportController = SportStateController(optionRepository);
    final trainingService = TrainingService(_MemoryTrainingRepository());
    final mealLogService = MealLogService(optionRepository);

    await tester.pumpWidget(
      app.FootballNoteApp(
        trainingService: trainingService,
        mealLogService: mealLogService,
        optionRepository: optionRepository,
        localeService: localeService,
        settingsService: settingsService,
        sportController: sportController,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey<String>('home-screen-football')),
      findsOneWidget,
    );

    await sportController.setCurrentSportId(SportCatalog.basketballId);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey<String>('home-screen-basketball')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-screen-football')),
      findsNothing,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'home startup sync checks daily backup before family refresh',
    (WidgetTester tester) async {
      final optionRepository = _MemoryOptionRepository();
      await optionRepository.setValue('tab_quick_guide_seen_v1_0', true);
      final localeService = LocaleService(optionRepository)..load();
      final settingsService = SettingsService(optionRepository)..load();
      final trainingService = TrainingService(_MemoryTrainingRepository());
      final mealLogService = MealLogService(optionRepository);
      final backupService = _TrackingBackupService();

      await tester.pumpWidget(
        _buildApp(
          HomeScreen(
            trainingService: trainingService,
            mealLogService: mealLogService,
            localeService: localeService,
            optionRepository: optionRepository,
            settingsService: settingsService,
            driveBackupService: backupService,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(backupService.autoBackupDailyCalls, 1);
      expect(backupService.refreshFamilySharedDataIfNeededCalls, 1);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('home weather badge follows shared weather snapshot updates', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final trainingService = TrainingService(_MemoryTrainingRepository());
    final mealLogService = MealLogService(optionRepository);

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

    WeatherSharedResource.primeSnapshot(
      WeatherSharedSnapshot(
        location: '탄천',
        localeTag: 'ko',
        fetchedAt: DateTime(2026, 6, 21, 9),
        summary: '소나기 18°C',
        weatherCode: 61,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('소나기'), findsOneWidget);
    expect(find.text('18°C'), findsOneWidget);
    expect(
      optionRepository.getValue<String>('home_weather_snapshot_v1'),
      contains('소나기 18°C'),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('home section settings hide and reorder sections', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final trainingService = TrainingService(_MemoryTrainingRepository());
    final mealLogService = MealLogService(optionRepository);

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

    double sectionTop(String key) {
      return tester.getTopLeft(find.byKey(ValueKey<String>(key))).dy;
    }

    expect(
      sectionTop('home-layout-level-section'),
      lessThan(sectionTop('home-layout-daily-flow-section')),
    );
    expect(find.text('홈화면 변경'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('home-section-settings-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('홈 화면 설정'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('home-section-drag-area-level')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('home-section-visible-level')),
    );
    await tester.pump();

    final reorderableList = tester.widget<ReorderableListView>(
      find.byKey(const ValueKey<String>('home-section-settings-list')),
    );
    reorderableList.onReorder(6, 5);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('홈 화면 순서를 저장했어요.'), findsOneWidget);

    final rawSettings = optionRepository.getValue<String>(
      HomeHubSectionSettings.storageKey,
    );
    expect(rawSettings, contains('"id":"level","visible":false'));
    expect(
      rawSettings!.indexOf('"id":"quick_actions"'),
      lessThan(rawSettings.indexOf('"id":"daily_flow"')),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('home-section-settings-back-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
        find.byKey(const ValueKey('home-layout-level-section')), findsNothing);
    expect(
      sectionTop('home-layout-quick-actions-section'),
      lessThan(sectionTop('home-layout-daily-flow-section')),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('home first-run guide uses coach marks and starts an action', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final trainingService = TrainingService(_MemoryTrainingRepository());
    final mealLogService = MealLogService(optionRepository);

    await tester.pumpWidget(
      _buildApp(
        HomeScreen(
          trainingService: trainingService,
          mealLogService: mealLogService,
          localeService: localeService,
          optionRepository: optionRepository,
          settingsService: settingsService,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey('tab-coach-mark-dialog')),
      findsOneWidget,
    );
    expect(find.text('3단계 중 1단계'), findsOneWidget);
    expect(
      optionRepository.getValue<bool>('tab_quick_guide_seen_v1_0'),
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('tab-coach-mark-next-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('3단계 중 2단계'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tab-coach-mark-try-button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('tab-coach-mark-try-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(MealLogScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'home quick actions and continue card use Japanese localization',
    (WidgetTester tester) async {
      final optionRepository = _MemoryOptionRepository();
      final localeService = LocaleService(optionRepository)..load();
      final settingsService = SettingsService(optionRepository)..load();
      final trainingService = TrainingService(_MemoryTrainingRepository());
      final mealLogService = MealLogService(optionRepository);

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
          locale: const Locale('ja'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('クイック操作'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('home-quick-action-logs')),
        findsNothing,
      );
      expect(find.text('試合を記録'), findsOneWidget);
      expect(find.text('練習計画を追加'), findsOneWidget);
      expect(find.text('続きから'), findsOneWidget);
      expect(find.text('Quick actions'), findsNothing);
      expect(find.text('Continue'), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('home quick plan opens plan registration sheet', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    await optionRepository.setValue('tab_quick_guide_seen_v1_0', true);
    await optionRepository.setValue('tab_quick_guide_seen_v1_2', true);
    await optionRepository.setValue('reminder_enabled', false);
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final trainingService = TrainingService(_MemoryTrainingRepository());
    final mealLogService = MealLogService(optionRepository);

    await tester.pumpWidget(
      _buildApp(
        HomeScreen(
          trainingService: trainingService,
          mealLogService: mealLogService,
          localeService: localeService,
          optionRepository: optionRepository,
          settingsService: settingsService,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.ensureVisible(find.text('훈련 계획'));
    await tester.pump();
    await tester.tap(find.text('훈련 계획'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('훈련 계획 추가'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('home quick match opens match registration sheet', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    await optionRepository.setValue('tab_quick_guide_seen_v1_0', true);
    await optionRepository.setValue('tab_quick_guide_seen_v1_2', true);
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final trainingService = TrainingService(_MemoryTrainingRepository());
    final mealLogService = MealLogService(optionRepository);

    await tester.pumpWidget(
      _buildApp(
        HomeScreen(
          trainingService: trainingService,
          mealLogService: mealLogService,
          localeService: localeService,
          optionRepository: optionRepository,
          settingsService: settingsService,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.ensureVisible(find.text('시합 기록'));
    await tester.pump();
    await tester.tap(find.text('시합 기록'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('시합 등록'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

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
    expect(find.textContaining('메인 구장'), findsNothing);
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
    expect(summary.data, isNot(contains('보조 구장')));
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
        location: '',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('오늘의 훈련 계획'), findsNothing);
    expect(find.text('다음 훈련'), findsNothing);
    expect(find.byKey(const ValueKey('today-plan-log-action')), findsNothing);
  });

  testWidgets('next training card is hidden when today plan section exists', (
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

    expect(find.text('다음 훈련'), findsNothing);
    expect(find.byKey(const ValueKey('next-plan-summary-text')), findsNothing);
    expect(find.byKey(const ValueKey('next-plan-card')), findsNothing);
    expect(openedPlanDay, isNull);
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

  testWidgets('lifting minutes count toward today tasks', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final trainingService = TrainingService(_MemoryTrainingRepository());
    final mealLogService = MealLogService(optionRepository);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await trainingService.add(
      TrainingEntry(
        date: today,
        createdAt: now,
        durationMinutes: 0,
        intensity: 3,
        type: '리프팅',
        mood: 3,
        injury: false,
        notes: '',
        location: '',
        liftingMinutes: 12,
      ),
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

    expect(find.text('오늘 할일'), findsOneWidget);
    expect(find.text('2/8 완료'), findsOneWidget);
    expect(find.text('리프팅'), findsOneWidget);
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

Widget _buildApp(Widget home, {Locale locale = const Locale('ko', 'KR')}) {
  return MaterialApp(
    locale: locale,
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

class _TrackingBackupService extends BackupService {
  int autoBackupDailyCalls = 0;
  int refreshFamilySharedDataIfNeededCalls = 0;

  _TrackingBackupService() : super(const _NoopBackupRepository());

  @override
  Future<void> autoBackupDaily() async {
    autoBackupDailyCalls += 1;
  }

  @override
  Future<FamilySharedSyncResult> refreshFamilySharedDataIfNeeded() async {
    refreshFamilySharedDataIfNeededCalls += 1;
    return const FamilySharedSyncResult.none(role: FamilyRole.child);
  }
}

class _NoopBackupRepository implements BackupRepository {
  const _NoopBackupRepository();

  @override
  Future<void> autoBackupDaily() async {}

  @override
  Future<void> backup() async {}

  @override
  Future<bool> backupIfSignedIn({bool requireAutoOnSave = false}) async => true;

  @override
  DateTime? getLastBackup() => null;

  @override
  bool isAutoDailyEnabled() => true;

  @override
  bool isAutoOnSaveEnabled() => true;

  @override
  Future<void> restoreLatest() async {}

  @override
  Future<void> setAutoDailyEnabled(bool value) async {}

  @override
  Future<void> setAutoOnSaveEnabled(bool value) async {}
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
  Future<List<TrainingEntry>> getRange(
    DateTime startInclusive,
    DateTime endExclusive,
  ) async {
    return _rangeEntries(startInclusive, endExclusive);
  }

  @override
  Future<List<TrainingEntry>> getRecent({
    required int limit,
    bool includeMatches = true,
    String? sportId,
  }) async {
    return _recentEntries(limit: limit, includeMatches: includeMatches);
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

  @override
  Stream<List<TrainingEntry>> watchRange(
    DateTime startInclusive,
    DateTime endExclusive,
  ) async* {
    yield _rangeEntries(startInclusive, endExclusive);
    yield* _controller.stream.map(
      (_) => _rangeEntries(startInclusive, endExclusive),
    );
  }

  @override
  Stream<List<TrainingEntry>> watchRecent({
    required int limit,
    bool includeMatches = true,
    String? sportId,
  }) async* {
    yield _recentEntries(limit: limit, includeMatches: includeMatches);
    yield* _controller.stream.map(
      (_) => _recentEntries(limit: limit, includeMatches: includeMatches),
    );
  }

  List<TrainingEntry> _rangeEntries(
    DateTime startInclusive,
    DateTime endExclusive,
  ) {
    return _entries
        .where(
          (entry) =>
              !entry.date.isBefore(startInclusive) &&
              entry.date.isBefore(endExclusive),
        )
        .toList(growable: false)
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<TrainingEntry> _recentEntries({
    required int limit,
    required bool includeMatches,
  }) {
    if (limit <= 0) return const <TrainingEntry>[];
    final entries = _entries
        .where((entry) => includeMatches || !entry.isMatch)
        .toList(growable: false)
      ..sort(TrainingEntry.compareByRecentCreated);
    if (entries.length <= limit) return entries;
    return entries.take(limit).toList(growable: false);
  }
}
