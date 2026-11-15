// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/auth/api_key_repository.dart';
import 'package:soundspan_api/soundspan_api.dart';

import 'device_link_fakes.dart';

void main() {
  late FakeDeviceLinkServer server;
  final baseUrl = Uri.parse('https://music.example');

  setUp(() => server = FakeDeviceLinkServer());

  test('list maps every key', () async {
    server.answers['GET /api/api-keys'] = ok({
      'apiKeys': [
        {
          'id': 'k1',
          'name': 'pc (soundspan Linux)',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'expiresAt': '2026-04-01T00:00:00.000Z',
          'lastUsed': null,
        },
      ],
    });
    final api = server.api(
      ApiConfig(baseUrl: baseUrl, userAgent: 't'),
      issuedKey,
    );
    addTearDown(api.close);

    final keys = await ApiKeyRepository(api).list();

    expect(keys, [
      ApiKeyInfo(
        id: 'k1',
        name: 'pc (soundspan Linux)',
        createdAt: DateTime.utc(2026),
        expiresAt: DateTime.utc(2026, 4),
      ),
    ]);
  });

  test('revokeCurrent sends DELETE /api/api-keys/current', () async {
    final api = server.api(
      ApiConfig(baseUrl: baseUrl, userAgent: 't'),
      issuedKey,
    );
    addTearDown(api.close);

    await ApiKeyRepository(api).revokeCurrent();

    expect(server.to('DELETE /api/api-keys/current'), hasLength(1));
  });

  test('revokeWith sends X-API-Key with the given key', () async {
    await ApiKeyRepository.revokeWith(
      baseUrl: baseUrl,
      apiKey: 'old-key',
      apis: server.api,
    );

    final sent = server.to('DELETE /api/api-keys/current').single;
    expect(sent.headers['X-API-Key'], 'old-key');
    expect(server.closed, 1);
  });

  test('revokeWith honours the timeout', () async {
    server.hang = true;
    final watch = Stopwatch()..start();

    await expectLater(
      ApiKeyRepository.revokeWith(
        baseUrl: baseUrl,
        apiKey: 'old-key',
        timeout: const Duration(milliseconds: 50),
        apis: server.api,
      ),
      throwsA(isA<Offline>()),
    );

    expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
    expect(server.closed, 1);
  });

  test('revokeWith lets a server error propagate', () async {
    server.answers['DELETE /api/api-keys/current'] = error(500, 'boom');

    await expectLater(
      ApiKeyRepository.revokeWith(
        baseUrl: baseUrl,
        apiKey: 'old-key',
        apis: server.api,
      ),
      throwsA(isA<ServerError>()),
    );
  });
}
