// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Contract group "Connection and session" of doc 03's endpoint inventory.
@Tags(['contract'])
library;

import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

import 'support.dart';
import 'support/totp.dart';

/// [token] with the first character of its signature changed, so the
/// server rejects it while its claims still decode. (The last character of
/// a base64url signature carries padding bits a decoder may ignore.)
String _tamper(String token) {
  final at = token.lastIndexOf('.') + 1;
  final replacement = token[at] == 'A' ? 'B' : 'A';
  return token.replaceRange(at, at + 1, replacement);
}

Matcher _unauthenticated({String? code}) => throwsA(
  isA<Unauthenticated>()
      .having((e) => e.status, 'status', 401)
      .having((e) => e.code, 'code', code),
);

void main() {
  late ContractCredentials credentials;

  setUp(() => credentials = ContractCredentials.load());

  group('anonymous operations', () {
    test('health answers without a credential and decodes', () async {
      final health = await anonymousApi(credentials)
          .send((rest) => rest.session.getHealth());

      expect(health.status, isNotEmpty);
      expect(health.startupComplete, isTrue);
      expect(health.version, isNotEmpty);
    });

    test(
      'auth config answers without a credential and offers local login',
      () async {
        final config = await anonymousApi(credentials)
            .send((rest) => rest.session.getAuthConfig());

        expect(config.localLoginEnabled, isTrue);
        expect(config.oidcEnabled, isA<bool>());
      },
    );

    test('onboarding status answers without a credential and reports that an '
        'account exists', () async {
      final status = await anonymousApi(credentials)
          .send((rest) => rest.session.getOnboardingStatus());

      expect(status.hasAccount, isTrue);
      expect(status.needsOnboarding, isFalse);
    });
  });

  group('login', () {
    test('with the right password returns both tokens and the user', () async {
      final login = await logIn(credentials, credentials.listener);

      expect(login.token, isNotEmpty);
      expect(login.refreshToken, isNotEmpty);
      expect(login.user.id, isNotEmpty);
      expect(login.user.username, credentials.listener.username);
      expect(login.user.role, LoginUserRole.user);
    });

    test('of the admin reports the admin role', () async {
      final login = await logIn(credentials, credentials.admin);

      expect(login.user.role, LoginUserRole.admin);
    });

    test('with a wrong password throws Unauthenticated', () async {
      final api = anonymousApi(credentials);

      await expectLater(
        api.send(
          (rest) => rest.session.login(
            body: LoginRequest(
              username: credentials.listener.username,
              password: '${credentials.listener.password}-wrong',
            ),
          ),
        ),
        _unauthenticated(),
      );
    });
  });

  group('me', () {
    test('with the access token returns the signed-in user', () async {
      final login = await logIn(credentials, credentials.listener);
      final api = await signedInApi(credentials, credentials.listener);

      final me = await api.send((rest) => rest.session.getCurrentUser());

      expect(me.id, login.user.id);
      expect(me.username, credentials.listener.username);
      expect(me.role, LoginUserRole.user);
    });

    test(
      'without a credential throws Unauthenticated with AUTH_REQUIRED',
      () async {
        final provider = InMemoryCredentialProvider(null);
        final api = credentialedApi(credentials, provider);

        await expectLater(
          api.send((rest) => rest.session.getCurrentUser()),
          _unauthenticated(code: 'AUTH_REQUIRED'),
        );
        expect(provider.unauthenticatedReasons, isEmpty);
      },
    );
  });

  group('refresh', () {
    test('returns a new pair and me works with the new access token', () async {
      final login = await logIn(credentials, credentials.listener);

      final tokens = await anonymousApi(credentials).send(
        (rest) => rest.session.refreshSession(
          body: RefreshSessionRequest(refreshToken: login.refreshToken),
        ),
      );
      final api = credentialedApi(
        credentials,
        InMemoryCredentialProvider(
          JwtCredentials(
            accessToken: tokens.token,
            refreshToken: tokens.refreshToken,
          ),
        ),
      );
      final me = await api.send((rest) => rest.session.getCurrentUser());

      expect(tokens.token, isNotEmpty);
      expect(tokens.refreshToken, isNotEmpty);
      expect(me.id, login.user.id);
    });

    test('accepts the previous refresh token again: tokens are stateless and '
        'a rotation does not revoke the old one', () async {
      final login = await logIn(credentials, credentials.listener);
      final api = anonymousApi(credentials);
      Future<SessionTokens> refresh() => api.send(
        (rest) => rest.session.refreshSession(
          body: RefreshSessionRequest(refreshToken: login.refreshToken),
        ),
      );

      await refresh();
      final again = await refresh();

      expect(again.token, isNotEmpty);
      expect(again.refreshToken, isNotEmpty);
    });
  });

  group('two-factor login', () {
    test('without a code returns the 2FA challenge', () async {
      final login = await anonymousApi(credentials).send(
        (rest) => rest.session.login(
          body: LoginRequest(
            username: credentials.twofa.username,
            password: credentials.twofa.password,
          ),
        ),
      );

      expect(
        login,
        isA<LoginTwoFactorChallenge>()
            .having((c) => c.requires2FA.toJson(), 'requires2FA', isTrue)
            .having((c) => c.message, 'message', isNotEmpty),
      );
    });

    test('with a valid TOTP code returns tokens', () async {
      final login = await logIn(
        credentials,
        credentials.twofa,
        totp: totp(credentials.totpSecret),
      );

      expect(login.token, isNotEmpty);
      expect(login.user.username, credentials.twofa.username);
    });

    test('with a wrong code throws Unauthenticated', () async {
      final api = anonymousApi(credentials);

      await expectLater(
        api.send(
          (rest) => rest.session.login(
            body: LoginRequest(
              username: credentials.twofa.username,
              password: credentials.twofa.password,
              token: wrongTotp(credentials.totpSecret),
            ),
          ),
        ),
        _unauthenticated(),
      );
    });
  });

  group('transport refresh', () {
    test('a rejected access token with a valid refresh token is refreshed '
        'once and the request succeeds on the replay', () async {
      final login = await logIn(credentials, credentials.listener);
      final provider = InMemoryCredentialProvider(
        JwtCredentials(
          accessToken: _tamper(login.token),
          refreshToken: login.refreshToken,
        ),
      );
      final api = credentialedApi(credentials, provider);

      final me = await api.send((rest) => rest.session.getCurrentUser());

      expect(me.id, login.user.id);
      expect(provider.rotations, hasLength(1));
      expect(provider.unauthenticatedReasons, isEmpty);
      expect(provider.current, same(provider.rotations.single));
    });

    test('a rejected access token with a rejected refresh token ends the '
        'session once', () async {
      final login = await logIn(credentials, credentials.listener);
      final provider = InMemoryCredentialProvider(
        JwtCredentials(
          accessToken: _tamper(login.token),
          refreshToken: _tamper(login.refreshToken),
        ),
      );
      final api = credentialedApi(credentials, provider);

      await expectLater(
        api.send((rest) => rest.session.getCurrentUser()),
        throwsA(isA<Unauthenticated>()),
      );
      expect(provider.rotations, isEmpty);
      expect(provider.unauthenticatedReasons, [
        UnauthenticatedReason.sessionExpired,
      ]);
    });
  });

  test('logout succeeds', () async {
    final api = await signedInApi(credentials, credentials.listener);

    final reply = await api.send((rest) => rest.session.logout());

    expect(reply.message, isNotEmpty);
  });

  group('server description', () {
    test('docs decodes with a non-empty version', () async {
      final api = await signedInApi(credentials, credentials.listener);

      final document = await api.send((rest) => rest.session.getApiDocument());

      expect(document.info.version, isNotEmpty);
    });

    test('features decodes with boolean flags', () async {
      final api = await signedInApi(credentials, credentials.listener);

      final features = await api.send(
        (rest) => rest.session.getSystemFeatures(),
      );

      expect([
        features.audioAnalysis,
        features.discovery,
        features.autoPlaylists,
        features.federation,
        features.vibeEmbeddings,
      ], everyElement(isA<bool>()));
      expect(features.loudnessTargetLufs, isA<num>());
    });
  });
}
