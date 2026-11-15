// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'online_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OnlineUser _$OnlineUserFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'displayName',
      'hasProfilePicture',
      'id',
      'isInListenTogetherGroup',
      'lastHeartbeatAt',
      'listeningStatus',
      'listeningTrack',
      'username',
    ],
    disallowNullValues: const [
      'displayName',
      'hasProfilePicture',
      'id',
      'isInListenTogetherGroup',
      'lastHeartbeatAt',
      'listeningStatus',
      'listeningTrack',
      'username',
    ],
  );
  return OnlineUser(
    displayName: json['displayName'] as String,
    hasProfilePicture: json['hasProfilePicture'] as bool,
    id: json['id'] as String,
    isInListenTogetherGroup: json['isInListenTogetherGroup'] as bool,
    lastHeartbeatAt: OnlineUser._read_lastHeartbeatAt(json['lastHeartbeatAt']),
    listeningStatus: OnlineUser._read_listeningStatus(json['listeningStatus']),
    listeningTrack: OnlineUserTrack.fromJson(
      json['listeningTrack'] as Map<String, dynamic>,
    ),
    username: json['username'] as String,
    additionalProperties:
        OnlineUser._extras(json, 'additionalProperties') == null
        ? const {}
        : OnlineUser._readExtras(
            OnlineUser._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$OnlineUserToJson(OnlineUser instance) =>
    <String, dynamic>{
      'displayName': instance.displayName,
      'hasProfilePicture': instance.hasProfilePicture,
      'id': instance.id,
      'isInListenTogetherGroup': instance.isInListenTogetherGroup,
      'lastHeartbeatAt': ?OnlineUser._write_lastHeartbeatAt(
        instance.lastHeartbeatAt,
      ),
      'listeningStatus': ?OnlineUser._write_listeningStatus(
        instance.listeningStatus,
      ),
      'listeningTrack': instance.listeningTrack.toJson(),
      'username': instance.username,
    };
