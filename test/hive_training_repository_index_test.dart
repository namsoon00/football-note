import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/drive_backup_service.dart';
import 'package:football_note/domain/entities/sport_definition.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/infrastructure/hive_training_repository.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  var generation = 0;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'football_note_training_index_',
    );
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TrainingEntryAdapter());
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  Future<_RepositoryHarness> openHarness({
    List<TrainingEntry> entries = const <TrainingEntry>[],
  }) async {
    final suffix = generation++;
    final trainingBoxName = 'training_entries_index_test_$suffix';
    final trainingBox = await Hive.openBox<TrainingEntry>(trainingBoxName);
    final indexBox = await Hive.openBox<dynamic>(
      HiveTrainingRepository.indexBoxNameFor(trainingBoxName),
    );
    if (entries.isNotEmpty) {
      await trainingBox.addAll(entries);
    }
    return _RepositoryHarness(
      trainingBox: trainingBox,
      indexBox: indexBox,
      repository: HiveTrainingRepository(trainingBox, indexBox: indexBox),
    );
  }

  test('empty and one-entry databases use index-compatible CRUD paths',
      () async {
    final harness = await openHarness();
    addTearDown(harness.close);

    await harness.repository.ensureIndexReady();
    harness.repository.debugCounters.reset();

    expect(await harness.repository.getRecent(limit: 5), isEmpty);
    expect(
      await harness.repository.getRange(
        DateTime(2026, 1, 1),
        DateTime(2026, 2, 1),
      ),
      isEmpty,
    );
    expect(harness.repository.debugCounters.sourceScanCount, 0);

    await harness.repository.add(
      _entry(
        date: DateTime(2026, 1, 3),
        createdAt: DateTime(2026, 1, 3, 18),
      ),
    );
    await _waitForHiveEvents();

    final recent = await harness.repository.getRecent(limit: 1);
    expect(recent, hasLength(1));
    expect(recent.single.date, DateTime(2026, 1, 3));
    expect(harness.repository.debugCounters.sourceScanCount, 0);
  });

  test(
    'indexed benchmark datasets avoid full source scans for 1k 5k 10k and 30k',
    () async {
      for (final size in const <int>[1000, 5000, 10000, 30000]) {
        final entries = _benchmarkEntries(size);
        final harness = await openHarness(entries: entries);
        addTearDown(harness.close);

        await harness.repository.ensureIndexReady();
        harness.repository.debugCounters.reset();

        final recent = await harness.repository.getRecent(
          limit: 10,
          includeMatches: false,
          sportId: SportCatalog.footballId,
        );

        expect(recent, hasLength(10), reason: 'recent size=$size');
        expect(
          recent.every(
            (entry) =>
                entry.sportId == SportCatalog.footballId && !entry.isMatch,
          ),
          isTrue,
        );
        expect(
          harness.repository.debugCounters.sourceScanCount,
          0,
          reason: 'recent source scan size=$size',
        );
        expect(
          harness.repository.debugCounters.trainingEntryFetchCount,
          10,
          reason: 'recent loaded entry count size=$size',
        );
        expect(
          harness.repository.debugCounters.indexRecordVisitCount,
          10,
          reason: 'recent candidate count size=$size',
        );

        harness.repository.debugCounters.reset();
        final start = DateTime(2025, 5, 1);
        final end = DateTime(2025, 6, 1);
        final range = await harness.repository.getRange(start, end);
        final expected = entries
            .where(
              (entry) =>
                  !entry.date.isBefore(start) && entry.date.isBefore(end),
            )
            .toList(growable: false)
          ..sort((a, b) {
            final dateCompare = a.date.compareTo(b.date);
            if (dateCompare != 0) return dateCompare;
            return a.createdAt.compareTo(b.createdAt);
          });

        expect(
          range.map((entry) => entry.createdAt),
          expected.map(
            (entry) => entry.createdAt,
          ),
          reason: 'range accuracy size=$size',
        );
        expect(
          harness.repository.debugCounters.sourceScanCount,
          0,
          reason: 'range source scan size=$size',
        );
        expect(
          harness.repository.debugCounters.trainingEntryFetchCount,
          expected.length,
          reason: 'range loaded entry count size=$size',
        );
        expect(
          harness.repository.debugCounters.indexRecordVisitCount,
          lessThan(size),
          reason: 'range candidate count size=$size',
        );
      }
    },
  );

  test('filters stay accurate across date createdAt sport and match updates',
      () async {
    final harness = await openHarness(
      entries: <TrainingEntry>[
        _entry(
          date: DateTime(2026, 1, 5),
          createdAt: DateTime(2026, 1, 5, 8),
          sportId: SportCatalog.footballId,
        ),
      ],
    );
    addTearDown(harness.close);

    await harness.repository.ensureIndexReady();
    harness.repository.debugCounters.reset();

    await harness.repository.update(
      0,
      _entry(
        date: DateTime(2026, 2, 7),
        createdAt: DateTime(2026, 3, 1, 9),
        sportId: SportCatalog.basketballId,
        isMatch: true,
      ),
    );
    await _waitForHiveEvents();

    expect(
      await harness.repository.getRange(
        DateTime(2026, 1, 1),
        DateTime(2026, 2, 1),
      ),
      isEmpty,
    );
    final movedRange = await harness.repository.getRange(
      DateTime(2026, 2, 1),
      DateTime(2026, 3, 1),
    );
    expect(movedRange.single.sportId, SportCatalog.basketballId);

    expect(
      await harness.repository.getRecent(
        limit: 1,
        includeMatches: false,
        sportId: SportCatalog.basketballId,
      ),
      isEmpty,
    );
    final matchRecent = await harness.repository.getRecent(
      limit: 1,
      includeMatches: true,
      sportId: SportCatalog.basketballId,
    );
    expect(matchRecent.single.isMatch, isTrue);
    expect(
      await harness.repository.getRecent(
        limit: 1,
        sportId: SportCatalog.footballId,
      ),
      isEmpty,
    );

    await harness.repository.delete(matchRecent.single);
    await _waitForHiveEvents();
    expect(await harness.repository.getRecent(limit: 1), isEmpty);
    expect(harness.repository.debugCounters.sourceScanCount, 0);
  });

  test('missing partial duplicate and stale indexes rebuild from source',
      () async {
    final entries = <TrainingEntry>[
      _entry(
        date: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1, 8),
      ),
      _entry(
        date: DateTime(2026, 1, 2),
        createdAt: DateTime(2026, 1, 2, 8),
      ),
      _entry(
        date: DateTime(2026, 2, 1),
        createdAt: DateTime(2026, 2, 1, 8),
        sportId: SportCatalog.baseballId,
      ),
    ];
    final harness = await openHarness(entries: entries);
    addTearDown(harness.close);

    await harness.repository.ensureIndexReady();
    await harness.repository.dispose();

    await harness.indexBox.clear();
    await _expectRestartRebuildsToSource(
      harness,
      expectedCreatedAt: entries.map((entry) => entry.createdAt).toSet(),
    );

    await harness.indexBox.clear();
    await harness.indexBox.put('recent', <Map<String, Object?>>[
      <String, Object?>{
        'key': 0,
        'dateMicros': entries.first.date.microsecondsSinceEpoch,
        'createdAtMicros': entries.first.createdAt.microsecondsSinceEpoch,
        'sportId': entries.first.sportId,
        'isMatch': entries.first.isMatch,
      },
    ]);
    await _expectRestartRebuildsToSource(
      harness,
      expectedCreatedAt: entries.map((entry) => entry.createdAt).toSet(),
    );

    final recent = (harness.indexBox.get('recent') as List).toList();
    recent
      ..add(recent.first)
      ..add(<String, Object?>{
        'key': 999999,
        'dateMicros': DateTime(2026, 4, 1).microsecondsSinceEpoch,
        'createdAtMicros': DateTime(2026, 4, 1).microsecondsSinceEpoch,
        'sportId': SportCatalog.footballId,
        'isMatch': false,
      });
    await harness.indexBox.put('recent', recent);

    await _expectRestartRebuildsToSource(
      harness,
      expectedCreatedAt: entries.map((entry) => entry.createdAt).toSet(),
    );
  });

  test('watch streams use Hive events for add update delete and cancellation',
      () async {
    final harness = await openHarness();
    addTearDown(harness.close);

    await harness.repository.ensureIndexReady();
    harness.repository.debugCounters.reset();
    final firstEmissions = <List<TrainingEntry>>[];
    final secondEmissions = <List<TrainingEntry>>[];
    final firstSub = harness.repository
        .watchRecent(limit: 2, includeMatches: false)
        .listen(firstEmissions.add);
    final secondSub = harness.repository
        .watchRecent(limit: 2, includeMatches: false)
        .listen(secondEmissions.add);
    addTearDown(firstSub.cancel);
    addTearDown(secondSub.cancel);

    await _waitForHiveEvents();
    expect(firstEmissions.last, isEmpty);
    expect(secondEmissions.last, isEmpty);

    await harness.repository.add(
      _entry(
        date: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1, 8),
      ),
    );
    await _waitForHiveEvents();
    expect(firstEmissions.last.single.createdAt, DateTime(2026, 1, 1, 8));
    expect(secondEmissions.last.single.createdAt, DateTime(2026, 1, 1, 8));

    await firstSub.cancel();
    final firstEmissionCount = firstEmissions.length;

    await harness.trainingBox.put(
      0,
      _entry(
        date: DateTime(2026, 1, 2),
        createdAt: DateTime(2026, 1, 3, 8),
      ),
    );
    await _waitForHiveEvents();

    expect(firstEmissions, hasLength(firstEmissionCount));
    expect(secondEmissions.last.single.date, DateTime(2026, 1, 2));
    expect(harness.repository.debugCounters.sourceScanCount, 0);
  });

  test('restore-style direct clear and add sequence is reflected by the index',
      () async {
    final harness = await openHarness(
      entries: <TrainingEntry>[
        _entry(
          date: DateTime(2026, 1, 1),
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
    );
    addTearDown(harness.close);

    await harness.repository.ensureIndexReady();
    harness.repository.debugCounters.reset();

    await harness.trainingBox.clear();
    await harness.trainingBox.addAll(<TrainingEntry>[
      _entry(
        date: DateTime(2026, 4, 10),
        createdAt: DateTime(2026, 4, 10, 9),
        sportId: SportCatalog.tennisId,
      ),
      _entry(
        date: DateTime(2026, 4, 11),
        createdAt: DateTime(2026, 4, 11, 9),
        sportId: SportCatalog.tennisId,
      ),
    ]);
    await _waitForHiveEvents();

    final restored = await harness.repository.getRange(
      DateTime(2026, 4, 1),
      DateTime(2026, 5, 1),
    );
    expect(restored, hasLength(2));
    expect(
      restored.every((entry) => entry.sportId == SportCatalog.tennisId),
      isTrue,
    );
    expect(harness.repository.debugCounters.sourceScanCount, 0);
  });

  test('Drive backup payload stays compatible and restore refreshes the index',
      () async {
    final harness = await openHarness(
      entries: <TrainingEntry>[
        _entry(
          date: DateTime(2026, 5, 1),
          createdAt: DateTime(2026, 5, 1, 8),
        ),
      ],
    );
    final optionBox =
        await Hive.openBox<dynamic>('options_index_test_$generation');
    addTearDown(() async {
      if (optionBox.isOpen) {
        await optionBox.close();
      }
    });
    addTearDown(harness.close);

    await harness.repository.ensureIndexReady();
    final service = DriveBackupService(harness.trainingBox, optionBox);
    final backup = service.buildBackupForTesting();

    expect(backup['entries'], isA<List>());
    expect(backup['optionRecords'], isA<List>());
    expect(backup.containsKey('training_entries_query_index_v1'), isFalse);
    expect(
        backup.containsKey(HiveTrainingRepository.indexBoxNameFor(
          harness.trainingBox.name,
        )),
        isFalse);

    final remoteTrainingBox = await Hive.openBox<TrainingEntry>(
      'remote_training_entries_index_test_${generation++}',
    );
    addTearDown(() async {
      if (remoteTrainingBox.isOpen) {
        await remoteTrainingBox.close();
      }
    });
    await remoteTrainingBox.add(
      TrainingEntry(
        date: DateTime(2026, 6, 10),
        createdAt: DateTime(2026, 6, 10, 9),
        sportId: SportCatalog.baseballId,
        durationMinutes: 80,
        intensity: 4,
        type: 'batting',
        mood: 5,
        injury: false,
        notes: 'restored',
        location: 'field',
      ),
    );
    final remote = DriveBackupService(
      remoteTrainingBox,
      optionBox,
    ).buildBackupForTesting();

    harness.repository.debugCounters.reset();
    await service.restoreFromMapForTesting(remote);
    await _waitForHiveEvents();

    final restored = await harness.repository.getRecent(
      limit: 1,
      sportId: SportCatalog.baseballId,
    );
    expect(restored.single.notes, 'restored');
    expect(harness.repository.debugCounters.sourceScanCount, 0);
  });

  test('training entry compaction strategy is conservative', () {
    expect(
      HiveTrainingRepository.trainingEntryCompactionStrategy(10000, 99),
      isFalse,
    );
    expect(
      HiveTrainingRepository.trainingEntryCompactionStrategy(10000, 2000),
      isFalse,
    );
    expect(
      HiveTrainingRepository.trainingEntryCompactionStrategy(10000, 3000),
      isTrue,
    );
  });
}

Future<void> _expectRestartRebuildsToSource(
  _RepositoryHarness harness, {
  required Set<DateTime> expectedCreatedAt,
}) async {
  final restarted = HiveTrainingRepository(
    harness.trainingBox,
    indexBox: harness.indexBox,
  );
  addTearDown(restarted.dispose);
  final recent = await restarted.getRecent(limit: 10);

  expect(recent.map((entry) => entry.createdAt).toSet(), expectedCreatedAt);
  expect(restarted.debugCounters.indexRebuildCount, 1);
  expect(restarted.debugCounters.sourceScanCount, 1);
  expect(
      restarted.debugCounters.sourceEntryVisitCount, expectedCreatedAt.length);
  await restarted.dispose();
}

List<TrainingEntry> _benchmarkEntries(int count) {
  final baseDate = DateTime(2025, 1, 1);
  final baseCreatedAt = DateTime(2026, 1, 1);
  return List<TrainingEntry>.generate(count, (index) {
    final forceRecentFootballTraining = index >= count - 50;
    final sportId = forceRecentFootballTraining
        ? SportCatalog.footballId
        : switch (index % 3) {
            0 => SportCatalog.footballId,
            1 => SportCatalog.baseballId,
            _ => SportCatalog.basketballId,
          };
    return _entry(
      date: baseDate.add(Duration(days: index % 365)),
      createdAt: baseCreatedAt.add(Duration(minutes: index)),
      sportId: sportId,
      isMatch: !forceRecentFootballTraining && index % 11 == 0,
      durationMinutes: 30 + (index % 70),
    );
  }, growable: false);
}

TrainingEntry _entry({
  required DateTime date,
  DateTime? createdAt,
  String sportId = SportCatalog.footballId,
  bool isMatch = false,
  int durationMinutes = 60,
}) {
  return TrainingEntry(
    date: date,
    createdAt: createdAt ?? date,
    durationMinutes: durationMinutes,
    intensity: 3,
    type: '기술',
    mood: 4,
    injury: false,
    notes: '',
    location: '학교 운동장',
    sportId: sportId,
    opponentTeam: isMatch ? 'Rival FC' : '',
    matchKind: isMatch ? 'league' : 'friendly',
    scoredGoals: isMatch ? 1 : null,
    concededGoals: isMatch ? 0 : null,
  );
}

Future<void> _waitForHiveEvents() async {
  await Future<void>.delayed(const Duration(milliseconds: 40));
}

class _RepositoryHarness {
  _RepositoryHarness({
    required this.trainingBox,
    required this.indexBox,
    required this.repository,
  });

  final Box<TrainingEntry> trainingBox;
  final Box<dynamic> indexBox;
  HiveTrainingRepository repository;

  Future<void> close() async {
    await repository.dispose();
    if (trainingBox.isOpen) {
      await trainingBox.close();
    }
    if (indexBox.isOpen) {
      await indexBox.close();
    }
  }
}
