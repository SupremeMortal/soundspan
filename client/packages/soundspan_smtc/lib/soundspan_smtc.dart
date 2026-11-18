// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The Windows System Media Transport Controls of the process, through the
/// in-repo C++/WinRT plugin (doc 06, Spike S4 finding).
///
/// Windows only: on other platforms every call fails with a
/// `MissingPluginException`.
library;

import 'package:flutter/services.dart';

/// An event of the System Media Transport Controls.
sealed class SmtcEvent {
  const new();
}

/// The user pressed [button]: `play`, `pause`, `next`, `previous`, `stop`,
/// `fastForward` or `rewind`.
final class SmtcButtonEvent extends SmtcEvent {
  /// Creates the event.
  const new(this.button);

  /// The button's name.
  final String button;
}

/// The user asked to move to [position].
final class SmtcSeekEvent extends SmtcEvent {
  /// Creates the event.
  const new(this.position);

  /// The requested position.
  final Duration position;
}

/// The process's System Media Transport Controls.
class SoundspanSmtc {
  /// Creates the binding; nothing reaches the platform until [initialize].
  new();

  static const MethodChannel _methods = MethodChannel('soundspan_smtc');
  static const EventChannel _events = EventChannel('soundspan_smtc/events');

  /// One stream for every listener: a second `receiveBroadcastStream`
  /// would replace the first one's platform listener.
  static final Stream<SmtcEvent> _stream = _events
      .receiveBroadcastStream()
      .map(_event)
      .where((e) => e != null)
      .cast<SmtcEvent>();

  /// The buttons pressed and the positions asked for.
  Stream<SmtcEvent> get events => _stream;

  /// Registers the session for the process's app user model id.
  Future<void> initialize() => _methods.invokeMethod<void>('initialize');

  /// Enables exactly the buttons passed as true.
  Future<void> setButtons({
    required bool play,
    required bool pause,
    required bool next,
    required bool previous,
    required bool stop,
    required bool fastForward,
    required bool rewind,
  }) => _methods.invokeMethod<void>('setButtons', {
    'play': play,
    'pause': pause,
    'next': next,
    'previous': previous,
    'stop': stop,
    'fastForward': fastForward,
    'rewind': rewind,
  });

  /// Shows a music item; [thumbnailPath] is a local file, or null for no
  /// artwork.
  Future<void> setMetadata({
    required String title,
    required String artist,
    required String album,
    String? thumbnailPath,
  }) => _methods.invokeMethod<void>('setMetadata', {
    'title': title,
    'artist': artist,
    'album': album,
    'thumbnailPath': thumbnailPath,
  });

  /// Shows [status]: `closed`, `stopped`, `paused`, `playing` or
  /// `changing`.
  Future<void> setStatus(String status) =>
      _methods.invokeMethod<void>('setStatus', {'status': status});

  /// Shows [position] in an item of [duration], when known.
  Future<void> setTimeline({
    required Duration position,
    required Duration? duration,
  }) => _methods.invokeMethod<void>('setTimeline', {
    'positionMs': position.inMilliseconds,
    'durationMs': duration?.inMilliseconds,
  });

  /// Removes the item shown.
  Future<void> clear() => _methods.invokeMethod<void>('clear');

  /// Unregisters the session.
  Future<void> dispose() => _methods.invokeMethod<void>('dispose');

  static SmtcEvent? _event(Object? raw) {
    if (raw is! Map) return null;
    final button = raw['button'];
    if (button is String) return SmtcButtonEvent(button);
    final seek = raw['seekMs'];
    if (seek is int) return SmtcSeekEvent(Duration(milliseconds: seek));
    return null;
  }
}
