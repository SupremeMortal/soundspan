// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// RFC 6238 one-time codes for the seeded 2FA account.
library;

import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// The step of the server's codes.
const _step = Duration(seconds: 30);

/// How many steps either side of now the server accepts (60 seconds of
/// tolerance in `verifyTotpToken`).
const _toleranceSteps = 2;

/// The six-digit RFC 6238 code (HMAC-SHA1, 30-second step) of the base32
/// [secret] at [at], or now.
///
/// Throws [FormatException] when [secret] is not base32.
String totp(String secret, {DateTime? at}) {
  final time = at ?? DateTime.now();
  final counter = time.millisecondsSinceEpoch ~/ _step.inMilliseconds;
  final message = ByteData(8)..setUint64(0, counter);
  final digest = Hmac(
    sha1,
    _base32Decode(secret),
  ).convert(message.buffer.asUint8List()).bytes;
  final offset = digest.last & 0x0f;
  final binary =
      (digest[offset] & 0x7f) << 24 |
      digest[offset + 1] << 16 |
      digest[offset + 2] << 8 |
      digest[offset + 3];
  return (binary % 1000000).toString().padLeft(6, '0');
}

/// A six-digit code that is not the code of [secret] in any step the server
/// accepts around [at], or now.
String wrongTotp(String secret, {DateTime? at}) {
  final time = at ?? DateTime.now();
  final accepted = {
    for (var step = -_toleranceSteps; step <= _toleranceSteps; step++)
      totp(secret, at: time.add(_step * step)),
  };
  for (var candidate = 0; ; candidate++) {
    final code = candidate.toString().padLeft(6, '0');
    if (!accepted.contains(code)) return code;
  }
}

/// RFC 4648 base32, ignoring case, spaces and padding.
Uint8List _base32Decode(String input) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  final clean = input
      .toUpperCase()
      .replaceAll(RegExp(r'\s'), '')
      .replaceAll(RegExp(r'=+$'), '');
  final bytes = <int>[];
  var buffer = 0;
  var bits = 0;
  for (final char in clean.split('')) {
    final index = alphabet.indexOf(char);
    if (index < 0) {
      throw FormatException('TOTP secret is not base32', input);
    }
    buffer = (buffer << 5 | index) & 0xffff;
    bits += 5;
    if (bits >= 8) {
      bytes.add(buffer >> (bits - 8) & 0xff);
      bits -= 8;
    }
  }
  return Uint8List.fromList(bytes);
}
