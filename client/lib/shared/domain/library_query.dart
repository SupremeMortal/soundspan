// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:freezed_annotation/freezed_annotation.dart';

part 'library_query.freezed.dart';

/// Which part of the library a list covers; [value] is the server's
/// `origin` parameter value.
enum LibraryOrigin {
  /// Everything.
  all('all'),

  /// The server's own files.
  local('local'),

  /// Federated peers.
  peers('peers'),

  /// Streaming services.
  remote('remote');

  new(this.value);

  /// The server's parameter value.
  final String value;
}

/// The `filter` values of the artists list.
enum ArtistFilter {
  /// Artists the library holds albums of.
  owned('owned'),

  /// Artists from discovery.
  discovery('discovery'),

  /// Artists from streaming services.
  remote('remote'),

  /// Every artist.
  all('all');

  new(this.value);

  /// The server's parameter value.
  final String value;
}

/// The `sortBy` values of the artists list.
enum ArtistSort {
  /// By name, A to Z.
  name('name'),

  /// By name, Z to A.
  nameDesc('name-desc'),

  /// By number of tracks.
  tracks('tracks');

  new(this.value);

  /// The server's parameter value.
  final String value;
}

/// The `filter` values of the albums list.
enum AlbumFilter {
  /// Albums the library holds.
  owned('owned'),

  /// Albums from discovery.
  discovery('discovery'),

  /// Every album.
  all('all');

  new(this.value);

  /// The server's parameter value.
  final String value;
}

/// The `sortBy` values of the albums list.
enum AlbumSort {
  /// By name, A to Z.
  name('name'),

  /// By name, Z to A.
  nameDesc('name-desc'),

  /// Most recently added first.
  recent('recent');

  new(this.value);

  /// The server's parameter value.
  final String value;
}

/// The `sortBy` values of the tracks list.
enum TrackSort {
  /// By name, A to Z.
  name('name'),

  /// By name, Z to A.
  nameDesc('name-desc');

  new(this.value);

  /// The server's parameter value.
  final String value;
}

/// The keyset cursor of the liked-tracks list: the like time and track id of
/// the last item of a page.
@freezed
abstract class LikedCursor with _$LikedCursor {
  /// Creates a cursor.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory LikedCursor({
    /// When the last track of the page was liked, in UTC.
    required DateTime likedAt,

    /// The id of the last track of the page.
    required String trackId,
  }) = _LikedCursor;
}

/// Builds a list key: [name], then `?` and the non-null [params] in the
/// given order.
String _listKey(String name, List<(String, String?)> params) {
  final present = [
    for (final (key, value) in params)
      if (value != null) '$key=${Uri.encodeQueryComponent(value)}',
  ];
  return present.isEmpty ? name : '$name?${present.join('&')}';
}

/// What the albums list shows (`GET /library/albums`).
@freezed
abstract class AlbumQuery with _$AlbumQuery {
  /// Creates a query; null fields take the server's defaults.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory AlbumQuery({
    /// Only the albums of this artist.
    String? artistId,

    /// Which albums.
    AlbumFilter? filter,

    /// The order.
    AlbumSort? sortBy,

    /// Which part of the library.
    LibraryOrigin? origin,
  }) = _AlbumQuery;

  const new _();

  /// The cache key of the list (doc 05, `listKey`); two different queries
  /// never share one.
  String get listKey => _listKey('albums', [
    ('artistId', artistId),
    ('filter', filter?.value),
    ('sort', sortBy?.value),
    ('origin', origin?.value),
  ]);
}

/// What the artists list shows (`GET /library/artists`).
@freezed
abstract class ArtistQuery with _$ArtistQuery {
  /// Creates a query; null fields take the server's defaults.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory ArtistQuery({
    /// Which artists.
    ArtistFilter? filter,

    /// The order.
    ArtistSort? sortBy,

    /// Which part of the library.
    LibraryOrigin? origin,
  }) = _ArtistQuery;

  const new _();

  /// The cache key of the list (doc 05, `listKey`); two different queries
  /// never share one.
  String get listKey => _listKey('artists', [
    ('filter', filter?.value),
    ('sort', sortBy?.value),
    ('origin', origin?.value),
  ]);
}

/// What the songs list shows (`GET /library/tracks`).
@freezed
abstract class TrackQuery with _$TrackQuery {
  /// Creates a query; null fields take the server's defaults.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory TrackQuery({
    /// Only the tracks of this album.
    String? albumId,

    /// The order.
    TrackSort? sortBy,

    /// Which part of the library.
    LibraryOrigin? origin,
  }) = _TrackQuery;

  const new _();

  /// The cache key of the list (doc 05, `listKey`); two different queries
  /// never share one.
  String get listKey => _listKey('tracks', [
    ('albumId', albumId),
    ('sort', sortBy?.value),
    ('origin', origin?.value),
  ]);
}
