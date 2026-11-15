// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:soundspan/core/auth/api_key_repository.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// One request a [FakeDeviceLinkServer] received.
typedef FakeRequest = ({
  String method,
  String path,
  Map<String, Object?> headers,
  Object? body,
});

/// One answer: `status` with a JSON `body` and extra `headers`.
typedef FakeAnswer = ({
  int status,
  Object? body,
  Map<String, List<String>> headers,
});

/// A 200 answer with [body].
FakeAnswer ok(Object? body) => (status: 200, body: body, headers: const {});

/// An error answer: [status] with `{ error: message }` and [headers].
FakeAnswer error(
  int status,
  String message, {
  String? code,
  Map<String, List<String>> headers = const {},
}) =>
    (status: status, body: {'error': message, 'code': ?code}, headers: headers);

/// The key the default verify answer hands out.
const issuedKey =
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

/// A server for the device-link sign-in: verify, `/auth/me`, the API-key
/// list and revoke, and the capability refresh (version and features).
///
/// Every answer is keyed by `METHOD /path`; tests replace entries of
/// [answers]. When [hang] is set, every request waits forever.
class FakeDeviceLinkServer implements HttpClientAdapter {
  /// Starts with answers for a successful sign-in of user `user-1` at
  /// server version [version].
  new({String version = '2.6.1'}) {
    answers.addAll({
      'POST /api/device-link/verify': ok({
        'success': true,
        'apiKey': issuedKey,
        'userId': 'user-1',
        'username': 'ada',
      }),
      'GET /api/auth/me': ok({
        'id': 'user-1',
        'username': 'ada',
        'role': 'admin',
        'displayName': 'Ada L.',
      }),
      'GET /api/api-keys': ok({'apiKeys': <Object?>[]}),
      'DELETE /api/api-keys/current': ok({'message': 'API key revoked'}),
      'GET /api/system/features': ok({
        'audioAnalysis': true,
        'autoPlaylists': false,
        'discovery': true,
        'federation': false,
        'loudnessTargetLufs': -14,
        'vibeEmbeddings': true,
      }),
    });
    setVersion(version);
  }

  /// The answers by `METHOD /path`; anything missing is a 404.
  final Map<String, FakeAnswer> answers = {};

  /// Every request, in order.
  final List<FakeRequest> requests = [];

  /// Whether every request waits forever.
  bool hang = false;

  /// How many times the adapter was closed.
  int closed = 0;

  /// Sets the version `GET /api/docs.json` and `GET /api/health` report.
  void setVersion(String version) {
    answers['GET /api/docs.json'] = ok({
      'openapi': '3.1.0',
      'info': {'title': 'soundspan', 'version': version},
      'paths': <String, Object?>{},
    });
    answers['GET /api/health'] = ok({
      'status': 'ok',
      'draining': false,
      'startupComplete': true,
      'role': 'all',
      'uptimeSeconds': 1,
      'version': version,
    });
  }

  /// The requests to `METHOD /path`.
  List<FakeRequest> to(String key) =>
      requests.where((r) => '${r.method} ${r.path}' == key).toList();

  /// A [KeyedApiFactory] whose APIs talk to this server.
  SoundspanApi api(ApiConfig config, String? apiKey) => apiKey == null
      ? SoundspanApi.anonymous(config.baseUrl, adapter: this)
      : SoundspanApi(config, credentials: _Key(apiKey), adapter: this);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object? body;
    if (requestStream != null) {
      final bytes = await requestStream.expand((chunk) => chunk).toList();
      if (bytes.isNotEmpty) body = jsonDecode(utf8.decode(bytes));
    }
    final key = '${options.method} ${options.uri.path}';
    requests.add((
      method: options.method,
      path: options.uri.path,
      headers: Map.of(options.headers),
      body: body,
    ));
    if (hang) await Completer<void>().future;
    final answer = answers[key] ?? error(404, 'Not found');
    return ResponseBody.fromString(
      jsonEncode(answer.body),
      answer.status,
      headers: {
        'content-type': ['application/json'],
        ...answer.headers,
      },
    );
  }

  @override
  void close({bool force = false}) => closed++;
}

class _Key implements CredentialProvider {
  new(this._apiKey);

  final String _apiKey;

  @override
  Credentials? get current => ApiKeyCredentials(apiKey: _apiKey);

  @override
  Future<void> onTokensRotated(JwtCredentials next) async {}

  @override
  void onUnauthenticated(UnauthenticatedReason reason) {}
}
