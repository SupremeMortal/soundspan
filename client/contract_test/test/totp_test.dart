// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:test/test.dart';

import 'support/totp.dart';

/// Base32 of the ASCII seed `12345678901234567890` of RFC 6238, Appendix B.
const _rfcSecret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';

DateTime _at(int seconds) =>
    DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);

void main() {
  group('totp', () {
    // The SHA-1 vectors of RFC 6238, Appendix B, reduced to six digits.
    const vectors = {
      59: '287082',
      1111111109: '081804',
      1111111111: '050471',
      1234567890: '005924',
      2000000000: '279037',
      20000000000: '353130',
    };
    for (final MapEntry(key: seconds, value: code) in vectors.entries) {
      test('answers $code at $seconds seconds', () {
        expect(totp(_rfcSecret, at: _at(seconds)), code);
      });
    }

    test('accepts lower case, padding and spaces in the secret', () {
      expect(
        totp('gezd gnbv gy3t qojq gezd gnbv gy3t qojq====', at: _at(59)),
        '287082',
      );
    });

    test('rejects a secret that is not base32', () {
      expect(() => totp('GEZD1', at: _at(59)), throwsFormatException);
    });
  });

  group('wrongTotp', () {
    test('differs from every code the server accepts around the time', () {
      final now = _at(1111111111);
      final wrong = wrongTotp(_rfcSecret, at: now);

      expect(wrong, matches(RegExp(r'^\d{6}$')));
      for (var step = -2; step <= 2; step++) {
        final at = now.add(Duration(seconds: 30 * step));
        expect(wrong, isNot(totp(_rfcSecret, at: at)));
      }
    });
  });
}
