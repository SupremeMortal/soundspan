// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_request_builder.dart';
import 'package:soundspan/core/downloads/download_scheduler.dart';
import 'package:soundspan/core/downloads/download_state_machine.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/storage/state/device_settings_dao.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/platform/downloader/downloader.dart';
import 'package:soundspan/platform/paths/paths.dart';
import 'package:soundspan_api/soundspan_api.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_reachability.dart';
import '../../helpers/fakes/fake_disk_space.dart';
import '../../helpers/fakes/fake_downloader.dart';
import '../logging/recording_sink.dart';

const int _mb = 1024 * 1024;

/// Timers that fire only when the test moves the [FakeClock] through
/// [elapse].
class _FakeTimers {
  new(this.clock);

  final FakeClock clock;
  final List<_FakeTimer> _timers = [];

  Timer create(Duration delay, void Function() callback) {
    final timer = _FakeTimer(clock.now().add(delay), callback);
    _timers.add(timer);
    return timer;
  }

  /// Moves the clock forward by [duration], firing every timer that falls
  /// due on the way, in due order.
  void elapse(Duration duration) {
    final end = clock.now().add(duration);
    while (true) {
      final due =
          _timers.where((t) => t.isActive && !t.at.isAfter(end)).toList()
            ..sort((a, b) => a.at.compareTo(b.at));
      if (due.isEmpty) break;
      final next = due.first;
      clock.set(next.at);
      next.fire();
    }
    clock.set(end);
  }
}

class _FakeTimer implements Timer {
  new(this.at, this._callback);

  final DateTime at;
  final void Function() _callback;
  bool _active = true;

  void fire() {
    _active = false;
    _callback();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}

/// Everything a scheduler runs against, in memory.
class _Rig {
  new(this.dir) {
    clock = FakeClock(start: DateTime.utc(2026, 3, 1, 12));
    timers = _FakeTimers(clock);
    db = StateDatabase(NativeDatabase.memory());
    final profile = ProfilePaths.derive(
      appSupport: dir.path,
      appCache: '${dir.path}/cache',
      profileId: 'p1',
    );
    paths = DownloadPaths(profile);
    store = DownloadStore(db, paths: paths);
    settings = DeviceSettingsDao(db);
    downloader = FakeDownloader(appSupport: dir.path);
    scheduler = DownloadScheduler(
      store: store,
      downloader: downloader,
      requestBuilder: DownloadRequestBuilder(
        paths: paths,
        urls: StreamUrls(Uri.parse('https://music.example.com')),
        currentCredentials: () => credentials,
        ensureFresh: ({required minRemaining}) async => credentials,
      ),
      reachability: reachability,
      settings: settings,
      diskSpace: disk,
      clock: clock,
      profileId: 'p1',
      mediaDirectory: profile.media,
      refreshCredentials: () async {
        refreshes++;
        credentials = const ApiKeyCredentials(apiKey: 'key-2');
      },
      createTimer: timers.create,
    );
  }

  final Directory dir;
  late final FakeClock clock;
  late final _FakeTimers timers;
  late final StateDatabase db;
  late final DownloadPaths paths;
  late final DownloadStore store;
  late final DeviceSettingsDao settings;
  late final FakeDownloader downloader;
  late final DownloadScheduler scheduler;
  final FakeReachability reachability = FakeReachability();
  final FakeDiskSpace disk = FakeDiskSpace();
  Credentials credentials = const ApiKeyCredentials(apiKey: 'key-1');
  int refreshes = 0;

  /// Adds a collection of [count] tracks requested at [at]. The items are
  /// inserted in reverse so that membership order, not insertion order,
  /// decides.
  Future<List<DownloadItemKey>> collection(
    DownloadCollectionKind kind,
    String id,
    int count, {
    required DateTime at,
    int? expectedBytes,
  }) async {
    await store.upsertCollection(
      kind: kind,
      refId: id,
      title: id,
      metaJson: '{}',
      status: DownloadCollectionStatus.ready,
      requestedAt: at,
    );
    final keys = [
      for (var i = 0; i < count; i++)
        TrackItemKey(
          count == 1 && kind == DownloadCollectionKind.track ? id : '$id-$i',
        ),
    ];
    for (var i = count - 1; i >= 0; i--) {
      await item(keys[i], at: at, expectedBytes: expectedBytes);
      await store.addMembership(kind, id, keys[i], i);
    }
    return keys;
  }

  Future<List<DownloadItemKey>> album(String id, int count, {DateTime? at}) =>
      collection(
        DownloadCollectionKind.album,
        id,
        count,
        at: at ?? clock.now(),
      );

  Future<DownloadItemKey> single(String playbackId, {DateTime? at}) async =>
      (await collection(
        DownloadCollectionKind.track,
        playbackId,
        1,
        at: at ?? clock.now(),
      )).single;

  Future<void> item(
    DownloadItemKey key, {
    required DateTime at,
    DownloadStatus status = DownloadStatus.queued,
    int? expectedBytes,
    String? taskId,
    DateTime? nextAttemptAt,
    int attempts = 0,
  }) => store.upsertItem(
    key,
    DownloadItemsCompanion(
      metaJson: const Value('{}'),
      status: Value(status),
      downloadUrl: Value('/api/offline/download/${key.encode()}'),
      expectedBytes: Value(expectedBytes),
      requestedAt: Value(at),
      taskId: Value(taskId),
      nextAttemptAt: Value(nextAttemptAt),
      attempts: Value(attempts),
    ),
  );

  Future<void> settle() => scheduler.settle();

  Future<void> start() async {
    await scheduler.start();
    await settle();
  }

  Future<DownloadItem> row(DownloadItemKey key) async =>
      (await store.item(key))!;

  Future<DownloadStatus> status(DownloadItemKey key) async =>
      (await row(key)).status;

  Future<List<DownloadItem>> running() =>
      store.itemsByStatus(DownloadStatus.running);

  /// The task ids handed to the downloader, oldest first.
  List<String> get requested => [
    for (final request in downloader.requests) request.taskId,
  ];

  Future<void> complete(DownloadItemKey key, {int bytes = 10}) async {
    await downloader.complete(itemKeyHash(key), bytes: bytes);
    await settle();
  }

  Future<void> fail(
    DownloadItemKey key,
    DownloaderFailureKind kind, {
    int? httpStatus,
  }) async {
    downloader.fail(itemKeyHash(key), kind: kind, httpStatus: httpStatus);
    await settle();
  }

  Future<void> dispose() async {
    await scheduler.dispose();
    await downloader.dispose();
    await db.close();
  }
}

String _task(DownloadItemKey key) => itemKeyHash(key);

void main() {
  late Directory dir;
  late _Rig rig;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('download_scheduler');
    rig = _Rig(dir);
  });
  tearDown(() async {
    await rig.dispose();
    dir.deleteSync(recursive: true);
  });

  test('a downloader that cannot initialise is logged once and reports '
      'downloads as unavailable instead of throwing', () async {
    final sink = RecordingSink();
    AppLogging.configure(sinks: [sink], releaseMode: true);
    addTearDown(AppLogging.reset);
    rig.downloader.startError = const FileSystemException(
      'Unable to get application documents directory',
    );
    expect(rig.scheduler.isAvailable, isTrue);
    await rig.album('a', 2);

    await rig.start();
    rig.scheduler.pump();
    await rig.settle();

    expect(rig.scheduler.isAvailable, isFalse);
    expect(rig.requested, isEmpty);
    expect(sink.entries.where((e) => e.scope == 'Downloads').length, 1);
  });

  test('five queued items: exactly two are enqueued, and completing one '
      'enqueues the third', () async {
    final keys = await rig.album('a', 5);

    await rig.start();

    expect(rig.requested, [_task(keys[0]), _task(keys[1])]);
    expect((await rig.running()).length, 2);

    await rig.complete(keys[0]);

    expect(await rig.status(keys[0]), DownloadStatus.verifying);
    expect(rig.requested, [_task(keys[0]), _task(keys[1]), _task(keys[2])]);
    expect((await rig.running()).length, 2);
  });

  test('order: a single track requested after an album runs before the '
      "album's remaining items; albums run in request order and their "
      'items in track order', () async {
    final t0 = rig.clock.now();
    final a = await rig.album('a', 3, at: t0);
    final b = await rig.album('b', 2, at: t0.add(const Duration(minutes: 2)));
    final single = await rig.single(
      's',
      at: t0.add(const Duration(minutes: 1)),
    );

    await rig.start();
    // Complete the oldest running item until nothing is left.
    for (var i = 0; i < 6; i++) {
      final running = await rig.running();
      if (running.isEmpty) break;
      final next = rig.requested.firstWhere(
        (id) => running.any((r) => r.taskId == id),
      );
      await rig.downloader.complete(next, bytes: 10);
      await rig.settle();
    }

    expect(rig.requested, [
      _task(single),
      _task(a[0]),
      _task(a[1]),
      _task(a[2]),
      _task(b[0]),
      _task(b[1]),
    ]);
    expect(rig.downloader.requests.first.highPriority, isTrue);
    expect(rig.downloader.requests[1].highPriority, isFalse);
  });

  test('Wi-Fi only: on mobile data nothing starts; a running item is paused '
      'for Wi-Fi and resumes when Wi-Fi returns', () async {
    await rig.settings.write(downloadsWifiOnlyKey, true);
    rig.reachability.connectionType = ConnectionType.cellular;
    final keys = await rig.album('a', 1);

    await rig.start();
    expect(rig.requested, isEmpty);

    rig.reachability.connectionType = ConnectionType.wifi;
    await rig.settle();
    expect(rig.requested, [_task(keys[0])]);
    expect(rig.downloader.requests.single.requiresWifi, isTrue);
    expect(await rig.status(keys[0]), DownloadStatus.running);

    rig.reachability.connectionType = ConnectionType.cellular;
    await rig.settle();
    final paused = await rig.row(keys[0]);
    expect(paused.status, DownloadStatus.paused);
    expect(paused.waitingFor, DownloadWaitReason.wifi.name);

    rig.reachability.connectionType = ConnectionType.wifi;
    await rig.settle();
    expect(await rig.status(keys[0]), DownloadStatus.running);
    expect(rig.requested, [_task(keys[0]), _task(keys[0])]);
  });

  test('turning Wi-Fi only on while on mobile data pauses the running '
      'item', () async {
    rig.reachability.connectionType = ConnectionType.cellular;
    final keys = await rig.album('a', 1);
    await rig.start();
    expect(await rig.status(keys[0]), DownloadStatus.running);

    await rig.settings.write(downloadsWifiOnlyKey, true);
    await pumpEventQueue();
    await rig.settle();

    expect(await rig.status(keys[0]), DownloadStatus.paused);
  });

  test('not online: nothing is enqueued; returning online pumps', () async {
    rig.reachability.set(Reachability.serverUnreachable);
    await rig.album('a', 3);

    await rig.start();
    expect(rig.requested, isEmpty);

    rig.reachability.set(Reachability.online);
    await rig.settle();
    expect(rig.requested.length, 2);
  });

  test('free space: an item waits for space when the disk lacks the reserve '
      'plus its size, starts once space is raised, and unknown space does '
      'not block', () async {
    rig.disk.free = 505 * _mb;
    final keys = await rig.collection(
      DownloadCollectionKind.album,
      'a',
      1,
      at: rig.clock.now(),
      expectedBytes: 10 * _mb,
    );

    await rig.start();
    final waiting = await rig.row(keys[0]);
    expect(waiting.status, DownloadStatus.queued);
    expect(waiting.waitingFor, DownloadWaitReason.space.name);
    expect(rig.requested, isEmpty);
    expect(rig.disk.asked, contains(rig.paths.profile.media));

    rig.disk.free = 520 * _mb;
    rig.scheduler.pump();
    await rig.settle();
    final started = await rig.row(keys[0]);
    expect(started.status, DownloadStatus.running);
    expect(started.waitingFor, isNull);

    await rig.complete(keys[0]);
    rig.disk.free = null;
    final more = await rig.album('b', 1);
    rig.scheduler.pump();
    await rig.settle();
    expect(await rig.status(more[0]), DownloadStatus.running);
  });

  test('an unknown size counts as 8 MB against free space', () async {
    rig.disk.free = 500 * _mb + 7 * _mb;
    final keys = await rig.album('a', 1);

    await rig.start();
    expect((await rig.row(keys[0])).waitingFor, DownloadWaitReason.space.name);

    rig.disk.free = 500 * _mb + 8 * _mb;
    rig.scheduler.pump();
    await rig.settle();
    expect(await rig.status(keys[0]), DownloadStatus.running);
  });

  test('an item the device limit marked as waiting for space is skipped '
      'until the marker is cleared', () async {
    final keys = await rig.album('a', 1);
    await rig.store.setWaitingFor(keys[0], DownloadWaitReason.space);

    await rig.start();
    expect(rig.requested, isEmpty);

    await rig.store.setWaitingFor(keys[0], null);
    rig.scheduler.pump();
    await rig.settle();
    expect(await rig.status(keys[0]), DownloadStatus.running);
  });

  test('DownloaderFailed(noSpace) pauses for space without counting an '
      'attempt', () async {
    final keys = await rig.album('a', 1);
    await rig.start();

    rig.disk.free = 100 * _mb;
    await rig.fail(keys[0], DownloaderFailureKind.noSpace);

    final row = await rig.row(keys[0]);
    expect(row.status, DownloadStatus.paused);
    expect(row.waitingFor, DownloadWaitReason.space.name);
    expect(row.attempts, 0);
    expect(rig.requested.length, 1);

    rig.disk.free = 600 * _mb;
    rig.scheduler.pump();
    await rig.settle();
    expect(await rig.status(keys[0]), DownloadStatus.running);
  });

  test('a retryable failure is not enqueued before its backoff elapses and '
      'is enqueued once after it', () async {
    final keys = await rig.album('a', 1);
    await rig.start();

    await rig.fail(keys[0], DownloaderFailureKind.network);
    final failed = await rig.row(keys[0]);
    expect(failed.status, DownloadStatus.failedRetryable);
    expect(
      failed.nextAttemptAt,
      rig.clock.now().add(const Duration(seconds: 5)),
    );

    rig.timers.elapse(const Duration(seconds: 4));
    await rig.settle();
    expect(rig.requested.length, 1);

    rig.timers.elapse(const Duration(seconds: 1));
    await rig.settle();
    expect(rig.requested.length, 2);
    expect(await rig.status(keys[0]), DownloadStatus.running);

    rig.timers.elapse(const Duration(hours: 1));
    await rig.settle();
    expect(rig.requested.length, 2);
  });

  test('a 401 refreshes the credentials and the retry carries the new '
      'header', () async {
    final keys = await rig.album('a', 1);
    await rig.start();
    expect(rig.downloader.requests.single.headers, {'X-API-Key': 'key-1'});

    await rig.fail(keys[0], DownloaderFailureKind.http, httpStatus: 401);
    expect(rig.refreshes, 1);

    rig.timers.elapse(const Duration(seconds: 5));
    await rig.settle();
    expect(rig.downloader.requests.last.headers, {'X-API-Key': 'key-2'});
  });

  test('a permanent failure and the other effects are left to the '
      'controller on the effects stream', () async {
    final effects = <DownloadItemEffect>[];
    rig.scheduler.effects.listen(effects.add);
    final keys = await rig.album('a', 1);
    await rig.start();

    await rig.fail(keys[0], DownloaderFailureKind.http, httpStatus: 404);
    await pumpEventQueue();

    expect(await rig.status(keys[0]), DownloadStatus.failedPermanent);
    expect(effects, [DownloadItemEffect(keys[0], const ReResolveCollection())]);
  });

  test('resumeItem with a task that cannot resume deletes the .part file '
      'and restarts from byte zero', () async {
    final keys = await rig.album('a', 1);
    await rig.start();
    final part = File(rig.downloader.pathOf(_task(keys[0])))
      ..createSync(recursive: true)
      ..writeAsBytesSync([1, 2, 3]);

    await rig.scheduler.pauseItem(keys[0]);
    await rig.settle();
    final paused = await rig.row(keys[0]);
    expect(paused.status, DownloadStatus.paused);
    expect(paused.waitingFor, DownloadWaitReason.user.name);
    expect(part.existsSync(), isTrue);

    await rig.scheduler.resumeItem(keys[0]);
    await rig.settle();

    expect(part.existsSync(), isFalse);
    expect(await rig.status(keys[0]), DownloadStatus.running);
    expect(rig.requested, [_task(keys[0]), _task(keys[0])]);
  });

  test('a paused queued item does not start until it is resumed', () async {
    final keys = await rig.album('a', 3);
    await rig.scheduler.pauseItem(keys[0]);

    await rig.start();
    expect(rig.requested, [_task(keys[1]), _task(keys[2])]);

    await rig.scheduler.resumeItem(keys[0]);
    await rig.complete(keys[1]);
    expect(rig.requested.last, _task(keys[0]));
  });

  test('cancelItem stops the transfer, deletes its .part file and frees '
      'the slot', () async {
    final keys = await rig.album('a', 3);
    await rig.start();

    await rig.scheduler.cancelItem(keys[0]);
    await rig.settle();

    expect(rig.downloader.cancelled, [_task(keys[0])]);
    expect(rig.requested, [_task(keys[0]), _task(keys[1]), _task(keys[2])]);
  });

  test('progress is written at most once per item per second and the '
      'response fills in the etag and a missing size', () async {
    final keys = await rig.album('a', 1);
    await rig.start();
    final task = _task(keys[0]);

    rig.downloader.emitProgress(task, receivedBytes: 100);
    await rig.settle();
    rig.downloader.emitProgress(task, receivedBytes: 200);
    await rig.settle();
    expect((await rig.row(keys[0])).receivedBytes, 100);

    rig.clock.advance(const Duration(seconds: 1));
    rig.downloader.emitProgress(task, receivedBytes: 300);
    await rig.settle();
    expect((await rig.row(keys[0])).receivedBytes, 300);

    await rig.downloader.complete(
      task,
      bytes: 10,
      etag: '"e1"',
      contentLength: 10,
    );
    await rig.settle();
    final row = await rig.row(keys[0]);
    expect(row.etag, '"e1"');
    expect(row.expectedBytes, 10);
  });

  test('start-up: a running row without a live task goes back to queued and '
      'is enqueued again; one with a live task is left alone and its later '
      'completion is processed', () async {
    final at = rig.clock.now();
    const lost = TrackItemKey('lost');
    const live = TrackItemKey('live');
    await rig.item(
      lost,
      at: at,
      status: DownloadStatus.running,
      taskId: _task(lost),
    );
    await rig.item(
      live,
      at: at,
      status: DownloadStatus.running,
      taskId: _task(live),
    );
    await rig.downloader.enqueue(
      DownloadRequest(
        taskId: _task(live),
        url: Uri.parse('https://music.example.com/x'),
        headers: const {},
        profileId: 'p1',
        relativeDirectory: 'media/${_task(live).substring(0, 2)}',
        filename: '${_task(live)}.part',
        requiresWifi: false,
        highPriority: false,
        metaData: live.encode(),
      ),
    );
    rig.downloader.requests.clear();

    await rig.start();

    expect(rig.downloader.startCount, 1);
    expect(rig.requested, [_task(lost)]);
    expect(await rig.status(lost), DownloadStatus.running);
    expect(await rig.status(live), DownloadStatus.running);

    await rig.complete(live);
    expect(await rig.status(live), DownloadStatus.verifying);
  });

  test(
    'start-up: a failedRetryable row is retried at its stored time',
    () async {
      const key = TrackItemKey('retry');
      await rig.item(
        key,
        at: rig.clock.now(),
        status: DownloadStatus.failedRetryable,
        attempts: 1,
        nextAttemptAt: rig.clock.now().add(const Duration(seconds: 30)),
      );

      await rig.start();
      rig.timers.elapse(const Duration(seconds: 29));
      await rig.settle();
      expect(rig.requested, isEmpty);

      rig.timers.elapse(const Duration(seconds: 1));
      await rig.settle();
      expect(rig.requested, [_task(key)]);
      expect((await rig.row(key)).attempts, 1);
    },
  );

  test('pauseAll then resumeAll restores two running items', () async {
    await rig.album('a', 4);
    await rig.start();
    expect((await rig.running()).length, 2);

    await rig.scheduler.pauseAll();
    await rig.settle();
    expect(await rig.running(), isEmpty);
    expect(rig.requested.length, 2);

    await rig.scheduler.resumeAll();
    await rig.settle();
    expect((await rig.running()).length, 2);
  });

  test('no more than two items run at any point of a randomised event '
      'sequence', () async {
    final random = Random(172);
    await rig.album('a', 6);
    await rig.single('s');
    await rig.album('b', 3);
    await rig.start();

    for (var step = 0; step < 120; step++) {
      final running = await rig.running();
      final pick = running.isEmpty
          ? null
          : running[random.nextInt(running.length)];
      final key = pick == null ? null : DownloadItemKey.decode(pick.itemKey);
      switch (random.nextInt(9)) {
        case 0 when key != null:
          await rig.complete(key);
        case 1 when key != null:
          await rig.fail(key, DownloaderFailureKind.network);
        case 2 when key != null:
          await rig.fail(key, DownloaderFailureKind.noSpace);
        case 3:
          rig.reachability.set(
            random.nextBool()
                ? Reachability.online
                : Reachability.serverUnreachable,
          );
        case 4:
          rig.timers.elapse(const Duration(minutes: 30));
        case 5 when key != null:
          await rig.scheduler.pauseItem(key);
        case 6:
          final paused = await rig.store.itemsByStatus(DownloadStatus.paused);
          if (paused.isNotEmpty) {
            await rig.scheduler.resumeItem(
              DownloadItemKey.decode(paused.first.itemKey),
            );
          }
        case 7:
          rig.disk.free = random.nextBool() ? null : 600 * _mb;
          rig.scheduler.pump();
        case _:
          rig.scheduler.pump();
      }
      await rig.settle();
      expect((await rig.running()).length, lessThanOrEqualTo(2));
      expect(
        (await rig.downloader.liveTaskIds(group: 'p:p1')).length,
        lessThanOrEqualTo(2),
      );
    }
  });
}
