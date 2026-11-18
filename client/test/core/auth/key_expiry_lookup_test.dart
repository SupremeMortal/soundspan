// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/auth/api_key_repository.dart';
import 'package:soundspan/core/auth/key_expiry_lookup.dart';
import 'package:soundspan_api/soundspan_api.dart';

import '../../helpers/fake_clock.dart';
import 'device_link_fakes.dart';

Map<String, Object?> _key(String id, String name, String createdAt) => {
  'id': id,
  'name': name,
  'createdAt': createdAt,
  'expiresAt': DateTime.parse(createdAt)
      .add(const Duration(days: 90))
      .toIso8601String(),
  'lastUsed': null,
};

void main() {
  late FakeDeviceLinkServer server;
  late FakeClock clock;
  late SoundspanApi api;
  late KeyExpiryLookup lookup;

  setUp(() {
    server = FakeDeviceLinkServer();
    clock = FakeClock(start: DateTime.utc(2026, 3, 1, 12));
    api = server.api(
      ApiConfig(baseUrl: Uri.parse('https://music.example'), userAgent: 't'),
      issuedKey,
    );
    lookup = KeyExpiryLookup(ApiKeyRepository(api), clock);
  });
  tearDown(() => api.close());

  test('one match gives its dates', () async {
    server.answers['GET /api/api-keys'] = ok({
      'apiKeys': [
        _key('k1', 'Other (soundspan iOS)', '2026-01-01T00:00:00.000Z'),
        _key('k2', 'pc (soundspan Linux)', '2026-02-01T00:00:00.000Z'),
      ],
    });

    final dates = await lookup.lookup(deviceName: 'pc (soundspan Linux)');

    expect(dates.createdAt, DateTime.utc(2026, 2));
    expect(
      dates.expiresAt,
      DateTime.utc(2026, 2).add(const Duration(days: 90)),
    );
  });

  test('two matches pick the newest createdAt', () async {
    server.answers['GET /api/api-keys'] = ok({
      'apiKeys': [
        _key('k1', 'pc (soundspan Linux)', '2026-01-01T00:00:00.000Z'),
        _key('k2', 'pc (soundspan Linux)', '2026-02-15T00:00:00.000Z'),
        _key('k3', 'pc (soundspan Linux)', '2026-02-01T00:00:00.000Z'),
      ],
    });

    final dates = await lookup.lookup(deviceName: 'pc (soundspan Linux)');

    expect(dates.createdAt, DateTime.utc(2026, 2, 15));
  });

  test('no match gives now and now + 90 days', () async {
    server.answers['GET /api/api-keys'] = ok({
      'apiKeys': [
        _key('k1', 'Other (soundspan iOS)', '2026-01-01T00:00:00.000Z'),
      ],
    });

    final dates = await lookup.lookup(deviceName: 'pc (soundspan Linux)');

    expect(dates.createdAt, clock.now());
    expect(dates.expiresAt, clock.now().add(const Duration(days: 90)));
  });

  test('a failed request gives now and now + 90 days', () async {
    server.answers['GET /api/api-keys'] = error(500, 'boom');

    final dates = await lookup.lookup(deviceName: 'pc (soundspan Linux)');

    expect(dates.createdAt, clock.now());
    expect(dates.expiresAt, clock.now().add(const Duration(days: 90)));
  });
}
