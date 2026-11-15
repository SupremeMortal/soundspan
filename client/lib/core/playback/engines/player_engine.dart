// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The two-slot playback engine seam: a current source and an optional
/// preloaded next source, behind which `just_audio` and `media_kit` live.
library;

/// A playable thing handed to the engine. Built by the source resolver.
final class EngineSource {
  /// Creates a source for the queue entry [queueItemId] at [uri].
  const new({
    required this.queueItemId,
    required this.uri,
    this.headers = const {},
    this.knownDuration,
    this.startAt = Duration.zero,
  });

  /// The queue entry this source plays; events name it.
  final String queueItemId;

  /// A `file://` or `http(s)://` address.
  final Uri uri;

  /// Request headers for every request the engine makes for [uri]. Empty for
  /// files and on the web.
  final Map<String, String> headers;

  /// The duration when it is known before loading, otherwise null.
  final Duration? knownDuration;

  /// Where playback starts: a resume position, zero normally.
  final Duration startAt;

  @override
  String toString() => 'EngineSource($queueItemId, $uri)';
}

/// What the engine is doing with its current source.
enum EngineStatus {
  /// Nothing is loaded.
  idle,

  /// The current source is being opened.
  loading,

  /// The current source can play from its position.
  ready,

  /// The current source waits for data before it can continue.
  buffering,

  /// The current source played to its end and no next source was set.
  ended,

  /// The current source failed; [EngineState.error] says why.
  error,
}

/// One value of [PlayerEngine.state].
final class EngineState {
  /// Creates a state value.
  const new({
    required this.status,
    required this.playing,
    required this.position,
    this.currentQueueItemId,
    this.bufferedPosition = Duration.zero,
    this.duration,
    this.error,
  });

  /// The state of an engine with nothing loaded: idle, not playing, at zero.
  static const EngineState idle = EngineState(
    status: EngineStatus.idle,
    playing: false,
    position: Duration.zero,
  );

  /// What the engine is doing.
  final EngineStatus status;

  /// The play intent: true while buffering after `play()`.
  final bool playing;

  /// The queue entry of the current source, null when nothing is loaded.
  final String? currentQueueItemId;

  /// The playback position in the current source.
  final Duration position;

  /// How far the current source is buffered.
  final Duration bufferedPosition;

  /// The duration of the current source once known.
  final Duration? duration;

  /// Why the current source failed, when [status] is [EngineStatus.error].
  final EngineError? error;

  @override
  // Every field is final; no package is imported so the engine seam stays
  // pure Dart.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      other is EngineState &&
      other.status == status &&
      other.playing == playing &&
      other.currentQueueItemId == currentQueueItemId &&
      other.position == position &&
      other.bufferedPosition == bufferedPosition &&
      other.duration == duration &&
      other.error == error;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes, see ==.
  int get hashCode => Object.hash(
    status,
    playing,
    currentQueueItemId,
    position,
    bufferedPosition,
    duration,
    error,
  );

  @override
  String toString() =>
      'EngineState(${status.name}, playing: $playing, '
      'item: $currentQueueItemId, position: $position, '
      'buffered: $bufferedPosition, duration: $duration, error: $error)';
}

/// Something that happened to a source, on [PlayerEngine.events].
sealed class EngineEvent {
  const new(this.queueItemId);

  /// The queue entry the event is about.
  final String queueItemId;
}

/// The engine moved from current to the preloaded next source by itself;
/// [queueItemId] is the new current entry.
final class AdvancedToNext extends EngineEvent {
  /// Creates the event for the new current entry [queueItemId].
  const new(super.queueItemId);

  @override
  // Every field is final; no package is imported so the engine seam stays
  // pure Dart.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      other is AdvancedToNext && other.queueItemId == queueItemId;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes, see ==.
  int get hashCode => Object.hash(AdvancedToNext, queueItemId);

  @override
  String toString() => 'AdvancedToNext($queueItemId)';
}

/// The current source finished and no next source was set.
final class Completed extends EngineEvent {
  /// Creates the event for the finished entry [queueItemId].
  const new(super.queueItemId);

  @override
  // Every field is final; no package is imported so the engine seam stays
  // pure Dart.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      other is Completed && other.queueItemId == queueItemId;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes, see ==.
  int get hashCode => Object.hash(Completed, queueItemId);

  @override
  String toString() => 'Completed($queueItemId)';
}

/// The source of [queueItemId] (current or next) could not be played.
final class Failed extends EngineEvent {
  /// Creates the event for the failed entry [queueItemId].
  const new(super.queueItemId, this.error);

  /// Why it failed.
  final EngineError error;

  @override
  // Every field is final; no package is imported so the engine seam stays
  // pure Dart.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      other is Failed &&
      other.queueItemId == queueItemId &&
      other.error == error;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes, see ==.
  int get hashCode => Object.hash(Failed, queueItemId, error);

  @override
  String toString() => 'Failed($queueItemId, $error)';
}

/// The kind of an [EngineError].
enum EngineErrorKind {
  /// The network could not be reached or the connection broke.
  network,

  /// The server answered an HTTP error not covered by another kind.
  http,

  /// The data could not be decoded.
  decode,

  /// The server answered 404, or a file does not exist.
  notFound,

  /// The server answered 401.
  unauthorized,

  /// Anything else.
  unknown,
}

/// Why a source failed.
final class EngineError {
  /// Creates an error of [kind].
  const new(this.kind, {this.httpStatus, this.detail = ''});

  /// What went wrong.
  final EngineErrorKind kind;

  /// The HTTP status when the server answered one.
  final int? httpStatus;

  /// A description for logs only; never shown to the user.
  final String detail;

  /// Errors are equal when [kind] and [httpStatus] are; [detail] is for logs.
  @override
  // Every field is final; no package is imported so the engine seam stays
  // pure Dart.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      other is EngineError &&
      other.kind == kind &&
      other.httpStatus == httpStatus;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes, see ==.
  int get hashCode => Object.hash(kind, httpStatus);

  @override
  String toString() =>
      'EngineError(${kind.name}${httpStatus == null ? '' : ', $httpStatus'}'
      '${detail.isEmpty ? '' : ', $detail'})';
}

/// Plays at most two things: the current source and a preloaded next source.
///
/// It knows nothing about queues, shuffle or the server. Contract, pinned by
/// the engine conformance suite (`integration_test/support/engine_conformance.dart`):
///
/// - [state] replays the latest value to a new listener; the initial state
///   is [EngineState.idle] (idle, not playing, position zero).
/// - [load] never throws for a bad source: it completes, emits [Failed] for
///   that source's queue entry, and the state is [EngineStatus.error] with
///   the [EngineError].
/// - A next source that fails to load emits [Failed] with the next entry's
///   id; the current entry is undisturbed and the next slot is empty.
/// - After [AdvancedToNext], the state's current entry is the new one, its
///   position restarts from zero, and the next slot is empty until [setNext]
///   is called again.
/// - After [Completed], the status is [EngineStatus.ended], `playing` is
///   false and the position equals the duration.
/// - [seek] clamps to `[0, duration]`. [play] with nothing loaded is a no-op.
///   [setVolume] clamps to 0.0–1.0 and [setSpeed] to 0.5–3.0.
/// - After [dispose], both streams are closed and any further call throws a
///   [StateError].
abstract interface class PlayerEngine {
  /// The engine's state. Replays the latest value to a new listener;
  /// position updates at least four times per second while playing.
  Stream<EngineState> get state;

  /// Transitions and failures, in the order they happen.
  Stream<EngineEvent> get events;

  /// Replaces everything with [current] and, when given, the preloaded
  /// [next]. Completes when [current] is ready or failed; never throws for a
  /// bad source. Starts playing when [autoPlay] is true.
  Future<void> load(
    EngineSource current, {
    EngineSource? next,
    bool autoPlay = true,
  });

  /// Sets, replaces, or clears the preloaded next source without disturbing
  /// the current one.
  Future<void> setNext(EngineSource? next);

  /// Plays the current source; a no-op when nothing is loaded.
  Future<void> play();

  /// Pauses, keeping the position.
  Future<void> pause();

  /// Moves to [position], clamped to `[0, duration]`.
  Future<void> seek(Duration position);

  /// Releases both sources; the engine stays usable.
  Future<void> stop();

  /// Sets the linear gain (user volume × loudness gain), clamped to 0.0–1.0.
  Future<void> setVolume(double linear);

  /// Sets the playback speed, clamped to 0.5–3.0. Podcasts only.
  Future<void> setSpeed(double speed);

  /// Releases the audio device and closes both streams.
  Future<void> dispose();
}
