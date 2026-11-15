// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_key_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiKeySummary _$ApiKeySummaryFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['createdAt', 'expiresAt', 'id', 'lastUsed', 'name'],
    disallowNullValues: const ['createdAt', 'expiresAt', 'id', 'name'],
  );
  return ApiKeySummary(
    createdAt: ApiKeySummary._read_createdAt(json['createdAt']),
    expiresAt: ApiKeySummary._read_expiresAt(json['expiresAt']),
    id: json['id'] as String,
    lastUsed: ApiKeySummary._read_lastUsed(json['lastUsed']),
    name: json['name'] as String,
    additionalProperties:
        ApiKeySummary._extras(json, 'additionalProperties') == null
        ? const {}
        : ApiKeySummary._readExtras(
            ApiKeySummary._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$ApiKeySummaryToJson(ApiKeySummary instance) =>
    <String, dynamic>{
      'createdAt': ?ApiKeySummary._write_createdAt(instance.createdAt),
      'expiresAt': ?ApiKeySummary._write_expiresAt(instance.expiresAt),
      'id': instance.id,
      'lastUsed': ApiKeySummary._write_lastUsed(instance.lastUsed),
      'name': instance.name,
    };
