// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/shared/data/library/library_mappers.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// The network half of the library repositories: calls the generated
/// `LibraryClient` and returns domain values. `ApiException`
/// propagates unchanged.
final class LibraryRemoteSource {
  /// Creates a source over the generated library client.
  new(this._client);

  final api.LibraryClient _client;

  /// One page of artists (`GET /library/artists`); the server's next cursor
  /// is carried in the page.
  Future<api.OffsetPage<Artist>> artists({
    int? offset,
    int? limit,
    String? cursor,
    ArtistFilter? filter,
    ArtistSort? sortBy,
    LibraryOrigin? origin,
    String? query,
  }) async {
    final response = await _client.listArtists(
      offset: offset,
      limit: limit,
      cursor: cursor,
      filter: filter == null
          ? null
          : api.ListArtistsFilter.fromJson(filter.value),
      sortBy: sortBy == null
          ? null
          : api.ListArtistsSortBy.fromJson(sortBy.value),
      origin: origin == null
          ? null
          : api.ListArtistsOrigin.fromJson(origin.value),
      query2: query,
    );
    return api.OffsetPage(
      items: [for (final artist in response.artists) artistFromSummary(artist)],
      offset: response.offset,
      limit: response.limit,
      total: response.total,
      nextCursor: response.nextCursor,
    );
  }

  /// An artist with discography, top tracks and similar artists
  /// (`GET /library/artists/:id`).
  Future<ArtistDetail> artist(String id) async => artistDetailFromWire(
    await _client.getArtist(
      id: id,
      includeDiscography: true,
      includeTopTracks: true,
      includeSimilarArtists: true,
    ),
  );

  /// One page of albums (`GET /library/albums`).
  Future<api.OffsetPage<Album>> albums({
    String? artistId,
    int? offset,
    int? limit,
    AlbumFilter? filter,
    AlbumSort? sortBy,
    LibraryOrigin? origin,
  }) async {
    final response = await _client.listAlbums(
      artistId: artistId,
      offset: offset,
      limit: limit,
      filter: filter == null
          ? null
          : api.ListAlbumsFilter.fromJson(filter.value),
      sortBy: sortBy == null
          ? null
          : api.ListAlbumsSortBy.fromJson(sortBy.value),
      origin: origin == null
          ? null
          : api.ListAlbumsOrigin.fromJson(origin.value),
    );
    return api.OffsetPage(
      items: [for (final album in response.albums) albumFromSummary(album)],
      offset: response.offset,
      limit: response.limit,
      total: response.total,
    );
  }

  /// An album with its tracks (`GET /library/albums/:id`).
  Future<AlbumDetail> album(String id) async =>
      albumDetailFromWire(await _client.getAlbum(id: id, includeTracks: true));

  /// One page of tracks (`GET /library/tracks`).
  Future<api.OffsetPage<Track>> tracks({
    String? albumId,
    int? offset,
    int? limit,
    TrackSort? sortBy,
    LibraryOrigin? origin,
  }) async {
    final response = await _client.listTracks(
      albumId: albumId,
      offset: offset,
      limit: limit,
      sortBy: sortBy == null
          ? null
          : api.ListTracksSortBy.fromJson(sortBy.value),
      origin: origin == null
          ? null
          : api.ListTracksOrigin.fromJson(origin.value),
    );
    return api.OffsetPage(
      items: [
        for (final track in response.tracks) trackFromLibraryTrack(track),
      ],
      offset: response.offset,
      limit: response.limit,
      total: response.total,
    );
  }

  /// One page of liked tracks, newest first (`GET /library/liked`); pass the
  /// page's next cursor back as [cursor] for the following page.
  Future<api.KeysetPage<Track, LikedCursor>> liked({
    int? limit,
    LikedCursor? cursor,
  }) async {
    final response = await _client.listLikedTracks(
      limit: limit,
      cursorLikedAt: cursor?.likedAt.toUtc().toIso8601String(),
      cursorTrackId: cursor?.trackId,
    );
    final pagination = response.pagination;
    return api.KeysetPage(
      items: [for (final track in response.tracks) trackFromLikedTrack(track)],
      hasMore: pagination.hasMore,
      nextCursor: switch (pagination.nextCursor) {
        final next? when pagination.hasMore => LikedCursor(
          likedAt: next.likedAt.toUtc(),
          trackId: next.trackId,
        ),
        _ => null,
      },
      total: response.total,
    );
  }
}
