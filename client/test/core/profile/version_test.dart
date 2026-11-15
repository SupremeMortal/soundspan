// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/profile/version.dart';

Version _v(String text) => Version.tryParse(text)!;

void main() {
  test('ordering table', () {
    final lower = <(String, String)>[
      ('1.2.3', '1.10.0'),
      ('1.9.9', '2.0.0'),
      ('1.2.3', '1.2.4'),
      ('2.0.0-rc.1', '2.0.0'),
      ('2.0.0-alpha', '2.0.0-beta'),
      ('2.0.0-alpha', '2.0.0-alpha.1'),
      ('2.0.0-alpha.1', '2.0.0-alpha.beta'),
      ('2.0.0-beta.2', '2.0.0-beta.11'),
      ('2.0.0-rc.1', '2.0.0-rc.1.1'),
    ];
    for (final (a, b) in lower) {
      expect(_v(a).compareTo(_v(b)), lessThan(0), reason: '$a < $b');
      expect(_v(b).compareTo(_v(a)), greaterThan(0), reason: '$b > $a');
      expect(_v(a) < _v(b), isTrue, reason: '$a < $b');
    }
  });

  test('a leading v and build metadata are ignored', () {
    expect(_v('v1.2.3'), _v('1.2.3'));
    expect(_v('1.2.3+build'), _v('1.2.3'));
    expect(_v('1.2.3+build').compareTo(_v('1.2.3')), 0);
    expect(_v('V2.0.0-rc.1+sha.5114f85'), _v('2.0.0-rc.1'));
    expect(_v('1.2.3').hashCode, _v('v1.2.3+x').hashCode);
  });

  test('toString is the canonical form', () {
    expect(_v('v1.2.3+build').toString(), '1.2.3');
    expect(_v('2.0.0-rc.1').toString(), '2.0.0-rc.1');
  });

  test('garbage gives null', () {
    for (final text in [
      '',
      'unknown',
      '1',
      '1.2',
      '1.2.3.4',
      'a.b.c',
      '01.2.3',
      '1.2.3-',
      '1.2.3-a..b',
      '1.2.3-01',
      '-1.2.3',
      ' 1.2.3',
      '1.2.3+',
    ]) {
      expect(Version.tryParse(text), isNull, reason: text);
    }
  });
}
