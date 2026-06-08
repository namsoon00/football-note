import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/family_access_service.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/repositories/training_repository.dart';
import 'package:football_note/application/training_service.dart';
import 'package:football_note/presentation/screens/logs_screen.dart';
import 'package:football_note/application/locale_service.dart';
import 'package:football_note/application/settings_service.dart';

import '../helpers/test_asset_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MemoryTrainingRepository trainingRepository;
  late TrainingService service;
  late _MemoryOptionRepository optionRepository;
  late LocaleService localeService;
  late SettingsService settingsService;

  setUp(() {
    trainingRepository = _MemoryTrainingRepository();
    service = TrainingService(trainingRepository);
    optionRepository = _MemoryOptionRepository();
    localeService = LocaleService(optionRepository)..load();
    settingsService = SettingsService(optionRepository)..load();
  });

  Future<void> clearTrainingBox() async {
    trainingRepository.clear();
  }

  testWidgets('Logs screen shows saved entry', (WidgetTester tester) async {
    await clearTrainingBox();
    final entry = TrainingEntry(
      date: DateTime(2024, 1, 1),
      durationMinutes: 60,
      intensity: 3,
      type: '기술',
      mood: 3,
      injury: false,
      notes: '메모',
      location: '학교 운동장',
      goodPoints: '압박을 잘 벗어남',
      improvements: '왼발 패스 템포가 느렸음',
      nextGoal: '터치 수 줄이기',
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
          home: LogsScreen(
            trainingService: service,
            localeService: localeService,
            optionRepository: optionRepository,
            settingsService: settingsService,
            onEdit: (_) {},
            onCreate: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('기술 · 60분 · 학교 운동장'), findsOneWidget);
    expect(find.text('터치 수 줄이기'), findsOneWidget);
    expect(find.byTooltip('다이어리'), findsNothing);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '메모');
    await tester.pump();
    expect(find.text('기술 · 60분 · 학교 운동장'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '없는검색');
    await tester.pump();
    expect(find.text('검색 결과가 없습니다.'), findsOneWidget);
  });

  testWidgets('Logs screen hides match entries from training log list', (
    WidgetTester tester,
  ) async {
    await clearTrainingBox();
    await service.add(
      TrainingEntry(
        date: DateTime(2024, 1, 2),
        durationMinutes: 90,
        intensity: 4,
        type: '경기',
        mood: 4,
        injury: false,
        notes: '시합 메모',
        location: '보조 경기장',
        program: '경기',
        opponentTeam: '라이벌 FC',
        scoredGoals: 2,
        concededGoals: 1,
        playerGoals: 1,
        playerAssists: 1,
        minutesPlayed: 80,
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
          home: LogsScreen(
            trainingService: service,
            localeService: localeService,
            optionRepository: optionRepository,
            settingsService: settingsService,
            onEdit: (_) {},
            onCreate: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('독립 시합 기록'), findsNothing);
    expect(find.textContaining('라이벌 FC'), findsNothing);
    expect(find.text('아직 기록이 없습니다.'), findsOneWidget);
  });

  testWidgets('Logs screen marks filter button when filters are active', (
    WidgetTester tester,
  ) async {
    await clearTrainingBox();
    optionRepository.clear();
    await service.add(
      TrainingEntry(
        date: DateTime(2024, 1, 4),
        durationMinutes: 45,
        intensity: 3,
        type: '패스',
        mood: 3,
        injury: true,
        notes: '필터 테스트',
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
          home: LogsScreen(
            trainingService: service,
            localeService: localeService,
            optionRepository: optionRepository,
            settingsService: settingsService,
            onEdit: (_) {},
            onCreate: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    final activeIndicatorKey = ValueKey(
      'home-option-active-${Icons.tune.codePoint}',
    );
    expect(find.byKey(activeIndicatorKey), findsNothing);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.tap(find.text('부상 기록만'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('적용'));
    await tester.pumpAndSettle();

    expect(find.byKey(activeIndicatorKey), findsOneWidget);
  });

  testWidgets('Logs screen shows quick guide only when there are no entries', (
    WidgetTester tester,
  ) async {
    await clearTrainingBox();
    optionRepository.clear();

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
          home: LogsScreen(
            trainingService: service,
            localeService: localeService,
            optionRepository: optionRepository,
            settingsService: settingsService,
            onEdit: (_) {},
            onCreate: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('빠른 시작 가이드'), findsOneWidget);

    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();

    await clearTrainingBox();
    await service.add(
      TrainingEntry(
        date: DateTime(2024, 1, 3),
        durationMinutes: 50,
        intensity: 3,
        type: '패스',
        mood: 3,
        injury: false,
        notes: '안내 숨김 확인',
        location: '실내 구장',
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
          home: LogsScreen(
            trainingService: service,
            localeService: localeService,
            optionRepository: optionRepository,
            settingsService: settingsService,
            onEdit: (_) {},
            onCreate: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('빠른 시작 가이드'), findsNothing);
  });

  testWidgets('parent mode logs screen hides delete affordances and add FAB', (
    WidgetTester tester,
  ) async {
    await clearTrainingBox();
    optionRepository.clear();
    await optionRepository.setValue(
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.parent.name,
    );
    await service.add(
      TrainingEntry(
        date: DateTime(2024, 1, 4),
        durationMinutes: 55,
        intensity: 3,
        type: '패스',
        mood: 4,
        injury: false,
        notes: '부모 모드 확인',
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
          home: LogsScreen(
            trainingService: service,
            localeService: localeService,
            optionRepository: optionRepository,
            settingsService: settingsService,
            onEdit: (_) {},
            onCreate: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Dismissible), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets(
    'parent mode empty logs screen shows guidance instead of create',
    (WidgetTester tester) async {
      await clearTrainingBox();
      optionRepository.clear();
      await optionRepository.setValue(
        FamilyAccessService.currentRoleLocalKey,
        FamilyRole.parent.name,
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
            home: LogsScreen(
              trainingService: service,
              localeService: localeService,
              optionRepository: optionRepository,
              settingsService: settingsService,
              onEdit: (_) {},
              onCreate: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('빠른 시작 가이드'), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.textContaining('보호자 모드에서는 새 훈련기록을 만들지 않고'), findsOneWidget);
    },
  );
}

class _MemoryTrainingRepository implements TrainingRepository {
  final List<TrainingEntry> _entries = <TrainingEntry>[];
  final StreamController<List<TrainingEntry>> _controller =
      StreamController<List<TrainingEntry>>.broadcast();

  void clear() {
    _entries.clear();
    _emit();
  }

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

  void clear() {
    _values.clear();
  }

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
