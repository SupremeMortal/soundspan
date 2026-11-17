// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/shared/domain/domain.dart';

/// What an in-app drag carries (doc 09, Desktop Interaction: Drag and
/// drop): tracks, or one album that the drop target resolves to its tracks.
sealed class DragPayload {
  const new();
}

/// Dragged tracks, in list order: the selection when the dragged row is
/// part of it, else that row alone; only tracks with a `playbackId`.
final class TracksPayload extends DragPayload {
  /// Creates the payload of [tracks].
  const new(this.tracks);

  /// The tracks, in list order.
  final List<Track> tracks;
}

/// A dragged album, resolved to its tracks on drop.
final class AlbumPayload extends DragPayload {
  /// Creates the payload of the album [albumId] titled [title].
  const new(this.albumId, this.title, this.trackCount);

  /// The album's id.
  final String albumId;

  /// The album's title, shown by the drag feedback.
  final String title;

  /// How many tracks the album has, when known.
  final int? trackCount;
}
