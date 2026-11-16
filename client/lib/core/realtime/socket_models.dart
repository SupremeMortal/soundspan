// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The payloads of the `/listen-together` socket (doc 08, Typed Events).
///
/// Socket events are not part of the OpenAPI document, so these models are
/// written by hand from the backend's emitters. Unknown keys are ignored and
/// unknown enum strings decode to an `unknown` value. Only the fields the
/// client uses are declared: a queue entry has no per-source keys.
///
/// This file imports nothing from Flutter, so the contract suite can use it.
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:soundspan_api/soundspan_api.dart' show ListenQueueTrackInput;

part 'socket_models.freezed.dart';
part 'socket_models.g.dart';

/// A track to add to a group's queue: its `playbackId` and, optionally, the
/// display metadata the server needs to create a remote track row.
typedef PlaybackRef = ListenQueueTrackInput;

/// A group's playback state as the server reports it.
enum GroupSyncState {
  /// Nothing is playing.
  idle,

  /// The members are loading the current item.
  waiting,

  /// The group is playing.
  playing,

  /// The group is paused.
  paused,

  /// A state this client does not know.
  unknown,
}

/// How a group is controlled.
enum GroupType {
  /// Only the host controls playback.
  @JsonValue('host-follower')
  hostFollower,

  /// Every member controls playback.
  collaborative,

  /// A type this client does not know.
  unknown,
}

/// A playback command of the `playback` event.
enum PlaybackAction {
  /// Start playing.
  play('play'),

  /// Pause.
  pause('pause'),

  /// Skip to the next item.
  next('next'),

  /// Go back to the previous item.
  previous('previous'),

  /// Seek to `positionMs`.
  seek('seek'),

  /// Play the item at `index`.
  setTrack('set-track');

  new(this.wireName);

  /// The `action` value the server expects.
  final String wireName;
}

/// A queue command of the `queue` event.
enum QueueAction {
  /// Append `tracks`.
  add('add'),

  /// Insert `tracks` after the current item.
  insertNext('insert-next'),

  /// Remove the item at `index`.
  remove('remove'),

  /// Move the item at `fromIndex` to `toIndex`.
  reorder('reorder'),

  /// Empty the queue.
  clear('clear');

  new(this.wireName);

  /// The `action` value the server expects.
  final String wireName;
}

/// The artist of a [SocketQueueEntry].
@freezed
abstract class SocketQueueArtist with _$SocketQueueArtist {
  /// Creates an artist reference.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory SocketQueueArtist({
    /// The server's artist id.
    required String id,

    /// The artist name.
    required String name,
  }) = _SocketQueueArtist;

  /// Decodes the `artist` object of a queue entry.
  factory fromJson(Map<String, Object?> json) =>
      _$SocketQueueArtistFromJson(json);
}

/// The album of a [SocketQueueEntry].
@freezed
abstract class SocketQueueAlbum with _$SocketQueueAlbum {
  /// Creates an album reference.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory SocketQueueAlbum({
    /// The server's album id.
    required String id,

    /// The album title.
    required String title,

    /// The value to pass to the cover-art endpoint, if there is art.
    String? coverArt,

    /// The album's integrated loudness, in LUFS.
    double? albumLoudnessLufs,

    /// The album's true peak, in dBTP.
    double? albumTruePeakDb,
  }) = _SocketQueueAlbum;

  /// Decodes the `album` object of a queue entry.
  factory fromJson(Map<String, Object?> json) =>
      _$SocketQueueAlbumFromJson(json);
}

/// One entry of a group's queue.
@freezed
abstract class SocketQueueEntry with _$SocketQueueEntry {
  /// Creates a queue entry.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory SocketQueueEntry({
    /// The track title.
    required String title,

    /// The duration, in seconds.
    required double duration,

    /// The artist.
    required SocketQueueArtist artist,

    /// The album.
    required SocketQueueAlbum album,

    /// The opaque id to stream the track with; null when the server cannot
    /// play it.
    String? playbackId,

    /// The track's integrated loudness, in LUFS.
    double? loudnessLufs,

    /// The track's true peak, in dBTP.
    double? truePeakDb,
  }) = _SocketQueueEntry;

  const new _();

  /// Decodes one entry of a `queue` array.
  factory fromJson(Map<String, Object?> json) =>
      _$SocketQueueEntryFromJson(json);

  /// Whether the server can stream this entry: it has a `playbackId`.
  bool get isPlayable => playbackId != null;
}

/// The `playback` object of a [GroupSnapshot].
@freezed
abstract class GroupPlayback with _$GroupPlayback {
  /// Creates a playback state.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory GroupPlayback({
    /// The group's queue.
    required List<SocketQueueEntry> queue,

    /// The index of the current item.
    required int currentIndex,

    /// Whether the group is playing.
    required bool isPlaying,

    /// The position at [serverTime], in milliseconds.
    required int positionMs,

    /// The server's clock when the state was taken, in milliseconds.
    required int serverTime,

    /// Grows with every change of the playback state.
    required int stateVersion,
  }) = _GroupPlayback;

  /// Decodes the `playback` object of a snapshot.
  factory fromJson(Map<String, Object?> json) => _$GroupPlaybackFromJson(json);
}

/// One member of a [GroupSnapshot].
@freezed
abstract class GroupMemberInfo with _$GroupMemberInfo {
  /// Creates a member.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory GroupMemberInfo({
    /// The member's user id.
    required String userId,

    /// The member's username.
    required String username,

    /// Whether the member hosts the group.
    required bool isHost,

    /// When the member joined.
    required DateTime joinedAt,

    /// Whether the member has a socket in the group.
    required bool isConnected,
  }) = _GroupMemberInfo;

  /// Decodes one entry of a snapshot's `members`.
  factory fromJson(Map<String, Object?> json) =>
      _$GroupMemberInfoFromJson(json);
}

/// `group:state`: the full state of a group.
@freezed
abstract class GroupSnapshot with _$GroupSnapshot {
  /// Creates a snapshot.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory GroupSnapshot({
    /// The group id.
    required String id,

    /// The group name.
    required String name,

    /// The code other users join with.
    required String joinCode,

    /// How the group is controlled.
    @JsonKey(unknownEnumValue: GroupType.unknown) required GroupType groupType,

    /// `public` or `private`.
    required String visibility,

    /// Whether the group has not ended.
    required bool isActive,

    /// The host's user id.
    required String hostUserId,

    /// The group's playback state.
    @JsonKey(unknownEnumValue: GroupSyncState.unknown)
    required GroupSyncState syncState,

    /// The queue and position.
    required GroupPlayback playback,

    /// The members.
    required List<GroupMemberInfo> members,
  }) = _GroupSnapshot;

  /// Decodes a `group:state` payload.
  factory fromJson(Map<String, Object?> json) => _$GroupSnapshotFromJson(json);
}

/// `group:playback-delta`: a change of play state or position.
@freezed
abstract class PlaybackDelta with _$PlaybackDelta {
  /// Creates a delta.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory PlaybackDelta({
    /// Whether the group is playing.
    required bool isPlaying,

    /// The position at [serverTime], in milliseconds.
    required int positionMs,

    /// The server's clock when the change was made, in milliseconds.
    required int serverTime,

    /// Grows with every change of the playback state.
    required int stateVersion,

    /// The index of the current item.
    required int currentIndex,
  }) = _PlaybackDelta;

  /// Decodes a `group:playback-delta` payload.
  factory fromJson(Map<String, Object?> json) => _$PlaybackDeltaFromJson(json);
}

/// `group:queue-delta`: the queue changed.
@freezed
abstract class QueueDelta with _$QueueDelta {
  /// Creates a delta.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory QueueDelta({
    /// The whole new queue.
    required List<SocketQueueEntry> queue,

    /// The index of the current item.
    required int currentIndex,

    /// Grows with every change of the playback state.
    required int stateVersion,
  }) = _QueueDelta;

  /// Decodes a `group:queue-delta` payload.
  factory fromJson(Map<String, Object?> json) => _$QueueDeltaFromJson(json);
}

/// `group:waiting`: load the item at [currentIndex] and report `ready`.
@freezed
abstract class WaitingEvent with _$WaitingEvent {
  /// Creates the event.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory WaitingEvent({
    /// The index of the item to load.
    required int currentIndex,
  }) = _WaitingEvent;

  /// Decodes a `group:waiting` payload.
  factory fromJson(Map<String, Object?> json) => _$WaitingEventFromJson(json);
}

/// `group:play-at`: start playing from [positionMs] at [serverTime].
@freezed
abstract class PlayAtEvent with _$PlayAtEvent {
  /// Creates the event.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory PlayAtEvent({
    /// Where to start, in milliseconds.
    required int positionMs,

    /// When to start, on the server's clock, in milliseconds.
    required int serverTime,

    /// Grows with every change of the playback state.
    required int stateVersion,
  }) = _PlayAtEvent;

  /// Decodes a `group:play-at` payload.
  factory fromJson(Map<String, Object?> json) => _$PlayAtEventFromJson(json);
}

/// A change of a group's members; the union key is the event name.
@Freezed(unionKey: 'event')
sealed class MemberEvent with _$MemberEvent {
  /// `group:member-joined`.
  @FreezedUnionValue('group:member-joined')
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory MemberEvent.joined({
    /// The group.
    required String groupId,

    /// The member's user id.
    required String userId,

    /// The member's username.
    required String username,
  }) = MemberJoined;

  /// `group:member-presence`: a member's socket connected or went away.
  @FreezedUnionValue('group:member-presence')
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory MemberEvent.presence({
    /// The group.
    required String groupId,

    /// The member's user id.
    required String userId,

    /// Whether the member has a socket in the group.
    required bool isConnected,
  }) = MemberPresence;

  /// `group:member-left`.
  @FreezedUnionValue('group:member-left')
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory MemberEvent.left({
    /// The group.
    required String groupId,

    /// The member's user id.
    required String userId,

    /// The member's username.
    required String username,

    /// The new host's user id, when the host left.
    String? newHostUserId,

    /// The new host's username, when the host left.
    String? newHostUsername,
  }) = MemberLeft;

  /// Decodes a payload whose `event` key holds the socket event name.
  factory fromJson(Map<String, Object?> json) => _$MemberEventFromJson(json);
}

/// The group ended for this client; the union key is the event name.
@Freezed(unionKey: 'event')
sealed class GroupEnded with _$GroupEnded {
  /// `group:ended`: the group was closed.
  @FreezedUnionValue('group:ended')
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory GroupEnded.ended({
    /// Why the group ended.
    String? reason,

    /// The group.
    String? groupId,
  }) = GroupClosed;

  /// `group:membership-revoked`: this user was removed from the group.
  @FreezedUnionValue('group:membership-revoked')
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory GroupEnded.revoked({
    /// Why the membership was revoked.
    String? reason,

    /// The group.
    String? groupId,
  }) = MembershipRevoked;

  /// Decodes a payload whose `event` key holds the socket event name.
  factory fromJson(Map<String, Object?> json) => _$GroupEndedFromJson(json);
}

/// `social:presence-updated`: a user's presence changed; read it over REST.
@freezed
abstract class PresenceUpdated with _$PresenceUpdated {
  /// Creates the event.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory PresenceUpdated({
    /// The user whose presence changed.
    required String userId,
  }) = _PresenceUpdated;

  /// Decodes a `social:presence-updated` payload.
  factory fromJson(Map<String, Object?> json) =>
      _$PresenceUpdatedFromJson(json);
}

/// The acknowledgement of a command: `{ ok }`.
@freezed
abstract class Ack with _$Ack {
  /// Creates an acknowledgement.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory Ack({
    /// Whether the server applied the command.
    @Default(false) bool ok,
  }) = _Ack;

  /// Decodes an acknowledgement.
  factory fromJson(Map<String, Object?> json) => _$AckFromJson(json);
}

/// The acknowledgement of a `queue` command.
@freezed
abstract class QueueAck with _$QueueAck {
  /// Creates an acknowledgement.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory QueueAck({
    /// Whether the server applied the command.
    @Default(false) bool ok,

    /// How many tracks of an addition were queued.
    int? acceptedCount,

    /// How many tracks of an addition were not queued.
    int? skippedCount,

    /// Whether the queue limit cut the addition short.
    bool? truncated,
  }) = _QueueAck;

  /// Decodes an acknowledgement.
  factory fromJson(Map<String, Object?> json) => _$QueueAckFromJson(json);
}
