// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_link_verify_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceLinkVerifyRequest _$DeviceLinkVerifyRequestFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['code'],
    disallowNullValues: const ['code', 'deviceName'],
  );
  return DeviceLinkVerifyRequest(
    code: json['code'] as String,
    deviceName: json['deviceName'] as String?,
    additionalProperties:
        DeviceLinkVerifyRequest._extras(json, 'additionalProperties') == null
        ? const {}
        : DeviceLinkVerifyRequest._readExtras(
            DeviceLinkVerifyRequest._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$DeviceLinkVerifyRequestToJson(
  DeviceLinkVerifyRequest instance,
) => <String, dynamic>{
  'code': instance.code,
  'deviceName': ?instance.deviceName,
};
