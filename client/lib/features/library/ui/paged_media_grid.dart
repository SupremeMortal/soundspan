// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/features/library/ui/paged_library_view.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/widgets/media_card.dart';
import 'package:soundspan/shared/widgets/media_grid_layout.dart';

/// A paged grid of [MediaCard]s over the [PagedSource] that [open] makes
/// from the library repository, in a [PagedLibraryView] under [controls]
/// (doc 09, Library).
///
/// The grid has `total` tiles; a tile whose item is not loaded is a
/// [MediaCardSkeleton]. Before any total is known it shows one screen of
/// skeletons. A long grid has the fast-scroll thumb on touch input.
class PagedMediaGrid<T> extends StatelessWidget {
  /// Creates a grid of the source [open] makes for [sourceKey].
  const new({
    required this.sourceKey,
    required this.open,
    required this.itemBuilder,
    required this.emptyIcon,
    required this.emptyMessage,
    this.controls = const [],
    this.bubbleTitle,
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

  /// The title the fast-scroll bubble takes its letter from, when the order
  /// is alphabetical (see [PagedLibraryView.bubbleTitle]).
  final String Function(T item)? bubbleTitle;

  @override
  Widget build(BuildContext context) => PagedLibraryView<T>(
    sourceKey: sourceKey,
    open: open,
    emptyIcon: emptyIcon,
    emptyMessage: emptyMessage,
    controls: controls,
    fastScroll: true,
    bubbleTitle: bubbleTitle,
    itemsBuilder: _grid,
  );

  Widget _grid(
    BuildContext context,
    SliverConstraints constraints,
    PagedSnapshot<T>? snapshot,
    void Function(int first, int last) ensureVisible,
  ) {
    final gutter = gutterOf(WindowClass.of(context));
    final width =
        constraints.crossAxisExtent - 2 * (gutter - MediaCard.padding);
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
    ensureVisible(first, last);

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        gutter - MediaCard.padding,
        0,
        gutter - MediaCard.padding,
        gutter,
      ),
      sliver: SliverGrid(
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
              : itemBuilder(context, item);
        }, childCount: total),
      ),
    );
  }
}
