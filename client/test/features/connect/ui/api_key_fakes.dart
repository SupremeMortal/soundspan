// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/auth/api_key_sign_in.dart';
import 'package:soundspan/core/auth/profile.dart';

import 'device_link_fakes.dart';

/// The profile a [FakeApiKeySignIn] answers with by default.
final Profile keyProfile = linkedProfile.copyWith(
  id: 'keyed',
  authKind: AuthKind.apiKey,
);

/// One call of [FakeApiKeySignIn.submit].
typedef ApiKeyCall = ({Uri baseUrl, String apiKey});

/// An [ApiKeySignIn] that records its calls and answers with [answer].
class FakeApiKeySignIn implements ApiKeySignIn {
  /// The calls, in order.
  final List<ApiKeyCall> calls = [];

  /// What the next call returns or throws.
  Future<Profile> Function() answer = () async => keyProfile;

  @override
  Future<Profile> submit({required Uri baseUrl, required String apiKey}) {
    calls.add((baseUrl: baseUrl, apiKey: apiKey));
    return answer();
  }
}
