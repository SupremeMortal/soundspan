// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/profile/capabilities.dart';
import 'package:soundspan/core/profile/version.dart';

final Version _min = Version.tryParse('1.4.0')!;

Profile _profile({
  String? serverVersion,
  Map<String, Object?>? features,
  DateTime? fetchedAt,
}) => Profile(
  id: 'p',
  baseUrl: Uri.parse('https://music.example.com'),
  displayName: 'music',
  userId: 'u',
  username: 'ada',
  role: 'user',
  authKind: AuthKind.password,
  deviceId: 'd',
  credentialCreatedAt: DateTime.utc(2025),
  state: ProfileState.active,
  lastUsedAt: DateTime.utc(2025),
  serverVersion: serverVersion,
  features: features,
  featuresFetchedAt: fetchedAt,
);

ServerCapabilities _at(String? version, [Map<String, Object?>? features]) =>
    ServerCapabilities.fromFeatures(
      serverVersion: version == null ? null : Version.tryParse(version),
      features: features,
      minServer: _min,
    );

void main() {
  test('feature mapping from the server names', () {
    final capabilities = _at('1.5.0', {
      'audioAnalysis': true,
      'autoPlaylists': true,
      'discovery': false,
      'federation': true,
      'loudnessTargetLufs': -14,
      'vibeEmbeddings': true,
      'somethingNew': true,
    });
    expect(capabilities.audioAnalysis, isTrue);
    expect(capabilities.autoPlaylists, isTrue);
    expect(capabilities.discovery, isFalse);
    expect(capabilities.federation, isTrue);
    expect(capabilities.vibe, isTrue);
    expect(capabilities.loudnessTargetLufs, -14);
    expect(capabilities.serverVersion, Version.tryParse('1.5.0'));
  });

  test('missing features are off and the loudness target defaults to -18', () {
    for (final features in [null, <String, Object?>{}]) {
      final capabilities = _at('1.5.0', features);
      expect(capabilities.audioAnalysis, isFalse);
      expect(capabilities.autoPlaylists, isFalse);
      expect(capabilities.discovery, isFalse);
      expect(capabilities.federation, isFalse);
      expect(capabilities.vibe, isFalse);
      expect(capabilities.loudnessTargetLufs, -18);
    }
  });

  test('P6 to P8 flags for below, in range and unknown', () {
    for (final (version, expected) in [
      ('1.3.9', false),
      ('1.4.0', true),
      ('2.0.0', true),
      (null, true),
    ]) {
      final capabilities = _at(version);
      expect(capabilities.hasP6SelfRevoke, expected, reason: '$version');
      expect(capabilities.hasP7PlayMarker, expected, reason: '$version');
      expect(capabilities.hasP8PlayedAt, expected, reason: '$version');
    }
  });

  test('round trip through the profile row', () {
    final fetchedAt = DateTime.utc(2025, 3, 4);
    final original = ServerCapabilities.fromFeatures(
      serverVersion: Version.tryParse('1.5.2-rc.1'),
      features: const {
        'audioAnalysis': true,
        'discovery': true,
        'vibeEmbeddings': true,
        'loudnessTargetLufs': -16.5,
      },
      minServer: _min,
      fetchedAt: fetchedAt,
    );
    final stored = _profile(
      serverVersion: original.serverVersion.toString(),
      features: original.toFeaturesJson(),
      fetchedAt: fetchedAt,
    );
    expect(ServerCapabilities.fromProfile(stored, minServer: _min), original);
  });

  test('a profile never refreshed is unknown with default features', () {
    final capabilities = ServerCapabilities.fromProfile(
      _profile(),
      minServer: _min,
    );
    expect(capabilities.serverVersion, isNull);
    expect(capabilities.fetchedAt, isNull);
    expect(capabilities.loudnessTargetLufs, -18);
    expect(capabilities.hasP8PlayedAt, isTrue);
  });

  test('an unparseable stored version is unknown', () {
    final capabilities = ServerCapabilities.fromProfile(
      _profile(serverVersion: 'nightly'),
      minServer: _min,
    );
    expect(capabilities.serverVersion, isNull);
  });
}
