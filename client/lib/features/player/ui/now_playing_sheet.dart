// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';

/// The page of the `/now-playing` route on compact and medium windows: a
/// bottom sheet over the page it was opened from (doc 09, Shell by Window
/// Class). Its route is a [NowPlayingSheetRoute].
class NowPlayingSheetPage extends Page<void> {
  /// Creates the page; [openDrag] makes the sheet follow the drag that
  /// opened it instead of sliding up on its own.
  const new({required this.child, this.openDrag, super.key, super.name});

  /// The sheet's content.
  final Widget child;

  /// The drag that opens the sheet, if one does.
  final NowPlayingOpenDrag? openDrag;

  @override
  Route<void> createRoute(BuildContext context) => NowPlayingSheetRoute(this);
}

/// The route of a [NowPlayingSheetPage]: a full-height sheet that slides up
/// over the page beneath it, which stays painted, over the `scrim` fading
/// in with it.
///
/// It is not opaque and has no horizontal back gesture. A pop (the close
/// button, system back, a committed Android predictive back, Escape) slides
/// it down. A drag moves it through [startDrag], [dragTo] and [endDrag]. Its
/// animations last [Motion.emphasized] on [Motion.curve] for a full slide,
/// and none with reduced motion.
class NowPlayingSheetRoute extends PageRoute<void> {
  /// Creates the route of [page].
  new(NowPlayingSheetPage page) : super(settings: page);

  NowPlayingSheetPage get _page => settings as NowPlayingSheetPage;

  /// The [NowPlayingSheetRoute] showing [context], if any.
  static NowPlayingSheetRoute? of(BuildContext context) =>
      switch (ModalRoute.of(context)) {
        final NowPlayingSheetRoute route => route,
        _ => null,
      };

  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration =>
      _reduceMotion ? Duration.zero : Motion.emphasized;

  // The page beneath stays still: no transition of its own runs.
  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) => false;

  // A pop slides the sheet down; no edge swipe or predictive back moves it.
  @override
  bool get popGestureEnabled => false;

  bool get _reduceMotion =>
      navigator?.context
          .getInheritedWidgetOfExactType<MediaQuery>()
          ?.data
          .disableAnimations ??
      false;

  /// Animates the sheet to [target] (0 closed, 1 open) over the part of
  /// [Motion.emphasized] the distance takes.
  TickerFuture _animateTo(double target) {
    final controller = this.controller!;
    final duration = _reduceMotion
        ? Duration.zero
        : Motion.emphasized * (target - controller.value).abs();
    return target >= controller.value
        ? controller.animateTo(target, duration: duration, curve: Motion.curve)
        : controller.animateBack(
            target,
            duration: duration,
            curve: Motion.curve,
          );
  }

  @override
  TickerFuture didPush() {
    unawaited(super.didPush());
    final drag = _page.openDrag;
    if (drag != null && drag._attach(this)) return TickerFuture.complete();
    return _animateTo(1);
  }

  @override
  bool didPop(void result) {
    final popped = super.didPop(result);
    // The slide down eases out like every other slide of the sheet.
    final controller = this.controller!;
    if (controller.isAnimating) {
      controller.animateBack(
        0,
        duration: Motion.emphasized * controller.value,
        curve: Motion.curve,
      );
    }
    return popped;
  }

  // Leaves the push animation for an open that follows a drag. The push
  // runs while the navigator builds, so the gesture starts after the frame.
  void _followOpenDrag(NowPlayingOpenDrag drag) {
    controller!
      ..stop()
      ..value = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isCurrent) return;
      startDrag();
      dragTo(drag._fraction);
      final endedOpen = drag._endedOpen;
      if (endedOpen != null) endDrag(open: endedOpen);
    });
  }

  /// The navigator counting this route's drag as a user gesture, from
  /// [startDrag] until the sheet settles after [endDrag].
  NavigatorState? _gestureNavigator;

  /// Whether a drag is moving the sheet.
  bool _following = false;

  AnimationStatusListener? _settled;

  /// Starts a drag that moves the sheet, stopping any slide in progress.
  /// The navigator counts a user gesture until the sheet settles after
  /// [endDrag].
  void startDrag() {
    final navigator = this.navigator;
    if (_following || navigator == null || !isCurrent) return;
    _following = true;
    final controller = this.controller!;
    final settled = _settled;
    if (settled != null) controller.removeStatusListener(settled);
    _settled = null;
    controller.stop();
    if (_gestureNavigator == null) {
      _gestureNavigator = navigator;
      navigator.didStartUserGesture();
    }
  }

  /// Shows [fraction] of the sheet's height, unless the platform asks for
  /// reduced motion.
  void dragTo(double fraction) {
    if (!_following || !isCurrent || _reduceMotion) return;
    controller!.value = fraction.clamp(0.0, 1.0);
  }

  /// Ends the drag: the sheet slides open when [open], and otherwise the
  /// route pops, sliding the sheet down from where it is.
  void endDrag({required bool open}) {
    if (!_following) return;
    _following = false;
    if (!isCurrent) return _stopGesture();
    if (open) {
      unawaited(_animateTo(1));
    } else {
      navigator!.pop();
    }
    final controller = this.controller!;
    if (!controller.isAnimating) return _stopGesture();
    void settled(AnimationStatus status) {
      if (status.isAnimating) return;
      controller.removeStatusListener(settled);
      _settled = null;
      _stopGesture();
    }

    _settled = settled;
    controller.addStatusListener(settled);
  }

  void _stopGesture() {
    final navigator = _gestureNavigator;
    if (navigator == null) return;
    _gestureNavigator = null;
    if (!navigator.mounted) return;
    navigator.didStopUserGesture();
    // The gesture took focus from the route; once the route can take focus
    // again (after this frame), its last focused widget gets it back.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = subtreeContext;
      if (!isCurrent || _following || context == null || !context.mounted) {
        return;
      }
      final scope = FocusScope.of(context);
      if (!scope.hasFocus) scope.requestFocus();
    });
  }

  @override
  void dispose() {
    _following = false;
    _stopGesture();
    super.dispose();
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => _page.child;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => Stack(
    fit: StackFit.expand,
    children: [
      FadeTransition(
        opacity: animation,
        child: ColoredBox(color: context.colors.scrim),
      ),
      SlideTransition(
        position: animation.drive(
          Tween(begin: const Offset(0, 1), end: Offset.zero),
        ),
        child: child,
      ),
    ],
  );
}

/// A drag that opens the now playing sheet as it goes, such as the mini
/// player's swipe up. Pass it as the `extra` of the `/now-playing` push when
/// the drag starts; the [NowPlayingSheetRoute] it creates then follows
/// [update] instead of sliding up, and [end] opens or closes it.
final class NowPlayingOpenDrag {
  /// Creates a drag with the sheet closed.
  new();

  NowPlayingSheetRoute? _route;
  double _fraction = 0;
  bool? _endedOpen;

  /// Whether the drag has ended.
  bool get isEnded => _endedOpen != null;

  /// Makes [route] follow this drag unless another route already does;
  /// returns whether it does.
  bool _attach(NowPlayingSheetRoute route) {
    if (_route != null) return false;
    _route = route;
    route._followOpenDrag(this);
    return true;
  }

  /// Shows [fraction] of the sheet's height.
  void update(double fraction) {
    if (isEnded) return;
    _fraction = fraction;
    _route?.dragTo(fraction);
  }

  /// Ends the drag: the sheet opens fully when [open], and otherwise slides
  /// back down and its route pops.
  void end({required bool open}) {
    if (isEnded) return;
    _endedOpen = open;
    _route?.endDrag(open: open);
  }
}
