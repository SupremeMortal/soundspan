// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:soundspan/core/auth/session_controller.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/playback/data/playback_info_repository.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/failure_policy.dart';
import 'package:soundspan/core/playback/persistence.dart';
import 'package:soundspan/core/playback/playback_command.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/core/playback/queue/queue_command.dart';
import 'package:soundspan/core/playback/queue/queue_reducer.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/core/playback/snapshot_publisher.dart';
import 'package:soundspan/core/playback/source_resolver.dart';
import 'package:soundspan/core/playback/stream_quality_info.dart';
import 'package:soundspan/core/storage/state/device_settings_dao.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan/shared/domain/queue_item.dart';

final AppLogger _log = AppLogger.scope('Playback');

/// The `device_settings` key of the user volume, a decimal string
/// 0.0–1.0 (doc 05).
const String playbackVolumeKey = 'playback.volume';

/// Creates the timer of a failure retry; [Timer.new] outside tests.
typedef PlaybackTimerFactory = Timer Function(
  Duration delay,
  void Function() callback,
);

/// Takes the queue and transport commands of a `PlaybackController` while
/// it is attached, such as Listen Together sending them to the server
/// (doc 06, Listen Together Hook).
abstract interface class RemoteDriver {
  /// Receives every queue and transport command issued while the driver is attached.
  Future<void> onCommand(PlaybackCommand command);
}

/// The one object UI, OS controls and Listen Together talk to (doc 06,
/// Component Responsibilities).
///
/// It owns the queue (through [QueueReducer]) and the engine, publishes
/// [PlaybackSnapshot]s, turns commands and queue effects into engine calls,
/// and keeps the engine's preloaded next source equal to the queue's
/// `upNext`. Nothing else calls the engine.
///
/// A failed current item is retried, skipped or stops playback by the
/// [FailurePolicy]; a 401 renews the credential through [_session] once.
///
/// With a [QueuePersistence], [restore] reads the queue this device stored
/// and the persistence follows the snapshots from then on. When none is
/// stored, the queue comes from the remote restore when one is given (the
/// state the server keeps for this device, doc 06, Playback-State Sync).
///
/// The user volume is kept in the device settings under
/// [playbackVolumeKey] and read back before the first command is applied.
class PlaybackController {
  /// Creates the controller of one profile; it owns [_engine] from now on.
  new({
    required this._engine,
    required this._resolver,
    required this._info,
    required this._session,
    required Clock clock,
    this._deviceSettings,
    this._reducer = const QueueReducer(),
    this._createTimer = Timer.new,
    this._persistence,
    this._remoteRestore,
  }) : _publisher = SnapshotPublisher(clock) {
    _stateSubscription = _engine.state.listen(_onEngineState);
    _eventSubscription = _engine.events.listen(
      (event) => unawaited(_enqueue(() => _onEngineEvent(event))),
    );
    if (_deviceSettings != null) unawaited(_enqueue(_restoreVolume));
  }

  final PlayerEngine _engine;
  final SourceResolver _resolver;
  final PlaybackInfoRepository _info;
  final SessionController _session;
  final DeviceSettingsDao? _deviceSettings;
  final PlaybackTimerFactory _createTimer;
  final QueueReducer _reducer;
  final SnapshotPublisher _publisher;
  final QueuePersistence? _persistence;
  final Future<RestoredQueue?> Function()? _remoteRestore;
  final StreamController<PlaybackNotice> _notices =
      StreamController<PlaybackNotice>.broadcast();
  final StreamController<EntryEnded> _ended =
      StreamController<EntryEnded>.broadcast();
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

  final ValueNotifier<double> _volume = ValueNotifier<double>(1);
  double get _userVolume => _volume.value;
  set _userVolume(double value) => _volume.value = value;
  final Map<String, double> _volumeFactors = {};

  final FailurePolicy _failures = FailurePolicy();

  /// The waiting retry of the current item, if any.
  Timer? _retryTimer;

  /// Counts changes of the current item and stops; a retry of an older
  /// generation is dropped.
  int _generation = 0;

  /// Whether the failure of the current load was handled already; a second
  /// `Failed` for the same load is ignored.
  bool _failureHandled = false;

  /// The last position the engine reported for the current item.
  Duration _lastPosition = Duration.zero;

  /// The entry whose quality info is known or being fetched.
  String? _qualityOf;
  StreamQualityInfo? _quality;

  RemoteDriver? _driver;

  PauseOrigin? _pauseOrigin;

  /// Asked before playback starts, while the controller is paused: when it
  /// answers false, playback does not start and [FocusDenied] is emitted.
  /// Set by the audio-focus rules, so audio never starts before the OS
  /// granted focus (doc 06, Audio Focus and Interruptions).
  Future<bool> Function()? beforePlay;

  /// Who issued the latest transport command (play, pause, stop, next,
  /// previous, jump, seek); [PauseOrigin.focus] only while the latest one
  /// is a pause by the audio-focus rules. Null before the first one.
  PauseOrigin? get pauseOrigin => _pauseOrigin;

  /// The snapshots; a new listener receives the latest one first. Changes
  /// of the position alone arrive at most four times a second.
  Stream<PlaybackSnapshot> get snapshots => _publisher.stream;

  /// The latest snapshot.
  PlaybackSnapshot get snapshot => _publisher.latest;

  /// One-shot messages for the UI.
  Stream<PlaybackNotice> get notices => _notices.stream;

  /// Every time the current entry stops being the one playing: next,
  /// previous that moves the cursor, jump, replace, remove, clear, stop, a
  /// failure that skips or stops, its natural end, and a repeat-one replay
  /// (doc 06, Play Reporting). Each event is emitted before the snapshots
  /// that follow it and reaches a listener after the snapshots published
  /// before it.
  Stream<EntryEnded> get entryEnded => Stream<EntryEnded>.multi((listener) {
    if (_ended.isClosed) {
      unawaited(listener.close());
      return;
    }
    // The same two hops as [snapshots], so both arrive in emission order.
    final subscription = _ended.stream.listen(
      listener.add,
      onDone: listener.close,
    );
    listener.onCancel = subscription.cancel;
  });

  /// The user volume, 0.0–1.0.
  double get volume => _userVolume;

  /// The user volume, 0.0–1.0, notifying when it is set or read back from
  /// the device settings.
  ValueListenable<double> get volumeListenable => _volume;

  /// Whether a [RemoteDriver] takes the queue and transport commands.
  bool get hasRemoteDriver => _driver != null;

  /// Routes every queue and transport command to [driver] until
  /// [detachRemoteDriver]; `setVolume` stays local. Throws [StateError]
  /// when a driver is attached already.
  void attachRemoteDriver(RemoteDriver driver) {
    if (_driver != null) {
      throw StateError('A RemoteDriver is attached already');
    }
    _driver = driver;
  }

  /// Applies commands locally again.
  void detachRemoteDriver() => _driver = null;

  /// Rebuilds the queue this device stored, paused at the stored position,
  /// and starts persisting changes. Called once, before any command; it
  /// makes no engine call and, with a stored queue, no network request: the
  /// first [play] loads the current item at that position. Only when no
  /// queue is stored is the remote restore asked. Does nothing without a
  /// [QueuePersistence].
  Future<void> restore() => _enqueue(() async {
    final persistence = _persistence;
    if (persistence == null) return;
    final restored = await persistence.load() ?? await _remoteRestore?.call();
    if (restored != null) {
      _queue = restored.queue;
      _pendingStartAt = restored.position;
      _publish();
    }
    persistence.follow(snapshots, isRemote: () => hasRemoteDriver);
  });

  /// Applies [command] after every command that arrived before it, or
  /// hands it to the attached [RemoteDriver].
  ///
  /// Completes when the command is applied and the engine's next source
  /// it caused is set.
  Future<void> dispatch(PlaybackCommand command) {
    final driver = _driver;
    if (driver != null && command is! SetVolumeCommand) {
      return driver.onCommand(command);
    }
    return _enqueue(() => _apply(command));
  }

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

  /// Pauses, keeping the position; [origin] tells a pause of the
  /// audio-focus rules from the user's.
  Future<void> pause({PauseOrigin origin = PauseOrigin.user}) =>
      dispatch(PauseCommand(origin: origin));

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

  /// Sets the user volume, clamped to 0.0–1.0, and stores it on the
  /// device.
  Future<void> setVolume(double volume) => dispatch(SetVolumeCommand(volume));

  /// Sets the engine speed to [speed] (clamped to 0.5–3.0 by the engine)
  /// when the current entry is an episode; with a track or nothing current
  /// it does nothing (doc 06, Podcasts).
  Future<void> setEpisodeSpeed(double speed) => _enqueue(() async {
    if (_queue.current is EpisodeQueueItem) await _engine.setSpeed(speed);
  });

  /// Sets the volume factor named [key] (`loudness`, `duck`); the engine
  /// volume is the user volume times every factor, clamped to 0.0–1.0.
  /// An unset factor counts as 1.0; setting a factor to the value it has
  /// makes no engine call.
  void setVolumeFactor(String key, double factor) {
    final unchanged = (_volumeFactors[key] ?? 1.0) == factor;
    _volumeFactors[key] = factor;
    if (!unchanged) unawaited(_applyVolume());
  }

  /// Writes the queue a last time, stops playback, disposes the engine and
  /// closes both streams. Safe to call more than once.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _retryTimer?.cancel();
    try {
      await _persistence?.dispose();
    } on Object catch (error, stackTrace) {
      _log.warning('Saving the queue failed', const {}, error, stackTrace);
    }
    await _stateSubscription.cancel();
    await _eventSubscription.cancel();
    await _publisher.close();
    await _notices.close();
    await _ended.close();
    _volume.dispose();
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
    _noteOrigin(command);
    switch (command) {
      case PlayItemsCommand(:final items, :final startIndex, :final context):
        _playIntent = await _mayStart();
        _failures.resetCount();
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
        _playIntent = await _mayStart();
        _failures.resetCount();
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
        _endCurrent();
        await _stopEngine();
        _publish();
      case SetVolumeCommand(:final volume):
        _userVolume = volume.clamp(0.0, 1.0);
        await _applyVolume();
        await _storeVolume();
    }
  }

  /// Records who issued [command] when it is a transport command.
  void _noteOrigin(PlaybackCommand command) {
    switch (command) {
      case PauseCommand(:final origin):
        _pauseOrigin = origin;
      case PlayItemsCommand() ||
          PlayCommand() ||
          TogglePlayPauseCommand() ||
          SeekCommand() ||
          NextCommand() ||
          PreviousCommand() ||
          JumpToCommand() ||
          StopCommand():
        _pauseOrigin = PauseOrigin.user;
      case PlayNextCommand() ||
          AppendCommand() ||
          RemoveAtCommand() ||
          MoveCommand() ||
          SetShuffleCommand() ||
          SetRepeatCommand() ||
          ClearCommand() ||
          SetVolumeCommand():
        break;
    }
  }

  /// Whether playback may start: true when it plays already or
  /// [beforePlay] allows it; otherwise emits [FocusDenied].
  Future<bool> _mayStart() async {
    final hook = beforePlay;
    if (_playIntent || hook == null) return true;
    if (await hook()) return true;
    _notices.add(const FocusDenied());
    return false;
  }

  Future<void> _play() async {
    if (!await _mayStart()) {
      _publish();
      return;
    }
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
    final previous = _queue.current?.queueItemId;
    final transition = _reducer.reduce(_queue, command);
    _queue = transition.state;
    final effect = transition.effect;
    if (previous != null &&
        (_queue.current?.queueItemId != previous ||
            effect == QueueEffect.stop ||
            effect == QueueEffect.loadCurrent ||
            (effect == QueueEffect.restartCurrent && command is! Previous))) {
      _ended.add(EntryEnded(previous, natural: command is ItemFinished));
    }
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
    _cancelRetry();
    _clearNextSlot();
    _currentSource = null;
    await _engine.stop();
  }

  /// Resolves the queue's current item and loads it; the engine's next slot
  /// is empty afterwards. A [retry] loads the same item again and keeps its
  /// used retries and its quality info.
  Future<void> _loadCurrent({bool retry = false}) async {
    final item = _queue.current;
    _clearNextSlot();
    _currentSource = null;
    _error = null;
    if (!retry) _onItemChanged(item);
    if (item == null) return;
    final startAt = _pendingStartAt;
    _pendingStartAt = Duration.zero;
    _lastPosition = startAt;
    final EngineSource source;
    try {
      source = await _resolver.resolve(item, startAt: startAt);
    } on NotPlayable {
      await _onCurrentItemFailed(_failures.onNotPlayable(), item);
      return;
    } on Object catch (error, stackTrace) {
      _log.warning(
        'Resolving the current item failed',
        const {},
        error,
        stackTrace,
      );
      await _onCurrentItemFailed(_failures.onResolveError(), item);
      return;
    }
    _currentSource = source;
    _failureHandled = false;
    _fetchQuality(item, source);
    _publish();
    await _engine.load(source, autoPlay: _playIntent);
  }

  /// A different item (or none) is current: its retries are unused, a
  /// waiting retry of the previous one is cancelled, and the quality info
  /// of another entry is dropped.
  void _onItemChanged(QueueItem? item) {
    _cancelRetry();
    _failures.onNewItem();
    if (item?.queueItemId != _qualityOf) {
      _qualityOf = null;
      _quality = null;
    }
  }

  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _generation++;
  }

  /// Fetches the stream info of [item] once while it is current, when it
  /// is a streamed track (doc 06, Quality badge).
  void _fetchQuality(QueueItem item, EngineSource source) {
    if (_qualityOf == item.queueItemId) return;
    if (item is! TrackQueueItem || source.uri.isScheme('file')) return;
    final playbackId = item.track.playbackId;
    if (playbackId == null) return;
    _qualityOf = item.queueItemId;
    unawaited(_loadQuality(item.queueItemId, playbackId, source.streamQuality));
  }

  Future<void> _loadQuality(
    String queueItemId,
    PlaybackId playbackId,
    String? quality,
  ) async {
    final StreamQualityInfo info;
    try {
      info = await _info.streamInfo(playbackId, quality: quality);
    } on Object catch (error, stackTrace) {
      _log.warning('Fetching stream info failed', const {}, error, stackTrace);
      return;
    }
    if (_disposed || _qualityOf != queueItemId) return;
    _quality = info;
    _publish();
  }

  /// Carries out [decision] about a failure of the current [item].
  Future<void> _onCurrentItemFailed(
    FailureDecision decision,
    QueueItem item,
  ) async {
    final id = item.queueItemId;
    switch (decision) {
      case RetryAfter(:final delay):
        final generation = _generation;
        final position = _lastPosition;
        _publish();
        _retryTimer = _createTimer(delay, () {
          _retryTimer = null;
          unawaited(
            _enqueue(() async {
              if (generation != _generation || _queue.current != item) return;
              await _reload(position);
            }),
          );
        });
      case RefreshAndRetry():
        final position = _lastPosition;
        try {
          await _session.refreshNow();
        } on Object catch (error) {
          _log.info('Renewing the credential failed', {'error': '$error'});
          await _onCurrentItemFailed(_failures.onRefreshFailed(), item);
          return;
        }
        if (_queue.current != item) return;
        await _reload(position);
      case SkipItem(:final kind):
        _error = PlaybackError(kind, queueItemId: id);
        _notices.add(ItemSkipped(id, kind));
        _publish();
        await _skipFailed();
      case StopPlayback(:final kind):
        _endCurrent();
        await _stopEngine();
        _error = PlaybackError(kind, queueItemId: id);
        _notices.add(PlaybackStopped(kind));
        _publish();
    }
  }

  /// Loads the current item again at [position], keeping the play intent.
  Future<void> _reload(Duration position) async {
    _pendingStartAt = position;
    await _loadCurrent(retry: true);
    _publish();
    _syncNext();
  }

  /// Advances past a failed item as `Next` would; at the end of the queue
  /// with nothing to wrap to, stops and keeps the item's error.
  Future<void> _skipFailed() async {
    _endCurrent();
    final transition = _reducer.reduce(_queue, const Next());
    if (transition.effect != QueueEffect.loadCurrent) {
      final error = _error;
      await _stopEngine();
      _error = error;
      _publish();
      return;
    }
    _queue = transition.state;
    await _loadCurrent();
    _publish();
    _syncNext();
  }

  Future<void> _onEngineEvent(EngineEvent event) async {
    switch (event) {
      case AdvancedToNext(:final queueItemId):
        await _onAdvanced(queueItemId);
      case Completed(:final queueItemId):
        await _reduce(ItemFinished(queueItemId));
      case Failed(:final queueItemId, :final error):
        await _onFailed(queueItemId, error);
    }
  }

  Future<void> _onAdvanced(String queueItemId) async {
    final finished = _queue.current?.queueItemId;
    final preloaded = _nextSource;
    _clearNextSlot();
    if (finished != null) {
      _ended.add(EntryEnded(finished, natural: true));
      final transition = _reducer.reduce(_queue, ItemFinished(finished));
      _queue = transition.state;
      if (_queue.current?.queueItemId == queueItemId) {
        _onItemChanged(_queue.current);
        _currentSource = preloaded;
        _failureHandled = false;
        _lastPosition = Duration.zero;
        if (preloaded != null) _fetchQuality(_queue.current!, preloaded);
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

  Future<void> _onFailed(String queueItemId, EngineError error) async {
    final current = _queue.current;
    final isCurrent =
        current?.queueItemId == queueItemId &&
        _currentSource != null &&
        (_nextId != queueItemId || _engineState.status == EngineStatus.error);
    if (isCurrent) {
      if (_failureHandled) return;
      _failureHandled = true;
      await _onCurrentItemFailed(_failures.onEngineError(error), current!);
    } else if (_nextId == queueItemId) {
      _nextSource = null;
      _nextSync = _engine.setNext(null);
    }
  }

  /// Emits [EntryEnded] for the current entry, if there is one.
  void _endCurrent() {
    final current = _queue.current;
    if (current != null) {
      _ended.add(EntryEnded(current.queueItemId, natural: false));
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

  /// Reads the stored user volume; 1.0 when none is stored or it does not
  /// parse.
  Future<void> _restoreVolume() async {
    final Object? stored;
    try {
      stored = await _deviceSettings?.read(playbackVolumeKey);
    } on Object catch (error, stackTrace) {
      _log.warning('Reading the volume failed', const {}, error, stackTrace);
      return;
    }
    final volume = switch (stored) {
      final String text => double.tryParse(text),
      final num value => value.toDouble(),
      _ => null,
    };
    if (volume == null || volume.isNaN) return;
    _userVolume = volume.clamp(0.0, 1.0);
    await _applyVolume();
  }

  Future<void> _storeVolume() async {
    try {
      await _deviceSettings?.write(playbackVolumeKey, '$_userVolume');
    } on Object catch (error, stackTrace) {
      _log.warning('Storing the volume failed', const {}, error, stackTrace);
    }
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
    final id = state.currentQueueItemId;
    if (id != null && id == _queue.current?.queueItemId) {
      switch (state.status) {
        case EngineStatus.ready || EngineStatus.buffering:
          _lastPosition = state.position;
          if (state.status == EngineStatus.ready && state.playing) {
            _failures.resetCount();
          }
        case EngineStatus.idle ||
            EngineStatus.loading ||
            EngineStatus.ended ||
            EngineStatus.error:
          break;
      }
    }
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
        // A restored item waits, unloaded, at its stored position.
        position: _currentSource == null && _pendingStartAt > Duration.zero
            ? _pendingStartAt
            : state.position,
        buffered: state.bufferedPosition,
        duration: state.duration,
        quality: _quality,
        error: _error,
        isLocalFile: _currentSource?.uri.isScheme('file') ?? false,
      ),
    );
  }
}
