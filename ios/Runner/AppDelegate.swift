import Flutter
import UIKit
import FirebaseCore
import GoogleSignIn

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if FirebaseApp.app() == nil {
      if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
         let options = FirebaseOptions(contentsOfFile: path) {
        FirebaseApp.configure(options: options)
      } else {
        let options = FirebaseOptions(
          googleAppID: "1:771305087734:ios:996636a06e365a873a02d7",
          gcmSenderID: "771305087734"
        )
        options.apiKey = "AIzaSyBvRwlgLjLwtvMrxySQacPP5TQjw8P1T3Y"
        options.projectID = "football-note-efef0"
        options.storageBucket = "football-note-efef0.firebasestorage.app"
        options.bundleID = "com.namsoon.footballnote"
        FirebaseApp.configure(options: options)
      }
    }

    if GIDSignIn.sharedInstance.configuration == nil {
      GIDSignIn.sharedInstance.configuration = GIDConfiguration(
        clientID: "771305087734-9t068sugq2613or2h7h53vnr1vgld604.apps.googleusercontent.com"
      )
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
