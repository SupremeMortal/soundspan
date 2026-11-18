// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:drift/drift.dart'
    show ApplyInterceptor, QueryExecutor, QueryInterceptor, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/downloads/background_download_router.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_request_builder.dart';
import 'package:soundspan/core/downloads/download_scheduler.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/storage/state/device_settings_dao.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/platform/database_opener/database_opener.dart';
import 'package:soundspan/platform/downloader/downloader.dart';
import 'package:soundspan/platform/paths/paths.dart';
import 'package:soundspan_api/soundspan_api.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_reachability.dart';
import '../../helpers/fakes/fake_disk_space.dart';
import '../../helpers/fakes/fake_downloader.dart';

/// Two profiles' `state.db`s in memory that keep their rows across opens,
/// counting the opens and closes of each.
final class _ProfilesOpener implements DatabaseOpener {
  final Map<String, sqlite.Database> raw = {
    'a': sqlite.sqlite3.openInMemory(),
    'b': sqlite.sqlite3.openInMemory(),
  };
  final List<String> opened = [];
  int openCount = 0;

  /// An executor over profile [id]'s rows that does not count as an open.
  QueryExecutor direct(String id) =>
      NativeDatabase.opened(raw[id]!, closeUnderlyingOnClose: false);

  @override
  bool get isVolatile => false;

  @override
  QueryExecutor open(DatabaseTarget target) {
    final id = (target as StateDatabaseTarget).profileId;
    opened.add(id);
    openCount++;
    return NativeDatabase.opened(
      raw[id] ?? (throw StateError('no database for $id')),
      closeUnderlyingOnClose: false,
    ).interceptWith(_OnClose(() => openCount--));
  }

  @override
  Future<void> delete(DatabaseTarget target) async {}

  void dispose() {
    for (final db in raw.values) {
      db.close();
    }
  }
}

class _OnClose extends QueryInterceptor {
  new(this.onClose);

  final void Function() onClose;

  @override
  Future<void> close(QueryExecutor inner) async {
    await inner.close();
    onClose();
  }
}

String _task(DownloadItemKey key) => itemKeyHash(key);

DownloadRequest _request(String profileId, DownloadItemKey key) =>
    DownloadRequest(
      taskId: _task(key),
      url: Uri.parse('https://music.example.com/x'),
      headers: const {},
      profileId: profileId,
      relativeDirectory: 'media/aa',
      filename: '${_task(key)}.part',
      requiresWifi: false,
      highPriority: false,
      metaData: key.encode(),
    );

void main() {
  late Directory dir;
  late _ProfilesOpener opener;
  late FakeDownloader downloader;
  late FakeClock clock;
  late BackgroundDownloadRouter router;
  late Set<String> profiles;

  /// A running item of profile [id] with its task known to the downloader.
  Future<DownloadItemKey> running(String id, String playbackId) async {
    final key = TrackItemKey(playbackId);
    final db = StateDatabase(opener.direct(id));
    await DownloadStore(db).upsertItem(
      key,
      DownloadItemsCompanion(
        metaJson: const Value('{}'),
        status: const Value(DownloadStatus.running),
        downloadUrl: Value('/api/offline/download/${key.encode()}'),
        requestedAt: Value(clock.now()),
        taskId: Value(_task(key)),
      ),
    );
    await db.close();
    await downloader.enqueue(_request(id, key));
    return key;
  }

  Future<DownloadItem> row(String id, DownloadItemKey key) async {
    final db = StateDatabase(opener.direct(id));
    try {
      return (await DownloadStore(db).item(key))!;
    } finally {
      await db.close();
    }
  }

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('background_router');
    opener = _ProfilesOpener();
    downloader = FakeDownloader(appSupport: dir.path);
    clock = FakeClock(start: DateTime.utc(2026, 3, 1, 12));
    profiles = {'a', 'b'};
    router = BackgroundDownloadRouter(
      downloader: downloader,
      opener: opener,
      clock: clock,
      profileExists: (id) async => profiles.contains(id),
    )..activeProfileId = 'a';
    await router.start();
  });

  tearDown(() async {
    await router.dispose();
    await downloader.dispose();
    opener.dispose();
    dir.deleteSync(recursive: true);
  });

  test(
    'start starts the downloader once, however often it is called',
    () async {
      await router.start();

      expect(downloader.startCount, 1);
    },
  );

  test("an active-profile event reaches that profile's scheduler and opens "
      'no database', () async {
    final key = await running('a', 'active');
    final db = StateDatabase(opener.direct('a'));
    final profile = ProfilePaths.derive(
      appSupport: dir.path,
      appCache: '${dir.path}/cache',
      profileId: 'a',
    );
    final scheduler = DownloadScheduler(
      store: DownloadStore(db),
      downloader: downloader,
      requestBuilder: DownloadRequestBuilder(
        paths: DownloadPaths(profile),
        urls: StreamUrls(Uri.parse('https://music.example.com')),
        currentCredentials: () => const ApiKeyCredentials(apiKey: 'k'),
        ensureFresh: ({required minRemaining}) async =>
            const ApiKeyCredentials(apiKey: 'k'),
      ),
      reachability: FakeReachability(),
      settings: DeviceSettingsDao(db),
      diskSpace: FakeDiskSpace(),
      clock: clock,
      profileId: 'a',
      mediaDirectory: profile.media,
      refreshCredentials: () async {},
    );
    addTearDown(() async {
      await scheduler.dispose();
      await db.close();
    });
    await scheduler.start();
    await scheduler.settle();

    await downloader.complete(_task(key), bytes: 10);
    await scheduler.settle();
    await router.flush();

    expect((await row('a', key)).status, DownloadStatus.verifying);
    expect(opener.opened, isEmpty);
  });

  test('a completion for the inactive profile leaves its row verifying and '
      'its database closed', () async {
    final key = await running('b', 'done');

    await downloader.complete(_task(key), bytes: 10);
    await router.flush();

    expect((await row('b', key)).status, DownloadStatus.verifying);
    expect(opener.opened, ['b']);
    expect(opener.openCount, 0);
  });

  test('a failure for the inactive profile records the failure and the '
      'attempt', () async {
    final key = await running('b', 'broken');

    downloader.fail(_task(key), kind: DownloaderFailureKind.network);
    await router.flush();

    final failed = await row('b', key);
    expect(failed.status, DownloadStatus.failedRetryable);
    expect(failed.attempts, 1);
    expect(failed.nextAttemptAt, isNotNull);
    expect(opener.openCount, 0);
  });

  test('a pause for the inactive profile is recorded', () async {
    final key = await running('b', 'paused');

    downloader.emit(DownloaderPaused(taskId: _task(key), group: 'p:b'));
    await router.flush();

    expect((await row('b', key)).status, DownloadStatus.paused);
  });

  test('progress for an inactive profile opens no database', () async {
    final key = await running('b', 'moving');

    downloader
      ..emitProgress(_task(key), receivedBytes: 5, expectedBytes: 10)
      ..emit(
        DownloaderResponseInfo(
          taskId: _task(key),
          group: 'p:b',
          isStrongEtag: false,
        ),
      );
    await Future<void>.delayed(
      kBackgroundEventWindow + const Duration(milliseconds: 50),
    );
    await router.flush();

    expect(opener.opened, isEmpty);
    expect((await row('b', key)).status, DownloadStatus.running);
  });

  test(
    'an unknown profile id cancels the task and deletes its .part file',
    () async {
      const key = TrackItemKey('orphan');
      await downloader.enqueue(_request('gone', key));
      final part = File(downloader.pathOf(_task(key)))
        ..createSync(recursive: true)
        ..writeAsStringSync('partial');

      downloader.emit(
        DownloaderFailed(
          taskId: _task(key),
          group: 'p:gone',
          kind: DownloaderFailureKind.network,
        ),
      );
      await router.flush();

      expect(downloader.cancelled, [_task(key)]);
      expect(part.existsSync(), isFalse);
      expect(opener.opened, isEmpty);
    },
  );

  test('a burst of events within the window opens the database once', () async {
    final keys = [for (var i = 0; i < 4; i++) await running('b', 'burst-$i')];

    for (final key in keys.take(3)) {
      await downloader.complete(_task(key), bytes: 10);
    }
    downloader.fail(_task(keys[3]), kind: DownloaderFailureKind.network);
    await Future<void>.delayed(
      kBackgroundEventWindow + const Duration(milliseconds: 100),
    );
    await router.flush();

    expect(opener.opened, ['b']);
    for (final key in keys.take(3)) {
      expect((await row('b', key)).status, DownloadStatus.verifying);
    }
    expect((await row('b', keys[3])).status, DownloadStatus.failedRetryable);
  });

  test('events of one profile arriving after a batch is applied open the '
      'database again, after the first batch', () async {
    final first = await running('b', 'first');
    final second = await running('b', 'second');

    await downloader.complete(_task(first), bytes: 10);
    await Future<void>.delayed(
      kBackgroundEventWindow + const Duration(milliseconds: 100),
    );
    await downloader.complete(_task(second), bytes: 10);
    await router.flush();

    expect(opener.opened, ['b', 'b']);
    expect(opener.openCount, 0);
    expect((await row('b', second)).status, DownloadStatus.verifying);
  });
}
