// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discover_current.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiscoverCurrent _$DiscoverCurrentFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'totalCount',
      'tracks',
      'unavailableCount',
      'weekEnd',
      'weekStart',
    ],
    disallowNullValues: const [
      'totalCount',
      'tracks',
      'unavailableCount',
      'weekEnd',
      'weekStart',
    ],
  );
  return DiscoverCurrent(
    totalCount: DiscoverCurrent._read_totalCount(json['totalCount']),
    tracks: (json['tracks'] as List<dynamic>)
        .map((e) => DiscoverTrack.fromJson(e as Map<String, dynamic>))
        .toList(),
    unavailableCount: DiscoverCurrent._read_unavailableCount(
      json['unavailableCount'],
    ),
    weekEnd: DiscoverCurrent._read_weekEnd(json['weekEnd']),
    weekStart: DiscoverCurrent._read_weekStart(json['weekStart']),
    additionalProperties:
        DiscoverCurrent._extras(json, 'additionalProperties') == null
        ? const {}
        : DiscoverCurrent._readExtras(
            DiscoverCurrent._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$DiscoverCurrentToJson(DiscoverCurrent instance) =>
    <String, dynamic>{
      'totalCount': ?DiscoverCurrent._write_totalCount(instance.totalCount),
      'tracks': instance.tracks.map((e) => e.toJson()).toList(),
      'unavailableCount': ?DiscoverCurrent._write_unavailableCount(
        instance.unavailableCount,
      ),
      'weekEnd': ?DiscoverCurrent._write_weekEnd(instance.weekEnd),
      'weekStart': ?DiscoverCurrent._write_weekStart(instance.weekStart),
    };
