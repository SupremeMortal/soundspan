// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/profile/settings/user_settings.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// Reads and writes the user's server-stored settings (`GET /settings`,
/// `POST /settings`). One request per call; `ApiException` propagates.
final class SettingsRepository {
  /// Creates a repository over the generated session client.
  new(this._client);

  final api.SessionClient _client;

  /// The current settings.
  Future<UserSettings> fetch() async =>
      userSettingsFromWire(await _client.getSettings());

  /// Changes the fields given and answers the settings the server holds
  /// afterwards. An [LoudnessMode.unknown] mode is left out of the request.
  Future<UserSettings> update({
    String? playbackQuality,
    LoudnessMode? loudnessMode,
  }) async => userSettingsFromWire(
    await _client.updateSettings(
      body: api.UpdateSettingsRequest(
        playbackQuality: playbackQuality == null
            ? null
            : api.PlaybackQuality.fromJson(playbackQuality),
        loudnessMode: loudnessModeToWire(loudnessMode),
      ),
    ),
  );
}

/// The domain settings of a `UserSettings` response.
UserSettings userSettingsFromWire(api.UserSettings wire) => UserSettings(
  playbackQuality: wire.playbackQuality.toJson(),
  loudnessMode: loudnessModeFromWire(wire.loudnessMode),
  maxCacheSizeMb: wire.maxCacheSizeMb,
);

/// The domain mode of a wire mode; a value this client does not know is
/// [LoudnessMode.unknown].
LoudnessMode loudnessModeFromWire(api.LoudnessMode wire) => switch (wire) {
  api.LoudnessModeKnown(value: api.LoudnessModeValue.off) => LoudnessMode.off,
  api.LoudnessModeKnown(value: api.LoudnessModeValue.track) =>
    LoudnessMode.track,
  api.LoudnessModeKnown(value: api.LoudnessModeValue.album) =>
    LoudnessMode.album,
  api.LoudnessModeKnown(value: api.LoudnessModeValue.auto) => LoudnessMode.auto,
  api.LoudnessModeUnknown() => LoudnessMode.unknown,
};

/// The wire mode to send for [mode]; null for no mode and for
/// [LoudnessMode.unknown], which is never sent.
api.LoudnessMode? loudnessModeToWire(LoudnessMode? mode) => switch (mode) {
  null || LoudnessMode.unknown => null,
  LoudnessMode.off => api.LoudnessMode.off,
  LoudnessMode.track => api.LoudnessMode.track,
  LoudnessMode.album => api.LoudnessMode.album,
  LoudnessMode.auto => api.LoudnessMode.auto,
};
