// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/platform/stream_auth/stream_auth.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// The [StreamAuth] of the web app.
StreamAuth currentStreamAuth() => const QueryTokenStreamAuth();

/// The web app: the access token goes into the `token` query parameter and
/// no headers are sent, because an `<audio>` element cannot send them.
final class QueryTokenStreamAuth implements StreamAuth {
  /// Creates the query-token strategy.
  const new();

  /// Throws [UnsupportedError] for an API key, which the web app never
  /// holds (`PlatformCapabilities.supportsApiKeyStreaming` is false there).
  @override
  ({Uri uri, Map<String, String> headers}) apply(
    Uri uri,
    Credentials credentials,
  ) => switch (credentials) {
    final JwtCredentials jwt => (
      uri: withQueryToken(uri, jwt),
      headers: const <String, String>{},
    ),
    ApiKeyCredentials() => throw UnsupportedError(
      'API keys cannot authorize streams on web',
    ),
  };
}
