import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    // Each profile's media directory is kept out of Time Machine backups
    // (lib/platform/downloader/downloader_io.dart).
    registerBackupExclusion(messenger: flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()
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
