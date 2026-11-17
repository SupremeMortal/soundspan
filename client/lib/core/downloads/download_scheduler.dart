// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Decides which queued download runs and when (doc 07, Transfers).
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show immutable, visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/download_artwork.dart';
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_reconciler.dart';
import 'package:soundspan/core/downloads/download_request_builder.dart';
import 'package:soundspan/core/downloads/download_state_machine.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/profile/api_provider.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/core/profile/profile_disposer.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/storage/state/device_settings_dao.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';
import 'package:soundspan/platform/disk_space/disk_space.dart';
import 'package:soundspan/platform/downloader/downloader.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// The `device_settings` key of Wi-Fi-only downloads: JSON `true` when
/// downloads may only run on Wi-Fi or Ethernet.
const String downloadsWifiOnlyKey = 'downloads.wifiOnly';

/// Whether downloads run on Wi-Fi only, given the stored value of
/// [downloadsWifiOnlyKey]. While the key is unset it is on where the device
/// can be on mobile data ([mobileData]: Android and iOS) and off elsewhere.
bool wifiOnlyFromStored(Object? stored, {required bool mobileData}) =>
    stored is bool ? stored : mobileData;

/// The most transfers of one profile that run at once.
const int kMaxRunningDownloads = 2;

/// The free disk space kept back from downloads: 500 MB.
const int kDiskReserveBytes = 500 * 1024 * 1024;

/// Creates the timer of a retry; [Timer.new] outside tests.
typedef RetryTimerFactory = Timer Function(
  Duration delay,
  void Function() callback,
);

/// A state-machine effect on item [key] that the scheduler does not run
/// itself: the controller renames, confirms, deletes and re-resolves.
@immutable
final class DownloadItemEffect {
  /// Creates the effect.
  const new(this.key, this.effect);

  /// The item it applies to.
  final DownloadItemKey key;

  /// What to do.
  final DownloadEffect effect;

  @override
  bool operator ==(Object other) =>
      other is DownloadItemEffect &&
      other.key == key &&
      other.effect.runtimeType == effect.runtimeType &&
      other.effect == effect;

  @override
  int get hashCode => Object.hash(key, effect.runtimeType, effect);

  @override
  String toString() => 'DownloadItemEffect($key, $effect)';
}

/// Hands one profile's queued items to the [Downloader], at most
/// [kMaxRunningDownloads] at a time, in the documented order, under the
/// reachability, Wi-Fi-only and free-space constraints (doc 07, Transfers;
/// Storage Accounting and Quota).
///
/// It turns downloader events into state-machine events and persists
/// them, runs the enqueue, pause, retry-timer and credential-refresh
/// effects, and emits every other effect on [effects]. All of its work runs
/// one step at a time, so a slot is never granted twice.
///
/// The free-space waits it sets itself are remembered in memory; any other
/// `waitingFor: space` marker belongs to the device limit and is skipped
/// until it is cleared.
class DownloadScheduler {
  /// Creates the scheduler of profile [profileId], whose files live under
  /// `mediaDirectory`.
  ///
  /// `refreshCredentials` renews the session after a 401
  /// (`SessionController.refreshNow`); the retry is then built with the
  /// new headers.
  new({
    required this._store,
    required this._downloader,
    required this._requestBuilder,
    required this._reachability,
    required this._settings,
    required this._diskSpace,
    required this._clock,
    required String profileId,
    required this._mediaDirectory,
    required this._refreshCredentials,
    this._createTimer = Timer.new,
    this._mobileData = false,
  }) : _group = downloaderGroup(profileId);

  static final AppLogger _log = AppLogger.scope('Downloads');

  final DownloadStore _store;
  final Downloader _downloader;
  final DownloadRequestBuilder _requestBuilder;
  final ReachabilityController _reachability;
  final DeviceSettingsDao _settings;
  final DiskSpace _diskSpace;
  final Clock _clock;
  final String _group;
  final String _mediaDirectory;
  final Future<void> Function() _refreshCredentials;
  final RetryTimerFactory _createTimer;

  /// Whether the device can be on mobile data: the Wi-Fi-only default.
  final bool _mobileData;

  final StreamController<DownloadItemEffect> _effects =
      StreamController<DownloadItemEffect>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final Map<DownloadItemKey, Timer> _retryTimers = {};
  final Map<DownloadItemKey, DateTime> _progressWrittenAt = {};
  final Map<String, DownloadRequest> _pendingRequests = {};
  final Set<DownloadItemKey> _diskWaits = {};
  final Map<DownloadItemKey, String?> _contentTypes = {};
  final Set<DownloadItemKey> _cancelled = {};

  Future<void> _tail = Future<void>.value();
  bool _pumpQueued = false;
  bool _wifiOnly = false;
  bool _started = false;
  bool _available = true;
  bool _disposed = false;

  /// The effects the controller runs: `VerifyFile` (with the response's
  /// `Content-Type` when this scheduler saw it), `RenamePartToFinal`,
  /// `SendComplete`, `DeleteFile`, `DeleteRow` and `ReResolveCollection`.
  Stream<DownloadItemEffect> get effects => _effects.stream;

  /// Whether downloads can run on this device: false once the downloader
  /// failed to initialise, such as on a Linux desktop without an XDG
  /// documents directory. Nothing is enqueued while false.
  bool get isAvailable => _available;

  /// Re-attaches to the operating system's tasks, reconciles `running`
  /// rows with them, hands every `verifying` row to the controller with a
  /// `VerifyFile` effect, re-arms the retries of `failedRetryable` rows,
  /// and pumps. Events the downloader delivers while starting are processed
  /// like live ones. When the downloader cannot initialise, that is logged
  /// once and [isAvailable] turns false instead of an error. Later calls
  /// do nothing.
  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    _wifiOnly = wifiOnlyFromStored(
      await _settings.read(downloadsWifiOnlyKey),
      mobileData: _mobileData,
    );
    try {
      _subscriptions.add(
        _downloader.events
            .where((event) => event.group == _group)
            .listen((event) => _serial(() => _onEvent(event))),
      );
      await _downloader.start();
    } on Object catch (error, stackTrace) {
      _available = false;
      _log.warning(
        'The downloader cannot initialise; downloads are unavailable',
        const {},
        error,
        stackTrace,
      );
      return;
    }
    _subscriptions
      ..add(
        _reachability.changes.listen((state) {
          if (state == Reachability.online) pump();
        }),
      )
      ..add(_reachability.connectionTypeChanges.listen((_) => pump()))
      ..add(
        _settings.watch(downloadsWifiOnlyKey).listen((value) {
          final wifiOnly = wifiOnlyFromStored(value, mobileData: _mobileData);
          if (wifiOnly == _wifiOnly) return;
          _wifiOnly = wifiOnly;
          pump();
        }),
      );
    await _serial(_reattach);
    pump();
  }

  /// Fills free slots with queued items. Idempotent: calls made while a
  /// pump is waiting to run share it.
  void pump() {
    if (_disposed || !_started || !_available || _pumpQueued) return;
    _pumpQueued = true;
    unawaited(
      _serial(() async {
        _pumpQueued = false;
        await _pump();
      }),
    );
  }

  /// Pauses every running item and holds every queued one, for the user.
  Future<void> pauseAll() => _serial(() async {
    for (final row in await _store.itemsByStatus(DownloadStatus.running)) {
      await _apply(_keyOf(row), const PauseRequested(DownloadWaitReason.user));
    }
    for (final row in await _store.itemsByStatus(DownloadStatus.queued)) {
      await _hold(row);
    }
  });

  /// Resumes every item the user paused or held, then pumps.
  Future<void> resumeAll() async {
    await _serial(() async {
      for (final row in await _store.itemsByStatus(DownloadStatus.paused)) {
        if (DownloadStore.waitReasonOf(row) == DownloadWaitReason.user) {
          await _resume(row);
        }
      }
      for (final row in await _store.itemsByStatus(DownloadStatus.queued)) {
        if (DownloadStore.waitReasonOf(row) == DownloadWaitReason.user) {
          await _store.setWaitingFor(_keyOf(row), null);
        }
      }
    });
    pump();
  }

  /// Pauses item [key] for the user: a running transfer stops and a queued
  /// item is held until [resumeItem].
  Future<void> pauseItem(DownloadItemKey key) async {
    await _serial(() async {
      final row = await _store.item(key);
      if (row == null) return;
      if (row.status == DownloadStatus.running) {
        await _apply(key, const PauseRequested(DownloadWaitReason.user));
      } else if (row.status == DownloadStatus.queued) {
        await _hold(row);
      }
    });
    pump();
  }

  /// Resumes item [key]. A task the downloader cannot resume has its
  /// `.part` file deleted and runs again from byte zero.
  Future<void> resumeItem(DownloadItemKey key) async {
    await _serial(() async {
      final row = await _store.item(key);
      if (row == null) return;
      if (row.status == DownloadStatus.paused) {
        await _resume(row);
      } else if (row.status == DownloadStatus.queued &&
          DownloadStore.waitReasonOf(row) == DownloadWaitReason.user) {
        await _store.setWaitingFor(key, null);
      }
    });
    pump();
  }

  /// Stops item [key] for good, as unpinning does: its transfer is
  /// cancelled with its `.part` file and it is never started again by this
  /// scheduler. Removing the row is the caller's work.
  Future<void> cancelItem(DownloadItemKey key) async {
    await _serial(() async {
      _cancelled.add(key);
      _retryTimers.remove(key)?.cancel();
      _diskWaits.remove(key);
      final row = await _store.item(key);
      if (row == null) return;
      await _apply(
        key,
        const PauseRequested(DownloadWaitReason.user),
        runEffects: false,
      );
      final taskId = row.taskId;
      if (taskId != null) {
        await _downloader.cancel(taskId, deletePartial: true);
      }
    });
    pump();
  }

  /// Applies [event] to item [key] in turn with this scheduler's own steps,
  /// runs the effects it owns (such as the retry of a failed verification)
  /// and emits the others on [effects].
  Future<void> deliver(DownloadItemKey key, DownloadEvent event) =>
      _serial(() => _apply(key, event));

  /// Applies the device limit (doc 07, Storage Accounting and Quota): each
  /// queued item of [waiting] waits with `waitingFor: space` until a later
  /// call lists it in [fitting], which clears that marker. Items the user
  /// holds keep their marker. Then pumps; free disk space is still checked
  /// by the pump.
  Future<void> applyDeviceLimit({
    required Iterable<DownloadItemKey> fitting,
    required Iterable<DownloadItemKey> waiting,
  }) async {
    await _serial(() async {
      for (final key in waiting) {
        final row = await _store.item(key);
        if (row == null || row.status != DownloadStatus.queued) continue;
        final reason = DownloadStore.waitReasonOf(row);
        if (reason == DownloadWaitReason.user) continue;
        _diskWaits.remove(key);
        if (reason != DownloadWaitReason.space) {
          await _store.setWaitingFor(key, DownloadWaitReason.space);
        }
      }
      for (final key in fitting) {
        final row = await _store.item(key);
        if (row == null || row.status != DownloadStatus.queued) continue;
        if (DownloadStore.waitReasonOf(row) != DownloadWaitReason.space) {
          continue;
        }
        _diskWaits.remove(key);
        await _store.setWaitingFor(key, null);
      }
    });
    pump();
  }

  /// Completes when every step queued so far, and every step those queue
  /// in turn, has run.
  @visibleForTesting
  Future<void> settle() async {
    Future<void> tail;
    do {
      tail = _tail;
      await tail;
      // Let downloader and timer callbacks queue their steps.
      await Future<void>.delayed(Duration.zero);
    } while (!identical(tail, _tail));
  }

  /// Stops listening, cancels the retry timers and closes [effects].
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final timer in _retryTimers.values) {
      timer.cancel();
    }
    _retryTimers.clear();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    await _tail;
    await _effects.close();
  }

  Future<void> _serial(Future<void> Function() step) {
    final next = _tail.then((_) async {
      if (_disposed) return;
      try {
        await step();
      } on Object catch (error, stackTrace) {
        _log.severe('A download step failed', const {}, error, stackTrace);
      }
    });
    _tail = next;
    return next;
  }

  Future<void> _reattach() async {
    final live = await _downloader.liveTaskIds(group: _group);
    for (final row in await _store.itemsByStatus(DownloadStatus.running)) {
      final taskId = row.taskId;
      if (taskId == null || !live.contains(taskId)) {
        await _apply(_keyOf(row), const TaskLost());
      }
    }
    // A transfer that finished before the app was killed, and was never
    // checked: verify it now. The response's Content-Type is gone, so the
    // final file gets the `bin` extension.
    for (final row in await _store.itemsByStatus(DownloadStatus.verifying)) {
      _effects.add(DownloadItemEffect(_keyOf(row), const VerifyFile()));
    }
    final now = _clock.now();
    for (final row in await _store.itemsByStatus(
      DownloadStatus.failedRetryable,
    )) {
      _armRetry(_keyOf(row), row.nextAttemptAt ?? now);
    }
  }

  Future<void> _pump() async {
    if (!_reachability.isOnline) return;
    final running = await _store.itemsByStatus(DownloadStatus.running);
    if (!_connectionAllowed) {
      for (final row in running) {
        await _apply(
          _keyOf(row),
          const PauseRequested(DownloadWaitReason.wifi),
        );
      }
      return;
    }
    final free = await _diskSpace.freeBytes(_mediaDirectory);
    var budget = free == null ? null : free - kDiskReserveBytes;
    bool fits(DownloadItem row) => budget == null || budget >= _remaining(row);

    for (final row in await _store.itemsByStatus(DownloadStatus.paused)) {
      final reason = DownloadStore.waitReasonOf(row);
      if (reason == DownloadWaitReason.wifi ||
          (reason == DownloadWaitReason.space && fits(row))) {
        await _resume(row);
      }
    }

    var slots = kMaxRunningDownloads - running.length;
    if (slots <= 0) return;
    for (final scheduled in await _store.queuedInScheduleOrder()) {
      if (slots <= 0) break;
      final row = scheduled.item;
      final key = _keyOf(row);
      if (_cancelled.contains(key)) continue;
      final reason = DownloadStore.waitReasonOf(row);
      if (reason == DownloadWaitReason.user) continue;
      if (reason == DownloadWaitReason.space && !_diskWaits.contains(key)) {
        continue;
      }
      if (!fits(row)) {
        if (reason != DownloadWaitReason.space) {
          await _store.setWaitingFor(key, DownloadWaitReason.space);
          _diskWaits.add(key);
        }
        continue;
      }
      if (!await _grant(key, row, userInitiated: scheduled.userInitiated)) {
        continue;
      }
      _diskWaits.remove(key);
      if (budget != null) budget -= _remaining(row);
      slots--;
    }
  }

  /// Builds item [row]'s request, marks it running and enqueues it.
  /// Returns false when no request could be built.
  Future<bool> _grant(
    DownloadItemKey key,
    DownloadItem row, {
    required bool userInitiated,
  }) async {
    final DownloadRequest request;
    try {
      request = await _requestBuilder.build(
        row,
        wifiOnly: _wifiOnly,
        userInitiated: userInitiated,
      );
    } on Object catch (error, stackTrace) {
      _log.warning(
        'Could not build a download request',
        {'item': itemKeyHash(key)},
        error,
        stackTrace,
      );
      return false;
    }
    _pendingRequests[request.taskId] = request;
    await _apply(key, SlotGranted(request.taskId));
    return true;
  }

  bool get _connectionAllowed =>
      !_wifiOnly ||
      switch (_reachability.connectionType) {
        ConnectionType.wifi || ConnectionType.other => true,
        ConnectionType.cellular || ConnectionType.none => false,
      };

  Future<void> _hold(DownloadItem row) async {
    final reason = DownloadStore.waitReasonOf(row);
    // A device-limit or free-space wait is kept: the item cannot run anyway.
    if (reason == DownloadWaitReason.space) return;
    await _store.setWaitingFor(_keyOf(row), DownloadWaitReason.user);
  }

  Future<void> _resume(DownloadItem row) async {
    final key = _keyOf(row);
    final taskId = row.taskId;
    final resumed = taskId != null && await _downloader.resume(taskId);
    await _apply(key, const ResumeRequested());
    if (resumed) {
      // The task carries on where it was; it already holds its slot.
      await _apply(key, SlotGranted(taskId), runEffects: false);
      return;
    }
    if (taskId != null) {
      await _downloader.cancel(taskId, deletePartial: true);
    }
  }

  Future<void> _onEvent(DownloaderEvent event) async {
    final row = await _store.itemByTaskId(event.taskId);
    if (row == null) return;
    final key = _keyOf(row);
    switch (event) {
      case DownloaderProgress(:final receivedBytes):
        final now = _clock.now();
        final last = _progressWrittenAt[key];
        if (last != null && now.difference(last) < const Duration(seconds: 1)) {
          return;
        }
        _progressWrittenAt[key] = now;
        await _store.updateProgress(key, receivedBytes);
      case DownloaderResponseInfo(
        :final etag,
        :final contentLength,
        :final contentType,
      ):
        _contentTypes[key] = contentType;
        await _store.recordResponse(
          key,
          etag: etag,
          contentLength: contentLength,
        );
      case DownloaderCompleted():
        _progressWrittenAt.remove(key);
        await _apply(key, const TransferCompleted());
        pump();
      case DownloaderPaused():
        await _apply(
          key,
          const PauseRequested(DownloadWaitReason.user),
          runEffects: false,
        );
        pump();
      case DownloaderFailed(:final kind, :final httpStatus):
        _progressWrittenAt.remove(key);
        await _apply(key, switch (kind) {
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
        }, runEffects: kind != DownloaderFailureKind.noSpace);
        pump();
    }
  }

  /// Applies [event] to item [key], persists the transition and, with
  /// [runEffects], runs or emits its effects.
  Future<void> _apply(
    DownloadItemKey key,
    DownloadEvent event, {
    bool runEffects = true,
  }) async {
    final row = await _store.item(key);
    if (row == null) return;
    final state = DownloadStore.stateOf(row);
    final transition = reduce(state, event, now: _clock.now());
    if (transition.next == state && transition.effects.isEmpty) return;
    final effects = await _store.applyTransition(key, transition);
    if (!runEffects) return;
    for (final effect in effects) {
      await _run(key, transition.next, effect);
    }
  }

  Future<void> _run(
    DownloadItemKey key,
    DownloadItemState state,
    DownloadEffect effect,
  ) async {
    switch (effect) {
      case EnqueueTask(:final taskId):
        final request = _pendingRequests.remove(taskId);
        if (request == null) return;
        try {
          await _downloader.enqueue(request);
        } on Object catch (error, stackTrace) {
          _log.warning(
            'The downloader refused a task',
            {'task': taskId},
            error,
            stackTrace,
          );
          await _apply(key, const TransferFailed(TransferFailureKind.network));
        }
      case PauseOrCancelKeepingPart():
        final taskId = state.taskId;
        if (taskId != null) await _downloader.pause(taskId);
      case ScheduleRetry(:final at):
        _armRetry(key, at);
      case RefreshCredentials():
        try {
          await _refreshCredentials();
        } on Object catch (error, stackTrace) {
          _log.warning(
            'Could not refresh credentials for a download',
            const {},
            error,
            stackTrace,
          );
        }
      case VerifyFile():
        _effects.add(
          DownloadItemEffect(
            key,
            VerifyFile(contentType: _contentTypes.remove(key)),
          ),
        );
      case RenamePartToFinal() ||
          SendComplete() ||
          DeleteFile() ||
          DeleteRow() ||
          ReResolveCollection():
        _effects.add(DownloadItemEffect(key, effect));
    }
  }

  void _armRetry(DownloadItemKey key, DateTime at) {
    _retryTimers.remove(key)?.cancel();
    var delay = at.difference(_clock.now());
    if (delay.isNegative) delay = Duration.zero;
    _retryTimers[key] = _createTimer(delay, () {
      _retryTimers.remove(key);
      unawaited(_serial(() => _apply(key, const BackoffElapsed())));
      pump();
    });
  }

  static int _remaining(DownloadItem row) {
    final expected = row.expectedBytes;
    if (expected == null) return kUnknownItemBytes;
    final remaining = expected - row.receivedBytes;
    return remaining < 0 ? 0 : remaining;
  }

  static DownloadItemKey _keyOf(DownloadItem row) =>
      DownloadItemKey.decode(row.itemKey);
}

/// The root-scope [Downloader] of the platform; tests override it.
final Provider<Downloader> downloaderProvider = Provider<Downloader>(
  (ref) => createDownloader(),
);

/// The [DownloadScheduler] of the profile scope, disposed when the scope
/// ends. Native targets only: on web the profile has no download paths
/// and reading it throws.
final Provider<DownloadScheduler> downloadSchedulerProvider =
    Provider<DownloadScheduler>(
      (ref) {
        final context = ref.watch(profileContextProvider);
        final profilePaths =
            context.paths ??
            (throw StateError('downloads need a profile directory'));
        final session = ref.watch(sessionControllerProvider);
        // The API attaches the session's refresher; watch it so it exists.
        ref.watch(soundspanApiProvider);
        final scheduler = DownloadScheduler(
          store: ref.watch(downloadStoreProvider),
          downloader: ref.watch(downloaderProvider),
          requestBuilder: DownloadRequestBuilder(
            paths: DownloadPaths(profilePaths),
            urls: StreamUrls(ref.watch(apiConfigProvider).baseUrl),
            currentCredentials: () => session.current,
            ensureFresh: session.ensureFresh,
          ),
          reachability: ref.watch(reachabilityProvider),
          settings: ref.watch(deviceSettingsDaoProvider),
          diskSpace: ref.watch(diskSpaceProvider),
          clock: ref.watch(clockProvider),
          profileId: context.profile.id,
          mediaDirectory: profilePaths.media,
          refreshCredentials: session.refreshNow,
          mobileData: ref.watch(platformCapabilitiesProvider).hasMobileData,
        );
        ref.watch(profileDisposerProvider).register(scheduler.dispose);
        return scheduler;
      },
      dependencies: [
        profileContextProvider,
        sessionControllerProvider,
        soundspanApiProvider,
        downloadStoreProvider,
        apiConfigProvider,
        deviceSettingsDaoProvider,
        profileDisposerProvider,
      ],
    );

/// The post-first-frame task of downloads (doc 02, Bootstrap Sequence,
/// step 8): creates the [DownloadController] and starts the
/// [DownloadScheduler], then the [DownloadArtwork], then the
/// [DownloadReconciler], of each profile the
/// [ProfileRuntime] under [root] activates, now and later, on targets that
/// can download.
Future<void> startDownloads(ProviderContainer root) async {
  if (!root.read(platformCapabilitiesProvider).canDownload) return;
  final runtime = root.read(profileRuntimeProvider);
  final started = Expando<bool>();
  void onState() {
    final container = runtime.container;
    if (runtime.state.value is! ProfileRuntimeActive || container == null) {
      return;
    }
    if (started[container] ?? false) return;
    started[container] = true;
    // The controller retries pending collections and re-resolves refused
    // items from here on.
    container.read(downloadControllerProvider);
    unawaited(
      container
          .read(downloadSchedulerProvider)
          .start()
          .then((_) => container.read(downloadArtworkProvider).start())
          // Reconciliation scans the files at once and asks the server
          // when online (doc 07, Reconciliation).
          .then((_) => container.read(downloadReconcilerProvider).start())
          .catchError(
            (Object error, StackTrace stackTrace) => DownloadScheduler._log
                .severe('Downloads did not start', const {}, error, stackTrace),
          ),
    );
  }

  runtime.state.addListener(onState);
  onState();
}
