// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/tone_server.dart';

void main() {
  late ToneServer server;
  late HttpClient client;

  setUp(() async {
    // flutter_test answers every HttpClient request with 400; this test
    // talks to a real server.
    HttpOverrides.global = null;
    server = await ToneServer.start(cors: true);
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

  final key = {ToneServer.keyHeader: ToneServer.key};

  test('a tone is a WAV file of the asked duration', () async {
    final (response, body) = await get('/tone/a.wav?ms=1000', headers: key);

    expect(response.statusCode, 200);
    expect(response.headers.contentType?.mimeType, 'audio/wav');
    expect(ascii.decode(body.sublist(0, 4)), 'RIFF');
    expect(ascii.decode(body.sublist(8, 12)), 'WAVE');
    expect(body, ToneServer.wav(const Duration(seconds: 1)));
    expect(body.length, 44 + 44100 * 2);
  });

  test('Range gives 206 with the right bytes', () async {
    final whole = ToneServer.wav(const Duration(seconds: 1));

    final (first, firstBody) = await get(
      '/tone/a.wav?ms=1000',
      headers: {...key, 'Range': 'bytes=0-1'},
    );
    expect(first.statusCode, 206);
    expect(firstBody, whole.sublist(0, 2));
    expect(first.headers.value('content-range'), 'bytes 0-1/${whole.length}');

    final (open, openBody) = await get(
      '/tone/a.wav?ms=1000',
      headers: {...key, 'Range': 'bytes=1000-'},
    );
    expect(open.statusCode, 206);
    expect(openBody, whole.sublist(1000));

    final (suffix, suffixBody) = await get(
      '/tone/a.wav?ms=1000',
      headers: {...key, 'Range': 'bytes=-10'},
    );
    expect(suffix.statusCode, 206);
    expect(suffixBody, whole.sublist(whole.length - 10));

    final (outside, _) = await get(
      '/tone/a.wav?ms=1000',
      headers: {...key, 'Range': 'bytes=${whole.length}-'},
    );
    expect(outside.statusCode, 416);
  });

  test('the 404 and 401 paths', () async {
    final (missing, _) = await get('/missing/a.wav', headers: key);
    final (forbidden, _) = await get('/unauthorized/a.wav', headers: key);

    expect(missing.statusCode, 404);
    expect(forbidden.statusCode, 401);
  });

  test('a tone request without the expected credential is rejected', () async {
    final (bare, _) = await get('/tone/a.wav');
    final (wrong, _) = await get(
      '/tone/a.wav',
      headers: {ToneServer.keyHeader: 'someone-else'},
    );
    final (token, _) = await get('/tone/a.wav?token=${ToneServer.key}');

    expect(bare.statusCode, 401);
    expect(wrong.statusCode, 401);
    expect(token.statusCode, 200);
  });

  test('recorded headers and query values are returned', () async {
    await get('/tone/b.wav?ms=1000&token=t', headers: {...key, 'X-Extra': '1'});

    final seen = server.lastRequest('/tone/b.wav')!;
    expect(seen.headers[ToneServer.keyHeader.toLowerCase()], ToneServer.key);
    expect(seen.headers['x-extra'], '1');
    expect(seen.query['token'], 't');
    expect(server.lastRequest('/tone/never.wav'), isNull);

    final (response, body) = await get('/requests?path=/tone/b.wav');
    expect(response.statusCode, 200);
    final json = jsonDecode(utf8.decode(body)) as Map<String, Object?>;
    expect((json['headers']! as Map)['x-extra'], '1');
    expect((json['query']! as Map)['token'], 't');
  });

  test('the slow tone is throttled', () async {
    final watch = Stopwatch()..start();
    final (response, body) = await get(
      '/slow/c.wav',
      headers: {...key, 'Range': 'bytes=0-${44 + 44100 * 2 * 2 - 1}'},
    );

    expect(response.statusCode, 206);
    expect(body.length, 44 + 44100 * 2 * 2);
    // Two seconds of audio at twice real time take about a second.
    expect(watch.elapsed, greaterThan(const Duration(milliseconds: 700)));
  });

  test('an unreachable server drops connections', () async {
    server.reachable = false;

    await expectLater(get('/tone/a.wav', headers: key), throwsA(anything));

    server.reachable = true;
    final (response, _) = await get('/tone/a.wav', headers: key);
    expect(response.statusCode, 200);
  });

  test('CORS preflight is answered when enabled', () async {
    final request = await client.openUrl(
      'OPTIONS',
      server.baseUrl.resolve('/tone/a.wav'),
    );
    final response = await request.close();
    await response.drain<void>();

    expect(response.statusCode, 204);
    expect(response.headers.value('access-control-allow-origin'), '*');
  });
}
