// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The values the [DownloadController] takes and answers: snapshots,
/// collection and item states, events and upkeep results (doc 07).
library;

import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:soundspan/core/downloads/download_controller.dart'
    show DownloadController;
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_quota.dart';
import 'package:soundspan/core/downloads/download_state_machine.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/downloads/offline_models.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/shared/domain/track.dart';

/// The `device_settings` key of the download quality:
/// `serverDefault`, `original`, `high`, `medium` or `low` (doc 05).
const String downloadQualityKey = 'quality.download';

/// Why the server will not let this device download an item, as stored in
/// an `unavailable` item's `failureCode`, with the l10n id of the message
/// the UI shows for it (doc 07, Requesting a Download). No message names a
/// source.
enum DownloadUnavailableReason {
  /// "Downloads are turned off on this server".
  downloadsDisabled('SOURCE_DOWNLOADS_DISABLED', 'downloadUnavailableDisabled'),

  /// "No longer available".
  trackUnavailable('TRACK_UNAVAILABLE', 'downloadUnavailableGone'),

  /// "Not available for your account".
  sourceUnavailable('SOURCE_UNAVAILABLE', 'downloadUnavailableAccount');

  new(this.code, this.messageId);

  /// The server's `reason`, stored as the item's `failureCode`.
  final String code;

  /// The l10n id of the message the UI shows.
  final String messageId;

  /// The reason stored as [code], or null for a code this client does not
  /// know.
  static DownloadUnavailableReason? fromCode(String? code) {
    for (final reason in values) {
      if (reason.code == code) return reason;
    }
    return null;
  }
}

/// The `failureCode` of an item the server refused for a reason this
/// client does not know.
const String unknownUnavailableCode = 'UNKNOWN';

/// What the caller already shows of a collection it pins: the album or
/// playlist detail, or the single track. It is the source of each item's
/// metadata, because the server's answer carries none.
@immutable
final class CollectionSnapshot {
  /// Creates the snapshot.
  const new({
    required this.title,
    required this.tracks,
    this.subtitle,
    this.artworkRef,
  });

  /// The collection's title.
  final String title;

  /// The line under the title, such as the artist, if any.
  final String? subtitle;

  /// The value to pass to the cover-art endpoint, if any.
  final String? artworkRef;

  /// The tracks shown, in order.
  final List<Track> tracks;
}

/// A collection's download state for the UI, derived from its row and its
/// items.
@immutable
final class CollectionDownloadState {
  /// Creates the state.
  const new({
    required this.status,
    required this.itemCount,
    required this.completedCount,
    required this.unavailableCount,
    required this.receivedBytes,
    required this.totalBytes,
    this.activeCount = 0,
    this.failedCount = 0,
    this.pausedCount = 0,
    this.blockedReason,
    this.blockedDetail,
    this.quotaShortfall,
    this.sourceGone = false,
  });

  /// Where the collection is.
  final DownloadCollectionStatus status;

  /// Why it is blocked, when it is.
  final CollectionBlock? blockedReason;

  /// The number of items, unavailable ones included.
  final int itemCount;

  /// The number of `completed` items.
  final int completedCount;

  /// The number of `unavailable` items.
  final int unavailableCount;

  /// The number of items still to download: `queued`, `running`,
  /// `verifying`, `paused` or `missing`.
  final int activeCount;

  /// The number of `failedRetryable` or `failedPermanent` items.
  final int failedCount;

  /// The number of active items the user paused or holds.
  final int pausedCount;

  /// Bytes on disk: the size of completed items plus the bytes received of
  /// the others.
  final int receivedBytes;

  /// Bytes the collection takes when complete: the size of completed items
  /// plus the expected size of the others that can be downloaded; unknown
  /// sizes count as zero.
  final int totalBytes;

  /// The detail of a block, such as the three byte values of a server
  /// quota refusal (`limitBytes`, `usedBytes`, `estimatedBytes`).
  final Map<String, Object?>? blockedDetail;

  /// Set while some of its items wait for space, on the device limit or on
  /// the disk: what they need and what is free for them.
  final QuotaShortfall? quotaShortfall;

  /// Whether the album or playlist was deleted on the server: its files
  /// are kept and the UI says "No longer on the server" (doc 07, Keeping
  /// Collections Current).
  final bool sourceGone;

  @override
  bool operator ==(Object other) =>
      other is CollectionDownloadState &&
      other.quotaShortfall == quotaShortfall &&
      other.sourceGone == sourceGone &&
      other.status == status &&
      other.blockedReason == blockedReason &&
      other.itemCount == itemCount &&
      other.completedCount == completedCount &&
      other.unavailableCount == unavailableCount &&
      other.activeCount == activeCount &&
      other.failedCount == failedCount &&
      other.pausedCount == pausedCount &&
      other.receivedBytes == receivedBytes &&
      other.totalBytes == totalBytes &&
      _sameDetail(other.blockedDetail, blockedDetail);

  @override
  int get hashCode => Object.hash(
    status,
    blockedReason,
    itemCount,
    completedCount,
    unavailableCount,
    activeCount,
    failedCount,
    pausedCount,
    receivedBytes,
    totalBytes,
    quotaShortfall,
    sourceGone,
  );

  @override
  String toString() =>
      'CollectionDownloadState($status, block: $blockedReason, '
      '${sourceGone ? 'source gone, ' : ''}'
      '$completedCount/$itemCount, unavailable: $unavailableCount, '
      'active: $activeCount, failed: $failedCount, paused: $pausedCount, '
      '$receivedBytes/$totalBytes bytes, shortfall: $quotaShortfall)';

  static bool _sameDetail(Map<String, Object?>? a, Map<String, Object?>? b) {
    if (a == null || b == null) return a == b;
    return listEquals(a.keys.toList(), b.keys.toList()) &&
        a.keys.every((k) => a[k] == b[k]);
  }
}

/// One pinned collection as the Downloads tab lists it: what it is, what
/// the caller showed of it when pinning, and its download state.
@immutable
final class DownloadCollectionEntry {
  /// Creates the entry.
  const new({
    required this.kind,
    required this.refId,
    required this.title,
    required this.state,
    this.subtitle,
    this.artworkRef,
    this.albumId,
  });

  /// The collection's kind.
  final CollectionKind kind;

  /// The album or playlist id, or the playback id of a single track.
  final String refId;

  /// The title of the snapshot it was pinned with; empty when none was
  /// given.
  final String title;

  /// The line under the title, if any.
  final String? subtitle;

  /// The cover's artwork ref, if any.
  final String? artworkRef;

  /// The album of a single track, from its stored metadata, if known.
  final String? albumId;

  /// Its download state.
  final CollectionDownloadState state;

  @override
  bool operator ==(Object other) =>
      other is DownloadCollectionEntry &&
      other.kind == kind &&
      other.refId == refId &&
      other.title == title &&
      other.subtitle == subtitle &&
      other.artworkRef == artworkRef &&
      other.albumId == albumId &&
      other.state == state;

  @override
  int get hashCode =>
      Object.hash(kind, refId, title, subtitle, artworkRef, albumId, state);
}

/// An item of a collection the server will not let this device download:
/// its title from the stored metadata and the reason, null for a reason
/// this client does not know.
@immutable
final class UnavailableDownload {
  /// Creates the value.
  const new({required this.title, this.reason});

  /// The track's title; empty when unknown.
  final String title;

  /// Why it cannot be downloaded.
  final DownloadUnavailableReason? reason;
}

/// One item's download state for the UI.
@immutable
final class ItemDownloadState {
  /// Creates the state.
  const new({
    required this.status,
    required this.receivedBytes,
    this.expectedBytes,
    this.sizeBytes,
    this.failureCode,
    this.waitingFor,
  });

  /// Where the item is.
  final DownloadStatus status;

  /// Bytes received so far.
  final int receivedBytes;

  /// The size the server announced, if any.
  final int? expectedBytes;

  /// The size of the file on disk, once completed.
  final int? sizeBytes;

  /// Why it failed or is unavailable; for `unavailable` see
  /// [DownloadUnavailableReason.fromCode].
  final String? failureCode;

  /// Why a queued or paused item does not run.
  final DownloadWaitReason? waitingFor;

  @override
  bool operator ==(Object other) =>
      other is ItemDownloadState &&
      other.status == status &&
      other.receivedBytes == receivedBytes &&
      other.expectedBytes == expectedBytes &&
      other.sizeBytes == sizeBytes &&
      other.failureCode == failureCode &&
      other.waitingFor == waitingFor;

  @override
  int get hashCode => Object.hash(
    status,
    receivedBytes,
    expectedBytes,
    sizeBytes,
    failureCode,
    waitingFor,
  );

  @override
  String toString() =>
      'ItemDownloadState($status, $receivedBytes/$expectedBytes, '
      'failure: $failureCode, waiting: $waitingFor)';
}

/// Something the [DownloadController] did that others react to, such as
/// pinning artwork (doc 05, Image Cache).
sealed class DownloadControllerEvent {
  const new();
}

/// Item [key] reached `completed`: its file is verified and in place.
final class DownloadItemCompleted extends DownloadControllerEvent {
  /// Creates the event.
  const new(this.key);

  /// The item.
  final DownloadItemKey key;
}

/// Collection [kind]/[refId] resolved to `ready`.
final class DownloadCollectionReady extends DownloadControllerEvent {
  /// Creates the event.
  const new(this.kind, this.refId);

  /// The collection's kind.
  final DownloadCollectionKind kind;

  /// The collection's id.
  final String refId;
}

/// Collection [kind]/[refId] was removed with the items left in no
/// collection.
final class DownloadCollectionRemoved extends DownloadControllerEvent {
  /// Creates the event.
  const new(this.kind, this.refId);

  /// The collection's kind.
  final DownloadCollectionKind kind;

  /// The collection's id.
  final String refId;
}

/// What refreshing a pinned collection did (doc 07, Keeping Collections
/// Current).
enum UpkeepResult {
  /// The collection is not pinned; nothing was sent.
  notPinned,

  /// The server answered and the collection follows it now.
  refreshed,

  /// The server refused with its quota or its admin switch; the collection
  /// is `blocked` and its files are kept.
  blocked,

  /// The album or playlist is gone from the server; its files are kept.
  sourceGone,

  /// Offline or a retryable error: nothing changed.
  unchanged,
}

/// The `detailJson` key that marks a collection deleted on the server.
const String collectionSourceGoneKey = 'sourceGone';
