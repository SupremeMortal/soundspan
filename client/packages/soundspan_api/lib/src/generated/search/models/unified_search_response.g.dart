// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unified_search_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnifiedSearchResponse _$UnifiedSearchResponseFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['hasMore', 'items'],
    disallowNullValues: const ['hasMore', 'items'],
  );
  return UnifiedSearchResponse(
    hasMore: json['hasMore'] as bool,
    items: (json['items'] as List<dynamic>)
        .map((e) => SearchItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    additionalProperties:
        UnifiedSearchResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : UnifiedSearchResponse._readExtras(
            UnifiedSearchResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$UnifiedSearchResponseToJson(
  UnifiedSearchResponse instance,
) => <String, dynamic>{
  'hasMore': instance.hasMore,
  'items': instance.items.map((e) => e.toJson()).toList(),
};
