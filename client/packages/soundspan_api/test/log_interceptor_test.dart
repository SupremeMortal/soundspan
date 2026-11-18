// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan_api/soundspan_api.dart';
import 'package:soundspan_api/src/transport/log_interceptor.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  group('LogInterceptor', () {
    late List<ApiLogEntry> entries;
    late Harness h;

    setUp(() {
      entries = [];
      var tick = DateTime.utc(2026);
      h = Harness(
        credentials: FixedCredentials(
          const ApiKeyCredentials(apiKey: 'K-SECRET'),
        ),
        playbackDeviceId: 'DEVICE-SECRET',
        log: entries.add,
        now: () => tick = tick.add(const Duration(milliseconds: 25)),
      );
    });

    test('reports method, path template, status and duration', () async {
      h.server.onGet(
        h.url('/library/albums/abc123'),
        (s) => s.reply(200, {'title': 'BODY-SECRET'}),
      );
      await h.dio.get<dynamic>(
        '/library/albums/abc123',
        queryParameters: {'size': 'QUERY-SECRET'},
      );
      expect(entries, hasLength(1));
      final entry = entries.single;
      expect(entry.method, 'GET');
      expect(entry.pathTemplate, '/library/albums/:id');
      expect(entry.status, 200);
      expect(entry.duration, const Duration(milliseconds: 25));
    });

    test('the entry text holds no query value, header value or body', () async {
      h.server.onPost(
        h.url('/playlists/p-9/items'),
        (s) => s.reply(201, {'title': 'BODY-SECRET'}),
      );
      await h.dio.post<dynamic>(
        '/playlists/p-9/items',
        queryParameters: {'size': 'QUERY-SECRET'},
        data: {'trackId': 'REQUEST-SECRET'},
      );
      final text = entries.single.toString();
      expect(text, contains('POST'));
      expect(text, contains('/playlists/:id/items'));
      expect(text, isNot(contains('SECRET')));
    });

    test('failed requests are reported with their status', () async {
      h.server.onGet(
        h.url('/library/tracks/t1'),
        (s) => s.reply(404, {'error': 'Not found'}),
      );
      await expectLater(
        h.dio.get<dynamic>('/library/tracks/t1'),
        throwsA(isA<NotFound>()),
      );
      expect(entries.single.status, 404);
      expect(entries.single.pathTemplate, '/library/tracks/:id');
    });
  });

  group('pathTemplate', () {
    test('keeps lower-case and hyphen segments and replaces the rest', () {
      expect(pathTemplate('/auth/me'), '/auth/me');
      expect(pathTemplate('/api-keys/current'), '/api-keys/current');
      expect(pathTemplate('/library/cover-art/X1'), '/library/cover-art/:id');
      expect(
        pathTemplate('/podcasts/1/episodes/2'),
        '/podcasts/:id/episodes/:id',
      );
    });
  });
}
