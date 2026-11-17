// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/shared/domain/track.dart';

/// How a Listen Together group is controlled.
enum GroupType {
  /// Only the host controls playback; the others follow.
  hostFollower,

  /// Every member controls playback.
  collaborative,

  /// A type this client does not know.
  unknown,
}

/// Who can find a group.
enum GroupVisibility {
  /// Listed in discovery.
  public,

  /// Joined by code only.
  private,
}

/// One member of a group.
final class GroupMember {
  /// Creates a member.
  const new({
    required this.userId,
    required this.username,
    required this.isConnected,
  });

  /// The member's user id.
  final String userId;

  /// The member's username.
  final String username;

  /// Whether the member has a live socket connection.
  final bool isConnected;
}

/// The playback block of a group: its queue and where it is.
final class GroupPlayback {
  /// Creates a playback block.
  const new({
    required this.queue,
    required this.currentIndex,
    required this.isPlaying,
    required this.positionMs,
    required this.serverTime,
    required this.stateVersion,
  });

  /// The group's queue; a track without a playback id is not playable.
  final List<Track> queue;

  /// The index of the current entry in [queue].
  final int currentIndex;

  /// Whether the group is playing.
  final bool isPlaying;

  /// The position in the current entry when [serverTime] was read.
  final int positionMs;

  /// The server clock, in milliseconds, when this block was built.
  final int serverTime;

  /// Increases with every change of the group's playback.
  final int stateVersion;
}

/// A Listen Together group as the server describes it.
final class Group {
  /// Creates a group.
  const new({
    required this.id,
    required this.name,
    required this.joinCode,
    required this.type,
    required this.visibility,
    required this.hostUserId,
    required this.members,
    required this.playback,
  });

  /// The group id.
  final String id;

  /// The group name.
  final String name;

  /// The code other users join with.
  final String joinCode;

  /// How the group is controlled.
  final GroupType type;

  /// Who can find the group.
  final GroupVisibility visibility;

  /// The host's user id.
  final String hostUserId;

  /// The members, the host included.
  final List<GroupMember> members;

  /// The queue and where the group is in it.
  final GroupPlayback playback;

  /// Whether [userId] may control playback: false only for a member other
  /// than the host in a [GroupType.hostFollower] group.
  bool canControl(String userId) =>
      type != GroupType.hostFollower || userId == hostUserId;
}

/// A group as discovery lists it.
final class GroupSummary {
  /// Creates a summary.
  const new({
    required this.id,
    required this.name,
    required this.joinCode,
    required this.type,
    required this.visibility,
    required this.hostUsername,
    required this.memberCount,
    required this.isMember,
    required this.isPlaying,
  });

  /// The group id.
  final String id;

  /// The group name.
  final String name;

  /// The code to join with.
  final String joinCode;

  /// How the group is controlled.
  final GroupType type;

  /// Who can find the group.
  final GroupVisibility visibility;

  /// The host's username.
  final String hostUsername;

  /// How many members the group has.
  final int memberCount;

  /// Whether the user is a member.
  final bool isMember;

  /// Whether the group is playing.
  final bool isPlaying;
}
