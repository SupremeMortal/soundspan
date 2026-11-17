// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The Library's Downloads tab (doc 09, Library: Downloads): a storage
/// summary, the pinned collections with their progress and size, an "In
/// progress" filter and Pause all / Resume all.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/download_state_machine.dart'
    show DownloadWaitReason;
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/downloads/offline_models.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/features/downloads/ui/download_actions.dart';
import 'package:soundspan/features/downloads/ui/download_glyph_mapper.dart';
import 'package:soundspan/features/downloads/ui/download_providers.dart';
import 'package:soundspan/features/downloads/ui/download_sheets.dart';
import 'package:soundspan/platform/artwork_store/artwork_store.dart';
import 'package:soundspan/shared/util/byte_format.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/context_menu.dart';
import 'package:soundspan/shared/widgets/download_glyph.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';

/// The totals of the Downloads tab's header, from the state of every item.
@immutable
final class DownloadTotals {
  /// Creates the totals.
  const new({
    required this.completedCount,
    required this.completedBytes,
    required this.activeCount,
    required this.pausedCount,
  });

  /// Sums [items]: completed ones and their size; active ones (queued,
  /// running, verifying, paused) and those the user paused or holds.
  factory of(Iterable<ItemDownloadState> items) {
    var completed = 0;
    var bytes = 0;
    var active = 0;
    var paused = 0;
    for (final item in items) {
      switch (item.status) {
        case DownloadStatus.completed:
          completed++;
          bytes += item.sizeBytes ?? item.expectedBytes ?? item.receivedBytes;
        case DownloadStatus.queued ||
            DownloadStatus.running ||
            DownloadStatus.verifying ||
            DownloadStatus.paused:
          active++;
          if (item.waitingFor == DownloadWaitReason.user) paused++;
        case _:
          break;
      }
    }
    return DownloadTotals(
      completedCount: completed,
      completedBytes: bytes,
      activeCount: active,
      pausedCount: paused,
    );
  }

  /// The number of downloaded items.
  final int completedCount;

  /// Their size on disk.
  final int completedBytes;

  /// The number of items still to download.
  final int activeCount;

  /// The number of those the user paused.
  final int pausedCount;

  @override
  bool operator ==(Object other) =>
      other is DownloadTotals &&
      other.completedCount == completedCount &&
      other.completedBytes == completedBytes &&
      other.activeCount == activeCount &&
      other.pausedCount == pausedCount;

  @override
  int get hashCode =>
      Object.hash(completedCount, completedBytes, activeCount, pausedCount);
}

/// The Downloads tab of the Library.
class DownloadsTab extends ConsumerStatefulWidget {
  /// Creates the tab.
  const new({super.key});

  /// The key of the "In progress" filter chip.
  static const Key inProgressKey = ValueKey('downloads.filter.inProgress');

  /// The key of the Pause all / Resume all button.
  static const Key pauseAllKey = ValueKey('downloads.pauseAll');

  /// The key of the row of collection [kind]/[refId].
  static Key rowKey(CollectionKind kind, String refId) =>
      ValueKey('downloads.row.${kind.name}.$refId');

  /// The key of the overflow button of collection [kind]/[refId].
  static Key menuKey(CollectionKind kind, String refId) =>
      ValueKey('downloads.menu.${kind.name}.$refId');

  @override
  ConsumerState<DownloadsTab> createState() => _DownloadsTabState();
}

class _DownloadsTabState extends ConsumerState<DownloadsTab> {
  bool _inProgressOnly = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries =
        ref.watch(downloadCollectionEntriesProvider).value ??
        const <DownloadCollectionEntry>[];
    final totals = ref.watch(
      itemDownloadStatesProvider.select(
        (states) => DownloadTotals.of(
          states.value?.values ?? const <ItemDownloadState>[],
        ),
      ),
    );
    if (entries.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.download_for_offline_outlined,
          message: l10n.downloadsEmpty,
        ),
      );
    }
    final shown = [
      for (final entry in entries)
        if (!_inProgressOnly || entry.state.activeCount > 0) entry,
    ];
    final gutter = MediaQuery.sizeOf(context).width < 600
        ? Spacing.x16
        : Spacing.x24;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter, Spacing.x16, gutter, 0),
          sliver: SliverToBoxAdapter(
            child: _Header(
              totals: totals,
              inProgressOnly: _inProgressOnly,
              onInProgress: (value) => setState(() => _inProgressOnly = value),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: gutter - Spacing.x8,
            vertical: Spacing.x8,
          ),
          sliver: SliverList.builder(
            itemCount: shown.length,
            itemBuilder: (context, index) => DownloadCollectionRow(
              key: DownloadsTab.rowKey(shown[index].kind, shown[index].refId),
              entry: shown[index],
            ),
          ),
        ),
        if (shown.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.x24),
              child: Text(
                l10n.downloadsEmpty,
                textAlign: TextAlign.center,
                style: context.typography.body.copyWith(
                  color: context.colors.contentSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Header extends ConsumerWidget {
  const new({
    required this.totals,
    required this.inProgressOnly,
    required this.onInProgress,
  });

  final DownloadTotals totals;
  final bool inProgressOnly;
  final ValueChanged<bool> onInProgress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final typography = context.typography;
    final locale = Localizations.localeOf(context).toString();
    final resume =
        totals.activeCount > 0 && totals.pausedCount == totals.activeCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.downloadsSummary(
            totals.completedCount,
            formatBytes(totals.completedBytes, locale),
          ),
          style: typography.subtitle.copyWith(color: colors.content),
        ),
        if (totals.activeCount > 0)
          Text(
            l10n.downloadsInProgressCount(totals.activeCount),
            style: typography.body.copyWith(color: colors.contentSecondary),
          ),
        const SizedBox(height: Spacing.x12),
        Wrap(
          spacing: Spacing.x8,
          runSpacing: Spacing.x8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilterChip(
              key: DownloadsTab.inProgressKey,
              label: Text(l10n.downloadsFilterInProgress),
              selected: inProgressOnly,
              onSelected: onInProgress,
            ),
            if (totals.activeCount > 0)
              OutlinedButton.icon(
                key: DownloadsTab.pauseAllKey,
                icon: Icon(
                  resume ? Icons.play_arrow_rounded : Icons.pause_rounded,
                ),
                label: Text(
                  resume ? l10n.downloadsResumeAll : l10n.downloadsPauseAll,
                ),
                onPressed: () {
                  final controller = ref.read(downloadControllerProvider);
                  unawaited(
                    resume ? controller.resumeAll() : controller.pauseAll(),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}

/// One collection of the Downloads tab: artwork, title, kind and progress,
/// glyph, size, a progress bar while active, and an overflow menu.
class DownloadCollectionRow extends ConsumerWidget {
  /// Creates the row of [entry].
  const new({required this.entry, super.key});

  /// The collection.
  final DownloadCollectionEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final typography = context.typography;
    final state = entry.state;
    final locale = Localizations.localeOf(context).toString();
    final kindLabel = switch (entry.kind) {
      CollectionKind.album => l10n.downloadsKindAlbum,
      CollectionKind.playlist => l10n.downloadsKindPlaylist,
      CollectionKind.track => l10n.downloadsKindTrack,
    };
    final subtitle = switch (state.status) {
      _ when state.sourceGone => l10n.downloadsSourceGone,
      DownloadCollectionStatus.pendingNetwork =>
        l10n.downloadsWaitingForConnection,
      DownloadCollectionStatus.blocked => switch (state.blockedReason) {
        CollectionBlock.serverQuota => l10n.downloadServerQuotaTitle,
        _ => l10n.downloadUnavailableDisabled,
      },
      _ => l10n.downloadsItemsProgress(
        kindLabel,
        state.completedCount,
        state.itemCount - state.unavailableCount,
      ),
    };
    final active =
        state.status == DownloadCollectionStatus.ready && state.activeCount > 0;
    final total = state.totalBytes;
    final menu = _menu(context, ref, l10n);
    void openMenu(Offset? position) =>
        unawaited(showContextMenu(context, menu, position: position));
    return InkWell(
      borderRadius: BorderRadius.circular(Radii.small),
      onTap: () => _open(context, ref),
      onLongPress: () => openMenu(null),
      onSecondaryTapUp: (details) => openMenu(details.globalPosition),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.x8,
          vertical: Spacing.x8,
        ),
        child: Row(
          children: [
            _EntryArtwork(artworkRef: entry.artworkRef),
            const SizedBox(width: Spacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.title.isEmpty ? kindLabel : entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.body.copyWith(color: colors.content),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.bodySmall.copyWith(
                      color: colors.contentSecondary,
                    ),
                  ),
                  if (active) ...[
                    const SizedBox(height: Spacing.x4),
                    LinearProgressIndicator(
                      value: total > 0 ? state.receivedBytes / total : null,
                      color: colors.brand,
                      backgroundColor: colors.line,
                      minHeight: 2,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: Spacing.x8),
            DownloadGlyph(
              state: glyphOfCollection(state),
              onTap: state.failedCount > 0
                  ? () => unawaited(
                      ref
                          .read(downloadControllerProvider)
                          .retryCollection(entry.kind, entry.refId),
                    )
                  : null,
            ),
            const SizedBox(width: Spacing.x8),
            Text(
              formatBytes(total, locale),
              style: typography.caption.tabular.copyWith(
                color: colors.contentSecondary,
              ),
            ),
            Builder(
              builder: (context) => IconButton(
                key: DownloadsTab.menuKey(entry.kind, entry.refId),
                tooltip: l10n.menuMoreOptions,
                color: colors.contentSecondary,
                icon: const Icon(Icons.more_horiz_rounded),
                onPressed: () {
                  final box = context.findRenderObject()! as RenderBox;
                  openMenu(
                    box.localToGlobal(box.size.bottomCenter(Offset.zero)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<MenuEntry> _menu(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final state = entry.state;
    final controller = ref.read(downloadControllerProvider);
    return [
      if (state.failedCount > 0 ||
          state.status == DownloadCollectionStatus.blocked)
        MenuEntry(
          id: 'retry',
          label: l10n.menuRetryDownload,
          icon: Icons.refresh_rounded,
          onSelected: () =>
              unawaited(controller.retryCollection(entry.kind, entry.refId)),
        ),
      if (state.activeCount > state.pausedCount)
        MenuEntry(
          id: 'pause',
          label: l10n.downloadsPause,
          icon: Icons.pause_rounded,
          onSelected: () =>
              unawaited(controller.pauseCollection(entry.kind, entry.refId)),
        ),
      if (state.pausedCount > 0)
        MenuEntry(
          id: 'resume',
          label: l10n.downloadsResume,
          icon: Icons.play_arrow_rounded,
          onSelected: () =>
              unawaited(controller.resumeCollection(entry.kind, entry.refId)),
        ),
      if (entry.kind != CollectionKind.track)
        MenuEntry(
          id: 'checkForChanges',
          label: l10n.menuCheckForChanges,
          icon: Icons.sync_rounded,
          onSelected: () => unawaited(
            refreshDownloadedCollection(ref, entry.kind, entry.refId),
          ),
        ),
      MenuEntry(
        id: 'remove',
        label: l10n.menuRemoveDownload,
        icon: Icons.delete_outline_rounded,
        destructive: true,
        onSelected: () =>
            unawaited(confirmAndUnpin(context, ref, entry.kind, entry.refId)),
      ),
    ];
  }

  void _open(BuildContext context, WidgetRef ref) {
    final state = entry.state;
    if (state.status == DownloadCollectionStatus.blocked) {
      unawaited(
        showCollectionDownloadSheet(
          context,
          ref,
          entry.kind,
          entry.refId,
          state,
        ),
      );
      return;
    }
    switch (entry.kind) {
      case CollectionKind.album:
        DetailNavigation.openAlbum(context, entry.refId);
      case CollectionKind.playlist:
        DetailNavigation.openPlaylist(context, entry.refId);
      case CollectionKind.track:
        if (entry.albumId case final albumId?) {
          DetailNavigation.openAlbum(context, albumId);
        }
    }
  }
}

/// The cover of a row: the pinned file when there is one, so the tab
/// renders offline; otherwise the normal [Artwork].
class _EntryArtwork extends ConsumerWidget {
  const new({required this.artworkRef});

  final String? artworkRef;

  static const double _size = 56;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cover = artworkRef;
    final path = cover == null
        ? null
        : ref.watch(downloadArtworkFileProvider(cover)).value;
    final image = path == null ? null : artworkFileImage(path);
    if (image == null) return Artwork(ref: cover, size: _size);
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.small),
      child: Image(
        image: image,
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => Artwork(ref: cover, size: _size),
      ),
    );
  }
}
