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
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final archiveDirectory = Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}running_coach_videos',
    );
    if (!await archiveDirectory.exists()) {
      await archiveDirectory.create(recursive: true);
    }
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
  for (final path in paths) {
    if (path == null || path.isEmpty) continue;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // History cleanup is best effort.
    }
  }
}

String _safeVideoExtension(String name) {
  final dotIndex = name.lastIndexOf('.');
  if (dotIndex < 0 || dotIndex == name.length - 1) return '.mp4';
  final extension = name.substring(dotIndex).toLowerCase();
  return RegExp(r'^\.[a-z0-9]{2,8}$').hasMatch(extension) ? extension : '.mp4';
}
