// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_state_machine.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/core/storage/state/state_database.dart';

/// The size counted for an item whose size is not known yet: 8 MB.
const int kUnknownItemBytes = 8 * 1024 * 1024;

/// What a download collection is: the `kind` column of
/// `download_collections`.
enum DownloadCollectionKind {
  /// One track; its `refId` is the `playbackId`.
  track,

  /// An album.
  album,

  /// A playlist.
  playlist,

  /// A podcast episode; its `refId` is `<podcastId>:<episodeId>`.
  episode,
}

/// The `status` column of `download_collections`.
enum DownloadCollectionStatus {
  /// The server is resolving the collection's items.
  resolving,

  /// Resolution is waiting for the server to be reachable.
  pendingNetwork,

  /// The items are known.
  ready,

  /// The server refused the collection; see [CollectionBlock].
  blocked,
}

/// Why a collection is blocked: the `blockedReason` column.
enum CollectionBlock {
  /// The server's per-user limit is reached (409 `CACHE_LIMIT_EXCEEDED`).
  serverQuota,

  /// Downloads are turned off on the server (409
  /// `SOURCE_DOWNLOADS_DISABLED`).
  disabledByServer,
}

/// The one data access object over `download_collections`,
/// `download_items` and `download_membership` (doc 05, doc 07).
///
/// It persists what the state machine decides; it never runs effects.
class DownloadStore {
  /// Creates the store over [_db]. Without `paths` (web) there are no files
  /// and [completedFile] is always null.
  new(this._db, {this._paths});

  final StateDatabase _db;
  final DownloadPaths? _paths;

  /// Runs [body] in one transaction of the profile's `state.db`; store
  /// calls made inside it join the transaction.
  Future<T> transaction<T>(Future<T> Function() body) => _db.transaction(body);

  // Collections.

  /// Inserts or replaces the collection [kind]/[refId].
  ///
  /// Replacing keeps its memberships.
  Future<void> upsertCollection({
    required DownloadCollectionKind kind,
    required String refId,
    required String title,
    required String metaJson,
    required DownloadCollectionStatus status,
    required DateTime requestedAt,
    String? quality,
  }) => _db
      .into(_db.downloadCollections)
      .insertOnConflictUpdate(
        DownloadCollectionsCompanion.insert(
          kind: kind.name,
          refId: refId,
          title: title,
          metaJson: metaJson,
          status: status.name,
          quality: Value(quality),
          requestedAt: requestedAt,
        ),
      );

  /// Sets the collection's [status]. [block] and [detail] are stored as
  /// given, so a status without them clears both.
  Future<void> setCollectionStatus(
    DownloadCollectionKind kind,
    String refId,
    DownloadCollectionStatus status, {
    CollectionBlock? block,
    Map<String, Object?>? detail,
    DateTime? resolvedAt,
  }) =>
      (_db.update(
        _db.downloadCollections,
      )..where((c) => _collection(c, kind, refId))).write(
        DownloadCollectionsCompanion(
          status: Value(status.name),
          blockedReason: Value(block?.name),
          detailJson: Value(detail == null ? null : jsonEncode(detail)),
          resolvedAt: resolvedAt == null
              ? const Value.absent()
              : Value(resolvedAt),
        ),
      );

  /// Every collection, in request order, as it changes.
  Stream<List<DownloadCollection>> watchCollections() => (_db.select(
    _db.downloadCollections,
  )..orderBy([(c) => OrderingTerm.asc(c.requestedAt)])).watch();

  /// The collection [kind]/[refId], or null.
  Future<DownloadCollection?> collection(
    DownloadCollectionKind kind,
    String refId,
  ) => (_db.select(
    _db.downloadCollections,
  )..where((c) => _collection(c, kind, refId))).getSingleOrNull();

  /// The collections in [status], in request order.
  Future<List<DownloadCollection>> collectionsByStatus(
    DownloadCollectionStatus status,
  ) =>
      (_db.select(_db.downloadCollections)
            ..where((c) => c.status.equals(status.name))
            ..orderBy([(c) => OrderingTerm.asc(c.requestedAt)]))
          .get();

  /// The collections item [key] belongs to, in request order.
  Future<List<DownloadCollection>> collectionsOf(DownloadItemKey key) {
    final m = _db.downloadMembership;
    final c = _db.downloadCollections;
    final query =
        _db.select(c).join([
            innerJoin(m, m.kind.equalsExp(c.kind) & m.refId.equalsExp(c.refId)),
          ])
          ..where(m.itemKey.equals(key.encode()))
          ..orderBy([OrderingTerm.asc(c.requestedAt)]);
    return query.map((row) => row.readTable(c)).get();
  }

  /// The collection [kind]/[refId] with its items in membership order,
  /// again whenever either changes; null while there is no such
  /// collection.
  Stream<({DownloadCollection collection, List<DownloadItem> items})?>
  watchCollectionWithItems(DownloadCollectionKind kind, String refId) {
    final c = _db.downloadCollections;
    final m = _db.downloadMembership;
    final i = _db.downloadItems;
    final query =
        _db.select(c).join([
            leftOuterJoin(
              m,
              m.kind.equalsExp(c.kind) & m.refId.equalsExp(c.refId),
            ),
            leftOuterJoin(i, i.itemKey.equalsExp(m.itemKey)),
          ])
          ..where(_collection(c, kind, refId))
          ..orderBy([OrderingTerm.asc(m.position)]);
    return query.watch().map((rows) {
      if (rows.isEmpty) return null;
      return (
        collection: rows.first.readTable(c),
        items: [for (final row in rows) ?row.readTableOrNull(i)],
      );
    });
  }

  /// Deletes the collection and, by cascade, its memberships. Items are
  /// kept; use [removeMembershipsOf] first to learn which are orphaned.
  Future<void> deleteCollection(DownloadCollectionKind kind, String refId) =>
      (_db.delete(
        _db.downloadCollections,
      )..where((c) => _collection(c, kind, refId))).go();

  /// The status of [row].
  static DownloadCollectionStatus statusOf(DownloadCollection row) =>
      DownloadCollectionStatus.values.byName(row.status);

  /// Why [row] is blocked, or null.
  static CollectionBlock? blockOf(DownloadCollection row) {
    final reason = row.blockedReason;
    if (reason == null) return null;
    for (final block in CollectionBlock.values) {
      if (block.name == reason) return block;
    }
    return null;
  }

  /// The free-form state detail of [row]; empty when there is none or it
  /// does not decode to an object.
  static Map<String, Object?> detailOf(DownloadCollection row) {
    final json = row.detailJson;
    if (json == null) return const {};
    try {
      final decoded = jsonDecode(json);
      return decoded is Map<String, Object?> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }

  // Items.

  /// Inserts the item [key] with [fields], or updates the fields present in
  /// [fields]. The key and the media type come from [key].
  Future<void> upsertItem(DownloadItemKey key, DownloadItemsCompanion fields) {
    final row = fields.copyWith(
      itemKey: Value(key.encode()),
      mediaType: Value(switch (key) {
        TrackItemKey() => MediaType.track,
        EpisodeItemKey() => MediaType.episode,
      }),
    );
    return _db.into(_db.downloadItems).insertOnConflictUpdate(row);
  }

  /// Deletes the row of item [key] and, by cascade, its memberships.
  Future<void> deleteItem(DownloadItemKey key) => (_db.delete(
    _db.downloadItems,
  )..where((i) => i.itemKey.equals(key.encode()))).go();

  /// The item [key], or null.
  Future<DownloadItem?> item(DownloadItemKey key) =>
      _itemQuery(key).getSingleOrNull();

  /// The item [key] as it changes; null while there is no row.
  Stream<DownloadItem?> watchItem(DownloadItemKey key) =>
      _itemQuery(key).watchSingleOrNull();

  /// The items of collection [kind]/[refId] in membership order, as they
  /// change.
  Stream<List<DownloadItem>> watchItemsOf(
    DownloadCollectionKind kind,
    String refId,
  ) {
    final m = _db.downloadMembership;
    final query =
        _db.select(_db.downloadItems).join([
            innerJoin(m, m.itemKey.equalsExp(_db.downloadItems.itemKey)),
          ])
          ..where(m.kind.equals(kind.name) & m.refId.equals(refId))
          ..orderBy([OrderingTerm.asc(m.position)]);
    return query.watch().map(
      (rows) => [for (final r in rows) r.readTable(_db.downloadItems)],
    );
  }

  /// The items in [status].
  Future<List<DownloadItem>> itemsByStatus(DownloadStatus status) =>
      (_db.select(_db.downloadItems)
            ..where((i) => i.status.equalsValue(status))
            ..orderBy([(i) => OrderingTerm.asc(i.requestedAt)]))
          .get();

  /// The item whose transfer task is [taskId], or null.
  Future<DownloadItem?> itemByTaskId(String taskId) =>
      (_db.select(_db.downloadItems)
            ..where((i) => i.taskId.equals(taskId))
            ..limit(1))
          .getSingleOrNull();

  /// The `queued` items in the order the scheduler starts them (doc 07,
  /// Transfers): first items of a single-track or single-episode
  /// collection, oldest request first; then items of other collections by
  /// the collection's request time and, inside one, in membership order;
  /// then items with no membership. Ties keep the items' request order.
  Future<List<ScheduledDownload>> queuedInScheduleOrder() async {
    final items = await itemsByStatus(DownloadStatus.queued);
    if (items.isEmpty) return const [];
    final m = _db.downloadMembership;
    final c = _db.downloadCollections;
    final memberships = await _db.select(m).join([
      innerJoin(c, c.kind.equalsExp(m.kind) & c.refId.equalsExp(m.refId)),
    ]).get();
    final ranks = <String, _ScheduleRank>{};
    for (final row in memberships) {
      final membership = row.readTable(m);
      final collection = row.readTable(c);
      final single =
          collection.kind == DownloadCollectionKind.track.name ||
          collection.kind == DownloadCollectionKind.episode.name;
      final rank = _ScheduleRank(
        single ? 0 : 1,
        collection.requestedAt,
        single ? 0 : membership.position,
      );
      final best = ranks[membership.itemKey];
      if (best == null || rank.compareTo(best) < 0) {
        ranks[membership.itemKey] = rank;
      }
    }
    final ordered =
        [
          for (final (index, item) in items.indexed)
            (
              item: item,
              index: index,
              rank:
                  ranks[item.itemKey] ?? _ScheduleRank(2, item.requestedAt, 0),
            ),
        ]..sort((a, b) {
          final byRank = a.rank.compareTo(b.rank);
          return byRank != 0 ? byRank : a.index.compareTo(b.index);
        });
    return [
      for (final entry in ordered)
        ScheduledDownload(entry.item, userInitiated: entry.rank.group == 0),
    ];
  }

  /// The state-machine view of [row].
  static DownloadItemState stateOf(DownloadItem row) => DownloadItemState(
    status: row.status,
    attempts: row.attempts,
    taskId: row.taskId,
    serverConfirmed: row.serverConfirmed,
    failureCode: row.failureCode,
    nextAttemptAt: row.nextAttemptAt,
    waitingFor: _waitReason(row.waitingFor),
    sizeBytes: row.sizeBytes,
    relativePath: row.relativePath,
    completedAt: row.completedAt,
  );

  /// Persists [transition]'s next state for item [key] in one transaction
  /// and returns its effects for the caller to run.
  ///
  /// Throws a [StateError] when there is no such item.
  Future<List<DownloadEffect>> applyTransition(
    DownloadItemKey key,
    DownloadTransition transition,
  ) => _db.transaction(() async {
    final next = transition.next;
    final updated =
        await (_db.update(
          _db.downloadItems,
        )..where((i) => i.itemKey.equals(key.encode()))).write(
          DownloadItemsCompanion(
            status: Value(next.status),
            attempts: Value(next.attempts),
            taskId: Value(next.taskId),
            serverConfirmed: Value(next.serverConfirmed),
            failureCode: Value(next.failureCode),
            waitingFor: Value(next.waitingFor?.name),
            sizeBytes: Value(next.sizeBytes),
            relativePath: Value(next.relativePath),
            completedAt: Value(next.completedAt),
            nextAttemptAt: Value(next.nextAttemptAt),
          ),
        );
    if (updated == 0) throw StateError('no download item $key');
    return transition.effects;
  });

  /// Applies [ServerConfirmed] to item [key] at [now]: a `completed` item
  /// becomes `serverConfirmed`; any other item, or none, is left as it is.
  Future<void> markServerConfirmed(DownloadItemKey key, DateTime now) =>
      _db.transaction(() async {
        final row = await item(key);
        if (row == null) return;
        final state = stateOf(row);
        final transition = reduce(state, const ServerConfirmed(), now: now);
        if (transition.next == state) return;
        await applyTransition(key, transition);
      });

  /// Applies [FileMissing] to item [key] at [now]: a `completed` item
  /// whose file is gone is queued again; any other item, or none, is left
  /// as it is.
  Future<void> markFileMissing(DownloadItemKey key, DateTime now) =>
      _db.transaction(() async {
        final row = await item(key);
        if (row == null) return;
        final state = stateOf(row);
        final transition = reduce(state, const FileMissing(), now: now);
        if (transition.next == state) return;
        await applyTransition(key, transition);
      });

  /// Records [receivedBytes] of item [key]'s transfer.
  Future<void> updateProgress(DownloadItemKey key, int receivedBytes) =>
      _writeItem(
        key,
        DownloadItemsCompanion(receivedBytes: Value(receivedBytes)),
      );

  /// Records what the first response of item [key]'s transfer said: its
  /// [etag], and [contentLength] as the expected size when the server
  /// announced none, so verification can compare with it.
  Future<void> recordResponse(
    DownloadItemKey key, {
    String? etag,
    int? contentLength,
  }) => _db.transaction(() async {
    final row = await item(key);
    if (row == null) return;
    await _writeItem(
      key,
      DownloadItemsCompanion(
        etag: Value(etag),
        expectedBytes: row.expectedBytes == null && contentLength != null
            ? Value(contentLength)
            : const Value.absent(),
      ),
    );
  });

  /// Sets why item [key] waits, or clears it with null, without changing
  /// its status.
  Future<void> setWaitingFor(DownloadItemKey key, DownloadWaitReason? reason) =>
      _writeItem(key, DownloadItemsCompanion(waitingFor: Value(reason?.name)));

  /// Records that item [key] was played [at].
  Future<void> touchLastPlayed(DownloadItemKey key, DateTime at) =>
      _writeItem(key, DownloadItemsCompanion(lastPlayedAt: Value(at)));

  // Membership.

  /// Makes item [key] a member of collection [kind]/[refId] at [position].
  Future<void> addMembership(
    DownloadCollectionKind kind,
    String refId,
    DownloadItemKey key,
    int position,
  ) => _db
      .into(_db.downloadMembership)
      .insertOnConflictUpdate(
        DownloadMembershipCompanion.insert(
          kind: kind.name,
          refId: refId,
          itemKey: key.encode(),
          position: position,
        ),
      );

  /// Removes every membership of collection [kind]/[refId] and returns the
  /// keys of the items left with no membership.
  Future<List<DownloadItemKey>> removeMembershipsOf(
    DownloadCollectionKind kind,
    String refId,
  ) => _db.transaction(() async {
    final m = _db.downloadMembership;
    final members =
        await (_db.selectOnly(m)
              ..addColumns([m.itemKey])
              ..where(m.kind.equals(kind.name) & m.refId.equals(refId)))
            .map((r) => r.read(m.itemKey)!)
            .get();
    await (_db.delete(
      m,
    )..where((r) => r.kind.equals(kind.name) & r.refId.equals(refId))).go();
    final orphaned = <DownloadItemKey>[];
    for (final itemKey in members) {
      final key = DownloadItemKey.decode(itemKey);
      if (await membershipCount(key) == 0) orphaned.add(key);
    }
    return orphaned;
  });

  /// The number of collections item [key] belongs to.
  Future<int> membershipCount(DownloadItemKey key) {
    final m = _db.downloadMembership;
    final count = m.itemKey.count();
    return (_db.selectOnly(m)
          ..addColumns([count])
          ..where(m.itemKey.equals(key.encode())))
        .map((r) => r.read(count)!)
        .getSingle();
  }

  // Files and space.

  /// The absolute path of item [key]'s file when the item is `completed`,
  /// else null. Whether the file exists is the caller's check.
  Future<String?> completedFile(DownloadItemKey key) async {
    final paths = _paths;
    if (paths == null) return null;
    final row = await item(key);
    final relative = row?.relativePath;
    if (row?.status != DownloadStatus.completed || relative == null) {
      return null;
    }
    return paths.resolve(relative);
  }

  /// The bytes downloads hold or are about to hold: the size of completed
  /// items plus the expected size of queued, running, paused and verifying
  /// ones, counting an unknown size as [kUnknownItemBytes].
  Future<int> committedBytes() async {
    const pending = {
      DownloadStatus.queued,
      DownloadStatus.running,
      DownloadStatus.paused,
      DownloadStatus.verifying,
    };
    final rows =
        await (_db.select(_db.downloadItems)..where(
              (i) => i.status.isIn([
                for (final s in {DownloadStatus.completed, ...pending}) s.name,
              ]),
            ))
            .get();
    var total = 0;
    for (final row in rows) {
      final bytes = row.status == DownloadStatus.completed
          ? row.sizeBytes
          : row.expectedBytes;
      total += bytes ?? kUnknownItemBytes;
    }
    return total;
  }

  SimpleSelectStatement<$DownloadItemsTable, DownloadItem> _itemQuery(
    DownloadItemKey key,
  ) =>
      _db.select(_db.downloadItems)
        ..where((i) => i.itemKey.equals(key.encode()));

  Future<void> _writeItem(DownloadItemKey key, DownloadItemsCompanion fields) =>
      (_db.update(
        _db.downloadItems,
      )..where((i) => i.itemKey.equals(key.encode()))).write(fields);

  static Expression<bool> _collection(
    $DownloadCollectionsTable c,
    DownloadCollectionKind kind,
    String refId,
  ) => c.kind.equals(kind.name) & c.refId.equals(refId);

  /// Why [row] waits, read from its `waitingFor` column; null when it does
  /// not or the value is unknown.
  static DownloadWaitReason? waitReasonOf(DownloadItem row) =>
      _waitReason(row.waitingFor);

  static DownloadWaitReason? _waitReason(String? name) {
    for (final reason in DownloadWaitReason.values) {
      if (reason.name == name) return reason;
    }
    return null;
  }
}

/// A `queued` item in schedule order, as
/// [DownloadStore.queuedInScheduleOrder] returns it.
@immutable
final class ScheduledDownload {
  /// Creates the entry.
  const new(this.item, {required this.userInitiated});

  /// The item's row.
  final DownloadItem item;

  /// Whether a single-track or single-episode collection asked for it, so
  /// the platform runs it first where it can.
  final bool userInitiated;
}

/// Where an item falls in the schedule: its group, then the collection's
/// request time, then its position in the collection.
final class _ScheduleRank implements Comparable<_ScheduleRank> {
  const new(this.group, this.requestedAt, this.position);

  final int group;
  final DateTime requestedAt;
  final int position;

  @override
  int compareTo(_ScheduleRank other) {
    if (group != other.group) return group.compareTo(other.group);
    final byTime = requestedAt.compareTo(other.requestedAt);
    if (byTime != 0) return byTime;
    return position.compareTo(other.position);
  }
}

/// The [DownloadStore] of the profile's `state.db`, with the profile's
/// download paths on native targets.
final Provider<DownloadStore> downloadStoreProvider = Provider<DownloadStore>((
  ref,
) {
  final paths = ref.watch(profileContextProvider).paths;
  return DownloadStore(
    ref.watch(stateDatabaseProvider),
    paths: paths == null ? null : DownloadPaths(paths),
  );
}, dependencies: [stateDatabaseProvider, profileContextProvider]);
