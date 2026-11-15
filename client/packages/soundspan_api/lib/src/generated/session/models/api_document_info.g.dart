// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_document_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiDocumentInfo _$ApiDocumentInfoFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['info'],
    disallowNullValues: const ['info'],
  );
  return ApiDocumentInfo(
    info: ApiDocumentInfoInfo.fromJson(json['info'] as Map<String, dynamic>),
    additionalProperties:
        ApiDocumentInfo._extras(json, 'additionalProperties') == null
        ? const {}
        : ApiDocumentInfo._readExtras(
            ApiDocumentInfo._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$ApiDocumentInfoToJson(ApiDocumentInfo instance) =>
    <String, dynamic>{'info': instance.info.toJson()};
