// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/auth/server_address.dart';

typedef _Row = ({
  String input,
  List<String> candidates,
  String? linkCode,
  bool explicitScheme,
  bool publicCleartext,
});

_Row _row(
  String input,
  List<String> candidates, {
  String? linkCode,
  bool explicitScheme = false,
  bool publicCleartext = false,
}) => (
  input: input,
  candidates: candidates,
  linkCode: linkCode,
  explicitScheme: explicitScheme,
  publicCleartext: publicCleartext,
);

List<String> _lan(String hostAndPort) => [
  'http://$hostAndPort',
  'https://$hostAndPort',
];

final _rows = <_Row>[
  _row('music.example.com', ['https://music.example.com']),
  _row('  https://music.example.com/  ', [
    'https://music.example.com',
  ], explicitScheme: true),
  _row('HTTPS://Music.Example.COM', [
    'https://music.example.com',
  ], explicitScheme: true),
  _row('https://example.com/soundspan', [
    'https://example.com/soundspan',
  ], explicitScheme: true),
  _row('https://example.com/soundspan/api/', [
    'https://example.com/soundspan',
  ], explicitScheme: true),
  _row('https://example.com/Soundspan/API', [
    'https://example.com/Soundspan/API',
  ], explicitScheme: true),
  _row('example.com/api', ['https://example.com']),
  _row('https://example.com:443/x?y=1#z', [
    'https://example.com/x',
  ], explicitScheme: true),
  _row('https://example.com:8443', [
    'https://example.com:8443',
  ], explicitScheme: true),
  _row(
    'http://music.example.com',
    ['http://music.example.com'],
    explicitScheme: true,
    publicCleartext: true,
  ),
  _row('192.168.1.20:3030', _lan('192.168.1.20:3030')),
  _row('192.168.1.20:443', ['http://192.168.1.20:443', 'https://192.168.1.20']),
  for (final host in [
    '10.0.0.5',
    '172.16.0.1',
    '172.31.255.254',
    '127.0.0.1',
    '169.254.10.1',
    '100.64.0.1',
    '100.127.255.254',
  ])
    _row(host, _lan(host)),
  for (final host in [
    '172.15.0.1',
    '172.32.0.1',
    '100.63.255.255',
    '100.128.0.1',
    '8.8.8.8',
  ])
    _row(host, ['https://$host']),
  _row('::1', _lan('[::1]')),
  _row('[fd00::1]:3030', _lan('[fd00::1]:3030')),
  _row('fc00::1', _lan('[fc00::1]')),
  _row('fe80::1', _lan('[fe80::1]')),
  _row('febf::1', _lan('[febf::1]')),
  _row('2001:db8::1', ['https://[2001:db8::1]']),
  _row('fec0::1', ['https://[fec0::1]']),
  for (final host in [
    'nas',
    'localhost:3030',
    'server.local',
    'music.lan',
    'box.home.arpa',
    'svc.internal',
  ])
    _row(host, _lan(host)),
  _row('https://nas', ['https://nas'], explicitScheme: true),
  _row(
    'soundspan://link?code=ABC234&server=https%3A%2F%2Fmusic.example.com',
    ['https://music.example.com'],
    linkCode: 'ABC234',
    explicitScheme: true,
  ),
  _row(
    'soundspan://link?code=ABC234&server=192.168.1.20%3A3030',
    _lan('192.168.1.20:3030'),
    linkCode: 'ABC234',
  ),
];

final _errorRows = <(String, ServerAddressError)>[
  ('', ServerAddressError.empty),
  ('   \t\n', ServerAddressError.empty),
  ('ftp://example.com', ServerAddressError.unsupportedScheme),
  ('soundspan://album/1', ServerAddressError.unsupportedScheme),
  ('soundspan://link?code=ABC234', ServerAddressError.linkMissingServer),
  (
    'soundspan://link?code=ABC234&server=',
    ServerAddressError.linkMissingServer,
  ),
  ('https://user:pw@example.com', ServerAddressError.invalid),
  ('https://', ServerAddressError.invalid),
  ('exa mple.com', ServerAddressError.invalid),
  ('example.com:99999', ServerAddressError.invalid),
  ('example.com:0', ServerAddressError.invalid),
];

void main() {
  group('ServerAddress.parse', () {
    for (final row in _rows) {
      test('"${row.input}" gives ${row.candidates}', () {
        final address = ServerAddress.parse(row.input);
        expect(
          address.candidates.map((uri) => uri.toString()).toList(),
          row.candidates,
        );
        expect(address.linkCode, row.linkCode);
        expect(address.explicitScheme, row.explicitScheme);
        expect(address.isPublicCleartext, row.publicCleartext);
      });
    }

    for (final (input, error) in _errorRows) {
      test('"$input" throws ${error.name}', () {
        expect(
          () => ServerAddress.parse(input),
          throwsA(
            isA<ServerAddressException>().having(
              (e) => e.error,
              'error',
              error,
            ),
          ),
        );
      });
    }

    test('no candidate ends with a slash', () {
      for (final row in _rows) {
        for (final uri in ServerAddress.parse(row.input).candidates) {
          expect(uri.toString().endsWith('/'), isFalse, reason: '$uri');
        }
      }
    });

    test('parsing a candidate again returns that single candidate', () {
      for (final row in _rows) {
        for (final uri in ServerAddress.parse(row.input).candidates) {
          final again = ServerAddress.parse(uri.toString());
          expect(again.candidates, [uri]);
          expect(again.explicitScheme, isTrue);
        }
      }
    });

    test('hasPrivateHost reports the host of the input', () {
      expect(ServerAddress.parse('192.168.1.20').hasPrivateHost, isTrue);
      expect(ServerAddress.parse('https://nas').hasPrivateHost, isTrue);
      expect(ServerAddress.parse('music.example.com').hasPrivateHost, isFalse);
    });

    test('plain http to a private host is not public cleartext', () {
      final address = ServerAddress.parse('http://192.168.1.20:3030');
      expect(address.candidates.map((uri) => '$uri'), [
        'http://192.168.1.20:3030',
      ]);
      expect(address.isPublicCleartext, isFalse);
    });
  });

  group('ServerAddress.isPrivateHost', () {
    const private = [
      '10.0.0.0',
      '10.255.255.255',
      '172.16.0.0',
      '172.31.255.255',
      '192.168.0.0',
      '192.168.255.255',
      '127.0.0.1',
      '127.255.255.255',
      '169.254.0.0',
      '169.254.255.255',
      '100.64.0.0',
      '100.127.255.255',
      '::1',
      '[::1]',
      'fc00::',
      'fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
      'fe80::',
      'febf:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
      'nas',
      'localhost',
      'server.local',
      'music.lan',
      'box.home.arpa',
      'svc.internal',
      'NAS.LOCAL',
    ];
    const public = [
      '9.255.255.255',
      '11.0.0.0',
      '172.15.255.255',
      '172.32.0.0',
      '192.167.255.255',
      '192.169.0.0',
      '126.255.255.255',
      '128.0.0.0',
      '169.253.255.255',
      '169.255.0.0',
      '100.63.255.255',
      '100.128.0.0',
      '8.8.8.8',
      '::',
      '::2',
      'fbff:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
      'fe00::',
      'fe7f:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
      'fec0::',
      '2001:db8::1',
      'music.example.com',
      'local.example.com',
      'example.lan.com',
    ];
    for (final host in private) {
      test('$host is private', () {
        expect(ServerAddress.isPrivateHost(host), isTrue);
      });
    }
    for (final host in public) {
      test('$host is not private', () {
        expect(ServerAddress.isPrivateHost(host), isFalse);
      });
    }
  });
}
