// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The pure parts of `JustAudioEngine`: error mapping, slot events and the
/// reported position. Kept apart from the `just_audio` adapter so they run
/// in `flutter test`.
library;

import 'package:soundspan/core/playback/engines/player_engine.dart';

/// Which `just_audio` implementation reported an error; their error codes
/// mean different things.
enum PlayerFamily {
  /// ExoPlayer: the code is `ExoPlaybackException.type`.
  android,

  /// AVPlayer on iOS and macOS: the code is `NSError.code`.
  darwin,

  /// The browser's media element: the code is `MediaError.code`.
  web,
}

/// `NSURLError` codes of a connection that failed or was lost.
const _darwinNetwork = {-1001, -1003, -1004, -1005, -1009, -1020};

/// AVFoundation codes of data that could not be parsed or decoded.
const _darwinDecode = {-11821, -11828, -11829, -11853};

/// Maps a player failure to an [EngineError].
///
/// [httpStatus] is the status the server answered for the source, when
/// known; [unreachable] is true when the server gave no response at all.
/// Either decides over the player's [code]: 404 is
/// [EngineErrorKind.notFound], 401 [EngineErrorKind.unauthorized], any other
/// status of 400 or more [EngineErrorKind.http], and no response
/// [EngineErrorKind.network]. Otherwise the [code] of the player [family]
/// names a connection failure ([EngineErrorKind.network]), a format error
/// ([EngineErrorKind.decode]) or, on iOS and macOS, a refused credential or
/// a missing file; anything else is [EngineErrorKind.unknown].
EngineError engineErrorFor({
  required PlayerFamily family,
  required int code,
  String? message,
  int? httpStatus,
  bool unreachable = false,
}) {
  final detail = 'code $code${message == null ? '' : ': $message'}';
  if (httpStatus != null && httpStatus >= 400) {
    final kind = switch (httpStatus) {
      404 => EngineErrorKind.notFound,
      401 => EngineErrorKind.unauthorized,
      _ => EngineErrorKind.http,
    };
    return EngineError(kind, httpStatus: httpStatus, detail: detail);
  }
  if (unreachable) return EngineError(EngineErrorKind.network, detail: detail);
  final kind = switch (family) {
    PlayerFamily.android =>
      code == 1 ? EngineErrorKind.decode : EngineErrorKind.unknown,
    PlayerFamily.darwin => switch (code) {
      -1013 => EngineErrorKind.unauthorized,
      -1100 => EngineErrorKind.notFound,
      _ when _darwinNetwork.contains(code) => EngineErrorKind.network,
      _ when _darwinDecode.contains(code) => EngineErrorKind.decode,
      _ => EngineErrorKind.unknown,
    },
    PlayerFamily.web => switch (code) {
      2 => EngineErrorKind.network,
      3 || 4 => EngineErrorKind.decode,
      _ => EngineErrorKind.unknown,
    },
  };
  return EngineError(kind, detail: detail);
}

/// The event a player update means for the engine's two slots, or null.
///
/// [sequence] holds the queue entries of the player's playlist in order and
/// [index] the one it plays; [currentId] and [nextId] are the engine's
/// current and next entries. The player moving onto [nextId] while ready or
/// buffering is [AdvancedToNext]; the player completing [currentId] is
/// [Completed], once ([completedReported] says it was already reported).
EngineEvent? slotEvent({
  required List<String?> sequence,
  required int? index,
  required EngineStatus status,
  required String? currentId,
  required String? nextId,
  required bool completedReported,
}) {
  if (index == null || index < 0 || index >= sequence.length) return null;
  final playing = sequence[index];
  if (nextId != null &&
      playing == nextId &&
      (status == EngineStatus.ready || status == EngineStatus.buffering)) {
    return AdvancedToNext(nextId);
  }
  if (status == EngineStatus.ended &&
      !completedReported &&
      currentId != null &&
      playing == currentId) {
    return Completed(currentId);
  }
  return null;
}

/// How long after a transition the player's position is checked against
/// the time since the transition.
const Duration _staleWindow = Duration(seconds: 1);

/// How far the player's position may run ahead of the time since a
/// transition before it is taken for the previous item's end position.
const Duration _staleMargin = Duration(milliseconds: 150);

/// The position to report for the player position [raw], or null when
/// [raw] is not yet a position of the current item.
///
/// Clamped to `[0, duration]`, and [duration] once [ended]. [sinceAdvance]
/// is the time since the last [AdvancedToNext]: on iOS and macOS the index
/// change can arrive before the position reset, so for a second after a
/// transition a position further ahead than the time since it is still the
/// previous item's end, and null is returned until the player reports the
/// new item's own position. No position is invented.
Duration? reportedPosition({
  required Duration raw,
  required Duration? duration,
  required bool ended,
  Duration? sinceAdvance,
}) {
  if (ended && duration != null) return duration;
  var position = raw < Duration.zero ? Duration.zero : raw;
  if (duration != null && position > duration) position = duration;
  if (sinceAdvance != null &&
      sinceAdvance < _staleWindow &&
      position > sinceAdvance + _staleMargin) {
    return null;
  }
  return position;
}
