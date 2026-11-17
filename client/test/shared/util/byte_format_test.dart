// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/shared/util/byte_format.dart';

void main() {
  test('bytes under 1 KB are whole bytes', () {
    expect(formatBytes(0, 'en'), '0 B');
    expect(formatBytes(1023, 'en'), '1,023 B');
  });

  test('larger sizes use binary units with one decimal', () {
    expect(formatBytes(1024, 'en'), '1.0 KB');
    expect(formatBytes(1536 * 1024, 'en'), '1.5 MB');
    expect(formatBytes(20 * 1024 * 1024 * 1024, 'en'), '20.0 GB');
    expect(formatBytes(3 * 1024 * 1024 * 1024 * 1024, 'en'), '3.0 TB');
    expect(formatBytes(2048 * 1024 * 1024 * 1024 * 1024, 'en'), '2,048.0 TB');
  });

  test('the number follows the locale', () {
    expect(formatBytes(1536 * 1024, 'de'), '1,5 MB');
  });

  test('a negative size reads as zero', () {
    expect(formatBytes(-5, 'en'), '0 B');
  });
}
