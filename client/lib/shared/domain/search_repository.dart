// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/shared/domain/cached.dart';
import 'package:soundspan/shared/domain/search_results.dart';

/// Search, served from the cache and refreshed in the background (doc 05,
/// Read Policy: Stale-While-Revalidate). Offline, a result is served only
/// for the exact query and scope that were cached.
abstract interface class SearchRepository {
  /// The results of [query] over [scope].
  Stream<Cached<SearchResults>> search(String query, SearchScope scope);

  /// Searches [query] over [scope] again, whatever the age of the cached
  /// results.
  Future<void> refreshSearch(String query, SearchScope scope);
}
