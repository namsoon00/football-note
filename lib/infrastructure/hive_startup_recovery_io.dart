import 'dart:io';

Future<bool> hasHiveBoxFileSystemConflict(String name, {String? path}) async {
  if (path == null || path.trim().isEmpty) {
    return false;
  }
  final directory = Directory(path);
  if (!await directory.exists()) {
    return false;
  }
  final normalizedName = name.toLowerCase();
  for (final extension in const <String>['.hive', '.hivec', '.lock']) {
    final entityPath =
        '${directory.path}${Platform.pathSeparator}$normalizedName$extension';
    final entityType = await FileSystemEntity.type(entityPath);
    if (entityType == FileSystemEntityType.directory) {
      return true;
    }
  }
  return false;
}

Future<void> moveHiveBoxFilesAside(String name, {String? path}) async {
  if (path == null || path.trim().isEmpty) {
    return;
  }
  final directory = Directory(path);
  if (!await directory.exists()) {
    return;
  }

  final normalizedName = name.toLowerCase();
  final timestamp = DateTime.now()
      .toUtc()
      .toIso8601String()
      .replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
  for (final extension in const <String>['.hive', '.hivec', '.lock']) {
    final entityPath =
        '${directory.path}${Platform.pathSeparator}$normalizedName$extension';
    final entityType = await FileSystemEntity.type(entityPath);
    if (entityType == FileSystemEntityType.notFound) {
      continue;
    }
    final replacementPath = '${directory.path}${Platform.pathSeparator}'
        '$normalizedName.startup_recovery_$timestamp$extension';
    if (entityType == FileSystemEntityType.directory) {
      await Directory(entityPath).rename(replacementPath);
    } else {
      await File(entityPath).rename(replacementPath);
    }
  }
}
