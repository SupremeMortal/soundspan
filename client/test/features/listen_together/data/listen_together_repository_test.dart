// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/features/listen_together/data/listen_together_repository.dart';
import 'package:soundspan/features/listen_together/domain/group.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import '../../../helpers/fake_api.dart';

Track _track(String id, {bool playable = true}) => Track(
  meta: TrackMeta(
    title: 'Song $id',
    artist: 'Band',
    album: 'Record',
    durationSec: 200,
    artworkRef: 'art-$id',
  ),
  playbackId: playable ? PlaybackId('pb-$id') : null,
);

void main() {
  late FakeListenTogetherClient server;
  late ListenTogetherRepository repository;

  setUp(() {
    server = FakeApi().listenTogether;
    repository = ListenTogetherRepository(server);
  });

  test('create sends queueTracks as playbackId and metadata only, with the '
      'position and playing flag', () async {
    await repository.create(
      name: 'Friday',
      visibility: GroupVisibility.public,
      queueTracks: [_track('a'), _track('n', playable: false), _track('b')],
      currentTimeMs: 4200,
      isPlaying: true,
    );

    final body =
        jsonDecode(jsonEncode(server.creates.single)) as Map<String, Object?>;
    expect(
      body.keys,
      unorderedEquals([
        'name',
        'visibility',
        'queueTracks',
        'currentTimeMs',
        'isPlaying',
      ]),
    );
    expect(body['visibility'], 'public');
    expect(body['currentTimeMs'], 4200);
    expect(body['isPlaying'], isTrue);
    expect(body['queueTracks'], [
      {
        'playbackId': 'pb-a',
        'metadata': {
          'title': 'Song a',
          'artist': 'Band',
          'album': 'Record',
          'durationSec': 200,
          'artworkUrl': 'art-a',
        },
      },
      {
        'playbackId': 'pb-b',
        'metadata': {
          'title': 'Song b',
          'artist': 'Band',
          'album': 'Record',
          'durationSec': 200,
          'artworkUrl': 'art-b',
        },
      },
    ]);
  });

  test('create without a queue sends neither tracks nor a position', () async {
    await repository.create(visibility: GroupVisibility.private);

    final body =
        jsonDecode(jsonEncode(server.creates.single)) as Map<String, Object?>;
    expect(body, {'visibility': 'private'});
  });

  test('join maps the snapshot to a Group', () async {
    server.group = listenGroupJson(
      id: 'g7',
      name: 'Night',
      joinCode: 'XYZ789',
      groupType: 'collaborative',
      visibility: 'public',
      hostUserId: 'u1',
      memberIds: ['u1', 'u2'],
      queue: [('t1', 'pb-1'), ('t2', null)],
      currentIndex: 1,
      isPlaying: true,
      positionMs: 1234.0,
      serverTime: 99000,
      stateVersion: 12,
    );

    final group = await repository.join('XYZ789');

    expect(server.calls, ['join:XYZ789']);
    expect(group.id, 'g7');
    expect(group.name, 'Night');
    expect(group.joinCode, 'XYZ789');
    expect(group.type, GroupType.collaborative);
    expect(group.visibility, GroupVisibility.public);
    expect(group.hostUserId, 'u1');
    expect(group.members.map((m) => (m.userId, m.username, m.isConnected)), [
      ('u1', 'user u1', true),
      ('u2', 'user u2', true),
    ]);
    expect(group.playback.currentIndex, 1);
    expect(group.playback.isPlaying, isTrue);
    expect(group.playback.positionMs, 1234);
    expect(group.playback.serverTime, 99000);
    expect(group.playback.stateVersion, 12);
    final [first, second] = group.playback.queue;
    expect(first.playbackId, const PlaybackId('pb-1'));
    expect(
      first.meta,
      const TrackMeta(
        title: 'Song t1',
        artist: 'Band',
        album: 'Record',
        durationSec: 180,
        artworkRef: 'cover-1',
      ),
    );
    expect(first.libraryTrackId, 't1');
    expect(second.playbackId, isNull);
  });

  test('an unknown group type maps to unknown; canControl follows the '
      'type and host', () async {
    server.group = listenGroupJson(groupType: 'round-robin');
    expect((await repository.join('C')).type, GroupType.unknown);

    server.group = listenGroupJson(hostUserId: 'h');
    final hostFollower = await repository.join('C');
    expect(hostFollower.canControl('h'), isTrue);
    expect(hostFollower.canControl('m'), isFalse);

    server.group = listenGroupJson(groupType: 'collaborative', hostUserId: 'h');
    expect((await repository.join('C')).canControl('m'), isTrue);
  });

  test('discover maps each summary', () async {
    server.summaries.add({
      'id': 'g2',
      'name': 'Open',
      'joinCode': 'OPEN01',
      'groupType': 'host-follower',
      'visibility': 'public',
      'host': {'id': 'u9', 'username': 'dj'},
      'memberCount': 3,
      'isMember': false,
      'isPlaying': true,
      'currentTrack': null,
    });

    final [summary] = await repository.discover();

    expect(summary.id, 'g2');
    expect(summary.name, 'Open');
    expect(summary.joinCode, 'OPEN01');
    expect(summary.type, GroupType.hostFollower);
    expect(summary.visibility, GroupVisibility.public);
    expect(summary.hostUsername, 'dj');
    expect(summary.memberCount, 3);
    expect(summary.isMember, isFalse);
    expect(summary.isPlaying, isTrue);
  });

  test('mine is null outside a group and the group inside one', () async {
    expect(await repository.mine(), isNull);

    server.member = true;
    expect((await repository.mine())?.id, 'g1');
  });

  test('leave and end call the group operations; failures propagate', () async {
    await repository.leave('g1');
    await repository.end('g1');
    expect(server.calls, ['leave:g1', 'end:g1']);

    server.failures['end'] = const api.Forbidden(status: 403);
    expect(() => repository.end('g1'), throwsA(isA<api.Forbidden>()));
  });
}
