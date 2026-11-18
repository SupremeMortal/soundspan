// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/shared/util/byte_size.dart';

void main() {
  test('sizes read in decimal units, one decimal below 10', () {
    expect(formatByteSize(0), '0 B');
    expect(formatByteSize(-5), '0 B');
    expect(formatByteSize(512), '512 B');
    expect(formatByteSize(1500), '1.5 KB');
    expect(formatByteSize(30000000), '30 MB');
    expect(formatByteSize(1234567890), '1.2 GB');
    expect(formatByteSize(12000000000), '12 GB');
    expect(formatByteSize(5000000000000000), '5000 TB');
  });
}
