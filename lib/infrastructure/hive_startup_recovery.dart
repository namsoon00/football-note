import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'hive_startup_recovery_stub.dart'
    if (dart.library.io) 'hive_startup_recovery_io.dart' as platform;

const _recoveryOpenAttempts = 3;
const _recoveryOpenRetryDelay = Duration(milliseconds: 80);

Future<Box<T>> openRecoverableHiveBox<T>(
  String name, {
  String? path,
  CompactionStrategy? compactionStrategy,
}) async {
  if (Hive.isBoxOpen(name)) {
    return Hive.box<T>(name);
  }

  if (kIsWeb) {
    return _openHiveBox<T>(
      name,
      path: path,
      compactionStrategy: compactionStrategy,
    );
  }

  var sourceFilesWereQuarantined = false;
  try {
    if (await platform.hasHiveBoxFileSystemConflict(name, path: path)) {
      await platform.moveHiveBoxFilesAside(name, path: path);
      sourceFilesWereQuarantined = true;
    }
    return await _openHiveBox<T>(
      name,
      path: path,
      compactionStrategy: compactionStrategy,
    );
  } catch (error, stackTrace) {
    return _recoverHiveBoxAfterOpenFailure<T>(
      name,
      path: path,
      compactionStrategy: compactionStrategy,
      sourceFilesWereQuarantined: sourceFilesWereQuarantined,
      initialError: error,
      initialStackTrace: stackTrace,
    );
  }
}

Future<Box<T>> _recoverHiveBoxAfterOpenFailure<T>(
  String name, {
  required String? path,
  required CompactionStrategy? compactionStrategy,
  required bool sourceFilesWereQuarantined,
  required Object initialError,
  required StackTrace initialStackTrace,
}) async {
  try {
    if (!sourceFilesWereQuarantined) {
      await platform.moveHiveBoxFilesAside(name, path: path);
    }

    // Hive releases a failed box asynchronously. Retrying immediately can
    // collide with its transient lock file, especially after a crash recovery.
    await Future<void>.delayed(_recoveryOpenRetryDelay);
    late Object lastRecoveryError;
    late StackTrace lastRecoveryStackTrace;
    for (var attempt = 0; attempt < _recoveryOpenAttempts; attempt += 1) {
      try {
        return await _openHiveBox<T>(
          name,
          path: path,
          compactionStrategy: compactionStrategy,
        );
      } catch (error, stackTrace) {
        lastRecoveryError = error;
        lastRecoveryStackTrace = stackTrace;
        if (attempt + 1 < _recoveryOpenAttempts) {
          await Future<void>.delayed(_recoveryOpenRetryDelay);
        }
      }
    }
    Error.throwWithStackTrace(lastRecoveryError, lastRecoveryStackTrace);
  } catch (recoveryError, recoveryStackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: recoveryError,
        stack: recoveryStackTrace,
        library: 'football_note startup storage',
        context: ErrorDescription('while recovering Hive box "$name"'),
        informationCollector: () => <DiagnosticsNode>[
          ErrorDescription('Initial open error: $initialError'),
          ErrorDescription('Initial open stack: $initialStackTrace'),
        ],
      ),
    );
    Error.throwWithStackTrace(recoveryError, recoveryStackTrace);
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
