// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'end_listen_group_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EndListenGroupResponse _$EndListenGroupResponseFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['success'],
    disallowNullValues: const ['success'],
  );
  return EndListenGroupResponse(
    success: json['success'] as bool,
    additionalProperties:
        EndListenGroupResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : EndListenGroupResponse._readExtras(
            EndListenGroupResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$EndListenGroupResponseToJson(
  EndListenGroupResponse instance,
) => <String, dynamic>{'success': instance.success};
