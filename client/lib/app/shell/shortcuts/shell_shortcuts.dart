// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/gestures.dart'
    show kBackMouseButton, kForwardMouseButton;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/desktop/desktop_menu_bar.dart';
import 'package:soundspan/app/shell/shortcuts/shell_focus_groups.dart';
import 'package:soundspan/app/shell/shortcuts/shortcut_bindings.dart';
import 'package:soundspan/app/shell/shortcuts/shortcut_intents.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/features/player/player.dart';
import 'package:soundspan/shared/domain/queue_item.dart';
import 'package:soundspan/shared/providers/likes.dart';
import 'package:soundspan/shared/widgets/refresh_target.dart';

/// The shell's shortcuts: the `Shortcuts` of [shortcutBindings] and the
/// actions of every intent that is not a row's, around [child] (doc 09,
/// Desktop Interaction).
///
/// A shortcut whose action has no target (Space with an empty queue, Back
/// at a branch root) does nothing and leaves its key to the widgets above.
/// The mouse back and forward buttons call [onBack] and [onForward]. A
/// focus anchor keeps keys inside the shell while no control has focus.
/// Off desktop and the web it adds only the [RefreshRegistryScope].
class ShellShortcuts extends ConsumerStatefulWidget {
  /// Creates the shortcuts around [child].
  const new({
    required this.focusGroups,
    required this.onDestinationSelected,
    required this.onFocusSearch,
    required this.onOpenSettings,
    required this.child,
    this.onBack,
    this.onForward,
    super.key,
  });

  /// The shell's focus groups, which F6 cycles.
  final ShellFocusGroups focusGroups;

  /// Opens the destination at the index.
  final ValueChanged<int> onDestinationSelected;

  /// Focuses the search field, opening Search when it is not on screen.
  final VoidCallback onFocusSearch;

  /// Opens Settings.
  final VoidCallback onOpenSettings;

  /// Goes back; null while there is nowhere to go back to.
  final VoidCallback? onBack;

  /// Goes forward; null while there is nowhere to go forward to.
  final VoidCallback? onForward;

  /// The shell.
  final Widget child;

  @override
  ConsumerState<ShellShortcuts> createState() => _ShellShortcutsState();
}

class _ShellShortcutsState extends ConsumerState<ShellShortcuts> {
  final RefreshRegistry _refresh = RefreshRegistry();
  final FocusNode _anchor = FocusNode(debugLabel: 'shell.shortcuts');
  bool _queueSheetOpen = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_keepFocusInShell);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_keepFocusInShell);
    _anchor.dispose();
    super.dispose();
  }

  /// Brings focus back to the anchor when it fell above the shell, as when
  /// the shell's indexed stack hides the branch that held it, so the keys
  /// keep reaching the shortcuts. Focus in a dialog or a page above the
  /// shell is left alone.
  void _keepFocusInShell() {
    if (!mounted || !shortcutsActive()) return;
    final focused = FocusManager.instance.primaryFocus;
    if (focused != null && !_anchor.ancestors.contains(focused)) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    _anchor.requestFocus();
  }

  /// The playback controller, without creating it.
  PlaybackController? get _controller =>
      ref.read(playbackControllerProvider.exists)
      ? ref.read(playbackControllerProvider)
      : null;

  /// The controller while the queue has a current item.
  PlaybackController? get _playing {
    final controller = _controller;
    return controller?.snapshot.current == null ? null : controller;
  }

  void _seekBy(Duration offset) {
    final controller = _playing!;
    final snapshot = controller.snapshot;
    var position = snapshot.position + offset;
    final duration = snapshot.duration;
    if (duration != null && position > duration) position = duration;
    if (position < Duration.zero) position = Duration.zero;
    unawaited(controller.seek(position));
  }

  void _toggleQueue() {
    final size = MediaQuery.sizeOf(context);
    if (windowClassOf(size) == WindowClass.expanded) {
      ref.read(rightPanelProvider.notifier).toggle(RightPanel.queue);
      return;
    }
    if (_queueSheetOpen) {
      Navigator.of(context).maybePop();
      return;
    }
    _queueSheetOpen = true;
    unawaited(
      showQueueSheet(
        context,
        closeActivator: const SingleActivator(
          LogicalKeyboardKey.keyQ,
          control: true,
        ),
      ).whenComplete(() => _queueSheetOpen = false),
    );
  }

  Map<Type, Action<Intent>> _actions() => {
    TogglePlayPauseIntent: _ShellAction<TogglePlayPauseIntent>(
      enabled: (_) => _playing != null,
      (_) => unawaited(_playing!.togglePlayPause()),
    ),
    NextTrackIntent: _ShellAction<NextTrackIntent>(
      enabled: (_) => _playing != null,
      (_) => unawaited(_playing!.next()),
    ),
    PreviousTrackIntent: _ShellAction<PreviousTrackIntent>(
      enabled: (_) => _playing != null,
      (_) => unawaited(_playing!.previous()),
    ),
    SeekByIntent: _ShellAction<SeekByIntent>(
      enabled: (_) => _playing != null,
      (intent) => _seekBy(intent.offset),
    ),
    ChangeVolumeIntent: _ShellAction<ChangeVolumeIntent>(
      enabled: (_) => _controller != null,
      (intent) {
        final controller = _controller!;
        final volume = (controller.volume + intent.delta).clamp(0.0, 1.0);
        unawaited(controller.setVolume(volume));
      },
    ),
    ToggleShuffleIntent: _ShellAction<ToggleShuffleIntent>(
      enabled: (_) => _playing?.snapshot.current is TrackQueueItem,
      (_) {
        final controller = _playing!;
        unawaited(controller.setShuffle(!controller.snapshot.queue.isShuffled));
      },
    ),
    CycleRepeatIntent: _ShellAction<CycleRepeatIntent>(
      enabled: (_) => _playing?.snapshot.current is TrackQueueItem,
      (_) {
        final controller = _playing!;
        unawaited(
          controller.setRepeat(
            nextRepeatMode(controller.snapshot.queue.repeat),
          ),
        );
      },
    ),
    ToggleLikeCurrentIntent: _ShellAction<ToggleLikeCurrentIntent>(
      enabled: (_) => switch (_playing?.snapshot.current) {
        TrackQueueItem(:final track) => track.playbackId != null,
        _ => false,
      },
      (_) {
        final current = _playing!.snapshot.current! as TrackQueueItem;
        toggleLikeOf(ref, current.track)?.call();
      },
    ),
    FocusSearchIntent: _ShellAction<FocusSearchIntent>(
      (_) => widget.onFocusSearch(),
    ),
    GoToDestinationIntent: _ShellAction<GoToDestinationIntent>(
      (intent) => widget.onDestinationSelected(intent.index),
    ),
    ToggleQueueIntent: _ShellAction<ToggleQueueIntent>(
      enabled: (_) => _controller != null,
      (_) => _toggleQueue(),
    ),
    ToggleLyricsIntent: _ShellAction<ToggleLyricsIntent>(
      enabled: (_) =>
          _playing != null &&
          windowClassOf(MediaQuery.sizeOf(context)) == WindowClass.expanded,
      (_) => ref.read(rightPanelProvider.notifier).toggle(RightPanel.lyrics),
    ),
    NavigateBackIntent: _ShellAction<NavigateBackIntent>(
      enabled: (_) => widget.onBack != null,
      (_) => widget.onBack!(),
    ),
    NavigateForwardIntent: _ShellAction<NavigateForwardIntent>(
      enabled: (_) => widget.onForward != null,
      (_) => widget.onForward!(),
    ),
    OpenSettingsIntent: _ShellAction<OpenSettingsIntent>(
      (_) => widget.onOpenSettings(),
    ),
    RefreshIntent: _ShellAction<RefreshIntent>(
      enabled: (_) => _refresh.canRefresh,
      (_) => _refresh.refresh(),
    ),
    CycleFocusGroupIntent: _ShellAction<CycleFocusGroupIntent>(
      (intent) => widget.focusGroups.cycle(backward: intent.backward),
    ),
  };

  void _onPointerDown(PointerDownEvent event) {
    if (event.buttons & kBackMouseButton != 0) {
      widget.onBack?.call();
    } else if (event.buttons & kForwardMouseButton != 0) {
      widget.onForward?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoped = RefreshRegistryScope(
      registry: _refresh,
      child: widget.child,
    );
    if (!shortcutsActive()) return scoped;
    return Listener(
      onPointerDown: _onPointerDown,
      behavior: HitTestBehavior.translucent,
      child: Shortcuts(
        shortcuts: shortcutMap(defaultTargetPlatform),
        child: Actions(
          actions: _actions(),
          child: DesktopMenuBar(
            child: Focus(focusNode: _anchor, autofocus: true, child: scoped),
          ),
        ),
      ),
    );
  }
}

/// An action that is enabled while its `enabled` test says so.
class _ShellAction<T extends Intent> extends Action<T> {
  new(this._invoke, {this._enabled});

  final void Function(T intent) _invoke;
  final bool Function(T intent)? _enabled;

  @override
  bool isEnabled(T intent) => _enabled?.call(intent) ?? true;

  @override
  Object? invoke(T intent) {
    _invoke(intent);
    return null;
  }
}
