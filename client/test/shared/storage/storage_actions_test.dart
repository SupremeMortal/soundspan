// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show QueryExecutor, Value;
import 'package:drift/native.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart'
    show BaseCacheManager;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/downloads/offline_models.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/core/storage/cache/open_cache_database.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/platform/database_opener/database_opener.dart';
import 'package:soundspan/platform/file_sizes/file_sizes_io.dart';
import 'package:soundspan/platform/image_cache/image_cache.dart';
import 'package:soundspan/platform/paths/paths.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/storage/storage_actions.dart';

import '../../core/downloads/download_controller_rig.dart';

/// Opens `cache.db` as a real file at [paths], so a delete removes it.
final class _FileOpener implements DatabaseOpener {
  new(this.paths);

  final ProfilePaths paths;
  final List<DatabaseTarget> deleted = [];

  @override
  bool get isVolatile => false;

  @override
  QueryExecutor open(DatabaseTarget target) {
    final file = File(paths.cacheDb)..parent.createSync(recursive: true);
    return NativeDatabase(file);
  }

  @override
  Future<void> delete(DatabaseTarget target) async {
    deleted.add(target);
    for (final suffix in ['', '-wal', '-shm']) {
      final file = File('${paths.cacheDb}$suffix');
      if (file.existsSync()) file.deleteSync();
    }
  }
}

void main() {
  late Directory dir;
  late DownloadControllerRig rig;
  late ProfilePaths profile;
  late _FileOpener opener;
  late CacheDatabase cacheDb;
  late StorageActions actions;
  late int reopened;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('storage_actions');
    rig = DownloadControllerRig(dir);
    await rig.start();
    profile = rig.paths.profile;
    opener = _FileOpener(profile);
    cacheDb = await openCacheDatabase(opener, profile.profileId);
    reopened = 0;
  });
  tearDown(() async {
    await rig.dispose();
    await cacheDb.close();
    dir.deleteSync(recursive: true);
  });

  StorageActions build(BaseCacheManager images) => StorageActions(
    downloads: () => rig.controller,
    images: images,
    cacheDatabase: () async => cacheDb,
    opener: opener,
    profileId: profile.profileId,
    reopenCache: () => reopened++,
    files: const IoFileSizes(),
    paths: profile,
  );

  test('clearCache empties the image store and cache.db; a completed '
      "download's file and row survive", () async {
    final images = createImageCacheManager(
      profileId: profile.profileId,
      directory: profile.images,
    );
    addTearDown(images.dispose);
    final cached = await images.putFile(
      'https://music.example.com/art/a.jpg',
      Uint8List.fromList(List.filled(64, 7)),
    );
    expect(cached.existsSync(), isTrue);
    await CacheStore(cacheDb, rig.clock).upsertTracks([rigTrack('c1')]);
    rig.server.offline.albums['al'] = ['t1'];
    await rig.controller.pin(CollectionKind.album, 'al');
    await rig.settle();
    final file = await rig.completeOnDisk('t1');
    actions = build(images);

    await actions.clearCache();

    expect(cached.existsSync(), isFalse);
    expect(
      await images.getFileFromCache('https://music.example.com/art/a.jpg'),
      isNull,
    );
    expect(opener.deleted, [CacheDatabaseTarget(profile.profileId)]);
    expect(reopened, 1);
    final fresh = await openCacheDatabase(opener, profile.profileId);
    addTearDown(fresh.close);
    expect(await CacheStore(fresh, rig.clock).watchTrack('c1').first, isNull);
    expect(File(file).existsSync(), isTrue);
    expect((await rig.item('t1'))!.status, DownloadStatus.completed);
    expect(await rig.store.completedFile(const TrackItemKey('t1')), file);
  });

  test('removeAllDownloads leaves no file in media/, no rows, and '
      'offlineDelete ops for every track; episodes are not reported', () async {
    rig.server.offline
      ..albums['al'] = ['t1', 't2']
      ..playlists['pl'] = ['t3'];
    await rig.controller.pin(CollectionKind.album, 'al');
    await rig.controller.pin(CollectionKind.playlist, 'pl');
    await rig.settle();
    await rig.completeOnDisk('t1');
    await rig.completeOnDisk('t3');
    const episode = EpisodeItemKey(podcastId: 'pod', episodeId: 'e1');
    final episodeRelative = rig.paths.relativeFinalFile(
      itemKeyHash(episode),
      'audio/mpeg',
    );
    File(rig.paths.resolve(episodeRelative))
      ..createSync(recursive: true)
      ..writeAsBytesSync([1, 2, 3]);
    await rig.store.upsertCollection(
      kind: DownloadCollectionKind.episode,
      refId: 'pod:e1',
      title: 'Episode',
      metaJson: '{}',
      status: DownloadCollectionStatus.ready,
      requestedAt: rig.clock.now(),
    );
    await rig.store.upsertItem(
      episode,
      DownloadItemsCompanion(
        metaJson: const Value('{}'),
        status: const Value(DownloadStatus.completed),
        sizeBytes: const Value(3),
        relativePath: Value(episodeRelative),
        requestedAt: Value(rig.clock.now()),
      ),
    );
    await rig.store.addMembership(
      DownloadCollectionKind.episode,
      'pod:e1',
      episode,
      0,
    );
    // A file no row names, such as one a crash left behind.
    File(p.join(profile.media, 'zz', 'stray.flac'))
      ..createSync(recursive: true)
      ..writeAsBytesSync([1]);
    rig.setReachability(Reachability.noNetwork);
    final images = createImageCacheManager(
      profileId: profile.profileId,
      directory: profile.images,
    );
    addTearDown(images.dispose);
    actions = build(images);

    await actions.removeAllDownloads();
    await rig.settle();

    final left = Directory(profile.media).existsSync()
        ? Directory(profile.media).listSync(recursive: true).whereType<File>()
        : const <File>[];
    expect(left, isEmpty);
    expect(await rig.items(), isEmpty);
    expect(await rig.collections(), isEmpty);
    expect(await rig.memberships(), isEmpty);
    final ops = await rig.pendingDeletes();
    expect([for (final op in ops) ...op.playbackIds]..sort(), [
      't1',
      't2',
      't3',
    ]);
  });
}
