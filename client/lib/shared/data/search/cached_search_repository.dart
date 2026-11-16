// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/sync/outbox/optimistic_overlay.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/preference_overlay.dart';
import 'package:soundspan/shared/data/search/search_remote_source.dart';
import 'package:soundspan/shared/data/swr.dart';
import 'package:soundspan/shared/domain/domain.dart';

/// [SearchRepository] over the cache and [SearchRemoteSource].
///
/// The results of one query and scope are one blob, `search:<query>:<scope>`,
/// so a result is served offline only for the exact query and scope that
/// were cached. [SearchScope.all] and [SearchScope.library] call the library
/// search, [SearchScope.all] and [SearchScope.discover] the catalogue search,
/// and [SearchScope.podcasts] the library search for podcasts. Results show
/// the pending likes of the outbox ([PendingOps]).
class CachedSearchRepository implements SearchRepository {
  /// A repository reading [_remote] into [_store] through [_swr], overlaid
  /// with the ops [_pending] answers.
  new(this._remote, this._store, this._swr, {this._pending = noPendingOps});

  final SearchRemoteSource _remote;
  final CacheStore _store;
  final Swr _swr;
  final PendingOps _pending;

  @override
  Stream<Cached<SearchResults>> search(String query, SearchScope scope) {
    final key = _key(query, scope);
    return overlay(
      _swr.watch(
        key: key,
        ttl: searchTtl,
        cache: () => _store.watchBlob(
          key,
          (json) => SearchResults.fromJson(json! as Map<String, Object?>),
        ),
        fetch: () => _fetch(key, query, scope),
      ),
      _pending(albumPreferenceOps),
      overlaySearchResults,
      hold: preferenceHold,
    );
  }

  @override
  Future<void> refreshSearch(String query, SearchScope scope) {
    final key = _key(query, scope);
    return _swr.refresh(key, () => _fetch(key, query, scope));
  }

  static String _key(String query, SearchScope scope) =>
      'search:$query:${scope.name}';

  Future<void> _fetch(String key, String query, SearchScope scope) async {
    // Future.wait rethrows the first failure as it is and handles the
    // other.
    final results = await Future.wait<Object?>([
      switch (scope) {
        SearchScope.all || SearchScope.library => _remote.library(query),
        SearchScope.podcasts => _remote.library(
          query,
          type: LibrarySearchType.podcasts,
        ),
        SearchScope.discover => Future<Object?>.value(),
      },
      switch (scope) {
        SearchScope.all || SearchScope.discover => _remote.discover(query),
        SearchScope.library || SearchScope.podcasts => Future<Object?>.value(),
      },
    ]);
    final library = results[0] as LibrarySearchResults?;
    final discover = results[1] as DiscoverResults?;
    await _store.putBlob(
      key,
      SearchResults(library: library, discover: discover),
    );
  }
}
