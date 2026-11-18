// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'socket_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SocketQueueArtist _$SocketQueueArtistFromJson(Map<String, dynamic> json) =>
    _SocketQueueArtist(id: json['id'] as String, name: json['name'] as String);

Map<String, dynamic> _$SocketQueueArtistToJson(_SocketQueueArtist instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

_SocketQueueAlbum _$SocketQueueAlbumFromJson(Map<String, dynamic> json) =>
    _SocketQueueAlbum(
      id: json['id'] as String,
      title: json['title'] as String,
      coverArt: json['coverArt'] as String?,
      albumLoudnessLufs: (json['albumLoudnessLufs'] as num?)?.toDouble(),
      albumTruePeakDb: (json['albumTruePeakDb'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$SocketQueueAlbumToJson(_SocketQueueAlbum instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'coverArt': instance.coverArt,
      'albumLoudnessLufs': instance.albumLoudnessLufs,
      'albumTruePeakDb': instance.albumTruePeakDb,
    };

_SocketQueueEntry _$SocketQueueEntryFromJson(Map<String, dynamic> json) =>
    _SocketQueueEntry(
      title: json['title'] as String,
      duration: (json['duration'] as num).toDouble(),
      artist: SocketQueueArtist.fromJson(
        json['artist'] as Map<String, dynamic>,
      ),
      album: SocketQueueAlbum.fromJson(json['album'] as Map<String, dynamic>),
      playbackId: json['playbackId'] as String?,
      loudnessLufs: (json['loudnessLufs'] as num?)?.toDouble(),
      truePeakDb: (json['truePeakDb'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$SocketQueueEntryToJson(_SocketQueueEntry instance) =>
    <String, dynamic>{
      'title': instance.title,
      'duration': instance.duration,
      'artist': instance.artist,
      'album': instance.album,
      'playbackId': instance.playbackId,
      'loudnessLufs': instance.loudnessLufs,
      'truePeakDb': instance.truePeakDb,
    };

_GroupPlayback _$GroupPlaybackFromJson(Map<String, dynamic> json) =>
    _GroupPlayback(
      queue: (json['queue'] as List<dynamic>)
          .map((e) => SocketQueueEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentIndex: (json['currentIndex'] as num).toInt(),
      isPlaying: json['isPlaying'] as bool,
      positionMs: (json['positionMs'] as num).toInt(),
      serverTime: (json['serverTime'] as num).toInt(),
      stateVersion: (json['stateVersion'] as num).toInt(),
    );

Map<String, dynamic> _$GroupPlaybackToJson(_GroupPlayback instance) =>
    <String, dynamic>{
      'queue': instance.queue,
      'currentIndex': instance.currentIndex,
      'isPlaying': instance.isPlaying,
      'positionMs': instance.positionMs,
      'serverTime': instance.serverTime,
      'stateVersion': instance.stateVersion,
    };

_GroupMemberInfo _$GroupMemberInfoFromJson(Map<String, dynamic> json) =>
    _GroupMemberInfo(
      userId: json['userId'] as String,
      username: json['username'] as String,
      isHost: json['isHost'] as bool,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      isConnected: json['isConnected'] as bool,
    );

Map<String, dynamic> _$GroupMemberInfoToJson(_GroupMemberInfo instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'username': instance.username,
      'isHost': instance.isHost,
      'joinedAt': instance.joinedAt.toIso8601String(),
      'isConnected': instance.isConnected,
    };

_GroupSnapshot _$GroupSnapshotFromJson(Map<String, dynamic> json) =>
    _GroupSnapshot(
      id: json['id'] as String,
      name: json['name'] as String,
      joinCode: json['joinCode'] as String,
      groupType: $enumDecode(
        _$GroupTypeEnumMap,
        json['groupType'],
        unknownValue: GroupType.unknown,
      ),
      visibility: json['visibility'] as String,
      isActive: json['isActive'] as bool,
      hostUserId: json['hostUserId'] as String,
      syncState: $enumDecode(
        _$GroupSyncStateEnumMap,
        json['syncState'],
        unknownValue: GroupSyncState.unknown,
      ),
      playback: GroupPlayback.fromJson(
        json['playback'] as Map<String, dynamic>,
      ),
      members: (json['members'] as List<dynamic>)
          .map((e) => GroupMemberInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GroupSnapshotToJson(_GroupSnapshot instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'joinCode': instance.joinCode,
      'groupType': _$GroupTypeEnumMap[instance.groupType]!,
      'visibility': instance.visibility,
      'isActive': instance.isActive,
      'hostUserId': instance.hostUserId,
      'syncState': _$GroupSyncStateEnumMap[instance.syncState]!,
      'playback': instance.playback,
      'members': instance.members,
    };

const _$GroupTypeEnumMap = {
  GroupType.hostFollower: 'host-follower',
  GroupType.collaborative: 'collaborative',
  GroupType.unknown: 'unknown',
};

const _$GroupSyncStateEnumMap = {
  GroupSyncState.idle: 'idle',
  GroupSyncState.waiting: 'waiting',
  GroupSyncState.playing: 'playing',
  GroupSyncState.paused: 'paused',
  GroupSyncState.unknown: 'unknown',
};

_PlaybackDelta _$PlaybackDeltaFromJson(Map<String, dynamic> json) =>
    _PlaybackDelta(
      isPlaying: json['isPlaying'] as bool,
      positionMs: (json['positionMs'] as num).toInt(),
      serverTime: (json['serverTime'] as num).toInt(),
      stateVersion: (json['stateVersion'] as num).toInt(),
      currentIndex: (json['currentIndex'] as num).toInt(),
    );

Map<String, dynamic> _$PlaybackDeltaToJson(_PlaybackDelta instance) =>
    <String, dynamic>{
      'isPlaying': instance.isPlaying,
      'positionMs': instance.positionMs,
      'serverTime': instance.serverTime,
      'stateVersion': instance.stateVersion,
      'currentIndex': instance.currentIndex,
    };

_QueueDelta _$QueueDeltaFromJson(Map<String, dynamic> json) => _QueueDelta(
  queue: (json['queue'] as List<dynamic>)
      .map((e) => SocketQueueEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
  currentIndex: (json['currentIndex'] as num).toInt(),
  stateVersion: (json['stateVersion'] as num).toInt(),
);

Map<String, dynamic> _$QueueDeltaToJson(_QueueDelta instance) =>
    <String, dynamic>{
      'queue': instance.queue,
      'currentIndex': instance.currentIndex,
      'stateVersion': instance.stateVersion,
    };

_WaitingEvent _$WaitingEventFromJson(Map<String, dynamic> json) =>
    _WaitingEvent(currentIndex: (json['currentIndex'] as num).toInt());

Map<String, dynamic> _$WaitingEventToJson(_WaitingEvent instance) =>
    <String, dynamic>{'currentIndex': instance.currentIndex};

_PlayAtEvent _$PlayAtEventFromJson(Map<String, dynamic> json) => _PlayAtEvent(
  positionMs: (json['positionMs'] as num).toInt(),
  serverTime: (json['serverTime'] as num).toInt(),
  stateVersion: (json['stateVersion'] as num).toInt(),
);

Map<String, dynamic> _$PlayAtEventToJson(_PlayAtEvent instance) =>
    <String, dynamic>{
      'positionMs': instance.positionMs,
      'serverTime': instance.serverTime,
      'stateVersion': instance.stateVersion,
    };

MemberJoined _$MemberJoinedFromJson(Map<String, dynamic> json) => MemberJoined(
  groupId: json['groupId'] as String,
  userId: json['userId'] as String,
  username: json['username'] as String,
  $type: json['event'] as String?,
);

Map<String, dynamic> _$MemberJoinedToJson(MemberJoined instance) =>
    <String, dynamic>{
      'groupId': instance.groupId,
      'userId': instance.userId,
      'username': instance.username,
      'event': instance.$type,
    };

MemberPresence _$MemberPresenceFromJson(Map<String, dynamic> json) =>
    MemberPresence(
      groupId: json['groupId'] as String,
      userId: json['userId'] as String,
      isConnected: json['isConnected'] as bool,
      $type: json['event'] as String?,
    );

Map<String, dynamic> _$MemberPresenceToJson(MemberPresence instance) =>
    <String, dynamic>{
      'groupId': instance.groupId,
      'userId': instance.userId,
      'isConnected': instance.isConnected,
      'event': instance.$type,
    };

MemberLeft _$MemberLeftFromJson(Map<String, dynamic> json) => MemberLeft(
  groupId: json['groupId'] as String,
  userId: json['userId'] as String,
  username: json['username'] as String,
  newHostUserId: json['newHostUserId'] as String?,
  newHostUsername: json['newHostUsername'] as String?,
  $type: json['event'] as String?,
);

Map<String, dynamic> _$MemberLeftToJson(MemberLeft instance) =>
    <String, dynamic>{
      'groupId': instance.groupId,
      'userId': instance.userId,
      'username': instance.username,
      'newHostUserId': instance.newHostUserId,
      'newHostUsername': instance.newHostUsername,
      'event': instance.$type,
    };

GroupClosed _$GroupClosedFromJson(Map<String, dynamic> json) => GroupClosed(
  reason: json['reason'] as String?,
  groupId: json['groupId'] as String?,
  $type: json['event'] as String?,
);

Map<String, dynamic> _$GroupClosedToJson(GroupClosed instance) =>
    <String, dynamic>{
      'reason': instance.reason,
      'groupId': instance.groupId,
      'event': instance.$type,
    };

MembershipRevoked _$MembershipRevokedFromJson(Map<String, dynamic> json) =>
    MembershipRevoked(
      reason: json['reason'] as String?,
      groupId: json['groupId'] as String?,
      $type: json['event'] as String?,
    );

Map<String, dynamic> _$MembershipRevokedToJson(MembershipRevoked instance) =>
    <String, dynamic>{
      'reason': instance.reason,
      'groupId': instance.groupId,
      'event': instance.$type,
    };

_PresenceUpdated _$PresenceUpdatedFromJson(Map<String, dynamic> json) =>
    _PresenceUpdated(userId: json['userId'] as String);

Map<String, dynamic> _$PresenceUpdatedToJson(_PresenceUpdated instance) =>
    <String, dynamic>{'userId': instance.userId};

_Ack _$AckFromJson(Map<String, dynamic> json) =>
    _Ack(ok: json['ok'] as bool? ?? false);

Map<String, dynamic> _$AckToJson(_Ack instance) => <String, dynamic>{
  'ok': instance.ok,
};

_QueueAck _$QueueAckFromJson(Map<String, dynamic> json) => _QueueAck(
  ok: json['ok'] as bool? ?? false,
  acceptedCount: (json['acceptedCount'] as num?)?.toInt(),
  skippedCount: (json['skippedCount'] as num?)?.toInt(),
  truncated: json['truncated'] as bool?,
);

Map<String, dynamic> _$QueueAckToJson(_QueueAck instance) => <String, dynamic>{
  'ok': instance.ok,
  'acceptedCount': instance.acceptedCount,
  'skippedCount': instance.skippedCount,
  'truncated': instance.truncated,
};
