import AVKit
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
    // The audio output picker of the now-playing screen
    // (lib/platform/route_picker/route_picker.dart).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SoundspanRoutePicker") {
      registrar.register(
        RoutePickerViewFactory(),
        withId: "io.soundspan.app/route_picker"
      )
    }
  }
}

/// Creates the `AVRoutePickerView` platform views; the creation parameters
/// carry the icon tints as 32-bit ARGB integers under `tint` and
/// `activeTint`.
final class RoutePickerViewFactory: NSObject, FlutterPlatformViewFactory {
  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    let params = args as? [String: Any]
    return RoutePickerPlatformView(
      frame: frame,
      tint: color(params?["tint"]),
      activeTint: color(params?["activeTint"])
    )
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }

  private func color(_ value: Any?) -> UIColor? {
    guard let number = value as? NSNumber else { return nil }
    let argb = number.uint32Value
    return UIColor(
      red: CGFloat((argb >> 16) & 0xFF) / 255,
      green: CGFloat((argb >> 8) & 0xFF) / 255,
      blue: CGFloat(argb & 0xFF) / 255,
      alpha: CGFloat((argb >> 24) & 0xFF) / 255
    )
  }
}

/// One `AVRoutePickerView`, which presents the system output menu
/// (AirPlay, Bluetooth, the speaker) when tapped.
final class RoutePickerPlatformView: NSObject, FlutterPlatformView {
  private let picker: AVRoutePickerView

  init(frame: CGRect, tint: UIColor?, activeTint: UIColor?) {
    picker = AVRoutePickerView(frame: frame)
    picker.backgroundColor = .clear
    picker.prioritizesVideoDevices = false
    if let tint = tint { picker.tintColor = tint }
    if let activeTint = activeTint { picker.activeTintColor = activeTint }
    super.init()
  }

  func view() -> UIView {
    return picker
  }
}
