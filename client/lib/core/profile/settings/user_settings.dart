// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The user's loudness levelling mode (doc 06, Loudness).
enum LoudnessMode {
  /// No gain is applied.
  off,

  /// Each track is levelled on its own loudness.
  track,

  /// Tracks are levelled on their album's loudness.
  album,

  /// Album levelling inside an album run, track levelling otherwise.
  auto,

  /// A mode this client does not know; never sent back to the server.
  unknown,
}

/// The server-stored settings the client reads (`GET /settings`).
final class UserSettings {
  /// Creates settings.
  const new({
    required this.playbackQuality,
    required this.loudnessMode,
    required this.maxCacheSizeMb,
  });

  /// The stream quality: `original`, `high`, `medium` or `low`, verbatim.
  final String playbackQuality;

  /// The loudness levelling mode.
  final LoudnessMode loudnessMode;

  /// The server's cache size limit in MB.
  final int maxCacheSizeMb;

  @override
  bool operator ==(Object other) =>
      other is UserSettings &&
      other.playbackQuality == playbackQuality &&
      other.loudnessMode == loudnessMode &&
      other.maxCacheSizeMb == maxCacheSizeMb;

  @override
  int get hashCode =>
      Object.hash(playbackQuality, loudnessMode, maxCacheSizeMb);

  @override
  String toString() =>
      'UserSettings(playbackQuality: $playbackQuality, '
      'loudnessMode: ${loudnessMode.name}, maxCacheSizeMb: $maxCacheSizeMb)';
}
