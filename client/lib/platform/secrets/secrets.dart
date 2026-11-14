// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The secrets seam: where tokens and API keys are kept (doc 04, Secret
/// Storage).
///
/// `createSecretStore()` returns the OS secure storage on native targets, or
/// on web a store in memory mirrored to `sessionStorage`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'secrets_web.dart'
    if (dart.library.io) 'secrets_io.dart'
    show createSecretStore;

/// Keeps secrets by key.
abstract interface class SecretStore {
  /// The value stored under [key], or null when there is none.
  Future<String?> read(String key);

  /// Stores [value] under [key], replacing any earlier value.
  Future<void> write(String key, String value);

  /// Removes [key]; a key that does not exist is not an error.
  Future<void> delete(String key);
}

/// The platform cannot store secrets, for example Linux without a Secret
/// Service provider. There is no unencrypted fallback.
class SecretStoreUnavailable implements Exception {
  /// Creates the exception, with the platform's [message] when it gave one.
  const new([this.message]);

  /// What the platform reported.
  final String? message;

  @override
  String toString() => message == null
      ? 'SecretStoreUnavailable'
      : 'SecretStoreUnavailable: $message';
}

/// The app's [SecretStore]. Bootstrap overrides it (doc 02, Platform Seams).
final Provider<SecretStore> secretStoreProvider = Provider<SecretStore>(
  (ref) => throw UnimplementedError('secretStoreProvider is set by bootstrap'),
);
