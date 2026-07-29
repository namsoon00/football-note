class ArchivedRunningCoachVideo {
  final String path;
  final String name;

  const ArchivedRunningCoachVideo({required this.path, required this.name});
}

/// Browser file handles are intentionally not persisted. The detailed report
/// remains in history, while the user must select the source video again to
/// replay it after a page reload.
Future<ArchivedRunningCoachVideo?> archiveRunningCoachVideo({
  required String? sourcePath,
  required String? sourceName,
  required DateTime timestamp,
}) async =>
    null;

Future<void> deleteArchivedRunningCoachVideos(Iterable<String?> paths) async {}
