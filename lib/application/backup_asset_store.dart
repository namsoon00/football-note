import 'backup_asset_store_stub.dart'
    if (dart.library.io) 'backup_asset_store_io.dart' as platform;
import 'backup_asset_store_types.dart';

BackupAssetFileStore createBackupAssetFileStore() {
  return platform.createBackupAssetFileStore();
}
