import Flutter
import UIKit
import WebKit

final class RunningThreeDRunnerViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    RunningThreeDRunnerPlatformView(
      frame: frame,
      viewId: viewId,
      arguments: args,
      messenger: messenger
    )
  }
}

final class RunningThreeDRunnerPlatformView: NSObject, FlutterPlatformView, WKNavigationDelegate {
  private let webView: WKWebView
  private let channel: FlutterMethodChannel
  private var pendingPayload: String?
  private var isLoaded = false
  private let loadingLabel: String

  init(
    frame: CGRect,
    viewId: Int64,
    arguments args: Any?,
    messenger: FlutterBinaryMessenger
  ) {
    let configuration = WKWebViewConfiguration()
    configuration.allowsInlineMediaPlayback = true
    webView = WKWebView(frame: frame, configuration: configuration)
    channel = FlutterMethodChannel(
      name: "football_note/running_3d_runner/\(viewId)",
      binaryMessenger: messenger
    )
    let arguments = args as? [String: Any]
    pendingPayload = arguments?["payload"] as? String
    loadingLabel = arguments?["loadingLabel"] as? String ?? ""
    super.init()
    webView.isOpaque = false
    webView.backgroundColor = .clear
    webView.scrollView.isScrollEnabled = false
    webView.navigationDelegate = self
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setPayload" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let payload = call.arguments as? String else {
        result(
          FlutterError(
            code: "invalid_payload",
            message: "setPayload requires a JSON string.",
            details: nil
          )
        )
        return
      }
      self?.setPayload(payload)
      result(nil)
    }
    loadRenderer()
  }

  func view() -> UIView {
    webView
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    isLoaded = true
    if let payload = pendingPayload {
      setPayload(payload)
    }
  }

  private func loadRenderer() {
    guard let htmlURL = rendererHTMLURL() else {
      webView.loadHTMLString(
        "<html><body style=\"margin:0;background:#0b1220;color:#eaf0ff;display:grid;place-items:center;height:100vh;font:700 13px system-ui\">\(escapeHTML(loadingLabel))</body></html>",
        baseURL: nil
      )
      return
    }
    webView.loadFileURL(
      htmlURL,
      allowingReadAccessTo: htmlURL.deletingLastPathComponent()
    )
  }

  private func setPayload(_ payload: String) {
    pendingPayload = payload
    guard isLoaded else {
      return
    }
    let literal = javaScriptStringLiteral(payload)
    webView.evaluateJavaScript(
      "window.runningThreeDRunnerSetPayload && window.runningThreeDRunnerSetPayload(\(literal));",
      completionHandler: nil
    )
  }

  private func rendererHTMLURL() -> URL? {
    guard let resourceURL = Bundle.main.resourceURL else {
      return nil
    }
    let candidates = [
      resourceURL.appendingPathComponent(
        "Frameworks/App.framework/flutter_assets/assets/running_coach_3d_runner/runner.html"
      ),
      resourceURL.appendingPathComponent(
        "flutter_assets/assets/running_coach_3d_runner/runner.html"
      ),
    ]
    return candidates.first { FileManager.default.fileExists(atPath: $0.path) }
  }

  private func javaScriptStringLiteral(_ value: String) -> String {
    guard
      let data = try? JSONSerialization.data(withJSONObject: [value]),
      let arrayLiteral = String(data: data, encoding: .utf8),
      arrayLiteral.count >= 2
    else {
      return "\"\""
    }
    return String(arrayLiteral.dropFirst().dropLast())
  }

  private func escapeHTML(_ value: String) -> String {
    value
      .replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
      .replacingOccurrences(of: "\"", with: "&quot;")
  }
}
