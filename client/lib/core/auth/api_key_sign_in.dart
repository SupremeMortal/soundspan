// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart' show immutable;
import 'package:soundspan/core/auth/api_key_repository.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/auth/profile_repository.dart';
import 'package:soundspan/core/auth/server_admission.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// Why a pasted API key was not accepted (doc 04, Pasted API Key).
@immutable
sealed class ApiKeyFailure implements Exception {
  const new();

  /// The input is empty, too long, or not printable ASCII; nothing was
  /// sent.
  const factory malformed() = ApiKeyMalformed;

  /// The server answered 401 or 403 to the key.
  const factory rejected() = ApiKeyRejected;

  /// 429: try again after [retryAfter].
  const factory rateLimited(Duration retryAfter) = ApiKeyRateLimited;
}

/// The input cannot be an API key.
final class ApiKeyMalformed extends ApiKeyFailure {
  /// Creates the failure.
  const new();

  @override
  String toString() => 'ApiKeyFailure.malformed';
}

/// The server does not accept the key.
final class ApiKeyRejected extends ApiKeyFailure {
  /// Creates the failure.
  const new();

  @override
  String toString() => 'ApiKeyFailure.rejected';
}

/// 429.
final class ApiKeyRateLimited extends ApiKeyFailure {
  /// Creates the failure.
  const new(this.retryAfter);

  /// The server's `Retry-After`.
  final Duration retryAfter;

  @override
  String toString() => 'ApiKeyFailure.rateLimited($retryAfter)';
}

/// Signs in with an API key the user pasted from the web UI (doc 04,
/// Pasted API Key).
///
/// The key is never logged and never part of an exception.
class ApiKeySignIn {
  /// Creates the use case. `apis` builds the one-off client of the calls
  /// made with the key.
  new({
    required this._profiles,
    required this._admission,
    required this._clock,
    required this._userAgent,
    this._apis = keyedApi,
  });

  /// The longest input accepted, after whitespace is removed.
  static const maxLength = 256;

  static final AppLogger _log = AppLogger.scope('ApiKey');
  static final RegExp _whitespace = RegExp(r'\s+');

  final ProfileRepository _profiles;
  final ServerAdmission _admission;
  final Clock _clock;
  final String _userAgent;
  final KeyedApiFactory _apis;

  /// [input] without any whitespace, or null when what is left is empty,
  /// longer than [maxLength] or has a character outside printable ASCII.
  /// The server decides everything else about the key.
  static String? normalize(String input) {
    final key = input.replaceAll(_whitespace, '');
    if (key.isEmpty || key.length > maxLength) return null;
    for (final unit in key.codeUnits) {
      if (unit < 0x21 || unit > 0x7e) return null;
    }
    return key;
  }

  /// Validates [apiKey] at [baseUrl] with `GET /api/auth/me` and stores the
  /// profile: created with `authKind = apiKey`, or the credential of the
  /// existing profile of the same `(baseUrl, userId)` replaced.
  ///
  /// The key's expiry is unknown: a pasted key carries no name to find it
  /// by in `GET /api/api-keys`, so `credentialExpiresAt` is null and the
  /// app asks for a new sign-in when the server stops accepting the key.
  /// The [ServerAdmission] runs before anything is stored, so a server
  /// below the minimum leaves no profile and no secret behind.
  ///
  /// Throws an [ApiKeyFailure], [ServerTooOld] for a server below the
  /// minimum, and any other [ApiException] unchanged.
  Future<Profile> submit({required Uri baseUrl, required String apiKey}) async {
    final key = normalize(apiKey);
    if (key == null) throw const ApiKeyFailure.malformed();
    final api = _apis(ApiConfig(baseUrl: baseUrl, userAgent: _userAgent), key);
    try {
      final me = await _me(api);
      final server = await _admission.check(api);
      final profile = await _profiles.upsertSignedIn(
        baseUrl: baseUrl,
        userId: me.id,
        username: me.username,
        userDisplayName: me.displayName,
        role: me.role.toJson(),
        authKind: AuthKind.apiKey,
        credentials: ApiKeyCredentials(apiKey: key),
        credentialCreatedAt: _clock.now(),
      );
      if (server.fetchedAt != null) {
        await _profiles.updateServerInfo(
          profile.id,
          serverVersion: server.serverVersion,
          features: server.features,
          featuresFetchedAt: server.fetchedAt,
        );
      }
      _log.info('Signed in with an API key', {'profileId': profile.id});
      return (await _profiles.byId(profile.id))!;
    } on ServerTooOld catch (error) {
      _log.warning('API key sign-in refused: server too old', {
        'serverVersion': error.serverVersion,
      });
      rethrow;
    } finally {
      api.close();
    }
  }

  Future<LoginUser> _me(SoundspanApi api) async {
    try {
      return await api.send((rest) => rest.session.getCurrentUser());
    } on Unauthenticated {
      throw const ApiKeyFailure.rejected();
    } on Forbidden {
      throw const ApiKeyFailure.rejected();
    } on RateLimited catch (error) {
      throw ApiKeyFailure.rateLimited(error.retryAfter);
    } on ApiException catch (error) {
      _log.warning('API key sign-in failed', {'error': error.toString()});
      rethrow;
    }
  }
}
