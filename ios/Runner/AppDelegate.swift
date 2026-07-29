import Flutter
import UIKit
import FirebaseCore
import GoogleSignIn
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var runningPoseAnalysisChannels: [RunningPoseAnalysisChannel] = []
  private var runningPoseAnalysisChannelMessengers = Set<ObjectIdentifier>()
  private var appBadgeChannels: [FlutterMethodChannel] = []
  private var appBadgeChannelMessengers = Set<ObjectIdentifier>()

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
    let didFinish = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    if let controller = window?.rootViewController as? FlutterViewController {
      registerRunningPoseAnalysisChannel(binaryMessenger: controller.binaryMessenger)
      registerAppBadgeChannel(binaryMessenger: controller.binaryMessenger)
    }
    registerRunningThreeDRunnerView(pluginRegistry: self)
    return didFinish
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerRunningPoseAnalysisChannel(
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    registerAppBadgeChannel(
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    registerRunningThreeDRunnerView(pluginRegistry: engineBridge.pluginRegistry)
  }

  private func registerRunningThreeDRunnerView(pluginRegistry: FlutterPluginRegistry) {
    let registrar = pluginRegistry.registrar(forPlugin: "RunningThreeDRunnerView")
    registrar.register(
      RunningThreeDRunnerViewFactory(messenger: registrar.messenger()),
      withId: "football_note/running_3d_runner"
    )
  }

  private func registerRunningPoseAnalysisChannel(binaryMessenger: FlutterBinaryMessenger) {
    let messengerKey = ObjectIdentifier(binaryMessenger as AnyObject)
    guard !runningPoseAnalysisChannelMessengers.contains(messengerKey) else {
      return
    }

    runningPoseAnalysisChannels.append(
      RunningPoseAnalysisChannel(binaryMessenger: binaryMessenger)
    )
    runningPoseAnalysisChannelMessengers.insert(messengerKey)
  }

  private func registerAppBadgeChannel(binaryMessenger: FlutterBinaryMessenger) {
    let messengerKey = ObjectIdentifier(binaryMessenger as AnyObject)
    guard !appBadgeChannelMessengers.contains(messengerKey) else {
      return
    }

    let channel = FlutterMethodChannel(
      name: "football_note/app_badge",
      binaryMessenger: binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "setBadgeCount":
        guard let arguments = call.arguments as? [String: Any],
              let count = arguments["count"] as? Int else {
          result(
            FlutterError(
              code: "invalid_arguments",
              message: "setBadgeCount requires an integer count.",
              details: nil
            )
          )
          return
        }

        let badgeCount = max(0, count)
        UNUserNotificationCenter.current().getNotificationSettings { settings in
          let authorized: Bool
          switch settings.authorizationStatus {
          case .authorized, .provisional, .ephemeral:
            authorized = settings.badgeSetting == .enabled
          default:
            authorized = false
          }

          DispatchQueue.main.async {
            if authorized {
              UIApplication.shared.applicationIconBadgeNumber = badgeCount
            }
            result(nil)
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    appBadgeChannels.append(channel)
    appBadgeChannelMessengers.insert(messengerKey)
  }
}
