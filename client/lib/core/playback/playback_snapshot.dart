// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/core/playback/stream_quality_info.dart';
import 'package:soundspan/shared/domain/queue_item.dart';

/// The kind of a [PlaybackError].
enum PlaybackErrorKind {
  /// The engine could not play the item.
  itemFailed,

  /// The item cannot be streamed at all (it has no `playbackId`).
  itemUnavailable,
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
