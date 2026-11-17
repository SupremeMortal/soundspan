// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/shared/domain/queue_item.dart';

/// How an attached `RemoteDriver` applies the state it receives, such as
/// Listen Together applying the group's state (doc 06, Listen Together
/// Hook; doc 08, Applying State).
///
/// Every call acts on the queue and the engine directly, bypassing the
/// routing of commands to the driver, and runs after the steps queued
/// before it. Obtained from `PlaybackController.remote` while a driver is
/// attached.
abstract interface class RemotePlayback {
  /// Replaces the queue with [items], unshuffled and without repeat, with
  /// the cursor at [cursor] (clamped). The current item keeps playing when
  /// it is the same entry as before; otherwise the engine stops and nothing
  /// is loaded until [loadCurrent] or [play]. Empty [items] clear the
  /// queue.
  Future<void> replaceQueue(List<QueueItem> items, int cursor);

  /// Loads the current item at [position], playing when [play] is true and
  /// paused otherwise.
  Future<void> loadCurrent({required Duration position, required bool play});

  /// Plays the current item, loading it first when nothing is loaded.
  Future<void> play();

  /// Pauses, keeping the position.
  Future<void> pause();

  /// Moves to [position] in the current item.
  Future<void> seek(Duration position);
}
