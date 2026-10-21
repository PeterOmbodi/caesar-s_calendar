import CoreHaptics
import Flutter
import GameController
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "KeyboardPresence") {
      FlutterEventChannel(name: "caesar_puzzle/keyboard", binaryMessenger: registrar.messenger())
        .setStreamHandler(KeyboardPresenceStreamHandler())
      FlutterMethodChannel(name: "caesar_puzzle/device", binaryMessenger: registrar.messenger())
        .setMethodCallHandler { call, result in
          switch call.method {
          case "supportsHaptics":
            result(CHHapticEngine.capabilitiesForHardware().supportsHaptics)
          default:
            result(FlutterMethodNotImplemented)
          }
        }
    }
  }
}

/// Reports whether a hardware keyboard is attached, so the side rail shows shortcut hints only then.
final class KeyboardPresenceStreamHandler: NSObject, FlutterStreamHandler {
  private var observers: [NSObjectProtocol] = []

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    guard #available(iOS 14.0, *) else {
      events(false)
      return nil
    }
    let report = { events(GCKeyboard.coalesced != nil) }
    let center = NotificationCenter.default
    observers = [
      center.addObserver(forName: .GCKeyboardDidConnect, object: nil, queue: .main) { _ in report() },
      center.addObserver(forName: .GCKeyboardDidDisconnect, object: nil, queue: .main) { _ in report() },
    ]
    report()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    observers.forEach { NotificationCenter.default.removeObserver($0) }
    observers = []
    return nil
  }
}
