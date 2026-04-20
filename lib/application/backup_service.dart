import '../domain/repositories/backup_repository.dart';
import 'drive_connection_info.dart';
import 'drive_backup_service.dart';

class BackupService {
  final BackupRepository _repository;

  BackupService(this._repository);

  Future<void> backup() => _repository.backup();

  Future<void> restoreLatest() => _repository.restoreLatest();

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

  Stream<void> driveAccountStateChanges() {
    if (_repository case final DriveBackupService drive) {
      return drive.driveAccountStateChanges();
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
}
