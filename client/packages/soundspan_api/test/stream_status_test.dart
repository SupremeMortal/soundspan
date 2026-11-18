// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@TestOn('vm')
library;

import 'dart:io';

import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

void main() {
  late HttpServer server;
  late Uri base;
  final seen = <HttpHeaders>[];

  setUp(() async {
    seen.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = Uri.parse('http://127.0.0.1:${server.port}');
    server.listen((request) async {
      seen.add(request.headers);
      final status = switch (request.uri.path) {
        '/ok' => request.headers.value('x-key') == 'k' ? 206 : 401,
        '/gone' => 404,
        _ => 503,
      };
      request.response
        ..statusCode = status
        ..write('x');
      await request.response.close();
    });
  });

  tearDown(() => server.close(force: true));

  test('returns the status of a stream request carrying the headers', () async {
    final probe = StreamStatusProbe();
    addTearDown(probe.close);

    expect(
      await probe.status(base.resolve('/ok'), headers: {'X-Key': 'k'}),
      206,
    );
    expect(seen.single.value('x-key'), 'k');
    expect(seen.single.value('range'), 'bytes=0-0');
  });

  test('returns error statuses as they are', () async {
    final probe = StreamStatusProbe();
    addTearDown(probe.close);

    expect(await probe.status(base.resolve('/ok')), 401);
    expect(await probe.status(base.resolve('/gone')), 404);
    expect(await probe.status(base.resolve('/other')), 503);
  });

  test('returns null when no response arrives', () async {
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = socket.port;
    await socket.close();
    final probe = StreamStatusProbe();
    addTearDown(probe.close);

    expect(await probe.status(Uri.parse('http://127.0.0.1:$port/x')), isNull);
  });
}
