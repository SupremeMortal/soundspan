// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:cupertino_ui/cupertino_ui.dart'
    show
        CupertinoFullscreenDialogTransition,
        CupertinoPageTransition,
        CupertinoRouteTransitionMixin;
import 'package:flutter/gestures.dart' show HorizontalDragGestureRecognizer;
import 'package:material_ui/material_ui.dart';

/// A page transition that plays only when navigation has happened: a back
/// gesture never moves content before it commits.
///
/// Pushes and pops keep the platform look: [cupertino] selects the iOS
/// horizontal slide, otherwise the Material fade-forwards transition. The
/// builder ignores Android predictive-back progress, so the framework turns a
/// committed system back gesture into an ordinary pop. With [cupertino] the
/// page takes a [CommitOnlyEdgeSwipe] in place of the interactive Cupertino
/// back gesture.
class CommitOnlyPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Creates the builder; [cupertino] selects the iOS slide.
  const new({this.cupertino = false});

  /// Whether pages slide horizontally as on iOS.
  final bool cupertino;

  static const _fadeForwards = FadeForwardsPageTransitionsBuilder();

  @override
  Duration get transitionDuration => cupertino
      ? CupertinoRouteTransitionMixin.kTransitionDuration
      : _fadeForwards.transitionDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition => cupertino
      ? CupertinoPageTransition.delegatedTransition
      : _fadeForwards.delegatedTransition;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (!cupertino) {
      return _fadeForwards.buildTransitions(
        route,
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }
    if (route.fullscreenDialog) {
      return CupertinoFullscreenDialogTransition(
        primaryRouteAnimation: animation,
        secondaryRouteAnimation: secondaryAnimation,
        linearTransition: false,
        child: child,
      );
    }
    return CupertinoPageTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      linearTransition: false,
      child: CommitOnlyEdgeSwipe(route: route, child: child),
    );
  }
}

/// A back swipe from the leading edge that shows nothing while the finger is
/// down and pops [route] on release once the swipe is far or fast enough.
///
/// The swipe starts within [edgeWidth] of the leading edge (the right edge
/// in a right-to-left layout). On release it calls [Navigator.maybePop] when
/// it covered at least a third of the width or was flung toward the trailing
/// edge at [minFlingVelocity] or more. It does not start while
/// [ModalRoute.popGestureEnabled] is false (the first route, a
/// `PopScope(canPop: false)`, a route still animating) or while another
/// navigator gesture is in progress.
class CommitOnlyEdgeSwipe extends StatefulWidget {
  /// Wraps [child], the page of [route].
  const new({required this.route, required this.child, super.key});

  /// The route the swipe pops.
  final PageRoute<Object?> route;

  /// The page.
  final Widget child;

  /// The width of the strip along the leading edge where a swipe starts.
  static const double edgeWidth = 20;

  /// The share of the width a swipe covers to pop on release.
  static const double minDistanceFraction = 1 / 3;

  /// The release speed, in logical pixels per second, that pops a shorter
  /// swipe.
  static const double minFlingVelocity = 500;

  @override
  State<CommitOnlyEdgeSwipe> createState() => _CommitOnlyEdgeSwipeState();
}

class _CommitOnlyEdgeSwipeState extends State<CommitOnlyEdgeSwipe> {
  late final HorizontalDragGestureRecognizer _recognizer;

  // The distance covered toward the trailing edge.
  double _distance = 0;

  @override
  void initState() {
    super.initState();
    _recognizer = HorizontalDragGestureRecognizer(debugOwner: this)
      ..onStart = _handleStart
      ..onUpdate = _handleUpdate
      ..onEnd = _handleEnd;
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  bool get _enabled =>
      widget.route.popGestureEnabled && !widget.route.popGestureInProgress;

  void _handlePointerDown(PointerDownEvent event) {
    if (_enabled) {
      _recognizer.addPointer(event);
    }
  }

  void _handleStart(DragStartDetails details) => _distance = 0;

  void _handleUpdate(DragUpdateDetails details) =>
      _distance += _toTrailing(details.primaryDelta ?? 0);

  void _handleEnd(DragEndDetails details) {
    final width = context.size?.width ?? 0;
    final velocity = _toTrailing(details.velocity.pixelsPerSecond.dx);
    final commit =
        (width > 0 &&
            _distance >= width * CommitOnlyEdgeSwipe.minDistanceFraction) ||
        velocity >= CommitOnlyEdgeSwipe.minFlingVelocity;
    if (commit && widget.route.isCurrent) {
      // The route's own pop transition plays from here.
      Navigator.of(context).maybePop();
    }
  }

  double _toTrailing(double dx) => switch (Directionality.of(context)) {
    TextDirection.ltr => dx,
    TextDirection.rtl => -dx,
  };

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.passthrough,
    children: [
      widget.child,
      PositionedDirectional(
        start: 0,
        width: CommitOnlyEdgeSwipe.edgeWidth,
        top: 0,
        bottom: 0,
        child: Listener(
          onPointerDown: _handlePointerDown,
          behavior: HitTestBehavior.translucent,
        ),
      ),
    ],
  );
}
