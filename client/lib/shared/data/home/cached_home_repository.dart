// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/home/home_remote_source.dart';
import 'package:soundspan/shared/data/swr.dart';
import 'package:soundspan/shared/domain/domain.dart';

/// [HomeRepository] over the cache and [HomeRemoteSource]. Each shelf is
/// one blob, `home:<shelf>`.
class CachedHomeRepository implements HomeRepository {
  /// A repository reading [_remote] into [_store] through [_swr].
  new(this._remote, this._store, this._swr);

  final HomeRemoteSource _remote;
  final CacheStore _store;
  final Swr _swr;

  @override
  Stream<Cached<List<RecentItem>>> recentlyListened() =>
      _shelf('recentlyListened', _remote.recentlyListened, RecentItem.fromJson);

  @override
  Future<void> refreshRecentlyListened() =>
      _refresh('recentlyListened', _remote.recentlyListened);

  @override
  Stream<Cached<List<Artist>>> recentlyAdded() =>
      _shelf('recentlyAdded', _remote.recentlyAdded, Artist.fromJson);

  @override
  Future<void> refreshRecentlyAdded() =>
      _refresh('recentlyAdded', _remote.recentlyAdded);

  @override
  Stream<Cached<List<MixSummary>>> mixes() =>
      _shelf('mixes', _remote.mixes, MixSummary.fromJson);

  @override
  Future<void> refreshMixes() => _refresh('mixes', _remote.mixes);

  @override
  Stream<Cached<List<PodcastSummary>>> topPodcasts() =>
      _shelf('topPodcasts', _remote.topPodcasts, PodcastSummary.fromJson);

  @override
  Future<void> refreshTopPodcasts() =>
      _refresh('topPodcasts', _remote.topPodcasts);

  Stream<Cached<List<T>>> _shelf<T>(
    String shelf,
    Future<List<T>> Function() fetch,
    T Function(Map<String, Object?> json) decode,
  ) => _swr.watch(
    key: 'home:$shelf',
    ttl: homeShelfTtl,
    cache: () => _store.watchBlob('home:$shelf', (json) {
      return [
        for (final item in json! as List<Object?>)
          decode(item! as Map<String, Object?>),
      ];
    }),
    fetch: () async {
      await _store.putBlob('home:$shelf', await fetch());
    },
  );

  Future<void> _refresh<T>(String shelf, Future<List<T>> Function() fetch) =>
      _swr.refresh('home:$shelf', () async {
        await _store.putBlob('home:$shelf', await fetch());
      });
}
