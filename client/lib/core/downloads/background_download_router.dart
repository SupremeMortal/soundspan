// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Records the transfers of profiles that are not active (doc 04, Multiple
/// Profiles; doc 07, Transfers).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_scheduler.dart';
import 'package:soundspan/core/downloads/download_state_machine.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/storage/providers.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/platform/database_opener/database_opener.dart';
import 'package:soundspan/platform/downloader/downloader.dart';
import 'package:soundspan/shared/clock.dart';

/// How long the router collects events of one profile before it opens that
/// profile's database to apply them together.
const Duration kBackgroundEventWindow = Duration(milliseconds: 250);

/// The root-scope handler of downloader events (doc 02, Background Entry
/// Points).
///
/// Every event carries its group `p:<profileId>`. Events of the profile
/// whose [DownloadScheduler] is listening ([activeProfileId]) are left to
/// that scheduler. For any other profile that still exists, completions,
/// failures and pauses are applied through the pure state machine and the
/// [DownloadStore] of its `state.db`, which is opened for one batch of
/// events and closed again; a completion leaves the item `verifying`, and
/// that profile's scheduler verifies it when it next starts. Progress and
/// response events of such a profile are dropped. An event of a profile
/// that no longer exists cancels its task and deletes its `.part` file.
class BackgroundDownloadRouter {
  /// Creates the router; `profileExists` asks `app.db` whether a profile
  /// is still known.
  new({
    required this._downloader,
    required this._opener,
    required this._clock,
    required this._profileExists,
    this._window = kBackgroundEventWindow,
  });

  static final AppLogger _log = AppLogger.scope('Downloads');

  final Downloader _downloader;
  final DatabaseOpener _opener;
  final Clock _clock;
  final Future<bool> Function(String profileId) _profileExists;
  final Duration _window;

  final Map<String, List<DownloaderEvent>> _pending = {};
  final Map<String, Timer> _timers = {};
  final Map<String, Future<void>> _tails = {};
  final Set<String> _cancelled = {};
  StreamSubscription<DownloaderEvent>? _subscription;
  Future<void>? _starting;
  bool _disposed = false;

  /// The profile whose [DownloadScheduler] handles its own events, or null;
  /// `startDownloads` sets it before that scheduler starts.
  String? activeProfileId;

  /// Listens to the downloader, then starts it, so the events it delivers
  /// for transfers that ran while the app was dead are routed too. Later
  /// calls share the first.
  Future<void> start() => _starting ??= () async {
    _subscription = _downloader.events.listen(_onEvent);
    await _downloader.start();
  }();

  /// Completes when every event received so far has been applied.
  Future<void> flush() async {
    for (final profileId in _timers.keys.toList()) {
      _timers.remove(profileId)?.cancel();
      _schedule(profileId);
    }
    await Future.wait(_tails.values.toList());
  }

  /// Stops listening; events already collected are applied first.
  Future<void> dispose() async {
    if (_disposed) return;
    await _subscription?.cancel();
    await flush();
    _disposed = true;
  }

  void _onEvent(DownloaderEvent event) {
    if (_disposed) return;
    final profileId = profileIdOfGroup(event.group);
    if (profileId == null || profileId == activeProfileId) return;
    if (event is DownloaderProgress || event is DownloaderResponseInfo) return;
    (_pending[profileId] ??= []).add(event);
    _timers[profileId] ??= Timer(_window, () {
      _timers.remove(profileId);
      _schedule(profileId);
    });
  }

  /// Applies the pending events of [profileId] after any earlier batch of
  /// the same profile.
  void _schedule(String profileId) {
    final previous = _tails[profileId] ?? Future<void>.value();
    final next = previous.then((_) => _applyPending(profileId));
    _tails[profileId] = next;
    unawaited(
      next.whenComplete(
        () => _tails.removeWhere(
          (key, tail) => key == profileId && identical(tail, next),
        ),
      ),
    );
  }

  Future<void> _applyPending(String profileId) async {
    final events = _pending.remove(profileId);
    if (events == null || events.isEmpty) return;
    try {
      if (!await _profileExists(profileId)) {
        for (final event in events) {
          if (!_cancelled.add(event.taskId)) continue;
          await _downloader.cancel(event.taskId, deletePartial: true);
        }
        return;
      }
      final database = StateDatabase(
        _opener.open(StateDatabaseTarget(profileId)),
      );
      try {
        final store = DownloadStore(database);
        for (final event in events) {
          await _apply(store, event);
        }
      } finally {
        await database.close();
      }
    } on Object catch (error, stackTrace) {
      _log.warning(
        'A download of an inactive profile was not recorded',
        {'profileId': profileId},
        error,
        stackTrace,
      );
    }
  }

  Future<void> _apply(DownloadStore store, DownloaderEvent event) async {
    final downloadEvent = switch (event) {
      DownloaderCompleted() => const TransferCompleted(),
      DownloaderPaused() => const PauseRequested(DownloadWaitReason.user),
      DownloaderFailed(:final kind, :final httpStatus) => switch (kind) {
        DownloaderFailureKind.noSpace => const PauseRequested(
          DownloadWaitReason.space,
        ),
        DownloaderFailureKind.cancelled => const TaskLost(),
        DownloaderFailureKind.http => TransferFailed(
          TransferFailureKind.http,
          httpStatus: httpStatus,
        ),
        DownloaderFailureKind.network ||
        DownloaderFailureKind.fileSystem ||
        DownloaderFailureKind.unknown => const TransferFailed(
          TransferFailureKind.network,
        ),
      },
      DownloaderProgress() || DownloaderResponseInfo() => null,
    };
    if (downloadEvent == null) return;
    final row = await store.itemByTaskId(event.taskId);
    if (row == null) return;
    final state = DownloadStore.stateOf(row);
    final transition = reduce(state, downloadEvent, now: _clock.now());
    if (transition.next == state && transition.effects.isEmpty) return;
    // Effects wait for the profile's scheduler: it verifies `verifying`
    // rows and re-arms retries from `nextAttemptAt` when it starts.
    await store.applyTransition(
      DownloadItemKey.decode(row.itemKey),
      transition,
    );
  }
}

/// The profile id of downloader group [group] (`p:<profileId>`), or null
/// for any other group.
String? profileIdOfGroup(String group) {
  const prefix = 'p:';
  if (group.length <= prefix.length || !group.startsWith(prefix)) return null;
  return group.substring(prefix.length);
}

/// The root-scope [BackgroundDownloadRouter], disposed with the root.
final Provider<BackgroundDownloadRouter> backgroundDownloadRouterProvider =
    Provider<BackgroundDownloadRouter>((ref) {
      final repository = ref.watch(profileRepositoryProvider);
      final router = BackgroundDownloadRouter(
        downloader: ref.watch(downloaderProvider),
        opener: ref.watch(databaseOpenerProvider),
        clock: ref.watch(clockProvider),
        profileExists: (id) async => await repository.byId(id) != null,
      );
      ref.onDispose(() => unawaited(router.dispose()));
      return router;
    });
