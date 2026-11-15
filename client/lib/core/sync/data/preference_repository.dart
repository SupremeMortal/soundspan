// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/sync/data/playback_metadata.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan/shared/domain/track.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// Writes track and album preferences (likes) to the server
/// (`POST /library/preferences`, `POST /library/albums/:id/preference`).
/// One request per call; `ApiException` propagates.
final class PreferenceRepository {
  /// Creates a repository over the generated library client.
  new(this._client);

  final api.LibraryClient _client;

  /// Sets the preference of the track [id] to [value] and answers the state
  /// the server holds afterwards. [meta] is sent as the request's
  /// `metadata`.
  Future<Preference> setTrackPreference(
    PlaybackId id,
    Preference value, {
    required TrackMeta meta,
  }) async {
    final response = await _client.setTrackPreference(
      body: api.TrackPreferenceRequest(
        playbackId: id.value,
        signal: preferenceSignal(value),
        metadata: playbackMetadataFromMeta(meta),
      ),
    );
    return preferenceFromState(response.state);
  }

  /// Sets the preference of the album [albumId] to [value] and answers the
  /// state the server holds afterwards.
  Future<Preference> setAlbumPreference(
    String albumId,
    Preference value,
  ) async {
    final response = await _client.setAlbumPreference(
      id: albumId,
      body: api.AlbumPreferenceRequest(signal: preferenceSignal(value)),
    );
    return preferenceFromState(response.state);
  }
}

/// The `signal` that sets a preference to [value].
api.PreferenceSignal preferenceSignal(Preference value) => switch (value) {
  Preference.liked => api.PreferenceSignal.thumbsUp,
  Preference.disliked => api.PreferenceSignal.thumbsDown,
  Preference.neutral => api.PreferenceSignal.clear,
};

/// The domain preference of a server `state`; a state this client does not
/// know is [Preference.neutral].
Preference preferenceFromState(api.PreferenceState state) => switch (state) {
  api.PreferenceStateKnown(value: api.PreferenceStateValue.liked) =>
    Preference.liked,
  api.PreferenceStateKnown(value: api.PreferenceStateValue.disliked) =>
    Preference.disliked,
  api.PreferenceStateKnown(value: api.PreferenceStateValue.neutral) ||
  api.PreferenceStateUnknown() => Preference.neutral,
};
