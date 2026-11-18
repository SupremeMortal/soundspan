// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Keeps the device and the server in agreement about what is downloaded
/// (doc 07, Reconciliation).
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show immutable, visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/download_artwork.dart';
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_scheduler.dart';
import 'package:soundspan/core/downloads/download_state_machine.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/downloads/offline_delete_queue.dart';
import 'package:soundspan/core/downloads/offline_repository.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/core/profile/profile_disposer.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/storage/state/device_settings_dao.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/platform/downloader/downloader.dart';
import 'package:soundspan/platform/media_files/media_files.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/data/downloads/download_outbox.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// The `device_settings` key of the last successful server pass, an
/// ISO-8601 UTC time.
const String downloadsLastReconciledAtKey = 'downloads.lastReconciledAt';

/// How often the server pass runs at most, unless forced.
const Duration kReconcileInterval = Duration(hours: 6);

/// Creates the timer of the next due pass; [Timer.new] outside tests.
typedef ReconcileTimerFactory = Timer Function(
  Duration delay,
  void Function() callback,
);

/// What a server pass did.
@immutable
final class ReconcileReport {
  /// Creates the report.
  const new({
    this.revoked = 0,
    this.resent = 0,
    this.confirmed = 0,
    this.deletedOnServer = 0,
  });

  /// Local items the server revoked, now removed.
  final int revoked;

  /// Completed items the server did not know, reported again.
  final int resent;

  /// Completed items newly marked as confirmed by the server.
  final int confirmed;

  /// Playback ids queued for `DELETE /offline/items`.
  final int deletedOnServer;

  @override
  String toString() =>
      'ReconcileReport(revoked: $revoked, resent: $resent, '
      'confirmed: $confirmed, deletedOnServer: $deletedOnServer)';
}

/// What a local scan did.
@immutable
final class ScanReport {
  /// Creates the report.
  const new({
    this.missing = 0,
    this.orphansDeleted = 0,
    this.adopted = 0,
    this.artworkRemoved = 0,
  });

  /// Completed items whose file was absent or the wrong size, queued again.
  final int missing;

  /// Files under `media/` that belonged to no item, deleted.
  final int orphansDeleted;

  /// Renamed files whose row had not caught up, completed.
  final int adopted;

  /// Pinned covers nothing referenced, deleted.
  final int artworkRemoved;

  @override
  String toString() =>
      'ScanReport(missing: $missing, orphansDeleted: $orphansDeleted, '
      'adopted: $adopted, artworkRemoved: $artworkRemoved)';
}

/// Reconciles one profile's downloads with the server and with its files
/// (doc 07, Reconciliation).
///
/// The server pass ([runServerPass], rules 1 to 4) compares
/// `GET /offline/items` with the local track items: revoked items are
/// removed, completed items the server does not know are reported again,
/// known ones are marked confirmed, and server records with no local item
/// are deleted on the server through the outbox. The local scan
/// ([runLocalScan], rule 5) needs no server: completed items without their
/// file are queued again, files that belong to no item are deleted, a file
/// renamed just before a crash is adopted, and unreferenced covers go.
///
/// [start] scans at once and runs the server pass when online; afterwards
/// the pass runs when reachability returns to `online` and every
/// [kReconcileInterval], at most once per interval unless forced.
class DownloadReconciler {
  /// Creates the reconciler of the profile whose device id is `deviceId`
  /// and whose downloader group is that of `profileId`.
  new({
    required this._store,
    required this._offline,
    required this._scheduler,
    required this._controller,
    required this._deleteQueue,
    required this._downloader,
    required this._reachability,
    required this._settings,
    required this._mediaFiles,
    required this._artwork,
    required this._clock,
    required this._deviceId,
    required String profileId,
    required this._paths,
    this._createTimer = Timer.new,
  }) : _group = downloaderGroup(profileId);

  static final AppLogger _log = AppLogger.scope('Downloads');

  final DownloadStore _store;
  final OfflineRepository _offline;
  final DownloadScheduler _scheduler;
  final DownloadController _controller;
  final OfflineDeleteQueue _deleteQueue;
  final Downloader _downloader;
  final ReachabilityController _reachability;
  final DeviceSettingsDao _settings;
  final MediaFiles _mediaFiles;
  final DownloadArtwork _artwork;
  final Clock _clock;
  final String _deviceId;
  final String _group;
  final DownloadPaths _paths;
  final ReconcileTimerFactory _createTimer;

  StreamSubscription<Reachability>? _subscription;
  Timer? _timer;
  Future<ReconcileReport>? _pass;
  bool _started = false;
  bool _disposed = false;

  /// Runs the local scan, then the server pass when reachability is
  /// `online` (it is also how a sign-in reconciles, since signing in
  /// activates the profile afresh), and from then on runs the pass when
  /// reachability returns to `online` and on a timer, both subject to the
  /// interval. Later calls do nothing.
  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    _subscription = _reachability.changes.listen((state) {
      if (state == Reachability.online) unawaited(_guarded());
    });
    try {
      await runLocalScan();
    } on Object catch (error, stackTrace) {
      _log.warning(
        'The download scan did not finish',
        const {},
        error,
        stackTrace,
      );
    }
    if (_reachability.isOnline) {
      await _guarded(force: true);
    } else {
      await _arm();
    }
  }

  /// Runs the server pass when it is due: reachability is `online` and the
  /// last successful pass is older than [kReconcileInterval], or [force].
  /// Calls made while a pass runs share it.
  Future<void> runIfDue({bool force = false}) async {
    if (_disposed) return;
    final running = _pass;
    if (running != null) {
      await running;
      return;
    }
    try {
      if (!_reachability.isOnline) return;
      if (!force) {
        final last = await lastReconciledAt();
        if (last != null &&
            _clock.now().difference(last) < kReconcileInterval) {
          return;
        }
      }
      final pass = runServerPass();
      _pass = pass;
      try {
        await pass;
      } on api.ApiException catch (error) {
        // Nothing changed locally; the next trigger retries.
        _log.info("Could not list this device's downloads on the server", {
          'error': '$error',
        });
      } finally {
        _pass = null;
      }
    } finally {
      await _arm();
    }
  }

  /// When the last successful server pass ran, or null when none has.
  Future<DateTime?> lastReconciledAt() async {
    final stored = await _settings.read(downloadsLastReconciledAtKey);
    return stored is String ? DateTime.tryParse(stored)?.toUtc() : null;
  }

  /// Rules 1 to 4: compares the server's records of this device with the
  /// local track items; episodes are never part of it. Throws the
  /// server's [api.ApiException], having changed nothing locally, when the
  /// records cannot be listed.
  Future<ReconcileReport> runServerPass() async {
    final server = await _offline.list(deviceId: _deviceId);
    final local = <String, DownloadItem>{
      for (final row in await _store.items())
        if (DownloadItemKey.decode(row.itemKey) case TrackItemKey(
          :final playbackId,
        ))
          playbackId: row,
    };
    final toDelete = <PlaybackId>[];
    final known = <String>{};
    var revoked = 0;
    var confirmed = 0;
    for (final item in server) {
      final id = item.playbackId.value;
      known.add(id);
      final row = local[id];
      if (item.revoked) {
        if (row != null) {
          await _revoke(TrackItemKey(id));
          revoked++;
        }
        toDelete.add(item.playbackId);
      } else if (row == null) {
        toDelete.add(item.playbackId);
      } else if (row.status == DownloadStatus.completed &&
          !row.serverConfirmed) {
        await _store.markServerConfirmed(TrackItemKey(id), _clock.now());
        confirmed++;
      }
    }
    var resent = 0;
    for (final MapEntry(key: id, value: row) in local.entries) {
      if (row.status != DownloadStatus.completed || known.contains(id)) {
        continue;
      }
      await _controller.resendComplete(TrackItemKey(id));
      resent++;
    }
    for (var start = 0; start < toDelete.length;) {
      final end = (start + maxOfflineDeleteBatch).clamp(0, toDelete.length);
      await _deleteQueue.enqueue(
        deviceId: _deviceId,
        playbackIds: toDelete.sublist(start, end),
      );
      start = end;
    }
    await _settings.write(
      downloadsLastReconciledAtKey,
      _clock.now().toUtc().toIso8601String(),
    );
    final report = ReconcileReport(
      revoked: revoked,
      resent: resent,
      confirmed: confirmed,
      deletedOnServer: toDelete.length,
    );
    _log.info('Reconciled downloads with the server', {'report': '$report'});
    return report;
  }

  /// Rule 5: checks every completed item's file, adopts files renamed just
  /// before a crash, deletes files under `media/` that belong to no item
  /// (keeping the `.part` file of a live transfer), removes unreferenced
  /// covers and empty fan-out directories. Needs no server.
  Future<ScanReport> runLocalScan() async {
    final rows = await _store.items();
    final now = _clock.now();
    final byHash = <String, DownloadItem>{
      for (final row in rows)
        itemKeyHash(DownloadItemKey.decode(row.itemKey)): row,
    };
    final keep = <String>{};
    var missing = 0;
    for (final row in rows) {
      if (row.status != DownloadStatus.completed) continue;
      final key = DownloadItemKey.decode(row.itemKey);
      final relative = row.relativePath;
      final size = relative == null
          ? null
          : await _mediaFiles.length(_paths.resolve(relative));
      if (relative != null && size != null && size == row.sizeBytes) {
        keep.add(p.normalize(_paths.resolve(relative)));
        continue;
      }
      _log.info('A downloaded file is missing', {'item': itemKeyHash(key)});
      await _store.markFileMissing(key, now);
      missing++;
    }

    final live = await _downloader.liveTaskIds(group: _group);
    var orphans = 0;
    var adopted = 0;
    final media = _paths.profile.media;
    for (final file in await _mediaFiles.listFiles(media)) {
      final path = p.normalize(file);
      if (keep.contains(path)) continue;
      final name = p.basename(path);
      final dot = name.indexOf('.');
      final hash = dot < 0 ? name : name.substring(0, dot);
      final extension = dot < 0 ? '' : name.substring(dot + 1);
      final row = byHash[hash];
      if (row != null && extension == 'part') {
        final taskId = row.taskId;
        if (_inTransfer(row.status) &&
            taskId != null &&
            live.contains(taskId)) {
          continue;
        }
      } else if (row != null &&
          (row.status == DownloadStatus.verifying ||
              row.status == DownloadStatus.running)) {
        if (await _adopt(row, path)) {
          adopted++;
          continue;
        }
      }
      await _delete(path);
      orphans++;
    }
    await _mediaFiles.removeEmptyDirectories(media);
    final artworkRemoved = await _artwork.removeUnreferenced();
    if (missing > 0) _scheduler.pump();
    final report = ScanReport(
      missing: missing,
      orphansDeleted: orphans,
      adopted: adopted,
      artworkRemoved: artworkRemoved,
    );
    _log.info('Scanned downloaded files', {'report': '$report'});
    return report;
  }

  /// Completes [row] with the final file at [path] when its size is the
  /// expected one (any non-empty size when none is known) and answers
  /// true; otherwise answers false and the file is the caller's to
  /// delete.
  Future<bool> _adopt(DownloadItem row, String path) async {
    final key = DownloadItemKey.decode(row.itemKey);
    final size = await _mediaFiles.length(path);
    final expected = row.expectedBytes;
    if (size == null || size == 0 || (expected != null && size != expected)) {
      // The caller deletes the file; a verifying row fails verification
      // and retries, a running one is the scheduler's.
      if (row.status == DownloadStatus.verifying) {
        await _scheduler.deliver(key, const VerificationFailed());
      }
      return false;
    }
    if (row.status == DownloadStatus.running) {
      // The transfer's completion is in the past; its VerifyFile effect
      // has nothing left to check.
      final state = DownloadStore.stateOf(row);
      await _store.applyTransition(
        key,
        reduce(state, const TransferCompleted(), now: _clock.now()),
      );
    }
    final relative = p.relative(path, from: _paths.profile.supportRoot);
    await _scheduler.deliver(key, VerificationPassed(size, relative));
    _log.info('Adopted a renamed download', {'item': itemKeyHash(key)});
    return true;
  }

  Future<void> _revoke(DownloadItemKey key) async {
    // The transfer stops for good first; the state machine then deletes
    // the files and the row with its memberships.
    await _scheduler.cancelItem(key);
    await _scheduler.deliver(key, const Revoked());
  }

  Future<void> _delete(String path) async {
    try {
      await _mediaFiles.delete(path);
    } on Object catch (error, stackTrace) {
      _log.warning(
        'Could not delete an orphaned download file',
        const {},
        error,
        stackTrace,
      );
    }
  }

  static bool _inTransfer(DownloadStatus status) =>
      status == DownloadStatus.queued ||
      status == DownloadStatus.running ||
      status == DownloadStatus.paused ||
      status == DownloadStatus.verifying;

  Future<void> _guarded({bool force = false}) async {
    try {
      await runIfDue(force: force);
    } on Object catch (error, stackTrace) {
      _log.warning(
        'Could not reconcile downloads',
        const {},
        error,
        stackTrace,
      );
    }
  }

  /// Arms the timer for when the next pass is due: the interval after the
  /// last successful one, or a full interval from now when that is past.
  Future<void> _arm() async {
    if (_disposed || !_started) return;
    final last = await lastReconciledAt();
    var delay = last == null
        ? kReconcileInterval
        : last.add(kReconcileInterval).difference(_clock.now());
    if (delay <= Duration.zero) delay = kReconcileInterval;
    _timer?.cancel();
    if (_disposed) return;
    _timer = _createTimer(delay, () {
      _timer = null;
      unawaited(_guarded());
    });
  }

  /// Completes when the pass running now, if any, has finished.
  @visibleForTesting
  Future<void> settle() async {
    try {
      await _pass;
    } on Object {
      // The pass's own caller sees its error.
    }
  }

  /// Stops the timer and the reachability trigger. A pass already running
  /// still finishes.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    await _subscription?.cancel();
    _subscription = null;
    await settle();
  }
}

/// The [DownloadReconciler] of the profile scope, disposed when the scope
/// ends. Native targets only, like the [DownloadScheduler] it works with.
final Provider<DownloadReconciler> downloadReconcilerProvider =
    Provider<DownloadReconciler>(
      (ref) {
        final context = ref.watch(profileContextProvider);
        final profilePaths =
            context.paths ??
            (throw StateError('downloads need a profile directory'));
        final reconciler = DownloadReconciler(
          store: ref.watch(downloadStoreProvider),
          offline: ref.watch(offlineRepositoryProvider),
          scheduler: ref.watch(downloadSchedulerProvider),
          controller: ref.watch(downloadControllerProvider),
          deleteQueue: ref.watch(offlineDeleteQueueProvider),
          downloader: ref.watch(downloaderProvider),
          reachability: ref.watch(reachabilityProvider),
          settings: ref.watch(deviceSettingsDaoProvider),
          mediaFiles: ref.watch(mediaFilesProvider),
          artwork: ref.watch(downloadArtworkProvider),
          clock: ref.watch(clockProvider),
          deviceId: context.profile.deviceId,
          profileId: context.profile.id,
          paths: DownloadPaths(profilePaths),
        );
        ref.watch(profileDisposerProvider).register(reconciler.dispose);
        return reconciler;
      },
      dependencies: [
        profileContextProvider,
        downloadStoreProvider,
        offlineRepositoryProvider,
        downloadSchedulerProvider,
        downloadControllerProvider,
        offlineDeleteQueueProvider,
        deviceSettingsDaoProvider,
        downloadArtworkProvider,
        profileDisposerProvider,
      ],
    );
