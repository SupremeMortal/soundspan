// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Artwork of downloaded items and their collections, kept in the
/// profile's `art/` directory, which the OS never purges (doc 05, Files on
/// Disk and Image Cache; doc 07, Android Auto and Offline).
library;

import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/core/profile/profile_disposer.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/storage/artwork_fetcher.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/platform/artwork_store/artwork_store.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/providers/images.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// The file name of the pinned cover [ref]: the lower-case hex SHA-1 of the
/// ref string with the extension `.img`. The ref is hashed, never parsed.
String downloadArtworkFileName(String ref) =>
    '${sha1.convert(utf8.encode(ref))}.img';

final RegExp _pinnedName = RegExp(r'^[0-9a-f]{40}\.img$');

/// The `artworkRef` of a `metaJson` value, or null when it has none, it is
/// empty, or the value does not decode.
String? artworkRefOf(String metaJson) {
  try {
    final decoded = jsonDecode(metaJson);
    if (decoded case {'artworkRef': final String ref} when ref.isNotEmpty) {
      return ref;
    }
  } on FormatException {
    // Not JSON: no ref.
  }
  return null;
}

/// The covers of downloaded items and their collections, as local files.
abstract interface class DownloadArtwork {
  /// Starts pinning on the controller's events and runs the start-up
  /// repair once reachability is `online`. Later calls do nothing.
  void start();

  /// Copies the cover [ref] to `art/<sha1(ref)>.img` and answers the file's
  /// absolute path, or null when it could not be fetched.
  Future<String?> pin(String ref);

  /// The absolute path of the pinned file of [ref] when it exists; no
  /// network.
  Future<String?> fileFor(String ref);

  /// Deletes pinned files that no download item or collection references
  /// and answers how many. Never touches `now-playing.img`.
  Future<int> removeUnreferenced();
}

/// The [DownloadArtwork] of targets that cannot download: nothing is
/// pinned or found.
final class NoDownloadArtwork implements DownloadArtwork {
  /// Creates it.
  const new();

  @override
  void start() {}

  @override
  Future<String?> pin(String ref) async => null;

  @override
  Future<String?> fileFor(String ref) async => null;

  @override
  Future<int> removeUnreferenced() async => 0;
}

/// Pins covers of one profile's downloads under its art directory.
///
/// An item that reaches `completed` gets its cover and those of its
/// collections pinned; a collection that resolves to `ready` gets its
/// cover pinned at once; a removed collection leads to
/// [removeUnreferenced]. The first time reachability is `online` after
/// [start], covers of completed items and ready collections that have no
/// file are pinned one after another, at most [repairRate] a second. A
/// failed fetch is logged and left for that repair; it never fails an
/// item. Offline, nothing is fetched.
final class ProfileDownloadArtwork implements DownloadArtwork {
  /// Creates the pinner of a profile whose downloads are in `downloads`
  /// and announced on `events`, with covers of the server of `urls`
  /// fetched with the `credentials` of the moment by `fetch` and written
  /// by `store` under `artDirectory`. `delay` waits between repair
  /// fetches; it defaults to a timer.
  new({
    required this._downloads,
    required this._events,
    required this._reachability,
    required this._urls,
    required this._credentials,
    required this._fetch,
    required this._store,
    required this._artDirectory,
    required this._clock,
    Future<void> Function(Duration)? delay,
  }) : _delay = delay ?? _wait;

  /// The most fetches the start-up repair makes in one second.
  static const int repairRate = 4;

  static final AppLogger _log = AppLogger.scope('Downloads');

  static Future<void> _wait(Duration duration) =>
      Future<void>.delayed(duration);

  final DownloadStore _downloads;
  final Stream<DownloadControllerEvent> _events;
  final ReachabilityController _reachability;
  final ImageUrls _urls;
  final Credentials? Function() _credentials;
  final ArtworkBytesFetcher _fetch;
  final ArtworkStore _store;
  final String _artDirectory;
  final Clock _clock;
  final Future<void> Function(Duration) _delay;

  final Map<String, Future<String?>> _inFlight = {};
  final List<StreamSubscription<Object?>> _subscriptions = [];
  Future<void> _tail = Future<void>.value();
  bool _started = false;
  bool _repaired = false;
  bool _disposed = false;

  @override
  void start() {
    if (_started || _disposed) return;
    _started = true;
    _subscriptions
      ..add(_events.listen(_onEvent))
      ..add(
        _reachability.changes.listen((state) {
          if (state == Reachability.online) _scheduleRepair();
        }),
      );
    if (_reachability.isOnline) _scheduleRepair();
  }

  /// Completes when every reaction started so far has run.
  @visibleForTesting
  Future<void> settle() async {
    Future<void> tail;
    do {
      tail = _tail;
      await tail;
      await Future<void>.delayed(Duration.zero);
    } while (!identical(tail, _tail));
  }

  /// Stops reacting. Work already started still finishes.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    await _tail;
  }

  @override
  Future<String?> pin(String ref) async {
    final pending = _inFlight[ref];
    if (pending != null) return await pending;
    final pinning = _pinOnce(ref);
    _inFlight[ref] = pinning;
    try {
      return await pinning;
    } finally {
      // The removed future is [pinning] itself, already complete.
      unawaited(_inFlight.remove(ref));
    }
  }

  @override
  Future<String?> fileFor(String ref) async {
    final path = _pathOf(ref);
    return await _store.exists(path) ? path : null;
  }

  @override
  Future<int> removeUnreferenced() async {
    final referenced = {
      for (final ref in await _referencedRefs()) downloadArtworkFileName(ref),
    };
    var removed = 0;
    for (final name in await _store.list(_artDirectory)) {
      if (!_pinnedName.hasMatch(name) || referenced.contains(name)) continue;
      try {
        await _store.delete(p.join(_artDirectory, name));
        removed++;
      } on Object catch (error, stackTrace) {
        _log.warning(
          'Could not delete pinned artwork',
          const {},
          error,
          stackTrace,
        );
      }
    }
    return removed;
  }

  String _pathOf(String ref) =>
      p.join(_artDirectory, downloadArtworkFileName(ref));

  Future<String?> _pinOnce(String ref) async {
    final existing = await fileFor(ref);
    if (existing != null) return existing;
    if (!_reachability.isOnline) return null;
    final path = _pathOf(ref);
    try {
      await fetchAndStoreArtwork(
        ref,
        path: path,
        urls: _urls,
        credentials: _credentials(),
        fetch: _fetch,
        store: _store,
      );
      return path;
    } on Object catch (error) {
      _log.fine('Download artwork was not pinned', {
        'error': error.runtimeType.toString(),
      });
      return null;
    }
  }

  void _onEvent(DownloadControllerEvent event) {
    switch (event) {
      case DownloadItemCompleted(:final key):
        _serial(() async {
          final row = await _downloads.item(key);
          await _pinAll([
            if (row != null) artworkRefOf(row.metaJson),
            for (final collection in await _downloads.collectionsOf(key))
              artworkRefOf(collection.metaJson),
          ]);
        });
      case DownloadCollectionReady(:final kind, :final refId):
        _serial(() async {
          final row = await _downloads.collection(kind, refId);
          if (row != null) await _pinAll([artworkRefOf(row.metaJson)]);
        });
      case DownloadCollectionRemoved():
        _serial(removeUnreferenced);
    }
  }

  Future<void> _pinAll(Iterable<String?> refs) async {
    for (final ref in {...refs.nonNulls}) {
      await pin(ref);
    }
  }

  void _scheduleRepair() {
    if (_repaired || _disposed) return;
    _repaired = true;
    _serial(_repair);
  }

  /// Pins, one after another and at most [repairRate] a second, the covers
  /// of completed items and ready collections that have no file.
  Future<void> _repair() async {
    final refs = <String>{
      for (final item in await _downloads.itemsByStatus(
        DownloadStatus.completed,
      ))
        ?artworkRefOf(item.metaJson),
      for (final collection in await _downloads.collectionsByStatus(
        DownloadCollectionStatus.ready,
      ))
        ?artworkRefOf(collection.metaJson),
    };
    const interval = Duration(milliseconds: 1000 ~/ repairRate);
    DateTime? lastFetch;
    for (final ref in refs) {
      if (_disposed || !_reachability.isOnline) return;
      if (await fileFor(ref) != null) continue;
      if (lastFetch != null) {
        final wait = interval - _clock.now().difference(lastFetch);
        if (wait > Duration.zero) await _delay(wait);
      }
      lastFetch = _clock.now();
      await pin(ref);
    }
  }

  Future<Set<String>> _referencedRefs() async => {
    for (final item in await _downloads.items()) ?artworkRefOf(item.metaJson),
    for (final collection in await _downloads.collections())
      ?artworkRefOf(collection.metaJson),
  };

  void _serial(Future<void> Function() body) {
    _tail = _tail.then((_) async {
      try {
        await body();
      } on Object catch (error, stackTrace) {
        _log.warning(
          'Download artwork upkeep failed',
          const {},
          error,
          stackTrace,
        );
      }
    });
  }
}

/// The [DownloadArtwork] of the profile scope: covers of the profile's
/// server, fetched through its image cache with the session's current
/// credentials and written under its `art/` directory. A no-op where
/// [PlatformCapabilities.canDownload] is false or there is no profile
/// directory. `startDownloads` starts it after the scheduler.
final Provider<DownloadArtwork> downloadArtworkProvider =
    Provider<DownloadArtwork>(
      (ref) {
        final artDirectory = ref.watch(profileContextProvider).paths?.art;
        if (kIsWeb ||
            !ref.watch(platformCapabilitiesProvider).canDownload ||
            artDirectory == null) {
          return const NoDownloadArtwork();
        }
        final session = ref.watch(sessionControllerProvider);
        final artwork = ProfileDownloadArtwork(
          downloads: ref.watch(downloadStoreProvider),
          events: ref.watch(downloadControllerProvider).events,
          reachability: ref.watch(reachabilityProvider),
          urls: ImageUrls(ref.watch(apiConfigProvider).baseUrl),
          credentials: () => session.current,
          // The image cache is opened on the first fetch, not at start-up.
          fetch: (fetch) => imageCacheBytesFetcher(
            ref.read(imageCacheManagerProvider),
          )(fetch),
          store: ref.watch(artworkStoreProvider),
          artDirectory: artDirectory,
          clock: ref.watch(clockProvider),
        );
        ref.watch(profileDisposerProvider).register(artwork.dispose);
        return artwork;
      },
      dependencies: [
        profileContextProvider,
        sessionControllerProvider,
        downloadStoreProvider,
        downloadControllerProvider,
        apiConfigProvider,
        imageCacheManagerProvider,
        profileDisposerProvider,
      ],
    );
