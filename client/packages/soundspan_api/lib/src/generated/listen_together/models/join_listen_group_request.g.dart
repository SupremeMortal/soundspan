// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_listen_group_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JoinListenGroupRequest _$JoinListenGroupRequestFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['joinCode'],
    disallowNullValues: const ['joinCode'],
  );
  return JoinListenGroupRequest(
    joinCode: json['joinCode'] as String,
    additionalProperties:
        JoinListenGroupRequest._extras(json, 'additionalProperties') == null
        ? const {}
        : JoinListenGroupRequest._readExtras(
            JoinListenGroupRequest._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$JoinListenGroupRequestToJson(
  JoinListenGroupRequest instance,
) => <String, dynamic>{'joinCode': instance.joinCode};
