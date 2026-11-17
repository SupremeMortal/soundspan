// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Pins and unpins tracks, albums and playlists for offline use (doc 07,
/// Requesting a Download; Removing Downloads).
library;

import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show listEquals, visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_quota.dart';
import 'package:soundspan/core/downloads/download_scheduler.dart';
import 'package:soundspan/core/downloads/download_state_machine.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/downloads/download_values.dart';
import 'package:soundspan/core/downloads/offline_complete_queue.dart';
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
import 'package:soundspan/platform/disk_space/disk_space.dart';
import 'package:soundspan/platform/media_files/media_files.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/data/downloads/download_outbox.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan/shared/domain/track.dart';
import 'package:soundspan/shared/providers/cache.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

export 'package:soundspan/core/downloads/download_values.dart';

/// Looks up a track in the profile's `cache.db` by its playback id.
typedef CachedTrackLookup = Future<Track?> Function(PlaybackId playbackId);

/// Pins collections for offline use and removes them again (doc 07).
///
/// [pin] resolves a collection with the server, records the collection,
/// its items and their memberships, applies the device limit and hands
/// queued items to the [DownloadScheduler]; [unpin] removes the memberships
/// and, for every item left in no collection, its transfer, files and row,
/// and tells the server through the [OfflineDeleteQueue]. A finished
/// transfer is verified, renamed to its final file and reported to the
/// server, directly or through the [OfflineCompleteQueue]. Calls run one at
/// a time.
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
    required this._completeQueue,
    required this._diskSpace,
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
  final OfflineCompleteQueue _completeQueue;
  final DiskSpace _diskSpace;
  final CachedTrackLookup _cachedTrack;
  final MediaFiles _mediaFiles;
  final Clock _clock;
  final String _deviceId;
  final DownloadPaths? _paths;

  final List<StreamSubscription<Object?>> _subscriptions = [];
  final StreamController<DownloadControllerEvent> _events =
      StreamController<DownloadControllerEvent>.broadcast();
  Future<void> _tail = Future<void>.value();
  bool _started = false;
  bool _disposed = false;

  /// Retries `pendingNetwork` collections whenever reachability returns to
  /// `online`; runs the scheduler's controller effects (verifies finished
  /// transfers, confirms them with the server, deletes files and
  /// re-resolves the collections of an item the server refused); and
  /// applies the device limit now and whenever `downloads.quotaBytes`
  /// changes. Later calls do nothing.
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
      ..add(_scheduler.effects.listen(_onEffect))
      ..add(
        // The first value is the current one: the start-up pass, which also
        // clears the free-disk markers a previous run of the scheduler left.
        _settings
            .watch(downloadsQuotaKey)
            .distinct()
            .listen((_) => unawaited(_guard('recheck space', recheckSpace))),
      );
  }

  void _onEffect(DownloadItemEffect effect) {
    final key = effect.key;
    switch (effect.effect) {
      case ReResolveCollection():
        unawaited(_guard('re-resolve collections', () => _reResolve(key)));
      case VerifyFile(:final contentType):
        unawaited(
          _guard(
            'verify a download',
            () => _serial(() => _verify(key, contentType)),
          ),
        );
      case SendComplete():
        unawaited(
          _guard('confirm a download', () => _serial(() => _sendComplete(key))),
        );
      case DeleteFile():
        unawaited(
          _guard(
            'delete a download file',
            () => _serial(() async {
              await _deleteFiles(key, (await _store.item(key))?.relativePath);
            }),
          ),
        );
      // A revoked item's row goes after its files (DeleteFile comes
      // first), and its memberships with it.
      case DeleteRow():
        unawaited(
          _guard(
            'delete a download row',
            () => _serial(() => _store.deleteItem(key)),
          ),
        );
      // The file is renamed before VerificationPassed is delivered.
      case RenamePartToFinal() ||
          EnqueueTask() ||
          PauseOrCancelKeepingPart() ||
          ScheduleRetry() ||
          RefreshCredentials():
        break;
    }
  }

  /// What this controller did, as it happens: items that reached
  /// `completed`, collections that resolved to `ready` and collections
  /// removed. Closed by [dispose].
  Stream<DownloadControllerEvent> get events => _events.stream;

  void _emit(DownloadControllerEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  /// Completes when every call made so far, and every call those make in
  /// turn, has run.
  @visibleForTesting
  Future<void> settle() async {
    Future<void> tail;
    do {
      tail = _tail;
      await tail;
      await Future<void>.delayed(Duration.zero);
    } while (!identical(tail, _tail));
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
    await _events.close();
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

  /// Resolves the pinned collection [kind]/[refId] again and applies the
  /// difference (doc 07, Keeping Collections Current): new items are
  /// queued, items the server no longer lists leave the collection (and
  /// are removed when they belong to no other), refused items that are not
  /// on disk become `unavailable`, accepted `unavailable` items are queued,
  /// the membership order follows the server, and empty metadata is filled
  /// from [snapshot] or `cache.db`.
  ///
  /// Unlike [pin], a deleted album or playlist keeps its files and is
  /// marked [CollectionDownloadState.sourceGone], and an unreachable
  /// server changes nothing.
  Future<UpkeepResult> refreshCollection(
    CollectionKind kind,
    String refId, {
    CollectionSnapshot? snapshot,
  }) => _serial(() => _refresh(kind, refId, snapshot: snapshot));

  /// The playback ids of the pinned collection [kind]/[refId] in membership
  /// order, or null when it is not pinned.
  Future<List<PlaybackId>?> pinnedTrackIds(
    CollectionKind kind,
    String refId,
  ) async {
    final storeKind = _kindOf(kind);
    if (await _store.collection(storeKind, refId) == null) return null;
    return [
      for (final key in await _store.memberKeysOf(storeKind, refId))
        if (key case TrackItemKey(:final playbackId)) PlaybackId(playbackId),
    ];
  }

  /// The pinned albums and when each last resolved (null when never), in
  /// request order.
  Future<List<({String refId, DateTime? resolvedAt})>> pinnedAlbums() async => [
    for (final row in await _store.collections())
      if (row.kind == DownloadCollectionKind.album.name)
        (refId: row.refId, resolvedAt: row.resolvedAt),
  ];

  /// Removes the collection [kind]/[refId]; an unknown one is ignored.
  ///
  /// Every item left in no collection loses its transfer, its `.part` and
  /// final files and its row, and the server is told about removed tracks.
  /// Then the device limit is applied again, so items waiting for the
  /// space this freed can run.
  Future<void> unpin(CollectionKind kind, String refId) => _serial(() async {
    await _unpin(_kindOf(kind), refId);
    await _applyDeviceLimit();
  });

  /// Removes every collection, tracks and episodes alike, as [unpin] does
  /// for each, then applies the device limit again.
  Future<void> unpinAll() => _serial(() async {
    await _unpinAll();
    await _applyDeviceLimit();
  });

  /// Removes every download of the profile: every collection is unpinned
  /// as [unpinAll] does, then any item left in no collection is removed
  /// the same way. Removed tracks are reported to the server through the
  /// [OfflineDeleteQueue].
  Future<void> removeAll() => _serial(() async {
    await _unpinAll();
    await _removeItems([
      for (final row in await _store.allItems())
        DownloadItemKey.decode(row.itemKey),
    ]);
    await _applyDeviceLimit();
  });

  /// Sets the device limit to [bytes] and lets the items that now fit run,
  /// in schedule order.
  Future<void> raiseDeviceLimit(int bytes) => _serial(() async {
    await _settings.write(downloadsQuotaKey, bytes);
    await _applyDeviceLimit();
  });

  /// The device limit at which every queued item fits: what downloads
  /// hold or are about to hold, queued items included ("Raise limit").
  /// Null when free disk space, not the limit, is what stops them.
  Future<int?> deviceLimitToFitAll() => _serial(() async {
    final committed = await _store.committedBytes();
    final scheduled = await _store.queuedInScheduleOrder();
    if (scheduled.isEmpty) return committed;
    final decision = await _evaluateSpace(
      scheduled,
      persistDefault: false,
      deviceLimit: committed,
    );
    return decision.fitsAll ? committed : null;
  });

  /// Applies the device limit again: queued items that now fit lose their
  /// `waitingFor: space` marker, in schedule order, and the scheduler
  /// pumps. "Download what fits" needs no call: it is the state a pin
  /// leaves.
  Future<void> recheckSpace() => _serial(_applyDeviceLimit);

  /// The download state of collection [kind]/[refId], again on every
  /// change; null while it is not pinned.
  Stream<CollectionDownloadState?> watchCollection(
    CollectionKind kind,
    String refId,
  ) => _store
      .watchCollectionWithItems(_kindOf(kind), refId)
      .asyncMap(
        (row) async => row == null
            ? null
            : _collectionState(row, await _shortfallOf(row.items)),
      )
      .distinct();

  /// The download state of item [key], again on every change; null while
  /// there is no such item.
  Stream<ItemDownloadState?> watchItem(DownloadItemKey key) => _store
      .watchItem(key)
      .map((row) => row == null ? null : _itemState(row))
      .distinct();

  /// The download state of every item by its key, again on every change.
  Stream<Map<DownloadItemKey, ItemDownloadState>> watchItems() =>
      _store.watchItems().map(
        (rows) => {
          for (final row in rows)
            DownloadItemKey.decode(row.itemKey): _itemState(row),
        },
      );

  /// Every track, album and playlist collection in request order with its
  /// download state, again on every change.
  Stream<List<DownloadCollectionEntry>> watchCollectionEntries() => _store
      .watchCollectionsWithItems()
      .asyncMap((rows) async {
        final entries = <DownloadCollectionEntry>[];
        for (final row in rows) {
          final kind = _collectionKindOf(row.collection.kind);
          if (kind == null) continue;
          final meta = _decodeObject(row.collection.metaJson);
          final firstItem = row.items.isEmpty ? null : row.items.first;
          final albumId = kind == CollectionKind.track && firstItem != null
              ? _decodeObject(firstItem.metaJson)['albumId']
              : null;
          entries.add(
            DownloadCollectionEntry(
              kind: kind,
              refId: row.collection.refId,
              title: row.collection.title,
              subtitle: meta['subtitle'] as String?,
              artworkRef: meta['artworkRef'] as String?,
              albumId: albumId is String ? albumId : null,
              state: _collectionState(row, await _shortfallOf(row.items)),
            ),
          );
        }
        return entries;
      })
      .distinct(listEquals);

  /// The unavailable items of collection [kind]/[refId] in membership
  /// order, with their titles and reasons.
  Future<List<UnavailableDownload>> unavailableItems(
    CollectionKind kind,
    String refId,
  ) async {
    final row = await _store
        .watchCollectionWithItems(_kindOf(kind), refId)
        .first;
    return [
      for (final item in row?.items ?? const <DownloadItem>[])
        if (item.status == DownloadStatus.unavailable)
          UnavailableDownload(
            title: switch (_decodeObject(item.metaJson)['title']) {
              final String title => title,
              _ => '',
            },
            reason: DownloadUnavailableReason.fromCode(item.failureCode),
          ),
    ];
  }

  /// Queues the failed item [key] again with its attempts reset (the
  /// user's Retry).
  Future<void> retry(DownloadItemKey key) async {
    await _scheduler.deliver(key, const RetryPressed());
    _scheduler.pump();
  }

  /// Retries every failed item of collection [kind]/[refId]; a collection
  /// that is blocked or waiting for the network is resolved again.
  Future<void> retryCollection(CollectionKind kind, String refId) async {
    final storeKind = _kindOf(kind);
    final collection = await _store.collection(storeKind, refId);
    if (collection == null) return;
    final status = DownloadStore.statusOf(collection);
    if (status == DownloadCollectionStatus.blocked ||
        status == DownloadCollectionStatus.pendingNetwork) {
      await pin(kind, refId);
      return;
    }
    for (final item in await _itemsOf(storeKind, refId)) {
      if (item.status == DownloadStatus.failedRetryable ||
          item.status == DownloadStatus.failedPermanent) {
        await _scheduler.deliver(
          DownloadItemKey.decode(item.itemKey),
          const RetryPressed(),
        );
      }
    }
    _scheduler.pump();
  }

  /// Pauses every item of collection [kind]/[refId] for the user.
  Future<void> pauseCollection(CollectionKind kind, String refId) async {
    for (final item in await _itemsOf(_kindOf(kind), refId)) {
      await _scheduler.pauseItem(DownloadItemKey.decode(item.itemKey));
    }
  }

  /// Resumes every item of collection [kind]/[refId] the user paused.
  Future<void> resumeCollection(CollectionKind kind, String refId) async {
    for (final item in await _itemsOf(_kindOf(kind), refId)) {
      await _scheduler.resumeItem(DownloadItemKey.decode(item.itemKey));
    }
  }

  /// Pauses every transfer and holds every queued item, for the user.
  Future<void> pauseAll() => _scheduler.pauseAll();

  /// Resumes every item the user paused or held.
  Future<void> resumeAll() => _scheduler.resumeAll();

  Future<List<DownloadItem>> _itemsOf(
    DownloadCollectionKind kind,
    String refId,
  ) async =>
      (await _store.watchCollectionWithItems(kind, refId).first)?.items ??
      const [];

  static ItemDownloadState _itemState(DownloadItem row) => ItemDownloadState(
    status: row.status,
    receivedBytes: row.receivedBytes,
    expectedBytes: row.expectedBytes,
    sizeBytes: row.sizeBytes,
    failureCode: row.failureCode,
    waitingFor: DownloadStore.waitReasonOf(row),
  );

  static Map<String, Object?> _decodeObject(String json) {
    try {
      final decoded = jsonDecode(json);
      return decoded is Map<String, Object?> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }

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
      await _block(storeKind, refId, error);
      return;
    } on api.DownloadsDisabled catch (error) {
      await _block(storeKind, refId, error);
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
    _emit(DownloadCollectionReady(storeKind, refId));
    if (queued.isNotEmpty) await _applyDeviceLimit();
    _scheduler.pump();
  }

  /// Blocks collection [kind]/[refId] for the server's quota refusal or
  /// admin switch; its items and files stay.
  Future<void> _block(
    DownloadCollectionKind kind,
    String refId,
    api.ApiException error,
  ) => switch (error) {
    api.CacheLimitExceeded(
      :final limitBytes,
      :final usedBytes,
      :final estimatedBytes,
    ) =>
      _store.setCollectionStatus(
        kind,
        refId,
        DownloadCollectionStatus.blocked,
        block: CollectionBlock.serverQuota,
        detail: {
          'limitBytes': limitBytes,
          'usedBytes': usedBytes,
          'estimatedBytes': estimatedBytes,
        },
      ),
    _ => _store.setCollectionStatus(
      kind,
      refId,
      DownloadCollectionStatus.blocked,
      block: CollectionBlock.disabledByServer,
    ),
  };

  Future<UpkeepResult> _refresh(
    CollectionKind kind,
    String refId, {
    CollectionSnapshot? snapshot,
  }) async {
    final storeKind = _kindOf(kind);
    final existing = await _store.collection(storeKind, refId);
    if (existing == null) return UpkeepResult.notPinned;
    if (!_reachability.isOnline) return UpkeepResult.unchanged;
    final quality = await _downloadQuality();

    final OfflineResolution resolution;
    try {
      resolution = await _offline.resolve(
        kind,
        refId,
        deviceId: _deviceId,
        quality: quality,
      );
    } on api.CacheLimitExceeded catch (error) {
      await _block(storeKind, refId, error);
      return UpkeepResult.blocked;
    } on api.DownloadsDisabled catch (error) {
      await _block(storeKind, refId, error);
      return UpkeepResult.blocked;
    } on api.NotFound {
      // Nothing is deleted automatically: the files stay playable.
      await _store.setCollectionStatus(
        storeKind,
        refId,
        DownloadCollectionStatus.ready,
        detail: const {collectionSourceGoneKey: true},
      );
      return UpkeepResult.sourceGone;
    } on api.Offline catch (_) {
      return UpkeepResult.unchanged;
    } on api.ServerError catch (_) {
      return UpkeepResult.unchanged;
    } on api.Upstream catch (_) {
      return UpkeepResult.unchanged;
    } on api.RateLimited catch (_) {
      return UpkeepResult.unchanged;
    }

    final now = _clock.now();
    final byPlaybackId = {
      for (final track in snapshot?.tracks ?? const <Track>[])
        ?track.playbackId: track,
    };
    final (:queued, :orphaned) = await _store.transaction(() async {
      final queued = <DownloadItemKey>[];
      final returned = <DownloadItemKey>{};
      for (final (position, item) in resolution.items.indexed) {
        final key = TrackItemKey(item.playbackId.value);
        returned.add(key);
        if (await _recordItem(key, item, byPlaybackId, now, refresh: true)) {
          queued.add(key);
        }
        await _fillMeta(key, byPlaybackId);
        await _store.addMembership(storeKind, refId, key, position);
      }
      final orphaned = <DownloadItemKey>[];
      for (final key in await _store.memberKeysOf(storeKind, refId)) {
        if (returned.contains(key)) continue;
        if (await _store.removeMembership(storeKind, refId, key)) {
          orphaned.add(key);
        }
      }
      if (snapshot != null) {
        await _store.setCollectionMeta(
          storeKind,
          refId,
          title: snapshot.title,
          metaJson: jsonEncode({
            'subtitle': snapshot.subtitle,
            'artworkRef': snapshot.artworkRef,
          }),
        );
      }
      await _store.setCollectionStatus(
        storeKind,
        refId,
        DownloadCollectionStatus.ready,
        resolvedAt: now,
      );
      return (queued: queued, orphaned: orphaned);
    });
    await _removeItems(orphaned);
    _emit(DownloadCollectionReady(storeKind, refId));
    if (queued.isNotEmpty || orphaned.isNotEmpty) await _applyDeviceLimit();
    _scheduler.pump();
    return UpkeepResult.refreshed;
  }

  /// Fills the metadata of item [key] when its title is empty, from
  /// [snapshotTracks] or `cache.db`.
  Future<void> _fillMeta(
    DownloadItemKey key,
    Map<PlaybackId, Track> snapshotTracks,
  ) async {
    if (key is! TrackItemKey) return;
    final row = await _store.item(key);
    if (row == null) return;
    final title = _decodeObject(row.metaJson)['title'];
    if (title is String && title.isNotEmpty) return;
    final meta = await _metaJson(PlaybackId(key.playbackId), snapshotTracks);
    if ((_decodeObject(meta)['title'] as String?)?.isEmpty ?? true) return;
    await _store.setItemMeta(key, meta);
  }

  /// Records the item of [key] for [item] and answers whether it was
  /// queued for a transfer. On a [refresh] a refused item becomes
  /// `unavailable` only while nothing of it is on disk or in transfer.
  Future<bool> _recordItem(
    TrackItemKey key,
    OfflineItem item,
    Map<PlaybackId, Track> snapshotTracks,
    DateTime now, {
    bool refresh = false,
  }) async {
    final existing = await _store.item(key);
    if (!item.downloadable) {
      if (refresh &&
          existing != null &&
          !_refreshMarksUnavailable.contains(existing.status)) {
        return false;
      }
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

  /// The statuses a refresh turns `unavailable` when the server now
  /// refuses the item; a completed file is left to reconciliation.
  static const Set<DownloadStatus> _refreshMarksUnavailable = {
    DownloadStatus.queued,
    DownloadStatus.failedRetryable,
    DownloadStatus.failedPermanent,
    DownloadStatus.unavailable,
  };

  /// The statuses whose item a pin leaves as it is.
  static const Set<DownloadStatus> _keeps = {
    DownloadStatus.completed,
    DownloadStatus.queued,
    DownloadStatus.running,
    DownloadStatus.verifying,
    DownloadStatus.paused,
    DownloadStatus.failedRetryable,
  };

  // Device limit (doc 07, step 6; Storage Accounting and Quota).

  /// Holds the queued items beyond the device limit with `waitingFor:
  /// space` and releases the others, in schedule order.
  Future<void> _applyDeviceLimit() async {
    final scheduled = await _store.queuedInScheduleOrder();
    if (scheduled.isEmpty) return;
    final decision = await _evaluateSpace(scheduled, persistDefault: true);
    final keys = [
      for (final s in scheduled) DownloadItemKey.decode(s.item.itemKey),
    ];
    await _scheduler.applyDeviceLimit(
      fitting: keys.take(decision.fitCount),
      waiting: keys.skip(decision.fitCount),
    );
  }

  /// Evaluates the [scheduled] queued items against the device limit and
  /// the free disk space left once the transfers in flight finish.
  Future<QuotaDecision> _evaluateSpace(
    List<ScheduledDownload> scheduled, {
    required bool persistDefault,
    int? deviceLimit,
  }) async {
    final media = _paths?.profile.media;
    final free = media == null ? null : await _diskSpace.freeBytes(media);
    final limit =
        deviceLimit ?? await _deviceLimit(free, persist: persistDefault);
    final sizes = [for (final s in scheduled) s.item.expectedBytes];
    var queuedBytes = 0;
    for (final size in sizes) {
      queuedBytes += size ?? kUnknownItemBytes;
    }
    var inFlight = 0;
    for (final status in const [
      DownloadStatus.running,
      DownloadStatus.paused,
    ]) {
      for (final row in await _store.itemsByStatus(status)) {
        if (DownloadStore.waitReasonOf(row) == DownloadWaitReason.space) {
          continue;
        }
        inFlight += _remainingBytes(row);
      }
    }
    return evaluateQuota(
      committedBytes: await _store.committedBytes() - queuedBytes,
      newItemBytes: sizes,
      deviceLimitBytes: limit,
      freeDiskBytes: free == null ? null : free - inFlight,
    );
  }

  /// The `downloads.quotaBytes` setting; when unset, the default for
  /// [freeDiskBytes], written with [persist].
  Future<int> _deviceLimit(int? freeDiskBytes, {required bool persist}) async {
    final stored = await _settings.read(downloadsQuotaKey);
    if (stored is int && stored >= 0) return stored;
    final limit = defaultDeviceLimitBytes(freeDiskBytes);
    if (persist) await _settings.write(downloadsQuotaKey, limit);
    return limit;
  }

  /// What the items of a collection that wait for space need, and the
  /// room left for them after the queued items that fit; null when none
  /// waits.
  Future<QuotaShortfall?> _shortfallOf(List<DownloadItem> items) async {
    var needed = 0;
    var waiting = false;
    for (final item in items) {
      if ((item.status == DownloadStatus.queued ||
              item.status == DownloadStatus.paused) &&
          DownloadStore.waitReasonOf(item) == DownloadWaitReason.space) {
        waiting = true;
        needed += _remainingBytes(item);
      }
    }
    if (!waiting) return null;
    try {
      final scheduled = await _store.queuedInScheduleOrder();
      final decision = await _evaluateSpace(scheduled, persistDefault: false);
      var room = decision.availableBytes;
      for (final s in scheduled.take(decision.fitCount)) {
        room -= s.item.expectedBytes ?? kUnknownItemBytes;
      }
      return QuotaShortfall(
        neededBytes: needed,
        availableBytes: room < 0 ? 0 : room,
      );
    } on Object catch (error, stackTrace) {
      _log.warning('Could not measure free space', const {}, error, stackTrace);
      return QuotaShortfall(neededBytes: needed, availableBytes: 0);
    }
  }

  static int _remainingBytes(DownloadItem row) {
    final remaining =
        (row.expectedBytes ?? kUnknownItemBytes) - row.receivedBytes;
    return remaining < 0 ? 0 : remaining;
  }

  // Verification and confirmation (doc 07, Verification).

  /// Checks item [key]'s finished `.part` file and renames it to the final
  /// file named for [contentType]. A Content-Length the server sent where
  /// it announced no size is already the row's `expectedBytes`.
  Future<void> _verify(DownloadItemKey key, String? contentType) async {
    final paths = _paths;
    if (paths == null) return;
    final row = await _store.item(key);
    if (row == null || row.status != DownloadStatus.verifying) return;
    final hash = itemKeyHash(key);
    final part = paths.partFile(hash);
    final size = await _mediaFiles.length(part);
    final expected = row.expectedBytes;
    if (size == null) {
      // The app may have died between renaming the .part file and
      // recording the result: check the final file instead.
      final renamed = await _finalFileOf(paths, hash);
      if (renamed != null) {
        await _verifyRenamed(key, paths, hash, renamed, expected);
        return;
      }
    }
    if (size == null || size == 0 || (expected != null && size != expected)) {
      _log.info('A download failed verification', {
        'item': hash,
        'size': size,
        'expected': expected,
      });
      await _scheduler.deliver(key, const VerificationFailed());
      return;
    }
    final relative = paths.relativeFinalFile(hash, contentType);
    try {
      await _mediaFiles.replace(part, paths.resolve(relative));
    } on Object catch (error, stackTrace) {
      _log.warning(
        'Could not rename a verified download',
        {'item': hash},
        error,
        stackTrace,
      );
      await _scheduler.deliver(key, const VerificationFailed());
      return;
    }
    await _scheduler.deliver(key, VerificationPassed(size, relative));
    if ((await _store.item(key))?.status == DownloadStatus.completed) {
      _emit(DownloadItemCompleted(key));
    }
  }

  /// The absolute path of item [hash]'s final-named file in its fan-out
  /// directory, or null when there is none.
  Future<String?> _finalFileOf(DownloadPaths paths, String hash) async {
    final part = paths.partFile(hash);
    for (final file in await _mediaFiles.listFiles(p.dirname(part))) {
      final name = p.basename(file);
      if (name.startsWith('$hash.') && name != p.basename(part)) return file;
    }
    return null;
  }

  /// Verifies the final file at [path], renamed from item [key]'s `.part`
  /// file just before the app died, and completes the item with it; a
  /// file of the wrong size is deleted and the item fails verification.
  Future<void> _verifyRenamed(
    DownloadItemKey key,
    DownloadPaths paths,
    String hash,
    String path,
    int? expected,
  ) async {
    final size = await _mediaFiles.length(path);
    if (size == null || size == 0 || (expected != null && size != expected)) {
      _log.info('A renamed download failed verification', {
        'item': hash,
        'size': size,
        'expected': expected,
      });
      try {
        await _mediaFiles.delete(path);
      } on Object catch (error, stackTrace) {
        _log.warning(
          'Could not delete a renamed download',
          {'item': hash},
          error,
          stackTrace,
        );
      }
      await _scheduler.deliver(key, const VerificationFailed());
      return;
    }
    final relative = p.relative(path, from: paths.profile.supportRoot);
    await _scheduler.deliver(key, VerificationPassed(size, relative));
    _log.info('Adopted a renamed download', {'item': hash});
    if ((await _store.item(key))?.status == DownloadStatus.completed) {
      _emit(DownloadItemCompleted(key));
    }
  }

  /// Reports completed track [key] to the server again, even when it was
  /// confirmed before: reconciliation found the server does not know it
  /// (doc 07, Reconciliation, rule 3). Directly when online, else, or when
  /// the server cannot be reached, through the outbox.
  Future<void> resendComplete(DownloadItemKey key) =>
      _serial(() => _sendComplete(key, again: true));

  /// Reports completed track [key] to the server: directly when online,
  /// else, or when the server cannot be reached, through the outbox. A
  /// refusal (such as a track the server no longer knows) leaves it
  /// unconfirmed for reconciliation. Without [again] a confirmed item is
  /// not reported.
  Future<void> _sendComplete(DownloadItemKey key, {bool again = false}) async {
    if (key is! TrackItemKey) return;
    final row = await _store.item(key);
    final size = row?.sizeBytes;
    if (row == null ||
        row.status != DownloadStatus.completed ||
        (row.serverConfirmed && !again) ||
        size == null) {
      return;
    }
    final quality = row.quality ?? await _downloadQuality() ?? 'original';
    final playbackId = PlaybackId(key.playbackId);
    if (_reachability.isOnline) {
      try {
        await _offline.complete(
          deviceId: _deviceId,
          playbackId: playbackId,
          quality: quality,
          sizeBytes: size,
        );
        await _store.markServerConfirmed(key, _clock.now());
        return;
      } on api.Offline catch (_) {
        // Sent through the outbox below.
      } on api.ServerError catch (_) {
        // Sent through the outbox below.
      } on api.Upstream catch (_) {
        // Sent through the outbox below.
      } on api.RateLimited catch (_) {
        // Sent through the outbox below.
      } on api.ApiException catch (error) {
        _log.info('The server did not record a download', {
          'item': itemKeyHash(key),
          'error': '$error',
        });
        return;
      }
    }
    await _completeQueue.enqueue(
      deviceId: _deviceId,
      playbackId: playbackId,
      quality: quality,
      sizeBytes: size,
    );
  }

  Future<void> _waitForNetwork(DownloadCollectionKind kind, String refId) =>
      _store.setCollectionStatus(
        kind,
        refId,
        DownloadCollectionStatus.pendingNetwork,
      );

  Future<void> _unpinAll() async {
    final kinds = DownloadCollectionKind.values.asNameMap();
    for (final row in await _store.watchCollections().first) {
      final kind = kinds[row.kind];
      if (kind != null) await _unpin(kind, row.refId);
    }
  }

  Future<void> _unpin(DownloadCollectionKind kind, String refId) async {
    if (await _store.collection(kind, refId) == null) return;
    final orphaned = await _store.transaction(() async {
      final orphaned = await _store.removeMembershipsOf(kind, refId);
      await _store.deleteCollection(kind, refId);
      return orphaned;
    });
    await _removeItems(orphaned);
    _emit(DownloadCollectionRemoved(kind, refId));
  }

  /// Cancels the transfers of [keys], deletes their files and rows, and
  /// reports the removed tracks in batches.
  Future<void> _removeItems(List<DownloadItemKey> keys) async {
    final removedTracks = <PlaybackId>[];
    for (final key in keys) {
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
    QuotaShortfall? shortfall,
  ) {
    var completed = 0;
    var unavailable = 0;
    var active = 0;
    var failed = 0;
    var paused = 0;
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
          switch (item.status) {
            case DownloadStatus.failedRetryable ||
                DownloadStatus.failedPermanent:
              failed++;
            case DownloadStatus.revoked:
              break;
            case _:
              active++;
              if (DownloadStore.waitReasonOf(item) == DownloadWaitReason.user) {
                paused++;
              }
          }
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
      activeCount: active,
      failedCount: failed,
      pausedCount: paused,
      receivedBytes: received,
      totalBytes: total,
      blockedDetail: block == null
          ? null
          : DownloadStore.detailOf(row.collection),
      quotaShortfall: shortfall,
      sourceGone:
          block == null &&
          DownloadStore.detailOf(row.collection)[collectionSourceGoneKey] ==
              true,
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
          completeQueue: ref.watch(offlineCompleteQueueProvider),
          diskSpace: ref.watch(diskSpaceProvider),
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
        offlineCompleteQueueProvider,
        cacheStoreProvider,
        profileDisposerProvider,
      ],
    );
