// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:math';

/// Random (version 4) UUIDs.
abstract final class Uuid {
  static final Random _secure = Random.secure();

  /// A new UUID v4 in its lowercase 36-character form, drawn from
  /// [random] or, by default, `Random.secure()`.
  static String v4([Random? random]) {
    final r = random ?? _secure;
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4.
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant 10.
    final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')];
    return '${hex.sublist(0, 4).join()}-${hex.sublist(4, 6).join()}-'
        '${hex.sublist(6, 8).join()}-${hex.sublist(8, 10).join()}-'
        '${hex.sublist(10).join()}';
  }
}
