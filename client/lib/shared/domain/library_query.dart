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
