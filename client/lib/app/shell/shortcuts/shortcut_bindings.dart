// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/shell/adaptive_shell.dart';
import 'package:soundspan/app/shell/shortcuts/shortcut_intents.dart';

/// One key combination of a [ShortcutBinding].
///
/// [primary] is Ctrl, or Cmd on macOS; [control] is Ctrl on every
/// platform. A combination with [outsideText] does nothing while a text
/// field has focus, so the field keeps the key.
class ShortcutKeys {
  /// The combination of [key] with the given modifiers.
  const new(
    LogicalKeyboardKey this.key, {
    this.primary = false,
    this.control = false,
    this.shift = false,
    this.alt = false,
    this.outsideText = false,
  }) : character = null;

  /// The combination typing [character], whatever keys produce it.
  const new typed(String this.character, {this.outsideText = false})
    : key = null,
      primary = false,
      control = false,
      shift = false,
      alt = false;

  /// The key pressed, or null for a [ShortcutKeys.typed] combination.
  final LogicalKeyboardKey? key;

  /// The character typed, or null for a [key] combination.
  final String? character;

  /// Whether Ctrl (Cmd on macOS) is held.
  final bool primary;

  /// Whether Ctrl is held, on macOS too.
  final bool control;

  /// Whether Shift is held.
  final bool shift;

  /// Whether Alt (Option on macOS) is held.
  final bool alt;

  /// Whether the combination is ignored while a text field has focus.
  final bool outsideText;

  /// The activator of the combination on [platform].
  ShortcutActivator activator(TargetPlatform platform) {
    final mac = platform == TargetPlatform.macOS;
    final character = this.character;
    final ShortcutActivator activator;
    if (character != null) {
      activator = CharacterActivator(character);
    } else {
      activator = SingleActivator(
        key!,
        control: control || (primary && !mac),
        meta: primary && mac,
        shift: shift,
        alt: alt,
      );
    }
    return outsideText ? _OutsideTextActivator(activator) : activator;
  }

  /// The combination as shown in Settings on [platform]: "Ctrl+→",
  /// "Cmd+→" on macOS.
  String describe(AppLocalizations l10n, TargetPlatform platform) {
    final character = this.character;
    if (character != null) return character;
    final mac = platform == TargetPlatform.macOS;
    return [
      if (control || (primary && !mac)) l10n.keyCtrl,
      if (primary && mac) l10n.keyCmd,
      if (alt && mac) l10n.keyOption,
      if (alt && !mac) l10n.keyAlt,
      if (shift) l10n.keyShift,
      _keyName(l10n, key!),
    ].join('+');
  }

  static String _keyName(AppLocalizations l10n, LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.space) return l10n.keySpace;
    if (key == LogicalKeyboardKey.enter) return l10n.keyEnter;
    if (key == LogicalKeyboardKey.delete) return l10n.keyDelete;
    if (key == LogicalKeyboardKey.contextMenu) return l10n.keyMenu;
    if (key == LogicalKeyboardKey.arrowRight) return '→';
    if (key == LogicalKeyboardKey.arrowLeft) return '←';
    if (key == LogicalKeyboardKey.arrowUp) return '↑';
    if (key == LogicalKeyboardKey.arrowDown) return '↓';
    return key.keyLabel;
  }
}

/// A shortcut: the [intent] it sends, the [keys] that send it and the
/// [label] Settings shows for it (doc 09, Desktop Interaction).
class ShortcutBinding {
  /// Creates the binding of [keys] to [intent].
  const new({
    required this.intent,
    required this.keys,
    required this.label,
    this.pointerLabel,
  });

  /// The intent sent.
  final Intent intent;

  /// The key combinations that send it.
  final List<ShortcutKeys> keys;

  /// What the shortcut does, as Settings lists it.
  final String Function(AppLocalizations l10n) label;

  /// The mouse button that does the same, when there is one.
  final String Function(AppLocalizations l10n)? pointerLabel;
}

/// Every desktop shortcut, in the order Settings lists them. It drives the
/// shell's `Shortcuts` and Settings → Desktop.
final List<ShortcutBinding> shortcutBindings = [
  ShortcutBinding(
    intent: const TogglePlayPauseIntent(),
    keys: const [ShortcutKeys(LogicalKeyboardKey.space, outsideText: true)],
    label: (l10n) => l10n.shortcutPlayPause,
  ),
  ShortcutBinding(
    intent: const NextTrackIntent(),
    keys: const [
      ShortcutKeys(
        LogicalKeyboardKey.arrowRight,
        primary: true,
        outsideText: true,
      ),
    ],
    label: (l10n) => l10n.shortcutNext,
  ),
  ShortcutBinding(
    intent: const PreviousTrackIntent(),
    keys: const [
      ShortcutKeys(
        LogicalKeyboardKey.arrowLeft,
        primary: true,
        outsideText: true,
      ),
    ],
    label: (l10n) => l10n.shortcutPrevious,
  ),
  ShortcutBinding(
    intent: const SeekByIntent(seekStep),
    keys: const [
      ShortcutKeys(
        LogicalKeyboardKey.arrowRight,
        shift: true,
        outsideText: true,
      ),
    ],
    label: (l10n) => l10n.shortcutSeekForward(seekStep.inSeconds),
  ),
  ShortcutBinding(
    intent: SeekByIntent(-seekStep),
    keys: const [
      ShortcutKeys(
        LogicalKeyboardKey.arrowLeft,
        shift: true,
        outsideText: true,
      ),
    ],
    label: (l10n) => l10n.shortcutSeekBack(seekStep.inSeconds),
  ),
  ShortcutBinding(
    intent: const ChangeVolumeIntent(volumeStep),
    keys: const [
      ShortcutKeys(
        LogicalKeyboardKey.arrowUp,
        primary: true,
        outsideText: true,
      ),
    ],
    label: (l10n) => l10n.shortcutVolumeUp,
  ),
  ShortcutBinding(
    intent: const ChangeVolumeIntent(-volumeStep),
    keys: const [
      ShortcutKeys(
        LogicalKeyboardKey.arrowDown,
        primary: true,
        outsideText: true,
      ),
    ],
    label: (l10n) => l10n.shortcutVolumeDown,
  ),
  ShortcutBinding(
    intent: const ToggleShuffleIntent(),
    keys: const [ShortcutKeys(LogicalKeyboardKey.keyS, primary: true)],
    label: (l10n) => l10n.shortcutShuffle,
  ),
  ShortcutBinding(
    intent: const CycleRepeatIntent(),
    keys: const [ShortcutKeys(LogicalKeyboardKey.keyR, primary: true)],
    label: (l10n) => l10n.shortcutRepeat,
  ),
  ShortcutBinding(
    intent: const ToggleLikeCurrentIntent(),
    keys: const [ShortcutKeys(LogicalKeyboardKey.keyL, primary: true)],
    label: (l10n) => l10n.shortcutLike,
  ),
  ShortcutBinding(
    intent: const FocusSearchIntent(),
    keys: const [
      ShortcutKeys(LogicalKeyboardKey.keyK, primary: true),
      ShortcutKeys.typed('/', outsideText: true),
    ],
    label: (l10n) => l10n.shortcutSearch,
  ),
  for (final (index, destination) in ShellDestination.values.indexed)
    ShortcutBinding(
      intent: GoToDestinationIntent(index),
      keys: [
        ShortcutKeys(
          [
            LogicalKeyboardKey.digit1,
            LogicalKeyboardKey.digit2,
            LogicalKeyboardKey.digit3,
            LogicalKeyboardKey.digit4,
          ][index],
          primary: true,
        ),
      ],
      label: (l10n) => l10n.shortcutGoTo(destination.label(l10n)),
    ),
  ShortcutBinding(
    intent: const ToggleQueueIntent(),
    // Ctrl on macOS too: Cmd+Q quits the app (doc 10, macOS).
    keys: const [ShortcutKeys(LogicalKeyboardKey.keyQ, control: true)],
    label: (l10n) => l10n.shortcutQueue,
  ),
  ShortcutBinding(
    intent: const NavigateBackIntent(),
    keys: const [
      ShortcutKeys(LogicalKeyboardKey.arrowLeft, alt: true, outsideText: true),
    ],
    label: (l10n) => l10n.shellBack,
    pointerLabel: (l10n) => l10n.keyMouseBack,
  ),
  ShortcutBinding(
    intent: const NavigateForwardIntent(),
    keys: const [
      ShortcutKeys(LogicalKeyboardKey.arrowRight, alt: true, outsideText: true),
    ],
    label: (l10n) => l10n.shellForward,
    pointerLabel: (l10n) => l10n.keyMouseForward,
  ),
  ShortcutBinding(
    intent: const OpenSettingsIntent(),
    keys: const [ShortcutKeys(LogicalKeyboardKey.comma, primary: true)],
    label: (l10n) => l10n.screenSettings,
  ),
  ShortcutBinding(
    intent: const PlayRowIntent(),
    keys: const [ShortcutKeys(LogicalKeyboardKey.enter, outsideText: true)],
    label: (l10n) => l10n.shortcutPlayRow,
  ),
  ShortcutBinding(
    intent: const PlayRowNextIntent(),
    keys: const [
      ShortcutKeys(LogicalKeyboardKey.enter, shift: true, outsideText: true),
    ],
    label: (l10n) => l10n.shortcutPlayRowNext,
  ),
  ShortcutBinding(
    intent: const RemoveRowIntent(),
    keys: const [ShortcutKeys(LogicalKeyboardKey.delete, outsideText: true)],
    label: (l10n) => l10n.shortcutRemoveRow,
  ),
  ShortcutBinding(
    intent: const OpenMenuIntent(),
    keys: const [
      ShortcutKeys(LogicalKeyboardKey.contextMenu, outsideText: true),
      ShortcutKeys(LogicalKeyboardKey.f10, shift: true, outsideText: true),
    ],
    label: (l10n) => l10n.shortcutMenu,
  ),
  ShortcutBinding(
    intent: const RefreshIntent(),
    keys: const [
      ShortcutKeys(LogicalKeyboardKey.f5),
      ShortcutKeys(LogicalKeyboardKey.keyR, primary: true, shift: true),
    ],
    label: (l10n) => l10n.shortcutRefresh,
  ),
  ShortcutBinding(
    intent: const CycleFocusGroupIntent(),
    keys: const [ShortcutKeys(LogicalKeyboardKey.f6)],
    label: (l10n) => l10n.shortcutNextArea,
  ),
  ShortcutBinding(
    intent: const CycleFocusGroupIntent(backward: true),
    keys: const [ShortcutKeys(LogicalKeyboardKey.f6, shift: true)],
    label: (l10n) => l10n.shortcutPreviousArea,
  ),
];

/// How far Shift+arrow seeks.
const Duration seekStep = Duration(seconds: 10);

/// How much Ctrl+Up and Ctrl+Down change the volume.
const double volumeStep = 0.05;

/// The activators of [shortcutBindings] on [platform], for a `Shortcuts`
/// widget.
Map<ShortcutActivator, Intent> shortcutMap(TargetPlatform platform) => {
  for (final binding in shortcutBindings)
    for (final keys in binding.keys) keys.activator(platform): binding.intent,
};

/// Whether the desktop shortcuts are active: on a desktop platform, and on
/// the web, where they wait for a hardware keyboard (doc 09, Desktop
/// Interaction).
bool shortcutsActive() =>
    kIsWeb ||
    switch (defaultTargetPlatform) {
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      _ => false,
    };

/// Whether a text field has the primary focus.
bool textFieldHasFocus() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null || !context.mounted) return false;
  return context.widget is EditableText ||
      context.findAncestorWidgetOfExactType<EditableText>() != null;
}

/// [inner], ignored while a text field has focus.
class _OutsideTextActivator extends ShortcutActivator {
  const new(this.inner);

  final ShortcutActivator inner;

  @override
  Iterable<LogicalKeyboardKey>? get triggers => inner.triggers;

  @override
  bool accepts(KeyEvent event, HardwareKeyboard state) =>
      inner.accepts(event, state) && !textFieldHasFocus();

  @override
  String debugDescribeKeys() => inner.debugDescribeKeys();
}
