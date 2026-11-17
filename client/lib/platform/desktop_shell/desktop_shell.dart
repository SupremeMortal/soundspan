// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The window and tray seam of the desktop app (doc 02, Platform Seams;
/// doc 10).
///
/// `createDesktopShell()` returns the `window_manager` and `tray_manager`
/// implementation on Windows, Linux and macOS, and a no-op on Android, iOS
/// and web.
library;

import 'dart:ui' show Rect, Size;

import 'package:flutter/foundation.dart' show immutable;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/storage/app/app_settings_store.dart'
    show WindowBounds;
import 'package:soundspan/platform/desktop_shell/desktop_shell_web.dart'
    if (dart.library.io) 'package:soundspan/platform/desktop_shell/desktop_shell_io.dart';

export 'package:soundspan/core/storage/app/app_settings_store.dart'
    show WindowBounds;

export 'desktop_shell_web.dart'
    if (dart.library.io) 'desktop_shell_io.dart'
    show createDesktopShell;

/// The method channel on which the native runner forwards a second launch
/// (Windows `WM_COPYDATA`, Linux `GApplication` activate and open).
const String singleInstanceChannel = 'io.soundspan.app/single_instance';

/// The method of [singleInstanceChannel]; its argument is the second
/// launch's argument list.
const String secondInstanceMethod = 'secondInstance';

/// What a tray menu entry does when clicked.
enum TrayCommand {
  /// Plays or pauses the current item.
  playPause,

  /// Skips to the next item.
  next,

  /// Goes to the previous item.
  previous,

  /// Shows the window; also what a left click on the icon does.
  showWindow,

  /// Quits the app.
  quit,
}

/// The localized texts of the tray menu.
@immutable
final class TrayLabels {
  /// Creates the texts.
  const new({
    required this.play,
    required this.pause,
    required this.next,
    required this.previous,
    required this.showWindow,
    required this.quit,
    required this.tooltip,
  });

  /// The Play/Pause entry while paused.
  final String play;

  /// The Play/Pause entry while playing.
  final String pause;

  /// The Next entry.
  final String next;

  /// The Previous entry.
  final String previous;

  /// The Show window entry.
  final String showWindow;

  /// The Quit entry.
  final String quit;

  /// The icon's tooltip.
  final String tooltip;

  @override
  bool operator ==(Object other) =>
      other is TrayLabels &&
      other.play == play &&
      other.pause == pause &&
      other.next == next &&
      other.previous == previous &&
      other.showWindow == showWindow &&
      other.quit == quit &&
      other.tooltip == tooltip;

  @override
  int get hashCode =>
      Object.hash(play, pause, next, previous, showWindow, quit, tooltip);
}

/// One line of the tray menu.
@immutable
final class TrayEntry {
  /// Creates an entry showing [label] that sends [command]; an entry
  /// without a command is a label.
  const new(this.label, {this.command, this.enabled = true});

  /// The text shown.
  final String label;

  /// What a click sends; null for a label.
  final TrayCommand? command;

  /// Whether the entry can be clicked.
  final bool enabled;

  @override
  bool operator ==(Object other) =>
      other is TrayEntry &&
      other.label == label &&
      other.command == command &&
      other.enabled == enabled;

  @override
  int get hashCode => Object.hash(label, command, enabled);

  @override
  String toString() =>
      'TrayEntry($label, ${command?.name ?? 'label'}'
      '${enabled ? '' : ', disabled'})';
}

/// What the tray shows (doc 09, Desktop Interaction).
@immutable
final class TrayModel {
  /// Creates the model.
  const new({
    required this.labels,
    this.nowPlayingLabel,
    this.playing = false,
    this.hasQueue = false,
  });

  /// The menu's texts.
  final TrayLabels labels;

  /// "Title — Artist" of the current item; null without one.
  final String? nowPlayingLabel;

  /// Whether playback is running.
  final bool playing;

  /// Whether the queue has a current item.
  final bool hasQueue;

  /// The menu, in order: Play/Pause, Next, Previous, the current item as a
  /// disabled label (left out with an empty queue), Show window, Quit. The
  /// transport entries are disabled with an empty queue.
  List<TrayEntry> get entries => [
    TrayEntry(
      playing ? labels.pause : labels.play,
      command: TrayCommand.playPause,
      enabled: hasQueue,
    ),
    TrayEntry(labels.next, command: TrayCommand.next, enabled: hasQueue),
    TrayEntry(
      labels.previous,
      command: TrayCommand.previous,
      enabled: hasQueue,
    ),
    if (hasQueue && nowPlayingLabel != null)
      TrayEntry(nowPlayingLabel!, enabled: false),
    TrayEntry(labels.showWindow, command: TrayCommand.showWindow),
    TrayEntry(labels.quit, command: TrayCommand.quit),
  ];

  @override
  bool operator ==(Object other) =>
      other is TrayModel &&
      other.labels == labels &&
      other.nowPlayingLabel == nowPlayingLabel &&
      other.playing == playing &&
      other.hasQueue == hasQueue;

  @override
  int get hashCode => Object.hash(labels, nowPlayingLabel, playing, hasQueue);
}

/// The app's top-level window: geometry, visibility, title, tray and
/// second launches.
abstract interface class DesktopShell {
  /// Prepares the window plugin; called once before any other member.
  Future<void> init();

  /// Stops the window from becoming smaller than [size].
  Future<void> setMinimumSize(Size size);

  /// The window's normal (not maximized) bounds, or null when unknown.
  Future<WindowBounds?> getBounds();

  /// Moves and resizes the window to [bounds].
  Future<void> setBounds(WindowBounds bounds);

  /// Whether the window is maximized.
  Future<bool> isMaximized();

  /// Maximizes the window.
  Future<void> maximize();

  /// Shows the window, restores it if minimized, and gives it focus.
  Future<void> showAndFocus();

  /// The visible areas of every connected display; the primary first.
  Future<List<Rect>> displayAreas();

  /// Emits when the window was moved, resized, maximized or restored.
  Stream<void> get geometryChanges;

  /// Emits when the user asked to close the window.
  Stream<void> get closeRequests;

  /// Emits the argument list of each later launch of the app.
  Stream<List<String>> get secondInstanceLaunches;

  /// Whether a close request leaves the window open, so the app decides
  /// what closing does; off by default.
  Future<void> setPreventClose(bool prevent);

  /// Hides the window; the app keeps running.
  Future<void> hide();

  /// Minimizes the window.
  Future<void> minimize();

  /// Closes the window and ends the app.
  Future<void> quit();

  /// Sets the window's title.
  Future<void> setTitle(String title);

  /// Creates the tray icon; false when the platform has no tray host (on
  /// Linux, no StatusNotifier host answered) and on macOS.
  Future<bool> initTray();

  /// Shows [model] in the tray icon's menu.
  Future<void> setTray(TrayModel model);

  /// The commands of the tray icon and its menu.
  Stream<TrayCommand> get trayCommands;
}

/// A [DesktopShell] that does nothing: Android, iOS and web.
class NoopDesktopShell implements DesktopShell {
  /// Creates the no-op shell.
  const new();

  @override
  Future<void> init() async {}

  @override
  Future<void> setMinimumSize(Size size) async {}

  @override
  Future<WindowBounds?> getBounds() async => null;

  @override
  Future<void> setBounds(WindowBounds bounds) async {}

  @override
  Future<bool> isMaximized() async => false;

  @override
  Future<void> maximize() async {}

  @override
  Future<void> showAndFocus() async {}

  @override
  Future<List<Rect>> displayAreas() async => const [];

  @override
  Stream<void> get geometryChanges => const Stream.empty();

  @override
  Stream<void> get closeRequests => const Stream.empty();

  @override
  Stream<List<String>> get secondInstanceLaunches => const Stream.empty();

  @override
  Future<void> setPreventClose(bool prevent) async {}

  @override
  Future<void> hide() async {}

  @override
  Future<void> minimize() async {}

  @override
  Future<void> quit() async {}

  @override
  Future<void> setTitle(String title) async {}

  @override
  Future<bool> initTray() async => false;

  @override
  Future<void> setTray(TrayModel model) async {}

  @override
  Stream<TrayCommand> get trayCommands => const Stream.empty();
}

/// The app's [DesktopShell]; tests override it.
final Provider<DesktopShell> desktopShellProvider = Provider<DesktopShell>(
  (ref) => createDesktopShell(),
);
