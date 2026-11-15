// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/auth/password_sign_in.dart';
import 'package:soundspan_api/soundspan_api.dart';

import 'password_sign_in_fakes.dart';

final Uri _base = Uri.parse('https://music.example.com');

void main() {
  late FakeLoginClient client;
  late PasswordSignIn signIn;

  setUp(() {
    client = FakeLoginClient();
    signIn = PasswordSignIn(client.factory);
  });

  Future<PasswordSignInResult> submit({String? code}) => signIn.submit(
    baseUrl: _base,
    username: 'ada',
    password: 'secret',
    code: code,
  );

  test('signedIn', () async {
    client.answer = (_) async => tokenResponse();
    final result = await submit();
    expect(result, isA<SignInSignedIn>());
    final signedIn = result as SignInSignedIn;
    expect(signedIn.credentials.accessToken, 'access-1');
    expect(signedIn.credentials.refreshToken, 'refresh-1');
    expect(signedIn.user.id, 'user-1');
    expect(client.baseUrls.single, _base);
    expect(client.requests.single.username, 'ada');
    expect(client.requests.single.password, 'secret');
    expect(client.requests.single.token, isNull);
    expect(client.closed, 1);
  });

  test('signedIn on the code step sends the code as token', () async {
    client.answer = (_) async => tokenResponse();
    final result = await submit(code: '123456');
    expect(result, isA<SignInSignedIn>());
    expect(client.requests.single.token, '123456');
  });

  test('needsCode', () async {
    client.answer = (_) async => twoFactorChallenge();
    expect(await submit(), isA<SignInNeedsCode>());
  });

  test('invalidCredentials', () async {
    client.answer = (_) async =>
        throw const Unauthenticated(status: 401, serverMessage: 'x');
    expect(await submit(), isA<SignInInvalidCredentials>());
  });

  test('invalidCode', () async {
    client.answer = (_) async => throw const Unauthenticated(status: 401);
    expect(await submit(code: 'abcdef12'), isA<SignInInvalidCode>());
  });

  test('localLoginDisabled', () async {
    client.answer = (_) async => throw const Forbidden(status: 403);
    expect(await submit(), isA<SignInLocalLoginDisabled>());
  });

  test('rateLimited', () async {
    client.answer = (_) async =>
        throw const RateLimited(status: 429, retryAfter: Duration(seconds: 42));
    final result = await submit();
    expect(result, isA<SignInRateLimited>());
    expect(
      (result as SignInRateLimited).retryAfter,
      const Duration(seconds: 42),
    );
  });

  test('failed', () async {
    for (final error in const <ApiException>[
      Offline(),
      ServerError(status: 500),
      Upstream(status: 502),
      NotSoundspan(status: 404),
    ]) {
      client.answer = (_) async => throw error;
      final result = await submit();
      expect(result, isA<SignInFailed>());
      expect((result as SignInFailed).error, same(error));
    }
    expect(client.closed, 4);
  });
}
