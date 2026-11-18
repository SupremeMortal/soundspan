// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundspan/shared/data/search/search_remote_source.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

class _MockSearchClient extends Mock implements api.SearchClient;

api.SearchResponse _empty() => api.SearchResponse.fromJson({
  'artists': <Object?>[],
  'albums': <Object?>[],
  'tracks': <Object?>[],
  'podcasts': <Object?>[],
  'episodes': <Object?>[],
  'remoteTracks': <Object?>[],
  'remoteAlbums': <Object?>[],
});

void main() {
  late _MockSearchClient client;
  late SearchRemoteSource source;

  setUp(() {
    client = _MockSearchClient();
    source = SearchRemoteSource(client);
  });

  test('library passes its parameters through', () async {
    when(
      () => client.search(
        q: any(named: 'q'),
        type: any(named: 'type'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => _empty());

    final results = await source.library(
      'aster',
      type: LibrarySearchType.tracks,
      limit: 5,
      offset: 10,
    );

    verify(
      () => client.search(
        q: 'aster',
        type: api.SearchType.tracks,
        limit: 5,
        offset: 10,
      ),
    ).called(1);
    expect(results, const LibrarySearchResults());
  });

  test('discover passes its parameters through', () async {
    when(
      () => client.searchDiscover(
        q: any(named: 'q'),
        type: any(named: 'type'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => api.DiscoverSearchResponse.fromJson({
        'aliasInfo': null,
        'results': <Object?>[],
      }),
    );

    final results = await source.discover(
      'aster',
      type: DiscoverSearchType.all,
      limit: 7,
    );

    verify(
      () => client.searchDiscover(
        q: 'aster',
        type: api.SearchDiscoverType.all,
        limit: 7,
      ),
    ).called(1);
    expect(results, const DiscoverResults());
  });

  test('an ApiException propagates unchanged', () async {
    const error = api.InvalidRequest(status: 400, serverMessage: 'q too long');
    when(() => client.search(q: any(named: 'q'))).thenThrow(error);

    await expectLater(source.library('x'), throwsA(same(error)));
  });
}
