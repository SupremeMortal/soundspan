// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/platform/device_info/device_info.dart';

/// The [DeviceInfo] of a browser: no host name.
DeviceInfo currentDeviceInfo() =>
    const DeviceInfo(osLabel: 'Web', isMobile: false);

/// The Android API level: none in a browser.
Future<int?> androidSdkVersion() async => null;
