// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/shared/util/uuid.dart';

void main() {
  final shape = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  test('version and variant bits are correct', () {
    for (var i = 0; i < 100; i++) {
      final id = Uuid.v4();
      expect(id, matches(shape));
      final hex = id.replaceAll('-', '');
      // Version nibble (byte 6, high half) is 4.
      expect(int.parse(hex.substring(12, 13), radix: 16), 4);
      // Variant bits (byte 8, top two bits) are 10.
      expect(int.parse(hex.substring(16, 18), radix: 16) >> 6, 2);
    }
  });

  test('1,000 values are distinct', () {
    final ids = {for (var i = 0; i < 1000; i++) Uuid.v4()};
    expect(ids, hasLength(1000));
  });
}
