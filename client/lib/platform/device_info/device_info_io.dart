// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:soundspan/platform/device_info/device_info.dart';

/// The [DeviceInfo] of the operating system the app runs on; the host name
/// is read on desktop only.
DeviceInfo currentDeviceInfo() {
  final isMobile = Platform.isAndroid || Platform.isIOS;
  return DeviceInfo(
    hostName: isMobile ? null : _hostName(),
    osLabel: switch (Platform.operatingSystem) {
      'android' => 'Android',
      'ios' => 'iOS',
      'windows' => 'Windows',
      'macos' => 'macOS',
      _ => 'Linux',
    },
    isMobile: isMobile,
  );
}

String? _hostName() {
  try {
    final name = Platform.localHostname.trim();
    return name.isEmpty ? null : name;
  } on Object {
    return null;
  }
}
