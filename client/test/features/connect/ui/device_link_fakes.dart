// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/auth/device_link_code.dart';
import 'package:soundspan/core/auth/device_link_sign_in.dart';
import 'package:soundspan/core/auth/profile.dart';

/// The server the device-link tests link to.
const linkBase = 'https://music.example.com';

/// The profile a [FakeDeviceLinkSignIn] answers with by default.
final Profile linkedProfile = Profile(
  id: 'linked',
  baseUrl: Uri.parse(linkBase),
  displayName: 'music.example.com',
  userId: 'user-1',
  username: 'ada',
  role: 'user',
  authKind: AuthKind.deviceLink,
  deviceId: 'device-1',
  credentialCreatedAt: DateTime.utc(2026),
  state: ProfileState.active,
  lastUsedAt: DateTime.utc(2026),
);

/// One call of [FakeDeviceLinkSignIn.submit].
typedef DeviceLinkCall = ({
  Uri baseUrl,
  DeviceLinkCode code,
  String deviceName,
});

/// A [DeviceLinkSignIn] that records its calls and answers with [answer].
class FakeDeviceLinkSignIn implements DeviceLinkSignIn {
  /// The calls, in order.
  final List<DeviceLinkCall> calls = [];

  /// What the next call returns or throws.
  Future<Profile> Function() answer = () async => linkedProfile;

  @override
  Future<Profile> submit({
    required Uri baseUrl,
    required DeviceLinkCode code,
    required String deviceName,
  }) {
    calls.add((baseUrl: baseUrl, code: code, deviceName: deviceName));
    return answer();
  }
}
