// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The stream credentials seam: how a player authorizes a stream request
/// (doc 02, Platform Seams).
///
/// Native players send headers; a web `<audio>` element cannot, so on web
/// the access token goes into the `token` query parameter.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/platform/stream_auth/stream_auth_web.dart'
    if (dart.library.io) 'package:soundspan/platform/stream_auth/stream_auth_io.dart';
import 'package:soundspan_api/soundspan_api.dart';

export 'stream_auth_web.dart'
    if (dart.library.io) 'stream_auth_io.dart'
    show currentStreamAuth;

/// Turns a stream URI and a credential into what a player requests.
abstract interface class StreamAuth {
  /// Returns the URI and headers a player must use for [uri] with
  /// [credentials].
  ({Uri uri, Map<String, String> headers}) apply(
    Uri uri,
    Credentials credentials,
  );
}

/// The [StreamAuth] of the platform the app runs on.
final Provider<StreamAuth> streamAuthProvider = Provider<StreamAuth>(
  (ref) => currentStreamAuth(),
);
