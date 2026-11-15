// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/features/discover/data/discovery_mappers.dart';
import 'package:soundspan/features/discover/domain/discovery_artist.dart';
import 'package:soundspan/features/discover/domain/discovery_playlist.dart';
import 'package:soundspan/features/discover/domain/discovery_repository.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/swr.dart';
import 'package:soundspan/shared/domain/cached.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// The blob of the recommended artists.
const recommendedForYouKey = 'discovery:recommendedForYou';

/// The blob of the popular artists.
const popularArtistsKey = 'discovery:popularArtists';

/// The blob of this week's discovery playlist; JSON `null` when the server
/// has none.
const currentDiscoveryKey = 'discovery:current';

/// [DiscoveryRepository] over the cache and the generated
/// `DiscoveryClient`. Each read is one blob with the Home shelf TTL (doc 05,
/// TTL table).
class CachedDiscoveryRepository implements DiscoveryRepository {
  /// A repository reading [_client] into [_store] through [_swr].
  new(this._client, this._store, this._swr);

  final api.DiscoveryClient _client;
  final CacheStore _store;
  final Swr _swr;

  @override
  Stream<Cached<List<DiscoveryArtist>>> recommendedForYou({int limit = 20}) =>
      _artists(recommendedForYouKey, () => _fetchRecommended(limit));

  @override
  Future<void> refreshRecommendedForYou({int limit = 20}) =>
      _swr.refresh(recommendedForYouKey, () => _fetchRecommended(limit));

  @override
  Stream<Cached<List<DiscoveryArtist>>> popularArtists({int limit = 20}) =>
      _artists(popularArtistsKey, () => _fetchPopular(limit));

  @override
  Future<void> refreshPopularArtists({int limit = 20}) =>
      _swr.refresh(popularArtistsKey, () => _fetchPopular(limit));

  @override
  Stream<Cached<DiscoveryPlaylist?>> currentDiscovery() => _swr.watch(
    key: currentDiscoveryKey,
    ttl: homeShelfTtl,
    cache: () => _store.watchBlob(
      currentDiscoveryKey,
      (json) => json == null
          ? null
          : DiscoveryPlaylist.fromJson(json as Map<String, Object?>),
    ),
    fetch: _fetchCurrent,
  );

  @override
  Future<void> refreshCurrentDiscovery() =>
      _swr.refresh(currentDiscoveryKey, _fetchCurrent);

  Stream<Cached<List<DiscoveryArtist>>> _artists(
    String key,
    Future<void> Function() fetch,
  ) => _swr.watch(
    key: key,
    ttl: homeShelfTtl,
    cache: () => _store.watchBlob(key, (json) {
      return [
        for (final item in json! as List<Object?>)
          DiscoveryArtist.fromJson(item! as Map<String, Object?>),
      ];
    }),
    fetch: fetch,
  );

  Future<void> _fetchRecommended(int limit) async {
    final wire = await _client.getRecommendationsForYou(limit: limit);
    await _store.putBlob(recommendedForYouKey, [
      for (final artist in wire.artists) recommendedArtistFromWire(artist),
    ]);
  }

  Future<void> _fetchPopular(int limit) async {
    final wire = await _client.listPopularArtists(limit: limit);
    await _store.putBlob(popularArtistsKey, [
      for (final artist in wire.artists) popularArtistFromWire(artist),
    ]);
  }

  Future<void> _fetchCurrent() async {
    final wire = await _client.getCurrentDiscover();
    await _store.putBlob(currentDiscoveryKey, discoveryPlaylistFromWire(wire));
  }
}
