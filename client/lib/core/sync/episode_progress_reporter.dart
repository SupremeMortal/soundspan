// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/core/sync/play_reporter.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/domain/queue_item.dart';

final AppLogger _log = AppLogger.scope('EpisodeProgress');

/// A queue entry that stopped being current: `natural` when it played to
/// its end.
typedef EndedEntry = ({String queueItemId, bool natural});

/// The narrow view of playback [EpisodeProgressReporter] follows; the
/// playback controller is adapted to it in `core/playback` (doc 02).
abstract interface class EpisodeListeningSource {
  /// The listening states; a new listener receives the latest one first.
  Stream<ListeningState> get states;

  /// Every entry that stopped being current, delivered in order with
  /// [states].
  Stream<EndedEntry> get ended;
}

/// Saves how far the user got in the current episode as an
/// [EpisodeProgressOp] (doc 06, Podcasts; doc 07, Outbox).
///
/// Once an episode has played audibly, its progress is enqueued every
/// [interval] of audible playback, when it is paused, when it stops being
/// current, and when it ends. The op holds the position and the duration
/// in whole seconds (the position rounded); the episode counts as finished when it ended
/// naturally or at most [finishedWithin] is left. Nothing is enqueued
/// while the duration is unknown. The outbox keeps one op per episode,
/// the latest, so offline listening leaves one op to send.
///
/// The reporter only listens: it never commands playback.
class EpisodeProgressReporter {
  /// Creates the reporter of one profile, enqueueing through [_enqueue]
  /// (`Outbox.enqueue`).
  new(EpisodeListeningSource source, this._enqueue, this._clock) {
    _subscriptions
      ..add(source.states.listen(_onState))
      ..add(source.ended.listen(_onEnded));
  }

  /// How much audible playback passes between two saves.
  static const Duration interval = Duration(seconds: 15);

  /// How close to the end an episode counts as finished.
  static const Duration finishedWithin = Duration(seconds: 30);

  final Future<Object?> Function(OutboxOp op) _enqueue;
  final Clock _clock;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  /// The current episode once it has played audibly; null otherwise.
  EpisodeQueueItem? _episode;
  Duration _position = Duration.zero;
  Duration? _duration;
  bool _playing = false;

  /// When the current audible stretch began; null while not audible.
  DateTime? _audibleSince;

  /// Audible playback since the last save, up to [_audibleSince].
  Duration _heard = Duration.zero;

  Future<void> _tail = Future<void>.value();

  /// Completes when every op scheduled so far is enqueued.
  Future<void> flush() => _tail;

  /// Stops following playback. Safe to call more than once.
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    await flush();
  }

  void _onState(ListeningState state) {
    final now = _clock.now();
    final current = state.current;
    final open = _episode;
    if (open != null && current?.queueItemId != open.queueItemId) {
      _save(finished: false);
      _episode = null;
    }
    if (_episode == null) {
      if (current is! EpisodeQueueItem || !state.audible) return;
      _episode = current;
      _heard = Duration.zero;
      _audibleSince = now;
      _playing = true;
    }
    _position = state.position;
    _duration = state.duration ?? _duration;
    _accumulate(now, audible: state.audible);
    final paused = _playing && !state.playing;
    _playing = state.playing;
    if (paused) {
      _save(finished: false);
      _heard = Duration.zero;
    } else if (_heard >= interval) {
      _save(finished: false);
      _heard -= interval;
    }
  }

  void _onEnded(EndedEntry entry) {
    final open = _episode;
    if (open == null || open.queueItemId != entry.queueItemId) return;
    _accumulate(_clock.now(), audible: false);
    _save(finished: entry.natural);
    _episode = null;
  }

  void _accumulate(DateTime now, {required bool audible}) {
    final since = _audibleSince;
    if (since != null && now.isAfter(since)) _heard += now.difference(since);
    _audibleSince = audible ? now : null;
  }

  /// Enqueues the progress of the open episode; [finished] when it ended
  /// naturally.
  void _save({required bool finished}) {
    final episode = _episode;
    final duration = _duration;
    if (episode == null || duration == null || duration <= Duration.zero) {
      return;
    }
    final durationSec = duration.inSeconds;
    final currentSec = finished
        ? durationSec
        : (_position.inMilliseconds / 1000).round().clamp(0, durationSec);
    final op = EpisodeProgressOp(
      podcastId: episode.podcast.id,
      episodeId: episode.episode.id,
      currentTime: currentSec,
      duration: durationSec,
      isFinished:
          finished || durationSec - currentSec <= finishedWithin.inSeconds,
    );
    _tail = _tail
        .then((_) => _enqueue(op))
        .then<void>(
          (_) {},
          onError: (Object error, StackTrace stackTrace) => _log.warning(
            'Saving episode progress failed',
            const {},
            error,
            stackTrace,
          ),
        );
  }
}
