import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/locale_service.dart';
import 'package:football_note/application/match_competition_service.dart';
import 'package:football_note/application/settings_service.dart';
import 'package:football_note/application/training_service.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/repositories/training_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/match_hub_screen.dart';
import 'package:football_note/presentation/screens/match_record_screen.dart';

import '../helpers/test_asset_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MemoryTrainingRepository trainingRepository;
  late TrainingService trainingService;
  late _MemoryOptionRepository optionRepository;
  late LocaleService localeService;
  late SettingsService settingsService;

  setUp(() {
    trainingRepository = _MemoryTrainingRepository();
    trainingService = TrainingService(trainingRepository);
    optionRepository = _MemoryOptionRepository();
    localeService = LocaleService(optionRepository)..load();
    settingsService = SettingsService(optionRepository)..load();
  });

  tearDown(() async {
    await trainingRepository.dispose();
  });

  Future<void> pumpHub(
    WidgetTester tester, {
    VoidCallback? onOpenCalendar,
    VoidCallback? onOpenMatchStats,
  }) async {
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
          supportedLocales: const [
            Locale('en'),
            Locale('ko', 'KR'),
            Locale('ja'),
          ],
          home: MatchHubScreen(
            trainingService: trainingService,
            localeService: localeService,
            optionRepository: optionRepository,
            settingsService: settingsService,
            onOpenCalendar: onOpenCalendar ?? () {},
            onOpenMatchStats: onOpenMatchStats ?? () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Match hub shows competitions and recent match results', (
    tester,
  ) async {
    final competitionService = MatchCompetitionService(optionRepository);
    await competitionService.upsertCompetition(
      MatchCompetitionRecord.create(
        kind: MatchCompetitionRecord.kindLeague,
        name: '주말 리그',
        teams: const ['우리 팀', '서울 U15', '부산 U15'],
      ),
    );
    await competitionService.upsertCompetition(
      MatchCompetitionRecord.create(
        kind: MatchCompetitionRecord.kindTournament,
        name: '컵 대회',
        teams: const ['우리 팀', '인천 U15', '대전 U15', '광주 U15'],
        status: MatchCompetitionRecord.statusFinished,
      ),
    );
    await trainingService.add(
      TrainingEntry(
        date: DateTime(2026, 6, 20),
        durationMinutes: 70,
        intensity: 4,
        type: '시합',
        mood: 4,
        injury: false,
        notes: '',
        location: '메인 구장',
        opponentTeam: '서울 U15',
        scoredGoals: 3,
        concededGoals: 1,
        matchKind: MatchCompetitionRecord.kindLeague,
        matchCompetitionName: '주말 리그',
        leagueTeamNames: const ['우리 팀', '서울 U15', '부산 U15'],
        leaguePoints: 3,
      ),
    );
    await trainingService.add(
      TrainingEntry(
        date: DateTime(2026, 6, 18),
        durationMinutes: 60,
        intensity: 3,
        type: '시합',
        mood: 3,
        injury: false,
        notes: '',
        location: '보조 구장',
        opponentTeam: '인천 U15',
        scoredGoals: 1,
        concededGoals: 2,
        matchKind: MatchCompetitionRecord.kindTournament,
        matchCompetitionName: '컵 대회',
        leagueTeamNames: const ['우리 팀', '인천 U15'],
        tournamentOutcome: 'eliminated',
      ),
    );

    await pumpHub(tester);

    expect(find.text('시합 허브'), findsWidgets);
    expect(find.text('시합 운영 보드'), findsOneWidget);
    expect(find.text('2경기'), findsOneWidget);
    expect(find.text('1승 0무 1패'), findsOneWidget);
    expect(find.text('주말 리그'), findsOneWidget);
    expect(find.text('컵 대회'), findsOneWidget);
    expect(find.textContaining('서울 U15'), findsWidgets);
    expect(find.text('3 : 1'), findsOneWidget);
  });

  testWidgets('Match hub quick stats action calls the host callback', (
    tester,
  ) async {
    var openedStats = false;

    await pumpHub(
      tester,
      onOpenMatchStats: () => openedStats = true,
    );
    await tester.tap(find.text('시합 통계'));
    await tester.pump();
    await tester.pump();

    expect(openedStats, isTrue);
  });

  testWidgets('Match record screen saves a friendly result from touch controls',
      (
    tester,
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
          supportedLocales: const [
            Locale('en'),
            Locale('ko', 'KR'),
            Locale('ja'),
          ],
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MatchRecordScreen(
                          trainingService: trainingService,
                          localeService: localeService,
                          optionRepository: optionRepository,
                          settingsService: settingsService,
                          initialDate: DateTime(2026, 6, 26),
                        ),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), '서울 U15');
    await tester.ensureVisible(find.text('승'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('승'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('저장'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장'));
    await tester.pump(const Duration(seconds: 1));

    expect(trainingRepository.entries, hasLength(1));
    expect(trainingRepository.entries.single.opponentTeam, '서울 U15');
    expect(trainingRepository.entries.single.scoredGoals, 1);
    expect(trainingRepository.entries.single.concededGoals, 0);
    expect(trainingRepository.entries.single.matchKind, 'friendly');
  });
}

class _MemoryTrainingRepository implements TrainingRepository {
  final List<TrainingEntry> _entries = <TrainingEntry>[];
  final StreamController<List<TrainingEntry>> _controller =
      StreamController<List<TrainingEntry>>.broadcast();

  List<TrainingEntry> get entries => List<TrainingEntry>.unmodifiable(_entries);

  Future<void> dispose() => _controller.close();

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
  Future<List<TrainingEntry>> getAll() async =>
      List<TrainingEntry>.unmodifiable(_entries);

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
    return _recentEntries(
      limit: limit,
      includeMatches: includeMatches,
      sportId: sportId,
    );
  }

  @override
  Future<void> update(int key, TrainingEntry entry) async {
    if (key < 0 || key >= _entries.length) return;
    _entries[key] = entry;
    _emit();
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
            _recentEntries(
              limit: limit,
              includeMatches: includeMatches,
              sportId: sportId,
            ),
          );
        }
      }

      emit();
      final sub = _controller.stream.listen((_) => emit());
      controller.onCancel = sub.cancel;
    }, isBroadcast: true);
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List<TrainingEntry>.unmodifiable(_entries));
    }
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
    String? sportId,
  }) {
    if (limit <= 0) return const <TrainingEntry>[];
    final entries = _entries
        .where(
          (entry) =>
              (sportId == null || entry.sportId == sportId) &&
              (includeMatches || !entry.isMatch),
        )
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
