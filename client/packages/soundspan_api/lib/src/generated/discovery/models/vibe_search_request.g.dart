// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vibe_search_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VibeSearchRequest _$VibeSearchRequestFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['query'],
    disallowNullValues: const ['limit', 'minSimilarity', 'query'],
  );
  return VibeSearchRequest(
    limit: VibeSearchRequest._read_limit(json['limit']),
    minSimilarity: json['minSimilarity'] as num?,
    query: json['query'] as String,
    additionalProperties:
        VibeSearchRequest._extras(json, 'additionalProperties') == null
        ? const {}
        : VibeSearchRequest._readExtras(
            VibeSearchRequest._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$VibeSearchRequestToJson(VibeSearchRequest instance) =>
    <String, dynamic>{
      'limit': ?VibeSearchRequest._write_limit(instance.limit),
      'minSimilarity': ?instance.minSimilarity,
      'query': instance.query,
    };
