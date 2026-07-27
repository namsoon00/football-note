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

Future<void> moveHiveBoxFilesAside(
  String name, {
  String? path,
  String? recoveryId,
}) async {
  if (path == null || path.trim().isEmpty) {
    return;
  }
  final directory = Directory(path);
  if (!await directory.exists()) {
    return;
  }

  final normalizedName = name.toLowerCase();
  final requestedRecoveryId = recoveryId?.trim();
  final timestamp =
      requestedRecoveryId != null && requestedRecoveryId.isNotEmpty
          ? requestedRecoveryId
          : DateTime.now()
              .toUtc()
              .toIso8601String()
              .replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
  final uniqueRecoveryId = await _uniqueRecoveryId(
    directory: directory,
    name: normalizedName,
    requestedId: timestamp,
  );
  for (final extension in const <String>['.hive', '.hivec', '.lock']) {
    final entityPath =
        '${directory.path}${Platform.pathSeparator}$normalizedName$extension';
    final entityType = await FileSystemEntity.type(entityPath);
    if (entityType == FileSystemEntityType.notFound) {
      continue;
    }
    final replacementPath = '${directory.path}${Platform.pathSeparator}'
        '$normalizedName.startup_recovery_$uniqueRecoveryId$extension';
    if (entityType == FileSystemEntityType.directory) {
      await Directory(entityPath).rename(replacementPath);
    } else if (entityType == FileSystemEntityType.link) {
      await Link(entityPath).rename(replacementPath);
    } else {
      await File(entityPath).rename(replacementPath);
    }
  }
}

Future<String> _uniqueRecoveryId({
  required Directory directory,
  required String name,
  required String requestedId,
}) async {
  var candidate = requestedId;
  var suffix = 1;
  while (await _recoveryIdExists(
    directory: directory,
    name: name,
    recoveryId: candidate,
  )) {
    candidate = '${requestedId}_$suffix';
    suffix += 1;
  }
  return candidate;
}

Future<bool> _recoveryIdExists({
  required Directory directory,
  required String name,
  required String recoveryId,
}) async {
  for (final extension in const <String>['.hive', '.hivec', '.lock']) {
    final candidatePath = '${directory.path}${Platform.pathSeparator}'
        '$name.startup_recovery_$recoveryId$extension';
    if (await FileSystemEntity.type(candidatePath) !=
        FileSystemEntityType.notFound) {
      return true;
    }
  }
  return false;
}
