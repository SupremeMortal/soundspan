// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:math' as math;

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';

/// The list–detail layout of medium windows in landscape (doc 09, Shell by
/// Window Class: Medium).
///
/// The list takes [listWidth] at the start, a [dividerWidth] `line` divider
/// follows, and the detail fills the rest. The list is a [TwoPaneList]; the
/// detail is the detail route itself, built as a [TwoPaneDetailPage] that
/// paints only the detail pane, so the location stays the detail's own
/// route and Back closes it.
abstract final class TwoPane {
  /// The width of the list pane.
  static const double listWidth = 360;

  /// The width of the divider between the panes.
  static const double dividerWidth = 1;

  /// Whether the window of [context] shows two panes: a medium window wider
  /// than it is tall.
  static bool of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return windowClassOf(size) == WindowClass.medium &&
        size.width > size.height;
  }
}

/// The selected item of a [TwoPaneList]: the location segments of the
/// detail its pane shows, such as `['album', '42']`, or none.
class TwoPaneSelection extends InheritedWidget {
  /// Provides [segments] to [child], a list in the list pane when [active].
  const new({
    required this.segments,
    required this.active,
    required super.child,
    super.key,
  });

  /// The detail's segments after the list's location; empty when nothing
  /// is selected.
  final List<String> segments;

  /// Whether the list is in the list pane of a two-pane layout.
  final bool active;

  /// Whether [context] is inside the list pane of a two-pane layout, where
  /// opening an item replaces the open detail rather than stacking on it.
  static bool inListPane(BuildContext context) =>
      context.getInheritedWidgetOfExactType<TwoPaneSelection>()?.active ??
      false;

  /// Whether the detail of [kind] (`album`, `playlist`, a podcast's empty
  /// kind) and [id] is the selected one under [context]. Always false
  /// outside a two-pane layout.
  static bool isSelected(BuildContext context, String kind, String id) {
    final segments = context
        .dependOnInheritedWidgetOfExactType<TwoPaneSelection>()
        ?.segments;
    if (segments == null || segments.isEmpty) return false;
    return kind.isEmpty
        ? segments.length == 1 && segments.first == id
        : segments.length == 2 && segments[0] == kind && segments[1] == id;
  }

  @override
  bool updateShouldNotify(TwoPaneSelection oldWidget) =>
      active != oldWidget.active ||
      !_sameSegments(segments, oldWidget.segments);
}

bool _sameSegments(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// The list of a list–detail destination: with [enabled] and in a
/// two-pane window, [list] in the [TwoPane.listWidth] pane beside an
/// [EmptyState] ("Select an item"), which the detail route covers while
/// one is open; otherwise [list] alone. [selected] are the location
/// segments of the open detail (see [TwoPaneSelection]).
class TwoPaneList extends StatelessWidget {
  /// Creates the list layout of [list].
  const new({
    required this.list,
    this.selected = const [],
    this.enabled = true,
    super.key,
  });

  /// The list.
  final Widget list;

  /// The location segments of the open detail.
  final List<String> selected;

  /// Whether this list has a detail pane at all.
  final bool enabled;

  /// The key of the detail pane's empty state.
  static const Key emptyKey = Key('twoPane.empty');

  @override
  Widget build(BuildContext context) {
    final twoPane = enabled && TwoPane.of(context);
    final l10n = AppLocalizations.of(context);
    // One structure in both layouts, so the list keeps its state when the
    // window rotates or [enabled] changes.
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: twoPane ? TwoPane.listWidth : constraints.maxWidth,
            child: TwoPaneSelection(
              segments: twoPane ? selected : const [],
              active: twoPane,
              child: list,
            ),
          ),
          if (twoPane) ...[
            SizedBox(
              width: TwoPane.dividerWidth,
              child: ColoredBox(color: context.colors.line),
            ),
            Expanded(
              child: EmptyState(
                key: emptyKey,
                icon: Icons.touch_app_outlined,
                message: l10n.twoPaneSelectItem,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The page of a detail route that may open in a detail pane: in a
/// two-pane window with [paneEligible], a [TwoPaneDetailPage]; otherwise a
/// [MaterialPage] pushed over the list. It follows the window, so rotating
/// moves an open detail between the pane and a full page.
Page<void> twoPaneDetailPage(
  BuildContext context,
  GoRouterState state, {
  required Widget child,
  required bool paneEligible,
}) => paneEligible && TwoPane.of(context)
    ? TwoPaneDetailPage<void>(key: state.pageKey, child: child)
    : MaterialPage<void>(key: state.pageKey, child: child);

/// A detail shown in the detail pane of a two-pane window: its route paints
/// only the area after the list and the divider, on `surface`, without a
/// transition or a barrier, so the list beside it stays usable. The detail
/// takes the [WindowClass] of the pane's own size.
class TwoPaneDetailPage<T> extends Page<T> {
  /// Creates the page of [child].
  const new({required this.child, super.key});

  /// The detail screen.
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => _TwoPaneDetailRoute<T>(this);
}

class _TwoPaneDetailRoute<T> extends PageRoute<T> {
  new(TwoPaneDetailPage<T> page) : super(settings: page);

  TwoPaneDetailPage<T> get _page => settings as TwoPaneDetailPage<T>;

  @override
  bool get opaque => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  // No barrier: the list beside the pane takes input.
  @override
  Widget buildModalBarrier() => const SizedBox.shrink();

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      final width = math.max<double>(
        0,
        constraints.maxWidth - TwoPane.listWidth - TwoPane.dividerWidth,
      );
      // The detail lays itself out for the pane's own size.
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: SizedBox(
          width: width,
          child: WindowClassScope(
            windowClass: windowClassOf(Size(width, constraints.maxHeight)),
            child: Material(color: context.colors.surface, child: _page.child),
          ),
        ),
      );
    },
  );
}
