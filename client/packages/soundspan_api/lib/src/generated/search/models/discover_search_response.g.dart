// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discover_search_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiscoverSearchResponse _$DiscoverSearchResponseFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['aliasInfo', 'results'],
    disallowNullValues: const ['aliasInfo', 'results'],
  );
  return DiscoverSearchResponse(
    aliasInfo: DiscoverAliasInfo.fromJson(
      json['aliasInfo'] as Map<String, dynamic>,
    ),
    results: (json['results'] as List<dynamic>)
        .map((e) => DiscoverResult.fromJson(e as Map<String, dynamic>))
        .toList(),
    additionalProperties:
        DiscoverSearchResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : DiscoverSearchResponse._readExtras(
            DiscoverSearchResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$DiscoverSearchResponseToJson(
  DiscoverSearchResponse instance,
) => <String, dynamic>{
  'aliasInfo': instance.aliasInfo.toJson(),
  'results': instance.results.map((e) => e.toJson()).toList(),
};
