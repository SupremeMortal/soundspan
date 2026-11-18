// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/realtime/presence_models.dart';
import 'package:soundspan/core/realtime/presence_repository.dart';
import 'package:soundspan/shared/domain/track.dart';

import '../../helpers/fake_api.dart';

void main() {
  late FakeSocialClient server;
  late PresenceRepository repository;

  setUp(() {
    server = FakeApi().social;
    repository = PresenceRepository(server, currentUserId: 'me');
  });

  test('heartbeat posts once', () async {
    await repository.heartbeat();

    expect(server.calls, ['heartbeat']);
  });

  test('online maps statuses and now playing, and leaves out the current '
      'user', () async {
    server.users.addAll([
      onlineUserJson(
        'a',
        displayName: 'Ana',
        status: 'playing',
        track: onlineTrackJson('Song A', artist: 'Band A'),
      ),
      onlineUserJson('me', status: 'playing'),
      onlineUserJson('b', displayName: 'Ben', status: 'paused'),
      onlineUserJson('c', displayName: 'Cy'),
      onlineUserJson('d', displayName: 'Dee', status: 'away'),
    ]);

    final roster = await repository.online();

    expect(roster.users, [
      const OnlineUser(
        id: 'a',
        displayName: 'Ana',
        status: PresenceStatus.playing,
        nowPlaying: TrackMeta(
          title: 'Song A',
          artist: 'Band A',
          album: 'Record',
          durationSec: 200,
          artworkRef: 'art-Song A',
        ),
      ),
      const OnlineUser(
        id: 'b',
        displayName: 'Ben',
        status: PresenceStatus.paused,
      ),
      const OnlineUser(id: 'c', displayName: 'Cy', status: PresenceStatus.idle),
      const OnlineUser(
        id: 'd',
        displayName: 'Dee',
        status: PresenceStatus.idle,
      ),
    ]);
    expect(roster.peers, isEmpty);
  });

  test('online maps peers of connected servers and leaves out entries of '
      'another shape', () async {
    server.peers = [
      {
        'peerId': 'p1',
        'peerName': 'North',
        'fetchedAt': '2025-01-01T00:00:00.000Z',
        'users': [
          {
            'username': 'nia',
            'displayName': 'Nia',
            'status': 'playing',
            'track': {'title': 'Far', 'artist': 'Band', 'album': 'Away'},
            'updatedAt': '2025-01-01T00:00:00.000Z',
          },
          {
            'username': 'olu',
            'status': 'idle',
            'updatedAt': '2025-01-01T00:00:00.000Z',
          },
          {'status': 'idle'},
        ],
      },
      {'peerId': 'p2'},
      'garbage',
    ];

    final roster = await repository.online();

    expect(roster.peers, [
      const OnlinePeerUser(
        peerName: 'North',
        displayName: 'Nia',
        status: PresenceStatus.playing,
        nowPlaying: TrackMeta(
          title: 'Far',
          artist: 'Band',
          album: 'Away',
          durationSec: 0,
        ),
      ),
      const OnlinePeerUser(
        peerName: 'North',
        displayName: 'olu',
        status: PresenceStatus.idle,
      ),
    ]);
  });
}
