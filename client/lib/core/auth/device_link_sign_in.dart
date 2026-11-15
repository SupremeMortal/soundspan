// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart' show immutable;
import 'package:soundspan/core/auth/api_key_repository.dart';
import 'package:soundspan/core/auth/device_link_code.dart';
import 'package:soundspan/core/auth/key_expiry_lookup.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/auth/profile_repository.dart';
import 'package:soundspan/core/auth/server_admission.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// Why the server turned a device-link code down (doc 04, Device Link).
@immutable
sealed class DeviceLinkFailure implements Exception {
  const new();

  /// 404 `Invalid code`: no such code.
  const factory invalidCode() = DeviceLinkInvalidCode;

  /// 400 `Code already used`.
  const factory codeUsed() = DeviceLinkCodeUsed;

  /// 400 `Code expired`.
  const factory codeExpired() = DeviceLinkCodeExpired;

  /// Any other 400, with the server's [message].
  const factory rejected(String? message) = DeviceLinkRejected;

  /// 429: try again after [retryAfter].
  const factory rateLimited(Duration retryAfter) = DeviceLinkRateLimited;
}

/// 404 `Invalid code`.
final class DeviceLinkInvalidCode extends DeviceLinkFailure {
  /// Creates the failure.
  const new();
}

/// 400 `Code already used`.
final class DeviceLinkCodeUsed extends DeviceLinkFailure {
  /// Creates the failure.
  const new();
}

/// 400 `Code expired`.
final class DeviceLinkCodeExpired extends DeviceLinkFailure {
  /// Creates the failure.
  const new();
}

/// Another 400.
final class DeviceLinkRejected extends DeviceLinkFailure {
  /// Creates the failure with the server's [message].
  const new(this.message);

  /// The server's `error` text, if it sent one.
  final String? message;

  @override
  String toString() => 'DeviceLinkFailure.rejected($message)';
}

/// 429.
final class DeviceLinkRateLimited extends DeviceLinkFailure {
  /// Creates the failure.
  const new(this.retryAfter);

  /// The server's `Retry-After`.
  final Duration retryAfter;

  @override
  String toString() => 'DeviceLinkFailure.rateLimited($retryAfter)';
}

/// Turns a device-link code into a signed-in profile (doc 04, Device Link).
///
/// The API key is never logged and never part of an exception.
class DeviceLinkSignIn {
  /// Creates the use case. `apis` builds the one-off clients of the verify
  /// call and of the calls made with the new key.
  new({
    required this._profiles,
    required this._admission,
    required this._clock,
    required this._userAgent,
    this._apis = keyedApi,
  });

  static final AppLogger _log = AppLogger.scope('DeviceLink');

  final ProfileRepository _profiles;
  final ServerAdmission _admission;
  final Clock _clock;
  final String _userAgent;
  final KeyedApiFactory _apis;

  /// Exchanges [code] for an API key named [deviceName] at [baseUrl] and
  /// stores the profile: created with `authKind = deviceLink`, or the
  /// credential of the existing profile of the same `(baseUrl, userId)`
  /// replaced.
  ///
  /// Before anything is stored it reads `GET /api/auth/me`, the key's dates
  /// ([KeyExpiryLookup]) and runs the [ServerAdmission], so a server below
  /// the minimum leaves no profile and no secret behind.
  ///
  /// Throws a [DeviceLinkFailure] for the answers of doc 04's error table,
  /// [ServerTooOld] for a server below the minimum, and any other
  /// [ApiException] unchanged.
  Future<Profile> submit({
    required Uri baseUrl,
    required DeviceLinkCode code,
    required String deviceName,
  }) async {
    final config = ApiConfig(baseUrl: baseUrl, userAgent: _userAgent);
    final verified = await _verify(config, code, deviceName);
    final api = _apis(config, verified.apiKey);
    try {
      final me = await api.send((rest) => rest.session.getCurrentUser());
      final dates = await KeyExpiryLookup(
        ApiKeyRepository(api),
        _clock,
      ).lookup(deviceName: deviceName);
      final server = await _admission.check(api);
      final profile = await _profiles.upsertSignedIn(
        baseUrl: baseUrl,
        userId: verified.userId,
        username: verified.username,
        userDisplayName: me.displayName,
        role: me.role.toJson(),
        authKind: AuthKind.deviceLink,
        credentials: ApiKeyCredentials(apiKey: verified.apiKey),
        credentialCreatedAt: dates.createdAt,
        credentialExpiresAt: dates.expiresAt,
      );
      if (server.fetchedAt != null) {
        await _profiles.updateServerInfo(
          profile.id,
          serverVersion: server.serverVersion,
          features: server.features,
          featuresFetchedAt: server.fetchedAt,
        );
      }
      _log.info('Device linked', {'profileId': profile.id});
      return (await _profiles.byId(profile.id))!;
    } on ServerTooOld catch (error) {
      _log.warning('Device link refused: server too old', {
        'serverVersion': error.serverVersion,
      });
      rethrow;
    } finally {
      api.close();
    }
  }

  Future<DeviceLinkVerifyResponse> _verify(
    ApiConfig config,
    DeviceLinkCode code,
    String deviceName,
  ) async {
    final api = _apis(config, null);
    try {
      return await api.send(
        (rest) => rest.session.verifyDeviceLink(
          body: DeviceLinkVerifyRequest(
            code: code.value,
            deviceName: deviceName,
          ),
        ),
      );
    } on NotFound catch (error) {
      if (error.serverMessage == 'Invalid code') {
        throw const DeviceLinkFailure.invalidCode();
      }
      _log.warning('Device link failed', {'error': error.toString()});
      rethrow;
    } on InvalidRequest catch (error) {
      if (error.status != 400) rethrow;
      throw switch (error.serverMessage) {
        'Code already used' => const DeviceLinkFailure.codeUsed(),
        'Code expired' => const DeviceLinkFailure.codeExpired(),
        final message => DeviceLinkFailure.rejected(message),
      };
    } on RateLimited catch (error) {
      throw DeviceLinkFailure.rateLimited(error.retryAfter);
    } on ApiException catch (error) {
      _log.warning('Device link failed', {'error': error.toString()});
      rethrow;
    } finally {
      api.close();
    }
  }
}
