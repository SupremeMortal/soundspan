// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';

const _meta = <String, Object?>{
  'title': 'Song',
  'artist': 'Artist',
  'album': 'Album',
  'durationSec': 215,
};

/// One op of every type, with the `opType` and `entityKey` of doc 07.
final _cases = <(OutboxOp, String, String)>[
  (
    const PreferenceOp(
      playbackId: 'pb:1',
      signal: PreferenceSignal.thumbsUp,
      metadata: _meta,
    ),
    'preference',
    'pref:pb:1',
  ),
  (
    const AlbumPreferenceOp(albumId: 'al1', signal: PreferenceSignal.clear),
    'albumPreference',
    'apref:al1',
  ),
  (
    PlayOp(
      sessionId: 's1',
      playbackId: 'pb:1',
      metadata: _meta,
      playedAt: DateTime.utc(2025, 3, 4, 5, 6, 7),
      listenedMs: 42000,
    ),
    'play',
    'play:s1',
  ),
  (
    const PlaylistCreateOp(tempId: 'tmp_abc', name: 'Mine', isPublic: true),
    'playlistCreate',
    'pl:tmp_abc',
  ),
  (
    const PlaylistRenameOp(playlistId: 'p1', name: 'Renamed'),
    'playlistRename',
    'plname:p1',
  ),
  (const PlaylistDeleteOp(playlistId: 'p1'), 'playlistDelete', 'pl:p1'),
  (
    const PlaylistAddOp(
      playlistId: 'p1',
      opUuid: 'u1',
      playbackId: 'pb:1',
      metadata: _meta,
    ),
    'playlistAdd',
    'plitem:p1:u1',
  ),
  (
    const PlaylistRemoveOp(playlistId: 'p1', opUuid: 'u1', playbackId: 'pb:1'),
    'playlistRemove',
    'plitem:p1:u1',
  ),
  (
    const PlaylistReorderOp(playlistId: 'p1', playbackIds: ['pb:2', 'pb:1']),
    'playlistReorder',
    'plorder:p1',
  ),
  (
    const EpisodeProgressOp(
      podcastId: 'pod1',
      episodeId: 'ep1',
      currentTime: 61.5,
      duration: 3600,
      isFinished: false,
    ),
    'episodeProgress',
    'ep:ep1',
  ),
  (
    const OfflineCompleteOp(
      deviceId: 'd1',
      playbackId: 'pb:1',
      quality: 'original',
      sizeBytes: 1234567,
    ),
    'offlineComplete',
    'oc:pb:1',
  ),
  (
    const OfflineDeleteOp(
      batchUuid: 'b1',
      deviceId: 'd1',
      playbackIds: ['pb:1', 'pb:2'],
    ),
    'offlineDelete',
    'od:b1',
  ),
];

void main() {
  test('every operation type of doc 07 is covered', () {
    expect(_cases.map((c) => c.$2).toSet(), hasLength(12));
  });

  for (final (op, opType, entityKey) in _cases) {
    group(opType, () {
      test('has the opType and entityKey of doc 07', () {
        expect(op.opType, opType);
        expect(op.entityKey, entityKey);
      });

      test('round-trips through toPayload and decode', () {
        final json = jsonEncode(op.toPayload());
        final decoded = OutboxOp.decode(opType, json);
        expect(decoded, op);
        expect(decoded.toPayload(), op.toPayload());
      });

      test('a payload missing a field throws FormatException', () {
        final payload = op.toPayload()..remove(op.toPayload().keys.first);
        expect(
          () => OutboxOp.decode(opType, jsonEncode(payload)),
          throwsFormatException,
        );
      });
    });
  }

  test('preference payload uses the wire signal and the metadata', () {
    expect(
      const PreferenceOp(
        playbackId: 'pb:1',
        signal: PreferenceSignal.thumbsDown,
        metadata: _meta,
      ).toPayload(),
      {'playbackId': 'pb:1', 'signal': 'thumbs_down', 'metadata': _meta},
    );
  });

  test('play payload carries playedAt as UTC ISO 8601', () {
    final op = PlayOp(
      sessionId: 's1',
      playbackId: 'pb:1',
      metadata: _meta,
      playedAt: DateTime.utc(2025, 3, 4, 5, 6, 7),
      listenedMs: 1,
    );
    expect(op.toPayload()['playedAt'], '2025-03-04T05:06:07.000Z');
    final local = PlayOp(
      sessionId: 's1',
      playbackId: 'pb:1',
      metadata: _meta,
      playedAt: DateTime.utc(2025).toLocal(),
      listenedMs: 1,
    );
    expect(local.toPayload()['playedAt'], '2025-01-01T00:00:00.000Z');
  });

  test('playlistCreate without isPublic omits it and decodes as null', () {
    const op = PlaylistCreateOp(tempId: 'tmp_x', name: 'N');
    expect(op.toPayload(), {'tempId': 'tmp_x', 'name': 'N'});
    expect(OutboxOp.decode('playlistCreate', jsonEncode(op.toPayload())), op);
  });

  test('an unknown opType throws FormatException', () {
    expect(() => OutboxOp.decode('bogus', '{}'), throwsFormatException);
  });

  test('malformed payloads throw FormatException', () {
    for (final json in ['not json', '[]', '"x"', 'null']) {
      expect(
        () => OutboxOp.decode('playlistDelete', json),
        throwsFormatException,
        reason: json,
      );
    }
    expect(
      () => OutboxOp.decode('playlistDelete', '{"playlistId": 3}'),
      throwsFormatException,
    );
    expect(
      () => OutboxOp.decode(
        'preference',
        '{"playbackId":"p","signal":"love","metadata":{}}',
      ),
      throwsFormatException,
    );
    expect(
      () => OutboxOp.decode(
        'play',
        '{"sessionId":"s","playbackId":"p","metadata":{},'
            '"playedAt":"yesterday","listenedMs":1}',
      ),
      throwsFormatException,
    );
    expect(
      () => OutboxOp.decode(
        'playlistReorder',
        '{"playlistId":"p","playbackIds":["a",1]}',
      ),
      throwsFormatException,
    );
  });
}
