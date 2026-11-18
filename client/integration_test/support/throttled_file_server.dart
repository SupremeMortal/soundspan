// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// A local HTTP server that trickles one fixed body, for the downloader's
/// pause and restart cases (doc 07, Resume Rule).
///
/// Paths:
///
/// - `/ranged`: a strong `ETag`; a `Range` request is answered `206` with
///   the rest of the body.
/// - `/full200`: a strong `ETag`; every request, ranged or not, is answered
///   `200` with the whole body.
/// - `/weak`: like `/ranged`, with a weak `ETag`.
///
/// Every request is recorded in [ThrottledFileServer.requests].
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// One request the server received.
typedef ThrottledRequest = ({String path, String? range, String? ifRange});

/// Serves [body] slowly on the loopback interface.
final class ThrottledFileServer {
  new _(this._server, this.body);

  /// Starts a server that sends [size] bytes in about [duration].
  static Future<ThrottledFileServer> start({
    int size = 2 * 1024 * 1024,
    Duration duration = const Duration(seconds: 6),
  }) async {
    final body = Uint8List.fromList(
      List<int>.generate(size, (i) => (i * 31 + (i >> 8)) & 0xff),
    );
    late ThrottledFileServer server;
    final http = await shelf_io.serve(
      (request) => server._handle(request, duration),
      InternetAddress.loopbackIPv4,
      0,
    );
    return server = ThrottledFileServer._(http, body);
  }

  final HttpServer _server;

  /// The body every path serves.
  final Uint8List body;

  /// Every request received, oldest first.
  final List<ThrottledRequest> requests = [];

  /// The server's address.
  Uri get uri => Uri.parse('http://127.0.0.1:${_server.port}');

  /// Stops the server.
  Future<void> close() => _server.close(force: true);

  Response _handle(Request request, Duration duration) {
    final path = '/${request.url.path}';
    final range = request.headers['range'];
    requests.add((
      path: path,
      range: range,
      ifRange: request.headers['if-range'],
    ));
    final etag = switch (path) {
      '/ranged' || '/full200' => '"throttled-strong"',
      '/weak' => 'W/"throttled-weak"',
      _ => null,
    };
    if (etag == null) return Response.notFound('no such path');
    final start = path == '/full200' ? 0 : _rangeStart(range);
    final headers = {
      'etag': etag,
      'accept-ranges': 'bytes',
      'content-type': 'audio/flac',
      'content-length': '${body.length - start}',
      if (start > 0)
        'content-range': 'bytes $start-${body.length - 1}/${body.length}',
    };
    return Response(
      start > 0 ? 206 : 200,
      body: _trickle(start, duration),
      headers: headers,
    );
  }

  static int _rangeStart(String? range) {
    final match = RegExp(r'^bytes=(\d+)-$').firstMatch(range ?? '');
    return match == null ? 0 : int.parse(match.group(1)!);
  }

  Stream<List<int>> _trickle(int start, Duration duration) async* {
    const chunks = 60;
    final chunkSize = (body.length / chunks).ceil();
    final pause = duration ~/ chunks;
    for (var offset = start; offset < body.length; offset += chunkSize) {
      final end = offset + chunkSize < body.length
          ? offset + chunkSize
          : body.length;
      yield body.sublist(offset, end);
      await Future<void>.delayed(pause);
    }
  }
}
