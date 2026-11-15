// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart' show immutable;

/// A six-character device-link code from the web UI's device page (doc 04,
/// Device Link).
@immutable
final class DeviceLinkCode {
  const new _(this.value);

  /// The characters a code is made of: no `I`, `O`, `0` or `1`.
  static const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// How many characters a code has.
  static const length = 6;

  /// The code, upper-cased.
  final String value;

  /// The code in [input], trimmed and upper-cased, or null when that is not
  /// exactly [length] characters of [alphabet].
  static DeviceLinkCode? tryParse(String input) {
    final code = input.trim().toUpperCase();
    if (code.length != length) return null;
    for (var i = 0; i < code.length; i++) {
      if (!alphabet.contains(code[i])) return null;
    }
    return DeviceLinkCode._(code);
  }

  /// Whether [char] is one character of [alphabet], in either case (the
  /// code cells upper-case what is typed).
  static bool isAllowedChar(String char) =>
      char.length == 1 && alphabet.contains(char.toUpperCase());

  @override
  bool operator ==(Object other) =>
      other is DeviceLinkCode && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'DeviceLinkCode($value)';
}
