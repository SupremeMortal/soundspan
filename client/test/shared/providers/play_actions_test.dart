// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/queue/queue_reducer.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/play_actions.dart';
import 'package:soundspan_api/soundspan_api.dart' show ServerError;

import '../../core/playback/controller/controller_harness.dart';
import '../../helpers/fake_repositories.dart';

/// Track [id], playable unless [playable] is false.
Track _track(String id, {bool playable = true}) => Track(
  meta: TrackMeta(
    title: 'Song $id',
    artist: 'Band',
    album: 'Record',
    durationSec: 10,
  ),
  playbackId: playable ? PlaybackId('pb-$id') : null,
);

const QueueContext _context = QueueContext(
  kind: QueueContextKind.album,
  id: 'al-1',
  title: 'Record',
);

void main() {
  late ControllerHarness harness;
  late FakeLibraryRepository library;
  late FakePlaylistRepository playlists;
  late List<PlayNotice> notices;
  late PlayActions actions;

  PlaybackController controller() => harness.controller;

  /// The playback ids of the queue in play order.
  List<String> played() {
    final queue = controller().snapshot.queue;
    return [
      for (final index in queue.playOrder)
        switch (queue.items[index]) {
          TrackQueueItem(:final track) => track.playbackId!.value,
          EpisodeQueueItem() => 'episode',
        },
    ];
  }

  String? current() => switch (controller().snapshot.current) {
    TrackQueueItem(:final track) => track.playbackId!.value,
    _ => null,
  };

  setUp(() {
    harness = ControllerHarness(playAny: true);
    library = FakeLibraryRepository();
    playlists = FakePlaylistRepository();
    notices = [];
    actions = PlayActions(
      controller: harness.controller,
      library: () async => library,
      playlists: () async => playlists,
      notify: notices.add,
      random: Random(1),
    );
  });

  tearDown(() => harness.controller.dispose());

  group('playTracks', () {
    test('queues the list with the context and starts at the index', () async {
      await actions.playTracks(
        [_track('a'), _track('b'), _track('c')],
        startIndex: 1,
        context: _context,
      );
      await harness.settle();

      expect(played(), ['pb-a', 'pb-b', 'pb-c']);
      expect(current(), 'pb-b');
      expect(controller().snapshot.playing, isTrue);
      expect(controller().snapshot.queue.context, _context);
      for (final item in controller().snapshot.queue.items) {
        expect((item as TrackQueueItem).context, _context);
      }
    });

    test('an unplayable row before the start does not shift it', () async {
      await actions.playTracks(
        [_track('a', playable: false), _track('b'), _track('c')],
        startIndex: 2,
        context: _context,
      );
      await harness.settle();

      expect(played(), ['pb-b', 'pb-c']);
      expect(current(), 'pb-c');
    });

    test('an unplayable start does nothing', () async {
      await actions.playTracks(
        [_track('a'), _track('b', playable: false)],
        startIndex: 1,
        context: _context,
      );
      await harness.settle();

      expect(controller().snapshot.queue.items, isEmpty);
    });

    test('a list with nothing playable does nothing', () async {
      await actions.playTracks(
        [_track('a', playable: false), _track('b', playable: false)],
        startIndex: 0,
        context: _context,
      );
      await harness.settle();

      expect(controller().snapshot.queue.items, isEmpty);
    });

    test('the same track twice gets two fresh queueItemIds', () async {
      await actions.playTracks(
        [_track('a'), _track('a')],
        startIndex: 0,
        context: _context,
      );
      await harness.settle();

      final ids = [
        for (final item in controller().snapshot.queue.items) item.queueItemId,
      ];
      expect(ids, hasLength(2));
      expect(ids.toSet(), hasLength(2));
    });

    test(
      'more than the queue holds queues the first 5,000 and reports it',
      () async {
        await actions.playTracks(
          [for (var i = 0; i < 6000; i++) _track('t$i')],
          startIndex: 0,
          context: _context,
        );
        await harness.settle();

        expect(
          controller().snapshot.queue.items,
          hasLength(QueueReducer.maxItems),
        );
        expect(notices, [isA<QueueTruncated>()]);
        expect((notices.single as QueueTruncated).queued, 5000);
      },
    );
  });

  group('playNext and addToQueue', () {
    setUp(() async {
      await actions.playTracks(
        [_track('a'), _track('b')],
        startIndex: 0,
        context: _context,
      );
      await harness.settle();
    });

    test('playNext inserts after the current item, keeping order', () async {
      await actions.playNext([_track('x'), _track('y')]);
      await harness.settle();

      expect(played(), ['pb-a', 'pb-x', 'pb-y', 'pb-b']);
      expect(current(), 'pb-a');
    });

    test('addToQueue appends', () async {
      await actions.addToQueue([_track('x'), _track('y', playable: false)]);
      await harness.settle();

      expect(played(), ['pb-a', 'pb-b', 'pb-x']);
    });
  });

  for (final next in [true, false]) {
    test('${next ? 'playNext' : 'addToQueue'} on an empty queue creates a '
        'paused queue', () async {
      final tracks = [_track('x'), _track('y')];
      await (next ? actions.playNext(tracks) : actions.addToQueue(tracks));
      await harness.settle();

      expect(played(), ['pb-x', 'pb-y']);
      expect(current(), 'pb-x');
      expect(controller().snapshot.playing, isFalse);
    });
  }

  group('offline: only tracks with a file on this device', () {
    late Set<PlaybackId>? onDevice;

    setUp(() {
      onDevice = {const PlaybackId('pb-a'), const PlaybackId('pb-c')};
      actions = PlayActions(
        controller: harness.controller,
        library: () async => library,
        playlists: () async => playlists,
        notify: notices.add,
        random: Random(1),
        availableOffline: () async => onDevice,
      );
      library.albumDetails['al-1'] = AlbumDetail(
        album: const Album(
          id: 'al-1',
          title: 'Record',
          artistName: 'Band',
          artistId: 'ar-1',
        ),
        tracks: [_track('a'), _track('b'), _track('c')],
        owned: true,
      );
    });

    test('Play on a collection queues only the downloaded items', () async {
      await actions.playAlbum('al-1');
      await harness.settle();
      expect(played(), ['pb-a', 'pb-c']);
    });

    test('Shuffle on a collection queues only the downloaded items', () async {
      await actions.playAlbum('al-1', shuffle: true);
      await harness.settle();
      expect(played().toSet(), {'pb-a', 'pb-c'});
    });

    test('Play next queues only the downloaded items', () async {
      await actions.playNext([_track('a'), _track('b'), _track('c')]);
      await harness.settle();
      expect(played(), ['pb-a', 'pb-c']);
    });

    test('a row list starts at its downloaded row', () async {
      await actions.playTracks(
        [_track('a'), _track('b'), _track('c')],
        startIndex: 2,
        context: _context,
      );
      await harness.settle();
      expect(played(), ['pb-a', 'pb-c']);
      expect(current(), 'pb-c');
    });

    test('nothing downloaded queues nothing', () async {
      onDevice = {};
      await actions.playAlbum('al-1');
      await harness.settle();
      expect(played(), isEmpty);
    });

    test('online (null) queues everything', () async {
      onDevice = null;
      await actions.playAlbum('al-1');
      await harness.settle();
      expect(played(), ['pb-a', 'pb-b', 'pb-c']);
    });
  });

  group('collections', () {
    test('playAlbum queues the album with an album context', () async {
      library.albumDetails['al-1'] = AlbumDetail(
        album: const Album(
          id: 'al-1',
          title: 'Record',
          artistName: 'Band',
          artistId: 'ar-1',
        ),
        tracks: [_track('a'), _track('b', playable: false), _track('c')],
        owned: true,
      );

      await actions.playAlbum('al-1');
      await harness.settle();

      expect(played(), ['pb-a', 'pb-c']);
      expect(current(), 'pb-a');
      expect(
        controller().snapshot.queue.context,
        const QueueContext(
          kind: QueueContextKind.album,
          id: 'al-1',
          title: 'Record',
        ),
      );
    });

    test('playPlaylist leaves out items the server marks unplayable', () async {
      playlists.playlistDetails['p1'] = PlaylistDetail(
        summary: const PlaylistSummary(
          id: 'p1',
          name: 'Mine',
          trackCount: 3,
          isOwner: true,
          isPublic: false,
        ),
        items: [
          PlaylistItem(id: 'i1', sort: 0, track: _track('a'), isPlayable: true),
          PlaylistItem(
            id: 'i2',
            sort: 1,
            track: _track('b'),
            isPlayable: false,
          ),
          PlaylistItem(id: 'i3', sort: 2, track: _track('c'), isPlayable: true),
        ],
      );

      await actions.playPlaylist('p1');
      await harness.settle();

      expect(played(), ['pb-a', 'pb-c']);
      expect(
        controller().snapshot.queue.context?.kind,
        QueueContextKind.playlist,
      );
      expect(controller().snapshot.queue.context?.id, 'p1');
    });

    test('playPlaylist of liked queues the liked tracks', () async {
      library.likedList = [_track('l1'), _track('l2')];

      await actions.playPlaylist(PlayActions.likedPlaylistId);
      await harness.settle();

      expect(played(), ['pb-l1', 'pb-l2']);
      expect(
        controller().snapshot.queue.context?.kind,
        QueueContextKind.playlist,
      );
      expect(library.sources.single.disposed, isTrue);
    });

    test('a 6,000-track playlist queues 5,000 and reports it', () async {
      playlists.playlistDetails['big'] = PlaylistDetail(
        summary: const PlaylistSummary(
          id: 'big',
          name: 'Big',
          trackCount: 6000,
          isOwner: true,
          isPublic: false,
        ),
        items: [
          for (var i = 0; i < 6000; i++)
            PlaylistItem(
              id: 'i$i',
              sort: i,
              track: _track('t$i'),
              isPlayable: true,
            ),
        ],
      );

      await actions.playPlaylist('big');
      await harness.settle();

      expect(controller().snapshot.queue.items, hasLength(5000));
      expect(notices, [isA<QueueTruncated>()]);
    });

    test(
      'playArtist queues the Popular tracks with an artist context',
      () async {
        library.artistDetails['ar-1'] = ArtistDetail(
          artist: const Artist(id: 'ar-1', name: 'Band'),
          topTracks: [_track('p1'), _track('p2')],
        );

        await actions.playArtist('ar-1');
        await harness.settle();

        expect(played(), ['pb-p1', 'pb-p2']);
        expect(
          controller().snapshot.queue.context?.kind,
          QueueContextKind.artist,
        );
        expect(controller().snapshot.queue.context?.id, 'ar-1');
      },
    );

    test('shuffle turns shuffle on and plays the first of the shuffled '
        'order', () async {
      library.artistDetails['ar-1'] = ArtistDetail(
        artist: const Artist(id: 'ar-1', name: 'Band'),
        topTracks: [for (var i = 0; i < 8; i++) _track('p$i')],
      );

      await actions.playArtist('ar-1', shuffle: true);
      await harness.settle();

      final queue = controller().snapshot.queue;
      expect(queue.isShuffled, isTrue);
      expect(queue.cursor, 0);
      expect(controller().snapshot.playing, isTrue);
      expect(played().toSet(), {for (var i = 0; i < 8; i++) 'pb-p$i'});
    });

    test('a load failure queues nothing and reports it', () async {
      library.errors['album'] = const ServerError(status: 500);

      await actions.playAlbum('al-1');
      await harness.settle();

      expect(controller().snapshot.queue.items, isEmpty);
      expect(notices, [isA<PlayLoadFailed>()]);
      expect((notices.single as PlayLoadFailed).error, isA<ServerError>());
    });

    test('shuffleLibrary plays the server order with shuffle off', () async {
      await controller().setShuffle(true);
      library.shuffledList = [_track('s3'), _track('s1'), _track('s2')];

      await actions.shuffleLibrary();
      await harness.settle();

      expect(controller().snapshot.queue.isShuffled, isFalse);
      expect(played(), ['pb-s3', 'pb-s1', 'pb-s2']);
      expect(current(), 'pb-s3');
      expect(
        controller().snapshot.queue.context?.kind,
        QueueContextKind.library,
      );
    });
  });
}
