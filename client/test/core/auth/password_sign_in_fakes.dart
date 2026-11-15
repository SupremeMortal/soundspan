// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/auth/password_sign_in.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// A [LoginClient] whose answer the test sets.
class FakeLoginClient {
  /// The answer to every login; a successful sign-in unless set.
  Future<LoginResponse200> Function(LoginRequest request) answer = (_) async =>
      tokenResponse();

  /// The base URLs clients were created for.
  final List<Uri> baseUrls = [];

  /// Every request sent, in order.
  final List<LoginRequest> requests = [];

  /// How many clients were closed.
  int closed = 0;

  /// The [LoginClientFactory] over this fake.
  LoginClient factory(Uri baseUrl) {
    baseUrls.add(baseUrl);
    return _Client(this);
  }
}

class _Client implements LoginClient {
  new(this._fake);

  final FakeLoginClient _fake;

  @override
  Future<LoginResponse200> login(LoginRequest request) {
    _fake.requests.add(request);
    return _fake.answer(request);
  }

  @override
  void close() => _fake.closed++;
}

/// A token response for user `user-1` (`ada`).
LoginResponse200 tokenResponse({
  String access = 'access-1',
  String refresh = 'refresh-1',
  String userId = 'user-1',
  String username = 'ada',
}) => LoginResponse200.fromJson({
  'token': access,
  'refreshToken': refresh,
  'user': {
    'id': userId,
    'username': username,
    'role': 'user',
    'displayName': 'Ada',
  },
});

/// The second-factor challenge.
LoginResponse200 twoFactorChallenge() => LoginResponse200.fromJson({
  'requires2FA': true,
  'message': '2FA token required',
});
