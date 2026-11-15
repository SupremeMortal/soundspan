// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

void main() {
  test('a discover search without a correction decodes aliasInfo null', () {
    final response = DiscoverSearchResponse.fromJson({
      'aliasInfo': null,
      'results': <Object?>[],
    });

    expect(response.aliasInfo, isNull);
  });

  test('the last liked page decodes nextCursor null', () {
    final pagination = LikedTracksPagination.fromJson({
      'hasMore': false,
      'limit': 2,
      'nextCursor': null,
    });

    expect(pagination.nextCursor, isNull);
  });

  test('a search track decodes peer null', () {
    final track = SearchTrack.fromJson({
      'id': 't-1',
      'title': 'Song',
      'duration': 3,
      'trackNo': 1,
      'albumId': 'al-1',
      'peer': null,
    });

    expect(track.peer, isNull);
  });
}
