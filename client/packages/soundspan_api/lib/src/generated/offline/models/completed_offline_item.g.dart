// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'completed_offline_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompletedOfflineItem _$CompletedOfflineItemFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['playbackId', 'quality', 'sizeBytes'],
    disallowNullValues: const ['playbackId', 'quality', 'sizeBytes'],
  );
  return CompletedOfflineItem(
    playbackId: json['playbackId'] as String,
    quality: CompletedOfflineItem._read_quality(json['quality']),
    sizeBytes: CompletedOfflineItem._read_sizeBytes(json['sizeBytes']),
    additionalProperties:
        CompletedOfflineItem._extras(json, 'additionalProperties') == null
        ? const {}
        : CompletedOfflineItem._readExtras(
            CompletedOfflineItem._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$CompletedOfflineItemToJson(
  CompletedOfflineItem instance,
) => <String, dynamic>{
  'playbackId': instance.playbackId,
  'quality': ?CompletedOfflineItem._write_quality(instance.quality),
  'sizeBytes': ?CompletedOfflineItem._write_sizeBytes(instance.sizeBytes),
};
