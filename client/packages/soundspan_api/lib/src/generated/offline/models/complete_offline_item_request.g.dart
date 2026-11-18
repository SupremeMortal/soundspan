// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complete_offline_item_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompleteOfflineItemRequest _$CompleteOfflineItemRequestFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['deviceId', 'playbackId', 'quality', 'sizeBytes'],
    disallowNullValues: const [
      'deviceId',
      'playbackId',
      'quality',
      'sizeBytes',
    ],
  );
  return CompleteOfflineItemRequest(
    deviceId: json['deviceId'] as String,
    playbackId: json['playbackId'] as String,
    quality: CompleteOfflineItemRequest._read_quality(json['quality']),
    sizeBytes: CompleteOfflineItemRequest._read_sizeBytes(json['sizeBytes']),
    additionalProperties:
        CompleteOfflineItemRequest._extras(json, 'additionalProperties') == null
        ? const {}
        : CompleteOfflineItemRequest._readExtras(
            CompleteOfflineItemRequest._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$CompleteOfflineItemRequestToJson(
  CompleteOfflineItemRequest instance,
) => <String, dynamic>{
  'deviceId': instance.deviceId,
  'playbackId': instance.playbackId,
  'quality': ?CompleteOfflineItemRequest._write_quality(instance.quality),
  'sizeBytes': ?CompleteOfflineItemRequest._write_sizeBytes(instance.sizeBytes),
};
