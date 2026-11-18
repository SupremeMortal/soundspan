// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/core/sync/outbox/outbox.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/core/sync/play_session_store.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/domain/queue_item.dart';
import 'package:soundspan/shared/util/uuid.dart';

final AppLogger _log = AppLogger.scope('PlayReporter');

/// What [PlayReporter] reads of playback at one instant.
final class ListeningState {
  /// Creates the state of [current], [audible] when the engine is `ready`
  /// and playing it, [playing] while the play intent is on, at [position]
  /// of an item [duration] long.
  const new({
    required this.audible,
    required this.playing,
    this.current,
    this.position = Duration.zero,
    this.duration,
  });

  /// The queue's current entry, null when the queue is empty.
  final QueueItem? current;

  /// Whether [current] produces sound now: the engine is `ready` and
  /// playing.
  final bool audible;

  /// The play intent; it turns off when the user pauses.
  final bool playing;

  /// The position in [current].
  final Duration position;

  /// The length of [current] once the engine knows it.
  final Duration? duration;
}

/// The narrow view of playback [PlayReporter] follows. `core/sync` may not
/// import `core/playback`, so the playback controller is adapted to it
/// there (doc 02).
abstract interface class ListeningSource {
  /// The listening states; a new listener receives the latest one first.
  Stream<ListeningState> get states;

  /// The `queueItemId` of every entry that stopped being current, finished
  /// (repeat-one replays included) or was stopped, delivered in order with
  /// [states].
  Stream<String> get entryEnded;
}

/// Reports every listen of a track exactly once, when it ends (doc 06, Play
/// Reporting).
///
/// A play belongs to one queue entry. It starts at the first instant the
/// entry is current and audible, accumulates wall-clock time only while it
/// stays audible, and ends when the entry stops being current, finishes or
/// is stopped. A play of at least [minListened] is enqueued as a [PlayOp];
/// a shorter one is discarded. The open play is kept in `play_sessions` so a
/// killed app does not lose it, and rows left by an earlier process are
/// closed when a reporter is created.
///
/// The reporter only listens: it never commands playback.
class PlayReporter {
  /// Creates the reporter of one profile and closes the plays an earlier
  /// process left behind. It writes the open play when [lifecycle] reports
  /// the app going to the background.
  new(
    ListeningSource source,
    this._sessions,
    this._outbox,
    this._clock,
    Stream<AppLifecycleState> lifecycle,
  ) {
    _schedule(_recover);
    _subscriptions
      ..add(source.states.listen(_onState))
      ..add(source.entryEnded.listen(_onEnded))
      ..add(lifecycle.listen(_onLifecycle));
  }

  /// The shortest play that is reported; the server's minimum too (P8).
  static const Duration minListened = Duration(seconds: 5);

  /// How often the open play is written while it accumulates.
  static const Duration persistEvery = Duration(seconds: 10);

  final PlaySessionStore _sessions;
  final Outbox _outbox;
  final Clock _clock;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  _OpenPlay? _open;
  Future<void> _tail = Future<void>.value();
  bool _disposed = false;

  /// Completes when every write scheduled so far has finished.
  Future<void> flush() => _tail;

  /// Stops following playback and writes the open play once more without
  /// ending it; the next reporter over the same database reports it. Safe
  /// to call more than once.
  Future<void> dispose() async {
    if (_disposed) return await flush();
    _disposed = true;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    final open = _open;
    _open = null;
    if (open != null) {
      open.accumulate(_clock.now(), audible: false);
      _persist(open);
    }
    await flush();
  }

  void _onState(ListeningState state) {
    final now = _clock.now();
    final open = _open;
    if (open != null && state.current?.queueItemId != open.item.queueItemId) {
      _end(open, now);
    }
    final play = _open;
    if (play == null) {
      final current = state.current;
      if (current is TrackQueueItem && state.audible) {
        final playbackId = current.track.playbackId;
        if (playbackId != null) {
          _open = _OpenPlay(Uuid.v4(), current, playbackId.value, now);
        }
      }
      return;
    }
    final wasPlaying = play.playing;
    play
      ..accumulate(now, audible: state.audible)
      ..playing = state.playing;
    if (play.listened - play.persisted >= persistEvery ||
        (wasPlaying && !state.playing)) {
      _persist(play);
    }
  }

  void _onEnded(String queueItemId) {
    final open = _open;
    if (open == null || open.item.queueItemId != queueItemId) return;
    _end(open, _clock.now());
  }

  void _onLifecycle(AppLifecycleState state) {
    if (state != AppLifecycleState.paused &&
        state != AppLifecycleState.detached) {
      return;
    }
    final open = _open;
    if (open == null) return;
    open.accumulate(_clock.now(), audible: open.audibleSince != null);
    _persist(open);
  }

  /// Closes [play] at [now]: enqueued when it reached [minListened],
  /// discarded otherwise; its row goes either way.
  void _end(_OpenPlay play, DateTime now) {
    _open = null;
    play.accumulate(now, audible: false);
    final session = play.toRow(now);
    if (play.listened < minListened) {
      _schedule(() => _sessions.delete([session.sessionId]));
      return;
    }
    _schedule(
      () => _outbox.transaction((store) async {
        await _sessions.delete([session.sessionId]);
        await store.enqueue(_opOf(session));
      }),
    );
  }

  void _persist(_OpenPlay play) {
    play.persisted = play.listened;
    final row = play.toRow(_clock.now());
    _schedule(() => _sessions.write(row));
  }

  /// Closes every play an earlier process left: each one that reached
  /// [minListened] is enqueued with its stored total, and every row is
  /// deleted, in one transaction.
  Future<void> _recover() => _outbox.transaction((store) async {
    final rows = await _sessions.all();
    if (rows.isEmpty) return;
    for (final row in rows) {
      if (Duration(milliseconds: row.listenedMs) >= minListened) {
        await store.enqueue(_opOf(row));
      }
    }
    await _sessions.delete(rows.map((row) => row.sessionId));
  });

  static PlayOp _opOf(PlaySession row) => PlayOp(
    sessionId: row.sessionId,
    playbackId: row.playbackId,
    metadata: (jsonDecode(row.metaJson) as Map).cast<String, Object?>(),
    playedAt: row.playedAt.toUtc(),
    listenedMs: row.listenedMs,
  );

  void _schedule(Future<void> Function() write) {
    _tail = _tail
        .then((_) => write())
        .catchError(
          (Object error, StackTrace stackTrace) => _log.warning(
            'Writing a play failed',
            const {},
            error,
            stackTrace,
          ),
        );
  }
}

/// The play in progress.
final class _OpenPlay {
  new(this.sessionId, this.item, this.playbackId, this.playedAt)
    : audibleSince = playedAt;

  final String sessionId;
  final TrackQueueItem item;
  final String playbackId;
  final DateTime playedAt;

  /// When the current audible stretch began; null while not audible.
  DateTime? audibleSince;

  /// The total heard so far, up to [audibleSince].
  Duration listened = Duration.zero;

  /// [listened] when the row was last written.
  Duration persisted = Duration.zero;

  /// The play intent last seen.
  bool playing = true;

  /// Adds the audible stretch up to [now] and starts a new one when
  /// [audible].
  void accumulate(DateTime now, {required bool audible}) {
    final since = audibleSince;
    if (since != null && now.isAfter(since)) listened += now.difference(since);
    audibleSince = audible ? now : null;
  }

  PlaySession toRow(DateTime now) => PlaySession(
    sessionId: sessionId,
    queueItemId: item.queueItemId,
    playbackId: playbackId,
    metaJson: jsonEncode(item.track.meta.toJson()),
    playedAt: playedAt,
    listenedMs: listened.inMilliseconds,
    updatedAt: now,
  );
}
