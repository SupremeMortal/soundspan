// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundspan/core/sync/data/plays_repository.dart';
import 'package:soundspan/core/sync/data/preference_remote_source.dart';
import 'package:soundspan/core/sync/data/sync_outbox_handlers.dart';
import 'package:soundspan/core/sync/outbox/outbox_handler.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/shared/data/playlist/playlist_outbox_handlers.dart';
import 'package:soundspan/shared/data/playlist/playlist_remote_source.dart';
import 'package:soundspan/shared/domain/playlist.dart';
import 'package:soundspan/shared/domain/track.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

class _MockLibraryClient extends Mock implements api.LibraryClient;

class _MockPlaybackClient extends Mock implements api.PlaybackClient;

class _MockPlaylistsClient extends Mock implements api.PlaylistsClient;

const _metadata = <String, Object?>{
  'title': 'Aster Tone',
  'artist': 'Contract Aurora',
  'album': 'First Light',
  'durationSec': 30,
};

const _written = api.PlaylistWriteResult(message: 'ok');

void main() {
  late _MockLibraryClient library;
  late _MockPlaybackClient playback;
  late _MockPlaylistsClient playlists;
  late OutboxHandlerRegistry registry;

  setUpAll(() {
    registerFallbackValue(
      const api.TrackPreferenceRequest(
        playbackId: '',
        signal: api.PreferenceSignal.clear,
      ),
    );
    registerFallbackValue(
      const api.AlbumPreferenceRequest(signal: api.PreferenceSignal.clear),
    );
    registerFallbackValue(const api.RecordPlayRequest(playbackId: ''));
    registerFallbackValue(const api.CreatePlaylistRequest(name: ''));
    registerFallbackValue(const api.UpdatePlaylistRequest());
    registerFallbackValue(
      const api.ReorderPlaylistItemsRequest(playbackIds: []),
    );
  });

  setUp(() {
    library = _MockLibraryClient();
    playback = _MockPlaybackClient();
    playlists = _MockPlaylistsClient();
    registry = OutboxHandlerRegistry([
      ...syncOutboxHandlers(
        PreferenceRemoteSource(library),
        PlaysRepository(playback),
        (
          store: () => throw StateError('no cache in this test'),
          library: () => throw StateError('no library in this test'),
        ),
      ),
      ...playlistOutboxHandlers(PlaylistRemoteSource(playlists)),
    ]);
  });

  test('every M1 op type has a handler', () {
    for (final type in [
      PreferenceOp.type,
      AlbumPreferenceOp.type,
      PlayOp.type,
      PlaylistCreateOp.type,
      PlaylistRenameOp.type,
      PlaylistDeleteOp.type,
      PlaylistAddOp.type,
      PlaylistRemoveOp.type,
      PlaylistReorderOp.type,
    ]) {
      expect(registry[type], isNotNull, reason: type);
    }
    expect(registry[EpisodeProgressOp.type], isNull);
  });

  test('a later entry for the same opType replaces an earlier one', () async {
    final second = SendOnlyOutboxHandler<PreferenceOp>((_) async => 'second');
    final replaced = OutboxHandlerRegistry([
      outboxHandlerEntry(
        PreferenceOp.type,
        SendOnlyOutboxHandler<PreferenceOp>((_) async => 'first'),
      ),
      outboxHandlerEntry(PreferenceOp.type, second),
    ]);

    const op = PreferenceOp(
      playbackId: 'p',
      signal: PreferenceSignal.clear,
      metadata: _metadata,
    );
    expect(await replaced[PreferenceOp.type]!.send(op), 'second');
  });

  test('the signal maps to the domain preference', () {
    expect(preferenceOfSignal(PreferenceSignal.thumbsUp), Preference.liked);
    expect(
      preferenceOfSignal(PreferenceSignal.thumbsDown),
      Preference.disliked,
    );
    expect(preferenceOfSignal(PreferenceSignal.clear), Preference.neutral);
  });

  test('preference sends the playbackId, signal and metadata', () async {
    when(() => library.setTrackPreference(body: any(named: 'body'))).thenAnswer(
      (_) async => api.TrackPreferenceResponse.fromJson({
        'playbackId': 'p-1',
        'trackId': 't-1',
        'signal': 'thumbs_up',
        'state': 'liked',
        'score': 1,
        'likedAt': '2026-01-01T00:00:00.000Z',
        'dislikedAt': null,
        'updatedAt': '2026-01-01T00:00:00.000Z',
      }),
    );

    final answer = await registry[PreferenceOp.type]!.send(
      const PreferenceOp(
        playbackId: 'p-1',
        signal: PreferenceSignal.thumbsUp,
        metadata: _metadata,
      ),
    );

    final body =
        verify(
              () => library.setTrackPreference(body: captureAny(named: 'body')),
            ).captured.single
            as api.TrackPreferenceRequest;
    expect(body.playbackId, 'p-1');
    expect(body.signal, api.PreferenceSignal.thumbsUp);
    expect(body.metadata?.title, 'Aster Tone');
    expect(answer, Preference.liked);
  });

  test('album preference sends the album id', () async {
    when(
      () => library.setAlbumPreference(
        id: any(named: 'id'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => api.AlbumPreferenceResponse.fromJson({
        'albumId': 'al-1',
        'trackCount': 10,
        'signal': 'thumbs_down',
        'state': 'disliked',
        'score': 0,
        'likedAt': null,
        'dislikedAt': null,
        'updatedAt': '2026-01-01T00:00:00.000Z',
      }),
    );

    await registry[AlbumPreferenceOp.type]!.send(
      const AlbumPreferenceOp(
        albumId: 'al-1',
        signal: PreferenceSignal.thumbsDown,
      ),
    );

    verify(
      () => library.setAlbumPreference(
        id: 'al-1',
        body: any(named: 'body'),
      ),
    ).called(1);
  });

  test('play sends playedAt and listenedMs', () async {
    when(() => playback.recordPlay(body: any(named: 'body'))).thenAnswer(
      (_) async => api.RecordPlayResponse200.fromJson({'recorded': false}),
    );
    final playedAt = DateTime.utc(2026, 1, 2, 3);

    await registry[PlayOp.type]!.send(
      PlayOp(
        sessionId: 's',
        playbackId: 'p-1',
        metadata: _metadata,
        playedAt: playedAt,
        listenedMs: 4000,
      ),
    );

    final body =
        verify(() => playback.recordPlay(body: captureAny(named: 'body')))
                .captured
                .single
            as api.RecordPlayRequest;
    expect(body.playbackId, 'p-1');
    expect(body.playedAt, playedAt);
    expect(body.listenedMs, 4000);
  });

  test('playlist create answers the created summary', () async {
    when(() => playlists.createPlaylist(body: any(named: 'body'))).thenAnswer(
      (_) async => api.PlaylistRecord.fromJson({
        'id': 'pl-1',
        'name': 'Road',
        'isPublic': false,
        'userId': 'u-1',
        'mixId': null,
        'spotifyPlaylistId': null,
        'spotifyPlaylistUrl': null,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      }),
    );

    final answer = await registry[PlaylistCreateOp.type]!.send(
      const PlaylistCreateOp(tempId: 'tmp_1', name: 'Road'),
    );

    expect(answer, isA<PlaylistSummary>().having((s) => s.id, 'id', 'pl-1'));
  });

  test('playlist rename, delete and reorder reach their endpoints', () async {
    when(
      () => playlists.updatePlaylist(
        id: any(named: 'id'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => api.PlaylistRecord.fromJson({
        'id': 'pl-1',
        'name': 'Night',
        'isPublic': false,
        'userId': 'u-1',
        'mixId': null,
        'spotifyPlaylistId': null,
        'spotifyPlaylistUrl': null,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      }),
    );
    when(() => playlists.deletePlaylist(id: any(named: 'id')))
        .thenAnswer((_) async => _written);
    when(
      () => playlists.reorderPlaylistItems(
        id: any(named: 'id'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => _written);
    when(
      () => playlists.removePlaylistItem(
        id: any(named: 'id'),
        playbackId: any(named: 'playbackId'),
      ),
    ).thenAnswer((_) async => _written);

    await registry[PlaylistRenameOp.type]!.send(
      const PlaylistRenameOp(playlistId: 'pl-1', name: 'Night'),
    );
    await registry[PlaylistReorderOp.type]!.send(
      const PlaylistReorderOp(playlistId: 'pl-1', playbackIds: ['b', 'a']),
    );
    await registry[PlaylistRemoveOp.type]!.send(
      const PlaylistRemoveOp(playlistId: 'pl-1', opUuid: 'u', playbackId: 'a'),
    );
    await registry[PlaylistDeleteOp.type]!.send(
      const PlaylistDeleteOp(playlistId: 'pl-1'),
    );

    verify(
      () => playlists.updatePlaylist(
        id: 'pl-1',
        body: any(named: 'body'),
      ),
    ).called(1);
    final reorder =
        verify(
              () => playlists.reorderPlaylistItems(
                id: 'pl-1',
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as api.ReorderPlaylistItemsRequest;
    expect(reorder.playbackIds, ['b', 'a']);
    verify(() => playlists.removePlaylistItem(id: 'pl-1', playbackId: 'a'))
        .called(1);
    verify(() => playlists.deletePlaylist(id: 'pl-1')).called(1);
  });

  test('send-only handlers do nothing on success or drop', () async {
    const handler = SendOnlyOutboxHandler<PlaylistDeleteOp>(_noSend);
    const op = PlaylistDeleteOp(playlistId: 'p');

    await handler.onSuccess(op, null);
    await handler.onDropped(op, OutboxDropReason.notFound);
  });
}

Future<Object?> _noSend(PlaylistDeleteOp op) async => null;
