// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/downloads/downloaded_library.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/shared/domain/domain.dart';

final DateTime _at = DateTime.utc(2026, 5, 1, 12);

void main() {
  late StateDatabase db;
  late DownloadStore store;
  late DownloadedLibrary library;

  setUp(() {
    db = StateDatabase(NativeDatabase.memory());
    store = DownloadStore(db);
    library = DownloadedLibrary(db);
  });
  tearDown(() => db.close());

  Future<void> collection(
    DownloadCollectionKind kind,
    String refId,
    String title, {
    String? subtitle,
    String? artworkRef,
  }) => store.upsertCollection(
    kind: kind,
    refId: refId,
    title: title,
    metaJson: jsonEncode({'subtitle': subtitle, 'artworkRef': artworkRef}),
    status: DownloadCollectionStatus.ready,
    requestedAt: _at,
  );

  Future<void> track(
    String playbackId, {
    required String title,
    String artist = 'Artist A',
    String artistId = 'ar1',
    String album = 'Album A',
    String? albumId = 'al1',
    DownloadStatus status = DownloadStatus.completed,
    List<(DownloadCollectionKind, String)> memberOf = const [],
  }) async {
    final key = TrackItemKey(playbackId);
    await store.upsertItem(
      key,
      DownloadItemsCompanion(
        metaJson: Value(
          jsonEncode({
            'title': title,
            'artist': artist,
            'album': album,
            'durationSec': 180,
            'artworkRef': 'art-$albumId',
            'albumId': albumId,
            'artistId': artistId,
            'trackNumber': 1,
          }),
        ),
        status: Value(status),
        requestedAt: Value(_at),
      ),
    );
    for (final (index, (kind, refId)) in memberOf.indexed) {
      await store.addMembership(kind, refId, key, index);
    }
  }

  Future<void> seed() async {
    await collection(
      DownloadCollectionKind.album,
      'al1',
      'Album A',
      subtitle: 'Artist A',
      artworkRef: 'cover-al1',
    );
    await collection(DownloadCollectionKind.playlist, 'pl1', 'Road trip');
    await collection(DownloadCollectionKind.track, 'p3', 'Gamma');
    await collection(
      DownloadCollectionKind.album,
      'al3',
      'Album C',
      subtitle: 'Artist C',
    );
    // In both the album and the playlist.
    await track(
      'p1',
      title: 'beta',
      memberOf: [
        (DownloadCollectionKind.album, 'al1'),
        (DownloadCollectionKind.playlist, 'pl1'),
      ],
    );
    await track(
      'p2',
      title: 'Alpha',
      memberOf: [(DownloadCollectionKind.album, 'al1')],
    );
    // A single track of another album and artist.
    await track(
      'p3',
      title: 'Gamma',
      artist: 'Artist B',
      artistId: 'ar2',
      album: 'Album B',
      albumId: 'al2',
      memberOf: [(DownloadCollectionKind.track, 'p3')],
    );
    // Not downloaded yet: listed nowhere.
    await track(
      'p4',
      title: 'Delta',
      artist: 'Artist D',
      artistId: 'ar4',
      album: 'Album D',
      albumId: 'al4',
      status: DownloadStatus.queued,
      memberOf: [(DownloadCollectionKind.playlist, 'pl1')],
    );
  }

  test('tracks: completed track items once each, ordered by title', () async {
    await seed();
    final tracks = await library.watchTracks().first;
    expect([for (final t in tracks) t.meta.title], ['Alpha', 'beta', 'Gamma']);
    final beta = tracks[1];
    expect(beta.playbackId, const PlaybackId('p1'));
    expect(beta.albumId, 'al1');
    expect(beta.artistId, 'ar1');
    expect(beta.meta.artist, 'Artist A');
    expect(beta.meta.durationSec, 180);
  });

  test('albums: album collections plus albums with a completed item', () async {
    await seed();
    final albums = await library.watchAlbums().first;
    expect([for (final a in albums) a.id], ['al1', 'al2', 'al3']);
    expect(albums[0].title, 'Album A');
    expect(albums[0].artistName, 'Artist A');
    expect(albums[0].artistId, 'ar1');
    expect(albums[0].artworkRef, 'cover-al1');
    expect(albums[1].title, 'Album B');
    expect(albums[1].artistName, 'Artist B');
    expect(albums[1].artworkRef, 'art-al2');
    expect(albums[2].artistName, 'Artist C');
  });

  test('artists: distinct artists of completed items', () async {
    await seed();
    final artists = await library.watchArtists().first;
    expect(
      [for (final a in artists) (a.id, a.name)],
      [('ar1', 'Artist A'), ('ar2', 'Artist B')],
    );
  });

  test('playlists: playlist collections with their item counts', () async {
    await seed();
    final playlists = await library.watchPlaylists().first;
    expect(playlists, hasLength(1));
    expect(playlists.single.id, 'pl1');
    expect(playlists.single.name, 'Road trip');
    expect(playlists.single.trackCount, 2);
  });

  test('downloaded playback ids, and the lists follow changes', () async {
    await seed();
    expect(await library.downloadedPlaybackIds(), {
      const PlaybackId('p1'),
      const PlaybackId('p2'),
      const PlaybackId('p3'),
    });
    final lists = library.watchTracks();
    final later = expectLater(
      lists.map((tracks) => tracks.length),
      emitsThrough(4),
    );
    await track(
      'p4',
      title: 'Delta',
      artist: 'Artist D',
      artistId: 'ar4',
      album: 'Album D',
      albumId: 'al4',
    );
    await later;
  });
}
