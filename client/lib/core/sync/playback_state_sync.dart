// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/sync/data/playback_state_repository.dart';
import 'package:soundspan/core/sync/playback_state.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan/shared/domain/queue_item.dart';
import 'package:soundspan/shared/domain/track.dart';
import 'package:soundspan/shared/util/uuid.dart';

final AppLogger _log = AppLogger.scope('PlaybackStateSync');

/// Creates a one-shot timer; [Timer.new] outside tests.
typedef SyncTimerFactory = Timer Function(
  Duration delay,
  void Function() callback,
);

/// What [PlaybackStateSync] reads of the player: the queue in canonical
/// order with its shuffle permutation and cursor, and the transport.
///
/// `core/sync` may not import `core/playback` (doc 02), so the playback
/// wiring maps each controller snapshot to this.
final class SyncedPlayback {
  /// Creates the view of one snapshot.
  const new({
    required this.items,
    required this.revision,
    this.shuffleOrder,
    this.cursor,
    this.playing = false,
    this.position = Duration.zero,
  });

  /// The entries in canonical order.
  final List<QueueItem> items;

  /// A permutation of indices into [items] when shuffle is on.
  final List<int>? shuffleOrder;

  /// Index into the play order of the current entry; null when empty.
  final int? cursor;

  /// The queue's revision, grown on every queue change.
  final int revision;

  /// Whether playback is running.
  final bool playing;

  /// The position in the current entry.
  final Duration position;

  /// The index into [items] of the play-order position [playIndex].
  int canonicalIndex(int playIndex) => shuffleOrder?[playIndex] ?? playIndex;

  /// The current entry; null when the queue is empty.
  QueueItem? get current {
    final at = cursor;
    if (at == null || at < 0 || at >= items.length) return null;
    return items[canonicalIndex(at)];
  }
}

/// A queue rebuilt from the state the server stored for this device:
/// `items` in play order, the current one at `cursor`, `position` into it.
typedef RemoteQueue = ({
  List<QueueItem> items,
  int cursor,
  Duration position,
  bool isShuffle,
});

/// The window of [playback]'s play order the server stores: up to
/// [PlaybackStateSync.windowBefore] entries before the cursor, the current
/// one and up to [PlaybackStateSync.windowAfter] after it, without the
/// tracks that have no `playbackId`; `currentIndex` is the current entry's
/// index inside the window (doc 06, Playback-State Sync).
(List<PlaybackStateEntry> items, int currentIndex) windowOf(
  SyncedPlayback playback,
) {
  final cursor = playback.cursor;
  final length = playback.items.length;
  if (cursor == null || length == 0) return (const [], 0);
  final start = cursor - PlaybackStateSync.windowBefore < 0
      ? 0
      : cursor - PlaybackStateSync.windowBefore;
  final end = cursor + PlaybackStateSync.windowAfter + 1 > length
      ? length
      : cursor + PlaybackStateSync.windowAfter + 1;
  final entries = <PlaybackStateEntry>[];
  var currentIndex = 0;
  for (var playIndex = start; playIndex < end; playIndex++) {
    if (playIndex == cursor) currentIndex = entries.length;
    final entry = _entryOf(playback.items[playback.canonicalIndex(playIndex)]);
    if (entry != null) entries.add(entry);
  }
  return (entries, currentIndex);
}

PlaybackStateEntry? _entryOf(QueueItem item) => switch (item) {
  TrackQueueItem(:final track) =>
    track.playbackId == null
        ? null
        : PlaybackStateEntry.track(
            playbackId: track.playbackId,
            meta: track.meta,
          ),
  EpisodeQueueItem(:final episode, :final podcast) =>
    PlaybackStateEntry.episode(
      podcastId: podcast.id,
      episodeId: episode.id,
      title: episode.title,
      podcastTitle: podcast.title,
      durationSec: episode.durationSec ?? 0,
      coverUrl: episode.artworkRef ?? podcast.artworkRef,
    ),
};

/// Keeps the server's copy of this device's queue and position current
/// (`POST /playback-state`), and reads it back when the device has no
/// queue of its own (doc 06, Playback-State Sync).
///
/// It posts every [playingInterval] while playing, on pause, when the
/// current entry changes, [editDelay] after the last queue edit and when
/// the app goes to the background. At most one request is in flight: a
/// trigger meanwhile queues the newest state, sent when the request ends.
/// Nothing is sent while [ReachabilityController.isOnline] is false; a
/// skipped or failed state is sent when it is online again. An emptied
/// queue sends `DELETE /playback-state` instead. Nothing goes through the
/// outbox: only the latest state matters.
class PlaybackStateSync {
  /// Creates the sync over the profile's [_repository]; [_lifecycle] is the
  /// app's lifecycle states.
  new({
    required this._repository,
    required this._reachability,
    required this._lifecycle,
    this._createTimer = Timer.new,
  });

  /// How often the state is posted while playing (the web cadence).
  static const Duration playingInterval = Duration(seconds: 15);

  /// How long the queue must stay unedited before it is posted.
  static const Duration editDelay = Duration(seconds: 2);

  /// The most entries sent before the current one.
  static const int windowBefore = 20;

  /// The most entries sent after the current one.
  static const int windowAfter = 79;

  final PlaybackStateRepository _repository;
  final ReachabilityController _reachability;
  final Stream<AppLifecycleState> _lifecycle;
  final SyncTimerFactory _createTimer;

  final List<StreamSubscription<Object?>> _subscriptions = [];
  SyncedPlayback? _latest;
  String? _currentId;
  List<String> _itemIds = const [];
  List<int>? _shuffleOrder;
  int? _revision;
  bool _playing = false;
  Timer? _playingTimer;
  Timer? _editTimer;
  bool _inFlight = false;
  bool _queued = false;
  bool _missed = false;
  bool _disposed = false;

  /// Follows [playback] from now on; its first state is the one restored at
  /// start, so it is not sent.
  void follow(Stream<SyncedPlayback> playback) {
    if (_disposed) return;
    _subscriptions
      ..add(playback.listen(_onPlayback))
      ..add(_lifecycle.listen(_onLifecycle))
      ..add(_reachability.changes.listen(_onReachability));
  }

  /// The queue the server stored for this device: its tracks in the order
  /// stored, paused at the stored position. Null when there is none, it
  /// is empty or the request fails. Episode entries are left out; when the
  /// current entry was left out, the first remaining one is current, at
  /// position zero.
  Future<RemoteQueue?> restore() async {
    final RemotePlaybackState? state;
    try {
      state = await _repository.fetch();
    } on Object catch (error, stackTrace) {
      _log.warning(
        'Reading the stored playback state failed',
        const {},
        error,
        stackTrace,
      );
      return null;
    }
    if (state == null) return null;
    final items = <QueueItem>[];
    int? cursor;
    for (final (index, entry) in state.queue.indexed) {
      if (entry case TrackStateEntry(:final playbackId?, :final meta)) {
        if (index == state.currentIndex) cursor = items.length;
        items.add(_trackItem(playbackId: playbackId, meta: meta));
      }
    }
    if (items.isEmpty) return null;
    return (
      items: items,
      cursor: cursor ?? 0,
      position: cursor == null
          ? Duration.zero
          : Duration(milliseconds: (state.currentTime * 1000).round()),
      isShuffle: state.isShuffle,
    );
  }

  /// Stops following; a request in flight completes. Safe to call more
  /// than once.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _playingTimer?.cancel();
    _editTimer?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
  }

  void _onPlayback(SyncedPlayback playback) {
    if (_disposed) return;
    final first = _latest == null;
    final previous = _latest;
    _latest = playback;
    final currentId = playback.current?.queueItemId;
    final currentChanged = currentId != _currentId;
    final paused = _playing && !playback.playing;
    final revisionChanged = playback.revision != _revision;
    final edited = revisionChanged && _isEdit(playback);
    _currentId = currentId;
    _revision = playback.revision;
    _playing = playback.playing;
    _followPlaying(playback.playing);
    if (first) return;

    if (playback.items.isEmpty) {
      if (previous != null && previous.items.isNotEmpty) {
        _editTimer?.cancel();
        _send();
      }
      return;
    }
    if (currentChanged || paused) {
      _editTimer?.cancel();
      _send();
    } else if (edited) {
      _editTimer?.cancel();
      _editTimer = _createTimer(editDelay, _send);
    }
  }

  /// Whether [playback]'s entries or shuffle order differ from the last
  /// ones seen, rather than only its cursor; remembers them.
  bool _isEdit(SyncedPlayback playback) {
    final ids = [for (final item in playback.items) item.queueItemId];
    final shuffle = playback.shuffleOrder;
    final edited =
        !_sameList(ids, _itemIds) || !_sameNullableList(shuffle, _shuffleOrder);
    _itemIds = ids;
    _shuffleOrder = shuffle;
    return edited;
  }

  void _followPlaying(bool playing) {
    if (!playing) {
      _playingTimer?.cancel();
      _playingTimer = null;
      return;
    }
    if (_playingTimer != null) return;
    _playingTimer = _createTimer(playingInterval, () {
      _playingTimer = null;
      if (_disposed) return;
      _send();
      _followPlaying(_playing);
    });
  }

  void _onLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused || AppLifecycleState.detached:
        if (_latest != null) _send();
      case AppLifecycleState.resumed ||
          AppLifecycleState.inactive ||
          AppLifecycleState.hidden:
        break;
    }
  }

  void _onReachability(Reachability reachability) {
    if (reachability == Reachability.online && _missed) _send();
  }

  /// Sends the latest state now, or after the request in flight.
  void _send() {
    if (_disposed || _latest == null) return;
    if (!_reachability.isOnline) {
      _missed = true;
      return;
    }
    if (_inFlight) {
      _queued = true;
      return;
    }
    _missed = false;
    _inFlight = true;
    unawaited(_request(_latest!));
  }

  Future<void> _request(SyncedPlayback playback) async {
    try {
      final draft = _draftOf(playback);
      if (draft == null) {
        await _repository.clear();
      } else {
        await _repository.save(draft);
      }
    } on Object catch (error, stackTrace) {
      _missed = true;
      _log.warning(
        'Sending the playback state failed',
        const {},
        error,
        stackTrace,
      );
    } finally {
      _inFlight = false;
      if (_queued) {
        _queued = false;
        _send();
      }
    }
  }

  static PlaybackStateDraft? _draftOf(SyncedPlayback playback) {
    final current = playback.current;
    if (current == null) return null;
    final (queue, currentIndex) = windowOf(playback);
    final currentTime = playback.position.inMilliseconds / 1000;
    final isShuffle = playback.shuffleOrder != null;
    return switch (current) {
      TrackQueueItem(:final track) => PlaybackStateDraft(
        playbackType: PlaybackStateType.track,
        playbackId: track.playbackId,
        currentIndex: currentIndex,
        currentTime: currentTime,
        isShuffle: isShuffle,
        isPlaying: playback.playing,
        queue: queue,
      ),
      EpisodeQueueItem(:final podcast) => PlaybackStateDraft(
        playbackType: PlaybackStateType.podcast,
        podcastId: podcast.id,
        currentIndex: currentIndex,
        currentTime: currentTime,
        isShuffle: isShuffle,
        isPlaying: playback.playing,
        queue: queue,
      ),
    };
  }
}

/// The context of a queue restored from the server, which stores none.
const QueueContext restoredQueueContext = QueueContext(
  kind: QueueContextKind.library,
);

QueueItem _trackItem({
  required PlaybackId playbackId,
  required TrackMeta meta,
}) => QueueItem.track(
  queueItemId: Uuid.v4(),
  track: Track(meta: meta, playbackId: playbackId),
  context: restoredQueueContext,
);

bool _sameList(List<Object?> a, List<Object?> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _sameNullableList(List<Object?>? a, List<Object?>? b) =>
    a == null || b == null ? a == b : _sameList(a, b);
