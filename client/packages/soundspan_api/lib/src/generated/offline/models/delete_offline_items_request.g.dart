// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_offline_items_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeleteOfflineItemsRequest _$DeleteOfflineItemsRequestFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['deviceId', 'playbackIds'],
    disallowNullValues: const ['deviceId', 'playbackIds'],
  );
  return DeleteOfflineItemsRequest(
    deviceId: json['deviceId'] as String,
    playbackIds: (json['playbackIds'] as List<dynamic>)
        .map((e) => e as String)
        .toList(),
    additionalProperties:
        DeleteOfflineItemsRequest._extras(json, 'additionalProperties') == null
        ? const {}
        : DeleteOfflineItemsRequest._readExtras(
            DeleteOfflineItemsRequest._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$DeleteOfflineItemsRequestToJson(
  DeleteOfflineItemsRequest instance,
) => <String, dynamic>{
  'deviceId': instance.deviceId,
  'playbackIds': instance.playbackIds,
};
