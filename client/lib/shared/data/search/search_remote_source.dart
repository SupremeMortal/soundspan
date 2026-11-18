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

  /// One page of the library, the user's liked streaming items, their
  /// playlists and the catalogues, ranked together by relevance
  /// (`GET /search/unified`). The server honours [offset] only for a
  /// single-kind [filter].
  Future<SearchPage> search(
    String q, {
    SearchFilter filter = SearchFilter.all,
    int? limit,
    int? offset,
  }) async => searchPageFromWire(
    await _client.searchUnified(
      q: q,
      type: api.SearchUnifiedType.fromJson(filter.value),
      limit: limit,
      offset: offset,
    ),
  );
}
