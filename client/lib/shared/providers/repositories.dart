// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The profile-scoped repositories the UI reads (doc 02, Riverpod
/// Structure). They live outside `data/` because `ui/` may not import it.
///
/// Each provider is a [FutureProvider] because the profile's `cache.db`
/// opens asynchronously; it throws outside a profile scope.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/storage/cache/cache_pruner.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/data/home/cached_home_repository.dart';
import 'package:soundspan/shared/data/library/cached_library_repository.dart';
import 'package:soundspan/shared/data/paged_source_impl.dart';
import 'package:soundspan/shared/data/playlist/cached_playlist_repository.dart';
import 'package:soundspan/shared/data/search/cached_search_repository.dart';
import 'package:soundspan/shared/data/swr.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/cache.dart';

final AppLogger _log = AppLogger.scope('Cache');

/// The profile's [Swr], shared by its repositories so concurrent listeners
/// of one key share one fetch.
final Provider<Swr> swrProvider = Provider<Swr>((ref) {
  // Read only to tie the instance to the profile scope.
  ref.watch(profileContextProvider);
  return Swr(
    clock: ref.watch(clockProvider),
    reachability: ref.watch(reachabilityProvider),
  );
}, dependencies: [profileContextProvider]);

/// The profile's [PagedSources].
final FutureProvider<PagedSources> pagedSourcesProvider =
    FutureProvider<PagedSources>(
      (ref) async => PagedSources(
        await ref.watch(cacheStoreProvider.future),
        ref.watch(clockProvider),
        ref.watch(reachabilityProvider),
      ),
      dependencies: [cacheStoreProvider],
    );

/// The profile's [LibraryRepository].
final FutureProvider<LibraryRepository> libraryRepositoryProvider =
    FutureProvider<LibraryRepository>(
      (ref) async => CachedLibraryRepository(
        ref.watch(libraryRemoteSourceProvider),
        await ref.watch(cacheStoreProvider.future),
        ref.watch(swrProvider),
        await ref.watch(pagedSourcesProvider.future),
      ),
      dependencies: [
        libraryRemoteSourceProvider,
        cacheStoreProvider,
        swrProvider,
        pagedSourcesProvider,
      ],
    );

/// The profile's [PlaylistRepository].
final FutureProvider<PlaylistRepository> playlistRepositoryProvider =
    FutureProvider<PlaylistRepository>(
      (ref) async => CachedPlaylistRepository(
        ref.watch(playlistRemoteSourceProvider),
        await ref.watch(cacheStoreProvider.future),
        ref.watch(swrProvider),
        await ref.watch(pagedSourcesProvider.future),
      ),
      dependencies: [
        playlistRemoteSourceProvider,
        cacheStoreProvider,
        swrProvider,
        pagedSourcesProvider,
      ],
    );

/// The profile's [HomeRepository].
final FutureProvider<HomeRepository> homeRepositoryProvider =
    FutureProvider<HomeRepository>(
      (ref) async => CachedHomeRepository(
        ref.watch(homeRemoteSourceProvider),
        await ref.watch(cacheStoreProvider.future),
        ref.watch(swrProvider),
      ),
      dependencies: [homeRemoteSourceProvider, cacheStoreProvider, swrProvider],
    );

/// The profile's [SearchRepository].
final FutureProvider<SearchRepository> searchRepositoryProvider =
    FutureProvider<SearchRepository>(
      (ref) async => CachedSearchRepository(
        ref.watch(searchRemoteSourceProvider),
        await ref.watch(cacheStoreProvider.future),
        ref.watch(swrProvider),
      ),
      dependencies: [
        searchRemoteSourceProvider,
        cacheStoreProvider,
        swrProvider,
      ],
    );

/// The profile's [CachePruner], over its `cache.db`.
final FutureProvider<CachePruner> cachePrunerProvider =
    FutureProvider<CachePruner>(
      (ref) async => CachePruner(
        await ref.watch(cacheDatabaseProvider.future),
        ref.watch(clockProvider),
      ),
      dependencies: [cacheDatabaseProvider],
    );

/// The post-first-frame task of cache pruning (doc 02, Bootstrap Sequence,
/// step 8; doc 05, Pruning): prunes the `cache.db` of every profile
/// container the [ProfileRuntime] under `root` activates, once per
/// container.
Future<void> startCachePruning(ProviderContainer root) async {
  final runtime = root.read(profileRuntimeProvider);
  final pruned = Expando<bool>();
  void onState() {
    final container = runtime.container;
    if (runtime.state.value is! ProfileRuntimeActive || container == null) {
      return;
    }
    if (pruned[container] ?? false) return;
    pruned[container] = true;
    unawaited(
      container
          .read(cachePrunerProvider.future)
          .then((pruner) => pruner.pruneIfNeeded(atStartup: true))
          .then<void>(
            (_) {},
            onError: (Object error, StackTrace stackTrace) => _log.warning(
              'Cache pruning failed',
              const {},
              error,
              stackTrace,
            ),
          ),
    );
  }

  runtime.state.addListener(onState);
  onState();
}
