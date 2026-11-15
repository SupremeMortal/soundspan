// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

import 'support/session_harness.dart';

const Map<String, Object?> _health = {
  'status': 'ok',
  'draining': false,
  'startupComplete': true,
  'role': 'all',
  'uptimeSeconds': 12,
  'version': '2.7.0',
};

const Map<String, Object?> _unknownHealth = {
  'status': 'ok',
  'draining': false,
  'startupComplete': true,
  'role': 'all',
  'uptimeSeconds': 12,
  'version': 'unknown',
};

/// Serves `/api/docs.json` as `document` in chunks of [chunkSize] bytes,
/// counting the chunks the client pulled; every other path goes to
/// `fallback`.
class _ChunkedDocs implements HttpClientAdapter {
  new(
    String document, {
    this.chunkSize = 7,
    this.docsStatus = 200,
    this.gap,
    FutureOr<Reply> Function(RequestOptions)? fallback,
  }) : _bytes = utf8.encode(document),
       _fallback = ScriptedServer(fallback ?? (_) => const HttpReply(404));

  final Uint8List _bytes;
  final int chunkSize;
  final int docsStatus;

  /// The time between two chunks, like a network delivering them; none
  /// when null.
  final Duration? gap;
  final ScriptedServer _fallback;

  /// Whether the client cancelled the request to `/api/docs.json`.
  bool cancelled = false;

  /// The chunks of the document the client pulled.
  int pulled = 0;

  /// The total number of chunks of the document.
  int get chunks => (_bytes.length / chunkSize).ceil();

  /// The requests to `/api/docs.json`.
  final List<RequestOptions> docsRequests = [];

  /// Every request that reached the fallback.
  List<RequestOptions> get others => _fallback.requests;

  Stream<Uint8List> _stream() async* {
    for (var start = 0; start < _bytes.length; start += chunkSize) {
      if (cancelled) return;
      final gap = this.gap;
      if (gap != null && start > 0) await Future<void>.delayed(gap);
      pulled++;
      final end = start + chunkSize > _bytes.length
          ? _bytes.length
          : start + chunkSize;
      yield Uint8List.sublistView(_bytes, start, end);
    }
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.uri.path != '/api/docs.json') {
      return await _fallback.fetch(options, requestStream, cancelFuture);
    }
    docsRequests.add(options);
    unawaited(cancelFuture?.then((_) => cancelled = true));
    if (docsStatus != 200) {
      return ResponseBody.fromString(
        'blocked',
        docsStatus,
        headers: {
          'content-type': ['text/plain'],
        },
      );
    }
    return ResponseBody(
      _stream(),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

SoundspanApi _api(HttpClientAdapter adapter) => SoundspanApi(
  ApiConfig(baseUrl: Uri.parse('https://h'), userAgent: 'test'),
  credentials: RecordingCredentials(const ApiKeyCredentials(apiKey: 'key-1')),
  adapter: adapter,
);

/// A large document whose `info.version` is [version], followed by many
/// paths.
String _document(String version, {String prefix = ''}) => jsonEncode({
  'openapi': '3.1.0',
  if (prefix.isNotEmpty) 'x-note': prefix,
  'info': {'title': 'soundspan', 'version': version},
  'paths': {
    for (var i = 0; i < 400; i++)
      '/api/path$i': {
        'get': {'operationId': 'op$i', 'summary': 'Operation number $i'},
      },
  },
});

void main() {
  group('fetchServerVersion', () {
    test(
      'reads info.version from a document delivered in small chunks',
      () async {
        final docs = _ChunkedDocs(_document('2.6.1'), chunkSize: 3);
        final api = _api(docs);
        expect(await api.fetchServerVersion(), '2.6.1');
        expect(docs.docsRequests.single.headers['Accept'], 'application/json');
        expect(docs.others, isEmpty);
      },
    );

    test('stops reading after info.version', () async {
      final docs = _ChunkedDocs(
        _document('2.6.1'),
        chunkSize: 16,
        gap: const Duration(milliseconds: 1),
      );
      final api = _api(docs);
      expect(await api.fetchServerVersion(), '2.6.1');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      // The version sits in the first chunks of a document of thousands; the
      // request is cancelled and the rest is never pulled.
      expect(docs.cancelled, isTrue);
      expect(docs.chunks, greaterThan(1000));
      expect(docs.pulled, lessThan(docs.chunks ~/ 4));
    });

    test('a version key outside info is ignored', () async {
      final document = jsonEncode({
        'version': '9.9.9',
        'components': {
          'schemas': {
            'X': {'version': '8.8.8'},
          },
        },
        'info': {
          'title': 't',
          'contact': {'version': '7.7.7'},
          'version': '2.6.2',
        },
      });
      final api = _api(_ChunkedDocs(document, chunkSize: 5));
      expect(await api.fetchServerVersion(), '2.6.2');
    });

    test(
      'escaped quotes in earlier strings do not confuse the scanner',
      () async {
        const document =
            r'{"x-note":"a \"quoted\" {info} \\","info\"":{"version":"1.0.0"}, '
            r'"tags":["\"info\":{\"version\":\"0.0.1\"}"],'
            r'"info":{"title":"say \"hi\" é","version":"2.6.3-rc.1"}}';
        expect(jsonDecode(document), isA<Map<String, Object?>>());
        final api = _api(_ChunkedDocs(document, chunkSize: 2));
        expect(await api.fetchServerVersion(), '2.6.3-rc.1');
      },
    );

    test('401, 403 and 404 fall back to /health', () async {
      for (final status in [401, 403, 404]) {
        final docs = _ChunkedDocs(
          '',
          docsStatus: status,
          fallback: (request) => request.uri.path == '/api/health'
              ? const HttpReply(200, _health)
              : const HttpReply(404),
        );
        final api = _api(docs);
        expect(await api.fetchServerVersion(), '2.7.0', reason: '$status');
        expect(docs.others.single.uri.path, '/api/health', reason: '$status');
      }
    });

    test('health version unknown gives null', () async {
      final docs = _ChunkedDocs(
        '',
        docsStatus: 404,
        fallback: (_) => const HttpReply(200, _unknownHealth),
      );
      expect(await _api(docs).fetchServerVersion(), isNull);
    });

    test('a missing info.version gives null', () async {
      final document = jsonEncode({
        'info': {'title': 't'},
        'paths': <String, Object?>{},
      });
      expect(await _api(_ChunkedDocs(document)).fetchServerVersion(), isNull);
    });

    test('a 500 propagates as ServerError', () async {
      final docs = _ChunkedDocs('', docsStatus: 500);
      await expectLater(
        _api(docs).fetchServerVersion(),
        throwsA(isA<ServerError>()),
      );
      expect(docs.others, isEmpty);
    });
  });
}
