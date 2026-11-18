// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// One page of an offset-paged list (doc 03, Pagination): albums, tracks,
/// playlists, search, and artists, which may also carry a cursor.
final class OffsetPage<T> {
  /// Creates a page.
  const new({
    required this.items,
    required this.offset,
    required this.limit,
    this.total,
    this.nextCursor,
  });

  /// The items of this page, in server order.
  final List<T> items;

  /// The offset of the first item of this page.
  final int offset;

  /// The page size that was requested.
  final int limit;

  /// The number of items in the whole list, when the server sent it.
  final int? total;

  /// The cursor to pass back for the next page, when the server sent one.
  final String? nextCursor;

  /// Whether a further page exists: compared against [total] when it is
  /// known, otherwise a full page is taken to mean more may follow.
  bool get hasMore {
    final total = this.total;
    if (total != null) return offset + items.length < total;
    return items.isNotEmpty && items.length == limit;
  }

  /// The offset of the page after this one.
  int get nextOffset => offset + items.length;
}

/// One page of a keyset-paged list (doc 03, Pagination): liked tracks.
final class KeysetPage<T, C> {
  /// Creates a page.
  const new({
    required this.items,
    required this.hasMore,
    this.nextCursor,
    this.total,
  });

  /// The items of this page, in server order.
  final List<T> items;

  /// The cursor to pass back for the next page; null when there is none.
  final C? nextCursor;

  /// Whether the server reported a further page.
  final bool hasMore;

  /// The number of items in the whole list, when the server sent it.
  final int? total;
}
