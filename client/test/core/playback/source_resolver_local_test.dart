// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/playback/source_resolver.dart';
import 'package:soundspan/core/playback/stream_quality_policy.dart';
import 'package:soundspan/core/storage/state/device_settings_dao.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/platform/paths/paths.dart';
import 'package:soundspan/platform/stream_auth/stream_auth_io.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan/shared/domain/podcast.dart';
import 'package:soundspan/shared/domain/queue_item.dart';
import 'package:soundspan/shared/domain/track.dart';
import 'package:soundspan_api/soundspan_api.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_reachability.dart';
import '../../helpers/fakes/fake_media_files.dart';

final DateTime _at = DateTime.utc(2026, 5, 1, 12);

/// Counts the credential requests; none may happen for a file.
class _Credentials {
  int asked = 0;

  Future<Credentials> ensureFresh({required Duration minRemaining}) async {
    asked++;
    return const JwtCredentials(accessToken: 'a', refreshToken: 'r');
  }
}

/// A [DownloadStore] that counts the [completedFile] lookups.
class _CountingStore extends DownloadStore {
  new(super._db, {super.paths});

  int lookups = 0;

  @override
  Future<String?> completedFile(DownloadItemKey key) {
    lookups++;
    return super.completedFile(key);
  }
}

QueueItem _track(String id, String playbackId) => QueueItem.track(
  queueItemId: id,
  track: Track(
    meta: const TrackMeta(
      title: 'Song',
      artist: 'Artist',
      album: 'Album',
      durationSec: 215,
    ),
    playbackId: PlaybackId(playbackId),
  ),
  context: const QueueContext(kind: QueueContextKind.album),
);

void main() {
  late Directory dir;
  late StateDatabase db;
  late DownloadPaths paths;
  late _CountingStore store;
  late FakeReachability reachability;
  late _Credentials credentials;
  late int pumps;
  final clock = FakeClock(start: _at);

  SourceResolver resolverFor({bool canDownload = true}) => SourceResolver(
    ensureFresh: credentials.ensureFresh,
    urls: StreamUrls(Uri.parse('https://music.example.com')),
    quality: StreamQualityPolicy(DeviceSettingsDao(db), reachability),
    auth: const HeaderStreamAuth(),
    downloads: canDownload ? store : null,
    files: FakeMediaFiles(),
    reachability: reachability,
    clock: clock,
    onRequeued: () => pumps++,
  );

  /// Stores a completed item for [key] whose file is written unless
  /// [withFile] is false; returns the file's absolute path.
  Future<String> completed(DownloadItemKey key, {bool withFile = true}) async {
    final relative = paths.relativeFinalFile(itemKeyHash(key), 'audio/flac');
    await store.upsertItem(
      key,
      DownloadItemsCompanion(
        metaJson: const Value('{}'),
        status: const Value(DownloadStatus.completed),
        quality: const Value('high'),
        sizeBytes: const Value(4),
        relativePath: Value(relative),
        requestedAt: Value(_at),
        completedAt: Value(_at),
      ),
    );
    final absolute = paths.resolve(relative);
    if (withFile) {
      File(absolute)
        ..createSync(recursive: true)
        ..writeAsBytesSync([1, 2, 3, 4]);
    }
    return absolute;
  }

  setUp(() {
    dir = Directory.systemTemp.createTempSync('source_resolver_local');
    db = StateDatabase(NativeDatabase.memory());
    paths = DownloadPaths(
      ProfilePaths.derive(
        appSupport: p.join(dir.path, 'support'),
        appCache: p.join(dir.path, 'cache'),
        profileId: 'p1',
      ),
    );
    store = _CountingStore(db, paths: paths);
    reachability = FakeReachability();
    credentials = _Credentials();
    pumps = 0;
  });
  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  test('a completed item with a file plays from the file', () async {
    final file = await completed(const TrackItemKey('pb-1'));

    final resolved = await resolverFor().resolveSource(
      _track('q1', 'pb-1'),
      startAt: const Duration(seconds: 3),
    );

    expect(resolved.source.uri, Uri.file(file));
    expect(resolved.source.uri.isScheme('file'), isTrue);
    expect(resolved.source.headers, isEmpty);
    expect(resolved.source.startAt, const Duration(seconds: 3));
    expect(resolved.source.knownDuration, const Duration(seconds: 215));
    expect(resolved.source.streamQuality, isNull);
    expect(resolved.isLocalFile, isTrue);
    expect(resolved.download?.key, const TrackItemKey('pb-1'));
    expect(resolved.download?.quality, 'high');
    expect(credentials.asked, 0);
  });

  test('a downloaded episode plays from its file', () async {
    const key = EpisodeItemKey(podcastId: 'pod1', episodeId: 'e1');
    final file = await completed(key);

    final resolved = await resolverFor().resolveSource(
      const QueueItem.episode(
        queueItemId: 'q2',
        episode: Episode(id: 'e1', podcastId: 'pod1', title: 'Episode'),
        podcast: Podcast(id: 'pod1', title: 'Podcast'),
      ),
    );

    expect(resolved.source.uri, Uri.file(file));
    expect(resolved.download?.key, key);
    expect(credentials.asked, 0);
  });

  test('a completed row whose file is gone is queued again and streamed '
      'while online', () async {
    const key = TrackItemKey('pb-1');
    await completed(key, withFile: false);

    final resolved = await resolverFor().resolveSource(_track('q1', 'pb-1'));

    expect(resolved.isLocalFile, isFalse);
    expect(resolved.source.uri.path, '/api/playback/stream/pb-1');
    expect(credentials.asked, 1);
    final row = (await store.item(key))!;
    expect(row.status, DownloadStatus.queued);
    expect(row.relativePath, isNull);
    expect(pumps, 1);
  });

  test('a completed row whose file is gone throws NotAvailableOffline '
      'while offline', () async {
    const key = TrackItemKey('pb-1');
    await completed(key, withFile: false);
    reachability.set(Reachability.forcedOffline);

    await expectLater(
      resolverFor().resolveSource(_track('q1', 'pb-1')),
      throwsA(
        isA<NotAvailableOffline>().having((e) => e.queueItemId, 'id', 'q1'),
      ),
    );
    expect((await store.item(key))!.status, DownloadStatus.queued);
    expect(credentials.asked, 0);
  });

  for (final state in [
    Reachability.forcedOffline,
    Reachability.serverUnreachable,
    Reachability.noNetwork,
  ]) {
    test('no row while ${state.name} throws NotAvailableOffline', () async {
      reachability.set(state);

      await expectLater(
        resolverFor().resolveSource(_track('q1', 'pb-1')),
        throwsA(isA<NotAvailableOffline>()),
      );
      expect(credentials.asked, 0);
    });
  }

  test('no row while online is streamed', () async {
    final resolved = await resolverFor().resolveSource(_track('q1', 'pb-1'));

    expect(resolved.isLocalFile, isFalse);
    expect(resolved.download, isNull);
    expect(resolved.source.uri.path, '/api/playback/stream/pb-1');
    expect(resolved.source.headers, isNotEmpty);
  });

  test('without downloads the store is never consulted', () async {
    await completed(const TrackItemKey('pb-1'));

    final resolved = await resolverFor(canDownload: false)
        .resolveSource(_track('q1', 'pb-1'));

    expect(resolved.isLocalFile, isFalse);
    expect(store.lookups, 0);
  });

  test('markPlayed writes lastPlayedAt', () async {
    const key = TrackItemKey('pb-1');
    await completed(key);
    final resolved = await resolverFor().resolveSource(_track('q1', 'pb-1'));

    await resolverFor().markPlayed(resolved.download!);

    expect((await store.item(key))!.lastPlayedAt, _at);
  });

  test('markMissing queues the item again', () async {
    const key = TrackItemKey('pb-1');
    await completed(key);
    final resolved = await resolverFor().resolveSource(_track('q1', 'pb-1'));

    await resolverFor().markMissing(resolved.download!);

    expect((await store.item(key))!.status, DownloadStatus.queued);
    expect(pumps, 1);
  });
}
