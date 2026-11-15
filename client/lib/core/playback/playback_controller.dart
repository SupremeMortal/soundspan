// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/playback_command.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/core/playback/queue/queue_command.dart';
import 'package:soundspan/core/playback/queue/queue_reducer.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/core/playback/snapshot_publisher.dart';
import 'package:soundspan/core/playback/source_resolver.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/domain/queue_item.dart';

final AppLogger _log = AppLogger.scope('Playback');

/// The one object UI, OS controls and Listen Together talk to (doc 06,
/// Component Responsibilities).
///
/// It owns the queue (through [QueueReducer]) and the engine, publishes
/// [PlaybackSnapshot]s, turns commands and queue effects into engine calls,
/// and keeps the engine's preloaded next source equal to the queue's
/// `upNext`. Nothing else calls the engine.
class PlaybackController {
  /// Creates the controller of one profile; it owns [_engine] from now on.
  new({
    required this._engine,
    required this._resolver,
    required Clock clock,
    this._reducer = const QueueReducer(),
  }) : _publisher = SnapshotPublisher(clock) {
    _stateSubscription = _engine.state.listen(_onEngineState);
    _eventSubscription = _engine.events.listen(
      (event) => unawaited(_enqueue(() => _onEngineEvent(event))),
    );
  }

  final PlayerEngine _engine;
  final SourceResolver _resolver;
  final QueueReducer _reducer;
  final SnapshotPublisher _publisher;
  final StreamController<PlaybackNotice> _notices =
      StreamController<PlaybackNotice>.broadcast();
  late final StreamSubscription<EngineState> _stateSubscription;
  late final StreamSubscription<EngineEvent> _eventSubscription;

  Future<void> _tail = Future<void>.value();
  QueueState _queue = QueueState.empty();
  EngineState _engineState = EngineState.idle;
  bool _playIntent = false;
  PlaybackError? _error;
  EngineSource? _currentSource;
  bool _disposed = false;

  /// The id of the entry last handed to the engine as next; null when the
  /// slot is empty.
  String? _nextId;
  EngineSource? _nextSource;
  int _nextRequest = 0;
  Future<void> _nextSync = Future<void>.value();

  /// Where the current item starts when it is loaded lazily by [play].
  Duration _pendingStartAt = Duration.zero;

  double _userVolume = 1;
  final Map<String, double> _volumeFactors = {};

  /// The snapshots; a new listener receives the latest one first. Changes
  /// of the position alone arrive at most four times a second.
  Stream<PlaybackSnapshot> get snapshots => _publisher.stream;

  /// The latest snapshot.
  PlaybackSnapshot get snapshot => _publisher.latest;

  /// One-shot messages for the UI.
  Stream<PlaybackNotice> get notices => _notices.stream;

  /// The user volume, 0.0–1.0.
  double get volume => _userVolume;

  /// Applies [command] after every command that arrived before it.
  ///
  /// Completes when the command is applied and the engine's next source
  /// it caused is set.
  Future<void> dispatch(PlaybackCommand command) =>
      _enqueue(() => _apply(command));

  /// Replaces the queue with [items] and plays from [startIndex].
  Future<void> playItems(
    List<QueueItem> items, {
    int startIndex = 0,
    QueueContext? context,
  }) => dispatch(
    PlayItemsCommand(items, startIndex: startIndex, context: context),
  );

  /// Plays the current item, loading it first when nothing is loaded.
  Future<void> play() => dispatch(const PlayCommand());

  /// Pauses, keeping the position.
  Future<void> pause() => dispatch(const PauseCommand());

  /// Pauses when playing, else plays.
  Future<void> togglePlayPause() => dispatch(const TogglePlayPauseCommand());

  /// Moves to [position] in the current item.
  Future<void> seek(Duration position) => dispatch(SeekCommand(position));

  /// Skips to the next item.
  Future<void> next() => dispatch(const NextCommand());

  /// Restarts the current item or goes back one.
  Future<void> previous() => dispatch(const PreviousCommand());

  /// Plays the entry [queueItemId].
  Future<void> jumpTo(String queueItemId) =>
      dispatch(JumpToCommand(queueItemId));

  /// Inserts [items] directly after the current entry.
  Future<void> playNext(List<QueueItem> items) =>
      dispatch(PlayNextCommand(items));

  /// Adds [items] at the end of the queue.
  Future<void> append(List<QueueItem> items) => dispatch(AppendCommand(items));

  /// Removes the entry [queueItemId].
  Future<void> removeAt(String queueItemId) =>
      dispatch(RemoveAtCommand(queueItemId));

  /// Moves the entry [queueItemId] to [toPlayIndex] of the play order.
  Future<void> move(String queueItemId, int toPlayIndex) =>
      dispatch(MoveCommand(queueItemId, toPlayIndex));

  /// Turns shuffle on or off.
  Future<void> setShuffle(bool enabled) => dispatch(SetShuffleCommand(enabled));

  /// Sets the repeat mode.
  Future<void> setRepeat(RepeatMode mode) => dispatch(SetRepeatCommand(mode));

  /// Empties the queue and stops.
  Future<void> clear() => dispatch(const ClearCommand());

  /// Stops playback; the queue is kept.
  Future<void> stop() => dispatch(const StopCommand());

  /// Sets the user volume, clamped to 0.0–1.0.
  Future<void> setVolume(double volume) => dispatch(SetVolumeCommand(volume));

  /// Sets the volume factor named [key] (`loudness`, `duck`); the engine
  /// volume is the user volume times every factor, clamped to 0.0–1.0.
  void setVolumeFactor(String key, double factor) {
    _volumeFactors[key] = factor;
    unawaited(_applyVolume());
  }

  /// Stops playback, disposes the engine and closes both streams. Safe to
  /// call more than once.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _stateSubscription.cancel();
    await _eventSubscription.cancel();
    await _publisher.close();
    await _notices.close();
    try {
      await _engine.stop();
    } finally {
      await _engine.dispose();
    }
  }

  Future<void> _enqueue(Future<void> Function() step) {
    final result = _tail.then((_) => _disposed ? null : step());
    _tail = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) =>
          _log.warning('A playback step failed', const {}, error, stackTrace),
    );
    return result.then((_) => _nextSync);
  }

  Future<void> _apply(PlaybackCommand command) async {
    switch (command) {
      case PlayItemsCommand(:final items, :final startIndex, :final context):
        _playIntent = true;
        await _reduce(
          ReplaceAll(items, startIndex: startIndex, context: context),
        );
      case PlayCommand():
        await _play();
      case PauseCommand():
        _playIntent = false;
        _publish();
        await _engine.pause();
      case TogglePlayPauseCommand():
        if (_playIntent) {
          _playIntent = false;
          _publish();
          await _engine.pause();
        } else {
          await _play();
        }
      case SeekCommand(:final position):
        await _engine.seek(position);
      case NextCommand():
        await _reduce(const Next());
      case PreviousCommand():
        await _reduce(Previous(_engineState.position));
      case JumpToCommand(:final queueItemId):
        _playIntent = true;
        await _reduce(JumpTo(queueItemId));
      case PlayNextCommand(:final items):
        await _reduce(PlayNext(items));
      case AppendCommand(:final items):
        await _reduce(Append(items));
      case RemoveAtCommand(:final queueItemId):
        await _reduce(RemoveAt(queueItemId));
      case MoveCommand(:final queueItemId, :final toPlayIndex):
        await _reduce(Move(queueItemId, toPlayIndex));
      case SetShuffleCommand(:final enabled):
        await _reduce(SetShuffle(enabled));
      case SetRepeatCommand(:final mode):
        await _reduce(SetRepeat(mode));
      case ClearCommand():
        await _reduce(const Clear());
      case StopCommand():
        await _stopEngine();
        _publish();
      case SetVolumeCommand(:final volume):
        _userVolume = volume.clamp(0.0, 1.0);
        await _applyVolume();
    }
  }

  Future<void> _play() async {
    _playIntent = true;
    _publish();
    if (_queue.current == null) return;
    if (_currentSource == null) {
      await _loadCurrent();
      _syncNext();
    } else {
      await _engine.play();
    }
  }

  Future<void> _reduce(QueueCommand command) async {
    final transition = _reducer.reduce(_queue, command);
    _queue = transition.state;
    if (transition.dropped > 0) _notices.add(ItemsDropped(transition.dropped));
    await _applyEffect(transition.effect);
    _publish();
    _syncNext();
  }

  Future<void> _applyEffect(QueueEffect effect) async {
    switch (effect) {
      case QueueEffect.loadCurrent:
        await _loadCurrent();
      case QueueEffect.restartCurrent:
        await _engine.seek(Duration.zero);
        if (_playIntent) await _engine.play();
      case QueueEffect.stop:
        await _stopEngine();
      case QueueEffect.none:
        break;
    }
  }

  Future<void> _stopEngine() async {
    _playIntent = false;
    _clearNextSlot();
    _currentSource = null;
    await _engine.stop();
  }

  /// Resolves the queue's current item and loads it; the engine's next slot
  /// is empty afterwards.
  Future<void> _loadCurrent() async {
    final item = _queue.current;
    _clearNextSlot();
    _currentSource = null;
    _error = null;
    if (item == null) return;
    final startAt = _pendingStartAt;
    _pendingStartAt = Duration.zero;
    final EngineSource source;
    try {
      source = await _resolver.resolve(item, startAt: startAt);
    } on NotPlayable {
      _onCurrentItemFailed(PlaybackErrorKind.itemUnavailable, item.queueItemId);
      return;
    } on Object catch (error, stackTrace) {
      _log.warning(
        'Resolving the current item failed',
        const {},
        error,
        stackTrace,
      );
      _onCurrentItemFailed(PlaybackErrorKind.itemFailed, item.queueItemId);
      return;
    }
    _currentSource = source;
    _publish();
    await _engine.load(source, autoPlay: _playIntent);
  }

  /// What happens when the current item cannot be played.
  void _onCurrentItemFailed(PlaybackErrorKind kind, String queueItemId) {
    _error = PlaybackError(kind, queueItemId: queueItemId);
    _playIntent = false;
    _publish();
  }

  Future<void> _onEngineEvent(EngineEvent event) async {
    switch (event) {
      case AdvancedToNext(:final queueItemId):
        await _onAdvanced(queueItemId);
      case Completed(:final queueItemId):
        await _reduce(ItemFinished(queueItemId));
      case Failed(:final queueItemId):
        _onFailed(queueItemId);
    }
  }

  Future<void> _onAdvanced(String queueItemId) async {
    final finished = _queue.current?.queueItemId;
    final preloaded = _nextSource;
    _clearNextSlot();
    if (finished != null) {
      final transition = _reducer.reduce(_queue, ItemFinished(finished));
      _queue = transition.state;
      if (_queue.current?.queueItemId == queueItemId) {
        _currentSource = preloaded;
      } else {
        await _applyEffect(
          transition.effect == QueueEffect.stop
              ? QueueEffect.stop
              : QueueEffect.loadCurrent,
        );
      }
    }
    _publish();
    _syncNext();
  }

  void _onFailed(String queueItemId) {
    final isCurrent =
        _queue.current?.queueItemId == queueItemId &&
        (_nextId != queueItemId || _engineState.status == EngineStatus.error);
    if (isCurrent) {
      _onCurrentItemFailed(PlaybackErrorKind.itemFailed, queueItemId);
    } else if (_nextId == queueItemId) {
      _nextSource = null;
      _nextSync = _engine.setNext(null);
    }
  }

  void _clearNextSlot() {
    _nextId = null;
    _nextSource = null;
    _nextRequest++;
  }

  /// Hands the queue's `upNext` to the engine when it differs from what the
  /// engine has. Only the latest request counts.
  void _syncNext() {
    final upNext = _queue.upNext;
    final id = upNext?.queueItemId;
    if (_queue.current == null || _currentSource == null) return;
    if (id == _nextId) return;
    _nextId = id;
    _nextSource = null;
    final request = ++_nextRequest;
    _nextSync = _setNext(upNext, request);
  }

  Future<void> _setNext(QueueItem? item, int request) async {
    if (item == null) {
      await _engine.setNext(null);
      return;
    }
    EngineSource? source;
    try {
      source = await _resolver.resolve(item);
    } on Object catch (error) {
      _log.fine('The next item cannot be resolved', {'error': '$error'});
    }
    if (request != _nextRequest || _disposed) return;
    _nextSource = source;
    await _engine.setNext(source);
  }

  Future<void> _applyVolume() async {
    if (_disposed) return;
    var linear = _userVolume;
    for (final factor in _volumeFactors.values) {
      linear *= factor;
    }
    await _engine.setVolume(linear.clamp(0.0, 1.0));
  }

  void _onEngineState(EngineState state) {
    _engineState = state;
    _publish();
  }

  void _publish() {
    final current = _queue.current;
    final state = _engineState;
    _publisher.publish(
      PlaybackSnapshot(
        queue: _queue,
        current: current,
        status: state.status,
        playing: _playIntent,
        position: state.position,
        buffered: state.bufferedPosition,
        duration: state.duration,
        error: _error,
        isLocalFile: _currentSource?.uri.isScheme('file') ?? false,
      ),
    );
  }
}
