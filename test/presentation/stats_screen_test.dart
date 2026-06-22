import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:football_note/application/family_access_service.dart';
import 'package:football_note/application/meal_log_service.dart';
import 'package:football_note/domain/entities/meal_entry.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/repositories/training_repository.dart';
import 'package:football_note/application/player_profile_service.dart';
import 'package:football_note/application/training_service.dart';
import 'package:football_note/domain/entities/sport_definition.dart';
import 'package:football_note/presentation/screens/stats_screen.dart';
import 'package:football_note/application/locale_service.dart';
import 'package:football_note/application/settings_service.dart';

import '../helpers/test_asset_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MemoryTrainingRepository trainingRepository;
  late TrainingService service;
  late MealLogService mealLogService;
  late LocaleService localeService;
  late SettingsService settingsService;
  late _MemoryOptionRepository optionRepository;

  setUp(() async {
    trainingRepository = _MemoryTrainingRepository();
    service = TrainingService(trainingRepository);
    optionRepository = _MemoryOptionRepository();
    mealLogService = MealLogService(optionRepository);
    localeService = LocaleService(optionRepository)..load();
    settingsService = SettingsService(optionRepository)..load();
    await _markBenchmarksFresh(optionRepository);
  });

  testWidgets('Stats screen shows summary after save', (
    WidgetTester tester,
  ) async {
    final entry = TrainingEntry(
      date: DateTime.now(),
      durationMinutes: 60,
      intensity: 3,
      type: '기술',
      mood: 3,
      injury: false,
      notes: '',
      location: '학교 운동장',
      heightCm: 150,
      weightKg: 42.5,
      isLesson: true,
    );
    await service.add(entry);

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
          home: StatsScreen(
            trainingService: service,
            mealLogService: mealLogService,
            localeService: localeService,
            onCreate: () {},
            optionRepository: optionRepository,
            settingsService: settingsService,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('최근 1주일'), findsOneWidget);
    expect(find.text('훈련'), findsOneWidget);
    expect(find.text('시합'), findsOneWidget);
    expect(find.text('기록 리듬'), findsOneWidget);
    expect(find.text('레슨 횟수'), findsOneWidget);
    expect(find.text('1회'), findsOneWidget);
    expect(find.text('축구 성장 요약'), findsOneWidget);
    expect(find.byTooltip('다이어리'), findsNothing);
  });

  testWidgets('Growth summary is visible in the stats panel', (
    WidgetTester tester,
  ) async {
    await service.add(
      TrainingEntry(
        date: DateTime.now(),
        durationMinutes: 45,
        intensity: 3,
        type: '드리블',
        mood: 3,
        injury: false,
        notes: '',
        location: '학교 운동장',
      ),
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
          home: StatsScreen(
            trainingService: service,
            mealLogService: mealLogService,
            localeService: localeService,
            onCreate: () {},
            optionRepository: optionRepository,
            settingsService: settingsService,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('축구 성장 요약'), findsOneWidget);
    expect(find.text('총 훈련 시간'), findsOneWidget);
    expect(find.text('기록 리듬'), findsOneWidget);
    expect(find.text('계획 실행률'), findsOneWidget);
    expect(find.text('집중 분야'), findsOneWidget);
  });

  testWidgets('Stats screen separates match records in match tab', (
    WidgetTester tester,
  ) async {
    await service.add(
      TrainingEntry(
        date: DateTime.now(),
        durationMinutes: 80,
        intensity: 3,
        type: '경기',
        mood: 3,
        injury: false,
        notes: '전반 압박 좋았음',
        location: '메인 구장',
        opponentTeam: '라이벌 FC',
        scoredGoals: 3,
        concededGoals: 1,
        playerGoals: 1,
        playerAssists: 1,
        minutesPlayed: 70,
      ),
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
          home: StatsScreen(
            trainingService: service,
            mealLogService: mealLogService,
            localeService: localeService,
            onCreate: () {},
            optionRepository: optionRepository,
            settingsService: settingsService,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('시합'));
    await tester.pumpAndSettle();

    expect(find.text('시합 요약'), findsOneWidget);
    expect(find.text('전체 시합 기록'), findsOneWidget);
    expect(find.textContaining('라이벌 FC'), findsOneWidget);
  });

  testWidgets('Stats screen counts tournament match records separately', (
    WidgetTester tester,
  ) async {
    await service.add(
      TrainingEntry(
        date: DateTime.now(),
        durationMinutes: 90,
        intensity: 4,
        type: '경기',
        mood: 4,
        injury: false,
        notes: '',
        location: '컵 경기장',
        opponentTeam: '컵 FC',
        scoredGoals: 2,
        concededGoals: 0,
        matchKind: 'tournament',
        matchCompetitionName: '봄 컵',
        matchStage: 'final',
        tournamentOutcome: 'champion',
        leagueTeamNames: const <String>['컵 FC', '블루 FC'],
        tournamentWins: 2,
      ),
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
          home: StatsScreen(
            trainingService: service,
            mealLogService: mealLogService,
            localeService: localeService,
            onCreate: () {},
            optionRepository: optionRepository,
            settingsService: settingsService,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('시합'));
    await tester.pumpAndSettle();

    expect(find.textContaining('친선 경기 0 · 리그 경기 0 · 토너먼트 1'), findsOneWidget);
    expect(find.textContaining('토너먼트 · 컵 FC'), findsOneWidget);
    expect(find.textContaining('봄 컵'), findsOneWidget);
    expect(find.textContaining('결승'), findsOneWidget);
    expect(find.textContaining('우승'), findsOneWidget);
    expect(find.textContaining('2승'), findsWidgets);
  });

  testWidgets('Parent mode stats shows training, match, and meal records', (
    WidgetTester tester,
  ) async {
    await optionRepository.setValue(
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.parent.name,
    );
    await service.add(
      TrainingEntry(
        date: DateTime.now(),
        durationMinutes: 50,
        intensity: 4,
        type: '드리블',
        mood: 4,
        injury: false,
        notes: '',
        location: '학교 운동장',
        jumpRopeCount: 120,
        jumpRopeMinutes: 8,
        jumpRopeEnabled: true,
        liftingByPart: const <String, int>{'하체': 30},
      ),
    );
    await service.add(
      TrainingEntry(
        date: DateTime.now(),
        durationMinutes: 70,
        intensity: 4,
        type: '경기',
        mood: 4,
        injury: false,
        notes: '',
        location: '메인 구장',
        opponentTeam: '상대 FC',
        scoredGoals: 2,
        concededGoals: 1,
      ),
    );
    await mealLogService.save(
      MealEntry(
        date: DateTime.now(),
        breakfastRiceBowls: 1,
        lunchRiceBowls: 1,
        dinnerRiceBowls: 1,
      ),
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
          home: StatsScreen(
            trainingService: service,
            mealLogService: mealLogService,
            localeService: localeService,
            onCreate: () {},
            optionRepository: optionRepository,
            settingsService: settingsService,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('축구 성장 요약'), findsOneWidget);
    expect(find.text('줄넘기 통계'), findsOneWidget);
    expect(find.text('식사 기록'), findsOneWidget);

    await tester.tap(find.text('시합'));
    await tester.pumpAndSettle();

    expect(find.text('시합 요약'), findsOneWidget);
    expect(find.text('전체 시합 기록'), findsOneWidget);
  });

  testWidgets('Stats screen applies provided initial range label', (
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
          home: StatsScreen(
            trainingService: service,
            mealLogService: mealLogService,
            localeService: localeService,
            onCreate: () {},
            optionRepository: optionRepository,
            settingsService: settingsService,
            initialRange: DateTimeRange(
              start: DateTime(2026, 3, 16),
              end: DateTime(2026, 3, 22),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3/16~3/22'), findsOneWidget);
  });

  testWidgets('Stats screen shows meal averages from standalone logs', (
    WidgetTester tester,
  ) async {
    await service.add(
      TrainingEntry(
        date: DateTime.now(),
        durationMinutes: 40,
        intensity: 3,
        type: '패스',
        mood: 3,
        injury: false,
        notes: '',
        location: '학교 운동장',
        weightKg: 44.2,
      ),
    );
    await mealLogService.save(
      MealEntry(
        date: DateTime.now(),
        breakfastRiceBowls: 1,
        lunchRiceBowls: 0.5,
        dinnerRiceBowls: 1,
      ),
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
          home: StatsScreen(
            trainingService: service,
            mealLogService: mealLogService,
            localeService: localeService,
            onCreate: () {},
            optionRepository: optionRepository,
            settingsService: settingsService,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('식사 기록'), findsOneWidget);
    expect(find.text('2.5공기'), findsOneWidget);
    expect(find.text('식사 흐름'), findsOneWidget);
    expect(find.text('최근 기록 공기밥'), findsNothing);
    expect(find.text('기록 일수'), findsOneWidget);
    expect(find.text('평균 실제'), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('아침'), findsWidgets);
    expect(find.text('점심'), findsWidgets);
    expect(find.text('저녁'), findsWidgets);
  });

  testWidgets('Stats screen adapts report labels for the selected sport', (
    WidgetTester tester,
  ) async {
    await optionRepository.setValue(
      SportCatalog.currentSportOptionKey,
      SportCatalog.basketballId,
    );
    final now = DateTime.now();
    await optionRepository.setValue(
      SportCatalog.optionKey(
        PlayerProfileService.birthDateKey,
        sportId: SportCatalog.basketballId,
      ),
      DateTime(now.year - 13, now.month, now.day).toIso8601String(),
    );
    await optionRepository.setValue(
      SportCatalog.optionKey(
        PlayerProfileService.soccerStartDateKey,
        sportId: SportCatalog.basketballId,
      ),
      DateTime(now.year - 2, now.month, now.day).toIso8601String(),
    );
    await optionRepository.setValue(
      SportCatalog.optionKey(
        PlayerProfileService.heightCmKey,
        sportId: SportCatalog.basketballId,
      ),
      '158.0',
    );
    await optionRepository.setValue(
      SportCatalog.optionKey(
        PlayerProfileService.weightKgKey,
        sportId: SportCatalog.basketballId,
      ),
      '48.0',
    );
    await service.add(
      TrainingEntry(
        date: DateTime.now(),
        durationMinutes: 50,
        intensity: 4,
        type: '슈팅',
        mood: 4,
        injury: false,
        notes: '',
        location: '체육관',
        jumpRopeCount: 80,
        jumpRopeMinutes: 12,
        jumpRopeEnabled: true,
        liftingMinutes: 10,
        liftingByPart: const <String, int>{'infront': 20},
        sportId: SportCatalog.basketballId,
      ),
    );
    await service.add(
      TrainingEntry(
        date: DateTime.now(),
        durationMinutes: 40,
        intensity: 4,
        type: '경기',
        mood: 4,
        injury: false,
        notes: '',
        location: '체육관',
        opponentTeam: '블루',
        scoredGoals: 50,
        concededGoals: 40,
        playerGoals: 12,
        playerAssists: 4,
        shotsOnTarget: 7,
        ballsWon: 3,
        minutesPlayed: 20,
        sportId: SportCatalog.basketballId,
      ),
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
          home: StatsScreen(
            trainingService: service,
            mealLogService: mealLogService,
            localeService: localeService,
            onCreate: () {},
            optionRepository: optionRepository,
            settingsService: settingsService,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('농구 성장 요약'), findsOneWidget);
    expect(find.text('셔틀런 통계'), findsOneWidget);
    expect(find.text('볼 핸들링 세부 기록'), findsOneWidget);
    expect(find.text('평균 비교'), findsOneWidget);
    expect(find.text('볼 핸들링/세션'), findsOneWidget);
    expect(find.text('축구 평균 비교는 숨겼어요'), findsNothing);

    await tester.tap(find.text('시합'));
    await tester.pumpAndSettle();

    expect(find.text('농구 경기 리포트'), findsOneWidget);
    expect(find.text('40분 기준'), findsOneWidget);
    expect(find.textContaining('득점 12.0'), findsOneWidget);
  });
}

Future<void> _markBenchmarksFresh(
    _MemoryOptionRepository optionRepository) async {
  await optionRepository.setValue(
    'benchmark_synced_at_v2',
    DateTime.now().toUtc().toIso8601String(),
  );
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
    _entries.remove(entry);
    _emit();
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
      _emit();
    }
  }

  @override
  Stream<List<TrainingEntry>> watchAll() {
    return Stream<List<TrainingEntry>>.multi((controller) {
      void emit() {
        if (!controller.isClosed) {
          controller.add(List<TrainingEntry>.unmodifiable(_entries));
        }
      }

      emit();
      final sub = _controller.stream.listen((_) => emit());
      controller.onCancel = sub.cancel;
    }, isBroadcast: true);
  }

  @override
  Stream<List<TrainingEntry>> watchRange(
    DateTime startInclusive,
    DateTime endExclusive,
  ) {
    return Stream<List<TrainingEntry>>.multi((controller) {
      void emit() {
        if (!controller.isClosed) {
          controller.add(_rangeEntries(startInclusive, endExclusive));
        }
      }

      emit();
      final sub = _controller.stream.listen((_) => emit());
      controller.onCancel = sub.cancel;
    }, isBroadcast: true);
  }

  @override
  Stream<List<TrainingEntry>> watchRecent({
    required int limit,
    bool includeMatches = true,
    String? sportId,
  }) {
    return Stream<List<TrainingEntry>>.multi((controller) {
      void emit() {
        if (!controller.isClosed) {
          controller.add(
            _recentEntries(limit: limit, includeMatches: includeMatches),
          );
        }
      }

      emit();
      final sub = _controller.stream.listen((_) => emit());
      controller.onCancel = sub.cancel;
    }, isBroadcast: true);
  }

  void _emit() {
    _controller.add(List<TrainingEntry>.unmodifiable(_entries));
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

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  @override
  T? getValue<T>(String key) => _values[key] as T?;

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    if (value is List<int>) return List<int>.from(value);
    if (value is List) return value.whereType<int>().toList(growable: false);
    return List<int>.from(defaults);
  }

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    if (value is List<String>) return List<String>.from(value);
    if (value is List) {
      return value.whereType<String>().toList(growable: false);
    }
    return List<String>.from(defaults);
  }

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    _values[key] = List<dynamic>.from(options);
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    _values[key] = value;
  }
}
