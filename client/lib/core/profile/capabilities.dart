// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/core/profile/version.dart';
import 'package:soundspan/core/profile/version_gate.dart';

/// What the active profile's server is and can do (doc 04, Capability
/// Discovery and Version Gate). Navigation and every feature-gated screen
/// read it from [serverCapabilitiesProvider].
@immutable
final class ServerCapabilities {
  /// Creates the capabilities of a server at [serverVersion] (null when it
  /// did not say).
  const new({
    required this.serverVersion,
    required this.hasP6SelfRevoke,
    required this.hasP7PlayMarker,
    required this.hasP8PlayedAt,
    this.audioAnalysis = false,
    this.discovery = false,
    this.autoPlaylists = false,
    this.federation = false,
    this.vibe = false,
    this.loudnessTargetLufs = defaultLoudnessTargetLufs,
    this.fetchedAt,
  });

  /// The capabilities of a server at [serverVersion] reporting [features]
  /// (the body of `GET /api/system/features`, or what [toFeaturesJson]
  /// wrote; null before the first refresh), fetched at [fetchedAt].
  ///
  /// A missing flag is off; a missing loudness target is
  /// [defaultLoudnessTargetLufs]. The P6 to P8 flags hold when the version is
  /// unknown or at least [minServer], the release that ships them.
  factory fromFeatures({
    required Version? serverVersion,
    required Map<String, Object?>? features,
    required Version minServer,
    DateTime? fetchedAt,
  }) {
    final json = features ?? const <String, Object?>{};
    bool flag(String key) => json[key] == true;
    final fromMin = serverVersion == null || serverVersion >= minServer;
    return ServerCapabilities(
      serverVersion: serverVersion,
      audioAnalysis: flag(_audioAnalysis),
      discovery: flag(_discovery),
      autoPlaylists: flag(_autoPlaylists),
      federation: flag(_federation),
      vibe: flag(_vibeEmbeddings),
      loudnessTargetLufs: switch (json[_loudnessTargetLufs]) {
        final num value => value.toDouble(),
        _ => defaultLoudnessTargetLufs,
      },
      hasP6SelfRevoke: fromMin,
      hasP7PlayMarker: fromMin,
      hasP8PlayedAt: fromMin,
      fetchedAt: fetchedAt,
    );
  }

  /// The capabilities cached on [profile]'s `serverVersion`, `features` and
  /// `featuresFetchedAt` columns. An unparseable version is unknown.
  factory fromProfile(Profile profile, {required Version minServer}) =>
      ServerCapabilities.fromFeatures(
        serverVersion: Version.tryParse(profile.serverVersion ?? ''),
        features: profile.features,
        minServer: minServer,
        fetchedAt: profile.featuresFetchedAt,
      );

  /// The loudness target when the server does not report one.
  static const double defaultLoudnessTargetLufs = -18;

  static const _audioAnalysis = 'audioAnalysis';
  static const _discovery = 'discovery';
  static const _autoPlaylists = 'autoPlaylists';
  static const _federation = 'federation';
  static const _vibeEmbeddings = 'vibeEmbeddings';
  static const _loudnessTargetLufs = 'loudnessTargetLufs';

  /// The server's version; null when it is unknown.
  final Version? serverVersion;

  /// Whether audio analysis is on.
  final bool audioAnalysis;

  /// Whether discovery is on.
  final bool discovery;

  /// Whether automatic playlists are on.
  final bool autoPlaylists;

  /// Whether federation is on.
  final bool federation;

  /// Whether vibe search is on (the server's `vibeEmbeddings`).
  final bool vibe;

  /// The loudness the server normalizes to, in LUFS.
  final double loudnessTargetLufs;

  /// Whether a session can revoke itself (P6).
  final bool hasP6SelfRevoke;

  /// Whether play reports carry the play marker (P7).
  final bool hasP7PlayMarker;

  /// Whether play reports carry `playedAt` (P8).
  final bool hasP8PlayedAt;

  /// When these were fetched from the server; null before the first
  /// refresh.
  final DateTime? fetchedAt;

  /// The server feature flags, in the server's names, for the profile's
  /// `features` column.
  Map<String, Object?> toFeaturesJson() => {
    _audioAnalysis: audioAnalysis,
    _autoPlaylists: autoPlaylists,
    _discovery: discovery,
    _federation: federation,
    _loudnessTargetLufs: loudnessTargetLufs,
    _vibeEmbeddings: vibe,
  };

  @override
  bool operator ==(Object other) =>
      other is ServerCapabilities &&
      other.serverVersion == serverVersion &&
      other.audioAnalysis == audioAnalysis &&
      other.discovery == discovery &&
      other.autoPlaylists == autoPlaylists &&
      other.federation == federation &&
      other.vibe == vibe &&
      other.loudnessTargetLufs == loudnessTargetLufs &&
      other.hasP6SelfRevoke == hasP6SelfRevoke &&
      other.hasP7PlayMarker == hasP7PlayMarker &&
      other.hasP8PlayedAt == hasP8PlayedAt &&
      other.fetchedAt == fetchedAt;

  @override
  int get hashCode => Object.hash(
    serverVersion,
    audioAnalysis,
    discovery,
    autoPlaylists,
    federation,
    vibe,
    loudnessTargetLufs,
    hasP6SelfRevoke,
    hasP7PlayMarker,
    hasP8PlayedAt,
    fetchedAt,
  );

  @override
  String toString() =>
      'ServerCapabilities(${serverVersion ?? 'unknown'}, '
      '${toFeaturesJson()})';
}

/// Holds the active profile's [ServerCapabilities]: the value cached on the
/// profile row as soon as the scope exists, then each refreshed one.
class ServerCapabilitiesNotifier extends Notifier<ServerCapabilities> {
  @override
  ServerCapabilities build() => ServerCapabilities.fromProfile(
    ref.watch(profileContextProvider).profile,
    minServer: ref.watch(versionGateProvider).min,
  );

  /// The current value; the capability refresher replaces it.
  ServerCapabilities get current => state;

  set current(ServerCapabilities next) => state = next;
}

/// The [ServerCapabilities] of the profile scope. Destinations and actions
/// of optional features are built from it.
final NotifierProvider<ServerCapabilitiesNotifier, ServerCapabilities>
serverCapabilitiesProvider =
    NotifierProvider<ServerCapabilitiesNotifier, ServerCapabilities>(
      ServerCapabilitiesNotifier.new,
      dependencies: [profileContextProvider],
    );
