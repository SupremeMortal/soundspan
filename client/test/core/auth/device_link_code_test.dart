// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/auth/device_link_code.dart';

void main() {
  test('accepts lower case and returns the code upper-cased', () {
    expect(DeviceLinkCode.tryParse('abc234')?.value, 'ABC234');
  });

  test('trims surrounding whitespace', () {
    expect(DeviceLinkCode.tryParse('  XYZ789 \n')?.value, 'XYZ789');
  });

  test('rejects I, O, 0 and 1', () {
    for (final input in ['ABCDEI', 'ABCDEO', 'ABCDE0', 'ABCDE1']) {
      expect(DeviceLinkCode.tryParse(input), isNull, reason: input);
    }
  });

  test('rejects five and seven characters', () {
    expect(DeviceLinkCode.tryParse('ABCDE'), isNull);
    expect(DeviceLinkCode.tryParse('ABCDEFG'), isNull);
  });

  test('rejects an inner space and punctuation', () {
    expect(DeviceLinkCode.tryParse('ABC DE'), isNull);
    expect(DeviceLinkCode.tryParse('ABC-DE'), isNull);
  });

  test('isAllowedChar takes one character of the alphabet in either case', () {
    expect(DeviceLinkCode.isAllowedChar('A'), isTrue);
    expect(DeviceLinkCode.isAllowedChar('z'), isTrue);
    expect(DeviceLinkCode.isAllowedChar('9'), isTrue);
    for (final char in ['I', 'o', '0', '1', '-', '', 'AB']) {
      expect(DeviceLinkCode.isAllowedChar(char), isFalse, reason: char);
    }
  });

  test('codes with the same characters are equal', () {
    expect(
      DeviceLinkCode.tryParse('abc234'),
      DeviceLinkCode.tryParse('ABC234'),
    );
  });
}
