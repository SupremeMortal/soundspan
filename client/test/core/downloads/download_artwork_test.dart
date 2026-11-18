// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/download_artwork.dart';
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/offline_models.dart';
import 'package:soundspan/core/playback/media_controls/artwork_pinner.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/platform/artwork_store/artwork_store_io.dart'
    show IoArtworkStore;
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan/shared/domain/track.dart';
import 'package:soundspan/shared/providers/images.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import 'download_controller_rig.dart';

/// Answers each fetch with three bytes, recording the cover asked for; a
/// [gate] holds every answer until it completes.
final class _Fetcher {
  final List<ArtworkFetch> fetches = [];
  bool fail = false;
  Completer<void>? gate;

  Future<Uint8List> fetch(ArtworkFetch fetch) async {
    fetches.add(fetch);
    await gate?.future;
    if (fail) throw const SocketException('unreachable');
    return Uint8List.fromList([1, 2, 3]);
  }
}

String _task(String playbackId) => itemKeyHash(TrackItemKey(playbackId));

Track _track(String id, {String? artworkRef}) => Track(
  meta: TrackMeta(
    title: 'Song $id',
    artist: 'Contract Aurora',
    album: 'First Light',
    durationSec: 30,
    artworkRef: artworkRef,
  ),
  playbackId: PlaybackId(id),
  artistId: 'ar-1',
);

void main() {
  late Directory dir;
  late DownloadControllerRig rig;
  late _Fetcher fetcher;
  late String art;
  late List<Duration> delays;
  late ProfileDownloadArtwork artwork;

  ProfileDownloadArtwork create() => ProfileDownloadArtwork(
    downloads: rig.store,
    events: rig.controller.events,
    reachability: rig.reachability,
    urls: api.ImageUrls(Uri.parse('https://music.example.com')),
    credentials: () => const api.ApiKeyCredentials(apiKey: 'key-1'),
    fetch: fetcher.fetch,
    store: const IoArtworkStore(),
    artDirectory: art,
    clock: rig.clock,
    delay: (duration) async {
      delays.add(duration);
      rig.clock.advance(duration);
    },
  );

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('download_artwork');
    rig = DownloadControllerRig(dir);
    fetcher = _Fetcher();
    delays = [];
    art = '${dir.path}/profiles/p1/art';
    await rig.start();
    artwork = create();
  });
  tearDown(() async {
    await artwork.dispose();
    await rig.dispose();
    dir.deleteSync(recursive: true);
  });

  String fileOf(String ref) => '$art/${downloadArtworkFileName(ref)}';

  Future<void> settle() async {
    for (var round = 0; round < 3; round++) {
      await rig.settle();
      await artwork.settle();
    }
  }

  Future<void> pinAlbum(
    String id,
    List<String> tracks, {
    String? cover,
    Map<String, String> trackCovers = const {},
  }) async {
    rig.server.offline.albums[id] = tracks;
    await rig.controller.pin(
      CollectionKind.album,
      id,
      snapshot: CollectionSnapshot(
        title: id,
        artworkRef: cover,
        tracks: [for (final t in tracks) _track(t, artworkRef: trackCovers[t])],
      ),
    );
    await settle();
  }

  Future<void> finish(String playbackId) async {
    await rig.downloader.complete(
      _task(playbackId),
      bytes: 1000,
      contentType: 'audio/flac',
    );
    await settle();
  }

  test('the file name is the lower-case hex SHA-1 of the ref', () {
    expect(
      downloadArtworkFileName('al-1'),
      matches(RegExp(r'^[0-9a-f]{40}\.img$')),
    );
    expect(
      downloadArtworkFileName('al-1'),
      isNot(downloadArtworkFileName('al-2')),
    );
  });

  test("completing an item pins its artwork and its collection's artwork "
      'at art/<sha1(ref)>.img', () async {
    artwork.start();
    await pinAlbum(
      'al',
      ['t1'],
      cover: 'cover-al',
      trackCovers: {'t1': 'cover-t1'},
    );
    fetcher.fetches.clear();

    await finish('t1');

    expect((await rig.item('t1'))!.status, DownloadStatus.completed);
    expect(File(fileOf('cover-t1')).readAsBytesSync(), [1, 2, 3]);
    expect(File(fileOf('cover-al')).existsSync(), isTrue);
    expect(await artwork.fileFor('cover-t1'), fileOf('cover-t1'));
    // The album cover was already pinned when the album became ready.
    expect(fetcher.fetches, hasLength(1));
    final fetch = fetcher.fetches.single;
    expect(fetch.url.queryParameters['size'], '512');
    expect(fetch.cacheKey, artworkCacheKey('cover-t1', 512));
  });

  test('pinning a collection pins its cover before any item '
      'completes', () async {
    artwork.start();
    await pinAlbum('al', ['t1', 't2'], cover: 'cover-al');

    expect((await rig.item('t1'))!.status, isNot(DownloadStatus.completed));
    expect(File(fileOf('cover-al')).existsSync(), isTrue);
    expect(fetcher.fetches, hasLength(1));
  });

  test('a second pin for the same ref makes no request; two concurrent '
      'calls make one', () async {
    fetcher.gate = Completer<void>();
    final first = artwork.pin('cover-1');
    final second = artwork.pin('cover-1');
    fetcher.gate!.complete();

    expect(await first, fileOf('cover-1'));
    expect(await second, fileOf('cover-1'));
    expect(fetcher.fetches, hasLength(1));

    expect(await artwork.pin('cover-1'), fileOf('cover-1'));
    expect(fetcher.fetches, hasLength(1));
  });

  test('a failing fetch leaves the item completed and creates no file; the '
      'start-up repair pins it once the fetcher succeeds', () async {
    artwork.start();
    fetcher.fail = true;
    await pinAlbum(
      'al',
      ['t1'],
      cover: 'cover-al',
      trackCovers: {'t1': 'cover-t1'},
    );
    await finish('t1');

    expect((await rig.item('t1'))!.status, DownloadStatus.completed);
    expect(File(fileOf('cover-t1')).existsSync(), isFalse);
    expect(File(fileOf('cover-al')).existsSync(), isFalse);
    expect(await artwork.fileFor('cover-t1'), isNull);

    // The next start of the profile repairs what is missing.
    await artwork.dispose();
    fetcher
      ..fail = false
      ..fetches.clear();
    artwork = create()..start();
    await settle();

    expect(File(fileOf('cover-t1')).existsSync(), isTrue);
    expect(File(fileOf('cover-al')).existsSync(), isTrue);
    expect(fetcher.fetches, hasLength(2));
  });

  test('the start-up repair is sequential at no more than four fetches a '
      'second, and waits for reachability to be online', () async {
    fetcher.fail = true;
    await pinAlbum(
      'al',
      ['t1', 't2', 't3'],
      cover: 'cover-al',
      trackCovers: {'t1': 'c1', 't2': 'c2', 't3': 'c3'},
    );
    for (final id in ['t1', 't2', 't3']) {
      await finish(id);
    }
    fetcher
      ..fail = false
      ..fetches.clear();
    rig.setReachability(Reachability.noNetwork);

    artwork.start();
    await settle();
    expect(fetcher.fetches, isEmpty);

    rig.setReachability(Reachability.online);
    await settle();

    expect(fetcher.fetches, hasLength(4));
    expect(delays, hasLength(3));
    for (final delay in delays) {
      expect(delay, const Duration(milliseconds: 250));
    }
    for (final ref in ['c1', 'c2', 'c3', 'cover-al']) {
      expect(File(fileOf(ref)).existsSync(), isTrue, reason: ref);
    }
  });

  test('offline: no fetch is attempted', () async {
    rig.setReachability(Reachability.noNetwork);

    expect(await artwork.pin('cover-1'), isNull);

    expect(fetcher.fetches, isEmpty);
    expect(Directory(art).existsSync(), isFalse);
  });

  test('an item with no artwork ref is skipped', () async {
    artwork.start();
    await pinAlbum('al', ['t1']);

    await finish('t1');

    expect((await rig.item('t1'))!.status, DownloadStatus.completed);
    expect(fetcher.fetches, isEmpty);
    expect(Directory(art).existsSync(), isFalse);
  });

  test('two items sharing one album cover produce one file', () async {
    artwork.start();
    await pinAlbum(
      'al',
      ['t1', 't2'],
      trackCovers: {'t1': 'cover-al', 't2': 'cover-al'},
    );

    await finish('t1');
    await finish('t2');

    expect(Directory(art).listSync(), hasLength(1));
    expect(fetcher.fetches, hasLength(1));
  });

  test('removeUnreferenced deletes the file of an unpinned album, keeps a '
      'file still referenced by another collection, and keeps '
      'now-playing.img', () async {
    artwork.start();
    await pinAlbum('a', ['t1'], cover: 'cover-a');
    await pinAlbum('b', ['t2'], cover: 'cover-b');
    await pinAlbum('c', ['t3'], cover: 'cover-a');
    final nowPlaying = File('$art/${ArtworkPinner.fileName}')
      ..writeAsBytesSync([7]);
    expect(File(fileOf('cover-b')).existsSync(), isTrue);

    await rig.controller.unpin(CollectionKind.album, 'b');
    await settle();

    expect(File(fileOf('cover-b')).existsSync(), isFalse);
    expect(File(fileOf('cover-a')).existsSync(), isTrue);
    expect(nowPlaying.existsSync(), isTrue);

    await rig.controller.unpin(CollectionKind.album, 'a');
    await settle();
    expect(File(fileOf('cover-a')).existsSync(), isTrue);

    expect(await artwork.removeUnreferenced(), 0);
    expect(nowPlaying.existsSync(), isTrue);
  });

  test('removeUnreferenced counts the files it deletes', () async {
    await artwork.pin('stray-1');
    await artwork.pin('stray-2');

    expect(await artwork.removeUnreferenced(), 2);
    expect(Directory(art).listSync(), isEmpty);
  });

  test('the no-op implementation returns null and writes nothing', () async {
    const none = NoDownloadArtwork();
    none.start();

    expect(await none.pin('cover-1'), isNull);
    expect(await none.fileFor('cover-1'), isNull);
    expect(await none.removeUnreferenced(), 0);
    expect(Directory(art).existsSync(), isFalse);
  });

  test('artworkRefOf reads the artworkRef of metaJson and skips empty or '
      'undecodable values', () {
    expect(artworkRefOf('{"artworkRef":"x"}'), 'x');
    expect(artworkRefOf('{"artworkRef":""}'), isNull);
    expect(artworkRefOf('{"artworkRef":null}'), isNull);
    expect(artworkRefOf('{}'), isNull);
    expect(artworkRefOf('not json'), isNull);
  });
}
