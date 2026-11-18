// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The kind of entity a `list_entries` row points at (doc 05).
///
/// Stored by name in `list_entries.entity_kind`.
enum CacheEntityKind {
  /// A row in `tracks`, keyed by `key`.
  track,

  /// A row in `albums`, keyed by `id`.
  album,

  /// A row in `artists`, keyed by `id`.
  artist,

  /// A row in `playlists`, keyed by `id`.
  playlist,

  /// A row in `podcasts`, keyed by `id`.
  podcast,

  /// A row in `episodes`, keyed by `id`.
  episode,
}
