// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:soundspan/core/playback/engines/media_kit_mapping.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';

/// The [PlayerEngine] of Windows and Linux, over one `media_kit` [Player]
/// backed by libmpv (doc 06, `MediaKitEngine`).
///
/// The player's playlist holds the current source at index 0 and, when set,
/// the next one at index 1. When mpv moves onto the next source by itself
/// the engine reports [AdvancedToNext] and removes the played item, so the
/// new current source is index 0 again.
final class MediaKitEngine implements PlayerEngine {
  /// Creates an engine with its own player.
  ///
  /// `statusOf` is asked for the HTTP status of a stream source that failed
  /// when mpv's log did not carry it (a 401 is never logged).
  ///
  /// [audioOutputOverride] sets mpv's `ao`; null keeps mpv's default. The
  /// engine factory passes `'pulse,pipewire,alsa'` on Linux, where tearing
  /// down mpv's PipeWire output can stall mpv's core for 20 s or more. The
  /// device-test harness passes `'null'` on Windows, whose hosted runner has
  /// no audio endpoint, and `'pulse'` on Linux (doc 06).
  ///
  /// [player] replaces the libmpv player in unit tests.
  new({
    required this._statusOf,
    this.audioOutputOverride,
    @visibleForTesting Player? player,
  }) : _player =
           player ??
           Player(
             // ffmpeg logs `HTTP error <status>` at level warn, so the
             // player listens from that level up.
             configuration: const PlayerConfiguration(
               title: 'soundspan',
               logLevel: MPVLogLevel.warn,
             ),
           ) {
    _subscriptions.addAll([
      _player.stream.playlist.listen(_onPlaylist),
      _player.stream.completed.listen(_onCompleted),
      _player.stream.position.listen(_onPosition),
      _player.stream.duration.listen((_) => _onLoadProgress()),
      _player.stream.buffer.listen((_) => _reportAtPlayerPosition()),
      _player.stream.buffering.listen((_) => _reportAtPlayerPosition()),
      _player.stream.log.listen(_onLog),
      _player.stream.error.listen(_onError),
    ]);
    _configured = _configure();
  }

  /// Loads libmpv. Called once by the engine factory, on Windows and Linux
  /// only, before the first engine is created.
  static void ensureInitialized() {
    if (_initialized) return;
    MediaKit.ensureInitialized();
    _initialized = true;
  }

  static bool _initialized = false;

  /// mpv properties set once on every player (doc 06, `MediaKitEngine`).
  static const Map<String, String> _properties = {
    'vid': 'no',
    'gapless-audio': 'yes',
    'prefetch-playlist': 'yes',
    'audio-client-name': 'soundspan',
    'cache': 'yes',
    'demuxer-max-bytes': '64MiB',
    'network-timeout': '30',
    'volume-max': '100',
  };

  /// How long [load] waits for mpv to open the current source before it
  /// reports the source [Failed] with a network error; longer than mpv's
  /// `network-timeout`, so mpv's own error comes first when it reports one.
  static const Duration loadTimeLimit = Duration(seconds: 45);

  /// How long one player call may take before the caller gets a
  /// [TimeoutException] and the next player call runs.
  static const Duration callTimeLimit = Duration(seconds: 45);

  /// How long a change that carries no position (buffering, buffered
  /// position, duration) waits for the next position update while the
  /// clock runs before it is reported at the last position.
  static const Duration positionWait = Duration(milliseconds: 150);

  /// How long a load waits for mpv to report the position of a resume
  /// point before it reports the source ready anyway.
  static const Duration _startAtWait = Duration(seconds: 2);

  /// How long [dispose] waits for a pending player call and for the
  /// player's own dispose.
  static const Duration _disposeWait = Duration(seconds: 5);

  /// How often [dispose] checks whether mpv is idle.
  static const Duration _idlePoll = Duration(milliseconds: 20);

  /// How soon a held state is checked again after a transition.
  static const Duration _recheckDelay = Duration(milliseconds: 10);

  final StreamStatusOf _statusOf;

  /// mpv's `ao` when set; null keeps mpv's default audio output.
  final String? audioOutputOverride;

  final Player _player;

  final StreamController<EngineState> _states =
      StreamController<EngineState>.broadcast();
  final StreamController<EngineEvent> _events =
      StreamController<EngineEvent>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  late final Future<void> _configured;

  EngineSource? _current;
  EngineSource? _next;
  EngineError? _error;
  bool _loading = false;
  bool _ended = false;
  bool _playIntent = false;

  /// The position mpv's clock is expected to move on from after playback
  /// started, resumed or seeked; null once it moved. Until then the status
  /// is [EngineStatus.buffering]: the audio output may take a while to
  /// start consuming (a PulseAudio sink can take two seconds).
  Duration? _clockFrom;
  Duration _position = Duration.zero;
  Stopwatch? _sinceAdvance;
  Timer? _recheck;

  /// Reports a change that carries no position if no position update
  /// carries it first.
  Timer? _pendingChange;
  EngineState _latest = EngineState.idle;
  bool _disposed = false;

  /// Completes when the source of the running load is ready or failed.
  Completer<void>? _settled;

  /// The status of the last `HTTP error` line mpv logged, paired with the
  /// next failure.
  int? _loggedStatus;

  /// The last failure message that named neither source after the current
  /// source loaded (ffmpeg's connection error, logged before mpv's message
  /// naming the address); it is classified with the next named failure.
  String? _unattributed;

  /// Bumped by [load] and [stop]; a failure of an older source is ignored.
  int _generation = 0;

  /// Whether the current source's failure was already handled in this
  /// generation.
  bool _currentFailed = false;

  /// Player calls that change the playlist run one after another.
  Future<void> _serial = Future<void>.value();

  @override
  Stream<EngineState> get state => Stream<EngineState>.multi((listener) {
    if (_disposed) {
      unawaited(listener.close());
      return;
    }
    listener.add(_latest);
    final subscription = _states.stream.listen(
      listener.add,
      onDone: listener.close,
    );
    listener.onCancel = subscription.cancel;
  });

  @override
  Stream<EngineEvent> get events => _events.stream;

  @override
  Future<void> load(
    EngineSource current, {
    EngineSource? next,
    bool autoPlay = true,
  }) async {
    _checkNotDisposed();
    final generation = ++_generation;
    _current = current;
    _next = next;
    _error = null;
    _currentFailed = false;
    _ended = false;
    _loading = true;
    _playIntent = autoPlay;
    _position = current.startAt;
    _sinceAdvance = null;
    _loggedStatus = null;
    _unattributed = null;
    _settle();
    final settled = _settled = Completer<void>();
    _report();
    final started = Stopwatch()..start();
    try {
      await _run(() async {
        if (generation != _generation) return;
        await _player.open(
          Playlist([_media(current), if (next != null) _media(next)]),
          play: autoPlay,
        );
      });
      await settled.future.timeout(loadTimeLimit - started.elapsed);
    } on TimeoutException {
      if (generation == _generation && !_disposed && _loading) {
        _failLoad(current);
      }
      return;
    }
    if (generation != _generation || _error != null) return;
    if (current.startAt > Duration.zero) await _awaitStartAt(current.startAt);
    if (generation != _generation || _error != null) return;
    _loading = false;
    if (_playIntent) _clockFrom = _position;
    _report();
  }

  /// Waits until mpv reports a position at or past [startAt], for at most
  /// [_startAtWait].
  Future<void> _awaitStartAt(Duration startAt) async {
    final margin = startAt - const Duration(milliseconds: 50);
    if (_player.state.position >= margin) return;
    await _player.stream.position
        .firstWhere((p) => p >= margin)
        .timeout(_startAtWait, onTimeout: () => startAt)
        .catchError((Object _) => startAt);
  }

  @override
  Future<void> setNext(EngineSource? next) async {
    _checkNotDisposed();
    _next = next;
    if (_current == null || _error != null) return;
    final generation = _generation;
    await _run(() async {
      if (generation != _generation || _next != next) return;
      final playlist = _player.state.playlist;
      final at = playlist.index < 0 ? 0 : playlist.index;
      for (var i = playlist.medias.length - 1; i > at; i--) {
        await _player.remove(i);
      }
      if (next != null) await _player.add(_media(next));
    });
  }

  @override
  Future<void> play() async {
    _checkNotDisposed();
    if (_current == null || _error != null) return;
    if (!_playIntent) _clockFrom = _position;
    _playIntent = true;
    _report();
    await _run(_player.play);
  }

  /// Pauses and reports not playing once mpv has paused, at the last
  /// position mpv reported then: a position update already on its way when
  /// the pause was asked for would otherwise move a paused position.
  @override
  Future<void> pause() async {
    _checkNotDisposed();
    final generation = _generation;
    await _run(() async {
      await _player.pause();
      if (generation != _generation || !_live || _sinceAdvance != null) {
        return;
      }
      _position =
          mediaKitPosition(
            raw: _player.state.position,
            duration: _duration,
            ended: _ended,
          ) ??
          _position;
    });
    _playIntent = false;
    _clockFrom = null;
    _report();
  }

  @override
  Future<void> seek(Duration position) async {
    _checkNotDisposed();
    if (_current == null || _error != null) return;
    final duration = _duration;
    var target = position < Duration.zero ? Duration.zero : position;
    if (duration != null && target > duration) target = duration;
    _ended = false;
    _sinceAdvance = null;
    await _run(() => _player.seek(target));
    if (_playIntent) _clockFrom = target;
    _report();
  }

  @override
  Future<void> stop() async {
    _checkNotDisposed();
    _generation++;
    _current = null;
    _next = null;
    _error = null;
    _currentFailed = false;
    _unattributed = null;
    _loading = false;
    _ended = false;
    _playIntent = false;
    _clockFrom = null;
    _position = Duration.zero;
    _sinceAdvance = null;
    _pendingChange?.cancel();
    _pendingChange = null;
    _settle();
    _report();
    await _run(_player.stop);
  }

  @override
  Future<void> setVolume(double linear) async {
    _checkNotDisposed();
    await _run(() => _player.setVolume(mpvVolume(linear)));
  }

  @override
  Future<void> setSpeed(double speed) async {
    _checkNotDisposed();
    await _run(() => _player.setRate(speed.clamp(0.5, 3.0)));
  }

  @override
  Future<void> dispose() async {
    _checkNotDisposed();
    _disposed = true;
    _generation++;
    _settle();
    _recheck?.cancel();
    _pendingChange?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _states.close();
    await _events.close();
    // A player call that never returns must not keep the engine alive.
    await _serial.timeout(_disposeWait, onTimeout: () {});
    await _stopUntilIdle();
    await _player.dispose().timeout(_disposeWait, onTimeout: () {});
  }

  /// Stops mpv and waits, at most [_disposeWait], until it reports itself
  /// idle.
  ///
  /// media_kit's dispose calls `mpv_terminate_destroy` synchronously on this
  /// isolate a few seconds later. If mpv were still unloading a file then,
  /// it would wait for media_kit's `on_unload` hook, which only this
  /// (blocked) isolate can answer, and the app would hang.
  Future<void> _stopUntilIdle() async {
    final native = _player.platform;
    if (native is! NativePlayer) return;
    try {
      await _player.stop().timeout(_disposeWait);
      final deadline = Stopwatch()..start();
      while (deadline.elapsed < _disposeWait) {
        if (await native.getProperty('idle-active') == 'yes') return;
        await Future<void>.delayed(_idlePoll);
      }
    } on Object {
      // Disposing goes ahead; the wait only makes it safer.
    }
  }

  void _checkNotDisposed() {
    if (_disposed) throw StateError('MediaKitEngine used after dispose');
  }

  Future<void> _configure() async {
    final native = _player.platform;
    if (native is! NativePlayer) return;
    for (final MapEntry(:key, :value) in _properties.entries) {
      await native.setProperty(key, value);
    }
    final ao = audioOutputOverride;
    if (ao != null) await native.setProperty('ao', ao);
  }

  /// Runs [action] after every player call before it. A call that has not
  /// returned after [callTimeLimit] fails with a [TimeoutException], and the
  /// next call runs: one libmpv call that never returns must not hold up
  /// every later one.
  Future<void> _run(Future<void> Function() action) {
    final result = _serial.then((_) async {
      if (_disposed) return;
      await _configured;
      await action().timeout(callTimeLimit);
    });
    _serial = result.catchError((Object _) {});
    return result;
  }

  /// [_run] for a call nobody awaits; its failure is dropped.
  void _runDetached(Future<void> Function() action) =>
      unawaited(_run(action).catchError((Object _) {}));

  void _settle() {
    final settled = _settled;
    _settled = null;
    if (settled != null && !settled.isCompleted) settled.complete();
  }

  static String _location(EngineSource source) =>
      source.uri.isScheme('file') ? source.uri.toFilePath() : '${source.uri}';

  static Media _media(EngineSource source) => Media(
    _location(source),
    httpHeaders: source.headers.isEmpty ? null : source.headers,
    start: source.startAt > Duration.zero ? source.startAt : null,
  );

  Duration? get _duration {
    final duration = _player.state.duration;
    return duration > Duration.zero ? duration : null;
  }

  void _onLoadProgress() {
    if (_loading && _duration != null) _settle();
    _reportAtPlayerPosition();
  }

  /// Reports a change that carries no position (buffering, buffered
  /// position, duration).
  ///
  /// While the clock runs, the last reported position is already behind:
  /// emitting it with the change would stamp an old position with a later
  /// time. The change goes out with the next position update instead, or,
  /// when none comes within [positionWait] (mpv stalled), at the last
  /// position, which is where mpv stopped (doc 06). mpv's `time-pos` is
  /// never read here: libmpv answers a read synchronously on the app's
  /// isolate, and while mpv's core is busy that freezes the app.
  void _reportAtPlayerPosition() {
    if (!_live || !_playIntent || _ended) {
      _report();
      return;
    }
    _pendingChange ??= Timer(positionWait, () {
      _pendingChange = null;
      _report();
    });
  }

  /// Whether player updates are about a source the engine still plays.
  bool get _live =>
      !_disposed &&
      _current != null &&
      !_loading &&
      _error == null &&
      !_currentFailed;

  void _onPlaylist(Playlist playlist) {
    if (!_live) return;
    final event = mediaKitSlotEvent(
      index: playlist.index,
      completed: false,
      currentId: _current?.queueItemId,
      nextId: _next?.queueItemId,
      completedReported: _ended,
    );
    if (event is! AdvancedToNext) return;
    _current = _next;
    _next = null;
    _sinceAdvance = Stopwatch()..start();
    _clockFrom = null;
    _events.add(event);
    final generation = _generation;
    _runDetached(() async {
      if (generation != _generation) return;
      if (_player.state.playlist.index > 0) await _player.remove(0);
    });
  }

  void _onCompleted(bool completed) {
    if (!_live || !completed) return;
    final event = mediaKitSlotEvent(
      index: _player.state.playlist.index,
      completed: completed,
      currentId: _current?.queueItemId,
      nextId: _next?.queueItemId,
      completedReported: _ended,
    );
    if (event is! Completed) return;
    _ended = true;
    _playIntent = false;
    _report();
    _events.add(event);
  }

  void _onPosition(Duration raw) {
    _pendingChange?.cancel();
    _pendingChange = null;
    if (!_live) return;
    final reported = mediaKitPosition(
      raw: raw,
      duration: _duration,
      ended: _ended,
      sinceAdvance: _sinceAdvance?.elapsed,
    );
    if (reported == null) {
      // Re-arms the hold check.
      _report();
      return;
    }
    _sinceAdvance = null;
    final from = _clockFrom;
    if (from != null &&
        clockMoved(from: from, position: reported, duration: _duration)) {
      _clockFrom = null;
    }
    _position = reported;
    _report();
  }

  void _onLog(PlayerLog log) {
    final status = httpStatusInMpvLog(log.text);
    if (status != null) _loggedStatus = status;
  }

  /// Handles a failure mpv reported: [Failed] for the next source when the
  /// message names it, for the current source when it names that one or
  /// arrives while the current source loads.
  ///
  /// A message that names neither source after the current one loaded (a
  /// connection error, a decode error mpv plays through) is kept and
  /// classified with the next named failure.
  void _onError(String message) {
    if (_disposed) return;
    final current = _current;
    if (current == null || _error != null || _currentFailed) return;
    final next = _next;
    final namesNext = next != null && message.contains(_location(next));
    final namesCurrent = message.contains(_location(current));
    if (!namesNext && !namesCurrent && !_loading) {
      _unattributed = message;
      return;
    }
    final status = _loggedStatus;
    _loggedStatus = null;
    final context = _unattributed;
    _unattributed = null;
    final text = context == null ? message : '$context; $message';
    if (namesNext && !(namesCurrent && _loading)) {
      _next = null;
      unawaited(_failNext(next, text, status));
      return;
    }
    _currentFailed = true;
    final generation = _generation;
    // Keep mpv from moving on to the next playlist entry.
    _runDetached(() async {
      if (generation == _generation) await _player.stop();
    });
    unawaited(_failCurrent(current, text, status));
  }

  /// Reports the failure of [next] and drops it from the playlist; the
  /// current source plays on.
  Future<void> _failNext(EngineSource next, String message, int? status) async {
    final generation = _generation;
    final error = await _errorFor(next, message, status);
    if (generation != _generation || _disposed) return;
    _events.add(Failed(next.queueItemId, error));
    _runDetached(() async {
      if (generation != _generation || _next != null) return;
      final playlist = _player.state.playlist;
      final at = playlist.index < 0 ? 0 : playlist.index;
      for (var i = playlist.medias.length - 1; i > at; i--) {
        await _player.remove(i);
      }
    });
  }

  Future<void> _failCurrent(
    EngineSource current,
    String message,
    int? status,
  ) async {
    final generation = _generation;
    final error = await _errorFor(current, message, status);
    if (generation != _generation || _disposed) return;
    _reportFailure(current, error);
  }

  /// Fails [current], which mpv did not open within [loadTimeLimit], and
  /// stops mpv.
  void _failLoad(EngineSource current) {
    _currentFailed = true;
    final generation = _generation;
    _runDetached(() async {
      if (generation == _generation) await _player.stop();
    });
    _reportFailure(
      current,
      EngineError(
        EngineErrorKind.network,
        detail:
            'mpv did not open the source within '
            '${loadTimeLimit.inSeconds} s',
      ),
    );
  }

  void _reportFailure(EngineSource current, EngineError error) {
    _error = error;
    _loading = false;
    _next = null;
    _playIntent = false;
    _settle();
    _report();
    _events.add(Failed(current.queueItemId, error));
  }

  Future<EngineError> _errorFor(
    EngineSource source,
    String message,
    int? status,
  ) async {
    var httpStatus = status;
    if (httpStatus == null &&
        (source.uri.isScheme('http') || source.uri.isScheme('https'))) {
      httpStatus = await _statusOf(source.uri, source.headers);
    }
    return classifyMpvError(message, httpStatus: httpStatus);
  }

  void _report() {
    if (_disposed) return;
    final current = _current;
    final EngineStatus status;
    if (current == null) {
      status = EngineStatus.idle;
    } else if (_error != null) {
      status = EngineStatus.error;
    } else if (_ended) {
      status = EngineStatus.ended;
    } else if (_loading) {
      status = EngineStatus.loading;
    } else if (_player.state.buffering || (_playIntent && _clockFrom != null)) {
      status = EngineStatus.buffering;
    } else {
      status = EngineStatus.ready;
    }
    if (_sinceAdvance != null) {
      // The player is between items: hold the state until it reports a
      // position of the item it plays.
      _recheck ??= Timer(_recheckDelay, () {
        _recheck = null;
        if (_sinceAdvance != null) _onPosition(_player.state.position);
      });
      return;
    }
    final duration = current == null ? null : _duration;
    final position = current == null
        ? Duration.zero
        : _ended && duration != null
        ? duration
        : _position;
    final next = EngineState(
      status: status,
      playing:
          _playIntent &&
          (status == EngineStatus.ready ||
              status == EngineStatus.buffering ||
              status == EngineStatus.loading),
      currentQueueItemId: current?.queueItemId,
      position: position,
      bufferedPosition: current == null ? Duration.zero : _player.state.buffer,
      duration: duration,
      error: _error,
    );
    if (next == _latest) return;
    _latest = next;
    _states.add(next);
  }
}
