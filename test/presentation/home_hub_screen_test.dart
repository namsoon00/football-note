import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/backup_service.dart';
import 'package:football_note/application/club_schedule_service.dart';
import 'package:football_note/application/family_access_service.dart';
import 'package:football_note/application/locale_service.dart';
import 'package:football_note/application/meal_log_service.dart';
import 'package:football_note/application/settings_service.dart';
import 'package:football_note/application/sport_state_controller.dart';
import 'package:football_note/application/training_service.dart';
import 'package:football_note/application/weather_shared_resource.dart';
import 'package:football_note/domain/entities/sport_definition.dart';
import 'package:football_note/domain/entities/meal_entry.dart';
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
import 'package:football_note/presentation/widgets/watch_cart/watch_cart_card.dart';

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
    'home promotes incomplete meal routine to the top',
    (WidgetTester tester) async {
      final optionRepository = _MemoryOptionRepository();
      await optionRepository.setValue('tab_quick_guide_seen_v1_0', true);
      final localeService = LocaleService(optionRepository)..load();
      final settingsService = SettingsService(optionRepository)..load();
      final trainingService = TrainingService(_MemoryTrainingRepository());
      final mealLogService = MealLogService(optionRepository);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      await mealLogService.save(
        MealEntry(date: today, breakfastRiceBowls: 1),
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

      expect(find.text('식사 루틴을 더 채워야 합니다.'), findsOneWidget);
      expect(
        sectionTop('home-layout-meal-section'),
        lessThan(sectionTop('home-layout-club-schedule-section')),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

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
    await optionRepository.setValue(
      HomeHubSectionSettings.storageKey,
      HomeHubSectionSettings.fromOrder(
        HomeHubSectionSettings.routineFirstOrder,
      ).encode(),
    );
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
        fetchedAt: DateTime.now(),
        summary: '소나기 18°C',
        weatherCode: 61,
        pm10: 42,
        pm25: 18,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('18°C'), findsOneWidget);
    expect(find.text('미세먼지 42'), findsOneWidget);
    expect(find.text('소나기'), findsNothing);
    expect(
      optionRepository.getValue<String>('home_weather_snapshot_v1'),
      contains('소나기 18°C'),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('home shows club schedule card and opens schedule screen', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final trainingService = TrainingService(_MemoryTrainingRepository());
    final mealLogService = MealLogService(optionRepository);
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final canUseToday = nowMinutes < 22 * 60;
    final scheduleWeekday =
        canUseToday ? now.weekday : now.add(const Duration(days: 1)).weekday;
    final scheduleStartMinutes = canUseToday ? nowMinutes + 1 : 19 * 60;
    final scheduleEndMinutes = canUseToday ? nowMinutes + 61 : 21 * 60;

    await ClubScheduleService(optionRepository).saveProfile(
      ClubScheduleProfile.empty().copyWith(
        clubName: '성남 U15',
        weekdaySchedules: [
          ClubTrainingSchedule(
            weekday: scheduleWeekday,
            enabled: true,
            startMinutes: scheduleStartMinutes,
            endMinutes: scheduleEndMinutes,
            uniformColorValue: 0xFFDC2626,
          ),
        ],
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

    final card = find.byKey(const ValueKey<String>('home-club-schedule-card'));
    expect(card, findsOneWidget);
    expect(find.text('성남 U15'), findsOneWidget);
    final cardContext = tester.element(card);
    String timeLabel(int minutes) {
      return MaterialLocalizations.of(cardContext).formatTimeOfDay(
        TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(cardContext),
      );
    }

    final expectedTimeRange =
        '${timeLabel(scheduleStartMinutes)}-${timeLabel(scheduleEndMinutes)}';
    expect(
      find.textContaining(canUseToday ? '오늘' : '다음 훈련'),
      findsWidgets,
    );
    expect(find.textContaining(expectedTimeRange), findsOneWidget);

    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(find.text('클럽 일정'), findsWidgets);

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
      sectionTop('home-layout-club-schedule-section'),
      lessThan(sectionTop('home-layout-level-section')),
    );
    expect(
      sectionTop('home-layout-level-section'),
      lessThan(sectionTop('home-layout-daily-flow-section')),
    );
    expect(find.text('홈화면 변경'), findsOneWidget);
    final titleRect = tester.getRect(
      find.byKey(const ValueKey<String>('home-title-label')),
    );
    final layoutButtonRect = tester.getRect(
      find.byKey(const ValueKey<String>('home-section-settings-button')),
    );
    expect(layoutButtonRect.left - titleRect.right, closeTo(8, 0.1));
    final titleSectionRect = tester.getRect(
      find.byKey(const ValueKey<String>('home-layout-title-section')),
    );
    final weatherButtonRect = tester.getRect(
      find.byKey(const ValueKey<String>('home-weather-button')),
    );
    expect(titleSectionRect.right - weatherButtonRect.right, closeTo(0, 0.1));

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
    expect(
      find.byKey(
        const ValueKey<String>('home-section-drag-area-club_schedule'),
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('섹션 이동'), findsNothing);
    final levelSurfaceFinder = find.byKey(
      const ValueKey<String>('home-section-setting-surface-level'),
    );
    double levelSurfaceBorderWidth() {
      final surface = tester.widget<AnimatedContainer>(levelSurfaceFinder);
      final decoration = surface.decoration! as BoxDecoration;
      return (decoration.border! as Border).top.width;
    }

    expect(levelSurfaceBorderWidth(), 1);
    final pressGesture = await tester.startGesture(
      tester.getCenter(
        find.byKey(const ValueKey<String>('home-section-drag-handle-level')),
      ),
    );
    await tester.pump();
    expect(levelSurfaceBorderWidth(), greaterThan(1));
    await pressGesture.up();
    await tester.pump();
    expect(levelSurfaceBorderWidth(), 1);

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
    expect(
      find.byKey(const ValueKey('tab-coach-mark-screen-overlay')),
      findsOneWidget,
    );
    expect(
        find.byKey(const ValueKey<String>('home-title-label')), findsOneWidget);
    expect(find.text('3단계 중 1단계'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tab-coach-mark-highlight')),
      findsOneWidget,
    );
    final firstTargetRect = tester.getRect(
      find.byKey(const ValueKey<String>('home-daily-flow-log-action')),
    );
    final firstHighlightRect = tester.getRect(
      find.byKey(const ValueKey('tab-coach-mark-highlight')),
    );
    final firstPanelRect = tester.getRect(
      find.byKey(const ValueKey('tab-coach-mark-explanation-panel')),
    );
    expect(
      (firstHighlightRect.center - firstTargetRect.center).distance,
      lessThan(1),
    );
    expect(firstHighlightRect.overlaps(firstPanelRect), isFalse);
    expect(
      optionRepository.getValue<bool>('tab_quick_guide_seen_v1_0'),
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('tab-coach-mark-next-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));

    expect(find.text('3단계 중 2단계'), findsOneWidget);
    final secondTargetRect = tester.getRect(
      find.byKey(const ValueKey<String>('home-daily-flow-meal-action')),
    );
    final secondHighlightRect = tester.getRect(
      find.byKey(const ValueKey('tab-coach-mark-highlight')),
    );
    final secondPanelRect = tester.getRect(
      find.byKey(const ValueKey('tab-coach-mark-explanation-panel')),
    );
    expect(
      (secondHighlightRect.center - secondTargetRect.center).distance,
      lessThan(1),
    );
    expect(secondHighlightRect.overlaps(secondPanelRect), isFalse);
    expect(
      find.byKey(const ValueKey('tab-coach-mark-try-button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('tab-coach-mark-next-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));

    expect(find.text('3단계 중 3단계'), findsOneWidget);
    final thirdHighlightRect = tester.getRect(
      find.byKey(const ValueKey('tab-coach-mark-highlight')),
    );
    final thirdPanelRect = tester.getRect(
      find.byKey(const ValueKey('tab-coach-mark-explanation-panel')),
    );
    expect(thirdHighlightRect.overlaps(thirdPanelRect), isFalse);

    await tester.tap(find.byKey(const ValueKey('tab-coach-mark-back-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));

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
        find.byKey(const ValueKey<String>('home-quick-actions-card')),
        findsOneWidget,
      );
      expect(
        tester.widget(
          find.byKey(const ValueKey<String>('home-quick-actions-card')),
        ),
        isA<WatchCartCard>(),
      );
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

    final quickPlanButton = find.byKey(
      const ValueKey<String>('home-quick-action-plan'),
    );
    await tester.ensureVisible(quickPlanButton);
    await tester.pump();
    await tester.tap(quickPlanButton);
    await tester.pump();
    await tester.pumpAndSettle();

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

    final matchHubShortcut = find.byTooltip('팀·시합 관리');
    expect(matchHubShortcut, findsWidgets);

    final quickMatchButton = find.byKey(
      const ValueKey<String>('home-quick-action-match'),
    );
    await tester.ensureVisible(quickMatchButton);
    await tester.pump();
    await tester.tap(quickMatchButton);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('시합 등록'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'personal sport hides team management shortcut but keeps match record',
    (WidgetTester tester) async {
      final optionRepository = _MemoryOptionRepository();
      await optionRepository.setValue(
        SportCatalog.currentSportOptionKey,
        SportCatalog.tennisId,
      );
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

      expect(find.byTooltip('팀·시합 관리'), findsNothing);

      final quickMatchButton = find.byKey(
        const ValueKey<String>('home-quick-action-match'),
      );
      await tester.ensureVisible(quickMatchButton);
      await tester.pump();
      await tester.tap(quickMatchButton);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('시합 등록'), findsOneWidget);
      expect(find.text('팀 관리'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

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
