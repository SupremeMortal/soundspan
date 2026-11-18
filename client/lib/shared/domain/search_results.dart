// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:soundspan/shared/domain/album.dart';
import 'package:soundspan/shared/domain/artist.dart';
import 'package:soundspan/shared/domain/playlist.dart';
import 'package:soundspan/shared/domain/podcast.dart';
import 'package:soundspan/shared/domain/track.dart';

part 'search_results.freezed.dart';
part 'search_results.g.dart';

/// How many results one page of a search asks for.
const int searchPageSize = 30;

/// What a search lists: the filter chips of the Search screen. [value] is
/// the server's `type` parameter value.
enum SearchFilter {
  /// Every kind, in one list.
  all('all'),

  /// Songs only.
  songs('tracks'),

  /// Artists only.
  artists('artists'),

  /// Albums only.
  albums('albums'),

  /// Playlists only.
  playlists('playlists'),

  /// Podcasts only.
  podcasts('podcasts');

  new(this.value);

  /// The server's parameter value.
  final String value;

  /// Whether [hit] is of the kind this filter lists.
  bool admits(SearchHit hit) => switch (this) {
    SearchFilter.all => true,
    SearchFilter.songs => hit is TrackHit,
    SearchFilter.artists => hit is ArtistHit,
    SearchFilter.albums => hit is AlbumHit,
    SearchFilter.playlists => hit is PlaylistHit,
    SearchFilter.podcasts => hit is PodcastHit,
  };
}

/// One item found by a search.
@Freezed(unionKey: 'kind')
sealed class SearchHit with _$SearchHit {
  /// A track.
  @FreezedUnionValue('track')
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory SearchHit.track({
    /// The track.
    required Track track,
  }) = TrackHit;

  /// An album.
  @FreezedUnionValue('album')
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory SearchHit.album({
    /// The album.
    required Album album,
  }) = AlbumHit;

  /// An artist.
  @FreezedUnionValue('artist')
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory SearchHit.artist({
    /// The artist.
    required Artist artist,
  }) = ArtistHit;

  /// A playlist the user can see.
  @FreezedUnionValue('playlist')
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory SearchHit.playlist({
    /// The playlist.
    required PlaylistSummary playlist,
  }) = PlaylistHit;

  /// A podcast.
  @FreezedUnionValue('podcast')
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory SearchHit.podcast({
    /// The podcast.
    required PodcastSummary podcast,
  }) = PodcastHit;

  /// Decodes a hit written by [SearchHit.toJson].
  factory fromJson(Map<String, Object?> json) => _$SearchHitFromJson(json);
}

/// Whether a result is held by the user's library, so its page can be
/// opened, or only by a catalogue outside it. The screen never shows it.
enum SearchResultSource {
  /// The library, including the user's liked streaming items.
  library,

  /// A catalogue outside the library.
  catalogue,
}

/// One result of a search: the [SearchResult.hit], its relevance
/// [SearchResult.score] (higher is better, comparable across kinds) and its
/// [SearchResult.source].
@freezed
abstract class SearchResult with _$SearchResult {
  /// Creates a result.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory SearchResult({
    /// What was found.
    required SearchHit hit,

    /// The relevance score; results are listed highest first.
    @Default(0) double score,

    /// Where the result is held.
    @Default(SearchResultSource.library) SearchResultSource source,
  }) = _SearchResult;

  /// Decodes a result written by [SearchResult.toJson].
  factory fromJson(Map<String, Object?> json) => _$SearchResultFromJson(json);
}

/// One page of a search, best match first.
@freezed
abstract class SearchPage with _$SearchPage {
  /// Creates a page.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory SearchPage({
    /// The results, in server order.
    @Default(<SearchResult>[]) List<SearchResult> items,

    /// Whether a later page holds more results.
    @Default(false) bool hasMore,
  }) = _SearchPage;

  /// Decodes a page written by [SearchPage.toJson].
  factory fromJson(Map<String, Object?> json) => _$SearchPageFromJson(json);
}
