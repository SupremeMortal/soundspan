// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/window_controls.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/platform/desktop_shell/desktop_shell.dart';

/// The title bar the app draws this session: whether it draws one, its
/// window buttons and the window state they show.
@immutable
final class WindowChrome {
  /// Creates the chrome.
  const new({
    this.integrated = false,
    this.layout = WindowButtonLayout.none,
    this.state = const WindowChromeState(),
  });

  /// The chrome of a window with the system's title bar.
  static const WindowChrome system = WindowChrome();

  /// Whether the app draws its own title bar.
  final bool integrated;

  /// The window buttons, by side.
  final WindowButtonLayout layout;

  /// Maximised, fullscreen and focused.
  final WindowChromeState state;

  /// The buttons shown: none in fullscreen.
  WindowButtonLayout get shownLayout =>
      state.fullscreen ? WindowButtonLayout.none : layout;

  @override
  bool operator ==(Object other) =>
      other is WindowChrome &&
      other.integrated == integrated &&
      other.layout == layout &&
      other.state == state;

  @override
  int get hashCode => Object.hash(integrated, layout, state);
}

/// The [WindowChrome] of the app's [DesktopShell], now and after every
/// change.
final StreamProvider<WindowChrome> windowChromeProvider =
    StreamProvider<WindowChrome>((ref) {
      final shell = ref.watch(desktopShellProvider);
      WindowChrome read() => WindowChrome(
        integrated: shell.integratedTitleBar,
        layout: shell.buttonLayout,
        state: shell.chromeState,
      );
      final controller = StreamController<WindowChrome>()..add(read());
      final subscriptions = [
        shell.buttonLayoutChanges.listen((_) => controller.add(read())),
        shell.chromeStateChanges.listen((_) => controller.add(read())),
      ];
      ref.onDispose(() {
        for (final subscription in subscriptions) {
          unawaited(subscription.cancel());
        }
        unawaited(controller.close());
      });
      return controller.stream.distinct();
    });

/// The current [WindowChrome]; [WindowChrome.system] until it is known.
WindowChrome watchWindowChrome(WidgetRef ref) =>
    ref.watch(windowChromeProvider).value ?? WindowChrome.system;

/// Lets the window be moved from [child]'s empty space: dragging moves the
/// window, a double click maximises or restores it, and a right click opens
/// the window manager's window menu. Controls inside [child] keep their own
/// gestures; only space no control takes drags.
class WindowDragRegion extends ConsumerWidget {
  /// Creates the region around [child].
  const new({required this.child, super.key});

  /// The bar whose empty space drags.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shell = ref.watch(desktopShellProvider);
    return Stack(
      children: [
        Positioned.fill(
          child: Listener(
            // The window menu opens while the button is down: Wayland only
            // shows it for a press it is still delivering.
            onPointerDown: (event) {
              if (event.buttons == kSecondaryMouseButton) {
                unawaited(shell.showWindowMenu(event.position));
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (_) => unawaited(shell.startDragging()),
              onDoubleTap: () => unawaited(shell.toggleMaximize()),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// The height of the root title strip on [platform]: the system title
/// bar's on macOS and Windows, a little taller on Linux for the circles.
double titleStripHeight(TargetPlatform platform) => switch (platform) {
  TargetPlatform.macOS => 28,
  TargetPlatform.windows => 32,
  _ => 38,
};

/// The leading space the macOS traffic lights take.
const double macOSTrafficLightsInset = 72;

/// Wraps the app's navigator on a desktop whose title bar the app draws:
/// above every screen it shows a slim title strip with the window buttons
/// and a drag area, unless a [WindowTitleBarClaim] on the current route
/// (the expanded shell's top bar) hosts them itself.
class WindowTitleBarHost extends ConsumerStatefulWidget {
  /// Creates the host around [child].
  const new({required this.child, super.key});

  /// The navigator.
  final Widget child;

  /// The key of the title strip.
  static const Key stripKey = ValueKey<String>('window.titleStrip');

  @override
  ConsumerState<WindowTitleBarHost> createState() => _WindowTitleBarHostState();
}

class _WindowTitleBarHostState extends ConsumerState<WindowTitleBarHost> {
  final _Claims _claims = _Claims();

  /// The strip sits above the navigator, so its tooltips need an overlay
  /// of their own: this one holds the strip and the navigator.
  late final OverlayEntry _entry = OverlayEntry(builder: _buildContent);

  WindowChrome _chrome = WindowChrome.system;

  @override
  void dispose() {
    _entry
      ..remove()
      ..dispose();
    _claims.dispose();
    super.dispose();
  }

  Widget _buildContent(BuildContext context) {
    final chrome = _chrome;
    return ValueListenableBuilder<int>(
      valueListenable: _claims,
      builder: (context, claims, content) {
        final strip =
            chrome.integrated && !chrome.state.fullscreen && claims == 0;
        return Column(
          children: [
            if (strip) WindowTitleStrip(chrome: chrome),
            Expanded(child: content!),
          ],
        );
      },
      child: KeyedSubtree(
        key: const ValueKey<String>('window.content'),
        child: widget.child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _chrome = watchWindowChrome(ref);
    // The entry builds from this state's fields; rebuild it with them.
    _entry.markNeedsBuild();
    return _ClaimScope(
      claims: _claims,
      child: Overlay(initialEntries: [_entry]),
    );
  }
}

/// How many [WindowTitleBarClaim]s on current routes host the buttons.
class _Claims extends ValueNotifier<int> {
  new() : super(0);

  bool _disposed = false;

  /// Adds [delta] unless the host is gone.
  void adjust(int delta) {
    if (!_disposed) value += delta;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class _ClaimScope extends InheritedWidget {
  const new({required this.claims, required super.child});

  final _Claims claims;

  @override
  bool updateShouldNotify(_ClaimScope old) => old.claims != claims;
}

/// Tells the [WindowTitleBarHost] that [child] hosts the window buttons
/// while it is on screen, so the root title strip steps aside.
///
/// "On screen" is read from [TickerMode]: the [Overlay] builds the routes
/// under an opaque route (a full-screen page such as Settings) offstage
/// with tickers off, which releases the claim, while a popup menu, dialog
/// or bottom sheet above leaves them onstage and the claim held. The claim
/// therefore relies on no ancestor `TickerMode(enabled: false)` between
/// the route and the bar.
class WindowTitleBarClaim extends StatefulWidget {
  /// Creates the claim for [child].
  const new({required this.child, super.key});

  /// The bar that hosts the window buttons.
  final Widget child;

  @override
  State<WindowTitleBarClaim> createState() => _WindowTitleBarClaimState();
}

class _WindowTitleBarClaimState extends State<WindowTitleBarClaim> {
  _Claims? _claims;
  bool _claimed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = context.dependOnInheritedWidgetOfExactType<_ClaimScope>();
    if (!identical(scope?.claims, _claims)) {
      _set(false);
      _claims = scope?.claims;
    }
    // Not `ModalRoute.isCurrent`: a popup or dialog pushed above the route
    // makes it not current, yet the bar is still visible beneath it.
    _set(TickerMode.valuesOf(context).enabled);
  }

  @override
  void dispose() {
    _set(false);
    super.dispose();
  }

  /// Changes the count after the frame, as it rebuilds the host.
  void _set(bool claimed) {
    if (claimed == _claimed) return;
    _claimed = claimed;
    final claims = _claims;
    if (claims == null) return;
    final delta = claimed ? 1 : -1;
    SchedulerBinding.instance.addPostFrameCallback((_) => claims.adjust(delta));
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The slim title bar above screens that have no top bar: a drag area with
/// the window buttons at the ends the desktop asks for, clear of the macOS
/// traffic lights.
class WindowTitleStrip extends StatelessWidget {
  /// Creates the strip showing [chrome].
  const new({required this.chrome, super.key});

  /// The buttons and window state shown.
  final WindowChrome chrome;

  @override
  Widget build(BuildContext context) {
    final height = titleStripHeight(defaultTargetPlatform);
    final layout = chrome.shownLayout;
    return Material(
      key: WindowTitleBarHost.stripKey,
      color: context.colors.ground,
      child: WindowDragRegion(
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              if (layout.leading.isNotEmpty)
                WindowControls(
                  buttons: layout.leading,
                  state: chrome.state,
                  side: WindowControlsSide.leading,
                  height: height,
                ),
              const Spacer(),
              if (layout.trailing.isNotEmpty)
                WindowControls(
                  buttons: layout.trailing,
                  state: chrome.state,
                  side: WindowControlsSide.trailing,
                  height: height,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
