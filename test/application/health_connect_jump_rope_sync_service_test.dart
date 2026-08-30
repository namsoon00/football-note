import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:football_note/application/challenge_service.dart';
import 'package:football_note/application/health_connect_jump_rope_import_notification_service.dart';
import 'package:football_note/application/health_connect_jump_rope_sync_service.dart';
import 'package:football_note/application/player_level_service.dart';
import 'package:football_note/application/training_service.dart';
import 'package:football_note/domain/entities/challenge.dart';
import 'package:football_note/domain/entities/sport_definition.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/repositories/training_repository.dart';
import 'package:football_note/infrastructure/hive_training_repository.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('method channel platform is supported only on Android', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(
      MethodChannelHealthConnectJumpRopePlatform.isSupportedDevice,
      isFalse,
    );

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(
      MethodChannelHealthConnectJumpRopePlatform.isSupportedDevice,
      isTrue,
    );
  });

  test('syncRecent imports Health Connect jump rope sessions once', () async {
    final options = _MemoryOptionRepository();
    final trainingRepository = _MemoryTrainingRepository();
    final platform = _FakeHealthConnectJumpRopePlatform(
      sessions: [
        HealthConnectJumpRopeSession(
          id: 'hc-1',
          startTime: DateTime(2026, 7, 11, 7, 30),
          endTime: DateTime(2026, 7, 11, 7, 42),
          durationMillis: 12 * Duration.millisecondsPerMinute,
          jumpCount: 900,
          title: 'Jump rope',
          sourcePackage: 'com.sec.android.app.shealth',
          matchedBySegment: true,
        ),
      ],
    );
    final service = HealthConnectJumpRopeSyncService(
      trainingService: TrainingService(trainingRepository),
      optionRepository: options,
      platform: platform,
    );

    final firstResult = await service.syncRecent(
      now: DateTime(2026, 7, 11, 9),
    );
    final secondResult = await service.syncRecent(
      now: DateTime(2026, 7, 11, 9, 5),
    );

    expect(firstResult.importedCount, 1);
    expect(secondResult.importedCount, 0);
    expect(secondResult.duplicateCount, 0);
    expect(trainingRepository.entries, hasLength(1));
    final imported = trainingRepository.entries.single;
    expect(imported.sportId, SportCatalog.footballId);
    expect(imported.jumpRopeEnabled, isTrue);
    expect(imported.jumpRopeMinutes, 12);
    expect(imported.jumpRopeCount, 900);
    expect(imported.program, 'Jump rope');
    final syncedKeys = options.getOptions(
      HealthConnectJumpRopeSyncService.syncedRecordIdsKey,
      const <String>[],
    );
    expect(syncedKeys, contains('hc-1'));
    expect(
      syncedKeys,
      contains(
        _sessionFingerprint(
          sourcePackage: 'com.sec.android.app.shealth',
          startTime: DateTime(2026, 7, 11, 7, 30),
          endTime: DateTime(2026, 7, 11, 7, 42),
          durationMillis: 12 * Duration.millisecondsPerMinute,
        ),
      ),
    );
  });

  test('syncRecent does not show an OS notification for manual sync', () async {
    final options = _MemoryOptionRepository();
    final trainingRepository = _MemoryTrainingRepository();
    final notifier = _FakeHealthConnectJumpRopeImportNotifier();
    final platform = _FakeHealthConnectJumpRopePlatform(
      sessions: [
        HealthConnectJumpRopeSession(
          id: 'hc-manual',
          startTime: DateTime(2026, 7, 11, 7, 30),
          endTime: DateTime(2026, 7, 11, 7, 40),
          durationMillis: 10 * Duration.millisecondsPerMinute,
          jumpCount: 700,
          title: 'Jump rope',
          sourcePackage: 'com.sec.android.app.shealth',
          matchedBySegment: true,
        ),
      ],
    );
    final service = HealthConnectJumpRopeSyncService(
      trainingService: TrainingService(trainingRepository),
      optionRepository: options,
      platform: platform,
      importNotifier: notifier,
    );

    final result = await service.syncRecent(now: DateTime(2026, 7, 11, 9));

    expect(result.importedCount, 1);
    expect(notifier.notifications, isEmpty);
  });

  test('syncIfEnabled shows an OS notification after automatic import',
      () async {
    final options = _MemoryOptionRepository();
    await options.setValue(
      HealthConnectJumpRopeSyncService.autoSyncEnabledKey,
      true,
    );
    final trainingRepository = _MemoryTrainingRepository();
    final notifier = _FakeHealthConnectJumpRopeImportNotifier();
    final startTime = DateTime(2026, 7, 11, 7, 30);
    final platform = _FakeHealthConnectJumpRopePlatform(
      sessions: [
        HealthConnectJumpRopeSession(
          id: 'hc-auto',
          startTime: startTime,
          endTime: DateTime(2026, 7, 11, 7, 40),
          durationMillis: 10 * Duration.millisecondsPerMinute,
          jumpCount: 700,
          title: 'Jump rope',
          sourcePackage: 'com.sec.android.app.shealth',
          matchedBySegment: true,
        ),
      ],
    );
    final service = HealthConnectJumpRopeSyncService(
      trainingService: TrainingService(trainingRepository),
      optionRepository: options,
      platform: platform,
      importNotifier: notifier,
    );

    final result = await service.syncIfEnabled(now: DateTime(2026, 7, 11, 9));

    expect(result.importedCount, 1);
    expect(notifier.notifications, hasLength(1));
    expect(notifier.notifications.single.count, 1);
    expect(notifier.notifications.single.firstSessionStart, startTime);
  });

  test('syncRecent skips a session when only its Health Connect id changed',
      () async {
    final options = _MemoryOptionRepository();
    final trainingRepository = _MemoryTrainingRepository();
    final startTime = DateTime(2026, 7, 11, 7, 30);
    final endTime = DateTime(2026, 7, 11, 7, 42);
    await trainingRepository.add(
      TrainingEntry(
        date: DateTime(startTime.year, startTime.month, startTime.day),
        sportId: SportCatalog.footballId,
        durationMinutes: 12,
        intensity: 3,
        type: 'Jump rope',
        mood: 3,
        injury: false,
        notes: '',
        location: '',
        program: 'Jump rope',
        createdAt: startTime,
        jumpRopeCount: 900,
        jumpRopeMinutes: 12,
        jumpRopeEnabled: true,
      ),
    );
    await options.saveOptions(
      HealthConnectJumpRopeSyncService.syncedRecordIdsKey,
      <String>['hc-old'],
    );
    final platform = _FakeHealthConnectJumpRopePlatform(
      sessions: [
        HealthConnectJumpRopeSession(
          id: 'hc-new',
          startTime: startTime,
          endTime: endTime,
          durationMillis: 12 * Duration.millisecondsPerMinute,
          jumpCount: 900,
          title: 'Jump rope',
          sourcePackage: 'com.sec.android.app.shealth',
          matchedBySegment: true,
        ),
      ],
    );
    final service = HealthConnectJumpRopeSyncService(
      trainingService: TrainingService(trainingRepository),
      optionRepository: options,
      platform: platform,
    );

    final result = await service.syncRecent(now: DateTime(2026, 7, 11, 9));

    expect(result.importedCount, 0);
    expect(result.duplicateCount, 1);
    expect(trainingRepository.entries, hasLength(1));
    final syncedKeys = options.getOptions(
      HealthConnectJumpRopeSyncService.syncedRecordIdsKey,
      const <String>[],
    );
    expect(syncedKeys, contains('hc-old'));
    expect(syncedKeys, contains('hc-new'));
    expect(
      syncedKeys,
      contains(
        _sessionFingerprint(
          sourcePackage: 'com.sec.android.app.shealth',
          startTime: startTime,
          endTime: endTime,
          durationMillis: 12 * Duration.millisecondsPerMinute,
        ),
      ),
    );
  });

  test('requestPermissionsAndSync enables auto sync after permission grant',
      () async {
    final options = _MemoryOptionRepository();
    final trainingRepository = _MemoryTrainingRepository();
    final notifier = _FakeHealthConnectJumpRopeImportNotifier();
    final platform = _FakeHealthConnectJumpRopePlatform(
      permissionsGranted: false,
      grantOnRequest: true,
      sessions: [
        HealthConnectJumpRopeSession(
          id: 'hc-2',
          startTime: DateTime(2026, 7, 10, 18),
          endTime: DateTime(2026, 7, 10, 18, 8),
          durationMillis: 8 * Duration.millisecondsPerMinute,
          jumpCount: 0,
          title: '줄넘기',
          sourcePackage: 'com.sec.android.app.shealth',
          matchedBySegment: false,
        ),
      ],
    );
    final service = HealthConnectJumpRopeSyncService(
      trainingService: TrainingService(trainingRepository),
      optionRepository: options,
      platform: platform,
      importNotifier: notifier,
    );

    final result = await service.requestPermissionsAndSync(
      now: DateTime(2026, 7, 11, 9),
    );

    expect(result.importedCount, 1);
    expect(service.autoSyncEnabled, isTrue);
    expect(notifier.permissionRequests, 1);
    expect(trainingRepository.entries.single.program, '줄넘기');
  });

  test('imports only Samsung Health sessions and stores sync ownership',
      () async {
    final options = _MemoryOptionRepository();
    final trainingRepository = _MemoryTrainingRepository();
    final platform = _FakeHealthConnectJumpRopePlatform(
      sessions: [
        _session(id: 'samsung-1'),
        _session(
          id: 'other-1',
          sourcePackage: 'com.google.android.apps.fitness',
        ),
      ],
    );
    final service = HealthConnectJumpRopeSyncService(
      trainingService: TrainingService(trainingRepository),
      optionRepository: options,
      platform: platform,
    );

    final result = await service.syncRecent(now: DateTime(2026, 7, 11, 9));

    expect(result.importedCount, 1);
    expect(trainingRepository.entries, hasLength(1));
    expect(
      trainingRepository.entries.single.recordId,
      '${HealthConnectJumpRopeSyncService.ownedRecordIdPrefix}samsung-1',
    );
    expect(
      trainingRepository.entries.single.originDeviceId,
      'health_connect:samsung_health',
    );
    expect(trainingRepository.entries.single.payloadHash, isNotEmpty);
    expect(
      options.getValue<bool>(
        HealthConnectJumpRopeSyncService.samsungRecordDetectedKey,
      ),
      isTrue,
    );
  });

  test('first sync reads 30 days and later sync uses only changes', () async {
    final options = _MemoryOptionRepository();
    final platform = _FakeHealthConnectJumpRopePlatform(
      sessions: [_session(id: 'history-1')],
    );
    final service = HealthConnectJumpRopeSyncService(
      trainingService: TrainingService(_MemoryTrainingRepository()),
      optionRepository: options,
      platform: platform,
    );
    final now = DateTime(2026, 7, 31, 12);

    await service.syncRecent(now: now);
    await service.syncRecent(now: now.add(const Duration(hours: 1)));

    expect(platform.snapshotReadCount, 1);
    expect(platform.lastReadStart, now.subtract(const Duration(days: 30)));
    expect(platform.changesTokenRequests, 1);
    expect(
      options.getValue<String>(
        HealthConnectJumpRopeSyncService.changesTokenKey,
      ),
      isNotEmpty,
    );
  });

  test('expired changes token rebuilds the recent snapshot', () async {
    final options = _MemoryOptionRepository();
    await options.setValue(
      HealthConnectJumpRopeSyncService.changesTokenKey,
      'expired-token',
    );
    final platform = _FakeHealthConnectJumpRopePlatform(
      sessions: [_session(id: 'recovered-1')],
      changes: const [
        HealthConnectJumpRopeChanges(
          upsertedSessions: <HealthConnectJumpRopeSession>[],
          removedRecordIds: <String>[],
          nextChangesToken: '',
          changesTokenExpired: true,
          scannedCount: 0,
        ),
      ],
    );
    final trainingRepository = _MemoryTrainingRepository();
    final service = HealthConnectJumpRopeSyncService(
      trainingService: TrainingService(trainingRepository),
      optionRepository: options,
      platform: platform,
    );

    final result = await service.syncRecent(now: DateTime(2026, 7, 11, 9));

    expect(result.importedCount, 1);
    expect(platform.snapshotReadCount, 1);
    expect(platform.changesTokenRequests, 1);
    expect(trainingRepository.entries, hasLength(1));
  });

  test('incremental changes update and delete the owned Hive record', () async {
    final store = await _HiveTrainingTestStore.open();
    addTearDown(store.dispose);
    final options = _MemoryOptionRepository();
    final platform = _FakeHealthConnectJumpRopePlatform(
      sessions: [_session(id: 'mutable-1', durationMinutes: 10)],
    );
    final service = HealthConnectJumpRopeSyncService(
      trainingService: TrainingService(store.repository),
      optionRepository: options,
      platform: platform,
    );

    final initial = await service.syncRecent(now: DateTime(2026, 7, 11, 9));
    expect(initial.importedCount, 1);
    expect(PlayerLevelService(options).loadState().totalXp, greaterThan(0));

    platform.changes.add(
      HealthConnectJumpRopeChanges(
        upsertedSessions: [
          _session(id: 'mutable-1', durationMinutes: 20, jumpCount: 1400),
        ],
        removedRecordIds: const <String>[],
        nextChangesToken: 'after-update',
        changesTokenExpired: false,
        scannedCount: 1,
      ),
    );
    final updated = await service.syncRecent(now: DateTime(2026, 7, 11, 10));
    final entriesAfterUpdate = await store.repository.getAll();

    expect(updated.updatedCount, 1);
    expect(updated.importedCount, 0);
    expect(entriesAfterUpdate, hasLength(1));
    expect(entriesAfterUpdate.single.jumpRopeMinutes, 20);
    expect(entriesAfterUpdate.single.jumpRopeCount, 1400);

    platform.changes.add(
      const HealthConnectJumpRopeChanges(
        upsertedSessions: <HealthConnectJumpRopeSession>[],
        removedRecordIds: <String>['mutable-1'],
        nextChangesToken: 'after-delete',
        changesTokenExpired: false,
        scannedCount: 1,
      ),
    );
    final deleted = await service.syncRecent(now: DateTime(2026, 7, 11, 11));

    expect(deleted.deletedCount, 1);
    expect(await store.repository.getAll(), isEmpty);
    expect(PlayerLevelService(options).loadState().totalXp, 0);
  });

  test('imported jump rope time completes the matching challenge mission',
      () async {
    final options = _MemoryOptionRepository();
    final trainingRepository = _MemoryTrainingRepository();
    final syncService = HealthConnectJumpRopeSyncService(
      trainingService: TrainingService(trainingRepository),
      optionRepository: options,
      platform: _FakeHealthConnectJumpRopePlatform(
        sessions: [_session(id: 'challenge-1', durationMinutes: 10)],
      ),
    );
    await syncService.syncRecent(now: DateTime(2026, 7, 11, 9));

    final challengeService = ChallengeService(options);
    final run = await challengeService.startChallenge(
      challengeService.templateById('starter_3')!,
      selectedSkillIds: const <String>[],
      missionTargets: const ChallengeMissionTargets(
        trainingMinutes: 0,
        jumpRopeMinutes: 10,
        liftingMinutes: 0,
        riceBowls: 0,
      ),
      startedAt: DateTime(2026, 7, 11, 6),
    );
    final progress = challengeService.progressForRun(
      run: run,
      trainingEntries: await trainingRepository.getAll(),
      mealEntries: const [],
    )!;

    expect(progress.rounds.first.jumpRopeMinutes, 10);
    expect(progress.rounds.first.jumpRopeCompleted, isTrue);
    expect(progress.rounds.first.completed, isTrue);
  });

  test('repeated permission denial is exposed in diagnostics', () async {
    final options = _MemoryOptionRepository();
    final service = HealthConnectJumpRopeSyncService(
      trainingService: TrainingService(_MemoryTrainingRepository()),
      optionRepository: options,
      platform: _FakeHealthConnectJumpRopePlatform(
        permissionsGranted: false,
        grantOnRequest: false,
      ),
    );

    await service.requestPermissionsAndSync();
    await service.requestPermissionsAndSync();
    final diagnostics = await service.diagnostics();

    expect(diagnostics.permissionDenialCount, 2);
    expect(diagnostics.status.permissionsGranted, isFalse);
  });

  test('forwards access management and consumes privacy launch once', () async {
    final platform = _FakeHealthConnectJumpRopePlatform(
      launchPayload: 'taeonote://settings/health-connect-privacy',
    );
    final service = HealthConnectJumpRopeSyncService(
      trainingService: TrainingService(_MemoryTrainingRepository()),
      optionRepository: _MemoryOptionRepository(),
      platform: platform,
    );

    expect(await service.openManageAccess(), isTrue);
    expect(platform.manageAccessRequests, 1);
    expect(
      await service.healthConnectLaunchPayload(),
      'taeonote://settings/health-connect-privacy',
    );
    expect(await service.healthConnectLaunchPayload(), isNull);
  });
}

HealthConnectJumpRopeSession _session({
  required String id,
  String sourcePackage =
      HealthConnectJumpRopeSyncService.samsungHealthPackageName,
  int durationMinutes = 10,
  int jumpCount = 700,
}) {
  final start = DateTime(2026, 7, 11, 7, 30);
  return HealthConnectJumpRopeSession(
    id: id,
    startTime: start,
    endTime: start.add(Duration(minutes: durationMinutes)),
    durationMillis: durationMinutes * Duration.millisecondsPerMinute,
    jumpCount: jumpCount,
    title: 'Jump rope',
    sourcePackage: sourcePackage,
    matchedBySegment: true,
  );
}

String _sessionFingerprint({
  required String sourcePackage,
  required DateTime startTime,
  required DateTime endTime,
  required int durationMillis,
}) {
  return [
    'healthConnectJumpRope',
    sourcePackage,
    startTime.millisecondsSinceEpoch,
    endTime.millisecondsSinceEpoch,
    durationMillis,
  ].join('|');
}

class _FakeHealthConnectJumpRopeImportNotifier
    implements HealthConnectJumpRopeImportNotifier {
  final List<HealthConnectJumpRopeImportNotification> notifications =
      <HealthConnectJumpRopeImportNotification>[];
  var permissionRequests = 0;

  @override
  Future<bool> permissionGranted() async => true;

  @override
  Future<String?> launchPayload() async => null;

  @override
  Future<bool> requestPermission() async {
    permissionRequests += 1;
    return true;
  }

  @override
  Future<void> showImported(
    HealthConnectJumpRopeImportNotification notification,
  ) async {
    notifications.add(notification);
  }
}

class _FakeHealthConnectJumpRopePlatform
    implements HealthConnectJumpRopePlatform {
  bool permissionsGranted;
  final bool grantOnRequest;
  final List<HealthConnectJumpRopeSession> sessions;
  final List<HealthConnectJumpRopeChanges> changes;
  String? launchPayload;
  var changesTokenRequests = 0;
  var manageAccessRequests = 0;
  var snapshotReadCount = 0;
  DateTime? lastReadStart;
  DateTime? lastReadEnd;

  _FakeHealthConnectJumpRopePlatform({
    this.permissionsGranted = true,
    this.grantOnRequest = true,
    this.sessions = const <HealthConnectJumpRopeSession>[],
    List<HealthConnectJumpRopeChanges> changes =
        const <HealthConnectJumpRopeChanges>[],
    this.launchPayload,
  }) : changes = changes.toList(growable: true);

  @override
  Future<String?> consumeLaunchPayload() async {
    final value = launchPayload;
    launchPayload = null;
    return value;
  }

  @override
  Future<String> createChangesToken() async {
    changesTokenRequests += 1;
    return 'token-$changesTokenRequests';
  }

  @override
  Future<bool> openManageAccess() async {
    manageAccessRequests += 1;
    return true;
  }

  @override
  Future<HealthConnectJumpRopeChanges> readChanges(String token) async {
    if (changes.isNotEmpty) return changes.removeAt(0);
    return HealthConnectJumpRopeChanges(
      upsertedSessions: const <HealthConnectJumpRopeSession>[],
      removedRecordIds: const <String>[],
      nextChangesToken: '$token-next',
      changesTokenExpired: false,
      scannedCount: 0,
    );
  }

  @override
  Future<HealthConnectStatus> status() async {
    return HealthConnectStatus(
      availability: HealthConnectAvailabilityState.available,
      permissionsGranted: permissionsGranted,
    );
  }

  @override
  Future<bool> requestPermissions() async {
    permissionsGranted = grantOnRequest;
    return permissionsGranted;
  }

  @override
  Future<List<HealthConnectJumpRopeSession>> readJumpRopeSessions({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    snapshotReadCount += 1;
    lastReadStart = startInclusive;
    lastReadEnd = endExclusive;
    return sessions
        .where((session) => !session.startTime.isBefore(startInclusive))
        .where((session) => session.startTime.isBefore(endExclusive))
        .toList(growable: false);
  }
}

class _HiveTrainingTestStore {
  final Directory directory;
  final Box<TrainingEntry> box;
  final HiveTrainingRepository repository;

  const _HiveTrainingTestStore({
    required this.directory,
    required this.box,
    required this.repository,
  });

  static Future<_HiveTrainingTestStore> open() async {
    final directory = await Directory.systemTemp.createTemp(
      'health_connect_sync_test_',
    );
    Hive.init(directory.path);
    const trainingEntryTypeId = 1;
    if (!Hive.isAdapterRegistered(trainingEntryTypeId)) {
      Hive.registerAdapter(TrainingEntryAdapter());
    }
    final box = await Hive.openBox<TrainingEntry>(
      'training_${DateTime.now().microsecondsSinceEpoch}',
    );
    return _HiveTrainingTestStore(
      directory: directory,
      box: box,
      repository: HiveTrainingRepository(box),
    );
  }

  Future<void> dispose() async {
    await repository.dispose();
    await box.close();
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  }
}

class _MemoryTrainingRepository implements TrainingRepository {
  final List<TrainingEntry> entries = <TrainingEntry>[];

  @override
  Future<void> add(TrainingEntry entry) async {
    entries.add(entry);
  }

  @override
  Future<void> delete(TrainingEntry entry) async {
    entries.remove(entry);
  }

  @override
  Future<List<TrainingEntry>> getAll() async =>
      List<TrainingEntry>.from(entries);

  @override
  Future<List<TrainingEntry>> getRange(
    DateTime startInclusive,
    DateTime endExclusive,
  ) async {
    return entries
        .where((entry) => !entry.date.isBefore(startInclusive))
        .where((entry) => entry.date.isBefore(endExclusive))
        .toList(growable: false);
  }

  @override
  Future<List<TrainingEntry>> getRecent({
    required int limit,
    bool includeMatches = true,
    String? sportId,
  }) async {
    final sorted = entries.toList(growable: false)
      ..sort(TrainingEntry.compareByRecentCreated);
    return sorted.take(limit).toList(growable: false);
  }

  @override
  Future<void> update(int key, TrainingEntry entry) async {
    entries[key] = entry;
  }

  @override
  Stream<List<TrainingEntry>> watchAll() async* {
    yield List<TrainingEntry>.from(entries);
  }

  @override
  Stream<List<TrainingEntry>> watchRange(
    DateTime startInclusive,
    DateTime endExclusive,
  ) async* {
    yield await getRange(startInclusive, endExclusive);
  }

  @override
  Stream<List<TrainingEntry>> watchRecent({
    required int limit,
    bool includeMatches = true,
    String? sportId,
  }) async* {
    yield await getRecent(
      limit: limit,
      includeMatches: includeMatches,
      sportId: sportId,
    );
  }
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    if (value is List) return value.map((item) => item.toString()).toList();
    return defaults;
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    if (value is List) {
      return value.map((item) => int.tryParse(item.toString()) ?? 0).toList();
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
