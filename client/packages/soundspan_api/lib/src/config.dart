// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Server configuration and the credentials the transport sends.
library;

import 'package:meta/meta.dart';

/// How one `SoundspanApi` reaches its server.
@immutable
final class ApiConfig {
  /// Creates a configuration.
  ///
  /// Throws [ArgumentError] when [baseUrl] ends with a slash or carries a
  /// query or a fragment: the base URL is normalized before it gets here.
  new({
    required this.baseUrl,
    required this.userAgent,
    this.playbackDeviceId,
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 30),
  }) {
    if (baseUrl.path.endsWith('/')) {
      throw ArgumentError.value(baseUrl, 'baseUrl', 'ends with a slash');
    }
    if (baseUrl.hasQuery) {
      throw ArgumentError.value(baseUrl, 'baseUrl', 'has a query');
    }
    if (baseUrl.hasFragment) {
      throw ArgumentError.value(baseUrl, 'baseUrl', 'has a fragment');
    }
  }

  /// The server's address, which may contain a path prefix
  /// (`https://example.com/soundspan`). It never ends with a slash.
  final Uri baseUrl;

  /// Sent as `User-Agent` on native targets:
  /// `soundspan-client/<version> (<os>)`.
  final String userAgent;

  /// Sent as `X-Playback-Device-Id` when set.
  final String? playbackDeviceId;

  /// How long establishing a connection may take.
  final Duration connectTimeout;

  /// How long receiving a JSON response may take.
  final Duration receiveTimeout;
}

/// A credential the server accepts.
@immutable
sealed class Credentials {
  const new();
}

/// A JWT session: a short-lived access token and the refresh token that
/// renews it.
final class JwtCredentials extends Credentials {
  /// Creates a JWT session credential.
  const new({required this.accessToken, required this.refreshToken});

  /// Sent as `Authorization: Bearer <accessToken>`.
  final String accessToken;

  /// Exchanged for a new token pair at `/auth/refresh`.
  final String refreshToken;

  @override
  String toString() => 'JwtCredentials(<redacted>)';
}

/// A device-link API key.
final class ApiKeyCredentials extends Credentials {
  /// Creates an API key credential.
  const new({required this.apiKey});

  /// Sent as `X-API-Key`.
  final String apiKey;

  @override
  String toString() => 'ApiKeyCredentials(<redacted>)';
}

/// Why the server rejected a credential permanently.
enum UnauthenticatedReason {
  /// The JWT session can no longer be refreshed.
  sessionExpired,

  /// The server rejected the API key.
  keyRejected,
}

/// Implemented by the app (`SessionController`). The package never stores
/// secrets.
abstract interface class CredentialProvider {
  /// The credential to send, or null when signed out.
  Credentials? get current;

  /// Persist rotated tokens. Must complete before the returned future
  /// resolves.
  Future<void> onTokensRotated(JwtCredentials next);

  /// Called once when the server rejects the credential permanently.
  void onUnauthenticated(UnauthenticatedReason reason);
}
