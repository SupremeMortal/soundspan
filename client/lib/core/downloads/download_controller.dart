// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Pins and unpins tracks, albums and playlists for offline use (doc 07,
/// Requesting a Download; Removing Downloads).
library;

import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_scheduler.dart';
import 'package:soundspan/core/downloads/download_state_machine.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/downloads/offline_delete_queue.dart';
import 'package:soundspan/core/downloads/offline_models.dart';
import 'package:soundspan/core/downloads/offline_repository.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/core/profile/profile_disposer.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/storage/state/device_settings_dao.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/platform/media_files/media_files.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/data/downloads/download_outbox.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan/shared/domain/track.dart';
import 'package:soundspan/shared/providers/cache.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

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
    this.blockedReason,
    this.blockedDetail,
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

  @override
  bool operator ==(Object other) =>
      other is CollectionDownloadState &&
      other.status == status &&
      other.blockedReason == blockedReason &&
      other.itemCount == itemCount &&
      other.completedCount == completedCount &&
      other.unavailableCount == unavailableCount &&
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
    receivedBytes,
    totalBytes,
  );

  @override
  String toString() =>
      'CollectionDownloadState($status, block: $blockedReason, '
      '$completedCount/$itemCount, unavailable: $unavailableCount, '
      '$receivedBytes/$totalBytes bytes)';

  static bool _sameDetail(Map<String, Object?>? a, Map<String, Object?>? b) {
    if (a == null || b == null) return a == b;
    return listEquals(a.keys.toList(), b.keys.toList()) &&
        a.keys.every((k) => a[k] == b[k]);
  }
}

/// One item's download state for the UI.
@immutable
final class ItemDownloadState {
  /// Creates the state.
  const new({
    required this.status,
    required this.receivedBytes,
    this.expectedBytes,
    this.failureCode,
    this.waitingFor,
  });

  /// Where the item is.
  final DownloadStatus status;

  /// Bytes received so far.
  final int receivedBytes;

  /// The size the server announced, if any.
  final int? expectedBytes;

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
      other.failureCode == failureCode &&
      other.waitingFor == waitingFor;

  @override
  int get hashCode => Object.hash(
    status,
    receivedBytes,
    expectedBytes,
    failureCode,
    waitingFor,
  );

  @override
  String toString() =>
      'ItemDownloadState($status, $receivedBytes/$expectedBytes, '
      'failure: $failureCode, waiting: $waitingFor)';
}

/// Looks up a track in the profile's `cache.db` by its playback id.
typedef CachedTrackLookup = Future<Track?> Function(PlaybackId playbackId);

/// Pins collections for offline use and removes them again (doc 07).
///
/// [pin] resolves a collection with the server, records the collection,
/// its items and their memberships, and hands queued items to the
/// [DownloadScheduler]; [unpin] removes the memberships and, for every item
/// left in no collection, its transfer, files and row, and tells the
/// server through the [OfflineDeleteQueue]. Calls run one at a time.
class DownloadController {
  /// Creates the controller of the profile whose device id is
  /// `deviceId`. Without `paths` (web) there are no files to delete.
  new({
    required this._store,
    required this._offline,
    required this._scheduler,
    required this._reachability,
    required this._settings,
    required this._deleteQueue,
    required this._cachedTrack,
    required this._mediaFiles,
    required this._clock,
    required this._deviceId,
    this._paths,
  });

  static final AppLogger _log = AppLogger.scope('Downloads');

  final DownloadStore _store;
  final OfflineRepository _offline;
  final DownloadScheduler _scheduler;
  final ReachabilityController _reachability;
  final DeviceSettingsDao _settings;
  final OfflineDeleteQueue _deleteQueue;
  final CachedTrackLookup _cachedTrack;
  final MediaFiles _mediaFiles;
  final Clock _clock;
  final String _deviceId;
  final DownloadPaths? _paths;

  final List<StreamSubscription<Object?>> _subscriptions = [];
  Future<void> _tail = Future<void>.value();
  bool _started = false;
  bool _disposed = false;

  /// Retries `pendingNetwork` collections whenever reachability returns to
  /// `online`, and re-resolves the collections of an item whose transfer
  /// the server refused (the scheduler's `ReResolveCollection` effect).
  /// Later calls do nothing.
  void start() {
    if (_started || _disposed) return;
    _started = true;
    _subscriptions
      ..add(
        _reachability.changes.listen((state) {
          if (state == Reachability.online) {
            unawaited(
              _guard('retry pending collections', retryPendingCollections),
            );
          }
        }),
      )
      ..add(
        _scheduler.effects.listen((effect) {
          if (effect.effect is ReResolveCollection) {
            unawaited(
              _guard('re-resolve collections', () => _reResolve(effect.key)),
            );
          }
        }),
      );
  }

  /// Stops listening. Calls already made still finish.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    await _tail;
  }

  /// Pins the track, album or playlist [refId] of [kind]; pinning a pinned
  /// collection again refreshes it and never duplicates rows. [snapshot]
  /// is what the caller shows of it.
  ///
  /// When the server is unreachable the collection waits as
  /// `pendingNetwork` for [retryPendingCollections]. Throws the server's
  /// `NotFound` after removing the collection.
  Future<void> pin(
    CollectionKind kind,
    String refId, {
    CollectionSnapshot? snapshot,
  }) => _serial(() => _pin(kind, refId, snapshot: snapshot));

  /// Removes the collection [kind]/[refId]; an unknown one is ignored.
  ///
  /// Every item left in no collection loses its transfer, its `.part` and
  /// final files and its row, and the server is told about removed tracks.
  Future<void> unpin(CollectionKind kind, String refId) =>
      _serial(() => _unpin(_kindOf(kind), refId));

  /// The download state of collection [kind]/[refId], again on every
  /// change; null while it is not pinned.
  Stream<CollectionDownloadState?> watchCollection(
    CollectionKind kind,
    String refId,
  ) => _store
      .watchCollectionWithItems(_kindOf(kind), refId)
      .map((row) => row == null ? null : _collectionState(row))
      .distinct();

  /// The download state of item [key], again on every change; null while
  /// there is no such item.
  Stream<ItemDownloadState?> watchItem(DownloadItemKey key) => _store
      .watchItem(key)
      .map(
        (row) => row == null
            ? null
            : ItemDownloadState(
                status: row.status,
                receivedBytes: row.receivedBytes,
                expectedBytes: row.expectedBytes,
                failureCode: row.failureCode,
                waitingFor: DownloadStore.waitReasonOf(row),
              ),
      )
      .distinct();

  /// Resolves every `pendingNetwork` collection again, with its metadata
  /// from `cache.db`.
  Future<void> retryPendingCollections() => _serial(() async {
    final pending = await _store.collectionsByStatus(
      DownloadCollectionStatus.pendingNetwork,
    );
    for (final row in pending) {
      final kind = _collectionKindOf(row.kind);
      if (kind == null) continue;
      await _guard('retry ${row.kind}', () => _pin(kind, row.refId));
    }
  });

  Future<void> _reResolve(DownloadItemKey key) => _serial(() async {
    for (final row in await _store.collectionsOf(key)) {
      final kind = _collectionKindOf(row.kind);
      if (kind == null) continue;
      await _guard('re-resolve ${row.kind}', () => _pin(kind, row.refId));
    }
  });

  Future<void> _pin(
    CollectionKind kind,
    String refId, {
    CollectionSnapshot? snapshot,
  }) async {
    final storeKind = _kindOf(kind);
    final quality = await _downloadQuality();
    final existing = await _store.collection(storeKind, refId);
    final now = _clock.now();
    await _store.upsertCollection(
      kind: storeKind,
      refId: refId,
      title: snapshot?.title ?? existing?.title ?? '',
      metaJson: snapshot == null
          ? existing?.metaJson ?? '{}'
          : jsonEncode({
              'subtitle': snapshot.subtitle,
              'artworkRef': snapshot.artworkRef,
            }),
      status: DownloadCollectionStatus.resolving,
      requestedAt: existing?.requestedAt ?? now,
      quality: quality,
    );
    if (!_reachability.isOnline) {
      await _store.setCollectionStatus(
        storeKind,
        refId,
        DownloadCollectionStatus.pendingNetwork,
      );
      return;
    }

    final OfflineResolution resolution;
    try {
      resolution = await _offline.resolve(
        kind,
        refId,
        deviceId: _deviceId,
        quality: quality,
      );
    } on api.CacheLimitExceeded catch (error) {
      await _store.setCollectionStatus(
        storeKind,
        refId,
        DownloadCollectionStatus.blocked,
        block: CollectionBlock.serverQuota,
        detail: {
          'limitBytes': error.limitBytes,
          'usedBytes': error.usedBytes,
          'estimatedBytes': error.estimatedBytes,
        },
      );
      return;
    } on api.DownloadsDisabled {
      await _store.setCollectionStatus(
        storeKind,
        refId,
        DownloadCollectionStatus.blocked,
        block: CollectionBlock.disabledByServer,
      );
      return;
    } on api.NotFound {
      await _unpin(storeKind, refId);
      rethrow;
    } on api.Offline catch (_) {
      await _waitForNetwork(storeKind, refId);
      return;
    } on api.ServerError catch (_) {
      await _waitForNetwork(storeKind, refId);
      return;
    } on api.Upstream catch (_) {
      await _waitForNetwork(storeKind, refId);
      return;
    } on api.RateLimited catch (_) {
      await _waitForNetwork(storeKind, refId);
      return;
    } on Object {
      // Anything else is not a network condition; the collection still
      // waits rather than stay `resolving`, and the caller learns why.
      await _waitForNetwork(storeKind, refId);
      rethrow;
    }

    final byPlaybackId = {
      for (final track in snapshot?.tracks ?? const <Track>[])
        ?track.playbackId: track,
    };
    final queued = await _store.transaction(() async {
      final queued = <DownloadItemKey>[];
      for (final (position, item) in resolution.items.indexed) {
        final key = TrackItemKey(item.playbackId.value);
        if (await _recordItem(key, item, byPlaybackId, now)) queued.add(key);
        await _store.addMembership(storeKind, refId, key, position);
      }
      await _store.setCollectionStatus(
        storeKind,
        refId,
        DownloadCollectionStatus.ready,
        resolvedAt: now,
      );
      return queued;
    });
    await _applyDeviceLimit(queued);
    _scheduler.pump();
  }

  /// Records the item of [key] for [item] and answers whether it was
  /// queued for a transfer.
  Future<bool> _recordItem(
    TrackItemKey key,
    OfflineItem item,
    Map<PlaybackId, Track> snapshotTracks,
    DateTime now,
  ) async {
    final existing = await _store.item(key);
    if (!item.downloadable) {
      await _store.upsertItem(
        key,
        DownloadItemsCompanion(
          metaJson: Value(
            existing?.metaJson ??
                await _metaJson(item.playbackId, snapshotTracks),
          ),
          status: const Value(DownloadStatus.unavailable),
          failureCode: Value(_unavailableCode(item.reason)),
          waitingFor: const Value(null),
          requestedAt: Value(existing?.requestedAt ?? now),
        ),
      );
      return false;
    }
    // A completed file is kept whatever its quality (no re-download in v1),
    // and an item already on its way keeps its transfer.
    if (existing != null && _keeps.contains(existing.status)) return false;
    await _store.upsertItem(
      key,
      DownloadItemsCompanion(
        metaJson: Value(await _metaJson(item.playbackId, snapshotTracks)),
        status: const Value(DownloadStatus.queued),
        downloadUrl: Value(item.downloadUrl),
        expectedBytes: Value(item.expectedBytes),
        quality: Value(item.quality),
        requestedAt: Value(now),
        receivedBytes: const Value(0),
        attempts: const Value(0),
        failureCode: const Value(null),
        waitingFor: const Value(null),
        taskId: const Value(null),
        nextAttemptAt: const Value(null),
      ),
    );
    return true;
  }

  /// The statuses whose item a pin leaves as it is.
  static const Set<DownloadStatus> _keeps = {
    DownloadStatus.completed,
    DownloadStatus.queued,
    DownloadStatus.running,
    DownloadStatus.verifying,
    DownloadStatus.paused,
    DownloadStatus.failedRetryable,
  };

  /// Step 6 of doc 07 (the device limit), filled in with quota handling.
  Future<void> _applyDeviceLimit(List<DownloadItemKey> queued) async {}

  Future<void> _waitForNetwork(DownloadCollectionKind kind, String refId) =>
      _store.setCollectionStatus(
        kind,
        refId,
        DownloadCollectionStatus.pendingNetwork,
      );

  Future<void> _unpin(DownloadCollectionKind kind, String refId) async {
    if (await _store.collection(kind, refId) == null) return;
    final orphaned = await _store.transaction(() async {
      final orphaned = await _store.removeMembershipsOf(kind, refId);
      await _store.deleteCollection(kind, refId);
      return orphaned;
    });
    final removedTracks = <PlaybackId>[];
    for (final key in orphaned) {
      final row = await _store.item(key);
      if (row == null) continue;
      if (row.status != DownloadStatus.unavailable) {
        await _scheduler.cancelItem(key);
        await _deleteFiles(key, row.relativePath);
        if (key case TrackItemKey(:final playbackId)) {
          removedTracks.add(PlaybackId(playbackId));
        }
      }
      await _store.deleteItem(key);
    }
    for (var start = 0; start < removedTracks.length;) {
      final end = start + maxOfflineDeleteBatch < removedTracks.length
          ? start + maxOfflineDeleteBatch
          : removedTracks.length;
      await _deleteQueue.enqueue(
        deviceId: _deviceId,
        playbackIds: removedTracks.sublist(start, end),
      );
      start = end;
    }
  }

  Future<void> _deleteFiles(DownloadItemKey key, String? relativePath) async {
    final paths = _paths;
    if (paths == null) return;
    final files = [
      paths.partFile(itemKeyHash(key)),
      if (relativePath != null) paths.resolve(relativePath),
    ];
    for (final file in files) {
      try {
        await _mediaFiles.delete(file);
      } on Object catch (error, stackTrace) {
        // Windows refuses while the file plays; the start-up scan removes
        // the orphan.
        _log.warning(
          'Could not delete a downloaded file',
          {'item': itemKeyHash(key)},
          error,
          stackTrace,
        );
      }
    }
  }

  Future<String> _metaJson(
    PlaybackId playbackId,
    Map<PlaybackId, Track> snapshotTracks,
  ) async {
    var track = snapshotTracks[playbackId];
    if (track == null) {
      try {
        track = await _cachedTrack(playbackId);
      } on Object catch (error, stackTrace) {
        _log.warning(
          'Could not read a cached track',
          const {},
          error,
          stackTrace,
        );
      }
    }
    return jsonEncode(downloadMetaOf(track));
  }

  Future<String?> _downloadQuality() async {
    final value = await _settings.read(downloadQualityKey);
    return switch (value) {
      final String quality
          when const {'original', 'high', 'medium', 'low'}.contains(quality) =>
        quality,
      _ => null,
    };
  }

  CollectionDownloadState _collectionState(
    ({DownloadCollection collection, List<DownloadItem> items}) row,
  ) {
    var completed = 0;
    var unavailable = 0;
    var received = 0;
    var total = 0;
    for (final item in row.items) {
      switch (item.status) {
        case DownloadStatus.completed:
          completed++;
          final size = item.sizeBytes ?? item.expectedBytes ?? 0;
          received += size;
          total += size;
        case DownloadStatus.unavailable:
          unavailable++;
        case DownloadStatus.queued ||
            DownloadStatus.running ||
            DownloadStatus.verifying ||
            DownloadStatus.paused ||
            DownloadStatus.failedRetryable ||
            DownloadStatus.failedPermanent ||
            DownloadStatus.missing ||
            DownloadStatus.revoked:
          received += item.receivedBytes;
          total += item.expectedBytes ?? 0;
      }
    }
    final block = DownloadStore.blockOf(row.collection);
    return CollectionDownloadState(
      status: DownloadStore.statusOf(row.collection),
      blockedReason: block,
      itemCount: row.items.length,
      completedCount: completed,
      unavailableCount: unavailable,
      receivedBytes: received,
      totalBytes: total,
      blockedDetail: block == null
          ? null
          : DownloadStore.detailOf(row.collection),
    );
  }

  /// Runs [body] after every call made before it. Its error reaches the
  /// caller and does not stop the calls after it.
  Future<T> _serial<T>(Future<T> Function() body) {
    final result = _tail.then((_) => body());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<void> _guard(String what, Future<void> Function() body) async {
    try {
      await body();
    } on Object catch (error, stackTrace) {
      _log.warning('Could not $what', const {}, error, stackTrace);
    }
  }

  static String _unavailableCode(OfflineUnavailableReason? reason) =>
      switch (reason) {
        OfflineUnavailableReason.downloadsDisabled =>
          DownloadUnavailableReason.downloadsDisabled.code,
        OfflineUnavailableReason.trackUnavailable =>
          DownloadUnavailableReason.trackUnavailable.code,
        OfflineUnavailableReason.sourceUnavailable =>
          DownloadUnavailableReason.sourceUnavailable.code,
        OfflineUnavailableReason.unknown || null => unknownUnavailableCode,
      };

  static DownloadCollectionKind _kindOf(CollectionKind kind) => switch (kind) {
    CollectionKind.track => DownloadCollectionKind.track,
    CollectionKind.album => DownloadCollectionKind.album,
    CollectionKind.playlist => DownloadCollectionKind.playlist,
  };

  static CollectionKind? _collectionKindOf(String kind) {
    for (final value in CollectionKind.values) {
      if (value.name == kind) return value;
    }
    return null;
  }
}

/// The metadata stored with a downloaded track (`download_items.metaJson`):
/// the `TrackMeta` of [track] plus its album and artist ids, loudness, disc
/// and track number. Without a track every text is empty, for the upkeep
/// pass to fill in.
Map<String, Object?> downloadMetaOf(Track? track) {
  if (track == null) {
    return const TrackMeta(
      title: '',
      artist: '',
      album: '',
      durationSec: 0,
    ).toJson();
  }
  return {
    ...track.meta.toJson(),
    'albumId': track.albumId,
    'artistId': track.artistId,
    'loudness': track.loudness?.toJson(),
    'discNumber': track.discNumber,
    'trackNumber': track.trackNumber,
  };
}

/// The [DownloadController] of the profile scope, started when created and
/// disposed when the scope ends. Native targets only, like the
/// [DownloadScheduler] it drives.
final Provider<DownloadController> downloadControllerProvider =
    Provider<DownloadController>(
      (ref) {
        final context = ref.watch(profileContextProvider);
        final paths = context.paths;
        final controller = DownloadController(
          store: ref.watch(downloadStoreProvider),
          offline: ref.watch(offlineRepositoryProvider),
          scheduler: ref.watch(downloadSchedulerProvider),
          reachability: ref.watch(reachabilityProvider),
          settings: ref.watch(deviceSettingsDaoProvider),
          deleteQueue: ref.watch(offlineDeleteQueueProvider),
          cachedTrack: (playbackId) async {
            final store = await ref.read(cacheStoreProvider.future);
            return (await store.watchTrack(playbackId.value).first)?.value;
          },
          mediaFiles: ref.watch(mediaFilesProvider),
          clock: ref.watch(clockProvider),
          deviceId: context.profile.deviceId,
          paths: paths == null ? null : DownloadPaths(paths),
        )..start();
        ref.watch(profileDisposerProvider).register(controller.dispose);
        return controller;
      },
      dependencies: [
        profileContextProvider,
        downloadStoreProvider,
        offlineRepositoryProvider,
        downloadSchedulerProvider,
        deviceSettingsDaoProvider,
        offlineDeleteQueueProvider,
        cacheStoreProvider,
        profileDisposerProvider,
      ],
    );
