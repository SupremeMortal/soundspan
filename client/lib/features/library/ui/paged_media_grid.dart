// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/repositories.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan/shared/widgets/error_view.dart';
import 'package:soundspan/shared/widgets/media_card.dart';

/// The narrowest a grid tile gets.
const double gridMinTileWidth = 160;

/// The space between grid tiles.
const double gridSpacing = Spacing.x16;

/// The number of columns of a grid [availableWidth] wide: as many tiles of
/// at least [gridMinTileWidth] as fit with [gridSpacing] between them, from
/// 2 to 8 (doc 09, Library).
int gridColumnsFor(double availableWidth) =>
    ((availableWidth + gridSpacing) ~/ (gridMinTileWidth + gridSpacing)).clamp(
      2,
      8,
    );

/// The page gutter of [windowClass].
double gutterOf(WindowClass windowClass) => switch (windowClass) {
  WindowClass.compact => Gutters.compact,
  WindowClass.medium => Gutters.medium,
  WindowClass.expanded => Gutters.expanded,
};

/// A paged grid of [MediaCard]s over the [PagedSource] that [open] makes
/// from the library repository, under a row of [controls] that stays in
/// place while the grid scrolls (doc 09, Library).
///
/// The grid has `total` tiles; a tile whose item is not loaded is a
/// [MediaCardSkeleton], and the visible range is passed to
/// [PagedSource.ensureVisible] as it changes. Before any total is known it
/// shows one screen of skeletons. A total of 0 shows an [EmptyState] with
/// [emptyIcon] and [emptyMessage]; a failed load with nothing loaded shows
/// an [ErrorView] whose Retry refetches; a failed refresh with items
/// loaded keeps them and shows a snackbar.
///
/// A new [sourceKey] (another sort or filter) opens a new source and
/// scrolls to the top. Pull-to-refresh, and on pointer devices a refresh
/// button after [controls], refetch the visible pages.
class PagedMediaGrid<T> extends ConsumerStatefulWidget {
  /// Creates a grid of the source [open] makes for [sourceKey].
  const new({
    required this.sourceKey,
    required this.open,
    required this.itemBuilder,
    required this.emptyIcon,
    required this.emptyMessage,
    this.controls = const [],
    super.key,
  });

  /// Identifies the list; a new value opens a new source.
  final Object sourceKey;

  /// Opens the source of the list.
  final PagedSource<T> Function(LibraryRepository repository) open;

  /// Builds the card of a loaded item.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// The empty state's glyph.
  final IconData emptyIcon;

  /// The empty state's sentence, already localized.
  final String emptyMessage;

  /// The sort and filter controls above the grid.
  final List<Widget> controls;

  @override
  ConsumerState<PagedMediaGrid<T>> createState() => _PagedMediaGridState<T>();
}

class _PagedMediaGridState<T> extends ConsumerState<PagedMediaGrid<T>> {
  final ScrollController _scroll = ScrollController();
  final MouseTracker _mouseTracker = RendererBinding.instance.mouseTracker;
  late bool _mouse = _mouseTracker.mouseIsConnected;

  LibraryRepository? _repository;
  Object? _key;
  PagedSource<T>? _source;
  StreamSubscription<PagedSnapshot<T>>? _subscription;
  PagedSnapshot<T>? _snapshot;
  Object? _streamError;
  (int, int)? _requested;
  bool _ensureScheduled = false;

  @override
  void initState() {
    super.initState();
    _mouseTracker.addListener(_syncMouse);
  }

  @override
  void dispose() {
    _mouseTracker.removeListener(_syncMouse);
    _closeSource();
    _scroll.dispose();
    super.dispose();
  }

  void _syncMouse() {
    if (!mounted || _mouse == _mouseTracker.mouseIsConnected) return;
    setState(() => _mouse = _mouseTracker.mouseIsConnected);
  }

  void _closeSource() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    _source?.dispose();
    _source = null;
  }

  /// Opens the source for [repository] and the widget's key when either
  /// changed, scrolling to the top when the key did.
  void _syncSource(LibraryRepository? repository) {
    if (repository == null) return;
    final key = widget.sourceKey;
    if (identical(repository, _repository) && key == _key) return;
    final keyChanged = _key != null && key != _key;
    _closeSource();
    _repository = repository;
    _key = key;
    _snapshot = null;
    _streamError = null;
    _requested = null;
    final source = widget.open(repository);
    _source = source;
    _subscription = source.watch().listen(_onSnapshot, onError: _onError);
    if (keyChanged) {
      // Scrolling notifies listeners such as the app bar, so not during
      // this build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
      });
    }
  }

  void _onSnapshot(PagedSnapshot<T> next) {
    if (!mounted) return;
    final previous = _snapshot;
    setState(() {
      _snapshot = next;
      _streamError = null;
    });
    final error = next.refreshError;
    if (error != null &&
        previous?.refreshError == null &&
        next.loadedCount > 0) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(l10n.libraryRefreshFailed)));
    }
  }

  void _onError(Object error) {
    if (!mounted) return;
    setState(() => _streamError = error);
  }

  Future<void> _refresh() async {
    await _source?.refresh();
  }

  void _retry() {
    if (_streamError != null) {
      // The cache read failed: open the list again.
      final repository = _repository;
      _repository = null;
      setState(() => _syncSource(repository));
      return;
    }
    unawaited(_refresh());
  }

  /// Passes the visible range to the source after this frame, once per
  /// change.
  void _ensureVisible(int first, int last) {
    if (_requested == (first, last)) return;
    _requested = (first, last);
    if (_ensureScheduled) return;
    _ensureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureScheduled = false;
      final range = _requested;
      if (!mounted || range == null) return;
      _source?.ensureVisible(range.$1, range.$2);
    });
  }

  @override
  Widget build(BuildContext context) {
    _syncSource(ref.watch(libraryRepositoryProvider).value);
    final l10n = AppLocalizations.of(context);
    final gutter = gutterOf(WindowClass.of(context));
    final snapshot = _snapshot;
    final total = snapshot?.total;
    final error = _streamError ?? snapshot?.refreshError;

    final Widget body;
    if (total == 0) {
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(icon: widget.emptyIcon, message: widget.emptyMessage),
      );
    } else if (error != null && (snapshot?.loadedCount ?? 0) == 0) {
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorView(error: error, onRetry: _retry),
      );
    } else {
      body = SliverPadding(
        padding: EdgeInsets.fromLTRB(
          gutter - MediaCard.padding,
          0,
          gutter - MediaCard.padding,
          gutter,
        ),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) =>
              _grid(context, constraints, snapshot),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(gutter, Spacing.x8, gutter, Spacing.x8),
          child: Wrap(
            spacing: Spacing.x8,
            runSpacing: Spacing.x8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...widget.controls,
              if (_mouse)
                IconButton(
                  onPressed: () => unawaited(_refresh()),
                  tooltip: l10n.libraryRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [body],
            ),
          ),
        ),
      ],
    );
  }

  Widget _grid(
    BuildContext context,
    SliverConstraints constraints,
    PagedSnapshot<T>? snapshot,
  ) {
    final width = constraints.crossAxisExtent;
    final columns = gridColumnsFor(width);
    final tileWidth = (width - gridSpacing * (columns - 1)) / columns;
    final tileHeight = MediaCard.extentFor(context, width: tileWidth);
    final rowExtent = tileHeight + gridSpacing;
    final screenRows = (constraints.viewportMainAxisExtent / rowExtent).ceil();
    final total = snapshot?.total ?? columns * screenRows;

    final firstRow = (constraints.scrollOffset / rowExtent).floor();
    final lastRow =
        ((constraints.scrollOffset + constraints.remainingPaintExtent) /
                rowExtent)
            .ceil() -
        1;
    final first = math.min(firstRow * columns, math.max(0, total - 1));
    final last = math.max(
      first,
      math.min((math.max(firstRow, lastRow) + 1) * columns, total) - 1,
    );
    _ensureVisible(first, last);

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisExtent: tileHeight,
        crossAxisSpacing: gridSpacing,
        mainAxisSpacing: gridSpacing,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = snapshot?.itemAt(index);
        return item == null
            ? const MediaCardSkeleton()
            : widget.itemBuilder(context, item);
      }, childCount: total),
    );
  }
}
