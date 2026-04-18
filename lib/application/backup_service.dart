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

  Future<void> signOut() async {
    if (_repository case final DriveBackupService drive) {
      await drive.signOut();
    }
  }
}
