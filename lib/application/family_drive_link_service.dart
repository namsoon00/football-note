import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import '../domain/repositories/option_repository.dart';
import 'drive_connection_info.dart';

enum FamilyDrivePermissionRole { reader, writer }

enum FamilyDriveFileKind {
  coreBackup,
  parentContribution,
  childManifest,
  parentManifest,
  pairingCompletion,
}

enum FamilyDriveLinkOwnerRole { child, parent }

class FamilyDriveLinkException implements Exception {
  const FamilyDriveLinkException(this.code);

  static const expiredOffer = 'family_link_offer_expired';
  static const malformedOffer = 'family_link_offer_malformed';
  static const unsupportedOfferVersion =
      'family_link_offer_unsupported_version';
  static const missingGoogleAccount = 'family_link_google_account_required';
  static const missingPermissionEmail = 'family_link_permission_email_required';
  static const inviteAlreadyUsed = 'family_link_invite_already_used';
  static const missingPendingOffer = 'family_link_offer_not_pending';
  static const accountMismatch = 'family_link_account_mismatch';
  static const familyMismatch = 'family_link_family_mismatch';
  static const datasetMismatch = 'family_link_dataset_mismatch';
  static const playerMismatch = 'family_link_player_mismatch';
  static const permissionMismatch = 'family_link_permission_mismatch';
  static const permissionRevoked = 'family_link_permission_revoked';
  static const completionMissing = 'family_link_completion_missing';

  final String code;

  @override
  String toString() => code;
}

class FamilyDriveFileRef {
  const FamilyDriveFileRef({
    required this.id,
    required this.kind,
    this.name = '',
    this.resourceKey = '',
    this.modifiedAt,
    this.created = false,
    this.canRead = true,
    this.canWrite = false,
    this.appProperties = const <String, String>{},
  });

  final String id;
  final FamilyDriveFileKind kind;
  final String name;
  final String resourceKey;
  final DateTime? modifiedAt;
  final bool created;
  final bool canRead;
  final bool canWrite;
  final Map<String, String> appProperties;

  bool get isEmpty => id.trim().isEmpty;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'kind': kind.name,
      if (name.trim().isNotEmpty) 'name': name.trim(),
      if (resourceKey.trim().isNotEmpty) 'resourceKey': resourceKey.trim(),
      if (modifiedAt != null) 'modifiedAt': modifiedAt!.toIso8601String(),
      if (created) 'created': true,
      'canRead': canRead,
      'canWrite': canWrite,
      if (appProperties.isNotEmpty) 'appProperties': appProperties,
    };
  }

  static FamilyDriveFileRef fromMap(Map<dynamic, dynamic> map) {
    return FamilyDriveFileRef(
      id: map['id']?.toString().trim() ?? '',
      kind: _fileKindFromStorage(map['kind']?.toString()),
      name: map['name']?.toString().trim() ?? '',
      resourceKey: map['resourceKey']?.toString().trim() ?? '',
      modifiedAt: DateTime.tryParse(map['modifiedAt']?.toString() ?? ''),
      created: map['created'] == true,
      canRead: map['canRead'] != false,
      canWrite: map['canWrite'] == true,
      appProperties: _stringMap(map['appProperties']),
    );
  }
}

class FamilyDrivePermissionGrant {
  const FamilyDrivePermissionGrant({
    required this.fileId,
    required this.permissionId,
    required this.role,
    this.type = 'user',
  });

  final String fileId;
  final String permissionId;
  final FamilyDrivePermissionRole role;
  final String type;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'fileId': fileId,
      'permissionId': permissionId,
      'role': role.name,
      'type': type,
    };
  }

  static FamilyDrivePermissionGrant fromMap(Map<dynamic, dynamic> map) {
    return FamilyDrivePermissionGrant(
      fileId: map['fileId']?.toString().trim() ?? '',
      permissionId: map['permissionId']?.toString().trim() ?? '',
      role: _permissionRoleFromStorage(map['role']?.toString()),
      type: map['type']?.toString().trim().isNotEmpty == true
          ? map['type'].toString().trim()
          : 'user',
    );
  }
}

class FamilyPairingOffer {
  FamilyPairingOffer({
    required this.inviteId,
    required this.nonce,
    required this.parentMemberId,
    required this.parentSubjectId,
    required this.parentDisplayName,
    required this.parentEmailForPermission,
    required this.issuedAt,
    required this.expiresAt,
    this.schemaVersion = schemaVersionValue,
    List<String> capabilities = const <String>[
      'core.reader',
      'contribution.writer',
    ],
  }) : capabilities = List<String>.unmodifiable(capabilities);

  static const int schemaVersionValue = 2;
  static const Duration ttl = Duration(minutes: 5);
  static const String payloadPrefix = 'football-note-family-link-v2:';
  static const String payloadType = 'football_note_family_link_offer';

  final int schemaVersion;
  final String inviteId;
  final String nonce;
  final String parentMemberId;
  final String parentSubjectId;
  final String parentDisplayName;
  final String parentEmailForPermission;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final List<String> capabilities;

  bool isExpired(DateTime now) => !now.isBefore(expiresAt);

  String get nonceHash => sha256.convert(utf8.encode(nonce)).toString();

  String toQrPayload() {
    final bytes = utf8.encode(jsonEncode(toQrMap()));
    return '$payloadPrefix${base64UrlEncode(bytes)}';
  }

  Map<String, dynamic> toQrMap() {
    return <String, dynamic>{
      'type': payloadType,
      'version': schemaVersion,
      'inviteId': inviteId,
      'nonce': nonce,
      'parentMemberId': parentMemberId,
      'parentSubjectId': parentSubjectId,
      'parentDisplayName': parentDisplayName,
      // Drive v3 still requires emailAddress for a private user permission.
      // This field is short-lived QR transport only and is never written by
      // the durable record/manifest serializers in this file.
      'parentPermissionEmail': parentEmailForPermission,
      'issuedAt': issuedAt.toUtc().toIso8601String(),
      'expiresAt': expiresAt.toUtc().toIso8601String(),
      'capabilities': capabilities,
    };
  }

  Map<String, dynamic> toPendingMap() {
    return <String, dynamic>{
      'version': schemaVersion,
      'inviteId': inviteId,
      'nonceHash': nonceHash,
      'parentMemberId': parentMemberId,
      'parentSubjectId': parentSubjectId,
      'parentDisplayName': parentDisplayName,
      'issuedAt': issuedAt.toUtc().toIso8601String(),
      'expiresAt': expiresAt.toUtc().toIso8601String(),
      'capabilities': capabilities,
    };
  }

  Map<String, dynamic> toDisplayMap() {
    return <String, dynamic>{
      'version': schemaVersion,
      'inviteId': inviteId,
      'parentDisplayName': parentDisplayName,
      'expiresAt': expiresAt.toUtc().toIso8601String(),
    };
  }

  FamilyPairingOffer validate(DateTime now) {
    if (schemaVersion != schemaVersionValue) {
      throw const FamilyDriveLinkException(
        FamilyDriveLinkException.unsupportedOfferVersion,
      );
    }
    if (inviteId.length < 16 ||
        nonce.length < 16 ||
        parentMemberId.trim().isEmpty ||
        parentSubjectId.trim().isEmpty ||
        parentEmailForPermission.trim().isEmpty) {
      throw const FamilyDriveLinkException(
        FamilyDriveLinkException.malformedOffer,
      );
    }
    if (isExpired(now)) {
      throw const FamilyDriveLinkException(
        FamilyDriveLinkException.expiredOffer,
      );
    }
    return this;
  }

  static FamilyPairingOffer create({
    required DriveConnectionInfo parentAccount,
    DateTime? now,
    String Function(int byteCount)? randomToken,
  }) {
    final issuedAt = (now ?? DateTime.now()).toUtc();
    final token = randomToken ?? _secureToken;
    final subjectId = parentAccount.subjectId.trim();
    final email = parentAccount.email.trim();
    if (subjectId.isEmpty) {
      throw const FamilyDriveLinkException(
        FamilyDriveLinkException.missingGoogleAccount,
      );
    }
    if (email.isEmpty) {
      throw const FamilyDriveLinkException(
        FamilyDriveLinkException.missingPermissionEmail,
      );
    }
    return FamilyPairingOffer(
      inviteId: token(18),
      nonce: token(32),
      parentMemberId: 'parent-${token(12)}',
      parentSubjectId: subjectId,
      parentDisplayName: parentAccount.displayName.trim().isNotEmpty
          ? parentAccount.displayName.trim()
          : 'Parent',
      parentEmailForPermission: email,
      issuedAt: issuedAt,
      expiresAt: issuedAt.add(ttl),
    );
  }

  static FamilyPairingOffer parse(String raw, {DateTime? now}) {
    final trimmed = raw.trim();
    if (!trimmed.startsWith(payloadPrefix)) {
      throw const FamilyDriveLinkException(
        FamilyDriveLinkException.malformedOffer,
      );
    }
    final body = trimmed.substring(payloadPrefix.length);
    final dynamic decoded;
    try {
      decoded =
          jsonDecode(utf8.decode(base64Url.decode(_normalizeBase64(body))));
    } catch (_) {
      throw const FamilyDriveLinkException(
        FamilyDriveLinkException.malformedOffer,
      );
    }
    if (decoded is! Map) {
      throw const FamilyDriveLinkException(
        FamilyDriveLinkException.malformedOffer,
      );
    }
    final map = decoded.map((key, value) => MapEntry(key.toString(), value));
    if (map['type'] != payloadType) {
      throw const FamilyDriveLinkException(
        FamilyDriveLinkException.malformedOffer,
      );
    }
    final version = (map['version'] as num?)?.toInt() ?? -1;
    final issuedAt = DateTime.tryParse(map['issuedAt']?.toString() ?? '');
    final expiresAt = DateTime.tryParse(map['expiresAt']?.toString() ?? '');
    if (issuedAt == null || expiresAt == null) {
      throw const FamilyDriveLinkException(
        FamilyDriveLinkException.malformedOffer,
      );
    }
    final capabilities = (map['capabilities'] as List?)
            ?.map((value) => value.toString())
            .toList(growable: false) ??
        const <String>[];
    return FamilyPairingOffer(
      schemaVersion: version,
      inviteId: map['inviteId']?.toString().trim() ?? '',
      nonce: map['nonce']?.toString().trim() ?? '',
      parentMemberId: map['parentMemberId']?.toString().trim() ?? '',
      parentSubjectId: map['parentSubjectId']?.toString().trim() ?? '',
      parentDisplayName: map['parentDisplayName']?.toString().trim() ?? '',
      parentEmailForPermission:
          map['parentPermissionEmail']?.toString().trim() ?? '',
      issuedAt: issuedAt.toUtc(),
      expiresAt: expiresAt.toUtc(),
      capabilities: capabilities,
    ).validate(now ?? DateTime.now().toUtc());
  }
}

class FamilyDriveLinkRecord {
  const FamilyDriveLinkRecord({
    required this.familyId,
    required this.datasetId,
    required this.playerId,
    required this.parentMemberId,
    required this.parentSubjectId,
    required this.parentDisplayName,
    required this.childSubjectId,
    required this.coreBackupFileId,
    required this.contributionFileId,
    required this.corePermissionId,
    required this.contributionPermissionId,
    required this.createdAt,
    required this.updatedAt,
    this.schemaVersion = 2,
    this.coreBackupResourceKey = '',
    this.contributionResourceKey = '',
    this.childManifestFileId = '',
    this.parentManifestFileId = '',
    this.pairingCompletionFileId = '',
    this.pairingInviteId = '',
    this.pairingNonceHash = '',
    this.lastCoreModifiedAt,
    this.lastContributionModifiedAt,
    this.revokedAt,
    this.revocationReason = '',
  });

  final int schemaVersion;
  final String familyId;
  final String datasetId;
  final String playerId;
  final String parentMemberId;
  final String parentSubjectId;
  final String parentDisplayName;
  final String childSubjectId;
  final String coreBackupFileId;
  final String coreBackupResourceKey;
  final String contributionFileId;
  final String contributionResourceKey;
  final String corePermissionId;
  final String contributionPermissionId;
  final String childManifestFileId;
  final String parentManifestFileId;
  final String pairingCompletionFileId;
  final String pairingInviteId;
  final String pairingNonceHash;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastCoreModifiedAt;
  final DateTime? lastContributionModifiedAt;
  final DateTime? revokedAt;
  final String revocationReason;

  bool get isRevoked => revokedAt != null;

  String get storageId => parentMemberId;

  FamilyDriveFileRef get coreBackupFile => FamilyDriveFileRef(
        id: coreBackupFileId,
        resourceKey: coreBackupResourceKey,
        kind: FamilyDriveFileKind.coreBackup,
        modifiedAt: lastCoreModifiedAt,
        canRead: true,
      );

  FamilyDriveFileRef get contributionFile => FamilyDriveFileRef(
        id: contributionFileId,
        resourceKey: contributionResourceKey,
        kind: FamilyDriveFileKind.parentContribution,
        modifiedAt: lastContributionModifiedAt,
        canRead: true,
        canWrite: true,
      );

  FamilyDriveLinkRecord copyWith({
    String? familyId,
    String? datasetId,
    String? playerId,
    String? parentMemberId,
    String? parentSubjectId,
    String? parentDisplayName,
    String? childSubjectId,
    String? coreBackupFileId,
    String? coreBackupResourceKey,
    String? contributionFileId,
    String? contributionResourceKey,
    String? corePermissionId,
    String? contributionPermissionId,
    String? childManifestFileId,
    String? parentManifestFileId,
    String? pairingCompletionFileId,
    String? pairingInviteId,
    String? pairingNonceHash,
    DateTime? updatedAt,
    DateTime? lastCoreModifiedAt,
    DateTime? lastContributionModifiedAt,
    DateTime? revokedAt,
    String? revocationReason,
  }) {
    return FamilyDriveLinkRecord(
      schemaVersion: schemaVersion,
      familyId: familyId ?? this.familyId,
      datasetId: datasetId ?? this.datasetId,
      playerId: playerId ?? this.playerId,
      parentMemberId: parentMemberId ?? this.parentMemberId,
      parentSubjectId: parentSubjectId ?? this.parentSubjectId,
      parentDisplayName: parentDisplayName ?? this.parentDisplayName,
      childSubjectId: childSubjectId ?? this.childSubjectId,
      coreBackupFileId: coreBackupFileId ?? this.coreBackupFileId,
      coreBackupResourceKey:
          coreBackupResourceKey ?? this.coreBackupResourceKey,
      contributionFileId: contributionFileId ?? this.contributionFileId,
      contributionResourceKey:
          contributionResourceKey ?? this.contributionResourceKey,
      corePermissionId: corePermissionId ?? this.corePermissionId,
      contributionPermissionId:
          contributionPermissionId ?? this.contributionPermissionId,
      childManifestFileId: childManifestFileId ?? this.childManifestFileId,
      parentManifestFileId: parentManifestFileId ?? this.parentManifestFileId,
      pairingCompletionFileId:
          pairingCompletionFileId ?? this.pairingCompletionFileId,
      pairingInviteId: pairingInviteId ?? this.pairingInviteId,
      pairingNonceHash: pairingNonceHash ?? this.pairingNonceHash,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastCoreModifiedAt: lastCoreModifiedAt ?? this.lastCoreModifiedAt,
      lastContributionModifiedAt:
          lastContributionModifiedAt ?? this.lastContributionModifiedAt,
      revokedAt: revokedAt ?? this.revokedAt,
      revocationReason: revocationReason ?? this.revocationReason,
    );
  }

  FamilyDriveLinkRecord revoked({
    required DateTime at,
    required String reason,
  }) {
    return copyWith(
      updatedAt: at.toUtc(),
      revokedAt: at.toUtc(),
      revocationReason: reason,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'familyId': familyId,
      'datasetId': datasetId,
      'playerId': playerId,
      'parentMemberId': parentMemberId,
      'parentSubjectId': parentSubjectId,
      'parentDisplayName': parentDisplayName,
      'childSubjectId': childSubjectId,
      'coreBackupFileId': coreBackupFileId,
      if (coreBackupResourceKey.trim().isNotEmpty)
        'coreBackupResourceKey': coreBackupResourceKey,
      'contributionFileId': contributionFileId,
      if (contributionResourceKey.trim().isNotEmpty)
        'contributionResourceKey': contributionResourceKey,
      'corePermissionId': corePermissionId,
      'contributionPermissionId': contributionPermissionId,
      if (childManifestFileId.trim().isNotEmpty)
        'childManifestFileId': childManifestFileId,
      if (parentManifestFileId.trim().isNotEmpty)
        'parentManifestFileId': parentManifestFileId,
      if (pairingCompletionFileId.trim().isNotEmpty)
        'pairingCompletionFileId': pairingCompletionFileId,
      if (pairingInviteId.trim().isNotEmpty) 'pairingInviteId': pairingInviteId,
      if (pairingNonceHash.trim().isNotEmpty)
        'pairingNonceHash': pairingNonceHash,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      if (lastCoreModifiedAt != null)
        'lastCoreModifiedAt': lastCoreModifiedAt!.toUtc().toIso8601String(),
      if (lastContributionModifiedAt != null)
        'lastContributionModifiedAt':
            lastContributionModifiedAt!.toUtc().toIso8601String(),
      if (revokedAt != null) 'revokedAt': revokedAt!.toUtc().toIso8601String(),
      if (revocationReason.trim().isNotEmpty)
        'revocationReason': revocationReason,
    };
  }

  static FamilyDriveLinkRecord fromMap(Map<dynamic, dynamic> map) {
    final now = DateTime.now().toUtc();
    return FamilyDriveLinkRecord(
      schemaVersion: (map['schemaVersion'] as num?)?.toInt() ?? 1,
      familyId: map['familyId']?.toString().trim() ?? '',
      datasetId: map['datasetId']?.toString().trim() ?? '',
      playerId: map['playerId']?.toString().trim() ?? '',
      parentMemberId: map['parentMemberId']?.toString().trim() ?? '',
      parentSubjectId: map['parentSubjectId']?.toString().trim() ?? '',
      parentDisplayName: map['parentDisplayName']?.toString().trim() ?? '',
      childSubjectId: map['childSubjectId']?.toString().trim() ?? '',
      coreBackupFileId: map['coreBackupFileId']?.toString().trim() ?? '',
      coreBackupResourceKey:
          map['coreBackupResourceKey']?.toString().trim() ?? '',
      contributionFileId: map['contributionFileId']?.toString().trim() ?? '',
      contributionResourceKey:
          map['contributionResourceKey']?.toString().trim() ?? '',
      corePermissionId: map['corePermissionId']?.toString().trim() ?? '',
      contributionPermissionId:
          map['contributionPermissionId']?.toString().trim() ?? '',
      childManifestFileId: map['childManifestFileId']?.toString().trim() ?? '',
      parentManifestFileId:
          map['parentManifestFileId']?.toString().trim() ?? '',
      pairingCompletionFileId:
          map['pairingCompletionFileId']?.toString().trim() ?? '',
      pairingInviteId: map['pairingInviteId']?.toString().trim() ?? '',
      pairingNonceHash: map['pairingNonceHash']?.toString().trim() ?? '',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? now,
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? now,
      lastCoreModifiedAt:
          DateTime.tryParse(map['lastCoreModifiedAt']?.toString() ?? ''),
      lastContributionModifiedAt: DateTime.tryParse(
        map['lastContributionModifiedAt']?.toString() ?? '',
      ),
      revokedAt: DateTime.tryParse(map['revokedAt']?.toString() ?? ''),
      revocationReason: map['revocationReason']?.toString().trim() ?? '',
    );
  }
}

class FamilyDriveLinkManifest {
  const FamilyDriveLinkManifest({
    required this.ownerRole,
    required this.familyId,
    required this.datasetId,
    required this.playerId,
    required this.records,
    required this.createdAt,
    required this.updatedAt,
    this.schemaVersion = 2,
  });

  static const String formatValue = 'teo_note_family_links';

  final int schemaVersion;
  final FamilyDriveLinkOwnerRole ownerRole;
  final String familyId;
  final String datasetId;
  final String playerId;
  final List<FamilyDriveLinkRecord> records;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'format': formatValue,
      'schemaVersion': schemaVersion,
      'ownerRole': ownerRole.name,
      'familyId': familyId,
      'datasetId': datasetId,
      'playerId': playerId,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'records': records.map((record) => record.toMap()).toList(),
    };
  }

  static FamilyDriveLinkManifest fromMap(Map<dynamic, dynamic> map) {
    if (map['format'] != formatValue) {
      throw const FamilyDriveLinkException(
        FamilyDriveLinkException.malformedOffer,
      );
    }
    final now = DateTime.now().toUtc();
    return FamilyDriveLinkManifest(
      schemaVersion: (map['schemaVersion'] as num?)?.toInt() ?? 1,
      ownerRole: map['ownerRole'] == FamilyDriveLinkOwnerRole.parent.name
          ? FamilyDriveLinkOwnerRole.parent
          : FamilyDriveLinkOwnerRole.child,
      familyId: map['familyId']?.toString().trim() ?? '',
      datasetId: map['datasetId']?.toString().trim() ?? '',
      playerId: map['playerId']?.toString().trim() ?? '',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? now,
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? now,
      records: (map['records'] as List?)
              ?.whereType<Map>()
              .map(FamilyDriveLinkRecord.fromMap)
              .toList(growable: false) ??
          const <FamilyDriveLinkRecord>[],
    );
  }
}

class FamilyDriveLinkRecoveryResult {
  const FamilyDriveLinkRecoveryResult({
    required this.records,
    required this.activeRecord,
    this.noManifest = false,
  });

  const FamilyDriveLinkRecoveryResult.empty({this.noManifest = false})
      : records = const <FamilyDriveLinkRecord>[],
        activeRecord = null;

  final List<FamilyDriveLinkRecord> records;
  final FamilyDriveLinkRecord? activeRecord;
  final bool noManifest;

  bool get hasRecords => records.isNotEmpty;
}

class FamilyPairingCompletion {
  const FamilyPairingCompletion({
    required this.inviteId,
    required this.nonceHash,
    required this.record,
    required this.corePermission,
    required this.contributionPermission,
    required this.createdAt,
    this.schemaVersion = 2,
  });

  static const String formatValue = 'teo_note_family_link_completion';

  final int schemaVersion;
  final String inviteId;
  final String nonceHash;
  final FamilyDriveLinkRecord record;
  final FamilyDrivePermissionGrant corePermission;
  final FamilyDrivePermissionGrant contributionPermission;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'format': formatValue,
      'schemaVersion': schemaVersion,
      'inviteId': inviteId,
      'nonceHash': nonceHash,
      'record': record.toMap(),
      'corePermission': corePermission.toMap(),
      'contributionPermission': contributionPermission.toMap(),
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }

  static FamilyPairingCompletion fromMap(Map<dynamic, dynamic> map) {
    if (map['format'] != formatValue) {
      throw const FamilyDriveLinkException(
        FamilyDriveLinkException.completionMissing,
      );
    }
    final recordRaw = map['record'];
    final coreRaw = map['corePermission'];
    final contributionRaw = map['contributionPermission'];
    if (recordRaw is! Map || coreRaw is! Map || contributionRaw is! Map) {
      throw const FamilyDriveLinkException(
        FamilyDriveLinkException.completionMissing,
      );
    }
    return FamilyPairingCompletion(
      schemaVersion: (map['schemaVersion'] as num?)?.toInt() ?? 1,
      inviteId: map['inviteId']?.toString().trim() ?? '',
      nonceHash: map['nonceHash']?.toString().trim() ?? '',
      record: FamilyDriveLinkRecord.fromMap(recordRaw),
      corePermission: FamilyDrivePermissionGrant.fromMap(coreRaw),
      contributionPermission: FamilyDrivePermissionGrant.fromMap(
        contributionRaw,
      ),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}

class FamilyPairingCompletionCandidate {
  const FamilyPairingCompletionCandidate({
    required this.file,
    required this.payload,
  });

  final FamilyDriveFileRef file;
  final Map<String, dynamic> payload;
}

class FamilyDriveLinkStore {
  FamilyDriveLinkStore(this._options);

  static const String activeLinkIdKey = 'family_drive_active_link_id_v2';
  static const String linkRecordsKey = 'family_drive_link_records_v2';
  static const String usedInviteIdsKey = 'family_drive_used_invites_v2';
  static const String pendingOffersKey = 'family_drive_pending_offers_v2';

  final OptionRepository _options;

  List<FamilyDriveLinkRecord> loadRecords() {
    final raw = _options.getValue<List>(linkRecordsKey);
    if (raw is! List) return const <FamilyDriveLinkRecord>[];
    return raw
        .whereType<Map>()
        .map(FamilyDriveLinkRecord.fromMap)
        .toList(growable: false);
  }

  FamilyDriveLinkRecord? loadActiveRecord() {
    final activeId = _options.getValue<String>(activeLinkIdKey)?.trim() ?? '';
    final records = loadRecords();
    for (final record in records) {
      if (!record.isRevoked &&
          activeId.isNotEmpty &&
          record.storageId == activeId) {
        return record;
      }
    }
    for (final record in records) {
      if (!record.isRevoked) {
        return record;
      }
    }
    return null;
  }

  Future<void> saveRecord(
    FamilyDriveLinkRecord record, {
    bool makeActive = true,
  }) async {
    final records = loadRecords().toList(growable: true);
    final index =
        records.indexWhere((item) => item.storageId == record.storageId);
    if (index >= 0) {
      records[index] = record;
    } else {
      records.add(record);
    }
    await _options.setValue(
      linkRecordsKey,
      records.map((item) => item.toMap()).toList(growable: false),
    );
    if (makeActive && !record.isRevoked) {
      await _options.setValue(activeLinkIdKey, record.storageId);
    }
  }

  Future<void> saveRecords(
    List<FamilyDriveLinkRecord> incoming, {
    String? activeLinkId,
  }) async {
    if (incoming.isEmpty) return;
    final records = loadRecords().toList(growable: true);
    for (final record in incoming) {
      final index =
          records.indexWhere((item) => item.storageId == record.storageId);
      if (index >= 0) {
        records[index] = record;
      } else {
        records.add(record);
      }
    }
    await _options.setValue(
      linkRecordsKey,
      records.map((item) => item.toMap()).toList(growable: false),
    );
    final requestedActiveId = activeLinkId?.trim();
    final activeId = requestedActiveId == null
        ? _resolveActiveLinkId(records)
        : records.any(
            (item) =>
                !item.isRevoked &&
                requestedActiveId.isNotEmpty &&
                item.storageId == requestedActiveId,
          )
            ? requestedActiveId
            : '';
    await _options.setValue(activeLinkIdKey, activeId);
  }

  Future<void> revokeRecord({
    required String parentMemberId,
    required DateTime at,
    required String reason,
  }) async {
    final records = loadRecords().toList(growable: true);
    final index =
        records.indexWhere((item) => item.storageId == parentMemberId);
    if (index < 0) return;
    records[index] = records[index].revoked(at: at, reason: reason);
    await _options.setValue(
      linkRecordsKey,
      records.map((item) => item.toMap()).toList(growable: false),
    );
    if (_options.getValue<String>(activeLinkIdKey) == parentMemberId) {
      final next = records.where((item) => !item.isRevoked).firstOrNull;
      await _options.setValue(activeLinkIdKey, next?.storageId ?? '');
    }
  }

  bool isInviteUsed(String inviteId) {
    return _usedInvites().contains(inviteId.trim());
  }

  Future<void> markInviteUsed(String inviteId) async {
    final ids = _usedInvites().toList(growable: true);
    final trimmed = inviteId.trim();
    if (trimmed.isNotEmpty && !ids.contains(trimmed)) {
      ids.add(trimmed);
      await _options.setValue(usedInviteIdsKey, ids);
    }
  }

  Future<void> savePendingOffer(FamilyPairingOffer offer) async {
    final offers = _pendingOfferMaps()
      ..removeWhere((item) => item['inviteId'] == offer.inviteId)
      ..add(offer.toPendingMap());
    await _options.setValue(pendingOffersKey, offers);
  }

  Map<String, dynamic>? loadPendingOffer(String inviteId) {
    for (final offer in _pendingOfferMaps()) {
      if (offer['inviteId']?.toString() == inviteId.trim()) {
        return offer;
      }
    }
    return null;
  }

  Future<void> clearPendingOffer(String inviteId) async {
    final offers = _pendingOfferMaps()
      ..removeWhere((item) => item['inviteId'] == inviteId.trim());
    await _options.setValue(pendingOffersKey, offers);
  }

  List<Map<String, dynamic>> _pendingOfferMaps() {
    final raw = _options.getValue<List>(pendingOffersKey);
    if (raw is! List) return <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map(
            (item) => item.map((key, value) => MapEntry(key.toString(), value)))
        .toList(growable: true);
  }

  Set<String> _usedInvites() {
    final raw = _options.getValue<List>(usedInviteIdsKey);
    if (raw is! List) return <String>{};
    return raw.map((item) => item.toString().trim()).where((item) {
      return item.isNotEmpty;
    }).toSet();
  }

  String _resolveActiveLinkId(List<FamilyDriveLinkRecord> records) {
    final current = _options.getValue<String>(activeLinkIdKey)?.trim() ?? '';
    if (current.isNotEmpty &&
        records.any((item) => !item.isRevoked && item.storageId == current)) {
      return current;
    }
    return records.where((item) => !item.isRevoked).firstOrNull?.storageId ??
        '';
  }
}

abstract class FamilyDriveLinkGateway {
  Future<DriveConnectionInfo?> currentAccount();

  Future<FamilyDriveFileRef> ensureChildCoreSnapshot({
    required Map<String, dynamic> backupPayload,
    required Map<String, String> appProperties,
  });

  Future<FamilyDriveFileRef> ensureParentContributionFile({
    required String parentMemberId,
    required Map<String, dynamic> initialPayload,
    required Map<String, String> appProperties,
  });

  Future<FamilyDriveFileRef> writeJsonFile({
    required String fileName,
    required FamilyDriveFileKind kind,
    required Map<String, dynamic> payload,
    required Map<String, String> appProperties,
  });

  Future<FamilyDrivePermissionGrant> createPrivateUserPermission({
    required FamilyDriveFileRef file,
    required String emailAddress,
    required FamilyDrivePermissionRole role,
  });

  Future<void> deletePermission({
    required String fileId,
    required String permissionId,
  });

  Future<void> trashFile({required String fileId});

  Future<List<FamilyPairingCompletionCandidate>> listPairingCompletions({
    required String inviteId,
  });

  Future<Map<String, dynamic>> downloadJsonFile(FamilyDriveFileRef file);

  Future<FamilyDriveFileRef> saveParentManifest({
    required FamilyDriveLinkManifest manifest,
  });

  Future<FamilyDriveLinkManifest?> loadParentManifest();

  Future<FamilyDriveFileRef> saveChildManifest({
    required FamilyDriveLinkManifest manifest,
  });

  Future<FamilyDriveLinkManifest?> loadChildManifest();
}

class FamilyDriveLinkService {
  FamilyDriveLinkService({
    required FamilyDriveLinkStore store,
    required FamilyDriveLinkGateway gateway,
  })  : _store = store,
        _gateway = gateway;

  final FamilyDriveLinkStore _store;
  final FamilyDriveLinkGateway _gateway;

  Future<FamilyPairingOffer> createParentOffer({DateTime? now}) async {
    final account = await _gateway.currentAccount();
    if (account == null || account.subjectId.trim().isEmpty) {
      throw const FamilyDriveLinkException(
        FamilyDriveLinkException.missingGoogleAccount,
      );
    }
    final offer = FamilyPairingOffer.create(
      parentAccount: account,
      now: now,
    );
    await _store.savePendingOffer(offer);
    return offer;
  }

  Future<FamilyDriveLinkRecord> approveOfferOnChild({
    required String qrPayload,
    required String familyId,
    required String datasetId,
    required String playerId,
    required Map<String, dynamic> childBackupPayload,
    required Map<String, dynamic> parentContributionPayload,
    DateTime? now,
  }) async {
    final approvedAt = (now ?? DateTime.now()).toUtc();
    final offer = FamilyPairingOffer.parse(qrPayload, now: approvedAt);
    if (_store.isInviteUsed(offer.inviteId)) {
      throw const FamilyDriveLinkException(
        FamilyDriveLinkException.inviteAlreadyUsed,
      );
    }
    final childAccount = await _gateway.currentAccount();
    if (childAccount == null || childAccount.subjectId.trim().isEmpty) {
      throw const FamilyDriveLinkException(
        FamilyDriveLinkException.missingGoogleAccount,
      );
    }
    final createdPermissions = <FamilyDrivePermissionGrant>[];
    final createdFiles = <FamilyDriveFileRef>[];
    try {
      final properties = _linkAppProperties(
        inviteId: offer.inviteId,
        familyId: familyId,
        datasetId: datasetId,
        playerId: playerId,
        parentMemberId: offer.parentMemberId,
      );
      final coreFile = await _gateway.ensureChildCoreSnapshot(
        backupPayload: childBackupPayload,
        appProperties: <String, String>{
          ...properties,
          _appPropertyKind: FamilyDriveFileKind.coreBackup.name,
        },
      );
      if (coreFile.created) createdFiles.add(coreFile);
      final contributionFile = await _gateway.ensureParentContributionFile(
        parentMemberId: offer.parentMemberId,
        initialPayload: parentContributionPayload,
        appProperties: <String, String>{
          ...properties,
          _appPropertyKind: FamilyDriveFileKind.parentContribution.name,
        },
      );
      if (contributionFile.created) createdFiles.add(contributionFile);

      final corePermission = await _gateway.createPrivateUserPermission(
        file: coreFile,
        emailAddress: offer.parentEmailForPermission,
        role: FamilyDrivePermissionRole.reader,
      );
      createdPermissions.add(corePermission);
      final contributionPermission = await _gateway.createPrivateUserPermission(
        file: contributionFile,
        emailAddress: offer.parentEmailForPermission,
        role: FamilyDrivePermissionRole.writer,
      );
      createdPermissions.add(contributionPermission);

      final record = FamilyDriveLinkRecord(
        familyId: familyId,
        datasetId: datasetId,
        playerId: playerId,
        parentMemberId: offer.parentMemberId,
        parentSubjectId: offer.parentSubjectId,
        parentDisplayName: offer.parentDisplayName,
        childSubjectId: childAccount.subjectId.trim(),
        coreBackupFileId: coreFile.id,
        coreBackupResourceKey: coreFile.resourceKey,
        contributionFileId: contributionFile.id,
        contributionResourceKey: contributionFile.resourceKey,
        corePermissionId: corePermission.permissionId,
        contributionPermissionId: contributionPermission.permissionId,
        pairingInviteId: offer.inviteId,
        pairingNonceHash: offer.nonceHash,
        lastCoreModifiedAt: coreFile.modifiedAt,
        lastContributionModifiedAt: contributionFile.modifiedAt,
        createdAt: approvedAt,
        updatedAt: approvedAt,
      );
      final completion = FamilyPairingCompletion(
        inviteId: offer.inviteId,
        nonceHash: offer.nonceHash,
        record: record,
        corePermission: corePermission,
        contributionPermission: contributionPermission,
        createdAt: approvedAt,
      );
      final completionFile = await _gateway.writeJsonFile(
        fileName: 'family_link_${offer.inviteId}_completion.json',
        kind: FamilyDriveFileKind.pairingCompletion,
        payload: completion.toMap(),
        appProperties: <String, String>{
          ...properties,
          _appPropertyKind: FamilyDriveFileKind.pairingCompletion.name,
        },
      );
      if (completionFile.created) createdFiles.add(completionFile);
      final completionPermission = await _gateway.createPrivateUserPermission(
        file: completionFile,
        emailAddress: offer.parentEmailForPermission,
        role: FamilyDrivePermissionRole.reader,
      );
      createdPermissions.add(completionPermission);
      final completedRecord = record.copyWith(
        pairingCompletionFileId: completionFile.id,
        updatedAt: approvedAt,
      );
      final childManifest = await _mergedChildManifestForRecord(
        record: completedRecord,
        at: approvedAt,
      );
      final childManifestFile = await _gateway.saveChildManifest(
        manifest: childManifest,
      );
      if (childManifestFile.created) createdFiles.add(childManifestFile);
      final persisted = completedRecord.copyWith(
        childManifestFileId: childManifestFile.id,
        updatedAt: approvedAt,
      );
      await _store.saveRecord(persisted);
      await _store.markInviteUsed(offer.inviteId);
      return persisted;
    } catch (_) {
      for (final grant in createdPermissions.reversed) {
        await _bestEffort(
          () => _gateway.deletePermission(
            fileId: grant.fileId,
            permissionId: grant.permissionId,
          ),
        );
      }
      for (final file in createdFiles.reversed) {
        await _bestEffort(() => _gateway.trashFile(fileId: file.id));
      }
      rethrow;
    }
  }

  Future<FamilyDriveLinkRecord> completeParentPairing({
    required String inviteId,
    Future<void> Function(
      FamilyDriveLinkRecord record,
      Map<String, dynamic> childBackup,
    )? restoreChildBackup,
    DateTime? now,
  }) async {
    final completedAt = (now ?? DateTime.now()).toUtc();
    final pending = await _validatedPendingParentOffer(
      inviteId: inviteId,
      completedAt: completedAt,
    );
    final candidates = await _gateway.listPairingCompletions(
      inviteId: inviteId,
    );
    if (candidates.isEmpty) {
      throw const FamilyDriveLinkException(
        FamilyDriveLinkException.completionMissing,
      );
    }
    return _completeParentPairingWithCompletion(
      pending: pending,
      completion: FamilyPairingCompletion.fromMap(candidates.first.payload),
      completedAt: completedAt,
      restoreChildBackup: restoreChildBackup,
    );
  }

  Future<FamilyDriveLinkRecord> completeParentPairingFromCompletionPayload({
    required String inviteId,
    required Map<dynamic, dynamic> completionPayload,
    Future<void> Function(
      FamilyDriveLinkRecord record,
      Map<String, dynamic> childBackup,
    )? restoreChildBackup,
    DateTime? now,
  }) async {
    final completedAt = (now ?? DateTime.now()).toUtc();
    final pending = await _validatedPendingParentOffer(
      inviteId: inviteId,
      completedAt: completedAt,
    );
    return _completeParentPairingWithCompletion(
      pending: pending,
      completion: FamilyPairingCompletion.fromMap(completionPayload),
      completedAt: completedAt,
      restoreChildBackup: restoreChildBackup,
    );
  }

  Future<Map<String, dynamic>> _validatedPendingParentOffer({
    required String inviteId,
    required DateTime completedAt,
  }) async {
    if (_store.isInviteUsed(inviteId)) {
      throw const FamilyDriveLinkException(
        FamilyDriveLinkException.inviteAlreadyUsed,
      );
    }
    final pending = _store.loadPendingOffer(inviteId);
    if (pending == null) {
      throw const FamilyDriveLinkException(
        FamilyDriveLinkException.missingPendingOffer,
      );
    }
    final expiresAt = DateTime.tryParse(pending['expiresAt']?.toString() ?? '');
    if (expiresAt == null || !completedAt.isBefore(expiresAt.toUtc())) {
      throw const FamilyDriveLinkException(
        FamilyDriveLinkException.expiredOffer,
      );
    }
    final account = await _gateway.currentAccount();
    final expectedParentSubject =
        pending['parentSubjectId']?.toString().trim() ?? '';
    if (account == null ||
        account.subjectId.trim().isEmpty ||
        account.subjectId.trim() != expectedParentSubject) {
      throw const FamilyDriveLinkException(
        FamilyDriveLinkException.accountMismatch,
      );
    }
    return pending;
  }

  Future<FamilyDriveLinkRecord> _completeParentPairingWithCompletion({
    required Map<String, dynamic> pending,
    required FamilyPairingCompletion completion,
    required DateTime completedAt,
    Future<void> Function(
      FamilyDriveLinkRecord record,
      Map<String, dynamic> childBackup,
    )? restoreChildBackup,
  }) async {
    final inviteId = pending['inviteId']?.toString().trim() ?? '';
    _validateCompletionAgainstPending(completion, pending);
    final childBackup = await _gateway.downloadJsonFile(
      completion.record.coreBackupFile,
    );
    if (restoreChildBackup != null) {
      await restoreChildBackup(completion.record, childBackup);
    }
    final manifest = _manifestFor(
      role: FamilyDriveLinkOwnerRole.parent,
      records: <FamilyDriveLinkRecord>[completion.record],
      at: completedAt,
    );
    final manifestFile = await _gateway.saveParentManifest(manifest: manifest);
    final record = completion.record.copyWith(
      parentManifestFileId: manifestFile.id,
      updatedAt: completedAt,
    );
    await _store.saveRecord(record);
    await _store.markInviteUsed(inviteId);
    await _store.clearPendingOffer(inviteId);
    return record;
  }

  Future<FamilyDriveLinkRecord?> recoverParentLinkAfterReinstall() async {
    final result = await recoverParentLinksAfterReinstall();
    return result.activeRecord;
  }

  Future<FamilyDriveLinkRecoveryResult> recoverParentLinksAfterReinstall() {
    return _recoverLinksAfterReinstall(
      expectedRole: FamilyDriveLinkOwnerRole.parent,
    );
  }

  Future<FamilyDriveLinkRecoveryResult> recoverChildLinksAfterReinstall() {
    return _recoverLinksAfterReinstall(
      expectedRole: FamilyDriveLinkOwnerRole.child,
    );
  }

  Future<void> childInitiatedUnlink({
    required FamilyDriveLinkRecord record,
    DateTime? now,
  }) async {
    final at = (now ?? DateTime.now()).toUtc();
    await _validateCurrentSubjectForRecord(
      record: record,
      role: FamilyDriveLinkOwnerRole.child,
    );
    final revoked = record.revoked(at: at, reason: 'child_unlinked');
    final manifestFile = await _gateway.saveChildManifest(
      manifest: await _mergedChildManifestForRecord(record: revoked, at: at),
    );
    final localRevoked = revoked.copyWith(
      childManifestFileId: manifestFile.id.trim().isNotEmpty
          ? manifestFile.id.trim()
          : revoked.childManifestFileId,
    );
    await _store.saveRecord(
      localRevoked,
      makeActive: false,
    );
    await _bestEffort(
      () => _gateway.deletePermission(
        fileId: record.coreBackupFileId,
        permissionId: record.corePermissionId,
      ),
    );
    await _bestEffort(
      () => _gateway.deletePermission(
        fileId: record.contributionFileId,
        permissionId: record.contributionPermissionId,
      ),
    );
  }

  Future<void> parentLocalUnlink({
    required FamilyDriveLinkRecord record,
    DateTime? now,
  }) async {
    final at = (now ?? DateTime.now()).toUtc();
    await _validateCurrentSubjectForRecord(
      record: record,
      role: FamilyDriveLinkOwnerRole.parent,
    );
    final revoked = record.revoked(
      at: at,
      reason: 'parent_local_unlinked',
    );
    final manifestFile = await _gateway.saveParentManifest(
      manifest: await _mergedParentManifestForRecord(record: revoked, at: at),
    );
    final localRevoked = revoked.copyWith(
      parentManifestFileId: manifestFile.id.trim().isNotEmpty
          ? manifestFile.id.trim()
          : revoked.parentManifestFileId,
    );
    await _store.saveRecord(
      localRevoked,
      makeActive: false,
    );
  }

  Future<void> _validateCurrentSubjectForRecord({
    required FamilyDriveLinkRecord record,
    required FamilyDriveLinkOwnerRole role,
  }) async {
    final account = await _gateway.currentAccount();
    final currentSubjectId = account?.subjectId.trim() ?? '';
    if (currentSubjectId.isEmpty) {
      throw const FamilyDriveLinkException(
        FamilyDriveLinkException.missingGoogleAccount,
      );
    }
    final expectedSubjectId = role == FamilyDriveLinkOwnerRole.child
        ? record.childSubjectId.trim()
        : record.parentSubjectId.trim();
    if (expectedSubjectId.isEmpty || expectedSubjectId != currentSubjectId) {
      throw const FamilyDriveLinkException(
        FamilyDriveLinkException.accountMismatch,
      );
    }
  }

  FamilyDriveLinkManifest _manifestFor({
    required FamilyDriveLinkOwnerRole role,
    required List<FamilyDriveLinkRecord> records,
    required DateTime at,
  }) {
    final active = records.first;
    return FamilyDriveLinkManifest(
      ownerRole: role,
      familyId: active.familyId,
      datasetId: active.datasetId,
      playerId: active.playerId,
      records: records,
      createdAt: active.createdAt,
      updatedAt: at,
    );
  }

  Future<FamilyDriveLinkManifest> _mergedChildManifestForRecord({
    required FamilyDriveLinkRecord record,
    required DateTime at,
  }) async {
    return _mergedManifestForRecord(
      role: FamilyDriveLinkOwnerRole.child,
      record: record,
      at: at,
    );
  }

  Future<FamilyDriveLinkManifest> _mergedParentManifestForRecord({
    required FamilyDriveLinkRecord record,
    required DateTime at,
  }) async {
    return _mergedManifestForRecord(
      role: FamilyDriveLinkOwnerRole.parent,
      record: record,
      at: at,
    );
  }

  Future<FamilyDriveLinkManifest> _mergedManifestForRecord({
    required FamilyDriveLinkOwnerRole role,
    required FamilyDriveLinkRecord record,
    required DateTime at,
  }) async {
    final durable = role == FamilyDriveLinkOwnerRole.child
        ? await _gateway.loadChildManifest()
        : await _gateway.loadParentManifest();
    final records = _mergeCompatibleRecords(
      familyId: record.familyId,
      datasetId: record.datasetId,
      playerId: record.playerId,
      durableManifest: durable?.ownerRole == role ? durable : null,
      localRecords: _store.loadRecords(),
      upsertRecord: record,
    );
    return _manifestFor(
      role: role,
      records: records,
      at: at,
    );
  }

  Future<FamilyDriveLinkRecoveryResult> _recoverLinksAfterReinstall({
    required FamilyDriveLinkOwnerRole expectedRole,
  }) async {
    final account = await _gateway.currentAccount();
    final currentSubjectId = account?.subjectId.trim() ?? '';
    if (currentSubjectId.isEmpty) {
      return const FamilyDriveLinkRecoveryResult.empty();
    }
    final manifest = expectedRole == FamilyDriveLinkOwnerRole.child
        ? await _gateway.loadChildManifest()
        : await _gateway.loadParentManifest();
    if (manifest == null) {
      return const FamilyDriveLinkRecoveryResult.empty(noManifest: true);
    }
    if (manifest.ownerRole != expectedRole) {
      return const FamilyDriveLinkRecoveryResult.empty();
    }
    final records = manifest.records
        .where(
          (record) =>
              _recordMatchesManifestIdentity(record, manifest) &&
              _recordMatchesRecoverySubject(
                record: record,
                role: expectedRole,
                subjectId: currentSubjectId,
              ) &&
              (record.isRevoked || _hasUsableFileRefs(record)),
        )
        .toList(growable: false);
    if (records.isEmpty) {
      return const FamilyDriveLinkRecoveryResult.empty();
    }
    final active = records.where((record) => !record.isRevoked).firstOrNull;
    await _store.saveRecords(
      records,
      activeLinkId: active?.storageId ?? '',
    );
    return FamilyDriveLinkRecoveryResult(
      records: records,
      activeRecord: active,
    );
  }

  List<FamilyDriveLinkRecord> _mergeCompatibleRecords({
    required String familyId,
    required String datasetId,
    required String playerId,
    required FamilyDriveLinkManifest? durableManifest,
    required List<FamilyDriveLinkRecord> localRecords,
    required FamilyDriveLinkRecord upsertRecord,
  }) {
    final mergedByParent = <String, FamilyDriveLinkRecord>{};
    void mergeRecord(FamilyDriveLinkRecord record, {bool force = false}) {
      if (!_recordMatchesIdentity(
        record,
        familyId: familyId,
        datasetId: datasetId,
        playerId: playerId,
      )) {
        return;
      }
      final parentMemberId = record.parentMemberId.trim();
      if (parentMemberId.isEmpty) return;
      final existing = mergedByParent[parentMemberId];
      if (force ||
          existing == null ||
          !record.updatedAt.isBefore(existing.updatedAt)) {
        mergedByParent[parentMemberId] = record;
      }
    }

    if (durableManifest != null &&
        _manifestMatchesIdentity(
          durableManifest,
          familyId: familyId,
          datasetId: datasetId,
          playerId: playerId,
        )) {
      for (final record in durableManifest.records) {
        mergeRecord(record);
      }
    }
    for (final record in localRecords) {
      mergeRecord(record);
    }
    mergeRecord(upsertRecord, force: true);
    return mergedByParent.values.toList(growable: false);
  }

  bool _manifestMatchesIdentity(
    FamilyDriveLinkManifest manifest, {
    required String familyId,
    required String datasetId,
    required String playerId,
  }) {
    return _sameRequiredId(manifest.familyId, familyId) &&
        _sameRequiredId(manifest.datasetId, datasetId) &&
        _sameRequiredId(manifest.playerId, playerId);
  }

  bool _recordMatchesManifestIdentity(
    FamilyDriveLinkRecord record,
    FamilyDriveLinkManifest manifest,
  ) {
    return _recordMatchesIdentity(
      record,
      familyId: manifest.familyId,
      datasetId: manifest.datasetId,
      playerId: manifest.playerId,
    );
  }

  bool _recordMatchesIdentity(
    FamilyDriveLinkRecord record, {
    required String familyId,
    required String datasetId,
    required String playerId,
  }) {
    return _sameRequiredId(record.familyId, familyId) &&
        _sameRequiredId(record.datasetId, datasetId) &&
        _sameRequiredId(record.playerId, playerId);
  }

  bool _recordMatchesRecoverySubject({
    required FamilyDriveLinkRecord record,
    required FamilyDriveLinkOwnerRole role,
    required String subjectId,
  }) {
    final expected = role == FamilyDriveLinkOwnerRole.child
        ? record.childSubjectId.trim()
        : record.parentSubjectId.trim();
    return expected.isNotEmpty && expected == subjectId.trim();
  }

  bool _hasUsableFileRefs(FamilyDriveLinkRecord record) {
    return record.coreBackupFileId.trim().isNotEmpty &&
        record.contributionFileId.trim().isNotEmpty;
  }

  bool _sameRequiredId(String a, String b) {
    final left = a.trim();
    final right = b.trim();
    return left.isNotEmpty && right.isNotEmpty && left == right;
  }

  void _validateCompletionAgainstPending(
    FamilyPairingCompletion completion,
    Map<String, dynamic> pending,
  ) {
    final inviteId = pending['inviteId']?.toString().trim() ?? '';
    final nonceHash = pending['nonceHash']?.toString().trim() ?? '';
    final parentMemberId = pending['parentMemberId']?.toString().trim() ?? '';
    final parentSubjectId = pending['parentSubjectId']?.toString().trim() ?? '';
    if (completion.inviteId != inviteId ||
        completion.nonceHash != nonceHash ||
        completion.record.parentMemberId != parentMemberId ||
        completion.record.parentSubjectId != parentSubjectId) {
      throw const FamilyDriveLinkException(
        FamilyDriveLinkException.accountMismatch,
      );
    }
    if (completion.corePermission.role != FamilyDrivePermissionRole.reader ||
        completion.contributionPermission.role !=
            FamilyDrivePermissionRole.writer ||
        completion.corePermission.fileId !=
            completion.record.coreBackupFileId ||
        completion.contributionPermission.fileId !=
            completion.record.contributionFileId) {
      throw const FamilyDriveLinkException(
        FamilyDriveLinkException.permissionMismatch,
      );
    }
  }
}

class GoogleDriveFamilyLinkGateway implements FamilyDriveLinkGateway {
  GoogleDriveFamilyLinkGateway({
    required Future<drive.DriveApi> Function({required bool requireInteractive})
        driveApiLoader,
    required Future<DriveConnectionInfo?> Function() accountLoader,
  })  : _driveApiLoader = driveApiLoader,
        _accountLoader = accountLoader;

  static const String appPropertyInviteId = _appPropertyInviteId;
  static const String appPropertyKind = _appPropertyKind;

  final Future<drive.DriveApi> Function({required bool requireInteractive})
      _driveApiLoader;
  final Future<DriveConnectionInfo?> Function() _accountLoader;

  @override
  Future<DriveConnectionInfo?> currentAccount() => _accountLoader();

  @override
  Future<FamilyDriveFileRef> ensureChildCoreSnapshot({
    required Map<String, dynamic> backupPayload,
    required Map<String, String> appProperties,
  }) async {
    return writeJsonFile(
      fileName: 'teo_note_backup.json',
      kind: FamilyDriveFileKind.coreBackup,
      payload: backupPayload,
      appProperties: appProperties,
    );
  }

  @override
  Future<FamilyDriveFileRef> ensureParentContributionFile({
    required String parentMemberId,
    required Map<String, dynamic> initialPayload,
    required Map<String, String> appProperties,
  }) async {
    return writeJsonFile(
      fileName: 'family_${_fileSafeId(parentMemberId)}_contribution.json',
      kind: FamilyDriveFileKind.parentContribution,
      payload: initialPayload,
      appProperties: appProperties,
    );
  }

  @override
  Future<FamilyDriveFileRef> writeJsonFile({
    required String fileName,
    required FamilyDriveFileKind kind,
    required Map<String, dynamic> payload,
    required Map<String, String> appProperties,
  }) async {
    final api = await _driveApiLoader(requireInteractive: false);
    final folderId = await _findOrCreateFolder(api);
    final existing = await _findTaggedFile(
      api,
      folderId: folderId,
      kind: kind,
      appProperties: appProperties,
    );
    final bytes = utf8.encode(jsonEncode(payload));
    final media = drive.Media(Stream.value(bytes), bytes.length);
    if (existing != null && existing.id != null) {
      final updated = await api.files.update(
        drive.File(name: fileName, appProperties: appProperties),
        existing.id!,
        uploadMedia: media,
        $fields: 'id,name,resourceKey,modifiedTime,appProperties',
      );
      return _fileRefFromDriveFile(updated, kind: kind);
    }
    final created = await api.files.create(
      drive.File(
        name: fileName,
        parents: <String>[folderId],
        appProperties: appProperties,
      ),
      uploadMedia: media,
      $fields: 'id,name,resourceKey,modifiedTime,appProperties',
    );
    return _fileRefFromDriveFile(created, kind: kind, created: true);
  }

  @override
  Future<FamilyDrivePermissionGrant> createPrivateUserPermission({
    required FamilyDriveFileRef file,
    required String emailAddress,
    required FamilyDrivePermissionRole role,
  }) async {
    final trimmedEmail = emailAddress.trim();
    if (trimmedEmail.isEmpty) {
      throw const FamilyDriveLinkException(
        FamilyDriveLinkException.missingPermissionEmail,
      );
    }
    final api = await _driveApiLoader(requireInteractive: false);
    final permission = await api.permissions.create(
      drive.Permission(
        type: 'user',
        role: role.name,
        emailAddress: trimmedEmail,
      ),
      file.id,
      sendNotificationEmail: false,
      $fields: 'id,role,type',
    );
    return FamilyDrivePermissionGrant(
      fileId: file.id,
      permissionId: permission.id?.trim() ?? '',
      role: _permissionRoleFromStorage(permission.role),
      type: permission.type?.trim().isNotEmpty == true
          ? permission.type!.trim()
          : 'user',
    );
  }

  @override
  Future<void> deletePermission({
    required String fileId,
    required String permissionId,
  }) async {
    if (fileId.trim().isEmpty || permissionId.trim().isEmpty) return;
    final api = await _driveApiLoader(requireInteractive: false);
    await api.permissions.delete(fileId, permissionId);
  }

  @override
  Future<void> trashFile({required String fileId}) async {
    if (fileId.trim().isEmpty) return;
    final api = await _driveApiLoader(requireInteractive: false);
    await api.files.update(drive.File(trashed: true), fileId);
  }

  @override
  Future<List<FamilyPairingCompletionCandidate>> listPairingCompletions({
    required String inviteId,
  }) async {
    final api = await _driveApiLoader(requireInteractive: false);
    final result = await api.files.list(
      q: "sharedWithMe=true and trashed=false and "
          "appProperties has { key='$_appPropertyInviteId' and value='${_escapeQueryValue(inviteId)}' } and "
          "appProperties has { key='$_appPropertyKind' and value='${FamilyDriveFileKind.pairingCompletion.name}' }",
      spaces: 'drive',
      orderBy: 'modifiedTime desc',
      $fields:
          'files(id,name,resourceKey,modifiedTime,appProperties,capabilities)',
    );
    final candidates = <FamilyPairingCompletionCandidate>[];
    for (final file in result.files ?? const <drive.File>[]) {
      final id = file.id;
      if (id == null || id.isEmpty) continue;
      final payload = await downloadJsonFile(
        _fileRefFromDriveFile(file,
            kind: FamilyDriveFileKind.pairingCompletion),
      );
      candidates.add(
        FamilyPairingCompletionCandidate(
          file: _fileRefFromDriveFile(
            file,
            kind: FamilyDriveFileKind.pairingCompletion,
          ),
          payload: payload,
        ),
      );
    }
    return candidates;
  }

  @override
  Future<Map<String, dynamic>> downloadJsonFile(FamilyDriveFileRef file) async {
    final api = await _driveApiLoader(requireInteractive: false);
    final media = await api.files.get(
      file.id,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    final content = await utf8.decoder.bind(media.stream).join();
    final dynamic decoded = jsonDecode(content);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    throw const FamilyDriveLinkException(
      FamilyDriveLinkException.completionMissing,
    );
  }

  @override
  Future<FamilyDriveFileRef> saveParentManifest({
    required FamilyDriveLinkManifest manifest,
  }) {
    return writeJsonFile(
      fileName: _parentManifestFileName,
      kind: FamilyDriveFileKind.parentManifest,
      payload: manifest.toMap(),
      appProperties: <String, String>{
        _appPropertyKind: FamilyDriveFileKind.parentManifest.name,
        if (manifest.familyId.trim().isNotEmpty)
          _appPropertyFamilyId: manifest.familyId.trim(),
        if (manifest.datasetId.trim().isNotEmpty)
          _appPropertyDatasetId: manifest.datasetId.trim(),
        if (manifest.playerId.trim().isNotEmpty)
          _appPropertyPlayerId: manifest.playerId.trim(),
      },
    );
  }

  @override
  Future<FamilyDriveLinkManifest?> loadParentManifest() async {
    final api = await _driveApiLoader(requireInteractive: false);
    final folderId = await _findFolderId(api);
    if (folderId == null) return null;
    final file = await _findTaggedFile(
      api,
      folderId: folderId,
      kind: FamilyDriveFileKind.parentManifest,
      appProperties: const <String, String>{
        _appPropertyKind: 'parentManifest',
      },
    );
    if (file?.id == null) return null;
    final payload = await downloadJsonFile(
      _fileRefFromDriveFile(file!, kind: FamilyDriveFileKind.parentManifest),
    );
    return FamilyDriveLinkManifest.fromMap(payload);
  }

  @override
  Future<FamilyDriveFileRef> saveChildManifest({
    required FamilyDriveLinkManifest manifest,
  }) {
    return writeJsonFile(
      fileName: _childManifestFileName,
      kind: FamilyDriveFileKind.childManifest,
      payload: manifest.toMap(),
      appProperties: <String, String>{
        _appPropertyKind: FamilyDriveFileKind.childManifest.name,
        if (manifest.familyId.trim().isNotEmpty)
          _appPropertyFamilyId: manifest.familyId.trim(),
        if (manifest.datasetId.trim().isNotEmpty)
          _appPropertyDatasetId: manifest.datasetId.trim(),
        if (manifest.playerId.trim().isNotEmpty)
          _appPropertyPlayerId: manifest.playerId.trim(),
      },
    );
  }

  @override
  Future<FamilyDriveLinkManifest?> loadChildManifest() async {
    final api = await _driveApiLoader(requireInteractive: false);
    final folderId = await _findFolderId(api);
    if (folderId == null) return null;
    final file = await _findTaggedFile(
      api,
      folderId: folderId,
      kind: FamilyDriveFileKind.childManifest,
      appProperties: const <String, String>{
        _appPropertyKind: 'childManifest',
      },
    );
    if (file?.id == null) return null;
    final payload = await downloadJsonFile(
      _fileRefFromDriveFile(file!, kind: FamilyDriveFileKind.childManifest),
    );
    return FamilyDriveLinkManifest.fromMap(payload);
  }

  Future<String> _findOrCreateFolder(drive.DriveApi api) async {
    final existing = await _findFolderId(api);
    if (existing != null) return existing;
    final created = await api.files.create(
      drive.File(
        name: _folderName,
        mimeType: 'application/vnd.google-apps.folder',
        appProperties: const <String, String>{
          _appPropertyKind: 'familyLinkFolder',
        },
      ),
      $fields: 'id',
    );
    return created.id!;
  }

  Future<String?> _findFolderId(drive.DriveApi api) async {
    final result = await api.files.list(
      q: "mimeType='application/vnd.google-apps.folder' and name='$_folderName' and trashed=false",
      spaces: 'drive',
      orderBy: 'modifiedTime desc',
      $fields: 'files(id,name,modifiedTime)',
    );
    return result.files?.firstOrNull?.id;
  }

  Future<drive.File?> _findTaggedFile(
    drive.DriveApi api, {
    required String folderId,
    required FamilyDriveFileKind kind,
    required Map<String, String> appProperties,
  }) async {
    final query = StringBuffer(
      "'$folderId' in parents and trashed=false and "
      "appProperties has { key='$_appPropertyKind' and value='${kind.name}' }",
    );
    final familyId = appProperties[_appPropertyFamilyId]?.trim() ?? '';
    final datasetId = appProperties[_appPropertyDatasetId]?.trim() ?? '';
    final playerId = appProperties[_appPropertyPlayerId]?.trim() ?? '';
    final parentMemberId =
        appProperties[_appPropertyParentMemberId]?.trim() ?? '';
    if (familyId.isNotEmpty) {
      query.write(
        " and appProperties has { key='$_appPropertyFamilyId' and value='${_escapeQueryValue(familyId)}' }",
      );
    }
    if (datasetId.isNotEmpty) {
      query.write(
        " and appProperties has { key='$_appPropertyDatasetId' and value='${_escapeQueryValue(datasetId)}' }",
      );
    }
    if (playerId.isNotEmpty) {
      query.write(
        " and appProperties has { key='$_appPropertyPlayerId' and value='${_escapeQueryValue(playerId)}' }",
      );
    }
    if (parentMemberId.isNotEmpty) {
      query.write(
        " and appProperties has { key='$_appPropertyParentMemberId' and value='${_escapeQueryValue(parentMemberId)}' }",
      );
    }
    final result = await api.files.list(
      q: query.toString(),
      spaces: 'drive',
      orderBy: 'modifiedTime desc',
      $fields:
          'files(id,name,resourceKey,modifiedTime,appProperties,capabilities)',
    );
    return result.files?.firstOrNull;
  }
}

const String _folderName = 'teo';
const String _childManifestFileName = 'family_links_manifest_v2.json';
const String _parentManifestFileName = 'family_link_manifest_v2.json';
const String _appPropertyKind = 'teoFamilyLinkKind';
const String _appPropertyInviteId = 'teoFamilyInviteId';
const String _appPropertyFamilyId = 'teoFamilyId';
const String _appPropertyDatasetId = 'teoDatasetId';
const String _appPropertyPlayerId = 'teoPlayerId';
const String _appPropertyParentMemberId = 'teoParentMemberId';

Map<String, String> _linkAppProperties({
  required String inviteId,
  required String familyId,
  required String datasetId,
  required String playerId,
  required String parentMemberId,
}) {
  return <String, String>{
    _appPropertyInviteId: inviteId.trim(),
    if (familyId.trim().isNotEmpty) _appPropertyFamilyId: familyId.trim(),
    if (datasetId.trim().isNotEmpty) _appPropertyDatasetId: datasetId.trim(),
    if (playerId.trim().isNotEmpty) _appPropertyPlayerId: playerId.trim(),
    _appPropertyParentMemberId: parentMemberId.trim(),
  };
}

FamilyDriveFileKind _fileKindFromStorage(String? value) {
  for (final kind in FamilyDriveFileKind.values) {
    if (kind.name == value) return kind;
  }
  return FamilyDriveFileKind.coreBackup;
}

FamilyDrivePermissionRole _permissionRoleFromStorage(String? value) {
  return value == FamilyDrivePermissionRole.writer.name
      ? FamilyDrivePermissionRole.writer
      : FamilyDrivePermissionRole.reader;
}

Map<String, String> _stringMap(dynamic raw) {
  if (raw is! Map) return const <String, String>{};
  return raw.map(
    (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
  );
}

String _normalizeBase64(String raw) {
  final normalized = raw.trim();
  final remainder = normalized.length % 4;
  if (remainder == 0) return normalized;
  return normalized.padRight(normalized.length + 4 - remainder, '=');
}

String _secureToken(int byteCount) {
  final random = math.Random.secure();
  final bytes = List<int>.generate(byteCount, (_) => random.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

String _fileSafeId(String value) {
  final safe = value
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_');
  return safe.isEmpty ? 'member' : safe;
}

String _escapeQueryValue(String value) => value.replaceAll("'", "\\'");

FamilyDriveFileRef _fileRefFromDriveFile(
  drive.File file, {
  required FamilyDriveFileKind kind,
  bool created = false,
}) {
  return FamilyDriveFileRef(
    id: file.id?.trim() ?? '',
    kind: kind,
    name: file.name?.trim() ?? '',
    resourceKey: file.resourceKey?.trim() ?? '',
    modifiedAt: file.modifiedTime,
    created: created,
    canRead: true,
    canWrite: file.capabilities?.canEdit == true,
    appProperties: _stringMap(file.appProperties),
  );
}

Future<void> _bestEffort(Future<void> Function() action) async {
  try {
    await action();
  } catch (error, stackTrace) {
    debugPrint('Family Drive link cleanup skipped: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
