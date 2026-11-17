// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Keeps pinned albums and playlists current (doc 07, Keeping Collections
/// Current).
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals, visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/offline_models.dart';
import 'package:soundspan/core/downloads/pinned_playlist_listener.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/core/profile/profile_disposer.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan/shared/domain/track.dart';

export 'package:soundspan/core/downloads/download_controller.dart'
    show UpkeepResult;

/// How long a burst of changes to one playlist is collected before it is
/// resolved once.
const Duration kPlaylistUpkeepDebounce = Duration(seconds: 2);

/// How often a pinned album is resolved again at most, unless refreshed
/// by hand.
const Duration kAlbumUpkeepInterval = Duration(hours: 24);

/// Creates the debounce and daily timers; [Timer.new] outside tests.
typedef UpkeepTimerFactory = Timer Function(
  Duration delay,
  void Function() callback,
);

/// Keeps the pinned collections of one profile current.
///
/// A pinned playlist follows its track list: [onPlaylistTracksChanged],
/// called by the playlist data layer through the [PinnedPlaylistRelay],
/// resolves it again when its tracks differ from what is pinned, once per
/// burst of changes, and while offline remembers it for when reachability
/// returns to `online`. Pinned albums are resolved again at most once
/// every [kAlbumUpkeepInterval] ([runDailyAlbumPass]); [refresh] does so
/// for one collection at once, whatever its age. The difference is
/// applied by [DownloadController.refreshCollection]. Single tracks are
/// refreshed only by the scheduler's `ReResolveCollection` effect.
class CollectionUpkeep implements PinnedPlaylistListener {
  /// Creates the upkeep of the profile whose downloads [_controller] keeps.
  new({
    required this._controller,
    required this._reachability,
    required this._clock,
    this._relay,
    this._createTimer = Timer.new,
  });

  static final AppLogger _log = AppLogger.scope('Downloads');

  final DownloadController _controller;
  final ReachabilityController _reachability;
  final Clock _clock;
  final PinnedPlaylistRelay? _relay;
  final UpkeepTimerFactory _createTimer;

  final Map<String, Timer> _debounce = {};
  final Map<String, CollectionSnapshot> _latest = {};
  final Map<(CollectionKind, String), CollectionSnapshot?> _pending = {};
  final Set<Future<void>> _running = {};
  StreamSubscription<Reachability>? _subscription;
  Timer? _dailyTimer;
  Future<void>? _albumPass;
  bool _started = false;
  bool _disposed = false;

  /// Starts listening to playlist changes and to reachability, runs the
  /// album pass now (downloads start it after reconciliation) and then
  /// every [kAlbumUpkeepInterval]. Later calls do nothing.
  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    _relay?.listener = this;
    _subscription = _reachability.changes.listen((state) {
      if (state == Reachability.online) _track(_retryPending());
    });
    await _guard('run the album pass', runDailyAlbumPass);
    _armDaily();
  }

  /// Resolves collection [kind]/[refId] again and applies the difference,
  /// whatever the time of its last resolve. [snapshot] is what the caller
  /// shows of it. Offline, the collection is remembered and refreshed
  /// when reachability returns to `online`.
  Future<UpkeepResult> refresh(
    CollectionKind kind,
    String refId, {
    CollectionSnapshot? snapshot,
  }) async {
    if (!_reachability.isOnline) {
      if (await _controller.pinnedTrackIds(kind, refId) == null) {
        return UpkeepResult.notPinned;
      }
      _pending[(kind, refId)] = snapshot ?? _pending[(kind, refId)];
      return UpkeepResult.unchanged;
    }
    _pending.remove((kind, refId));
    return await _controller.refreshCollection(kind, refId, snapshot: snapshot);
  }

  /// Called by the playlist data layer when pinned playlist [playlistId]
  /// was refreshed or edited locally. Does nothing when the playlist is
  /// not pinned or its playback ids, in order, are those pinned; otherwise
  /// refreshes it after [kPlaylistUpkeepDebounce] with no further call
  /// for it, with the latest [tracks] as its snapshot.
  @override
  Future<void> onPlaylistTracksChanged(
    String playlistId,
    List<Track> tracks, {
    required String title,
    String? artworkRef,
  }) async {
    if (_disposed) return;
    final pinned = await _controller.pinnedTrackIds(
      CollectionKind.playlist,
      playlistId,
    );
    if (pinned == null) return;
    final ids = <PlaybackId>[for (final track in tracks) ?track.playbackId];
    if (listEquals(ids, pinned)) return;
    _latest[playlistId] = CollectionSnapshot(
      title: title,
      artworkRef: artworkRef,
      tracks: tracks,
    );
    _debounce.remove(playlistId)?.cancel();
    _debounce[playlistId] = _createTimer(kPlaylistUpkeepDebounce, () {
      _debounce.remove(playlistId);
      final snapshot = _latest.remove(playlistId);
      _track(
        _guard(
          'refresh a downloaded playlist',
          () =>
              refresh(CollectionKind.playlist, playlistId, snapshot: snapshot),
        ),
      );
    });
  }

  /// Resolves again, one after another, every pinned album whose last
  /// successful resolve is [kAlbumUpkeepInterval] old or older. Does
  /// nothing unless reachability is `online`; calls made while a pass runs
  /// share it.
  Future<void> runDailyAlbumPass() {
    final running = _albumPass;
    if (running != null) return running;
    final pass = _runAlbumPass().whenComplete(() => _albumPass = null);
    _albumPass = pass;
    return pass;
  }

  Future<void> _runAlbumPass() async {
    if (_disposed || !_reachability.isOnline) return;
    for (final album in await _controller.pinnedAlbums()) {
      if (_disposed || !_reachability.isOnline) return;
      final resolvedAt = album.resolvedAt;
      if (resolvedAt != null &&
          _clock.now().difference(resolvedAt) < kAlbumUpkeepInterval) {
        continue;
      }
      await _guard(
        'refresh a downloaded album',
        () => _controller.refreshCollection(CollectionKind.album, album.refId),
      );
    }
  }

  Future<void> _retryPending() async {
    final pending = Map.of(_pending);
    for (final MapEntry(key: (kind, refId), value: snapshot)
        in pending.entries) {
      if (_disposed || !_reachability.isOnline) return;
      await _guard(
        'refresh a downloaded ${kind.name}',
        () => refresh(kind, refId, snapshot: snapshot),
      );
    }
  }

  void _armDaily() {
    if (_disposed) return;
    _dailyTimer?.cancel();
    _dailyTimer = _createTimer(kAlbumUpkeepInterval, () {
      _dailyTimer = null;
      _track(
        _guard('run the album pass', runDailyAlbumPass).whenComplete(_armDaily),
      );
    });
  }

  void _track(Future<void> work) {
    _running.add(work);
    unawaited(work.whenComplete(() => _running.remove(work)));
  }

  Future<void> _guard(String what, Future<Object?> Function() body) async {
    try {
      await body();
    } on Object catch (error, stackTrace) {
      _log.warning('Could not $what', const {}, error, stackTrace);
    }
  }

  /// Completes when the work started so far has finished.
  @visibleForTesting
  Future<void> settle() async {
    while (_running.isNotEmpty || _albumPass != null) {
      await Future.wait([..._running, ?_albumPass]);
    }
  }

  /// Stops the timers and the triggers. Work already running finishes.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    if (identical(_relay?.listener, this)) _relay?.listener = null;
    for (final timer in _debounce.values) {
      timer.cancel();
    }
    _debounce.clear();
    _dailyTimer?.cancel();
    _dailyTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    await Future.wait([..._running]);
  }
}

/// The [CollectionUpkeep] of the profile scope, disposed when the scope
/// ends. `startDownloads` starts it after reconciliation. Native targets
/// only, like the [DownloadController] it drives.
final Provider<CollectionUpkeep> collectionUpkeepProvider =
    Provider<CollectionUpkeep>(
      (ref) {
        final upkeep = CollectionUpkeep(
          controller: ref.watch(downloadControllerProvider),
          reachability: ref.watch(reachabilityProvider),
          clock: ref.watch(clockProvider),
          relay: ref.watch(pinnedPlaylistRelayProvider),
        );
        ref.watch(profileDisposerProvider).register(upkeep.dispose);
        return upkeep;
      },
      dependencies: [
        profileContextProvider,
        downloadControllerProvider,
        pinnedPlaylistRelayProvider,
        profileDisposerProvider,
      ],
    );
