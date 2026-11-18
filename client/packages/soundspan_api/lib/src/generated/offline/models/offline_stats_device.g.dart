// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_stats_device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineStatsDevice _$OfflineStatsDeviceFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['deviceId', 'trackCount', 'usedMb'],
    disallowNullValues: const ['deviceId', 'trackCount', 'usedMb'],
  );
  return OfflineStatsDevice(
    deviceId: json['deviceId'] as String,
    trackCount: OfflineStatsDevice._read_trackCount(json['trackCount']),
    usedMb: json['usedMb'] as num,
    additionalProperties:
        OfflineStatsDevice._extras(json, 'additionalProperties') == null
        ? const {}
        : OfflineStatsDevice._readExtras(
            OfflineStatsDevice._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$OfflineStatsDeviceToJson(OfflineStatsDevice instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'trackCount': ?OfflineStatsDevice._write_trackCount(instance.trackCount),
      'usedMb': instance.usedMb,
    };
