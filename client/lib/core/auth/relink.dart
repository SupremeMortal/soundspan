// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/auth/api_key_repository.dart';
import 'package:soundspan/core/auth/device_link_code.dart';
import 'package:soundspan/core/auth/device_link_sign_in.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/auth/profile_repository.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// "Link again" (doc 04, API-Key Expiry): replaces a device-linked
/// profile's API key with a new one from a device-link code, then revokes
/// the old key with the old key itself (P6).
///
/// The profile's cache, downloads and outbox are never touched. Neither key
/// is logged or part of an exception.
class RelinkUseCase {
  /// Creates the use case. `apis` builds the one-off client of the revoke
  /// call, which gives up after `revokeTimeout` (5 s).
  new({
    required this._profiles,
    required this._signIn,
    required this._userAgent,
    this._apis = keyedApi,
    this._revokeTimeout = const Duration(seconds: 5),
  });

  static final AppLogger _log = AppLogger.scope('Relink');

  final ProfileRepository _profiles;
  final DeviceLinkSignIn _signIn;
  final String _userAgent;
  final KeyedApiFactory _apis;
  final Duration _revokeTimeout;

  /// Links [profile]'s server again with [code] under [deviceName] and
  /// returns the signed-in profile.
  ///
  /// When the code belongs to another user of the server, that user's
  /// profile is signed in and returned instead, and [profile] and its key
  /// are left untouched. Otherwise [profile] takes the new key and dates
  /// and becomes active, also when it was signed out. A failure of the
  /// device-link sign-in propagates and leaves the old key in place; a
  /// failure to revoke the old key is logged and ignored.
  Future<Profile> run(
    Profile profile,
    DeviceLinkCode code,
    String deviceName,
  ) async {
    var oldKey = switch (await _profiles.readCredentials(profile.id)) {
      ApiKeyCredentials(:final apiKey) => apiKey,
      _ => null,
    };
    final linked = await _signIn.submit(
      baseUrl: profile.baseUrl,
      code: code,
      deviceName: deviceName,
    );
    if (linked.id != profile.id) {
      _log.info('Re-link signed in another user', {'profileId': linked.id});
      return linked;
    }
    final newKey = switch (await _profiles.readCredentials(profile.id)) {
      ApiKeyCredentials(:final apiKey) => apiKey,
      _ => null,
    };
    if (oldKey != null && oldKey != newKey) {
      await _revoke(profile.baseUrl, oldKey, profile.id);
    }
    oldKey = null;
    _log.info('Device linked again', {'profileId': profile.id});
    return linked;
  }

  Future<void> _revoke(Uri baseUrl, String oldKey, String profileId) async {
    try {
      await ApiKeyRepository.revokeWith(
        baseUrl: baseUrl,
        apiKey: oldKey,
        timeout: _revokeTimeout,
        userAgent: _userAgent,
        apis: _apis,
      );
    } on Object catch (error) {
      // The old key expires on its own; the error carries no key.
      _log.warning('Could not revoke the old key', {
        'profileId': profileId,
        'error': error.runtimeType.toString(),
      });
    }
  }
}
