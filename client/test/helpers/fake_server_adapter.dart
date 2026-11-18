// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// One answer of a [FakeServerAdapter]: `status` with a JSON `body`.
typedef FakeReply = ({int status, Object? body});

/// A server that answers the capability refresh: `/api/docs.json` with
/// [version] as `info.version`, `/api/system/features` with [features],
/// and `/api/health`. Each answer waits for [gate] when it is set; [fail]
/// makes every answer a 500.
class FakeServerAdapter implements HttpClientAdapter {
  /// Serves [version] and [features].
  new({this.version = '2.6.1', Map<String, Object?>? features})
    : features = features ?? defaultFeatures;

  /// The features a server reports when the test names none.
  static const Map<String, Object?> defaultFeatures = {
    'audioAnalysis': true,
    'autoPlaylists': false,
    'discovery': true,
    'federation': false,
    'loudnessTargetLufs': -14,
    'vibeEmbeddings': true,
  };

  /// The version the server reports; null leaves it out.
  String? version;

  /// The features the server reports.
  Map<String, Object?> features;

  /// When set, every answer waits for it.
  Completer<void>? gate;

  /// Whether every answer is a 500.
  bool fail = false;

  /// The paths requested, in order.
  final List<String> requested = [];

  /// Whether [close] was called.
  bool closed = false;

  /// How many requests reached [path].
  int count(String path) => requested.where((p) => p == path).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    requested.add(path);
    await gate?.future;
    final reply = _reply(path);
    return ResponseBody.fromString(
      jsonEncode(reply.body),
      reply.status,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  FakeReply _reply(String path) {
    if (fail) return (status: 500, body: {'error': 'boom'});
    return switch (path) {
      '/api/docs.json' => (
        status: 200,
        body: {
          'openapi': '3.1.0',
          'info': {'title': 'soundspan', 'version': ?version},
          'paths': <String, Object?>{},
        },
      ),
      '/api/system/features' => (status: 200, body: features),
      '/api/health' => (
        status: 200,
        body: {
          'status': 'ok',
          'draining': false,
          'startupComplete': true,
          'role': 'all',
          'uptimeSeconds': 1,
          'version': version ?? 'unknown',
        },
      ),
      _ => (status: 404, body: {'error': 'not found'}),
    };
  }

  @override
  void close({bool force = false}) => closed = true;
}
