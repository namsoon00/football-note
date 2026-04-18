import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'backup_asset_store_types.dart';

BackupAssetFileStore createBackupAssetFileStore() => _IoBackupAssetFileStore();

class _IoBackupAssetFileStore implements BackupAssetFileStore {
  @override
  BackupAssetRecord? readFileSync({
    required String assetId,
    required String sourcePath,
    String? preferredFileName,
  }) {
    final trimmed = sourcePath.trim();
    if (trimmed.isEmpty || trimmed.startsWith('data:')) {
      return null;
    }
    final file = File(trimmed);
    if (!file.existsSync()) {
      return null;
    }
    final bytes = file.readAsBytesSync();
    if (bytes.isEmpty) {
      return null;
    }
    return BackupAssetRecord(
      assetId: assetId,
      fileName: _safeFileName(preferredFileName ?? _fileNameFromPath(trimmed)),
      bytesBase64: base64Encode(bytes),
    );
  }

  @override
  Future<String?> restoreFile(BackupAssetRecord record) async {
    final base = await getApplicationSupportDirectory();
    final directory = Directory('${base.path}/backup_assets');
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    final fileName = _safeFileName(record.fileName);
    final destination =
        File('${directory.path}/${record.assetId.hashCode}_$fileName');
    final bytes = base64Decode(record.bytesBase64);
    await destination.writeAsBytes(bytes, flush: true);
    return destination.path;
  }

  String _fileNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    if (index < 0 || index == normalized.length - 1) {
      return 'asset.bin';
    }
    return normalized.substring(index + 1);
  }

  String _safeFileName(String value) {
    final trimmed = value.trim();
    final sanitized = trimmed.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    if (sanitized.isEmpty) {
      return 'asset.bin';
    }
    return sanitized;
  }
}
