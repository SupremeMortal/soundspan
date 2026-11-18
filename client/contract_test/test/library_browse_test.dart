// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Contract group "Library and browse" of doc 03's endpoint inventory: every
/// M0 operation the browse screens call, plus `GET /mixes` and
/// `GET /podcasts/discover/top`, against the seeded server with response
/// validation on.
@Tags(['contract'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

import 'support.dart';

/// The fixture artist with two albums, one of them on two discs.
const _artistName = 'Contract Aurora';

/// The fixture album on two discs.
const _multiDiscAlbum = 'Long Evening';

/// The width and height of a PNG or baseline/progressive JPEG image, or null
/// when [bytes] is neither.
(int, int)? _imageSize(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  if (bytes.length >= 24 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47) {
    return (data.getUint32(16), data.getUint32(20));
  }
  if (bytes.length < 4 || bytes[0] != 0xff || bytes[1] != 0xd8) return null;
  var at = 2;
  while (at + 9 < bytes.length) {
    if (bytes[at] != 0xff) return null;
    final marker = bytes[at + 1];
    final length = data.getUint16(at + 2);
    if (marker >= 0xc0 && marker <= 0xc3) {
      return (data.getUint16(at + 7), data.getUint16(at + 5));
    }
    at += 2 + length;
  }
  return null;
}

/// GETs [uri] with [headers] and returns the status, content type and body.
Future<(int, String?, Uint8List)> _get(
  Uri uri, [
  Map<String, String> headers = const {},
]) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    headers.forEach(request.headers.set);
    final response = await request.close();
    final builder = await response.fold<BytesBuilder>(
      BytesBuilder(copy: false),
      (builder, chunk) => builder..add(chunk),
    );
    return (
      response.statusCode,
      response.headers.contentType?.mimeType,
      builder.takeBytes(),
    );
  } finally {
    client.close(force: true);
  }
}

void main() {
  late ContractCredentials credentials;
  late SoundspanApi api;

  setUp(() async {
    credentials = ContractCredentials.load();
    api = await signedInApi(credentials, credentials.listener);
  });

  Future<ArtistSummary> fixtureArtist() async {
    final page = await api.send(
      (rest) => rest.library2.listArtists(limit: 100),
    );
    return page.artists.singleWhere((artist) => artist.name == _artistName);
  }

  Future<AlbumSummary> fixtureAlbum(String title) async {
    final page = await api.send((rest) => rest.library2.listAlbums(limit: 100));
    return page.albums.singleWhere((album) => album.title == title);
  }

  group('artists', () {
    test('offset paging returns total and a second page without overlap; a '
        'returned nextCursor is accepted when passed back', () async {
      final first = await api.send(
        (rest) => rest.library2.listArtists(limit: 2, offset: 0),
      );
      final second = await api.send(
        (rest) => rest.library2.listArtists(limit: 2, offset: 2),
      );

      expect(first.total, 3);
      expect(first.artists, hasLength(2));
      expect(second.artists, hasLength(1));
      final firstIds = {for (final artist in first.artists) artist.id};
      expect(firstIds.intersection({second.artists.single.id}), isEmpty);

      final cursor = first.nextCursor;
      if (cursor != null) {
        final next = await api.send(
          (rest) => rest.library2.listArtists(limit: 2, cursor: cursor),
        );
        expect(
          {for (final artist in next.artists) artist.id}.intersection(firstIds),
          isEmpty,
        );
      }
    });

    test('artist detail decodes with discography, top tracks and similar '
        'artists', () async {
      final artist = await fixtureArtist();

      final detail = await api.send(
        (rest) => rest.library2.getArtist(
          id: artist.id,
          includeDiscography: true,
          includeTopTracks: true,
          includeSimilarArtists: true,
        ),
      );

      expect(detail.id, artist.id);
      expect(detail.name, _artistName);
      expect(detail.albums, isNotNull);
      expect(
        detail.albums!.map((album) => album.title).toSet(),
        containsAll(<String>['First Light', _multiDiscAlbum]),
      );
      final libraryAlbums = detail.albums!.where(
        (album) => album.source == ArtistAlbumSource.database,
      );
      expect(libraryAlbums, isNotEmpty);
      for (final album in libraryAlbums) {
        expect(album.primaryType, isNotNull, reason: album.title);
      }
    });
  });

  group('albums', () {
    test('albums filtered by artistId belong to that artist', () async {
      final artist = await fixtureArtist();

      final page = await api.send(
        (rest) => rest.library2.listAlbums(artistId: artist.id),
      );

      expect(page.albums, hasLength(2));
      for (final album in page.albums) {
        expect(album.artistId, artist.id);
      }
    });

    test(
      'tracks of the multi-disc album carry disc and track numbers',
      () async {
        final album = await fixtureAlbum(_multiDiscAlbum);

        final detail = await api.send(
          (rest) => rest.library2.getAlbum(id: album.id, includeTracks: true),
        );

        final tracks = detail.tracks!;
        expect(tracks, hasLength(7));
        expect({for (final track in tracks) track.discNo}, {1, 2});
        for (final track in tracks) {
          expect(track.discNo, isNotNull);
          expect(track.trackNo, isNotNull);
        }
      },
    );
  });

  group('tracks', () {
    test('a page of tracks decodes with the library total', () async {
      final page = await api.send(
        (rest) => rest.library2.listTracks(limit: 5, offset: 0),
      );

      expect(page.total, 40);
      expect(page.tracks, hasLength(5));
      for (final track in page.tracks) {
        expect(track.playbackId, isNotNull);
      }
    });

    test('shuffle returns at most limit tracks', () async {
      final shuffled = await api.send(
        (rest) => rest.library2.listShuffledTracks(limit: 3),
      );

      expect(shuffled.tracks.length, inInclusiveRange(1, 3));
      expect(shuffled.total, greaterThanOrEqualTo(shuffled.tracks.length));
      for (final track in shuffled.tracks) {
        expect(track.playbackId, isNotNull);
      }
    });

    test('liked: keyset paging with limit 2 returns all three tracks across '
        'two pages with hasMore false at the end', () async {
      final first = await api.send(
        (rest) => rest.library2.listLikedTracks(limit: 2),
      );
      expect(first.tracks, hasLength(2));
      expect(first.pagination.hasMore, isTrue);
      final cursor = first.pagination.nextCursor;
      expect(cursor, isNotNull);

      final second = await api.send(
        (rest) => rest.library2.listLikedTracks(
          limit: 2,
          cursorLikedAt: cursor!.likedAt.toUtc().toIso8601String(),
          cursorTrackId: cursor.trackId,
        ),
      );

      expect(second.tracks, hasLength(1));
      expect(second.pagination.hasMore, isFalse);
      expect({
        for (final track in [...first.tracks, ...second.tracks]) track.id,
      }, hasLength(3));
      expect(first.total, 3);
    });
  });

  group('home', () {
    test('recently listened holds the artist of the seeded play', () async {
      final recent = await api.send(
        (rest) => rest.library2.listRecentlyListened(limit: 10),
      );

      expect(recent.items, isNotEmpty);
      expect(
        recent.items.map((item) => item.type),
        contains(RecentlyListenedItemType.artist),
      );
    });

    test('recently added lists the fixture artists', () async {
      final added = await api.send(
        (rest) => rest.library2.listRecentlyAdded(limit: 10),
      );

      expect(added.artists.map((artist) => artist.name), contains(_artistName));
    });

    test('mixes: decodes, or is FeatureDisabled with status 404 and code '
        'FEATURE_DISABLED', () async {
      try {
        final mixes = await api.send((rest) => rest.discovery.listMixes());
        for (final mix in mixes) {
          expect(mix.id, isNotEmpty);
        }
      } on FeatureDisabled catch (error) {
        expect(error.status, 404);
        expect(error.code, 'FEATURE_DISABLED');
      }
    });

    test('top podcasts: decodes, or fails as Upstream/ServerError (the server '
        'depends on an external directory)', () async {
      try {
        final podcasts = await api.send(
          (rest) => rest.podcasts.listTopPodcasts(limit: 5),
        );
        for (final podcast in podcasts) {
          expect(podcast.id, isNotEmpty);
        }
      } on Upstream {
        // The directory could not be reached.
      } on ServerError {
        // The directory could not be reached.
      }
    });
  });

  group('cover art', () {
    test('ImageUrls.cover with credentials returns an image at the snapped '
        'size; without credentials 401', () async {
      final album = await fixtureAlbum(_multiDiscAlbum);
      final ref = album.coverArt;
      expect(ref, isNotNull, reason: 'fixture albums carry embedded art');
      final uri = ImageUrls(credentials.baseUrl)
          .cover(ref!, logicalPx: 100, devicePixelRatio: 1);
      expect(uri.queryParameters['size'], '128');
      final login = await logIn(credentials, credentials.listener);

      final (status, type, body) = await _get(
        uri,
        authHeaders(
          JwtCredentials(
            accessToken: login.token,
            refreshToken: login.refreshToken,
          ),
        ),
      );
      final (anonymousStatus, _, _) = await _get(uri);

      expect(status, 200);
      expect(type, startsWith('image/'));
      final size = _imageSize(body);
      expect(size, isNotNull, reason: 'a $type body of ${body.length} bytes');
      final (width, height) = size!;
      expect(width > height ? width : height, 128);
      expect(anonymousStatus, 401);
    });
  });

  group('playlists', () {
    test('playlists lists the seeded playlist', () async {
      final playlists = await api.send(
        (rest) => rest.playlists.listPlaylists(),
      );

      final seeded = playlists.singleWhere(
        (playlist) => playlist.id == credentials.playlistId,
      );
      expect(seeded.trackCount, 5);
      expect(seeded.isOwner, isTrue);
    });

    test('playlist detail lists the seeded items in order with '
        'playback.isPlayable', () async {
      final tracks = await api.send(
        (rest) => rest.library2.listTracks(limit: 5, offset: 0),
      );

      final detail = await api.send(
        (rest) => rest.playlists.getPlaylist(id: credentials.playlistId),
      );

      final items = [...detail.items]..sort((a, b) => a.sort.compareTo(b.sort));
      expect(
        [for (final item in items) item.track?.playbackId],
        [for (final track in tracks.tracks) track.playbackId],
      );
      for (final item in items) {
        expect(item.playback.isPlayable, isTrue);
      }
    });
  });

  group('search', () {
    test('search finds a seeded track, album and artist by name', () async {
      final byTrack = await api.send(
        (rest) => rest.search.search(q: 'Aster Tone'),
      );
      final byAlbum = await api.send(
        (rest) => rest.search.search(q: 'First Light'),
      );
      final byArtist = await api.send(
        (rest) => rest.search.search(q: _artistName),
      );

      expect(
        byTrack.tracks.map((track) => track.title),
        contains('Aster Tone'),
      );
      expect(
        byAlbum.albums.map((album) => album.title),
        contains('First Light'),
      );
      expect(
        byArtist.artists.map((artist) => artist.name),
        contains(_artistName),
      );
    });

    test('search/discover decodes with optional providers disabled', () async {
      final results = await api.send(
        (rest) => rest.search.searchDiscover(q: _artistName),
      );

      expect(results.results, isA<List<DiscoverResult>>());
    });
  });

  group('writes', () {
    // The admin account: no other contract test reads its likes, album
    // preferences or playlists, so these writes cannot race the listener's
    // seeded state.
    late SoundspanApi admin;

    setUp(
      () async => admin = await signedInApi(credentials, credentials.admin),
    );

    Future<List<String>> playbackIds(int count) async {
      final page = await admin.send(
        (rest) => rest.library2.listTracks(limit: count, offset: 10),
      );
      return [for (final track in page.tracks) track.playbackId!];
    }

    Future<List<String>> likedPlaybackIds() async {
      final liked = await admin.send(
        (rest) => rest.library2.listLikedTracks(limit: 100),
      );
      return [for (final track in liked.tracks) ?track.playbackId];
    }

    Future<TrackPreferenceResponse> setTrackPreference(
      String playbackId,
      PreferenceSignal signal,
    ) => admin.send(
      (rest) => rest.library2.setTrackPreference(
        body: TrackPreferenceRequest(playbackId: playbackId, signal: signal),
      ),
    );

    test('a track liked by playbackId is listed as liked; cleared, it is '
        'gone', () async {
      final playbackId = (await playbackIds(1)).single;
      addTearDown(() => setTrackPreference(playbackId, PreferenceSignal.clear));

      final liked = await setTrackPreference(
        playbackId,
        PreferenceSignal.thumbsUp,
      );
      expect(liked.state, PreferenceState.liked);
      expect(liked.likedAt, isNotNull);
      expect(await likedPlaybackIds(), contains(playbackId));

      final cleared = await setTrackPreference(
        playbackId,
        PreferenceSignal.clear,
      );
      expect(cleared.state, PreferenceState.neutral);
      expect(await likedPlaybackIds(), isNot(contains(playbackId)));
    });

    test('an album preference answers the state it set and the album '
        'answers it on the next fetch', () async {
      final album = await fixtureAlbum(_multiDiscAlbum);
      Future<AlbumPreferenceResponse> setAlbum(PreferenceSignal signal) =>
          admin.send(
            (rest) => rest.library2.setAlbumPreference(
              id: album.id,
              body: AlbumPreferenceRequest(signal: signal),
            ),
          );
      addTearDown(() => setAlbum(PreferenceSignal.clear));

      Future<PreferenceState?> albumPreference() async => (await admin.send(
        (rest) => rest.library2.getAlbum(id: album.id, includeTracks: false),
      )).preference;

      final liked = await setAlbum(PreferenceSignal.thumbsUp);
      expect(liked.albumId, album.id);
      expect(liked.state, PreferenceState.liked);
      expect(await albumPreference(), PreferenceState.liked);

      final cleared = await setAlbum(PreferenceSignal.clear);
      expect(cleared.state, PreferenceState.neutral);
      expect(await albumPreference(), PreferenceState.neutral);
    });

    test('a playlist is created, renamed, filled, reordered and emptied by '
        'playbackId, then deleted', () async {
      final ids = await playbackIds(3);
      final created = await admin.send(
        (rest) => rest.playlists.createPlaylist(
          body: const CreatePlaylistRequest(name: 'Contract writes'),
        ),
      );
      var deleted = false;
      addTearDown(() async {
        if (!deleted) {
          await admin.send(
            (rest) => rest.playlists.deletePlaylist(id: created.id),
          );
        }
      });
      expect(created.name, 'Contract writes');
      expect(created.isPublic, isFalse);

      final renamed = await admin.send(
        (rest) => rest.playlists.updatePlaylist(
          id: created.id,
          body: const UpdatePlaylistRequest(name: 'Contract renamed'),
        ),
      );
      expect(renamed.name, 'Contract renamed');

      for (final playbackId in ids) {
        final added = await admin.send(
          (rest) => rest.playlists.addPlaylistItem(
            id: created.id,
            body: AddPlaylistItemRequest(playbackId: playbackId),
          ),
        );
        expect(added.asPlaylistItem?.track?.playbackId, playbackId);
      }

      Future<List<String?>> order() async {
        final detail = await admin.send(
          (rest) => rest.playlists.getPlaylist(id: created.id),
        );
        expect(detail.name, 'Contract renamed');
        final items = [...detail.items]
          ..sort((a, b) => a.sort.compareTo(b.sort));
        return [for (final item in items) item.track?.playbackId];
      }

      expect(await order(), ids);

      final reordered = [ids[2], ids[0], ids[1]];
      await admin.send(
        (rest) => rest.playlists.reorderPlaylistItems(
          id: created.id,
          body: ReorderPlaylistItemsRequest(playbackIds: reordered),
        ),
      );
      expect(await order(), reordered);

      await admin.send(
        (rest) => rest.playlists.removePlaylistItem(
          id: created.id,
          playbackId: Uri.encodeComponent(ids[0]),
        ),
      );
      expect(await order(), [ids[2], ids[1]]);

      await admin.send((rest) => rest.playlists.deletePlaylist(id: created.id));
      deleted = true;
      await expectLater(
        admin.send((rest) => rest.playlists.getPlaylist(id: created.id)),
        throwsA(isA<NotFound>()),
      );
    });

    test('adding an unknown playbackId with metadata is NotFound '
        'TRACK_NOT_FOUND', () async {
      final created = await admin.send(
        (rest) => rest.playlists.createPlaylist(
          body: const CreatePlaylistRequest(name: 'Contract unknown track'),
        ),
      );
      addTearDown(
        () =>
            admin.send((rest) => rest.playlists.deletePlaylist(id: created.id)),
      );

      await expectLater(
        admin.send(
          (rest) => rest.playlists.addPlaylistItem(
            id: created.id,
            body: const AddPlaylistItemRequest(
              playbackId: 't.contract-unknown-track',
              metadata: PlaybackMetadata(
                title: 'Missing',
                artist: 'Nobody',
                album: 'Nowhere',
                durationSec: 30,
              ),
            ),
          ),
        ),
        throwsA(
          isA<NotFound>().having(
            (error) => error.code,
            'code',
            'TRACK_NOT_FOUND',
          ),
        ),
      );
    });
  });
}
