// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/platform/secrets/secrets.dart';
import 'package:web/web.dart' as web;

/// Creates the web [SecretStore].
SecretStore createSecretStore() => WebSecretStore();

/// The web [SecretStore]: values live in memory and are mirrored to
/// `window.sessionStorage` under the same key, so a reload keeps the
/// session. Nothing is written to `localStorage`.
///
/// A new store loads the `sessionStorage` entries whose key starts with
/// `p/`. When `sessionStorage` is unavailable or throws, the store keeps
/// working from memory.
final class WebSecretStore implements SecretStore {
  /// Creates the store and loads the existing `p/` entries.
  new() {
    _mirror((storage) {
      for (var i = 0; i < storage.length; i++) {
        final key = storage.key(i);
        if (key == null || !key.startsWith(_prefix)) continue;
        final value = storage.getItem(key);
        if (value != null) _values[key] = value;
      }
    });
  }

  static const _prefix = 'p/';

  final _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
    _mirror((storage) => storage.setItem(key, value));
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
    _mirror((storage) => storage.removeItem(key));
  }

  static void _mirror(void Function(web.Storage storage) action) {
    try {
      action(web.window.sessionStorage);
    } on Object {
      // Storage is blocked or full: memory stays the source of truth.
    }
  }
}
