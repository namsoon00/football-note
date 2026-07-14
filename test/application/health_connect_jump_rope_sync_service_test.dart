import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/health_connect_jump_rope_sync_service.dart';
import 'package:football_note/application/training_service.dart';
import 'package:football_note/domain/entities/sport_definition.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/repositories/training_repository.dart';

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
    expect(secondResult.duplicateCount, 1);
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
    );

    final result = await service.requestPermissionsAndSync(
      now: DateTime(2026, 7, 11, 9),
    );

    expect(result.importedCount, 1);
    expect(service.autoSyncEnabled, isTrue);
    expect(trainingRepository.entries.single.program, '줄넘기');
  });
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

class _FakeHealthConnectJumpRopePlatform
    implements HealthConnectJumpRopePlatform {
  bool permissionsGranted;
  final bool grantOnRequest;
  final List<HealthConnectJumpRopeSession> sessions;

  _FakeHealthConnectJumpRopePlatform({
    this.permissionsGranted = true,
    this.grantOnRequest = true,
    this.sessions = const <HealthConnectJumpRopeSession>[],
  });

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
    return sessions
        .where((session) => !session.startTime.isBefore(startInclusive))
        .where((session) => session.startTime.isBefore(endExclusive))
        .toList(growable: false);
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
