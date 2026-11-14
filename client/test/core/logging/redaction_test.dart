// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/logging/redaction.dart';

import 'recording_sink.dart';

void main() {
  group('redact', () {
    const keys = [
      'token',
      'refreshToken',
      'apiKey',
      'password',
      'authorization',
      'x-api-key',
    ];
    for (final key in keys) {
      for (final variant in {
        key.toLowerCase(),
        key.toUpperCase(),
        _mixedCase(key),
      }) {
        test('redacts the field "$variant"', () {
          final out = redact(entryWith(fields: {variant: 'secret'}));
          expect(out.fields[variant], '<redacted>');
        });
      }
    }

    test('redacts a key inside a nested map', () {
      final out = redact(
        entryWith(
          fields: {
            'headers': {'Authorization': 'Bearer abc', 'accept': 'json'},
          },
        ),
      );
      expect(out.fields['headers'], {
        'Authorization': '<redacted>',
        'accept': 'json',
      });
    });

    test('redacts a key inside a list of maps', () {
      final out = redact(
        entryWith(
          fields: {
            'profiles': [
              {'id': 1, 'apiKey': 'k1'},
              {'id': 2, 'password': 'p'},
            ],
          },
        ),
      );
      expect(out.fields['profiles'], [
        {'id': 1, 'apiKey': '<redacted>'},
        {'id': 2, 'password': '<redacted>'},
      ]);
    });

    test('redacts ?token= at the end of a message', () {
      final out = redact(entryWith(message: 'GET /api/stream?token=abc'));
      expect(out.message, 'GET /api/stream?token=<redacted>');
    });

    test('redacts &token= in the middle of a message', () {
      final out = redact(entryWith(message: 'GET /s?a=1&token=abc&x=1'));
      expect(out.message, 'GET /s?a=1&token=<redacted>&x=1');
    });

    test('redacts ?token= inside a field value', () {
      final out = redact(entryWith(fields: {'url': '/s?token=abc'}));
      expect(out.fields['url'], '/s?token=<redacted>');
    });

    test('redacts ?token= inside the error text', () {
      final out = redact(entryWith(error: 'failed: /s?token=abc'));
      expect(out.error, 'failed: /s?token=<redacted>');
    });

    test('redacts ?token= inside the stack trace', () {
      final out = redact(entryWith(stackTrace: '#0 at /s?token=abc\n#1'));
      expect(out.stackTrace, '#0 at /s?token=<redacted>\n#1');
    });

    test('replaces the server base URL with <server>', () {
      final out = redact(
        entryWith(
          message: 'GET https://music.example.com/soundspan/api/library/albums',
          fields: {'url': 'https://music.example.com/soundspan/api/me'},
          error: 'at https://music.example.com/soundspan/api/x',
        ),
        serverBaseUrl: Uri.parse('https://music.example.com/soundspan'),
      );
      expect(out.message, 'GET <server>/api/library/albums');
      expect(out.fields['url'], '<server>/api/me');
      expect(out.error, 'at <server>/api/x');
    });

    test('replaces a base URL with a port', () {
      final out = redact(
        entryWith(message: 'http://10.0.0.2:3006/api/health'),
        serverBaseUrl: Uri.parse('http://10.0.0.2:3006/'),
      );
      expect(out.message, '<server>/api/health');
    });

    test('leaves URLs alone without a base URL', () {
      const message = 'GET https://music.example.com/soundspan/api/me';
      expect(redact(entryWith(message: message)).message, message);
    });

    test('leaves non-secret fields unchanged', () {
      final fields = <String, Object?>{
        'bytes': 3,
        'name': 'album',
        'ok': true,
        'nothing': null,
        'tokens': 'counted',
      };
      final entry = entryWith(fields: fields);
      final out = redact(entry);
      expect(out.fields, fields);
      expect(out.time, entry.time);
      expect(out.level, entry.level);
      expect(out.scope, entry.scope);
    });
  });
}

String _mixedCase(String key) {
  final buffer = StringBuffer();
  for (var i = 0; i < key.length; i++) {
    buffer.write(i.isEven ? key[i].toUpperCase() : key[i].toLowerCase());
  }
  return buffer.toString();
}
