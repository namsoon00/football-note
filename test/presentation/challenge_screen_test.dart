import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/challenge_service.dart';
import 'package:football_note/application/family_access_service.dart';
import 'package:football_note/application/locale_service.dart';
import 'package:football_note/application/meal_log_service.dart';
import 'package:football_note/application/settings_service.dart';
import 'package:football_note/application/training_service.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/repositories/training_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/challenge_screen.dart';
import 'package:football_note/presentation/screens/entry_form_screen.dart';

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

    await tester.tap(
      find.byKey(const ValueKey('challenge-template-starter_3')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('2. 미션 선택'), findsOneWidget);
    expect(find.text('훈련 프로그램 편집'), findsOneWidget);
    expect(find.text('미션별 목표량'), findsOneWidget);
    expect(find.text('3. 시작 준비'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '챌린지 시작'), findsOneWidget);
    expect(find.text('라운드'), findsNothing);
    final defaultProgramChip = find.widgetWithText(FilterChip, '기본기');
    expect(defaultProgramChip, findsOneWidget);
    expect(tester.widget<FilterChip>(defaultProgramChip).selected, isFalse);
    await tester.ensureVisible(defaultProgramChip);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(defaultProgramChip);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.widget<FilterChip>(defaultProgramChip).selected, isTrue);
    expect(
      tester
          .widgetList<ChoiceChip>(find.widgetWithText(ChoiceChip, '30분'))
          .any((chip) => chip.selected),
      isTrue,
    );

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
    expect(find.text('훈련 프로그램 편집'), findsNothing);
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

  testWidgets('parent mode keeps challenge screen view only', (
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

    expect(find.text('챌린지는 읽기 전용이에요.'), findsOneWidget);
    expect(find.text('챌린지 포기'), findsNothing);
    expect(find.text('훈련 프로그램 편집'), findsNothing);
    expect(find.byKey(const ValueKey('challenge-rounds-calendar')),
        findsOneWidget);
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

  testWidgets('parent mode cannot start a new challenge', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    await optionRepository.setValue(
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.parent.name,
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

    expect(find.text('챌린지는 읽기 전용이에요.'), findsOneWidget);
    expect(find.text('1. 기간 선택'), findsNothing);
    expect(find.widgetWithText(FilledButton, '챌린지 시작'), findsNothing);
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

  final size = tester.getSize(
    find.byKey(const ValueKey('challenge-calendar-round-1')),
  );
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await mealLogService.dispose();
  return size;
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
