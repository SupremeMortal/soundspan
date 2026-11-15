// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Scrubbing, encoding and the step model of `tool/capture_fixtures.dart`.
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:soundspan_api/soundspan_api.dart';

import '../../test/support.dart';

/// What every value under a secret key becomes.
const redacted = '<redacted>';

/// What every value under an `email` key becomes.
const scrubbedEmail = 'user@example.invalid';

/// The keys whose values become [redacted], at any depth.
const redactedKeys = {
  'token',
  'refreshToken',
  'apiKey',
  'secret',
  'password',
  'passwordHash',
};

/// Returns [json] with every value under a key of [redactedKeys] replaced by
/// [redacted], every value under `email` replaced by [scrubbedEmail], and
/// the keys of every object sorted, at any depth. Scrubbing a scrubbed value
/// returns an equal value.
Object? scrub(Object? json) => switch (json) {
  final Map<String, Object?> object => {
    for (final key in object.keys.toList()..sort())
      key: redactedKeys.contains(key)
          ? redacted
          : key == 'email'
          ? scrubbedEmail
          : scrub(object[key]),
  },
  final List<Object?> array => [for (final element in array) scrub(element)],
  _ => json,
};

/// Encodes [json] as a fixture file: two-space indentation, object keys
/// sorted at every depth, and a trailing newline.
String encodeFixture(Object? json) =>
    '${const JsonEncoder.withIndent('  ').convert(_sortKeys(json))}\n';

Object? _sortKeys(Object? json) => switch (json) {
  final Map<String, Object?> object => {
    for (final key in object.keys.toList()..sort()) key: _sortKeys(object[key]),
  },
  final List<Object?> array => [
    for (final element in array) _sortKeys(element),
  ],
  _ => json,
};

/// Sends the request of one [CaptureStep] and returns its response, whose
/// body is the raw text the server sent.
typedef CaptureRequest = Future<Response<String>> Function(CaptureContext c);

/// One captured response: the operation it belongs to, the response shape
/// ([variant]) when the operation has more than one, and how to request it.
final class CaptureStep {
  /// Creates a step.
  const new(this.operationId, this.request, {this.variant});

  /// The `operationId` in the client-surface spec.
  final String operationId;

  /// The response shape, for an operation with more than one.
  final String? variant;

  /// Sends the request whose response becomes the fixture.
  final CaptureRequest request;

  /// `<operationId>[.<variant>].json`.
  String get fileName =>
      variant == null ? '$operationId.json' : '$operationId.$variant.json';
}

/// The connections capture steps send requests with, and values steps leave
/// for later steps.
///
/// Every connection is a Dio built by `createDio` (base-URL guard and
/// credential interceptors included) that returns bodies as plain text, so
/// nothing is decoded before the body is written.
final class CaptureContext {
  /// Creates a context over the seeded [credentials].
  new({required this.credentials, required this.adapter});

  /// The seed's credentials.
  final ContractCredentials credentials;

  /// Makes the HTTP adapter of each new connection.
  final HttpClientAdapter Function() adapter;

  /// Values one step leaves for a later one (ids it created or looked up).
  final values = <String, Object?>{};

  final _opened = <Dio>[];

  /// A connection without a credential.
  late final Dio anonymous = _open(null);

  /// The listener's signed-in connection, shared by every step; set by
  /// [signIn].
  late final Dio listener;

  /// The admin's signed-in connection, shared by every step; set by
  /// [signIn].
  late final Dio admin;

  /// Signs the listener and the admin in for [listener] and [admin].
  Future<void> signIn() async {
    listener = await freshSession(credentials.listener);
    admin = await freshSession(credentials.admin);
  }

  /// Signs [account] in with a new session of its own and returns the login
  /// body.
  Future<Map<String, Object?>> logIn(ContractAccount account) async {
    final response = await anonymous.post<String>(
      '/auth/login',
      data: {'username': account.username, 'password': account.password},
    );
    final body = decode(response);
    if (body is! Map<String, Object?> || body['token'] is! String) {
      throw StateError('${account.username} did not receive a session');
    }
    return body;
  }

  /// A connection carrying a new session of [account], not shared with any
  /// other step (for operations that end the session).
  Future<Dio> freshSession(ContractAccount account) async {
    final login = await logIn(account);
    return _open(
      _FixedCredentials(
        JwtCredentials(
          accessToken: login['token']! as String,
          refreshToken: login['refreshToken']! as String,
        ),
      ),
    );
  }

  /// A connection that sends [apiKey] as `X-API-Key`.
  Dio apiKeySession(String apiKey) =>
      _open(_FixedCredentials(ApiKeyCredentials(apiKey: apiKey)));

  /// Decodes the JSON body of [response].
  Object? decode(Response<String> response) => jsonDecode(response.data ?? '');

  /// Closes every connection.
  void close() {
    for (final dio in _opened) {
      dio.close(force: true);
    }
  }

  Dio _open(CredentialProvider? provider) {
    final dio = createDio(
      ApiConfig(
        baseUrl: credentials.baseUrl,
        userAgent: 'soundspan-capture-fixtures',
      ),
      credentials: provider,
      adapter: adapter(),
    )..options.responseType = ResponseType.plain;
    _opened.add(dio);
    return dio;
  }
}

/// A credential provider holding one session that never rotates.
final class _FixedCredentials implements CredentialProvider {
  new(this.current);

  @override
  Credentials? current;

  @override
  Future<void> onTokensRotated(JwtCredentials next) async => current = next;

  @override
  void onUnauthenticated(UnauthenticatedReason reason) => current = null;
}
