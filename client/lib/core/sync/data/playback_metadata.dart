// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/shared/domain/track.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// The `metadata` sent with a `playbackId` on every write, built from the
/// [TrackMeta] the client already holds (doc 03, Wire Models).
api.PlaybackMetadata playbackMetadataFromMeta(TrackMeta meta) =>
    api.PlaybackMetadata(
      title: meta.title,
      artist: meta.artist,
      album: meta.album,
      durationSec: meta.durationSec,
      artworkUrl: meta.artworkRef,
      isrc: meta.isrc,
    );
