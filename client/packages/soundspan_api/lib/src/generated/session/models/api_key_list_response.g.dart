// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_key_list_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiKeyListResponse _$ApiKeyListResponseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['apiKeys'],
    disallowNullValues: const ['apiKeys'],
  );
  return ApiKeyListResponse(
    apiKeys: (json['apiKeys'] as List<dynamic>)
        .map((e) => ApiKeySummary.fromJson(e as Map<String, dynamic>))
        .toList(),
    additionalProperties:
        ApiKeyListResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : ApiKeyListResponse._readExtras(
            ApiKeyListResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$ApiKeyListResponseToJson(ApiKeyListResponse instance) =>
    <String, dynamic>{
      'apiKeys': instance.apiKeys.map((e) => e.toJson()).toList(),
    };
