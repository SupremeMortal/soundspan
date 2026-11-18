// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/app/session/downloads_sign_out_participant.dart';
import 'package:soundspan/app/session/sign_out_participant.dart';
import 'package:soundspan/app/session/sign_out_sequence.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/auth/profile_repository.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/offline_delete_queue.dart';
import 'package:soundspan/core/downloads/offline_models.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/platform/database_opener/database_opener.dart';
import 'package:soundspan/platform/downloader/downloader.dart';
import 'package:soundspan/shared/data/downloads/download_outbox.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import '../../core/downloads/download_controller_rig.dart';
import '../../core/logging/recording_sink.dart';
import '../../core/profile/profile_harness.dart';

/// The five tracks of the album every seeded rig pins.
const List<String> _tracks = ['pb-1', 'pb-2', 'pb-3', 'pb-4', 'pb-5'];

String _task(String playbackId) => itemKeyHash(TrackItemKey(playbackId));

/// A [Downloader] over the rig's fake that can fail or hang.
final class _Downloader implements Downloader {
  new(this.inner);

  final Downloader inner;

  /// When set, [cancel] throws it.
  Exception? cancelError;

  /// Whether [liveTaskIds] never completes.
  bool hangLive = false;

  @override
  Future<void> cancel(String taskId, {bool deletePartial = false}) async {
    if (cancelError case final error?) throw error;
    await inner.cancel(taskId, deletePartial: deletePartial);
  }

  @override
  Future<Set<String>> liveTaskIds({required String group}) async {
    if (hangLive) await Completer<void>().future;
    return await inner.liveTaskIds(group: group);
  }

  @override
  Future<void> start() => inner.start();

  @override
  Future<void> enqueue(DownloadRequest request) => inner.enqueue(request);

  @override
  Future<bool> pause(String taskId) => inner.pause(taskId);

  @override
  Future<bool> resume(String taskId) => inner.resume(taskId);

  @override
  Stream<DownloaderEvent> get events => inner.events;
}

/// An [OfflineDeleteQueue] that records each batch in [log] and can throw.
final class _DeleteQueue implements OfflineDeleteQueue {
  new(this.log, this.inner);

  final List<String> log;
  final OfflineDeleteQueue inner;

  /// The size of every batch, in order.
  final List<int> batches = [];

  /// When set, [enqueue] throws it.
  Exception? error;

  @override
  Future<void> enqueue({
    required String deviceId,
    required List<PlaybackId> playbackIds,
  }) async {
    if (error case final failure?) throw failure;
    batches.add(playbackIds.length);
    log.add('offlineDelete ${[for (final id in playbackIds) id.value]}');
    await inner.enqueue(deviceId: deviceId, playbackIds: playbackIds);
  }
}

/// The participant's scope, flushing the rig's outbox.
final class _Scope implements SignOutScope {
  new(this.log, this.downloads, this.participants);

  final List<String> log;
  final DownloadControllerRig downloads;

  @override
  final List<SignOutParticipant> participants;

  @override
  Future<void> flushOutbox() async {
    log.add('flush');
    await downloads.outbox.flush();
  }

  @override
  Future<int> pendingChanges() => downloads.outboxStore.watchCount().first;
}

final class _Revoker implements SessionRevoker {
  @override
  Future<void> revoke(Profile profile, api.Credentials credentials) async {}
}

/// One-shot timers a test fires.
final class _Timers {
  final List<_OneShot> created = [];

  Iterable<_OneShot> get active => created.where((t) => t.isActive);

  Timer create(Duration duration, void Function() callback) {
    final timer = _OneShot(duration, callback);
    created.add(timer);
    return timer;
  }
}

final class _OneShot implements Timer {
  new(this.duration, this._callback);

  final Duration duration;
  final void Function() _callback;
  bool _active = true;

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
  int get tick => 0;
}

Future<void> _until(bool Function() done) async {
  for (var i = 0; i < 200 && !done(); i++) {
    await pumpEventQueue();
  }
}

/// Profiles A (active) and B, profile A's downloads over in-memory
/// databases with `FakeApi` as the server, the participant and the
/// sign-out sequence.
final class _Rig {
  new _(this.h, this.runtime, this.d, this.deviceId);

  static Future<_Rig> create(Directory dir) async {
    final h = await ProfileHarness.create();
    final runtime = h.root.read(profileRuntimeProvider);
    addTearDown(runtime.dispose);
    await runtime.switchTo(h.a);
    final d = DownloadControllerRig(dir, profileId: h.a);
    addTearDown(d.dispose);
    await d.start();
    final profile = await h.root.read(profileRepositoryProvider).byId(h.a);
    return _Rig._(h, runtime, d, profile!.deviceId);
  }

  final ProfileHarness h;
  final ProfileRuntime runtime;
  final DownloadControllerRig d;
  final String deviceId;
  final List<String> log = [];
  final _Timers timers = _Timers();
  final _Timers sequenceTimers = _Timers();
  late final _Downloader downloader = _Downloader(d.downloader);
  late final _DeleteQueue deleteQueue = _DeleteQueue(
    log,
    OutboxOfflineDeleteQueue(d.outbox.enqueue),
  );

  late final DownloadsSignOutParticipant participant =
      DownloadsSignOutParticipant(
        store: d.store,
        scheduler: d.scheduler,
        controller: d.controller,
        downloader: downloader,
        deleteQueue: deleteQueue,
        mediaFiles: d.mediaFiles,
        paths: d.profilePaths,
        deviceId: deviceId,
        clock: d.clock,
        timer: timers.create,
      );

  late final SignOutSequence sequence = SignOutSequence(
    runtime: runtime,
    profiles: profiles,
    revoker: _Revoker(),
    opener: h.opener,
    clock: h.clock,
    scopeOf: (_) => _Scope(log, d, [participant]),
    cancelInactiveDownloads: (profileId) =>
        cancelDownloadTasks(d.downloader, profileId),
    timer: sequenceTimers.create,
  );

  ProfileRepository get profiles => h.root.read(profileRepositoryProvider);

  Future<ProfileState?> stateOf(String id) async =>
      (await profiles.byId(id))?.state;

  /// Pins an album of [_tracks]: the first two run, with `.part` files on
  /// disk; the other three are completed files. One artwork file is
  /// pinned.
  Future<void> seed() async {
    d.server.offline.albums['al'] = _tracks;
    await d.controller.pin(CollectionKind.album, 'al');
    await d.settle();
    expect(d.requested, [_task('pb-1'), _task('pb-2')]);
    for (final id in _tracks.take(2)) {
      File(d.downloader.pathOf(_task(id)))
        ..createSync(recursive: true)
        ..writeAsStringSync('partial');
    }
    for (final id in _tracks.skip(2)) {
      await d.completeOnDisk(id);
    }
    artwork
      ..createSync(recursive: true)
      ..writeAsStringSync('art');
  }

  File get artwork => File('${d.profilePaths.art}/0a1b.img');

  File part(String id) => File(d.downloader.pathOf(_task(id)));

  Future<File> finalFile(String id) async =>
      File(d.paths.resolve((await d.item(id))!.relativePath!));

  /// Every file left under `media/`.
  List<String> mediaFiles() {
    final media = Directory(d.profilePaths.media);
    if (!media.existsSync()) return const [];
    return [
      for (final file in media.listSync(recursive: true).whereType<File>())
        file.path,
    ];
  }

  /// The `playbackId`s of the pending and sent `offlineDelete` batches.
  Future<Set<String>> reportedDeletes() async => {
    for (final op in await d.pendingDeletes()) ...op.playbackIds,
    for (final request in d.deleteRequests) ...request.playbackIds,
  };

  /// Adds a completed episode with a file on disk and no collection.
  Future<File> addEpisode() async {
    const key = EpisodeItemKey(podcastId: 'pod-1', episodeId: 'ep-1');
    final relative = d.paths.relativeFinalFile(itemKeyHash(key), 'audio/mpeg');
    final file = File(d.paths.resolve(relative))
      ..createSync(recursive: true)
      ..writeAsStringSync('episode');
    await d.store.upsertItem(
      key,
      DownloadItemsCompanion(
        metaJson: const Value('{}'),
        requestedAt: Value(d.clock.now()),
        status: const Value(DownloadStatus.completed),
        sizeBytes: const Value(7),
        relativePath: Value(relative),
      ),
    );
    return file;
  }
}

void main() {
  late Directory dir;
  late RecordingSink logs;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('downloads_sign_out');
    logs = RecordingSink();
    AppLogging.configure(sinks: [logs], releaseMode: false);
  });
  tearDown(() {
    AppLogging.reset();
    dir.deleteSync(recursive: true);
  });

  test('sign-out, box unticked: running transfers are cancelled and '
      'queued without their .part files; completed files, rows and '
      'artwork stay; nothing is reported to the server', () async {
    final rig = await _Rig.create(dir);
    await rig.seed();

    await rig.sequence.signOut(rig.h.a);

    expect(
      rig.d.downloader.cancelled,
      containsAll([_task('pb-1'), _task('pb-2')]),
    );
    for (final id in ['pb-1', 'pb-2']) {
      final row = (await rig.d.item(id))!;
      expect(row.status, DownloadStatus.queued);
      expect(row.taskId, isNull);
      expect(rig.part(id).existsSync(), isFalse);
    }
    for (final id in ['pb-3', 'pb-4', 'pb-5']) {
      expect((await rig.d.item(id))!.status, DownloadStatus.completed);
      expect((await rig.finalFile(id)).existsSync(), isTrue);
    }
    expect(rig.artwork.existsSync(), isTrue);
    expect(await rig.d.collections(), hasLength(1));
    expect(await rig.reportedDeletes(), isEmpty);
    expect(await rig.stateOf(rig.h.a), ProfileState.signedOut);
  });

  test('sign-out, box ticked: no media file and no download row is left, '
      'and offlineDelete holds every track but no episode', () async {
    final rig = await _Rig.create(dir);
    await rig.seed();
    final episode = await rig.addEpisode();
    rig.d.setReachability(Reachability.noNetwork);

    await rig.sequence.signOut(rig.h.a, removeDownloads: true);

    expect(rig.mediaFiles(), isEmpty);
    expect(episode.existsSync(), isFalse);
    expect(await rig.d.items(), isEmpty);
    expect(await rig.d.collections(), isEmpty);
    expect(await rig.reportedDeletes(), _tracks.toSet());
    expect(await rig.stateOf(rig.h.a), ProfileState.signedOut);
  });

  test('remove server: offlineDelete is queued for confirmed and completed '
      'tracks before the flush, then media/ and art/ are gone', () async {
    final rig = await _Rig.create(dir);
    await rig.seed();
    await rig.d.store.markServerConfirmed(
      const TrackItemKey('pb-3'),
      rig.d.clock.now(),
    );
    await rig.addEpisode();
    rig.d.setReachability(Reachability.noNetwork);

    await rig.sequence.removeServer(rig.h.a);

    expect(rig.log, ['offlineDelete [pb-3, pb-4, pb-5]', 'flush']);
    expect(Directory(rig.d.profilePaths.media).existsSync(), isFalse);
    expect(Directory(rig.d.profilePaths.art).existsSync(), isFalse);
    expect(await rig.profiles.byId(rig.h.a), isNull);
  });

  test('remove server online sends DELETE /offline/items with the '
      "profile's deviceId", () async {
    final rig = await _Rig.create(dir);
    await rig.seed();

    await rig.sequence.removeServer(rig.h.a);

    final request = rig.d.deleteRequests.single;
    expect(request.deviceId, rig.deviceId);
    expect(request.playbackIds, unorderedEquals(['pb-3', 'pb-4', 'pb-5']));
    expect(await rig.d.pendingDeletes(), isEmpty);
    expect(await rig.profiles.byId(rig.h.a), isNull);
  });

  group('a best-effort step that fails', () {
    test('Downloader.cancel throws: the rows are still queued', () async {
      final rig = await _Rig.create(dir);
      await rig.seed();
      rig.downloader.cancelError = Exception('plugin gone');

      await rig.sequence.signOut(rig.h.a);

      expect((await rig.d.item('pb-1'))!.status, DownloadStatus.queued);
      expect(await rig.stateOf(rig.h.a), ProfileState.signedOut);
      expect(
        logs.entries.map((e) => e.message),
        contains('Cancelling a download failed'),
      );
    });

    test('liveTaskIds never completes: abandoned after 5 s', () async {
      final rig = await _Rig.create(dir);
      await rig.seed();
      rig.downloader.hangLive = true;
      var done = false;
      final run = rig.sequence.signOut(rig.h.a).then((_) => done = true);

      await _until(() => rig.timers.active.isNotEmpty);
      final timer = rig.timers.active.single;
      expect(timer.duration, const Duration(seconds: 5));
      expect(DownloadsSignOutParticipant.cancelBudget, timer.duration);
      expect(done, isFalse);
      timer.fire();
      await run;

      expect((await rig.d.item('pb-1'))!.status, DownloadStatus.queued);
      expect(await rig.stateOf(rig.h.a), ProfileState.signedOut);
      expect(
        logs.entries.map((e) => e.message),
        contains('Cancelling downloads timed out'),
      );
    });

    test('deleting one file throws: the others are still deleted', () async {
      final rig = await _Rig.create(dir);
      await rig.seed();
      final stuck = await rig.finalFile('pb-4');
      rig.d.mediaFiles.failingPaths.add(stuck.path);

      await rig.sequence.removeServer(rig.h.a);

      expect(rig.mediaFiles(), [stuck.path]);
      expect(rig.artwork.existsSync(), isFalse);
      expect(await rig.profiles.byId(rig.h.a), isNull);
    });

    test('deleting the files never completes: abandoned after 10 s', () async {
      final rig = await _Rig.create(dir);
      await rig.seed();
      rig.d.mediaFiles.treeGate = Completer<void>().future;
      var done = false;
      final run = rig.sequence.removeServer(rig.h.a).then((_) => done = true);

      await _until(
        () => rig.timers.active.any(
          (t) => t.duration == const Duration(seconds: 10),
        ),
      );
      expect(done, isFalse);
      expect(
        DownloadsSignOutParticipant.deleteBudget,
        const Duration(seconds: 10),
      );
      rig.timers.active.single.fire();
      await run;

      expect(await rig.profiles.byId(rig.h.a), isNull);
      expect(
        logs.entries.map((e) => e.message),
        contains('Deleting downloaded files timed out'),
      );
    });

    test(
      'enqueueing offlineDelete throws: the files are still deleted',
      () async {
        final rig = await _Rig.create(dir);
        await rig.seed();
        rig.deleteQueue.error = Exception('database locked');

        await rig.sequence.removeServer(rig.h.a);

        expect(rig.mediaFiles(), isEmpty);
        expect(await rig.profiles.byId(rig.h.a), isNull);
        expect(
          logs.entries.map((e) => e.message),
          contains('Queueing offline deletes failed'),
        );
      },
    );

    test('the flush is offline: the deletes stay stored after sign-out and '
        'go with the profile on removal', () async {
      final rig = await _Rig.create(dir);
      await rig.seed();
      rig.d.setReachability(Reachability.noNetwork);

      await rig.sequence.signOut(rig.h.a, removeDownloads: true);

      expect(await rig.stateOf(rig.h.a), ProfileState.signedOut);
      expect(await rig.d.pendingDeletes(), isNotEmpty);
      expect(rig.d.deleteRequests, isEmpty);

      await rig.sequence.removeServer(rig.h.a);

      expect(await rig.profiles.byId(rig.h.a), isNull);
      expect(rig.h.opener.deleted, contains(StateDatabaseTarget(rig.h.a)));
    });

    test('the server answers 500 to the delete', () async {
      final rig = await _Rig.create(dir);
      await rig.seed();
      rig.d.server.offline.deleteError = const api.ServerError(status: 500);

      await rig.sequence.removeServer(rig.h.a);

      expect(rig.d.deleteRequests, hasLength(1));
      expect(await rig.profiles.byId(rig.h.a), isNull);
    });
  });

  test('neither method throws with no downloads at all', () async {
    final rig = await _Rig.create(dir);

    await rig.participant.onSignOut(removeDownloads: true);
    await rig.participant.beforeRemove();

    expect(await rig.reportedDeletes(), isEmpty);
    expect(rig.d.downloader.cancelled, isEmpty);
    expect(
      await rig.participant.downloadsSummary(),
      const DownloadsSummary(itemCount: 0, bytes: 0),
    );
  });

  test('downloadsSummary counts completed items and their size', () async {
    final rig = await _Rig.create(dir);
    await rig.seed();

    expect(
      await rig.participant.downloadsSummary(),
      const DownloadsSummary(itemCount: 3, bytes: 30),
    );
  });

  test('1,200 items produce delete batches of 500, 500 and 200', () async {
    final rig = await _Rig.create(dir);
    rig.d.setReachability(Reachability.noNetwork);
    for (var i = 0; i < 1200; i++) {
      await rig.d.store.upsertItem(
        TrackItemKey('pb-$i'),
        DownloadItemsCompanion(
          metaJson: const Value('{}'),
          requestedAt: Value(rig.d.clock.now()),
          status: const Value(DownloadStatus.completed),
          sizeBytes: const Value(1),
        ),
      );
    }

    await rig.participant.beforeRemove();

    expect(rig.deleteQueue.batches, [500, 500, 200]);
    expect(
      [for (final op in await rig.d.pendingDeletes()) op.playbackIds.length],
      [500, 500, 200],
    );
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('inactive profile: its tasks are cancelled without opening its '
      "database; the active profile's tasks are untouched", () async {
    final rig = await _Rig.create(dir);
    await rig.seed();
    DownloadRequest request(String profileId, String taskId) => DownloadRequest(
      taskId: taskId,
      url: Uri.parse('https://b.example.com/x'),
      headers: const {},
      profileId: profileId,
      relativeDirectory: 'media/ab',
      filename: '$taskId.part',
      requiresWifi: false,
      highPriority: false,
      metaData: 't:x',
    );
    await rig.d.downloader.enqueue(request(rig.h.b, 'b-task'));
    rig.h.opener.opened.clear();

    await rig.sequence.signOut(rig.h.b);

    expect(rig.d.downloader.cancelled, ['b-task']);
    expect(
      await rig.d.downloader.liveTaskIds(group: downloaderGroup(rig.h.a)),
      {_task('pb-1'), _task('pb-2')},
    );
    expect(rig.h.opener.opened, isNot(contains(StateDatabaseTarget(rig.h.b))));
    expect(await rig.stateOf(rig.h.b), ProfileState.signedOut);
    expect(rig.log, isEmpty);
  });

  test('inactive profile removal cancels its tasks and logs that the '
      'server keeps its records', () async {
    final rig = await _Rig.create(dir);

    await rig.sequence.removeServer(rig.h.b);

    expect(await rig.profiles.byId(rig.h.b), isNull);
    expect(
      logs.entries.map((e) => e.message),
      contains(
        'Downloads of an inactive profile are not removed on the '
        'server',
      ),
    );
  });

  test('signing in again after an unticked sign-out hands the queued items '
      'to the scheduler and completed files still resolve', () async {
    final rig = await _Rig.create(dir);
    await rig.seed();
    await rig.sequence.signOut(rig.h.a);
    final before = rig.d.downloader.requests.length;

    final next = rig.d.buildScheduler();
    addTearDown(next.dispose);
    await next.start();
    await next.settle();

    expect(
      [for (final r in rig.d.downloader.requests.skip(before)) r.taskId],
      [_task('pb-1'), _task('pb-2')],
    );
    for (final id in ['pb-3', 'pb-4', 'pb-5']) {
      final path = await rig.d.store.completedFile(TrackItemKey(id));
      expect(File(path!).existsSync(), isTrue);
    }
  });

  test('no log line holds a token, a key or a playbackId', () async {
    final rig = await _Rig.create(dir);
    await rig.seed();
    rig.downloader.cancelError = Exception('plugin gone');
    rig.d.mediaFiles.failingPaths.add((await rig.finalFile('pb-3')).path);
    rig.d.server.offline.deleteError = const api.ServerError(status: 500);

    await rig.sequence.removeServer(rig.h.a);

    expect(logs.entries, isNotEmpty);
    for (final entry in logs.entries) {
      final line =
          '${entry.message} ${entry.fields} ${entry.error} '
          '${entry.stackTrace}';
      for (final secret in ['pb-', 'key-1', 'a-access', 'a-r']) {
        expect(line, isNot(contains(secret)), reason: line);
      }
    }
  });
}
