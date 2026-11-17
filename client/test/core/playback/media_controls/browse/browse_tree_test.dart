// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/media_controls/browse/browse_tree.dart';
import 'package:soundspan/core/playback/media_controls/browse/media_browse_source.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../../../helpers/fake_media_browse_source.dart';

const _titles = BrowseRootTitles(
  recent: 'Recent',
  playlists: 'Playlists',
  albums: 'Albums',
);

const _oddPlaylistId = 'p/1 two';

FakeMediaBrowseSource _source() => FakeMediaBrowseSource()
  ..recentTracks = [
    browseTrack('r0', playbackId: 'pr0'),
    browseTrack('r1', playbackId: 'pr1'),
  ]
  ..playlistList = const [
    BrowsePlaylist(id: 'p1', name: 'Mix', trackCount: 2),
    BrowsePlaylist(id: _oddPlaylistId, name: 'Odd', trackCount: 1),
  ]
  ..playlistTrackMap = {
    'p1': [
      browseTrack('p0', playbackId: 'pp0'),
      browseTrack('p1', playbackId: 'pp1'),
    ],
    _oddPlaylistId: [browseTrack('o0', playbackId: 'po0')],
  }
  ..albumList = [
    for (var i = 0; i < 250; i++)
      BrowseAlbum(id: 'a$i', title: 'Album $i', artist: 'Band'),
  ]
  ..albumTrackMap = {
    'a1': [
      browseTrack('t0', playbackId: 'pt0'),
      browseTrack('gone'),
      browseTrack('t1', playbackId: 'pt1'),
      browseTrack('t2', playbackId: 'pt2'),
    ],
  }
  ..searchHits = {
    'daft punk': [
      browseTrack('d0', playbackId: 'pd0'),
      browseTrack('d1', playbackId: 'pd1'),
    ],
  };

BrowseTree _tree([FakeMediaBrowseSource? source]) =>
    BrowseTree(source: source ?? _source(), titles: _titles);

List<String> _titlesOf(List<Track> tracks) => [
  for (final t in tracks) t.meta.title,
];

void main() {
  group('children', () {
    test('root returns Recent, Playlists and Albums in order', () async {
      final nodes = await _tree().children('root');

      expect([for (final n in nodes) n.id], ['recent', 'playlists', 'albums']);
      expect(
        [for (final n in nodes) n.title],
        ['Recent', 'Playlists', 'Albums'],
      );
      expect(nodes.every((n) => !n.playable), isTrue);
    });

    test('albums returns at most 200 browsable album nodes', () async {
      final source = _source();
      final nodes = await _tree(source).children('albums');

      expect(nodes, hasLength(200));
      expect(source.lastAlbumLimit, 200);
      expect(nodes.every((n) => !n.playable), isTrue);
      expect(nodes.first.id, 'album/a0');
      expect(nodes.first.title, 'Album 0');
      expect(nodes.first.subtitle, 'Band');
    });

    test('an album returns its playable tracks, indexed over the '
        'filtered list', () async {
      final nodes = await _tree().children('album/a1');

      expect(
        [for (final n in nodes) n.id],
        ['album/a1/0', 'album/a1/1', 'album/a1/2'],
      );
      expect([for (final n in nodes) n.title], ['t0', 't1', 't2']);
      expect(nodes.first.subtitle, 'Artist t0');
      expect(nodes.every((n) => n.playable), isTrue);
    });

    test('recent returns its tracks as recent/tracks/<index>', () async {
      final nodes = await _tree().children('recent');

      expect(
        [for (final n in nodes) n.id],
        ['recent/tracks/0', 'recent/tracks/1'],
      );
      expect(nodes.every((n) => n.playable), isTrue);
    });

    test('a playlist id with a slash and a space round-trips', () async {
      final tree = _tree();
      final playlists = await tree.children('playlists');
      final odd = playlists.singleWhere((n) => n.title == 'Odd');

      expect(odd.id, 'playlist/p%2F1%20two');
      expect(odd.playable, isFalse);

      final tracks = await tree.children(odd.id);
      expect([for (final n in tracks) n.id], ['playlist/p%2F1%20two/0']);
      expect(tracks.single.title, 'o0');

      final request = await tree.resolve(tracks.single.id);
      expect(request?.context.id, _oddPlaylistId);
      expect(_titlesOf(request!.tracks), ['o0']);
    });

    test('an unknown or malformed id returns nothing', () async {
      final tree = _tree();

      expect(await tree.children('nonsense'), isEmpty);
      expect(await tree.children('album/'), isEmpty);
      expect(await tree.children('album/%E0%A4%A'), isEmpty);
      expect(await tree.children('album/a1/0'), isEmpty);
    });

    test('a failing source returns nothing', () async {
      final tree = _tree(_source()..failing = true);

      expect(await tree.children('albums'), isEmpty);
      expect(await tree.children('album/a1'), isEmpty);
      expect(await tree.children('recent'), isEmpty);
    });
  });

  group('resolve', () {
    test('an album track yields the playable album tracks from that '
        'index', () async {
      final request = await _tree().resolve('album/a1/2');

      expect(_titlesOf(request!.tracks), ['t0', 't1', 't2']);
      expect(request.startIndex, 2);
      expect(request.kind, QueueContextKind.album);
      expect(request.context.id, 'a1');
    });

    test('recent, playlist and search tracks resolve', () async {
      final tree = _tree();

      final recent = await tree.resolve('recent/tracks/0');
      expect(_titlesOf(recent!.tracks), ['r0', 'r1']);
      expect(recent.startIndex, 0);
      expect(recent.kind, QueueContextKind.library);

      final playlist = await tree.resolve('playlist/p1/1');
      expect(_titlesOf(playlist!.tracks), ['p0', 'p1']);
      expect(playlist.startIndex, 1);
      expect(playlist.kind, QueueContextKind.playlist);
      expect(playlist.context.id, 'p1');

      final search = await tree.resolve('search/daft%20punk/0');
      expect(_titlesOf(search!.tracks), ['d0', 'd1']);
      expect(search.startIndex, 0);
      expect(search.kind, QueueContextKind.search);
    });

    test('an index out of range, a browsable id and a raw playback id '
        'resolve to nothing', () async {
      final tree = _tree();

      expect(await tree.resolve('album/a1/3'), isNull);
      expect(await tree.resolve('album/a1/-1'), isNull);
      expect(await tree.resolve('album/a1'), isNull);
      expect(await tree.resolve('albums'), isNull);
      expect(await tree.resolve('root'), isNull);
      expect(await tree.resolve('pt0'), isNull);
    });

    test('a failing source resolves to nothing', () async {
      expect(
        await _tree(_source()..failing = true).resolve('album/a1/0'),
        isNull,
      );
    });
  });

  group('search', () {
    test('a blank query resolves to recent from the start', () async {
      final tree = _tree();

      for (final query in ['', '   ']) {
        final request = await tree.search(query);
        expect(_titlesOf(request!.tracks), ['r0', 'r1']);
        expect(request.startIndex, 0);
        expect(request.kind, QueueContextKind.library);
      }
    });

    test('a query resolves to its hits from the start', () async {
      final request = await _tree().search('daft punk');

      expect(_titlesOf(request!.tracks), ['d0', 'd1']);
      expect(request.startIndex, 0);
      expect(request.kind, QueueContextKind.search);
    });

    test('a query without hits resolves to nothing', () async {
      expect(await _tree().search('x'), isNull);
    });

    test('the result nodes are playable search ids', () async {
      final nodes = await _tree().searchResults('daft punk');

      expect(
        [for (final n in nodes) n.id],
        ['search/daft%20punk/0', 'search/daft%20punk/1'],
      );
      expect(nodes.every((n) => n.playable), isTrue);
    });
  });
}
