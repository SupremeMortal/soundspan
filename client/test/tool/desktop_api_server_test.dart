// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/desktop_app.dart';
import '../../integration_test/support/tone_server.dart';

void main() {
  late DesktopApiServer server;
  late HttpClient client;

  setUp(() async {
    server = await DesktopApiServer.start();
    client = HttpClient();
  });

  tearDown(() async {
    client.close(force: true);
    await server.close();
  });

  Future<(HttpClientResponse, List<int>)> get(
    String path, {
    Map<String, String> headers = const {},
  }) async {
    final request = await client.getUrl(server.baseUrl.resolve(path));
    headers.forEach(request.headers.set);
    final response = await request.close();
    final body = await response.fold<List<int>>([], (a, b) => a..addAll(b));
    return (response, body);
  }

  // AVPlayer (JustAudioEngine on macOS and iOS) opens an HTTP stream with a
  // Range request and plays nothing from a server without byte ranges.
  test(
    'a stream answers Range requests with 206 and the asked bytes',
    () async {
      final whole = ToneServer.wav(DesktopApiServer.trackLength);
      const path = '/api/playback/stream/t.smoke-1';

      final (full, fullBody) = await get(path);
      expect(full.statusCode, 200);
      expect(full.headers.value('accept-ranges'), 'bytes');
      expect(full.headers.contentType?.mimeType, 'audio/wav');
      expect(fullBody, whole);

      final (probe, probeBody) = await get(
        path,
        headers: {'Range': 'bytes=0-1'},
      );
      expect(probe.statusCode, 206);
      expect(probe.headers.value('content-range'), 'bytes 0-1/${whole.length}');
      expect(probeBody, whole.sublist(0, 2));

      final (rest, restBody) = await get(
        path,
        headers: {'Range': 'bytes=1000-'},
      );
      expect(rest.statusCode, 206);
      expect(restBody, whole.sublist(1000));

      final (outside, _) = await get(
        path,
        headers: {'Range': 'bytes=${whole.length}-'},
      );
      expect(outside.statusCode, 416);
      expect(server.requested, everyElement(startsWith('GET $path')));
    },
  );
}
