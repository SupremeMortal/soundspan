// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:soundspan/core/playback/engines/just_audio_mapping.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';

/// Asks the server which HTTP status a request for [uri] with [headers]
/// gets; null when no response arrived.
typedef StreamStatusOf = Future<int?> Function(
  Uri uri,
  Map<String, String> headers,
);

/// The [PlayerEngine] of Android, iOS, macOS and the web, over one
/// `just_audio` [AudioPlayer] (doc 06, `JustAudioEngine`).
///
/// The player's playlist holds the current source at index 0 and, when set,
/// the next one at index 1. When the player moves onto the next source by
/// itself the engine reports [AdvancedToNext] and drops the played item, so
/// the new current source is index 0 again.
final class JustAudioEngine implements PlayerEngine {
  /// Creates an engine for the player [family].
  ///
  /// [reloadOnSetNext] makes [setNext] reload the whole playlist at the
  /// current position instead of replacing index 1 (macOS, Spike S1
  /// finding). `statusOf` is asked for the HTTP status of a stream source
  /// that failed, because the player's error does not always carry it.
  new({
    required this.family,
    required this._statusOf,
    this.reloadOnSetNext = false,
  }) {
    _subscriptions
      ..add(
        _player.playbackEventStream.listen(
          (_) => _onPlayerEvent(),
          onError: _onPlayerError,
        ),
      )
      ..add(_player.playingStream.listen((_) => _report()));
    _ticker = Timer.periodic(_tick, (_) {
      if (_player.playing && _current != null) _report();
    });
  }

  /// How often the position is reported while playing: ten times a second.
  static const Duration _tick = Duration(milliseconds: 100);

  /// How soon a held state is checked again after a transition.
  static const Duration _recheckDelay = Duration(milliseconds: 10);

  /// Which `just_audio` implementation runs, for its error codes.
  final PlayerFamily family;

  /// Whether [setNext] reloads the playlist (macOS).
  final bool reloadOnSetNext;

  final StreamStatusOf _statusOf;

  final AudioPlayer _player = AudioPlayer(
    handleInterruptions: false,
    audioLoadConfiguration: const AudioLoadConfiguration(
      androidLoadControl: AndroidLoadControl(
        minBufferDuration: Duration(seconds: 30),
        maxBufferDuration: Duration(seconds: 120),
      ),
    ),
  );

  final StreamController<EngineState> _states =
      StreamController<EngineState>.broadcast();
  final StreamController<EngineEvent> _events =
      StreamController<EngineEvent>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  late final Timer _ticker;

  EngineSource? _current;
  EngineSource? _next;
  EngineError? _error;
  bool _loading = false;
  bool _ended = false;
  Stopwatch? _sinceAdvance;
  Timer? _recheck;
  EngineState _latest = EngineState.idle;
  bool _disposed = false;

  /// Bumped by [load] and [stop]; a failure of an older source is ignored.
  int _generation = 0;
  Future<void>? _failure;

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
    _failure = null;
    _current = current;
    _next = next;
    _error = null;
    _ended = false;
    _loading = true;
    _sinceAdvance = null;
    _report();
    await _run(() async {
      try {
        if (!autoPlay) await _player.pause();
        await _player.setAudioSources(
          [_audioSource(current), if (next != null) _audioSource(next)],
          initialIndex: 0,
          initialPosition: current.startAt,
        );
        if (generation != _generation) return;
        _loading = false;
        _report();
        if (autoPlay) unawaited(_player.play().catchError((Object _) {}));
      } on PlayerInterruptedException {
        // A newer load or stop replaced this one.
      } on Object catch (error) {
        if (generation != _generation) return;
        _loading = false;
        await _onPlayerError(error);
      }
    });
  }

  @override
  Future<void> setNext(EngineSource? next) async {
    _checkNotDisposed();
    _next = next;
    final current = _current;
    if (current == null || _error != null) return;
    final generation = _generation;
    await _run(() async {
      if (generation != _generation || _next != next) return;
      try {
        if (reloadOnSetNext) {
          await _player.setAudioSources(
            [_audioSource(current), if (next != null) _audioSource(next)],
            initialIndex: 0,
            initialPosition: _player.position,
          );
        } else {
          final length = _player.sequence.length;
          if (length > 1) await _player.removeAudioSourceRange(1, length);
          if (next != null) await _player.addAudioSource(_audioSource(next));
        }
      } on PlayerInterruptedException {
        // A newer load or stop replaced this one.
      } on Object catch (error) {
        if (generation == _generation) await _onPlayerError(error);
      }
    });
  }

  @override
  Future<void> play() async {
    _checkNotDisposed();
    if (_current == null || _error != null) return;
    unawaited(_player.play().catchError((Object _) {}));
  }

  @override
  Future<void> pause() async {
    _checkNotDisposed();
    await _player.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    _checkNotDisposed();
    if (_current == null) return;
    final duration = _player.duration;
    var target = position < Duration.zero ? Duration.zero : position;
    if (duration != null && target > duration) target = duration;
    _ended = false;
    _sinceAdvance = null;
    await _player.seek(target);
    _report();
  }

  @override
  Future<void> stop() async {
    _checkNotDisposed();
    _generation++;
    _failure = null;
    _current = null;
    _next = null;
    _error = null;
    _loading = false;
    _ended = false;
    _sinceAdvance = null;
    _report();
    await _run(() async {
      await _player.stop();
      await _player.clearAudioSources();
    });
  }

  @override
  Future<void> setVolume(double linear) async {
    _checkNotDisposed();
    await _player.setVolume(linear.clamp(0.0, 1.0));
  }

  @override
  Future<void> setSpeed(double speed) async {
    _checkNotDisposed();
    await _player.setSpeed(speed.clamp(0.5, 3.0));
  }

  @override
  Future<void> dispose() async {
    _checkNotDisposed();
    _disposed = true;
    _generation++;
    _ticker.cancel();
    _recheck?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _player.dispose();
    await _states.close();
    await _events.close();
  }

  void _checkNotDisposed() {
    if (_disposed) throw StateError('JustAudioEngine used after dispose');
  }

  Future<void> _run(Future<void> Function() action) {
    final result = _serial.then((_) => _disposed ? null : action());
    _serial = result.catchError((Object _) {});
    return result;
  }

  static AudioSource _audioSource(EngineSource source) {
    if (source.uri.isScheme('file')) {
      return AudioSource.file(source.uri.toFilePath(), tag: source.queueItemId);
    }
    return AudioSource.uri(
      source.uri,
      headers: source.headers.isEmpty ? null : source.headers,
      tag: source.queueItemId,
    );
  }

  EngineStatus _playerStatus() => switch (_player.processingState) {
    ProcessingState.idle || ProcessingState.loading => EngineStatus.loading,
    ProcessingState.buffering => EngineStatus.buffering,
    ProcessingState.ready => EngineStatus.ready,
    ProcessingState.completed => EngineStatus.ended,
  };

  void _onPlayerEvent() {
    if (_disposed || _current == null || _error != null || _loading) {
      _report();
      return;
    }
    final event = slotEvent(
      sequence: [for (final s in _player.sequence) s.tag as String?],
      index: _player.currentIndex,
      status: _playerStatus(),
      currentId: _current?.queueItemId,
      nextId: _next?.queueItemId,
      completedReported: _ended,
    );
    switch (event) {
      case AdvancedToNext():
        _current = _next;
        _next = null;
        _sinceAdvance = Stopwatch()..start();
        _report();
        _events.add(event);
        final generation = _generation;
        unawaited(
          _run(() async {
            if (generation != _generation) return;
            final index = _player.sequence.indexWhere(
              (s) => s.tag == event.queueItemId,
            );
            if (index > 0) await _player.removeAudioSourceRange(0, index);
          }),
        );
      case Completed():
        _ended = true;
        _report();
        _events.add(event);
        unawaited(_player.pause().catchError((Object _) {}));
      case Failed() || null:
        _report();
    }
  }

  /// Handles an error of the player or of a player call: reports [Failed]
  /// for the current source, or for the next one when only that failed.
  Future<void> _onPlayerError(Object error, [StackTrace? _]) {
    if (_disposed) return Future<void>.value();
    if (error is PlayerInterruptedException) return Future<void>.value();
    final current = _current;
    if (current == null) return Future<void>.value();
    final code = error is PlayerException ? error.code : -1;
    final message = error is PlayerException ? error.message : '$error';
    final index = error is PlayerException ? error.index : null;
    final sequence = _player.sequence;
    final failedId = index != null && index >= 0 && index < sequence.length
        ? sequence[index].tag as String?
        : current.queueItemId;
    final next = _next;
    if (next != null &&
        failedId == next.queueItemId &&
        failedId != current.queueItemId &&
        _player.processingState != ProcessingState.idle) {
      _next = null;
      return _failNext(next, code, message);
    }
    return _failure ??= _failCurrent(current, code, message);
  }

  /// Reports the failure of [next] and drops it from the playlist; the
  /// current source plays on. Never waits on [_run], which may be running
  /// the call that failed.
  Future<void> _failNext(EngineSource next, int code, String? message) async {
    final generation = _generation;
    final error = await _errorFor(next, code, message);
    if (generation != _generation || _disposed) return;
    _events.add(Failed(next.queueItemId, error));
    unawaited(
      _run(() async {
        if (generation != _generation) return;
        final at = _player.sequence.indexWhere(
          (s) => s.tag == next.queueItemId,
        );
        if (at > 0) await _player.removeAudioSourceAt(at);
      }),
    );
  }

  Future<void> _failCurrent(
    EngineSource current,
    int code,
    String? message,
  ) async {
    final generation = _generation;
    final error = await _errorFor(current, code, message);
    if (generation != _generation || _disposed) return;
    _error = error;
    _loading = false;
    _next = null;
    _report();
    _events.add(Failed(current.queueItemId, error));
    await _player.pause().catchError((Object _) {});
  }

  Future<EngineError> _errorFor(
    EngineSource source,
    int code,
    String? message,
  ) async {
    int? status;
    var unreachable = false;
    if (source.uri.isScheme('http') || source.uri.isScheme('https')) {
      status = await _statusOf(source.uri, source.headers);
      unreachable = status == null;
    }
    return engineErrorFor(
      family: family,
      code: code,
      message: message,
      httpStatus: status,
      unreachable: unreachable,
    );
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
    } else {
      final player = _playerStatus();
      // The ended state is reported with Completed, from _onPlayerEvent.
      status = player == EngineStatus.ended ? EngineStatus.ready : player;
    }
    final duration = current == null ? null : _player.duration;
    var position = Duration.zero;
    if (current != null) {
      final reported = reportedPosition(
        raw: _player.position,
        duration: duration,
        ended: _ended,
        sinceAdvance: _sinceAdvance?.elapsed,
      );
      if (reported == null) {
        // The player still reports the previous item's end; hold the state
        // until it reports the new item's own position.
        _recheck ??= Timer(_recheckDelay, () {
          _recheck = null;
          _report();
        });
        return;
      }
      _sinceAdvance = null;
      position = reported;
    }
    final next = EngineState(
      status: status,
      playing:
          _player.playing &&
          (status == EngineStatus.ready ||
              status == EngineStatus.buffering ||
              status == EngineStatus.loading),
      currentQueueItemId: current?.queueItemId,
      position: position,
      bufferedPosition: current == null
          ? Duration.zero
          : _player.bufferedPosition,
      duration: duration,
      error: _error,
    );
    if (next == _latest) return;
    _latest = next;
    _states.add(next);
  }
}
