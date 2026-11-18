// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';

import '../../../../integration_test/support/device_gap_tolerance.dart';

void main() {
  group('deviceGapTolerance', () {
    test('is 20 ms on a device without a defined tolerance', () {
      expect(
        deviceGapTolerance(isMacOS: false, definedMs: 0),
        const Duration(milliseconds: 20),
      );
    });

    test('is 100 ms on macOS', () {
      expect(
        deviceGapTolerance(isMacOS: true, definedMs: 0),
        const Duration(milliseconds: 100),
      );
    });

    test('takes the tolerance a CI job defines, such as the iOS simulator', () {
      expect(
        deviceGapTolerance(isMacOS: false, definedMs: 100),
        const Duration(milliseconds: 100),
      );
    });

    test('never exceeds the 100 ms doc 06 allows', () {
      expect(
        deviceGapTolerance(isMacOS: false, definedMs: 250),
        const Duration(milliseconds: 100),
      );
    });

    test('never goes below the 20 ms every device must hold', () {
      expect(
        deviceGapTolerance(isMacOS: false, definedMs: 5),
        const Duration(milliseconds: 20),
      );
    });
  });
}
