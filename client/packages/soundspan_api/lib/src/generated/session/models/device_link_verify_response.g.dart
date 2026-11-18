// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_link_verify_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceLinkVerifyResponse _$DeviceLinkVerifyResponseFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['apiKey', 'userId', 'username'],
    disallowNullValues: const ['apiKey', 'userId', 'username'],
  );
  return DeviceLinkVerifyResponse(
    apiKey: json['apiKey'] as String,
    userId: json['userId'] as String,
    username: json['username'] as String,
    additionalProperties:
        DeviceLinkVerifyResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : DeviceLinkVerifyResponse._readExtras(
            DeviceLinkVerifyResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$DeviceLinkVerifyResponseToJson(
  DeviceLinkVerifyResponse instance,
) => <String, dynamic>{
  'apiKey': instance.apiKey,
  'userId': instance.userId,
  'username': instance.username,
};
