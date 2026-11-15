// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/release/validate_tag.dart';

void main() {
  test('client-v0.1.0 with pubspec 0.1.0+1 passes and yields 0.1.0', () {
    final result = validateTag(tag: 'client-v0.1.0', pubspecVersion: '0.1.0+1');

    expect(result.ok, isTrue, reason: result.message);
    expect(result.version, '0.1.0');
  });

  test('a pre-release tag matching the pubspec version passes', () {
    final result = validateTag(
      tag: 'client-v0.1.0-rc.1',
      pubspecVersion: '0.1.0-rc.1+7',
    );

    expect(result.ok, isTrue, reason: result.message);
    expect(result.version, '0.1.0-rc.1');
  });

  test('a pubspec version without a build number is accepted', () {
    final result = validateTag(tag: 'client-v1.2.3', pubspecVersion: '1.2.3');

    expect(result.ok, isTrue, reason: result.message);
    expect(result.version, '1.2.3');
  });

  for (final tag in [
    'v0.1.0',
    'client-0.1.0',
    'client-v0.1',
    'client-v0.1.0+3',
    'client-v0.2.0',
    'client-v01.0.0',
  ]) {
    test('$tag fails with a message naming both values', () {
      final result = validateTag(tag: tag, pubspecVersion: '0.1.0+1');

      expect(result.ok, isFalse);
      expect(result.version, isNull);
      expect(result.message, contains(tag));
      expect(result.message, contains('0.1.0+1'));
    });
  }

  test('an invalid pubspec version fails', () {
    final result = validateTag(tag: 'client-v0.1', pubspecVersion: '0.1+1');

    expect(result.ok, isFalse);
    expect(result.message, contains('0.1+1'));
  });

  group('pubspecVersion', () {
    test('reads the version field', () {
      expect(
        pubspecVersion('name: soundspan\nversion: 0.3.0+12\n'),
        '0.3.0+12',
      );
    });

    test('is null without a version', () {
      expect(pubspecVersion('name: soundspan\n'), isNull);
    });
  });
}
