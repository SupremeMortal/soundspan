// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/device_link_sign_in.dart';
import 'package:soundspan/core/auth/server_admission.dart';
import 'package:soundspan/core/profile/capabilities.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/profile/version.dart';
import 'package:soundspan/core/profile/version_gate.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// The [ServerAdmission] of [VersionGate]: reads the server version (an
/// unreadable one is unknown and admitted), blocks a version below
/// [VersionGate.min], then reads the features as the capability refresh
/// does. Features that cannot be read leave the snapshot without them; the
/// profile's own refresh fetches them once it is active.
class VersionGateAdmission implements ServerAdmission {
  /// Creates the admission over [_gate], timing reads with [_clock].
  const new(this._gate, this._clock);

  final VersionGate _gate;
  final Clock _clock;

  @override
  Future<ServerSnapshot> check(SoundspanApi api) async {
    String? version;
    try {
      version = await api.fetchServerVersion();
    } on ApiException {
      version = null;
    }
    final parsed = Version.tryParse(version ?? '');
    if (version != null && _gate.evaluate(parsed).blocks) {
      throw ServerTooOld(
        serverVersion: version,
        minServer: _gate.min.toString(),
      );
    }
    try {
      final features = await api.send(
        (rest) => rest.session.getSystemFeatures(),
      );
      final capabilities = ServerCapabilities.fromFeatures(
        serverVersion: parsed,
        features: features.toJson(),
        minServer: _gate.min,
      );
      return ServerSnapshot(
        serverVersion: version,
        features: capabilities.toFeaturesJson(),
        fetchedAt: _clock.now(),
      );
    } on ApiException {
      return ServerSnapshot(serverVersion: version);
    }
  }
}

/// The app's [DeviceLinkSignIn].
final Provider<DeviceLinkSignIn> deviceLinkSignInProvider =
    Provider<DeviceLinkSignIn>(
      (ref) => DeviceLinkSignIn(
        profiles: ref.watch(profileRepositoryProvider),
        admission: VersionGateAdmission(
          ref.watch(versionGateProvider),
          ref.watch(clockProvider),
        ),
        clock: ref.watch(clockProvider),
        userAgent: ref.watch(userAgentProvider),
      ),
    );
