// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// The login call of [PasswordSignIn]: `POST /api/auth/login` on an
/// anonymous session client.
abstract interface class LoginClient {
  /// Sends [request] to `POST /api/auth/login`.
  Future<LoginResponse200> login(LoginRequest request);

  /// Releases the connection.
  void close();
}

/// Creates the [LoginClient] of a server's base URL.
typedef LoginClientFactory = LoginClient Function(Uri baseUrl);

/// The default [LoginClientFactory]: the generated session client of a
/// [SoundspanApi.anonymous].
LoginClient anonymousLoginClient(Uri baseUrl) =>
    _AnonymousLoginClient(SoundspanApi.anonymous(baseUrl));

class _AnonymousLoginClient implements LoginClient {
  new(this._api);

  final SoundspanApi _api;

  @override
  Future<LoginResponse200> login(LoginRequest request) =>
      _api.send((rest) => rest.session.login(body: request));

  @override
  void close() => _api.close();
}

/// What a [PasswordSignIn.submit] ended in (doc 04, Password).
@immutable
sealed class PasswordSignInResult {
  const new();
}

/// 200 with tokens: the user is signed in.
final class SignInSignedIn extends PasswordSignInResult {
  /// Creates the result.
  const new({required this.user, required this.credentials});

  /// The signed-in user.
  final LoginUser user;

  /// The session's access and refresh tokens.
  final JwtCredentials credentials;
}

/// 200 `{ requires2FA: true }`: the account wants a second factor.
final class SignInNeedsCode extends PasswordSignInResult {
  /// Creates the result.
  const new();
}

/// 401 on the first step: wrong user name or password.
final class SignInInvalidCredentials extends PasswordSignInResult {
  /// Creates the result.
  const new();
}

/// 401 on the code step: wrong authenticator or recovery code.
final class SignInInvalidCode extends PasswordSignInResult {
  /// Creates the result.
  const new();
}

/// 403: the server no longer offers password sign-in.
final class SignInLocalLoginDisabled extends PasswordSignInResult {
  /// Creates the result.
  const new();
}

/// 429: too many attempts; try again after [retryAfter].
final class SignInRateLimited extends PasswordSignInResult {
  /// Creates the result.
  const new(this.retryAfter);

  /// The server's `Retry-After`.
  final Duration retryAfter;
}

/// Anything else: the server could not be reached or failed.
final class SignInFailed extends PasswordSignInResult {
  /// Creates the result.
  const new(this.error);

  /// What the call threw.
  final ApiException error;
}

/// Signs in with a user name and password, and a second-factor code when
/// the account has one (doc 04, Password).
class PasswordSignIn {
  /// Creates the use case over [_clients].
  const new(this._clients);

  final LoginClientFactory _clients;

  /// Sends the login of [username] and [password] to [baseUrl]; [code], the
  /// authenticator or recovery code, is sent as `token` on the code step.
  Future<PasswordSignInResult> submit({
    required Uri baseUrl,
    required String username,
    required String password,
    String? code,
  }) async {
    final client = _clients(baseUrl);
    try {
      final response = await client.login(
        LoginRequest(username: username, password: password, token: code),
      );
      return switch (response) {
        LoginTokenResponse(:final token, :final refreshToken, :final user) =>
          SignInSignedIn(
            user: user,
            credentials: JwtCredentials(
              accessToken: token,
              refreshToken: refreshToken,
            ),
          ),
        LoginTwoFactorChallenge() => const SignInNeedsCode(),
      };
    } on Unauthenticated {
      return code == null
          ? const SignInInvalidCredentials()
          : const SignInInvalidCode();
    } on Forbidden {
      return const SignInLocalLoginDisabled();
    } on RateLimited catch (error) {
      return SignInRateLimited(error.retryAfter);
    } on ApiException catch (error) {
      return SignInFailed(error);
    } finally {
      client.close();
    }
  }
}

/// The app's [PasswordSignIn] over anonymous session clients.
final Provider<PasswordSignIn> passwordSignInProvider =
    Provider<PasswordSignIn>(
      (ref) => const PasswordSignIn(anonymousLoginClient),
    );
