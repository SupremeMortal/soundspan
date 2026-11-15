// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/platform/connectivity/connectivity.dart';

void main() {
  test('no result or only none is no interface', () {
    expect(connectivityInfoFrom(const []), ConnectivityInfo.none);
    expect(
      connectivityInfoFrom(const [ConnectivityResult.none]),
      ConnectivityInfo.none,
    );
  });

  test('Wi-Fi wins over mobile, mobile over anything else', () {
    expect(
      connectivityInfoFrom(const [
        ConnectivityResult.mobile,
        ConnectivityResult.wifi,
      ]),
      const ConnectivityInfo(hasInterface: true, type: ConnectivityType.wifi),
    );
    expect(
      connectivityInfoFrom(const [
        ConnectivityResult.vpn,
        ConnectivityResult.mobile,
      ]),
      const ConnectivityInfo(
        hasInterface: true,
        type: ConnectivityType.cellular,
      ),
    );
    expect(
      connectivityInfoFrom(const [ConnectivityResult.ethernet]),
      const ConnectivityInfo(hasInterface: true, type: ConnectivityType.other),
    );
  });
}
