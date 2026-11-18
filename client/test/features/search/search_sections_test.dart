// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/features/search/domain/search_sections.dart';
import 'package:soundspan/shared/domain/domain.dart';

Track _track(String title, {String? playbackId}) => Track(
  meta: TrackMeta(title: title, artist: 'A', album: 'B', durationSec: 60),
  playbackId: playbackId == null ? null : PlaybackId(playbackId),
);

Artist _artist(String name) => Artist(id: 'ar:$name', name: name);

Album _album(String title) =>
    Album(id: 'al:$title', title: title, artistName: 'A', artistId: 'ar:A');

PodcastSummary _podcast(String title) =>
    PodcastSummary(id: 'po:$title', title: title);

PlaylistSummary _playlist(String name) => PlaylistSummary(
  id: 'pl:$name',
  name: name,
  trackCount: 1,
  isOwner: true,
  isPublic: false,
);

List<String> _titles(SearchSection? section) => [
  for (final item in section?.items ?? const <SearchItem>[]) _title(item),
];

String _title(SearchItem item) => switch (item) {
  SearchTrackItem(:final track) => track.meta.title,
  SearchArtistItem(:final artist) => artist.name,
  SearchAlbumItem(:final album) => album.title,
  SearchPlaylistItem(:final playlist) => playlist.name,
  SearchPodcastItem(:final podcast) => podcast.title,
};

void main() {
  final library = LibrarySearchResults(
    artists: [_artist('Lib Artist')],
    albums: [_album('Lib Album')],
    tracks: [
      _track('Lib Song 1', playbackId: 'p1'),
      _track('Lib Song 2', playbackId: 'p2'),
    ],
    podcasts: [_podcast('Lib Pod')],
  );
  final discover = DiscoverResults(
    hits: [
      SearchHit.track(track: _track('Cat Song 2', playbackId: 'p2')),
      SearchHit.artist(artist: _artist('Cat Artist')),
      SearchHit.track(track: _track('Cat Song 3', playbackId: 'p3')),
      SearchHit.album(album: _album('Cat Album')),
      SearchHit.podcast(podcast: _podcast('Cat Pod')),
    ],
  );
  final playlists = [_playlist('Road Trip'), _playlist('Gym')];

  SearchSections build(
    SearchScope scope, {
    LibrarySearchResults? lib,
    DiscoverResults? disc,
    String query = 'road',
  }) => buildSearchSections(
    lib ?? library,
    disc ?? discover,
    playlists,
    query,
    scope,
  );

  test('sections come in the documented order', () {
    final sections = build(SearchScope.all);
    expect(
      [for (final s in sections.sections) s.kind],
      [
        SearchSectionKind.songs,
        SearchSectionKind.artists,
        SearchSectionKind.albums,
        SearchSectionKind.playlists,
        SearchSectionKind.podcasts,
      ],
    );
    expect(sections.topResult, isNotNull);
  });

  test('library items precede catalogue items and server order is kept '
      'inside each group', () {
    final sections = build(SearchScope.all);
    expect(_titles(sections.section(SearchSectionKind.artists)), [
      'Lib Artist',
      'Cat Artist',
    ]);
    expect(_titles(sections.section(SearchSectionKind.albums)), [
      'Lib Album',
      'Cat Album',
    ]);
    expect(_titles(sections.section(SearchSectionKind.podcasts)), [
      'Lib Pod',
      'Cat Pod',
    ]);
  });

  test('a track in both groups appears once', () {
    // The top result is the first song; the rest of Songs follows it.
    final sections = build(SearchScope.all);
    expect(_title(sections.topResult!), 'Lib Song 1');
    expect(_titles(sections.section(SearchSectionKind.songs)), [
      'Lib Song 2',
      'Cat Song 3',
    ]);
  });

  test('each section is capped at 5 with the full list available', () {
    final sections = build(
      SearchScope.library,
      lib: LibrarySearchResults(
        albums: [for (var i = 0; i < 8; i++) _album('Album $i')],
      ),
    );
    // The first album is the top result.
    final albums = sections.section(SearchSectionKind.albums)!;
    expect(albums.items, hasLength(7));
    expect(albums.preview, hasLength(SearchSection.previewLength));
    expect(albums.hasMore, isTrue);
    expect(_title(albums.preview.first), 'Album 1');
  });

  test('top result: exact artist match, else first song, else first album, '
      'else first artist', () {
    SearchItem? top(LibrarySearchResults lib, String query) =>
        build(SearchScope.library, lib: lib, query: query).topResult;

    final all = LibrarySearchResults(
      artists: [_artist('Milestones'), _artist('Miles')],
      albums: [_album('Kind of Blue')],
      tracks: [_track('So What', playbackId: 'p1')],
    );
    expect(_title(top(all, 'MILES')!), 'Miles');
    expect(_title(top(all, 'mil')!), 'So What');
    expect(_title(top(all.copyWith(tracks: const []), 'mil')!), 'Kind of Blue');
    expect(
      _title(top(all.copyWith(tracks: const [], albums: const []), 'mil')!),
      'Milestones',
    );
    expect(top(const LibrarySearchResults(), 'mil'), isNull);
  });

  test('the top result is not repeated in its section', () {
    final sections = build(SearchScope.all, query: 'lib artist');
    expect(_title(sections.topResult!), 'Lib Artist');
    expect(_titles(sections.section(SearchSectionKind.artists)), [
      'Cat Artist',
    ]);
    expect(_titles(sections.section(SearchSectionKind.songs)), [
      'Lib Song 1',
      'Lib Song 2',
      'Cat Song 3',
    ]);
  });

  test('playlists match by name without case', () {
    final sections = build(SearchScope.all, query: 'ROAD');
    expect(_titles(sections.section(SearchSectionKind.playlists)), [
      'Road Trip',
    ]);
  });

  test('scope Library drops catalogue items, Discover drops library items '
      'and playlists, Podcasts keeps only podcasts', () {
    final lib = build(SearchScope.library);
    expect(_titles(lib.section(SearchSectionKind.artists)), ['Lib Artist']);
    expect(_titles(lib.section(SearchSectionKind.playlists)), ['Road Trip']);
    expect(_titles(lib.section(SearchSectionKind.podcasts)), ['Lib Pod']);

    final disc = build(SearchScope.discover);
    expect(_title(disc.topResult!), 'Cat Song 2');
    expect(_titles(disc.section(SearchSectionKind.songs)), ['Cat Song 3']);
    expect(_titles(disc.section(SearchSectionKind.artists)), ['Cat Artist']);
    expect(disc.section(SearchSectionKind.playlists), isNull);
    expect(_titles(disc.section(SearchSectionKind.podcasts)), ['Cat Pod']);

    final pods = build(SearchScope.podcasts);
    expect(pods.topResult, isNull);
    expect(
      [for (final s in pods.sections) s.kind],
      [SearchSectionKind.podcasts],
    );
    expect(_titles(pods.section(SearchSectionKind.podcasts)), ['Lib Pod']);
  });

  test('albums and artists of the library search carry their library id; '
      'catalogue ones carry none', () {
    final sections = build(SearchScope.all, query: 'x');
    final artists = sections.section(SearchSectionKind.artists)!.items;
    expect(
      [for (final a in artists) (a as SearchArtistItem).libraryId],
      ['ar:Lib Artist', null],
    );
    final albums = sections.section(SearchSectionKind.albums)!.items;
    expect(
      [for (final a in albums) (a as SearchAlbumItem).libraryId],
      ['al:Lib Album', null],
    );
  });

  test('no results is empty', () {
    final sections = build(
      SearchScope.all,
      lib: const LibrarySearchResults(),
      disc: const DiscoverResults(),
      query: 'zzz',
    );
    expect(sections.isEmpty, isTrue);
  });
}
