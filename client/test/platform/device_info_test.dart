// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@TestOn('linux')
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/platform/device_info/device_info.dart';

void main() {
  test('on Linux the device is a desktop named by its host', () {
    final info = currentDeviceInfo();

    expect(info.osLabel, 'Linux');
    expect(info.isMobile, isFalse);
    expect(info.hostName, isNotEmpty);
  });

  test('the provider yields the current device', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(deviceInfoProvider).osLabel, 'Linux');
  });
}
