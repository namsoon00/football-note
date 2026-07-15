import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'hive_startup_recovery_stub.dart'
    if (dart.library.io) 'hive_startup_recovery_io.dart' as platform;

Future<Box<T>> openRecoverableHiveBox<T>(
  String name, {
  String? path,
  CompactionStrategy? compactionStrategy,
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
    return await _openHiveBox<T>(
      name,
      path: path,
      compactionStrategy: compactionStrategy,
    );
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
      return await _openHiveBox<T>(
        name,
        path: path,
        compactionStrategy: compactionStrategy,
      );
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

Future<Box<T>> _openHiveBox<T>(
  String name, {
  required String? path,
  required CompactionStrategy? compactionStrategy,
}) {
  final strategy = compactionStrategy;
  if (strategy == null) {
    return Hive.openBox<T>(name, path: path);
  }
  return Hive.openBox<T>(
    name,
    path: path,
    compactionStrategy: strategy,
  );
}
