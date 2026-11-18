// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/platform/device_info/device_info.dart';

final AppLogger _log = AppLogger.scope('DeviceInfo');

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

/// The Android API level, asked of `MainActivity` over
/// [deviceInfoChannel]; null off Android and when no activity answers
/// (the engine was started by the playback service).
Future<int?> androidSdkVersion() async {
  if (!Platform.isAndroid) return null;
  try {
    return await const MethodChannel(deviceInfoChannel)
        .invokeMethod<int>('sdkInt');
  } on Object catch (error, stackTrace) {
    _log.warning('The API level was not read', const {}, error, stackTrace);
    return null;
  }
}
