// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart' show CancelToken, Options;
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_request_builder.dart';
import 'package:soundspan/core/downloads/download_scheduler.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/downloads/offline_repository.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/core/storage/state/device_settings_dao.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/core/sync/outbox/outbox.dart';
import 'package:soundspan/core/sync/outbox/outbox_handler.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/core/sync/outbox/outbox_store.dart';
import 'package:soundspan/core/sync/outbox/outbox_worker.dart';
import 'package:soundspan/core/sync/outbox/temp_id_rewriter.dart';
import 'package:soundspan/platform/paths/paths.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/downloads/download_outbox.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan/shared/domain/track.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import '../../helpers/fake_api.dart';
import '../../helpers/fake_clock.dart';
import '../../helpers/fake_reachability.dart';
import '../../helpers/fakes/fake_disk_space.dart';
import '../../helpers/fakes/fake_downloader.dart';
import '../../helpers/fakes/fake_media_files.dart';
import '../sync/outbox/outbox_test_support.dart' show ManualTimer;

/// A retry timer the test fires with [fire].
final class RigTimer implements Timer {
  /// Creates a timer that would run [_callback] after [delay].
  new(this.delay, this._callback);

  /// The delay the scheduler asked for.
  final Duration delay;
  final void Function() _callback;
  bool _active = true;

  /// Runs the callback, as the delay elapsing would.
  void fire() {
    if (!_active) return;
    _active = false;
    _callback();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => _active ? 0 : 1;
}

/// The device id of the rig's profile.
const String rigDeviceId = 'device-1';

/// A track with [id] as its playback id and [title].
Track rigTrack(String id, {String? title, String? albumId}) => Track(
  meta: TrackMeta(
    title: title ?? 'Song $id',
    artist: 'Contract Aurora',
    album: 'First Light',
    durationSec: 30,
  ),
  playbackId: PlaybackId(id),
  albumId: albumId,
  artistId: 'ar-1',
  discNumber: 1,
  trackNumber: 2,
  loudness: const Loudness(loudnessLufs: -9),
);

/// An offline client whose `POST /offline/items` waits for [gate].
final class GatedOfflineClient implements api.OfflineClient {
  /// Wraps [inner].
  new(this.inner);

  /// The server model.
  final FakeOfflineClient inner;

  /// Completed by the test to let the request through.
  final Completer<void> gate = Completer<void>();

  @override
  Future<api.OfflineItemsResponse> requestOfflineItems({
    required api.RequestOfflineItemsRequest body,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    await gate.future;
    return await inner.requestOfflineItems(body: body);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// A profile's downloads over in-memory databases: the controller, a
/// started scheduler, the outbox and [FakeApi] as the server.
final class DownloadControllerRig {
  /// Creates the rig in [dir]; [offlineClient] replaces the fake server's
  /// offline client when given.
  new(this.dir, {api.OfflineClient? offlineClient}) {
    // Each rig has its own in-memory databases.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    clock = FakeClock(start: DateTime.utc(2026, 3, 1, 12));
    state = StateDatabase(NativeDatabase.memory());
    cacheDb = CacheDatabase(NativeDatabase.memory());
    cache = CacheStore(cacheDb, clock);
    final profile = ProfilePaths.derive(
      appSupport: dir.path,
      appCache: '${dir.path}/cache',
      profileId: 'p1',
    );
    paths = DownloadPaths(profile);
    store = DownloadStore(state, paths: paths);
    settings = DeviceSettingsDao(state);
    downloader = FakeDownloader(appSupport: dir.path);
    const credentials = api.ApiKeyCredentials(apiKey: 'key-1');
    scheduler = DownloadScheduler(
      store: store,
      downloader: downloader,
      requestBuilder: DownloadRequestBuilder(
        paths: paths,
        urls: api.StreamUrls(Uri.parse('https://music.example.com')),
        currentCredentials: () => credentials,
        ensureFresh: ({required minRemaining}) async => credentials,
      ),
      reachability: reachability,
      settings: settings,
      diskSpace: diskSpace,
      clock: clock,
      profileId: 'p1',
      mediaDirectory: profile.media,
      refreshCredentials: () async {},
      createTimer: (delay, callback) {
        final timer = RigTimer(delay, callback);
        retryTimers.add(timer);
        return timer;
      },
    );
    offline = OfflineRepository(offlineClient ?? server.offline);
    outboxStore = OutboxStore(state, clock);
    worker = OutboxWorker(
      outboxStore,
      OutboxHandlerRegistry(
        downloadOutboxHandlers(offline, store: store, clock: clock),
      ),
      reachability,
      clock,
      AppLogger.scope('DownloadControllerTest'),
      rewriter: TempIdRewriter(state, () async => cacheDb),
      periodicTimer: ManualTimer.new,
    );
    final outbox = Outbox(outboxStore, worker);
    controller = DownloadController(
      store: store,
      offline: offline,
      scheduler: scheduler,
      reachability: reachability,
      settings: settings,
      deleteQueue: OutboxOfflineDeleteQueue(outbox.enqueue),
      completeQueue: OutboxOfflineCompleteQueue(outbox.enqueue),
      diskSpace: diskSpace,
      cachedTrack: (id) async =>
          (await cache.watchTrack(id.value).first)?.value,
      mediaFiles: mediaFiles,
      clock: clock,
      deviceId: rigDeviceId,
      paths: paths,
    );
  }

  /// The temporary directory standing in for application support.
  final Directory dir;

  /// The server.
  final FakeApi server = FakeApi();

  /// Reachability, `online` at first.
  final FakeReachability reachability = FakeReachability();

  /// The file seam.
  final FakeMediaFiles mediaFiles = FakeMediaFiles();

  /// Free disk space, unknown at first.
  final FakeDiskSpace diskSpace = FakeDiskSpace();

  /// The scheduler's retry timers, oldest first.
  final List<RigTimer> retryTimers = [];

  late final FakeClock clock;
  late final StateDatabase state;
  late final CacheDatabase cacheDb;
  late final CacheStore cache;
  late final DownloadPaths paths;
  late final DownloadStore store;
  late final DeviceSettingsDao settings;
  late final FakeDownloader downloader;
  late final DownloadScheduler scheduler;
  late final OfflineRepository offline;
  late final OutboxStore outboxStore;
  late final OutboxWorker worker;
  late final DownloadController controller;

  /// Starts the scheduler, the outbox worker and the controller.
  Future<void> start() async {
    await scheduler.start();
    await worker.start();
    controller.start();
    await settle();
  }

  /// Waits for the scheduler, the controller and the outbox worker, and
  /// for the work each hands the others.
  Future<void> settle() async {
    for (var round = 0; round < 4; round++) {
      await scheduler.settle();
      await controller.settle();
      await worker.idle;
    }
  }

  /// Fires every pending retry timer.
  void fireRetries() {
    final due = retryTimers.where((t) => t.isActive).toList();
    for (final timer in due) {
      timer.fire();
    }
  }

  /// The `POST /offline/items` bodies the server received.
  List<api.RequestOfflineItemsRequest> get resolveRequests => server
      .offline
      .requests
      .whereType<api.RequestOfflineItemsRequest>()
      .toList();

  /// The `DELETE /offline/items` bodies the server received.
  List<api.DeleteOfflineItemsRequest> get deleteRequests => server
      .offline
      .requests
      .whereType<api.DeleteOfflineItemsRequest>()
      .toList();

  /// The task ids handed to the downloader, oldest first.
  List<String> get requested => [
    for (final request in downloader.requests) request.taskId,
  ];

  /// Every item row.
  Future<List<DownloadItem>> items() => state.select(state.downloadItems).get();

  /// Every collection row.
  Future<List<DownloadCollection>> collections() =>
      state.select(state.downloadCollections).get();

  /// Every membership row.
  Future<List<DownloadMembershipData>> memberships() =>
      state.select(state.downloadMembership).get();

  /// The row of track [playbackId].
  Future<DownloadItem?> item(String playbackId) =>
      store.item(TrackItemKey(playbackId));

  /// The decoded `metaJson` of track [playbackId].
  Future<Map<String, Object?>> meta(String playbackId) async =>
      jsonDecode((await item(playbackId))!.metaJson) as Map<String, Object?>;

  /// The pending `offlineDelete` ops.
  Future<List<OfflineDeleteOp>> pendingDeletes() async => [
    for (final entry in await outboxStore.pending())
      if (entry.op case final OfflineDeleteOp op) op,
  ];

  /// Marks track [playbackId] completed at [quality] with a real file of
  /// [bytes] bytes, and answers the file's path.
  Future<String> completeOnDisk(
    String playbackId, {
    String quality = 'original',
    int bytes = 10,
  }) async {
    final key = TrackItemKey(playbackId);
    final relative = paths.relativeFinalFile(itemKeyHash(key), 'audio/flac');
    final file = File(paths.resolve(relative))
      ..createSync(recursive: true)
      ..writeAsBytesSync(List.filled(bytes, 1));
    final row = (await store.item(key))!;
    await store.upsertItem(
      key,
      DownloadItemsCompanion(
        metaJson: Value(row.metaJson),
        requestedAt: Value(row.requestedAt),
        status: const Value(DownloadStatus.completed),
        quality: Value(quality),
        sizeBytes: Value(bytes),
        relativePath: Value(relative),
        taskId: const Value(null),
      ),
    );
    return file.path;
  }

  /// Sets reachability to [state].
  void setReachability(Reachability state) => reachability.set(state);

  /// Releases everything.
  Future<void> dispose() async {
    await controller.dispose();
    await worker.dispose();
    await scheduler.dispose();
    await downloader.dispose();
    await state.close();
    await cacheDb.close();
  }
}
