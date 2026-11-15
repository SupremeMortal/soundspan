// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/shared/domain/track.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// The `metadata` sent with a `playbackId` on every write, built from the
/// [TrackMeta] the client already holds (doc 03, Wire Models).
///
/// Null when the title, artist or album is blank: the server rejects blank
/// values, and it needs `metadata` only for tracks outside the library,
/// which always carry all three.
api.PlaybackMetadata? playbackMetadataFromMeta(TrackMeta meta) =>
    meta.title.trim().isEmpty ||
        meta.artist.trim().isEmpty ||
        meta.album.trim().isEmpty
    ? null
    : api.PlaybackMetadata(
        title: meta.title,
        artist: meta.artist,
        album: meta.album,
        durationSec: meta.durationSec,
        artworkUrl: meta.artworkRef,
        isrc: meta.isrc,
      );
