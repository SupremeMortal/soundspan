// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/downloads/episode_download_meta.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/playback/media_controls/audio_service_controls.dart';
import 'package:soundspan/core/playback/media_controls/browse/browse_tree.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/platform/artwork_content_uri/artwork_content_uri.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../../helpers/fake_media_browse_source.dart';
import '../../../helpers/recording_media_command_handler.dart';
import '../../logging/recording_sink.dart';

String _subtitle(DownloadCollectionKind kind, int count) =>
    '${kind.name} · $count';

const _titles = BrowseRootTitles(
  recent: 'Recent',
  playlists: 'Playlists',
  albums: 'Albums',
  downloads: 'Downloads',
  downloadsSubtitle: _subtitle,
);

const String _oddPlaylist = 'pl/with slash';

/// Answers a content URI for the refs in [pinned] only.
class _FakeArtwork implements ArtworkContentUri {
  final Set<String> pinned = {};

  @override
  Uri? forArtRef(String ref) =>
      pinned.contains(ref) ? Uri.parse('content://art/$ref') : null;
}

void main() {
  late StateDatabase db;
  late DownloadStore store;
  late _FakeArtwork artwork;
  late FakeMediaBrowseSource source;
  late RecordingMediaCommandHandler commands;
  late SoundspanAudioHandler handler;
  var minute = 0;

  Future<void> collection(
    DownloadCollectionKind kind,
    String refId,
    List<(String, DownloadStatus)> items, {
    String? artworkRef,
  }) async {
    await store.upsertCollection(
      kind: kind,
      refId: refId,
      title: 'C $refId',
      metaJson: jsonEncode({'subtitle': 'Sub', 'artworkRef': artworkRef}),
      status: DownloadCollectionStatus.ready,
      requestedAt: DateTime.utc(2026, 5, 1, 12, minute++),
    );
    for (var i = 0; i < items.length; i++) {
      final (id, status) = items[i];
      final key = TrackItemKey(id);
      await store.upsertItem(
        key,
        DownloadItemsCompanion(
          metaJson: Value(
            jsonEncode({
              'title': 'T $id',
              'artist': 'A $id',
              'album': 'Al $id',
              'durationSec': 180,
              'artworkRef': 'art-$id',
              'albumId': 'album-$id',
            }),
          ),
          status: Value(status),
          requestedAt: Value(DateTime.utc(2026, 5, 2)),
        ),
      );
      await store.addMembership(kind, refId, key, i);
    }
  }

  Future<void> episode(
    String podcastId,
    String episodeId,
    DownloadStatus status,
  ) async {
    final refId = '$podcastId:$episodeId';
    await store.upsertCollection(
      kind: DownloadCollectionKind.episode,
      refId: refId,
      title: 'Ep $episodeId',
      metaJson: jsonEncode({
        'subtitle': 'Pod',
        'artworkRef': 'cover-$podcastId',
      }),
      status: DownloadCollectionStatus.ready,
      requestedAt: DateTime.utc(2026, 5, 1, 12, minute++),
    );
    final key = EpisodeItemKey(podcastId: podcastId, episodeId: episodeId);
    await store.upsertItem(
      key,
      DownloadItemsCompanion(
        metaJson: Value(
          EpisodeDownloadMeta(
            episodeId: episodeId,
            podcastId: podcastId,
            title: 'Ep $episodeId',
            podcastTitle: 'Pod $podcastId',
            durationSec: 1200,
            artworkRef: 'cover-$podcastId',
            positionSec: 30,
          ).toJson(),
        ),
        status: Value(status),
        requestedAt: Value(DateTime.utc(2026, 5, 2)),
      ),
    );
    await store.addMembership(DownloadCollectionKind.episode, refId, key, 0);
  }

  setUp(() async {
    minute = 0;
    db = StateDatabase(NativeDatabase.memory());
    store = DownloadStore(db);
    artwork = _FakeArtwork();
    source = FakeMediaBrowseSource();
    commands = RecordingMediaCommandHandler()
      ..browseSource = source
      ..browseDownloads = DownloadsBrowse(store: store, artwork: artwork);
    handler = SoundspanAudioHandler(commands, browseTitles: () => _titles);

    await collection(DownloadCollectionKind.album, 'al1', [
      ('a0', DownloadStatus.completed),
      ('a1', DownloadStatus.queued),
      ('a2', DownloadStatus.completed),
      ('a3', DownloadStatus.failedPermanent),
      ('a4', DownloadStatus.unavailable),
      ('a5', DownloadStatus.completed),
    ], artworkRef: 'cover-al1');
    await collection(DownloadCollectionKind.playlist, 'empty', [
      ('e0', DownloadStatus.queued),
    ]);
    await collection(DownloadCollectionKind.track, 'solo', [
      ('solo', DownloadStatus.completed),
    ]);
    await collection(DownloadCollectionKind.playlist, _oddPlaylist, [
      ('p0', DownloadStatus.completed),
    ]);
  });
  tearDown(() => db.close());

  test('root children include Downloads last', () async {
    final items = await handler.getChildren('root');

    expect(
      [for (final i in items) i.id],
      ['recent', 'playlists', 'albums', 'downloads'],
    );
    expect(items.last.title, 'Downloads');
    expect(items.last.playable, isFalse);
  });

  test('downloads lists only collections with a completed item, in request '
      'order, with kind subtitles and artwork', () async {
    artwork.pinned.add('cover-al1');

    final items = await handler.getChildren('downloads');

    expect(
      [for (final i in items) i.id],
      [
        'downloads/album/al1',
        'downloads/track/solo/0',
        'downloads/playlist/${Uri.encodeComponent(_oddPlaylist)}',
      ],
    );
    expect(
      [for (final i in items) i.title],
      ['C al1', 'T solo', 'C $_oddPlaylist'],
    );
    expect(
      [for (final i in items) i.artist],
      ['album · 3', 'track · 1', 'playlist · 1'],
    );
    expect(items[0].artUri, Uri.parse('content://art/cover-al1'));
    expect(items[2].artUri, isNull);
  });

  test("a collection's children are its completed items in order, with "
      'their metadata and artwork', () async {
    artwork.pinned.add('art-a2');

    final items = await handler.getChildren('downloads/album/al1');

    expect(
      [for (final i in items) i.id],
      [
        'downloads/album/al1/0',
        'downloads/album/al1/1',
        'downloads/album/al1/2',
      ],
    );
    expect([for (final i in items) i.title], ['T a0', 'T a2', 'T a5']);
    expect(items.every((i) => i.playable ?? false), isTrue);
    expect(items[1].artist, 'A a2');
    expect(items[1].album, 'Al a2');
    expect(items[1].duration, const Duration(seconds: 180));
    expect(items[1].artUri, Uri.parse('content://art/art-a2'));
    expect(items[0].artUri, isNull);
  });

  test('a single-track collection is playable at the top level', () async {
    final items = await handler.getChildren('downloads');
    final solo = items.singleWhere((i) => i.id == 'downloads/track/solo/0');

    expect(solo.playable, isTrue);

    await handler.playFromMediaId('downloads/track/solo/0');

    final request = commands.requests.single;
    expect(request.context.kind, QueueContextKind.single);
    expect(
      [for (final t in request.tracks) t.playbackId],
      [const PlaybackId('solo')],
    );
  });

  test('playFromMediaId for index 2 replaces the queue with the completed '
      'items and starts at index 2', () async {
    await handler.playFromMediaId('downloads/album/al1/2');

    expect(commands.calls, ['playRequest 2']);
    final request = commands.requests.single;
    expect(
      [for (final t in request.tracks) t.playbackId],
      [const PlaybackId('a0'), const PlaybackId('a2'), const PlaybackId('a5')],
    );
    expect(request.tracks[2].meta.title, 'T a5');
    expect(request.tracks[2].albumId, 'album-a5');
    expect(
      request.context,
      const QueueContext(kind: QueueContextKind.album, id: 'al1'),
    );
  });

  test('an unknown or malformed downloads id is ignored and logged, with no '
      'command sent', () async {
    final sink = RecordingSink();
    AppLogging.configure(sinks: [sink], releaseMode: false);
    addTearDown(AppLogging.reset);

    for (final id in [
      'downloads/album/al1/3',
      'downloads/album/al1/x',
      'downloads/album/nope/0',
      'downloads/song/al1/0',
      'downloads/album/%zz/0',
      'downloads/album//0',
      'downloads/album/al1/0/1',
      'downloads/empty',
    ]) {
      await handler.playFromMediaId(id);
      expect(await handler.getChildren(id), isEmpty, reason: id);
    }

    expect(commands.calls, isEmpty);
    expect(sink.entries.where((e) => e.scope == 'AndroidAuto'), isNotEmpty);
  });

  test('no call reaches the browse source while browsing or playing from '
      'Downloads', () async {
    await handler.getChildren('downloads');
    await handler.getChildren('downloads/album/al1');
    await handler.playFromMediaId('downloads/album/al1/0');

    expect(source.calls, 0);
    expect(commands.calls, ['playRequest 0']);
  });

  test('a refId containing / round-trips through the media id', () async {
    final encoded = Uri.encodeComponent(_oddPlaylist);

    final items = await handler.getChildren('downloads/playlist/$encoded');
    expect([for (final i in items) i.id], ['downloads/playlist/$encoded/0']);

    await handler.playFromMediaId(items.single.id);
    expect(
      commands.requests.single.context,
      const QueueContext(kind: QueueContextKind.playlist, id: _oddPlaylist),
    );
  });

  test('a completed episode collection is listed as a playable episode with '
      'the episode subtitle and its cover; a queued one is not', () async {
    await episode('pod/1', 'ep1', DownloadStatus.completed);
    await episode('pod2', 'ep2', DownloadStatus.queued);
    artwork.pinned.add('cover-pod/1');

    final items = await handler.getChildren('downloads');
    final id = 'downloads/episode/${Uri.encodeComponent('pod/1:ep1')}/0';

    expect([for (final i in items) i.id], contains(id));
    expect(
      items.where((i) => i.id.startsWith('downloads/episode/')),
      hasLength(1),
    );
    final node = items.singleWhere((i) => i.id == id);
    expect(node.playable, isTrue);
    expect(node.title, 'Ep ep1');
    expect(node.artist, 'episode · 1');
    expect(node.duration, const Duration(seconds: 1200));
    expect(node.artUri, Uri.parse('content://art/cover-pod/1'));
  });

  test('playing a downloaded episode sends one episode to the controller, '
      'with no call to the browse source', () async {
    await episode('pod/1', 'ep1', DownloadStatus.completed);
    final id = 'downloads/episode/${Uri.encodeComponent('pod/1:ep1')}/0';

    await handler.getChildren('downloads');
    await handler.playFromMediaId(id);

    expect(commands.calls, ['playRequest 0']);
    final request = commands.requests.single;
    expect(request.tracks, isEmpty);
    expect(request.episode?.id, 'ep1');
    expect(request.episode?.title, 'Ep ep1');
    expect(request.episode?.progress?.currentTimeSec, 30);
    expect(request.podcast?.id, 'pod/1');
    expect(request.podcast?.title, 'Pod pod/1');
    expect(source.calls, 0);
  });

  test(
    'a queued episode, or an index past the episode, plays nothing',
    () async {
      await episode('pod2', 'ep2', DownloadStatus.queued);
      await episode('pod3', 'ep3', DownloadStatus.completed);

      await handler.playFromMediaId(
        'downloads/episode/${Uri.encodeComponent('pod2:ep2')}/0',
      );
      await handler.playFromMediaId(
        'downloads/episode/${Uri.encodeComponent('pod3:ep3')}/1',
      );

      expect(commands.calls, isEmpty);
    },
  );

  test('without downloads the root has no Downloads entry', () async {
    commands.browseDownloads = null;

    final items = await handler.getChildren('root');

    expect([for (final i in items) i.id], ['recent', 'playlists', 'albums']);
    expect(await handler.getChildren('downloads'), isEmpty);
  });
}
