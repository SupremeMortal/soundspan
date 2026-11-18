// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The sections of the Search screen (doc 09, Search), built from the
/// library search, the catalogue search and the user's playlists. Nothing
/// in a section says where an item came from.
library;

import 'package:soundspan/shared/domain/domain.dart';

/// The sections of the Search screen, in screen order.
enum SearchSectionKind {
  /// Tracks.
  songs,

  /// Artists.
  artists,

  /// Albums.
  albums,

  /// The user's playlists whose name contains the query.
  playlists,

  /// Podcasts.
  podcasts,
}

/// One item of a section, or the top result.
sealed class SearchItem {
  const new();
}

/// A track.
final class SearchTrackItem extends SearchItem {
  /// The item for [track].
  const new(this.track);

  /// The track.
  final Track track;
}

/// An artist; [libraryId] is null when its page cannot be opened.
final class SearchArtistItem extends SearchItem {
  /// The item for [artist].
  const new(this.artist, {this.libraryId});

  /// The artist.
  final Artist artist;

  /// The id the artist page opens with, if any.
  final String? libraryId;
}

/// An album; [libraryId] is null when its page cannot be opened.
final class SearchAlbumItem extends SearchItem {
  /// The item for [album].
  const new(this.album, {this.libraryId});

  /// The album.
  final Album album;

  /// The id the album page opens with, if any.
  final String? libraryId;
}

/// One of the user's playlists.
final class SearchPlaylistItem extends SearchItem {
  /// The item for [playlist].
  const new(this.playlist);

  /// The playlist.
  final PlaylistSummary playlist;
}

/// A podcast.
final class SearchPodcastItem extends SearchItem {
  /// The item for [podcast].
  const new(this.podcast);

  /// The podcast.
  final PodcastSummary podcast;
}

/// One non-empty section: every fetched item, of which [preview] shows
/// first.
final class SearchSection {
  /// The [kind] section of [items].
  const new(this.kind, this.items);

  /// How many items show before "Show all".
  static const int previewLength = 5;

  /// Which section this is.
  final SearchSectionKind kind;

  /// Every item, in screen order.
  final List<SearchItem> items;

  /// The items shown while the section is collapsed.
  List<SearchItem> get preview =>
      items.length <= previewLength ? items : items.sublist(0, previewLength);

  /// Whether [items] holds more than [preview].
  bool get hasMore => items.length > previewLength;
}

/// The top result and the non-empty sections, in screen order.
final class SearchSections {
  /// The sections [sections] under [topResult].
  const new({required this.sections, this.topResult});

  /// The top result, not repeated in its section.
  final SearchItem? topResult;

  /// The non-empty sections, in [SearchSectionKind] order.
  final List<SearchSection> sections;

  /// Whether nothing was found.
  bool get isEmpty => topResult == null && sections.isEmpty;

  /// The [kind] section, or null when it is empty.
  SearchSection? section(SearchSectionKind kind) {
    for (final section in sections) {
      if (section.kind == kind) return section;
    }
    return null;
  }
}

/// Builds the sections for [query] over [scope].
///
/// Songs, Artists, Albums and Podcasts list the [library] results first and
/// then the [discover] ones, each in server order; an item in both appears
/// once, at its first position (tracks by `playbackId`, the others by id).
/// Playlists are those of [playlists] whose name contains [query] without
/// case. [SearchScope.library] ignores [discover], [SearchScope.discover]
/// ignores [library] and [playlists], and [SearchScope.podcasts] keeps only
/// the podcasts of [library].
///
/// The top result is the first artist whose name equals [query] without
/// case, else the first song, else the first album, else the first artist;
/// it is left out of its section.
SearchSections buildSearchSections(
  LibrarySearchResults? library,
  DiscoverResults? discover,
  List<PlaylistSummary> playlists,
  String query,
  SearchScope scope,
) {
  final lib = scope == SearchScope.discover ? null : library;
  final disc = switch (scope) {
    SearchScope.all || SearchScope.discover => discover,
    SearchScope.library || SearchScope.podcasts => null,
  };
  final hits = disc?.hits ?? const <SearchHit>[];
  final musicScope = scope != SearchScope.podcasts;

  final songs = musicScope
      ? _unique<SearchItem>([
          for (final track in lib?.tracks ?? const <Track>[])
            SearchTrackItem(track),
          for (final hit in hits)
            if (hit case TrackHit(:final track)) SearchTrackItem(track),
        ], (item) => (item as SearchTrackItem).track.playbackId?.value)
      : <SearchItem>[];
  final artists = musicScope
      ? _unique<SearchItem>([
          for (final artist in lib?.artists ?? const <Artist>[])
            SearchArtistItem(artist, libraryId: artist.id),
          for (final hit in hits)
            if (hit case ArtistHit(:final artist)) SearchArtistItem(artist),
        ], (item) => (item as SearchArtistItem).artist.id)
      : <SearchItem>[];
  final albums = musicScope
      ? _unique<SearchItem>([
          for (final album in lib?.albums ?? const <Album>[])
            SearchAlbumItem(album, libraryId: album.id),
          for (final hit in hits)
            if (hit case AlbumHit(:final album)) SearchAlbumItem(album),
        ], (item) => (item as SearchAlbumItem).album.id)
      : <SearchItem>[];
  final needle = query.trim().toLowerCase();
  final ownPlaylists = switch (scope) {
    SearchScope.all || SearchScope.library => <SearchItem>[
      for (final playlist in playlists)
        if (needle.isNotEmpty && playlist.name.toLowerCase().contains(needle))
          SearchPlaylistItem(playlist),
    ],
    SearchScope.discover || SearchScope.podcasts => <SearchItem>[],
  };
  final podcasts = _unique<SearchItem>([
    for (final podcast in lib?.podcasts ?? const <PodcastSummary>[])
      SearchPodcastItem(podcast),
    for (final hit in hits)
      if (hit case PodcastHit(:final podcast)) SearchPodcastItem(podcast),
  ], (item) => (item as SearchPodcastItem).podcast.id);

  SearchItem? exactArtist;
  for (final item in artists) {
    if ((item as SearchArtistItem).artist.name.toLowerCase() == needle) {
      exactArtist = item;
      break;
    }
  }
  final top =
      exactArtist ??
      songs.firstOrNull ??
      albums.firstOrNull ??
      artists.firstOrNull;

  final byKind = {
    SearchSectionKind.songs: songs,
    SearchSectionKind.artists: artists,
    SearchSectionKind.albums: albums,
    SearchSectionKind.playlists: ownPlaylists,
    SearchSectionKind.podcasts: podcasts,
  };
  return SearchSections(
    topResult: top,
    sections: [
      for (final kind in SearchSectionKind.values)
        if ([
              for (final item in byKind[kind]!)
                if (!identical(item, top)) item,
            ]
            case final items when items.isNotEmpty)
          SearchSection(kind, items),
    ],
  );
}

/// [items] without the later ones whose [key] repeats an earlier one; an
/// item without a key is always kept.
List<T> _unique<T>(List<T> items, String? Function(T item) key) {
  final seen = <String>{};
  return [
    for (final item in items)
      if (key(item) case final k when k == null || seen.add(k)) item,
  ];
}
