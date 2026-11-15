// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

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
  new({required this._statusOf}) {
    _subscriptions.addAll([
      _player.stream.playlist.listen(_onPlaylist),
      _player.stream.completed.listen(_onCompleted),
      _player.stream.position.listen(_onPosition),
      _player.stream.duration.listen((_) => _onLoadProgress()),
      _player.stream.buffer.listen((_) => _report()),
      _player.stream.buffering.listen((_) => _report()),
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

  /// How long a load waits for mpv to report the position of a resume
  /// point before it reports the source ready anyway.
  static const Duration _startAtWait = Duration(seconds: 2);

  /// How soon a held state is checked again after a transition.
  static const Duration _recheckDelay = Duration(milliseconds: 10);

  final StreamStatusOf _statusOf;

  // ffmpeg logs `HTTP error <status>` at level warn, so the player listens
  // from that level up.
  final Player _player = Player(
    configuration: const PlayerConfiguration(
      title: 'soundspan',
      logLevel: MPVLogLevel.warn,
    ),
  );

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
  Duration _position = Duration.zero;
  Stopwatch? _sinceAdvance;
  Timer? _recheck;
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
    await _run(() async {
      if (generation != _generation) return;
      await _player.open(
        Playlist([_media(current), if (next != null) _media(next)]),
        play: autoPlay,
      );
    });
    await settled.future;
    if (generation != _generation || _error != null) return;
    if (current.startAt > Duration.zero) await _awaitStartAt(current.startAt);
    if (generation != _generation || _error != null) return;
    _loading = false;
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
    _playIntent = true;
    _report();
    await _run(_player.play);
  }

  /// Pauses and reports not playing once mpv has paused, at the position
  /// mpv paused at: a position update already on its way when the pause
  /// was asked for would otherwise move a paused position.
  @override
  Future<void> pause() async {
    _checkNotDisposed();
    final generation = _generation;
    await _run(() async {
      await _player.pause();
      if (generation != _generation || !_live || _sinceAdvance != null) {
        return;
      }
      final native = _player.platform;
      if (native is! NativePlayer) return;
      final raw = mpvSeconds(await native.getProperty('time-pos'));
      if (raw == null || !_live) return;
      _position =
          mediaKitPosition(raw: raw, duration: _duration, ended: _ended) ??
          _position;
    });
    _playIntent = false;
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
    _position = Duration.zero;
    _sinceAdvance = null;
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
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _serial;
    await _player.dispose();
    await _states.close();
    await _events.close();
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
  }

  Future<void> _run(Future<void> Function() action) {
    final result = _serial.then((_) async {
      if (_disposed) return;
      await _configured;
      await action();
    });
    _serial = result.catchError((Object _) {});
    return result;
  }

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
    _report();
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
    _events.add(event);
    final generation = _generation;
    unawaited(
      _run(() async {
        if (generation != _generation) return;
        if (_player.state.playlist.index > 0) await _player.remove(0);
      }),
    );
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
    unawaited(
      _run(() async {
        if (generation == _generation) await _player.stop();
      }),
    );
    unawaited(_failCurrent(current, text, status));
  }

  /// Reports the failure of [next] and drops it from the playlist; the
  /// current source plays on.
  Future<void> _failNext(EngineSource next, String message, int? status) async {
    final generation = _generation;
    final error = await _errorFor(next, message, status);
    if (generation != _generation || _disposed) return;
    _events.add(Failed(next.queueItemId, error));
    unawaited(
      _run(() async {
        if (generation != _generation || _next != null) return;
        final playlist = _player.state.playlist;
        final at = playlist.index < 0 ? 0 : playlist.index;
        for (var i = playlist.medias.length - 1; i > at; i--) {
          await _player.remove(i);
        }
      }),
    );
  }

  Future<void> _failCurrent(
    EngineSource current,
    String message,
    int? status,
  ) async {
    final generation = _generation;
    final error = await _errorFor(current, message, status);
    if (generation != _generation || _disposed) return;
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
    } else if (_player.state.buffering) {
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
