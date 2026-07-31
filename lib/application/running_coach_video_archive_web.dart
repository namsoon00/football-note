class ArchivedRunningCoachVideo {
  final String path;
  final String name;

  const ArchivedRunningCoachVideo({required this.path, required this.name});
}

/// Browser uploads cannot be archived durably by this app. Returning no
/// archive prevents a session-only `blob:` URL from being labelled as a saved
/// video after the user reloads the page.
Future<ArchivedRunningCoachVideo?> archiveRunningCoachVideo({
  required String? sourcePath,
  required String? sourceName,
  required DateTime timestamp,
}) async => null;

Future<void> deleteArchivedRunningCoachVideos(Iterable<String?> paths) async {}
