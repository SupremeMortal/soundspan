// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineStats _$OfflineStatsFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'availableMb',
      'maxMb',
      'percentUsed',
      'trackCount',
      'usedMb',
    ],
    disallowNullValues: const [
      'availableMb',
      'device',
      'maxMb',
      'percentUsed',
      'trackCount',
      'usedMb',
    ],
  );
  return OfflineStats(
    availableMb: json['availableMb'] as num,
    device: json['device'] == null
        ? null
        : OfflineStatsDevice.fromJson(json['device'] as Map<String, dynamic>),
    maxMb: OfflineStats._read_maxMb(json['maxMb']),
    percentUsed: json['percentUsed'] as num,
    trackCount: OfflineStats._read_trackCount(json['trackCount']),
    usedMb: json['usedMb'] as num,
    additionalProperties:
        OfflineStats._extras(json, 'additionalProperties') == null
        ? const {}
        : OfflineStats._readExtras(
            OfflineStats._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$OfflineStatsToJson(OfflineStats instance) =>
    <String, dynamic>{
      'availableMb': instance.availableMb,
      'device': ?instance.device?.toJson(),
      'maxMb': ?OfflineStats._write_maxMb(instance.maxMb),
      'percentUsed': instance.percentUsed,
      'trackCount': ?OfflineStats._write_trackCount(instance.trackCount),
      'usedMb': instance.usedMb,
    };
