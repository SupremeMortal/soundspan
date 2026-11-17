import AVKit
import Flutter
import UIKit
#if canImport(background_downloader)
  import background_downloader
#endif

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Downloads run in the background URLSession named in Info.plist
    // (doc 10, iOS Downloads), set before the plugin creates the session.
    #if canImport(background_downloader)
      if let identifier = Bundle.main.object(
        forInfoDictionaryKey: "SoundspanDownloadSessionIdentifier") as? String
      {
        UrlSessionDelegate.sessionIdentifier = identifier
      }
    #endif
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // When iOS relaunches the app for events of the background download
  // session, FlutterAppDelegate hands them to background_downloader, which
  // reconnects to the session and calls the completion handler.
  override func application(
    _ application: UIApplication,
    handleEventsForBackgroundURLSession identifier: String,
    completionHandler: @escaping () -> Void
  ) {
    super.application(
      application,
      handleEventsForBackgroundURLSession: identifier,
      completionHandler: completionHandler
    )
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
    // Each profile's media directory is kept out of backups
    // (lib/platform/downloader/downloader_io.dart).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SoundspanBackup") {
      registerBackupExclusion(messenger: registrar.messenger())
    }
  }
}

/// Handles `excludeFromBackup(path)` on `io.soundspan.app/backup`: creates
/// the directory at `path` if needed and sets `isExcludedFromBackup` on it
/// (doc 05, Files on Disk).
func registerBackupExclusion(messenger: FlutterBinaryMessenger) {
  let channel = FlutterMethodChannel(
    name: "io.soundspan.app/backup", binaryMessenger: messenger)
  channel.setMethodCallHandler { call, result in
    guard call.method == "excludeFromBackup", let path = call.arguments as? String else {
      result(FlutterMethodNotImplemented)
      return
    }
    var url = URL(fileURLWithPath: path, isDirectory: true)
    do {
      try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      try url.setResourceValues(values)
      result(nil)
    } catch {
      result(FlutterError(code: "backup", message: error.localizedDescription, details: nil))
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
