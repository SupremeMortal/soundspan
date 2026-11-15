// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiError _$ApiErrorFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['error'],
    disallowNullValues: const ['code', 'error'],
  );
  return ApiError(
    code: json['code'] as String?,
    error: json['error'] as String,
    additionalProperties: ApiError._extras(json, 'additionalProperties') == null
        ? const {}
        : ApiError._readExtras(ApiError._extras(json, 'additionalProperties')),
  );
}

Map<String, dynamic> _$ApiErrorToJson(ApiError instance) => <String, dynamic>{
  'code': ?instance.code,
  'error': instance.error,
};
