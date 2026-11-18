// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_offline_items_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceOfflineItemsResponse _$DeviceOfflineItemsResponseFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['items'],
    disallowNullValues: const ['items'],
  );
  return DeviceOfflineItemsResponse(
    items: (json['items'] as List<dynamic>)
        .map((e) => DeviceOfflineItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    additionalProperties:
        DeviceOfflineItemsResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : DeviceOfflineItemsResponse._readExtras(
            DeviceOfflineItemsResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$DeviceOfflineItemsResponseToJson(
  DeviceOfflineItemsResponse instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
