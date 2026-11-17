// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the right-hand panel of expanded windows shows (doc 09, Shell by
/// Window Class).
enum RightPanel {
  /// No panel.
  none,

  /// The queue.
  queue,

  /// The lyrics.
  lyrics,
}

/// The right-hand panel of expanded windows; [RightPanel.none] at start.
class RightPanelNotifier extends Notifier<RightPanel> {
  @override
  RightPanel build() => RightPanel.none;

  /// Shows [panel], or closes it when it is the one shown.
  void toggle(RightPanel panel) =>
      state = state == panel ? RightPanel.none : panel;

  /// Closes the panel.
  void close() => state = RightPanel.none;
}

/// The right-hand panel of the shell; a root provider, so it outlives the
/// pages beside it.
final NotifierProvider<RightPanelNotifier, RightPanel> rightPanelProvider =
    NotifierProvider<RightPanelNotifier, RightPanel>(RightPanelNotifier.new);

/// Whether the now-playing overlay covers the content area of expanded
/// windows; false at start.
class NowPlayingOverlayNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Shows the overlay when hidden and hides it when shown.
  void toggle() => state = !state;

  /// Hides the overlay.
  void close() => state = false;
}

/// Whether the now-playing overlay is shown; a root provider like
/// [rightPanelProvider].
final NotifierProvider<NowPlayingOverlayNotifier, bool>
nowPlayingOverlayProvider = NotifierProvider<NowPlayingOverlayNotifier, bool>(
  NowPlayingOverlayNotifier.new,
);
