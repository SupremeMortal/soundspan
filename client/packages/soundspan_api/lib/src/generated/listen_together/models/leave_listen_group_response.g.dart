// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leave_listen_group_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaveListenGroupResponse _$LeaveListenGroupResponseFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['ended', 'success'],
    disallowNullValues: const [
      'ended',
      'newHostUserId',
      'newHostUsername',
      'success',
    ],
  );
  return LeaveListenGroupResponse(
    ended: json['ended'] as bool,
    newHostUserId: json['newHostUserId'] as String?,
    newHostUsername: json['newHostUsername'] as String?,
    success: json['success'] as bool,
    additionalProperties:
        LeaveListenGroupResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : LeaveListenGroupResponse._readExtras(
            LeaveListenGroupResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$LeaveListenGroupResponseToJson(
  LeaveListenGroupResponse instance,
) => <String, dynamic>{
  'ended': instance.ended,
  'newHostUserId': ?instance.newHostUserId,
  'newHostUsername': ?instance.newHostUsername,
  'success': instance.success,
};
