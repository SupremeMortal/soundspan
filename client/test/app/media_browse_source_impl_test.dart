// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/app/media_browse_source_impl.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../helpers/fake_media_browse_source.dart';
import '../helpers/fake_repositories.dart';

Album _album(int i) =>
    Album(id: 'a$i', title: 'Album $i', artistName: 'Band', artistId: 'b');

PlaylistSummary _playlist(String id) => PlaylistSummary(
  id: id,
  name: 'List $id',
  trackCount: 2,
  isOwner: true,
  isPublic: false,
);

void main() {
  late FakeRepositories repositories;
  late MediaBrowseSourceImpl source;

  setUp(() {
    repositories = FakeRepositories();
    source = MediaBrowseSourceImpl(
      library: () async => repositories.library,
      playlists: () async => repositories.playlists,
      home: () async => repositories.home,
      search: () async => repositories.search,
    );
  });

  test('recent is the top tracks of the recently listened artists, in '
      'order, up to the limit', () async {
    repositories.home.recent = const [
      RecentItem.artist(
        artist: Artist(id: 'x', name: 'X'),
      ),
      RecentItem.podcast(
        podcast: Podcast(id: 'pod', title: 'Pod'),
      ),
      RecentItem.artist(
        artist: Artist(id: 'y', name: 'Y'),
      ),
      RecentItem.artist(
        artist: Artist(id: 'z', name: 'Z'),
      ),
    ];
    repositories.library.artistDetails['x'] = ArtistDetail(
      artist: const Artist(id: 'x', name: 'X'),
      topTracks: [browseTrack('x0'), browseTrack('x1')],
    );
    repositories.library.artistDetails['y'] = ArtistDetail(
      artist: const Artist(id: 'y', name: 'Y'),
      topTracks: [browseTrack('y0'), browseTrack('y1')],
    );

    final tracks = await source.recent(limit: 3);

    expect([for (final t in tracks) t.meta.title], ['x0', 'x1', 'y0']);
    expect(repositories.library.readCalls['artist'], 2);
  });

  test('recent skips an artist that fails to load', () async {
    repositories.home.recent = const [
      RecentItem.artist(
        artist: Artist(id: 'gone', name: 'Gone'),
      ),
      RecentItem.artist(
        artist: Artist(id: 'y', name: 'Y'),
      ),
    ];
    repositories.library.artistDetails['y'] = ArtistDetail(
      artist: const Artist(id: 'y', name: 'Y'),
      topTracks: [browseTrack('y0')],
    );

    final tracks = await source.recent();

    expect([for (final t in tracks) t.meta.title], ['y0']);
  });

  test('playlists lists every playlist with its count', () async {
    repositories.playlists.playlistList = [_playlist('p1'), _playlist('p2')];

    final playlists = await source.playlists();

    expect([for (final p in playlists) p.id], ['p1', 'p2']);
    expect(playlists.first.name, 'List p1');
    expect(playlists.first.trackCount, 2);
  });

  test('playlist tracks leave out items the server marks not '
      'playable', () async {
    repositories.playlists.playlistDetails['p1'] = PlaylistDetail(
      summary: _playlist('p1'),
      items: [
        PlaylistItem(
          id: 'i0',
          sort: 0,
          track: browseTrack('ok', playbackId: 'k'),
          isPlayable: true,
        ),
        PlaylistItem(
          id: 'i1',
          sort: 1,
          track: browseTrack('no', playbackId: 'n'),
          isPlayable: false,
        ),
      ],
    );

    final tracks = await source.playlistTracks('p1');

    expect([for (final t in tracks) t.meta.title], ['ok']);
  });

  test('albums are read by name up to the limit', () async {
    repositories.library.albumList = [for (var i = 0; i < 70; i++) _album(i)];

    final albums = await source.albums(limit: 65);

    expect(albums, hasLength(65));
    expect(albums.first.id, 'a0');
    expect(albums.first.title, 'Album 0');
    expect(albums.first.artist, 'Band');
    expect(
      repositories.library.queries.single,
      const AlbumQuery(sortBy: AlbumSort.name),
    );
    expect(repositories.library.sources.single.disposed, isTrue);
  });

  test('album tracks come from the album detail', () async {
    repositories.library.albumDetails['a1'] = AlbumDetail(
      album: _album(1),
      tracks: [browseTrack('t0'), browseTrack('t1')],
      owned: true,
    );

    final tracks = await source.albumTracks('a1');

    expect([for (final t in tracks) t.meta.title], ['t0', 't1']);
  });

  test('search reads the library tracks of the query up to the '
      'limit', () async {
    repositories.search.results['q'] = SearchResults(
      library: LibrarySearchResults(
        tracks: [browseTrack('s0'), browseTrack('s1'), browseTrack('s2')],
      ),
    );

    final tracks = await source.searchTracks('q', limit: 2);

    expect([for (final t in tracks) t.meta.title], ['s0', 's1']);
    expect(repositories.search.searches.single, ('q', SearchScope.library));
  });
}
