// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/platform/stream_auth/stream_auth.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// The [StreamAuth] of native targets.
StreamAuth currentStreamAuth() => const HeaderStreamAuth();

/// Native players: the URI is unchanged and the credential travels as
/// `Authorization: Bearer` or `X-API-Key`.
final class HeaderStreamAuth implements StreamAuth {
  /// Creates the header strategy.
  const new();

  @override
  ({Uri uri, Map<String, String> headers}) apply(
    Uri uri,
    Credentials credentials,
  ) => (uri: uri, headers: authHeaders(credentials));
}
