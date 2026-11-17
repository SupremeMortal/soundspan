// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The intents of the desktop shortcuts (doc 09, Desktop Interaction).
///
/// `shortcutBindings` maps keys to them; the shell's actions and the track
/// lists' row actions handle them. An intent no action handles leaves its
/// key to the widgets above.
library;

import 'package:flutter/widgets.dart';

/// Plays or pauses the current item.
class TogglePlayPauseIntent extends Intent {
  /// Creates the intent.
  const new();
}

/// Skips to the next item.
class NextTrackIntent extends Intent {
  /// Creates the intent.
  const new();
}

/// Goes to the previous item.
class PreviousTrackIntent extends Intent {
  /// Creates the intent.
  const new();
}

/// Moves the position of the current item by [offset], clamped to the item.
class SeekByIntent extends Intent {
  /// Creates the intent moving by [offset].
  const new(this.offset);

  /// How far to move; negative moves back.
  final Duration offset;
}

/// Changes the volume by [delta], clamped to 0–1.
class ChangeVolumeIntent extends Intent {
  /// Creates the intent changing the volume by [delta].
  const new(this.delta);

  /// The change, as a fraction of full volume.
  final double delta;
}

/// Turns shuffle on or off.
class ToggleShuffleIntent extends Intent {
  /// Creates the intent.
  const new();
}

/// Sets the next repeat mode: off, all, one, off.
class CycleRepeatIntent extends Intent {
  /// Creates the intent.
  const new();
}

/// Likes or removes the like of the current track; nothing for an episode.
class ToggleLikeCurrentIntent extends Intent {
  /// Creates the intent.
  const new();
}

/// Focuses the search field, opening Search when no field is on screen.
class FocusSearchIntent extends Intent {
  /// Creates the intent.
  const new();
}

/// Opens the top-level destination at [index] (Home, Search, Library,
/// Podcasts).
class GoToDestinationIntent extends Intent {
  /// Creates the intent opening destination [index].
  const new(this.index);

  /// The index of the destination.
  final int index;
}

/// Toggles the queue: the right panel on expanded windows, the queue sheet
/// otherwise.
class ToggleQueueIntent extends Intent {
  /// Creates the intent.
  const new();
}

/// Goes back in the current branch.
class NavigateBackIntent extends Intent {
  /// Creates the intent.
  const new();
}

/// Re-opens the location last left with Back.
class NavigateForwardIntent extends Intent {
  /// Creates the intent.
  const new();
}

/// Opens Settings.
class OpenSettingsIntent extends Intent {
  /// Creates the intent.
  const new();
}

/// Plays the focused row, or the selection it belongs to.
class PlayRowIntent extends Intent {
  /// Creates the intent.
  const new();
}

/// Queues the focused row, or the selection it belongs to, after the
/// current item.
class PlayRowNextIntent extends Intent {
  /// Creates the intent.
  const new();
}

/// Removes the focused row, or the selection it belongs to, from the
/// playlist the user owns.
class RemoveRowIntent extends Intent {
  /// Creates the intent.
  const new();
}

/// Opens the menu of the focused row or card.
class OpenMenuIntent extends Intent {
  /// Creates the intent.
  const new();
}

/// Refreshes the screen shown.
class RefreshIntent extends Intent {
  /// Creates the intent.
  const new();
}

/// Moves focus to the next focus group of the shell, or the previous one
/// when [backward].
class CycleFocusGroupIntent extends Intent {
  /// Creates the intent.
  const new({this.backward = false});

  /// Whether focus moves to the previous group.
  final bool backward;
}
