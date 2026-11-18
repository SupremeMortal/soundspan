// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:soundspan/platform/secrets/secrets.dart';

/// Creates the native [SecretStore].
SecretStore createSecretStore() => IoSecretStore();

/// The native [SecretStore]: `flutter_secure_storage` with the options of
/// doc 04.
///
/// - Android: the plugin's default AES-GCM storage with RSA-OAEP key
///   wrapping in the Android Keystore, which replaced
///   `encryptedSharedPreferences`.
/// - iOS and macOS: keychain items readable after the first unlock, never
///   synchronised or migrated to another device.
/// - Linux: libsecret (Secret Service). Windows: Credential Manager.
///
/// A [PlatformException] from the plugin is rethrown as
/// [SecretStoreUnavailable].
final class IoSecretStore implements SecretStore {
  /// Creates the store over [storage], by default the plugin with the
  /// options above.
  new([FlutterSecureStorage? storage]) : _storage = storage ?? _defaultStorage;

  // Android, Linux and Windows use the plugin's default options.
  static const _defaultStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _guard(() => _storage.read(key: key));

  @override
  Future<void> write(String key, String value) =>
      _guard(() => _storage.write(key: key, value: value));

  @override
  Future<void> delete(String key) => _guard(() => _storage.delete(key: key));

  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PlatformException catch (error) {
      throw SecretStoreUnavailable(error.message ?? error.code);
    }
  }
}
