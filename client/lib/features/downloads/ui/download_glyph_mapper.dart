// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Maps item and collection download states to the [DownloadGlyphState]
/// the UI shows (doc 09, Components: `DownloadGlyph`).
library;

import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/shared/widgets/download_glyph.dart';

/// The glyph of one item: none when there is no item (or it is being
/// revoked), waiting while queued, paused or missing, running with the
/// fraction received (indeterminate when the size is unknown), and
/// completed, failed or unavailable as the item is.
DownloadGlyphState glyphOfItem(ItemDownloadState? item) {
  if (item == null) return DownloadGlyphState.none;
  return switch (item.status) {
    DownloadStatus.queued ||
    DownloadStatus.paused ||
    DownloadStatus.missing => DownloadGlyphState.queued,
    DownloadStatus.running => DownloadGlyphState.running(
      _fraction(item.receivedBytes, item.expectedBytes),
    ),
    DownloadStatus.verifying => const DownloadGlyphState.running(1),
    DownloadStatus.completed => DownloadGlyphState.completed,
    DownloadStatus.failedRetryable ||
    DownloadStatus.failedPermanent => DownloadGlyphState.failed,
    DownloadStatus.unavailable => DownloadGlyphState.unavailable,
    DownloadStatus.revoked => DownloadGlyphState.none,
  };
}

/// The glyph of a collection: none while it is not pinned; waiting while
/// it resolves or waits for the network; failed when the server blocked
/// it; running with the byte ratio while any item is active; failed when
/// nothing is active and an item failed; unavailable when no item can be
/// downloaded; completed when every available item is.
DownloadGlyphState glyphOfCollection(CollectionDownloadState? collection) {
  if (collection == null) return DownloadGlyphState.none;
  switch (collection.status) {
    case DownloadCollectionStatus.resolving ||
        DownloadCollectionStatus.pendingNetwork:
      return DownloadGlyphState.queued;
    case DownloadCollectionStatus.blocked:
      return DownloadGlyphState.failed;
    case DownloadCollectionStatus.ready:
      break;
  }
  if (collection.activeCount > 0) {
    return DownloadGlyphState.running(
      _fraction(collection.receivedBytes, collection.totalBytes),
    );
  }
  if (collection.failedCount > 0) return DownloadGlyphState.failed;
  if (collection.itemCount > 0 &&
      collection.unavailableCount == collection.itemCount) {
    return DownloadGlyphState.unavailable;
  }
  return DownloadGlyphState.completed;
}

/// [received] of [total] in whole percent steps, so a glyph changes at
/// most a hundred times; null when [total] is unknown.
double? _fraction(int received, int? total) {
  if (total == null || total <= 0) return null;
  return (received / total * 100).floor().clamp(0, 100) / 100;
}
