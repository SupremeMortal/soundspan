// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/shared/data/search/search_mappers.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// The network half of search: calls the generated `SearchClient` and
/// returns domain values. `ApiException` propagates unchanged.
class SearchRemoteSource {
  /// Creates a source over the generated search client.
  new(this._client);

  final api.SearchClient _client;

  /// Searches the library and the user's liked streaming items
  /// (`GET /search`).
  Future<LibrarySearchResults> library(
    String q, {
    LibrarySearchType? type,
    int? limit,
    int? offset,
  }) async => librarySearchResultsFromWire(
    await _client.search(
      q: q,
      type: type == null ? null : api.SearchType.fromJson(type.value),
      limit: limit,
      offset: offset,
    ),
  );

  /// Searches catalogues outside the library (`GET /search/discover`).
  Future<DiscoverResults> discover(
    String q, {
    DiscoverSearchType? type,
    int? limit,
  }) async => discoverResultsFromWire(
    await _client.searchDiscover(
      q: q,
      type: type == null ? null : api.SearchDiscoverType.fromJson(type.value),
      limit: limit,
    ),
  );
}
