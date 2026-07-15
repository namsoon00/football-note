import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/firebase_startup.dart';

void main() {
  test('web without Firebase configuration exits before reading apps',
      () async {
    var readApps = false;
    var initialized = false;
    var reported = false;

    await initializeOptionalFirebase(
      isWeb: true,
      isConfigured: false,
      hasApps: () {
        readApps = true;
        throw StateError('Firebase.apps was read');
      },
      initializeApp: () async {
        initialized = true;
        throw StateError('Firebase.initializeApp was called');
      },
      reportError: (_, __) {
        reported = true;
      },
    );

    expect(readApps, isFalse);
    expect(initialized, isFalse);
    expect(reported, isFalse);
  });

  test('mobile initializes Firebase when no apps are registered', () async {
    var initialized = false;

    await initializeOptionalFirebase(
      isWeb: false,
      isConfigured: true,
      hasApps: () => false,
      initializeApp: () async {
        initialized = true;
      },
      reportError: (_, __) => fail('unexpected Firebase startup error'),
    );

    expect(initialized, isTrue);
  });

  test('mobile ignores duplicate Firebase app errors', () async {
    var reported = false;

    await initializeOptionalFirebase(
      isWeb: false,
      isConfigured: true,
      hasApps: () => false,
      initializeApp: () async {
        throw FirebaseException(
          plugin: 'firebase_core',
          code: 'duplicate-app',
        );
      },
      reportError: (_, __) {
        reported = true;
      },
    );

    expect(reported, isFalse);
  });

  test('mobile reports non-duplicate Firebase startup errors', () async {
    Object? reportedError;

    await initializeOptionalFirebase(
      isWeb: false,
      isConfigured: true,
      hasApps: () => false,
      initializeApp: () async {
        throw FirebaseException(
          plugin: 'firebase_core',
          code: 'unknown',
        );
      },
      reportError: (error, _) {
        reportedError = error;
      },
    );

    expect(reportedError, isA<FirebaseException>());
  });
}
