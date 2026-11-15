// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:math' as math;

import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/swr.dart' show listPageTtl;
import 'package:soundspan/shared/domain/paged_source.dart';
import 'package:soundspan_api/soundspan_api.dart' show ApiException, Offline;

/// How a list's pages follow each other (doc 03, Pagination).
enum PagingStyle {
  /// Each page is addressed by its offset; a cursor the server sent with a
  /// page is passed back with the next one.
  offset,

  /// Each page needs the cursor of the page before it, so pages load in
  /// order.
  keyset,
}

/// What a [PageFetcher] is asked for: page `index`, which starts at
/// `offset` and holds up to `limit` items. `cursor` is the cursor the
/// previous page returned, when it is known; for [PagingStyle.keyset] it is
/// always known and null only for the first page.
typedef PageRequest = ({int index, int offset, int limit, Object? cursor});

/// One page as the server sent it.
final class FetchedPage<T> {
  /// A page of [items].
  const new({
    required this.items,
    required this.hasMore,
    this.total,
    this.nextCursor,
  });

  /// The items, in server order.
  final List<T> items;

  /// Whether a further page exists.
  final bool hasMore;

  /// The number of items in the whole list, when the server sent it.
  final int? total;

  /// The cursor to pass back with the next page, when the server sent one.
  final Object? nextCursor;
}

/// Gets one page from the server. `ApiException` propagates unchanged.
typedef PageFetcher<T> = Future<FetchedPage<T>> Function(PageRequest request);

/// [PagedSource] over the cache list [listKey] and a [PageFetcher].
///
/// The cached list is read first; a page is fetched when it has no cached
/// item or is older than [listPageTtl], and only while the server is
/// reachable. A page is as old as the oldest stored item in it; an empty
/// list is as old as the list. Fetched pages are written to the cache,
/// which emits the new state.
class CachedPagedSource<T extends Object> implements PagedSource<T> {
  /// A source of pages of [pageSize] for [listKey].
  new({
    required this.listKey,
    required this.pageSize,
    required this._store,
    required this._clock,
    required this._reachability,
    required this._fetchPage,
    this.style = PagingStyle.offset,
  }) {
    _cacheSubscription = _store
        .watchList(listKey)
        .listen(_onCache, onError: _controller.addError);
  }

  /// The cache key of the list.
  final String listKey;

  @override
  final int pageSize;

  /// How pages follow each other.
  final PagingStyle style;

  final CacheStore _store;
  final Clock _clock;
  final ReachabilityController _reachability;
  final PageFetcher<T> _fetchPage;
  final StreamController<PagedSnapshot<T>> _controller =
      StreamController<PagedSnapshot<T>>.broadcast();
  late final StreamSubscription<CacheListSnapshot?> _cacheSubscription;

  Map<int, T> _items = const {};
  Map<int, DateTime> _itemFetchedAt = const {};
  int? _total;
  bool _cacheRead = false;
  DateTime? _listFetchedAt;
  final Set<int> _inflight = {};
  final Map<int, Object?> _cursors = {0: null};
  int? _lastPage;
  ApiException? _error;
  (int, int)? _visible;
  int _keysetTarget = -1;
  Future<void>? _keysetChain;
  bool _disposed = false;
  PagedSnapshot<T>? _current;

  @override
  Stream<PagedSnapshot<T>> watch() => Stream.multi((listener) {
    if (_current case final current?) listener.add(current);
    final subscription = _controller.stream.listen(
      listener.add,
      onError: listener.addError,
      onDone: listener.close,
    );
    listener.onCancel = subscription.cancel;
  });

  @override
  void ensureVisible(int first, int last) {
    if (_disposed) return;
    final from = math.max(0, first);
    _visible = (from, math.max(from, last));
    if (_cacheRead) unawaited(_load(force: false));
  }

  @override
  Future<void> refresh() async {
    if (_disposed) return;
    if (!_cacheRead) await _controller.stream.first;
    if (!_reachability.isOnline) {
      _error = const Offline();
      _emit();
      return;
    }
    await _load(force: true);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_cacheSubscription.cancel());
    unawaited(_controller.close());
  }

  void _onCache(CacheListSnapshot? list) {
    if (_disposed) return;
    final items = <int, T>{};
    final fetchedAt = <int, DateTime>{};
    if (list != null) {
      for (final (index, item) in list.items.indexed) {
        if (item is T) {
          final position = list.positions[index];
          items[position] = item;
          fetchedAt[position] = list.itemFetchedAt[index];
        }
      }
    }
    _items = items;
    _itemFetchedAt = fetchedAt;
    _total = list?.total;
    _listFetchedAt = list?.fetchedAt;
    if (!_cacheRead) {
      _cacheRead = true;
      _emit();
      if (_visible != null) unawaited(_load(force: false));
    } else {
      _emit();
    }
  }

  void _emit() {
    if (_disposed) return;
    final snapshot = PagedSnapshot<T>(
      total: _total,
      items: _items,
      refreshing: _inflight.isNotEmpty || _keysetChain != null,
      refreshError: _error,
    );
    _current = snapshot;
    _controller.add(snapshot);
  }

  /// The pages to load: with [force], those covering the visible range;
  /// otherwise also the page after it, minus the ones that are fresh.
  Future<void> _load({required bool force}) {
    final (first, last) = _visible ?? (0, 0);
    final firstPage = first ~/ pageSize;
    final lastPage = last ~/ pageSize + (force ? 0 : 1);
    final wanted = [
      for (var page = firstPage; page <= lastPage; page++)
        if (_exists(page) && (force || _needsFetch(page))) page,
    ];
    if (wanted.isEmpty) return Future.value();
    if (!_reachability.isOnline) return Future.value();
    return switch (style) {
      PagingStyle.offset => Future.wait([
        for (final page in wanted)
          if (!_inflight.contains(page)) _fetch(page),
      ]),
      PagingStyle.keyset => _chainTo(wanted.last),
    };
  }

  /// Whether [page] can hold items, as far as is known. The first page
  /// always can, so an empty list is refreshed too.
  bool _exists(int page) {
    if (page == 0) return true;
    if (_lastPage case final lastPage? when page > lastPage) return false;
    if (_total case final total? when page * pageSize >= total) return false;
    return true;
  }

  /// When [page] was stored: the oldest time among its items, or for an
  /// empty list the list's time; null when it is not cached.
  DateTime? _pageFetchedAt(int page) {
    DateTime? oldest;
    final start = page * pageSize;
    for (var index = start; index < start + pageSize; index++) {
      if (_itemFetchedAt[index] case final fetchedAt?
          when oldest == null || fetchedAt.isBefore(oldest)) {
        oldest = fetchedAt;
      }
    }
    if (oldest == null && page == 0 && _total == 0) return _listFetchedAt;
    return oldest;
  }

  bool _needsFetch(int page) {
    final fetchedAt = _pageFetchedAt(page);
    if (fetchedAt == null) return true;
    return _clock.now().difference(fetchedAt) > listPageTtl;
  }

  /// Loads keyset pages in order up to [target], starting at the last page
  /// whose cursor is known; joins a chain already running.
  Future<void> _chainTo(int target) {
    _keysetTarget = math.max(_keysetTarget, target);
    return _keysetChain ??= () async {
      try {
        var page = _cursors.keys
            .where((known) => known <= _keysetTarget)
            .reduce(math.max);
        while (!_disposed && page <= _keysetTarget && _exists(page)) {
          if (!await _fetch(page)) break;
          page++;
        }
      } finally {
        _keysetChain = null;
        _keysetTarget = -1;
        _emit();
      }
    }();
  }

  /// Fetches and stores [page]; answers whether it succeeded.
  Future<bool> _fetch(int page) async {
    _inflight.add(page);
    _emit();
    final offset = page * pageSize;
    try {
      final FetchedPage<T> result;
      try {
        result = await _fetchPage((
          index: page,
          offset: offset,
          limit: pageSize,
          cursor: _cursors[page],
        ));
        _reachability.reportCallOutcome(success: true);
      } on Offline {
        _reachability.reportCallOutcome(success: false);
        rethrow;
      } on ApiException {
        _reachability.reportCallOutcome(success: true);
        rethrow;
      }
      if (_disposed) return false;
      if (result.nextCursor != null || style == PagingStyle.keyset) {
        _cursors[page + 1] = result.nextCursor;
      }
      // Without a server total, only the last page's end is the total; an
      // empty page past the end says only that the list ends before it.
      final pastEnd = !result.hasMore && result.items.isEmpty && page > 0;
      final total =
          result.total ??
          (result.hasMore || pastEnd ? _total : offset + result.items.length);
      if (!result.hasMore) _lastPage = pastEnd ? page - 1 : page;
      _total = total;
      _error = null;
      await _store.writePage(
        listKey,
        offset: offset,
        items: result.items,
        total: total,
        complete: !result.hasMore,
      );
      return true;
    } on ApiException catch (error) {
      _error = error;
      return false;
    } on Object catch (error, stackTrace) {
      if (!_disposed) _controller.addError(error, stackTrace);
      return false;
    } finally {
      _inflight.remove(page);
      _emit();
    }
  }
}

/// Creates the [CachedPagedSource]s of one profile's repositories.
class PagedSources {
  /// Sources over [_store] that read the time from [_clock] and the
  /// server's state from [_reachability].
  new(this._store, this._clock, this._reachability);

  final CacheStore _store;
  final Clock _clock;
  final ReachabilityController _reachability;

  /// A source of pages of [pageSize] for [listKey], fetched by [fetchPage].
  PagedSource<T> create<T extends Object>({
    required String listKey,
    required int pageSize,
    required PageFetcher<T> fetchPage,
    PagingStyle style = PagingStyle.offset,
  }) => CachedPagedSource<T>(
    listKey: listKey,
    pageSize: pageSize,
    store: _store,
    clock: _clock,
    reachability: _reachability,
    fetchPage: fetchPage,
    style: style,
  );
}
