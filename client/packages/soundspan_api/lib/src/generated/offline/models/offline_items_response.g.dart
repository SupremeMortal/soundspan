// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_items_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineItemsResponse _$OfflineItemsResponseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'cacheLimitBytes',
      'cacheUsedBytes',
      'estimatedTotalBytes',
      'items',
    ],
    disallowNullValues: const [
      'cacheLimitBytes',
      'cacheUsedBytes',
      'estimatedTotalBytes',
      'items',
    ],
  );
  return OfflineItemsResponse(
    cacheLimitBytes: OfflineItemsResponse._read_cacheLimitBytes(
      json['cacheLimitBytes'],
    ),
    cacheUsedBytes: OfflineItemsResponse._read_cacheUsedBytes(
      json['cacheUsedBytes'],
    ),
    estimatedTotalBytes: OfflineItemsResponse._read_estimatedTotalBytes(
      json['estimatedTotalBytes'],
    ),
    items: (json['items'] as List<dynamic>)
        .map((e) => OfflineItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    additionalProperties:
        OfflineItemsResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : OfflineItemsResponse._readExtras(
            OfflineItemsResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$OfflineItemsResponseToJson(
  OfflineItemsResponse instance,
) => <String, dynamic>{
  'cacheLimitBytes': ?OfflineItemsResponse._write_cacheLimitBytes(
    instance.cacheLimitBytes,
  ),
  'cacheUsedBytes': ?OfflineItemsResponse._write_cacheUsedBytes(
    instance.cacheUsedBytes,
  ),
  'estimatedTotalBytes': ?OfflineItemsResponse._write_estimatedTotalBytes(
    instance.estimatedTotalBytes,
  ),
  'items': instance.items.map((e) => e.toJson()).toList(),
};
