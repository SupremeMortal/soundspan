// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundspan/shared/data/playlist/playlist_remote_source.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

class _MockPlaylistsClient extends Mock implements api.PlaylistsClient;

Map<String, Object?> _summaryJson(String id) => {
  'id': id,
  'name': 'Playlist $id',
  'trackCount': 2,
  'isOwner': false,
  'isPublic': true,
  'isHidden': false,
  'items': <Object?>[],
  'createdAt': '2024-01-01T00:00:00.000Z',
  'updatedAt': '2024-01-02T00:00:00.000Z',
  'user': {'username': 'other'},
  'userId': 'u-2',
};

void main() {
  late _MockPlaylistsClient client;
  late PlaylistRemoteSource source;

  setUp(() {
    client = _MockPlaylistsClient();
    source = PlaylistRemoteSource(client);
  });

  test(
    'playlists passes offset and limit through; the page has no total',
    () async {
      when(
        () => client.listPlaylists(
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => [
          api.PlaylistSummary.fromJson(_summaryJson('pl-1')),
          api.PlaylistSummary.fromJson(_summaryJson('pl-2')),
        ],
      );

      final page = await source.playlists(offset: 20, limit: 2);

      verify(() => client.listPlaylists(offset: 20, limit: 2)).called(1);
      expect([for (final p in page.items) p.id], ['pl-1', 'pl-2']);
      expect(page.offset, 20);
      expect(page.limit, 2);
      expect(page.total, isNull);
      expect(page.hasMore, isTrue);
    },
  );

  test('playlists without parameters uses the server defaults', () async {
    when(() => client.listPlaylists()).thenAnswer((_) async => []);

    final page = await source.playlists();

    verify(() => client.listPlaylists()).called(1);
    expect(page.offset, 0);
    expect(page.limit, PlaylistRemoteSource.serverDefaultLimit);
    expect(page.hasMore, isFalse);
  });

  test('playlist asks for the id and maps the detail', () async {
    when(() => client.getPlaylist(id: any(named: 'id'))).thenAnswer(
      (_) async => api.PlaylistDetail.fromJson({
        ..._summaryJson('pl-1'),
        'items': <Object?>[],
        'pendingCount': 0,
        'totalItemCount': 0,
        'truncated': false,
      }),
    );

    final detail = await source.playlist('pl-1');

    verify(() => client.getPlaylist(id: 'pl-1')).called(1);
    expect(detail.summary.name, 'Playlist pl-1');
    expect(detail.items, isEmpty);
  });

  test('an ApiException propagates unchanged', () async {
    const error = api.Forbidden(status: 403, serverMessage: 'Private');
    when(() => client.getPlaylist(id: any(named: 'id'))).thenThrow(error);

    await expectLater(source.playlist('pl-9'), throwsA(same(error)));
  });
}
