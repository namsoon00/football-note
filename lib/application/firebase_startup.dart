import 'package:firebase_core/firebase_core.dart';

typedef HasFirebaseApps = bool Function();
typedef InitializeFirebaseApp = Future<void> Function();
typedef ReportFirebaseStartupError = void Function(
  Object error,
  StackTrace stackTrace,
);

Future<void> initializeOptionalFirebase({
  required bool isWeb,
  required bool isConfigured,
  required HasFirebaseApps hasApps,
  required InitializeFirebaseApp initializeApp,
  required ReportFirebaseStartupError reportError,
}) async {
  if (isWeb && !isConfigured) {
    return;
  }

  try {
    if (hasApps()) {
      return;
    }
    await initializeApp();
  } on FirebaseException catch (error, stackTrace) {
    if (error.code == 'duplicate-app' || hasApps()) {
      return;
    }
    if (isWeb) {
      return;
    }
    reportError(error, stackTrace);
  } catch (_) {
    if (isWeb) {
      return;
    }
  }
}
