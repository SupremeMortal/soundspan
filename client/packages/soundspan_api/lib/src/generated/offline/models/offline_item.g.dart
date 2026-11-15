// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineItem _$OfflineItemFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['downloadable', 'playbackId'],
    disallowNullValues: const [
      'downloadUrl',
      'downloadable',
      'playbackId',
      'quality',
      'reason',
    ],
  );
  return OfflineItem(
    contentType: json['contentType'] as String?,
    downloadUrl: json['downloadUrl'] as String?,
    downloadable: json['downloadable'] as bool,
    expectedSize: OfflineItem._read_expectedSize(json['expectedSize']),
    playbackId: json['playbackId'] as String,
    quality: OfflineItem._read_quality(json['quality']),
    reason: OfflineItem._read_reason(json['reason']),
    additionalProperties:
        OfflineItem._extras(json, 'additionalProperties') == null
        ? const {}
        : OfflineItem._readExtras(
            OfflineItem._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$OfflineItemToJson(OfflineItem instance) =>
    <String, dynamic>{
      'contentType': ?instance.contentType,
      'downloadUrl': ?instance.downloadUrl,
      'downloadable': instance.downloadable,
      'expectedSize': ?OfflineItem._write_expectedSize(instance.expectedSize),
      'playbackId': instance.playbackId,
      'quality': ?OfflineItem._write_quality(instance.quality),
      'reason': ?OfflineItem._write_reason(instance.reason),
    };
