// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundspan/shared/data/playlist/playlist_remote_source.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

class _MockPlaylistsClient extends Mock implements api.PlaylistsClient;

const _meta = TrackMeta(
  title: 'Aster Tone',
  artist: 'Contract Aurora',
  album: 'First Light',
  durationSec: 30,
  artworkRef: 'cover-1',
);

api.PlaylistRecord _record({String name = 'Road', bool isPublic = false}) =>
    api.PlaylistRecord.fromJson({
      'id': 'pl-1',
      'name': name,
      'isPublic': isPublic,
      'userId': 'u-1',
      'mixId': null,
      'spotifyPlaylistId': null,
      'spotifyPlaylistUrl': null,
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': '2026-01-01T00:00:00.000Z',
    });

Map<String, Object?> _itemJson(String id) => {
  'id': id,
  'playlistId': 'pl-1',
  'sort': 3,
  'type': 'track',
  'playback': {'isPlayable': true, 'reason': null, 'message': null},
  'track': {
    'id': 't-1',
    'title': 'Aster Tone',
    'duration': 30,
    'trackNo': 1,
    'source': 'local',
    'albumId': 'al-1',
    'artistId': 'ar-1',
    'playbackId': 'p-1',
    'album': {'id': 'al-1', 'title': 'First Light', 'coverArt': 'cover-1'},
    'artist': {'id': 'ar-1', 'name': 'Contract Aurora'},
  },
};

const _written = api.PlaylistWriteResult(message: 'ok');

void main() {
  late _MockPlaylistsClient client;
  late PlaylistRemoteSource source;

  setUpAll(() {
    registerFallbackValue(const api.CreatePlaylistRequest(name: ''));
    registerFallbackValue(const api.UpdatePlaylistRequest());
    registerFallbackValue(const api.AddPlaylistItemRequest(playbackId: ''));
    registerFallbackValue(
      const api.ReorderPlaylistItemsRequest(playbackIds: []),
    );
  });

  setUp(() {
    client = _MockPlaylistsClient();
    source = PlaylistRemoteSource(client);
  });

  test(
    'create sends name and isPublic and answers an empty owned playlist',
    () async {
      when(() => client.createPlaylist(body: any(named: 'body')))
          .thenAnswer((_) async => _record(isPublic: true));

      final playlist = await source.create('Road', isPublic: true);

      final body =
          verify(() => client.createPlaylist(body: captureAny(named: 'body')))
                  .captured
                  .single
              as api.CreatePlaylistRequest;
      expect(body.toJson(), {'name': 'Road', 'isPublic': true});
      expect(
        playlist,
        const PlaylistSummary(
          id: 'pl-1',
          name: 'Road',
          trackCount: 0,
          isOwner: true,
          isPublic: true,
        ),
      );
    },
  );

  test('create without isPublic leaves the server default', () async {
    when(() => client.createPlaylist(body: any(named: 'body')))
        .thenAnswer((_) async => _record());

    await source.create('Road');

    final body =
        verify(() => client.createPlaylist(body: captureAny(named: 'body')))
                .captured
                .single
            as api.CreatePlaylistRequest;
    expect(body.name, 'Road');
    expect(body.isPublic, isFalse);
  });

  test('update sends only the fields given to the playlist id', () async {
    when(
      () => client.updatePlaylist(
        id: any(named: 'id'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => _record(name: 'Night'));

    await source.update('pl-1', name: 'Night');

    final captured = verify(
      () => client.updatePlaylist(
        id: captureAny(named: 'id'),
        body: captureAny(named: 'body'),
      ),
    ).captured;
    expect(captured[0], 'pl-1');
    expect((captured[1] as api.UpdatePlaylistRequest).toJson(), {
      'name': 'Night',
    });
  });

  test('update can change visibility alone', () async {
    when(
      () => client.updatePlaylist(
        id: any(named: 'id'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => _record(isPublic: true));

    await source.update('pl-1', isPublic: true);

    final body =
        verify(
              () => client.updatePlaylist(
                id: 'pl-1',
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as api.UpdatePlaylistRequest;
    expect(body.toJson(), {'isPublic': true});
  });

  test('delete deletes the playlist id', () async {
    when(() => client.deletePlaylist(id: any(named: 'id')))
        .thenAnswer((_) async => _written);

    await source.delete('pl-1');

    verify(() => client.deletePlaylist(id: 'pl-1')).called(1);
  });

  test(
    'addItem sends the playbackId with metadata and maps the item',
    () async {
      when(
        () => client.addPlaylistItem(
          id: any(named: 'id'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => api.AddPlaylistItemResponse200.fromJson(_itemJson('i-1')),
      );

      final item = await source.addItem(
        'pl-1',
        const PlaybackId('p-1'),
        meta: _meta,
      );

      final captured = verify(
        () => client.addPlaylistItem(
          id: captureAny(named: 'id'),
          body: captureAny(named: 'body'),
        ),
      ).captured;
      expect(captured[0], 'pl-1');
      expect((captured[1] as api.AddPlaylistItemRequest).toJson(), {
        'playbackId': 'p-1',
        'metadata': {
          'title': 'Aster Tone',
          'artist': 'Contract Aurora',
          'album': 'First Light',
          'durationSec': 30,
          'artworkUrl': 'cover-1',
        },
      });
      expect(item.id, 'i-1');
      expect(item.track.playbackId, const PlaybackId('p-1'));
    },
  );

  test(
    'addItem of a track already in the playlist answers that item',
    () async {
      when(
        () => client.addPlaylistItem(
          id: any(named: 'id'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => api.AddPlaylistItemResponse200.fromJson({
          'message': 'Track already in playlist',
          'duplicated': true,
          'item': _itemJson('i-7'),
        }),
      );

      final item = await source.addItem(
        'pl-1',
        const PlaybackId('p-1'),
        meta: _meta,
      );

      expect(item.id, 'i-7');
    },
  );

  test('addItem answering an item without a track is an InvalidResponse '
      'naming track', () async {
    when(
      () => client.addPlaylistItem(
        id: any(named: 'id'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => api.AddPlaylistItemResponse200.fromJson({
        ..._itemJson('i-8'),
        'track': null,
      }),
    );

    await expectLater(
      source.addItem('pl-1', const PlaybackId('p-1'), meta: _meta),
      throwsA(
        isA<api.InvalidResponse>()
            .having((e) => e.operationId, 'operationId', 'addPlaylistItem')
            .having((e) => e.key, 'key', 'track'),
      ),
    );
  });

  test(
    'removeItem sends the playbackId as one percent-encoded segment',
    () async {
      when(
        () => client.removePlaylistItem(
          id: any(named: 'id'),
          playbackId: any(named: 'playbackId'),
        ),
      ).thenAnswer((_) async => _written);

      await source.removeItem('pl-1', const PlaybackId('t.a/b c%'));

      verify(
        () =>
            client.removePlaylistItem(id: 'pl-1', playbackId: 't.a%2Fb%20c%25'),
      ).called(1);
    },
  );

  test('reorder sends the full order as playbackIds', () async {
    when(
      () => client.reorderPlaylistItems(
        id: any(named: 'id'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => _written);

    await source.reorder('pl-1', const [
      PlaybackId('p-3'),
      PlaybackId('p-1'),
      PlaybackId('p-2'),
    ]);

    final body =
        verify(
              () => client.reorderPlaylistItems(
                id: 'pl-1',
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as api.ReorderPlaylistItemsRequest;
    expect(body.toJson(), {
      'playbackIds': ['p-3', 'p-1', 'p-2'],
    });
  });

  test('NotFound propagates unchanged', () async {
    const error = api.NotFound(status: 404);
    when(() => client.deletePlaylist(id: any(named: 'id'))).thenThrow(error);

    await expectLater(source.delete('pl-9'), throwsA(same(error)));
  });

  test('Forbidden propagates unchanged', () async {
    const error = api.Forbidden(status: 403);
    when(
      () => client.updatePlaylist(
        id: any(named: 'id'),
        body: any(named: 'body'),
      ),
    ).thenThrow(error);

    await expectLater(
      source.update('pl-9', name: 'Mine'),
      throwsA(same(error)),
    );
  });
}
