// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The pure parts of `MediaKitEngine`: error classification, slot events,
/// volume and the reported position. Kept apart from the `media_kit`
/// adapter so they run in `flutter test`.
library;

import 'package:soundspan/core/playback/engines/player_engine.dart';

final RegExp _httpErrorLine = RegExp(r'HTTP error (\d{3})\b');

final RegExp _network = RegExp(
  'connection refused|connection reset|connection timed out|timed out|'
  'timeout|failed to resolve|name or service not known|network is unreachable|'
  'no route to host|broken pipe|end of file|i/o error',
  caseSensitive: false,
);

final RegExp _decode = RegExp(
  'failed to recognize file format|unrecognized file format|'
  'invalid data found|error decoding|could not decode|decoder|demux',
  caseSensitive: false,
);

final RegExp _missingFile = RegExp(
  'no such file or directory',
  caseSensitive: false,
);

/// The HTTP status of ffmpeg's `HTTP error <status> <reason>` log line, or
/// null for any other line.
///
/// mpv's own failure message ("Failed to open …") carries no status; ffmpeg
/// logs this line (at level `warn`) just before it, for every error status
/// except 401.
int? httpStatusInMpvLog(String text) {
  final match = _httpErrorLine.firstMatch(text);
  return match == null ? null : int.parse(match.group(1)!);
}

/// Classifies an mpv failure [message] as an [EngineError].
///
/// [httpStatus] is the status the server answered for the source, when
/// known, and decides over the text: 404 is [EngineErrorKind.notFound], 401
/// [EngineErrorKind.unauthorized], any other status of 400 or more
/// [EngineErrorKind.http]. Otherwise connection and timeout failures are
/// [EngineErrorKind.network], demux and decode failures
/// [EngineErrorKind.decode], a missing local file
/// [EngineErrorKind.notFound], and the rest [EngineErrorKind.unknown].
EngineError classifyMpvError(String message, {int? httpStatus}) {
  if (httpStatus != null && httpStatus >= 400) {
    final kind = switch (httpStatus) {
      404 => EngineErrorKind.notFound,
      401 => EngineErrorKind.unauthorized,
      _ => EngineErrorKind.http,
    };
    return EngineError(kind, httpStatus: httpStatus, detail: message);
  }
  final kind = _network.hasMatch(message)
      ? EngineErrorKind.network
      : _decode.hasMatch(message)
      ? EngineErrorKind.decode
      : _missingFile.hasMatch(message)
      ? EngineErrorKind.notFound
      : EngineErrorKind.unknown;
  return EngineError(kind, detail: message);
}

/// The event a player update means for the engine's two slots, or null.
///
/// The player's playlist holds the current entry [currentId] at [index] 0
/// and the next entry [nextId], when set, at index 1. The player moving to
/// index 1 while a next entry is set is [AdvancedToNext]. [completed] with
/// no next entry is [Completed] for the current entry, once
/// ([completedReported] says it was already reported); media_kit reports
/// `completed` for a moment at the end of every item, so with a next entry
/// set it means nothing.
EngineEvent? mediaKitSlotEvent({
  required int index,
  required bool completed,
  required String? currentId,
  required String? nextId,
  required bool completedReported,
}) {
  if (currentId == null) return null;
  if (index == 1 && nextId != null) return AdvancedToNext(nextId);
  if (index == 0 && completed && nextId == null && !completedReported) {
    return Completed(currentId);
  }
  return null;
}

/// The mpv `volume` (0–100, with `volume-max=100`) for the linear gain
/// [linear], clamped to 0.0–1.0.
double mpvVolume(double linear) {
  if (linear.isNaN) return 0;
  return linear.clamp(0.0, 1.0) * 100;
}

/// How far mpv's position must move on before playback counts as running.
const Duration _clockStep = Duration(milliseconds: 50);

/// Whether [position] shows mpv's clock running after playback started,
/// resumed or seeked at [from]: at least 50 ms further on, or at the end
/// of the item ([duration]). While an audio output has not started
/// consuming, mpv reports positions that jitter by microseconds around
/// [from]; those are not movement.
bool clockMoved({
  required Duration from,
  required Duration position,
  required Duration? duration,
}) {
  if (duration != null && position >= duration && position > from) {
    return true;
  }
  return position >= from + _clockStep;
}

/// How long after a transition a position is checked against the time
/// since the transition.
const Duration _staleWindow = Duration(seconds: 1);

/// How far a position may run ahead of the time since a transition before
/// it is taken for the previous item's end position.
const Duration _staleMargin = Duration(milliseconds: 150);

/// The position to report for the mpv position [raw], or null when [raw]
/// is not yet a position of the current item.
///
/// Clamped to `[0, duration]`, and [duration] once [ended]. [sinceAdvance]
/// is the time since the last [AdvancedToNext], null when there was none
/// since the last report of a position. After a transition (Spike S2
/// finding) media_kit first resets the position to zero, then mpv reports
/// the new item's position minus the previous item's audio still buffered
/// (negative), and a last position of the previous item can arrive after
/// the index change. None of these is a position of the new item, so for
/// a second after the transition null is returned until a positive one
/// arrives that is not further ahead than the time since the transition.
/// No position is invented.
Duration? mediaKitPosition({
  required Duration raw,
  required Duration? duration,
  required bool ended,
  Duration? sinceAdvance,
}) {
  if (ended && duration != null) return duration;
  if (sinceAdvance != null &&
      sinceAdvance < _staleWindow &&
      (raw <= Duration.zero || raw > sinceAdvance + _staleMargin)) {
    return null;
  }
  var position = raw < Duration.zero ? Duration.zero : raw;
  if (duration != null && position > duration) position = duration;
  return position;
}
