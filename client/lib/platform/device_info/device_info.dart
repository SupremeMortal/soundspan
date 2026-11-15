// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The device-info seam: the host name and operating system a device-link
/// key is named after (doc 04, Device Link).
///
/// `currentDeviceInfo()` reads them on native targets; on web there is no
/// host name. No hardware identifiers are read.
library;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/platform/device_info/device_info_web.dart'
    if (dart.library.io) 'package:soundspan/platform/device_info/device_info_io.dart';

export 'device_info_web.dart'
    if (dart.library.io) 'device_info_io.dart'
    show currentDeviceInfo;

/// What the app knows about the device it runs on, for naming it.
@immutable
final class DeviceInfo {
  /// Creates the description.
  const new({required this.osLabel, required this.isMobile, this.hostName});

  /// The host name on desktop; null on mobile, on web and when the OS does
  /// not say.
  final String? hostName;

  /// `Android`, `iOS`, `Windows`, `macOS` or `Linux` (`Web` in a browser).
  final String osLabel;

  /// Whether the device is a phone or tablet.
  final bool isMobile;
}

/// The [DeviceInfo] of the running app; tests override it.
final Provider<DeviceInfo> deviceInfoProvider = Provider<DeviceInfo>(
  (ref) => currentDeviceInfo(),
);
