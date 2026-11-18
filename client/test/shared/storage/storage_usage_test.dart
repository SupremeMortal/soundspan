// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/platform/file_sizes/file_sizes_io.dart';
import 'package:soundspan/platform/paths/paths.dart';
import 'package:soundspan/shared/storage/storage_usage.dart';

import '../../helpers/fakes/fake_disk_space.dart';

void main() {
  late Directory dir;
  late StateDatabase state;
  late ProfilePaths paths;
  late DownloadStore store;
  late FakeDiskSpace diskSpace;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('storage_usage');
    state = StateDatabase(NativeDatabase.memory());
    paths = ProfilePaths.derive(
      appSupport: p.join(dir.path, 'support'),
      appCache: p.join(dir.path, 'cache'),
      profileId: 'p1',
    );
    store = DownloadStore(state, paths: DownloadPaths(paths));
    diskSpace = FakeDiskSpace();
  });
  tearDown(() async {
    await state.close();
    dir.deleteSync(recursive: true);
  });

  void write(String path, int bytes) => File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(List.filled(bytes, 1));

  Future<void> item(
    DownloadItemKey key,
    DownloadStatus status, {
    int? sizeBytes,
    int? expectedBytes,
  }) => store.upsertItem(
    key,
    DownloadItemsCompanion(
      metaJson: const Value('{}'),
      status: Value(status),
      sizeBytes: Value(sizeBytes),
      expectedBytes: Value(expectedBytes),
      requestedAt: Value(DateTime.utc(2026)),
    ),
  );

  StorageUsageCalculator calculator({ProfilePaths? profile}) =>
      StorageUsageCalculator(
        downloads: store,
        files: const IoFileSizes(),
        diskSpace: diskSpace,
        paths: profile,
      );

  test('totals match the seeded rows and files', () async {
    await item(
      const TrackItemKey('t1'),
      DownloadStatus.completed,
      sizeBytes: 1000,
    );
    await item(
      const EpisodeItemKey(podcastId: 'pod', episodeId: 'e1'),
      DownloadStatus.completed,
      sizeBytes: 500,
    );
    await item(
      const TrackItemKey('t2'),
      DownloadStatus.queued,
      expectedBytes: 9000,
    );
    // A file in media/ does not count: downloads come from the rows.
    write(p.join(paths.media, 'ab', 'stray.flac'), 7777);
    write(p.join(paths.images, 'a.jpg'), 300);
    write(p.join(paths.images, 'nested', 'b.jpg'), 200);
    write(paths.stateDb, 40);
    write('${paths.stateDb}-wal', 4);
    write('${paths.stateDb}-shm', 2);
    write(paths.cacheDb, 30);
    write('${paths.cacheDb}-wal', 3);
    diskSpace.free = 123456;

    final usage = await calculator(profile: paths).compute();

    expect(usage.downloadsBytes, 1500);
    expect(usage.downloadCount, 2);
    expect(usage.imageCacheBytes, 500);
    expect(usage.databaseBytes, 79);
    expect(usage.freeDiskBytes, 123456);
  });

  test('missing directories and files count as zero', () async {
    final usage = await calculator(profile: paths).compute();

    expect(usage.downloadsBytes, 0);
    expect(usage.downloadCount, 0);
    expect(usage.imageCacheBytes, 0);
    expect(usage.databaseBytes, 0);
    expect(usage.freeDiskBytes, isNull);
  });

  test('without profile paths (web) every figure is zero', () async {
    await item(
      const TrackItemKey('t1'),
      DownloadStatus.completed,
      sizeBytes: 1000,
    );

    final usage = await calculator().compute();

    expect(usage, StorageUsage.none);
  });
}
