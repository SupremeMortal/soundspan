// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/profile/api_provider.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/core/profile/profile_disposer.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/core/storage/cache/open_cache_database.dart';
import 'package:soundspan/core/storage/providers.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/home/home_remote_source.dart';
import 'package:soundspan/shared/data/library/library_remote_source.dart';
import 'package:soundspan/shared/data/playlist/playlist_remote_source.dart';
import 'package:soundspan/shared/data/search/search_remote_source.dart';

/// The profile's `cache.db`, opened with `openCacheDatabase` and closed
/// through the [ProfileDisposer] when the profile scope ends.
final FutureProvider<CacheDatabase> cacheDatabaseProvider =
    FutureProvider<CacheDatabase>((ref) async {
      final profileId = ref.watch(profileContextProvider).profile.id;
      final disposer = ref.watch(profileDisposerProvider);
      final database = await openCacheDatabase(
        ref.watch(databaseOpenerProvider),
        profileId,
      );
      disposer.register(database.close);
      return database;
    }, dependencies: [profileContextProvider, profileDisposerProvider]);

/// The [CacheStore] over [cacheDatabaseProvider].
final FutureProvider<CacheStore> cacheStoreProvider =
    FutureProvider<CacheStore>(
      (ref) async => CacheStore(
        await ref.watch(cacheDatabaseProvider.future),
        ref.watch(clockProvider),
      ),
      dependencies: [cacheDatabaseProvider],
    );

/// The profile's [LibraryRemoteSource].
final Provider<LibraryRemoteSource> libraryRemoteSourceProvider =
    Provider<LibraryRemoteSource>(
      (ref) =>
          LibraryRemoteSource(ref.watch(soundspanApiProvider).rest.library2),
      dependencies: [soundspanApiProvider],
    );

/// The profile's [PlaylistRemoteSource].
final Provider<PlaylistRemoteSource> playlistRemoteSourceProvider =
    Provider<PlaylistRemoteSource>(
      (ref) =>
          PlaylistRemoteSource(ref.watch(soundspanApiProvider).rest.playlists),
      dependencies: [soundspanApiProvider],
    );

/// The profile's [SearchRemoteSource].
final Provider<SearchRemoteSource> searchRemoteSourceProvider =
    Provider<SearchRemoteSource>(
      (ref) => SearchRemoteSource(ref.watch(soundspanApiProvider).rest.search),
      dependencies: [soundspanApiProvider],
    );

/// The profile's [HomeRemoteSource].
final Provider<HomeRemoteSource> homeRemoteSourceProvider =
    Provider<HomeRemoteSource>((ref) {
      final rest = ref.watch(soundspanApiProvider).rest;
      return HomeRemoteSource(
        libraryClient: rest.library2,
        discoveryClient: rest.discovery,
        podcastsClient: rest.podcasts,
      );
    }, dependencies: [soundspanApiProvider]);
