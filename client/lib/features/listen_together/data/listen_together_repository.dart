// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/sync/data/playback_metadata.dart';
import 'package:soundspan/features/listen_together/domain/group.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan/shared/domain/track.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// The Listen Together REST operations over the generated
/// `ListenTogetherClient` (doc 03, "Home, discovery, social"; doc 08,
/// Joining and Leaving), mapped to the domain [Group].
///
/// Initial queue tracks are sent as `{ playbackId, metadata }` only; the
/// legacy `queueTrackIds` and `currentTrackId` fields are never sent.
class ListenTogetherRepository {
  /// A repository over [_client].
  new(this._client);

  final api.ListenTogetherClient _client;

  /// `POST /listen-together`: creates a group hosted by the user, with
  /// [queueTracks] (those with a playback id) as its queue, the first being
  /// current, at [currentTimeMs] and [isPlaying].
  Future<Group> create({
    required GroupVisibility visibility,
    String? name,
    List<Track> queueTracks = const [],
    int? currentTimeMs,
    bool? isPlaying,
  }) async {
    final inputs = [
      for (final track in queueTracks)
        if (track.playbackId case final playbackId?)
          api.ListenQueueTrackInput(
            playbackId: playbackId.value,
            metadata: playbackMetadataFromMeta(track.meta),
          ),
    ];
    final snapshot = await _client.createListenGroup(
      body: api.CreateListenGroupRequest(
        name: name,
        visibility: switch (visibility) {
          GroupVisibility.public =>
            api.CreateListenGroupRequestVisibility.public,
          GroupVisibility.private =>
            api.CreateListenGroupRequestVisibility.private,
        },
        queueTracks: inputs.isEmpty ? null : inputs,
        currentTimeMs: inputs.isEmpty ? null : currentTimeMs,
        isPlaying: inputs.isEmpty ? null : isPlaying,
      ),
    );
    return groupOf(_required(snapshot, 'create'));
  }

  /// `POST /listen-together/join`: joins the group with [joinCode].
  Future<Group> join(String joinCode) async => groupOf(
    _required(
      await _client.joinListenGroup(
        body: api.JoinListenGroupRequest(joinCode: joinCode),
      ),
      'join',
    ),
  );

  /// `GET /listen-together/discover`: active public groups.
  Future<List<GroupSummary>> discover() async => [
    for (final summary in await _client.discoverListenGroups())
      groupSummaryOf(summary),
  ];

  /// `GET /listen-together/mine`: the group the user is in, if any.
  Future<Group?> mine() async {
    final snapshot = await _client.getMyListenGroup();
    return snapshot == null ? null : groupOf(snapshot);
  }

  /// `POST /listen-together/:id/leave`.
  Future<void> leave(String groupId) async {
    await _client.leaveListenGroup(groupId: groupId);
  }

  /// `POST /listen-together/:id/end`: ends the group for every member.
  Future<void> end(String groupId) async {
    await _client.endListenGroup(groupId: groupId);
  }

  static api.ListenGroupSnapshot _required(
    api.ListenGroupSnapshot? snapshot,
    String operation,
  ) =>
      snapshot ??
      (throw FormatException('Listen Together $operation answered null'));
}

/// The domain group of [snapshot].
Group groupOf(api.ListenGroupSnapshot snapshot) => Group(
  id: snapshot.id,
  name: snapshot.name,
  joinCode: snapshot.joinCode,
  type: groupTypeOf(snapshot.groupType.toJson()),
  visibility: groupVisibilityOf(snapshot.visibility.toJson()),
  hostUserId: snapshot.hostUserId,
  members: [
    for (final member in snapshot.members)
      GroupMember(
        userId: member.userId,
        username: member.username,
        isConnected: member.isConnected,
      ),
  ],
  playback: GroupPlayback(
    queue: [for (final item in snapshot.playback.queue) groupTrackOf(item)],
    currentIndex: snapshot.playback.currentIndex,
    isPlaying: snapshot.playback.isPlaying,
    positionMs: snapshot.playback.positionMs.round(),
    serverTime: snapshot.playback.serverTime,
    stateVersion: snapshot.playback.stateVersion,
  ),
);

/// The domain summary of [summary].
GroupSummary groupSummaryOf(api.ListenGroupSummary summary) => GroupSummary(
  id: summary.id,
  name: summary.name,
  joinCode: summary.joinCode,
  type: groupTypeOf(summary.groupType.toJson()),
  visibility: groupVisibilityOf(summary.visibility.toJson()),
  hostUsername: summary.host.username,
  memberCount: summary.memberCount,
  isMember: summary.isMember,
  isPlaying: summary.isPlaying,
);

/// The track of a group queue entry; without a playback id it is not
/// playable.
Track groupTrackOf(api.ListenQueueItem item) => Track(
  meta: TrackMeta(
    title: item.title,
    artist: item.artist.name,
    album: item.album.title,
    durationSec: item.duration,
    artworkRef: item.album.coverArt,
  ),
  playbackId: switch (item.playbackId) {
    final String value => PlaybackId(value),
    null => null,
  },
  libraryTrackId: item.id,
);

/// The [GroupType] of the wire string [wire].
GroupType groupTypeOf(String wire) => switch (wire) {
  'host-follower' => GroupType.hostFollower,
  'collaborative' => GroupType.collaborative,
  _ => GroupType.unknown,
};

/// The [GroupVisibility] of the wire string [wire]; anything but `public`
/// is private.
GroupVisibility groupVisibilityOf(String wire) =>
    wire == 'public' ? GroupVisibility.public : GroupVisibility.private;
