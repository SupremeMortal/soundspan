// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/sync/outbox/optimistic_overlay.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/preference_overlay.dart';
import 'package:soundspan/shared/data/search/search_remote_source.dart';
import 'package:soundspan/shared/data/swr.dart';
import 'package:soundspan/shared/domain/domain.dart';

/// [SearchRepository] over the cache and [SearchRemoteSource].
///
/// Each page is one blob, `search:<query>:<filter>`, with `:<offset>`
/// appended after the first page, so a page is served offline only for the
/// exact query, filter and offset that were cached. Every page asks for
/// [searchPageSize] results. Results show the pending likes of the outbox
/// ([PendingOps]).
class CachedSearchRepository implements SearchRepository {
  /// A repository reading [_remote] into [_store] through [_swr], overlaid
  /// with the ops [_pending] answers.
  new(this._remote, this._store, this._swr, {this._pending = noPendingOps});

  final SearchRemoteSource _remote;
  final CacheStore _store;
  final Swr _swr;
  final PendingOps _pending;

  @override
  Stream<Cached<SearchPage>> search(
    String query,
    SearchFilter filter, {
    int offset = 0,
  }) {
    final start = _offset(filter, offset);
    final key = _key(query, filter, start);
    return overlay(
      _swr.watch(
        key: key,
        ttl: searchTtl,
        cache: () => _store.watchBlob(
          key,
          (json) => SearchPage.fromJson(json! as Map<String, Object?>),
        ),
        fetch: () => _fetch(key, query, filter, start),
      ),
      _pending(albumPreferenceOps),
      overlaySearchPage,
      hold: preferenceHold,
    );
  }

  @override
  Future<void> refreshSearch(
    String query,
    SearchFilter filter, {
    int offset = 0,
  }) {
    final start = _offset(filter, offset);
    final key = _key(query, filter, start);
    return _swr.refresh(key, () => _fetch(key, query, filter, start));
  }

  /// [offset], or 0 for [SearchFilter.all], which does not page.
  static int _offset(SearchFilter filter, int offset) =>
      filter == SearchFilter.all ? 0 : offset;

  static String _key(String query, SearchFilter filter, int offset) =>
      offset == 0
      ? 'search:$query:${filter.name}'
      : 'search:$query:${filter.name}:$offset';

  Future<void> _fetch(
    String key,
    String query,
    SearchFilter filter,
    int offset,
  ) async {
    final page = await _remote.search(
      query,
      filter: filter,
      limit: searchPageSize,
      offset: filter == SearchFilter.all ? null : offset,
    );
    await _store.putBlob(key, page);
  }
}
