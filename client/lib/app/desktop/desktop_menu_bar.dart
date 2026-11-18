// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/desktop/desktop_controller.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/shell/shortcuts/shortcut_bindings.dart';
import 'package:soundspan/app/shell/shortcuts/shortcut_intents.dart';
import 'package:soundspan/core/playback/playback_providers.dart';

/// The macOS menu bar (doc 10, macOS): the application menu (About,
/// Settings…, Quit), Playback (Play/Pause, Next, Previous, Shuffle,
/// Repeat), View (Queue, Lyrics) and Window (Minimise, Zoom), around
/// [child]. Elsewhere it is [child] alone.
///
/// Each item invokes the intent of its shortcut binding through the
/// enclosing `Actions` and shows that binding's keys; a binding limited to
/// outside text fields shows none, as a menu key equivalent would take the
/// key from a text field too. Items whose action is unavailable, the
/// playback items and Lyrics with an empty queue among them, are disabled.
class DesktopMenuBar extends ConsumerWidget {
  /// Creates the menu bar around [child].
  const new({required this.child, super.key});

  /// The shell.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (defaultTargetPlatform != TargetPlatform.macOS) return child;
    final l10n = AppLocalizations.of(context);
    // Rebuilt when the current item changes, as the actions' availability
    // follows it.
    final current = ref.watch(playbackControllerProvider.exists)
        ? ref.watch(
            playbackStateProvider.select((state) => state.value?.current),
          )
        : null;
    final hasQueue = current != null;

    PlatformMenuItem item(
      String label,
      Intent intent, {
      bool needsQueue = false,
    }) {
      final enabled =
          (!needsQueue || hasQueue) &&
          (Actions.maybeFind<Intent>(
                context,
                intent: intent,
              )?.isEnabled(intent) ??
              false);
      return PlatformMenuItem(
        label: label,
        shortcut: menuShortcutOf(intent),
        onSelected: enabled ? () => Actions.invoke(context, intent) : null,
      );
    }

    return PlatformMenuBar(
      menus: [
        PlatformMenu(
          label: l10n.appTitle,
          menus: [
            PlatformMenuItemGroup(
              members: [
                if (PlatformProvidedMenuItem.hasMenu(
                  PlatformProvidedMenuItemType.about,
                ))
                  const PlatformProvidedMenuItem(
                    type: PlatformProvidedMenuItemType.about,
                  ),
              ],
            ),
            PlatformMenuItemGroup(
              members: [item(l10n.menuSettings, const OpenSettingsIntent())],
            ),
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: l10n.menuQuit,
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyQ,
                    meta: true,
                  ),
                  // Read on selection: the controller needs `app.db`.
                  onSelected: () {
                    final desktop = ref.read(desktopControllerProvider);
                    if (desktop != null) unawaited(desktop.quit());
                  },
                ),
              ],
            ),
          ],
        ),
        PlatformMenu(
          label: l10n.menuPlayback,
          menus: [
            item(
              l10n.menuPlayPause,
              const TogglePlayPauseIntent(),
              needsQueue: true,
            ),
            item(l10n.menuNext, const NextTrackIntent(), needsQueue: true),
            item(
              l10n.menuPrevious,
              const PreviousTrackIntent(),
              needsQueue: true,
            ),
            item(
              l10n.menuShuffle,
              const ToggleShuffleIntent(),
              needsQueue: true,
            ),
            item(l10n.menuRepeat, const CycleRepeatIntent(), needsQueue: true),
          ],
        ),
        PlatformMenu(
          label: l10n.menuView,
          menus: [
            item(l10n.menuQueue, const ToggleQueueIntent()),
            item(l10n.menuLyrics, const ToggleLyricsIntent(), needsQueue: true),
          ],
        ),
        PlatformMenu(
          label: l10n.menuWindow,
          menus: [
            for (final type in const [
              PlatformProvidedMenuItemType.minimizeWindow,
              PlatformProvidedMenuItemType.zoomWindow,
            ])
              if (PlatformProvidedMenuItem.hasMenu(type))
                PlatformProvidedMenuItem(type: type),
          ],
        ),
      ],
      child: child,
    );
  }
}

/// The macOS keys of the shortcut binding of [intent], for its menu item;
/// null when it has none or when it is limited to outside text fields.
MenuSerializableShortcut? menuShortcutOf(Intent intent) {
  for (final binding in shortcutBindings) {
    if (binding.intent.runtimeType != intent.runtimeType) continue;
    final keys = binding.keys.first;
    if (keys.outsideText) return null;
    final activator = keys.activator(TargetPlatform.macOS);
    return activator is MenuSerializableShortcut ? activator : null;
  }
  return null;
}
