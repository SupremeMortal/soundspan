// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_offline_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceOfflineItem _$DeviceOfflineItemFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['playbackId', 'quality', 'revoked', 'sizeBytes'],
    disallowNullValues: const ['playbackId', 'quality', 'revoked', 'sizeBytes'],
  );
  return DeviceOfflineItem(
    playbackId: json['playbackId'] as String,
    quality: DeviceOfflineItem._read_quality(json['quality']),
    revoked: json['revoked'] as bool,
    sizeBytes: DeviceOfflineItem._read_sizeBytes(json['sizeBytes']),
    additionalProperties:
        DeviceOfflineItem._extras(json, 'additionalProperties') == null
        ? const {}
        : DeviceOfflineItem._readExtras(
            DeviceOfflineItem._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$DeviceOfflineItemToJson(DeviceOfflineItem instance) =>
    <String, dynamic>{
      'playbackId': instance.playbackId,
      'quality': ?DeviceOfflineItem._write_quality(instance.quality),
      'revoked': instance.revoked,
      'sizeBytes': ?DeviceOfflineItem._write_sizeBytes(instance.sizeBytes),
    };
