import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not configured for Firebase.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError('macOS is not configured for Firebase.');
      case TargetPlatform.fuchsia:
        throw UnsupportedError('Fuchsia is not configured for Firebase.');
      case TargetPlatform.windows:
        throw UnsupportedError('Windows is not configured for Firebase.');
      case TargetPlatform.linux:
        throw UnsupportedError('Linux is not configured for Firebase.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAOCkZfaqvG5ZCk-q5ymtUx4jB_8e0pryc',
    appId: '1:771305087734:android:8c00b077f87123f93a02d7',
    messagingSenderId: '771305087734',
    projectId: 'football-note-efef0',
    storageBucket: 'football-note-efef0.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBvRwlgLjLwtvMrxySQacPP5TQjw8P1T3Y',
    appId: '1:771305087734:ios:996636a06e365a873a02d7',
    messagingSenderId: '771305087734',
    projectId: 'football-note-efef0',
    storageBucket: 'football-note-efef0.firebasestorage.app',
    iosBundleId: 'com.namsoon.footballnote',
    iosClientId:
        '771305087734-9t068sugq2613or2h7h53vnr1vgld604.apps.googleusercontent.com',
  );
}
