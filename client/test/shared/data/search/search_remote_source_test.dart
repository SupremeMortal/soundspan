// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundspan/shared/data/search/search_remote_source.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

class _MockSearchClient extends Mock implements api.SearchClient;

api.UnifiedSearchResponse _empty({bool hasMore = false}) =>
    api.UnifiedSearchResponse.fromJson({
      'items': <Object?>[],
      'hasMore': hasMore,
    });

void main() {
  late _MockSearchClient client;
  late SearchRemoteSource source;

  setUp(() {
    client = _MockSearchClient();
    source = SearchRemoteSource(client);
    registerFallbackValue(api.SearchUnifiedType.all);
  });

  test('search sends the filter as type with limit and offset', () async {
    when(
      () => client.searchUnified(
        q: any(named: 'q'),
        type: any(named: 'type'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => _empty(hasMore: true));

    final page = await source.search(
      'aster',
      filter: SearchFilter.songs,
      limit: 30,
      offset: 60,
    );

    verify(
      () => client.searchUnified(
        q: 'aster',
        type: api.SearchUnifiedType.tracks,
        limit: 30,
        offset: 60,
      ),
    ).called(1);
    expect(page, const SearchPage(hasMore: true));
  });

  test('every filter maps to its server type', () async {
    when(
      () => client.searchUnified(
        q: any(named: 'q'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) async => _empty());

    for (final filter in SearchFilter.values) {
      await source.search('x', filter: filter);
    }

    final types = verify(
      () => client.searchUnified(
        q: 'x',
        type: captureAny(named: 'type'),
      ),
    ).captured;
    expect(
      [for (final type in types) (type as api.SearchUnifiedType).toJson()],
      ['all', 'tracks', 'artists', 'albums', 'playlists', 'podcasts'],
    );
  });

  test('an ApiException propagates unchanged', () async {
    const error = api.InvalidRequest(status: 400, serverMessage: 'q too long');
    when(
      () => client.searchUnified(
        q: any(named: 'q'),
        type: any(named: 'type'),
      ),
    ).thenThrow(error);

    await expectLater(source.search('x'), throwsA(same(error)));
  });
}
