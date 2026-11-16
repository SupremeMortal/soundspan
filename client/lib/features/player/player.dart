// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The player: the player bar on expanded windows, the mini player on
/// compact and medium ones, and the seek bar they share (doc 09,
/// Components).
library;

export 'ui/mini_player.dart' show MiniPlayer;
export 'ui/player_bar.dart' show PlayPauseButton, PlayerBar, nextRepeatMode;
export 'ui/seek_bar.dart' show SeekBar;
