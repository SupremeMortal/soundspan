// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan_api/soundspan_api.dart' show ApiException;

/// The page size of the album and artist grids (doc 03, Pagination).
const int gridPageSize = 60;

/// The page size of track and playlist lists (doc 03, Pagination).
const int listPageSize = 100;

/// A long list that loads only the pages on screen and serves cached pages
/// first (doc 03, Pagination; doc 09, Library).
abstract interface class PagedSource<T> {
  /// How many items one page holds.
  int get pageSize;

  /// Every change of the list. A new listener gets the current state first
  /// once the cache has been read.
  Stream<PagedSnapshot<T>> watch();

  /// Called by the list as it scrolls, with the first and last visible
  /// indexes. Loads the page containing [first] and the one after it, and
  /// the page containing [last] when that is a later one.
  void ensureVisible(int first, int last);

  /// Fetches the pages covering the last visible range again, whatever
  /// their age.
  Future<void> refresh();

  /// Stops loading and emitting.
  void dispose();
}

/// One state of a [PagedSource].
final class PagedSnapshot<T> {
  /// A state of [total] items, of which `items` (by index) are loaded.
  const new({
    this.total,
    this._items = const {},
    this.refreshing = false,
    this.refreshError,
  });

  /// The number of items in the whole list; null until the first page or a
  /// cached total is known.
  final int? total;

  final Map<int, T> _items;

  /// Whether a page fetch is in flight.
  final bool refreshing;

  /// Why the last page fetch failed; the loaded items are kept.
  final ApiException? refreshError;

  /// The item at [index], or null when it is not loaded: the list then
  /// renders a skeleton of fixed height.
  T? itemAt(int index) => _items[index];

  /// How many items are loaded.
  int get loadedCount => _items.length;

  /// The loaded items by index.
  Map<int, T> get loaded => Map.unmodifiable(_items);

  @override
  String toString() =>
      'PagedSnapshot(total: $total, loaded: ${_items.length}, '
      'refreshing: $refreshing, refreshError: $refreshError)';
}
