class ArchivedRunningCoachVideo {
  final String path;
  final String name;

  const ArchivedRunningCoachVideo({required this.path, required this.name});
}

/// Keeps a browser-backed source available for the active page session.
///
/// `image_picker` exposes an uploaded browser file as a `blob:` URL. That URL
/// remains playable while the page is open, but browsers intentionally revoke
/// it after a reload, so it must never be presented as durable storage.
Future<ArchivedRunningCoachVideo?> archiveRunningCoachVideo({
  required String? sourcePath,
  required String? sourceName,
  required DateTime timestamp,
}) async {
  final path = sourcePath?.trim();
  if (path == null || path.isEmpty) return null;
  final source = Uri.tryParse(path);
  if (source == null ||
      !const <String>{'blob', 'http', 'https'}.contains(source.scheme)) {
    return null;
  }
  final fallbackName = 'running-coach-${timestamp.microsecondsSinceEpoch}.mp4';
  return ArchivedRunningCoachVideo(
    path: path,
    name: sourceName?.trim().isNotEmpty == true
        ? sourceName!.trim()
        : fallbackName,
  );
}

Future<void> deleteArchivedRunningCoachVideos(Iterable<String?> paths) async {}
