// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// What the Windows System Media Transport Controls offer (doc 06, OS Media
/// Controls; Spike S4 finding), as a seam so `SmtcControls` runs without
/// Windows.
library;

/// A button of the Windows media flyout or a media key.
enum SmtcButton {
  /// Play.
  play,

  /// Pause.
  pause,

  /// Next track.
  next,

  /// Previous track.
  previous,

  /// Stop.
  stop,

  /// Fast forward.
  fastForward,

  /// Rewind.
  rewind,
}

/// The playback status the flyout shows.
enum SmtcStatus {
  /// No media.
  closed,

  /// Stopped.
  stopped,

  /// Paused.
  paused,

  /// Playing.
  playing,

  /// Changing between items or waiting for data.
  changing,
}

/// The System Media Transport Controls of the process.
abstract interface class SmtcGateway {
  /// Registers the session for the process's app user model id.
  Future<void> init();

  /// The buttons the user presses.
  Stream<SmtcButton> get buttonPresses;

  /// Positions the user asks to move to; empty if the binding has none.
  Stream<Duration> get seekRequests;

  /// Enables exactly [buttons].
  Future<void> setEnabledButtons(Set<SmtcButton> buttons);

  /// Shows a music item; [thumbnail] is a `file://` URI, or null for none.
  Future<void> setMetadata({
    required String title,
    required String artist,
    required String album,
    Uri? thumbnail,
  });

  /// Shows [status].
  Future<void> setStatus(SmtcStatus status);

  /// Shows [position] within an item of [duration], when known.
  Future<void> setTimeline({
    required Duration position,
    required Duration? duration,
  });

  /// Removes the item shown.
  Future<void> clear();

  /// Unregisters the session.
  Future<void> dispose();
}
