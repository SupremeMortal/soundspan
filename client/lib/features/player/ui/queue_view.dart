// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/features/listen_together/listen_together.dart';
import 'package:soundspan/features/player/ui/player_item.dart';
import 'package:soundspan/features/player/ui/queue_context_label.dart';
import 'package:soundspan/shared/actions/app_menu_commands.dart';
import 'package:soundspan/shared/actions/track_actions.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan/shared/widgets/group_controls.dart';
import 'package:soundspan/shared/widgets/track_row.dart';

/// The play queue (doc 09, Now Playing, Queue, Lyrics): a "Now playing"
/// section with the current entry, a "Next up" section with the entries
/// after it in play order, and a "Clear" action.
///
/// Tapping a "Next up" row plays it. Those rows are reordered by dragging
/// (by a trailing handle on touch platforms, by the whole row with a
/// pointer) and removed with their remove button; screen readers get the
/// same as custom actions. Every edit is a controller command addressing
/// the entry, not the track. A track entry of "Next up" also opens the track
/// menu (doc 09, Track Actions) from its overflow button, a long press or a
/// secondary click, over the queue's tracks in play order. The rows have a fixed extent and are built
/// lazily. An empty queue, and a profile whose controller does not exist
/// yet, shows an [EmptyState].
class QueueView extends ConsumerWidget {
  /// Creates the queue view; [scrollController] drives its scroll view, as
  /// a draggable sheet needs.
  const new({this.scrollController, super.key});

  /// The controller of the scroll view, or null for its own.
  final ScrollController? scrollController;

  /// The key of the "Clear" action.
  static const Key clearKey = Key('queue.clear');

  /// The key of the row of the entry [queueItemId].
  static Key rowKey(String queueItemId) => Key('queue.row.$queueItemId');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final queue = ref.watch(playbackControllerProvider.exists)
        ? ref.watch(playbackStateProvider).value?.queue
        : null;
    final current = queue?.current;
    final cursor = queue?.cursor;
    if (queue == null || current == null || cursor == null) {
      return EmptyState(
        icon: Icons.queue_music_rounded,
        message: l10n.queueEmpty,
      );
    }
    final controller = ref.read(playbackControllerProvider);
    final locked = hostControlsPlayback(ref);
    final order = queue.playOrder;
    final upNextCount = order.length - cursor - 1;
    final extent = TrackRow.extentFor(context, withThumbnail: true);
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        const SliverToBoxAdapter(child: ListenTogetherQueueHeader()),
        if (queueContextLabel(l10n, queue.context) case final label?)
          SliverToBoxAdapter(child: _ContextLine(label)),
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: l10n.queueNowPlaying,
            action: TextButton(
              key: clearKey,
              onPressed: () => unawaited(controller.clear()),
              child: Text(l10n.queueClear),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.x8),
          sliver: SliverToBoxAdapter(
            child: SizedBox(
              height: extent,
              child: _QueueRow(
                key: rowKey(current.queueItemId),
                item: current,
                selected: true,
              ),
            ),
          ),
        ),
        if (upNextCount > 0) ...[
          SliverToBoxAdapter(child: _SectionHeader(title: l10n.queueNextUp)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.x8,
              0,
              Spacing.x8,
              Spacing.x16,
            ),
            sliver: _NextUpList(
              queue: queue,
              order: order,
              cursor: cursor,
              count: upNextCount,
              extent: extent,
              controller: controller,
              locked: locked,
            ),
          ),
        ],
      ],
    );
  }
}

/// The reorderable "Next up" rows.
class _NextUpList extends ConsumerWidget {
  const new({
    required this.queue,
    required this.order,
    required this.cursor,
    required this.count,
    required this.extent,
    required this.controller,
    required this.locked,
  });

  final QueueState queue;
  final List<int> order;
  final int cursor;
  final int count;
  final double extent;
  final PlaybackController controller;

  /// Whether only the group's host may reorder: no drag, no move actions.
  final bool locked;

  QueueItem _itemAt(int index) => queue.items[order[cursor + 1 + index]];

  void _move(int from, int to) {
    if (from == to || to < 0 || to >= count) return;
    unawaited(controller.move(_itemAt(from).queueItemId, cursor + 1 + to));
  }

  /// Opens the track menu of [item] at [position], over the queue's
  /// tracks in play order.
  void _openMenu(
    BuildContext context,
    WidgetRef ref,
    TrackQueueItem item,
    Offset? position,
  ) {
    final entries = [
      for (final i in order)
        if (queue.items[i] case final TrackQueueItem entry) entry,
    ];
    unawaited(
      openTrackMenu(
        context,
        ref,
        TrackActionScope(
          track: item.track,
          tracks: [for (final entry in entries) entry.track],
          index: entries.indexWhere((e) => e.queueItemId == item.queueItemId),
          context: queue.context ?? item.context,
        ),
        position: position,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final touch = switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
    return SliverReorderableList(
      itemCount: count,
      itemExtent: extent,
      onReorderItem: _move,
      itemBuilder: (context, index) {
        final item = _itemAt(index);
        final id = item.queueItemId;
        void remove() => unawaited(controller.removeAt(id));
        final row = _QueueRow(
          item: item,
          onTap: () => unawaited(controller.jumpTo(id)),
          onMenu: item is TrackQueueItem
              ? (position) => _openMenu(context, ref, item, position)
              : null,
          onAddToQueue: item is TrackQueueItem
              ? addToQueueOf(ref, item.track)
              : null,
          semanticActions: {
            CustomSemanticsAction(label: l10n.queueRemove): remove,
            if (!locked && index > 0)
              CustomSemanticsAction(label: l10n.queueMoveUp): () =>
                  _move(index, index - 1),
            if (!locked && index < count - 1)
              CustomSemanticsAction(label: l10n.queueMoveDown): () =>
                  _move(index, index + 1),
          },
        );
        final line = Row(
          children: [
            Expanded(child: row),
            IconButton(
              tooltip: l10n.queueRemove,
              color: colors.contentSecondary,
              icon: const Icon(Icons.close_rounded),
              onPressed: remove,
            ),
            if (touch && !locked)
              ReorderableDragStartListener(
                index: index,
                child: SizedBox.square(
                  dimension: Sizes.touchTarget,
                  child: Tooltip(
                    message: l10n.queueReorderHandle,
                    child: Icon(
                      Icons.drag_handle_rounded,
                      color: colors.contentSecondary,
                    ),
                  ),
                ),
              ),
          ],
        );
        return KeyedSubtree(
          key: QueueView.rowKey(id),
          child: touch || locked
              ? line
              : ReorderableDragStartListener(index: index, child: line),
        );
      },
    );
  }
}

/// One queue entry as a [TrackRow] with its cover.
class _QueueRow extends StatelessWidget {
  const new({
    required this.item,
    this.selected = false,
    this.onTap,
    this.onMenu,
    this.onAddToQueue,
    this.semanticActions = const {},
    super.key,
  });

  final QueueItem item;
  final bool selected;
  final VoidCallback? onTap;
  final void Function(Offset? position)? onMenu;
  final VoidCallback? onAddToQueue;
  final Map<CustomSemanticsAction, VoidCallback> semanticActions;

  @override
  Widget build(BuildContext context) => TrackRow(
    title: item.playerTitle,
    artist: item.playerSubtitle,
    duration: item.playerDuration,
    leading: TrackRowLeading.thumbnail(item.playerArtworkRef),
    selected: selected,
    onTap: onTap,
    onMenu: onMenu,
    onAddToQueue: onAddToQueue,
    semanticActions: semanticActions,
  );
}

/// What the queue plays from, above the sections.
class _ContextLine extends StatelessWidget {
  const new(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(
      Spacing.x16,
      Spacing.x16,
      Spacing.x16,
      0,
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.typography.caption.copyWith(
        color: context.colors.contentSecondary,
      ),
    ),
  );
}

/// A section title in `subtitle`, with an optional action at the end.
class _SectionHeader extends StatelessWidget {
  const new({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        Spacing.x16,
        Spacing.x16,
        Spacing.x8,
        Spacing.x8,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Sizes.touchTarget),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: context.typography.subtitle.copyWith(
                    color: colors.content,
                  ),
                ),
              ),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}
