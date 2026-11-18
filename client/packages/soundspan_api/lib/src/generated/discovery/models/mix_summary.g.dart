// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mix_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MixSummary _$MixSummaryFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'color',
      'coverUrls',
      'description',
      'id',
      'name',
      'trackCount',
      'trackIds',
      'type',
    ],
    disallowNullValues: const [
      'color',
      'coverUrls',
      'description',
      'id',
      'name',
      'trackCount',
      'trackIds',
      'type',
    ],
  );
  return MixSummary(
    color: json['color'] as String,
    coverUrls: (json['coverUrls'] as List<dynamic>)
        .map((e) => e as String)
        .toList(),
    description: json['description'] as String,
    id: json['id'] as String,
    name: json['name'] as String,
    trackCount: MixSummary._read_trackCount(json['trackCount']),
    trackIds: (json['trackIds'] as List<dynamic>)
        .map((e) => e as String)
        .toList(),
    type: json['type'] as String,
    additionalProperties:
        MixSummary._extras(json, 'additionalProperties') == null
        ? const {}
        : MixSummary._readExtras(
            MixSummary._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$MixSummaryToJson(MixSummary instance) =>
    <String, dynamic>{
      'color': instance.color,
      'coverUrls': instance.coverUrls,
      'description': instance.description,
      'id': instance.id,
      'name': instance.name,
      'trackCount': ?MixSummary._write_trackCount(instance.trackCount),
      'trackIds': instance.trackIds,
      'type': instance.type,
    };
