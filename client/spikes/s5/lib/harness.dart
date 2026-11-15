// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Spike S5 test servers: a throttling pass-through proxy that records the
/// resume headers of every request, and a slow server that answers every
/// request, ranged or not, with `200` and a fixed body. Pure `dart:io`, so
/// `tool/slow_server.dart` runs it on the CI host for the Android driver.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Bytes sent per write by the throttled servers.
const chunkBytes = 16 * 1024;

/// The fixed 2 MB body of the slow server: a deterministic byte pattern.
final Uint8List slowBody = Uint8List.fromList([
  for (var i = 0; i < 2 * 1024 * 1024; i++) (i * 31 + (i >> 11)) & 0xff,
]);

/// The strong `ETag` the slow server sends in its `etag` mode.
const slowEtag = '"s5-fixed-body"';

/// Lowercase hex SHA-256 of [bytes].
String sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();

/// One request seen by a harness server, with the answer it got.
class Exchange {
  /// Records one request and its answer.
  Exchange({
    required this.server,
    required this.path,
    required this.range,
    required this.ifRange,
    required this.status,
    required this.etag,
    required this.contentRange,
    required this.contentLength,
  });

  /// `proxy` or `slow`.
  final String server;

  /// Path and query of the request.
  final String path;

  /// The request's `Range` header.
  final String? range;

  /// The request's `If-Range` header.
  final String? ifRange;

  /// The response status.
  final int status;

  /// The response's `ETag` header.
  final String? etag;

  /// The response's `Content-Range` header.
  final String? contentRange;

  /// The response's `Content-Length` header.
  final String? contentLength;

  /// Body bytes written to the client before the response ended or the
  /// client went away.
  int bytesSent = 0;

  /// The first byte offset of [range], or null.
  int? get rangeStart {
    final match = RegExp(r'bytes=(\d+)-').firstMatch(range ?? '');
    return match == null ? null : int.parse(match.group(1)!);
  }

  /// One log line for the step summary and the proxy-log artifact.
  String toLine() =>
      'S5-HTTP ${jsonEncode({'server': server, 'path': path.replaceAll(RegExp('token=[^&]*'), 'token=***'), 'range': range, 'ifRange': ifRange, 'status': status, 'etag': etag, 'contentRange': contentRange, 'contentLength': contentLength, 'bytesSent': bytesSent})}';
}

/// Writes [body] to [response] in [chunkBytes] pieces spread over [duration],
/// counting into [exchange]; stops quietly when the client goes away.
Future<void> _trickle(
  HttpResponse response,
  Stream<List<int>> body,
  int? length,
  Duration duration,
  Exchange exchange,
) async {
  final pieces = length == null || length == 0
      ? 1
      : (length + chunkBytes - 1) ~/ chunkBytes;
  final delay = Duration(microseconds: duration.inMicroseconds ~/ pieces);
  var pending = <int>[];
  try {
    await for (final data in body) {
      pending = [...pending, ...data];
      while (pending.length >= chunkBytes) {
        response.add(pending.sublist(0, chunkBytes));
        await response.flush();
        exchange.bytesSent += chunkBytes;
        pending = pending.sublist(chunkBytes);
        await Future<void>.delayed(delay);
      }
    }
    if (pending.isNotEmpty) {
      response.add(pending);
      await response.flush();
      exchange.bytesSent += pending.length;
    }
    await response.close();
  } on Object {
    // The client paused or was killed: the connection is gone.
  }
}

/// A pass-through proxy to [target] that trickles every response body over
/// about [perFile] and records each request's resume headers.
class ThrottleProxy {
  ThrottleProxy._(this._server, this.target, this.perFile);

  /// Starts the proxy on a free loopback port.
  static Future<ThrottleProxy> start(
    Uri target, {
    Duration perFile = const Duration(seconds: 10),
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final proxy = ThrottleProxy._(server, target, perFile);
    server.listen(proxy._handle);
    return proxy;
  }

  final HttpServer _server;

  /// The server requests are forwarded to.
  final Uri target;

  /// Roughly how long one full body takes to pass.
  final Duration perFile;

  final HttpClient _client = HttpClient();

  /// Every request so far, in arrival order.
  final List<Exchange> exchanges = [];

  /// The proxy's base address.
  Uri get uri => Uri.parse('http://127.0.0.1:${_server.port}');

  Future<void> _handle(HttpRequest request) async {
    final upstream = await _client.openUrl(
      request.method,
      target.resolve(request.uri.toString()),
    );
    request.headers.forEach((name, values) {
      if (name == HttpHeaders.hostHeader) return;
      for (final value in values) {
        upstream.headers.add(name, value);
      }
    });
    upstream.followRedirects = false;
    await upstream.addStream(request);
    final answer = await upstream.close();
    final exchange = Exchange(
      server: 'proxy',
      path: request.uri.toString(),
      range: request.headers.value(HttpHeaders.rangeHeader),
      ifRange: request.headers.value('if-range'),
      status: answer.statusCode,
      etag: answer.headers.value(HttpHeaders.etagHeader),
      contentRange: answer.headers.value(HttpHeaders.contentRangeHeader),
      contentLength: answer.headers.value(HttpHeaders.contentLengthHeader),
    );
    exchanges.add(exchange);
    final response = request.response
      ..statusCode = answer.statusCode
      ..contentLength = answer.contentLength
      ..persistentConnection = false;
    answer.headers.forEach((name, values) {
      if (name == HttpHeaders.contentLengthHeader ||
          name == HttpHeaders.transferEncodingHeader ||
          name == HttpHeaders.connectionHeader) {
        return;
      }
      for (final value in values) {
        response.headers.add(name, value);
      }
    });
    response.headers.contentLength = answer.contentLength;
    await _trickle(
      response,
      answer,
      answer.contentLength < 0 ? null : answer.contentLength,
      perFile,
      exchange,
    );
  }

  /// Stops the proxy.
  Future<void> close() async {
    _client.close(force: true);
    await _server.close(force: true);
  }
}

/// Serves [slowBody] slowly on `/full` (always `200` with the whole body and
/// [slowEtag]), `/full-noetag` (the same without an `ETag`) and `/ranged`
/// (`206` from the requested offset under [slowEtag] when a `Range` comes
/// without an `If-Range` or with a matching one). Every answer advertises
/// `Accept-Ranges: bytes`. Query `seconds` sets the duration of a full body
/// (default 10; 0 sends it at once).
class SlowServer {
  SlowServer._(this._server);

  /// Starts on [address] and [port] (0 picks a free port); [onExchange]
  /// sees each request once its response has ended.
  static Future<SlowServer> start({
    InternetAddress? address,
    int port = 0,
    void Function(Exchange exchange)? onExchange,
  }) async {
    final server = await HttpServer.bind(
      address ?? InternetAddress.loopbackIPv4,
      port,
    );
    final slow = SlowServer._(server).._onExchange = onExchange;
    server.listen(slow._handle);
    return slow;
  }

  final HttpServer _server;
  void Function(Exchange exchange)? _onExchange;

  /// Every request so far, in arrival order.
  final List<Exchange> exchanges = [];

  /// The server's port.
  int get port => _server.port;

  /// The server's loopback base address.
  Uri get uri => Uri.parse('http://127.0.0.1:${_server.port}');

  Future<void> _handle(HttpRequest request) async {
    final mode = request.uri.path;
    final seconds =
        int.tryParse(request.uri.queryParameters['seconds'] ?? '') ?? 10;
    final range = request.headers.value(HttpHeaders.rangeHeader);
    final ifRange = request.headers.value('if-range');
    final response = request.response..persistentConnection = false;
    response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
    if (mode != '/full-noetag') {
      response.headers.set(HttpHeaders.etagHeader, slowEtag);
    }
    var start = 0;
    final rangeStart = RegExp(r'bytes=(\d+)-').firstMatch(range ?? '');
    if (mode == '/ranged' &&
        rangeStart != null &&
        (ifRange == null || ifRange == slowEtag)) {
      start = int.parse(rangeStart.group(1)!);
    }
    final total = slowBody.length;
    if (start > 0) {
      response
        ..statusCode = HttpStatus.partialContent
        ..headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes $start-${total - 1}/$total',
        );
    } else if (!{'/full', '/full-noetag', '/ranged'}.contains(mode)) {
      response.statusCode = HttpStatus.notFound;
      await response.close();
      return;
    }
    final body = slowBody.sublist(start);
    response.contentLength = body.length;
    final exchange = Exchange(
      server: 'slow',
      path: request.uri.toString(),
      range: range,
      ifRange: ifRange,
      status: response.statusCode,
      etag: response.headers.value(HttpHeaders.etagHeader),
      contentRange: response.headers.value(HttpHeaders.contentRangeHeader),
      contentLength: '${body.length}',
    );
    exchanges.add(exchange);
    await _trickle(
      response,
      Stream.value(body),
      body.length,
      Duration(seconds: seconds) * (body.length / total),
      exchange,
    );
    _onExchange?.call(exchange);
  }

  /// Stops the server.
  Future<void> close() => _server.close(force: true);
}

/// GETs [uri] with [headers] through `dart:io` alone: the reference bytes.
Future<Uint8List> fetchReference(
  Uri uri, [
  Map<String, String> headers = const {},
]) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    headers.forEach(request.headers.set);
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('reference GET answered ${response.statusCode}');
    }
    final builder = await response.fold<BytesBuilder>(
      BytesBuilder(copy: false),
      (builder, chunk) => builder..add(chunk),
    );
    return builder.takeBytes();
  } finally {
    client.close(force: true);
  }
}
