// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/realtime/socket_models.dart' as wire;
import 'package:soundspan/features/listen_together/data/listen_together_repository.dart';
import 'package:soundspan/features/listen_together/domain/group.dart';
import 'package:soundspan/shared/domain/domain.dart';

/// The queue entry id of the group queue entry at [index] with
/// [playbackId]: the same index and playback id give the same id, so the
/// playback controller keeps an unchanged current entry playing across
/// queue updates (doc 08, Applying State).
String groupQueueItemId(int index, String? playbackId) =>
    'lt-$index-${playbackId ?? 'none'}';

/// The track of a socket queue entry; without a playback id it is not
/// playable.
Track trackOfEntry(wire.SocketQueueEntry entry) => Track(
  meta: TrackMeta(
    title: entry.title,
    artist: entry.artist.name,
    album: entry.album.title,
    durationSec: entry.duration.round(),
    artworkRef: entry.album.coverArt,
  ),
  playbackId: switch (entry.playbackId) {
    final String value => PlaybackId(value),
    null => null,
  },
);

/// The play queue entries of a group queue, each a single track keyed by
/// [groupQueueItemId].
List<QueueItem> queueItemsOf(List<wire.SocketQueueEntry> entries) => [
  for (final (index, entry) in entries.indexed)
    QueueItem.track(
      queueItemId: groupQueueItemId(index, entry.playbackId),
      track: trackOfEntry(entry),
      context: const QueueContext(kind: QueueContextKind.single),
    ),
];

/// The domain group of a `group:state` snapshot.
Group groupOfSocket(wire.GroupSnapshot snapshot) => Group(
  id: snapshot.id,
  name: snapshot.name,
  joinCode: snapshot.joinCode,
  type: switch (snapshot.groupType) {
    wire.GroupType.hostFollower => GroupType.hostFollower,
    wire.GroupType.collaborative => GroupType.collaborative,
    wire.GroupType.unknown => GroupType.unknown,
  },
  visibility: groupVisibilityOf(snapshot.visibility),
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
    queue: [for (final entry in snapshot.playback.queue) trackOfEntry(entry)],
    currentIndex: snapshot.playback.currentIndex,
    isPlaying: snapshot.playback.isPlaying,
    positionMs: snapshot.playback.positionMs,
    serverTime: snapshot.playback.serverTime,
    stateVersion: snapshot.playback.stateVersion,
  ),
);

/// [group] with the member event [event] applied: a member added, removed
/// (and the host handed over when the event names a new one), or its
/// connection flag changed.
Group groupWithMemberEvent(Group group, wire.MemberEvent event) {
  final members = switch (event) {
    wire.MemberJoined(:final userId, :final username) => [
      for (final member in group.members)
        if (member.userId != userId) member,
      GroupMember(userId: userId, username: username, isConnected: true),
    ],
    wire.MemberLeft(:final userId) => [
      for (final member in group.members)
        if (member.userId != userId) member,
    ],
    wire.MemberPresence(:final userId, :final isConnected) => [
      for (final member in group.members)
        if (member.userId == userId)
          GroupMember(
            userId: member.userId,
            username: member.username,
            isConnected: isConnected,
          )
        else
          member,
    ],
  };
  final host = switch (event) {
    wire.MemberLeft(:final newHostUserId?) => newHostUserId,
    _ => group.hostUserId,
  };
  return Group(
    id: group.id,
    name: group.name,
    joinCode: group.joinCode,
    type: group.type,
    visibility: group.visibility,
    hostUserId: host,
    members: members,
    playback: group.playback,
  );
}
