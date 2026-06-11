import Flutter
import UIKit
import AppTrackingTransparency

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else {
      return
    }

    let flutterViewController = FlutterViewController(
      project: nil,
      nibName: nil,
      bundle: nil
    )
    registerPrepLinePulseTrackingAuthorizationChannel(
      with: flutterViewController
    )
    GeneratedPluginRegistrant.register(with: flutterViewController)

    let window = UIWindow(windowScene: windowScene)
    window.rootViewController = flutterViewController
    self.window = window
    window.makeKeyAndVisible()
  }

  private func registerPrepLinePulseTrackingAuthorizationChannel(
    with controller: FlutterViewController
  ) {
    let channel = FlutterMethodChannel(
      name: "prep_line_pulse/tracking_authorization",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "trackingAuthorizationStatus":
        result(self.prepLinePulseTrackingAuthorizationStatus())
      case "requestTrackingAuthorization":
        self.prepLinePulseRequestTrackingAuthorization(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func prepLinePulseTrackingAuthorizationStatus() -> Int {
    if #available(iOS 14, *) {
      return Int(ATTrackingManager.trackingAuthorizationStatus.rawValue)
    }
    return 4
  }

  private func prepLinePulseRequestTrackingAuthorization(
    result: @escaping FlutterResult
  ) {
    if #available(iOS 14, *) {
      ATTrackingManager.requestTrackingAuthorization { status in
        DispatchQueue.main.async {
          result(Int(status.rawValue))
        }
      }
    } else {
      result(4)
    }
  }
}
