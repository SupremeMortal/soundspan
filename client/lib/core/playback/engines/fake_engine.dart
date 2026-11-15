// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:soundspan/core/playback/engines/player_engine.dart';

/// How a [FakeEngine] behaves for one URI.
final class FakeSource {
  /// Scripts a source of [duration].
  const new({
    required this.duration,
    this.failure,
    this.bufferedAhead,
    this.requiredHeaders = const {},
  });

  /// The length of the source.
  final Duration duration;

  /// When set, loading the source fails with this error.
  final EngineError? failure;

  /// How far ahead of the position the source is buffered; the whole
  /// source when null. A seek past the buffered range buffers first.
  final Duration? bufferedAhead;

  /// Headers a request must carry with these exact values; a request
  /// without them fails with [EngineErrorKind.unauthorized] (401).
  final Map<String, String> requiredHeaders;
}

final class _Slot {
  const new(this.source, this.script);

  final EngineSource source;
  final FakeSource script;
}

/// A deterministic [PlayerEngine] on virtual time, for tests.
///
/// Nothing moves until [advance] is called: it moves playback forward and
/// emits state (every [positionInterval] while playing, and at every
/// transition) and events in order, with no real timers. Sources are
/// scripted by URI in [sources]; a URI with no script fails with
/// [EngineErrorKind.notFound]. Every source the engine opens, current or
/// next, is recorded in [requested] with its headers.
final class FakeEngine implements PlayerEngine {
  /// Creates an engine that reads [sources] each time it opens a source, so
  /// scripts added to the map later are seen.
  new({Map<Uri, FakeSource>? sources}) : sources = sources ?? {};

  /// How often the position is reported while playing: five times a second.
  static const Duration positionInterval = Duration(milliseconds: 200);

  /// The scripts by URI.
  final Map<Uri, FakeSource> sources;

  /// Every source the engine opened, in order, with the headers it sent.
  final List<EngineSource> requested = [];

  /// Whether `http` and `https` sources can be reached; when false they fail
  /// with [EngineErrorKind.network] and only `file` sources play.
  bool networkAvailable = true;

  final StreamController<EngineState> _states =
      StreamController<EngineState>.broadcast();
  final StreamController<EngineEvent> _events =
      StreamController<EngineEvent>.broadcast();

  _Slot? _current;
  _Slot? _next;
  String? _currentId;
  EngineStatus _status = EngineStatus.idle;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _buffered = Duration.zero;
  EngineError? _error;
  EngineState _latest = EngineState.idle;
  Duration _sinceReport = Duration.zero;
  bool _unreported = false;
  double _volume = 1;
  double _speed = 1;
  bool _disposed = false;

  /// The linear gain last set, clamped to 0.0–1.0.
  double get volume => _volume;

  /// The speed last set, clamped to 0.5–3.0.
  double get speed => _speed;

  /// Whether [dispose] has been called.
  bool get isDisposed => _disposed;

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

  /// Lets [d] of virtual time pass, moving playback forward at [speed].
  void advance(Duration d) {
    _checkNotDisposed();
    var left = d;
    while (left > Duration.zero) {
      final untilReport = positionInterval - _sinceReport;
      final step = left < untilReport ? left : untilReport;
      left -= step;
      _sinceReport += step;
      _progress(step);
      if (_sinceReport >= positionInterval) {
        _sinceReport = Duration.zero;
        if (_unreported) _report();
      }
    }
  }

  @override
  Future<void> load(
    EngineSource current, {
    EngineSource? next,
    bool autoPlay = true,
  }) async {
    _checkNotDisposed();
    _current = null;
    _next = null;
    _currentId = current.queueItemId;
    _status = EngineStatus.loading;
    _playing = autoPlay;
    _position = Duration.zero;
    _buffered = Duration.zero;
    _error = null;
    _sinceReport = Duration.zero;
    _report();

    final (script, error) = _open(current);
    if (script == null) {
      _status = EngineStatus.error;
      _playing = false;
      _error = error;
      _report();
      _events.add(Failed(current.queueItemId, error!));
      return;
    }
    _current = _Slot(current, script);
    _position = _clamp(current.startAt, script.duration);
    _buffered = _bufferedFrom(_position);
    _status = EngineStatus.ready;
    _report();
    if (next != null) _prepareNext(next);
  }

  @override
  Future<void> setNext(EngineSource? next) async {
    _checkNotDisposed();
    _next = null;
    if (next != null) _prepareNext(next);
  }

  @override
  Future<void> play() async {
    _checkNotDisposed();
    if (_current == null || _playing) return;
    if (_status != EngineStatus.ready && _status != EngineStatus.buffering) {
      return;
    }
    _playing = true;
    _report();
  }

  @override
  Future<void> pause() async {
    _checkNotDisposed();
    if (_current == null || !_playing) return;
    _playing = false;
    _report();
  }

  @override
  Future<void> seek(Duration position) async {
    _checkNotDisposed();
    final current = _current;
    if (current == null) return;
    _position = _clamp(position, current.script.duration);
    if (_position > _buffered) {
      _status = EngineStatus.buffering;
      _buffered = _position;
    } else {
      _status = EngineStatus.ready;
    }
    _report();
  }

  @override
  Future<void> stop() async {
    _checkNotDisposed();
    _current = null;
    _next = null;
    _currentId = null;
    _status = EngineStatus.idle;
    _playing = false;
    _position = Duration.zero;
    _buffered = Duration.zero;
    _error = null;
    _report();
  }

  @override
  Future<void> setVolume(double linear) async {
    _checkNotDisposed();
    _volume = linear.clamp(0.0, 1.0);
  }

  @override
  Future<void> setSpeed(double speed) async {
    _checkNotDisposed();
    _speed = speed.clamp(0.5, 3.0);
  }

  @override
  Future<void> dispose() async {
    _checkNotDisposed();
    _disposed = true;
    _current = null;
    _next = null;
    await _states.close();
    await _events.close();
  }

  void _checkNotDisposed() {
    if (_disposed) throw StateError('FakeEngine used after dispose');
  }

  /// Opens [source] like a server or file system would answer it.
  (FakeSource?, EngineError?) _open(EngineSource source) {
    requested.add(source);
    final remote = source.uri.isScheme('http') || source.uri.isScheme('https');
    if (remote && !networkAvailable) {
      return (
        null,
        const EngineError(EngineErrorKind.network, detail: 'offline'),
      );
    }
    final script = sources[source.uri];
    if (script == null) {
      return (
        null,
        EngineError(EngineErrorKind.notFound, detail: '${source.uri}'),
      );
    }
    if (script.failure case final failure?) return (null, failure);
    for (final MapEntry(:key, :value) in script.requiredHeaders.entries) {
      if (source.headers[key] != value) {
        return (
          null,
          EngineError(
            EngineErrorKind.unauthorized,
            httpStatus: 401,
            detail: key,
          ),
        );
      }
    }
    return (script, null);
  }

  void _prepareNext(EngineSource next) {
    final (script, error) = _open(next);
    if (script == null) {
      _events.add(Failed(next.queueItemId, error!));
      return;
    }
    _next = _Slot(next, script);
  }

  void _progress(Duration step) {
    var current = _current;
    if (current == null || !_playing) return;
    if (_status == EngineStatus.buffering) {
      _status = EngineStatus.ready;
      _buffered = _bufferedFrom(_position);
      _unreported = true;
      return;
    }
    if (_status != EngineStatus.ready) return;

    var move = step * _speed;
    while (true) {
      final left = current!.script.duration - _position;
      if (move < left) {
        _position += move;
        final buffered = _bufferedFrom(_position);
        if (buffered > _buffered) _buffered = buffered;
        _unreported = true;
        return;
      }
      move -= left;
      _position = current.script.duration;
      _buffered = _position;
      final next = _next;
      if (next == null) {
        _status = EngineStatus.ended;
        _playing = false;
        _report();
        _events.add(Completed(current.source.queueItemId));
        return;
      }
      _report();
      _next = null;
      _current = current = next;
      _currentId = next.source.queueItemId;
      _position = Duration.zero;
      _buffered = _bufferedFrom(Duration.zero);
      _report();
      _events.add(AdvancedToNext(next.source.queueItemId));
    }
  }

  Duration _bufferedFrom(Duration position) {
    final duration = _current!.script.duration;
    final ahead = _current!.script.bufferedAhead;
    if (ahead == null) return duration;
    final end = position + ahead;
    return end > duration ? duration : end;
  }

  static Duration _clamp(Duration position, Duration duration) {
    if (position < Duration.zero) return Duration.zero;
    return position > duration ? duration : position;
  }

  void _report() {
    _unreported = false;
    _latest = EngineState(
      status: _status,
      playing: _playing,
      currentQueueItemId: _currentId,
      position: _position,
      bufferedPosition: _buffered,
      duration: _current?.script.duration,
      error: _error,
    );
    _states.add(_latest);
  }
}
