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
import 'package:soundspan/core/playback/podcast_settings.dart';
import 'package:soundspan/core/playback/queue/queue_command.dart';
import 'package:soundspan/core/playback/queue/queue_reducer.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/core/playback/remote_playback.dart';
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
/// A downloaded file is played whenever one exists. While the server is
/// out of reach, items without one are skipped; when no item of the queue
/// can play, playback stops with [PlaybackErrorKind.notAvailableOffline]
/// and the cursor goes back to where the skipping started. A downloaded
/// file the engine cannot open is queued to be downloaded again and the
/// item is resolved once more at the same position.
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
    if (_deviceSettings != null) {
      unawaited(_enqueue(_restoreVolume));
      unawaited(_enqueue(_readSkipInterval));
    }
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

  /// The downloaded file the current source plays; null for a stream.
  LocalDownload? _currentLocal;
  bool _disposed = false;

  /// The entry that last resolved to a source since the user last chose
  /// what to play; where the cursor returns when nothing after it can be
  /// played offline.
  String? _lastPlayable;

  /// Where the cursor returns when the run of items that cannot be played
  /// offline ends without a playable one.
  String? _offlineOrigin;

  /// The id of the entry last handed to the engine as next; null when the
  /// slot is empty.
  String? _nextId;
  EngineSource? _nextSource;
  LocalDownload? _nextLocal;
  int _nextRequest = 0;
  Future<void> _nextSync = Future<void>.value();

  /// Where the current item starts when it is loaded lazily by [play].
  Duration _pendingStartAt = Duration.zero;

  /// The speed last given to the engine; the engine starts at 1.0.
  double _speed = 1;

  /// The skip interval of episodes, as last read from the device settings.
  Duration _skipInterval = defaultEpisodeSkipInterval;

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
  bool _remoteCanControl = true;

  /// The shuffle and repeat of the queue when the driver was attached,
  /// restored on detach.
  bool _shuffleBeforeRemote = false;
  RepeatMode _repeatBeforeRemote = RepeatMode.off;

  late final RemotePlayback _remote = _ControllerRemotePlayback(this);

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
  /// [detachRemoteDriver]; `setVolume` stays local. Shuffle and repeat are
  /// turned off while it is attached. Throws [StateError] when a driver is
  /// attached already.
  void attachRemoteDriver(RemoteDriver driver) {
    if (_driver != null) {
      throw StateError('A RemoteDriver is attached already');
    }
    _driver = driver;
    _remoteCanControl = true;
    unawaited(_enqueue(_suspendShuffleAndRepeat));
  }

  /// Applies commands locally again and restores the shuffle and repeat the
  /// queue had when the driver was attached.
  void detachRemoteDriver() {
    if (_driver == null) return;
    _driver = null;
    _remoteCanControl = true;
    unawaited(_enqueue(_resumeShuffleAndRepeat));
  }

  /// How the attached driver applies the state it receives, bypassing the
  /// routing of commands. Throws [StateError] when no driver is attached.
  RemotePlayback get remote {
    if (_driver == null) throw StateError('No RemoteDriver is attached');
    return _remote;
  }

  /// Sets whether this device may control playback while a driver is
  /// attached, published as [PlaybackSnapshot.remoteCanControl]; detaching
  /// resets it to true.
  void setRemoteCanControl(bool value) {
    if (_remoteCanControl == value) return;
    _remoteCanControl = value;
    _publish();
  }

  /// Replaces the queue with [queue], paused at [position] and unloaded, as
  /// [restore] does: the first [play] loads the current item there. Never
  /// handed to a driver; Listen Together restores the user's own queue with
  /// it after leaving a group.
  Future<void> restoreQueue(QueueState queue, {required Duration position}) =>
      _enqueue(() async {
        _endCurrent();
        await _stopEngine();
        _queue = queue.copyWith(
          revision:
              (queue.revision > _queue.revision
                  ? queue.revision
                  : _queue.revision) +
              1,
        );
        _error = null;
        _onItemChanged(_queue.current);
        _pendingStartAt = _queue.current == null ? Duration.zero : position;
        _publish();
      });

  Future<void> _suspendShuffleAndRepeat() async {
    _shuffleBeforeRemote = _queue.isShuffled;
    _repeatBeforeRemote = _queue.repeat;
    if (_shuffleBeforeRemote) {
      _queue = _reducer.reduce(_queue, const SetShuffle(false)).state;
    }
    if (_repeatBeforeRemote != RepeatMode.off) {
      _queue = _reducer.reduce(_queue, const SetRepeat(RepeatMode.off)).state;
    }
    _publish();
    _syncNext();
  }

  Future<void> _resumeShuffleAndRepeat() async {
    if (_shuffleBeforeRemote) {
      _queue = _reducer.reduce(_queue, const SetShuffle(true)).state;
    }
    if (_repeatBeforeRemote != RepeatMode.off) {
      _queue = _reducer.reduce(_queue, SetRepeat(_repeatBeforeRemote)).state;
    }
    _shuffleBeforeRemote = false;
    _repeatBeforeRemote = RepeatMode.off;
    _publish();
    _syncNext();
  }

  Future<void> _remoteReplaceQueue(List<QueueItem> items, int cursor) async {
    final previous = _queue.current?.queueItemId;
    final transition = _reducer.reduce(
      QueueState(revision: _queue.revision),
      ReplaceAll(items, startIndex: cursor),
    );
    _queue = transition.state;
    if (transition.dropped > 0) _notices.add(ItemsDropped(transition.dropped));
    final current = _queue.current?.queueItemId;
    if (current != null && current == previous && _currentSource != null) {
      _publish();
      _syncNext();
      return;
    }
    if (previous != null) _ended.add(EntryEnded(previous, natural: false));
    await _stopEngine();
    _onItemChanged(_queue.current);
    _pendingStartAt = Duration.zero;
    _publish();
  }

  Future<void> _remoteLoadCurrent(Duration position, bool play) async {
    _playIntent = play;
    if (_queue.current == null) {
      _publish();
      return;
    }
    _pendingStartAt = position;
    await _loadCurrent();
    _publish();
    _syncNext();
  }

  Future<void> _remotePause() async {
    _playIntent = false;
    _publish();
    await _engine.pause();
  }

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

  /// Completes once every step queued before it, [restore] included, is
  /// done.
  Future<void> get settled => _enqueue(() async {});

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

  /// Sets the engine speed to [speed] (clamped to 0.5–3.0) when the
  /// current entry is an episode; with a track or nothing current the
  /// engine is not touched (doc 06, Podcasts). With [remember] the speed
  /// is also stored as the episode speed, `playback.speed.podcast`, which
  /// every episode that becomes current plays at.
  Future<void> setEpisodeSpeed(double speed, {bool remember = false}) =>
      _enqueue(() async {
        final clamped = speed.clamp(0.5, 3.0);
        if (remember) {
          try {
            await _deviceSettings?.write(podcastSpeedKey, clamped);
          } on Object catch (error, stackTrace) {
            _log.warning(
              'Storing the episode speed failed',
              const {},
              error,
              stackTrace,
            );
          }
        }
        if (_queue.current is EpisodeQueueItem) await _setSpeed(clamped);
      });

  /// Moves forward in the current item by the episode skip interval
  /// (`playback.skipSeconds`, default 15 s), clamped to its duration.
  Future<void> skipForward() => _skipBy(forward: true);

  /// Moves back in the current item by the episode skip interval, clamped
  /// to its start.
  Future<void> skipBackward() => _skipBy(forward: false);

  /// The episode skip interval as last read from the device settings.
  Duration get skipInterval => _skipInterval;

  Future<void> _skipBy({required bool forward}) async {
    await _readSkipInterval();
    final snapshot = this.snapshot;
    final current = snapshot.current;
    if (current == null) return;
    var target = forward
        ? snapshot.position + _skipInterval
        : snapshot.position - _skipInterval;
    final duration = snapshot.duration ?? _knownDuration(current);
    if (duration != null && target > duration) target = duration;
    if (target < Duration.zero) target = Duration.zero;
    await seek(target);
  }

  static Duration? _knownDuration(QueueItem item) {
    final seconds = switch (item) {
      TrackQueueItem(:final track) => track.meta.durationSec,
      EpisodeQueueItem(:final episode) => episode.durationSec,
    };
    return seconds == null || seconds <= 0 ? null : Duration(seconds: seconds);
  }

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
        _onUserChoice();
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
        _onUserChoice();
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

  /// The user chose what to play: failure runs start over.
  void _onUserChoice() {
    _failures.resetCount();
    _lastPlayable = null;
    _offlineOrigin = null;
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
    _currentLocal = null;
    await _engine.stop();
  }

  /// Resolves the queue's current item and loads it; the engine's next slot
  /// is empty afterwards. A [retry] loads the same item again and keeps its
  /// used retries and its quality info.
  Future<void> _loadCurrent({bool retry = false}) async {
    final item = _queue.current;
    _clearNextSlot();
    _currentSource = null;
    _currentLocal = null;
    _error = null;
    if (!retry) _onItemChanged(item);
    if (item == null) return;
    final startAt = !retry && _pendingStartAt == Duration.zero
        ? _resumePosition(item)
        : _pendingStartAt;
    _pendingStartAt = Duration.zero;
    _lastPosition = startAt;
    final ResolvedSource resolved;
    try {
      resolved = await _resolver.resolveSource(item, startAt: startAt);
    } on NotAvailableOffline {
      _offlineOrigin ??= _lastPlayable ?? item.queueItemId;
      await _onCurrentItemFailed(
        _failures.onNotAvailableOffline(_queue.playOrder.length),
        item,
      );
      return;
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
    final source = resolved.source;
    _currentSource = source;
    _currentLocal = resolved.download;
    _onPlayable(item);
    _failureHandled = false;
    _fetchQuality(item, resolved);
    _publish();
    await _engine.load(source, autoPlay: _playIntent);
    if (!retry) await _markPlayed(resolved.download);
    await _applySpeedFor(item);
  }

  /// [item] resolved to a source: a run of items that cannot be played
  /// offline is over.
  void _onPlayable(QueueItem item) {
    _failures.onPlayable();
    _lastPlayable = item.queueItemId;
    _offlineOrigin = null;
  }

  /// Records that the downloaded file [download] started playing.
  Future<void> _markPlayed(LocalDownload? download) async {
    if (download == null) return;
    try {
      await _resolver.markPlayed(download);
    } on Object catch (error, stackTrace) {
      _log.warning(
        'Recording the play of a download failed',
        const {},
        error,
        stackTrace,
      );
    }
  }

  /// Where [item] starts when nothing else says: an episode at its saved
  /// progress, anything else at zero.
  static Duration _resumePosition(QueueItem item) => switch (item) {
    EpisodeQueueItem(:final episode) => episodeResumePosition(episode),
    TrackQueueItem() => Duration.zero,
  };

  /// Gives the engine the speed of [item]: the stored episode speed for
  /// an episode, 1.0 for anything else.
  Future<void> _applySpeedFor(QueueItem? item) async {
    if (item is EpisodeQueueItem) {
      await _setSpeed(await _readEpisodeSpeed());
    } else {
      await _setSpeed(1);
    }
  }

  Future<void> _setSpeed(double speed) async {
    if (speed == _speed || _disposed) return;
    _speed = speed;
    await _engine.setSpeed(speed);
    _publish();
  }

  Future<double> _readEpisodeSpeed() async {
    try {
      return episodeSpeedOf(await _deviceSettings?.read(podcastSpeedKey));
    } on Object catch (error, stackTrace) {
      _log.warning(
        'Reading the episode speed failed',
        const {},
        error,
        stackTrace,
      );
      return defaultEpisodeSpeed;
    }
  }

  Future<void> _readSkipInterval() async {
    final settings = _deviceSettings;
    if (settings == null) return;
    final Duration interval;
    try {
      interval = episodeSkipIntervalOf(await settings.read(skipSecondsKey));
    } on Object catch (error, stackTrace) {
      _log.warning(
        'Reading the skip interval failed',
        const {},
        error,
        stackTrace,
      );
      return;
    }
    if (interval == _skipInterval || _disposed) return;
    _skipInterval = interval;
    _publish();
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
  /// is a streamed track; a downloaded file shows the quality it was
  /// downloaded at instead (doc 06, Quality badge).
  void _fetchQuality(QueueItem item, ResolvedSource resolved) {
    if (resolved.download case final download?) {
      _qualityOf = item.queueItemId;
      _quality = StreamQualityInfo.downloaded(quality: download.quality);
      return;
    }
    if (_qualityOf == item.queueItemId) return;
    if (item is! TrackQueueItem) return;
    final source = resolved.source;
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
      case SkipUnavailableOffline():
        _error = PlaybackError(
          PlaybackErrorKind.notAvailableOffline,
          queueItemId: id,
        );
        _publish();
        await _skipFailed();
      case StopPlayback(:final kind):
        _endCurrent();
        await _stopEngine();
        _error = PlaybackError(kind, queueItemId: id);
        if (kind == PlaybackErrorKind.notAvailableOffline) {
          _returnToOfflineOrigin();
        }
        _notices.add(PlaybackStopped(kind));
        _publish();
    }
  }

  /// Ends a run of items that cannot be played offline with nothing
  /// playable found: the cursor goes back to where the run started (the
  /// last item that played, or the one the user chose).
  void _returnToOfflineOrigin() {
    final origin = _offlineOrigin;
    _offlineOrigin = null;
    _error = const PlaybackError(PlaybackErrorKind.notAvailableOffline);
    if (origin == null || origin == _queue.current?.queueItemId) return;
    if (!_queue.items.any((item) => item.queueItemId == origin)) return;
    _queue = _reducer.reduce(_queue, JumpTo(origin)).state;
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
      if (error?.kind == PlaybackErrorKind.notAvailableOffline) {
        _returnToOfflineOrigin();
      }
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
    final preloadedLocal = _nextLocal;
    _clearNextSlot();
    if (finished != null) {
      _ended.add(EntryEnded(finished, natural: true));
      final transition = _reducer.reduce(_queue, ItemFinished(finished));
      _queue = transition.state;
      if (_queue.current?.queueItemId == queueItemId) {
        _onItemChanged(_queue.current);
        _currentSource = preloaded;
        _currentLocal = preloaded == null ? null : preloadedLocal;
        _failureHandled = false;
        _lastPosition = Duration.zero;
        if (preloaded != null) {
          _onPlayable(_queue.current!);
          _fetchQuality(
            _queue.current!,
            ResolvedSource(preloaded, download: preloadedLocal),
          );
          await _markPlayed(_currentLocal);
        }
        await _applySpeedFor(_queue.current);
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
      final local = _currentLocal;
      if (local != null &&
          (error.kind == EngineErrorKind.decode ||
              error.kind == EngineErrorKind.notFound)) {
        await _onLocalFileFailed(local);
        return;
      }
      await _onCurrentItemFailed(_failures.onEngineError(error), current!);
    } else if (_nextId == queueItemId) {
      _nextSource = null;
      _nextLocal = null;
      _nextSync = _engine.setNext(null);
    }
  }

  /// The engine cannot open the current item's downloaded file [download]:
  /// the download is queued again and the item resolved once more at the
  /// same position, streamed when the server can be reached and skipped by
  /// the offline rule when it cannot.
  Future<void> _onLocalFileFailed(LocalDownload download) async {
    try {
      await _resolver.markMissing(download);
    } on Object catch (error, stackTrace) {
      _log.warning(
        'Queuing a missing download again failed',
        const {},
        error,
        stackTrace,
      );
    }
    _qualityOf = null;
    _quality = null;
    await _reload(_lastPosition);
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
    _nextLocal = null;
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
    ResolvedSource? resolved;
    try {
      resolved = await _resolver.resolveSource(item);
    } on Object catch (error) {
      // NotAvailableOffline included: the item is skipped when its turn
      // comes.
      _log.fine('The next item cannot be resolved', {'error': '$error'});
    }
    if (request != _nextRequest || _disposed) return;
    _nextSource = resolved?.source;
    _nextLocal = resolved?.download;
    await _engine.setNext(resolved?.source);
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
        isLocalFile: _currentLocal != null,
        speed: _speed,
        skipInterval: _skipInterval,
        remoteAttached: _driver != null,
        remoteCanControl: _driver == null || _remoteCanControl,
      ),
    );
  }
}

/// The [RemotePlayback] of one [PlaybackController]: each call is a step of
/// the controller's queue.
final class _ControllerRemotePlayback implements RemotePlayback {
  new(this._controller);

  final PlaybackController _controller;

  @override
  Future<void> replaceQueue(List<QueueItem> items, int cursor) => _controller
      ._enqueue(() => _controller._remoteReplaceQueue(items, cursor));

  @override
  Future<void> loadCurrent({required Duration position, required bool play}) =>
      _controller._enqueue(
        () => _controller._remoteLoadCurrent(position, play),
      );

  @override
  Future<void> play() => _controller._enqueue(_controller._play);

  @override
  Future<void> pause() => _controller._enqueue(_controller._remotePause);

  @override
  Future<void> seek(Duration position) =>
      _controller._enqueue(() => _controller._engine.seek(position));
}
