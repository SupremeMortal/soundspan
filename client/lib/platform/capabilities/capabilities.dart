// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The capabilities seam: what this platform can do (doc 02, Platform
/// Seams).
///
/// `currentPlatformCapabilities()` returns the constants of the operating
/// system the app runs on, or on web [PlatformCapabilities.web]. UI asks
/// [platformCapabilitiesProvider], never `Platform.isX`.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/platform/capabilities/capabilities_web.dart'
    if (dart.library.io) 'package:soundspan/platform/capabilities/capabilities_io.dart';

export 'capabilities_web.dart'
    if (dart.library.io) 'capabilities_io.dart'
    show currentPlatformCapabilities;

/// What the platform the app runs on can do. Screens hide features by these
/// flags.
@immutable
final class PlatformCapabilities {
  /// Creates a set of capabilities; every flag is required.
  const new({
    required this.canDownload,
    required this.canScanQr,
    required this.hasTray,
    required this.hasBackgroundPlayback,
    required this.supportsApiKeyStreaming,
    required this.isDesktop,
    required this.allowsPublicCleartextHttp,
  });

  /// The capabilities of the native app on [platform] (doc 10).
  factory forTarget(TargetPlatform platform) => switch (platform) {
    TargetPlatform.android || TargetPlatform.fuchsia => android,
    TargetPlatform.iOS => iOS,
    TargetPlatform.macOS => macOS,
    TargetPlatform.windows || TargetPlatform.linux => windowsAndLinux,
  };

  /// Android.
  static const android = PlatformCapabilities(
    canDownload: true,
    canScanQr: true,
    hasTray: false,
    hasBackgroundPlayback: true,
    supportsApiKeyStreaming: true,
    isDesktop: false,
    allowsPublicCleartextHttp: true,
  );

  /// iOS; App Transport Security blocks public `http://` servers.
  static const iOS = PlatformCapabilities(
    canDownload: true,
    canScanQr: true,
    hasTray: false,
    hasBackgroundPlayback: true,
    supportsApiKeyStreaming: true,
    isDesktop: false,
    allowsPublicCleartextHttp: false,
  );

  /// macOS; closing the window keeps the app in the Dock, so there is no
  /// tray. App Transport Security blocks public `http://` servers.
  static const macOS = PlatformCapabilities(
    canDownload: true,
    canScanQr: true,
    hasTray: false,
    hasBackgroundPlayback: true,
    supportsApiKeyStreaming: true,
    isDesktop: true,
    allowsPublicCleartextHttp: false,
  );

  /// Windows and Linux; no camera QR scanner.
  static const windowsAndLinux = PlatformCapabilities(
    canDownload: true,
    canScanQr: false,
    hasTray: true,
    hasBackgroundPlayback: true,
    supportsApiKeyStreaming: true,
    isDesktop: true,
    allowsPublicCleartextHttp: true,
  );

  /// The web app: no downloads, and streams carry a JWT in `?token=`, which
  /// an API key cannot be.
  static const web = PlatformCapabilities(
    canDownload: false,
    canScanQr: true,
    hasTray: false,
    hasBackgroundPlayback: false,
    supportsApiKeyStreaming: false,
    isDesktop: false,
    allowsPublicCleartextHttp: true,
  );

  /// Tracks and episodes can be downloaded for offline use.
  final bool canDownload;

  /// A camera QR scanner is available for the device-link code.
  final bool canScanQr;

  /// The app can show a system tray icon.
  final bool hasTray;

  /// Playback continues with no window or with the app in the background.
  final bool hasBackgroundPlayback;

  /// Streams can be authorized with an API key.
  final bool supportsApiKeyStreaming;

  /// The app runs as a desktop application.
  final bool isDesktop;

  /// The platform lets the app reach a public server over plain `http://`.
  final bool allowsPublicCleartextHttp;

  @override
  bool operator ==(Object other) =>
      other is PlatformCapabilities &&
      other.canDownload == canDownload &&
      other.canScanQr == canScanQr &&
      other.hasTray == hasTray &&
      other.hasBackgroundPlayback == hasBackgroundPlayback &&
      other.supportsApiKeyStreaming == supportsApiKeyStreaming &&
      other.isDesktop == isDesktop &&
      other.allowsPublicCleartextHttp == allowsPublicCleartextHttp;

  @override
  int get hashCode => Object.hash(
    canDownload,
    canScanQr,
    hasTray,
    hasBackgroundPlayback,
    supportsApiKeyStreaming,
    isDesktop,
    allowsPublicCleartextHttp,
  );

  @override
  String toString() =>
      'PlatformCapabilities(canDownload: $canDownload, '
      'canScanQr: $canScanQr, hasTray: $hasTray, '
      'hasBackgroundPlayback: $hasBackgroundPlayback, '
      'supportsApiKeyStreaming: $supportsApiKeyStreaming, '
      'isDesktop: $isDesktop, '
      'allowsPublicCleartextHttp: $allowsPublicCleartextHttp)';
}

/// The capabilities of the platform the app runs on.
final Provider<PlatformCapabilities> platformCapabilitiesProvider =
    Provider<PlatformCapabilities>((ref) => currentPlatformCapabilities());
