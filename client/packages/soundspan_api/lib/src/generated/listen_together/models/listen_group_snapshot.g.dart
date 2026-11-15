// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listen_group_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListenGroupSnapshot _$ListenGroupSnapshotFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'groupType',
      'hostUserId',
      'id',
      'isActive',
      'joinCode',
      'members',
      'name',
      'playback',
      'syncState',
      'visibility',
    ],
    disallowNullValues: const [
      'groupType',
      'hostUserId',
      'id',
      'isActive',
      'joinCode',
      'members',
      'membershipVersion',
      'name',
      'playback',
      'readyUserIds',
      'syncState',
      'visibility',
    ],
  );
  return ListenGroupSnapshot(
    groupType: ListenGroupSnapshot._read_groupType(json['groupType']),
    hostUserId: json['hostUserId'] as String,
    id: json['id'] as String,
    isActive: json['isActive'] as bool,
    joinCode: json['joinCode'] as String,
    members: (json['members'] as List<dynamic>)
        .map((e) => ListenGroupMember.fromJson(e as Map<String, dynamic>))
        .toList(),
    membershipVersion: ListenGroupSnapshot._read_membershipVersion(
      json['membershipVersion'],
    ),
    name: json['name'] as String,
    playback: ListenGroupPlayback.fromJson(
      json['playback'] as Map<String, dynamic>,
    ),
    readyDeadlineMs: ListenGroupSnapshot._read_readyDeadlineMs(
      json['readyDeadlineMs'],
    ),
    readyUserIds: (json['readyUserIds'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList(),
    syncState: ListenGroupSnapshot._read_syncState(json['syncState']),
    visibility: ListenGroupSnapshot._read_visibility(json['visibility']),
    additionalProperties:
        ListenGroupSnapshot._extras(json, 'additionalProperties') == null
        ? const {}
        : ListenGroupSnapshot._readExtras(
            ListenGroupSnapshot._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$ListenGroupSnapshotToJson(
  ListenGroupSnapshot instance,
) => <String, dynamic>{
  'groupType': ?ListenGroupSnapshot._write_groupType(instance.groupType),
  'hostUserId': instance.hostUserId,
  'id': instance.id,
  'isActive': instance.isActive,
  'joinCode': instance.joinCode,
  'members': instance.members.map((e) => e.toJson()).toList(),
  'membershipVersion': ?ListenGroupSnapshot._write_membershipVersion(
    instance.membershipVersion,
  ),
  'name': instance.name,
  'playback': instance.playback.toJson(),
  'readyDeadlineMs': ?ListenGroupSnapshot._write_readyDeadlineMs(
    instance.readyDeadlineMs,
  ),
  'readyUserIds': ?instance.readyUserIds,
  'syncState': ?ListenGroupSnapshot._write_syncState(instance.syncState),
  'visibility': ?ListenGroupSnapshot._write_visibility(instance.visibility),
};
