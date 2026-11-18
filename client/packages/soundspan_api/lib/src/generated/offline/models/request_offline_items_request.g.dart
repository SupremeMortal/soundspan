// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_offline_items_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RequestOfflineItemsRequest _$RequestOfflineItemsRequestFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['deviceId', 'id', 'kind'],
    disallowNullValues: const ['deviceId', 'id', 'kind', 'quality'],
  );
  return RequestOfflineItemsRequest(
    deviceId: json['deviceId'] as String,
    id: json['id'] as String,
    kind: RequestOfflineItemsRequest._read_kind(json['kind']),
    quality: RequestOfflineItemsRequest._read_quality(json['quality']),
    additionalProperties:
        RequestOfflineItemsRequest._extras(json, 'additionalProperties') == null
        ? const {}
        : RequestOfflineItemsRequest._readExtras(
            RequestOfflineItemsRequest._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$RequestOfflineItemsRequestToJson(
  RequestOfflineItemsRequest instance,
) => <String, dynamic>{
  'deviceId': instance.deviceId,
  'id': instance.id,
  'kind': ?RequestOfflineItemsRequest._write_kind(instance.kind),
  'quality': ?RequestOfflineItemsRequest._write_quality(instance.quality),
};
