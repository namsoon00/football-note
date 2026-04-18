import 'backup_asset_store_types.dart';

BackupAssetFileStore createBackupAssetFileStore() =>
    _NoopBackupAssetFileStore();

class _NoopBackupAssetFileStore implements BackupAssetFileStore {
  @override
  BackupAssetRecord? readFileSync({
    required String assetId,
    required String sourcePath,
    String? preferredFileName,
  }) {
    return null;
  }

  @override
  Future<String?> restoreFile(BackupAssetRecord record) async {
    return null;
  }
}
