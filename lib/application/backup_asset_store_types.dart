class BackupAssetRecord {
  final String assetId;
  final String fileName;
  final String bytesBase64;

  const BackupAssetRecord({
    required this.assetId,
    required this.fileName,
    required this.bytesBase64,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'fileName': fileName,
      'bytesBase64': bytesBase64,
    };
  }

  static BackupAssetRecord? tryParse(String assetId, dynamic raw) {
    if (raw is! Map) return null;
    final map = raw.cast<String, dynamic>();
    final fileName = map['fileName']?.toString().trim() ?? '';
    final bytesBase64 = map['bytesBase64']?.toString().trim() ?? '';
    if (fileName.isEmpty || bytesBase64.isEmpty) {
      return null;
    }
    return BackupAssetRecord(
      assetId: assetId,
      fileName: fileName,
      bytesBase64: bytesBase64,
    );
  }
}

abstract class BackupAssetFileStore {
  BackupAssetRecord? readFileSync({
    required String assetId,
    required String sourcePath,
    String? preferredFileName,
  });

  Future<String?> restoreFile(BackupAssetRecord record);
}
