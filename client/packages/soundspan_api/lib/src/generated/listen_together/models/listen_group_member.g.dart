// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listen_group_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListenGroupMember _$ListenGroupMemberFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'isConnected',
      'isHost',
      'joinedAt',
      'userId',
      'username',
    ],
    disallowNullValues: const [
      'isConnected',
      'isHost',
      'joinedAt',
      'userId',
      'username',
    ],
  );
  return ListenGroupMember(
    isConnected: json['isConnected'] as bool,
    isHost: json['isHost'] as bool,
    joinedAt: ListenGroupMember._read_joinedAt(json['joinedAt']),
    userId: json['userId'] as String,
    username: json['username'] as String,
    additionalProperties:
        ListenGroupMember._extras(json, 'additionalProperties') == null
        ? const {}
        : ListenGroupMember._readExtras(
            ListenGroupMember._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$ListenGroupMemberToJson(ListenGroupMember instance) =>
    <String, dynamic>{
      'isConnected': instance.isConnected,
      'isHost': instance.isHost,
      'joinedAt': ?ListenGroupMember._write_joinedAt(instance.joinedAt),
      'userId': instance.userId,
      'username': instance.username,
    };
