import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/entities/sport_definition.dart';
import '../domain/entities/training_entry.dart';
import '../domain/repositories/option_repository.dart';
import 'player_level_service.dart';
import 'sport_service.dart';
import 'training_service.dart';

enum HealthConnectAvailabilityState {
  available,
  updateRequired,
  unavailable,
}

class HealthConnectStatus {
  final HealthConnectAvailabilityState availability;
  final bool permissionsGranted;

  const HealthConnectStatus({
    required this.availability,
    required this.permissionsGranted,
  });

  const HealthConnectStatus.unavailable()
      : availability = HealthConnectAvailabilityState.unavailable,
        permissionsGranted = false;

  bool get isAvailable =>
      availability == HealthConnectAvailabilityState.available;
}

class HealthConnectJumpRopeSession {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMillis;
  final int jumpCount;
  final String title;
  final String sourcePackage;
  final bool matchedBySegment;

  const HealthConnectJumpRopeSession({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.durationMillis,
    required this.jumpCount,
    required this.title,
    required this.sourcePackage,
    required this.matchedBySegment,
  });

  int get durationMinutes {
    if (durationMillis <= 0) return 0;
    return math.max(
        1, (durationMillis / Duration.millisecondsPerMinute).ceil());
  }

  factory HealthConnectJumpRopeSession.fromMap(Map<dynamic, dynamic> map) {
    final startEpochMillis = (map['startEpochMillis'] as num?)?.toInt() ?? 0;
    final endEpochMillis = (map['endEpochMillis'] as num?)?.toInt() ?? 0;
    return HealthConnectJumpRopeSession(
      id: map['id']?.toString() ?? '',
      startTime: DateTime.fromMillisecondsSinceEpoch(startEpochMillis),
      endTime: DateTime.fromMillisecondsSinceEpoch(endEpochMillis),
      durationMillis: (map['durationMillis'] as num?)?.toInt() ?? 0,
      jumpCount: (map['jumpCount'] as num?)?.toInt() ?? 0,
      title: map['title']?.toString() ?? '',
      sourcePackage: map['sourcePackage']?.toString() ?? '',
      matchedBySegment: map['matchedBySegment'] as bool? ?? false,
    );
  }
}

class HealthConnectJumpRopeSyncResult {
  final HealthConnectStatus status;
  final int scannedCount;
  final int importedCount;
  final int duplicateCount;
  final DateTime? syncedAt;

  const HealthConnectJumpRopeSyncResult({
    required this.status,
    required this.scannedCount,
    required this.importedCount,
    required this.duplicateCount,
    this.syncedAt,
  });

  const HealthConnectJumpRopeSyncResult.skipped({
    required this.status,
  })  : scannedCount = 0,
        importedCount = 0,
        duplicateCount = 0,
        syncedAt = null;
}

abstract class HealthConnectJumpRopePlatform {
  Future<HealthConnectStatus> status();
  Future<bool> requestPermissions();
  Future<List<HealthConnectJumpRopeSession>> readJumpRopeSessions({
    required DateTime startInclusive,
    required DateTime endExclusive,
  });
}

class MethodChannelHealthConnectJumpRopePlatform
    implements HealthConnectJumpRopePlatform {
  static const MethodChannel _channel = MethodChannel(
    'com.namsoon.footballnote/health_connect',
  );

  const MethodChannelHealthConnectJumpRopePlatform();

  @override
  Future<HealthConnectStatus> status() async {
    if (!_isAndroid) return const HealthConnectStatus.unavailable();
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>('getStatus');
      return _statusFromMap(raw);
    } on MissingPluginException {
      return const HealthConnectStatus.unavailable();
    } on PlatformException {
      return const HealthConnectStatus.unavailable();
    }
  }

  @override
  Future<bool> requestPermissions() async {
    if (!_isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('requestPermissions') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<List<HealthConnectJumpRopeSession>> readJumpRopeSessions({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    if (!_isAndroid) return const <HealthConnectJumpRopeSession>[];
    final raw = await _channel.invokeListMethod<dynamic>(
      'readJumpRopeSessions',
      <String, Object>{
        'startEpochMillis': startInclusive.millisecondsSinceEpoch,
        'endEpochMillis': endExclusive.millisecondsSinceEpoch,
      },
    );
    if (raw == null) return const <HealthConnectJumpRopeSession>[];
    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map(HealthConnectJumpRopeSession.fromMap)
        .where((session) => session.id.trim().isNotEmpty)
        .where((session) => session.durationMinutes > 0)
        .toList(growable: false);
  }

  HealthConnectStatus _statusFromMap(Map<String, dynamic>? raw) {
    if (raw == null) return const HealthConnectStatus.unavailable();
    final availability = switch (raw['availability']?.toString()) {
      'available' => HealthConnectAvailabilityState.available,
      'updateRequired' => HealthConnectAvailabilityState.updateRequired,
      _ => HealthConnectAvailabilityState.unavailable,
    };
    return HealthConnectStatus(
      availability: availability,
      permissionsGranted: raw['permissionsGranted'] as bool? ?? false,
    );
  }

  static bool get isSupportedDevice =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get _isAndroid => isSupportedDevice;
}

class HealthConnectJumpRopeSyncService {
  static const String autoSyncEnabledKey =
      'health_connect_jump_rope_auto_sync_enabled_v1';
  static const String syncedRecordIdsKey =
      'health_connect_jump_rope_synced_record_ids_v1';
  static const String lastSyncAtKey =
      'health_connect_jump_rope_last_sync_at_v1';
  static const String lastImportCountKey =
      'health_connect_jump_rope_last_import_count_v1';

  static const int defaultLookbackDays = 30;
  static const int _maxStoredRecordIds = 1000;

  final TrainingService _trainingService;
  final OptionRepository _optionRepository;
  final HealthConnectJumpRopePlatform _platform;

  HealthConnectJumpRopeSyncService({
    required TrainingService trainingService,
    required OptionRepository optionRepository,
    HealthConnectJumpRopePlatform platform =
        const MethodChannelHealthConnectJumpRopePlatform(),
  })  : _trainingService = trainingService,
        _optionRepository = optionRepository,
        _platform = platform;

  bool get autoSyncEnabled =>
      _optionRepository.getValue<bool>(autoSyncEnabledKey) ?? false;

  DateTime? get lastSyncAt {
    final raw = _optionRepository.getValue<String>(lastSyncAtKey);
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  int get lastImportCount =>
      _optionRepository.getValue<int>(lastImportCountKey) ?? 0;

  Future<void> setAutoSyncEnabled(bool enabled) {
    return _optionRepository.setValue(autoSyncEnabledKey, enabled);
  }

  Future<HealthConnectStatus> status() => _platform.status();

  Future<HealthConnectJumpRopeSyncResult> requestPermissionsAndSync({
    DateTime? now,
  }) async {
    final granted = await _platform.requestPermissions();
    if (!granted) {
      return HealthConnectJumpRopeSyncResult.skipped(
        status: await status(),
      );
    }
    await setAutoSyncEnabled(true);
    return syncRecent(now: now);
  }

  Future<HealthConnectJumpRopeSyncResult> syncIfEnabled({
    DateTime? now,
  }) async {
    if (!autoSyncEnabled) {
      return const HealthConnectJumpRopeSyncResult.skipped(
        status: HealthConnectStatus.unavailable(),
      );
    }
    return syncRecent(now: now);
  }

  Future<HealthConnectJumpRopeSyncResult> syncRecent({
    DateTime? now,
    int lookbackDays = defaultLookbackDays,
  }) async {
    final currentStatus = await _platform.status();
    if (!currentStatus.isAvailable || !currentStatus.permissionsGranted) {
      return HealthConnectJumpRopeSyncResult.skipped(status: currentStatus);
    }

    final syncEndedAt = now ?? DateTime.now();
    final sessions = await _platform.readJumpRopeSessions(
      startInclusive: syncEndedAt.subtract(Duration(days: lookbackDays)),
      endExclusive: syncEndedAt.add(const Duration(minutes: 1)),
    );
    final syncedIds = _syncedRecordIds();
    final existingEntries = await _trainingService.allEntries();
    final sportId = SportCatalog.normalizeSportId(
      SportService(_optionRepository).currentSportId(),
    );

    var importedCount = 0;
    var duplicateCount = 0;
    final nextSyncedIds = syncedIds.toList(growable: true);
    for (final session in sessions) {
      final recordId = session.id.trim();
      final syncKeys = _syncKeysForSession(session);
      final alreadyImported = syncKeys.any(syncedIds.contains) ||
          _matchesExistingEntry(session, existingEntries);
      if (recordId.isEmpty || alreadyImported) {
        duplicateCount += 1;
        if (recordId.isNotEmpty && alreadyImported) {
          nextSyncedIds.addAll(syncKeys);
          syncedIds.addAll(syncKeys);
        }
        continue;
      }

      final entry = _entryFromSession(session, sportId: sportId);
      await _trainingService.add(entry);
      await PlayerLevelService(
        _optionRepository,
        sportId: sportId,
      ).awardForTrainingLog(
        entry: entry,
        existingEntries: existingEntries,
      );
      existingEntries.add(entry);
      importedCount += 1;
      nextSyncedIds.addAll(syncKeys);
      syncedIds.addAll(syncKeys);
    }

    await _optionRepository.setValue(
      syncedRecordIdsKey,
      _trimmedRecordIds(nextSyncedIds),
    );
    await _optionRepository.setValue(
      lastSyncAtKey,
      syncEndedAt.toIso8601String(),
    );
    await _optionRepository.setValue(lastImportCountKey, importedCount);

    return HealthConnectJumpRopeSyncResult(
      status: currentStatus,
      scannedCount: sessions.length,
      importedCount: importedCount,
      duplicateCount: duplicateCount,
      syncedAt: syncEndedAt,
    );
  }

  TrainingEntry _entryFromSession(
    HealthConnectJumpRopeSession session, {
    required String sportId,
  }) {
    final label = session.title.trim();
    final minutes = session.durationMinutes;
    final day = DateTime(
      session.startTime.year,
      session.startTime.month,
      session.startTime.day,
    );
    return TrainingEntry(
      date: day,
      sportId: sportId,
      durationMinutes: minutes,
      intensity: 3,
      type: label,
      mood: 3,
      injury: false,
      notes: '',
      location: '',
      program: label,
      trainingProgramMinutes:
          label.isEmpty ? const <String, int>{} : <String, int>{label: minutes},
      createdAt: session.startTime,
      jumpRopeCount: session.jumpCount,
      jumpRopeMinutes: minutes,
      jumpRopeEnabled: true,
      jumpRopeNote: '',
    );
  }

  Set<String> _syncedRecordIds() {
    return _optionRepository
        .getOptions(syncedRecordIdsKey, const <String>[])
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  List<String> _trimmedRecordIds(List<String> ids) {
    final unique = <String>[];
    final seen = <String>{};
    for (final id in ids) {
      final normalized = id.trim();
      if (normalized.isEmpty || !seen.add(normalized)) continue;
      unique.add(normalized);
    }
    if (unique.length <= _maxStoredRecordIds) return unique;
    return unique.sublist(unique.length - _maxStoredRecordIds);
  }

  List<String> _syncKeysForSession(HealthConnectJumpRopeSession session) {
    final id = session.id.trim();
    final fingerprint = [
      'healthConnectJumpRope',
      session.sourcePackage.trim(),
      session.startTime.millisecondsSinceEpoch,
      session.endTime.millisecondsSinceEpoch,
      session.durationMillis,
    ].join('|');
    return <String>[
      if (id.isNotEmpty) id,
      fingerprint,
    ];
  }

  bool _matchesExistingEntry(
    HealthConnectJumpRopeSession session,
    List<TrainingEntry> entries,
  ) {
    final sessionDay = DateTime(
      session.startTime.year,
      session.startTime.month,
      session.startTime.day,
    );
    return entries.any((entry) {
      if (!entry.jumpRopeEnabled) return false;
      if (entry.createdAt != session.startTime) return false;
      if (entry.date != sessionDay) return false;
      if (entry.jumpRopeMinutes != session.durationMinutes) return false;
      if (session.jumpCount > 0 && entry.jumpRopeCount != session.jumpCount) {
        return false;
      }
      return true;
    });
  }
}
