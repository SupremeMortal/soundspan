// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/shared/domain/queue_item.dart';

/// A change to the play queue, applied by `QueueReducer` (doc 06, Queue
/// Model). Commands address entries by `queueItemId`, never by track.
sealed class QueueCommand {
  /// Creates a command.
  const new();
}

/// Replaces the queue with [items] and starts at [startIndex].
final class ReplaceAll extends QueueCommand {
  /// Creates a replace command.
  const new(this.items, {this.startIndex = 0, this.context});

  /// The new entries, in canonical order.
  final List<QueueItem> items;

  /// The play index of the entry to start with; clamped into range.
  final int startIndex;

  /// What "Play" was pressed on.
  final QueueContext? context;
}

/// Inserts [items] directly after the current entry.
final class PlayNext extends QueueCommand {
  /// Creates a play-next command.
  const new(this.items);

  /// The entries to insert, in order.
  final List<QueueItem> items;
}

/// Adds [items] at the end of the queue.
final class Append extends QueueCommand {
  /// Creates an append command.
  const new(this.items);

  /// The entries to add, in order.
  final List<QueueItem> items;
}

/// Removes the entry [queueItemId].
final class RemoveAt extends QueueCommand {
  /// Creates a remove command.
  const new(this.queueItemId);

  /// The entry to remove.
  final String queueItemId;
}

/// Moves the entry [queueItemId] to [toPlayIndex] of the play order.
final class Move extends QueueCommand {
  /// Creates a move command.
  const new(this.queueItemId, this.toPlayIndex);

  /// The entry to move.
  final String queueItemId;

  /// The play index the entry ends up at; clamped into range.
  final int toPlayIndex;
}

/// Makes the entry [queueItemId] current.
final class JumpTo extends QueueCommand {
  /// Creates a jump command.
  const new(this.queueItemId);

  /// The entry to play.
  final String queueItemId;
}

/// Moves to the next entry in play order.
final class Next extends QueueCommand {
  /// Creates a next command.
  const new();
}

/// Goes back: restarts the current entry when it has played for more than
/// `QueueReducer.previousRestartThreshold`, else moves to the previous entry
/// in play order.
final class Previous extends QueueCommand {
  /// Creates a previous command.
  const new(this.position);

  /// How far the current entry has played.
  final Duration position;
}

/// Turns shuffle on or off.
final class SetShuffle extends QueueCommand {
  /// Creates a shuffle command.
  const new(this.enabled);

  /// Whether the play order is shuffled.
  final bool enabled;
}

/// Sets the repeat mode.
final class SetRepeat extends QueueCommand {
  /// Creates a repeat command.
  const new(this.mode);

  /// The new repeat mode.
  final RepeatMode mode;
}

/// Empties the queue.
final class Clear extends QueueCommand {
  /// Creates a clear command.
  const new();
}

/// Reports that the entry [queueItemId] played to its end.
final class ItemFinished extends QueueCommand {
  /// Creates an item-finished command.
  const new(this.queueItemId);

  /// The entry that finished.
  final String queueItemId;
}
