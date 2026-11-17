// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/features/downloads/downloads.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';
import 'package:soundspan/shared/domain/podcast.dart';

/// A [DownloadController] whose states the test sets and whose calls it
/// records as strings, such as `pin album al-1` or `pauseAll`.
final class FakeDownloadController implements DownloadController {
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Every item's state; change it through [setItem].
  final Map<DownloadItemKey, ItemDownloadState> items = {};

  /// Each pinned collection's state; change it through [setCollection].
  final Map<(CollectionKind, String), CollectionDownloadState> collections = {};

  /// The Downloads tab's list; change it through [setEntries].
  List<DownloadCollectionEntry> entries = const [];

  /// The calls, in order.
  final List<String> calls = [];

  /// The snapshots passed to [pin], by `kind refId`.
  final Map<String, CollectionSnapshot?> snapshots = {};

  /// The state a pin leaves its collection in.
  CollectionDownloadState pinResult = const CollectionDownloadState(
    status: DownloadCollectionStatus.ready,
    itemCount: 1,
    completedCount: 0,
    unavailableCount: 0,
    receivedBytes: 0,
    totalBytes: 1000,
    activeCount: 1,
  );

  /// What [deviceLimitToFitAll] answers.
  int? limitToFitAll = 5000;

  /// What [unavailableItems] answers.
  List<UnavailableDownload> unavailable = const [];

  /// Sets the state of item [key], or removes it when null.
  void setItem(DownloadItemKey key, ItemDownloadState? state) {
    if (state == null) {
      items.remove(key);
    } else {
      items[key] = state;
    }
    _changes.add(null);
  }

  /// Sets the state of collection [kind]/[refId], or unpins it when null.
  void setCollection(
    CollectionKind kind,
    String refId,
    CollectionDownloadState? state,
  ) {
    if (state == null) {
      collections.remove((kind, refId));
    } else {
      collections[(kind, refId)] = state;
    }
    _changes.add(null);
  }

  /// The downloaded episodes; change them through
  /// [setDownloadedEpisodes].
  List<EpisodeDownloadMeta> downloadedEpisodes = const [];

  /// Sets the downloaded episodes.
  void setDownloadedEpisodes(List<EpisodeDownloadMeta> value) {
    downloadedEpisodes = value;
    _changes.add(null);
  }

  /// Sets the Downloads tab's list.
  void setEntries(List<DownloadCollectionEntry> value) {
    entries = value;
    _changes.add(null);
  }

  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    yield* _changes.stream.map((_) => read());
  }

  @override
  Stream<Map<DownloadItemKey, ItemDownloadState>> watchItems() =>
      _watch(() => Map.of(items));

  @override
  Stream<ItemDownloadState?> watchItem(DownloadItemKey key) =>
      _watch(() => items[key]).distinct();

  @override
  Stream<CollectionDownloadState?> watchCollection(
    CollectionKind kind,
    String refId,
  ) => _watch(() => collections[(kind, refId)]).distinct();

  @override
  Stream<List<DownloadCollectionEntry>> watchCollectionEntries() =>
      _watch(() => entries);

  @override
  Future<void> pin(
    CollectionKind kind,
    String refId, {
    CollectionSnapshot? snapshot,
  }) async {
    calls.add('pin ${kind.name} $refId');
    snapshots['${kind.name} $refId'] = snapshot;
    setCollection(kind, refId, pinResult);
  }

  @override
  Stream<List<EpisodeDownloadMeta>> watchDownloadedEpisodes() =>
      _watch(() => downloadedEpisodes);

  @override
  Future<void> pinEpisode(Podcast podcast, Episode episode) async =>
      calls.add('pinEpisode ${podcast.id} ${episode.id}');

  @override
  Future<void> unpin(CollectionKind kind, String refId) async {
    calls.add('unpin ${kind.name} $refId');
    setCollection(kind, refId, null);
  }

  @override
  Future<void> retry(DownloadItemKey key) async => calls.add('retry $key');

  @override
  Future<void> retryCollection(CollectionKind kind, String refId) async =>
      calls.add('retryCollection ${kind.name} $refId');

  @override
  Future<void> pauseCollection(CollectionKind kind, String refId) async =>
      calls.add('pauseCollection ${kind.name} $refId');

  @override
  Future<void> resumeCollection(CollectionKind kind, String refId) async =>
      calls.add('resumeCollection ${kind.name} $refId');

  @override
  Future<void> pauseAll() async => calls.add('pauseAll');

  @override
  Future<void> resumeAll() async => calls.add('resumeAll');

  @override
  Future<int?> deviceLimitToFitAll() async => limitToFitAll;

  @override
  Future<void> raiseDeviceLimit(int bytes) async =>
      calls.add('raiseDeviceLimit $bytes');

  @override
  Future<List<UnavailableDownload>> unavailableItems(
    CollectionKind kind,
    String refId,
  ) async => unavailable;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');

  /// The overrides that put this controller in a test's scope, on a
  /// platform that downloads unless [canDownload] is false.
  List<Override> overrides({bool canDownload = true}) => [
    platformCapabilitiesProvider.overrideWithValue(
      canDownload ? PlatformCapabilities.android : PlatformCapabilities.web,
    ),
    downloadControllerProvider.overrideWithValue(this),
    downloadArtworkFileProvider.overrideWith((ref, _) async => null),
  ];
}

/// An item state of [status], [received] of [expected] bytes.
ItemDownloadState itemState(
  DownloadStatus status, {
  int received = 0,
  int? expected = 1000,
  int? size,
}) => ItemDownloadState(
  status: status,
  receivedBytes: received,
  expectedBytes: expected,
  sizeBytes: size,
);
