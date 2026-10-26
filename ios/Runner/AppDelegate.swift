import Flutter
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
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "WirdAppIcon") {
      AppIconChannel.shared.attach(to: registrar.messenger())
    }
  }
}

/// Switches between the per-prayer home screen icons (see AppIconService in
/// Dart). Maghrib is the primary icon; the other four are the alternate
/// AppIcon-<prayer> sets in Assets.xcassets.
///
/// iOS only changes an icon while the app is active and always confirms it
/// with a system alert, so a change asked for in the background waits until
/// the app is next active, and asking for the icon that's already showing
/// does nothing.
final class AppIconChannel {
  static let shared = AppIconChannel()

  private static let primary = "maghrib"
  private var pending: String?
  private var observer: NSObjectProtocol?

  func attach(to messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "com.SayanKabir.wird2/app_icon", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setIcon",
            let args = call.arguments as? [String: Any],
            let name = args["name"] as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.request(name)
      result(nil)
    }
    observer = NotificationCenter.default.addObserver(
      forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
    ) { [weak self] _ in
      guard let self, let name = self.pending else { return }
      self.pending = nil
      self.apply(name)
    }
  }

  private func request(_ name: String) {
    if UIApplication.shared.applicationState == .active {
      apply(name)
    } else {
      pending = name
    }
  }

  private func apply(_ name: String) {
    let app = UIApplication.shared
    guard app.supportsAlternateIcons else { return }
    let target: String? = name == AppIconChannel.primary ? nil : "AppIcon-\(name)"
    guard app.alternateIconName != target else { return }
    app.setAlternateIconName(target) { error in
      if let error { NSLog("Wird: couldn't change the app icon: \(error.localizedDescription)") }
    }
  }
}
