// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/app/build_config.dart';
import 'package:soundspan/core/profile/version.dart';

/// Where a server version falls against the versions this client supports
/// (doc 04, Capability Discovery and Version Gate).
enum VersionGateResult {
  /// Older than the oldest supported server: sign-in is blocked.
  belowMin,

  /// Between the oldest supported and the newest tested server.
  inRange,

  /// Newer than the newest tested server: a dismissible notice.
  aboveTested,

  /// The server did not say: a dismissible notice; otherwise as in range.
  unknown;

  /// Whether the server cannot be used.
  bool get blocks => this == belowMin;
}

/// Places server versions between [min] and [maxTested], both inclusive.
@immutable
final class VersionGate {
  /// Creates the gate.
  const new(this.min, this.maxTested);

  /// The oldest supported server version.
  final Version min;

  /// The newest server version this client was tested against.
  final Version maxTested;

  /// Where [version] falls; null is [VersionGateResult.unknown].
  VersionGateResult evaluate(Version? version) {
    if (version == null) return VersionGateResult.unknown;
    if (version < min) return VersionGateResult.belowMin;
    if (version > maxTested) return VersionGateResult.aboveTested;
    return VersionGateResult.inRange;
  }

  @override
  bool operator ==(Object other) =>
      other is VersionGate && other.min == min && other.maxTested == maxTested;

  @override
  int get hashCode => Object.hash(min, maxTested);
}

/// The app's [VersionGate], from [BuildConfig.minServer] and
/// [BuildConfig.maxTestedServer]. Tests override it with their own range.
final Provider<VersionGate> versionGateProvider = Provider<VersionGate>(
  (ref) => VersionGate(
    Version.tryParse(BuildConfig.minServer)!,
    Version.tryParse(BuildConfig.maxTestedServer)!,
  ),
);
