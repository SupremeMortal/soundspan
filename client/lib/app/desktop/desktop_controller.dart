// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/app/app.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/placeholder_screen.dart';
import 'package:soundspan/app/shell/window_state_controller.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/storage/app/app_settings_store.dart';
import 'package:soundspan/core/storage/providers.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';
import 'package:soundspan/platform/desktop_shell/desktop_shell.dart';
import 'package:soundspan/shared/domain/queue_item.dart';

final AppLogger _log = AppLogger.scope('Desktop');

/// The localized texts of the tray and the window title.
@immutable
final class DesktopTexts {
  /// Creates the texts.
  const new({
    required this.tray,
    required this.nowPlaying,
    required this.windowTitle,
    required this.screenTitle,
    required this.appTitle,
  });

  /// The texts of [l10n].
  factory of(AppLocalizations l10n) => DesktopTexts(
    tray: TrayLabels(
      play: l10n.trayPlay,
      pause: l10n.trayPause,
      next: l10n.shortcutNext,
      previous: l10n.shortcutPrevious,
      showWindow: l10n.trayShowWindow,
      quit: l10n.trayQuit,
      tooltip: l10n.appTitle,
    ),
    nowPlaying: l10n.trayNowPlaying,
    windowTitle: l10n.windowTitleNowPlaying,
    screenTitle: l10n.windowTitle,
    appTitle: l10n.appTitle,
  );

  /// The tray menu's texts.
  final TrayLabels tray;

  /// "Title — Artist", the tray's label of the current item.
  final String Function(String title, String artist) nowPlaying;

  /// "Title — Artist · soundspan", the window title while playing.
  final String Function(String title, String artist) windowTitle;

  /// "Name · soundspan", the window title of an item with no artist.
  final String Function(String name) screenTitle;

  /// The window title before any screen set one.
  final String appTitle;
}

/// What closing the window does when no tray can hold the app and
/// something is playing.
enum KeepPlayingAnswer {
  /// Minimise the window; playback continues.
  keepPlaying,

  /// Quit the app.
  quit,
}

/// Whether closing the window hides it to the tray when `closeToTray` is
/// not stored: on Windows and Linux; macOS keeps the app in the Dock
/// instead (doc 06, Background Behaviour by Platform).
bool closeToTrayDefault(TargetPlatform platform) => switch (platform) {
  TargetPlatform.windows || TargetPlatform.linux => true,
  _ => false,
};

/// The stored `closeToTray`, or its default on this platform when not
/// stored.
final StreamProvider<bool> closeToTraySettingProvider = StreamProvider<bool>(
  (ref) => ref
      .watch(appSettingsProvider)
      .watch(AppSettingKeys.closeToTray)
      .map((value) => value ?? closeToTrayDefault(defaultTargetPlatform)),
);

/// The stored `window.useSystemTitleBar`; off when not stored.
final StreamProvider<bool> useSystemTitleBarSettingProvider =
    StreamProvider<bool>(
      (ref) => ref
          .watch(appSettingsProvider)
          .watch(AppSettingKeys.useSystemTitleBar)
          .map((value) => value ?? false),
    );

/// The tray, the window title and what closing the window does on desktop
/// platforms (doc 09, Desktop Interaction; doc 10).
///
/// [start] runs in bootstrap step 5 (doc 02) after the window is restored;
/// [bind] follows the active profile's [PlaybackController].
class DesktopController {
  /// Creates the controller of [shell] on [platform], keeping `closeToTray`
  /// in [settings]. [texts] gives the localized texts each time they are
  /// shown; [onTrayHost] hears whether the tray icon was created;
  /// [saveWindow] stores the window state before the app quits.
  new({
    required this.shell,
    required this.settings,
    required this.platform,
    required this.texts,
    this.onTrayHost,
    this.saveWindow,
  });

  /// The window and tray.
  final DesktopShell shell;

  /// Where `closeToTray` is kept.
  final AppSettingsStore settings;

  /// The operating system the app runs on.
  final TargetPlatform platform;

  /// The localized texts, read each time they are shown.
  final DesktopTexts Function() texts;

  /// Hears whether the tray icon was created.
  final void Function(bool available)? onTrayHost;

  /// Stores the window state before the app quits.
  final Future<void> Function()? saveWindow;

  /// Asks "Keep playing in the background?" when the window is closed with
  /// no tray and something playing; null (or a dismissed question) leaves
  /// the window open. The app's root widget sets it.
  Future<KeepPlayingAnswer?> Function()? askKeepPlaying;

  final List<StreamSubscription<Object?>> _subscriptions = [];
  StreamSubscription<PlaybackSnapshot>? _snapshots;
  PlaybackController? _controller;
  Future<void> Function()? _flush;
  bool _started = false;
  bool _hasTray = false;
  bool _quitting = false;
  TrayModel? _pushedTray;
  String? _pushedTitle;
  String? _routeTitle;

  /// Whether the tray icon was created.
  bool get hasTray => _hasTray;

  /// Creates the tray icon where there is one, takes over closing the
  /// window and starts following the tray's commands.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    final traySupported =
        platform == TargetPlatform.windows || platform == TargetPlatform.linux;
    _hasTray = traySupported && await shell.initTray();
    if (traySupported) onTrayHost?.call(_hasTray);
    await shell.setPreventClose(true);
    _subscriptions.addAll([
      shell.closeRequests.listen((_) => unawaited(_guard(handleClose))),
      shell.trayCommands.listen(
        (command) => unawaited(_guard(() => _onTrayCommand(command))),
      ),
    ]);
    _render(_controller?.snapshot);
  }

  /// Follows [controller], whose queue [flush] writes at once; null when no
  /// profile is active.
  void bind(PlaybackController? controller, {Future<void> Function()? flush}) {
    unawaited(_snapshots?.cancel());
    _snapshots = null;
    _controller = controller;
    _flush = flush;
    if (controller != null) {
      _snapshots = controller.snapshots.listen(_render);
    }
    _render(controller?.snapshot);
  }

  /// Records the title the shown screen gives the window, which the window
  /// shows while nothing plays.
  void setRouteTitle(String title) {
    _routeTitle = title;
    _render(_controller?.snapshot);
  }

  /// What closing the window does (doc 10): macOS hides it; with a tray it
  /// hides when `closeToTray` is on and quits otherwise; without a tray it
  /// asks whether to keep playing when something plays, and quits when
  /// nothing does.
  Future<void> handleClose() async {
    if (_quitting) return;
    if (platform == TargetPlatform.macOS) return await shell.hide();
    if (_hasTray) {
      final closeToTray =
          await settings.read(AppSettingKeys.closeToTray) ??
          closeToTrayDefault(platform);
      return closeToTray ? await shell.hide() : await quit();
    }
    if (!(_controller?.snapshot.playing ?? false)) return await quit();
    final answer = await askKeepPlaying?.call();
    switch (answer) {
      case KeepPlayingAnswer.keepPlaying:
        await shell.minimize();
      case KeepPlayingAnswer.quit:
        await quit();
      case null:
        break;
    }
  }

  /// Quits the app: pauses playback, so the queue keeps its position,
  /// writes the queue and the window state, then ends the app.
  Future<void> quit() async {
    if (_quitting) return;
    _quitting = true;
    final controller = _controller;
    if (controller != null) {
      await _guard(() async {
        await controller.pause();
        await controller.settled;
      });
    }
    await _guard(() async => await _flush?.call());
    await _guard(() async => await saveWindow?.call());
    await shell.quit();
  }

  Future<void> _onTrayCommand(TrayCommand command) async {
    final controller = _controller;
    final hasQueue = controller?.snapshot.current != null;
    switch (command) {
      case TrayCommand.playPause when hasQueue:
        await controller!.togglePlayPause();
      case TrayCommand.next when hasQueue:
        await controller!.next();
      case TrayCommand.previous when hasQueue:
        await controller!.previous();
      case TrayCommand.showWindow:
        await shell.showAndFocus();
      case TrayCommand.quit:
        await quit();
      case TrayCommand.playPause || TrayCommand.next || TrayCommand.previous:
        break;
    }
  }

  /// Pushes the tray model and the window title when they changed; a
  /// position tick changes neither.
  void _render(PlaybackSnapshot? snapshot) {
    if (!_started) return;
    final texts = this.texts();
    final names = switch (snapshot?.current) {
      TrackQueueItem(:final track) => (track.meta.title, track.meta.artist),
      EpisodeQueueItem(:final episode, :final podcast) => (
        episode.title,
        podcast.title,
      ),
      null => null,
    };
    final playing = snapshot?.playing ?? false;
    if (_hasTray) {
      final model = TrayModel(
        labels: texts.tray,
        nowPlayingLabel: switch (names) {
          null => null,
          (final title, '') => title,
          (final title, final artist) => texts.nowPlaying(title, artist),
        },
        playing: playing,
        hasQueue: names != null,
      );
      if (model != _pushedTray) {
        _pushedTray = model;
        unawaited(_guard(() => shell.setTray(model)));
      }
    }
    final title = switch (names) {
      (final name, '') when playing => texts.screenTitle(name),
      (final name, final artist) when playing => texts.windowTitle(
        name,
        artist,
      ),
      _ => _routeTitle ?? texts.appTitle,
    };
    if (title != _pushedTitle) {
      _pushedTitle = title;
      unawaited(_guard(() => shell.setTitle(title)));
    }
  }

  static Future<void> _guard(Future<void> Function() step) async {
    try {
      await step();
    } on Object catch (error, stackTrace) {
      _log.warning('Desktop step failed', const {}, error, stackTrace);
    }
  }

  /// Stops following the shell and the controller.
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    unawaited(_snapshots?.cancel());
    _snapshots = null;
  }
}

/// The app's [DesktopController]; null on a platform that is not a desktop.
final Provider<DesktopController?> desktopControllerProvider =
    Provider<DesktopController?>((ref) {
      if (!ref.watch(platformCapabilitiesProvider.select((c) => c.isDesktop))) {
        return null;
      }
      final controller = DesktopController(
        shell: ref.watch(desktopShellProvider),
        settings: ref.watch(appSettingsProvider),
        platform: defaultTargetPlatform,
        texts: () => DesktopTexts.of(
          lookupAppLocalizations(
            ref.read(localeSettingProvider).value ?? const Locale('en'),
          ),
        ),
        onTrayHost: (available) =>
            ref.read(trayHostProvider.notifier).available = available,
        saveWindow: () => ref.read(windowStateControllerProvider).save(),
      );
      final routeTitle = ref.watch(routeTitleProvider);
      void onRouteTitle() {
        final title = routeTitle.value;
        if (title != null) controller.setRouteTitle(title);
      }

      routeTitle.addListener(onRouteTitle);
      onRouteTitle();
      ref.onDispose(() {
        routeTitle.removeListener(onRouteTitle);
        controller.dispose();
      });
      return controller;
    });

/// Desktop only (doc 02, step 5): starts [desktopControllerProvider] and
/// binds it to the playback controller of every profile that becomes
/// active in [root].
Future<void> startDesktop(ProviderContainer root) async {
  final desktop = root.read(desktopControllerProvider);
  if (desktop == null) return;
  await desktop.start();
  final runtime = root.read(profileRuntimeProvider);
  ProviderContainer? bound;
  var first = true;
  void onState() {
    final container = runtime.state.value is ProfileRuntimeActive
        ? runtime.container
        : null;
    if (!first && identical(container, bound)) return;
    first = false;
    bound = container;
    if (container == null) return desktop.bind(null);
    desktop.bind(
      container.read(playbackControllerProvider),
      flush: () => container.read(queuePersistenceProvider).flush(),
    );
  }

  runtime.state.addListener(onState);
  onState();
}
