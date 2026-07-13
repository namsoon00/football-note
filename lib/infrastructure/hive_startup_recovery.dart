import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'hive_startup_recovery_stub.dart'
    if (dart.library.io) 'hive_startup_recovery_io.dart' as platform;

Future<Box<T>> openRecoverableHiveBox<T>(
  String name, {
  String? path,
}) async {
  if (Hive.isBoxOpen(name)) {
    return Hive.box<T>(name);
  }

  if (!kIsWeb &&
      await platform.hasHiveBoxFileSystemConflict(name, path: path)) {
    await platform.moveHiveBoxFilesAside(name, path: path);
    try {
      await Hive.deleteBoxFromDisk(name, path: path);
    } catch (_) {
      // The box files may already have been moved aside.
    }
  }

  try {
    return await Hive.openBox<T>(name, path: path);
  } catch (error, stackTrace) {
    if (kIsWeb) {
      rethrow;
    }
    try {
      await platform.moveHiveBoxFilesAside(name, path: path);
      try {
        await Hive.deleteBoxFromDisk(name, path: path);
      } catch (_) {
        // The box files may already have been moved aside.
      }
      return await Hive.openBox<T>(name, path: path);
    } catch (recoveryError, recoveryStackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: recoveryError,
          stack: recoveryStackTrace,
          library: 'football_note startup storage',
          context: ErrorDescription('while recovering Hive box "$name"'),
          informationCollector: () => <DiagnosticsNode>[
            ErrorDescription('Initial open error: $error'),
            ErrorDescription('Initial open stack: $stackTrace'),
          ],
        ),
      );
      rethrow;
    }
  }
}
