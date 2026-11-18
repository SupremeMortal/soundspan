// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_document_info_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiDocumentInfoInfo _$ApiDocumentInfoInfoFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['version'],
    disallowNullValues: const ['version'],
  );
  return ApiDocumentInfoInfo(
    version: json['version'] as String,
    additionalProperties:
        ApiDocumentInfoInfo._extras(json, 'additionalProperties') == null
        ? const {}
        : ApiDocumentInfoInfo._readExtras(
            ApiDocumentInfoInfo._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$ApiDocumentInfoInfoToJson(
  ApiDocumentInfoInfo instance,
) => <String, dynamic>{'version': instance.version};
