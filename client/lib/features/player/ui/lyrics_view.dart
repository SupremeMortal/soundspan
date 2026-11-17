// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/rendering.dart'
    show RenderAbstractViewport, ScrollDirection;
import 'package:flutter/services.dart'
    show KeyDownEvent, KeyEvent, KeyRepeatEvent, LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/features/player/domain/lrc.dart';
import 'package:soundspan/features/player/domain/lyrics.dart';
import 'package:soundspan/features/player/lyrics_providers.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/util/duration_format.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan/shared/widgets/error_view.dart';
import 'package:soundspan/shared/widgets/group_controls.dart';

/// The lyrics of the current track (doc 09, Now Playing, Queue, Lyrics).
///
/// Synced lyrics show the current line in `content` at `title` size and
/// the others in `contentSecondary` (`headline` and `subtitle` when
/// [large]); only a change of the current line rebuilds them. Each synced
/// line is a button that seeks to it through the playback controller,
/// disabled with "The host controls playback" for a Listen Together
/// follower; Up and Down move focus between lines. While following, a
/// line change scrolls the current line to [followAlignment] of the view
/// over [Motion.emphasized], or at once when reduced motion is requested.
/// A user scroll (drag, wheel, trackpad, scrollbar, keyboard paging)
/// pauses following and shows "Resume auto-scroll"; following resumes
/// from that button, from tapping a line, or [resumeAfter] after the last
/// user scroll by the [Clock]. A track change resets to following at the
/// top. Plain lyrics are selectable and scroll freely. Without lyrics it
/// says "No lyrics found"; while loading it shows skeleton lines, and a
/// failure with nothing cached shows an [ErrorView] with Retry.
class LyricsView extends ConsumerWidget {
  /// Creates the view; [scrollController] drives its scrolling when it
  /// sits in a sheet, and [large] steps the type up one level and keeps
  /// lines to [maxLineWidth], as in the now-playing overlay.
  const new({this.scrollController, this.large = false, super.key});

  /// The controller of the scrolling content, if a sheet provides one.
  final ScrollController? scrollController;

  /// Whether the view uses the larger type of the now-playing overlay.
  final bool large;

  /// The key of the skeleton shown while the lyrics load.
  static const Key skeletonKey = Key('lyrics.skeleton');

  /// The key of each ♪ marker standing for an instrumental gap.
  static const Key instrumentalKey = Key('lyrics.instrumental');

  /// The number of skeleton lines.
  static const int skeletonLines = 8;

  /// Where in the view the current line is scrolled to, from the top.
  static const double followAlignment = 0.35;

  /// How long after the last user scroll following resumes by itself.
  static const Duration resumeAfter = Duration(seconds: 5);

  /// The widest a line is when [large].
  static const double maxLineWidth = 640;

  /// How many times synced lines were built, for tests asserting that
  /// position ticks within a line rebuild nothing.
  @visibleForTesting
  static int debugLineListBuilds = 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lyrics = ref.watch(currentLyricsProvider);
    final none = EmptyState(
      icon: Icons.lyrics_outlined,
      message: l10n.lyricsNone,
    );
    final typography = context.typography;
    return switch (lyrics) {
      AsyncValue(:final value?) => switch (value.value) {
        SyncedLyrics(:final lines) => _SyncedLyrics(
          lines: lines,
          scrollController: scrollController,
          large: large,
        ),
        PlainLyrics(:final text) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(Spacing.x16),
          // Long-press selects, so the text is a tap target of its own.
          child: _LineWidth(
            large: large,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: Sizes.touchTarget),
              child: SelectableText(
                text,
                style: (large ? typography.subtitle : typography.body).copyWith(
                  color: context.colors.content,
                ),
              ),
            ),
          ),
        ),
        NoLyrics() => none,
      },
      AsyncValue(isLoading: true) => const _Skeleton(),
      AsyncValue(:final error?) => ErrorView(
        error: error,
        onRetry: () => ref.invalidate(currentLyricsProvider),
      ),
      _ => none,
    };
  }
}

/// [child] aligned to the start, at most [LyricsView.maxLineWidth] wide
/// when [large].
class _LineWidth extends StatelessWidget {
  const new({required this.large, required this.child, super.key});

  final bool large;
  final Widget child;

  @override
  Widget build(BuildContext context) => large
      ? Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: LyricsView.maxLineWidth,
            ),
            child: child,
          ),
        )
      : child;
}

/// Synced lines that seek when activated, following the current one.
class _SyncedLyrics extends ConsumerStatefulWidget {
  const new({
    required this.lines,
    required this.scrollController,
    required this.large,
  });

  final List<LyricLine> lines;
  final ScrollController? scrollController;
  final bool large;

  @override
  ConsumerState<_SyncedLyrics> createState() => _SyncedLyricsState();
}

class _SyncedLyricsState extends ConsumerState<_SyncedLyrics> {
  List<GlobalKey> _keys = [];
  List<FocusNode> _nodes = [];
  ScrollController? _ownController;

  /// Whether line changes scroll the view.
  bool _following = true;

  /// The line last scrolled to while following.
  int? _scrolledTo;

  /// The line just tapped, shown as current until the position reports a
  /// line of its own.
  int? _tapped;

  /// When the user last scrolled, by the [Clock].
  DateTime? _lastUserScroll;
  Timer? _resumeTimer;

  ScrollController get _controller =>
      widget.scrollController ?? (_ownController ??= ScrollController());

  @override
  void initState() {
    super.initState();
    _createLines();
  }

  @override
  void didUpdateWidget(_SyncedLyrics oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.lines, widget.lines)) {
      _disposeLines();
      _createLines();
      _scrolledTo = null;
      _tapped = null;
    }
  }

  @override
  void dispose() {
    _resumeTimer?.cancel();
    _disposeLines();
    _ownController?.dispose();
    super.dispose();
  }

  void _createLines() {
    _keys = [for (final _ in widget.lines) GlobalKey()];
    _nodes = [
      for (final (index, _) in widget.lines.indexed)
        FocusNode(debugLabel: 'lyrics line $index'),
    ];
  }

  void _disposeLines() {
    for (final node in _nodes) {
      node.dispose();
    }
  }

  /// Follows again, from the top: the current item changed.
  void _restart() {
    _resumeTimer?.cancel();
    _lastUserScroll = null;
    _scrolledTo = null;
    _tapped = null;
    if (_controller.hasClients) _controller.jumpTo(0);
    if (!_following) setState(() => _following = true);
  }

  /// Follows again, scrolling to the current line.
  void _resume() {
    _resumeTimer?.cancel();
    _lastUserScroll = null;
    setState(() {
      _following = true;
      _scrolledTo = null;
    });
  }

  void _userScrolled() {
    _lastUserScroll = ref.read(clockProvider).now();
    if (_following) setState(() => _following = false);
    _scheduleResume(LyricsView.resumeAfter);
  }

  void _scheduleResume(Duration after) {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(after, () {
      final last = _lastUserScroll;
      if (!mounted || last == null) return;
      final elapsed = ref.read(clockProvider).now().difference(last);
      if (elapsed >= LyricsView.resumeAfter) {
        _resume();
      } else {
        _scheduleResume(LyricsView.resumeAfter - elapsed);
      }
    });
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    final user = switch (notification) {
      UserScrollNotification(:final direction) =>
        direction != ScrollDirection.idle,
      ScrollStartNotification(:final dragDetails) => dragDetails != null,
      ScrollUpdateNotification(:final dragDetails) => dragDetails != null,
      _ => false,
    };
    if (user) _userScrolled();
    return false;
  }

  void _seek(int index) {
    _resumeTimer?.cancel();
    _lastUserScroll = null;
    setState(() {
      _following = true;
      _scrolledTo = null;
      _tapped = index;
    });
    unawaited(
      ref.read(playbackControllerProvider).seek(widget.lines[index].time),
    );
  }

  /// Scrolls [index] to [LyricsView.followAlignment] after this frame.
  void _follow(int? index) {
    if (index == null || index == _scrolledTo) return;
    _scrolledTo = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_following || !_controller.hasClients) return;
      final target = _keys[index].currentContext?.findRenderObject();
      if (target == null) return;
      final viewport = RenderAbstractViewport.maybeOf(target);
      if (viewport == null) return;
      final position = _controller.position;
      final offset = viewport
          .getOffsetToReveal(target, LyricsView.followAlignment)
          .offset
          .clamp(position.minScrollExtent, position.maxScrollExtent);
      final duration = Motion.of(context, Motion.emphasized);
      if (duration == Duration.zero) {
        position.jumpTo(offset);
      } else {
        // Not awaited: a newer line may start another scroll meanwhile.
        unawaited(
          position.animateTo(offset, duration: duration, curve: Motion.curve),
        );
      }
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final step = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowDown => 1,
      LogicalKeyboardKey.arrowUp => -1,
      _ => 0,
    };
    final index = _nodes.indexWhere((node) => node.hasPrimaryFocus);
    if (step == 0 || index < 0) return KeyEventResult.ignored;
    final next = (index + step).clamp(0, _nodes.length - 1);
    _nodes[next].requestFocus();
    if (_keys[next].currentContext case final target?) {
      Scrollable.ensureVisible(
        target,
        alignmentPolicy: step > 0
            ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
            : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.lines;
    ref.listen(
      playbackStateProvider.select(
        (snapshot) => snapshot.value?.current?.queueItemId,
      ),
      (previous, next) {
        if (previous != next) _restart();
      },
    );
    final positionLine = playbackSnapshotProvider.select(
      (snapshot) =>
          currentLineIndex(lines, snapshot.value?.position ?? Duration.zero),
    );
    ref.listen(positionLine, (_, _) => _tapped = null);
    final reported = ref.watch(positionLine);
    final current = _tapped ?? reported;
    final locked = hostControlsPlayback(ref);
    // Hidden (a closed tab, an offstage route): no scrolling work.
    if (_following && TickerMode.valuesOf(context).enabled) _follow(current);
    LyricsView.debugLineListBuilds++;
    return Stack(
      children: [
        Positioned.fill(
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: Actions(
              actions: {ScrollIntent: _UserScrollAction(_userScrolled)},
              child: Focus(
                canRequestFocus: false,
                skipTraversal: true,
                onKeyEvent: _onKey,
                child: SingleChildScrollView(
                  controller: _controller,
                  padding: const EdgeInsets.all(Spacing.x16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (index, line) in lines.indexed)
                        _LineWidth(
                          key: _keys[index],
                          large: widget.large,
                          child: _LyricLineButton(
                            line: line,
                            current: index == current,
                            large: widget.large,
                            locked: locked,
                            focusNode: _nodes[index],
                            onSeek: () => _seek(index),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (!_following)
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: Spacing.x16,
            child: Center(
              child: FilledButton.icon(
                key: _resumeKey,
                style: FilledButton.styleFrom(shape: const StadiumBorder()),
                onPressed: _resume,
                icon: const Icon(Icons.vertical_align_center_rounded),
                label: Text(
                  AppLocalizations.of(context).lyricsResumeAutoScroll,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

const Key _resumeKey = Key('lyrics.resume');

/// The scroll action of keyboard paging, which also reports a user scroll.
class _UserScrollAction extends ScrollAction {
  new(this._onUserScroll);

  final VoidCallback _onUserScroll;

  @override
  void invoke(ScrollIntent intent, [BuildContext? context]) {
    _onUserScroll();
    super.invoke(intent, context);
  }
}

/// One synced line: a button seeking to it, a ♪ marker for an instrumental
/// gap.
class _LyricLineButton extends StatelessWidget {
  const new({
    required this.line,
    required this.current,
    required this.large,
    required this.locked,
    required this.focusNode,
    required this.onSeek,
  });

  final LyricLine line;
  final bool current;
  final bool large;
  final bool locked;
  final FocusNode focusNode;
  final VoidCallback onSeek;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final typography = context.typography;
    final style = current
        ? (large ? typography.headline : typography.title).copyWith(
            color: colors.content,
          )
        : (large ? typography.subtitle : typography.body).copyWith(
            color: colors.contentSecondary,
          );
    final gap = line.text.isEmpty;
    final button = Semantics(
      container: true,
      button: true,
      enabled: !locked,
      selected: current,
      label: gap ? l10n.lyricsInstrumental : line.text,
      hint: locked
          ? l10n.listenTogetherHostControls
          : l10n.lyricsSeekHint(formatTrackDuration(line.time)),
      child: InkWell(
        focusNode: focusNode,
        onTap: locked ? null : onSeek,
        borderRadius: BorderRadius.circular(Radii.small),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Sizes.touchTarget),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.x8,
                vertical: Spacing.x8,
              ),
              child: ExcludeSemantics(
                child: gap
                    // The ♪ marker; an icon, as text fonts lack the glyph.
                    ? Icon(
                        Icons.music_note_rounded,
                        key: LyricsView.instrumentalKey,
                        color: style.color,
                        size: MediaQuery.textScalerOf(context)
                            .scale(style.fontSize!),
                      )
                    : Text(line.text, style: style),
              ),
            ),
          ),
        ),
      ),
    );
    if (!locked) return button;
    return Tooltip(
      message: l10n.listenTogetherHostControls,
      excludeFromSemantics: true,
      child: button,
    );
  }
}

/// `surfaceHighlight` bars standing for lines while the lyrics load.
class _Skeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final height = MediaQuery.textScalerOf(context)
        .scale(context.typography.body.fontSize!);
    return ExcludeSemantics(
      child: SingleChildScrollView(
        key: LyricsView.skeletonKey,
        padding: const EdgeInsets.all(Spacing.x16),
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < LyricsView.skeletonLines; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.x8),
                child: FractionallySizedBox(
                  widthFactor: const [0.7, 0.5, 0.8, 0.6][i % 4],
                  child: Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: colors.surfaceHighlight,
                      borderRadius: BorderRadius.circular(Spacing.x4),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The lyrics in the right-hand panel of expanded windows: a "Lyrics" title
/// above the [LyricsView].
class LyricsPanel extends StatelessWidget {
  /// Creates the panel content.
  const new({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          Spacing.x16,
          Spacing.x16,
          Spacing.x16,
          0,
        ),
        child: Semantics(
          header: true,
          child: Text(
            AppLocalizations.of(context).lyricsTitle,
            style: context.typography.title.copyWith(
              color: context.colors.content,
            ),
          ),
        ),
      ),
      const Expanded(child: LyricsView()),
    ],
  );
}

/// Opens the lyrics as a modal sheet over the now-playing screen, reading
/// the providers of [context]'s scope as the queue sheet does.
Future<void> showLyricsSheet(BuildContext context) {
  final container = ProviderScope.containerOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: context.colors.surface,
    builder: (_) => UncontrolledProviderScope(
      container: container,
      child: const LyricsSheet(),
    ),
  );
}

/// The content of the lyrics sheet: a "Lyrics" title above the
/// [LyricsView], in a sheet that opens at 70 % of the height and drags to
/// full height.
class LyricsSheet extends StatelessWidget {
  /// Creates the sheet content.
  const new({super.key});

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.7,
    minChildSize: 0.4,
    builder: (context, scrollController) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.x16),
          child: Semantics(
            header: true,
            child: Text(
              AppLocalizations.of(context).lyricsTitle,
              style: context.typography.title.copyWith(
                color: context.colors.content,
              ),
            ),
          ),
        ),
        Expanded(child: LyricsView(scrollController: scrollController)),
      ],
    ),
  );
}
