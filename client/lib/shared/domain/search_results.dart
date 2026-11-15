// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:soundspan/shared/domain/album.dart';
import 'package:soundspan/shared/domain/artist.dart';
import 'package:soundspan/shared/domain/podcast.dart';
import 'package:soundspan/shared/domain/track.dart';

part 'search_results.freezed.dart';
part 'search_results.g.dart';

/// The `type` values of a library search; [value] is the server's
/// parameter value.
enum LibrarySearchType {
  /// Every group.
  all('all'),

  /// Artists only.
  artists('artists'),

  /// Albums only.
  albums('albums'),

  /// Tracks only.
  tracks('tracks'),

  /// Podcasts only.
  podcasts('podcasts');

  new(this.value);

  /// The server's parameter value.
  final String value;
}

/// The `type` values of a catalogue search; [value] is the server's
/// parameter value.
enum DiscoverSearchType {
  /// Artists and tracks.
  music('music'),

  /// Podcasts.
  podcasts('podcasts'),

  /// Music and podcasts.
  all('all');

  new(this.value);

  /// The server's parameter value.
  final String value;
}

/// One result of a search.
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

/// The groups of a library search, each in server order.
@freezed
abstract class LibrarySearchResults with _$LibrarySearchResults {
  /// Creates library search results.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory LibrarySearchResults({
    /// Matching artists.
    @Default(<Artist>[]) List<Artist> artists,

    /// Matching albums.
    @Default(<Album>[]) List<Album> albums,

    /// Matching tracks.
    @Default(<Track>[]) List<Track> tracks,

    /// Matching podcasts.
    @Default(<PodcastSummary>[]) List<PodcastSummary> podcasts,
  }) = _LibrarySearchResults;

  /// Decodes results written by [LibrarySearchResults.toJson].
  factory fromJson(Map<String, Object?> json) =>
      _$LibrarySearchResultsFromJson(json);
}

/// The spelling correction a catalogue search applied to the query.
@freezed
abstract class AliasInfo with _$AliasInfo {
  /// Creates alias information.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory AliasInfo({
    /// The query as typed.
    required String original,

    /// The name the search used instead.
    required String canonical,
  }) = _AliasInfo;

  /// Decodes alias information written by [AliasInfo.toJson].
  factory fromJson(Map<String, Object?> json) => _$AliasInfoFromJson(json);
}

/// The results of a catalogue search.
@freezed
abstract class DiscoverResults with _$DiscoverResults {
  /// Creates catalogue search results.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory DiscoverResults({
    /// The results in server order, across kinds.
    @Default(<SearchHit>[]) List<SearchHit> hits,

    /// The correction applied to the query, if any.
    AliasInfo? aliasInfo,
  }) = _DiscoverResults;

  /// Decodes results written by [DiscoverResults.toJson].
  factory fromJson(Map<String, Object?> json) =>
      _$DiscoverResultsFromJson(json);
}

/// What a search covers: the filter chips of the Search screen.
enum SearchScope {
  /// The library and catalogues outside it.
  all,

  /// The library only.
  library,

  /// Catalogues outside the library only.
  discover,

  /// Podcasts of the library search only.
  podcasts,
}

/// The results of one search: the library search, the catalogue search, or
/// both, by [SearchScope].
@freezed
abstract class SearchResults with _$SearchResults {
  /// Creates search results.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory SearchResults({
    /// The library search, when the scope includes it.
    LibrarySearchResults? library,

    /// The catalogue search, when the scope includes it.
    DiscoverResults? discover,
  }) = _SearchResults;

  /// Decodes results written by [SearchResults.toJson].
  factory fromJson(Map<String, Object?> json) => _$SearchResultsFromJson(json);
}
