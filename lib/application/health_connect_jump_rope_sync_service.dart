import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/entities/sport_definition.dart';
import '../domain/entities/training_entry.dart';
import '../domain/repositories/option_repository.dart';
import 'health_connect_jump_rope_import_notification_service.dart';
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
      1,
      (durationMillis / Duration.millisecondsPerMinute).ceil(),
    );
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

class HealthConnectJumpRopeChanges {
  final List<HealthConnectJumpRopeSession> upsertedSessions;
  final List<String> removedRecordIds;
  final String nextChangesToken;
  final bool changesTokenExpired;
  final int scannedCount;

  const HealthConnectJumpRopeChanges({
    required this.upsertedSessions,
    required this.removedRecordIds,
    required this.nextChangesToken,
    required this.changesTokenExpired,
    required this.scannedCount,
  });

  factory HealthConnectJumpRopeChanges.fromMap(Map<dynamic, dynamic> map) {
    final rawSessions = map['upsertedSessions'] as List<dynamic>? ?? const [];
    final rawRemovedIds = map['removedRecordIds'] as List<dynamic>? ?? const [];
    return HealthConnectJumpRopeChanges(
      upsertedSessions: rawSessions
          .whereType<Map<dynamic, dynamic>>()
          .map(HealthConnectJumpRopeSession.fromMap)
          .where((session) => session.id.trim().isNotEmpty)
          .where((session) => session.durationMinutes > 0)
          .toList(growable: false),
      removedRecordIds: rawRemovedIds
          .map((id) => id.toString().trim())
          .where((id) => id.isNotEmpty)
          .toList(growable: false),
      nextChangesToken: map['nextChangesToken']?.toString().trim() ?? '',
      changesTokenExpired: map['changesTokenExpired'] as bool? ?? false,
      scannedCount: (map['scannedCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class HealthConnectJumpRopeSyncResult {
  final HealthConnectStatus status;
  final int scannedCount;
  final int importedCount;
  final int updatedCount;
  final int deletedCount;
  final int duplicateCount;
  final DateTime? syncedAt;

  const HealthConnectJumpRopeSyncResult({
    required this.status,
    required this.scannedCount,
    required this.importedCount,
    required this.updatedCount,
    required this.deletedCount,
    required this.duplicateCount,
    this.syncedAt,
  });

  const HealthConnectJumpRopeSyncResult.skipped({
    required this.status,
  })  : scannedCount = 0,
        importedCount = 0,
        updatedCount = 0,
        deletedCount = 0,
        duplicateCount = 0,
        syncedAt = null;
}

class HealthConnectJumpRopeDiagnostics {
  final HealthConnectStatus status;
  final bool notificationPermissionGranted;
  final bool samsungRecordDetected;
  final bool incrementalSyncReady;
  final int permissionDenialCount;
  final DateTime? lastSyncAt;
  final int lastScannedCount;
  final int lastImportCount;
  final int lastUpdateCount;
  final int lastDeleteCount;
  final int lastDuplicateCount;

  const HealthConnectJumpRopeDiagnostics({
    required this.status,
    required this.notificationPermissionGranted,
    required this.samsungRecordDetected,
    required this.incrementalSyncReady,
    required this.permissionDenialCount,
    required this.lastSyncAt,
    required this.lastScannedCount,
    required this.lastImportCount,
    required this.lastUpdateCount,
    required this.lastDeleteCount,
    required this.lastDuplicateCount,
  });
}

abstract class HealthConnectJumpRopePlatform {
  Future<HealthConnectStatus> status();
  Future<bool> requestPermissions();
  Future<List<HealthConnectJumpRopeSession>> readJumpRopeSessions({
    required DateTime startInclusive,
    required DateTime endExclusive,
  });
  Future<String> createChangesToken();
  Future<HealthConnectJumpRopeChanges> readChanges(String token);
  Future<bool> openManageAccess();
  Future<String?> consumeLaunchPayload();
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

  @override
  Future<String> createChangesToken() async {
    if (!_isAndroid) return '';
    return (await _channel.invokeMethod<String>('createChangesToken'))
            ?.trim() ??
        '';
  }

  @override
  Future<HealthConnectJumpRopeChanges> readChanges(String token) async {
    final raw = await _channel.invokeMapMethod<dynamic, dynamic>(
      'readChanges',
      <String, Object>{'token': token},
    );
    if (raw == null) {
      throw PlatformException(
        code: 'health_connect_empty_changes',
        message: 'Health Connect returned no changes response.',
      );
    }
    return HealthConnectJumpRopeChanges.fromMap(raw);
  }

  @override
  Future<bool> openManageAccess() async {
    if (!_isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('openManageAccess') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<String?> consumeLaunchPayload() async {
    if (!_isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('consumeLaunchPayload');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
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
  static const String samsungHealthPackageName = 'com.sec.android.app.shealth';
  static const String ownedRecordIdPrefix =
      'health_connect_jump_rope|$samsungHealthPackageName|';
  static const String _originDeviceId = 'health_connect:samsung_health';

  static const String autoSyncEnabledKey =
      'health_connect_jump_rope_auto_sync_enabled_v1';
  static const String syncedRecordIdsKey =
      'health_connect_jump_rope_synced_record_ids_v1';
  static const String changesTokenKey =
      'health_connect_jump_rope_changes_token_v1';
  static const String lastSyncAtKey =
      'health_connect_jump_rope_last_sync_at_v1';
  static const String lastScannedCountKey =
      'health_connect_jump_rope_last_scanned_count_v1';
  static const String lastImportCountKey =
      'health_connect_jump_rope_last_import_count_v1';
  static const String lastUpdateCountKey =
      'health_connect_jump_rope_last_update_count_v1';
  static const String lastDeleteCountKey =
      'health_connect_jump_rope_last_delete_count_v1';
  static const String lastDuplicateCountKey =
      'health_connect_jump_rope_last_duplicate_count_v1';
  static const String samsungRecordDetectedKey =
      'health_connect_jump_rope_samsung_record_detected_v1';
  static const String permissionDenialCountKey =
      'health_connect_jump_rope_permission_denial_count_v1';

  static const int defaultLookbackDays = 30;
  static const int _maxStoredRecordIds = 1000;

  final TrainingService _trainingService;
  final OptionRepository _optionRepository;
  final HealthConnectJumpRopePlatform _platform;
  final HealthConnectJumpRopeImportNotifier _importNotifier;

  HealthConnectJumpRopeSyncService({
    required TrainingService trainingService,
    required OptionRepository optionRepository,
    HealthConnectJumpRopePlatform platform =
        const MethodChannelHealthConnectJumpRopePlatform(),
    HealthConnectJumpRopeImportNotifier importNotifier =
        const NoopHealthConnectJumpRopeImportNotifier(),
  })  : _trainingService = trainingService,
        _optionRepository = optionRepository,
        _platform = platform,
        _importNotifier = importNotifier;

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

  Future<HealthConnectJumpRopeDiagnostics> diagnostics() async {
    final currentStatus = await status();
    final notificationPermissionGranted =
        await _importNotifier.permissionGranted();
    return HealthConnectJumpRopeDiagnostics(
      status: currentStatus,
      notificationPermissionGranted: notificationPermissionGranted,
      samsungRecordDetected:
          _optionRepository.getValue<bool>(samsungRecordDetectedKey) ?? false,
      incrementalSyncReady: _changesToken.isNotEmpty,
      permissionDenialCount:
          _optionRepository.getValue<int>(permissionDenialCountKey) ?? 0,
      lastSyncAt: lastSyncAt,
      lastScannedCount:
          _optionRepository.getValue<int>(lastScannedCountKey) ?? 0,
      lastImportCount: lastImportCount,
      lastUpdateCount: _optionRepository.getValue<int>(lastUpdateCountKey) ?? 0,
      lastDeleteCount: _optionRepository.getValue<int>(lastDeleteCountKey) ?? 0,
      lastDuplicateCount:
          _optionRepository.getValue<int>(lastDuplicateCountKey) ?? 0,
    );
  }

  Future<HealthConnectJumpRopeSyncResult> requestPermissionsAndSync({
    DateTime? now,
  }) async {
    final granted = await _platform.requestPermissions();
    if (!granted) {
      final previous =
          _optionRepository.getValue<int>(permissionDenialCountKey) ?? 0;
      await _optionRepository.setValue(permissionDenialCountKey, previous + 1);
      return HealthConnectJumpRopeSyncResult.skipped(
        status: await status(),
      );
    }
    await _optionRepository.setValue(permissionDenialCountKey, 0);
    await setAutoSyncEnabled(true);
    await _importNotifier.requestPermission();
    return syncRecent(now: now);
  }

  Future<bool> requestImportNotificationPermission() {
    return _importNotifier.requestPermission();
  }

  Future<String?> importNotificationLaunchPayload() {
    return _importNotifier.launchPayload();
  }

  Future<String?> healthConnectLaunchPayload() {
    return _platform.consumeLaunchPayload();
  }

  Future<bool> openManageAccess() {
    return _platform.openManageAccess();
  }

  Future<HealthConnectJumpRopeSyncResult> syncIfEnabled({
    DateTime? now,
  }) async {
    if (!autoSyncEnabled) {
      return const HealthConnectJumpRopeSyncResult.skipped(
        status: HealthConnectStatus.unavailable(),
      );
    }
    return syncRecent(now: now, notifyOnImport: true);
  }

  Future<HealthConnectJumpRopeSyncResult> syncRecent({
    DateTime? now,
    int lookbackDays = defaultLookbackDays,
    bool notifyOnImport = false,
  }) async {
    final currentStatus = await _platform.status();
    if (!currentStatus.isAvailable || !currentStatus.permissionsGranted) {
      return HealthConnectJumpRopeSyncResult.skipped(status: currentStatus);
    }

    final syncEndedAt = now ?? DateTime.now();
    final syncedIds = _syncedRecordIds();
    late final _SyncExecution execution;
    final token = _changesToken;
    if (token.isEmpty) {
      execution = await _bootstrapSync(
        syncEndedAt: syncEndedAt,
        lookbackDays: lookbackDays,
        syncedIds: syncedIds,
      );
    } else {
      final changes = await _platform.readChanges(token);
      execution = changes.changesTokenExpired
          ? await _bootstrapSync(
              syncEndedAt: syncEndedAt,
              lookbackDays: lookbackDays,
              syncedIds: syncedIds,
            )
          : await _applyIncrementalChanges(
              changes,
              syncedIds: syncedIds,
            );
    }

    await _optionRepository.setValue(
      syncedRecordIdsKey,
      _trimmedRecordIds(syncedIds.toList(growable: false)),
    );
    await _optionRepository.setValue(
      changesTokenKey,
      execution.nextChangesToken.trim(),
    );
    await _saveLastSync(execution.summary, syncEndedAt: syncEndedAt);

    if (notifyOnImport && execution.summary.importedCount > 0) {
      try {
        await _importNotifier.showImported(
          HealthConnectJumpRopeImportNotification(
            count: execution.summary.importedCount,
            importedAt: syncEndedAt,
            firstSessionStart: execution.summary.firstImportedSessionStart,
          ),
        );
      } catch (_) {
        // The imported records are already saved; notification can retry later.
      }
    }

    return HealthConnectJumpRopeSyncResult(
      status: currentStatus,
      scannedCount: execution.summary.scannedCount,
      importedCount: execution.summary.importedCount,
      updatedCount: execution.summary.updatedCount,
      deletedCount: execution.summary.deletedCount,
      duplicateCount: execution.summary.duplicateCount,
      syncedAt: syncEndedAt,
    );
  }

  Future<_SyncExecution> _bootstrapSync({
    required DateTime syncEndedAt,
    required int lookbackDays,
    required Set<String> syncedIds,
  }) async {
    final snapshotToken = (await _platform.createChangesToken()).trim();
    if (snapshotToken.isEmpty) {
      throw StateError('Health Connect returned an empty changes token.');
    }
    final snapshot = _samsungSessions(
      await _platform.readJumpRopeSessions(
        startInclusive: syncEndedAt.subtract(Duration(days: lookbackDays)),
        endExclusive: syncEndedAt.add(const Duration(minutes: 1)),
      ),
    );
    var summary = await _applyMutationBatch(
      upsertedSessions: snapshot,
      removedRecordIds: const <String>[],
      scannedCount: snapshot.length,
      syncedIds: syncedIds,
    );

    final changes = await _platform.readChanges(snapshotToken);
    if (changes.changesTokenExpired) {
      return _SyncExecution(summary: summary, nextChangesToken: '');
    }
    final incremental = await _applyMutationBatch(
      upsertedSessions: changes.upsertedSessions,
      removedRecordIds: changes.removedRecordIds,
      scannedCount: changes.scannedCount,
      syncedIds: syncedIds,
    );
    summary = summary.combine(incremental);
    return _SyncExecution(
      summary: summary,
      nextChangesToken: changes.nextChangesToken,
    );
  }

  Future<_SyncExecution> _applyIncrementalChanges(
    HealthConnectJumpRopeChanges changes, {
    required Set<String> syncedIds,
  }) async {
    final summary = await _applyMutationBatch(
      upsertedSessions: changes.upsertedSessions,
      removedRecordIds: changes.removedRecordIds,
      scannedCount: changes.scannedCount,
      syncedIds: syncedIds,
    );
    return _SyncExecution(
      summary: summary,
      nextChangesToken: changes.nextChangesToken,
    );
  }

  Future<_MutationSummary> _applyMutationBatch({
    required List<HealthConnectJumpRopeSession> upsertedSessions,
    required List<String> removedRecordIds,
    required int scannedCount,
    required Set<String> syncedIds,
  }) async {
    final sessions = _samsungSessions(upsertedSessions);
    final existingEntries = (await _trainingService.allEntries()).toList(
      growable: true,
    );
    final currentSportId = SportCatalog.normalizeSportId(
      SportService(_optionRepository).currentSportId(),
    );
    var importedCount = 0;
    var updatedCount = 0;
    var deletedCount = 0;
    var duplicateCount = 0;
    DateTime? firstImportedSessionStart;

    for (final session in sessions) {
      final ownedRecordId = _ownedRecordId(session.id);
      final payloadHash = _payloadHashForSession(session);
      final ownedIndex = existingEntries.indexWhere(
        (entry) => entry.effectiveRecordId == ownedRecordId,
      );
      if (ownedIndex >= 0) {
        final existing = existingEntries[ownedIndex];
        syncedIds.addAll(_syncKeysForSession(session));
        if (existing.payloadHash == payloadHash) {
          duplicateCount += 1;
          continue;
        }
        final key = existing.key;
        if (key is! int) {
          throw StateError('Stored Health Connect entry has no Hive key.');
        }
        final updated = _entryFromSession(
          session,
          sportId: existing.sportId,
          payloadHash: payloadHash,
        );
        await _trainingService.update(key, updated);
        await PlayerLevelService(
          _optionRepository,
          sportId: existing.sportId,
        ).awardForTrainingLogUpdate(
          previousEntry: existing,
          updatedEntry: updated,
        );
        existingEntries[ownedIndex] = updated;
        updatedCount += 1;
        continue;
      }

      final syncKeys = _syncKeysForSession(session);
      final isLegacyDuplicate = syncKeys.any(syncedIds.contains) ||
          _matchesExistingEntry(session, existingEntries);
      if (isLegacyDuplicate) {
        duplicateCount += 1;
        syncedIds.addAll(syncKeys);
        continue;
      }

      final entry = _entryFromSession(
        session,
        sportId: currentSportId,
        payloadHash: payloadHash,
      );
      await _trainingService.add(entry);
      final persistedEntry = (await _trainingService.allEntries()).firstWhere(
        (candidate) => candidate.effectiveRecordId == entry.effectiveRecordId,
        orElse: () => entry,
      );
      await PlayerLevelService(
        _optionRepository,
        sportId: currentSportId,
      ).awardForTrainingLog(
        entry: persistedEntry,
        existingEntries: existingEntries,
      );
      existingEntries.add(persistedEntry);
      importedCount += 1;
      firstImportedSessionStart ??= session.startTime;
      syncedIds.addAll(syncKeys);
    }

    for (final sourceRecordId in removedRecordIds) {
      final normalizedId = sourceRecordId.trim();
      if (normalizedId.isEmpty) continue;
      final ownedIndex = existingEntries.indexWhere(
        (entry) => entry.effectiveRecordId == _ownedRecordId(normalizedId),
      );
      if (ownedIndex < 0) continue;
      final existing = existingEntries[ownedIndex];
      if (existing.key is! int) {
        throw StateError('Stored Health Connect entry has no Hive key.');
      }
      await PlayerLevelService(
        _optionRepository,
        sportId: existing.sportId,
      ).revokeTrainingEntryAward(existing);
      await _trainingService.delete(existing);
      existingEntries.removeAt(ownedIndex);
      deletedCount += 1;
    }

    if (sessions.isNotEmpty) {
      await _optionRepository.setValue(samsungRecordDetectedKey, true);
    }
    return _MutationSummary(
      scannedCount: scannedCount,
      importedCount: importedCount,
      updatedCount: updatedCount,
      deletedCount: deletedCount,
      duplicateCount: duplicateCount,
      firstImportedSessionStart: firstImportedSessionStart,
    );
  }

  Future<void> _saveLastSync(
    _MutationSummary summary, {
    required DateTime syncEndedAt,
  }) async {
    await _optionRepository.setValue(
      lastSyncAtKey,
      syncEndedAt.toIso8601String(),
    );
    await _optionRepository.setValue(lastScannedCountKey, summary.scannedCount);
    await _optionRepository.setValue(lastImportCountKey, summary.importedCount);
    await _optionRepository.setValue(lastUpdateCountKey, summary.updatedCount);
    await _optionRepository.setValue(lastDeleteCountKey, summary.deletedCount);
    await _optionRepository.setValue(
      lastDuplicateCountKey,
      summary.duplicateCount,
    );
  }

  TrainingEntry _entryFromSession(
    HealthConnectJumpRopeSession session, {
    required String sportId,
    required String payloadHash,
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
      recordId: _ownedRecordId(session.id),
      originDeviceId: _originDeviceId,
      payloadHash: payloadHash,
    );
  }

  String get _changesToken =>
      _optionRepository.getValue<String>(changesTokenKey)?.trim() ?? '';

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

  List<HealthConnectJumpRopeSession> _samsungSessions(
    List<HealthConnectJumpRopeSession> sessions,
  ) {
    return sessions
        .where(
          (session) => session.sourcePackage.trim() == samsungHealthPackageName,
        )
        .where((session) => session.id.trim().isNotEmpty)
        .where((session) => session.durationMinutes > 0)
        .toList(growable: false);
  }

  String _ownedRecordId(String sourceRecordId) {
    return '$ownedRecordIdPrefix${sourceRecordId.trim()}';
  }

  String _payloadHashForSession(HealthConnectJumpRopeSession session) {
    return <Object>[
      'healthConnectJumpRopePayloadV1',
      session.sourcePackage.trim(),
      session.id.trim(),
      session.startTime.millisecondsSinceEpoch,
      session.endTime.millisecondsSinceEpoch,
      session.durationMillis,
      session.jumpCount,
      session.title.trim(),
      session.matchedBySegment,
    ].join('|');
  }

  List<String> _syncKeysForSession(HealthConnectJumpRopeSession session) {
    final id = session.id.trim();
    final fingerprint = <Object>[
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

class _SyncExecution {
  final _MutationSummary summary;
  final String nextChangesToken;

  const _SyncExecution({
    required this.summary,
    required this.nextChangesToken,
  });
}

class _MutationSummary {
  final int scannedCount;
  final int importedCount;
  final int updatedCount;
  final int deletedCount;
  final int duplicateCount;
  final DateTime? firstImportedSessionStart;

  const _MutationSummary({
    required this.scannedCount,
    required this.importedCount,
    required this.updatedCount,
    required this.deletedCount,
    required this.duplicateCount,
    required this.firstImportedSessionStart,
  });

  _MutationSummary combine(_MutationSummary other) {
    return _MutationSummary(
      scannedCount: scannedCount + other.scannedCount,
      importedCount: importedCount + other.importedCount,
      updatedCount: updatedCount + other.updatedCount,
      deletedCount: deletedCount + other.deletedCount,
      duplicateCount: duplicateCount + other.duplicateCount,
      firstImportedSessionStart:
          firstImportedSessionStart ?? other.firstImportedSessionStart,
    );
  }
}
