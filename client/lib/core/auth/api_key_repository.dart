// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:soundspan_api/soundspan_api.dart';

/// Builds a one-off [SoundspanApi] for [config]: anonymous when [apiKey] is
/// null, else authenticated with that key as `X-API-Key`.
typedef KeyedApiFactory = SoundspanApi Function(
  ApiConfig config,
  String? apiKey,
);

/// The default [KeyedApiFactory], over the platform's HTTP adapter.
SoundspanApi keyedApi(ApiConfig config, String? apiKey) => apiKey == null
    ? SoundspanApi.anonymous(
        config.baseUrl,
        userAgent: config.userAgent,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
      )
    : SoundspanApi(config, credentials: _FixedApiKey(apiKey));

/// One of the signed-in user's API keys, as `GET /api/api-keys` lists it.
@immutable
final class ApiKeyInfo {
  /// Creates the entry.
  const new({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.expiresAt,
  });

  /// The server's id of the key.
  final String id;

  /// The name the key was created with (a device-link key: the device name).
  final String name;

  /// When the key was issued, in UTC.
  final DateTime createdAt;

  /// When the key stops working, in UTC.
  final DateTime expiresAt;

  @override
  bool operator ==(Object other) =>
      other is ApiKeyInfo &&
      other.id == id &&
      other.name == name &&
      other.createdAt == createdAt &&
      other.expiresAt == expiresAt;

  @override
  int get hashCode => Object.hash(id, name, createdAt, expiresAt);

  @override
  String toString() => 'ApiKeyInfo($id, $name, $createdAt, $expiresAt)';
}

/// The API-key operations of a signed-in session (doc 03, Connection and
/// session): list the user's keys and revoke the key of this session.
class ApiKeyRepository {
  /// Creates the repository over [_api].
  const new(this._api);

  final SoundspanApi _api;

  /// The signed-in user's API keys, newest first.
  Future<List<ApiKeyInfo>> list() async {
    final response = await _api.send((rest) => rest.session.listApiKeys());
    return [
      for (final key in response.apiKeys)
        ApiKeyInfo(
          id: key.id,
          name: key.name,
          createdAt: key.createdAt.toUtc(),
          expiresAt: key.expiresAt.toUtc(),
        ),
    ];
  }

  /// Revokes the API key that authenticates this session
  /// (`DELETE /api/api-keys/current`).
  Future<void> revokeCurrent() async {
    await _api.send((rest) => rest.session.revokeCurrentApiKey());
  }

  /// Revokes [apiKey] on the server at [baseUrl] with a one-off client
  /// authenticated by that key, for a key that is no longer a profile's
  /// credential (doc 04, API-Key Expiry).
  ///
  /// Gives up after [timeout] with an [Offline]; any other failure
  /// propagates as its `ApiException`. [apis] builds the client.
  static Future<void> revokeWith({
    required Uri baseUrl,
    required String apiKey,
    Duration timeout = const Duration(seconds: 5),
    String userAgent = 'soundspan-client',
    KeyedApiFactory apis = keyedApi,
  }) async {
    final api = apis(
      ApiConfig(
        baseUrl: baseUrl,
        userAgent: userAgent,
        connectTimeout: timeout,
        receiveTimeout: timeout,
      ),
      apiKey,
    );
    try {
      await ApiKeyRepository(api)
          .revokeCurrent()
          .timeout(timeout, onTimeout: () => throw const Offline());
    } finally {
      api.close();
    }
  }
}

/// A [CredentialProvider] that always sends one API key and never rotates
/// or forgets it; the caller handles a rejection.
final class _FixedApiKey implements CredentialProvider {
  new(String apiKey) : current = ApiKeyCredentials(apiKey: apiKey);

  @override
  final Credentials current;

  @override
  Future<void> onTokensRotated(JwtCredentials next) async {}

  @override
  void onUnauthenticated(UnauthenticatedReason reason) {}
}
