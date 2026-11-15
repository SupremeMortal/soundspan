// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listen_group_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListenGroupSummary _$ListenGroupSummaryFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'currentTrack',
      'groupType',
      'host',
      'id',
      'isMember',
      'isPlaying',
      'joinCode',
      'memberCount',
      'name',
      'visibility',
    ],
    disallowNullValues: const [
      'groupType',
      'host',
      'id',
      'isMember',
      'isPlaying',
      'joinCode',
      'memberCount',
      'name',
      'visibility',
    ],
  );
  return ListenGroupSummary(
    currentTrack: json['currentTrack'] == null
        ? null
        : ListenGroupSummaryCurrentTrack.fromJson(
            json['currentTrack'] as Map<String, dynamic>,
          ),
    groupType: ListenGroupSummary._read_groupType(json['groupType']),
    host: ListenGroupSummaryHost.fromJson(json['host'] as Map<String, dynamic>),
    id: json['id'] as String,
    isMember: json['isMember'] as bool,
    isPlaying: json['isPlaying'] as bool,
    joinCode: json['joinCode'] as String,
    memberCount: ListenGroupSummary._read_memberCount(json['memberCount']),
    name: json['name'] as String,
    visibility: ListenGroupSummary._read_visibility(json['visibility']),
    additionalProperties:
        ListenGroupSummary._extras(json, 'additionalProperties') == null
        ? const {}
        : ListenGroupSummary._readExtras(
            ListenGroupSummary._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$ListenGroupSummaryToJson(
  ListenGroupSummary instance,
) => <String, dynamic>{
  'currentTrack': instance.currentTrack?.toJson(),
  'groupType': ?ListenGroupSummary._write_groupType(instance.groupType),
  'host': instance.host.toJson(),
  'id': instance.id,
  'isMember': instance.isMember,
  'isPlaying': instance.isPlaying,
  'joinCode': instance.joinCode,
  'memberCount': ?ListenGroupSummary._write_memberCount(instance.memberCount),
  'name': instance.name,
  'visibility': ?ListenGroupSummary._write_visibility(instance.visibility),
};
