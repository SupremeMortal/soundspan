// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter/services.dart'
    show KeyDownEvent, KeyRepeatEvent, LogicalKeyboardKey;
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/shared/util/duration_format.dart';

/// The position in the playing item, and the control that changes it
/// (doc 09, Components).
///
/// A 4 px track with the played part in `brand` and the buffered range in
/// `lineStrong`; the thumb shows on hover, drag and focus only. Between
/// two values of [position] it moves on with a ticker while [status] is
/// [EngineStatus.ready] and [playing], unless the platform asks for
/// reduced motion. It has its own [RepaintBoundary], so the moving
/// position repaints nothing else.
///
/// Dragging shows the dragged position and calls [onSeek] once, on
/// release; a tap seeks to the tapped point. With focus, the Left and
/// Right arrows seek 5 s back and forward, within `[0, duration]`. With an
/// unknown [duration], or without [onSeek], the bar is disabled and has no
/// thumb; without [onSeek] the position still moves.
///
/// With [showTimes], the elapsed time is shown before the bar and the
/// length after it, or with [showRemaining] the time left as `-m:ss`.
///
/// Between snapshots the position moves at [speed] times real time.
class SeekBar extends StatefulWidget {
  /// Creates the bar of an item [duration] long, at [position].
  const new({
    required this.position,
    required this.duration,
    required this.status,
    required this.playing,
    this.buffered = Duration.zero,
    this.onSeek,
    this.showTimes = false,
    this.showRemaining = false,
    this.speed = 1,
    super.key,
  });

  /// The position of the latest snapshot.
  final Duration position;

  /// How far the item is buffered.
  final Duration buffered;

  /// The item's length; null while unknown.
  final Duration? duration;

  /// What the engine is doing with the item.
  final EngineStatus status;

  /// The play intent.
  final bool playing;

  /// Called with the position to seek to.
  final ValueChanged<Duration>? onSeek;

  /// Whether the elapsed time and the length are shown beside the bar.
  final bool showTimes;

  /// Whether the time after the bar is the time left rather than the
  /// length; only with [showTimes].
  final bool showRemaining;

  /// The playback speed the position moves at between snapshots.
  final double speed;

  /// How far an arrow key seeks.
  static const Duration keyStep = Duration(seconds: 5);

  /// The height of the bar's hit area.
  static const double height = Sizes.pointerTarget;

  /// The thickness of the track.
  static const double trackHeight = 4;

  /// The diameter of the thumb.
  static const double thumbSize = 12;

  /// The key of the bar itself, without the times.
  static const Key barKey = Key('seekBar.bar');

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> with SingleTickerProviderStateMixin {
  late final ValueNotifier<Duration> _shown = ValueNotifier(widget.position);
  late final Ticker _ticker = createTicker(_onTick);

  /// The position the ticker counts from, and the ticker's elapsed time
  /// when it was taken.
  late Duration _base = widget.position;
  Duration _baseElapsed = Duration.zero;
  Duration _elapsed = Duration.zero;

  Duration? _drag;
  bool _hovering = false;
  bool _focused = false;
  bool _reduceMotion = false;

  Duration? get _duration {
    final duration = widget.duration;
    return duration == null || duration <= Duration.zero ? null : duration;
  }

  bool get _enabled => _duration != null;

  /// Whether the bar takes input: a known duration and an [SeekBar.onSeek].
  bool get _interactive => _enabled && widget.onSeek != null;

  bool get _advancing =>
      widget.status == EngineStatus.ready &&
      widget.playing &&
      !_reduceMotion &&
      _drag == null &&
      _enabled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _syncTicker();
  }

  @override
  void didUpdateWidget(SeekBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position != widget.position ||
        oldWidget.status != widget.status ||
        oldWidget.playing != widget.playing ||
        oldWidget.duration != widget.duration) {
      _rebase(widget.position);
    }
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _shown.dispose();
    super.dispose();
  }

  void _rebase(Duration position) {
    _base = position;
    _baseElapsed = _elapsed;
    if (_drag == null) _shown.value = _clamp(position);
  }

  void _syncTicker() {
    if (_advancing) {
      if (!_ticker.isActive) {
        _elapsed = Duration.zero;
        _baseElapsed = Duration.zero;
        _ticker.start();
      }
    } else if (_ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    _elapsed = elapsed;
    _shown.value = _clamp(_base + (elapsed - _baseElapsed) * widget.speed);
  }

  Duration _clamp(Duration value) {
    final duration = _duration;
    if (value < Duration.zero) return Duration.zero;
    if (duration != null && value > duration) return duration;
    return value;
  }

  Duration _at(double dx, double width) {
    final duration = _duration!;
    var fraction = width <= 0 ? 0.0 : (dx / width).clamp(0.0, 1.0);
    if (Directionality.of(context) == TextDirection.rtl) {
      fraction = 1 - fraction;
    }
    return duration * fraction;
  }

  void _seek(Duration position) {
    final target = _clamp(position);
    _rebase(target);
    widget.onSeek?.call(target);
  }

  void _step(Duration delta) {
    if (!_interactive) return;
    _seek(_shown.value + delta);
  }

  void _startDrag(Duration position) {
    setState(() => _drag = position);
    _shown.value = position;
    _syncTicker();
  }

  void _updateDrag(Duration position) {
    _drag = position;
    _shown.value = position;
  }

  void _endDrag() {
    final position = _drag;
    if (position == null) return;
    setState(() => _drag = null);
    _seek(position);
    _syncTicker();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_interactive || event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _step(-SeekBar.keyStep);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _step(SeekBar.keyStep);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bar = _bar(context);
    if (!widget.showTimes) return bar;
    final style = context.typography.caption.tabular.copyWith(
      color: colors.contentMuted,
    );
    final duration = _duration;
    return Row(
      children: [
        ExcludeSemantics(
          child: ValueListenableBuilder<Duration>(
            valueListenable: _shown,
            builder: (context, shown, _) =>
                Text(formatTrackDuration(shown), style: style),
          ),
        ),
        const SizedBox(width: Spacing.x8),
        Expanded(child: bar),
        const SizedBox(width: Spacing.x8),
        ExcludeSemantics(
          child: duration != null && widget.showRemaining
              ? ValueListenableBuilder<Duration>(
                  valueListenable: _shown,
                  builder: (context, shown, _) => Text(
                    '-${formatTrackDuration(_clamp(duration - shown))}',
                    style: style,
                  ),
                )
              : Text(
                  duration == null ? '-:--' : formatTrackDuration(duration),
                  style: style,
                ),
        ),
      ],
    );
  }

  Widget _bar(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final enabled = _interactive;
    final duration = _duration;
    final showThumb = enabled && (_hovering || _focused || _drag != null);
    final painter = _SeekBarPainter(
      shown: _shown,
      buffered: widget.buffered,
      duration: duration,
      showThumb: showThumb,
      rtl: Directionality.of(context) == TextDirection.rtl,
      track: colors.line,
      bufferedColor: colors.lineStrong,
      fill: colors.brand,
      thumb: colors.content,
    );
    return ValueListenableBuilder<Duration>(
      valueListenable: _shown,
      builder: (context, shown, child) {
        final position = formatTrackDuration(shown);
        final length = duration == null ? '' : formatTrackDuration(duration);
        String valueAt(Duration at) =>
            l10n.playerSeekValue(formatTrackDuration(_clamp(at)), length);
        return Semantics(
          slider: true,
          enabled: enabled,
          label: l10n.playerSeek,
          value: _enabled ? l10n.playerSeekValue(position, length) : null,
          increasedValue: enabled ? valueAt(shown + SeekBar.keyStep) : null,
          decreasedValue: enabled ? valueAt(shown - SeekBar.keyStep) : null,
          onIncrease: enabled ? () => _step(SeekBar.keyStep) : null,
          onDecrease: enabled ? () => _step(-SeekBar.keyStep) : null,
          child: child,
        );
      },
      child: Focus(
        canRequestFocus: enabled,
        skipTraversal: !enabled,
        onFocusChange: (focused) => setState(() => _focused = focused),
        onKeyEvent: _onKey,
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return GestureDetector(
                excludeFromSemantics: true,
                behavior: HitTestBehavior.opaque,
                onTapUp: enabled
                    ? (details) => _seek(_at(details.localPosition.dx, width))
                    : null,
                onHorizontalDragStart: enabled
                    ? (details) =>
                          _startDrag(_at(details.localPosition.dx, width))
                    : null,
                onHorizontalDragUpdate: enabled
                    ? (details) =>
                          _updateDrag(_at(details.localPosition.dx, width))
                    : null,
                onHorizontalDragEnd: enabled ? (_) => _endDrag() : null,
                onHorizontalDragCancel: enabled ? _endDrag : null,
                child: RepaintBoundary(
                  child: CustomPaint(
                    key: SeekBar.barKey,
                    size: Size(width, SeekBar.height),
                    painter: painter,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Paints the track, the buffered range, the played part and the thumb;
/// repaints when [shown] changes.
class _SeekBarPainter extends CustomPainter {
  new({
    required this.shown,
    required this.buffered,
    required this.duration,
    required this.showThumb,
    required this.rtl,
    required this.track,
    required this.bufferedColor,
    required this.fill,
    required this.thumb,
  }) : super(repaint: shown);

  final ValueListenable<Duration> shown;
  final Duration buffered;
  final Duration? duration;
  final bool showThumb;
  final bool rtl;
  final Color track;
  final Color bufferedColor;
  final Color fill;
  final Color thumb;

  double _fraction(Duration value) {
    final duration = this.duration;
    if (duration == null) return 0;
    return (value.inMicroseconds / duration.inMicroseconds).clamp(0.0, 1.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final top = (size.height - SeekBar.trackHeight) / 2;
    const radius = Radius.circular(SeekBar.trackHeight / 2);
    RRect bar(double fraction) => RRect.fromLTRBR(
      rtl ? size.width * (1 - fraction) : 0,
      top,
      rtl ? size.width : size.width * fraction,
      top + SeekBar.trackHeight,
      radius,
    );
    canvas
      ..drawRRect(bar(1), Paint()..color = track)
      ..drawRRect(bar(_fraction(buffered)), Paint()..color = bufferedColor);
    final played = _fraction(shown.value);
    canvas.drawRRect(bar(played), Paint()..color = fill);
    if (showThumb) {
      canvas.drawCircle(
        Offset(
          rtl ? size.width * (1 - played) : size.width * played,
          size.height / 2,
        ),
        SeekBar.thumbSize / 2,
        Paint()..color = thumb,
      );
    }
  }

  @override
  bool shouldRepaint(_SeekBarPainter old) =>
      old.shown != shown ||
      old.buffered != buffered ||
      old.duration != duration ||
      old.showThumb != showThumb ||
      old.rtl != rtl ||
      old.track != track ||
      old.bufferedColor != bufferedColor ||
      old.fill != fill ||
      old.thumb != thumb;
}
