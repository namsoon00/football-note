import '../domain/repositories/backup_repository.dart';
import 'backup_restore_plan.dart';
import 'drive_connection_info.dart';
import 'drive_backup_service.dart';
import 'family_drive_link_service.dart';
import 'family_access_service.dart';

class BackupService {
  final BackupRepository _repository;

  BackupService(this._repository);

  Future<void> backup() => _repository.backup();

  Future<void> restoreLatest() => _repository.restoreLatest();

  Future<RestoreReceipt> restoreLatestWithMode(
    RestoreMode mode, {
    String? expectedPlanHash,
  }) async {
    if (_repository case final DriveBackupService drive) {
      return drive.restoreLatestWithMode(
        mode,
        expectedPlanHash: expectedPlanHash,
      );
    }
    await _repository.restoreLatest();
    return const RestoreReceipt(
      planHash: '',
      applied: 0,
      updated: 0,
      skipped: 0,
      conflicts: 0,
      deleted: 0,
    );
  }

  Future<RestorePlan?> previewLatestRestore({
    RestoreMode mode = RestoreMode.safeMerge,
  }) async {
    if (_repository case final DriveBackupService drive) {
      return drive.previewLatestRestore(mode: mode);
    }
    return null;
  }

  BackupSnapshotDescriptor? describeLocalBackup() {
    if (_repository case final DriveBackupService drive) {
      return drive.describeLocalBackup();
    }
    return null;
  }

  Future<void> restorePreviousBackup() async {
    if (_repository case final DriveBackupService drive) {
      await drive.restorePreviousBackup();
      return;
    }
    throw StateError('Previous backup restore is not available.');
  }

  Future<void> autoBackupDaily() => _repository.autoBackupDaily();

  Future<bool> backupIfSignedIn({bool requireAutoOnSave = false}) =>
      _repository.backupIfSignedIn(requireAutoOnSave: requireAutoOnSave);

  bool isAutoDailyEnabled() => _repository.isAutoDailyEnabled();

  Future<void> setAutoDailyEnabled(bool value) =>
      _repository.setAutoDailyEnabled(value);

  bool isAutoOnSaveEnabled() => _repository.isAutoOnSaveEnabled();

  Future<void> setAutoOnSaveEnabled(bool value) =>
      _repository.setAutoOnSaveEnabled(value);

  DateTime? getLastBackup() => _repository.getLastBackup();

  DateTime? getLastRecordBackup() {
    if (_repository case final DriveBackupService drive) {
      return drive.getLastRecordBackup();
    }
    return _repository.getLastBackup();
  }

  DateTime? getPreviousBackupCreatedAt() {
    if (_repository case final DriveBackupService drive) {
      return drive.getPreviousBackupCreatedAt();
    }
    return null;
  }

  DateTime? getLastFamilySyncPush() {
    if (_repository case final DriveBackupService drive) {
      return drive.getLastFamilySyncPush();
    }
    return null;
  }

  DateTime? getLastFamilySyncPull() {
    if (_repository case final DriveBackupService drive) {
      return drive.getLastFamilySyncPull();
    }
    return null;
  }

  DateTime? getLastFamilyRefresh() {
    if (_repository case final DriveBackupService drive) {
      return drive.getLastFamilyRefresh();
    }
    return null;
  }

  bool hasPendingParentSharedChanges() {
    if (_repository case final DriveBackupService drive) {
      return drive.hasPendingParentSharedChanges();
    }
    return false;
  }

  bool hasLocalPreRestoreBackup() {
    if (_repository case final DriveBackupService drive) {
      return drive.hasLocalPreRestoreBackup();
    }
    return false;
  }

  DateTime? getLocalPreRestoreTime() {
    if (_repository case final DriveBackupService drive) {
      return drive.getLocalPreRestoreTime();
    }
    return null;
  }

  Future<void> restoreLocalPreBackup() async {
    if (_repository case final DriveBackupService drive) {
      await drive.restoreLocalPreBackup();
      return;
    }
    throw StateError('Local restore is not available.');
  }

  List<LocalBackupRecoveryPoint> getLocalRecoveryPoints() {
    if (_repository case final DriveBackupService drive) {
      return drive.getLocalRecoveryPoints();
    }
    return const <LocalBackupRecoveryPoint>[];
  }

  Future<void> restoreLocalRecoveryPoint(String id) async {
    if (_repository case final DriveBackupService drive) {
      await drive.restoreLocalRecoveryPoint(id);
      return;
    }
    throw StateError('Local restore is not available.');
  }

  Future<void> signIn() async {
    if (_repository case final DriveBackupService drive) {
      await drive.signIn();
    }
  }

  Future<bool> isSignedIn() async {
    if (_repository case final DriveBackupService drive) {
      return drive.isSignedIn();
    }
    return false;
  }

  Future<DriveConnectionInfo?> getDriveConnectionInfo() async {
    if (_repository case final DriveBackupService drive) {
      return drive.getDriveConnectionInfo();
    }
    return null;
  }

  Future<DriveConnectionInfo?> getSharedChildDriveConnectionInfo({
    bool allowRemoteLookup = false,
  }) async {
    if (_repository case final DriveBackupService drive) {
      return drive.getSharedChildDriveConnectionInfo(
        allowRemoteLookup: allowRemoteLookup,
      );
    }
    return null;
  }

  Future<bool> hasRemotePlayerBackup() async {
    if (_repository case final DriveBackupService drive) {
      return drive.hasRemotePlayerBackup();
    }
    return false;
  }

  bool hasChangedPlayerDriveConnection() {
    if (_repository case final DriveBackupService drive) {
      return drive.hasChangedPlayerDriveConnection();
    }
    return false;
  }

  PlayerDriveBindingState getPlayerDriveBindingState() {
    if (_repository case final DriveBackupService drive) {
      return drive.getPlayerDriveBindingState();
    }
    return PlayerDriveBindingState.notConnected;
  }

  bool hasLegacyPlayerDriveConnection() {
    if (_repository case final DriveBackupService drive) {
      return drive.hasLegacyPlayerDriveConnection();
    }
    return false;
  }

  bool needsPlayerDriveImportBeforeBackup() {
    if (_repository case final DriveBackupService drive) {
      return drive.needsPlayerDriveImportBeforeBackup();
    }
    return false;
  }

  Future<bool> importChangedPlayerDriveBackup() async {
    if (_repository case final DriveBackupService drive) {
      return drive.importChangedPlayerDriveBackup();
    }
    return false;
  }

  Future<bool> startChangedPlayerDriveWithEmptyData() async {
    if (_repository case final DriveBackupService drive) {
      return drive.startChangedPlayerDriveWithEmptyData();
    }
    return false;
  }

  Stream<void> driveAccountStateChanges() {
    if (_repository case final DriveBackupService drive) {
      return drive.driveAccountStateChanges();
    }
    return const Stream<void>.empty();
  }

  Stream<void> dataChanges() {
    if (_repository case final DriveBackupService drive) {
      return drive.dataChanges();
    }
    return const Stream<void>.empty();
  }

  String getSharedChildDriveEmail() {
    if (_repository case final DriveBackupService drive) {
      return drive.getSharedChildDriveEmail();
    }
    return '';
  }

  String getSharedChildDriveLabel() {
    if (_repository case final DriveBackupService drive) {
      return drive.getSharedChildDriveLabel();
    }
    return '';
  }

  String getSavedRecordDriveEmail() {
    if (_repository case final DriveBackupService drive) {
      return drive.getSavedRecordDriveEmail();
    }
    return '';
  }

  String getSavedRecordDriveLabel() {
    if (_repository case final DriveBackupService drive) {
      return drive.getSavedRecordDriveLabel();
    }
    return '';
  }

  String getSavedPlayerDriveEmail() {
    return getSavedRecordDriveEmail();
  }

  String getSavedPlayerDriveLabel() {
    return getSavedRecordDriveLabel();
  }

  String getSavedParentDriveEmail() {
    if (_repository case final DriveBackupService drive) {
      return drive.getSavedParentDriveEmail();
    }
    return '';
  }

  String getSavedParentDriveLabel() {
    if (_repository case final DriveBackupService drive) {
      return drive.getSavedParentDriveLabel();
    }
    return '';
  }

  Future<void> rememberRecordDriveConnection() async {
    if (_repository case final DriveBackupService drive) {
      await drive.rememberRecordDriveConnection();
    }
  }

  Future<void> rememberPlayerDriveConnection() async {
    await rememberRecordDriveConnection();
  }

  Future<void> rememberParentDriveConnection() async {
    if (_repository case final DriveBackupService drive) {
      await drive.rememberParentDriveConnection();
    }
  }

  Future<void> rememberCurrentRoleDriveConnection() async {
    if (_repository case final DriveBackupService drive) {
      await drive.rememberCurrentRoleDriveConnection();
    }
  }

  bool needsDriveImportBeforeBackup() {
    if (_repository case final DriveBackupService drive) {
      return drive.needsDriveImportBeforeBackup();
    }
    return false;
  }

  Future<void> signInForSavedRecord() async {
    if (_repository case final DriveBackupService drive) {
      await drive.signInForSavedRecord();
    }
  }

  Future<void> signInForSavedPlayer() async {
    await signInForSavedRecord();
  }

  Future<void> signInForSavedParent() async {
    if (_repository case final DriveBackupService drive) {
      await drive.signInForSavedParent();
    }
  }

  Future<void> signOut() async {
    if (_repository case final DriveBackupService drive) {
      await drive.signOut();
    }
  }

  Future<void> revokeGoogleAppAccess() async {
    if (_repository case final DriveBackupService drive) {
      await drive.revokeGoogleAppAccess();
    }
  }

  bool hasActiveFamilyDriveLink() {
    if (_repository case final DriveBackupService drive) {
      return drive.hasActiveFamilyDriveLink();
    }
    return false;
  }

  FamilyDriveLinkRecord? getActiveFamilyDriveLink() {
    if (_repository case final DriveBackupService drive) {
      return drive.getActiveFamilyDriveLink();
    }
    return null;
  }

  String getActiveFamilyDriveLinkParentName() {
    if (_repository case final DriveBackupService drive) {
      return drive.getActiveFamilyDriveLinkParentName();
    }
    return '';
  }

  Future<FamilyPairingOffer> createParentPairingOffer() async {
    if (_repository case final DriveBackupService drive) {
      return drive.createParentPairingOffer();
    }
    throw StateError('Family pairing is not available.');
  }

  Future<FamilyDriveLinkRecord> approveFamilyPairingOffer(
    String qrPayload,
  ) async {
    if (_repository case final DriveBackupService drive) {
      return drive.approveFamilyPairingOffer(qrPayload);
    }
    throw StateError('Family pairing is not available.');
  }

  Future<FamilyDriveLinkRecord> completeParentPairing(String inviteId) async {
    if (_repository case final DriveBackupService drive) {
      return drive.completeParentPairing(inviteId);
    }
    throw StateError('Family pairing is not available.');
  }

  Future<void> unlinkActiveFamilyLink() async {
    if (_repository case final DriveBackupService drive) {
      await drive.unlinkActiveFamilyLink();
    }
  }

  Future<bool> setCurrentFamilyRole(FamilyRole role) async {
    if (_repository case final DriveBackupService drive) {
      await drive.setCurrentFamilyRole(role);
      return true;
    }
    return false;
  }

  Future<void> markParentSharedDataDirty() async {
    if (_repository case final DriveBackupService drive) {
      await drive.markParentSharedDataDirty();
    }
  }

  Future<bool> refreshParentSharedDataIfNeeded() async {
    if (_repository case final DriveBackupService drive) {
      return drive.refreshParentSharedDataIfNeeded();
    }
    return false;
  }

  Future<FamilySharedSyncResult> refreshFamilySharedDataIfNeeded() async {
    if (_repository case final DriveBackupService drive) {
      return drive.refreshFamilySharedDataIfNeeded();
    }
    return const FamilySharedSyncResult.none(role: FamilyRole.child);
  }
}
