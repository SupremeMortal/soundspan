// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The tone server of the engine conformance suite on devices: WAV tones
/// generated in Dart, served with Range support, with dedicated 404 and 401
/// paths, a throttled long tone and a record of the headers per path.
///
/// Paths, `<name>` being any file name:
///
/// - `/tone/<name>?ms=<duration>`: a 440 Hz tone (3 s when `ms` is absent).
///   Answers 401 unless the request carries [ToneServer.keyHeader] or the
///   `token` query value set to [ToneServer.key].
/// - `/slow/<name>`: a 60 s tone sent at twice real time, under the same
///   credential check.
/// - `/missing/<name>`: always 404. `/unauthorized/<name>`: always 401.
/// - `/requests?path=<path>`: the last request recorded for `<path>` as JSON
///   `{"headers": {...}, "query": {...}}`, or 404. Not recorded itself.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// The headers (lower-case names) and query values of one request.
final class RecordedRequest {
  /// Creates a record.
  const new(this.headers, this.query);

  /// The request headers by lower-case name.
  final Map<String, String> headers;

  /// The query values.
  final Map<String, String> query;

  /// The record as JSON.
  Map<String, Object?> toJson() => {'headers': headers, 'query': query};
}

/// A `shelf` server of test tones on the loopback interface.
final class ToneServer {
  new _(this._server, {required this.cors}) {
    for (final ms in const [1000, 3000, 5000]) {
      _tones[ms] = wav(Duration(milliseconds: ms));
    }
    _tones[slowLength.inMilliseconds] = wav(slowLength);
  }

  /// Starts a server on [port] (any free one when 0) of the loopback
  /// interface. [cors] allows every origin, for a test page served from
  /// another port.
  static Future<ToneServer> start({int port = 0, bool cors = false}) async {
    late ToneServer tones;
    final server = await shelf_io.serve(
      (request) => tones._handle(request),
      InternetAddress.loopbackIPv4,
      port,
    );
    return tones = ToneServer._(server, cors: cors);
  }

  /// The header that carries the credential.
  static const String keyHeader = 'X-Conformance-Key';

  /// The credential the tone paths expect.
  static const String key = 'conformance';

  /// The length of the slow tone.
  static const Duration slowLength = Duration(seconds: 60);

  /// Samples per second of every tone.
  static const int sampleRate = 44100;

  static const int _headerLength = 44;

  final HttpServer _server;

  /// Whether every response allows any origin.
  final bool cors;

  final Map<int, Uint8List> _tones = {};
  final Map<String, RecordedRequest> _recorded = {};

  /// While false every connection is closed without a response, as if the
  /// network were down.
  bool reachable = true;

  /// The server address, without a trailing slash.
  Uri get baseUrl => Uri.parse('http://127.0.0.1:${_server.port}');

  /// The last request recorded for [path], or null.
  RecordedRequest? lastRequest(String path) => _recorded[path];

  /// Stops the server.
  Future<void> close() => _server.close(force: true);

  /// A mono 16-bit PCM WAV file of a 440 Hz tone lasting [duration].
  static Uint8List wav(Duration duration) {
    final samples = duration.inMicroseconds * sampleRate ~/ 1000000;
    final data = samples * 2;
    final bytes = ByteData(_headerLength + data);
    void ascii4(int at, String s) {
      for (var i = 0; i < 4; i++) {
        bytes.setUint8(at + i, s.codeUnitAt(i));
      }
    }

    ascii4(0, 'RIFF');
    bytes.setUint32(4, 36 + data, Endian.little);
    ascii4(8, 'WAVE');
    ascii4(12, 'fmt ');
    bytes
      ..setUint32(16, 16, Endian.little)
      ..setUint16(20, 1, Endian.little) // PCM
      ..setUint16(22, 1, Endian.little) // mono
      ..setUint32(24, sampleRate, Endian.little)
      ..setUint32(28, sampleRate * 2, Endian.little)
      ..setUint16(32, 2, Endian.little)
      ..setUint16(34, 16, Endian.little);
    ascii4(36, 'data');
    bytes.setUint32(40, data, Endian.little);
    for (var i = 0; i < samples; i++) {
      final value = (math.sin(2 * math.pi * 440 * i / sampleRate) * 9830)
          .round();
      bytes.setInt16(_headerLength + i * 2, value, Endian.little);
    }
    return bytes.buffer.asUint8List();
  }

  Map<String, String> get _corsHeaders => cors
      ? const {
          'access-control-allow-origin': '*',
          'access-control-allow-headers': '*',
          'access-control-allow-methods': 'GET, HEAD, OPTIONS',
          'access-control-expose-headers': '*',
        }
      : const {};

  Future<Response> _handle(Request request) async {
    if (!reachable) {
      request.hijack((channel) => unawaited(channel.sink.close()));
    }
    if (request.method == 'OPTIONS') {
      return Response(204, headers: _corsHeaders);
    }
    final path = '/${request.url.path}';
    if (path == '/requests') {
      final recorded = _recorded[request.url.queryParameters['path']];
      return recorded == null
          ? Response.notFound('', headers: _corsHeaders)
          : Response.ok(
              jsonEncode(recorded.toJson()),
              headers: {..._corsHeaders, 'content-type': 'application/json'},
            );
    }
    _recorded[path] = RecordedRequest({
      for (final MapEntry(:key, :value) in request.headers.entries)
        key.toLowerCase(): value,
    }, Map.of(request.url.queryParameters));

    final segments = request.url.pathSegments;
    final kind = segments.isEmpty ? '' : segments.first;
    switch (kind) {
      case 'missing':
        return Response.notFound('', headers: _corsHeaders);
      case 'unauthorized':
        return Response.unauthorized('', headers: _corsHeaders);
      case 'tone' || 'slow':
        if (!_authorized(request)) {
          return Response.unauthorized('', headers: _corsHeaders);
        }
        final slow = kind == 'slow';
        final ms = slow
            ? slowLength.inMilliseconds
            : int.tryParse(request.url.queryParameters['ms'] ?? '') ?? 3000;
        final tone = _tones[ms] ??= wav(Duration(milliseconds: ms));
        return _serve(request, tone, throttled: slow);
      default:
        return Response.notFound('', headers: _corsHeaders);
    }
  }

  bool _authorized(Request request) =>
      request.headers[keyHeader] == key ||
      request.url.queryParameters['token'] == key;

  Response _serve(Request request, Uint8List tone, {required bool throttled}) {
    final length = tone.length;
    final headers = {
      ..._corsHeaders,
      'content-type': 'audio/wav',
      'accept-ranges': 'bytes',
    };
    var start = 0;
    var end = length - 1;
    var status = 200;
    final range = request.headers['range'];
    if (range != null) {
      final match = RegExp(r'^bytes=(\d*)-(\d*)$').firstMatch(range.trim());
      final from = match?.group(1) ?? '';
      final to = match?.group(2) ?? '';
      if (match == null || (from.isEmpty && to.isEmpty)) {
        return _unsatisfiable(headers, length);
      }
      if (from.isEmpty) {
        start = math.max(0, length - int.parse(to));
      } else {
        start = int.parse(from);
        if (to.isNotEmpty) end = math.min(end, int.parse(to));
      }
      if (start >= length || start > end) {
        return _unsatisfiable(headers, length);
      }
      status = 206;
      headers['content-range'] = 'bytes $start-$end/$length';
    }
    headers['content-length'] = '${end - start + 1}';
    if (request.method == 'HEAD') return Response(status, headers: headers);
    final body = Uint8List.sublistView(tone, start, end + 1);
    return Response(
      status,
      headers: headers,
      body: throttled ? _throttle(body) : body,
    );
  }

  static Response _unsatisfiable(Map<String, String> headers, int length) =>
      Response(416, headers: {...headers, 'content-range': 'bytes */$length'});

  /// Sends [body] at twice real time: 100 ms of audio every 50 ms.
  static Stream<List<int>> _throttle(Uint8List body) async* {
    const chunk = sampleRate * 2 ~/ 10;
    for (var at = 0; at < body.length; at += chunk) {
      yield Uint8List.sublistView(body, at, math.min(at + chunk, body.length));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }
}
