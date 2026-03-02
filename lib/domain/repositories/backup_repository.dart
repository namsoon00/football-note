abstract class BackupRepository {
  Future<void> backup();
  Future<void> restoreLatest();

  Future<bool> backupIfSignedIn({bool requireAutoOnSave = false});
  Future<void> autoBackupDaily();

  bool isAutoDailyEnabled();
  Future<void> setAutoDailyEnabled(bool value);

  bool isAutoOnSaveEnabled();
  Future<void> setAutoOnSaveEnabled(bool value);

  DateTime? getLastBackup();
}
