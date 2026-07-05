import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/backup_service.dart';
import 'package:football_note/application/challenge_service.dart';
import 'package:football_note/application/family_access_service.dart';
import 'package:football_note/application/locale_service.dart';
import 'package:football_note/application/meal_log_service.dart';
import 'package:football_note/application/player_level_service.dart';
import 'package:football_note/application/settings_service.dart';
import 'package:football_note/application/training_service.dart';
import 'package:football_note/domain/entities/challenge.dart';
import 'package:football_note/domain/entities/sport_definition.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/domain/repositories/backup_repository.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/repositories/training_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/challenge_screen.dart';
import 'package:football_note/presentation/screens/entry_form_screen.dart';

void main() {
  testWidgets('challenge screen prepares then starts a template', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.view.devicePixelRatio = 1;
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetDevicePixelRatio();
    });
    final optionRepository = _MemoryOptionRepository();
    final challengeService = ChallengeService(optionRepository);
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

    expect(find.text('챌린지 만들기'), findsOneWidget);
    expect(find.text('1. 기간 선택'), findsNothing);
    expect(find.text('3일 챌린지'), findsNothing);
    expect(find.text('2. 미션 선택'), findsNothing);
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

    await tester.tap(find.byKey(const ValueKey('challenge-create-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('1. 기간 선택'), findsOneWidget);
    expect(find.text('3일 챌린지'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('challenge-template-starter_3')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('진행 간격'), findsOneWidget);
    expect(find.text('이틀에 한 번'), findsOneWidget);
    expect(find.text('2. 미션 선택'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('challenge-add-training-program-button')),
      findsOneWidget,
    );
    expect(find.text('미션별 목표량'), findsOneWidget);
    expect(find.text('3. 준비 저장'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '챌린지 준비'), findsOneWidget);
    expect(find.text('라운드'), findsNothing);
    final defaultProgramChip = find.widgetWithText(FilterChip, '기본기');
    expect(defaultProgramChip, findsOneWidget);
    expect(tester.widget<FilterChip>(defaultProgramChip).selected, isTrue);
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, '줄넘기'))
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, '리프팅'))
          .selected,
      isFalse,
    );
    expect(
      tester.widget<FilterChip>(find.widgetWithText(FilterChip, '식사')).selected,
      isFalse,
    );
    await tester.ensureVisible(defaultProgramChip);
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester
          .widgetList<ChoiceChip>(find.widgetWithText(ChoiceChip, '30분'))
          .any((chip) => chip.selected),
      isTrue,
    );

    await tester.ensureVisible(find.widgetWithText(FilledButton, '챌린지 준비'));
    await tester.pump(const Duration(milliseconds: 300));
    final prepareButton = find.widgetWithText(FilledButton, '챌린지 준비');
    await tester.tap(prepareButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final prepareSnackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(prepareSnackBar.behavior, SnackBarBehavior.floating);
    final prepareSnackBarMargin =
        prepareSnackBar.margin! as EdgeInsetsDirectional;
    expect(prepareSnackBarMargin.bottom, greaterThan(100));
    await tester.pump(const Duration(seconds: 1));

    expect(challengeService.activeRun()?.isStarted, isFalse);
    expect(find.byKey(const ValueKey('challenge-ready-card')), findsOneWidget);
    expect(find.text('3일 챌린지 준비 완료'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '지금 시작'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('challenge-rounds-calendar')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('challenge-start-prepared-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(challengeService.activeRun()?.isStarted, isTrue);
    expect(
      find.byKey(const ValueKey('challenge-rounds-calendar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('challenge-calendar-round-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('challenge-current-round-status-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('challenge-current-round-cute-marker-1')),
      findsOneWidget,
    );
    expect(find.text('줄넘기'), findsAtLeastNWidgets(1));
    expect(find.text('리프팅'), findsNothing);
    expect(find.text('훈련 프로그램 편집'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await mealLogService.dispose();
  });

  testWidgets('completed challenge encourages starting the next challenge', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.view.devicePixelRatio = 1;
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetDevicePixelRatio();
    });
    final optionRepository = _MemoryOptionRepository();
    final challengeService = ChallengeService(optionRepository);
    final template = challengeService.templateById('starter_3')!;
    final run = await challengeService.startChallenge(
      template,
      selectedSkillIds: const <String>['passing'],
      missionTargets: const ChallengeMissionTargets(
        trainingMinutes: 1,
        jumpRopeMinutes: 0,
        liftingMinutes: 0,
        riceBowls: 0,
      ),
      startedAt: DateTime(2026, 6, 1, 9),
    );
    await challengeService.completeRun(
      run.id,
      completedAt: DateTime(2026, 6, 3, 18),
      completedRoundNumbers: const <int>[1, 2, 3],
    );
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

    expect(
      find.byKey(const ValueKey('challenge-finished-praise-card')),
      findsOneWidget,
    );
    expect(find.text('끝까지 해낸 챌린지예요'), findsOneWidget);
    expect(
      find.text('3일 챌린지에서 3라운드를 모두 완주했어요. 이 꾸준함을 다음 챌린지로 이어가 볼까요?'),
      findsOneWidget,
    );
    expect(find.text('아래에서 다음 챌린지를 선택해요'), findsOneWidget);
    expect(find.text('1. 기간 선택'), findsNothing);
    expect(find.text('챌린지 만들기'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('challenge-create-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('1. 기간 선택'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('challenge-template-weekly_7')),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(
      find.byKey(const ValueKey('challenge-template-weekly_7')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('2. 미션 선택'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '챌린지 준비'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await mealLogService.dispose();
  });

  testWidgets('challenge screen shows multiple active challenges', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 720));
    tester.view.devicePixelRatio = 1;
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetDevicePixelRatio();
    });
    final optionRepository = _MemoryOptionRepository();
    final challengeService = ChallengeService(optionRepository);
    final starter = challengeService.templateById('starter_3')!;
    final weekly = challengeService.templateById('weekly_7')!;
    final today = DateTime.now();
    final starterRun = await challengeService.startChallenge(
      starter,
      startedAt: DateTime(today.year, today.month, today.day, 9),
    );
    final weeklyRun = await challengeService.prepareChallenge(
      weekly,
      preparedAt: DateTime(today.year, today.month, today.day, 10),
      cadenceDays: 2,
    );
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
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('활성 챌린지'), findsAtLeastNWidgets(1));
    expect(find.text('7일 챌린지'), findsOneWidget);
    expect(find.text('3일 챌린지'), findsOneWidget);
    expect(
      find.byKey(ValueKey('challenge-list-card-${weeklyRun.id}')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('challenge-list-card-${starterRun.id}')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('challenge-current-round-cute-marker-1')),
      findsNothing,
    );

    await tester
        .tap(find.byKey(ValueKey('challenge-list-card-${weeklyRun.id}')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('챌린지 상세'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('challenge-rounds-calendar')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('challenge-ready-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('challenge-edit-button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('challenge-edit-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('챌린지 수정'), findsAtLeastNWidgets(1));
    expect(find.widgetWithText(FilledButton, '수정 저장'), findsOneWidget);
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, '일주일에 한 번'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(ChoiceChip, '일주일에 한 번'));
    await tester.pump();
    await tester.ensureVisible(find.widgetWithText(FilledButton, '수정 저장'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(FilledButton, '수정 저장'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      challengeService
          .activeRuns()
          .firstWhere((run) => run.id == weeklyRun.id)
          .cadenceDays,
      7,
    );
    expect(find.text('챌린지 상세'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('challenge-ready-card')),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('활성 챌린지'), findsAtLeastNWidgets(1));

    await tester.tap(find.byKey(const ValueKey('challenge-create-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('1. 기간 선택'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await mealLogService.dispose();
  });

  testWidgets('challenge screen uses sport-specific conditioning missions', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.view.devicePixelRatio = 1;
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetDevicePixelRatio();
    });
    final optionRepository = _MemoryOptionRepository();
    await optionRepository.setValue(
      SportCatalog.currentSportOptionKey,
      SportCatalog.baseballId,
    );
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

    await tester.tap(find.byKey(const ValueKey('challenge-create-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const ValueKey('challenge-template-starter_3')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final sprintChip = find.widgetWithText(FilterChip, '스프린트');
    final catchPlayChip = find.widgetWithText(FilterChip, '캐치볼');
    expect(sprintChip, findsOneWidget);
    expect(catchPlayChip, findsOneWidget);
    expect(tester.widget<FilterChip>(sprintChip).selected, isTrue);
    expect(tester.widget<FilterChip>(catchPlayChip).selected, isFalse);
    expect(find.text('줄넘기'), findsNothing);
    expect(find.text('리프팅'), findsNothing);
    expect(find.text('스프린트'), findsAtLeastNWidgets(1));
    expect(find.text('캐치볼'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await mealLogService.dispose();
  });

  testWidgets('round calendar uses seven-day card sizing for every template', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.view.devicePixelRatio = 1;
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetDevicePixelRatio();
    });

    final starterSize = await _pumpActiveChallengeRoundCard(
      tester,
      templateId: 'starter_3',
    );
    final weeklySize = await _pumpActiveChallengeRoundCard(
      tester,
      templateId: 'weekly_7',
    );
    final focusSize = await _pumpActiveChallengeRoundCard(
      tester,
      templateId: 'focus_14',
    );

    expect(starterSize.width, moreOrLessEquals(weeklySize.width));
    expect(starterSize.height, moreOrLessEquals(weeklySize.height));
    expect(focusSize.width, moreOrLessEquals(weeklySize.width));
    expect(focusSize.height, moreOrLessEquals(weeklySize.height));
  });

  testWidgets('missed calendar rounds hide round labels', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.view.devicePixelRatio = 1;
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetDevicePixelRatio();
    });
    final optionRepository = _MemoryOptionRepository();
    final challengeService = ChallengeService(optionRepository);
    final template = challengeService.templateById('starter_3')!;
    final today = DateTime.now();
    await challengeService.startChallenge(
      template,
      startedAt: DateTime(today.year, today.month, today.day - 2, 9),
    );
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
    await tester.pump(const Duration(milliseconds: 300));

    await _openChallengeDetailByTitle(tester, '3일 챌린지');

    expect(find.text('R1'), findsNothing);
    expect(find.text('R2'), findsNothing);
    expect(find.text('R3'), findsNothing);
    expect(
      find.byKey(const ValueKey('challenge-calendar-round-3')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await mealLogService.dispose();
  });

  testWidgets('parent mode keeps mission records view only', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.view.devicePixelRatio = 1;
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetDevicePixelRatio();
    });
    final optionRepository = _MemoryOptionRepository();
    await optionRepository.setValue(
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.parent.name,
    );
    final challengeService = ChallengeService(optionRepository);
    final template = challengeService.templateById('starter_3')!;
    await challengeService.startChallenge(
      template,
      startedAt: DateTime(2099, 1, 1, 9),
    );
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
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('보호자가 챌린지를 만들 수 있어요.'), findsOneWidget);
    expect(find.text('챌린지 포기'), findsNothing);
    expect(find.text('훈련 프로그램 편집'), findsNothing);
    expect(
      find.byKey(const ValueKey('challenge-rounds-calendar')),
      findsNothing,
    );

    await _openChallengeDetailByTitle(tester, '3일 챌린지');

    expect(find.text('보호자가 챌린지를 만들 수 있어요.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('challenge-rounds-calendar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('challenge-edit-button')),
      findsNothing,
    );
    expect(find.text('줄넘기'), findsAtLeastNWidgets(1));

    await tester.tap(find.text('줄넘기').first, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(EntryFormScreen), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await mealLogService.dispose();
  });

  testWidgets('parent mode can prepare a new challenge with a gift reward', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 720));
    tester.view.devicePixelRatio = 1;
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetDevicePixelRatio();
    });
    final optionRepository = _MemoryOptionRepository();
    await optionRepository.setValue(
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.parent.name,
    );
    final challengeService = ChallengeService(optionRepository);
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
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('보호자가 챌린지를 만들 수 있어요.'), findsOneWidget);
    expect(find.text('1. 기간 선택'), findsNothing);
    expect(find.widgetWithText(FilledButton, '챌린지 준비'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('challenge-create-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const ValueKey('challenge-template-starter_3')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('선물 보상'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('challenge-reward-gift-input')),
      '새 축구공',
    );
    await tester.pump();

    await tester.ensureVisible(find.widgetWithText(FilledButton, '챌린지 준비'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(FilledButton, '챌린지 준비'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(challengeService.activeRun()?.rewardGift, '새 축구공');
    expect(challengeService.activeRun()?.isStarted, isFalse);
    expect(find.text('완주하면 새 축구공 선물이 기다려요.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('challenge-ready-card')),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, '지금 시작'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await mealLogService.dispose();
  });

  testWidgets('parent challenge prepare does not wait for shared backup sync', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 720));
    tester.view.devicePixelRatio = 1;
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetDevicePixelRatio();
    });
    final optionRepository = _MemoryOptionRepository();
    await optionRepository.setValue(
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.parent.name,
    );
    final challengeService = ChallengeService(optionRepository);
    final trainingService = TrainingService(_MemoryTrainingRepository());
    final mealLogService = MealLogService(optionRepository);
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final backupRepository = _SlowBackupRepository();

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
          driveBackupService: BackupService(backupRepository),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const ValueKey('challenge-create-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester
        .tap(find.byKey(const ValueKey('challenge-template-starter_3')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.ensureVisible(find.widgetWithText(FilledButton, '챌린지 준비'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(FilledButton, '챌린지 준비'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(challengeService.activeRun(), isNotNull);
    expect(challengeService.activeRun()?.isStarted, isFalse);
    expect(backupRepository.backupRequested, isTrue);
    expect(
      find.byKey(const ValueKey('challenge-ready-card')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    backupRepository.completeBackup();
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await mealLogService.dispose();
  });

  testWidgets('parent challenge prepare ignores repeated taps while saving', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 720));
    tester.view.devicePixelRatio = 1;
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetDevicePixelRatio();
    });
    final optionRepository = _SlowChallengeSaveOptionRepository();
    await optionRepository.setValue(
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.parent.name,
    );
    final challengeService = ChallengeService(optionRepository);
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
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const ValueKey('challenge-create-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester
        .tap(find.byKey(const ValueKey('challenge-template-starter_3')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final prepareButton = find.widgetWithText(FilledButton, '챌린지 준비');
    await tester.ensureVisible(prepareButton);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(prepareButton);
    await tester.tap(prepareButton);
    await tester.pump();

    expect(optionRepository.challengeSaveCount, 1);
    expect(challengeService.activeRuns(), isEmpty);
    expect(tester.widget<FilledButton>(prepareButton).onPressed, isNull);

    optionRepository.releaseChallengeSave();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(challengeService.activeRuns(), hasLength(1));
    expect(challengeService.activeRun()?.isStarted, isFalse);
    expect(
      find.byKey(const ValueKey('challenge-ready-card')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await mealLogService.dispose();
  });

  testWidgets('parent mode can delete a challenge before player records', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 720));
    tester.view.devicePixelRatio = 1;
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetDevicePixelRatio();
    });
    final optionRepository = _MemoryOptionRepository();
    await optionRepository.setValue(
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.parent.name,
    );
    final challengeService = ChallengeService(optionRepository);
    final template = challengeService.templateById('starter_3')!;
    await challengeService.prepareChallenge(template);
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
    await tester.pump(const Duration(milliseconds: 300));

    await _openChallengeDetailByTitle(tester, '3일 챌린지');
    expect(
      find.byKey(const ValueKey('challenge-delete-pending-button')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('challenge-delete-pending-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('챌린지 삭제'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '삭제'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(challengeService.activeRuns(), isEmpty);
    expect(find.text('챌린지 만들기'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('challenge-rounds-calendar')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await mealLogService.dispose();
  });

  testWidgets(
    'parent mode keeps delete and edit hidden after player records progress',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 720));
      tester.view.devicePixelRatio = 1;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetDevicePixelRatio();
      });
      final optionRepository = _MemoryOptionRepository();
      await optionRepository.setValue(
        FamilyAccessService.currentRoleLocalKey,
        FamilyRole.parent.name,
      );
      final challengeService = ChallengeService(optionRepository);
      final template = challengeService.templateById('starter_3')!;
      final today = DateTime.now();
      await challengeService.startChallenge(
        template,
        selectedSkillIds: const <String>['passing'],
        missionTargets: const ChallengeMissionTargets(
          trainingMinutes: 30,
          jumpRopeMinutes: 0,
          liftingMinutes: 0,
          riceBowls: 0,
        ),
        startedAt: DateTime(today.year, today.month, today.day, 9),
      );
      final trainingRepository = _MemoryTrainingRepository();
      await trainingRepository.add(
        _trainingEntry(
          day: DateTime(today.year, today.month, today.day, 17),
          minutes: 5,
        ),
      );
      final trainingService = TrainingService(trainingRepository);
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
      await tester.pump(const Duration(milliseconds: 300));

      await _openChallengeDetailByTitle(tester, '3일 챌린지');

      expect(
        find.byKey(const ValueKey('challenge-delete-pending-button')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('challenge-edit-button')), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await mealLogService.dispose();
    },
  );

  testWidgets('challenge edit save is blocked after challenge starts', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 720));
    tester.view.devicePixelRatio = 1;
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetDevicePixelRatio();
    });
    final optionRepository = _MemoryOptionRepository();
    await optionRepository.setValue(
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.parent.name,
    );
    final challengeService = ChallengeService(optionRepository);
    final template = challengeService.templateById('starter_3')!;
    final today = DateTime.now();
    final run = await challengeService.prepareChallenge(
      template,
      selectedSkillIds: const <String>['passing'],
      missionTargets: const ChallengeMissionTargets(
        trainingMinutes: 30,
        jumpRopeMinutes: 0,
        liftingMinutes: 0,
        riceBowls: 0,
      ),
      rewardGift: '새 축구공',
      preparedAt: DateTime(today.year, today.month, today.day, 9),
    );
    final trainingRepository = _MemoryTrainingRepository();
    final trainingService = TrainingService(trainingRepository);
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
    await tester.pump(const Duration(milliseconds: 300));

    await _openChallengeDetailByTitle(tester, '3일 챌린지');
    await tester.tap(find.byKey(const ValueKey('challenge-edit-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('챌린지 수정'), findsAtLeastNWidgets(1));

    await tester.enterText(
      find.byKey(const ValueKey('challenge-reward-gift-input')),
      '새 풋살화',
    );
    await tester.pump();
    await challengeService.startPreparedRun(
      run.id,
      startedAt: DateTime(today.year, today.month, today.day, 10),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.ensureVisible(find.widgetWithText(FilledButton, '수정 저장'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(FilledButton, '수정 저장'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(challengeService.activeRun()?.rewardGift, '새 축구공');
    expect(find.text('이미 기록이 시작된 챌린지는 수정할 수 없어요.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('challenge-rounds-calendar')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await mealLogService.dispose();
  });

  testWidgets('mission completion after record return shows celebration', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.view.devicePixelRatio = 1;
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetDevicePixelRatio();
    });
    final optionRepository = _MemoryOptionRepository();
    final challengeService = ChallengeService(optionRepository);
    final template = challengeService.templateById('starter_3')!;
    final today = DateTime.now();
    await challengeService.startChallenge(
      template,
      selectedSkillIds: const <String>['passing'],
      missionTargets: const ChallengeMissionTargets(
        trainingMinutes: 1,
        jumpRopeMinutes: 0,
        liftingMinutes: 0,
        riceBowls: 0,
      ),
      startedAt: DateTime(today.year, today.month, today.day, 9),
    );
    final trainingRepository = _MemoryTrainingRepository();
    final trainingService = TrainingService(trainingRepository);
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
    await tester.pump(const Duration(milliseconds: 300));

    await _openChallengeDetailByTitle(tester, '3일 챌린지');

    await tester.tap(find.byKey(const ValueKey('challenge-mission-training')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(EntryFormScreen), findsOneWidget);

    await trainingService.add(
      _trainingEntry(day: DateTime.now(), minutes: 1, program: '패스'),
    );
    final challengeDay = normalizeDay(DateTime.now());
    final updatedProgress = challengeService.activeProgress(
      trainingEntries: await trainingService.entriesInRange(
        challengeDay,
        challengeDay.add(const Duration(days: 3)),
      ),
      mealEntries: const [],
    );
    expect(updatedProgress?.completedRoundCount, 1);
    Navigator.of(tester.element(find.byType(EntryFormScreen))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 1));

    expect(PlayerLevelService(optionRepository).loadState().totalXp, 10);
    expect(find.text('미션 완료!'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await mealLogService.dispose();
  });

  testWidgets('completed gift challenge shows Rinzy gift receive screen', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    tester.view.devicePixelRatio = 1;
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetDevicePixelRatio();
    });
    final optionRepository = _MemoryOptionRepository();
    final challengeService = ChallengeService(optionRepository);
    final template = challengeService.templateById('starter_3')!;
    final today = normalizeDay(DateTime.now());
    final startDay = today.subtract(const Duration(days: 2));
    await challengeService.startChallenge(
      template,
      selectedSkillIds: const <String>['passing'],
      missionTargets: const ChallengeMissionTargets(
        trainingMinutes: 1,
        jumpRopeMinutes: 0,
        liftingMinutes: 0,
        riceBowls: 0,
      ),
      rewardGift: '새 축구공',
      startedAt: startDay.add(const Duration(hours: 9)),
    );
    final trainingRepository = _MemoryTrainingRepository();
    final trainingService = TrainingService(trainingRepository);
    await trainingService.add(
      _trainingEntry(day: startDay, minutes: 1, program: '패스'),
    );
    await trainingService.add(
      _trainingEntry(
        day: startDay.add(const Duration(days: 1)),
        minutes: 1,
        program: '패스',
      ),
    );
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
    await tester.pump(const Duration(milliseconds: 300));

    await _openChallengeDetailByTitle(tester, '3일 챌린지');
    final trainingMission =
        find.byKey(const ValueKey('challenge-mission-training'));
    await tester.ensureVisible(trainingMission);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(trainingMission);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(EntryFormScreen), findsOneWidget);

    await trainingService.add(
      _trainingEntry(day: today, minutes: 1, program: '패스'),
    );
    Navigator.of(tester.element(find.byType(EntryFormScreen))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('린지가 선물을 가져왔어요!'), findsOneWidget);
    expect(
      find.text('새 축구공 선물을 받을 시간이에요. 끝까지 해낸 약속을 린지가 축하하고 있어요.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, '선물 받았어요'), findsOneWidget);
    expect(find.byIcon(Icons.card_giftcard_rounded), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await mealLogService.dispose();
  });

  testWidgets(
      'record return shows completion screen after reward is already synced', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.view.devicePixelRatio = 1;
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetDevicePixelRatio();
    });
    final optionRepository = _MemoryOptionRepository();
    final challengeService = ChallengeService(optionRepository);
    final template = challengeService.templateById('starter_3')!;
    final today = DateTime.now();
    await challengeService.startChallenge(
      template,
      selectedSkillIds: const <String>['passing'],
      missionTargets: const ChallengeMissionTargets(
        trainingMinutes: 1,
        jumpRopeMinutes: 0,
        liftingMinutes: 0,
        riceBowls: 0,
      ),
      startedAt: DateTime(today.year, today.month, today.day, 9),
    );
    final trainingRepository = _MemoryTrainingRepository();
    final trainingService = TrainingService(trainingRepository);
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
    await tester.pump(const Duration(milliseconds: 300));

    await _openChallengeDetailByTitle(tester, '3일 챌린지');

    await tester.tap(find.byKey(const ValueKey('challenge-mission-training')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(EntryFormScreen), findsOneWidget);

    await trainingService.add(
      _trainingEntry(day: DateTime.now(), minutes: 1, program: '패스'),
    );
    final challengeDay = normalizeDay(DateTime.now());
    final updatedProgress = challengeService.activeProgress(
      trainingEntries: await trainingService.entriesInRange(
        challengeDay,
        challengeDay.add(const Duration(days: 3)),
      ),
      mealEntries: const [],
    );
    expect(updatedProgress?.completedRoundCount, 1);
    await challengeService.awardCompletedRounds(
      progress: updatedProgress!,
      playerLevelService: PlayerLevelService(optionRepository),
    );
    expect(PlayerLevelService(optionRepository).loadState().totalXp, 10);

    Navigator.of(tester.element(find.byType(EntryFormScreen))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 1));

    expect(PlayerLevelService(optionRepository).loadState().totalXp, 10);
    expect(find.text('미션 완료!'), findsOneWidget);
    expect(find.text('라운드 미션을 완료했어요. 기록을 확인하세요.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await mealLogService.dispose();
  });

  testWidgets('opening challenge page does not show completion screen', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.view.devicePixelRatio = 1;
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetDevicePixelRatio();
    });
    final optionRepository = _MemoryOptionRepository();
    final challengeService = ChallengeService(optionRepository);
    final template = challengeService.templateById('starter_3')!;
    final today = DateTime.now();
    await challengeService.startChallenge(
      template,
      selectedSkillIds: const <String>['passing'],
      missionTargets: const ChallengeMissionTargets(
        trainingMinutes: 1,
        jumpRopeMinutes: 0,
        liftingMinutes: 0,
        riceBowls: 0,
      ),
      startedAt: DateTime(today.year, today.month, today.day, 9),
    );
    final trainingRepository = _MemoryTrainingRepository();
    final trainingService = TrainingService(trainingRepository);
    await trainingService.add(
      _trainingEntry(day: DateTime.now(), minutes: 1, program: '패스'),
    );
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
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('미션 완료!'), findsNothing);
    expect(
      find.byKey(const ValueKey('challenge-rounds-calendar')),
      findsNothing,
    );
    expect(find.text('활성 챌린지'), findsAtLeastNWidgets(1));
    expect(find.text('3일 챌린지'), findsOneWidget);
    expect(PlayerLevelService(optionRepository).loadState().totalXp, 10);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await mealLogService.dispose();
  });
}

Future<Size> _pumpActiveChallengeRoundCard(
  WidgetTester tester, {
  required String templateId,
}) async {
  final optionRepository = _MemoryOptionRepository();
  final challengeService = ChallengeService(optionRepository);
  final template = challengeService.templateById(templateId)!;
  await challengeService.startChallenge(
    template,
    startedAt: DateTime(2099, 1, 1, 9),
  );
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
  await tester.pump(const Duration(milliseconds: 300));

  await _openChallengeDetailByTitle(
    tester,
    _challengeTemplateTitleForTest(templateId),
  );

  final size = tester.getSize(
    find.byKey(const ValueKey('challenge-calendar-round-1')),
  );
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await mealLogService.dispose();
  return size;
}

Future<void> _openChallengeDetailByTitle(
  WidgetTester tester,
  String title,
) async {
  await tester.tap(find.text(title).first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

String _challengeTemplateTitleForTest(String templateId) {
  return switch (templateId) {
    'starter_3' => '3일 챌린지',
    'weekly_7' => '7일 챌린지',
    'focus_14' => '14일 챌린지',
    _ => '챌린지',
  };
}

TrainingEntry _trainingEntry({
  required DateTime day,
  required int minutes,
  String program = '패스',
}) {
  return TrainingEntry(
    date: day,
    durationMinutes: minutes,
    intensity: 3,
    type: program,
    mood: 3,
    injury: false,
    notes: '',
    location: '운동장',
    program: program,
  );
}

class _SlowBackupRepository implements BackupRepository {
  final Completer<bool> _backupCompleter = Completer<bool>();
  bool backupRequested = false;

  void completeBackup() {
    if (!_backupCompleter.isCompleted) {
      _backupCompleter.complete(true);
    }
  }

  @override
  Future<void> autoBackupDaily() async {}

  @override
  Future<void> backup() async {}

  @override
  Future<bool> backupIfSignedIn({bool requireAutoOnSave = false}) {
    backupRequested = true;
    return _backupCompleter.future;
  }

  @override
  DateTime? getLastBackup() => null;

  @override
  bool isAutoDailyEnabled() => false;

  @override
  bool isAutoOnSaveEnabled() => false;

  @override
  Future<void> restoreLatest() async {}

  @override
  Future<void> setAutoDailyEnabled(bool value) async {}

  @override
  Future<void> setAutoOnSaveEnabled(bool value) async {}
}

class _SlowChallengeSaveOptionRepository extends _MemoryOptionRepository {
  final Completer<void> _challengeSaveCompleter = Completer<void>();
  int challengeSaveCount = 0;

  void releaseChallengeSave() {
    if (!_challengeSaveCompleter.isCompleted) {
      _challengeSaveCompleter.complete();
    }
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    if (key == ChallengeService.storageKey) {
      challengeSaveCount += 1;
      await _challengeSaveCompleter.future;
    }
    await super.setValue(key, value);
  }
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    if (value is List<String>) return value;
    return List<String>.from(defaults);
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    if (value is List<int>) return value;
    return List<int>.from(defaults);
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
