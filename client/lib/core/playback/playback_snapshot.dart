// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/core/playback/stream_quality_info.dart';
import 'package:soundspan/shared/domain/queue_item.dart';

/// The kind of a [PlaybackError].
enum PlaybackErrorKind {
  /// The engine could not play the item.
  itemFailed,

  /// The item cannot be streamed at all: it has no `playbackId`, or the
  /// server answered that it does not exist or cannot be played.
  itemUnavailable,

  /// The server rejected the credential again after it was renewed.
  unauthorized,

  /// Three items in a row failed, so playback stopped.
  serverUnreachable,
}

/// Why the current item is not playing.
final class PlaybackError {
  /// Creates an error of [kind] for the queue entry [queueItemId].
  const new(this.kind, {this.queueItemId});

  /// What went wrong.
  final PlaybackErrorKind kind;

  /// The queue entry it is about, when there is one.
  final String? queueItemId;

  @override
  // Every field is final and the class is immutable.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      other is PlaybackError &&
      other.kind == kind &&
      other.queueItemId == queueItemId;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes, see ==.
  int get hashCode => Object.hash(kind, queueItemId);

  @override
  String toString() => 'PlaybackError(${kind.name}, $queueItemId)';
}

/// Everything the UI and the OS controls show about playback (doc 06,
/// Controller Behaviour). One value of `PlaybackController.snapshots`.
final class PlaybackSnapshot {
  /// Creates a snapshot.
  const new({
    required this.queue,
    required this.status,
    required this.playing,
    this.current,
    this.position = Duration.zero,
    this.buffered = Duration.zero,
    this.duration,
    this.quality,
    this.error,
    this.isLocalFile = false,
  });

  /// The snapshot of a controller with an empty queue and nothing loaded.
  static final PlaybackSnapshot initial = PlaybackSnapshot(
    queue: QueueState.empty(),
    status: EngineStatus.idle,
    playing: false,
  );

  /// The play queue.
  final QueueState queue;

  /// The queue's current entry, null when the queue is empty.
  final QueueItem? current;

  /// What the engine is doing with the current source.
  final EngineStatus status;

  /// The play intent.
  final bool playing;

  /// The position in the current item.
  final Duration position;

  /// How far the current item is buffered.
  final Duration buffered;

  /// The current item's duration once known.
  final Duration? duration;

  /// The stream's quality, for the quality badge; null until known.
  final StreamQualityInfo? quality;

  /// Why the current item is not playing, when it failed.
  final PlaybackError? error;

  /// Whether the current item plays from a local file.
  final bool isLocalFile;

  /// Whether [other] differs from this snapshot only in [position] and
  /// [buffered] (or not at all).
  bool differsOnlyInPosition(PlaybackSnapshot other) =>
      identical(other.queue, queue) &&
      other.current == current &&
      other.status == status &&
      other.playing == playing &&
      other.duration == duration &&
      other.quality == quality &&
      other.error == error &&
      other.isLocalFile == isLocalFile;

  @override
  String toString() =>
      'PlaybackSnapshot(${status.name}, playing: $playing, '
      'current: ${current?.queueItemId}, position: $position, '
      'error: $error)';
}

/// A one-shot message for the UI, on `PlaybackController.notices`.
sealed class PlaybackNotice {
  const new();
}

/// [count] items were left out because the queue holds at most
/// `QueueReducer.maxItems`.
final class ItemsDropped extends PlaybackNotice {
  /// Creates the notice for [count] dropped items.
  const new(this.count);

  /// How many items were left out.
  final int count;

  @override
  String toString() => 'ItemsDropped($count)';
}

/// The failed entry [queueItemId] was skipped (doc 06, Failure policy).
final class ItemSkipped extends PlaybackNotice {
  /// Creates the notice for the entry [queueItemId] that failed with [kind].
  const new(this.queueItemId, this.kind);

  /// The entry that was skipped.
  final String queueItemId;

  /// Why it failed.
  final PlaybackErrorKind kind;

  @override
  // Every field is final and the class is immutable.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      other is ItemSkipped &&
      other.queueItemId == queueItemId &&
      other.kind == kind;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes, see ==.
  int get hashCode => Object.hash(ItemSkipped, queueItemId, kind);

  @override
  String toString() => 'ItemSkipped($queueItemId, ${kind.name})';
}

/// Playback stopped because of [kind] (doc 06, Failure policy); the queue
/// is kept.
final class PlaybackStopped extends PlaybackNotice {
  /// Creates the notice.
  const new(this.kind);

  /// Why playback stopped.
  final PlaybackErrorKind kind;

  @override
  // Every field is final and the class is immutable.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      other is PlaybackStopped && other.kind == kind;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes, see ==.
  int get hashCode => Object.hash(PlaybackStopped, kind);

  @override
  String toString() => 'PlaybackStopped(${kind.name})';
}

/// Playback did not start because the OS denied audio focus (doc 06, Audio
/// Focus and Interruptions); the controller stays paused.
final class FocusDenied extends PlaybackNotice {
  /// Creates the notice.
  const new();

  @override
  // The class has no fields.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) => other is FocusDenied;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes, see ==.
  int get hashCode => (FocusDenied).hashCode;

  @override
  String toString() => 'FocusDenied()';
}

/// The queue entry [queueItemId] stopped being the one playing, on
/// `PlaybackController.entryEnded`: it finished ([natural]), or it was
/// skipped, replaced, removed, cleared or stopped. A repeat-one replay
/// ends the entry before it plays again.
final class EntryEnded {
  /// Creates the event for [queueItemId].
  const new(this.queueItemId, {required this.natural});

  /// The entry that ended.
  final String queueItemId;

  /// Whether it played to its end.
  final bool natural;

  @override
  // Every field is final and the class is immutable.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      other is EntryEnded &&
      other.queueItemId == queueItemId &&
      other.natural == natural;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes, see ==.
  int get hashCode => Object.hash(queueItemId, natural);

  @override
  String toString() => 'EntryEnded($queueItemId, natural: $natural)';
}
