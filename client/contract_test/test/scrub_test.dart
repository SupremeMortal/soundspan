// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:test/test.dart';

import '../tool/src/capture.dart';

void main() {
  const redactedKeys = [
    'token',
    'refreshToken',
    'apiKey',
    'secret',
    'password',
    'passwordHash',
  ];

  group('scrub', () {
    for (final key in redactedKeys) {
      test('replaces "$key" at the top level, nested and in arrays', () {
        final scrubbed = scrub({
          key: 'top',
          'nested': {key: 'inner'},
          'items': [
            {key: 'first'},
            {key: 'second'},
          ],
        });
        expect(scrubbed, {
          key: redacted,
          'nested': {key: redacted},
          'items': [
            {key: redacted},
            {key: redacted},
          ],
        });
      });
    }

    test('replaces "email" at the top level, nested and in arrays', () {
      final scrubbed = scrub({
        'email': 'a@b.c',
        'user': {'email': 'd@e.f'},
        'users': [
          {'email': 'g@h.i'},
        ],
      });
      expect(scrubbed, {
        'email': scrubbedEmail,
        'user': {'email': scrubbedEmail},
        'users': [
          {'email': scrubbedEmail},
        ],
      });
    });

    test('replaces a non-string value under a scrubbed key', () {
      expect(scrub({'token': null, 'secret': 42}), {
        'token': redacted,
        'secret': redacted,
      });
    });

    test('leaves other keys and values untouched', () {
      final body = {
        'id': 'abc',
        'username': 'listener',
        'count': 3,
        'ok': true,
        'missing': null,
        'tokens': ['x'],
        'list': [1, 'two', null],
      };
      expect(scrub(body), body);
    });

    test('sorts object keys at every depth', () {
      final scrubbed = scrub({
        'b': 1,
        'a': {'z': 1, 'y': 2},
        'c': [
          {'q': 1, 'p': 2},
        ],
      });
      expect(scrubbed, isA<Map<String, Object?>>());
      final map = scrubbed! as Map<String, Object?>;
      expect(map.keys, ['a', 'b', 'c']);
      expect((map['a']! as Map<String, Object?>).keys, ['y', 'z']);
      final element = (map['c']! as List<Object?>).single;
      expect((element! as Map<String, Object?>).keys, ['p', 'q']);
    });

    test('is idempotent', () {
      final once = scrub({
        'token': 't',
        'email': 'e@x.y',
        'b': [
          {'password': 'p', 'a': 1},
        ],
      });
      expect(scrub(once), once);
      expect(encodeFixture(scrub(once)), encodeFixture(once));
    });

    test('scrubs an array body', () {
      expect(
        scrub([
          {'apiKey': 'k'},
        ]),
        [
          {'apiKey': redacted},
        ],
      );
    });
  });

  group('encodeFixture', () {
    test('pretty-prints with sorted keys and a trailing newline', () {
      final text = encodeFixture({'b': 1, 'a': 2});
      expect(text, '{\n  "a": 2,\n  "b": 1\n}\n');
      expect(jsonDecode(text), {'a': 2, 'b': 1});
    });
  });
}
