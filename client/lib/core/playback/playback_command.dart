// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/shared/domain/queue_item.dart';

/// One user action on playback, applied by `PlaybackController.dispatch`
/// one at a time in arrival order.
sealed class PlaybackCommand {
  const new();
}

/// Replaces the queue with [items] and plays from [startIndex].
final class PlayItemsCommand extends PlaybackCommand {
  /// Creates the command.
  const new(this.items, {this.startIndex = 0, this.context});

  /// The new entries, in canonical order.
  final List<QueueItem> items;

  /// The play index of the entry to start with.
  final int startIndex;

  /// What "Play" was pressed on.
  final QueueContext? context;
}

/// Plays the current item.
final class PlayCommand extends PlaybackCommand {
  /// Creates the command.
  const new();
}

/// Who paused playback.
enum PauseOrigin {
  /// The user, or anything acting for them: the UI, OS media controls.
  user,

  /// The audio-focus rules (doc 06, Audio Focus and Interruptions): an
  /// interruption, or the output becoming noisy.
  focus,
}

/// Pauses, keeping the position.
final class PauseCommand extends PlaybackCommand {
  /// Creates the command; [origin] is who paused.
  const new({this.origin = PauseOrigin.user});

  /// Who paused.
  final PauseOrigin origin;
}

/// Pauses when playing, else plays.
final class TogglePlayPauseCommand extends PlaybackCommand {
  /// Creates the command.
  const new();
}

/// Moves to [position] in the current item.
final class SeekCommand extends PlaybackCommand {
  /// Creates the command.
  const new(this.position);

  /// Where to move to.
  final Duration position;
}

/// Skips to the next item in play order.
final class NextCommand extends PlaybackCommand {
  /// Creates the command.
  const new();
}

/// Restarts the current item or goes back one, by the queue's rule.
final class PreviousCommand extends PlaybackCommand {
  /// Creates the command.
  const new();
}

/// Plays the entry [queueItemId].
final class JumpToCommand extends PlaybackCommand {
  /// Creates the command.
  const new(this.queueItemId);

  /// The entry to play.
  final String queueItemId;
}

/// Inserts [items] directly after the current entry.
final class PlayNextCommand extends PlaybackCommand {
  /// Creates the command.
  const new(this.items);

  /// The entries to insert, in order.
  final List<QueueItem> items;
}

/// Adds [items] at the end of the queue.
final class AppendCommand extends PlaybackCommand {
  /// Creates the command.
  const new(this.items);

  /// The entries to add, in order.
  final List<QueueItem> items;
}

/// Inserts [items] at [playOrderIndex] of the play order.
final class InsertAtCommand extends PlaybackCommand {
  /// Creates the command.
  const new(this.items, this.playOrderIndex);

  /// The entries to insert, in order.
  final List<QueueItem> items;

  /// The play index the first entry ends up at.
  final int playOrderIndex;
}

/// Removes the entry [queueItemId].
final class RemoveAtCommand extends PlaybackCommand {
  /// Creates the command.
  const new(this.queueItemId);

  /// The entry to remove.
  final String queueItemId;
}

/// Moves the entry [queueItemId] to [toPlayIndex] of the play order.
final class MoveCommand extends PlaybackCommand {
  /// Creates the command.
  const new(this.queueItemId, this.toPlayIndex);

  /// The entry to move.
  final String queueItemId;

  /// The play index it ends up at.
  final int toPlayIndex;
}

/// Turns shuffle on or off.
final class SetShuffleCommand extends PlaybackCommand {
  /// Creates the command.
  const new(this.enabled);

  /// Whether the play order is shuffled.
  final bool enabled;
}

/// Sets the repeat mode.
final class SetRepeatCommand extends PlaybackCommand {
  /// Creates the command.
  const new(this.mode);

  /// The new repeat mode.
  final RepeatMode mode;
}

/// Empties the queue and stops.
final class ClearCommand extends PlaybackCommand {
  /// Creates the command.
  const new();
}

/// Stops playback and releases the sources; the queue is kept.
final class StopCommand extends PlaybackCommand {
  /// Creates the command.
  const new();
}

/// Sets the user volume.
final class SetVolumeCommand extends PlaybackCommand {
  /// Creates the command.
  const new(this.volume);

  /// The user volume, 0.0–1.0.
  final double volume;
}
