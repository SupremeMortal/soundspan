// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

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
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan/shared/widgets/error_view.dart';

/// The lyrics of the current track (doc 09, Now Playing, Queue, Lyrics).
///
/// Synced lyrics show the current line in `content` at `title` size and
/// the others in `contentSecondary`, and scroll to keep the current line
/// centred, over [Motion.emphasized] or at once when reduced motion is
/// requested; only a change of the current line rebuilds them. Plain
/// lyrics are selectable and scroll freely. Without lyrics it says "No
/// lyrics found"; while loading it shows skeleton lines, and a failure
/// with nothing cached shows an [ErrorView] with Retry.
class LyricsView extends ConsumerWidget {
  /// Creates the view; [scrollController] drives its scrolling when it
  /// sits in a sheet.
  const new({this.scrollController, super.key});

  /// The controller of the scrolling content, if a sheet provides one.
  final ScrollController? scrollController;

  /// The key of the skeleton shown while the lyrics load.
  static const Key skeletonKey = Key('lyrics.skeleton');

  /// The number of skeleton lines.
  static const int skeletonLines = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lyrics = ref.watch(currentLyricsProvider);
    final none = EmptyState(
      icon: Icons.lyrics_outlined,
      message: l10n.lyricsNone,
    );
    return switch (lyrics) {
      AsyncValue(:final value?) => switch (value.value) {
        SyncedLyrics(:final lines) => _SyncedLyrics(
          lines: lines,
          scrollController: scrollController,
        ),
        PlainLyrics(:final text) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(Spacing.x16),
          // Long-press selects, so the text is a tap target of its own.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Sizes.touchTarget),
            child: SelectableText(
              text,
              style: context.typography.body.copyWith(
                color: context.colors.content,
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

/// Synced lines, scrolled to keep the current one centred.
class _SyncedLyrics extends ConsumerStatefulWidget {
  const new({required this.lines, required this.scrollController});

  final List<LyricLine> lines;
  final ScrollController? scrollController;

  @override
  ConsumerState<_SyncedLyrics> createState() => _SyncedLyricsState();
}

class _SyncedLyricsState extends ConsumerState<_SyncedLyrics> {
  List<GlobalKey> _keys = [];
  int? _scrolledTo;

  @override
  void initState() {
    super.initState();
    _keys = [for (final _ in widget.lines) GlobalKey()];
  }

  @override
  void didUpdateWidget(_SyncedLyrics oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lines.length != widget.lines.length) {
      _keys = [for (final _ in widget.lines) GlobalKey()];
      _scrolledTo = null;
    }
  }

  void _centre(int? index) {
    if (index == null || index == _scrolledTo) return;
    _scrolledTo = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _keys[index].currentContext;
      if (!mounted || target == null) return;
      final duration = Motion.of(context, Motion.emphasized);
      // Not awaited: a newer line may start another scroll meanwhile.
      Scrollable.ensureVisible(
        target,
        alignment: 0.5,
        duration: duration,
        curve: Motion.curve,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.lines;
    final current = ref.watch(
      playbackSnapshotProvider.select(
        (snapshot) =>
            currentLineIndex(lines, snapshot.value?.position ?? Duration.zero),
      ),
    );
    _centre(current);
    final colors = context.colors;
    final typography = context.typography;
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(Spacing.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, line) in lines.indexed)
            Padding(
              key: _keys[index],
              padding: const EdgeInsets.symmetric(vertical: Spacing.x8),
              child: Semantics(
                selected: index == current,
                child: Text(
                  line.text,
                  style: index == current
                      ? typography.title.copyWith(color: colors.content)
                      : typography.body.copyWith(
                          color: colors.contentSecondary,
                        ),
                ),
              ),
            ),
        ],
      ),
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
