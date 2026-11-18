// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/app/session/sign_out_participant.dart';
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_scheduler.dart';
import 'package:soundspan/core/downloads/download_state_machine.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/downloads/offline_delete_queue.dart';
import 'package:soundspan/core/downloads/offline_repository.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/platform/downloader/downloader.dart';
import 'package:soundspan/platform/media_files/media_files.dart';
import 'package:soundspan/platform/paths/paths.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/data/downloads/download_outbox.dart';
import 'package:soundspan/shared/domain/playback_id.dart';

final AppLogger _log = AppLogger.scope('SignOut');

/// Creates a one-shot timer that runs `callback` after `duration`.
typedef BudgetTimer = Timer Function(
  Duration duration,
  void Function() callback,
);

/// Downloads' part in sign-out and server removal (doc 04, Sign-Out steps
/// 2 and 6; doc 07, Removing Downloads).
///
/// Signing out stops the scheduler and cancels the profile's transfers, so
/// running items wait as `queued` for the next sign-in; completed files
/// stay unless the user asked to remove them. Removing the server also
/// queues `DELETE /offline/items` for every track the server may know
/// about, for the outbox pass that follows, and deletes the profile's
/// `media/` and `art/` directories.
///
/// Every step is best-effort: a failure is logged by its type only and the
/// next step runs, and neither method throws. Cancelling the transfers may
/// take [cancelBudget] and deleting the files [deleteBudget]; a step that
/// takes longer is abandoned.
final class DownloadsSignOutParticipant
    implements SignOutParticipant, ReportsDownloads {
  /// Creates the participant of the profile whose files live under
  /// `paths` and whose server device id is `deviceId`; `timer` (default
  /// [Timer.new]) ends a step after its budget.
  new({
    required this._store,
    required this._scheduler,
    required this._controller,
    required this._downloader,
    required this._deleteQueue,
    required this._mediaFiles,
    required this._paths,
    required this._deviceId,
    required this._clock,
    this._timer = Timer.new,
  });

  /// How long cancelling the transfers may take.
  static const Duration cancelBudget = Duration(seconds: 5);

  /// How long deleting the profile's media and artwork may take.
  static const Duration deleteBudget = Duration(seconds: 10);

  final DownloadStore _store;
  final DownloadScheduler _scheduler;
  final DownloadController _controller;
  final Downloader _downloader;
  final OfflineDeleteQueue _deleteQueue;
  final MediaFiles _mediaFiles;
  final ProfilePaths _paths;
  final String _deviceId;
  final Clock _clock;
  final BudgetTimer _timer;

  bool _stopped = false;

  /// The completed downloads and their size; null when they cannot be read.
  @override
  Future<DownloadsSummary?> downloadsSummary() async {
    try {
      final rows = await _store.itemsByStatus(DownloadStatus.completed);
      var bytes = 0;
      for (final row in rows) {
        bytes += row.sizeBytes ?? 0;
      }
      return DownloadsSummary(itemCount: rows.length, bytes: bytes);
    } on Object catch (error) {
      _log.warning('Downloads not counted', {
        'error': error.runtimeType.toString(),
      });
      return null;
    }
  }

  @override
  Future<void> onSignOut({required bool removeDownloads}) async {
    await _stopTransfers();
    if (removeDownloads) {
      await _guard('Removing downloads failed', _controller.removeAll);
    }
  }

  @override
  Future<void> beforeRemove() async {
    await _stopTransfers();
    await _guard('Queueing offline deletes failed', _reportAllRemoved);
    await _withBudget('Deleting downloaded files', deleteBudget, () async {
      for (final directory in [_paths.media, _paths.art]) {
        await _guard(
          'Deleting downloaded files failed',
          () => _mediaFiles.deleteTree(directory),
        );
      }
    });
  }

  /// Steps 1 and 2 of the participant, once: nothing starts any more, the
  /// profile's transfers are cancelled with their `.part` files, and
  /// running items go back to `queued`.
  Future<void> _stopTransfers() async {
    if (_stopped) return;
    _stopped = true;
    await _withBudget('Cancelling downloads', cancelBudget, () async {
      await _guard('Stopping the scheduler failed', _scheduler.dispose);
      await _guard(
        'Cancelling downloads failed',
        () => _cancelTasks(_downloader, _paths.profileId),
      );
    });
    await _guard('Requeueing downloads failed', () async {
      for (final row in await _store.itemsByStatus(DownloadStatus.running)) {
        final key = DownloadItemKey.decode(row.itemKey);
        final transition = reduce(
          DownloadStore.stateOf(row),
          const TaskLost(),
          now: _clock.now(),
        );
        await _store.applyTransition(key, transition);
      }
    });
  }

  /// Queues `offlineDelete` for every track of this device the server may
  /// know about: confirmed ones and completed ones not yet confirmed.
  Future<void> _reportAllRemoved() async {
    final ids = <PlaybackId>[
      for (final row in await _store.allItems())
        if (row.serverConfirmed || row.status == DownloadStatus.completed)
          if (DownloadItemKey.decode(row.itemKey) case TrackItemKey(
            :final playbackId,
          ))
            PlaybackId(playbackId),
    ];
    for (var start = 0; start < ids.length; start += maxOfflineDeleteBatch) {
      final end = start + maxOfflineDeleteBatch < ids.length
          ? start + maxOfflineDeleteBatch
          : ids.length;
      await _deleteQueue.enqueue(
        deviceId: _deviceId,
        playbackIds: ids.sublist(start, end),
      );
    }
  }

  Future<void> _withBudget(
    String what,
    Duration budget,
    Future<void> Function() action,
  ) => _runWithBudget(_timer, what, budget, action);
}

/// Cancels every transfer of profile [profileId] that [downloader] still
/// holds, deleting its `.part` file; one that cannot be cancelled is
/// logged and the others still are.
Future<void> _cancelTasks(Downloader downloader, String profileId) async {
  final live = await downloader.liveTaskIds(group: downloaderGroup(profileId));
  for (final taskId in live) {
    await _guard(
      'Cancelling a download failed',
      () => downloader.cancel(taskId, deletePartial: true),
    );
  }
}

/// Cancels the transfers of an inactive profile [profileId] through the
/// root [downloader], without opening its database (doc 04, Sign-Out). Its
/// rows stay `running` until the profile is active again, when the
/// scheduler finds no live task and queues them. Takes at most
/// [DownloadsSignOutParticipant.cancelBudget]; never throws.
Future<void> cancelDownloadTasks(
  Downloader downloader,
  String profileId, {
  BudgetTimer timer = Timer.new,
}) => _runWithBudget(
  timer,
  'Cancelling downloads',
  DownloadsSignOutParticipant.cancelBudget,
  () => _guard(
    'Cancelling downloads failed',
    () => _cancelTasks(downloader, profileId),
  ),
);

Future<void> _guard(String message, Future<void> Function() action) async {
  try {
    await action();
  } on Object catch (error) {
    _log.warning(message, {'error': error.runtimeType.toString()});
  }
}

/// Waits for [action] for at most [budget]; a timeout is logged and the
/// action is left to finish on its own.
Future<void> _runWithBudget(
  BudgetTimer createTimer,
  String what,
  Duration budget,
  Future<void> Function() action,
) async {
  final expired = Completer<bool>();
  final timer = createTimer(budget, () {
    if (!expired.isCompleted) expired.complete(false);
  });
  try {
    final finished = await Future.any([
      _guard('$what failed', action).then((_) => true),
      expired.future,
    ]);
    if (!finished) _log.warning('$what timed out');
  } finally {
    timer.cancel();
  }
}

/// The [DownloadsSignOutParticipant] of the profile scope. Native targets
/// only, like the [DownloadController] it uses.
final Provider<DownloadsSignOutParticipant>
downloadsSignOutParticipantProvider = Provider<DownloadsSignOutParticipant>(
  (ref) {
    final context = ref.watch(profileContextProvider);
    return DownloadsSignOutParticipant(
      store: ref.watch(downloadStoreProvider),
      scheduler: ref.watch(downloadSchedulerProvider),
      controller: ref.watch(downloadControllerProvider),
      downloader: ref.watch(downloaderProvider),
      deleteQueue: ref.watch(offlineDeleteQueueProvider),
      mediaFiles: ref.watch(mediaFilesProvider),
      paths:
          context.paths ??
          (throw StateError('downloads need a profile directory')),
      deviceId: context.profile.deviceId,
      clock: ref.watch(clockProvider),
    );
  },
  dependencies: [
    profileContextProvider,
    downloadStoreProvider,
    downloadSchedulerProvider,
    downloadControllerProvider,
    offlineDeleteQueueProvider,
  ],
);
