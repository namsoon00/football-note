import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'family_access_service.dart';

enum RestoreMode {
  safeMerge,
  addMissingOnly,
  exactReplace,
}

enum RestoreOperationType {
  add,
  update,
  conflict,
  tombstone,
  skip,
}

enum RestoreOperationCategory {
  training,
  option,
  asset,
  metadata,
}

class BackupCategoryCounts {
  const BackupCategoryCounts({
    this.trainingEntries = 0,
    this.options = 0,
    this.assets = 0,
  });

  final int trainingEntries;
  final int options;
  final int assets;

  int get total => trainingEntries + options + assets;

  Map<String, int> toMap() {
    return <String, int>{
      'trainingEntries': trainingEntries,
      'options': options,
      'assets': assets,
      'total': total,
    };
  }
}

class BackupSnapshotDescriptor {
  const BackupSnapshotDescriptor({
    required this.format,
    required this.version,
    required this.createdAt,
    required this.role,
    required this.familyId,
    required this.playerId,
    required this.datasetId,
    required this.accountEmail,
    required this.accountLabel,
    required this.accountSubjectId,
    required this.contentHash,
    required this.integrityVerified,
    required this.counts,
    this.firstTrainingAt,
    this.lastTrainingAt,
  });

  final String format;
  final int version;
  final DateTime? createdAt;
  final FamilyRole? role;
  final String familyId;
  final String playerId;
  final String datasetId;
  final String accountEmail;
  final String accountLabel;
  final String accountSubjectId;
  final String contentHash;
  final bool integrityVerified;
  final BackupCategoryCounts counts;
  final DateTime? firstTrainingAt;
  final DateTime? lastTrainingAt;

  bool get hasCoreData => counts.trainingEntries > 0 || counts.options > 0;
}

class RestoreOperation {
  const RestoreOperation({
    required this.type,
    required this.category,
    required this.recordId,
    required this.label,
    required this.reason,
    this.localHash,
    this.remoteHash,
  });

  final RestoreOperationType type;
  final RestoreOperationCategory category;
  final String recordId;
  final String label;
  final String reason;
  final String? localHash;
  final String? remoteHash;
}

class RestorePlan {
  const RestorePlan({
    required this.source,
    required this.target,
    required this.mode,
    required this.planHash,
    required this.beforeSummary,
    required this.afterSummary,
    required this.warnings,
    required this.operations,
  });

  final BackupSnapshotDescriptor source;
  final BackupSnapshotDescriptor target;
  final RestoreMode mode;
  final String planHash;
  final Map<String, int> beforeSummary;
  final Map<String, int> afterSummary;
  final List<String> warnings;
  final List<RestoreOperation> operations;

  int count(RestoreOperationType type) {
    return operations.where((operation) => operation.type == type).length;
  }

  int categoryCount(
    RestoreOperationCategory category,
    RestoreOperationType type,
  ) {
    return operations
        .where(
          (operation) =>
              operation.category == category && operation.type == type,
        )
        .length;
  }

  bool get hasConflicts => count(RestoreOperationType.conflict) > 0;
}

class RestoreReceipt {
  const RestoreReceipt({
    required this.planHash,
    required this.applied,
    required this.updated,
    required this.skipped,
    required this.conflicts,
    required this.deleted,
  });

  final String planHash;
  final int applied;
  final int updated;
  final int skipped;
  final int conflicts;
  final int deleted;
}

class BackupRestorePlanner {
  static const String backupFormatValue = 'teo_note_backup';
  static const String contributionFormatValue = 'teo_note_family_contribution';
  static const String entryRecordIdKey = 'recordId';
  static const String entryUpdatedAtKey = 'updatedAt';
  static const String entryRevisionKey = 'revision';
  static const String entryOriginDeviceIdKey = 'originDeviceId';
  static const String entryPayloadHashKey = 'payloadHash';
  static const String entryDeletedAtKey = 'deletedAt';
  static const String safetyManifestKey = 'safetyManifest';
  static const String optionRecordsKey = 'optionRecords';
  static const String familyMetadataKey = 'family';
  static const String driveAccountMetadataKey = 'driveAccount';
  static const String assetRecordsKey = 'assetRecords';

  static const Set<String> syncMetadataKeys = <String>{
    entryRecordIdKey,
    entryUpdatedAtKey,
    entryRevisionKey,
    entryOriginDeviceIdKey,
    entryPayloadHashKey,
    entryDeletedAtKey,
  };

  const BackupRestorePlanner();

  BackupSnapshotDescriptor describe(Map<String, dynamic> backup) {
    final entries = _entryRecords(backup);
    DateTime? firstTrainingAt;
    DateTime? lastTrainingAt;
    for (final entry in entries) {
      final parsed = _parseDateTime(entry['date']);
      if (parsed == null) continue;
      if (firstTrainingAt == null || parsed.isBefore(firstTrainingAt)) {
        firstTrainingAt = parsed;
      }
      if (lastTrainingAt == null || parsed.isAfter(lastTrainingAt)) {
        lastTrainingAt = parsed;
      }
    }
    final options = _optionRecordsByKey(backup);
    final assets = backup[assetRecordsKey];
    final family = _stringMap(backup[familyMetadataKey]);
    final manifest = _stringMap(backup[safetyManifestKey]);
    final driveAccount = _stringMap(backup[driveAccountMetadataKey]);
    final roleRaw = family['updatedByRole']?.toString();
    return BackupSnapshotDescriptor(
      format: backup['format']?.toString() ?? backupFormatValue,
      version: (backup['version'] as num?)?.toInt() ?? 1,
      createdAt: _parseDateTime(backup['createdAt']),
      role:
          roleRaw == null ? null : FamilyAccessService.roleFromStorage(roleRaw),
      familyId: _firstNonEmpty([
        family['familyId']?.toString(),
        options[FamilyAccessService.familyIdKey]?.toString(),
        manifest['familyId']?.toString(),
      ]),
      playerId: _firstNonEmpty([
        family['playerId']?.toString(),
        manifest['playerId']?.toString(),
      ]),
      datasetId: manifest['datasetId']?.toString().trim() ?? '',
      accountEmail: _firstNonEmpty([
        driveAccount['email']?.toString(),
        manifest['accountEmail']?.toString(),
      ]),
      accountLabel: driveAccount['label']?.toString().trim() ?? '',
      accountSubjectId: _firstNonEmpty([
        driveAccount['subjectId']?.toString(),
        manifest['accountSubjectId']?.toString(),
      ]),
      contentHash: manifest['contentHash']?.toString().trim().isNotEmpty == true
          ? manifest['contentHash'].toString().trim()
          : stableBackupContentHash(backup),
      integrityVerified: manifest['hashAlgorithm'] == 'sha256' &&
          manifest['contentHash'] == stableBackupContentHash(backup),
      counts: BackupCategoryCounts(
        trainingEntries: entries.length,
        options: options.length,
        assets: assets is Map ? assets.length : 0,
      ),
      firstTrainingAt: firstTrainingAt,
      lastTrainingAt: lastTrainingAt,
    );
  }

  RestorePlan buildPlan({
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
    required RestoreMode mode,
    required Map<String, String> baselineEntryHashes,
    required Map<String, String> baselineOptionHashes,
  }) {
    final localEntries = _recordsById(
      _entryRecords(local),
      idForRecord: trainingRecordId,
      hashForRecord: entryPayloadHash,
    );
    final remoteEntries = _recordsById(
      _entryRecords(remote),
      idForRecord: trainingRecordId,
      hashForRecord: entryPayloadHash,
    );
    final localOptions = _optionRecordsByKey(local);
    final remoteOptions = _optionRecordsByKey(remote);
    final operations = <RestoreOperation>[
      ..._planRecordSet(
        category: RestoreOperationCategory.training,
        local: localEntries,
        remote: remoteEntries,
        baselineHashes: baselineEntryHashes,
        mode: mode,
      ),
      ..._planRecordSet(
        category: RestoreOperationCategory.option,
        local: localOptions.map(
          (key, value) => MapEntry(
            key,
            _MergeRecord(
              id: key,
              label: key,
              payload: <String, dynamic>{'key': key, 'value': value},
              payloadHash: optionPayloadHash(value),
              hasStableIdentity: true,
              deletedAt: null,
            ),
          ),
        ),
        remote: remoteOptions.map(
          (key, value) => MapEntry(
            key,
            _MergeRecord(
              id: key,
              label: key,
              payload: <String, dynamic>{'key': key, 'value': value},
              payloadHash: optionPayloadHash(value),
              hasStableIdentity: true,
              deletedAt: null,
            ),
          ),
        ),
        baselineHashes: baselineOptionHashes,
        mode: mode,
      ),
    ];

    final warnings = <String>[
      if (operations.any((operation) =>
          operation.type == RestoreOperationType.conflict &&
          operation.reason == 'missing_stable_identity'))
        'legacy_records_need_review',
      if (operations.any(
        (operation) => operation.type == RestoreOperationType.conflict,
      ))
        'conflicts_require_review',
    ];
    final source = describe(remote);
    final target = describe(local);
    final beforeSummary = target.counts.toMap();
    final afterSummary = <String, int>{
      'trainingEntries': target.counts.trainingEntries +
          operations
              .where(
                (operation) =>
                    operation.category == RestoreOperationCategory.training &&
                    operation.type == RestoreOperationType.add,
              )
              .length,
      'options': target.counts.options +
          operations
              .where(
                (operation) =>
                    operation.category == RestoreOperationCategory.option &&
                    operation.type == RestoreOperationType.add,
              )
              .length,
      'assets': target.counts.assets,
    };
    afterSummary['total'] = (afterSummary['trainingEntries'] ?? 0) +
        (afterSummary['options'] ?? 0) +
        (afterSummary['assets'] ?? 0);
    final planHash = sha256
        .convert(
          utf8.encode(
            jsonEncode(
              _canonicalJson(<String, dynamic>{
                'mode': mode.name,
                'source': source.contentHash,
                'target': target.contentHash,
                'operations': operations
                    .map(
                      (operation) => <String, dynamic>{
                        'type': operation.type.name,
                        'category': operation.category.name,
                        'recordId': operation.recordId,
                        'localHash': operation.localHash,
                        'remoteHash': operation.remoteHash,
                      },
                    )
                    .toList(growable: false),
              }),
            ),
          ),
        )
        .toString();
    return RestorePlan(
      source: source,
      target: target,
      mode: mode,
      planHash: planHash,
      beforeSummary: beforeSummary,
      afterSummary: afterSummary,
      warnings: warnings,
      operations: List<RestoreOperation>.unmodifiable(operations),
    );
  }

  static String stableBackupContentHash(Map<String, dynamic> backup) {
    final canonical = jsonEncode(
      _canonicalJson(<String, dynamic>{
        'entries': backup['entries'] ?? const <dynamic>[],
        optionRecordsKey: _extractOptionRecords(backup),
        familyMetadataKey: backup[familyMetadataKey],
        assetRecordsKey: backup[assetRecordsKey],
      }),
    );
    return sha256.convert(utf8.encode(canonical)).toString();
  }

  static String entryPayloadHash(Map<String, dynamic> entry) {
    final payload = <String, dynamic>{};
    for (final item in entry.entries) {
      if (syncMetadataKeys.contains(item.key)) continue;
      payload[item.key] = item.value;
    }
    return sha256
        .convert(utf8.encode(jsonEncode(_canonicalJson(payload))))
        .toString();
  }

  static String optionPayloadHash(dynamic value) {
    return sha256
        .convert(utf8.encode(jsonEncode(_canonicalJson(value))))
        .toString();
  }

  static String trainingRecordId(Map<String, dynamic> entry) {
    final explicit = entry[entryRecordIdKey]?.toString().trim() ?? '';
    if (explicit.isNotEmpty) return explicit;
    final legacy = legacyTrainingRecordId(entry['createdAt']);
    if (legacy.isNotEmpty) return legacy;
    return '';
  }

  static String legacyTrainingRecordId(Object? createdAt) {
    final parsed = _parseDateTime(createdAt);
    if (parsed == null) return '';
    return 'training_${parsed.toUtc().microsecondsSinceEpoch}';
  }

  static List<Map<String, dynamic>> _entryRecords(Map<String, dynamic> backup) {
    final entries = backup['entries'];
    if (entries is! List) return const <Map<String, dynamic>>[];
    return entries
        .whereType<Map>()
        .map((entry) =>
            entry.map((key, value) => MapEntry(key.toString(), value)))
        .toList(growable: false);
  }

  static Map<String, dynamic> _optionRecordsByKey(Map<String, dynamic> backup) {
    final result = <String, dynamic>{};
    for (final record in _extractOptionRecords(backup)) {
      final key = record['key'];
      if (key is! String || key.trim().isEmpty) continue;
      result[key] = record['value'];
    }
    return result;
  }

  static List<Map<String, dynamic>> _extractOptionRecords(
    Map<String, dynamic> backup,
  ) {
    final raw = backup[optionRecordsKey];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) =>
              item.map((key, value) => MapEntry(key.toString(), value)))
          .toList(growable: true);
    }
    final options = backup['options'];
    if (options is! Map) {
      return <Map<String, dynamic>>[];
    }
    return options.entries
        .map(
          (entry) => <String, dynamic>{
            'key': entry.key.toString(),
            'value': entry.value,
          },
        )
        .toList(growable: true);
  }

  Map<String, _MergeRecord> _recordsById(
    Iterable<Map<String, dynamic>> records, {
    required String Function(Map<String, dynamic>) idForRecord,
    required String Function(Map<String, dynamic>) hashForRecord,
  }) {
    final result = <String, _MergeRecord>{};
    final ambiguous = <String>{};
    for (final payload in records) {
      final id = idForRecord(payload);
      final hash = hashForRecord(payload);
      final stable = id.isNotEmpty;
      final key = stable ? id : 'legacy-import-candidate:$hash';
      if (result.containsKey(key)) {
        ambiguous.add(key);
      }
      result[key] = _MergeRecord(
        id: key,
        label: stable ? key : 'Legacy record without ID',
        payload: payload,
        payloadHash: hash,
        hasStableIdentity: stable,
        deletedAt: _parseDateTime(payload[entryDeletedAtKey]),
      );
    }
    for (final key in ambiguous) {
      final record = result[key];
      if (record == null) continue;
      result[key] = record.copyWith(hasStableIdentity: false);
    }
    return result;
  }

  Iterable<RestoreOperation> _planRecordSet({
    required RestoreOperationCategory category,
    required Map<String, _MergeRecord> local,
    required Map<String, _MergeRecord> remote,
    required Map<String, String> baselineHashes,
    required RestoreMode mode,
  }) sync* {
    final ids = <String>{...local.keys, ...remote.keys}.toList(growable: false)
      ..sort();
    for (final id in ids) {
      final localRecord = local[id];
      final remoteRecord = remote[id];
      if (remoteRecord != null && !remoteRecord.hasStableIdentity) {
        yield RestoreOperation(
          type: RestoreOperationType.conflict,
          category: category,
          recordId: id,
          label: remoteRecord.label,
          reason: 'missing_stable_identity',
          localHash: localRecord?.payloadHash,
          remoteHash: remoteRecord.payloadHash,
        );
        continue;
      }
      if (remoteRecord == null) {
        yield RestoreOperation(
          type: RestoreOperationType.skip,
          category: category,
          recordId: id,
          label: localRecord?.label ?? id,
          reason: 'local_only_kept',
          localHash: localRecord?.payloadHash,
        );
        continue;
      }
      if (localRecord == null) {
        yield RestoreOperation(
          type: remoteRecord.deletedAt == null
              ? RestoreOperationType.add
              : RestoreOperationType.skip,
          category: category,
          recordId: id,
          label: remoteRecord.label,
          reason: remoteRecord.deletedAt == null
              ? 'remote_only'
              : 'remote_tombstone_without_local_record',
          remoteHash: remoteRecord.payloadHash,
        );
        continue;
      }
      if (mode == RestoreMode.addMissingOnly) {
        yield RestoreOperation(
          type: RestoreOperationType.conflict,
          category: category,
          recordId: id,
          label: remoteRecord.label,
          reason: 'different_existing_record_not_updated',
          localHash: localRecord.payloadHash,
          remoteHash: remoteRecord.payloadHash,
        );
        continue;
      }
      final baselineHash = baselineHashes[id];
      if (remoteRecord.deletedAt != null) {
        yield RestoreOperation(
          type: baselineHash != null && localRecord.payloadHash == baselineHash
              ? RestoreOperationType.tombstone
              : RestoreOperationType.conflict,
          category: category,
          recordId: id,
          label: remoteRecord.label,
          reason:
              baselineHash != null && localRecord.payloadHash == baselineHash
                  ? 'explicit_tombstone'
                  : 'delete_vs_local_edit',
          localHash: localRecord.payloadHash,
          remoteHash: remoteRecord.payloadHash,
        );
        continue;
      }
      if (localRecord.payloadHash == remoteRecord.payloadHash) {
        yield RestoreOperation(
          type: RestoreOperationType.skip,
          category: category,
          recordId: id,
          label: remoteRecord.label,
          reason: 'identical',
          localHash: localRecord.payloadHash,
          remoteHash: remoteRecord.payloadHash,
        );
        continue;
      }
      if (baselineHash == null) {
        yield RestoreOperation(
          type: RestoreOperationType.conflict,
          category: category,
          recordId: id,
          label: remoteRecord.label,
          reason: 'no_baseline_for_update',
          localHash: localRecord.payloadHash,
          remoteHash: remoteRecord.payloadHash,
        );
        continue;
      }
      if (localRecord.payloadHash == baselineHash) {
        yield RestoreOperation(
          type: RestoreOperationType.update,
          category: category,
          recordId: id,
          label: remoteRecord.label,
          reason: 'remote_changed_local_unchanged',
          localHash: localRecord.payloadHash,
          remoteHash: remoteRecord.payloadHash,
        );
        continue;
      }
      if (remoteRecord.payloadHash == baselineHash) {
        yield RestoreOperation(
          type: RestoreOperationType.skip,
          category: category,
          recordId: id,
          label: remoteRecord.label,
          reason: 'local_changed_remote_unchanged',
          localHash: localRecord.payloadHash,
          remoteHash: remoteRecord.payloadHash,
        );
        continue;
      }
      yield RestoreOperation(
        type: RestoreOperationType.conflict,
        category: category,
        recordId: id,
        label: remoteRecord.label,
        reason: 'both_changed',
        localHash: localRecord.payloadHash,
        remoteHash: remoteRecord.payloadHash,
      );
    }
  }

  static Map<String, dynamic> _stringMap(Object? raw) {
    if (raw is! Map) return <String, dynamic>{};
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }

  static String _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  static DateTime? _parseDateTime(Object? raw) {
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  static dynamic _canonicalJson(dynamic value) {
    if (value is Map) {
      final result = <String, dynamic>{};
      final entries = value.entries
          .map((entry) => MapEntry(entry.key.toString(), entry.value))
          .toList(growable: false)
        ..sort((a, b) => a.key.compareTo(b.key));
      for (final entry in entries) {
        result[entry.key] = _canonicalJson(entry.value);
      }
      return result;
    }
    if (value is List) {
      return value.map(_canonicalJson).toList(growable: false);
    }
    return value;
  }
}

class _MergeRecord {
  const _MergeRecord({
    required this.id,
    required this.label,
    required this.payload,
    required this.payloadHash,
    required this.hasStableIdentity,
    required this.deletedAt,
  });

  final String id;
  final String label;
  final Map<String, dynamic> payload;
  final String payloadHash;
  final bool hasStableIdentity;
  final DateTime? deletedAt;

  _MergeRecord copyWith({bool? hasStableIdentity}) {
    return _MergeRecord(
      id: id,
      label: label,
      payload: payload,
      payloadHash: payloadHash,
      hasStableIdentity: hasStableIdentity ?? this.hasStableIdentity,
      deletedAt: deletedAt,
    );
  }
}
