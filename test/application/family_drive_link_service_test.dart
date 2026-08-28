import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/drive_connection_info.dart';
import 'package:football_note/application/family_drive_link_service.dart';
import 'package:football_note/domain/repositories/option_repository.dart';

void main() {
  const parentAccount = DriveConnectionInfo(
    email: 'parent@example.com',
    displayName: 'Parent One',
    subjectId: 'parent-subject',
  );
  const childAccount = DriveConnectionInfo(
    email: 'child@example.com',
    displayName: 'Child One',
    subjectId: 'child-subject',
  );
  final issuedAt = DateTime.utc(2026, 8, 27, 10);

  test('pairing offer is versioned, expiring, and durable maps omit email', () {
    final offer = FamilyPairingOffer.create(
      parentAccount: parentAccount,
      now: issuedAt,
    );

    final parsed = FamilyPairingOffer.parse(
      offer.toQrPayload(),
      now: issuedAt.add(const Duration(minutes: 1)),
    );

    expect(parsed.schemaVersion, FamilyPairingOffer.schemaVersionValue);
    expect(parsed.inviteId, offer.inviteId);
    expect(parsed.nonce, offer.nonce);
    expect(
        parsed.expiresAt.difference(parsed.issuedAt), FamilyPairingOffer.ttl);
    expect(parsed.parentEmailForPermission, parentAccount.email);
    expect(_containsValue(offer.toPendingMap(), parentAccount.email), isFalse);
    expect(_containsValue(offer.toDisplayMap(), parentAccount.email), isFalse);

    final record = _recordFromOffer(offer);
    final manifest = FamilyDriveLinkManifest(
      ownerRole: FamilyDriveLinkOwnerRole.parent,
      familyId: record.familyId,
      datasetId: record.datasetId,
      playerId: record.playerId,
      records: <FamilyDriveLinkRecord>[record],
      createdAt: issuedAt,
      updatedAt: issuedAt,
    );
    expect(_containsValue(record.toMap(), parentAccount.email), isFalse);
    expect(_containsValue(manifest.toMap(), parentAccount.email), isFalse);
  });

  test('pairing parser rejects malformed, expired, and unsupported payloads',
      () {
    expect(
      () => FamilyPairingOffer.parse('not-a-family-link', now: issuedAt),
      throwsA(_familyLinkError(FamilyDriveLinkException.malformedOffer)),
    );

    final offer = FamilyPairingOffer.create(
      parentAccount: parentAccount,
      now: issuedAt,
    );
    expect(
      () => FamilyPairingOffer.parse(
        offer.toQrPayload(),
        now: issuedAt.add(const Duration(minutes: 6)),
      ),
      throwsA(_familyLinkError(FamilyDriveLinkException.expiredOffer)),
    );

    final unsupported = _encodeOfferPayload(<String, dynamic>{
      ...offer.toQrMap(),
      'version': FamilyPairingOffer.schemaVersionValue + 1,
    });
    expect(
      () => FamilyPairingOffer.parse(unsupported, now: issuedAt),
      throwsA(
        _familyLinkError(FamilyDriveLinkException.unsupportedOfferVersion),
      ),
    );
  });

  test('child approval creates exact per-file permissions and is single use',
      () async {
    final store = FamilyDriveLinkStore(_MemoryOptionRepository());
    final gateway = _FakeFamilyDriveLinkGateway(account: childAccount);
    final service = FamilyDriveLinkService(store: store, gateway: gateway);
    final offer = FamilyPairingOffer.create(
      parentAccount: parentAccount,
      now: issuedAt,
    );

    final record = await service.approveOfferOnChild(
      qrPayload: offer.toQrPayload(),
      familyId: 'family-1',
      datasetId: 'dataset-1',
      playerId: 'player-1',
      childBackupPayload: _childBackupPayload(),
      parentContributionPayload: _contributionPayload(),
      now: issuedAt.add(const Duration(minutes: 1)),
    );

    expect(record.coreBackupFileId, 'core-file');
    expect(record.contributionFileId, 'contribution-${offer.parentMemberId}');
    expect(record.corePermissionId, isNotEmpty);
    expect(record.contributionPermissionId, isNotEmpty);
    expect(gateway.permissionCalls, hasLength(3));
    expect(
      gateway.permissionCalls
          .where((call) => call.fileKind == FamilyDriveFileKind.coreBackup)
          .single
          .role,
      FamilyDrivePermissionRole.reader,
    );
    expect(
      gateway.permissionCalls
          .where(
            (call) => call.fileKind == FamilyDriveFileKind.parentContribution,
          )
          .single
          .role,
      FamilyDrivePermissionRole.writer,
    );
    expect(
      gateway.permissionCalls
          .where(
            (call) => call.fileKind == FamilyDriveFileKind.pairingCompletion,
          )
          .single
          .role,
      FamilyDrivePermissionRole.reader,
    );

    await expectLater(
      service.approveOfferOnChild(
        qrPayload: offer.toQrPayload(),
        familyId: 'family-1',
        datasetId: 'dataset-1',
        playerId: 'player-1',
        childBackupPayload: _childBackupPayload(),
        parentContributionPayload: _contributionPayload(),
        now: issuedAt.add(const Duration(minutes: 2)),
      ),
      throwsA(_familyLinkError(FamilyDriveLinkException.inviteAlreadyUsed)),
    );
  });

  test('child approval rolls back permissions and files after partial failure',
      () async {
    final store = FamilyDriveLinkStore(_MemoryOptionRepository());
    final gateway = _FakeFamilyDriveLinkGateway(
      account: childAccount,
      failPairingCompletionWrite: true,
    );
    final service = FamilyDriveLinkService(store: store, gateway: gateway);
    final offer = FamilyPairingOffer.create(
      parentAccount: parentAccount,
      now: issuedAt,
    );

    await expectLater(
      service.approveOfferOnChild(
        qrPayload: offer.toQrPayload(),
        familyId: 'family-1',
        datasetId: 'dataset-1',
        playerId: 'player-1',
        childBackupPayload: _childBackupPayload(),
        parentContributionPayload: _contributionPayload(),
        now: issuedAt.add(const Duration(minutes: 1)),
      ),
      throwsA(isA<StateError>()),
    );

    expect(
      gateway.deletedPermissions.map((call) => call.permissionId),
      containsAll(<String>['permission-1', 'permission-2']),
    );
    expect(
      gateway.trashedFileIds,
      containsAll(
          <String>['core-file', 'contribution-${offer.parentMemberId}']),
    );
    expect(store.loadRecords(), isEmpty);
    expect(store.isInviteUsed(offer.inviteId), isFalse);
  });

  test('parent completion validates pending offer, roles, and single use',
      () async {
    final parentStore = FamilyDriveLinkStore(_MemoryOptionRepository());
    final childStore = FamilyDriveLinkStore(_MemoryOptionRepository());
    final gateway = _FakeFamilyDriveLinkGateway(account: parentAccount);
    final parentService = FamilyDriveLinkService(
      store: parentStore,
      gateway: gateway,
    );
    final childService = FamilyDriveLinkService(
      store: childStore,
      gateway: gateway,
    );
    final offer = await parentService.createParentOffer(now: issuedAt);
    gateway.account = childAccount;
    await childService.approveOfferOnChild(
      qrPayload: offer.toQrPayload(),
      familyId: 'family-1',
      datasetId: 'dataset-1',
      playerId: 'player-1',
      childBackupPayload: _childBackupPayload(),
      parentContributionPayload: _contributionPayload(),
      now: issuedAt.add(const Duration(minutes: 1)),
    );

    gateway.account = const DriveConnectionInfo(
      email: 'other@example.com',
      displayName: 'Other Parent',
      subjectId: 'other-parent-subject',
    );
    await expectLater(
      parentService.completeParentPairing(
        inviteId: offer.inviteId,
        now: issuedAt.add(const Duration(minutes: 2)),
      ),
      throwsA(_familyLinkError(FamilyDriveLinkException.accountMismatch)),
    );

    gateway.account = parentAccount;
    var restored = false;
    final record = await parentService.completeParentPairing(
      inviteId: offer.inviteId,
      restoreChildBackup: (record, childBackup) async {
        restored = true;
        expect(childBackup['format'], 'teo_note_backup');
      },
      now: issuedAt.add(const Duration(minutes: 2)),
    );

    expect(restored, isTrue);
    expect(record.parentManifestFileId, 'parent-manifest-file');
    expect(parentStore.loadActiveRecord()?.familyId, 'family-1');
    expect(gateway.savedParentManifest?.ownerRole,
        FamilyDriveLinkOwnerRole.parent);

    await expectLater(
      parentService.completeParentPairing(
        inviteId: offer.inviteId,
        now: issuedAt.add(const Duration(minutes: 3)),
      ),
      throwsA(_familyLinkError(FamilyDriveLinkException.inviteAlreadyUsed)),
    );
  });

  test('parent completion rejects incorrect permission roles', () async {
    final store = FamilyDriveLinkStore(_MemoryOptionRepository());
    final gateway = _FakeFamilyDriveLinkGateway(account: parentAccount);
    final service = FamilyDriveLinkService(store: store, gateway: gateway);
    final offer = await service.createParentOffer(now: issuedAt);
    final record = _recordFromOffer(offer);
    final completion = FamilyPairingCompletion(
      inviteId: offer.inviteId,
      nonceHash: offer.nonceHash,
      record: record,
      corePermission: FamilyDrivePermissionGrant(
        fileId: record.coreBackupFileId,
        permissionId: record.corePermissionId,
        role: FamilyDrivePermissionRole.reader,
      ),
      contributionPermission: FamilyDrivePermissionGrant(
        fileId: record.contributionFileId,
        permissionId: record.contributionPermissionId,
        role: FamilyDrivePermissionRole.reader,
      ),
      createdAt: issuedAt.add(const Duration(minutes: 1)),
    );
    gateway.completionCandidates.add(
      FamilyPairingCompletionCandidate(
        file: const FamilyDriveFileRef(
          id: 'completion-file',
          kind: FamilyDriveFileKind.pairingCompletion,
        ),
        payload: completion.toMap(),
      ),
    );

    await expectLater(
      service.completeParentPairing(
        inviteId: offer.inviteId,
        now: issuedAt.add(const Duration(minutes: 2)),
      ),
      throwsA(_familyLinkError(FamilyDriveLinkException.permissionMismatch)),
    );
  });

  test('unlink tombstones the record and removes stored Drive permissions',
      () async {
    final store = FamilyDriveLinkStore(_MemoryOptionRepository());
    final gateway = _FakeFamilyDriveLinkGateway(account: childAccount);
    final service = FamilyDriveLinkService(store: store, gateway: gateway);
    final offer = FamilyPairingOffer.create(
      parentAccount: parentAccount,
      now: issuedAt,
    );
    final record = _recordFromOffer(offer);
    await store.saveRecord(record);

    await service.childInitiatedUnlink(
      record: record,
      now: issuedAt.add(const Duration(minutes: 3)),
    );

    expect(
      gateway.deletedPermissions.map((call) => call.permissionId),
      containsAll(<String>['core-permission', 'contribution-permission']),
    );
    final stored = store.loadRecords().single;
    expect(stored.isRevoked, isTrue);
    expect(stored.revocationReason, 'child_unlinked');
    expect(store.loadActiveRecord(), isNull);
  });

  test('parent reinstall recovers durable link manifest without email',
      () async {
    final repository = _MemoryOptionRepository();
    final store = FamilyDriveLinkStore(repository);
    final gateway = _FakeFamilyDriveLinkGateway(account: parentAccount);
    final service = FamilyDriveLinkService(store: store, gateway: gateway);
    final offer = FamilyPairingOffer.create(
      parentAccount: parentAccount,
      now: issuedAt,
    );
    final record = _recordFromOffer(offer);
    gateway.savedParentManifest = FamilyDriveLinkManifest(
      ownerRole: FamilyDriveLinkOwnerRole.parent,
      familyId: record.familyId,
      datasetId: record.datasetId,
      playerId: record.playerId,
      records: <FamilyDriveLinkRecord>[record],
      createdAt: issuedAt,
      updatedAt: issuedAt,
    );

    final recovered = await service.recoverParentLinkAfterReinstall();

    expect(recovered?.parentMemberId, offer.parentMemberId);
    expect(store.loadActiveRecord()?.coreBackupFileId, 'core-file');
    expect(
      _containsValue(repository.values, parentAccount.email),
      isFalse,
    );
  });
}

Matcher _familyLinkError(String code) {
  return isA<FamilyDriveLinkException>().having(
    (error) => error.code,
    'code',
    code,
  );
}

String _encodeOfferPayload(Map<String, dynamic> payload) {
  return '${FamilyPairingOffer.payloadPrefix}'
      '${base64UrlEncode(utf8.encode(jsonEncode(payload)))}';
}

bool _containsValue(Object? value, String expected) {
  if (value == expected) return true;
  if (value is Map) {
    return value.values.any((item) => _containsValue(item, expected));
  }
  if (value is Iterable) {
    return value.any((item) => _containsValue(item, expected));
  }
  return false;
}

Map<String, dynamic> _childBackupPayload() {
  return <String, dynamic>{
    'format': 'teo_note_backup',
    'version': 6,
    'createdAt': '2026-08-27T10:00:00.000Z',
    'entries': const <Map<String, dynamic>>[],
    'options': const <String, dynamic>{},
    'optionRecords': const <Map<String, dynamic>>[],
    'family': const <String, dynamic>{
      'updatedByRole': 'child',
      'familyLayerOnly': false,
    },
  };
}

Map<String, dynamic> _contributionPayload() {
  return <String, dynamic>{
    'format': 'teo_note_family_contribution',
    'version': 6,
    'createdAt': '2026-08-27T10:00:00.000Z',
    'entries': const <Map<String, dynamic>>[],
    'options': const <String, dynamic>{},
    'optionRecords': const <Map<String, dynamic>>[],
    'family': const <String, dynamic>{
      'updatedByRole': 'parent',
      'familyLayerOnly': true,
    },
  };
}

FamilyDriveLinkRecord _recordFromOffer(FamilyPairingOffer offer) {
  return FamilyDriveLinkRecord(
    familyId: 'family-1',
    datasetId: 'dataset-1',
    playerId: 'player-1',
    parentMemberId: offer.parentMemberId,
    parentSubjectId: offer.parentSubjectId,
    parentDisplayName: offer.parentDisplayName,
    childSubjectId: 'child-subject',
    coreBackupFileId: 'core-file',
    contributionFileId: 'contribution-${offer.parentMemberId}',
    corePermissionId: 'core-permission',
    contributionPermissionId: 'contribution-permission',
    pairingInviteId: offer.inviteId,
    pairingNonceHash: offer.nonceHash,
    pairingCompletionFileId: 'completion-file',
    createdAt: offer.issuedAt,
    updatedAt: offer.issuedAt,
  );
}

class _FakeFamilyDriveLinkGateway implements FamilyDriveLinkGateway {
  _FakeFamilyDriveLinkGateway({
    required this.account,
    this.failPairingCompletionWrite = false,
  });

  DriveConnectionInfo? account;
  final bool failPairingCompletionWrite;
  final List<_PermissionCall> permissionCalls = <_PermissionCall>[];
  final List<_DeletedPermission> deletedPermissions = <_DeletedPermission>[];
  final List<String> trashedFileIds = <String>[];
  final List<FamilyPairingCompletionCandidate> completionCandidates =
      <FamilyPairingCompletionCandidate>[];
  FamilyDriveLinkManifest? savedParentManifest;
  Map<String, dynamic> childBackup = _childBackupPayload();
  Map<String, dynamic> contribution = _contributionPayload();
  var _permissionCounter = 0;

  @override
  Future<DriveConnectionInfo?> currentAccount() async => account;

  @override
  Future<FamilyDriveFileRef> ensureChildCoreSnapshot({
    required Map<String, dynamic> backupPayload,
    required Map<String, String> appProperties,
  }) async {
    childBackup = backupPayload;
    return FamilyDriveFileRef(
      id: 'core-file',
      kind: FamilyDriveFileKind.coreBackup,
      modifiedAt: DateTime.utc(2026, 8, 27, 10, 1),
      created: true,
      canRead: true,
      canWrite: false,
      appProperties: appProperties,
    );
  }

  @override
  Future<FamilyDriveFileRef> ensureParentContributionFile({
    required String parentMemberId,
    required Map<String, dynamic> initialPayload,
    required Map<String, String> appProperties,
  }) async {
    contribution = initialPayload;
    return FamilyDriveFileRef(
      id: 'contribution-$parentMemberId',
      kind: FamilyDriveFileKind.parentContribution,
      modifiedAt: DateTime.utc(2026, 8, 27, 10, 1),
      created: true,
      canRead: true,
      canWrite: true,
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
    if (failPairingCompletionWrite &&
        kind == FamilyDriveFileKind.pairingCompletion) {
      throw StateError('completion write failed');
    }
    final file = FamilyDriveFileRef(
      id: kind == FamilyDriveFileKind.childManifest
          ? 'child-manifest-file'
          : 'completion-file',
      kind: kind,
      modifiedAt: DateTime.utc(2026, 8, 27, 10, 2),
      created: true,
      canRead: true,
      canWrite: kind != FamilyDriveFileKind.coreBackup,
      appProperties: appProperties,
    );
    if (kind == FamilyDriveFileKind.pairingCompletion) {
      completionCandidates.add(
        FamilyPairingCompletionCandidate(file: file, payload: payload),
      );
    }
    return file;
  }

  @override
  Future<FamilyDrivePermissionGrant> createPrivateUserPermission({
    required FamilyDriveFileRef file,
    required String emailAddress,
    required FamilyDrivePermissionRole role,
  }) async {
    _permissionCounter += 1;
    permissionCalls.add(
      _PermissionCall(
        fileId: file.id,
        fileKind: file.kind,
        emailAddress: emailAddress,
        role: role,
      ),
    );
    return FamilyDrivePermissionGrant(
      fileId: file.id,
      permissionId: 'permission-$_permissionCounter',
      role: role,
    );
  }

  @override
  Future<void> deletePermission({
    required String fileId,
    required String permissionId,
  }) async {
    deletedPermissions.add(
      _DeletedPermission(fileId: fileId, permissionId: permissionId),
    );
  }

  @override
  Future<void> trashFile({required String fileId}) async {
    trashedFileIds.add(fileId);
  }

  @override
  Future<List<FamilyPairingCompletionCandidate>> listPairingCompletions({
    required String inviteId,
  }) async {
    return completionCandidates
        .where((candidate) => candidate.payload['inviteId'] == inviteId)
        .toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>> downloadJsonFile(FamilyDriveFileRef file) async {
    return switch (file.kind) {
      FamilyDriveFileKind.coreBackup => childBackup,
      FamilyDriveFileKind.parentContribution => contribution,
      _ => <String, dynamic>{},
    };
  }

  @override
  Future<FamilyDriveFileRef> saveParentManifest({
    required FamilyDriveLinkManifest manifest,
  }) async {
    savedParentManifest = manifest;
    return const FamilyDriveFileRef(
      id: 'parent-manifest-file',
      kind: FamilyDriveFileKind.parentManifest,
      created: true,
      canRead: true,
      canWrite: true,
    );
  }

  @override
  Future<FamilyDriveLinkManifest?> loadParentManifest() async {
    return savedParentManifest;
  }
}

class _PermissionCall {
  const _PermissionCall({
    required this.fileId,
    required this.fileKind,
    required this.emailAddress,
    required this.role,
  });

  final String fileId;
  final FamilyDriveFileKind fileKind;
  final String emailAddress;
  final FamilyDrivePermissionRole role;
}

class _DeletedPermission {
  const _DeletedPermission({
    required this.fileId,
    required this.permissionId,
  });

  final String fileId;
  final String permissionId;
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> values = <String, dynamic>{};

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = values[key];
    if (value is List<String>) return value;
    return defaults;
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = values[key];
    if (value is List<int>) return value;
    return defaults;
  }

  @override
  T? getValue<T>(String key) => values[key] as T?;

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    values[key] = options;
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    values[key] = value;
  }
}
