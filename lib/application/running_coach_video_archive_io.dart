import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ArchivedRunningCoachVideo {
  final String path;
  final String name;

  const ArchivedRunningCoachVideo({required this.path, required this.name});
}

Future<ArchivedRunningCoachVideo?> archiveRunningCoachVideo({
  required String? sourcePath,
  required String? sourceName,
  required DateTime timestamp,
}) async {
  if (sourcePath == null || sourcePath.trim().isEmpty) return null;
  try {
    final source = File(sourcePath);
    if (!await source.exists()) return null;
    final archiveDirectory = await _archiveDirectory(create: true);
    if (archiveDirectory == null) return null;
    final extension = _safeVideoExtension(sourceName ?? source.path);
    final archivedName =
        'running-coach-${timestamp.microsecondsSinceEpoch}$extension';
    final destination = File(
      '${archiveDirectory.path}${Platform.pathSeparator}$archivedName',
    );
    await source.copy(destination.path);
    return ArchivedRunningCoachVideo(
      path: destination.path,
      name: sourceName?.trim().isNotEmpty == true ? sourceName! : archivedName,
    );
  } catch (_) {
    return null;
  }
}

Future<void> deleteArchivedRunningCoachVideos(Iterable<String?> paths) async {
  final archiveDirectory = await _archiveDirectory();
  if (archiveDirectory == null || !await archiveDirectory.exists()) return;
  String archiveRoot;
  try {
    archiveRoot = await archiveDirectory.resolveSymbolicLinks();
  } catch (_) {
    return;
  }
  for (final path in paths) {
    if (path == null || path.isEmpty) continue;
    try {
      final file = File(path);
      if (!await file.exists()) continue;
      final resolvedFilePath = await file.resolveSymbolicLinks();
      if (!_isManagedArchivePath(resolvedFilePath, archiveRoot)) continue;
      await file.delete();
    } catch (_) {
      // History cleanup is best effort.
    }
  }
}

Future<Directory?> _archiveDirectory({bool create = false}) async {
  try {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}running_coach_videos',
    );
    if (create && !await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  } catch (_) {
    return null;
  }
}

bool _isManagedArchivePath(String resolvedFilePath, String archiveRoot) {
  final prefix = archiveRoot.endsWith(Platform.pathSeparator)
      ? archiveRoot
      : '$archiveRoot${Platform.pathSeparator}';
  return resolvedFilePath.startsWith(prefix);
}

String _safeVideoExtension(String name) {
  final dotIndex = name.lastIndexOf('.');
  if (dotIndex < 0 || dotIndex == name.length - 1) return '.mp4';
  final extension = name.substring(dotIndex).toLowerCase();
  return RegExp(r'^\.[a-z0-9]{2,8}$').hasMatch(extension) ? extension : '.mp4';
}
