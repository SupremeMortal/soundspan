// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:soundspan_api/soundspan_api.dart';

import 'harness.dart';

/// One scripted answer of a [ScriptedServer].
sealed class Reply {
  const new();
}

/// An HTTP response.
final class HttpReply extends Reply {
  /// A response with [status], a JSON or plain-text [body] and [headers].
  const new(this.status, [this.body, this.headers = const {}]);

  /// The status code.
  final int status;

  /// A JSON value, or a [String] sent as plain text.
  final Object? body;

  /// Extra response headers.
  final Map<String, String> headers;
}

/// A connection failure: no response arrives.
final class NetworkFailure extends Reply {
  /// Creates the failure.
  const new();
}

/// Decides the reply to one request; may complete later.
typedef Route = FutureOr<Reply> Function(RequestOptions request);

/// An [HttpClientAdapter] that answers with [route] and records every
/// request that reached it, in order.
class ScriptedServer implements HttpClientAdapter {
  /// Serves [route].
  new(this.route);

  /// Decides each reply.
  Route route;

  /// Every request that reached the server.
  final List<RequestOptions> requests = [];

  /// Requests to [path] (relative to the API root).
  List<RequestOptions> to(String path) =>
      requests.where((r) => r.uri.path == '/api$path').toList();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final reply = await route(options);
    switch (reply) {
      case NetworkFailure():
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'scripted network failure',
        );
      case HttpReply(:final status, :final body, :final headers):
        final text = body is String ? body : jsonEncode(body);
        final type = body is String ? 'text/plain' : 'application/json';
        return ResponseBody.fromString(
          text,
          status,
          headers: {
            'content-type': [type],
            for (final MapEntry(:key, :value) in headers.entries) key: [value],
          },
        );
    }
  }

  @override
  void close({bool force = false}) {}
}

/// A [CredentialProvider] that records every callback in [events].
class RecordingCredentials implements CredentialProvider {
  /// Starts with [current].
  new(this.current);

  @override
  Credentials? current;

  /// `rotated:<accessToken>` and `unauthenticated:<reason>`, in order.
  final List<String> events = [];

  /// Completes [onTokensRotated] when set; otherwise it completes at once.
  Completer<void>? rotationGate;

  @override
  Future<void> onTokensRotated(JwtCredentials next) async {
    await rotationGate?.future;
    current = next;
    events.add('rotated:${next.accessToken}');
  }

  @override
  void onUnauthenticated(UnauthenticatedReason reason) {
    events.add('unauthenticated:${reason.name}');
  }
}

/// A JWT whose payload holds [iat] and [exp] (seconds since the epoch).
String jwt({int? iat, int? exp, String tag = 'a'}) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return [
    part({'alg': 'HS256', 'typ': 'JWT'}),
    part({'iat': ?iat, 'exp': ?exp, 'tag': tag}),
    'signature',
  ].join('.');
}

/// A [createDio] Dio over a [ScriptedServer], with a fake clock, a delay
/// that records its durations and completes at once, and a seeded random.
class SessionHarness {
  /// Builds the Dio. [nowSeconds] is the fake clock's reading.
  new({this.credentials, Route? route, this.nowSeconds = 1000})
    : server = ScriptedServer(route ?? (_) => const HttpReply(200, {})) {
    dio = createDio(
      ApiConfig(baseUrl: Uri.parse(testBase), userAgent: 'ua'),
      credentials: credentials,
      adapter: server,
      now: () => DateTime.fromMillisecondsSinceEpoch(nowSeconds * 1000),
      delay: (duration) async => delays.add(duration),
      random: Random(7),
    );
  }

  /// The credential provider, if any.
  final CredentialProvider? credentials;

  /// The scripted server behind [dio].
  final ScriptedServer server;

  /// The Dio under test.
  late final Dio dio;

  /// What the fake clock reads, in seconds since the epoch.
  int nowSeconds;

  /// Every backoff the interceptors asked for, in order.
  final List<Duration> delays = [];

  /// Sends `GET /library/albums`.
  Future<Response<dynamic>> get([String path = '/library/albums']) =>
      dio.get<dynamic>(path);
}

/// The `Authorization` header of [request].
String? bearerOf(RequestOptions request) =>
    request.headers['Authorization'] as String?;
