// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/shared/domain/cached.dart';
import 'package:soundspan/shared/domain/search_results.dart';

/// Search, served from the cache and refreshed in the background (doc 05,
/// Read Policy: Stale-While-Revalidate). Offline, a page is served only for
/// the exact query, filter and offset that were cached.
abstract interface class SearchRepository {
  /// The page of [query] under [filter] that starts at [offset]. Only a
  /// single-kind filter pages; [SearchFilter.all] ignores [offset].
  Stream<Cached<SearchPage>> search(
    String query,
    SearchFilter filter, {
    int offset = 0,
  });

  /// Searches [query] under [filter] at [offset] again, whatever the age of
  /// the cached page.
  Future<void> refreshSearch(
    String query,
    SearchFilter filter, {
    int offset = 0,
  });
}
