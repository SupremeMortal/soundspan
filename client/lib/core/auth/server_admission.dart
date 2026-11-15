// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart' show immutable;
import 'package:soundspan_api/soundspan_api.dart';

/// What the capability refresh read from a server a sign-in reached.
@immutable
final class ServerSnapshot {
  /// Creates the snapshot.
  const new({this.serverVersion, this.features, this.fetchedAt});

  /// The server's version; null when it did not say.
  final String? serverVersion;

  /// The feature flags to store on the profile; null when they could not
  /// be read.
  final Map<String, Object?>? features;

  /// When [features] was read; null when it could not be.
  final DateTime? fetchedAt;
}

/// The capability refresh and version gate a sign-in runs before it stores
/// a profile (doc 04, Capability Discovery and Version Gate). `core/profile`
/// implements it, because the gate lives there.
abstract interface class ServerAdmission {
  /// Reads the version and features of [api]'s server.
  ///
  /// Throws [ServerTooOld] when the server is older than the oldest
  /// supported version.
  Future<ServerSnapshot> check(SoundspanApi api);
}

/// The server is older than this client supports; sign-in is blocked.
final class ServerTooOld implements Exception {
  /// Creates the error.
  const new({required this.serverVersion, required this.minServer});

  /// The version the server reported.
  final String serverVersion;

  /// The oldest supported version.
  final String minServer;

  @override
  String toString() => 'ServerTooOld($serverVersion < $minServer)';
}
